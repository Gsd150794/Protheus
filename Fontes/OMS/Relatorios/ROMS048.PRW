/*
===============================================================================================================================
               ULTIMAS ATUALIZACOES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Alexandre Villar  | 23/03/2016 | Ajuste para padronizar a utilizacao de rotinas de consultas customizadas. Chamado 14774      
-------------------------------------------------------------------------------------------------------------------------------
Josue Danich      | 08/03/2019 | Revisao para loboguara - Chamado 28356
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  	  | 17/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: ROMS048
Autor-----------: Alex Wallauer Ferreira
Data da Criacao-: 09/06/2017
===============================================================================================================================
Descricao-------: Relatorio de Listagem de cargas sem Faturamento
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ROMS048()

Local oReport 
Private _cPerg:="ROMS48"

oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa--------: ReportDef
Autor-----------: Eduardo Riera
Data da Criacao-: 10/05/2006
===============================================================================================================================
Descricao-------: A funcao eStatica ReportDef devera ser criada para todos os  
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: ExpO1: Objeto do relatorio
===============================================================================================================================
*/
Static Function ReportDef()
Local oReport
Local oCarga
Local oItCarga
Local oItPedido
Local oItPedido2
Local oItNF
Local oItNF2
Local lQuery  := .F.
Local cNReduz := ""

Local cAliasDAK := GetNextAlias()
Local cAliasDAI := cAliasDAK
Local cAliasSC9 := cAliasDAK
Local cAliasSD2 := cAliasDAK
                                            
oReport := TReport():New("ROMS048","Listagem de cargas sem Faturamento", _cPerg, {|oReport| ReportPrint(oReport,cAliasSC9,oItPedido,cAliasSD2,oITNF,oItPedido2,oItNF2,cAliasDAK,cAliasDAI,oCarga,cAliasSD2,@lQuery,cNReduz)},OemToAnsi("Este relatorio ira imprimir a listagem de cargas de acordo")+" "+OemToAnsi("com os parametros informados pelo usuario"))
oReport:SetLandscape() 
oReport:SetTotalInLine(.F.)

Pergunte(oReport:uParam,.F.)

// Section(1)                                                               
oCarga:= TRSection():New(oReport,"Carga",{"DAK","DA3","DA4"},/*{"Pedido","Item"}*/,/*Campos do SX3*/,/*Campos do SIX*/) 
oCarga:SetTotalInLine(.F.)
TRCell():New(oCarga , "DAK_COD"    , "DAK" , "Carga"    , PesqPict("DAK","DAK_COD")   	, TamSX3("DAK_COD")[1]+1   	, /*lPixel*/ , /*{|| code-block de impressao }*/) //"Carga"
TRCell():New(oCarga , "DAK_SEQCAR" , "DAK" , "Seq."     , PesqPict("DAK","DAK_SEQCAR")	, TamSX3("DAK_COD")[1]     	, /*lPixel*/ , /*{|| code-block de impressao }*/) //"Seq."
TRCell():New(oCarga , "DAK_CAMINH" , "DAK" , /*Titulo*/ , PesqPict("DAK","DAK_CAMINH")	, TamSX3("DAK_CAMINH")[1]+3	, /*lPixel*/ , /*{|| code-block de impressao }*/)
TRCell():New(oCarga , "DA3_DESC"   , "DA3" , /*Titulo*/ , /*Picture*/					, /*Tamanho*/				, /*lPixel*/ , /*{|| code-block de impressao }*/)
TRCell():New(oCarga , "DAK_MOTORI" , "DAK" , /*Titulo*/ , /*Picture*/					, /*Tamanho*/ 				, /*lPixel*/ , /*{|| code-block de impressao }*/)
TRCell():New(oCarga , "DA4_NOME"   , "DA4" , ""         , /*Picture*/					, /*Tamanho*/ 				, /*lPixel*/ , /*{|| code-block de impressao }*/)
TRCell():New(oCarga , "DAK_PESO"   , "DAK" , /*Titulo*/ , /*Picture*/					, /*Tamanho*/ 				, /*lPixel*/ , /*{|| code-block de impressao }*/)
TRCell():New(oCarga , "DAK_CAPVOL" , "DAK" , /*Titulo*/ , /*Picture*/					, /*Tamanho*/ 				, /*lPixel*/ , /*{|| code-block de impressao }*/)
TRCell():New(oCarga , "DAK_PTOENT" , "DAK" , /*Titulo*/ , /*Picture*/					, /*Tamanho*/	 			, /*lPixel*/ , /*{|| code-block de impressao }*/)
TRCell():New(oCarga , "DAK_VALOR"  , "DAK" , /*Titulo*/ , /*Picture*/					, /*Tamanho*/ 				, /*lPixel*/ , /*{|| code-block de impressao }*/)
TRCell():New(oCarga , "DAK_I_PREC" , "DAI" , /*Titulo*/ , /*Picture*/                   , /*Tamanho*/               , /*lPixel*/ , {|| If((cAliasDAK)->DAK_I_PREC="1","Sim","Não") })
TRCell():New(oCarga , "DAK_DATA"   , "DAK" , /*Titulo*/ , /*Picture*/					, TamSX3("DAK_DATA")[1]+6	, /*lPixel*/ , /*{|| code-block de impressao }*/)
TRCell():New(oCarga , "DAK_HORA"   , "DAK" , /*Titulo*/ , /*Picture*/					, TamSX3("DAK_HORA")[1]+4	, /*lPixel*/ , /*{|| code-block de impressao }*/)

