/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |10/06/2025| Chamado 45229. Retirada do parâmetro p/determinar se a integração WebS. será TMS Multiembarcador ou 
			  |			 | RDC para chamar a U_IT_TMS(_cLocEmb).
Alex Wallauer |10/06/2025| Chamado 45229. Tratamento para validar FWIsInCallStack("U_AOMS085B") junto com FWIsInCallStack("U_ALTERAP")
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
-==============================================================================================================================
*/

#Include "TOTVS.ch"

Static lStaticRet:=.T.
/*
===============================================================================================================================
Programa----------: MT410ACE
Autor-------------: Alexandre Villar
Data da Criacao---: 24/02/2014
Descrição---------: Ponto de entrada antes de operações de Exclusão/Cópia/Alteração no Pedido de Vendas para validar acesso
Parametros--------: Nenhum
Retorno-----------: _lRet - lógico indicando se vai poder alterar ou não o pedido de vendas
===============================================================================================================================
*/
User Function MT410ACE()

Local _lRet			:= .T.
Local _nOpc			:= ParamIXB[1]  // 2-Visualiza, 3-Copia, 4-Alteracao, 1-Excluir  - Inclusão não passa por aqui
Local oproc 		
Local _lshow    := .F.
Local _cTextoMsg 

//====================================================================================================
// Se é visualização não faz NADA
//====================================================================================================
If _nopc == 2 .Or. FWIsInCallStack("A410VISUAL")
   Return .T.
EndIf

Public _aLogSC5	:= {}
Public _aLogSC6	:= {}
Public _cActLog	:= IIf(_nopc==3 .Or. _nopc == 4 .Or. _nopc == 1,"A","")
Public _dDtLgC5	:= Date()
Public _cTmLgC5 := Time()
lMsErroAuto	:= .F.  

Begin Sequence

//====================================================================================================
// Se veio do webservice já retorna .T.
//====================================================================================================
If FWIsInCallStack("U_ALTERAP") .Or. FWIsInCallStack("U_INCLUIC") .Or. FWIsInCallStack("U_AOMS085B")
	U_ITCONOUT("PROCESSOU MT410ACE - PV: "+SC5->C5_NUM)
	Break
EndIf

//====================================================================================================
// Verifica se abriu via sigamdi ou sigaadv para mostrar telas e mensagens
//====================================================================================================
If (FWIsInCallStack("MDIEXECUTE") .Or. FWIsInCallStack("SIGAADV"))
	_lshow := .T.
EndIf

//====================================================================================================
// Sequência principal de validações com e sem mensagens na tela
//====================================================================================================
If _lshow
    _cTextoMsg := "Fazendo Lock em tabelas de muro TMS para o pedido "  

	FWMsgRun(,{|oproc| _lRet := VLDALT(_nopc,oproc,_lshow,_lRet)},"Aguarde...", "Validando acesso a alteração/exclusão de pedido " + SC5->C5_NUM + "...")
	FWMsgRun(,{|oproc| _lRet := VLDEXC(_nopc,oproc,_lshow,_lRet)},"Aguarde...", "Validando bloqueio de cliente para exclusão " + SC5->C5_NUM + "...")
	FWMsgRun(,{|oproc| _lRet := VLDTRI(_nopc,oproc,_lshow,_lRet)},"Aguarde...", "Validando operação triangular do pedido " + SC5->C5_NUM + "...")
	FWMsgRun(,{|oproc| _lRet := LOCKMU(_nopc,oproc,_lshow,_lRet)},"Aguarde...", _cTextoMsg + SC5->C5_NUM + "...")
Else
	_lRet := VLDALT(_nopc, oproc,_lshow,_lRet)
	_lRet := VLDEXC(_nopc,oproc,_lshow,_lRet)
	_lRet := VLDTRI(_nopc,oproc,_lshow,_lRet)
	_lRet := LOCKMU(_nopc,oproc,_lshow,_lRet)	
EndIf

End Sequence

//============================================================================================
//Inicio de gravação de log de alteração de pedido, não realizar validações após esse ponto
//============================================================================================
If _lRet .And.  _lshow .And. (_nopc == 4 .Or. _nopc == 1)

	FWMsgRun( ,{|| _aLogSC5 := U_ITIniLog( 'SC5' ) }, 'Aguarde!' , 'Iniciando o controle de logs da capa...'   )
	INILOG6(_nopc,oproc,_lshow,_lRet)

