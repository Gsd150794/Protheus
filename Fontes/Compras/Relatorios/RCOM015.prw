/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |06/09/2024| Chamado 48316. Incluído parâmetro para tratar CFOP.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RCOM015
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 31/07/2024
Descrição---------: Relatório de Descontos Tetra Pak
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM015

Local oReport
Pergunte("RCOM015",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 31/07/2024
Descrição---------: Processa a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Filial + Emissão"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RCOM015","Descontos Tetra Pak","RCOM015",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Apresenta os documentos de entrada e saída onde foram aplicados os descontos da Tetra Pak.")
oSection := TRSection():New(oReport,"Dados",/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.F.)

//Definicoes da fonte utilizada
oReport:cFontBody := "Arial"
oReport:SetLineHeight(50)
oReport:nFontBody := 8

//Aqui iremos deixar como selecionado a opção Planilha, e iremos habilitar somente o formato de tabela
oReport:SetDevice(4) //Planilha
oReport:SetTpPlanilha({.F., .F., .T., .T.}) //Formato Tabela {Normal, Suprimir linhas brancas e totais, Formato de Tabela, Formato de Tabela xlsx}

TRCell():New(oSection,"D1_FILIAL","SD1",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_DOC","SD1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_SERIE","SD1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_FORNECE","SD1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_LOJA","SD1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_EMISSAO","SD1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_DTDIGIT","SD1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_ITEM","SD1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_COD","SD1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"B1_DESC","SB1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_TOTAL","SD1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_CUSTO","SD1"/*Table*/,"Base Cálculo"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D3_CUSTO1","SD3"/*Table*/,"Total Desconto"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_VALIPI","SD1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_VALICM","SD1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_VALIMP5","SD1"/*Table*/,"PIS"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_VALIMP6","SD1"/*Table*/,"Cofins"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_VALDESC","SD1"/*Table*/,"Despesas acessórias"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZM5_AVD","ZM5"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZM5_QSR","ZM5"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZM5_SDESN","ZM5"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZM5_LAD","ZM5"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZM5_APD","ZM5"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZM5_CTD","ZM5"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 31/07/2024
Descrição---------: Processa a impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro    := "%"
Local _cAlias     := ""
Local _aSelFil    := {}
Local _nOrdem	    := oReport:Section(1):GetOrder()
Local _cCFOPE	    := "% AND D1_CF IN "+ FormatIn( AllTrim(SuperGetMV("IT_CFTETRE",.F.,"1101/2101/1122/2122")),'/') + "%"
Local _cCFOPS	    := "% AND D2_CF IN "+ FormatIn( AllTrim(SuperGetMV("IT_CFTETRS",.F.,"6201/5201")),'/') + "%"

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"SD1")
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
_cFiltro += GetRngFil( _aSelFil, "SD1", .T.,) += " %"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
  SELECT D1_FILIAL, D1_DOC, D1_SERIE, D1_FORNECE, D1_LOJA, D1_EMISSAO, D1_DTDIGIT, D1_ITEM, D1_COD, B1_DESC, D1_TOTAL, D1_CUSTO, D3_CUSTO1,
  D1_VALIPI, D1_VALICM, D1_VALIMP5, D1_VALIMP6, D1_VALDESC+D1_SEGURO+D1_DESPESA+D1_VALFRE D1_VALDESC,
  Round(D1_CUSTO*(ZM5_AVD)/100,6) ZM5_AVD,
  Round(D1_CUSTO*(ZM5_QSR)/100,6) ZM5_QSR,
  Round(D1_CUSTO*(ZM5_SDESN)/100,6) ZM5_SDESN,
  Round(D1_CUSTO*(ZM5_LAD)/100,6) ZM5_LAD,
  Round(D1_CUSTO*(ZM5_APD)/100,6) ZM5_APD,
  Round(D1_CUSTO*(ZM5_CTD)/100,6) ZM5_CTD
  FROM %Table:SD3% SD3, %Table:SD1% SD1, %Table:ZM5% ZM5, %Table:SB1% SB1
  WHERE SD3.D_E_L_E_T_ = ' '
  AND SD1.D_E_L_E_T_ = ' '
  AND ZM5.D_E_L_E_T_ = ' '
  AND SB1.D_E_L_E_T_ = ' '
  AND D1_COD = B1_COD
  AND D3_FILIAL %exp:_cFiltro%
  AND D3_EMISSAO BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
  AND D3_CHAVEF1 <> ' '
  AND D3_I_ORIGE = 'DESCTETRAE'
  AND D3_ESTORNO <> 'S'
  AND D1_COD = ZM5_PRODUT
  AND D3_FILIAL = ZM5_FILIAL
  AND D1_FILIAL = D3_FILIAL
  %exp:_cCFOPE%
  AND D1_EMISSAO BETWEEN ZM5_DTINI AND ZM5_DTFIM
  AND D1_FORNECE = 'F00004'
  AND D1_TIPO = 'N'
  AND D1_DOC||D1_SERIE||D1_FORNECE||D1_LOJA||D1_COD||D1_ITEM = TRIM(D3_CHAVEF1)
  UNION ALL
  SELECT D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA, D2_EMISSAO, D2_EMISSAO, D2_ITEM, D2_COD, B1_DESC, D2_TOTAL, D2_CUSTO1, D3_CUSTO1,
  D2_VALIPI, D2_VALICM, D2_VALIMP5, D2_VALIMP6, D2_DESCON+D2_SEGURO+D2_DESPESA+D2_VALFRE D1_VALDESC,
  Round(D2_CUSTO1*(ZM5_AVD)/100,6) ZM5_AVD,
  Round(D2_CUSTO1*(ZM5_QSR)/100,6) ZM5_QSR,
  Round(D2_CUSTO1*(ZM5_SDESN)/100,6) ZM5_SDESN,
  Round(D2_CUSTO1*(ZM5_LAD)/100,6) ZM5_LAD,
  Round(D2_CUSTO1*(ZM5_APD)/100,6) ZM5_APD,
  Round(D2_CUSTO1*(ZM5_CTD)/100,6) ZM5_CTD
  FROM %Table:SD3% SD3, %Table:SD2% SD2, %Table:ZM5% ZM5, %Table:SB1% SB1, %Table:SD1% SD1
  WHERE SD3.D_E_L_E_T_ = ' '
  AND SD2.D_E_L_E_T_ = ' '
  AND ZM5.D_E_L_E_T_ = ' '
  AND SB1.D_E_L_E_T_ = ' '
  AND SD1.D_E_L_E_T_ = ' '
  AND D1_FILIAL = D2_FILIAL
  AND D1_DOC = D2_NFORI
  AND D1_SERIE = D2_SERIORI
  AND D1_ITEM = D2_ITEMORI
  AND D1_FORNECE = D2_CLIENTE
  AND D1_LOJA = D2_LOJA
  AND D2_COD = B1_COD
  AND D3_FILIAL %exp:_cFiltro%
  AND D3_EMISSAO BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
  AND D3_CHAVEF1 <> ' '
  AND D3_I_ORIGE = 'DESCTETRAS'
  AND D3_ESTORNO <> 'S'
  AND D2_COD = ZM5_PRODUT
  AND D3_FILIAL = ZM5_FILIAL
  AND D2_FILIAL = D3_FILIAL
  %exp:_cCFOPS%
  AND D1_EMISSAO BETWEEN ZM5_DTINI AND ZM5_DTFIM
  AND D2_CLIENTE = 'F00004'
  AND D2_TIPO = 'N'
  AND D2_DOC||D2_SERIE||D2_CLIENTE||D2_LOJA||D2_COD||D2_ITEM = TRIM(D3_CHAVEF2)
  ORDER BY D1_FILIAL, D1_DTDIGIT, D1_DOC, D1_SERIE
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
oReport:Section(1):Init()
oReport:SetMsgPrint("Imprimindo")
oReport:SetMeter(0)

While !oReport:Cancel() .And. (_cAlias)->(!Eof())
	oReport:Section(1):PrintLine()
	oReport:IncMeter()
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
