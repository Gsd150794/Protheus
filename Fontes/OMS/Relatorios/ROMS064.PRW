/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer | 23/02/2023 | Chamado 43076. Busca da Assistente no Cadastro de Assistente Adm Comercial responsável.
Igor Fricks   | 02/02/2024 | Chamado 46192. Ajuste para impressão do campo Shelf Life P.
Lucas Borges  | 22/04/2025 | Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
=================================================================================================================================================================
Analista         - Programador    - Inicio     - Envio    - Chamado - Motivo da Alteração
=================================================================================================================================================================
Jerry Santiago   - Julio Paz      - 14/07/2025 - 21/07/25 - 50633   - Inclusão do novo campo Kit de Vendas no relatório.
=================================================================================================================================================================

*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ROMS064
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/12/2020
Descrição---------: Novo Relatório da emissão do espelho de pedidos de vendas. Lê os dados das tabelas SC5 e SC6. É uma versão 
                    do fonte ROMS035 que lê os dados da tabela SZW. Chamado 34671.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS064()

Begin Sequence
   
   If U_ITMsg("Confirma a Impressão do Espelho de Pedido de Vendas para o Pedido Posicionado?","Atenção" , , ,2, 2) 
      FWMsgRun(,{|oproc| U_ROMS064R(oproc)},"Aguarde...","Imprimindo espelho do pedido...")
   EndIf 

End Sequence 

Return 

/*
===============================================================================================================================
Programa----------: ROMS064RUN
Autor-------------: Julio de Paula Paz
Data da Criacao---: 08/12/2020
Descrição---------: Relatório da emissão do espelho de pedidos de vendas para as tabelas SC5 e SC6. Uma versão do fonte
                    ROMS035 que roda sobre a tabela SZW.
Parametros--------: oproc
Retorno-----------: Nenhum
===============================================================================================================================
*/                        

User Function ROMS064RUN(oproc)

Local _oPrint		:= NIL 
Local _cAliasD	:= CriaTrab(Nil,.F.)
Local _cAlias		:= CriaTrab(Nil,.F.)
Local _cQuery		:= ""
Local _nCount		:= 0           
Local _oFont09 	:= TFont():New("Arial",9,7 ,.T.,.F.,5,.T.,5,.T.,.F.)
Local _oFont10 	:= TFont():New("Arial",9,08,.T.,.F.,5,.T.,5,.T.,.F.)
Local _oFont10n	:= TFont():New("Arial",9,08,.T.,.T.,5,.T.,5,.T.,.F.)
Local _oFont14n	:= TFont():New("Arial",9,12,.T.,.T.,5,.T.,5,.T.,.F.)
Local _oFont16 	:= TFont():New("Arial",9,14,.T.,.F.,5,.T.,5,.T.,.F.)
Local _oFont16n	:= TFont():New("Arial",9,14,.T.,.T.,5,.T.,5,.T.,.F.)
Local _oFont48n	:= TFont():New("Arial",9,44,.T.,.T.,5,.T.,5,.T.,.F.)
Local I				:= 0
Local _cTipo		:= ""
Local _cCoord		:= ""
Local _cSuperv      := ""
Local _dData		:= SToD('')
Local _cHora		:= ''
Local cDesCondCli   := ''
Local cDesCond      := ''
Local _cDescTipo    := ""
Private _lInvAll	:= .F.
Private _cMark	:= GetMark()
Private _oMark	:= NIL
Private _nTotPVImposto := 0

