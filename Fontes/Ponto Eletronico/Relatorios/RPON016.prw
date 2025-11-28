/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |14/09/2021| Chamado 37715. Retirada da gravacao do SX1.
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RPON016
Autor-------------: Alex Wallauer
Data da Criacao---: 03/09/2021                            .
Descrição---------: Relatório Empresas x Colaborador. Chamado 37671
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RPON016()

Local _oReport := nil
Private _oSect0_A := Nil
Private _oSect1_A := Nil

SET DATE FORMAT TO "DD/MM/YYYY"

While Pergunte("RPON016",,"Relatório Empresas x Colaborador")	          

   If Empty(MV_PAR04) .Or.  Empty(MV_PAR05) .Or.  MV_PAR04 > MV_PAR05
      U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo com as 2 datas preenchidas",3)
      Loop
   EndIf

   // Chama a montagem do relatório.
   _lSair:=.F.
   _oReport := RPON016D("RPON016")
   _oReport:PrintDialog()
   If _lSair
      Exit
   EndIf   

EndDo

Return

/*
===============================================================================================================================
Programa----------: RPON016D
Autor-------------: Alex Wallauer
Data da Criacao---: 03/09/2021
Descrição---------: Realiza as definições do relatório. (ReportDef)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RPON016D(_cPrograma)

Local _oReport := Nil

_oReport := TReport():New(_cPrograma,"Relatório Empresas x Colaborador",_cPrograma,{|_oReport| RPON016P(_oReport)},"Emissão do Relatório Empresas X Colaborador ")
_oReport:SetLandscape()    
_oReport:SetTotalInLine(.F.)

//====================================================================================================
// Define as totalizações e quebra por seção.
//====================================================================================================	
//TRFunction():New(oSection2:Cell("B1_COD"),NIL,"COUNT",,,,,.F.,.T.)
_oReport:SetTotalInLine(.F.)


_oSect0_A := TRSection():New(_oReport , "Relatório Empresas x Colaborador" , {}, , .F., .T.)
TRCell():New(_oSect0_A,"CODIEMPRCONT" , "TRBCOL"  ,"Cod.Empr.","@!",14)  
TRCell():New(_oSect0_A,"NOMEEMPRCONT" , "TRBCOL"  ,"Empresa","@!",40)  

_oSect0_A:SetTotalText(" ")
_oSect0_A:Disable()

_oSect1_A := TRSection():New(_oSect0_A , "Relatório Empresas x Colaborador" , {}, , .F., .T.)

TRCell():New(_oSect1_A,"DESCFILIAL"   , "TRBCOL"  ,"Filial"              ,"@!",014) 
TRCell():New(_oSect1_A,"IDCOLAB"	     , "TRBCOL"  ,"Id.Colaborador"      ,"@!",014)  
TRCell():New(_oSect1_A,"NOMEPESS"	 , "TRBCOL"  ,"Nome"                ,"@!",035)   
TRCell():New(_oSect1_A,"ICARD"        , "TRBCOL"  ,"Numero Crachá"       ,"@!",014) 
TRCell():New(_oSect1_A,"DESCTIPOCOLA" , "TRBCOL"  ,"Tipo Colaborador"    ,"@!",035)   
TRCell():New(_oSect1_A,"DESCSITU"	 , "TRBCOL"  ,"Situação Trabalhista","@!",025)   
TRCell():New(_oSect1_A,"JORNADA"	     , "TRBCOL"  ,"Jornada"             ,"@!",006)   
TRCell():New(_oSect1_A,"INTERVALO"	 , "TRBCOL"  ,"Intervalo"           ,"@!",006)   
TRCell():New(_oSect1_A,"DATAINIC"     , "TRBCOL"  ,"Data Acesso"        ,"@!",014) 
TRCell():New(_oSect1_A,"MARCACAO"	 , "TRBCOL"  ,"Marcações"           ,"@!",100)   

_oSect1_A:SetTotalText(" ")
_oSect1_A:Disable()
					
Return(_oReport)

/*
===============================================================================================================================
Programa----------: RPON016P
Autor-------------: Alex Wallauer
Data da Criacao---: 03/09/2021
Descrição---------: Realiza a impressão do relatório. (ReportPrint)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RPON016P(_oReport)
Local _cQry   := ""		
Local _cOrder := ""
Local _cCodEmpresa , D
Local _nTotAtivos, _nTotInativos, _nTotGAtivos, _nTotGInativos

//====================================================================================================
// Ativa a seção do relatório conforme a ordem de emissão do relatório.
//====================================================================================================	
_cOrder := " ORDER BY F.CODIEMPRCONT, B.NOMEPESS, H.DATAINIC "

_oSect0_A:Enable() 
_oSect1_A:Enable()
   
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
_cQry += " A.SITUAFAS, "    
_cQry += " C.DESCSITU, "    
_cQry += " F.CODIEMPRCONT, "
_cQry += " F.NOMEEMPRCONT, "
_cQry += " H.ICARD, "
_cQry += " H.DATAINIC, "
_cQry += " H.DATAFINA "
_cQry += " FROM SURICATO.TBCOLAB A, SURICATO.TBPESSOA B, SURICATO.TBSITUA C, SURICATO.TBCONTR D, SURICATO.TBTIPOCOLAB E, SURICATO.TBEMPREPREST F, SURICATO.TBHISTOCONTR G, SURICATO.TBHISTOCRACH H "
_cQry += " WHERE A.IdPessoa     = B.IdPessoa  "
_cQry += "   AND A.TipoCola     = E.TipoCola  "
_cQry += "   AND A.SituAfas     = C.CodiSitu  "
_cQry += "   AND D.CODIEMPRCONT = F.CODIEMPRCONT "
_cQry += "   AND D.IDCONT       = G.IDCONT  "
_cQry += "   AND A.IDCOLAB      = G.IDCOLAB "
_cQry += "   AND H.IDCOLAB      = A.IDCOLAB "
_cQry += "   AND (A.TIPOCOLA = 2 OR A.TIPOCOLA = 3) " 

If MV_PAR01 == 1 // Tipo de Colaborador 
   _cQry += " AND A.TIPOCOLA = 2 "  // Terceiro
ElseIf MV_PAR01 == 2
   _cQry += " AND A.TIPOCOLA = 3 "  // Parceiro
EndIf

If ! Empty(MV_PAR02) //  Numero Cracha
   _cQry += " AND H.ICARD = '"+AllTrim(MV_PAR02)+"' "
EndIf

_cQry := _cQry + _cOrder

If Select("TRBCOL") <> 0
   TRBCOL->(DBCloseArea())
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQry) , "TRBCOL" , .T. , .F. )
   
DBSelectArea("TRBCOL")
TRBCOL->(DBGoTop())

Count to _ntotRegs	
If _ntotRegs = 0 
   _lSair:=.F.
   Return .F.
EndIf
   _cTot:=AllTrim(Str(_ntotRegs))
   _nTam:=Len(_cTot)+1
   _nConta:=0
_oReport:SetMeter(_ntotRegs)	

_aFiliais      := FwLoadSM0()
_nTotGAtivos   := 0 
_nTotGInativos := 0
_nMarca        :=0
//====================================================================================================
// Inicia processo de impressão.
//====================================================================================================		
TRBCOL->(DBGoTop())


While !TRBCOL->(Eof())
   
   //====================================================================================================
   // Inicializando a primeira seção
   //====================================================================================================		 
   _oSect0_A:Init()
   
   _oSect0_A:Cell("CODIEMPRCONT"):SetValue(TRBCOL->CODIEMPRCONT) // Codigo da empresa
   _oSect0_A:Cell("NOMEEMPRCONT"):SetValue(TRBCOL->NOMEEMPRCONT) // Nome da empresa
   _oSect0_A:PrintLine()
   
   _oSect1_A:Init()
   
   _cCodEmpresa := TRBCOL->CODIEMPRCONT
   _nTotAtivos  := 0
   _nTotInativos:= 0

   While ! TRBCOL->(Eof()) .And. _cCodEmpresa == TRBCOL->CODIEMPRCONT
      
      _nConta++
      _oReport:IncMeter()
      _oReport:SetMsgPrint("Lendo : "+AllTrim(Str(_nConta,_nTam)) +" de "+ _cTot)
   
      If Year(TRBCOL->DATAFINA) = 1900 .Or. TRBCOL->DATAFINA > Date() //1-TRABALHANDO 
            If MV_PAR03 = 2
            TRBCOL->(DBSkip())
            Loop
            EndIf
         _nTotAtivos    += 1
         _nTotGAtivos   += 1 
      Else//2-DESLIGADO 
            If MV_PAR03 = 1
            TRBCOL->(DBSkip())
            Loop
            EndIf
         _nTotGInativos += 1
         _nTotInativos  += 1
      EndIf
         
      //_cCodFilCad := StrZero(TRBCOL->CODIEMPR,2)
      
      If Year(TRBCOL->DATAFINA) = 1900 .Or. TRBCOL->DATAFINA > Date() //1-TRABALHANDO 
         _cDESCSITU := "TRABALHANDO"
      Else//2-DESLIGADO 
         _cDESCSITU := "DESLIGADO"
      EndIf

      _aDados:={}
      _cDescFilial:=""
      FWMsgRun( ,{|oproc| _aDados := RPON016SEL(oproc,TRBCOL->IDCOLAB,TRBCOL->NOMEPESS) } , "Aguarde!" , "Lendo Marcacoes do "+AllTrim(TRBCOL->NOMEPESS) )
   
      If Len(_aDados) > 0 
         For D := 1 TO Len(_aDados)
               _oSect1_A:Cell("DESCFILIAL"  ):SetValue(AllTrim(_cDescFilial))//+" ["+_cCodFilCad+"]")// Filial
               _oSect1_A:Cell("IDCOLAB"     ):SetValue(TRBCOL->IDCOLAB)      // Id.Colaborador
               _oSect1_A:Cell("NOMEPESS"    ):SetValue(TRBCOL->NOMEPESS)     // Nome
               _oSect1_A:Cell("ICARD"       ):SetValue(TRBCOL->ICARD)        // Numero Crachá
               _oSect1_A:Cell("DESCTIPOCOLA"):SetValue(TRBCOL->DESCTIPOCOLA) // Tipo Colaborador
               _oSect1_A:Cell("DESCSITU"):SetValue(_cDESCSITU)               // Situação Trabalhista	  
               _oSect1_A:Cell("JORNADA"  ):SetValue(_aDados[D,8])   
               _oSect1_A:Cell("INTERVALO"):SetValue(_aDados[D,9])   
            //_oSect1_A:Cell("DATAINI2" ):SetValue(TRBCOL->DATAINIC)        // Data Origem
            //_oSect1_A:Cell("DATAFINA" ):SetValue(TRBCOL->DATAFINA)        // Data Final
               _oSect1_A:Cell("DATAINIC" ):SetValue(_aDados[D,6])            // Data 
               _oSect1_A:Cell("MARCACAO" ):SetValue(_aDados[D,7]) 
               _oSect1_A:PrintLine()
               _nMarca++
         Next		 
         _lSair:=.T.
      EndIf  
      
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
_oReport:PrintText("Total Ativos e Desligados: "+AllTrim(Str(_nTotGAtivos + _nTotGInativos)))
_oReport:PrintText("Total Ativos.............: "+AllTrim(Str(_nTotGAtivos)))
_oReport:PrintText("Total Desligados.........: "+AllTrim(Str(_nTotGInativos)))
_oReport:PrintText("Total Marcações na Filial Atual : "+AllTrim(Str(_nMarca)))


//====================================================================================================
// Finaliza primeira seção.
//====================================================================================================	 	  
_oSect0_A:Finish()
_oSect1_A:Finish()

_cMSG:=+CHR(13)+CHR(10)
_cMSG+="Total Ativos : "+AllTrim(Str(_nTotGAtivos))+CHR(13)+CHR(10)
_cMSG+="Total Desligados : "+AllTrim(Str(_nTotGInativos))+CHR(13)+CHR(10)
_cMSG+="Total Ativos e Desligados : "+AllTrim(Str(_nTotGAtivos + _nTotGInativos))+CHR(13)+CHR(10)
_cMSG+="Total Marcações na Filial Atual : "+AllTrim(Str(_nMarca))+CHR(13)+CHR(10)

U_ITMsg("LEITURA CONCLUIDA COM SUCESSO"+_cMSG,'LEITURA OK',,2)

Return .T.


/*
===============================================================================================================================
Programa----------: RPON016SEL
Autor-------------: Alex Wallauer
Data da Criacao---: 03/09/2021
Descrição---------: Carga de dados para o relatório
Parametros--------: oproc - objeto da barra de processmento / idcolab
Retorno-----------: _aRet - dados coletados do banco
===============================================================================================================================
*/
Static Function RPON016SEL(oproc,nidcolab,_cNome,_cCodFil)

