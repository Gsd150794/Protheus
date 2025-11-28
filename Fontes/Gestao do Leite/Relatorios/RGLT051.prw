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
Programa--------: RGLT051
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 03/11/2021
Descrição-------: Relatório dos Valores Recolhidos de Fundepec/Fundesa - Por Produtor
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RGLT051

Local oReport
Pergunte("RGLT051",.F.)
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
Local _aOrdem   := {"Por Filial+Produtor","Por Filial+Setor"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT051","Valores recolhidos de ","RGLT051",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Apresenta os valores do evento 000014 referente ao Fundepec/Fundesa.")
oSection := TRSection():New(oReport,"Movimentos"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.T.)//Imprime totalizador em linhas
oReport:nFontBody	:= 8 //Define o tamanho da fonte. Não é possível alterar apos a criação das sessões
oReport:nLineHeight	:= 40 // Define a altura da linha.
//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZLF_FILIAL","ZLF","Fil"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2"/*Table*/,"Setor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2"/*Table*/,"Setor"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_COD","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_LOJA","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_CGC","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_L_FUNDE","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_L_NIRF","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOLUME",/*Tabela*/,"Volume", GetSx3Cache("ZLD_QTDBOM","X3_PICTURE")/*Picture*/,GetSx3Cache("ZLD_QTDBOM","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VALOR",/*Tabela*/,"Valor Fundepec", "@E 9,999,999,999.99" ,16,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"STATUS",/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

