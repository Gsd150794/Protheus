/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Antonio.Ramos |19/12/2023| Ajuste na rotina para verificar a existência da Tag 
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RFIS007
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/08/2021
Descrição---------: Relatório comparativo de envio de dados para o ECAC versus o que foi retornado pela ECAC. (Retorno REINF).
                    Chamado 37607.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function RFIS007()
Local _cPerg := "RFIS007"

Private _aDados := {}

Begin Sequence 

   //=============================================
   // Tela de filtro
   //=============================================
   If !Pergunte(_cPerg)
      Break
   EndIf 
   
   If MV_PAR03 <> 3
      U_ITMsg("Por enquanto este relatório é apenas para o evento R-2055.","Atenção",1)
      Break
   EndIf 

   //=============================================
   // Criando Tabela Temporária.
   //=============================================
   _aStruct := {}
   aAdd(_aStruct,{"WK_RECIBO" ,"C",30 ,0})  // Recibo Sped
   aAdd(_aStruct,{"WK_DATA"   ,"D",8  ,0})  // Data Sped
   aAdd(_aStruct,{"WK_HORA"   ,"C",8  ,0})  // Hora Sped
   aAdd(_aStruct,{"WK_RECNO"  ,"N",10 ,0})  // Recno Sped500
      
   If Select("SPEDTRB") > 0
      SPEDTRB->(DBCloseArea())
   EndIf

   //================================================================================
   // Abre o arquivo TRBCABA criado dentro do banco de dados protheus.
   //================================================================================
   _oTemp := FWTemporaryTable():New( "SPEDTRB",  _aStruct )
   
   //================================================================================
   // Cria os indices para o arquivo.
   //================================================================================
   _oTemp:AddIndex( "01", {"WK_RECIBO"} )
   _oTemp:Create()
   
   DBSelectArea("SPEDTRB") 

   //=============================================
   // Emite o relatório.
   //=============================================
   Processa( {|| RFIS007D()} , 'Lendo Dados do Relatório...' , 'Aguarde!' )
  
   If Len(_aDados) == 0
      U_ITMsg("Não existem dados para emissão do relatório.","Atenção",1)
      Break
   EndIf

   _aTitulos := {"Filial",;
                 "Evento",; 
                 "CPF Produtor",;
                 "Nome do Produtor",;
                 "Ind Isenção",;
                 "Desc Isenção",;
                 "Base de Calculo",;
                 "Valor INSS",;
                 "Valor GilRAT",;
                 "Valor Senar",;
                 "Valor INSS_165601",;
                 "INSS ENVRET",;       
                 "Valor GilRAT_164603",;
                 "GilRAT ENVRET",;     
                 "Valor Senar_121306",;
                 "Senar ENVRET",;      
                 "Data Transmissao",;
                 "Status",;
                 "Desc Status",;
                 "Recibo",;
                 "Cod.Resposta",;
                 "Desc.Resposta",;
                 "Local do Erro"}

   U_ITListBox("Retorno REINF" , _aTitulos , _aDados , .T. , 1 , "Exportação excel/arquivo")   
   
End Sequence 

If Select("SPEDTRB") > 0
   SPEDTRB->(DBCloseArea())
EndIf

Return 

/*
===============================================================================================================================
Programa----------: RFIS007D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/04/2017
Descrição---------: Gera os dados do relatório e grava em tabelas temporárias para emissão do relatorio em Excel.
Parametros--------: Nenhum
Retorno-----------: .T. OU .F.
===============================================================================================================================
*/  
Static Function RFIS007D()                                                                                                                  
Local _cQry
Local _nTOTREGS
Local _nI, _cXmlEnvio, _cXmlRetorno  
Local _lNovoReg, _lAtualiza, _nReglidos

