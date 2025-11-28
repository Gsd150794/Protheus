/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |13/11/2024| Chamado 46161. Novos tratamentos p/ os campos Dt de Entrega no Op.Log (Dt.Canhoto) e Dt.Entrega no 
			  |			 | Cliente (Dt.Canhoto) no Lançamento de CTE x Nfe, e listar os Cte da Nfe vinculadas a Nfe lançada.
Lucas Borges  |23/07/2025| Chamado 51340. Trocado e-mail padrão para sistema@italac.com.br
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWMVCDEF.ch"

/* 
===============================================================================================================================
Programa--------: AOMS054
Autor-----------: Fabiano Dias
Data da Criacao-: 10/08/2011
Descrição-------: Rotina desenvolvida para possibilitar a insercao e manutencao dos conhecimentos de frete
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AOMS054()

Local _oBrowse
Private aRotina	:= {}
Private _cOperLog := Space(6)
//Private _cNOperLog := ""
Private _lTelaCanh := .T.  

//==========================================
//Grava log de utilização da rotina
//==========================================
 
//Instaciamento
_oBrowse := FWMBrowse():New()

//tabela que será utilizada
_oBrowse:SetAlias( "ZZN" )

//Define legendas
_oBrowse:AddLegend( "U_AOMS054L() == 1" , "BR_VERMELHO"	, "Aberto" 			)
_oBrowse:AddLegend( "U_AOMS054L() == 2" , "BR_AZUL"		, "Fiscal" 			)
_oBrowse:AddLegend( "U_AOMS054L() == 3" , "BR_VERDE"	, "Pago Total"		)
_oBrowse:AddLegend( "U_AOMS054L() == 4" , "BR_LARANJA"	, "Pago Parcial" 	)

//Define menus
ADD OPTION aRotina Title 'Visualizar'	 Action 'VIEWDEF.AOMS054'	  OPERATION 2 ACCESS 0
ADD OPTION aRotina Title 'Incluir'		 Action 'VIEWDEF.AOMS054'	  OPERATION 3 ACCESS 0
ADD OPTION aRotina Title 'Alterar'		 Action 'VIEWDEF.AOMS054'	  OPERATION 4 ACCESS 0
ADD OPTION aRotina Title 'Excluir'		 Action 'VIEWDEF.AOMS054'	  OPERATION 5 ACCESS 0
ADD OPTION aRotina Title 'Legenda'		 Action 'U_AOMS054C()'		  OPERATION 6 ACCESS 0
ADD OPTION aRotina Title 'CTE Diferente' Action 'FWMsgRun(,{|O| U_AOMS54Lista(.T.,O) }, "Lendo CTEs diferentes...","Aguarde...")'  OPERATION 6 ACCESS 0

//Titulo
_oBrowse:SetDescription( "Relacionamento CTE x NF x Fatura de transporte" )

//ativa
_oBrowse:Activate()

Return


/*
===============================================================================================================================
Programa----------: AOMS054L
Autor-------------: Guilherme Diogo
Data da Criacao---: 07/12/2012
Descrição---------: Retorna valor para montagem da legenda referente ao Status do CTE
Parametros--------: Nenhum
Retorno-----------: _nRet - Retorna a configuração da legenda
===============================================================================================================================
*/

User Function AOMS054L()

Local _nRet      := 1
Local _cFilial   := ZZN->ZZN_FILIAL
Local _cTDoc     := ZZN->ZZN_CTRANS
Local _cTSerie   := ZZN->ZZN_SERCTR 
Local _cTrans    := ZZN->ZZN_FTRANS
Local _cLoja     := ZZN->ZZN_LOJAFT
Local _aArea     := FWGetArea()

DBSelectArea("SF1")
SF1->( DBSetOrder(1) )
SF1->( DBGoTop() )
If SF1->( DBSeek( _cFilial + _cTDoc + _cTSerie + _cTrans + _cLoja ) )
	
	DBSelectArea("SE2")
	SE2->( DBSetOrder( 6 ) )
	SE2->( DBGoTop() )
	If SE2->( DBSeek( _cFilial + _cTrans + _cLoja + _cTSerie + _cTDoc ) )
	    
	    If SE2->E2_SALDO == SE2->E2_VALOR
	    	_nRet := 2
		ElseIf SE2->E2_SALDO == 0
			_nRet := 3
		ElseIf SE2->E2_SALDO > 0 .And. SE2->E2_SALDO <> SE2->E2_VALOR
			_nRet := 4
		EndIf
		
	EndIf
	
EndIf

FWRestArea( _aArea )

Return( _nRet )

/*
===============================================================================================================================
Programa----------: AOMS054C
Autor-------------: Guilherme Diogo
Data da Criacao---: 07/12/2012
Descrição---------: Retorna a configuração para montagem e exibição da legenda
Parametros--------: Nenhum
Retorno-----------: _nRet - Retorna a configuração da legenda
===============================================================================================================================
*/

User Function AOMS054C()

Local aLegenda := {}

aAdd( aLegenda , { "BR_VERMELHO"	, "Aberto"			} )
aAdd( aLegenda , { "BR_AZUL"		, "Fiscal"			} )
aAdd( aLegenda , { "BR_VERDE"		, "Pago Total"		} )
aAdd( aLegenda , { "BR_LARANJA"		, "Pago Parcial"	} )

BrwLegenda( "Status CTE" , "Legenda" , aLegenda )

Return

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Alexandre Villar
Data da Criacao---: 13/08/2014
Descrição---------: Define o modelo de dados para a rotina de cadastro
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ModelDef()

//================================================================================
// Prepara a estrutura a ser usada no Modelo de Dados
//================================================================================
Local oStruCAB	:= FWFormStruct( 1 , 'ZZN' , { |cCampo| AOMS054K( cCampo , 1 ) } )
Local oStruITN	:= FWFormStruct( 1 , 'ZZN' , { |cCampo| AOMS054K( cCampo , 2 ) } )
Local oModel	:= Nil
Local _aGatAux	:= {}

oStruCAB:AddField( 'Vlr Total' , 'Valor Total do Frete' , 'ZZN_TOTAUX' , 'N' , 14 , 2 , NIL , NIL , NIL , .F. , NIL , NIL , NIL , .T. )

//================================================================================
// Criação dos gatilhos para o cabeçalho da rotina
//================================================================================
_aGatAux := FwStruTrigger( 'ZZN_FATURA'	, 'ZZN_FATURA'	, 'U_ITZERESQ( M->ZZN_FATURA , "ZZN_FATURA" , "ZZNMASTER" )'						, .F. )
oStruCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//================================================================================
// Criação dos gatilhos para o grid da rotina
//================================================================================
_aGatAux := FwStruTrigger( 'ZZN_NFISCA'	, 'ZZN_NFISCA'	, 'U_ITZERESQ( M->ZZN_NFISCA , "ZZN_NFISCA" , "ZZNDETAIL" )'			, .F. )
oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZZN_CTRANS'	, 'ZZN_CTRANS'	, 'U_ITZERESQ( M->ZZN_CTRANS , "ZZN_CTRANS" , "ZZNDETAIL" )'			, .F. )
oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZZN_NFISCA'	, 'ZZN_DESMUN'	, 'U_AOMS054U(M->ZZN_NFISCA,M->ZZN_SERIE,M->ZZN_FILNFV)'						, .F. )
oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZZN_SERIE'	, 'ZZN_DESMUN'	, 'U_AOMS054U(M->ZZN_NFISCA,M->ZZN_SERIE,M->ZZN_FILNFV)'						, .F. )
oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZZN_MTDINF'	, 'ZZN_DESMNF'	, 'Posicione("ZZO",1,xFilial("ZZO")+M->ZZN_MTDINF,"ZZO->ZZO_DESCRI")'	, .F. )
oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZZN_MTDIVF'	, 'ZZN_DESCMD'	, 'Posicione("ZZO",1,xFilial("ZZO")+M->ZZN_MTDIVF,"ZZO->ZZO_DESCRI")'	, .F. )
oStruITN:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//================================================================================
// Cria e configura o modelo de dados
//================================================================================
oModel := MPFormModel():New( 'AOMS054M' )

oModel:SetDescription( 'Modelo de Dados do Lançamento de Conhecimento de Transporte' )

oModel:AddFields(	"ZZNMASTER" , /*cOwner*/  , oStruCAB , /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCarga*/ )
oModel:AddGrid(		"ZZNDETAIL" , "ZZNMASTER" , oStruITN , /*bPreValidacao*/ , /*bPosValidacao*/ , /*bCarga*/ )
oModel:AddCalc( 	'ZZNCALC01' , 'ZZNMASTER' , 'ZZNDETAIL' , 'ZZN_VLRCTR' , 'ZZN_TOTAUX' , 'FORMULA' , {|| .T. } ,, 'Valor Total', {|| U_AOMS054Y() }  )

oModel:SetRelation( "ZZNDETAIL" , {	{ "ZZN_FILIAL" , 'xFilial("ZZN")'	} ,;
									{ "ZZN_FATURA" , "ZZN_FATURA"		} ,;
									{ "ZZN_FTRANS" , "ZZN_FTRANS"		} ,;
									{ "ZZN_LOJAFT" , "ZZN_LOJAFT"		} } , ZZN->( IndexKey( 1 ) ) )

oModel:GetModel( 'ZZNDETAIL' ):SetUniqueLine( { 'ZZN_ITEM' } )

oModel:GetModel( "ZZNMASTER" ):SetDescription( "Dados da Fatura"	)
oModel:GetModel( "ZZNDETAIL" ):SetDescription( "Itens da Fatura"	)

oModel:SetPrimaryKey( { 'ZZN_FILIAL' , 'ZZN_ITEM', 'ZZN_FATURA' , 'ZZN_FTRANS' , 'ZZN_LOJAFT'  } )

Return( oModel )

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Alexandre Villar
Data da Criacao---: 13/08/2014
Descrição---------: Define a View de dados para a rotina de cadastro
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ViewDef()

//================================================================================
// Prepara a estrutura do objeto da View
//================================================================================
Local oModel   	:= FWLoadModel( 'AOMS054' )
Local oCalc		:= FWCalcStruct( oModel:GetModel( 'ZZNCALC01') )
Local oStruCAB	:= FWFormStruct( 2 , 'ZZN' , { |cCampo| AOMS054K( cCampo , 1 ) } )
Local oStruITN	:= FWFormStruct( 2 , 'ZZN' , { |cCampo| AOMS054K( cCampo , 2 ) } )
Local oView		:= Nil

//================================================================================
// Instancia o Objeto da View
//================================================================================
oView := FWFormView():New()

//================================================================================
// Define o modelo de dados da view
//================================================================================
oView:SetModel( oModel )

//================================================================================
// Instancia os objetos da View com as estruturas de dados
//================================================================================
oView:AddField(	"VIEW_CAB"	, oStruCAB	, "ZZNMASTER"	)
oView:AddGrid(	"VIEW_ITN"	, oStruITN	, "ZZNDETAIL"	)
oView:AddField( 'VIEW_CAL'	, oCalc		, 'ZZNCALC01'	)

//================================================================================
// Cria os Box horizontais para a View
//================================================================================
oView:CreateHorizontalBox( 'BOX0101' , 25 )
oView:CreateHorizontalBox( 'BOX0102' , 62 )
oView:CreateHorizontalBox( 'BOX0103' , 13 )

//================================================================================
// Define as estruturas da View para cada Box
//================================================================================
oView:SetOwnerView( "VIEW_CAB" , "BOX0101" )
oView:SetOwnerView( "VIEW_ITN" , "BOX0102" )
oView:SetOwnerView( "VIEW_CAL" , "BOX0103" )

//Botão de posiciona linha
oView:AddUserButton("Reenvia Fatura"         ,"",{|oView| U_ROMS057(oView)},"1-Reenvia Fatura")
oView:AddUserButton('Lista CTEs Diferentes'  ,"",{|V|_V:=V,FWMsgRun(,{|O| U_AOMS54Lista(.T.,O,_V,.F.) }, "Lendo CTEs diferentes...","Aguarde...")},'')
oView:AddUserButton('Visualiza Canhoto da NF',"",{|V|_V:=V,FWMsgRun(,{|O| U_AOMS54Lista(.T.,O,_V,.T.) }, "Lendo Canhoto da Nota...","Aguarde...")},'')

//================================================================================
// Define campo incremental para o GRID
//================================================================================
oView:AddIncrementField( 'VIEW_ITN' , 'ZZN_ITEM' )

Return( oView )

/*
===============================================================================================================================
Programa----------: AOMS054K
Autor-------------: Alexandre Villar
Data da Criacao---: 04/06/2014
Descrição---------: Valida os Campos que serão exibidos no Browse
Parametros--------: Nenhum
Retorno-----------: lRet - Indica se o código foi validado ou seje já existe
===============================================================================================================================
*/
Static Function AOMS054K( _cCampo , _nLocal )

Local _lRet := AllTrim( _cCampo ) $ "ZZN_FILIAL,ZZN_CODIGO,ZZN_FTRANS,ZZN_LOJAFT,ZZN_DESCTR,ZZN_CGC,ZZN_FATURA,ZZN_FATFIN"

If _nLocal == 2
	_lRet := !_lRet
EndIf

Return( _lRet )


