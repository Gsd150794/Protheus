/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     | 19/08/2024 | Chamado 47782. Inclusão de nova coluna para exibir o tipo de averbação de carga.
Lucas Borges  | 09/10/2024 | Chamado 48465. Retirada manipulação do SX1
Lucas Borges  | 22/04/2025 | Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "Report.ch"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ROMS034
Autor-------------: Fabiano Dias
Data da Criacao---: 29/09/2011
Descrição---------: Relatorio utilizado para exibir os dados da rotina de lancamento de conhecimento de transporte(AOMS054).
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function ROMS034()

Private cPerg		:= "ROMS034"

Private QRY1		:= ''
Private QRY2		:= ''

Private oReport		:= Nil
Private oSecTran1	:= Nil
Private oSecTran2	:= Nil
Private oSecTran3	:= Nil
Private oSecTran4	:= Nil
Private oSecTran5	:= Nil
Private oSecTran6	:= Nil
Private oBreak1		:= Nil
Private oBreak2		:= Nil

Private cNomeTrans	:= ""
Private cNumFatura	:= ""

Private aOrd		:= { "Fatura" , "Carga" , "Transportadora" }

Private _cQuebra	:= ""
Private _cConhecim	:= ""
Private _nVlrCtr	:= 0

Private _cQbrTrans	:= ""
Private _cCtrTrans	:= ""
Private _nVlrTrans	:= 0

Private aQbrNfs		:= {}
Private _nVlrPesLi	:= 0
Private _nVlrPesBr	:= 0

Pergunte( cPerg , .F. )

DEFINE REPORT oReport NAME cPerg TITLE "Conhecimento de Transporte x N.F." PARAMETER cPerg ACTION {|oReport| PrintReport(oReport)} Description "Este relatório emitirá a relação de conhecimento de transporte x Nota Fiscal"

oReport:SetLandscape() // Seta Padrao de impressao como Paisagem
oReport:SetTotalInLine(.F.)

oReport:nFontBody	:= 08
oReport:cFontBody	:= "Courier New"
oReport:nLineHeight	:= 50 // Define a altura da linha.


oReport:DisableOrientation() // Desabilita a escolha do tipo de orientacao da pagina retrato ou paisagem
oReport:SetMsgPrint( 'Aguarde enquanto os dados estão sendo processados...' ) // Mensagem exibida no momento da impressao

//====================================================================================================
// Define secoes para primeira ordem - Fatura
//====================================================================================================
// Secao dados da Transportadora
//====================================================================================================
DEFINE Section oSecTran1 OF oReport TITLE "Ordem_Fatura" TABLES "SA2" ORDERS aOrd

DEFINE CELL NAME "CODTRANSP"  OF oSecTran1 ALIAS "SA2"  TITLE "Transportadora"      SIZE 15 
DEFINE CELL NAME "LOJTRANSP"  OF oSecTran1 ALIAS "SA2"  TITLE "Loja" 		 	    SIZE 10
DEFINE CELL NAME "CGCTRANSP"  OF oSecTran1 ALIAS "SA2"  TITLE "CNPJ/CPF" 		   	SIZE 20 BLOCK{|| IIf (Len(AllTrim(QRY1->CGCTRANSP)) == 11,Transform(AllTrim(QRY1->CGCTRANSP),"@R 999.999.999-99"),Transform(AllTrim(QRY1->CGCTRANSP),"@R! NN.NNN.NNN/NNNN-99"))  }
DEFINE CELL NAME "DESCTRANSP" OF oSecTran1 ALIAS "SA2"  TITLE "Razao Social" 		SIZE 60

DEFINE CELL NAME "TRANSPORT"  OF oSecTran1 ALIAS "ZZN"  TITLE "Ctr/Serie" 	 	    SIZE 10 BLOCK{|| QRY1->CODTRANSP + QRY1->LOJTRANSP }

oSecTran1:Disable()
oSecTran1:SetLineStyle(.T.)
oSecTran1:SetLinesBefore(1)

oSecTran1:Cell("TRANSPORT"):Disable()
oSecTran1:OnPrintLine( {|| cNomeTrans := QRY1->CODTRANSP +"/"+ QRY1->LOJTRANSP +' - '+ SubStr( QRY1->DESCTRANSP , 1 , 40 ) } )

//====================================================================================================
// Secao numero da Fatura
//====================================================================================================
DEFINE Section oSecTran2 OF oSecTran1 TITLE "Numero_Fatura" TABLES "ZZN"

DEFINE CELL NAME "FATURA"	 OF oSecTran2 ALIAS "ZZN"    TITLE "Fatura" SIZE 40

oSecTran2:Disable()
oSecTran2:SetLineStyle(.T.)
oSecTran2:SetLinesBefore(0)

//====================================================================================================
// Secao dados da Fatura
//====================================================================================================
DEFINE Section oSecTran3 OF oSecTran2 TITLE "Dados_da_Fatura" TABLES "ZZN","SF2","CC2"

