/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |25/05/2022| Chamado 40238. Modifiado tratamento do Incentivo à Produção.
Lucas Borges  |15/03/2024| Chamado 46626. Substituida a coluna Total Base.
Lucas Borges  |30/09/2025| Chamado 52232. Corrigida amarração entre tabelas
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT066
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 10/07/2020
Descrição---------: Relatório Composição de Preços do Mix - Chamado 33479
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT066

Local oReport := Nil as Object
Pergunte("RGLT066",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 10/07/2020
Descrição---------: Processa a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef() As Object

Local oReport := Nil As Object
Local oSection:= Nil As Object
Local _aOrdem := {"Filial","Filial+Setor","Filial+Setor+Linha"} As Array

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT066","Composição de Preços do Mix","RGLT066",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Apresenta a Composição de preços do Mix, avaliando a ZLF.")
oSection := TRSection():New(oReport,"Movimentos"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZL2_FILIAL","ZL2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PROD",/*Table*/,"Produtor"/*cTitle*/,/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2"/*Table*/,"Setor"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_COD","ZL3"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_DESCRI","ZL3"/*Table*/,"Linha"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOLUME",/*Tabela*/,"Volume", "@E 9,999,999,999" ,13,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VLR_P_LITRO",/*Tabela*/,"Vlr p/Litro", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TOT_GERAL",/*Tabela*/,"Total Geral", "@E 9,999,999,999.99" ,16,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"LLIQSI",/*Tabela*/,"Total Bruto"+CRLF+"p/Litro", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TOT_LIQ",/*Tabela*/,"Tot Líq.", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"QUALIDADE",/*Tabela*/,"Qualidade", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"LEITE_COTA",/*Tabela*/,"Leite Cota", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"GORDURA",/*Tabela*/,"Gordura", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PROTEINA",/*Tabela*/,"Proteína", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CCS",/*Tabela*/,"CCS", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CBT",/*Tabela*/,"CBT", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"DES_GORD",/*Tabela*/,"Des.Gord", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"DES_PROT",/*Tabela*/,"Des.Prot", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"DES_CCS",/*Tabela*/,"Des.CCS", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"DES_CBT",/*Tabela*/,"Des.CBT", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"OUTRO_PAG",/*Tabela*/,"Outro Pag", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ADIC_MERDO",/*Tabela*/,"Adic.Merc", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ADIC_VOLUM",/*Tabela*/,"Adic.Vol", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"BONIF_LTE",/*Tabela*/,"Bonif.Lte", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"BONIF_EXTR",/*Tabela*/,"Bonif.Extr", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PGT_MG_CTL",/*Tabela*/,"Pgt.MG CTL", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PGT_MG",/*Tabela*/,"Pgt.MG", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"AJ_CUS_VET",/*Tabela*/,"Aj.Cus.Vet.", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"OUT_PG_IMP",/*Tabela*/,"Out.Pg.Imp", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"DIVERSOS",/*Tabela*/,"Diversos", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 10/07/2020
Descrição---------: Processa a impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport As Object,_aOrdem As Array)

Local _cFiltro	:= "%" As Character
Local _cAlias		:= "" As Character
Local _aSelFil	:= {} As Array
Local _nOrdem		:= oReport:Section(1):GetOrder() As Numeric
Local _lPlanilha:= oReport:nDevice == 4 As Logical
Local _cFilial	:= "" As Character
Local _cSetor		:= "" As Character
Local _cLinha		:= "" As Character
Local _nCountRec:= 0 As Numeric