Begin Sequence 

   //====================================================================================================
   // Calcula o valor total do pedido de vendas com impostos
   //====================================================================================================
   oproc:cCaption := "Calculando total do pedido de vendas com impostos..." 
   _nTotPVImposto := U_ROMS064I() // Retorna o total do pedido de vendas com impostos


   //====================================================================================================
   // Inicializa o objeto de impressão
   //====================================================================================================
   _oPrint := TMSPrinter():New( "Espelho de Pedido" )
   _oPrint:SetPortrait()
   _oPrint:StartPage()
	
   oproc:cCaption := "Imprimindo pedido..." 
   ProcessMessages()
		
   _cQuery := " SELECT "
   _cQuery += "     ZM.ZZM_DESCRI DESCR,"
   _cQuery += "     SC5.C5_I_OPER TIPO,"
   _cQuery += "     SC5.C5_VEND1 VEND,"
   _cQuery += "     SC5.C5_I_IDPED NUMPED,"
   _cQuery += "     SC6.C6_PEDCLI PEDCLI,"
   _cQuery += "     SC5.C5_I_DTENT DTENTR,"
   _cQuery += "     SC5.C5_FILIAL FILIAL,"
   _cQuery += "     SC6.C6_FILIAL FILPRO,"		
   _cQuery += "     SC5.C5_EMISSAO EMISS,"
   _cQuery += "     SC5.C5_CLIENTE CODCLI,"
   _cQuery += "     SC5.C5_LOJACLI LOJCLI,"
   _cQuery += "     SC5.C5_I_HOREN HRENT,"
   _cQuery += "     SC5.C5_I_SENHA SENHA,"
   _cQuery += "     SC5.C5_I_EVENT EVENTO,"
   _cQuery += "     SC5.C5_TPFRETE TPFRET,"
   _cQuery += "     SC5.C5_I_TIPCA TIPCAR,"
   _cQuery += "     SC5.C5_I_CHAPA CHAPA,"
   _cQuery += "     SC5.C5_I_HORDE HRDES,"
   _cQuery += "     SC5.C5_I_CUSDE CUSDES,"
   _cQuery += "     SC5.C5_I_OBPED OBSCOM,"
   _cQuery += "     SC5.C5_MENNOTA MENNF,"
   _cQuery += "     SC6.C6_ITEM ITEM,"
   _cQuery += "     SC6.C6_PRODUTO PROD,"
   _cQuery += "     SC6.C6_QTDVEN QTDVEN,"
   _cQuery += "     SC6.C6_UM UM1,"
   _cQuery += "     SC6.C6_PRCVEN  PRCVEN,"
   _cQuery += "     SC6.C6_I_KIT KIT," 
   _cQuery += "     (SC6.C6_QTDVEN * SC6.C6_PRCVEN ) TOTAL,"
   _cQuery += "     A1.A1_CGC CGC,"
   _cQuery += "     A1.A1_CONTATO CONTATO,"
   _cQuery += "     (A1.A1_DDD||'-'||A1.A1_TEL) TEL,"
   _cQuery += "     A1.A1_NOME NOME,"
   _cQuery += "     A1.A1_EMAIL EMAIL,"
   _cQuery += "     A1.A1_MUN MUN,"
   _cQuery += "     A1.A1_EST EST,"
   _cQuery += "     A1.A1_END ENDEREC,"
   _cQuery += "     A1.A1_BAIRRO BAIRRO,"
   _cQuery += "     A1.A1_CEP CEP,"
	_cQuery += "     A1.A1_I_SHLFP SHELF,"
   _cQuery += "     SC5.C5_CONDPAG COND,"
   _cQuery += "     A1.A1_COND CONDPA,"
   _cQuery += "     SC5.C5_I_HREMI HRINC,"
   _cQuery += "     SC5.C5_I_DATAA DATAAPR,"
   _cQuery += "     SC5.C5_I_HORAA HRAPR,"
   _cQuery += "	 SC5.C5_I_EVENT EVENTO,"
   _cQuery += "	 SC5.C5_I_AGEND TPENT," 
   _cQuery += "   	 DECODE ( C5_I_AGEND,'A','AGENDADA','I','IMEDIATO','M','AGENDADA C/MULTA','P','AGUARD.AGENDA') DESCTIPO,"
   _cQuery += "     SC5.R_E_C_N_O_ REGSC5, "
   _cQuery += "     SC5.C5_I_TPVEN TPVEN "
   _cQuery += " FROM "+ RetSqlName('SC5') +" SC5, "+ RetSqlName('SC6') +" SC6, "+ RetSqlName('ZZM') +" ZM, "+ RetSqlName('SA1') +" A1 " 
   _cQuery += " WHERE "
   _cQuery += "     SC5.C5_FILIAL  = SC6.C6_FILIAL "
   _cQuery += " AND SC5.C5_NUM     = SC6.C6_NUM "
   _cQuery += " AND A1.A1_COD     = SC5.C5_CLIENTE "
   _cQuery += " AND A1.A1_LOJA    = SC5.C5_LOJACLI "
   _cQuery += " AND ZM.ZZM_CODIGO = SC5.C5_FILIAL  "
   _cQuery += " AND A1.D_E_L_E_T_ = ' ' "
   _cQuery += " AND ZM.D_E_L_E_T_ = ' ' "          
   _cQuery += " AND SC5.D_E_L_E_T_ = ' ' "
   _cQuery += " AND SC6.D_E_L_E_T_ = ' ' "
   _cQuery += " AND SC5.C5_FILIAL  = '" + SC5->C5_FILIAL + "' "
   _cQuery += " AND SC5.C5_NUM     = '" + SC5->C5_NUM    + "' "

   If Select(_cAliasD) > 0
	  (_cAliasD)->( DBCloseArea() )
   EndIf
	
   //DBUseArea( .T. , "TOPCONN" , TcGenQy(,,_cQuery) , _cAliasD , .T. , .F. )  
     MPSysOpenQuery( _cQuery , _cAliasD)
		
   DBSelectArea(_cAliasD)
   (_cAliasD)->( DBGoTop() )
		
   COUNT TO _nCount
		
   (_cAliasD)->( DBGoTop() )
		
   ProcRegua(_nCount)
		
   If _nCount > 0
		
	  DBSelectArea("SA3")
	  SA3->( DBSetOrder(1) )
	  If SA3->( DBSeek( xFilial("SA3") + (_cAliasD)->VEND ))
	 	 _cCoord  := SA3->A3_SUPER
	     _cSuperv := SA3->A3_I_SUPE 
	  EndIf

	  _dData := Date()
	  _cHora := SubStr( Time() , 1 , 5 )

	  _oPrint:StartPage()
	  _oPrint:SayBitmap( 70 , 0100 , "\SYSTEM\lgrl01.bmp" , 350 , 209 )
			
	  _cTipo := (_cAliasD)->TIPO
	  _cDescTipo := ""
        
	  If _cTipo == "01"
	     _cDescTipo := "Venda de Mercadorias"
	  ElseIf _cTipo == "10"
	     _cDescTipo := "Bonificação"  
	  ElseIf _cTipo == "24"
	     _cDescTipo := "Data Crítica"  
	  ElseIf _cTipo == "05"
	     _cDescTipo := "Triangular"  
	  ElseIf (_cAliasD)->TPFRET == "F"
	     _cDescTipo := "Frete FOB"  
	  EndIf

	  _oPrint:Say( 100 , 0460 , "Unidade: "+ AllTrim( (_cAliasD)->DESCR )												, _oFont16n	)
	  _oPrint:Say( 180 , 0460 , _cDescTipo , _oFont16	)
	  _oPrint:Say( 240 , 1150 , "Espelho do Pedido Protheus"																	, _oFont16n	)
	  _oPrint:Say( 300 , 0100 , "Informações Gerais: "																, _oFont14n	)
			
	  cNmVend	:= GetAdvFVal( "SA3" , "A3_NOME"	, xFilial("SA3") + (_cAliasD)->VEND		, 1 , "" )
	  cNmCoord	:= GetAdvFVal( "SA3" , "A3_NOME"	, xFilial("SA3") + _cCoord				, 1 , "" )
	  cNmSuper	:= GetAdvFVal( "SA3" , "A3_NOME"	, xFilial("SA3") + _cSuperv				, 1 , "" )
		 
	  cDesCond	:= (_cAliasD)->COND   + "  --  " + GetAdvFVal( "SE4" , "E4_DESCRI"	, xFilial("SE4") + (_cAliasD)->COND		, 1 , "" )
 	  cDesCondCli	:= (_cAliasD)->CONDPA + "  --  " + GetAdvFVal( "SE4" , "E4_DESCRI"	, xFilial("SE4") + (_cAliasD)->CONDPA	, 1 , "" )
			
	  _oBrush1	:= TBrush():New( , CLR_HGRAY )
			
	  _oPrint:FillRect( { 400 , 0100 , 440 , 2300 } , _oBrush1 ) 
	  _oPrint:FillRect( { 400 , 0950 , 440 , 2300 } , _oBrush1 ) 
      _oPrint:FillRect( { 400 , 1620 , 440 , 2300 } , _oBrush1 )
 
	  _oPrint:FillRect( { 480 , 0100 , 520 , 0600 } , _oBrush1 )
	  _oPrint:FillRect( { 480 , 0600 , 520 , 1200 } , _oBrush1 )
	  _oPrint:FillRect( { 480 , 1200 , 520 , 1800 } , _oBrush1 )
	  _oPrint:FillRect( { 480 , 1800 , 520 , 2300 } , _oBrush1 )
	    	 
	  _oPrint:Box( 400 , 0100 , 440 , 2300 ) 
	  _oPrint:Box( 440 , 0100 , 480 , 2300 )
			
	  _oPrint:Box( 400 , 950 , 440 , 2300 ) 
	  _oPrint:Box( 440 , 950 , 480 , 2300 )

	  _oPrint:Box( 400 , 1620 , 440 , 2300 )   
	  _oPrint:Box( 440 , 1620 , 480 , 2300 )   
			
	 // _oPrint:Box( 480 , 0100 , 520 , 0400 )
	 // _oPrint:Box( 520 , 0100 , 560 , 0400 )

	  _oPrint:Box( 480 , 0100 , 520 , 0440 )
	  _oPrint:Box( 520 , 0100 , 560 , 0440 ) 

	  //_oPrint:Box( 480 , 0400 , 520 , 1200 )
	  //_oPrint:Box( 520 , 0400 , 560 , 1200 )
	  _oPrint:Box( 480 , 0440 , 520 , 1200 )
	  _oPrint:Box( 520 , 0440 , 560 , 1200 )
			
	  _oPrint:Box( 480 , 1200 , 520 , 1800 )
	  _oPrint:Box( 520 , 1200 , 560 , 1800 )
			
	  _oPrint:Box( 480 , 1800 , 520 , 2300 )
	  _oPrint:Box( 520 , 1800 , 560 , 2300 )
			
	  _oPrint:Say( 405 , 0110 , "Codigo / Representante"						, _oFont10n ,,, 2	)
	  _oPrint:Say( 445 , 0110 , (_cAliasD)->VEND +" / "+ cNmVend				, _oFont09			)
			
	  _oPrint:Say( 405 , 0960 , "Codigo / Supervisor"					    	, _oFont10n ,,, 2	)  
	  _oPrint:Say( 445 , 0960 , _cSuperv + " / " + cNmSuper					    , _oFont09		)  

 	  _oPrint:Say( 405 , 1630 , "Codigo / Coordenador"						    , _oFont10n ,,, 2 )  
	  _oPrint:Say( 445 , 1630 , _cCoord +" / "+ cNmCoord						, _oFont09		  )  
			
	  _oPrint:Say( 485 , 0110 , "Ped.Portal/Ped.Prot."	    		, _oFont10n			)
	  _oPrint:Say( 525 , 0110 , AllTrim((_cAliasD)->NUMPED) +" / "+SC5->C5_NUM			, _oFont09			)
			
	  //_oPrint:Say( 485 , 0410 , "FiL Faturamento / Fil Carregamento"			, _oFont10n			)
	  //_oPrint:Say( 525 , 0410 , (_cAliasD)->FILIAL +" - "+ AllTrim((_cAliasD)->DESCR),_oFont09			)
	  _oPrint:Say( 485 , 0450 , "FiL Faturamento / Fil Carregamento"			, _oFont10n			)
	  _oPrint:Say( 525 , 0450 , (_cAliasD)->FILIAL +" - "+ AllTrim((_cAliasD)->DESCR),_oFont09			)
		
	  _oPrint:Say( 485 , 1210 , "Cond. Pagto. Pedido:"				, _oFont10n			)
	  _oPrint:Say( 525 , 1210 , cDesCond										, _oFont09			)
			
	  _oPrint:Say( 485 , 1810 , "Cond. Pagto Cliente:"				, _oFont10n			)
	  _oPrint:Say( 525 , 1810 , cDesCondCli									, _oFont09			)
					
	  _oPrint:FillRect( { 560 , 0100 , 600 , 0800 } , _oBrush1 ) 
	  _oPrint:FillRect( { 560 , 0800 , 600 , 2300 } , _oBrush1 )
			
	  _oPrint:Box( 560 , 0100 , 600 , 0800 )
	  _oPrint:Box( 600 , 0100 , 640 , 0800 )
	  _oPrint:Box( 560 , 0800 , 600 , 1500 )
	  _oPrint:Box( 600 , 0800 , 640 , 1500 )
	  _oPrint:Box( 560 , 1500 , 600 , 2300 )
	  _oPrint:Box( 600 , 1500 , 640 , 2300 )
			
	  _oPrint:Say( 565 , 0110 , "Dt/Hr Inc.Ven."										, _oFont10n	)
	  _oPrint:Say( 605 , 0110 , DToC( SToD( (_cAliasD)->EMISS ) )		+" - "+ (_cAliasD)->HRINC +" hs"	, _oFont10	)
			
	  _oPrint:Say( 565 , 0810 , "Dt/Hr de Aprovação"									, _oFont10n	)
	  _oPrint:Say( 605 , 0810 , DToC( SToD( (_cAliasD)->DATAAPR ) )	+" - "+ (_cAliasD)->HRAPR +" hs"	, _oFont10	)
			
	  _oPrint:Say( 565 , 1510 , "Dt/Hr Impr."										, _oFont10n	)
	  _oPrint:Say( 605 , 1510 , DToC( _dData ) +" - "+ _cHora +" hs"										, _oFont10	)
		 	
	  cQtCol := 660
			
	  _oPrint:Say( cQtCol , 0100 , "Informações do Cliente: "			, _oFont14n )
			
	  cQtCol += 060
			
	  _oPrint:FillRect( { cQtCol , 0100 , cQtCol+40 , 1000 } , _oBrush1 )
	  _oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 1000 )
	    	
	  _oPrint:Say( cQtCol + 5 , 0110 , "Nome:" , _oFont10n )
			
	  cQt1Col := cQtCol
	  cQtCol	+= 40
			
	  _oPrint:FillRect( { cQt1Col , 1000 , cQt1Col + 40 , 2000 }	, _oBrush1	)
	  _oPrint:FillRect( { cQt1Col , 2000 , cQt1Col + 40 , 2300 }	, _oBrush1	)
	  
			
	  _oPrint:Line( cQt1Col, 100, cQt1Col, 2300)
	  _oPrint:Box( cQt1Col, 1800 , cQt1Col + 40 , 2000 )
	  _oPrint:Box( cQtCol , 0100 , cQtCol  + 40 , 1800 )
	  _oPrint:Box( cQtCol , 1800 , cQtCol  + 40 , 2000 )
	  _oPrint:Box( cQt1Col, 2000 , cQt1Col + 40 , 2300 )
	  _oPrint:Box( cQtCol , 2000 , cQtCol  + 40 , 2300 )
		    
	  //===================================================================
	  //Busca informações de rede do cliente para apresentar na descrição
	  //===================================================================
	  _crede := Posicione("SA1",1,xFilial("SA1")+(_cAliasD)->CODCLI+(_cAliasD)->LOJCLI,"A1_GRPVEN")
		    
	  If Empty(_crede) .Or. AllTrim(_crede) == "999999"
	     _cdescr := ""
	  Else
	     ACY->( DBSetOrder(1) )
		 If ACY->( DBSeek( xFilial("ACY") + AllTrim(_crede) ) )
		 	_cdescr := " - " + AllTrim( ACY->ACY_DESCRI )
		 Else
		 	_cdescr := ""
		 EndIf
      EndIf		    

	  _oPrint:Say( cQtCol + 5 , 0110 , AllTrim((_cAliasD)->NOME)            				, _oFont09		)
	  _oPrint:Say( cQtCol + 5 , 0110 + (Len(AllTrim((_cAliasD)->NOME)) * 18) , _cdescr		, _oFont10n	)
	  _oPrint:Say( cQt1Col + 5 , 1810 , "Cód./Loja:"											, _oFont10n 	)
	  _oPrint:Say( cQtCol  + 5 , 1810 , (_cAliasD)->CODCLI +" / "+ (_cAliasD)->LOJCLI		, _oFont09  	)
			
	  _oPrint:Say( cQt1Col + 5 , 2010 , "CPF/CNPJ:"										, _oFont10n )
	  _oPrint:Say( cQtCol  + 5 , 2010 , Transform( (_cAliasD)->CGC , IIf( Len( AllTrim( (_cAliasD)->CGC ) ) > 11 , "@R! NN.NNN.NNN/NNNN-99" , "@R 999.999.999-99" ) ) , _oFont09 )
			
	  cQtCol := cQtCol+40
	
	  _oPrint:FillRect( { cQtCol , 0100 , cQtCol + 40 , 2300 } , _oBrush1 )
	  _oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 2300 )
			
	  _oPrint:Say( cQtCol + 5 , 0110 , "Contato:"		, _oFont10n )
			
	  cQt1Col	:= cQtCol
	  cQtCol	+= 40
			
  	  _oPrint:FillRect( { cQt1Col , 0800 , cQt1Col + 40 , 1600 } , _oBrush1 )
	  _oPrint:FillRect( { cQt1Col , 1600 , cQt1Col + 40 , 2300 } , _oBrush1 )
			
	  _oPrint:Box( cQtCol	 , 0100 , cQtCol  + 40 , 0800 )
	  _oPrint:Box( cQt1Col , 0800 , cQt1Col + 40 , 1600 )
	  _oPrint:Box( cQtCol	 , 0800 , cQtCol  + 40 , 1600 )
	  _oPrint:Box( cQt1Col , 1600 , cQt1Col + 40 , 2300 )
	  _oPrint:Box( cQtCol  , 1600 , cQtCol  + 40 , 2300 )
	  _oPrint:Box( cQt1Col , 2110 , cQt1Col + 40 , 2300 )
	  _oPrint:Box( cQtCol  , 2110 , cQtCol  + 40 , 2300 )

	  _oPrint:Say( cQtCol  + 5 , 0110 , (_cAliasD)->CONTATO	, _oFont09	)
			
	  _oPrint:Say( cQt1Col + 5 , 0810 , "Tel.:"				, _oFont10n	)
	  _oPrint:Say( cQtCol  + 5 , 0810 , (_cAliasD)->TEL		, _oFont09	)
			
	  _oPrint:Say( cQt1Col + 5 , 1610 , "E-Mail:"				, _oFont10n	)
	  _oPrint:Say( cQtCol  + 5 , 1610 , (_cAliasD)->EMAIL		, _oFont09	)

	  _oPrint:Say( cQt1Col + 5 , 2120 , "Shelf Life P:"				, _oFont10n	)
	  _oPrint:Say( cQtCol  + 5 , 2120 , (_cAliasD)->SHELF		, _oFont09	)
	
	  cQtCol += 40
			
	  _oPrint:FillRect( {cQtCol,0100, cQtCol+40, 2300}, _oBrush1 )
	    	
	  _oPrint:Box (cQtCol,0100,cQtCol+40,800)
			
	  _oPrint:Say  (cQtCol+5,0110,"Cidade:"	,_oFont10n )
			
	  cQt1Col	:= cQtCol
	  cQtCol	:= cQtCol + 40
			
	  _cENDEREC := (_cAliasD)->ENDEREC

	  If Mod( Len( _cENDEREC ) , 35 ) > 0 
	     _n1 :=  1 
	  Else
		 _n1 :=  0
	  EndIf 

	  _n2:= INT( Len( AllTrim( _cENDEREC ) ) / 35 )  

	  _ncalc := (_n1 + _n2) * 40

	  cQt2Col	:= cQtCol + _ncalc
		   
	  _oPrint:FillRect( { cQt1Col , 0800 , cQt1Col + 40 , 1600 } , _oBrush1 )
	  _oPrint:FillRect( { cQt1Col , 1600 , cQt1Col + 40 , 2300 } , _oBrush1 )
		    
	  _oPrint:Box( cQtCol	, 0100 , cQt2Col		, 0800 )
	  _oPrint:Box( cQt1Col, 0800 , cQt1Col + 40	, 1600 )
	  _oPrint:Box( cQtCol	, 0800 , cQt2Col		, 1600 )
	  _oPrint:Box( cQt1Col, 1600 , cQt1Col + 40	, 2300 )
	  _oPrint:Box( cQtCol	, 1600 , cQt2Col		, 2300 )
			
	  _oPrint:Say( cQtCol  + 5 , 0110 , (_cAliasD)->MUN		, _oFont09	)
			
	  _oPrint:Say( cQt1Col + 5 , 0810 , "Estado:"				, _oFont10n	)
	  _oPrint:Say( cQtCol  + 5 , 0810 , (_cAliasD)->EST		, _oFont09	)
			
	  _oPrint:Say( cQt1Col + 5 , 1610 , "Endereço:"			, _oFont10n	)
			
	  lRet	:= .T.
	  _cENDEREC := (_cAliasD)->ENDEREC
	  nQtEnd	:= Len( AllTrim( _cENDEREC ) )
	  nLinEnd	:= cQtCol + 5
	  n		:= 1
			
	  While lRet
	   	 
		 If nQtEnd > 0
			_oPrint:Say( nLinEnd , 1610 , SubStr( (_cAliasD)->ENDEREC , n , 35 )	, _oFont09	)
		 Else
			lRet := .F.
		 EndIf
				
		 n		+= 35
		 nQtEnd	-= 35
		 nLinEnd	+= 40
				
	  EndDo
			
	  cQtCol := cQt2Col + 060
			
	  _oPrint:Say( cQtCol , 0100 , "Dados Financeiros - Analise de Crédito " , _oFont14n )
			
	  aSM0	:= FWLoadSM0()
	  cMvFil	:= ""
			
	  For I := 1 To Len(aSM0)
	      cMvFil += aSM0[I][2] + IIf( I == Len(aSM0) , "" , ";" )
	  Next I
			
	  cTit := " SELECT "
	  cTit += "     SE1.E1_CLIENTE,"
	  cTit += "     SE1.E1_LOJA   ,"
	  cTit += "     ( SELECT SUM(E11.E1_SALDO) "
	  cTit += "       FROM  "+ RETSQLNAME('SE1') +" E11 "
	  cTit += "       WHERE "
	  cTit += "           E11.D_E_L_E_T_ = ' ' "
	  cTit += "       AND E11.E1_SALDO   + E11.E1_SDACRES - E11.E1_SDDECRE > 0 "
	  cTit += "       AND E11.E1_VENCREA < '"+ DToS(Date()) +"' "
	  cTit += "       AND E11.E1_FILIAL  IN "+ FormatIn(cMvFil,";") +" "
	  cTit += "       AND E11.E1_CLIENTE = '"+ (_cAliasD)->CODCLI +"' "
	  cTit += "       AND E11.E1_TIPO    NOT IN ('RA','NCC') ) SLD_VENCTO ,"
	  cTit += "     ( SELECT SUM(E1_SALDO) "
	  cTit += "       FROM  "+ RetSqlName('SE1') +" E12 "
	  cTit += "       WHERE "
	  cTit += "           E12.D_E_L_E_T_ = ' ' "
	  cTit += "       AND E12.E1_SALDO   + E12.E1_SDACRES - E12.E1_SDDECRE > 0 "
	  cTit += "       AND E12.E1_VENCREA >= '"+ DToS(Date()) +"' "
	  cTit += "       AND E12.E1_FILIAL  IN "+ FormatIn(cMvFil,";") +" "
	  cTit += "       AND E12.E1_CLIENTE = '"+ (_cAliasD)->CODCLI +"' "
	  cTit += "       AND E12.E1_TIPO    NOT IN ('RA','NCC') ) SLD_A_VENCTO "
	  cTit += " FROM  "+ RetSqlName('SE1') +" SE1 "
	  cTit += " WHERE "
	  cTit += "     SE1.D_E_L_E_T_ = ' ' "
	  cTit += " AND SE1.E1_FILIAL  IN "+ FormatIn( cMvFil , ";" ) +" "
	  cTit += " AND SE1.E1_CLIENTE = '"+ (_cAliasD)->CODCLI       +"' "
	  cTit += " GROUP BY SE1.E1_CLIENTE, SE1.E1_LOJA "
	 	
	  If Select(_cAlias) > 0
	     (_cAlias)->( DBCloseArea() )
	  EndIf
			
	  //DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cTit) , _cAlias , .T. , .F. )
	  MPSysOpenQuery( cTit , _cAlias)
	 	 	
	  DBSelectArea( _cAlias )
	  (_cAlias)->( DBGoTop() )
			
	  cQtCol := cQtCol + 060
	    	