DEFINE CELL NAME "CTR"        OF oSecTran3 ALIAS "ZZN"  TITLE "Ctr/Serie" 	 	    SIZE 21 BLOCK{|| QRY1->CONTRANS + '/' + QRY1->SERCONRANS }
DEFINE CELL NAME "VALOR"      OF oSecTran3 ALIAS "ZZN"  TITLE "Valor CTR" 		   	SIZE 20 PICTURE PesqPict("ZZN","ZZN_VLRCTR")
DEFINE CELL NAME "NF" 		  OF oSecTran3 ALIAS "ZZN"  TITLE "NF/Serie" 	     	SIZE 20 BLOCK{|| QRY1->NF + '/' + QRY1->SERIENF }
DEFINE CELL NAME "CARGA" 	  OF oSecTran3 ALIAS "ZZN"  TITLE "Carga" 	    		SIZE 11
DEFINE CELL NAME "PESLIQUI"   OF oSecTran3 ALIAS "SF2"  TITLE "P.Liquido"     		SIZE 18 PICTURE PesqPict("SF2","F2_PLIQUI")
DEFINE CELL NAME "PESBRUTO"   OF oSecTran3 ALIAS "SF2"  TITLE "P.Bruto"     		SIZE 18 PICTURE PesqPict("SF2","F2_PBRUTO")
DEFINE CELL NAME "PESCARGA"   OF oSecTran3 ALIAS "SF2"  TITLE "P.c/ Pallet"   		SIZE 18 PICTURE PesqPict("DAK","DAK_PESO")
DEFINE CELL NAME "DESCMUN"    OF oSecTran3 ALIAS "CC2"  TITLE "Municipio"   		SIZE 35
DEFINE CELL NAME "OBS"    	  OF oSecTran3 ALIAS "ZZN"  TITLE "Observacao"   		SIZE 40
DEFINE CELL NAME "DESCMOTIV"  OF oSecTran3 ALIAS "ZZN"  TITLE "Mot.Div.Valor"  		SIZE 32
DEFINE CELL NAME "STATUS"  	  OF oSecTran3 ALIAS "ZZN"  TITLE "Status"   		    SIZE 22 BLOCK{|| ROMS034S(xFilial("ZZN"),QRY1->CODTRANSP,QRY1->LOJTRANSP,QRY1->CONTRANS,QRY1->SERCONRANS) }
DEFINE CELL NAME "QBRFATURA"  OF oSecTran3 ALIAS "ZZN"  TITLE "QUEBRAFAT" 	 	    SIZE 10 BLOCK{|| QRY1->CODTRANSP + QRY1->LOJTRANSP + QRY1->FATURA}
DEFINE CELL NAME "FRETECARGA" OF oSecTran3 ALIAS "SF2"  TITLE "Vlr.Frete OC"     	SIZE 18 PICTURE PesqPict("SF2","F2_I_FRET") 

DEFINE CELL NAME "TIPOAVERB" OF oSecTran3 ALIAS "SA2"  TITLE "Tipo Averb.Carga"     SIZE 18 BLOCK {|| If(QRY1->TIPOAVERBC=="E","EMBARCADOR",If(QRY1->TIPOAVERBC=="T","TRANSPORTADOR",""))} 

oSecTran3:Cell("QBRFATURA"):Disable()
oSecTran3:OnPrintLine({|| cNumFatura := QRY1->FATURA })

oSecTran3:Disable()
oSecTran3:SetCellBorder(5,2,CLR_LIGHTGRAY,.T.)
oSecTran3:SetCellBorder(5,2,CLR_LIGHTGRAY,.F.)
oSecTran3:SetAutoSize(.T.)
oSecTran3:SetLinesBefore(0)
oSecTran3:SetHeaderPage(.T.)

oSecTran3:Cell("VALOR"):SetHeaderAlign("RIGHT")
oSecTran3:Cell("PESLIQUI"):SetHeaderAlign("RIGHT")
oSecTran3:Cell("PESBRUTO"):SetHeaderAlign("RIGHT")
oSecTran3:Cell("PESCARGA"):SetHeaderAlign("RIGHT")

oSecTran3:SetTotalInLine(.F.)

//====================================================================================================
// Define secoes para segunda ordem - Carga
//====================================================================================================
// Secao dados da Transportadora
//====================================================================================================
DEFINE Section oSecTran4 OF oReport TITLE "Ordem_Carga" TABLES "SA2" ORDERS aOrd

DEFINE CELL NAME "CODTRANSP"  OF oSecTran4 ALIAS "SA2"  TITLE "Transportadora"      SIZE 15
DEFINE CELL NAME "LOJTRANSP"  OF oSecTran4 ALIAS "SA2"  TITLE "Loja" 		 	    SIZE 10
DEFINE CELL NAME "CGCCPF"     OF oSecTran4 ALIAS "SA2"  TITLE "CNPJ/CPF" 		   	SIZE 20 BLOCK{|| IIf (Len(AllTrim(QRY2->CGCTRANSP)) == 11,Transform(AllTrim(QRY2->CGCTRANSP),"@R 999.999.999-99"),Transform(AllTrim(QRY2->CGCTRANSP),"@R! NN.NNN.NNN/NNNN-99"))  }
DEFINE CELL NAME "DESCTRANSP" OF oSecTran4 ALIAS "SA2"  TITLE "Razao Social" 		SIZE 60
DEFINE CELL NAME "TRANSPORT"  OF oSecTran4 ALIAS "ZZN"  TITLE "Ctr/Serie" 	 	    SIZE 10 BLOCK{|| QRY2->CODTRANSP + QRY2->LOJTRANSP }

oSecTran4:Disable()
oSecTran4:SetLineStyle(.T.)
oSecTran4:SetLinesBefore(1)

oSecTran4:Cell("TRANSPORT"):Disable()
oSecTran4:OnPrintLine({|| cNomeTrans := QRY2->CODTRANSP  + "/" + QRY2->LOJTRANSP + ' - ' + SubStr(QRY2->DESCTRANSP,1,40)})

//====================================================================================================
// Secao numero da Carga
//====================================================================================================
DEFINE Section oSecTran5 OF oSecTran4 TITLE "Carga" TABLES "ZZN"

DEFINE CELL NAME "CARGA" OF oSecTran5 ALIAS "ZZN"   TITLE "Carga" SIZE 40

oSecTran5:Disable()
oSecTran5:SetLineStyle(.T.)
oSecTran5:SetLinesBefore(0)

//====================================================================================================
// Secao dados da Carga
//====================================================================================================
DEFINE Section oSecTran6 OF oSecTran5 TITLE "Dados_da_Carga" TABLES "ZZN","SF2","CC2"

