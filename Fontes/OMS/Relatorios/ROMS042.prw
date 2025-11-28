/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaco  |08/02/2022| Chamado 43148 - Ajustes de inclusão de campo se Gera DCT e correção de error.log. 			
Julio Paz     |03/07/2023| Chamado 43597 - Correções no relatorio, Alteração de Titulos e inclusão de novas informações.
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/
#Include "report.ch"
#Include "TOTVS.ch" 
#Include "topconn.ch"

Static _cAliasQRY := ""
/*
===============================================================================================================================
Programa----------: ROMS042
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 01/06/2016
Descrição---------: Relatorio de subsidio de desconto contratual
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS042()
Private oReport		:= Nil
Private oSecEntr_1	:= Nil
Private oSecDado_1	:= Nil
Private oSecEntr_2	:= Nil
Private oSecDado_2	:= Nil

Private oBrkEntr_1	:= Nil

Private _aOrd		:= {  }
Private _cNomeInv	:= "" //Armazena o nome e o codigo de Investimento para ser utilizado na impressao da quebra
Private _cNumPC     := "" //Armazena o numero do PC e nota fiscal para ser utilizado na impressao da quebra

Private _cPerg		:= "ROMS042"
Private _nCont		:= 0

_cAliasQRY := GetNextAlias()

Pergunte( _cPerg , .T. )

DEFINE REPORT oReport	NAME		_cPerg ;
						TITLE		"Relatório de Subsidio de Desconto Contratual" ;
						PARAMETER	_cPerg ;
						ACTION		{|oReport| ROMS042PR( oReport ) } ;
						Description	"Este relatório emitirá a relação de valores por nota de acordo com os parâmetros informados pelo usuário."

//====================================================================================================
// Seta Padrao de impressao como Paisagem
//====================================================================================================
oReport:SetLandscape()
oReport:SetTotalInLine(.F.)

oReport:nFontBody	:= 08
oReport:cFontBody	:= "Courier New"
oReport:nLineHeight	:= 45 // Define a altura da linha.

If MV_PAR12 == 2//Sintético
	//====================================================================================================
	// Secao dados do Investimento
	//====================================================================================================
	DEFINE Section oSecEntr_1 OF oReport TITLE "Entrada_ordem_1" TABLES "SF2" ORDERS _aOrd
	DEFINE CELL NAME "F2_FILIAL"	OF oSecEntr_1 ALIAS "SF2"  TITLE "Filial"	  			SIZE 02
	DEFINE CELL NAME "F2_DOC"  		OF oSecEntr_1 ALIAS "SF2"  TITLE "Documento"			SIZE 20
	DEFINE CELL NAME "F2_EMISSAO"	OF oSecEntr_1 ALIAS "SF2"  TITLE "Emissão"				SIZE 10
	DEFINE CELL NAME "F2_CLIENTE"	OF oSecEntr_1 ALIAS "SF2"  TITLE "Cliente"				SIZE 20
	DEFINE CELL NAME "F2_LOJA"  	OF oSecEntr_1 ALIAS "SF2"  TITLE "Loja"					SIZE 20
	DEFINE CELL NAME "A1_NOME"	    OF oSecEntr_1 ALIAS "SA1"  TITLE "Nome"					SIZE 20 // A1_NREDUZ // JPP TESTE
	DEFINE CELL NAME "_VALBRUT"	    OF oSecEntr_1 ALIAS "SF2"  TITLE "Vlr. Bruto"			SIZE 20 PICTURE "@E 99,999,999,999.99" BLOCK{||IIf(MV_PAR14 == 2,(_cAliasQRY)->VALBRUT,(_cAliasQRY)->VALBRUT*(((_cAliasQRY)->VALMERC-(_cAliasQRY)->TOTDEV)/(_cAliasQRY)->VALMERC))}
	DEFINE CELL NAME "_ICMSRET"	    OF oSecEntr_1 ALIAS "SF2"  TITLE "ICMS Ret"				SIZE 20 PICTURE "@E 99,999,999,999.99" BLOCK{||IIf(MV_PAR14 == 2,(_cAliasQRY)->ICMSRET,(_cAliasQRY)->ICMSRET*(((_cAliasQRY)->VALMERC-(_cAliasQRY)->TOTDEV)/(_cAliasQRY)->VALMERC))}
	DEFINE CELL NAME "_VALMERC"	    OF oSecEntr_1 ALIAS "SF2"  TITLE "Valor Mercadoria"		SIZE 20 PICTURE "@E 99,999,999,999.99" BLOCK{||IIf(MV_PAR14 == 2,(_cAliasQRY)->VALMERC,(_cAliasQRY)->VALMERC-(_cAliasQRY)->TOTDEV)}
	DEFINE CELL NAME "VALIPI"    	OF oSecEntr_1 ALIAS "SD2"  TITLE "Vlr. IPI"				SIZE 20 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "VALICM"    	OF oSecEntr_1 ALIAS "SD2"  TITLE "Vlr. ICMS"			SIZE 20 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "VALPIS"    	OF oSecEntr_1 ALIAS "SD2"  TITLE "Vlr. PIS"				SIZE 20 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "VALCOF"    	OF oSecEntr_1 ALIAS "SD2"  TITLE "Vlr. COFINS"			SIZE 20 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "VALSIMP"   	OF oSecEntr_1 ALIAS "SD2"  TITLE "Vlr. Sem Impostos"	SIZE 20 PICTURE "@E 99,999,999,999.99" BLOCK{||(_cAliasQRY)->VALBRUT - ( (_cAliasQRY)->ICMSRET + (_cAliasQRY)->VALICM  + (_cAliasQRY)->VALIPI  + (_cAliasQRY)->VALPIS  + (_cAliasQRY)->VALCOF )  }
	DEFINE CELL NAME "VLRDC"		OF oSecEntr_1 ALIAS "SF2"  TITLE "Valor Desconto"		SIZE 20 PICTURE "@E 99,999,999,999.99" BLOCK{||IIf(MV_PAR14 == 2,(_cAliasQRY)->VLRDC,(_cAliasQRY)->VLRDC*(((_cAliasQRY)->VALMERC-(_cAliasQRY)->TOTDEV)/(_cAliasQRY)->VALMERC))}
	DEFINE CELL NAME "F2_I_PEDID"	OF oSecEntr_1 ALIAS "SF2"  TITLE "Pedido"				SIZE 20
	DEFINE CELL NAME "F2_I_DESC"	OF oSecEntr_1 ALIAS "SF2"  TITLE "% Desc Contratual"	SIZE 20 PICTURE "@E 99.99"
	DEFINE CELL NAME "F2_I_DCUST"	OF oSecEntr_1 ALIAS "SD2"  TITLE "Utiliza ST?"			SIZE 20 BLOCK{|| IIf((_cAliasQRY)->F2_I_DCUST == "S", "SIM", "NÃO") }
	DEFINE CELL NAME "VDCUS"		OF oSecEntr_1 ALIAS "SF2"  TITLE "% Desc Realizado"		SIZE 20 PICTURE "@E 99,999,999,999.99" BLOCK{|| IIf((_cAliasQRY)->F2_I_DCUST == "S", NoRound(((_cAliasQRY)->VLRDC/(_cAliasQRY)->VALBRUT)*100,2), NoRound(((_cAliasQRY)->VLRDC/(_cAliasQRY)->VALMERC)*100,2)) }
	DEFINE CELL NAME "TOTDEV"	    OF oSecEntr_1 ALIAS "SF2"  TITLE "Devolução"			SIZE 20 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "E2_MUM"    	OF oSecEntr_1 ALIAS "SE2"  TITLE "Gerou DCT?"			SIZE 20 BLOCK{|| IIf( !Empty(AllTrim((_cAliasQRY)->E1_NUM)), "SIM", "NÃO") }

Else//ANALITICO
	//====================================================================================================
	// Secao dados do Investimento
	//====================================================================================================
	DEFINE Section oSecEntr_1 OF oReport TITLE "Entrada_ordem_1" TABLES "SF2" ORDERS _aOrd
	DEFINE CELL NAME "D2_FILIAL"	OF oSecEntr_1 ALIAS "SD2"  TITLE "Filial"	  			SIZE 02
	DEFINE CELL NAME "D2_DOC"  		OF oSecEntr_1 ALIAS "SD2"  TITLE "Documento"			SIZE 20
	DEFINE CELL NAME "D2_EMISSAO"	OF oSecEntr_1 ALIAS "SD2"  TITLE "Emissão"				SIZE 10
	DEFINE CELL NAME "D2_CLIENTE"	OF oSecEntr_1 ALIAS "SD2"  TITLE "Cliente"				SIZE 15
	DEFINE CELL NAME "D2_LOJA"  	OF oSecEntr_1 ALIAS "SD2"  TITLE "Loja"					SIZE 10
	DEFINE CELL NAME "A1_NOME"   	OF oSecEntr_1 ALIAS "SA1"  TITLE "Nome"					SIZE 20 // A1_NREDUZ
	DEFINE CELL NAME "D2_ITEM"		OF oSecEntr_1 ALIAS "SD2"  TITLE "Item"					SIZE 08
	DEFINE CELL NAME "D2_COD"		OF oSecEntr_1 ALIAS "SD2"  TITLE "Produto"				SIZE 20
	DEFINE CELL NAME "B1_DESC"		OF oSecEntr_1 ALIAS "SB1"  TITLE "Descrição"			SIZE 20
	DEFINE CELL NAME "VALBRUT"	    OF oSecEntr_1 ALIAS "SD2"  TITLE "Vlr. Bruto"			SIZE 20 PICTURE "@E 99,999,999,999.99" BLOCK{||IIf(MV_PAR14 == 2,(_cAliasQRY)->D2_VALBRUT,(_cAliasQRY)->D2_VALBRUT*(((_cAliasQRY)->D2_TOTAL-(_cAliasQRY)->D2_VALDEV)/(_cAliasQRY)->D2_TOTAL))}
	DEFINE CELL NAME "ICMSRET"	    OF oSecEntr_1 ALIAS "SD2"  TITLE "ICMS Ret"				SIZE 20 PICTURE "@E 99,999,999,999.99" BLOCK{||IIf(MV_PAR14 == 2,(_cAliasQRY)->D2_ICMSRET,(_cAliasQRY)->D2_ICMSRET*(((_cAliasQRY)->D2_TOTAL-(_cAliasQRY)->D2_VALDEV)/(_cAliasQRY)->D2_TOTAL))}
	DEFINE CELL NAME "TOTAL"		OF oSecEntr_1 ALIAS "SD2"  TITLE "Valor Mercadoria"		SIZE 20 PICTURE "@E 99,999,999,999.99" BLOCK{||IIf(MV_PAR14 == 2,(_cAliasQRY)->D2_TOTAL,(_cAliasQRY)->D2_TOTAL-(_cAliasQRY)->D2_VALDEV)}
	DEFINE CELL NAME "D2_VALIPI"    OF oSecEntr_1 ALIAS "SD2"  TITLE "Vlr. IPI"				SIZE 20 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D2_VALICM"    OF oSecEntr_1 ALIAS "SD2"  TITLE "Vlr. ICMS"			SIZE 20 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D2_VALPIS"    OF oSecEntr_1 ALIAS "SD2"  TITLE "Vlr. PIS"				SIZE 20 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "D2_VALCOF"    OF oSecEntr_1 ALIAS "SD2"  TITLE "Vlr. COFINS"			SIZE 20 PICTURE "@E 99,999,999,999.99"
	DEFINE CELL NAME "VALSIMP"   	OF oSecEntr_1 ALIAS "SD2"  TITLE "Vlr. Sem Impostos"	SIZE 20 PICTURE "@E 99,999,999,999.99" BLOCK{||(_cAliasQRY)->D2_VALBRUT - ( (_cAliasQRY)->D2_ICMSRET + (_cAliasQRY)->D2_VALICM  + (_cAliasQRY)->D2_VALIPI  + (_cAliasQRY)->D2_VALPIS  + (_cAliasQRY)->D2_VALCOF )  }
	DEFINE CELL NAME "_VLRDC"		OF oSecEntr_1 ALIAS "SD2"  TITLE "Valor Desconto"		SIZE 20 PICTURE "@E 99,999,999,999.99" BLOCK{||IIf(MV_PAR14 == 2,(_cAliasQRY)->VLRDC,(_cAliasQRY)->VLRDC*(((_cAliasQRY)->D2_TOTAL-(_cAliasQRY)->D2_VALDEV)/(_cAliasQRY)->D2_TOTAL))}
	DEFINE CELL NAME "D2_PEDIDO"	OF oSecEntr_1 ALIAS "SD2"  TITLE "Pedido"				SIZE 15
	DEFINE CELL NAME "D2_I_PRCDC"	OF oSecEntr_1 ALIAS "SD2"  TITLE "% Desc Contratual"	SIZE 20 PICTURE "@E 99.99"
	DEFINE CELL NAME "F2_I_DCUST"	OF oSecEntr_1 ALIAS "SF2"  TITLE "Utiliza ST?"			SIZE 20 BLOCK{|| IIf((_cAliasQRY)->F2_I_DCUST == "S", "SIM", "NÃO") }
	DEFINE CELL NAME "VDCUS"		OF oSecEntr_1 ALIAS "SD2"  TITLE "% Desc Realizado"		SIZE 20 PICTURE "@E 99,999,999,999.99" BLOCK{|| IIf((_cAliasQRY)->F2_I_DCUST == "S", NoRound(((_cAliasQRY)->VLRDC/(_cAliasQRY)->D2_VALBRUT)*100,2), NoRound(((_cAliasQRY)->VLRDC/(_cAliasQRY)->D2_TOTAL)*100,2)) }
	DEFINE CELL NAME "TIPO"			OF oSecEntr_1 ALIAS "SD2"  TITLE "Tipo"					SIZE 15 BLOCK{|| ROMS042T((_cAliasQRY)->D2_CF)}
	DEFINE CELL NAME "D2_VALDEV"    OF oSecEntr_1 ALIAS "SF2"  TITLE "Devolução"			SIZE 20 PICTURE "@E 99,999,999,999.99"
    DEFINE CELL NAME "C5_I_OPER"	OF oSecEntr_1 ALIAS "SF2"  TITLE "Tp Oper."				SIZE 20
	DEFINE CELL NAME "C5_I_OPTRI"	OF oSecEntr_1 ALIAS "SC5" TITLE "Tp PV Op Tri?"         SIZE 13
	DEFINE CELL NAME "C5_I_PVREM"   OF oSecEntr_1 ALIAS "SC5" TITLE "PV Remessa"            SIZE 10 
	DEFINE CELL NAME "C5_I_PVFAT"   OF oSecEntr_1 ALIAS "SC5" TITLE "PV Faturamento"        SIZE 14
	DEFINE CELL NAME "C5_I_CLIEN"   OF oSecEntr_1 ALIAS "SC5" TITLE "Cliente Triangular"       SIZE 11 BLOCK {|| U_ROMS042Q("C5_I_CLIEN") } // -->  "Cliente Rem."
	DEFINE CELL NAME "C5_I_LOJEN"   OF oSecEntr_1 ALIAS "SC5" TITLE "Loja Tri."                SIZE 10 BLOCK {|| U_ROMS042Q("C5_I_LOJEN") }// -->  "Loja Rem."
	DEFINE CELL NAME "A1_NOME"      OF oSecEntr_1 ALIAS ""    TITLE "Razão Social Triangular"  SIZE 40 BLOCK {|| U_ROMS042Q("A1_NOME") } PICTURE "@!" // --> "Razao Social Cli.Rem." // BLOCK {|| (_cAliasQRY)->NOME_CLIREM    }
	DEFINE CELL NAME "A1_NREDUZ"    OF oSecEntr_1 ALIAS "SA1" TITLE "Nome Fantasia Triangular" SIZE 40 BLOCK {|| U_ROMS042Q("A1_NREDUZ") } PICTURE "@!" // --> "Nome Fantasia Cli.Rem." // BLOCK {|| (_cAliasQRY)->FANTASIA_CLIREM}
	DEFINE CELL NAME "VENDREM"      OF oSecEntr_1 ALIAS ""    TITLE "Vendedor Triangular"      SIZE 20 BLOCK {|| U_ROMS042Q("VENDREM") } PICTURE "@!" // --> "Vendedor Remessa" // BLOCK {|| (_cAliasQRY)->VENDREM        }
	DEFINE CELL NAME "NOMEVENDREM"  OF oSecEntr_1 ALIAS ""    TITLE "Nome Vendedor Triangular" SIZE 40 BLOCK {|| U_ROMS042Q("NOMEVENDREM") } PICTURE "@!" // --> "Nome Vendedor Remessa" // BLOCK {|| (_cAliasQRY)->NOMEVENDREM    }
	DEFINE CELL NAME "GEROU_DCT"  	OF oSecEntr_1 ALIAS "SE1"  TITLE "Gerou DCT?"			SIZE 20 BLOCK{|| U_ROMS042Q("GEROU_DCT") }
EndIf

oSecEntr_1:Disable()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ROMS042PR
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 01/06/2012
===============================================================================================================================
Descrição---------: Executa relatório
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS042PR( oReport )
Local 	_cFiltro  	:= "% "

oSecEntr_1:Enable()


If !Empty(MV_PAR01)

	_cFiltro += " F2_FILIAL IN " + FormatIn(AllTrim(MV_PAR01),";") + " AND "
	
EndIf

_cFiltro += "  F2_DOC BETWEEN '" + MV_PAR02 + "' AND '" + MV_PAR03 + "' "
_cFiltro += " AND F2_CLIENTE BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR06 + "' "
_cFiltro += " AND F2_LOJA BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR07 + "' "
_cFiltro += " AND F2_EMISSAO BETWEEN '"+ DToS( MV_PAR10 ) +"' AND '"+ DToS( MV_PAR11 ) +"' "
_cFiltro += " AND SA1.A1_GRPVEN BETWEEN '" + MV_PAR08 + "' AND '" + MV_PAR09 + "' "

If !Empty(MV_PAR13)

	_cFiltro += " AND SC5.C5_I_OPER IN " + FormatIn(AllTrim(MV_PAR13),";") 
	
EndIf

If !Empty(MV_PAR15)

	_cFiltro += " AND (SELECT ZAY_TPOPER FROM " + retsqlname("ZAY") + " ZAY WHERE ZAY.D_E_L_E_T_ = ' ' AND ZAY_FILIAL = '" + xFilial("ZAY") + "' AND ZAY_CF = SD2.D2_CF AND ROWNUM = 1) IN " + FormatIn(MV_PAR15,";") 
	
EndIf

If MV_PAR12 = 1 //ANALITICO
   _cFiltro += " AND F2_TIPO = 'N' "
EndIf

_cFiltro += " %"

If MV_PAR12 == 2 //Sintético
	oReport:SetTitle( "Valores por Nota  - Emissão de " + DToC(MV_PAR10) + " até "  + DToC(MV_PAR11) + " - Sintético" )

	//====================================================================================================
	// Executa query para consultar Dados
	//====================================================================================================
	BEGIN REPORT QUERY oSecEntr_1
		
		BeginSql Alias _cAliasQRY
			
			SELECT F2_FILIAL, F2_DOC, F2_SERIE, F2_EMISSAO, F2_CLIENTE, F2_LOJA, SUM(D2_TOTAL) VALMERC,
			 		SUM(D2_ICMSRET) ICMSRET, SUM(D2_VALIMP6 + D2_VALPIS) VALPIS, SUM(D2_VALIMP5 + D2_VALCOF) VALCOF, SUM(D2_VALIPI) VALIPI, SUM(D2_VALICM) VALICM, SUM(D2_VALBRUT) VALBRUT, SUM(D2_I_VLRDC + D2_I_VLPAR) VLRDC, F2_I_DCUST, 
			 		F2_I_PEDID, ((100 * SUM(D2_I_VLRDC + D2_I_VLPAR))/SUM(D2_VALBRUT)) F2_I_DESC,SA1.A1_NOME, 
			 		SUM(SD2.D2_VALDEV) TOTDEV, E1_NUM, SUM(D2_VALIMP6 + D2_VALPIS) D2_VALPIS
			FROM %Table:SF2% SF2
            JOIN %Table:SD2% SD2 ON F2_FILIAL = D2_FILIAL AND F2_DOC = D2_DOC AND F2_SERIE = D2_SERIE AND F2_CLIENTE = D2_CLIENTE AND F2_LOJA = D2_LOJA AND SD2.%notDel%
			JOIN %Table:SA1% SA1 ON A1_FILIAL = %xFilial:SA1% AND A1_COD = F2_CLIENTE AND A1_LOJA = F2_LOJA AND SA1.%notDel%
            LEFT JOIN %Table:SC5% SC5 ON C5_FILIAL = SD2.D2_FILIAL AND C5_NUM = SD2.D2_PEDIDO AND SC5.%notDel%
            LEFT JOIN %Table:SE1% SE1 ON E1_FILIAL = SF2.F2_FILIAL AND E1_NUM = SF2.F2_DOC AND E1_CLIENTE = SF2.F2_CLIENTE AND E1_LOJA = SF2.F2_LOJA AND E1_PREFIXO = 'DCT' AND SE1.%notDel%

			WHERE %exp:_cFiltro%
			  AND SF2.%notDel%
            GROUP BY F2_FILIAL, F2_DOC, F2_SERIE, F2_EMISSAO, F2_CLIENTE, F2_LOJA, F2_VALMERC, F2_ICMSRET, F2_VALBRUT, F2_I_VLRDC, 
                    F2_I_VLPAR, F2_I_DCUST, F2_I_PEDID, F2_I_VLRDC, F2_I_VLPAR, F2_VALBRUT, A1_NOME, E1_NUM
			ORDER BY F2_FILIAL, F2_EMISSAO, F2_DOC, F2_CLIENTE, F2_LOJA

		EndSql
		 
	END REPORT QUERY oSecEntr_1
		
Else//Analítico
	oReport:SetTitle( "Valores por Nota  - Emissão de " + DToC(MV_PAR10) + " até "  + DToC(MV_PAR11) + " - Analítico" )


	//====================================================================================================
	// Executa query para consultar Dados
	//====================================================================================================

	BEGIN REPORT QUERY oSecEntr_1
		
		BeginSql alias _cAliasQRY
			
			SELECT D2_FILIAL, D2_DOC, D2_SERIE, D2_EMISSAO, D2_CLIENTE, D2_LOJA, D2_ITEM, D2_COD, D2_CF, D2_VALBRUT,
			       D2_TOTAL, D2_ICMSRET, (D2_VALIMP6 + D2_VALPIS) D2_VALPIS, (D2_VALIMP5 + D2_VALCOF) D2_VALCOF, D2_VALIPI, D2_VALICM, D2_PEDIDO, (D2_I_VLRDC + D2_I_VLPAR) VLRDC, D2_I_PRCDC, SA1.A1_NOME, B1_DESC, F2_I_DCUST,D2_VALDEV ,
					SC5.C5_I_OPER,SC5.C5_I_OPTRI,SC5.C5_I_PVREM,SC5.C5_I_PVFAT,	SC5.C5_I_CLIEN, SC5.C5_I_LOJEN, SA1R.A1_NOME AS NOME_CLIREM,SA1R.A1_NREDUZ AS FANTASIA_CLIREM, SC52.C5_VEND1 VENDREM, SC52.C5_I_V1NOM NOMEVENDREM,
					D2_I_VLRDC
			FROM %Table:SF2% SF2
			JOIN %Table:SD2% SD2 ON F2_FILIAL = D2_FILIAL AND F2_DOC = D2_DOC AND F2_SERIE = D2_SERIE AND F2_CLIENTE = D2_CLIENTE AND F2_LOJA = D2_LOJA AND SD2.%notDel%
			JOIN %Table:SA1% SA1 ON A1_FILIAL = %xFilial:SA1% AND A1_COD = F2_CLIENTE AND A1_LOJA = F2_LOJA AND SA1.%notDel%
            JOIN %Table:SC5% SC5 ON SC5.C5_FILIAL  = SD2.D2_FILIAL AND SC5.C5_NUM  = SD2.D2_PEDIDO  AND SC5.%notDel%
            LEFT JOIN %Table:SB1% SB1 ON B1_FILIAL = %xFilial:SB1% AND B1_COD = D2_COD AND SB1.%notDel%
	        LEFT JOIN %Table:SC5% SC52 ON SC52.C5_FILIAL = SC5.C5_FILIAL AND SC52.C5_NUM = SC5.C5_I_PVREM AND SC52.%notDel%
			LEFT JOIN %Table:SA1% SA1R ON SA1R.A1_FILIAL = ' ' AND SA1R.A1_COD = SC5.C5_I_CLIEN AND SA1R.A1_LOJA = SC5.C5_I_LOJEN AND SA1R.%notDel% 
  
			WHERE %exp:_cFiltro%
			  AND SF2.%notDel%
			ORDER BY  D2_FILIAL, D2_EMISSAO, D2_DOC, D2_ITEM, D2_CLIENTE, D2_LOJA

		EndSql
		 
	END REPORT QUERY oSecEntr_1

EndIf

oSecEntr_1:Print(.T.)

Return

/*
===============================================================================================================================
Programa----------: ROMS042T
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 05/06/2016
===============================================================================================================================
Descrição---------: Função criada para verificar qual o tipo de operação
===============================================================================================================================
Parametros--------: _cTipCf	- Tipo de operação do registro atual
===============================================================================================================================
Retorno-----------: _cRet	- Retorna a descrição do tipo de operação
===============================================================================================================================
*/
Static Function ROMS042T(_cTipCf)
Local _aArea	:= FWGetArea()
Local _cRet		:= ""

