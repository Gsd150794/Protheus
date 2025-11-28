/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |12/07/2023| Chamado 44405. Ajuste para incluir no pergunte o tipo de aumento e descrição do aumento na impressão
Igor Melgaço  |17/08/2023| Chamado 44732. Ajuste no pergunte tipo de aumento para multipla seleção. 
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include 'TOPCONN.CH'

/*
===============================================================================================================================
Programa--------: RGPE023
Autor-----------: Julio de Paula Paz
Data da Criacao-: 12/06/2023
Descrição-------: Rotina responsável pela impressão do relatório de Histórico Salarial. Chamado 44099.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function RGPE023()
Local _oReport := nil
Local _cPerg	:=	"RGPE023"

Private _aOrder := {'1 - Matrícula + Data','2 - Data + Matrícula'}
Private _oSect1_A := Nil
Private _oSect1_B := Nil
Private _nOrdReport := 1
Private _oBreakFil

_cSelectX5 := " SELECT X5_CHAVE,X5_DESCRI  FROM "+ RetSQLName("SX5") +" WHERE D_E_L_E_T_ = ' ' " 
_cSelectX5 += " AND X5_TABELA = '41'"

_aItalac_F3:={}//       1           2         3                      4                      5          6                      7         8          9         10         11        12
//  (_aItalac_F3,{"CPOCAMPO",_cTabela   ,_nCpoChave            , _nCpoDesc               ,_bCondTab   , _cTitAux           , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR11",_cSelectX5,{|Tab|AllTrim((Tab)->X5_CHAVE)},{|Tab|(Tab)->X5_DESCRI}                  ,,"Tipo de Aumento",          ,          ,          ,.F.        ,       , } )

Begin Sequence 
	
   Pergunte(_cPerg,.F.)	          
	_oReport := RGPE023D(_cPerg)
	_oReport:PrintDialog()

End Sequence

Return

/*
===============================================================================================================================
Programa----------: RGPE023D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 12/06/2023
Descrição---------: Realiza as definições do relatório. (ReportDef)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGPE023D(_cNome)
Local _oReport := Nil

Begin Sequence	
   _oReport := TReport():New(_cNome,"Relatório de Histórico Salarial" ,_cNome,{|_oReport| RGPE023P(_oReport)},"Relatório de Histórico Salarial")
   _oReport:SetLandscape()    
   _oReport:SetTotalInLine(.F.)

   _oSect1_A := TRSection():New(_oReport, "Relatório de Histórico Salarial"  , {"SR7","SRA","SR3"},_aOrder , .F., .T.)
   TRCell():New(_oSect1_A,"R7_FILIAL"	,"TRBSR7","Filial","@!",10)
   TRCell():New(_oSect1_A,"WK_NOMEFIL"	,"TRBSR7","Filial","@!",10)
   
   _oSect1_B := TRSection():New(_oReport, "Relatório de Histórico Salarial"  , {"SR7","SRA","SR3"},_aOrder , .F., .T.)
   TRCell():New(_oSect1_B,"R7_MAT"	    , "TRBSR7"  ,"Matricula"   ,"@!",10)		
   TRCell():New(_oSect1_B,"RA_NOME"	    , "TRBSR7"  ,"Nome"        ,"@!",40)		
   TRCell():New(_oSect1_B,"R7_DATA" 	 , "TRBSR7"  ,"Data Aumento","@!",14)	
   TRCell():New(_oSect1_B,"R7_TIPO" 	 , "TRBSR7"  ,"Tipo Aumento","@!",10)
   TRCell():New(_oSect1_B,"R7_DTIPO" 	 , "TRBSR7"  ,"Desc Tipo Aumento","@!",40)
   TRCell():New(_oSect1_B,"R7_CATFUNC"  , "TRBSR7"  ,"Cat."        ,"@!",20) // ExistCpo('SX5','28'+M->R7_CATFUNC)
   TRCell():New(_oSect1_B,"WK_VALOR" 	 , "TRBSR7"  ,"Valor"       ,"@E 999,999,999.99",16)
   TRCell():New(_oSect1_B,"R7_CARGO" 	 , "TRBSR7"  ,"Cargo"       ,"@!",14)
   TRCell():New(_oSect1_B,"R7_DESCCAR"  , "TRBSR7"  ,"Desc.Cargo"  ,"@!",30)
   TRCell():New(_oSect1_B,"R3_DTCDISS"	 , "TRBSR7"  ,"Dt.Cal.Diss.","@!",14)
   TRCell():New(_oSect1_B,"RA_CBO" 	    , "TRBSR7"  ,"C.B.O.  1994","@!",30)
   _oSect1_B:SetTotalText(" ")              

   //Definindo a quebra
	_oBreak := TRBreak():New(_oSect1_A,{|| TRBSR7->R7_FILIAL },{|| "Total Filial" },.F.,,.T.)
	_oSect1_A:SetHeaderBreak(.T.)

   // TRFunction():New(oSecCab:Cell("B1_COD")    ,/*cId*/,"COUNT",/*oBreak*/,/*cTitle*/,/*cPicture*/,/*uFormula*/,.F.           ,.T.           ,.F.        ,oSecCab)	
   TRFunction():New(_oSect1_B:Cell("R7_MAT")  ,NIL    ,"COUNT",_oBreak ,,,,.F.,.T.)
   TRFunction():New(_oSect1_B:Cell("WK_VALOR"),NIL    ,"SUM"  ,_oBreak ,,,,.F.,.T.)