ElseIf _lRet .And.  (_nopc == 4 .Or. _nopc == 1)

	_aLogSC5 := U_ITIniLog( 'SC5' )
	INILOG6(_nopc,oproc,_lshow,_lRet)
		
EndIf

//============================================================================================
//Só altera o conteudo do lMsErroAuto se ele tiver Falso e o retorno For falso
//============================================================================================
If Type("lMsErroAuto") = "L" .And. !_lRet .And. !lMsErroAuto
   lMsErroAuto:=!_lRet//Só Joga verdadeiro de For o caso
EndIf

If !_lRet .And.  FWIsInCallStack("U_AOMS109")
	_lOK_RDC := .F.
EndIf

lStaticRet:=_lRet

Return( _lRet )

//=================================//
//Autor-----------: Alex Wallauer
//Data da Criacao-: 19/02/2024
//=================================//
User Function RetMT410ACE()//Usada no programa A410EXC.PRW
Return lStaticRet

/*
===============================================================================================================================
Programa--------: validCarga
Autor-----------: Fabiano Dias 
Data da Criacao-: 12/07/2010
Descrição-------: Validar a exclusao/alteracao do Pedido de Venda, para verificar se existe carga montada		
Parametros------: Nenhum
Retorno---------: .T. ou .F. Sendo que .T. continua o processo de alteracao/exclusão e .F. aborta
===============================================================================================================================
*/
Static Function validCarga()

Local _cQuery   := ""
Local _cAliasDAI:= GetNextAlias()  
Local _nCountRec:= 0
Local _lRet     := .T.    

_cQuery := "SELECT"    
_cQuery += " DAI_FILIAL , DAI_PEDIDO , DAI_COD , DAI_SEQCAR "
_cQuery += "FROM " + RetSqlName("DAI") + " DAI "
_cQuery += "WHERE"
_cQuery += " D_E_L_E_T_= ' '"      
_cQuery += " AND DAI_FILIAL = '" + SC5->C5_FILIAL + "'"
_cQuery += " AND DAI_PEDIDO = '" + SC5->C5_NUM    + "'"        
	
If Select(_cAliasDAI) > 0
	DBSelectArea(_cAliasDAI)
	(_cAliasDAI)->(DBCloseArea())
EndIf
	
dbUseArea( .T., "TOPCONN",TcGenQry(,,_cQuery),_cAliasDAI,.T.,.F.)         
COUNT To _nCountRec
	
DBSelectArea(_cAliasDAI)               
(_cAliasDAI)->(DBGoTop())
	
If _nCountRec > 0 
	
    If (FUNNAME()) $ "MATA521B" .Or. FWIsInCallStack("M520_VALID")
       _cCargaAchou:=(_cAliasDAI)->(DAI_FILIAL+DAI_PEDIDO+DAI_COD+DAI_SEQCAR)//Usado no ponto de entrada M520BROW.PRW e AOMS116.PRW
    Else
 	
 	   _lRet     := .F.  
 	   _cviagem :=  Posicione("DAK",1,(_cAliasDAI)->DAI_FILIAL+(_cAliasDAI)->DAI_COD,"DAK_I_CARG")
 	   
 	   If !Empty(_cviagem)
          _cviagem := " e a viagem " + _cviagem + " no TMS seja estornada."
 	   Else
		  _cviagem := " seja estornada."
 	   	EndIf
 	   	
  	   U_MT_ITMSG("Não será possível realizar a alteração/exclusão do pedido de venda(" + SC5->C5_NUM + "), pois existe uma carga montada que utiliza este pedido.","Atenção!",;
			           "Para alterar/excluir este pedido é necessário que antes a carga: " + (_cAliasDAI)->DAI_COD + _cviagem ,1)
	EndIf
EndIf       
	
DBSelectArea(_cAliasDAI)
(_cAliasDAI)->(DBCloseArea())       
	

Return _lRet

