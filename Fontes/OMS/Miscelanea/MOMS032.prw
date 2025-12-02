#Include	"Protheus.Ch"
#Include 	"TopConn.ch"

/*
===============================================================================================================================
Programa----------: MOMS032
Autor-------------: Alex Wallauer
Data da Criacao---: 23/09/2016
===============================================================================================================================
Descrição---------: Schedule para verificar bloqueio de credito dos Pedidos de Venda - Chamado 17025
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function MOMS032()//U_MOMS032

Local aTables    := {"SC5","SC6","SC9","SA1","SF4","ZAY"}    
Private _lShedule:= .F. 
                        
If Select("SX3") <= 0
	_lShedule:= .T.
EndIf   
            
If _lShedule

	 //Mensagem que ficara armazenada no arquivo totvsconsole.log para posterior monitoramento 
    u_itconout("[MOMS032] - Inicio da Analise do Bloqueio de Credito dos Pedidos de Vendas data: " + DToC(DATE()) + ' - ' + Time())

	//Nao consome licensas
	RPCSetType(3)
	
	//seta o ambiente com a empresa 01 filial 01   	 
	RpcSetEnv("01","01",,,,/*"XML_WALlMART"*/,aTables)     
    cUserName:="Schedule [MOMS032]"
    MOMS032E(.T.)

Else

   cCadastro:="Analise Bloqueio de Credito dos Pedidos de Vendas"

   aRotina := {{ OemToAnsi("Pesquisar")     ,"AxPesqui"	      ,0,1,0,.F.},;
			   { OemToAnsi("Visualizar")    ,'AxVisual'       ,0,2,0,NIL},;
			   { OemToAnsi("Analisar Atual"),'U_MOMS032E(.F.)',0,2,0,NIL},;
			   { OemToAnsi("Analisar Todos"),'U_MOMS032E(.T.)',0,2,0,NIL}}

   _aCorLegen:={}
   aAdd(_aCorLegen,{  "C5_I_BLCRE <> 'B' .And. C5_LIBEROK <> 'S' .And. C5_NOTA = ' ' .And.  (C5_I_PEDPA <> 'S' .Or. C5_I_PEDGE = 'S') .And. C5_TIPO = 'N'" ,'ENABLE'  })			
   aAdd(_aCorLegen,{"!(C5_I_BLCRE <> 'B' .And. C5_LIBEROK <> 'S' .And. C5_NOTA = ' ' .And.  (C5_I_PEDPA <> 'S' .Or. C5_I_PEDGE = 'S') .And. C5_TIPO = 'N')",'DISABLE'})

   mBrowse(,,,,"SC5",,,,,,_aCorLegen)//Menu do OMS

EndIf

Return .F.

