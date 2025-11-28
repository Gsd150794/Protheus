/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |19/06/2019| Chamado 29572. Corrigido cálculo da média.
Lucas Borges  |19/06/2019| Chamado 29763. Ajustado para exibir produtores que não possuem nenhuma análise importada.
Lucas Borges  |25/07/2019| Chamado 28346. Corrigida a barra de progresso.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT005
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 19/05/2019
Descrição---------: Relatório de reincidência de eventos de qualidade. Chamado 29479
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT005()

Local oReport
Pergunte("RGLT005",.F.)
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
Local _aOrdem   := {"Por Filial"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT005","Relatório de reincidência de eventos de qualidade","RGLT005",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Demonstra a média dos eventos de qualidade")
oSection := TRSection():New(oReport,"Reincidências"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)

oReport:SetLandscape( )//Define como Paisagem
oSection:SetTotalInLine(.F.)//Define se os totalizadores serão impressos em linha ou coluna

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZLD_FILIAL","ZLD","Fil"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2","Setor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_COD","ZL3","Linha"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_DESCRI","ZL3",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_COD","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_LOJA","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2","Produtor"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOLUME",/*Tabela*/,"Volume"/*cTitle*/,"@E 9,999,999"/*Picture*/,9/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLB_TIPOFX","ZLB",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL9_DESCRI","ZL9",/*cTitle*/,/*Picture*/,20/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"P01_01",/*Tabela*/," 01"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"P01_02",/*Tabela*/," 02"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"P01_03",/*Tabela*/," 03"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"P02_01",/*Tabela*/," 01"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"P02_02",/*Tabela*/," 02"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"P02_03",/*Tabela*/," 03"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"P03_01",/*Tabela*/," 01"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"P03_02",/*Tabela*/," 02"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"P03_03",/*Tabela*/," 03"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"P04_01",/*Tabela*/," 01"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"P04_02",/*Tabela*/," 02"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"P04_03",/*Tabela*/," 03"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"P05_01",/*Tabela*/," 01"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"P05_02",/*Tabela*/," 02"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"P05_03",/*Tabela*/," 03"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"MEDIA01",/*Tabela*/,"Média 01"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"MEDIA02",/*Tabela*/,"Média 02"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"MEDIA03",/*Tabela*/,"Média 03"/*cTitle*/,"@E 9,999.99"/*Picture*/,8/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
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

Local _cFiltro1		:= "%"
Local _cFiltro2		:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-Agrupa por filial 2-Agrupa também por Setor
Local _cFilial		:= ""
Local _cSetor		:= ""
Local _lPlanilha 	:= oReport:nDevice == 4
Local _nMed01		:=0
Local _nMed02		:=0
Local _nMed03		:=0
Local _nMed04		:=0
Local _nMed05		:=0
Local _nMedT01		:=0
Local _nMedT02		:=0
Local _nMedT03		:=0
Local _nAux			:=0
Local _nOk			:=0
Local _nX			:=0
Local _nI			:=0
Local _nMed			:=0
Local _cMes01 		:= SubStr(MesExtenso(Month(MonthSub(MV_PAR07,4))),1,3)
Local _cMes02 		:= SubStr(MesExtenso(Month(MonthSub(MV_PAR07,3))),1,3)
Local _cMes03 		:= SubStr(MesExtenso(Month(MonthSub(MV_PAR07,2))),1,3)
Local _cMes04 		:= SubStr(MesExtenso(Month(MonthSub(MV_PAR07,1))),1,3)
Local _cMes05 		:= SubStr(MesExtenso(Month(MV_PAR07)),1,3)
Local _nCountRec	:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR09 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZLD")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

