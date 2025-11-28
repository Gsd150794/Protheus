/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |16/09/2019| Chamado 28346. Retirado uso não permitido de chamada de API de Console.
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "report.ch"

/*
===============================================================================================================================
Programa----------: RPON010
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/02/2018
Descrição---------: Relatório de Refeições.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RPON010

Local aOrd := {}
Private _cPerg := "RPON010"
Private _cNomeFunc := ""
Private oReport, oSecDados_1

Begin Sequence
   
   Pergunte("RPON010" , .F.)

   DEFINE REPORT oReport NAME _cPerg TITLE "Relatório de Refeições" PARAMETER _cPerg ACTION {|oReport| U_RPON010P(oReport)} Description "Este relatório emitirá uma listagem de movimentos do refeitorio."

   //Seta Padrao de impressao como Paisagem
   oReport:SetLandscape()
   oReport:SetTotalInLine(.T.)                                                        

   //====================================================================
   // Define secoes do relatorio.
   //====================================================================

    DEFINE Section oSecDados_1 OF oReport TITLE "Relatorio Refeiçoes" TABLES "QRYSP5" ORDERS aOrd

    DEFINE CELL NAME "CFILIAL"   OF oSecDados_1 ALIAS "QRYSP5"  TITLE "Filial" SIZE 6
    DEFINE CELL NAME "DDATA"     OF oSecDados_1 ALIAS "QRYSP5"  TITLE "Dia Refeição" SIZE 12
    DEFINE CELL NAME "MATRICULA" OF oSecDados_1 ALIAS "QRYSP5"  TITLE "Matricula" SIZE 10
    DEFINE CELL NAME "NOMEFUNC"  OF oSecDados_1 ALIAS "QRYSP5"  TITLE "Nome Funcionario" SIZE 40
    DEFINE CELL NAME "VALORDESC" OF oSecDados_1 ALIAS "QRYSP5"  TITLE "Valor Refeicao" SIZE 18
    DEFINE CELL NAME "HORA"      OF oSecDados_1 ALIAS "QRYSP5"  TITLE "Hora REfeição" SIZE 14
    DEFINE CELL NAME "TIPOREF"   OF oSecDados_1 ALIAS "QRYSP5"  TITLE "Tipo Refeiçao" SIZE 14
    DEFINE CELL NAME "DESCREF"   OF oSecDados_1 ALIAS "QRYSP5"  TITLE "Desc.Tipo Ref." SIZE 20

    oSecDados_1:Cell("VALORDESC"):SetHeaderAlign("RIGHT") 

    oSecDados_1:SetTotalInLine(.T.)                                               

    oSecDados_1:OnPrintLine({|| _cNomeFunc := QRYSP5->MATRICULA  + " - " + SubStr(QRYSP5->NOMEFUNC,1,40)})
    
    oReport:PrintDialog()

End Sequence

Return

/*
===============================================================================================================================
Função------------: RPON010P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/02/2018
Descrição---------: Retornar a ultima data de afastamento do funcionário.
Parametros--------: oReport = Objeto do relatório.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RPON010P(oReport)

Local _cQry, _cQry2
Local _aSaveArea := FWGetArea()
Local _cWhere, _cWhere2 
Local _cQuery
Local _cOrderm

Begin Sequence
   oReport:SetTitle("Relatório de Refeições - Emissao de " + DToC(MV_PAR02) + " até "  + DToC(MV_PAR03))
   oSecDados_1:Enable() 
   
   oBrkDados_1:= TRBreak():New(oSecDados_1,oSecDados_1:CELL("MATRICULA"),"SubTotal Refeições: ",.F.)          
   oBrkDados_1:SetTotalText({|| "SubTotal Refeições: " })
		
   TRFunction():New(oSecDados_1:Cell("MATRICULA") ,"MATRICULA" ,"COUNT"  ,oBrkDados_1,NIL,NIL,NIL,.F.,.F.)
   TRFunction():New(oSecDados_1:Cell("VALORDESC")  ,"VALORDESC"  ,"SUM"    ,oBrkDados_1,NIL,NIL,NIL,.F.,.F.)
   
   TRFunction():New(oSecDados_1:Cell("MATRICULA") ,"TOTMATRICULA","COUNT"  ,NIL        ,"TOTAL DE REFEIÇÕES"       ,NIL,NIL,.F.,.T.)
   TRFunction():New(oSecDados_1:Cell("VALORDESC")  ,"TOTVALORDESC" ,"SUM"    ,NIL        ,"VALOR TOTAL DAS REFEIÇÕES",NIL,NIL,.F.,.T.)

   _cWhere := " "
   _cWhere2 := " "

   _cQry := " SELECT DISTINCT P5_FILIAL CFILIAL, P5_DATA DDATA, P5_MAT MATRICULA, RA_NOMECMP NOMEFUNC, P5_HORA HORA, P5_TIPOREF TIPOREF, PM_DESCREF DESCREF, P5_DESCFUN VALORDESC "
   _cQry += " FROM " + RetSqlName("SP5") + " SP5, " + RetSqlName("SRA") + " SRA, " + RetSqlName("SPM") + " SPM "
   _cQry += " WHERE SP5.D_E_L_E_T_ = ' ' AND SRA.D_E_L_E_T_ = ' ' AND SP5.P5_MAT = SRA.RA_MAT AND SP5.P5_FILIAL = SRA.RA_FILIAL "
   _cQry += " AND P5_TIPOREF = PM_TIPOREF "
   
   _cQry2 := " SELECT DISTINCT PN_FILIAL CFILIAL, PN_DATA DDATA, PN_MAT MATRICULA, RA_NOMECMP NOMEFUNC, PN_HORA HORA, PN_TIPOREF TIPOREF, PM_DESCREF DESCREF, PN_DESCFUN VALORDESC "
   _cQry2 += " FROM " + RetSqlName("SPN") + " SPN, " + RetSqlName("SRA") + " SRA, " + RetSqlName("SPM") + " SPM "
   _cQry2 += " WHERE SPN.D_E_L_E_T_ = ' ' AND SRA.D_E_L_E_T_ = ' ' AND SPN.PN_MAT = SRA.RA_MAT AND SPN.PN_FILIAL = SRA.RA_FILIAL "
   _cQry2 += " AND PN_TIPOREF = PM_TIPOREF " 
   
   If ! Empty(MV_PAR01) // Filiais
      _cWhere += " AND P5_FILIAL IN "+ FormatIn(MV_PAR01,";") 
      _cWhere2 += " AND PN_FILIAL IN "+ FormatIn(MV_PAR01,";")  
   EndIf
   
   If !Empty(MV_PAR02) // Data Inicial 
      _cWhere += " AND P5_DATA >= '" + DToS(MV_PAR02) + "' "
      _cWhere2 += " AND PN_DATA >= '" + DToS(MV_PAR02) + "' "
   EndIf
   
   If !Empty(MV_PAR03)  // Data Final  
      _cWhere += " AND P5_DATA <= '" + DToS(MV_PAR03) + "' "
      _cWhere2 += " AND PN_DATA <= '" + DToS(MV_PAR03) + "' "
   EndIf

   If !Empty(MV_PAR04) // Matrícula de 
      _cWhere += " AND P5_MAT >= '" + MV_PAR04 + "' "
      _cWhere2 += " AND PN_MAT >= '" + MV_PAR04 + "' "
   EndIf
   
   If !Empty(MV_PAR05) // Matrícula até 
      _cWhere += " AND P5_MAT <= '" + MV_PAR05 + "' "
      _cWhere2 += " AND PN_MAT <= '" + MV_PAR05 + "' "
   EndIf
   
   If !Empty(MV_PAR06) // Tipo Refeição 
      _cWhere += " AND P5_TIPOREF IN "+ FormatIn(MV_PAR06,";") 
      _cWhere2 += " AND PN_TIPOREF IN "+ FormatIn(MV_PAR06,";")  
   EndIf  

   If MV_PAR07 = 1
      _cOrderm := " ORDER BY CFILIAL, NOMEFUNC , DDATA " 
   Else
      _cOrderm := " ORDER BY CFILIAL, MATRICULA, DDATA " 
   EndIf

   _cQuery := _cQry + _cWhere + " UNION " + _cQry2 + _cWhere2 + _cOrderm
   //_cQuery += " ORDER BY FILIAL, MATRICULA, DDATA "
   
   If Select("QRYSP5")
      QRYSP5->(DBCloseArea())
   EndIf
   
   DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , "QRYSP5" , .F. , .T. )
   TCSetField("QRYSP5","DDATA","D",8,0)
   TCSetField("QRYSP5","VALORDESC","N",18,6)
		
   QRYSP5->( DBGoTop() )
   
   oSecDados_1:Print(.T.)
  
   QRYSP5->( DBCloseArea() )

End Sequence

FWRestArea(_aSaveArea)

Return
