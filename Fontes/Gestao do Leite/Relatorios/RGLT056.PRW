/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |29/08/2019| Chamado 30459. Corrigido filtro do Mix.
Lucas Borges  |13/09/2023| Chamado 44985. Implementado envio de e-mail para o transportador com valor a ser pago.
Lucas Borges  |09/11/2023| Chamado 45518. Incluída a informação de pedágio para o transportador.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT056
Autor-------------: Erich Buttner
Data da Criacao---: 08/03/2013
Descrição---------: Relatório com informações referente ao frete dos transportadores de leite para análise de custos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT056()

Local oReport
Pergunte("RGLT056",.F.)
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

oReport := TReport():New("RGLT056","Relatório Apuração Custo Frete","RGLT056",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Relatório Apuração Custo Frete")
oSection := TRSection():New(oReport,"Custo Frete"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais: "/*uTotalText*/,.T./*lTotalInLine*/)

oSection:SetTotalInLine(.F.)

//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New(oSection,"ZLD_FILIAL","ZLD","Fil"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TRANS",/*cAlias*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_COD","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_LOJA","SA2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"A2_NOME","SA2","Fretista"/*cTitle*/,/*Picture*/,35/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_COD","ZL2","Setor"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL2_DESCRI","ZL2",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_COD","ZL3","Linha"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"ZL3_DESCRI","ZL3",/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VOLUME",/*cAlias*/,"Volume"/*cTitle*/,"@E 9,999,999,999"/*Picture*/,14/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"KM",/*cAlias*/,"Km"/*cTitle*/,"@E 999,999,999"/*Picture*/,12/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VLRKM",/*cAlias*/,"Preço/Km"/*cTitle*/,GetSX3Cache("ZLB_VLRFX","X3_PICTURE")/*Picture*/,GetSX3Cache("ZLB_VLRFX","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"PEDAGIO",/*cAlias*/,"Pedagio"/*cTitle*/,GetSX3Cache("ZLC_QTD","X3_PICTURE")/*Picture*/,GetSX3Cache("ZLC_QTD","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"TOTFRE",/*cAlias*/,"Total Frete"/*cTitle*/,GetSX3Cache("ZLC_QTD","X3_PICTURE")/*Picture*/,GetSX3Cache("ZLC_QTD","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"DENSIDADE",/*Table*/,"Densidade"/*cTitle*/,GetSX3Cache("ZLC_QTD","X3_PICTURE")/*Picture*/,GetSX3Cache("ZLC_QTD","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"VLRLTO",/*Table*/,"Custo/Litro"/*cTitle*/,GetSX3Cache("ZLB_VLRFX","X3_PICTURE")/*Picture*/,GetSX3Cache("ZLB_VLRFX","X3_TAMANHO")/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oSection,"LOG",/*Table*/,"Log e-mail"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

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
Local _cCampos		:= "%"
Local _cOrder		:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder() //1-Agrupa por filial 2-Agrupa também por Setor
Local _cFilial		:= ""
Local _cFretis		:= ""
Local _lPlanilha 	:= oReport:nDevice == 4
Local _nCountRec	:= 0
Local _cErro		:= ""
Local _cAssunto		:= ""
Local _cMensagem	:= ""
Local _cFrom		:= FWSFAllUsers({RetCodUsr()})[1][5]//retorna o e-mail do usuário
Local _cReplyTo		:= AllTrim(MV_PAR11)

//Chama função que permitirá a seleção das filiais
If MV_PAR03 == 1
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
If MV_PAR09 = 1 .Or. MV_PAR10 == 1 // 1-Analítico 2-Sintético ou 1-Envia e-mail 2-Não envia e-mail
	oQbrFret	:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("TRANS") /*uBreak*/, {||"Fretista: " + _cFretis} /*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.F./*lPageBreak*/)
	oTotVol 	:= TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFret/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("KM")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFret/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("PEDAGIO")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFret/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	oTotFre 	:= TRFunction():New(oReport:Section(1):Cell("TOTFRE")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFret/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	TRFunction():New(oReport:Section(1):Cell("VLRLTO")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrFret/*oBreak*/,/*cTitle*/,/*cPicture*/,{||oTotFre:GetValue()/oTotVol:GetValue()}/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
EndIf

oQbrFil		:= TRBreak():New( oReport:Section(1)/*oParent*/, oReport:Section(1):Cell("ZLD_FILIAL") /*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
oTotFVol 	:= TRFunction():New(oReport:Section(1):Cell("VOLUME")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("KM")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("PEDAGIO")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
oTotFFre 	:= TRFunction():New(oReport:Section(1):Cell("TOTFRE")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F./*lEndSection*/,.T./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
TRFunction():New(oReport:Section(1):Cell("VLRLTO")/*oCell*/,/*cName*/,"ONPRINT"/*cFunction*/,oQbrFil/*oBreak*/,/*cTitle*/,/*cPicture*/,{||oTotFFre:GetValue()/oTotFVol:GetValue()}/*uFormula*/,.F./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
oReport:Section(1):Cell("TRANS"):Disable()
oReport:Section(1):Cell("ZL2_COD"):Disable()
oReport:Section(1):Cell("ZL2_DESCRI"):Disable()
oReport:Section(1):Cell("ZL3_COD"):Disable()
oReport:Section(1):Cell("ZL3_DESCRI"):Disable()
If MV_PAR09 == 1 .Or. MV_PAR10 == 1 // 1-Analítico 2-Sintético ou 1-Envia e-mail 2-Não envia e-mail
	oReport:Section(1):Cell("ZL2_COD"):Enable()
	oReport:Section(1):Cell("ZL2_DESCRI"):Enable()
	If MV_PAR10 == 2 // Se estiver enviando e-mail nunca deve ser levado ao nível da Linha
		oReport:Section(1):Cell("ZL3_COD"):Enable()
		oReport:Section(1):Cell("ZL3_DESCRI"):Enable()
	EndIf
EndIf

If !_lPlanilha
	oReport:Section(1):Cell("ZL2_DESCRI"):Disable()
EndIf

If !(_lPlanilha .And. MV_PAR10 == 1)
	oReport:Section(1):Cell("LOG"):Disable()
EndIf

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND ZLD.ZLD_FILIAL "+ GetRngFil( _aSelFil, "ZLD", .T.,)

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR01) .Or. Empty(MV_PAR01) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZLD.ZLD_SETOR IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR08)
	_cFiltro += " AND ZLD.ZLD_LINROT IN " + FormatIn(MV_PAR08,";")
EndIf

If MV_PAR10 == 1 // 1-Envia e-mail 2-Não envia e-mail
	_cCampos += " ZL2.ZL2_COD, ZL2.ZL2_DESCRI, "
	_cOrder	+= " , ZL2.ZL2_COD "
ElseIf MV_PAR09 == 1 // 1-Analítico 2-Sintético
	_cCampos += " ZL2.ZL2_COD, ZL2.ZL2_DESCRI, ZL3.ZL3_COD, ZL3.ZL3_DESCRI, "
	_cOrder	+= " , ZL2.ZL2_COD, ZL3.ZL3_COD"
EndIf

_cFiltro += "%"
_cCampos += "%"
_cOrder += "%"
//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oReport:Section(1):BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
	SELECT RES.ZLD_FILIAL, %exp:_cCampos% SA2.A2_COD || SA2.A2_LOJA TRANS,SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, SA2.A2_EMAIL, 
	       RES.ZLE_DTINI, SUM(RES.TOTFRE) TOTFRE, SUM(RES.VOLUME) VOLUME, SUM(RES.KM) KM, SUM(RES.PEDAGIO) PEDAGIO,
	       Case WHEN SUM(KM) = 0 THEN 0 Else SUM(TOTFRE) / SUM(KM) END VLRKM,
	       Case WHEN SUM(KM) = 0 THEN 0 Else SUM(VOLUME) / SUM(KM) END DENSIDADE,
	       Case WHEN SUM(VOLUME) = 0 THEN 0 Else SUM(TOTFRE) / SUM(VOLUME) END VLRLTO
	  FROM (SELECT ZLD.ZLD_FILIAL, ZLD.ZLD_SETOR, ZLD.ZLD_LINROT, ZLD.ZLD_FRETIS, ZLD.ZLD_LJFRET, ZLE.ZLE_COD, ZLE.ZLE_DTINI, ZLE.ZLE_DTFIM,
	               (SELECT NVL(SUM(ZLF_TOTAL), 0) TOTAL
	                  FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
	                 WHERE ZLF.D_E_L_E_T_ = ' '
	                   AND ZL8.D_E_L_E_T_ = ' '
	                   AND ZLF.ZLF_FILIAL = ZLD.ZLD_FILIAL
	                   AND ZL8.ZL8_FILIAL = ZLF_FILIAL
	                   AND ZLF.ZLF_EVENTO = ZL8_COD
	                   AND ZLF.ZLF_CODZLE = ZLE.ZLE_COD
	                   AND ZLF.ZLF_A2COD = ZLD.ZLD_FRETIS
	                   AND ZLF.ZLF_A2LOJA = ZLD.ZLD_LJFRET
	                   AND ZLF.ZLF_LINROT = ZLD.ZLD_LINROT
	                   AND ZLF.ZLF_SETOR = ZLD.ZLD_SETOR
	                   AND ZLF.ZLF_ENTMIX = 'S'
	                   AND ZL8.ZL8_DEBCRE = 'C'
	                   AND ZLF_TP_MIX = 'F') TOTFRE,
					(SELECT NVL(SUM(ZLF_TOTAL), 0) TOTAL
	                  FROM %Table:ZLF% ZLF
	                 WHERE ZLF.D_E_L_E_T_ = ' '
	                   AND ZLF.ZLF_FILIAL = ZLD.ZLD_FILIAL
	                   AND ZLF.ZLF_EVENTO = '000194'
	                   AND ZLF.ZLF_CODZLE = ZLE.ZLE_COD
	                   AND ZLF.ZLF_A2COD = ZLD.ZLD_FRETIS
	                   AND ZLF.ZLF_A2LOJA = ZLD.ZLD_LJFRET
	                   AND ZLF.ZLF_LINROT = ZLD.ZLD_LINROT
	                   AND ZLF.ZLF_SETOR = ZLD.ZLD_SETOR) PEDAGIO,
	               NVL(SUM(ZLD.ZLD_QTDBOM), 0) VOLUME,
	               NVL((SELECT SUM(A.ZLD_KM)
	                     FROM (SELECT KM.ZLD_TICKET, KM.ZLD_KM
	                             FROM %Table:ZLD% KM
	                            WHERE KM.D_E_L_E_T_ = ' '
	                              AND KM.ZLD_FILIAL = ZLD.ZLD_FILIAL
	                              AND KM.ZLD_SETOR = ZLD.ZLD_SETOR
	                              AND KM.ZLD_LINROT = ZLD.ZLD_LINROT
	                              AND KM.ZLD_FRETIS = ZLD.ZLD_FRETIS
	                              AND KM.ZLD_LJFRET = ZLD.ZLD_LJFRET
	                              AND KM.ZLD_DTCOLE BETWEEN ZLE.ZLE_DTINI AND ZLE.ZLE_DTFIM
	                            GROUP BY KM.ZLD_TICKET, KM.ZLD_KM) A), 0) KM
	          FROM %Table:ZLD% ZLD, %Table:ZLE% ZLE
	         WHERE ZLD.D_E_L_E_T_ = ' '
	           AND ZLE.D_E_L_E_T_ = ' '
	           %exp:_cFiltro%
	           AND ZLD.ZLD_FRETIS BETWEEN %exp:MV_PAR04% AND %exp:MV_PAR05%
	           AND ZLD.ZLD_LJFRET BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR07%
	           AND ZLE.ZLE_COD = %exp:MV_PAR02%
	           AND ZLD.ZLD_DTCOLE BETWEEN ZLE.ZLE_DTINI AND ZLE.ZLE_DTFIM
	         GROUP BY ZLD.ZLD_FILIAL, ZLD.ZLD_SETOR, ZLD.ZLD_LINROT, ZLD.ZLD_FRETIS, ZLD.ZLD_LJFRET,
	                  ZLE.ZLE_COD, ZLE.ZLE_DTINI, ZLE.ZLE_DTFIM) RES,
	       %Table:ZL3% ZL3, %Table:SA2% SA2, %Table:ZL2% ZL2
	 WHERE ZL3.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND ZL2.D_E_L_E_T_ = ' '
	   AND RES.ZLD_FILIAL = ZL2.ZL2_FILIAL
	   AND RES.ZLD_FILIAL = ZL3.ZL3_FILIAL
	   AND RES.ZLD_LINROT = ZL3.ZL3_COD
	   AND RES.ZLD_SETOR = ZL2.ZL2_COD
	   AND SA2.A2_COD = RES.ZLD_FRETIS
	   AND SA2.A2_LOJA = RES.ZLD_LJFRET
	 GROUP BY RES.ZLD_FILIAL, %exp:_cCampos% SA2.A2_COD, SA2.A2_LOJA, SA2.A2_NOME, SA2.A2_EMAIL, RES.ZLE_DTINI
	 ORDER BY RES.ZLD_FILIAL, SA2.A2_COD, SA2.A2_LOJA %exp:_cOrder%
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
	//O envio de e-mail só deve ser disparado no modo analítico pois é onde é segregrado por setor, visto que é emitido um CT-e por setor
	If MV_PAR10 == 1 .And. (_cAlias)->TOTFRE > 0
		If !Empty((_cAlias)->A2_EMAIL)
			_cAssunto := "Solicitação de CT-e - " + (_cAlias)->(A2_COD+A2_LOJA) +" - " + AllTrim((_cAlias)->A2_NOME) +" - Setor: "+ (_cAlias)->ZL2_COD+" - "+ AllTrim((_cAlias)->ZL2_DESCRI)
			_cMensagem := "<HTML><HEAD></HEAD><BODY><Font face='arial' Style='font-size:14px'>"
			_cMensagem += "Boa tarde,<br><br>"
			_cMensagem += "Favor emitir CT-E para "+(_cAlias)->(A2_COD+A2_LOJA) +" - " + AllTrim((_cAlias)->A2_NOME)+" referente ao mês de "+Upper(MesExtenso(Month((_cAlias)->ZLE_DTINI)))+"/"+Str(Year((_cAlias)->ZLE_DTINI),4)+", do serviço prestado no setor: "+(_cAlias)->ZL2_COD+" - "+ AllTrim((_cAlias)->ZL2_DESCRI)+".<br><br><br>"
			_cMensagem += "Volume Coletado: "+AllTrim(Transform((_cAlias)->VOLUME,"@E 9,999,999,999"))+" <br>"
			_cMensagem += "Total KM: "+AllTrim(Transform((_cAlias)->KM,"@E 999,999,999"))+" <br>"
			_cMensagem += "Valor Pedágio: R$ "+AllTrim(Transform((_cAlias)->PEDAGIO,GetSX3Cache("ZLC_QTD","X3_PICTURE")))+" <br>"
			_cMensagem += "Valor Frete: R$ "+AllTrim(Transform((_cAlias)->(TOTFRE-PEDAGIO),GetSX3Cache("ZLC_QTD","X3_PICTURE")))+" <br>"
			_cMensagem += "Valor Total CT-e: R$ "+AllTrim(Transform((_cAlias)->TOTFRE,GetSX3Cache("ZLC_QTD","X3_PICTURE")))+" <br>"
			_cMensagem += "</Font></BODY></HTML>"

			If U_EnvMail(_cMensagem/*_cMensagem*/,_cFrom/*_cFrom*/,(_cAlias)->A2_EMAIL/*_cTO*/,;
					_cReplyTo/*_cCC*/,/*_cBCC*/,_cReplyTo/*_cReplyTo*/,_cAssunto/*_cAssunto*/,@_cErro/*_cErro*/)
				oReport:Section(1):Cell("LOG"):SetBlock({||"e-Mail enviado com sucesso." })
			Else
				oReport:Section(1):Cell("LOG"):SetBlock({||_cErro })
			EndIf
		Else
			oReport:Section(1):Cell("LOG"):SetBlock({||"e-Mail não informado no cadastro do transportador" })
		EndIf
	EndIf
	oReport:Section(1):PrintLine()
	oReport:IncMeter()
	_cFilial := (_cAlias)->ZLD_FILIAL
	_cFretis := (_cAlias)->A2_COD +"-"+(_cAlias)->A2_LOJA
	(_cAlias)->(DBSkip())
EndDo

oReport:Section(1):Finish()
(_cAlias)->(DBCloseArea())

Return
