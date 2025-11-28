/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |02/07/2019| Chamado 28346. Migração para tReport e incluída seleção de vários setores.
Lucas Borges  |27/08/2019| Chamado 28346. Corrigida a barra de progresso.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT042
Autor-------------: Fabiano Dias Silva
Data da Criacao---: 21/01/2010
Descrição---------: Resumo de Litragem e rendimentos de um fretista quebrando por municipio dentro de um determinado período
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT042()

Local oReport
Pergunte("RGLT042",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 26/06/2019
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Sintético","Analítico"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT042","Rendimento de transportadores","RGLT042",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Lista o Volume e Rendimentos dos transportadores de acordo com a ordem selecionada")
oSection := TRSection():New(oReport,"Produtores"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZLD_FILIAL","ZLD",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TRANS",/*cAlias*/,"Transportador"/*cTitle*/,/*Picture*/,/*Tamanho*/11,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2","Setor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2",/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_COD","ZL3","Linha"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_DESCRI","ZL3",/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CC2_CODMUN","CC2","Código"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CC2_MUN","CC2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"RENDIMENTO",/*cAlias*/,"Rendimentos"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOLUME",/*cAlias*/,"Vol. Transportado"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 26/06/2019
Descrição---------: Realiza a impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro1		:= "%"
Local _cFiltro2		:= "%"
Local _cCampo		:= "%"
Local _cGroup		:= "%"
Local _cOrder		:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-Sintético 2-Analítico
Local _lPlanilha 	:= oReport:nDevice == 4
Local _cFilial		:= ""
Local _nCountRec	:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR05 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZLD")
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
oQbrTrans	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("TRANS") /*uBreak*/, {||"Total do Transportador: " + _cTrans}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("RENDIMENTOS")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrTrans/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrTrans/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZLD_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("RENDIMENTOS")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If _nOrdem == 1 //1-Sintético 2-Analítico
	oReport:Section(1):Cell("ZL2_COD"):Disable()
	oReport:Section(1):Cell("ZL2_DESCRI"):Disable()
	oReport:Section(1):Cell("ZL3_COD"):Disable()
	oReport:Section(1):Cell("ZL3_DESCRI"):Disable()
Else
	If !_lPlanilha
		oReport:Section(1):Cell("ZL3_DESCRI"):Disable()
	EndIf
EndIf

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro1 += " AND ZLD.ZLD_FILIAL "+ GetRngFil( _aSelFil, "ZLD", .T.,)
_cFiltro2 += " AND ZLF.ZLF_FILIAL "+ GetRngFil( _aSelFil, "ZLD", .T.,)

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR01) .Or. Empty(MV_PAR01) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro1 += " AND ZLD.ZLD_SETOR IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
	_cFiltro2 += " AND ZLF.ZLF_SETOR IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR04)
	_cFiltro1 += " AND ZLD.ZLD_LINROT IN " + FormatIn(MV_PAR05,";")
	_cFiltro2 += " AND ZLF.ZLF_LINROT IN " + FormatIn(MV_PAR05,";")
EndIf

If _nOrdem == 1 //1-Sintético 2-Analítico
	_cCampo += ", ZL2.ZL2_COD, ZL2.ZL2_DESCRI, ZL3.ZL3_COD, ZL3.ZL3_DESCRI "
	_cGroup += ", ZL2.ZL2_COD, ZL2.ZL2_DESCRI, ZL3.ZL3_COD, ZL3.ZL3_DESCRI "
	_cOrder += ", ZL2.ZL2_COD, ZL3.ZL3_COD"
EndIf

_cCampo += "%"
_cGroup += "%"
_cOrder += "%"
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
	SELECT MOV.ZLD_FILIAL, SA2T.A2_COD||'-'||SA2T.A2_LOJA TRANS, SA2T.A2_NOME, CC2_CODMUN, CC2_MUN,
	       NVL(SUM(RENDIMENTO), 0) RENDIMENTO, SUM(VOLUME) VOLUME %exp:_cCampo%
	  FROM %Table:SA2% SA2T, %Table:SA2% SA2P, %Table:ZL2% ZL2, %Table:ZL3% ZL3, %Table:CC2% CC2,
	       (SELECT ZLD_FILIAL, ZLD_RETIRO, ZLD_RETILJ, ZLD_FRETIS, ZLD_LJFRET, ZLD_SETOR, ZLD_LINROT, SUM(ZLD_QTDBOM) VOLUME
	          FROM %Table:ZLD% ZLD
	         WHERE ZLD.D_E_L_E_T_ = ' '
	           AND ZLD_FRETIS <> ' '
	           AND ZLD_STATUS = 'F'
	           %exp:_cFiltro1%
	           AND ZLD_DTCOLE BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
	           AND ZLD_FRETIS BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
	           AND ZLD_LJFRET BETWEEN %exp:MV_PAR08% AND %exp:MV_PAR09%
	         GROUP BY ZLD_FILIAL, ZLD_RETIRO, ZLD_RETILJ, ZLD_FRETIS, ZLD_LJFRET, ZLD_SETOR, ZLD_LINROT) MOV,
	       (SELECT ZLF_FILIAL, ZLF_RETIRO, ZLF_RETILJ, ZLF_A2COD, ZLF_A2LOJA,  ZLF_SETOR, ZLF_LINROT, SUM(ZLF_TOTAL) RENDIMENTO
	          FROM %Table:ZLF% ZLF
	         WHERE ZLF.D_E_L_E_T_ = ' '
	           AND ZLF_STATUS = 'F'
	           AND ZLF_TP_MIX = 'F'
	           AND ZLF_DEBCRE = 'C'
	           AND SubStr(ZLF_A2COD, 1, 1) = 'G'
	           %exp:_cFiltro2%
	           AND ZLF_DTINI BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
	           AND ZLF_A2COD BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
	           AND ZLF_A2LOJA BETWEEN %exp:MV_PAR08% AND %exp:MV_PAR09%
	         GROUP BY ZLF_FILIAL, ZLF_RETIRO, ZLF_RETILJ, ZLF_A2COD, ZLF_A2LOJA, ZLF_SETOR, ZLF_LINROT) FIN
	 WHERE SA2T.D_E_L_E_T_ = ' '
	   AND SA2P.D_E_L_E_T_ = ' '
	   AND ZL2.D_E_L_E_T_ = ' '
	   AND ZL3.D_E_L_E_T_ = ' '
	   AND CC2.D_E_L_E_T_ = ' '
	   AND MOV.ZLD_FILIAL = ZL2_FILIAL
	   AND MOV.ZLD_FILIAL = ZL3_FILIAL
	   AND FIN.ZLF_FILIAL(+) = MOV.ZLD_FILIAL
	   AND MOV.ZLD_FRETIS = SA2T.A2_COD
	   AND MOV.ZLD_LJFRET = SA2T.A2_LOJA
	   AND MOV.ZLD_RETIRO = SA2P.A2_COD
	   AND MOV.ZLD_RETILJ = SA2P.A2_LOJA
	   AND FIN.ZLF_A2COD(+) = MOV.ZLD_FRETIS
	   AND FIN.ZLF_A2LOJA(+) = MOV.ZLD_LJFRET
	   AND FIN.ZLF_RETIRO(+) = MOV.ZLD_RETIRO
	   AND FIN.ZLF_RETILJ(+) = MOV.ZLD_RETILJ
	   AND FIN.ZLF_SETOR(+) = MOV.ZLD_SETOR
	   AND FIN.ZLF_LINROT(+) = MOV.ZLD_LINROT
	   AND MOV.ZLD_SETOR = ZL2_COD
	   AND MOV.ZLD_LINROT = ZL3_COD
	   AND SA2P.A2_EST = CC2_EST
	   AND SA2P.A2_COD_MUN = CC2_CODMUN
	 GROUP BY MOV.ZLD_FILIAL, SA2T.A2_COD, SA2T.A2_LOJA, SA2T.A2_NOME, CC2_CODMUN, CC2_MUN %exp:_cGroup%
	 ORDER BY MOV.ZLD_FILIAL, SA2T.A2_COD, SA2T.A2_LOJA, CC2_CODMUN %exp:_cOrder%
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
	_cTrans	:= (_cAlias)->TRANS + ' - ' + (_cAlias)->A2_NOME
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
