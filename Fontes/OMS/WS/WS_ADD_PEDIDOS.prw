/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor       |   Data   |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 09/01/20 | Chamado 31826. Tratamento para o armazem 70 e 72 e liberação do Pedido. 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 15/04/20 | Chamado 31826. Tratamento para gravar o Pedido no Portal (SWZ). 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 21/05/20 | Chamado 33016. Ajustes na importacao de PV via TXT para validar o preço conta a tabela de Preço. 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 02/10/20 | Chamado 33016. Gravacao do campo de percetual de leite magro. 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 26/10/20 | Chamado 33016. Validação se o Pedido do DW já foi integrado no SWZ. 
-------------------------------------------------------------------------------------------------------------------------------
Jerry        | 04/11/20 | Chamado 34582. Validar novo campo de Tabela de Preço. 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 11/11/20 | Chamado 33016. Alterações e tratamento das novas TAGs: FILCARREGAMENTO / TIPVEND . 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 03/11/20 | Chamado 33016. Correção da funcao GeraZWIDPED() . 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 11/12/20 | Chamado 33016. Alteraçao da gravação dos campos:  ZW_FECENT E ZW_I_AGEND . 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 18/12/20 | Chamado 33016. Nova validacao da comissao . 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 15/02/20 | Chamado 33016. Gravacao do campo ZW_TIMEEMI com FWTimeStamp( 4, DATE(), Time() ). 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 15/03/20 | Chamado 33016. Correção da validacao da comissao . 
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz    | 11/06/21 | Chamado 36795. Correção na gravação da filial de carregamento no pedido de vendas.
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 02/07/21 | Chamado 31826. Novos tratamentos para a filial de carregamento = "90I". 
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço | 13/08/21 | Chamado 37416. Retirado validação da Filial DA0 e DA1. 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 02/03/22 | Chamado 31826. Usar a Data de emissao que vem do WS: DATA_EMISSAO . 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 23/03/22 | Chamado 39557. Retirada da validacao de regras de comissao.  
-------------------------------------------------------------------------------------------------------------------------------
Jerry        | 12/05/22 | Chamado 40094. Adicionado Campo para Código de Evento (APAS). 
-------------------------------------------------------------------------------------------------------------------------------
Jerry        | 10/08/22 | Chamado 40977. Adicionado Campo para Código Cliente e Loja de Remessa para Op.Triangular. 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 12/03/24 | Chamado 46578. Gravacao do campo ZW_TPFRETE com a TAG TIPO_FRETE.
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 23/07/24 | Chamado 47894. Ajuste para grava o campo ZW_FILPRO=ZW_FILIAL quando o mesmo vem com Zero ou "ZZ".
================================================================================================================================================================================================
Analista      - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
================================================================================================================================================================================================
Jerry         - Alex Wallauer - 18/03/25 - 18/03/25 - 50230   - Correção do Ajuste para grava o campo ZW_FILPRO=ZW_FILIAL quando o mesmo vem com Zero ou "ZZ".
Jerry         - Julio Paz     - 08/04/25 - 11/04/25 - 49837   - Inclusão da nova Tag ITEMKITPORTAL e gravação nos campos ZW_KIT e C6_I_KIT.
Jerry         - Julio Paz     - 10/04/25 - 11/04/25 - 41527   - Inclusão da nova Tag RECEBE_SABADO e gravação nos campos ZW_I_RECSA no C5_I_RECSA.
Jerry         - Julio Paz     - 14/07/25 - 24/07/25 - 50433   - Realização de Ajustes nas Regras para Determinar o Armazém de Pedidos de Vendas do Portal - ZW_LOCAL.
================================================================================================================================================================================================

*/                                         
//====================================================================================================
// Definicoes de Includes da Rotina
//====================================================================================================
#Include "APWEBSRV.CH"
#Include "TOTVS.ch"
#Include "TBICONN.CH"
#Include "topconn.ch"
/*
===============================================================================================================================
Programa----------: WS_ADD_PEDIDOS
Autor-------------: TOTVS
Data da Criacao---: n/a
===============================================================================================================================
Descrição---------: Integração de Pedidos de Vendas 
===============================================================================================================================
Parametros--------: XML
===============================================================================================================================
Retorno-----------: Grava o PV
===============================================================================================================================
*/
//===========================================================================================================================
// ENDEREÇO PARA TESTES http://10.55.0.130:4003/ws/WANW001.apw?WSDL 
//===========================================================================================================================
// Tags dos detalhes do pedido. Aliementará a tabela SC6

WSSTRUCT tAddPedidoDet

	WSDATA	ITEMDW		  as string          // numero
	WSDATA	ITEMPRODUTO	  as string          // produto_codigo
	WSDATA	ITEMQTDE	  as float           // quantidade_un_1
	WSDATA	ITEMQTDE2UM	  as float OPTIONAL  // quantidade_un_2
	WSDATA	ITEMPRCTAB	  as float OPTIONAL  // valor_unitario_tabela_preco
	WSDATA	ITEMVALDESC	  as float OPTIONAL  // valor_total_descontos
	WSDATA	ITEMPERDESC	  as float OPTIONAL  // percentual_total_descontos
	WSDATA	ITEMPRCVEN	  as float OPTIONAL  // valor_unitario_venda
	WSDATA	ITEMPERCOMS	  as float OPTIONAL  // comissao_porcentagem
	WSDATA	ITEMNUMPCOM	  as string OPTIONAL // ordem_compra
	WSDATA  ITEMKITPORTAL as string OPTIONAL // Código do Kit no Portal

ENDWSSTRUCT

//===========================================================================================================================
// Cabeçalho do pedido de vendas. Alimentará a tabela SC5

WSSTRUCT tAddPedidoCab

	WSDATA  EMPRESA         	AS string OPTIONAL// cnpj
	WSDATA  FILIAL          	AS string OPTIONAL// cnpj
	WSDATA  CNPJ				AS String

	WSDATA PEDIDODW		as string // codigo
	WSDATA COND_PGTO	as string // condicao_pagamento_codigo
	WSDATA TABELAPRECO	as string OPTIONAL // tabela_preco_codigo
	WSDATA TRANSPORT	as string OPTIONAL // transportadora_codigo
	WSDATA VENDEDOR	 	as string OPTIONAL // vendedor_codigo
	WSDATA TIPVEND      as string OPTIONAL // Tipo de Venda C5_I_TPVEN
	WSDATA TIPO_FRETE	as string // frete_codigo
	WSDATA DATA_ENTREGA	as date // data_entrega
	WSDATA DATA_EMISSAO	as date OPTIONAL // data_emissao
	WSDATA VALOR_FRETE	as float OPTIONAL // valor_total_frete
	WSDATA COMISSAO		as float OPTIONAL // porcentagem_total_comissao
	WSDATA MENS_NOTA	as string OPTIONAL // mensagem_nota_fiscal
	WSDATA MENS_PEDIDO	as string OPTIONAL // observacao_comercial
	WSDATA DESCONTO		as float OPTIONAL // percentual_total_descontos
	WSDATA STATUS		as string // status
	WSDATA OPERACAO		as string // operacao_codigo
	WSDATA ORDEM_COMPRA	as string OPTIONAL // ordem_compra

	WSDATA TOT_C_IMPOST		as float OPTIONAL // valor_total_com_impostos
	WSDATA TOT_S_IMPOST		as float OPTIONAL // valor_total_sem_impostos
	WSDATA VALOR_DESC		as float OPTIONAL // valor_total_descontos
	WSDATA TOTAL_IPI		as float OPTIONAL // valor_total_ipi
	WSDATA TOTAL_ICMS		as float OPTIONAL // valor_total_icms
	WSDATA TOTAL_ICMS_ST	as float OPTIONAL //valor_total_st
	WSDATA TOTAL_DESCONT	as float OPTIONAL // valor_total_sem_descontos
	WSDATA TOTAL_IMPOSTOS	as float OPTIONAL  // valor_total_impostos
	WSDATA PESO_TOTAL		as float OPTIONAL  // peso_total
	WSDATA MOTIV_REPROV		as string OPTIONAL  // motivo_reprovacao_codigo
	WSDATA QTDE_FATURADA	as float OPTIONAL // total_quantidade_un_1_faturada
	WSDATA QTDE_PEDIDO		as float OPTIONAL // total_quantidade_un_1
	WSDATA HORA_EMISSAO		as string OPTIONAL // hora_emissao
	WSDATA ALCADA			as string OPTIONAL // alcada
	WSDATA ORIGEM_PEDIDO	as string OPTIONAL // origem
	WSDATA TOTAL_COMISSAO	as float OPTIONAL // valor_total_comissao
	WSDATA REPRESENTANTE	as string OPTIONAL // pedido_representante
	WSDATA DATA_FATURAM		as date OPTIONAL // data_faturamento
	WSDATA CUBAGEM			as float OPTIONAL // total_metragem_cubica
	WSDATA PEDIDO_ORIGEM	as string OPTIONAL // pedido_origem
	WSDATA NRO_EDICOES		as string OPTIONAL // edicoes
	WSDATA CONTATO_PED		as string OPTIONAL // contato_codigo
	WSDATA USUARIO			as string OPTIONAL // usuario_codigo
	WSDATA PENDENCIA		as string OPTIONAL // aceita_pendencia
	WSDATA VAL_DEONERADO	as float OPTIONAL // valor_total_desoneracao_icms
	WSDATA PV_BONIFIC		as string OPTIONAL // pedido_bonificado_codigo  
	WSDATA EVENTO           as string OPTIONAL // Evento APAS   
	     
	//DW
	WSDATA TIPOENTREGA	 	as string OPTIONAL // Tipo de Entrega (Imediato / Agendado / Agendado Com MultA
	WSDATA HORAENTREGA	 	as string OPTIONAL // Hora de Entrega  
	WSDATA SENHA	    	as string OPTIONAL // Senha
    WSDATA TIPCA            as string OPTIONAL // Tipo de Carga C5_I_TIPCA
	WSDATA CHAPA			as float OPTIONAL  // Qtd de Chapa
	WSDATA CUSTOENTREGA		as float OPTIONAL  // Custo de Entrega 
	WSDATA INFOENTREGA      as string OPTIONAL // Informação de Entrega do Cliente
	WSDATA FILCARREGAMENTO  as string OPTIONAL // Filial  C5_I_FLFNC
 	WSDATA FAIXA            as string OPTIONAL // Faixa de Peso para Gravar no Item do Pedido
	WSDATA ZW_CLIREM        as string OPTIONAL // Cliente Remessa Quando Pedido Operação Triangular
	WSDATA ZW_LOJEN         as string OPTIONAL // Loja do Cliente Remessa Quando Pedido Operação Triangular	
	WSDATA RECEBE_SABADO    as string OPTIONAL // Cliente Recebe aos Sabados S=Sim e N=Não
 	
	// itens do pedido
	WSDATA zzItensDoPedido	AS Array Of tAddPedidoDet