/*
===============================================================================================================================
Programa--------: VLDALT
Autor-----------: Josué Danich Prestes
Data da Criacao-: 21/09/2018
Descrição-------: Validações se pedido de vendas pode ser alterado e/ou excluido	
Parametros------: _nopc - tipo de operação
				  oproc - objeto da barra de processamento
				  _lshow - se exibe objetos gráficos de interface
				  _lRet - status da validação geral
Retorno---------: _lRet - validação da condição
===============================================================================================================================
*/
Static Function VLDALT(_nopc,oproc,_lshow,_lRet)

Local _cFilHabilit 	:= SuperGetMV('IT_FILINTW',.F.,'') // Filiais habilitadas na integracao Webservice Italac x RDC.     
Local _nRegSC5, _aOrd, _cFilSC5, _cNrPedVinc 
Local _lVoltouVinculo := .F.
Local _cTextoMsg 

//Se validação não está mais válida já retorna false
If !_lRet
	Return _lRet
EndIf

//Só faz validações para alteração e exclusão
If  _nopc == 4 .Or. _nopc == 1     
	//Valida se pedido está com bloqueio logístico
	If SC5->C5_I_BLOG == "S"
		ZZL->(DBSetOrder(3))
		If !(ZZL->(DBSeek(xFilial("ZZL") + RetCodUsr()))) .Or. ZZL->ZZL_PVLOG != "S"	
			_lRet := .F.
			If _lshow
				U_MT_ITMSG("Pedido tem bloqueio logístico!","Atenção",,1)
			EndIf
		EndIf
	EndIf

	If _lRet
		_lRet:= validCarga()
	EndIf

   	If _lRet  
		If SC5->C5_FILIAL $ _cFilHabilit // Filiais habilitadas na integracao Webservice Italac x RDC.
			_cTipoOperac := ""
			If _nopc == 4
				_cTipoOperac := "alterar"
			Else
				_cTipoOperac := "excluir"
			EndIf
			
			If SC5->C5_I_ENVRD == "S"
						
				If !FWIsInCallStack("U_ALTERAP") .AND.; //Não puxa de volta se For integração RDC  
					!FWIsInCallStack("AOMS032PPV")       //Não puxa de volta se For visulização da tela de transferência 
					_cTextoMsg := "Este pedido já foi integrado para o sistema TMS, deseja realmente "
					If _lshow .And. ( FWIsInCallStack("U_AOMS109") .Or. FWIsInCallStack("U_MOMS066") .OR.; 
						U_ITMsg(_cTextoMsg + _cTipoOperac + " o pedido? ","Atenção",,2,2,2))
						_lRet := .T.
						If ! Empty(SC5->C5_I_PEVIN)
							_nRegSC5    := SC5->(Recno())   // Salva a posição atual do SC5.
							_aOrd       := SaveOrd({"SC5"}) // Salva a ordem dos indices.
							_cFilSC5    := SC5->C5_FILIAL
							_cNrPedVinc := SC5->C5_I_PEVIN
							
							SC5->(DBSetOrder(1))       // C5_FILIAL+C5_NUM 

							If SC5->(DBSeek(_cFilSC5+_cNrPedVinc))  // Posiciona no Pedido de Vendas Vinculado.                 
								If ! U_IT_TMS(SC5->C5_I_LOCEM)//_lWsTms
									FWMsgRun( ,{|| _lRet := U_AOMS094E()} , 'Aguarde!' , 'Trazendo Pedido de Vendas Vinculado do RDC para o Protheus...' )
								Else
									FWMsgRun( ,{|_oProc| _lRet := U_AOMS140E(_oProc,.T.)} , 'Aguarde!' , 'Trazendo Pedido de Vendas Vinculado do TMS Multi-Embarcador para o Protheus...' ) 
								EndIf 

								If _lRet
									_lVoltouVinculo := .T.
								EndIf
							EndIf
								
							SC5->(DBGoTo(_nRegSC5)) // Volta o SC5 para a posição original.
							RestOrd(_aOrd)          // Volta os indices para a posição original.
						EndIf
					
						If _lRet
							If ! U_IT_TMS(SC5->C5_I_LOCEM)//_lWsTms
								FWMsgRun( ,{|| _lRet := U_AOMS094E()} , 'Aguarde!' , 'Trazendo Pedido de Vendas do RDC para o Protheus...' )
							Else
								FWMsgRun( ,{|_oProc| _lRet := U_AOMS140E(_oProc, .T.)} , 'Aguarde!' , 'Trazendo Pedido de Vendas do TMS Multi-Embarcador para o Protheus...' )
							EndIf 
							If _lVoltouVinculo
								If ! _lRet // Voltou o pedido de vendas vinculado, mas ocorreu erro ao voltar o pedido de vendas principal.
									_nRegSC5 := SC5->(Recno()) // Salva a posição atual do SC5.
									_aOrd := SaveOrd({"SC5"})  // Salva a ordem dos indices.
									_cFilSC5 := SC5->C5_FILIAL
									_cNrPedVinc := SC5->C5_I_PEVIN
									
									SC5->(DBSetOrder(1))       // C5_FILIAL+C5_NUM 
									If SC5->(DBSeek(_cFilSC5+_cNrPedVinc))  // Posiciona no Pedido de Vendas Vinculado.
										U_RETPVRDC() // Grava na tabela de muro o pedido de vendas vinculado para envio ao sistema RDC.
									EndIf 

									SC5->(DBGoTo(_nRegSC5)) // Volta o SC5 para a posição original.
									RestOrd(_aOrd)          // Volta os indices para a posição original.
								EndIf
							EndIf
						EndIf
					Else
						_lRet := .F.
					EndIf
				If !_lRet
					If _lshow .And. !FWIsInCallStack("U_AOMS109")
						If ! U_IT_TMS(SC5->C5_I_LOCEM)//_lWsTms
							_cTextoMsg :="Este pedido já foi integrado ao sistema RDC e não pode ser alterado ou excluido."
						Else
							_cTextoMsg :="Este pedido já foi integrado ao sistema TMS Multi-Embarcador e não pode ser alterado ou excluido."
						EndIf 
						U_MT_ITMSG(_cTextoMsg,"Atenção","Solicite o retorno do pedido para o Protheus.",1)
					EndIf
				EndIf
			EndIf
			
		EndIf

		//Valida se precisa puxar pedido vinculado de operação triangular do RDC
		If _lRet  .And. !FWIsInCallStack("U_ALTERAP") //Não puxa de volta se For integração RDC  
			If SC5->C5_I_OPTRI = "R" .And. !Empty( SC5->C5_I_PVFAT ) .OR.; //Alterações do PV de Remessa no PV de Faturamento
				SC5->C5_I_OPTRI = "F" .And. !Empty( SC5->C5_I_PVREM )       //Alterações do PV de Faturamento no PV de Remessa 
					If SC5->C5_I_OPTRI="R"
						_cPedido:=SC5->C5_I_PVFAT
						_cTesxto:="PV de Remessa"
					Else
						_cPedido:=SC5->C5_I_PVREM
						_cTesxto:="PV de Faturamento"
					EndIf
					
					_nRecOrigem := SC5->(Recno())
					
					SC5->(DBSetOrder(1))
					
					If SC5->(DBSeek(xFilial()+_cPedido))
						If ( FWIsInCallStack("U_AOMS109")) .And. SC5->C5_I_ENVRD == "S"
							_cTextoMsg := "O pedido vinculado de operação triangular já foi integrado para o sistema TMS, deseja realmente "
							If _lshow .And. U_ITMsg( _cTextoMsg + _cTipoOperac + " o pedido? ","Atenção",,2,2,2)
								If ! U_IT_TMS(SC5->C5_I_LOCEM)//_lWsTms
									FWMsgRun( ,{|| _lRet := U_AOMS094E()} , 'Aguarde!' , 'Trazendo Pedido de Vendas do RDC para o Protheus...' )
								Else
									FWMsgRun( ,{|_oProc| _lRet := U_AOMS140E(_oProc, .T.)} , 'Aguarde!' , 'Trazendo Pedido de Vendas do TMS Multi-Embarcador para o Protheus...' )
								EndIf 
							EndIf
						Else
							_lRet := .T.
						EndIf
		
						If !_lRet
							If  !FWIsInCallStack("U_AOMS109") .And. SC5->C5_I_ENVRD == "S"
								If _lshow
									_cTextoMsg := "O pedido vinculado de operação triangular já foi integrado ao sistema TMS e não pode ser alterado ou excluido." 
									U_MT_ITMSG(_cTextoMsg , "Atenção","Solicite o retorno do pedido para o Protheus.",1)
								EndIf									
							EndIf
						EndIf
					EndIf
					SC5->(DBGoTo(_nRecOrigem))//Volta o POSICIONAMENTO do pedido de origem
				EndIf
			EndIf
		EndIf
   	EndIf
EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: VLDEXC
Autor-----------: Josué Danich Prestes
Data da Criacao-: 21/09/2018
Descrição-------: Validações se pedido de vendas pode ser alterado e/ou excluido	
Parametros------: _nopc - tipo de operação
				  oproc - objeto da barra de processamento
				  _lshow - se exibe objetos gráficos de interface
				  _lRet - status da validação geral
Retorno---------: _lRet - validação da condição
===============================================================================================================================
*/
Static Function VLDEXC(_nopc,oproc,_lshow,_lRet)

Local _aAreaSC5 := {}
Local _cNumPed  := ""

//Se validação não está mais válida já retorna false
If !_lRet
	Return _lRet
EndIf

_cOperTriangular:= AllTrim(SuperGetMV("IT_OPERTRI",.F.,"05,42"))// Tipos de operações da operação trigular
_cOperRemessa   := RIGHT(_cOperTriangular,2)
_cOperFat       := LEFT(_cOperTriangular,2)

If _lRet .And. (_nopc == 1) .And. SC5->C5_I_OPER = _cOperFat .And. !FWIsInCallStack("U_IT_OperTriangular")
	If !Empty(AllTrim(SC5->C5_I_PVREM))
		_cNumPed  := SC5->C5_I_PVREM
		_aAreaSC5 := GetArea("SC5")
		SC5->(DBSetOrder(1))
		If SC5->(DBSeek(xFilial("SC5")+_cNumPed))
			U_MT_ITMSG("Não é possivel Excluir esse Pedido de Faturamento.","Atenção!","Para excluir o PV de Faturamento Exclua ou Altere o Pedido de Remessa: "+_cNumPed,1)
			_lRet:=.F.
		EndIf
		FWRestArea(_aAreaSC5)
   EndIf
