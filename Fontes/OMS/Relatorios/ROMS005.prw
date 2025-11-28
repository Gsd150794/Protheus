/*
=================================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
=================================================================================================================================
 Autor        |    Data    |                              Motivo
=================================================================================================================================
Alex Wallauer | 03/05/2019 | Chamado 29042. Inclusão da coluna Pedido por ordem de Carga. 
Alex Wallauer | 07/05/2019 | Chamado 29104. Retirada as opções de ordem 8 e 9. 
Lucas Borges  | 17/10/2019 | Chamado 28346. Removidos os Warning na compilação da release 12.1.25. .
Julio Paz     | 18/09/2020 | Chamado 34103. Inclusão de coluna p/exibir tipo de frete p/algumas ordens de impressão do relatorio.
Igor Melgaço  | 27/04/2021 | Chamado 36203. Ajuste para visual. de regsitros qdo F2_TIPO = D ou B visualizando os dados do For. 
Igor Melgaço  | 04/06/2021 | Chamado 36726. Ajuste conceitualmente igual ao anterior para demais ordens do relatório. 
Alex Wallauer | 24/03/2022 | Chamado 40019. Novas Colunas de valor de Frete e Armazém na Ordem AT&M. 
Jerry         | 05/07/2022 | Chamado 40677. Adicionar Desc. do Produto na Ordem Produto x UF. 
Alex Wallauer | 09/01/2023 | Chamado 41604. Novo tratamento para Pedidos de Operacao Triangular. Cancelado
Alex Wallauer | 23/01/2024 | Chamado 45841. Jerry. Adicionar a Colunas de Observações da Ordem de Carga (DAK_I_OBS+DAK_I_OBS2).
Julio Paz     | 13/08/2024 | Chamado 47782. Jerry. Incluir nova coluna para exibir o novo campo Tipo Averb. Carga (A2_I_TPAVE).
=================================================================================================================================
==============================================================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==============================================================================================================================================================
Lucas    - Alex Wallauer - 13/08/25 - 14/08/25 -  51786  - Correção do error.log: Error : 1704 - ORA-01704: string literal too long
Jerry    - Julio Paz     - 29/09/25 -          -  52177  - Correções nos filtros do relatório. 
==============================================================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "Report.ch" 
#Include "TOTVS.ch"


/*
===============================================================================================================================
Programa--------: ROMS005
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Relatório de Fretes por Transportadoras
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ROMS005()

Private oBrkTransp
Private oReport   
Private oSF2FIL_1
Private oSF2_1
Private oSF2_1A
//Private oSF2S_1
Private oSF2A_1
Private oSF2FIL_5
Private oSF2_5
Private oSF2_2
Private oSF2A_2
Private cPerg		:= "ROMS005"
Private QRY1
Private QRY2                                                                                                                                                                              
Private QRY5           //01        02          03             04          05                 06                  07                08                           09               10       11
Private aOrd		:= {"1-Carga","2-Produto","3-Grupo Produto","4-Resumido","5-Transportador","6-Grupo de Produto x UF","7-Produto x UF","8-Fechamento x Produto","9-Fechamento x Sub-Grupo","10-Veiculo","11-AT&M"}  
Private cTransp		:= " "
Private cCarga		:= " "
Private nOrdem		:= 1
//Private oSumVrFret  
Private cFiltro		:= " "
Private nTotFret	:= 0
Private nAuxNF		:= 0
Private nAuxCarga	:= 0
Private cNomeFil	:= " "

Pergunte( cPerg , .F. )
/////////////////////////////   REPORT   /////////////////////////////   
DEFINE REPORT oReport NAME "ROMS005" TITLE "Relação de Fretes por Transportadoras" PARAMETER cPerg ACTION {|oReport| ROMS005RUN(oReport) } 

oReport:SetLandscape() // Seta Padrao de impressao Paisagem.
oReport:SetTotalInLine(.F.)

//====================================================================================================
// Define secoes para PRIMEIRA ORDEM - Transp/Carga ***************************************
//====================================================================================================
// Secao Filial
//====================================================================================================
DEFINE Section oSF2FIL_1 OF oReport TITLE "O1-Filial" TABLES "SD2"  ORDERS aOrd

DEFINE CELL NAME "D2_FILIAL"	OF oSF2FIL_1 ALIAS "SD2"  TITLE "Cod "
DEFINE CELL NAME "NOMFIL"	    OF oSF2FIL_1 ALIAS "" BLOCK{|| FWFilialName(,QRY1->D2_FILIAL)} TITLE "Filial" SIZE 20

oSF2FIL_1:OnPrintLine( {|| cNomeFil := QRY1->D2_FILIAL +" -  "+ FWFilialName(, QRY1->D2_FILIAL ) } )
oSF2FIL_1:SetTotalText( {|| "SUBTOTAL FILIAL: "+ cNomeFil } )
oSF2FIL_1:Disable()

//====================================================================================================
// Secao Transportadora
//====================================================================================================
DEFINE Section oSF2_1 OF oSF2FIL_1 TITLE "O1-Transportadora" TABLES "SA2"  ORDERS aOrd

DEFINE CELL NAME "A2_COD"	    OF oSF2_1 ALIAS "SA2"  TITLE "Cod." 
DEFINE CELL NAME "A2_NREDUZ"	OF oSF2_1 ALIAS "SA2"  TITLE "Transportadora" SIZE 40
DEFINE CELL NAME "A2_EST"		OF oSF2_1 ALIAS "SA2"  TITLE "UF" 

oSF2_1:SetTotalText( {|| "SUBTOTAL TRANSPORTADORA: "+ cTransp +" Total de Cargas: "+ Transform( oCountCarga:GetValue() , "@E 9999" ) +" Total de NF's: "+ Transform( oCountNF:GetValue() , "@E 9999" ) } )
oSF2_1:OnPrintLine( {|| cTransp := QRY1->A2_COD + " - " + QRY1->A2_NREDUZ ,AllwaysTrue() } )
oSF2_1:SetLinesBefore(5)
oSF2_1:Disable()

DEFINE BREAK oBrkTransp OF oSF2_1 WHEN oSF2_1:Cell("A2_COD") TITLE {|| "SUBTOTAL TRANSPORTADORA: "+ cTransp + ROMS005UPC( oCountNF:GetValue() , oCountCarga:GetValue() ) }

//====================================================================================================
// Secao Carga - SubSecao da Secao Transportadora
//====================================================================================================
DEFINE Section oSF2_1A OF oSF2_1 TITLE "O1-Carga" TABLES "DAK","DA3","DA4"  ORDERS aOrd

DEFINE CELL NAME "DAK_COD"  	OF oSF2_1A ALIAS "DAK" TITLE "Carga"
DEFINE CELL NAME "DAK_DATA"		OF oSF2_1A ALIAS "DAK" TITLE "Data"
DEFINE CELL NAME "DAK_I_FRET" 	OF oSF2_1A ALIAS "SF2"
DEFINE CELL NAME "DAK_PESO" 	OF oSF2_1A ALIAS "SF2" PICTURE "@E 999,999,999,999.99" SIZE 17
DEFINE CELL NAME "DA3_PLACA" 	OF oSF2_1A ALIAS "DA3" 
DEFINE CELL NAME "DA3_DESC" 	OF oSF2_1A ALIAS "DA3" TITLE "Veiculo" SIZE 30
DEFINE CELL NAME "DA3_I_PLCV" 	OF oSF2_1A ALIAS "DA3"
DEFINE CELL NAME "DA3_I_PLVG" 	OF oSF2_1A ALIAS "DA3"
DEFINE CELL NAME "DA4_COD" 	    OF oSF2_1A ALIAS "DA4" TITLE "Motorista" SIZE 35 BLOCK{|| QRY1->DA4_COD + '-' + QRY1->DA4_NOME}

oSF2_1A:SetTotalInLine(.F.)
oSF2_1A:SetTotalText({||"SUBTOTAL CARGA: " + cCarga  })
oSF2_1A:OnPrintLine({|| cCarga := QRY1->DAK_COD ,AllwaysTrue()}) //Atualiza Variavel do Subtotal
oSF2_1A:SetLinesBefore(3) //Quantidade de linhas a serem saltadas antes de imprimir a secao
oSF2_1A:Disable()

//====================================================================================================
// Secao Cabecalho Nota - SubSecao da Secao Transportadora
//====================================================================================================
DEFINE Section oSF2_1B OF oSF2_1A TITLE "01-Nota Fiscal" TABLES "SF2","DA3"  ORDERS aOrd

DEFINE CELL NAME "F2_DOC"    	OF oSF2_1B ALIAS "SF2" TITLE "Doc. Fiscal"
DEFINE CELL NAME "F2_EMISSAO" 	OF oSF2_1B ALIAS "SF2"
DEFINE CELL NAME "D2_CLIENTE" 	OF oSF2_1B ALIAS "SD2" TITLE "Cod."
DEFINE CELL NAME "D2_LOJA" 		OF oSF2_1B ALIAS "SD2" SIZE 05
DEFINE CELL NAME "A1_NREDUZ" 	OF oSF2_1B ALIAS "SA1" SIZE 30 TITLE "Cliente"
DEFINE CELL NAME "A1_MUN" 	    OF oSF2_1B ALIAS "SA1"
DEFINE CELL NAME "A1_EST" 	    OF oSF2_1B ALIAS "SA1" TITLE "UF" 
DEFINE CELL NAME "F2_VALMERC" 	OF oSF2_1B ALIAS "SF2" TITLE "Vlr.Total" 
DEFINE CELL NAME "F2_VALBRUT" 	OF oSF2_1B ALIAS "SF2"
DEFINE CELL NAME "F2_PLIQUI"   	OF oSF2_1B ALIAS "SF2" TITLE "Peso Total" PICTURE "@E 999,999,999,999.99"  SIZE 17
DEFINE CELL NAME "D2_I_FRET" 	OF oSF2_1B ALIAS "SD2" TITLE "Frete N.F." PICTURE "@E 999,999,999,999.99"  SIZE 20
DEFINE CELL NAME "DAI_PEDIDO"  	OF oSF2_1B ALIAS "DAI" TITLE "Pedido"
DEFINE CELL NAME "DAK_I_OBS"	OF oSF2_1B ALIAS "DAK" TITLE "Observacao" SIZE Len(DAK->DAK_I_OBS+DAK->DAK_I_OBS2) BLOCK{|| AllTrim(QRY1->DAK_I_OBS) + ' ' + AllTrim(QRY1->DAK_I_OBS2)}
//DEFINE CELL NAME "DAK_I_OBS2"	OF oSF2_1B ALIAS "DAK" TITLE "Observacao2" SIZE Len(DAK->DAK_I_OBS2) //PARA TESTES

oSF2_1B:SetTotalInLine(.F.)
oSF2_1B:SetTotalText({||"SUBTOTAL NOTA: " + cCarga  })
oSF2_1B:OnPrintLine({|| cCarga := QRY1->DAK_COD ,AllwaysTrue()}) //Atualiza Variavel do Subtotal
oSF2_1B:Disable()

//====================================================================================================
// Secao Detalhes Analitico - SubSecao da Secao SF2_1B
//====================================================================================================
DEFINE Section oSF2A_1         OF oSF2_1B TITLE "01-Carga" TABLES "SD2","SB1" ORDERS aOrd

DEFINE CELL NAME "D2_COD"	    OF oSF2A_1 ALIAS "SD2" TITLE "Produto"
DEFINE CELL NAME "B1_I_DESCD" 	OF oSF2A_1 ALIAS "SB1" TITLE "Descricao" SIZE 40
DEFINE CELL NAME "D2_QUANT"	    OF oSF2A_1 ALIAS "SD2" PICTURE "@E 999,999,999,999.99" SIZE 16 
DEFINE CELL NAME "D2_UM"      	OF oSF2A_1 ALIAS "SD2" TITLE "Un. M" SIZE 6
DEFINE CELL NAME "D2_QTSEGUM" 	OF oSF2A_1 ALIAS "SD2" PICTURE "@E 999,999,999.99" SIZE 14 
DEFINE CELL NAME "D2_SEGUM" 	OF oSF2A_1 ALIAS "SD2" TITLE "Seg. UM" SIZE 6
DEFINE CELL NAME "D2_PRCVEN"	OF oSF2A_1 ALIAS "SD2" //PICTURE "@E 999,999,999.99"
DEFINE CELL NAME "D2_TOTAL" 	OF oSF2A_1 ALIAS "SD2" //PICTURE "@E 999,999,999.99"  
DEFINE CELL NAME "D2_VALBRUT" 	OF oSF2A_1 ALIAS "SD2" //PICTURE "@E 999,999,999.99"  
DEFINE CELL NAME "VLRITEM" 	    OF oSF2A_1 ALIAS "SD2" TITLE "Frete Item" PICTURE "@E 999,999,999.99" SIZE 14

DEFINE CELL NAME "A2_I_TPAVE" 	OF oSF2A_1 ALIAS "SA2" TITLE "Tipo Averb.Carga" BLOCK {|| If(QRY1->A2_I_TPAVE=="E","EMBARCADOR",If(QRY1->A2_I_TPAVE=="T","TRANSPORTADOR",""))} 

oSF2A_1:SetTotalInLine(.F.)
oSF2A_1:SetTotalText({||"SUBTOTAL NOTA:" })

oSF2A_1:Disable()

//====================================================================================================
// Define secoes para SEGUNDA ORDEM - Produtos ***************************************
//====================================================================================================
// Secao Filial
//====================================================================================================
DEFINE Section oSF2FIL_2 OF oReport TITLE "O2-Filial" TABLES "SD2"  ORDERS aOrd

DEFINE CELL NAME "D2_FILIAL"	OF oSF2FIL_2 ALIAS "SD2"  TITLE "Cod "
DEFINE CELL NAME "NOMFIL"	    OF oSF2FIL_2 ALIAS "" BLOCK{|| FWFilialName(,QRY2->D2_FILIAL)} TITLE "Filial" SIZE 20

oSF2FIL_2:OnPrintLine( {|| cNomeFil := QRY2->D2_FILIAL +" -  "+ FWFilialName(,QRY2->D2_FILIAL) } )
oSF2FIL_2:SetTotalText( {|| "SUBTOTAL FILIAL: "+ cNomeFil } )
oSF2FIL_2:Disable()

//====================================================================================================
// Secao Transportadora
//====================================================================================================
DEFINE Section oSF2_2 OF oSF2FIL_2 TITLE "O2-Transportadora" TABLES "SA2" ORDERS aOrd

DEFINE CELL NAME "A2_COD"	    OF oSF2_2 ALIAS "SA2"  TITLE "Cod." 
DEFINE CELL NAME "A2_NREDUZ"	OF oSF2_2 ALIAS "SA2"  TITLE "Transportadora" SIZE 40
DEFINE CELL NAME "A2_EST"		OF oSF2_2 ALIAS "SA2"  TITLE "UF" 

oSF2_2:Disable()                                                                                              

//====================================================================================================
// Secao Carga - SubSecao da Secao Transportadora
//====================================================================================================
DEFINE Section oSF2A_2 OF oSF2_2 TITLE "O2-Produtos" TABLES "SB1"

DEFINE CELL NAME "D2_COD"	    OF oSF2A_2 ALIAS "SD2" TITLE "Produto"
DEFINE CELL NAME "B1_I_DESCD" 	OF oSF2A_2 ALIAS "SB1" TITLE "Descricao" SIZE 40 PICTURE "@S40"
DEFINE CELL NAME "D2_QUANT"	    OF oSF2A_2 ALIAS "SD2" PICTURE "@E 999,999,999,999.99" SIZE 16 
DEFINE CELL NAME "D2_UM"      	OF oSF2A_2 ALIAS "SD2" TITLE "Un. M" SIZE 6
DEFINE CELL NAME "D2_QTSEGUM" 	OF oSF2A_2 ALIAS "SD2" PICTURE "@E 999,999,999.99" SIZE 14 
DEFINE CELL NAME "D2_SEGUM" 	OF oSF2A_2 ALIAS "SD2" SIZE 6
DEFINE CELL NAME "D2_PRCVEN"	OF oSF2A_2 ALIAS "SD2" PICTURE "@E 999,999,999.9999"
DEFINE CELL NAME "D2_TOTAL" 	OF oSF2A_2 ALIAS "SD2" PICTURE "@E 999,999,999.99"       
DEFINE CELL NAME "D2_VALBRUT" 	OF oSF2A_2 ALIAS "SD2" PICTURE "@E 999,999,999.99"
DEFINE CELL NAME "D2_I_FRET" 	OF oSF2A_2 ALIAS "SD2" TITLE "Frete" PICTURE "@E 999,999,999.99" SIZE 14
DEFINE CELL NAME "MEDIA"    	OF oSF2A_2 ALIAS "SF2" TITLE "Frete Unit" BLOCK {|| ((QRY2->D2_I_FRET/QRY2->D2_QUANT))} PICTURE "@E 999,999,999.99" SIZE 14
DEFINE CELL NAME "D2_DOC" 		OF oSF2A_2 ALIAS "SD2" TITLE "NF" PICTURE "999999999"
DEFINE CELL NAME "F2_CARGA" 	OF oSF2A_2 ALIAS "SF2" TITLE "Carga" PICTURE "999999"

oSF2A_2:Disable()
oSF2A_2:SetTotalInLine(.F.)
oSF2A_2:SetTotalText( {|| "SUBTOTAL TRANSPORTADORA: " + cTransp } )
oSF2A_2:OnPrintLine( {|| cTransp := QRY2->A2_COD + " - " + QRY2->A2_NREDUZ ,AllwaysTrue() } ) //Atualiza Variavel do Subtotal
oSF2A_2:Cell("MEDIA"):SetHeaderAlign("RIGHT")

//====================================================================================================
// Define secoes para TERCEIRA ORDEM - Grupos Produtos ***************************************
//====================================================================================================
// Secao Filial
//====================================================================================================
DEFINE Section oSF2FIL_3 OF oReport TITLE "O3-Filial" TABLES "SD2"  ORDERS aOrd

DEFINE CELL NAME "D2_FILIAL"	OF oSF2FIL_3 ALIAS "SD2"  TITLE "Cod "
DEFINE CELL NAME "NOMFIL"	    OF oSF2FIL_3 ALIAS "" BLOCK{|| FWFilialName(,QRY3->D2_FILIAL)} TITLE "Filial" SIZE 20

oSF2FIL_3:OnPrintLine( {|| cNomeFil := QRY3->D2_FILIAL  +" - "+ FWFilialName(,QRY3->D2_FILIAL) } )
oSF2FIL_3:SetTotalText( {|| "SUBTOTAL FILIAL: " + cNomeFil } )
oSF2FIL_3:Disable()

//====================================================================================================
// Secao Transportadora
//====================================================================================================
DEFINE Section oSF2_3 OF oSF2FIL_3 TITLE "O3-Transportadora" TABLES "SA2" ORDERS aOrd

DEFINE CELL NAME "A2_COD"	    OF oSF2_3 ALIAS "SA2"  TITLE "Cod." 
DEFINE CELL NAME "A2_NREDUZ"	OF oSF2_3 ALIAS "SA2"  TITLE "Transportadora" SIZE 40
DEFINE CELL NAME "A2_EST"		OF oSF2_3 ALIAS "SA2"  TITLE "UF" 

oSF2_3:Disable()

//====================================================================================================
// Secao Carga - SubSecao da Secao Transportadora
//====================================================================================================
DEFINE Section oSF2A_3 OF oSF2_3 TITLE "O3-Grupos Produtos" TABLES "SB1"

DEFINE CELL NAME "B1_GRUPO"	    OF oSF2A_3 ALIAS "SB1" TITLE "Grupo"
DEFINE CELL NAME "DESCGRUPO"   	OF oSF2A_3 ALIAS ""    TITLE "Descricao" SIZE 40  BLOCK{|| Posicione( "SBM" , 1 , xFilial("SBM") + QRY3->B1_GRUPO , "BM_DESC" ) }
DEFINE CELL NAME "D2_QUANT"	    OF oSF2A_3 ALIAS "SD2" PICTURE "@E 999,999,999,999.99" SIZE 16 
DEFINE CELL NAME "D2_UM"      	OF oSF2A_3 ALIAS "SD2" TITLE "Un. M" SIZE 6
DEFINE CELL NAME "D2_QTSEGUM" 	OF oSF2A_3 ALIAS "SD2" PICTURE "@E 999,999,999.99" SIZE 14 
DEFINE CELL NAME "D2_SEGUM" 	OF oSF2A_3 ALIAS "SD2" TITLE "Seg. UM" SIZE 6
DEFINE CELL NAME "D2_PRCVEN"	OF oSF2A_3 ALIAS "SD2" PICTURE "@E 999,999,999.9999"
DEFINE CELL NAME "D2_TOTAL" 	OF oSF2A_3 ALIAS "SD2" PICTURE "@E 999,999,999.99" 
DEFINE CELL NAME "D2_VALBRUT" 	OF oSF2A_3 ALIAS "SD2" PICTURE "@E 999,999,999.99" 
DEFINE CELL NAME "D2_I_FRET" 	OF oSF2A_3 ALIAS "SD2" TITLE "Frete" PICTURE "@E 999,999,999.99" SIZE 14
DEFINE CELL NAME "MEDIA"    	OF oSF2A_3 ALIAS "SF2" TITLE "Frete Unit." BLOCK {|| ( QRY3->D2_I_FRET / QRY3->D2_QUANT ) } PICTURE "@E 999,999,999.99" SIZE 14

oSF2A_3:Disable()
oSF2A_3:SetTotalInLine(.F.)
oSF2A_3:OnPrintLine( {|| cTransp := QRY3->A2_COD +" - "+ QRY3->A2_NREDUZ , AllwaysTrue() } ) //Atualiza Variavel do Subtotal
oSF2A_3:SetTotalText( {|| "SUBTOTAL TRANSPORTADORA: "+ cTransp } )

//====================================================================================================
// Define secoes para QUARTA ORDEM - Transp/Resumido ***************************************
//====================================================================================================
// Secao Filial
//====================================================================================================
DEFINE Section oSF2FIL_4 OF oReport TITLE "O4-Filial" TABLES "SD2"  ORDERS aOrd

DEFINE CELL NAME "D2_FILIAL"	OF oSF2FIL_4 ALIAS "SD2"  TITLE "Cod "
DEFINE CELL NAME "NOMFIL"	    OF oSF2FIL_4 ALIAS "" BLOCK{|| FWFilialName(,QRY4->D2_FILIAL) } TITLE "Filial" SIZE 20

oSF2FIL_4:OnPrintLine( {|| cNomeFil := QRY4->D2_FILIAL +" - "+ FWFilialName(,QRY4->D2_FILIAL) } )
oSF2FIL_4:SetTotalText( {|| "SUBTOTAL FILIAL: " + cNomeFil } )
oSF2FIL_4:Disable()

//====================================================================================================
// Secao Transportadora
//====================================================================================================
DEFINE Section oSF2_4 OF oSF2FIL_4 TITLE "O4-Resumido" TABLES "SA2" ORDERS aOrd

DEFINE CELL NAME "A2_COD"	    OF oSF2_4 ALIAS "SA2"  TITLE "Cod."
DEFINE CELL NAME "A2_NREDUZ"	OF oSF2_4 ALIAS "SA2"  TITLE "Transportadora" SIZE 40
DEFINE CELL NAME "A2_EST"		OF oSF2_4 ALIAS "SA2"  TITLE "UF" 
DEFINE CELL NAME "D2_TOTAL"     OF oSF2_4 ALIAS "SD2"  TITLE "Valor"
DEFINE CELL NAME "D2_I_FRET"    OF oSF2_4 ALIAS "SD2"  TITLE "Frete" 
DEFINE CELL NAME "F2_DOC"	    OF oSF2_4 ALIAS "SF2"  TITLE "Qtd. Notas"
DEFINE CELL NAME "DAK_COD"	    OF oSF2_4 ALIAS "DAK"  TITLE "Qtd. Cargas"
DEFINE CELL NAME "PERCPART"	    OF oSF2_4 ALIAS ""     PICTURE  "@E 999.99" TITLE "% Participacao" BLOCK {|| (QRY4->D2_I_FRET/nTotFret)*100 }

oSF2_4:SetTotalInLine(.F.)
oSF2_4:SetTotalText(" ")
oSF2_4:Disable()                                                                                              
oSF2_4:Cell("F2_DOC"):SetHeaderAlign("RIGHT")
oSF2_4:Cell("DAK_COD"):SetHeaderAlign("RIGHT")
oSF2_4:Cell("PERCPART"):SetHeaderAlign("RIGHT")
                                   
//====================================================================================================
// Define secoes para QUINTA ORDEM - Transportador ***************************************
//====================================================================================================
// Secao Filial
//====================================================================================================
DEFINE Section oSF2FIL_5 OF oReport TITLE "O5-Filial" TABLES "SD2"  ORDERS aOrd

DEFINE CELL NAME "D2_FILIAL"	OF oSF2FIL_5 ALIAS "SD2"  TITLE "Cod "
DEFINE CELL NAME "NOMFIL"	    OF oSF2FIL_5 ALIAS "" BLOCK{|| FWFilialName(,QRY5->D2_FILIAL) } TITLE "Filial" SIZE 40

oSF2FIL_5:OnPrintLine( {|| cNomeFil := QRY5->D2_FILIAL +" - "+ FWFilialName(,QRY5->D2_FILIAL) } )
oSF2FIL_5:SetTotalText( {|| "SUBTOTAL FILIAL: "+ cNomeFil } )
oSF2FIL_5:Disable()

//====================================================================================================
// Secao Dados transportados por uma determinada Transportadora
//====================================================================================================
DEFINE Section oSF2_5 OF oSF2FIL_5 TITLE "O5-Transportador" TABLES "SD2","SA2"

DEFINE CELL NAME "A2_COD"	    OF oSF2_5 ALIAS "SA2" TITLE "Cod." 
DEFINE CELL NAME "A2_NREDUZ"	OF oSF2_5 ALIAS "SA2" TITLE "Transportadora"	SIZE 35
DEFINE CELL NAME "A2_CGC"		OF oSF2_5 ALIAS "SA2" TITLE "CPF/CNPJ"			SIZE 20
DEFINE CELL NAME "A2_EST"		OF oSF2_5 ALIAS "SA2" TITLE "UF" 
DEFINE CELL NAME "D2_TOTAL" 	OF oSF2_5 ALIAS "SD2" PICTURE "@E 999,999,999.99"
DEFINE CELL NAME "D2_VALBRUT" 	OF oSF2_5 ALIAS "SD2" PICTURE "@E 999,999,999.99" 
DEFINE CELL NAME "D2_QUANT"	    OF oSF2_5 ALIAS "SD2" PICTURE "@E 999,999,999,999.99" SIZE 16 
DEFINE CELL NAME "MEDIA"    	OF oSF2_5 ALIAS ""    TITLE "Media" BLOCK {|| ((QRY5->D2_I_FRET/QRY5->D2_QUANT))} PICTURE "@E 999,999,999.999999" SIZE 20
DEFINE CELL NAME "D2_I_FRET" 	OF oSF2_5 ALIAS "SD2" TITLE "Frete" PICTURE "@E 999,999,999.99" SIZE 14
DEFINE CELL NAME "C5_TPFRETE" 	OF oSF2_5 ALIAS "SC5" TITLE "Tipo de Frete" PICTURE "@!" SIZE 20
DEFINE CELL NAME "A2_I_TPAVE" 	OF oSF2_5 ALIAS "SA2" TITLE "Tipo Averb.Carga" PICTURE "@!" BLOCK {|| If(QRY5->A2_I_TPAVE=="E","EMBARCADOR",If(QRY5->A2_I_TPAVE=="T","TRANSPORTADOR",""))} 

oSF2_5:Disable()
oSF2_5:SetTotalInLine(.F.)
oSF2_5:Cell("MEDIA"):SetHeaderAlign("RIGHT")

oSF2FIL_5:SetTotalInLine(.F.)

oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa--------: ROMS005RUN
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Relatório de Fretes de Transportadoras
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS005RUN( oReport )

cFiltro	:= "%"
nOrdem	:= oSF2FIL_1:GetOrder() // Busca ordem selecionada pelo usuario

//====================================================================================================
// Muda titulo do relatorio de acordo com ordem escolhida pelo usuario
//====================================================================================================
oReport:SetTitle( oReport:Title() +" - "+ If( nOrdem <> 5 , IIf( MV_PAR19 == 1 , "Sintetico." , "Analitico." ) , "" ) +" Ordem "+ aOrd[nOrdem] +". De "+  DToC(MV_PAR02) +" até "+ DToC(MV_PAR03) )

//====================================================================================================
// Define o filtro de acordo com os parametros digitados
// Filtra Filial das tabelas SF2,SD2,SA1,SA2,SB1,DAK,DAI,DA3,DA4
//====================================================================================================
If !Empty( MV_PAR01 )
    MV_PAR01:=AllTrim(MV_PAR01)
	If !Empty( xFilial("SF2") )
		cFiltro += " AND SF2.F2_FILIAL IN "+ FormatIn( MV_PAR01 , ";" )
	EndIf
	
	If !Empty( xFilial("SD2") )
		cFiltro += " AND SD2.D2_FILIAL IN "+ FormatIn( MV_PAR01 , ";" )
	EndIf
	
	If !Empty( xFilial("DAK") )
		cFiltro += " AND DAK.DAK_FILIAL IN "+ FormatIn( MV_PAR01 , ";" )
	EndIf
	
	If !Empty( xFilial("DAI") )
		cFiltro += " AND DAI.DAI_FILIAL IN "+ FormatIn( MV_PAR01 , ";" )
	EndIf

EndIf

//====================================================================================================
// Filtra Emissao da SF2
//====================================================================================================
If !Empty(MV_PAR02) .And. !Empty(MV_PAR03)
	cFiltro += " AND SF2.F2_EMISSAO BETWEEN '" + DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "'"
EndIf

//====================================================================================================
// Filtra Produto
//====================================================================================================
If !Empty(MV_PAR04) .And. !Empty(MV_PAR05)
	cFiltro += " AND SD2.D2_COD BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR05 + "'"
EndIf

//====================================================================================================
// Filtra Armazém
//====================================================================================================
If !Empty(MV_PAR27) 
	cFiltro += " AND SD2.D2_LOCAL IN " + FormatIn(AllTrim( MV_PAR27 ),";")
EndIf

//====================================================================================================
// Filtra Cliente
//====================================================================================================
If !Empty(MV_PAR06) .And. !Empty(MV_PAR08)
	cFiltro += " AND SD2.D2_CLIENTE BETWEEN '" + MV_PAR06 + "' AND '" + MV_PAR08 + "'"
EndIf

//====================================================================================================
// Filtra Loja Cliente
//====================================================================================================
If !Empty(MV_PAR07) .And. !Empty(MV_PAR09)
	cFiltro += " AND SD2.D2_LOJA BETWEEN '" + MV_PAR07 + "' AND '" + MV_PAR09 + "'"
EndIf

//====================================================================================================
// Filtra Rede Cliente
//====================================================================================================
If !Empty(MV_PAR10)
	cFiltro += " AND SA1.A1_GRPVEN IN " + FormatIn(AllTrim( MV_PAR10),";")
EndIf

//====================================================================================================
// Filtra Estado Cliente
//====================================================================================================
If !Empty(MV_PAR11) 
	cFiltro += " AND SA1.A1_EST IN " + FormatIn(AllTrim( MV_PAR11),";")
EndIf

//====================================================================================================
// Filtra Cod Municipio Cliente
//====================================================================================================
If !Empty(MV_PAR12) 
	cFiltro += " AND SA1.A1_COD_MUN IN " + FormatIn(AllTrim( MV_PAR12),";")
EndIf

//====================================================================================================
// Filtra Vendedor
//====================================================================================================
If !Empty(MV_PAR13) 
	cFiltro += " AND SA3.A3_COD IN " + FormatIn(AllTrim( MV_PAR13),";")
EndIf

//====================================================================================================
// Filtra Supervisor
//====================================================================================================
If !Empty(MV_PAR14)
	cFiltro += " AND SA3.A3_SUPER IN " + FormatIn(AllTrim( MV_PAR14),";")
EndIf

//====================================================================================================
// Filtra Grupo de Produtos
//====================================================================================================
If !Empty(MV_PAR15)
	cFiltro += " AND SB1.B1_GRUPO IN " + FormatIn(AllTrim( MV_PAR15),";")
EndIf

//====================================================================================================
// Filtra Produto Nivel 2
//====================================================================================================
If !Empty(MV_PAR16)
	cFiltro += " AND SB1.B1_I_NIV2 IN " + FormatIn(AllTrim( MV_PAR16),";")
EndIf

//====================================================================================================
// Filtra Produto Nivel 3
//====================================================================================================
If !Empty(MV_PAR17)
	cFiltro += " AND SB1.B1_I_NIV3 IN " + FormatIn(AllTrim( MV_PAR17),";")
EndIf

//====================================================================================================
// Filtra Produto Nivel 4
//====================================================================================================
If !Empty(MV_PAR18)
	cFiltro += " AND SB1.B1_I_NIV4 IN " + FormatIn(AllTrim( MV_PAR18),";")
EndIf 

//====================================================================================================
// Filtra Transportadoras
//====================================================================================================
If !Empty(MV_PAR20)
	cFiltro += " AND SA2.A2_COD IN " + FormatIn(AllTrim( MV_PAR20),";")
EndIf 

//====================================================================================================
// Filtra tipo do Fornecedor
//====================================================================================================
If !Empty(MV_PAR25)
	cFiltro    += " AND SA2.A2_I_CLASS IN " + FormatIn(AllTrim( MV_PAR25),";")
EndIf

//====================================================================================================
// Filtra Transportadoras por averbacao
//====================================================================================================
/* Por solicitação da usuária fixar a opção de filtro Transportadoras por averbação em abas.
If MV_PAR28 == 1
	cFiltro += " AND SA2.A2_I_AVERB = '1'"
EndIf 
If MV_PAR28 == 2
	cFiltro += " AND SA2.A2_I_AVERB = '2'"
EndIf
*/
//====================================================================================================
// busca CFOPS de acordo com parametro definido por usuario
//====================================================================================================
If !Empty(MV_PAR21)
	
	If !("A" $ MV_PAR21 ) // Senao tiver escolhido a opcao todos
	
		cCfops	:= U_ITCFOPS( AllTrim( Upper( MV_PAR21 ) ) )
		cFiltro	+= " AND SD2.D2_CF IN "+ FormatIn( cCfops , ";" )

