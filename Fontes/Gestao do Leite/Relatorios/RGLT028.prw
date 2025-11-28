/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |26/07/2019| Chamado 28346. Corrigida a barra de progresso.
Lucas Borges  |27/09/2019| Chamado 28346. Revisão de fontes.
Lucas Borges  |16/08/2023| Chamado 44752. Corrgido filtro de Setor.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT028
Autor-------------: Abrahao P. Santos
Data da Criacao---: 09/04/2009
Descrição---------: Relatório da relação de convênios
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT028()

Local oReport
Pergunte("RGLT028",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 04/02/2019
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Por Filial","Por Convênio"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT028","Relação de Convênios","RGLT028",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Lista todos os Convênios de Leite Próprio ou de Terceiros, acordo com os parâmetros informados")
oSection := TRSection():New(oReport,"Relação Convênios"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/,.T./*lTotalInLine*/)
oReport:SetLandscape()//Paisagem
oSection:lForceLineStyle:= .T.
oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZLL_FILIAL","ZLL",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2","Setor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,.T./*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_COD","ZL3","Lin/Rot"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_DESCRI","ZL3",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,.T./*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLL_COD","ZLL",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLL_CONVEN","ZLL","Conv."/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLL_LJCONV","ZLL","Loja"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"NOME_CONV",/*Tabela*/,"Nome Conv."/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,.T./*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLL_DATA","ZLL",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLL_VENCTO","ZLL","Vencto"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLL_RETIRO","ZLL",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLL_RETILJ","ZLL","Loja"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"NOME_RET",/*Tabela*/,"Nome Retiro"/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,.T./*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLL_STATUS",/*Tabela*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLL_VALOR","ZZL","Val. Bruto"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ALIQ",/*Tabela*/,"%"/*cTitle*/,"@E 99.99"/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLL_TXADM",/*Tabela*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VALOR_LIQ",/*Tabela*/,"Val. Líq."/*cTitle*/,"@E 9,999,999,999.99"/*Picture*/,15/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLL_OBSERV","ZLL",/*cTitle*/,/*Picture*/,40/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,.T./*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 31/01/2019
Descrição---------: Relacao Rota/Linha
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro		:= "%"
Local _cCampo		:= "%"
Local _cTabela		:= "%"
Local _cOrder		:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-Agrupa por filial 2-Agrupa também por Setor
Local _cFilial		:= ""
Local _cConv		:= ""
Local _lPlanilha 	:= oReport:nDevice == 4
Local _cAux			:= IIf( MV_PAR18 == 1 , "ZLL" , "ZLI" )//1-Produtor 2-Cooperativa
Local _nCountRec	:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR15 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZLL")
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
If !_lPlanilha
   	oReport:Section(1):Cell("ZL2_DESCRI"):Disable()
   	oReport:Section(1):Cell("ZL3_DESCRI"):Disable()
EndIf
If MV_PAR18 == 2 //Leite de Terceiro não usa esses campos
   	oReport:Section(1):Cell("ZL2_COD"):Disable()
   	oReport:Section(1):Cell("ZL2_DESCRI"):Disable()
   	oReport:Section(1):Cell("ZL3_COD"):Disable()
   	oReport:Section(1):Cell("ZL3_DESCRI"):Disable()
EndIf
//================================================================================
//| Configuração das quebras do relatório                                        |
//================================================================================
If _nOrdem == 2
	oQbrConv	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZLL_COD")/*uBreak*/, {||"Total do Convênio: " + _cConv }/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
	TRFunction():New(oReport:Section(1):Cell("ZLL_VALOR")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrConv/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("VALOR_LIQ")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrConv/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("ZLL_TXADM")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrConv/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
EndIf

oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZLL_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("ZLL_VALOR")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VALOR_LIQ")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("ZLL_TXADM")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cTabela += RetSqlName(_cAux) +" E "
If MV_PAR18 == 1
	_cTabela += ", " + RetSqlName("ZL2") +" ZL2, " + RetSqlName("ZL3") +" ZL3 "
EndIf

_cCampo+= _cAux +"_COD ZLL_COD,"+ _cAux +"_CONVEN ZLL_CONVEN, "+ _cAux +"_LJCONV ZLL_LJCONV, "+_cAux +"_FILIAL ZLL_FILIAL, "+ _cAux +"_DATA ZLL_DATA, "
_cCampo+= _cAux +"_VENCTO ZLL_VENCTO, "+ _cAux +"_RETIRO ZLL_RETIRO, "+_cAux +"_RETILJ ZLL_RETILJ, "+_cAux +"_VALOR ZLL_VALOR, "+ _cAux +"_STATUS ZLL_STATUS, "
_cCampo+= _cAux +"_VALOR-"+ _cAux +"_TXADM VALOR_LIQ, "+ _cAux +"_TXADM ZLL_TXADM, "+_cAux +"_OBSERV ZLL_OBSERV, "+_cAux +"_VALOR ZLL_VALOR, "+ _cAux +"_TXADM/"+ _cAux +"_VALOR*100 ALIQ"

If MV_PAR18 == 1
	_cCampo+= ", ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI "
	_cFiltro+=	" AND ZL2.D_E_L_E_T_ = ' '"
	_cFiltro+=	" AND ZL3.D_E_L_E_T_ (+)= ''
	_cFiltro += " AND ZLL_FILIAL = ZL2_FILIAL"
	_cFiltro += " AND ZL3_FILIAL (+)= ZLL_FILIAL"
	_cFiltro += " AND ZLL_SETOR = ZL2_COD"
	_cFiltro += " AND ZL3_SETOR (+)= ZL2_COD"
	_cFiltro += " AND ZL3_COD (+)= SA2.A2_L_LI_RO"
	
EndIf

_cFiltro += " AND "+ _cAux +"_FILIAL "+ GetRngFil( _aSelFil, _cAux, .T.,)
_cFiltro += " AND SA2.A2_COD = "+_cAux +"_RETIRO"
_cFiltro += " AND SA2.A2_LOJA = "+_cAux +"_RETILJ"
_cFiltro += " AND CONV.A2_COD = "+_cAux +"_CONVEN"
_cFiltro += " AND CONV.A2_LOJA = "+_cAux +"_LJCONV"
_cFiltro += " AND "+_cAux +"_DATA BETWEEN '"+ DToS(MV_PAR10) +"' AND '"+ DToS(MV_PAR11) +"'"
_cFiltro += " AND "+_cAux +"_VENCTO BETWEEN '"+ DToS(MV_PAR12) +"' AND '"+ DToS(MV_PAR13) +"'"

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If MV_PAR18 == 1 .And. (!Empty(MV_PAR01) .Or. (Empty(MV_PAR01) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'))
	_cFiltro += " AND ZL2.ZL2_COD IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
EndIf

//Verifica se foi fornecido o filtro de linha
If MV_PAR18 == 1 .And. !Empty(MV_PAR16)
	_cFiltro += " AND ZL3_COD IN " + FormatIn(MV_PAR16,";")
EndIf

//Verifica se foi fornecido o Evento
If MV_PAR18 == 1 .And. !Empty(MV_PAR14)
	_cFiltro += " AND ZLL_EVENTO IN " + FormatIn(MV_PAR14,";")
EndIf

//Filtra o Status do convênio
If MV_PAR18 == 1 .And. MV_PAR17 == 2 //Aberto
	_cFiltro += " AND ZLL_STATUS = 'A' "
ElseIf MV_PAR18 == 1 .And. MV_PAR17 == 3 //Pago
	_cFiltro += " AND ZLL_STATUS = 'P' "
ElseIf MV_PAR18 == 1 .And. MV_PAR17 == 3 //Suspenso
	_cFiltro += " AND ZLL_STATUS = 'S' "
EndIf

_cOrder += _cAux +"_FILIAL, "+_cAux +"_COD, "
_cCampo += "%"
_cTabela += "%"
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
	SELECT CONV.A2_NOME NOME_CONV, SA2.A2_NOME NOME_RET, %Exp:_cCampo%
	FROM %Table:SA2% SA2, %Table:SA2% CONV, %Exp:_cTabela%
	WHERE E.D_E_L_E_T_ = ' '
	AND SA2.D_E_L_E_T_ = ' '
	AND CONV.D_E_L_E_T_ = ' '
	%Exp:_cFiltro%
	AND CONV.A2_COD BETWEEN %Exp:MV_PAR02% AND %Exp:MV_PAR03%
	AND CONV.A2_LOJA BETWEEN %Exp:MV_PAR04% AND %Exp:MV_PAR05%
	AND SA2.A2_COD BETWEEN %Exp:MV_PAR06% AND %Exp:MV_PAR07%
	AND SA2.A2_LOJA BETWEEN %Exp:MV_PAR08% AND %Exp:MV_PAR09%
	ORDER BY %Exp:_cOrder% SA2.A2_COD, SA2.A2_LOJA
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
	_cFilial := (_cAlias)->ZLL_FILIAL
	_cConv := (_cAlias)->ZLL_COD
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
