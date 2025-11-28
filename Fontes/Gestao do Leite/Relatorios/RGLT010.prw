/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |19/07/2019| Chamado 29986. Corrigida query do relatório.
Lucas Borges  |27/09/2019| Chamado 28346. Revisão de fontes.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT010
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 31/05/2019
Descrição---------: Relatório de conferência de Recepções Leite Próprio. Lista os produtores que entregaram em mais de uma 
					linha/rota dentro do mesmo período. Situação não é recomendada em Jaru e sempre centralizam em apenas uma
					linha/rota. Chamado 29424
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT010()

Local oReport
Pergunte("RGLT010",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 31/05/2019
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

oReport := TReport():New("RGLT010","Movimentação de Produtores em mais de uma Linha/Rota","RGLT010",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Demonstra produtores que entregaram leite e mais de uma linha/rota por período")
oSection := TRSection():New(oReport,"Movimentos Por Produtor"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)

oSection:SetTotalInLine(.T.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZLD_FILIAL","ZLD",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PRODUTOR",/*Table*/,"Código"/*cTitle*/,/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2","Produtor"/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2","Setor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2",/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_COD","ZL3","Linha"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_DESCRI","ZL3",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLD_DTCOLE","ZLD","Data"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLD_TICKET","ZLD",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOLUME",/*Table*/,"Volume" ,"@E 9,999,999"/*Picture*/,9/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 31/05/2019
Descrição---------: Processa impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro		:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-Agrupa por filial 2-Agrupa também por Setor
Local _cFilial		:= ""
Local _cProd		:= ""
Local _nCountRec	:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR08 == 1
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
oQbrForn	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("PRODUTOR") /*uBreak*/, {||"Produtor: " + _cProd} /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrForn/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ZLD_FILIAL")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrForn/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZLD_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ZLD_FILIAL")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrFilial/*oBreak*/,"Registros"/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZLD.ZLD_FILIAL "+ GetRngFil( _aSelFil, "ZLD", .T.,)

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR01) .Or. Empty(MV_PAR01) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZL2.ZL2_COD IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
EndIf

_cFiltro += "%"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
SELECT ZLD.ZLD_FILIAL, SA2.A2_COD ||'-'|| SA2.A2_LOJA PRODUTOR, SA2.A2_NOME, 
       ZL2.ZL2_COD, ZL2.ZL2_DESCRI, ZL3.ZL3_COD, ZL3.ZL3_DESCRI,
       ZLD.ZLD_DTCOLE, ZLD.ZLD_TICKET, ZLD.ZLD_QTDBOM VOLUME
    FROM %Table:SA2% SA2, %Table:ZL3% ZL3, %Table:ZL2% ZL2, %Table:ZLD% ZLD
    WHERE SA2.D_E_L_E_T_ = ' '
    AND ZL3.D_E_L_E_T_ = ' '
    AND ZL2.D_E_L_E_T_ = ' '
    AND ZLD.D_E_L_E_T_ = ' '
    AND ZLD.ZLD_SETOR = ZL2.ZL2_COD
    AND ZLD.ZLD_LINROT = ZL3.ZL3_COD
    AND ZL3.ZL3_FILIAL = ZL2.ZL2_FILIAL
    AND ZLD.ZLD_FILIAL = ZL2.ZL2_FILIAL
    AND ZLD.ZLD_RETIRO = SA2.A2_COD
    AND ZLD.ZLD_RETILJ = SA2.A2_LOJA
    %exp:_cFiltro%
    AND ZLD.ZLD_DTCOLE BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
    AND EXISTS (SELECT 1 FROM  ZLD010 ZLD2
                       WHERE ZLD2.D_E_L_E_T_ = ' '
                       AND ZLD2.ZLD_FILIAL = ZLD.ZLD_FILIAL
                       AND ZLD2.ZLD_RETIRO = ZLD.ZLD_RETIRO
                       AND ZLD2.ZLD_RETILJ = ZLD.ZLD_RETILJ
                       AND ZLD2.ZLD_SETOR = ZLD.ZLD_SETOR
                       AND ZLD2.ZLD_LINROT <> ZLD.ZLD_LINROT
                       AND ZLD2.ZLD_TICKET <> ZLD.ZLD_TICKET
                       AND ZLD2.ZLD_DTCOLE BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%)
    AND ZLD.ZLD_RETIRO BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR03%
    AND ZLD.ZLD_RETILJ BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
ORDER BY ZLD.ZLD_FILIAL, SA2.A2_COD, SA2.A2_LOJA, ZL2.ZL2_COD, ZL3.ZL3_COD, ZLD.ZLD_DTCOLE
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
	_cProd := (_cAlias)->PRODUTOR
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
