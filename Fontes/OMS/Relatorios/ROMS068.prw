/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ROMS068
Autor-------------: Julio de Paula Paz
Data da Criacao---: 12/05/2022
Descrição---------: Relatório de Comissões para Análise Gerencial. Chamado 38767.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS068()
Local _cPerg := "ROMS068"

Private _aDados := {}
Private _aTitulos := {}

Begin Sequence
   If ! Pergunte(_cPerg ,.T. ,"Relatório de Comissões para Análise Gerencial")
      Break 
   EndIf 

   If (Empty(MV_PAR02) .Or. Empty(MV_PAR03)) .And. Empty(MV_PAR01)
      U_ITMsg("É preciso informar a data de emissão inicial e final ou o período de fechamento da comissão, antes de emitir este relatório.","Atenção",,1)
	   Break 
   EndIf 

   Processa( {|| U_ROMS068D() }, "Aguarde...", "Gerando dados dos relatório... ",.F.)

   If ! Empty(_aDados)

      _aTitulo := { "Data de Fechamento",;       // 1   // TRBZBK->ZBK_DTFECH
                    "Versão",;                   // 2   // TRBZBK->ZBK_VERSAO
                    "Filial",;				       // 3   // TRBZBK->ZBK_FILDOC
                    "Tipo",;					       // 4   // TRBZBK->ZBK_TIPO
                    "Dt. Emissão",;	             // 5   // TRBZBK->ZBK_EMISSA
                    "Dt. Baixa",;		          // 6   // TRBZBK->ZBK_BAIXA
                    "Documento",;		          // 7	  // TRBZBK->ZBK_DOCTO
                    "Parcela",;			          // 8	  // TRBZBK->ZBK_SERIE
                    "Rede",;                     // 9   // TRBZBK->ZBK_GRPVEN	
                    "Descrição Rede",;           // 10  // TRBZBK->ZBK_DSCRED
                    "Cliente",;				       // 11  // TRBZBK->ZBK_CLIENT	
                    "Loja",;					       // 12  // TRBZBK->ZBK_LOJA 
                    "Nome Cliente",;             // 13  // TRBZBK->ZBK_NOMECL	
                    "Sequencia",;                // 14  // TRBZBK->ZBK_SEQUEN	
                    "Valor Original",; 		    // 15  // TRBZBK->ZBK_VLORIG
                    "Vlr Compensado",; 		    // 16  // TRBZBK->ZBK_COMPEN
                    "Vlr Desconto",;	 		    // 17  // TRBZBK->ZBK_DESCON
                    "Vlr Baixas Ant",; 		    // 18  // TRBZBK->ZBK_VLBXAN 
                    "Base Comissão",;  		    // 19  // TRBZBK->ZBK_BASECM
                    "Representante",;  		    // 20  // TRBZBK->ZBK_VEND
                    "Nome rep.",;      		    // 21  // TRBZBK->ZBK_NOMVEN	
                    "Tipo Repres",;              // 22  // TRBZBK->ZBK_TIPVEN	
                    "% Com.Repres",;             // 23  // TRBZBK->ZBK_PERCVD
                    "Comiss.Repres",;            // 24  // TRBZBK->ZBK_COMVEN	
                    "Supervisor",; 			       // 25  // TRBZBK->ZBK_SUPERV	
                    "Nome sup.",;       	       // 26  // TRBZBK->ZBK_NOMSUP
                    "% Com.Super",;              // 27  // TRBZBK->ZBK_PERSUP	
                    "Comiss.Seper",;             // 28  // TRBZBK->ZBK_COMSUP	
                    "Coordenador",;     	       // 29  // TRBZBK->ZBK_COORDE 
                    "Nome Coord.",;    		    // 30  // TRBZBK->ZBK_NOMCOO 
                    "% Com.Coord",;              // 31  // TRBZBK->ZBK_PERCOO
                    "Comiss.Coord",;             // 32  // TRBZBK->ZBK_COMCOO	
                    "Gerente",; 				       // 33  // TRBZBK->ZBK_GERENT 
                    "Nome Ger.",;      	       // 34  // TRBZBK->ZBK_NOMGER 
                    "% Com.Geren",;              // 35  // TRBZBK->ZBK_PERGER	
                    "Comiss.Geren",;             // 36  // TRBZBK->ZBK_COMGER	
	                 "Gerente Nacional",; 	       // 37  // TRBZBK->ZBK_GERNAC	
                    "Nome Ger.Nac.",;   	       // 38  // TRBZBK->ZBK_NOMGNC   
                    "% Com.Ger.Nac",;            // 39  // TRBZBK->ZBK_PERGNC	
                    "Comiss.Ger.Nac",;           // 40  // TRBZBK->ZBK_COMGNC
                    "Codigo Produto",;           // 41  // TRBZBK->ZBK_CODPRO	
                    "Descrição Produto",;        // 42  // TRBZBK->ZBK_DSCPRD 
                    "Grupo Produto",;            // 43  // TRBZBK->ZBK_GRPPRD
                    "Descrição Grupo Produto",;  // 44  // TRBZBK->ZBK_GRPDSC 
                    "Mix BI"}                    // 45  // TRBZBK->ZBK_BIMIX

      U_ITListBox( 'Relatório de Comissão e Análise Gerencial' ,_aTitulo , _aDados , .T. , 1 )
   Else 
      U_ITMsg("Não foram encontrados dados para emissão do relatório.","Atenção",,1)
      Break
   EndIf 