/*        cFiltro += " AND SC5.C5_I_OPER <> '05' "
	    If ("V" $ MV_PAR21 ) .And. !("R" $ MV_PAR21 )
		   cFiltro += " AND ( SD2.D2_CF IN " + FormatIn(AllTrim(cCfops),";")
		   cCfopsR := U_ITCFOPS("R")
		   cFiltro += " OR ( SD2.D2_CF IN " + FormatIn(AllTrim(cCfopsR),";") + " AND SC5.C5_I_OPER = '42' ) ) "
	    Else//If !("V" $ MV_PAR21 ) 
		   cFiltro += " AND SD2.D2_CF IN " + FormatIn(AllTrim(cCfops),";")
		EndIf*/
		
	EndIf
	
EndIf

//====================================================================================================
// Verifica se filtro os dados das cargas que possuem Frete: 1, que nao possuem frete: 2 ou ambas: 3
//====================================================================================================
/* Por solicitação do usuário fixar a opção "Possui Frete"  em ambas.
If MV_PAR22 == 1

	cFiltro += " AND SF2.F2_I_FRET > 0 "

ElseIf MV_PAR22 == 2

	cFiltro += " AND SF2.F2_I_FRET = 0 "

EndIf
*/ 

//====================================================================================================
// Sub Grupo de Produtos
//====================================================================================================
If !Empty(MV_PAR23)
	cFiltro += " AND SB1.B1_I_SUBGR IN " + FormatIn(AllTrim( MV_PAR23),";")
EndIf 

//====================================================================================================
// Filtra Tipo da carga
//====================================================================================================
If !Empty(MV_PAR24)
	cFiltro += " AND DAK.DAK_I_TPCA IN " + FormatIn(AllTrim( MV_PAR24),";")
EndIf           

//====================================================================================================
// Filtra Transportadoras por averbacao
//====================================================================================================
If !Empty(MV_PAR29)
	cFiltro += " AND SC5.C5_TPFRETE IN"+ FormatIn(AllTrim(  MV_PAR29) , ";" )
EndIf 

//====================================================================================================================================
//"6-Grupo de Produto x UF","7-Produto x UF","8-Fechamento x Produto","9-Fechamento x Sub-Grupo","10-Veiculo","11-AT&M"
//====================================================================================================================================
If nOrdem == 6 .Or. nOrdem == 7 .Or. nOrdem == 8 .Or. nOrdem == 9 .Or. nOrdem == 10 .Or. nordem == 11

	oReport:Disable()
    If MV_PAR26 == 2 // Relatório em Excel  
       oReport:CancelPrint()
    EndIf
    
	If ROMS05Val(nOrdem)    
	   ROMS005GRP()
	EndIf

    If MV_PAR26 == 1 // Impressão
       oReport:CancelPrint()
    EndIf
     
EndIf

cFiltro += "%"

//====================================================================================================
// Verifica qual ordem usuario definiu
//====================================================================================================
If nOrdem == 1 //ORDEM POR CARGA

	//====================================================================================================
	// Habilita Secoes e Define break para Filial para sumarizar campos
	//====================================================================================================
	DEFINE BREAK oBrkFil OF oSF2FIL_1 WHEN oSF2FIL_1:CELL("D2_FILIAL") TITLE {|| "SUBTOTAL FILIAL: " + cNomeFil }
	
	oSF2FIL_1:Enable()
	oSF2_1:Enable()
	oSF2_1A:Enable()
	oSF2_1B:Enable()
	
	If MV_PAR19 == 2 //Analitico
	
	   oSF2A_1:Enable()
		//====================================================================================================
		// Secao Detalhes Analitico - SubSecao da Secao SF2_1B
		//====================================================================================================
		   
		DEFINE FUNCTION FROM oSF2A_1:Cell("D2_QUANT")   FUNCTION SUM NO END Section BREAK oBrkTransp
		DEFINE FUNCTION FROM oSF2A_1:Cell("D2_QTSEGUM") FUNCTION SUM NO END Section BREAK oBrkTransp
		DEFINE FUNCTION FROM oSF2A_1:Cell("D2_TOTAL")   FUNCTION SUM NO END Section BREAK oBrkTransp 
		DEFINE FUNCTION FROM oSF2A_1:Cell("D2_VALBRUT") FUNCTION SUM NO END Section BREAK oBrkTransp  
		DEFINE FUNCTION FROM oSF2A_1:Cell("VLRITEM")    FUNCTION SUM NO END Section BREAK oBrkTransp 	                                            
		
		DEFINE FUNCTION FROM oSF2A_1:Cell("D2_QUANT")   FUNCTION SUM BREAK oBrkFil NO END Section NO END REPORT
		DEFINE FUNCTION FROM oSF2A_1:Cell("D2_QTSEGUM") FUNCTION SUM BREAK oBrkFil NO END Section NO END REPORT                                                                                                       
		DEFINE FUNCTION FROM oSF2A_1:Cell("D2_TOTAL")   FUNCTION SUM BREAK oBrkFil NO END Section NO END REPORT
		DEFINE FUNCTION FROM oSF2A_1:Cell("D2_VALBRUT") FUNCTION SUM BREAK oBrkFil NO END Section NO END REPORT
		DEFINE FUNCTION FROM oSF2A_1:Cell("VLRITEM")    FUNCTION SUM BREAK oBrkFil NO END Section NO END REPORT
		
	Else
	
		DEFINE FUNCTION FROM oSF2_1B:Cell("F2_VALBRUT") FUNCTION SUM BREAK oBrkFil NO END Section NO END REPORT
		DEFINE FUNCTION FROM oSF2_1B:Cell("F2_VALMERC") FUNCTION SUM BREAK oBrkFil NO END Section NO END REPORT
		DEFINE FUNCTION FROM oSF2_1B:Cell("F2_PLIQUI")  FUNCTION SUM BREAK oBrkFil NO END Section NO END REPORT
		DEFINE FUNCTION FROM oSF2_1B:Cell("D2_I_FRET")  FUNCTION SUM BREAK oBrkFil NO END Section NO END REPORT
	
	EndIf
	
	oCountNF	:= TRFunction():New( oSF2_1B:Cell( "A1_MUN"  ) , NIL , "COUNT" , NIL , "Total NF"     , NIL , NIL , .F. , .F. )
	oCountCarga	:= TRFunction():New( oSF2_1A:Cell( "DAK_COD" ) , NIL , "COUNT" , NIL , "Total Cargas" , NIL , NIL , .F. , .F. )
    
	//====================================================================================================
	// Query para relatorio Analitico
	//====================================================================================================
	If MV_PAR19 == 2
	
		BEGIN REPORT QUERY oSF2FIL_1
		
			BeginSql alias "QRY1"
			
				SELECT
				    SUM(SD2.D2_TOTAL)					AS D2_TOTAL,
				    SUM(SD2.D2_VALBRUT)					AS D2_VALBRUT,
				    SUM(SD2.D2_PESO * SD2.D2_QUANT)		AS D2_PESO,
				    SUM(SD2.D2_I_FRET)					AS VLRITEM,
					Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD    WHEN SA2.A2_I_CLASS = 'A' THEN '999999'    END AS A2_COD,
					Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END AS A2_NREDUZ,
					DAK.DAK_COD,
					DAK.DAK_DATA,
					DAK_I_OBS,
					DAK_I_OBS2,
					SF2.F2_EMISSAO,
					SD2.D2_CLIENTE,
					SD2.D2_LOJA,
					SA1.A1_NREDUZ,
					SA1.A1_MUN,
					SA1.A1_EST,
					SF2.F2_DOC,
					SF2.F2_SERIE,
					SF2.F2_VALBRUT,
					SF2.F2_I_FRET AS D2_I_FRET,
					SD2.D2_COD,
					SB1.B1_I_DESCD,
					SD2.D2_QUANT,
					SD2.D2_UM,
					SD2.D2_SEGUM,
					SD2.D2_QTSEGUM,
					SF2.F2_PBRUTO,
					SF2.F2_PLIQUI,
					DA3.DA3_PLACA,
					DA3.DA3_I_PLCV,
					DA3.DA3_I_PLVG,
					DAK.DAK_I_FRET,
					SD2.D2_I_FRET,
					DAK.DAK_PESO,
					SD2.D2_TOTAL,
					SD2.D2_FILIAL,
					SD2.D2_PRCVEN,
					SF2.F2_VALMERC,
					SA2.A2_I_CLASS,
					SA2.A2_EST,
					SA2.A2_I_TPAVE, 
					DA3.DA3_DESC,
					DA4.DA4_COD,
					DA4.DA4_NOME,
					DAI_PEDIDO
				FROM %Table:DAK% DAK
				JOIN %Table:DAI% DAI ON DAI.DAI_COD    = DAK.DAK_COD	AND DAI.DAI_FILIAL = DAK.DAK_FILIAL
				JOIN %Table:DA3% DA3 ON DAK.DAK_CAMINH = DA3.DA3_COD
				JOIN %Table:SF2% SF2 ON SF2.F2_DOC     = DAI.DAI_NFISCA	AND SF2.F2_SERIE   = DAI.DAI_SERIE	AND SF2.F2_FILIAL = DAI.DAI_FILIAL
				JOIN %Table:SD2% SD2 ON SD2.D2_DOC     = SF2.F2_DOC		AND SD2.D2_SERIE   = SF2.F2_SERIE	AND SD2.D2_FILIAL = SF2.F2_FILIAL
				JOIN (SELECT A1_FILIAL, A1_COD, A1_LOJA, A1_NREDUZ, A1_MUN, A1_EST, A1_GRPVEN, A1_COD_MUN   
						FROM %Table:SA1% SA1
						WHERE SA1.%notDel% 
						UNION
						SELECT A2_FILIAL, A2_COD, A2_LOJA, A2_NREDUZ, A2_MUN, A2_EST, '' As A1_GRPVEN , A2_COD_MUN A1_COD_MUN 
						FROM %Table:SA2% SA2
						WHERE SA2.%notDel% ) SA1 ON SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA  = SA1.A1_LOJA
				JOIN %Table:SA3% SA3 ON SF2.F2_VEND1   = SA3.A3_COD
				JOIN %Table:SB1% SB1 ON SD2.D2_COD     = SB1.B1_COD
				JOIN %Table:DA4% DA4 ON DAK.DAK_MOTORI = DA4.DA4_COD
				JOIN %Table:SA2% SA2 ON SF2.F2_I_CTRA  = SA2.A2_COD		AND SF2.F2_I_LTRA  = SA2.A2_LOJA
				JOIN %Table:SC5% SC5 ON SC5.C5_FILIAL  = SD2.D2_FILIAL  AND SC5.C5_NUM     = SD2.D2_PEDIDO
				WHERE
		        	DAK.%notDel%
		        AND DAI.%notDel%
				AND SF2.%notDel%		        
				AND SD2.%notDel%
				AND SB1.%notDel%
				AND DA4.%notDel%
				AND DA3.%notDel%
				AND SA3.%notDel%
				AND SA2.%notDel%
				AND SC5.%notDel%
				AND SA2.A2_I_CLASS IN ('T','A','G')
				AND SD2.D2_CF <> '5927'
				%exp:cFiltro%
				GROUP BY	Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD    WHEN SA2.A2_I_CLASS = 'A' THEN '999999'    END,
							Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END,
							DAK.DAK_COD,DAK.DAK_DATA,SF2.F2_EMISSAO,SD2.D2_CLIENTE,SD2.D2_LOJA,SA1.A1_NREDUZ,SA1.A1_MUN,SA1.A1_EST,SF2.F2_DOC,SF2.F2_SERIE,SF2.F2_VALBRUT,SF2.F2_I_FRET,SD2.D2_COD,
							SB1.B1_I_DESCD,SD2.D2_QUANT,SD2.D2_UM,SD2.D2_SEGUM,SD2.D2_QTSEGUM,SF2.F2_PBRUTO,SF2.F2_PLIQUI,DA3.DA3_PLACA,DA3.DA3_I_PLCV,DA3.DA3_I_PLVG,DAK.DAK_I_FRET,
							SD2.D2_I_FRET,DAK.DAK_PESO,SD2.D2_TOTAL,SD2.D2_FILIAL,SD2.D2_PRCVEN,SF2.F2_VALMERC,SA2.A2_I_CLASS,SA2.A2_EST,SA2.A2_I_TPAVE,DA3.DA3_DESC,DA4.DA4_COD,DA4.DA4_NOME, 
							DAI_PEDIDO,DAK_I_OBS,DAK_I_OBS2
				ORDER BY	SD2.D2_FILIAL,SA2.A2_I_CLASS,A2_COD,DAK.DAK_DATA,DAK.DAK_COD,SF2.F2_DOC,SF2.F2_SERIE
				
			EndSql
			
		END REPORT QUERY oSF2FIL_1

    	//====================================================================================================
	    // Query para relatorio sintetico
	    //====================================================================================================
	Else
	
		BEGIN REPORT QUERY oSF2FIL_1
		
			BeginSql alias "QRY1"
			
				SELECT
				    SUM(SD2.D2_TOTAL)				AS D2_TOTAL,
				    SUM(SD2.D2_VALBRUT)				AS D2_VALBRUT,
				    SUM(SD2.D2_PESO * SD2.D2_QUANT)	AS D2_PESO,
				    SUM(SD2.D2_I_FRET)				AS D2_I_FRET,
					Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD    WHEN SA2.A2_I_CLASS = 'A' THEN '999999'    END AS A2_COD,
					Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END AS A2_NREDUZ,
					DAK.DAK_COD,
					DAK.DAK_DATA,
					DAK_I_OBS,
					DAK_I_OBS2,
				    SF2.F2_EMISSAO,
					SD2.D2_CLIENTE,
					SD2.D2_LOJA,
					SA1.A1_NREDUZ,
					SA1.A1_MUN,
					SA1.A1_EST,
					SF2.F2_DOC,
					SF2.F2_SERIE,
					SF2.F2_VALBRUT,
					SF2.F2_I_FRET,
					SF2.F2_PBRUTO,
					DA3.DA3_PLACA,
					DA3.DA3_I_PLCV,
					DA3.DA3_I_PLVG,
					DAK.DAK_I_FRET,
					DAK.DAK_PESO,
					SD2.D2_FILIAL,
					SF2.F2_VALMERC,
					F2_PLIQUI,
					SA2.A2_I_CLASS,
					SA2.A2_EST,
					SA2.A2_I_TPAVE, 
					DA3.DA3_DESC,
					DA4.DA4_COD,
					DA4.DA4_NOME,
					DAI_PEDIDO
				FROM %Table:DAK% DAK
				JOIN %Table:DAI% DAI ON DAI.DAI_COD    = DAK.DAK_COD	AND DAI.DAI_FILIAL = DAK.DAK_FILIAL
				JOIN %Table:DA3% DA3 ON DAK.DAK_CAMINH = DA3.DA3_COD
				JOIN %Table:SF2% SF2 ON SF2.F2_DOC     = DAI.DAI_NFISCA AND SF2.F2_SERIE   = DAI.DAI_SERIE	AND SF2.F2_FILIAL = DAI.DAI_FILIAL
				JOIN %Table:SD2% SD2 ON SD2.D2_DOC     = SF2.F2_DOC		AND SD2.D2_SERIE   = SF2.F2_SERIE	AND SD2.D2_FILIAL = SF2.F2_FILIAL
				JOIN %Table:SA3% SA3 ON SF2.F2_VEND1   = SA3.A3_COD
				JOIN (SELECT A1_FILIAL, A1_COD, A1_LOJA, A1_NREDUZ, A1_MUN, A1_EST, A1_GRPVEN, A1_COD_MUN  
						FROM %Table:SA1% SA1
						WHERE SA1.%notDel% 
						UNION
						SELECT A2_FILIAL, A2_COD, A2_LOJA, A2_NREDUZ, A2_MUN, A2_EST, '' As A1_GRPVEN, A2_COD_MUN A1_COD_MUN 
						FROM %Table:SA2% SA2
						WHERE SA2.%notDel% ) SA1 ON SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA  = SA1.A1_LOJA
				JOIN %Table:SB1% SB1 ON SD2.D2_COD     = SB1.B1_COD
				JOIN %Table:DA4% DA4 ON DAK.DAK_MOTORI = DA4.DA4_COD
				JOIN %Table:SA2% SA2 ON SF2.F2_I_CTRA  = SA2.A2_COD		AND SF2.F2_I_LTRA  = SA2.A2_LOJA
				JOIN %Table:SC5% SC5 ON SC5.C5_FILIAL  = SD2.D2_FILIAL  AND SC5.C5_NUM     = SD2.D2_PEDIDO
				WHERE
		        	DAK.%notDel%
	        	AND SA3.%notDel%
		        AND DAI.%notDel%
				AND SF2.%notDel%
				AND SD2.%notDel%
				AND SB1.%notDel%
				AND DA4.%notDel%
				AND DA3.%notDel%
			 	AND SA2.%notDel%
			 	AND SC5.%notDel%
			 	AND SA2.A2_I_CLASS IN ('T','A','G')			
				AND SD2.D2_CF <> '5927'
				%exp:cFiltro%
				GROUP BY	Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD    WHEN SA2.A2_I_CLASS = 'A' THEN '999999'    END,
							Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END,
							DAK.DAK_COD,DAK.DAK_DATA,SF2.F2_EMISSAO,SD2.D2_CLIENTE,SD2.D2_LOJA,SA1.A1_NREDUZ,SA1.A1_MUN,SA1.A1_EST,SF2.F2_DOC,SF2.F2_SERIE,
							SF2.F2_VALBRUT,SF2.F2_I_FRET,SF2.F2_PBRUTO,DA3.DA3_PLACA,DA3.DA3_I_PLCV,DA3.DA3_I_PLVG,DAK.DAK_I_FRET,DAK.DAK_PESO,
							SD2.D2_FILIAL,SF2.F2_VALMERC,F2_PLIQUI,SA2.A2_I_CLASS,SA2.A2_EST,SA2.A2_I_TPAVE,DA3.DA3_DESC,DA4.DA4_COD,DA4.DA4_NOME,  
							DAI_PEDIDO,DAK_I_OBS,DAK_I_OBS2  
				ORDER BY	SD2.D2_FILIAL,SA2.A2_I_CLASS,A2_COD,DAK_DATA,DAK.DAK_COD,SF2.F2_DOC,SF2.F2_SERIE
				
			EndSql
			
		END REPORT QUERY oSF2FIL_1
		
	EndIf

