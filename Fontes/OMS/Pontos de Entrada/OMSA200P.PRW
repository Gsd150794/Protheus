/*
======================================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
======================================================================================================================================
     Autor     |    Data    |                                             Motivo
--------------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer | 29/12/2016 | Ajustes da Unificação - Pre-Carga - Chamado 18245
 Julio Paz     | 23/01/2017 | Inclusão da rotina de integração de cancelamento de carga Italac x RDC via Webservice. Chamado: 16681.
 Lucas Borges  | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
 Alex Wallauer | 01/02/2021 | Remoção de bugs apontados pelo Totvs CodeAnalysis. Chamado: 34262
======================================================================================================================================

==================================================================================================================================================================================================================
Analista        - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==================================================================================================================================================================================================================
Vanderlei Alves - Igor Melgaço  - 10/01/24 - 26/06/25 -  49552 - Ajustes para nova regra de cancelamento de carga no TMS Multiembarcador
==================================================================================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "RwMake.ch"

/*
===============================================================================================================================
Programa----------: OMSA200P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/09/2015
Descrição---------: Ponto de entrada que valida o estorno de montagem de carga - Chamado 12082
Parametros--------: Nenhum
Retorno-----------: .T. - Permite seleção .F. - Não permite a seleção
===============================================================================================================================
*/
User Function OMSA200P()

 Local _aArea	:=FWGetArea()            //Salva area geral
 Local _lRet		:= .T.
 Local _cmens	:= ""
 Local _aRet		:= {}
 Local _cCodUsr	:= AllTrim(RetCodUsr())
 
 If Type("_lAutomatico") == "U"
    Private _lAutomatico := .F.
 EndIf
 
 If _lAutomatico
    _lUsuConfirmou := .T.
 EndIf
 
 //Posiciona carga
 DBSelectArea("DAI")
 DAI->( DBSetOrder(1) )
 
 If DAI->( DBSeek( xFilial("DAI")+ AllTrim(ParamIXB[1])+ AllTrim(ParamIXB[2])))
 
     If Posicione("SC5",1,xFilial("SC5") + AllTrim(DAI->DAI_PEDIDO),"SC5->C5_TIPO") == 'N'
 
         DBSelectArea("SC6")
         DBSetOrder(1)
 
         If DBSeek(xFilial("SC6")+AllTrim(DAI->DAI_PEDIDO))
 
             While AllTrim(DAI->DAI_PEDIDO) == AllTrim(SC6->C6_NUM)
 
                 //============================================
                 //Valida armazémxprodutoxfilialxusuário
                 //============================================
                 _aRet := U_ACFG004E(_cCodUsr, AllTrim(xFilial("SC6")), AllTrim(SC6->C6_LOCAL),AllTrim(SC6->C6_PRODUTO), .F.)
 
                 //se ainda está valido verifica se não teve erro
                 If _lRet
 
                       _lRet:= _aRet[1]
 
                 EndIf
 
                 // adiciona armazens com problema se ainda não estiver na mensagem
                 If Empty(_cmens)
 
                     _cmens += _aRet[2]
 
                 ElseIf !(_aRet[2]$_cmens) .And. !(Empty(_aRet[2]))
 
                     _cmens += ", " + _aRet[2]
 
                 EndIf
 
 
                 SC6->( DBSkip() )
 
             EndDo
 
             //============================================
             //Mostra lista de armazéns com problema
             //============================================
             If !(_lRet)
                If ! _lAutomatico
                   MessageBox( 'Usuário sem acesso ao(s) armazém(éns) abaixo nessa filial: ' + CRLF + _cmens + CRLF + CRLF+;
                               'Caso necessário solicite a manutenção à um usuário com acesso ou, se necessário, solicite o acesso à área de TI/ERP.' , 'Atenção! (OMSA200P)' , 48 )
                Else
                   _cMsgEstorno := 'Usuário sem acesso ao(s) armazém(éns) abaixo nessa filial: ' + _cmens
 
                EndIf
             EndIf
 
         EndIf
 
     EndIf
 
 Else
 
     If ! _lAutomatico
        //Se não localizaou o registro na DAI existe problema na base de dados
        MessageBox( 'Problema ao localizar dados da carga!'+CRLF+;
                    'Solicite suporte à área de TI/ERP.' , 'Atenção! (OMSA200P)' , 48 )
     Else
        _cMsgEstorno := 'Problema ao localizar dados da carga! '
     EndIf
 
     _lRet:= .F.
 
 EndIf
 // O Envio do e-mail foi para dentro da funcao U_OM20MNUE no ponto de entrada OM200MNU.prw ==> U_OM200Email(.T.,_aPVs_DAI)//AWF - 14/07/2016
 
 If _lRet
    If ! _lAutomatico
       Processa( {|| _lRet:=OMS200DelPV() } )
    Else
       _lRet := OMS200DelPV()
    EndIf
 EndIf
 
 If _lRet .And. DAK->DAK_I_TMS == 'M' .And. DAK->DAK_ACECAR == "2" .And. DAK->DAK_ACEFIN == "2"
    _lRet := U_ITMa521Mbrow("DAK")
 EndIf

 FWRestArea(_aArea) //-- Restaura a posição da tabela corrente

 If _lRet .And. _lAutomatico
    Os200ProcEst(DAK->DAK_COD)
    _lRet := .F.
 EndIf
 
 FWRestArea(_aArea) //-- Restaura a posição da tabela corrente