/*
===============================================================================================================================
Programa----------: AOMS054J
Autor-------------: Josué Danich Prestes
Data da Criacao---: 15/01/2017
Descrição---------: Retorna status da canhoto na tabela de muro da Estec
Parametros--------: _cfilial - filial da nota
					_cdoc - Número da nota
					_cserie - serie da nota
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS054J(_cfilial,_cdoc, _cserie)

Local _cstatus := "Nao recepcionado"   //,"Aguardando Conf","Aprovado","Reprovado"

If cfilant $ SuperGetMV("IT_FILESTC",.F.,"01;90")

	//Se é filial Estec sempre é canhoto da Estec
	_cstatus := "Aguardando Conf"
	
	ZGJ->(DBSetOrder(1))
	If ZGJ->(DBSeek(_cfilial+_cdoc+_cserie))

		_cstatus := AllTrim(ZGJ->ZGJ_STATUS)

	Else
	
		RecLock("ZGJ",.T.)
		ZGJ->ZGJ_FILIAL := _cfilial
		ZGJ->ZGJ_NOTA  := _cdoc
		ZGJ->ZGJ_SERIE := _cserie
		ZGJ->ZGJ_DTENT := SToD("")
		ZGJ->ZGJ_DATAI := Date()
		ZGJ->ZGJ_HORAI := Time()
		ZGJ->ZGJ_STATUS:= "Aguardando Conf"
		ZGJ->(MSUnLock())
		
	EndIf
	
EndIf 

Return _cstatus

/*
===============================================================================================================================
Programa----------: AOMS054G
Autor-------------: Alexandre Villar
Data da Criacao---: 24/09/2014
Descrição---------: Função que monta a tela de lançamento
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS054G()

Local _nOpc		 := 2
Local _cTipoNF	 := ''
Local _lRet      := .F.
Local _cfilori   := cfilant
Local _cFilCarreg:= ""
Local _cAprOperL := ""
Local _lGrvOperL := .F.  // Indica se houve alterações nas datas informadas pelo operador logístico.
Local _lGrvCanho := .F.  // Indica se houve alterações nas datas informados do canhoto.
Local _oModel	 := FWModelActive()
Local _dPrevEOL  := CTOD("") //F2_I_PENOL - Previsão de entrega no operador logístico 
Local _dPrevECL  := CTOD("") //F2_I_PENCL - Previsão de entrega no cliente
Local _dChegOL   := CTOD("") //F2_I_DCHOL - Data de chegada no operador logístico 
Local _dChegCL   := CTOD("") //F2_I_DCHCL - Data de chegada no cliente
Local _dEntrCL   := CTOD("") //F2_I_DENCL - Data de entrega no cliente
Private _dEntrOL  := CTOD("")//F2_I_DENOL - Data de entrega no operador logístico  EDI // NÃO pode MAIS ser editado.
Private _dEntOLCha:= CTOD("")//F2_I_DTOP  - Data em que o Transportador Entregou efetivamente a Carga no Operador Logístico // pode ser editado.
Private _lTrocaNF:= .F.
Private _lTriangu:= .F.
Private _lReplica:= .F.
Private _lTemOpl := .F.//ALTERA DENTRO DA FUNCAO SeMostraTela()
Private _leOpLog := .F.//ALTERA DENTRO DA FUNCAO SeMostraTela()
Private _lPalletRetorno := .F.

Begin Sequence 
   
   //==========================================================
   // A tela já foi chamada uma vez para digitação das datas.
   //==========================================================
   If ! _lTelaCanh 
      _lRet := .T.
      Break // SAIR SE NÃO TEM TELA
   EndIf 	
   
   //=========================================================================
   //Verifica se falta confirmar CANHOTO (F2_I_DTRC)  ENTREGA NO CLIENTE
   //OU data de OPERADOR LOGISTICO (F2_I_DENOL) ENTREGA NO OPERADOR
   //DECIDE SE MOSTRA A TELA OU NAO
   //=========================================================================
   If SeMostraTela()//_lMostraTela ***********************************************************************************************************************

	  //Verifica se nao tem nota de devolução formulário próprio vinculada

      _cQuery := " SELECT D1.R_E_C_N_O_  RECN , F1.R_E_C_N_O_  RECNF1 , F1.F1_FORMUL , F1.F1_DAUTNFE , F1.F1_HAUTNFE , F1.F1_USERLGI  "
	  _cQuery += " FROM "+ RetSqlName("SF1") + " F1 JOIN " + RetSqlName("SD1") + " D1 ON F1.F1_FILIAL = D1.D1_FILIAL AND F1.F1_FORNECE = D1.D1_FORNECE  " 
	  _cQuery += " AND F1.F1_LOJA = D1.D1_LOJA WHERE "
	  _cQuery += "     	D1.D_E_L_E_T_ = ' ' AND F1.D_E_L_E_T_ = ' ' AND F1.F1_FILIAL = '" + SF2->F2_FILIAL + "' AND D1.D1_FILIAL = '" + SF2->F2_FILIAL + "' "
	  If !_lPalletRetorno 
		 _cQuery += "     	AND F1.F1_FORMUL = 'S' "
	  EndIf
	  _cQuery += " 		AND D1.D1_NFORI   = '" + AllTrim(SF2->F2_DOC)     + "' "
	  _cQuery += " 		AND D1.D1_SERIORI = '" + AllTrim(SF2->F2_SERIE)   + "' "
	  _cQuery += " 		AND D1.D1_FORNECE = '" + AllTrim(SF2->F2_CLIENTE) + "' "
	  _cQuery += " 		AND D1.D1_LOJA    = '" + AllTrim(SF2->F2_LOJA)    + "' "
	  _cQuery += " 		AND F1.F1_STATUS  = 'A'  "
		
	  If Select("SD1T") > 0
	     DBSelectArea("SD1T")
		 SD1T->(DBCloseArea())
	  EndIf
		
      MPSysOpenQuery( _cQuery , "SD1T" )

	  If !(SD1T->(Eof()))
		 SD1->(DBGoTo(SD1T->RECN))
		 SF1->(DBGoTo(SD1T->RECNF1))
	  	 //Achou nota de devolução da venda registra automaticamente o canhoto da entrega
		 SF2->(RecLock("SF2", .F.))
	     If _lPalletRetorno 
		    SF2->F2_I_DTRC := SF1->F1_DAUTNFE//SD1->D1_EMISSAO
		 EndIf
		 SF2->F2_I_CUSER:= Subs(Embaralha(SF1->F1_USERLGA, 1), 3, 6)//__cUserId UsrFullName(Subs(Embaralha(SD1T->F1_USERLGI, 1), 3, 6))
		 SF2->F2_I_CDATA:= SF1->F1_DAUTNFE//Date()
		 SF2->F2_I_CHORA:= SF1->F1_HAUTNFE//Time()
         SF2->F2_I_CORIG:= "AOMS054"
		 SF2->F2_I_OBRC	:= "NFD: "+SD1->D1_DOC+" "+SD1->D1_SERIE +" Formulario Proprio: ("+SF1->F1_FORMUL+")"
		 SF2->(MSUnLock())
		
		 //Carrega motivo de nota de devolução a origem para a nota
		 _oModel   := FWModelActive()
		 _oModelDET:= _oModel:GetModel('ZZNDETAIL')
		 _oModelDET:SeTValue("ZZN_MTDINF",'03')
		
		 cfilant := _cfilori
		
		 Return .T./// RETORNA AQUI
	  EndIf

	 
	  DBSelectArea('SA1')
	  SA1->( DBSetOrder(1) )
	  SA1->( DBSeek( xFilial('SA1') + SF2->( F2_CLIENTE + F2_LOJA ) ) )
	
	  Do Case
		 Case SF2->F2_TIPO == 'N'
			 _cTipoNf := "Normal"
		 Case SF2->F2_TIPO == 'D'
			 _cTipoNf := "Devolucao"
		 Case SF2->F2_TIPO == 'C'
			 _cTipoNf := "Complemento Precos"
		 Case SF2->F2_TIPO == 'I'
			 _cTipoNf := "Complemento ICMS"
		 Case SF2->F2_TIPO == 'P'
			 _cTipoNf := "Complemento IPI"
		 Case SF2->F2_TIPO == 'B'
			 _cTipoNf := "Utiliza Fornecedor"
	  EndCase

	
	  cFilNF    := SF2->F2_FILIAL
	  cGNumNF 	:= SF2->F2_DOC
	  cGSerie	:= SF2->F2_SERIE
	  cGCliente	:= SF2->F2_CLIENTE +'/'+ SF2->F2_LOJA
	  cGDescCli	:= SA1->A1_NOME
	  cGCGC		:= SA1->A1_CGC
	  cGRede	:= SA1->A1_GRPVEN +' - '+ SA1->A1_I_NGRPC
	  cGEmissao	:= SF2->F2_EMISSAO
	  cGCarga 	:= SF2->F2_CARGA
	  cGVlrNF	:= SF2->F2_VALBRUT
	  cGetDtCanh:= SF2->F2_I_DTRC

      //-------------------------------------------------------------
      _dPrevEOL := SF2->F2_I_PENOL // Previsão de entrega no operador logístico 
      _dPrevECL := SF2->F2_I_PENCL // Previsão de entrega no cliente
      _dChegOL  := SF2->F2_I_DCHOL // Data de chegada no operador logístico 
      _dChegCL  := SF2->F2_I_DCHCL // Data de chegada no cliente
      _dEntrCL  := SF2->F2_I_DENCL // Data de entrega no cliente
      _dEntrOL  := SF2->F2_I_DENOL // Data de entrega no operador logístico  EDI // NÃO pode MAIS ser editado.
      _dEntOLCha:= SF2->F2_I_DTOP  // Data em que o Transportador Entregou efetivamente a Carga no Operador Logístico // pode ser editado. 
	
	  If ! Empty(SF2->F2_I_OUSER)
         _cAprOperL  := UsrFullName(SF2->F2_I_OUSER) + " - " + DToC(SF2->F2_I_ODATA) + " - " + SF2->F2_I_OHORA
      EndIf

      //-------------------------------------------------------------
	  cGetObser	:= SF2->F2_I_OBRC
	  cGetStat    := U_AOMS054J(SF2->F2_FILIAL,SF2->F2_DOC,SF2->F2_SERIE)
	  _cnflabel := cFilNF + "/" + cGNumNF

	  //Se For cte do operador logistico e data de entrega de operador 
	  // logistico já está preenchida retorna validado
	  _loplog := u_Nfoplog(cFilNF,cGNumNF,cGSerie)
    
	  cAprovacao:=""
      cAprovCanh:=""
      ZGJ->(DBSetOrder(1))
      If ZGJ->(DBSeek(SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE))
         cGetstat    := ZGJ->ZGJ_STATUS
         cGetDtCanh  := ZGJ->ZGJ_DTENT
         cAprovCanh  := UsrFullName(AllTrim(ZGJ->ZGJ_APROVA))
         cDatavCanh  := DToC(ZGJ->ZGJ_DATAA)
         cHoravCanh  := ZGJ->ZGJ_HORAA
         cGetObser   := ZGJ->ZGJ_OBS
      Else
         cGetDtCanh  := SF2->F2_I_DTRC
         cDatavCanh  := DToC(SF2->F2_I_CDATA)
         cHoravCanh  := SF2->F2_I_CHORA
         cGetObser   := SF2->F2_I_OBRC
         If !Empty(cGetDtCanh)
            cGetstat := "Aprovado"
         EndIf
      EndIf
      If Empty(cAprovCanh)//Pq o conteudo do campo ZGJ_APROVA dos antigos não é __cUserId, coloquei a partir de 16/06/2022
         cAprovCanh  := UsrFullName((SF2->F2_I_CUSER))
      EndIf
      If Empty(cAprovCanh)//Pq se conteudo do campo F2_I_CUSER For branco e o ZGJ_APROVA For o antigo vai ele mesmo
         cAprovCanh  := ZGJ->ZGJ_APROVA
      EndIf
      cAprovacao:=AllTrim(cAprovCanh)
      If !Empty(CTOD(cDatavCanh))
         cAprovacao+=" - "+cDatavCanh
      EndIf
      If !Empty(cHoravCanh)
         cAprovacao+=" - "+cHoravCanh
      EndIf

	  SC5->(DBSetOrder(1))
	  If SC5->(DBSeek(SF2->F2_FILIAL+AllTrim(SF2->F2_I_PEDID))) .And. SC5->C5_I_OPER = '51' //_lPalletRetorno
	     U_ITMsg("A PRÓXIMA TELA MOSTRA OS DADOS REFERENTE AO PEDIDO DE PALLET RETORNO DO TRANSPORTADOR: "+SC5->C5_I_NOME,"ATENÇÃO",,3)
	  EndIf

      While .T.

         _nOpc:= 2
			
         _nLin1 := 74// 29  // soma 27
         _nLin2 := 82 // 37  // soma 27

	     DEFINE MSDIALOG oDlg2 TITLE "Recebimento de Canhoto:" FROM 000, 000  To 600, 1200 PIXEL // 450, 1200
	
	        oPanel	:= TPanel():New( 0 , 0 , '' , oDlg2 ,, .T. , .T. ,,, 815 , 600 , .T. , .T. )

	        @ 040, 014 Say "Tipo da N.F."				SIZE 032, 007 PIXEL OF oPanel  
	        @ 048, 014 MSGET oGTipNF VAR _cTipoNf		SIZE 060, 010 PIXEL OF oPanel READONLY
	
	        @ 040, 098 Say "Numero da N.F."				SIZE 048, 007 PIXEL OF oPanel 
	        @ 048, 097 MSGET oGNumNF VAR _cnflabel		SIZE 060, 010 PIXEL OF oPanel READONLY
	
	        @ 040, 193 Say "Serie"						SIZE 025, 007 PIXEL OF oPanel 
	        @ 048, 193 MSGET oGSerie VAR cGSerie		SIZE 060, 010 PIXEL OF oPanel READONLY
	
	        @ 040, 268 Say "Cliente/Loja"				SIZE 033, 007 PIXEL OF oPanel 
	        @ 048, 268 MSGET oGCliente VAR cGCliente	SIZE 060, 010 PIXEL OF oPanel READONLY
	
	        @ 040, 343 Say "Descrição do Cliente"		SIZE 067, 007 PIXEL OF oPanel 
	        @ 048, 343 MSGET oGDescCli VAR cGDescCli	SIZE 200, 010 PIXEL OF oPanel READONLY
	
	        @ 072, 014 Say "CNPJ/CPF"					SIZE 025, 007 PIXEL OF oPanel 
	        @ 080, 014 MSGET oGCGC VAR cGCGC			SIZE 060, 010 PIXEL OF oPanel READONLY
	
	        @ 072, 097 Say "Codigo da Rede/Descrição"	SIZE 074, 007 PIXEL OF oPanel 
	        @ 080, 097 MSGET oGRede VAR cGRede			SIZE 080, 010 PIXEL OF oPanel READONLY
	
	        @ 072, 193 Say "Emissão"					SIZE 025, 007 PIXEL OF oPanel 
	        @ 080, 193 MSGET oGEmissao VAR cGEmissao	SIZE 060, 010 PIXEL OF oPanel READONLY
	
	        @ 072, 268 Say "Carga"						SIZE 025, 007 PIXEL OF oPanel 
	        @ 080, 268 MSGET oGCarga VAR cGCarga		SIZE 060, 010 PIXEL OF oPanel READONLY
	
	        @ 072, 343 Say "Valor da N.F."				SIZE 036, 007 PIXEL OF oPanel 
	        @ 080, 343 MSGET oGVlrNF VAR cGVlrNF		SIZE 060, 010 PIXEL OF oPanel READONLY PICTURE "@E 99,999,999,999.99"

	        //Só mostra campo de data de operador logistico para notas que tem operador logistico ou ocorrência de op logistico
	        _loplog:=u_nfoplog(cFilNF,cGNumNF,cGSerie)  
	        If _loplog  

               _nLin1 += 27
               _nLin2 += 27

               @ _nLin1 , 014 Say "Prev.Entrega Oper.Logistico"   SIZE 081, 007 PIXEL OF oPanel 
               @ _nLin2 , 014 MSGET _dPrevEOL                     SIZE 060, 010 PIXEL OF oPanel WHEN .F.

               @ _nLin1 , 098 Say "Dt.Ocorr.Oper.Logistico"       SIZE 081, 007 PIXEL OF oPanel          // "Dt.Chegada Oper.Logistico"
               @ _nLin2 , 097 MSGET _dChegOL                      SIZE 060, 010 PIXEL OF oPanel WHEN .F.

               @ _nLin1 , 182 Say "Dt. Entrega Op. Log. (EDI)"    SIZE 081, 007 PIXEL OF oPanel
               @ _nLin2 , 182 MSGET _dEntrOL                      SIZE 060, 010 PIXEL OF oPanel WHEN .F. // NÃO pode MAIS ser editado.

               @ _nLin1 , 266 Say "Entrega no OpLog (Dt.Canhoto)" SIZE 081, 007 PIXEL OF oPanel
               @ _nLin2 , 266 MSGET _dEntOLCha                    SIZE 060, 010 PIXEL OF oPanel WHEN !_leOpLog // Edita só se For o lançamento do CTE do Transportador

	           @ _nLin1, 415 Say  "Usuario Alt.Dt.Entrega Opl- Data - Hora:" SIZE 300, 007 PIXEL OF oPanel    
               @ _nLin2, 415 MSGET _cAprOperL                     SIZE 165, 010 PIXEL OF oPanel WHEN .F.

            EndIf 

            _nLin1 += 27
            _nLin2 += 27

	        @ _nLin1 , 014 Say "Prev.Entrega Cliente"            SIZE 081, 007 PIXEL OF oPanel
            @ _nLin2 , 014 MSGET _dPrevECL                       SIZE 060, 010 PIXEL OF oPanel WHEN .F.

            @ _nLin1 , 098 Say "Dt.Ocorrencia Cliente"           SIZE 081, 007 PIXEL OF oPanel //"Dt.Chegada Cliente"
            @ _nLin2 , 097 MSGET _dChegCL                        SIZE 060, 010 PIXEL OF oPanel WHEN .F.

            @ _nLin1 , 182 Say "Dt.Entrega Cliente (EDI)"        SIZE 081, 007 PIXEL OF oPanel
            @ _nLin2 , 182 MSGET _dEntrCL                        SIZE 060, 010 PIXEL OF oPanel WHEN .F.

	        @ _nLin1 , 266 Say "Entrega no Cliente (Dt.Canhoto)" SIZE 081, 007 PIXEL OF oPanel
	        @ _nLin2 , 266 MSGET oGetDtCanh VAR cGetDtCanh	     SIZE 060, 010 PIXEL OF oPanel WHEN (!_loplog .Or. _leOpLog) ;//Edita se não tiver Operador Log. OU se tiver mas é o lançamento do CTE do Transportador
			                         VALID { || cGetStat := IIf(AllTrim(cGetStat)=="Nao recepcionado","Nao recepcionado","Aprovado")}
	
            _nColU:=415
            @ _nLin1, _nColU Say "Usuario Apr. Canhoto - Data - Hora:" SIZE 300, 007 PIXEL OF oPanel    
            @ _nLin2, _nColU MSGET cAprovacao                    SIZE 165, 010 PIXEL OF oPanel WHEN .F.

	        _ncol := 97
	
	        _nLin1 += 27
            _nLin2 += 27
    
	        @ _nLin1 , 014 Say "Status"					    SIZE 040, 007 PIXEL OF oPanel
	        @ _nLin2 , 014 MSCOMBOBOX oGetStat VAR cGetStat ITEMS IIf(AllTrim(cGetStat)=="Nao recepcionado",{"Nao recepcionado"},{"Aguardando Conf","Aprovado","Reprovado"}) SIZE 074, 010 PIXEL OF oPanel 

	        @ _nLin1 , 098 Say "Observação"					SIZE 040, 007 PIXEL OF oPanel
	        @ _nLin2 , 098 MSGET oGetObser VAR cGetObser	SIZE 250, 010 PIXEL OF oPanel

	        If AllTrim(cGetStat)!="Nao recepcionado" 

	           _lReti := .F.

	           //Carrega canhoto da página da Estec
	           FWMsgRun( ,{|oproc| _lReti := U_CARCANHO(cFilNF,AllTrim(cGNumNF),oproc,.F.) } , "Aguarde!", "Carregando imagem do canhoto..."  )
	
	           oTBitmap1 := TBitmap():New(180,014,170,300,,"\temp\canhoto" + AllTrim(cGNumNF)+ "_" + AllTrim(cFilNF) + ".jpg",.T.,opanel,,,.F.,.F.,,,.F.,,.T.,,.F.) // 132,014,202,300
                                  
	           oTBitmap1:lAutoSize := .T. 		
		
	        EndIf
	
		    //@ 112, _ncol MSCOMBOBOX oGetStat VAR cGetStat ITEMS IIf(AllTrim(cGetStat)=="Nao recepcionado",{"Nao recepcionado"},{"Aguardando Conf","Aprovado","Reprovado"}) SIZE 074, 010 PIXEL OF oPanel 
		
	        oGetDtCanh:SetFocus()	  
           		
	     ACTIVATE MSDIALOG oDlg2 ON INIT ( EnchoiceBar( oDlg2 , {|| Eval( {|| _nOpc := 1 , oDlg2:End() } )  } ,   {|| _nOpc := 2 , oDlg2:End() } ,, ) , )
	
		 //Valida datas de canhoto contra data de emissão da nota de venda
		 If _nOpc == 1

			If _loplog .And. !Empty(_dEntOLCha) .And. (_dEntOLCha < cGEmissao) 				
			   U_ITMsg("Data de Entrega no OL (Dt.Canhoto): "+DToC(_dEntOLCha)+" precisa ser maior ou igual a data de emissão: "+DToC(cGEmissao)+" da nota de saída: "+_cnflabel,"Atenção",,1)
			   Loop
            EndIf
			If _loplog .And. !Empty(_dEntOLCha) .And. _dEntOLCha > Date()
			   U_ITMsg("Data de Entrega no OL (Dt.Canhoto): "+DToC(_dEntOLCha)+" precisa ser menor ou igual a data de hoje: "+DToC(Date())+" da nota de saída: "+_cnflabel,"Atenção",,1)
			   Loop
            EndIf

			//Canhoto de transportador
			If Empty(cGetDtCanh) .And. !_loplog
				
			   U_ITMsg("Data de Entrega no Cliente (Dt.Canhoto) é obrigatório para o Cte de Transportador: "+_cnflabel,"Atenção",,1)
			   Loop

			ElseIf !Empty(cGetDtCanh) .AND.(cGetDtCanh < cGEmissao) 
				
			   U_ITMsg("Data de Entrega no Cliente (Dt.Canhoto): "+DToC(cGetDtCanh)+" precisa ser maior ou igual a data de emissão: "+DToC(cGEmissao)+" da nota de saída (canhoto): "+_cnflabel,"Atenção",,1)
			   Loop
            
			ElseIf !Empty(cGetDtCanh) .And. cGetDtCanh > Date() 
				U_ITMsg("Data de Entrega no Cliente (Dt.Canhoto): "+DToC(cGetDtCanh)+" precisa ser menor ou igual a data atual!","Atenção",,1)
				Loop
			
			EndIf
		 Else

			If U_ITMsg("Cancela processamento de canhotos do CTR?","Atenção",,2,2,2)
			   _lRet := .F.
			   _nopc := 2
			   _lTrocaNF := .F.
			   _lTriangu := .F.
			EndIf
		 EndIf

		 Exit
	  EndDo

	  //================================================================================
      // Confirma reprovação do canhoto
	  //================================================================================
	  If _nOpc == 1 .And. AllTrim(cGetStat) == "Reprovado" //.AND. _nopcao == 1
		 If !U_ITMsg("Confirma reprovação do canhoto?","Atenção","CTE não será liberado para pagamento!",3,2,2)
		
			_nOpc := 2
			
		 EndIf
	  EndIf	
	
	  If _nOpc == 1
	    
	     If (SF2->F2_I_DTRC <> cGetDtCanh) //.And. !Empty(cGetDtCanh) 	   
	        _lGrvCanho := .T.  // Indica se houve alterações nas datas informados do canhoto.
	     EndIf 

         If (SF2->F2_I_DTOP <> _dEntOLCha) //.And. !Empty(_dEntOLCha) 
	        _lGrvOperL := .T.  // Indica se houve alterações nas datas informadas pelo operador logístico.
	     EndIf 
		
		 //Só grava SF2 para liberar cte se o canhoto não foi reprovado
		 If AllTrim(cGetStat) != "Reprovado"
		
			SF2->( RecLock( "SF2" , .F. ) )
			SF2->F2_I_DTRC	:= cGetDtCanh
			SF2->F2_I_OBRC	:= AllTrim( cGetObser )
            SF2->F2_I_DTOP  := _dEntOLCha // Data em que o Transportador Entregou efetivamente a Carga no Operador Logístico // pode ser editado.
            If _lGrvOperL 
			   SF2->F2_I_OUSER := __cUserId
			   SF2->F2_I_ODATA := Date()
			   SF2->F2_I_OHORA := Time()
			EndIf

            If _lGrvCanho
			   SF2->F2_I_CUSER := __cUserId // Usuário de aprovação do canhoto.
               SF2->F2_I_CDATA := Date()    // Data de digitação do Canhoto.
               SF2->F2_I_CHORA := Time()    // hora de digitação do Canhoto.
			EndIf
            SF2->F2_I_CORIG := "AOMS054"
			SF2->( MSUnLock() )
			
			//================================================================================
			//	Atualiza muro de canhoto com a Estec
			//================================================================================
			ZGJ->(DBSetOrder(1))
			If ZGJ->(DBSeek(SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE))
		       If !Empty(cGetDtCanh) .And. ZGJ->ZGJ_DTENT <> cGetDtCanh
				  ZGJ->( RecLock( "ZGJ" , .F. ) )
				  ZGJ->ZGJ_DTENT:= cGetDtCanh
				  ZGJ->ZGJ_OBS	:= cGetObser
			      If !Empty(cGetDtCanh) //CHAMADO 39375. Quando informado uma Data de Canhoto e existir tabela de Controle de Digitalização de Canhoto (ZGJ) gravar o status da digitalização igual a "Aprovado" e Data de Entrega 
				     ZGJ->ZGJ_STATUS := "Aprovado"
				  Else
				     ZGJ->ZGJ_STATUS := AllTrim(cGetStat)
				  EndIf
				  ZGJ->ZGJ_DATAA  := Date()
				  ZGJ->ZGJ_HORAA  := Time()
				  ZGJ->ZGJ_APROVA := __cUserId
				  ZGJ->( MSUnLock() )
	           EndIf	
			EndIf
		
			//================================================================================
			//	Encerra monitor de pedidos se houver e se o canhoto não estiver reprovado
			//=============================================================================== 
			SC5->(DBSetOrder(1))
			SC5->(DBSeek(SF2->F2_FILIAL+SF2->F2_I_PEDID))

			If !(AllTrim(SC5->C5_I_OPER) $ AllTrim(SuperGetMV('IT_MPVOP',.T.,'50/51/02')))
		
				aheader := {}
				acols := {}
				aAdd(aheader,{1,"C6_ITEM"})
				aAdd(aheader,{2,"C6_PRODUTO"})
				aAdd(aheader,{3,"C6_LOCAL"})

				SC6->(DBSetOrder(1))
				SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
		
				While SC6->(!Eof()) .And. SC5->C5_FILIAL == SC6->C6_FILIAL .And. SC5->C5_NUM == SC6->C6_NUM
					aAdd(acols,{SC6->C6_ITEM,SC6->C6_PRODUTO,SC6->C6_LOCAL})
					SC6->(DBSkip())
				EndDo
                
				_cFilCarreg := SC5->C5_FILIAL
                If ! Empty(SC5->C5_I_FLFNC)
                   _cFilCarreg := SC5->C5_I_FLFNC
                EndIf 

				_dDTNECE := SC5->C5_I_DTENT - (U_OMSVLDENT(SC5->C5_I_DTENT,SC5->C5_CLIENTE,SC5->C5_LOJACLI,SC5->C5_I_FILFT,SC5->C5_NUM,1, ,_cFilCarreg,SC5->C5_I_OPER,SC5->C5_I_TPVEN))
				
				If !Empty(cGetDtCanh) .And. AllTrim(cGetStat) != "Reprovado"
					_cJUSCOD := "012"//"RECEBIMENTO DE CANHOTO"
					_cCOMENT := "*** Encerrado por recebimento do canhoto - entrega em " + DToC(cGetDtCanh)
					_cLENCMON := 'S'
				ElseIf Empty(cGetDtCanh) 
					_cJUSCOD:= "013"//"ESTORNO DE RECEBIMENTO DE CANHOTO"
					_cCOMENT := "*** Estorno do recebimento do canhoto."
					_cLENCMON:= 'I'
				ElseIf AllTrim(&( _cAlias +'->'+ _cAlias +'_STATC' )) == "Reprovado"
					_cJUSCOD:= "013"//"ESTORNO DE RECEBIMENTO DE CANHOTO"
					_cCOMENT := "*** Reprovacao do recebimento do canhoto. - " + cGetObser
					_cLENCMON:= 'I'
				EndIf

				U_GrvMonitor(,,_cJUSCOD,_cCOMENT,_cLENCMON,_dDTNECE,SC5->C5_I_DTENT,SC5->C5_I_DTENT)
     
			EndIf
		 ElseIf AllTrim(cGetStat) == "Reprovado"
			SF2->( RecLock( "SF2" , .F. ) )
			SF2->F2_I_DTRC	:= ctod(" ")
			//SF2->F2_I_DTOL:= ctod(" ")
			SF2->F2_I_OBRC	:= AllTrim( cGetObser )
			SF2->F2_I_CUSER := __cUserId
			SF2->F2_I_CDATA := Date()
			SF2->F2_I_CHORA := Time()
            SF2->F2_I_CORIG := "AOMS054"
			SF2->( MSUnLock() )
		 EndIf
	  EndIf

	  //Apaga os arquivos gerados para mostrar o canhoto
	  ferase("\temp\canhoto" + AllTrim(SF2->F2_DOC)+ "_" + AllTrim(cFilNF) + ".pdf")
	  ferase("\temp\canhoto" + AllTrim(SF2->F2_DOC)+ "_" + AllTrim(cFilNF) + ".jpg")
	
	  If _nopc == 1
	
		 _lRet := .T.
		 
	  EndIf

	  If (_lTrocaNF .Or. _lTriangu) .And. _lReplica
         
		 U_Repl2DtsTransTime( SF2->(RECNO()) , SF2->F2_I_OBRC ) //REPLICA OS CAMPOS DO PEDIDO PRINCIPAL PARA OS GERADOS 
	    
	  EndIf
	
	  cfilant := _cfilori
   Else
	  _lRet := .T.
	
   EndIf


   cfilant := _cfilori

   //ANALISA SE LIBERA OU NÃO O CTR

   If _lRet
	  If Empty(SF2->F2_I_DTRC) .And. (!_lTemOpl .Or. _leOpLog)  //.and. Empty(SF2->F2_I_DTOL) //duas datas em branco
		 _lRet := .F.
		 Help( ,, 'Atenção!',, "Canhoto não confirmado para a Nota fiscal " +;
								_oModel:GetValue('ZZNDETAIL','ZZN_FILNFV') + "/" +  _oModel:GetValue('ZZNDETAIL','ZZN_NFISCA'), 1, 0 )
	  EndIf
   Else	 
	  Help( ,, 'Atenção!',, "Canhoto não confirmado para a Nota fiscal " +;
	   		_oModel:GetValue('ZZNDETAIL','ZZN_FILNFV') + "/" + _oModel:GetValue('ZZNDETAIL','ZZN_NFISCA'), 1, 0 )
	 
   EndIf

End Sequence 

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS054A
Autor-------------: Alexandre Villar
Data da Criacao---: 24/09/2014
Descrição---------: Rotina para digitação da data de recebimento do canhoto
Parametros--------: Nenhum
Retorno-----------: _lRet		- Retorno lógico da validação
===============================================================================================================================
*/
Static Function AOMS054A()

