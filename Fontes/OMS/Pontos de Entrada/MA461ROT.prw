/*
===============================================================================================================================
                          ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 30/03/2017 | Chamado 18604/19299 - Previnir erros  na geração de Nota por Carga.                              
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 02/08/2017 | Chamado 20971 - Revisão para Versão 12.       
-------------------------------------------------------------------------------------------------------------------------------
 Igor Melgaço     | 22/08/2024 | Chamado 46984 - Implementação de rotina para marcação de todos os registros do browse      
===============================================================================================================================
*/
//=========================================================================================================================================
// Definicoes de Includes da Rotina.
//=========================================================================================================================================
/*
============================================================================================================================================
Programa----------: MA461ROT
Autor-------------: Alex Wallauer
Data da Criacao---: 30/03/2017
============================================================================================================================================
Descrição---------: Ponto de Entrada antes dos mBrowse's de geração dos documentos de entrada para os pedidos no programa MATA461.PRX
============================================================================================================================================
Parametros--------: Nenhum
============================================================================================================================================
Observação--------: Esse PE deve retornar um aRotina custumizado para ser adicionado no aRotina padrão caso For preciso senão retornar 
                    qq coisa diferente de array
============================================================================================================================================
*/
User Function MA461ROT()

Local _nPos:=aScan(aRotina, {|R| Upper(R[2]) == Upper("Ma460Nota") } )

If _nPos # 0

   aRotina[_nPos][2] := "U_I_Ma460Nota"

EndIf

aAdd( aRotina,{'Marcar Todos'		      , 'U_MA461M(.T.)', 0 , 2 , 0 , NIL } )
aAdd( aRotina,{'Desmarcar Todos'		   , 'U_MA461M(.F.)', 0 , 2 , 0 , NIL } )
aAdd( aRotina,{'Solic.Ret.Pedido <== TMS RDC/Multi', 'U_MA461RP()', 0 , 2 , 0 , NIL } )

Return ""

********************************************************
User Function I_Ma460Nota(cAlias, nRecno, nOpcx)
********************************************************
If ThisInv()

   U_ITMsg( 'Não é permitido selecionar todos os pedidos ou trazer pedidos selecionados. ','Validação de Processo',;
			   'Utilize a seleção manual de pedidos',1)

    Return .F.
    
EndIf

Ma460Nota(cAlias, nRecno, nOpcx)

Return .T.


/*
===============================================================================================================================
Programa----------: MA461M
Autor-------------: Igor Melgaço
Data da Criacao---: 26/07/2024
===============================================================================================================================
Descrição---------: Marca todos os registros
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: 
===============================================================================================================================
*/
User Function MA461M(_lMark)
Local aArea		:= FWGetArea()         //Salva a area atual
Local oMark		:= GetMarkBrow()     //Objeto do Browser Markbrow()
Local nQtdAtu	:= 0 //Quantidade de Registros Atualizados
Local cOk      := ""

   If _lMark
      If MV_PAR03 = 1 .And. MV_PAR04 = 1 // Considera Parametros abaixo = Sim / Trazer Pedidos Marcados = Sim
         cOk := " "
      Else
         cOk := oMark:cMark
      EndIf
   Else
      If MV_PAR03 = 1 .And. MV_PAR04 = 1 // Considera Parametros abaixo = Sim / Trazer Pedidos Marcados = Sim
         cOk := oMark:cMark
      Else
         cOk := " "
      EndIf
   EndIf

   FWMsgRun( ,{|oProc| nQtdAtu := MA461MARK(oProc,cOk) } , "Processando..." , "Marcação de registros..." )

   FWRestArea(aArea)

   //Somente atualiza o browse se a quantidade de registros atualizados For maiou que 1, ou seja, atualizaou um registro além do corrente
   If nQtdAtu > 1
   	oMark:Refresh()
   	Eval(bFiltraBrw)
   EndIf

Return