//*********************************************************************************************************************************************			
	  _oPrint:FillRect( { cQtCol , 0100 , cQtCol + 40 , 800 } , _oBrush1 )
	    	
	  _oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 800 )
			
	  _oPrint:Say( cQtCol + 5 , 0110 , "Titulos Vencidos:"	, _oFont10n	)
			
	  cQt1Col	:= cQtCol
	  cQtCol	+= 40

	  _nCol2:=650
	  _nCol3:=_nCol2+400
			
	  _oPrint:FillRect( {cQt1Col,_nCol2,cQt1Col+40, 2300}, _oBrush1 )
	  
	  _oPrint:Box( cQt1Col , _nCol2 , cQt1Col + 40 , _nCol3 )
	  _oPrint:Box( cQt1Col , _nCol3 , cQt1Col + 40 , 1600   )
	  _oPrint:Box( cQt1Col , 1600   , cQt1Col + 40 , 2300   )
	  
	  _oPrint:Box( cQtCol  , 0100   , cQtCol  + 40 , _nCol2 )
	  _oPrint:Box( cQtCol  , _nCol2 , cQtCol  + 40 , _nCol3 )
	  _oPrint:Box( cQtCol  , _nCol3 , cQtCol  + 40 , 1600   )
	  _oPrint:Box( cQtCol  , 1600   , cQtCol  + 40 , 2300   )


	  _oPrint:Say( cQtCol  + 5 , 0110 , "R$ "+ Transform( (_cAlias)->SLD_VENCTO , "@E 9,999,999,999.99" )	, _oFont09	)
			