Local _aArea	:= FWGetArea()
Local _oModel	:= FWModelActive()
Local _lRet := .T.
Local _cfilial	:=  _oModel:GetValue( 'ZZNDETAIL' , 'ZZN_FILNFV' ) 
Local _cChave	:= IIf( !Empty( _oModel:GetValue( 'ZZNDETAIL' , 'ZZN_NFISCA' ) ) , StrZero( Val( _oModel:GetValue( 'ZZNDETAIL' , 'ZZN_NFISCA' ) ) , TamSX3('F2_DOC')[01]   ) , '' )

Begin Sequence

If !Empty( _cChave ) .And. _cChave > StrZero( 0 , TamSX3('F2_DOC')[01] )

	DBSelectArea('SF2')
	SF2->( DBSetOrder(1) )
	SF2->( DBGoTop() )
	If SF2->( DBSeek( _cfilial + _cChave + _oModel:GetValue( 'ZZNDETAIL' , 'ZZN_SERIE' ) ) )
		
		//se For a nota de carregamento de um troca nota, traz o canhoto da nota de faturamento para conferir primeiro
		SC5->(DBSetOrder(1))
		If SC5->(DBSeek(SF2->F2_FILIAL+AllTrim(SF2->F2_I_PEDID)))
		
			If SC5->C5_I_TRCNF == "S" .And. SC5->C5_NUM == SC5->C5_I_PDPR
			
				If SC5->(DBSeek(SC5->C5_I_FILFT+SC5->C5_I_PDFT))
				
					If SF2->(DBSeek(SC5->C5_I_FILFT+SC5->C5_NOTA+SC5->C5_SERIE))
					
						_cfil := cfilant
						cfilant := SC5->C5_I_FILFT
					
					    _lTelaCanh := .T. // Para Permitir a digitação das datas do canhoto em outra nota fiscal 

						_lRet := AOMS054G() //Chama tela de confirmação do canhoto da nota de faturamnto
						
						cfilant := _cfil
						
						
					EndIf
					
					SF2->( DBSeek( _cfilial + _cChave + _oModel:GetValue( 'ZZNDETAIL' , 'ZZN_SERIE' ) ) )
					
				EndIf
				
			EndIf
			
		EndIf
		
		If _lRet		
		
			_lRet := AOMS054G()  //Chama tela de confirmação do canhoto da nota selecionada
			
		EndIf
		
	EndIf

EndIf

End Sequence

FWRestArea( _aArea )

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS054U
Autor-------------: Fabiano Dias
Data da Criacao---: 29/08/2011
Descrição---------: Rotina para preenchimento do campo virtual ZZN_DESMUN conforme o cadastro do Cliente contido na NF
Parametros--------: _cdoc - documento de saída
					_cserie - série da nf de saída
					_cfilial - filial da nf de saída
Retorno-----------: _cDesMun	- Descrição do município
===============================================================================================================================
*/
User Function AOMS054U(_cdoc,_cserie,_cfilial)

Local _cAlias	:= ""
Local _cDescMun	:= ""
Local _aArea	:= FWGetArea()

Default _cfilial := cfilant

//================================================================================
// Retorna o município do Cliente da Nota Fiscal para o campo virtual da tela
//================================================================================
If !Empty(_cDoc) .And. !Empty(_cSerie) .And. ValType(_cDoc) == 'C' .And. ValType(_cSerie) == 'C'

	//================================================================================
	// Query para selecionar a descricao do municio para campo virtural muncipio da 
	// tela principal.
	//================================================================================
	_cAlias := GetNextAlias()
	AOMS054Q( 8 , _cAlias , _cDoc , _cSerie , "" , 0 , "" , "",_cfilial )
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBGoTop() )
	
	If (_cAlias)->( !Eof() )
		_cDescMun:= (_cAlias)->CC2_MUN
	EndIf
	
	(_cAlias)->( DBCloseArea() )

EndIf

FWRestArea(_aArea)

Return( _cDescMun )