ENDWSSTRUCT
 
//==============================================================================================================================
// serviço de atualização de Pedidos de Vendas

WSSERVICE WANW001 DESCRIPTION "Serviço de atualização dos pedidos de vendas"

	WSDATA EMPRESA         	AS string OPTIONAL// cnpj
	WSDATA FILIAL          	AS string OPTIONAL// cnpj
	WSDATA CNPJ				AS String
	WSDATA tAddPedido		AS tAddPedidoCab
	WSDATA NumeroDoPedido	AS String
	WSDATA WsStrDel			AS String 

	WSMETHOD AddPedido      DESCRIPTION "Modo de Inclusão do Pedido de Vendas"

ENDWSSERVICE

//=============================================================================================================================
//Metodo para Inclusao do Pedido de Venda.

WSMETHOD AddPedido WSRECEIVE EMPRESA, FILIAL, CNPJ, tAddPedido WSSEND NumeroDoPedido WSSERVICE WANW001

Local aArea			:= {}
Local aCabDw		:= {}
Local aItemDw		:= {}
Local lReturn  		:= .T.
Local aRetIte		:= {}
Local cEmprWan		:= Upper(AllTrim(::Empresa))
Local cFilWan		:= Upper(AllTrim(::Filial))
Local aRecnoSM0		:= {}
Local lEmpres		:= .F.

Private cNumpedDW := ::tAddPedido:PEDIDODW
Private cCnpj	  := UnMaskCNPJ( ::CNPJ ) 
Private _lPortal  := U_ITGETMV("IT_INPORTAL",.T.) 


WSConOut("[WS_ADD_PEDIDOS] "+Repl("-",150))
WSConOut("[WS_ADD_PEDIDOS] INICIO AddPedido WSRECEIVE NUMERO DW, FILIAL: " + cNumpedDW + " " + cFilWan ) 

Private lMsErroAuto		:= .F.	// Variavel que define que o help deve ser gravado no arquivo de log e que as informacoes estao vindo a partir da rotina automatica
Private lMsHelpAuto		:= .T.	// Forca a gravacao das informacoes de erro em array para manipulacao da gravacao ao inves de gravar direto no arquivo temporario
Private lAutoErrNoFile	:= .T.
Private _nSeq			:= 0
Private _cNumPed		:= ""
Private _cFilPedido   	:= ""

_cFilAtual:= cFilAnt // Filial que esta logado
cFilAnt	 := cFilWan  // Filial que o pedido do portal esta selecionado para efetivacao 

// tratamento para carregar a empresa diretamente no fonte
aRecnoSM0	:=	{cEmprWan,cFilWan} //Posição 1 referente ao codigo da empresa, posição 2 referente a filial caso não seja informado no aParam
If !Empty(AllTrim(aRecnoSM0[01])) .And. !Empty(AllTrim(aRecnoSM0[02]))
     Reset Environment
     RPCSetType(3)
     If FindFunction("WFPREPENV")
          WfPrepENV(aRecnoSM0[1],aRecnoSM0[2])
          lAuto	:=	.T.
     Else
          Prepare Environment Empresa aRecnoSM0[1] Filial aRecnoSM0[2]
     EndIf
     lEmpres := .T.                                         
EndIf

aArea	:= FWGetArea()

WSConOut("[WS_ADD_PEDIDOS] WebService Pedido de Venda Filial "   ) 
WSConOut("[WS_ADD_PEDIDOS] Inicio: " + Time() + " Data: " + DToC(Date()))

// validações gerais do cabeçalho
aCabDw := WFADDCABDW(@::tAddPedido)            
If aCabDw[1]
	//WSConOut(oemtoansi("[WS_ADD_PEDIDOS] Pedido DW " + cNumpedDW + " está apto a passar pela validação dos itens para gerar Pedido de Vendas"))
	aItemDw := WFADDITDW(@::tAddPedido,@::tAddPedido:zzItensDoPedido)
	If aItemDw[1]
		//WSConOut(oemtoansi("[WS_ADD_PEDIDOS] Pedido DW " + cNumpedDW + " está apto a gerar Pedido de Vendas"))
		aRetIte := WSGRPED(@::tAddPedido, @::tAddPedido:zzItensDoPedido)
		If aRetIte[1]

            WSConOut("[WS_ADD_PEDIDOS] Retorno .T. - C5_I_PEDDW: "+cNumpedDW)
            If _lPortal

			   ::NumeroDoPedido := AllTrim(aRetIte[2])//SZW->ZW_IDPED
			
			Else
			
			   // Envio o número do pedido para o DW
			   cQuery := " SELECT COUNT(C5_NUM) QUANT, C5_NUM, C5_I_PEDDW "
			   cQuery += " from " + retSqlName("SC5") + " SC5 "
			   cQuery += " WHERE SC5.D_E_L_E_T_ = ' ' "
			   cQuery += " and C5_I_PEDDW = '" + cNumpedDW + " ' "
			   //cQuery += " and C5_FILIAL = '" + xFilial("SC5") + "' "
			   cQuery += " group by C5_I_PEDDW,C5_NUM "
   
               //WSConOut("[WS_ADD_PEDIDOS] cQuery: "+cQuery)
   
			   TCQuery cQuery NEW ALIAS "WSPED1"
   
			   If WSPED1->QUANT > 0
			   	  While WSPED1->(!Eof())
			   	  	 _cNumPed := AllTrim(WSPED1->C5_NUM)
			   	  	 ::NumeroDoPedido := AllTrim(_cNumPed)
			   	  	  WSPED1->(DBSkip())
			   	  EndDo
			   EndIf
			   WSPED1->(DBCloseArea())

			EndIf
		Else
			If !Empty(aRetIte[2])
				WSConOut("[WS_ADD_PEDIDOS] Retorno .F. - aRetIte[2]: "+aRetIte[2])
				SetSoapFault( "AddPedido" ,aRetIte[2])
			EndIf
			lReturn := .F.

		EndIf
		lValidaPed	:= .T.
	Else
		If !Empty(aItemDw[2])
			WSConOut("[WS_ADD_PEDIDOS] aItemDw[2]: "+aItemDw[2])
			SetSoapFault( "AddPedido" ,aItemDw[2])
		EndIf
		lReturn := .F.
	EndIf
Else
	If !Empty(aCabDw[2])
		WSConOut(aCabDw[2])
		SetSoapFault( "AddPedido" ,aCabDw[2])
	EndIf
	lReturn := .F.

EndIf

WSConOut("[WS_ADD_PEDIDOS] Fim: " + Time() + " Data: " + DToC(Date()))

If lEmpres
	RpcClearEnv()
EndIf

FWRestArea(aArea)

WSConOut("[WS_ADD_PEDIDOS] "+Repl("-",150))

Return( lReturn )

//===========================================================================================================================
// geração do pedido de vendas propriamente dita

Static Function WSGRPED(oObjSC5, oObjSC6)

