/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |12/07/2024| Chamado 47714. Ajustes para adição de filtro.
Igor Melgaço  |10/06/2025| Chamado 45229. Ajuste do parâmetro p/determinar se a integração WebS.será TMS Multiembarcador ou RDC
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
==============================================================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
========================================================================================================================================================================================================
Jerry    - Julio Paz     - 27/10/25 - 05/11/25 - 51789   - Alterar a query que lista os pedidos de vendas para permitir visualizar e selecionar pedidos de remessa.
========================================================================================================================================================================================================
*/

#Include "TOTVS.ch"  
#Include "vkey.ch"

/*
===============================================================================================================================
Programa----------: AOMS108
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/04/2018
Descrição---------: Funcao utilizada para realizar a exclusão multipla de pedidos de vendas - Chamado 24028
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS108()

Private nRadMenu1 := 1
Private _alista := {}

AOMS108INI()

Return

/*
===============================================================================================================================
Programa----------: AOMS108INI
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/04/2018
Descrição---------: Funcao que controla o processamento da exclusão
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS108INI()

Local _lRet := .T.

Private cMarkado	:= GetMark()
Private lInverte	:= .F.
Private cPerg		:= 'AOMS108'
Private cArqTRB1	:= ''
Private cArqTRB2	:= ''
Private cArqTRB3	:= ''
Private cArqTRB4	:= ''
Private cInd1Trab	:= ''
Private cIndTRB1	:= 'TRBF_NUM'
Private aCampos		:= {}
Private _mvpar15    := ""
Private _mvpar16    := ""
Private _mvpar17   := ""

Begin Sequence
	
   //================================================================================
   // Tela de Parametros
   //================================================================================
   If !Pergunte( cPerg , .T. )
      _lRet := .F.		
      Break
   EndIf

   //Validação de campos de produto e grupo
   If !Empty(MV_PAR15) .And. !Empty(MV_PAR16)

      U_ITMsg("Só é possível selecionar produto ou grupo de produto para exclusão!","Atenção","Selecione somente produto ou somente grupo de produto para exclusão",1)
	  _lRet := .F.
	
   EndIf

   //Validação de campos de produto e subgrupo
   If !Empty(MV_PAR15) .And. !Empty(MV_PAR17)

      U_ITMsg("Só é possível selecionar produto ou subgrupo de produto para exclusão!","Atenção","Selecione somente produto ou somente subgrupo de produto para exclusão",1)
	  _lRet := .F.
	
   EndIf

   //Validação de campos de grupo e subgrupo
   If !Empty(MV_PAR16) .And. !Empty(MV_PAR17)

      U_ITMsg("Só é possível selecionar grupo ou subgrupo de produto para exclusão!","Atenção","Selecione somente grupo ou somente subgrupo de produto para exclusão",1)
	  _lRet := .F.
	
   EndIf
	
   _mvpar15 := MV_PAR15
   _mvpar16 := MV_PAR16	
   _mvpar17 := MV_PAR17

   //==========================================
   //Grava log de utilização da rotina
   //==========================================
   U_ITLOGACS()

   AOMS108PRC()

End Sequence

Return _lRet 

/*
===============================================================================================================================
Programa----------: AOMS108PRC
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/04/2018
Descrição---------: Função que Processa os pedidos de venda
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS108PRC()

Local _nControle := 0 
Local _lRet      := .T.
Private cMarca   := GetMark()
Private aCampos  := {}
Private cPerg		:= 'AOMS108'

Begin Sequence
   Pergunte( cPerg , .F. )
       
   //================================================================================
   // Cria o arquivo Temporario para insercao dos dados selecionados.
   //================================================================================
   FWMsgRun( , {|| _nControle := AOMS108ARQ() }, "Aguarde!" , 'Lendo Dados dos pedidos...' )

   If ! Empty(_alista)
      U_ITListBox( 'Pedidos que não podem ser excluidos' , {"Numero","Situacao"} , _alista , .T. , 1 )
      _alista := {}
   EndIf
  
   If _nControle == 1

	  U_ITMsg("Nao foram encontrados pedidos para realizar a exclusão multipla."					,;
				"Atenção!"																						,;
				"Favor verificar os parâmetros informados e se possue(m) pedido(s) de venda em aberto(status verde) "+;
				"para a filial corrente. Pedidos de PALLET CHEP não podem ser excluidos por essa função.",1)


      _lRet := .F. 
      Break

   EndIf

   _nopc := AOMS108TRS()//Função que monta a tela para processar as exclusoes 

End Sequence

Return _lRet 

/*
===============================================================================================================================
Programa----------: AOMS108TRS
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/04/2018
Descrição---------: Função que monta a tela para processar as exclusoes
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS108TRS()

Local oPanel		:= Nil
Local oDlg1			:= Nil
Local oQtda			:= Nil
Local nHeight		:= 0
Local nWidth		:= 0
Local aSize			:= {}
Local aBotoes		:= {}
Local aCoors		:= {}
Local nLinha        := 10
Local _nCol			:= 15


Private nOpca		:= 0
                             
Private cFiltro		:= "%" 
Private _aCabecPV	:= {}
Private _aItensPV	:= {}
Private _aCabcPVEx	:= {} 
Private _aItenPVEx	:= {}
Private _aAreaCabec	:= {} 

Private _cFilPed	:= ""
Private _cNumPed	:= ""          
Private nSaveSX8	:= "" 
Private _cFilAtual	:= ""

Private oMark		:= Nil
Private oBrowse		:= Nil  
Private oFilTran	:= Nil
Private _cFilTran	:= ""
Private nQtdTit		:= 0


DEFINE FONT oFontLbl NAME "Arial" SIZE 6, 15 BOLD

//================================================================================
// Botoes da tela.
//================================================================================
aAdd( aBotoes , { "PESQUISA" , {|| AOMS108PSQ(oMark,"TRBF") }	, "Pesquisar..."         , "Pesquisar"		} )
aAdd( aBotoes , { "S4WB005N" , {|| AOMS108PPV()           }		, "Visualizar Pedido..." , "Visualizar Pedido"	} ) // "Pedido"

//================================================================================
// Faz o calculo automatico de dimensoes de objetos
//================================================================================
aSize := MSADVSIZE() 


//================================================================================
// Cria a tela para selecao dos pedidos
//================================================================================
_ctitulo := "EXCLUSAO MULTIPLA DE PEDIDO(S) DE VENDA (EXCLUSAO COMPLETA)"

If !Empty(MV_PAR15)

	_ctitulo := "EXCLUSAO MULTIPLA DE PEDIDO(S) DE VENDA (SOMENTE PRODUTO " + AllTrim(MV_PAR15) + ")"
	
EndIf

If !Empty(MV_PAR16)

	_ctitulo := "EXCLUSAO MULTIPLA DE PEDIDO(S) DE VENDA (SOMENTE GRUPO " + AllTrim(MV_PAR16) + ")"
	
EndIf

If !Empty(MV_PAR17)

	_ctitulo := "EXCLUSAO MULTIPLA DE PEDIDO(S) DE VENDA (SOMENTE SUBGRUPO " + AllTrim(MV_PAR17) + ")"
	
EndIf


DEFINE MSDIALOG oDlg1 TITLE OemToAnsi(_ctitulo) From 0,0 To aSize[6],aSize[5] OF oMainWnd PIXEL

oPanel       := TPanel():New(30,0,'',oDlg1,, .T., .T.,, ,315,20,.T.,.T. )
@0.8,00.8 Say OemToAnsi("Quantidade:")						OF oPanel
@0.8,0005 Say oQtda		VAR nQtdTit		Picture "@E 99999"	OF oPanel SIZE 60,8


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
oMark:bMark				:= {|| AOMS108INV( cMarkado , lInverte , oQtda ) }
oMark:oBrowse:bAllMark	:= {|| AOMS108ALL( cMarkado , oQtda ) }

oDlg1:lMaximized:=.T.

ACTIVATE MSDIALOG oDlg1 ON INIT ( EnchoiceBar(oDlg1,{|| IIf(AOMS108VLD(nQtdTit),(nOpca := 1,oDlg1:End()),) },{|| nOpca := 2,oDlg1:End()},,aBotoes),;
								oPanel:Align:=CONTROL_ALIGN_TOP , oMark:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT , oMark:oBrowse:Refresh())

If nOpca = 1

	_cQuery := " SELECT "
	_cQuery += " DISTINCT X5_CHAVE CHAVE,X5_DESCRI DESCRI "
	_cQuery += " FROM "+ RetSqlName("SX5") +" X5 "
	_cQuery += " WHERE "
	_cQuery += "     D_E_L_E_T_ = ' ' "
	_cQuery += " AND X5_TABELA  = 'Z1' AND TRIM(X5_CHAVE) <> '98' AND TRIM(X5_CHAVE) <> '99' "
	_cQuery += " ORDER BY X5_CHAVE "

	If Select("TMPCF") > 0 
		("TMPCF")->( DBCloseArea() )
	EndIf

	_cQuery := ChangeQuery(_cQuery)
	MPSysOpenQuery(_cQuery,'TMPCF')

	_amotivs := {}

	While TMPCF->( !Eof() )
                               
		aAdd( _amotivs , AllTrim( TMPCF->CHAVE ) + " - " + AllTrim( TMPCF->DESCRI ) )

		TMPCF->( DBSkip() )
	EndDo

	("TMPCF")->( DBCloseArea() )

	Public _cmotivs := _AMOTIVS[1]

	DEFINE MSDIALOG _oDlg2 TITLE ("Corte por exclusão de PVs") From 0,0 To 325, 650 OF oMainWnd PIXEL
                                                                       
	@ nLinha,_nCol Say OemToAnsi("Selecione o motivo para corte:")
	nLinha+=12

	_omotiv := TComboBox():New(nLinha,_nCol,{|u|If(PCount()>0,_cmotivs:=u,_cmotivs)}, _amotivs,250,20,_oDlg2,,;
							,,,,.T.,,,,,,,,,'') //40

	nLinha+=38

	@ nLinha,_nCol    Button "OK" SIZE 41,15 ACTION ( _oDlg2:End(), FWMsgRun( , {|oproc| AOMS108EXE(oproc) }, "Aguarde!" , 'PROCESSANDO EXCLUSAO DOS PEDIDOS DE VENDAS...' )) Pixel 
	@ nLinha,_nCol+57 Button "Cancela"     SIZE 41,15 ACTION ( _oDlg2:End() ) Pixel 

	ACTIVATE MSDIALOG _oDlg2 

     
 EndIf

Return nOpca

/*
===============================================================================================================================
Programa----------: AOMS108EXE
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/04/2018
Descrição---------: Função que Processa as exclusoes
Parametros--------: oproc - objeto da regua de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function AOMS108EXE(oproc)

Local _aArea		:= FWGetArea()
Local _lOK_RDC      := .T.

Local _cFilRem, _cPedRemessa
Local _cMsg, _cCodOper, _dDataOper, _cEncer
Local _bPergunte    := {|| Pergunte( cPerg , .F. ) }
Local _cTextoMsg := ""

Private lMsErroAuto	:= .F.                        
Private lMsHelpAuto	:= .T.
Private lAutoErrNoFile := .T.  
Private _cAOMS074Vld   := " "  
                                            
If nOpca == 1

	DBSelectArea("TRBF")
	TRBF->( DBGoTop() )
	
	//================================================================================
	// Armazena todos os pedidos selecionados pelo usuario
	//================================================================================
	While TRBF->(!Eof())
	
		//================================================================================
		// Somente pedidos selecionados pelo usuario
		//================================================================================
		If IsMark( "TRBF_OK" , cMarkado )
		    
		    //================================================================================
		    // A filial dos pedidos eh sempre a mesma
		    //================================================================================
			_cFilPed	:= TRBF_FILIA
			_cNumPed	+= "'"+ TRBF_NUM +"',"
		
		EndIf
		
	TRBF->( DBSkip() )
	EndDo
	
	//================================================================================
	// Fecha a area de uso do arquivo temporario no Protheus.
	//================================================================================
	TRBF->( DBCloseArea() )

	//================================================================================
	// Verifica se ja existe um arquivo com mesmo nome, se sim deleta
	//================================================================================
	If Select("QRYCABEC") <> 0
		QRYCABEC->( DBCloseArea() )
	EndIf
	
	//================================================================================
	// Filtro para selecao dos dados do pedido de venda
	//================================================================================
	cFiltro += " AND C5_FILIAL = '"+ _cFilPed +"' "
	cFiltro += " AND C5_NUM    IN (" + SubStr(_cNumPed,1,Len(_cNumPed) - 1) + ") "
	cFiltro += "%"
	
	//================================================================================
	// Query para selecao dos dados do cabecalho do pedido de venda
	//================================================================================
	BeginSql alias "QRYCABEC"
	
	   	SELECT
				C5_TIPO,C5_CLIENTE,C5_LOJACLI,C5_CLIENT,C5_LOJAENT,C5_TIPOCLI,C5_CONDPAG,C5_TIPOCLI,C5_VEND1,C5_EMISSAO,C5_TPFRETE,
				C5_VOLUME1,C5_ESPECI1,C5_NUM,C5_FILIAL,C5_TPCARGA,C5_TRANSP,C5_MENPAD,C5_MOEDA,C5_MENNOTA,C5_VEND2,C5_VEND3,C5_I_CDUSU,
				C5_I_HREMI,C5_DESCONT,C5_PDESCAB,C5_PARC1,C5_DATA1,C5_PARC2,C5_DATA2,C5_PARC3,C5_DATA3,C5_PARC4,C5_DATA4,C5_FRETE,C5_PESOL,
				C5_PBRUTO,C5_I_NRZAZ,C5_I_HOREN,C5_I_SENHA,C5_I_OBCOP,C5_I_OBPED,C5_I_BLOQ,C5_I_MTBON,C5_I_DLIBE,C5_I_HLIBE,C5_I_STAWF,C5_I_PEDGE,C5_I_NPALE,
				C5_I_DTENT,C5_I_OPER,C5_I_BLPRC,C5_I_IDPED,C5_I_MOTLB,C5_I_VLIBB,C5_I_QLIBB,C5_I_LLIBB,C5_I_CLILB,C5_I_ULIBB,C5_I_MOTBL,
				C5_I_DTLIC,	C5_I_BLCRE,C5_I_LIBCV,C5_I_LIBL,C5_I_LIBCT,C5_I_LIBCD,C5_I_LIBCA,C5_I_TRCNF,C5_I_FILFT,C5_I_AGEND, C5_I_PEVIN,C5_I_ENVRD,C5_I_LIBC
					  
		FROM	%Table:SC5% C5
		WHERE	D_E_L_E_T_ = ' '
				%exp:cFiltro%
		
	EndSql
	
	//================================================================================
	// Percorre os pedidos selecionados e monta o cabecalho e itens do pedido de venda
	//================================================================================
	Begin Transaction
	
	_npv := 1
	
	While QRYCABEC->( !Eof() )
	
		DBSelectArea("SC5")
		SC5->( DBSetOrder(1) )
		SC5->( DBSeek( QRYCABEC->C5_FILIAL + QRYCABEC->C5_NUM) )
				
		_cFilPed := QRYCABEC->C5_FILIAL
		_cNumPed := QRYCABEC->C5_NUM         
		
		_cFilRem := ""
		_cPedRemessa := ""
		
		If SC5->C5_I_OPER == "05" // Operação Triangular.
		   If ! Empty(SC5->C5_I_PVREM) // Pedido de Remessa.
		      _cFilRem := SC5->C5_FILIAL // Filial da Remessa.
		      _cPedRemessa := SC5->C5_I_PVREM  
		   EndIf
		EndIf
						
		//Atualiza régua
		oproc:cCaption := ("Processando pedido de vendas... ["+ StrZero(_npv,6) +"] de ["+ StrZero(nQtdTit,6) +"]")
		ProcessMessages()
		_npv++
		
		//================================================================================
		// Zera Variaveis de controle
		//================================================================================
		_aCabecPV	:= {}
		_aItensPV	:= {}
		_aCabcPVEx	:= {}
		_aItenPVEx	:= {}
		_lblqprc    := .F.
		
	
		//================================================================================
		// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
		//================================================================================
		If Select("QRYITENS") <> 0
			QRYITENS->( DBCloseArea() )
		EndIf
		
		//================================================================================
		// Filtro para selecao dos dados do pedido de venda
		//================================================================================
		cFiltro   := "% "
		cFiltro   += " AND C6_FILIAL = '"+ _cFilPed +"' AND C6_NUM  = '"+ _cNumPed +"' "
		
		//================================================================================
		// Na exclusão por produto ou grupo, filtra os itens do pedido de vendas que possuem o
		// produto/grupo/SUBGRUPO informado no parâmetro MV_PAR15/MV_PAR16/MV_PAR17.
		//================================================================================
		If !Empty(MV_PAR15)
		   cFiltro += " AND C6_PRODUTO = '" + MV_PAR15 + "' "
		EndIf
		
		If !Empty(MV_PAR16)
		   cFiltro += " AND (SELECT B1_GRUPO FROM " + Retsqlname("SB1")  + " B1  WHERE B1.D_E_L_E_T_ = ' ' AND B1_COD = C6.C6_PRODUTO) = '" + MV_PAR16 + "' "
		EndIf

		If !Empty(MV_PAR17)
		   cFiltro += " AND (SELECT B1_I_SUBGR FROM " + Retsqlname("SB1")  + " B1  WHERE B1.D_E_L_E_T_ = ' ' AND B1_COD = C6.C6_PRODUTO) = '" + MV_PAR17 + "' "
		EndIf
		
		
		cFiltro   += " %"
		
		//================================================================================
		// Query para selecao dos itens do pedido de venda
		//================================================================================
		BeginSql alias "QRYITENS"
		
			SELECT	C6_ITEM,C6_PRODUTO,C6_QTDVEN,C6_PRCVEN,C6_LOCAL,C6_UM,
					C6_VALOR,C6_TES,C6_PEDCLI,C6_QTDLIB,C6_ENTREG,C6_FILIAL,
					C6_CF,C6_LOCAL,C6_PRUNIT,C6_UNSVEN,C6_I_QESP,C6_I_LIBPR,C6_I_BLPRC,
					C6_I_PLIBB,C6_I_LIBPR,C6_I_LLIBB,C6_I_VLIBB,C6_I_QLIBB,C6_I_DLIBB,
					C6_I_MOTLB,C6_I_LIBPC
			FROM	%Table:SC6% C6
			WHERE	D_E_L_E_T_ = ' '
					%exp:cFiltro%
		
		EndSql
		
		DBSelectArea("QRYITENS")
		QRYITENS->( DBGoTop() )
		
		While QRYITENS->( !Eof() )
		
			SA1->(DBSetOrder(1))
			SA1->(DBSeek(xFilial("SA1") + QRYCABEC->C5_CLIENTE + QRYCABEC->C5_LOJACLI))
			
			_cfilg := cfilant
			cfilant := SubStr(_cFilTran,1,2)
			SM0->( DBSetOrder(1))   
			SM0->( DBSeek( SubStr( cNumEmp , 1 , 2 ) + cFilAnt ) )
			
		
		
			cfilant := _cfilg
			SM0->( DBSetOrder(1))   
			SM0->( DBSeek( SubStr( cNumEmp , 1 , 2 ) + cFilAnt ) )
			
			
			If !Empty(MV_PAR15) .Or. !Empty(MV_PAR16) .Or. !Empty(MV_PAR17)
			   //================================================================================
			   // Realiza a exclusão do item informado no parâmetro MV_PAR15/MV_PAR16/MV_PAR17 já 
			   // filtrado na query.
			   //================================================================================
			   aAdd( _aItenPVEx , { { "LINPOS"     ,"C6_ITEM", QRYITENS->C6_ITEM},; 
                                    { "AUTDELETA"  ,"S"                     ,Nil},; 
									{ "C6_FILIAL"  , QRYITENS->C6_FILIAL	,Nil},; 
									{ "C6_ITEM"    , QRYITENS->C6_ITEM		,Nil},;
									{ "C6_PRODUTO" , QRYITENS->C6_PRODUTO	,Nil},;
									{ "C6_QTDVEN"  , QRYITENS->C6_QTDVEN	,Nil},;
									{ "C6_UM"      , QRYITENS->C6_UM		,Nil},;
									{ "C6_PRCVEN"  , QRYITENS->C6_PRCVEN	,Nil},;
									{ "C6_VALOR"   , QRYITENS->C6_VALOR	    ,Nil},;
									{ "C6_PEDCLI"  , QRYITENS->C6_PEDCLI	,Nil},;
									{ "C6_QTDLIB"  , QRYITENS->C6_QTDLIB	,Nil},;
									{ "C6_LOCAL"   , QRYITENS->C6_LOCAL	    ,Nil},;
									{ "C6_NUM"     , _cNumPed				,Nil}})
		    Else
		       //=============================================================================
		       // Realiza a exclusão de todos os itens do pedido de vendas.
		       //=============================================================================
		       aAdd( _aItenPVEx , {	{ "C6_FILIAL"  , QRYITENS->C6_FILIAL	,Nil},; 
									{ "C6_ITEM"    , QRYITENS->C6_ITEM		,Nil},;
									{ "C6_PRODUTO" , QRYITENS->C6_PRODUTO	,Nil},;
									{ "C6_QTDVEN"  , QRYITENS->C6_QTDVEN	,Nil},;
									{ "C6_UM"      , QRYITENS->C6_UM		,Nil},;
									{ "C6_PRCVEN"  , QRYITENS->C6_PRCVEN	,Nil},;
									{ "C6_VALOR"   , QRYITENS->C6_VALOR	    ,Nil},;
									{ "C6_PEDCLI"  , QRYITENS->C6_PEDCLI	,Nil},;
									{ "C6_QTDLIB"  , QRYITENS->C6_QTDLIB	,Nil},;
									{ "C6_LOCAL"   , QRYITENS->C6_LOCAL	    ,Nil},;
									{ "C6_NUM"     , _cNumPed				,Nil}})
		    EndIf
		
		   QRYITENS->( DBSkip() )
		EndDo
		
		QRYITENS->( DBCloseArea() )
		
		//================================================================================
		// Prepara arrays de cabeçalhos dos pedidos
		//================================================================================
		_aCabcPVEx := {		{ "C5_FILIAL"  , QRYCABEC->C5_FILIAL   			,Nil},;
							{ "C5_NUM"     , QRYCABEC->C5_NUM         		,Nil},;
							{ "C5_TIPO"    , QRYCABEC->C5_TIPO    			,Nil},;
							{ "C5_CLIENTE" , QRYCABEC->C5_CLIENTE 			,Nil},;
							{ "C5_LOJACLI" , QRYCABEC->C5_LOJACLI 			,Nil},;
							{ "C5_CLIENT " , QRYCABEC->C5_CLIENT  			,Nil},; // Codigo do cliente
							{ "C5_LOJAENT" , QRYCABEC->C5_LOJAENT 			,Nil},; // Loja para entrada
							{ "C5_TIPOCLI" , QRYCABEC->C5_TIPOCLI 			,Nil},;
							{ "C5_CONDPAG" , QRYCABEC->C5_CONDPAG 			,Nil},;
							{ "C5_VEND1"   , QRYCABEC->C5_VEND1   			,Nil},;
							{ "C5_EMISSAO" , SToD(QRYCABEC->C5_EMISSAO) 	,Nil},;
							{ "C5_TPFRETE" , QRYCABEC->C5_TPFRETE 			,Nil},;
							{ "C5_VOLUME1" , QRYCABEC->C5_VOLUME1 			,Nil},;
							{ "C5_ESPECI1" , QRYCABEC->C5_ESPECI1 			,Nil},;
							{ "C5_TPCARGA" , QRYCABEC->C5_TPCARGA 			,Nil},;
							{ "C5_I_AGEND" , QRYCABEC->C5_I_AGEND 			,Nil},;
							{ "C5_I_ENVRD" , "N"                			,Nil},;							
					  		{ "C5_I_IDPED" , QRYCABEC->C5_I_IDPED			,Nil} }  
		
		_aAreaCabec := QRYCABEC->( FWGetArea() )
		
		
		DBSelectArea("SC5")
		SC5->( DBSetOrder(1) )
		
				
		//=======================================================================================================
		// Caso outro usuario exclua, libere, fature ou bloqueie o Pedido de Venda posteriormente ao usuario ter 
		// clicado no botao ok da exclusao
		//=======================================================================================================
		If SC5->( DBSeek( xFilial("SC5") + _cNumPed ) ) .And. Empty(SC5->C5_LIBEROK) .And. Empty(SC5->C5_NOTA) .And. Empty(SC5->C5_BLQ) 
					
			//Verifica pedido vinculado
			If !Empty(SC5->C5_I_PEVIN)
			
			  If (Empty(MV_PAR15) .And. Empty(MV_PAR16) .And. Empty(MV_PAR17)) .Or. AOMS108N(_cNumPed) == 1	
				
				If !U_ITMsg("Existe pedido vinculado (" + SC5->C5_I_PEVIN +  "). Desvincular e excluir o pedido principal?","Atenção","O pedido vinculado continuará inalterado.",2,2,2)
				
					QRYCABEC->( DBSkip() )
					Loop
					
				Else
				
					_nc5ori := SC5->(Recno())
					
					If ((Empty(MV_PAR15) .And. Empty(MV_PAR16) .And. Empty(MV_PAR17)) .Or. AOMS108N(_cNumPed) == 1 ) .And. SC5->( DBSeek( xFilial("SC5") + SC5->C5_I_PEVIN ) )
					
						RecLock("SC5",.F.)
						SC5->C5_I_PEVIN := " "
						SC5->(MSUnLock())
						
					EndIf
					
					SC5->(DBGoTo(_nc5ori)) 
					
					RecLock("SC5",.F.)
					SC5->C5_I_PEVIN := " "
					SC5->(MSUnLock())
				
				EndIf
				
			  EndIf
				
			EndIf
			
			//Se o cliente estiver bloqueado 
			SA1->(DBSetOrder(1))
			_lbloqcli := .F.
			If SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)) .And. SA1->A1_MSBLQL == '1'
			
				_lbloqcli := .T.
				_ccliente := SC5->C5_CLIENTE
				_clojacli := SC5->C5_LOJACLI
				_cobs := SA1->A1_I_ACRED
				RecLock("SA1",.F.)
				SA1->A1_MSBLQL := "2"
				SA1->A1_I_ACRED := _cobs + CHR(13)+CHR(10) + "Desbloqueado pela rotina AOMS108 em " + DToC(Date())
				SA1->(MSUnLock())
				
			EndIf
            
			_lOK_RDC := .T.

			_clocmot := _cmotivs
			If SC5->C5_I_ENVRD = "S"
			   If !u_IT_TMS(SC5->C5_I_LOCEM)  //! _lWsTms 
				  FWMsgRun( ,{|P| _lOK_RDC:=U_AOMS094E(P)} , 'Aguarde!' , 'Enviando para o RDC o cancelamento do Pedido...') 
			   Else
                  FWMsgRun( ,{|P| _lOK_RDC:=U_AOMS140E(P, .T.)} , 'Aguarde!' , 'Enviando para o TMS Multi-Embarcador o cancelamento do Pedido...') 
			   EndIf 
            EndIf
 
            _lExclParcial:= .T.
		    _cAOMS074    := "AOMS108"  	 //Não mostra mensagens do mata410
		    _cAOMS074Vld := " " //Zera para cada pedido

			If _lOK_RDC
			   	If !Empty(MV_PAR15) .Or. !Empty(MV_PAR16) .Or. !Empty(MV_PAR17)
					//================================================================================
					// Realiza a exclusão do item informado no parâmetro MV_PAR15/MV_PAR16/MV_PAR17 já 
					// filtrado na query.
					//================================================================================
					If AOMS108N(_cNumPed) == 1 // Indica que só existe um item/grupo no pedido de vendas. Todo o Pedido de vendas deve ser excluido. 
						SC5->(RecLock("SC5"),.F.)	
						lMsErroAuto := .F.
						MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabcPVEx , _aItenPVEx , 5 ) // Exclui todo o pedido de vendas.
						SC5->(MSUnLock())
						_lExclParcial := .F.
					Else
						lMsErroAuto := .F.
						MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabcPVEx , _aItenPVEx , 4 ) // Exclui apenas o item/grupo do pedido de vendas.
						_lExclParcial := .T.
					EndIf

					//Recarrega parâmetros
					EVAL(_bPergunte)
			  	Else
			   		
					//========================================================
					// Realiza a exclusão de todo o pedido de vendas
					//========================================================
					SC5->(RecLock("SC5"),.F.)
					lMsErroAuto := .F.
					MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabcPVEx , _aItenPVEx , 5 )
					SC5->(MSUnLock())
					_lExclParcial := .F.
					//Recarrega parâmetros
					EVAL(_bPergunte)

			   	EndIf
				
            EndIf
            

			SC5->( MSUnLock() )
			_cmotivs := _clocmot
			
			//Se cliente foi desbloqueado para ajustes dos pedidos volta a bloquear
			SA1->(DBSetOrder(1))
			If _lbloqcli .And. SA1->(DBSeek(xFilial("SA1")+_ccliente+_clojacli)) 
			
				RecLock("SA1",.F.)
				SA1->A1_MSBLQL := "1"
				SA1->A1_I_ACRED := _cobs 
				SA1->(MSUnLock())
				
			EndIf
			
			If lMsErroAuto .Or. !_lOK_RDC
               If !u_IT_TMS(SC5->C5_I_LOCEM)  //! _lWsTms
			      _cTextoMsg := "Erro ao excluir no RDC."
               Else
                  _cTextoMsg := "Erro ao excluir no TMS Multi-Embarcador."
			   EndIf 

               aAdd(_alista,{_cNumPed, IIf(_lOK_RDC,"Erro ao excluir no Protheus: " + _cAOMS074Vld + CRLF + "["+MostraErro("\data\Italac\AOMS108\","AOMS108_MostraErro_"+AllTrim(QRYCABEC->C5_NUM)+".LOG")+"]",_cTextoMsg)})

			Else
				
				_ctitulo := " (EXCLUSAO COMPLETA)"

				If !Empty(_MVPAR15)
		
					_ctitulo := " (SOMENTE PRODUTO " + AllTrim(_MVPAR15) + ")"
			
				EndIf

				If !Empty(_MVPAR16)
		
					_ctitulo := " (SOMENTE GRUPO " + AllTrim(_MVPAR16) + ")"
			
				EndIf

				If !Empty(_MVPAR17)
		
					_ctitulo := " (SOMENTE SUBGRUPO " + AllTrim(_MVPAR17) + ")"
			
				EndIf
				

				aAdd(_alista,{_cNumPed, "Excluido com sucesso " + _ctitulo})

                If _lExclParcial
                   _cMsg      := "Monitor exclusão parcial do pedido de vendas, " + _ctitulo
                   _cCodOper  := "007"
                   _dDataOper := Date()
                   _cEncer    := "N"
                Else
                   _cMsg      := "Monitor encerrado por exclusao do pedido de vendas."
                   _cCodOper  := "010"
                   _dDataOper := Date()
                   _cEncer    := "S"
                EndIf
                  
                U_GrvMonitor(_cFilPed,_cNumPed,_cCodOper,_cMsg  ,_cEncer  ,_dDataOper,_dDataOper,_dDataOper) 
                
				//================================================================================
				//Encerra tabela de muro do RDC do pedido excluido
				//================================================================================
				ZFQ->(DBSetOrder(3))
				ZFQ->(DBGoTop())
				
				If ZFQ->(DBSeek(xFilial("SC5")+_cNumPed))
		
					While ZFQ->ZFQ_FILIAL == xFilial("SC5") .And. ZFQ->ZFQ_PEDIDO == _cNumPed
			
						If ZFQ->ZFQ_SITUAC == 'N'
						
							RecLock("ZFQ",.F.)
							ZFQ->ZFQ_SITUAC := 'P'
							ZFQ->(MSUnLock())
							
						EndIf
				
						ZFQ->(DBSkip())
				
					EndDo
			
				EndIf
		
				ZFR->(DBSetOrder(3))
				ZFR->(DBGoTop())
				
				If ZFR->(DBSeek(xFilial("SC5")+_cNumPed))
		
					While ZFR->ZFR_FILIAL == xFilial("SC5") .And. ZFR->ZFR_NUMPED == _cNumPed
			
						If ZFR->ZFR_SITUAC == 'N'
						
							RecLock("ZFR",.F.)
							ZFR->(DBDelete())
							ZFR->(MSUnLock())
							
						EndIf
				
						ZFR->(DBSkip())
				
					EndDo
			
				EndIf
				
			EndIf
		
		Else
			
			//Registra problema com pedido
			If !SC5->( DBSeek( xFilial("SC5") + _cNumPed ) )
			
				aAdd(_alista,{_cNumPed, "Pedido foi excluido antes do processamento"})
			
			ElseIf !Empty(SC5->C5_LIBEROK) 
			
				aAdd(_alista,{_cNumPed, "Pedido foi liberado antes do processamento"})
			
			ElseIf !Empty(SC5->C5_NOTA) 
			
				aAdd(_alista,{_cNumPed, "Pedido foi faturado antes do processamento"})
			
			ElseIf !Empty(SC5->C5_BLQ)
			
				aAdd(_alista,{_cNumPed, "Pedido foi bloqueado antes do processamento"})
			
			EndIf
			 
		EndIf
		
		_cpedvinc := SC5->C5_I_PEVIN
		
		If ! Empty(_cPedRemessa)
           //============================================================================
           // Realiza a Exclusão do Pedido de Remessa vinculado ao pedido de vendas
           // excluido, da operação triangular.		
		   //============================================================================      
		   If !lMsErroAuto .And. _lOK_RDC
              AOMS108R(_cFilRem, _cPedRemessa,1)
		   EndIf
		EndIf
				
		FWRestArea(_aAreaCabec)
		
	    QRYCABEC->( DBSkip() )
	    
	EndDo

	End Transaction

	If Len(_alista) > 0

		_ctitulo := "Pedidos excluidos (EXCLUSAO COMPLETA)"
		
		If !Empty(_MVPAR15)
		
			_ctitulo := "Pedidos excluidos (SOMENTE PRODUTO " + AllTrim(_MVPAR15) + ")"
			
		EndIf
		
		If !Empty(_MVPAR16)
		
			_ctitulo := "Pedidos excluidos (SOMENTE GRUPO " + AllTrim(_MVPAR16) + ")"
			
		EndIf

		If !Empty(_MVPAR17)
		
			_ctitulo := "Pedidos excluidos (SOMENTE SUBGRUPO " + AllTrim(_MVPAR17) + ")"
			
		EndIf
		

		U_ITListBox( _ctitulo , {"Numero","Situacao"} , _alista , .T. , 1 )
			
	EndIf
	
	_alista := {}
	
	QRYCABEC->( DBCloseArea() )
	
Else

	//================================================================================
	// Fecha a area de uso do arquivo temporario no Protheus.
	//================================================================================
	TRBF->( DBCloseArea() )
	
EndIf

FWRestArea( _aArea )

Return

/*
===============================================================================================================================
Programa----------: AOMS108PSQ
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/04/2018
Descrição---------: Funcao para pesquisa no arquivo temporario.
Parametros--------: oMark  - Objeto de dados
------------------: cAlias - Alias temporário
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS108PSQ( oMark , cAlias )

Local oGet1		:= Nil
Local oDlg		:= Nil
Local cGet1		:= Space(40)
Local cComboBx1	:= ""
Local aComboBx1	:= { "Pedido" , "Cliente+Loja" , "Descricao Cliente" , "Descricao Rede" }
Local nOpca		:= 0
Local nI		:= 0

DEFINE MSDIALOG oDlg TITLE "Pesquisar" FROM 178,181 To 259,697 PIXEL

	@004,003 ComboBox	cComboBx1	Items aComboBx1 Size 213,010 OF oDlg PIXEL
	@020,003 MsGet		oGet1		Var cGet1		Size 212,009 OF oDlg PIXEL COLOR CLR_BLACK Picture "@!"
	
	DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( nOpca := 1 , oDlg:End() ) OF oDlg
	DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( nOpca := 0 , oDlg:End() ) OF oDlg

ACTIVATE MSDIALOG oDlg CENTERED

If nOpca == 1

	For nI := 1 To Len(aComboBx1)
	
		If cComboBx1 == aComboBx1[nI]
		
			DBSelectArea("TRBF")
			TRBF->( DBSetOrder(nI) )
			
			MsSeek( cGet1 , .T. )
			
			oMark:oBrowse:Refresh( .T. )
			
		EndIf
		
	Next nI
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS108INV
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/04/2018
Descrição---------: Rotina para inverter a marcacao do registro posicionado.
Parametros--------: oMark  - Objeto de dados
------------------: cAlias - Alias temporário
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS108INV( cMarca , lInverte , oQtda )

Local lMarcado := IsMark( "TRBF_OK" , cMarca , lInverte )

If lMarcado
	nQtdTit++
Else
	nQtdTit--
EndIf

oQtda:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS108ALL
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/04/2018
Descrição---------: Rotina para inverter a marcacao de todos os registros.
Parametros--------: oMark  - Objeto de dados
------------------: cAlias - Alias temporário
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS108ALL( cMarca , oQtda )

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
		
		nQtdTit--
		
	Else
	
		TRBF->( RecLock( "TRBF" , .F. ) )
		TRBF->TRBF_OK := cMarca
		TRBF->( MSUnLock() )
		
		nQtdTit++
		
	EndIf
	
	nQtdTit := IIf( nQtdTit < 0 , 0 , nQtdTit )
	
	TRBF->( DBSkip() )
EndDo

TRBF->( DBGoTo(nReg) )

oQtda:Refresh()
oMark:oBrowse:Refresh(.T.)

Return

/*
===============================================================================================================================
Programa----------: AOMS108ARQ
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/04/2018
Descrição---------: Rotina para criação do arquivo temporário
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS108ARQ()

Local aEstru		:= {}
Local cFiltro		:= "%" 

Local _nNumReg		:= 0

//================================================================================
// Armazena no array aEstru a estrutura dos campos da tabela.
//================================================================================
aAdd( aEstru , { "TRBF_OK"		, 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBF_FILIA"	, 'C' , 02 , 0 } )    
aAdd( aEstru , { "TRBF_NUM"		, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBF_OPER"    , 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBF_DTEMI"	, 'D' , 08 , 0 } )
aAdd( aEstru , { "TRBF_DTENT"	, 'D' , 08 , 0 } )
aAdd( aEstru , { "TRBF_CODCL"	, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBF_LOJCL"	, 'C' , 04 , 0 } )
aAdd( aEstru , { "TRBF_DESCL"	, 'C' , 30 , 0 } )
aAdd( aEstru , { "TRBF_CODRE"	, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBF_DESCR"	, 'C' , 20 , 0 } )
aAdd( aEstru , { "TRBF_CODVE"	, 'C' , 06 , 0 } )
aAdd( aEstru , { "TRBF_DESVE"	, 'C' , 25 , 0 } )
aAdd( aEstru , { "TRBF_UF"   	, 'C' , 02 , 0 } )
aAdd( aEstru , { "TRBF_VALOR"	, 'N' , 14 , 2 } )
aAdd( aEstru , { "TRBF_FILCR"	, 'C' , 02 , 0 } ) 
aAdd( aEstru , { "TRBF_FILFT"	, 'C' , 02 , 0 } ) 
aAdd( aEstru , { "TRBF_AGEND"	, 'C' , 01 , 0 } )
aAdd( aEstru , { "C5_I_PEVIN"	, 'C' , Len(SC5->C5_I_PEVIN),0}) 
aAdd( aEstru , { "C5_I_ENVRD"	, 'C' , Len(SC5->C5_I_ENVRD),0}) 

//================================================================================
// Armazena no array aCampos o nome, picture e descricao dos campos
//================================================================================
aAdd( aCampos , { "TRBF_OK"		, "" , " "					, " "										} )
aAdd( aCampos , { "TRBF_FILIA"	, "" , "Filial"				, PesqPict( "SC5" , "C5_FILIAL"	 )			} )    
aAdd( aCampos , { "TRBF_NUM"	, "" , "Pedido"				, PesqPict( "SC5" , "C5_NUM"	 )	 		} )
aAdd( aCampos , { "C5_I_PEVIN"	, "" , "PV Vinculado"       , "@!"	} )
aAdd( aCampos , { "TRBF_OPER"	, "" , "Operação"			, PesqPict( "SC5" , "C5_I_OPER"	 )	 		} )
aAdd( aCampos , { "TRBF_DTEMI"	, "" , "Data Emissao"		, PesqPict( "SC5" , "C5_EMISSAO" )	  		} )
aAdd( aCampos , { "TRBF_DTENT"	, "" , "Data Entrega"		, PesqPict( "SC5" , "C5_I_DTENT" )	  		} )
aAdd( aCampos , { "TRBF_CODCL"	, "" , "Cliente"			, PesqPict( "SC5" , "C5_CLIENTE" )	  		} )
aAdd( aCampos , { "TRBF_LOJCL"	, "" , "Loja"				, PesqPict( "SC5" , "C5_LOJACLI" )	  		} )
aAdd( aCampos , { "TRBF_DESCL"	, "" , "Descricao Cliente"	, PesqPict( "SC5" , "C5_I_NOME"  )	  		} )
aAdd( aCampos , { "TRBF_CODRE"	, "" , "Rede"				, PesqPict( "SC5" , "C5_I_GRPVE" )	  		} )
aAdd( aCampos , { "TRBF_DESCR"	, "" , "Descricao Rede"		, PesqPict( "SC5" , "C5_I_NOMRD" )	  		} ) 
aAdd( aCampos , { "TRBF_UF"	    , "" , "UF"					, PesqPict( "SA1" , "A1_EST"     )	  		} )
aAdd( aCampos , { "TRBF_CODVE"	, "" , "Vendedor"			, PesqPict( "SC5" , "C5_VEND1"   )	  		} )
aAdd( aCampos , { "TRBF_DESVE"	, "" , "Descricao Vendedor"	, PesqPict( "SC5" , "C5_I_V1NOM" )	  		} )
aAdd( aCampos , { "TRBF_FILCR"	, "" , "Filial Carregamento", "@!"	} )
aAdd( aCampos , { "TRBF_FILFT"	, "" , "Filial Faturamento" , "@!"	} )
aAdd( aCampos , { "TRBF_AGEND"	, "" , "Tipo de Entrega"    , "@!"	} ) 
aAdd( aCampos , { {||If(TRBF->C5_I_ENVRD="S","Sim","Não")},"","Envio RDC?",""} )

//================================================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//================================================================================
If Select("TRBF") > 0
	TRBF->( DBCloseArea() )
EndIf

//================================================================================
// Abre o arquivo TRBZFQ criado dentro do protheus.
//================================================================================
_otemp := FWTemporaryTable():New( "TRBF",  aEstru )
   
//================================================================================
// Cria os indices para o arquivo.
//================================================================================
_otemp:AddIndex( "01", {'TRBF_NUM'} )
_otemp:Create()   
   
DBSelectArea("TRBF")

//================================================================================
// Filtra Filiais
//================================================================================
If !Empty( xFilial("SC5") )
	cFiltro += " AND C5.C5_FILIAL	= '"+ xFilial("SC5") +"' "
EndIf

If !Empty( xFilial("SA1") )
	cFiltro += " AND A1.A1_FILIAL	= '"+ xFilial("SA1") +"' "
EndIf

If !Empty( xFilial("SA3") )
	cFiltro += " AND SA3.A3_FILIAL	= '"+ xFilial("SA3") +"' "
EndIf

//================================================================================
// Emissao de - Ate
//================================================================================
If !Empty( MV_PAR01 ) .And. !Empty( MV_PAR02 )
		cFiltro += " AND C5.C5_EMISSAO	BETWEEN '"+ DToS(MV_PAR01)	+"' AND '"+ DToS(MV_PAR02)	+"' "
EndIf
	
//================================================================================
// Data Entrega De - Ate
//================================================================================
If !Empty( MV_PAR03 ) .And. !Empty( MV_PAR04 )
	cFiltro += " AND C5.C5_I_DTENT	BETWEEN '"+ DToS(MV_PAR03)	+"' AND '"+ DToS(MV_PAR04)	+"' "
EndIf
	
//================================================================================
// Cliente De - Ate
//================================================================================
If !Empty( MV_PAR05 ) .And. !Empty( MV_PAR07 )
	cFiltro += " AND C5.C5_CLIENTE	BETWEEN '"+ MV_PAR05		+"' AND '"+ MV_PAR07		+"' "
EndIf

//================================================================================
// Loja De - Ate
//================================================================================
If !Empty( MV_PAR06 ) .And. !Empty( MV_PAR08 )
	cFiltro += " AND C5.C5_LOJACLI	BETWEEN '"+ MV_PAR06		+"' AND '"+ MV_PAR08		+"' "
EndIf

//================================================================================
// Rede
//================================================================================
If !Empty( MV_PAR09 )                                                   
	If Len(AllTrim(MV_PAR09)) <= 6
		cFiltro += " AND C5.C5_I_GRPVE	= '" + AllTrim(MV_PAR09) + "' "
	Else
		cFiltro += " AND C5.C5_I_GRPVE	IN " + FormatIn( MV_PAR09 , ";" )
	EndIf
EndIf

//================================================================================
// Estado
//================================================================================
If !Empty( MV_PAR10 )     
	If Len(AllTrim(MV_PAR10)) <= 2
		cFiltro  += " AND A1.A1_EST = '"+ AllTrim(MV_PAR10) + "' "
	Else
		cFiltro  += " AND A1.A1_EST IN "+ FormatIn( MV_PAR10 , ";" )
	EndIf
EndIf

//================================================================================
// Municipio
//================================================================================
If !Empty( MV_PAR11 )             
	If Len(AllTrim(MV_PAR11)) <= 6
		cFiltro  += " AND A1.A1_COD_MUN = '"+ AllTrim(MV_PAR11) + "' "
	Else
		cFiltro  += " AND A1.A1_COD_MUN	IN "+ FormatIn( MV_PAR11 , ";" )
	EndIf
EndIf

//================================================================================
// Filtra Supervisor
//================================================================================
If !Empty( MV_PAR12 )             
	If Len(AllTrim(MV_PAR12)) <= 6
		cFiltro += " AND A3.A3_SUPER = '"+ AllTrim(MV_PAR12) + "' "
	Else
		cFiltro += " AND A3.A3_SUPER IN "+ FormatIn( MV_PAR12 , ";" )
	EndIf
EndIf

//================================================================================
// Filtra Vendedor
//================================================================================
If !Empty( MV_PAR13 )      
	If Len(AllTrim(MV_PAR13)) <= 6
		cFiltro += " AND A3.A3_COD = '"+ AllTrim(MV_PAR13) + "' "
	Else
		cFiltro += " AND A3.A3_COD IN "+ FormatIn( MV_PAR13 , ";" )
	EndIf
EndIf

//================================================================================
// Filtra Produto
//================================================================================
If !Empty( MV_PAR14 )

	cFiltro += " AND EXISTS (SELECT 'Y' FROM " +RetSqlName("SC6")+ " C6 "
	cFiltro += " WHERE C6.D_E_L_E_T_ = ' ' AND C6.C6_FILIAL = C5.C5_FILIAL AND C6.C6_NUM = C5.C5_NUM "
	cFiltro += " AND C6.C6_PRODUTO	IN "+ FormatIn( MV_PAR14 , ";" ) + " )" 	
	
EndIf

//================================================================================
// Filtra Produto a Excluir do Pedido de Vendas
//================================================================================
If !Empty( MV_PAR15 )

	cFiltro += " AND EXISTS (SELECT 'Y' FROM " +RetSqlName("SC6")+ " C62 "
	cFiltro += " WHERE C62.D_E_L_E_T_ = ' ' AND C62.C6_FILIAL = C5.C5_FILIAL AND C62.C6_NUM = C5.C5_NUM "
	cFiltro += " AND C62.C6_PRODUTO	= '"+ MV_PAR15 + "') "         
		
EndIf

//================================================================================
// Filtra Grupo a Excluir do Pedido de Vendas
//================================================================================
If !Empty( MV_PAR16 )

	cFiltro += " AND EXISTS (SELECT 'Y' FROM " +RetSqlName("SC6")+ " C62 "
	cFiltro += " WHERE C62.D_E_L_E_T_ = ' ' AND C62.C6_FILIAL = C5.C5_FILIAL AND C62.C6_NUM = C5.C5_NUM "
	cFiltro += " AND (SELECT B1_GRUPO FROM " +RetSqlName("SB1")+ " B12 WHERE B12.D_E_L_E_T_ = ' ' AND B12.B1_COD = C62.C6_PRODUTO)	= '"+ MV_PAR16 + "') "         
		
EndIf

//================================================================================
// Filtra SubGrupo a Excluir do Pedido de Vendas
//================================================================================
If !Empty( MV_PAR17 )

	cFiltro += " AND EXISTS (SELECT 'Y' FROM " +RetSqlName("SC6")+ " C62 "
	cFiltro += " WHERE C62.D_E_L_E_T_ = ' ' AND C62.C6_FILIAL = C5.C5_FILIAL AND C62.C6_NUM = C5.C5_NUM "
	cFiltro += " AND (SELECT B1_I_SUBGR FROM " +RetSqlName("SB1")+ " B12 WHERE B12.D_E_L_E_T_ = ' ' AND B12.B1_COD = C62.C6_PRODUTO)	= '"+ MV_PAR17 + "') "         
		
EndIf


//================================================================================
// Filtra Gerente
//================================================================================
If !Empty( MV_PAR18 )
	cFiltro += " AND C5.C5_VEND3 IN "+ FormatIn( MV_PAR18 , ";" )
EndIf


If  MV_PAR19 > 0 .Or. MV_PAR20 > 0

	cFiltro += " AND EXISTS (SELECT 'Y' FROM " +RetSqlName("SC6")+ " C63 "
	cFiltro += " WHERE C63.D_E_L_E_T_ = ' ' AND C63.C6_FILIAL = C5.C5_FILIAL AND C63.C6_NUM = C5.C5_NUM "
	cFiltro += " AND (C63.C6_PRCVEN - (C63.C6_PRCVEN * C63.C6_I_PDESC)/100) BETWEEN "+ Str(MV_PAR19,15,2) + " AND "+ Str(MV_PAR20,15,2) + ") "   

EndIf


If  MV_PAR21 > 0 .Or. MV_PAR22 > 0

	cFiltro += " AND C5.C5_I_PESBR BETWEEN "+ Str(MV_PAR21,15,3) + " AND "+ Str(MV_PAR22,15,3) 

EndIf

If !Empty( MV_PAR23 )

	cFiltro += " AND C5.C5_I_AGEND IN "+ FormatIn( MV_PAR23 , ";" )

EndIf

//================================================================================
// Filtra Pedidos de Remessa da Operação Triangular.
//================================================================================
//cFiltro += " AND C5.C5_I_OPTRI <> 'R' "  // Removendo este filtro para permitir exibir e selecionar pedidos de remessa.

//================================================================================
// Filtra Pedidos de Vendas Normais. Apenas os Pedidos de Tipo Normal podem ser
// excluidos.
//================================================================================
cFiltro += " AND C5.C5_TIPO = 'N' "

cFiltro += " %"

//================================================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//================================================================================
If Select("QRYPED") > 0
	QRYPED->( DBCloseArea() )
EndIf

//================================================================================
// Query para selecao dos dados DOS PEDIDOS
//================================================================================
BeginSql alias "QRYPED"

	SELECT		C5.C5_FILIAL	, C5.C5_NUM		, C5.C5_CLIENTE	, C5.C5_LOJACLI		, A1.A1_NOME	,
				C5.C5_I_GRPVE	, C5.C5_I_NOMRD	, C5.C5_VEND1	, A3.A3_NOME		, C5.C5_EMISSAO	,
				C5.C5_I_PEDGE	, C5.C5_I_NPALE	, A1.A1_EMAIL	, C5_I_PVREM        , C5_I_BLOG,
				C5.C5_I_FILFT	, C5.C5_I_FLFNC , C5_I_AGEND    , C5_I_PEVIN        , C5_I_ENVRD,
				C5_I_TRCNF      , C5_I_PDFT     , C5_I_OPER     , A1_EST            , C5_I_DTENT
	
	FROM		%Table:SC5% C5
	
	JOIN		%Table:SA1% A1  ON C5.C5_CLIENTE = A1.A1_COD    AND C5.C5_LOJACLI = A1.A1_LOJA
	JOIN		%Table:SA3% A3  ON C5.C5_VEND1   = A3.A3_COD
	
	WHERE			C5.D_E_L_E_T_ = ' '
				AND A1.D_E_L_E_T_ = ' '
				AND A3.D_E_L_E_T_ = ' ' 
				AND C5.C5_LIBEROK = ' ' 
				AND C5.C5_NOTA    = ' '
				AND C5.C5_BLQ     = ' '
				%exp:cFiltro%
	
	ORDER BY	C5_FILIAL,C5_NUM
	
EndSql

DBSelectArea("QRYPED")
QRYPED->( DBGoTop() )

//================================================================================
// 1 - Indica que nao foram encontrados dados
// 0 - Indica que foram encontrados dados
//================================================================================
_nRet := 1
_cUserAux:=RetCodUsr()

While QRYPED->(!Eof())
    _nRet := 0
    
 	//================================================================================
    // Filtra pedidos em planejamento logístico
    //================================================================================ 
	ZZL->(DBSetOrder(3))
	If !(ZZL->(DBSeek(xFilial("ZZL") + _cUserAux))) .Or. ZZL->ZZL_PVLOG != "S"	

		If QRYPED->C5_I_BLOG = 'S' 
   			aAdd(_alista,{QRYPED->C5_NUM, "Pedido em planejamento logístico. Não pode ser excluido."})
	    	QRYPED->( DBSkip() )
	    	Loop
		EndIf

	EndIf

   	//================================================================================
    // Filtra pedidos troca nota que não podem ser excluidos.
    //================================================================================ 
	If QRYPED->C5_I_TRCNF = 'S' 
	   If (QRYPED->C5_FILIAL == QRYPED->C5_I_FLFNC .And. ! Empty(QRYPED->C5_I_PDFT))
	      aAdd(_alista,{QRYPED->C5_NUM, "Este é um pedido de vendas troca nota e já possui um pedido de faturamento. Não pode ser excluido."})
	      QRYPED->( DBSkip() )
	      Loop
	   ElseIf (QRYPED->C5_FILIAL <> QRYPED->C5_I_FLFNC)
	      aAdd(_alista,{QRYPED->C5_NUM, "Este não é um pedido de vendas troca nota da filial de origem. Não pode ser excluido."})
	      QRYPED->( DBSkip() )
	      Loop
	   EndIf
	EndIf
    
   	//================================================================================
    // Filtra pedidos de operação triangular que não podem ser excluidos
    //================================================================================ 
    If AllTrim(QRYPED->C5_I_OPER) == '05' .And. !Empty(QRYPED->C5_I_PVREM)
    
    	SC5->(DBSetOrder(1))
    	If SC5->(DBSeek(QRYPED->C5_FILIAL+QRYPED->C5_I_PVREM)) .And. SC5->C5_LIBEROK = 'S'
    	  
    	  aAdd(_alista,{QRYPED->C5_NUM, "Pedido de vendas atrelado a operação triangular com estoque já liberado."})
	      QRYPED->( DBSkip() )
	      Loop
	   
	   EndIf
 	
	EndIf
		
	//================================================================================
	// Armazena o numero de registros encontrados.
	//================================================================================
	_nNumReg++
			
	DBSelectArea("TRBF")					
	TRBF->( dbappend() )
			
			TRBF->TRBF_FILIA	:= QRYPED->C5_FILIAL
			TRBF->TRBF_NUM		:= QRYPED->C5_NUM
	        TRBF->TRBF_OPER     := QRYPED->C5_I_OPER 
			TRBF->TRBF_DTEMI	:= SToD(QRYPED->C5_EMISSAO)
			TRBF->TRBF_DTENT	:= SToD(QRYPED->C5_I_DTENT)
			TRBF->TRBF_CODCL	:= QRYPED->C5_CLIENTE
			TRBF->TRBF_LOJCL	:= QRYPED->C5_LOJACLI
			TRBF->TRBF_DESCL	:= QRYPED->A1_NOME
			TRBF->TRBF_UF   	:= QRYPED->A1_EST
			TRBF->TRBF_CODRE	:= QRYPED->C5_I_GRPVE
			TRBF->TRBF_DESCR	:= QRYPED->C5_I_NOMRD
			TRBF->TRBF_CODVE	:= QRYPED->C5_VEND1
			TRBF->TRBF_DESVE	:= QRYPED->A3_NOME
			TRBF->TRBF_FILCR    := QRYPED->C5_I_FLFNC 
			TRBF->TRBF_FILFT 	:= QRYPED->C5_I_FILFT  
			TRBF->TRBF_AGEND 	:= QRYPED->C5_I_AGEND 
			TRBF->C5_I_PEVIN 	:= QRYPED->C5_I_PEVIN 
			TRBF->C5_I_ENVRD 	:= QRYPED->C5_I_ENVRD
	
	QRYPED->( DBSkip() )
	
EndDo

QRYPED->( DBCloseArea())
If _nNumReg == 0
	_nRet := 1
EndIf	

Return( _nRet )

/*
===============================================================================================================================
Programa----------: AOMS108PPV
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/04/2018
Descrição---------: Função para Pesquisar Pedidos de Vendas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS108PPV()   
                              
DBSelectArea("SC5")
SC5->( DBSetOrder(1) )
If SC5->( DBSeek( TRBF->( TRBF_FILIA + TRBF_NUM ) ) )
	MatA410(Nil, Nil, Nil, Nil, "A410Visual") 
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS108VLD
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/04/2018
Descrição---------: Verifica a seleção dos pedidos 
Parametros--------: nQtdTit   - Quantidade de Títulos Selecionados
Retorno-----------: _lRet     - Define se os dados foram validados com sucesso
===============================================================================================================================
*/
Static Function AOMS108VLD( nQtdTit )