/*
===============================================================================================================================
Programa----------: MOMS032E
Autor-------------: Alex Wallauer
Data da Criacao---: 23/09/2016
===============================================================================================================================
Descrição---------: Rotina para analisar o credito dos pedido de venda
===============================================================================================================================
Parametros--------: lTodos: .T. analisa todos senao só o atual
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS032E(lTodos)
Local oproc


FWMsgRun(,{|oproc| MOMS032E(lTodos,oproc) },"Aguarde...","Analisando Pedidos...")

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS032E
Autor-------------: Alex Wallauer
Data da Criacao---: 23/09/2016
===============================================================================================================================
Descrição---------: Processamento principal do schedule
===============================================================================================================================
Parametros--------: lTodos: .T. analisa todos senao só o atual
					oproc - objeto da barra de processamento
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function MOMS032E(lTodos,oproc)

Local cAlias  :=GetNextAlias()  
Local lEfetiva:=.T.
Local _cCarga :=""
Local _lGrvLog:=.F.
Local _nConta :=0
Local cQuery  :="SELECT SC5.R_E_C_N_O_ REC_SC5 "
Local _nLog		:= 0

Default oproc := nil

Private ntot := 0

_cTimeInicial :=Time()
If !_lShedule 
   oproc:cCaption := ("Etapa 1 de 3 - Filtrando pedidos...")
   ProcessMessages()
EndIf

cQuery += " FROM " + RETSQLNAME("SC5") +  " SC5 "
cQuery += " WHERE D_E_L_E_T_ = ' ' AND C5_NOTA = ' ' AND  (C5_I_PEDPA <> 'S' OR C5_I_PEDGE = 'S') "
cQuery += " AND C5_TIPO = 'N' "

If !lTodos

   cQuery += " AND C5_FILIAL = '"+SC5->C5_FILIAL+"' AND C5_NUM = '"+SC5->C5_NUM+"' "

EndIf

cQuery += " ORDER BY C5_FILIAL,C5_NUM


cQuery := ChangeQuery(cQuery)

If Select(cAlias) >0

   (cAlias)->( DBCloseArea() )

EndIf

TCQUERY cQuery New Alias (cAlias)

DBSelectArea(cAlias)
count to nTot

(cAlias)->( DBGoTop() )

If !_lShedule 
  
   If nTot = 0

      U_ITMsg("Não existe Pedido(s) com o criterio da selecao! ","Atenção","Refaça a seleção...",1)
      Return .F.

   Else

      If (nRet:=Aviso("Analise de Credito","Quantidade de Pedido(s): "+AllTrim(Str(nTot))+CHR(13)+CHR(10)+"Confirma Analise de Credito?",{'OK/Consulta','OK/Efetiva','Sair'},2 )) = 3
         (cAlias)->(DBCloseArea())
         DBSelectArea("SC5")
         Return .F.
      EndIf

      _cTimeInicial :=Time()

      lEfetiva := (nRet = 2)

   EndIf

EndIf


(cAlias)->(DBGoTop())

Private _cCodChep:= AllTrim(GetMV("IT_CCHEP"))
Private _nTotPed := 0
Private _aLog    :={}

_cTotal:=AllTrim(StrZero(nTot,6))

SC5->( DBSetOrder(1) )
SC9->( DBSetOrder(1) )

While (cAlias)->(!Eof())
	
   SC5->(DBGoTo((cAlias)->REC_SC5))
	
   _nConta++
   If !_lShedule 
      oproc:cCaption := "Lendo Filial/PV: "+SC5->C5_FILIAL+"/"+SC5->C5_NUM+" - "+AllTrim(StrZero(_nConta,6))+"/"+_cTotal
      ProcessMessages()
   EndIf
   
   //Atualiza campo C5_I_DTNEC
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
   	
   	_dtnec := SC5->C5_I_DTENT - (U_OMSVLDENT(SC5->C5_I_DTENT,SC5->C5_CLIENTE,SC5->C5_LOJACLI,SC5->C5_I_FILFT,SC5->C5_NUM,1))
   
   	If _dtnec != SC5->C5_I_DTENT  
   		RecLock("SC5",.F.)
   		SC5->C5_I_DTNEC := _dtnec 
   		SC5->(MSUnLock())
   	EndIf

   If SC5->C5_I_BLCRE = "R"
	  (cAlias)->(DBSkip())
      Loop
   EndIf

   If !MOMS032V( SC5->C5_FILIAL+SC5->C5_NUM ) //Verifica se pedido sofre avaliação de crédito
	   (cAlias)->(DBSkip())
       Loop
   EndIf
	
   _cCarga   :=""
   _lLiberado:=.T.
   _cCliente :=SC5->C5_CLIENTE+" / "+SC5->C5_LOJACLI+" / "+Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NREDUZ") //SC5->C5_CLIENTE+" - "+SC5->C5_LOJACLI+" - "+

   _cCarga:="Não / Não"
   If SC9->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
      _cCarga:="Sim / "+If(SC5->C5_I_ENVRD="S","Sim","Não")
      If !Empty(SC9->C9_CARGA)
         _cCarga+=" / "+SC9->C9_CARGA // se Tem CARGA
      EndIf
   EndIf         

   _aRetCre  := U_ValidaCredito( _nTotPed )//Validação de crédito unificada
   _lLimpaLCC:= .F.//Limpa Liberação Completa de Crédito

   If _aRetCre[1] == "Bloqueado por liberação completa de crédito expirada"
      _aRetCre  := U_ValidaCredito( _nTotPed,,,, {|| .F. } )//Validação de crédito sem olhar liberação completa de crédito expirada
      _lLimpaLCC:= .T.//Limpa Liberação Completa de Crédito
   EndIf

   _cBlqCred:=_aRetCre[1]
   If Len(_aRetCre) > 3
      _cBlqCred:= _aRetCre[4]// Complemento da descricoes da avaliação de credito
   EndIf

   If _aRetCre[2] = "B"//Se bloqueou

      _lGrvLog:=.F.
      If SC5->C5_I_BLCRE != "B" //  manda tudo que bloqueou .And. (_cCarga # "Não / Não" .Or. SC5->C5_I_ENVRD = "S")
         _lGrvLog:=.T.//Gerar WK e-mail
      EndIf

      _lLimpaLCC:=.F.//Não Limpa Liberação Completa de Crédito pq já vai limpar abaixo
      _lLiberado:=.F.

      If lEfetiva
         SC5->(RecLock("SC5",.F.))
         SC5->C5_I_BLCRE := "B"
	     SC5->C5_I_DTAVA := Date()
	     SC5->C5_I_HRAVA := Time()
	     SC5->C5_I_USRAV := cUserName
	     SC5->C5_I_MOTBL := _aRetCre[1]
	     SC5->C5_I_LIBCA := ""
	     SC5->C5_I_LIBCT := ""
	     SC5->C5_I_LIBC  := 0       //LIB COMP
	     SC5->C5_I_LIBL  := CTOD("")//LIB COMP
	     SC5->C5_I_LIBCV := 0       //LIB COMP
	     SC5->C5_I_LIBCD := CTOD("")
	     SC5->C5_I_DTLIC := CTOD("")
	     SC5->(MSUnLock())
      EndIf

      If _lGrvLog .Or. !_lShedule 
   	     aAdd( _aLog ,{_lLiberado,SC5->C5_FILIAL,SC5->C5_NUM+"- "+DToC(SC5->C5_EMISSAO),_cCarga,_cCliente,_cBlqCred,U_STPEDIDO(1),SC5->C5_I_ENVRD} )
   	  EndIf
      
   ElseIf SC5->C5_I_BLCRE != "L"
   
      If lEfetiva
         SC5->(RecLock("SC5",.F.))
	     SC5->C5_I_BLCRE := " "
	     SC5->C5_I_DTAVA := Date()
	     SC5->C5_I_HRAVA := Time()
	     SC5->C5_I_USRAV := cUserName
	     SC5->C5_I_MOTBL := _aRetCre[1]
   	     SC5->(MSUnLock())
      EndIf

      If !_lShedule 
         aAdd( _aLog ,{_lLiberado,SC5->C5_FILIAL,SC5->C5_NUM+"- "+DToC(SC5->C5_EMISSAO),_cCarga,_cCliente,_cBlqCred,U_STPEDIDO(1),SC5->C5_I_ENVRD} )
      EndIf
      
   EndIf

   If _lLimpaLCC .And. lEfetiva//Limpa os campos se passar na liberção sem olhar a Liberação Completa de Crédito expirada
      SC5->(RecLock("SC5",.F.))
      SC5->C5_I_LIBC  := 0       //LIB COMP
	  SC5->C5_I_LIBL  := CTOD("")//LIB COMP
	  SC5->C5_I_LIBCV := 0       //LIB COMP
   	  SC5->(MSUnLock())
   EndIf
   
   U_ENVSITPV() //Envia interface de atualização do status do pedido para o RDC e atualiza campo C5_I_STATU

   (cAlias)->(DBSkip())
	
EndDo
		
(cAlias)->(DBCloseArea())
DBSelectArea("SC5")

If _lShedule

   If Len(_aLog) > 0 .And. lEfetiva
      _aFilLog:={}
      For _nLog := 1 TO Len(_aLog)
          If aScan(_aFilLog,_aLog[_nLog,2])=0
             aAdd(_aFilLog,_aLog[_nLog,2])
          EndIf
      Next
    
      //Grava filial original
      _cfilial := cfilant
    
      For _nLog := 1 TO Len(_aFilLog)//Tem que fazer um array de filial 
          cFilAnt  :=_aFilLog[_nLog]
          MOM032EML("Filial lida: "+cFilAnt+" - "+AllTrim( Posicione('SM0',1,cEmpAnt+cFilAnt,'M0_FILIAL') )+CHR(13)+CHR(10)+;
                     'Hora Inicial: '+_cTimeInicial+CHR(13)+CHR(10)+;
                     'Hora Final: '+TIME()+CHR(13)+CHR(10),_aLog, .F. , .T. )
      Next
      
      //Retorna filial original
      cfilant := _cfilial
      _cfilial := Posicione('SM0',1,cEmpAnt+cFilAnt,'M0_FILIAL')
   
   EndIf
   
   u_itconout("[MOMS032] - Termino da Analise de Bloqueio de Credito dos Pedidos de Vendas data: " + DToC(DATE()) + ' - ' + Time())

   RpcClearEnv() //Limpa o ambiente, liberando a licença e fechando as conexões

Else
    
    If Len(_aLog) > 0
       _aButtons:={}
       aAdd( _aButtons , { "Envia Email"	, {|| MOM032EML("",_aLog,.T.,.F.)  }, "Envia Email do Log","Envia Email"} )

       _cSubTit:="Quantidade de Pedidos Analisados: "+AllTrim(Str(Len(_aLog)))+" - "+;
                 'Hora Inicial: '+_cTimeInicial+' / Hora Final: '+Time()

	   U_ITListBox( 'Log de Analise de Credito de Pedidos de Venda' ,;
	              {" ","Filial","Pedido","Liberado / RDC / Carga","Cliente","Resultado da Analise","Status do pedido"},_aLog,.T.,4,_cSubTit,,;
	              { 10,      30,      35,                      80,      200,                 200,500},,,, _aButtons )

    Else

       U_ITMsg("Nenhuma Pedidos de Venda alterado.","Atenção",1)

    EndIf

EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS032V
Autor-------------: Alex Wallauer
Data da Criacao---: 23/09/2016
===============================================================================================================================
Descrição---------: Verifica se pedido de vendas passa por validação de crédito
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS032V(cChave)

Local _lValCredito:=.T.

_nTotPed := 0

SC6->( DBSetOrder(1) )

If SC6->(DBSeek( cChave  ))
   
   While SC6->(!Eof()) .And. cChave == SC6->C6_FILIAL+SC6->C6_NUM
	
	  //Caso encontre uma das duas CFOP citadas abaixo o pedido |
	  //de venda corrente sera considerado do tipo bonificacao. |
	  If AllTrim(SC6->C6_PRODUTO) == _cCodChep .Or. AllTrim(SC6->C6_CF) $ '5910/6910/5911/6911'
         _lValCredito:=.F.
         Exit
	  EndIf

      If Posicione("SF4",1,xFilial("SF4")+SC6->C6_TES,"F4_DUPLIC") != 'S' //NÃO VALIDA CRÉDITO PARA PEDIDO SEM DUPLICATA
         _lValCredito:=.F.
         Exit
      EndIf
    
      If Posicione("ZAY",1,xFilial("ZAY")+ SC6->C6_CF,"ZAY_TPOPER") != 'V' //NÃO VALIDA CRÉDITO PARA PEDIDO COM CFOP QUE NÃO SEJA DE VENDA
         _lValCredito:=.F.
         Exit
      EndIf
   
	  //Efetua o somatorio dos itens do pedido 
	  _nTotPed += SC6->C6_VALOR

      SC6->(DBSkip())

   EndDo
	
Else

   _lValCredito:=.F.

EndIf

Return( _lValCredito )


/*
===============================================================================================================================
Programa----------: MOM032EML
Autor-------------: Alex Wallauer
Data da Criacao---: 17/04/2017
===============================================================================================================================
Descrição---------: Rotina para enviar e-mail de notificação quando houver uma falha de integração
===============================================================================================================================
Parametros--------: _cObs: Observacoes
                    _aLog: Lista de logs
                    _lProcessa: .T. com Tela
===============================================================================================================================
*/
Static Function MOM032EML( _cObs,_aLog,_lProcessa,_lFiltra )

