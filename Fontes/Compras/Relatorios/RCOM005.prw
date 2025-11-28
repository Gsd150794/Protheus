/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/09/2019| Chamado 28346. Retirada chamada da função itputx1.
Lucas Borges  |04/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Lucas Borges  |25/01/2023| Chamado 42685. Retirada referência à tabela ZZM.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RCOM005
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 10/05/2018
Descrição---------: Documentos de entrada X MD-e. Chamado 24792
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM005

Local oReport
Local _cPerg	:= "RCOM005"
Local _cAlias 	:= GetNextAlias()
Local _aSelFil	:= {}

Pergunte( _cPerg , .F. )

oReport := RCOM005RUN(_cAlias, _aSelFil)

oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: RCOM005RUN
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 10/05/2018
Descrição---------: Processa a montagem do relatório
Parametros--------: _cAlias, _aSelFil
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM005RUN(_cAlias, _aSelFil)

Local oSection1	:= Nil
Local _cRaz		:= ""

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao
oReport := TReport():New( "RCOM005" , "Documentos de Entrada x MD-e", "RCOM005" , {|oReport| RCOM005PRT( oReport , _cAlias, _aSelFil ) } , "Documentos de Entrada x MD-e" , .T. )
oSection := TRSection():New( oReport , "" , {""} )
oSection:SetTotalInLine(.F.)

oSection1 := TRSection():New(oSection,"Filial"	,{""})
oSection1:SetTotalInLine(.F.)

TRCell():New( oSection1 , "FILIAL" ,, "Filial" ,, 20 ,, {|| FILIAL } )
TRCell():New( oSection1 , "_cRaz"		,, "Nome "		,, 60 ,, {|| _cRaz		})

oSection2 := TRSection():New( oSection , "Documentos")
oSection2:SetTotalInLine(.F.)

//TRFunction():New(oCell,cName,cFunction,oBreak,cTitle,cPicture,uFormula,lEndSection,lEndReport,lEndPage,oParent,bCondition,lDisable,bCanPrint) 
//TRCell():New(oParent,cName,cAlias,cTitle,cPicture,nSize,lPixel,bBlock,cAlign,lLineBreak,cHeaderAlign,lCellBreak,nColSpace,lAutoSize,nClrBack,nClrFore,lBold)
TRCell():New( oSection2 , "F1_FILIAL"			,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->FILIAL	})
TRCell():New( oSection2 , "F1_EMISSAO"			,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->F1_EMISSAO	})
TRCell():New( oSection2 , "F1_DTDIGIT"			,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->F1_DTDIGIT	})
TRCell():New( oSection2 , "F1_CHVNFE"			,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->F1_CHVNFE	})
TRCell():New( oSection2 , "STATUS_ESCRITURACAO"	,_cAlias,"Status Escrit.",/*Picture*/,15,/*lPixel*/,{|| AllTrim((_cAlias)->STATUS_ESCRITURACAO)	})
TRCell():New( oSection2 , "MANIFESTACAO"		,_cAlias,"Manifestação",/*Picture*/,17,/*lPixel*/,{|| AllTrim((_cAlias)->MANIFESTACAO)	})
TRCell():New( oSection2 , "STATUS_TRANS"		,_cAlias,"Status Transmissão",/*Picture*/,17,/*lPixel*/,{|| AllTrim((_cAlias)->STATUS_TRANS)	})
TRCell():New( oSection2 , "TP_TRANS"			,_cAlias,"Tipo Transmissão",/*Picture*/,17,/*lPixel*/,{|| AllTrim((_cAlias)->TP_TRANS)	})
TRCell():New( oSection2 , "STATUS_TRANS_TSS"	,_cAlias,"Status Transmissão TSS",/*Picture*/,17,/*lPixel*/,{|| AllTrim((_cAlias)->STATUS_TRANS_TSS)	})

//Quebra página por seção
oSection1:SetPageBreak(.T.)
	
Return( oReport )

