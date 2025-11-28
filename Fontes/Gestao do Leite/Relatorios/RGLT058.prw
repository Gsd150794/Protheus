/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |24/06/2019| Chamado 28346. Revisão de fontes.
Lucas Borges  |29/08/2019| Chamado 28346. Correção da barra de progresso.
Lucas Borges  |11/11/2019| Chamado 31136. Ajuste nos campos de hora.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT058
Autor-------------: Josué Danich Prestes
Data da Criacao---: 11/08/2015
Descrição---------: Relatório de tempo de veículos na fábrica
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT058()

Local oReport
Pergunte("RGLT058",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 23/04/2019
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Por Produto"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT058","Leite de terceiros - Tempo de veículos na fábrica","RGLT058",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Lista o tempo de permanencia na fábrica para o Leite de Terceiros, acordo com os parâmetros informados")
oSection := TRSection():New(oReport,"Relação Movimentos"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/,.T./*lTotalInLine*/)
oReport:SetLandscape()//Paisagem
oSection:lForceLineStyle:= .T.
oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZZX_FILIAL","ZZX",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZZX_CODPRD","ZZX","Prod."/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"X5_DESCRI",/*Tabela*/,"Desc. Prod"/*cTitle*/,/*Picture*/,25/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_CODIGO","ZLX",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_STATUS","ZLX",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NREDUZ_T",/*Tabela*/,"Transportadora"/*cTitle*/,/*Picture*/,40/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_PLACA","ZLX","Placa"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZZV_FXCAPA","ZZV","Cap."/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NREDUZ_F",/*Tabela*/,"Fornecedor"/*cTitle*/,/*Picture*/,40/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_NRONF","ZLX",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ENTRADA",/*Tabela*/,"Entrada"/*cTitle*/,/*Picture*/,16/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"SAIDA",/*Tabela*/,"Saída"/*cTitle*/,/*Picture*/,16/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PERMANENCIA",/*Tabela*/,"Tempo na Fáb."/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"MEDPERM",/*Tabela*/,"Média perma."/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,"RIGHT"/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 23/04/2019
Descrição---------: Relacao de movimentos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro		:= "%"
Local _cOrder		:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-Agrupa por filial 2-Agrupa também por Setor
Local _cFilial		:= ""
Local _cProd		:= ""
Local _nCountRec	:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZLX")
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

//==========================================================================
// Difine Células que não serão impressas
//==========================================================================
oReport:Section(1):Cell("ENTRADA"):SetBlock({||DToC((_cAlias)->ZLX_DATAEN)+ ' - ' + (_cAlias)->ZLX_HRENTR})
//Necessário incluir os : porque o gênio que criou a rotina não conseguiu seguir um padrão. Tratar no futuro.
oReport:Section(1):Cell("SAIDA"):SetBlock({||DToC((_cAlias)->ZLX_DTSAID)+ ' - ' + (_cAlias)->ZLX_HRSAID})
oReport:Section(1):Cell("MEDPERM"):SetBlock({||(_cAlias)->PERMANENCIA})

//================================================================================
//| Configuração das quebras do relatório                                        |
//================================================================================
oQbrPrd	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZZX_CODPRD")/*uBreak*/, {||"Total do Produto: " + _cProd +;
 Space(120) + "Total Permanência"+Space(5)+"Média Permanência"}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)

oTotQtd:= TRFunction():New(oReport:Section(1):Cell("ZZX_FILIAL")/*oCell*/,"QTD"/*cName*/,"COUNT"/*cFunction*/,oQbrPrd/*oBreak*/,"Viagens"/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
oTotH:= TRFunction():New(oReport:Section(1):Cell("PERMANENCIA")/*oCell*/,"TOTAL"/*cName*/,"TIMESUM"/*cFunction*/,oQbrPrd/*oBreak*/,"Total de Permanência"/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("MEDPERM")/*oCell*/,"MEDIA"/*cName*/,"ONPRINT"/*cFunction*/,oQbrPrd/*oBreak*/,"Media de Permanência"/*cTitle*/,/*cPicture*/,{||;
StrZero(Int(Min2Hrs(Hrs2Min(oTotH:GetValue())/oTotQtd:GetValue())),4) + ":" + StrZero(Round(((Min2Hrs(Hrs2Min(oTotH:GetValue())/oTotQtd:GetValue())) - Int(Min2Hrs(Hrs2Min(oTotH:GetValue())/oTotQtd:GetValue()))) * 100,0),2);
}/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZZX_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )+;
 Space(135) + "Total Permanência"+Space(5)+"Média Permanência"}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