//PEDIDO
//Section(1):Section(1)
oItCarga:= TRSection():New(oCarga,"Pedidos da Carga",{"DAI","SA1"},/* ,"SF2" {Array com as ordens do relatorio}*/,/*Campos do SX3*/,/*Campos do SIX*/)
oItCarga:SetTotalInLine(.F.)
TRCell():New(oItCarga , "DAI_SEQUEN" ,"DAI" , /*Titulo*/ , /*Picture*/ , /*Tamanho*/ , /*lPixel*/ , /*{|| code-block de impressao }*/)
TRCell():New(oItCarga , "DAI_PEDIDO" ,"DAI" , /*Titulo*/ , /*Picture*/ , /*Tamanho*/ , /*lPixel*/ , /*{|| code-block de impressao }*/)
TRCell():New(oItCarga , "DAI_CLIENT" ,"DAI" , /*Titulo*/ , /*Picture*/ , /*Tamanho*/ , /*lPixel*/ , /*{|| code-block de impressao }*/)
TRCell():New(oItCarga , "DAI_LOJA"   ,"DAI" , /*Titulo*/ , /*Picture*/ , /*Tamanho*/ , /*lPixel*/ , /*{|| code-block de impressao }*/)
TRCell():New(oItCarga , "A1_NREDUZ"  ,      , /*Titulo*/ , /*Picture*/ , /*Tamanho*/ , /*lPixel*/ , /*{|| code-block de impressao }*/)
TRCell():New(oItCarga , "DAI_PESO"   ,"DAI" , /*Titulo*/ , /*Picture*/ , /*Tamanho*/ , /*lPixel*/ , /*{|| code-block de impressao }*/)

//PRODUTO
//Section(1):Section(1):Section(1)
oItPedido:= TRSection():New(oItCarga,"Item do Pedido de venda",{"SC9","SB1"},/*{Array com as ordens do relatório}*/,/*Campos do SX3*/,/*Campos do SIX*/) //
oItPedido:SetTotalInLine(.F.)
TRCell():New(oItPedido , "C9_ITEM"    , "SC9" , /*Titulo*/ , /*Picture*/ , /*Tamanho*/ , /*lPixel*/  , /*{|| code-block de impressao }*/)
TRCell():New(oItPedido , "C9_PRODUTO" , "SC9" , /*Titulo*/ , /*Picture*/ , /*Tamanho*/ , /*lPixel*/  , /*{|| code-block de impressao }*/)
TRCell():New(oItPedido , "B1_DESC"    , "SB1" , /*Titulo*/ , /*Picture*/ , /*Tamanho*/ , /*lPixel*/  , /*{|| code-block de impressao }*/)
TRCell():New(oItPedido , "C9_QTDLIB"  , "SC9" , /*Titulo*/ , /*Picture*/ , /*Tamanho*/ , /*lPixel*/  , /*{|| code-block de impressao }*/)
TRCell():New(oItPedido , "B1_UM"      , "SB1" , /*Titulo*/ , /*Picture*/ , /*Tamanho*/ , /*lPixel*/  , /*{|| code-block de impressao }*/)
TRCell():New(oItPedido , "C9_QTDLIB2" , "SC9" , /*Titulo*/ , /*Picture*/ , /*Tamanho*/ , /*lPixel*/  , /*{|| code-block de impressao }*/)
TRCell():New(oItPedido , "B1_SEGUM"   , "SB1" , /*Titulo*/ , /*Picture*/ , /*Tamanho*/ , /*lPixel*/  , /*{|| code-block de impressao }*/)
TRCell():New(oItPedido , "C6_VALOR"   , "SC6" , /*Titulo*/ , /*Picture*/ , /*Tamanho*/ , /*lPixel*/  , {|| (cAliasSC9)->C9_QTDLIB*(cAliasSC9)->C9_PRCVEN })

