/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |26/07/2019| Chmamado 28346. Corrigida a barra de progresso.
Lucas Borges  |09/10/2019| Chamado 30812. Corrigido error.log na impressão.
Lucas Borges  |30/10/2019| Chamado 31033. Ajustada análise da faixa por Volume.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT029
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 19/05/2019
Descrição---------: Relatório de Produção por Faixa
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT029()

Local oReport
Pergunte("RGLT029",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 29/05/2019
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Por Filial X Faixa"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT029","Relatório de Produção por Faixa","RGLT029",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Agrupa os produtores de acordo com a faixa do evento desejato")
oSection := TRSection():New(oReport,"Faixas"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)

oReport:SetLandscape( )//Define como Paisagem
oSection:SetTotalInLine(.F.)//Define se os totalizadores serão impressos em linha ou coluna

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZLD_FILIAL","ZLD","Fil"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2","Setor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2",/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_COD","ZL3","Linha"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_DESCRI","ZL3",/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_COD","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_LOJA","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2","Produtor"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOL_BRUT",/*Tabela*/,"Vol Bruto"/*cTitle*/,"@E 9,999,999"/*Picture*/,9/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOL_CRI",/*Tabela*/,"Vol Desc"/*cTitle*/,"@E 9,999,999"/*Picture*/,9/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOL_LIQ",/*Tabela*/,"Vol Liq"/*cTitle*/,"@E 9,999,999"/*Picture*/,9/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL9_COD","ZL9",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL9_DESCRI","ZL9",/*cTitle*/,/*Picture*/,20/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"FAIXA",/*Tabela*/,"Faixa"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"MEDIA",/*Tabela*/,"Média"/*cTitle*/,"@E 9,999.9999"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 29/05/2019
Descrição---------: Realiza a impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro		:= "%"
Local _cAlias		:= ""
Local _cAlias2		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-Agrupa por filial 2-Agrupa também por Setor
Local _cFilial		:= ""
Local _cFaixa		:= ""
Local _lPlanilha 	:= oReport:nDevice == 4
Local _nAux			:=0
Local _nOk			:=0
Local _nX			:=0
Local _nMed			:=0
Local _aStru		:= {}
Local _nCountRec	:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR09 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZLD")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

//====================================================
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
oQbrFaixa	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("FAIXA") /*uBreak*/, {||"Total da Faixa: " + _cFaixa} /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("A2_COD")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrFaixa/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOL_BRUT")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFaixa/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOL_CRI")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFaixa/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOL_LIQ")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFaixa/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("MEDIA")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFaixa/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZLD_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("A2_COD")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOL_BRUT")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOL_CRI")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOL_LIQ")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("MEDIA")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If !_lPlanilha
//	oReport:Section(1):Cell("ZL3_COD"):Disable()
//	oReport:Section(1):Cell("ZL3_DESCRI"):Disable()
//	oReport:Section(1):Cell("ZL2_COD"):Disable()
//	oReport:Section(1):Cell("ZL2_DESCRI"):Disable()
//	oReport:Section(1):Cell("ZL9_COD"):Disable()
//	oReport:Section(1):Cell("ZL9_DESCRI"):Disable()
	oReport:Section(1):Cell("FAIXA"):Disable()
EndIf

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZLD.ZLD_FILIAL "+ GetRngFil( _aSelFil, "ZLD", .T.,)
 
//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR01) .Or. Empty(MV_PAR01) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZL2.ZL2_COD IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR10)
	_cFiltro += " AND ZL3.ZL3_COD IN " + FormatIn(MV_PAR10,";")
EndIf

//Verifica se foi fornecido o filtro de Faixa
If !Empty(MV_PAR08)
	_cFiltro += " AND ZL9.ZL9_COD IN "+ FormatIn( AllTrim(MV_PAR08) , ';' )
EndIf

_cFiltro += "%"