/*
==============================================================================================================================
Programa----------: AOMS054Q
Autor-------------: Fabiano Dias
Data da Criacao---: 10/08/2011
Descrição---------: Rotina desenvolvida para realizar as consultas necessárias no Banco de Dados.
Parametros--------: _nOpcao    - número da query a ser executada
------------------: _cAlias    - Alias da query a ser executada
------------------: _cDoc      - Numero da nota fiscal corrente inserida no item da fatura
------------------: _cSerie    - Serie da nota fiscal corrente inserida no item da fatura
------------------: _cCTR      - Numero do conhecimento de transporte inserido no item da fatura
------------------: _nOperacao - Tipo da operacao que esta sendo realizada(Ex: inclusao, alteracao...)
------------------: _cSerieCTR - Serie do Conhecimento de transporte.
------------------: _cCarga    - Codigo da Carga
------------------: _cfilial   - Filial para filtrar query de sf2
------------------: _cftrans   - Transportador no cabeçalho
------------------: _clojaft   - Loja do transportador no cabeçalho
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS054Q( _nOpcao , _cAlias , _cDoc , _cSerie , _cCTR , _nOperacao , _cSerieCTR , _cCarga, _cfilial,_cftrans,_clojaft )

Local _cFiltro		:= ''
Local _cFilSedex	:= ''
Default _cfilial := cfilant

Do Case


	//================================================================================
	// Query para seleciionar os dados da nota fiscal corrente que o usuario esta 
	// fazendo o lancamento nos itens.
	//================================================================================
	Case _nOpcao == 2
		
		_cFiltro := "% "
		_cFiltro += " AND SF2.F2_FILIAL  = '"+ _cfilial       +"' "
		_cFiltro += " AND DAK.DAK_FILIAL = '"+ _cfilial       +"' "
		_cFiltro += " AND SF2.F2_DOC     = '"+ _cDoc          +"' "
		_cFiltro += " AND SF2.F2_SERIE   = '"+ _cSerie        +"' "
		_cFiltro += " %"
		
		_cFilSedex := "% "
		_cFilSedex += " AND SF2.F2_FILIAL = '"+ _cfilial       +"' "
		_cFilSedex += " AND SF2.F2_DOC    = '"+ _cDoc          +"' "
		_cFilSedex += " AND SF2.F2_SERIE  = '"+ _cSerie        +"' "
		_cFilSedex += " %"
		
		BeginSql alias _cAlias
		
			SELECT
				SF2.F2_FILIAL,
				SF2.F2_DOC,
				SF2.F2_SERIE,
				SF2.F2_I_CTRA,
				SF2.F2_I_LTRA,
				SF2.F2_I_FRET,
				F2_I_DTRC,
				SA2.A2_NREDUZ,
				'N' NFSEDEX,
				SF2.F2_CARGA CARGA
			FROM %Table:SF2% SF2
			JOIN %Table:DAK% DAK ON DAK.DAK_FILIAL = SF2.F2_FILIAL AND DAK.DAK_COD = SF2.F2_CARGA
			JOIN %Table:DA4% DA4 ON DA4.DA4_COD = DAK.DAK_MOTORI
			JOIN %Table:SA2% SA2 ON SF2.F2_I_CTRA = SA2.A2_COD AND SF2.F2_I_LTRA = SA2.A2_LOJA
			WHERE
				SF2.D_E_L_E_T_ = ' '
			AND DAK.D_E_L_E_T_ = ' '
			AND DA4.D_E_L_E_T_ = ' '
			AND SA2.D_E_L_E_T_ = ' '
	    	%exp:_cFiltro%
	    	
			UNION ALL
			
			SELECT
				SF2.F2_FILIAL,
				SF2.F2_DOC,
				SF2.F2_SERIE,
				' ' F2_I_CTRA,
				' ' F2_I_LTRA,
				SF2.F2_I_FRET,
				F2_I_DTRC,
				' ' A2_NREDUZ,
				'S' NFSEDEX,
				SF2.F2_CARGA CARGA
			FROM %Table:SF2% SF2
			WHERE
				SF2.D_E_L_E_T_ = ' '
			AND SF2.F2_I_NFSED = 'S'
			%Exp:_cFilSedex%
			
		EndSql
	
	//================================================================================
	// Query para checar se ja foi lancado o CTE corrente para o transportador
	//================================================================================
	Case _nOpcao == 3
	 		
 		_cFiltro := "% "
		_cFiltro += " AND ZZN_FILIAL     = '"+ xFilial("ZZN") +"' " 
		_cFiltro += " AND ZZN_CTRANS     = '"+ _cCTR          +"' "
		_cFiltro += " AND ZZN_SERCTR     = '"+ _cSerieCTR     +"' "
		_cFiltro += " AND ZZN_FTRANS     = '"+ _cftrans  +"' "
		_cFiltro += " AND ZZN_LOJAFT     = '"+ _clojaft  +"' "
		
		//================================================================================
		// Para verifica se nao existe algum tupo de duplicidade no banco deve-se 
		// desconsiderar no caso da alteracao o codigo do lancamento corrente que esta 
		// sendo alterado.
		//================================================================================
		If _nOperacao == 4
			_cFiltro += " AND ZZN_CODIGO <> '"+ M->ZZN_CODIGO  +"' "
		EndIf 
		
		_cFiltro += " %"
		
		BeginSql alias _cAlias	
			SELECT 
			    COUNT(*) NUMREG
			FROM %Table:ZZN%
			WHERE 
			    D_E_L_E_T_ = ' '
			%exp:_cFiltro%		    		    		    
		 EndSql
	
	//================================================================================
	// Query para checar se o numero e serie da nota fiscal que deseja lancar no item 
	// corrente ja nao foi lancado anteriormente na tabela ZZN.
	//================================================================================
	Case _nOpcao == 4
	
		_cFiltro := "% "
		_cFiltro += " AND ZZN_FILIAL = '"+ xFilial("ZZN") +"' " 
		_cFiltro += " AND ZZN_NFISCA = '"+ _cDoc          +"' "
		_cFiltro += " AND ZZN_SERIE  = '"+ _cSerie        +"' "
		_cFiltro += " AND ZZN_FILNFV  = '"+ _cfilial       +"' "
		
		//================================================================================
		// Para verificar se nao existe algum tupo de duplicidade no banco deve-se 
		// desconsiderar no caso da alteracao o codigo do lancamento corrente.
		//================================================================================
		If _nOperacao == 4
			_cFiltro += " AND ZZN_CODIGO <> '" + M->ZZN_CODIGO  + "'"
		EndIf 
		
		_cFiltro += " %"
		
		BeginSql alias _cAlias
			SELECT
			    COUNT(*) NUMREG
			FROM %Table:ZZN%
			WHERE
			    D_E_L_E_T_ = ' '
			%exp:_cFiltro%
	    EndSql
	
	
	//================================================================================
	// Query para selecionar a descrição do municio para campo virtural da tela
	//================================================================================
	Case _nOpcao == 8			         
	
		_cFiltro := "% "
		_cFiltro += " AND F2.F2_FILIAL = '"+ _cfilial        +"' "
		_cFiltro += " AND F2.F2_DOC    = '"+ _cDoc           +"' "
		_cFiltro += " AND F2.F2_SERIE  = '"+ _cSerie         +"' "
		_cFiltro += " %"
	
		BeginSql alias _cAlias
			SELECT
			    CC2.CC2_MUN
			FROM %Table:SF2% F2      
			JOIN %Table:SA1% A1  ON A1.A1_COD   = F2.F2_CLIENTE AND A1.A1_LOJA     = F2.F2_LOJA
			JOIN %Table:CC2% CC2 ON CC2.CC2_EST = A1.A1_EST     AND CC2.CC2_CODMUN = A1.A1_COD_MUN
			WHERE
			    F2.D_E_L_E_T_ = ' '
			AND A1.D_E_L_E_T_ = ' '
			AND CC2.D_E_L_E_T_ = ' '
			%Exp:_cFiltro%
		EndSql
	
	//================================================================================
	// Query para selecionar a carga de uma determinada nota fiscal.
	//================================================================================
	Case _nOpcao == 11
		
		_cFiltro := "% "
	    _cFiltro += " AND F2_FILIAL = '" + _cfilial        + "'"
		_cFiltro += " AND F2_DOC = '"    + _cDoc 		   + "'"
		_cFiltro += " AND F2_SERIE = '"  + _cSerie         + "'"  
		_cFiltro += "%"
	
		BeginSql alias _cAlias
			SELECT
			      F2_CARGA
			FROM
			      %Table:SF2%
			WHERE
			      D_E_L_E_T_ = ' '	
			      %Exp:_cFiltro%	
		EndSql 
		           
	//================================================================================
	// Query para selecionar as notas fiscais de uma determinada carga.
	//================================================================================
	Case _nOpcao == 12
		
		_cFiltro := "% "
		_cFiltro += " AND DAI_FILIAL = '" + _cfilial       + "'"
		_cFiltro += " AND DAI_COD = '"    + _cCarga        + "'"
		_cFiltro += " %"
	
		BeginSql alias _cAlias	    
		    SELECT
			      DAI_NFISCA, DAI_SERIE
			FROM
			      %Table:DAI%
			WHERE
			      D_E_L_E_T_ = ' ' 
			      %Exp:_cFiltro%                         	    
		EndSql
	

EndCase

Return

/*
===============================================================================================================================
Programa----------: AOMS054M
Autor-------------: Alexandre Villar
Data da Criacao---: 22/10/2014
Descrição---------: Rotina de controle e processamento dos pontos de entrada do MVC
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS054M()

Local _aParam		:= ParamIXB
Local _xRet			:= .T.
Local _oObj			:= ''
Local _oModel 		:= FWModelActive()
Local _oModelMAS	:= Nil
Local _oModelDET	:= Nil
Local _cIdPonto		:= ''
Local _cIdModel		:= ''
Local _lIsGrid		:= .F.
Local _nLinha		:= 0
Local _nQtdLin		:= 0
Local _nOper		:= 0
Local _aHelp		:= {}
Local _cAlias		:= GetNextAlias()
Local _cAlias2		:= GetNextAlias()
Local _cCarga		:= ""
Local _cNfsCarga	:= ""
Local _cNFAux		:= ''
Local _cSRAux		:= ''
Local _lNF			:= .F.
Local _cCargaNF		:= ''
Local _nni			:= 0
Local _njj			:= 0
Local _nI			:= 0
Private _actrs        := {}
Private _ccond        := ""
Private _cconda       := ""
Private _cnatureza    := ""

Static _cfatura2 := ""   
Static _lenviaf := .F.

If _aParam <> NIL

	_oObj		:= _aParam[01]
	_cIdPonto	:= _aParam[02]
	_cIdModel	:= _aParam[03]
	_lIsGrid	:= ( Len( _aParam ) > 3 ) .And. ValType( _aParam[04] ) == 'N'
	_nOper		:= _oObj:GetOperation()
	
	Begin Sequence

	If _cIdPonto == "MODELCANCEL" 
       _lTelaCanh := .T.
	EndIf 
	
		If _cIdPonto == 'MODELPOS'	.And. ( _nOper == MODEL_OPERATION_DELETE  ) 

		_oModel 		:= FWModelActive()

		If SuperGetMV("IT_FATCTR",.F.,.F.)

			_lRet := AOMS0548(_omodel) //Valida e exclui fatura se necessário

			If !_lRet
				Return .F.
			Else
				//Envia email de exclusão da fatura
				AOMS054T(_omodel)
			EndIf
		EndIf
	EndIf

	
	If _cIdPonto == 'MODELPOS'	.And. ( _nOper == MODEL_OPERATION_INSERT .Or. _nOper == MODEL_OPERATION_UPDATE ) .And. SuperGetMV("IT_VLDCRG",.F.,.T.)
	
		_lpassou    := .F.
		_oModel 		:= FWModelActive()
		_oModelMAS 	:= _oModel:GetModel('ZZNMASTER')
		_oModelDET 	:= _oModel:GetModel('ZZNDETAIL')
		_nlin 		:= _oModelDET:Length(.F.)
		_nni 			:= 1


		//Valida datas de vencimento
		For _nni := 1 To _nlin

			//Se a linha está deletada não faz validações
			If _oModelDET:IsDeleted(_nni)
				Loop
			EndIf

			If !_lpassou
				_dvencto 	:= _oModelDET:GetValue("ZZN_PRVPAG", _nni )
				_lpassou := .T.
			EndIf

			If _dvencto != _oModelDET:GetValue("ZZN_PRVPAG", _nni )
	
				Help( ,, 'Atenção!',, "Divergência de datas de previsão de pagamento", 1, 0 )
				Return .F.

			EndIf

		Next

		//Verifica se todas as notas das cargas citadas estão na mesma fatura
		_acargas := {}
		_anotast := {}
		_aerros := {}
		_anotase := {}
			

		//verifica se não é fatura duplicada para o fornecedor
		ZZN->(DBSetOrder(1))
		If _nOper == MODEL_OPERATION_INSERT .And. !U_AOMS0546(AllTrim(_oModelMAS:GetValue("ZZN_FATURA")),;
																			AllTrim(_oModelMAS:GetValue( 'ZZN_FTRANS')),;
																			AllTrim(_oModelMAS:GetValue(  'ZZN_LOJAFT')))	
			Return .F.
		EndIf

		For _nni := 1 To _nlin

			//Se a linha está deletada não faz validações
			If _oModelDET:IsDeleted(_nni)
				Loop
			EndIf

			//==========================================================================================
			// Verifica se o Transportador da Fatura é o mesmo da Nota Fiscal se não tiver op logistico
			//==========================================================================================
			SF2->(DBSetOrder(1))
			If SF2->(DBSeek(_oModelDET:GetValue("ZZN_FILNFV", _nni )+AllTrim(_oModelDET:GetValue("ZZN_NFISCA", _nni ))))

				If  _xRet  .And. SF2->F2_I_NFSED != 'S' .And.  !U_Nfoplog(SF2->F2_FILIAL,SF2->F2_DOC,SF2->F2_SERIE)
				
					_CTRANS := AllTrim(_oModelMAS:GetValue( 'ZZN_FTRANS')) + AllTrim(_oModelMAS:GetValue(  'ZZN_LOJAFT'))
					_ctrans2 := AllTrim(_oModelMAS:GetValue( 'ZZN_FTRANS')) + "\" + AllTrim(_oModelMAS:GetValue(  'ZZN_LOJAFT'))
		
					If SF2->F2_I_CTRA + SF2->F2_I_LTRA <>  _ctrans .And. Empty( _oModelDET:GetValue( 'ZZN_MTDINF',_nni ) ) 

						If aScan(_aerros, {|it| it[1] == _oModelDET:GetValue("ZZN_ITEM",_nni) .And. it[4] == "Transportador do ctr divergente do transportador da nota de vendas" }) == 0

							aAdd(_aerros,{				_oModelDET:GetValue("ZZN_ITEM",_nni),;
					 				_oModelMAS:GetValue( 'ZZN_FTRANS')+"/"+ _oModelMAS:GetValue(  'ZZN_LOJAFT'),;
									_oModelDET:GetValue("ZZN_CTRANS",_nni) + "/" + _oModelDET:GetValue("ZZN_SERCTR",_nni),;
									"Transportador do ctr divergente do transportador da nota de vendas",;
									"Transportador do ctr: " + _ctrans2  + " -  Transportador da nota de vendas(" + SF2->F2_DOC + "): " + SF2->F2_I_CTRA +"\" + SF2->F2_I_LTRA})
						EndIf						
					EndIf
				EndIf
			Else
				aAdd(_aerros,{				_oModelDET:GetValue("ZZN_ITEM",_nni),;
					 				_oModelMAS:GetValue( 'ZZN_FTRANS')+"/"+ _oModelMAS:GetValue(  'ZZN_LOJAFT'),;
									_oModelDET:GetValue("ZZN_CTRANS",_nni) + "/" + _oModelDET:GetValue("ZZN_SERCTR",_nni),;
									"Nota fiscal de vendas não localizada",;
									"Nota fiscal de vendas: " + _oModelDET:GetValue("ZZN_FILNFV", _nni ) + ;
											"/" + AllTrim(_oModelDET:GetValue("ZZN_NFISCA", _nni )) + " não localizada."})

			EndIf

			//Valida se todos o ctrs possuem títulos com valores coerentes pendentes de baixa e em carteira
			
			SE2->(DBSetOrder(6)) //E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM
			
			If !(SE2->(DBSeek(xFilial("SE2")+_oModelMAS:GetValue( 'ZZN_FTRANS')+_oModelMAS:GetValue( 'ZZN_LOJAFT')+;
									_oModelDET:GetValue("ZZN_SERCTR", _nni )+_oModelDET:GetValue("ZZN_CTRANS", _nni ))))

				aAdd(_aerros,{				_oModelDET:GetValue("ZZN_ITEM",_nni),;
					 				_oModelMAS:GetValue( 'ZZN_FTRANS')+"/"+ _oModelMAS:GetValue(  'ZZN_LOJAFT'),;
									_oModelDET:GetValue("ZZN_CTRANS",_nni) + "/" + _oModelDET:GetValue("ZZN_SERCTR",_nni),;
									"Título do CTR não localizado no contas a pagar",;
									"Título do CTR : " + _oModelDET:GetValue("ZZN_CTRANS", _nni ) + ;
											"/" + AllTrim(_oModelDET:GetValue("ZZN_SERCTR", _nni )) + " não localizado no contas a pagar."})

			ElseIf (!Empty(SE2->E2_BAIXA) .Or. SE2->E2_SALDO != SE2->E2_VALOR) .And. _nOper == MODEL_OPERATION_INSERT 

				aAdd(_aerros,{				_oModelDET:GetValue("ZZN_ITEM",_nni),;
					 				_oModelMAS:GetValue( 'ZZN_FTRANS')+"/"+ _oModelMAS:GetValue(  'ZZN_LOJAFT'),;
									_oModelDET:GetValue("ZZN_CTRANS",_nni) + "/" + _oModelDET:GetValue("ZZN_SERCTR",_nni),;
									"Título do CTR com valor já baixado",;
									"Título do CTR : " + _oModelDET:GetValue("ZZN_CTRANS", _nni ) + ;
											"/" + AllTrim(_oModelDET:GetValue("ZZN_SERCTR", _nni )) + " com valor já baixado " + ;
											" no contas a pagar."})

			ElseIf !Empty(SE2->E2_FATURA) .And. AllTrim(SE2->E2_FATURA) != AllTrim(_oModelMAS:GetValue( 'ZZN_FATFIN')) .And. SuperGetMV("IT_FATCTR",.F.,.F.)

				aAdd(_aerros,{				_oModelDET:GetValue("ZZN_ITEM",_nni),;
					 				_oModelMAS:GetValue( 'ZZN_FTRANS')+"/"+ _oModelMAS:GetValue(  'ZZN_LOJAFT'),;
									_oModelDET:GetValue("ZZN_CTRANS",_nni) + "/" + _oModelDET:GetValue("ZZN_SERCTR",_nni),;
									"Título do CTR já pertence a fatura financeira",;
									"Título do CTR : " + _oModelDET:GetValue("ZZN_CTRANS", _nni ) + ;
											"/" + AllTrim(_oModelDET:GetValue("ZZN_SERCTR", _nni )) + " já pertence " + ;
											" a fatura: " + SE2->E2_FATURA})

			EndIf

			_nposk := aScan( _actrs, {|item| item[1]  = AllTrim(_oModelDET:GetValue("ZZN_CTRANS", _nni )) })

			If  _nposk  == 0

				aAdd(_actrs, {	AllTrim(_oModelDET:GetValue("ZZN_CTRANS", _nni )),;
							  	AllTrim(_oModelDET:GetValue("ZZN_SERCTR",_nni)),; 
								_oModelDET:GetValue("ZZN_VLRCTR",_nni),;
								SE2->E2_VALOR,;
								_oModelDET:GetValue("ZZN_ITEM",_nni) })

			Else
				_actrs[_nposk][3] += _oModelDET:GetValue("ZZN_VLRCTR",_nni)
			EndIf

			//Puxa condição de pagamento dos ctrs
  			_cconda := Posicione("SF1",1,xFilial("SF1")+_oModelDET:GetValue("ZZN_CTRANS", _nni )+_oModelDET:GetValue("ZZN_SERCTR", _nni );
											+_oModelMAS:GetValue( 'ZZN_FTRANS')+_oModelMAS:GetValue( 'ZZN_LOJAFT'),"F1_COND")

			If _cconda != _ccond
				If Empty(_ccond)
					_ccond := _cconda
				EndIf
			EndIf
		Next

		//Valida valores de ctrs versus valores do se2
		For _njj := 1 To Len(_actrs)

			If _actrs[_njj][3] != _actrs[_njj][4]

				aAdd(_aerros,{		_actrs[_njj][5],;
					 				_oModelMAS:GetValue( 'ZZN_FTRANS')+"/"+ _oModelMAS:GetValue(  'ZZN_LOJAFT'),;
									_actrs[_njj][1] + "/" + _actrs[_njj][2],;
									"Título do CTR com valor divergente no contas a pagar",;
									"Valor do CTR : " + AllTrim(transform(_actrs[_njj][3], "@E 999,999,999.99")) + ;
									  " com valor divergente do valor" + " no contas a pagar: " + ;
									  AllTrim(transform(_actrs[_njj][4], "@E 999,999,999.99"))})
			EndIf
		Next

		//Carrega arrays com todas as notas e cargas na tela
		For _nni := 1 To _nlin

			//Se a linha está deletada não faz validações
			If _oModelDET:IsDeleted(_nni)
				Loop
			EndIf
		
			_ccarga := AllTrim(_oModelDET:GetValue("ZZN_CARGA", _nni ))
			_cfilial := _oModelDET:GetValue("ZZN_FILNFV",_nni)

			If !(_oModelDET:IsDeleted(_nni))
				aAdd(_anotast, {_oModelDET:GetValue("ZZN_FILNFV", _nni ),AllTrim(_oModelDET:GetValue("ZZN_NFISCA",_nni))})
			EndIf

			If !(_oModelDET:IsDeleted(_nni)) .And. !Empty(_ccarga) .And. aScan(_acargas,{|xd| xd[2] == _ccarga .And. xd[1] == _cfilial}) == 0 
	
				_loplogi := .F.
				_loprede := .F.
				
				//Se For nota de operador logístico não precisa verificar a carga
				DAI->(DBSetOrder(3))  //DAI_FILIAL + DAI_NFISCA + DAI_SERIE
				If DAI->(DBSeek(_oModelDET:GetValue("ZZN_FILNFV",_nni)+AllTrim(_oModelDET:GetValue("ZZN_NFISCA", _nni ))+AllTrim(_oModelDET:GetValue("ZZN_SERIE", _nni ))))
				
					If (AllTrim(_oModelMAS:GetValue("ZZN_FTRANS")) ==AllTrim(DAI->DAI_I_OPLO) .And. AllTrim(_oModelMAS:GetValue("ZZN_LOJAFT")) ==AllTrim(DAI->DAI_I_LOPL) ) 
					
						_loplogi := .T.
						aAdd(_anotase, {_oModelDET:GetValue("ZZN_FILNFV",_nni),AllTrim(_oModelDET:GetValue("ZZN_NFISCA",_nni))})
						
					EndIf
					
					If (AllTrim(_oModelMAS:GetValue("ZZN_FTRANS")) ==AllTrim(DAI->DAI_I_TRED) .And. AllTrim(_oModelMAS:GetValue("ZZN_LOJAFT")) ==AllTrim(DAI->DAI_I_LTRE) ) 
					
						_loprede := .T.
						aAdd(_anotase, {_oModelDET:GetValue("ZZN_FILNFV",_nni),AllTrim(_oModelDET:GetValue("ZZN_NFISCA",_nni))})
						
					EndIf
	
					
				EndIf
				
				If !_loplogi .And. !_loprede
	
					aAdd(_acargas,{	_ccarga,;
									_oModelDET:GetValue("ZZN_FILNFV",_nni) + "/" + AllTrim(_oModelDET:GetValue("ZZN_NFISCA",_nni))+"/"+AllTrim(_oModelDET:GetValue("ZZN_SERIE", _nni )),;
									IIf(Empty(AllTrim(DAI->DAI_I_OPLO)),"",AllTrim(DAI->DAI_I_OPLO)+"/"+AllTrim(DAI->DAI_I_LOPL)),;
									IIf(Empty(AllTrim(DAI->DAI_I_TRED)),"",AllTrim(DAI->DAI_I_TRED)+"/"+AllTrim(DAI->DAI_I_LTRE)),;
									AllTrim(_oModelDET:GetValue("ZZN_CTRANS", _nni ))+"/"+AllTrim(_oModelDET:GetValue("ZZN_SERCTR", _nni )),;
									_oModelDET:GetValue("ZZN_FILNFV",_nni)})
				
				EndIf
	
			EndIf
	
		Next
		
		//Analisa se as cargas contidas na tela possuem todas as notas citadas na tela
		For _nni := 1 To Len(_acargas)
		
			DAI->(DBSetOrder(1))  //DAI_FILIAL + DAI_COD
			
			If DAI->(DBSeek(AllTrim(_acargas[_nni][6])+AllTrim(_acargas[_nni][1])))
			
				While AllTrim(DAI->DAI_FILIAL) == AllTrim(_acargas[_nni][6]) .And. AllTrim(DAI->DAI_COD) == AllTrim(_acargas[_nni][1])
				
				 	If aScan(_anotast,{ |xa| xa[1] == DAI->DAI_FILIAL .And.  xa[2] == AllTrim(DAI->DAI_NFISCA)}) == 0;
					 			.And. 	aScan(_anotase,{ |xa| xa[1] == DAI->DAI_FILIAL .And. xa[2] == AllTrim(DAI->DAI_NFISCA)}) == 0			 	 	
				 	
				 		aAdd(_aerros,{			_oModelDET:GetValue("ZZN_ITEM"),;
					 				_oModelMAS:GetValue( 'ZZN_FTRANS') + "/" + _oModelMAS:GetValue(  'ZZN_LOJAFT'),;
									_oModelDET:GetValue("ZZN_CTRANS") + "/" + _oModelDET:GetValue("ZZN_SERCTR"),;
									"Carga " + AllTrim(DAI->DAI_FILIAL) + "/" + AllTrim(DAI->DAI_COD) + " contém a nota fiscal " + AllTrim(DAI->DAI_FILIAL) + "/" +  AllTrim(DAI->DAI_NFISCA) + " não incluida nessa fatura!",;
									"Carga citada na nota " + _acargas[_nni][6] + "/" + _acargas[_nni][2] + IIf(!Empty(_acargas[_nni][3])," com operador logístico " + _acargas[_nni][3] + ", ", " ") + ;
									 IIf(!Empty(_acargas[_nni][4])," com redespacho " + _acargas[_nni][4] + ", ", " ")  +  " do CTR " + _acargas[_nni][5] })

				 	EndIf
				 	
				 	DAI->(DBSkip())
				 	
				 EndDo
				 
			Else
			
				aAdd(_aerros,{		_oModelDET:GetValue("ZZN_ITEM"),;
					 				_oModelMAS:GetValue( 'ZZN_FTRANS')+"/"+ _oModelMAS:GetValue(  'ZZN_LOJAFT'),;
									_oModelDET:GetValue("ZZN_CTRANS") + "/" + _oModelDET:GetValue("ZZN_SERCTR"),;
									"Carga " + AllTrim(DAI->DAI_FILIAL) + "/" + AllTrim(DAI->DAI_COD) + " não localizada!",;
									"Carga citada na nota " + _acargas[_nni][2] + " do CTR " + _acargas[_nni][5]})
	
			EndIf

					
		Next
		
		If Len(_aerros) > 0
			Help( ,, 'Atenção!',, "Existem problemas na fatura!", 1, 0 )
			U_ITListBox( 'Ocorreram erros de validação da fatura' , {"Linha","Transportador","CTR","Erro","Origem"} , _aerros , .T. , 1 )
			Return .F.
		Else

			//Se a fatura foi validada cria a fatura no financeiro se ainda não existir
			//Se é alteração exclui fatura primeiro

				If  _nOper == MODEL_OPERATION_UPDATE  .And. !Empty(AllTrim(_oModelMAS:GetValue("ZZN_FATFIN")))

					If SuperGetMV("IT_FATCTR",.F.,.F.)

						_lRet := AOMS0548(_omodel) //Exclui titulos da fatura

						If !_lRet
							Return .F.
						Else
							AOMS054T(_omodel) //Envia email de exclusão da fatura
						EndIf

					EndIf

				EndIf

				If SuperGetMV("IT_FATCTR",.F.,.F.)

					_lRet := AOMS0549(_omodel) //Libera titulos e cria fatura

					If !_lRet

						Return .F.
			
					Else

						//Envia email com documento da fatura criada
						_lenviaf := .T.

					EndIf

				EndIf
	
		EndIf
		
	EndIf

	If _cIdPonto == 'MODELCOMMITNTTS' .And. ( _nOper == MODEL_OPERATION_INSERT .Or. _nOper == MODEL_OPERATION_UPDATE )//Chamada após a gravação total do modelo e fora da transação.
       
	   _lTelaCanh := .T. 

		_cchavi := ZZN->ZZN_FILIAL+ZZN->ZZN_FATURA+ZZN->ZZN_FTRANS+ZZN->ZZN_LOJAFT

		If !Empty(_cfatura2) //Criou fatura

			ZZN->(DBSetOrder(1))
			If ZZN->(DBSeek(ZZN->ZZN_FILIAL+ZZN->ZZN_FATURA+ZZN->ZZN_FTRANS+ZZN->ZZN_LOJAFT))

				_cchavi := ZZN->ZZN_FILIAL+ZZN->ZZN_FATURA+ZZN->ZZN_FTRANS+ZZN->ZZN_LOJAFT

				While _cchavi == ZZN->ZZN_FILIAL+ZZN->ZZN_FATURA+ZZN->ZZN_FTRANS+ZZN->ZZN_LOJAFT

					RecLock("ZZN", .F.)
					ZZN->ZZN_FATFIN := _cfatura2
					ZZN->(MSUnLock())

					ZZN->(DBSkip())

				EndDo

			EndIf

		EndIf

		If _lenviaf 
	
			ZZN->(DBSetOrder(1))
			ZZN->(DBSeek(_cchavi))

			SE2->( DBSetOrder(1) )
			SE2->( DBSeek( cfilant + "MAN" + _cfatura2  + '01' + "FT " +;
								 ZZN->ZZN_FTRANS+ZZN->ZZN_LOJAFT ) )
			
			FWMsgRun(,{|| U_ROMS057E()}, "Criando documento da fatura " + _cfatura2 + "...","Aguarde...")

		EndIf

        FWMsgRun(,{|O| U_AOMS54Lista(.F.,O) }, "Lendo CTEs diferentes...","Aguarde...")

	EndIf

	
	If _cIdPonto == 'FORMLINEPOS' .And. ( _nOper == MODEL_OPERATION_INSERT .Or. _nOper == MODEL_OPERATION_UPDATE )
		
		_oModel := FWModelActive()
		
		If ValType(_oModel) == "O"
			
			_oModelMAS := _oModel:GetModel('ZZNMASTER')
			_oModelDET := _oModel:GetModel('ZZNDETAIL')
			
			If _lIsGrid
				_nQtdLin	:= _oModelDET:Length()
				_nLinha		:= _oModelDET:nLine
			EndIf
			
			
			//================================================================================
			// Por questoes de validacoes sera necessario o preenchimento dos campos
			// Transportardor e codigo do transportador antes de inserir linhas no acols.
			//================================================================================
			If Empty( _oModelMAS:GetValue( 'ZZN_FTRANS' ) ) .Or. Empty( _oModelMAS:GetValue(  'ZZN_LOJAFT' ) ) .Or. Empty( _oModelMAS:GetValue(  'ZZN_FATURA' ) )
				
				_aHelp := {}
				aAdd( _aHelp , { 'Antes do preenchimento dos itens é ','necessário o preenchimento dos campos ','obrigatórios do cabeçalho!'	})
				aAdd( _aHelp , { 'Verificar o preenchimento dos campos ','citados para prosseguir com o ','lançamento.'							})
				
				U_ITCADHLP( _aHelp , 'AOMS5401' )
				
				_xRet := .F.
			
			EndIf
			
			//================================================================================
			// Verifica se o usuario forneceu um numero de NF ou Carga
			//================================================================================
			If _xRet .And. ( Empty(_oModel:GetValue('ZZNDETAIL','ZZN_NFISCA')) .Or.  Empty(_oModel:GetValue('ZZNDETAIL','ZZN_SERIE')) ) 
			
				_aHelp := {}
				aAdd( _aHelp , { 'É necessário informar o número da NF ','para confirmar a inclusão ','da Linha atual!'	})
				aAdd( _aHelp , { 'Verificar o preenchimento dos campos ','citados para prosseguir com o ','lançamento.'					})
				
				U_ITCADHLP( _aHelp , 'AOMS5402' )
				
				_xRet := .F.
			
			EndIf
			
			//================================================================================
			// Verifica se o numero do CTE ja nao foi lancado anteriormente, na tabela de
			// lancamento de conhecimento.
			//================================================================================
			If _xRet
				

				AOMS054Q( 		3 ,;												//01
						 		_cAlias ,;											//02
								"" ,;												//03
								"" ,;												//04
								_oModel:GetValue('ZZNDETAIL','ZZN_CTRANS') ,;		//05
								_nOper ,; 											//06
								_oModel:GetValue('ZZNDETAIL','ZZN_SERCTR'),;		//07
								,;													//08
								,;													//09
								AllTrim(_oModelMAS:GetValue( 'ZZN_FTRANS' )),;	 	//10
								AllTrim(_oModelMAS:GetValue(  'ZZN_LOJAFT' ));		//11
								 )
				
				DBSelectArea(_cAlias)
				(_cAlias)->( DBGoTop() )
				
				If (_cAlias)->NUMREG > 0
				
					_aHelp := {}
					aAdd( _aHelp , { 'Já existe lançamento desse conhecimento ','de frete feito anteriormente em outra ','fatura para o Transportador atual!'	})
					aAdd( _aHelp , { 'Verificar o preenchimento dos campos ','citados para prosseguir com o ','lançamento.'										})
					
					U_ITCADHLP( _aHelp , 'AOMS5403' )
					
					_xRet := .F.
				
				EndIf
				
				(_cAlias)->( DBCloseArea() )
			
			EndIf
			
			//================================================================================
			// Verifica se a Nota Fiscal/Carga já foi lançada anteriormente nessa fatura
			//================================================================================
			If _xRet
				
				_cNFAux		:= _oModelDET:GetValue( 'ZZN_NFISCA' )
				_cSRAux		:= _oModelDET:GetValue( 'ZZN_SERIE'  )
				_cFilAux	:= _oModelDET:GetValue( 'ZZN_FILNFV' )
				_nVLAux		:= _oModelDET:GetValue( 'ZZN_VLRCTR' )
				_cMotDiv	:= _oModelDET:GetValue( 'ZZN_MTDINF' )
				_cMotVal	:= _oModelDET:GetValue( 'ZZN_MTDIVF' )
				
				_cTRaux		:= _oModelMAS:GetValue( 'ZZN_FTRANS' )
				_cLTAux		:= _oModelMAS:GetValue( 'ZZN_LOJAFT' )
				
				If !Empty(_cNFAux) .And. !Empty(_cSRAux)
				
					_lNF := .T.
					
					AOMS054Q( 11 , _cAlias , _cNFAux , _cSRAux , "" , 0 , "" , "", _cFilAux )
					
					DBSelectArea(_cAlias)
					(_cAlias)->( DBGoTop() )
					If (_cAlias)->( !Eof() )
						_cCargaNF := (_cAlias)->F2_CARGA
					EndIf
					
					(_cAlias)->( DBCloseArea() )
					
				Else
					
					_lNF := .F.
					
					AOMS054Q( 12 , _cAlias , "" , "" , "" , 0 , "" , " ", _cFilAux )
					
					DBSelectArea(_cAlias)
					(_cAlias)->( DBGoTop() )
					
					While (_cAlias)->( !Eof() )
					
						_cNfsCarga += '/' + (_cAlias)->DAI_FILIAL + " - " + (_cAlias)->DAI_NFISCA + " - " +  AllTrim( (_cAlias)->DAI_SERIE )
					
					(_cAlias)->( DBSkip() )
					EndDo
					
					(_cAlias)->( DBCloseArea() )
					
				EndIf
				
				For _nI := 1 To _nQtdLin
					
					If !Empty(_cNFAux) .Or. !Empty(_cSRAux) 
					
						_oModelDET:GoLine( _nI )
						
						If _nI <> _nLinha .And. !( _oObj:IsDeleted() )
							
							If _lNF
							
								If _cNFAux == _oModelDET:GetValue( 'ZZN_NFISCA' ) .And.;
										 _cSRAux == _oModelDET:GetValue( 'ZZN_SERIE' ) .And. ;
										 _cFilAux ==  _oModelDET:GetValue( 'ZZN_FILNFV' ) .And. Empty( _cMotDiv )
									
									_aHelp := {}
									aAdd( _aHelp , { 'Já existe essa Nota Fiscal no ','lançamento atual!'											})
									aAdd( _aHelp , { 'Se For necessário repetir a mesma Nota ','deverá ser informado o motivo da ','divergência.'	})
									
									U_ITCADHLP( _aHelp , 'AOMS5404' )
									
									_xRet := .F.
									Exit
									
								EndIf
															
							EndIf
							
						EndIf
					
					EndIf
					
				Next nI
				
				If _nQtdLin > 1
					_oModelDET:GoLine( _nLinha )
				EndIf
				
			EndIf
			
			If _xRet .And. _lNF 
			
			
				//================================================================================
				// Verifica se a Nota Fiscal já foi lançada anteriormente para o Transportador
				//================================================================================
				If _xRet
				
					AOMS054Q( 2 , _cAlias2 , _cNFAux , _cSRAux , "", _nOper , "", ,_cFilAux )
		
					DBSelectArea(_cAlias2)
					(_cAlias2)->( DBGoTop() )
					
					//Se a nota fiscal tem operador logistico e o transportador do cte é diferente do transp da nota já preenche o motivo de divergência
					If U_Nfoplog((_cAlias2)->F2_FILIAL,(_cAlias2)->F2_DOC,(_cAlias2)->F2_SERIE)
					
						_oModelDET:SetValue("ZZN_MTDINF","31")
					
					EndIf
					
					If Select(_cAlias2) > 0
						(_cAlias2)->( DBCloseArea() )
					EndIf
					
									
					AOMS054Q( 4 , _cAlias , _cNFAux , _cSRAux , "" , _nOper , "", ,_cFilAux )
					
						
					DBSelectArea(_cAlias)
					(_cAlias)->( DBGoTop() )
					
					If (_cAlias)->NUMREG > 0 .And. Empty( _oModelDET:GetValue( 'ZZN_MTDINF' ) )
						
						_aHelp := {}
						aAdd( _aHelp , { 'A Nota Fiscal informada já existe em ','um lançamento anterior!',''   	})
						aAdd( _aHelp , { 'Se For necessário repetir a mesma Nota ','deverá ser informado o motivo da ','divergência.'	})
						
						U_ITCADHLP( _aHelp , 'AOMS5408' )
						
						_xRet := .F.
						
					EndIf
					
					(_cAlias)->( DBCloseArea() )
					
				EndIf
				
				//================================================================================
				// Verifica se a Nota Fiscal digitada é válida e se já existe canhoto recebido
				//================================================================================
				If _xRet
					
					AOMS054Q( 2 , _cAlias , _cNFAux , _cSRAux , "", _nOper , "", ,_cFilAux )
		
					DBSelectArea(_cAlias)
					(_cAlias)->( DBGoTop() )
					
						
					If (_cAlias)->( Eof() ) .And. Empty( _oModelDET:GetValue( 'ZZN_MTDINF' ) )  
		    			
		    			_aHelp := {}
		    			aAdd( _aHelp , { 'A Nota Fiscal de venda informada não ' , 'foi encontrada nos Documentos de Saída ' ,'!'  })
						aAdd( _aHelp , { 'Se For necessário informar essa nota'   , 'deverá ser informado o motivo da ' , 'divergência.'	                       })
						
						U_ITCADHLP( _aHelp , 'AOMS5409' )
						
						_xRet := .F. 
					
					EndIf
				
				EndIf
								
					
				//================================================================================
				// Verifica se o valor do frete digitado no lacamento do conhecimento é diferente
				// do lancado na nota fiscal
				//================================================================================
				If _xRet
					
					If (_cAlias)->NFSEDEX == 'S' .And. Empty( _cMotDiv )
						
						_aHelp := {}
						aAdd( _aHelp , { 'A Nota Fiscal possui o frete registrado ','como SEDEX!'												})
						aAdd( _aHelp , { 'Para confirmar a utilização da Nota de ','SEDEX é necessário informar o motivo da ','divergência.'	})
						
						U_ITCADHLP( _aHelp , 'AOMS5414' )
						
						_xRet := .F.
					
					EndIf
					
				EndIf 
				
				If Select(_cAlias) > 0
					(_cAlias)->( DBCloseArea() )
				EndIf
						
			EndIf
			
			//================================================================================
			// Valida canhoto e abre tela de confirmação se necessário
			//================================================================================
			//If _xRet			
			//   _xRet := AOMS054A()								
			//EndIf
									
		EndIf
		
	EndIf
	
	End Sequence
	
EndIf

Return( _xRet )

/*
===============================================================================================================================
Programa----------: AOMS054N
Autor-------------: Fabiano Dias
Data da Criacao---: 10/08/2011
Descrição---------: Gera o número máximo para o lançamento da fatura do conhecimento de transporte.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS054N()

Local _cRet    := ""
Local _aArea   := FWGetArea()     

Local _cAlias  := GetNextAlias()
Local _cFiltro := "%"  

_cFiltro += " AND ZZN_FILIAL = '" + xFilial("ZZN") + "'"
_cFiltro += "%"

BeginSql alias _cAlias
	SELECT
	      TO_NUMBER(NVL(MAX(ZZN_CODIGO),'0')) AS CODIGO
	FROM
	      %Table:ZZN%
	WHERE
	      D_E_L_E_T_ = ' '
	      %exp:_cFiltro%	      
EndSql

DBSelectArea(_cAlias)
(_cAlias)->(DBGoTop())    

_cRet:= StrZero((_cAlias)->CODIGO + 1,6)          

//================================================================================
// Finaliza a area criada anteriormente.
//================================================================================
DBSelectArea(_cAlias)
(_cAlias)->(DBCloseArea())

While !MayIUseCode("ZZN_CODIGO" + xFilial("ZZN") + _cRet)  //verifica se esta na memoria, sendo usado
	_cRet := Soma1(_cRet)						           // busca o proximo numero disponivel 
EndDo 

FWRestArea(_aArea)

Return _cRet


/*
===============================================================================================================================
Programa----------: AOMS054B
Autor-------------: Josué Danich Prestes
Data da Criacao---: 02/03/2018
Descrição---------: Validação de campos do grid
Parametros--------: _cnctr - numero do ctr
					_csctr - série do ctr
					_ctrans - código do transportador
					_cloja - loja do transportador
					_CCHAV - Chave do CTE
					_ccampo - Campo chamando o gatilho
					_cchavi - Chave do ctr selecionado
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS054B(_cnctr , _csctr, _ctrans, _cloja, _cchav, _ccampo, _cchavi)

Local _lRet := .T.
Local _oModel := FWModelActive()
Local _oModelMAS := _oModel:GetModel('ZZNMASTER')
Local _oModelDET := _oModel:GetModel('ZZNDETAIL')
Local _nI := 0
Local _nfi := 0
Local _nnit	:= 0
Default _cchavi := ""

Begin Sequence			
		
	//Processa chamada a partir do campo de chave de conhecimento de transporte
	If (_ccampo == "ZZN_CHAV"  .And. !Empty(AllTrim(M->ZZN_CHAV))) .Or. ((_ccampo == "ZZN_CTRANS" .Or. _ccampo == "ZZN_SERCTR") .And. !Empty(_cchavi))
	
		//Limpa campo de municipio, ctr e série do ctr que controla when do campo de nota fiscal
		_oModelDET:LoadValue("ZZN_DESMUN","")
		_oModelDET:LoadValue("ZZN_CTRANS","")
		_oModelDET:LoadValue("ZZN_SERCTR","")
	
		_lauto := .T.
		_aerros := {}
		
		If _ccampo == "ZZN_CHAV"
		
			_cchavi := AllTrim(M->ZZN_CHAV)
		Else	
			_oModelDET:LoadValue("ZZN_CHAV",_cchavi) 
		EndIf

		_cQuery := " SELECT R_E_C_N_O_ RECN"
		_cQuery += " FROM "+ RetSqlName("SF1") 
		_cQuery += " WHERE "
		_cQuery += "     	D_E_L_E_T_ = ' ' "
		_cQuery += " 		AND F1_CHVNFE = '" + _cchavi + " ' "
		_cQuery += " 		AND F1_FILIAL = '"+ cfilant + "' "
		_cQuery += " 		AND F1_ESPECIE = 'CTE' "
		_cQuery += " 		AND F1_STATUS = 'A'"
	
		
		If Select("SF1T") > 0
		
			DBSelectArea("SF1T")
			SF1T->(DBCloseArea())
			
		EndIf
		
		MPSysOpenQuery( _cQuery , "SF1T" ) 
		
	
		If !(SF1T->(Eof()))
		
			SF1->(DBGoTo(SF1T->RECN))
			
			If !Empty(_oModelMAS:GetValue("ZZN_FTRANS")) .And. !Empty(_oModelMAS:GetValue("ZZN_LOJAFT"))
			
				If !(AllTrim(_oModelMAS:GetValue("ZZN_FTRANS")) == AllTrim(SF1->F1_FORNECE)) 
				
								
					Help( ,, 'Atenção!',, "CTR selecionado não pertence ao mesmo transportador", 1, 0 )
							
					_lRet := .F.
					
					Break
					
				EndIf
				
			EndIf
	
			//Carrega dados do cabeçalho e da linha atual
			_oModelMAS:LoadValue("ZZN_FTRANS",SF1->F1_FORNECE)  
			_oModelMAS:LoadValue("ZZN_LOJAFT",SF1->F1_LOJA)
			_oModelMAS:LoadValue("ZZN_DESCTR",Posicione("SA2",1,xFilial("SA2")+SF1->F1_FORNECE+SF1->F1_LOJA,"SA2->A2_NOME")) 
			_oModelMAS:LoadValue("ZZN_CGC",Posicione("SA2",1,xFilial("SA2")+SF1->F1_FORNECE+SF1->F1_LOJA,"SA2->A2_CGC"))      
			_oModelDET:LoadValue("ZZN_CTRANS",SF1->F1_DOC)  
			_oModelDET:LoadValue("ZZN_SERCTR",SF1->F1_SERIE)
			
			//Se já preencheu o campo de nota e série de venda então é entrada manual e não continua carregando dados
			If !Empty(AllTrim(_oModelDET:GetValue("ZZN_NFISCA"))) .And. !Empty(AllTrim(_oModelDET:GetValue("ZZN_SERIE")));
						.And. !Empty(AllTrim(_oModelDET:GetValue("ZZN_FILNFV")))
			
				//Garante que campo de carga e descrição do municipio estão ok
				SF2->(DBSetOrder(1))
				If SF2->(DBSeek(_oModelDET:GetValue("ZZN_FILNFV")+AllTrim(_oModelDET:GetValue("ZZN_NFISCA"))+AllTrim(_oModelDET:GetValue("ZZN_SERIE"))))
				
					_cmuni := U_AOMS054U(AllTrim(SF2->F2_DOC),AllTrim(SF2->F2_SERIE),AllTrim(SF2->F2_FILIAL))
					
					_oModelDET:LoadValue("ZZN_DESMUN",AllTrim(_cmuni))
					_oModelDET:LoadValue("ZZN_CARGA",AllTrim(SF2->F2_CARGA))
					
				EndIf
			
				Break
				
			EndIf
			
			//Carrega xml para procurar notas do CTR
			_anotas := {}
			
			_cQuery := " SELECT R_E_C_N_O_ RECN"
			_cQuery += " FROM "+ RetSqlName("SDS") 
			_cQuery += " WHERE "
			_cQuery += "     	D_E_L_E_T_ = ' ' "
			_cQuery += " 		AND DS_CHAVENF = '" + _cchavi + " ' "
			
		
			If Select("SDST") > 0
		
				DBSelectArea("SDST")
				SDST->(DBCloseArea())
			
			EndIf
		
            MPSysOpenQuery( _cQuery , "SDST" ) 

			If .not. SDST->(Eof())
			
					SDS->(DBGoTo(SDST->RECN))
			
					_cQuery := " SELECT R_E_C_N_O_ RECN"
					_cQuery += " FROM "+ RetSqlName("CKO") 
					_cQuery += " WHERE "
					_cQuery += "     	D_E_L_E_T_ = ' ' "
					_cQuery += " 		AND CKO_ARQUIV = '" + AllTrim(SDS->DS_ARQUIVO) + " ' " 
			
					If Select("CKOT") > 0
		
						DBSelectArea("CKOT")
						CKOT->(DBCloseArea())
			
					EndIf
		
					MPSysOpenQuery( _cQuery , "CKOT" ) 

					If .not. CKOT->(Eof())
					
						CKO->(DBGoTo(CKOT->RECN))
						
						//Gera o Objeto XML
						_cerror := ""
						_cWarning := ""
						
						_cxml := StrTran(CKO->CKO_XMLRET,"???")
												
						_oXml := XmlParser( _cxml, "_", @_cError, @_cWarning )
						
						If (_oXml == NIL )
							U_ITMsg("Falha ao gerar Objeto XML da CTR : "+SubStr(_cError,1,10000)+" / "+SubStr(_cWarning,1,10000),"Atenção","Será necessário informar manualmente as nfs do CTR",2)	
							_lgravacko := .F.
						Else
							_lgravacko := .T.
						EndIf 
						
						If _lgravacko
						
							_cXmlDeNFE := XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE,"_INFCTENORM")
							
						EndIf 
						
						If _lgravacko .And. ValType(_cXmlDeNFE) <> "O" 
							U_ITMsg("O CTE: "+AllTrim(SDS->DS_DOC)+"-"+AllTrim(SDS->DS_SERIE)+" não pertence a uma nota fiscal de saida.","Atenção","Será necessário informar manualmente as nfs do CTR",2)		
							_lgravacko := .F.
						EndIf   
           
						If _lgravacko .And. ValType(XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM,"_INFDOC")) <> "O" .And. ValType(XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM,"_INFDOC")) <> "A"
							U_ITMsg("O CTE: "+AllTrim(SDS->DS_DOC)+"-"+AllTrim(SDS->DS_SERIE)+" não pertence a uma nota fiscal de saida.","Atenção","Será necessário informar manualmente as nfs do CTR",2)		
							_lgravacko := .F.                                             
						EndIf
      
						If _lgravacko 
      
							_cXmlDeNFE := XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC,"_INFNFE")
      
						EndIf
      
						If _lgravacko .And.  ValType(_cXmlDeNFE) <> "O" .And. ValType(_cXmlDeNFE) <> "A"
							U_ITMsg("O CTE: "+AllTrim(SDS->DS_DOC)+"-"+AllTrim(SDS->DS_SERIE)+" não pertence a uma nota fiscal de saida.","Atenção","Será necessário informar manualmente as nfs do CTR",2)		
							_lgravacko := .F.
						EndIf

						_nQtdNFE := 0
						
						If _lgravacko
						
							_cInfoNFE := _oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE
							_nQtdNFE := 1
							If ValType(_cInfoNFE) == "A"
								_nQtdNFE := Len(_cInfoNFE)
							EndIf
						
						EndIf
						
						_anotas := {}
						_cnump := "  "
						_cchavep := "  "
      
						For _nI := 1 To _nQtdNFE
      
							_cnump := "  "
							_cchavep := "  "
      
							If _nQtdNFE == 1                                          
								_cNroNFE := XmlChildEx(_oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE,"_CHAVE")
								_cnump := _cNroNFE
             
								If ValType(_cNroNFE) <> "O" .And. ValType(_cNroNFE) <> "A"
									If ValType(_cInfoNFE:TEXT) == "C"
										_cChaveNFE := _cInfoNFE:TEXT
										_cchavep := _cChaveNFE
									Else
										_lgravacko := .F.
									EndIf
								Else
									_cChaveNFE := _oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE:_CHAVE:TEXT
									_cchavep := _cChaveNFE
								EndIf
							Else
								_cChaveNFE := _oXml:_CTEPROC:_CTE:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE[_nI]:_CHAVE:TEXT   
								_cchavep := _cChaveNFE          
							EndIf        
           
							If _lgravacko
          	          
								aAdd(_anotas,{_cnump,_cchavep})
			
							EndIf
          
						Next
						
						_oXml := nil
						DelClassIntf() 
						
					EndIf
			
			EndIf
			
			//Inclui notas de pallets referenciadas se não vieram no xml do ctr
			_nfi := 1
			_anotast := _anotas
			_anotas := {}
	
			For _nfi := 1 To Len(_anotast)
			
				 aAdd(_anotas,_anotast[_nfi])

				_cQuery := " SELECT R_E_C_N_O_ RECN"
				_cQuery += " FROM "+ RetSqlName("SF2") 
				_cQuery += " WHERE "
				_cQuery += "     	D_E_L_E_T_ = ' ' "
				_cQuery += " 		AND F2_CHVNFE = '" + AllTrim(_anotast[_nfi][2]) + " ' "
	
		
				If Select("SF2T") > 0
		
					DBSelectArea("SF2T")
					SF2T->(DBCloseArea())
			
				EndIf	
						
				MPSysOpenQuery( _cQuery , "SF2T" ) 

				If  !(SF2T->(Eof()))
				
					SF2->(DBGoTo(SF2T->RECN))
					
					SC5->(DBSetOrder(1))
					If SC5->(DBSeek(SF2->F2_FILIAL+AllTrim(SF2->F2_I_PEDID))) .And. SC5->C5_I_PEDGE = "S"  //Verifica se pedido da nota gerou pedido de pallet
					
						If SC5->(DBSeek(SC5->C5_FILIAL+SC5->C5_I_NPALE))  //Procura pedido de pallet
						
							SF2->(DBSetOrder(1)) //F2_FILIAL+F2_DOC+F2_SERIE
							
							If SF2->(DBSeek(SC5->C5_FILIAL + SC5->C5_NOTA + SC5->C5_SERIE)) //Procura nota do pedido de pallet
							
								If aScan(_anotast,{|x| x[2] = AllTrim(SF2->F2_CHVNFE)} ) == 0 //Verifica se a nota de pallet já não foi inclusa no xml do cte
								
									aAdd(_anotas,{AllTrim(SF2->F2_DOC),AllTrim(SF2->F2_CHVNFE)}) //Inclui nota de pallet na sequência de notas do ctr
									
								EndIf
								
							EndIf
							
						EndIf
					
					EndIf	
					
				EndIf
						
			Next
			
			
			_nfi := 1
			_ncc := 0

			For _nfi := 1 To Len(_anotas)
			 
				_ncc++
				
				_cQuery := " SELECT R_E_C_N_O_ RECN"
				_cQuery += " FROM "+ RetSqlName("SF2") 
				_cQuery += " WHERE "
				_cQuery += "     	D_E_L_E_T_ = ' ' "
				_cQuery += " 		AND F2_CHVNFE = '" + AllTrim(_anotas[_nfi][2]) + " ' "
	
		
				If Select("SF2T") > 0
		
					DBSelectArea("SF2T")
					SF2T->(DBCloseArea())
			
				EndIf	
						
				MPSysOpenQuery( _cQuery , "SF2T" ) 

				//Posiciona para função AOM S054G que verifica e confirma canhoto
				If  !(SF2T->(Eof()))
				
					SF2->(DBGoTo(SF2T->RECN))
					
				EndIf
				
                _lteste:=.F.
				If  !(SF2T->(Eof())) .And. AOMS054G()
				
					//Posiciona de novo pois a funçao de canhoto pode ter desposicionado
					SF2->(DBGoTo(SF2T->RECN))

					//Reposicionar SF1 de acordo com o CTE que esta no buffer
					SF1->(DBGoTo(SF1T->RECN))
					//*******************************************************
				
					If _ncc > 1
				
						_lteste := _oModelDET:VldLineData(.T.)
					
						//Se achou mais de uma nota no CTE acrescenta linhas
						_cchav :=  _oModelDET:GetValue("ZZN_CHAV")
						
						_nnv := _oModelDET:AddLine()

						If _lteste
					
							//Código de segurança para garantir que o ZZN_ITEM vai ser corretamente preenchido
							_nvalit := 1
							
							For _nnit := 1 To _oModelDET:GetQTDLine()
							
								If Val(_oModelDET:GetValue("ZZN_ITEM",_nnit)) >= _nvalit
								
									_nvalit := Val(_oModelDET:GetValue("ZZN_ITEM",_nnit)) + 1
									
								EndIf
							
							Next
							
							_oModelDET:LoadValue("ZZN_ITEM",StrZero(_nvalit,3))
							_oModelDET:LoadValue("ZZN_CTRANS",SF1->F1_DOC)  
							_oModelDET:LoadValue("ZZN_SERCTR",SF1->F1_SERIE)
							_oModelDET:LoadValue("ZZN_CHAV",_cchav)
							_oModelDET:SeTValue("ZZN_VLRCTR",0)
							
					
						Else
					
							_aerror := _oModel:GetErrorMessage(.T.)
						
							If Len(_aerror) > 0
						
								aAdd(_aerros,{			_oModelDET:GetValue("ZZN_ITEM"),;
					 				_oModelMAS:GetValue( 'ZZN_FTRANS')+"/"+ _oModelMAS:GetValue(  'ZZN_LOJAFT'),;
									_oModelDET:GetValue("ZZN_CTRANS") + "/" + _oModelDET:GetValue("ZZN_SERCTR"),;
									"Erro na inclusão da linha da nota fiscal " + AllTrim(SF2->F2_DOC), _aerror[6]})
							
							Else
						
								aAdd(_aerros,{				_oModelDET:GetValue("ZZN_ITEM"),;
					 				_oModelMAS:GetValue( 'ZZN_FTRANS')+"/"+ _oModelMAS:GetValue(  'ZZN_LOJAFT'),;
									_oModelDET:GetValue("ZZN_CTRANS") + "/" + _oModelDET:GetValue("ZZN_SERCTR"),;
									"Erro sem mensagem para a nota fiscal "  + AllTrim(SF2->F2_DOC)," "})
						
							EndIf
										
						EndIf
				
					EndIf
			
				ElseIf (SF2T->(Eof()))
				
					aAdd(_aerros,{				_oModelDET:GetValue("ZZN_ITEM"),;
					 				_oModelMAS:GetValue( 'ZZN_FTRANS')+"/"+ _oModelMAS:GetValue(  'ZZN_LOJAFT'),;
									_oModelDET:GetValue("ZZN_CTRANS") + "/" + _oModelDET:GetValue("ZZN_SERCTR"),;
									"Chave de nota fiscal não localizada "  + AllTrim(_anotas[_nfi][2])," "})
					_lteste := .F.
					
				Else
				
					aAdd(_aerros,{	_oModelDET:GetValue("ZZN_ITEM"),;
					 				_oModelMAS:GetValue( 'ZZN_FTRANS')+"/"+ _oModelMAS:GetValue(  'ZZN_LOJAFT'),;
									_oModelDET:GetValue("ZZN_CTRANS") + "/" + _oModelDET:GetValue("ZZN_SERCTR"),;
									 "Confirmação de canhoto não efetuada para nota "  + AllTrim(SF2->F2_DOC)," "})
					_lteste := .F.
					Exit //Quando não confirma canhoto sai para não ficar pedindo outros canhotos
				
				EndIf
						
				If Select("SF2T") > 0 .And. !SF2T->(Eof()) .And. (_ncc == 1 .Or. _lteste)  
				
					SF2->(DBGoTo(SF2T->RECN))
					
					//Limpa campo de municipio que controla when do campo de nota fiscal
					_oModelDET:LoadValue("ZZN_DESMUN"," ")
					
					_oModelDET:LoadValue("ZZN_NFISCA",SF2->F2_DOC)
					_oModelDET:LoadValue("ZZN_FILNFV",SF2->F2_FILIAL)
					_oModelDET:LoadValue("ZZN_SERIE",SF2->F2_SERIE)
					_oModelDET:LoadValue("ZZN_CARGA",SF2->F2_CARGA)
					_oModelDET:LoadValue("ZZN_SEDEX",U_AOMS0547(_oModelDET))
					
					If _ncc == 1
						
						_oModelDET:SeTValue("ZZN_VLRCTR",SF1->F1_VALBRUT)
						
					Else
					
						_oModelDET:SeTValue("ZZN_VLRCTR",0)
						
					EndIf
					
					
					//Preenche novamente campo de municipio que controla when do campo de nota fiscal
					_cmuni := U_AOMS054U(AllTrim(SF2->F2_DOC),AllTrim(SF2->F2_SERIE),AllTrim(SF2->F2_FILIAL))
					SF2->(DBGoTo(SF2T->RECN))
					
					_oModelDET:LoadValue("ZZN_DESMUN",AllTrim(_cmuni))
																
					If Empty(AllTrim(_oModelDET:GeTValue("ZZN_MTDIVF")))
					
						_oModelDET:SeTValue("ZZN_DESCMD",' ')
						
					EndIf
						
				EndIf
				
				If Select("SF2T") > 0
				
					DBSelectArea("SF2T")
					SF2T->(DBCloseArea())
					
				EndIf
						
			Next
						
		Else
		
			Help( ,, 'Atenção!',, "Chave não recepcionada como CTR da filial", 1, 0 )
			_lRet := .F.
			Break
			
		EndIf
		
		If Select("SF1T") > 0 
		
			DBSelectArea("SF1T")
			SF1T->(DBCloseArea())
			
		EndIf

		If Len(_aerros) > 0

			//Se  falhou, limpa todos os campos atuais
			_oModelDET:LoadValue("ZZN_DESMUN"," ")
			_oModelDET:LoadValue("ZZN_CHAV"," ")
			_oModelDET:LoadValue("ZZN_CTRANS"," ")  
			_oModelDET:LoadValue("ZZN_SERCTR"," ")
			_oModelDET:LoadValue("ZZN_SERCTR"," ")
			_oModelDET:LoadValue("ZZN_NFISCA"," ")
			_oModelDET:LoadValue("ZZN_SEDEX","  ")
			_oModelDET:LoadValue("ZZN_FILDEV","  ")
			_oModelDET:LoadValue("ZZN_DOCDEV","  ")
			_oModelDET:LoadValue("ZZN_DTDEV",CTOD("  "))
			_oModelDET:LoadValue("ZZN_FILNFV"," ")
			_oModelDET:LoadValue("ZZN_SERIE"," ")
			_oModelDET:LoadValue("ZZN_VLRCTR",0)
			_oModelDET:SetValue("ZZN_MTDIVF"," ")
			
			U_ITListBox( 'Ocorreram erros no carregamento do CTR' , {"Linha","Transportador","CTR","Erro","Detalhe"} , _aerros , .T. , 1 )
			
		EndIf
				
	EndIf

End Sequence

If _lRet

	_oModelDET:Setline(_oModelDET:Length(.F.))	
	_oview := FWViewActive()
	_oview:Refresh()

EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS054F
Autor-------------: Fabiano dias
Data da Criacao---: 29/08/2011
Descrição---------: Valida se campo pode ser editado
Parametros--------: _ccampo - Campo a ser analiszado
Retorno-----------: lRet - Indica se o código foi validado ou seje já existe
===============================================================================================================================
*/
User Function AOMS054F(_ccampo)  