Local _aConfig	:= U_ITCFGEML('')
Local _cMsgEml	:= ''
Local _cEmail	:= SuperGetMV('IT_VALCRED',.F.,'sistema@italac.com.br' )
Local _cData	:= DToC(DATE())
Local _cHoraT   := _cTimeInicial
Local _cAssunto := 'Workflow - Validação de Credito'
Local _nI		:= 0
DEFAULT _lFiltra:= .F.
DEFAULT _lProcessa:=.F.

If _lProcessa
   ProcRegua(0)
   If Type('__cUserId') == 'C'
      _cEmail := FWSFAllUsers({__cUserID},{'USR_EMAIL'})[1][3]
   EndIf   
   If Empty(_cEmail)
	   Aviso("Sem e-mail cadastrado","Usuário sem e-mail no cadastro",{"OK"} , 1 )
      Return .F.
   EndIf
Else
   If Empty(_cEmail)
	  u_itconout('[MOMS032] - Sem e-mail cadastrado, verifique o parametro "IT_VALCRED" com a area de TI')
      Return .F.
   EndIf
  _cAssunto += " - Processamento agendado (Schedule) - Filial : "+cFilAnt+" - "+AllTrim( Posicione('SM0',1,cEmpAnt+cFilAnt,'M0_FILIAL') )
