/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |10/06/2025| Chamado 45229. Tratamento para validar FWIsInCallStack("U_AOMS085B") junto com FWIsInCallStack("U_ALTERAP").
Alex Wallauer |11/09/2025| Chamado 52085. Correção do error.log: variable does not exist _CAOMS074VLD on U_AOMS098(AOMS098.PRW) Line : 626.
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AOMS098
Autor-------------: Julio de Paula Paz
Data da Criacao---: 12/04/2017
Descrição---------: Rotina de gravação dos dados de  Desmembramento de Pedidos de Vendas. - Chamado 16681
Parametros--------: _cFilial = Código da Filial
                    _cPedido = Numero do Pedido de Vendas
                    _aItensPedido = Array de duas colunas, podendo ter nLinhas, contendo: {Numero_do_Item, quantidade_do_item}
                    _ccodusuario - Código do usuário a ser gravado no C5_USRLGA
Retorno-----------: Array com três posições contendo: {_lSucesso, _numero_novo_pedido,_cMensagem_Retorno}
                    _lSucesso = Variável do tipo lógico, indica se hove ou não sucesso no desmembramento do pedido de vendas.
                    _numero_novo_pedido = numero do novo pedido de vendas.
                    _cMensagem_Retorno = Mensagem retornada tanto no sucesso como na falha do desmembramento do pedido de vendas.
===============================================================================================================================
*/
User Function AOMS098(_cFilial,_cPedido,_aItensPedido,_ccodusuario)

Local _aCabPV, _aItemPV, _aItensPV
Local _aCabPVNovo, _aItemPVNovo, _aItensPVNovo
Local _aRet
Local _aOrd:= SaveOrd({"SC5","SC6"})
Local _nRegSC5, _nRegSC6
Local _cMsg, _lSucesso, _cNumPed
Local _cItem
Local _nTamItem   := TamSX3("C6_ITEM")[1]
Local _nI, _nQtd, _nQtd_A, _nQtd_B
Local _cPedidoNovo
Local _cNovoNum
Local _nPosVLIBB, _nPosQLIBB, _nVLIBB, _nQLIBB, _nVLIBBNovo, _nQLIBBNovo
Local _nFatConv
Local _nPesoMinimo := SuperGetMV("IT_PEBLSLD",.F.,3000)
Private 	_cAOMS074Vld:=""//Pega as mensagens de erro do MT410TOK.PRW

 If ValType(_nPesoMinimo) <> "N"
   _nPesoMinimo:=3000
 EndIf
//==========================================
//Grava log de utilização da rotina
//==========================================
//U_ITLOGACS()

Default _ccodusuario := RetCodUsr()

