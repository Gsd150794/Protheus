/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
André Lisboa  | 07/01/2020 | Chamado 31640. Na query da tabela SC9 tratar quando retorno For NULL                     
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  | 24/10/2022 | Chamado 41426. Ajuste para execução via Schedule
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  | 01/11/2022 | Chamado 41426. Ajuste para Filtros de Armazens e Filial via Schedule               
-------------------------------------------------------------------------------------------------------------------------------
*/

#Include "TOTVS.ch"  
#Include "RWMAKE.CH"             
#Include "TopConn.ch"                                                         
#Include "vkey.ch"                    

Static _lScheduler := FWGetRunSchedule() .Or. SELECT("SX3") <= 0
                                                 
/*                                                    
===============================================================================================================================
Programa----------: MOMS046   
Autor-------------: Jerry 
Data da Criacao---: 23/12/2019
===============================================================================================================================
Descrição---------: Funcao utilizada para Corrigir B2_RESERVA conforme somatória de C9_QTDLIB
===============================================================================================================================  
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS046()
Private _aLista := {}

MOMS046INI()

Return

/*
===============================================================================================================================
Programa----------: MOMS046INI
===============================================================================================================================
Descrição---------: Funcao que controla o processamento
===============================================================================================================================

*/

Static Function MOMS046INI()
Local _lRet := .T.
Local _LigaDesWS := .T.

Private cMarkado	:= Space(2)
Private lInverte	:= .F.
Private cPerg		:= 'MOMS046'
Private cArqTRB1	:= ''
Private cArqTRB2	:= ''
Private cArqTRB3	:= ''
Private cArqTRB4	:= ''
Private cInd1Trab	:= ''      

 
Begin Sequence
     //Testa se esta sendo rodado do menu
If _lScheduler
	
	RPCSetType( 3 )					//Não consome licensa de uso
		
	RpcSetEnv('01','01',,,,GetEnvServer(),{ "SA3","SE1" })
	sleep( 5000 )					//Aguarda 5 segundos para que as jobs IPC subam.

	cMarkado	:= GetMark()

	_LigaDesWS := U_ITGETMV('ITHABJOBSB2', .T.) 
   	If ! _LigaDesWS
      Break 
   	EndIf 

	MOMS046PRC()

Else
	cMarkado	:= GetMark()

	cPerg := 'MOMS046'	

	If Pergunte( cPerg , .T. )
	       
	   MOMS046PRC()
	   
	EndIf   
EndIf
	
End Sequence

Return _lRet               

/*
===============================================================================================================================
Programa----------: MOMS046PRC
===============================================================================================================================
Descrição---------: Função que Processa 
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS046PRC()

Local _nControle := 0 
Local _lRet      := .T.
Private cMarca   := GetMark()
Private aCampos  := {}
Private cPerg	 := 'MOMS046'
 
Begin Sequence


   Pergunte( cPerg , .F. )
       
   //================================================================================
   // Cria o arquivo Temporario para insercao dos dados selecionados.
   //================================================================================
   If _lScheduler
      _nControle := MOMS046ARQ() 
   Else
      FWMsgRun( , {|| _nControle := MOMS046ARQ() }, "Aguarde!" , 'Lendo Dados ...' )
   EndIf

   If !Empty(_aLista)
      _aLista := {}                             
   EndIf
  
   If _nControle == 1
      If _lScheduler
		U_ITCONOUT("Nao foram encontrados Dados para realizar o processamento.")
	  Else
		Alert("Nao foram encontrados Dados para realizar o processamento.")
      EndIf
	  _lRet := .F. 
	  Break
   EndIf

   _nopc := MOMS046TRS()//Função que monta a tela para processar as Correções

End Sequence
 
Return _lRet 

/*
===============================================================================================================================
Programa----------: MOMS046TRS
===============================================================================================================================
Descrição---------: Função que monta a tela para processar
===============================================================================================================================
*/
                          
Static Function MOMS046TRS()   