Local aArea 		:= FWGetArea()
//Local lRetPv		:= .T.
//Local lOrdenaIt		:= .F.
//Local cQuery 		:= ""
//Local aItem     	:= {}
//Local _cPendC5		:= getNextAlias()
Local cItemSeq	:= Replicate( "0" , GetSx3Cache( "C6_ITEM" , "X3_TAMANHO" ) )
Local nItem     := 0
Local nItens  	:= 0
//Local cRastro	:= " "
Local nLimite	:= 999 // supergetmv("MV_NUMITEN",.F.,150)
Local _aDevol	:= {}
Local nItemPed	:= 0

Private cPedido 	:= ""
Private lRetItem  	:= .T.
Private _cDevol		:= ""
Private cOperC5 	:= AllTrim(oObjSC5:Operacao)

Private aCab 		:= {}
Private aItem		:= {}
Private aItens		:= {}
Private _lPortal  := U_ITGETMV("IT_INPORTAL",.T.)  


nItens := Len(oObjSC6)

For nItem := 1 To nItens

	If !Empty(oObjSC6[nItem]:ITEMPRODUTO)

		cItemSeq := Soma1(cItemSeq)

		If oObjSC5:DESCONTO > 0
			_nPrcVen := oObjSC6[nItem]:ITEMPRCVEN
//			_nPrcVen := _nPrcVen * (1-(oObjSC5:DESCONTO / 100))
//			_nPrcVen := Round(_nPrcVen,TamSX3("C6_PRCVEN")[02])
		Else
			_nPrcVen := oObjSC6[nItem]:ITEMPRCVEN
		EndIf
		//--> Campos fixos
		aAdd( aItem , { "C6_ITEM"  		, cItemSeq      							, NIL } )
		aAdd( aItem , { "C6_PRODUTO"	, oObjSC6[nItem]:ITEMPRODUTO				, NIL } )
		aAdd( aItem , { "C6_QTDVEN"  	, oObjSC6[nItem]:ITEMQTDE					, NIL } )
		aAdd( aItem , { "C6_UNSVEN" 	, oObjSC6[nItem]:ITEMQTDE2UM				, Nil } ) 
		aAdd( aItem , { "C6_PRCVEN"  	, _nPrcVen									, NIL } )
        If _lPortal
		   aAdd( aItem , { "C6_PRUNIT"  	, Round(oObjSC6[nItem]:ITEMPRCTAB,2)	, NIL } )
        EndIf
//		aAdd( aItem , { "C6_DESCONT"  	, oObjSC6[nItem]:ITEMPERDESC				, NIL } )
		aAdd( aItem , { "C6_NUMPCOM"  	, oObjSC5:ORDEM_COMPRA						, NIL } )
  		aAdd( aItem , { "C6_ITEMPC"  	, cItemSeq                                  , NIL } )
		aAdd( aItem , { "C6_ENTREG"  	, oObjSC5:DATA_ENTREGA						, NIL } )
		aAdd( aItem , { "C6_OPER"	  	, oObjSC5:OPERACAO							, NIL } ) 
		aAdd( aItem , { "C6_LOCAL"	  	, "70"          							, NIL } ) 	
		aAdd( aItem , { "C6_I_FXPES"  	, oObjSC5:FAIXA						        , NIL } )		
        aAdd( aItem , { "C6_I_KIT" 	    , oObjSC6[nItem]:ITEMKITPORTAL				, Nil } )  

		//

			If SC6->(FieldPos("C6_I_ITDW")) > 0
				If ValType(SC6->C6_I_ITDW) = "C"
					aAdd( aItem , { "C6_I_ITDW",oObjSC6[nItem]:ITEMDW, NIL } )
				ElseIf ValType(SC6->C6_I_ITDW) = "N"
					aAdd( aItem , { "C6_I_ITDW",Val(AllTrim(oObjSC6[nItem]:ITEMDW)), NIL } )
				EndIf
			EndIf

//		aItem := WsAutoOpc( @aItem , .T. )

		aAdd( aItens , aItem )
		aItem := {}
		nItemPed := nItemPed + 1
	EndIf

	// se o numeero do item lido + 1 For maior que o parametrizado, gero o cabeçalho do pedido de vendas
	If nItemPed + 1 > nLimite
		_nSeq := _nSeq + 1
		PutPvHead(oObjSC5,aItens)
		cItemSeq	:= Replicate( "0" , GetSx3Cache( "C6_ITEM" , "X3_TAMANHO" ) )
		nItemPed := 0
		aCab 	:= {}
		aItens 	:= {}
	EndIf

Next nItem

//pego o que sobrou para não ficar nada de fora
If Len(aItens) > 0
	_nSeq := _nSeq + 1
	PutPvHead(oObjSC5,aItens)
EndIf

FWRestArea(aArea)

aAdd(_aDevol, lRetItem)
aAdd(_aDevol, _cDevol)

Return ( _aDevol )

//============================================================================================================================
// geração do cabe?lho do pedido de vendas

Static Function PutPvHead(oObj,aItens)

Local cPedDw			:= AllTrim(oObj:PEDIDODW)
//Local cPedido			:= "AUTOMATICO"  
Local cCodigoCliente 	:= Posicione("SA1",03,xFilial("SA1") + cCnpj, "A1_COD")
Local cLojaCliente 		:= Posicione("SA1",03,xFilial("SA1") + cCnpj, "A1_LOJA")
Local cTipoCliente 		:= Posicione("SA1",03,xFilial("SA1") + cCnpj, "A1_TIPO")
Local _aProdutos:={}, P  , I
Local _cProdutos:=""
Local cArm  :=""
Local _aItem:={}
Local _nPosI:=0
Local _nPosQ:=0
Local _cFilAux:="" //, C
Local _cFilCarreg
Local _cTpPedVd, _nPosTpPv

If _nSeq > 1
	cPedDw := cPedDw + "-" + AllTrim(Str(_nSeq - 1))
EndIf
/*
DBSelectArea("SC5")
SC5->(DBSetOrder(1))
While (.T.)
	cPedido := GETSXENUM("SC5","C5_NUM")
	If !SC5->(DBSeek(xFilial("SC5") + cPedido))
		SC5->(rollbackSx8())
		Exit
	EndIf
	SC5->(ConfirmSX8())
EndDo   */

//_cFilCarreg := Space(2)
//If ! Empty(oObj:FILCARREGAMENTO)
   _cFilCarreg := oObj:FILCARREGAMENTO//LEFT(oObj:FILCARREGAMENTO,2)
//EndIf 

// zero o aCab
aCab 	:= {}                       
	aCab := {	{ "C5_FILIAL"	, oObj:FILIAL    			, Nil },;  //				{ "C5_NUM"		, cPedido	  	    		, NIL },;
				{ "C5_I_OPER" 	, oObj:OPERACAO				, Nil },;
				{ "C5_TIPO"   	, "N"	        			, Nil },;				
				{ "C5_CLIENTE"	, cCodigoCliente			, Nil },;
				{ "C5_LOJACLI"	, cLojaCliente	    		, Nil },;
				{ "C5_TIPOCLI"	, cTipoCliente 	    		, Nil },;
				{ "C5_VEND1"	, oObj:VENDEDOR				, Nil },;
				{ "C5_CLIENT"	, cCodigoCliente			, NIL },;
  				{ "C5_LOJAENT"	, cLojaCliente				, NIL },;//{ "C5_DESC1"	, oObj:DESCONTO				, NIL },;//
  				{ "C5_TRANSP"	, oObj:TRANSPORT			, NIL },;
  				{ "C5_CONDPAG"	, oObj:COND_PGTO			, NIL },;
  				{ "C5_I_TAB"	, oObj:TABELAPRECO			, NIL },;
  				{ "C5_I_PEDDW"	, AllTrim(cPedDw)			, NIL },;
  				{ "C5_MENNOTA"	, AllTrim(oObj:MENS_NOTA) 	, NIL },;
  				{ "C5_TPFRETE"	, oObj:TIPO_FRETE	  	  	, NIL },;
 				{ "C5_EMISSAO"  , oObj:DATA_EMISSAO			, NIL },;
 				{ "C5_I_DTENT"  , oObj:DATA_ENTREGA			, NIL },;
 				{ "C5_FECENT"   , oObj:DATA_ENTREGA			, NIL },;
 				{ "C5_I_OBPED"	, AllTrim(oObj:MENS_PEDIDO)	, NIL },;
 				{ "C5_I_TRCNF"	, "N"                   	, NIL },;
 				{ "C5_I_AGEND"	, oObj:TIPOENTREGA          , NIL },;
 				{ "C5_I_HOREN"  , oObj:HORAENTREGA          , NIL },;
 				{ "C5_I_SENHA"  , oObj:SENHA                , NIL },;
 				{ "C5_I_TIPCA"  , oObj:TIPCA                , NIL },;//"1"  
 				{ "C5_I_HORP"   , oObj:INFOENTREGA          , NIL },;
 				{ "C5_I_CHAPA"  , AllTrim(oObj:CHAPA)       , NIL },;
 				{ "C5_I_TPVEN"  , AllTrim(oObj:TIPVEND)     , NIL },;//"F"  
 				{ "C5_I_PEDDW"  , oObj:PEDIDODW				, NIL },;	
 				{ "C5_I_FLFNC"  , _cFilCarreg               , NIL },;//FILIAL DE PRODUCAO / CARREGAMENTO	 // LEFT(oObj:FILCARREGAMENTO,2)
 				{ "C5_I_EVENT"  , oObj:EVENTO				, NIL },;	
 				{ "C5_I_CLIEN"  , oObj:ZW_CLIREM			, NIL },;					
 				{ "C5_I_LOJEN"  , oObj:ZW_LOJEN 			, NIL },;									
 				{ "C5_I_CUSDE"  , oObj:CUSTOENTREGA         , NIL },;
				{ "C5_I_RECSA"  , If(Empty(oObj:RECEBE_SABADO),"N",oObj:RECEBE_SABADO), NIL }}  
