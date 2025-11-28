/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |27/08/2019| Chamado 28346. Revisão do fonte.
Lucas Borges  |16/08/2022| Chamado 41037. Corrigida query para não considerar pre-notas.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "REPORT.CH"

/*
===============================================================================================================================
Programa----------: RGLT054
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 12/03/2012
Descrição---------: Relatório das notas fiscais de produtores (NFP) lançadas no Documento de Entrada. Essas notas são necessárias
					para o fechamento das filiais situadas no RS, onde é validado na transmissão do XML da NF-e, se existe uma
					nota de produtor associada à nota que está sendo emitida.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT054()

Private cPerg := "RGLT054"
Private QRY1
Private oReport
Private oSecCabec,oSecDetalh
Private cDadoNFP:= ""
Private oTitulo := ""

Pergunte(cPerg,.F.)

DEFINE REPORT oReport NAME cPerg TITLE "Relação de Notas Fiscais de Produtor - NFPs" PARAMETER cPerg ACTION {|oReport| PrintReport(oReport)} Description "Este relatório ir?emitir uma relacao Notas Fiscais de Produtor conforme parâmetros."

//Seta Padrao de impressao como Paisagem
oReport:SetLandscape()
oReport:SetTotalInLine(.F.)

oReport:nFontBody	:= 10
oReport:cFontBody	:= "Courier New"
oReport:nLineHeight	:= 50 // Define a altura da linha.

oReport:DisableOrientation()//Desabilita a escolha do tipo de orientacao da pagina retrato ou paisagem

//===========================================
//Seção cabecalho - Linha
//===========================================

//Seção dados da Linha
DEFINE Section oSecCabec OF oReport TITLE "Linha/Rota" TABLES "ZL3"

DEFINE CELL NAME "ZL3_COD"  	OF oSecCabec ALIAS "ZL3" TITLE "Linha\Rota"
DEFINE CELL NAME "ZL3_DESCRI" OF oSecCabec ALIAS "ZL3" TITLE "Descirção"

oSecCabec:SetTotalInLine(.F.)

oSecCabec:SetLineStyle(.T.)
oSecCabec:SetLinesBefore(2)
oSecCabec:Disable()

//===========================================
//Seção detalhes - Dados da NFP
//===========================================

DEFINE Section oSecDetalh OF oSecCabec TITLE oTitulo TABLES "SF1","SA2"

DEFINE CELL NAME "A2_COD" OF oSecDetalh ALIAS "SA2" TITLE "Código"
DEFINE CELL NAME "A2_LOJA"  OF oSecDetalh ALIAS "SA2" TITLE "Loja"
DEFINE CELL NAME "A2_NOME" OF oSecDetalh ALIAS "SA2" TITLE "Nome do Produtor"
DEFINE CELL NAME "F1_DOC"   OF oSecDetalh ALIAS "SF1" TITLE "Nro. Documento"
DEFINE CELL NAME "F1_SERIE"    OF oSecDetalh ALIAS "SF1" TITLE "Série"
DEFINE CELL NAME "F1_EMISSAO"  OF oSecDetalh ALIAS "SF1" TITLE "Emissão"
DEFINE CELL NAME "F1_DTDIGIT" OF oSecDetalh ALIAS "SF1" TITLE "Digitação"

oSecDetalh:OnPrintLine({|| cDadoNFP := 'Linha\Rota: ' + AllTrim(QRY1->ZL3_COD) + ' Descrição: ' +  AllTrim(QRY1->ZL3_DESCRI)})

oSecDetalh:SetTotalInLine(.F.)
oSecDetalh:Disable()

oSecDetalh:SetAutoSize(.T.)
oSecDetalh:SetLinesBefore(2)
oSecDetalh:SetHeaderPage(.T.)

oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: PrintReport
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 21/03/2012
Descrição---------: Função estática que faz os filtros do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function PrintReport(oReport)

oSecCabec:Enable()
oSecDetalh:Enable()

If MV_PAR05 == 1 //NFPs Lançadas

	oReport:SetTitle("Relação de NFPs Lançadas - Digitação de " + DToC(MV_PAR03) + " até"  + DToC(MV_PAR04))
	oTitutlo:= "NFPs Lançadas"

	//Quebra por Linha
	oBreak1:= TRBreak():New(oSecDetalh,oSecCabec:CELL("ZL3_COD"),"Total NFPs: " + cDadoNFP,.F.)
	oBreak1:SetTotalText({|| "Total NFPs: " })
	TRFunction():New(oSecDetalh:Cell("A2_COD")  ,NIL,"COUNT",oBreak1,NIL,NIL,NIL,.F.,.T.)

	//==========================================================================
	// Query do relatório da secao 1
	//==========================================================================
	BEGIN REPORT QUERY oSecCabec
		BeginSql alias "QRY1"   	   	
			SELECT ZL3.ZL3_COD, ZL3.ZL3_DESCRI, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, SF1.F1_DOC, SF1.F1_SERIE, SF1.F1_EMISSAO, SF1.F1_DTDIGIT
			  FROM %Table:ZLF% ZLF, %Table:SA2% SA2, %Table:ZL3% ZL3, %Table:SF1% SF1
			 WHERE ZLF.D_E_L_E_T_ = ' '
			   AND SA2.D_E_L_E_T_ = ' '
			   AND ZL3.D_E_L_E_T_ = ' '
			   AND SF1.D_E_L_E_T_ = ' '
			   AND ZLF.ZLF_RETIRO = SA2.A2_COD
			   AND ZLF.ZLF_RETILJ = SA2.A2_LOJA
			   AND SA2.A2_L_LI_RO = ZL3.ZL3_COD
			   AND SF1.F1_FORNECE = SA2.A2_COD
			   AND SF1.F1_LOJA = SA2.A2_LOJA
			   AND SF1.F1_FILIAL = %xFilial:SF1%
			   AND SA2.A2_FILIAL = %xFilial:SA2%
			   AND ZL3.ZL3_FILIAL = %xFilial:ZL3%
			   AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
			   AND ZLF.ZLF_CODZLE = %exp:MV_PAR06%
			   AND ZLF.ZLF_LINROT BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
			   AND SF1.F1_ESPECIE = 'NFP'
			   AND SF1.F1_STATUS = 'A'
			   AND SF1.F1_DTDIGIT BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
			   AND SA2.A2_COD BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR09%
			   AND SA2.A2_LOJA BETWEEN %exp:MV_PAR08% AND %exp:MV_PAR10%
			 GROUP BY ZL3.ZL3_COD, ZL3.ZL3_DESCRI, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, SF1.F1_DOC, SF1.F1_SERIE, SF1.F1_EMISSAO, SF1.F1_DTDIGIT
			 ORDER BY ZL3.ZL3_COD, SA2.A2_COD, SA2.A2_LOJA
		EndSql

	END REPORT QUERY oSecCabec

//Dados do segundo relatorio
ElseIf MV_PAR05 == 2 //NFPs Pendentes

	oReport:SetTitle("Relação de NFPs Pendentes - Digitação de " + DToC(MV_PAR03) + " até"  + DToC(MV_PAR04))
	oTitutlo:= "NFPs Pendentes"

	//Desabilita Céludas que não são usadas
	oSecDetalh:Cell("F1_DOC"):Disable()
	oSecDetalh:Cell("F1_SERIE"):Disable()
	oSecDetalh:Cell("F1_EMISSAO"):Disable()
	oSecDetalh:Cell("F1_DTDIGIT"):Disable()

	//Quebra por Linha
	oBreak1:= TRBreak():New(oSecDetalh,oSecCabec:CELL("ZL3_COD"),"Total NFPs: " + cDadoNFP,.F.)
	oBreak1:SetTotalText({|| "Total NFPs: " + cDadoNFP })
	TRFunction():New(oSecDetalh:Cell("A2_COD")  ,NIL,"COUNT",oBreak1,NIL,NIL,NIL,.F.,.T.)

	//Executa query para consultar Dados
	BEGIN REPORT QUERY oSecCabec
		BeginSql alias "QRY1"   	   	
			SELECT ZL3.ZL3_COD, ZL3.ZL3_DESCRI, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME
			  FROM %Table:ZLF% ZLF, %Table:SA2% SA2, %Table:ZL3% ZL3
			 WHERE ZLF.D_E_L_E_T_ = ' '
			   AND SA2.D_E_L_E_T_ = ' '
			   AND ZL3.D_E_L_E_T_ = ' '
			   AND ZLF.ZLF_RETIRO = SA2.A2_COD
			   AND ZLF.ZLF_RETILJ = SA2.A2_LOJA
			   AND SA2.A2_L_LI_RO = ZL3.ZL3_COD
			   AND ZL3.ZL3_FILIAL = %xFilial:ZL3%
			   AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
			   AND SA2.A2_FILIAL = %xFilial:SA2%
			   AND ZLF.ZLF_CODZLE = %exp:MV_PAR06%
			   AND ZLF.ZLF_LINROT BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
			   AND SA2.A2_COD BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR09%
			   AND SA2.A2_LOJA BETWEEN %exp:MV_PAR08% AND %exp:MV_PAR10%
			   AND NOT EXISTS
			        (SELECT 1
			          FROM %Table:SF1% SF1
			         WHERE SF1.D_E_L_E_T_ = ' '
			           AND SF1.F1_FORNECE = SA2.A2_COD
			           AND SF1.F1_LOJA = SA2.A2_LOJA
			           AND SF1.F1_FILIAL = ZLF.ZLF_FILIAL
			           AND SF1.F1_ESPECIE = 'NFP'
			           AND SF1.F1_DTDIGIT BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%)
			 GROUP BY ZL3.ZL3_COD, ZL3.ZL3_DESCRI, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME
			 ORDER BY ZL3.ZL3_COD, SA2.A2_COD, SA2.A2_LOJA
		EndSql
	
		END REPORT QUERY oSecCabec               

ElseIf MV_PAR05 == 3 //NFPs Divergentes

	oReport:SetTitle("Relação de NFPs Divergêntes - Digitação de " + DToC(MV_PAR03) + " atè"  + DToC(MV_PAR04))
	oTitutlo:= "NFPs Divergentes"

	//Quebra por Linha
	oBreak1:= TRBreak():New(oSecDetalh,oSecCabec:CELL("ZL3_COD"),"Total NFPs: " + cDadoNFP,.F.)
	oBreak1:SetTotalText({|| "Total NFPs: " + cDadoNFP })
	TRFunction():New(oSecDetalh:Cell("A2_COD")  ,NIL,"COUNT",oBreak1,NIL,NIL,NIL,.F.,.T.)

	//Executa query para consultar Dados
	BEGIN REPORT QUERY oSecCabec
		BeginSql alias "QRY1"
			SELECT ZL3.ZL3_COD, ZL3.ZL3_DESCRI, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, SF1.F1_DOC, SF1.F1_SERIE, SF1.F1_EMISSAO, SF1.F1_DTDIGIT
			  FROM %Table:SF1% SF1, %Table:SA2% SA2, %Table:ZL3% ZL3
			 WHERE SF1.D_E_L_E_T_ = ' '
			   AND SA2.D_E_L_E_T_ = ' '
			   AND ZL3.D_E_L_E_T_ = ' '
			   AND SA2.A2_L_LI_RO = ZL3.ZL3_COD
			   AND SF1.F1_FORNECE = SA2.A2_COD
			   AND SF1.F1_LOJA = SA2.A2_LOJA
			   AND SF1.F1_ESPECIE = 'NFP'
			   AND SF1.F1_STATUS = 'A'
			   AND ZL3.ZL3_FILIAL = %xFilial:ZL3%
			   AND SF1.F1_FILIAL = %xFilial:SF1%
			   AND SA2.A2_FILIAL = %xFilial:SA2%
			   AND SF1.F1_DTDIGIT BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
			   AND SA2.A2_COD BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR09%
			   AND SA2.A2_LOJA BETWEEN %exp:MV_PAR08% AND %exp:MV_PAR10%
			   AND NOT EXISTS
			        (SELECT 1
			          FROM %Table:ZLF% ZLF
			         WHERE ZLF.D_E_L_E_T_ = ' '
			           AND ZLF.ZLF_RETIRO = SA2.A2_COD
			           AND ZLF.ZLF_RETILJ = SA2.A2_LOJA
			           AND SF1.F1_FILIAL = ZLF.ZLF_FILIAL
			           AND ZLF.ZLF_LINROT BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
			           AND ZLF.ZLF_CODZLE = %exp:MV_PAR06%)
			 GROUP BY ZL3.ZL3_COD, ZL3.ZL3_DESCRI, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, SF1.F1_DOC, SF1.F1_SERIE, SF1.F1_EMISSAO, SF1.F1_DTDIGIT
			 ORDER BY ZL3.ZL3_COD, SA2.A2_COD, SA2.A2_LOJA
		EndSql

	END REPORT QUERY oSecCabec

EndIf

oSecDetalh:SetParentQuery()
oSecDetalh:SetParentFilter({|cParam| QRY1->ZL3_COD == cParam },{|| QRY1->ZL3_COD })

oSecCabec:Print(.T.)

Return
