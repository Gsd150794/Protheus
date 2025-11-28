/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT072
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 30/03/2023
Descrição---------: Relatório Mov. de Nfes - Cooperativas do Mix - Chamado 43437
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT072

Local oReport
Pergunte("RGLT072",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 30/03/2023
Descrição---------: Processa a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Filial x Emissao"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT072","Movimentos de Notas das Cooperativas Integradas ao Mix","RGLT072",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Apresenta a relação de notas fiscais que serão usadas para compor o valor do mix no fechamento.")
oSection := TRSection():New(oReport,"Dados"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total: "/*uTotalText*/)
oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"F1_FILIAL","SF1","Fil"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_EMISSAO","SF1"/*Table*/,"Data"+CRLF+"Emissão"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_DTDIGIT","SF1"/*Table*/,"Data"+CRLF+"Digitação"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TIPO",/*Table*/,"Tipo"/*cTitle*/,/*Picture*/,9/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_DOC","SF1"/*Table*/,"Número"+CRLF+"NF-e"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_SERIE","SF1"/*Table*/,"Série"+CRLF+"NF-e"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_COD","SA2"/*Table*/,"Código"+CRLF+"Fornecedor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2"/*Table*/,"Razão"+CRLF+"Social"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NREDUZ","SA2"/*Table*/,"Nome"+CRLF+"Fornecedor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_QUANT","SD1"/*Table*/,"Quantidade"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_VUNIT","SD1"/*Table*/,"Vlr."+CRLF+"Unitário"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"D1_TOTAL","SD1"/*Table*/,"Vlr."+CRLF+"Faturado"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_L_MIX","SF1"/*Table*/,"Mix"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 30/03/2023
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
Local _lPlanilha  := oReport:nDevice == 4

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
oQbrForn:= TRBreak():New( oReport:Section(1)/*oParent*/, {||oReport:Section(1):Cell("F1_FILIAL"):uPrint+oReport:Section(1):Cell("A2_COD"):uPrint} /*uBreak*/, {||"Total Mix " + _cAux } /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("D1_QUANT")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrForn/*oBreak*/,/*cTitle*/,/*cPicture*/,{||IIf(AllTrim(oReport:Section(1):Cell("TIPO"):uPrint) == 'NFE',oReport:Section(1):Cell("D1_QUANT"):uPrint*-1,oReport:Section(1):Cell("D1_QUANT"):uPrint)}/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("D1_VUNIT")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrForn/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/,/*oParent*/,{|| IIf( AllTrim(oReport:Section(1):Cell("TIPO"):uPrint) == 'NFE',.T., .F. ) }/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("D1_TOTAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrForn/*oBreak*/,/*cTitle*/,/*cPicture*/,{||IIf(AllTrim(oReport:Section(1):Cell("TIPO"):uPrint) == 'NFE',oReport:Section(1):Cell("D1_TOTAL"):uPrint*-1,oReport:Section(1):Cell("D1_TOTAL"):uPrint)}/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,.F./*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If !_lPlanilha
	oReport:Section(1):Cell("A2_NREDUZ"):Disable()
	oReport:Section(1):Cell("F1_L_MIX"):Disable()
EndIf

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
SELECT F1_FILIAL, F1_EMISSAO, F1_DTDIGIT, Case WHEN ORDEM = '1' THEN 'RECEPCAO' WHEN ORDEM = '2' THEN 'NFE' Else 'MIX'END TIPO,
       F1_DOC, F1_SERIE, A2_COD, A2_NOME, A2_NREDUZ, D1_QUANT,  D1_VUNIT, D1_TOTAL, F1_L_MIX
  FROM (SELECT F1_FILIAL, '2' ORDEM, F1_EMISSAO, F1_DTDIGIT, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA,
               SUM(D1_QUANT) D1_QUANT, SUM(D1_VUNIT) D1_VUNIT, SUM(D1_TOTAL) D1_TOTAL, F1_L_MIX
          FROM %Table:SD1% SD1, %Table:SF1% SF1
         WHERE SD1.D_E_L_E_T_ = ' '
           AND SF1.D_E_L_E_T_ = ' '
           AND F1_FILIAL = D1_FILIAL
           AND F1_DOC = D1_DOC
           AND F1_SERIE = D1_SERIE
           AND F1_FORNECE = D1_FORNECE
           AND F1_LOJA = D1_LOJA
           AND F1_L_MIX = %exp:MV_PAR02%
           AND F1_FORMUL = ' '
           AND F1_FILIAL %exp:_cFiltro%
           AND NOT EXISTS (SELECT 1 FROM %Table:ZZ4%
                 WHERE D_E_L_E_T_ = ' '
                   AND ZZ4_FILIAL = F1_FILIAL
                   AND ZZ4_CODMIX = F1_L_MIX
                   AND ZZ4_CODPRO = F1_FORNECE
                   AND ZZ4_LOJPRO = F1_LOJA
                   AND ZZ4_NUMCNF = F1_DOC
                   AND ZZ4_SERIE = F1_SERIE)
         GROUP BY F1_FILIAL, F1_EMISSAO, F1_DTDIGIT, F1_DOC, F1_SERIE, F1_FORNECE, F1_LOJA, F1_L_MIX
        UNION
        SELECT ZLD_FILIAL, '1' ORDEM, ZLD_DTCOLE, ZLD_DTLANC, '', '', ZLD_RETIRO, '0001', SUM(ZLD_QTDBOM) D1_QUANT, 0, 0, ZLE_COD
          FROM %Table:ZLD% ZLD, %Table:ZLE% ZLE
         WHERE ZLD.D_E_L_E_T_ = ' '
           AND ZLE.D_E_L_E_T_ = ' '
           AND ZLD_FILIAL %exp:_cFiltro%
           AND ZLE_COD = %exp:MV_PAR02%
           AND ZLD_DTCOLE BETWEEN ZLE_DTINI AND ZLE_DTFIM
         GROUP BY ZLD_FILIAL, ZLD_DTCOLE, ZLD_DTLANC, ZLD_RETIRO, ZLE_COD
        UNION
        SELECT ZLF_FILIAL, '3' ORDEM, '99999999', '99999999', '', '', ZLF_A2COD, '0001', 0, 0, SUM(ZLF_TOTAL) D1_TOTAL, ZLF_CODZLE
          FROM %Table:ZLF% ZLF
         WHERE D_E_L_E_T_ = ' '
           AND ZLF_DEBCRE = 'C'
           AND ZLF_TP_MIX = 'L'
           AND ZLF_ENTMIX = 'S'
           AND ZLF_FILIAL %exp:_cFiltro%
           AND ZLF_CODZLE = %exp:MV_PAR02%
         GROUP BY ZLF_FILIAL, ZLF_DTFIM, ZLF_A2COD, ZLF_CODZLE) MOV,
       %Table:SA2% SA2
 WHERE SA2.D_E_L_E_T_ = ' '
   AND F1_FORNECE = A2_COD
   AND F1_LOJA = A2_LOJA
   AND SA2.A2_L_NFPRO = 'S'
   AND A2_COD BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
 ORDER BY F1_FILIAL, F1_FORNECE, F1_EMISSAO, ORDEM
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
	_cAux := (_cAlias)->F1_L_MIX + " - " + (_cAlias)->A2_COD + " - " + (_cAlias)->A2_NOME
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