/*
If _lPortal//SZW
   aCab2 := ACLONE(aCab)
   aCab2 := WsAutoOpc( @aCab2 )
    For C := 1 TO Len(aCab2)
       WSConOut(ARRTOKSTR(aCab2[C],";"))
	Next
Else
   aCab := WsAutoOpc( @aCab )
    For C := 1 TO Len(aCab)
       WSConOut(ARRTOKSTR(aCab[C],";"))
	Next
EndIf*/

_nPosI:=aScan(aCab, {|I| I[1] == "C5_FILIAL"  } )
If _nPosI <> 0
   _cFilAux:=aCab[_nPosI,2]
EndIf
If Empty(_cFilAux)
   _cFilAux:=xFilial("SC5")
EndIf

_aProdutos:={}
_cProdutos:=""
//_cItensZAE:=""
//_cCodVend :=LEFT(oObj:VENDEDOR,Len(ZAE->ZAE_VEND))

//ZAE->(DBSetOrder(4)) // ZAE_FILIAL+ZAE_VEND+ZAE_PROD+ZAE_GRPVEN+ZAE_CLI+ZAE_LOJA

For P := 1 TO Len(aItens)
   _aItem:=aItens[P]//Linha
   _nPosI:=aScan(_aItem, {|I| I[1] == "C6_PRODUTO" } )
   _nPosQ:=aScan(_aItem, {|I| I[1] == "C6_QTDVEN"  } )
   aAdd(_aProdutos,{_aItem[_nPosI,2],;//1
                    _aItem[_nPosQ,2],;//2
					0, ;//3
					0, ;//4
					""})//5
   _cProdutos+=_aItem[_nPosI,2]+";"
/*
   WSConOut("Seek no ZAE : "+_cCodVend+_aItem[_nPosI,2]) 
   If !ZAE->(DBSeek(xFilial("ZAE")+_cCodVend+_aItem[_nPosI,2]))  .OR.;
                                          ZAE->ZAE_MSBLQL = '1'  .OR.;
										  !Empty(ZAE->ZAE_GRPVEN) .OR.;
										  !Empty(ZAE->ZAE_CLI   ) .OR.;
										  !Empty(ZAE->ZAE_LOJA  ) 
   	  _cItensZAE += "["+AllTrim(_aItem[_nPosI,2])+"] "
      WSConOut("Erro no ZAE : ZAE_MSBLQL ="+ZAE->ZAE_MSBLQL) 
   EndIf*/

Next
/*
If !Empty(_cItensZAE)
   _cDevol := "[WS_ADD_PEDIDOS] Produtos: "+_cItensZAE+" nao possui regra de comissao ou bloqueada."
   WSConOut(_cDevol)
   _lRet := lRetItem := .F.
   Return
EndIf*/

If !_lPortal

   _cProdutos:=LEFT(_cProdutos,Len(_cProdutos)-1)
   
   WSConOut("[WS_ADD_PEDIDOS] INICIO Ver_Est_PV() "+_cProdutos+" Len(_aItem) = "+Str(Len(_aItem)))
      
   _lRet := Ver_Est_PV(_cFilAux,_aProdutos,@_cProdutos)//Verefica se tem estoque nos armazens indicados no parametro IT_WSPVARM
   
   If !_lRet
   	  _cDevol := "[WS_ADD_PEDIDOS] Pedido com saldo insuficiente nos produtos: "+_cProdutos+ "."
   	  WSConOut(_cDevol)
   	  lRetItem := .F.
   	  Return
   Else
   	  For P := 1 TO Len(aItens)
   	  	_aItem:=aItens[P]//Linha
  	    _nPosL:=aScan(_aItem, {|I| I[1] == "C6_LOCAL" } )
  	    _nPosI:=aScan(_aItem, {|I| I[1] == "C6_PRODUTO" } )
		_cProduto:=_aItem[_nPosI,2]
		cArm:=""
		If (_nPosA:=aScan(_aProdutos,{|S| S[1]==_cProduto} ))
		   cArm:=_aProdutos[_nPosA,5]
   	  	   _aItem[_nPosL,2]:=cArm
		EndIf	 
   	    WSConOut("[WS_ADD_PEDIDOS] Arm.: "+cArm+" sera ultilizado para o produto: "+_cProduto+ ".")
   	  Next   	
   EndIf
EndIf


// geração do pedido de vendas
If Len(aCab) > 0 .And. Len(aItens) > 0
   //================================================================================
   // Definir o tipo de venda com base nas regras da tabela de preços.
   //================================================================================
   _cTpPedVd := DefTPPedVd(aItens, oObj:OPERACAO, AllTrim(oObj:TIPVEND), oObj:TABELAPRECO, _cFilAux)
   If AllTrim(oObj:TIPVEND) <> _cTpPedVd
      _nPosTpPv := aScan(aCab, {|x| x[1] == "C5_I_TPVEN"})
	  aCab[_nPosTpPv,2] := _cTpPedVd  
   EndIf
   //================================================================================

	WSConOut ("[WS_ADD_PEDIDOS] Inicio da Montando PEDIDO. PV posicionado: " + SC5->C5_FILIAL+"-"+SC5->C5_NUM)

    _cAOMS074:=""//Pega as mensagens de erro do MT410TOK.prw  // ITALAC

	begintran()                                    

	If _lPortal
       
	   WSConOut ("[WS_ADD_PEDIDOS] GRAVANDO PV VIA PORTAL [SZW]")
	   _cDevol:=GravaPortal(aCab,aItens,_cFilAux)//SZW->ZW_IDPED
    
	Else

	   WSConOut ("[WS_ADD_PEDIDOS] GRAVANDO PV VIA MSEXECAUTO [SC5]")
   
//	   MSExecAuto({|a,b,c,d| MATA410(a,b,c,d)}, aCabec,aItens, nOpcX,.F.)
	   MsExecAuto({|x,y,z,d| MATA410(x,y,z,d)} ,aCab  ,aItens, 3    ,.F.)

    EndIf

	WSConOut ("[WS_ADD_PEDIDOS] Final da Montagem do PEDIDO. PV posicionado: " +  SC5->C5_FILIAL+"-"+SC5->C5_NUM)

	If lMsErroAuto

		aAutoErro := GETAUTOGRLOG()
		_cDevol := "[WS_ADD_PEDIDOS] Resultado - [ERRO]: " + AllTrim(XCONVERRLOG(aAutoErro))
		WSConOut(_cDevol)
		If !Empty(_cAOMS074)// ITALAC
		    WSConOut("[WS_ADD_PEDIDOS] _cAOMS074: "+AllTrim(_cAOMS074))
		   _cDevol += " [MT410TOK]: "+AllTrim(_cAOMS074)// ITALAC
		EndIf// ITALAC
		lRetItem := .F.

	ElseIf !_lPortal

	    WSConOut ("[WS_ADD_PEDIDOS] LIBERANDO o Pedido: " + SC5->C5_FILIAL+"-"+SC5->C5_NUM+"/ Pedido DW: " + AllTrim(oObj:PEDIDODW))
		If !Ver_Lib_PV(SC5->C5_FILIAL+SC5->C5_NUM)//LIBERA O PEDIDO SE INCLUIDO COM SUCESSO
			_cDevol := "[WS_ADD_PEDIDOS] Resultado - NAO foi possivel LIBERAR (SC9) o Pedido: "+SC5->C5_FILIAL+"-"+SC5->C5_NUM+"/ Pedido DW: " + AllTrim(oObj:PEDIDODW)
			WSConOut(_cDevol)
			lRetItem := .F.
		    DisarmTransaction()			
		Else
	        WSConOut ("[WS_ADD_PEDIDOS] Resultado - LIBEROU o Pedido: "+SC5->C5_FILIAL+"-"+SC5->C5_NUM+"/ Pedido DW: " + AllTrim(oObj:PEDIDODW))
			// Zero as variaeis temporarias
			cItemSeq	:= Replicate( "0" , GetSx3Cache( "C6_ITEM" , "X3_TAMANHO" ) )
			nItemPed := 0
			aCab 	:= {}
			aItens 	:= {}
	    EndIf

	EndIf
	endtran()
