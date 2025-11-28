/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Igor Fricks   | 02/02/2024 | Chamado 46192. Ajuste para impressão do campo Shelf Life P.
Alex Wallauer | 08/02/2024 | Chamado 44782. Jerry. Ajustes para a nova opcao de tipo de entrega: O = Agendado pelo Op.Log.
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
Programa----------: ROMS035
Autor-------------: Erich Buttner
Data da Criacao---: 03/07/2013
Descrição---------: Relatório da emissão do espelho de pedidos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS035( _cPed , _cCodCli , _cLojCli , _cFilPed , _cCodVen )

Local _oDlg			:= Nil
Local _oButton1		:= Nil
Local _oButton2		:= Nil
Local _oGroup1		:= Nil

Private _aPed			:= {}
Private _cPerg		:= 	"ROMS035"
Private _aCampos		:= {}
Private _oRadMnu1		:= Nil
Private _nRadMnu1		:= 1  

Default _cPed			:= ''
Default _cCodCli		:= ''
Default _cLojCli		:= ''
Default _cFilPed		:= ''

If !Empty(_cPed) .And. !Empty(_cCodCli) .And. !Empty(_cLojCli) .And. !Empty(_cFilPed) .And. !Empty(_cCodVen)
	aAdd( _aPed , { _cFilPed , _cPed , _cCodCli , _cLojCli , _cCodVen } )
EndIf

DEFINE MSDIALOG _oDlg TITLE "IMPRIMIR PEDIDOS?" FROM 000,000 TO 200,500 COLORS 0,16777215 PIXEL

	@006,007 GROUP	_oGroup1 TO 059,238 PROMPT "Selecione um dos modos de impressão indicados abaixo:"	OF _oDlg COLOR 0,16777215 PIXEL
	@026,020 RADIO	_oRadMnu1 VAR _nRadMnu1 ITEMS "Pedido Posicionado","Vários Pedidos","Varios Pedidos(Somente não impressos)"	SIZE 200,028	OF _oDlg COLOR 0,16777215 PIXEL
	@070,045 BUTTON _oButton1 PROMPT "Confirmar"										SIZE 044,015	OF _oDlg ACTION ( FWMsgRun( ,{|oproc| U_ROMS035RUN(oproc) } , "Processando..." , 'Aguarde!' ) , _oDlg:End() ) PIXEL
	@070,158 BUTTON _oButton2 PROMPT "Cancelar"											SIZE 047,015	OF _oDlg ACTION _oDlg:End() PIXEL

ACTIVATE MSDIALOG _oDlg CENTERED

Return