EndIf

_cMsgEml := '<html>'
_cMsgEml += '<head><title>Validação de Credito</title></head>'
_cMsgEml += '<body>'
_cMsgEml += '<style Type="text/css"><!--'
_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
_cMsgEml += 'td.aceito	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #00CC00; }'
_cMsgEml += 'td.recusa  { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FF0000; }'
_cMsgEml += '--></style>'
_cMsgEml += '<center>'
_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="700" height="50"><br>'
_cMsgEml += '<table class="bordasimples" width="700">'
_cMsgEml += '    <tr>'
_cMsgEml += '	<td class="titulos"><center>Log de Processamento</center></td>'
_cMsgEml += '	</tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="700">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="2" class="grupos">Analise de Credito de Pedidos de Venda</b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Data:</b></td>'
_cMsgEml += '      <td class="itens" align="left" >'+ _cData +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Hora:</b></td>'
_cMsgEml += '      <td class="itens" align="left" >'+ _cHoraT +'</td>'
_cMsgEml += '    </tr>'

   _cObs+="#OBS#"
   _cMsgEml += '    <tr>'
   _cMsgEml += '      <td class="itens" align="center" width="20%"><b>Observação:</b></td>'
   _cMsgEml += '      <td class="itens" align="left" >'+ AllTrim( _cObs ) +'</td>'
   _cMsgEml += '    </tr>'