EndIf

SA1->(DBSetOrder(1))
If _lRet .And. (_nopc == 1) .And. SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
	If SA1->A1_MSBLQL == '1' 
		BEGIN TRANSACTION
	
		//Se o cliente está bloqueado faz o estorno das liberações
		RecLock("SA1",.F.)
		SA1->A1_MSBLQL := '2'
		SA1->(MSUnLock())
		
		RecLock("SC5",.F.)
		
		_aCabPV  :={}
		_aItemPV :={}
		_aItensPV:={}
                    
		aAdd( _aCabPV, { "C5_FILIAL"	,SC5->C5_FILIAL  , Nil})//filial
		aAdd( _aCabPV, { "C5_NUM"    	,SC5->C5_NUM	 , Nil})
		aAdd( _aCabPV, { "C5_TIPO"	    ,SC5->C5_TIPO    , Nil})//Tipo de pedido
		aAdd( _aCabPV, { "C5_I_OPER"	,SC5->C5_I_OPER  , Nil})//Tipo da operacao
		aAdd( _aCabPV, { "C5_CLIENTE"	,SC5->C5_CLIENTE , NiL})//Codigo do cliente
		aAdd( _aCabPV, { "C5_CLIENT" 	,SC5->C5_CLIENT	 , Nil})
		aAdd( _aCabPV, { "C5_LOJAENT"	,SC5->C5_LOJAENT , NiL})//Loja para entrada
		aAdd( _aCabPV, { "C5_LOJACLI"	,SC5->C5_LOJACLI , NiL})//Loja do cliente
		aAdd( _aCabPV, { "C5_EMISSAO"	,SC5->C5_EMISSAO , NiL})//Data de emissao
		aAdd( _aCabPV, { "C5_TRANSP" 	,SC5->C5_TRANSP	 , Nil})
		aAdd( _aCabPV, { "C5_CONDPAG"	,SC5->C5_CONDPAG , NiL})//Codigo da condicao de pagamanto*
		aAdd( _aCabPV, { "C5_VEND1"  	,SC5->C5_VEND1	 , Nil})
		aAdd( _aCabPV, { "C5_MOEDA"	    ,SC5->C5_MOEDA   , Nil})//Moeda
		aAdd( _aCabPV, { "C5_MENPAD" 	,SC5->C5_MENPAD	 , Nil})
		aAdd( _aCabPV, { "C5_LIBEROK"	,SC5->C5_LIBEROK , NiL})//Liberacao Total
		aAdd( _aCabPV, { "C5_TIPLIB"  	,SC5->C5_TIPLIB  , Nil})//Tipo de Liberacao
		aAdd( _aCabPV, { "C5_TIPOCLI"	,SC5->C5_TIPOCLI , NiL})//Tipo do Cliente
		aAdd( _aCabPV, { "C5_I_NPALE"	,SC5->C5_I_NPALE , NiL})//Numero que originou a pedido de palete
		aAdd( _aCabPV, { "C5_I_PEDPA"	,SC5->C5_I_PEDPA , NiL})//Pedido Refere a um pedido de Pallet
		aAdd( _aCabPV, { "C5_I_DTENT"	,Date()+365       , Nil})//Dt de Entrega 
		aAdd( _aCabPV, { "C5_I_TRCNF"   ,SC5->C5_I_TRCNF , Nil})
		aAdd( _aCabPV, { "C5_I_BLPRC"   ,SC5->C5_I_BLPRC , Nil})
		aAdd( _aCabPV, { "C5_I_FILFT"   ,SC5->C5_I_FILFT , Nil})
		aAdd( _aCabPV, { "C5_I_FLFNC"   ,SC5->C5_I_FLFNC , Nil})
      	
		SC6->(DBSetOrder(1))
		SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
		
		While SC5->C5_FILIAL == SC6->C6_FILIAL .And. SC5->C5_NUM == SC6->C6_NUM
			_aItemPV:={}
			aAdd( _aItemPV , { "C6_FILIAL"  ,SC6->C6_FILIAL  , Nil }) // FILIAL
			aAdd( _aItemPV , { "C6_NUM"    	,SC6->C6_NUM	 , Nil })
			aAdd( _aItemPV , { "C6_ITEM"    ,SC6->C6_ITEM    , Nil }) // Numero do Item no Pedido
			aAdd( _aItemPV , { "C6_PRODUTO" ,SC6->C6_PRODUTO , Nil }) // Codigo do Produto
			aAdd( _aItemPV , { "C6_QTDVEN"  ,SC6->C6_QTDVEN  , Nil }) // Quantidade Vendida
			aAdd( _aItemPV , { "C6_PRCVEN"  ,SC6->C6_PRCVEN  , Nil }) // Preco Unitario Liquido
			aAdd( _aItemPV , { "C6_PRUNIT"  ,SC6->C6_PRUNIT  , Nil }) // Preco Unitario Liquido
			aAdd( _aItemPV , { "C6_ENTREG"  ,SC6->C6_ENTREG  , Nil }) // Data da Entrega
			aAdd( _aItemPV , { "C6_LOJA"   	,SC6->C6_LOJA	 , Nil })
			aAdd( _aItemPV , { "C6_SUGENTR" ,SC6->C6_SUGENTR , Nil }) // Data da Entrega
			aAdd( _aItemPV , { "C6_VALOR"   ,SC6->C6_VALOR   , Nil }) // valor total do item
			aAdd( _aItemPV , { "C6_UM"      ,SC6->C6_UM      , Nil }) // Unidade de Medida Primar.
			aAdd( _aItemPV , { "C6_TES"    	,SC6->C6_TES	 , Nil })
			aAdd( _aItemPV , { "C6_LOCAL"   ,SC6->C6_LOCAL   , Nil }) // Almoxarifado
			aAdd( _aItemPV , { "C6_CF"     	,SC6->C6_CF		 , Nil })
			aAdd( _aItemPV , { "C6_DESCRI"  ,SC6->C6_DESCRI  , Nil }) // Descricao
			aAdd( _aItemPV , { "C6_QTDLIB"  ,SC6->C6_QTDLIB  , Nil }) // Quantidade Liberada
			aAdd( _aItemPV , { "C6_PEDCLI" 	,SC6->C6_PEDCLI	 , Nil })
			aAdd( _aItemPV , { "C6_I_BLPRC"	,SC6->C6_I_BLPRC , Nil })
        	aAdd( _aItensPV ,_aItemPV )
			
           SC6->(DBSkip())
		EndDo
		
		If _lshow
			FWMsgRun(,{ || MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , 4 )},"Aguarde...","Excluindo liberações para PV com cliente bloqueado...")
		Else
			MSExecAuto( {|x,y,z| Mata410(x,y,z)  } , _aCabPV , _aItensPV , 4 )
		EndIf
		
		If lMsErroAuto
			DisarmTransaction()
			U_MT_ITMSG("O PV possui liberação e está com cliente bloqueado, foi realizada uma tentativa de excluir a liberação sem sucesso",;
					"Atenção","Solicite o desbloqueio do cliente e estorno de liberação de estoque antes de excluir o PV",1)
			If _lshow
				MostraErro()
			EndIf
			_lRet := .F.
			SA1->(MSUnLock())
			SC5->(MSUnLock())
		Else
			RecLock("SA1",.F.)
			SA1->A1_MSBLQL := '1'
			SA1->(MSUnLock())
			SC5->(MSUnLock())
		EndIf
		   
        END TRANSACTION
    EndIf
EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: LOCKMU
Autor-----------: Josué Danich Prestes
Data da Criacao-: 21/09/2018
Descrição-------: Reserva de locks para alteração de pedido de vendas
Parametros------: _nopc - tipo de operação
				  oproc - objeto da barra de processamento
				  _lshow - se exibe objetos gráficos de interface
				  _lRet - status da validação geral
Retorno---------: _lRet - validação da condição
===============================================================================================================================
*/
Static Function LOCKMU(_nopc,oproc,_lshow,_lRet)

Local _cTextoMsg

//Se validação não está mais válida já retorna false
If !_lRet
	Return _lRet
EndIf

//Faz lock nos registros da tabela de muro para garantir que não serão lockados por outro processo travando a alteração do pedido
If AllTrim(FunName()) == 'MATA410' .And. _lRet  .And. (_nopc == 1 .Or. _nOpc == 4)
 
	cQuery	:= " SELECT ZFQ.r_e_c_n_o_ REG "
	cQuery	+= " FROM  "+ RetSqlName('ZFQ') + " ZFQ "
	cQuery	+= " WHERE "+ RetSqlDel('ZFQ') + " AND ZFQ_PEDIDO = '" + SC5->C5_NUM  + "'"
   
   	If Select("TRABT") <> 0
			TRABT->( DBCloseArea() )
	EndIf
		
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,, cQuery) , "TRABT" , .T. , .F. )
   
    Begin Sequence
   
    While !(TRABT->(Eof())) 
    	ZFQ->(DBGoTo(TRABT->REG))
      		If ZFQ->(MsRLock( ZFQ->(RECNO()) ))
 	   			ZFQ->(MSUnLock())
      			ZFQ->(MSUnLockALL())
      		Else
 	   			ZFQ->(MSUnLock())
      			ZFQ->(MSUnLockALL())
      			_lRet := .F.

                _cTextoMsg := "Este pedido está em processamento de transmissão para o TMS. (Lock ZFQ)"

 		         U_MT_ITMSG(_cTextoMsg,"Atenção","Tente realizar alteração novamente em alguns minutos.",1)
			    Break
      		EndIf
       	TRABT->(DBSkip())
   	EndDo
   
	cQuery	:= " SELECT ZFR.r_e_c_n_o_ REG "
	cQuery	+= " FROM  "+ RetSqlName('ZFR') + " ZFR "
	cQuery	+= " WHERE "+ RetSqlDel('ZFR') + " AND ZFR_NUMPED = '" + SC5->C5_NUM + "'"
	
	If Select("TRABT") <> 0
			TRABT->( DBCloseArea( ) )
	EndIf
		
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,, cQuery) , "TRABT" , .T. , .F. )
	
	While !(TRABT->(Eof())) 
		ZFR->(DBGoTo(TRABT->REG))
      	 	If ZFR->(MsRLock( ZFR->(RECNO()) ))
 	   			ZFR->(MSUnLock())
      			ZFR->(MSUnLockALL())
      		Else
 	   			ZFR->(MSUnLock())
      			ZFR->(MSUnLockALL())
      			_lRet := .F.

                _cTextoMsg := "Este pedido está em processamento de transmissão para o TMS. (Lock ZFR)"

 		        U_MT_ITMSG(_cTextoMsg,"Atenção", "Tente realizar alteração novamente em alguns minutos.",1)
			    Break
      		EndIf
         TRABT->(DBSkip())
    EndDo
    End Sequence