Local oPanel		:= Nil
Local oDlg1			:= Nil
Local oQtda			:= Nil 
Local nHeight		:= 0
Local nWidth		:= 0
Local aSize			:= {}
Local aRotina       := {}
Local aCoors		:= {}

Private nOpca		:= 0
Private cFiltro		:= "%" 
Private _aCabecPV	:= {}
Private _aItensPV	:= {}
Private _aCabcPVEx	:= {} 
Private _aItenPVEx	:= {}
Private _aAreaCabec	:= {} 

Private _cFilAtual	:= ""

Private oMark		:= Nil
Private oBrowse		:= Nil  
Private oFilTran	:= Nil
Private _cFilTran	:= ""
Private nQtdProd		:= 0

//================================================================================
// Botoes da tela.
//================================================================================
 
If !_lScheduler
             
	aSize := MSADVSIZE() 
	
	_ctitulo := "Processamento para Correção"


	DEFINE MSDIALOG oDlg1 TITLE OemToAnsi(_ctitulo) From 0,0 To aSize[6],aSize[5] PIXEL 

		oPanel       := TPanel():New(30,0,'',oDlg1,, .T., .T.,, ,315,20,.T.,.T. )    
		@0.8,00.8 Say OemToAnsi("Quantidade:")						OF oPanel
		@0.8,0005 Say oQtda		VAR nQtdProd		Picture "@E 99999"	OF oPanel SIZE 60,8

		If FlatMode()
		
			aCoors	:= GetScreenRes()
			nHeight	:= aCoors[2]
			nWidth	:= aCoors[1]
			
		Else
		
			nHeight	:= 143
			nWidth	:= 315           
			
		EndIf                             
		
		DBSelectArea("TRBF")
		TRBF->(DBGoTop()) 
		
		oMark					:= MsSelect():New( "TRBF" , "TRBF_OK" , "" , aCampos , @lInverte , @cMarkado , { 35 , 1 , nHeight , nWidth } )
		oMark:bMark				:= {|| MOMS046INV( cMarkado , lInverte , oQtda ) }
		oMark:oBrowse:bAllMark	:= {|| MOMS046ALL( cMarkado , oQtda ) }

		oDlg1:lMaximized:=.T.

	ACTIVATE MSDIALOG oDlg1 ON INIT ( EnchoiceBar(oDlg1,{|| IIf(MOMS046VLD(nQtdProd),(nOpca := 1,oDlg1:End()),) },{|| nOpca := 2,oDlg1:End()},,aRotina),;
									oPanel:Align:=CONTROL_ALIGN_TOP , oMark:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT , oMark:oBrowse:Refresh())
Else
	MOMS046ALL( cMarkado , oQtda ) 
	nOpca := 1
EndIf

If nOpca = 1

	MOMS046EXE()

     
EndIf
 
Return nOpca   

/*
===============================================================================================================================
Programa----------: MOMS046EXE
===============================================================================================================================
Descrição---------: Função que Processa a Geração
===============================================================================================================================
*/

Static Function MOMS046EXE(oproc)
Local _aArea := FWGetArea()
Local _nI := 0
Local _nC := 0
Local _cResult := ""

Private _aresults   := {}

DBSelectArea("TRBF")
TRBF->( DBGoTop() )
	
//================================================================================
// Armazena todos os Dados selecionados
//================================================================================
While TRBF->(!Eof())  

	If TRBF->TRBF_OK = cMarkado 
		DBSelectArea("SB2")                     
	    SB2->(DBGoTo( TRBF->TRBF_REC ) )          
		
		 If SB2->(RECNO()) = TRBF->TRBF_REC
	   		aAdd(_aresults, {LoadBitmap(GetResources(),"BR_VERDE"),TRBF->TRBF_FIL,TRBF->TRBF_COD,TRBF->TRBF_DES,TRBF->TRBF_LOC,"Corrigido"})
			SB2->(RecLock("SB2",.F.))
			SB2->B2_RESERVA := TRBF->TRBF_SC9
			SB2->(MSUnLock())          
	   	 EndIf
	EndIf
		                                        
	TRBF->( DBSkip() )                                                           
