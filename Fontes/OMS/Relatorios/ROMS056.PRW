/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |09/06/2021| Chamado 36726. Ajuste registros qdo F2_TIPO = D ou B visualizando os dados do Fornecedor.
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/
#Include "TOTVS.ch"
#Include 'TOPCONN.CH'
/*
===============================================================================================================================
Programa----------: ROMS056
Autor-------------: Alex Wallauer
Data da Criacao---: 07/05/2019 
Descrição---------: Relatório de Fechamento do Frete - Chamado 29104 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS056()

While .T.
   If !Pergunte("ROMS056",.T.)
      Return
   EndIf

    If Empty(MV_PAR02) .Or. Empty(MV_PAR03) .Or. MV_PAR03 < MV_PAR02
       U_ITMsg("Datas invalidas ou não preenchidas",'Atenção!',"Preencha as 2 datas e a final maior ou igual a inicial",1)
       Loop
    EndIf

   cTimeInicial:=Time()

   FWMsgRun( ,{|oProc|  ROMS056R(oProc) } , "Processando - Hora Inicial: "+cTimeInicial+", Aguarde...",  )

  EndDo 

U_ITLOGACS( "ROMS056" )

Return


/*
===============================================================================================================================
Programa----------: ROMS056R
Autor-------------: Alex Wallauer
Data da Criacao---: 07/05/2019
Descrição---------: Função que imprime o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS056R(oProc)
Local cQuery := "" 
Local cFiltro := ""
Local _aCampos := {} // Array com os campos da tabela temporária.
Local _cDir := GetTempPath()  // Diretório de Geração das planilhas.
Local _cArq := "_"+DToS(Date())+"_"+StrTran(Time(),":","")+".xml"  // Nome da planilha a ser gerada.   
Local _aCabecalho := {} // Array com o cabeçalho das colunas do relatório.
Local _cTitulo
Private _cAlias:= GetNextAlias()
Private _aDadosPar:={}
Private _aPergunte:={}

oProc:cCaption :=  "Selecionando Dados, Aguarde... "
ProcessMessages()

//====================================================================================================
// Define o filtro de acordo com os parametros digitados
// Filtra Filial das tabelas SF2,SD2,SA1,SA2,SB1,DAK,DAI,DA3,DA4
//====================================================================================================
If !Empty( MV_PAR01 )

	If !Empty( xFilial("SF2") )
		cFiltro += " AND SF2.F2_FILIAL IN "+ FormatIn( MV_PAR01 , ";" )
	EndIf
	
	If !Empty( xFilial("SD2") )
		cFiltro += " AND SD2.D2_FILIAL IN "+ FormatIn( MV_PAR01 , ";" )
	EndIf
	
	If !Empty( xFilial("DAK") )
		cFiltro += " AND DAK.DAK_FILIAL IN "+ FormatIn( MV_PAR01 , ";" )
	EndIf
	
	If !Empty( xFilial("DAI") )
		cFiltro += " AND DAI.DAI_FILIAL IN "+ FormatIn( MV_PAR01 , ";" )
	EndIf

EndIf

//====================================================================================================
// Filtra Emissao da SF2
//====================================================================================================
If !Empty(MV_PAR02) .And. !Empty(MV_PAR03)
	cFiltro += " AND SF2.F2_EMISSAO BETWEEN '" + DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "'"
EndIf

//====================================================================================================
// Filtra Produto
//====================================================================================================
If !Empty(MV_PAR04) .And. !Empty(MV_PAR05)
	cFiltro += " AND SD2.D2_COD BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR05 + "'"
EndIf

//====================================================================================================
// Filtra Armazém
//====================================================================================================
If !Empty(MV_PAR27) 
	cFiltro += " AND SD2.D2_LOCAL IN " + FormatIn(MV_PAR27,";")
EndIf

//====================================================================================================
// Filtra Cliente
//====================================================================================================
If !Empty(MV_PAR06) .And. !Empty(MV_PAR08)
	cFiltro += " AND SD2.D2_CLIENTE BETWEEN '" + MV_PAR06 + "' AND '" + MV_PAR08 + "'"
EndIf

//====================================================================================================
// Filtra Loja Cliente
//====================================================================================================
If !Empty(MV_PAR07) .And. !Empty(MV_PAR09)
	cFiltro += " AND SD2.D2_LOJA BETWEEN '" + MV_PAR07 + "' AND '" + MV_PAR09 + "'"
EndIf

//====================================================================================================
// Filtra Rede Cliente
//====================================================================================================
If !Empty(MV_PAR10)
	cFiltro += " AND SA1.A1_GRPVEN IN " + FormatIn(MV_PAR10,";")
EndIf

//====================================================================================================
// Filtra Estado Cliente
//====================================================================================================
If !Empty(MV_PAR11) 
	cFiltro += " AND SA1.A1_EST IN " + FormatIn(MV_PAR11,";")
EndIf

//====================================================================================================
// Filtra Cod Municipio Cliente
//====================================================================================================
If !Empty(MV_PAR12) 
	cFiltro += " AND SA1.A1_COD_MUN IN " + FormatIn(MV_PAR12,";")
EndIf

//====================================================================================================
// Filtra Vendedor
//====================================================================================================
If !Empty(MV_PAR13) 
	cFiltro += " AND SA3.A3_COD IN " + FormatIn(MV_PAR13,";")
EndIf

//====================================================================================================
// Filtra Supervisor
//====================================================================================================
If !Empty(MV_PAR14)
	cFiltro += " AND SA3.A3_SUPER IN " + FormatIn(MV_PAR14,";")
EndIf

//====================================================================================================
// Filtra Grupo de Produtos
//====================================================================================================
If !Empty(MV_PAR15)
	cFiltro += " AND SB1.B1_GRUPO IN " + FormatIn(MV_PAR15,";")
EndIf

//====================================================================================================
// Filtra Produto Nivel 2
//====================================================================================================
If !Empty(MV_PAR16)
	cFiltro += " AND SB1.B1_I_NIV2 IN " + FormatIn(MV_PAR16,";")
EndIf

//====================================================================================================
// Filtra Produto Nivel 3
//====================================================================================================
If !Empty(MV_PAR17)
	cFiltro += " AND SB1.B1_I_NIV3 IN " + FormatIn(MV_PAR17,";")
EndIf

//====================================================================================================
// Filtra Produto Nivel 4
//====================================================================================================
If !Empty(MV_PAR18)
	cFiltro += " AND SB1.B1_I_NIV4 IN " + FormatIn(MV_PAR18,";")
EndIf 

//====================================================================================================
// Filtra Transportadoras
//====================================================================================================
If !Empty(MV_PAR20)
	cFiltro += " AND SA2.A2_COD IN " + FormatIn(MV_PAR20,";")
EndIf 

//====================================================================================================
// Filtra tipo do Fornecedor
//====================================================================================================
If !Empty(MV_PAR25)
	cFiltro    += " AND SA2.A2_I_CLASS IN " + FormatIn(MV_PAR25,";")
EndIf

//====================================================================================================
// Filtra Transportadoras por averbacao
//====================================================================================================
If MV_PAR28 == 1
	cFiltro += " AND SA2.A2_I_AVERB = '1'"
EndIf 
If MV_PAR28 == 2
	cFiltro += " AND SA2.A2_I_AVERB = '2'"
EndIf

//====================================================================================================
// busca CFOPS de acordo com parametro definido por usuario
//====================================================================================================
If !Empty(MV_PAR21)
	
	If !("A" $ MV_PAR21 ) // Senao tiver escolhido a opcao todos
	
		cCfops	:= U_ITCFOPS( AllTrim( Upper( MV_PAR21 ) ) )
		cFiltro	+= " AND SD2.D2_CF IN "+ FormatIn( cCfops , ";" )
		
	EndIf
	
EndIf

//====================================================================================================
// Verifica se filtro os dados das cargas que possuem Frete: 1, que nao possuem frete: 2 ou ambas: 3
//====================================================================================================
If MV_PAR22 == 1

	cFiltro += " AND SF2.F2_I_FRET > 0 "

ElseIf MV_PAR22 == 2

	cFiltro += " AND SF2.F2_I_FRET = 0 "

EndIf

//====================================================================================================
// Sub Grupo de Produtos
//====================================================================================================
If !Empty(MV_PAR23)
	cFiltro += " AND SB1.B1_I_SUBGR IN " + FormatIn(MV_PAR23,";")
EndIf 

//====================================================================================================
// Filtra Tipo da carga
//====================================================================================================
If !Empty(MV_PAR24)
	cFiltro += " AND DAK.DAK_I_TPCA IN " + FormatIn(MV_PAR24,";")
EndIf           

//====================================================================================================
// Filtra Transportadoras por averbacao
//====================================================================================================
If !Empty(MV_PAR29)
	cFiltro += " AND SC5.C5_TPFRETE IN"+ FormatIn( MV_PAR29 , ";" )
EndIf 

If MV_PAR30 = 1
   nOrdem:=8
ElseIf MV_PAR30 = 2
   nOrdem:=9
EndIf   


   cQuery := " SELECT "
   cQuery += " Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD    WHEN SA2.A2_I_CLASS = 'A' THEN '999999'    END AS A2_COD,"
   cQuery += " Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END AS A2_NREDUZ,"
   cQuery += " SA2.A2_EST, "
    If MV_PAR19 = 1
       cQuery += " SA1.A1_COD,"
       cQuery += " SA1.A1_NREDUZ,"
       cQuery += " SA1.A1_EST,"
       cQuery += " DAK.DAK_COD,"
	EndIf   
   cQuery += " SUM(SD2.D2_QUANT)   AS D2_QUANT,"
   cQuery += " SUM(SD2.D2_QTSEGUM) AS D2_QTSEGUM,"
   cQuery += " SUM(SD2.D2_I_FRET)  AS D2_I_FRET,"        
   If nOrdem == 8
      cQuery += " SB1.B1_COD PRODUTO,"		
      cQuery += " SB1.B1_I_DESCD DESCR,"		
   ElseIf nOrdem == 9
	  cQuery += " SB1.B1_I_SUBGR PRODUTO,"
   EndIf
   cQuery += " SD2.D2_UM,"		
   cQuery += " SD2.D2_SEGUM,"		
   cQuery += " SUM(SD2.D2_VALBRUT) AS VLBRUT " 
   cQuery += " FROM "+ RetSqlName("DAK") +" DAK "
   cQuery += " JOIN "+ RetSqlName("DAI") +" DAI ON DAI.DAI_COD = DAK.DAK_COD AND DAI.DAI_FILIAL = DAK.DAK_FILIAL "
   cQuery += " JOIN "+ RetSqlName("DA3") +" DA3 ON DAK.DAK_CAMINH = DA3.DA3_COD "
   cQuery += " JOIN "+ RetSqlName("SF2") +" SF2 ON SF2.F2_DOC = DAI.DAI_NFISCA AND SF2.F2_SERIE = DAI.DAI_SERIE AND DAI.DAI_FILIAL = SF2.F2_FILIAL "
   cQuery += " JOIN "+ RetSqlName("SD2") +" SD2 ON SD2.D2_DOC = SF2.F2_DOC AND SD2.D2_SERIE = SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL "
   cQuery += " JOIN (SELECT A1_FILIAL, A1_COD, A1_LOJA, A1_NREDUZ, A1_MUN, A1_EST, A1_CGC, A1_GRPVEN "
   cQuery += " 		FROM "+ RetSqlName("SA1") +" SA1 "
   cQuery += " 		WHERE SA1.D_E_L_E_T_ = ' ' "
   cQuery += " 		UNION
   cQuery += " 		SELECT A2_FILIAL, A2_COD, A2_LOJA, A2_NREDUZ, A2_MUN, A2_EST, A2_CGC, '' As A1_GRPVEN "
   cQuery += " 		FROM "+ RetSqlName("SA2") +" SA2 "
   cQuery += " 		WHERE SA2.D_E_L_E_T_ = ' '  ) SA1 ON SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA  = SA1.A1_LOJA "   
   cQuery += " JOIN "+ RetSqlName("SA3") +" SA3 ON SF2.F2_VEND1 = SA3.A3_COD "
   cQuery += " JOIN "+ RetSqlName("SB1") +" SB1 ON SD2.D2_COD = SB1.B1_COD "
   cQuery += " JOIN "+ RetSqlName("DA4") +" DA4 ON DAK.DAK_MOTORI = DA4.DA4_COD "
   cQuery += " JOIN "+ RetSqlName("SA2") +" SA2 ON SF2.F2_I_CTRA = SA2.A2_COD AND SF2.F2_I_LTRA = SA2.A2_LOJA "
   cQuery += " JOIN "+ RetSqlName("SC5") +" SC5 ON SC5.C5_FILIAL = SD2.D2_FILIAL AND SC5.C5_NUM = SD2.D2_PEDIDO"
   cQuery += " WHERE "
   cQuery +=     " DAK.D_E_L_E_T_ = ' ' "
   cQuery += " AND DAI.D_E_L_E_T_ = ' ' "  
   cQuery += " AND DA3.D_E_L_E_T_ = ' ' "
   cQuery += " AND SF2.D_E_L_E_T_ = ' ' "
   cQuery += " AND SD2.D_E_L_E_T_ = ' ' "
   cQuery += " AND SA3.D_E_L_E_T_ = ' ' "
   cQuery += " AND SB1.D_E_L_E_T_ = ' ' "
   cQuery += " AND DA4.D_E_L_E_T_ = ' ' "
   cQuery += " AND SA2.D_E_L_E_T_ = ' ' "
   cQuery += " AND SC5.D_E_L_E_T_ = ' ' "
   cQuery += " AND SA2.A2_I_CLASS IN ('T','A','G') "
   cQuery += " AND SD2.D2_CF <> '5927' "
   cQuery +=  cFiltro
   cQuery += "GROUP BY" 
   cQuery += " Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_COD WHEN SA2.A2_I_CLASS = 'A' THEN '999999' END,"
   cQuery += " Case WHEN SA2.A2_I_CLASS IN ('T','G') THEN SA2.A2_NREDUZ WHEN SA2.A2_I_CLASS = 'A' THEN 'AUTONOMOS' END,"
   cQuery += " SA2.A2_EST, "
   If MV_PAR19 = 1
      cQuery += " SA1.A1_COD,"
      cQuery += " SA1.A1_NREDUZ,"
      cQuery += " SA1.A1_EST,"
      cQuery += " DAK.DAK_COD,"
	EndIf   
   If nOrdem == 8
      cQuery += " SB1.B1_COD,SB1.B1_I_DESCD,SD2.D2_UM,SD2.D2_SEGUM "
   ElseIf nOrdem == 9
	  cQuery += " SB1.B1_I_SUBGR,SD2.D2_UM,SD2.D2_SEGUM "
   EndIf
   cQuery += " ORDER BY PRODUTO, D2_QUANT DESC, A2_COD " 

//crio o novo alias
MPSysOpenQuery( cQuery, _cAlias ) 

nTotal:=nConta:=0
DBSelectArea(_cAlias)
COUNT TO nTotal
(_cAlias)->(DBGoTop())

If nTotal = 0 
   U_ITMsg("Não há dados para essa seleção",'Atenção!',,3)
   Return .F.
EndIf


If MV_PAR26 = 1 //Excel
 // Relatório em Excel                     
   oProc:cCaption :=  "Os dados estão sendo gerados em Excel, favor aguardar..."
   ProcessMessages()

   // Array com os campos da tabela temporária.                                         
   If nOrdem == 8 //Fechamento x Produto
      _aCampos := {'(_cAlias)->PRODUTO',;                                                                 //"COD.PRODUTO"
                   '(_cAlias)->DESCR',;                                                                   //"DESCR.PRODUTO"
                   '(_cAlias)->A2_COD +"-"+ (_cAlias)->A2_NREDUZ',;                                       // "TRANSPORTADORA"   
                   '(_cAlias)->A2_EST'                           ,;                                       // "UF TRANSPORTADORA"   
                   '(_cAlias)->D2_QUANT',;                                                                // "QUANTIDADE"
                   '(_cAlias)->D2_UM',;                                                                   // "U.M."
                   '(_cAlias)->D2_QTSEGUM',;                                                              // "QUANT.2a U.M." 
                   '(_cAlias)->D2_SEGUM',;                                                                // "2a U.M."
                   '(_cAlias)->D2_I_FRET',;                                                               // "FRETE"
                   '(_cAlias)->D2_I_FRET / (_cAlias)->D2_QUANT',;                                         // "MÉDIA"
                   '(_cAlias)->VLBRUT'}                                                                   // "VALOR BRUTO"
   Else//nOrdem == 9 
      _aCampos := {'(_cAlias)->PRODUTO',;                                                                 //"COD.PRODUTO"
                   'Posicione("ZB9",1,xFilial("ZB9") + AllTrim((_cAlias)->PRODUTO),"ZB9_DESSUB" )',;      //"DESCR.PRODUTO"
                   '(_cAlias)->A2_COD +"-"+ (_cAlias)->A2_NREDUZ',;                                       // "TRANSPORTADORA"   
                   '(_cAlias)->A2_EST'                           ,;                                       // "UF TRANSPORTADORA"   
                   '(_cAlias)->D2_QUANT',;                                                                // "QUANTIDADE"
                   '(_cAlias)->D2_UM',;                                                                   // "U.M."
                   '(_cAlias)->D2_QTSEGUM',;                                                              // "QUANT.2a U.M." 
                   '(_cAlias)->D2_SEGUM',;                                                                // "2a U.M."
                   '(_cAlias)->D2_I_FRET',;                                                               // "FRETE"
                   '(_cAlias)->D2_I_FRET / (_cAlias)->D2_QUANT',;                                         // "MÉDIA"
                   '(_cAlias)->VLBRUT'}                                                                   // "VALOR BRUTO"
   EndIf
   If MV_PAR19 = 1
      aAdd(_aCampos,'(_cAlias)->DAK_COD')								                                     // CARGA
      aAdd(_aCampos,'(_cAlias)->A1_COD +"-"+ (_cAlias)->A1_NREDUZ')                                 // CLIENTE
      aAdd(_aCampos,'(_cAlias)->A1_EST')                                                            // "UF CLIENTE
   EndIf
   _aCabecalho := {} // Array com o cabeçalho das colunas do relatório. 
   // Alinhamento( 1-Left,2-Center,3-Right )
   // Formatação( 1-General,2-Number,3-Monetário,4-DateTime )
   //                Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?  
   aAdd(_aCabecalho,{"COD.PRODUTO"      ,1           ,1         ,.F.}) 
   aAdd(_aCabecalho,{"DESCR.PRODUTO"    ,1           ,1         ,.F.})    
   aAdd(_aCabecalho,{"TRANSPORTADORA"   ,1           ,1         ,.F.}) 
   aAdd(_aCabecalho,{"UF"               ,1           ,1         ,.F.}) 
   aAdd(_aCabecalho,{"QUANTIDADE"       ,3           ,1         ,.F.}) 
   aAdd(_aCabecalho,{"U.M."             ,2           ,1         ,.F.}) 
   aAdd(_aCabecalho,{"QUANT.2a U.M."    ,3           ,1         ,.F.}) 
   aAdd(_aCabecalho,{"2a U.M."          ,2           ,1         ,.F.}) 
   aAdd(_aCabecalho,{"FRETE"            ,3           ,3         ,.F.}) 
   aAdd(_aCabecalho,{"MÉDIA"            ,3           ,3         ,.F.}) 
   aAdd(_aCabecalho,{"VALOR BRUTO"      ,3           ,3         ,.F.}) 
   If MV_PAR19 = 1
      aAdd(_aCabecalho,{"CARGA"            ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"CLIENTE"          ,1           ,1         ,.F.}) 
      aAdd(_aCabecalho,{"UF"               ,1           ,1         ,.F.}) 
   EndIf
   If nOrdem == 8 //Fechamento x Produto
      _cArq := "Fechamento_x_Produto"+_cArq // Nome da planilha a ser gerada.   
      _cTitulo := "RELATÓRIO DE FRETE POR TRANSPORTADOR (FECHAMENTO X PRODUTO)" 
   Else //Fechamento x SubGrupo // nOrdem == 9 
      _cArq := "Fechamento_x_sub_Grupo"+_cArq // Nome da planilha a ser gerada.   
      _cTitulo := "RELATÓRIO DE FRETE POR TRANSPORTADOR (FECHAMENTO X SUB-GRUPO)"
   EndIf
   _aPergunte:={}
   ROMS056Z()
   U_ITGEREXCEL(_cArq,_cDir,_cTitulo,"Relatorio",_aCabecalho,,.T.,_cAlias,_aCampos,,,_aPergunte)
 
ElseIf MV_PAR26 = 2//Tela

   nTotal:=AllTrim(Str(nTotal))
   nTam:=Len(nTotal)+1   
   _aDados:={}
   SCR->(DBSetOrder(1))
   _cPicQ:=PESQPICT("SD2","D2_QUANT")
   _cPic2:=PESQPICT("SD2","D2_QTSEGUM")
   _cPicF:=PESQPICT("SD2","D2_I_FRET")
   _cPicB:=PESQPICT("SD2","D2_VALBRUT")
   
   While !(_cAlias)->(Eof())
   
      nConta++
      oProc:cCaption :=  "Lendo "+StrZero(nConta,nTam)+" de "+nTotal +" - Lendo Item: " +(_cAlias)->PRODUTO
      ProcessMessages()
      
      _aItens:={}
      aAdd(_aItens,(_cAlias)->PRODUTO)                                                                    //"COD.PRODUTO"
      If nOrdem == 8 //Fechamento x Produto
         aAdd(_aItens,AllTrim((_cAlias)->DESCR))                                                          //"DESCR.PRODUTO"
      Else//nOrdem == 9 
         aAdd(_aItens,AllTrim(Posicione("ZB9",1,xFilial("ZB9")+AllTrim((_cAlias)->PRODUTO),"ZB9_DESSUB")))// "DESCR.PRODUTO"
      EndIf
      aAdd(_aItens,(_cAlias)->A2_COD +"-"+ (_cAlias)->A2_NREDUZ)                   // "TRANSPORTADORA"   
      aAdd(_aItens,(_cAlias)->A2_EST)                                              // "UF TRANSPORTADORA"   
      aAdd(_aItens,(Transform((_cAlias)->D2_QUANT,_cPicQ)))                        // "QUANTIDADE"
      aAdd(_aItens,(_cAlias)->D2_UM)                                               // "U.M."
      aAdd(_aItens,(Transform((_cAlias)->D2_QTSEGUM,_cPic2)))                      // "QUANT.2a U.M." 
      aAdd(_aItens,(_cAlias)->D2_SEGUM)                                            // "2a U.M."
      aAdd(_aItens,(Transform((_cAlias)->D2_I_FRET,_cPicF)))                       // "FRETE"
      aAdd(_aItens,(Transform((_cAlias)->D2_I_FRET / (_cAlias)->D2_QUANT,_cPicQ))) // "MÉDIA"
      aAdd(_aItens,(Transform((_cAlias)->VLBRUT,_cPicB)))                          // "VALOR BRUTO"
      If MV_PAR19 = 1
         aAdd(_aItens,(_cAlias)->DAK_COD)								                    // CARGA
         aAdd(_aItens,(_cAlias)->A1_COD +"-"+ (_cAlias)->A1_NREDUZ)                // CLIENTE
         aAdd(_aItens,(_cAlias)->A1_EST)                                           // "UF CLIENTE
   	EndIf	 
           
      aAdd(_aDados,ACLONE(_aItens))
   
      (_cAlias)->(DBSkip())
   	
   EndDo
   
   If Len(_aDados) = 0 
       U_ITMsg("Não há dados para essa seleção",'Atenção!',,3)
   EndIf
   
   While Len(_aDados) > 0 
      _aTit:={}
      _aSiz:={}
      aAdd(_aTit,"Codigo") 
      aAdd(_aSiz,30)
      If nOrdem == 8 //Fechamento x Produto
         aAdd(_aTit,"Descricao do Produto")
      Else
         aAdd(_aTit,"Descricao do Grupo")
      EndIf   
      aAdd(_aSiz,40)
      aAdd(_aTit,"TRANSPORTADORA" )
      aAdd(_aSiz,90)
      aAdd(_aTit,"UF")
      aAdd(_aSiz,20)
      aAdd(_aTit,"QUANTIDADE" )
      aAdd(_aSiz,45)
      aAdd(_aTit,"U.M.")
      aAdd(_aSiz,20)
      aAdd(_aTit,"QUANT.2a U.M." )
      aAdd(_aSiz,45)
      aAdd(_aTit,"2a U.M.")
      aAdd(_aSiz,20)
      aAdd(_aTit,"FRETE" )
      aAdd(_aSiz,45)
      aAdd(_aTit,"MÉDIA" )
      aAdd(_aSiz,45)
      aAdd(_aTit,"VALOR BRUTO" )
      aAdd(_aSiz,45)
      If MV_PAR19 = 1
         aAdd(_aTit,"CARGA" )
         aAdd(_aSiz,25)
         aAdd(_aTit,"CLIENTE")
         aAdd(_aSiz,100)
         aAdd(_aTit,"UF" )
         aAdd(_aSiz,20)
      EndIf
      If nOrdem == 8 //Fechamento x Produto
         _cTitulo := "RELATÓRIO DE FRETE; POR TRANSPORTADOR (FECHAMENTO X PRODUTO)" 
      Else           //Fechamento x SubGrupo // nOrdem == 9 
         _cTitulo := "RELATÓRIO DE FRETE; POR TRANSPORTADOR (FECHAMENTO X SUB-GRUPO)"
      EndIf
   
      _cMsgTop:="Produtos encontrados - H.I.: "+cTimeInicial+" H.F.: "+Time()
   
      _aDadosPar:=ACLONE(_aDados)
      ROMS056Z()
   
   //   _cTitulo:="Par. 1 : "+DToC(MV_PAR01)+"; Par. 2 : "+DToC(MV_PAR02)+"; Par. 3 : "+AllTrim(MV_PAR03)+"; Par. 4 : "+AllTrim(Str(MV_PAR04))+;
              //"; Par. 5 : "+AllTrim(MV_PAR05)
              
      bOk:={|| If(U_ITMsg("Confirma Gerar EXCEL ?",'Atenção!',,2,2,2) , DlgToExcel( { { "ARRAY" , _cTitulo , _aTit , _aDadosPar } } )  ,.F. )   }
   
      //                           , _aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
         U_ITListBox(_cTitulo,_aTit,_aDados  , .T.    , 3    ,_cMsgTop,          ,_aSiz   ,         , bOk ,        , )
                                                                                                     
   
      If  !U_ITMsg("Confirma Sair ?",'Atenção!',,3,2,2)
          Loop
      EndIf
   
      Exit
   
   EndDo

ElseIf MV_PAR26 = 3//Impressora

   Private nPagina     := 1
   Private nLinha      := 0100
   Private nColInic    := 0030
   Private nColFinal   := 3360 
   Private nqbrPagina  := 2200 
   Private nLinInBox   
   Private nSaltoLinha := 50 
   aProduto  := {} //Para controla a quebra de grupo de produto/Produto por Filial    
   //Variaveis para controle dos totalizadores por Produto                 
   nTotqtde1 := 0
   nTotqtde2 := 0 
   nTotvlrFr := 0      
   nTotvlrBr := 0 
   //Variaveis para controle dos totalizadores Geral                
   nGrTotqtd1:= 0
   nGrTotqtd2:= 0 
   nGrTotvlFr:= 0 
   nGrTotvlBr:= 0     
 
   //Private nAjustAlt   := 10   
   Private oBrush      := TBrush():New( ,CLR_LIGHTGRAY)   
   Define Font oFont10    Name "Courier New"       Size 0,-08       // Tamanho 14    
   Define Font oFont10b   Name "Courier New"       Size 0,-08 Bold  // Tamanho 14 
   Define Font oFont12    Name "Courier New"       Size 0,-10       // Tamanho 12
   Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito  
   Define Font oFont14Prb Name "Courier New"       Size 0,-12 Bold  // Tamanho 14 Negrito
   Define Font oFont16b   Name "Helvetica"         Size 0,-14 Bold  // Tamanho 16 Negrito  

   oPrint:= TMSPrinter():New( "GRUPO DE PRODUTO X UF" ) ////  TMSPRINTER()   //////////////////////////////////////////
   oPrint:SetPaperSize(9)	// Seta para papel A4

   If MV_PAR19 == 1 // Com Carga + Cliente  
	   oPrint:SetLandscape() 	// Paisagem    
	   nColFinal   := 3360
	   nqbrPagina  := 2200
   Else
      oPrint:SetPortrait() 	// Retrato
      nColFinal   := 2360
      nqbrPagina  := 2200 
   EndIf


   oPrint:Say( 0 , 0 , " " , oFont12 , 100 )
   oPrint:StartPage()

   ROMS056C(0)
   ROMS056Z(oPrint)

   If nTotal > 0  

      nTotal:=AllTrim(Str(nTotal))
      nTam:=Len(nTotal)+1   

	  ROMS056C(1) // Imprime cabecalho
	
	  DBSelectArea(_cAlias)
	  (_cAlias)->( DBGoTop() )
	  While (_cAlias)->( !Eof() )
	
      nConta++
      oProc:cCaption :=  "Lendo "+StrZero(nConta,nTam)+" de "+nTotal +" - Lendo Item: " +(_cAlias)->PRODUTO
      ProcessMessages()
		
		 //Incremente as variaves de somatorio geral
		 nGrTotqtd1 += (_cAlias)->D2_QUANT
		 nGrTotqtd2 += (_cAlias)->D2_QTSEGUM
		 nGrTotvlFr += (_cAlias)->D2_I_FRET
		 nGrTotvlBr += (_cAlias)->VLBRUT
		
		 nPosProdut := aScan( aProduto , {|x| x[1] == AllTrim( (_cAlias)->PRODUTO ) } )
		
		 //Produto ja possui um item lancado anteriormente 		 
		 If nPosProdut > 0   
		    
			nlinha += nSaltoLinha
			
			oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
			
			ROMS5Qbg(1)
			
			ROMS0563( (_cAlias)->A2_COD +'-'+ (_cAlias)->A2_NREDUZ , (_cAlias)->D2_QUANT , (_cAlias)->D2_UM , (_cAlias)->D2_QTSEGUM , (_cAlias)->D2_SEGUM , (_cAlias)->D2_I_FRET , (_cAlias)->VLBRUT )
			
			//Incrementa variaveis de somatorio de somatorio por Produto
			nTotqtde1 += (_cAlias)->D2_QUANT
			nTotqtde2 += (_cAlias)->D2_QTSEGUM
			nTotvlrFr += (_cAlias)->D2_I_FRET
			nTotvlrBr += (_cAlias)->VLBRUT
			
		    //Novo produto a ser inserido no relatorio
		 Else
		
			//Finaliza o produto anterior
			If Len(aProduto) > 0
			
				nlinha += nSaltoLinha
				
				oPrint:Line( nLinha , nColInic , nLinha , nColFinal )
				
				ROMS5Qbg(1)
				
				ROMS0564( nTotqtde1 , nTotqtde2 , nTotvlrFr , nTotvlrBr )
				
				nlinha += nSaltoLinha
				
				ROMS0562()
				
			EndIf
			
			aAdd( aProduto , { AllTrim( (_cAlias)->PRODUTO ) } )
				
			nlinha += nSaltoLinha
			
			ROMS5Qbg(0)      
			
			If nOrdem == 8
			
				ROMS0567( AllTrim( (_cAlias)->PRODUTO ) +'-'+ AllTrim( (_cAlias)->DESCR ) )
				
			ElseIf nOrdem == 9
			
				If Len( AllTrim( (_cAlias)->PRODUTO ) ) > 0
				
					ROMS0567(AllTrim((_cAlias)->PRODUTO) + '-' + AllTrim(Posicione("ZB9",1,xFilial("ZB9") + AllTrim((_cAlias)->PRODUTO),"ZB9_DESSUB" ) ) )
					
				Else
				
					ROMS0567('-')
					
				EndIf
				
			EndIf
			
			nlinha += nSaltoLinha
			
			oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
			
			ROMS5Qbg(1)
			
			ROMS0563( (_cAlias)->A2_COD +'-'+ (_cAlias)->A2_NREDUZ , (_cAlias)->D2_QUANT , (_cAlias)->D2_UM , (_cAlias)->D2_QTSEGUM , (_cAlias)->D2_SEGUM , (_cAlias)->D2_I_FRET , (_cAlias)->VLBRUT )
			
			//Seta variaveis de controle de somatorio
			nTotqtde1 := (_cAlias)->D2_QUANT
			nTotqtde2 := (_cAlias)->D2_QTSEGUM
			nTotvlrFr := (_cAlias)->D2_I_FRET
			nTotvlrBr := (_cAlias)->VLBRUT
			
		 EndIf
	
	     (_cAlias)->( DBSkip() )
	  EndDo
	
	  //Finaliza o ultimo produto
	  nlinha += nSaltoLinha
	
	  oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
	
	  ROMS5Qbg(1)
	
	  ROMS0564(nTotqtde1,nTotqtde2,nTotvlrFr,nTotvlrBr)
	
	  nlinha += nSaltoLinha
	
	  ROMS0562()
	
	  //Imprime totalizador geral
	  nlinha += nSaltoLinha
	  nlinha += nSaltoLinha
	
	  ROMS5Qbg(0)
	
	  ROMS0565(nGrTotqtd1,nGrTotqtd2,nGrTotvlFr,nGrTotvlBr)
	
	  nlinha += nSaltoLinha
	
	  ROMS0562()

     oPrint:EndPage()	// Finaliza a Pagina.
     oPrint:Preview()	// Visualiza antes de Imprimir.

   EndIf


EndIf

Return

/*
===============================================================================================================================
Programa--------: ROMS056C
Autor-----------: Alex Wallauer Ferreira
Data da Criacao-: 07/05/2019
Descrição-------: imprimir os dados de cabeçalho do relatório
Parametros------: IMPNRPAG - Se imprime ou não o número de página (0 não imprime, 1 imprime)
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS056C( impNrPag )

Local cRaizServer := If(issrvunix(), "/", "\")    
Local cTitulo     := ""
Local nDiferLay   := 0

If nOrdem == 8 //Fechamento x Produto
   cTitulo := "Relatorio de Frete por Transportador (Fechamento x Produto) De: "+ DToC(MV_PAR02) +" Até "+ DToC(MV_PAR03)
Else           //Fechamento x SubGrupo // nOrdem == 9 
   cTitulo := "Relatorio de Frete por Transportador (Fechamento x Sub-Grupo) De: "+ DToC(MV_PAR02) +" Até "+ DToC(MV_PAR03)
EndIf

nLinha := 0070

//Para subtrair este valor de acordo com o modelo da pagina Paisagem ou Retrato
If nOrdem == 8 .Or. nOrdem == 9 .Or. nOrdem == 10
	nDiferLay := 1000
EndIf

oPrint:SayBitmap( nLinha , nColInic , cRaizServer + "system/lgrl01.bmp" , 250 , 100 )

If impNrPag <> 0

	oPrint:Say( nlinha			, ( nColInic + 2750 ) - nDiferLay , "PÁGINA: "+ AllTrim( Str( nPagina ) )								, oFont12b )
	
Else

	oPrint:Say( nlinha			, ( nColInic + 2750 ) - nDiferLay , "SIGA/ROMS056"														, oFont12b )
	oPrint:Say( nlinha + 100	, ( nColInic + 2750 ) - nDiferLay , "EMPRESA: " + AllTrim(SM0->M0_NOME) + '/' + AllTrim(SM0->M0_FILIAL)	, oFont12b )
	
EndIf

oPrint:Say( nlinha + 50			, ( nColInic + 2750 ) - nDiferLay , "DATA DE EMISSÃO: "+ DToC( Date() )									, oFont12b )

nlinha += ( nSaltoLinha * 3 )

	oPrint:Say (nlinha,nColFinal / 2,cTitulo,oFont16b,nColFinal,,,2)
	
	nlinha+=nSaltoLinha 
	nlinha+=nSaltoLinha        
	
	oPrint:Line(nLinha,nColInic,nLinha,nColFinal) 

Return

/*
===============================================================================================================================
Programa--------: ROMS5Qbg
Autor-----------: Alex Wallauer Ferreira
Data da Criacao-: 07/05/2019
Descrição-------: Processa a quebra de páginas
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS5Qbg( impBox )

If nLinha > nqbrPagina

	If impBox == 1
		ROMS0562()
	EndIf
	
	oPrint:EndPage()	// Finaliza a Pagina
	oPrint:StartPage()	// Inicia uma nova Pagina
	
	nPagina++
	
	ROMS056C(1)		// Chama cabecalho
	
	nlinha		+= nSaltoLinha
	nLinInBox	:= nLinha
	
EndIf

Return

/*
===============================================================================================================================
Programa--------: ROMS0562
Autor-----------: Alex Wallauer Ferreira
Data da Criacao-: 07/05/2019
Descrição-------: Processa a impressao do box dos dados
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0562()

oPrint:Line( nLinInBox , 0725 , nLinha , 0725 ) // 1 UM
oPrint:Line( nLinInBox , 1090 , nLinha , 1090 ) // 2 UM
oPrint:Line( nLinInBox , 1505 , nLinha , 1505 ) // FRETE
oPrint:Line( nLinInBox , 1805 , nLinha , 1805 ) // MEDIA
oPrint:Line( nLinInBox , 2000 , nLinha , 2000 ) // VALOR BRUTO
If MV_PAR19 == 1 // Com Carga   (_cAlias)->DAK_COD
   oPrint:Line( nLinInBox , 2380 , nLinha , 2380 ) // CARGA
   oPrint:Line( nLinInBox , 2600 , nLinha , 2600 ) // Cliente  
EndIf
oPrint:Box( nLinInBox , nColInic , nLinha , nColFinal )

Return

/*
===============================================================================================================================
Programa--------: ROMS0567
Autor-----------: Alex Wallauer Ferreira
Data da Criacao-: 07/05/2019
Descrição-------: Imprime cabeçalho dos dados
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0567( cProduto )

oPrint:FillRect( { ( nlinha + 3 ) , nColInic , nlinha + nSaltoLinha , nColFinal } , oBrush )

oPrint:Box( nlinha , nColInic , nLinha + nSaltoLinha , nColFinal )

oPrint:Say( nlinha , nColFinal / 2 , cProduto , oFont16b , nColFinal ,,, 2 )

nlinha += nSaltoLinha

oPrint:Line( nLinha , nColInic , nLinha , nColFinal )

ROMS5Qbg(0)

nLinInBox := nlinha

oPrint:Say( nlinha + 10 , nColInic + 0010 , "TRANSPORTADORA"	, oFont12b )
oPrint:Say( nlinha + 10 , nColInic + 0870 , "1a U.M."			, oFont12b )
oPrint:Say( nlinha + 10 , nColInic + 1285 , "2a U.M."			, oFont12b )
oPrint:Say( nlinha + 10 , nColInic + 1640 , "FRETE"				, oFont12b )
oPrint:Say( nlinha + 10 , nColInic + 1840 , "MÉDIA"				, oFont12b )
oPrint:Say( nlinha + 10 , nColInic + 2050 , "VALOR BRUTO"		, oFont12b )
If MV_PAR19 == 1 // Com Carga   (_cAlias)->DAK_COD
   oPrint:Say( nlinha + 10 , nColInic + 2410, "CARGA"		, oFont12b )
   oPrint:Say( nlinha + 10 , nColInic + 2590, "CLIENTE"	, oFont12b )
EndIf

Return

/*
===============================================================================================================================
Programa--------: ROMS0563
Autor-----------: Alex Wallauer Ferreira
Data da Criacao-: 07/05/2019
Descrição-------: Processa a impressao dos dados
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0563( cTransport , nqtde1 , cum1 , nqtde2 , cum2 , nFrete , nValBrut )
Local nColAux:=nColInic
oPrint:Say( nlinha + 10 , nColInic + 0010 , SubStr(cTransport,1,46)											, oFont10 )
nColInic:=nColInic-30
oPrint:Say( nlinha + 10 , nColInic + 0765 , Transform(nqtde1,"@E 999,999,999.99") + "-"+ PadR(cum1,2," ")	, oFont10 )
oPrint:Say( nlinha + 10 , nColInic + 1180 , Transform(nqtde2,"@E 999,999,999.99") + "-"+ PadR(cum2,2," ")	, oFont10 )
oPrint:Say( nlinha + 10 , nColInic + 1510 , 'R$ ' + Transform(nFrete,"@E 999,999,999.99")					, oFont10 )
oPrint:Say( nlinha + 10 , nColInic + 1700 , Transform(nFrete / nqtde1 ,"@E 999,999,999.99999")				, oFont10 )
oPrint:Say( nlinha + 10 , nColInic + 2040 , 'R$ ' + Transform(nValBrut,"@E 999,999,999.99")				, oFont10 )
If MV_PAR19 == 1 // Com Carga   
   oPrint:Say( nlinha + 10 , nColInic + 2440 , (_cAlias)->DAK_COD					, oFont10  )
   oPrint:Say( nlinha + 10 , nColInic + 2620 , (_cAlias)->A1_COD +"-"+ (_cAlias)->A1_NREDUZ+"  ( "+(_cAlias)->A1_EST+" )", oFont10  )
EndIf
nColInic:=nColAux

Return

/*
===============================================================================================================================
Programa--------: ROMS0564
Autor-----------: Alex Wallauer Ferreira
Data da Criacao-: 07/05/2019
Descrição-------: Processa a impressao dos dados
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0564( nTotqtde1 , nTotqtde2 , nTotvlrFre , nTotValBr )
Local nColAux:=nColInic
oPrint:Say( nlinha + 10 , nColInic + 0010 , 'TOTAL:'															, oFont10b )
nColInic:=nColInic-30
oPrint:Say( nlinha + 10 , nColInic + 0765 , Transform(nTotqtde1,"@E 999,999,999.99") + " "+ PadR("",2," ")	, oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 1180 , Transform(nTotqtde2,"@E 999,999,999.99") + " "+ PadR("",2," ")	, oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 1510 , 'R$ ' + Transform(nTotvlrFre,"@E 999,999,999.99")					, oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 1700 , Transform(nTotvlrFre / nTotqtde1 ,"@E 999,999,999.99999")			, oFont10b ) 
oPrint:Say( nlinha + 10 , nColInic + 2040 , 'R$ ' + Transform(nTotValBr,"@E 999,999,999.99")					, oFont10b )
nColInic:=nColAux

Return

/*
===============================================================================================================================
Programa--------: ROMS0565
Autor-----------: Alex Wallauer Ferreira
Data da Criacao-: 07/05/2019
Descrição-------: Processa a impressao dos dados
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ROMS0565( nTotqtde1 , nTotqtde2 , nTotvlrFre , nTotValBr )
Local nColAux:=nColInic

nLinInBox := nLinha

oPrint:Box( nlinha,nColInic,nLinha + nSaltoLinha,nColFinal)

oPrint:Say( nlinha + 10 , nColInic + 0010 , 'TOTAL GERAL:'														, oFont10b )
nColInic:=nColInic-30
oPrint:Say( nlinha + 10 , nColInic + 0765 , Transform(nTotqtde1,"@E 9,999,999,999.99") + " "+ PadR("",2," "), oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 1180 , Transform(nTotqtde2,"@E 9,999,999,999.99") + " "+ PadR("",2," "), oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 1510 , 'R$' + Transform(nTotvlrFre,"@E 9999,999,999.99")					, oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 1700 , Transform(nTotvlrFre / nTotqtde1 ,"@E 999,999,999.99999")			, oFont10b )
oPrint:Say( nlinha + 10 , nColInic + 2040 , 'R$ ' + Transform(nTotValBr,"@E 9,999,999,999.99")					, oFont10b )
nColInic:=nColAux

Return

/*
===============================================================================================================================
Programa--------: ROMS056Z
Autor-----------: Alex Wallauer
Data da Criacao-: 07/05/2019
Descrição-------: Imprime a página de parâmetros do relatório
Parametros------: oPrint - objeto da impressao
Retorno---------: Nenhum
===============================================================================================================================
*/               
Static Function ROMS056Z(oPrint)
Local _aDadosPegunte := {}
Local _nI
Local _cTexto