//=====================================================
// Altero nome dinâmico das colunas
//=====================================================
oReport:Section(1):Cell("P01_01"):SetTitle(_cMes01+" 01")
oReport:Section(1):Cell("P01_02"):SetTitle(_cMes01+" 02")
oReport:Section(1):Cell("P01_03"):SetTitle(_cMes01+" 03")
oReport:Section(1):Cell("P02_01"):SetTitle(_cMes02+" 01")
oReport:Section(1):Cell("P02_02"):SetTitle(_cMes02+" 02")
oReport:Section(1):Cell("P02_03"):SetTitle(_cMes02+" 03")
oReport:Section(1):Cell("P03_01"):SetTitle(_cMes03+" 01")
oReport:Section(1):Cell("P03_02"):SetTitle(_cMes03+" 02")
oReport:Section(1):Cell("P03_03"):SetTitle(_cMes03+" 03")
oReport:Section(1):Cell("P04_01"):SetTitle(_cMes04+" 01")
oReport:Section(1):Cell("P04_02"):SetTitle(_cMes04+" 02")
oReport:Section(1):Cell("P04_03"):SetTitle(_cMes04+" 03")
oReport:Section(1):Cell("P05_01"):SetTitle(_cMes05+" 01")
oReport:Section(1):Cell("P05_02"):SetTitle(_cMes05+" 02")
oReport:Section(1):Cell("P05_03"):SetTitle(_cMes05+" 03")
oReport:Section(1):Cell("MEDIA01"):SetTitle("Média "+_cMes03)
oReport:Section(1):Cell("MEDIA02"):SetTitle("Média "+_cMes04)
oReport:Section(1):Cell("MEDIA03"):SetTitle("Média "+_cMes05)

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
oQbrSetor	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL2_COD") /*uBreak*/, {||"Total do Setor: " + _cSetor} /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("A2_COD")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrSetor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSetor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZLD_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("A2_COD")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If !_lPlanilha
	oReport:Section(1):Cell("ZL3_COD"):Disable()
	oReport:Section(1):Cell("ZL3_DESCRI"):Disable()
	oReport:Section(1):Cell("ZL2_COD"):Disable()
	oReport:Section(1):Cell("ZL2_DESCRI"):Disable()
	oReport:Section(1):Cell("ZLB_TIPOFX"):Disable()
EndIf

oReport:Section(1):Cell("MEDIA01"):SetBlock({||_nMedT01 })
oReport:Section(1):Cell("MEDIA02"):SetBlock({||_nMedT02 })
oReport:Section(1):Cell("MEDIA03"):SetBlock({||_nMedT03 })

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro1 += " AND ZLD.ZLD_FILIAL "+ GetRngFil( _aSelFil, "ZLD", .T.,)
_cFiltro2 += " AND ZLB.ZLB_FILIAL "+ GetRngFil( _aSelFil, "ZLB", .T.,)
_cFiltro2 += " AND ZLB.ZLB_TIPOFX IN "+ FormatIn( AllTrim(MV_PAR08) , ';' )
 
//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR01) .Or. Empty(MV_PAR01) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro1 += " AND ZL2.ZL2_COD IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
	_cFiltro2 += " AND ZLB.ZLB_SETOR IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR10)
	_cFiltro1 += " AND ZL3.ZL3_COD IN " + FormatIn(MV_PAR10,";")
EndIf