DBSelectArea("ZAY")
DBSetOrder(1)
If DBSeek(xFilial("ZAY") + _cTipCf)

	If ZAY->ZAY_TPOPER == "V"
		_cRet := "VENDAS"
	ElseIf ZAY->ZAY_TPOPER == "B"
		_cRet := "BONIFICAÇÃO"
	ElseIf ZAY->ZAY_TPOPER == "T"
		_cRet := "TRANSFERÊNCIA"
	ElseIf ZAY->ZAY_TPOPER == "R"
		_cRet := "REMESSA"
	ElseIf ZAY->ZAY_TPOPER == "Z"
		_cRet := "AMOSTRA"
	ElseIf ZAY->ZAY_TPOPER == "O"
		_cRet := "OUTROS"
	EndIf
EndIf

FWRestArea(_aArea)
Return(_cRet)


/*
===============================================================================================================================
Programa----------: ROMS042T
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 05/06/2016
===============================================================================================================================
Descrição---------: Função criada para verificar qual o tipo de operação
===============================================================================================================================
Parametros--------: _cCampo - Campo do relatório que chamou a função.
===============================================================================================================================
Retorno-----------: _cRet	- Retorna o conteúdo do campo.
===============================================================================================================================
*/
User Function ROMS042Q(_cCampo)
Local _cRet := ""
Local _lAchou := .F.
Local _cDCT := ""


