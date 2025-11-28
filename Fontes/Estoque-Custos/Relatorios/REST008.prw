/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |06/11/2019| Chamado 28346. Revisão de fonte para novo appserver
Julio Paz     |08/08/2022| Chamado 40619. Realização de Ajustes no Relatório, Alteração Títulos, Colunas, Inclusão colunas.
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include 'TOPCONN.CH'

/*
===============================================================================================================================
Programa----------: REST008
Autor-------------: Darcio R Sporl
Data da Criacao---: 08/07/2016
Descrição---------: Relatório de central de pallets
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function REST008()
Local oReport	:= nil
Private _cPerg	:= "REST008"
Private aOrd	:= {} 

If !Pergunte(_cPerg,.T.)
     Return
EndIf

oReport := REST008R(_cPerg)
oReport:PrintDialog()  

//========================================================================
// Grava log de Relatório de Relatório Clientes com Contrato.
//======================================================================== 
U_ITLOGACS('REST008')

Return

/*
===============================================================================================================================
Programa----------: REST008R
Autor-------------: Darcio R Sporl
Data da Criacao---: 08/07/2016
Descrição---------: Função que faz a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function REST008R(cNome)
Local oReport	:= Nil
Local oSection1	:= Nil
Local oSection2	:= Nil
Local oSection3 := Nil
Local oSection4 := Nil
Local oSection5 := Nil
Local oSection6 := Nil
	
oReport:= TReport():New("REST008","Relatório Movimentações. - " + AllTrim(MV_PAR05) + " - " + Posicione("SB1",1,xFilial("SB1")+AllTrim(MV_PAR05),"B1_DESC");
							+ " -> "+ AllTrim(MV_PAR06) + " - " + Posicione("SB1",1,xFilial("SB1")+AllTrim(MV_PAR06),"B1_DESC"),"REST008",;
							 {|oReport| REST008P(oReport)},"Emissao da Relacao das movimentações de estoque.")
oReport:SetLandscape()

If MV_PAR08 == 1		//Entradas
	oSection1 := TRSection():New(oReport, "Movimentações por Produto", {"TRBPRO"},aOrd , .F., .T.)

	TRCell():New(oSection1,"PRODUTO"	,"TRBPRO","Produto"  		,"@!",100)
	
	oSection2 := TRSection():New(oSection1, "Documento de Entrada", {"TRBNFE"}, NIL, .F., .T.)

	TRCell():New(oSection2,"DATADOC"	,"TRBNFE","Data"				,"@D",10)
	TRCell():New(oSection2,"DOCUMENTO"	,"TRBNFE","Documento Entrada"	,"@!",15)
	TRCell():New(oSection2,"CLIENTE"	,"TRBNFE","Cliente"				,"@!",50)
	TRCell():New(oSection2,"QTDE1UM"	,"TRBNFE","Qtde 1a UM"			,"@E 99,999,999,999.999",25)
	TRCell():New(oSection2,"1UNIDME"	,"TRBNFE","1a UM"				,"@!",06)
	TRCell():New(oSection2,"QTDE2UM"	,"TRBNFE","Qtde 2a UM"			,"@E 999,999,999.999",20)
	TRCell():New(oSection2,"2UNIDME"	,"TRBNFE","2a UM"				,"@!",06)
	TRCell():New(oSection2,"PRCUNIT"	,"TRBNFE","Prc. Unit."			,"@E 99,999,999,999.99",25)
	TRCell():New(oSection2,"VLRTOTAL"	,"TRBNFE","Valor Total"			,"@E 99,999,999,999.99",25)

	oSection3 := TRSection():New(oSection1, "Movimentações Internas (Entradas)", {"TRBMVE"}, NIL, .F., .T.)

	TRCell():New(oSection3,"DATADOC"	,"TRBMVE","Data"				,"@D",10)
	TRCell():New(oSection3,"TPMOVIM"	,"TRBMVE","Tp.Mov.Entrada"		,"@!",50)
	TRCell():New(oSection3,"QTDE1UM"	,"TRBMVE","Qtde 1a UM"			,"@E 99,999,999,999.999",25)
	TRCell():New(oSection3,"1UNIDME"	,"TRBMVE","1a UM"				,"@!",06)
	TRCell():New(oSection3,"QTDE2UM"	,"TRBMVE","Qtde 2a UM"			,"@E 999,999,999.999",20)
	TRCell():New(oSection3,"2UNIDME"	,"TRBMVE","2a UM"				,"@!",06)
	TRCell():New(oSection3,"PRCUNIT"	,"TRBMVE","Prc. Unit."			,"@E 99,999,999,999.99",25)
	TRCell():New(oSection3,"VLRTOTAL"	,"TRBMVE","Valor Total"			,"@E 99,999,999,999.99",25)

	oSection4 := TRSection():New(oSection1, "Central Pallets Chep", {"TRBPAL"}, NIL, .F., .T.)

	TRCell():New(oSection4,"DTINCL"	,"TRBPAL","Data Contagem"		,"@D",10)
	TRCell():New(oSection4,"PALCPR"	,"TRBPAL","Pallet C/ Prod"		,"@E 99,999,999,999.999",25)
	TRCell():New(oSection4,"PALCEA"	,"TRBPAL","Pallet Emb/Alm"		,"@E 99,999,999,999.999",25)
	TRCell():New(oSection4,"PALAVA"	,"TRBPAL","Pallet Avaria"		,"@E 99,999,999,999.999",25)
	TRCell():New(oSection4,"PALVAZ"	,"TRBPAL","Pallet Vazio"		,"@E 99,999,999,999.999",25)
	TRCell():New(oSection4,"PALSUJ"	,"TRBPAL","Pallet Sujo"			,"@E 99,999,999,999.999",25)
	TRCell():New(oSection4,"PALTOT"	,"TRBPAL","Tot.Pallets Fabric"	,"@E 99,999,999,999.999",25) // Total Pallets 
	TRCell():New(oSection4,"MEDCON"	,"TRBPAL","Média Cons.Dia"		,"@E 99,999,999,999.999",25)
	TRCell():New(oSection4,"AUTEST"	,"TRBPAL","Aut. Est. Dias"		,"@E 99,999,999,999.999",25)

ElseIf MV_PAR08 == 2	//Saídas
	oSection1:= TRSection():New(oReport, "Movimentações por Produto", {"TRBPRO"},aOrd , .F., .T.)

	TRCell():New(oSection1,"PRODUTO"	,"TRBPRO","Produto"  		,"@!",100)
	
	oSection2:= TRSection():New(oSection1, "Documento de Saída", {"TRBNFS"}, NIL, .F., .T.)

	TRCell():New(oSection2,"DATADOC"	,"TRBNFS","Data"				,"@D",10)
	TRCell():New(oSection2,"DOCUMENTO"	,"TRBNFS","Documento Saída"		,"@!",15)
	TRCell():New(oSection2,"CLIENTE"	,"TRBNFS","Cliente"				,"@!",50)
	TRCell():New(oSection2,"QTDE1UM"	,"TRBNFS","Qtde 1a UM"			,"@E 99,999,999,999.999",25)
	TRCell():New(oSection2,"1UNIDME"	,"TRBNFS","1a UM"				,"@!",06)
	TRCell():New(oSection2,"QTDE2UM"	,"TRBNFS","Qtde 2a UM"			,"@E 999,999,999.999",20)
	TRCell():New(oSection2,"2UNIDME"	,"TRBNFS","2a UM"				,"@!",06)
	TRCell():New(oSection2,"PRCUNIT"	,"TRBNFS","Prc. Unit."			,"@E 99,999,999,999.99",25)
	TRCell():New(oSection2,"VLRTOTAL"	,"TRBNFS","Valor Total"			,"@E 99,999,999,999.99",25)

	oSection3:= TRSection():New(oSection1, "Movimentações Internas (Saídas)", {"TRBMVS"}, NIL, .F., .T.)

	TRCell():New(oSection3,"DATADOC"	,"TRBMVS","Data"				,"@D",10)
	TRCell():New(oSection3,"TPMOVIM"	,"TRBMVS","Tp.Mov.Saída"		,"@!",50)
	TRCell():New(oSection3,"QTDE1UM"	,"TRBMVS","Qtde 1a UM"			,"@E 99,999,999,999.999",25)
	TRCell():New(oSection3,"1UNIDME"	,"TRBMVS","1a UM"				,"@!",06)
	TRCell():New(oSection3,"QTDE2UM"	,"TRBMVS","Qtde 2a UM"			,"@E 999,999,999.999",20)
	TRCell():New(oSection3,"2UNIDME"	,"TRBMVS","2a UM"				,"@!",06)
	TRCell():New(oSection3,"PRCUNIT"	,"TRBMVS","Prc. Unit."			,"@E 99,999,999,999.99",25)
	TRCell():New(oSection3,"VLRTOTAL"	,"TRBMVS","Valor Total"			,"@E 99,999,999,999.99",25)

	oSection4 := TRSection():New(oSection1, "Central Pallets Chep", {"TRBPAL"}, NIL, .F., .T.)

	TRCell():New(oSection4,"DTINCL"	,"TRBPAL","Data Contagem"		,"@D",10)
	TRCell():New(oSection4,"PALCPR"	,"TRBPAL","Pallet C/ Prod"		,"@E 99,999,999,999.999",25)
	TRCell():New(oSection4,"PALCEA"	,"TRBPAL","Pallet Emb/Alm"		,"@E 99,999,999,999.999",25)
	TRCell():New(oSection4,"PALAVA"	,"TRBPAL","Pallet Avaria"		,"@E 99,999,999,999.999",25)
	TRCell():New(oSection4,"PALVAZ"	,"TRBPAL","Pallet Vazio"		,"@E 99,999,999,999.999",25)
	TRCell():New(oSection4,"PALSUJ"	,"TRBPAL","Pallet Sujo"			,"@E 99,999,999,999.999",25)
	TRCell():New(oSection4,"PALTOT"	,"TRBPAL","Tot.Pallets Fabric"	,"@E 99,999,999,999.999",25) // Total Pallets 
	TRCell():New(oSection4,"MEDCON"	,"TRBPAL","Média Cons.Dia"		,"@E 99,999,999,999.999",25)
	TRCell():New(oSection4,"AUTEST"	,"TRBPAL","Aut. Est. Dias"		,"@E 99,999,999,999.999",25)

Else					//Ambas

	oSection1:= TRSection():New(oReport, "Movimentações por Produto", {"TRBPRO"},aOrd , .F., .T.)

	TRCell():New(oSection1,"PRODUTO"	,"TRBPRO","Produto"  		,"@!",100)
	
	oSection2:= TRSection():New(oSection1, "Documento de Entrada", {"TRBNFE"}, NIL, .F., .T.)

	TRCell():New(oSection2,"DATADOC"	,"TRBNFE","Data"				,"@D",10)
	TRCell():New(oSection2,"DOCUMENTO"	,"TRBNFE","Documento Entrada"	,"@!",15)
	TRCell():New(oSection2,"CLIENTE"	,"TRBNFE","Cliente"				,"@!",50)
	TRCell():New(oSection2,"QTDE1UM"	,"TRBNFE","Qtde 1a UM"			,"@E 99,999,999,999.999",25)
	TRCell():New(oSection2,"1UNIDME"	,"TRBNFE","1a UM"				,"@!",06)
	TRCell():New(oSection2,"QTDE2UM"	,"TRBNFE","Qtde 2a UM"			,"@E 999,999,999.999",20)
	TRCell():New(oSection2,"2UNIDME"	,"TRBNFE","2a UM"				,"@!",06)
	TRCell():New(oSection2,"PRCUNIT"	,"TRBNFE","Prc. Unit."			,"@E 99,999,999,999.99",25)
	TRCell():New(oSection2,"VLRTOTAL"	,"TRBNFE","Valor Total"			,"@E 99,999,999,999.99",25)

	oSection3:= TRSection():New(oSection1, "Movimentações Internas (Entadas)", {"TRBMVE"}, NIL, .F., .T.)

	TRCell():New(oSection3,"DATADOC"	,"TRBMVE","Data"				,"@D",10)
	TRCell():New(oSection3,"TPMOVIM"	,"TRBMVE","Tp.Mov.Entrada"		,"@!",50)
	TRCell():New(oSection3,"QTDE1UM"	,"TRBMVE","Qtde 1a UM"			,"@E 99,999,999,999.999",25)
	TRCell():New(oSection3,"1UNIDME"	,"TRBMVE","1a UM"				,"@!",06)
	TRCell():New(oSection3,"QTDE2UM"	,"TRBMVE","Qtde 2a UM"			,"@E 999,999,999.999",20)
	TRCell():New(oSection3,"2UNIDME"	,"TRBMVE","2a UM"				,"@!",06)
	TRCell():New(oSection3,"PRCUNIT"	,"TRBMVE","Prc. Unit."			,"@E 99,999,999,999.99",25)
	TRCell():New(oSection3,"VLRTOTAL"	,"TRBMVE","Valor Total"			,"@E 99,999,999,999.99",25)

	oSection4:= TRSection():New(oSection1, "Documento de Saída", {"TRBNFS"}, NIL, .F., .T.)

	TRCell():New(oSection4,"DATADOC"	,"TRBNFS","Data"				,"@D",10)
	TRCell():New(oSection4,"DOCUMENTO"	,"TRBNFS","Documento Saída"		,"@!",15)
	TRCell():New(oSection4,"CLIENTE"	,"TRBNFS","Cliente"				,"@!",50)
	TRCell():New(oSection4,"QTDE1UM"	,"TRBNFS","Qtde 1a UM"			,"@E 99,999,999,999.999",25)
	TRCell():New(oSection4,"1UNIDME"	,"TRBNFS","1a UM"				,"@!",06)
	TRCell():New(oSection4,"QTDE2UM"	,"TRBNFS","Qtde 2a UM"			,"@E 999,999,999.999",20)
	TRCell():New(oSection4,"2UNIDME"	,"TRBNFS","2a UM"				,"@!",06)
	TRCell():New(oSection4,"PRCUNIT"	,"TRBNFS","Prc. Unit."			,"@E 99,999,999,999.99",25)
	TRCell():New(oSection4,"VLRTOTAL"	,"TRBNFS","Valor Total"			,"@E 99,999,999,999.99",25)

	oSection5:= TRSection():New(oSection1, "Movimentações Internas (Saídas)", {"TRBMVS"}, NIL, .F., .T.)

	TRCell():New(oSection5,"DATADOC"	,"TRBMVS","Data"				,"@D",10)
	TRCell():New(oSection5,"TPMOVIM"	,"TRBMVS","Tp.Mov.Saída"		,"@!",50)
	TRCell():New(oSection5,"QTDE1UM"	,"TRBMVS","Qtde 1a UM"			,"@E 99,999,999,999.999",25)
	TRCell():New(oSection5,"1UNIDME"	,"TRBMVS","1a UM"				,"@!",06)
	TRCell():New(oSection5,"QTDE2UM"	,"TRBMVS","Qtde 2a UM"			,"@E 999,999,999.999",20)
	TRCell():New(oSection5,"2UNIDME"	,"TRBMVS","2a UM"				,"@!",06)
	TRCell():New(oSection5,"PRCUNIT"	,"TRBMVS","Prc. Unit."			,"@E 99,999,999,999.99",25)
	TRCell():New(oSection5,"VLRTOTAL"	,"TRBMVS","Valor Total"			,"@E 99,999,999,999.99",25)


	oSection6:= TRSection():New(oSection1, "Resumo das Movimentações", {"TRBMOV"}, NIL, .F., .T.)

	TRCell():New(oSection6,"ESTINIC"	,"TRBMVS","Estoque Inicial"		,"@E 99,999,999,999.999",22)
	TRCell():New(oSection6,"DOCENTR"	,"TRBMVS","Tot. Entradas"		,"@E 99,999,999,999.999",22)
	TRCell():New(oSection6,"DOCSAID"	,"TRBMVS","Tot. Saidas"			,"@E 99,999,999,999.999",22)
	TRCell():New(oSection6,"ESTATUA"	,"TRBMVS","Saldo Atual"		    ,"@E 99,999,999,999.999",22) // Estoque Atual 
	If MV_PAR04 >= Date()
		TRCell():New(oSection6,"SALATUA"	,"TRBMVS","Estoque Atual"   ,"@E 99,999,999,999.999",22) // Saldo Atual 
	EndIf		 
	TRCell():New(oSection6,"PALCPR"	   ,"TRBMVS","Pallet C/ Prod"		,"@E 99,999,999,999.999",22)
	TRCell():New(oSection6,"PALCEA"	   ,"TRBMVS","Pallet Emb/Alm"		,"@E 99,999,999,999.999",22)
	TRCell():New(oSection6,"PALAVA"	   ,"TRBMVS","Pallet Avaria"		,"@E 99,999,999,999.999",22)
	TRCell():New(oSection6,"PALVAZ"	   ,"TRBMVS","Pallet Vazio"			,"@E 99,999,999,999.999",22)
	TRCell():New(oSection6,"PALSUJ"	   ,"TRBMVS","Pallet Sujo"			,"@E 99,999,999,999.999",22)
	TRCell():New(oSection6,"PALDES"	   ,"TRBMVS","Pallet Descarte"		,"@E 99,999,999,999.999",22)
	TRCell():New(oSection6,"PALPEC"	   ,"TRBMVS","Qtde Peças"			,"@E 99,999,999,999.999",22)
	TRCell():New(oSection6,"TOTPALL"   ,"TRBMVS","Tot.Pallets Fabric"	,"@E 99,999,999,999.999",22) // Total Pallets 
	TRCell():New(oSection6,"DIFEREN"   ,"TRBMVS","Diferença"			,"@E 99,999,999,999.999",22)
	TRCell():New(oSection6,"MEDCONS"   ,"TRBMVS","Méd.Cons.Dias"		,"@E 99,999,999,999.999",22)
	TRCell():New(oSection6,"AUTESTD"   ,"TRBMVS","Auto.Est.Dias"		,"@E 99,999,999,999.999",22)
	TRCell():New(oSection6,"DTINCL"	   ,"TRBMVS","Data Contagem"		,"@D",10)
	TRCell():New(oSection6,"TOTGERPALL","TRBMVS","Total Pallets"		,"@E 99,999,999,999.999",22) // Total Pallets 

EndIf

Return(oReport)

/*
===============================================================================================================================
Programa----------: REST008P
Autor-------------: Darcio R Sporl
Data da Criacao---: 08/07/2016
Descrição---------: Função que imprime o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function REST008P(oReport)
Local oSection1 := oReport:Section(1)
Local oSection2 := oReport:Section(1):Section(1)
Local oSection3 := oReport:Section(1):Section(2)
Local oSection4	:= oReport:Section(1):Section(3)
Local oSection5	:= Nil
Local oSection6	:= Nil
Local oSection7 := Nil
Local cQry1		:= ""
Local cQry2		:= ""
Local cQry3		:= ""
Local cQry4		:= ""
Local cQry5		:= ""
Local cQry6		:= ""
Local aResum	:= {} , nJ , nI , nX
Local aDados	:= Array(19)
Local nDias		:= (MV_PAR04 - MV_PAR03) + 1

If MV_PAR08 == 1

	cQry1 := "SELECT B1_COD, B1_GRUPO, B1_DESC, B1_I_DESCD "
	cQry1 += "FROM " + RetSqlName("SB1") + " "
	cQry1 += "WHERE B1_FILIAL IN '" + xFilial("SB1") + "' "
	cQry1 += "  AND B1_COD >= '" + MV_PAR05 + "' "
	cQry1 += "  AND B1_COD <= '" + MV_PAR06 + "' "
	If !Empty(MV_PAR07)
		cQry1 += "  AND B1_GRUPO IN " + FormatIn( MV_PAR07 , ";" )
	EndIf
	cQry1 += "  AND D_E_L_E_T_ = ' ' "

	If Select("TRBPRO") <> 0
		DBSelectArea("TRBPRO")
		DBCloseArea()
	EndIf

	TCQUERY cQry1 NEW ALIAS "TRBPRO"
		
	DBSelectArea("TRBPRO")
	TRBPRO->(DBGoTop())
		
	oReport:SetMeter(TRBPRO->(LastRec()))

	While !TRBPRO->(Eof())
	
		If oReport:Cancel()
			Exit
		EndIf

		oSection1:Init()
	
		oReport:IncMeter()
	
		IncProc("Imprimindo Filial " + AllTrim(TRBPRO->B1_COD) + " - " + AllTrim(TRBPRO->B1_DESC))

		oSection1:Cell("PRODUTO")	:SetValue(AllTrim(TRBPRO->B1_COD) + " - " + AllTrim(TRBPRO->B1_DESC))
		oSection1:PrintLine()

		oSection2:init()

		cQry2 := "SELECT D1.D1_FILIAL FILIAL, D1.D1_COD PRODUTO, D1.D1_DTDIGIT EMISSAO, D1.D1_DOC DOCUMENTO, D1.D1_SERIE SERIE, D1.D1_FORNECE CLIENTE, D1.D1_LOJA LOJA, D1.D1_LOCAL ARMAZEM, "
		cQry2 += "       Case "
        cQry2 += "		 WHEN D1.D1_TIPO <> 'D' THEN ( SELECT A2.A2_NREDUZ "
        cQry2 += "        		                       FROM " + RetSqlName("SA2") + " A2 "
        cQry2 += "                		               WHERE A2.D_E_L_E_T_ = ' ' "
        cQry2 += "                        		         AND D1.D1_FORNECE = A2.A2_COD "
        cQry2 += "                                		 AND D1.D1_LOJA = A2.A2_LOJA ) "
		cQry2 += "         Else ( SELECT A1.A1_NREDUZ "
        cQry2 += "		          FROM " + RetSqlName("SA1") + " A1 "
		cQry2 += "                WHERE A1.D_E_L_E_T_ = ' ' "
        cQry2 += "		          AND D1.D1_FORNECE = A1.A1_COD "
		cQry2 += "                  AND D1.D1_LOJA = A1.A1_LOJA ) END	NOMFANTASIA	, "
		cQry2 += "      D1.D1_UM UM, D1.D1_SEGUM SEGUM, "
		cQry2 += "      SUM(D1.D1_QUANT)	QUANT, "
		cQry2 += "      SUM(D1.D1_QTSEGUM)	QTSEGUM, "
		cQry2 += "      Case "
		cQry2 += "        WHEN SUM(D1.D1_QUANT) > 0 THEN DECODE( SUM(D1.D1_QUANT) , 0 , 0 , SUM(D1.D1_TOTAL) / SUM(D1.D1_QUANT) ) "
		cQry2 += "        Else 0 END PRCVEN, "
		cQry2 += "      SUM(D1.D1_TOTAL) TOTAL, "
		cQry2 += "      TO_CHAR(NULL) TM, "
		cQry2 += "      'A' TIPO, "
		cQry2 += "      B1.B1_I_DESCD DESCPROD, "
		cQry2 += "      Case "
		cQry2 += "        WHEN D1.D1_TIPO = 'N' And D1.D1_FORNECE = 'F00001' THEN 'Transferencia' "
		cQry2 += "        WHEN D1.D1_TIPO = 'N' And D1.D1_FORNECE <> 'F00001' THEN 'Outras Entradas' "
		cQry2 += "        WHEN D1.D1_TIPO = 'D' THEN 'Devolucao' "
		cQry2 += "        Else 'Outras Entradas' END	DESCMOVINT, "
		cQry2 += "      Case "
		cQry2 += "        WHEN D1.D1_TIPO = 'N' And D1.D1_FORNECE = 'F00001' THEN 'Transferencia' "
		cQry2 += "        WHEN D1.D1_TIPO = 'N' And D1.D1_FORNECE <> 'F00001' THEN 'Outras Entradas' "
		cQry2 += "        WHEN D1.D1_TIPO = 'D' THEN 'Devolucao' "
        cQry2 += "		Else 'Outras Entradas' END	TPNOTAENT "
		cQry2 += "FROM " + RetSqlName("SD1") + " D1 "
		cQry2 += "JOIN " + RetSqlName("SF4") + " F4 ON D1.D1_FILIAL = F4.F4_FILIAL AND D1.D1_TES = F4.F4_CODIGO "
		cQry2 += "JOIN (SELECT B1.B1_FILIAL,B1.B1_COD,B1.B1_I_DESCD,B1.B1_GRUPO,B1.B1_I_SUBGR,B1.B1_I_NIV4,B1.B1_I_NIV3,B1.B1_I_NIV2 "
		cQry2 += "      FROM " + RetSqlName("SB1") + " B1 "
		cQry2 += "      WHERE B1.D_E_L_E_T_ = ' ')  B1 ON B1.B1_FILIAL = '" + xFilial("SB1") + "' AND D1.D1_COD = B1.B1_COD "
		cQry2 += "WHERE D1.D_E_L_E_T_ = ' ' "
		cQry2 += "  AND F4.D_E_L_E_T_ = ' ' "
		cQry2 += "  AND F4.F4_ESTOQUE = 'S' "
		If !Empty(MV_PAR01)
			cQry2 += "  AND F4.F4_FILIAL IN " + FormatIn( MV_PAR01 , ";" )
		EndIf
		cQry2 += "  AND D1.D1_COD = '" + TRBPRO->B1_COD + "' "
		If !Empty(MV_PAR01)
			cQry2 += "  AND D1.D1_FILIAL IN " + FormatIn( MV_PAR01 , ";" )
		EndIf
		If !Empty(MV_PAR02)
			cQry2 += "  AND D1.D1_LOCAL = '" + MV_PAR02 + "' "
		EndIf
		cQry2 += "  AND D1.D1_DTDIGIT BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' "
		If !Empty(MV_PAR07)
			cQry2 += "  AND B1.B1_GRUPO IN " + FormatIn( MV_PAR07 , ";" )
		EndIf
		cQry2 += "GROUP BY D1.D1_FILIAL, D1.D1_COD, D1.D1_DTDIGIT, D1.D1_DOC, D1.D1_SERIE, D1.D1_FORNECE, D1.D1_LOJA, D1.D1_LOCAL, D1.D1_UM, D1.D1_SEGUM, B1.B1_I_DESCD, D1.D1_TIPO "
		cQry2 += "ORDER BY FILIAL, PRODUTO, EMISSAO "

		If Select("TRBNFE") <> 0
			DBSelectArea("TRBNFE")
			DBCloseArea()
		EndIf
	
		TCQUERY cQry2 NEW ALIAS "TRBNFE"
		
		DBSelectArea("TRBNFE")
		TRBNFE->(DBGoTop())
		
		oReport:SetMeter(TRBNFE->(LastRec()))
	
		While !TRBNFE->(Eof())
			oReport:IncMeter()

			IncProc("Imprimindo Documento " + AllTrim(TRBNFE->DOCUMENTO) + " - " + AllTrim(TRBNFE->SERIE))
			oSection2:Cell("DATADOC")		:SetValue(DToS(SToD(TRBNFE->EMISSAO)))
			oSection2:Cell("DOCUMENTO")		:SetValue(AllTrim(TRBNFE->DOCUMENTO) + " - " + AllTrim(TRBNFE->SERIE))
			oSection2:Cell("CLIENTE")		:SetValue(TRBNFE->CLIENTE + "/" + TRBNFE->LOJA + " " + TRBNFE->NOMFANTASIA)
			oSection2:Cell("QTDE1UM")		:SetValue(TRBNFE->QUANT)
			oSection2:Cell("1UNIDME")		:SetValue(TRBNFE->UM)
			oSection2:Cell("QTDE2UM")		:SetValue(TRBNFE->QTSEGUM)
			oSection2:Cell("2UNIDME")		:SetValue(TRBNFE->SEGUM)
			oSection2:Cell("PRCUNIT")		:SetValue(TRBNFE->PRCVEN)
			oSection2:Cell("VLRTOTAL")		:SetValue(TRBNFE->TOTAL)
			oSection2:PrintLine()
	
			TRBNFE->(DBSkip())
		End
		oSection2:Finish()

		oSection3:init()

		cQry3 := "SELECT D3.D3_FILIAL FILIAL, D3.D3_COD PRODUTO, D3.D3_EMISSAO EMISSAO, TO_CHAR(NULL) DOCUMENTO, TO_CHAR(NULL) SERIE, TO_CHAR(NULL) CLIENTE, TO_CHAR(NULL) LOJA, D3.D3_LOCAL ARMAZEM, "
		cQry3 += "       TO_CHAR(NULL) NOMFANTASIA, D3.D3_UM UM, D3.D3_SEGUM SEGUM, SUM(D3.D3_QUANT) QUANT, SUM(D3.D3_QTSEGUM) QTSEGUM, DECODE( SUM(D3.D3_QUANT), 0, 0, "
		cQry3 += "       ( SUM(D3.D3_CUSTO1) / SUM(D3.D3_QUANT) ) ) PRCVEN, SUM( D3.D3_CUSTO1) TOTAL, D3.D3_TM TM, 'B' TIPO, B1.B1_I_DESCD DESCPROD, "
		cQry3 += "       Case "
		cQry3 += "         WHEN D3_TM IN ('001','003','004') THEN ' Producao' "
		cQry3 += "         WHEN D3_TM = '499' THEN 'Entrada Transf.Perda' "
		cQry3 += "         Else 'Outras Entradas' END DESCMOVINT, "
		cQry3 += "       TO_CHAR(NULL) TPNOTAENT "
		cQry3 += "FROM " + RetSqlName("SD3") + " D3 "
		cQry3 += "JOIN (SELECT B1.B1_FILIAL,B1.B1_COD,B1.B1_I_DESCD,B1.B1_GRUPO,B1.B1_I_SUBGR,B1.B1_I_NIV4,B1.B1_I_NIV3,B1.B1_I_NIV2 "
		cQry3 += "      FROM " + RetSqlName("SB1") + " B1 "
		cQry3 += "      WHERE B1.D_E_L_E_T_ = ' ')  B1 ON B1.B1_FILIAL = '" + xFilial("SB1") + "' AND D3.D3_COD = B1.B1_COD "
		cQry3 += "WHERE D3.D_E_L_E_T_ = ' ' "
		cQry3 += "  AND D3.D3_TM < '500' "
		cQry3 += "  AND D3_ESTORNO <> 'S' "
		cQry3 += "  AND D3_COD = '" + TRBPRO->B1_COD + "' "
		If !Empty(MV_PAR01)
			cQry3 += "  AND D3.D3_FILIAL IN " + FormatIn( MV_PAR01 , ";" )
		EndIf
		If !Empty(MV_PAR02)
			cQry3 += "  AND D3.D3_LOCAL = '" + MV_PAR02 + "' "
		EndIf
		cQry3 += "  AND D3.D3_EMISSAO BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' "
		If !Empty(MV_PAR07)
			cQry3 += "  AND B1.B1_GRUPO IN " + FormatIn( MV_PAR07 , ";" )
		EndIf
		cQry3 += "GROUP BY D3.D3_FILIAL, D3.D3_COD, D3.D3_EMISSAO, D3.D3_LOCAL, D3.D3_TM, D3.D3_UM, D3.D3_SEGUM, B1.B1_I_DESCD "
		cQry3 += "ORDER BY FILIAL, PRODUTO , TIPO , EMISSAO , TPNOTAENT , DOCUMENTO "

		If Select("TRBMVE") <> 0
			DBSelectArea("TRBMVE")
			DBCloseArea()
		EndIf
	
		TCQUERY cQry3 NEW ALIAS "TRBMVE"
		
		DBSelectArea("TRBMVE")
		TRBMVE->(DBGoTop())
		
		oReport:SetMeter(TRBMVE->(LastRec()))
	
		While !TRBMVE->(Eof())
			oReport:IncMeter()

			IncProc("Imprimindo Movimentação " + AllTrim(TRBMVE->DESCMOVINT))
			oSection3:Cell("DATADOC")		:SetValue(DToC(SToD(TRBMVE->EMISSAO)))
			oSection3:Cell("TPMOVIM")		:SetValue(AllTrim(TRBMVE->DESCMOVINT))
			oSection3:Cell("QTDE1UM")		:SetValue(TRBMVE->QUANT)
			oSection3:Cell("1UNIDME")		:SetValue(TRBMVE->UM)
			oSection3:Cell("QTDE2UM")		:SetValue(TRBMVE->QTSEGUM)
			oSection3:Cell("2UNIDME")		:SetValue(TRBMVE->SEGUM)
			oSection3:Cell("PRCUNIT")		:SetValue(TRBMVE->PRCVEN)
			oSection3:Cell("VLRTOTAL")		:SetValue(TRBMVE->TOTAL)
			oSection3:PrintLine()
	
			TRBMVE->(DBSkip())
		End

		oSection3:Finish()
		
		oSection4:init()

		cQry4 := "SELECT ZE2_FILIAL, ZE2_PRODUT, ZE2_DESCRI, ZE2_DTCONT, ZE2_PALCPR, ZE2_PALCEA, ZE2_PALAVA, ZE2_PALVAZ, ZE2_PALTOT, ZE2_MEDCON, ZE2_QTDALT, ZE2_PALSUJ, ZE2_AUTEST "
		cQry4 += "FROM " + RetSqlName("ZE2") + " "
		cQry4 += "WHERE D_E_L_E_T_ = ' ' "
		If !Empty(MV_PAR01)
			cQry4 += "  AND ZE2_FILIAL IN " + FormatIn( MV_PAR01 , ";" )
		EndIf
		cQry4 += "  AND ZE2_PRODUT = '" + TRBPRO->B1_COD + "' "
		cQry4 += "  AND ZE2_DTCONT BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' "
		cQry4 += "ORDER BY ZE2_FILIAL , ZE2_PRODUT , ZE2_DTCONT "

		If Select("TRBPAL") <> 0
			DBSelectArea("TRBPAL")
			DBCloseArea()
		EndIf
	
		TCQUERY cQry4 NEW ALIAS "TRBPAL"
		
		DBSelectArea("TRBPAL")
		TRBPAL->(DBGoTop())
		
		oReport:SetMeter(TRBPAL->(LastRec()))
	
		While !TRBPAL->(Eof())
			oReport:IncMeter()

			oSection4:Cell("DTINCL")		:SetValue(DToC(SToD(TRBPAL->ZE2_DTCONT)))
			oSection4:Cell("PALCPR")		:SetValue(TRBPAL->ZE2_PALCPR)
			oSection4:Cell("PALCEA")		:SetValue(TRBPAL->ZE2_PALCEA)
			oSection4:Cell("PALAVA")		:SetValue(TRBPAL->ZE2_PALAVA)
			oSection4:Cell("PALVAZ")		:SetValue(TRBPAL->ZE2_PALVAZ)
			oSection4:Cell("PALSUJ")		:SetValue(TRBPAL->ZE2_PALSUJ)
			oSection4:Cell("PALTOT")		:SetValue(TRBPAL->ZE2_PALTOT)
			oSection4:Cell("MEDCON")		:SetValue(TRBPAL->ZE2_MEDCON)
			oSection4:Cell("AUTEST")		:SetValue(TRBPAL->ZE2_AUTEST)

			oSection4:PrintLine()
	
			TRBPAL->(DBSkip())
		End

		oSection4:Finish()

		TRBPRO->(DBSkip())
	End
	
	oSection1:Finish()
	oSection1:Enable()
	oSection2:Enable()
	oSection3:Enable()
	oSection4:Enable()

ElseIf MV_PAR08 == 2		//Saídas

	cQry1 := "SELECT B1_COD, B1_GRUPO, B1_DESC, B1_I_DESCD "
	cQry1 += "FROM " + RetSqlName("SB1") + " "
	cQry1 += "WHERE B1_FILIAL = '" + xFilial("SB1") + "' "
	cQry1 += "  AND B1_COD >= '" + MV_PAR05 + "' "
	cQry1 += "  AND B1_COD <= '" + MV_PAR06 + "' "
	If !Empty(MV_PAR07)
		cQry1 += "  AND B1_GRUPO IN " + FormatIn( MV_PAR07 , ";" )
	EndIf
	cQry1 += "  AND D_E_L_E_T_ = ' ' "

	If Select("TRBPRO") <> 0
		DBSelectArea("TRBPRO")
		DBCloseArea()
	EndIf

	TCQUERY cQry1 NEW ALIAS "TRBPRO"
		
	DBSelectArea("TRBPRO")
	TRBPRO->(DBGoTop())
		
	oReport:SetMeter(TRBPRO->(LastRec()))

	While !TRBPRO->(Eof())
	
		If oReport:Cancel()
			Exit
		EndIf

		oSection1:Init()
	
		oReport:IncMeter()
	
		IncProc("Imprimindo Filial " + AllTrim(TRBPRO->B1_COD) + " - " + AllTrim(TRBPRO->B1_DESC))

		oSection1:Cell("PRODUTO")	:SetValue(AllTrim(TRBPRO->B1_COD) + " - " + AllTrim(TRBPRO->B1_DESC))
		oSection1:PrintLine()

		oSection2:init()

		cQry2 := "SELECT D2.D2_FILIAL FILIAL, D2.D2_COD PRODUTO, D2.D2_EMISSAO	EMISSAO, D2.D2_DOC DOCUMENTO, D2.D2_SERIE SERIE, D2.D2_CLIENTE CLIENTE, D2.D2_LOJA LOJA, D2.D2_LOCAL ARMAZEM, "
		cQry2 += "       Case "
		cQry2 += "         WHEN F2.F2_TIPO IN ('D','B') THEN ( SELECT A2.A2_NREDUZ "
		cQry2 += "                                             FROM " + RetSqlName("SA2") + " A2 "
		cQry2 += "                                             WHERE A2.A2_FILIAL = '" + xFilial("SA2") + "' "
		cQry2 += "                                             AND A2.D_E_L_E_T_ = ' ' "
		cQry2 += "                                             AND D2.D2_CLIENTE = A2.A2_COD "
		cQry2 += "                                             AND D2.D2_LOJA = A2.A2_LOJA ) "
		cQry2 += "         Else ( SELECT A1.A1_NREDUZ "
		cQry2 += "                FROM " + RetSqlName("SA1") + " A1 "
		cQry2 += "                WHERE A1.A1_FILIAL = '" + xFilial("SA1") + "' "
		cQry2 += "                  AND A1.D_E_L_E_T_ = ' ' "
		cQry2 += "                  AND D2.D2_CLIENTE = A1.A1_COD "
		cQry2 += "                  AND D2.D2_LOJA = A1.A1_LOJA ) END NOMFANTASIA, "
		cQry2 += "       D2.D2_UM UM, D2.D2_SEGUM SEGUM, SUM(D2.D2_QUANT)	QUANT, SUM(D2.D2_QTSEGUM)	QTSEGUM, DECODE( SUM(D2.D2_QUANT), 0, 0, "
		cQry2 += "       SUM(D2.D2_TOTAL) / SUM(D2.D2_QUANT) ) PRCVEN, SUM(D2.D2_TOTAL)	TOTAL, TO_CHAR(NULL) TM, 'A' TIPO, B1.B1_I_DESCD DESCPROD, "
		cQry2 += "       'SAIDA POR NF' DESCMOVINT, TO_CHAR(NULL) TPNOTAENT	"
		cQry2 += "FROM " + RetSqlName("SD2") + " D2 "
		cQry2 += "JOIN (SELECT F2.F2_FILIAL, F2.F2_DOC, F2.F2_CLIENTE, F2.F2_LOJA, F2.F2_TIPO "
		cQry2 += "      FROM " + RetSqlName("SF2") + " F2 "
		cQry2 += "      WHERE F2.D_E_L_E_T_ = ' ') F2 ON F2.F2_FILIAL = D2.D2_FILIAL AND F2.F2_DOC = D2.D2_DOC AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA = D2.D2_LOJA "
		cQry2 += "JOIN (SELECT F4.F4_FILIAL,F4.F4_CODIGO,F4.F4_ESTOQUE "
		cQry2 += "      FROM " + RetSqlName("SF4") + " F4 "
		cQry2 += "      WHERE F4.D_E_L_E_T_ = ' ') F4 ON D2.D2_FILIAL = F4.F4_FILIAL AND D2.D2_TES = F4.F4_CODIGO "
		cQry2 += "JOIN (SELECT B1.B1_FILIAL,B1.B1_COD,B1.B1_I_DESCD,B1.B1_GRUPO,B1.B1_I_SUBGR,B1.B1_I_NIV4,B1.B1_I_NIV3,B1.B1_I_NIV2 "
		cQry2 += "      FROM " + RetSqlName("SB1") + " B1 "
		cQry2 += "      WHERE B1.D_E_L_E_T_ = ' ') B1 ON B1.B1_FILIAL = '" + xFilial("SB1") + "' AND D2.D2_COD = B1.B1_COD "
		cQry2 += "WHERE D2.D_E_L_E_T_ = ' ' "
		cQry2 += "  AND F4.F4_ESTOQUE = 'S' "
		cQry2 += "  AND D2.D2_COD = '" + TRBPRO->B1_COD + "' "
		If !Empty(MV_PAR01)
			cQry2 += "  AND D2.D2_FILIAL IN " + FormatIn( MV_PAR01 , ";" )
			cQry2 += "  AND F4.F4_FILIAL IN " + FormatIn( MV_PAR01 , ";" )
		EndIf
		If !Empty(MV_PAR02)
			cQry2 += "  AND D2.D2_LOCAL = '" + MV_PAR02 + "' "
		EndIf
		cQry2 += "  AND D2.D2_EMISSAO BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' "
		If !Empty(MV_PAR07)
			cQry2 += "  AND B1.B1_GRUPO IN " + FormatIn( MV_PAR07 , ";" )
		EndIf
		cQry2 += "GROUP BY D2.D2_FILIAL,D2.D2_COD,D2.D2_EMISSAO,D2.D2_DOC,D2.D2_SERIE,D2.D2_CLIENTE,D2.D2_LOJA,D2.D2_LOCAL,D2.D2_UM,D2.D2_SEGUM,B1.B1_I_DESCD,F2.F2_TIPO "
		cQry2 += "ORDER BY FILIAL, PRODUTO, EMISSAO "

		If Select("TRBNFS") <> 0
			DBSelectArea("TRBNFS")
			DBCloseArea()
		EndIf
	
		TCQUERY cQry2 NEW ALIAS "TRBNFS"
		
		DBSelectArea("TRBNFS")
		TRBNFS->(DBGoTop())
		
		oReport:SetMeter(TRBNFS->(LastRec()))
	
		While !TRBNFS->(Eof())
			oReport:IncMeter()

			IncProc("Imprimindo Documento " + AllTrim(TRBNFS->DOCUMENTO) + " - " + AllTrim(TRBNFS->SERIE))
			oSection2:Cell("DATADOC")		:SetValue(DToC(SToD(TRBNFS->EMISSAO)))
			oSection2:Cell("DOCUMENTO")		:SetValue(AllTrim(TRBNFS->DOCUMENTO) + " - " + AllTrim(TRBNFS->SERIE))
			oSection2:Cell("CLIENTE")		:SetValue(TRBNFS->CLIENTE + "/" + TRBNFS->LOJA + " " + TRBNFS->NOMFANTASIA)
			oSection2:Cell("QTDE1UM")		:SetValue(TRBNFS->QUANT)
			oSection2:Cell("1UNIDME")		:SetValue(TRBNFS->UM)
			oSection2:Cell("QTDE2UM")		:SetValue(TRBNFS->QTSEGUM)
			oSection2:Cell("2UNIDME")		:SetValue(TRBNFS->SEGUM)
			oSection2:Cell("PRCUNIT")		:SetValue(TRBNFS->PRCVEN)
			oSection2:Cell("VLRTOTAL")		:SetValue(TRBNFS->TOTAL)
			oSection2:PrintLine()
	
			TRBNFS->(DBSkip())
		End

		oSection2:Finish()

		oSection3:init()

		cQry3 := "SELECT D3.D3_FILIAL FILIAL, D3.D3_COD PRODUTO, D3.D3_EMISSAO EMISSAO, TO_CHAR(NULL) DOCUMENTO, TO_CHAR(NULL)	SERIE, TO_CHAR(NULL) CLIENTE, TO_CHAR(NULL) LOJA, D3.D3_LOCAL ARMAZEM, "
		cQry3 += "       TO_CHAR(NULL) NOMFANTASIA, D3.D3_UM UM, D3.D3_SEGUM SEGUM, SUM(D3.D3_QUANT) QUANT, SUM(D3.D3_QTSEGUM) QTSEGUM,	"
		cQry3 += "       DECODE( SUM(D3.D3_QUANT), 0, 0, ( SUM(D3.D3_CUSTO1) / SUM(D3.D3_QUANT) ) ) PRCVEN, "
		cQry3 += "       SUM(D3.D3_CUSTO1) TOTAL, D3.D3_TM TM, 'B' TIPO, B1.B1_I_DESCD DESCPROD, "
		cQry3 += "       Case "
		cQry3 += "         WHEN D3_TM = '803' THEN 'Consumo Interno' "
		cQry3 += "         WHEN D3_TM = '804' THEN 'Faltas/Descarte' "
		cQry3 += "         WHEN D3_TM = '999' THEN 'Transf.Armazem Perda' "
		cQry3 += "         Else 'Outras Saidas' END DESCMOVINT, "
		cQry3 += "      TO_CHAR(NULL) TPNOTAENT "
		cQry3 += "FROM " + RetSqlName("SD3") + " D3 "
		cQry3 += "JOIN (SELECT B1.B1_FILIAL,B1.B1_COD,B1.B1_I_DESCD,B1.B1_GRUPO,B1.B1_I_SUBGR,B1.B1_I_NIV4,B1.B1_I_NIV3,B1.B1_I_NIV2 "
		cQry3 += "      FROM " + RetSqlName("SB1") + " B1 "
		cQry3 += "		WHERE B1.D_E_L_E_T_ = ' ')  B1 ON B1.B1_FILIAL = '" + xFilial("SB1") + "' AND D3.D3_COD = B1.B1_COD "
		cQry3 += "WHERE D3.D_E_L_E_T_ = ' ' "
		cQry3 += "  AND D3.D3_COD = '" + TRBPRO->B1_COD + "' "
		cQry3 += "  AND D3.D3_TM > '500' "
		cQry3 += "  AND D3_ESTORNO <> 'S' "
		If !Empty(MV_PAR01)
			cQry3 += "  AND D3.D3_FILIAL IN " + FormatIn( MV_PAR01 , ";" )
		EndIf
		If !Empty(MV_PAR02)
			cQry3 += "  AND D3.D3_LOCAL = '" + MV_PAR02 + "' "
		EndIf
		cQry3 += "  AND D3.D3_EMISSAO BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' "
		If !Empty(MV_PAR07)
			cQry3 += "  AND B1.B1_GRUPO IN " + FormatIn( MV_PAR07 , ";" )
		EndIf
		cQry3 += "GROUP BY D3.D3_FILIAL,D3.D3_COD,D3.D3_EMISSAO,D3.D3_LOCAL,D3.D3_TM,D3.D3_UM,D3.D3_SEGUM,B1.B1_I_DESCD "
		cQry3 += "ORDER BY FILIAL, PRODUTO , TIPO , EMISSAO , DOCUMENTO , TM "

		If Select("TRBMVS") <> 0
			DBSelectArea("TRBMVS")
			DBCloseArea()
		EndIf
	
		TCQUERY cQry3 NEW ALIAS "TRBMVS"
		
		DBSelectArea("TRBMVS")
		TRBMVS->(DBGoTop())
		
		oReport:SetMeter(TRBMVS->(LastRec()))
	
		While !TRBMVS->(Eof())
			oReport:IncMeter()

			IncProc("Imprimindo Movimentação " + AllTrim(TRBMVS->DESCMOVINT))
			oSection3:Cell("DATADOC")		:SetValue(DToC(SToD(TRBMVS->EMISSAO)))
			oSection3:Cell("TPMOVIM")		:SetValue(AllTrim(TRBMVS->DESCMOVINT))
			oSection3:Cell("QTDE1UM")		:SetValue(TRBMVS->QUANT)
			oSection3:Cell("1UNIDME")		:SetValue(TRBMVS->UM)
			oSection3:Cell("QTDE2UM")		:SetValue(TRBMVS->QTSEGUM)
			oSection3:Cell("2UNIDME")		:SetValue(TRBMVS->SEGUM)
			oSection3:Cell("PRCUNIT")		:SetValue(TRBMVS->PRCVEN)
			oSection3:Cell("VLRTOTAL")		:SetValue(TRBMVS->TOTAL)

			oSection3:PrintLine()
	
			TRBMVS->(DBSkip())
		End

		oSection3:Finish()

		oSection4:init()

		cQry4 := "SELECT ZE2_FILIAL, ZE2_PRODUT, ZE2_DESCRI, ZE2_DTCONT, ZE2_PALCPR, ZE2_PALCEA, ZE2_PALAVA, ZE2_PALVAZ, ZE2_PALTOT, ZE2_MEDCON, ZE2_QTDALT, ZE2_PALSUJ, ZE2_AUTEST "
		cQry4 += "FROM " + RetSqlName("ZE2") + " "
		cQry4 += "WHERE D_E_L_E_T_ = ' ' "
		If !Empty(MV_PAR01)
			cQry4 += "  AND ZE2_FILIAL IN " + FormatIn( MV_PAR01 , ";" )
		EndIf
		cQry4 += "  AND ZE2_PRODUT = '" + TRBPRO->B1_COD + "' "
		cQry4 += "  AND ZE2_DTCONT BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' "
		cQry4 += "ORDER BY ZE2_FILIAL , ZE2_PRODUT , ZE2_DTCONT "

		If Select("TRBPAL") <> 0
			DBSelectArea("TRBPAL")
			DBCloseArea()
		EndIf
	
		TCQUERY cQry4 NEW ALIAS "TRBPAL"
		
		DBSelectArea("TRBPAL")
		TRBPAL->(DBGoTop())
		
		oReport:SetMeter(TRBPAL->(LastRec()))
	
		While !TRBPAL->(Eof())
			oReport:IncMeter()

			oSection4:Cell("DTINCL")		:SetValue(DToC(SToD(TRBPAL->ZE2_DTCONT)))
			oSection4:Cell("PALCPR")		:SetValue(TRBPAL->ZE2_PALCPR)
			oSection4:Cell("PALCEA")		:SetValue(TRBPAL->ZE2_PALCEA)
			oSection4:Cell("PALAVA")		:SetValue(TRBPAL->ZE2_PALAVA)
			oSection4:Cell("PALVAZ")		:SetValue(TRBPAL->ZE2_PALVAZ)
			oSection4:Cell("PALSUJ")		:SetValue(TRBPAL->ZE2_PALSUJ)
			oSection4:Cell("PALTOT")		:SetValue(TRBPAL->ZE2_PALTOT)
			oSection4:Cell("MEDCON")		:SetValue(TRBPAL->ZE2_MEDCON)
			oSection4:Cell("AUTEST")		:SetValue(TRBPAL->ZE2_AUTEST)

			oSection4:PrintLine()
	
			TRBPAL->(DBSkip())
		End

		oSection4:Finish()

		TRBPRO->(DBSkip())
	End
	oSection1:Finish()
	oSection1:Enable()
	oSection2:Enable()
	oSection3:Enable()
	oSection4:Enable()

Else			//Ambas

	oSection4 := oReport:Section(1):Section(3)
	oSection5 := oReport:Section(1):Section(4)
	oSection6 := oReport:Section(1):Section(5)
	oSection7 := oReport:Section(1):Section(6)

	cQry1 := "SELECT B1_COD, B1_GRUPO, B1_DESC, B1_I_DESCD "
	cQry1 += "FROM " + RetSqlName("SB1") + " "
	cQry1 += "WHERE B1_FILIAL = '" + xFilial("SB1") + "' "
	cQry1 += "  AND B1_COD >= '" + MV_PAR05 + "' "
	cQry1 += "  AND B1_COD <= '" + MV_PAR06 + "' "
	If !Empty(MV_PAR07)
		cQry1 += "  AND B1_GRUPO IN " + FormatIn( MV_PAR07 , ";" )
	EndIf
	cQry1 += "  AND D_E_L_E_T_ = ' ' "

	If Select("TRBPRO") <> 0
		DBSelectArea("TRBPRO")
		DBCloseArea()
	EndIf

	TCQUERY cQry1 NEW ALIAS "TRBPRO"
		
	DBSelectArea("TRBPRO")
	TRBPRO->(DBGoTop())

	//aDados                      
	//[1] Produto                 
	//[2] Data                    
	//[3] Estoque Inicial         
	//[4] Entradas Fiscais        
	//[5] Entradas Internas       
	//[6] Saídas Fiscais          
	//[7] Saídas Internas         
	//[8] Estoque Atual           
	//[9] Saldo Atual             
	//[10] Pallet c/ Prod         
	//[11] Pallet Emb/Alm         
	//[12] Pallet Avaria          
	//[13] Pallet Vazio           
	//[14] Pallet Sujo            
	//[15] Total Pallets          
	//[16] Média Consumo Dias     
	//[17] Autonomia Estoque Dias 
	//[18] descarte de pallets    
	//[19] qtde peças
	

	dData := MV_PAR03

	For nI := 1 To Len(aDados)
		aDados[nI] := {}
		For nJ := 1 To nDias
			If nI == 1
				aAdd(aDados[nI],TRBPRO->B1_COD)
			ElseIf nI == 2
				aAdd(aDados[nI],dData)
				dData := dData + 1
			Else
				aAdd(aDados[nI], 0)
			EndIf
		Next nJ
	Next nI

	oReport:SetMeter(TRBPRO->(LastRec()))

	While !TRBPRO->(Eof())
	
		If oReport:Cancel()
			Exit
		EndIf

		aAdd(aResum,{TRBPRO->B1_COD,0,0,0,0,0,0,0,CtoD("//")})

		oSection1:Init()
	
		oReport:IncMeter()
	
		IncProc("Imprimindo Filial " + AllTrim(TRBPRO->B1_COD) + " - " + AllTrim(TRBPRO->B1_DESC))

		oSection1:Cell("PRODUTO")	:SetValue(AllTrim(TRBPRO->B1_COD) + " - " + AllTrim(TRBPRO->B1_DESC))
		oSection1:PrintLine()

		oSection2:init()

		cQry2 := "SELECT D1.D1_FILIAL FILIAL, D1.D1_COD PRODUTO, D1.D1_DTDIGIT EMISSAO, D1.D1_DOC DOCUMENTO, D1.D1_SERIE SERIE, D1.D1_FORNECE CLIENTE, D1.D1_LOJA LOJA, D1.D1_LOCAL ARMAZEM, "
		cQry2 += "       Case "
        cQry2 += "		 WHEN D1.D1_TIPO <> 'D' THEN ( SELECT A2.A2_NREDUZ "
        cQry2 += "        		                       FROM " + RetSqlName("SA2") + " A2 "
        cQry2 += "                		               WHERE A2.D_E_L_E_T_ = ' ' "
        cQry2 += "                        		         AND D1.D1_FORNECE = A2.A2_COD "
        cQry2 += "                                		 AND D1.D1_LOJA = A2.A2_LOJA ) "
		cQry2 += "         Else ( SELECT A1.A1_NREDUZ "
        cQry2 += "		          FROM " + RetSqlName("SA1") + " A1 "
		cQry2 += "                WHERE A1.D_E_L_E_T_ = ' ' "
        cQry2 += "		          AND D1.D1_FORNECE = A1.A1_COD "
		cQry2 += "                  AND D1.D1_LOJA = A1.A1_LOJA ) END	NOMFANTASIA	, "
		cQry2 += "      D1.D1_UM UM, D1.D1_SEGUM SEGUM, "
		cQry2 += "      SUM(D1.D1_QUANT)	QUANT, "
		cQry2 += "      SUM(D1.D1_QTSEGUM)	QTSEGUM, "
		cQry2 += "      Case "
		cQry2 += "        WHEN SUM(D1.D1_QUANT) > 0 THEN DECODE( SUM(D1.D1_QUANT) , 0 , 0 , SUM(D1.D1_TOTAL) / SUM(D1.D1_QUANT) ) "
		cQry2 += "        Else 0 END PRCVEN, "
		cQry2 += "      SUM(D1.D1_TOTAL) TOTAL, "
		cQry2 += "      TO_CHAR(NULL) TM, "
		cQry2 += "      'A' TIPO, "
		cQry2 += "      B1.B1_I_DESCD DESCPROD, "
		cQry2 += "      Case "
		cQry2 += "        WHEN D1.D1_TIPO = 'N' And D1.D1_FORNECE = 'F00001' THEN 'Transferencia' "
		cQry2 += "        WHEN D1.D1_TIPO = 'N' And D1.D1_FORNECE <> 'F00001' THEN 'Outras Entradas' "
		cQry2 += "        WHEN D1.D1_TIPO = 'D' THEN 'Devolucao' "
		cQry2 += "        Else 'Outras Entradas' END	DESCMOVINT, "
		cQry2 += "      Case "
		cQry2 += "        WHEN D1.D1_TIPO = 'N' And D1.D1_FORNECE = 'F00001' THEN 'Transferencia' "
		cQry2 += "        WHEN D1.D1_TIPO = 'N' And D1.D1_FORNECE <> 'F00001' THEN 'Outras Entradas' "
		cQry2 += "        WHEN D1.D1_TIPO = 'D' THEN 'Devolucao' "
        cQry2 += "		Else 'Outras Entradas' END	TPNOTAENT "
		cQry2 += "FROM " + RetSqlName("SD1") + " D1 "
		cQry2 += "JOIN " + RetSqlName("SF4") + " F4 ON D1.D1_FILIAL = F4.F4_FILIAL AND D1.D1_TES = F4.F4_CODIGO "
		cQry2 += "JOIN (SELECT B1.B1_FILIAL,B1.B1_COD,B1.B1_I_DESCD,B1.B1_GRUPO,B1.B1_I_SUBGR,B1.B1_I_NIV4,B1.B1_I_NIV3,B1.B1_I_NIV2 "
		cQry2 += "      FROM " + RetSqlName("SB1") + " B1 "
		cQry2 += "      WHERE B1.D_E_L_E_T_ = ' ')  B1 ON B1.B1_FILIAL = '" + xFilial("SB1") + "' AND D1.D1_COD = B1.B1_COD "
		cQry2 += "WHERE D1.D_E_L_E_T_ = ' ' "
		cQry2 += "  AND F4.D_E_L_E_T_ = ' ' "
		cQry2 += "  AND F4.F4_ESTOQUE = 'S' "
		If !Empty(MV_PAR01)
			cQry2 += "  AND F4.F4_FILIAL IN " + FormatIn( MV_PAR01 , ";" )
		EndIf
		cQry2 += "  AND D1.D1_COD = '" + TRBPRO->B1_COD + "' "
		If !Empty(MV_PAR01)
			cQry2 += "  AND D1.D1_FILIAL IN " + FormatIn( MV_PAR01 , ";" )
		EndIf
		If !Empty(MV_PAR02)
			cQry2 += "  AND D1.D1_LOCAL = '" + MV_PAR02 + "' "
		EndIf
		cQry2 += "  AND D1.D1_DTDIGIT BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' "
		If !Empty(MV_PAR07)
			cQry2 += "  AND B1.B1_GRUPO IN " + FormatIn( MV_PAR07 , ";" )
		EndIf
		cQry2 += "GROUP BY D1.D1_FILIAL, D1.D1_COD, D1.D1_DTDIGIT, D1.D1_DOC, D1.D1_SERIE, D1.D1_FORNECE, D1.D1_LOJA, D1.D1_LOCAL, D1.D1_UM, D1.D1_SEGUM, B1.B1_I_DESCD, D1.D1_TIPO "
		cQry2 += "ORDER BY FILIAL, PRODUTO, EMISSAO "

		If Select("TRBNFE") <> 0
			DBSelectArea("TRBNFE")
			DBCloseArea()
		EndIf
	
		TCQUERY cQry2 NEW ALIAS "TRBNFE"
		
		DBSelectArea("TRBNFE")
		TRBNFE->(DBGoTop())
		
		oReport:SetMeter(TRBNFE->(LastRec()))
	
		While !TRBNFE->(Eof())
			oReport:IncMeter()

			IncProc("Imprimindo Documento " + AllTrim(TRBNFE->DOCUMENTO) + " - " + AllTrim(TRBNFE->SERIE))
			oSection2:Cell("DATADOC")		:SetValue(DToC(SToD(TRBNFE->EMISSAO)))
			oSection2:Cell("DOCUMENTO")		:SetValue(AllTrim(TRBNFE->DOCUMENTO) + " - " + AllTrim(TRBNFE->SERIE))
			oSection2:Cell("CLIENTE")		:SetValue(TRBNFE->CLIENTE + "/" + TRBNFE->LOJA + " " + TRBNFE->NOMFANTASIA)
			oSection2:Cell("QTDE1UM")		:SetValue(TRBNFE->QUANT)
			oSection2:Cell("1UNIDME")		:SetValue(TRBNFE->UM)
			oSection2:Cell("QTDE2UM")		:SetValue(TRBNFE->QTSEGUM)
			oSection2:Cell("2UNIDME")		:SetValue(TRBNFE->SEGUM)
			oSection2:Cell("PRCUNIT")		:SetValue(TRBNFE->PRCVEN)
			oSection2:Cell("VLRTOTAL")		:SetValue(TRBNFE->TOTAL)

			oSection2:PrintLine()

			aResum[Len(aResum)][2] += TRBNFE->QUANT

			DBSelectArea("ZE2")
			DBSetOrder(1)
			If DBSeek(TRBNFE->FILIAL + TRBNFE->PRODUTO + DToS(MV_PAR04))
				aResum[Len(aResum)][6] := ZE2->ZE2_PALTOT
				aResum[Len(aResum)][7] := ZE2->ZE2_MEDCON
				aResum[Len(aResum)][8] := ZE2->ZE2_AUTEST
				aResum[Len(aResum)][9] := ZE2->ZE2_DTCONT
			EndIf

			aDados[4][aScan(aDados[2],SToD(TRBNFE->EMISSAO))] += TRBNFE->QUANT
			aDados[1][aScan(aDados[2],SToD(TRBNFE->EMISSAO))] := TRBPRO->B1_COD

			TRBNFE->(DBSkip())
		End

		oSection2:Finish()

		oSection3:init()

		cQry3 := "SELECT D3.D3_FILIAL FILIAL, D3.D3_COD PRODUTO, D3.D3_EMISSAO EMISSAO, TO_CHAR(NULL) DOCUMENTO, TO_CHAR(NULL) SERIE, TO_CHAR(NULL) CLIENTE, TO_CHAR(NULL) LOJA, D3.D3_LOCAL ARMAZEM, "
		cQry3 += "       TO_CHAR(NULL) NOMFANTASIA, D3.D3_UM UM, D3.D3_SEGUM SEGUM, SUM(D3.D3_QUANT) QUANT, SUM(D3.D3_QTSEGUM) QTSEGUM, DECODE( SUM(D3.D3_QUANT), 0, 0, "
		cQry3 += "       ( SUM(D3.D3_CUSTO1) / SUM(D3.D3_QUANT) ) ) PRCVEN, SUM( D3.D3_CUSTO1) TOTAL, D3.D3_TM TM, 'B' TIPO, B1.B1_I_DESCD DESCPROD, "
		cQry3 += "       Case "
		cQry3 += "         WHEN D3_TM IN ('001','003','004') THEN ' Producao' "
		cQry3 += "         WHEN D3_TM = '499' THEN 'Entrada Transf.Perda' "
		cQry3 += "         Else 'Outras Entradas' END DESCMOVINT, "
		cQry3 += "       TO_CHAR(NULL) TPNOTAENT "
		cQry3 += "FROM " + RetSqlName("SD3") + " D3 "
		cQry3 += "JOIN (SELECT B1.B1_FILIAL,B1.B1_COD,B1.B1_I_DESCD,B1.B1_GRUPO,B1.B1_I_SUBGR,B1.B1_I_NIV4,B1.B1_I_NIV3,B1.B1_I_NIV2 "
		cQry3 += "      FROM " + RetSqlName("SB1") + " B1 "
		cQry3 += "      WHERE B1.D_E_L_E_T_ = ' ')  B1 ON B1.B1_FILIAL = '" + xFilial("SB1") + "' AND D3.D3_COD = B1.B1_COD "
		cQry3 += "WHERE D3.D_E_L_E_T_ = ' ' "
		cQry3 += "  AND D3.D3_TM < '500' "
		cQry3 += "  AND D3_ESTORNO <> 'S' "
		cQry3 += "  AND D3_COD = '" + TRBPRO->B1_COD + "' "
		If !Empty(MV_PAR01)
			cQry3 += "  AND D3.D3_FILIAL IN " + FormatIn( MV_PAR01 , ";" )
		EndIf
		If !Empty(MV_PAR02)
			cQry3 += "  AND D3.D3_LOCAL = '" + MV_PAR02 + "' "
		EndIf
		cQry3 += "  AND D3.D3_EMISSAO BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' "
		If !Empty(MV_PAR07)
			cQry3 += "  AND B1.B1_GRUPO IN " + FormatIn( MV_PAR07 , ";" )
		EndIf
		cQry3 += "GROUP BY D3.D3_FILIAL, D3.D3_COD, D3.D3_EMISSAO, D3.D3_LOCAL, D3.D3_TM, D3.D3_UM, D3.D3_SEGUM, B1.B1_I_DESCD "
		cQry3 += "ORDER BY FILIAL, PRODUTO , TIPO , EMISSAO , TPNOTAENT , DOCUMENTO "

		If Select("TRBMVE") <> 0
			DBSelectArea("TRBMVE")
			DBCloseArea()
		EndIf
	
		TCQUERY cQry3 NEW ALIAS "TRBMVE"
		
		DBSelectArea("TRBMVE")
		TRBMVE->(DBGoTop())
		
		oReport:SetMeter(TRBMVE->(LastRec()))
	
		While !TRBMVE->(Eof())
			oReport:IncMeter()

			IncProc("Imprimindo Movimentação " + AllTrim(TRBMVE->DESCMOVINT))
			oSection3:Cell("DATADOC")		:SetValue(DToC(SToD(TRBMVE->EMISSAO)))
			oSection3:Cell("TPMOVIM")		:SetValue(AllTrim(TRBMVE->DESCMOVINT))
			oSection3:Cell("QTDE1UM")		:SetValue(TRBMVE->QUANT)
			oSection3:Cell("1UNIDME")		:SetValue(TRBMVE->UM)
			oSection3:Cell("QTDE2UM")		:SetValue(TRBMVE->QTSEGUM)
			oSection3:Cell("2UNIDME")		:SetValue(TRBMVE->SEGUM)
			oSection3:Cell("PRCUNIT")		:SetValue(TRBMVE->PRCVEN)
			oSection3:Cell("VLRTOTAL")		:SetValue(TRBMVE->TOTAL)

			oSection3:PrintLine()

			aResum[Len(aResum)][3] += TRBMVE->QUANT

			DBSelectArea("ZE2")
			DBSetOrder(1)
			If DBSeek(TRBMVE->FILIAL + TRBMVE->PRODUTO + DToS(MV_PAR04))
				aResum[Len(aResum)][6] := ZE2->ZE2_PALTOT
				aResum[Len(aResum)][7] := ZE2->ZE2_MEDCON
				aResum[Len(aResum)][8] := ZE2->ZE2_AUTEST
				aResum[Len(aResum)][9] := ZE2->ZE2_DTCONT
			EndIf

			aDados[5][aScan(aDados[2],SToD(TRBMVE->EMISSAO))] += TRBMVE->QUANT

			TRBMVE->(DBSkip())
		End

		oSection3:Finish()

		oSection4:init()

		cQry4 := "SELECT D2.D2_FILIAL FILIAL, D2.D2_COD PRODUTO, D2.D2_EMISSAO	EMISSAO, D2.D2_DOC DOCUMENTO, D2.D2_SERIE SERIE, D2.D2_CLIENTE CLIENTE, D2.D2_LOJA LOJA, D2.D2_LOCAL ARMAZEM, "
		cQry4 += "       Case "
		cQry4 += "         WHEN F2.F2_TIPO IN ('D','B') THEN ( SELECT A2.A2_NREDUZ "
		cQry4 += "                                             FROM " + RetSqlName("SA2") + " A2 "
		cQry4 += "                                             WHERE A2.A2_FILIAL = '" + xFilial("SA2") + "' "
		cQry4 += "                                             AND A2.D_E_L_E_T_ = ' ' "
		cQry4 += "                                             AND D2.D2_CLIENTE = A2.A2_COD "
		cQry4 += "                                             AND D2.D2_LOJA = A2.A2_LOJA ) "
		cQry4 += "         Else ( SELECT A1.A1_NREDUZ "
		cQry4 += "                FROM " + RetSqlName("SA1") + " A1 "
		cQry4 += "                WHERE A1.A1_FILIAL = '" + xFilial("SA1") + "' "
		cQry4 += "                  AND A1.D_E_L_E_T_ = ' ' "
		cQry4 += "                  AND D2.D2_CLIENTE = A1.A1_COD "
		cQry4 += "                  AND D2.D2_LOJA = A1.A1_LOJA ) END NOMFANTASIA, "
		cQry4 += "       D2.D2_UM UM, D2.D2_SEGUM SEGUM, SUM(D2.D2_QUANT)	QUANT, SUM(D2.D2_QTSEGUM)	QTSEGUM, DECODE( SUM(D2.D2_QUANT), 0, 0, "
		cQry4 += "       SUM(D2.D2_TOTAL) / SUM(D2.D2_QUANT) ) PRCVEN, SUM(D2.D2_TOTAL)	TOTAL, TO_CHAR(NULL) TM, 'A' TIPO, B1.B1_I_DESCD DESCPROD, "
		cQry4 += "       'SAIDA POR NF' DESCMOVINT, TO_CHAR(NULL) TPNOTAENT	"
		cQry4 += "FROM " + RetSqlName("SD2") + " D2 "
		cQry4 += "JOIN (SELECT F2.F2_FILIAL, F2.F2_DOC, F2.F2_CLIENTE, F2.F2_LOJA, F2.F2_TIPO "
		cQry4 += "      FROM " + RetSqlName("SF2") + " F2 "
		cQry4 += "      WHERE F2.D_E_L_E_T_ = ' ') F2 ON F2.F2_FILIAL = D2.D2_FILIAL AND F2.F2_DOC = D2.D2_DOC AND F2.F2_CLIENTE = D2.D2_CLIENTE AND F2.F2_LOJA = D2.D2_LOJA "
		cQry4 += "JOIN (SELECT F4.F4_FILIAL,F4.F4_CODIGO,F4.F4_ESTOQUE "
		cQry4 += "      FROM " + RetSqlName("SF4") + " F4 "
		cQry4 += "      WHERE F4.D_E_L_E_T_ = ' ') F4 ON D2.D2_FILIAL = F4.F4_FILIAL AND D2.D2_TES = F4.F4_CODIGO "
		cQry4 += "JOIN (SELECT B1.B1_FILIAL,B1.B1_COD,B1.B1_I_DESCD,B1.B1_GRUPO,B1.B1_I_SUBGR,B1.B1_I_NIV4,B1.B1_I_NIV3,B1.B1_I_NIV2 "
		cQry4 += "      FROM " + RetSqlName("SB1") + " B1 "
		cQry4 += "      WHERE B1.D_E_L_E_T_ = ' ') B1 ON B1.B1_FILIAL = '" + xFilial("SB1") + "' AND D2.D2_COD = B1.B1_COD "
		cQry4 += "WHERE D2.D_E_L_E_T_ = ' ' "
		cQry4 += "  AND D2.D2_COD = '" + TRBPRO->B1_COD + "' "
		cQry4 += "  AND F4.F4_ESTOQUE = 'S' "
		If !Empty(MV_PAR01)
			cQry4 += "  AND D2.D2_FILIAL IN " + FormatIn( MV_PAR01 , ";" )
			cQry4 += "  AND F4.F4_FILIAL IN " + FormatIn( MV_PAR01 , ";" )
		EndIf
		If !Empty(MV_PAR02)
			cQry4 += "  AND D2.D2_LOCAL = '" + MV_PAR02 + "' "
		EndIf
		cQry4 += "  AND D2.D2_EMISSAO BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' "
		If !Empty(MV_PAR07)
			cQry2 += "  AND B1.B1_GRUPO IN " + FormatIn( MV_PAR07 , ";" )
		EndIf
		cQry4 += "GROUP BY D2.D2_FILIAL,D2.D2_COD,D2.D2_EMISSAO,D2.D2_DOC,D2.D2_SERIE,D2.D2_CLIENTE,D2.D2_LOJA,D2.D2_LOCAL,D2.D2_UM,D2.D2_SEGUM,B1.B1_I_DESCD,F2.F2_TIPO "
		cQry4 += "ORDER BY FILIAL, PRODUTO, EMISSAO "

		If Select("TRBNFS") <> 0
			DBSelectArea("TRBNFS")
			DBCloseArea()
		EndIf
	
		TCQUERY cQry4 NEW ALIAS "TRBNFS"
		
		DBSelectArea("TRBNFS")
		TRBNFS->(DBGoTop())
		
		oReport:SetMeter(TRBNFS->(LastRec()))
	
		While !TRBNFS->(Eof())
			oReport:IncMeter()

			IncProc("Imprimindo Documento " + AllTrim(TRBNFS->DOCUMENTO) + " - " + AllTrim(TRBNFS->SERIE))
			oSection4:Cell("DATADOC")		:SetValue(DToC(SToD(TRBNFS->EMISSAO)))
			oSection4:Cell("DOCUMENTO")		:SetValue(AllTrim(TRBNFS->DOCUMENTO) + " - " + AllTrim(TRBNFS->SERIE))
			oSection4:Cell("CLIENTE")		:SetValue(TRBNFS->CLIENTE + "/" + TRBNFS->LOJA + " " + TRBNFS->NOMFANTASIA)
			oSection4:Cell("QTDE1UM")		:SetValue(TRBNFS->QUANT)
			oSection4:Cell("1UNIDME")		:SetValue(TRBNFS->UM)
			oSection4:Cell("QTDE2UM")		:SetValue(TRBNFS->QTSEGUM)
			oSection4:Cell("2UNIDME")		:SetValue(TRBNFS->SEGUM)
			oSection4:Cell("PRCUNIT")		:SetValue(TRBNFS->PRCVEN)
			oSection4:Cell("VLRTOTAL")		:SetValue(TRBNFS->TOTAL)

			oSection4:PrintLine()

			aResum[Len(aResum)][4] += TRBNFS->QUANT

			DBSelectArea("ZE2")
			DBSetOrder(1)
			If DBSeek(TRBNFS->FILIAL + TRBNFS->PRODUTO + DToS(MV_PAR04))
				aResum[Len(aResum)][6] := ZE2->ZE2_PALTOT
				aResum[Len(aResum)][7] := ZE2->ZE2_MEDCON
				aResum[Len(aResum)][8] := ZE2->ZE2_AUTEST
				aResum[Len(aResum)][9] := ZE2->ZE2_DTCONT
			EndIf

			aDados[6][aScan(aDados[2],SToD(TRBNFS->EMISSAO))] += TRBNFS->QUANT

			TRBNFS->(DBSkip())
		End

		oSection4:Finish()

		oSection5:init()

		cQry5 := "SELECT D3.D3_FILIAL FILIAL, D3.D3_COD PRODUTO, D3.D3_EMISSAO EMISSAO, TO_CHAR(NULL) DOCUMENTO, TO_CHAR(NULL)	SERIE, TO_CHAR(NULL) CLIENTE, TO_CHAR(NULL) LOJA, D3.D3_LOCAL ARMAZEM, "
		cQry5 += "       TO_CHAR(NULL) NOMFANTASIA, D3.D3_UM UM, D3.D3_SEGUM SEGUM, SUM(D3.D3_QUANT) QUANT, SUM(D3.D3_QTSEGUM) QTSEGUM,	"
		cQry5 += "       DECODE( SUM(D3.D3_QUANT), 0, 0, ( SUM(D3.D3_CUSTO1) / SUM(D3.D3_QUANT) ) ) PRCVEN, "
		cQry5 += "       SUM(D3.D3_CUSTO1) TOTAL, D3.D3_TM TM, 'B' TIPO, B1.B1_I_DESCD DESCPROD, "
		cQry5 += "       Case "
		cQry5 += "         WHEN D3_TM = '803' THEN 'Consumo Interno' "
		cQry5 += "         WHEN D3_TM = '804' THEN 'Faltas/Descarte' "
		cQry5 += "         WHEN D3_TM = '999' THEN 'Transf.Armazem Perda' "
		cQry5 += "         Else 'Outras Saidas' END DESCMOVINT, "
		cQry5 += "      TO_CHAR(NULL) TPNOTAENT "
		cQry5 += "FROM " + RetSqlName("SD3") + " D3 "
		cQry5 += "JOIN (SELECT B1.B1_FILIAL,B1.B1_COD,B1.B1_I_DESCD,B1.B1_GRUPO,B1.B1_I_SUBGR,B1.B1_I_NIV4,B1.B1_I_NIV3,B1.B1_I_NIV2 "
		cQry5 += "      FROM " + RetSqlName("SB1") + " B1 "
		cQry5 += "		WHERE B1.D_E_L_E_T_ = ' ')  B1 ON B1.B1_FILIAL = '" + xFilial("SB1") + "' AND D3.D3_COD = B1.B1_COD "
		cQry5 += "WHERE D3.D_E_L_E_T_ = ' ' "
		cQry5 += "  AND D3.D3_COD = '" + TRBPRO->B1_COD + "' "
		cQry5 += "  AND D3.D3_TM > '500' "
		cQry5 += "  AND D3_ESTORNO <> 'S' "
		If !Empty(MV_PAR01)
			cQry5 += "  AND D3.D3_FILIAL IN " + FormatIn( MV_PAR01 , ";" )
		EndIf
		If !Empty(MV_PAR02)
			cQry5 += "  AND D3.D3_LOCAL = '" + MV_PAR02 + "' "
		EndIf
		cQry5 += "  AND D3.D3_EMISSAO BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' "
		If !Empty(MV_PAR07)
			cQry5 += "  AND B1.B1_GRUPO IN " + FormatIn( MV_PAR07 , ";" )
		EndIf
		cQry5 += "GROUP BY D3.D3_FILIAL,D3.D3_COD,D3.D3_EMISSAO,D3.D3_LOCAL,D3.D3_TM,D3.D3_UM,D3.D3_SEGUM,B1.B1_I_DESCD "
		cQry5 += "ORDER BY FILIAL, PRODUTO , TIPO , EMISSAO , DOCUMENTO , TM "

		If Select("TRBMVS") <> 0
			DBSelectArea("TRBMVS")
			DBCloseArea()
		EndIf
	
		TCQUERY cQry5 NEW ALIAS "TRBMVS"
		
		DBSelectArea("TRBMVS")
		TRBMVS->(DBGoTop())
		
		oReport:SetMeter(TRBMVS->(LastRec()))
	
		While !TRBMVS->(Eof())
			oReport:IncMeter()

			IncProc("Imprimindo Movimentação " + AllTrim(TRBMVS->DESCMOVINT))
			oSection5:Cell("DATADOC")		:SetValue(DToC(SToD(TRBMVS->EMISSAO)))
			oSection5:Cell("TPMOVIM")		:SetValue(AllTrim(TRBMVS->DESCMOVINT))
			oSection5:Cell("QTDE1UM")		:SetValue(TRBMVS->QUANT)
			oSection5:Cell("1UNIDME")		:SetValue(TRBMVS->UM)
			oSection5:Cell("QTDE2UM")		:SetValue(TRBMVS->QTSEGUM)
			oSection5:Cell("2UNIDME")		:SetValue(TRBMVS->SEGUM)
			oSection5:Cell("PRCUNIT")		:SetValue(TRBMVS->PRCVEN)
			oSection5:Cell("VLRTOTAL")		:SetValue(TRBMVS->TOTAL)

			oSection5:PrintLine()

			//===============================================================================================
			//Somo as quantidades das movimentações de saídas para apresentar no resumo no final do relatório
			//===============================================================================================
			aResum[Len(aResum)][5] += TRBMVS->QUANT

			DBSelectArea("ZE2")
			DBSetOrder(1)
			If DBSeek(TRBMVS->FILIAL + TRBMVS->PRODUTO + DToS(MV_PAR04))
				aResum[Len(aResum)][6] := ZE2->ZE2_PALTOT
				aResum[Len(aResum)][7] := ZE2->ZE2_MEDCON
				aResum[Len(aResum)][8] := ZE2->ZE2_AUTEST
				aResum[Len(aResum)][9] := ZE2->ZE2_DTCONT
			EndIf

			aDados[7][aScan(aDados[2],SToD(TRBMVS->EMISSAO))] += TRBMVS->QUANT

			TRBMVS->(DBSkip())
		End

		oSection5:Finish()

		oSection6:init()

		cQry6 := "SELECT ZE2_FILIAL, ZE2_PRODUT, ZE2_DESCRI, ZE2_DTCONT, ZE2_PALCPR, ZE2_PALCEA, ZE2_PALAVA, ZE2_PALVAZ, ZE2_PALTOT, ZE2_MEDCON, ZE2_QTDALT, ZE2_PALSUJ, ZE2_AUTEST, "
		cQry6 += "ZE2_PALDES,ZE2_QTDPC "
		cQry6 += "FROM " + RetSqlName("ZE2") + " "
		cQry6 += "WHERE D_E_L_E_T_ = ' ' "
		If !Empty(MV_PAR01)
			cQry6 += "  AND ZE2_FILIAL IN " + FormatIn( MV_PAR01 , ";" )
		EndIf
		cQry6 += "  AND ZE2_PRODUT = '" + TRBPRO->B1_COD + "' "
		cQry6 += "  AND ZE2_DTCONT BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "' "
		cQry6 += "ORDER BY ZE2_FILIAL , ZE2_PRODUT , ZE2_DTCONT "

		If Select("TRBPAL") <> 0
			DBSelectArea("TRBPAL")
			DBCloseArea()
		EndIf
	
		TCQUERY cQry6 NEW ALIAS "TRBPAL"
		
		DBSelectArea("TRBPAL")
		TRBPAL->(DBGoTop())
		
		oReport:SetMeter(TRBPAL->(LastRec()))
	
		While !TRBPAL->(Eof())

			DBSelectArea("ZE2")
			DBSetOrder(1)

			If DBSeek(TRBPAL->ZE2_FILIAL + TRBPAL->ZE2_PRODUT + DToS(MV_PAR04))
				aResum[Len(aResum)][6] := ZE2->ZE2_PALTOT
				aResum[Len(aResum)][7] := ZE2->ZE2_MEDCON
				aResum[Len(aResum)][8] := ZE2->ZE2_AUTEST
				aResum[Len(aResum)][9] := ZE2->ZE2_DTCONT
			EndIf

			aDados[10][aScan(aDados[2],SToD(TRBPAL->ZE2_DTCONT))] += TRBPAL->ZE2_PALCPR
			aDados[11][aScan(aDados[2],SToD(TRBPAL->ZE2_DTCONT))] += TRBPAL->ZE2_PALCEA
			aDados[12][aScan(aDados[2],SToD(TRBPAL->ZE2_DTCONT))] += TRBPAL->ZE2_PALAVA
			aDados[13][aScan(aDados[2],SToD(TRBPAL->ZE2_DTCONT))] += TRBPAL->ZE2_PALVAZ
			aDados[14][aScan(aDados[2],SToD(TRBPAL->ZE2_DTCONT))] += TRBPAL->ZE2_PALSUJ
			aDados[15][aScan(aDados[2],SToD(TRBPAL->ZE2_DTCONT))] += TRBPAL->ZE2_PALTOT
			aDados[16][aScan(aDados[2],SToD(TRBPAL->ZE2_DTCONT))] += TRBPAL->ZE2_MEDCON
			aDados[17][aScan(aDados[2],SToD(TRBPAL->ZE2_DTCONT))] += TRBPAL->ZE2_AUTEST
			aDados[18][aScan(aDados[2],SToD(TRBPAL->ZE2_DTCONT))] += TRBPAL->ZE2_PALDES
			aDados[19][aScan(aDados[2],SToD(TRBPAL->ZE2_DTCONT))] += TRBPAL->ZE2_QTDPC

			TRBPAL->(DBSkip())
		End

		TRBPRO->(DBSkip())
	End

	oReport:SetMeter(Len(aDados[1]))

	aFiliais := StrTokArr(AllTrim(MV_PAR01),";")

	For nX := 1 To Len(aDados[1])
		
		nEstoque	:= 0
		nSalSb2		:= 0
		oReport:IncMeter()
		IncProc("Imprimindo Resumo... ")

		For nI := 1 To Len(aFiliais)

			DBSelectArea("NNR")
			NNR->(DBGoTop())
			
			While !NNR->(Eof())
				If NNR->NNR_CODIGO == MV_PAR02 .Or. Empty(MV_PAR02)
					nEstoque += (aSldAnt := CalcEst( aDados[1][nX],NNR->NNR_CODIGO,aDados[2][nX],aFiliais[nI] ))[1]
						DBSelectArea("SB2")
						DBSeek(aFiliais[nI] + aDados[1][nX] + NNR->NNR_CODIGO)						
						nSalSb2 += SB2->B2_QATU
				EndIf
				NNR->(DBSkip())
			End
		Next nI

		oSection6:Cell("ESTINIC")		:SetValue(nEstoque)			// Estoque Inicial
		oSection6:Cell("DOCENTR")		:SetValue(aDados[4][nX]+aDados[5][nX])	// Entradas
		oSection6:Cell("DOCSAID")		:SetValue(aDados[6][nX]+aDados[7][nX])	// Saídas
		oSection6:Cell("ESTATUA")		:SetValue(nEstoque + aDados[4][nX] + aDados[5][nX] - aDados[6][nX] - aDados[7][nX])	// Estoque Atual
		
		If MV_PAR04 >= Date()
			oSection6:Cell("SALATUA")		:SetValue(nSalSb2)		// Saldo Atual
		EndIf
		
		oSection6:Cell("PALCPR")		:SetValue(aDados[10][nX])
		oSection6:Cell("PALCEA")		:SetValue(aDados[11][nX])
		oSection6:Cell("PALAVA")		:SetValue(aDados[12][nX])
		oSection6:Cell("PALVAZ")		:SetValue(aDados[13][nX])
		oSection6:Cell("PALSUJ")		:SetValue(aDados[14][nX])
		oSection6:Cell("PALDES")		:SetValue(aDados[18][nX])
		oSection6:Cell("PALPEC")		:SetValue(aDados[19][nX])
		

		oSection6:Cell("TOTPALL")		:SetValue(aDados[15][nX])	// Tot. pallets fabric // Antiga coluna "Total de Pallets"
		
		oSection6:Cell("TOTGERPALL")	:SetValue(nSalSb2 + aDados[15][nX])	// Total de Pallets
		
		_ndif := nEstoque + aDados[4][nX] + aDados[5][nX] - aDados[6][nX] - aDados[7][nX]-aDados[15][nX]
		
		If _ndif <> 0
		
			oSection6:Cell("DIFEREN")		:LBOLD := .T.
		
		EndIf
				
		oSection6:Cell("DIFEREN")		:SetValue(_ndif)	// Diferença
		
		oSection6:Cell("MEDCONS")		:SetValue(aDados[16][nX])	// Média de Consumo Diário
		oSection6:Cell("AUTESTD")		:SetValue(aDados[17][nX])	// Autonomia Estoque em Dias
		oSection6:Cell("DTINCL")		:SetValue(aDados[2][nX] )	// Data

		oSection6:PrintLine()
		
	Next nX
	oSection6:Finish()

	oSection1:Finish()
	oSection1:Enable()
	oSection2:Enable()
	oSection3:Enable()
	oSection4:Enable()
	oSection5:Enable()
	oSection6:Enable()

EndIf

Return