/*
===============================================================================================================================
Programa----------: RCOM005PRT
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 10/05/2018
Descrição---------: Processa a impressão do relatório
Parametros--------: oReport , _cAlias, _aSelFil
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM005PRT( oReport , _cAlias, _aSelFil)

Local oSection1	:= oReport:Section(1):Section(1)
Local oSection2	:= oReport:Section(1):Section(2)
Local _cFil		:= ""
Local _cQuery	:= "%"
Local _cQryFil	:= " "
Local _cFilSF1	:= "%"
Local _lPlanilha := oReport:nDevice == 4
Local _nCountRec:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"SF1")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf
_cQryFil := GetRngFil( _aSelFil, "SF1", .T.,)

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cFilSF1+=" AND SF1.F1_FILIAL " +_cQryFil +" "
_cFilSF1+=" AND SF1.F1_EMISSAO BETWEEN '"+ DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "'"
_cFilSF1+=" AND SF1.F1_DTDIGIT BETWEEN '"+ DToS(MV_PAR04) + "' AND '" + DToS(MV_PAR05) + "'%"

If !Empty(MV_PAR06)
	_cQuery+=" AND TPEVENTO IN "+StrTran(FormatIn(AllTrim(MV_PAR06),";"),"'","")
EndIf
If !Empty(MV_PAR07)
	_cQuery+=" AND STATUS_154 IN "+StrTran(FormatIn(AllTrim(MV_PAR07),";"),"'","")
EndIf
_cQuery+="%"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oSection1:BeginQuery()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql Alias _cAlias

 SELECT F1_FILIAL FILIAL,
        F1_EMISSAO,
        F1_DTDIGIT,
        F1_CHVNFE,
        Case
          WHEN F1_STATUS = 'A' THEN
           'Classificado'
          WHEN F1_STATUS = ' ' THEN
           'Pre-nota'
        END STATUS_ESCRITURACAO,
        Case
          WHEN C00_STATUS = '0' THEN
           'Sem Manif.'
          WHEN C00_STATUS = '1' THEN
           'Confirmada'
          WHEN C00_STATUS = '2' THEN
           'Desconhecida'
          WHEN C00_STATUS = '3' THEN
           'Nao realizada'
          WHEN C00_STATUS = '4' THEN
           'Ciencia'
          WHEN C00_STATUS IS NULL THEN
           'NF-e inexistente'
        END MANIFESTACAO,
        Case
          WHEN C00_CODEVE = '1' THEN
           'Nao Transmit.'
          WHEN C00_CODEVE = '2' THEN
           'Monit. Pendente'
          WHEN C00_CODEVE = '3' THEN
           'Manif. Sucesso'
          WHEN C00_CODEVE = '4' THEN
           'Manif. Problema'
          WHEN C00_CODEVE IS NULL THEN
           'NF-e inexistente'
        END STATUS_TRANS,
        Case
          WHEN TPEVENTO = 210200 THEN
           'Confirmada'
          WHEN TPEVENTO = 210220 THEN
           'Desconhecida'
          WHEN TPEVENTO = 210240 THEN
           'Nao Realizada'
          WHEN TPEVENTO = 210210 THEN
           'Ciencia'
          WHEN TPEVENTO = 110111 THEN
           'Cancelamento'
          WHEN TPEVENTO = 888888 THEN
           'Nao Transmitido'
          Else
           'Acionar TI'
        END TP_TRANS,
        Case
          WHEN STATUS_154 = 6 THEN
           'OK'
          WHEN STATUS_154 = 5 THEN
           'Erro'
          WHEN STATUS_154 = 8 THEN
           'Nao Transmitido'
          Else
           'Acionar TI'
        END STATUS_TRANS_TSS,
        TPEVENTO
   FROM (SELECT F1_FILIAL,
                F1_EMISSAO,
                F1_DTDIGIT,
                F1_CHVNFE,
                F1_STATUS,
                C00_STATUS,
                C00_CODEVE,
                NVL(TPEVENTO, 888888) TPEVENTO,
                NVL(STATUS_154, 8) STATUS_154
           FROM %Table:SF1% SF1
           LEFT JOIN %Table:C00% C001
             ON (C001.D_E_L_E_T_ = ' ' AND C001.C00_FILIAL = SF1.F1_FILIAL AND
                C001.C00_CHVNFE = SF1.F1_CHVNFE)
           LEFT JOIN (SELECT S.M0_CODFIL   FILIAL,
                            SPED154.NFE_CHV  NFE_CHV,
                            SPED154.TPEVENTO TPEVENTO,
                            SPED154.STATUS   STATUS_154
                       FROM SPED154, SPED001, SYS_COMPANY S
                      WHERE SPED154.D_E_L_E_T_ = ' '
                        AND SPED001.D_E_L_E_T_ = ' '
                        AND S.D_E_L_E_T_ = ' '
                        AND SPED001.IE = S.M0_INSC
                        AND SPED001.ID_ENT = SPED154.ID_ENT
                        AND S.M0_CGC = SPED001.CNPJ
                        AND SPED154.TPEVENTO IN
                            (210200, 210220, 210240, 210210)
                        AND SPED154.R_E_C_N_O_ =
                            (SELECT MAX(B.R_E_C_N_O_)
                               FROM SPED154 B
                              WHERE B.D_E_L_E_T_ = ' '
                                AND B.NFE_CHV = SPED154.NFE_CHV
                                AND B.ID_ENT = SPED154.ID_ENT)) SPED154T
             ON (SPED154T.FILIAL = SF1.F1_FILIAL AND
                SPED154T.NFE_CHV = SF1.F1_CHVNFE)
          WHERE SF1.D_E_L_E_T_ = ' '
            AND SF1.F1_FORMUL <> 'S'
            AND SF1.F1_CHVNFE <> ' '
            AND SF1.F1_ESPECIE = 'SPED'
            %exp:_cFilSF1%)
   	WHERE F1_FILIAL <> ' '
	%exp:_cQuery%
  ORDER BY F1_FILIAL, F1_EMISSAO, F1_CHVNFE

EndSql
//==========================================================================
// Metodo EndQuery ( Classe TRSection )                                     
//                                                                          
// Prepara o relatório para executar o Embedded SQL.                        
//                                                                          
// ExpA1 : Array com os parametros do tipo Range                            
//                                                                          
//==========================================================================
oSection1:EndQuery(/*Array com os parametros do tipo Range*/)

//=======================================================================
//Impressao do Relatorio
//=======================================================================
Count To _nCountRec
(_cAlias)->( DBGoTop() )
oReport:SetMeter(_nCountRec)
oReport:SetMsgPrint("Imprimindo")
oReport:SetMeter(_nCountRec)

If !_lPlanilha
   	oSection2:Cell("F1_FILIAL"):Disable()
EndIf

While !oReport:Cancel() .And. (_cAlias)->( !Eof() )
	oReport:IncMeter()
	If (_cAlias)->FILIAL <> _cFil
		oSection1:Init()
		oSection1:Cell("_cRaz"):SetValue( FWFilialName(cEmpAnt,(_cAlias)->FILIAL,1 ) )
		oSection1:PrintLine()
		oSection1:Finish()
		oSection2:Finish()
		oSection2:Init()
		oSection2:PrintLine()
		_cFil := (_cAlias)->FILIAL
	Else
		oSection2:PrintLine()
	EndIf
	(_cAlias)->( DBSkip() )
EndDo

oSection1:Finish()
oSection1:Init()
oSection2:Finish()
oSection2:Init()

Return
