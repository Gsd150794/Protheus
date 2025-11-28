/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |21/02/2025| Chamado 49932. Ajustado o relatório para contemplar as informações do RGLT015 e RGLT016
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT077
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 14/06/2024
Descrição---------: Relatório Composição de Preços Por Responsável de Tanque. Chamado 47600
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT077

Local oReport as Object
Pergunte("RGLT077",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 14/06/2024
Descrição---------: Processa a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport as Object
Local oSection as Object
Local oSection2 as Object
Local _aOrdem   := {"Filial + Tanque","Filial + Produtor"} as Array
Local _cAliasEve:= GetNextAlias() as String
Local _aSelFil	:= {} as Array
Local _cFiltro	:= "%" as String
Local _cPivot	:= "" as String
Local _cCampos	:= "" as String

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT077","Composição de Preços Por Responsável de Tanque","RGLT077",;
{|oReport| ReportPrint(oReport,_aOrdem,@_cFiltro,@_aSelFil,@_cPivot,@_cCampos,_cAliasEve)},"Apresenta a relação de produtores de acordo com o banco informado no cadastro.")
oSection := TRSection():New(oReport,"Dados",/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oSection2 := TRSection():New(oReport,"Totais",/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Resumo dos eventos: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.F.)

//Definicoes da fonte utilizada
oReport:cFontBody := "Arial"
oReport:SetLineHeight(50)
oReport:nFontBody := 8

//Aqui iremos deixar como selecionado a opção Planilha, e iremos habilitar somente o formato de tabela
oReport:SetDevice(4) //Planilha

TRCell():New(oSection,"ZLF_FILIAL","ZLF",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLF_CODZLE","ZLF"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLF_SETOR","ZLF"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLF_LINROT","ZLF"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLF_A2COD","ZL3"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLF_A2LOJA","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PRODUTOR","SA2"/*Table*/,"Produtor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_L_TANQ","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_L_TANLJ","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"RESPONSAVEL","SA2"/*Table*/,"Responsavel"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLF_QTDBOM","ZLF"/*Table*/,"Volume"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLF_VLRLTR","ZLF"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

TRCell():New(oSection2,"ZL8_COD",/*Table*/,"Código"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection2,"ZL8_NREDUZ",/*Table*/,"Evento"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection2,"CREDITO",/*Table*/,"Créditos"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection2,"DEBITO",/*Table*/,"Débitos"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 19/08/2020
Descrição---------: Processa a impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport as Object,_aOrdem as Array,_cFiltro as String,_aSelFil as Array,_cPivot as String,;
							_cCampos as String,_cAliasEve as String)

Local _cAlias	:= "" as String
Local _nOrdem	:= oReport:Section(1):GetOrder() as Array
Local _nCountRec:= 0 as Number
Local _nX		:= 0 as Number	
Local _aCampos	:= {} as Array
Local _cFilial 	:= "" as String
Local _cOrder	:= "%%" as String
Local _nVolume	:= 0 as Number
Local _nCredito := 0 as Nmmber
Local _nDebito	:= 0 as Number

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZLF")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

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

//Entra Mix ?
If MV_PAR09 == 2
	_cFiltro += " AND ZLF_ENTMIX = 'S' "
ElseIf MV_PAR09 == 3
	_cFiltro += " AND ZLF_ENTMIX = 'N' "
EndIf

//Produtor TQ ?
If !Empty(MV_PAR11) .And. !Empty(MV_PAR12)
	_cFiltro += " AND SA2.A2_L_TANQ  = '"+ MV_PAR11 +"' "
	_cFiltro += " AND SA2.A2_L_TANLJ = '"+ MV_PAR12 +"' "
EndIf
//Recolhimento eSocial
If MV_PAR13 == 1//Sob Produção
	_cFiltro += " AND SA2.A2_INDCP  = '1' "
ElseIf MV_PAR13 == 2 //Sob Folha de Pagamento
	_cFiltro += " AND SA2.A2_INDCP  = '2' "
EndIf
//Tipo Fornecedor ?
If MV_PAR10 == 1 //Pessoa Física
	_cFiltro += " AND SA2.A2_TIPO  = 'F' "
ElseIf MV_PAR10 == 2 //Pessoa Jurídica
	_cFiltro += " AND SA2.A2_TIPO  = 'J' "
EndIf

//Apenas Negativos
If MV_PAR14 == 1
	_cFiltro += " AND (SELECT SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else ZLF_TOTAL * -1 END) FROM "+ RetSqlName("ZLF") +" A "
	_cFiltro += " WHERE A.D_E_L_E_T_ = ' ' AND A.ZLF_FILIAL = ZLF.ZLF_FILIAL "
	_cFiltro += " AND A.ZLF_CODZLE = ZLF.ZLF_CODZLE "
	_cFiltro += " AND A.ZLF_A2COD = ZLF.ZLF_A2COD "
	_cFiltro += " AND A.ZLF_A2LOJA = ZLF.ZLF_A2LOJA) < 0 "
EndIf

_cFiltro += "%"

If _nOrdem == 1
	_cOrder := "% A2_L_TANQ, A2_L_TANLJ, A2_L_CLASS, PRODUTOR %"
Else
	_cOrder := "% ZLF_A2COD, ZLF_A2LOJA %"	
EndIf

BeginSql alias _cAliasEve
	SELECT NVL(LISTAGG(''''||ZL8_NREDUZ||''' XXAS "'||REGEXP_REPLACE(TRIM(REGEXP_REPLACE(ZL8_NREDUZ,'[^a-zA-Z0-9 ]','')),' +','_') || '"', ', ') WITHIN GROUP (ORDER BY ZL8_NREDUZ),'''SEM_DADOS''') PIVO,
	NVL(LISTAGG('SUM(' || REGEXP_REPLACE(TRIM(REGEXP_REPLACE(ZL8_NREDUZ, '[^a-zA-Z0-9 ]', '')),' +','_') || ') AS "' || REGEXP_REPLACE(TRIM(REGEXP_REPLACE(ZL8_NREDUZ, '[^a-zA-Z0-9 ]', '')),' +','_') || '"', ', ') WITHIN GROUP (ORDER BY ZL8_NREDUZ), '''SEM_DADOS''') CAMPOS,
	NVL(LISTAGG(REGEXP_REPLACE(TRIM(REGEXP_REPLACE(ZL8_NREDUZ, '[^a-zA-Z0-9 ]', '')),' +','_') || '', ';') WITHIN GROUP (ORDER BY ZL8_NREDUZ), '''SEM_DADOS''') ARRAY
	FROM (SELECT ZL8_NREDUZ, ZLF_DEBCRE FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8, %Table:SA2% SA2
	WHERE ZLF.D_E_L_E_T_ = ' '
	AND ZL8.D_E_L_E_T_ = ' '
	AND SA2.D_E_L_E_T_ = ' '
	AND A2_COD = ZLF_A2COD
	AND A2_LOJA = ZLF_A2LOJA
	AND ZLF_FILIAL = ZL8_FILIAL
	AND ZLF_EVENTO = ZL8_COD
	%exp:_cFiltro%
	AND ZLF_CODZLE = %exp:MV_PAR02%
	AND ZLF_A2COD BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
	AND ZLF_A2LOJA BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR08%
	GROUP BY ZL8_NREDUZ, ZLF_DEBCRE)
EndSql

While (_cAliasEve)->(!Eof())
	_cPivot := "%"+AllTrim((_cAliasEve)->PIVO)+"%"
	//Ajustes para retirar caracter que o SQL Embedded está incluindo
	_cPivot := Replace(_cPivot,"' ", "'")
	_cPivot := Replace(_cPivot," '", "'")
	_cPivot := Replace(_cPivot,"XXAS", " AS")
	_cCampos := "%"+AllTrim((_cAliasEve)->CAMPOS)+"%"
	_aCampos := StrTokArr((_cAliasEve)->ARRAY,';')
	(_cAliasEve)->(DBSkip())
EndDo

TRCell():New(oReport:Section(1),"DEBITO",/*Table*/,"Debito"/*cTitle*/,"@E 999,999,999.99"/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oReport:Section(1),"TOTLIQ",/*Table*/,"Total Líquido"/*cTitle*/,"@E 999,999,999.99"/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oReport:Section(1),"TOTBRUT",/*Table*/,"Total Bruto"/*cTitle*/,"@E 999,999,999.99"/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

For _nX := 1 to Len(_aCampos)
	TRCell():New(oReport:Section(1),_aCampos[_nX],/*Tabela*/,_aCampos[_nX]/*cTitle*/,"@E 999,999,999.99"/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,0/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
Next _nX

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

oQbrFilial := TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZLF_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
For _nX := 1 to Len(_aCampos)
	TRFunction():New(oReport:Section(1):Cell(_aCampos[_nX])/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
Next _nX
oTotVol 	:= TRFunction():New(oReport:Section(1):Cell("ZLF_QTDBOM")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
oTotLiq 	:= TRFunction():New(oReport:Section(1):Cell("TOTLIQ")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ZLF_VLRLTR")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,{||oTotLiq:GetValue()/oTotVol:GetValue()}/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("TOTBRUT")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("DEBITO")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
SELECT ZLF_FILIAL, ZLF_CODZLE, ZLF_SETOR, ZLF_LINROT, ZLF_A2COD, ZLF_A2LOJA, PRODUTOR, A2_L_CLASS, A2_L_TANQ, A2_L_TANLJ, 
RESPONSAVEL, AVG(ZLF_QTDBOM) ZLF_QTDBOM, SUM(TOTBRUT) TOTBRUT, SUM(DEBITO) DEBITO, SUM(TOTLIQ) TOTLIQ,
Round((SUM(TOTLIQ))/DECODE(MAX(NVL(ZLF_QTDBOM,0)),0,1,MAX(NVL(ZLF_QTDBOM,0))),4)  ZLF_VLRLTR,
%exp:_cCampos%
FROM (
SELECT ZLF_FILIAL, ZLF_CODZLE, ZLF_SETOR, ZLF_LINROT, ZLF_A2COD, ZLF_A2LOJA, SA2.A2_NOME PRODUTOR, SA2.A2_L_CLASS, SA2.A2_L_TANQ, 
SA2.A2_L_TANLJ, ZLF_RETIRO, ZLF_RETILJ, RESP.A2_NOME RESPONSAVEL, ZLF_EVENTO, 
(SELECT SUM(ZLD_QTDBOM) FROM %Table:ZLD%
WHERE D_E_L_E_T_ = ' '
AND ZLD_FILIAL = ZLF_FILIAL
AND ZLD_SETOR = ZLF_SETOR
AND ZLD_LINROT = ZLF_LINROT
AND ZLF_A2COD = Case WHEN SubStr(ZLF_A2COD,1,1)='G' THEN ZLD_FRETIS Else ZLD_RETIRO END
AND ZLF_A2LOJA = Case WHEN SubStr(ZLF_A2COD,1,1)='G' THEN ZLD_LJFRET Else ZLD_RETILJ END
AND ZLD_DTCOLE BETWEEN ZLF_DTINI AND ZLF_DTFIM)ZLF_QTDBOM,
SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else ZLF_TOTAL * -1 END) ZLF_TOTAL, ZL8_NREDUZ,
SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else ZLF_TOTAL * -1 END) TOTLIQ,
SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL END) TOTBRUT,
SUM(Case WHEN ZLF_DEBCRE = 'D' THEN ZLF_TOTAL END) DEBITO
 FROM %Table:ZLF% ZLF, %Table:SA2% SA2, %Table:ZL8% ZL8, %Table:SA2% RESP
WHERE ZLF.D_E_L_E_T_ = ' '
AND SA2.D_E_L_E_T_ = ' '
AND ZL8.D_E_L_E_T_ = ' '
AND RESP.D_E_L_E_T_ (+)= ' '
AND SA2.A2_COD = ZLF_A2COD
AND SA2.A2_LOJA = ZLF_A2LOJA
AND SA2.A2_L_TANQ = RESP.A2_COD (+)
AND SA2.A2_L_TANLJ = RESP.A2_LOJA (+)
AND ZLF_FILIAL = ZL8_FILIAL
AND ZLF_EVENTO = ZL8_COD
%exp:_cFiltro%
AND ZLF_CODZLE = %exp:MV_PAR02%
AND ZLF_A2COD BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
AND ZLF_A2LOJA BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR08%
GROUP BY SA2.A2_L_TANQ, SA2.A2_L_TANLJ, SA2.A2_L_CLASS, SA2.A2_NOME, RESP.A2_NOME, ZLF_FILIAL, ZLF_CODZLE, ZLF_SETOR, ZLF_LINROT, ZLF_A2COD,
		 ZLF_A2LOJA, ZL8_NREDUZ, ZLF_EVENTO, ZLF_QTDBOM, ZLF_DTINI, ZLF_DTFIM, ZLF_RETIRO, ZLF_RETILJ)
PIVOT ( SUM(ZLF_TOTAL) For ZL8_NREDUZ IN ( 
%exp:_cPivot%
))
GROUP BY ZLF_FILIAL, ZLF_CODZLE, ZLF_SETOR, ZLF_LINROT, ZLF_A2COD, ZLF_A2LOJA, PRODUTOR, A2_L_CLASS, A2_L_TANQ, A2_L_TANLJ, RESPONSAVEL
ORDER BY ZLF_FILIAL, %exp:_cOrder%
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
	If SubStr(MV_PAR05,1,1)=="G" .And. SubStr(MV_PAR06,1,1)=="G"
		_nVolume += (_cAlias)->ZLF_QTDBOM
	ElseIf SubStr((_cAlias)->ZLF_A2COD,1,1)=="P"
		_nVolume += (_cAlias)->ZLF_QTDBOM
	EndIf
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

//==========================================================================
// Query do relatório da secao 2
//==========================================================================
oReport:Section(2):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
SELECT ZL8_COD, ZL8_NREDUZ,
       SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL END) CREDITO,
       SUM(Case WHEN ZLF_DEBCRE = 'D' THEN ZLF_TOTAL * -1 END) DEBITO,
	   SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else ZLF_TOTAL * -1 END) LIQ
 FROM %Table:ZLF% ZLF, %Table:SA2% SA2, %Table:ZL8% ZL8
WHERE ZLF.D_E_L_E_T_ = ' '
AND SA2.D_E_L_E_T_ = ' '
AND ZL8.D_E_L_E_T_ = ' '
AND SA2.A2_COD = ZLF_A2COD
AND SA2.A2_LOJA = ZLF_A2LOJA
AND ZLF_FILIAL = ZL8_FILIAL
AND ZLF_EVENTO = ZL8_COD
%exp:_cFiltro%
AND ZLF_CODZLE = %exp:MV_PAR02%
AND ZLF_A2COD BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
AND ZLF_A2LOJA BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR08%
GROUP BY ZL8_COD, ZL8_NREDUZ
ORDER BY ZL8_COD, ZL8_NREDUZ
EndSql
//==========================================================================
// Metodo EndQuery ( Classe TRSection )                                     
//                                                                          
// Prepara o relatório para executar o Embedded SQL.                        
//                                                                          
// ExpA1 : Array com os parametros do tipo Range                            
//                                                                          
//==========================================================================
oReport:Section(2):EndQuery(/*Array com os parametros do tipo Range*/)

//=======================================================================
//Impressao do Relatorio
//=======================================================================
oReport:Section(2):Init()

oReport:SetMsgPrint("Imprimindo")
oReport:SetMeter(_nCountRec)

While !oReport:Cancel() .And. (_cAlias)->(!Eof())
	oReport:Section(2):PrintLine()
	oReport:IncMeter()
	_nCredito += (_cAlias)->CREDITO
	_nDebito += (_cAlias)->DEBITO
	(_cAlias)->(DBSkip())
EndDo

oReport:SkipLine()
oReport:SkipLine()
oReport:Section(2):Cell("ZL8_COD"):SetBlock({|| 'Total' })
oReport:Section(2):Cell("CREDITO"):SetBlock({|| _nCredito })
oReport:Section(2):Cell("DEBITO"):SetBlock({|| _nDebito })
oReport:Section(2):PrintLine()
oReport:SkipLine()
oReport:Section(2):Cell("ZL8_COD"):SetBlock({|| 'Valor Liquido' })
oReport:Section(2):Cell("CREDITO"):SetBlock({|| _nCredito+_nDebito })
oReport:Section(2):Cell("DEBITO"):SetBlock({|| 0 })
oReport:Section(2):PrintLine()
oReport:SkipLine()
oReport:Section(2):Cell("ZL8_COD"):SetBlock({|| 'Volume Total' })
oReport:Section(2):Cell("CREDITO"):SetBlock({|| _nVolume })
oReport:Section(2):PrintLine()

(_cAlias)->(DBCloseArea())

Return