ElseIf nOrdem == 2 //ORDEM POR PRODUTO

	DEFINE BREAK oBrkFil OF oSF2FIL_2 WHEN oSF2FIL_2:CELL("D2_FILIAL") TITLE {|| "SUBTOTAL FILIAL: " + cNomeFil }
	
	oSF2FIL_2:Enable()
	oSF2_2:Enable()
	oSF2A_2:Enable()
	
	DEFINE FUNCTION FROM oSF2A_2:Cell("D2_QUANT")   FUNCTION SUM BREAK oBrkFil
	DEFINE FUNCTION FROM oSF2A_2:Cell("D2_QTSEGUM") FUNCTION SUM BREAK oBrkFil
 	DEFINE FUNCTION FROM oSF2A_2:Cell("D2_TOTAL")   FUNCTION SUM BREAK oBrkFil
 	DEFINE FUNCTION FROM oSF2A_2:Cell("D2_VALBRUT") FUNCTION SUM BREAK oBrkFil
	DEFINE FUNCTION FROM oSF2A_2:Cell("D2_PRCVEN")  FUNCTION AVERAGE
	DEFINE FUNCTION FROM oSF2A_2:Cell("D2_I_FRET")  FUNCTION SUM BREAK oBrkFil
	
	//====================================================================================================
	// Define query para ordem 02 - produtos
	//====================================================================================================
	BEGIN REPORT QUERY oSF2FIL_2
	
	BeginSql alias "QRY2"
	
		SELECT
			Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD    WHEN SA2.A2_I_CLASS = 'A' THEN '999999'    END AS A2_COD,
			Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END AS A2_NREDUZ,
			SUM(SD2.D2_QUANT)	AS D2_QUANT,
			SUM(SD2.D2_QTSEGUM)	AS D2_QTSEGUM,
			AVG(SD2.D2_PRCVEN)	AS D2_PRCVEN,
			SUM(SD2.D2_TOTAL)	AS D2_TOTAL,
			SUM(SD2.D2_VALBRUT)	AS D2_VALBRUT,
			SUM(SD2.D2_I_FRET)	AS D2_I_FRET,
			SA2.A2_EST,
			SD2.D2_COD,
			SB1.B1_I_DESCD,
			SD2.D2_UM,
			SD2.D2_SEGUM,
			SD2.D2_FILIAL,
			SF2.F2_CARGA,
			SD2.D2_DOC
		FROM %Table:DAK% DAK
		JOIN %Table:DAI% DAI ON DAI.DAI_COD    = DAK.DAK_COD	AND DAI.DAI_FILIAL = DAK.DAK_FILIAL 
		JOIN %Table:DA3% DA3 ON DAK.DAK_CAMINH = DA3.DA3_COD
		JOIN %Table:SF2% SF2 ON SF2.F2_DOC     = DAI.DAI_NFISCA	AND SF2.F2_SERIE   = DAI.DAI_SERIE	AND DAI.DAI_FILIAL = SF2.F2_FILIAL
		JOIN %Table:SD2% SD2 ON SD2.D2_DOC     = SF2.F2_DOC		AND SD2.D2_SERIE   = SF2.F2_SERIE	AND SD2.D2_FILIAL  = SF2.F2_FILIAL
		JOIN (SELECT A1_FILIAL, A1_COD, A1_LOJA, A1_NREDUZ, A1_MUN, A1_EST, A1_GRPVEN, A1_COD_MUN  
				FROM %Table:SA1% SA1
				WHERE SA1.%notDel% 
				UNION
				SELECT A2_FILIAL, A2_COD, A2_LOJA, A2_NREDUZ, A2_MUN, A2_EST, '' As A1_GRPVEN, A2_COD_MUN A1_COD_MUN   
				FROM %Table:SA2% SA2
				WHERE SA2.%notDel% ) SA1 ON SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA  = SA1.A1_LOJA
		JOIN %Table:SA3% SA3 ON SF2.F2_VEND1   = SA3.A3_COD
		JOIN %Table:SB1% SB1 ON SD2.D2_COD     = SB1.B1_COD
		JOIN %Table:DA4% DA4 ON DAK.DAK_MOTORI = DA4.DA4_COD
		JOIN %Table:SA2% SA2 ON SF2.F2_I_CTRA  = SA2.A2_COD		AND SF2.F2_I_LTRA  = SA2.A2_LOJA
		JOIN %Table:SC5% SC5 ON SC5.C5_FILIAL  = SD2.D2_FILIAL  AND SC5.C5_NUM     = SD2.D2_PEDIDO
		WHERE
        	DAK.%notDel%
       	AND SA3.%notDel%
        AND DAI.%notDel%
		AND SF2.%notDel%
		AND SD2.%notDel%
		AND SB1.%notDel%
		AND DA4.%notDel%
		AND DA3.%notDel%
		AND SA2.%notDel%
		AND SC5.%notDel%
		AND SA2.A2_I_CLASS IN ('T','A','G')
		AND SD2.D2_CF <> '5927'
		%exp:cFiltro%
		GROUP BY	Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD    WHEN SA2.A2_I_CLASS = 'A' THEN '999999'    END,
					Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END,SA2.A2_EST,
					SD2.D2_COD,SB1.B1_I_DESCD,SD2.D2_UM,SD2.D2_SEGUM,SD2.D2_FILIAL,SF2.F2_CARGA,SD2.D2_DOC
		ORDER BY	SD2.D2_FILIAL,A2_COD,A2_NREDUZ
		
	EndSql
	
	END REPORT QUERY oSF2FIL_2

ElseIf nOrdem == 3 //ORDEM POR GRUPO DE PRODUTO

	DEFINE BREAK oBrkFil OF oSF2FIL_3 WHEN oSF2FIL_3:CELL("D2_FILIAL") TITLE {|| "SUBTOTAL FILIAL: " + cNomeFil}
	
	oSF2FIL_3:Enable()
	oSF2_3:Enable()
	oSF2A_3:Enable()
	
	DEFINE FUNCTION FROM oSF2A_3:Cell("D2_QUANT")   FUNCTION SUM BREAK oBrkFil
	DEFINE FUNCTION FROM oSF2A_3:Cell("D2_QTSEGUM") FUNCTION SUM BREAK oBrkFil
 	DEFINE FUNCTION FROM oSF2A_3:Cell("D2_TOTAL")   FUNCTION SUM BREAK oBrkFil
 	DEFINE FUNCTION FROM oSF2A_3:Cell("D2_VALBRUT") FUNCTION SUM BREAK oBrkFil
	DEFINE FUNCTION FROM oSF2A_3:Cell("D2_PRCVEN")  FUNCTION AVERAGE
	DEFINE FUNCTION FROM oSF2A_3:Cell("D2_I_FRET")  FUNCTION SUM BREAK oBrkFil
	
	//====================================================================================================
	//Define query para terceira ordem
	//====================================================================================================
	BEGIN REPORT QUERY oSF2FIL_3
	
	BeginSql alias "QRY3"
	
		SELECT
			Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD    WHEN SA2.A2_I_CLASS = 'A' THEN '999999'    END AS A2_COD,
			Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END AS A2_NREDUZ,
			SUM(SD2.D2_QUANT)	AS D2_QUANT,
			SUM(SD2.D2_QTSEGUM)	AS D2_QTSEGUM,
			AVG(SD2.D2_PRCVEN)	AS D2_PRCVEN,
			SUM(SD2.D2_TOTAL)	AS D2_TOTAL,
			SUM(SD2.D2_VALBRUT)	AS D2_VALBRUT,
			SUM(SD2.D2_I_FRET)	AS D2_I_FRET,
			SB1.B1_GRUPO,SD2.D2_UM,SD2.D2_SEGUM,SD2.D2_FILIAL,SA2.A2_EST
		FROM %Table:DAK% DAK
		JOIN %Table:DAI% DAI ON DAI.DAI_COD    = DAK.DAK_COD	AND DAI.DAI_FILIAL = DAK.DAK_FILIAL
		JOIN %Table:DA3% DA3 ON DAK.DAK_CAMINH = DA3.DA3_COD
		JOIN %Table:SF2% SF2 ON SF2.F2_DOC     = DAI.DAI_NFISCA AND SF2.F2_SERIE   = DAI.DAI_SERIE	AND DAI.DAI_FILIAL = SF2.F2_FILIAL
		JOIN %Table:SD2% SD2 ON SD2.D2_DOC     = SF2.F2_DOC		AND SD2.D2_SERIE   = SF2.F2_SERIE	AND SD2.D2_FILIAL  = SF2.F2_FILIAL
		JOIN (SELECT A1_FILIAL, A1_COD, A1_LOJA, A1_NREDUZ, A1_MUN, A1_EST, A1_GRPVEN, A1_COD_MUN  
				FROM %Table:SA1% SA1
				WHERE SA1.%notDel% 
				UNION
				SELECT A2_FILIAL, A2_COD, A2_LOJA, A2_NREDUZ, A2_MUN, A2_EST, '' As A1_GRPVEN, A2_COD_MUN A1_COD_MUN 
				FROM %Table:SA2% SA2
				WHERE SA2.%notDel% ) SA1 ON SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA  = SA1.A1_LOJA
		JOIN %Table:SA3% SA3 ON SF2.F2_VEND1   = SA3.A3_COD
		JOIN %Table:SB1% SB1 ON SD2.D2_COD     = SB1.B1_COD
		JOIN %Table:DA4% DA4 ON DAK.DAK_MOTORI = DA4.DA4_COD
		JOIN %Table:SA2% SA2 ON SF2.F2_I_CTRA  = SA2.A2_COD		AND SF2.F2_I_LTRA  = SA2.A2_LOJA
		JOIN %Table:SC5% SC5 ON SC5.C5_FILIAL  = SD2.D2_FILIAL  AND SC5.C5_NUM     = SD2.D2_PEDIDO
		WHERE
        	DAK.%notDel%
		AND SA3.%notDel%
        AND DAI.%notDel%
		AND SF2.%notDel%
		AND SD2.%notDel%
		AND SB1.%notDel%
		AND DA4.%notDel%
		AND DA3.%notDel%
		AND SA2.%notDel%
		AND SC5.%notDel%
		AND SA2.A2_I_CLASS IN ('T','A','G')
		AND SD2.D2_CF <> '5927'
		%exp:cFiltro%
		GROUP BY	Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD    WHEN SA2.A2_I_CLASS = 'A' THEN '999999'    END,
					Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END,
					SB1.B1_GRUPO,SD2.D2_UM,SD2.D2_SEGUM,SD2.D2_FILIAL,SA2.A2_EST
		ORDER BY	SD2.D2_FILIAL, A2_COD, A2_NREDUZ
		
	EndSql
	
	END REPORT QUERY oSF2FIL_3

ElseIf nOrdem == 4 //ORDEM RESUMIDA

	DEFINE BREAK oBrkFil OF oSF2FIL_4 WHEN oSF2FIL_4:CELL("D2_FILIAL") TITLE {|| "SUBTOTAL FILIAL: " + cNomeFil }
	
	oSF2FIL_4:Enable()
	oSF2_4:Enable()
	
	DEFINE FUNCTION FROM oSF2_4:Cell("D2_I_FRET")	FUNCTION SUM BREAK oBrkFil  NO END Section
	DEFINE FUNCTION FROM oSF2_4:Cell("D2_TOTAL")	FUNCTION SUM BREAK oBrkFil  NO END Section
	DEFINE FUNCTION FROM oSF2_4:Cell("DAK_COD")		FUNCTION SUM BREAK oBrkFil  NO END Section
	DEFINE FUNCTION FROM oSF2_4:Cell("F2_DOC")		FUNCTION SUM BREAK oBrkFil  NO END Section
	DEFINE FUNCTION FROM oSF2_4:Cell("PERCPART")	FUNCTION SUM BREAK oBrkFil  NO END Section
	
	//====================================================================================================
	// Define query para quarta ordem
	//====================================================================================================
	BEGIN REPORT QUERY oSF2FIL_4
	
	BeginSql alias "QRY4"
	
		SELECT 			
			Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD    WHEN SA2.A2_I_CLASS = 'A' THEN '999999'    END AS A2_COD,
			Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END AS A2_NREDUZ,
			SUM(SD2.D2_TOTAL)			AS D2_TOTAL,
			SUM(SD2.D2_I_FRET)			AS D2_I_FRET,
            COUNT(DISTINCT SF2.F2_DOC)	AS F2_DOC,
            COUNT(DISTINCT DAK.DAK_COD)	AS DAK_COD,
            SD2.D2_FILIAL,SA2.A2_EST
		FROM %Table:DAK% DAK
		JOIN %Table:DAI% DAI ON DAI.DAI_COD    = DAK.DAK_COD	AND DAI.DAI_FILIAL = DAK.DAK_FILIAL
		JOIN %Table:DA3% DA3 ON DAK.DAK_CAMINH = DA3.DA3_COD
		JOIN %Table:SF2% SF2 ON SF2.F2_DOC     = DAI.DAI_NFISCA	AND SF2.F2_SERIE   = DAI.DAI_SERIE	AND SF2.F2_FILIAL = DAI.DAI_FILIAL
		JOIN %Table:SD2% SD2 ON SD2.D2_DOC     = SF2.F2_DOC		AND SD2.D2_SERIE   = SF2.F2_SERIE	AND SD2.D2_FILIAL = SF2.F2_FILIAL
		JOIN (SELECT A1_FILIAL, A1_COD, A1_LOJA, A1_NREDUZ, A1_MUN, A1_EST, A1_GRPVEN, A1_COD_MUN 
				FROM %Table:SA1% SA1
				WHERE SA1.%notDel% 
				UNION
				SELECT A2_FILIAL, A2_COD, A2_LOJA, A2_NREDUZ, A2_MUN, A2_EST, '' As A1_GRPVEN, A2_COD_MUN A1_COD_MUN 
				FROM %Table:SA2% SA2
				WHERE SA2.%notDel% ) SA1 ON SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA  = SA1.A1_LOJA
		JOIN %Table:SA3% SA3 ON SF2.F2_VEND1   = SA3.A3_COD
		JOIN %Table:SB1% SB1 ON SD2.D2_COD     = SB1.B1_COD
		JOIN %Table:DA4% DA4 ON DAK.DAK_MOTORI = DA4.DA4_COD
		JOIN %Table:SA2% SA2 ON SF2.F2_I_CTRA  = SA2.A2_COD		AND SF2.F2_I_LTRA  = SA2.A2_LOJA
		JOIN %Table:SC5% SC5 ON SC5.C5_FILIAL  = SD2.D2_FILIAL  AND SC5.C5_NUM     = SD2.D2_PEDIDO
		WHERE						
        	DAK.%notDel%
		AND SA3.%notDel%
        AND DAI.%notDel%
		AND SF2.%notDel%
		AND SD2.%notDel%
		AND SB1.%notDel%
		AND DA4.%notDel%
		AND DA3.%notDel%
		AND SA2.%notDel%
		AND SC5.%notDel%
		AND SA2.A2_I_CLASS IN ('T','A','G')
		AND SD2.D2_CF <> '5927'
		%exp:cFiltro%
		GROUP BY	Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD    WHEN SA2.A2_I_CLASS = 'A' THEN '999999'    END,
					Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END,
					SD2.D2_FILIAL,SA2.A2_EST
		ORDER BY	SD2.D2_FILIAL, D2_I_FRET DESC, A2_COD, A2_NREDUZ
		
	EndSql
	
	END REPORT QUERY oSF2FIL_4
	
	nTotFret := ROMS005TFR("QRY4")