//*********************************************************************************************************************************************			
	  _oPrint:Say( cQt1Col + 5 , _nCol2+10 , "Títulos à Vencer:"		 										, _oFont10n	)
	  _oPrint:Say( cQtCol  + 5 , _nCol2+10 , "R$ "+ Transform( (_cAlias)->SLD_A_VENCTO , "@E 99,999,999,999.99" )	, _oFont09	)

//*********************************************************************************************************************************************			
	  cRisCli:=Upper(SA1->A1_RISCO) 
	  nLimCr:= SA1->A1_LC
	  SA1->( DBSetOrder(1) )	        
	  If SA1->( DBSeek( xFilial("SA1") + (_cAliasD)->CODCLI) )
	  	 While SA1->(!Eof()) .And. xFilial("SA1") == SA1->A1_FILIAL .And.  (_cAliasD)->CODCLI == SA1->A1_COD
	  	 	If !Empty(SA1->A1_LC)
	  	 		cRisCli :=  Upper(SA1->A1_RISCO) 
	  	 		nLimCr  := SA1->A1_LC
			   cShelf  := SA1->A1_I_SHLFP
	  	 		Exit
	  	 	EndIf
	  	 	SA1->(DBSkip())
	  	 EndDo
	  EndIf
	  _oPrint:Say( cQt1Col + 5 , _nCol3+10 , "Limite de Credito (Risco):"											, _oFont10n	)
	  _oPrint:Say( cQtCol  + 5 , _nCol3+10 , "R$ "+ Transform( nLimCr , "@E 999,999,999.99" )+" ( "+cRisCli+" )"	, _oFont09	) 

//*********************************************************************************************************************************************			

      _cfilpro := SC5->C5_FILIAL
	  _cvend2 := Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_SUPER")  
	  _cvend3 := Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_GEREN")                                                                                      
					
      _ctab := SC5->C5_I_TAB

	  _oPrint:Say( cQt1Col + 5 , 1610 , "Tabela de preço:"												, _oFont10n	)
	  _oPrint:Say( cQtCol  + 5 , 1610 , _ctab + " - " + Posicione("DA0",1,xFilial("DA0")+_ctab,"DA0_DESCRI")	, _oFont09	)

	  cQtCol += 060
			
	  _oPrint:Say( cQtCol      , 0100 , "Informações do Pedido "											, _oFont14n	)
			
	  cQtCol += 060
		
	  _oPrint:FillRect( { cQtCol , 0100 , cQtCol + 40 , 500 } , _oBrush1 )
			
	  _oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 500 )
			
	  _oPrint:Say( cQtCol + 5 , 0110 , "Pedido do Cliente:"	, _oFont10n )
			
	  cQt1Col	:= cQtCol
	  cQtCol	+= 40
			
	  dDtEntr := If(Empty(AllTrim((_cAliasD)->DTENTR)),"N/A",	SubStr((_cAliasD)->DTENTR,7,2)+"/"+SubStr((_cAliasD)->DTENTR,5,2)+"/"+SubStr((_cAliasD)->DTENTR,1,4))
			
	  _oPrint:FillRect( { cQt1Col , 0500 , cQt1Col + 40 , 1050 } , _oBrush1 )
	  _oPrint:FillRect( { cQt1Col , 1050 , cQt1Col + 40 , 1400 } , _oBrush1 )
	  _oPrint:FillRect( { cQt1Col , 1400 , cQt1Col + 40 , 2300 } , _oBrush1 )
			
	  _oPrint:Box( cQtCol  , 0100 , cQtCol  + 120 , 0500 )
	  _oPrint:Box( cQt1Col , 0500 , cQt1Col + 040 , 1050 )
	  _oPrint:Box( cQtCol  , 0500 , cQtCol  + 120 , 1050 )
	  _oPrint:Box( cQt1Col , 1050 , cQt1Col + 040 , 1400 )
	  _oPrint:Box( cQtCol  , 1050 , cQtCol  + 120 , 1400 )
	  _oPrint:Box( cQt1Col , 1400 , cQt1Col + 040 , 2300 )
	  _oPrint:Box( cQtCol  , 1400 , cQtCol  + 200 , 2300 )

	  //---------------------------------------------------
	  _oPrint:FillRect( { cQtCol + 45  , 1050  , cQtCol + 85 ,  1400 } , _oBrush1 )
	  _oPrint:Box( cQtCol + 45, 1050 , cQtCol + 085 , 1400 )
			
	  _oPrint:Say( cQtCol  + 05 , 0110 , If(Empty(AllTrim((_cAliasD)->PEDCLI)),"N/A",	(_cAliasD)->PEDCLI)	,_oFont09 )
			
	  _oPrint:Say( cQt1Col + 05 , 0510 , "Entrega: " , _oFont10n )
			
	  _oPrint:Say( cQtCol  + 05 , 0510 , "Data: "+  dDtEntr + " - Tp Ent.: " + (_cAliasD)->DESCTIPO           	, _oFont09	)			
	  _oPrint:Say( cQtCol  + 45 , 0510 , "Hora: "+  IIf( Empty( (_cAliasD)->HRENT ) , "N/A" , (_cAliasD)->HRENT )	, _oFont09	)
	  _oPrint:Say( cQtCol  + 85 , 0510 , "Senha: "+ IIf( Empty( (_cAliasD)->SENHA ) , "N/A" , (_cAliasD)->SENHA ) , _oFont09	)
			
	  _oPrint:Say( cQt1Col + 05 , 1060 , "Tipo Frete: "																							, _oFont10n	)
	  _oPrint:Say( cQtCol  + 05 , 1060 , IIf( Empty( (_cAliasD)->TPFRET ) , "N/A" , IIf( AllTrim( (_cAliasD)->TPFRET ) == "C" , "CIF" , "FOB" ) ) , _oFont09	)

//---------------------------------------------------
      _oPrint:Say( cQtCol  + 45 , 1060 , "Tipo de Carga: "		, _oFont10n	)
	  _oPrint:Say( cQtCol  + 85 , 1060 , IIf( Empty( (_cAliasD)->TPVEN ) , "N/A" , IIf( AllTrim( (_cAliasD)->TPVEN ) == "F" , "FECHADA" , "FRACIONADA" ) ) , _oFont09	)	 
