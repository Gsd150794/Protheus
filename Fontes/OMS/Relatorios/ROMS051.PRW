/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves | 12/12/2023 | Chamado 45764. Adição do campo Peso Bruto no Relatório
Julio Paz     | 19/08/2024 | Chamado 47782. Inclusão de novo campo para informar o tipo de averbação de carga..
Lucas Borges  | 22/04/2025 | Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "report.ch"
#Include 'TOPCONN.CH'

/*
===============================================================================================================================
Programa----------: ROMS051
Autor-------------: Julio de Paula Paz
Data da Criacao---: 11/05/2018
Descrição---------: Relatório CTE versus Notas Fiscais. Chamado 24800.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS051()
Local _oReport := nil
Private _aOrder := {"Data de Digitação"}
Private _oSect1_A := Nil
Private _oSect2_A := Nil
Private _oSect1_S := Nil
Private _oSect2_S := Nil
Private _cArqCTE

Begin Sequence	
   //====================================================================================================
   // Gera a pergunta de modo oculto, ficando disponível no botão ações relacionadas
   //====================================================================================================
   Pergunte("ROMS051",.F.)	          

   //====================================================================================================
   // Chama a montagem do relatório.
   //====================================================================================================	
   _oReport := ROMS051D("ROMS051")
   _oReport:PrintDialog()

End Sequence

//================================================================================
// Fecha e exclui as tabelas temporárias
//================================================================================                    
If Select("TRBCTE") > 0  
   TRBCTE->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Programa----------: ROMS051D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 11/05/2018
Descrição---------: Realiza as definições do relatório. (ReportDef)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS051D(_cNome)
Local _oReport := Nil

Begin Sequence	
   _oReport := TReport():New(_cNome,"Relatório CTE X Notas Fiscais de Saída ou Entrada",_cNome,{|_oReport| ROMS051P(_oReport)},"Emissão do Relatório CTE X Notas Fiscais de Saída ou Entrada")
   _oReport:SetLandscape()    
   _oReport:SetTotalInLine(.F.)

   //====================================================================================================
   // Define as totalizações e quebra por seção.
   //====================================================================================================	
   _oReport:SetTotalInLine(.F.)
   
   //====================================================================================================
   // Definições do Relatório Analítico.
   //====================================================================================================	
   // "Data de digitação 
   _oSect1_A := TRSection():New(_oReport, "CTE X NFs - Analítico"  , {"TRBCTE"},_aOrder , .F., .T.)
   
   // "Data de digitação 
   _oSect2_A := TRSection():New(_oSect1_A, "CTE X NFs - Analítico" , {"TRBCTE"}, , .F., .T.)
   //------------------------------------------------------------------------------------------------------------------------
   TRCell():New(_oSect2_A,"F1_FILIAL" , "TRBCTE"  ,"Filial"           ,"@!",6)                       // Filial
   TRCell():New(_oSect2_A,"F1_DTDIGIT", "TRBCTE"  ,"Dt.Digitação"     ,"@D",12)                      // DT Digitação
   TRCell():New(_oSect2_A,"F1_EMISSAO", "TRBCTE"  ,"Dt.Emissão"       ,"@D",11)                      // DT Emissao
   TRCell():New(_oSect2_A,"F1_ESPECIE", "TRBCTE"  ,"Especie Doc."     ,"@!",40)                      // Especie Documento 
   TRCell():New(_oSect2_A,"F1_DOC"    , "TRBCTE"  ,"Doc. CTE"  		  ,"@!",11)                      // Documento
   TRCell():New(_oSect2_A,"F1_SERIE"  , "TRBCTE"  ,"Serie Doc.E."     ,"@!",11)                      // Serie
   TRCell():New(_oSect2_A,"D1_CF"     , "TRBCTE"  ,"CF CTE"     ,"@!",10)                            // Cod. Fiscal    
   TRCell():New(_oSect2_A,"A2_CGC"    , "TRBCTE"  ,"CNPJ Transport."  ,"@R! NN.NNN.NNN/NNNN-99",17)   // CNPJ do Transportado
   TRCell():New(_oSect2_A,"A2_NOME"   , "TRBCTE"  ,"Transportador"    ,"@!",40)                      // Transportador
   TRCell():New(_oSect2_A,"F1_VALBRUT", "TRBCTE"  ,"Valor Total"      ,"@E 999,999,999,999.99",17)   // Vlr.Total
   TRCell():New(_oSect2_A,"FT_CSTPIS" , "TRBCTE"  ,"Sit.Trib.PIS"     ,"@!",12)                      // Sit.Trib.PIS
   TRCell():New(_oSect2_A,"FT_CSTCOF" , "TRBCTE"  ,"Sit.Trib.COFINS"  ,"@!",12)                      // Sit.Trib.COFINS
   TRCell():New(_oSect2_A,"F1_CHVNFE" , "TRBCTE"  ,"Chave CTE"        ,"@!",40)                      // Chave 
   TRCell():New(_oSect2_A,"F1_PBRUTO",  "TRBCTE"  ,"Peso Bruto"      ,"@E 999,999,999,999.9999",17)   // Peso Bruto
   //===================================================================================================
   // Amarrado com a respectiva Nota Fiscal Transportada, que devera conter os seguintes dados:
   //===================================================================================================
   TRCell():New(_oSect2_A,"F2_DOC"    , "TRBCTE"  ,"Doc. NF"          ,"@!",10)                      // Documento
   TRCell():New(_oSect2_A,"F2_SERIE"  , "TRBCTE"  ,"Serie Doc.S."     ,"@!",11)                      // Serie
   TRCell():New(_oSect2_A,"F2_VALBRUT", "TRBCTE"  ,"Valor Total NFE"  ,"@E 999,999,999,999.99",17)   // Vlr.Total da Nota
   TRCell():New(_oSect2_A,"F2_VALMERC", "TRBCTE" ,"Val.Tot.Mercadoria","@E 999,999,999,999.99",17)   // Vlr.Total Mercadoria
   TRCell():New(_oSect2_A,"F2_EMISSAO", "TRBCTE"  ,"Dt.Emis.NFE"      ,"@D",11)                      // DT Emissão
   TRCell():New(_oSect2_A,"D2_CF"     , "TRBCTE"  ,"CF NFE"     ,"@!",10)                            // Cod. Fiscal
   TRCell():New(_oSect2_A,"F2_CLIENTE", "TRBCTE"  ,"CNPJ/CPF" ,"@R! NN.NNN.NNN/NNNN-99",17)   // CNPJ/CPF Cliente
   TRCell():New(_oSect2_A,"B1_DESC"   , "TRBCTE"  ,"Descrição Produto","@!",30)                      // Descrição Produto
   TRCell():New(_oSect2_A,"B1_POSIPI" , "TRBCTE"  ,"NCM"              ,"@!",11)                      // NCM
   TRCell():New(_oSect2_A,"FT2_CSTPIS", "TRBCTE"  ,"Sit.T.PIS NFE"    ,"@!",11)                      // Sit.Trib.PIS
   TRCell():New(_oSect2_A,"FT2_CSTCOF", "TRBCTE"  ,"Sit.T.COFINS NFE" ,"@!",14)                      // Sit.Trib.COFINS
   TRCell():New(_oSect2_A,"F2_CHVNFE" , "TRBCTE"  ,"Chave NFE"         ,"@!",40)                     // Chave Nfe
   //----------------------------
   TRCell():New(_oSect2_A,"A2_I_TPAVE", "TRBCTE"  ,"Tipo Averb.Carga"  ,"@!",20)                     // Tipo Averbação de Carga

   _oSect2_A:SetTotalText(" ")
   _oSect2_A:Disable()

   //====================================================================================================
   // Definições do Relatório Sintético.
   //====================================================================================================	
   // "Data de digitação 
   _oSect1_S := TRSection():New(_oReport, "CTE X NFs - Sintetico"  , {"TRBCTE"},_aOrder , .F., .T.)
   //TRCell():New(_oSect1_A,"F1_DTDIGIT"	,"TRBCTE","Data de Digitação","@D",15)
   
   // "Data de digitação 
   _oSect2_S := TRSection():New(_oSect1_S, "CTE X NFs - Sintetico" , {"TRBCTE"}, , .F., .T.)
   //------------------------------------------------------------------------------------------------------------------------
   TRCell():New(_oSect2_S,"F1_FILIAL" , "TRBCTE"  ,"Filial"           ,"@!",6)                       // Filial
   TRCell():New(_oSect2_S,"F1_DTDIGIT", "TRBCTE"  ,"Dt.Digitação"     ,"@D",12)                      // DT Digitação
   TRCell():New(_oSect2_S,"F1_EMISSAO", "TRBCTE"  ,"Dt.Emissão"       ,"@D",11)                      // DT Emissao
   TRCell():New(_oSect2_S,"F1_ESPECIE", "TRBCTE"  ,"Especie Doc."     ,"@!",40)                      // Especie Documento 
   TRCell():New(_oSect2_S,"F1_DOC"    , "TRBCTE"  ,"Doc. CTE"	      ,"@!",11)                      // Documento
   TRCell():New(_oSect2_S,"F1_SERIE"  , "TRBCTE"  ,"Serie Doc.E."     ,"@!",11)                      // Serie
   TRCell():New(_oSect2_S,"D1_CF"     , "TRBCTE"  ,"CF CTE"     ,"@!",10)                            // Cod. Fiscal    
   TRCell():New(_oSect2_S,"A2_CGC"    , "TRBCTE"  ,"CNPJ Transport."  ,"@R! NN.NNN.NNN/NNNN-99",17)   // CNPJ do Transportado
   TRCell():New(_oSect2_S,"A2_NOME"   , "TRBCTE"  ,"Transportador"    ,"@!",40)                      // Transportador
   TRCell():New(_oSect2_S,"F1_VALBRUT", "TRBCTE"  ,"Valor Total"      ,"@E 999,999,999,999.99",17)   // Vlr.Total
   TRCell():New(_oSect2_S,"FT_CSTPIS" , "TRBCTE"  ,"Sit.Trib.PIS"     ,"@!",12)                      // Sit.Trib.PIS
   TRCell():New(_oSect2_S,"FT_CSTCOF" , "TRBCTE"  ,"Sit.Trib.COFINS"  ,"@!",12)                      // Sit.Trib.COFINS
   TRCell():New(_oSect2_S,"F1_CHVNFE" , "TRBCTE"  ,"Chave CTE"        ,"@!",40)                      // Chave 
   TRCell():New(_oSect2_S,"F1_PBRUTO",  "TRBCTE"  ,"Peso Bruto"      ,"@E 999,999,999,999.9999",17)   // Peso Bruto
   //===================================================================================================
   // Amarrado com a respectiva Nota Fiscal Transportada, que devera conter os seguintes dados:
   //===================================================================================================
   TRCell():New(_oSect2_S,"F2_DOC"    , "TRBCTE"  ,"Doc. NF"          ,"@!",10)                      // Documento
   TRCell():New(_oSect2_S,"F2_SERIE"  , "TRBCTE"  ,"Serie Doc.S."     ,"@!",11)                      // Serie
   TRCell():New(_oSect2_S,"F2_VALBRUT", "TRBCTE"  ,"Valor Total NFE"  ,"@E 999,999,999,999.99",17)   // Vlr.Total da Nota
   TRCell():New(_oSect2_S,"F2_VALMERC", "TRBCTE"  ,"Val.Tot.Mercadoria","@E 999,999,999,999.99",17)  // Vlr.Total Mercadoria
   TRCell():New(_oSect2_S,"F2_EMISSAO", "TRBCTE"  ,"Dt.Emis.NFE"      ,"@D",11)                      // DT Emissão
   TRCell():New(_oSect2_S,"F2_CLIENTE", "TRBCTE"  ,"CNPJ/CPF" ,"@R! NN.NNN.NNN/NNNN-99",17)           // CNPJ/CPF Cliente
   TRCell():New(_oSect2_S,"F2_CHVNFE" , "TRBCTE"  ,"Chave NFE"         ,"@!",40)                     // Chave Nfe
   //------------------------ 
   TRCell():New(_oSect2_S,"A2_I_TPAVE", "TRBCTE"  ,"Tipo Averb.Carga"  ,"@!",20)                     // Tipo Averbação de Carga 


   _oSect2_S:SetTotalText(" ")
   _oSect2_S:Disable()
   
End Sequence
					
Return(_oReport)

/*
===============================================================================================================================
Programa----------: ROMS051P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 11/05/2018
Descrição---------: Realiza a impressão do relatório. (ReportPrint)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS051P(_oReport)

Local _lRet
Local oproc
Local _cTpAverb := ""


Begin Sequence                    
   //====================================================================================================
   // Ativa a seção do relatório conforme a ordem de emissão do relatório.
   //====================================================================================================	
   
   If MV_PAR04 == 1 // Relatório Sintético 
      _oSect1_S:Enable() 
      _oSect2_S:Enable() 
   Else // Relatório Analitico
      _oSect1_A:Enable() 
      _oSect2_A:Enable() 
   EndIf
   If MV_PAR05 = 1//Saida
      _oReport:SetTitle( _oReport:Title()+" - Saida")
   Else
      _oReport:SetTitle( _oReport:Title()+" - Entrada")
   EndIf
   
   FWMsgRun( ,{|oproc|  _lRet := ROMS051E(oproc) } , 'Aguarde!' , 'Lendo dados do relatório...' )
   If ! _lRet // ROMS051E()
      Break
   EndIf

   DBSelectArea("TRBCTE")
   TRBCTE->(DBGoTop())
	
   _oReport:SetMeter(TRBCTE->(LastRec()))	

   //====================================================================================================
   // Inicia processo de impressão.
   //====================================================================================================		
   While !TRBCTE->(Eof())
		
      If _oReport:Cancel()
		 Exit
      EndIf
					
      //====================================================================================================
      // Inicializando a primeira seção
      //====================================================================================================
      If MV_PAR04 == 1 // Relatório Sintético 		 
	     _oSect1_S:Init()
	  Else // Relatório Analítico
	     _oSect1_A:Init()
	  EndIf

	  _oReport:IncMeter()
	          
      //====================================================================================================
      // Inicializando a segunda seção
      //====================================================================================================		 		
	  
	  // "Data de digitação 
	  If MV_PAR04 == 1 // Relatório Sintético
         _oSect2_S:init()
      Else // Relatório Analítico
         _oSect2_A:init()
      EndIf
	  				
      While TRBCTE->(!Eof()) // &(_cCondicao)

         _cTpAverb := ""
         If TRBCTE->A2_I_TPAVE == "T"
            _cTpAverb := "TRANSPORTADOR" 
         ElseIf TRBCTE->A2_I_TPAVE == "E"
            _cTpAverb := "EMBARCADOR" 
         EndIf

		   //====================================================================================================
         // Imprimindo segunda seção "Data de digitação"
         //====================================================================================================		      		
         If MV_PAR04 == 1 // Relatório Sintético
            _oSect2_S:Cell("F1_FILIAL"):SetValue(TRBCTE->F1_FILIAL)          // Filial
            _oSect2_S:Cell("F1_DTDIGIT"):SetValue(TRBCTE->F1_DTDIGIT)        // DT Digitação
            _oSect2_S:Cell("F1_EMISSAO"):SetValue(TRBCTE->F1_EMISSAO)        // DT Emissao
            _oSect2_S:Cell("F1_DOC"):SetValue(TRBCTE->F1_DOC)                // Documento
            _oSect2_S:Cell("F1_SERIE"):SetValue(TRBCTE->F1_SERIE)            // Serie
            _oSect2_S:Cell("D1_CF"):SetValue(TRBCTE->D1_CF)                  // Cod. Fiscal    
            _oSect2_S:Cell("A2_CGC"):SetValue(TRBCTE->A2_CGC)                // CNPJ do Transportado
            _oSect2_S:Cell("A2_NOME"):SetValue(TRBCTE->A2_NOME)              // Transportador
            _oSect2_S:Cell("F1_VALBRUT"):SetValue(TRBCTE->F1_VALBRUT)        // Vlr.Total
            _oSect2_S:Cell("FT_CSTPIS"):SetValue(TRBCTE->FT_CSTPIS)          // Sit.Trib.PIS
            _oSect2_S:Cell("FT_CSTCOF"):SetValue(TRBCTE->FT_CSTCOF)          // Sit.Trib.COFINS
            _oSect2_S:Cell("F1_CHVNFE"):SetValue(TRBCTE->F1_CHVNFE)          // Chave 
            _oSect2_S:Cell("F1_ESPECIE"):SetValue(TRBCTE->F1_ESPECIE)        // Especie Documento 
            _oSect2_S:Cell("F1_PBRUTO"):SetValue(TRBCTE->F1_PBRUTO)         // Peso Bruto
            //===================================================================================================
            // Amarrado com a respectiva Nota Fiscal Transportada, que devera conter os seguintes dados:
            //===================================================================================================
            _oSect2_S:Cell("F2_DOC"):SetValue(TRBCTE->F2_DOC)                 // Documento
            _oSect2_S:Cell("F2_SERIE"):SetValue(TRBCTE->F2_SERIE)             // Serie
            _oSect2_S:Cell("F2_VALBRUT"):SetValue(TRBCTE->F2_VALBRUT)         // Vlr.Total da Nota
            _oSect2_S:Cell("F2_EMISSAO"):SetValue(TRBCTE->F2_EMISSAO)         // DT Emissão
            _oSect2_S:Cell("F2_CLIENTE"):SetValue(TRBCTE->F2_CLIENTE)         // CNPJ/CPF Cliente
            _oSect2_S:Cell("F2_VALMERC"):SetValue(TRBCTE->F2_VALMERC)         // Vlr.Total Mercadoria
            _oSect2_S:Cell("F2_CHVNFE"):SetValue(TRBCTE->F2_CHVNFE)           // Chave Nfe
            _oSect2_S:Cell("A2_I_TPAVE"):SetValue(_cTpAverb)                  // Tipo de Averbação de Carga 
            
            _oSect2_S:SetTotalText(" ")
            _oSect2_S:PrintLine()
         Else // Relatório Analítico    
            _oSect2_A:Cell("F1_FILIAL"):SetValue(TRBCTE->F1_FILIAL)          // Filial
            _oSect2_A:Cell("F1_DTDIGIT"):SetValue(TRBCTE->F1_DTDIGIT)      // DT Digitação
            _oSect2_A:Cell("F1_EMISSAO"):SetValue(TRBCTE->F1_EMISSAO)        // DT Emissao
            _oSect2_A:Cell("F1_DOC"):SetValue(TRBCTE->F1_DOC)                // Documento
            _oSect2_A:Cell("F1_SERIE"):SetValue(TRBCTE->F1_SERIE)            // Serie
            _oSect2_A:Cell("D1_CF"):SetValue(TRBCTE->D1_CF)                  // Cod. Fiscal    
            _oSect2_A:Cell("A2_CGC"):SetValue(TRBCTE->A2_CGC)                // CNPJ do Transportado
            _oSect2_A:Cell("A2_NOME"):SetValue(TRBCTE->A2_NOME)              // Transportador
            _oSect2_A:Cell("F1_VALBRUT"):SetValue(TRBCTE->F1_VALBRUT)        // Vlr.Total
            _oSect2_A:Cell("FT_CSTPIS"):SetValue(TRBCTE->FT_CSTPIS)          // Sit.Trib.PIS
            _oSect2_A:Cell("FT_CSTCOF"):SetValue(TRBCTE->FT_CSTCOF)          // Sit.Trib.COFINS
            _oSect2_A:Cell("F1_CHVNFE"):SetValue(TRBCTE->F1_CHVNFE)          // Chave 
            _oSect2_A:Cell("F1_PBRUTO"):SetValue(TRBCTE->F1_PBRUTO)           // Peso Bruto
            _oSect2_A:Cell("F1_ESPECIE"):SetValue(TRBCTE->F1_ESPECIE)        // Especie Documento 
            //===================================================================================================
            // Amarrado com a respectiva Nota Fiscal Transportada, que devera conter os seguintes dados:
            //===================================================================================================
            _oSect2_A:Cell("F2_DOC"):SetValue(TRBCTE->F2_DOC)                 // Documento
            _oSect2_A:Cell("F2_SERIE"):SetValue(TRBCTE->F2_SERIE)             // Serie
            _oSect2_A:Cell("F2_VALBRUT"):SetValue(TRBCTE->F2_VALBRUT)         // Vlr.Total da Nota
            _oSect2_A:Cell("F2_EMISSAO"):SetValue(TRBCTE->F2_EMISSAO)         // DT Emissão
            _oSect2_A:Cell("D2_CF"):SetValue(TRBCTE->D2_CF)                   // Cod. Fiscal
            _oSect2_A:Cell("F2_CLIENTE"):SetValue(TRBCTE->F2_CLIENTE)         // CNPJ/CPF Cliente
            _oSect2_A:Cell("B1_DESC"):SetValue(TRBCTE->B1_DESC)               // Descrição Produto
            _oSect2_A:Cell("B1_POSIPI"):SetValue(TRBCTE->B1_POSIPI)           // NCM
            _oSect2_A:Cell("FT2_CSTPIS"):SetValue(TRBCTE->FT2_CSTPIS)         // Sit.Trib.PIS
            _oSect2_A:Cell("FT2_CSTCOF"):SetValue(TRBCTE->FT2_CSTCOF)         // Sit.Trib.COFINS
            _oSect2_A:Cell("F2_VALMERC"):SetValue(TRBCTE->F2_VALMERC)         // Vlr.Total Mercadoria
            _oSect2_A:Cell("F2_CHVNFE"):SetValue(TRBCTE->F2_CHVNFE)           // Chave Nfe
            _oSect2_A:Cell("A2_I_TPAVE"):SetValue(_cTpAverb)                  // Tipo de Averbação de Carga 

            _oSect2_A:SetTotalText(" ")
            _oSect2_A:PrintLine()
         EndIf

         TRBCTE->(DBSkip())
      EndDo		
 	  //====================================================================================================
      // Finaliza segunda seção.
      //====================================================================================================	
      If MV_PAR04 == 1 // Relatório Sintético
 	     _oSect2_S:Finish()
 	  Else // Relatório Analitico
 	     _oSect2_A:Finish()
 	  EndIf
 	  
 	  //====================================================================================================
      // Imprime linha separadora.
      //====================================================================================================	
 	  _oReport:ThinLine()
 	  //====================================================================================================
      // Finaliza primeira seção.
      //====================================================================================================	 	  
      If MV_PAR04 == 1 // Relatório Sintético
	     _oSect1_S:Finish()
	  Else // Relatório Analitico
	     _oSect1_A:Finish()
	  EndIf
      
   EndDo     

End Sequence

If Select("TRBCTE") > 0
   TRBCTE->( DBCloseArea() )
EndIf


Return

/*
===============================================================================================================================
Programa----------: ROMS051E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 11/05/2018
Descrição---------: Gera os dados para a emissão do relatório.
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS051E(oproc)
Local _aStructCTE := {}
Local _lRet := .T.
Local _nTotRegs
Local _aDadosXML
Local _nI
Local _aDadosTrib
Local _cD1_CF      := ""   
Local _cF4_CSTPIS  := "" 
Local _cF4_CSTCOF  := "" 
Local _nni := 1
Local _cQry       := ""
Private _otemp := nil

Begin Sequence
   //================================================================================
   // Cria as estruturas das tabelas temporárias
   //================================================================================
   aAdd(_aStructCTE,{"F1_FILIAL" ,"C", 2,0})                                             // Filial
   aAdd(_aStructCTE,{"F1_DTDIGIT","D", 8,0})                                             // DT Digitação
   aAdd(_aStructCTE,{"F1_EMISSAO","D", 8 , 0})                                           // DT Emissao
   aAdd(_aStructCTE,{"F1_DOC"    ,"C", TamSX3("F1_DOC")[1]  , 0})                        // Documento
   aAdd(_aStructCTE,{"F1_SERIE"  ,"C", TamSX3("F1_SERIE")[1], 0})                        // Serie
   aAdd(_aStructCTE,{"D1_CF"     ,"C", 40, 0})                                           // Cod. Fiscal    
   aAdd(_aStructCTE,{"A2_CGC"    ,"C", TamSX3("A2_CGC")[1]  , 0})                        // -> F1_FORNECE + F1_LOJA // CNPJ do Transportado
   aAdd(_aStructCTE,{"A2_NOME"   ,"C", TamSX3("A2_NOME")[1] , 0})                        // Transportador
   aAdd(_aStructCTE,{"M0_CGC"    ,"C", TamSX3("A2_CGC")[1]  , 0})                        //  cnpj da filial = F1_FILIAL // CNPJ Estabelecimento que deu saída à mercadoria
   aAdd(_aStructCTE,{"F1_VALBRUT","N", TamSX3("F1_VALBRUT")[1],TamSX3("F1_VALBRUT")[2]}) // Vlr.Total
   aAdd(_aStructCTE,{"FT_CSTPIS" ,"C", 40 , 0})                                          // Sit.Trib.PIS
   aAdd(_aStructCTE,{"FT_CSTCOF" ,"C", 40 , 0})                                          // Sit.Trib.COFINS
   aAdd(_aStructCTE,{"F1_CHVNFE" ,"C", TamSX3("F1_CHVNFE")[1] , 0})                      // Chave 
   aAdd(_aStructCTE,{"F1_ESPECIE","C", TamSX3("F1_ESPECIE")[1] , 0})                     // Chave 
   aAdd(_aStructCTE,{"F1_PBRUTO", "N", TamSX3("F1_PBRUTO")[1] , 0})                     // Peso Bruto 

   //===================================================================================================
   // Amarrado com a respectiva Nota Fiscal Transportada, que devera conter os seguintes dados:
   //===================================================================================================
   aAdd(_aStructCTE,{"F2_DOC"    ,"C", TamSX3("F2_DOC")[1],0})                           // Documento
   aAdd(_aStructCTE,{"F2_SERIE"  ,"C", TamSX3("F2_SERIE")[1],0})                         // serie
   aAdd(_aStructCTE,{"F2_VALBRUT","N", TamSX3("F2_VALBRUT")[1],TamSX3("F2_VALBRUT")[2]}) // Vlr.Total da Nota
   aAdd(_aStructCTE,{"F2_EMISSAO","D", 8,0})                                             // DT Emissão
   aAdd(_aStructCTE,{"D2_CF"     ,"C", 40,0})                                            // Cod. Fiscal
   aAdd(_aStructCTE,{"F2_CLIENTE","C", 18,0})                                            // F2_LOJA  // CNPJ/CPF Cliente // TamSX3("F2_CLIENTE")[1]
   aAdd(_aStructCTE,{"B1_DESC"   ,"C", 150,0})                                           // D2_COD (B1_DESC)   // Descrição Produto
   aAdd(_aStructCTE,{"B1_POSIPI" ,"C", 50,0})                                            // D2_COD (B1_POSIPI)  // NCM
   aAdd(_aStructCTE,{"FT2_CSTPIS","C", 40,0})                                            // Sit.Trib.PIS
   aAdd(_aStructCTE,{"FT2_CSTCOF","C", 40,0})                                            // Sit.Trib.COFINS
   aAdd(_aStructCTE,{"F2_VALMERC","N", TamSX3("F2_VALMERC")[1],TamSX3("F2_VALMERC")[2]}) // Vlr.Total Mercadoria
   aAdd(_aStructCTE,{"F2_CHVNFE" ,"C", TamSX3("F2_CHVNFE")[1],0})                        // Chave Nfe
   aAdd(_aStructCTE,{"A2_I_TPAVE","C", 1,0})                                             // A2_I_TPAVE   // Tipo de Averbação de Carga 
    
   //================================================================================
   // Verifica se ja existe um arquivo com mesmo nome, se sim fecha.
   //================================================================================
   If Select("TRBCTE") > 0
      TRBCTE->( DBCloseArea() )
   EndIf
    
    oproc:cCaption := ("1/3 Criando tabela temporária...")
	ProcessMessages()
      
   _otemp := FWTemporaryTable():New( "TRBCTE", _aStructCTE )

   _otemp:AddIndex( "01", {"F1_FILIAL","F1_DTDIGIT","F1_DOC","F1_SERIE"} )
   
   _otemp:Create()
   
    oproc:cCaption := ("2/3 Carregando query de dados...")
	ProcessMessages()
   
   //====================================================================================================
   // Monta a query de dados.
   //====================================================================================================	
   _cQry := " SELECT DISTINCT CKO.R_E_C_N_O_ RECNOCKO, SF1.R_E_C_N_O_ RECNOSF1 "
   _cQry += " FROM " + RetSqlName("CKO") + " CKO, " + RetSqlName("SF1") +" SF1 "
   _cQry += " WHERE CKO.D_E_L_E_T_ = ' ' AND SF1.D_E_L_E_T_ = ' ' "
   _cQry += " AND F1_ESPECIE = 'CTE' AND F1_STATUS = 'A' "
   _cQry += " AND SubStr(CKO_ARQUIV,4,44) = F1_CHVNFE "
   _cQry += " AND CKO_CODEDI = '214' "

   If !Empty(MV_PAR01) // De Filial  
      _cQry +=  " AND F1_FILIAL IN " + FormatIn(MV_PAR01,";")
   EndIf

   If ! Empty(MV_PAR02) // De Emissao  
      _cQry += " AND F1_DTDIGIT >= '"+DToS(MV_PAR02)+"' "
   EndIf
   
   If !Empty(MV_PAR03) // Até Emissao 
      _cQry += " AND F1_DTDIGIT <= '"+DToS(MV_PAR03)+"' "
   EndIf

   If !Empty(MV_PAR06) // De Transportadora 
      _cQry +=  " AND F1_FORNECE >=  '" + MV_PAR06 + "'"
   EndIf

   If !Empty(MV_PAR08) // Até Transportadora 
      _cQry +=  " AND F1_FORNECE <=  '" + MV_PAR08 + "'"
   EndIf

   If !Empty(MV_PAR07) // De Loja
      _cQry +=  " AND F1_LOJA >=  '" + MV_PAR07 + "'"
   EndIf

   If !Empty(MV_PAR09) // Até Loja 
      _cQry +=  " AND F1_LOJA <=  '" + MV_PAR09 + "'"
   EndIf
      
   If Select("TRBSF1") <> 0
	  TRBSF1->(DBCloseArea())
   EndIf
	
   TCQUERY _cQry NEW ALIAS "TRBSF1"	
   
   If TRBSF1->(Eof()) .Or. TRBSF1->(Bof())
      U_ITMsg("Não existem dados que satisfaçam as condições de filtros para a emissão do relatório.","Atenção", ,1) 
      _lRet := .F.
      Break
   EndIf
   
   DBSelectArea("TRBSF1")
      
   COUNT TO _nTotRegs
      
   TRBSF1->(DBGoTop())
    
   While ! TRBSF1->(Eof())
      
       oproc:cCaption := ("3/3 Carregando dados de CTE, " + StrZero(_nni,6) + " de " + StrZero(_ntotregs,6) + "...")
       ProcessMessages()
       _nni++
      
      //================================================
      // Posiciona nos registros da tabela CKO e SF1.
      //================================================
      CKO->(DBGoTo(TRBSF1->RECNOCKO))
      SF1->(DBGoTo(TRBSF1->RECNOSF1)) 
      
      //=====================================================
      // Grava os dados da tabela temporária do relatorio.
      //=====================================================
      _cF1_FILIAL  := SF1->F1_FILIAL                                                                             // Filial
      _dF1_DTDIGIT := SF1->F1_DTDIGIT                                                                            // DT Digitação
      _dF1_EMISSAO := SF1->F1_EMISSAO                                                                            // DT Emissao
      _cF1_DOC     := SF1->F1_DOC                                                                                // Documento
      _cF1_SERIE   := SF1->F1_SERIE                                                                              // Serie
      _cA2_CGC     := Posicione("SA2",1,xFilial("SA2")+SF1->(F1_FORNECE + F1_LOJA),"A2_CGC")                     // -> F1_FORNECE + F1_LOJA // CNPJ do Transportado
      _cA2_NOME    := Posicione("SA2",1,xFilial("SA2")+SF1->(F1_FORNECE + F1_LOJA),"A2_NOME")                    // Transportador
      _cA2_TPAVE   := Posicione("SA2",1,xFilial("SA2")+SF1->(F1_FORNECE + F1_LOJA),"A2_I_TPAVE")                 // Tipo Averbação de Carga 
      _nF1_VALBRUT := SF1->F1_VALBRUT                                                                            // Vlr.Total           
      _cF1_ESPECIE := SF1->F1_ESPECIE       
      _cF1_PBRUTO  := SF1->F1_PBRUTO                                                                     // Peso Bruto     
      
       _aDadosTrib  := ROMS051F(SF1->F1_FILIAL,SF1->F1_DOC,SF1->F1_SERIE,SF1->F1_FORNECE,SF1->F1_LOJA,"ENTRADA")    
      _cD1_CF      := ""                                                                                         // Cod. Fiscal  
      _cF4_CSTPIS  := "" 				                                                                          // Sit.Trib.PIS
      _cF4_CSTCOF  := "" 				                                                                          // Sit.Trib.COFINS
      
      If ! Empty(_aDadosTrib)
         For _nI := 1 To Len(_aDadosTrib)
             _cD1_CF     += If(!Empty(_cD1_CF),"/","") + _aDadosTrib[_nI,2] // Codigo Fiscal
             _cF4_CSTPIS += If(!Empty(_cF4_CSTPIS),"/","") + _aDadosTrib[_nI,5] // CST PIS
             _cF4_CSTCOF += If(!Empty(_cF4_CSTCOF),"/","") + _aDadosTrib[_nI,6] // CST COFINS
         Next
      EndIf
      
      _cF1_CHVNFE  := SF1->F1_CHVNFE                                                                             // Chave 
 
      If Empty(CKO->CKO_XMLRET)
         _aDadosXML  := {}
      Else
         _aDadosXML := ROMS051H(CKO->CKO_XMLRET)  // Dados do CTE contido no XML.
      EndIf
      
      If Empty(_aDadosXML)
         TRBCTE->(DBAPPEND()) 
         TRBCTE->F1_FILIAL  := _cF1_FILIAL      // Filial
         TRBCTE->F1_DTDIGIT := _dF1_DTDIGIT     // DT Digitação
         TRBCTE->F1_EMISSAO := _dF1_EMISSAO     // DT Emissao
         TRBCTE->F1_DOC     := _cF1_DOC         // Documento
         TRBCTE->F1_SERIE   := _cF1_SERIE       // Serie
         TRBCTE->D1_CF      := _cD1_CF          // Cod. Fiscal    
         TRBCTE->A2_CGC     := _cA2_CGC         // -> F1_FORNECE + F1_LOJA // CNPJ do Transportado
         TRBCTE->A2_NOME    := _cA2_NOME        // Transportador
         TRBCTE->F1_VALBRUT := _nF1_VALBRUT     // Vlr.Total
         TRBCTE->FT_CSTPIS  := _cF4_CSTPIS      // Sit.Trib.PIS
         TRBCTE->FT_CSTCOF  := _cF4_CSTCOF      // Sit.Trib.COFINS
         TRBCTE->F1_CHVNFE  := _cF1_CHVNFE      // Chave  
         TRBCTE->F1_ESPECIE := _cF1_ESPECIE     // Especie do Documento
         TRBCTE->F1_PBRUTO  := _cF1_PBRUTO
         TRBCTE->A2_I_TPAVE := _cA2_TPAVE       // Tipo de Averbação de Carga 
      Else
         For _nI := 1 To Len(_aDadosXML)
             TRBCTE->(DBAPPEND()) 
             TRBCTE->F1_FILIAL  := _cF1_FILIAL      // Filial
             TRBCTE->F1_DTDIGIT := _dF1_DTDIGIT     // DT Digitação
             TRBCTE->F1_EMISSAO := _dF1_EMISSAO     // DT Emissao
             TRBCTE->F1_DOC     := _cF1_DOC         // Documento
             TRBCTE->F1_SERIE   := _cF1_SERIE       // Serie
             TRBCTE->D1_CF      := _cD1_CF          // Cod. Fiscal    
             TRBCTE->A2_CGC     := _cA2_CGC         // -> F1_FORNECE + F1_LOJA // CNPJ do Transportado
             TRBCTE->A2_NOME    := _cA2_NOME        // Transportador
             TRBCTE->F1_VALBRUT := _nF1_VALBRUT     // Vlr.Total
             TRBCTE->FT_CSTPIS  := _cF4_CSTPIS      // Sit.Trib.PIS
             TRBCTE->FT_CSTCOF  := _cF4_CSTCOF      // Sit.Trib.COFINS
             TRBCTE->F1_CHVNFE  := _cF1_CHVNFE      // Chave CTE 
             TRBCTE->F1_ESPECIE := _cF1_ESPECIE     // Especie do Documento
             TRBCTE->F1_PBRUTO  := _cF1_PBRUTO      // Peso Bruto
             TRBCTE->A2_I_TPAVE := _cA2_TPAVE       // Tipo de Averbação de Carga 

             //===================================================================================================
             // Amarrado com a respectiva Nota Fiscal Transportada, que devera conter os seguintes dados:
             //===================================================================================================
             TRBCTE->F2_DOC     :=  _aDadosXML[_nI, 8]   // Documento
             TRBCTE->F2_SERIE   :=  _aDadosXML[_nI, 9]   // serie
             TRBCTE->F2_VALBRUT :=  _aDadosXML[_nI,10]   // Vlr.Total da Nota
             TRBCTE->F2_EMISSAO :=  _aDadosXML[_nI,11]   // DT Emissão
             TRBCTE->D2_CF      :=  _aDadosXML[_nI,15]   // Cod. Fiscal
             TRBCTE->F2_CLIENTE :=  _aDadosXML[_nI,14]   // F2_LOJA  // CNPJ/CPF Cliente
             TRBCTE->B1_DESC    :=  _aDadosXML[_nI,16]   // D2_COD (B1_DESC)   // Descrição Produto
             TRBCTE->B1_POSIPI  :=  _aDadosXML[_nI,17]   // D2_COD (B1_POSIPI)  // NCM
             TRBCTE->FT2_CSTPIS :=  _aDadosXML[_nI,18]   // Sit.Trib.PIS
             TRBCTE->FT2_CSTCOF :=  _aDadosXML[_nI,19]   // Sit.Trib.COFINS
             TRBCTE->F2_VALMERC :=  _aDadosXML[_nI,12]   // Vlr.Total Mercadoria
             TRBCTE->F2_CHVNFE  :=  _aDadosXML[_nI,13]   // Chave Nfe

         Next
      EndIf      
  
      TRBSF1->(DBSkip()) 
   EndDo
   
End Sequence

If Select("TRBSF1") <> 0
   TRBSF1->(DBCloseArea())
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: ROMS051F
Autor-------------: Julio de Paula Paz
Data da Criacao---: 14/05/2018
Descrição---------: Retorna a Classificação Fiscal dos itens da nota fiscal concatenados.
Parametros--------: _cCodFilial = Código da filial
                    _cNrNf      = Numero da nota fiscal de entrada
                    _cSerieNf   = Serie da nota fiscal
                    _cFornece   = Codigo do fornecedor
                    _cLoja      = Loja do fornecedor
Retorno-----------: _aRet = {        ITEM, = Item da SD2 ou SD1   // 1
                                _cCodFisc, = Código Fiscal        // 2
                                _cDescPrd, = Descrição do Produto // 3
                                    _cNcm, = Código da NCM        // 4 
                                 _cCSTPIS, = CST PIS              // 5 
                               _cCSTCOFINS = CST COFINS           // 6 
                               Recno       =  Recno da tabela SD1 ou SD2} // 7
===============================================================================================================================
*/
Static Function ROMS051F(_cCodFilial, _cNrNf, _cSerieNf, _cFornece, _cLoja, _cTIPONF)
Local _aRet := ""
Local _cCodFisc := ""
Local _cDescPrd := ""
Local _cNcm     := ""
Local _cCSTPIS    := ""
Local _cCSTCOFINS := ""