Else
	If Len(aCab) == 0
		_cDevol := oemtoansi("[WS_ADD_PEDIDOS] Resultado - Pedido DW " + AllTrim(oObj:PEDIDODW) + " - Problema no cabeçalho do pedido do cliente " + cCNPJ  + ".")
		lRetItem := .F.
	ElseIf Len(aItens) == 0
		_cDevol :=  oemtoansi("[WS_ADD_PEDIDOS] Resultado - Pedido DW " + AllTrim(oObj:PEDIDODW) + " - Problema nos itens do pedido do cliente " + cCNPJ  + ".")
		lRetItem := .F.
	EndIf
	WSConOut(_cDevol)
EndIf

Return
//============================================================================================================================
// Validações do cabeçalho de vendas
Static Function WFADDCABDW(oSC5Tmp)

Local lExiste 	:= .T.
Local cMsg		:= ""
Local cQuery 	:= ""
Local _cAliasDw	:= ""
//Local _aArea	:= ""
//Local cSA1Fil	:= xFilial( "SA1" )
Local _aRet		:= {}
Local  _lPortal  := U_ITGETMV("IT_INPORTAL",.T.) 

// pedido já existe no protheus?
_cAliasDw := getNextAlias()

If _lPortal
   cQuery := " SELECT ZW_IDPED AS C5_NUM "
   cQuery += " FROM " + RETSQLTAB("SZW")
   cQuery += " WHERE SZW.D_E_L_E_T_ = ' '
   cQuery += " and ZW_I_PEDDW LIKE '%" + cNumpedDW + "%' "
Else
   cQuery := " SELECT C5_NUM  "
   cQuery += " FROM " + RETSQLTAB("SC5")
   cQuery += " WHERE SC5.D_E_L_E_T_ = ' '
   //cQuery += " and C5_FILIAL = '" + xFilial("SC5") + "' "
   cQuery += " and C5_I_PEDDW LIKE '%" + cNumpedDW + "%' "
EndIf

dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),_cAliasDw,.T.,.T.)

If !Empty((_cAliasDw)->C5_NUM)
	lExiste := .F.
	cMsg := oemtoansi("[WS_ADD_PEDIDOS] Pedido DW " + cNumpedDW + " com Cliente do CNPJ " + cCnpj  + " Já integrado anteriormente, PV Protheus: "+(_cAliasDw)->C5_NUM)
EndIf
(_cAliasDw)->(DBCloseArea())            

// CNPJ existe no Protheus?
If lExiste
	If Empty(cCnpj)
		lExiste := .F.
		cMsg := oemtoansi("[WS_ADD_PEDIDOS] Pedido DW " + cNumpedDW + " sem CNPJ / CPF informado!")
	Else
		SA1->(DBSetOrder(03)) // A1_FILIAL+A1_CGC
		If SA1->(!DBSeek(xFilial("SA1") + cCnpj))
			lExiste := .F.
			cMsg := oemtoansi("[WS_ADD_PEDIDOS] Pedido DW " + cNumpedDW + " - Cliente do CNPJ " + cCnpj  + " não encontrado. Verificar cadastro de clientes.")
  		Else
  			If SA1->(FieldPos("A1_MSBLQL")) > 0
				If SA1->A1_MSBLQL == "1"
                   SA1->(RecLock("SA1",.F.))
				   SA1->A1_MSBLQL:="2"
				   If SA1->A1_VENCLC >= Date()
				      SA1->A1_VENCLC :=(DATE()-1)
				   EndIf 
				   SA1->(MSUnLock())
				//	lExiste := .F.
					WSConOut("[WS_ADD_PEDIDOS] Pedido DW " + cNumpedDW + " - Cliente do CNPJ " + cCnpj  + " está com cadastro BLOQUEADO. FOI DESBLOQUEADO")
				EndIf
			EndIf  
		EndIf
	EndIf
EndIf

// demais dados do cabeçalho do pedido de vendas é valido?
// Tipo de frete é válido?
If lExiste
	If (!oSC5Tmp:TIPO_FRETE $ "C#F#T#R#D#S") .Or. Empty(oSC5Tmp:TIPO_FRETE)
		lExiste := .F.
		cMsg := oemtoansi("[WS_ADD_PEDIDOS] Pedido DW " + cNumpedDW + " - tipo de frete " + oSC5Tmp:TIPO_FRETE  + " é inválido..")
	EndIf
EndIf

// condição de pagamento existe e é válida?
If lExiste 
	If Empty(oSC5Tmp:COND_PGTO)
	   If !_lPortal
		  lExiste := .F.
		  cMsg := oemtoansi("[WS_ADD_PEDIDOS] Pedido DW " + cNumpedDW + " - condição de pagamento não informada.")
	   EndIf
	Else
		DBSelectArea("SE4")
		DBSetOrder(01)
		If !DBSeek(xFilial("SE4") + PadR(AllTrim(oSC5Tmp:COND_PGTO),TamSX3("E4_CODIGO")[01]))
			lExiste := .F.
			cMsg := oemtoansi("[WS_ADD_PEDIDOS] Pedido DW " + cNumpedDW + " - está com condição de pagamento inválida.")
		EndIf

	EndIf
EndIf

// Se informada, a tabela de preços existe?
If lExiste
	If !Empty(oSC5Tmp:TABELAPRECO)
		DBSelectArea("DA0")
		DBSetOrder(01)
		If !DBSeek(xFilial("DA0") + PadR(AllTrim(oSC5Tmp:TABELAPRECO),TamSX3("DA0_CODTAB")[01]))
			lExiste := .F.
			cMsg := oemtoansi("[WS_ADD_PEDIDOS] Pedido DW " + cNumpedDW + " - está com tabela de preços inválida.")
		EndIf
	EndIf
EndIf

aAdd(_aRet,lExiste)
aAdd(_aRet,cMsg)

Return(_aRet)
//============================================================================================================================
// Validações do item de vendas
Static Function WFADDITDW(oSC5Tmp,oSC6Tmp)

Local lExiste 	:= .T.
Local cMsg		:= ""
Local _aItPed	:= oSC6Tmp
Local nItens 	:= 0
Local nItem 	:= 0
Local _aRet		:= {}

nItens := Len(_aItPed)

For nItem := 1 To nItens

	If lExiste
		DBSelectArea("SB1")
		DBSetOrder(01)
		If DBSeek(xFilial("SB1") + oSc6Tmp[nItem]:ITEMPRODUTO)
			// o produto está ativo no cadastro?
			If SB1->(FieldPos("B1_MSBLQL")) > 0
				If SB1->B1_MSBLQL == "1"
					lExiste := .F.
					cMsg := oemtoansi("[WS_ADD_PEDIDOS] Pedido DW " + cNumpedDW + " - produto " + AllTrim(oSc6Tmp[nItem]:ITEMPRODUTO)  + " está com cadastro BLOQUEADO.")
				EndIf
			EndIf
		EndIf
	EndIf

	If lExiste
		// a quantidade foi informada?
		If oSc6Tmp[nItem]:ITEMQTDE == 0
			lExiste := .F.
			cMsg := oemtoansi("[WS_ADD_PEDIDOS] Pedido DW " + cNumpedDW + " - produto " + AllTrim(oSc6Tmp[nItem]:ITEMPRODUTO)  + " está com quantidade zerada.")
		EndIf
	EndIf

	If lExiste
		//caso não exista tabela de preços ou o produto não esteja em uma tabela de preços, o preço unitário deve ser informado
		If Empty(oSC5Tmp:TABELAPRECO)
			If oSc6Tmp[nItem]:ITEMPRCVEN == 0
				lExiste := .F.
				cMsg := oemtoansi("[WS_ADD_PEDIDOS] Pedido DW " + cNumpedDW + " - produto " + AllTrim(oSc6Tmp[nItem]:ITEMPRODUTO)  + " está sem preço.")
			EndIf
		Else
			DBSelectArea("DA1")
			DBSetOrder(01)
			If !DBSeek(xFilial("DA1") + PadR(AllTrim(oSC5Tmp:TABELAPRECO),TamSX3("DA1_CODTAB")[01])+ PadR(AllTrim(oSc6Tmp[nItem]:ITEMPRODUTO),TamSX3("DA1_CODPRO")[01]) )
				// se não encontrar o preço na tabela de preços, sou obrigado a ter o preço do produto
				If Empty(oSC5Tmp:TABELAPRECO)
					If oSc6Tmp[nItem]:ITEMPRCVEN == 0
						lExiste := .F.
						cMsg := oemtoansi("[WS_ADD_PEDIDOS] Pedido DW " + cNumpedDW + " - produto " + AllTrim(oSc6Tmp[nItem]:ITEMPRODUTO)  + " possui tabela de preços, mas não possui um preço.")
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
	// demais campos do item de vendas estão OK?

Next nItem

aAdd(_aRet,lExiste)
aAdd(_aRet,cMsg)