//---------------------------------------------------

	  _oPrint:Say( cQt1Col + 05 , 1410 , "Observação (Comercial): " , _oFont10n )
			
	  lRet1	:= .T.
	  nQtObs	:= Len( AllTrim( (_cAliasD)->( StrTran( StrTran( OBSCOM , CHR(13) , " " ) , CHR(10) , " " ) ) ) )
	  n		:= 1
	  nLinEnd	:= cQtCol + 5
			
	  While lRet1
				
	     _cTxtAux := (_cAliasD)->( StrTran( StrTran( OBSCOM , CHR(13) , " " ) , CHR(10) , " " ) )
				
		 If nQtObs > 0
			_oPrint:Say( nLinEnd , 1410 , IIf( Empty( _cTxtAux ) , "Nenhum Registro" , SubStr( _cTxtAux , n , 55 ) ) , _oFont09 )
		 Else
		    lRet1 := .F.
		 EndIf
				
		 nQtObs	-= 55
		 n		+= 55
		 nLinEnd += 40
				
	  EndDo
			
	  cQtCol	+= 120
	  cQt1Col := cQtCol
			
	  _oPrint:FillRect( { cQtCol , 0100 , cQtCol + 40 , 500 } , _oBrush1 )
	    	
	  _oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 500 )
			
	  _oPrint:Say( cQtCol + 5 , 0110 , "Tipo Carga:"	, _oFont10n )
			
	  cQtCol += 40
			
	  _oPrint:FillRect( { cQt1Col , 0500 , cQt1Col + 40 , 0850 } , _oBrush1 )
	  _oPrint:FillRect( { cQt1Col , 0850 , cQt1Col + 40 , 1050 } , _oBrush1 )
	  _oPrint:FillRect( { cQt1Col , 1050 , cQt1Col + 40 , 1400 } , _oBrush1 )
			
	  _oPrint:Box( cQtCol  , 0100 , cQtCol  + 40 , 0500 )
	  _oPrint:Box( cQt1Col , 0500 , cQt1Col + 40 , 0850 )
	  _oPrint:Box( cQtCol  , 0500 , cQtCol  + 40 , 0850 )
	  _oPrint:Box( cQt1Col , 0850 , cQt1Col + 40 , 1050 )
	  _oPrint:Box( cQtCol  , 0850 , cQtCol  + 40 , 1050 )
	  _oPrint:Box( cQt1Col , 1050 , cQt1Col + 40 , 1400 )
	  _oPrint:Box( cQtCol  , 1050 , cQtCol  + 40 , 1400 )
			
	  _oPrint:Say( cQtCol  + 5 , 0110 , IIf( Empty( (_cAliasD)->TIPCAR ) , "N/A" , IIf( (_cAliasD)->TIPCAR == '1' , (_cAliasD)->TIPCAR +" - Paletizada" , (_cAliasD)->TIPCAR +" - Batida" ) ) , _oFont09 )
			
	  _oPrint:Say( cQt1Col + 5 , 0510 , "Quant. Chapa:"		, _oFont10n )
	  _oPrint:Say( cQtCol  + 5 , 0510 , IIf( Empty( (_cAliasD)->CHAPA ) , "N/A" , (_cAliasD)->CHAPA ) , _oFont09 )
			
	  _oPrint:Say( cQt1Col + 5 , 0860 , "Hr. Descarga:"		, _oFont10n )
	  _oPrint:Say( cQtCol  + 5 , 0860 , IIf( Empty( (_cAliasD)->HRDES ) , "N/A" , (_cAliasD)->HRDES)	, _oFont09 )
	 		
	  _oPrint:Say( cQt1Col + 5 , 1060 , "Custo Descarga: "	, _oFont10n )
	  _oPrint:Say( cQtCol  + 5 , 1060 , Transform( (_cAliasD)->CUSDES , "@E 99,999,999.99" )			, _oFont09 )
	 		
	  cQtCol	+= 40
	  cQt1Col := cQtCol
			
	  _oPrint:FillRect( { cQtCol , 0100 , cQtCol + 40 , 1200 } , _oBrush1 )
	     	
	  _oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 1200 )
			
	  _oPrint:Say( cQtCol + 5 , 0110 , "Cliente de Entrega:" , _oFont10n )
			
	  cQtCol += 40
			
	  _oPrint:FillRect( { cQt1Col , 1200 , cQt1Col + 40 , 2300 } , _oBrush1 )
			
	  _oPrint:Box( cQtCol  , 0100 , cQtCol  +240 , 1200 )
	  _oPrint:Box( cQt1Col , 1200 , cQt1Col +040 , 2300 )
	  _oPrint:Box( cQtCol  , 1200 , cQtCol  +240 , 2300 )
			
	  _oPrint:Say( cQtCol  + 005 , 0110 , "Cliente: "+ AllTrim( (_cAliasD)->NOME ) +" - "+ (_cAliasD)->CODCLI +"/"+ (_cAliasD)->LOJCLI	, _oFont09	)
	  _oPrint:Say( cQtCol  + 045 , 0110 , "Endereço: "+ AllTrim( (_cAliasD)->ENDEREC )														, _oFont09	)
	  _oPrint:Say( cQtCol  + 085 , 0110 , "Bairro: "+ (_cAliasD)->BAIRRO																	, _oFont09	)
	  _oPrint:Say( cQtCol  + 125 , 0110 , "CEP: "+ (_cAliasD)->CEP																		, _oFont09	)
	  _oPrint:Say( cQtCol  + 165 , 0110 , "Cidade: "+ (_cAliasD)->MUN																		, _oFont09	)
	  _oPrint:Say( cQtCol  + 205 , 0110 , "Estado: "+ (_cAliasD)->EST																		, _oFont09	)
	  _oPrint:Say( cQt1Col + 005 , 1210 , "Mensagem da Nota Fiscal:"																		, _oFont10n	)
			
	  lRet2	:= .T.
	  nQtMNF	:= Len( AllTrim( (_cAliasD)->MENNF ) )
	  n		:= 1
	  nLinEnd := cQtCol + 5
			
	  While lRet2
			
		 If nQtMNF > 0
			_oPrint:Say( nLinEnd , 1210 , IIf( Empty( AllTrim( (_cAliasD)->MENNF ) ) , "N/A" , SubStr( (_cAliasD)->MENNF , n , 68 ) )	, _oFont09 )
		 Else
			lRet2 := .F.
		 EndIf
				
		 nQtMNF	-= 68
		 n		+= 68
		 nLinEnd += 40
	  EndDo
			
	  cQtCol += 320
			
	  _oPrint:FillRect( { cQtCol , 0100 , cQtCol + 45 , 2300 } , _oBrush1 )
			
	  _oPrint:Box( cQtCol , 0100 , cQtCol + 45 , 2300 )
			
	  _oPrint:Say( cQtCol + 6 , 0110 , "Porcentagem de Leite Magro "			, _oFont10n	)
			
	  If Val((_cAliasD)->EVENTO) > 0
	     _oPrint:Say( cQtCol + 6 , 1210 , "Pedido de Evento: " + AllTrim((_cAliasD)->EVENTO)	+ "  -  " + Posicione("ZY4",1,xFilial("ZY4")+(_cAliasD)->EVENTO,"ZY4_DESCRI"), _oFont10n	)
	  EndIf
			
	  cQtCol += 45
			
	  _oPrint:Box( cQtCol , 0100 , cQtCol + 45 , 2300 )
			
	  _oPrint:Say( cQtCol + 6 , 0110 , AllTrim( Transform( U_ROMS064L(SC5->C5_FILIAL,SC5->C5_NUM) , "@E 999,999,999.99" ) ) +" %"	, _oFont09	) 
			
	  cQtCol += 100
			
	  _oPrint:Say( cQtCol , 0100,"Produtos "	,_oFont14n )
			
	  cQtCol	+= 060
	  cQt1Col := cQtCol
			
	  _oPrint:FillRect( { cQtCol , 0190 , cQtCol + 40 , 0800 } , _oBrush1 ) // 0190 - 0850
	  _oPrint:FillRect( { cQtCol , 0800 , cQtCol + 40 , 0950 } , _oBrush1 ) // 0850 - 1000
	  _oPrint:FillRect( { cQtCol , 0950 , cQtCol + 40 , 1080 } , _oBrush1 ) // 1000 - 1130
	  _oPrint:FillRect( { cQtCol , 1080 , cQtCol + 40 , 1230 } , _oBrush1 ) // 1130 - 1280
	  _oPrint:FillRect( { cQtCol , 1230 , cQtCol + 40 , 1330 } , _oBrush1 ) // 1280 - 1380
	  _oPrint:FillRect( { cQtCol , 1330 , cQtCol + 40 , 1480 } , _oBrush1 ) // 1380 - 1550
	  _oPrint:FillRect( { cQtCol , 1480 , cQtCol + 40 , 1630 } , _oBrush1 ) // 1550 - 1750 ***
	  _oPrint:FillRect( { cQtCol , 1630 , cQtCol + 40 , 1830 } , _oBrush1 ) // 1750 - 2000
	    	
	  _oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 0190 )  // 0100 - 0190
	  _oPrint:Box( cQtCol , 0190 , cQtCol + 40 , 0800 )  // 0190 - 0850
	  _oPrint:Box( cQtCol , 0800 , cQtCol + 40 , 0950 )  // 0850 - 1000
	  _oPrint:Box( cQtCol , 0950 , cQtCol + 40 , 1080 )  // 1000 - 1130
	  _oPrint:Box( cQtCol , 1080 , cQtCol + 40 , 1230 )  // 1130 - 1280
	  _oPrint:Box( cQtCol , 1230 , cQtCol + 40 , 1330 )  // 1280 - 1380
	  _oPrint:Box( cQtCol , 1330 , cQtCol + 40 , 1480 )  // 1380 - 1550
	  _oPrint:Box( cQtCol , 1480 , cQtCol + 40 , 1630 )  // 1550 - 1750 ***
	  _oPrint:Box( cQtCol , 1630 , cQtCol + 40 , 1830 )  // 1750 - 2000
			
	  _oPrint:Say( cQtCol + 5 , 0110 , "Item:"		, _oFont10n ) // 0110
	  _oPrint:Say( cQtCol + 5 , 0195 , "Descrição:"	, _oFont10n ) // 0195
	  _oPrint:Say( cQtCol + 5 , 0810 , "Qtd 2UM:"	, _oFont10n ) // 0860
	  _oPrint:Say( cQtCol + 5 , 0960 , "Seg UM:"	, _oFont10n ) // 1010
	  _oPrint:Say( cQtCol + 5 , 1090 , "Qtd. 1UM:"	, _oFont10n ) // 1140
	  _oPrint:Say( cQtCol + 5 , 1240 , "Unid.:"		, _oFont10n ) // 1290
	  _oPrint:Say( cQtCol + 5 , 1340 , "Prc. Vend.:", _oFont10n ) // 1390
	  _oPrint:Say( cQtCol + 5 , 1490 , "Pes.Bruto:"	, _oFont10n ) // 1560 ***
	  _oPrint:Say( cQtCol + 5 , 1635 , "Total:"		, _oFont10n ) // 1755
			
	  If (_cAliasD)->TIPO == '01' .Or. (_cAliasD)->TIPO == '03'
	     _oPrint:FillRect( { cQtCol , 1830 , cQtCol + 40 , 2030 } , _oBrush1 ) // 2000 - 2200
	     _oPrint:FillRect( { cQtCol , 2030 , cQtCol + 40 , 2130 } , _oBrush1 ) // 2200 - 2400
		 _oPrint:FillRect( { cQtCol , 2130 , cQtCol + 40 , 2300 } , _oBrush1 ) // 2200 - 2400
	    		
		 _oPrint:Box( cQtCol , 1830 , cQtCol + 40 , 2030 ) // 2000 - 2200
		 _oPrint:Box( cQtCol , 2030 , cQtCol + 40 , 2130 ) // 2200 - 2400
		 _oPrint:Box( cQtCol , 2130 , cQtCol + 40 , 2300 ) // 2200 - 2400
				
		 _oPrint:Say( cQtCol + 5 , 1835 , "% Contrato:"	, _oFont10n ) // 2010
		 _oPrint:Say( cQtCol + 5 , 2035 , "Prc Net:"	, _oFont10n ) // 2210
		 _oPrint:Say( cQtCol + 5 , 2135 , "Kit Portal:"	, _oFont10n ) // 2210
      Else 
	     _oPrint:FillRect( { cQtCol , 1830, cQtCol + 40 , 2030 } , _oBrush1 ) // 2200 - 2400
		 _oPrint:Box( cQtCol , 1830 , cQtCol + 40 , 2030) // 2200 - 2400
		 _oPrint:Say( cQtCol + 5 , 1830 , "Kit Portal:"	, _oFont10n ) // 2210
	  EndIf
			
	  cQtCol	+= 40
			
	  nToT1UM	:= 0
	  nToT2UM	:= 0
	  nToTPrc	:= 0
	  nToT	:= 0
	  nTotNet	:= 0
	  nPrcNet	:= 0
	  nTotPes	:= 0
	  nPesBru	:= 0
			
	  While (_cAliasD)->( !Eof() )
	     nFatConv	:= GetAdvFVal( "SB1" , "B1_CONV"	, xFilial("SB1") + (_cAliasD)->PROD , 1 , "" )
		 cTpConv		:= GetAdvFVal( "SB1" , "B1_TIPCONV"	, xFilial("SB1") + (_cAliasD)->PROD , 1 , "" )
		 nNewFat		:= GetAdvFVal( "SB1" , "B1_I_FATCO"	, xFilial("SB1") + (_cAliasD)->PROD , 1 , "" )
				
		 If cTpConv == "M"
			nQtd2UM:= If (nFatConv == 0, nNewFat*(_cAliasD)->QTDVEN,nFatConv*(_cAliasD)->QTDVEN)
		 Else
			nQtd2UM:= If (nFatConv == 0, (_cAliasD)->QTDVEN/nNewFat,(_cAliasD)->QTDVEN/nFatConv)
		 EndIf
				
		 nPesBru := GetAdvFVal("SB1","B1_PESBRU",xFilial("SB1")+(_cAliasD)->PROD,1,"")*(_cAliasD)->QTDVEN
				
		 _oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 0190 ) // 0100 - 0190
		 _oPrint:Box( cQtCol , 0190 , cQtCol + 40 , 0800 ) // 0190 - 0850
		 _oPrint:Box( cQtCol , 0800 , cQtCol + 40 , 0950 ) // 0850 - 1000
		 _oPrint:Box( cQtCol , 0950 , cQtCol + 40 , 1080 ) // 1000 - 1130
		 _oPrint:Box( cQtCol , 1080 , cQtCol + 40 , 1230 ) // 1130 - 1280
		 _oPrint:Box( cQtCol , 1230 , cQtCol + 40 , 1330 ) // 1280 - 1380
		 _oPrint:Box( cQtCol , 1330 , cQtCol + 40 , 1480 ) // 1380 - 1550
		 _oPrint:Box( cQtCol , 1480 , cQtCol + 40 , 1630 ) // 1550 - 1750 *** 
		 _oPrint:Box( cQtCol , 1630 , cQtCol + 40 , 1830 ) // 1750 - 2000
				
		 _oPrint:Say( cQtCol + 5 , 0110 , (_cAliasD)->ITEM																								, _oFont09 ) // 0110
		 _oPrint:Say( cQtCol + 5 , 0195 , AllTrim( SubStr( GetAdvFVal( "SB1" , "B1_I_DESCD" , xFilial("SB1") + (_cAliasD)->PROD , 1 , "" ) , 1 , 45 ) )	, _oFont09 ) // 0195
		 _oPrint:Say( cQtCol + 5 , 0812 , cValToChar( nQtd2UM )																							, _oFont09 ) // 0862
		 _oPrint:Say( cQtCol + 5 , 0960 , GetAdvFVal( "SB1" , "B1_SEGUM" , xFilial("SB1") + (_cAliasD)->PROD , 1 , "" )									, _oFont09 ) // 1010
		 _oPrint:Say( cQtCol + 5 , 1082 , cValToChar( (_cAliasD)->QTDVEN )																				, _oFont09 ) // 1132
		 _oPrint:Say( cQtCol + 5 , 1240 , (_cAliasD)->UM1																								, _oFont09 ) // 1292
		 _oPrint:Say( cQtCol + 5 , 1332 , Transform( (_cAliasD)->PRCVEN , "@E 99,999,999.99" )															, _oFont09 ) // 1382
		 _oPrint:Say( cQtCol + 5 , 1482 , Transform( nPesBru , "@E 9,999,999.999" )																		, _oFont09 ) // 1552 ***
		 _oPrint:Say( cQtCol + 5 , 1632 , Transform( (_cAliasD)->TOTAL , "@E 99,999,999.99" )															, _oFont09 ) // 1752
				
		 aVlrDesc := {}

	     If (_cAliasD)->TIPO == '01' .Or. (_cAliasD)->TIPO == '03' 
			_oPrint:Box( cQtCol , 1830 , cQtCol + 40 , 2030 ) // 2000 - 2200
			_oPrint:Box( cQtCol , 2030 , cQtCol + 40 , 2130 ) // 2200 - 2400
			_oPrint:Box( cQtCol , 2130 , cQtCol + 40 , 2300 ) // 2200 - 2400
					
			aVlrDesc	:= U_veriContrato( (_cAliasD)->CODCLI , (_cAliasD)->LOJCLI , (_cAliasD)->PROD )
			nPrcNet		:= (_cAliasD)->PRCVEN - ( ( aVlrDesc[1] * (_cAliasD)->PRCVEN ) / 100 )
					
			_oPrint:Say( cQtCol + 5 , 1835 , Transform( aVlrDesc[1]	, "@E 99,999,999.99" ) , _oFont09 ) // 2010
			_oPrint:Say( cQtCol + 5 , 2035 , Transform( nPrcNet		, "@E 99,999,999.99" ) , _oFont09 ) // 2210
			_oPrint:Say( cQtCol + 5 , 2135 , (_cAliasD)->KIT, _oFont09 ) // 2210 
        
		 Else 
            _oPrint:Box( cQtCol , 1830 , cQtCol + 40 , 2030 ) // 2000 - 2200		
		    _oPrint:Say( cQtCol + 5 , 1835 , (_cAliasD)->KIT, _oFont09 ) // 2210
		 EndIf
				
		 cQtCol	+= 40
				
		 nToT1UM	+= (_cAliasD)->QTDVEN
		 nToT2UM	+= nQtd2UM
		 nToTPrc	+= (_cAliasD)->PRCVEN
		 nToT	+= (_cAliasD)->TOTAL
		 nTotNet	+= nPrcNet
		 nTotPes	+= nPesBru
		 cTp		:= (_cAliasD)->TIPO
				
		 (_cAliasD)->( DBSkip() )
				
		 If cQtCol > 3450
				
			_oPrint:EndPage()
			_oPrint:StartPage()
					
			cQtCol := 070
					
	    	_oPrint:FillRect( { cQtCol , 0100 , cQtCol + 40 , 0190 } , _oBrush1 ) // 0100 - 0190
			_oPrint:FillRect( { cQtCol , 0190 , cQtCol + 40 , 0800 } , _oBrush1 ) // 0190 - 0700
			_oPrint:FillRect( { cQtCol , 0800 , cQtCol + 40 , 0950 } , _oBrush1 ) // 0700 - 0900
			_oPrint:FillRect( { cQtCol , 0950 , cQtCol + 40 , 1080 } , _oBrush1 ) // 0900 - 1050
			_oPrint:FillRect( { cQtCol , 1080 , cQtCol + 40 , 1230 } , _oBrush1 ) // 1050 - 1250
			_oPrint:FillRect( { cQtCol , 1230 , cQtCol + 40 , 1330 } , _oBrush1 ) // 1250 - 1350
			_oPrint:FillRect( { cQtCol , 1330 , cQtCol + 40 , 1480 } , _oBrush1 ) // 1380 - 1500
			_oPrint:FillRect( { cQtCol , 1480 , cQtCol + 40 , 1630 } , _oBrush1 ) // 1550 - 1700 ***
			_oPrint:FillRect( { cQtCol , 1630 , cQtCol + 40 , 1880 } , _oBrush1 ) // 1700 - 2000
				
			_oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 0190 ) // 0100 - 0190
			_oPrint:Box( cQtCol , 0190 , cQtCol + 40 , 0800 ) // 0190 - 0700
			_oPrint:Box( cQtCol , 0800 , cQtCol + 40 , 0950 ) // 0700 - 0900
			_oPrint:Box( cQtCol , 0950 , cQtCol + 40 , 1080 ) // 0900 - 1050
			_oPrint:Box( cQtCol , 1080 , cQtCol + 40 , 1230 ) // 1050 - 1250
			_oPrint:Box( cQtCol , 1230 , cQtCol + 40 , 1330 ) // 1250 - 1350
			_oPrint:Box( cQtCol , 1330 , cQtCol + 40 , 1480 ) // 1380 - 1550
			_oPrint:Box( cQtCol , 1480 , cQtCol + 40 , 1630 ) // 1550 - 1700 ***
			_oPrint:Box( cQtCol , 1630 , cQtCol + 40 , 1830 ) // 1700 - 2000
					
			_oPrint:Say( cQtCol + 5 , 0110 , "Item:"		, _oFont10n ) // 0110
			_oPrint:Say( cQtCol + 5 , 0195 , "Descrição:"	, _oFont10n ) // 0195
			_oPrint:Say( cQtCol + 5 , 0810 , "Qtd 2UM:"		, _oFont10n ) // 0710
			_oPrint:Say( cQtCol + 5 , 0960 , "Seg UM:"		, _oFont10n ) // 0910
			_oPrint:Say( cQtCol + 5 , 1090 , "Qtd. 1UM:"	, _oFont10n ) // 1060
			_oPrint:Say( cQtCol + 5 , 1240 , "Unid.:"		, _oFont10n ) // 1260
			_oPrint:Say( cQtCol + 5 , 1330 , "Prc. Vend.:"	, _oFont10n ) // 1390     
			_oPrint:Say( cQtCol + 5 , 1490 , "Pes.Bruto:"	, _oFont10n ) // 1560 ***
			_oPrint:Say( cQtCol + 5 , 1640 , "Total:"		, _oFont10n ) // 1710
					
			If cTp == '01' .Or. cTp == '03'
			   aVlrDesc	:= U_veriContrato( (_cAliasD)->CODCLI , (_cAliasD)->LOJCLI , (_cAliasD)->PROD )
			   nPrcNet		:= (_cAliasD)->PRCVEN - ( ( aVlrDesc[1] * (_cAliasD)->PRCVEN ) / 100 )
						
			   _oPrint:Box( cQtCol , 1830 , cQtCol + 40 , 2030 ) // 2000 - 2200
			   _oPrint:Box( cQtCol , 2030 , cQtCol + 40 , 2130 ) // 2200 - 2400
			   _oPrint:Box( cQtCol , 2130 , cQtCol + 40 , 2300 ) // 2200 - 2400
						
			   _oPrint:Say( cQtCol + 5 , 1835 , Transform( aVlrDesc[1]	, "@E 99,999,999.99" ) , _oFont09 ) // 2010
			   _oPrint:Say( cQtCol + 5 , 2035 , Transform( nPrcNet		, "@E 99,999,999.99" ) , _oFont09 ) // 2210 
			   _oPrint:Say( cQtCol + 5 , 2135 , (_cAliasD)->KIT                                , _oFont09 ) // 2210 
            Else 
               _oPrint:Box( cQtCol , 1830 , cQtCol + 40 , 2030 ) // 2000 - 2200
               _oPrint:Say( cQtCol + 5 , 1835 , (_cAliasD)->KIT                                , _oFont09 ) // 2210 
			EndIf
					
			cQtCol += 40
					
		 EndIf
				
	  EndDo
			
	  If cQtCol > 3450
	     _oPrint:EndPage()
		 _oPrint:StartPage()
				
		 cQtCol := 070
	 
	   	 _oPrint:FillRect( { cQtCol , 0100 , cQtCol + 40 , 0800 } , _oBrush1 ) // 0100 - 0900
	   	 _oPrint:FillRect( { cQtCol , 0800 , cQtCol + 40 , 0950 } , _oBrush1 ) // 0850 - 1000
	   	 _oPrint:FillRect( { cQtCol , 0950 , cQtCol + 40 , 1080 } , _oBrush1 ) // 1000 - 1130
	   	 _oPrint:FillRect( { cQtCol , 1080 , cQtCol + 40 , 1230 } , _oBrush1 ) // 1130 - 1380
	   	 _oPrint:FillRect( { cQtCol , 1230 , cQtCol + 40 , 1330 } , _oBrush1 ) // 1280 - 1380
	   	 _oPrint:FillRect( { cQtCol , 1330 , cQtCol + 40 , 1480 } , _oBrush1 ) // 1380 - 1150
	   	 _oPrint:FillRect( { cQtCol , 1480 , cQtCol + 40 , 1630 } , _oBrush1 ) // 1550 - 1750 ***
	   	 _oPrint:FillRect( { cQtCol , 1630 , cQtCol + 40 , 1830 } , _oBrush1 ) // 1750 - 2000
	   	    	 
		 _oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 0800 ) // 0100 - 0850
		 _oPrint:Box( cQtCol , 0800 , cQtCol + 40 , 0950 ) // 0850 - 1000
		 _oPrint:Box( cQtCol , 0950 , cQtCol + 40 , 1080 ) // 1000 - 1130
		 _oPrint:Box( cQtCol , 1080 , cQtCol + 40 , 1230 ) // 1130 - 1380
		 _oPrint:Box( cQtCol , 1230 , cQtCol + 40 , 1330 ) // 1280 - 1380
		 _oPrint:Box( cQtCol , 1330 , cQtCol + 40 , 1480 ) // 1380 - 1550
		 _oPrint:Box( cQtCol , 1480 , cQtCol + 40 , 1630 ) // 1550 - 1750 ***
		 _oPrint:Box( cQtCol , 1630 , cQtCol + 40 , 1830 ) // 1750 - 2000
				
		 _oPrint:Say( cQtCol + 5 , 0110 , "Totais do Pedido: "							  , _oFont10n )
		 _oPrint:Say( cQtCol + 5 , 0810 , nToT2UM										  , _oFont10n ) // 0860    
		 _oPrint:Say( cQtCol + 5 , 1085 , Transform( nToT1UM	, "@E 999999999"		) , _oFont10n ) // 1135
		 _oPrint:Say( cQtCol + 5 , 1482 , Transform( nToTPes	, "@E 9,999,999.999"	) , _oFont10n ) // 1552 ***
		 _oPrint:Say( cQtCol + 5 , 1630 , Transform( nToT	    , "@E 99,999,999.99"	) , _oFont10n ) // 1760
				
		 If cTp == '01' .Or. cTp == '03'
			_oPrint:FillRect( { cQtCol , 1830 , cQtCol + 40 , 2030 } , _oBrush1 ) // 2000 - 2200
			_oPrint:FillRect( { cQtCol , 2030 , cQtCol + 40 , 2130 } , _oBrush1 ) // 2200 - 2400
			_oPrint:FillRect( { cQtCol , 2130 , cQtCol + 40 , 2300 } , _oBrush1 ) // 2200 - 2400

					
			_oPrint:Box( cQtCol , 1830 , cQtCol + 40 , 2030 ) // 2000 - 2200
			_oPrint:Box( cQtCol , 2030 , cQtCol + 40 , 2130 ) // 2200 - 2400
			_oPrint:Box( cQtCol , 2130 , cQtCol + 40 , 2300 ) // 2200 - 2400
				
         EndIf
      Else
	     _oPrint:FillRect( { cQtCol , 0100 , cQtCol + 40 , 0800 } , _oBrush1 ) // 0100 - 0900
	     _oPrint:FillRect( { cQtCol , 0800 , cQtCol + 40 , 0950 } , _oBrush1 ) // 0850 - 1000
		 _oPrint:FillRect( { cQtCol , 0950 , cQtCol + 40 , 1080 } , _oBrush1 ) // 1000 - 1130
		 _oPrint:FillRect( { cQtCol , 1080 , cQtCol + 40 , 1230 } , _oBrush1 ) // 1130 - 1380
		 _oPrint:FillRect( { cQtCol , 1230 , cQtCol + 40 , 1330 } , _oBrush1 ) // 1280 - 1380
		 _oPrint:FillRect( { cQtCol , 1330 , cQtCol + 40 , 1480 } , _oBrush1 ) // 1380 - 1550
		 _oPrint:FillRect( { cQtCol , 1480 , cQtCol + 40 , 1630 } , _oBrush1 ) // 1550 - 1750 ***
		 _oPrint:FillRect( { cQtCol , 1630 , cQtCol + 40 , 1880 } , _oBrush1 ) // 1750 - 2000
				
		 _oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 0800 ) // 0100 - 0850
		 _oPrint:Box( cQtCol , 0800 , cQtCol + 40 , 0950 ) // 0850 - 1000
		 _oPrint:Box( cQtCol , 0950 , cQtCol + 40 , 1080 ) // 1000 - 1130
		 _oPrint:Box( cQtCol , 1080 , cQtCol + 40 , 1230 ) // 1130 - 1380
		 _oPrint:Box( cQtCol , 1230 , cQtCol + 40 , 1330 ) // 1280 - 1380 
		 _oPrint:Box( cQtCol , 1330 , cQtCol + 40 , 1480 ) // 1380 - 1550
		 _oPrint:Box( cQtCol , 1480 , cQtCol + 40 , 1630 ) // 1550 - 1750 ***
		 _oPrint:Box( cQtCol , 1630 , cQtCol + 40 , 1830 ) // 1750 - 2000
				
		 _oPrint:Say( cQtCol + 5 , 0110 , "Totais do Pedido: "	,_oFont10n )  // 0110
		 _oPrint:Say( cQtCol + 5 , 0810 , cValtoChar(nToT2UM)   ,_oFont10n )  // 0860
		 _oPrint:Say( cQtCol + 5 , 1085 , cValToChar(nToT1UM)	,_oFont10n )  // 1135 
		 _oPrint:Say( cQtCol + 5 , 1482 , Transform( nToTPes	, "@E 9,999,999.999" )	,_oFont10n ) // 1552 ***
		 _oPrint:Say( cQtCol + 5 , 1640 , Transform( nToT	    , "@E 99,999,999.99" )	,_oFont10n ) // 1760

         If cTp == '01' 
   	    	_oPrint:FillRect( { cQtCol , 1830 , cQtCol + 40 , 2030 } , _oBrush1 ) // 2000 - 2200
 			_oPrint:FillRect( { cQtCol , 2030 , cQtCol + 40 , 2130 } , _oBrush1 ) // 2200 - 2400
			_oPrint:FillRect( { cQtCol , 2130 , cQtCol + 40 , 2300 } , _oBrush1 ) // 2200 - 2400
					
			_oPrint:Box( cQtCol , 1830 , cQtCol + 40 , 2030 ) // 2000 - 2200
			_oPrint:Box( cQtCol , 2030 , cQtCol + 40 , 2130 ) // 2200 - 2400
			_oPrint:Box( cQtCol , 2130 , cQtCol + 40 , 2300 ) // 2200 - 2400
         Else 	
		    _oPrint:FillRect( { cQtCol , 1830 , cQtCol + 40 , 2030 } , _oBrush1 ) // 2000 - 2200	
			_oPrint:Box( cQtCol , 1830 , cQtCol + 40 , 2030 ) // 2000 - 2200	
         EndIf
             
         cQtCol += 40 
         _oPrint:FillRect( { cQtCol , 0100 , cQtCol + 45 , 1950 } , _oBrush1 )                           // 0100 - 2000
		 _oPrint:Box( cQtCol  , 0100 , cQtCol + 45 , 1950 )                                              // 0100 - 2000 
         _oPrint:Say( cQtCol + 10 , 0110 , "Totais do Pedido com Impostos: "			,_oFont10n )         // 0110
		 _oPrint:Say( cQtCol + 10 , 1640 , Transform( _nTotPVImposto	, "@E 99,999,999.99" )	,_oFont10n ) // 1760
      EndIf
			
	  cQtCol += 120
			
	  If cQtCol > 3450
		 _oPrint:EndPage()
		 _oPrint:StartPage()
				
		 cQtCol := 070
      EndIf
  	  
	  If SC5->(FIELDPOS("C5_ASSCOD")) <> 0 .And. !Empty(SC5->C5_ASSCOD)
         ZPG->(DBSetOrder( 1 ))//ZPG_FILIAL+ZPG_ASSCOD"
         ZPG->(DBSeek( xFilial()+SC5->C5_ASSCOD ))
	     _oPrint:Say( cQtCol      , 0100 , "Assistente  Responsavel: "+AllTrim(ZPG->ZPG_ASSNOM)+ " / Tel.: "+AllTrim(ZPG->ZPG_TEL1), _oFont10n )
	     _oPrint:Say( cQtCol + 150, 0100 , "E-Mail: "+AllTrim(ZPG->ZPG_EMAIL), _oFont10n )
	  EndIf

	  If _cTipo == '10'
		 //_oPrint:Say( cQtCol			, 0100 , "Autorização: "												, _oFont14n )
		 //_oPrint:Say( cQtCol + 150	, 0100 , "__________________________________________________________ "	, _oFont14n )
		 _oPrint:Say( cQtCol + 300	, 0100 , "__________________________________________________________ "	, _oFont14n )
		 _oPrint:Say( cQtCol + 500	, 0075 , "* Bonificação *"												, _oFont48n )
      ElseIf _cTipo == '24'
 		 //_oPrint:Say( cQtCol			, 0100 , "Autorização: "												, _oFont14n )
		 //_oPrint:Say( cQtCol + 150	, 0100 , "__________________________________________________________ "	, _oFont14n )
		 _oPrint:Say( cQtCol + 300	, 0100 , "__________________________________________________________ "	, _oFont14n )
		 _oPrint:Say( cQtCol + 500	, 0075 , "* Data Crítica *"												, _oFont48n )
      Else
	     //_oPrint:Say( cQtCol			, 0100 , "Autorização: "												, _oFont14n )
		 //_oPrint:Say( cQtCol + 150	, 0100 , "__________________________________________________________ "	, _oFont14n )
		 _oPrint:Say( cQtCol + 300	, 0100 , "__________________________________________________________ "	, _oFont14n )
	  EndIf
   EndIf

   (_cAliasD)->( DBCloseArea() )
	    
   _oPrint:EndPage()
	    
   _oPrint:Preview()