EndDo                                

If Len(_aresults) > 0
	If _lScheduler
		U_ITConout( "Resultado do processamento")
		U_ITConout( "Correção da Qtd Reservada")
		U_ITConout( " Filial / Cod.Prod / Des.Proc / Local / Resultado")
		For _nI := 1 To Len(_aresults)
			_cResult := ""
			For _nC := 2 To Len(_aresults[_nI])
				_cResult += IIf(Empty(_cResult),"","/") + _aresults[_nI][_nC]
			Next 
			U_ITConout( _cResult )
		Next
	Else
		U_ITListBox( "Correção da Qtd Reservada" , {' ','Filial','Cod.Prod','Des.Proc','Local', 'Resultado'}, _aresults , .T. , 1,"Resultado do processamento" )	
	EndIf
Else
	If _lScheduler
		U_ITConout("Nenhum registro Alterado !")
	Else
		Alert("Nenhum registro Alterado !")
	EndIf
EndIf

//================================================================================
// Fecha a area de uso do arquivo temporario no Protheus.
//================================================================================
TRBF->( DBCloseArea() )

//================================================================================
// Restaura a area
//================================================================================
FWRestArea( _aArea )

Return

/*
===============================================================================================================================
Programa----------: MOMS046INV
===============================================================================================================================
Descrição---------: Rotina para inverter a marcacao do registro posicionado.
===============================================================================================================================
Parametros--------: oMark  - Objeto de dados
------------------: cAlias - Alias temporário
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS046INV( cMarca , lInverte , oQtda )

Local lMarcado := IsMark( "TRBF_OK" , cMarca , lInverte )

If lMarcado
	nQtdProd++
Else
	nQtdProd--
EndIf

If !_lScheduler
	oQtda:Refresh()
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS046ALL
===============================================================================================================================
Descrição---------: Rotina para inverter a marcacao de todos os registros.
===============================================================================================================================
Parametros--------: oMark  - Objeto de dados
------------------: cAlias - Alias temporário
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS046ALL( cMarca , oQtda )

Local nReg     := TRBF->( Recno() )
Local lMarcado := .F.

DBSelectArea("TRBF")
TRBF->( DBGoTop() )

While TRBF->( !Eof() )
	
	lMarcado := IsMark( "TRBF_OK" , cMarca , lInverte )
	
	If lMarcado .Or. lInverte
	
		TRBF->( RecLock( "TRBF" , .F. ) )
		TRBF->TRBF_OK := Space(2)
		TRBF->( MSUnLock() )
		
		nQtdProd--
		
	Else
	
		TRBF->( RecLock( "TRBF" , .F. ) )
		TRBF->TRBF_OK := cMarca
		TRBF->( MSUnLock() )
		
		nQtdProd++
		
	EndIf
	
	nQtdProd := IIf( nQtdProd < 0 , 0 , nQtdProd )
	
TRBF->( DBSkip() )
EndDo

TRBF->( DBGoTo(nReg) )

If !_lScheduler
	oQtda:Refresh()
	oMark:oBrowse:Refresh(.T.)
EndIf

Return
                                               
/*
===============================================================================================================================
Programa----------: MOMS046ARQ
===============================================================================================================================
Descrição---------: Rotina para criação do arquivo temporário
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS046ARQ()
Local aEstru		:= {}
Local _cQuery		:= ""
Local _nNumReg		:= 0
Local _cITFILM036   := U_ItGetMV("ITFILM036","")
Local _cITARMM036   := U_ItGetMV("ITARMM036","")

//================================================================================
// Armazena no array aEstru a estrutura dos campos da tabela.
//================================================================================    

aAdd( aEstru , { "TRBF_OK"	, 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBF_FIL"	, 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBF_COD"	, 'C' , 15 , 0 } )
aAdd( aEstru , { "TRBF_DES"	, 'C' , 100 , 0 } )
aAdd( aEstru , { "TRBF_LOC"	, 'C' , 02 , 0 } )    
aAdd( aEstru , { "TRBF_RES"	, 'N' , 12 , 4 } )
aAdd( aEstru , { "TRBF_SC9"	, 'N' , 12 , 4 } ) 
aAdd( aEstru , { "TRBF_REC" , 'N' , 08 , 0 } ) 
 
//================================================================================
// Armazena no array aCampos o nome, picture e descricao dos campos
//================================================================================
aAdd( aCampos , { "TRBF_OK"		, "" , " "			, " "										} )
aAdd( aCampos , { "TRBF_FIL"	, "" , "Filial"		, PesqPict( "SB2" , "B2_FILIAL"	 )			} )    
aAdd( aCampos , { "TRBF_COD"	, "" , "Produto"	, PesqPict( "SB1" , "B1_COD"	 )	 		} )
aAdd( aCampos , { "TRBF_DES"	, "" , "Descricao"	, PesqPict( "SB1" , "B1_DESC"	 )	 		} )
aAdd( aCampos , { "TRBF_LOC"	, "" , "Local"		, PesqPict( "SB1" , "B1_LOCAL" )	  		} ) 
aAdd( aCampos , { "TRBF_RES"	, "" , "Qtd Reservada"	, PesqPict( "SB2" , "B2_RESERVA" )	  		} ) 
aAdd( aCampos , { "TRBF_SC9"	, "" , "Qtd Pedido Reservado"	, PesqPict( "SC9" , "C9_QTDLIB" )	  		} )
aAdd( aCampos , { "TRBF_REC"	, "" , "Recno"  , PesqPict( "SB1" , "B1_FATOR" )	  		} )  

//================================================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//================================================================================
If Select("TRBF") > 0
	TRBF->( DBCloseArea() )
EndIf

//================================================================================
// Abre o arquivo TRBF criado dentro do protheus.
//================================================================================
_otemp := FWTemporaryTable():New( "TRBF",  aEstru )
   
//================================================================================
// Cria os indices para o arquivo.
//================================================================================
_otemp:AddIndex( "01", {"TRBF_FIL","TRBF_COD","TRBF_LOC" } ) 
_otemp:Create()   
   
DBSelectArea("TRBF")

//INICIO
_cQuery := "SELECT SB2REC,	B2_FILIAL,	B2_COD,	B2_LOCAL,	B2_RESERVA,	C9_RESERVA,	B1_DESC  "
_cQuery += " FROM (  "
_cQuery += " SELECT SB2.R_E_C_N_O_ SB2REC, B2_FILIAL, B2_LOCAL, B2_COD , B1_DESC, B2_QATU,B2_QNPT, B2_RESERVA "
_cQuery += " ,  NVL((SELECT SUM(SC9.C9_QTDLIB)  "
_cQuery += " FROM " + RetSqlName("SC9") + " SC9," + RetSqlName("SC6") + " SC6," + RetSqlName("SF4") + " SF4 "
_cQuery += " WHERE SC9.D_E_L_E_T_ = ' '  "
_cQuery += " AND C9_PRODUTO       = B2_COD "
_cQuery += " AND C9_FILIAL        = B2_FILIAL "           
_cQuery += " AND C9_LOCAL         = B2_LOCAL "
_cQuery += " AND C9_NFISCAL       = ' '  "       
_cQuery += " AND C9_BLEST         =  ' ' "  
_cQuery += " AND SC6.C6_FILIAL    = SC9.C9_FILIAL "
_cQuery += " AND SC6.C6_NUM       = SC9.C9_PEDIDO "
_cQuery += " AND SC6.C6_ITEM      = SC9.C9_ITEM "
_cQuery += " AND SC6.C6_PRODUTO   = SC9.C9_PRODUTO "
_cQuery += " AND SC6.D_E_L_E_T_   = ' ' "
_cQuery += " AND SF4.F4_FILIAL    = SC9.C9_FILIAL  " 
_cQuery += " AND SF4.F4_CODIGO    = SC6.C6_TES "
_cQuery += " AND SF4.F4_ESTOQUE   = 'S' " 
_cQuery += " AND SF4.D_E_L_E_T_   = ' ' "
_cQuery += " GROUP BY C9_FILIAL, C9_LOCAL,  C9_PRODUTO ),0) C9_RESERVA "
_cQuery += " FROM " + RetSqlName("SB2") + " SB2," + RetSqlName("SB1") + " SB1"  
_cQuery += " WHERE SB2.D_E_L_E_T_ = ' '
If !Empty(MV_PAR01)               
	_cQuery += " AND B2_COD = '" + MV_PAR01 + "' "
EndIf
If !_lScheduler
	_cQuery += " AND B2_FILIAL = '" + xFilial("SB2") + "' "  
	If !Empty(MV_PAR02)
		_cQuery += " AND B2_LOCAL = '" + AllTrim(MV_PAR02) + "' "
	EndIf
Else
	If !Empty(_cITFILM036)
		_cQuery += " AND B2_FILIAL IN " + FormatIn(_cITFILM036,";") 
	EndIf
	If !Empty(_cITARMM036)
		_cQuery += " AND B2_LOCAL IN " + FormatIn(_cITARMM036,";") 
	EndIf
EndIf
_cQuery += " AND B1_FILIAL = ' ' "
_cQuery += " AND B1_COD = B2_COD  "
_cQuery += " AND B1_TIPO IN ( 'PA','UN') ) "
_cQuery += " WHERE  (B2_RESERVA-C9_RESERVA) <> 0 "

If Select("QRYSB2") > 0
	QRYSB2->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery), "QRYSB2" , .T. , .F.)

DBSelectArea("QRYSB2")
QRYSB2->( DBGoTop() )

//================================================================================
// 1 - Indica que nao foram encontrados dados
// 0 - Indica que foram encontrados dados
//================================================================================
_nRet := 1

While QRYSB2->(!Eof())
    _nRet := 0
    
	//================================================================================
	// Armazena o numero de registros encontrados.
	//================================================================================
	_nNumReg++
			
	DBSelectArea("TRBF")					
	TRBF->( dbappend() )         

	TRBF->TRBF_FIL := QRYSB2->B2_FILIAL
	TRBF->TRBF_COD := QRYSB2->B2_COD
	TRBF->TRBF_DES := QRYSB2->B1_DESC	
	TRBF->TRBF_LOC := QRYSB2->B2_LOCAL
	TRBF->TRBF_RES := QRYSB2->B2_RESERVA
	TRBF->TRBF_SC9 := QRYSB2->C9_RESERVA
	TRBF->TRBF_REC := QRYSB2->SB2REC

	QRYSB2->( DBSkip() )
	
EndDo

QRYSB2->( DBCloseArea())
If _nNumReg == 0
	_nRet := 1
EndIf	

Return( _nRet )

/*
===============================================================================================================================
Programa----------: MOMS046VLD
===============================================================================================================================
Descrição---------: Verifica a seleção dos produtos inconsistentes 
===============================================================================================================================
Parametros--------: nQtdProd   - Quantidade produtos Selecionados
===============================================================================================================================
Retorno-----------: _lRet     - Define se os dados foram validados com sucesso
===============================================================================================================================
*/
Static Function MOMS046VLD( nQtdProd )

Local _lRet		:= .T.

//================================================================================
// Verifica se o usurio selecionou alguma linha
//================================================================================
If nQtdProd == 0 
	If _lScheduler
		U_ItConout("Para executar a rotina  deve-se primeiramente selecionar o(s) Registro(s)."    )
	Else
		Alert("Para executar a rotina  deve-se primeiramente selecionar o(s) Registro(s)."    )
	EndIf
	_lRet := .F.										
EndIf

Return( _lRet )               