Local _lRet := .T.
Local _oModel := FWModelActive()
Local _oModelDET := _oModel:GetModel('ZZNDETAIL')


If Empty( FwFldGet( 'ZZN_FATURA' ) )

	_lRet := .F.
	
EndIf

If _lRet .And. _ccampo == "ZZN_CARGA"

	_lRet := .F.
	
EndIf

If _lRet .And. (_ccampo == "ZZN_CTRANS" .Or. _ccampo == "ZZN_SERCTR")

	If (!Empty(_oModelDET:GetValue("ZZN_CTRANS")) .And. !Empty(_oModelDET:GetValue("ZZN_SERCTR")))
	
		_lRet := .F.
		
	EndIf
	
EndIf

If _lRet .And. (_ccampo == "ZZN_FILNFV" .Or. _ccampo == "ZZN_NFISCA" .Or. _ccampo == "ZZN_SERIE" .Or. _ccampo == "ZZN_CHAVE")

	If (!Empty(_oModelDET:GetValue("ZZN_CTRANS")) .And. !Empty(_oModelDET:GetValue("ZZN_SERCTR")) .And. !Empty((_oModelDET:GetValue("ZZN_DESMUN"))))
	
		_lRet := .F.
		
	EndIf
	
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS054Z
Autor-------------: Fabiano dias
Data da Criacao---: 29/08/2011
Descrição---------: Validação de campo com barra de progresso
Parametros--------: _ccampo - Campo a ser analiszado
Retorno-----------: lRet - Indica se o código foi validado ou seje já existe
===============================================================================================================================
*/
User Function AOMS054Z(_ccampo)  