aAdd(_aDadosPegunte,{"01", "Filial ?"               , "MV_PAR01"})       
aAdd(_aDadosPegunte,{"02", "De Emissao ? "          , "MV_PAR02"})           
aAdd(_aDadosPegunte,{"03", "Ate Emissao ?"          , "MV_PAR03"})
aAdd(_aDadosPegunte,{"04", "De Produto ? "          , "MV_PAR04"})           
aAdd(_aDadosPegunte,{"05", "Ate Produto ?"          , "MV_PAR05"})
aAdd(_aDadosPegunte,{"06", "De Cliente ? "          , "MV_PAR06"})
aAdd(_aDadosPegunte,{"07", "Loja ?   "              , "MV_PAR07"})  
aAdd(_aDadosPegunte,{"08", "Ate Cliente ? "         , "MV_PAR08"})  
aAdd(_aDadosPegunte,{"09", "Loja ?"                 , "MV_PAR09"})       
aAdd(_aDadosPegunte,{"10", "Rede ?"                 , "MV_PAR10"})           
aAdd(_aDadosPegunte,{"11", "Estado ?"               , "MV_PAR11"})
aAdd(_aDadosPegunte,{"12", "Municipio ?"            , "MV_PAR12"})           
aAdd(_aDadosPegunte,{"13", "Vendedor ?  "           , "MV_PAR13"})          
aAdd(_aDadosPegunte,{"14", "Supervisor ? "          , "MV_PAR14"})
aAdd(_aDadosPegunte,{"15", "Grupo Produto ? "       , "MV_PAR15"})
aAdd(_aDadosPegunte,{"16", "Produto Nivel 2 ?"      , "MV_PAR16"})  
aAdd(_aDadosPegunte,{"17", "Produto Nivel 3 ?"      , "MV_PAR17"})  
aAdd(_aDadosPegunte,{"18", "Produto Nivel 4 ?"      , "MV_PAR18"})
aAdd(_aDadosPegunte,{"19", "Considerar Carga ?"     , "MV_PAR19"})
aAdd(_aDadosPegunte,{"20", "Transportaodora ?"      , "MV_PAR20"})
aAdd(_aDadosPegunte,{"21", "CFOP's ? "              , "MV_PAR21"})
aAdd(_aDadosPegunte,{"22", "Possui Frete ?"         , "MV_PAR22"})
aAdd(_aDadosPegunte,{"23", "Sub Grupo Produto ? "   , "MV_PAR23"})
aAdd(_aDadosPegunte,{"24", "Tipo de Carga ?  "      , "MV_PAR24"})
aAdd(_aDadosPegunte,{"25", "Tipo de Fornecedor ? "  , "MV_PAR25"})
aAdd(_aDadosPegunte,{"26", "Rel Excel / Tela / Imp ?","MV_PAR26"})
aAdd(_aDadosPegunte,{"27", "Armazéns ?"             , "MV_PAR27"})
aAdd(_aDadosPegunte,{"28", "Averbacao Forn ?"       , "MV_PAR28"})
aAdd(_aDadosPegunte,{"29", "Tipo de frete ?"        , "MV_PAR29"})
aAdd(_aDadosPegunte,{"30", "Ordem do Relatorio ?"   , "MV_PAR30"})