Begin Sequence 

   _cQry := " SELECT SPED.RECIBO , SPED.DTPROC, SPED.HRPROC, SPED.DTENTRADA, SPED.R_E_C_N_O_ NRREC "
   _cQry += " FROM SPED500 SPED"
   _cQry += " WHERE  SPED.D_E_L_E_T_ = ' ' "

   If ! Empty(MV_PAR01)        
      _cQry +=  " AND DTENTRADA >= '"+DToS(MV_PAR01)+"' "
   EndIf
   
   If ! Empty(MV_PAR02)        
      _cQry +=  " AND DTENTRADA <= '"+DToS(MV_PAR02)+"' "
   EndIf
   
   If MV_PAR03 == 1
      _cQry+=  " AND CODEVENTO = 'R-2010' "
   ElseIf MV_PAR03 == 2
      _cQry+=  " AND CODEVENTO = 'R-2040' "
   ElseIf MV_PAR03 == 3   
      _cQry+=  " AND CODEVENTO = 'R-2055' "
   EndIf

   _cQry += " ORDER BY DTENTRADA "
     
   If Select("QRYSPED") > 0
      QRYSPED->(DBCloseArea())
   EndIf
   
   _cQry := ChangeQuery(_cQry) 

   DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry), "QRYSPED", .F., .T.)    
   
   COUNT TO _nTOTREGS 

   If _nTOTREGS == 0
      Break
   EndIf                 
 
   //===================================================================================================
   // Abre o arquivo de Sped para leitura dos XML e Envio para o RDC.
   //===================================================================================================
   If Select("SPED500") > 0
      SPED500->( DBCloseArea() )
   EndIf     
   
   USE SPED500 ALIAS "SPED500" SHARED NEW VIA "TOPCONN" 
  
   //===================================================================================================
   // Inicia leitura e gravação dos dados
   //===================================================================================================

   ProcRegua(_nTOTREGS)

   If MV_PAR04 ==  2 // Exibe recibos repetidos
      QRYSPED->(DBGoTop())
   
      _nI := 1

      While ! QRYSPED->(Eof()) 
         IncProc( "Favor Aguardar... Processando registro: " + AllTrim( Str(_nI,5) ) +"/"+AllTrim(Str(_nTOTREGS,5)))
      
         _nI += 1

         SPED500->(DBGoTo(QRYSPED->NRREC))
      
         _cXmlEnvio := AllTrim(SPED500->XMLEVENTO) 
      
         _cXmlRetorno := AllTrim(SPED500->XMLRETEVEN)

         U_RFIS007R(_cXmlEnvio,_cXmlRetorno) 

         _cXmlEnvio   := Nil 
         _cXmlRetorno := Nil
         DelClassIntf()  // Remove da memória da Thread todos os objetos.

         QRYSPED->(DBSkip())
      EndDo

   Else // Exibe apena o último recibo quando registrado mais de uma vez.

      QRYSPED->(DBGoTop())
   
      _nI := 1
      _nReglidos := 0

      While ! QRYSPED->(Eof()) 
         IncProc( "Favor Aguardar... Processando registro: " + AllTrim( Str(_nI,5) ) +"/"+AllTrim(Str(_nTOTREGS,5)))
         _nI += 1
         _nReglidos += 1

         _lNovoReg :=  .T.
         If SPEDTRB->(MSSEEK(SubStr(QRYSPED->RECIBO,1,30)))
            _lNovoReg := .F.
         EndIf 
         
         If ! _lNovoReg
            If DToS(SPEDTRB->WK_DATA) < QRYSPED->DTPROC .Or. (DToS(SPEDTRB->WK_DATA) == QRYSPED->DTPROC .And. SPEDTRB->WK_HORA < QRYSPED->HRPROC)
               _lAtualiza := .T.
            Else 
               _lAtualiza := .F.
            EndIf  
             
            If ! _lAtualiza
               QRYSPED->(DBSkip())
               Loop
            EndIf  
         EndIf 

         If _lNovoReg
            SPEDTRB->(RecLock("SPEDTRB", .T.))
         Else 
            SPEDTRB->(RecLock("SPEDTRB", .F.)) 
         EndIf    

         SPEDTRB->WK_RECIBO := QRYSPED->RECIBO       // Recibo Sped
         SPEDTRB->WK_DATA   := SToD(QRYSPED->DTPROC) // Data Sped
         SPEDTRB->WK_HORA   := QRYSPED->HRPROC       // Hora Sped
         SPEDTRB->WK_RECNO  := QRYSPED->NRREC        // Recno Sped500
         SPEDTRB->(MSUnLock())

         QRYSPED->(DBSkip())
      EndDo
 
      ProcRegua(_nReglidos)
      
      SPEDTRB->(DBGoTop())
   
      _nI := 1
 
      While ! SPEDTRB->(Eof()) 
         
         IncProc( "Favor Aguardar... Processando XMLs (Sped): " + AllTrim( Str(_nI,10) ) + "/" + AllTrim(Str(_nReglidos,10)))
         _nI += 1

         SPED500->(DBGoTo(SPEDTRB->WK_RECNO))
      
         _cXmlEnvio := AllTrim(SPED500->XMLEVENTO) 
      
         _cXmlRetorno := AllTrim(SPED500->XMLRETEVEN)

         U_RFIS007R(_cXmlEnvio,_cXmlRetorno) 

         _cXmlEnvio   := Nil 
         _cXmlRetorno := Nil
         DelClassIntf()  // Remove da memória da Thread todos os objetos.

         SPEDTRB->(DBSkip())
      EndDo

   EndIf  