Local _oModel := FWModelActive()
Local _oModelMAS := _oModel:GetModel('ZZNMASTER')
Local _oModelDET := _oModel:GetModel('ZZNDETAIL')
Local _cchavi    := ""
Local _actes     := {}
Local _ctransp   := ""
Local _clojat    := {}
Local _nI        := 0
Local _nDiasCte  := SuperGetMV("IT_DIASCTE",.F.,0) 

Private nTam		:= 0
Private nMaxSelect	:= 0
Private aCat		:= {}
Private MvRet		:= AllTrim(ReadVar())
Private MvPar		:= ""
Private cTitulo		:= ""
Private MvParDef	:= ""
Private _lReti := .T.

Begin Sequence

//Processa chamada a partir do campo de número ou série de conhecimento de transporte
If (_ccampo == "ZZN_CTRANS" .Or. _ccampo == "ZZN_SERCTR") .And. Empty(M->ZZN_CHAV) 
		_cQuery := " SELECT R_E_C_N_O_ RECN"
		_cQuery += " FROM "+ RetSqlName("SF1") 
		_cQuery += " WHERE "
		_cQuery += "     	D_E_L_E_T_ = ' ' "
		_cQuery += " 		AND F1_DOC = '" + AllTrim(_oModelDET:GetValue("ZZN_CTRANS")) + "' "
		_cQuery += " 		AND F1_SERIE = '" + AllTrim(_oModelDET:GetValue("ZZN_SERCTR")) + "' "
		_cQuery += " 		AND F1_FILIAL = '" + AllTrim(xFilial("SF1")) + "' "
		_cQuery += " 		AND F1_ESPECIE = 'CTE' "

		_cQuery += " 		AND F1_STATUS = 'A'"
		  
		//Se cabeçalho já selecionou um fornecedor restringe a busca
		If !Empty(AllTrim(_oModelMAS:GetValue("ZZN_FTRANS"))) .And. !Empty(AllTrim(_oModelMAS:GetValue("ZZN_LOJAFT")))
		
			_cQuery += " 		AND F1_FORNECE = '" + AllTrim(_oModelMAS:GetValue("ZZN_FTRANS")) + "' "
			_cQuery += " 		AND F1_LOJA = '" + AllTrim(_oModelMAS:GetValue("ZZN_LOJAFT")) + "' "
		 
		//Senão traz os transportadores que começam com T
		Else
		
			_cQuery += " AND SubStr(F1_FORNECE,1,1) = 'T' "
		
		EndIf

		If _nDiasCte > 0
			_dInicial := DToS(Date()-_nDiasCte)
			_cQuery += "  AND F1_EMISSAO >= '" + _dInicial + "'"				
		End
		
		If Select("SF1T") > 0
		
			DBSelectArea("SF1T")
			SF1T->(DBCloseArea())
			
		EndIf
		
		MPSysOpenQuery( _cQuery , "SF1T" ) 
		_actes := {}
		
		If SF1T->(Eof()) .And. !(Empty(AllTrim(_oModelDET:GetValue("ZZN_CTRANS")))) .And. !(Empty(AllTrim(_oModelDET:GetValue("ZZN_SERCTR"))))  
		
			If !Empty(AllTrim(_oModelMAS:GetValue("ZZN_FTRANS"))) .And. !Empty(AllTrim(_oModelMAS:GetValue("ZZN_LOJAFT")))
				Help( ,, 'Atenção!',, "Número de CTE " + AllTrim(_oModelDET:GetValue("ZZN_CTRANS")) + "/" + ;
				 AllTrim(_oModelDET:GetValue("ZZN_SERCTR")) + "  não localizado para o fornecedor do cabeçalho",;
				  1, 0,, ,,, , {"Contate o departamento fiscal para confirmar a escrituração do CTE"} )
			Else
				Help( ,, 'Atenção!',, "Número de CTE " + AllTrim(_oModelDET:GetValue("ZZN_CTRANS")) + "/" + AllTrim(_oModelDET:GetValue("ZZN_SERCTR"));
				 	+ "  não localizado", 1, 0,, ,,, , {"Contate o departamento fiscal para confirmar a escrituração do CTE"}  )
		
			EndIf
			_lReti := .F.
			Break
			
		EndIf
	
		While !(SF1T->(Eof()))
		
			SF1->(DBGoTo(SF1T->RECN))
			
			If aScan(_actes,{|_vAux|_vAux[1]== AllTrim(SF1->F1_FORNECE) .And. _vAux[2] == AllTrim(SF1->F1_LOJA)}) == 0
			
				aAdd(_actes, {AllTrim(SF1->F1_FORNECE),AllTrim(SF1->F1_LOJA),AllTrim(SF1->F1_CHVNFE)})
				
			EndIf
			
			SF1T->(DBSkip())	
	
		EndDo
		
		
		_cchavi := ""
		
		//Se tiver só um cte com o número escolhido seleciona automaticamente
		If Len(_actes) == 1
		
			_cchavi := _actes[1][3]
			_ctransp := _actes[1][1]
			_clojat := _actes[1][2]
		
		//Se tiver mais de um cte com mesmo número para vários fornecedores então vai abrir tela de seleção
		ElseIf Len(_actes) > 0
		
			//====================================================================================================
			// Tratamento para carregar variaveis da lista de opcoes
			//====================================================================================================
			nTam		:= 11
			nMaxSelect	:= 1
			cTitulo		:= "Selecione fornecedor do CTR"

			For _nI := 1 To Len( _actes ) 

				MvParDef += AllTrim( _actes[_nI][1] + "/" + _actes[_nI][2] )
				aAdd( aCat , AllTrim( Posicione( 'SA2' , 1 , xFilial('SA2')+_actes[_nI][1]+_actes[_nI][2] , 'A2_NOME' ) ) )
	
			Next _nI

			//====================================================================================================
			// Trativa abaixo para no caso de uma alteracao do campo trazer todos os dados que foram selecionados
			//====================================================================================================
			If Len( AllTrim( &MvRet ) ) == 0

				MvPar  := PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )
				&MvRet := PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )
	
			Else

				MvPar := AllTrim( StrTran( &MvRet , ";" , "/" ) )

			EndIf

			//====================================================================================================
			// Executa funcao que monta tela de opcoes
			//====================================================================================================
			If f_Opcoes( @MvPar , cTitulo , aCat , MvParDef , 12 , 49 , .F. , nTam , nMaxSelect )

				//====================================================================================================
				// Tratamento para separar retorno com ";"
				//====================================================================================================
				&MvRet := ""
	
				For _nI := 1 To Len( MvPar ) step nTam
	
					If !(SubStr( MvPar , _nI , 1 ) $ " |*" )
						&MvRet += SubStr( MvPar , _nI , nTam ) +";"
					EndIf
		
				Next _nI
	
				//====================================================================================================
				// Trata para tirar o ultimo caracter
				//====================================================================================================
				&MvRet := SubStr( &MvRet , 1 , Len(&MvRet) - 1 )
				
				//Carrega chave do ctr do fornecedor selecionado
				_np := aScan(_actes,{|_vAux|_vAux[1]== SubStr(AllTrim(&mvret),1,6) .And. _vAux[2] == SubStr(AllTrim(&mvret),8,4)})

				If _np > 0
				
					_cchavi := _actes[_np][3]
					_ctransp := _actes[_np][1]
					_clojat := _actes[_np][2]
					
				Else
				
					Help( ,, 'Atenção!',, "Fornecedor para o CTR não foi selecionado", 1, 0 )
					_lReti := .F.
					Break
				
				EndIf
				
				
			Else
			
				Help( ,, 'Atenção!',, "Fornecedor para o CTR não foi selecionado", 1, 0 )
				_lReti := .F.
				Break
				
			EndIf

			
		EndIf
		
		//Se está validando, verifica se não é fatura duplicada para o fornecedor
		ZZN->(DBSetOrder(1))
		If _lReti .And. inclui .And. !U_AOMS0546(AllTrim(_oModelMAS:GetValue("ZZN_FATURA")),_ctransp,_clojat)	
		
			_lReti := .F.
			Break
				
		EndIf
	
EndIf

End Sequence

If _lReti

	FWMsgRun(, {| |  _lReti := U_AOMS054B( ,,,,, _ccampo,_cchavi )  }, "Processando", "Carregando dados...")
	
EndIf                                        

Return _lReti

/*
===============================================================================================================================
Programa----------: AOMS054Y
Autor-------------: Josué Danich Prestes
Data da Criacao---: 07/03/2018
Descrição---------: Soma total da fatura
Parametros--------: Nenhum
Retorno-----------: _ntot - Total da fatura
===============================================================================================================================
*/
User Function AOMS054Y()

Local _ntot := 0
Local _oModel := FWModelActive()
Local _oModelDET := _oModel:GetModel('ZZNDETAIL')
Local _nlin := _oModelDET:Length(.F.)
Local _nni := 1

For _nni := 1 To _nlin
	If !(_oModelDET:IsDeleted(_nni))
		_ntot := _ntot + _oModelDET:GetValue("ZZN_VLRCTR", _nni ) - _oModelDET:GetValue("ZZN_DESCON", _nni )
	EndIf
Next _nni

Return _ntot

/*
===============================================================================================================================
Programa----------: AOMS054D
Autor-------------: Josué Danich Prestes
Data da Criacao---: 07/03/2018
Descrição---------: Carrega da prevista de pagamento
Parametros--------: Nenhum
Retorno-----------: _ddata - data prevista de pagamento
===============================================================================================================================
*/
User Function AOMS054D()

Local _ddata := ctod("")
Local _oModel := FWModelActive()
Local _oModelDET := _oModel:GetModel('ZZNDETAIL')
Local _nlin := _oModelDET:Length(.F.)
Local _nni := 1

For _nni := 1 To _nlin

	If !(_oModelDET:IsDeleted(_nni)) .And. _oModelDET:GetValue("ZZN_PRVPAG", _nni ) > CTOD('01/01/2001')
	
		_ddata := _oModelDET:GetValue("ZZN_PRVPAG", _nni )
	
	EndIf
	
Next

Return _ddata

/*
===============================================================================================================================
Programa----------: AOMS0546
Autor-------------: Josué Danich Prestes
Data da Criacao---: 07/03/2018
Descrição---------: Valida Fatura duplicada para transportador
Parametros--------: _cfatura - número da fatura
					_ctrans - transportador
					_cloja - loja do transportador
Retorno-----------: _lRet - .F. se For fatura duplicada para o transportador
===============================================================================================================================
*/
User Function AOMS0546(_cfatura,_ctrans,_cloja)

Local _lRet := .T.

_cfatura := PadL( _cfatura , TamSX3("ZZN_FATURA")[01] , '0' )

ZZN->(DBSetOrder(1)) //ZZN_FILIAL+ZZN_FATURA+ZZN_FTTRANS+ZZN_LOJAFT

If !Empty(_cfatura) .And. !Empty(_ctrans) .And. !Empty(_cloja) .And. ZZN->(DBSeek(xFilial("ZZN")+_cfatura+_ctrans+_cloja))

	_cnomefor := Posicione("SA2",1,xFilial("SA2")+_ctrans+_cloja,"A2_NOME")
	 Help( ,, 'Atenção!',, "Fatura " + _cfatura  + " já existe para o fornecedor " + _ctrans + "/" + _cloja + " - " + _cnomefor, 1, 0 )
	_lRet := .F.
	
EndIf


Return _lRet	

/*
===============================================================================================================================
Programa----------: AOMS0549
Autor-------------: Josué Danich Prestes
Data da Criacao---: 07/03/2018
Descrição---------: Libera titulos e inclui fatura no financeiro para o CTR
Parametros--------: _omodel  - modelo da tela ativa
Retorno-----------: _lRet - .F. se incluiu com sucesso
===============================================================================================================================
*/
Static Function AOMS0549(_omodel)

Local _lRet := .T.
Local _aTit	:= {}
Local _nni	:= 0
Local nAux	:= 0
Local _cMsg			:= ''
Local _cCodUsr	:= RetCodUsr()

_oModelMAS 	:= _oModel:GetModel('ZZNMASTER')
_oModelDET 	:= _oModel:GetModel('ZZNDETAIL')
_nlin 		:= _oModelDET:Length(.F.)
_lpassou    := .F.

//Valida datas de vencimento
For _nni := 1 To _nlin

	//Se a linha está deletada não faz validações
	If _oModelDET:IsDeleted(_nni)
		Loop
	EndIf

	If !_lpassou
		_dvencto 	:= _oModelDET:GetValue("ZZN_PRVPAG", _nni )
		_lpassou := .T.
	EndIf

	If _dvencto != _oModelDET:GetValue("ZZN_PRVPAG", _nni )
	
		Help( ,, 'Atenção!',, "Divergência de datas de previsão de pagamento", 1, 0 )
		Return .F.

	EndIf

Next


BEGIN TRANSACTION

Begin Sequence

//Libera títulos
_atit := {}
_dini := Date()
_dfini := Date()-400
        
_dorig := dDataBase
dDataBase := _dvencto
_ndesconto := 0

For _nni := 1 To _nlin

	//Se a linha está deletada não faz validações
	If _oModelDET:IsDeleted(_nni)
		Loop
	EndIf

	_ndesconto += _oModelDET:GetValue("ZZN_DESCON", _nni )

	//aAdd(_aTit,{ SE2->E2_PREFIXO, SE2->E2_NUM, SE2->E2_PARCELA , SE2->E2_TIPO, .F.,SE2->E2_FORNECE,SE2->E2_LOJA})
	_nlp := aScan(_atit,{|it| AllTrim(it[2]) == AllTrim(_oModelDET:GetValue("ZZN_CTRANS", _nni ))})

	If _nlp == 0 //Se ainda não processou o titulo faz a liberação

		SE2->(DBSetOrder(6)) // E2_FILIAL+E2_FORNECE+E2_LOJA+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO
		If (SE2->(DBSeek(xFilial("SE2")+_oModelMAS:GetValue( 'ZZN_FTRANS')+_oModelMAS:GetValue( 'ZZN_LOJAFT')+;
							_oModelDET:GetValue("ZZN_SERCTR", _nni )+_oModelDET:GetValue("ZZN_CTRANS", _nni ))))
 
 			If Empty(SE2->E2_BAIXA )  
             				
				SE2->(RecLock("SE2",.F.))
        		SE2->E2_DATALIB := Date()
        		SE2->E2_USUALIB := cUserName
				SE2->E2_I_CLIB := _cCodUsr
        		SE2->E2_STATLIB := "03"  // Movimento liberado pelo usuário
    	   		SE2->E2_CODAPRO := IIf(FindFunction("Fa006User"), Fa006User( "000000", .F., 2 ), "" )
       	   		SE2->(MSUnLock())

				If SE2->E2_EMISSAO < _dini

            		_dini := SE2->E2_EMISSAO

				EndIf

				If SE2->E2_EMISSAO > _dfini

		       		_dfini := SE2->E2_EMISSAO

    			EndIf

				//Array para criação da fatura
				aAdd(_aTit,{ SE2->E2_PREFIXO, SE2->E2_NUM, SE2->E2_PARCELA , SE2->E2_TIPO, .F.,SE2->E2_FORNECE,SE2->E2_LOJA})
															
			ElseIf !Empty(SE2->E2_BAIXA )

					DisarmTransaction()	
					Help( ,, 'Atenção!',, "Titulo do CTR " + SE2->E2_NUM + " já possui baixa!", 1, 0 )
					_lRet := .F.
					Break

			EndIf

		Else

			DisarmTransaction()	
			Help( ,, 'Atenção!',, "Falha no processamento financeiro da fatura!", 1, 0 )
			_lRet := .F.
			Break

		EndIf
					
	EndIf

Next

_cnatureza := SuperGetMV("IT_NATFAT",.F.,"231007")

//Cria Fatura no financeiro
aArray := {  	"MAN",;
   				"FT",;
  				"   ",; //Em branco para seguir sequência de fatura do Protheus
   				_cnatureza,;
   				_dini,;
   				_dfini,;
   				_oModelMAS:GetValue( 'ZZN_FTRANS'),;
   				"    ",;   //Loja em branco para trazer todos os títulos do fornecedor
   				_oModelMAS:GetValue( 'ZZN_FTRANS'),;
   				_oModelMAS:GetValue( 'ZZN_LOJAFT'),;
   				_ccond,;
   				01,;
   				_aTit , , }

_cfatura2 := Soma1(GetMV( 'MV_NUMFATP' ,, '0' ))
lMsErroAuto := .F.

FWMsgRun(,{|| MsExecAuto( { |x,y| FINA290(x,y)},3,aArray,)},"Aguarde...","Criando fatura " + _cfatura2 + " no financeiro...")

If lMsErroAuto

	//Pegando log do ExecAuto
	cLogTxt := ""
	aLogAuto := GetAutoGRLog()
			
	//Percorrendo o Log
	For nAux:=1 To Len(aLogAuto)
		cLogTxt += aLogAuto[nAux] + Chr(13)+Chr(10)
	Next

	_cMsg := "Erro ao gerar a Fatura no financeiro - " +  cLogTxt
		
	DisarmTransaction()	
	Help( ,, 'Atenção!',, _cMsg, 1, 0 )
	_lRet := .F.
	Break
  
Else

	SE2->( DBSetOrder(1) )
	If SE2->( DBSeek( cfilant + "MAN" + _cfatura2  + '01' + "FT " + _oModelMAS:GetValue( 'ZZN_FTRANS') + _oModelMAS:GetValue( 'ZZN_LOJAFT') ) )

    	SE2->( RecLock('SE2',.F.) )
		SE2->E2_VENCTO	:= _dvencto
		SE2->E2_VENCORI	:= _dvencto
		SE2->E2_VENCREA	:= DataValida( _dvencto )
    	_chisto := "Orig: fatura " + _oModelMAS:GetValue( 'ZZN_FATURA') + " do transportador."
		SE2->E2_HIST := _chisto 
		SE2->E2_DECRESC := _ndesconto
		SE2->E2_SDDECRE := _ndesconto
		SE2->E2_DATALIB := Date()
        SE2->E2_USUALIB := cUserName
		SE2->E2_I_CLIB := RetCodUsr()
        SE2->E2_STATLIB := "03"  // Movimento liberado pelo usuário
    	SE2->E2_CODAPRO := IIf(FindFunction("Fa006User"), Fa006User( "000000", .F., 2 ), "" )
		SE2->( MSUnLock() )
			
    Else

    	_cMsg := "Erro ao gerar a Fatura no financeiro - Titulo da fatura não localizado" 
		
		DisarmTransaction()	
		Help( ,, 'Atenção!',, _cMsg, 1, 0 )
		_lRet := .F.
		Break
    EndIf
 
EndIf

dDataBase := _dorig
End Sequence
END TRANSACTION

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS0548
Autor-------------: Josué Danich Prestes
Data da Criacao---: 07/03/2018
Descrição---------: Exclui fatura no financeiro para o CTR
Parametros--------: _omodel - modelo da tela ativa
Retorno-----------: _lRet - .F. se incluiu com sucesso
===============================================================================================================================
*/
Static Function AOMS0548(_omodel)

Local _lRet := .T.
Local nAux	:= 0

_oModelMAS 	:= _oModel:GetModel('ZZNMASTER')
_oModelDET 	:= _oModel:GetModel('ZZNDETAIL')
_nlin 		:= _oModelDET:Length(.F.)


BEGIN TRANSACTION
Begin Sequence