Begin Sequence
   _nRegSC5 := SC5->(Recno())
   _nRegSC6 := SC6->(Recno())
   _cMsg := ""
   _lSucesso := .T.
   _cNumPed := ""

   SC5->(DBSetOrder(1))
   If ! SC5->(DBSeek(_cFilial+_cPedido,))
      _cMsg := "Filial + Pedido de vendas não localizado. "
      _lSucesso := .F.
      _cNumPed := ""
      _aRet := {_lSucesso,_cNumPed,_cMsg}
      Break
   EndIf

   SC6->(DBSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO

   For _nI := 1 To Len(_aItensPedido)
       _cItem := StrZero(Val(_aItensPedido[_nI,1]) , _nTamItem)
       If ! SC6->(DBSeek(_cFilial+_cPedido+_cItem))
          _cMsg := "Item de Pedido de vendas não localizado. Filial: "+_cFilial+"/ Pedido: "+_cPedido+"/ Item: "+_cItem
          _lSucesso := .F.
          _cNumPed := ""
          _aRet := {_lSucesso,_cNumPed,_cMsg}
          Break
       EndIf
   Next

   _aCabPV  :={}
   _aItemPV :={}
   _aItensPV:={}
   If FindFunction("U_AOMS089")
      _cNovoNum:=U_AOMS089(.F.)//Aqui nessa função já tem U_ITConout´s
   Else
      //U_ITConout('****** ////  Usou GetSXENum("SC5","C5_NUM","  \DATA\"+RETSQLNAME("SC5"),24) '+TIME()+"  \\\\******")
      _cNovoNum:=GetSXENum("SC5","C5_NUM","  \DATA\"+RETSQLNAME("SC5"),24)
   EndIf

   aAdd( _aCabPV, { "C5_FILIAL"	   ,SC5->C5_FILIAL  , Nil})// 01 //filial
   aAdd( _aCabPV, { "C5_NUM"        ,SC5->C5_NUM	  , Nil})// 02
   aAdd( _aCabPV, { "C5_TIPO"	      ,SC5->C5_TIPO    , Nil})// 03 //Tipo de pedido
   aAdd( _aCabPV, { "C5_I_OPER"	   ,SC5->C5_I_OPER  , Nil})// 04 //Tipo da operacao
   aAdd( _aCabPV, { "C5_CLIENTE"    ,SC5->C5_CLIENTE , NiL})// 05 //Codigo do cliente
   aAdd( _aCabPV, { "C5_CLIENT"     ,SC5->C5_CLIENT  , Nil})// 06
   aAdd( _aCabPV, { "C5_LOJAENT"    ,SC5->C5_LOJAENT , NiL})// 07 //Loja para entrada
   aAdd( _aCabPV, { "C5_LOJACLI"    ,SC5->C5_LOJACLI , NiL})// 08 //Loja do cliente
   aAdd( _aCabPV, { "C5_EMISSAO"    ,SC5->C5_EMISSAO , NiL})// 09 //Data de emissao
   aAdd( _aCabPV, { "C5_TRANSP"     ,SC5->C5_TRANSP  , Nil})// 10
   aAdd( _aCabPV, { "C5_CONDPAG"    ,SC5->C5_CONDPAG , NiL})// 11 //Codigo da condicao de pagamanto*
   aAdd( _aCabPV, { "C5_VEND1"      ,SC5->C5_VEND1	  , Nil})// 12
   aAdd( _aCabPV, { "C5_MOEDA"      ,SC5->C5_MOEDA   , Nil})// 13 //Moeda
   aAdd( _aCabPV, { "C5_MENPAD"     ,SC5->C5_MENPAD  , Nil})// 14
   aAdd( _aCabPV, { "C5_LIBEROK"    ,SC5->C5_LIBEROK , NiL})// 15 //Liberacao Total
   aAdd( _aCabPV, { "C5_TIPLIB"     ,SC5->C5_TIPLIB  , Nil})// 16 //Tipo de Liberacao
   aAdd( _aCabPV, { "C5_TIPOCLI"    ,SC5->C5_TIPOCLI , NiL})// 17 //Tipo do Cliente
   aAdd( _aCabPV, { "C5_I_NPALE"    ,SC5->C5_I_NPALE , NiL})// 18 //Numero que originou a pedido de palete
   aAdd( _aCabPV, { "C5_I_PEDPA"    ,SC5->C5_I_PEDPA , NiL})// 19 //Pedido Refere a um pedido de Pallet
   aAdd( _aCabPV, { "C5_I_DTENT"    ,SC5->C5_I_DTENT , Nil})// 20 //Dt de Entrega // SC5->C5_I_DTENT
   aAdd( _aCabPV, { "C5_I_TRCNF"    ,SC5->C5_I_TRCNF , Nil})// 21
   aAdd( _aCabPV, { "C5_I_OBCOP" 	,SC5->C5_I_OBCOP , Nil})// 22
   aAdd( _aCabPV, { "C5_I_OBPED" 	,SC5->C5_I_OBPED , Nil})// 23
   aAdd( _aCabPV, { "C5_I_BLPRC"    ,SC5->C5_I_BLPRC , Nil})// 24
   aAdd( _aCabPV, { "C5_I_BLCRE"    ,SC5->C5_I_BLCRE , Nil})// 25
   aAdd( _aCabPV, { "C5_I_FILFT"    ,SC5->C5_I_FILFT , Nil})// 26
   aAdd( _aCabPV, { "C5_I_FLFNC"    ,SC5->C5_I_FLFNC , Nil})// 27
   aAdd( _aCabPV, { "C5_I_BLCRE"    ,SC5->C5_I_BLCRE , Nil})// 28
   aAdd( _aCabPV, { "C5_I_TIPCA"    ,SC5->C5_I_TIPCA , Nil})// 29
   aAdd( _aCabPV, { "C5_MENNOTA"    ,SC5->C5_MENNOTA , Nil})// 30
   aAdd( _aCabPV, { "C5_MENPAD"     ,SC5->C5_MENPAD  , Nil})// 31
   aAdd( _aCabPV, { "C5_I_PODES"    ,SC5->C5_NUM     , Nil}) ; nPosPODES:=Len(_aCabPV) // 32
   aAdd( _aCabPV, { "C5_I_BLPRC"    ,SC5->C5_I_BLPRC , Nil})// 33
   aAdd( _aCabPV, { "C5_I_DTLIB"    ,SC5->C5_I_DTLIB , Nil})// 34
   aAdd( _aCabPV, { "C5_I_IDPED"    ,SC5->C5_I_IDPED , Nil})// 35
   aAdd( _aCabPV, { "C5_ORIGEM "    ,SC5->C5_ORIGEM  , Nil})// 36
   aAdd( _aCabPV, { "C5_I_DTAIM"    ,SC5->C5_I_DTAIM , Nil})// 37
   aAdd( _aCabPV, { "C5_I_HORAI"    ,SC5->C5_I_HORAI , Nil})// 38
   aAdd( _aCabPV, { "C5_I_DATAA"    ,SC5->C5_I_DATAA , Nil})// 39
   aAdd( _aCabPV, { "C5_I_HORAA"    ,SC5->C5_I_HORAA , Nil})// 40
   aAdd( _aCabPV, { "C5_I_DTLIP"    ,SC5->C5_I_DTLIP , Nil})// 41
   aAdd( _aCabPV, { "C5_I_MLIBP"    ,SC5->C5_I_MLIBP , Nil})// 42
   aAdd( _aCabPV, { "C5_I_DTAVA"    ,SC5->C5_I_DTAVA , Nil})// 43
   aAdd( _aCabPV, { "C5_I_HRAVA"    ,SC5->C5_I_HRAVA , Nil})// 44
   aAdd( _aCabPV, { "C5_I_USRAV"    ,SC5->C5_I_USRAV , Nil})// 45
   aAdd( _aCabPV, { "C5_I_LIBCA"    ,SC5->C5_I_LIBCA , Nil})// 46
   aAdd( _aCabPV, { "C5_I_LIBCT"    ,SC5->C5_I_LIBCT , Nil})// 47
   aAdd( _aCabPV, { "C5_I_LIBL "    ,SC5->C5_I_LIBL  , Nil})// 48
   aAdd( _aCabPV, { "C5_I_LIBCV"    ,SC5->C5_I_LIBCV , Nil})// 49
   aAdd( _aCabPV, { "C5_I_LIBCD"    ,SC5->C5_I_LIBCD , Nil})// 50
   aAdd( _aCabPV, { "C5_I_BLCRE"    ,SC5->C5_I_BLCRE , Nil})// 51
   aAdd( _aCabPV, { "C5_I_MOTBL"    ,SC5->C5_I_MOTBL , Nil})// 52
   aAdd( _aCabPV, { "C5_I_DTLIC"    ,SC5->C5_I_DTLIC , Nil})// 53
   aAdd( _aCabPV, { "C5_I_PLIBP"    ,SC5->C5_I_PLIBP , Nil})// 54
   aAdd( _aCabPV, { "C5_I_ULIBP"    ,SC5->C5_I_ULIBP , Nil})// 55
   aAdd( _aCabPV, { "C5_I_VLIBP"    ,SC5->C5_I_VLIBP , Nil})// 56
   aAdd( _aCabPV, { "C5_I_MOTLP"    ,SC5->C5_I_MOTLP , Nil})// 57
   aAdd( _aCabPV, { "C5_I_MOTLB"    ,SC5->C5_I_MOTLB , Nil})// 58
   aAdd( _aCabPV, { "C5_I_QLIBP"    ,SC5->C5_I_QLIBP , Nil})// 59
   aAdd( _aCabPV, { "C5_I_VLIBB"    ,SC5->C5_I_VLIBB , Nil})// 60
   aAdd( _aCabPV, { "C5_I_QLIBB"    ,SC5->C5_I_QLIBB , Nil})// 61
   aAdd( _aCabPV, { "C5_I_CLILP"    ,SC5->C5_I_CLILP , Nil})// 62
   aAdd( _aCabPV, { "C5_I_CLILB"    ,SC5->C5_I_CLILB , Nil})// 63
   aAdd( _aCabPV, { "C5_I_LLIBB"    ,SC5->C5_I_LLIBB , Nil})// 64
   aAdd( _aCabPV, { "C5_I_ULIBB"    ,SC5->C5_I_ULIBB , Nil})// 65
   aAdd( _aCabPV, { "C5_I_LLIBP"    ,SC5->C5_I_LLIBP , Nil})// 66
   aAdd( _aCabPV, { "C5_I_HLIBP"    ,SC5->C5_I_HLIBP , Nil})// 67
   aAdd( _aCabPV, { "C5_I_FILOR"    ,SC5->C5_I_FILOR , Nil})// 68
   aAdd( _aCabPV, { "C5_I_PEDOR"   , IIf(Empty(SC5->C5_I_PEDOR),SC5->C5_NUM, SC5->C5_I_PEDOR), Nil})//69
   aAdd( _aCabPV, { "C5_I_DTRAN"    ,SC5->C5_I_DTRAN, Nil})
   aAdd( _aCabPV, { "C5_I_UTRAN"    ,SC5->C5_I_UTRAN, Nil})
   aAdd( _aCabPV, { "C5_I_MTRAN"    ,SC5->C5_I_MTRAN, Nil})
   aAdd( _aCabPV, { "C5_I_HORP "    ,SC5->C5_I_HORP , Nil})
   aAdd( _aCabPV, { "C5_I_AGEND"    ,SC5->C5_I_AGEND, Nil}) ;  nPosAGEND:=Len(_aCabPV)
   aAdd( _aCabPV, { "C5_I_CHPCL"    ,SC5->C5_I_CHPCL, Nil})
   aAdd( _aCabPV, { "C5_I_DOCA "    ,SC5->C5_I_DOCA , Nil})
   aAdd( _aCabPV, { "C5_I_TRCNF"    ,SC5->C5_I_TRCNF, Nil})
   aAdd( _aCabPV, { "C5_I_FLFNC"    ,SC5->C5_I_FLFNC, Nil})
   aAdd( _aCabPV, { "C5_I_OBSAV"    ,SC5->C5_I_OBSAV, Nil})
   aAdd( _aCabPV, { "C5_I_FILFT"    ,SC5->C5_I_FILFT, Nil})
   aAdd( _aCabPV, { "C5_I_PDFT "    ,SC5->C5_I_PDFT , Nil})
   aAdd( _aCabPV, { "C5_I_PDPR "    ,SC5->C5_I_PDPR , Nil})
   aAdd( _aCabPV, { "C5_TPFRETE"    ,If(SC5->C5_TPFRETE="R","C",SC5->C5_TPFRETE), Nil})
   aAdd( _aCabPV, { "C5_I_PSORI"    ,SC5->C5_I_PSORI , Nil})

   aAdd( _aCabPV, { "C5_I_TAB"     ,SC5->C5_I_TAB   , Nil})
   aAdd( _aCabPV, { "C5_I_PEDDW"   ,SC5->C5_I_PEDDW , Nil})
   aAdd( _aCabPV, { "C5_I_TPVEN"   ,SC5->C5_I_TPVEN , Nil})
   aAdd( _aCabPV, { "C5_VEND2"     ,SC5->C5_VEND2	 , Nil})
   aAdd( _aCabPV, { "C5_VEND3"     ,SC5->C5_VEND3	 , Nil})
   aAdd( _aCabPV, { "C5_VEND4"     ,SC5->C5_VEND4	 , Nil})
   aAdd( _aCabPV, { "C5_VEND5"     ,SC5->C5_VEND5	 , Nil})

   aAdd( _aCabPV, { "C5_I_SENHA"   ,SC5->C5_I_SENHA , Nil})
   aAdd( _aCabPV, { "C5_I_NRZAZ"   ,SC5->C5_I_NRZAZ , Nil})
   aAdd( _aCabPV, { "C5_I_LIBC"    ,SC5->C5_I_LIBC	 , Nil})

// ----------------------------------------------------------------
   aAdd( _aCabPV, { "C5_I_OPTRI"   ,SC5->C5_I_OPTRI  , Nil}) // Tipo PV na operacao trian
   aAdd( _aCabPV, { "C5_I_PVREM"   ,SC5->C5_I_PVREM  , Nil}) // Pedido de Remessa
   aAdd( _aCabPV, { "C5_I_PVFAT"   ,SC5->C5_I_PVFAT  , Nil}) // Pedido de FAturamento
   aAdd( _aCabPV, { "C5_I_CLIEN"   ,SC5->C5_I_CLIEN  , Nil}) // Cli Remessa
   aAdd( _aCabPV, { "C5_I_LOJEN"   ,SC5->C5_I_LOJEN  , Nil}) // Loj Remessa
   If SC5->(FIELDPOS("C5_I_BLSLD")) > 0
      aAdd( _aCabPV, { "C5_I_BLSLD",SC5->C5_I_BLSLD  , Nil}) // Bloq. de carregamentro p/ Saldo
   EndIf
   nPosBLSLD:=Len(_aCabPV)
//-----------------------------------------------------------------

   _aCabPVNovo := AClone(_aCabPV)

   //==============================================================================
   // Complementa os dados da capa do novo pedido de vendas.
   //==============================================================================
   aAdd( _aCabPVNovo, { "C5_I_BLOQ"    ,SC5->C5_I_BLOQ  , Nil})
   aAdd( _aCabPVNovo, { "C5_I_MTBON"   ,SC5->C5_I_MTBON , Nil})
   aAdd( _aCabPVNovo, { "C5_I_DLIBE"   ,SC5->C5_I_DLIBE , Nil})
   aAdd( _aCabPVNovo, { "C5_I_HLIBE"   ,SC5->C5_I_HLIBE , Nil})
   aAdd( _aCabPVNovo, { "C5_I_STAWF"   ,SC5->C5_I_STAWF , Nil})

   //==============================================================================
   // Calcula e grava os arrays dos itens.
   //==============================================================================
   _aItemPVNovo := {}
   _aItensPVNovo := {}

   _nvalori := 0
   _nvalnovo := 0
   _nlibpnovo := 0
   _nlibpori := 0
	_cAOMS074Vld:=""//Pega as mensagens de erro do MT410TOK.PRW

   // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
   SC6->(DBSetOrder(1))
   SC6->(DBSeek(_cFilial+_cPedido))
   While ! SC6->(Eof()) .And. SC6->(C6_FILIAL+C6_NUM) == _cFilial+_cPedido

       _lRemoveItem := .T.
      _nQtd_A := SC6->C6_QTDVEN
      _nQtd_B := SC6->C6_QTDVEN

      _nI := aScan(_aItensPedido,{|x| x[1] == SC6->C6_ITEM})
      If _nI > 0
         _nQtd := SC6->C6_QTDVEN - _aItensPedido[_nI,2]
         _nQtd_A := 0
         _nQtd_B := 0

         If _aItensPedido[_nI,2] > 0
             _lRemoveItem := .F.
            _nQtd_A := _aItensPedido[_nI,2]
            _nQtd_B := _nQtd
         ElseIf _aItensPedido[_nI,2] <= 0
            _lRemoveItem := .T.
            _nQtd_A := 0
            _nQtd_B := SC6->C6_QTDVEN
         EndIf
      EndIf

      SB1->(MsSeek(xFilial("SB1")+SC6->C6_PRODUTO ))

      _nFatConv := SB1->B1_CONV

      If SB1->B1_CONV == 0
         _nFatConv := SB1->B1_I_FATCO
      EndIf

      If SB1->B1_TIPCONV == "M"
         _n2Qtd_A := _nQtd_A * _nFatConv // SB1->B1_CONV
         _n2Qtd_B := _nQtd_B * _nFatConv // SB1->B1_CONV
      Else
         _n2Qtd_A := _nQtd_A / _nFatConv // SB1->B1_CONV
         _n2Qtd_B := _nQtd_B / _nFatConv // SB1->B1_CONV
      EndIf

      If ! _lRemoveItem .And. _nI > 0
         _cDeleta := "N"
      Else
         _cDeleta := "S"
         _n2Qtd_A := SC6->C6_UNSVEN
         _nQtd_A := SC6->C6_QTDVEN

      EndIf

      _aItemPV:={}
	  aAdd( _aItemPV , { "LINPOS"     ,"C6_ITEM", SC6->C6_ITEM }) //  Informa a posição do item
      aAdd( _aItemPV , { "AUTDELETA"  ,_cDeleta        , Nil }) // Informa se o item será ou não excluído.
	  aAdd( _aItemPV , { "C6_FILIAL"  ,SC6->C6_FILIAL  , Nil }) // FILIAL
	  aAdd( _aItemPV , { "C6_NUM"     ,SC6->C6_NUM     , Nil }) // Num. Pedido
	  aAdd( _aItemPV , { "C6_ITEM"    ,SC6->C6_ITEM    , Nil }) // Numero do Item no Pedido
	  aAdd( _aItemPV , { "C6_PRODUTO" ,SC6->C6_PRODUTO , Nil }) // Codigo do Produto
	  aAdd( _aItemPV , { "C6_UNSVEN"  ,_n2Qtd_A        , Nil }) // Quantidade Vendida 2 un
	  aAdd( _aItemPV , { "C6_QTDVEN"  ,_nQtd_A         , Nil }) // Quantidade Vendida
	  aAdd( _aItemPV , { "C6_PRCVEN"  ,SC6->C6_PRCVEN  , Nil }) // Preco Unitario Liquido
	  aAdd( _aItemPV , { "C6_PRUNIT"  ,SC6->C6_PRUNIT  , Nil }) // Preco Unitario Liquido
	  aAdd( _aItemPV , { "C6_ENTREG"  ,SC6->C6_ENTREG  , Nil }) // Data da Entrega
	  aAdd( _aItemPV , { "C6_LOJA"    ,SC6->C6_LOJA	   , Nil })
	  aAdd( _aItemPV , { "C6_SUGENTR" ,SC6->C6_SUGENTR , Nil }) // Data da Entrega
	  aAdd( _aItemPV , { "C6_VALOR"   ,Round((SC6->C6_PRCVEN * _nQtd_A),2), Nil }) // valor total do item // SC6->C6_VALOR
	  aAdd( _aItemPV , { "C6_UM"      ,SC6->C6_UM      , Nil }) // Unidade de Medida Primar.
	  aAdd( _aItemPV , { "C6_TES"     ,SC6->C6_TES     , Nil })
	  aAdd( _aItemPV , { "C6_LOCAL"   ,SC6->C6_LOCAL   , Nil }) // Almoxarifado
	  aAdd( _aItemPV , { "C6_CF"      ,SC6->C6_CF	  , Nil })
	  aAdd( _aItemPV , { "C6_DESCRI"  ,SC6->C6_DESCRI  , Nil }) // Descricao
	  aAdd( _aItemPV , { "C6_QTDLIB"  ,SC6->C6_QTDLIB  , Nil }) // Quantidade Liberada
	  aAdd( _aItemPV , { "C6_PEDCLI"  ,SC6->C6_PEDCLI  , Nil })
	  aAdd( _aItemPV , { "C6_I_BLPRC" ,SC6->C6_I_BLPRC , Nil })
      aAdd( _aItemPV , { "C6_I_QPALT" ,Round((SC6->C6_I_QPALT/(_NQTD_A + _NQTD_B))*_nQtd_A,0), Nil }) // Quantidade de Pallets
      aAdd( _aItemPV,  { "C6_I_USER "    ,SC6->C6_I_USER , Nil})
      aAdd( _aItemPV,  { "C6_I_LIBPC"    ,SC6->C6_I_LIBPC, Nil})
      aAdd( _aItemPV,  { "C6_I_DLIBP"    ,SC6->C6_I_DLIBP, Nil})
      aAdd( _aItemPV,  { "C6_I_PLIBP"    ,SC6->C6_I_PLIBP, Nil})
      aAdd( _aItemPV,  { "C6_I_ULIBP"    ,SC6->C6_I_ULIBP, Nil})
      aAdd( _aItemPV,  { "C6_I_VLIBP"    ,SC6->C6_I_VLIBP, Nil})
      aAdd( _aItemPV,  { "C6_I_MOTLP"    ,SC6->C6_I_MOTLP, Nil})
      aAdd( _aItemPV,  { "C6_I_QTLIP"    ,_nQtd_A, Nil})
      aAdd( _aItemPV,  { "C6_I_CLILP"    ,SC6->C6_I_CLILP, Nil})
      aAdd( _aItemPV,  { "C6_I_CLILB"    ,SC6->C6_I_CLILB, Nil})
      aAdd( _aItemPV,  { "C6_I_VLIBB"    ,SC6->C6_I_VLIBB, Nil})
      aAdd( _aItemPV,  { "C6_I_QLIBB"    ,_nQtd_A, Nil})
      aAdd( _aItemPV,  { "C6_I_LLIBP"    ,SC6->C6_I_LLIBP, Nil})
      aAdd( _aItemPV,  { "C6_I_LLIBB"    ,SC6->C6_I_LLIBB, Nil})
      aAdd( _aItemPV,  { "C6_I_MOTLB"    ,SC6->C6_I_MOTLB, Nil})
      aAdd( _aItemPV,  { "C6_I_PLIBB"    ,SC6->C6_I_PLIBB, Nil})
      aAdd( _aItemPV,  { "C6_I_DLIBB"    ,SC6->C6_I_DLIBB, Nil})
      aAdd( _aItemPV,  { "C6_COMIS1"     ,SC6->C6_COMIS1, Nil})
      aAdd( _aItemPV,  { "C6_COMIS2"     ,SC6->C6_COMIS2, Nil})
      aAdd( _aItemPV,  { "C6_COMIS3"     ,SC6->C6_COMIS3, Nil})
      aAdd( _aItemPV,  { "C6_COMIS4"     ,SC6->C6_COMIS4, Nil})
      aAdd( _aItemPV,  { "C6_COMIS5"     ,SC6->C6_COMIS5, Nil})
      aAdd( _aItemPV,  { "C6_I_PDESC"    ,SC6->C6_I_PDESC, Nil})
      aAdd( _aItemPV,  { "C6_I_VLTAB"    ,SC6->C6_I_VLTAB, Nil})
      aAdd( _aItemPV,  { "C6_I_PRMIN"    ,SC6->C6_I_PRMIN, Nil})
      aAdd( _aItemPV,  { "C6_ITEMPC"     ,SC6->C6_ITEMPC, Nil})

      If _cDeleta != "S"

       	_nvalori += Round((SC6->C6_PRCVEN * _nQtd_A),2)
       	_nlibpori += Round((SC6->C6_I_VLIBP * _nQtd_A),2)

      EndIf

      aAdd( _aItensPV ,_aItemPV )

      If  _nQtd_B > 0
         _aItemPVNovo:={}
	     aAdd( _aItemPVNovo , { "C6_FILIAL"  ,SC6->C6_FILIAL  , Nil }) // FILIAL
	     aAdd( _aItemPVNovo , { "C6_NUM"     ,_cNovoNum     , Nil }) // Num. Pedido
	     aAdd( _aItemPVNovo , { "C6_ITEM"    ,SC6->C6_ITEM    , Nil }) // Numero do Item no Pedido
	     aAdd( _aItemPVNovo , { "C6_PRODUTO" ,SC6->C6_PRODUTO , Nil }) // Codigo do Produto
	     aAdd( _aItemPVNovo , { "C6_UNSVEN"  ,_n2Qtd_B        , Nil }) // Quantidade Vendida 2 un
	     aAdd( _aItemPVNovo , { "C6_QTDVEN"  ,_nQtd_B         , Nil }) // Quantidade Vendida
	     aAdd( _aItemPVNovo , { "C6_PRCVEN"  ,SC6->C6_PRCVEN  , Nil }) // Preco Unitario Liquido
	     aAdd( _aItemPVNovo , { "C6_PRUNIT"  ,SC6->C6_PRUNIT  , Nil }) // Preco Unitario Liquido
	     aAdd( _aItemPVNovo , { "C6_ENTREG"  ,SC6->C6_ENTREG  , Nil }) // Data da Entrega
	     aAdd( _aItemPVNovo , { "C6_LOJA"    ,SC6->C6_LOJA	   , Nil })
	     aAdd( _aItemPVNovo , { "C6_SUGENTR" ,SC6->C6_SUGENTR , Nil }) // Data da Entrega
	     aAdd( _aItemPVNovo , { "C6_VALOR"   ,Round((SC6->C6_PRCVEN * _nQtd_B),2), Nil }) // valor total do item // SC6->C6_VALOR
	     aAdd( _aItemPVNovo , { "C6_UM"      ,SC6->C6_UM      , Nil }) // Unidade de Medida Primar.
	     aAdd( _aItemPVNovo , { "C6_TES"     ,SC6->C6_TES     , Nil })
	     aAdd( _aItemPVNovo , { "C6_LOCAL"   ,SC6->C6_LOCAL   , Nil }) // Almoxarifado
	     aAdd( _aItemPVNovo , { "C6_CF"      ,SC6->C6_CF	  , Nil })
	     aAdd( _aItemPVNovo , { "C6_DESCRI"  ,SC6->C6_DESCRI  , Nil }) // Descricao
	     aAdd( _aItemPVNovo , { "C6_QTDLIB"  ,SC6->C6_QTDLIB  , Nil }) // Quantidade Liberada
	     aAdd( _aItemPVNovo , { "C6_PEDCLI"  ,SC6->C6_PEDCLI  , Nil })
	     aAdd( _aItemPVNovo , { "C6_I_BLPRC" ,SC6->C6_I_BLPRC , Nil })
	     aAdd( _aItemPVNovo , { "C6_I_QPALT" ,Round((SC6->C6_I_QPALT/(_NQTD_A + _NQTD_B))*_nQtd_B,0), Nil }) // Quantidade de Pallets
         aAdd( _aItemPVNovo,  { "C6_I_USER "    ,SC6->C6_I_USER , Nil})
         aAdd( _aItemPVNovo,  { "C6_I_LIBPC"    ,SC6->C6_I_LIBPC, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_DLIBP"    ,SC6->C6_I_DLIBP, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_PLIBP"    ,SC6->C6_I_PLIBP, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_ULIBP"    ,SC6->C6_I_ULIBP, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_VLIBP"    ,SC6->C6_I_VLIBP, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_MOTLP"    ,SC6->C6_I_MOTLP, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_QTLIP"    ,_nQtd_B, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_CLILP"    ,SC6->C6_I_CLILP, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_CLILB"    ,SC6->C6_I_CLILB, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_VLIBB"    ,SC6->C6_I_VLIBB, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_QLIBB"    ,(SC6->C6_I_QLIBB/(_NQTD_A + _NQTD_B))*_nQtd_B, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_LLIBP"    ,SC6->C6_I_LLIBP, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_LLIBB"    ,SC6->C6_I_LLIBB, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_MOTLB"    ,SC6->C6_I_MOTLB, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_PLIBB"    ,SC6->C6_I_PLIBB, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_DLIBB"    ,SC6->C6_I_DLIBB, Nil})
         aAdd( _aItemPVNovo,  { "C6_COMIS1"     ,SC6->C6_COMIS1, Nil})
         aAdd( _aItemPVNovo,  { "C6_COMIS2"     ,SC6->C6_COMIS2, Nil})
         aAdd( _aItemPVNovo,  { "C6_COMIS3"     ,SC6->C6_COMIS3 , Nil})
         aAdd( _aItemPVNovo,  { "C6_COMIS4"     ,SC6->C6_COMIS4 , Nil})
         aAdd( _aItemPVNovo,  { "C6_COMIS5"     ,SC6->C6_COMIS5 , Nil})
         aAdd( _aItemPVNovo,  { "C6_DTFIMNT"    ,SC6->C6_DTFIMNT, Nil})
         aAdd( _aItemPVNovo,  { "C6_DATCPL"     ,SC6->C6_DATCPL , Nil})
         aAdd( _aItemPVNovo,  { "C6_DATAEMB"    ,SC6->C6_DATAEMB, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_PDESC"    ,SC6->C6_I_PDESC, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_VLTAB"    ,SC6->C6_I_VLTAB, Nil})
         aAdd( _aItemPVNovo,  { "C6_I_PRMIN"    ,SC6->C6_I_PRMIN, Nil})
         aAdd( _aItemPVNovo,  { "C6_ITEMPC"     ,SC6->C6_ITEMPC,  Nil})

         _nvalnovo += Round((SC6->C6_PRCVEN * _nQtd_B),2)
         _nlibpnovo += Round((SC6->C6_I_VLIBP * _nQtd_B),2)

         aAdd( _aItensPVNovo ,_aItemPVNovo )
      EndIf

      SC6->(DBSkip())
   End Do

   //======================================================================
   //Se não tem itens para o pedido desmembrado encerra o processamento
   //======================================================================
   If Len(_aitenspvnovo) == 0 .Or. Len(_aitenspv) == 0

         //u_itconout("Não há itens a desmembrar do pedido de vendas: "+AllTrim(_cPedido)+". "+" - "+DToC(DATE())+" - "+TIME())
         _cMsg := "SUCESSO:FALSE; Não há itens a desmembrar do pedido de vendas: "+AllTrim(_cPedido)+". "
         _lSucesso := .F.

         Break

   EndIf


   //======================================================================
   // Calcula a quantidade e o valor liberado de bonificação para os itens
   // do pedido de origem.
   //======================================================================
   _nPosVLIBB := aScan(_aItensPV[1],{|x| x[1] == "C6_VALOR"})
   _nPosQLIBB := aScan(_aItensPV[1],{|x| x[1] == "C6_QTDVEN"})
   _nVLIBB := 0
   _nQLIBB := 0

   For _nI := 1 To Len(_aItensPV)
       _nVLIBB += _aItensPV[_nI,_nPosVLIBB,2]
       _nQLIBB += _aItensPV[_nI,_nPosQLIBB,2]
   Next

   //======================================================================
   // Calcula a quantidade e o valor liberado de bonificação para os itens
   // do novo pedido de vendas.
   //======================================================================
   _nPosVLIBB := aScan(_aItensPVNovo[1],{|x| x[1] == "C6_VALOR"})
   _nPosQLIBB := aScan(_aItensPVNovo[1],{|x| x[1] == "C6_QTDVEN"})
   _nVLIBBNovo := 0
   _nQLIBBNovo := 0

   For _nI := 1 To Len(_aItensPVNovo)
       _nVLIBBNovo += _aItensPVNovo[_nI,_nPosVLIBB,2]
       _nQLIBBNovo += _aItensPVNovo[_nI,_nPosQLIBB,2]
   Next

   //======================================================================
   // Atualiza capa do pedido de vendas Original
   //======================================================================
   _nPosVLIBB := aScan(_aCabPV,{|x| x[1] == "C5_I_VLIBB"})
   _nPosQLIBB := aScan(_aCabPV,{|x| x[1] == "C5_I_QLIBB"})

   _aCabPV[_nPosVLIBB,2] := _nVLIBB
   _aCabPV[_nPosQLIBB,2] := _nQLIBB

   //======================================================================
   // Atualiza capa do novo pedido de vendas.
   //======================================================================
   _nPosVLIBB := aScan(_aCabPVNovo,{|x| x[1] == "C5_I_VLIBB"})
   _nPosQLIBB := aScan(_aCabPVNovo,{|x| x[1] == "C5_I_QLIBB"})

   _aCabPVNovo[_nPosVLIBB,2] := _nVLIBBNovo
   _aCabPVNovo[_nPosQLIBB,2] := _nQLIBBNovo

   //======================================================================
   _cPedido := SC5->C5_NUM

   _cPedidoNovo := ""

   //======================================================================
   // Grava alteração do pedido de vendas que foi desmembrado.
   //======================================================================
      _cMsg := ""
      _lSucesso := .T.
      _cNumPed := ""

      lMsErroAuto:=.F.
      _cMsgErro:=""

		_cAOMS074   :="AOMS098"//DesAtiva o _lMsgEmTela := .F. no MT410TOK.PRW

      _aCabPv[nPosPODES][2] := _cNovoNum //grava referência do pedido desmembrado
      _npedlibc := _aCabPv[49][2]
      _npedlibp := _aCabPv[56][2]
      _npedlibb := _aCabPv[59][2]
      _aCabPv[49][2] := Round(((_nvalori/(_nvalnovo+_nvalori)) * _aCabPv[49][2]),2) //proporção de credito liberado
      _aCabPv[59][2] := Round(((_nlibpori/(_nlibpnovo+_nlibpori)) * _aCabPv[59][2]),2) //proporção de preço liberado
      _aCabPv[60][2] := Round(((_nvalori/(_nvalnovo+_nvalori)) * _aCabPv[60][2]),2) //proporção de bonificação liberada

      MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , 4 )//PEDIDO ATUAL - ALTERARCAO

      //u_itconout("Integra para o sistema RDC o status do pedido de vendas, Alterado pelo sistema RDC: " + AllTrim(SC5->C5_NUM)+".")
      U_ENVSITPV()

      If lMsErroAuto
         _cNomeArqLog := "Pedido_"+AllTrim(_cPedido)+"_"+DToS(Date())+"_"+StrTran(Time(),":","_")+".log"
         If FWIsInCallStack( 'U_AOMS099' )
            _cMsgErro := MostraErro()
         Else
            _cMsgErro := MostraErro("\data\logs_generico\", _cNomeArqLog)
         EndIf
         //u_itconout("Erro no desmembramento do pedido de vendas: "+AllTrim(_cPedido)+". "+_cMsgErro)
         _cMsg := "SUCESSO:FALSE; Erro no desmembramento do pedido de vendas: "+AllTrim(_cPedido)+". "+_cMsgErro
         _lSucesso := .F.

         Break
      Else
         _cPedido := SC5->C5_NUM

         //Garante a correta gravação dos campos do cabeçalho
         RecLock("SC5",.F.)
         _nI := 1
         While _nI <= Len(_aCabPV)

         	&("SC5->" + _aCabPV[_nI][1]) := _aCabPV[_nI][2]

         	_nI++

         EndDo

         SC5->C5_I_VLIBB := _nVLIBB
         SC5->C5_I_QLIBB := _nQLIBB
         SC5->C5_USERLGA := u_retlgilga(_cCodUsuario)

         SC5->(MSUnLock())

          //u_itconout("Desmembramento do pedido de vendas realizado com sucesso: "+AllTrim(_cPedido)+".")
         _cMsg := "SUCESSO:TRUE; Desmembramento do pedido de vendas realizado com sucesso:"+AllTrim(_cPedido)+"."
      EndIf

      If Len(_aItensPVNovo) < 1
      	 //u_itconout("Erro na inclusão do novo pedido de vendas, resultado do desmembramento. Não há itens selecionados para o novo pedido ")
         _cMsg := "SUCESSO:FALSE; Erro na inclusão do novo pedido de vendas, resultado do desmembramento. Não há itens selecionados para o novo pedido "
         _lSucesso := .F.
         Break
      EndIf

      //======================================================================
      // Grava novo pedido de vendas com os dados restantes do desmembrado.
      //======================================================================
      lMsErroAuto:=.F.
      _aCabPv[02][2] := _cNovoNum //grava novo numero do pedido
      _aCabPv[32][2] := SC5->C5_NUM //grava referencia ao pedido gerador
      _aCabPv[49][2] := Round(((_nvalnovo/(_nvalnovo+_nvalori)) * _npedlibc),2) //proporção de credito liberado
      _aCabPv[59][2] := Round(((_nlibpnovo/(_nlibpnovo+_nlibpori)) * _npedlibp),2) //proporção de preço liberado
      _aCabPv[60][2] := Round(((_nvalnovo/(_nvalnovo+_nvalori)) * _npedlibb),2) //proporção de bonificação liberada

      MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPVNovo , 3 )//PEDIDO NOVO - Inclusao

      If lMsErroAuto
         _cNomeArqLog := "Pedido_"+AllTrim(_cPedido)+"_novo_"+DToS(Date())+"_"+StrTran(Time(),":","_")+".log"
         If FWIsInCallStack( 'U_AOMS099' )
            _cMsgErro := MostraErro()
         Else
            _cMsgErro := MostraErro("\data\logs_generico\", _cNomeArqLog)
         EndIf

        //u_itconout(_cMsgErro)
         _cMsg := "SUCESSO:FALSE; Erro ao Incluir PV novo: "+AllTrim(_cMsgErro)
         _lSucesso := .F.
         Break
      Else
         _cNumPed := SC5->C5_NUM
         CONFIRMSX8()

         //Garante a correta gravação dos campos do cabeçalho
         RecLock("SC5",.F.)
         _nI := 1

         While _nI <= Len(_aCabPV)
         	&("SC5->" + _aCabPV[_nI][1]) := _aCabPV[_nI][2]
         	_nI++
         EndDo

         If SC5->(FIELDPOS("C5_I_BLSLD")) > 0
            If FWIsInCallStack("U_ALTERAP") .And. FWIsInCallStack("U_AOMS085B") .And. SC5->C5_I_PESBR <=  _nPesoMinimo
               SC5->C5_I_BLSLD:="S"
            Else
               SC5->C5_I_BLSLD:="N"
            EndIf
         EndIf

         SC5->C5_I_VLIBB := _nVLIBBNovo
         SC5->C5_I_QLIBB := _nQLIBBNovo
         SC5->C5_USERLGA := u_retlgilga(_cCodUsuario)
         SC5->C5_USERLGI := u_retlgilga(_cCodUsuario)
         SC5->C5_I_CDUSU := FWSFAllUsers({_cCodUsuario},{"USR_FILIAL"})[1][3]+FWSFAllUsers({_cCodUsuario},{"USR_CODFUNC"})[1][3]
         SC5->(MSUnLock())

         //u_itconout("Inclusão do novo pedido de vendas realizado com sucesso: "+AllTrim(_cNumPed)+".")
         _cMsg := "SUCESSO:TRUE; Inclusão do novo pedido de vendas realizado com sucesso: "+AllTrim(_cNumPed)+"."

         //u_itconout("Integra para o sistema RDC o status do novo pedido de vendas, criado pelo sistema RDC: " + AllTrim(SC5->C5_NUM)+".")
         U_ENVSITPV()

      EndIf

End Sequence

If Type("_cMsgErro") != "C"
   _cMsgErro := "  "
EndIf

_aRet := {_lSucesso,;//01
          _cNumPed,;//02
          _cMsg,;//03
          LEFT(_cMsgErro,150),;//04
          _cAOMS074Vld,;//05
          _cMsgErro}//06

RestOrd(_aOrd)

Return _aRet