DEFINE CELL NAME "CTR"        OF oSecTran6 ALIAS "ZZN"  TITLE "Ctr/Serie" 	 	    SIZE 21 BLOCK{|| QRY2->CONTRANS + '/' + QRY2->SERCONRANS }
DEFINE CELL NAME "VALOR"      OF oSecTran6 ALIAS "ZZN"  TITLE "Valor CTR" 		   	SIZE 20 PICTURE PesqPict("ZZN","ZZN_VLRCTR")
DEFINE CELL NAME "NF" 		  OF oSecTran6 ALIAS "ZZN"  TITLE "NF/Serie" 	     	SIZE 20 BLOCK{|| QRY2->NF + '/' + QRY2->SERIENF }
DEFINE CELL NAME "FATURA" 	  OF oSecTran6 ALIAS "ZZN"  TITLE "Fatura" 	    		SIZE 15
DEFINE CELL NAME "PESLIQUI"   OF oSecTran6 ALIAS "SF2"  TITLE "P.Liquido"     		SIZE 18 PICTURE PesqPict("SF2","F2_PLIQUI")
DEFINE CELL NAME "PESBRUTO"   OF oSecTran6 ALIAS "SF2"  TITLE "P.Bruto"     		SIZE 18 PICTURE PesqPict("SF2","F2_PBRUTO")
DEFINE CELL NAME "PESCARGA"   OF oSecTran6 ALIAS "SF2"  TITLE "P.c/ Pallet"   		SIZE 18 PICTURE PesqPict("DAK","DAK_PESO")
DEFINE CELL NAME "DESCMUN"    OF oSecTran6 ALIAS "CC2"  TITLE "Municipio"   		SIZE 35
DEFINE CELL NAME "OBS"    	  OF oSecTran6 ALIAS "ZZN"  TITLE "Observacao"   		SIZE 40
DEFINE CELL NAME "DESCMOTIV"  OF oSecTran6 ALIAS "ZZN"  TITLE "Mot.Div.Valor"  		SIZE 35
DEFINE CELL NAME "STATUS"  	  OF oSecTran6 ALIAS "ZZN"  TITLE "Status"   		    SIZE 22 BLOCK{|| ROMS034S(xFilial("ZZN"),QRY2->CODTRANSP,QRY2->LOJTRANSP,QRY2->CONTRANS,QRY2->SERCONRANS) }
DEFINE CELL NAME "QBRFATURA"  OF oSecTran6 ALIAS "ZZN"  TITLE "QUEBRAFAT" 	 	    SIZE 10 BLOCK{|| QRY2->CODTRANSP + QRY2->LOJTRANSP + QRY2->CARGA}
DEFINE CELL NAME "FRETECARGA" OF oSecTran6 ALIAS "SF2"  TITLE "Vlr.Frete OC"     	SIZE 18 PICTURE PesqPict("SF2","F2_I_FRET") 
DEFINE CELL NAME "TIPOAVERB"  OF oSecTran6 ALIAS "SA2"  TITLE "Tipo Averb.Carga"   	SIZE 18 BLOCK {|| If(QRY2->TIPOAVERBC=="E","EMBARCADOR",If(QRY2->TIPOAVERBC=="T","TRANSPORTADOR",""))}  

oSecTran6:Cell("QBRFATURA"):Disable()

oSecTran6:OnPrintLine({|| ROMS034C(QRY2->CODTRANSP,QRY2->LOJTRANSP,QRY2->CARGA,QRY2->VALOR,QRY2->PESCARGA,QRY2->CONTRANS,QRY2->SERCONRANS,QRY2->NF,QRY2->SERIENF,QRY2->PESLIQUI,QRY2->PESBRUTO) })

oSecTran6:Disable()
oSecTran6:SetCellBorder(5,2,CLR_LIGHTGRAY,.T.)
oSecTran6:SetCellBorder(5,2,CLR_LIGHTGRAY,.F.)
oSecTran6:SetAutoSize(.T.)
oSecTran6:SetLinesBefore(0)
oSecTran6:SetHeaderPage(.T.)

oSecTran6:Cell("VALOR"):SetHeaderAlign("RIGHT")
oSecTran6:Cell("PESLIQUI"):SetHeaderAlign("RIGHT")
oSecTran6:Cell("PESBRUTO"):SetHeaderAlign("RIGHT")
oSecTran6:Cell("PESCARGA"):SetHeaderAlign("RIGHT")
oSecTran6:Cell("PESCARGA"):Hide() // Desabilita a impressao da celula

oSecTran6:SetTotalInLine(.F.) // Define se os totalizadores serão impressos em linha (.T.) ou coluna(.F.)

//====================================================================================================
// HEDER - 02/12/11 - Implementacao de nova ordem - Define secoes para terceira ordem - Transportadora
//====================================================================================================
// Secao dados da Transportadora
//====================================================================================================
DEFINE Section oSecTran7 OF oReport TITLE "Ordem_Transportadora" TABLES "ZZN","SF2","CC2" ORDERS aOrd

DEFINE CELL NAME "TRANSPLOJA" OF oSecTran7 ALIAS "ZZN"  TITLE "Transportadora"      SIZE 50 BLOCK{|| CODTRANSP + '/' + LOJTRANSP + ' - ' + AllTrim(DESCTRANSP) }
DEFINE CELL NAME "CGCTRANSP"  OF oSecTran7 ALIAS "ZZN"  TITLE "CNPJ/CPF" 		   	SIZE 20 BLOCK{|| IIf (Len(AllTrim(QRY3->CGCTRANSP)) == 11,Transform(AllTrim(QRY3->CGCTRANSP),"@R 999.999.999-99"),Transform(AllTrim(QRY3->CGCTRANSP),"@R! NN.NNN.NNN/NNNN-99"))  }

oSecTran7:SetLineStyle(.T.)

oSecTran7:Cell("TRANSPLOJA") :lBold := .T.
oSecTran7:Cell("CGCTRANSP")  :lBold := .T.

oSecTran7:SetLinesBefore(2)
oSecTran7:SetHeaderPage(.T.)
oSecTran7:Disable()

//====================================================================================================
// Secao dados da Fatura
//====================================================================================================
DEFINE Section oSecTran8 OF oSecTran7 TITLE "Dados_do_Transp" TABLES "ZZN","SF2","CC2"

