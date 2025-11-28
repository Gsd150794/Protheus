/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |04/07/2019| Chamado 28346. Relatório reescrito, aproveitando apenas a ideia base.
Lucas Borges  |10/07/2019| Chamado 28346. Modificado para tratar registros duplicados que não deveriam ocorrer.
Lucas Borges  |25/07/2019| Chamado 28346. Corrigida a barra de progresso.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT018
Autor-------------: Abrahao P. Santos
Data da Criacao---: 23/01/2009
Descrição---------: Relatório de Divergência entre Estoque (SD3) e Recepção de Leite Próprio (ZLD)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT018()

Local oReport
Pergunte("RGLT018",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 04/07/2019
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

oReport := TReport():New("RGLT018","Diferença entre Movimento de Estoque e Recepção Leite Próprio","RGLT018",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Cruza as informações entre as Recepções de Leite Próprio e os Movimentos de Estoque, encontrando divergências.")
oSection := TRSection():New(oReport,"Movimentos"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)

oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"FILIAL",/*Table*/,"Fil"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLD_DTCOLE","ZLD","Data"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TICKET",/*Table*/,"Ticket"/*cTitle*/,/*Picture*/,10/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2","Setor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2",/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"INEXISTENTE","ZLD","Inexistente em" ,/*Picture*/,9/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"QTD_RECEP","ZLD","Qtd. Repecção" ,"@E 9,999,999"/*Picture*/,9/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"QTD_EST","ZLD","Qtd. Estoque" ,"@E 9,999,999"/*Picture*/,9/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"DIFERENCA","ZLD","Diferença" ,"@E 9,999,999"/*Picture*/,9/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 04/07/2019
Descrição---------: Processa impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltroZLD	:= "%"
Local _cFiltroSD3	:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-Agrupa por filial 2-Agrupa também por Setor
Local _cFilial		:= ""
Local _nCountRec	:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR04 == 1
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
oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("TICKET")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("QTD_RECEP")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("QTD_EST")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("DIFERENCA")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltroZLD += " AND ZLD.ZLD_FILIAL "+ GetRngFil( _aSelFil, "ZLD", .T.,)
_cFiltroSD3 += " AND SD3.D3_FILIAL "+ GetRngFil( _aSelFil, "SD3", .T.,)

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR03) .Or. Empty(MV_PAR03) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltroZLD += " AND ZLD.ZLD_SETOR IN "+ FormatIn( AllTrim(MV_PAR03) , ';' )
	_cFiltroSD3 += " AND SD3.D3_L_SETOR IN "+ FormatIn( AllTrim(MV_PAR03) , ';' )
EndIf
_cFiltroZLD += " AND ZLD.ZLD_DTCOLE BETWEEN '"+DToS(MV_PAR01)+"' AND '"+DToS(MV_PAR02)+"' %"
_cFiltroSD3 += " AND SD3.D3_EMISSAO BETWEEN '"+DToS(MV_PAR01)+"' AND '"+DToS(MV_PAR02)+"' %"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
SELECT A.*, ZL2.ZL2_COD, ZL2.ZL2_DESCRI
  FROM %Table:ZL2% ZL2,
       (SELECT Case WHEN L.ZLD_FILIAL IS NULL THEN E.D3_FILIAL Else L.ZLD_FILIAL END FILIAL,
               Case WHEN L.ZLD_DTCOLE IS NULL THEN E.D3_EMISSAO Else L.ZLD_DTCOLE END ZLD_DTCOLE,
               Case WHEN L.ZLD_TICKET IS NULL THEN E.D3_L_ORIG Else L.ZLD_TICKET END TICKET,
               Case WHEN L.ZLD_SETOR IS NULL THEN E.D3_L_SETOR Else L.ZLD_SETOR END SETOR,
               Case WHEN L.ZLD_SETOR IS NULL THEN 'Leite' WHEN E.D3_L_SETOR IS NULL THEN 'Estoque' Else ' ' END INEXISTENTE,
               L.ZLD_TOTBOM QTD_RECEP,
               E.D3_QUANT QTD_EST,
               ABS(NVL(L.ZLD_TOTBOM,0) - NVL(E.D3_QUANT,0)) DIFERENCA
          FROM (SELECT ZLD.ZLD_FILIAL, ZLD.ZLD_DTCOLE, ZLD.ZLD_TICKET, ZLD.ZLD_SETOR, ZLD.ZLD_TOTBOM
                  FROM %Table:ZLD% ZLD
                 WHERE ZLD.D_E_L_E_T_ = ' '
                   %exp:_cFiltroZLD%
                   AND ZLD.ZLD_TOTBOM > 0
                 GROUP BY ZLD.ZLD_FILIAL, ZLD.ZLD_DTCOLE, ZLD.ZLD_TICKET, ZLD.ZLD_SETOR, ZLD.ZLD_TOTBOM) L
          FULL OUTER JOIN (SELECT SD3.D3_FILIAL, SD3.D3_EMISSAO, SD3.D3_L_ORIG, SD3.D3_L_SETOR, SUM(SD3.D3_QUANT) D3_QUANT
                            FROM %Table:SD3% SD3
                           WHERE SD3.D_E_L_E_T_ = ' '
                             %exp:_cFiltroSD3%
                             AND SD3.D3_ESTORNO <> 'S'
                             AND SD3.D3_L_ORIG <> ' '
                           GROUP BY SD3.D3_FILIAL, SD3.D3_EMISSAO, SD3.D3_L_ORIG, SD3.D3_L_SETOR) E
            ON E.D3_FILIAL = L.ZLD_FILIAL
           AND E.D3_L_SETOR = L.ZLD_SETOR
           AND E.D3_L_ORIG = L.ZLD_TICKET
         WHERE (L.ZLD_TOTBOM <> E.D3_QUANT 
               OR L.ZLD_TOTBOM IS NULL OR
               E.D3_QUANT IS NULL)) A
 WHERE ZL2.D_E_L_E_T_ = ' '
   AND ZL2.ZL2_FILIAL = FILIAL
   AND ZL2.ZL2_COD = SETOR
 ORDER BY FILIAL, TICKET, ZLD_DTCOLE

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
	_cFilial := (_cAlias)->FILIAL
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