//Chama função que permitirá a seleção das filiais
If MV_PAR02 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZL2")
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
If _nOrdem == 3
    oQbrLin	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL3_COD") /*uBreak*/, {||"Total da Linha: " + _cLinha} /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
    TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrLin/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("VLR_P_LITRO")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrLin/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("TOT_GERAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrLin/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("LLIQSI")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrLin/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("TOT_LIQ")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrLin/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
EndIf
If _nOrdem <> 1
    oQbrSet	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL2_COD") /*uBreak*/, {||"Total do Setor: " + _cSetor } /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
    TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("VLR_P_LITRO")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("TOT_GERAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("LLIQSI")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("TOT_LIQ")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
EndIf

oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL2_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VLR_P_LITRO")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("TOT_GERAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("LLIQSI")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("TOT_LIQ")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)


//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If !_lPlanilha
	oReport:Section(1):Cell("ZL2_COD"):Disable()
	oReport:Section(1):Cell("ZL2_DESCRI"):Disable()
	oReport:Section(1):Cell("ZL3_COD"):Disable()
	oReport:Section(1):Cell("ZL3_DESCRI"):Disable()
  oReport:Section(1):Cell("BONIF_LTE"):Disable()
  oReport:Section(1):Cell("BONIF_EXTR"):Disable()
  oReport:Section(1):Cell("PGT_MG_CTL"):Disable()
  oReport:Section(1):Cell("PGT_MG"):Disable()
  oReport:Section(1):Cell("AJ_CUS_VET"):Disable()
  oReport:Section(1):Cell("OUT_PG_IMP"):Disable()  
  oReport:Section(1):Cell("DIVERSOS"):SetBlock({||(_cAlias)->(BONIF_LTE+BONIF_EXTR+PGT_MG_CTL+PGT_MG+AJ_CUS_VET+OUT_PG_IMP+DIVERSOS) })
EndIf


//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZLF_FILIAL "+ GetRngFil( _aSelFil, "ZLF", .T.,)
//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR07) .Or. Empty(MV_PAR07) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZLF_SETOR IN "+ FormatIn( AllTrim(MV_PAR07) , ';' )
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR08)
	_cFiltro += " AND ZLF_LINROT IN " + FormatIn(AllTrim(MV_PAR08),";")
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
SELECT B.*,
       Round((TOT_CRED / DECODE(VOLUME,0,1,VOLUME)) + (TOT_IMP / DECODE(VOLUME,0,1,VOLUME)) - TOT_DEB, 4) TOT_LIQ,
       Round(TOT_GERAL / DECODE(VOLUME,0,1,VOLUME), 4) VLR_P_LITRO,
       Round((TOT_CRED  - TOT_DEB2) / DECODE(VOLUME,0,1,VOLUME), 4) LLIQSI
  FROM (SELECT ZL2_FILIAL, A2_COD||'-'||A2_LOJA PROD, A2_NOME, ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI,
               NVL((SELECT SUM(ZLD_QTDBOM)
                     FROM %Table:ZLD% ZLD
                    WHERE ZLD.D_E_L_E_T_ = ' '
                      AND ZLD_FILIAL = ZL2_FILIAL
                      AND ZLD_SETOR = ZL2_COD
                      AND ZLD_LINROT = ZL3_COD
                      AND ZLD_RETIRO = A2_COD
                      AND ZLD_RETILJ = A2_LOJA
                      AND ZLD_DTCOLE BETWEEN ZLE_DTINI AND ZLE_DTFIM),0) VOLUME,
               NVL((SELECT SUM(Case WHEN ZL8_DEBCRE = 'C' AND ZL8_QUALID = 'S' THEN ZLF_VLRLTR
                                WHEN ZL8_DEBCRE = 'D' AND ZL8_QUALID = 'S' THEN ZLF_VLRLTR * -1 END)
                     FROM %Table:ZLF% ZLF1, %Table:ZL8% ZL81
                    WHERE ZL81.D_E_L_E_T_ = ' '
                      AND ZLF1.D_E_L_E_T_ = ' '
                      AND ZLF1.ZLF_FILIAL = ZL81.ZL8_FILIAL
                      AND ZLF1.ZLF_EVENTO = ZL81.ZL8_COD
                      AND ZLF1.ZLF_FILIAL = ZL2_FILIAL
                      AND ZLF1.ZLF_A2COD = A2_COD
                      AND ZLF1.ZLF_A2LOJA = A2_LOJA
                      AND ZLF1.ZLF_SETOR = ZL2_COD
                      AND ZLF1.ZLF_LINROT = ZL3_COD
                      AND ZLF1.ZLF_CODZLE = ZLE_COD
                      AND ZLF1.ZLF_ENTMIX = 'S'),0) QUALIDADE,
               NVL((SELECT NVL(SUM(ZLF_TOTAL), 0)
                     FROM %Table:ZLF% ZLF2
                    WHERE ZLF2.D_E_L_E_T_ = ' '
                      AND ZLF2.ZLF_FILIAL = ZL2_FILIAL
                      AND ZLF2.ZLF_SETOR = ZL2_COD
                      AND ZLF2.ZLF_LINROT = ZL3_COD
                      AND ZLF2.ZLF_A2COD = A2_COD
                      AND ZLF2.ZLF_A2LOJA = A2_LOJA
                      AND ZLF2.ZLF_CODZLE = ZLE_COD
                      AND ZLF2.ZLF_TP_MIX = 'L'
                      AND ZLF2.ZLF_ENTMIX = 'S'
                      AND ZLF2.ZLF_DEBCRE = 'C'),0) TOT_CRED,
               NVL((SELECT SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else ZLF_TOTAL * -1 END)
                     FROM %Table:ZLF% ZLF4, %Table:ZL8% ZL84
                    WHERE ZLF4.D_E_L_E_T_ = ' '
                      AND ZL84.D_E_L_E_T_ = ' '
                      AND ZLF4.ZLF_FILIAL = ZL84.ZL8_FILIAL
                      AND ZLF4.ZLF_EVENTO = ZL84.ZL8_COD
                      AND ZLF4.ZLF_FILIAL = ZL2_FILIAL
                      AND ZLF4.ZLF_SETOR = ZL2_COD
                      AND ZLF4.ZLF_LINROT = ZL3_COD
                      AND ZLF4.ZLF_A2COD = A2_COD
                      AND ZLF4.ZLF_A2LOJA = A2_LOJA
                      AND ZLF4.ZLF_CODZLE = ZLE_COD
                      AND ZL84.ZL8_PERTEN = 'P'
                      AND ZL84.ZL8_GRUPO = '000007'),0) TOT_IMP,
               NVL((SELECT SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else ZLF_TOTAL * -1 END)
                     FROM %Table:ZLF% ZLF5
                    WHERE ZLF5.D_E_L_E_T_ = ' '
                      AND ZLF5.ZLF_FILIAL = ZL2_FILIAL
                      AND ZLF5.ZLF_SETOR = ZL2_COD
                      AND ZLF5.ZLF_LINROT = ZL3_COD
                      AND ZLF5.ZLF_RETIRO = A2_COD
                      AND ZLF5.ZLF_RETILJ = A2_LOJA
                      AND ZLF5.ZLF_CODZLE = ZLE_COD
                      AND ZLF5.ZLF_ENTMIX = 'S'),0) TOT_GERAL,
               NVL((SELECT NVL(SUM(ZLF_VLRLTR), 0)
                     FROM %Table:ZLF% ZLF6
                    WHERE ZLF6.D_E_L_E_T_ = ' '
                      AND ZLF6.ZLF_FILIAL = ZL2_FILIAL
                      AND ZLF6.ZLF_SETOR = ZL2_COD
                      AND ZLF6.ZLF_LINROT = ZL3_COD
                      AND ZLF6.ZLF_A2COD = A2_COD
                      AND ZLF6.ZLF_A2LOJA = A2_LOJA
                      AND ZLF6.ZLF_CODZLE = ZLE_COD
                      AND ZLF6.ZLF_DEBCRE = 'D'),0) TOT_DEB,
                NVL((SELECT NVL(SUM(ZLF_TOTAL), 0)
                     FROM ZLF010 ZLF2
                    WHERE ZLF2.D_E_L_E_T_ = ' '
                      AND ZLF2.ZLF_FILIAL = ZL2_FILIAL
                      AND ZLF2.ZLF_SETOR = ZL2_COD
                      AND ZLF2.ZLF_LINROT = ZL3_COD
                      AND ZLF2.ZLF_A2COD = A2_COD
                      AND ZLF2.ZLF_A2LOJA = A2_LOJA
                      AND ZLF2.ZLF_CODZLE = ZLE_COD
                      AND ZLF2.ZLF_TP_MIX = 'L'
                      AND ZLF2.ZLF_ENTMIX = 'S'
                      AND ZLF2.ZLF_DEBCRE = 'D'),0) TOT_DEB2,
               NVL(LEITE_COTA, 0) LEITE_COTA,
               NVL(GORDURA, 0) GORDURA,
               NVL(PROTEINA, 0) PROTEINA,
               NVL(CCS, 0) CCS,
               NVL(CBT, 0) CBT,
               NVL(DES_GORD, 0) DES_GORD,
               NVL(DES_PROT, 0) DES_PROT,
               NVL(DES_CCS, 0) DES_CCS,
               NVL(DES_CBT, 0) DES_CBT,
               NVL(OUTRO_PAG, 0) OUTRO_PAG,
               NVL(ADIC_MERDO, 0) ADIC_MERDO,
               NVL(ADIC_VOLUM, 0) ADIC_VOLUM,
               NVL(BONIF_LTE, 0) BONIF_LTE,
               NVL(BONIF_EXTR, 0) BONIF_EXTR,
               NVL(PGT_MG_CTL, 0) PGT_MG_CTL,
               NVL(PGT_MG, 0) PGT_MG,
               NVL(AJ_CUS_VET, 0) AJ_CUS_VET,
               NVL(OUT_PG_IMP, 0) OUT_PG_IMP,
               NVL(DIVERSOS, 0) DIVERSOS
          FROM (SELECT ZLF_FILIAL, ZLF_A2COD, ZLF_A2LOJA, ZLF_SETOR, ZLF_LINROT, ZLF_CODZLE,
                       Case
                         WHEN ZL8_NREDUZ = 'LEITE COTA' THEN 'LEITE_COTA'
                         WHEN ZL8_NREDUZ = 'GORDURA' THEN 'GORDURA'
                         WHEN ZL8_NREDUZ = 'PROTEINA' THEN 'PROTEINA'
                         WHEN ZL8_NREDUZ = 'CCS' THEN 'CCS'
                         WHEN ZL8_NREDUZ = 'CBT' THEN 'CBT'
                         WHEN ZL8_NREDUZ = 'DES.GORD' THEN 'DES_GORD'
                         WHEN ZL8_NREDUZ = 'DES.PROT' THEN 'DES_PROT'
                         WHEN ZL8_NREDUZ = 'DES.CCS' THEN 'DES_CCS'
                         WHEN ZL8_NREDUZ = 'DES.CBT' THEN 'DES_CBT'
                         WHEN ZL8_NREDUZ = 'OUTRO PAG' THEN 'OUTRO_PAG'
                         WHEN ZL8_NREDUZ = 'ADIC MERDO' THEN 'ADIC_MERDO'
                         WHEN ZL8_NREDUZ = 'ADIC VOLUM' THEN 'ADIC_VOLUM'
                         WHEN ZL8_NREDUZ = 'BONIF.LTE' THEN 'BONIF_LTE'
                         WHEN ZL8_NREDUZ = 'BONIF.EXTR' THEN 'BONIF_EXTR'
                         WHEN ZL8_NREDUZ = 'PGT.MG CTL' THEN 'PGT_MG_CTL'
                         WHEN ZL8_NREDUZ = 'PGT.MG' THEN 'PGT_MG'
                         WHEN ZL8_NREDUZ = 'AJ.CUS.VET' THEN 'AJ_CUS_VET'
                         WHEN ZL8_NREDUZ = 'OUT PG IMP' THEN 'OUT_PG_IMP'
                         Else'DIVERSOS' END EVENTO,
                       ZLF_VLRLTR
                  FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
                 WHERE ZL8.D_E_L_E_T_ = ' '
                   AND ZLF.D_E_L_E_T_ = ' '
                   AND ZLF_FILIAL = ZL8_FILIAL
                   AND ZLF_EVENTO = ZL8_COD
                   %exp:_cFiltro%
                   AND ZLF_CODZLE = %exp:MV_PAR01%
                   AND ZLF_A2COD LIKE 'P%'
                   AND ZLF_A2COD BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR05%
                   AND ZLF_A2LOJA BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR06%
                   AND ZLF_ENTMIX = 'S')
        PIVOT(SUM(ZLF_VLRLTR)
           For EVENTO IN('LEITE_COTA' LEITE_COTA,
                        'GORDURA' GORDURA,
                        'PROTEINA' PROTEINA,
                        'CCS' CCS,
                        'CBT' CBT,
                        'DES_GORD' DES_GORD,
                        'DES_PROT' DES_PROT,
                        'DES_CCS' DES_CCS,
                        'DES_CBT' DES_CBT,
                        'OUTRO_PAG' OUTRO_PAG,
                        'ADIC_MERDO' ADIC_MERDO,
                        'ADIC_VOLUM' ADIC_VOLUM,
                        'BONIF_LTE' BONIF_LTE,
                        'BONIF_EXTR' BONIF_EXTR,
                        'PGT_MG_CTL' PGT_MG_CTL,
                        'PGT_MG' PGT_MG,
                        'AJ_CUS_VET' AJ_CUS_VET,
                        'OUT_PG_IMP' OUT_PG_IMP,
                        'DIVERSOS' DIVERSOS)) A, %Table:ZLE% ZLE, %Table:ZL2% ZL2, %Table:ZL3% ZL3, %Table:SA2% SA2
         WHERE ZLE.D_E_L_E_T_ = ' '
           AND ZL2.D_E_L_E_T_ = ' '
           AND ZL3.D_E_L_E_T_ = ' '
           AND SA2.D_E_L_E_T_ = ' '
           AND A.ZLF_CODZLE = ZLE_COD
           AND ZL2_FILIAL = A.ZLF_FILIAL
           AND ZL3_FILIAL = A.ZLF_FILIAL
           AND ZL2_COD = A.ZLF_SETOR
           AND ZL3_COD = A.ZLF_LINROT
           AND A2_COD = A.ZLF_A2COD
           AND A2_LOJA = A.ZLF_A2LOJA) B
ORDER BY ZL2_FILIAL, ZL2_COD, ZL3_COD, PROD
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
Count To _nCountRec
(_cAlias)->( DBGoTop() )
oReport:SetMsgPrint("Imprimindo")
oReport:SetMeter(_nCountRec)

While !oReport:Cancel() .And. (_cAlias)->(!Eof())
	oReport:Section(1):PrintLine()
	oReport:IncMeter()
	_cFilial := (_cAlias)->ZL2_FILIAL
	_cSetor	:= (_cAlias)->ZL2_COD + ' - ' + (_cAlias)->ZL2_DESCRI
   _cLinha	:= (_cAlias)->ZL3_COD + ' - ' + (_cAlias)->ZL3_DESCRI
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