ElseIf nOrdem == 5 //ORDEM POR TRANSPORTADOR

	oSF2FIL_5:Enable()
	oSF2_5:Enable()
	
	DEFINE BREAK oBrkFil OF oSF2FIL_5 WHEN oSF2FIL_5:CELL("D2_FILIAL") TITLE {|| "SUBTOTAL FILIAL: " + cNomeFil}
	
 	DEFINE FUNCTION FROM oSF2_5:Cell("D2_TOTAL")   FUNCTION SUM BREAK oBrkFil NO END Section
 	DEFINE FUNCTION FROM oSF2_5:Cell("D2_VALBRUT") FUNCTION SUM BREAK oBrkFil NO END Section
	
	TRFunction():New(oSF2_5:Cell("D2_QUANT") ,"QUANT","SUM"    ,oBrkFil  ,NIL,NIL,NIL								   															,.F.,.T.)
	TRFunction():New(oSF2_5:Cell("D2_I_FRET"),"FRETE","SUM"    ,oBrkFil  ,NIL,NIL,NIL								   															,.F.,.T.)
	TRFunction():New(oSF2_5:Cell("MEDIA")    ,NIL    ,"ONPRINT",oBrkFil  ,NIL,NIL,{|| (oSF2_5:GetFunction("FRETE"):GetLastValue()/oSF2_5:GetFunction("QUANT"):GetLastValue()) }	,.F.,.T.)
	
	BEGIN REPORT QUERY oSF2FIL_5
	
	BeginSql alias "QRY5"
	
		SELECT
			Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD    WHEN SA2.A2_I_CLASS = 'A' THEN '999999'    END AS A2_COD,
			Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END AS A2_NREDUZ,
			Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_CGC    WHEN SA2.A2_I_CLASS = 'A' THEN '-'         END AS A2_CGC,
			SUM(SD2.D2_QUANT)	AS D2_QUANT,
			SUM(SD2.D2_TOTAL)	AS D2_TOTAL,
			SUM(SD2.D2_VALBRUT)	AS D2_VALBRUT,
			SUM(SD2.D2_I_FRET)	AS D2_I_FRET,
			SD2.D2_FILIAL,
			SA2.A2_EST,
			SA2.A2_I_TPAVE, 
            Case
               WHEN SC5.C5_TPFRETE = 'C' THEN 'CIF'
			   WHEN SC5.C5_TPFRETE = 'F' THEN 'FOB'
			   WHEN SC5.C5_TPFRETE = 'T' THEN 'POR CONTA DE TERCEIROS'
			   WHEN SC5.C5_TPFRETE = 'R' THEN 'POR CONTA DO REMETENTE'
			   WHEN SC5.C5_TPFRETE = 'D' THEN 'POR CONTA DO DESTINATARIO'
			   WHEN SC5.C5_TPFRETE = 'S' THEN 'SEM FRETE'  
			END AS C5_TPFRETE 			
		FROM %Table:DAK% DAK
		JOIN %Table:DAI% DAI ON DAI.DAI_COD    = DAK.DAK_COD	AND DAI.DAI_FILIAL = DAK.DAK_FILIAL 
		JOIN %Table:DA3% DA3 ON DAK.DAK_CAMINH = DA3.DA3_COD
		JOIN %Table:SF2% SF2 ON SF2.F2_DOC     = DAI.DAI_NFISCA	AND SF2.F2_SERIE   = DAI.DAI_SERIE	AND DAI.DAI_FILIAL = SF2.F2_FILIAL
		JOIN %Table:SD2% SD2 ON SD2.D2_DOC     = SF2.F2_DOC		AND SD2.D2_SERIE   = SF2.F2_SERIE	AND SD2.D2_FILIAL  = SF2.F2_FILIAL
		JOIN (SELECT A1_FILIAL, A1_COD, A1_LOJA, A1_NREDUZ, A1_MUN, A1_EST, A1_GRPVEN, A1_COD_MUN 
				FROM %Table:SA1% SA1
				WHERE SA1.%notDel% 
				UNION
				SELECT A2_FILIAL, A2_COD, A2_LOJA, A2_NREDUZ, A2_MUN, A2_EST, '' As A1_GRPVEN,  A2_COD_MUN A1_COD_MUN 
				FROM %Table:SA2% SA2
				WHERE SA2.%notDel% ) SA1 ON SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA  = SA1.A1_LOJA
		JOIN %Table:SA3% SA3 ON SF2.F2_VEND1   = SA3.A3_COD
		JOIN %Table:SB1% SB1 ON SD2.D2_COD     = SB1.B1_COD
		JOIN %Table:DA4% DA4 ON DAK.DAK_MOTORI = DA4.DA4_COD
		JOIN %Table:SA2% SA2 ON SF2.F2_I_CTRA  = SA2.A2_COD		AND SF2.F2_I_LTRA  = SA2.A2_LOJA
		JOIN %Table:SC5% SC5 ON SC5.C5_FILIAL  = SD2.D2_FILIAL  AND SC5.C5_NUM     = SD2.D2_PEDIDO
		WHERE
        	DAK.%notDel% 
		AND SA3.%notDel%
        AND DAI.%notDel%
		AND SF2.%notDel%
		AND SD2.%notDel%
		AND SB1.%notDel%
		AND DA4.%notDel%
		AND DA3.%notDel%
		AND SA2.%notDel%
		AND SC5.%notDel%
		AND SA2.A2_I_CLASS IN ('T','A','G')
		AND SD2.D2_CF <> '5927'
		%exp:cFiltro%
		GROUP BY	Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD    WHEN SA2.A2_I_CLASS = 'A' THEN '999999'    END,
					Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END,
					Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_CGC    WHEN SA2.A2_I_CLASS = 'A' THEN '-'         END,
					SD2.D2_FILIAL,
					SA2.A2_EST,
					A2_I_TPAVE, 
				    Case
                       WHEN SC5.C5_TPFRETE = 'C' THEN 'CIF'
			           WHEN SC5.C5_TPFRETE = 'F' THEN 'FOB'
			           WHEN SC5.C5_TPFRETE = 'T' THEN 'POR CONTA DE TERCEIROS'
			           WHEN SC5.C5_TPFRETE = 'R' THEN 'POR CONTA DO REMETENTE'
			           WHEN SC5.C5_TPFRETE = 'D' THEN 'POR CONTA DO DESTINATARIO'
			           WHEN SC5.C5_TPFRETE = 'S' THEN 'SEM FRETE'  
			        END  
		ORDER BY	SD2.D2_FILIAL, A2_COD, A2_NREDUZ
		
	EndSql
	
	END REPORT QUERY oSF2FIL_5
	
EndIf

If nOrdem = 1 //ORDEM POR CARGA

	oSF2_1:SetParentQuery()
	oSF2_1:SetParentFilter({|cParam| QRY1->D2_FILIAL == cParam },{|| QRY1->D2_FILIAL })

	oSF2_1A:SetParentQuery()
	oSF2_1A:SetParentFilter({|cParam| QRY1->A2_I_CLASS + QRY1->A2_COD == cParam },{|| QRY1->A2_I_CLASS + QRY1->A2_COD })

	oSF2_1B:SetParentQuery()                                                                                      
	oSF2_1B:SetParentFilter({|cParam| IIf(ValType(QRY1->DAK_DATA) == 'D',DToS(QRY1->DAK_DATA),QRY1->DAK_DATA) + QRY1->DAK_COD == cParam },{|| IIf(ValType(QRY1->DAK_DATA) == 'D',DToS(QRY1->DAK_DATA),QRY1->DAK_DATA) + QRY1->DAK_COD })

	If MV_PAR19 == 2
		oSF2A_1:SetParentQuery()           
		oSF2A_1:SetParentFilter({|cParam| QRY1->F2_DOC+QRY1->F2_SERIE == cParam },{|| QRY1->F2_DOC+QRY1->F2_SERIE })
	EndIf
	
	oSF2FIL_1:Print(.T.)
	
ElseIf nOrdem == 2 //ORDEM POR PRODUTO

	oSF2_2:SetParentQuery()
	oSF2_2:SetParentFilter( {|cParam| QRY2->D2_FILIAL == cParam } , {|| QRY2->D2_FILIAL } )
	
	oSF2A_2:SetParentQuery()
	oSF2A_2:SetParentFilter( {|cParam| QRY2->A2_COD == cParam } , {|| QRY2->A2_COD } )
	oSF2FIL_2:Print(.T.)
	
ElseIf nOrdem == 3 //ORDEM POR GRUPO DE PRODUTO

	oSF2_3:SetParentQuery()
	oSF2_3:SetParentFilter( {|cParam| QRY3->D2_FILIAL == cParam } , {|| QRY3->D2_FILIAL } )
	
	oSF2A_3:SetParentQuery()
	oSF2A_3:SetParentFilter( {|cParam| QRY3->A2_COD == cParam } , {|| QRY3->A2_COD } )
	oSF2FIL_3:Print(.T.)
	
ElseIf nOrdem == 4 //ORDEM RESUMIDA

	oSF2_4:SetParentQuery()
	oSF2_4:SetParentFilter( {|cParam| QRY4->D2_FILIAL == cParam } , {|| QRY4->D2_FILIAL } )
	
	oSF2FIL_4:Print(.T.)
	
ElseIf nOrdem == 5 //ORDEM POR TRANSPORTADOR

	oSF2_5:SetParentQuery()
	oSF2_5:SetParentFilter( {|cParam| QRY5->D2_FILIAL == cParam } , {|| QRY5->D2_FILIAL } )
	
	oSF2FIL_5:Print(.T.)
	
EndIf

Return

/*
===============================================================================================================================
Programa--------: ROMS005TFR
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Verifica o cadastro dos grupos de perguntas (SX1)
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS005TFR(cQry)

Local nRet	:= 0 
Local aArea	:= FWGetArea()

&(cQry)->( DBGoTop() )
While &(cQry)->( !Eof() )

	nRet += &( cQry + "->D2_I_FRET" )
	
&(cQry)->( DBSkip() )
EndDo

&(cQry)->( DBGoTop() )

FWRestArea(aArea)

Return( nRet )

/*
===============================================================================================================================
Programa--------: ROMS005UPC
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Atualiza variaveis com ultimo valor impresso do totalizador
===============================================================================================================================
Parametros------: nContNF , nContCarga
===============================================================================================================================
Retorno---------: cRet
===============================================================================================================================
*/
Static Function ROMS005UPC( nContNF , nContCarga )

Local cRet := " Total de NF's: "+ Transform( nContNF - nAuxNF , "@E 999" ) +" Total de Cargas : "+ Transform( nContCarga - nAuxCarga , "@E 999" )

nAuxNF		:= nContNF
nAuxCarga	:= nContCarga

Return( cRet )
      
/*
===============================================================================================================================
Programa--------: ROMS005GRP
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Relatorio grafico dentro do TReport para imprimir as ordens de: Grupo de Produto X UF e Produto X UF.
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function ROMS005GRP()
/*
Private oFont10
Private oFont10b
Private oFont12
Private oFont12b
Private oFont16b
Private oFont14
Private oFont14b*/

Private oPrint

Private nPagina     := 1

Private nLinha      := 0100
//Private nLinhaInic  := 0100
Private nColInic    := 0030
Private nColFinal   := 3360 
Private nqbrPagina  := 2200 
Private nLinInBox   
Private nSaltoLinha := 50      
Private nAjustAlt   := 10

Private oBrush      := TBrush():New( ,CLR_LIGHTGRAY)

Define Font oFont10    Name "Courier New"       Size 0,-08       // Tamanho 14    
Define Font oFont10b   Name "Courier New"       Size 0,-08 Bold  // Tamanho 14 
Define Font oFont12    Name "Courier New"       Size 0,-10       // Tamanho 12
Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito  
//Define Font oFont14    Name "Courier New"       Size 0,-10       // Tamanho 14
//Define Font oFont14b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 14         
//Define Font oFont14Pr  Name "Courier New"       Size 0,-12       // Tamanho 14
Define Font oFont14Prb Name "Courier New"       Size 0,-12 Bold  // Tamanho 14 Negrito
Define Font oFont16b   Name "Helvetica"         Size 0,-14 Bold  // Tamanho 16 Negrito  

If MV_PAR26 == 1 // Impressão
   oPrint:= TMSPrinter():New( "GRUPO DE PRODUTO X UF" ) ////  TMSPRINTER()   //////////////////////////////////////////
   oPrint:SetPaperSize(9)	// Seta para papel A4
EndIf

//Seta variaveis de controle de tamanho do relatorio de acordo com o tipo da pagina(Paisagem ou Retrato)
//Grupo de Produto X UF ou Produto X UF	
If nOrdem == 6 .Or. nOrdem == 7 //"6-Grupo de Produto x UF","7-Produto x UF",
   If MV_PAR26 == 1 // Impressão     
	  oPrint:SetLandscape() 	// Paisagem    
	  nColFinal   := 3360
	  nqbrPagina  := 2200
   EndIf
//Fechamento do Frete
ElseIf nOrdem == 8 .Or. nOrdem == 9 .Or. nOrdem == 10 //"8-Fechamento x Produto","9-Fechamento x Sub-Grupo","10-Veiculo"
   If MV_PAR26 == 1 // Impressão	
	  oPrint:SetPortrait() 	// Retrato
	  nColFinal   := 2360
	  nqbrPagina  := 3300
   EndIf
EndIf

If MV_PAR26 == 1 // Impressão
   /// startando a impressora
   oPrint:Say( 0 , 0 , " " , oFont12 , 100 )
   oPrint:StartPage()
EndIf

If MV_PAR26 == 1  // Impressão
   //0 - para nao imprimir a numeracao de pagina na emissao da pagina de parametros
   ROMS005C(0)
   ROMS005Z(oPrint)
EndIf

If nOrdem == 6 .Or. nOrdem == 7	//"6-Grupo de Produto x UF","7-Produto x UF"  

	Processa( {|| ROMD005O() } ) 
	
ElseIf nOrdem == 8 .Or. nOrdem == 9 //"8-Fechamento x Produto","9-Fechamento x Sub-Grupo"

	Processa( {|| ROMS0058() } ) 
	
ElseIf nOrdem == 10//"10-Veiculo"
	
	Processa( {|| ROMS0507() } )  
	
ElseIf nOrdem == 11//"11-AT&M"
	
	Processa( {|| ROMS005D() } )  

EndIf


If MV_PAR26 == 1  // Impressão     
   oPrint:EndPage()	// Finaliza a Pagina.
   oPrint:Preview()	// Visualiza antes de Imprimir.
EndIf

Return

