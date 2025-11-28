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
Programa----------: RGLT057
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 25/11/2019
Descrição---------: Relatório CEPEA - Chamado 31287
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT057()

Local oReport
Pergunte("RGLT057",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 25/11/2019
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Por Filial"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT057","Relatório CEPEA","RGLT057",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Apresenta informações referente aos movimentos do produtor para apresentação ao CEPEA")
oSection := TRSection():New(oReport,"Movimentos"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem

oSection:SetTotalInLine(.T.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZLF_FILIAL","ZLF"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_COD","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_LOJA","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2"/*Table*/,"Setor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CC2_MUN","CC2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOLUME",/*Table*/,"Volume Mensal"/*cTitle*/,"@E 9,999,999,999"/*Picture*/,13/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VALOR",/*Table*/,"Valor Total"/*cTitle*/,"@E 9,999,999.99"/*Picture*/,12/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VALOR_LITRO",/*Table*/,"Valor Líquido"/*cTitle*/,"@E 99.9999"/*Picture*/,7/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOL_DIA",/*Table*/,"Volume Diário"/*cTitle*/,"@E 999,999"/*Picture*/,7/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 25/11/2019
Descrição---------: Processa impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro		:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-Agrupa por filial 2-Agrupa também por Setor
Local _cFilial		:= ""
Local _nCountRec	:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZLF")
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
oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZLF_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VALOR")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VALOR_LITRO")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOL_DIA")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZLF.ZLF_FILIAL "+ GetRngFil( _aSelFil, "ZLF", .T.,)
//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR03) .Or. Empty(MV_PAR03) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZLF.ZLF_SETOR IN "+ FormatIn( AllTrim(MV_PAR03) , ';' )
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR04)
	_cFiltro += " AND ZLF.ZLF_LINROT IN " + FormatIn(AllTrim(MV_PAR04),";")
EndIf

//Verifica se foi fornecido o Município
If !Empty(MV_PAR09)
	_cFiltro += " AND CC2.CC2_CODMUN IN " + FormatIn(AllTrim(MV_PAR09),";")
EndIf
_cFiltro += " %"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
	SELECT A.ZLF_FILIAL, A.A2_COD, A.A2_LOJA, A.A2_NOME, A.ZL2_COD, A.ZL2_DESCRI, A.CC2_MUN, A.VOLUME, A.VALOR,
	       DECODE( A.VOLUME,0,0,Round(A.VALOR / A.VOLUME, 4)) VALOR_LITRO,
	       Round(A.VOLUME / SubStr(A.ZLF_DTFIM, 7, 2), 0) VOL_DIA
	  FROM (SELECT ZLF.ZLF_FILIAL, ZLF.ZLF_DTINI, ZLF.ZLF_DTFIM, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, ZL2.ZL2_COD, ZL2.ZL2_DESCRI, CC2.CC2_MUN,
	               NVL((SELECT SUM(ZLD_QTDBOM)
	                     FROM %Table:ZLD% ZLD
	                    WHERE ZLD.D_E_L_E_T_ = ' '
	                      AND ZLD.ZLD_FILIAL = ZLF.ZLF_FILIAL
	                      AND ZLD.ZLD_DTCOLE BETWEEN ZLF.ZLF_DTINI AND ZLF.ZLF_DTFIM
	                      AND ZLD.ZLD_STATUS = 'F'
	                      AND ZLD.ZLD_RETIRO = SA2.A2_COD
	                      AND ZLD.ZLD_RETILJ = SA2.A2_LOJA
	                      AND ZLD.ZLD_SETOR = ZL2.ZL2_COD),
	                   0) VOLUME,
	               AVG((SELECT SUM(Case WHEN ZLF1.ZLF_DEBCRE = 'C' THEN ZLF1.ZLF_TOTAL Else ZLF1.ZLF_TOTAL * -1 END) VALOR
	                     FROM %Table:ZLF% ZLF1, %Table:ZL8% ZL8
	                    WHERE ZLF1.D_E_L_E_T_ = ' '
	                      AND ZL8.D_E_L_E_T_ = ' '
	                      AND ZLF1.ZLF_FILIAL = ZLF.ZLF_FILIAL
	                      AND ZLF1.ZLF_CODZLE = ZLF.ZLF_CODZLE
	                      AND ZLF1.ZLF_SETOR = ZL2.ZL2_COD
	                      AND ZLF1.ZLF_A2COD = SA2.A2_COD
	                      AND ZLF1.ZLF_A2LOJA = SA2.A2_LOJA
	                      AND ZLF1.ZLF_FILIAL = ZL8.ZL8_FILIAL
	                      AND ZLF1.ZLF_EVENTO = ZL8.ZL8_COD
	                      AND ZL8.ZL8_GRUPO <> '000003')) VALOR
	          FROM %Table:ZLF% ZLF, %Table:SA2% SA2, %Table:CC2% CC2, %Table:ZL2% ZL2
	         WHERE ZLF.D_E_L_E_T_ = ' '
	           AND SA2.D_E_L_E_T_ = ' '
	           AND CC2.D_E_L_E_T_ = ' '
	           AND ZL2.D_E_L_E_T_ = ' '
	           AND ZLF.ZLF_FILIAL = ZL2.ZL2_FILIAL
	           AND ZLF.ZLF_SETOR = ZL2.ZL2_COD
	           AND SA2.A2_COD = ZLF.ZLF_A2COD
	           AND SA2.A2_LOJA = ZLF.ZLF_A2LOJA
	           AND SA2.A2_EST = CC2.CC2_EST
	           AND SA2.A2_COD_MUN = CC2.CC2_CODMUN
	           %exp:_cFiltro%
	           AND ZLF.ZLF_CODZLE = %exp:MV_PAR02%
	           AND ZLF.ZLF_A2COD LIKE 'P%'
	           AND SA2.A2_COD BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
	           AND SA2.A2_LOJA BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR08%
	         GROUP BY ZLF.ZLF_FILIAL, ZLF.ZLF_DTINI, ZLF.ZLF_DTFIM, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, ZL2.ZL2_COD, ZL2.ZL2_DESCRI, CC2.CC2_MUN) A
	 ORDER BY A.ZLF_FILIAL, A.ZL2_COD, A.A2_COD, A.A2_LOJA
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
oReport:SetMeter(_nCountRec)

While !oReport:Cancel() .And. (_cAlias)->(!Eof())
	oReport:Section(1):PrintLine()
	oReport:IncMeter()
	_cFilial := (_cAlias)->ZLF_FILIAL
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