/*
===============================================================================================================================
Programa----------: MA461MARK
Autor-------------: Igor Melgaço
Data da Criacao---: 22/08/2024
===============================================================================================================================
Descrição---------: Marcação do registro
===============================================================================================================================
Parametros--------: oProc,cOK,lECCia
===============================================================================================================================
Retorno-----------: nQtdAtu
===============================================================================================================================
*/
Static Function MA461MARK(oProc,cOK)
Local nQtdAtu	:= 0 //Quantidade de Registros Atualizados
Local cIndPed	:= SC9->C9_FILIAL+SC9->C9_PEDIDO  //Chave do pedido
Local cPedido	:= ""                //Chave do pedido presente
Local lSelPedEC := .F. //Seleciona Pedido e-commerce
Local cOrcamto := "" //Numero do Orçamento SL1 Rakuten
Local aAreaSL1 := {} //WorkArea SL1
Local nRecnoSC9 := 0
Local lECCia	:= SuperGetMV("MV_LJECOMO",,.F.)// EC CiaShop

   DBSelectArea("SC9")
   SC9->(DBGoTop())
   Eval(bFiltraBrw)
   While SC9->(!Eof()) .And. SC9->C9_FILIAL == cFilAnt
      nRecnoSC9 := SC9->(Recno())

   	If  A460CKPRES(@cPedido)
   		//Help( " ", 1, "MA461PVPai", , STR0084 + cPedido, 1 )  //"Pedido Presente, favor selecionar o Pedido Pai!"
         oProc:cCaption := ("Pedido  "+SC9->C9_PEDIDO+" Presente, favor selecionar o Pedido Pai!")
         ProcessMessages()
   	ElseIf A460Avalia()
   		//Help( " ", 1, "MA461PVBloq", , STR0085, 1 )   //"Pedido pode estar Bloqueado\Faturado!"
         oProc:cCaption := ("Pedido "+SC9->C9_PEDIDO+" pode estar Bloqueado\Faturado!")
         ProcessMessages()
      Else

         oProc:cCaption := (IIf(Empty(cOK),"Desmarcando","Marcando") + " pedido "+SC9->C9_PEDIDO+" ...")
         ProcessMessages()

   		RecLock("SC9",.F.)
   		SC9->C9_OK := cOK
   		SC9->( MSUnLock() )
   		nQtdAtu++ //Atualiza a quantidade de Registros atualizados

   		If lECCia .And. SC5->(FieldPos("C5_PEDECOM")) > 0 .And. Val(SC5->C5_PEDECOM) > 0 //E-Commerce CiaShop
   			lSelPedEC := .T.
   		ElseIf !Empty(SC5->C5_ORCRES)
   			aAreaSL1 := SL1->(GetArea())
   			cOrcamto := Posicione("SL1",1,xFilial("SL1")+SC5->C5_ORCRES,"L1_ORCRES")
   			lSelPedEC := SL1->(FieldPos("L1_ECFLAG")) > 0 .And. !Empty(cOrcamto) .And. !Empty(SL1->L1_ECFLAG)//E-commerce Rakuten
   			FWRestArea(aAreaSL1)
   		EndIf

   		If lSelPedEC .And. !( Empty(cPedido) ) .And. SC9->( DBSeek(cIndPed) )
   			nQtdAtu-- //subtrai a quantidade atualizada anteriormente, porque o registro vai ser atualizado novamente
   			While !( Eof() ) .And. ((C9_FILIAL+C9_PEDIDO == cPedido) .Or. (C9_FILIAL+C9_PEDIDO == cIndPed))

   				RecLock("SC9",.F.)
   				SC9->C9_OK := cOK
   				SC9->( MSUnLock() )

               nRecnoSC9 := SC9->(Recno())

   				SC9->( DBSkip() )
   				nQtdAtu++
   			End
   		EndIf
   	EndIf
      
      SC9->(DBGoTo(nRecnoSC9))

      SC9->(DBSkip())
   EndDo   	

Return nQtdAtu

/*
===============================================================================================================================
Programa----------: MA461M
Autor-------------: Igor Melgaço
Data da Criacao---: 26/07/2024
===============================================================================================================================
Descrição---------: Marca todos os registros
===============================================================================================================================
Parametros--------: 
===============================================================================================================================
Retorno-----------: 
===============================================================================================================================
*/
User Function MA461RP()

DBSelectArea("SC5")
DBSetOrder(1)
If DBSeek(SC9->C9_FILIAL+SC9->C9_PEDIDO)
   U_AOMS084B()
Else
   U_ITMsg( 'Não encontrado o pedido '+SC9->C9_PEDIDO+' para execução da rotina!','Validação de Processo',;
			   'Comunique o administrador do sistema.',1)
EndIf

Return