Return If(_lRet,NIL,.F.)//nao pode retornar um valor logico se For .T. pq ele mata a validacao padrao se For .F.

/*
===============================================================================================================================
Programa--------: OMS200DelPV()
Autor-----------: Alex Wallauer
Data da Criacao-: 11/08/2016
Descrição-------: Apaga os pedidos de pallet gerados na montagem de carga
Retorno---------: Lógico (.T.) Se apagou / (.F.) Se nao apagou
===============================================================================================================================
*/
Static Function OMS200DelPV(_lOMSA200P As Logical) As Logical

Local _aPeds_Pallet := {} As Array
Local _cPVs := "" As Char
Local C As Numeric
Local _lOK := .T. As Logical

SC5->(DBSetOrder(1))

If ! _lAutomatico
   ProcRegua(Len(_aPVs_DAI))
EndIf

_aFatPedCarga:={}//Private do rdmake OM200MNU.PRW

For C := 1 TO Len(_aPVs_DAI)
    DAI->( DBGoTo( _aPVs_DAI[C,3] ))

    If ! _lAutomatico
       IncProc("Lendo Pedido: "+DAI->DAI_PEDIDO)
    EndIf

    If !SC5->( DBSeek( xFilial("SC5") + _aPVs_DAI[C,1] ) )
       Loop
    EndIf
    If !Empty(DAI->DAI_I_QTPA)//DAI->DAI_I_TIPC $ "1,3,4" .And. - AWF 29/12/2016 - Retirei o tipo pq se entrar novos tipos não precisa alterar mais aqui
       If Empty(SC5->C5_I_PDFT)//Se tiver preenchido é pq já gerou a Nota do pedido de carregamento e esta tentando estornar a carga do fatura/mento dai nao entra aqui
          If SC5->C5_I_PEDPA = 'S' .And. SC5->C5_I_PEDGE # 'S' .And. !Empty(SC5->C5_I_NPALE)//Se é Pedido de Pallet (Tem Dupla) e se não é o Pedido gerador de Pallet que esta na carga
                      //Recno do Pedido de Pallet , Pedido que gerou o Pallet ,DAI  ,Pedido de Pallet
             aAdd(_aPeds_Pallet, { SC5->(RECNO()) , SC5->C5_I_NPALE , DAI->(RECNO()) , _aPVs_DAI[C,1] })
          EndIf
       EndIf
    EndIf
    If !Empty(SC5->C5_I_PDFT)//Quando esta estornando a carga gerada automatica na filial de faturamento
       aAdd(_aFatPedCarga,{SC5->(RECNO()),SC5->C5_I_FLFNC+SC5->C5_I_PDPR,"",SC5->C5_I_CARGA})//Guarda o Pedido da Carga Gerada para voltar o antigo
    EndIf
Next

//BEGIN Transaction // foi para a chamada do programa no rdmake OM200MNU.PRW

   _lOK:=.T.
   _cPVs:=""
   If ! _lAutomatico
      ProcRegua(Len(_aPeds_Pallet))
   EndIf

   For C := 1 TO Len(_aPeds_Pallet)

       If !OMS200Apaga(_aPeds_Pallet[C,1],_aPeds_Pallet[C,2],_aPeds_Pallet[C,3])
          SC5->( DBGoTo( _aPeds_Pallet[C,1] ))
          _cPVs+=SC5->C5_NUM+", "
          _lOK:=.F.
       EndIf

   Next

   If !_lOK

      DisarmTransaction()
      _lUsuConfirmou:=.F.//Variavel Private usada no rdmake OM200MNU.PRW para saber se o usuario confirmou o estorno
      _cPVs:=LEFT(_cPVs,Len(_cPVs)-2)

      If ! _lAutomatico
         MessageBox( "Nao foi possivel excluir o(s) Pedido(s) de Pallet: "+_cPVs+CRLF+;
                     "Verifique o(s) Pedido(s) de Pallet conforme Mensage(ns) de erro(s) apresentada(s)"+CRLF+;
                     "Depois tente estornar essa Carga novamente." , 'Atenção! (OMSA200P)' , 48 )
      Else
         _cMsgEstorno := "Nao foi possivel excluir o(s) Pedido(s) de Pallet: "+_cPVs+"."+;
                         " Verifique o(s) Pedido(s) de Pallet conforme Mensage(ns) de erro(s) apresentada(s),"+;
                         " depois tente estornar essa Carga novamente."
      EndIf
   EndIf

//END Transaction // foi para a chamada do programa no rdmake OM200MNU.PRW

Return _lOK