DEFINE CELL NAME "FATURA" 	  OF oSecTran8 ALIAS "ZZN"  TITLE "Fatura" 	    		SIZE 17
DEFINE CELL NAME "CTR"        OF oSecTran8 ALIAS "ZZN"  TITLE "Ctr/Serie" 	 	    SIZE 21 BLOCK{|| QRY3->CONTRANS + '/' + QRY3->SERCONRANS }
DEFINE CELL NAME "VALOR"      OF oSecTran8 ALIAS "ZZN"  TITLE "Valor CTR" 		   	SIZE 20 PICTURE PesqPict("ZZN","ZZN_VLRCTR")
DEFINE CELL NAME "NF" 		  OF oSecTran8 ALIAS "ZZN"  TITLE "NF/Serie" 	     	SIZE 20 BLOCK{|| QRY3->NF + '/' + QRY3->SERIENF }
DEFINE CELL NAME "CARGA" 	  OF oSecTran8 ALIAS "ZZN"  TITLE "Carga" 	    		SIZE 11
DEFINE CELL NAME "PESLIQUI"   OF oSecTran8 ALIAS "SF2"  TITLE "P.Liquido"     		SIZE 18 PICTURE PesqPict("SF2","F2_PLIQUI")
DEFINE CELL NAME "PESBRUTO"   OF oSecTran8 ALIAS "SF2"  TITLE "P.Bruto"     		SIZE 18 PICTURE PesqPict("SF2","F2_PBRUTO")
DEFINE CELL NAME "PESCARGA"   OF oSecTran8 ALIAS "SF2"  TITLE "P.c/ Pallet"   		SIZE 18 PICTURE PesqPict("DAK","DAK_PESO")
DEFINE CELL NAME "DESCMUN"    OF oSecTran8 ALIAS "CC2"  TITLE "Municipio"   		SIZE 30
DEFINE CELL NAME "OBS"    	  OF oSecTran8 ALIAS "ZZN"  TITLE "Observacao"   		SIZE 40
DEFINE CELL NAME "DESCMOTIV"  OF oSecTran8 ALIAS "ZZN"  TITLE "Mot.Div.Valor"  		SIZE 25  
DEFINE CELL NAME "STATUS" 	  OF oSecTran8 ALIAS "ZZN"  TITLE "Status"   		    SIZE 22 BLOCK{|| ROMS034S(xFilial("ZZN"),QRY3->CODTRANSP,QRY3->LOJTRANSP,QRY3->CONTRANS,QRY3->SERCONRANS) }
DEFINE CELL NAME "FRETECARGA" OF oSecTran8 ALIAS "SF2"  TITLE "Vlr.Frete OC"   		SIZE 18 PICTURE PesqPict("SF2","F2_I_FRET") 
DEFINE CELL NAME "TIPOAVERB"  OF oSecTran8 ALIAS "SA2"  TITLE "Tipo Averb.Carga" 	SIZE 18 BLOCK {|| If(QRY3->TIPOAVERBC=="E","EMBARCADOR",If(QRY3->TIPOAVERBC=="T","TRANSPORTADOR",""))}  
oSecTran8:SetCellBorder(5,2,CLR_LIGHTGRAY,.T.)
oSecTran8:SetCellBorder(5,2,CLR_LIGHTGRAY,.F.)

oSecTran8:SetAutoSize(.T.)
oSecTran8:SetLinesBefore(0)
oSecTran8:SetHeaderPage(.F.)

oSecTran8:Cell("VALOR")   :SetHeaderAlign("RIGHT")
oSecTran8:Cell("PESLIQUI"):SetHeaderAlign("RIGHT")
oSecTran8:Cell("PESBRUTO"):SetHeaderAlign("RIGHT")
oSecTran8:Cell("PESCARGA"):SetHeaderAlign("RIGHT")

oSecTran8:SetTotalInLine(.F.) // Define se os totalizadores serão impressos em linha (.T.) ou coluna(.F.)

oSecTran8:Disable()

//====================================================================================================
// Exibe a tela de configuração para a impressão do relatório
//====================================================================================================
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: PrintReport
Autor-------------: Fabiano Dias
Data da Criacao---: 29/09/2011
Descrição---------: Rotina que realiza a consulta e estrutura os dados para impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function PrintReport(oReport)

Local cFiltro	:= "%"
Local _cFiltFil	:= "%"
Private nOrdem	:= oSecTran1:GetOrder() //Busca ordem selecionada pelo usuario

oReport:SetTitle( "Relação de Conhecimento Transporte x Nota Fiscal Saída - Ordem "+ aOrd[nOrdem] +" - Emissao de "+ DToC(MV_PAR11) +" até "+ DToC(MV_PAR12))

//====================================================================================================
// Define o filtro de acordo com os parametros digitados
//====================================================================================================

//====================================================================================================
// Filtra somente a filial corrente
//====================================================================================================
cFiltro   += " AND ZZN.ZZN_FILIAL = '"+ xFilial("ZZN") +"' "
_cFiltFil += " AND F2.F2_FILIAL   = '"+ xFilial("ZZN") +"' "
cFiltro   += " AND F2.F2_FILIAL   = '"+ xFilial("SF2") +"' "
_cFiltFil += " AND D2.D2_FILIAL   = '"+ xFilial("SF2") +"' "
_cFiltFil += " %"

//====================================================================================================
// Filtra o codigo da Transportadora
//====================================================================================================
cFiltro += " AND ZZN.ZZN_FTRANS BETWEEN '"+ MV_PAR01 +"' AND '"+ MV_PAR03 +"' "

//====================================================================================================
// Filtra a loja da transportadora
//====================================================================================================
cFiltro += " AND ZZN.ZZN_LOJAFT BETWEEN '"+ MV_PAR02 +"' AND '"+ MV_PAR04 +"' "

//====================================================================================================
// Conhecimento de transporte
//====================================================================================================
cFiltro += " AND ZZN.ZZN_CTRANS BETWEEN '"+ MV_PAR05 +"' AND '"+ MV_PAR06 +"' "

//====================================================================================================
// Numero da Fatura
//====================================================================================================
cFiltro += " AND ZZN.ZZN_FATURA BETWEEN '"+ MV_PAR07 +"' AND '"+ MV_PAR08 +"' "