EndIf    

If Select("TRABT") <> 0
	TRABT->( DBCloseArea(  ) )
EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: VLDTRI
Autor-----------: Josué Danich Prestes
Data da Criacao-: 21/09/2018
Descrição-------: Valida se pedido de operação triangular pode ser alterado
Parametros------: _nopc - tipo de operação
				  oproc - objeto da barra de processamento
				  _lshow - se exibe objetos gráficos de interface
				  _lRet - status da validação geral
Retorno---------: _lRet - validação da condição
===============================================================================================================================
*/
Static Function VLDTRI(_nopc,oproc,_lshow,_lRet)

//Se validação não está mais válida já retorna false
If !_lRet
	Return _lRet
EndIf

_nRecOrigem     := SC5->(RECNO())

If SC5->C5_I_OPTRI = "R" .And. !Empty( SC5->C5_I_PVFAT ) .OR.; //Alterações do PV de Remessa no PV de Faturamento
	SC5->C5_I_OPTRI = "F" .And. !Empty( SC5->C5_I_PVREM )       //Alterações do PV de Faturamento no PV de Remessa 
	If SC5->C5_I_OPTRI="R"
		_cPedido:=SC5->C5_I_PVFAT
		_cTesxto:="PV de Remessa"
	Else
		_cPedido:=SC5->C5_I_PVREM
		_cTesxto:="PV de Faturamento"
	EndIf
	SC5->(DBSetOrder(1))
	If SC5->(DBSeek(xFilial()+_cPedido))
		If !SC5->(MsRLock( SC5->(RECNO()) ))
			_cUser:= TCInternal(53)
			U_MT_ITMSG(_cTesxto+" desse Pedido está sendo alterado pelo usuario "+_cUser+" . (Lock SC5)","Atenção","Tente realizar alteração novamente em alguns minutos.",1)
			_lRet := .F.
		EndIf
	EndIf