//Valida e exclui fatura do financeiro se necessário
If !Empty(AllTrim(_oModelMAS:GetValue("ZZN_FATFIN")))

	SE2->( DBSetOrder(1) )
	If SE2->( DBSeek( cfilant + "MAN" + _oModelMAS:GetValue("ZZN_FATFIN")  + '01' + "FT " +;
								 _oModelMAS:GetValue( 'ZZN_FTRANS') + _oModelMAS:GetValue( 'ZZN_LOJAFT') ) )
	
		_chavi := cfilant + "MAN" + _oModelMAS:GetValue("ZZN_FATFIN")  + '01' 
		_chavi += "FT " + _oModelMAS:GetValue( 'ZZN_FTRANS') + _oModelMAS:GetValue( 'ZZN_LOJAFT')

		//Exclui Fatura no financeiro
		aArray := {  	"MAN",;
           				"FT",;
           				"   ",; //Em branco para seguir sequência de fatura do Protheus
          				SE2->E2_NATUREZA,;
           				SE2->E2_EMISSAO,;
           				SE2->E2_EMISSAO,;
           				_oModelMAS:GetValue( 'ZZN_FTRANS'),;
           				"    ",;   //Loja em branco para trazer todos os títulos do fornecedor
           				_oModelMAS:GetValue( 'ZZN_FTRANS'),;
           				_oModelMAS:GetValue( 'ZZN_LOJAFT'),;
	       				  ,;
           				01,;
   						{ SE2->E2_PREFIXO, SE2->E2_NUM, SE2->E2_PARCELA , SE2->E2_TIPO, .F.,SE2->E2_FORNECE,SE2->E2_LOJA},;
						 	, , }

      			
		lMsErroAuto := .F.

       	FWMsgRun(,{|| MsExecAuto( { |x,y| FINA290(x,y)},4,aArray,)},"Aguarde...",;
			   			"Excluindo fatura " + AllTrim(_oModelMAS:GetValue("ZZN_FATFIN")) + " no financeiro...")

		If lMsErroAuto

        	//Pegando log do ExecAuto
			cLogTxt := ""
        	aLogAuto := GetAutoGRLog()
			
			//Percorrendo o Log
			For nAux:=1 To Len(aLogAuto)
				cLogTxt += aLogAuto[nAux] + Chr(13)+Chr(10)
			Next

			_cMsg := "Erro ao excluir a Fatura no financeiro - " +  cLogTxt
		
			DisarmTransaction()	
			Help( ,, 'Atenção!',, _cMsg, 1, 0 )
			_lRet := .F.
			Break
  
    	Else

    		SE2->( DBSetOrder(1) )
    		If SE2->( DBSeek( _chavi ) )

    			_cMsg := "Erro ao excluir a Fatura no financeiro" 
		
				DisarmTransaction()	
				Help( ,, 'Atenção!',, _cMsg, 1, 0 )
				_lRet := .F.
				Break

         	EndIf

		EndIf

	EndIf
 
EndIf	
End Sequence
END TRANSACTION

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS054T
Autor-------------: Josué Danich Prestes
Data da Criacao---: 07/03/2018
Descrição---------: Monta e envia email de exclusão de fatura dos ctrs
Parametros--------: _omodel - modelo da tela
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS054T(_omodel)

Local _cEmail 		:= SuperGetMV("IT_WFFATFI",.F.,"sistema@italac.com.br" )
Local _cAnexo 		:= " "
Local _ccc    		:= Space(80)
Local _oModelMAS 	:= _oModel:GetModel('ZZNMASTER')
Local _cfatura 		:= _oModelMas:GetValue("ZZN_FATFIN")
Local _cnome     	:= Posicione("SA2",1,xFilial("SA2")+_oModelMas:GetValue("ZZN_FTRANS")+_oModelMas:GetValue("ZZN_LOJAFT"),"A2_NOME")
Local _cAssunto 	:= "Cancelamento de fatura de CTRs: " + _cfatura + " do transportador: " + _cnome
Local oAssunto
Local oButCan
Local oButEnv
Local oCc
Local oGetAssun
Local oGetCc
Local oGetPara
Local oMens
Local oPara
Local _csetor := ""
Local cMailCom := " "
Local _aConfig	:= U_ITCFGEML('')
Local _cEmlLog	:= ""
Local cHtml		:= ""
Local nOpcA		:= 2

Local cGetAnx	:= _cAnexo
Local cGetAssun	:= _cAssunto
Local cGetCc	:= _cCc
Local cGetMens	:= ""
Local cGetPara	:= _cEmail + Space(80)

Private oDlgMail

If (Len(PswRet()) # 0) // Quando nao For rotina automatica do configurador

	_csetor	:= AllTrim(PswRet()[1][12])		// Pega departamento do usuario
   
EndIf
If Empty(AllTrim(_csetor))
  	_csetor := "Logistica"
EndIf

cHtml := 'Ao departamento financeiro,'
cHtml += '<br><br>'
cHtml += '&nbsp;&nbsp;&nbsp;Realizado cancelamento da fatura de CTRs - ' + _cfatura + ' de nossa filial '+ cfilant + "<br>"
cHtml += '&nbsp;&nbsp;&nbsp;Documento financeiro foi cancelado e respectivos títulos continuam liberados.<br>'
cHtml += '&nbsp;&nbsp;&nbsp;Favor confirmar o recebimento, retornando com o seu CIENTE!'
cHtml += '<br><br>'
cHtml += '<br><br>'


cHtml += '&nbsp;&nbsp;&nbsp;A disposição!'
cHtml += '<br><br>'


cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
cHtml += '<tr>'
cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=         '<p class=MsoNormal align=center style="text-align:center">'
cHtml +=             '<b><span style="font-size:18.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">'+ Capital( AllTrim( UsrFullName( RetCodUsr() ) ) ) +'</span></b>'
cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=     '</td>'
cHtml +=     '<td style="background:#A2CFF0;padding:.75pt .75pt .75pt .75pt">&nbsp;</td>'
cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">
cHtml +=         '<table class=MsoNormalTable border=0 cellpadding=0>'
cHtml +=              '<tr>'
cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=                      '<p class=MsoNormal><b><span style="font-size:13.5pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#6FB4E3;mso-fareast-language:PT-BR">' + _cSetor + '</span></b>'
cHtml +=                      '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></b>
cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"><br></span>
cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=                  '</td>'
cHtml +=              '</tr>'
cHtml +=              '<tr>'
cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">
cHtml +=                      '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Tel: ' + Posicione("SY1",3,xFilial("SY1") + RetCodUsr(),"Y1_TEL") + '</span>'
cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=                  '</td>'
cHtml +=              '</tr>'
cHtml +=         '</table>'
cHtml +=     '</td>'
cHtml += '</tr>'
cHtml += '</table>'
cHtml += '<table class=MsoNormalTable border=0 cellpadding=0 width=437 style="width:327.75pt">'
cHtml +=     '<tr>'
cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR">'
cHtml +=                 '<img width=400 height=51 src="http://www.italac.com.br/assinatura-italac/images/marcas-goiasminas-industria-de-laticinios-ltda.jpg">'
cHtml +=             '</span>
cHtml +=             '</p>'
cHtml +=         '</td>'
cHtml +=     '</tr>'
cHtml += '</table>'
cHtml += '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';display:none;mso-fareast-language:PT-BR">&nbsp;</span></p>'
cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
cHtml +=     '<tr>'
cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
cHtml +=             '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Política de Privacidade </span></b>'
cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>
cHtml +=             '<p class=MsoNormal style="mso-margin-top-alt:auto;mso-margin-bottom-alt:auto;text-align:justify">'
cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">
cHtml +=                 'Esta mensagem é destinada exclusivamente para fins profissionais, para a(s) pessoa(s) a quem For dirigida, podendo conter informação confidencial e legalmente privilegiada. '
cHtml +=                 'Ao recebê-la, se você não For destinatário desta mensagem, fica automaticamente notificado de abster-se a divulgar, copiar, distribuir, examinar ou, de qualquer forma, utilizar '
cHtml +=                 'sua informação, por configurar ato ilegal. Caso você tenha recebido esta mensagem indevidamente, solicitamos que nos retorne este e-mail, promovendo, concomitantemente sua '
cHtml +=                 'eliminação de sua base de dados, registros ou qualquer outro sistema de controle. Fica desprovida de eficácia e validade a mensagem que contiver vínculos obrigacionais, expedida '
cHtml +=                 'por quem não detenha poderes de representação, bem como não esteja legalmente habilitado para utilizar o referido endereço eletrônico, configurando falta grave conforme nossa '
cHtml +=                 'política de privacidade corporativa. As informações nela contidas são de propriedade da Italac, podendo ser divulgadas apenas a quem de direito e devidamente reconhecido pela empresa.'
cHtml +=             '</span>'
cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serif'+"'"+';mso-fareast-language:PT-BR"></span></p>'
cHtml +=         '</td>'
cHtml +=     '</tr>
cHtml += '</table>'

DEFINE MSDIALOG oDlgMail TITLE "E-Mail" FROM 000, 000  To 415, 584 PIXEL

	//======
	// Para:
	//======
	@ 005, 006 Say oPara PROMPT "Para:" SIZE 015, 007 OF oDlgMail PIXEL
	@ 005, 030 MSGET oGetPara VAR cGetPara SIZE 256, 010 OF oDlgMail PICTURE "@x" PIXEL

	//===========
	// Com cópia:
	//===========
	@ 021, 006 Say oCc PROMPT "Cc:" SIZE 015, 007 OF oDlgMail PIXEL
	@ 021, 030 MSGET oGetCc VAR cGetCc SIZE 256, 010 OF oDlgMail PICTURE "@x" PIXEL

	//=========
	// Assunto:
	//=========
	@ 037, 006 Say oAssunto PROMPT "Assunto:" SIZE 022, 007 OF oDlgMail PIXEL
	@ 037, 030 MSGET oGetAssun VAR cGetAssun SIZE 256, 010 OF oDlgMail PICTURE "@x" PIXEL

	//==========
	// Mensagem:
	//==========
	@ 069, 006 Say oMens PROMPT "Mensagem:" SIZE 030, 007 OF oDlgMail PIXEL
	_oFont		:= TFont():New( 'Courier new' ,, 12 , .F. )
	_oScrAux	:= TSimpleEditor():New( 080 , 006 , oDlgMail , 285 , 105 ,,,,, .T. )
	
	_oScrAux:Load( cHtml )
	
	@ 189, 201 BUTTON oButEnv PROMPT "&Enviar"		SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 1 , cHtml := _oScrAux:RetText() , oDlgMail:End() ) PIXEL
	@ 189, 245 BUTTON oButCan PROMPT "&Cancelar"	SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 2 , oDlgMail:End() ) PIXEL

ACTIVATE MSDIALOG oDlgMail CENTERED