//====================================================================================================
// Nota fiscal
//====================================================================================================
cFiltro += " AND ZZN.ZZN_NFISCA BETWEEN '"+ MV_PAR09 +"' AND '"+ MV_PAR10 +"' "

//====================================================================================================
// Emissao da nota fiscal
//====================================================================================================
cFiltro += " AND F2.F2_EMISSAO BETWEEN '"+ DToS( MV_PAR11 ) +"' AND '"+ DToS( MV_PAR12 ) +"' "

//====================================================================================================
// Carga
//====================================================================================================
cFiltro += " AND ZZN.ZZN_CARGA BETWEEN '"+ MV_PAR13 +"' AND '"+ MV_PAR14 +"' "

//====================================================================================================
// Data de Previsao de pagamento - Incluido filtro para imprimir apenas pgto na data solicitada
//====================================================================================================
If Len( AllTrim( DToS( MV_PAR15 ) ) ) + Len( AllTrim( DToS( MV_PAR16 ) ) ) > 0
	cFiltro += " AND ZZN.ZZN_PRVPAG BETWEEN '"+ DToS( MV_PAR15 ) +"' AND '"+ DToS( MV_PAR16 ) +"' "
EndIf

If !Empty( AllTrim( MV_PAR17 ) )
	cFiltro += " AND ZZN.ZZN_MTDIVF IN "+ FormatIn( MV_PAR17 , ";" )
EndIf

cFiltro += "%"

//====================================================================================================
// Primeira Ordem - Transportadora
//====================================================================================================
If nOrdem == 1

	oSecTran1:Enable()
	oSecTran2:Enable()
	oSecTran3:Enable()
	
	//====================================================================================================
	// Quebras
	//====================================================================================================
	oBreak1 := TRBreak():New( oSecTran1 , oSecTran1:CELL( "TRANSPORT" ) , "Total Transportadora: "+ cNomeTrans , .F. )
	
	oBreak1:SetTotalText( {|| "Total Transportadora: "+ cNomeTrans } )
	
	TRFunction():New( oSecTran3:Cell("VALOR") , NIL , "SUM" , oBreak1 , NIL , NIL , NIL , .F. , .T. )
	TRFunction():New( oSecTran3:Cell("VALOR") , NIL , "SUM" , NIL     , NIL , NIL , NIL , .T. , .F. )
	
	//====================================================================================================
	// Executa query para consultar Dados
	//====================================================================================================
	BEGIN REPORT QUERY oSecTran1
	
		BeginSql alias "QRY1"
		
			SELECT
				DADOS.CODTRANSP,
				DADOS.LOJTRANSP,
				DADOS.CODTRANSP,
				DADOS.LOJTRANSP,
				DADOS.DESCTRANSP,
				DADOS.CGCTRANSP,
				DADOS.FATURA,
				DADOS.ITEM,
				DADOS.CONTRANS,
				DADOS.SERCONRANS,
				DADOS.VALOR,
				DADOS.NF,
				DADOS.SERIENF,
				DADOS.CARGA,
				DADOS.OBS,
				DADOS.DESCMOTIV,
				DADOS.DESCMUN,
				DADOS.PREV_PGTO,
				DADOS.PESLIQUI,
				DADOS.PESBRUTO,
				DADOS.PESCARGA,
				DADOS.FRETECARGA,
				DADOS.TIPOAVERBC
			FROM (	SELECT
						ZZN.ZZN_FTRANS	AS CODTRANSP,
						ZZN.ZZN_LOJAFT	AS LOJTRANSP,
						SA2.A2_NOME		AS DESCTRANSP,
						SA2.A2_CGC		AS CGCTRANSP,
						ZZN.ZZN_FATURA	AS FATURA,
						ZZN.ZZN_ITEM	AS ITEM,
						ZZN.ZZN_CTRANS	AS CONTRANS,
						ZZN.ZZN_SERCTR	AS SERCONRANS,
						ZZN.ZZN_VLRCTR	AS VALOR,
						ZZN.ZZN_NFISCA	AS NF,
						ZZN.ZZN_SERIE	AS SERIENF,
						ZZN.ZZN_CARGA	AS CARGA,
						ZZN.ZZN_OBS		AS OBS,
						(	SELECT ZZO.ZZO_DESCRI
							FROM %Table:ZZO% ZZO
							WHERE	ZZO.D_E_L_E_T_ = ' '
							AND		ZZN.ZZN_MTDIVF = ZZO.ZZO_CODIGO ) AS DESCMOTIV,
						CC2.CC2_MUN		AS DESCMUN,
						ZZN.ZZN_PRVPAG	AS PREV_PGTO,
						F2.F2_PLIQUI	AS PESLIQUI,
						F2.F2_PBRUTO	AS PESBRUTO,
                        SA2.A2_I_TPAVE  AS TIPOAVERBC,
						(SELECT DAK_PESO FROM %Table:DAK% DAK WHERE DAK.D_E_L_E_T_ = ' ' AND DAK.DAK_FILIAL = F2.F2_FILIAL AND ZZN.ZZN_CARGA = DAK.DAK_COD AND ROWNUM = 1 )	AS PESCARGA,
						F2.F2_I_FRET    AS FRETECARGA
					FROM %Table:ZZN% ZZN
					JOIN %Table:SA2% SA2 ON SA2.A2_COD     = ZZN.ZZN_FTRANS AND SA2.A2_LOJA    = ZZN_LOJAFT
					JOIN %Table:SF2% F2  ON ZZN.ZZN_FILIAL = ZZN.ZZN_FILIAL AND ZZN.ZZN_NFISCA = F2.F2_DOC     AND ZZN.ZZN_SERIE = F2.F2_SERIE
					JOIN %Table:SA1% A1  ON A1.A1_COD      = F2.F2_CLIENTE  AND A1.A1_LOJA     = F2.F2_LOJA
					JOIN %Table:CC2% CC2 ON CC2.CC2_EST    = A1.A1_EST      AND CC2.CC2_CODMUN = A1.A1_COD_MUN
                    JOIN %Table:SA2% SA2 ON SA2.A2_COD = F2.F2_I_CTRA AND SA2.A2_LOJA = F2.F2_I_LTRA
					WHERE
						ZZN.D_E_L_E_T_ = ' '
					AND SA2.D_E_L_E_T_ = ' '
					AND F2.D_E_L_E_T_  = ' '
					AND A1.D_E_L_E_T_  = ' '
					AND CC2.D_E_L_E_T_ = ' '
					AND ZZN.ZZN_NFISCA <> ' '
					AND SA2.D_E_L_E_T_  = ' '
					
					%Exp:cFiltro%
					
					) DADOS
			
			ORDER BY DADOS.LOJTRANSP , DADOS.DESCTRANSP , DADOS.FATURA , DADOS.CONTRANS
			
		EndSql
		
	END REPORT QUERY oSecTran1
	
	oSecTran2:SetParentQuery()
	oSecTran2:SetParentFilter({|cParam| QRY1->CODTRANSP + QRY1->LOJTRANSP == cParam},{|| QRY1->CODTRANSP + QRY1->LOJTRANSP })
	
	oSecTran3:SetParentQuery()
	oSecTran3:SetParentFilter({|cParam| QRY1->FATURA == cParam},{|| QRY1->FATURA })
	
	oSecTran1:Print(.T.)