Default _cTIPONF := "ENTRADA"

Begin Sequence
   If _cTIPONF == "ENTRADA"
      _aRet := {}
      SF4->(DBSetOrder(1)) // F4_FILIAL+F4_CODIGO
      SD1->(DBSetOrder(1)) // D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA+D1_COD+D1_ITEM
      SD1->(DBSeek(_cCodFilial + _cNrNf + _cSerieNf + _cFornece + _cLoja))
      While ! SD1->(Eof()) .And. SD1->(D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA) == _cCodFilial + _cNrNf + _cSerieNf + _cFornece + _cLoja
         //_aRet += If(!Empty(_aRet),"/","") + AllTrim(SD1->D1_CF)
         _cCodFisc := AllTrim(SD1->D1_CF)
         _cDescPrd := AllTrim(Posicione("SB1",1,xFilial("SB1")+SD1->D1_COD,"B1_DESC"))
         _cNcm     := AllTrim(Posicione("SB1",1,xFilial("SB1")+SD1->D1_COD,"B1_POSIPI"))
         _cCSTPIS    := ""
         _cCSTCOFINS := ""
         If SF4->(DBSeek(SD1->D1_FILIAL+SD1->D1_TES))
            _cCSTPIS    := SF4->F4_CSTPIS // AllTrim(Posicione("SF4",1,SD1->D1_FILIAL+SD1->D1_TES,"F4_CSTPIS"))
            _cCSTCOFINS := SF4->F4_CSTCOF // AllTrim(Posicione("SF4",1,SD1->D1_FILIAL+SD1->D1_TES,"F4_CSTCOF"))
         EndIf
                 //      1             2         3        4      5         6             7
         aAdd(_aRet,{SD1->D1_ITEM, _cCodFisc, _cDescPrd, _cNcm,_cCSTPIS,_cCSTCOFINS,SD1->(Recno())})
      
         SD1->(DBSkip())
      EndDo
   Else // "SAIDA" 
      _aRet := {}
      
      SF4->(DBSetOrder(1)) // F4_FILIAL+F4_CODIGO 
      SD2->(DBSetOrder(3)) // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM 
      SD2->(DBSeek(_cCodFilial + _cNrNf + _cSerieNf + _cFornece + _cLoja))
      While ! SD2->(Eof()) .And. SD2->(D2_FILIAL+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA) == _cCodFilial + _cNrNf + _cSerieNf + _cFornece + _cLoja
         _cCodFisc := AllTrim(SD2->D2_CF)
         _cDescPrd := AllTrim(Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_DESC"))
         _cNcm     := AllTrim(Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_POSIPI"))
         _cCSTPIS    := ""
         _cCSTCOFINS := ""
         If SF4->(DBSeek(SD2->D2_FILIAL+SD2->D2_TES))
            _cCSTPIS    := SF4->F4_CSTPIS // AllTrim(Posicione("SF4",1,SD2->D2_FILIAL+SD2->D2_TES,"F4_CSTPIS"))
            _cCSTCOFINS := SF4->F4_CSTCOF // AllTrim(Posicione("SF4",1,SD2->D2_FILIAL+SD2->D2_TES,"F4_CSTCOF"))
         EndIf
                    //   1           2           3        4        5        6               7   
         aAdd(_aRet,{SD2->D2_ITEM, _cCodFisc, _cDescPrd, _cNcm, _cCSTPIS,_cCSTCOFINS, SD2->(Recno())})
         
         SD2->(DBSkip())
      EndDo
      
   EndIf
End Sequence

Return _aRet

/*
===============================================================================================================================
Programa----------: ROMS051H
Autor-------------: Julio de Paula Paz
Data da Criacao---: 14/05/2018
Descrição---------: Efetua a leitura das notas fiscais de vendas contidas no conteúdo dos XML do CTE.
Parametros--------: _cXML = XML do CTE.
Retorno-----------: _aRet = Array com o contéudo das notas fiscais de vendas.
===============================================================================================================================
*/
Static Function ROMS051H(_cXML)
Local _aRet := {}
Local _cChaveCTE   := ""
Local _cNrCTE      := ""
Local _cSerieCTE   := ""
Local _cEmissaoCTE := ""
Local _cCnpjTransp := ""
Local _cRazaoTrans := ""
Local _cXmlDeNFE   := ""
Local _lGravaCKO   := .T.
Local _cXmlCKO     := ""
Local _nI, _nJ
Local _cError := "", _cWarning := "" 
Local _nTamFil := TamSX3("F2_FILIAL")[1]
Local _nTamChave := TamSX3("F2_CHVNFE")[1]
Local _cD2_CF      := ""   // Cod. Fiscal 
Local _cB1_DESC    := ""   // D2_COD (B1_DESC)   // Descrição Produto
Local _cB1_POSIPI  := ""   // D2_COD (B1_POSIPI)  // NCM
Local _cF4_CSTPIS  := ""   // Sit.Trib.PIS
Local _cF4_CSTCOF  := ""   // Sit.Trib.COFINS


Begin Sequence
   _lGravaCKO := .T.
   
   //Gera o Objeto XML
   _cXmlCKO := AllTrim(_cXML) 
   
   _nI := At("<",_cXmlCKO)
   If _nI > 1 //.And. SubStr(_cXmlCKO,1,1) == "?" 
      _nJ := Len(_cXmlCKO)
      _cXmlCKO := SubStr(_cXmlCKO,_nI,_nJ) // Alguns XML possuem caracteres ? antes da primeira Tag. Esta instrução remove os caracteres ? antes da primeira tag. 
   EndIf
   _oXML := Nil
   _oXml := XmlParser(_cXmlCKO, "_", @_cError, @_cWarning ) 
      
   If (_oXml == NIL )
	  //u_itconout("Falha ao gerar Objeto XML : "+SubStr(_cError,1,10000)+" / "+SubStr(_cWarning,1,10000))	
	  _lGravaCKO := .F.
   EndIf       
      
   If _lGravaCKO
      //============================================================================================================	  
      // Dados do CTE
      //============================================================================================================	  
      _cChaveCTE   := AllTrim(_oXml:_CTEPROC:_PROTCTE:_INFPROT:_CHCTE:Text)
      _cNrCTE      := AllTrim(_oXml:_CTEPROC:_CTE:_INFCTE:_IDE:_NCT:Text)
      _cNrCTE      := StrZero(Val(_cNrCTE),9) 
      _cSerieCTE   := _oXml:_CTEPROC:_CTE:_INFCTE:_IDE:_SERIE:Text
      _cEmissaoCTE := SubStr(_oXml:_CTEPROC:_CTE:_INFCTE:_IDE:_DHEMI:Text,1,10)
      _cEmissaoCTE := AllTrim(StrTran(_cEmissaoCTE,"-",""))
      _cCnpjTransp := _oXml:_CTEPROC:_CTE:_INFCTE:_EMIT:_CNPJ:Text
      _cRazaoTrans := _oXml:_CTEPROC:_CTE:_INFCTE:_EMIT:_XNOME:Text
      
      _cXmlDeNFE := XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE,"_INFCTENORM")
 
      If ValType(_cXmlDeNFE) <> "O" 
         //u_itconout("O CTE: "+_cNrCTE+"-"+_cSerieCTE+" não pertence a uma nota fiscal de saida.")	
	     Break
	  EndIf   
           
      If _lgravacko .And. ValType(XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM,"_INFDOC")) <> "O" .And. ValType(XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM,"_INFDOC")) <> "A"
         //u_itconout("O CTE: "+_cNrCTE+"-"+_cSerieCTE+" não pertence a uma nota fiscal de saida.")	
   	     Break                                             
      EndIf
      
      _cXmlDeNFE := XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC,"_INFNFE")
      
      If ValType(_cXmlDeNFE) <> "O" .And. ValType(_cXmlDeNFE) <> "A"
         //  U_itconout("O CTE: "+_cNrCTE+"-"+_cSerieCTE+" não pertence a uma nota fiscal de saida.")	
		 Break
	  EndIf

      _cInfoNFE := _oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE
      _nQtdNFE := 1
      
      If ValType(_cInfoNFE) == "A"
         _nQtdNFE := Len(_cInfoNFE)
      EndIf
      
      SF1->(DBSetOrder(8) )      //F1_FILIAL+F1_CHVNFE
      SF2->(DbOrderNickName("IT_CHVNF2") )// K - 20 - F2_CHVNFE
      
      For _nI := 1 To _nQtdNFE
          //=================================================================================      
          _cF2_DOC     := ""               // Documento
          _cF2_SERIE   := ""               // serie
          _nF2_VALBRUT := 0                // Vlr.Total da Nota
          _dF2_EMISSAO := Ctod("  /  /  ") // DT Emissão
          _nF2_VALMERC := 0                // Vlr.Total Mercadoria
          _cF2_CHVNFE  := ""               // Chave Nfe
          _cF2_CLIENTE := ""               // F2_CLIENTE+F2_LOJA  // CNPJ/CPF Cliente
          _cD2_CF      := ""               // Cod. Fiscal
          _cB1_DESC    := ""               // D2_COD (B1_DESC)   // Descrição Produto
          _cB1_POSIPI  := ""               // D2_COD (B1_POSIPI)  // NCM
          //=================================================================================      
            
          If _nQtdNFE == 1                                          
             _cNroNFE := XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE,"_CHAVE")
                          
             If ValType(_cNroNFE) <> "O" .And. ValType(_cNroNFE) <> "A"
                If ValType(_cInfoNFE:TEXT) == "C"
                   _cChaveNFE := _cInfoNFE:TEXT
                Else
                   _lgravacko := .F.
                EndIf
             Else
                _cChaveNFE := _oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE:_CHAVE:TEXT
             EndIf
          Else
             _cChaveNFE := _oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE[_nI]:_CHAVE:TEXT   
          EndIf         
           
          If _lgravacko

             If (MV_PAR05 = 1 .And. SF2->(DBSeek(PadR(_cChaveNFE,_nTamChave," "))) ) .OR.;//Saida
                (MV_PAR05 = 2 .And. SF1->(DBSeek(PadR(CKO->CKO_FILPRO,_nTamFil," ") + PadR(_cChaveNFE,_nTamChave," "))) )//Entrada

                If MV_PAR05 = 1//Saida
                   _cF2_DOC     := SF2->F2_DOC      // Documento
                   _cF2_SERIE   := SF2->F2_SERIE    // serie
                   _nF2_VALBRUT := SF2->F2_VALBRUT  // Vlr.Total da Nota
                   _dF2_EMISSAO := SF2->F2_EMISSAO  // DT Emissão
                   _nF2_VALMERC := SF2->F2_VALMERC  // Vlr.Total Mercadoria
                   _cF2_CHVNFE  := SF2->F2_CHVNFE   // Chave Nfe
                   _cF2_CLIENTE := Posicione("SA1",1,xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA),"A1_CGC") // CNPJ/CPF Cliente    //Posicione("SA2",1,xFilial("SA2")+SF2->(F2_CLIENTE+F2_LOJA),"A2_CGC") // CNPJ/CPF Cliente
                ElseIf MV_PAR05 = 2//Entrada
                   _cF2_DOC     := SF1->F1_DOC      // Documento
                   _cF2_SERIE   := SF1->F1_SERIE    // serie
                   _nF2_VALBRUT := SF1->F1_VALBRUT  // Vlr.Total da Nota
                   _dF2_EMISSAO := SF1->F1_EMISSAO  // DT Emissão
                   _nF2_VALMERC := SF1->F1_VALMERC  // Vlr.Total Mercadoria
                   _cF2_CHVNFE  := SF1->F1_CHVNFE   // Chave Nfe
                   _cF2_CLIENTE := Posicione("SA2",1,xFilial("SA2")+SF1->F1_FORNECE+SF1->F1_LOJA,"A2_CGC") // CNPJ/CPF Cliente    //Posicione("SA2",1,xFilial("SA2")+SF2->(F2_CLIENTE+F2_LOJA),"A2_CGC") // CNPJ/CPF Cliente
                EndIf
                
                If MV_PAR04 == 1 // Relatório Sintético 
                   _cD2_CF      := ""   // Cod. Fiscal 
                   _cB1_DESC    := ""   // D2_COD (B1_DESC)   // Descrição Produto
                   _cB1_POSIPI  := ""   // D2_COD (B1_POSIPI)  // NCM
                   _cF4_CSTPIS  := ""   // Sit.Trib.PIS
                   _cF4_CSTCOF  := ""   // Sit.Trib.COFINS
                   _cD2_CF      := ""
                   _cB1_DESC    := ""
                   
                   aAdd(_aRet,{_cChaveCTE,;    // Chave CTE                               // 1
                               _cNrCTE,;       // Numero CTE                              // 2
                               _cSerieCTE,;    // Serie CTE                               // 3 
                               _cEmissaoCTE,;  // Emissão CT                              // 4
                               _cCnpjTransp,;  // CNPJ Transportadora                     // 5  
                               _cRazaoTrans,;  // Nome Transportadora                     // 6
                               _cChaveNFE,;    // Chave Nota Fiscal Eletronica XML        // 7
                               _cF2_DOC,;      // Documento                               // 8
                               _cF2_SERIE,;    // serie                                   // 9
                               _nF2_VALBRUT,;  // Vlr.Total da Nota                       // 10
                               _dF2_EMISSAO,;  // DT Emissão                              // 11
                               _nF2_VALMERC,;  // Vlr.Total Mercadoria                    // 12
                               _cF2_CHVNFE,;   // Chave Nfe SF2                           // 13
                               _cF2_CLIENTE,;  // CNPJ/CPF Cliente                        // 14
                               _cD2_CF,;       // Cod. Fiscal                             // 15 
                               _cB1_DESC,;     // D2_COD (B1_DESC)   // Descrição Produto // 16
                               _cB1_POSIPI,;   // D2_COD (B1_POSIPI)  // NCM              // 17
                               _cF4_CSTPIS,;   // Sit.Trib.PIS                            // 18
                               _cF4_CSTCOF})   // Sit.Trib.COFINS			              // 19

                Else // MV_PAR04 == 2 // Relatório Analítico

                If MV_PAR05 = 1//Saida
                   _aDadosTrib  := ROMS051F(SF2->F2_FILIAL,SF2->F2_DOC,SF2->F2_SERIE,SF2->F2_CLIENTE,SF2->F2_LOJA,"SAIDA")    
                ElseIf MV_PAR05 = 2//Entrada
                   _aDadosTrib  := ROMS051F(SF1->F1_FILIAL,SF1->F1_DOC,SF1->F1_SERIE,SF1->F1_FORNECE,SF1->F1_LOJA,"ENTRADA")    
                EndIf
                   //-----------------------------------------------------------------------------------------------------------------//
                   For _nJ := 1 To Len(_aDadosTrib)
                       _cD2_CF     := _aDadosTrib[_nJ,2] // AllTrim(SD2->D2_CF)
                       _cB1_DESC   := _aDadosTrib[_nJ,3] // AllTrim(Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_DESC"))
                       _cB1_POSIPI := _aDadosTrib[_nJ,4] // AllTrim(Posicione("SB1",1,xFilial("SB1")+SD2->D2_COD,"B1_POSIPI"))
                       _cF4_CSTPIS := _aDadosTrib[_nJ,5]
                       _cF4_CSTCOF := _aDadosTrib[_nJ,6]
                      
                       aAdd(_aRet,{_cChaveCTE,;   // Chave CTE                               // 1
                                  _cNrCTE,;       // Numero CTE                              // 2
                                  _cSerieCTE,;    // Serie CTE                               // 3 
                                  _cEmissaoCTE,;  // Emissão CT                              // 4
                                  _cCnpjTransp,;  // CNPJ Transportadora                     // 5  
                                  _cRazaoTrans,;  // Nome Transportadora                     // 6
                                  _cChaveNFE,;    // Chave Nota Fiscal Eletronica XML        // 7
                                  _cF2_DOC,;      // Documento                               // 8
                                  _cF2_SERIE,;    // serie                                   // 9
                                  _nF2_VALBRUT,;  // Vlr.Total da Nota                       // 10
                                  _dF2_EMISSAO,;  // DT Emissão                              // 11
                                  _nF2_VALMERC,;  // Vlr.Total Mercadoria                    // 12
                                  _cF2_CHVNFE,;   // Chave Nfe SF2                           // 13
                                  _cF2_CLIENTE,;  // CNPJ/CPF Cliente                        // 14
                                  _cD2_CF,;       // Cod. Fiscal                             // 15 
                                  _cB1_DESC,;     // D2_COD (B1_DESC)   // Descrição Produto // 16
                                  _cB1_POSIPI,;   // D2_COD (B1_POSIPI)  // NCM              // 17
                                  _cF4_CSTPIS,;   // Sit.Trib.PIS                            // 18
                                  _cF4_CSTCOF})   // Sit.Trib.COFINS			              // 19
                   
                   Next
               EndIf
		     EndIf
          EndIf
      Next 
   EndIf
   
End Sequence

_oXML:=Nil
DelClassIntf()

Return _aRet
