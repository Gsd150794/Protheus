/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |13/12/2017| Chamado 22718. Correção na regra do Incentivo à Produção.
Lucas Borges  |30/08/2019| Chamado 28346. Correção da barra de progresso.
Lucas Borges  |27/09/2019| Chamado 28346. Revisão de fontes.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT064
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 04/12/2017
Descrição---------: Mapa Analítico Anual - Relatório de volume anual de produtores, mês a mês para avaliação do limite atingido,
					que interfere no cálculo de impostos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT064

Local oReport
Pergunte("RGLT064",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 04/12/2017
Descrição---------: Processa a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport	:= Nil
Local oSection1	:= Nil
Local _aOrdem   := {"Por Filial"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New( "RGLT064" , "Mapa Analítico Anual", "RGLT064" , {|oReport| ReportPrint(oReport,_aOrdem) } , "Mapa Analítico Anual" , .T. )
oSection := TRSection():New(oReport,""	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,/*uTotalText*/)
oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"cPeriodo",/*cAlias*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

oSection1 := TRSection():New(oSection,""	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,/*uTotalText*/)
oSection1:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection1,"_cRaz",/*cAlias*/,"Razão Social: "/*cTitle*/,/*Picture*/,60/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

oSection2 := TRSection():New(oSection,""	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,/*uTotalText*/)
oSection2:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection2,"FILIAL",/*cAlias*/,"Filial"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection2,"RETIRO",/*cAlias*/,"Produtor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection2,"A2_NOME","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection2,"A2_INSCR","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection2,"LOJAS",/*cAlias*/,/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection2,"SETORES",/*cAlias*/,"Setores"/*cTitle*/,/*Picture*/,40/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

oSection3 := TRSection():New(oSection,""	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,/*uTotalText*/)
oSection3:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection3,"n01",/*cAlias*/,"01"/*cTitle*/,"@E 999999"/*Picture*/,06/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection3,"n02",/*cAlias*/,"02"/*cTitle*/,"@E 999999"/*Picture*/,06/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection3,"n03",/*cAlias*/,"03"/*cTitle*/,"@E 999999"/*Picture*/,06/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection3,"n04",/*cAlias*/,"04"/*cTitle*/,"@E 999999"/*Picture*/,06/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection3,"n05",/*cAlias*/,"05"/*cTitle*/,"@E 999999"/*Picture*/,06/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection3,"n06",/*cAlias*/,"06"/*cTitle*/,"@E 999999"/*Picture*/,06/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection3,"n07",/*cAlias*/,"07"/*cTitle*/,"@E 999999"/*Picture*/,06/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection3,"n08",/*cAlias*/,"08"/*cTitle*/,"@E 999999"/*Picture*/,06/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection3,"n09",/*cAlias*/,"09"/*cTitle*/,"@E 999999"/*Picture*/,06/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection3,"n10",/*cAlias*/,"10"/*cTitle*/,"@E 999999"/*Picture*/,06/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection3,"n11",/*cAlias*/,"11"/*cTitle*/,"@E 999999"/*Picture*/,06/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection3,"n12",/*cAlias*/,"12"/*cTitle*/,"@E 999999"/*Picture*/,06/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection3,"nVol",/*cAlias*/,"Litragem Total"/*cTitle*/,"@E 999999999999"/*Picture*/,12/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return( oReport )

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 29/11/2017
Descrição---------: Processa a impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro		:= "%"
Local _cAlias		:= ""
Local _cAlias2		:= " "
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-Agrupa por filial 2-Agrupa também por Setor
Local _cCampos		:= "%"
Local _cFrom		:= "%"
Local _cGroup		:= "%"
Local _nCountRec	:= 0
Local _cQuery		:= " "
Local _dDataFim		:= Posicione("ZLE",1,xFilial("ZLE")+MV_PAR01,"ZLE_DTFIM")
Local _dDataIni		:= SToD( cValToChar( Year( _dDataFim ) ) + '0101' )
Local _cAux			:= "ZLD"
Local n01			:= 0
Local n02			:= 0
Local n03			:= 0
Local n04			:= 0
Local n05			:= 0
Local n06			:= 0
Local n07			:= 0
Local n08			:= 0
Local n09			:= 0
Local n10			:= 0
Local n11			:= 0
Local n12			:= 0
Local nVol			:= 0

If MV_PAR04 == 2
	_cAux:='ZLW'
EndIf

//Chama função que permitirá a seleção das filiais
If MV_PAR07 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,_cAux)
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
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
oReport:Section(1):Section(3):Cell("n01"):SetBlock({||n01 })
oReport:Section(1):Section(3):Cell("n02"):SetBlock({||n02 })
oReport:Section(1):Section(3):Cell("n03"):SetBlock({||n03 })
oReport:Section(1):Section(3):Cell("n04"):SetBlock({||n04 })
oReport:Section(1):Section(3):Cell("n05"):SetBlock({||n05 })
oReport:Section(1):Section(3):Cell("n06"):SetBlock({||n06 })
oReport:Section(1):Section(3):Cell("n07"):SetBlock({||n07 })
oReport:Section(1):Section(3):Cell("n08"):SetBlock({||n08 })
oReport:Section(1):Section(3):Cell("n09"):SetBlock({||n09 })
oReport:Section(1):Section(3):Cell("n10"):SetBlock({||n10 })
oReport:Section(1):Section(3):Cell("n11"):SetBlock({||n11 })
oReport:Section(1):Section(3):Cell("n12"):SetBlock({||n12 })
oReport:Section(1):Section(3):Cell("nVol"):SetBlock({||nVol })
oReport:Section(1):Section(1):Cell("_cRaz"):SetBlock({||_cRaz })

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cCampos += _cAux+"_FILIAL FILIAL, "+_cAux+"_RETIRO RETIRO, "+_cAux+"_RETILJ LOJA, "+_cAux+"_SETOR SETOR, SUM("+_cAux+"_QTDBOM) VOLUME %"
_cFrom := "%"+RetSqlName(_cAux)+" %"
_cFiltro += " AND "+_cAux+"_FILIAL "+ GetRngFil( _aSelFil, _cAux, .T.,)
_cFiltro += " AND "+_cAux+"_RETIRO BETWEEN '"+ MV_PAR02 +"' AND '"+ MV_PAR03 + "'"
_cFiltro += " AND "+_cAux+"_DTCOLE BETWEEN '"+ DToS(_dDataIni) +"' AND '"+ DToS(_dDataFim) + "'%"
_cGroup += _cAux+"_FILIAL, "+_cAux+"_RETIRO, "+_cAux+"_RETILJ, "+_cAux+"_SETOR %"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):Section(2):BeginQuery()
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
SELECT FILIAL, RETIRO, A2_INSCR, A2_NOME, SUM(VOLUME) VOLUME,
		LISTAGG(SETOR, '; ') WITHIN GROUP(ORDER BY SETOR) SETORES,
			LISTAGG(LOJA, '; ') WITHIN GROUP(ORDER BY LOJA) LOJAS
		FROM %Table:SA2% SA2,
		        (SELECT %exp:_cCampos%
           FROM %exp:_cFrom%
          WHERE D_E_L_E_T_ = ' '
			%exp:_cFiltro%
          GROUP BY %exp:_cGroup%)
  WHERE SA2.D_E_L_E_T_ = ' '
    AND SA2.A2_COD = RETIRO
    AND SA2.A2_LOJA = LOJA
  GROUP BY FILIAL, RETIRO, A2_INSCR, A2_NOME
 HAVING SUM(VOLUME) BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
 ORDER BY FILIAL, RETIRO