//==========================================================================
// Query para tabela temporária onde calcularemos as médias e faixas
//==========================================================================
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
SELECT ZLD.ZLD_FILIAL, ZL2.ZL2_COD, ZL2.ZL2_DESCRI, ZL3.ZL3_COD, ZL3.ZL3_DESCRI, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, 
		ZL9.ZL9_COD, ZL9.ZL9_DESCRI, ZL9.ZL9_MEDIA,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM ZLB010 ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
                      AND ZLB1.ZLB_TIPOFX = ZL9.ZL9_COD)
            WHERE LINHA = 1),
           0) P01_01,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM ZLB010 ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
                      AND ZLB1.ZLB_TIPOFX = ZL9.ZL9_COD)
            WHERE LINHA = 2),
           0) P01_02,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM ZLB010 ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
                      AND ZLB1.ZLB_TIPOFX = ZL9.ZL9_COD)
            WHERE LINHA = 3),
           0) P01_03,
       NVL((SELECT SUM(ZLD_QTDBOM)
             FROM ZLD010 A
            WHERE A.D_E_L_E_T_ = ' '
              AND A.ZLD_FILIAL = ZLD.ZLD_FILIAL
              AND A.ZLD_RETIRO = SA2.A2_COD
              AND A.ZLD_RETILJ = SA2.A2_LOJA
              AND A.ZLD_SETOR = ZL2.ZL2_COD
              AND A.ZLD_DTCOLE BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%),
           0) VOL_BRUT,
       NVL((SELECT SUM(ZLB_VOLCRI)
             FROM ZLB010 A
            WHERE A.D_E_L_E_T_ = ' '
              AND A.ZLB_FILIAL = ZLD.ZLD_FILIAL
              AND A.ZLB_RETIRO = SA2.A2_COD
              AND A.ZLB_RETILJ = SA2.A2_LOJA
              AND A.ZLB_SETOR = ZL2.ZL2_COD
              AND A.ZLB_TIPOFX IN ('000012', '000013')
              AND A.ZLB_DATA BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%),
           0) VOL_CRI
  FROM %Table:ZLD% ZLD, %Table:SA2% SA2, %Table:ZL2% ZL2, %Table:ZL3% ZL3, %Table:ZLB% ZLB, %Table:ZL9% ZL9
 WHERE ZLD.D_E_L_E_T_ = ' '
   AND SA2.D_E_L_E_T_ = ' '
   AND ZL2.D_E_L_E_T_ = ' '
   AND ZL3.D_E_L_E_T_ = ' '
   AND ZLB.D_E_L_E_T_ (+)= ' '
   AND ZL9.D_E_L_E_T_ = ' '
   AND ZLD.ZLD_FILIAL = ZL9.ZL9_FILIAL
   AND ZLB.ZLB_FILIAL (+)= ZLD.ZLD_FILIAL
   AND ZLD.ZLD_FILIAL = ZL2.ZL2_FILIAL
   AND ZLD.ZLD_FILIAL = ZL3.ZL3_FILIAL
   AND ZLD.ZLD_RETIRO BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
   AND ZLD.ZLD_RETILJ BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
   AND SA2.A2_COD = ZLD.ZLD_RETIRO
   AND SA2.A2_LOJA = ZLD.ZLD_RETILJ
   AND ZLB.ZLB_RETIRO (+)= ZLD.ZLD_RETIRO
   AND ZLB.ZLB_RETILJ (+)= ZLD.ZLD_RETILJ
   AND ZLB.ZLB_SETOR (+)= ZL2.ZL2_COD
   AND ZL2.ZL2_COD = ZLD.ZLD_SETOR
   AND ZL3.ZL3_COD = ZLD.ZLD_LINROT
   AND ZLB.ZLB_TIPOFX (+)= ZL9.ZL9_COD
   %exp:_cFiltro%
   AND ZLB.ZLB_DATA (+) BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
   AND ZLD.ZLD_DTCOLE BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
 GROUP BY ZLD.ZLD_FILIAL, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, ZL2.ZL2_COD, ZL2.ZL2_DESCRI, 
       ZL3.ZL3_COD, ZL3.ZL3_DESCRI, ZL9.ZL9_COD, ZL9.ZL9_DESCRI, ZL9.ZL9_MEDIA
EndSql

//----------------------------------------------------------------------
// Montra estrutura para ser usada na tabela temporária
//----------------------------------------------------------------------
aAdd(_aStru,{"ZLD_FILIAL"	,"C",GetSX3Cache("ZLD_FILIAL","X3_TAMANHO"),00})
aAdd(_aStru,{"ZL2_COD"		,"C",GetSX3Cache("ZL2_COD","X3_TAMANHO"),00})
aAdd(_aStru,{"ZL2_DESCRI"	,"C",GetSX3Cache("ZL2_DESCRI","X3_TAMANHO"),00})
aAdd(_aStru,{"ZL3_COD"		,"C",GetSX3Cache("ZL3_COD","X3_TAMANHO"),00})
aAdd(_aStru,{"ZL3_DESCRI"	,"C",GetSX3Cache("ZL3_DESCRI","X3_TAMANHO"),00})
aAdd(_aStru,{"A2_COD"		,"C",GetSX3Cache("A2_COD","X3_TAMANHO"),00})
aAdd(_aStru,{"A2_LOJA"		,"C",GetSX3Cache("A2_LOJA","X3_TAMANHO"),00})
aAdd(_aStru,{"A2_NOME"		,"C",GetSX3Cache("A2_NOME","X3_TAMANHO"),00})
aAdd(_aStru,{"ZL9_COD"		,"C",GetSX3Cache("ZL9_COD","X3_TAMANHO"),00})
aAdd(_aStru,{"ZL9_DESCRI"	,"C",GetSX3Cache("ZL9_DESCRI","X3_TAMANHO"),00})
aAdd(_aStru,{"ZL9_MEDIA"	,"C",GetSX3Cache("ZL9_MEDIA","X3_TAMANHO"),00})
aAdd(_aStru,{"MEDIA"		,"N",GetSX3Cache("ZLB_VLRFX","X3_TAMANHO"),GetSX3Cache("ZLB_VLRFX","X3_DECIMAL")})
aAdd(_aStru,{"P01_01"		,"N",GetSX3Cache("ZLB_VLRFX","X3_TAMANHO"),GetSX3Cache("ZLB_VLRFX","X3_DECIMAL")})
aAdd(_aStru,{"P01_02"		,"N",GetSX3Cache("ZLB_VLRFX","X3_TAMANHO"),GetSX3Cache("ZLB_VLRFX","X3_DECIMAL")})
aAdd(_aStru,{"P01_03"		,"N",GetSX3Cache("ZLB_VLRFX","X3_TAMANHO"),GetSX3Cache("ZLB_VLRFX","X3_DECIMAL")})
aAdd(_aStru,{"VOL_BRUT"		,"N",08,00})
aAdd(_aStru,{"VOL_CRI"		,"N",08,00})

