/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |21/02/2022| Chamado 38650. Criada a rotina de agendamento de entrega do leite de terceiros
Lucas Borges  |22/07/2022| Chamado 40778. Tratamento para Extrato Seco Total (EST).
Lucas Borges  |23/01/2025| Chamado 49641. Implementada faixa de início e fim para pagamento do excedente de matéria gorda
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "RWMAKE.CH"

/*
===============================================================================================================================
Programa--------: AGLT019
Autor-----------: Alexandre Villar
Data da Criacao-: 03/09/2015
Descrição-------: Rotina para configurar os campos do Leite através dos pedidos de compra - Chamado 11190
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AGLT019()

Local _cAlias	:= ""
Local _lOk		:= .F.

DBSelectArea('ZA7')
ZA7->( DBSetOrder(2) )
If ZA7->( DBSeek( xFilial('ZA7') + SC7->C7_PRODUTO ) )
	_cAlias := GetNextAlias()	
	BeginSql alias _cAlias
		SELECT COUNT(1) MIX
		  FROM %Table:ZLY%
		 WHERE D_E_L_E_T_ = ' '
		   AND ZLY_FILIAL = %xFilial:ZLY%
		   AND ZLY_REFINI <= %exp:SC7->C7_EMISSAO%
		   AND ZLY_REFFIM >= %exp:SC7->C7_EMISSAO%
		   AND ZLY_DFECHA = ' '
	EndSql	

	If (_cAlias)->( !Eof() ) .And. (_cAlias)->MIX > 0
		_lOk := .T.
	Else
		MsgInfo("O período de emissão do pedido já foi Fechado e não permite alterações! Verifique o pedido selecionado.","AGLT01901")
	EndIf

	(_cAlias)->( DBCloseArea() )

	If _lOk
		_cAlias := GetNextAlias()
		BeginSql alias _cAlias
			SELECT COUNT(1) QTDNF
			  FROM %Table:ZLX% ZLX, %Table:SD1% SD1
			 WHERE ZLX.D_E_L_E_T_ = ' '
			   AND SD1.D_E_L_E_T_ = ' '
			   AND ZLX.ZLX_FILIAL = %xFilial:ZLX%
			   AND SD1.D1_FILIAL = %xFilial:SD1%
			   AND ZLX.ZLX_NRONF = SD1.D1_DOC
			   AND ZLX.ZLX_SERINF = SD1.D1_SERIE
			   AND ZLX.ZLX_FORNEC = SD1.D1_FORNECE
			   AND ZLX.ZLX_LJFORN = SD1.D1_LOJA
			   AND ZLX.ZLX_FILIAL = SD1.D1_FILIAL
			   AND SD1.D1_FORMUL <> 'S'
			   AND SD1.D1_PEDIDO = %exp:SC7->C7_NUM%
		EndSql
		If (_cAlias)->( !Eof() ) .And. (_cAlias)->QTDNF > 0
			LjMsgRun( 'Processando. . .' , 'Aguarde!' , {|| AGLT019EXE() } )
		Else
			MsgInfo("O pedido atual não está amarrado à recepções de leite de terceiros! Verifique o pedido selecionado.","AGLT01902")
		EndIf
		(_cAlias)->( DBCloseArea() )
	EndIf

Else
	MsgInfo("O produto do pedido selecionado não está relacionado à recepção do leite de terceiros! Verifique o pedido selecionado.","AGLT01903")
EndIf

Return

/*
===============================================================================================================================
Programa--------: AGLT019EXE
Autor-----------: Alexandre Villar
Data da Criacao-: 03/09/2015
Descrição-------: Rotina que monta a tela para configuração dos campos
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AGLT019EXE()

Local _oDlg		:= Nil
Local _oBtn1	:= Nil
Local _oBtn2	:= Nil
Local _oFont	:= TFont():New( "Arial" ,, 14 ,, .F. ,,,, .T. , .F. )
Local _nGet1	:= 0
Local _nGet2	:= 0
Local _nGet3	:= 0
Local _nGet4	:= 0
Local _nGet5	:= 0
Local _nGet6	:= 0
Local _nGet7	:= 0
Local _nGet8	:= 0
Local _nGet9	:= 0
Local _nOpc		:= 0

DEFINE DIALOG _oDlg FROM 0,0 TO 395,500 PIXEL

	TGroup():New( 002 , 002 , 016 , 040 , 'Pedido: '					, _oDlg ,, CLR_GRAY , .T. )
	TGroup():New( 002 , 045 , 016 , 083 , 'Emissão: '					, _oDlg ,, CLR_GRAY , .T. )
	TGroup():New( 020 , 002 , 034 , 250 , 'Fornecedor: '				, _oDlg ,, CLR_GRAY , .T. )
	TGroup():New( 038 , 002 , 052 , 250 , 'Produto: '					, _oDlg ,, CLR_GRAY , .T. )
	TGroup():New( 059 , 002 , 114 , 250 , 'Configuração do Pedido: '	, _oDlg ,, CLR_GRAY , .T. )
	TGroup():New( 120 , 002 , 175 , 250 , 'Configuração do Leite: '		, _oDlg ,, CLR_GRAY , .T. )

	TSay():New( 008 , 008 , {|| SC7->C7_NUM																													} , _oDlg ,, _oFont ,,,, .T. ,,, 030 , 10 )
	TSay():New( 008 , 050 , {|| DToC( SC7->C7_EMISSAO )																										} , _oDlg ,, _oFont ,,,, .T. ,,, 050 , 10 )
	TSay():New( 026 , 005 , {|| SC7->C7_FORNECE +'/'+ SC7->C7_LOJA +' - '+ AllTrim(Posicione('SA2',1,xFilial('SA2')+SC7->(C7_FORNECE+C7_LOJA),'A2_NOME') )	} , _oDlg ,, _oFont ,,,, .T. ,,, 200 , 10 )
	TSay():New( 044 , 005 , {|| AllTrim( SC7->C7_PRODUTO ) +' - '+ AllTrim( Posicione('SB1',1,xFilial('SB1')+SC7->C7_PRODUTO,'B1_DESC') )					} , _oDlg ,, _oFont ,,,, .T. ,,, 200 , 10 )

	_nGet3 := SC7->C7_QUANT
    TSay():New( 070 , 005 , {|| GetSX3Cache("C7_QUANT","X3_TITULO")} , _oDlg ,, _oFont ,,,, .T. ,,, 200 , 10 )
	_oGet1 := TGet():New( 068 , 040 , {|u| If( PCount() > 0 , _nGet3 := u , _nGet3 ) } , _oDlg , 070 , 010 , GetSX3Cache("C7_QUANT","X3_PICTURE") ,, 0 , 16777215 ,, .F. ,, .T. ,, .F. ,, .F. , .F. ,, .F. , .F. ,, "_nGet3" ,,,, .T. )

	_nGet4 := SC7->C7_PRECO
	TSay():New( 085 , 005 , {|| GetSX3Cache("C7_PRECO","X3_TITULO") } , _oDlg ,, _oFont ,,,, .T. ,,, 200 , 10 )
	_oGet1 := TGet():New( 083 , 040 , {|u| If( PCount() > 0 , _nGet4 := u , _nGet4 ) } , _oDlg , 070 , 010 , GetSX3Cache("C7_PRECO","X3_PICTURE") ,, 0 , 16777215 ,, .F. ,, .T. ,, .F. ,, .F. , .F. ,, .F. , .F. ,, "_nGet4" ,,,, .T. )

    _nGet5 := SC7->C7_PICM
    TSay():New( 100 , 005 , {|| GetSX3Cache("C7_PICM","X3_TITULO") } , _oDlg ,, _oFont ,,,, .T. ,,, 200 , 10 )
	_oGet1 := TGet():New( 097 , 040 , {|u| If( PCount() > 0 , _nGet5 := u , _nGet5 ) } , _oDlg , 070 , 010 , GetSX3Cache("C7_PICM","X3_PICTURE") ,, 0 , 16777215 ,, .F. ,, .T. ,, .F. ,, .F. , .F. ,, .F. , .F. ,, "_nGet5" ,,,, .T. )

	_nGet1 := SC7->C7_L_PMGB
	TSay():New( 130 , 005 , {|| GetSX3Cache("C7_L_PMGB","X3_TITULO") } , _oDlg ,, _oFont ,,,, .T. ,,, 200 , 10 )
	_oGet1 := TGet():New( 128 , 040 , {|u| If( PCount() > 0 , _nGet1 := u , _nGet1 ) } , _oDlg , 050 , 010 , GetSX3Cache("C7_L_PMGB","X3_PICTURE") ,, 0 , 16777215 ,, .F. ,, .T. ,, .F. ,, .F. , .F. ,, .F. , .F. ,, "_nGet1" ,,,, .T. )

	_nGet8 := SC7->C7_L_PMGB2
	TSay():New( 130 , 120 , {|| GetSX3Cache("C7_L_PMGB2","X3_TITULO") } , _oDlg ,, _oFont ,,,, .T. ,,, 200 , 10 )
	_oGet1 := TGet():New( 128 , 160 , {|u| If( PCount() > 0 , _nGet8 := u , _nGet8 ) } , _oDlg , 050 , 010 , GetSX3Cache("C7_L_PMGB2","X3_PICTURE") ,, 0 , 16777215 ,, .F. ,, .T. ,, .F. ,, .F. , .F. ,, .F. , .F. ,, "_nGet8" ,,,, .T. )

	_nGet2 := SC7->C7_L_EXEMG
	TSay():New( 145 , 005 , {|| GetSX3Cache("C7_L_EXEMG","X3_TITULO") } , _oDlg ,, _oFont ,,,, .T. ,,, 200 , 10 )
	_oGet2 := TGet():New( 143 , 040 , {|u| If( PCount() > 0 , _nGet2 := u , _nGet2 ) } , _oDlg , 050 , 010 , GetSX3Cache("C7_L_EXEMG","X3_PICTURE") ,, 0 , 16777215 ,, .F. ,, .T. ,, .F. ,, .F. , .F. ,, .F. , .F. ,, "_nGet2" ,,,, .T. )
	
	_nGet9 := SC7->C7_L_EXEM2
	TSay():New( 145 , 120 , {|| GetSX3Cache("C7_L_EXEM2","X3_TITULO") } , _oDlg ,, _oFont ,,,, .T. ,,, 200 , 10 )
	_oGet2 := TGet():New( 143 , 160 , {|u| If( PCount() > 0 , _nGet9 := u , _nGet9 ) } , _oDlg , 050 , 010 , GetSX3Cache("C7_L_EXEM2","X3_PICTURE") ,, 0 , 16777215 ,, .F. ,, .T. ,, .F. ,, .F. , .F. ,, .F. , .F. ,, "_nGet9" ,,,, .T. )

	_nGet6 := SC7->C7_L_PMEST
	TSay():New( 160 , 005 , {|| GetSX3Cache("C7_L_PMEST","X3_TITULO") } , _oDlg ,, _oFont ,,,, .T. ,,, 200 , 10 )
	_oGet1 := TGet():New( 158 , 040 , {|u| If( PCount() > 0 , _nGet6 := u , _nGet6 ) } , _oDlg , 050 , 010 , GetSX3Cache("C7_L_PMEST","X3_PICTURE") ,, 0 , 16777215 ,, .F. ,, .T. ,, .F. ,, .F. , .F. ,, .F. , .F. ,, "_nGet6" ,,,, .T. )

	_nGet7 := SC7->C7_L_EXEST
	TSay():New( 160 , 120 , {|| GetSX3Cache("C7_L_EXEST","X3_TITULO") } , _oDlg ,, _oFont ,,,, .T. ,,, 200 , 10 )
	_oGet2 := TGet():New( 158 , 160 , {|u| If( PCount() > 0 , _nGet7 := u , _nGet7 ) } , _oDlg , 050 , 010 , GetSX3Cache("C7_L_EXEST","X3_PICTURE") ,, 0 , 16777215 ,, .F. ,, .T. ,, .F. ,, .F. , .F. ,, .F. , .F. ,, "_nGet7" ,,,, .T. )
	
	@180,149 BUTTON _oBtn1 PROMPT "Confirmar"	ACTION ( _nOpc := 1 , _oDlg:End() )	SIZE 050,012 OF _oDlg PIXEL
	@180,200 BUTTON _oBtn2 PROMPT "Cancelar"	ACTION ( _nOpc := 2 , _oDlg:End() )	SIZE 050,012 OF _oDlg PIXEL

ACTIVATE DIALOG _oDlg CENTERED

If _nOpc == 1

	If SC7->C7_QUANT <> _nGet3

		If SC7->C7_QUJE > _nGet3
			MsgInfo("Não é possível definir uma quantidade menor que a já recebida em notas para o pedido selecionado! Qtd. recebida: "+ AllTrim( Transform( SC7->C7_QUJE , '@E 999,999,999,999.99' ) )+;
					"Verifique os dados e tente novamente, a quantidade informada não será gravada.","AGLT01904")
			_nGet3 := SC7->C7_QUANT
		EndIf

	EndIf

	U_IGravSCY(SC7->C7_FILIAL, SC7->C7_NUM)

	RecLock( 'SC7' , .F. )

	    SC7->C7_L_PMGB	:= _nGet1
		SC7->C7_L_PMGB2	:= _nGet8
	    SC7->C7_L_EXEMG	:= _nGet2
		SC7->C7_L_EXEM2	:= _nGet9
		SC7->C7_L_PMEST	:= _nGet6
	    SC7->C7_L_EXEST	:= _nGet7
	    SC7->C7_PICM	:= _nGet5
	    SC7->C7_QUANT	:= _nGet3
		SC7->C7_PRECO	:= _nGet4
		SC7->C7_TOTAL	:= Round( SC7->C7_QUANT * SC7->C7_PRECO , 2 )
		SC7->C7_BASEIPI	:= SC7->C7_TOTAL

		If _nGet5 > 0
			SC7->C7_PICM	:= _nGet5
			SC7->C7_BASEICM	:= SC7->C7_TOTAL
			SC7->C7_VALICM	:= Round( SC7->C7_TOTAL * ( SC7->C7_PICM / 100 ) , 2 )
		Else
			SC7->C7_PICM	:= 0
			SC7->C7_BASEICM	:= 0
			SC7->C7_VALICM	:= 0
		EndIf

		DBSelectArea('SBZ')
		SBZ->( DBSetOrder(1) )
		If SBZ->( DBSeek( SC7->( C7_FILIAL + C7_PRODUTO ) ) )

			If SBZ->BZ_PCOFINS > 0
				SC7->C7_BASIMP5	:= SC7->C7_TOTAL
				SC7->C7_VALIMP5	:= Round( SC7->C7_BASIMP5 * ( SBZ->BZ_PCOFINS	/ 100 ) , 2 )
			EndIf

			If SBZ->BZ_PPIS > 0
				SC7->C7_BASIMP6	:= SC7->C7_TOTAL
				SC7->C7_VALIMP6	:= Round( SC7->C7_BASIMP6 * ( SBZ->BZ_PPIS		/ 100 ) , 2 )
			EndIf

		EndIf

    SC7->(DbCommit())
    SC7->( MSUnLock() )

EndIf

Return

/*
===============================================================================================================================
Programa--------: AGLT0192
Autor-----------: Alex Wallauer
Data da Criacao-: 21/02/2022
Descrição-------: Rotina de agendamento de entrega do leite de terceiros: criar rotina auxiliarão pedido de compra olhando para os campos data de entrega e emissão
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AGLT0192(_lBrowse)
Local _cC7_I_MEAGE:= "" , D
Local nPosPrf  
Local nPosQt   
Local nPosMELT 
DEFAULT _lBrowse := .T.

Private _aLinhas  := {}
Private _cPict    := "@E 999,999,999.99"

If _lBrowse

   ZA7->( DBSetOrder(2) )
   If !ZA7->( DBSeek( xFilial('ZA7') + SC7->C7_PRODUTO ) )
       U_ITMsg("O produto do pedido selecionado não está relacionado à recepção do leite de terceiros! Verifique o pedido selecionado.",'Atenção!',,3)
   	   Return .F.
   EndIf

   cA120Num      := SC7->C7_NUM
   M->C7_EMISSAO := SC7->C7_EMISSAO
   M->C7_DATPRF  := SC7->C7_DATPRF 
   M->C7_QUANT   := SC7->C7_QUANT  
   M->C7_I_MEAGE := SC7->C7_I_MEAGE

   If Empty(M->C7_DATPRF) .Or. Empty(M->C7_EMISSAO)
      U_ITMsg("Data de emissão ou data de entrega do item não preenchida",'Atenção!',"Preencha as 2 datas pra acessar essa opção",3) // ALERT
      Return .F.
   EndIf

Else

   nPosProd    := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_PRODUTO"})
   
   ZA7->( DBSetOrder(2) )
   If !ZA7->( DBSeek( xFilial('ZA7') + aCols[n][nPosProd ]  ) )
   	  U_ITMsg("O produto do pedido selecionado não está relacionado à recepção do leite de terceiros! Verifique o pedido selecionado.",'Atenção!',,3)
   	  Return .F.
   EndIf

   nPosPrf     := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_DATPRF"})
   nPosQt      := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_QUANT"})
   nPosMELT    := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_I_MEAGE"})

   M->C7_EMISSAO     := dA120Emis
   If N > 0
      M->C7_DATPRF   := aCols[n][nPosPrf ] 
      M->C7_QUANT    := aCols[n][nPosQt  ] 
      M->C7_I_MEAGE  := aCols[n][nPosMELT] 
   EndIf   

   If n = 0 .Or. Empty(M->C7_DATPRF) .Or. Empty(M->C7_EMISSAO)
      U_ITMsg("Data de emissão ou data de entrega do item não preenchida",'Atenção!',"Preencha as 2 datas pra acessar essa opção",3) // ALERT
      Return .F.
   EndIf

EndIf
_lCria:=.F.
_lRecalcula:=.F.
nDias:=(M->C7_DATPRF - M->C7_EMISSAO)+1

If Empty(M->C7_I_MEAGE)
   _lCria:=.T.
Else
   _cC7_I_MEAGE:=StrTran(AllTrim(M->C7_I_MEAGE),CHR(13)+CHR(10),"")
   _aLinAux:=StrToArray(_cC7_I_MEAGE,";")

  If DToC(M->C7_EMISSAO) <> _aLinAux[1]  .OR.;
     (Len(_aLinAux) <= 2 .And.  M->C7_DATPRF > M->C7_EMISSAO)  .OR.;
     (Len(_aLinAux) >  2 .And.  DToC(M->C7_DATPRF) <> _aLinAux[Len(_aLinAux)-1])

      If nDias < (Len(_aLinAux)/2) .And. U_ITMsg("Data de entrega do item foi alterada",'Atenção!',"Deseja recalcular as datas para menos?",2,2,3,,"RECALCULAR","CONTINUAR") 
         _lRecalcula:=.T.
	  EndIf
   EndIf
EndIf

If _lCria
   nSoma:=0
   For D := 1 TO nDias
       _cC7_I_MEAGE +=DToC(M->C7_EMISSAO+nSoma)+";0,00;"+CHR(13)+CHR(10)//+  Str(M->C7_QUANT/nDias,15,8)+";"
       aAdd(_aLinhas,{DToC(M->C7_EMISSAO+nSoma)," 0,00"})//TRANSFORM(M->C7_QUANT/nDias,_cPict) })
	   nSoma++
   Next
Else

   If _lRecalcula
      nTotDias:=(nDias*2)//*2 PQ cada dia tem 2 linhas no _aLinAux
   Else
      nTotDias:=Len(_aLinAux)
   EndIf
   For D := 1 TO nTotDias
       aAdd(_aLinhas,{_aLinAux[D] , _aLinAux[D+1] })
	   D++
   Next
   nTotDias:=(Len(_aLinAux)/2)// dividido por 2 PQ cada dia tem 2 linhas no _aLinAux
   If nDias >  nTotDias
      nSoma:= (nTotDias+1)
      For D:= (nTotDias+1) TO nDias
          _cC7_I_MEAGE +=DToC(M->C7_EMISSAO+nSoma)+";0,00;"+CHR(13)+CHR(10)//+  Str(M->C7_QUANT/nDias,15,8)+";"
          aAdd(_aLinhas,{DToC(M->C7_EMISSAO+nSoma)," 0,00"})//TRANSFORM(M->C7_QUANT/nDias,_cPict) })
	      nSoma++
      Next   
   EndIf
EndIf

_cTitAux :="Programação de Entrega do Pedido: "+cA120Num
_cMsgTop :="Data de "+DToC(M->C7_EMISSAO)+" ate "+DToC(M->C7_DATPRF)+" / "+AllTrim(Str(nDias)) + " dia(s) / Quantidade do Produto: "+TRANSFORM(M->C7_QUANT,_cPict)
bDblClk  :={|| AGLT0192(@oLbxAux)}
_aCab    :={"Data","Rateio da Quantidade"}
_nPosColRepo:=2

//      ITListBox(_cTitAux, _aHeader , _aCols    , _lMaxSiz ,  nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca,_bLegenda)
lRet:=U_ITLISTBOX(_cTitAux, _aCab    , _aLinhas  , .F.      , 1      , _cMsgTop ,          ,         ,         ,     ,        ,          ,       ,bDblClk ,          ,           ,         )

If lRet
   _cC7_I_MEAGE:=""
   For D := 1 TO Len(_aLinhas)
       _cC7_I_MEAGE+=_aLinhas[D,1]+";"+_aLinhas[D,2]+";"+CHR(13)+CHR(10)
   Next
   _cC7_I_MEAGE:=LEFT(_cC7_I_MEAGE,Len(_cC7_I_MEAGE)-2)
EndIf

If _lBrowse
   SC7->(RecLock( 'SC7' , .F. ))
   SC7->C7_I_MEAGE	:= _cC7_I_MEAGE
   SC7->(DBCOMMIT())
   SC7->(MSUnLock())
Else
   aCols[n][nPosMELT] := _cC7_I_MEAGE
EndIf


Return .T.

/*
===============================================================================================================================
Programa----------: AGLT0192
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2019
Descrição---------: Rotina de duplo clique na linha do browse
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT0192(oLbxAux)

Local _nLinPos  := oLbxAux:nAt
Local _bOK, D

If oLbxAux:nColPos == _nPosColRepo	
   _bOK:={|| If(_nQtde >= 0 .And. _nQtde <= M->C7_QUANT,.T.,(U_ITMsg("Quantidade INVALIDA",'Atenção!',"Digite um valor maior que zero e menor qde que o item posicionado: "+TRANSFORM(M->C7_QUANT,_cPict),3),.F.) ) }
   _nQtde :=StrTran(_aLinhas[_nLinPos,_nPosColRepo],".","") //Tira o ponto dos milhar
   _nQtde :=Val(StrTran(_nQtde,",",".") )//Tira a virgula e poe o ponto para o Val() não comer a decimal
   lOK:=.F.

   While .T.
      _nLin:=11
	  @ 00,00 To 150,280 Dialog oDlgDes Title "Quantidade de Leite"
	  
	  @ _nLin  ,10 Say   "Qtde Produto:" Pixel of oDlgDes
	  @ _nLin-1,50 MSGET M->C7_QUANT Picture _cPict  Pixel Of oDlgDes WHEN .F.
	   _nLin+=20
	  @ _nLin  ,10 Say   "Quantidade:" Pixel of oDlgDes
	  @ _nLin-1,50 MSGET _nQtde Picture _cPict  Pixel Of oDlgDes
	   _nLin+=20
	  @ _nLin,50 BMPBUTTON Type 1 ACTION (If(EVAL(_bOK),(lOK:=.T.,Close(oDlgDes)),))
	  @ _nLin,82 BMPBUTTON Type 2 ACTION Close(oDlgDes)
	  Activate Dialog oDlgDes Center
  
      If lOK
	     _cQtdeSalva:=oLbxAux:aArray[ _nLinPos , _nPosColRepo ]
         oLbxAux:aArray[ _nLinPos , _nPosColRepo ] := TRANSFORM(_nQtde,_cPict)
         _nQtdeSoma:=0
         For D := 1 TO Len(oLbxAux:aArray)
             _nQtdeAux :=StrTran(oLbxAux:aArray[D,_nPosColRepo],".","") //Tira o ponto dos milhar
             _nQtdeAux :=Val(StrTran(_nQtdeAux,",",".") )//Tira a virgula e poe o ponto para o Val() não comer a decimal
		     _nQtdeSoma+=_nQtdeAux
         Next
		 If _nQtdeSoma > M->C7_QUANT
            U_ITMsg("Somatoria das quantidades mais a digitada é maior que a quantidade do item posicionado: "+TRANSFORM(_nQtdeSomaT,_cPict),'Atenção!',"Digitar quantidade para somatoria menor ou igual a "+TRANSFORM(M->C7_QUANT,_cPict),3) // ALERT
            oLbxAux:aArray[ _nLinPos , _nPosColRepo ] := _cQtdeSalva//VOLTA O ANTERIOR
		    Loop
		 EndIf
         //_aLinhas[_nLinPos,_nPosColRepo]:=TRANSFORM(_nQtde,_cPict)  
      EndIf
      Exit
   EndDo
EndIf

//oLbxAux:Setarray(_aLinhas)
oLbxAux:Refresh()
ProcessMessages()

Return