/*
===============================================================================================================================
Programa--------: OMS200Apaga(_nRecPedPallet,_cPedGerou,_nRecDAI)
Autor-----------: Alex Wallauer
Data da Criacao-: 11/08/2016
Descrição-------: _nRecPedPallet: Recno do Pedido de Pallet
                  _cPedGerou: Pedido que gerou o Pallet
                  _nRecDAI: recno do DAI
Retorno---------: Lógico (.T.) Se apagou / (.F.) Se nao apagou
===============================================================================================================================
*/
Static Function OMS200Apaga(_nRecPedPallet As Numeric, _cPedGerou As Char, _nRecDAI As Numeric) As Logical

Local _aCabPV  := {} As Array
Local _aItemPV := {} As Array
Local _aItensPV:= {} As Array
Local _cPedidoP As Char

If _nRecPedPallet # 0
   SC5->( DBGoTo( _nRecPedPallet ))
Else
   Return .F.
EndIf

If ! _lAutomatico
   IncProc("Lendo Pedido: "+SC5->C5_NUM)
EndIf

//====================================================================================================
// Limpa a carga do DAI para nao dar mensagem de erro customizada no estorno da liberacao
DAI->( DBGoTo( _nRecDAI ))
DAI->(RecLock("DAI",.F.))
DAI->(DBDELETE())
DAI->(MSUnLock())
//====================================================================================================

//====================================================================================================
// Limpa a carga do SC9 para nao dar mensagem de erro padrao no estorno do Pedido de Pallet
SC9->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
While SC9->( !Eof() ) .And. SC9->( C9_FILIAL + C9_PEDIDO) == SC5->C5_FILIAL + SC5->C5_NUM

   SC9->( RecLock('SC9',.F.) )
   SC9->C9_CARGA:=""
   SC9->C9_SEQCAR:=""
   SC9->C9_SEQENT:=""
   SC9->( MSUnLock() )
   SC9->( DBSkip() )

EndDo
//====================================================================================================

_aCabPV  :={}
_aItemPV :={}
_aItensPV:={}
_dDtEnt	 := If(SC5->C5_I_DTENT < DATE(),DATE(),SC5->C5_I_DTENT)//Para nao travar a alteracao do Pedido de Pallet

//====================================================================================================
// Monta o cabeçalho do pedido
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
aAdd( _aCabPV, { "C5_I_DTENT"	,_dDtEnt         , Nil})//Dt de Entrega foi alterado para data do dia
aAdd( _aCabPV, { "C5_I_TRCNF"   ,SC5->C5_I_TRCNF , Nil})
aAdd( _aCabPV, { "C5_I_BLPRC"   ,SC5->C5_I_BLPRC , Nil})
aAdd( _aCabPV, { "C5_I_FILFT"   ,SC5->C5_I_FILFT , Nil})
aAdd( _aCabPV, { "C5_I_FLFNC"   ,SC5->C5_I_FLFNC , Nil})
//====================================================================================================

//====================================================================================================
// Monta o item do pedido
SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )

While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM

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

    SC6->( DBSkip() )

EndDo
//====================================================================================================

//====================================================================================================
// Alteração do pedido de Pallet para consegui estornar
lMsErroAuto:=.F.

MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , 4 )

lErroSC9:=.F.
SC9->( DBSetOrder(1) )

_cPedidoP := AllTrim(SC5->C5_NUM)

If lMsErroAuto .Or. ( lErroSC9:=SC9->( DBSeek( SC5->C5_FILIAL+SC5->C5_NUM ) ))//Se liberou o estoque nao pode achar no SC9, portanto se char é um erro

    If lErroSC9
        If ! _lAutomatico
           MessageBox("Erro ao Estornar a liberação do pedido de Pallet, ainda tem dados de liberacao (SC9)." , 'Atenção! (OMSA200P)' , 48 )
        Else
           _cMsgEstorno := "Erro ao Estornar a liberação do pedido de Pallet, ainda tem dados de liberacao (SC9)."
        EndIf
    Else
       If ! _lAutomatico
          MostraErro()
       Else
          _cMsgEstorno := MostraErro("\system\", "Estorno_Pedido_Pallet_"+_cPedidoP+"_"+DToC(Date())+"_"+Time()+".log")
       EndIf
    EndIf

    Return .F.

EndIf
//====================================================================================================

//====================================================================================================
// Estorno do pedido de Pallet
MSEXECAUTO({|x,y,z| MATA410(x,y,z)}, _aCabPV , _aItensPV ,5)

If lMSERROAUTO
   If ! _lAutomatico
      MOSTRAERRO()
   Else
      _cMsgEstorno := MostraErro("\system\", "Estorno_Pedido_Pallet_"+_cPedidoP+"_"+DToC(Date())+"_"+Time()+".log")
   EndIf

   Return .F.

Else

   // LIMPA O NUMERO DO PEDIDO DE PALLET do Pedido que gerou o Pedido de Pallet
   SC5->(DBSetOrder(1))
   If SC5->( DBSeek( xFilial("SC5") + _cPedGerou ) )//Pedido que gerou o Pallet
      SC5->(RecLock("SC5",.F.))
      SC5->C5_I_NPALE := ""
      SC5->C5_I_PEDPA := ""
      SC5->C5_I_PEDGE := ""
      SC5->(MSUnLock())
   EndIf

EndIf
//====================================================================================================

Return .T.