_cAlias2 := GetNextAlias()
// Cria arquivo de dados temporário
_oTempTable := FWTemporaryTable():New( _cAlias2, _aStru )
_oTempTable:AddIndex( "01", {"ZLD_FILIAL", "ZL2_COD", "ZL9_COD", "MEDIA"} )
_oTempTable:Create()

Count To _nCountRec
(_cAlias)->( DBGoTop() )
oReport:SetMsgPrint("Processando")
oReport:SetMeter(_nCountRec)

While (_cAlias)->(!Eof())
	_nMed:=0
	_nAux:=0
	_nOk:=0
	If (_cAlias)->ZL9_COD == '000010'//Volume - tratamento diferenciado pois a origem das informações não está na ZLB
		_nMed := Round(((_cAlias)->VOL_BRUT-(_cAlias)->VOL_CRI)/(MV_PAR07-MV_PAR06),0)
	Else
		//Busco as 3 possíveis coletas dentro do mesmo mês e calculo a média
		For _nX:=1 To 3
			_nAux:=(_cAlias)->&("P01_0"+cValToChar(_nX))
			IIf((_cAlias)->ZL9_MEDIA=="G",IIf(_nAux != 0,IIf(_nMed != 0,_nMed*=_nAux,_nMed+=_nAux),),_nMed+=_nAux)
			IIf(_nAux != 0,_nOk++,)
		Next _nX
		_nMed := IIf(_nOk != 0, IIf((_cAlias)->ZL9_MEDIA=="G",_nMed^(1/_nOk),_nMed/_nOk),0)
	EndIf
	//Gravo informações na tabela temporária
	RecLock(_cAlias2,.T.)
		(_cAlias2)->ZLD_FILIAL:= (_cAlias)->ZLD_FILIAL
		(_cAlias2)->ZL2_COD:= (_cAlias)->ZL2_COD
		(_cAlias2)->ZL2_DESCRI:= (_cAlias)->ZL2_DESCRI
		(_cAlias2)->ZL3_COD:= (_cAlias)->ZL3_COD
		(_cAlias2)->ZL3_DESCRI:= (_cAlias)->ZL3_DESCRI
		(_cAlias2)->A2_COD:= (_cAlias)->A2_COD
		(_cAlias2)->A2_LOJA:= (_cAlias)->A2_LOJA
		(_cAlias2)->A2_NOME:= (_cAlias)->A2_NOME
		(_cAlias2)->ZL9_COD:= (_cAlias)->ZL9_COD
		(_cAlias2)->ZL9_DESCRI:= (_cAlias)->ZL9_DESCRI
		(_cAlias2)->ZL9_MEDIA:= (_cAlias)->ZL9_MEDIA
		(_cAlias2)->MEDIA:= _nMed //Média
		(_cAlias2)->P01_01:= (_cAlias)->P01_01
		(_cAlias2)->P01_02:= (_cAlias)->P01_02
		(_cAlias2)->P01_03:= (_cAlias)->P01_03
		(_cAlias2)->VOL_BRUT:= (_cAlias)->VOL_BRUT
		(_cAlias2)->VOL_CRI:= (_cAlias)->VOL_CRI
	MSUnLock()

	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

_cAlias := GetNextAlias()
_cFiltro := "% " +_oTempTable:GetRealName() + " %"
BeginSql alias _cAlias
	SELECT A.*, A.VOL_BRUT-A.VOL_CRI VOL_LIQ, A.ZL9_COD||'-'||RTRIM(A.ZL9_DESCRI)||' - '||TO_CHAR(ZLA_FXINI,'FM999,999,990.00000') ||' - ' ||TO_CHAR(ZLA_FXFIM,'FM9,999,999,999,990.0000') FAIXA
	FROM %exp:_cFiltro% A, %Table:ZLA% ZLA
	WHERE ZLA.D_E_L_E_T_ =' '
	AND A.ZLD_FILIAL = ZLA.ZLA_FILIAL
	AND A.ZL2_COD = ZLA.ZLA_SETOR
	AND A.ZL9_COD = ZLA.ZLA_COD
	AND ZLA.ZLA_FXINI <= A.MEDIA
	AND ZLA.ZLA_FXFIM >= A.MEDIA
	ORDER BY A.ZLD_FILIAL, A.ZL9_COD, ZLA.ZLA_SEQ, A.ZL2_COD, A.A2_COD, A.A2_LOJA
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
	_cFilial := (_cAlias)->ZLD_FILIAL
	_cFaixa	:= (_cAlias)->FAIXA
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())
_oTempTable:Delete()

Return
