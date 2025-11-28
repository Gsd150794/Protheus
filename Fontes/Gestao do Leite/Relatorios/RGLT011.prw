/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |04/02/2019| Chamado 27636. Retirados campos desnecessários.
Lucas Borges  |25/07/2019| Chamado 28346. Corrigida a barra de progresso.
Lucas Borges  |19/06/2024| Chamado 47627. Incluído novo produto na regra.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT011
Autor-------------: Marcelo Sanches/Abrahao
Data da Criacao---: 22/10/2008
Descrição---------: Resumo dos Eventos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT011

Local oReport
Pergunte("RGLT011",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 29/01/2019
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Por Filial","Por Setor"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT011","Resumo de Eventos","RGLT011",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Imprime os totais dos eventos referente ao Mix informado")
oSection := TRSection():New(oReport,"Resumo de Eventos"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)

oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZLF_FILIAL","ZLF",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLF_EVENTO","ZLF",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL8_DESCRI","ZL8",/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2",/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLF_QTDBOM","ZLF","Volume"/*cTitle*/,"@E 9,999,999,999"/*Picture*/,12/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CREDITO",/*Tabela*/,"Créditos"/*cTitle*/,"@E 999,999,999.99"/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"DEBITO",/*Tabela*/,"Débitos"/*cTitle*/,"@E 999,999,999.99"/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLF_TOTAL","ZLF","Valor p/ Lts"/*cTitle*/,"@E 9.9999"/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLF_ENTMIX","ZLF","Mix"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 29/01/2019
Descrição---------: Processa dados do relatório
Parametros--------: oReport, _aOrdem
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro		:= "%"
Local _cCampo		:= "%"
Local _cGroup		:= "%"
Local _cOrder		:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-Agrupa por filial 2-Agrupa também por Setor
Local _cFilial		:= ""
Local _cSetor		:= ""
Local _cProd		:= ""
Local _nCountRec	:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR03 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZLF")
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
If _nOrdem == 2 //Quebra por Setor

	oQbrSetor	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL2_COD") /*uBreak*/, {||"Total do Setor: " + _cSetor}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
	TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSetor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,{||IIf(_cProd $ '08000000030/08000000035/08000000065',.T.,.F.)}/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("CREDITO")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSetor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("DEBITO")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSetor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
Else
	oReport:Section(1):Cell("ZL2_COD"):Disable()
	oReport:Section(1):Cell("ZL2_DESCRI"):Disable()
EndIf

oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZLF_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,{||IIf(_cProd $ '08000000030/08000000035/08000000065',.T.,.F.)}/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("CREDITO")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("DEBITO")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

oReport:Section(1):Cell("CREDITO"):SetBlock({||(_cAlias)->CREDITO })
oReport:Section(1):Cell("DEBITO" ):SetBlock({||(_cAlias)->DEBITO})
oReport:Section(1):Cell("ZLF_QTDBOM" ):SetBlock({||(_cAlias)->VOLUME })
oReport:Section(1):Cell("ZLF_TOTAL" ):SetBlock({||(_cAlias)->TOTAL })
oReport:Section(1):Cell("ZLF_ENTMIX" ):SetBlock({||(_cAlias)->ENTMIX })

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro +=  GetRngFil( _aSelFil, "ZLF", .T.,)

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR01) .Or. Empty(MV_PAR01) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZL2_COD IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
EndIf
If MV_PAR04==1 // Somente Mix Fechado
	_cFiltro += " AND ZLF_STATUS = 'F'"
EndIf
_cFiltro += " %"

If _nOrdem == 2 //Quebra por Setor
	_cCampo += " , ZL2_COD, ZL2_DESCRI %"
	_cGroup += " , ZL2_COD, ZL2_DESCRI %"
	_cOrder += " ZL2_COD, %"
EndIf

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
  SELECT ZLF_FILIAL, ZLF_EVENTO,ZL8_DESCRI, ZL8_SB1COD,
         SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else 0 END) CREDITO,
         SUM(Case WHEN ZLF_DEBCRE = 'D' THEN ZLF_TOTAL Else 0END) DEBITO,
         Case WHEN SUM(ZLF_QTDBOM) > 0 THEN Round(SUM(ZLF_TOTAL)/SUM(ZLF_QTDBOM),4) Else 0 END TOTAL,
         SUM(ZLF_QTDBOM) VOLUME, DECODE(ZLF_ENTMIX, 'S', 'Sim', 'Nao') ENTMIX
         %Exp:_cCampo%
    FROM %Table:ZL8% ZL8, %Table:ZLF% ZLF, %Table:ZL2% ZL2
   WHERE ZL8.D_E_L_E_T_ = ' '
     AND ZLF.D_E_L_E_T_ = ' '
     AND ZL2.D_E_L_E_T_ = ' '
     AND ZLF_FILIAL %Exp:_cFiltro%
     AND ZLF_EVENTO = ZL8_COD
     AND ZLF_CODZLE = %Exp:MV_PAR02%
     AND ZLF_FILIAL = ZL8_FILIAL
     AND ZLF_FILIAL = ZL2_FILIAL
     AND ZLF_SETOR = ZL2_COD
   GROUP BY ZLF_FILIAL, ZLF_EVENTO, ZL8_DESCRI, ZL8_SB1COD, ZLF_ENTMIX %Exp:_cGroup%
   ORDER BY ZLF_FILIAL %Exp:_cCampo%, ZLF_EVENTO 
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
	//Alimentar essa variável antes da impressão da linha
	//para carregar o valor correto.
	_cProd := AllTrim((_cAlias)->ZL8_SB1COD)
	oReport:Section(1):PrintLine()
	oReport:IncMeter()
	//Alimentar essas variáveis depois da impressão da linha
	//para carregar o valor correto.
	_cFilial := (_cAlias)->ZLF_FILIAL
	If _nOrdem == 2 //Quebra por Setor
		_cSetor	:= (_cAlias)->ZL2_COD + ' - ' + (_cAlias)->ZL2_DESCRI
	EndIf
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