End Sequence
					
Return(_oReport)

/*
===============================================================================================================================
Programa----------: RGPE023P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 12/06/2023
Descrição---------: Realiza a impressão do relatório. (ReportPrint)
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGPE023P(_oReport)
Local _cQry       := ""		
Local _cOrderBy
Local _cWhere := ""
Local _nTotRegs, _nI, _nX 
Local _cFilImpr
Local _aFilial := FwLoadSM0()
Local _cNomeFil := ""
Local _aFunLidos := {}
Local _lFirstPag := .T.

Begin Sequence                    

   //====================================================================================================
   // Monta a query de dados.
   //====================================================================================================	

   _nOrdReport := _oReport:GetOrder()    
   If _nOrdReport == 1
   	//_cOrderBy := " R7_FILIAL, R7_MAT, R7_DATA "
      _cOrderBy := " R7_FILIAL, R7_MAT, ULTIMADT "
	ElseIf _nOrdReport == 2
		//_cOrderBy := " R7_FILIAL, R7_DATA, R7_MAT "
      _cOrderBy := " R7_FILIAL, ULTIMADT, R7_MAT "
	EndIf	

   If ! Empty(MV_PAR01)
	   _cWhere += " AND RA_FILIAL = '" + MV_PAR01 + "' "
	EndIf 
    
	If ! Empty(MV_PAR02)
	   _cWhere += " AND RA_MAT = '" + MV_PAR02 + "' "
	EndIf 

   If ! Empty(MV_PAR05)
	   _cWhere += " AND RA_DEPTO = '"+ MV_PAR05 + "' " //MV_PAR05 // DEPARTAMENTO  RA_DEPTO
	EndIf 

   If ! Empty(MV_PAR06)
	   _cWhere += " AND R7_CARGO = '"+ MV_PAR06 + "' " //MV_PAR06 //CARGO // R7_CARGO
   EndIf 

   If ! Empty(MV_PAR08)
	   _cWhere += " AND RA_CC = '" + MV_PAR08 + "' "   //_cCentroC //MV_PAR08 // CENTRO DE CUSTO // RA_CC
   EndIf 
	
   If ! Empty(MV_PAR03) 
	  _cWhere += " AND R7_DATA >= '"+ DToS(MV_PAR03) +"' "
   EndIf 

   If ! Empty(MV_PAR04)
	   _cWhere += " AND R7_DATA <= '" + DToS(MV_PAR04) + "' "
   EndIf 
	
   If (Len(MV_PAR07) > 0)		
	  _cWhere += " AND RA_SITFOLH IN (" + fSqlIn(MV_PAR07,1) + ") "		 
   EndIf 

   MV_PAR09 := StrTran(MV_PAR09, '*')

   If (Len(MV_PAR09) > 0)		
	  _cWhere += " AND R7_CATFUNC IN (" + fSqlIn(MV_PAR09,1) + ") "		 
   EndIf 

   If ! Empty(MV_PAR11)
      _cWhere += " AND R7_TIPO IN " + FormatIn(MV_PAR11,";")
   EndIf 

   If MV_PAR10 == 1
      _cQry := "SELECT R7_FILIAL, R7_MAT, RA_NOME, MAX(R7_DATA) ULTIMADT, R7_TIPO, R7_CATFUNC, "
   Else 
      _cQry := "SELECT R7_FILIAL, R7_MAT, RA_NOME, R7_DATA ULTIMADT, R7_TIPO, R7_CATFUNC, "
   EndIf 

	_cQry += " R3_VALOR, R7_CARGO, R7_DESCCAR, R3_DTCDISS,RA_CBO, RA_SALARIO "
	_cQry += " FROM " + RetSqlName("SR7") + " SR7 "
	_cQry += " INNER JOIN " + RetSqlName("SRA") + " SRA ON(SRA.RA_FILIAL = R7_FILIAL AND SRA.D_E_L_E_T_ = ' ' AND SRA.RA_MAT = R7_MAT) "
	_cQry += " INNER JOIN " + RetSqlName("SR3") + " SR3 ON(SR3.R3_FILIAL = SRA.RA_FILIAL AND SR3.D_E_L_E_T_ = ' ' AND R3_MAT = R7_MAT AND R3_DATA = R7_DATA AND R3_SEQ = R7_SEQ) "
	_cQry += " WHERE  SR7.D_E_L_E_T_ = ' ' "
   _cQry := _cQry  + _cWhere

   If MV_PAR10 == 1
      _cQry += " GROUP BY R7_FILIAL, R7_MAT, RA_NOME, R7_TIPO, R7_CATFUNC, "
	   _cQry += " R3_VALOR, R7_CARGO, R7_DESCCAR, R3_DTCDISS,RA_CBO, RA_SALARIO "
   EndIf 

   _cQry += " ORDER BY " + _cOrderBy 

   If Select("TRBSR7") <> 0
	   TRBSR7->(DBCloseArea())
   EndIf
	
   TCQUERY _cQry NEW ALIAS "TRBSR7"	
   //TCSetField('TRBSR7',"R7_DATA","D",8,0)
   TCSetField('TRBSR7',"ULTIMADT","D",8,0)
   TCSetField('TRBSR7',"R3_DTCDISS","D",8,0)
      	
   DBSelectArea("TRBSR7")
   TRBSR7->(DBGoTop())

   Count to _nTotRegs	

   If _ntotRegs = 0
      U_ITMsg("Não existe dados para emissão do relatório.",'Atenção!',"Altere os filtros do relatório e tente novamente",3) 
      BREAK
   EndIf

   _cTotGeral:=AllTrim(Str(_nTotRegs,10))

   //====================================================================================================
   // Ativa a seção do relatório conforme a ordem de emissão do relatório.
   //====================================================================================================	
   _oSect1_A:Enable() 
   _oSect1_B:Enable() 

   _oReport:SetMeter(_nTotRegs)	

   //====================================================================================================
   // Inicia/Lista todos os reajustes, conforme os filtros informados.
   //====================================================================================================		
   If MV_PAR10 <> 1
      TRBSR7->(DBGoTop())
      _cFilImpr := ""

      //====================================================================================================
      // Inicia processo de impressão.
      //====================================================================================================		
      _aFunLidos := {} 

      While !TRBSR7->(Eof())
		
         If _oReport:Cancel()
		      Exit
         EndIf

         If MV_PAR10 == 1
            _nI := aScan(_aFunLidos,{|x| x[1] == TRBSR7->R7_FILIAL .And. x[2] == TRBSR7->R7_MAT}) 
      
            If _nI == 0
               aAdd(_aFunLidos,{TRBSR7->R7_FILIAL,TRBSR7->R7_MAT})
            Else
               TRBSR7->(DBSkip())
               Loop
            EndIf 

         EndIf 

         //====================================================================================================
         // Inicializando a primeira seção
         //====================================================================================================		 
         If _cFilImpr <> TRBSR7->R7_FILIAL
            _cFilImpr := TRBSR7->R7_FILIAL

            _nI := aScan(_aFilial,{|x| x[2] == TRBSR7->R7_FILIAL}) 
	         If _nI > 0
               _cNomeFil :=  _aFilial[_nI,7]
	         EndIf

	         _oSect1_A:Init()
         
	         _oReport:IncMeter()
	                  
            _oSect1_A:Cell("R7_FILIAL"):SetValue(TRBSR7->R7_FILIAL)
		      _oSect1_A:Cell("WK_NOMEFIL"):SetValue(_cNomeFil)
		      _oSect1_A:PrintLine()
            //_oSect1_A:ThinLine()
         
            _oSect1_B:Init()

            If ! _lFirstPag
               _oSect1_B:PrintHeader(.T.,.T.)
            Else 
               _lFirstPag := .F.
            EndIf 

         EndIf 

         //====================================================================================================
         // Inicializando a segunda seção
         //====================================================================================================		 
	      _oReport:IncMeter()

         _oSect1_B:Cell("R7_MAT"):SetValue(TRBSR7->R7_MAT)	// R7_MAT	
         _oSect1_B:Cell("RA_NOME"):SetValue(TRBSR7->RA_NOME)		
         _oSect1_B:Cell("R7_DATA"):SetValue(TRBSR7->ULTIMADT) // R7_DATA)	
         _oSect1_B:Cell("R7_TIPO"):SetValue(TRBSR7->R7_TIPO)
         _oSect1_B:Cell("R7_DTIPO"):SetValue(Tabela("41",TRBSR7->R7_TIPO,.F.))
         _oSect1_B:Cell("R7_CATFUNC"):SetValue( Tabela("28",TRBSR7->R7_CATFUNC,.F.)) // TRBSR7->R7_CATFUNC) // ExistCpo('SX5','28'+M->R7_CATFUNC)
         _oSect1_B:Cell("WK_VALOR"):SetValue(TRBSR7->R3_VALOR) //R3_VALOR
         _oSect1_B:Cell("R7_CARGO"):SetValue(TRBSR7->R7_CARGO)
         _oSect1_B:Cell("R7_DESCCAR"):SetValue(TRBSR7->R7_DESCCAR)
         _oSect1_B:Cell("R3_DTCDISS"):SetValue(TRBSR7->R3_DTCDISS)
         _oSect1_B:Cell("RA_CBO"):SetValue(TRBSR7->RA_CBO)
	      _oSect1_B:PrintLine()
      
         TRBSR7->(DBSkip())
      EndDo		
   
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
	   _oSect1_B:Finish()
	
      //==================================================================================
      // Finaliza a impressão do relatório listando todos os reajustes dos funcionários. 
      //==================================================================================
      Break 

   EndIf 

   //===============================================================================
   // Emite o relatório listando apenas os ultimos reajustes dos funcionários.
   //===============================================================================
   TRBSR7->(DBGoTop())
   
   _aFunLidos := {} 

   While !TRBSR7->(Eof())
      
      _oReport:IncMeter()

      _nI := aScan(_aFunLidos,{|x| x[1] == TRBSR7->R7_FILIAL .And. x[2] == TRBSR7->R7_MAT}) 
      
      If _nI == 0
         aAdd(_aFunLidos,{TRBSR7->R7_FILIAL,;  // 1 = Filial
         TRBSR7->R7_MAT,;                      // 2 = Matricula
         TRBSR7->RA_NOME,;		                 // 3 = Nome
         TRBSR7->ULTIMADT,;                    // 4 = Data Aumento
         TRBSR7->R7_TIPO,;                     // 5 = Tipo Aumento
         Tabela("28",TRBSR7->R7_CATFUNC,.F.),; // 6 = Descrição Categoria
         TRBSR7->R3_VALOR,;                    // 7 = Valor
         TRBSR7->R7_CARGO,;                    // 8 = Cargo
         TRBSR7->R7_DESCCAR,;                  // 9 = Descrição do Cargo
         TRBSR7->R3_DTCDISS,;                  // 10 = Data de Discidio
         TRBSR7->RA_CBO,;                      // 11 = CBO
         Tabela("41",TRBSR7->R7_TIPO,.F.) })   // 12 = Descrição Tipo de Aumento
      Else
         If (DToS(_aFunLidos[_nI,4]) < DToS(TRBSR7->ULTIMADT)) .Or. ;
            (DToS(_aFunLidos[_nI,4]) == DToS(TRBSR7->ULTIMADT) .And. _aFunLidos[_nI,7] < TRBSR7->R3_VALOR)

            _aFunLidos[_nI,4]  := TRBSR7->ULTIMADT                    // 4 = Data Aumento
            _aFunLidos[_nI,5]  := TRBSR7->R7_TIPO                     // 5 = Tipo Aumento
            _aFunLidos[_nI,6]  := Tabela("28",TRBSR7->R7_CATFUNC,.F.) // 6 = Desc Categoria
            _aFunLidos[_nI,7]  := TRBSR7->R3_VALOR                    // 7 = Valor
            _aFunLidos[_nI,8]  := TRBSR7->R7_CARGO                    // 8 = Cargo
            _aFunLidos[_nI,9]  := TRBSR7->R7_DESCCAR                  // 9 = Descrição do Cargo
            _aFunLidos[_nI,10] := TRBSR7->R3_DTCDISS                  // 10 = Data de Discidio
            _aFunLidos[_nI,11] := TRBSR7->RA_CBO                      // 11 = CBO 
            _aFunLidos[_nI,12] := Tabela("41",TRBSR7->R7_TIPO,.F.)    // 12 = Desc Tipo de Aumento

         EndIf 

      EndIf 
            
      TRBSR7->(DBSkip())
   EndDo		

   _nTotRegs := Len(_aFunLidos)

   _oReport:SetMeter(_nTotRegs)
   _cFilImpr := ""
   //====================================================================================================
   // Inicia processo de impressão.
   //====================================================================================================		
   For _nX := 1 To _nTotRegs 	
         
       If _oReport:Cancel()
		    Exit
       EndIf

       //====================================================================================================
       // Inicializando a primeira seção
       //====================================================================================================		 
       If _cFilImpr <> _aFunLidos[_nX,1] // Filial
          _cFilImpr := _aFunLidos[_nX,1] // Filial

          _nI := aScan(_aFilial,{|x| x[2] == _cFilImpr }) 
	       If _nI > 0
             _cNomeFil :=  _aFilial[_nI,7]
	       EndIf

	       _oSect1_A:Init()
         
	       _oReport:IncMeter()
	                  
          _oSect1_A:Cell("R7_FILIAL"):SetValue(_cFilImpr)
		    _oSect1_A:Cell("WK_NOMEFIL"):SetValue(_cNomeFil)
		    _oSect1_A:PrintLine()
          //_oSect1_A:ThinLine()
         
          _oSect1_B:Init()

          If ! _lFirstPag
             _oSect1_B:PrintHeader(.T.,.T.)
          Else 
             _lFirstPag := .F.
          EndIf 
       EndIf 

       //====================================================================================================
       // Inicializando a segunda seção
       //====================================================================================================		 
       _oReport:IncMeter()

       _oSect1_B:Cell("R7_MAT"):SetValue(_aFunLidos[_nX,2])      // TRBSR7->R7_MAT)	    - Matricula
       _oSect1_B:Cell("RA_NOME"):SetValue(_aFunLidos[_nX,3])     // TRBSR7->RA_NOME)    - Nome Funcinário		
       _oSect1_B:Cell("R7_DATA"):SetValue(_aFunLidos[_nX,4])     // TRBSR7->ULTIMADT)   - Data de Reajuste
       _oSect1_B:Cell("R7_TIPO"):SetValue(_aFunLidos[_nX,5])     // TRBSR7->R7_TIPO)    - Tipo de Aumento
       _oSect1_B:Cell("R7_DTIPO"):SetValue(_aFunLidos[_nX,12])     // Tabela("41",TRBSR7->R7_TIPO,.F.)    - Desc Tipo de Aumento
       _oSect1_B:Cell("R7_CATFUNC"):SetValue(_aFunLidos[_nX,6])  // Tabela("28",TRBSR7->R7_CATFUNC,.F.)) - Descrição da Categoria
       _oSect1_B:Cell("WK_VALOR"):SetValue(_aFunLidos[_nX,7])    // TRBSR7->R3_VALOR)   - Valor
       _oSect1_B:Cell("R7_CARGO"):SetValue(_aFunLidos[_nX,8])    // TRBSR7->R7_CARGO)   - Cargo 
       _oSect1_B:Cell("R7_DESCCAR"):SetValue(_aFunLidos[_nX,9])  // TRBSR7->R7_DESCCAR) - Descrição do Cargo
       _oSect1_B:Cell("R3_DTCDISS"):SetValue(_aFunLidos[_nX,10]) // TRBSR7->R3_DTCDISS) - Data Dissidio
       _oSect1_B:Cell("RA_CBO"):SetValue(_aFunLidos[_nX,11])     // TRBSR7->RA_CBO)     - CBO
	    _oSect1_B:PrintLine()

   Next   
   
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
	_oSect1_B:Finish()

End Sequence

If Select("TRBSR7") <> 0
   TRBSR7->(DBCloseArea())
EndIf

Return