Local _aRet			:= {}
Local _cAlias3		:= GetNextAlias()
Local _cAlias4		:= GetNextAlias()
Local _cQuery		:= ""
Local _nnj			:= 0
Local _nnd			:= 0 , _nnh
Local _aDados     := {}

Default oproc := nil

If ValType(oproc) = "O"
   oproc:cCaption := ("Lendo funcionários " + AllTrim(_cNome) + "...")
   ProcessMessages()
EndIf
//Carrega crachas do funcionario no periodo
_cQuery :=  "select icard,datainic,horainic,datafina,horafina FROM SURICATO.TBHISTOCRACH 
_cQuery +=  " WHERE IDCOLAB  = " + AllTrim(Str(nidcolab))   
_cQuery +=  " and  datainic <= TO_DATE('" + DToS(MV_PAR05) + "', 'yyyymmdd') "
_cQuery +=  " and (datafina >= TO_DATE('" + DToS(MV_PAR05) + "', 'yyyymmdd') "
_cQuery +=  " or   datafina  = TO_DATE('19001231', 'yyyymmdd')) "

If Select(_cAlias3) > 0

   DBSelectArea(_cAlias3)
   (_cAlias3)->(DBCloseArea())

EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias3 , .T. , .F. )
DBSelectArea(_cAlias3)

