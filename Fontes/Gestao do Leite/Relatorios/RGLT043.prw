/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |04/08/2020| Chamado 33750. Proteção para impressão direto do Mix e ajuste para produtores sem movimento.
Lucas Borges  |24/12/2021| Chamado 38549 e 38663. Tratamento para uso do Configurador de Tributos para o Reinf (R-2055).
Lucas Borges  |25/05/2022| Chamado 40238. Modifiado tratamento do Incentivo à Produção.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT043
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 31/05/2010
Descrição---------: Relatório que imprime dados dos produtores, volume, valores com ordenação por preço pago.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT043

Local _aArea := FWGetArea()
Local oReport
If AllTrim(FunName()) == 'AGLT008' 
	MV_PAR01:= ZLE->ZLE_COD
EndIf
Pergunte("RGLT043",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Erich Buttner
Data da Criacao---: 27/03/2013
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Filial + Custo Empresa","Filial + Preço Bruto", "Filial + Preço Líquido", "Filial + Volume",;
					"Custo Empres","Preço Bruto","Preço Líquido","Volume"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT043","Classificação de produtores no Mix","RGLT043",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Apresenta a classificação dos produtores dentro do Mix com as ordenações escolhidas.")
oSection := TRSection():New(oReport,"Movimentos"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZL2_FILIAL","ZL2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_COD","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_LOJA","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2"/*Table*/,"Setor"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_COD","ZL3"/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_DESCRI","ZL3"/*Table*/,"Linha"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOLUME",/*Tabela*/,"Volume", "@E 9,999,999,999" ,13,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"CUS_EMP",/*Tabela*/,"Custo Emp.", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PRC_BRUTO",/*Tabela*/,"Preço Bruto", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PRC_LIQ",/*Tabela*/,"Preço Liq.", "@E 99.9999" ,7,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 26/06/2020
Descrição---------: Processa a impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro		:= "%"
Local _cFiltro2		:= "%"
Local _cOrder		:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() 
Local _cFilial		:= ""
Local _nCountRec	:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR02 == 1
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
If _nOrdem > 0 .And. _nOrdem < 5
	oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL2_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
EndIf

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZL2_FILIAL "+ GetRngFil( _aSelFil, "ZL2", .T.,)
//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR07) .Or. Empty(MV_PAR07) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZL2_COD IN "+ FormatIn( AllTrim(MV_PAR07) , ';' )
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR12)
	_cFiltro += " AND ZL3_COD IN " + FormatIn(AllTrim(MV_PAR12),";")
EndIf
If MV_PAR13 == 1 //Custo Empresa
	_cFiltro2 += " CUS_EMP"
ElseIf MV_PAR13 == 2 //Preco Bruto
	_cFiltro2 += " PRC_BRUTO"
ElseIf MV_PAR13 == 3 //Preco Liquido
	_cFiltro2 += " PRC_LIQ"
EndIf

If _nOrdem == 1
	_cOrder += " ZL2_FILIAL, CUS_EMP "+IIf(MV_PAR08==2,"DESC","")+", VOLUME "+IIf(MV_PAR08==2,"DESC","")
ElseIf _nOrdem == 2
	_cOrder += " ZL2_FILIAL, PRC_BRUTO "+IIf(MV_PAR08==2,"DESC","")+", VOLUME "+IIf(MV_PAR08==2,"DESC","")
ElseIf _nOrdem == 3
	_cOrder += " ZL2_FILIAL, PRC_LIQ "+IIf(MV_PAR08==2,"DESC","")+", VOLUME "+IIf(MV_PAR08==2,"DESC","")
ElseIf _nOrdem == 4
	_cOrder += " ZL2_FILIAL, VOLUME "+IIf(MV_PAR08==2,"DESC","")
ElseIf _nOrdem == 5
	_cOrder += " CUS_EMP "+IIf(MV_PAR08==2,"DESC","")+", VOLUME "+IIf(MV_PAR08==2,"DESC","")
ElseIf _nOrdem == 6
	_cOrder += " PRC_BRUTO "+IIf(MV_PAR08==2,"DESC","")+", VOLUME "+IIf(MV_PAR08==2,"DESC","")
ElseIf _nOrdem == 7
	_cOrder += " PRC_LIQ "+IIf(MV_PAR08==2,"DESC","")+", VOLUME "+IIf(MV_PAR08==2,"DESC","")
