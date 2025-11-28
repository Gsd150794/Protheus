/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |27/09/2019| Chamado 28346. Revisão de fontes.
Lucas Borges  |29/03/2021| Chamado 36072. Corrigido error.log.
Lucas Borges  |21/07/2021| Chamado 37147. Tratamento para produtores familiares (A2_L_CLASS=L).
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "REPORT.CH"

/*
===============================================================================================================================
Programa----------: RGLT053
Autor-------------: Heder Jose
Data da Criacao---: 22/02/12
Descrição---------: Relatorio desenvolvido para realizar a impressao da relação de produtores por tanque
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT053()

Local oReport

Private cPerg      := "RGLT053"
Private oOrd1_A, oOrd1_B, oBrk1A          //Ordem Produtor
Private oOrd2_A, oOrd2_B, oOrd2_C, oBrk2A, oBrk2B  //Ordem Municipio
Private oOrd3_A, oOrd3_B, oOrd3_C, oBrk3A  //Ordem Resp. Tanque

Private QRY1,QRY2,QRY3
Private aOrd       := {"Produtor","Município","Responsável Tanque" } 
Private cTitulo    := "Relação de Produtor por Classificação de Tanque "
Private nVol:= 0
Private cNRota1A, cNRota2A, cNRota3A  := ""
Private cNomeMun, cRespTq   := ""

Pergunte(cPerg,.F.)

oReport := TReport():New(cPerg,cTitulo,cPerg,{|oReport| PrintReport(oReport)},"Este relatório ira imprimir a relação de produtores por classificação de tanque.") 

//Seta Padrao de impressao como Paisagem
oReport:SetLandscape()

//Desabilita a escolha do tipo de orientacao da pagina retrato ou paisagem
oReport:DisableOrientation()

//Define que será impresso o rodapé do relatório.
oReport:ShowFooter(.T.)

//Define que será impresso o cabeçalho do relatório.
oReport:ShowHeader(.T.)

//Configuracao da fonte
oReport:nFontBody	:= 07
oReport:cFontBody	:= "Courier New"
oReport:nLineHeight	:= 45 // Define a altura da linha.

//Msg para aguardar impressao
oReport:SetMsgPrint('Aguarde os Dados do Relatório estão sendo Processados!')

oReport:SetTotalInLine(.F.)		

oReport:SetTotalText({|| "Total Geral: "})

oReport:Disable()

//===========================
//Primeira Ordem - PRODUTOR
//===========================
DEFINE Section oOrd1_A OF oReport TITLE "Rota" TABLES "ZL3" ORDERS aOrd
DEFINE CELL NAME "ROTA" 	  OF oOrd1_A ALIAS "ZL3" SIZE 80 TITLE "Rota" BLOCK{|| QRY1->ZL3_COD + " - " + AllTrim(QRY1->ZL3_DESCRI) }	
				
//Passa fonte para negrito
oOrd1_A:Cell("ROTA"):lBold:= .T.
		
//Linhas a considerar da quebra de uma transportadora para outra
oOrd1_A:SetLinesBefore(3)
		
//Define que imprime cabeçalho das células no topo da página.
oOrd1_A:SetHeaderPage(.F.)
		
oOrd1_A:OnPrintLine({|| cNRota1A := QRY1->ZL3_COD + " - " + AllTrim(QRY1->ZL3_DESCRI)  })				
		
//Desabilita a impressão da secao
oOrd1_A:Disable()

DEFINE Section oOrd1_B OF oOrd1_A TITLE "Produtor" TABLE "SA2","CC2"
DEFINE CELL NAME "A2_COD"     OF oOrd1_B ALIAS "SA2" TITLE "Código"          ALIGN LEFT   SIZE 08
DEFINE CELL NAME "A2_LOJA"    OF oOrd1_B ALIAS "SA2" TITLE "Loja"            ALIGN LEFT   SIZE 06
DEFINE CELL NAME "A2_NOME"    OF oOrd1_B ALIAS "SA2" TITLE "Nome Produtor"   ALIGN LEFT   SIZE 30
DEFINE CELL NAME "A2_END"     OF oOrd1_B ALIAS "SA2" TITLE "Logradouro"      ALIGN LEFT   SIZE 20
DEFINE CELL NAME "CC2_MUN"    OF oOrd1_B ALIAS "CC2" TITLE "Município"		 ALIGN LEFT   SIZE 20
DEFINE CELL NAME "A2_CGC"     OF oOrd1_B ALIAS "SA2" TITLE "CPF"             ALIGN LEFT   SIZE 18 PICTURE "@R 999.999.999-99"
DEFINE CELL NAME "A2_INSCR"   OF oOrd1_B ALIAS "SA2" TITLE "Inscrição"		 ALIGN LEFT   SIZE 13
DEFINE CELL NAME "A2_L_SIGSI" OF oOrd1_B ALIAS "SA2" TITLE "NRP-SIGSIF"      ALIGN LEFT   SIZE 13
DEFINE CELL NAME "Vol.Mensal" OF oOrd1_B ALIAS "SA2" TITLE "Vol.Mensal"      ALIGN RIGHT  SIZE 15 BLOCK{|| IIf(MV_PAR11==1,nVol,nVol:=0) }	 PICTURE "@E 999,999"
DEFINE CELL NAME "Vol.Dia"    OF oOrd1_B ALIAS "SA2" TITLE "Vol.Dia"         ALIGN RIGHT  SIZE 10 BLOCK{|| nVol/Val(SubStr(DToS(LastDay(MV_PAR06)),7,2)) } PICTURE "@E 999,999"
DEFINE CELL NAME "A2_L_MARTQ" OF oOrd1_B ALIAS "SA2" TITLE "Marca"           ALIGN LEFT   SIZE 15
DEFINE CELL NAME "A2_L_CAPTQ" OF oOrd1_B ALIAS "SA2" TITLE "Cap.Tq"          ALIGN RIGHT  SIZE 08 PICTURE PesqPict("SA2","A2_L_CAPTQ")
DEFINE CELL NAME "A2_L_FREQU" OF oOrd1_B ALIAS "SA2" TITLE "Col.24/48"       ALIGN CENTER SIZE 11
				
//Define que imprime cabeçalho das células no topo da página.
oOrd1_B:SetHeaderPage(.F.)		
	
//Apresenta totais em linha
oOrd1_B:SetTotalInLine(.F.)
		
//Desabilita a impressão da secao
oOrd1_B:Disable()

//===========================
//Segunda Ordem - MUNICIPIO
//===========================
DEFINE Section oOrd2_A OF oReport TITLE "Rota" TABLES "ZL3" ORDERS aOrd
DEFINE CELL NAME "ROTA" 	  OF oOrd2_A ALIAS "ZL3" SIZE 80 TITLE "Rota" BLOCK{|| QRY2->ZL3_COD + " - " + AllTrim(QRY2->ZL3_DESCRI) }

//Passa fonte para negrito
oOrd2_A:Cell("ROTA"):lBold := .T.
		
//Linhas a considerar da quebra de uma ROTA para outra
oOrd2_A:SetLinesBefore(2)
		
//Define que imprime cabeçalho das células no topo da página.
oOrd2_A:SetHeaderPage(.F.)		
		
//Desabilita a impressão da secao
oOrd2_A:Disable()
				
DEFINE Section oOrd2_B OF oOrd2_A TITLE "Municipio" TABLES "CC2"
DEFINE CELL NAME "MUNICIPIO" 	  OF oOrd2_B ALIAS "CC2" SIZE 80 TITLE "Município" BLOCK{|| cNomeMun := QRY2->A2_COD_MUN + " - " + AllTrim(QRY2->CC2_MUN) }
		
//Passa fonte para negrito
oOrd2_B:Cell("MUNICIPIO"):lBold := .T.
		
//Define que imprime cabeçalho das células no topo da página.
oOrd2_B:SetHeaderPage(.F.)
	
//Linhas a considerar da quebra de uma transportadora para outra
oOrd2_B:OnPrintLine({|| cNRota2A := QRY2->ZL3_COD + " - " + AllTrim(QRY2->ZL3_DESCRI)  })		
		
//Desabilita a impressão da secao
oOrd2_B:Disable()				
		
DEFINE Section oOrd2_C OF oOrd2_B TITLE "Produtor" TABLE "SA2","CC2"
DEFINE CELL NAME "A2_COD"     OF oOrd2_C ALIAS "SA2" TITLE "Código"          ALIGN LEFT   SIZE 08
DEFINE CELL NAME "A2_LOJA"    OF oOrd2_C ALIAS "SA2" TITLE "Loja"            ALIGN LEFT   SIZE 06
DEFINE CELL NAME "A2_NOME"    OF oOrd2_C ALIAS "SA2" TITLE "Nome Produtor"   ALIGN LEFT   SIZE 30
DEFINE CELL NAME "A2_END"     OF oOrd2_C ALIAS "SA2" TITLE "Logradouro"      ALIGN LEFT   SIZE 20
DEFINE CELL NAME "A2_CGC"     OF oOrd2_C ALIAS "SA2" TITLE "CPF"             ALIGN LEFT   SIZE 18 PICTURE "@R 999.999.999-99"
DEFINE CELL NAME "A2_INSCR"   OF oOrd2_C ALIAS "SA2" TITLE "Inscrição"		 ALIGN LEFT   SIZE 13
DEFINE CELL NAME "A2_L_SIGSI" OF oOrd2_C ALIAS "SA2" TITLE "NRP-SIGSIF"      ALIGN LEFT   SIZE 13
DEFINE CELL NAME "Vol.Mensal" OF oOrd2_C ALIAS "SA2" TITLE "Vol.Mensal"      ALIGN RIGHT  SIZE 15 BLOCK{|| IIf(MV_PAR11==1,nVol,nVol:=0) }	 PICTURE "@E 999,999"
DEFINE CELL NAME "Vol.Dia"    OF oOrd2_C ALIAS "SA2" TITLE "Vol.Dia"         ALIGN RIGHT  SIZE 10 BLOCK{|| nVol/Val(SubStr(DToS(LastDay(MV_PAR06)),7,2)) } PICTURE "@E 999,999"
DEFINE CELL NAME "A2_L_MARTQ" OF oOrd2_C ALIAS "SA2" TITLE "Marca"           ALIGN LEFT   SIZE 15
DEFINE CELL NAME "A2_L_CAPTQ" OF oOrd2_C ALIAS "SA2" TITLE "Cap.Tq"          ALIGN RIGHT  SIZE 08 PICTURE PesqPict("SA2","A2_L_CAPTQ")
DEFINE CELL NAME "A2_L_FREQU" OF oOrd2_C ALIAS "SA2" TITLE "Col.24/48"       ALIGN CENTER SIZE 11
		
oOrd2_C:OnPrintLine({|| QRY2->A2_COD_MUN + " - " + AllTrim(QRY2->CC2_MUN) })
		
//Define que imprime cabeçalho das células no topo da página.
oOrd2_C:SetHeaderPage(.F.)		
		
//Apresenta totais em linha
oOrd2_C:SetTotalInLine(.F.)
		
//Desabilita a impressão da secao
oOrd2_C:Disable()

//=============================
//Terceira Ordem - RESP.TANQUE
//=============================
DEFINE Section oOrd3_A OF oReport TITLE "Rota" TABLES "ZL3" ORDERS aOrd
DEFINE CELL NAME "ROTA" 	  OF oOrd3_A ALIAS "ZL3" SIZE 80 TITLE "Rota" BLOCK{|| QRY3->ZL3_COD + " - " + AllTrim(QRY3->ZL3_DESCRI) }	
				
//Passa fonte para negrito
oOrd3_A:Cell("ROTA"):lBold := .T.
		
//Linhas a considerar da quebra de uma transportadora para outra
oOrd3_A:SetLinesBefore(3)
		
//Define que imprime cabeçalho das células no topo da página.
oOrd3_A:SetHeaderPage(.T.)
		
//Desabilita a impressão da secao
oOrd3_A:Disable()
		
    
DEFINE Section oOrd3_B OF oOrd3_A TITLE "Resp. Tanque" TABLES "ZL3"
DEFINE CELL NAME "RESP. TANQUE" OF oOrd3_B ALIAS "ZL3" SIZE 80 TITLE "Resp. Tanque" BLOCK{|| cRespTq := QRY3->RESP_TQ +" - "+QRY3->A2_NOME }
		
//Passa fonte para negrito
oOrd3_B:Cell("RESP. TANQUE"):lBold := .T.
	
//Define que imprime cabeçalho das células no topo da página.
oOrd3_B:SetHeaderPage(.F.)
	
//Linhas a considerar da quebra de uma transportadora para outra
oOrd3_B:OnPrintLine({|| cNRota3A := QRY3->ZL3_COD + " - " + AllTrim(QRY3->ZL3_DESCRI)  })		
		
//Desabilita a impressão da secao
oOrd3_B:Disable()
		
DEFINE Section oOrd3_C OF oOrd3_B TITLE "Produtor" TABLE "SA2","CC2"
DEFINE CELL NAME "A2_COD"     OF oOrd3_C ALIAS "SA2" TITLE "Código"          ALIGN LEFT   SIZE 08
DEFINE CELL NAME "A2_LOJA"    OF oOrd3_C ALIAS "SA2" TITLE "Loja"            ALIGN LEFT   SIZE 06
DEFINE CELL NAME "A2_NOME"    OF oOrd3_C ALIAS "SA2" TITLE "Nome Produtor"   ALIGN LEFT   SIZE 30
DEFINE CELL NAME "A2_END"     OF oOrd3_C ALIAS "SA2" TITLE "Logradouro"      ALIGN LEFT   SIZE 20
DEFINE CELL NAME "CC2_MUN"    OF oOrd3_C ALIAS "CC2" TITLE "Município"		 ALIGN LEFT   SIZE 20
DEFINE CELL NAME "A2_CGC"     OF oOrd3_C ALIAS "SA2" TITLE "CPF"             ALIGN LEFT   SIZE 18 PICTURE "@R 999.999.999-99"
DEFINE CELL NAME "A2_INSCR"   OF oOrd3_C ALIAS "SA2" TITLE "Inscrição"		 ALIGN LEFT   SIZE 13
DEFINE CELL NAME "A2_L_SIGSI" OF oOrd3_C ALIAS "SA2" TITLE "NRP-SIGSIF"      ALIGN LEFT   SIZE 13
DEFINE CELL NAME "Vol.Mensal" OF oOrd3_C ALIAS "SA2" TITLE "Vol.Mensal"      ALIGN RIGHT  SIZE 15 BLOCK{|| IIf(MV_PAR11==1,nVol,nVol:=0) }	 PICTURE "@E 9999,999"
DEFINE CELL NAME "Vol.Dia"    OF oOrd3_C ALIAS "SA2" TITLE "Vol.Dia"         ALIGN RIGHT  SIZE 10 BLOCK{|| nVol/Val(SubStr(DToS(LastDay(MV_PAR06)),7,2)) } PICTURE "@E 9999,999"
DEFINE CELL NAME "A2_L_MARTQ" OF oOrd3_C ALIAS "SA2" TITLE "Marca"           ALIGN LEFT   SIZE 15
DEFINE CELL NAME "A2_L_CAPTQ" OF oOrd3_C ALIAS "SA2" TITLE "Cap.Tq"          ALIGN RIGHT  SIZE 08 PICTURE PesqPict("SA2","A2_L_CAPTQ")
DEFINE CELL NAME "A2_L_FREQU" OF oOrd3_C ALIAS "SA2" TITLE "Col.24/48"       ALIGN CENTER SIZE 11
DEFINE CELL NAME "TXRES"      OF oOrd3_C ALIAS "SA2" TITLE "Tx.Resfriamento" ALIGN RIGHT  SIZE 14 PICTURE "@!"
				
//Define que imprime cabeçalho das células no topo da página.
oOrd3_C:SetHeaderPage(.T.)
		
//Apresenta totais em linha
oOrd3_C:SetTotalInLine(.F.)
		
oOrd3_C:OnPrintLine({|| QRY3->RESP_TQ + " - " + QRY3->A2_NOME  })				
		
//Desabilita a impressão da secao
oOrd3_C:Disable()

oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: PrintReport
Autor-------------: Heder Jose
Data da Criacao---: 22/02/12
Descrição---------: Processa relatório
Parametros--------: oReport
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function PrintReport(oReport)

Private cFiltro    := "%"
Private cFiltro3   := "%"
Private nOrdem     := oReport:Section(1):GetOrder()

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
If !Empty(AllTrim(MV_PAR01))
	cFiltro += " AND ZL2.ZL2_COD = '"    + AllTrim(MV_PAR01) + "' "
	cFiltro3 += " AND ZL2.ZL2_COD = '"    + AllTrim(MV_PAR01) + "' "
EndIf

cFiltro += " AND ZL3.ZL3_COD BETWEEN '" + MV_PAR02 + "' AND '" + AllTrim(MV_PAR03) + "' "
cFiltro3 += " AND ZL3.ZL3_COD BETWEEN '" + MV_PAR02 + "' AND '" + AllTrim(MV_PAR03) + "' "
cFiltro += " AND SA2.A2_L_CLASS = '" + Upper(AllTrim(MV_PAR04)) + "' "

If Upper(AllTrim(MV_PAR04)) $ "C/F"
	cFiltro += " AND A2_L_TANQ || A2_L_TANLJ = A2_COD || A2_LOJA "
ElseIf Upper(AllTrim(MV_PAR04)) == "U"
	cFiltro += " AND A2_L_TANQ || A2_L_TANLJ != A2_COD || A2_LOJA "
EndIf

If !Empty(AllTrim(MV_PAR05))
	cFiltro += " AND A2_COD_MUN = '" + AllTrim(MV_PAR05) + "' "
	cFiltro3 += " AND Q2.A2_COD_MUN = '" + AllTrim(MV_PAR05) + "' "
EndIf

cFiltro += " AND SA2.A2_COD BETWEEN '"  + MV_PAR07 + "' AND '" + AllTrim(MV_PAR09) + "'"
cFiltro3 += " AND Q2.A2_COD BETWEEN '"  + MV_PAR07 + "' AND '" + AllTrim(MV_PAR09) + "'"

cFiltro += " AND SA2.A2_LOJA BETWEEN '" + MV_PAR08 + "' AND '" + AllTrim(MV_PAR10) + "'"
cFiltro3 += " AND Q2.A2_LOJA BETWEEN '" + MV_PAR08 + "' AND '" + AllTrim(MV_PAR10) + "'"

cFiltro+="%"
cFiltro3+="%"


//================================================================================
//| Configuração das quebras do relatório                                        |
//================================================================================
If nOrdem==1 // Produtor
	//Efetua quebra por cada modificacao no codigo da ROTA
	DEFINE BREAK oBrk1A OF oOrd1_A WHEN oOrd1_A:Cell("ROTA") TITLE {|| "Total Rota: " + cNRota1A } PAGE BREAK
	oOrd1_B:SetTotalText({|| "Total Rota: " + cNRota1A })	
	
	DEFINE FUNCTION FROM oOrd1_B:Cell("A2_COD")     FUNCTION COUNT BREAK oBrk1A NO END Section                      //NO END REPORT
	DEFINE FUNCTION FROM oOrd1_B:Cell("Vol.Mensal") FUNCTION SUM   BREAK oBrk1A NO END Section PICTURE "@E 999,999,999" //NO END REPORT
	DEFINE FUNCTION FROM oOrd1_B:Cell("Vol.Dia")    FUNCTION SUM   BREAK oBrk1A NO END Section PICTURE "@E 999,999,999" //NO END REPORT
	
	oReport:Enable()
	oOrd1_A:Enable()
	oOrd1_B:Enable()
	BEGIN REPORT QUERY oOrd1_A

		BeginSql alias "QRY1"
			SELECT A2_COD, A2_LOJA, A2_NOME, A2_L_LI_RO, A2_COD_MUN, A2_END, A2_CGC, A2_INSCR, A2_L_SIGSI, A2_L_MARTQ, A2_L_CAPTQ, A2_L_FREQU, A2_L_TXRES,
				CC2_CODMUN, CC2_EST, CC2_MUN, ZL3_COD, ZL3_DESCRI
			FROM %Table:SA2% SA2, %Table:CC2% CC2, %Table:ZL3% ZL3, %Table:ZL2% ZL2
			WHERE SA2.D_E_L_E_T_ = ' '
				AND ZL2.D_E_L_E_T_ = ' '
				AND ZL3.D_E_L_E_T_ = ' '
				AND CC2.D_E_L_E_T_ = ' '
				AND A2_COD LIKE 'P%'
				AND CC2_EST = A2_EST 
				AND CC2_CODMUN = A2_COD_MUN
				%exp:cFiltro%
				AND ZL3_FILIAL = %xFilial:ZL3%
				AND ZL2_FILIAL = %xFilial:ZL2%
				AND ZL3_COD = A2_L_LI_RO
				AND ZL2_COD = ZL3_SETOR
			ORDER BY ZL3_COD, A2_NOME, A2_COD, A2_LOJA
		EndSql

	END REPORT QUERY oOrd1_A
	
	oOrd1_B:SetParentQuery()
	oOrd1_B:SetParentFilter({|cParam| QRY1->ZL3_COD == cParam },{|| QRY1->ZL3_COD  } ) 
	
	If MV_PAR11 == 1
		oOrd1_B:SetLineCondition({|| (nVol:= u_VolLeite(xFilial("ZLD"),FirstDay(MV_PAR06),LastDay(MV_PAR06),MV_PAR01,,QRY1->A2_COD,QRY1->A2_LOJA,)) > 0  } )
	Else
		oOrd1_B:Cell("Vol.Mensal"):Disable()
 		oOrd1_B:Cell("Vol.Dia"):Disable()
 	EndIf
	
	oOrd1_A:Print()	

ElseIf nOrdem==2 // Município   

	//Efetua quebra por cada modificacao no codigo da ROTA
	DEFINE BREAK oBrk2A OF oReport WHEN oOrd2_A:Cell("ROTA") TITLE {|| "Total Rota: " + cNRota2A } PAGE BREAK	
	oBrk2A:SetTotalText({|| "Total Rota: " + cNRota2A })		
	
	//Efetua quebra por cada modificacao no codigo do municipio
	DEFINE BREAK oBrk2B OF oOrd2_B WHEN oOrd2_B:Cell("MUNICIPIO") TITLE {|| "Total Municipio: " + cNomeMun }
	oBrk2B:SetTotalText({|| "Total Municipio: " + cNomeMun })				
	
	// Acrescentado NO END Section para que não subtotalize a cada quebra de municipio
	DEFINE FUNCTION FROM oOrd2_C:Cell("A2_COD")     FUNCTION COUNT BREAK oBrk2A NO END Section NO END REPORT
	DEFINE FUNCTION FROM oOrd2_C:Cell("Vol.Mensal") FUNCTION SUM   BREAK oBrk2A NO END Section NO END REPORT PICTURE "@E 999,999,999"
	DEFINE FUNCTION FROM oOrd2_C:Cell("Vol.Dia")    FUNCTION SUM   BREAK oBrk2A NO END Section NO END REPORT PICTURE "@E 999,999,999"
	DEFINE FUNCTION FROM oOrd2_C:Cell("A2_COD")     FUNCTION COUNT BREAK oBrk2B NO END Section                      //NO END REPORT
	DEFINE FUNCTION FROM oOrd2_C:Cell("Vol.Mensal") FUNCTION SUM   BREAK oBrk2B NO END Section PICTURE "@E 999,999,999" //NO END REPORT
	DEFINE FUNCTION FROM oOrd2_C:Cell("Vol.Dia")    FUNCTION SUM   BREAK oBrk2B NO END Section PICTURE "@E 999,999,999" //NO END REPORT
	
	oReport:Enable()
	oOrd2_A:Enable()
	oOrd2_B:Enable()	
	oOrd2_C:Enable()
	BEGIN REPORT QUERY oOrd2_A	

		BeginSql alias "QRY2"
			SELECT  A2_COD, A2_LOJA, A2_NOME, A2_L_LI_RO, A2_COD_MUN, A2_END, A2_CGC, A2_INSCR, A2_L_SIGSI, A2_L_MARTQ, A2_L_CAPTQ, A2_L_FREQU, A2_L_TXRES,
				CC2_CODMUN, CC2_EST, CC2_MUN, ZL3_COD, ZL3_DESCRI
			FROM %Table:SA2% SA2, %Table:CC2% CC2, %Table:ZL3% ZL3, %Table:ZL2% ZL2
			WHERE SA2.D_E_L_E_T_ = ' '
				AND ZL2.D_E_L_E_T_ = ' '
				AND ZL3.D_E_L_E_T_ = ' '
				AND CC2.D_E_L_E_T_ = ' '
				AND A2_COD LIKE 'P%'
				AND CC2_EST = A2_EST 
				AND CC2_CODMUN = A2_COD_MUN
				%exp:cFiltro%
				AND ZL3_FILIAL = %xFilial:ZL3%
				AND ZL2_FILIAL = %xFilial:ZL2%
				AND ZL3_COD = A2_L_LI_RO
				AND ZL2_COD = ZL3_SETOR
			ORDER BY ZL3_COD, A2_COD_MUN, A2_NOME, A2_COD, A2_LOJA
		EndSql

	END REPORT QUERY oOrd2_A

	oOrd2_B:SetParentQuery()
	oOrd2_B:SetParentFilter({|cParam| QRY2->ZL3_COD == cParam },{|| QRY2->ZL3_COD  } )
	
	oOrd2_C:SetParentQuery()                  
	oOrd2_C:SetParentFilter({|cParam| QRY2->ZL3_COD + QRY2->A2_COD_MUN == cParam },{|| QRY2->ZL3_COD + QRY2->A2_COD_MUN  } )
	
	If MV_PAR11 == 1
		oOrd2_C:SetLineCondition({|| (nVol := u_VolLeite(xFilial("ZLD"),FirstDay(MV_PAR06),LastDay(MV_PAR06),MV_PAR01,,QRY2->A2_COD,QRY2->A2_LOJA,)) > 0  } )
	Else                        
		oOrd2_C:Cell("Vol.Mensal"):Disable()
 		oOrd2_C:Cell("Vol.Dia"):Disable()
 	EndIf		
	
	oOrd2_A:Print()	
	

ElseIf nOrdem==3 // Responsavel Tanque
	
	//Efetua quebra por cada modificacao no codigo da ROTA
	DEFINE BREAK oBrk3A OF oReport WHEN oOrd3_A:Cell("ROTA") TITLE {|| "Total Rota: " + cNRota3A } PAGE BREAK	
	oBrk3A:SetTotalText({|| "Total Rota: " + cNRota3A })		
	
	//Efetua quebra por cada modificacao no responsávelpor tanque
	DEFINE BREAK oBrk3B OF oOrd3_B WHEN oOrd3_B:Cell("RESP. TANQUE") TITLE {|| "Total Resp. Tanque: " + cRespTq }
	oBrk3B:SetTotalText({|| "Total Resp. Tanque: " + cRespTq })				
	
	// Acrescentado NO END Section para que não subtotalize a cada quebra de responsavel por tanque
	DEFINE FUNCTION FROM oOrd3_C:Cell("A2_COD")     FUNCTION COUNT BREAK oBrk3A NO END Section NO END REPORT
	DEFINE FUNCTION FROM oOrd3_C:Cell("Vol.Mensal") FUNCTION SUM   BREAK oBrk3A NO END Section NO END REPORT PICTURE "@E 999,999,999"
	DEFINE FUNCTION FROM oOrd3_C:Cell("Vol.Dia")    FUNCTION SUM   BREAK oBrk3A NO END Section NO END REPORT PICTURE "@E 999,999,999"
	DEFINE FUNCTION FROM oOrd3_C:Cell("A2_COD")     FUNCTION COUNT BREAK oBrk3B NO END Section                      //NO END REPORT
	DEFINE FUNCTION FROM oOrd3_C:Cell("Vol.Mensal") FUNCTION SUM   BREAK oBrk3B NO END Section PICTURE "@E 999,999,999" //NO END REPORT
	DEFINE FUNCTION FROM oOrd3_C:Cell("Vol.Dia")    FUNCTION SUM   BREAK oBrk3B NO END Section PICTURE "@E 999,999,999" //NO END REPORT
	
	oReport:Enable()
	oOrd3_A:Enable()
	oOrd3_B:Enable()	
	oOrd3_C:Enable()
	BEGIN REPORT QUERY oOrd3_A
	
	If Upper(MV_PAR04) <> 'C'
		MsgStop("No parâmetro CLASSIFICAÇÃO não foi informado o tipo COLETIVO ('C')."+;
		"Para a impressão da ordem RESPONSÁVEL DO TANQUE é necessário informar no parametro CLASSIFICAÇÃO como COLETIVO ('C').","RGLT05301")
		oReport:CancelPrint()
	EndIf 		
	
	BEGIN REPORT QUERY oOrd3_A 	

		BeginSql alias "QRY3"
			//Q1 = USUARIO Q2 = RESPONSAVEL
			SELECT
				Q1.A2_COD, Q1.A2_LOJA, TRIM(Q1.A2_NOME) A2_NOME, Q1.A2_L_LI_RO, Q1.A2_COD_MUN, TRIM(Q1.A2_END) A2_END, Q1.A2_CGC, Q1.A2_INSCR, Q1.A2_L_SIGSI, TRIM(Q1.A2_L_MARTQ) A2_L_MARTQ, Q1.A2_L_CAPTQ, Q1.A2_L_FREQU, Q2.A2_COD||Q2.A2_LOJA RESP_TQ,
				Case
				  WHEN Q1.A2_COD||Q1.A2_LOJA = Q1.A2_L_TANQ||Q1.A2_L_TANLJ THEN 'RESP.TANQUE'
				  WHEN Q1.A2_COD||Q1.A2_LOJA <> Q1.A2_L_TANQ||Q1.A2_L_TANLJ THEN TO_CHAR(Q1.A2_L_TXRES,'99999990D00')
				END TXRES,
				CC2.CC2_CODMUN, CC2.CC2_EST, TRIM(CC2.CC2_MUN) CC2_MUN,
				ZL3.ZL3_COD, TRIM(ZL3.ZL3_DESCRI) ZL3_DESCRI
			FROM %Table:SA2% Q1, %Table:SA2% Q2, %Table:ZL3% ZL3, %Table:ZL2% ZL2, %Table:CC2% CC2
			WHERE Q1.D_E_L_E_T_ = ' '
				AND Q2.D_E_L_E_T_ = ' '
				AND ZL2.D_E_L_E_T_ = ' '
				AND ZL2.D_E_L_E_T_ = ' '
				AND CC2.D_E_L_E_T_ = ' '
				AND Q2.A2_L_CLASS IN ('C','F')
				AND Q2.A2_COD = Q1.A2_L_TANQ 
				AND Q2.A2_LOJA = Q1.A2_L_TANLJ
				%exp:cFiltro3%
				AND ZL3.ZL3_FILIAL = %xFilial:ZL3%
				AND ZL3.ZL3_COD = Q2.A2_L_LI_RO
				AND ZL2.ZL2_FILIAL = %xFilial:ZL2%
				AND ZL2.ZL2_COD = ZL3.ZL3_SETOR
				AND CC2.CC2_EST = Q2.A2_EST 
				AND CC2.CC2_CODMUN = Q2.A2_COD_MUN
			ORDER BY ZL3.ZL3_COD, RESP_TQ, TXRES DESC, Q2.A2_NOME
		EndSql

	END REPORT QUERY oOrd3_A
	
	oOrd3_B:SetParentQuery()
	oOrd3_B:SetParentFilter({|cParam| QRY3->ZL3_COD == cParam },{|| QRY3->ZL3_COD } )

	oOrd3_C:SetParentQuery()
	oOrd3_C:SetParentFilter({|cParam| QRY3->ZL3_COD + QRY3->RESP_TQ == cParam },{|| QRY3->ZL3_COD + QRY3->RESP_TQ  } )
	
	If MV_PAR11 == 1
		oOrd3_C:SetLineCondition({|| (nVol := u_VolLeite(xFilial("ZLD"),FirstDay(MV_PAR06),LastDay(MV_PAR06),MV_PAR01,,QRY3->A2_COD,QRY3->A2_LOJA,)) > 0  } )
	Else
		oOrd3_C:Cell("Vol.Mensal"):Disable()
 		oOrd3_C:Cell("Vol.Dia"):Disable()
 	EndIf

	oOrd3_A:Print()	
	
	oOrd3_A:Finish()
		
EndIf

Return