//====================================================================================================
// Segunda Ordem - Carga
//====================================================================================================
ElseIf nOrdem == 2

	oSecTran4:Enable()
	oSecTran5:Enable()
	oSecTran6:Enable()
	
	//====================================================================================================
	// Quebras
	//====================================================================================================
	oBreak2 := TRBreak():New( oSecTran4 , oSecTran4:CELL( "TRANSPORT" ) , "Total Transportadora: "+ cNomeTrans , .F. )
	
	oBreak2:SetTotalText( {|| "Total Transportadora: "+ cNomeTrans } )
	
	TRFunction():New( oSecTran6:Cell("VALOR")    , NIL , "MAX"     , oBreak2 , NIL , NIL , {|| _nVlrTrans } , .F. , .F. )
	TRFunction():New( oSecTran6:Cell("VALOR")    , NIL , "MAX"     , NIL     , NIL , NIL , {|| _nVlrCtr   } , .T. , .F. )
	TRFunction():New( oSecTran6:Cell("PESLIQUI") , NIL , "MAX"     , NIL     , NIL , NIL , {|| _nVlrPesLi } , .T. , .F. )
	TRFunction():New( oSecTran6:Cell("PESBRUTO") , NIL , "MAX"     , NIL     , NIL , NIL , {|| _nVlrPesBr } , .T. , .F. )
	TRFunction():New( oSecTran6:Cell("PESCARGA") , NIL , "AVERAGE" , NIL     , NIL , NIL , NIL              , .T. , .F. )
	
	//====================================================================================================	
	// Executa query para consultar Dados
	//====================================================================================================
	BEGIN REPORT QUERY oSecTran4

		BeginSql alias "QRY2"
		
			SELECT
				ZZN.ZZN_FTRANS	AS CODTRANSP,
				ZZN.ZZN_LOJAFT	AS LOJTRANSP,
				SA2.A2_NOME		AS DESCTRANSP,
				SA2.A2_CGC		AS CGCTRANSP,
				ZZN.ZZN_FATURA	AS FATURA,
				ZZN.ZZN_ITEM	AS ITEM,
				ZZN.ZZN_CTRANS	AS CONTRANS,
				ZZN.ZZN_SERCTR	AS SERCONRANS,
				ZZN.ZZN_VLRCTR	AS VALOR,
				ZZN.ZZN_CARGA	AS CARGA,
				ZZN.ZZN_OBS		AS OBS,
				F2.F2_PLIQUI	AS PESLIQUI,
				F2.F2_PBRUTO	AS PESBRUTO,
				F2.F2_DOC		AS NF,
				F2.F2_SERIE		AS SERIENF,
				DAK.DAK_PESO	AS PESCARGA,
				CC2.CC2_MUN		AS DESCMUN,
                SA2.A2_I_TPAVE  AS TIPOAVERBC,
				(	SELECT ZZO.ZZO_DESCRI
					FROM %Table:ZZO% ZZO
					WHERE	ZZO.D_E_L_E_T_ = ' '
					AND		ZZN.ZZN_MTDIVF = ZZO.ZZO_CODIGO ) DESCMOTIV,
				F2_I_FRET       AS FRETECARGA
			FROM %Table:ZZN% ZZN
			JOIN %Table:SA2% SA2 ON SA2.A2_COD     = ZZN.ZZN_FTRANS AND SA2.A2_LOJA    = ZZN_LOJAFT
			JOIN %Table:SF2% F2  ON ZZN.ZZN_FILIAL = F2.F2_FILIAL   AND ZZN.ZZN_CARGA  = F2.F2_CARGA 
			JOIN %Table:SC5% SC5 ON F2.F2_FILIAL   = SC5.C5_FILIAL  AND F2.F2_I_PEDID  = SC5.C5_NUM  
			JOIN %Table:DAK% DAK ON ZZN.ZZN_FILIAL = DAK.DAK_FILIAL AND ZZN.ZZN_CARGA  = DAK.DAK_COD
			JOIN %Table:SA1% A1  ON A1.A1_COD      = F2.F2_CLIENTE  AND A1.A1_LOJA     = F2.F2_LOJA
			JOIN %Table:CC2% CC2 ON CC2.CC2_EST    = A1.A1_EST      AND CC2.CC2_CODMUN = A1.A1_COD_MUN
			WHERE
				ZZN.D_E_L_E_T_ = ' '
			AND SA2.D_E_L_E_T_ = ' '
			AND F2.D_E_L_E_T_  = ' ' 
			AND DAK.D_E_L_E_T_ = ' ' 
			AND ZZN.ZZN_CARGA <> ' '
			AND SC5.D_E_L_E_T_ = ' '
			AND SC5.C5_I_OPER NOT IN ('50','51')
			%Exp:cFiltro%
			
			GROUP BY	ZZN.ZZN_FTRANS	, ZZN.ZZN_LOJAFT	, SA2.A2_NOME		, SA2.A2_CGC	, ZZN.ZZN_FATURA	, ZZN.ZZN_ITEM		,
						ZZN.ZZN_CTRANS	, ZZN.ZZN_SERCTR	, ZZN.ZZN_VLRCTR	, ZZN.ZZN_CARGA	, ZZN.ZZN_OBS		, F2.F2_PLIQUI		,
						F2.F2_PBRUTO	, F2.F2_DOC			, F2.F2_SERIE		, DAK.DAK_PESO	, CC2.CC2_MUN		, ZZN.ZZN_MTDIVF    ,
						F2.F2_I_FRET    , SA2.A2_I_TPAVE
			
			ORDER BY LOJTRANSP , DESCTRANSP , OBS , SERCONRANS , VALOR , SERIENF , PESCARGA
			
		EndSql
		
	END REPORT QUERY oSecTran4
	
	oSecTran5:SetParentQuery()
	oSecTran5:SetParentFilter({|cParam| QRY2->CODTRANSP + QRY2->LOJTRANSP == cParam},{|| QRY2->CODTRANSP + QRY2->LOJTRANSP })
	
	oSecTran6:SetParentQuery()
	oSecTran6:SetParentFilter({|cParam| QRY2->CARGA == cParam},{|| QRY2->CARGA })
	
	oSecTran4:Print(.T.)
	