_cMsgEml += '	<tr>'
_cMsgEml += '      <td class="titulos" align="center" colspan="2"><font color="red">Esta é uma mensagem automática. Por favor não responder!</font></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</table>'

If _aLog # NIL .And. !Empty(_aLog)  .And. Len( _aLog ) > 0
	
	_cMsgEml += '<br>'
	_cMsgEml += '<table class="bordasimples" width="1200">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td align="center" colspan="5" class="grupos">PEDIDOS DE VENDA</b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" width="1%"><b>  </b></td>'
	_cMsgEml += '      <td class="itens" align="center" width="17%"><b>Filial-Pedido-Emissão</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="12%"><b>Liberado/RDC/Carga</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="28%"><b>Codigo / Loja / Cliente</b></td>'
	_cMsgEml += '      <td class="itens" align="left" width="44%"><b>Resultado da Analise</b></td>'
	_cMsgEml += '    </tr>'

	
	If _lProcessa
		ProcRegua(Len( _aLog ))
	EndIf

	_nBloquedos:=0
    _nLiberados:=0
    _nConta    :=0

	For _nI := 1 To Len( _aLog )

	    If _lProcessa
		   IncProc()
	    EndIf

	    If _lFiltra .And. _aLog[_nI][02] # cFilAnt
		   Loop
	    EndIf

		_cMsgEml += '    <tr>'
		If !_aLog[_nI][1] //= "X"
			_cMsgEml += '      <td class="recusa" align="center" width="1%"><b>B</b></td>'
		Else
			_cMsgEml += '      <td class="aceito" align="center" width="1%"><b>L</b></td>'
		EndIf

		_cMsgEml += '      <td class="itens" align="center" width="17%">'+ _aLog[_nI][02]+" -"+_aLog[_nI][03]+'</td>'
		_cMsgEml += '      <td class="itens" align="left" width="12%">'  + _aLog[_nI][04]+'</td>'
		_cMsgEml += '      <td class="itens" align="left" width="28%">'  + _aLog[_nI][05]+'</td>'
		_cMsgEml += '      <td class="itens" align="left" width="44%">'  + _aLog[_nI][06]+'</td>'
		_cMsgEml += '    </tr>'
        
		If !_aLog[_nI][01]
		   _nBloquedos++
		Else
           _nLiberados++
        EndIf
        _nConta++
		
	Next _nI
	
	_cMsgEml += '</table>'
	