Return( oReport )

/*
===============================================================================================================================
Programa--------: ReportPrint
Autor-----------: Eduardo Riera
Data da Criacao-: 10/05/2006
===============================================================================================================================
Descricao-------: A funcao eStatica ReportDef devera ser criada para todos os
===============================================================================================================================
Parametros------: ExpO1: Objeto Report do Relatorio
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,cAliasSC9,oItPedido,cAliasSD2,oITNF,oItPedido2,oItNF2,cAliasDAK,cAliasDAI,oCarga,cAliasSD2,lQuery,cNReduz)
Local cFilPV    := ""
Local nTipoOper := OsVlEntCom()
Local cFilWhere	:= ""
Local cQrySelect := "%%"

// Transforma parametros Range em expressao SQL                             
MakeSqlExpr(oReport:uParam)

// Filtragem do relatorio                                                   

	lQuery := .T.
	// Query do relatorio                                                       
	Do Case

		Case MV_PAR11 == 1 ////SINTETICO
				cQrySelect := "%"+cQrySelect+"%"
				oReport:Section(1):BeginQuery()
				BeginSql Alias cAliasDAK
					SELECT DAK_FILIAL,DAK_COD,DAK_SEQCAR,DAK_CAMINH,DAK_MOTORI,DAK_DATA,DAK_PESO,DAK_CAPVOL,
							DAK_PTOENT,DAK_VALOR,DAK_HORA,DAK_PESO,DAK_I_PREC
					FROM %Table:DAK% DAK 
					WHERE DAK_FILIAL = %xFilial:DAK% AND 
							DAK_COD    >= %exp:MV_PAR01% AND 
							DAK_COD    <= %exp:MV_PAR02% AND 
							DAK_SEQCAR >= %exp:MV_PAR03% AND 
							DAK_SEQCAR <= %exp:MV_PAR04% AND 
							DAK_CAMINH >= %exp:MV_PAR05% AND 
							DAK_CAMINH <= %exp:MV_PAR06% AND 
							DAK_MOTORI >= %exp:MV_PAR07% AND 
							DAK_MOTORI <= %exp:MV_PAR08% AND 
							DAK_DATA   >= %exp:DToS(MV_PAR09)% AND 
							DAK_DATA   <= %exp:DToS(MV_PAR10)% AND 
							DAK_FEZNF  = '2' AND 
							DAK.%NotDel%
					ORDER BY DAK_FILIAL,DAK_COD,DAK_SEQCAR
				EndSql
				oReport:Section(1):EndQuery()

		Case MV_PAR11 == 2	// ANALITICO

			cQrySelect := ""

			If	MV_PAR13 == 1 //PEDIDO
				cQrySelect := "%"+cQrySelect+"%"

				oReport:Section(1):BeginQuery()
				BeginSql Alias cAliasDAK
					SELECT DAK_FILIAL,DAK_COD,DAK_SEQCAR,DAK_CAMINH,DAK_MOTORI,DAK_DATA,DAK_PESO,DAK_CAPVOL,
							DAK_PTOENT,DAK_VALOR,DAK_HORA,DAK_I_PREC,DAI_FILIAL,DAI_COD,DAI_SEQCAR,DAI_SEQUEN,DAI_PEDIDO,
							DAI_CLIENT,DAI_LOJA,DAI_PESO,DAI_CAPVOL,DAI_NFISCA,DAI_SERIE
							%exp:cQrySelect%
					FROM %Table:DAK% DAK ,%table:DAI% DAI
					WHERE DAK_FILIAL = %xFilial:DAK% AND 
							DAK_COD    >= %exp:MV_PAR01% AND 
							DAK_COD    <= %exp:MV_PAR02% AND 
							DAK_SEQCAR >= %exp:MV_PAR03% AND 
							DAK_SEQCAR <= %exp:MV_PAR04% AND 
							DAK_CAMINH >= %exp:MV_PAR05% AND 
							DAK_CAMINH <= %exp:MV_PAR06% AND 
							DAK_MOTORI >= %exp:MV_PAR07% AND 
							DAK_MOTORI <= %exp:MV_PAR08% AND 
							DAK_DATA   >= %exp:DToS(MV_PAR09)% AND 
							DAK_DATA   <= %exp:DToS(MV_PAR10)% AND 
							DAK.%NotDel% AND 
							DAI_FILIAL = %exp:xFilial("DAI")% AND 
							DAI_COD    = DAK.DAK_COD AND 
							DAI_SEQCAR = DAK.DAK_SEQCAR AND
							DAI_NFISCA = ' ' AND  
							DAI.%NotDel%
					ORDER BY DAK_FILIAL,DAK_COD,DAK_SEQCAR,DAI_SEQUEN
				EndSql
				oReport:Section(1):EndQuery()
			    oReport:Section(1):Section(1):SetParentQuery()
			    
			Else	//PRODUTO
				cQrySelect := ""
				cFilWhere := IIf(nTipoOper == 1, xFilial("SC9"),"%"+OsFilQry("SC9","DAI.DAI_FILPV")+"%" )

				oReport:Section(1):BeginQuery()
				BeginSql Alias cAliasDAK
					SELECT DAK_FILIAL,DAK_COD,DAK_SEQCAR,DAK_CAMINH,DAK_MOTORI,DAK_DATA,DAK_PESO,DAK_CAPVOL,DAK_PTOENT,DAK_VALOR,DAK_HORA,DAK_I_PREC,
							DAI_FILIAL,DAI_COD,DAI_SEQCAR,DAI_SEQUEN,DAI_PEDIDO,DAI_CLIENT,DAI_LOJA,DAI_PESO,DAI_CAPVOL,DAI_NFISCA,DAI_SERIE,
							C9_FILIAL,C9_CLIENTE,C9_LOJA,C9_PEDIDO,C9_ITEM,C9_PRODUTO,C9_QTDLIB,C9_QTDLIB2,C9_PRCVEN,C9_CARGA,C9_SEQCAR,C9_NFISCAL,C9_SERIENF,C9_LOTECTL,C9_NUMLOTE,B1_UM,B1_SEGUM
					FROM %Table:DAK% DAK ,%table:DAI% DAI ,%table:SC9% SC9 ,%table:SB1% SB1
					WHERE DAK_FILIAL = %xFilial:DAK% AND 
							DAK_COD    >= %exp:MV_PAR01% AND 
							DAK_COD    <= %exp:MV_PAR02% AND 
							DAK_SEQCAR >= %exp:MV_PAR03% AND 
							DAK_SEQCAR <= %exp:MV_PAR04% AND 
							DAK_CAMINH >= %exp:MV_PAR05% AND 
							DAK_CAMINH <= %exp:MV_PAR06% AND 
							DAK_MOTORI >= %exp:MV_PAR07% AND 
							DAK_MOTORI <= %exp:MV_PAR08% AND 
							DAK_DATA   >= %exp:DToS(MV_PAR09)% AND 
							DAK_DATA   <= %exp:DToS(MV_PAR10)% AND 
							DAK.%NotDel% AND 
							DAI_FILIAL = %exp:xFilial("DAI")% AND 
							DAI_COD    = DAK_COD AND 
							DAI_SEQCAR = DAK_SEQCAR AND 
							DAI_NFISCA = ' ' AND  
							DAI.%NotDel% AND 
							B1_FILIAL  = %exp:xFilial("SB1")% AND 
							B1_COD = C9_PRODUTO AND
							SB1.%NotDel% AND 
							C9_FILIAL  = %exp:cFilWhere% AND 
							C9_PEDIDO  = DAI_PEDIDO AND 
							C9_CLIENTE = DAI_CLIENT AND 
							C9_LOJA    = DAI_LOJA   AND 
							C9_CARGA   = DAI_COD    AND 
							C9_SEQCAR  = DAI_SEQCAR AND 
							SC9.%NotDel%
					ORDER BY DAK_FILIAL,DAK_COD,DAK_SEQCAR,DAI_SEQUEN,C9_PEDIDO,C9_ITEM
				EndSql
				oReport:Section(1):EndQuery()
  			    oReport:Section(1):Section(1):SetParentQuery()
 			    oReport:Section(1):Section(1):Section(1):SetParentQuery()
			EndIf

			
	EndCase


//Desliga e liga as Section com base nas opcoes
If MV_PAR11 == 1 //SINTETICO

   oReport:Section(1):Enable()
   oReport:Section(1):Section(1):Disable()
   oReport:Section(1):Section(1):Section(1):Disable()

ElseIf MV_PAR11 == 2 //ANALITICO

   oReport:Section(1):Section(1):SetParentFilter({|x| (cAliasDAI)->DAI_FILIAL+(cAliasDAI)->DAI_COD+(cAliasDAI)->DAI_SEQCAR == x})
   oReport:Section(1):Section(1):bParentParam := {||  (cAliasDAK)->DAK_FILIAL+(cAliasDAK)->DAK_COD+(cAliasDAK)->DAK_SEQCAR}
   
   oReport:Section(1):Section(1):Enable()//Por Pedido
   oReport:Section(1):Section(1):Section(1):Disable()

   If MV_PAR13 == 2 //Por Produto

	  oReport:Section(1):Section(1):Section(1):SetParentFilter({|x|(cAliasSC9)->C9_FILIAL +(cAliasSC9)->C9_CLIENTE+(cAliasSC9)->C9_LOJA+ (cAliasSC9)->C9_PEDIDO == x})
	  oReport:Section(1):Section(1):Section(1):bParentParam := {|| (cAliasDAI)->DAI_FILIAL+(cAliasDAI)->DAI_CLIENT+(cAliasDAI)->DAI_LOJA+(cAliasDAI)->DAI_PEDIDO}

      oReport:Section(1):Section(1):Section(1):Enable()

   EndIf
EndIf

oReport:Section(1):Section(1):Cell("A1_NREDUZ" ):SetBlock({|| cNReduz})

TRPosition():New(oReport:Section(1),"DA3",1,{|| xFilial("DA3")+(cAliasDAK)->DAK_CAMINH })
TRPosition():New(oReport:Section(1),"DA4",1,{|| xFilial("DA4")+(cAliasDAK)->DAK_MOTORI })

TRPosition():New(oReport:Section(1):Section(1),"SC5",1,{|| BuscaNome((cAliasDAI)->DAI_FILIAL+(cAliasDAI)->DAI_PEDIDO,@cNReduz)})
TRPosition():New(oReport:Section(1):Section(1),"SA1",1,{|| xFilial("SA1") + SC5->C5_CLIENTE + SC5->C5_LOJACLI })

TRPosition():New(oReport:Section(1):Section(1):Section(1),"SB1",1,{|| OsFilial("SB1",cFilPv)+(cAliasSC9)->C9_PRODUTO})

// Inicio da impressao do fluxo do relatorio                                
oReport:SetMeter(DAK->(LastRec()))
If MV_PAR12 == 1
   oReport:Section(1):SetPageBreak()
EndIf

oReport:Section(1):Print()

RetIndex("SC9")
RetIndex("SD2")
RetIndex("DAK")
RetIndex("DAI")

Return

/*
===============================================================================================================================
Programa--------: BuscaNome
Autor-----------: Eduardo Riera
Data da Criacao-: 10/05/2006
===============================================================================================================================
Descricao-------: Busca nome do cliente/fornecedor dependendo do tipo do pedido de vendas
===============================================================================================================================
Parametros------: ExpC1: Filial_Numero do pedido de vendas
					ExpC2: Nome do cliente/fornececor
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function BuscaNome(cChave,cNReduz)
DBSelectArea("SC5")
DBSetOrder(1)
If DBSeek(cChave)
	If !SC5->C5_TIPO $ "BD"
		DBSelectArea("SA1")
		DBSetOrder(1)
		DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
		cNReduz := SA1->A1_NREDUZ
	Else
		DBSelectArea("SA2")
		DBSetOrder(1)
		DBSeek(xFilial("SA2")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)
		cNReduz := SA2->A2_NREDUZ
	EndIf
EndIf

Return( cChave )