oTotFQtd:=TRFunction():New(oReport:Section(1):Cell("ZZX_FILIAL")/*oCell*/,"QTD"/*cName*/,"COUNT"/*cFunction*/,oQbrFilial/*oBreak*/,"Viagens"/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
oTotFH:= TRFunction():New(oReport:Section(1):Cell("PERMANENCIA")/*oCell*/,"TOTAL"/*cName*/,"TIMESUM"/*cFunction*/,oQbrFilial/*oBreak*/,"Total de Permanência"/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("MEDPERM")/*oCell*/,"MEDIA"/*cName*/,"ONPRINT"/*cFunction*/,oQbrFilial/*oBreak*/,"Media de Permanência"/*cTitle*/,/*cPicture*/,{||;
StrZero(Int(Min2Hrs(Hrs2Min(oTotFH:GetValue())/oTotFQtd:GetValue())),4) + ":" + StrZero(Round(((Min2Hrs(Hrs2Min(oTotFH:GetValue())/oTotFQtd:GetValue())) - Int(Min2Hrs(Hrs2Min(oTotFH:GetValue())/oTotFQtd:GetValue()))) * 100,0),2);
}/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZLX_FILIAL "+ GetRngFil( _aSelFil, "ZLX", .T.,)

//Verifica se foi fornecido o filtro de Código do produto
If !Empty(MV_PAR19)
	_cFiltro += " AND ZZX.ZZX_CODPRD IN " + FormatIn(MV_PAR19,";")
EndIf

//Verifica se foi fornecido o filtro de Placa
If !Empty(MV_PAR21)
	_cFiltro += " AND ZLX.ZLX_PLACA IN " + FormatIn(MV_PAR21,";")
EndIf

//Verifica se foi fornecido o filtro de Faixa de Capacidade
If !Empty(MV_PAR10)
	_cFiltro += " AND ZZV.ZZV_FXCAPA IN " + FormatIn(MV_PAR10,";")
EndIf

//Verifica se foi fornecido o filtro de Status
If !Empty(MV_PAR17)
	_cFiltro += " AND ZLX.ZLX_STATUS IN " + FormatIn(MV_PAR17,";")
EndIf

If !Empty(MV_PAR20) .And. MV_PAR20 < 4 
	_cFiltro += " AND ZLX.ZLX_TIPOLT = "
	If MV_PAR20 == 1 
		_cFiltro += " 'F' "
	ElseIf MV_PAR20 == 2
		_cFiltro += " 'T' "
	ElseIf MV_PAR20 == 3
		_cFiltro += " 'P' "
	EndIf
EndIf

If MV_PAR18 == 1      // Ordem de data/hora entrada
	_cOrder += " ZLX.ZLX_DATAEN, ZLX.ZLX_HRENTR"
ElseIf MV_PAR18 == 2 // Maior tempo na fábrica
	_cOrder += " PERMANENCIA DESC"
ElseIf MV_PAR18 == 3 // Menor tempo na fábrica
	_cOrder += " PERMANENCIA"
EndIf

_cFiltro += "%"
_cOrder += "%"
//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
	SELECT ZZX.ZZX_FILIAL, ZZX.ZZX_CODPRD, SX5.X5_DESCRI DESCRI, ZLX.ZLX_CODIGO, ZLX.ZLX_STATUS, SA2T.A2_NREDUZ A2_NREDUZ_T, ZLX.ZLX_PLACA, ZZV.ZZV_FXCAPA,
	       SA2F.A2_NREDUZ A2_NREDUZ_F, ZLX.ZLX_NRONF, ZLX.ZLX_DATAEN, ZLX.ZLX_HRENTR, ZLX.ZLX_DTSAID,
	       ZLX.ZLX_HRSAID, LPAD(TRUNC((TO_DATE(ZLX.ZLX_DTSAID || ZLX.ZLX_HRSAID,'YYYYMMDDhh24:mi') -
	       TO_DATE(ZLX.ZLX_DATAEN || ZLX.ZLX_HRENTR,'YYYYMMDDhh24:mi')) * 24),4,'0') || ':' ||
	       LPAD(Round(MOD((TO_DATE(ZLX.ZLX_DTSAID || ZLX.ZLX_HRSAID,'YYYYMMDDhh24:mi') - TO_DATE(ZLX.ZLX_DATAEN || ZLX.ZLX_HRENTR,
	       'YYYYMMDDhh24:mi')) * 24,1) * 60,2),2,'0') PERMANENCIA
	  FROM %Table:ZLX% ZLX, %Table:SA2% SA2T, %Table:SA2% SA2F, %Table:ZZX% ZZX, %Table:ZZV% ZZV, %Table:SX5% SX5
	 WHERE ZLX.D_E_L_E_T_ = ' '
	   AND SA2T.D_E_L_E_T_ = ' '
	   AND SA2F.D_E_L_E_T_ = ' '
	   AND ZZX.D_E_L_E_T_ = ' '
	   AND ZZV.D_E_L_E_T_ = ' '
	   AND SX5.D_E_L_E_T_ = ' '
	   AND ZLX.ZLX_FILIAL = ZZV.ZZV_FILIAL
	   AND ZZV.ZZV_FILIAL = ZZX.ZZX_FILIAL
	   AND ZLX.ZLX_FORNEC = SA2F.A2_COD
	   AND ZLX.ZLX_LJFORN = SA2F.A2_LOJA
	   AND ZLX.ZLX_TRANSP = SA2T.A2_COD
	   AND ZLX.ZLX_LJTRAN = SA2T.A2_LOJA
	   AND ZZX.ZZX_CODIGO = ZLX.ZLX_CODANA
	   AND ZZX.ZZX_PLACA = ZZV.ZZV_PLACA
	   AND ZZV.ZZV_TRANSP = ZLX.ZLX_TRANSP
	   AND ZZV.ZZV_LJTRAN = ZLX.ZLX_LJTRAN
	   AND SX5.X5_TABELA = 'Z7'
	   AND ZZX.ZZX_CODPRD = SX5.X5_CHAVE
   	   %exp:_cFiltro%
	   AND ZLX.ZLX_DTENTR BETWEEN %exp:MV_PAR11% AND %exp:MV_PAR12%
	   AND ZLX.ZLX_DATAEN BETWEEN %exp:MV_PAR13% AND %exp:MV_PAR14%
	   AND ZLX.ZLX_DTSAID BETWEEN %exp:MV_PAR15% AND %exp:MV_PAR16%
	   AND ZLX.ZLX_FORNEC BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR04%
	   AND ZLX.ZLX_LJFORN BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR05%
	   AND ZLX.ZLX_TRANSP BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR08%
	   AND ZLX.ZLX_LJTRAN BETWEEN %exp:MV_PAR07% AND %exp:MV_PAR09%
	 ORDER BY ZZX.ZZX_CODPRD, %exp:_cOrder%
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
//Inibindo celulas, utilizadas apenas para totalizadores
//=======================================================================
oReport:Section(1):Cell("MEDPERM"):Hide()
oReport:Section(1):Cell("MEDPERM"):HideHeader()

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
  	_cFilial := (_cAlias)->ZZX_FILIAL
	_cProd := (_cAlias)->ZZX_CODPRD + ' - ' + (_cAlias)->DESCRI
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
