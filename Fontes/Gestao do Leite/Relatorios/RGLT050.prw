/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |07/08/2019| Chamado 30202. Corrigida largura das colunas que estavam sendo cortadas.
Lucas Borges  |27/08/2019| Chamado 28346. Corrigida a barra de progresso.
Lucas Borges  |04/09/2019| Chamado 30471. Criado tratamento para não filtrar setor e linha para os usuários do tanque.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT050
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 05/12/2009
Descrição---------: Relatorio Demonstrativo Eventos. 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT050()

Local oReport
Pergunte("RGLT050",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 31/01/2019
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oSection
Local _aOrdem   := {"Por Filial","Por Linha","Por Dono Tanque"}

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT050","Demostrativo de Valores de Eventos","RGLT050",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Detalha valor de cada evento, por produtor ou dono de tanque")
oSection := TRSection():New(oReport,"Valores Evento"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/)
oReport:SetLandscape()//Paisagem
oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZLF_FILIAL","ZLF",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL8_COD","ZL8","Evento"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL8_DESCRI","ZL8",/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZLF_DEBCRE","ZLF","Deb./Cred"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2","Setor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2",/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_COD","ZL3","Linha"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_DESCRI","ZL3",/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_COD","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_LOJA","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2",/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TANQUE",/*Tabela*/,"Cod. Tanque"/*cTitle*/,/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"NOME_TANQUE",/*Tabela*/,"Resp. Tanque"/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOLUME",/*Tabela*/,"Volume" ,"@E 9,999,999,999" ,12,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PRC_LITRO",/*Tabela*/,"Valor p/ Lts"/*cTitle*/,"@E 9.9999"/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TOTAL",/*Tabela*/,"Valor Total", "@E 9,999,999,999.99" ,12,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

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
Local _cOrder		:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-Agrupa por filial 2-Agrupa também por Setor
Local _cFilial		:= ""
Local _cTanque		:= ""
Local _cLinha		:= ""
Local _lPlanilha 	:= oReport:nDevice == 4
Local _nCountRec	:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR10 == 1
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
If _nOrdem == 2
	oQbrLinha	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZL3_COD")/*uBreak*/, {||"Total da Linha: " + _cLinha }/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
	TRFunction():New(oReport:Section(1):Cell("A2_COD")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrLinha/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrLinha/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("PRC_LITRO")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrLinha/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("TOTAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrLinha/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
ElseIf _nOrdem == 3
	oQbrTanque	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("TANQUE")/*uBreak*/, {||"Total do Responsável do Tanque: " + _cTanque }/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
	TRFunction():New(oReport:Section(1):Cell("A2_COD")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrTanque/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrTanque/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("PRC_LITRO")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrTanque/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("TOTAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrTanque/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
EndIf

oQbrFilial	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZLF_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
TRFunction():New(oReport:Section(1):Cell("A2_COD")/*oCell*/,/*cName*/,"COUNT"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("PRC_LITRO")/*oCell*/,/*cName*/,"AVERAGE"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("TOTAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If _nOrdem == 1
	oReport:Section(1):Cell("NOME_TANQUE"):Disable()
EndIf
If !_lPlanilha .And. _nOrdem == 2
	oReport:Section(1):Cell("ZL2_DESCRI"):Disable()
EndIf
//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
//==================================================================
//Define se vou buscar o volume de leite do produtor individualmente
//ou de todos que usaram seu tanque coletivo
//==================================================================
_cFiltro += " AND ZLF_FILIAL "+ GetRngFil( _aSelFil, "ZLF", .T.,)

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR02) .Or. Empty(MV_PAR02) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZL2.ZL2_COD IN "+ FormatIn( AllTrim(MV_PAR02) , ';' )
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR03)
	_cFiltro += " AND ZL3_COD IN " + FormatIn(MV_PAR03,";")
EndIf

//Verifica se foi fornecido o Evento
If !Empty(MV_PAR04)
	_cFiltro += " AND ZLF_EVENTO IN " + FormatIn(MV_PAR04,";")
EndIf

If _nOrdem == 3
	_cOrder += " TANQUE, "
EndIf
         
If MV_PAR09 == 2//1-Volume Individual 2-Volume Coletivo
	_cCampo += " +  NVL((SELECT SUM(ZLD_QTDBOM) ZLD_QTDBOM
	_cCampo += " FROM "+ RetSQLName("ZLD") + " ZLD"
	_cCampo += " WHERE ZLD.D_E_L_E_T_ = ' '"
	_cCampo += " AND ZLD_FILIAL = ZLF_FILIAL"
	_cCampo += " AND ZLD_DTCOLE BETWEEN ZLF.ZLF_DTINI AND ZLF.ZLF_DTFIM"
	_cCampo += " AND ZLD_RETIRO||ZLD_RETILJ <> SA2.A2_COD||SA2.A2_LOJA" 		
	_cCampo += " AND EXISTS (SELECT 1"
	_cCampo += " FROM "+ RetSQLName("SA2") + " SA22"
	_cCampo += " WHERE SA22.D_E_L_E_T_ = ' '"
	_cCampo += " AND SA22.A2_L_TANQ = SA2.A2_COD"
	_cCampo += " AND SA22.A2_L_TANLJ = SA2.A2_LOJA"
	_cCampo += " AND SA22.A2_COD = ZLD_RETIRO"
	_cCampo += " AND SA22.A2_LOJA = ZLD_RETILJ)),0)"
EndIf

_cCampo += "%"
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
	SELECT A.*, Case WHEN VOLUME > 0 THEN Round(TOTAL/VOLUME,4) Else 0 END PRC_LITRO
	  FROM (SELECT ZLF_FILIAL, ZL8_COD, ZL8_DESCRI, ZLF_DEBCRE, ZL2_COD, ZL2_DESCRI,
	               ZL3_COD, ZL3_DESCRI, SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, SA2.A2_L_TANQ ||'-'|| SA2.A2_L_TANLJ TANQUE,
	               TNQ.A2_NOME NOME_TANQUE, SUM(ZLF_TOTAL) TOTAL,
	               NVL(NVL((SELECT SUM(ZLD_QTDBOM)
	                  FROM %Table:ZLD% ZLD
	                 WHERE ZLD.D_E_L_E_T_ = ' '
	                   AND ZLD_FILIAL = ZLF_FILIAL
	                   AND ZLD_DTCOLE BETWEEN ZLF.ZLF_DTINI AND ZLF.ZLF_DTFIM
	                   AND ZLD_SETOR = ZL2_COD
	                   AND ZLD_LINROT = ZL3_COD
	                   AND ZLD_RETIRO = SA2.A2_COD 
	                   AND ZLD_RETILJ = SA2.A2_LOJA),0)
	                       %Exp:_cCampo%,0) VOLUME
	          FROM %Table:ZL8% ZL8, %Table:ZLF% ZLF, %Table:ZL2% ZL2, %Table:ZL3% ZL3, %Table:SA2% SA2, %Table:SA2% TNQ
	         WHERE ZL8.D_E_L_E_T_ = ' '
	           AND ZLF.D_E_L_E_T_ = ' '
	           AND ZL2.D_E_L_E_T_ = ' '
	           AND SA2.D_E_L_E_T_ = ' '
	           AND ZL3.D_E_L_E_T_ = ' '
	           AND TNQ.D_E_L_E_T_ (+)= ' '
	           AND SA2.A2_COD = ZLF_A2COD
	           AND SA2.A2_LOJA = ZLF_A2LOJA
	           AND TNQ.A2_COD (+)= SA2.A2_L_TANQ
	           AND TNQ.A2_LOJA (+)= SA2.A2_L_TANLJ
	           AND ZLF_EVENTO = ZL8_COD
	           %Exp:_cFiltro%
	           AND ZLF_CODZLE = %Exp:MV_PAR01%
	           AND SA2.A2_COD BETWEEN %Exp:MV_PAR05% AND %Exp:MV_PAR06%
	           AND SA2.A2_LOJA BETWEEN %Exp:MV_PAR07% AND %Exp:MV_PAR08%
	           AND ZLF_FILIAL = ZL8_FILIAL
	           AND ZLF_FILIAL = ZL2_FILIAL
	           AND ZLF_FILIAL = ZL3_FILIAL
	           AND ZLF_SETOR = ZL2_COD
	           AND ZLF_LINROT = ZL3_COD
	         GROUP BY ZLF_FILIAL, ZL8_COD, ZL8_DESCRI, ZLF_DEBCRE, ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI,
	                  SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, SA2.A2_L_TANQ, SA2.A2_L_TANLJ, TNQ.A2_NOME, ZLF.ZLF_DTINI, ZLF.ZLF_DTFIM) A
	 ORDER BY ZLF_FILIAL, %Exp:_cOrder% ZL2_COD, ZL3_COD, A2_COD, A2_LOJA
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
	_cFilial := (_cAlias)->ZLF_FILIAL
	_cTanque := AllTrim((_cAlias)->TANQUE) + " - " + (_cAlias)->NOME_TANQUE
	_cLinha := (_cAlias)->ZL3_COD + " - " + (_cAlias)->ZL3_DESCRI
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