If oPrint <> NIL	
   nLinha+= 080                                    
   oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
   nLinha+= 60
EndIf
For _nI := 1 To Len(_aDadosPegunte)          
	    
	If _aDadosPegunte[_nI,3] == "MV_PAR19"
	   If MV_PAR19 ==  1
	      _cTexto := "Sim"
	   ElseIf MV_PAR19 == 2
	      _cTexto := "Nao"
	   Else
	      _cTexto := ""
	   EndIf
	
	ElseIf _aDadosPegunte[_nI,3] == "MV_PAR22"
	   If MV_PAR22 ==  1
	      _cTexto := "Sim"
	   ElseIf MV_PAR22 == 2
	      _cTexto := "Não"
	   Else
	      _cTexto := "Ambos"
	   EndIf
	
	ElseIf _aDadosPegunte[_nI,3] == "MV_PAR26"
	   If MV_PAR26 ==  1
	      _cTexto := "Excel"
	   ElseIf MV_PAR26 == 2
	      _cTexto := "Tela"
	   ElseIf MV_PAR26 == 3
	      _cTexto := "Impressora"
	   Else
	      _cTexto := ""
	   EndIf
    
    ElseIf _aDadosPegunte[_nI,3] == "MV_PAR28"
	   If MV_PAR28 ==  1
	      _cTexto := "Com Averbação"
	   ElseIf MV_PAR28 == 2
	      _cTexto := "Sem Averbação"
	   Else
	      _cTexto := "Ambos"
	   EndIf

	ElseIf _aDadosPegunte[_nI,3] == "MV_PAR30"
	   If MV_PAR30 ==  1
	      _cTexto := "Fechamento x Produto"
	   ElseIf MV_PAR30 == 2
	      _cTexto := "Fechamento x SubGrupo"
	   Else
	      _cTexto := ""
	   EndIf
	   
    Else
       _cTexto := &(_aDadosPegunte[_nI,3])
       If ValType(_cTexto) == "D"
          _cTexto := DToC(_cTexto)
       EndIf   
		
    EndIf	

   If oPrint <> NIL	
       oPrint:Say (nLinha,nColInic + 10,"Pergunta " + _aDadosPegunte[_nI,1] + ':  ' +  _aDadosPegunte[_nI,2] , oFont14Prb)    
       oPrint:Say (nLinha,1050,_cTexto,oFont14Prb)  			    
   	 nLinha+= 60
   Else    

      aAdd(_aDadosPar,{"Pergunta " + _aDadosPegunte[_nI,1] + ':',_aDadosPegunte[_nI,2],_cTexto, , , , , , , , , , , , })
      aAdd(_aPergunte,{"Pergunta " + _aDadosPegunte[_nI,1] + ':',_aDadosPegunte[_nI,2],_cTexto })

   EndIf

Next

If oPrint <> NIL	
   nLinha+= 60
   oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
   oPrint:EndPage()     // Finaliza a página
EndIf

Return