EndSql
//==========================================================================
// Metodo EndQuery ( Classe TRSection )                                     
//                                                                          
// Prepara o relatório para executar o Embedded SQL.                        
//                                                                          
// ExpA1 : Array com os parametros do tipo Range                            
//                                                                          
//==========================================================================
oReport:Section(1):Section(2):EndQuery(/*Array com os parametros do tipo Range*/)

//=======================================================================
//Impressao do Relatorio
//=======================================================================
Count To _nCountRec
(_cAlias)->( DBGoTop() )
oReport:SetMsgPrint("Imprimindo")
oReport:SetMeter(_nCountRec)

oReport:Section(1):Section(1):Init()
oReport:Section(1):Section(1):Cell("_cRaz"):SetValue( SM0->M0_NOMECOM )
oReport:Section(1):Section(1):PrintLine()
oReport:Section(1):Section(1):Finish()

oReport:Section(1):Section(2):Init()
oReport:Section(1):Section(3):Init()

While !oReport:Cancel() .And. (_cAlias)->( !Eof() )
	oReport:IncMeter()	
	_cAlias2	:= GetNextAlias()

	_cQuery := " SELECT SubStr("+_cAux+"_DTCOLE, 5, 2) MES,"
	_cQuery += "        SUM("+_cAux+"_QTDBOM) TOTAL_MES"
	_cQuery += "  FROM "+ RetSqlName(_cAux) +" , "+ RetSqlName('SA2') +" SA2"
	_cQuery += " WHERE "+RetSqlName(_cAux)+".D_E_L_E_T_ = ' '"
	_cQuery += "   AND SA2.D_E_L_E_T_ = ' '"
	_cQuery += "   AND SA2.A2_COD = "+_cAux+"_RETIRO"
	_cQuery += "   AND SA2.A2_LOJA = "+_cAux+"_RETILJ"
	_cQuery += "   AND SA2.A2_INSCR  ='"+(_cAlias)->A2_INSCR+"'"
	_cQuery += "   AND "+_cAux+"_FILIAL = '"+(_cAlias)->FILIAL+"'"
	_cQuery += "   AND "+_cAux+"_DTCOLE BETWEEN '"+ DToS(_dDataIni) +"' AND '"+ DToS(_dDataFim) + "'"
	_cQuery += "   AND "+_cAux+"_RETIRO = '"+(_cAlias)->RETIRO+"'"
	_cQuery += " GROUP BY SubStr("+_cAux+"_DTCOLE, 5, 2)"

	DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAlias2 , .F. , .T. )
	
	nVol:= (_cAlias)->VOLUME
	While (_cAlias2)->( !Eof() )
	
		&("n"+(_cAlias2)->MES) := (_cAlias2)->TOTAL_MES
	(_cAlias2)->( DBSkip() )
	EndDo
	
	(_cAlias2)->(DBCloseArea())
	
	oReport:Section(1):Section(2):PrintLine()
	oReport:Section(1):Section(3):PrintLine()
	oReport:Section(1):Section(2):Finish()
	oReport:Section(1):Section(3):Finish()
	oReport:Section(1):Section(2):Init()
	oReport:Section(1):Section(3):Init()

	nVol := n01	:= n02 := n03 := n04 := n05 := n06 := n07 := n08 := n09 := n10 := n11 := n12 := 0
	
	(_cAlias)->( DBSkip() )
EndDo

oReport:Section(1):Section(1):Finish()
oReport:Section(1):Section(1):Init()

oReport:Section(1):Section(2):Finish()
oReport:Section(1):Section(2):Init()

oReport:Section(1):Section(3):Finish()
oReport:Section(1):Section(3):Init()

oReport:Section(1):Finish()
oReport:Section(1):Init()

Return
