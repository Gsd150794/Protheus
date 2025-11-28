/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |23/06/2021| Chamado 36805. Ajustes para adaptação ao novo parametro incluído: Formato MV_PAR07.
Julio Paz     |10/07/2024| Chamado 47774. Alt.Título,incl.10 grupos col.p/preencher manual:VOLUME/FABRICAÇÃO/MÁQUINA/LOTE/HORÁRIO
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "Report.ch"
#Include "TOTVS.ch"
#Include "fileio.ch"

/*
===============================================================================================================================
Programa--------: ROMS062
Autor-----------: Julio de Paula Paz
Data da Criacao-: 22/07/2020
Descrição-------: Relatório de Rastreabilidade - Chamado 31503.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ROMS062()
Local _aDadosRel
Local _cArq, _cDir, _cTitulo, _aTitulos

Private _cPerg := "ROMS062"

Begin Sequence
   //==================================================== 
   // Exibe a tela de parâmetros iniciais 
   //====================================================
   If ! Pergunte(_cPerg, .T.,"Relatório de Rastreabilidade")
      Break
   EndIf
 
   //======================================================
   // Roda a query com base na tela de parâmetros iniciais
   // e cria tabela temporária.
   //======================================================
   Processa( {|| _aDadosRel := U_ROMS062Q() }, "Aguarde...", "Gerando dados do relatório...",.F.)

   If Empty(_aDadosRel)
      U_ITMsg("Não existem dados para emissão do relatório","Atenção",,1)
      Break
   EndIf
 
   _cArq := "ROMS062.XML"
   _cDir := AllTrim(GetTempPath())
   _cTitulo := "RASTREABILIDADE PRODUTOS EXPEDIDOS - CÓD.: CB.F.EXP.025 - REVISÃO: 00"

   _aTitulos := {}
    
   aAdd(_aTitulos,{"EMBARQUE"       , 2 , 4 , .F.})

   If MV_PAR07 = 1
       aAdd(_aTitulos,{"COD CLIENTE"    , 1 , 1 , .F.})
       aAdd(_aTitulos,{"LOJA"           , 1 , 1 , .F.})
       aAdd(_aTitulos,{"CLIENTE"        , 1 , 1 , .F.})
       aAdd(_aTitulos,{"CIDADE"         , 1 , 1 , .F.})
       aAdd(_aTitulos,{"UF"             , 1 , 1 , .F.})
   EndIf
   
   aAdd(_aTitulos,{"ORDEM DE CARGA" , 1 , 1 , .F.})
   aAdd(_aTitulos,{"CÓDIGO"         , 1 , 1 , .F.})
   aAdd(_aTitulos,{"DESCRIÇÃO"      , 1 , 1 , .F.})
   aAdd(_aTitulos,{"UNIDADES"       , 3 , 2 , .F.})
   aAdd(_aTitulos,{"1a. UM"         , 1 , 1 , .F.})
   aAdd(_aTitulos,{"CX AVULSA"      , 3 , 2 , .F.})
   aAdd(_aTitulos,{"2a.UM"          , 1 , 1 , .F.})
   aAdd(_aTitulos,{"VOLUME 1"       , 1 , 1 , .F.})
   aAdd(_aTitulos,{"FABRICAÇÃO"     , 1 , 1 , .F.})
   aAdd(_aTitulos,{"MÁQUINA"        , 1 , 1 , .F.})
   aAdd(_aTitulos,{"LOTE"           , 1 , 1 , .F.})
   aAdd(_aTitulos,{"HORÁRIO"        , 1 , 1 , .F.})  
   aAdd(_aTitulos,{"VOLUME 2"       , 1 , 1 , .F.})
   aAdd(_aTitulos,{"FABRICAÇÃO"     , 1 , 1 , .F.})
   aAdd(_aTitulos,{"MÁQUINA"        , 1 , 1 , .F.})
   aAdd(_aTitulos,{"LOTE"           , 1 , 1 , .F.})
   aAdd(_aTitulos,{"HORÁRIO"        , 1 , 1 , .F.})  
//--------------------------------------------------
   aAdd(_aTitulos,{"VOLUME 3"       , 1 , 1 , .F.})
   aAdd(_aTitulos,{"FABRICAÇÃO"     , 1 , 1 , .F.})
   aAdd(_aTitulos,{"MÁQUINA"        , 1 , 1 , .F.})
   aAdd(_aTitulos,{"LOTE"           , 1 , 1 , .F.})
   aAdd(_aTitulos,{"HORÁRIO"        , 1 , 1 , .F.})  
   aAdd(_aTitulos,{"VOLUME 4"       , 1 , 1 , .F.})
   aAdd(_aTitulos,{"FABRICAÇÃO"     , 1 , 1 , .F.})
   aAdd(_aTitulos,{"MÁQUINA"        , 1 , 1 , .F.})
   aAdd(_aTitulos,{"LOTE"           , 1 , 1 , .F.})
   aAdd(_aTitulos,{"HORÁRIO"        , 1 , 1 , .F.})  
//--------------------------------------------------
   aAdd(_aTitulos,{"VOLUME 5"       , 1 , 1 , .F.})
   aAdd(_aTitulos,{"FABRICAÇÃO"     , 1 , 1 , .F.})
   aAdd(_aTitulos,{"MÁQUINA"        , 1 , 1 , .F.})
   aAdd(_aTitulos,{"LOTE"           , 1 , 1 , .F.})
   aAdd(_aTitulos,{"HORÁRIO"        , 1 , 1 , .F.})  
   aAdd(_aTitulos,{"VOLUME 6"       , 1 , 1 , .F.})
   aAdd(_aTitulos,{"FABRICAÇÃO"     , 1 , 1 , .F.})
   aAdd(_aTitulos,{"MÁQUINA"        , 1 , 1 , .F.})
   aAdd(_aTitulos,{"LOTE"           , 1 , 1 , .F.})
   aAdd(_aTitulos,{"HORÁRIO"        , 1 , 1 , .F.})  
//--------------------------------------------------
   aAdd(_aTitulos,{"VOLUME 7"       , 1 , 1 , .F.})
   aAdd(_aTitulos,{"FABRICAÇÃO"     , 1 , 1 , .F.})
   aAdd(_aTitulos,{"MÁQUINA"        , 1 , 1 , .F.})
   aAdd(_aTitulos,{"LOTE"           , 1 , 1 , .F.})
   aAdd(_aTitulos,{"HORÁRIO"        , 1 , 1 , .F.})  
   aAdd(_aTitulos,{"VOLUME 8"       , 1 , 1 , .F.})
   aAdd(_aTitulos,{"FABRICAÇÃO"     , 1 , 1 , .F.})
   aAdd(_aTitulos,{"MÁQUINA"        , 1 , 1 , .F.})
   aAdd(_aTitulos,{"LOTE"           , 1 , 1 , .F.})
   aAdd(_aTitulos,{"HORÁRIO"        , 1 , 1 , .F.})  
//--------------------------------------------------
   aAdd(_aTitulos,{"VOLUME 9"       , 1 , 1 , .F.})
   aAdd(_aTitulos,{"FABRICAÇÃO"     , 1 , 1 , .F.})
   aAdd(_aTitulos,{"MÁQUINA"        , 1 , 1 , .F.})
   aAdd(_aTitulos,{"LOTE"           , 1 , 1 , .F.})
   aAdd(_aTitulos,{"HORÁRIO"        , 1 , 1 , .F.})  
   aAdd(_aTitulos,{"VOLUME 10"       , 1 , 1 , .F.})
   aAdd(_aTitulos,{"FABRICAÇÃO"     , 1 , 1 , .F.})
   aAdd(_aTitulos,{"MÁQUINA"        , 1 , 1 , .F.})
   aAdd(_aTitulos,{"LOTE"           , 1 , 1 , .F.})
   aAdd(_aTitulos,{"HORÁRIO"        , 1 , 1 , .F.})  

   U_ITGEREXCEL(_cArq,_cDir,_cTitulo,"Relatorio",_aTitulos,_aDadosRel,.F.)

End Sequence

Return

/*
===============================================================================================================================
Programa--------: ROMS062Q
Autor-----------: Julio de Paula Paz
Data da Criacao-: 22/07/2020
Descrição-------: Gera a query de dados do relatório.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ROMS062Q()
Local _cQry, _aDados := {}
Local _nI, _nTotRegs, _nJ
Local _cFiltro := ""
Local _cTipo := "N"

Begin Sequence
 
   //==============================================================
   // Define o filtro de acordo com os parametros digitados
   //==============================================================
   _cFiltro := ""

   //Filtra Emissao da NOTA FISCAL
   If ! Empty(MV_PAR01) 
	   _cFiltro += " AND SD2.D2_EMISSAO >= '" + DToS(MV_PAR01) + "' "
   EndIf

   If ! Empty(MV_PAR02) 
	   _cFiltro += " AND SD2.D2_EMISSAO <= '" + DToS(MV_PAR02) + "' "
   EndIf
   
   If !Empty(AllTrim(MV_PAR03))
       _cFiltro += " AND SD2.D2_LOCAL IN "+FormatIn(MV_PAR03,";") 
   EndIf

   If MV_PAR04 = 1
       _cTipo += ";D"
   EndIf

   If MV_PAR05 = 1
       _cTipo += ";B"
   EndIf

    _cFiltro += " AND SF2.F2_TIPO IN "+FormatIn(_cTipo,";") 

   If MV_PAR06 = 1
       _cFiltro += " AND SF2.F2_CARGA <> ' ' "
   EndIf  
   
   _cQry := "SELECT "
   _cQry += " SUM(SD2.D2_QTSEGUM) AS D2_QTSEGUM, "
   
   If MV_PAR07 = 1 
       _cQry += " SD2.D2_CLIENTE, "
       _cQry += " SD2.D2_LOJA, "
       _cQry += " SA1.A1_NOME, "
       _cQry += " SA1.A1_EST, "
       _cQry += " SA1.A1_MUN, "
   EndIf

   _cQry += " SD2.D2_EMISSAO, "
   _cQry += " SD2.D2_SEGUM AS D2_SEGUM, "
   _cQry += " SF2.F2_CARGA, "
   _cQry += " SB1.B1_COD, "
   _cQry += " SB1.B1_DESC, "
   _cQry += " SUM(SD2.D2_QUANT) AS D2_QUANT, "
   _cQry += " SD2.D2_UM AS D2_UM  "
   _cQry += " FROM  "
   _cQry += " " + RetSqlName("SF2") + " SF2  "
   _cQry += " JOIN " + RetSqlName("SD2") + " SD2 ON SD2.D2_DOC = SF2.F2_DOC AND SD2.D2_SERIE = SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL  "
   _cQry += " JOIN (SELECT A1_FILIAL, A1_COD, A1_LOJA, A1_NREDUZ, A1_NOME, A1_MUN, A1_EST, A1_CGC, A1_GRPVEN "
   _cQry += " 		FROM "+ RetSqlName("SA1") +" SA1 "
   _cQry += " 		WHERE SA1.D_E_L_E_T_ = ' ' "
   _cQry += " 		UNION "
   _cQry += " 		SELECT A2_FILIAL, A2_COD, A2_LOJA, A2_NREDUZ, A2_NOME, A2_MUN, A2_EST, A2_CGC, '' As A1_GRPVEN "
   _cQry += " 		FROM "+ RetSqlName("SA2") +" SA2 "
   _cQry += " 		WHERE SA2.D_E_L_E_T_ = ' '  ) SA1 ON  SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA  = SA1.A1_LOJA "
   _cQry += " JOIN " + RetSqlName("SB1") + " SB1 ON SD2.D2_COD = SB1.B1_COD  "  
   _cQry += " WHERE  "
   _cQry += " SF2.D_E_L_E_T_ = ' '  "
   _cQry += " AND SD2.D_E_L_E_T_ = ' '  "
   _cQry += " AND SD2.D2_CF <> '5927'  AND SD2.D2_CF <> '6927' "
   _cQry += " AND SB1.D_E_L_E_T_ = ' '  "	
   _cQry += " AND SF2.F2_FILIAL = '"+xFilial("SF2") + "' "
   _cQry += " AND SB1.B1_TIPO = 'PA' "
   _cQry += _cFiltro     
   _cQry += " GROUP BY  "

   If MV_PAR07 = 1 
      _cQry += " SD2.D2_CLIENTE,SD2.D2_LOJA,SA1.A1_NOME,SA1.A1_MUN, SA1.A1_EST, "
   EndIf
   
   _cQry += " SD2.D2_EMISSAO,SF2.F2_CARGA, SB1.B1_COD, SB1.B1_DESC, "
   _cQry += " SD2.D2_SEGUM,SD2.D2_UM "
   _cQry += " ORDER BY  "
   _cQry += " SD2.D2_EMISSAO,SF2.F2_CARGA, "
   
   If MV_PAR07 = 1 
      _cQry += " SD2.D2_CLIENTE,SD2.D2_LOJA,  "
   EndIf
   
   _cQry += " SB1.B1_COD  "

   If Select("TRBSF2") > 0
      TRBSF2->(DBCloseArea())
   EndIf

   DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQry ) , "TRBSF2" , .F. , .T. )
   DBSelectArea("TRBSF2")
   
   TCSetField( "TRBSF2", "D2_EMISSAO", "D", 8 )

   Count To _nTotRegs
   _nI := 0
   
   ProcRegua(_nTotRegs)
   
   TRBSF2->(DBGoTop())
  
   _aDados := {}
   
   _cCliente := ""
   _cCidade  := ""
   _cEstado  := ""


   While ! TRBSF2->(Eof())
      _nI += 1
      IncProc("Lendo dados: " + StrZero(_nI,6) + "/" + StrZero(_nTotRegs,6))
      
      If MV_PAR07 = 1 
      
         _nJ := aScan(_aDados,{|x| x[1] == TRBSF2->D2_EMISSAO .And. x[7] == TRBSF2->F2_CARGA .And. x[2] == TRBSF2->D2_CLIENTE .And. x[3] == TRBSF2->D2_LOJA .And. x[8] == TRBSF2->B1_COD})

          If _nJ == 0
             aAdd(_aDados,{TRBSF2->D2_EMISSAO,; // EMBARQUE             - 1	
                           TRBSF2->D2_CLIENTE,; // COD CLIENTE          - 2
                           TRBSF2->D2_LOJA,;    // LOJA                 - 3 
                           TRBSF2->A1_NOME,;    // CLIENTE	            - 4
                           TRBSF2->A1_MUN,;     // CIDADE	            - 5
                           TRBSF2->A1_EST,;     // UF	                  - 6 
                           TRBSF2->F2_CARGA,;   // ORDEM DE CARGA       - 7	
                           TRBSF2->B1_COD,;     // CÓDIGO	            - 8
                           TRBSF2->B1_DESC,;    // DESCRIÇÃO	         - 9
                           TRBSF2->D2_QUANT,;   // UNIDADES  	         - 10
                           TRBSF2->D2_UM,;      // 1a. UM   	         - 11                      
                           TRBSF2->D2_QTSEGUM,; // CX AVULSA	         - 12
                           TRBSF2->D2_SEGUM,;   // 2a UNIDADE DE MEDIDA - 13
                           "",;                 // VOLUME 1             - 14 <<<<
                           "",;                 // FABRICAÇÃO	         - 15                      
                           "",;                 // MÁQUINA	            - 16 
                           "",;                 // LOTE	               - 17
                           "",;                 // HORÁRIO              - 18  
                           "",;                 // VOLUME 2             - 19 <<<< 
                           "",;                 // FABRICAÇÃO	         - 20                      
                           "",;                 // MÁQUINA	            - 21
                           "",;                 // LOTE                 - 22 
                           "",;                 // HORÁRIO              - 23 
                           "",;                 // VOLUME 3             - 24 <<<<
                           "",;                 // FABRICAÇÃO	         - 25                      
                           "",;                 // MÁQUINA	            - 26 
                           "",;                 // LOTE	               - 27
                           "",;                 // HORÁRIO              - 28  
                           "",;                 // VOLUME 4             - 29 <<<<
                           "",;                 // FABRICAÇÃO	         - 30                       
                           "",;                 // MÁQUINA	            - 31 
                           "",;                 // LOTE                 - 32 
                           "",;                 // HORÁRIO              - 33
                           "",;                 // VOLUME 5             - 34 <<<<
                           "",;                 // FABRICAÇÃO	         - 35                      
                           "",;                 // MÁQUINA	            - 36 
                           "",;                 // LOTE	               - 37
                           "",;                 // HORÁRIO              - 38 
                           "",;                 // VOLUME 6             - 39 <<<<
                           "",;                 // FABRICAÇÃO	         - 40                      
                           "",;                 // MÁQUINA	            - 41
                           "",;                 // LOTE                 - 42 
                           "",;                 // HORÁRIO              - 43     
                           "",;                 // VOLUME 7             - 44 <<<<
                           "",;                 // FABRICAÇÃO	         - 45                      
                           "",;                 // MÁQUINA	            - 46
                           "",;                 // LOTE                 - 47 
                           "",;                 // HORÁRIO              - 48
                           "",;                 // VOLUME 8             - 49 <<<<
                           "",;                 // FABRICAÇÃO	         - 50                      
                           "",;                 // MÁQUINA	            - 51 
                           "",;                 // LOTE	               - 52
                           "",;                 // HORÁRIO              - 53
                           "",;                 // VOLUME 9             - 54 <<<<
                           "",;                 // FABRICAÇÃO	         - 55                      
                           "",;                 // MÁQUINA	            - 56
                           "",;                 // LOTE                 - 57 
                           "",;                 // HORÁRIO              - 58
                           "",;                 // VOLUME 10            - 59 <<<<
                           "",;                 // FABRICAÇÃO	         - 60                      
                           "",;                 // MÁQUINA	            - 61
                           "",;                 // LOTE                 - 62 
                           ""})                 // HORÁRIO              - 63

          Else 
             _aDados[_nJ,10] += TRBSF2->D2_QUANT
             _aDados[_nJ,12] += TRBSF2->D2_QTSEGUM
          EndIf
    	  
      Else
      
         _nJ := aScan(_aDados,{|x| x[1] == TRBSF2->D2_EMISSAO .And. x[2] == TRBSF2->F2_CARGA .And. x[3] == TRBSF2->B1_COD})
      
         If _nJ == 0
             aAdd(_aDados,{TRBSF2->D2_EMISSAO,; // EMBARQUE             - 1	
                           TRBSF2->F2_CARGA,;   // ORDEM DE CARGA       - 2	
                           TRBSF2->B1_COD,;     // CÓDIGO	            - 3
                           TRBSF2->B1_DESC,;    // DESCRIÇÃO	         - 4
                           TRBSF2->D2_QUANT,;   // UNIDADES  	         - 5
                           TRBSF2->D2_UM,;      // 1a. UM   	         - 6                      
                           TRBSF2->D2_QTSEGUM,; // CX AVULSA	         - 7
                           TRBSF2->D2_SEGUM,;   // 2a UNIDADE DE MEDIDA - 8
                           "",;                 // VOLUME 1             - 9  <<<<
                           "",;                 // FABRICAÇÃO	         - 10                      
                           "",;                 // MÁQUINA	            - 11 
                           "",;                 // LOTE	               - 12
                           "",;                 // HORÁRIO              - 13
                           "",;                 // VOLUME 2             - 14 <<<<
                           "",;                 // FABRICAÇÃO	         - 15                      
                           "",;                 // MÁQUINA	            - 16
                           "",;                 // LOTE                 - 17
                           "",;                 // HORÁRIO              - 18                            
                           "",;                 // VOLUME 3             - 19 <<<<
                           "",;                 // FABRICAÇÃO	         - 20                      
                           "",;                 // MÁQUINA	            - 21
                           "",;                 // LOTE                 - 22 
                           "",;                 // HORÁRIO              - 23 
                           "",;                 // VOLUME 4             - 24 <<<<
                           "",;                 // FABRICAÇÃO	         - 25                      
                           "",;                 // MÁQUINA	            - 26 
                           "",;                 // LOTE	               - 27
                           "",;                 // HORÁRIO              - 28  
                           "",;                 // VOLUME 5             - 29 <<<<
                           "",;                 // FABRICAÇÃO	         - 30                      
                           "",;                 // MÁQUINA	            - 31 
                           "",;                 // LOTE                 - 32 
                           "",;                 // HORÁRIO              - 33
                           "",;                 // VOLUME 6             - 34 <<<<
                           "",;                 // FABRICAÇÃO	         - 35                      
                           "",;                 // MÁQUINA	            - 36 
                           "",;                 // LOTE	               - 37
                           "",;                 // HORÁRIO              - 38 
                           "",;                 // VOLUME 7             - 39
                           "",;                 // FABRICAÇÃO	         - 40 <<<<                     
                           "",;                 // MÁQUINA	            - 41
                           "",;                 // LOTE                 - 42 
                           "",;                 // HORÁRIO              - 43  
                           "",;                 // VOLUME 8             - 44 <<<<
                           "",;                 // FABRICAÇÃO	         - 45                      
                           "",;                 // MÁQUINA	            - 46 
                           "",;                 // LOTE	               - 47
                           "",;                 // HORÁRIO              - 48
                           "",;                 // VOLUME 9             - 49  <<<
                           "",;                 // FABRICAÇÃO	         - 50                      
                           "",;                 // MÁQUINA	            - 51
                           "",;                 // LOTE                 - 52 
                           "",;                 // HORÁRIO              - 53
                           "",;                 // VOLUME 10            - 54   <<<<
                           "",;                 // FABRICAÇÃO	         - 55                      
                           "",;                 // MÁQUINA	            - 56
                           "",;                 // LOTE                 - 57 
                           ""})                 // HORÁRIO              - 58
          Else 
             _aDados[_nJ,5] += TRBSF2->D2_QUANT
             _aDados[_nJ,7] += TRBSF2->D2_QTSEGUM
          EndIf
    	  
      EndIf
      
      TRBSF2->(DBSkip())

   EndDo
  
End Sequence

If Select("TRBSF2") > 0
   TRBSF2->(DBCloseArea())
EndIf 

Return _aDados