End Sequence

If Select("QRYSPED") > 0
   QRYSPED->( DBCloseArea() )
EndIf

If Select("SPED500") > 0
   SPED500->( DBCloseArea() )
EndIf 

If Select("SPEDTRB") > 0
   SPEDTRB->( DBCloseArea() )
EndIf

Return

/*
===============================================================================================================================
Programa----------: RFIS007R
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/04/2017
Descrição---------: Faz a leitura dos XMLs passados por parâmetro e gera os dados do relatório.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function RFIS007R(_cXmlEnvio,_cXmlRetorno)
//Local _oXmlEnvio,_oXmlRetorno
Local _cXmlEnv, _cXmlRet 
Local _cError, _cWarning 
Local _nI, _nTotLin 

Begin Sequence 
   _cFilial        := ""
   _cNrInscr       := ""
   _cEvento        := ""
   _cCPFProdutor   := ""
   _cNomeProdutor  := ""
   _cIndIsencao    := ""
   _cDescIsencao   := ""
   _nBaseCalculo   := 0
   _nValorINSS     := 0
   _nValorGilRAT   := 0
   _nValorSenar    := 0
   _nINSS_165601   := 0
   _cEnvRetI165601  := ""
   _nGilRAT_164603 := 0
   _cEnvRetG164603  := ""
   _nSenar_121306  := 0
   _cEnvRetS121306  := ""
   _dDataTransmissao := Ctod("  /  /  ")
   _cStatus        := ""
   _cDescStatus    := ""
   _cRecibo        := ""
   _cCodResp       := ""
   _cDescResp      := ""
   _cLocalErro     := ""
 
   _cNrInscrA   := ""
   _cNrInscrP   := ""
   _cIndAquis   := ""
   _nValBruto   := "0"
   _nValCpDesc  := "0"
   _nValRatDesc := "0"
   _nValSenar   := "0"      
 
   _nTotLin        := 0
   _nINSS_165601   := ""
   _nGilRAT_164603 := ""
   _nSenar_121306  := ""
 

   _cError   := ""
   _cWarning := ""

   _cXmlEnv := AllTrim(StrTran(_cXmlEnvio,"???","")) 
 
   _oXmlE := ""
   If ! Empty(_cXmlEnv)
      _oXmlE := XmlParser(_cXmlEnv, "_" , @_cError , @_cWarning )
   EndIf
   
   If ValType(_oXmlE) == "O"
      If ValType( XmlChildEx( _oXmlE:_REINF:_EVTAQPROD:_INFOAQUISPROD:_IDEESTABADQUIR,"_NRINSCADQ")) <> "U"
         _cNrInscrA := _oXmlE:_REINF:_EVTAQPROD:_INFOAQUISPROD:_IDEESTABADQUIR:_NRINSCADQ:TEXT 
      EndIf
      //--------------------------------------------------------------------------- 
      //_REINF->EVTAQPROD->INFOAQUISPROD->IDEESTABADQUIR->IDEPRODUTOR->NRINSCPROD->TEXT  
      //_REINF->EVTAQPROD->INFOAQUISPROD->IDEESTABADQUIR->NRINSCADQ->TEXT  
      
      If ValType( XmlChildEx( _oXmlE:_REINF:_EVTAQPROD:_INFOAQUISPROD:_IDEESTABADQUIR:_IDEPRODUTOR,"_NRINSCPROD")) <> "U"
         _cNrInscrP:= _oXmlE:_REINF:_EVTAQPROD:_INFOAQUISPROD:_IDEESTABADQUIR:_IDEPRODUTOR:_NRINSCPROD:TEXT
      EndIf
   If ValType(XmlChildEx( _oXmlE:_REINF:_EVTAQPROD:_INFOAQUISPROD:_IDEESTABADQUIR:_IDEPRODUTOR,"_DETAQUIS")) <> "U"
      //REINF->EVTAQPROD->INFOAQUISPROD->IDEESTABADQUIR->IDEPRODUTOR->DETAQUIS->INDAQUIS->TEXT
      If ValType( XmlChildEx( _oXmlE:_REINF:_EVTAQPROD:_INFOAQUISPROD:_IDEESTABADQUIR:_IDEPRODUTOR:_DETAQUIS,"_INDAQUIS")) <> "U"
         _cIndAquis := _oXmlE:_REINF:_EVTAQPROD:_INFOAQUISPROD:_IDEESTABADQUIR:_IDEPRODUTOR:_DETAQUIS:_INDAQUIS:TEXT
      EndIf
      //REINF->EVTAQPROD->INFOAQUISPROD->IDEESTABADQUIR->IDEPRODUTOR->DETAQUIS->VLRBRUTO->TEXT
      If ValType( XmlChildEx( _oXmlE:_REINF:_EVTAQPROD:_INFOAQUISPROD:_IDEESTABADQUIR:_IDEPRODUTOR:_DETAQUIS,"_VLRBRUTO")) <> "U"
         _nValBruto:= _oXmlE:_REINF:_EVTAQPROD:_INFOAQUISPROD:_IDEESTABADQUIR:_IDEPRODUTOR:_DETAQUIS:_VLRBRUTO:TEXT
      EndIf
      //REINF->EVTAQPROD->INFOAQUISPROD->IDEESTABADQUIR->IDEPRODUTOR->DETAQUIS->VLRCPDESCPR->TEXT
      If ValType( XmlChildEx( _oXmlE:_REINF:_EVTAQPROD:_INFOAQUISPROD:_IDEESTABADQUIR:_IDEPRODUTOR:_DETAQUIS,"_VLRCPDESCPR")) <> "U"
         _nValCpDesc := _oXmlE:_REINF:_EVTAQPROD:_INFOAQUISPROD:_IDEESTABADQUIR:_IDEPRODUTOR:_DETAQUIS:_VLRCPDESCPR:TEXT 
      EndIf

      //REINF->EVTAQPROD->INFOAQUISPROD->IDEESTABADQUIR->IDEPRODUTOR->DETAQUIS->VLRRATDESCPR->TEXT
      If ValType( XmlChildEx( _oXmlE:_REINF:_EVTAQPROD:_INFOAQUISPROD:_IDEESTABADQUIR:_IDEPRODUTOR:_DETAQUIS,"_VLRRATDESCPR")) <> "U"
         _nValRatDesc := _oXmlE:_REINF:_EVTAQPROD:_INFOAQUISPROD:_IDEESTABADQUIR:_IDEPRODUTOR:_DETAQUIS:_VLRRATDESCPR:TEXT
      EndIf

      //REINF->EVTAQPROD->INFOAQUISPROD->IDEESTABADQUIR->IDEPRODUTOR->DETAQUIS->VLRSENARDESC->TEXT
      //vlrSenarDesc
      If ValType( XmlChildEx( _oXmlE:_REINF:_EVTAQPROD:_INFOAQUISPROD:_IDEESTABADQUIR:_IDEPRODUTOR:_DETAQUIS,"_VLRSENARDESC")) <> "U"
         _nValSenar := _oXmlE:_REINF:_EVTAQPROD:_INFOAQUISPROD:_IDEESTABADQUIR:_IDEPRODUTOR:_DETAQUIS:_VLRSENARDESC:TEXT
      EndIf
   EndIf 
EndIf 
   _cError   := ""
   _cWarning := ""

   _cXmlRet := AllTrim(StrTran(_cXmlRetorno,"???","")) 

   _oXmlR := ""
   If ! Empty(_cXmlRet)
      _oXmlR := XmlParser(_cXmlRet, "_" , @_cError , @_cWarning )
   EndIf

   If ValType(_oXmlR) == "O"   
      If Type( "_oXmlR:_REINF") == "O"
         If ValType( XmlChildEx(_oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB,"_RAQUIS")) <> "U"
            //REINF->EVTTOTAL->INFOTOTAL->IDEESTAB->RAQUIS[N]->CRAQUIS->TEXT
            //REINF->EVTTOTAL->INFOTOTAL->IDEESTAB->RAQUIS[N]->VLRCRAQUIS->TEXT
            //_oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB:_RAQUIS[N]
            //_cTipoVar := ValType( XmlChildEx(_oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB,"_RAQUIS"))
            
            If ValType( XmlChildEx(_oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB,"_RAQUIS")) == "O"
               If AllTrim(_oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB:_RAQUIS:_CRAQUIS:TEXT) == "165601" // INSS
                  _nINSS_165601   := _oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB:_RAQUIS:_VLRCRAQUIS:TEXT
               EndIf 

               If AllTrim(_oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB:_RAQUIS:_CRAQUIS:TEXT) == "164603" //  GilRAT
                  _nGilRAT_164603 := _oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB:_RAQUIS:_VLRCRAQUIS:TEXT 
               EndIf 

               If AllTrim(_oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB:_RAQUIS:_CRAQUIS:TEXT) == "121306" // SENAR
                  _nSenar_121306  := _oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB:_RAQUIS:_VLRCRAQUIS:TEXT
               EndIf 
            ElseIf ValType( XmlChildEx(_oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB,"_RAQUIS")) == "A"
               _nTotLin := Len(_oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB:_RAQUIS)
               If _nTotLin > 0
                  For _nI := 1 To _nTotLin
                      If AllTrim(_oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB:_RAQUIS[_nI]:_CRAQUIS:TEXT) == "165601" // INSS
                         _nINSS_165601   := _oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB:_RAQUIS[_nI]:_VLRCRAQUIS:TEXT
                      EndIf 

                      If AllTrim(_oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB:_RAQUIS[_nI]:_CRAQUIS:TEXT) == "164603" //  GilRAT
                         _nGilRAT_164603 := _oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB:_RAQUIS[_nI]:_VLRCRAQUIS:TEXT 
                      EndIf 

                      If AllTrim(_oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB:_RAQUIS[_nI]:_CRAQUIS:TEXT) == "121306" // SENAR
                         _nSenar_121306  := _oXmlR:_REINF:_EVTTOTAL:_INFOTOTAL:_IDEESTAB:_RAQUIS[_nI]:_VLRCRAQUIS:TEXT
                      EndIf 
                  Next
               EndIf
            EndIf 
         EndIf
      
      ElseIf Type( "_oXmlR:_REGOCORRS") == "O"
         _cCodResp   := _oXmlR:_REGOCORRS:_CODRESP:TEXT
         _cDescResp  := _oXmlR:_REGOCORRS:_DSCRESP:TEXT
         _cLocalErro := _oXmlR:_REGOCORRS:_LOCALERROAVISO:TEXT
      EndIf    

   EndIf 
   
   _cFilial        := U_RFIS007F(_cNrInscrA)
   _cNrInscr       := _cNrInscrA
   _cEvento        := "R-2055"
   _cCPFProdutor   := _cNrInscrP
   _cNomeProdutor  := Posicione("SA2",3,xFilial("SA2")+_cNrInscrP,"A2_NOME")
   _cIndIsencao    := AllTrim(_cIndAquis)

   If AllTrim(_cIndAquis) == "1"
      _cDescIsencao   := "Aquisição da produção de produtor rural pessoa física ou segurado especial em geral"
   ElseIf AllTrim(_cIndAquis) == "2"
      _cDescIsencao   := "Aquisição da produção de produtor rural pessoa física ou segurado especial em geral por Entidade do PAA"
   ElseIf AllTrim(_cIndAquis) == "3"
      _cDescIsencao   := "Aquisição da produção de produtor rural pessoa jurídica por Entidade do PAA"
   ElseIf AllTrim(_cIndAquis) == "4"
      _cDescIsencao   := "Aquisição da produção de produtor rural pessoa física ou segurado especial em geral - Produção Isenta (Lei 13.606/2018)"
   ElseIf AllTrim(_cIndAquis) == "5"
      _cDescIsencao   := "Aquisição da produção de produtor rural pessoa física ou segurado especial em geral por Entidade do PAA - Produção Isenta (Lei 13.606/2018)"
   ElseIf AllTrim(_cIndAquis) == "6"
      _cDescIsencao   := "Aquisição da produção de produtor rural pessoa jurídica por Entidade do PAA - Produção Isenta (Lei 13.606/2018)"
   EndIf 

   _nINSS_165601   := StrTran(_nINSS_165601, ",", "." )
   _nGilRAT_164603 := StrTran(_nGilRAT_164603, ",", "." )
   _nSenar_121306  := StrTran(_nSenar_121306, ",", "." )

   _nINSS_165601   := Val(_nINSS_165601)
   _nGilRAT_164603 := Val(_nGilRAT_164603)
   _nSenar_121306  := Val(_nSenar_121306)

   _nValBruto      := StrTran(_nValBruto, ",", "." )
   _nValCpDesc     := StrTran(_nValCpDesc, ",", "." )
   _nValRatDesc    := StrTran(_nValRatDesc, ",", "." )
   _nValSenar      := StrTran(_nValSenar , ",", "." )

   _nBaseCalculo   := Val(_nValBruto)
   _nValorINSS     := Val(_nValCpDesc)
   _nValorGilRAT   := Val(_nValRatDesc)
   _nValorSenar    := Val(_nValSenar)

   If (_nINSS_165601 == 0 .And. _nValorINSS > 0) .Or. (_nINSS_165601 <> _nValorINSS)
      _cEnvRetI165601  := "INVÁLIDO"
   Else 
      _cEnvRetI165601  := "VÁLIDO"
   EndIf 

   If (_nGilRAT_164603 == 0 .And. _nValorGilRAT > 0) .Or. (_nGilRAT_164603 <> _nValorGilRAT)
      _cEnvRetG164603  := "INVÁLIDO"
   Else 
      _cEnvRetG164603  := "VÁLIDO"
   EndIf 
   
   If (_nSenar_121306 == 0 .And. _nValorSenar > 0) .Or. (_nSenar_121306 <> _nValorSenar)
      _cEnvRetS121306  := "INVÁLIDO"
   Else 
      _cEnvRetS121306  := "VÁLIDO"
   EndIf 

   _dDataTransmissao := SPED500->DTTRANS 
   _cStatus          := SPED500->STATUS
   _cDescStatus      := SPED500->DETSTATUS
   _cRecibo          := SPED500->RECIBO
    
   aAdd(_aDados,{_cFilial,;
                 _cEvento,; 
                 _cCPFProdutor,;
                 _cNomeProdutor,;
                 _cIndIsencao,;
                 _cDescIsencao,;
                 _nBaseCalculo,;
                 _nValorINSS,;
                 _nValorGilRAT,;
                 _nValorSenar,;
                 _nINSS_165601,;   // _cEnvRet165601,;
                 _cEnvRetI165601,;
                 _nGilRAT_164603,; // _cEnvRet164603,;   
                 _cEnvRetG164603,;              
                 _nSenar_121306,;  // _cEnvRet121306,;   
                 _cEnvRetS121306,;               
                 _dDataTransmissao,;
                 _cStatus,;
                 _cDescStatus,;
                 _cRecibo,;
                 _cCodResp,;
                 _cDescResp,;
                 _cLocalErro})
      
   _oXmlR := Nil 
   _oXmlE := Nil 
      
   DelClassIntf()

End Sequence

Return 

/*
===============================================================================================================================
Programa----------: RFIS007F
Autor-------------: Julio de Paula Paz
Data da Criacao---: 27/08/2021
Descrição---------: Retorna a filial com base no cadastro de filiais Scheduller.
Parametros--------: _cCnpj = CNPJ da unidade
Retorno-----------: _cRet = Código da filia + Nome
===============================================================================================================================
*/  
User Function RFIS007F(_cCnp)
Local _cRet := ""
Local _cQry

Begin Sequence 

   _cQry := " SELECT ZZM_CODIGO, ZZM_DESCRI "
   _cQry += " FROM " + RetSqlName("ZZM") + " ZZM "
   _cQry += " WHERE  ZZM.D_E_L_E_T_ = ' ' "
   _cQry += " AND ZZM_CGC = '" + AllTrim(_cCnp) + "' "

   If Select("QRYZZM") > 0
      QRYZZM->(DBCloseArea())
   EndIf
   
   _cQry := ChangeQuery(_cQry) 

   DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry), "QRYZZM", .F., .T.)    
   
   If ! QRYZZM->(Eof()) .And. ! QRYZZM->(Bof())
      _cRet := AllTrim(QRYZZM->ZZM_CODIGO) + "-" + AllTrim(QRYZZM->ZZM_DESCRI)
   EndIf

End Sequence

If Select("QRYZZM") > 0
   QRYZZM->( DBCloseArea() )
EndIf

Return _cRet 
