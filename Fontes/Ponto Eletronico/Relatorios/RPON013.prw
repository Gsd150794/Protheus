/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |02/09/2021| Chamado 37603. Inclusao do filtro de situação Trabanhando / Desligado / Ambos.
Alex Wallauer |08/03/2023| Chamado 43096. Inclusao do filtro de Tipo de Relatorio Sintetico e Analitico (9 Campos novos).
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RPON013
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/08/2018                            .
Descrição---------: Relatório Empresas x Colaborador. Chamado 25734.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RPON013()

Local _oReport := nil
Private _aOrder := {"Empresa"}
Private _oSect0_A := Nil
Private _oSect1_A := Nil

Begin Sequence	

	SET DATE FORMAT TO "DD/MM/YYYY"

   Pergunte("RPON013",.F.)	          

   //====================================================================================================
   // Chama a montagem do relatório.
   //====================================================================================================	
   _oReport := RPON013D("RPON013")
   _oReport:PrintDialog()
	
End Sequence

Return

/*
===============================================================================================================================
Programa----------: RPON013D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/08/2018
Descrição---------: Realiza as definições do relatório. (ReportDef)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RPON013D(_cNome)
Local _oReport := Nil

Begin Sequence	
   _oReport := TReport():New(_cNome,"Relatório Empresas x Colaborador ",_cNome,{|_oReport| RPON013P(_oReport)},"Emissão do Relatório Empresas X Colaborador ")
   _oReport:SetLandscape()    
   _oReport:SetTotalInLine(.F.)

   //====================================================================================================
   // Define as totalizações e quebra por seção.
   //====================================================================================================	
   //TRFunction():New(oSection2:Cell("B1_COD"),NIL,"COUNT",,,,,.F.,.T.)
   _oReport:SetTotalInLine(.F.)
   
   _oSect0_A := TRSection():New(_oReport , "Relatório Empresas x Colaborador" , {},_aOrder , .F., .T.)
   TRCell():New(_oSect0_A,"CODIEMPRCONT" , "TRBCOL"  ,"Cod.Empr."            ,"@!",14)  
   TRCell():New(_oSect0_A,"NOMEEMPRCONT" , "TRBCOL"  ,"Empresa"              ,"@!",40)  
   
   _oSect0_A:SetTotalText(" ")
   _oSect0_A:Disable()
   
   _oSect1_A := TRSection():New(_oSect0_A , "Relatório Empresas x Colaborador" , {},_aOrder , .F., .T.)
   
   TRCell():New(_oSect1_A,"CODFILIAL"    , "TRBCOL"  , "Cod.Filial"          ,"@!",010) 
   TRCell():New(_oSect1_A,"DESCFILIAL"   , "TRBCOL"  , "Nome Filial"         ,"@!",014) 
   TRCell():New(_oSect1_A,"CODIMATR"     , "TRBCOL"  , "Matricula"           ,"@!",100)               
   TRCell():New(_oSect1_A,"IDCOLAB"	     , "TRBCOL"  , "Id.Colaborador"      ,"@!",014)  
   TRCell():New(_oSect1_A,"NOMEPESS"	  , "TRBCOL"  , "Nome"                ,"@!",035)   
   TRCell():New(_oSect1_A,"ICARD"        , "TRBCOL"  , "Numero Crachá"       ,"@!",014) 
   TRCell():New(_oSect1_A,"DATAINIC"     , "TRBCOL"  , "Data Inicial"        ,"@!",014) 
   TRCell():New(_oSect1_A,"DATAFINA"     , "TRBCOL"  , "Data Final"          ,"@!",014) 
   TRCell():New(_oSect1_A,"DESCTIPOCOLA" , "TRBCOL"  , "Tipo Colaborador"    ,"@!",035)   
   TRCell():New(_oSect1_A,"DESCSITU"	  , "TRBCOL"  , "Situação Trabalhista","@!",025)   
   TRCell():New(_oSect1_A,"TIPOCONT"	  , "TRBCOL"  , "Tipo de Contrato"    ,"@!",016)    
   TRCell():New(_oSect1_A,"SEXOCOLA"	  , "TRBCOL"  , "Sexo"                ,"@!",014)     
   TRCell():New(_oSect1_A,"DATANASC"	  , "TRBCOL"  , "Data Nascimento"     ,"@!",014)     
   TRCell():New(_oSect1_A,"APELEMPRCONT" , "TRBCOL"  , "Nome Fantasia"       ,"@!",100)                   
   TRCell():New(_oSect1_A,"NUMETELE"     , "TRBCOL"  , "Telefone"            ,"@!",100)               
   TRCell():New(_oSect1_A,"MAILCONT"     , "TRBCOL"  , "E-Mail"              ,"@!",100)               
   TRCell():New(_oSect1_A,"CONTEMPR"     , "TRBCOL"  , "Contato"             ,"@!",100)               
   TRCell():New(_oSect1_A,"NUMEDOCU"     , "TRBCOL"  , "Inscrição"           ,"@!",100) 
   TRCell():New(_oSect1_A,"DATAVALIASO"  , "TRBCOL"  , "Validade ASO"        ,"@!",100)                  
   TRCell():New(_oSect1_A,"DATATREISEGU" , "TRBCOL"  , "Vld Trein. Serurança","@!",100)                   
   TRCell():New(_oSect1_A,"TIPOTERC"     , "TRBCOL"  , "Tipo"                ,"@!",100)               
   
   _oSect1_A:SetTotalText(" ")
   _oSect1_A:Disable()

End Sequence
					
Return(_oReport)

/*
===============================================================================================================================
Programa----------: RPON013P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/08/2018
Descrição---------: Realiza a impressão do relatório. (ReportPrint)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RPON013P(_oReport)
Local _cQry   := ""		
Local _cOrder := ""
Local _nI, _aFiliais := FwLoadSM0()
Local _cCodFil, _cDescFilial
Local _cCodEmpresa
Local _nTotAtivos, _nTotInativos, _nTotGeral , _nTotGAtivos, _nTotGInativos
Local _cSexo

Begin Sequence                    
   //====================================================================================================
   // Ativa a seção do relatório conforme a ordem de emissão do relatório.
   //====================================================================================================	
   _cOrder := " ORDER BY F.CODIEMPRCONT, B.NOMEPESS "

   _oSect0_A:Enable() 
   _oSect1_A:Enable()

   If MV_PAR05 = 1
      _oSect1_A:Cell("CODIMATR"    ):Disable()
      _oSect1_A:Cell("APELEMPRCONT"):Disable()
      _oSect1_A:Cell("NUMETELE"    ):Disable()
      _oSect1_A:Cell("MAILCONT"    ):Disable()
      _oSect1_A:Cell("CONTEMPR"    ):Disable()
      _oSect1_A:Cell("NUMEDOCU"    ):Disable()
      _oSect1_A:Cell("DATAVALIASO" ):Disable()
      _oSect1_A:Cell("DATATREISEGU"):Disable()
      _oSect1_A:Cell("TIPOTERC"    ):Disable()
   EndIf
      
   //====================================================================================================
   // Monta a query de dados.
   //====================================================================================================	
   _cQry := " SELECT "
   _cQry += " A.IDCOLAB, " 
   _cQry += " A.IDPESSOA, " 
   _cQry += " B.NOMEPESS, "
   _cQry += " A.CODIEMPR, "
   _cQry += " A.TIPOCOLA, "
   _cQry += " E.DESCTIPOCOLA, " 
   _cQry += " A.APELCOLA, "    
   _cQry += " A.DATAADMI, "    
   _cQry += " A.SITUAFAS, "    
   _cQry += " C.DESCSITU, "    
   _cQry += " A.DATAAFAS, "    
   _cQry += " A.HORAAFAS, "  
   _cQry += " A.TIPOCONT, " 
   _cQry += " A.SEXOCOLA, "  
   _cQry += " A.DATANASC, "  
   _cQry += " F.CODIEMPRCONT, "
   _cQry += " F.NOMEEMPRCONT, "
   If MV_PAR05 = 2
      _cQry+="F.APELEMPRCONT, "
      _cQry+="F.NUMETELE, "
      _cQry+="F.MAILCONT, "
      _cQry+="F.CONTEMPR, "
      _cQry+="F.NUMEDOCU, "//CNPJ OU CPF
      _cQry+="I.DATAVALIASO, "
      _cQry+="I.DATATREISEGU, "
      _cQry+="A.CODIMATR, "
      _cQry+="A.TIPOCONT, "
      _cQry+="A.TIPOTERC, "
   EndIf
   _cQry += " H.ICARD, "
   _cQry += " H.DATAINIC, "
   _cQry += " H.DATAFINA "
   _cQry += " FROM SURICATO.TBCOLAB A, SURICATO.TBPESSOA B, SURICATO.TBSITUA C, SURICATO.TBCONTR D, SURICATO.TBTIPOCOLAB E, SURICATO.TBEMPREPREST F, SURICATO.TBHISTOCONTR G, SURICATO.TBHISTOCRACH H, SURICATO.TBACESSCOLAB I "
   _cQry += " WHERE A.IDPESSOA = B.IDPESSOA "
   _cQry += " AND A.TIPOCOLA = E.TIPOCOLA  "
   _cQry += " AND A.IDCOLAB = I.IDCOLAB  "
   _cQry += " AND A.SITUAFAS = C.CODISITU  "
   _cQry += " AND D.CODIEMPRCONT = F.CODIEMPRCONT "
   _cQry += " AND D.IDCONT = G.IDCONT "
   _cQry += " AND A.IDCOLAB = G.IDCOLAB "
   _cQry += " AND H.IDCOLAB = A.IDCOLAB "
   _cQry += " AND (A.TIPOCOLA = 2 OR A.TIPOCOLA = 3) " 

   If MV_PAR02 == 1 // Tipo de Colaborador 
      _cQry += " AND A.TIPOCOLA = 2 "  // Terceiro
   ElseIf MV_PAR02 == 2
      _cQry += " AND A.TIPOCOLA = 3 "  // Parceiro
   EndIf
   
   If ! Empty(MV_PAR03) //  Numero Cracha
      _cQry += " AND H.ICARD = '"+AllTrim(MV_PAR03)+"' "
   EndIf
   
   _cQry := _cQry + _cOrder
   
   If Select("TRBCOL") <> 0
	  TRBCOL->(DBCloseArea())
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQry) , "TRBCOL" , .T. , .F. )
   	
   DBSelectArea("TRBCOL")
   TRBCOL->(DBGoTop())

   Count to _ntotRegs	
   _oReport:SetMeter(_ntotRegs)	
   
   _nTotGeral    := 0
   _nTotGAtivos   := 0 
   _nTotGInativos := 0
   
   //====================================================================================================
   // Inicia processo de impressão.
   //====================================================================================================		
   TRBCOL->(DBGoTop())
   
   While !TRBCOL->(Eof())
		
      If _oReport:Cancel()
		 Exit
      EndIf

	  _oReport:IncMeter()
	  
	  //====================================================================================================
      // Inicializando a primeira seção
      //====================================================================================================		 
      _oSect0_A:Init()
      
	  _oSect0_A:Cell("CODIEMPRCONT"):SetValue(TRBCOL->CODIEMPRCONT) // Codigo da empresa
      _oSect0_A:Cell("NOMEEMPRCONT"):SetValue(TRBCOL->NOMEEMPRCONT) // Nome da empresa
	  _oSect0_A:PrintLine()
	  
	  _oSect1_A:Init()
      
      _nTotAtivos    := 0
      _nTotInativos  := 0
      
      
      _cCodEmpresa := TRBCOL->CODIEMPRCONT

      While ! TRBCOL->(Eof()) .And. _cCodEmpresa == TRBCOL->CODIEMPRCONT
         _cCodFil := StrZero(TRBCOL->CODIEMPR,2)
         
         //====================================================================================================
         // Filtro por filial
         //====================================================================================================		   
         If ! Empty(MV_PAR01) // Nome Colaborador
            If ! _cCodFil $ MV_PAR01
               TRBCOL->(DBSkip())
               Loop
            EndIf
         EndIf
         
         _nTotGeral     += 1
         
         If Year(TRBCOL->DATAFINA) = 1900 .Or. TRBCOL->DATAFINA > Date() //1-TRABALHANDO 
             If MV_PAR04 = 2
               TRBCOL->(DBSkip())
               Loop
             EndIf
            _nTotAtivos    += 1
            _nTotGAtivos   += 1 
         Else//2-DESLIGADO 
             If MV_PAR04 = 1
               TRBCOL->(DBSkip())
               Loop
             EndIf
            _nTotGInativos += 1
            _nTotInativos  += 1
         EndIf
         _oReport:IncMeter()
          
	     _cCodFil := StrZero(TRBCOL->CODIEMPR,2)
	  
	     _nI := aScan(_aFiliais,{|x| x[5] == _cCodFil})
	     If _nI > 0 
	        _cDescFilial := _cCodFil + "-" + _aFiliais[_nI,7]
	     Else
	        _cDescFilial := _cCodFil
	     EndIf

         _oSect1_A:Cell("CODFILIAL"):SetValue(_cCodFil)                // Cod.Filial   
         _oSect1_A:Cell("DESCFILIAL"):SetValue(_cDescFilial)           // Filialr
         _oSect1_A:Cell("IDCOLAB"):SetValue(TRBCOL->IDCOLAB)           // Id.Colaborador
         _oSect1_A:Cell("NOMEPESS"):SetValue(TRBCOL->NOMEPESS)         // Nome
         _oSect1_A:Cell("ICARD"):SetValue(TRBCOL->ICARD)               // Numero Crachá
         _oSect1_A:Cell("DATAINIC"):SetValue(TRBCOL->DATAINIC)         // Data Inicial
         _oSect1_A:Cell("DATAFINA"):SetValue(TRBCOL->DATAFINA)         // Data Final
         _oSect1_A:Cell("DESCTIPOCOLA"):SetValue(TRBCOL->DESCTIPOCOLA) // Tipo Colaborador
         
         If Year(TRBCOL->DATAFINA) = 1900 .Or. TRBCOL->DATAFINA > Date() //1-TRABALHANDO 
            _cDESCSITU := "TRABALHANDO"
         Else//2-DESLIGADO 
            _cDESCSITU := "DESLIGADO"
         EndIf
         _oSect1_A:Cell("DESCSITU"):SetValue(_cDESCSITU)     // Situação Trabalhista
         
         If Upper(AllTrim(TRBCOL->SEXOCOLA)) == "M"
            _cSexo := "MASCULINO"
         Else
            _cSexo := "FEMININO"
         EndIf
         
         _oSect1_A:Cell("SEXOCOLA"):SetValue(_cSexo)               // Sexo  // SetValue(TRBCOL->SEXOCOLA)
         _oSect1_A:Cell("DATANASC"):SetValue(TRBCOL->DATANASC)     // Data Nascimento

         TpContrato := ""
         If TRBCOL->TIPOCONT = 1
            TpContrato := "Colaborador"
         ElseIf TRBCOL->TIPOCONT = 2
            TpContrato := "Diretor"
         ElseIf TRBCOL->TIPOCONT = 3
            TpContrato := "Estagiario"
         ElseIf TRBCOL->TIPOCONT = 4
            TpContrato := "Menor aprendiz"
         ElseIf TRBCOL->TIPOCONT = 5
            TpContrato := "Prazo determinado"
         ElseIf TRBCOL->TIPOCONT = 6
            TpContrato := "Diretor aposentado"
         ElseIf TRBCOL->TIPOCONT = 7
            TpContrato := "Cooperado"
         EndIf
         _oSect1_A:Cell("TIPOCONT"):SetValue(TpContrato) // Tipo de Contrato
         
        If MV_PAR05 = 2
           _oSect1_A:Cell("APELEMPRCONT"):SetValue(TRBCOL->APELEMPRCONT)
           _oSect1_A:Cell("NUMETELE"    ):SetValue(TRBCOL->NUMETELE   )
           _oSect1_A:Cell("MAILCONT"    ):SetValue(TRBCOL->MAILCONT   )
           _oSect1_A:Cell("CONTEMPR"    ):SetValue(TRBCOL->CONTEMPR   )
           _oSect1_A:Cell("NUMEDOCU"    ):SetValue(TRBCOL->NUMEDOCU   )
           _oSect1_A:Cell("DATAVALIASO" ):SetValue(TRBCOL->DATAVALIASO)
           _oSect1_A:Cell("DATATREISEGU"):SetValue(TRBCOL->DATATREISEGU)
           _oSect1_A:Cell("CODIMATR"    ):SetValue(TRBCOL->CODIMATR   )
        
           TpTerceiro := ""
           If TRBCOL->TIPOTERC = 1
              TpTerceiro := "Temporario"
           ElseIf TRBCOL->TIPOTERC = 2
              TpTerceiro := "Frequente"
           ElseIf TRBCOL->TIPOTERC = 3
              TpTerceiro := "Pountual"
           EndIf
           _oSect1_A:Cell("TIPOTERC"):SetValue(TpTerceiro) 
     
	     EndIf
  
	     _oSect1_A:PrintLine()
         
         TRBCOL->(DBSkip())
      EndDo
      
      //====================================================================================================
      // Imprime linha separadora e subtotais.
      //====================================================================================================	
      _oReport:ThinLine()
      _oReport:PrintText("Subtotal Ativos e Desligados: "+AllTrim(Str(_nTotAtivos + _nTotInativos,12)))
      _oReport:PrintText("Subtotal Ativos.............: "+AllTrim(Str(_nTotAtivos,12)))
      _oReport:PrintText("Subtotal Desligados.........: "+AllTrim(Str(_nTotInativos,12)))
      
      
      //====================================================================================================
      // Finaliza segunda seção.
      //====================================================================================================	
 	  _oSect1_A:Finish()
 	  
 	  //====================================================================================================
      // Imprime linha separadora.
      //====================================================================================================	
 	  _oReport:ThinLine()
 	  
 	  //====================================================================================================
      // Finaliza primeira seção.
      //====================================================================================================	 	  
	  _oSect0_A:Finish()
      
   EndDo		
      
   //====================================================================================================
   // Imprime linha separadora.
   //====================================================================================================	
   _oReport:ThinLine()
   _oReport:PrintText("Total Ativos e Desligados: "+AllTrim(Str(_nTotGAtivos + _nTotGInativos ,12)))
   _oReport:PrintText("Total Ativos.............: "+AllTrim(Str(_nTotGAtivos,12)))
   _oReport:PrintText("Total Desligados.........: "+AllTrim(Str(_nTotGInativos,12)))
   
   //====================================================================================================
   // Finaliza primeira seção.
   //====================================================================================================	 	  
   _oSect0_A:Finish()
   _oSect1_A:Finish()

End Sequence

Return
