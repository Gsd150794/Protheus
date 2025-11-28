/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |04/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Lucas Borges  |10/01/2019| Chamado 23984. Incluído tratamento para CTeOS.
Lucas Borges  |22/05/2024| Chamado 47282. Melhoria no tratatamento da emissão na CKO.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RCOM004
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/05/2018
Descrição---------: Fila processamento XMLs. Chamado 24695
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM004

Local oReport
Local _cPerg	:= "RCOM004"
Local _cAlias 	:= GetNextAlias()
Local _aSelFil	:= {}

Pergunte( _cPerg , .F. )

oReport := RCOM004RUN(_cAlias, _aSelFil)

oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: RCOM004RUN
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/05/2018
Descrição---------: Processa a montagem do relatório
Parametros--------: _cAlias, _aSelFil
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM004RUN(_cAlias, _aSelFil)

Local oSection1	:= Nil
Local _cRaz		:= ""

//Criacao do componente de impressao
//TReport():New
//ExpC1 : Nome do relatorio
//ExpC2 : Titulo
//ExpC3 : Pergunte
//ExpB4 : Bloco de codigo que sera executado na confirmacao da impressao
//ExpC5 : Descricao
oReport := TReport():New( "RCOM004" , "Fila de XMLs para Processamento", "RCOM004" , {|oReport| RCOM004PRT( oReport , _cAlias, _aSelFil ) } , "Fila de XMLs para Processamento" , .T. )
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
TRCell():New( oSection2 , "DS_FILIAL"	,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->FILIAL	})
TRCell():New( oSection2 , "DS_EMISSAO",_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| SToD((_cAlias)->EMISSAO)	})
TRCell():New( oSection2 , "DS_CHAVENF"	,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->CHAVE	})
TRCell():New( oSection2 , "DS_DOC"		,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->NUMERO	})
TRCell():New( oSection2 , "DS_SERIE"	,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->SERIE	})
TRCell():New( oSection2 , "A2_CGC"		,_cAlias, /*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->CNPJ	})
TRCell():New( oSection2 , "A2_NOME"		,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| (_cAlias)->NOME	})
TRCell():New( oSection2 , "DS_ESPECI"	,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| AllTrim((_cAlias)->ESPECIE)	})
TRCell():New( oSection2 , "STATUS_REPROCESSAMENTO"	,_cAlias,"Status Reproc.",,18,,{|| AllTrim((_cAlias)->STATUS_REPROCESSAMENTO)	})
TRCell():New( oSection2 , "CKO_CODERR"	,_cAlias,/*X3Titulo*/,/*Picture*/,/*Tamanho*/,/*lPixel*/,{|| AllTrim((_cAlias)->ERRO_REPROCESSAMENTO)	})
TRCell():New( oSection2 , "ERRO_REPROCESSAMENTO"	,_cAlias, "Descrição Erro"		,, 50 ,, {|| U_ColErro((_cAlias)->ERRO_REPROCESSAMENTO)	})

//Quebra página por seção
oSection1:SetPageBreak(.T.)
	
Return( oReport )

/*
===============================================================================================================================
Programa----------: RCOM004PRT
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/05/2018
Descrição---------: Processa a impressão do relatório
Parametros--------: oReport , _cAlias, _aSelFil
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM004PRT( oReport , _cAlias, _aSelFil)

Local oSection1	:= oReport:Section(1):Section(1)
Local oSection2	:= oReport:Section(1):Section(2)
Local _cFil		:= ""
Local _cQuery	:= "%"
Local _lPlanilha := oReport:nDevice == 4
Local _nCountRec:= 0

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"SDS")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cQuery +=" AND RTRIM(CKO.CKO_FILPRO) " +GetRngFil( _aSelFil, "SDS", .T.,)
If !Empty(MV_PAR03) //Emissao
	_cQuery += " AND CKO.CKO_I_EMIS BETWEEN '"+ DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "'"
EndIf
If !Empty(MV_PAR07) //Numero
   _cQuery += " AND SubStr(CKO.CKO_ARQUIV, 29, 9) BETWEEN '"+ MV_PAR06 + "' AND '" + MV_PAR07 + "'"
EndIf
If !Empty(MV_PAR09) //Serie
   _cQuery += " AND SubStr(CKO.CKO_ARQUIV, 26, 3) BETWEEN '"+ MV_PAR08 + "' AND '" + MV_PAR09 + "'"
EndIf
If !Empty(MV_PAR05) //CNPJ
   _cQuery += " AND CKO.CKO_I_EMIT BETWEEN '"+ MV_PAR04 + "' AND '" + MV_PAR05 + "'"
EndIf

_cQuery+=" %"

//==========================================================================
// Query do relatório da secao 1                                            
//==========================================================================
oSection1:BeginQuery()

oReport:SetMsgPrint("Consultando registros no Banco de Dados")
oReport:SetMeter(0)

BeginSql Alias _cAlias

SELECT RTRIM(CKO.CKO_FILPRO) FILIAL,
       CKO.CKO_I_EMIS EMISSAO,
       SubStr(CKO.CKO_ARQUIV, 4, 44) CHAVE,
       SubStr(CKO.CKO_ARQUIV, 29, 9) NUMERO,
       SubStr(CKO.CKO_ARQUIV, 26, 3) SERIE,
       CKO.CKO_I_EMIT CNPJ,
       (SELECT NOME
          FROM ((SELECT A2_CGC CGC, A2_NOME NOME
                   FROM %Table:SA2%
                  WHERE D_E_L_E_T_ = ' '
                    AND CKO.CKO_I_EMIT = A2_CGC
                  GROUP BY A2_CGC, A2_NOME
                 UNION
                 SELECT A1_CGC CGC, A1_NOME NOME
                   FROM %Table:SA1%
                  WHERE D_E_L_E_T_ = ' '
                    AND CKO.CKO_I_EMIT = A1_CGC
                  GROUP BY A1_CGC, A1_NOME))
         WHERE ROWNUM = 1) NOME,
       Case
         WHEN CKO_FLAG = '2' THEN
          'Inconsistencia'
         WHEN CKO_FLAG = '9' THEN
          'Excluido_Fiscal'
         WHEN CKO_FLAG = '0' THEN
          'Pendente'
         WHEN CKO_FLAG = '1' AND EXISTS
          (SELECT 1
                 FROM %Table:SDS% SDS
                WHERE SDS.D_E_L_E_T_ = ' '
                  AND RTRIM(CKO.CKO_FILPRO) = SDS.DS_FILIAL
                  AND SDS.DS_CHAVENF = SubStr(CKO.CKO_ARQUIV, 4, 44)) THEN
          'Excluido'
         Else
          'Acionar TI'
       END STATUS_REPROCESSAMENTO,
       CKO_CODERR ERRO_REPROCESSAMENTO,
       DECODE(CKO_CODEDI, '109', 'NFE', '214', 'CTE', '273', 'CTEOS') ESPECIE
  FROM %Table:CKO% CKO
 WHERE CKO.D_E_L_E_T_ = ' '
   AND CKO.CKO_FLAG <> '1'
   %exp:_cQuery%
 ORDER BY FILIAL, CHAVE

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

oReport:SetMsgPrint("Imprimindo")
oReport:SetMeter(_nCountRec)

If !_lPlanilha
   	oSection2:Cell("DS_FILIAL"):Disable()
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
