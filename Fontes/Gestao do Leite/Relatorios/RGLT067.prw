/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT067
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 19/08/2020
Descrição---------: Relatório Fornecedores por Banco - Chamado 33875
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT067

Local oReport
Pergunte("RGLT067",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 19/08/2020
Descrição---------: Processa a montagem do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Banco x Filial","Banco x Setor"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT067","Fornecedores por Banco","RGLT067",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Apresenta a relação de produtores de acordo com o banco informado no cadastro.")
oSection := TRSection():New(oReport,"Dados"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total dos Bancos: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.T.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZL2_FILIAL","ZL2","Fil"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2"/*Table*/,"Setor"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_COD","ZL3"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_DESCRI","ZL3"/*Table*/,"Linha"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_COD","SA2"/*Table*/,"Fornecedor"/*cTitle*/,/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_LOJA","SA2"/*Table*/,/*cTitle*/,/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_CGC","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_L_TPPAG","SA2"/*Table*/,/*cTitle*/,/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_BANCO","SA2"/*Table*/,/*cTitle*/,/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_AGENCIA","SA2"/*Table*/,/*cTitle*/,/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NUMCON","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_L_TIPPR","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_L_ATIVO","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

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
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro	:= "%"
Local _cFiltro2	:= ""
Local _cOrder   := "%"
Local _cAlias		:= ""
Local _aSelFil	:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() 
Local _cFilial	:= ""
Local _cBanco 	:= ""
Local _cSetor	  := ""
Local _nCountRec:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR09 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZL2")
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
If _nOrdem == 1
  oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL2_FILIAL") /*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )} /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
Else
  oQbrSet	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL2_COD") /*uBreak*/, {||"Total do Setor: " + _cSetor } /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
EndIf

oQbrBanco	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("A2_BANCO")/*uBreak*/, {||"Total do Banco: " + _cBanco }/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("ZL2_FILIAL")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrBanco/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)


//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
//Filtra o Tipo do produtor
If MV_PAR10 == 2 //Leite Proprio
	_cFiltro += " AND SA2.A2_L_TIPPR = 'P' "
ElseIf MV_PAR10 == 3 //Cooperativa
	_cFiltro += " AND SA2.A2_L_TIPPR = 'C' "
ElseIf MV_PAR10 == 4 //Atravessador
	_cFiltro += " AND SA2.A2_L_TIPPR = 'A' "
EndIf

//Filtra o Status do produtor
If MV_PAR11 == 2 //Bloqueados
	_cFiltro += " AND SA2.A2_L_ATIVO = 'N' "
ElseIf MV_PAR11 == 3 //Ativos
	_cFiltro += " AND SA2.A2_L_ATIVO <> 'N' "
EndIf

_cFiltro2 += _cFiltro

_cFiltro2 += " AND ZL2_FILIAL "+ GetRngFil( _aSelFil, "ZLF", .T.,)
//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR07) .Or. Empty(MV_PAR07) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro2 += " AND ZL2_COD IN "+ FormatIn( AllTrim(MV_PAR07) , ';' )
  _cFiltro += " AND R_E_C_N_O_ = 0" // sempre que informar setor deve anular a segunda query
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR08)
	_cFiltro2 += " AND ZL3_COD IN " + FormatIn(AllTrim(MV_PAR08),";")
  _cFiltro += " AND R_E_C_N_O_ = 0" // sempre que informar setor deve anular a segunda query
EndIf

If _nOrdem == 1
  _cOrder += " ZL2_FILIAL, "
Else
  _cOrder += " ZL2_COD, "
EndIf

_cFiltro += " %"
_cFiltro2 += " %"
_cOrder += " %"
//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
SELECT ZL2_FILIAL, ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI, A2_COD, A2_LOJA, A2_NOME, A2_CGC, A2_L_TPPAG, A2_BANCO, A2_AGENCIA, A2_NUMCON, A2_L_TIPPR, A2_L_ATIVO
  FROM %Table:SA2% SA2, %Table:ZL2% ZL2, %Table:ZL3% ZL3
 WHERE ZL2.D_E_L_E_T_ = ' '
   AND ZL3.D_E_L_E_T_ = ' '
   AND SA2.D_E_L_E_T_ = ' '
   AND ZL2_FILIAL = ZL3_FILIAL
   AND ZL3_SETOR = ZL2_COD
   %exp:_cFiltro2%
   AND ZL3_COD = A2_L_LI_RO
   AND A2_COD BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR05%
   AND A2_LOJA BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR06%
   AND A2_BANCO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
UNION
SELECT ' ', ' ', ' ', ' ', ' ', A2_COD, A2_LOJA, A2_NOME, A2_CGC, A2_L_TPPAG, A2_BANCO, A2_AGENCIA, A2_NUMCON, A2_L_TIPPR, A2_L_ATIVO
  FROM %Table:SA2% SA2
 WHERE SA2.D_E_L_E_T_ = ' '
   AND A2_L_LI_RO = ' '
   %exp:_cFiltro%
   AND A2_COD BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR05%
   AND A2_LOJA BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR06%
   AND A2_BANCO BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
 ORDER BY A2_BANCO, %exp:_cOrder% A2_COD, A2_LOJA
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
	_cFilial := (_cAlias)->ZL2_FILIAL
	_cSetor := (_cAlias)->ZL2_COD +" - " + (_cAlias)->ZL2_DESCRI
  _cBanco := (_cAlias)->A2_BANCO
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