EndIf
SC5->(DBGoTo(_nRecOrigem))//Volta o POSICIONAMENTO do pedido de origem

Return _lRet

/*
===============================================================================================================================
Programa--------: INILOG6
Autor-----------: Josué Danich Prestes
Data da Criacao-: 21/09/2018
Descrição-------: Grava situação inicial do SC6 para log e alterações
Parametros------: _nopc - tipo de operação
				  oproc - objeto da barra de processamento
				  _lshow - se exibe objetos gráficos de interface
				  _lRet - status da validação geral
Retorno---------: _lRet - validação da condição
===============================================================================================================================
*/
Static Function INILOG6(_nopc,oproc,_lshow,_lRet)

Local _acampos		:= {'C6_ITEM','C6_PRODUTO','C6_PRCVEN','C6_TES','C6_QTDVEN','C6_LOCAL','C6_PEDCLI'}
Local _asc6  := SC6->(GetArea())
Local _nnl		:= 0

//Se validação não está mais válida já retorna false
If !_lRet
	Return _lRet
EndIf

SC6->(DBSetOrder(1))
If SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
	While SC5->C5_FILIAL+SC5->C5_NUM == SC6->C6_FILIAL+SC6->C6_NUM
		For _nnl := 1 To Len(_acampos)
			_cCpoAux := "SC6->"+ _acampos[_nnl]
			aAdd( _aLogSC6 , { SC6->( C6_FILIAL + C6_NUM + SC6->C6_ITEM ) , _acampos[_nnl] , &_cCpoAux } )
		Next _nnl
		SC6->(DBSkip())
	EndDo
EndIf

SC6->(FWRestArea(_asc6))

Return _lRet
