/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Jerry         |12/11/2020| Chamado 33708. Inclusão coluna  Data Canhoto Oper.Logístico.
Igor Melgaço  |20/12/2021| Chamado 38610. Inclusão das campos  Municipio, UF do Cliente, CTE e data de baixa.
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "report.ch"
#Include 'TOPCONN.CH'

/*
===============================================================================================================================
Programa----------: ROMS043
Autor-------------: Julio de Paula Paz
Data da Criacao---: 29/06/2016
Descrição---------: Relatório Notas Fiscais versus Canhoto. Chamado 13615.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS043()
Local _oReport := nil
Private _aOrder := {"Data de Emissão","Cliente","Transportador"}
Private _oSect1_A := Nil
Private _oSect2_A := Nil
Private _oSect1_B := Nil
Private _oSect2_B := Nil
Private _oSect1_C := Nil
Private _oSect2_C := Nil
Private _nOrdReport := 1

Begin Sequence		
	//====================================================================================================
    // Gera a pergunta de modo oculto, ficando disponível no botão ações relacionadas
    //====================================================================================================
    Pergunte("ROMS043",.F.)	          

	//====================================================================================================
    // Chama a montagem do relatório.
    //====================================================================================================	
	_oReport := ROMS043D("ROMS043")
	_oReport:PrintDialog()
	
End Sequence

Return

/*
===============================================================================================================================
Programa----------: ROMS043D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 29/06/2016
Descrição---------: Realiza as definições do relatório. (ReportDef)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS043D(_cNome)
Local _oReport := Nil

Begin Sequence	
   _oReport := TReport():New(_cNome,"Relatório Notas Fiscais X Canhoto",_cNome,{|_oReport| ROMS043P(_oReport)},"Emissão da Relação de Notas Fiscais X Canhotos")
   _oReport:SetLandscape()    
   _oReport:SetTotalInLine(.F.)

   //====================================================================================================
   // Define as totalizações e quebra por seção.
   //====================================================================================================	
   //TRFunction():New(oSection2:Cell("B1_COD"),NIL,"COUNT",,,,,.F.,.T.)
   _oReport:SetTotalInLine(.F.)
   
//------------------------------------------------------------------------------------------------------------------------------------------
   // "Data de emissão 
   _oSect1_A := TRSection():New(_oReport, "Notas Fiscais de Saída" , {"SF2","SA1"},_aOrder , .F., .T.)
   TRCell():New(_oSect1_A,"F2_EMISSAO"	,"TRBSF2","Data de Emissão","@D",15)
   
   _oSect1_B := TRSection():New(_oReport, "Notas Fiscais de Saída" , {"SF2","SA1"},_aOrder , .F., .T.)
   TRCell():New(_oSect1_B,"F2_CLIENTE"	, "TRBSF2"  ,"Cod.Cliente","@!",11)		
   TRCell():New(_oSect1_B,"F2_LOJA"	    , "TRBSF2"  ,"Loja Cli","@!",8)		
   TRCell():New(_oSect1_B,"A1_NOME" 	, "TRBSF2"  ,"Nome Cliente","@!",40)	

   _oSect1_C := TRSection():New(_oReport, "Notas Fiscais de Saída" , {"SF2","SA1"},_aOrder , .F., .T.)
   TRCell():New(_oSect1_C,"F2_I_CTRA"	, "TRBSF2"  ,"Cod.Transp","@!",8)
   TRCell():New(_oSect1_C,"F2_I_LTRA"	, "TRBSF2"  ,"Loja Transp.","@!",4)
   TRCell():New(_oSect1_C,"A2_NOME"	    , "TRBSF2"  ,"Nome Transportador","@!",40)	

   // "Data de emissão 
   _oSect2_A := TRSection():New(_oSect1_A, "Por Dt.Emissão" , {"SF2","SA1","SA2"}, , .F., .T.)
   TRCell():New(_oSect2_A,"F2_FILIAL"	     , "TRBSF2"  ,"Filial","@!",6)
   TRCell():New(_oSect2_A,"F2_DOC"	         , "TRBSF2"  ,"Nota Fiscal","@!",11)
   TRCell():New(_oSect2_A,"F2_SERIE"	     , "TRBSF2"  ,"Serie","@!",5)		
   TRCell():New(_oSect2_A,"F2_CLIENTE"	     , "TRBSF2"  ,"Cod.Cliente","@!",11)		
   TRCell():New(_oSect2_A,"F2_LOJA"	         , "TRBSF2"  ,"Loja Cli","@!",8)		
   TRCell():New(_oSect2_A,"A1_NOME" 	     , "TRBSF2"  ,"Nome Cliente","@!",40)		
   TRCell():New(_oSect2_A,"F2_I_CTRA"	     , "TRBSF2"  ,"Cod.Transp","@!",10)		
   TRCell():New(_oSect2_A,"F2_I_LTRA"	     , "TRBSF2"  ,"Loja Transp.","@!",10)		
   TRCell():New(_oSect2_A,"A2_NOME"	         , "TRBSF2"  ,"Nome Transportador","@!",40)		
   TRCell():New(_oSect2_A,"WK_TEMPO"         , "TRBSF2"  ,"Tempo Emissão","@!",13)		
   TRCell():New(_oSect2_A,"F2_I_DTRC"	     , "TRBSF2"  ,"Receb.Canhoto","@!",13)		
   TRCell():New(_oSect2_A,"WKOPERCFOP"	     , "TRBSF2"  ,"Oper.CFOP","@!",14)		
   TRCell():New(_oSect2_A,"F2_VALBRUT"       , "TRBSF2"  ,"Valor Total NFE"   ,"@E 999,999,999,999.99",17)   // Vlr.Total da Nota
   TRCell():New(_oSect2_A,"F2_VALMERC"       , "TRBSF2"  ,"Val.Tot.Mercadoria","@E 999,999,999,999.99",17)   // Vlr.Total Mercadoria
//-----------------------------------------------------------------------------------------------------------------------------------
   TRCell():New(_oSect2_A,"WK_TROCANF"	     , "TRBSF2"  ,"Troca NF?","@!",9)
   TRCell():New(_oSect2_A,"WF2_FILIAL"	     , "TRBSF2"  ,"Filial Fat.","@!",6)
   TRCell():New(_oSect2_A,"WF2_DOC"	         , "TRBSF2"  ,"NF Fat","@!",11)
   TRCell():New(_oSect2_A,"WF2_SERIE"	     , "TRBSF2"  ,"Serie Fat","@!",5)		
   TRCell():New(_oSect2_A,"WF2_CLIENT"	     , "TRBSF2"  ,"Cod.Cli.Fat.","@!",12)		
   TRCell():New(_oSect2_A,"WF2_LOJA"	     , "TRBSF2"  ,"Loja Cli","@!",8)		
   TRCell():New(_oSect2_A,"WF2_NOME" 	     , "TRBSF2"  ,"Nome Cliente Fat. ","@!",40)	
   TRCell():New(_oSect2_A,"WF2_I_DTRC" 	     , "TRBSF2"  ,"Data Canhoto ","@!",10)	   
//----------------------------------------------------------------------------------------------------------------------------------
   TRCell():New(_oSect2_A,"WKOPERACAO"       , "TRBSF2"  ,"Operação","@!",33)
   TRCell():New(_oSect2_A,"WKDESCOPER"       , "TRBSF2"  ,"Desc.Operação","@!",33)	    
   TRCell():New(_oSect2_A,"WKREJCLIEN"       , "TRBSF2"  ,"Com Devolução","@!",13)
   TRCell():New(_oSect2_A,"WKNFSEDEX"        , "TRBSF2"  ,"Nota SEDEX","@!",3)   
   TRCell():New(_oSect2_A,"WKTIPFRETE"       , "TRBSF2"  ,"Tipo Frete","@!",22)

   TRCell():New(_oSect2_A,"F2_I_DTOL"	     , "TRBSF2"  ,"Receb.Canhoto Op.Log.","@!",13)		
   TRCell():New(_oSect2_A,"A1_MUN" 	         , "TRBSF2"  ,"Cidade","@!",40)
   TRCell():New(_oSect2_A,"A1_EST" 	         , "TRBSF2"  ,"UF","@!",10)	
   TRCell():New(_oSect2_A,"ZZN_CTRANS" 	   , "TRBSF2"  ,"CTE","@!",40)	
   TRCell():New(_oSect2_A,"BXCTE" 	         , "TRBSF2"  ,"Dt.Baixa","@D",40)		
   _oSect2_A:SetTotalText(" ")
   _oSect2_A:Disable()
   
   // "Cliente"
   _oSect2_B := TRSection():New(_oSect1_B, "Por Cliente" , {"SF2","SA1","SA2"}, , .F., .T.)
   TRCell():New(_oSect2_B,"F2_FILIAL"	     , "TRBSF2"  ,"Filial","@!",6)
   TRCell():New(_oSect2_B,"F2_DOC"	         , "TRBSF2"  ,"Nota Fiscal","@!",11)
   TRCell():New(_oSect2_B,"F2_SERIE"	     , "TRBSF2"  ,"Serie","@!",5)		
   TRCell():New(_oSect2_B,"F2_EMISSAO"	     , "TRBSF2"  ,"Dt.Emissão","@!",10)		
   TRCell():New(_oSect2_B,"F2_I_CTRA"	     , "TRBSF2"  ,"Cod.Transp","@!",10)		
   TRCell():New(_oSect2_B,"F2_I_LTRA"	     , "TRBSF2"  ,"Loja Transp.","@!",10)		
   TRCell():New(_oSect2_B,"A2_NOME"	         , "TRBSF2"  ,"Nome Transportador","@!",40)		
   TRCell():New(_oSect2_B,"WK_TEMPO"         , "TRBSF2"  ,"Tempo Emissão","@!",13)		
   TRCell():New(_oSect2_B,"F2_I_DTRC"	     , "TRBSF2"  ,"Receb.Canhoto","@!",13)		
   TRCell():New(_oSect2_B,"WKOPERCFOP"	     , "TRBSF2"  ,"Oper.CFOP","@!",14)
   TRCell():New(_oSect2_B,"F2_VALBRUT"       , "TRBSF2"  ,"Valor Total NFE"   ,"@E 999,999,999,999.99",17)   // Vlr.Total da Nota
   TRCell():New(_oSect2_B,"F2_VALMERC"       , "TRBSF2"  ,"Val.Tot.Mercadoria","@E 999,999,999,999.99",17)   // Vlr.Total Mercadoria
//-----------------------------------------------------------------------------------------------------------------------------------
   TRCell():New(_oSect2_B,"WK_TROCANF"	     , "TRBSF2"  ,"Troca NF?","@!",9)
   TRCell():New(_oSect2_B,"WF2_FILIAL"	     , "TRBSF2"  ,"Filial Fat.","@!",6)
   TRCell():New(_oSect2_B,"WF2_DOC"	         , "TRBSF2"  ,"NF Fat","@!",11)
   TRCell():New(_oSect2_B,"WF2_SERIE"	     , "TRBSF2"  ,"Serie Fat","@!",5)		
   TRCell():New(_oSect2_B,"WF2_CLIENT"	     , "TRBSF2"  ,"Cod.Cli.Fat.","@!",12)		
   TRCell():New(_oSect2_B,"WF2_LOJA"	     , "TRBSF2"  ,"Loja Cli","@!",8)		
   TRCell():New(_oSect2_B,"WF2_NOME" 	     , "TRBSF2"  ,"Nome Cliente Fat. ","@!",40)
   TRCell():New(_oSect2_B,"WF2_I_DTRC" 	     , "TRBSF2"  ,"Data Canhoto ","@!",10)
//----------------------------------------------------------------------------------------------------------------------------------
   TRCell():New(_oSect2_B,"WKOPERACAO"       , "TRBSF2"  ,"Operação","@!",33)
   TRCell():New(_oSect2_B,"WKDESCOPER"       , "TRBSF2"  ,"Desc.Operação","@!",33)	    
   TRCell():New(_oSect2_B,"WKREJCLIEN"       , "TRBSF2"  ,"Com Devolução","@!",13)
   TRCell():New(_oSect2_B,"WKNFSEDEX"        , "TRBSF2"  ,"Nota SEDEX","@!",3)   
   TRCell():New(_oSect2_B,"WKTIPFRETE"       , "TRBSF2"  ,"Tipo Frete","@!",22)

   TRCell():New(_oSect2_B,"F2_I_DTOL"	     , "TRBSF2"  ,"Receb.Canhoto Op.Log.","@!",13)		
   
   TRCell():New(_oSect2_B,"A1_MUN" 	         , "TRBSF2"  ,"Cidade","@!",40)
   TRCell():New(_oSect2_B,"A1_EST" 	         , "TRBSF2"  ,"UF","@!",10)	
   TRCell():New(_oSect2_B,"ZZN_CTRANS" 	   , "TRBSF2"  ,"CTE","@!",40)	
   TRCell():New(_oSect2_B,"BXCTE" 	         , "TRBSF2"  ,"Dt.Baixa","@D",40)		

   _oSect2_B:SetTotalText(" ") 
   _oSect2_B:Disable()
   
   // "Transportador"
   _oSect2_C:= TRSection():New(_oSect1_C, "Por Transportador" , {"SF2","SA1","SA2"}, , .F., .T.)
   TRCell():New(_oSect2_C,"F2_FILIAL"	     , "TRBSF2"  ,"Filial","@!",6)
   TRCell():New(_oSect2_C,"F2_DOC"	         , "TRBSF2"  ,"Nota Fiscal","@!",11)
   TRCell():New(_oSect2_C,"F2_SERIE"	     , "TRBSF2"  ,"Serie","@!",5)		
   TRCell():New(_oSect2_C,"F2_EMISSAO"	     , "TRBSF2"  ,"Dt.Emissão","@!",10)		
   TRCell():New(_oSect2_C,"F2_CLIENTE"	     , "TRBSF2"  ,"Cod.Cliente","@!",11)		
   TRCell():New(_oSect2_C,"F2_LOJA"	         , "TRBSF2"  ,"Loja Cli","@!",8)		
   TRCell():New(_oSect2_C,"A1_NOME" 	     , "TRBSF2"  ,"Nome Cliente","@!",40)		
   TRCell():New(_oSect2_C,"WK_TEMPO"         , "TRBSF2"  ,"Tempo Emissão","@!",13)		
   TRCell():New(_oSect2_C,"F2_I_DTRC"	     , "TRBSF2"  ,"Receb.Canhoto","@!",13)
   TRCell():New(_oSect2_C,"WKOPERCFOP"	     , "TRBSF2"  ,"Oper.CFOP","@!",14)		
   TRCell():New(_oSect2_C,"F2_VALBRUT"       , "TRBSF2"  ,"Valor Total NFE"   ,"@E 999,999,999,999.99",17)   // Vlr.Total da Nota
   TRCell():New(_oSect2_C,"F2_VALMERC"       , "TRBSF2"  ,"Val.Tot.Mercadoria","@E 999,999,999,999.99",17)   // Vlr.Total Mercadoria
//-----------------------------------------------------------------------------------------------------------------------------------
   TRCell():New(_oSect2_C,"WK_TROCANF"	     , "TRBSF2"  ,"Troca NF?","@!",9)
   TRCell():New(_oSect2_C,"WF2_FILIAL"	     , "TRBSF2"  ,"Filial Fat.","@!",6)
   TRCell():New(_oSect2_C,"WF2_DOC"	         , "TRBSF2"  ,"NF Fat","@!",11)
   TRCell():New(_oSect2_C,"WF2_SERIE"	     , "TRBSF2"  ,"Serie Fat","@!",5)		
   TRCell():New(_oSect2_C,"WF2_CLIENT"	     , "TRBSF2"  ,"Cod.Cli.Fat.","@!",12)		
   TRCell():New(_oSect2_C,"WF2_LOJA"	     , "TRBSF2"  ,"Loja Cli","@!",8)		
   TRCell():New(_oSect2_C,"WF2_NOME" 	     , "TRBSF2"  ,"Nome Cliente Fat. ","@!",40)	
   TRCell():New(_oSect2_C,"WF2_I_DTRC" 	     , "TRBSF2"  ,"Data Canhoto ","@!",10)	 
//----------------------------------------------------------------------------------------------------------------------------------
   TRCell():New(_oSect2_C,"WKOPERACAO"       , "TRBSF2"  ,"Operação","@!",33)
   TRCell():New(_oSect2_C,"WKDESCOPER"       , "TRBSF2"  ,"Desc.Operação","@!",33)	    
   TRCell():New(_oSect2_C,"WKREJCLIEN"       , "TRBSF2"  ,"Com Devolução","@!",13)
   TRCell():New(_oSect2_C,"WKNFSEDEX"        , "TRBSF2"  ,"Nota SEDEX","@!",3)   
   TRCell():New(_oSect2_C,"WKTIPFRETE"       , "TRBSF2"  ,"Tipo Frete","@!",22)
     
   TRCell():New(_oSect2_C,"F2_I_DTOL"	     , "TRBSF2"  ,"Receb.Canhoto Op.Log.","@!",13)

   TRCell():New(_oSect2_C,"A1_MUN" 	         , "TRBSF2"  ,"Cidade","@!",40)
   TRCell():New(_oSect2_C,"A1_EST" 	         , "TRBSF2"  ,"UF","@!",10)		
   TRCell():New(_oSect2_C,"ZZN_CTRANS" 	     , "TRBSF2"  ,"CTE","@!",40)	
   TRCell():New(_oSect2_C,"BXCTE" 	         , "TRBSF2"  ,"Dt.Baixa","@D",40)	

   _oSect2_C:SetTotalText(" ")              
   _oSect2_C:Disable()

End Sequence
					
Return(_oReport)

/*
===============================================================================================================================
Programa----------: ROMS043P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 29/06/2016
Descrição---------: Realiza a impressão do relatório. (ReportPrint)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS043P(_oReport)
Local _cQry       := ""		
//Local _lPrim 	:= .T.	      
Local _cCondicao, _cOperCfop, _cCfops, _aDadosTrNf, _cTrocaNF, _ntotRegs
Local _cDescOper, _cSedex, _cTipoFrete
Local _cValdev

Private _dData, _cCodigo, _cLoja, _cNome

Begin Sequence                    
   //====================================================================================================
   // Ativa a seção do relatório conforme a ordem de emissão do relatório.
   //====================================================================================================	
   _nOrdReport := _oReport:GetOrder()
   
   If _nOrdReport == 1 // "Data de emissão 
      _oSect1_A:Enable() 
      _oSect2_A:Enable() 
   ElseIf _nOrdReport == 2 // "Cliente"
      _oSect1_B:Enable() 
      _oSect2_B:Enable() 
   Else // "Transportador"
      _oSect1_C:Enable() 
      _oSect2_C:Enable() 
   EndIf
    
   //====================================================================================================
   // Monta a query de dados.
   //====================================================================================================	
   _cQry := "SELECT DISTINCT F2_FILIAL, F2_DOC, F2_SERIE, F2_EMISSAO, F2_CLIENTE, F2_LOJA, A1_NOME, A1_MUN, A1_EST, F2_I_CTRA, F2_I_LTRA, A2_NOME, F2_I_DTRC,F2_I_DTOL, F2_VALBRUT, F2_VALMERC, F2_I_PEDID, C5_I_OPER, C5_I_NFSED, C5_TPFRETE "
   _cQry += " , D2_CF, VALORDEV, ZZN_CTRANS, SE2.E2_BAIXA BXCTE, SE2_2.E2_BAIXA BXFATURA" 
   _cQry += " FROM " + RetSqlName("SF2") + " SF2 "
   _cQry += "     JOIN " + RetSqlName("SA1") +" SA1 ON  F2_CLIENTE = A1_COD AND F2_LOJA = A1_LOJA AND SA1.D_E_L_E_T_ = ' '" 
   _cQry += "     JOIN " + RetSqlName("SA2") +" SA2 ON  F2_I_CTRA  = A2_COD AND F2_I_LTRA = A2_LOJA AND SA2.D_E_L_E_T_ = ' '" 
   _cQry += "     JOIN "
   _cQry += "         (SELECT D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA, D2_CF, SUM(D2_VALDEV) VALORDEV FROM " + RetSqlName("SD2") + " SD2B WHERE SD2B.D_E_L_E_T_ = ' ' GROUP BY D2_FILIAL, D2_DOC, D2_SERIE, D2_CLIENTE, D2_LOJA, D2_CF) SUBSD2 "
   _cQry += "          ON D2_FILIAL = F2_FILIAL AND D2_DOC = SF2.F2_DOC AND D2_SERIE = SF2.F2_SERIE AND SUBSD2.D2_FILIAL = SF2.F2_FILIAL AND SUBSD2.D2_DOC = SF2.F2_DOC AND SUBSD2.D2_SERIE = SF2.F2_SERIE AND SUBSD2.D2_CLIENTE = SF2.F2_CLIENTE AND SUBSD2.D2_LOJA = SF2.F2_LOJA "
   _cQry += "     JOIN " + RetSqlName("SC5") +" SC5 ON  F2_CLIENTE = D2_CLIENTE AND F2_LOJA = D2_LOJA AND F2_FILIAL = C5_FILIAL AND F2_I_PEDID = C5_NUM AND SC5.D_E_L_E_T_ = ' ' " 
   _cQry += "     LEFT JOIN " + RetSqlName("ZZN") +" ZZN ON  ZZN.ZZN_FILIAL = SF2.F2_FILIAL AND ZZN.ZZN_NFISCA = SF2.F2_DOC AND ZZN.ZZN_SERIE = SF2.F2_SERIE AND ZZN.D_E_L_E_T_ = ' ' "
   _cQry += "     LEFT JOIN " + RetSqlName("SE2") +" SE2 ON  ZZN_FILIAL = SE2.E2_FILIAL AND ZZN_CTRANS = SE2.E2_NUM AND SE2.E2_PREFIXO = ZZN_SERCTR AND SE2.E2_TIPO = 'NF ' AND ZZN_FTRANS = SE2.E2_FORNECE AND ZZN_LOJAFT = SE2.E2_LOJA AND SE2.D_E_L_E_T_ = ' ' "
   _cQry += "     LEFT JOIN " + RetSqlName("SE2") +" SE2_2 ON SE2.E2_FILIAL = SE2_2.E2_FILIAL AND SE2.E2_FATURA = SE2_2.E2_NUM  AND SE2_2.E2_PREFIXO = 'MAN' AND SE2_2.E2_TIPO = 'FT ' AND  SE2.E2_FORNECE  = SE2_2.E2_FORNECE AND SE2.E2_LOJA = SE2_2.E2_LOJA AND SE2_2.D_E_L_E_T_ = ' ' "
   
   _cQry += " WHERE SF2.D_E_L_E_T_ = ' '   "

   If ! Empty(MV_PAR01) // De Filial  
      _cQry +=  " AND F2_FILIAL IN " + FormatIn(MV_PAR01,";")
   EndIf

   If ! Empty(MV_PAR02) // De Emissao  
      _cQry += " AND F2_EMISSAO >= '"+DToS(MV_PAR02)+"' "
   EndIf
   
   If ! Empty(MV_PAR03) // Até Emissao 
      _cQry += " AND F2_EMISSAO <= '"+DToS(MV_PAR03)+"' "
   EndIf
   
   If ! Empty(MV_PAR04) // De Cliente 
      _cQry += " AND F2_CLIENTE >= '"+MV_PAR04+"' " 
   EndIf
   
   If ! Empty(MV_PAR05) // De Loja   
      _cQry += " AND F2_LOJA  >= '"+MV_PAR05+"' "
   EndIf
   
   If ! Empty(MV_PAR06) // Até Cliente  
      _cQry += " AND F2_CLIENTE <= '"+MV_PAR06+"' "        
   EndIf
   
   If ! Empty(MV_PAR07) // Até Loja  
      _cQry += " AND F2_LOJA  <= '"+MV_PAR07+"' "
   EndIf
   
   If ! Empty(MV_PAR08) // De Transportaodora 
      _cQry += " AND F2_I_CTRA >= '"+MV_PAR08+"' "
   EndIf
   
   If ! Empty(MV_PAR09) // De Loja  
      _cQry += " AND F2_I_LTRA >= '"+MV_PAR09+"' "
   EndIf
   
   If ! Empty(MV_PAR10) // Até Transportaodora  
      _cQry += " AND F2_I_CTRA <= '"+MV_PAR10+"' " 
   EndIf
   
   If ! Empty(MV_PAR11) // Até Loja 
      _cQry += " AND F2_I_LTRA <= '"+MV_PAR11+"' "
   EndIf
   
   If MV_PAR12 == 1  // Imprime Canhoto Recebido?   // Sim 
      _cQry += " AND F2_I_DTRC <> '        ' "
   ElseIf MV_PAR12  == 2 // Não 
      _cQry += " AND F2_I_DTRC = '        ' "
   EndIf               
            
   If ! Empty(MV_PAR13)
      If !("A" $ MV_PAR13 )
		 _cCfops := U_ITCFOPS(MV_PAR13)
		 _cQry +=  " AND D2_CF IN " + FormatIn(_cCfops,";")
	  EndIf 
   EndIf
   
   If _nOrdReport == 1 // Orden de Emiss.: Data de emissão 
      _cQry += " ORDER BY F2_EMISSAO,F2_CLIENTE,F2_LOJA,F2_I_CTRA,F2_I_LTRA " 
   ElseIf _nOrdReport == 2 // Cliente
      _cQry += " ORDER BY F2_CLIENTE,F2_LOJA,F2_EMISSAO,F2_I_CTRA,F2_I_LTRA "
   ElseIf _nOrdReport == 3 // Transportador
      _cQry += " ORDER BY F2_I_CTRA,F2_I_LTRA,F2_EMISSAO,F2_CLIENTE,F2_LOJA "
   EndIf

   If Select("TRBSF2") <> 0
	  TRBSF2->(DBCloseArea())
   EndIf
	
   TCQUERY _cQry NEW ALIAS "TRBSF2"	
   TCSetField('TRBSF2',"F2_EMISSAO","D",8,0)
   TCSetField('TRBSF2',"F2_I_DTRC","D",8,0)
   TCSetField('TRBSF2',"F2_I_DTOL","D",8,0)
   TCSetField('TRBSF2',"BXFATURA","D",8,0)
   TCSetField('TRBSF2',"BXCTE","D",8,0)
      	
   DBSelectArea("TRBSF2")
   TRBSF2->(DBGoTop())

   Count to _ntotRegs	
   _oReport:SetMeter(_ntotRegs)	
   
   TRBSF2->(DBGoTop())
   //====================================================================================================
   // Inicia processo de impressão.
   //====================================================================================================		
   While !TRBSF2->(Eof())
		
      If _oReport:Cancel()
		 Exit
      EndIf
					
      If _nOrdReport == 1
         //====================================================================================================
         // Inicializando a primeira seção
         //====================================================================================================		 
	     _oSect1_A:Init()

	     _oReport:IncMeter()
	          
         //====================================================================================================
         // Imprimindo primeira seção "Data de emissão"
         //====================================================================================================		 
         _dData  := TRBSF2->F2_EMISSAO
         _cCondicao := "(_dData  == TRBSF2->F2_EMISSAO)"
         IncProc("Imprimindo Data Emissão: "+DToC(_dData))
         _oSect1_A:Cell("F2_EMISSAO"):SetValue(TRBSF2->F2_EMISSAO)
		 _oSect1_A:PrintLine()
      ElseIf _nOrdReport == 2   
         //====================================================================================================
         // Inicializando a primeira seção
         //====================================================================================================		 
	     _oSect1_B:Init()

	     _oReport:IncMeter()
         
         //====================================================================================================
         // Imprimindo primeira seção "Cliente"
         //====================================================================================================		 
         _cCodigo := TRBSF2->F2_CLIENTE
         _cLoja   := TRBSF2->F2_LOJA
         _cNome   := TRBSF2->A1_NOME
         _cCondicao := "(_cCodigo+_cLoja+_cNome == TRBSF2->(F2_CLIENTE+F2_LOJA+A1_NOME))"           
         IncProc("Imprimindo Cliente: "+AllTrim(_cCodigo+"-"+_cLoja+"-"+_cNome))
         _oSect1_B:Cell("F2_CLIENTE"):SetValue(TRBSF2->F2_CLIENTE)
		 _oSect1_B:Cell("F2_LOJA"):SetValue(TRBSF2->F2_LOJA)				
		 _oSect1_B:Cell("A1_NOME"):SetValue(TRBSF2->A1_NOME)				
		 _oSect1_B:PrintLine()         
      Else
         //====================================================================================================
         // Inicializando a primeira seção
         //====================================================================================================		 
	     _oSect1_C:Init()

	     _oReport:IncMeter()
          
         //====================================================================================================
         // Imprimindo primeira seção "Transportador"
         //====================================================================================================		 
         _cCodigo := TRBSF2->F2_I_CTRA
         _cLoja   := TRBSF2->F2_I_LTRA
         _cNome   := TRBSF2->A2_NOME  
         _cCondicao := "(_cCodigo+_cLoja+_cNome == TRBSF2->(F2_I_CTRA+F2_I_LTRA+A2_NOME))"
         IncProc("Imprimindo Transportador: "+AllTrim(_cCodigo+"-"+_cLoja+"-"+_cNome))
         // Imprimindo primeira seção
         _oSect1_C:Cell("F2_I_CTRA"):SetValue(TRBSF2->F2_I_CTRA)
		 _oSect1_C:Cell("F2_I_LTRA"):SetValue(TRBSF2->F2_I_LTRA)				
		 _oSect1_C:Cell("A2_NOME"):SetValue(TRBSF2->A2_NOME)				
		 _oSect1_C:PrintLine()         
      EndIf

      //====================================================================================================
      // Inicializando a segunda seção
      //====================================================================================================		 		
	  If _nOrdReport == 1 // "Data de emissão 
         _oSect2_A:init()
      ElseIf _nOrdReport == 2  // "Cliente"
         _oSect2_B:init()
      Else // "Transportador"
         _oSect2_C:init()
      EndIf
	  				
      While &(_cCondicao)
		 _oReport:IncMeter()
		 
		 //====================================================================================================
         // Determina descrição da operação com base no campo C5_I_OPER
         //====================================================================================================		      		
		 _cDescOper := Posicione("ZB4",1,xFilial("ZB4")+TRBSF2->C5_I_OPER,"ZB4_DESCRI")
		 
		 //====================================================================================================
         // Determina se é nota Sedex C5_I_NFSED
         //====================================================================================================		      		
         If TRBSF2->C5_I_NFSED == "S"
		    _cSedex := "SIM"
		 Else
		    _cSedex := "NAO"
		 EndIf
		 
		 //====================================================================================================
         // Determina o tipo de Frete C5_TPFRETE
         //====================================================================================================	
         If TRBSF2->C5_TPFRETE == "C"	      		
		    _cTipoFrete := "CIF"
		 ElseIf TRBSF2->C5_TPFRETE == "F"	      		
		    _cTipoFrete := "FOB"
		 ElseIf TRBSF2->C5_TPFRETE == "T"	      		
		    _cTipoFrete := "POR CONTA TERCEIROS"
		 ElseIf TRBSF2->C5_TPFRETE == "R"	      		
		    _cTipoFrete := "POR CONTA REMETENTE"
		 ElseIf TRBSF2->C5_TPFRETE == "D"	      		
		    _cTipoFrete := "POR CONTA DESTINATARIO"
		 ElseIf TRBSF2->C5_TPFRETE == "S"	      		
		    _cTipoFrete := "SEM FRETE"		    
		 Else   
		    _cTipoFrete := TRBSF2->C5_TPFRETE
		 EndIf            
		             
		 //====================================================================================================
         // Determina o tipo de operação com base na CFOP
         //====================================================================================================		      		
         _cOperCfop := Posicione("ZAY",1,xFilial("ZAY")+TRBSF2->D2_CF,"ZAY_TPOPER")
         If AllTrim(_cOperCfop) == "V" // VENDA
            _cOperCfop := "VENDA"
         ElseIf AllTrim(_cOperCfop) == "T" // TRANSFERENCIA
            _cOperCfop := "TRANSFERENCIA"
         ElseIf AllTrim(_cOperCfop) == "B" // BONIFICACAO
            _cOperCfop := "BONIFICACAO"
         ElseIf AllTrim(_cOperCfop) == "R" // REMESSA
            _cOperCfop := "REMESSA"
         ElseIf AllTrim(_cOperCfop) == "Z" // AMOSTRA 
            _cOperCfop := "AMOSTRA"
         ElseIf AllTrim(_cOperCfop) == "O" // OUTROS
            _cOperCfop := "OUTROS"           
         EndIf 
		 
		 //====================================================================================================
		 // Verifica de o pedido de vendas é do tipo Troca Nota. Caso afirmativo retorna os dados das notas 
		 // ficais vinculadas.
		 //====================================================================================================
		 _aDadosTrNf := ROMS043T(TRBSF2->F2_FILIAL, TRBSF2->F2_I_PEDID) 
		 _cTrocaNF := "NAO"
		 If !Empty(_aDadosTrNf)
		    _cTrocaNF := "SIM"
		 EndIf
		
		 //====================================================================================================
         // Imprimindo SIM/NAO na coluna com devolução. Quando o valor da devolução é maior que zero, "SIM" 
         // houve devolução. Quando For zero, "NAO" houve devolução.
         //====================================================================================================		      		
         _cValdev := "NAO"		
         If TRBSF2->VALORDEV > 0
            _cValdev := "SIM"        
         EndIf
         		 
		 //====================================================================================================
         // Imprimindo segunda seção "Data de emissão"
         //====================================================================================================		      		
         If _nOrdReport == 1 // "Data de emissão             
            _oSect2_A:Cell("F2_FILIAL"):SetValue(TRBSF2->F2_FILIAL)
            _oSect2_A:Cell("F2_DOC"):SetValue(TRBSF2->F2_DOC)
            _oSect2_A:Cell("F2_SERIE"):SetValue(TRBSF2->F2_SERIE)
            _oSect2_A:Cell("F2_CLIENTE"):SetValue(TRBSF2->F2_CLIENTE)
            _oSect2_A:Cell("F2_LOJA"):SetValue(TRBSF2->F2_LOJA)
            _oSect2_A:Cell("A1_NOME"):SetValue(TRBSF2->A1_NOME)
            _oSect2_A:Cell("F2_I_CTRA"):SetValue(TRBSF2->F2_I_CTRA)
            _oSect2_A:Cell("F2_I_LTRA"):SetValue(TRBSF2->F2_I_LTRA)
            _oSect2_A:Cell("A2_NOME"):SetValue(TRBSF2->A2_NOME)
            _oSect2_A:Cell("WK_TEMPO"):SetValue(DATE()-TRBSF2->F2_EMISSAO)
            _oSect2_A:Cell("F2_I_DTRC"):SetValue(TRBSF2->F2_I_DTRC)
            _oSect2_A:Cell("WKOPERCFOP"):SetValue(_cOperCfop)
            _oSect2_A:Cell("F2_VALBRUT"):SetValue(TRBSF2->F2_VALBRUT)// Vlr.Total da Nota
            _oSect2_A:Cell("F2_VALMERC"):SetValue(TRBSF2->F2_VALMERC)// Vlr.Total Mercadoria
            //------------------------------------------------------------------------------
            _oSect2_A:Cell("WK_TROCANF"):SetValue(_cTrocaNF)
            If _cTrocaNF == "SIM"	     
               _oSect2_A:Cell("WF2_FILIAL"):SetValue(_aDadosTrNf[1])	     
               _oSect2_A:Cell("WF2_DOC"):SetValue(_aDadosTrNf[2])	     
               _oSect2_A:Cell("WF2_SERIE"):SetValue(_aDadosTrNf[3])	     	
               _oSect2_A:Cell("WF2_CLIENT"):SetValue(_aDadosTrNf[4])	     		
               _oSect2_A:Cell("WF2_LOJA"):SetValue(_aDadosTrNf[5])	     	
               _oSect2_A:Cell("WF2_NOME"):SetValue(_aDadosTrNf[6]) 
               _oSect2_A:Cell("WF2_I_DTRC"):SetValue(_aDadosTrNf[7]) 
            Else
               _oSect2_A:Cell("WF2_FILIAL"):SetValue("")	     
               _oSect2_A:Cell("WF2_DOC"):SetValue("")	     
               _oSect2_A:Cell("WF2_SERIE"):SetValue("")	     	
               _oSect2_A:Cell("WF2_CLIENT"):SetValue("")	     		
               _oSect2_A:Cell("WF2_LOJA"):SetValue("")	     	
               _oSect2_A:Cell("WF2_NOME"):SetValue("") 
               _oSect2_A:Cell("WF2_I_DTRC"):SetValue("") 
            EndIf
            //-----------------------------------------------------------------------------------------
            _oSect2_A:Cell("WKOPERACAO"):SetValue(TRBSF2->C5_I_OPER) // "Operação"
            _oSect2_A:Cell("WKDESCOPER"):SetValue(_cDescOper) // "Desc.Operação"
            _oSect2_A:Cell("WKREJCLIEN"):SetValue(_cValdev) // "Valor Devoluc." // TRBSF2->VALORDEV
            _oSect2_A:Cell("WKNFSEDEX"):SetValue(_cSedex)  // "Nota SEDEX"
            _oSect2_A:Cell("WKTIPFRETE"):SetValue(_cTipoFrete) // "Tipo Frete"
            _oSect2_A:Cell("F2_I_DTOL"):SetValue(TRBSF2->F2_I_DTOL)

            _oSect2_A:Cell("A1_MUN"):SetValue(TRBSF2->A1_MUN)
            _oSect2_A:Cell("A1_EST"):SetValue(TRBSF2->A1_EST)	
            _oSect2_A:Cell("ZZN_CTRANS"):SetValue(TRBSF2->ZZN_CTRANS)	
            _oSect2_A:Cell("BXCTE"):SetValue(IIf(Empty(TRBSF2->BXCTE),TRBSF2->BXFATURA,TRBSF2->BXCTE))	

            _oSect2_A:PrintLine()
         //====================================================================================================
         // Imprimindo segunda seção "Cliente"
         //====================================================================================================		 
         ElseIf _nOrdReport == 2   // "Cliente"            
            _oSect2_B:Cell("F2_FILIAL"):SetValue(TRBSF2->F2_FILIAL)
            _oSect2_B:Cell("F2_DOC"):SetValue(TRBSF2->F2_DOC)
            _oSect2_B:Cell("F2_SERIE"):SetValue(TRBSF2->F2_SERIE)
            _oSect2_B:Cell("F2_EMISSAO"):SetValue(TRBSF2->F2_EMISSAO)
            _oSect2_B:Cell("F2_I_CTRA"):SetValue(TRBSF2->F2_I_CTRA)
            _oSect2_B:Cell("F2_I_LTRA"):SetValue(TRBSF2->F2_I_LTRA)
            _oSect2_B:Cell("A2_NOME"):SetValue(TRBSF2->A2_NOME)
            _oSect2_B:Cell("WK_TEMPO"):SetValue(DATE()- TRBSF2->F2_EMISSAO)     
            _oSect2_B:Cell("F2_I_DTRC"):SetValue(TRBSF2->F2_I_DTRC)
            _oSect2_B:Cell("WKOPERCFOP"):SetValue(_cOperCfop)
            _oSect2_B:Cell("F2_VALBRUT"):SetValue(TRBSF2->F2_VALBRUT)// Vlr.Total da Nota
            _oSect2_B:Cell("F2_VALMERC"):SetValue(TRBSF2->F2_VALMERC)// Vlr.Total Mercadoria
            //-----------------------------------------------------------------------------------------
            _oSect2_B:Cell("WK_TROCANF"):SetValue(_cTrocaNF)	     
            If _cTrocaNF == "SIM"	     
               _oSect2_B:Cell("WF2_FILIAL"):SetValue(_aDadosTrNf[1])	     
               _oSect2_B:Cell("WF2_DOC"):SetValue(_aDadosTrNf[2])	     
               _oSect2_B:Cell("WF2_SERIE"):SetValue(_aDadosTrNf[3])	     		
               _oSect2_B:Cell("WF2_CLIENT"):SetValue(_aDadosTrNf[4])	     	
               _oSect2_B:Cell("WF2_LOJA"):SetValue(_aDadosTrNf[5])	     		
               _oSect2_B:Cell("WF2_NOME"):SetValue(_aDadosTrNf[6]) 
               _oSect2_B:Cell("WF2_I_DTRC"):SetValue(_aDadosTrNf[7]) 
            Else
               _oSect2_B:Cell("WF2_FILIAL"):SetValue("")	     
               _oSect2_B:Cell("WF2_DOC"):SetValue("")	     
               _oSect2_B:Cell("WF2_SERIE"):SetValue("")	     		
               _oSect2_B:Cell("WF2_CLIENT"):SetValue("")	     	
               _oSect2_B:Cell("WF2_LOJA"):SetValue("")	     		
               _oSect2_B:Cell("WF2_NOME"):SetValue("") 
               _oSect2_B:Cell("WF2_I_DTRC"):SetValue("") 
            EndIf
            //-----------------------------------------------------------------------------------------
            _oSect2_B:Cell("WKOPERACAO"):SetValue(TRBSF2->C5_I_OPER) // "Operação"
            _oSect2_B:Cell("WKDESCOPER"):SetValue(_cDescOper) // "Desc.Operação"
            _oSect2_B:Cell("WKREJCLIEN"):SetValue(_cValdev) // "Valor Devoluc." // TRBSF2->VALORDEV
            _oSect2_B:Cell("WKNFSEDEX"):SetValue(_cSedex)  // "Nota SEDEX"
            _oSect2_B:Cell("WKTIPFRETE"):SetValue(_cTipoFrete) // "Tipo Frete"
            _oSect2_B:Cell("F2_I_DTOL"):SetValue(TRBSF2->F2_I_DTOL)
            
            _oSect2_B:Cell("A1_MUN"):SetValue(TRBSF2->A1_MUN)
            _oSect2_B:Cell("A1_EST"):SetValue(TRBSF2->A1_EST)	
            _oSect2_B:Cell("ZZN_CTRANS"):SetValue(TRBSF2->ZZN_CTRANS)	
            _oSect2_B:Cell("BXCTE"):SetValue(IIf(Empty(TRBSF2->BXCTE),TRBSF2->BXFATURA,TRBSF2->BXCTE))	

            _oSect2_B:PrintLine()
         //====================================================================================================
         // Imprimindo segunda seção "Transportador"
         //====================================================================================================		 
         Else // "Transportador"             
            _oSect2_C:Cell("F2_FILIAL"):SetValue(TRBSF2->F2_FILIAL)
            _oSect2_C:Cell("F2_DOC"):SetValue(TRBSF2->F2_DOC)
            _oSect2_C:Cell("F2_SERIE"):SetValue(TRBSF2->F2_SERIE)     
            _oSect2_C:Cell("F2_EMISSAO"):SetValue(TRBSF2->F2_EMISSAO)
            _oSect2_C:Cell("F2_CLIENTE"):SetValue(TRBSF2->F2_CLIENTE)
            _oSect2_C:Cell("F2_LOJA"):SetValue(TRBSF2->F2_LOJA)
            _oSect2_C:Cell("A1_NOME"):SetValue(TRBSF2->A1_NOME)     
            _oSect2_C:Cell("WK_TEMPO"):SetValue(Date() - TRBSF2->F2_EMISSAO)
            _oSect2_C:Cell("F2_I_DTRC"):SetValue(TRBSF2->F2_I_DTRC)
            _oSect2_C:Cell("WKOPERCFOP"):SetValue(_cOperCfop)
            _oSect2_C:Cell("F2_VALBRUT"):SetValue(TRBSF2->F2_VALBRUT)// Vlr.Total da Nota
            _oSect2_C:Cell("F2_VALMERC"):SetValue(TRBSF2->F2_VALMERC)// Vlr.Total Mercadoria
            //-----------------------------------------------------------------------------------
            _oSect2_C:Cell("WK_TROCANF"):SetValue(_cTrocaNF)	     
            If _cTrocaNF == "SIM"	     
               _oSect2_C:Cell("WF2_FILIAL"):SetValue(_aDadosTrNf[1])	     
               _oSect2_C:Cell("WF2_DOC"):SetValue(_aDadosTrNf[2])	     
               _oSect2_C:Cell("WF2_SERIE"):SetValue(_aDadosTrNf[3])	     		
               _oSect2_C:Cell("WF2_CLIENT"):SetValue(_aDadosTrNf[4])	     		
               _oSect2_C:Cell("WF2_LOJA"):SetValue(_aDadosTrNf[5])	     	
               _oSect2_C:Cell("WF2_NOME"):SetValue(_aDadosTrNf[6]) 
               _oSect2_C:Cell("WF2_I_DTRC"):SetValue(_aDadosTrNf[7]) 
            Else
               _oSect2_C:Cell("WF2_FILIAL"):SetValue("")	     
               _oSect2_C:Cell("WF2_DOC"):SetValue("")	     
               _oSect2_C:Cell("WF2_SERIE"):SetValue("")	     		
               _oSect2_C:Cell("WF2_CLIENT"):SetValue("")	     		
               _oSect2_C:Cell("WF2_LOJA"):SetValue("")	     	
               _oSect2_C:Cell("WF2_NOME"):SetValue("") 
               _oSect2_C:Cell("WF2_I_DTRC"):SetValue("") 
            EndIf
            //-----------------------------------------------------------------------------------------
            _oSect2_C:Cell("WKOPERACAO"):SetValue(TRBSF2->C5_I_OPER) // "Operação"
            _oSect2_C:Cell("WKDESCOPER"):SetValue(_cDescOper) // "Desc.Operação"
            _oSect2_C:Cell("WKREJCLIEN"):SetValue(_cValdev) // "Valor Devoluc." // TRBSF2->VALORDEV
            _oSect2_C:Cell("WKNFSEDEX"):SetValue(_cSedex)  // "Nota SEDEX"
            _oSect2_C:Cell("WKTIPFRETE"):SetValue(_cTipoFrete) // "Tipo Frete"
            _oSect2_C:Cell("F2_I_DTOL"):SetValue(TRBSF2->F2_I_DTOL)
            
            _oSect2_C:Cell("A1_MUN"):SetValue(TRBSF2->A1_MUN) 
            _oSect2_C:Cell("A1_EST"):SetValue(TRBSF2->A1_EST) 
            _oSect2_C:Cell("ZZN_CTRANS"):SetValue(TRBSF2->ZZN_CTRANS)	
            _oSect2_C:Cell("BXCTE"):SetValue(IIf(Empty(TRBSF2->BXCTE),TRBSF2->BXFATURA,TRBSF2->BXCTE))	
            
            _oSect2_C:PrintLine()
         EndIf     
         
         TRBSF2->(DBSkip())
      EndDo		
      
      If _nOrdReport == 1 // "Data de emissão 
 	     //====================================================================================================
         // Finaliza segunda seção.
         //====================================================================================================	
 	     _oSect2_A:Finish()
 	     //====================================================================================================
         // Imprime linha separadora.
         //====================================================================================================	
 	     _oReport:ThinLine()
 	     //====================================================================================================
         // Finaliza primeira seção.
         //====================================================================================================	 	  
	     _oSect1_A:Finish()
	     
      ElseIf _nOrdReport == 2  // "Cliente"
         //====================================================================================================
         // Finaliza segunda seção.
         //====================================================================================================	
 	     _oSect2_B:Finish()
 	     //====================================================================================================
         // Imprime linha separadora.
         //====================================================================================================	
 	     _oReport:ThinLine()
 	     //====================================================================================================
         // Finaliza primeira seção.
         //====================================================================================================	 	  
	     _oSect1_B:Finish() 
      Else // "Transportador"
         //====================================================================================================
         // Finaliza segunda seção.
         //====================================================================================================	
 	     _oSect2_C:Finish()
 	     //====================================================================================================
         // Imprime linha separadora.
         //====================================================================================================	
 	     _oReport:ThinLine()
 	     //====================================================================================================
         // Finaliza primeira seção.
         //====================================================================================================	 	  
	     _oSect1_C:Finish()
      EndIf
      
   EndDo     

End Sequence

Return

/*
===============================================================================================================================
Programa----------: ROMS043T
Autor-------------: Julio de Paula Paz
Data da Criacao---: 05/07/2018
Descrição---------: Verifica se um pedido de vendas é do tipo troca nota. Caso afirmativo retorna os dados das notas fiscais
                    vinculadas.
Parametros--------: _cCodFilial == Codigo da filial.
                    _cNrPedido  == Numero do pedido de vendas.
Retorno-----------: _aRet = dados das notas fiscais vinculdas ao pedido troca nf.
===============================================================================================================================
*/
Static Function ROMS043T(_cCodFilial, _cNrPedido)
Local _aRet := {}
Local _aOrd := SaveOrd({"SF2","SC5"})

Begin Sequence
   // F2_FILIAL+F2_I_PEDID > K = 20
   SF2->(DBSetOrder(20))
   SC5->(DBSetOrder(1))
   If SC5->(DBSeek(_cCodFilial + _cNrPedido))
      If SC5->C5_I_TRCNF == "S" // É troca nota?
         If SF2->(DBSeek(SC5->C5_I_FILFT + SC5->C5_I_PDFT))
            _aRet := { SC5->C5_I_FILFT,;    // 1
                       SF2->F2_DOC,;        // 2
                       SF2->F2_SERIE,;      // 3
                       SF2->F2_CLIENTE,;    // 4
                       SF2->F2_LOJA,;       // 5
                       Posicione("SA1",1,xFilial("SA1")+SF2->F2_CLIENTE+SF2->F2_LOJA,"A1_NOME"),;  // SF2->F2_I_NCLIE,;    // 6
                       SF2->F2_I_DTRC}      // 7
                  
         EndIf
      EndIf
   EndIf

End Sequence

RestOrd(_aOrd)

Return _aRet
