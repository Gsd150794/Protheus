/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |10/02/2020| Chamado 32011. Migração do relatório para tReport.
Lucas Borges  |17/12/2020| Chamado 34997. Ajuste para impressão no WebApp.
Lucas Borges  |26/01/2021| Chamado 35410. Corrigidas as informações cortadas.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGLT024
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 11/02/2020
Descrição---------: Relatório Mapa Analítico Fretistas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT024()

Local oReport
Pergunte("RGLT024",.F.)
//Inferface de Impressão
oReport := ReportDef()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: ReportDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 11/02/2020
Descrição---------: Definição do Componente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportDef()

Local oReport
Local oFornec
Local oMovimen
Local _aOrdem   := {"Fretista","Fretista X Setor","Fretista x Linha","Setor X Fretista","Linha x Fretista"}
Local _nX 		:= 0

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao

oReport := TReport():New("RGLT024","Mapa Analítico Fretista","RGLT024",;
{|oReport| ReportPrint(oReport,_aOrdem)},"Apresenta informações referente aos movimentos diários do Fretista.")
oReport:SetLandscape()//Paisagem

//Sessão 1 - Cabeçalho com dados do Fretista
oFornec := TRSection():New(oReport,"Fretistas"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais1: "/*uTotalText*/)
oFornec:SetTotalInLine(.F.)
//oFornec:SetHeaderPage()

TRCell():New(oFornec,"ZL2_FILIAL",/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*Block*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oFornec,"FORNEC",/*Table*/,"Código"/*cTitle*/,/*Picture*/,11/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oFornec,"A2_NOME",/*Table*/,"Fretista"/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oFornec,"ZL2_COD",/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oFornec,"ZL2_DESCRI",/*Table*/,"Setor"/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oFornec,"ZL3_COD",/*Table*/,/*cTitle*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
TRCell():New(oFornec,"ZL3_DESCRI",/*Table*/,"Linha/Rota"/*cTitle*/,/*Picture*/,30/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,/*cHeaderAlign*/,/*lCellBreak*/,/*nColSpace*/,/*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

//Sessão 2 - Itens com dados dos movimentos do Fretista
oMovimen := TRSection():New(oFornec,"Movimentos"	,/*uTable {}*/, _aOrdem/*aOrder*/, .F./*lLoadCells*/, .T./*lLoadOrder*/,"Total das Filiais2: "/*uTotalText*/)
oMovimen:SetTotalInLine(.F.)
oMovimen:SetHeaderPage()
oMovimen:nFontBody := 5
For _nX := 1 to 31
	TRCell():New(oMovimen,"X"+StrZero(_nX,2),/*Tabela*/," "+StrZero(_nX,2)/*cTitle*/,"@E 999,999"/*Picture*/,/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,0/*nColSpace*/,.T./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)
Next _nX
TRCell():New(oMovimen,"TOTAL",/*Tabela*/,"Total"/*cTitle*/,"@E 99,999,999"/*Picture*/,9/*Tamanho*/,/*lPixel*/,/*{||bBlock}*/,/*cAlign*/,/*lLineBreak*/,"RIGHT"/*cHeaderAlign*/,/*lCellBreak*/,0/*nColSpace*/,.F./*lAutoSize*/,/*nClrBack*/,/*nClrFore*/,/*lBold*/)

Return oReport

/*
===============================================================================================================================
Programa----------: ReportPrint
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 11/02/2020
Descrição---------: Processa impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ReportPrint(oReport,_aOrdem)

Local _cFiltro		:= "%"
Local _cFiltro2		:= ""
Local _cCampo1		:= "%"
Local _cCampo2		:= "%"
Local _cTabela		:= "%"
Local _cGroup		:= "%"
Local _cOrder		:= "%"
Local _cAlias		:= ""
Local _aSelFil		:= {}
Local _nOrdem		:= oReport:Section(1):GetOrder()
Local oFornec  		:= oReport:Section(1)
Local oMovimen 		:= oReport:Section(1):Section(1)
Local _cFilial		:= ""
Local _nCountRec	:= 0
Local _cAux			:= IIf( MV_PAR10 == 1 , "ZLD" , "ZLW" )//1-Produtor 2-Cooperativa
Local _cDesc		:= ""
Local _nX			:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR09 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,_cAux)
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

//=====================================================
// Adiciona a ordem escolhida ao titulo do relatorio  |
//=====================================================
oReport:SetTitle(oReport:Title() + " ("+AllTrim(_aOrdem[_nOrdem])+" - "+IIf(MV_PAR11==1,"Leite","KM")+")  - "+DToC(MV_PAR06)+" - "+DToC(MV_PAR07))

//==========================================================================
// Transforma parametros Range em expressao SQL                             	
//==========================================================================
MakeSqlExpr(oReport:uParam)

//================================================================================
//| Configuração das quebras do relatório                                        |
//================================================================================
If _nOrdem == 4
	oQbrSetor := TRBreak():New( oFornec/*oParent*/, oFornec:Cell("ZL3_COD")/*uBreak*/, {||"Total do Setor: " + _cDesc}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
	For _nX := 1 to 31
		TRFunction():New(oMovimen:Cell("X"+StrZero(_nX,2))/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSetor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	Next _nX
	TRFunction():New(oMovimen:Cell("TOTAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrSetor/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
EndIf

If _nOrdem == 5
	oQbrLinha := TRBreak():New( oFornec/*oParent*/, oFornec:Cell("ZL3_COD")/*uBreak*/, {||"Total da Linha: " + _cDesc}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
	For _nX := 1 to 31
		TRFunction():New(oMovimen:Cell("X"+StrZero(_nX,2))/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrLinha/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
	Next _nX
	TRFunction():New(oMovimen:Cell("TOTAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrLinha/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
EndIf

oQbrFilial := TRBreak():New( oFornec/*oParent*/, oFornec:Cell("ZL2_FILIAL")/*uBreak*/, {||"Total da Filial: " + _cFilial + ' - '+ FWFilialName(cEmpAnt,_cFilial,1 )}/*uTitle*/, .F. /*lTotalInLine*/,/*cName*/,.T./*lPageBreak*/)
For _nX := 1 to 31
	TRFunction():New(oMovimen:Cell("X"+StrZero(_nX,2))/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)
Next _nX
TRFunction():New(oMovimen:Cell("TOTAL")/*oCell*/,/*cName*/,"SUM"/*cFunction*/,oQbrFilial/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.T./*lEndSection*/,.F./*lEndReport*/,/*lEndPage*/,/*oParent*/,/*bCondition*/,/*lDisable*/,/*bCanPrint*/)

//==========================================================================
// Trata as células a serem exibidas de acordo com sessão e parâmetros
//==========================================================================
If _nOrdem == 1
	oFornec:Cell("ZL2_COD"):Disable()
	oFornec:Cell("ZL2_DESCRI"):Disable()
	oFornec:Cell("ZL3_COD"):Disable()
	oFornec:Cell("ZL3_DESCRI"):Disable()
ElseIf _nOrdem == 2 .Or. _nOrdem == 4
	oFornec:Cell("ZL3_COD"):Disable()
	oFornec:Cell("ZL3_DESCRI"):Disable()
EndIf

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFiltro += " AND M."+ _cAux +"_FILIAL = ZL3.ZL3_FILIAL"
_cFiltro += " AND M."+ _cAux +"_LINROT = ZL3.ZL3_COD"
_cFiltro += " AND M."+ _cAux +"_FILIAL = ZL2.ZL2_FILIAL"
_cFiltro += " AND M."+ _cAux +"_SETOR = ZL2.ZL2_COD"
_cFiltro += " AND M."+ _cAux +"_FRETIS = SA2.A2_COD"
_cFiltro += " AND M."+ _cAux +"_LJFRET = SA2.A2_LOJA"
_cFiltro += " AND M."+ _cAux +"_DTCOLE BETWEEN '"+ DToS(MV_PAR06) +"' AND '"+ DToS(MV_PAR07) +"'"

_cFiltro += " AND ZL2_FILIAL "+ GetRngFil( _aSelFil, _cAux, .T.,)
//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR01) .Or. Empty(MV_PAR01) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND ZL2_COD IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
	_cFiltro2 += " AND N."+ _cAux +"_SETOR IN "+ FormatIn( AllTrim(MV_PAR01) , ';' )
EndIf

//Verifica se foi fornecido o filtro de linha
If !Empty(MV_PAR08)
	_cFiltro += " AND ZL3_COD IN " + FormatIn(AllTrim(MV_PAR08),";")
	_cFiltro2 += " AND N."+ _cAux +"_LINROT IN " + FormatIn(AllTrim(MV_PAR08),";")
EndIf

If _nOrdem == 1
	_cOrder += ", A2_COD, A2_LOJA "
ElseIf _nOrdem == 2 
	_cCampo1 += " ZL2_COD, ZL2_DESCRI, "
	_cGroup += " ZL2_COD, ZL2_DESCRI, "
	_cOrder += ", A2_COD, A2_LOJA, ZL2_COD, ZL2_DESCRI "
ElseIf _nOrdem == 3
	_cCampo1 += " ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI, "
	_cGroup += " ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI, "
	_cOrder += ", A2_COD, A2_LOJA, ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI "
ElseIf _nOrdem == 4 
	_cCampo1 += " ZL2_COD, ZL2_DESCRI, "
	_cGroup += " ZL2_COD, ZL2_DESCRI, "
	_cOrder += ", ZL2_COD, ZL2_DESCRI, A2_COD, A2_LOJA "
ElseIf _nOrdem == 5
	_cCampo1 += " ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI, "
	_cGroup += " ZL2_COD, ZL2_DESCRI, ZL3_COD, ZL3_DESCRI, "
	_cOrder += ", ZL3_COD, ZL3_DESCRI, A2_COD, A2_LOJA, ZL2_COD, ZL2_DESCRI "
EndIf

_cCampo2 := _cCampo1 + " SubStr(M."+ _cAux +"_DTCOLE, 7, 2) DIA, "
If MV_PAR11 == 1 //Soma Volume de Leite
	_cCampo2 += " SUM("+ _cAux +"_QTDBOM) QTD"
Else //Soma KM
	_cCampo2 += " NVL((SELECT SUM("+ _cAux +"_KM)
	_cCampo2 += " FROM (SELECT N."+ _cAux +"_TICKET, N."+ _cAux +"_CODREC, N."+ _cAux +"_KM
	_cCampo2 += "         FROM "+ RetSqlName(_cAux)+" N"
	_cCampo2 += "         WHERE N.D_E_L_E_T_ = ' '
	_cCampo2 += "           AND N."+ _cAux +"_DTCOLE = M."+ _cAux +"_DTCOLE
	_cCampo2 += "           AND N."+ _cAux +"_FILIAL = ZL2_FILIAL
	_cCampo2 += "           AND N."+ _cAux +"_FRETIS = A2_COD
	_cCampo2 += "           AND N."+ _cAux +"_LJFRET = A2_LOJA
	If _nOrdem <> 1
		_cCampo2 += "           AND N."+ _cAux +"_SETOR = ZL2_COD
	EndIf
	If _nOrdem == 3 .Or. _nOrdem == 5
		_cCampo2 += "           AND N."+ _cAux +"_LINROT = ZL3_COD
	EndIf
	_cCampo2 += _cFiltro2
	_cCampo2 += "         GROUP BY N."+ _cAux +"_TICKET, N."+ _cAux +"_CODREC, N."+ _cAux +"_KM)),0) QTD
EndIf

_cGroup += " M."+ _cAux +"_DTCOLE"

_cTabela += RetSqlName(_cAux)

_cCampo1 += " %"
_cCampo2 += " %"
_cTabela += " %"
_cFiltro += " %"
_cGroup += " %"
_cOrder += " %"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oFornec:BeginQuery()	
_cAlias := GetNextAlias()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql alias _cAlias
SELECT ZL2_FILIAL, A2_COD||'-'||A2_LOJA FORNEC, A2_NOME, %exp:_cCampo1%
       NVL(X01,0) X01, NVL(X02,0) X02, NVL(X03,0) X03, NVL(X04,0) X04,
       NVL(X05,0) X05, NVL(X06,0) X06, NVL(X07,0) X07, NVL(X08,0) X08,
       NVL(X09,0) X09, NVL(X10,0) X10, NVL(X11,0) X11, NVL(X12,0) X12,
       NVL(X13,0) X13, NVL(X14,0) X14, NVL(X15,0) X15, NVL(X16,0) X16,
       NVL(X17,0) X17, NVL(X18,0) X18, NVL(X19,0) X19, NVL(X20,0) X20,
       NVL(X21,0) X21, NVL(X22,0) X22, NVL(X23,0) X23, NVL(X24,0) X24,
       NVL(X25,0) X25, NVL(X26,0) X26, NVL(X27,0) X27, NVL(X28,0) X28,
       NVL(X29,0) X29, NVL(X30,0) X30, NVL(X31,0) X31, 
       (NVL(X01,0)+NVL(X02,0)+NVL(X03,0)+NVL(X04,0)+NVL(X05,0)+NVL(X06,0)+NVL(X07,0)+NVL(X08,0)+
       NVL(X09,0)+NVL(X10,0)+NVL(X11,0)+NVL(X12,0)+NVL(X13,0)+NVL(X14,0)+NVL(X15,0)+NVL(X16,0)+
       NVL(X17,0)+NVL(X18,0)+NVL(X19,0)+NVL(X20,0)+NVL(X21,0)+NVL(X22,0)+NVL(X23,0)+NVL(X24,0)+
       NVL(X25,0)+NVL(X26,0)+NVL(X27,0)+NVL(X28,0)+NVL(X29,0)+NVL(X30,0)+NVL(X31,0)) TOTAL
  FROM (SELECT ZL2_FILIAL, A2_COD, A2_LOJA, A2_NOME, %exp:_cCampo2%
          FROM %exp:_cTabela% M, %Table:SA2% SA2, %Table:ZL3% ZL3, %Table:ZL2% ZL2
         WHERE M.D_E_L_E_T_ = ' '
           AND SA2.D_E_L_E_T_ = ' '
           AND ZL3.D_E_L_E_T_ = ' '
           AND ZL2.D_E_L_E_T_ = ' '
           %exp:_cFiltro%
           AND A2_COD BETWEEN %exp:MV_PAR02% AND %exp:MV_PAR04%
           AND A2_LOJA BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR05%
         GROUP BY ZL2_FILIAL, A2_COD, A2_LOJA, A2_NOME, %exp:_cGroup%)
PIVOT(SUM(QTD)
   For DIA IN('01' AS X01, '02' AS X02, '03' AS X03, '04' AS X04, '05' AS X05, '06' AS X06,
              '07' AS X07, '08' AS X08, '09' AS X09, '10' AS X10, '11' AS X11, '12' AS X12,
              '13' AS X13, '14' AS X14, '15' AS X15, '16' AS X16, '17' AS X17, '18' AS X18,
              '19' AS X19, '20' AS X20, '21' AS X21, '22' AS X22, '23' AS X23, '24' AS X24,
              '25' AS X25, '26' AS X26, '27' AS X27, '28' AS X28, '29' AS X29, '30' AS X30,
              '31' AS X31))
ORDER BY ZL2_FILIAL %exp:_cOrder%
EndSql
//==========================================================================
// Metodo EndQuery ( Classe TRSection )                                     
//                                                                          
// Prepara o relatório para executar o Embedded SQL.                        
//                                                                          
// ExpA1 : Array com os parametros do tipo Range                            
//                                                                          
//==========================================================================
oFornec:EndQuery(/*Array com os parametros do tipo Range*/)
//Define se a seção filha utilizara a query da seção pai no processamento do método Print
oMovimen:SetParentQuery()

//=======================================================================
//Impressao do Relatorio
//=======================================================================
oReport:SetMsgPrint("Imprimindo")
oReport:SetMeter(_nCountRec)
	
oFornec:Init()
While !oReport:Cancel() .And. (_cAlias)->(!Eof())
	oFornec:PrintLine()
	oReport:FatLine()
	oMovimen:Init()	
	oMovimen:PrintLine()
	oReport:IncMeter()
	oReport:Skipline()
	_cFilial := (_cAlias)->ZL2_FILIAL
	If _nOrdem == 4
		_cDesc := (_cAlias)->ZL2_COD + " - " + (_cAlias)->ZL2_DESCRI
	ElseIf _nOrdem == 5
		_cDesc := (_cAlias)->ZL3_COD + " - " + (_cAlias)->ZL3_DESCRI
	EndIf
	(_cAlias)->(DBSkip())
EndDo

oFornec:Finish()

(_cAlias)->(DBCloseArea())

Return
