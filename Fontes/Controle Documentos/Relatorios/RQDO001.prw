/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "report.ch"
#Include 'TOPCONN.CH'

/*
===============================================================================================================================
Programa----------: RQDO001
Autor-------------: Julio de Paula Paz
Data da Criacao---: 06/07/2022
Descrição---------: Relatório do histórico dos documentos. Chamado 40631.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RQDO001()
Local _oReport := nil
Local _cPerg   := "RQDO001"
Private _aOrder := {"Cadastramento"}
Private _oSect1 := Nil
Private _oSect2 := Nil
Private _nOrdReport := 1

Begin Sequence	
   //====================================================================================================
   // Cria as consultas de multiplas seleções para os filtros da função Pergunte.
   //====================================================================================================
   _aItalac_F3:={}

   _cSelQDH :="SELECT QDH_DOCTO CODDOC,QDH_TITULO FROM "+RETSQLNAME("QDH")+" QDH WHERE QDH.D_E_L_E_T_ = ' ' ORDER BY QDH_DOCTO "

   _cSelQD2 :="SELECT QD2_CODTP CODTIP,QD2_DESCTP FROM "+RETSQLNAME("QD2")+" QD2 WHERE QD2.D_E_L_E_T_ = ' ' ORDER BY QD2_CODTP "

   //Italac_F3:={}         1           2         3                       4                         5            6                    7                    8             9         10         11        12
   //AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave             , _nCpoDesc                ,_bCondTab , _cTitAux            , _nTamChv , _aDados  , _nMaxSel ,_lFilAtual,_cMVRET    ,_bValida})
   aAdd(_aItalac_F3,{"MV_PAR01"   ,_cSelQDH,{|Tab|(Tab)->CODDOC},{|Tab| (Tab)->QDH_TITULO} ,          ,"Documentos"         ,          ,          ,20        ,.F.        ,       , } )
   aAdd(_aItalac_F3,{"MV_PAR03"   ,_cSelQD2,{|Tab|(Tab)->CODTIP},{|Tab| (Tab)->QD2_DESCTP} ,          ,"Tipos de Documentos",          ,          ,20        ,.F.        ,       , } )

	//====================================================================================================
    // Gera a pergunta de modo oculto, ficando disponível no botão ações relacionadas
    //====================================================================================================
    Pergunte(_cPerg,.F.,"Filtros Relatório Histórico de Documentos")	          

	//====================================================================================================
    // Chama a montagem do relatório.
    //====================================================================================================	
	_oReport := RQDO001D(_cPerg)
	_oReport:PrintDialog()
	
End Sequence

Return

/*
===============================================================================================================================
Programa----------: RQDO001D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 06/07/2022
Descrição---------: Realiza as definições do relatório. (ReportDef)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RQDO001D(_cNome)
Local _oReport := Nil

Begin Sequence	
   _oReport := TReport():New(_cNome,"Relatório do Histórico de Documentos",_cNome,{|_oReport| RQDO001P(_oReport)},"Emissão do Relatório do Histórico de Documentos")
   _oReport:SetLandscape()    
   _oReport:SetTotalInLine(.F.)

   //====================================================================================================
   // Define as totalizações e quebra por seção.
   //====================================================================================================	
   _oReport:SetTotalInLine(.F.)
   
   // "Dados dos Documentos"
   _oSect1 := TRSection():New(_oReport, "Dados dos Documentos" , {"QD0", "QD1", "QD3", "QA2", "QDH", "QAA"},_aOrder , .F., .T.)
   TRCell():New(_oSect1,"QDH_DOCTO"	 , "TRBDOC"  ,"Cod.Documento"   ,"@!",16)		
   TRCell():New(_oSect1,"QDH_TITULO" , "TRBDOC"  ,"Titulo Documento","@!",40)		
   TRCell():New(_oSect1,"QD3_DESCAS" , "TRBDOC"  ,"Assunto"         ,"@!",40)	
   TRCell():New(_oSect1,"QDH_DTIMPL" , "TRBDOC"  ,"Data Implantação","@!",16)	
   TRCell():New(_oSect1,"QDH_DTLIM"	 , "TRBDOC"  ,"Data Validade"   ,"@!",13)	
   TRCell():New(_oSect1,"QA2_TEXTO"	 , "TRBDOC"  ,"Motivo Revisão"  ,"@!",40)	
   TRCell():New(_oSect1,"WK_STATUS"	 , "TRBDOC"  ,"Status"          ,"@!",08)	

   _oSect1:SetTotalText(" ")
   _oSect1:Disable()

   // "Responsáveis"
   _oSect2 := TRSection():New(_oSect1, "Responsáveis " , {"QD0", "QD1", "QD3", "QA2", "QDH", "QAA"}, , .F., .T.)
   TRCell():New(_oSect2,"QD0_AUT"    , "TRBDOC"  ,"Categoria"       ,"@!",15)
   TRCell():New(_oSect2,"QDH_RV"     , "TRBDOC"  ,"Revisão"         ,"@!",08)
   TRCell():New(_oSect2,"QD0_MAT"	 , "TRBDOC"  ,"Matricula"       ,"@!",16)
   TRCell():New(_oSect2,"WK_NOME"    , "TRBDOC"  ,"Nome"            ,"@!",30)		
   TRCell():New(_oSect2,"QD1_DTBAIX" , "TRBDOC"  ,"Data da Baixa"   ,"@!",14)	
   TRCell():New(_oSect2,"WK_RESPON"  , "TRBDOC"  ,"Responsabilidade","@!",14)	
   
   _oSect2:SetTotalText(" ")
   _oSect2:Disable()

End Sequence
					
Return(_oReport)

/*
===============================================================================================================================
Programa----------: RQDO001P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 06/07/2022
Descrição---------: Realiza a impressão do relatório. (ReportPrint)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RQDO001P(_oReport)
Local _cQry       := ""		
Local _cCodDoc, _cStatus, _cNome, _cCategor
Local _cQry2      := ""
Local _cDocFiltro := "", _cUltimaRv

Begin Sequence                    
   //====================================================================================================
   // Ativa a seção do relatório conforme a ordem de emissão do relatório.
   //====================================================================================================	
   _nOrdReport := _oReport:GetOrder()
   
   _oSect1:Enable() 
   _oSect2:Enable() 

   //====================================================================================================
   // Monta a query de dados.
   //====================================================================================================	
   _cQry := "SELECT DISTINCT QDH_DOCTO, QDH_TITULO, QDH_RV, QDH_DTIMPL IMPLANTACAO, QDH_DTLIM LIMITE, QD3_DESCAS ASSUNTO, " 
   _cQry += " QD0_AUT, QD0_MAT, QA2_TEXTO, QD1_DTBAIX, QD1_FILMAT, QD1_MAT, QD1_TPPEND  "
   _cQry += " FROM " + RetSqlName("QD0") + " QD0 " 
   _cQry += " JOIN " + RetSqlName("QDH") + " QDH ON QD0_DOCTO = QDH_DOCTO "
   _cQry += " JOIN " + RetSqlName("QD3") + " QD3 ON QDH_CODASS = QD3_CODASS "
   _cQry += " JOIN " + RetSqlName("QA2") + " QA2 ON QDH_CHAVE = QA2_CHAVE "
   _cQry += " JOIN " + RetSqlName("QD1") + " QD1 ON QD0_DOCTO = QD1_DOCTO AND QD0_RV = QD1_RV AND QD0_MAT = QD1_MAT "
   _cQry += " WHERE QD0.D_E_L_E_T_ = ' ' "
   _cQry += " AND QDH.D_E_L_E_T_ = ' '  "
   _cQry += " AND QD3.D_E_L_E_T_ = ' '  "
   _cQry += " AND QA2.D_E_L_E_T_ = ' '  "
   _cQry += " AND QD1.D_E_L_E_T_ = ' '  "
   _cQry += " AND QA2.QA2_ESPEC = 'REV'  " 
   _cQry += " AND QD1_TPPEND IN ('E','R','A','I') "
   _cQry += " AND QDH_RV = QD0_RV "
   _cQry += " AND QD0_RV = QD1_RV "
   _cQry += " AND QD1_RV = QDH_RV "

   If ! Empty(MV_PAR01)
      _cQry += " AND QDH_DOCTO IN " + FormatIn( MV_PAR01 , ";" )
   EndIf 

   If ! Empty(MV_PAR03)
      _cQry += " AND QDH_CODTP IN " + FormatIn( MV_PAR03 , ";" )
   EndIf 

   _cQry += " ORDER BY QDH_DOCTO, QDH_RV, QDH_DTIMPL, QD1_DTBAIX " // QD0.R_E_C_N_O_ 

   If Select("TRBDOC") <> 0
	   TRBDOC->(DBCloseArea())
   EndIf
	
   TCQUERY _cQry NEW ALIAS "TRBDOC"	
   TCSetField('TRBDOC',"IMPLANTACAO","D",8,0)
   TCSetField('TRBDOC',"LIMITE" ,"D",8,0)
   TCSetField('TRBDOC',"QD1_DTBAIX","D",8,0)
   	
   DBSelectArea("TRBDOC")
   TRBDOC->(DBGoTop())

   Count to _ntotRegs	
   _oReport:SetMeter(_ntotRegs)	
   
   TRBDOC->(DBGoTop())

   _cCodDoc := "" 
   _cDocFiltro := ""
   _cUltimaRv := "000"

   //====================================================================================================
   // Inicia processo de impressão.
   //====================================================================================================		
   While !TRBDOC->(Eof())
		
      If _oReport:Cancel()
		   Exit
      EndIf

      //===================================================================================
      // Se o usuário optar pela ulmiva revisão do documento. Este trecho filtra os dados.
      //===================================================================================
      If MV_PAR02 == 1 // Ultima revisão 

         If _cDocFiltro <> TRBDOC->QDH_DOCTO  
            _cDocFiltro := TRBDOC->QDH_DOCTO  
            _cUltimaRv := "000"

            _cQry2 := "SELECT MAX(QDH_RV) ULTIMARV "
            _cQry2 += " FROM " + RetSqlName("QDH") + " QDH "
            _cQry2 += " JOIN " + RetSqlName("QD1") + " QD1 ON QDH_DOCTO = QD1_DOCTO AND QDH_RV = QD1_RV  "
            _cQry2 += " WHERE QDH_DOCTO = '" + TRBDOC->QDH_DOCTO + "' "
            _cQry2 += " AND QDH.D_E_L_E_T_ = ' ' "
            _cQry2 += " AND QD1.D_E_L_E_T_ = ' ' "
            _cQry2 += " AND QD1_TPPEND IN ('E','R','A','I') "
          
            If Select("TRBFILTRO") <> 0
	            TRBFILTRO->(DBCloseArea())
            EndIf
	
            TCQUERY _cQry2 NEW ALIAS "TRBFILTRO"	
  
            _cUltimaRv := TRBFILTRO->ULTIMARV

            If Select("TRBFILTRO") <> 0
	            TRBFILTRO->(DBCloseArea())
            EndIf
         EndIf 

         If TRBDOC->QDH_RV <> _cUltimaRv
            TRBDOC->(DBSkip())
            Loop 
         EndIf 

      EndIf 

      //===================================
      // Gera o Relatório
      //===================================
      If TRBDOC->LIMITE >= Date()
         _cStatus := "Vigente"
      Else 
         _cStatus := "Obsoleto"
      EndIf 

      If _cCodDoc <> TRBDOC->QDH_DOCTO
         //====================================================================================================
         // Inicializando a primeira seção
         //====================================================================================================		 
	      _oSect1:Init()

	      _oReport:IncMeter()
	          
         //====================================================================================================
         // Imprimindo primeira seção "Data de emissão"
         //====================================================================================================		 
         IncProc("Imprimindo Dados do Documento: "+ TRBDOC->QDH_DOCTO)
		   
         If _cCodDoc <> "" 
            _oReport:ThinLine()
         EndIf 

         _oSect1:Cell("QDH_DOCTO"):SetValue(TRBDOC->QDH_DOCTO)		
         _oSect1:Cell("QDH_TITULO"):SetValue(TRBDOC->QDH_TITULO)		
         //_oSect1:Cell("QDH_RV"):SetValue(TRBDOC->QDH_RV)	
         _oSect1:Cell("QD3_DESCAS"):SetValue(TRBDOC->ASSUNTO)	
         _oSect1:Cell("QDH_DTIMPL"):SetValue(TRBDOC->IMPLANTACAO)	
         _oSect1:Cell("QDH_DTLIM"):SetValue(TRBDOC->LIMITE)	
         _oSect1:Cell("QA2_TEXTO"):SetValue(TRBDOC->QA2_TEXTO)	
         _oSect1:Cell("WK_STATUS"):SetValue(_cStatus)	
         _oSect1:PrintLine()
         _oReport:ThinLine()

         _cCodDoc := TRBDOC->QDH_DOCTO

      EndIf
     
      _oSect2:Init()
	   _oReport:IncMeter()
     
      _cNome := Posicione( "QAA" , 1 ,TRBDOC->QD1_FILMAT+TRBDOC->QD1_MAT , "QAA_NOME")
      
      _cCategor := TRBDOC->QD0_AUT
      If AllTrim(TRBDOC->QD0_AUT) == "E"
         _cCategor = "Elaborador" 
      ElseIf AllTrim(TRBDOC->QD0_AUT) == "R"
         _cCategor = "Revisor"
      ElseIf AllTrim(TRBDOC->QD0_AUT) == "A"
         _cCategor = "Aprovador"
      ElseIf AllTrim(TRBDOC->QD0_AUT) == "H"
         _cCategor = "Homologador"
      EndIf 
      
      _cRespon := Tabela("Q7",TRBDOC->QD1_TPPEND,.F.)

      IncProc("Imprimindo Responsáveis: " + AllTrim(TRBDOC->QD0_MAT+"-"+_cNome))

      _oSect2:Cell("QD0_AUT"):SetValue(_cCategor)
      _oSect2:Cell("QD0_MAT"):SetValue(TRBDOC->QD0_MAT)
      _oSect2:Cell("QDH_RV"):SetValue(TRBDOC->QDH_RV)
      _oSect2:Cell("WK_NOME"):SetValue(_cNome)
      _oSect2:Cell("QD1_DTBAIX"):SetValue(TRBDOC->QD1_DTBAIX)
      _oSect2:Cell("WK_RESPON"):SetValue(_cRespon)                                                      

      _oSect2:PrintLine()         
         
      TRBDOC->(DBSkip())
   EndDo		
   
   //====================================================================================================
   // Finaliza segunda seção.
   //====================================================================================================	
 	_oSect2:Finish()
 	//====================================================================================================
   // Imprime linha separadora.
   //====================================================================================================	
 	_oReport:ThinLine()
 	//====================================================================================================
   // Finaliza primeira seção.
   //====================================================================================================	 	  
	_oSect1:Finish()

End Sequence

Return