oSecTotal := TRSection():New(oReport,"Totalizadores"	,/*uTable {}*/, /*aOrder*/, .F./*lLoadCells*/, .F./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
TRCell():New(oSecTotal,"FILIAL",/*Table*/,"Filial"/*cTitle*/,/*Picture*/,50/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecTotal,"VOLUME",/*Tabela*/,"Volume", "@E 9,999,999,999" ,13,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSecTotal,"VALOR",/*Tabela*/,"Valor Fundepec", "@E 9,999,999,999.99" ,16,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

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
Local _cFiltro2 := "%"
Local _cOrder	:= "%%"
Local _cAlias	:= ""
Local _aSelFil	:= {}
Local _nOrdem	:= oReport:Section(1):GetOrder() //1-"Por Filial+Produtor",2-"Por Filial+Setor"
//Local _lPlanilha:= oReport:nDevice == 4
Local _cFilial	:= ""
Local _cSetor	:= ""
Local _nCountRec:= 0
Local _cProdutor:= ""
Local _aTot		:= {}
Local _nX		:= 0
Local _nValor	:= 0
Local _nVolume	:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZLF")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

//=====================================================
// Adiciona a ordem escolhida ao titulo do relatorio
//=====================================================
oReport:SetTitle(oReport:Title() + IIf(MV_PAR08==1," Fundepec"," Fundesa")+ " ("+AllTrim(_aOrdem[_nOrdem])+") ")

//==========================================================================
// Transforma parametros Range em expressao SQL                             	
//==========================================================================
MakeSqlExpr(oReport:uParam)

//================================================================================
// Configuração das quebras do relatório
//================================================================================
If _nOrdem == 2
    oQbrSet	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL2_COD") /*uBreak*/, {||"Total do Setor: " + _cSetor } /*uTitle*/, .T. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
	TRFunction():New(oReport:Section(1):Cell("A2_COD")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrSet/*oBreak*/,"Produção"/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
    TRFunction():New(oReport:Section(1):Cell("VALOR")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSet/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
EndIf

oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZLF_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .T. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("ZL2_DESCRI")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrFilial/*oBreak*/,"Produtores"/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,{||oReport:Section(1):Cell("A2_COD"):GetText()<>_cProdutor}/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("A2_COD")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrFilial/*oBreak*/,"Produção"/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VALOR")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
oReport:Section(1):Cell("VALOR"):SetTitle("Valor"+IIf(MV_PAR08==1," Fundepec"," Fundesa"))

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZLF.ZLF_FILIAL "+ GetRngFil( _aSelFil, "ZLF", .T.,)
//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR03) .Or. Empty(MV_PAR03) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro+=" AND ZL2.ZL2_COD IN " + FormatIn( AllTrim(MV_PAR03),';')
	_cFiltro2+=" AND ZL2.ZL2_COD IN " + FormatIn( AllTrim(MV_PAR03),';')
EndIf

_cFiltro += " %"
_cFiltro2+= " %"

If _nOrdem == 2
	_cOrder := "% ZL2_COD, %"
EndIf
//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
	SELECT ZLF.ZLF_FILIAL, ZL2.ZL2_COD, ZL2.ZL2_DESCRI, SA2.A2_COD, SA2.A2_LOJA,SA2.A2_NOME, SA2.A2_CGC, SA2.A2_L_FUNDE, SA2.A2_L_NIRF,
	       NVL((SELECT SUM(ZLD_QTDBOM)
	             FROM %Table:ZLD% ZLD
	            WHERE ZLD.D_E_L_E_T_ = ' '
	              AND ZLD.ZLD_FILIAL = ZLF.ZLF_FILIAL
	              AND ZLD.ZLD_DTCOLE BETWEEN ZLF.ZLF_DTINI AND ZLF.ZLF_DTFIM
	              AND ZLD.ZLD_SETOR = ZL2.ZL2_COD
	              AND ZLD.ZLD_RETIRO = SA2.A2_COD
	              AND ZLD.ZLD_RETILJ = SA2.A2_LOJA
	              %exp:_cFiltro%), 0) VOLUME,
	       NVL(SUM(ZLFF.ZLF_TOTAL), 0) VALOR,
	       DECODE(ZLFF.ZLF_L_SEEK, 'PREVISAO', 'PREVISAO', ' ') STATUS
       FROM %Table:ZLF% ZLF, %Table:SA2% SA2, %Table:ZLF% ZLFF, %Table:ZL2% ZL2
	 WHERE ZLF.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND ZL2.D_E_L_E_T_ = ' '
	   AND ZLFF.D_E_L_E_T_(+) = ' '
	   AND SA2.A2_COD = ZLF.ZLF_A2COD
	   AND SA2.A2_LOJA = ZLF.ZLF_A2LOJA
	   AND ZL2.ZL2_FILIAL = ZLF.ZLF_FILIAL
	   AND ZL2.ZL2_COD = ZLF.ZLF_SETOR
	   AND SubStr(ZLF.ZLF_A2COD, 1, 1) = 'P'
	   AND ZLFF.ZLF_FILIAL(+) = ZLF.ZLF_FILIAL
	   AND ZLFF.ZLF_CODZLE(+) = ZLF.ZLF_CODZLE
	   AND ZLFF.ZLF_SETOR(+) = ZLF.ZLF_SETOR
       AND ZLFF.ZLF_LINROT(+) = ZLF.ZLF_LINROT
	   AND ZLFF.ZLF_RETIRO(+) = ZLF.ZLF_A2COD
	   AND ZLFF.ZLF_RETILJ(+) = ZLF.ZLF_A2LOJA
	   AND ZLFF.ZLF_EVENTO(+) = ZLF.ZLF_EVENTO
	   AND ZLFF.ZLF_EVENTO(+) = '000014'
	   %exp:_cFiltro%
	   AND ZLF.ZLF_CODZLE = %exp:MV_PAR02%
	   AND SA2.A2_COD BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR06%
	   AND SA2.A2_LOJA BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07%
	 GROUP BY ZLF.ZLF_FILIAL, ZL2.ZL2_COD, ZL2.ZL2_DESCRI, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME,
	          SA2.A2_CGC, SA2.A2_L_FUNDE, SA2.A2_L_NIRF, ZLF.ZLF_DTINI, ZLF.ZLF_DTFIM,
	          DECODE(ZLFF.ZLF_L_SEEK, 'PREVISAO', 'PREVISAO', ' ')
	 ORDER BY ZLF.ZLF_FILIAL, %exp:_cOrder% SA2.A2_COD, SA2.A2_LOJA
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
	_cFilial := (_cAlias)->ZLF_FILIAL
	_cSetor	:= (_cAlias)->ZL2_COD + ' - ' + (_cAlias)->ZL2_DESCRI
	_cProdutor := (_cAlias)->A2_COD
	If (_nX:= aScan(_aTot,{|x| x[1] == _cFilial } )) == 0
		aAdd(_aTot,{_cFilial,(_cAlias)->VOLUME,(_cAlias)->VALOR})
	Else
		_aTot[_nX,2]+=(_cAlias)->VOLUME
      	_aTot[_nX,3]+=(_cAlias)->VALOR
	EndIf
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

//Impressão do Resumo das filiais
oReport:EndPage()
oReport:SetTitle("Resumo" + IIf(MV_PAR08==1," Fundepec"," Fundesa")+ " por Filial ("+AllTrim(_aOrdem[_nOrdem])+") ")

oReport:Section(2):Init()
For _nX := 1 To Len(_aTot)
	_nVolume += _aTot[_nX][2]
	_nValor += _aTot[_nX][3]
	oReport:Section(2):Cell("FILIAL"):SetValue(_aTot[_nX][1]+" - "+FWFilialName(cEmpAnt,_aTot[_nX][1],1))
	oReport:Section(2):Cell("VOLUME"):SetValue(_aTot[_nX][2])
	oReport:Section(2):Cell("VALOR"):SetValue(_aTot[_nX][3])
	oReport:Section(2):PrintLine()
Next _nX
//Imprime total de todas as filiais
oReport:Section(2):Cell("FILIAL"):SetValue("Total Geral")
oReport:Section(2):Cell("VOLUME"):SetValue(_nVolume)
oReport:Section(2):Cell("VALOR"):SetValue(_nValor)
oReport:Section(2):PrintLine()
oReport:Section(2):Finish()

Return