Return(_aRet)

//===========================================================================================================================
// remove a mascara do CNPJ
Static Function UnMaskCNPJ( cCNPJ )

Local cCNPJClear := cCNPJ

Begin Sequence

	If Empty( cCNPJClear )

		BREAK
	EndIf

	cCNPJClear := StrTran( cCNPJClear , "." , "" )
	cCNPJClear := StrTran( cCNPJClear , "/" , "" )
	cCNPJClear := StrTran( cCNPJClear , "-" , "" )
	cCNPJClear := AllTrim( cCNPJClear )

End Sequence

Return( cCNPJClear )

//===========================================================================================================================
// converte error log

Static Function xConverrLog(aAutoErro)

Local cRet := ""
Local _nI   := 1

For _nI := 1 to Len(aAutoErro)
	cRet += CRLF+AllTrim(aAutoErro[_nI])
Next _nI

Return cRet

//==========================================================================================================================
//Retorna data e Hora Atual Convertido em Caracter
/*
Static Function xDatAt()

Local cRet	:=	""
cRet	:=	CRLF+"("+DToC(DATE())+" "+TIME()+")"

Return cRet*/


/*
===============================================================================================================================
Programa--------: Ver_Lib_PV(cChave)
Autor-----------: Alex Wallauer
Data da Criacao-: 09/01/2019
===============================================================================================================================
Descrição-------: Verefica se no SC9 esta tudo OK ou tenta liberar o Pedido
===============================================================================================================================
Parametros------: cChave: Filia + Pedido, 
==============================================================================================================================
Retorno---------: Lógico (.F.) Tá com erro (.T.) Tá tudo OK
===============================================================================================================================
*/
*====================================================================================================*
Static Function Ver_Lib_PV(cChave)
*====================================================================================================*
Local _lOK:=.T.//Não Tem erro
Local _nQtdLib:=0

SC6->( DBSetOrder(1) )//C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
If !SC6->( DBSeek( cChave ) )
	_lOK:=.F.//Tem erro
EndIf

SC9->( DBSetOrder(1) )//
While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == cChave
	
	If !SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))
		_nQtdLib := MaLibDoFat(SC6->(RecNo()),SC6->C6_QTDVEN)//LIBERA ITEM DO PEDIDO
	EndIf

	If SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))
       If SC9->C9_QTDLIB <> SC6->C6_QTDVEN  		        	 
		  _lOK:=.F.//Tem erro
		  Exit 
       ElseIf !Empty(SC9->C9_BLEST)  	
		  _lOK:=.F.//Tem erro
		  Exit 
	   EndIf
	Else
	   _lOK:=.F.//Tem erro
	   Exit 
	EndIf
	SC6->( DBSkip() )
	
EndDo

Return _lOK

/*
===============================================================================================================================
Programa--------: Ver_Est_PV
Autor-----------: Alex Wallauer
Data da Criacao-: 09/01/2019
===============================================================================================================================
Descrição-------: Verefica se tem estoque nos armazens indicados no parametro IT_WSPVARM
===============================================================================================================================
Parametros------: cFil,_aProdutos,_cProdutos
==============================================================================================================================
Retorno---------: Return _cArmA ou _cArmB ou ""
===============================================================================================================================
*/
*====================================================================================================*
Static Function Ver_Est_PV(cFil,_aProdutos,_cProdutos)
*====================================================================================================*
//Local _lOKA:=.T.
//Local _lOKB:=.T.
Local _cQuery:=""  
Local _cAlias:= GetNextAlias()
Local _cArm  :=U_ITGETMV("IT_WSPVARM",'20;22')//'70;72'
Local _cArmA :=SubStr(_cArm,1,2)//'70'
Local _cArmB :=SubStr(_cArm,4,2)//'72'
Local nPos:=0

_cQuery += " SELECT DISTINCT B2_COD,"
_cQuery += "        NVL ((SELECT (B2_QATU - (B2_QEMP + B2_RESERVA + B2_QACLASS))"
_cQuery += "             FROM " + RetSqlName("SB2")+ " SB270"
_cQuery += "            WHERE     SB270.B2_FILIAL = SB2.B2_FILIAL"
_cQuery += "                  AND SB270.B2_COD = SB2.B2_COD"
_cQuery += "                  AND SB270.B2_LOCAL = '"+_cArmA+"' "
_cQuery += "                  AND SB270.D_E_L_E_T_ = ' '),0)  SALDO70,"
_cQuery += "       NVL ((SELECT (B2_QATU - (B2_QEMP + B2_RESERVA + B2_QACLASS))"
_cQuery += "             FROM " + RetSqlName("SB2")+ " SB272"
_cQuery += "            WHERE     SB272.B2_FILIAL = SB2.B2_FILIAL"
_cQuery += "                  AND SB272.B2_COD = SB2.B2_COD"
_cQuery += "                  AND SB272.B2_LOCAL = '"+_cArmB+"' "
_cQuery += "                  AND SB272.D_E_L_E_T_ = ' '),0)  SALDO72 "
_cQuery += "  FROM " + RetSqlName("SB2")+ " SB2 "
_cQuery += " WHERE     B2_FILIAL = '"+cFil+"' "
_cQuery += "       AND B2_COD IN "+FormatIn(_cProdutos,";")//('00020020301', '00020010301', '00010115901', '00030010601','10030000467')
_cQuery += "       AND B2_LOCAL IN " + FormatIn(AllTrim(_cArm),";")//('"+_cArmA+"', '"+_cArmB+"') "
_cQuery += "       AND SB2.D_E_L_E_T_ = ' ' "

//WSConOut("WS_ADD_PEDIDOS] "+_cQuery)
//_cFileNome:="\DATA\ITALAC\WS\WS_PV_"+DToS(DATE())+"_"+StrTran(TIME(),":","_")+".TXT"
//MemoWrite(_cFileNome,_cQuery)

DBUSEAREA(.T., "TOPCONN", TCGenQry(,,_cQuery), _cAlias, .T., .F.)
DBSelectArea(_cAlias)

While !Eof()
   If (nPos:=aScan(_aProdutos, {|P| AllTrim(P[1]) == AllTrim((_cAlias)->B2_COD) } )) <> 0
      _aProdutos[nPos,3]:=(_cAlias)->SALDO70
      _aProdutos[nPos,4]:=(_cAlias)->SALDO72
   EndIf
//	_cDevol := "[WS_ADD_PEDIDOS] "+(_cAlias)->B2_COD+": "+_cArmA+": "+Str( (_cAlias)->SALDO70 )+" / "+_cArmB+": "+Str( (_cAlias)->SALDO72 )
//	WSConOut(_cDevol)
   DBSkip()
EndDo

(_cAlias)->(DBCloseArea())

_cProdutos:=""

For nPos := 1 TO Len(_aProdutos)
    If _aProdutos[nPos,2] <= _aProdutos[nPos,3]//20,70
       _aProdutos[nPos,5]:=_cArmA
	   _cDevol := "[WS_ADD_PEDIDOS] "+_aProdutos[nPos,1]+": QTDE: "+Str( _aProdutos[nPos,2] )+" / ["+_cArmA+"]: "+Str( _aProdutos[nPos,3] )+" / "+_cArmB+": "+Str( _aProdutos[nPos,4] )
    ElseIf _aProdutos[nPos,2] <= _aProdutos[nPos,4]//22,72
       _aProdutos[nPos,5]:=_cArmB
	   _cDevol := "[WS_ADD_PEDIDOS] "+_aProdutos[nPos,1]+": QTDE: "+Str( _aProdutos[nPos,2] )+" / "+_cArmA+": "+Str( _aProdutos[nPos,3] )+" / ["+_cArmB+"]: "+Str( _aProdutos[nPos,4] )
	Else
	   _cDevol := "[WS_ADD_PEDIDOS] "+_aProdutos[nPos,1]+": QTDE: "+Str( _aProdutos[nPos,2] )+" / "+_cArmA+": "+Str( _aProdutos[nPos,3] )+" / "+_cArmB+": "+Str( _aProdutos[nPos,4] )
       _cProdutos+=_aProdutos[nPos,1]+","
    EndIf
	WSConOut(_cDevol)
Next

_cProdutos:=LEFT(_cProdutos,Len(_cProdutos)-1)//ITENS SEM ARMAZEM

If Empty(_cProdutos)// SE TODOS OS ITENS COM ARMAZEM
   Return .T.
Else// SE ALGUM ITEM SEM ARAMZEM
   Return .F.
EndIf

*==========================================*
Static Function WSConOut(cMensagem)
*==========================================*
//Local _cFileNome:="\DATA\ITALAC\WS\WS_PV_"+DToS(DATE())+"_"+StrTran(TIME(),":","_")+".TXT"

U_ITConOut(cMensagem)

//MemoWrite(_cFileNome,cMensagem)

Return