End Sequence 

Return

/*
===============================================================================================================================
Programa----------: ROMS064I
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/11/2020
Descrição---------: Rotina que retorna o valor total do pedido de vendas com os impostos.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function ROMS064I()
Local _nRet := 0
Local _nTotCampos, _aNoFields, _nI 

Begin Sequence

   MV_PAR04 := 2
   INCLUI := .F.
   ALTERA := .F.

   aCols := {}
   aHeader := {}
   
   _nTotCampos := SC5->(FCount())
   For _nI := 1 To _nTotCampos
       &("M->" + SC5->(FieldName(_nI))) := &("SC5->" + SC5->(FieldName(_nI)))
   Next                                                                     

   //==================================================================
   // Campos que não serão exibidos na msgetdados.
   //==================================================================           
   _aNoFields := {"C6_SLDALIB",;
                  "C6_INFAD",;
                  "C6_I_QESP",; 
                  "C6_GRADE",;  
                  "C6_TPOP",;   
                  "C6_TPCONTR",;
                  "C6_REGWMS",; 
                  "C6_TPDEDUZ",;
                  "C6_MOTDED",; 
                  "C6_I_DIFPE",;
                  "C6_VDMOST",; 
                  "C6_RATEIO",; 
                  "C6_INTROT",;
                  "C6_TPPROD"} 

   //============================================================================
   //Indica as rotinas abaixo que se trata de alteracao                         
   //=============================================================================
   //ALTERA := .T.


   //============================================================================
   //Montagem do aheader                                                        
   //============================================================================= 
   FillGetDados(1     ,"SC6"   ,1       ,          ,             ,{||.T.}    ,_aNoFields ,,,,,.T.)
   
   SC6->(DBSetOrder(1))                                     
   SC6->(MsSeek(SC5->(C5_FILIAL+C5_NUM)))

   _aItensPV := {}

   While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == SC5->(C5_FILIAL+C5_NUM)
      aAdd(aCols,Array(Len(aHeader)+1))  
       
      For _nI := 1 To Len(aHeader)
	       _cCampo := AllTrim(aHeader[_nI,2])
	       
	       If (aHeader[_nI,10] # "V" .And. ! (_cCampo $ "C6_QTDLIB/C6_ALI_WT/C6_REC_WT")) 
	          aCols[Len(aCols)][_nI] := &("SC6->"+_cCampo)
	       EndIf
      Next    
    
      SC6->(DBSkip())
   EndDo

   _nRet := Ma410Impos( 6, .T., {}) // Total do Pedido de Vendas com impostos.

End Sequence

Return _nRet


/*
===============================================================================================================================
Programa----------: ROMS064L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 07/12/2020
Descrição---------: Rotina que retorna o percentual de leite magro.
Parametros--------: _cCodFil = Filial do pedido de vendas
                    _cNrPed  = Numero do pedido de vendas
Retorno-----------: _nRet = Percentual de leite magro.
===============================================================================================================================
*/  
User Function ROMS064L(_cCodFil,_cNrPed)
Local _nRet := 0
Local _nRegSC6 := SC6->(Recno())
Local _nQtdeM, _nQtdeI // , _nQtde

Begin Sequence
   _nQtdeM := 0
   _nQtdeI := 0

   SB1->(DBSetOrder(1))

   SC6->(DBSetOrder(1))
   SC6->(MsSeek(_cCodFil+_cNrPed))
    
   While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == _cCodFil+_cNrPed
      
	  If SB1->(MsSeek(xFilial("SB1")+SC6->C6_PRODUTO))
         If SB1->B1_I_TIPLT = "M"
	        _nQtdeM += SC6->C6_QTDVEN
         ElseIf SB1->B1_I_TIPLT = "I"
            _nQtdeI += SC6->C6_QTDVEN
         EndIf
	  EndIf 	 

      SC6->(DBSkip())
   EndDo 

   If _nQtdeM <> 0 
      _nRet := ((_nQtdeM / (_nQtdeM + _nQtdeI)) * 100)
   EndIf 
	
End Sequence

SC6->(DBGoTo(_nRegSC6))

Return _nRet
