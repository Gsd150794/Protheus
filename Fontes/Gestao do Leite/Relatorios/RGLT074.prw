/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges |19/12/2023| Chamado 45906. Incluída amarração na ZZX para evitar duplicidade quando o mesmo produto possui 2 
              |          | tipos de cadsatro na ZA7. 
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT074
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 30/06/2023
Descrição---------: Relatório Análise Custo Contábil MIX - Chamado 44347
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT074

Local oReport
Pergunte("RGLT074",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 30/06/2023
Descrição---------: Processa a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Filial"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT074","Relatório Análise Custo Contábil MIX","RGLT074",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Apresenta o volume de leite entregue de acordo com o período informado.")
oSection := TRSection():New(oReport,"Dados"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total: "/*uTotalText*/)
oSection:SetTotalInLine(.F.)

//Aqui iremos deixar como selecionado a opção Planilha, e iremos habilitar somente o formato de tabela
oReport:SetDevice(4) //Planilha
oReport:SetTpPlanilha({.F., .F., .T., .T.}) //Formato Tabela {Normal, Suprimir linhas brancas e totais, Formato de Tabela, Formato de Tabela xlsx}

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"F1_FILIAL","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_DOC","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_SERIE","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_FORNECE","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_LOJA","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_EMISSAO","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_DTDIGIT","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_COD","SD1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_CUSTO","SD1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_TOTAL","SD1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOL",/*Table*/,"Volume"/*cTitle*/,GetSx3Cache("ZLD_QTDBOM","X3_PICTURE")/*Picture*/,GetSx3Cache("ZLD_QTDBOM","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,'RIGHT'/*cAlign*/,/*lLineBreak*/,'RIGHT'/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_L_MIX","SF1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLE_DTINI","ZLE"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLE_DTFIM","ZLE"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CT2_LOTE","CT2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CT2_DOC","CT2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CT2_LINHA","CT2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CT2_VALOR","CT2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CT2_DEBITO","CT2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CT1_DESC01","CT1"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CT2_HIST","CT2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CT2_CCD","CT2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CTT_DESC01","CTT"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CTT_I_UNIF","CTT"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CT2_ITEMD","CT2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)


Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 12/05/2023
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

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"SF1")
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
_cFiltro += GetRngFil( _aSelFil, "SF1", .T.,) += " %"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
SELECT F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_EMISSAO, F1_DTDIGIT, D1_COD, D1_CUSTO, D1_TOTAL, VOL, F1_L_MIX, ZLE_DTINI, ZLE_DTFIM, CT2_LOTE, 
       CT2_DOC, CT2_LINHA, CT2_VALOR, CT2_DEBITO, CT1_DESC01, CT1_I_UNIF, CT2_HIST, CT2_LP, CT2_ORIGEM, CT2_CCD, CTT_DESC01, CTT_I_UNIF, CT2_ITEMD
  FROM 
(SELECT F1_FILIAL, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_EMISSAO, F1_DTDIGIT, D1_COD, D1_CUSTO, D1_TOTAL, F1_L_MIX, D1_MSUIDT, ZLE_DTINI, ZLE_DTFIM, 
       Case
         WHEN SubStr(F1_FORNECE, 1, 1) = 'P' AND D1_ITEM = '0001' AND F1_L_SETOR <> ' ' THEN
          (SELECT NVL(SUM(ZLD_QTDBOM), 0)
             FROM %Table:ZLD% ZLD
            WHERE ZLD.D_E_L_E_T_ = ' '
              AND ZLD_FILIAL = F1_FILIAL
              AND ZLD_DTCOLE BETWEEN ZLE_DTINI AND ZLE_DTFIM
              AND F1_FILIAL = ZLD_FILIAL
              AND F1_FORNECE = ZLD_RETIRO
              AND F1_LOJA = ZLD_RETILJ
              AND F1_L_SETOR = ZLD_SETOR
              AND F1_L_LINHA = ZLD_LINROT)
         WHEN SubStr(F1_FORNECE, 1, 1) = 'P' AND D1_ITEM = '0001' AND F1_L_SETOR = ' ' THEN D1_QUANT Else 0 END VOL
  FROM %Table:SD1% SD1, %Table:SF1% SF1, %Table:ZLE% ZLE
 WHERE SD1.D_E_L_E_T_ = ' '
   AND SF1.D_E_L_E_T_ = ' '
   AND ZLE.D_E_L_E_T_ (+)= ' '
   AND F1_FILIAL = D1_FILIAL
   AND F1_DOC = D1_DOC
   AND F1_SERIE = D1_SERIE
   AND F1_FORNECE = D1_FORNECE
   AND F1_LOJA = D1_LOJA
   AND ZLE_COD (+)= F1_L_MIX
   AND F1_FILIAL %exp:_cFiltro%
   AND F1_STATUS = 'A'
   AND F1_DTDIGIT BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
   AND ((F1_L_MIX <> ' ' AND NOT EXISTS
        (SELECT 1 FROM %Table:ZZ4%
           WHERE D_E_L_E_T_ = ' '
             AND ZZ4_FILIAL = F1_FILIAL
             AND ZZ4_CODMIX = F1_L_MIX
             AND ZZ4_CODPRO = F1_FORNECE
             AND ZZ4_LOJPRO = F1_LOJA
             AND ZZ4_NUMCNF = F1_DOC
             AND ZZ4_SERIE = F1_SERIE)) 
        OR F1_FORNECE LIKE 'G%'
        OR (F1_ESPECIE = 'CTE' AND EXISTS
        (SELECT 1 FROM %Table:ZLX% ZLX, %Table:ZA7% ZA7, %Table:ZZX% ZZX
           WHERE ZLX.D_E_L_E_T_ = ' '
             AND ZA7.D_E_L_E_T_ = ' '
             AND ZZX.D_E_L_E_T_ = ' '
             AND ZLX_FILIAL = F1_FILIAL
             AND ZLX_TRANSP = F1_FORNECE
             AND ZLX_LJTRAN = F1_LOJA
             AND ZA7_FILIAL = ZLX_FILIAL
             AND ZA7_FILIAL = ZZX_FILIAL
             AND ZA7_TIPPRD = ZZX_CODPRD
             AND ZA7_CODPRD = ZLX_PRODLT
             AND ZZX_CODIGO = ZLX_CODANA
             AND ZLX_PGFRT = 'S'
             AND ZLX_TIPOLT = 'P'
             AND ZLX_ORIGEM = '3'
             AND ZA7_TIPPRD = '001'))
        )
   ) M, 
       (SELECT CT2_FILORI, CT2_LOTE, CT2_DOC, CT2_LINHA, CT2_VALOR, CT2_DEBITO, CT1_DESC01, CT1_I_UNIF, CT2_HIST, CT2_LP, CT2_ORIGEM, 
       CT2_CCD, CTT_DESC01, CTT_I_UNIF, CT2_ITEMD, RTRIM(CV3_IDORIG) CV3_IDORIG
       FROM %Table:CT2% CT2, %Table:CTT% CTT, %Table:CT1% CT1, %Table:CV3% CV3
       WHERE CT2.D_E_L_E_T_ = ' '
       AND CTT.D_E_L_E_T_(+) = ' '
       AND CT1.D_E_L_E_T_(+) = ' '
       AND CV3.D_E_L_E_T_ = ' '
       AND CT2.CT2_MSUIDT = RTRIM(CV3.CV3_IDDEST)
       AND CT2_CCD = CTT.CTT_CUSTO (+)
       AND CT2_DEBITO = CT1.CT1_CONTA (+)
       AND CT2_LOTE = '008810'
       AND CV3_LP = '650'
       AND CV3_LPSEQ = '002'
       AND CT2_DATA BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
       ) CTB
 WHERE 
D1_MSUIDT = CV3_IDORIG (+)

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