If nOpcA == 1
	cGetMens := AOMS054TT(cGetMens)
	//====================================
	// Chama a função para envio do e-mail
	//====================================
	U_ITENVMAIL( Lower(AllTrim(UsrRetMail(RetCodUsr()))), cGetPara, cGetCc, cMailCom, cGetAssun, cHtml, cGetAnx, _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

Else
	U_ITMsg( 'Envio de e-mail cancelado pelo usuário.' , 'Atenção!' , ,1 )
EndIf

Return

/*
===============================================================================================================================
Programa----------:AOMS054TT
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 12/02/2018
Descrição---------: Função criada para fazer a quebra de linha na mensagem digitada pelo usuário
Parametros--------: ExpC1	- Texto da mensagem
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS054TT(cGetMens)
Local aTexto	:= StrTokArr( cGetMens, chr(10)+chr(13) )
Local cRet		:= ""
Local nI		:= 0

For nI := 1 To Len(aTexto)
	cRet += aTexto[nI] + "<br>"
Next

Return(cRet)

/*
===============================================================================================================================
Programa----------: AOMS0547
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/06/2019
Descrição---------: Gatilho para campos Sedex
Parametros--------: _oModelDET - objeto dos detalhes da tela
Retorno-----------: _xretorno - Retorno do gatilho
===============================================================================================================================
*/
User Function AOMS0547(_oModelDET)

Local _xretorno := "N"

//Valida se a nota é Sedex
SC5->(DBSetOrder(1))
If SC5->(DBSeek(SF2->F2_FILIAL+SF2->F2_I_PEDID))

	If SC5->C5_I_NFSED == "S"

		_xretorno := "S"
		_oModelDET:LoadValue("ZZN_FILDEV",SC5->C5_FILIAL)
		_oModelDET:LoadValue("ZZN_DOCDEV",SC5->C5_I_NFREF)
		_oModelDET:LoadValue("ZZN_SERDEV",SC5->C5_I_SERNF)
		_oModelDET:LoadValue("ZZN_DTDEV",SC5->C5_EMISSAO)

	EndIf

EndIf

Return _xretorno

/*
===============================================================================================================================
Programa----------: SeMostraTela()
Autor-------------: Alex Wallauer
Data da Criacao---: 05/06/2023
Descrição---------: Verifica se falta confirmar datas do primeiro ou segundo percurso
Parametros--------: Nenhum
Retorno-----------: .F. ou .T.
===============================================================================================================================
*/
Static Function SeMostraTela()
Local _oModel   := FWModelActive()
Local _oModelMAS:= _oModel:GetModel('ZZNMASTER')
Local _cOperTriangular := AllTrim(SuperGetMV("IT_OPERTRI",.F.,"05,42"))// Tipos de operações da operação trigular
Local _cOperRemessa    := RIGHT(_cOperTriangular,2)//42
Local _cOperFat        := LEFT(_cOperTriangular,2)//05
Local _lPedidoPrincipal:= .F.
Local _lPedidoNormal   := .F.
Local _lMostraTela     := .F.
_lTemOpl  := .F.
_leOpLog  := .F.

DAI->(DBSetOrder(3))
If !Empty(SF2->F2_CARGA) .And. !DAI->(DBSeek(SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE))
   U_ITMsg("Não foi possível localizar (DAI) carga vinculada a nota " + SF2->F2_FILIAL + "/" + SF2->F2_DOC+" "+SF2->F2_SERIE,"Atenção",,1)
   Return .F./// RETORNA AQUI ***************************************************************************************
EndIf

_cCodOL  := ""//Preenchida dentro da U_Nfoplog()
_cLojaOP := ""//Preenchida dentro da U_Nfoplog()
_lTemOpl := U_Nfoplog(SF2->F2_FILIAL,SF2->F2_DOC,SF2->F2_SERIE) //NOTA TEM OPERADOR LOGISTICO ?

If _lTemOpl //Se tiver operador nos pedidos

   _leOpLog := (AllTrim(_cCodOL)) == AllTrim( _oModelMAS:GetValue( 'ZZN_FTRANS' ) )//SE É OPERADOR LOGISTICO SEGUNDA PERNA  

   If !_leOpLog .And. AllTrim(SF2->F2_I_CTRA) !=  AllTrim( _oModelMAS:GetValue( 'ZZN_FTRANS' ) ) 

	  U_ITMsg("CTE de transportador " + AllTrim( _oModelMAS:GetValue( 'ZZN_FTRANS' ) ) + " e nota " + SF2->F2_DOC + " registrada para " + ;
	  		  " transportador " + AllTrim(SF2->F2_I_CTRA) + " com operador logístico " + AllTrim(_cCodOL),;
	  		  "Atenção","CTE precisa ser do transportador ou do operador logístico para confirmar canhoto",1)

	  Return .F./// RETORNA AQUI ***************************************************************************************

   EndIf

EndIf

SC5->(DBSetOrder(1))
If SC5->(DBSeek(SF2->F2_FILIAL+AllTrim(SF2->F2_I_PEDID)))
   _lPedidoPrincipal:=(SC5->C5_I_OPER = _cOperRemessa .Or.  (SC5->C5_I_TRCNF == "S" .And. SC5->C5_NUM == SC5->C5_I_PDFT))// 42 - REMESSA .Or. TROCA NF FATURAMENTO
   _lPedidoNormal  :=(!SC5->C5_I_OPER $ _cOperTriangular .And.  SC5->C5_I_TRCNF <> "S")
Else
	  U_ITMsg("Pedido " + AllTrim( SF2->F2_I_PEDID) + " da nota " + SF2->F2_DOC + " "+SF2->F2_SERIE + " não encontrado ",;
	  		  "Atenção",,1)
   Return .F.
EndIf


If _lPedidoPrincipal .Or. _lPedidoNormal// ** TESTE PARA VER SE VAI ABRIR A TELA PARA O PEDIDO PRINCIPAL (42 OU TROCA NF FAT)  OU NORMAL**
   If !_lTemOpl .And. Empty(SF2->F2_I_DTRC)  //NAÕ TEM OPERADOR LOGISTICO
      _lMostraTela := .T.
   ElseIf _lTemOpl .And. _leOpLog .And. Empty(SF2->F2_I_DTRC) //TEM OPERADOR LOGISTICO E É O OPL - SEGUNDO TRECHO
      _lMostraTela := .T.
   ElseIf _lTemOpl .And. !_leOpLog .And.Empty(SF2->F2_I_DENOL) //TEM OPERADOR LOGISTICO E É NÃO O OPL - PRIMEIRO TRECHO
      _lMostraTela := .T.
   EndIf
EndIf

//Entra se precisar Mostrar Tela para o Pedido PRINCIPAL OU se NÃO For o pedido principal para buscar os dados do PRINCIPAL
If (_lMostraTela .Or. !_lPedidoPrincipal) .And. !_lPedidoNormal

	  //Verifica se não é nota de carregamento com nota de faturamento
	  _nRegSF2 := SF2->(RECNO()) //GUARDA POSIÇÃO ORIGINAL DA SF2
 	 
	  SC5->(DBSetOrder(1))
	  If SC5->(DBSeek(SF2->F2_FILIAL+AllTrim(SF2->F2_I_PEDID)))
	
		 If SC5->C5_I_OPER = '51' 
			_lPalletRetorno := .T.
		 EndIf
		 // ------------------ CONTROLE DA TRIANGULAR				
		 If SC5->C5_I_OPER = _cOperRemessa// 42 - REMESSA - PRINCIPAL
			_lTriangu := .T.
			_lReplica := .T.
		 ElseIf SC5->C5_I_OPER = _cOperFat// 05 - FATURAMENTO - GERADO - TEORICAMENTE NÃO VAI EXISTIR
			_lTriangu := .T.
			_lReplica := .F.
			If SC5->(DBSeek(SC5->C5_FILIAL+SC5->C5_I_PVREM))//  ************* POSICIONA NO PV DE REMESSA - PRINCIPAL
	 		   If SF2->(DBSeek(SC5->C5_FILIAL+SC5->C5_NOTA+SC5->C5_SERIE))//  ************* POSICIONA NA NOTA NO PV DE REMESSA - PRINCIPAL
		          _cOBSC   := "CANHOTO CONF NA NOTA DE REMESSA "+SF2->F2_FILIAL + "/" + SF2->F2_DOC
                  _cCodOL  := ""//Preenchida dentro da U_Nfoplog()
                  _lTemOpl := U_Nfoplog(SF2->F2_FILIAL,SF2->F2_DOC,SF2->F2_SERIE) //nota tem operador logistico
				  _leOpLog := .F.
                  If _lTemOpl  .And. !Empty(_cCodOL)//se tem op log ja verifica se o TRANSP DO CTE é o OPERADOR LOGISTICO 
	                 _leOpLog := (AllTrim(_cCodOL)) == AllTrim( _oModelMAS:GetValue( 'ZZN_FTRANS' ) )  
                  EndIf
                  // ** VOLTA PARA O PEDIDO PRINCIPAL PARA VER SE VAI ABRIR A TELA PARA O PEDIDO GERADO (05)  **
                  _lMostraTela := .F.
                  If !_lTemOpl .And. Empty(SF2->F2_I_DTRC)  
                     _lMostraTela := .T.
                  ElseIf _lTemOpl .And. _leOpLog .And. Empty(SF2->F2_I_DTRC ) 
                     _lMostraTela := .T.
                  ElseIf _lTemOpl .And. !_leOpLog .And. Empty(SF2->F2_I_DENOL ) 
                     _lMostraTela := .T.
                  EndIf

                  // ** SE NAO VAI ABRIR A TELA, REPLICA OS DADOS DO PEDIDO PRINCIPAL PARA O GERADO
				  If !_lMostraTela
                     If U_Repl2DtsTransTime( SF2->(RECNO()) , _cOBSC ) //Se replicou da 42 para a 05 não apresenta a tela
		                Return _lMostraTela /// RETORNA AQUI ***************************************************************************************
					 Else
                        _lMostraTela := .T.
					 EndIf
				  EndIf
			   EndIf
			EndIf
		 EndIf
		 // ------------------ CONTROLE DA TROCA NOTA
		 If SC5->C5_I_TRCNF == "S" .And. SC5->C5_NUM == SC5->C5_I_PDFT //PEDIDO DE FATURAMENTO - PRINCIPAL
			_lTrocaNF := .T.
			_lReplica := .T.
		 ElseIf SC5->C5_I_TRCNF == "S" .And. SC5->C5_NUM == SC5->C5_I_PDPR//PEDIDO DE CARREGAMENTO - GERADO
			_lTrocaNF := .T.
			_lReplica := .F.
			If SC5->(DBSeek(SC5->C5_I_FILFT+SC5->C5_I_PDFT))//  ************* POSICIONA NO PV DE FATURAMENTO - PRINCIPAL
	 		   If SF2->(DBSeek(SC5->C5_I_FILFT+SC5->C5_NOTA+SC5->C5_SERIE))
		          _cOBSC   := "CANHOTO CONF NA NOTA DE FATURAMENTO "+SF2->F2_FILIAL + "/" + SF2->F2_DOC
                  _cCodOL  := ""//Preenchida dentro da U_Nfoplog()
                  _lTemOpl := U_Nfoplog(SF2->F2_FILIAL,SF2->F2_DOC,SF2->F2_SERIE) //nota tem operador logistico
				  _leOpLog := .F.
                  If _lTemOpl .And. !Empty(_cCodOL)//se tem op log ja verifica se o TRANSP DO CTE é o OPERADOR LOGISTICO 
	                 _leOpLog := (AllTrim(_cCodOL)) == AllTrim( _oModelMAS:GetValue( 'ZZN_FTRANS' ) )  
                  EndIf
                  // ** VOLTA PARA O PEDIDO PRINCIPAL PARA VER SE VAI ABRIR A TELA PARA O PEDIDO GERADO (TROCA NF CARREGAMENTO) **
                  _lMostraTela := .F.
                  If !_lTemOpl .And. Empty(SF2->F2_I_DTRC)  
                     _lMostraTela := .T.
                  ElseIf _lTemOpl .And. _leOpLog .And. Empty(SF2->F2_I_DTRC ) 
                     _lMostraTela := .T.
                  ElseIf _lTemOpl .And. !_leOpLog .And.Empty(SF2->F2_I_DENOL ) 
                     _lMostraTela := .T.
                  EndIf

                  // ** SE NAO VAI ABRIR A TELA, REPLICA OS DADOS DO PEDIDO PRINCIPAL PARA O GERADO
				  If !_lMostraTela
                     If U_Repl2DtsTransTime( SF2->(RECNO()) , _cOBSC ) //Se replicou da FATURAMENTO para a CARREGAMENTO não apresenta a tela
		                Return _lMostraTela /// RETORNA AQUI ***************************************************************************************
					 Else
                        _lMostraTela := .T.
					 EndIf
				  EndIf
			   EndIf
			EndIf
		 EndIf
	  EndIf

EndIf

Return _lMostraTela
/*
===============================================================================================================================
Programa----------: Repl2DtsTransTime()
Autor-------------: Alex Wallauer
Data da Criacao---: 25/05/2023
Descrição---------: Atualiza todas as data de previstas e entragas na 05 da 42 e na 20 (carregamento) da troca nota
Parametros--------: _nRecnoSF2Atual = Recno do SF2 posicionado
Retorno-----------: .F. ou .T.
===============================================================================================================================
*/
User Function Repl2DtsTransTime( _nRecnoSF2Atual , _cOBSC )//CHAMADA DA MOMS016.PRW TAMBEM
Local _lRet:=.F. , T
Local _aOrd:= SaveOrd({"SC5","SF2"}) // Salva a ordem dos indices.

Local _cOperTriangular:= AllTrim(SuperGetMV("IT_OPERTRI",.F.,"05,42"))// Tipos de operações da operação trigular
Local _cOperRemessa   := RIGHT(_cOperTriangular,2)//42

Local _xF2_DTRC := SF2->F2_I_DTRC  // Entrega no Cliente (Dt.Canhoto)
Local _xF2_PENOL:= SF2->F2_I_PENOL // Previsão de entrega no operador logístico 
Local _xF2_PENCL:= SF2->F2_I_PENCL // Previsão de entrega no cliente
Local _xF2_DCHOL:= SF2->F2_I_DCHOL // Data de chegada no operador logístico 
Local _xF2_DCHCL:= SF2->F2_I_DCHCL // Data de chegada no cliente
Local _xF2_DENCL:= SF2->F2_I_DENCL // Data de entrega no cliente **
Local _xF2_DENOL:= SF2->F2_I_DENOL // Data de entrega no operador logístico  EDI  **
Local _xF2_PENCO:= SF2->F2_I_PENCO // Previsão de entrega no cliente (original)
Local _xF2_OUSER:= SF2->F2_I_OUSER // Usuario Informou o Op.Log
Local _xF2_ODATA:= SF2->F2_I_ODATA // Data inf.
Local _xF2_OHORA:= SF2->F2_I_OHORA // Hora Inf.
Local _xF2_CUSER:= SF2->F2_I_CUSER // Usuário de aprovação do canhoto. 
Local _xF2_CDATA:= SF2->F2_I_CDATA // Data de digitação do Canhoto. 
Local _xF2_CHORA:= SF2->F2_I_CHORA // hora de digitação do Canhoto. 
Local _xF2_CORIG:= SF2->F2_I_CORIG // Origem
Local _xF2_TT1TR:= SF2->F2_I_TT1TR // Transit Time 1o Trecho
Local _xF2_TT2TR:= SF2->F2_I_TT2TR // Transit Time 2o Trecho
Local _xF2_REDP := SF2->F2_I_REDP  // Transportadora de redespacho     
Local _xF2_RELO := SF2->F2_I_RELO  // Loja Transportadora de redespacho
Local _xF2_OPER := SF2->F2_I_OPER  // Operador Logistico               
Local _xF2_OPLO := SF2->F2_I_OPLO  // Loja do Operador Logistico      

Local aRecsSF2    := {}
Local _nRegrTriFat:= 0
Local _nRegrTransf:= 0
Local _nRegSF2    := 0
Local _nRegCopia  := 0

SC5->(DBSetOrder(1))
If SC5->(DBSeek(SF2->F2_FILIAL+AllTrim(SF2->F2_I_PEDID)))
   SF2->(DBSetOrder(1)) //F2_FILIAL+F2_DOC+F2_SERIE
   // ------------------ CONTROLE DA TRIANGULAR ------------------ //
   If SC5->C5_I_OPER = _cOperRemessa//42
      If SC5->(DBSeek(SC5->C5_FILIAL+SC5->C5_I_PVFAT))// POSICIONA NO PV DE FATURAMENTO
         If SF2->(DBSeek(SC5->C5_FILIAL+SC5->C5_NOTA+SC5->C5_SERIE))
            _nRegrTriFat:= SF2->(RECNO()) //GUARDA A POSIÇÃO DA SF2 NA NOTA NO PV DE FATURAMENTO
            _nRegCopia  := _nRegrTriFat//Copia os campos só se o pedido For 42 para 05
         EndIf
      EndIf
   EndIf

   // ------------------ CONTROLE DA TROCA NOTA ------------------ //
   If SC5->C5_I_TRCNF == "S" .And. SC5->C5_NUM == SC5->C5_I_PDFT .And. SC5->C5_I_OPER <> "20"// É PEDIDO DE FATURAMENTO , ATUALIZA O CARREGAMENTO
	  If SC5->(DBSeek(SC5->C5_I_FLFNC+SC5->C5_I_PDPR))
	     If SF2->(DBSeek(SC5->C5_I_FLFNC+SC5->C5_NOTA+SC5->C5_SERIE))
            _nRegrTransf:= SF2->(RECNO()) //GUARDA A POSIÇÃO DA SF2 NA NOTA NO PV DE CARREGAMENTO
  	     EndIf
	  EndIf
	EndIf
   aRecsSF2:={_nRegrTriFat,_nRegrTransf}
EndIf


For T := 1 To Len(aRecsSF2)
    _nRegSF2:=aRecsSF2[T]
    
	If _nRegSF2 > 0
    
	   SF2->(DBGoTo(_nRegSF2))
       SF2->(RecLock("SF2",.F.))

       SF2->F2_I_DTRC  := _xF2_DTRC  // Entrega no Cliente (Dt.Canhoto)
       SF2->F2_I_PENOL := _xF2_PENOL // Previsão de entrega no operador logístico 
       SF2->F2_I_PENCL := _xF2_PENCL // Previsão de entrega no cliente
       SF2->F2_I_DCHOL := _xF2_DCHOL // Data de chegada no operador logístico 
       SF2->F2_I_DCHCL := _xF2_DCHCL // Data de chegada no cliente
       SF2->F2_I_DENCL := _xF2_DENCL // Data de entrega no cliente
       SF2->F2_I_DENOL := _xF2_DENOL // Data de entrega no operador logístico  EDI // pode ser editado.
       SF2->F2_I_PENCO := _xF2_PENCO // Previsão de entrega no cliente (original)
       SF2->F2_I_OUSER := _xF2_OUSER // Usuario Informou o Op.Log
       SF2->F2_I_ODATA := _xF2_ODATA // Data inf.
       SF2->F2_I_OHORA := _xF2_OHORA // Hora Inf.
       SF2->F2_I_CUSER := _xF2_CUSER // Usuário de aprovação do canhoto. 
       SF2->F2_I_CDATA := _xF2_CDATA // Data de digitação do Canhoto. 
       SF2->F2_I_CHORA := _xF2_CHORA // hora de digitação do Canhoto. 
       SF2->F2_I_CORIG := _xF2_CORIG // Origem
       SF2->F2_I_TT1TR := _xF2_TT1TR // Transit Time 1o Trecho
       SF2->F2_I_TT2TR := _xF2_TT2TR // Transit Time 2o Trecho
       SF2->F2_I_OBRC  := _cOBSC     // Observacao
       If _nRegCopia = _nRegSF2//SÓ PEDIDO 05 da TRIANGULAR
          SF2->F2_I_REDP  := _xF2_REDP  // Transportadora de redespacho     
          SF2->F2_I_RELO  := _xF2_RELO  // Loja Transportadora de redespacho
          SF2->F2_I_OPER  := _xF2_OPER  // Operador Logistico               
          SF2->F2_I_OPLO  := _xF2_OPLO  // Loja do Operador Logistico      
       EndIf
       SF2->(MSUnLock())
	   _lRet:=.T.
	EndIf
Next

RestOrd(_aOrd)//VOLTA SC5 E SF2
SF2->(DBGoTo(_nRecnoSF2Atual))//POR GARANTIA

Return _lRet
/*
===============================================================================================================================
Programa----------: AOMS54Lista()
Autor-------------: Alex Wallauer
Data da Criacao---: 13/09/2024
Descrição---------: Buscar na ZZN se a Nfe tem algum registro, com Cte dirente do que esta sendo lançado e se encontrar listaros dados.
Parametros--------: lMensagem : .T. - MOSTRA / .F. - NÃO MOSTRA MENSAGEM  , oProc , _oModel , _lCanhoto
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AOMS54Lista(lMensagem,oProc,_oModel,_lCanhoto)
Local _aColZZN:={} , P 
Local _aCabZZN:={}
Local _aNotas :={}
Local nConta  :=0
Local _cOperTriangular:= AllTrim(SuperGetMV("IT_OPERTRI",.F.,"05,42"))
Local _cOperFat       := LEFT( _cOperTriangular,2)//05
Local _cOperRemessa   := RIGHT(_cOperTriangular,2)//42
Local _aOrd           := SaveOrd({"ZZN","SF2","SC5"}) // Salva a ordem dos indices.
Local _cFatura        := ""
Local _oModelMAS , _oModelDET
Default _lCanhoto := .F.

If ValType(_oModel) = "O"
   _oModelMAS  :=_oModel:GetModel('ZZNMASTER')
   _oModelDET  :=_oModel:GetModel('ZZNDETAIL')
   _cFatura    := cFilAnt+" "+_oModelMAS:GetValue("ZZN_FATURA") +" "+ _oModelMAS:GetValue( 'ZZN_FTRANS') +" "+ _oModelMAS:GetValue( 'ZZN_LOJAFT')
   _cChaveLinha:= cFilAnt    +_oModelMAS:GetValue("ZZN_FATURA")     + _oModelMAS:GetValue( 'ZZN_FTRANS')     + _oModelMAS:GetValue( 'ZZN_LOJAFT')
   _cZZNCTRANS :=_oModelDET:GetValue("ZZN_CTRANS")
   _cZZNSERCTR :=_oModelDET:GetValue("ZZN_SERCTR")
   _cZZNNFISCA :=_oModelDET:GetValue("ZZN_NFISCA")
   _cZZNSERIE  :=_oModelDET:GetValue("ZZN_SERIE")   
Else
   _cFatura    :=ZZN->ZZN_FILIAL+" "+ZZN->ZZN_FATURA+" "+ZZN->ZZN_FTRANS+" "+ZZN->ZZN_LOJAFT
   _cChaveLinha:=ZZN->ZZN_FILIAL    +ZZN->ZZN_FATURA    +ZZN->ZZN_FTRANS    +ZZN->ZZN_LOJAFT
   _cZZNCTRANS :=ZZN->ZZN_CTRANS //Linha do Lançamento
   _cZZNSERCTR :=ZZN->ZZN_SERCTR //Linha do Lançamento
   _cZZNNFISCA :=ZZN->ZZN_NFISCA
   _cZZNSERIE  :=ZZN->ZZN_SERIE
EndIf   

If _lCanhoto
   U_VISCANHO( cFilAnt, _cZZNNFISCA+_cZZNSERIE )
   RestOrd(_aOrd)
   Return .T.
EndIf

ZZN->(DBSetOrder(1))//ZZN_FILIAL+ZZN_FATURA+ZZN_FTRANS+ZZN_LOJAFT+ZZN_ITEM

If ZZN->(DBSeek(_cChaveLinha))
   While ZZN->(!Eof()) .And. ZZN->ZZN_FILIAL = cFilAnt .And. _cChaveLinha == ZZN->ZZN_FILIAL+ZZN->ZZN_FATURA+ZZN->ZZN_FTRANS+ZZN->ZZN_LOJAFT
      nConta++
      oProc:cCaption:='1/2 - Quantidade de NF Lidas: '+AllTrim(Str(nConta))+ " / "+AllTrim(Str(Len(_aNotas)))
      ProcessMessages()

	  _cChaveNF:=ZZN->(ZZN_FILIAL+ZZN_NFISCA+ZZN_SERIE)
      
	  If !SF2->( DBSeek( ZZN->(ZZN_FILIAL+ZZN_NFISCA+ZZN_SERIE) ) )
	     ZZN->(DBSkip())
	     Loop 
	  EndIf
      If !SC5->(DBSeek(SF2->F2_FILIAL+SF2->F2_I_PEDID))
	     ZZN->(DBSkip())
	     Loop 
	  EndIf
      
	  If aScan(_aNotas,{|P| P[1] == _cChaveNF } ) = 0
         aAdd(_aNotas,{ _cChaveNF, ZZN->ZZN_CTRANS+" "+ZZN->ZZN_SERCTR , ZZN->ZZN_ITEM , SC5->C5_NUM ,SC5->C5_I_OPER })
      EndIf
	  
      ZZN->(DBSkip())
   EndDo
EndIf

_aColZZN:={}
SC5->(DBSetOrder(1))
SF2->(DBSetOrder(1))
ZZN->(DBSetOrder(6))//ZZN_FILIAL+ZZN_NFISCA+ZZN_SERIE
For P := 1 To Len(_aNotas)

    oProc:cCaption:='2/2 - Quantidade de NF Lidas: '+AllTrim(Str(P))+ " / "+AllTrim(Str(Len(_aNotas)))
    ProcessMessages()
	If !ZZN->(DBSeek(_aNotas[P,1]) )
	   Loop 
	EndIf
    
    While ZZN->(!Eof()) .And. _aNotas[P,1] == ZZN->(ZZN_FILIAL+ZZN_NFISCA+ZZN_SERIE)
       
	   _nSalvaRecZZN:=ZZN->(RECNO())//Guarda recno da posicao atual
	   
	   If !SF2->( DBSeek( ZZN->(ZZN_FILIAL+ZZN_NFISCA+ZZN_SERIE) ) )
	      ZZN->(DBSkip())
	      Loop 
	   EndIf

       If !SC5->(DBSeek(SF2->F2_FILIAL+SF2->F2_I_PEDID))
	      ZZN->(DBSkip())
	      Loop 
	   EndIf
	   
	   If !Empty(SC5->C5_I_OPER)
          _cOperacao:=SC5->C5_I_OPER
	   Else
          _cOperacao:="Tipo Ped.: "+SC5->C5_TIPO
	   EndIf
	   
	   // TROCA NF               OU  TRIANGULAR  
       If SC5->C5_I_TRCNF = "S" .Or. SC5->C5_I_OPER $ _cOperTriangular 
          
          If SC5->C5_I_TRCNF = "S" 
		     _cTipoNF:="NF Troca nota"
		  ElseIf SC5->C5_I_OPER $ _cOperTriangular 
		     _cTipoNF:="NF Triangular"
		  EndIf
	      
		  If !_aNotas[P,2] == ZZN->ZZN_CTRANS+" "+ZZN->ZZN_SERCTR 
		     _cTipoNF+=", CTE diferente"
             _aColZZN := GrvLsta(_aColZZN,_cTipoNF,_aNotas[P])//GRAVA PRIMEIRA PERNA DE For DIFERENTE
             ZZN->(DBGoTo(_nSalvaRecZZN))
	         ZZN->(DBSkip())
			 Loop// Loop pq já busquei a segunda perna quando é o CTE igual (posicionado), senão duplica a segunda perna
	      EndIf
          
		  _cChave2P:=""
		  _cTipoNF :=""
          If SC5->C5_I_TRCNF = "S" .And. SC5->C5_I_OPER = "20" .And. SC5->C5_NUM == SC5->C5_I_PDPR
		     
             If SC5->(DBSeek(SC5->C5_I_FILFT+SC5->C5_I_PDFT))
			    _cTipoNF:="NF Troca nota, Ped. Fat. : "+SC5->C5_FILIAL+" "+SC5->C5_NUM
		        _cTipoNF+=", Oper.: "+SC5->C5_I_OPER
				_cChave2P:=SC5->C5_FILIAL+SC5->C5_NOTA+SC5->C5_SERIE
			 EndIf

          ElseIf SC5->C5_I_TRCNF = "S" .And. SC5->C5_I_OPER <> "20" .And. SC5->C5_NUM == SC5->C5_I_PDFT
          
             If SC5->(DBSeek(SC5->C5_I_FLFNC+SC5->C5_I_PDPR))
			    _cTipoNF:="NF Troca nota, Ped. Carr. : "+SC5->C5_FILIAL+" "+SC5->C5_NUM
		        _cTipoNF+=", Oper.: "+SC5->C5_I_OPER
				_cChave2P:=SC5->C5_FILIAL+SC5->C5_NOTA+SC5->C5_SERIE
			 EndIf
		  
		  ElseIf SC5->C5_I_TRCNF <> "S" .And. SC5->C5_I_OPER == _cOperFat//05
          
             If SC5->(DBSeek(SC5->C5_FILIAL+SC5->C5_I_PVREM))
		        _cTipoNF:="NF Triangular, Ped. Remessa : "+SC5->C5_NUM
		        _cTipoNF+=", Oper.: "+SC5->C5_I_OPER
				_cChave2P:=SC5->C5_FILIAL+SC5->C5_NOTA+SC5->C5_SERIE
			 EndIf

		  ElseIf SC5->C5_I_TRCNF <> "S" .And. SC5->C5_I_OPER == _cOperRemessa//42
		  
             If SC5->(DBSeek(SC5->C5_FILIAL+SC5->C5_I_PVFAT))
		        _cTipoNF:="NF Triangular, Ped. Fat. : "+SC5->C5_NUM
		        _cTipoNF+=", Oper.: "+SC5->C5_I_OPER
				_cChave2P:=SC5->C5_FILIAL+SC5->C5_NOTA+SC5->C5_SERIE
			 EndIf

		  EndIf

	      If !Empty(_cChave2P) .And. ZZN->(DBSeek( _cChave2P ))
             _aColZZN := GrvLsta(_aColZZN,_cTipoNF,_aNotas[P])//SEMPRE GRAVA SEGUNDA PERNA 
		  EndIf

	   Else

	      If !_aNotas[P,2] == ZZN->ZZN_CTRANS+" "+ZZN->ZZN_SERCTR 
             _aColZZN := GrvLsta(_aColZZN,"NF normal, CTE diferente",_aNotas[P])
	      EndIf

	   EndIf
       ZZN->(DBGoTo(_nSalvaRecZZN)) //Volta recno da posicao atual pq pode ter seeks no ZZN
	   ZZN->(DBSkip())
    EndDo
Next

If Len(_aColZZN ) > 0
	_aCabZZN:={}
	aAdd(_aCabZZN,"Filial"           )//ZZN_FILIAL
	aAdd(_aCabZZN,"Item"             )
	aAdd(_aCabZZN,"Nota Fiscal"      )//ZZN_NFISCA
	aAdd(_aCabZZN,"Cod. Transp."     )//ZZN_FTRANS
	aAdd(_aCabZZN,"Loja Transp."     )//ZZN_LOJAFT
	aAdd(_aCabZZN,"Nome Transp."     )//A2_NOME 
	aAdd(_aCabZZN,"Nome Red. Transp.")//A2_NREDUZ
    aAdd(_aCabZZN,"Fatura"           )//ZZN_FATURA
    aAdd(_aCabZZN,"Numero CTE"       )//ZZN_CTRANS
    aAdd(_aCabZZN,"Serie CTE"        )//ZZN_SERCTR
    aAdd(_aCabZZN,"Carga"            )//ZZN_CARGA
    aAdd(_aCabZZN,"Valor CTE"        )//ZZN_VLRCTR
    aAdd(_aCabZZN,"Dados Ped. Troca NF / Triangular"   )

	aAdd(_aCabZZN,"Item Atual"       )
	aAdd(_aCabZZN,"CTE Atual"        )
    aAdd(_aCabZZN,"Pedido NF Atual"  )
    aAdd(_aCabZZN,"Operacao NF Atual")

	U_ITListBox( 'Lista de CTE diferentes já lançados, Troca NF ou NF Triangular, Fatura '+_cFatura, _aCabZZN, _aColZZN , .T. , 1 )

Else
	If lMensagem
       U_ITMsg("Não foram encontrados CTE's diferentes, Troca NF ou NF Triangular para fatura: "+_cFatura,"ATENÇÃO",,1)	   
	EndIf
EndIf

RestOrd(_aOrd)

Return .T.

Static Function GrvLsta(_aColZZN,_cTipoNF,_aNotasLin)
Local _Itens:={}
       
aAdd(_Itens,ZZN->ZZN_FILIAL )// Pesquisado      
aAdd(_Itens,ZZN->ZZN_ITEM   )// Pesquisado 
aAdd(_Itens,ZZN->ZZN_NFISCA )// Pesquisado      
aAdd(_Itens,ZZN->ZZN_FTRANS )// Pesquisado      
aAdd(_Itens,ZZN->ZZN_LOJAFT )// Pesquisado      
aAdd(_Itens,Posicione("SA2",1,xFilial("SA2")+ZZN->ZZN_FTRANS + ZZN->ZZN_LOJAFT,"A2_NOME"))//Pesquisado 
aAdd(_Itens,SA2->A2_NREDUZ  )// Pesquisado     
aAdd(_Itens,ZZN->ZZN_FATURA )// Pesquisado      
aAdd(_Itens,ZZN->ZZN_CTRANS )// Pesquisado      
aAdd(_Itens,ZZN->ZZN_SERCTR )// Pesquisado      
aAdd(_Itens,ZZN->ZZN_CARGA  )// Pesquisado     
aAdd(_Itens,ZZN->ZZN_VLRCTR )// Pesquisado     
aAdd(_Itens,_cTipoNF        )// Pesquisado     

aAdd(_Itens,_aNotasLin[3])//"Item Atual"       
aAdd(_Itens,_aNotasLin[2])//"CTE Atual"        
aAdd(_Itens,_aNotasLin[4])//"Pedido NF Atual"  
aAdd(_Itens,_aNotasLin[5])//"Operacao NF Atual"

aAdd(_aColZZN,_Itens)

Return _aColZZN
