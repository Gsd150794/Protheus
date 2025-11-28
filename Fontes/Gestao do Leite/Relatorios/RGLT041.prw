/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |30/08/2019| Chamado 28346. Incluído campo ZLX_LISTA para pode descontinuar RGLT063.
Lucas Borges  |16/08/2022| Chamado 41037. Corrigida query para não considerar pre-notas.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT041
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 19/07/2019
Descrição---------: Relatório Movimentação do Leite Cooperativa X Entrada Estoque Efetiva. Litas as recepções do Leite de Cooperativa para
					avaliar as datas das recepções x movimentação de estoque. Chamado 30038
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT041()

Local oReport
Pergunte("RGLT041",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 19/07/2019
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

oReport := TReport():New("RGLT041","Movimentação do Leite Cooperativa X Entrada Estoque Efetiva","RGLT041",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Confronta a movimentação das recepções do Leite de Oooperativa com a data de movimentação do estoque efetiva.")
oSection := TRSection():New(oReport,"Movimentos"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem

oSection:SetTotalInLine(.T.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZLX_FILIAL","ZLX",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PRODUTO",/*Table*/,"Produto"/*cTitle*/,/*Picture*/,25/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"FORNECEDOR",/*Table*/,"Fornecedor"/*cTitle*/,/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"NOME_FOR",/*Table*/,"Razão Social"/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TRANSP",/*Table*/,"Transportador"/*cTitle*/,/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"NOME_TRAN",/*Table*/,"Razão Social"/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_CODIGO","ZLX","Recepção"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_TIPOLT","ZLX",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_DOC",/*Table*/,"Doc/Ticket"/*cTitle*/,/*Picture*/,10/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_PLACA","ZLX","Placa"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_VOLREC","ZLX",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_VOLNF","ZLX",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_DIFVOL","ZLX",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"F1_DTDIGIT",/*Table*/,"Dt. Estoq."/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_DTENTR","ZLX","Dt. Recep."/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_DTESTO","ZLX",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLX_LISTA","ZLX",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 19/07/2019
Descrição---------: Processa impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro		:= "%"
Local _cFiltroSD3	:= ""
Local _cFiltroSF1	:= ""
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-Agrupa por filial 2-Agrupa também por Setor
Local _cFilial		:= ""
Local _cProd		:= ""
Local _lPlanilha 	:= oReport:nDevice == 4
Local _nCountRec	:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR14 == 1
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

//================================================================================
//| Configuração das quebras do relatório                                        |
//================================================================================
oQbrProd	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("PRODUTO") /*uBreak*/, {||"Produto: " + _cProd} /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("ZLX_CODIGO")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrProd/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ZLX_VOLREC")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrProd/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ZLX_VOLNF")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrProd/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ZLX_DIFVOL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrProd/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZLX_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("ZLX_CODIGO")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ZLX_VOLREC")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ZLX_VOLNF")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ZLX_DIFVOL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If !_lPlanilha
	oReport:Section(1):Cell("ZLX_LISTA"):Disable()
EndIf
//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZLX.ZLX_FILIAL "+ GetRngFil( _aSelFil, "ZLX", .T.,)
If MV_PAR03 < 4
	_cFiltro += " AND ZLX.ZLX_TIPOLT = '"+ IIf( MV_PAR03 == 1 , 'F' , IIf( MV_PAR03 == 2 , 'T' , 'P' ) ) +"' "
EndIf
If !Empty( MV_PAR04 )
	_cFiltro += " AND ZZX.ZZX_CODPRD IN "+ FormatIn( AllTrim(MV_PAR04) , ';' )
EndIf

If !Empty( MV_PAR13 )
	_cFiltro += " AND ZLX.ZLX_PLACA  IN "+ FormatIn( AllTrim( MV_PAR13 ) , ';' )
EndIf

If !Empty( MV_PAR19 )
	_cFiltro += " AND ZLX.ZLX_STATUS IN "+ FormatIn( AllTrim( MV_PAR19 ) , ';' )
EndIf

_cFiltroSF1 += _cFiltro
_cFiltroSD3 += _cFiltro
If MV_PAR22 <> 3
	_cFiltroSF1 += " AND SF1.F1_DTDIGIT " +IIf(MV_PAR22==1,"<>","=")+ " ZLX_DTENTR "
	_cFiltroSD3 += " AND SD3.D3_EMISSAO " +IIf(MV_PAR22==1,"<>","=")+ " ZLX_DTENTR "
EndIf
_cFiltro += "%"
_cFiltroSF1 += "%"
_cFiltroSD3 += "%"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
	SELECT ZLX_FILIAL, ZZX_CODPRD||'-'||X5_DESCRI PRODUTO, ZLX_CODIGO, ZLX_TIPOLT, F1_DOC, ZLX_FORNEC||'-'||ZLX_LJFORN FORNECEDOR, SA2F.A2_NOME NOME_FOR,
			ZLX_TRANSP||'-'||ZLX_LJTRAN TRANSP, SA2T.A2_NOME NOME_TRAN, ZLX_PLACA, ZLX_VOLREC, ZLX_VOLNF, ZLX_DIFVOL, F1_DTDIGIT, ZLX_DTENTR, ZLX_DTESTO, ZLX_LISTA
	  FROM %Table:SX5% SX5, %Table:SA2% SA2F, %Table:SA2% SA2T,
	       (SELECT ZLX_FILIAL, ZLX_CODIGO, ZLX_TIPOLT, F1_DOC, ZLX_FORNEC, ZLX_LJFORN, ZLX_TRANSP,ZLX_LJTRAN,
	               ZLX_PLACA, ZLX_VOLREC, ZLX_VOLNF, ZLX_DIFVOL, F1_DTDIGIT, ZLX_DTENTR, ZLX_DTESTO, ZZX_CODPRD, UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SubStr(ZLX_LISTA, 500, 1)) ZLX_LISTA
	          FROM ZLX010 ZLX, ZZX010 ZZX, SF1010 SF1
	         WHERE ZLX.D_E_L_E_T_ = ' '
	           AND ZZX.D_E_L_E_T_ = ' '
	           AND SF1.D_E_L_E_T_ = ' '
	           AND ZLX.ZLX_FILIAL = ZZX.ZZX_FILIAL
	           AND ZLX.ZLX_CODANA = ZZX.ZZX_CODIGO
	           AND ZLX.ZLX_FILIAL = SF1.F1_FILIAL
	           AND ZLX.ZLX_NRONF = SF1.F1_DOC
	           AND ZLX.ZLX_SERINF = SF1.F1_SERIE
	           AND ZLX.ZLX_FORNEC = SF1.F1_FORNECE
	           AND ZLX.ZLX_LJFORN = SF1.F1_LOJA
			   AND SF1.F1_STATUS = 'A'
	           %exp:_cFiltroSF1%
	           AND SF1.F1_DTDIGIT BETWEEN %exp:MV_PAR20% AND %exp:MV_PAR21%
	           AND ZLX.ZLX_DTENTR BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	           AND ZLX.ZLX_FORNEC BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07% 
	           AND ZLX.ZLX_LJFORN BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR08%
	           AND ZLX.ZLX_TRANSP BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR11%
	           AND ZLX.ZLX_LJTRAN BETWEEN %exp:MV_PAR10% AND %exp:MV_PAR12%
	           AND ZLX.ZLX_NRONF BETWEEN %exp:MV_PAR15% AND %exp:MV_PAR16%
	           AND ZLX.ZLX_CODIGO BETWEEN %exp:MV_PAR17% AND %exp:MV_PAR18%
	           AND ZLX.ZLX_ORIGEM = ' '
	        UNION
	        SELECT ZLX_FILIAL, ZLX_CODIGO, ZLX_TIPOLT, '', ZLX_FORNEC, ZLX_LJFORN, ZLX_TRANSP,ZLX_LJTRAN,
	               ZLX_PLACA, ZLX_VOLREC, ZLX_VOLNF, ZLX_DIFVOL, '', ZLX_DTENTR, ZLX_DTESTO, ZZX_CODPRD, UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SubStr(ZLX_LISTA, 500, 1)) ZLX_LISTA
	          FROM ZLX010 ZLX, ZZX010 ZZX
	         WHERE ZLX.D_E_L_E_T_ = ' '
	           AND ZZX.D_E_L_E_T_ = ' '
	           AND ZLX.ZLX_FILIAL = ZZX.ZZX_FILIAL
	           AND ZLX.ZLX_CODANA = ZZX.ZZX_CODIGO
	           %exp:_cFiltro%
	           AND ZLX.ZLX_DTENTR BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	           AND ZLX.ZLX_FORNEC BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07% 
	           AND ZLX.ZLX_LJFORN BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR08%
	           AND ZLX.ZLX_TRANSP BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR11%
	           AND ZLX.ZLX_LJTRAN BETWEEN %exp:MV_PAR10% AND %exp:MV_PAR12%
	           AND ZLX.ZLX_NRONF BETWEEN %exp:MV_PAR15% AND %exp:MV_PAR16%
	           AND ZLX.ZLX_CODIGO BETWEEN %exp:MV_PAR17% AND %exp:MV_PAR18%
	           AND ZLX.ZLX_ORIGEM = '1'
	        UNION
	        SELECT ZLX_FILIAL, ZLX_CODIGO, ZLX_TIPOLT, ZLX_TICKET, ZLX_FORNEC, ZLX_LJFORN, ZLX_TRANSP, ZLX_LJTRAN, 
	               ZLX_PLACA, ZLX_VOLREC, ZLX_VOLNF, ZLX_DIFVOL, D3_EMISSAO, ZLX_DTENTR, ZLX_DTESTO, ZZX_CODPRD, UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SubStr(ZLX_LISTA, 500, 1)) ZLX_LISTA
	          FROM ZLX010 ZLX, ZZX010 ZZX, SD3010 SD3
	         WHERE ZLX.D_E_L_E_T_ = ' '
	           AND ZZX.D_E_L_E_T_ = ' '
	           AND SD3.D_E_L_E_T_ = ' '
	           AND ZLX.ZLX_FILIAL = ZZX.ZZX_FILIAL
	           AND ZLX.ZLX_CODANA = ZZX.ZZX_CODIGO
	           AND ZLX.ZLX_FILIAL = SD3.D3_FILIAL
	           AND ZLX.ZLX_TICKET = SD3.D3_L_ORIG
	           %exp:_cFiltroSD3% 
	           AND SD3.D3_EMISSAO BETWEEN %exp:MV_PAR20% AND %exp:MV_PAR21%
	           AND ZLX.ZLX_DTENTR BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	           AND ZLX.ZLX_FORNEC BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07%
	           AND ZLX.ZLX_LJFORN BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR08%
	           AND ZLX.ZLX_TRANSP BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR11%
	           AND ZLX.ZLX_LJTRAN BETWEEN %exp:MV_PAR10% AND %exp:MV_PAR12%
	           AND ZLX.ZLX_NRONF BETWEEN %exp:MV_PAR15% AND %exp:MV_PAR16%
	           AND ZLX.ZLX_CODIGO BETWEEN %exp:MV_PAR17% AND %exp:MV_PAR18%
	           AND ZLX.ZLX_ORIGEM IN ('2', '3')
	           AND SD3.D3_ESTORNO <> 'S') A
	 WHERE SA2F.D_E_L_E_T_ = ' '
	   AND SA2T.D_E_L_E_T_ = ' '
	   AND SX5.D_E_L_E_T_ = ' '
	   AND SA2F.A2_COD = A.ZLX_FORNEC
	   AND SA2F.A2_LOJA = A.ZLX_LJFORN
	   AND SA2T.A2_COD = A.ZLX_TRANSP
	   AND SA2T.A2_LOJA = A.ZLX_LJTRAN
	   AND SX5.X5_CHAVE = A.ZZX_CODPRD
	   AND SX5.X5_TABELA = 'Z7'
	 ORDER BY ZLX_FILIAL, ZZX_CODPRD, ZLX_CODIGO, ZLX_FORNEC, ZLX_LJFORN, ZLX_DTENTR
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
	_cFilial := (_cAlias)->ZLX_FILIAL
	_cProd := (_cAlias)->PRODUTO
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
