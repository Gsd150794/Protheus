/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RFIS008
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/06/2022
Descrição---------: Relatório para análise de Escrituração Fiscal. Chamado 48343
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RFIS008()

Local oReport

  Pergunte("RFIS008",.F.)
  //Inferface de Impressão
  oReport := ReportDef()
  oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/06/2022
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem     := {"Documento e Serie"}
Local _aCampos    := {}
Local _nX, _nY		:= 0
Local _cCampos1	  :="% "
Local _cCampos2	  :="% "

//{query 01 base, query 02 base, query 03 base, query 04 base, Alias célula, descrição célula}
aAdd(_aCampos,{"D1_FILIAL",	  "D2_FILIAL",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_FILIAL","X3_TITULO")})
aAdd(_aCampos,{"D1_DOC",      "D2_DOC",   	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_DOC","X3_TITULO")})
aAdd(_aCampos,{"D1_SERIE",	  "D2_SERIE",		        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_SERIE","X3_TITULO")})
aAdd(_aCampos,{"D1_EMISSAO",  "D2_EMISSAO",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_EMISSAO","X3_TITULO")})
aAdd(_aCampos,{"D1_DTDIGIT",  "D2_EMISSAO",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_DTDIGIT","X3_TITULO")})
aAdd(_aCampos,{"D1_FORNECE",  "D2_CLIENTE",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_FORNECE","X3_TITULO")})
aAdd(_aCampos,{"D1_LOJA",	    "D2_LOJA",		        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_LOJA","X3_TITULO")})
aAdd(_aCampos,{"A2_NOME",	    "A2_NOME",		        "SA2",	"SA2-"+GetSX3Cache("A2_NOME","X3_TITULO")})
aAdd(_aCampos,{"A2_CGC",	    "A2_CGC",		          "SA2",	"SA2-"+GetSX3Cache("A2_CGC","X3_TITULO")})
aAdd(_aCampos,{"A2_INSCR",	  "A2_INSCR",		        "SA2",	"SA2-"+GetSX3Cache("A2_INSCR","X3_TITULO")})
aAdd(_aCampos,{"A2_INSCRM",	  "A2_INSCRM",	        "SA2",	"SA2-"+GetSX3Cache("A2_INSCRM","X3_TITULO")})
aAdd(_aCampos,{"F1_EST",	    "F2_EST",	            "SD1",	"SD1/SD2-"+GetSX3Cache("F1_EST","X3_TITULO")})
aAdd(_aCampos,{"A2_MUN",	    "A2_MUN",		          "SA2",	"SA2-"+GetSX3Cache("A2_MUN","X3_TITULO")})
aAdd(_aCampos,{"A2_CALCIRF",  "A2_CALCIRF",	        "SA2",	"SA2-"+GetSX3Cache("A2_CALCIRF","X3_TITULO")})
aAdd(_aCampos,{"A1_SIMPNAC",  "A1_SIMPNAC",	        "SA1",	"SA1-"+GetSX3Cache("A1_SIMPNAC","X3_TITULO")})
aAdd(_aCampos,{"GER_LIVRO",   "GER_LIVRO",	        "",	    "Gerou Livro"})
aAdd(_aCampos,{"TIPOMOV",     "TIPOMOV",	          "",	    "ENT/SAID"})
aAdd(_aCampos,{"F1_ESPECIE",  "F2_ESPECIE",	        "SF1",	"SF1/SF2-"+GetSX3Cache("F1_ESPECIE","X3_TITULO")})
aAdd(_aCampos,{"D1_TIPO",	    "D2_TIPO",		        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_TIPO","X3_TITULO")})
aAdd(_aCampos,{"FT_DTCANC",	  "FT_DTCANC",	        "SFT",	"SFT-"+GetSX3Cache("FT_DTCANC","X3_TITULO")})
aAdd(_aCampos,{"D1_FORMUL",	  "D2_FORMUL",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_FORMUL","X3_TITULO")})
aAdd(_aCampos,{"E2_NATUREZ",  "E2_NATUREZ",	        "SE2",	"SE2-"+GetSX3Cache("E2_NATUREZ","X3_TITULO")})
aAdd(_aCampos,{"ED_DESCRIC",  "ED_DESCRIC",	        "SED",	"SED-"+GetSX3Cache("ED_DESCRIC","X3_TITULO")})
aAdd(_aCampos,{"F1_COND",	    "F2_COND",		        "SF1",	"SF1/SF2-"+GetSX3Cache("F1_COND","X3_TITULO")})
aAdd(_aCampos,{"COLAB",	      "COLAB",              '',     "Colaboração"})
aAdd(_aCampos,{"STATUS",	    "STATUS",             '',     "Status"})
aAdd(_aCampos,{"ERRO",		    "ERRO",			          '',	    "Erro Escrituração"})
aAdd(_aCampos,{"F3_CODRSEF",  "F3_CODRSEF",         "SF3",	"SF3-"+GetSX3Cache("F3_CODRSEF","X3_TITULO")})
aAdd(_aCampos,{"FT_CHVNFE",	  "FT_CHVNFE",	        "SFT",	"SFT-"+GetSX3Cache("FT_CHVNFE","X3_TITULO")})
aAdd(_aCampos,{"D1_ITEM",	    "D2_ITEM",            "SD1",	"SD1/SD2-"+GetSX3Cache("D1_ITEM","X3_TITULO")})
aAdd(_aCampos,{"D1_COD",      "D2_COD",	            "SD1",	"SD1/SD2-"+GetSX3Cache("D1_COD","X3_TITULO")})
aAdd(_aCampos,{"B1_DESC",	    "B1_DESC",		        "SB1",	"SB1-"+GetSX3Cache("B1_DESC","X3_TITULO")})
aAdd(_aCampos,{"D1_GRUPO",	  "D2_GRUPO",		        "SD1",	"SD1-"+GetSX3Cache("D1_GRUPO","X3_TITULO")})
aAdd(_aCampos,{"BM_DESC",	    "BM_DESC",		        "SBM",	"SBM-"+GetSX3Cache("BM_DESC","X3_TITULO")})
aAdd(_aCampos,{"D1_CONTA",	  "D2_CONTA",		        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_CONTA","X3_TITULO")})
aAdd(_aCampos,{"D1_CC",		    "D2_CCUSTO",        	"SD1",	"SD1/SD2"+CRLF+"Desc. C.Custo"})
aAdd(_aCampos,{"CTT_DESC01",  "CTT_DESC01",	        "CTT",	"CTT"+CRLF+"Desc Centro de Custo"})
aAdd(_aCampos,{"D1_TES",	    "D2_TES",		          "SD1",	"SD1/SD2"+CRLF+"TES"})
aAdd(_aCampos,{"D1_CF",	      "D2_CF",              "SD1",	"SD1/SD2-"+GetSX3Cache("D1_CF","X3_TITULO")})
aAdd(_aCampos,{"F4_CF",       "F4_CF",	            "SF4",	"SF4-"+GetSX3Cache("F4_CF","X3_TITULO")})
aAdd(_aCampos,{"F4_DUPLIC",	  "F4_DUPLIC",	        "SF4",	"SF4-"+GetSX3Cache("F4_DUPLIC","X3_TITULO")})
aAdd(_aCampos,{"F4_FINALID",  "F4_FINALID",	        "SF4",	"SF4-"+GetSX3Cache("F4_FINALID","X3_TITULO")})
aAdd(_aCampos,{"F4_INCIDE",   "F4_INCIDE",	        "SF4",	"SF4-"+GetSX3Cache("F4_INCIDE","X3_TITULO")})
aAdd(_aCampos,{"F4_BASEICM",  "F4_BASEICM",	        "SF4",	"SF4-"+GetSX3Cache("F4_BASEICM","X3_TITULO")})
aAdd(_aCampos,{"F4_LFICM",    "F4_LFICM",	          "SF4",	"SF4-"+GetSX3Cache("F4_LFICM","X3_TITULO")})
aAdd(_aCampos,{"F4_ICM",      "F4_ICM",	            "SF4",	"SF4-"+GetSX3Cache("F4_LFICM","X3_TITULO")})
aAdd(_aCampos,{"F4_COMPL",    "F4_COMPL",	          "SF4",	"SF4-"+GetSX3Cache("F4_COMPL","X3_TITULO")})

aAdd(_aCampos,{"D1_UM",		    "D2_UM",		          "SD1",	"SD1/SD2-"+GetSX3Cache("D1_UM","X3_TITULO")})
aAdd(_aCampos,{"D1_SEGUM",	  "D2_SEGUM",		        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_SEGUM","X3_TITULO")})
aAdd(_aCampos,{"F4_ESTOQUE",  "F4_ESTOQUE",	        "SF4",	"SF4-"+GetSX3Cache("F4_ESTOQUE","X3_TITULO")})
aAdd(_aCampos,{"D1_QUANT",	  "D2_QUANT",		        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_QUANT","X3_TITULO")})
aAdd(_aCampos,{"D1_QTSEGUM",  "D2_QTSEGUM",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_QTSEGUM","X3_TITULO")})
aAdd(_aCampos,{"D1_VUNIT",    "D2_PRCVEN",          "SD1",	"SD1/SD2-"+GetSX3Cache("D1_VUNIT","X3_TITULO")})
aAdd(_aCampos,{"D1_VALDESC",  "D2_DESCON",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_VALDESC","X3_TITULO")})
aAdd(_aCampos,{"D1_TOTAL",	  "D2_TOTAL",		        "SF2",	"SD1/SD2-"+GetSX3Cache("D1_TOTAL","X3_TITULO")})
aAdd(_aCampos,{"D1_VALFRE",	  "D2_VALFRE+D2_I_FRET","SD1",	"SD1/SD2-"+GetSX3Cache("D1_VALFRE","X3_TITULO")})
aAdd(_aCampos,{"D1_SEGURO",	  "D2_SEGURO",          "SD1",	"SD1/SD2-"+GetSX3Cache("D1_SEGURO","X3_TITULO")})
aAdd(_aCampos,{"D1_DESPESA",  "D2_DESPESA",         "SD1",	"SD1/SD2-"+GetSX3Cache("D1_DESPESA","X3_TITULO")})
aAdd(_aCampos,{"D1_NFORI",	  "D2_NFORI",           "SD1",	"SD1/SD2-"+GetSX3Cache("D1_NFORI","X3_TITULO")})
aAdd(_aCampos,{"D1_SERIORI",  "D2_SERIORI",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_SERIORI","X3_TITULO")})
aAdd(_aCampos,{"D1_ITEMORI",  "D2_ITEMORI",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_ITEMORI","X3_TITULO")})
aAdd(_aCampos,{"D1_PEDIDO",	  "D2_PEDIDO",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_PEDIDO","X3_TITULO")})
aAdd(_aCampos,{"D1_ITEMPC",	  "D2_ITEMPV",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_ITEMPC","X3_TITULO")})
aAdd(_aCampos,{"D1_LOCAL",	  "D2_LOCAL",		        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_LOCAL","X3_TITULO")})
aAdd(_aCampos,{"D1_TP",		    "D2_TP",		          "SD1",	"SD1/SD2-"+GetSX3Cache("D1_TP","X3_TITULO")})
aAdd(_aCampos,{"D1_QTDEDEV",  "D2_QTDEDEV",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_QTDEDEV","X3_TITULO")})
aAdd(_aCampos,{"D1_VALDEV",	  "D2_VALDEV",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_VALDEV","X3_TITULO")})
aAdd(_aCampos,{"D1_SERVIC",	  "D2_SERVIC",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_SERVIC","X3_TITULO")})
aAdd(_aCampos,{"F1_TPFRETE",  "F2_TPFRETE",	        "SF1",	"SF1/SF2-"+GetSX3Cache("F1_TPFRETE","X3_TITULO")})
aAdd(_aCampos,{"F1_I_PLACA",  "F2_I_PLACA",	        "SF1",	"SF1/SF2-"+GetSX3Cache("F1_I_PLACA","X3_TITULO")})
aAdd(_aCampos,{"F1_SEGURO",	  "F2_SEGURO",	        "SF1",	"SF1/SF2-"+GetSX3Cache("F1_SEGURO","X3_TITULO")})
aAdd(_aCampos,{"F1_VALMERC",  "F2_VALMERC",	        "SF1",	"SF1/SF2-"+GetSX3Cache("F1_VALMERC","X3_TITULO")})
aAdd(_aCampos,{"F1_FRETE",	  "F2_FRETE+F2_I_FRET", "SF1",  "SF1/SF2-"+GetSX3Cache("F1_FRETE","X3_TITULO")})
aAdd(_aCampos,{"F1_DESPESA",  "F2_DESPESA",	        "SF1",	"SF1/SF2-"+GetSX3Cache("F1_DESPESA","X3_TITULO")})
aAdd(_aCampos,{"F1_DESCONT",  "F2_DESCONT",	        "SF1",	"SF1/SF2-"+GetSX3Cache("F1_DESCONT","X3_TITULO")})
aAdd(_aCampos,{"F1_VALPEDG",  "0 F1_VALPEDG",       "SF1",	"SF1/SF2-"+GetSX3Cache("F1_VALPEDG","X3_TITULO")})

aAdd(_aCampos,{"F1_BASEICM",  "F2_BASEICM",         "SF1",	"SF1/SF2-"+GetSX3Cache("F1_BASEICM","X3_TITULO")})
aAdd(_aCampos,{"F1_VALICM",   "F2_VALICM",          "SF1",	"SF1/SF2-"+GetSX3Cache("F1_VALICM","X3_TITULO")})
aAdd(_aCampos,{"F1_BRICMS",   "F2_BRICMS",          "SF1",	"SF1/SF2-"+GetSX3Cache("F1_VALICM","X3_TITULO")})
aAdd(_aCampos,{"F1_ICMSRET",  "F2_ICMSRET",         "SF1",	"SF1/SF2-"+GetSX3Cache("F1_VALICM","X3_TITULO")})
aAdd(_aCampos,{"F1_BASEIPI",  "F2_BASEIPI",         "SF1",	"SF1/SF2-"+GetSX3Cache("F1_BASEIPI","X3_TITULO")})
aAdd(_aCampos,{"F1_VALIPI",   "F2_VALIPI",          "SF1",	"SF1/SF2-"+GetSX3Cache("F1_VALIPI","X3_TITULO")})
aAdd(_aCampos,{"F1_BASIMP5",  "F2_BASIMP5",         "SF1",	"SF1/SF2-"+GetSX3Cache("F1_BASIMP5","X3_TITULO")})
aAdd(_aCampos,{"F1_VALIMP5",  "F2_VALIMP5",         "SF1",	"SF1/SF2-"+GetSX3Cache("F1_VALIMP5","X3_TITULO")})
aAdd(_aCampos,{"F1_BASIMP6",  "F2_BASIMP6",         "SF1",	"SF1/SF2-"+GetSX3Cache("F1_BASIMP6","X3_TITULO")})
aAdd(_aCampos,{"F1_VALIMP6",  "F2_VALIMP6",         "SF1",	"SF1/SF2-"+GetSX3Cache("F1_VALIMP6","X3_TITULO")})
aAdd(_aCampos,{"F1_ISS",      "0 F2_ISS",           "SF1",	"SF1/SF2-"+GetSX3Cache("F1_ISS","X3_TITULO")})
aAdd(_aCampos,{"F1_BFCPANT",  "0 F2_BFCPANT",       "SF1",	"SF1/SF2-"+GetSX3Cache("F1_BFCPANT","X3_TITULO")})
aAdd(_aCampos,{"F1_VFCPANT",  "0 F2_VFCPANT",       "SF1",	"SF1/SF2-"+GetSX3Cache("F1_VFCPANT","X3_TITULO")})
aAdd(_aCampos,{"F1_BSFCPST",  "F2_BSFCPST",         "SF1",	"SF1/SF2-"+GetSX3Cache("F1_BSFCPST","X3_TITULO")})

aAdd(_aCampos,{"DS_SEGURO",	  "0 DS_SEGURO",	      "SDS",	"SDS-"+GetSX3Cache("DS_SEGURO","X3_TITULO")})
aAdd(_aCampos,{"DS_VALMERC",  "0 DS_VALMERC",	      "SDS",	"SDS-"+GetSX3Cache("DS_VALMERC","X3_TITULO")})
aAdd(_aCampos,{"DS_FRETE",	  "0 DS_FRETE",	        "SDS",	"SDS-"+GetSX3Cache("DS_FRETE","X3_TITULO")})
aAdd(_aCampos,{"DS_DESPESA",	"0 DS_DESPESA",       "SDS",	"SDS-"+GetSX3Cache("DS_FRETE","X3_TITULO")})
aAdd(_aCampos,{"DS_DESCONT",	"0 DS_DESCONT",       "SDS",	"SDS-"+GetSX3Cache("DS_DESCONT","X3_TITULO")})
aAdd(_aCampos,{"DS_VALPEDG",	"0 DS_VALPEDG",       "SDS",	"SDS-"+GetSX3Cache("DS_DESCONT","X3_TITULO")})

aAdd(_aCampos,{"XBASICM",	    "0 XBASICM",          "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_XBASICM","X3_TITULO")})//Base ICMS XML
aAdd(_aCampos,{"XMLICM",	    "0 XMLICM",           "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_XMLICM","X3_TITULO")})//Valor ICMS XML
aAdd(_aCampos,{"XBICST",	    "0 XBICST",           "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_XBICST","X3_TITULO")})//Base ICMS ST XML
aAdd(_aCampos,{"XMLICST",	    "0 XMLICST",          "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_XMLICST","X3_TITULO")})//Valor ICMS ST XML
aAdd(_aCampos,{"XBASIPI",	    "0 XBASIPI",          "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_XBASIPI","X3_TITULO")})//Base IPI XML
aAdd(_aCampos,{"XMLIPI",	    "0 XMLIPI",           "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_XMLIPI","X3_TITULO")})//Valor IPI XML
aAdd(_aCampos,{"XMLISS",	    "0 XMLISS",           "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_XMLISS","X3_TITULO")})//Valor ISS
aAdd(_aCampos,{"XBASPIS",	    "0 XBASPIS",          "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_XBASPIS","X3_TITULO")})//Base PIS XML
aAdd(_aCampos,{"XMLPIS",	    "0 XMLPIS",           "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_XMLPIS","X3_TITULO")})//Valor PIS XML
aAdd(_aCampos,{"XBASCOF",	    "0 XBASCOF",          "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_XBASCOF","X3_TITULO")})//Base Cofins XML
aAdd(_aCampos,{"XMLCOF",	    "0 XMLCOF",           "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_XMLCOF","X3_TITULO")})//Valor Cofins XML
aAdd(_aCampos,{"XBFCPAN",	    "0 XBFCPAN",          "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_XBFCPAN","X3_TITULO")})//Base FCP Ant
aAdd(_aCampos,{"XVFCPAN",	    "0 XVFCPAN",          "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_XVFCPAN","X3_TITULO")})//Valor FCP Ant
aAdd(_aCampos,{"XBFCPST",	    "0 XBFCPST",          "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_XBFCPST","X3_TITULO")})//Base FCP ST
aAdd(_aCampos,{"XVFCPST",	    "0 XVFCPST",          "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_XVFCPST","X3_TITULO")})//Valor FCP ST
aAdd(_aCampos,{"BASNDES",	    "0 BASNDES",          "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_BASNDES","X3_TITULO")})//Base ICMS ST Ant
aAdd(_aCampos,{"ICMNDES",	    "0 ICMNDES",          "SDT",	"SDT Tot NF -"+CRLF+GetSX3Cache("DT_ICMNDES","X3_TITULO")})//Valor ICMS ST Ant

aAdd(_aCampos,{"D1_CLASFIS",	"D2_CLASFIS",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_CLASFIS","X3_TITULO")})
aAdd(_aCampos,{"FT_VALCONT",  "FT_VALCONT",	        "SFT",	"SFT-"+GetSX3Cache("FT_VALCONT","X3_TITULO")})
aAdd(_aCampos,{"D1_BASEICM",	"D2_BASEICM",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_BASEICM","X3_TITULO")})
aAdd(_aCampos,{"D1_PICM",		  "D2_PICM",		        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_PICM","X3_TITULO")})
aAdd(_aCampos,{"D1_VALICM",	  "D2_VALICM",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_VALICM","X3_TITULO")})
aAdd(_aCampos,{"FT_ISENICM",  "FT_ISENICM",	        "SFT",	"SFT-"+GetSX3Cache("FT_ISENICM","X3_TITULO")})
aAdd(_aCampos,{"FT_OUTRICM",  "FT_OUTRICM",	        "SFT",	"SFT-"+GetSX3Cache("FT_OUTRICM","X3_TITULO")})
aAdd(_aCampos,{"D1_IPI",      "D2_IPI",	            "SD1",	"SD1/SD2-"+GetSX3Cache("D1_IPI","X3_TITULO")})
aAdd(_aCampos,{"D1_BASEIPI",	"D2_BASEIPI",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_BASEIPI","X3_TITULO")})
aAdd(_aCampos,{"D1_VALIPI",	  "D2_VALIPI",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_VALIPI","X3_TITULO")})
aAdd(_aCampos,{"FT_OUTRIPI",  "FT_OUTRIPI",	        "SFT",	"SFT-"+GetSX3Cache("FT_OUTRIPI","X3_TITULO")})
aAdd(_aCampos,{"D1_BRICMS",	  "D2_BRICMS",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_BRICMS","X3_TITULO")})
aAdd(_aCampos,{"D1_ICMSRET",	"D2_ICMSRET",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_ICMSRET","X3_TITULO")})
aAdd(_aCampos,{"D1_ICMSCOM",	"D2_ICMSCOM",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_ICMSCOM","X3_TITULO")})
aAdd(_aCampos,{"D1_ICMSDIF",	"D2_ICMSDIF",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_ICMSDIF","X3_TITULO")})
aAdd(_aCampos,{"FT_CTIPI",	  "FT_CTIPI",		        "SFT",	"SFT-"+GetSX3Cache("FT_CTIPI","X3_TITULO")})
aAdd(_aCampos,{"D1_BASEINS",	"D2_BASEINS",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_BASEINS","X3_TITULO")})
aAdd(_aCampos,{"D1_ALIQINS",	"D2_ALIQINS",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_ALIQINS","X3_TITULO")})
aAdd(_aCampos,{"D1_VALINS",	  "D2_VALINS",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_VALINS","X3_TITULO")})
aAdd(_aCampos,{"FT_POSIPI",	  "FT_POSIPI",	        "SD1",	"SD1/SD2-"+GetSX3Cache("FT_POSIPI","X3_TITULO")})

aAdd(_aCampos,{"D1_BASEPIS",	"D2_BASEPIS",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_BASEPIS","X3_TITULO")})
aAdd(_aCampos,{"D1_ALQPIS",	  "D2_ALQPIS",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_ALQPIS","X3_TITULO")})
aAdd(_aCampos,{"D1_VALPIS",	  "D2_VALPIS",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_VALPIS","X3_TITULO")})
aAdd(_aCampos,{"D1_BASIMP6",	"D2_BASIMP6",	        "SD1",	"SD1/SD2-Base PIS"})
aAdd(_aCampos,{"D1_ALQIMP6",	"D2_ALQIMP6",	        "SD1",	"SD1/SD2-Alq. PIS"})
aAdd(_aCampos,{"D1_VALIMP6",	"D2_VALIMP6",	        "SD1",	"SD1/SD2-Valor PIS"})

aAdd(_aCampos,{"D1_BASECOF",	"D2_BASECOF",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_BASECOF","X3_TITULO")})
aAdd(_aCampos,{"D1_ALQCOF",	  "D2_ALQCOF",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_ALQCOF","X3_TITULO")})
aAdd(_aCampos,{"D1_VALCOF",	  "D2_VALCOF",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_VALCOF","X3_TITULO")})
aAdd(_aCampos,{"D1_BASIMP5",	"D2_BASIMP5",	        "SD1",	"SD1/SD2-Base Cofins"})
aAdd(_aCampos,{"D1_ALQIMP5",	"D2_ALQIMP5",	        "SD1",	"SD1/SD2-Alq. Cofins"})
aAdd(_aCampos,{"D1_VALIMP5",	"D2_VALIMP5",	        "SD1",	"SD1/SD2-Valor Cofins"})

aAdd(_aCampos,{"D1_BASECSL",	"D2_BASECSL",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_BASECSL","X3_TITULO")})
aAdd(_aCampos,{"D1_ALQCSL",	  "D2_ALQCSL",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_ALQCSL","X3_TITULO")})
aAdd(_aCampos,{"D1_VALCSL",	  "D2_VALCSL",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_VALCSL","X3_TITULO")})
aAdd(_aCampos,{"FT_RECISS",	  "FT_RECISS",	        "SFT",	"SFT-"+GetSX3Cache("FT_RECISS","X3_TITULO")})
aAdd(_aCampos,{"D1_DESCZFR",	"D2_DESCZFR",	        "SD1",	"SD1-"+GetSX3Cache("D1_DESCZFR","X3_TITULO")})
aAdd(_aCampos,{"FT_CSTPIS",	  "FT_CSTPIS",	        "SFT",	"SFT-"+GetSX3Cache("FT_CSTPIS","X3_TITULO")})
aAdd(_aCampos,{"FT_CSTCOF",	  "FT_CSTCOF",	        "SFT",	"SFT-"+GetSX3Cache("FT_CSTCOF","X3_TITULO")})
aAdd(_aCampos,{"D1_BSSENAR",	"D2_BSSENAR",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_BSSENAR","X3_TITULO")})
aAdd(_aCampos,{"D1_ALSENAR",	"D2_ALSENAR",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_ALSENAR","X3_TITULO")})
aAdd(_aCampos,{"D1_VLSENAR",	"D2_VLSENAR",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_VLSENAR","X3_TITULO")})
aAdd(_aCampos,{"FT_INDISEN",  "FT_INDISEN",	        "SFT",	"SFT-"+GetSX3Cache("FT_INDISEN","X3_TITULO")})
aAdd(_aCampos,{"D1_BASEFUN",	"D2_BASEFUN",	        "SD1",	"SD1-"+GetSX3Cache("D1_BASEFUN","X3_TITULO")})
aAdd(_aCampos,{"D1_ALIQFUN",	"D2_ALIQFUN",	        "SD1",	"SD1-"+GetSX3Cache("D1_ALIQFUN","X3_TITULO")})
aAdd(_aCampos,{"D1_VALFUN",	  "D2_VALFUN",	        "SD1",	"SD1-"+GetSX3Cache("D1_VALFUN","X3_TITULO")})
aAdd(_aCampos,{"FT_CODBCC",	  "FT_CODBCC",	        "SFT",	"SFT-"+GetSX3Cache("FT_CODBCC","X3_TITULO")})
aAdd(_aCampos,{"D1_TNATREC",	"D2_TNATREC",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_TNATREC","X3_TITULO")})
aAdd(_aCampos,{"D1_CNATREC",	"D2_CNATREC",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_CNATREC","X3_TITULO")})
aAdd(_aCampos,{"D1_GRUPONC",	"D2_GRUPONC",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_GRUPONC","X3_TITULO")})
aAdd(_aCampos,{"D1_DTFIMNT",  "D2_DTFIMNT",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_DTFIMNT","X3_TITULO")})
aAdd(_aCampos,{"FT_CEST",	    "FT_CEST",            "SFT",	"SFT-"+GetSX3Cache("FT_CEST","X3_TITULO")})
aAdd(_aCampos,{"D1_BASEDES",	"D2_BASEDES",	        "SD1",	"SD1/SD2-"+GetSX3Cache("D1_BASEDES","X3_TITULO")})
aAdd(_aCampos,{"FT_BSICMOR",  "FT_BSICMOR",	        "SFT",	"SFT-"+GetSX3Cache("FT_BSICMOR","X3_TITULO")})
aAdd(_aCampos,{"DT_TOTAL",    "0 DT_TOTAL",	        "SDT",	"SDT-"+GetSX3Cache("DT_TOTAL","X3_TITULO")})
aAdd(_aCampos,{"DT_VALFRE",   "0 DT_VALFRE",        "SDT",	"SDT-"+GetSX3Cache("DT_VALFRE","X3_TITULO")})
aAdd(_aCampos,{"DT_SEGURO",   "0 DT_SEGURO",        "SDT",	"SDT-"+GetSX3Cache("DT_SEGURO","X3_TITULO")})
aAdd(_aCampos,{"DT_DESPESA",  "0 DT_DESPESA",       "SDT",	"SDT-"+GetSX3Cache("DT_DESPESA","X3_TITULO")})
aAdd(_aCampos,{"DT_VALDESC",  "0 DT_VALDESC",	      "SDT",	"SDT-"+GetSX3Cache("DT_VALDESC","X3_TITULO")})

aAdd(_aCampos,{"DT_CLASFIS",	"' ' DT_CLASFIS",	    "SDT",	"SDT-"+GetSX3Cache("DT_CLASFIS","X3_TITULO")})//Sit. Tributária
aAdd(_aCampos,{"DT_I_POSIP",  "'' DT_I_POSIP",      "SDT",	"SDT-"+GetSX3Cache("DT_I_POSIP","X3_TITULO")})//NCM
aAdd(_aCampos,{"DT_I_XCEST",  "'' DT_I_XCEST",      "SDT",	"SDT-"+GetSX3Cache("DT_I_XCEST","X3_TITULO")})//CEST
aAdd(_aCampos,{"DT_I_XFCI",   "'' DT_I_XFCI",       "SDT",	"SDT-"+GetSX3Cache("DT_I_XFCI","X3_TITULO")})//Código do Benefício
aAdd(_aCampos,{"C7_I_APLIC",  "'' C7_I_APLIC",      "SC7",	"SC7-"+GetSX3Cache("C7_I_APLIC","X3_TITULO")})
aAdd(_aCampos,{"C7_I_USOD",   "'' C7_I_USOD",       "SC7",	"SC7-"+GetSX3Cache("C7_I_USOD","X3_TITULO")})

aAdd(_aCampos,{"DT_XBASICM",  "0 DT_XBASICM",	      "SDT",	"SDT-"+GetSX3Cache("DT_XBASICM","X3_TITULO")}) //Base ICMS XML
aAdd(_aCampos,{"DT_XALQICM",  "0 DT_XALQICM",	      "SDT",	"SDT-"+GetSX3Cache("DT_XALQICM","X3_TITULO")}) //Aliq. ICMS XML
aAdd(_aCampos,{"DT_XMLICM",	  "0 DT_XMLICM",	      "SDT",	"SDT-"+GetSX3Cache("DT_XMLICM","X3_TITULO")}) //Valor ICMS XML

aAdd(_aCampos,{"DT_XBICST",   "0 DT_XBICST",	      "SDT",	"SDT-"+GetSX3Cache("DT_XBICST","X3_TITULO")}) //Base ICMS ST XML
aAdd(_aCampos,{"DT_XALICST",  "0 DT_XALICST",	      "SDT",	"SDT-"+GetSX3Cache("DT_XALICST","X3_TITULO")}) //Aliq. ICMS ST XML
aAdd(_aCampos,{"DT_XMLICST",  "0 DT_XMLICST",     	"SDT",	"SDT-"+GetSX3Cache("DT_XMLICST","X3_TITULO")}) //Valor ICMS ST XML

aAdd(_aCampos,{"DT_XBASIPI",  "0 DT_XBASIPI",	      "SDT",	"SDT-"+GetSX3Cache("DT_XBASIPI","X3_TITULO")})//Base IPI XML
aAdd(_aCampos,{"DT_XALQIPI",  "0 DT_XALQIPI",	      "SDT",	"SDT-"+GetSX3Cache("DT_XALQIPI","X3_TITULO")})//Aliq. IPI XML
aAdd(_aCampos,{"DT_XMLIPI",	  "0 DT_XMLIPI",	      "SDT",	"SDT-"+GetSX3Cache("DT_XMLIPI","X3_TITULO")})//Valor IPI XML

aAdd(_aCampos,{"DT_XALQISS",  "0 DT_XALQISS",	      "SDT",	"SDT-"+GetSX3Cache("DT_XALQISS","X3_TITULO")})//Aliq. ISS
aAdd(_aCampos,{"DT_XMLISS",	  "0 DT_XMLISS",	      "SDT",	"SDT-"+GetSX3Cache("DT_XMLISS","X3_TITULO")})//Valor ISS

aAdd(_aCampos,{"DT_I_XCPIS",  "'' DT_I_XCPIS",	    "SDT",	"SDT-"+GetSX3Cache("DT_I_XCPIS","X3_TITULO")})//CST PIS XML
aAdd(_aCampos,{"DT_XBASPIS",  "0 DT_XBASPIS",	      "SDT",	"SDT-"+GetSX3Cache("DT_XBASPIS","X3_TITULO")})//Base PIS XML
aAdd(_aCampos,{"DT_XALQPIS",  "0 DT_XALQPIS",	      "SDT",	"SDT-"+GetSX3Cache("DT_XALQPIS","X3_TITULO")})//Aliq. PIS XML
aAdd(_aCampos,{"DT_XMLPIS",	  "0 DT_XMLPIS",	      "SDT",	"SDT-"+GetSX3Cache("DT_XMLPIS","X3_TITULO")})//Valor PIS XML

aAdd(_aCampos,{"DT_I_XCCOF",  "'' DT_I_XCCOF",	    "SDT",	"SDT-"+GetSX3Cache("DT_I_XCCOF","X3_TITULO")})//CST Cofins XML
aAdd(_aCampos,{"DT_XBASCOF",  "0 DT_XBASCOF",	      "SDT",	"SDT-"+GetSX3Cache("DT_XBASCOF","X3_TITULO")})//Base Cofins XML
aAdd(_aCampos,{"DT_XALQCOF",  "0 DT_XALQCOF",	      "SDT",	"SDT-"+GetSX3Cache("DT_XALQCOF","X3_TITULO")})//Aliq. Cofins XML
aAdd(_aCampos,{"DT_XMLCOF",	  "0 DT_XMLCOF",	      "SDT",	"SDT-"+GetSX3Cache("DT_XMLCOF","X3_TITULO")})//Valor Cofins XML

aAdd(_aCampos,{"DT_XBFCPAN",  "0 DT_XBFCPAN",	      "SDT",	"SDT-"+GetSX3Cache("DT_XBFCPAN","X3_TITULO")})//Base FCP Ant
aAdd(_aCampos,{"DT_XAFCPAN",  "0 DT_XAFCPAN",	      "SDT",	"SDT-"+GetSX3Cache("DT_XAFCPAN","X3_TITULO")})//Aliq. FCP Ant
aAdd(_aCampos,{"DT_XVFCPAN",  "0 DT_XVFCPAN",	      "SDT",	"SDT-"+GetSX3Cache("DT_XVFCPAN","X3_TITULO")})//Valor FCP Ant

aAdd(_aCampos,{"DT_XBFCPST",  "0 DT_XBFCPST",	      "SDT",	"SDT-"+GetSX3Cache("DT_XBFCPST","X3_TITULO")})//Base FCP ST
aAdd(_aCampos,{"DT_XAFCPST",  "0 DT_XAFCPST",	      "SDT",	"SDT-"+GetSX3Cache("DT_XAFCPST","X3_TITULO")})//Aliq. FCP ST
aAdd(_aCampos,{"DT_XVFCPST",  "0 DT_XVFCPST",	      "SDT",	"SDT-"+GetSX3Cache("DT_XVFCPST","X3_TITULO")})//Valor FCP ST

aAdd(_aCampos,{"DT_BASNDES",  "0 DT_BASNDES",	      "SDT",	"SDT-"+GetSX3Cache("DT_BASNDES","X3_TITULO")})//Base ICMS ST Ant
aAdd(_aCampos,{"DT_ALQNDES",  "0 DT_ALQNDES",	      "SDT",	"SDT-"+GetSX3Cache("DT_ALQNDES","X3_TITULO")})//Aliq. ICMS ST Ant
aAdd(_aCampos,{"DT_ICMNDES",  "0 DT_ICMNDES",	      "SDT",	"SDT-"+GetSX3Cache("DT_ICMNDES","X3_TITULO")})//Valor ICMS ST Ant

//Monta string usada no Select para as duas partes da consulta de acordo com o array _aCampos. Apenas os campos da subconsulta devem ser informados
For _nY :=1 To 2
  For _nX := 1 To Len(_aCampos)
    If _aCampos[_nX][3] $ "SD2/SD1/SF2/SF1/SFT/SF3/SDT/SDS/SC7/SF4"
      &("_cCampos"+cvaltochar(_nY)) += _aCampos[_nX][_nY]+","
    EndIf
  Next _nX
  &("_cCampos"+cvaltochar(_nY)) += ' %'
Next _nY
//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RFIS008","Análise de documentos escriturados","RFIS008",;
{|oReport| ReportPrint(oReport,_aOrdem,_cCampos1,_cCampos2)},"Imprime todos os documentos que constam no Documento de entrada e/ou saída.")
oSection := TRSection():New(oReport,"Documentos",/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.F.)

//Definicoes da fonte utilizada
oReport:cFontBody := "Arial"
oReport:SetLineHeight(50)
oReport:nFontBody := 8
oReport:nXlsxTypeWrite:= 3
//Aqui iremos deixar como selecionado a opção Planilha, e iremos habilitar somente o formato de tabela
oReport:SetDevice(4) //Planilha
oReport:SetTpPlanilha({.F., .F., .T., .T.}) //Formato Tabela {Normal, Suprimir linhas brancas e totais, Formato de Tabela, Formato de Tabela xlsx}

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)

For _nX :=1 To Len(_aCampos)
	TRCell():New(oSection,_aCampos[_nX][01],_aCampos[_nX][03],_aCampos[_nX][04]/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
Next _nX

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 29/01/2019
Descrição---------: Processa dados do relatório
Parametros--------: oReport, _aOrdem
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem,_cCampos1,_cCampos2)

Local _cFilSD1		:= "%"
Local _cFilSD2		:= "%"
Local _cFilTot		:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-Agrupa por filial 2-Agrupa também por Setor

//Chama função que permitirá a seleção das filiais
If MV_PAR09 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"SFT")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

//=====================================================
// Adiciona a ordem escolhida ao titulo do relatorio  |
//=====================================================
oReport:SetTitle(oReport:Title() + " ("+AllTrim(_aOrdem[_nOrdem])+") ")

//==========================================================================
// Transforma parametros Range em expressao SQL                             	
//==========================================================================
MakeSqlExpr(oReport:uParam)

//================================================================================
//| Configuração das quebras do relatório                                        |
//================================================================================

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
//Normalmente não precisaria desse filtro pois o fonte trataria o agendamento independente da filial, porém, se For informado apenas a empresa, ele irá processar
//e disparar e-mail para todas as filiais que nem usam o leite. Se informar todas as filiais que usam o leite, ele processará todos ao mesmo tempo, ocupando todas as threads.
//Diante disso, travei para que sempre sejam processadas todas as filiais ao mesmo tempo, bastando agendar uma filial qualquer.
If !FWGetRunSchedule()
  _cFilSD1 += " AND D1_FILIAL "+ GetRngFil( _aSelFil, "SD1", .T.,)
  _cFilSD2 += " AND D2_FILIAL "+ GetRngFil( _aSelFil, "SD1", .T.,)
EndIf
If MV_PAR10 == 1//Entradas
	_cFilSD2 += " AND SD2.R_E_C_N_O_ = 0"
ElseIf MV_PAR10 == 2//Saídas
	_cFilSD1 += " AND SD1.R_E_C_N_O_ = 0"
EndIf
If !Empty(MV_PAR11)
	_cFilSD1 += " AND D1_CF IN " + FormatIn(MV_PAR11,";")
EndIf
If !Empty(MV_PAR13)
	_cFilSD2 += " AND D2_CF IN " + FormatIn(MV_PAR11,";")
EndIf
If MV_PAR12 == 1
	_cFilTot += " AND ERRO <> ' ' "
EndIf
_cFilTot += " %"
_cFilSD2 += " %"
_cFilSD1 += " %"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
	SELECT E2_NATUREZ,ENT.*,B1_DESC,BM_DESC,ED_DESCRIC,CTT_DESC01,BASE.*
  FROM (SELECT B.*,Case
          WHEN (TIPOMOV = 'E' AND D1_TIPO IN ('B', 'D')) OR (TIPOMOV = 'S' AND D1_TIPO NOT IN ('B', 'D'))THEN
          (SELECT E1_NATUREZ
            FROM %Table:SE1%
            WHERE D_E_L_E_T_ = ' '
            AND D1_FILIAL = E1_FILIAL
            AND D1_DOC = E1_NUM
            AND D1_SERIE = E1_PREFIXO
            AND D1_FORNECE = E1_CLIENTE
            AND D1_LOJA = E1_LOJA
            AND ROWNUM = 1)
          Else
          (SELECT E2_NATUREZ
            FROM %Table:SE2%
            WHERE D_E_L_E_T_ = ' '
            AND D1_FILIAL = E2_FILIAL
            AND D1_DOC = E2_NUM
            AND D1_SERIE = E2_PREFIXO
            AND D1_FORNECE = E2_FORNECE
            AND D1_LOJA = E2_LOJA
            AND ROWNUM = 1)
        END E2_NATUREZ,
      Case WHEN (TIPOMOV = 'E' AND STATUS = 'CLASSIFICADO') THEN 
        Case WHEN D1_CF NOT IN('1933','2933') AND (DS_VALMERC <> F1_VALMERC OR DS_FRETE <> F1_FRETE OR DS_SEGURO <> F1_SEGURO) THEN 'Mercadoria, frete e/ou seguro diferente do XML' 
        WHEN D1_CF IN ('1910','2910') AND D1_PEDIDO <> ' ' THEN 'Bonificacao com pedido vinculado'
        WHEN D1_TIPO <> 'I' AND D1_TOTAL+D1_VALFRE+D1_SEGURO+D1_DESPESA-D1_VALDESC+ DECODE(F4_INCIDE,'N',0,D1_VALIPI) <> D1_BASEICM AND SubStr(D1_CLASFIS,2,2) IN ('00','10') AND F4_BASEICM = 0 THEN 'Diferenca base de calculo/valor contabil para notas tributadas'
        WHEN D1_TIPO <> 'I' AND D1_TOTAL+D1_VALFRE+D1_SEGURO+D1_DESPESA-D1_VALDESC+ DECODE(F4_INCIDE,'N',0,D1_VALIPI) = D1_BASEICM AND SubStr(D1_CLASFIS,2,2) = '20' THEN 'Base de calculo igual valor contabil para situacoes com reducao'
        WHEN D1_TIPO <> 'I' AND D1_VALICM = 0 AND SubStr(D1_CLASFIS,2,2) IN ('00','10','20') THEN 'ICMS zerado'
        WHEN SubStr(D1_CLASFIS,2,2) = '40' AND (F4_CF NOT IN ('1352','1151','1920','1921','1203','1204','1916','1101','1949') 
            OR (F4_CF = '1949' AND D1_GRUPO <> '0813')
            OR (F4_CF = '1101' AND D1_COD NOT IN ('08000000004','08000000034','08000000062','08000000065'))
            ) THEN 'Operacao isenta com CST ou CFOP errado'
        WHEN D1_COD IN ('08070000004','08070000063') AND NOT ((D1_CF IN ('1101','1949') AND SubStr(D1_CLASFIS,2,2) = '90')
            OR (D1_CF IN ('2101','2949') AND SubStr(D1_CLASFIS,2,2) = '00')) THEN 'Nota de lenha com CST ou CFOP errado'
        WHEN SubStr(D1_CLASFIS,2,2) = '10' AND (D1_VALICM = 0 OR D1_ICMSRET = 0) THEN 'ICMS/ST incorreto - CST 10'
        WHEN SubStr(D1_CLASFIS,2,2) = '60' AND F4_CF IN ('1410','1411') AND D1_ICMSRET <> 0 THEN 'ICMS/ST incorreto - CST 60'          
        WHEN D1_SERIE NOT BETWEEN '890' AND '899' AND D1_SERIE NOT BETWEEN '910' AND '969' AND NOT (SubStr(D1_CLASFIS,2,2) IN ('40','90') AND F1_ESPECIE = 'CTE') 
          AND DT_XMLICM > 0  AND D1_VALICM = 0 THEN 'XML possui ICMS, mas o lançamento não'
        WHEN D1_SERIE NOT BETWEEN '890' AND '899' AND D1_SERIE NOT BETWEEN '910' AND '969' AND NOT (SubStr(D1_CLASFIS,2,2) IN ('40','90') AND F1_ESPECIE = 'CTE') 
          AND DT_XMLICST > 0 AND D1_ICMSRET = 0 THEN 'XML possui ICMS-ST, mas o lançamento não'
        WHEN SubStr(D1_FORNECE,1,1) IN ('T','C','G') AND F4_CF NOT IN ('1352') THEN 'CFOP errado para frete'
        WHEN SubStr(D1_FORNECE,1,1) NOT IN ('T','C','G') AND F4_CF IN ('1352') THEN 'CFOP indevido para frete'
        WHEN D1_CF = '2352' AND NOT ((SubStr(D1_CLASFIS,2,2) = '00' AND D1_VALICM > 0 AND D1_PICM > 0) 
            OR (SubStr(D1_CLASFIS,2,2) = '90' AND ((F4_COMPL = 'N' AND D1_VALICM = 0 AND D1_PICM = 0) OR F4_COMPL <> 'N' AND D1_VALICM > 0 AND D1_PICM > 0))
            ) THEN 'CST divergente da TES'
        WHEN F4_ICM = 'S' AND ((F4_BASEICM = 0 AND F4_LFICM = 'T') OR (F4_BASEICM > 0 AND F4_LFICM = 'O')) AND DT_XALQICM <> D1_PICM THEN 'Alíquota do ICMS do XML diferente do escriturado'
        /*WHEN XMLICM <> F1_VALICM THEN 'Valor do ICMS do XML diferente do escriturado'*/
        WHEN D1_VALIPI > 0 AND DT_XALQIPI <> D1_IPI THEN 'Alíquota do IPI do XML diferente do escriturado'
        /*WHEN XMLIPI <> F1_VALIPI THEN 'Valor do IPI do XML diferente do escriturado'*/
        WHEN F1_ESPECIE = 'CTE' AND D1_TIPO = 'C' AND D1_ALQIMP5 > 0 AND D1_ALQIMP5 <> 7.6 THEN 'CTe- Complementar com alíquota diferenciada'
        Else ' ' 
        END
      END ERRO
		 FROM (SELECT %exp:_cCampos1% 'E' TIPOMOV, DECODE (FT_FILIAL, NULL, 'NAO','SIM') GER_LIVRO, DECODE(DS_FILIAL,NULL,'NAO','SIM') COLAB, DECODE(F1_STATUS, 'A', 'CLASSIFICADO', 'PRE-NOTA') STATUS
          FROM %Table:SFT% SFT, %Table:SF3% SF3, %Table:SD1% SD1, %Table:SF1% SF1, %Table:SDS% SDS, %Table:SDT% SDT, %Table:SC7% SC7, %Table:SF4% SF4,
          (SELECT DT_FILIAL FILIAL, DT_DOC DOC, DT_SERIE SERIE, DT_FORNEC FORNEC, DT_LOJA LOJA, SUM(DT_XBASICM) XBASICM, SUM(DT_XMLICM) XMLICM, SUM(DT_XBICST) XBICST, 
            SUM(DT_XMLICST) XMLICST, SUM(DT_XBASIPI) XBASIPI, SUM(DT_XMLIPI) XMLIPI, SUM(DT_XMLISS) XMLISS, 
            SUM(DT_XBASPIS) XBASPIS, SUM(DT_XMLPIS) XMLPIS, SUM(DT_XBASCOF) XBASCOF, SUM(DT_XMLCOF) XMLCOF, SUM(DT_XBFCPAN) XBFCPAN, SUM(DT_XVFCPAN) XVFCPAN,
            SUM(DT_XBFCPST) XBFCPST, SUM(DT_XVFCPST) XVFCPST, SUM(DT_BASNDES) BASNDES, SUM(DT_ICMNDES) ICMNDES
            FROM %Table:SDT%
            WHERE D_E_L_E_T_ = ' '
            GROUP BY DT_FILIAL, DT_DOC, DT_SERIE, DT_FORNEC, DT_LOJA) SDTT
         WHERE SD1.D_E_L_E_T_ = ' '
           AND SF1.D_E_L_E_T_ = ' '
           AND SF4.D_E_L_E_T_(+) = ' '
           AND SFT.D_E_L_E_T_ (+)= ' '
           AND SF3.D_E_L_E_T_ (+)= ' '
           AND SDS.D_E_L_E_T_ (+)= ' '
           AND SDT.D_E_L_E_T_ (+)= ' '
           AND SC7.D_E_L_E_T_ (+)= ' '
           AND D1_FILIAL = F1_FILIAL
           AND D1_DOC = F1_DOC
           AND D1_SERIE = F1_SERIE
           AND D1_FORNECE = F1_FORNECE
           AND D1_LOJA = F1_LOJA
           AND FT_FILIAL (+)= D1_FILIAL
           AND FT_NFISCAL (+)= D1_DOC
           AND FT_SERIE (+)= D1_SERIE
           AND FT_CLIEFOR (+)= D1_FORNECE
           AND FT_LOJA (+)= D1_LOJA
           AND FT_ITEM (+)= D1_ITEM
           AND F3_FILIAL (+)= D1_FILIAL
           AND F3_NFISCAL (+)= D1_DOC
           AND F3_SERIE (+)= D1_SERIE
           AND F3_CLIEFOR (+)= D1_FORNECE
           AND F3_LOJA (+)= D1_LOJA
           AND FT_IDENTF3 = F3_IDENTFT
           AND DS_FILIAL (+)= D1_FILIAL
           AND DS_DOC (+)= D1_DOC
           AND DS_SERIE (+)= D1_SERIE
           AND DS_FORNEC (+)= D1_FORNECE
           AND DS_LOJA (+)= D1_LOJA
           AND FILIAL (+)= D1_FILIAL
           AND DOC (+)= D1_DOC
           AND SERIE (+)= D1_SERIE
           AND FORNEC (+)= D1_FORNECE
           AND LOJA (+)= D1_LOJA
           AND DT_FILIAL (+) = D1_FILIAL
           AND DT_DOC (+) = D1_DOC
           AND DT_SERIE (+) = D1_SERIE
           AND DT_FORNEC (+) = D1_FORNECE
           AND DT_LOJA (+) = D1_LOJA
           AND DT_ITEM (+) = D1_ITEM
           AND DT_COD (+) = D1_COD
           AND C7_FILIAL (+)= D1_FILIAL
           AND C7_NUM (+) = D1_PEDIDO
           AND C7_ITEM (+)= D1_ITEMPC
           AND F4_FILIAL(+) = D1_FILIAL
           AND F4_CODIGO(+) = D1_TES
           %exp:_cFilSD1%
           AND D1_DTDIGIT BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
           AND D1_EMISSAO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
           AND D1_FORNECE BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
           AND D1_LOJA BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR08%
           UNION ALL
           SELECT %exp:_cCampos2% 'S' TIPOMOV, DECODE (FT_FILIAL, NULL, 'NAO','SIM') GER_LIVRO, '' COLAB, '' STATUS
           FROM %Table:SFT% SFT, %Table:SF3% SF3, %Table:SD2% SD2, %Table:SF2% SF2, %Table:SF4% SF4
         WHERE SD2.D_E_L_E_T_ = ' '
           AND SF2.D_E_L_E_T_ = ' '
           AND SF4.D_E_L_E_T_(+) = ' '
           AND SFT.D_E_L_E_T_ (+)= ' '
           AND SF3.D_E_L_E_T_ (+)= ' '
           AND D2_FILIAL = F2_FILIAL
           AND D2_DOC = F2_DOC
           AND D2_SERIE = F2_SERIE
           AND D2_CLIENTE = F2_CLIENTE
           AND D2_LOJA = F2_LOJA
           AND FT_FILIAL (+)= D2_FILIAL
           AND FT_NFISCAL (+)= D2_DOC
           AND FT_SERIE (+)= D2_SERIE
           AND FT_CLIEFOR (+)= D2_CLIENTE
           AND FT_LOJA (+)= D2_LOJA
           AND FT_ITEM (+)= D2_ITEM
           AND F3_FILIAL (+)= D2_FILIAL
           AND F3_NFISCAL (+)= D2_DOC
           AND F3_SERIE (+)= D2_SERIE
           AND F3_CLIEFOR (+)= D2_CLIENTE
           AND F3_LOJA (+)= D2_LOJA
           AND FT_IDENTF3 = F3_IDENTFT
           AND F4_FILIAL(+) = D2_FILIAL
           AND F4_CODIGO(+) = D2_TES
           %exp:_cFilSD2%
           AND D2_EMISSAO BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
           AND D2_CLIENTE BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
           AND D2_LOJA BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR08%
           )B )BASE,
       (SELECT 'SA2' ENT,A2_COD,A2_LOJA,A2_NOME,A2_MUN,A2_CGC,A2_INSCR,A2_INSCRM,A2_CALCIRF,'' A1_SIMPNAC
          FROM %Table:SA2%
         WHERE D_E_L_E_T_ = ' '
        UNION ALL
        SELECT 'SA1' ENT,A1_COD,A1_LOJA,A1_NOME,A1_MUN,A1_CGC,A1_INSCR,A1_INSCRM,'' A1_CALCIRF,A1_SIMPNAC
          FROM %Table:SA1% 
         WHERE D_E_L_E_T_ = ' ') ENT,
       %Table:SB1% SB1, %Table:SBM% SBM, %Table:SED% SED, %Table:CTT% CTT
 WHERE SB1.D_E_L_E_T_ = ' '
   AND SBM.D_E_L_E_T_ = ' '
   AND SED.D_E_L_E_T_(+) = ' '
   AND CTT.D_E_L_E_T_(+) = ' '
   AND B1_COD = D1_COD
   AND B1_GRUPO = BM_GRUPO
   AND ED_CODIGO(+) = E2_NATUREZ
   AND CTT_CUSTO(+) = D1_CC
   AND D1_FORNECE = A2_COD
   AND D1_LOJA = A2_LOJA
   AND ENT = Case WHEN (TIPOMOV = 'E' AND D1_TIPO IN ('B', 'D')) OR(TIPOMOV = 'S' AND D1_TIPO NOT IN ('B', 'D')) THEN 'SA1' Else 'SA2' END
   %exp:_cFilTot%
EndSql
//==========================================================================
// Metodo EndQuery ( Classe TRSection )                                     
//                                                                          
// Prepara o relatório para executar o Embedded SQL.                        
//                                                                          
// ExpA1 : Array com os parametros do tipo Range                            
//                                                                          
//==========================================================================
oReport:Section(1):EndQuery(/*Array com os parametros do tipo Range*/)

//=======================================================================
//Impressao do Relatorio
//=======================================================================
oReport:Section(1):EndQuery(/*Array com os parametros do tipo Range*/)

//=======================================================================
//Impressao do Relatorio
//=======================================================================
oReport:Section(1):Init()
oReport:SetMsgPrint("Imprimindo")
oReport:SetMeter(0)

While !oReport:Cancel() .And. (_cAlias)->(!Eof())
	oReport:Section(1):PrintLine()
	oReport:IncMeter()
	//Mascara para impressao - CNPJ/CPF
	If RetPessoa((_cAlias)->A2_CGC) == "J"
		oReport:Section(1):Cell("A2_CGC"):SetPicture("@R! NN.NNN.NNN/NNNN-99")
	Else
		oReport:Section(1):Cell("A2_CGC"):SetPicture("@R 999.999.999-99")
	EndIf
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa----------: SchedDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 25/05/2017
Descrição---------: DefiniçStaticStatic Function SchedDef para o novo Schedule
					No novo Schedule existe uma forma para a definição dos Perguntes para o botão Parâmetros, além do cadastro 
					das funções no SXD. Ao definir em sua rotinStaticatic Function SchedDef(), no cadastro da rotina no Agenda-
					mento do Schedule será verificado se existe estStaticic Function e irá executá-la habilitando o botão Parâ-
					metros com as informações do retorno da SchedDef(), deixando de verificar assim as informações na SXD. O 
					retorno da SchedDef deverá ser um array.
					Válido para Function e User Function, lembrando que uma vez definido a SchedDef, ao chamar a rotina o ambi-
					ente já está inicializado.
					Uma vez definido a Static Function SchedDef(), a rotina deixa de ser uma execução como processo especial, 
					ou seja, não se deve cadastrá-la no Agendamento passando parâmetros de linha. Ex: Funcao("A","B") ou 
					U_Funcao("A","B").
Parametros--------: aReturn[1] - Tipo: "P" - para Processo, "R" -  para Relatórios
					aReturn[2] - Nome do Pergunte, caso nao use passar ParamDef
					aReturn[3] - Alias  (para Relatório)
					aReturn[4] - Array de ordem  (para Relatório)
					aReturn[5] - Título (para Relatório)
Retorno-----------: aParam
===============================================================================================================================
*/
Static Function SchedDef()

Local aParam  := {}
Local aOrd := {}

aParam := { "R",;
            "RFIS008",;
            "",;
            aOrd,;
            'Análise de documentos escriturados'}

Return aParam