Begin Sequence 
   
   If _cCampo == "GEROU_DCT"
   
	  // Índice SE1 - 02 - E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	  _cDCT := Posicione("SE1",2,(_cAliasQRY)->D2_FILIAL+(_cAliasQRY)->D2_CLIENTE + (_cAliasQRY)->D2_LOJA +U_ITKEY("DCT", "E1_PREFIXO") + (_cAliasQRY)->D2_DOC ,"E1_NUM")

	  If Empty(_cDCT)
	     _cRet := "NAO" 
	  Else 
         _cRet := "SIM"
	  EndIf 

      Break 
   EndIf 

   If _cCampo $ "C5_I_CLIEN/C5_I_LOJEN/A1_NOME/A1_NREDUZ/VENDREM/NOMEVENDREM"
   
      If (_cAliasQRY)->C5_I_OPER <> "05" .And. (_cAliasQRY)->C5_I_OPER <> "42"   
         If _cCampo == "C5_I_CLIEN"      // "Cliente Triangular" 
            _cRet := (_cAliasQRY)->C5_I_CLIEN 
         ElseIf _cCampo == "C5_I_LOJEN"  // "Loja Tri."
            _cRet := (_cAliasQRY)->C5_I_LOJEN
         ElseIf _cCampo == "A1_NOME"     // "Razão Social Triangular" 
            _cRet := (_cAliasQRY)->NOME_CLIREM 
         ElseIf _cCampo == "A1_NREDUZ"   // "Nome Fantasia Triangular"
            _cRet := (_cAliasQRY)->FANTASIA_CLIREM
         ElseIf _cCampo == "VENDREM"     // "Vendedor Triangular"      
            _cRet := (_cAliasQRY)->VENDREM 
         ElseIf _cCampo == "NOMEVENDREM" // "Nome Vendedor Triangular"
            _cRet := (_cAliasQRY)->NOMEVENDREM
	     EndIf 
      Else
         _cRet :=  ""
         SC5->(DBSetOrder(1))
         _lAchou := .F.

         If (_cAliasQRY)->C5_I_OPER == "05" .And. SC5->(MsSeek( (_cAliasQRY)->D2_FILIAL + (_cAliasQRY)->C5_I_PVREM))
	        _lAchou := .T. 
         EndIf 

	     If (_cAliasQRY)->C5_I_OPER == "42" .And. SC5->(MsSeek( (_cAliasQRY)->D2_FILIAL + (_cAliasQRY)->C5_I_PVFAT))
	        _lAchou := .T. 
         EndIf 

	     If _lAchou
            If _cCampo == "C5_I_CLIEN"      // "Cliente Triangular" 
               _cRet := SC5->C5_CLIENTE
            ElseIf _cCampo == "C5_I_LOJEN"  // "Loja Tri."
               _cRet := SC5->C5_LOJACLI
            ElseIf _cCampo == "A1_NOME"     // "Razão Social Triangular" 
               _cRet := Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME")
            ElseIf _cCampo == "A1_NREDUZ"   // "Nome Fantasia Triangular"
               _cRet := Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ")
            ElseIf _cCampo == "VENDREM"     // "Vendedor Triangular"      
               _cRet := SC5->C5_VEND1 //Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ")
            ElseIf _cCampo == "NOMEVENDREM" // "Nome Vendedor Triangular"
               _cRet := SC5->C5_I_V1NOM
	        EndIf 
         EndIf 
	  EndIf 	 
   EndIf 

End Sequence 

Return _cRet