_acrachas := {}

While (_cAlias3)->( !Eof() )

   aAdd(_acrachas, {(_cAlias3)->icard,(_cAlias3)->datainic,(_cAlias3)->horainic,(_cAlias3)->datafina,(_cAlias3)->horafina} )
   
   (_cAlias3)->(DBSkip())
   
EndDo
      
If Len(_acrachas) > 0

   //Carrega marcações do funcionario no periodo
   For _nnj := 1 to Len(_acrachas)
   
      _cQuery :=	" SELECT DATAACES,HORAACES,DIREACES,CODICOLE, P.CODIEMPR "
      _cQuery +=	" FROM   SURICATO.TBMARCAACESS M, SURICATO.TBPLANT P " 
      _cQuery +=	" WHERE  M.CODIPLAN = P.CODIPLAN "
      _cQuery +=	" AND    DATAACES >= TO_DATE('" + DToS(MV_PAR04) + "', 'yyyymmdd') " //data inicio do relatorio 
      _cQuery +=	" AND    DATAACES <= TO_DATE('" + DToS(MV_PAR05) + "', 'yyyymmdd') " //data fim do relatorio 
      _cQuery +=	" AND ( (DATAACES  = TO_DATE('" + DToS(_acrachas[_nnj][2]) + "', 'yyyymmdd') "
      _cQuery +=	" AND    HORAACES >= 1) "
      _cQuery +=	" OR     DATAACES  > TO_DATE('" + DToS(_acrachas[_nnj][2]) + "', 'yyyymmdd') ) " //data inicio do cracha
      
      //inclui filtro de data final do cracha só se a data final For diferente 31/12/1900
      If DToS(_acrachas[_nnj][4]) != "19001231"					
         _cQuery +=	" and ( ( dataaces = TO_DATE('" + DToS(_acrachas[_nnj][4]) + "', 'yyyymmdd') and horaaces <= 1) "
         _cQuery +=	"      or dataaces < TO_DATE('" + DToS(_acrachas[_nnj][4]) + "', 'yyyymmdd')) " //data final do cracha						
      EndIf
      
      _cQuery +=	" and icard = " + AllTrim(Str(_acrachas[_nnj][1])) 
      _cQuery +=  " and tipoaces = 1 " //Acesso com sucesso na catraca
      //cFilSalva:=cFilAnt
      //cFilAnt  :=_cCodFil
      _cQuery  +=  " and codicole in  " + FormatIn(u_itgetmv("ITCATRAC","1;2"),";") 
      //cFilAnt  :=cFilSalva					
      _cQuery +=  " ORDER BY dataaces,horaaces"

      If Select(_cAlias4) > 0

         DBSelectArea(_cAlias4)
         (_cAlias4)->(DBCloseArea())

      EndIf

      DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias4 , .T. , .F. )
      DBSelectArea(_cAlias4)
      
      ajorns := {}
      _dultima := (_cAlias4)->dataaces
      
      While (_cAlias4)->( !Eof() )

            _cCodFil := StrZero((_cAlias4)->CODIEMPR,2)

         // Filtro da filial
         If _cCodFil <> cFilAnt
            (_cAlias4)->(DBSkip())
               Loop
         EndIf
         _nI := aScan(_aFiliais,{|x| x[5] == _cCodFil})
         If _nI > 0 
            _cDescFilial := _cCodFil + "-" + _aFiliais[_nI,7]
         Else
            _cDescFilial := _cCodFil
         EndIf

         _nhoras := int((_cAlias4)->horaaces / 60)
         _nminutos :=  (_cAlias4)->horaaces - ((int((_cAlias4)->horaaces / 60))*60) 
         _choras := (_cAlias4)->direaces +"("+AllTrim(Str((_cAlias4)->CODICOLE))+") "+ StrZero(_nhoras,2) + ":" + StrZero(_nminutos,2)
      
         If (_cAlias4)->dataaces == _dultima
      
            If (_cAlias4)->direaces == "E"
            
               If Len(ajorns) = 0 .Or. (Len(ajorns) > 0 .And. ajorns[Len(ajorns)][2] >= 0) //Validação contra dupla marcação de entrada
         
                  aAdd(ajorns,{(_cAlias4)->horaaces,-1})
                  
               EndIf
               
            ElseIf (_cAlias4)->direaces == "S" .And. Len(ajorns) > 0 .And. ajorns[Len(ajorns)][2] = -1
            
               ajorns[Len(ajorns)][2] := (_cAlias4)->horaaces
               
            EndIf
            
         Else
         
            //Se virou o dia sem sair da fabrica marca final da jornada do dia as 23:59
            If (_cAlias4)->direaces == "S" .And. Len(ajorns) > 0 .And. ajorns[Len(ajorns)][2] = -1
            
               ajorns[Len(ajorns)][2] := 1439
               
            EndIf
            
            //Soma total da jornada e intervalo do dia
            _ntotdia := 0
            _nintdia := 0
            
            For _nnd := 1 to Len(ajorns)
            
               If ajorns[_nnd][1] >= 0 .And. ajorns[_nnd][2] >= 0
               
                  _ntotdia := _ntotdia + ajorns[_nnd][2] - ajorns[_nnd][1]
                  
                  If _nnd > 1
                  
                     _nintdia := _nintdia + ajorns[_nnd][1] - ajorns[_nnd-1][2]
                  
                  EndIf
                  
               EndIf
            
            Next
            
            //Registra jornada do dia e reinicia contador 
            _nnk := aScan(_aRet,{|_vAux| _vAux[1]==AllTrim(_cCodFil) .and.;
                                          _vAux[3]==AllTrim(Str(nidcolab))  .AND.;
                                    _vAux[9]==AllTrim(DToC(_dultima)) }) 
            
            _aRet[_nnk][11] :=   StrZero(int(_ntotdia/60),2) + ":" + StrZero(_ntotdia-(int(_ntotdia/60)*60),2)
            _aRet[_nnk][12] :=   StrZero(int(_nintdia/60),2) + ":" + StrZero(_nintdia-(int(_nintdia/60)*60),2)
            
            ajorns := {}
            
            //Se virou o dia sem sair da fabrica registra entrada à 12:00 
            If (_cAlias4)->direaces == "S" 
            
               aAdd(ajorns,{0,(_cAlias4)->horaaces})
               
            Else
            
               aAdd(ajorns,{(_cAlias4)->horaaces,-1})
            
            EndIf
            
            //vira ultimo dia
            _dultima := (_cAlias4)->dataaces
         
         EndIf
      
         _nnp := aScan(_aRet,{|_vAux| _vAux[1]==AllTrim(_cCodFil) .and.;
                                       _vAux[3]==AllTrim(Str(nidcolab)) .AND.;
                                 _vAux[9]==AllTrim(DToC((_cAlias4)->dataaces)) }) 
      
         If Len(AllTrim(_choras)) > 45
         
            _choras := SubStr(AllTrim(_choras),1,45) + "..."
            
         EndIf
      
         If _nnp == 0
      
            aAdd(_aRet,{_cCodFil	                                ,; //01-Filial
                        AllTrim(StrZero(_acrachas[_nnj][1],11))     ,; //02-CRACHA
                        AllTrim(Str(nidcolab))					    ,; //03-Matrícula
                        AllTrim(Capital(AllTrim(_cNome)))           ,; //04-Funcionário
                        ""                                          ,; //05-Desc. Funçao 
                        ""                                          ,; //06-Codigo Setor 
                        ""				                            ,; //07-Desc. Setor
                        ""			                                ,; //08-Dt Admissao 
                        AllTrim(DToC((_cAlias4)->DATAACES))	        ,; //09-Data do Apontamento
                        AllTrim(_choras)					        ,; //10-Marcações da Data
                        AllTrim(" ")						        ,; //11-Jornada
                        AllTrim(" ")				                }) //12-Intervalo
         
         Else
         
            _aRet[_nnp][10] := _aRet[_nnp][10] + " - " + _choras
         
         EndIf
         
         (_cAlias4)->(DBSkip())
         
      EndDo

      //Faz ultima jornada
            
      //Soma total da jornada do dia
      _ntotdia := 0
      _nintdia := 0
            
      For _nnd := 1 to Len(ajorns)
            
         If ajorns[_nnd][1] >= 0 .And. ajorns[_nnd][2] >= 0
               
            _ntotdia := _ntotdia + ajorns[_nnd][2] - ajorns[_nnd][1]
            
            If _nnd > 1
                  
               _nintdia := _nintdia + ajorns[_nnd][1] - ajorns[_nnd-1][2]
                  
            EndIf
                  
         EndIf
            
      Next
            
      //Registra jornada do dia e reinicia contador 
      _nnk := aScan(_aRet,{|_vAux| _vAux[1]==AllTrim(_cCodFil) .and.;
                                    _vAux[3]==AllTrim(Str(nidcolab)) .AND.;
                              _vAux[9]==AllTrim(DToC(_dultima)) }) 
            
      If _ntotdia > 0 .And. _nnk > 0
         _aRet[_nnk][11] :=   StrZero(int(_ntotdia/60),2) + ":" + StrZero(_ntotdia-(int(_ntotdia/60)*60),2)
         _aRet[_nnk][12] :=   StrZero(int(_nintdia/60),2) + ":" + StrZero(_nintdia-(int(_nintdia/60)*60),2)
      ElseIf _nnk > 0
         _aRet[_nnk][11] := " "
         _aRet[_nnk][12] := " "
      EndIf					
   Next
EndIf

_aDados:=ACLONE(_aRet)
_aRet:={}
For _nnh := 1 to Len(_aDados)
	aAdd(_aRet, {_aDados[_nnh][1],_aDados[_nnh][7],_aDados[_nnh][3],_aDados[_nnh][4],_aDados[_nnh][5],_aDados[_nnh][9],_aDados[_nnh][10],_aDados[_nnh][11],_aDados[_nnh][12] })
Next _nnh

Return( _aRet )