Local _lRet		:= .T.

//================================================================================
// Verifica se o usurio selecionou pedidos de vendas e informou a filial
//================================================================================
If nQtdTit == 0 

	U_ITMsg("Para executar a rotina de exclusao multipla de Pedidos de venda deve-se "+;
			"primeiramente selecionar pelo menos um pedido de venda ."		,;
			"Atenção"																	,;
			"Favor informar os dados citados acima para executar a rotina de exclusao.",1)
	
	_lRet := .F.
	
EndIf


Return( _lRet )

/*
===============================================================================================================================
Programa----------: AOMS108R
Autor-------------: Julio de Paula Paz
Data da Criacao---: 03/05/2018
Descrição---------: Exclusão dos pedidos de remessa da operação triangular e pedido vinculado.
Parametros--------: _cFilRem = Filial do Pedido de Remessa.
                    _cNumPedRem = Numero do Pedido de Remessa.
                    _ntipo - 1 pedido de remessa, 2 pedido vinculado
Retorno-----------: _lRet = .T. = Exclusão realizada com sucesso.
                            .F. = Falha na exclusão do pedido de remessa.
===============================================================================================================================
*/
Static Function AOMS108R(_cFilRem, _cNumPedRem,_ntipo)

Local _lRet	:= .T.
Local _aCabecPV
Local _aItensPV
Local _aCabcPVEx
Local _aItenPVEx
Local _lblqprc
Local _aArea := FWGetArea()
Local _lExclParcial
Local _cMsg, _cCodOper, _dDataOper, _cEncer
Local _ctpped := IIf(_ntipo==1,"remessa","vinculado")