EndIf
_cObsT:=""
If _nLiberados # 0
   _cObsT:=AllTrim(Str(_nLiberados,10))+' Pedidos Liberados "L" (verde) '+CHR(13)+CHR(10)
EndIf
If _nBloquedos # 0
   _cObsT+=AllTrim(Str(_nBloquedos,10))+' Pedidos Bloqueados "B" (vermelho) '+CHR(13)+CHR(10)
EndIf
_cMsgEml:=StrTran(_cMsgEml,"#OBS#",_cObsT)  

_cMsgEml += '</center>'

   _cMsgEml += '    <tr>'
   _cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
   _cMsgEml += '      <td class="itens" align="left" > ['+ GetEnvServer() +'] </td>'
   _cMsgEml += '    </tr>'

_cMsgEml += '</body>'
_cMsgEml += '</html>'

_cEmlLog := ''
//    ITEnvMail(cFrom     ,cEmailTo ,cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer      ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
U_ITENVMAIL( _aConfig[01] , _cEmail ,        ,         ,_cAssunto, _cMsgEml ,         ,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

If !Empty( _cEmlLog )

   If _lProcessa
      MessageBox( _cEmlLog+CHR(13)+CHR(10)+" E-mails: "+_cEmail , 'Envio do WF por e-mail' , 64 )
   Else
      u_itconout("[MOMS032] - "+_cEmlLog+CHR(13)+CHR(10)+" E-mails: "+_cEmail)
   EndIf

Else

   If _lProcessa
      U_ITMsg("Enviado E-mails: "+_cEmail+", "+AllTrim(Str(_nConta,10))+" Pedidos Processados ]", "Analise de Credito dos Pedidos de Vendas  - "+Time() ,,1 )
   Else
      u_itconout("[MOMS032] - Analise de Credito dos Pedidos de Vendas  - "+TIME()+" - [ Enviando E-mail para Filial: "+cFilAnt+", "+AllTrim(Str(_nConta,10))+" Pedidos Processados ]")
   EndIf

EndIf

Return .T.
