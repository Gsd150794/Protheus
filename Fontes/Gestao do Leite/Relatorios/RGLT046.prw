/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |19/06/2019| Chamado 28346. Revisão de fontes.
Lucas Borges  |26/08/2019| Chamado 30185. Modificada validação de acesso aos setores.
Lucas Borges  |12/12/2021| Chamado 38597. Migração do relatório para tReport.
===============================================================================================================================
*/

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Programa--------: RGLT046
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 03/11/2021
Descrição-------: Relatório dos Valores Recolhidos de Fundepec/Fundesa - Por Produtor
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RGLT046

Local oReport
Pergunte("RGLT046",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Processa a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local oSecTotal
Local _aOrdem   := {"Por Filial+Data"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT046","Relatório de análise de Adiantamentos, Antecipações e Empréstimos","RGLT046",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Apresenta os valores de Adiantamentos, Antecipações e Empréstimos")
oSection := TRSection():New(oReport,"Movimentos"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.T.)//Imprime totalizador em linhas
oReport:nFontBody	:= 7 //Define o tamanho da fonte. Não é possível alterar apos a criação das sessões
oReport:nLineHeight	:= 40 // Define a altura da linha.
//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZLM_FILIAL","ZLM","Fil"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLM_DATA","ZLM"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLM_SA2COD","ZLM"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLM_SA2LJ","ZLM"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLM_SA2NOM","ZLM"/*Table*/,/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLM_TIPO","ZLM"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLM_COD","ZLM"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOLUME",/*Tabela*/,"Volume"/*cTitle*/,GetSx3Cache("ZLD_QTDBOM","X3_PICTURE")/*Picture*/,GetSx3Cache("ZLD_QTDBOM","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLM_TOTAL","ZLM"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLM_PARC","ZLM"/*Table*/,"Parc."/*cTitle*/,"@E 99"/*Picture*/,2/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLM_STATUS","ZLM"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"RECEBIDO",/*Tabela*/,"V.Recebido"/*cTitle*/,GetSx3Cache("E5_VALOR","X3_PICTURE")/*Picture*/,GetSx3Cache("E5_VALOR","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ABERTO",/*Tabela*/,"V. em Aberto"/*cTitle*/,GetSx3Cache("E5_VALOR","X3_PICTURE")/*Picture*/,GetSx3Cache("E5_VALOR","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VENCIDO",/*Table*/,"V.Vencido"/*cTitle*/,GetSx3Cache("E5_VALOR","X3_PICTURE")/*Picture*/,GetSx3Cache("E5_VALOR","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VLUCRO",/*Table*/,"V.Lucro"/*cTitle*/,GetSx3Cache("E5_VALOR","X3_PICTURE")/*Picture*/,GetSx3Cache("E5_VALOR","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLM_JUROS","ZLM"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

oSecTotal := TRSection():New(oReport,"Totalizadores"	,/*uTable {}*/, /*aOrder*/, .F./*lLoadCells*/, .F./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
TRCell():New(oSecTotal,"FILIAL",/*Table*/,"Filial"/*cTitle*/,/*Picture*/,50/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecTotal,"ZLM_TIPO","ZLM"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecTotal,"ZLM_TOTAL","ZLM"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecTotal,"RECEBIDO",/*Tabela*/,"V.Recebido"/*cTitle*/,GetSx3Cache("E5_VALOR","X3_PICTURE")/*Picture*/,GetSx3Cache("E5_VALOR","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecTotal,"ABERTO",/*Tabela*/,"V. em Aberto"/*cTitle*/,GetSx3Cache("E5_VALOR","X3_PICTURE")/*Picture*/,GetSx3Cache("E5_VALOR","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecTotal,"VENCIDO",/*Table*/,"V.Vencido"/*cTitle*/,GetSx3Cache("E5_VALOR","X3_PICTURE")/*Picture*/,GetSx3Cache("E5_VALOR","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecTotal,"VLUCRO",/*Table*/,"V.Lucro"/*cTitle*/,GetSx3Cache("E5_VALOR","X3_PICTURE")/*Picture*/,GetSx3Cache("E5_VALOR","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/11/2021
Descrição---------: Processa a impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro	:= "%"
Local _cAlias	:= ""
Local _aSelFil	:= {}
Local _nOrdem	:= oReport:Section(1):GetOrder() //1-"Por Filial+Produtor",2-"Por Filial+Setor"
//Local _lPlanilha:= oReport:nDevice == 4
Local _cFilial	:= ""
Local _nCountRec:= 0
Local _aTot		:= {}
Local _aTotG	:= {0,0,0,0,0,0}
Local _nX		:= 0
Local _aRetBox1 := RetSx3Box(GetSx3Cache("ZLM_TIPO","X3_CBOX"),,,1)//Retorno a descrição da opção do X3_CBOX

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZLM")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

//=====================================================
// Adiciona a ordem escolhida ao titulo do relatorio
//=====================================================
oReport:SetTitle(oReport:Title() + " ("+AllTrim(_aOrdem[_nOrdem])+") ")

//==========================================================================
// Transforma parametros Range em expressao SQL                             	
//==========================================================================
MakeSqlExpr(oReport:uParam)

//================================================================================
// Configuração das quebras do relatório
//================================================================================
oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZLM_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ZLM_TOTAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("RECEBIDO")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ABERTO")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VENCIDO")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VLUCRO")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZLM_FILIAL "+ GetRngFil( _aSelFil, "ZLM", .T.,)
//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR08) .Or. Empty(MV_PAR08) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro+=" AND ZLM_SETOR IN " + FormatIn(AllTrim(MV_PAR08),';')
EndIf

//Tipo da Solicitacao
If !Empty(MV_PAR09)
	_cFiltro   += " AND ZLM_TIPO IN "+ FormatIn(AllTrim(MV_PAR09),";")
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
  SELECT ZLM_FILIAL, ZLM_DATA, ZLM_SA2COD, ZLM_SA2LJ, ZLM_SA2NOM, ZLM_TIPO, ZLM_COD, ZLM_TOTAL, ZLM_PARC, ZLM_STATUS, ZLM_JUROS, ZLM_PAGTO-ZLM_TOTAL VLUCRO,
         (SELECT NVL(SUM(E5_VALOR), 0)
            FROM %Table:SE5% SE5
           WHERE SE5.D_E_L_E_T_ = ' '
             AND ZLM_FILIAL = E5_FILIAL
             AND ZLM_COD = E5_NUMERO
             AND ZLM_SA2COD = E5_CLIFOR
             AND ZLM_SA2LJ = E5_LOJA
             AND E5_TIPO IN ('NDF')
             AND E5_PREFIXO IN ('GLE', 'GLA', 'GLN')
             AND E5_TIPODOC NOT IN ('ES', 'DC', 'JR')
             AND E5_SITUACA <> 'C'
             AND E5_MOTBX IN ('NOR', 'DAC', 'GLT')
             AND E5_RECPAG = 'R') RECEBIDO,
         (SELECT (SUM(E2_SALDO) + SUM(E2_SDACRES)) - SUM(E2_SDDECRE)
            FROM %Table:SE2% SE2
           WHERE SE2.D_E_L_E_T_ = ' '
             AND ZLM_FILIAL = E2_FILIAL
             AND ZLM_COD = E2_NUM
             AND ZLM_SA2COD = E2_FORNECE
             AND ZLM_SA2LJ = E2_LOJA
             AND E2_TIPO IN ('NDF')
             AND E2_PREFIXO IN ('GLE', 'GLA', 'GLN')
             AND E2_SALDO + E2_SDACRES > 0
             AND E2_VENCREA >= %exp:Date()%) ABERTO,
         (SELECT (SUM(E2_SALDO) + SUM(E2_SDACRES)) - SUM(E2_SDDECRE)
            FROM %Table:SE2% SE2
           WHERE SE2.D_E_L_E_T_ = ' '
             AND ZLM_FILIAL = E2_FILIAL
             AND ZLM_COD = E2_NUM
             AND ZLM_SA2COD = E2_FORNECE
             AND ZLM_SA2LJ = E2_LOJA
             AND E2_TIPO IN ('NDF')
             AND E2_PREFIXO IN ('GLE', 'GLA', 'GLN')
             AND E2_SALDO + E2_SDACRES > 0
             AND E2_VENCREA < %exp:Date()%) VENCIDO,
			 NVL((SELECT SUM(ZLD_QTDBOM)
						FROM %Table:ZLD% ZLD
						WHERE ZLD.D_E_L_E_T_ = ' '
						AND ZLD.ZLD_FILIAL = ZLM_FILIAL
						AND ZLD.ZLD_DTCOLE BETWEEN %exp:MV_PAR10% AND %exp:MV_PAR11%
						AND ZLD.ZLD_RETIRO = ZLM_SA2COD
						AND ZLD.ZLD_RETILJ = ZLM_SA2LJ
						AND ZLD.ZLD_SETOR = ZLM_SETOR), 0) VOLUME
    FROM %Table:ZLM% ZLM
   WHERE ZLM.D_E_L_E_T_ = ' '
     AND ZLM_STATUS IN ('4','5','6')
	 %exp:_cFiltro%
     AND ZLM_DATA BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
	 AND ZLM_SA2COD BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR04%
	 AND ZLM_SA2LJ BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR05%
   ORDER BY ZLM_FILIAL, ZLM_DATA, ZLM_TIPO, ZLM_COD
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
	_cFilial := (_cAlias)->ZLM_FILIAL
	_cTipo := (_cAlias)->ZLM_TIPO
	If (_nX:= aScan(_aTot,{|x| x[1]+x[2] == _cFilial+_cTipo } )) == 0
		aAdd(_aTot,{_cFilial,_cTipo,(_cAlias)->ZLM_TOTAL,(_cAlias)->RECEBIDO,(_cAlias)->ABERTO,(_cAlias)->VENCIDO,(_cAlias)->VLUCRO})
	Else
		_aTot[_nX,3]+=(_cAlias)->ZLM_TOTAL
      	_aTot[_nX,4]+=(_cAlias)->RECEBIDO
		_aTot[_nX,5]+=(_cAlias)->ABERTO
		_aTot[_nX,6]+=(_cAlias)->VENCIDO
		_aTot[_nX,7]+=(_cAlias)->VLUCRO
	EndIf
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

//Impressão do Resumo das filiais
oReport:EndPage()
oReport:SetTitle("Resumo por Filial e Tipo de Solicitação ("+AllTrim(_aOrdem[_nOrdem])+") ")

oReport:Section(2):Init()
For _nX := 1 To Len(_aTot)
	_aTotG[1] += _aTot[_nX][3]//ZLM_TOTAL
	_aTotG[2] += _aTot[_nX][4]//RECEBIDO
	_aTotG[3] += _aTot[_nX][5]//ABERTO
	_aTotG[4] += _aTot[_nX][6]//VENCIDO
	_aTotG[5] += _aTot[_nX][7]//VLUCRO
	oReport:Section(2):Cell("FILIAL"):SetValue(_aTot[_nX][1]+" - "+FWFilialName(cEmpAnt,_aTot[_nX][1],1))
	oReport:Section(2):Cell("ZLM_TIPO"):SetValue(AllTrim(_aRetBox1[aScan(_aRetBox1,{|x|x[2]==_aTot[_nX][2]}),3]))
	oReport:Section(2):Cell("ZLM_TOTAL"):SetValue(_aTot[_nX][3])
	oReport:Section(2):Cell("RECEBIDO"):SetValue(_aTot[_nX][4])
	oReport:Section(2):Cell("ABERTO"):SetValue(_aTot[_nX][5])
	oReport:Section(2):Cell("VENCIDO"):SetValue(_aTot[_nX][6])
	oReport:Section(2):Cell("VLUCRO"):SetValue(_aTot[_nX][7])
	oReport:Section(2):PrintLine()
Next _nX
//Imprime total de todas as filiais
oReport:Section(2):Cell("FILIAL"):SetValue("Total Geral")
oReport:Section(2):Cell("ZLM_TOTAL"):SetValue(_aTotG[1])
oReport:Section(2):Cell("RECEBIDO"):SetValue(_aTotG[2])
oReport:Section(2):Cell("ABERTO"):SetValue(_aTotG[3])
oReport:Section(2):Cell("VENCIDO"):SetValue(_aTotG[4])
oReport:Section(2):Cell("VLUCRO"):SetValue(_aTotG[5])
oReport:Section(2):PrintLine()
oReport:Section(2):Finish()

Return