/*
===============================================================================================================================
Programa----------: GravaPortal
Autor-------------: Alex Wallauer
Data da Criacao---: 03/04/2020
===============================================================================================================================
Descrição---------: Processamento de Importação de DADOS DO Sistema Blokers/Italac
===============================================================================================================================
Parametros--------: aCab,aItens
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function GravaPortal(aCab,aItens,_cFilAux)
Local _nCpo
Local cFili  :=_cFilAux//aCab[aScan(aCab,{|C| C[1] == "C5_FILIAL"  } ) , 2  ]
Local cVend  :=aCab[aScan(aCab,{|C| C[1] == "C5_VEND1"   } ) , 2  ]
Local cPVDW  :=aCab[aScan(aCab,{|C| C[1] == "C5_I_PEDDW" } ) , 2  ]
Local cTaPr  :=aCab[aScan(aCab,{|C| C[1] == "C5_I_TAB"  } ) , 2  ]
Local cClie  :=aCab[aScan(aCab,{|C| C[1] == "C5_CLIENTE" } ) , 2  ]
Local cLoja  :=aCab[aScan(aCab,{|C| C[1] == "C5_LOJACLI" } ) , 2  ]
Local cCond  :=aCab[aScan(aCab,{|C| C[1] == "C5_CONDPAG" } ) , 2  ]
Local cOper  :=aCab[aScan(aCab,{|C| C[1] == "C5_I_OPER"  } ) , 2  ]
Local cMenNf :=aCab[aScan(aCab,{|C| C[1] == "C5_MENNOTA" } ) , 2  ]//<MENS_NOTA>
Local cHora  :=aCab[aScan(aCab,{|C| C[1] == "C5_I_HOREN" } ) , 2  ]//<HORAENTREGA>
Local nQtdCha:=aCab[aScan(aCab,{|C| C[1] == "C5_I_CHAPA" } ) , 2  ]//<CHAPA>
Local nCusDes:=aCab[aScan(aCab,{|C| C[1] == "C5_I_CUSDE" } ) , 2  ]//<CUSTOENTREGA>
Local cSenha :=aCab[aScan(aCab,{|C| C[1] == "C5_I_SENHA" } ) , 2  ]//<SENHA>
Local cObs   :=aCab[aScan(aCab,{|C| C[1] == "C5_I_OBPED" } ) , 2  ]//<MENS_PEDIDO>
Local cFilPRO:=aCab[aScan(aCab,{|C| C[1] == "C5_I_FLFNC" } ) , 2  ]//FILIAL DE PRODUCAO/CARREGAMENTO
Local cTpVevd:=aCab[aScan(aCab,{|C| C[1] == "C5_I_TPVEN" } ) , 2  ]//Tipo de Venda
Local cTpCarg:=aCab[aScan(aCab,{|C| C[1] == "C5_I_TIPCA" } ) , 2  ]//Tipo de Carga
Local cTpAgen:=aCab[aScan(aCab,{|C| C[1] == "C5_I_AGEND" } ) , 2  ]//Tipo de Agendamento
Local dDtEmis:=aCab[aScan(aCab,{|C| C[1] == "C5_EMISSAO" } ) , 2  ]//Data de Emissao
Local cEvento:=aCab[aScan(aCab,{|C| C[1] == "C5_I_EVENT" } ) , 2  ]//Evento
Local cCliRem:=aCab[aScan(aCab,{|C| C[1] == "C5_I_CLIEN" } ) , 2  ]//Cliente Remessa 
Local cLojRem:=aCab[aScan(aCab,{|C| C[1] == "C5_I_LOJEN" } ) , 2  ]//Loja Cliente Remessa 
Local cTpfret:=aCab[aScan(aCab,{|C| C[1] == "C5_TPFRETE" } ) , 2  ]//Tipo do frete
Local _cRecSabad :=aCab[aScan(aCab,{|C| C[1] == "C5_I_RECSA" } ) , 2  ]// Cliente Recebe aos Sabados

Local _cCodSWZ:=GeraZWIDPED(cVend)
Local _nPerLMagro:=0
Local nQtdeM:=0
Local nQtdeI:=0
Local cFx := ""
Local _cKitPortal := ""

If !Empty(cObs)
//    cObs:=cObs+" "+"Pedido Importado WS: "+cPVDW
Else
    cObs:="Pedido Importado WS: "+cPVDW
EndIf

If Empty(cFilPRO) .Or. AllTrim(cFilPRO) == "0" .Or. AllTrim(cFilPRO) == 'ZZ'
   cFilPRO:=cFili
EndIf

If Empty(cTpAgen)
   cTpAgen:="I"
EndIf

ConOut("Data de Emissao: "+AllToChar(dDtEmis)+" / ValType(dDtEmis) = "+ValType(dDtEmis))

SB1->(DBSetOrder(1))
For _nCpo := 1 TO Len(aItens)
	_aDados:=aItens[_nCpo]
    cProd:=_aDados[aScan(_aDados,{|C| C[1] == "C6_PRODUTO" } ) , 2  ]
    nQtde:=_aDados[aScan(_aDados,{|C| C[1] == "C6_QTDVEN"  } ) , 2  ]
	SB1->(DBSeek(xFilial()+LEFT(cProd,11)))
    If SB1->B1_I_TIPLT = "M"
	   nQtdeM+=nQtde
    ElseIf SB1->B1_I_TIPLT = "I"
       nQtdeI+=nQtde
    EndIf
 //   WSConOut("[WS_ADD_PEDIDOS] Produto.: "+cProd+", B1_I_TIPLT : "+SB1->B1_I_TIPLT + ", QTDE: "+AllToChar(nQtde))
Next   	
If nQtdeM <> 0 //.AND. nQtdeI <> 0
   _nPerLMagro:=((nQtdeM / (nQtdeM+nQtdeI))*100)
   WSConOut("[WS_ADD_PEDIDOS] (nQtdeM ["+AllToChar(nQtdeM)+"]  / ( ["+AllToChar(nQtdeM)+"] + nQtdeI ["+AllToChar(nQtdeI)+"] ))*100 = _nPerLMagro ["+AllToChar(_nPerLMagro)+"]  ")
EndIf

DA1->(DBSetOrder(1))
SA1->(DBSetOrder(1))
SA1->(DBSeek(xFilial()+cClie+cLoja ))

If Empty(cCond)
   cCond:=SA1->A1_COND
EndIf
_cTimeStamp:=FWTimeStamp( 4, DATE(), Time() )
_nItem:=0
For  _nCpo := 1 TO Len(aItens)
	//CAPA
	SZW->(RecLock("SZW",.T.))
	SZW->ZW_FILIAL := cFili
	SZW->ZW_CODEMP := "010"
	SZW->ZW_IDPED  := _cCodSWZ//SubStr(cVend,3,4)+"-"+_cCodSWZ//cPVDW
	SZW->ZW_EMISSAO:= If(ValType(dDtEmis)="D" .And. !Empty(dDtEmis),dDtEmis,DATE())
	SZW->ZW_TIMEEMI:= _cTimeStamp
	SZW->ZW_IDUSER := cVend
	SZW->ZW_VEND1  := cVend
	SZW->ZW_TABELA := cTaPr
	SZW->ZW_STATUS := "A"
	SZW->ZW_CLIENTE:= SA1->A1_COD
	SZW->ZW_LOJACLI:= SA1->A1_LOJA
	SZW->ZW_CLIENT := SZW->ZW_CLIENTE
	SZW->ZW_LOJAENT:= SZW->ZW_LOJACLI
	SZW->ZW_CONDPAG:= cCond
	SZW->ZW_TPFRETE:= cTpfret//"C"
	SZW->ZW_TIPO   := cOper//"01"
	SZW->ZW_TIPOCLI:= SA1->A1_TIPO//"R"
	SZW->ZW_TIPCAR := If(AllTrim(cTpCarg)="1","1","2") //"2"//"1 - Paletizada" , "2 - Batida"
	SZW->ZW_MENNOTA:= cMenNf //<MENS_NOTA>
	SZW->ZW_HOREN  := cHora  //<HORAENTREGA>
	SZW->ZW_CHAPA  := nQtdCha//<CHAPA>
	SZW->ZW_CUSDES := nCusDes//<CUSTOENTREGA>
	SZW->ZW_SENHA  := cSenha //<SENHA>
	SZW->ZW_PEDIMPO:= cPVDW
	SZW->ZW_I_PEDDW:= cPVDW
	SZW->ZW_I_LMAGR:= _nPerLMagro 
    SZW->ZW_FILPRO := LEFT(cFilPRO,2)
	SZW->ZW_CLIREM := cCliRem
    SZW->ZW_LOJEN   := cLojRem

	If Empty(_cRecSabad) 
	   SZW->ZW_I_RECSA := "N"
	Else 
	   SZW->ZW_I_RECSA := _cRecSabad
	EndIf 

	//ITENS
	_aDados:=aItens[_nCpo]
    cProd:=_aDados[aScan(_aDados,{|C| C[1] == "C6_PRODUTO" } ) , 2  ]
    nQtde:=_aDados[aScan(_aDados,{|C| C[1] == "C6_QTDVEN"  } ) , 2  ]
    nQSeg:=_aDados[aScan(_aDados,{|C| C[1] == "C6_UNSVEN"  } ) , 2  ]
    nPrec:=_aDados[aScan(_aDados,{|C| C[1] == "C6_PRCVEN"  } ) , 2  ]
	nPrUN:=_aDados[aScan(_aDados,{|C| C[1] == "C6_PRUNIT"  } ) , 2  ]
//	cLoca:=_aDados[aScan(_aDados,{|C| C[1] == "C6_LOCAL"   } ) , 2  ]
	cItDW:=_aDados[aScan(_aDados,{|C| C[1] == "C6_I_ITDW"  } ) , 2  ]
	cPdCl:=_aDados[aScan(_aDados,{|C| C[1] == "C6_NUMPCOM" } ) , 2  ]//<ORDEM_COMPRA>
	dDEnt:=_aDados[aScan(_aDados,{|C| C[1] == "C6_ENTREG"  } ) , 2  ]
	cFx         :=_aDados[aScan(_aDados,{|C| C[1] == "C6_I_FXPES" } ) , 2  ]
	_cKitPortal :=_aDados[aScan(_aDados,{|C| C[1] == "C6_I_KIT" } ) , 2  ] 

	If Empty(cFx)
	   cFx:="1"
	EndIf 

    WSConOut("DATA DE ENTREGA: "+AllToChar(dDEnt))

	_nItem++
	SZW->ZW_PRODUTO:= LEFT(cProd,11)
	SB1->(DBSeek(xFilial()+SZW->ZW_PRODUTO))
	DA1->(DBSeek(xFilial("DA1")+SZW->ZW_TABELA+SZW->ZW_PRODUTO))
	SZW->ZW_ITEM   := AllTrim(Str( _nItem , Len(SZW->ZW_ITEM) ))
	SZW->ZW_UM     := SB1->B1_UM
	SZW->ZW_QTDVEN := nQtde
	SZW->ZW_PRCVEN := nPrec
	SZW->ZW_PRUNIT := nPrUN
	SZW->ZW_OBSCOM := cObs//<MENS_PEDIDO>
	SZW->ZW_HORAINC:= Time()
	SZW->ZW_2UM    := SB1->B1_SEGUM
	SZW->ZW_I_PRNET:= SZW->ZW_PRCVEN
	SZW->ZW_I_AGEND:= cTpAgen//"I"
	SZW->ZW_PEDCLI := cPdCl//"NT"//<ORDEM_COMPRA>	
//  If SZW->ZW_TIPO  = "01"
    If Upper(cTpVevd)  = "F"
	   SZW->ZW_TPVENDA := 'V'
	   SZW->ZW_I_PRMP := DA1->DA1_I_PMFR
	Else
	   SZW->ZW_TPVENDA := 'F'
	   SZW->ZW_I_PRMP := DA1->DA1_I_PMFE
	EndIf
//  SZW->ZW_LOCAL  := cLoca
	If SZW->(FIELDPOS( "ZW_I_ITDW" )) <>  0
	   SZW->ZW_I_ITDW:=cItDW
	EndIf

//	If cFilPRO = "90I"
//       SZW->ZW_LOCAL  := "36"
//	Else
//	   cArm:= Posicione("SBZ",1,SZW->ZW_FILPRO+SZW->ZW_PRODUTO,"BZ_LOCPAD")
//	   If cArm $ "20/36"
//	      SZW->ZW_LOCAL  := "20"
//       Else
//	      SZW->ZW_LOCAL  := "22"
//	   EndIf
//	EndIf

   //======================================
   // Nova regra para obter o Armazém.  
   //======================================
   cArm:= Posicione("SBZ",1,SZW->ZW_FILPRO+SZW->ZW_PRODUTO,"BZ_LOCPAD") 
   SZW->ZW_LOCAL  := cArm
   //--------------------------------------

    If SB1->B1_CONV > 0
       If SB1->B1_TIPCONV = 'D'
          SZW->ZW_SEGQTD:=(SZW->ZW_QTDVEN/SB1->B1_CONV)
       Else
          SZW->ZW_SEGQTD:=(SZW->ZW_QTDVEN*SB1->B1_CONV)
       EndIf
    Else
   	   SZW->ZW_SEGQTD:=nQSeg
   	EndIf
	If cTpAgen == "I"
	   If !ZG5->(DBSeek(xFilial()+SZW->ZW_FILPRO+SA1->A1_EST+SA1->A1_COD_MUN ))
	      If !ZG5->(DBSeek(xFilial()+SZW->ZW_FILPRO+SA1->A1_EST))
	         SZW->ZW_FECENT := (DATE()+1)
	      Else   
	         SZW->ZW_FECENT := DATE()+ZG5->ZG5_DIAS+1
	      EndIf   
	   Else   
	      SZW->ZW_FECENT := DATE()+ZG5->ZG5_DIAS+1
	   EndIf
	Else   
	   SZW->ZW_FECENT :=dDEnt
	EndIf

/*
	If cFilPRO = "90I" //TEMPORARIO ATE ARUMAR COMECAR A VIR OPERACAO 25
	   SZW->ZW_TIPO   := '25'
	   SZW->ZW_TABELA := "120"
	EndIf
*/

	SZW->ZW_I_FXPES := Val(cFx)   //Faixa de Peso da tabela de preço
	SZW->ZW_EVENTO  := cEvento
    SZW->ZW_KIT     := _cKitPortal 
	SZW->(MSUnLock())