//====================================================================================================
// Terceira ordem - Transportadora
//====================================================================================================
ElseIf nOrdem == 3

	oSecTran7:Enable()
	oSecTran8:Enable()
	
	//====================================================================================================
	// Quebras
	//====================================================================================================
	oBreak3 := TRBreak():New( oSecTran7 , oSecTran7:CELL( "TRANSPLOJA" ) , "Total Transportadora: "+ cNomeTrans , .F. )
	
	oBreak3:SetTotalText( {|| "Total Transportadora: "+ cNomeTrans } )
	
	TRFunction():New( oSecTran8:Cell("VALOR") , NIL , "SUM" , oBreak3 , NIL , NIL , NIL , .F. , .T. )
	
	//====================================================================================================	
	// Executa query para consultar Dados
	//====================================================================================================
	BEGIN REPORT QUERY oSecTran7
	
		BeginSql alias "QRY3"
		
			SELECT
				DADOS.CODTRANSP,
				DADOS.LOJTRANSP,
				DADOS.DESCTRANSP,
				DADOS.CGCTRANSP,
				DADOS.FATURA,
				DADOS.ITEM,
				DADOS.CONTRANS,
				DADOS.SERCONRANS,
				DADOS.VALOR,
				DADOS.NF,
				DADOS.SERIENF,
				DADOS.CARGA,
				DADOS.OBS,
				DADOS.DESCMOTIV,
				DADOS.DESCMUN,
				DADOS.PREV_PGTO,
				DADOS.PESLIQUI,
				DADOS.PESBRUTO,
				DADOS.PESCARGA,
				DADOS.FRETECARGA,
                DADOS.TIPOAVERBC
			FROM (	SELECT
						ZZN.ZZN_FTRANS	AS CODTRANSP,
						ZZN.ZZN_LOJAFT	AS LOJTRANSP,
						SA2.A2_NOME		AS DESCTRANSP,
						SA2.A2_CGC		AS CGCTRANSP,
						ZZN.ZZN_FATURA	AS FATURA,
						ZZN.ZZN_ITEM	AS ITEM,
						ZZN.ZZN_CTRANS	AS CONTRANS,
						ZZN.ZZN_SERCTR	AS SERCONRANS,
						ZZN.ZZN_VLRCTR	AS VALOR,
						ZZN.ZZN_NFISCA	AS NF,
						ZZN.ZZN_SERIE	AS SERIENF,
						ZZN.ZZN_CARGA	AS CARGA,
						ZZN.ZZN_OBS		AS OBS,
						NVL( ZZO.ZZO_DESCRI , ' ' ) AS DESCMOTIV,
						CC2.CC2_MUN		AS DESCMUN,
						ZZN.ZZN_PRVPAG	AS PREV_PGTO,
						F2.F2_PLIQUI	AS PESLIQUI,
						F2.F2_PBRUTO	AS PESBRUTO,
                        SA2.A2_I_TPAVE  AS TIPOAVERBC, 
						(SELECT MAX(DAK_PESO) FROM %Table:DAK% DAK WHERE DAK.D_E_L_E_T_ = ' ' AND DAK.DAK_FILIAL = F2.F2_FILIAL AND ZZN.ZZN_CARGA = DAK.DAK_COD )	AS PESCARGA,
						F2.F2_I_FRET    AS FRETECARGA
				FROM %Table:ZZN% ZZN
				JOIN %Table:SA2% SA2      ON SA2.A2_COD     = ZZN.ZZN_FTRANS AND SA2.A2_LOJA    = ZZN_LOJAFT
				JOIN %Table:SF2% F2       ON ZZN.ZZN_FILIAL = ZZN.ZZN_FILIAL AND ZZN.ZZN_NFISCA = F2.F2_DOC     AND ZZN.ZZN_SERIE = F2.F2_SERIE
				JOIN %Table:SA1% A1       ON A1.A1_COD      = F2.F2_CLIENTE  AND A1.A1_LOJA     = F2.F2_LOJA
				JOIN %Table:CC2% CC2      ON CC2.CC2_EST    = A1.A1_EST      AND CC2.CC2_CODMUN = A1.A1_COD_MUN
				LEFT JOIN %Table:ZZO% ZZO ON ZZN.ZZN_MTDIVF = ZZO.ZZO_CODIGO
				WHERE
					ZZN.D_E_L_E_T_  = ' '
				AND SA2.D_E_L_E_T_  = ' '
				AND F2.D_E_L_E_T_   = ' '
				AND A1.D_E_L_E_T_   = ' '
				AND CC2.D_E_L_E_T_  = ' '
				AND ZZN.ZZN_NFISCA <> ' '
				AND SA2.D_E_L_E_T_   = ' '
				
				%Exp:cFiltro%
							
			)DADOS
			
			ORDER BY DADOS.LOJTRANSP , DADOS.DESCTRANSP , DADOS.FATURA , DADOS.CONTRANS
			
		EndSql
		
	END REPORT QUERY oSecTran7
	
	oSecTran8:SetParentQuery()
	oSecTran8:SetParentFilter( {|cParam| QRY3->CODTRANSP + QRY3->LOJTRANSP == cParam } , {|| QRY3->CODTRANSP + QRY3->LOJTRANSP } )
	
	oSecTran7:Print(.T.)