End Sequence

U_ITMsg("Termino da emissão do relatório.","Atenção",,1)

Return 

/*
===============================================================================================================================
Programa----------: ROMS068D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/05/2022
Descrição---------: Gera os dados do relatório com base nos filtros informados na tela de parâmetros iniciais.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS068D()
Local _cQry, _cVersao 
Local _nTotRegs, _nI 
Local _cPerFech 

Begin Sequence 
   
   _cPerFech := SubStr(MV_PAR01, 3, 4) + SubStr(MV_PAR01, 1, 2) + "01"

   ProcRegua(0)
   IncProc("Obtendo a ultima versão...")

   //====================================================================
   // Obtem a ultima versão do Período.
   //====================================================================
   _cQry := " SELECT MAX(ZBK_VERSAO) VERSAO "
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "

   If ! Empty(MV_PAR02)
      _cQry += " AND ZBK_EMISSA >= '"+DToS(MV_PAR02)+"' "
   EndIf 

   If ! Empty(MV_PAR03)
      _cQry += " AND ZBK_EMISSA <= '" + DToS(MV_PAR03) + "' "
   EndIf 

   If ! Empty(MV_PAR01)
      _cQry += " AND ZBK_DTFECH = '" + _cPerFech + "' "
   EndIf 
   
   If Select("TRBZBK") > 0
      TRBZBK->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBZBK" , .T. , .F. )

   If TRBZBK->(Eof()) .Or. TRBZBK->(Bof())
      Break 
   EndIf 
   
   _cVersao := TRBZBK->VERSAO

   IncProc("Contando registros...")

   //====================================================================
   // Obtem o total de registros a serem processados.
   //====================================================================
   _cQry := " SELECT Count(*) TOTREGS "    // "Data de Fechamento"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   //_cQry += " AND ZBK_EMISSA >= '"+DToS(MV_PAR02)+"' AND ZBK_EMISSA <= '" + DToS(MV_PAR03) + "' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "

//---------------------------------------------------------
   If ! Empty(MV_PAR02)
      _cQry += " AND ZBK_EMISSA >= '"+DToS(MV_PAR02)+"' "
   EndIf 

   If ! Empty(MV_PAR03)
      _cQry += " AND ZBK_EMISSA <= '" + DToS(MV_PAR03) + "' "
   EndIf 

   If ! Empty(MV_PAR01)
      _cQry += " AND ZBK_DTFECH = '" + _cPerFech + "' "
   EndIf 
//---------------------------------------------------------

   If ! Empty(MV_PAR04)
      _cQry += " AND ZBK_DOCTO >= '" +MV_PAR04+"' "
   EndIf 

   If ! Empty(MV_PAR05)
      _cQry += " AND ZBK_DOCTO <= '" +MV_PAR05+"' "
   EndIf 

   If ! Empty(MV_PAR06)
      _cQry += " AND ZBK_CODPRO IN " + FormatIn(MV_PAR06,";") +" "
   EndIf 

   If ! Empty(MV_PAR07)
      _cQry += " AND ZBK_GRPPRD IN " + FormatIn(MV_PAR07,";") +" "
   EndIf 

   If ! Empty(MV_PAR08)
      _cQry += " AND ZBK_BIMIX = '" + MV_PAR08 +"' "
   EndIf 

   If ! Empty(MV_PAR09)
      _cQry += " AND ZBK_GERENT IN " + FormatIn(MV_PAR09,";") +" "
   EndIf 

   If ! Empty(MV_PAR10)
      _cQry += " AND ZBK_COORDE IN " + FormatIn(MV_PAR10,";") +" "
   EndIf 

   If ! Empty(MV_PAR11)
      _cQry += " AND ZBK_SUPERV IN " + FormatIn(MV_PAR11,";") +" "
   EndIf 

   If ! Empty(MV_PAR12)
      _cQry += " AND ZBK_VEND IN " + FormatIn(MV_PAR12,";") +" "
   EndIf 

   _cQry += " ORDER BY ZBK_VEND, ZBK_CODPRO " 

   If Select("TRBZBK") > 0
      TRBZBK->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBZBK" , .T. , .F. )

   _nTotRegs := TRBZBK->TOTREGS

   If _nTotRegs == 0
      Break 
   EndIf 
   
   IncProc("Efetuando leitura dos dados...")
   //====================================================================
   // Query principal do relatório.
   //====================================================================   
   _cQry := " SELECT ZBK_DTFECH, "    // "Data de Fechamento"
   _cQry += "    ZBK_VERSAO, "    // "Versão"
   _cQry += "    ZBK_FILDOC, "    // "Filial"				
	_cQry += "    ZBK_TIPO, "      // "Tipo"					
	_cQry += "    ZBK_EMISSA, "	 // "Dt. Emissão"	        
	_cQry += "    ZBK_BAIXA, "     // "Dt. Baixa"		    
	_cQry += "    ZBK_DOCTO, "	    // "Documento"			
	_cQry += "    ZBK_SERIE, "	    // "Parcela"				
   _cQry += "    ZBK_GRPVEN, "	 // "Rede"
   _cQry += "    ZBK_DSCRED, "	 // "Descrição Rede"
	_cQry += "    ZBK_CLIENT, "	 // "Cliente"				
	_cQry += "    ZBK_LOJA, "      // "Loja"					
   _cQry += "    ZBK_NOMECL, "	 // "Nome Cliente"      
	_cQry += "    ZBK_SEQUEN, "	 // "Sequencia"            
	_cQry += "    ZBK_VLORIG, "    // "Valor Original" 		
	_cQry += "    ZBK_COMPEN, "    // "Vlr Compensado" 		
	_cQry += "    ZBK_DESCON, "    // "Vlr Desconto"	 		
	_cQry += "    ZBK_VLBXAN, "    // "Vlr Baixas Ant" 		
	_cQry += "    ZBK_BASECM, "    // "Base Comissão"  		
	_cQry += "    ZBK_VEND, "	    // "Representante"  		
	_cQry += "    ZBK_NOMVEN, "	 // "Nome rep."      		
	_cQry += "    ZBK_TIPVEN, "	 // "Tipo Repres"          
	_cQry += "    ZBK_PERCVD, "	 // "% Com.Repres"         
	_cQry += "    ZBK_COMVEN, "	 // "Comiss.Repres"        
	_cQry += "    ZBK_SUPERV, "	 // "Supervisor" 			
	_cQry += "    ZBK_NOMSUP, "	 // "Nome sup."       		
	_cQry += "    ZBK_PERSUP, "	 // "% Com.Super"          
	_cQry += "    ZBK_COMSUP, "	 // "Comiss.Seper"         
	_cQry += "    ZBK_COORDE, "    // "Coordenador"     		
   _cQry += "    ZBK_NOMCOO, "    // "Nome Coord."    		
	_cQry += "    ZBK_PERCOO, "	 // "% Com.Coord"          
	_cQry += "    ZBK_COMCOO, "	 // "Comiss.Coord"         
	_cQry += "    ZBK_GERENT, "    // "Gerente" 				
	_cQry += "    ZBK_NOMGER, "    // "Nome Ger."      	   
	_cQry += "    ZBK_PERGER, "	 // "% Com.Geren"          
	_cQry += "    ZBK_COMGER, "	 // "Comiss.Geren"         
	_cQry += "    ZBK_GERNAC, "	 // "Gerente Nacional" 	
	_cQry += "    ZBK_NOMGNC, "    // "Nome Ger.Nac."   		
	_cQry += "    ZBK_PERGNC, "	 // "% Com.Ger.Nac"        
	_cQry += "    ZBK_COMGNC, "	 // "Comiss.Ger.Nac"        
   _cQry += "    ZBK_CODPRO, "	 // "Codigo Produto"
   _cQry += "    ZBK_DSCPRD, "    // "Descrição Produto"
   _cQry += "    ZBK_GRPPRD, "	 // "Grupo Produto"
	_cQry += "    ZBK_GRPDSC, "    // "Descrição Grupo Produto"
   _cQry += "    ZBK_BIMIX"	    // "Mix BI"
   _cQry += " FROM "+ RetSqlName('ZBK') +" ZBK "
   _cQry += " WHERE "
   _cQry += "     ZBK.D_E_L_E_T_ = ' ' "
   _cQry += " AND ZBK_VERSAO = '" + _cVersao + "' "

//---------------------------------------------------------
   If ! Empty(MV_PAR02)
      _cQry += " AND ZBK_EMISSA >= '"+DToS(MV_PAR02)+"' "
   EndIf 

   If ! Empty(MV_PAR03)
      _cQry += " AND ZBK_EMISSA <= '" + DToS(MV_PAR03) + "' "
   EndIf 

   If ! Empty(MV_PAR01)
      _cQry += " AND ZBK_DTFECH = '" + _cPerFech + "' "
   EndIf 
//---------------------------------------------------------

   If ! Empty(MV_PAR04)
      _cQry += " AND ZBK_DOCTO >= '" +MV_PAR04+"' "
   EndIf 

   If ! Empty(MV_PAR05)
      _cQry += " AND ZBK_DOCTO <= '" +MV_PAR05+"' "
   EndIf 

   If ! Empty(MV_PAR06)
      _cQry += " AND ZBK_CODPRO IN " + FormatIn(MV_PAR06,";") +" "
   EndIf 

   If ! Empty(MV_PAR07)
      _cQry += " AND ZBK_GRPPRD IN " + FormatIn(MV_PAR07,";") +" "
   EndIf 

   If ! Empty(MV_PAR08)
      _cQry += " AND ZBK_BIMIX = '" + MV_PAR08 +"' "
   EndIf 

   If ! Empty(MV_PAR09)
      _cQry += " AND ZBK_GERENT IN " + FormatIn(MV_PAR09,";") +" "
   EndIf 

   If ! Empty(MV_PAR10)
      _cQry += " AND ZBK_COORDE IN " + FormatIn(MV_PAR10,";") +" "
   EndIf 

   If ! Empty(MV_PAR11)
      _cQry += " AND ZBK_SUPERV IN " + FormatIn(MV_PAR11,";") +" "
   EndIf 

   If ! Empty(MV_PAR12)
      _cQry += " AND ZBK_VEND IN " + FormatIn(MV_PAR12,";") +" "
   EndIf 

   _cQry += " ORDER BY ZBK_VEND, ZBK_CODPRO " 

   If Select("TRBZBK") > 0
      TRBZBK->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQry ) , "TRBZBK" , .T. , .F. )
   
   ProcRegua(_nTotRegs)
   
   _nI := 1
   
   _aDados := {}

   While ! TRBZBK->(Eof())   
      
      IncProc("Gerando dados do Relatório: " + StrZero(_nI,6) + " de " + StrZero(_nTotRegs,6)+"." )

      aAdd(_aDados, {SToD(TRBZBK->ZBK_DTFECH),;  // "Data de Fechamento"      // 1
                     TRBZBK->ZBK_VERSAO,;        // "Versão"                  // 2
                     TRBZBK->ZBK_FILDOC,;        // "Filial"				      // 3
               	   TRBZBK->ZBK_TIPO,;          // "Tipo"					      // 4
               	   SToD(TRBZBK->ZBK_EMISSA),;	 // "Dt. Emissão"	            // 5 
               	   SToD(TRBZBK->ZBK_BAIXA),;   // "Dt. Baixa"		         // 6
               	   TRBZBK->ZBK_DOCTO,;	       // "Documento"		         // 7	
               	   TRBZBK->ZBK_SERIE,;	       // "Parcela"			         // 8	
                     TRBZBK->ZBK_GRPVEN,;	       // "Rede"                    // 9
                     TRBZBK->ZBK_DSCRED,;	       // "Descrição Rede"          // 10
               	   TRBZBK->ZBK_CLIENT,;	       // "Cliente"				      // 11
               	   TRBZBK->ZBK_LOJA,;          // "Loja"					      // 12
                     TRBZBK->ZBK_NOMECL,;	       // "Nome Cliente"            // 13
               	   TRBZBK->ZBK_SEQUEN,;	       // "Sequencia"               // 14
               	   TRBZBK->ZBK_VLORIG,;        // "Valor Original" 		   // 15
               	   TRBZBK->ZBK_COMPEN,;        // "Vlr Compensado" 		   // 16
               	   TRBZBK->ZBK_DESCON,;        // "Vlr Desconto"	 		   // 17
               	   TRBZBK->ZBK_VLBXAN,;        // "Vlr Baixas Ant" 		   // 18
               	   TRBZBK->ZBK_BASECM,;        // "Base Comissão"  		   // 19
               	   TRBZBK->ZBK_VEND,;	       // "Representante"  		   // 20
               	   TRBZBK->ZBK_NOMVEN,;	       // "Nome rep."      		   // 21
               	   TRBZBK->ZBK_TIPVEN,;	       // "Tipo Repres"             // 22 
               	   TRBZBK->ZBK_PERCVD,;	       // "% Com.Repres"            // 23 
               	   TRBZBK->ZBK_COMVEN,;	       // "Comiss.Repres"           // 24
               	   TRBZBK->ZBK_SUPERV,;	       // "Supervisor" 			      // 25
               	   TRBZBK->ZBK_NOMSUP,;	       // "Nome sup."       	      // 26	
               	   TRBZBK->ZBK_PERSUP,;	       // "% Com.Super"             // 27
               	   TRBZBK->ZBK_COMSUP,;	       // "Comiss.Seper"            // 28
               	   TRBZBK->ZBK_COORDE,;        // "Coordenador"     	      // 29	
                     TRBZBK->ZBK_NOMCOO,;        // "Nome Coord."    		   // 30 
               	   TRBZBK->ZBK_PERCOO,;	       // "% Com.Coord"             // 31 
               	   TRBZBK->ZBK_COMCOO,;	       // "Comiss.Coord"            // 32 
               	   TRBZBK->ZBK_GERENT,;        // "Gerente" 				      // 33
               	   TRBZBK->ZBK_NOMGER,;        // "Nome Ger."      	      // 34
               	   TRBZBK->ZBK_PERGER,;	       // "% Com.Geren"             // 35 
               	   TRBZBK->ZBK_COMGER,;	       // "Comiss.Geren"            // 36
	                  TRBZBK->ZBK_GERNAC,;	       // "Gerente Nacional" 	      // 37
               	   TRBZBK->ZBK_NOMGNC,;        // "Nome Ger.Nac."   	      // 38	
               	   TRBZBK->ZBK_PERGNC,;	       // "% Com.Ger.Nac"           // 39
               	   TRBZBK->ZBK_COMGNC,;	       // "Comiss.Ger.Nac"          // 40 
                     TRBZBK->ZBK_CODPRO,;	       // "Codigo Produto"          // 41
                     TRBZBK->ZBK_DSCPRD,;        // "Descrição Produto"       // 42
                     TRBZBK->ZBK_GRPPRD,;	       // "Grupo Produto"           // 43
               	   TRBZBK->ZBK_GRPDSC,;        // "Descrição Grupo Produto" // 44
                     TRBZBK->ZBK_BIMIX})	       // "Mix BI"                  // 45

      TRBZBK->(DBSkip()) 
   EndDo 

End Sequence 

Return