Next

Return SZW->ZW_IDPED


/*
===============================================================================================================================
Programa----------: GeraZWIDPED()
Autor-------------: Alex Wallauer
Data da Criacao---: 06/01/2020
===============================================================================================================================
Descrição---------: Gera oproximo ZW_IDPED
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function GeraZWIDPED(_cCodVen)
Local _cAlias:= GetNextAlias()

_cQuery:=" SELECT  NVL(MAX(ZW_IDPED),'0') AS CODIGO FROM "+ RetSqlName('SZW') +" SZW WHERE ZW_VEND1 = '"+_cCodVen+"' "

DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAlias , .T., .F. )

(_cAlias)->( DBGoTop() )
If (_cAlias)->(!Eof()) .And. (_cAlias)->CODIGO <> '0'
    nAt:=AT("-",(_cAlias)->CODIGO)
	_cRet := LEFT( (_cAlias)->CODIGO,nAt )
	_cRet := _cRet + Soma1( AllTrim(SubStr( (_cAlias)->CODIGO,nAt+1)) )
Else
	_cRet := AllTrim(Str(Val(_cCodVen)))+"-00001"
EndIf

If Empty(_cRet)//Para garantir não devolver branco
   _cRet := AllTrim(Str(Val(_cCodVen)))+"-00001"
EndIf

(_cAlias)->(DBCloseArea())
DBSelectArea("SZW")

Return _cRet

/*
===============================================================================================================================
Programa----------: DefTPPedVd
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/06/2021
===============================================================================================================================
Descrição---------: Define o tipo de pedido de vendas com base nas regras das tabelas de preços (F= Venda Fracionada, 
                    C=Venda Fechada).
===============================================================================================================================
Parametros--------: _aItensPv - Itens do pedido de vendas.
                    _cOperacao - Código da Operação.
					_cTpPvPortal - Tipo de pedido de vendas portal.
					_cTabPrcPortal - Código da tabela de Preços do Portal
===============================================================================================================================
Retorno-----------: _cTipoPV  - Tipo de pedido de vendas.
===============================================================================================================================
*/
Static Function DefTPPedVd(_aItensPv, _cOperacao, _cTpPvPortal, _cTabPrcPortal, _cFilialPV)
Local _cTipoPV := _cTpPvPortal
Local _nPosProd, _nPosQtd
Local _nI, _nPesTot

Begin Sequence 
   If AllTrim(_cOperacao) == "24"
      If Empty(_cFilialPV) .Or. Empty(_cTabPrcPortal)
         Break 
	  EndIf 

      DA0->(DBSetOrder(1))
	  SB1->(DBSetOrder(1))

      _nPosProd := aScan(_aItensPv[1], {|x| x[1] == "C6_PRODUTO" } )
      _nPosQtd  := aScan(_aItensPv[1], {|x| x[1] == "C6_QTDVEN"  } )
      _nPesTot  := 0

	  If DA0->(MsSeek(xFilial("DA0")+_cTabPrcPortal))
	     For _nI := 1 To Len(_aItensPv)
		     SB1->(MsSeek(xFilial("SB1")+_aItensPv[_nI,_nPosProd,2]))
             _nPesTot += (_aItensPv[_nI,_nPosQtd,2] * SB1->B1_PESBRU )
         Next 
	     		 
         If _nPesTot < DA0->DA0_I_PES1
            _cTipoPV := "F"  
		 Else 
		    _cTipoPV := "C" 
		 EndIf 

	  EndIf
   EndIf

End Sequence

Return _cTipoPV