/*
===============================================================================================================================
Programa--------: ROMS005D
Autor-----------: Josué Prestes
Data da Criacao-: 23/09/2016
===============================================================================================================================
Descrição-------: RELATORIO DE FRETE POR TRANSPORTADOR (ATM)
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS005D()

Local nCountRec	:= 0
Local cQuery	:= ""       
Local _aCampos := {} // Array com os campos da tabela temporária.
Local _aCabecalho := {} // Array com o cabeçalho das colunas do relatório.
Local _cTitulo

   ProcRegua(2)

   //Filtro indicados anteriormente
   cFiltro := SubStr( cFiltro , 2 , Len(cFiltro) )

   cQuery := " SELECT "
   cQuery +=     " F2_FILIAL  ,"
   cQuery +=     " F2_EMISSAO ,"
   cQuery +=     " F2_DOC     ,"
   cQuery +=     " F2_SERIE   ,"
   cQuery +=     " ZZM_EST    ,"
   cQuery +=     " F2_EST     ,"
   cQuery +=     " F2_I_PLACA ,"
   cQuery +=     " F2_DAUTNFE ,"
   cQuery +=     " F2_HAUTNFE ,"
   cQuery +=     " A1_CGC     ,"
   cQuery +=     " A1_EST     ,"
   cQuery +=     " F2_I_CTRA  ,"
   cQuery +=     " F2_I_LTRA  ,"
   cQuery +=     " F2_I_FRET  ,"
   cQuery +=     " A2_CGC     ,"
   cQuery +=     " A2_NOME    ,"
   cQuery +=     " A2_EST     ,"

   cQuery +=     " Case "
   cQuery +=     "    WHEN SA2.A2_I_TPAVE = 'E' THEN 'EMBARCADOR' "
   cQuery +=     " 	  WHEN SA2.A2_I_TPAVE = 'T' THEN 'TRANSPORTADOR' "
   cQuery +=     " 	  WHEN SA2.A2_I_TPAVE = ' ' THEN ' ' "
   cQuery +=    " END AS A2_I_TPAVE, " 
   
   cQuery +=     " SUM(D2_VALBRUT) TOTAL, "
   cQuery +=     " Case "
   cQuery +=     "    WHEN SC5.C5_TPFRETE = 'C' THEN 'CIF' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'F' THEN 'FOB' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'T' THEN 'POR CONTA DE TERCEIROS' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'R' THEN 'POR CONTA DO REMETENTE' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'D' THEN 'POR CONTA DO DESTINATARIO' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'S' THEN 'SEM FRETE' "  
   cQuery +=    " END AS C5_TPFRETE " 
   
   cQuery += " FROM "+ RetSqlName("DAK") +" DAK "
   cQuery += " JOIN "+ RetSqlName("DAI") +" DAI ON DAI.DAI_COD    = DAK.DAK_COD    AND DAI.DAI_FILIAL = DAK.DAK_FILIAL "
   cQuery += " JOIN "+ RetSqlName("DA3") +" DA3 ON DAK.DAK_CAMINH = DA3.DA3_COD "
   cQuery += " JOIN "+ RetSqlName("SF2") +" SF2 ON SF2.F2_DOC     = DAI.DAI_NFISCA AND SF2.F2_SERIE   = DAI.DAI_SERIE AND DAI.DAI_FILIAL = SF2.F2_FILIAL "
   cQuery += " JOIN "+ RetSqlName("ZZM") +" ZZM ON ZZM.ZZM_CODIGO = SF2.F2_FILIAL "
   cQuery += " JOIN "+ RetSqlName("SD2") +" SD2 ON SD2.D2_DOC     = SF2.F2_DOC     AND SD2.D2_SERIE   = SF2.F2_SERIE  AND SD2.D2_FILIAL  = SF2.F2_FILIAL "
   cQuery += " JOIN "+ RetSqlName("SA3") +" SA3 ON SF2.F2_VEND1   = SA3.A3_COD " 
	cQuery += " JOIN (SELECT A1_FILIAL, A1_COD, A1_LOJA, A1_NREDUZ, A1_MUN, A1_EST, A1_CGC, A1_GRPVEN, A1_COD_MUN " 
	cQuery += " 		FROM "+ RetSqlName("SA1") +" SA1 "
	cQuery += " 		WHERE SA1.D_E_L_E_T_ = ' ' "
	cQuery += " 		UNION
	cQuery += " 		SELECT A2_FILIAL, A2_COD, A2_LOJA, A2_NREDUZ, A2_MUN, A2_EST, A2_CGC, '' As A1_GRPVEN, A2_COD_MUN A1_COD_MUN " 
	cQuery += " 		FROM "+ RetSqlName("SA2") +" SA2 "
	cQuery += " 		WHERE SA2.D_E_L_E_T_ = ' '  ) SA1 ON  SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA  = SA1.A1_LOJA "
   cQuery += " JOIN "+ RetSqlName("SB1") +" SB1 ON SD2.D2_COD     = SB1.B1_COD "
   cQuery += " JOIN "+ RetSqlName("SBM") +" SBM ON SB1.B1_GRUPO   = SBM.BM_GRUPO "
   cQuery += " JOIN "+ RetSqlName("DA4") +" DA4 ON DAK.DAK_MOTORI = DA4.DA4_COD "
   cQuery += " JOIN "+ RetSqlName("SA2") +" SA2 ON SF2.F2_I_CTRA  = SA2.A2_COD     AND SF2.F2_I_LTRA  = SA2.A2_LOJA "
   cQuery += " JOIN "+ RetSqlName("SC5") +" SC5 ON SC5.C5_FILIAL  = SD2.D2_FILIAL  AND SC5.C5_NUM     = SD2.D2_PEDIDO"
   
   cQuery += " WHERE "
   cQuery += " SA2.A2_I_CLASS IN ('T','A','G') "             
   cQuery += " AND SD2.D2_CF <> '5927'  "
   cQuery += " AND DAK.D_E_L_E_T_ = ' ' "
   cQuery += " AND DAI.D_E_L_E_T_ = ' ' "
   cQuery += " AND DA3.D_E_L_E_T_ = ' ' "
   cQuery += " AND DA4.D_E_L_E_T_ = ' ' "
   cQuery += " AND SF2.D_E_L_E_T_ = ' ' "
   cQuery += " AND SD2.D_E_L_E_T_ = ' ' "
   cQuery += " AND SB1.D_E_L_E_T_ = ' ' "
   cQuery += " AND SA2.D_E_L_E_T_ = ' ' "
   cQuery += " AND SA3.D_E_L_E_T_ = ' ' "
   cQuery += " AND SBM.D_E_L_E_T_ = ' ' "
   cQuery += " AND ZZM.D_E_L_E_T_ = ' ' "
   cQuery += " AND SC5.D_E_L_E_T_ = ' ' "
   cQuery += cFiltro
 
   cQuery += " GROUP BY F2_FILIAL, F2_EMISSAO,F2_DOC, F2_SERIE, ZZM_EST, F2_EST, F2_I_PLACA, F2_DAUTNFE, F2_HAUTNFE, A1_CGC, A1_EST, F2_I_CTRA, F2_I_LTRA,F2_I_FRET, A2_CGC, A2_NOME, A2_EST, A2_I_TPAVE "

   cQuery +=     ", Case "
   cQuery +=     "    WHEN SC5.C5_TPFRETE = 'C' THEN 'CIF' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'F' THEN 'FOB' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'T' THEN 'POR CONTA DE TERCEIROS' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'R' THEN 'POR CONTA DO REMETENTE' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'D' THEN 'POR CONTA DO DESTINATARIO' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'S' THEN 'SEM FRETE' "  
   cQuery +=    " END " 

   cQuery += " ORDER BY SF2.F2_FILIAL,SF2.F2_DOC"  
   

   //Para que nao ocorra erro, quando duas pessoas acessarem o relatorio simultaneamente
   If Select("TMPORDEM") > 0 
      TMPORDEM->( DBCloseArea() )
   EndIf
   
   IncProc( "SELECT: Lendo dados que serão gerados em Excel, favor aguardar..." )

   DBUseArea( .T. , "TOPCONN" , TCGenQry(,,cQuery) , 'TMPORDEM' , .F. , .T. )

   IncProc( "SELECT: Lendo dados que serão gerados em Excel, favor aguardar..." )
   
   COUNT TO nCountRec

   DBSelectArea("TMPORDEM")
   TMPORDEM->( DBGoTop() )

   ProcRegua(nCountRec)
   cTot:=AllTrim(Str(nCountRec))
   nConta:=0     
      
// If MV_PAR26 == 2 // Relatório em Excel  //COMO SÓ imprimi em excel tanto faz o parametro MV_PAR26

    SD2->(DBSetOrder(3)) // ITENS DA NOTA FISCAL DE SAÍDA   // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
   
     	While !( TMPORDEM->( Eof() ) )
           nConta++
           IncProc( 'Lendo DOC: '+TMPORDEM->F2_DOC+" - "+AllTrim(Str(nConta))+" de "+cTot )
		   
		   _cArmazens:=""
           SD2->(DBSeek(TMPORDEM->F2_FILIAL+TMPORDEM->F2_DOC+TMPORDEM->F2_SERIE)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM 
           While ! SD2->(Eof()) .And. SD2->D2_FILIAL+SD2->D2_DOC+SD2->D2_SERIE == TMPORDEM->F2_FILIAL+TMPORDEM->F2_DOC+TMPORDEM->F2_SERIE
              If !SD2->D2_LOCAL $ _cArmazens
                 _cArmazens+=AllTrim(SD2->D2_LOCAL)+", "
			  EndIf
              SD2->(DBSkip())
           EndDo   
           _cArmazens:=LEFT(_cArmazens,Len(_cArmazens)-2)

      		aAdd( _aCampos ,{SubStr(TMPORDEM->F2_EMISSAO,7,2)+"/"+SubStr(TMPORDEM->F2_EMISSAO,5,2)+"/"+SubStr(TMPORDEM->F2_EMISSAO,1,4),;
      				         TMPORDEM->F2_DOC,;
      				         TMPORDEM->F2_SERIE,;
      				         TMPORDEM->ZZM_EST,;
      				         TMPORDEM->F2_EST,;
                             TMPORDEM->F2_I_PLACA,;
                             SubStr(TMPORDEM->F2_DAUTNFE,7,2)+"/"+SubStr(TMPORDEM->F2_DAUTNFE,5,2)+"/"+SubStr(TMPORDEM->F2_DAUTNFE,1,4),;
                             TMPORDEM->F2_HAUTNFE,;
                             TMPORDEM->A1_CGC    ,;
                             TMPORDEM->A1_EST    ,;
                             TMPORDEM->F2_I_CTRA ,;
                             TMPORDEM->F2_I_LTRA ,;
                             TMPORDEM->A2_CGC    ,;
                             TMPORDEM->A2_NOME   ,;
                             TMPORDEM->A2_EST    ,;
                             TMPORDEM->TOTAL     ,;
							 TMPORDEM->C5_TPFRETE,; 
							 TMPORDEM->F2_I_FRET,; 
							 _cArmazens,;// Array com os campos da tabela temporária.
							 TMPORDEM->A2_I_TPAVE} )  

      		TMPORDEM->( DBSkip() )
      		
      	EndDo
      
      _aCabecalho := {} 
       
      aAdd(_aCabecalho,"DATA EMISSAO" ) 
      aAdd(_aCabecalho,"DOCUMENTO") 
      aAdd(_aCabecalho,"SERIE") 
      aAdd(_aCabecalho,"UF ORIGEM" ) 
      aAdd(_aCabecalho,"UF DESTINO" ) 
      aAdd(_aCabecalho,"PLACA VEICULO") 
      aAdd(_aCabecalho,"DATA EMBARQUE" ) 
      aAdd(_aCabecalho,"HORA EMBARQUE") 
      aAdd(_aCabecalho,"CNPJ CLIENTE" ) 
      aAdd(_aCabecalho,"UF CLIENTE" ) 
      aAdd(_aCabecalho,"CODIGO TRANSPORTADOR" )
      aAdd(_aCabecalho,"LOJA TRANSPORTADOR" ) 
      aAdd(_aCabecalho,"CNPJ TRANSPORTADOR" ) 
      aAdd(_aCabecalho,"NOME TRANSPORTADOR" ) 
      aAdd(_aCabecalho,"UF TRANSPORTADOR" ) 
      aAdd(_aCabecalho,"VALOR MERCADORIA") 
	  aAdd(_aCabecalho,"TIPO DE FRETE") 
	  aAdd(_aCabecalho,"VALOR DO FRETE") 
	  aAdd(_aCabecalho,"Armazens") 
	  aAdd(_aCabecalho,"TIPO AVERBACAO CARGA") 
            
      _cTitulo := "RELATORIO DE FRETE POR TRANSPORTADOR (ATM)"
      
      If Len(_aCampos) = 0
     	 ALERT("Não foram localizados registros!")
      Else          //_cTitAux ,_aHeader    , _aCols  , _lMaxSiz , _nTipo , _cMsgTop
      	 U_ITLISTBOX( _cTitulo ,_aCabecalho , _aCampos,    .T.   ,        , _cTitulo+" - Ordem de "+ aOrd[nOrdem] +" de: "+ DToC(MV_PAR02) +" Ate "+ DToC(MV_PAR03)+" [ROM005]")
      EndIf 
    
//  EndIf  
 
TMPORDEM->( DBCloseArea() )

Return
         
/*
===============================================================================================================================
Programa--------: ROMD005O
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: imprimir as ordens de: Grupo de Produto X UF e Produto X UF
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMD005O()

Local nCountRec	:= 0
Local cQuery	:= ""       
Local aFilial	:= {} //Para controlar a quebra por Filial do Relatorio
Local aProduto	:= {} //Para controla a quebra de grupo de produto/Produto por Filial
Local nPosFilial
Local nPosProdut

//Variaveis para controle dos totalizadores por Produto
Local nTotqtde1	:= 0
Local nTotqtde2	:= 0
Local nTotvlrTo	:= 0
Local nTotvlrBr	:= 0 
Local nTotvlrFr	:= 0

//Variaveis para controle dos totalizadores por Filial 
Local nFTotqtde1:= 0
Local nFTotqtde2:= 0
Local nFTotvlrTo:= 0
Local nFTotvlrBr:= 0 
Local nFTotvlrFr:= 0 

Local _aCampos := {} // Array com os campos da tabela temporária.
Local _cDir := GetTempPath()  // Diretório de Geração das planilhas.
Local _cArq := "_"+DToS(Date())+"_"+StrTran(Time(),":","")+".xml"  // Nome da planilha a ser gerada.   
Local _aCabecalho := {} // Array com o cabeçalho das colunas do relatório.
Local _cTitulo

Begin Sequence                   
   //Filtro indicados anteriormente
   cFiltro := SubStr( cFiltro , 2 , Len(cFiltro) )

   cQuery := " SELECT "
   cQuery +=     " SUM(SD2.D2_QUANT)   AS D2_QUANT  ,"
   cQuery +=     " SUM(SD2.D2_QTSEGUM) AS D2_QTSEGUM,"
   cQuery +=     " SUM(SD2.D2_TOTAL)   AS D2_TOTAL  ,"
   cQuery +=     " SUM(SD2.D2_VALBRUT) AS D2_VALBRUT,"
   cQuery +=     " SUM(SD2.D2_I_FRET)  AS D2_I_FRET ,"
   cQuery +=     " Case "
   cQuery +=     "    WHEN SC5.C5_TPFRETE = 'C' THEN 'CIF' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'F' THEN 'FOB' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'T' THEN 'POR CONTA DE TERCEIROS' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'R' THEN 'POR CONTA DO REMETENTE' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'D' THEN 'POR CONTA DO DESTINATARIO' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'S' THEN 'SEM FRETE' "  
   cQuery +=     "END AS C5_TPFRETE, " 

   //Grupo de Produto X UF
   If nOrdem == 6

	  cQuery += " SBM.BM_GRUPO PRODUTO,"
	  cQuery += " SBM.BM_DESC DESCR,"
	  cQuery += " SD2.D2_UM,"
	  cQuery += " SD2.D2_SEGUM,"
	  cQuery += " SD2.D2_FILIAL,"
	  cQuery += " SA1.A1_EST " 
    
   //Produto X UF
   ElseIf nOrdem == 7

	  cQuery += " SB1.B1_COD PRODUTO,"
	  cQuery += " SB1.B1_I_DESCD DESCR,"
	  cQuery += " SD2.D2_UM,"
	  cQuery += " SD2.D2_SEGUM,"
	  cQuery += " SD2.D2_FILIAL,"
	  cQuery += " SA1.A1_EST "
   	
   EndIf

   cQuery += " FROM "+ RetSqlName("DAK") +" DAK "
   cQuery += " JOIN "+ RetSqlName("DAI") +" DAI ON DAI.DAI_COD    = DAK.DAK_COD    AND DAI.DAI_FILIAL = DAK.DAK_FILIAL "
   cQuery += " JOIN "+ RetSqlName("DA3") +" DA3 ON DAK.DAK_CAMINH = DA3.DA3_COD "
   cQuery += " JOIN "+ RetSqlName("SF2") +" SF2 ON SF2.F2_DOC     = DAI.DAI_NFISCA AND SF2.F2_SERIE   = DAI.DAI_SERIE AND DAI.DAI_FILIAL = SF2.F2_FILIAL "
   cQuery += " JOIN "+ RetSqlName("SD2") +" SD2 ON SD2.D2_DOC     = SF2.F2_DOC     AND SD2.D2_SERIE   = SF2.F2_SERIE  AND SD2.D2_FILIAL  = SF2.F2_FILIAL "
   cQuery += " JOIN (SELECT A1_FILIAL, A1_COD, A1_LOJA, A1_NREDUZ, A1_MUN, A1_EST, A1_CGC, A1_GRPVEN, A1_COD_MUN "  
   cQuery += " 		FROM "+ RetSqlName("SA1") +" SA1 "
   cQuery += " 		WHERE SA1.D_E_L_E_T_ = ' ' "
   cQuery += " 		UNION
   cQuery += " 		SELECT A2_FILIAL, A2_COD, A2_LOJA, A2_NREDUZ, A2_MUN, A2_EST, A2_CGC, '' As A1_GRPVEN, A2_COD_MUN A1_COD_MUN "  
   cQuery += " 		FROM "+ RetSqlName("SA2") +" SA2 "
   cQuery += " 		WHERE SA2.D_E_L_E_T_ = ' '  ) SA1 ON  SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA  = SA1.A1_LOJA "
   cQuery += " JOIN "+ RetSqlName("SA3") +" SA3 ON SF2.F2_VEND1   = SA3.A3_COD "
   cQuery += " JOIN "+ RetSqlName("SB1") +" SB1 ON SD2.D2_COD     = SB1.B1_COD "
   cQuery += " JOIN "+ RetSqlName("SBM") +" SBM ON SB1.B1_GRUPO   = SBM.BM_GRUPO "
   cQuery += " JOIN "+ RetSqlName("DA4") +" DA4 ON DAK.DAK_MOTORI = DA4.DA4_COD "
   cQuery += " JOIN "+ RetSqlName("SA2") +" SA2 ON SF2.F2_I_CTRA  = SA2.A2_COD     AND SF2.F2_I_LTRA  = SA2.A2_LOJA "
   cQuery += " JOIN "+ RetSqlName("SC5") +" SC5 ON SC5.C5_FILIAL  = SD2.D2_FILIAL  AND SC5.C5_NUM     = SD2.D2_PEDIDO"
   
   cQuery += " WHERE "
   cQuery +=     " DAK.D_E_L_E_T_ = ' ' "
   cQuery += " AND DAI.D_E_L_E_T_ = ' ' "  
   cQuery += " AND DA3.D_E_L_E_T_ = ' ' "
   cQuery += " AND SF2.D_E_L_E_T_ = ' ' "
   cQuery += " AND SD2.D_E_L_E_T_ = ' ' "
   cQuery += " AND SA3.D_E_L_E_T_ = ' ' "
   cQuery += " AND SB1.D_E_L_E_T_ = ' ' "
   cQuery += " AND SBM.D_E_L_E_T_ = ' ' "
   cQuery += " AND DA4.D_E_L_E_T_ = ' ' "
   cQuery += " AND SA2.D_E_L_E_T_ = ' ' "
   cQuery += " AND SC5.D_E_L_E_T_ = ' ' "
   cQuery += " AND SA2.A2_I_CLASS IN ('T','A','G') "
   cQuery += " AND SD2.D2_CF <> '5927' "
   cQuery += cFiltro
   cQuery += "GROUP BY" 

   If nOrdem == 6
      cQuery += " SD2.D2_FILIAL,SBM.BM_GRUPO,SA1.A1_EST,SBM.BM_DESC,SD2.D2_UM,SD2.D2_SEGUM "
   ElseIf nOrdem == 7
      cQuery += " SD2.D2_FILIAL,SB1.B1_COD,SA1.A1_EST,SB1.B1_I_DESCD,SD2.D2_UM,SD2.D2_SEGUM "	
   EndIf
   
   cQuery +=     " ,Case "
   cQuery +=     "    WHEN SC5.C5_TPFRETE = 'C' THEN 'CIF' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'F' THEN 'FOB' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'T' THEN 'POR CONTA DE TERCEIROS' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'R' THEN 'POR CONTA DO REMETENTE' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'D' THEN 'POR CONTA DO DESTINATARIO' "
   cQuery +=     " 	  WHEN SC5.C5_TPFRETE = 'S' THEN 'SEM FRETE' "  
   cQuery +=     " END " 

   cQuery += " ORDER BY SD2.D2_FILIAL,PRODUTO,DESCR,D2_QUANT "

   //Para que nao ocorra erro, quando duas pessoas acessarem o relatorio simultaneamente
   If Select("TMPORDEM") > 0 
      TMPORDEM->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TCGenQry(,,cQuery) , 'TMPORDEM' , .F. , .T. )

   COUNT TO nCountRec

   DBSelectArea("TMPORDEM")
   TMPORDEM->( DBGoTop() )

   ProcRegua(nCountRec)
 
   If MV_PAR26 == 2 // Relatório em Excel                     
      IncProc( "Os dados estão sendo gerados em Excel, favor aguardar..." )

      _aCampos := {'TMPORDEM->D2_FILIAL','TMPORDEM->PRODUTO','TMPORDEM->DESCR','TMPORDEM->A1_EST','TMPORDEM->D2_QUANT','TMPORDEM->D2_UM','TMPORDEM->D2_QTSEGUM',;
                   'TMPORDEM->D2_SEGUM','TMPORDEM->D2_TOTAL/TMPORDEM->D2_QUANT','TMPORDEM->D2_TOTAL','TMPORDEM->D2_VALBRUT','TMPORDEM->D2_I_FRET', 'TMPORDEM->C5_TPFRETE'} // Array com os campos da tabela temporária.

      _aCabecalho := {} // Array com o cabeçalho das colunas do relatório. 
      // Alinhamento( 1-Left,2-Center,3-Right )
      // Formatação( 1-General,2-Number,3-Monetário,4-DateTime )
      //                Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?  
      aAdd(_aCabecalho,{"FILIAL"           ,1           ,1         ,.F.})    
      aAdd(_aCabecalho,{"PRODUTO"          ,1           ,1         ,.F.}) 
  	  aAdd(_aCabecalho,{"DESC PRODUTO"     ,1           ,1         ,.F.}) 	  
      aAdd(_aCabecalho,{"ESTADO"           ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"QUANTIDADE"       ,3           ,3         ,.F.}) 
      aAdd(_aCabecalho,{"1a U.M."          ,2           ,2         ,.F.}) 
      aAdd(_aCabecalho,{"QUANTIDADE 2 U.M.",3           ,3         ,.F.}) 
      aAdd(_aCabecalho,{"2a U.M."          ,2           ,2         ,.F.}) 
      aAdd(_aCabecalho,{"VALOR UNITARIO"   ,3           ,3         ,.F.}) 
      aAdd(_aCabecalho,{"VALOR TOTAL"      ,3           ,3         ,.F.}) 
      aAdd(_aCabecalho,{"VALOR BRUTO"      ,3           ,3         ,.F.}) 
      aAdd(_aCabecalho,{"VALOR FRETE"      ,3           ,3         ,.F.}) 
      aAdd(_aCabecalho,{"TIPO DE FRETE"    ,1           ,1         ,.F.}) 

      If nOrdem == 6 //Grupo de Produto X UF
         _cArq := "Grupo_de_Produto_X_UF"+_cArq // Nome da planilha a ser gerada.   
         _cTitulo := "RELATÓRIO DE FRETE POR TRANSPORTADOR (GRUPO DE PRODUTOS X UF)" 
      Else //Produto X UF
         _cArq := "Produto_X_UF"+_cArq // Nome da planilha a ser gerada.   
         _cTitulo := "RELATÓRIO DE FRETE POR TRANSPORTADOR (PRODUTOS X UF)"
      EndIf
      
      U_ITGEREXCEL(_cArq,_cDir,_cTitulo,"Relatorio",_aCabecalho,,.T.,"TMPORDEM",_aCampos)         
      Break                              
    
   ElseIf MV_PAR26 == 3 // Relatório em Excel  AT&M
  
      IncProc( "Os dados estão sendo gerados em Excel, favor aguardar..." )
      _aCampos := {'TMPORDEM->D2_FILIAL','TMPORDEM->PRODUTO','TMPORDEM->A1_EST','TMPORDEM->D2_QUANT','TMPORDEM->D2_UM','TMPORDEM->D2_QTSEGUM',;
                   'TMPORDEM->D2_SEGUM','TMPORDEM->D2_TOTAL/TMPORDEM->D2_QUANT','TMPORDEM->D2_TOTAL','TMPORDEM->D2_VALBRUT','TMPORDEM->D2_I_FRET','TMPORDEM->C5_TPFRETE'} // Array com os campos da tabela temporária.
      
      _aCabecalho := {} // Array com o cabeçalho das colunas do relatório. 
      // Alinhamento( 1-Left,2-Center,3-Right )
      // Formatação( 1-General,2-Number,3-Monetário,4-DateTime )
      //                Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?  
      aAdd(_aCabecalho,{"FILIAL"           ,1           ,1         ,.F.})    
      aAdd(_aCabecalho,{"DATA EMISSAO"     ,1           ,4         ,.F.}) 
      aAdd(_aCabecalho,{"DOCUMENTO"        ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"SERIE"            ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"UF ORIGEM"        ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"UF DESTINO"       ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"PLACA VEICULO"    ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"DATA EMBARQUE"    ,1           ,4         ,.F.}) 
      aAdd(_aCabecalho,{"HORA EMBARQUE"    ,1           ,3         ,.F.}) 
      aAdd(_aCabecalho,{"CNPJ CLIENTE"     ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"COD TRANSP"       ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"LOJA TRANSP"      ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"CNPJ TRANSP "     ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"NOME TRANSP "     ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"VALOR MERCADORIA" ,1           ,2         ,.F.}) 
      aAdd(_aCabecalho,{"TIPO DE FRETE"    ,1           ,1         ,.F.}) 

      _cArq := "ATM"+_cArq // Nome da planilha a ser gerada.   
      _cTitulo := "RELATÓRIO DE FRETE POR TRANSPORTADOR (ATM)"
      
      U_ITGEREXCEL(_cArq,_cDir,_cTitulo,"Relatorio",_aCabecalho,,.T.,"TMPORDEM",_aCampos)         
      Break                              
   
   EndIf                                            
   
   If nCountRec > 0

	  //Imprime cabecalho
	  ROMS005C(1)

	  While TMPORDEM->( !Eof() )
	
		 IncProc( "Os dados estão sendo processados, favor aguardar..." )
		
		 nPosFilial := aScan( aFilial , {|x| x[1] == AllTrim(TMPORDEM->D2_FILIAL) } )
		
		 //Verifica se ja existe dados da Filial Lancados anteriormente
		 If nPosFilial > 0
		
			//Efetua somatorio dos totalizadores por Filial
			nFTotqtde1 += TMPORDEM->D2_QUANT
			nFTotqtde2 += TMPORDEM->D2_QTSEGUM
			nFTotvlrTo += TMPORDEM->D2_TOTAL
			nFTotvlrBr += TMPORDEM->D2_VALBRUT
			nFTotvlrFr += TMPORDEM->D2_I_FRET
			
			//Verifica se eh o mesmo produto dentro da Filial
			nPosProdut := aScan( aProduto , {|x| x[1] == AllTrim(TMPORDEM->D2_FILIAL) + AllTrim(TMPORDEM->PRODUTO) } )
			
			//Caso ja haja lancamentos deste produto anteriormente
			If nPosProdut > 0
			
				nlinha += nSaltoLinha
				
				oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
				
				ROMS005Q(0,0)
				
				ROMS005K('',TMPORDEM->A1_EST,TMPORDEM->D2_QUANT,TMPORDEM->D2_UM,TMPORDEM->D2_QTSEGUM,TMPORDEM->D2_SEGUM,TMPORDEM->D2_TOTAL,TMPORDEM->D2_VALBRUT,TMPORDEM->D2_I_FRET)
				
				//Variaveis que controlam os totalizadores do produto, efetua somatorio
				nTotqtde1 += TMPORDEM->D2_QUANT
				nTotqtde2 += TMPORDEM->D2_QTSEGUM
				nTotvlrTo += TMPORDEM->D2_TOTAL
				nTotvlrBr += TMPORDEM->D2_VALBRUT
				nTotvlrFr += TMPORDEM->D2_I_FRET
				
			//Caso seja o primeiro registro do produto corrente dentro da filial atual
			Else
				
				aAdd( aProduto , { AllTrim( AllTrim(TMPORDEM->D2_FILIAL) + AllTrim(TMPORDEM->PRODUTO) ) } )
				
				nlinha += nSaltoLinha
				
				oPrint:Line( nLinha , nColInic , nLinha , nColFinal )
				
				ROMS005Q(0,0)
				
				ROMS005H( 'TOTAL:' , nTotqtde1 , nTotqtde2 , nTotvlrTo , nTotvlrBr , nTotvlrFr , 0 )
				
				nlinha += nSaltoLinha
				
				roms005n() // Imprime o box e divisorias do produto anterior
				
				nlinha += nSaltoLinha
				
				ROMS005Q(1)
				
				ROMS005L() // Imprime cabelho dos dados
				
				nlinha += nSaltoLinha
				
				oPrint:Line( nLinha , nColInic , nLinha , nColFinal )
				
				ROMS005Q(0,0)
				
				//Imprime a primeira linha de registros da nova filial
				ROMS005K(TMPORDEM->DESCR,TMPORDEM->A1_EST,TMPORDEM->D2_QUANT,TMPORDEM->D2_UM,TMPORDEM->D2_QTSEGUM,TMPORDEM->D2_SEGUM,TMPORDEM->D2_TOTAL,TMPORDEM->D2_VALBRUT,TMPORDEM->D2_I_FRET) 
				
				//Variaveis que controlam os totalizadores do produto, seta novo produto
				nTotqtde1 := TMPORDEM->D2_QUANT
				nTotqtde2 := TMPORDEM->D2_QTSEGUM
				nTotvlrTo := TMPORDEM->D2_TOTAL
				nTotvlrBr := TMPORDEM->D2_VALBRUT 
				nTotvlrFr := TMPORDEM->D2_I_FRET
				
		    EndIf

		 //Caso seja o primeiro dado da Filial imprimir cabecalho e dados
		 Else
		
			//Imprime o box e divisorias do produto anterior
			If Len(aFilial) > 0
			
				nlinha += nSaltoLinha
				
				oPrint:Line( nLinha , nColInic , nLinha , nColFinal )
				
				ROMS005Q(1,0)
				
				//Imprime totalizador por Produto
				ROMS005H('TOTAL:',nTotqtde1,nTotqtde2,nTotvlrTo,nTotvlrBr,nTotvlrFr,0)
				
				nlinha += nSaltoLinha
				
				roms005n()
				
				//Imprime o totalizador da Filial   
				nlinha += ( nSaltoLinha * 2 )
				
				ROMS005Q(2,0)
				
				ROMS005H('TOTAL FILIAL: ' + AllTrim(aFilial[Len(aFilial),1]) + ' - ' + FWFilialName(,AllTrim(aFilial[Len(aFilial),1])),nFTotqtde1,nFTotqtde2,nFTotvlrTo,nFTotvlrBr,nFTotvlrFr,1)
				
				nlinha += nSaltoLinha
			
			EndIf
 		
			//Efetua somatorio dos totalizadores por Filial
			nFTotqtde1 := TMPORDEM->D2_QUANT
			nFTotqtde2 := TMPORDEM->D2_QTSEGUM
			nFTotvlrTo := TMPORDEM->D2_TOTAL
			nFTotvlrBr := TMPORDEM->D2_VALBRUT
			nFTotvlrFr := TMPORDEM->D2_I_FRET
			
			aAdd( aFilial  , { AllTrim(TMPORDEM->D2_FILIAL) } )     
			aAdd( aProduto , { AllTrim(TMPORDEM->D2_FILIAL) + AllTrim(TMPORDEM->PRODUTO) } )
			
			nlinha += nSaltoLinha
			
			ROMS005Q(1,1)
			
			ROMS005F( TMPORDEM->D2_FILIAL ) // Imprime cabecalho da Filial
			
			nlinha += ( nSaltoLinha * 2 )
			
			ROMS005Q(2,1)
			
			ROMS005L() // Imprime cabelho dos dados
			
			nlinha += nSaltoLinha
			
			oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
			
			ROMS005Q(0)
			
			//Imprime a primeira linha de registros da nova filial
			ROMS005K(TMPORDEM->DESCR,TMPORDEM->A1_EST,TMPORDEM->D2_QUANT,TMPORDEM->D2_UM,TMPORDEM->D2_QTSEGUM,TMPORDEM->D2_SEGUM,TMPORDEM->D2_TOTAL,TMPORDEM->D2_VALBRUT,TMPORDEM->D2_I_FRET)
			
			//Variaveis que controlam os totalizadores do produto, seta novo produto
			nTotqtde1 := TMPORDEM->D2_QUANT
			nTotqtde2 := TMPORDEM->D2_QTSEGUM
			nTotvlrTo := TMPORDEM->D2_TOTAL
			nTotvlrBr := TMPORDEM->D2_VALBRUT
			nTotvlrFr := TMPORDEM->D2_I_FRET
		
		 EndIf
		
	     TMPORDEM->( DBSkip() )
	  EndDo
	
	  //Para o grupo de produto/produto impresso eh necessario finalizar a sua impressao com o box e divisorias e toalizadores
	  nlinha += nSaltoLinha
	
	  oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	
	  ROMS005Q(1,0)
	
	  ROMS005H('TOTAL:',nTotqtde1,nTotqtde2,nTotvlrTo,nTotvlrBr,nTotvlrFr,0)
	
	  nlinha += nSaltoLinha
	
	  roms005n()
	
	  nlinha += ( nSaltoLinha * 2 )
	
	  ROMS005Q(2,1)
	
	  ROMS005H('TOTAL FILIAL: ' + AllTrim(aFilial[Len(aFilial),1]) + ' - ' + FWFilialName(,AllTrim(aFilial[Len(aFilial),1])),nFTotqtde1,nFTotqtde2,nFTotvlrTo,nFTotvlrBr,nFTotvlrFr,1)
	
	  nlinha += nSaltoLinha
	
   EndIf

End Sequence

TMPORDEM->( DBCloseArea() )

Return

/*
===============================================================================================================================
Programa--------: ROMS005C
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: imprimir os dados de cabeçalho do relatório
===============================================================================================================================
Parametros------: IMPNRPAG - Se imprime ou não o número de página (0 não imprime, 1 imprime)
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS005C( impNrPag )

Local cRaizServer := If(issrvunix(), "/", "\")    
Local cTitulo     := "Relação de Fretes por Transportadora - Ordem de "+ aOrd[nOrdem] +" de: "+ DToC(MV_PAR02) +" Até "+ DToC(MV_PAR03)
Local nDiferLay   := 0

nLinha := 0070

//Para subtrair este valor de acordo com o modelo da pagina Paisagem ou Retrato
If nOrdem == 8 .Or. nOrdem == 9 .Or. nOrdem == 10
	nDiferLay := 1000
EndIf

oPrint:SayBitmap( nLinha , nColInic , cRaizServer + "system/lgrl01.bmp" , 250 , 100 )

If impNrPag <> 0

	oPrint:Say( nlinha			, ( nColInic + 2750 ) - nDiferLay , "PÁGINA: "+ AllTrim( Str( nPagina ) )								, oFont12b )
	
Else

	oPrint:Say( nlinha			, ( nColInic + 2750 ) - nDiferLay , "SIGA/ROMS005"														, oFont12b )
	oPrint:Say( nlinha + 100	, ( nColInic + 2750 ) - nDiferLay , "EMPRESA: " + AllTrim(SM0->M0_NOME) + '/' + AllTrim(SM0->M0_FILIAL)	, oFont12b )
	
EndIf

oPrint:Say( nlinha + 50			, ( nColInic + 2750 ) - nDiferLay , "DATA DE EMISSÃO: "+ DToC( Date() )									, oFont12b )

nlinha += ( nSaltoLinha * 3 )

	oPrint:Say (nlinha,nColFinal / 2,cTitulo,oFont16b,nColFinal,,,2)
	
	nlinha+=nSaltoLinha 
	nlinha+=nSaltoLinha        
	
	oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 

Return

/*
===============================================================================================================================
Programa--------: ROMS005F
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: imprimir os dados de cabeçalho do relatório
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS005F( cCodFilial )

oPrint:FillRect( { ( nlinha + 3 ) , nColInic , nlinha + nSaltoLinha , nColFinal - 1270 } , oBrush )

oPrint:Box( nlinha , nColInic , nLinha + nSaltoLinha , nColFinal - 1270 )

oPrint:Say( nlinha , nColInic + 025 , "Filial:"											, oFont14Prb )
oPrint:Say( nlinha , nColInic + 230 , AllTrim(cCodFilial) +'-'+ FWFilialName(,cCodFilial)	, oFont14Prb )

Return

/*
===============================================================================================================================
Programa--------: ROMS005L
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: imprimir os dados de cabeçalho do relatório
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS005L()        

Local nColuna := 0
Local cTitulo := ""

//Grupo de Produtos x UF
If nOrdem == 6
    
    cTitulo:= "Grupo de Produto"
    
//Produtos x UF
ElseIf nOrdem == 7

	cTitulo:= "Produto"
	
EndIf

nLinInBox := nlinha

oPrint:FillRect( { (nlinha+3) , nColInic , nlinha + nSaltoLinha , nColFinal } , oBrush )

oPrint:Say( nlinha , nColInic + 010				, cTitulo			, oFont12b ) ; nColuna += 010
oPrint:Say( nlinha , nColInic + 680 + nColuna	, "Estado"			, oFont12b ) ; nColuna += 570
oPrint:Say( nlinha , nColInic + 350 + nColuna	, "Quantidade"		, oFont12b ) ; nColuna += 300
oPrint:Say( nlinha , nColInic + 300 + nColuna	, "1a U.M."			, oFont12b ) ; nColuna += 300
oPrint:Say( nlinha , nColInic + 225 + nColuna	, "Qtde 2a U.M."	, oFont12b ) ; nColuna += 225
oPrint:Say( nlinha , nColInic + 280 + nColuna	, "2a U.M."			, oFont12b ) ; nColuna += 300
oPrint:Say( nlinha , nColInic + 220 + nColuna	, "Vlr.Unit"		, oFont12b ) ; nColuna += 200
oPrint:Say( nlinha , nColInic + 300 + nColuna	, "Vlr.Total"		, oFont12b ) ; nColuna += 300
oPrint:Say( nlinha , nColInic + 300 + nColuna	, "Vlr.Bruto"		, oFont12b ) ; nColuna += 300
oPrint:Say( nlinha , nColInic + 300 + nColuna	, "Vlr.Frete"		, oFont12b ) ; nColuna += 300
oPrint:Say( nlinha , nColInic + 300 + nColuna	, "Frete/Unid"		, oFont12b )

Return

/*
===============================================================================================================================
Programa--------: ROMS005K
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: imprimir a linha de dados do relatório
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function ROMS005K(cProduto,cEstado,nqtde1um,um1,nqtde2um,um2,nVlrTotal,nVlrBruto,nValFrete)

Local nColuna := 0

oPrint:Say( nlinha , nColInic + 010				, SubStr(cProduto,1,35)									, oFont10b) ; nColuna+= 010
oPrint:Say( nlinha , nColInic + 680 + nColuna	, cEstado												, oFont10b) ; nColuna+= 570
oPrint:Say( nlinha , nColInic + 290 + nColuna	, Transform(nqtde1um,"@E 9,999,999,999.99")				, oFont10 ) ; nColuna+= 300
oPrint:Say( nlinha , nColInic + 300 + nColuna	, um1													, oFont10 ) ; nColuna+= 300
oPrint:Say( nlinha , nColInic + 205 + nColuna	, Transform(nqtde2um,"@E 9,999,999,999.99")				, oFont10 ) ; nColuna+= 225
oPrint:Say( nlinha , nColInic + 280 + nColuna	, um2													, oFont10 ) ; nColuna+= 300
oPrint:Say( nlinha , nColInic + 155 + nColuna	, Transform(nVlrTotal/nqtde1um,"@E 9,999,999.9999")		, oFont10 ) ; nColuna+= 200
oPrint:Say( nlinha , nColInic + 215 + nColuna	, Transform(nVlrTotal,"@E 9,999,999,999.99")			, oFont10 ) ; nColuna+= 300
oPrint:Say( nlinha , nColInic + 215 + nColuna	, Transform(nVlrBruto,"@E 9,999,999,999.99")			, oFont10 ) ; nColuna+= 300
oPrint:Say( nlinha , nColInic + 225 + nColuna	, Transform(nValFrete,"@E 9,999,999,999.99")			, oFont10 ) ; nColuna+= 300
oPrint:Say( nlinha , nColInic + 230 + nColuna	, Transform(nValFrete/nqtde1um,"@E 999,999,999.9999")	, oFont10 )

Return

/*
===============================================================================================================================
Programa--------: ROMS005H
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: imprimir os dados de total do relatório
===============================================================================================================================
Parametros------: cDescTot , nTotqtde1 , nTotqtde2 , nTotvlrTo , nTotvlrBr , nTotvlrFr , nTipo
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS005H( cDescTot , nTotqtde1 , nTotqtde2 , nTotvlrTo , nTotvlrBr , nTotvlrFr , nTipo )

Local nColuna := 0

// Imprime totalizador por Filial
If nTipo == 1

	oPrint:Box(nlinha,nColInic,nLinha + nSaltoLinha,nColFinal)
	
	oPrint:Line( nlinha , 0710 , nLinha + nSaltoLinha , 0710 ) // PRODUTO
	oPrint:Line( nlinha , 0860 , nLinha + nSaltoLinha , 0860 ) // ESTADO
	oPrint:Line( nlinha , 1190 , nLinha + nSaltoLinha , 1190 ) // QUANTIDADE
	oPrint:Line( nlinha , 1360 , nLinha + nSaltoLinha , 1360 ) // 1a U.M.
	oPrint:Line( nlinha , 1705 , nLinha + nSaltoLinha , 1705 ) // QUANTIDADE 2 U.M.
	oPrint:Line( nlinha , 1875 , nLinha + nSaltoLinha , 1875 ) // 2a U.M.
	oPrint:Line( nlinha , 2145 , nLinha + nSaltoLinha , 2145 ) // VALOR UNITARIO
	oPrint:Line( nlinha , 2440 , nLinha + nSaltoLinha , 2440 ) // VALOR TOTAL
	oPrint:Line( nlinha , 2740 , nLinha + nSaltoLinha , 2740 ) // VALOR BRUTO
	oPrint:Line( nlinha , 3050 , nLinha + nSaltoLinha , 3050 ) // VALOR FRETE
	
EndIf

oPrint:Say( nlinha , nColInic + 010           , SubStr(cDescTot,1,36)									, oFont10b) ; nColuna+= 580
oPrint:Say( nlinha , nColInic + 290 + nColuna , Transform(nTotqtde1,"@E 9,999,999,999.99")				, oFont10 ) ; nColuna+= 600
oPrint:Say( nlinha , nColInic + 205 + nColuna , Transform(nTotqtde2,"@E 9,999,999,999.99")				, oFont10 ) ; nColuna+= 525
oPrint:Say( nlinha , nColInic + 155 + nColuna , Transform(nTotvlrTo/nTotqtde1,"@E 9,999,999.9999")		, oFont10 ) ; nColuna+= 200
oPrint:Say( nlinha , nColInic + 215 + nColuna , Transform(nTotvlrTo,"@E 9,999,999,999.99")				, oFont10 ) ; nColuna+= 300
oPrint:Say( nlinha , nColInic + 215 + nColuna , Transform(nTotvlrBr,"@E 9,999,999,999.99")				, oFont10 ) ; nColuna+= 300                                                                                    
oPrint:Say( nlinha , nColInic + 225 + nColuna , Transform(nTotvlrFr,"@E 9,999,999,999.99")				, oFont10 ) ; nColuna+= 300
oPrint:Say( nlinha , nColInic + 230 + nColuna , Transform(nTotvlrFr/nTotqtde1,"@E 999,999,999.9999")	, oFont10 )

Return

/*
===============================================================================================================================
Programa--------: ROMS005Q
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Verifica e Processa a quebra de páginas
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS005Q( nLinhas , impBox )

//Quebra de pagina
If nLinha > nqbrPagina
	
	nlinha:= nlinha - (nSaltoLinha * nLinhas)
	
	If impBox == 0
		roms005n()
	EndIf
	
	oPrint:EndPage()	// Finaliza a Pagina.
	oPrint:StartPage()	// Inicia uma nova Pagina.
	
	nPagina++
	
	ROMS005C(1)		// Chama cabecalho
	
	nlinha		+= nSaltoLinha
	nLinInBox	:= nLinha
	
EndIf

Return

/*
===============================================================================================================================
Programa--------: roms005n
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Imprime box para divisão dos dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function roms005n()

oPrint:Line( nLinInBox , 0710 , nLinha , 0710 ) // PRODUTO
oPrint:Line( nLinInBox , 0860 , nLinha , 0860 ) // ESTADO
oPrint:Line( nLinInBox , 1190 , nLinha , 1190 ) // QUANTIDADE
oPrint:Line( nLinInBox , 1360 , nLinha , 1360 ) // 1a U.M.
oPrint:Line( nLinInBox , 1705 , nLinha , 1705 ) // QUANTIDADE 2 U.M.
oPrint:Line( nLinInBox , 1875 , nLinha , 1875 ) // 2a U.M.
oPrint:Line( nLinInBox , 2145 , nLinha , 2145 ) // VALOR UNITARIO
oPrint:Line( nLinInBox , 2440 , nLinha , 2440 ) // VALOR TOTAL
oPrint:Line( nLinInBox , 2740 , nLinha , 2740 ) // VALOR BRUTO
oPrint:Line( nLinInBox , 3050 , nLinha , 3050 ) // VALOR FRETE

oPrint:Box( nLinInBox , nColInic , nLinha , nColFinal )

Return
                        
/*
===============================================================================================================================
Programa--------: ROMS005Z
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Imprime a página de parâmetros do relatório
===============================================================================================================================
Parametros------: oPrint - objeto da impressao
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/               
Static Function ROMS005Z( oPrint )
Local nAux		:= 1

Local _aDadosPegunte := {}
Local _nI
Local _cTexto

nLinha+= 080                                    
oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
nLinha+= 60

aAdd(_aDadosPegunte,{"01", "Filial ?"               , "MV_PAR01"})       
aAdd(_aDadosPegunte,{"02", "De Emissao ? "          , "MV_PAR02"})           
aAdd(_aDadosPegunte,{"03", "Ate Emissao ?"          , "MV_PAR03"})
aAdd(_aDadosPegunte,{"04", "De Produto ? "          , "MV_PAR04"})           
aAdd(_aDadosPegunte,{"05", "Ate Produto ?"          , "MV_PAR05"})
aAdd(_aDadosPegunte,{"06", "De Cliente ? "          , "MV_PAR06"})
aAdd(_aDadosPegunte,{"07", "Loja ?   "              , "MV_PAR07"})  
aAdd(_aDadosPegunte,{"08", "Ate Cliente ? "         , "MV_PAR08"})  
aAdd(_aDadosPegunte,{"09", "Loja ?"                 , "MV_PAR09"})       
aAdd(_aDadosPegunte,{"10", "Rede ?"                 , "MV_PAR10"})           
aAdd(_aDadosPegunte,{"11", "Estado ?"               , "MV_PAR11"})
aAdd(_aDadosPegunte,{"12", "Municipio ?"            , "MV_PAR12"})           
aAdd(_aDadosPegunte,{"13", "Vendedor ?  "           , "MV_PAR13"})          
aAdd(_aDadosPegunte,{"14", "Supervisor ? "          , "MV_PAR14"})
aAdd(_aDadosPegunte,{"15", "Grupo Produto ? "       , "MV_PAR15"})
aAdd(_aDadosPegunte,{"16", "Produto Nivel 2 ?"      , "MV_PAR16"})  
aAdd(_aDadosPegunte,{"17", "Produto Nivel 3 ?"      , "MV_PAR17"})  
aAdd(_aDadosPegunte,{"18", "Produto Nivel 4 ?"      , "MV_PAR18"})
aAdd(_aDadosPegunte,{"19", "Relatorio ?"            , "MV_PAR19"})
aAdd(_aDadosPegunte,{"20", "Transportaodora ?"      , "MV_PAR20"})
aAdd(_aDadosPegunte,{"21", "CFOP's ? "              , "MV_PAR21"})
aAdd(_aDadosPegunte,{"22", "Possui Frete ?"         , "MV_PAR22"})
aAdd(_aDadosPegunte,{"23", "Sub Grupo Produto ? "   , "MV_PAR23"})
aAdd(_aDadosPegunte,{"24", "Tipo de Carga ?  "      , "MV_PAR24"})
aAdd(_aDadosPegunte,{"25", "Tipo de Fornecedor ? "  , "MV_PAR25"})
aAdd(_aDadosPegunte,{"26", "Rel Graf Excel/Impr ? " , "MV_PAR26"})
aAdd(_aDadosPegunte,{"27", "Armazéns ?"             , "MV_PAR27"})
aAdd(_aDadosPegunte,{"28", "Averbacao Forn ?"       , "MV_PAR28"})
aAdd(_aDadosPegunte,{"29", "Tipo de frete ?"        , "MV_PAR29"})

For _nI := 1 To Len(_aDadosPegunte)          
	nAux:= 1      
	
	oPrint:Say (nLinha,nColInic + 10,"Pergunta " + _aDadosPegunte[_nI,1] + ':' +  _aDadosPegunte[_nI,2] , oFont14Prb)    
		
	If _aDadosPegunte[_nI,3] == "MV_PAR19"
	   If MV_PAR19 ==  1
	      _cTexto := "Sintético"
	   ElseIf MV_PAR19 == 2
	      _cTexto := "Analítico"
	   Else
	      _cTexto := ""
	   EndIf
	   oPrint:Say (nLinha,1200,_cTexto,oFont14Prb)  
	
	ElseIf _aDadosPegunte[_nI,3] == "MV_PAR22"
	   If MV_PAR22 ==  1
	      _cTexto := "Sim"
	   ElseIf MV_PAR22 == 2
	      _cTexto := "Não"
	   Else
	      _cTexto := "Ambos"
	   EndIf
	   oPrint:Say (nLinha,1200,_cTexto,oFont14Prb)     	   
	
	ElseIf _aDadosPegunte[_nI,3] == "MV_PAR26"
	   If MV_PAR26 ==  1
	      _cTexto := "Impressora"
	   ElseIf MV_PAR26 == 2
	      _cTexto := "Excel"
	   Else
	      _cTexto := ""
	   EndIf
	   oPrint:Say (nLinha,1200,_cTexto,oFont14Prb)  	   
    
    ElseIf _aDadosPegunte[_nI,3] == "MV_PAR28"
	   _cTexto := "Ambos"
	   /* Por solicitação da usuária fixar a opção de filtro transportadoras por averbação em ambos
	   If MV_PAR28 ==  1
	      _cTexto := "Com Averbação"
	   ElseIf MV_PAR28 == 2
	      _cTexto := "Sem Averbação"
	   Else
	      _cTexto := "Ambos"
	   EndIf
	   */
	   oPrint:Say (nLinha,1200,_cTexto,oFont14Prb)  
	   
    Else
       _cTexto := &(_aDadosPegunte[_nI,3])
       If ValType(_cTexto) == "D"
          _cTexto := DToC(_cTexto)
       EndIf   
       oPrint:Say (nLinha,1200,_cTexto,oFont14Prb)  		
    EndIf	
	    
	nLinha+= 60