/*
===============================================================================================================================
Programa----------: ROMS035RUN
Autor-------------: Erich Buttner
Data da Criacao---: 03/07/2013
Descrição---------: Relatório da emissão do espelho de pedidos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/                        

User Function ROMS035RUN(oproc)

Local _aCfgRun	:= {'','','','',''}
Local _oPrint		:= NIL 
Local _cArq		:= ''
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
Local _aStru		:= {}
Local _aCpoBro	:= {}
Local _oDlg		:= NIL
Local _aSize		:= {}
Local _nOpca		:= 0
Local _cTipo		:= ""
Local _cCoord		:= ""
Local _cSuperv      := ""
Local _dData		:= SToD('')
Local _cHora		:= ''
Local cDesCondCli   := ''
Local cDesCond      := ''
Local _nI			:= 0
Local _cDescTipo    := ""
Private _lInvAll	:= .F.
Private _cMark	:= GetMark()
Private _oMark	:= NIL

If (_nRadMnu1 == 2 .Or. _nRadMnu1 == 3) .Or. Empty( _aPed ) 
	
	_aPed := {}
	
	// Armazena no array aEstru a estrutura dos campos da tabela
	_aStru := {	{ "OK"     	, 'C' , 02 , 0 },;
				{ "IMPRIME"	, 'C' , 06 , 0 },;
				{ "FILIAL"  , 'C' , 02 , 0 },;    
				{ "NUMPED"	, 'C' , 10 , 0 },;
				{ "TIPO"  	, 'C' , 02 , 0 },;
				{ "CODCLI"  , 'C' , 06 , 0 },;
				{ "LOJA"  	, 'C' , 04 , 0 },;
				{ "NMCLI"  	, 'C' , 30 , 0 },;
				{ "VEND1"  	, 'C' , 06 , 0 },;
				{ "NMVEND1" , 'C' , 30 , 0 } }
	
	If Select("TTRB") > 0
	
		DBSelectArea("TTRB")
		DBCloseArea()
		
	EndIfç
	
	_otemp := FWTemporaryTable():New( "TTRB", _aStru )

	DBSelectArea("TMP")
	TMP->( DBGoTop() )
	While TMP->( !Eof() )
	    
		If _nRadMnu1 == 2 .Or. (_nRadMnu1 == 3 .And. TMP->IMPRIME != '1-SIM')
		
			DBSelectArea("TTRB")
			RecLock( "TTRB" , .T. )
		
			TTRB->IMPRIME	:= TMP->IMPRIME	   
			TTRB->FILIAL    := TMP->FILIAL	
			TTRB->NUMPED    := TMP->NUMPED		
			TTRB->TIPO    	:= TMP->TIPO		
			TTRB->CODCLI 	:= TMP->CODCLI		
			TTRB->LOJA	  	:= TMP->LOJA		
			TTRB->NMCLI  	:= TMP->NMCLI
			TTRB->VEND1	    := TMP->VEND1
			TTRB->NMVEND1   := TMP->NMVEND1
			
			TTRB->( MSUnLock() )
			
		EndIf
		
	TMP->( DBSkip() )
	EndDo
	
	_aCpoBro := {	{ "OK"			,, " "           	, "@!" },;
					{ "IMPRIME"		,, "Imprime"		, "@!" },;			
					{ "FILIAL"		,, "Filial"         , "@!" },;			
					{ "NUMPED"		,, "Pedido"         , "@!" },;			
					{ "TIPO"		,, "Tipo"           , "@!" },;			
					{ "CODCLI"		,, "Cliente"   		, "@!" },;			
		   			{ "LOJA"		,, "Loja"       	, "@!" },;
		   			{ "NMCLI"		,, "Nome Cliente"   , "@!" },;
		   			{ "VEND1"		,, "Vendedor"		, "@!" },;
		   			{ "NMVEND1"		,, "Nome Vend"		, "@!" } }
	
	_aSize := MSADVSIZE()
	
	DEFINE MSDIALOG _oDlg TITLE "Selecione os pedidos para imprimir:" From 0,0 To _aSize[6],_aSize[5] PIXEL 
	    
		DBSelectArea("TTRB")
		DBGoTop()
		
		_oMark							:= MsSelect():New( "TTRB" , "OK" , "" , _aCpoBro , @_lInvAll , @_cMark , { 035 , 000 , _aSize[04] , _aSize[03] } )
		_oMark:obrowse:lCanAllmark	:= .T.
		_oDlg:lMaximized				:= .T.
		
	ACTIVATE MSDIALOG _oDlg CENTERED ON INIT EnchoiceBar( _oDlg , {|| _nOpca := 1 , MsgRun( 'Imprimindo os pedidos selecionados...' , 'Aguarde!' ) , _oDlg:End() } , {|| _nOpca := 2 , _oDlg:End() } )
	
	If _nopca == 2
	
		Return
		
	EndIf
	
	
	TTRB->( DBGoTop() )
	While TTRB->( !Eof() ) 
	
		If Marked("OK")
		
				aAdd( _aPed , { TTRB->FILIAL , TTRB->NUMPED , TTRB->CODCLI , TTRB->LOJA , TTRB->VEND1 } ) 
		
		EndIf
		
	TTRB->( DBSkip() )
	EndDo
	
	TTRB->( DBCloseArea() )
	
	IIf( File( _cArq + GetDBExtension() ) , FErase( _cArq  + GetDBExtension() ) , Nil )
	
EndIf

If !Empty( _aPed )

	//====================================================================================================
	// Inicializa o objeto de impressão
	//====================================================================================================
	_oPrint := TMSPrinter():New( "Espelho de Pedido" )
	_oPrint:SetPortrait()
	_oPrint:StartPage()
	
	For _nI := 1 To Len( _aPed )

		oproc:cCaption := ("Imprimindo pedido " + StrZero(_nI,3) + " de " + StrZero(Len(_aped),3)) + "..."
		ProcessMessages()
	
		_aCfgRun[01] := _aPed[_nI][1]
		_aCfgRun[02] := _aPed[_nI][2]
		_aCfgRun[03] := _aPed[_nI][3]
		_aCfgRun[04] := _aPed[_nI][4]
		_aCfgRun[05] := _aPed[_nI][5]
		
		If AllTrim(funname()) == "AOMS061"
			
			TMP->( DBSetOrder(3) )
			TMP->( DBGoTop() )
			TMP->( DBSeek( _aCfgRun[01] + _aCfgRun[02] ) )
				
			TMP->( RecLock( "TMP", .F. ) )
		
			TMP->IMPRIME := '1-SIM'
		
			TMP->( MSUnLock() )
				
		EndIf
		
		
			 
		_cQuery := " SELECT "
		_cQuery += "     ZM.ZZM_DESCRI DESCR,"
		_cQuery += "     ZM2.ZZM_DESCRI DESCR2,"		
		_cQuery += "     ZW.ZW_TIPO TIPO,"
		_cQuery += "     ZW.ZW_VEND1 VEND,"
		_cQuery += "     ZW.ZW_IDPED NUMPED,"
		_cQuery += "     ZW.ZW_PEDCLI PEDCLI,"
		_cQuery += "     ZW.ZW_FECENT DTENTR,"
		_cQuery += "     ZW.ZW_FILIAL FILIAL,"
		_cQuery += "     ZW.ZW_FILPRO FILPRO,"		
		_cQuery += "     ZW.ZW_EMISSAO EMISS,"
		_cQuery += "     ZW.ZW_CLIENTE CODCLI,"
		_cQuery += "     ZW.ZW_LOJACLI LOJCLI,"
		_cQuery += "     ZW.ZW_HOREN HRENT,"
		_cQuery += "     ZW.ZW_SENHA SENHA,"
		_cQuery += "     ZW.ZW_EVENTO EVENTO,"
		_cQuery += "     ZW.ZW_TPFRETE TPFRET,"
		_cQuery += "     ZW.ZW_TIPCAR TIPCAR,"
		_cQuery += "     ZW.ZW_CHAPA CHAPA,"
		_cQuery += "     ZW.ZW_HORDES HRDES,"
		_cQuery += "     ZW.ZW_CUSDES CUSDES,"
		_cQuery += "     ZW.ZW_OBSCOM OBSCOM,"
		_cQuery += "     ZW.ZW_MENNOTA MENNF,"
		_cQuery += "     ZW.ZW_ITEM ITEM,"
       _cQuery += "      ZW.ZW_KIT  KIT, "

		_cQuery += "     ZW.ZW_PRODUTO PROD,"
		_cQuery += "     ZW.ZW_QTDVEN QTDVEN,"
		_cQuery += "     ZW.ZW_UM UM1,"
		_cQuery += "     ZW.ZW_PRCVEN PRCVEN,"
		_cQuery += "     (ZW.ZW_QTDVEN * ZW.ZW_PRCVEN) TOTAL,"
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
		_cQuery += "     ZW.ZW_CONDPAG COND,"
		_cQuery += "     A1.A1_COND CONDPA,"
		_cQuery += "     ZW.ZW_HORAINC HRINC,"
		_cQuery += "     ZW.ZW_DATAAPR DATAAPR,"
		_cQuery += "     ZW.ZW_HORAAPR HRAPR,"
		_cQuery += "     ZW.ZW_I_DLIBG ,"
        _cQuery += "     ZW.ZW_I_HLIBG ,"
		_cQuery += "     ZW.ZW_DTIMPRI DTIMPRI,"
		_cQuery += "     ZW.ZW_HRIMPRI HRIMPRI," 
		_cQuery += "     ZW.ZW_I_LMAGR LMAGR,"
		_cQuery += "	 ZW.ZW_EVENTO EVENTO,"
		_cQuery += "	 ZW.ZW_I_AGEND ," //_cQuery += "   	DECODE ( ZW_I_AGEND,'A','AGENDADA','I','IMEDIATO','M','AGENDADA C/MULTA','P','AGUARD.AGENDA') DESCTIPO,"
		_cQuery += "     ZW.R_E_C_N_O_ REGSZW ,"
		_cQuery += "     ZW.ZW_TPVENDA TPVENDA "
		_cQuery += " FROM "+ RetSqlName('SZW') +" ZW, "+ RetSqlName('ZZM') +" ZM, "+ RetSqlName('SA1') +" A1, " + RetSqlName('ZZM') +" ZM2 "
		_cQuery += " WHERE "
		_cQuery += "     ZW.ZW_FILIAL  = '"+ _aCfgRun[01] +"' "
		_cQuery += " AND ZW.ZW_IDPED   = '"+ _aCfgRun[02] +"' "
		_cQuery += " AND ZW.ZW_CLIENTE = '"+ _aCfgRun[03] +"' "
		_cQuery += " AND ZW.ZW_LOJACLI = '"+ _aCfgRun[04] +"' "
		_cQuery += " AND A1.A1_COD     = ZW.ZW_CLIENTE "
		_cQuery += " AND A1.A1_LOJA    = ZW.ZW_LOJACLI "
		_cQuery += " AND ZM.ZZM_CODIGO = ZW.ZW_FILIAL  "
		_cQuery += " AND ZM2.ZZM_CODIGO(+) = ZW.ZW_FILPRO "		
		_cQuery += " AND A1.D_E_L_E_T_ = ' ' "
		_cQuery += " AND ZM.D_E_L_E_T_ = ' ' "          
		_cQuery += " AND ZW.D_E_L_E_T_ = ' ' "
		_cQuery += " AND ZM2.D_E_L_E_T_(+) = ' ' "
		
		If Select(_cAliasD) > 0
			(_cAliasD)->( DBCloseArea() )
		EndIf
	
		//DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAliasD , .T. , .F. )  // Alterar 
		MPSysOpenQuery( _cQuery , _cAliasD)
		
		DBSelectArea(_cAliasD)
		(_cAliasD)->( DBGoTop() )
		
		COUNT TO _nCount
		
		(_cAliasD)->( DBGoTop() )
		
		ProcRegua(_nCount)
		
		If _nCount > 0
		
			DBSelectArea("SA3")
			SA3->( DBSetOrder(1) )
			If SA3->( DBSeek( xFilial("SA3") + _aCfgRun[05] ) )
				_cCoord  := SA3->A3_SUPER
				_cSuperv := SA3->A3_I_SUPE 
			EndIf
			
			DBSelectArea("SZW")
			SZW->( DBSetOrder(1) )
			If SZW->( DBSeek( _aCfgRun[01] + _aCfgRun[02] ) )
			
				_cChvAux := SZW->( ZW_FILIAL + ZW_IDPED )
				
				_dData := Date()
				_cHora := SubStr( Time() , 1 , 5 )
				
				While !Eof() .And. SZW->( ZW_FILIAL + ZW_IDPED ) == _cChvAux
				
					RecLock( "SZW" , .F. )
					
						SZW->ZW_DTIMPRI := _dData
						SZW->ZW_HRIMPRI := _cHora
						SZW->ZW_IMPRIME := '1'
					
					SZW->( MSUnLock() )
					
				SZW->( DBSkip() )
				EndDo
			
			EndIf
			
			_oPrint:StartPage()
			_nLarg:=179
			_nAltu:=86
			_oPrint:SayBitmap( 70 , 0100 , "\SYSTEM\LOGOBOLETO.BMP" , _nLarg , _nAltu )
			
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
			//_oPrint:Say( 180 , 0460 , If( _cTipo == '01' , "Pedido de Venda" , If( _cTipo == '10' , "Bonificação" , "" ) )	, _oFont16	)
			_oPrint:Say( 180 , 0460 , _cDescTipo , _oFont16	)
			_oPrint:Say( 240 , 1150 , "Espelho do Pedido Portal"																	, _oFont16n	)
			_oPrint:Say( 300 , 0100 , "Informações Gerais: "																, _oFont14n	)
			
			cNmVend		:= GetAdvFVal( "SA3" , "A3_NOME"	, xFilial("SA3") + (_cAliasD)->VEND		, 1 , "" )
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
			
			_oPrint:Box( 480 , 0100 , 520 , 0400 )
			_oPrint:Box( 520 , 0100 , 560 , 0400 )

			_oPrint:Box( 480 , 0400 , 520 , 1200 )
			_oPrint:Box( 520 , 0400 , 560 , 1200 )
			
			_oPrint:Box( 480 , 1200 , 520 , 1800 )
			_oPrint:Box( 520 , 1200 , 560 , 1800 )
			
			_oPrint:Box( 480 , 1800 , 520 , 2300 )
			_oPrint:Box( 520 , 1800 , 560 , 2300 )
			
			_oPrint:Say( 405 , 0110 , "Codigo / Representante"						, _oFont10n ,,, 2	)
			_oPrint:Say( 445 , 0110 , (_cAliasD)->VEND +" / "+ cNmVend				, _oFont09			)
			
			_oPrint:Say( 405 , 0960 , "Codigo / Supervisor"					    	, _oFont10n ,,, 2	)  
		    _oPrint:Say( 445 , 0960 , _cSuperv + " / " + cNmSuper					, _oFont09		)  

 			_oPrint:Say( 405 , 1630 , "Codigo / Coordenador"						, _oFont10n ,,, 2 )  
		    _oPrint:Say( 445 , 1630 , _cCoord +" / "+ cNmCoord						, _oFont09		  )  
			
			_oPrint:Say( 485 , 0110 , "Numero Ped."									, _oFont10n			)
			_oPrint:Say( 525 , 0110 , (_cAliasD)->NUMPED							, _oFont09			)
			
			_oPrint:Say( 485 , 0410 , "FiL Faturamento / Fil Carregamento"			, _oFont10n			)
			
			If !Empty(AllTrim((_cAliasD)->DESCR2))
			    _oPrint:Say( 525 , 0410 , (_cAliasD)->FILIAL +" - "+ AllTrim((_cAliasD)->DESCR)	+ "   /   " +(_cAliasD)->FILPRO +" - "+ AllTrim((_cAliasD)->DESCR2),_oFont09			)
			Else 
			    _oPrint:Say( 525 , 0410 , (_cAliasD)->FILIAL +" - "+ AllTrim((_cAliasD)->DESCR),_oFont09			)
			EndIf			
			
			_oPrint:Say( 485 , 1210 , "Condição de Pagamento Pedido:"				, _oFont10n			)
			_oPrint:Say( 525 , 1210 , cDesCond										, _oFont09			)
			
	    	_oPrint:Say( 485 , 1810 , "Condição de Pagamento Padrão:"				, _oFont10n			)
			_oPrint:Say( 525 , 1810 , cDesCondCli									, _oFont09			)
					
			_oPrint:FillRect( { 560 , 0100 , 600 , 0800 } , _oBrush1 ) 
			_oPrint:FillRect( { 560 , 0800 , 600 , 2300 } , _oBrush1 )
			
            nCol2:=600
            nCol3:=nCol2+550
            nCol4:=nCol3+550
			_oPrint:Box( 560 , 0100  , 600 , nCol2 )
			_oPrint:Box( 600 , 0100  , 640 , nCol2 )

			_oPrint:Box( 560 , nCol2 , 600 , nCol3 )
			_oPrint:Box( 600 , nCol2 , 640 , nCol3 )

			_oPrint:Box( 560 , nCol3 , 600 , nCol4 )
			_oPrint:Box( 600 , nCol3 , 640 , nCol4 )
			
			_oPrint:Box( 560 , nCol4 , 600 , 2300  )
			_oPrint:Box( 600 , nCol4 , 640 , 2300  )
			
			_oPrint:Say( 565 , 0110     , "Data / Hora de Inclusão do Vendedor"										, _oFont10n	)
			_oPrint:Say( 605 , 0110     , DToC( SToD( (_cAliasD)->EMISS ) )		+" - "+ (_cAliasD)->HRINC +" hs"	, _oFont10	)
			
			_oPrint:Say( 565 , nCol2+10 , "Data / Hora de Aprovação do Coordenador"									, _oFont10n	)
			_oPrint:Say( 605 , nCol2+10 , DToC( SToD( (_cAliasD)->DATAAPR ) )	+" - "+ (_cAliasD)->HRAPR +" hs"	, _oFont10	)
			
			_oPrint:Say( 565 , nCol3+10 , "Data / Hora de Aprovação do Gerente"									    , _oFont10n	)
			_oPrint:Say( 605 , nCol3+10 , DToC( SToD( (_cAliasD)->ZW_I_DLIBG ) )+" - "+ LEFT((_cAliasD)->ZW_I_HLIBG,5)+" hs" , _oFont10	)
			
			_oPrint:Say( 565 , nCol4+10 , "Data / Hora de Impressão do Pedido "										, _oFont10n	)
			_oPrint:Say( 605 , nCol4+10 , DToC( _dData ) +" - "+ _cHora +" hs"										, _oFont10	)
		 	
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
			
			_oPrint:Box( cQtCol	, 0100 , cQtCol  + 40 , 0800 )
			_oPrint:Box( cQt1Col , 0800 , cQt1Col + 40 , 1600 )
			_oPrint:Box( cQtCol	, 0800 , cQtCol  + 40 , 1600 )
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

			If  Mod( Len( _cENDEREC ) , 35 ) > 0 
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
			
			//DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cTit) , _cAlias , .T. , .F. ) // Alterar 
			MPSysOpenQuery( cTit , _cAlias)
	 	 	
	 	 	DBSelectArea( _cAlias )
			(_cAlias)->( DBGoTop() )
			
	    	cQtCol := cQtCol + 060

			_nCol2:=650
			_nCol3:=_nCol2+400
	    	
//*********************************************************************************************************************************************			
	    	_oPrint:FillRect( { cQtCol , 0100 , cQtCol + 40 , _nCol2 } , _oBrush1 )
	    	
			_oPrint:Box( cQtCol , 0100 , cQtCol + 40 , _nCol2 )
			
			_oPrint:Say( cQtCol + 5 , 0110 , "Titulos Vencidos:"	, _oFont10n	)
			
			cQt1Col	:= cQtCol
			cQtCol	+= 40
			
			_oPrint:FillRect( {cQt1Col,_nCol2,cQt1Col+40, 2300}, _oBrush1 )
			
			_oPrint:Box( cQt1Col , _nCol2 , cQt1Col + 40 , _nCol3 )
			_oPrint:Box( cQt1Col , _nCol3 , cQt1Col + 40 , 1600   )
			_oPrint:Box( cQt1Col , 1600   , cQt1Col + 40 , 2300   )
			
			_oPrint:Box( cQtCol  , 0100   , cQtCol  + 40 , _nCol2 )
			_oPrint:Box( cQtCol  , _nCol2 , cQtCol  + 40 , _nCol3 )
			_oPrint:Box( cQtCol  , _nCol3 , cQtCol  + 40 , 1600   )
			_oPrint:Box( cQtCol  , 1600   , cQtCol  + 40 , 2300   ) 
			
			_oPrint:Say( cQtCol  + 5 , 0110 , "R$ "+ Transform( (_cAlias)->SLD_VENCTO , "@E 99,999,999.99" )	, _oFont09	)

//*********************************************************************************************************************************************			
			_oPrint:Say( cQt1Col + 5 , _nCol2+10 , "Títulos à Vencer:"												, _oFont10n	)
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
	        			Exit
	        		EndIf
	        		SA1->(DBSkip())
	        	EndDo
	        EndIf

			_oPrint:Say( cQt1Col + 5 , _nCol3+10 , "Limite de Credito (Risco):"											, _oFont10n	)
			_oPrint:Say( cQtCol  + 5 , _nCol3+10 , "R$ "+ Transform( nLimCr , "@E 999,999,999.99" )+" ( "+cRisCli+" )"	, _oFont09	) 

//*********************************************************************************************************************************************			

			//Posiciona SZW e calcula tabela de preço
			SZW->(DBGoTo((_cAliasD)->REGSZW))

			If SZW->ZW_FILPRO != '0 ' .And. !Empty(SZW->ZW_FILPRO) .And. SZW->ZW_FILPRO != SZW->ZW_FILIAL 
		
				_cfilpro := SZW->ZW_FILPRO
			
			Else
		
				_cfilpro := SZW->ZW_FILIAL
			
			EndIf

			_cvend2 := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_SUPER")  
			_cvend3 := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_GEREN")                                                                                      
					
            _ctab := SZW->ZW_TABELA 

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
			
			_oPrint:Say( cQtCol  + 05 , 0510 , "Data: "+  dDtEntr + " - Tp Entrega: " + U_TipoEntrega((_cAliasD)->ZW_I_AGEND), _oFont09)
			_oPrint:Say( cQtCol  + 45 , 0510 , "Hora: "+  IIf( Empty( (_cAliasD)->HRENT ) , "N/A" , (_cAliasD)->HRENT )	, _oFont09	)
			_oPrint:Say( cQtCol  + 85 , 0510 , "Senha: "+ IIf( Empty( (_cAliasD)->SENHA ) , "N/A" , (_cAliasD)->SENHA ) , _oFont09	)
			
	    	_oPrint:Say( cQt1Col + 05 , 1060 , "Tipo Frete: "																							, _oFont10n	)
			_oPrint:Say( cQtCol  + 05 , 1060 , IIf( Empty( (_cAliasD)->TPFRET ) , "N/A" , IIf( AllTrim( (_cAliasD)->TPFRET ) == "C" , "CIF" , "FOB" ) ) , _oFont09	)
//--------------------------------------------
            _oPrint:Say( cQtCol  + 45 , 1060 , "Tipo de Carga: " , _oFont10n	)
			_oPrint:Say( cQtCol  + 85 , 1060 , IIf( Empty( (_cAliasD)->TPVENDA ) , "N/A" , IIf( AllTrim( (_cAliasD)->TPVENDA ) == "F" , "FECHADA" , "FRACIONADA" ) ) , _oFont09	)
//--------------------------------------------
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
			
			_oPrint:Say( cQtCol + 6 , 0110 , AllTrim( Transform( (_cAliasD)->LMAGR , "@E 999,999,999.99" ) ) +" %"	, _oFont09	)
			
			cQtCol += 100
			
			_oPrint:Say( cQtCol , 0100,"Produtos "	,_oFont14n )
			
			cQtCol	+= 060
			cQt1Col := cQtCol
			
			_aCfgRun[01] := (_cAliasD)->NUMPED
			
	    	_oPrint:FillRect( { cQtCol , 0100 , cQtCol + 40 , 0190 } , _oBrush1 )
	    	_oPrint:FillRect( { cQtCol , 0190 , cQtCol + 40 , 0800 } , _oBrush1 ) // 190 - 850
	    	_oPrint:FillRect( { cQtCol , 0800 , cQtCol + 40 , 0950 } , _oBrush1 ) // 850 - 1000
	    	_oPrint:FillRect( { cQtCol , 0950 , cQtCol + 40 , 1080 } , _oBrush1 ) // 1000 - 1130
	    	_oPrint:FillRect( { cQtCol , 1080 , cQtCol + 40 , 1230 } , _oBrush1 ) // 1130 - 1280
	    	_oPrint:FillRect( { cQtCol , 1230 , cQtCol + 40 , 1330 } , _oBrush1 ) // 1280 - 1380
	    	_oPrint:FillRect( { cQtCol , 1330 , cQtCol + 40 , 1500 } , _oBrush1 ) // 1380 - 1550
	    	_oPrint:FillRect( { cQtCol , 1500 , cQtCol + 40 , 1650 } , _oBrush1 ) // 1550 - 1750
	    	_oPrint:FillRect( { cQtCol , 1650 , cQtCol + 40 , 1800 } , _oBrush1 ) // 1750 - 2000   <<<<
	    	
			_oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 0190 )
			_oPrint:Box( cQtCol , 0190 , cQtCol + 40 , 0800 )  // 190 - 850
			_oPrint:Box( cQtCol , 0800 , cQtCol + 40 , 0950 )  // 850 - 1000
			_oPrint:Box( cQtCol , 0950 , cQtCol + 40 , 1080 )  // 1000 - 1130
			_oPrint:Box( cQtCol , 1080 , cQtCol + 40 , 1230 )  // 1130 - 1280
			_oPrint:Box( cQtCol , 1230 , cQtCol + 40 , 1330 )  // 1280 - 1380
			_oPrint:Box( cQtCol , 1330 , cQtCol + 40 , 1500 )  // 1380 - 1550
			_oPrint:Box( cQtCol , 1500 , cQtCol + 40 , 1650 )  // 1550 - 1750
			_oPrint:Box( cQtCol , 1650 , cQtCol + 40 , 1800 )  // 1750 - 2000   <<<<
			
			_oPrint:Say( cQtCol + 5 , 0110 , "Item:"		, _oFont10n ) 
			_oPrint:Say( cQtCol + 5 , 0195 , "Descrição:"	, _oFont10n ) // 195
			_oPrint:Say( cQtCol + 5 , 0810 , "Qtd 2UM:"		, _oFont10n ) // 860
			_oPrint:Say( cQtCol + 5 , 0960 , "Seg UM:"		, _oFont10n ) // 1010
			_oPrint:Say( cQtCol + 5 , 1090 , "Qtd. 1UM:"	, _oFont10n ) // 1140
			_oPrint:Say( cQtCol + 5 , 1240 , "Unid.:"		, _oFont10n ) // 1290 
			_oPrint:Say( cQtCol + 5 , 1340 , "Prc. Vend.:"	, _oFont10n ) // 1390
			_oPrint:Say( cQtCol + 5 , 1510 , "Pes.Bruto:"	, _oFont10n ) // 1560
			_oPrint:Say( cQtCol + 5 , 1660 , "Total:"		, _oFont10n ) // 1755   <<<<

			If (_cAliasD)->TIPO != '10'  
			
	    		_oPrint:FillRect( { cQtCol , 1800 , cQtCol + 40 , 1950 } , _oBrush1 ) // 2000 - 2150
	    		_oPrint:FillRect( { cQtCol , 1950 , cQtCol + 40 , 2150 } , _oBrush1 ) // 2200 - 2350

                _oPrint:FillRect( { cQtCol , 2150 , cQtCol + 40 , 2350 } , _oBrush1 ) // 2200 - 2350

	    		
				_oPrint:Box( cQtCol , 1800 , cQtCol + 40 , 1950 )  // 2000
				_oPrint:Box( cQtCol , 1950 , cQtCol + 40 , 2150 )  // 2200

                _oPrint:Box( cQtCol , 2150 , cQtCol + 40 , 2350 )  // 2200

				_oPrint:Say( cQtCol + 5 , 1810 , "% Contrato:"	, _oFont10n ) // 2010 
				_oPrint:Say( cQtCol + 5 , 1960 , "Prc Net:"		, _oFont10n ) // 2210

                _oPrint:Say( cQtCol + 5 , 2160 , "Kit Portal:"	, _oFont10n ) // 2210
			Else
			   _oPrint:FillRect( { cQtCol , 1800 , cQtCol + 40 , 2000 } , _oBrush1 ) // 2000 - 2150
			   _oPrint:Box( cQtCol , 1800 , cQtCol + 40 , 2000 )  // 2000
			   _oPrint:Say( cQtCol + 5 , 1810 , "Kit Portal:"	, _oFont10n ) // 2210
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
			
			While (_cAliasD)->( !Eof() ) .And. _aCfgRun[01] == (_cAliasD)->NUMPED
			    
				nFatConv	:= GetAdvFVal( "SB1" , "B1_CONV"	, xFilial("SB1") + (_cAliasD)->PROD , 1 , "" )
				cTpConv		:= GetAdvFVal( "SB1" , "B1_TIPCONV"	, xFilial("SB1") + (_cAliasD)->PROD , 1 , "" )
				nNewFat		:= GetAdvFVal( "SB1" , "B1_I_FATCO"	, xFilial("SB1") + (_cAliasD)->PROD , 1 , "" )
				
				If cTpConv == "M"
					nQtd2UM:= If (nFatConv == 0, nNewFat*(_cAliasD)->QTDVEN,nFatConv*(_cAliasD)->QTDVEN)
				Else
					nQtd2UM:= If (nFatConv == 0, (_cAliasD)->QTDVEN/nNewFat,(_cAliasD)->QTDVEN/nFatConv)
				EndIf
				
				nPesBru := GetAdvFVal("SB1","B1_PESBRU",xFilial("SB1")+(_cAliasD)->PROD,1,"")*(_cAliasD)->QTDVEN
				
				_oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 0190 )
				_oPrint:Box( cQtCol , 0190 , cQtCol + 40 , 0800 ) // 190 - 850
				_oPrint:Box( cQtCol , 0800 , cQtCol + 40 , 0950 ) // 850 - 1000
				_oPrint:Box( cQtCol , 0950 , cQtCol + 40 , 1080 ) // 1000 - 1130 
				_oPrint:Box( cQtCol , 1080 , cQtCol + 40 , 1230 ) // 1130 - 1280
				_oPrint:Box( cQtCol , 1230 , cQtCol + 40 , 1330 ) // 1280 - 1380
				_oPrint:Box( cQtCol , 1330 , cQtCol + 40 , 1500 ) // 1380 - 1550
				_oPrint:Box( cQtCol , 1500 , cQtCol + 40 , 1650 ) // 1550 - 1750
				_oPrint:Box( cQtCol , 1650 , cQtCol + 40 , 1800 ) // 1750 - 2000    <<<<
				
				_oPrint:Say( cQtCol + 5 , 0110 , (_cAliasD)->ITEM																								, _oFont09 )
				_oPrint:Say( cQtCol + 5 , 0195 , AllTrim( SubStr( GetAdvFVal( "SB1" , "B1_I_DESCD" , xFilial("SB1") + (_cAliasD)->PROD , 1 , "" ) , 1 , 45 ) )	, _oFont09 ) // 195
				_oPrint:Say( cQtCol + 5 , 0812 , cValToChar( nQtd2UM )																							, _oFont09 ) // 862
				_oPrint:Say( cQtCol + 5 , 0960 , GetAdvFVal( "SB1" , "B1_SEGUM" , xFilial("SB1") + (_cAliasD)->PROD , 1 , "" )									, _oFont09 ) // 1010
				_oPrint:Say( cQtCol + 5 , 1082 , cValToChar( (_cAliasD)->QTDVEN )																				, _oFont09 ) // 1132
				_oPrint:Say( cQtCol + 5 , 1240 , (_cAliasD)->UM1																								, _oFont09 ) // 1290
				_oPrint:Say( cQtCol + 5 , 1342 , Transform( (_cAliasD)->PRCVEN , "@E 99,999,999.99" )															, _oFont09 ) // 1382
				_oPrint:Say( cQtCol + 5 , 1502 , Transform( nPesBru , "@E 9,999,999.999" )																		, _oFont09 ) // 1552
				_oPrint:Say( cQtCol + 5 , 1652 , Transform( (_cAliasD)->TOTAL , "@E 99,999,999.99" ))  //   <<<<															, _oFont09 ) // 1772

				aVlrDesc := {}
				
				If (_cAliasD)->TIPO != '10' 
				    
					_oPrint:Box( cQtCol , 1800 , cQtCol + 40 , 1950 ) // 2000
					_oPrint:Box( cQtCol , 1950 , cQtCol + 40 , 2150 ) // 2200
//------------------------
					_oPrint:Box( cQtCol , 2150 , cQtCol + 40 , 2350 ) // 2200
					
					aVlrDesc	:= U_veriContrato( (_cAliasD)->CODCLI , (_cAliasD)->LOJCLI , (_cAliasD)->PROD )
					nPrcNet		:= (_cAliasD)->PRCVEN - ( ( aVlrDesc[1] * (_cAliasD)->PRCVEN ) / 100 )
					
					_oPrint:Say( cQtCol + 5 , 1810 , Transform( aVlrDesc[1]	, "@E 99,999,999.99" ) , _oFont09 ) // 2010
					_oPrint:Say( cQtCol + 5 , 1960 , Transform( nPrcNet		, "@E 99,999,999.99" ) , _oFont09 ) // 2210
//------------------------					
                    _oPrint:Say( cQtCol + 5 , 2160 , (_cAliasD)->KIT                               , _oFont09 ) // 2210
				Else
					_oPrint:Box( cQtCol , 1800 , cQtCol + 40 , 2000 ) // 2000
					_oPrint:Say( cQtCol + 5 , 1810, (_cAliasD)->KIT                               , _oFont09 ) // 2210
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
					
	    			_oPrint:FillRect( { cQtCol , 0100 , cQtCol + 40 , 0190 } , _oBrush1 )
					_oPrint:FillRect( { cQtCol , 0190 , cQtCol + 40 , 0650 } , _oBrush1 ) // 190 - 700
					_oPrint:FillRect( { cQtCol , 0650 , cQtCol + 40 , 0850 } , _oBrush1 ) // 700 - 900
					_oPrint:FillRect( { cQtCol , 0850 , cQtCol + 40 , 1000 } , _oBrush1 ) // 900 - 1050
					_oPrint:FillRect( { cQtCol , 1000 , cQtCol + 40 , 1200 } , _oBrush1 ) // 1050 - 1250
					_oPrint:FillRect( { cQtCol , 1200 , cQtCol + 40 , 1330 } , _oBrush1 ) // 1250 - 1350
					_oPrint:FillRect( { cQtCol , 1330 , cQtCol + 40 , 1500 } , _oBrush1 ) // 1380 - 1550
					_oPrint:FillRect( { cQtCol , 1500 , cQtCol + 40 , 1650 } , _oBrush1 ) // 1550 - 1700
					_oPrint:FillRect( { cQtCol , 1650 , cQtCol + 40 , 1800 } , _oBrush1 ) // 1700 - 2000
					
					_oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 0190 )
					_oPrint:Box( cQtCol , 0190 , cQtCol + 40 , 0650 ) // 190  - 700
					_oPrint:Box( cQtCol , 0650 , cQtCol + 40 , 0850 ) // 700  - 900
					_oPrint:Box( cQtCol , 0850 , cQtCol + 40 , 1000 ) // 900  - 1050
					_oPrint:Box( cQtCol , 1000 , cQtCol + 40 , 1200 ) // 1050 - 1250
					_oPrint:Box( cQtCol , 1000 , cQtCol + 40 , 1330 ) // 1250 - 1350
					_oPrint:Box( cQtCol , 1330 , cQtCol + 40 , 1500 ) // 1380 - 1550
					_oPrint:Box( cQtCol , 1500 , cQtCol + 40 , 1650 ) // 1550 - 1700
					_oPrint:Box( cQtCol , 1650 , cQtCol + 40 , 1800 ) // 1700 - 2000
					
					_oPrint:Say( cQtCol + 5 , 0110 , "Item:"		, _oFont10n )
					_oPrint:Say( cQtCol + 5 , 0195 , "Descrição:"	, _oFont10n ) // 195
					_oPrint:Say( cQtCol + 5 , 0660 , "Qtd 2UM:"		, _oFont10n ) // 710
					_oPrint:Say( cQtCol + 5 , 0860 , "Seg UM:"		, _oFont10n ) // 910
					_oPrint:Say( cQtCol + 5 , 1010 , "Qtd. 1UM:"	, _oFont10n ) // 1060
					_oPrint:Say( cQtCol + 5 , 1210 , "Unid.:"		, _oFont10n ) // 1260
					_oPrint:Say( cQtCol + 5 , 1340 , "Prc. Vend.:"	, _oFont10n ) // 1390
					_oPrint:Say( cQtCol + 5 , 1510 , "Pes.Bruto:"	, _oFont10n ) // 1560
					_oPrint:Say( cQtCol + 5 , 1660 , "Total:"		, _oFont10n ) // 1710  <<<<

					If cTp != '10' 
					
						aVlrDesc	:= U_veriContrato( (_cAliasD)->CODCLI , (_cAliasD)->LOJCLI , (_cAliasD)->PROD )
						nPrcNet		:= (_cAliasD)->PRCVEN - ( ( aVlrDesc[1] * (_cAliasD)->PRCVEN ) / 100 )
						
						_oPrint:Box( cQtCol , 1800 , cQtCol + 40 , 1950 )  // 2000 - 2200
						_oPrint:Box( cQtCol , 1950 , cQtCol + 40 , 2150 )  // 2400 - 2400

                        _oPrint:Box( cQtCol , 2150 , cQtCol + 40 , 2350 )  // 2400 - 2400
						
						_oPrint:Say( cQtCol + 5 , 1810 , Transform( aVlrDesc[1]	, "@E 99,999,999.99" ) , _oFont09 ) // 2010
						_oPrint:Say( cQtCol + 5 , 1960 , Transform( nPrcNet		, "@E 99,999,999.99" ) , _oFont09 ) // 2210 

                        _oPrint:Say( cQtCol + 5 , 2160 , (_cAliasD)->KIT                                , _oFont09 ) // 2210 
                    Else
					   _oPrint:Box( cQtCol , 1800 , cQtCol + 40 , 2000 )  // 2000 - 2200	
					   _oPrint:Say( cQtCol + 5 , 1810 , (_cAliasD)->KIT                                , _oFont09 ) // 2210					
					EndIf
					
					cQtCol += 40
					
				EndIf
				
			EndDo
			
			If cQtCol > 3450
	
				_oPrint:EndPage()
				_oPrint:StartPage()
				
				cQtCol := 070
	 
	   	    	_oPrint:FillRect( { cQtCol , 0100 , cQtCol + 40 , 0900 } , _oBrush1 )
	   	    	_oPrint:FillRect( { cQtCol , 0850 , cQtCol + 40 , 1000 } , _oBrush1 )  // 0850 - 1000
	   	    	_oPrint:FillRect( { cQtCol , 0950 , cQtCol + 40 , 1080 } , _oBrush1 )  // 1000 - 1130
	   	    	_oPrint:FillRect( { cQtCol , 1080 , cQtCol + 40 , 1330 } , _oBrush1 )  // 1130 - 1280
	   	    	_oPrint:FillRect( { cQtCol , 1230 , cQtCol + 40 , 1330 } , _oBrush1 )  // 1280 - 1380
	   	    	_oPrint:FillRect( { cQtCol , 1330 , cQtCol + 40 , 1500 } , _oBrush1 )  // 1380 - 1550
	   	    	_oPrint:FillRect( { cQtCol , 1500 , cQtCol + 40 , 1650 } , _oBrush1 )  // 1550 - 1750
	   	    	_oPrint:FillRect( { cQtCol , 1650 , cQtCol + 40 , 1800 } , _oBrush1 )  // 1750 - 2000
	   	    	
				_oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 0850 )
				_oPrint:Box( cQtCol , 0850 , cQtCol + 40 , 1000 ) // 0850 - 1000
				_oPrint:Box( cQtCol , 0950 , cQtCol + 40 , 1080 ) // 1000 - 1130
				_oPrint:Box( cQtCol , 1080 , cQtCol + 40 , 1330 ) // 1130 - 1380
				_oPrint:Box( cQtCol , 1230 , cQtCol + 40 , 1330 ) // 1280 - 1380
				_oPrint:Box( cQtCol , 1330 , cQtCol + 40 , 1500 ) // 1380 - 1550
				_oPrint:Box( cQtCol , 1500 , cQtCol + 40 , 1650 ) // 1550 - 1750
				_oPrint:Box( cQtCol , 1650 , cQtCol + 40 , 1800 ) // 1750 - 2000
				
				_oPrint:Say( cQtCol + 5 , 0110 , "Totais do Pedido: "							, _oFont10n )
				_oPrint:Say( cQtCol + 5 , 0860 , nToT2UM										, _oFont10n )
			   	_oPrint:Say( cQtCol + 5 , 1085 , Transform( nToT1UM	, "@E 999999999"		)	, _oFont10n ) // 1135
				_oPrint:Say( cQtCol + 5 , 1502 , Transform( nToTPes	, "@E 9,999,999.999"	)	, _oFont10n ) // 1552
				_oPrint:Say( cQtCol + 5 , 1660 , Transform( nToT	, "@E 99,999,999.99"	)	, _oFont10n ) // 1760
				
				If cTp != '10' 
	 
					_oPrint:FillRect( { cQtCol , 1800 , cQtCol + 40 , 1950 } , _oBrush1 ) // 2000
					_oPrint:FillRect( { cQtCol , 1950 , cQtCol + 40 , 2150 } , _oBrush1 ) // 2200 

                    _oPrint:FillRect( { cQtCol , 2150 , cQtCol + 40 , 2350 } , _oBrush1 ) // 2200 					
					
					_oPrint:Box( cQtCol , 1800 , cQtCol + 40 , 1950 ) // 2000 - 2200
					_oPrint:Box( cQtCol , 1950 , cQtCol + 40 , 2150 ) // 2200 - 2400

                    _oPrint:Box( cQtCol , 2150 , cQtCol + 40 , 2350 ) // 2200 - 2400		
				Else			
				   _oPrint:FillRect( { cQtCol , 1800 , cQtCol + 40 , 2000 } , _oBrush1 ) // 2000
				   _oPrint:Box( cQtCol , 1800 , cQtCol + 40 , 2000 ) // 2200 - 2400	
				EndIf
			
			Else
			
				_oPrint:FillRect( { cQtCol , 0100 , cQtCol + 40 , 0800 } , _oBrush1 ) // 0100 - 0900
				_oPrint:FillRect( { cQtCol , 0800 , cQtCol + 40 , 0950 } , _oBrush1 ) // 0850 - 1000
				_oPrint:FillRect( { cQtCol , 0950 , cQtCol + 40 , 1080 } , _oBrush1 ) // 1000 - 1130
				_oPrint:FillRect( { cQtCol , 1080 , cQtCol + 40 , 1230 } , _oBrush1 ) // 1130 - 1280
			   	_oPrint:FillRect( { cQtCol , 1230 , cQtCol + 40 , 1330 } , _oBrush1 ) // 1280 - 1380
				_oPrint:FillRect( { cQtCol , 1330 , cQtCol + 40 , 1500 } , _oBrush1 ) // 1380 - 1550
				_oPrint:FillRect( { cQtCol , 1500 , cQtCol + 40 , 1650 } , _oBrush1 ) // 1550 - 1750
				_oPrint:FillRect( { cQtCol , 1650 , cQtCol + 40 , 1800 } , _oBrush1 ) // 1750 - 2000
				
				_oPrint:Box( cQtCol , 0100 , cQtCol + 40 , 0800 ) // 0100 - 0850
				_oPrint:Box( cQtCol , 0800 , cQtCol + 40 , 0950 ) // 0850 - 1000
				_oPrint:Box( cQtCol , 0950 , cQtCol + 40 , 1080 ) // 1000 - 1130
				_oPrint:Box( cQtCol , 1080 , cQtCol + 40 , 1230 ) // 1130 - 1380 - 1280
				_oPrint:Box( cQtCol , 1230 , cQtCol + 40 , 1330 ) // 1280 - 1380
				_oPrint:Box( cQtCol , 1330 , cQtCol + 40 , 1500 ) // 1380 - 1550
				_oPrint:Box( cQtCol , 1500 , cQtCol + 40 , 1650 ) // 1550 - 1750
				_oPrint:Box( cQtCol , 1650 , cQtCol + 40 , 1800 ) // 1750 - 2000 
				
				_oPrint:Say( cQtCol + 5 , 0110 , "Totais do Pedido: "						,_oFont10n )
				_oPrint:Say( cQtCol + 5 , 0810 , cValtoChar(nToT2UM)						,_oFont10n ) // 860 
			   	_oPrint:Say( cQtCol + 5 , 1085 , cValToChar(nToT1UM)						,_oFont10n ) // 1135
				_oPrint:Say( cQtCol + 5 , 1502 , Transform( nToTPes	, "@E 9,999,999.999" )	,_oFont10n ) // 1552
				_oPrint:Say( cQtCol + 5 , 1660 , Transform( nToT	, "@E 99,999,999.99" )	,_oFont10n ) // 1760 
	             
				If cTp != '10'
	 			
	 	   	    	_oPrint:FillRect( { cQtCol , 1800 , cQtCol + 40 , 1950 } , _oBrush1 ) // 2000
					_oPrint:FillRect( { cQtCol , 1950 , cQtCol + 40 , 2150 } , _oBrush1 ) // 2200

                    _oPrint:FillRect( { cQtCol , 2150 , cQtCol + 40 , 2350 } , _oBrush1 ) // 2200					
					
					_oPrint:Box( cQtCol , 1800 , cQtCol + 40 , 1950 ) // 2000
					_oPrint:Box( cQtCol , 1950 , cQtCol + 40 , 2150 ) // 2200 

					_oPrint:Box( cQtCol , 2150 , cQtCol + 40 , 2350 ) // 2200 
				Else 
                   _oPrint:FillRect( { cQtCol , 1800 , cQtCol + 40 , 2000} , _oBrush1 ) // 2000
				   _oPrint:Box( cQtCol , 1800 , cQtCol + 40 , 2000 ) // 2200 
				EndIf
			
			EndIf
			
			cQtCol += 120
			
			If cQtCol > 3450
			
				_oPrint:EndPage()
				_oPrint:StartPage()
				
				cQtCol := 070
				
			EndIf
			
			If _cTipo == '10'

				_oPrint:Say( cQtCol			, 0100 , "Autorização: "												, _oFont14n )
				_oPrint:Say( cQtCol + 150	, 0100 , "__________________________________________________________ "	, _oFont14n )
				_oPrint:Say( cQtCol + 300	, 0100 , "__________________________________________________________ "	, _oFont14n )
				_oPrint:Say( cQtCol + 500	, 0075 , "* Bonificação *"												, _oFont48n )
				
			ElseIf _cTipo == '24'

				_oPrint:Say( cQtCol			, 0100 , "Autorização: "												, _oFont14n )
				_oPrint:Say( cQtCol + 150	, 0100 , "__________________________________________________________ "	, _oFont14n )
				_oPrint:Say( cQtCol + 300	, 0100 , "__________________________________________________________ "	, _oFont14n )
				_oPrint:Say( cQtCol + 500	, 0075 , "* Data Crítica *"												, _oFont48n )
				
			Else
			
				_oPrint:Say( cQtCol			, 0100 , "Autorização: "												, _oFont14n )
				_oPrint:Say( cQtCol + 150	, 0100 , "__________________________________________________________ "	, _oFont14n )
				_oPrint:Say( cQtCol + 300	, 0100 , "__________________________________________________________ "	, _oFont14n )
				
			EndIf
			
		EndIf

	    (_cAliasD)->( DBCloseArea() )
	    
	    _oPrint:EndPage()
	    
	Next _nI
	
	_oPrint:Preview()

Else

	MessageBox( 'Não foram encontrados registros para imprimir!' , 'Atenção!' , 48 )

EndIf

Return