_cFiltro1 += "%"
_cFiltro2 += "%"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
SELECT ZLD.ZLD_FILIAL, ZL2.ZL2_COD, ZL2.ZL2_DESCRI, ZL3.ZL3_COD, ZL3.ZL3_DESCRI, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, 
		SUM(ZLD.ZLD_QTDBOM) VOLUME, A.ZLB_TIPOFX, NVL(A.ZL9_DESCRI, 'Analise nao importada') ZL9_DESCRI, A.ZL9_MEDIA,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM %Table:ZLB% ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MonthSub(MV_PAR06,4)% AND %exp:LastDate(MonthSub(MV_PAR07,4))%
                      AND ZLB1.ZLB_TIPOFX = A.ZLB_TIPOFX)
            WHERE LINHA = 1),
           0) P01_01,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM %Table:ZLB% ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MonthSub(MV_PAR06,4)% AND %exp:LastDate(MonthSub(MV_PAR07,4))%
                      AND ZLB1.ZLB_TIPOFX = A.ZLB_TIPOFX)
            WHERE LINHA = 2),
           0) P01_02,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM %Table:ZLB% ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MonthSub(MV_PAR06,4)% AND %exp:LastDate(MonthSub(MV_PAR07,4))%
                      AND ZLB1.ZLB_TIPOFX = A.ZLB_TIPOFX)
            WHERE LINHA = 3),
           0) P01_03,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM %Table:ZLB% ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MonthSub(MV_PAR06,3)% AND %exp:LastDate(MonthSub(MV_PAR07,3))%
                      AND ZLB1.ZLB_TIPOFX = A.ZLB_TIPOFX)
            WHERE LINHA = 1),
           0) P02_01,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM %Table:ZLB% ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MonthSub(MV_PAR06,3)% AND %exp:LastDate(MonthSub(MV_PAR07,3))%
                      AND ZLB1.ZLB_TIPOFX = A.ZLB_TIPOFX)
            WHERE LINHA = 2),
           0) P02_02,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM %Table:ZLB% ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MonthSub(MV_PAR06,3)% AND %exp:LastDate(MonthSub(MV_PAR07,3))%
                      AND ZLB1.ZLB_TIPOFX = A.ZLB_TIPOFX)
            WHERE LINHA = 3),
           0) P02_03,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM %Table:ZLB% ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MonthSub(MV_PAR06,2)% AND %exp:LastDate(MonthSub(MV_PAR07,2))%
                      AND ZLB1.ZLB_TIPOFX = A.ZLB_TIPOFX)
            WHERE LINHA = 1),
           0) P03_01,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM %Table:ZLB% ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MonthSub(MV_PAR06,2)% AND %exp:LastDate(MonthSub(MV_PAR07,2))%
                      AND ZLB1.ZLB_TIPOFX = A.ZLB_TIPOFX)
            WHERE LINHA = 2),
           0) P03_02,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM %Table:ZLB% ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MonthSub(MV_PAR06,2)% AND %exp:LastDate(MonthSub(MV_PAR07,2))%
                      AND ZLB1.ZLB_TIPOFX = A.ZLB_TIPOFX)
            WHERE LINHA = 3),
           0) P03_03,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM %Table:ZLB% ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MonthSub(MV_PAR06,1)% AND %exp:LastDate(MonthSub(MV_PAR07,1))%
                      AND ZLB1.ZLB_TIPOFX = A.ZLB_TIPOFX)
            WHERE LINHA = 1),
           0) P04_01,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM %Table:ZLB% ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MonthSub(MV_PAR06,1)% AND %exp:LastDate(MonthSub(MV_PAR07,1))%
                      AND ZLB1.ZLB_TIPOFX = A.ZLB_TIPOFX)
            WHERE LINHA = 2),
           0) P04_02,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM %Table:ZLB% ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MonthSub(MV_PAR06,1)% AND %exp:LastDate(MonthSub(MV_PAR07,1))%
                      AND ZLB1.ZLB_TIPOFX = A.ZLB_TIPOFX)
            WHERE LINHA = 3),
           0) P04_03,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM %Table:ZLB% ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
                      AND ZLB1.ZLB_TIPOFX = A.ZLB_TIPOFX)
            WHERE LINHA = 1),
           0) P05_01,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM %Table:ZLB% ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
                      AND ZLB1.ZLB_TIPOFX = A.ZLB_TIPOFX)
            WHERE LINHA = 2),
           0) P05_02,
       NVL((SELECT ZLB_VLRFX
             FROM (SELECT ZLB_DATA, ZLB_VLRFX, ROWNUM LINHA
                     FROM %Table:ZLB% ZLB1
                    WHERE ZLB1.D_E_L_E_T_ = ' '
                      AND ZLB1.ZLB_FILIAL = ZLD.ZLD_FILIAL
                      AND ZLB1.ZLB_RETIRO = SA2.A2_COD
                      AND ZLB1.ZLB_RETILJ = SA2.A2_LOJA
                      AND ZLB1.ZLB_SETOR = ZL2.ZL2_COD
                      AND ZLB1.ZLB_DATA BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
                      AND ZLB1.ZLB_TIPOFX = A.ZLB_TIPOFX)
            WHERE LINHA = 3),
           0) P05_03
  FROM %Table:ZLD% ZLD, %Table:SA2% SA2, %Table:ZL2% ZL2, %Table:ZL3% ZL3,
		(SELECT ZLB.ZLB_FILIAL, ZLB.ZLB_RETIRO, ZLB.ZLB_RETILJ, ZLB.ZLB_SETOR, ZLB.ZLB_TIPOFX, ZL9.ZL9_DESCRI, ZL9.ZL9_MEDIA
		           FROM %Table:ZLB% ZLB, %Table:ZL9% ZL9
		          WHERE ZLB.D_E_L_E_T_ = ' '
		            AND ZL9.D_E_L_E_T_ = ' '
		            AND ZL9.ZL9_FILIAL = ZLB.ZLB_FILIAL
		            %exp:_cFiltro2%
		            AND ZLB.ZLB_RETIRO BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
		            AND ZLB.ZLB_RETILJ BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
		            AND ZLB.ZLB_TIPOFX = ZL9.ZL9_COD
		            AND ZLB.ZLB_DATA BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
		          GROUP BY ZLB.ZLB_FILIAL, ZLB.ZLB_RETIRO, ZLB.ZLB_RETILJ, ZLB.ZLB_SETOR, ZLB.ZLB_TIPOFX, ZL9.ZL9_DESCRI, ZL9.ZL9_MEDIA) A
 WHERE ZLD.D_E_L_E_T_ = ' '
   AND SA2.D_E_L_E_T_ = ' '
   AND ZL2.D_E_L_E_T_ = ' '
   AND ZL3.D_E_L_E_T_ = ' '
   AND ZLD.ZLD_FILIAL = ZL2.ZL2_FILIAL
   AND ZLD.ZLD_FILIAL = ZL3.ZL3_FILIAL
   AND ZLD.ZLD_RETIRO BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
   AND ZLD.ZLD_RETILJ BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
   AND SA2.A2_COD = ZLD.ZLD_RETIRO
   AND SA2.A2_LOJA = ZLD.ZLD_RETILJ
   AND A.ZLB_FILIAL(+) = ZLD.ZLD_FILIAL
   AND A.ZLB_RETIRO(+) = ZLD.ZLD_RETIRO
   AND A.ZLB_RETILJ(+) = ZLD.ZLD_RETILJ
   AND A.ZLB_SETOR(+) = ZL2.ZL2_COD
   AND ZL2.ZL2_COD = ZLD.ZLD_SETOR
   AND ZL3.ZL3_COD = ZLD.ZLD_LINROT
   %exp:_cFiltro1%
   AND ZLD.ZLD_DTCOLE BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
 GROUP BY ZLD.ZLD_FILIAL, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, ZL2.ZL2_COD, ZL2.ZL2_DESCRI, 
 			ZL3.ZL3_COD, ZL3.ZL3_DESCRI, A.ZLB_TIPOFX, A.ZL9_DESCRI, A.ZL9_MEDIA