Next


oPrint:Say (nLinha,nColInic + 10,"Ordem de "+ aOrd[nOrdem] , oFont14Prb)    
nLinha+= 60
	  
nLinha+= 60
oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	
oPrint:EndPage()     // Finaliza a página

Return

/*
===============================================================================================================================
Programa--------: ROMS0058
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Processa as informacoes para imprimir a ordem Fechamento do Frete
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0058()

Local nCountRec := 0
Local cQuery    := ""       
Local aProduto  := {} //Para controla a quebra de grupo de produto/Produto por Filial
Local nPosProdut                

//Variaveis para controle dos totalizadores por Produto                 
Local nTotqtde1 := 0
Local nTotqtde2 := 0 
Local nTotvlrFr := 0      
Local nTotvlrBr := 0 

//Variaveis para controle dos totalizadores Geral                
Local nGrTotqtd1:= 0
Local nGrTotqtd2:= 0 
Local nGrTotvlFr:= 0 
Local nGrTotvlBr:= 0     

Local _aCampos := {} // Array com os campos da tabela temporária.
Local _cDir := GetTempPath()  // Diretório de Geração das planilhas.
Local _cArq := "_"+DToS(Date())+"_"+StrTran(Time(),":","")+".xml"  // Nome da planilha a ser gerada.   
Local _aCabecalho := {} // Array com o cabeçalho das colunas do relatório.
Local _cTitulo

Private _cAlias   := GetNextAlias() 

Begin Sequence     
   //Filtro indicados anteriormente
   cFiltro := SubStr( cFiltro , 2 , Len(cFiltro) )

   cQuery := " SELECT "
   cQuery += " Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD    WHEN SA2.A2_I_CLASS = 'A' THEN '999999'    END AS A2_COD,"
   cQuery += " Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END AS A2_NREDUZ,"
   cQuery += " SA2.A2_EST, "
   cQuery += " SA1.A1_COD,"
   cQuery += " SA1.A1_NREDUZ,"
   cQuery += " SA1.A1_EST,"
   If MV_PAR30 = 1
      cQuery += " DAK.DAK_COD,"
   EndIf   
   cQuery += " SUM(SD2.D2_QUANT)   AS D2_QUANT,"
   cQuery += " SUM(SD2.D2_QTSEGUM) AS D2_QTSEGUM,"
   cQuery += " SUM(SD2.D2_I_FRET)  AS D2_I_FRET,"        

   If nOrdem == 8
      cQuery += " SB1.B1_COD PRODUTO,SB1.B1_I_DESCD DESCR,SD2.D2_UM,SD2.D2_SEGUM,"		
   ElseIf nOrdem == 9
	  cQuery += " SB1.B1_I_SUBGR PRODUTO,SD2.D2_UM,SD2.D2_SEGUM,"
   EndIf

   cQuery += " SUM(SD2.D2_VALBRUT) AS VLBRUT " 
   cQuery += " FROM "+ RetSqlName("DAK") +" DAK "
   cQuery += " JOIN "+ RetSqlName("DAI") +" DAI ON DAI.DAI_COD = DAK.DAK_COD AND DAI.DAI_FILIAL = DAK.DAK_FILIAL "
   cQuery += " JOIN "+ RetSqlName("DA3") +" DA3 ON DAK.DAK_CAMINH = DA3.DA3_COD "
   cQuery += " JOIN "+ RetSqlName("SF2") +" SF2 ON SF2.F2_DOC = DAI.DAI_NFISCA AND SF2.F2_SERIE = DAI.DAI_SERIE AND DAI.DAI_FILIAL = SF2.F2_FILIAL "
   cQuery += " JOIN "+ RetSqlName("SD2") +" SD2 ON SD2.D2_DOC = SF2.F2_DOC AND SD2.D2_SERIE = SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL "
   cQuery += " JOIN (SELECT A1_FILIAL, A1_COD, A1_LOJA, A1_NREDUZ, A1_MUN, A1_EST, A1_CGC, A1_GRPVEN, A1_COD_MUN "  
   cQuery += " 		FROM "+ RetSqlName("SA1") +" SA1 "
   cQuery += " 		WHERE SA1.D_E_L_E_T_ = ' ' "
   cQuery += " 		UNION
   cQuery += " 		SELECT A2_FILIAL, A2_COD, A2_LOJA, A2_NREDUZ, A2_MUN, A2_EST, A2_CGC, '' As A1_GRPVEN, A2_COD_MUN A1_COD_MUN "  
   cQuery += " 		FROM "+ RetSqlName("SA2") +" SA2 "
   cQuery += " 		WHERE SA2.D_E_L_E_T_ = ' '  ) SA1 ON  SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA  = SA1.A1_LOJA "
   cQuery += " JOIN "+ RetSqlName("SA3") +" SA3 ON SF2.F2_VEND1 = SA3.A3_COD "
   cQuery += " JOIN "+ RetSqlName("SB1") +" SB1 ON SD2.D2_COD = SB1.B1_COD "
   cQuery += " JOIN "+ RetSqlName("DA4") +" DA4 ON DAK.DAK_MOTORI = DA4.DA4_COD "
   cQuery += " JOIN "+ RetSqlName("SA2") +" SA2 ON SF2.F2_I_CTRA = SA2.A2_COD AND SF2.F2_I_LTRA = SA2.A2_LOJA "
   cQuery += " JOIN "+ RetSqlName("SC5") +" SC5 ON SC5.C5_FILIAL = SD2.D2_FILIAL AND SC5.C5_NUM = SD2.D2_PEDIDO"
   cQuery += " WHERE "
   cQuery +=     " DAK.D_E_L_E_T_ = ' ' "
   cQuery += " AND DAI.D_E_L_E_T_ = ' ' "  
   cQuery += " AND DA3.D_E_L_E_T_ = ' ' "
   cQuery += " AND SF2.D_E_L_E_T_ = ' ' "
   cQuery += " AND SD2.D_E_L_E_T_ = ' ' "
   cQuery += " AND SA3.D_E_L_E_T_ = ' ' "
   cQuery += " AND SB1.D_E_L_E_T_ = ' ' "
   cQuery += " AND DA4.D_E_L_E_T_ = ' ' "
   cQuery += " AND SA2.D_E_L_E_T_ = ' ' "
   cQuery += " AND SC5.D_E_L_E_T_ = ' ' "
   cQuery += " AND SA2.A2_I_CLASS IN ('T','A','G') "
   cQuery += " AND SD2.D2_CF <> '5927' "
   cQuery +=  cFiltro
   cQuery += "GROUP BY" 
   cQuery += " Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD WHEN SA2.A2_I_CLASS = 'A' THEN '999999' END,"
   cQuery += " Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END,"
   cQuery += " SA2.A2_EST, "
   cQuery += " SA1.A1_COD,"
   cQuery += " SA1.A1_NREDUZ,"
   cQuery += " SA1.A1_EST,"
    If MV_PAR30 = 1
       cQuery += " DAK.DAK_COD,"
	EndIf   
   If nOrdem == 8
      cQuery += " SB1.B1_COD,SB1.B1_I_DESCD,SD2.D2_UM,SD2.D2_SEGUM "
   ElseIf nOrdem == 9
	  cQuery += " SB1.B1_I_SUBGR,SD2.D2_UM,SD2.D2_SEGUM "
   EndIf
   cQuery += " ORDER BY PRODUTO, D2_QUANT DESC, A2_COD " 

   If Select(_cAlias) > 0 
	  (_cAlias)->( DBCloseArea() )
   EndIf
    
   DBUseArea( .T. , "TOPCONN" , TCGenQry(,,cQuery) , _cAlias , .F. , .T. )

   COUNT TO nCountRec
	
   ProcRegua(nCountRec)    

   If MV_PAR26 == 2 // Relatório em Excel                     
      IncProc( "Os dados estão sendo gerados em Excel, favor aguardar..." )
      // Array com os campos da tabela temporária.                                         
      If nOrdem == 8 //Fechamento x Produto
         _aCampos := {'(_cAlias)->PRODUTO',;                                                                 //"COD.PRODUTO"
                      '(_cAlias)->DESCR',;                                                                   //"DESCR.PRODUTO"
                      '(_cAlias)->A2_COD +"-"+ (_cAlias)->A2_NREDUZ',;                                       // "TRANSPORTADORA"   
                      '(_cAlias)->A2_EST'                           ,;                                       // "UF TRANSPORTADORA"   
                      '(_cAlias)->D2_QUANT',;                                                                // "QUANTIDADE"
                      '(_cAlias)->D2_UM',;                                                                   // "U.M."
                      '(_cAlias)->D2_QTSEGUM',;                                                              // "QUANT.2a U.M." 
                      '(_cAlias)->D2_SEGUM',;                                                                // "2a U.M."
                      '(_cAlias)->D2_I_FRET',;                                                               // "FRETE"
                      '(_cAlias)->D2_I_FRET / (_cAlias)->D2_QUANT',;                                         // "MÉDIA"
                      '(_cAlias)->VLBRUT',;                                                                  // "VALOR BRUTO"
                      '(_cAlias)->A1_COD +"-"+ (_cAlias)->A1_NREDUZ',;                                       // CLIENTE
                      '(_cAlias)->A1_EST'}                                                                   // "UF CLIENTE
      Else//nOrdem == 9 
         _aCampos := {'(_cAlias)->PRODUTO',;                                                                 //"COD.PRODUTO"
                      'Posicione("ZB9",1,xFilial("ZB9") + AllTrim((_cAlias)->PRODUTO),"ZB9_DESSUB" )',;      //"DESCR.PRODUTO"
                      '(_cAlias)->A2_COD +"-"+ (_cAlias)->A2_NREDUZ',;                                       // "TRANSPORTADORA"   
                      '(_cAlias)->A2_EST'                           ,;                                       // "UF TRANSPORTADORA"   
                      '(_cAlias)->D2_QUANT',;                                                                // "QUANTIDADE"
                      '(_cAlias)->D2_UM',;                                                                   // "U.M."
                      '(_cAlias)->D2_QTSEGUM',;                                                              // "QUANT.2a U.M." 
                      '(_cAlias)->D2_SEGUM',;                                                                // "2a U.M."
                      '(_cAlias)->D2_I_FRET',;                                                               // "FRETE"
                      '(_cAlias)->D2_I_FRET / (_cAlias)->D2_QUANT',;                                         // "MÉDIA"
                      '(_cAlias)->VLBRUT',;                                                                  // "VALOR BRUTO"
                      '(_cAlias)->A1_COD +"-"+ (_cAlias)->A1_NREDUZ',;                                       // CLIENTE
                      '(_cAlias)->A1_EST'}                                                                   // "UF CLIENTE
      EndIf
      If MV_PAR30 = 1
         aAdd(_aCampos,'(_cAlias)->DAK_COD')								                                     // CARGA
      EndIf
      _aCabecalho := {} // Array com o cabeçalho das colunas do relatório. 
      // Alinhamento( 1-Left,2-Center,3-Right )
      // Formatação( 1-General,2-Number,3-Monetário,4-DateTime )
      //                Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?  
      aAdd(_aCabecalho,{"COD.PRODUTO"      ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"DESCR.PRODUTO"    ,1           ,1         ,.F.})    
      aAdd(_aCabecalho,{"TRANSPORTADORA"   ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"UF"               ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"QUANTIDADE"       ,3           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"U.M."             ,2           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"QUANT.2a U.M."    ,3           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"2a U.M."          ,2           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"FRETE"            ,3           ,3         ,.F.}) 
      aAdd(_aCabecalho,{"MÉDIA"            ,3           ,3         ,.F.}) 
      aAdd(_aCabecalho,{"VALOR BRUTO"      ,3           ,3         ,.F.}) 
      aAdd(_aCabecalho,{"CLIENTE"          ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"UF"               ,1           ,1         ,.F.}) 
      If MV_PAR30 = 1
         aAdd(_aCabecalho,{"CARGA"            ,1           ,1         ,.F.}) 
      EndIf

      If nOrdem == 8 //Fechamento x Produto
         _cArq := "Fechamento_x_Produto"+_cArq // Nome da planilha a ser gerada.   
         _cTitulo := "RELATÓRIO DE FRETE POR TRANSPORTADOR (FECHAMENTO X PRODUTO)" 
      Else //Fechamento x SubGrupo // nOrdem == 9 
         _cArq := "Fechamento_x_sub_Grupo"+_cArq // Nome da planilha a ser gerada.   
         _cTitulo := "RELATÓRIO DE FRETE POR TRANSPORTADOR (FECHAMENTO X SUB-GRUPO)"
      EndIf
      
      U_ITGEREXCEL(_cArq,_cDir,_cTitulo,"Relatorio",_aCabecalho,,.T.,_cAlias,_aCampos)         
      Break                              
   EndIf

   If nCountRec > 0  

	  ROMS005C(1) // Imprime cabecalho
	
	  DBSelectArea(_cAlias)
	  (_cAlias)->( DBGoTop() )
	  While (_cAlias)->( !Eof() )
	
		 IncProc( "Os dados estão sendo processados, favor aguardar..." )
		
		 //Incremente as variaves de somatorio geral
		 nGrTotqtd1 += (_cAlias)->D2_QUANT
		 nGrTotqtd2 += (_cAlias)->D2_QTSEGUM
		 nGrTotvlFr += (_cAlias)->D2_I_FRET
		 nGrTotvlBr += (_cAlias)->VLBRUT
		
		 nPosProdut := aScan( aProduto , {|x| x[1] == AllTrim( (_cAlias)->PRODUTO ) } )
		
		 //Produto ja possui um item lancado anteriormente 		 
		 If nPosProdut > 0   
		    
			nlinha += nSaltoLinha
			
			oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
			
			ROMS0056(1)
			
			ROMS0053( (_cAlias)->A2_COD +'-'+ (_cAlias)->A2_NREDUZ , (_cAlias)->D2_QUANT , (_cAlias)->D2_UM , (_cAlias)->D2_QTSEGUM , (_cAlias)->D2_SEGUM , (_cAlias)->D2_I_FRET , (_cAlias)->VLBRUT )
			
			//Incrementa variaveis de somatorio de somatorio por Produto
			nTotqtde1 += (_cAlias)->D2_QUANT
			nTotqtde2 += (_cAlias)->D2_QTSEGUM
			nTotvlrFr += (_cAlias)->D2_I_FRET
			nTotvlrBr += (_cAlias)->VLBRUT
			
		    //Novo produto a ser inserido no relatorio
		 Else
		
			//Finaliza o produto anterior
			If Len(aProduto) > 0
			
				nlinha += nSaltoLinha
				
				oPrint:Line( nLinha , nColInic , nLinha , nColFinal )
				
				ROMS0056(1)
				
				ROMS0054( nTotqtde1 , nTotqtde2 , nTotvlrFr , nTotvlrBr )
				
				nlinha += nSaltoLinha
				
				ROMS0052()
				
			EndIf
			
			aAdd( aProduto , { AllTrim( (_cAlias)->PRODUTO ) } )
				
			nlinha += nSaltoLinha
			
			ROMS0056(0)      
			
			If nOrdem == 8
			
				ROMS0057( AllTrim( (_cAlias)->PRODUTO ) +'-'+ AllTrim( (_cAlias)->DESCR ) )
				
			ElseIf nOrdem == 9
			
				If Len( AllTrim( (_cAlias)->PRODUTO ) ) > 0
				
					ROMS0057(AllTrim((_cAlias)->PRODUTO) + '-' + AllTrim(Posicione("ZB9",1,xFilial("ZB9") + AllTrim((_cAlias)->PRODUTO),"ZB9_DESSUB" ) ) )
					
				Else
				
					ROMS0057('-')
					
				EndIf
				
			EndIf
			
			nlinha += nSaltoLinha
			
			oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
			
			ROMS0056(1)
			
			ROMS0053( (_cAlias)->A2_COD +'-'+ (_cAlias)->A2_NREDUZ , (_cAlias)->D2_QUANT , (_cAlias)->D2_UM , (_cAlias)->D2_QTSEGUM , (_cAlias)->D2_SEGUM , (_cAlias)->D2_I_FRET , (_cAlias)->VLBRUT )
			
			//Seta variaveis de controle de somatorio
			nTotqtde1 := (_cAlias)->D2_QUANT
			nTotqtde2 := (_cAlias)->D2_QTSEGUM
			nTotvlrFr := (_cAlias)->D2_I_FRET
			nTotvlrBr := (_cAlias)->VLBRUT
			
		 EndIf
	
	     (_cAlias)->( DBSkip() )
	  EndDo
	
	  //Finaliza o ultimo produto
	  nlinha += nSaltoLinha
	
	  oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	
	  ROMS0056(1)
	
	  ROMS0054(nTotqtde1,nTotqtde2,nTotvlrFr,nTotvlrBr)
	
	  nlinha += nSaltoLinha
	
	  ROMS0052()
	
	  //Imprime totalizador geral
	  nlinha += nSaltoLinha
	  nlinha += nSaltoLinha
	
	  ROMS0056(0)
	
	  ROMS0055(nGrTotqtd1,nGrTotqtd2,nGrTotvlFr,nGrTotvlBr)
	
	  nlinha += nSaltoLinha
	
	  ROMS0052()

   EndIf

End Sequence

(_cAlias)->( DBCloseArea() )

Return

/*
===============================================================================================================================
Programa--------: ROMS0057
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Imprime cabeçalho dos dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0057( cProduto )

oPrint:FillRect( { ( nlinha + 3 ) , nColInic , nlinha + nSaltoLinha , nColFinal } , oBrush )

oPrint:Box( nlinha , nColInic , nLinha + nSaltoLinha , nColFinal )

oPrint:Say( nlinha , nColFinal / 2 , cProduto , oFont16b , nColFinal ,,, 2 )

nlinha += nSaltoLinha

oPrint:Line( nLinha , nColInic , nLinha , nColFinal )

ROMS0056(0)

nLinInBox := nlinha

oPrint:Say( nlinha + 10 , nColInic + 0010 , "TRANSPORTADORA"	, oFont12b )
oPrint:Say( nlinha + 10 , nColInic + 0910 , "1a U.M."			, oFont12b )
oPrint:Say( nlinha + 10 , nColInic + 1325 , "2a U.M."			, oFont12b )
oPrint:Say( nlinha + 10 , nColInic + 1650 , "FRETE"				, oFont12b )
oPrint:Say( nlinha + 10 , nColInic + 1850 , "MÉDIA"				, oFont12b )
oPrint:Say( nlinha + 10 , nColInic + 2105 , "VALOR BRUTO"		, oFont12b )

Return

/*
===============================================================================================================================
Programa--------: ROMS0056
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Processa a quebra de páginas
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0056( impBox )

If nLinha > nqbrPagina

	If impBox == 1
		ROMS0052()
	EndIf
	
	oPrint:EndPage()	// Finaliza a Pagina
	oPrint:StartPage()	// Inicia uma nova Pagina
	
	nPagina++
	
	ROMS005C(1)		// Chama cabecalho
	
	nlinha		+= nSaltoLinha
	nLinInBox	:= nLinha
	
EndIf

Return

/*
===============================================================================================================================
Programa--------: ROMS0052
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Processa a impressao do box dos dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0052()

oPrint:Line( nLinInBox , 0725 , nLinha , 0725 ) // 1 UM
oPrint:Line( nLinInBox , 1090 , nLinha , 1090 ) // 2 UM
oPrint:Line( nLinInBox , 1505 , nLinha , 1505 ) // FRETE
oPrint:Line( nLinInBox , 1805 , nLinha , 1805 ) // MEDIA
oPrint:Line( nLinInBox , 2000 , nLinha , 2000 ) // VALOR BRUTO

oPrint:Box( nLinInBox , nColInic , nLinha , nColFinal )

Return

/*
===============================================================================================================================
Programa--------: ROMS0053
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Processa a impressao dos dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0053( cTransport , nqtde1 , cum1 , nqtde2 , cum2 , nFrete , nValBrut )

oPrint:Say( nlinha + 10 , nColInic + 0010 , SubStr(cTransport,1,46)											, oFont10 )
oPrint:Say( nlinha + 10 , nColInic + 0765 , Transform(nqtde1,"@E 9,999,999,999.99") + "-"+ PadR(cum1,2," ")	, oFont10 )
oPrint:Say( nlinha + 10 , nColInic + 1180 , Transform(nqtde2,"@E 9,999,999,999.99") + "-"+ PadR(cum2,2," ")	, oFont10 )
oPrint:Say( nlinha + 10 , nColInic + 1480 , 'R$ ' + Transform(nFrete,"@E 9,999,999,999.99")					, oFont10 )
oPrint:Say( nlinha + 10 , nColInic + 1700 , Transform(nFrete / nqtde1 ,"@E 999,999,999.99999")				, oFont10 )
oPrint:Say( nlinha + 10 , nColInic + 2040 , 'R$ ' + Transform(nValBrut,"@E 9,999,999,999.99")				, oFont10 )

Return

/*
===============================================================================================================================
Programa--------: ROMS0054
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Processa a impressao dos dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0054( nTotqtde1 , nTotqtde2 , nTotvlrFre , nTotValBr )

oPrint:Say( nlinha + 10 , nColInic + 0010 , 'TOTAL:'															, oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 0765 , Transform(nTotqtde1,"@E 9,999,999,999.99") + " "+ PadR("",2," ")	, oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 1180 , Transform(nTotqtde2,"@E 9,999,999,999.99") + " "+ PadR("",2," ")	, oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 1480 , 'R$ ' + Transform(nTotvlrFre,"@E 9,999,999,999.99")					, oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 1700 , Transform(nTotvlrFre / nTotqtde1 ,"@E 999,999,999.99999")			, oFont10b ) 
oPrint:Say( nlinha + 10 , nColInic + 2040 , 'R$ ' + Transform(nTotValBr,"@E 9,999,999,999.99")					, oFont10  )

Return

/*
===============================================================================================================================
Programa--------: ROMS0055
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Processa a impressao dos dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0055( nTotqtde1 , nTotqtde2 , nTotvlrFre , nTotValBr )

nLinInBox := nLinha

oPrint:Box( nlinha,nColInic,nLinha + nSaltoLinha,nColFinal)

oPrint:Say( nlinha + 10 , nColInic + 0010 , 'TOTAL GERAL:'														, oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 0765 , Transform(nTotqtde1,"@E 9,999,999,999.99") + " "+ PadR("",2," ")	, oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 1180 , Transform(nTotqtde2,"@E 9,999,999,999.99") + " "+ PadR("",2," ")	, oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 1480 , 'R$ ' + Transform(nTotvlrFre,"@E 9,999,999,999.99")					, oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 1700 , Transform(nTotvlrFre / nTotqtde1 ,"@E 999,999,999.99999")			, oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 2040 , 'R$ ' + Transform(nTotValBr,"@E 9,999,999,999.99")					, oFont10  )

Return

/*
===============================================================================================================================
Programa--------: ROMS005T
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Imprime o cabeçalho de Filiais
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS005T( cCodFilial )

oPrint:FillRect( { (nlinha+3) , nColInic , nlinha + nSaltoLinha , nColFinal - 230 } , oBrush )

oPrint:Box( nlinha , nColInic , nLinha + nSaltoLinha , nColFinal - 230 )

oPrint:Say( nlinha + nAjustAlt , nColInic + 025 , "Filial:"											, oFont14Prb )
oPrint:Say( nlinha + nAjustAlt , nColInic + 230 , AllTrim(cCodFilial) +'-'+ FWFilialName(,cCodFilial)	, oFont14Prb )

Return

/*
===============================================================================================================================
Programa--------: ROMS005A
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Imprime o cabeçalho de Data de Emissão
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS005A( cDtCarga )

oPrint:FillRect( { ( nlinha + 3 ) , nColInic , nlinha + nSaltoLinha , nColFinal - 850 } , oBrush )

oPrint:Box( nlinha , nColInic , nLinha + nSaltoLinha , nColFinal - 850 )

oPrint:Say( nlinha + nAjustAlt , nColInic + 10 , "Data de Emissão NF: "+ cDtCarga , oFont12b )

Return

/*
===============================================================================================================================
Programa--------: ROMS005M
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Imprime o cabeçalho de Total da Filial
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS005M( cCodFilial )

oPrint:FillRect( { ( nlinha + 3 ) , nColInic , nlinha + nSaltoLinha , nColFinal - 850 } , oBrush )

oPrint:Box( nlinha , nColInic , nLinha + nSaltoLinha , nColFinal - 850 )

oPrint:Say( nlinha + nAjustAlt , nColInic + 25 , "Total Filial: "+ AllTrim(cCodFilial) +'-'+ FWFilialName(,cCodFilial) , oFont14Prb )

Return

/*
===============================================================================================================================
Programa--------: ROMS0059
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Imprime o cabeçalho dos dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0059()

nLinInBox := nlinha

oPrint:FillRect( { ( nlinha + 3 ) , nColInic , nlinha + nSaltoLinha , nColFinal - 230 } , oBrush )

oPrint:Say( nlinha + nAjustAlt , nColInic + 0010 , "Tipo do Veículo" , oFont12b )
oPrint:Say( nlinha + nAjustAlt , nColInic + 0910 , "Qtde Cargas"		 , oFont12b )
oPrint:Say( nlinha + nAjustAlt , nColInic + 1240 , "Perc Cargas"	     , oFont12b )
oPrint:Say( nlinha + nAjustAlt , nColInic + 1570 , "Peso Bruto"		 , oFont12b )
oPrint:Say( nlinha + nAjustAlt , nColInic + 1880 , "Perc Peso"	     , oFont12b )

Return

/*
===============================================================================================================================
Programa--------: ROMS0050
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Imprime os dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function ROMS0050( cTipoVeic , nQtde , nPercent, nPes, nperpeso )
                                    
oPrint:Say( nlinha + nAjustAlt , nColInic + 0010 , cTipoVeic								, oFont12 )
oPrint:Say( nlinha + nAjustAlt , nColInic + 0810 , TransForm(nQtde   ,"@E 999,999,999,999")	, oFont12 )
oPrint:Say( nlinha + nAjustAlt , nColInic + 1260 , TransForm(nPercent,"@E 999.999") + ' %'	, oFont12 )
oPrint:Say( nlinha + nAjustAlt , nColInic + 1510 , TransForm(nPes   ,"@E 999,999,999,999")	, oFont12 )
oPrint:Say( nlinha + nAjustAlt , nColInic + 1940 , TransForm(nperpeso,"@E 999.999") + ' %'	, oFont12 )

Return

/*
===============================================================================================================================
Programa--------: ROMS056
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Imprime os dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS056(cTipoVeic,nQtde,nPercent,nPeso,nperpeso)  

oPrint:Line( nLinha , 0800 , nLinha + nSaltoLinha , 0800 ) //Tipo do Veiculo | Quantidade
oPrint:Line( nLinha , 1200 , nLinha + nSaltoLinha , 1200 ) //Quantidade | Percentual

oPrint:Box( nlinha , nColInic , nLinha + nSaltoLinha , nColFinal - 230 )

oPrint:Say( nlinha + nAjustAlt , nColInic + 0010 , cTipoVeic                                , oFont12b )
oPrint:Say( nlinha + nAjustAlt , nColInic + 0810 , TransForm(nQtde   ,"@E 999,999,999,999") , oFont12b )
oPrint:Say( nlinha + nAjustAlt , nColInic + 1260 , TransForm(nPercent,"@E 999.999") + ' %'  , oFont12b )
oPrint:Say( nlinha + nAjustAlt , nColInic + 1510 , TransForm(nPeso   ,"@E 999,999,999,999"), oFont12 )
oPrint:Say( nlinha + nAjustAlt , nColInic + 1940 , TransForm(nperpeso,"@E 999.999") + ' %'	, oFont12 )


Return

/*
===============================================================================================================================
Programa--------: ROMS0509
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Imprime o box dos dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0509()

nlinha += nSaltoLinha

oPrint:Line( nLinInBox , 0800 , nLinha , 0800 ) // Tipo do Veiculo | Quantidade
oPrint:Line( nLinInBox , 1200 , nLinha , 1200 ) // Quantidade | Percentual

oPrint:Box( nLinInBox , nColInic , nLinha , nColFinal - 230 )

Return

/*
===============================================================================================================================
Programa--------: ROMS0508
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Processa a quebra de páginas
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0508( impBox , nLinhas )

If nLinha > nqbrPagina // Quebra de pagina
	
	nlinha := nlinha - ( nSaltoLinha * nLinhas )
	
	If impBox == 1
		ROMS0509()
	EndIf
	
	oPrint:EndPage()	// Finaliza a Pagina
	oPrint:StartPage()	// Inicia uma nova Pagina
	ROMS005C(1)		// Chama cabecalho
	
	nPagina++
	
	nlinha += ( nSaltoLinha * 2 )
	
	nLinInBox := nlinha
	
EndIf

Return

/*
===============================================================================================================================
Programa--------: ROMS0507
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Verifica e Processa os dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0507()   

Local cQuery	   := ""	
Local nCountRec    := 0 
Local nPosFilial   := 0  , x

Local _cDir := GetTempPath()  // Diretório de Geração das planilhas.
Local _cArq := "_"+DToS(Date())+"_"+StrTran(Time(),":","")+".xml"  // Nome da planilha a ser gerada.   
Local _aCabecalho := {} // Array com o cabeçalho das colunas do relatório.
Local _cTitulo, _nI
Local _aDtCarTpVeic := {}  // Array por filial + Data da Carga +  Tipo de Veiculo 
Local _aTipoVeic := {}     // Array por filial + Tipo de Veiculo 
Local _ntotpes     // Peso total dos veiculos
Local _cDtCarga		:= ""  // Data da Carga
Local _nTotVeicDt	:= 0// Total de veiculos por data
Local _cFilial          := ""
                          
Private cAliasOr10 := GetNextAlias()
Private _aFilial   := {}
Private _aDadoCarg := {}   
Private _aDadCarGr := {}
Private _aTpVeic   := {}

Begin Sequence
   aAdd( _aTpVeic , { "F-4000    - Até 05 ton"           , 00000 , 5000      } )
   aAdd( _aTpVeic , { "TRUCK     - Até 16 ton"           , 05001 , 16000     } )
   aAdd( _aTpVeic , { "BI-TRUCK  - Até 22 ton"           , 16001 , 22000     } )
   aAdd( _aTpVeic , { "CARRETA   - Até 36 ton"           , 22001 , 36000     } )
   aAdd( _aTpVeic , { "BI-TREM   - Até 42 ton"           , 36001 , 42000     } )
   aAdd( _aTpVeic , { "RODO-TREM - Até 53 ton"           , 42001 , 53000     } )    
   aAdd( _aTpVeic , { "NAO ESPECIFICADO ACIMA DE 53 TON" , 53001 , 999999999 } )

   cFiltro := SubStr( cFiltro , 2 , Len( cFiltro ) )

   cQuery := " SELECT "
   cQuery +=     " DAK_FILIAL,"
   cQuery +=     " DAK_COD,"
   cQuery +=     " SF2.F2_EMISSAO DAK_DATA,"
   cQuery +=     " DAK_PESO "
   cQuery += " FROM "+ RetSqlName("DAK") +" DAK "
   cQuery += " JOIN "+ RetSqlName("DAI") +" DAI ON DAI.DAI_COD    = DAK.DAK_COD    AND DAI.DAI_FILIAL = DAK.DAK_FILIAL "
   cQuery += " JOIN "+ RetSqlName("DA3") +" DA3 ON DAK.DAK_CAMINH = DA3.DA3_COD "
   cQuery += " JOIN "+ RetSqlName("SF2") +" SF2 ON SF2.F2_DOC     = DAI.DAI_NFISCA AND SF2.F2_SERIE   = DAI.DAI_SERIE AND DAI.DAI_FILIAL = SF2.F2_FILIAL "
   cQuery += " JOIN "+ RetSqlName("SD2") +" SD2 ON SD2.D2_DOC     = SF2.F2_DOC     AND SD2.D2_SERIE   = SF2.F2_SERIE  AND SD2.D2_FILIAL  = SF2.F2_FILIAL "
   cQuery += " JOIN (SELECT A1_FILIAL, A1_COD, A1_LOJA, A1_NREDUZ, A1_MUN, A1_EST, A1_CGC, A1_GRPVEN, A1_COD_MUN " 
   cQuery += " 		FROM "+ RetSqlName("SA1") +" SA1 "
   cQuery += " 		WHERE SA1.D_E_L_E_T_ = ' ' "
   cQuery += " 		UNION
   cQuery += " 		SELECT A2_FILIAL, A2_COD, A2_LOJA, A2_NREDUZ, A2_MUN, A2_EST, A2_CGC, '' As A1_GRPVEN, A2_COD_MUN A1_COD_MUN " 
   cQuery += " 		FROM "+ RetSqlName("SA2") +" SA2 "
   cQuery += " 		WHERE SA2.D_E_L_E_T_ = ' '  ) SA1 ON  SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA  = SA1.A1_LOJA "
   cQuery += " JOIN "+ RetSqlName("SA3") +" SA3 ON SF2.F2_VEND1   = SA3.A3_COD "
   cQuery += " JOIN "+ RetSqlName("SB1") +" SB1 ON SD2.D2_COD     = SB1.B1_COD "
   cQuery += " JOIN "+ RetSqlName("DA4") +" DA4 ON DAK.DAK_MOTORI = DA4.DA4_COD "
   cQuery += " JOIN "+ RetSqlName("SA2") +" SA2 ON SF2.F2_I_CTRA  = SA2.A2_COD     AND SF2.F2_I_LTRA  = SA2.A2_LOJA "
   cQuery += " JOIN "+ RetSqlName("SC5") +" SC5 ON SC5.C5_FILIAL  = SD2.D2_FILIAL  AND SC5.C5_NUM     = SD2.D2_PEDIDO"
   cQuery += " WHERE "
   cQuery +=     " DAK.D_E_L_E_T_ = ' ' "
   cQuery += " AND DAI.D_E_L_E_T_ = ' ' "
   cQuery += " AND DA3.D_E_L_E_T_ = ' ' "
   cQuery += " AND SF2.D_E_L_E_T_ = ' ' "
   cQuery += " AND SD2.D_E_L_E_T_ = ' ' "
   cQuery += " AND SA3.D_E_L_E_T_ = ' ' "
   cQuery += " AND SB1.D_E_L_E_T_ = ' ' "
   cQuery += " AND DA4.D_E_L_E_T_ = ' ' "
   cQuery += " AND SA2.D_E_L_E_T_ = ' ' "
   cQuery += " AND SC5.D_E_L_E_T_ = ' ' "
   cQuery += " AND SA2.A2_I_CLASS IN ('T','A','G') "
   cQuery += " AND SD2.D2_CF <> '5927' "
   cQuery += cFiltro
   cQuery += " GROUP BY DAK_FILIAL , DAK_COD , SF2.F2_EMISSAO , DAK_PESO"
   cQuery += " ORDER BY DAK_FILIAL , SF2.F2_EMISSAO "

   If Select(cAliasOr10) > 0
      (cAliasOr10)->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TCGenQry(,,cQuery) , cAliasOr10 , .F. , .T. )

   COUNT TO nCountRec

   DBSelectArea(cAliasOr10)
   (cAliasOr10)->( DBGoTop() )
   
   If nCountRec > 0  
	
	  ProcRegua(nCountRec)
	
	  While (cAliasOr10)->( !Eof() )
	
		 IncProc( "Processando os dados do Relatório, favor aguardar..." )
		
		
		 nPosFilial := aScan( _aFilial , {|x| x[1] == (cAliasOr10)->(DAK_FILIAL) } ) // Insere somente as Filiais que ainda nao foram inseridas anteriormente
		
		 If nPosFilial == 0
			aAdd( _aFilial , { (cAliasOr10)->(DAK_FILIAL) } )
	  	 EndIf
		
		 //Armazena dados das cargas por Filial + Data da Carga + Tipo do Veiculo 
		 ROMS0505()
	
	     (cAliasOr10)->( DBSkip() )
	  EndDo
	
	  (cAliasOr10)->( DBCloseArea() )
	
	  //====================================================================================================
 	  // Ordena os dados por Filial + Data da Efetivacao da carga + Tipo do Veiculo
	  //====================================================================================================
	  _aDadoCarg:=aSort(_aDadoCarg,,,{|x, y| x[1] + x[2] + x[3] < y[1] + y[2] + y[3]})
	
	  //====================================================================================================
	  // Ordena os dados por Filial + Data da Efetivacao da carga + Tipo do Veiculo
	  //====================================================================================================
	  _aDadCarGr:=aSort(_aDadCarGr,,,{|x, y| x[1] + x[2] < y[1] + y[2]})
	  
      //====================================================================================================
	  // Se o usuário escolheu gerar relatório em Excel, gera dois relatórios em Excel utilizando Arrays
	  //====================================================================================================
      If MV_PAR26 == 2 // Relatório em Excel                     
         IncProc( "Os dados estão sendo gerados em Excel, favor aguardar..." )
        
         _nTotVeicDt := ROMS0502( _cFilial )[1]
         _ntotpes := ROMS0502( _cFilial )[2]
        
         _aDtCarTpVeic := {}  // Array por filial + Data da Carga +  Tipo de Veiculo   // _aDadoCarg
         _aTipoVeic := {}     // Array por filial + Tipo de Veiculo    // _aDadCarGr
       
         For _nI := 1 To Len(_aDadCarGr)
 		                    //   "Tipo do Veículo", "Qtde Cargas"      , "Perc Cargas"                                , "Peso Bruto"        , "Perc Peso" 
             aAdd(_aTipoVeic, {_aDadCarGr[_nI][3] , _aDadCarGr[_nI][4] , (( _aDadCarGr[_nI][4] / _nTotVeicDt ) * 100 ),  _aDadCarGr[_nI][6] , (( _aDadCarGr[_nI][6] / _nTotpes ) * 100 )})
         Next

         If Len(_aDadoCarg) > 0  // Pega o primeiro registro do array
            _cFilial := _aDadoCarg[1][1] // Filial de processamento
            _nTotVeicDt := ROMS0503( _aDadoCarg[1][1] , _aDadoCarg[1][2] )[1]
            _npesveicdt := ROMS0503( _aDadoCarg[1][1] , _aDadoCarg[1][2] )[2]
            _cDtCarga := _aDadoCarg[1][2]
         EndIf

         For _nI := 1 To Len( _aDadoCarg )
             // Realiza a mudança de somatoria por data e por filial.
             If _cFilial <>  _aDadoCarg[_nI][1] .Or. _cDtCarga <> _aDadoCarg[_nI][2]
                _cFilial := _aDadoCarg[_nI][1] // Filial de processamento
                _nTotVeicDt := ROMS0503( _aDadoCarg[_nI][1] , _aDadoCarg[_nI][2] )[1]
                _npesveicdt := ROMS0503( _aDadoCarg[_nI][1] , _aDadoCarg[_nI][2] )[2]
                _cDtCarga   := _aDadoCarg[_nI][2]    
             EndIf
            
             //                      "Data de Emissão NF",  "Tipo do Veículo", "Qtde Cargas"      , "Perc Cargas"                                , "Peso Bruto"      , "Perc Peso"
             aAdd(_aDtCarTpVeic,	{SToD(_aDadoCarg[_nI][2])  ,_aDadoCarg[_nI][4] , _aDadoCarg[_nI][5] , (( _aDadoCarg[_nI][5] / _nTotVeicDt ) * 100 ), _aDadoCarg[_nI][6], (( _aDadoCarg[_nI][6] / _npesVeicDt ) * 100 )})
         Next
        
         _cArq := "Veiculo_Data_e_Tipo"+_cArq // Nome da planilha a ser gerada.   
         _cTitulo := "RELATÓRIO DE FRETE POR TRANSPORTADOR (VEICULO - DATA E TIPO)"
        
         _aCabecalho := {} // Array com o cabeçalho das colunas do relatório. 
         // Alinhamento( 1-Left,2-Center,3-Right )
         // Formatação( 1-General,2-Number,3-Monetário,4-DateTime )
         //                Titulo das Colunas  ,Alinhamento ,Formatação, Totaliza?
         aAdd(_aCabecalho,{"Data de Emissão NF",2           ,4         ,.F.})   
         aAdd(_aCabecalho,{"Tipo do Veículo"   ,1           ,1         ,.F.})    
         aAdd(_aCabecalho,{"Qtde Cargas"       ,3           ,2         ,.F.}) 
         aAdd(_aCabecalho,{"Perc Cargas"       ,3           ,2         ,.F.}) 
         aAdd(_aCabecalho,{"Peso Bruto"        ,3           ,2         ,.F.}) 
         aAdd(_aCabecalho,{"Perc Peso"         ,3           ,2         ,.F.}) 
         U_ITGEREXCEL(_cArq,_cDir,_cTitulo,"Relatorio",_aCabecalho,_aDtCarTpVeic,.F.)

         _cArq := "Veiculo_Tipo"+_cArq // Nome da planilha a ser gerada.   
         _cTitulo := "RELATÓRIO DE FRETE POR TRANSPORTADOR (VEICULO - TIPO)"
        
         _aCabecalho := {} // Array com o cabeçalho das colunas do relatório. 
         // Alinhamento( 1-Left,2-Center,3-Right )
         // Formatação( 1-General,2-Number,3-Monetário,4-DateTime )
         //                Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?  
        
         aAdd(_aCabecalho,{"Tipo do Veículo"  ,1           ,1         ,.F.}) 
         aAdd(_aCabecalho,{"Qtde Cargas"      ,3           ,2         ,.F.}) 
         aAdd(_aCabecalho,{"Perc Cargas"      ,3           ,2         ,.F.}) 
         aAdd(_aCabecalho,{"Peso Bruto"       ,3           ,2         ,.F.}) 
         aAdd(_aCabecalho,{"Perc Peso"        ,3           ,2         ,.F.}) 

         U_ITGEREXCEL(_cArq,_cDir,_cTitulo,"Relatorio",_aCabecalho,_aTipoVeic,.F.)
         Break                              
      EndIf
	
	  //====================================================================================================
	  // Percorre todas as Filiais para realizar a impressao, desta forma ja gera a quebra por Filial
	  //====================================================================================================
	  For x := 1 To Len(_aFilial)
	
		  oPrint:EndPage()	// Finaliza a Pagina
		  oPrint:StartPage()	// Inicia uma nova Pagina
		
		  ROMS005C(1)		// Chama cabecalho
		
		  nPagina++
		
		  nlinha += ( nSaltoLinha * 2 )
		
		  ROMS005T( _aFilial[x,1] )
		
		  ROMS0504( _aFilial[x,1] ) // Imprime Dados por Filial + Data da Carga + Tipo do Veiculo
		
		  nlinha += ( nSaltoLinha * 2 )
		
		  ROMS0508(0,0)
		
		  ROMS005M( _aFilial[x,1] )
		
		  ROMS0501( _aFilial[x,1] ) // Imprime Dados por Filial + Tipo do Veiculo
	
	  Next x
	
   EndIf

End Sequence

Return

/*
===============================================================================================================================
Programa--------: ROMS0505
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Verifica e Processa os dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0505()  

Local nPosDtCarg:= 0
Local nPosCargGr:= 0
Local nPosPeso	:= 0

//Retorna a posicao do tipo do veiculo de acordo com o peso da carga corrente
nPosPeso := aScan( _aTpVeic , {|x| (cAliasOr10)->(DAK_PESO) >= x[2] .And. (cAliasOr10)->(DAK_PESO) <= x[3] } )

nPosDtCarg := aScan( _aDadoCarg , {|x| x[1] + x[2] + x[3] == (cAliasOr10)->(DAK_FILIAL) + (cAliasOr10)->(DAK_DATA) + AllTrim( Str( nPosPeso ) ) } )

If nPosPeso <> 0 // INSERIDO POR ERICH BUTTNER DIA 02/08/13 - VERIFICA SE A FILIAL ESTÁ EM BRANCO NÃO TENTA ADICIONAR NO ARRAY

	If nPosDtCarg == 0
	
		//1 - Filial
		//2 - Data da geracao da Carga
		//3 - Numero que identifica o tipo do veiculo
		//4 - Descricao do tipo do Veiculo
		//5 - Numero de Veiculos do tipo do veiculo encontrado por Filial + Data da efetivacao da Carga
		//6 - Peso da carga
		aAdd( _aDadoCarg , { (cAliasOr10)->(DAK_FILIAL) , (cAliasOr10)->(DAK_DATA) , AllTrim( Str( nPosPeso ) ) , _aTpVeic[nPosPeso][1] , 1 , (cAliasOr10)->(DAK_PESO)} )
	
	Else
	
		_aDadoCarg[nPosDtCarg][5] += 1 // Incrementa um no tipo de veiculo encontrada
		_aDadoCarg[nPosDtCarg][6] += (cAliasOr10)->(DAK_PESO) // Incrementa peso da carga
	
	EndIf
	
EndIf

nPosCargGr := aScan( _aDadCarGr , {|x| x[1] + x[2] == (cAliasOr10)->(DAK_FILIAL) + AllTrim( Str( nPosPeso ) ) } )

If nPosPeso <> 0 // INSERIDO POR ERICH BUTTNER DIA 02/08/13 - VERIFICA SE A FILIAL ESTÁ EM BRANCO NÃO TENTA ADICIONAR NO ARRAY

	If nPosCargGr == 0
	
		//1 - Filial
		//2 - Numero que identifica o tipo do veiculo
		//3 - Descricao do tipo do Veiculo
		//4 - Numero de Veiculos do tipo do veiculo encontrado por Filial
		aAdd( _aDadCarGr , { (cAliasOr10)->(DAK_FILIAL) , AllTrim( Str( nPosPeso ) ) , _aTpVeic[nPosPeso][1] , 1, 0, (cAliasOr10)->(DAK_PESO) } )
	
	Else
	
		_aDadCarGr[nPosCargGr][4] += 1 // Incrementa um no tipo de veiculo encontrada
		_aDadCarGr[nPosCargGr][6] += (cAliasOr10)->(DAK_PESO) // Incrementa carga no veiculo
	
	EndIf
	
EndIf

Return

/*
===============================================================================================================================
Programa--------: ROMS0504
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Imprime dados das Filiais
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0504(_cFil)

Local cDtCarga		:= ""
Local nTotVeicDt	:= 0  , y

For y := 1 To Len( _aDadoCarg )

    //Verifica se eh a mesma Filial     
 	If _aDadoCarg[y][1] == _cFil
		
	 	//Verifica a necessidade de se criar o cabecalho de data da Carga
	 	If cDtCarga <> _aDadoCarg[y][2]
	 	
	 		If Len( AllTrim( cDtCarga ) ) > 0
	 			ROMS0509()
 			EndIf
	 		
	 		nlinha += ( nSaltoLinha * 2 )
			
			ROMS0508(0,0)
			
			ROMS005A( DToC( SToD( _aDadoCarg[y][2] ) ) )
			
			nlinha += ( nSaltoLinha * 2 )
			
			ROMS0508(0,0)
			
			ROMS0059()
			
			nTotVeicDt := ROMS0503( _aDadoCarg[y][1] , _aDadoCarg[y][2] )[1]
			npesVeicDt := ROMS0503( _aDadoCarg[y][1] , _aDadoCarg[y][2] )[2]
	 		
 		EndIf
	 	
	 	nlinha += nSaltoLinha
	 	
 		oPrint:Line( nLinha , nColInic , nLinha , nColFinal - 230 ) // Tipo do Veiculo | Quantidade
 		
 		ROMS0508(1,1)
 		
	 	ROMS0050( _aDadoCarg[y][4] , _aDadoCarg[y][5] , (( _aDadoCarg[y][5] / nTotVeicDt ) * 100 ), _aDadoCarg[y][6], (( _aDadoCarg[y][6] / npesVeicDt ) * 100 ) )
	 	
	 	cDtCarga := _aDadoCarg[y][2]
	 	
	EndIf
	
Next y

//Imprime box da ultima pagina do ultima data da carga
ROMS0509()

Return

/*
===============================================================================================================================
Programa--------: ROMS0503
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Processa os dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0503( _cFilial , cDataCarga )

Local _aCont := {0,0}  , w

For w:=1 To Len(_aDadoCarg)

	If _aDadoCarg[w][1] + _aDadoCarg[w][2] == _cFilial + cDataCarga
	    _aCont[1] += _aDadoCarg[w][5]
	    _aCont[2] += _aDadoCarg[w][6]
	EndIf
	
Next w

Return( _aCont )

/*
===============================================================================================================================
Programa--------: ROMS0502
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Processa os dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0502( _cFilial )

Local _aCont := {0,0} , w

For w := 1 to Len(_aDadCarGr)

	If _aDadCarGr[w,1] == _cFilial
	    _aCont[1] += _aDadCarGr[w][4]
	    _aCont[2] += _aDadCarGr[w][6]
	EndIf

Next w

Return( _aCont )

/*
===============================================================================================================================
Programa--------: ROMS0501
Autor-----------: Jeovane
Data da Criacao-: 12/03/2009
===============================================================================================================================
Descrição-------: Processa os dados
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0501( _cFilial )

Local nTotVeicDt	:= 0      
Local nTotalQtde	:= 0  
Local nTotalPorc	:= 0
Local nTotalpes	:= 0  
Local nTotalPors	:= 0   , k

nTotVeicDt := ROMS0502( _cFilial )[1]
nTotpes := ROMS0502( _cFilial )[2]

nlinha += ( nSaltoLinha * 2 )

ROMS0059()

For k := 1 to Len( _aDadCarGr )

	If _aDadCarGr[k][1] == _cFilial
		
		nlinha += nSaltoLinha
		
 		oPrint:Line( nLinha , nColInic , nLinha , nColFinal - 230 ) // Tipo do Veiculo | Quantidade
 		
 		ROMS0508(1,1)
 		
 		ROMS0050( _aDadCarGr[k][3] , _aDadCarGr[k][4] , (( _aDadCarGr[k][4] / nTotVeicDt ) * 100 ),  _aDadCarGr[k][6] , (( _aDadCarGr[k][6] / nTotpes ) * 100 ))
	 	
		nTotalQtde += _aDadCarGr[k][4]
		nTotalPorc += ( _aDadCarGr[k][4] / nTotVeicDt ) * 100 
		nTotalpes += _aDadCarGr[k][6]
		nTotalPors += ( _aDadCarGr[k][6] / nTotpes ) * 100
		
	EndIf
	
Next k                                                            

ROMS0509()

nlinha += ( nSaltoLinha * 2 )

ROMS0508(0,0)

ROMS056( "TOTAL" , nTotalQtde , nTotalPorc, nTotalpes, nTotalPors ) // Imprime totalizador

Return

Static Function ROMS05Val(nOrdem)

If (nOrdem = 8 .Or. nOrdem = 9)
   U_ITMsg("Essa ordem "+aOrd[nOrdem]+ " não esta mais disponivel nesse menu.",'Atenção!',;
           "Acesse OMS --> Relatórios --> Especifico Italac --> Fretes por Produto [ROMS056].",3)
   Return .F.
EndIf

Return .T.