Private lAutoErrNoFile := .T.  
Private _cAOMS074Vld   := " "  

Begin Sequence
   SC5->( DBSetOrder(1) )
   If !	SC5->( DBSeek( _cFilRem + _cNumPedRem) )
      aAdd(_aLista,{_cNumPedRem, "Pedido " + _ctpped + " não localizado."})
      _lRet := .F.
      Break
   EndIf

   //================================================================================
   // Zera Variaveis de controle
   //================================================================================
   _aCabecPV	:= {}
   _aItensPV	:= {}
   _aCabcPVEx	:= {}
   _aItenPVEx	:= {}
   _lblqprc    := .F.
		
   SC6->(DBSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
   SC6->(DBSeek(_cFilRem + _cNumPedRem))
		
   While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == _cFilRem + _cNumPedRem 
		If !Empty(MV_PAR15) .Or. !Empty(MV_PAR16) .Or. !Empty(MV_PAR17)
			//=============================================================================
			// Realiza a exclusão do item informado no parâmetro MV_PAR15/MV_PAR16 já filtrado 
			// na query.
			//=============================================================================
			If !Empty(MV_PAR15) .And. AllTrim(SC6->C6_PRODUTO) <> AllTrim(MV_PAR15)
				SC6->(DBSkip())
				Loop
			EndIf
			
			If !Empty(MV_PAR16) .And. AllTrim(Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_GRUPO")) <> AllTrim(MV_PAR16)
				SC6->(DBSkip())
				Loop
			EndIf

			If !Empty(MV_PAR17) .And. AllTrim(Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_I_SUBGR")) <> AllTrim(MV_PAR17)
				SC6->(DBSkip())
				Loop
			EndIf
			
			If MV_PAR19 > 0 .Or. MV_PAR20 > 0 .And. (SC6->C6_PRCVEN - (SC6->C6_PRCVEN * SC6->C6_I_PDESC)/100) >= MV_PAR19 .And. (SC6->C6_PRCVEN - (SC6->C6_PRCVEN * SC6->C6_I_PDESC)/100) <= MV_PAR20
				SC6->(DBSkip())
				Loop
			EndIf

			aAdd( _aItenPVEx , { { "LINPOS"     ,"C6_ITEM",SC6->C6_ITEM},; 
								{ "AUTDELETA"  ,"S"               ,Nil},; 
								{ "C6_FILIAL"  , SC6->C6_FILIAL	 ,Nil},; 
								{ "C6_ITEM"    , SC6->C6_ITEM	 ,Nil},;
								{ "C6_PRODUTO" , SC6->C6_PRODUTO	 ,Nil},;
								{ "C6_QTDVEN"  , SC6->C6_QTDVEN	 ,Nil},;
								{ "C6_UM"      , SC6->C6_UM		 ,Nil},;
								{ "C6_PRCVEN"  , SC6->C6_PRCVEN	 ,Nil},;
								{ "C6_VALOR"   , SC6->C6_VALOR	 ,Nil},;
								{ "C6_PEDCLI"  , SC6->C6_PEDCLI	 ,Nil},;
								{ "C6_QTDLIB"  , SC6->C6_QTDLIB	 ,Nil},;
								{ "C6_LOCAL"   , SC6->C6_LOCAL	 ,Nil},;
								{ "C6_NUM"     , SC6->C6_NUM		 ,Nil}})
		Else
			//=============================================================================
			// Realiza a exclusão de todos os itens do pedido de vendas.
			//=============================================================================
			aAdd( _aItenPVEx , {	{ "C6_FILIAL"  , SC6->C6_FILIAL	,Nil},; 
									{ "C6_ITEM"    , SC6->C6_ITEM	,Nil},;
									{ "C6_PRODUTO" , SC6->C6_PRODUTO,Nil},;
									{ "C6_QTDVEN"  , SC6->C6_QTDVEN	,Nil},;
									{ "C6_UM"      , SC6->C6_UM		,Nil},;
									{ "C6_PRCVEN"  , SC6->C6_PRCVEN	,Nil},;
									{ "C6_VALOR"   , SC6->C6_VALOR	,Nil},;
									{ "C6_PEDCLI"  , SC6->C6_PEDCLI	,Nil},;
									{ "C6_QTDLIB"  , SC6->C6_QTDLIB	,Nil},;
									{ "C6_LOCAL"   , SC6->C6_LOCAL	,Nil},;
									{ "C6_NUM"     , SC6->C6_NUM	,Nil}})
		EndIf
		
		SC6->( DBSkip() )
   EndDo
		
   //================================================================================
   // Prepara arrays de cabeçalhos dos pedidos
   //================================================================================
	_aCabcPVEx := {		{ "C5_FILIAL"  , SC5->C5_FILIAL   	  ,Nil},;
						{ "C5_NUM"     , SC5->C5_NUM       	  ,Nil},;
						{ "C5_TIPO"    , SC5->C5_TIPO    	  ,Nil},;
						{ "C5_CLIENTE" , SC5->C5_CLIENTE 	  ,Nil},;
						{ "C5_LOJACLI" , SC5->C5_LOJACLI 	  ,Nil},;
						{ "C5_CLIENT " , SC5->C5_CLIENT  	  ,Nil},; // Codigo do cliente
						{ "C5_LOJAENT" , SC5->C5_LOJAENT 	  ,Nil},; // Loja para entrada
						{ "C5_TIPOCLI" , SC5->C5_TIPOCLI 	  ,Nil},;
						{ "C5_CONDPAG" , SC5->C5_CONDPAG 	  ,Nil},;
						{ "C5_VEND1"   , SC5->C5_VEND1   	  ,Nil},;
						{ "C5_EMISSAO" , SC5->C5_EMISSAO      ,Nil},;
						{ "C5_TPFRETE" , SC5->C5_TPFRETE 	  ,Nil},;
						{ "C5_VOLUME1" , SC5->C5_VOLUME1 	  ,Nil},;
						{ "C5_ESPECI1" , SC5->C5_ESPECI1 	  ,Nil},;
						{ "C5_TPCARGA" , SC5->C5_TPCARGA 	  ,Nil},;
						{ "C5_I_AGEND" , SC5->C5_I_AGEND 	  ,Nil},;
						{ "C5_I_ENVRD" , "N"                  ,Nil},;
						{ "C5_I_IDPED" , SC5->C5_I_IDPED	  ,Nil} }
		
	//=======================================================================================================
	// Caso outro usuario exclua, libere, fature ou bloqueie o Pedido de Venda posteriormente ao usuario ter 
	// clicado no botao ok da exclusao
	//========================================================================================================
	If Empty(SC5->C5_LIBEROK) .And. Empty(SC5->C5_NOTA) .And. Empty(SC5->C5_BLQ)  
		//Para que a exclusao no siga auto seja executada em modo exclusivo e nao esteja locado por outro usuario o pedido de venda ocrrente
		SC5->(RecLock("SC5"),.F.)	
				
		_lOK_RDC := .T.
		If SC5->C5_I_ENVRD = "S"
		   If !u_IT_TMS(SC5->C5_I_LOCEM)  //! _lWsTms
			  FWMsgRun( ,{|P| _lOK_RDC:=U_AOMS094E(P)} , 'Aguarde!' , 'Enviando para o RDC o cancelamento do Pedido Remessa...') 
		   Else
              FWMsgRun( ,{|P| _lOK_RDC:=U_AOMS140E(P,.T.)} , 'Aguarde!' , 'Enviando para o TMS Multi-Embarcador o cancelamento do Pedido Remessa...') 
		   EndIf 
		EndIf
   					   
		_lExclParcial:= .T.
		_cAOMS074    := "AOMS108"  	 //Não mostra mensagens do mata410
		_cAOMS074Vld := " " //Zera para cada pedido
		
		If _lOK_RDC
			//Efetua a exclusao do Pedido de venda que foi efetuada a importacao para a filial de destino
			If !Empty(MV_PAR15) .Or. !Empty(MV_PAR16) .Or. !Empty(MV_PAR17)
				//=============================================================================
				// Realiza a exclusão do item informado no parâmetro MV_PAR15/MV_PAR16/MV_PAR17 já filtrado na
				// query.
				//=============================================================================
				If AOMS108N(SC5->C5_NUM) == 1 // Indica que só existe um item ou grupo no pedido de vendas. Todo o Pedido de vendas deve ser excluido. 
					lMsErroAuto := .F.
					MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabcPVEx , _aItenPVEx , 5 ) // Exclui todo o pedido de vendas.
					_lExclParcial := .F.
				Else
					lMsErroAuto := .F.
					MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabcPVEx , _aItenPVEx , 4 )  
					_lExclParcial := .T.
				EndIf
				//Recarrega parâmetros
				Pergunte( cPerg , .F. )
			Else
				//========================================================
				// Realiza a exclusão de todo o pedido de vendas
				//========================================================
				lMsErroAuto := .F.
				MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabcPVEx , _aItenPVEx , 5 )
				_lExclParcial := .F.
				//Recarrega parâmetros
				Pergunte( cPerg , .F. )
			EndIf
		EndIf
				
		SC5->( MSUnLock() )
				
		If lMsErroAuto .Or. !_lOK_RDC 
           
		   If !u_IT_TMS(SC5->C5_I_LOCEM)  //! _lWsTms
		      _cTextoMsg := "Erro ao excluir Pedido " + _ctpped + " no RDC!" 
           Else
              _cTextoMsg := "Erro ao excluir Pedido " + _ctpped + " no TMS Multi-Embarcador!"
		   EndIf  
		
			//aAdd(_alista,{_cNumPedRem, IIf(_lOK_RDC,"Erro ao excluir Pedido " + _ctpped + " no Protheus","Erro ao excluir Pedido " + _ctpped + " no RDC!")})
			aAdd(_alista,{_cNumPedRem, IIf(_lOK_RDC,"Erro ao excluir Pedido " + _ctpped + " no Protheus: " + _cAOMS074Vld + CRLF + "["+MostraErro("\data\Italac\AOMS108\","AOMS108_MostraErro_"+AllTrim(_ctpped)+".LOG")+"]",_cTextoMsg)})

		Else
		
			aAdd(_alista,{_cNumPedRem, "Pedido " + _ctpped + " Excluido com sucesso!"})
			
			If _lExclParcial
				_cMsg      := "Monitor exclusão parcial do pedido de vendas, " + IIf(Empty(MV_PAR16),IIf(Empty(MV_PAR17)," item: " + AllTrim(MV_PAR15)," subgrupo: " + AllTrim(MV_PAR17))," grupo: " + AllTrim(MV_PAR16))
				_cCodOper  := "007"
				_dDataOper := Date()
				_cEncer    := "N"
			Else
				_cMsg      := "Monitor encerrado por exclusao do pedido de vendas."
				_cCodOper  := "010"
				_dDataOper := Date()
				_cEncer    := "S"
			EndIf
					
			U_GrvMonitor(_cFilPed,_cNumPedRem,_cCodOper,_cMsg,_cEncer,_dDataOper,_dDataOper,_dDataOper) 
			//================================================================================
			// Encerra tabela de muro do RDC do pedido excluido
			ZFQ->(DBSetOrder(3))
			ZFQ->(DBGoTop())
				
			If ZFQ->(DBSeek(xFilial("SC5")+_cNumPedRem))
				While ZFQ->ZFQ_FILIAL == xFilial("SC5") .And. ZFQ->ZFQ_PEDIDO == _cNumPedRem
					If ZFQ->ZFQ_SITUAC == 'N'
					ZFQ->(RecLock("ZFQ",.F.))
					ZFQ->ZFQ_SITUAC := 'P'
					ZFQ->(MSUnLock())
					EndIf
					
					ZFQ->(DBSkip())
					
				EndDo
			EndIf
		
			ZFR->(DBSetOrder(3))
			ZFR->(DBGoTop())
					
			If ZFR->(DBSeek(xFilial("SC5")+_cNumPedRem))
				While ZFR->ZFR_FILIAL == xFilial("SC5") .And. ZFR->ZFR_NUMPED == _cNumPedRem
					If ZFR->ZFR_SITUAC == 'N'
					ZFR->(RecLock("ZFR",.F.))
					ZFR->(DBDelete())
					ZFR->(MSUnLock())
					EndIf
					ZFR->(DBSkip())
				EndDo
			EndIf
		EndIf
	Else
	   //Registra problema com pedido
	   If !SC5->( DBSeek( xFilial("SC5") + _cNumPedRem ) )
		  aAdd(_alista,{_cNumPedRem, "Pedido " + _ctpped + " foi excluido antes do processamento"})
	   ElseIf !Empty(SC5->C5_LIBEROK) 
		  aAdd(_alista,{_cNumPedRem, "Pedido " + _ctpped + " foi liberado antes do processamento"})
	   ElseIf !Empty(SC5->C5_NOTA) 
		  aAdd(_alista,{_cNumPedRem, "Pedido " + _ctpped + " foi faturado antes do processamento"})
	   ElseIf !Empty(SC5->C5_BLQ)
		  aAdd(_alista,{_cNumPedRem, "Pedido " + _ctpped + " foi bloqueado antes do processamento"})
	   EndIf
	EndIf

	FWRestArea(_aArea)

End Sequence

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AOMS108N
Autor-------------: Julio de Paula Paz
Data da Criacao---: 29/05/2018
Descrição---------: Retorna a quantidade de itens ou grupos do pedido de vendas.
Parametros--------: _cNumPed = Numero do pedido de vendas.
Retorno-----------: _nItens = Quantidade de itens do pedido de vendas
===============================================================================================================================
*/
Static Function AOMS108N(_cNumPed)

Local _aOrd := SaveOrd({"SC6"})
Local _nRegAtu := SC6->(Recno())
Local _nItens := 0
Local _agrupos := {}

Begin Sequence
   SC6->(DBSetOrder(1))
   SC6->(DBSeek(xFilial("SC6")+_cNumPed))
   While !SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == xFilial("SC6")+_cNumPed
 
   	  If !Empty(MV_PAR15)
      
   	  	_nItens += 1
   	  	
   	  Else
   	  
   	  	If aScan(_agrupos,Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_GRUPO")) == 0
   	  	
   	  		aAdd(_agrupos,SB1->B1_GRUPO)
   	  		_nItens +=1
   	  		
   	  	EndIf
   	  
   	  EndIf
      
      SC6->(DBSkip())
   EndDo
End Sequence

RestOrd(_aOrd)
SC6->(DBGoTo(_nRegAtu))

Return _nItens