ORDER BY ZLD.ZLD_FILIAL, ZL2.ZL2_COD, SA2.A2_COD, SA2.A2_LOJA, A.ZLB_TIPOFX
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
	//Reinicio o valor das variáveis
	_nMedT01:=0
	_nMedT02:=0
	_nMedT03:=0
	//Primeiro eu calculo a média de cada mês para a
	//primeira parte do cálculo
	For _nX:=1 To 5
		_nMed:=0
		_nAux:=0
		_nOk:=0
		//==========================================================================================
		//Primeiro faço a média das coletas dentro do próprio mês. Nesse ponto, posso ter coletas
		//com o valor 0 que não zero a média, pois não é obrigatória mais de uma análise.
		//Quando fizer a média entre os meses, ai já preciso invalidar (zerar) a média caso um dos
		//meses tenha valor zerado. Essa regra é diferente do que é feito no Demonstrativo (RGLT019)
		//pois uma coisa é o pagamento do produtor, outra é o acompanhamento de suas médias, que é
		//definido por lei.
		//==========================================================================================

		//Busco as 3 possíveis coletas dentro do mesmo mês
		For _nI:=1 To 3
			_nAux:=(_cAlias)->&("P0"+cValToChar(_nX)+"_0"+cValToChar(_nI))
			IIf((_cAlias)->ZL9_MEDIA=="G",IIf(_nAux != 0,IIf(_nMed != 0,_nMed*=_nAux,_nMed+=_nAux),),_nMed+=_nAux)
			IIf(_nAux != 0,_nOk++,)
		Next _nI
		
		// Media
		If _nX == 1
			_nMed01:=IIf(_nOk != 0, IIf((_cAlias)->ZL9_MEDIA=="G",_nMed^(1/_nOk),_nMed/_nOk),0)
		ElseIf _nX == 2
			_nMed02:=IIf(_nOk != 0, IIf((_cAlias)->ZL9_MEDIA=="G",_nMed^(1/_nOk),_nMed/_nOk),0)
		ElseIf _nX == 3
			_nMed03:=IIf(_nOk != 0, IIf((_cAlias)->ZL9_MEDIA=="G",_nMed^(1/_nOk),_nMed/_nOk),0)
		ElseIf _nX == 4
			_nMed04:=IIf(_nOk != 0, IIf((_cAlias)->ZL9_MEDIA=="G",_nMed^(1/_nOk),_nMed/_nOk),0)
		ElseIf _nX == 5
			_nMed05:=IIf(_nOk != 0, IIf((_cAlias)->ZL9_MEDIA=="G",_nMed^(1/_nOk),_nMed/_nOk),0)
		EndIf
	Next _nX
	
	//Agrupo de 3 em 3 meses e faço uma média deles
	For _nX:=1 To 3
		_nMed:=1
		_nAux:=0
		_nOk:=0

		// Obtem média do primeiro mês
		_nAux:=&("_nMed"+StrZero(_nX,2))
		If _nAux == 0
			Loop
		EndIf
		IIf((_cAlias)->ZL9_MEDIA=="G",_nMed*=_nAux,_nMed+=_nAux)
		IIf(_nAux != 0,_nOk++,)
				
		// Obtem média do segundo mês
		_nAux:=&("_nMed"+StrZero(_nX+1,2))
		If _nAux == 0
			Loop
		EndIf
		IIf((_cAlias)->ZL9_MEDIA=="G",_nMed*=_nAux,_nMed+=_nAux)
		IIf(_nAux != 0,_nOk++,)
				
		// Obtem média do terceiro mês
		_nAux:=&("_nMed"+StrZero(_nX+2,2))
		If _nAux == 0
			Loop
		EndIf
		IIf((_cAlias)->ZL9_MEDIA=="G",_nMed*=_nAux,_nMed+=_nAux)
		IIf(_nAux != 0,_nOk++,)
		
		// Media
		If _nX == 1
			_nMedT01:=IIf(_nOk != 0, IIf((_cAlias)->ZL9_MEDIA=="G",_nMed^(1/_nOk),_nMed/_nOk),0)
		ElseIf _nX == 2
			_nMedT02:=IIf(_nOk != 0, IIf((_cAlias)->ZL9_MEDIA=="G",_nMed^(1/_nOk),_nMed/_nOk),0)
		ElseIf _nX == 3
			_nMedT03:=IIf(_nOk != 0, IIf((_cAlias)->ZL9_MEDIA=="G",_nMed^(1/_nOk),_nMed/_nOk),0)
		EndIf
	Next _nX
	
	oReport:Section(1):PrintLine()
	oReport:IncMeter()
	_cFilial := (_cAlias)->ZLD_FILIAL
	_cSetor	:= (_cAlias)->ZL2_COD + ' - ' + (_cAlias)->ZL2_DESCRI
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