EndIf

Return

/*
===============================================================================================================================
Programa--------: ROMS034C
Autor-----------: Fabiano Dias
Data da Criacao-: 29/09/2011
Descrição-------: Rotina que realiza a consulta e estrutura os dados para impressão do relatório
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS034C( _cCodTrans , _cLjTrans , _cCarga , _nValorCTR , _nPesCarga , _cCtr , _cSerieCtr , _cNF , _cSerieNF , _nPesLiq , _nPesBrt )

If _cQbrTrans != _cCodTrans + _cLjTrans
	
	_nVlrTrans := _nValorCTR
	_cQbrTrans := _cCodTrans + _cLjTrans
	_cCtrTrans := _cCtr + _cSerieCtr

Else
	
	If _cCtrTrans != _cCtr + _cSerieCtr
		
		_nVlrTrans += _nValorCTR
		
		_cCtrTrans := _cCtr + _cSerieCtr
		
	EndIf
	
EndIf

If _cQuebra != _cCodTrans + _cLjTrans + _cCarga
	
	aQbrNfs := {}
	
	If _cConhecim != _cCtr + _cSerieCtr
		
		_nVlrCtr   := _nValorCTR
		_cConhecim := _cCtr + _cSerieCtr
		
	EndIf
	
	If aScan( aQbrNfs , {|W| W[1] == _cNF + _cSerieNF } ) == 0
		
		_nVlrPesLi := _nPesLiq
		_nVlrPesBr := _nPesBrt
		
		aAdd( aQbrNfs , { _cNF + _cSerieNF } )
		
	EndIf
	
	_cQuebra  := _cCodTrans + _cLjTrans + _cCarga
	
Else
	
	If _cConhecim != _cCtr + _cSerieCtr
		
		_nVlrCtr   += _nValorCTR
		_cConhecim := _cCtr + _cSerieCtr
		
	EndIf
	
	If aScan( aQbrNfs , {|W| W[1] == _cNF + _cSerieNF } ) == 0
		
		_nVlrPesLi += _nPesLiq
		_nVlrPesBr += _nPesBrt
		
		aAdd( aQbrNfs , { _cNF + _cSerieNF } )
		
	EndIf
	
EndIf

Return

/*
===============================================================================================================================
Programa--------: ROMS034L
Autor-----------: Fabiano Dias
Data da Criacao-: 29/09/2011
Descrição-------: Monta Tela para consulta dos Motivos de Divergencias
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ROMS034L()

Local i := 0

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

//====================================================================================================
// Tratamento para carregar variaveis da lista de opcoes
//====================================================================================================
nTam		:= 2
nMaxSelect	:= 25
cTitulo		:= "Motivo Divergencia Frete"

ZZO->( DBSetOrder(1) )
ZZO->( DBGoTop() )
While ZZO->( !Eof() )
	
	MvParDef += AllTrim( ZZO->ZZO_CODIGO )
	
	aAdd( aCat , AllTrim( ZZO->ZZO_DESCRI ) )
	
ZZO->( DBSkip() )
EndDo

//====================================================================================================
// Trativa para no caso de alteracao do campo trazer todos os dados que já foram selecionados antes
//====================================================================================================
If Len( AllTrim( &MvRet ) ) == 0
	
	MvPar	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )
	&MvRet	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )
	
Else
	
	MvPar:= AllTrim(StrTran(&MvRet,";","/"))
	
EndIf

//====================================================================================================
// Somente altera o conteudo caso o usuario clique no botao ok
//====================================================================================================
If F_Opcoes( @MvPar , cTitulo , aCat , MvParDef , 12 , 49 , .F. , nTam , nMaxSelect ) // Executa funcao que monta tela de opcoes
	
	&MvRet := "" // Tratamento para separar retorno com barra ";"
	
	For i := 1 To Len(MvPar) Step nTam
	
		If !( SubStr( MvPar , i , 1 ) $ " |*" )
			&MvRet += SubStr( MvPar , i , nTam ) +";"
		EndIf
		
	Next i
	
	&MvRet := SubStr( &MvRet , 1 , Len( &MvRet ) - 1 ) // Trata para tirar o ultimo caracter
	
EndIf

Return(.T.)

/*
===============================================================================================================================
Programa--------: ROMS034S
Autor-----------: Fabiano Dias
Data da Criacao-: 29/09/2011
Descrição-------: Retorna o Status do CTR
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS034S( _cFilial , _cTrans , _cLoja , _cTDoc , _cTSerie )

Local _cStatus := "ABERTO" 
Local _aArea   := FWGetArea()

DBSelectArea("SF1")   
SF1->( DBSetOrder(1) )
SF1->( DBGoTop() )
If SF1->( DBSeek( _cFilial + _cTDoc + _cTSerie + _cTrans + _cLoja ) )
	
	DBSelectArea("SE2")   
	SE2->( DBSetOrder(6) )
	SE2->( DBGoTop() )
	If SE2->( DBSeek( _cFilial + _cTrans + _cLoja + _cTSerie + _cTDoc ) )
	    
	    Do Case
	    	Case SE2->E2_SALDO == SE2->E2_VALOR							; _cStatus := "FISCAL"
			Case SE2->E2_SALDO == 0										; _cStatus := "PAGO TOTAL"
			Case SE2->E2_SALDO > 0 .And. SE2->E2_SALDO <> SE2->E2_VALOR ; _cStatus := "PAGO PARCIAL"
		EndCase
		
	EndIf
	
EndIf

FWRestArea(_aArea)

Return( _cStatus )