ElseIf _nOrdem == 8
	_cOrder += " VOLUME "+IIf(MV_PAR08==2,"DESC","")
EndIf

If MV_PAR11 > 0
	_cOrder += " FETCH FIRST "+cValToChar(MV_PAR11)+" ROWS ONLY "
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
SELECT *
  FROM (SELECT ZL2_FILIAL, A2_COD, A2_LOJA, A2_NOME, ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI, VOLUME,
               Round(TOT_MIX / Case WHEN VOLUME=0 THEN 1 Else VOLUME END, 4) CUS_EMP, Round(TOT_CRED / Case WHEN VOLUME=0 THEN 1 Else VOLUME END, 4) PRC_BRUTO,
               Round((TOT_CRED / Case WHEN VOLUME=0 THEN 1 Else VOLUME END) + (TOT_IMP / Case WHEN VOLUME=0 THEN 1 Else VOLUME END) - TOT_DEB, 4) PRC_LIQ
          FROM (SELECT ZL2_FILIAL, A2_COD, A2_LOJA, A2_NOME, ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI,
                       NVL((SELECT SUM(ZLD.ZLD_QTDBOM)
                             FROM ZLD010 ZLD
                            WHERE D_E_L_E_T_ = ' '
                              AND ZLD_FILIAL = ZL2_FILIAL
                              AND ZLD_RETIRO = A2_COD
                              AND ZLD_RETILJ = A2_LOJA
                              AND ZLD_SETOR = ZL2_COD
                              AND ZLD_LINROT = ZL3_COD
                              AND ZLD_DTCOLE BETWEEN ZLE_DTINI AND ZLE_DTFIM),
                           0) VOLUME,
                       NVL((SELECT NVL(SUM(ZLF_TOTAL), 0)
                          FROM %Table:ZLF% ZLF1
                         WHERE ZLF1.D_E_L_E_T_ = ' '
                           AND ZLF1.ZLF_FILIAL = ZL2_FILIAL
                           AND ZLF1.ZLF_SETOR = ZL2_COD
                           AND ZLF1.ZLF_LINROT = ZL3_COD
                           AND ZLF1.ZLF_A2COD = A2_COD
                           AND ZLF1.ZLF_A2LOJA = A2_LOJA
                           AND ZLF1.ZLF_CODZLE = ZLE_COD
                           AND ZLF1.ZLF_TP_MIX = 'L'
                           AND ZLF1.ZLF_ENTMIX = 'S'
                           AND ZLF1.ZLF_DEBCRE = 'C'),0) TOT_CRED,
                       NVL((SELECT SUM(Case WHEN ZL8.ZL8_DEBCRE = 'C' THEN ZLF2.ZLF_TOTAL Else ZLF2.ZLF_TOTAL * -1 END)
                          FROM %Table:ZLF% ZLF2, %Table:ZL8% ZL8
                         WHERE ZLF2.D_E_L_E_T_ = ' '
                           AND ZL8.D_E_L_E_T_ = ' '
                           AND ZLF2.ZLF_FILIAL = ZL8.ZL8_FILIAL
                           AND ZLF2.ZLF_EVENTO = ZL8_COD
                           AND ZLF2.ZLF_FILIAL = ZL2_FILIAL
                           AND ZLF2.ZLF_SETOR = ZL2_COD
                           AND ZLF2.ZLF_LINROT = ZL3_COD
                           AND ZLF2.ZLF_A2COD = A2_COD
                           AND ZLF2.ZLF_A2LOJA = A2_LOJA
                           AND ZLF2.ZLF_CODZLE = ZLE_COD
                           AND ZL8.ZL8_PERTEN = 'P'
                           AND ZL8.ZL8_GRUPO = '000007'),0) TOT_IMP,
                       NVL((SELECT SUM(Case WHEN ZL8.ZL8_DEBCRE = 'C' THEN ZLF2.ZLF_TOTAL Else ZLF2.ZLF_TOTAL * -1 END)
                          FROM %Table:ZLF% ZLF2, %Table:ZL8% ZL8
                         WHERE ZLF2.D_E_L_E_T_ = ' '
                           AND ZL8.D_E_L_E_T_ = ' '
                           AND ZLF2.ZLF_FILIAL = ZL8.ZL8_FILIAL
                           AND ZLF2.ZLF_EVENTO = ZL8_COD
                           AND ZLF2.ZLF_FILIAL = ZL2_FILIAL
                           AND ZLF2.ZLF_SETOR = ZL2_COD
                           AND ZLF2.ZLF_LINROT = ZL3_COD
                           AND ZLF2.ZLF_RETIRO = A2_COD
                           AND ZLF2.ZLF_RETILJ = A2_LOJA
                           AND ZLF2.ZLF_CODZLE = ZLE_COD
                           AND ZLF2.ZLF_ENTMIX = 'S'),0) TOT_MIX,
                       NVL((SELECT NVL(SUM(ZLF_VLRLTR), 0)
                          FROM %Table:ZLF% ZLF1
                         WHERE ZLF1.D_E_L_E_T_ = ' '
                           AND ZLF1.ZLF_FILIAL = ZL2_FILIAL
                           AND ZLF1.ZLF_SETOR = ZL2_COD
                           AND ZLF1.ZLF_LINROT = ZL3_COD
                           AND ZLF1.ZLF_A2COD = A2_COD
                           AND ZLF1.ZLF_A2LOJA = A2_LOJA
                           AND ZLF1.ZLF_CODZLE = ZLE_COD
                           AND ZLF1.ZLF_DEBCRE = 'D'),0) TOT_DEB
                  FROM (SELECT ZL2_FILIAL, ZLE_COD, A2_COD, A2_LOJA, A2_NOME, ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI, ZLE_DTINI, ZLE_DTFIM
                          FROM %Table:ZLD% ZLD, %Table:SA2% SA2, %Table:ZL2% ZL2, %Table:ZL3% ZL3, %Table:ZLE% ZLE
                         WHERE ZLD.D_E_L_E_T_ = ' '
                           AND SA2.D_E_L_E_T_ = ' '
                           AND ZL2.D_E_L_E_T_ = ' '
                           AND ZL3.D_E_L_E_T_ = ' '
                           AND ZLE.D_E_L_E_T_ = ' '
                           %exp:_cFiltro%
                           AND ZLD_FILIAL = ZL2_FILIAL
                           AND ZLD_FILIAL = ZL3_FILIAL
                           AND A2_COD = ZLD_RETIRO
                           AND A2_LOJA = ZLD_RETILJ
                           AND ZL3_COD = ZLD_LINROT
                           AND ZL2_COD = ZLD_SETOR
                           AND ZLE_COD = %exp:MV_PAR01%
                           AND A2_COD BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR05%
                           AND A2_LOJA BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR06%
                           AND ZLD_DTCOLE BETWEEN ZLE_DTINI AND ZLE_DTFIM
                         GROUP BY ZL2_FILIAL, ZLE_COD, A2_COD, A2_LOJA, A2_NOME, ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI, ZLE_DTINI, ZLE_DTFIM
                        UNION
                        SELECT ZL2_FILIAL, ZLE_COD, A2_COD, A2_LOJA, A2_NOME, ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI, ZLE_DTINI, ZLE_DTFIM
                          FROM %Table:ZLF% ZLF, %Table:SA2% SA2, %Table:ZL2% ZL2, %Table:ZL3% ZL3, %Table:ZLE% ZLE
                         WHERE ZLF.D_E_L_E_T_ = ' '
                           AND SA2.D_E_L_E_T_ = ' '
                           AND ZL2.D_E_L_E_T_ = ' '
                           AND ZL3.D_E_L_E_T_ = ' '
                           AND ZLE.D_E_L_E_T_ = ' '
                           %exp:_cFiltro%
                           AND ZLF_FILIAL = ZL2_FILIAL
                           AND ZLF_FILIAL = ZL3_FILIAL
                           AND A2_COD = ZLF_A2COD
                           AND A2_LOJA = ZLF_A2LOJA
                           AND ZL3_COD = ZLF_LINROT
                           AND ZL2_COD = ZLF_SETOR
                           AND ZLE_COD = %exp:MV_PAR01%
                           AND A2_COD BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR05%
                           AND A2_LOJA BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR06%
                           AND ZLF_CODZLE = ZLE_COD
                         GROUP BY ZL2_FILIAL, ZLE_COD, A2_COD, A2_LOJA, A2_NOME, ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI, ZLE_DTINI, ZLE_DTFIM) B))
 WHERE %exp:_cFiltro2% BETWEEN %exp:MV_PAR09% AND %exp:MV_PAR10%
 ORDER BY %exp:_cOrder%
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
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
