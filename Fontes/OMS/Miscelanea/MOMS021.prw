/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |24/11/2023| Chamado 45665. Criacao de um parametro IT_M021EXC (ZP1) novo, para filtrar codigos dos itens MP.
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
===============================================================================================================================
*/

#Include "AP5mail.ch"
#Include "TBIConn.ch"
#Include "TOTVS.ch"  
#Include "APWEBSRV.CH"  
#Include "TBICONN.CH"   

/*
===============================================================================================================================
Programa----------: MOMS021
Autor-------------: Guilherme Diogo
Data da Criacao---: 21/09/2012
Descrição---------: Programa para gerar e enviar o relatório de Estoque x Pedido em Carteira diário.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS021()

Local aTables    := { "SB1" , "SB2" , "SC5" , "SC6" , "SD1" , "SD2" , "SD3" , "SF4" , "ZB9" }
Local _cTimeINI  := Time()

Private _lCriaAmb   := !(isincallstack("MDIEXECUTE") .Or. isincallstack("SIGAADV"))
Private _lUserLogado:= .F.

//Verifica a necessidade de abrir o ambiente para o processamento.
If _lCriaAmb

	// Prepara e inicializa o ambiente
	RPCSetType(3)
	RpcSetEnv( "01" , "01" ,,,, "SCHEDULE_EMAIL_RESUMO" , aTables )
    sleep( 5000 )
    u_itconout( 'Gerando envio do arquivo HTML de Estoque xPedido em Carteira na data: ' + DToC(DATE()) + ' - ' + Time() )
    u_itconout( 'Executando no ambiente ' + Upper( GetEnvServer() ))
    

    MOMS021P()

Else
    _cFilial := AllTrim( GetMV("IT_FILWEP") )
    _cFilUser:=""
    ZZL->(DBSetOrder(3)) //ZZL_FILIAL + ZZL_CODUSU
    If ZZL->(DBSeek(xFilial("ZZL") + __cUserId))
    	If ZZL->ZZL_ENVEXP == "S"
		   _cFilUser:=AllTrim(ZZL->ZZL_FILWEP)
        Else
		   U_ITMsg("Usuario sem acesso a essa rotina.",'Atenção!',,3) // ALERT
		   Return .F.
    	EndIf
    Else
	   U_ITMsg("Usuario sem acesso a essa rotina",'Atenção!',,3) // ALERT
	   Return .F.
	EndIf
    

    If U_ITMsg("Executar relatório via JOB?","Filiais do IT_FILWEP: "+_cFilial,;
    			"A execução via JOB é mais rápida e não segura a tela do Protheus, clique em não somente se precisar acompanhar a execução em tela",3,2,2)	
    	U_MOMS021Y()				
    Else

	    If U_ITMsg("Executar relatório somente para usuario logado?","Filiais do IT_FILWEP: "+_cFilial,;
	    			"Se SIM sera enviado e-mail somente para voce das seguintes filiais: "+_cFilUser+". Se NÃO para todos usuarios habilitados para esse relatorio.",;
	    			3,2,2)
           _lUserLogado:= .T.
	    EndIf
		FWMsgRun( ,{|oproc|  MOMS021P(oproc) } , "Aguarde!", "Lendo..."  )
		
	EndIf

EndIf

// Encerra o ambiente aberto
If _lCriaAmb
	RpcClearEnv()
	U_ITCONOUT('Termino de execucao normal do envio do WF.')
Else
	U_ITMsg('Termino de execucao normal do envio do WF.',,"Hora Inicial: "+_cTimeINI+" -> Hora Final: "+Time(),2)
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS021P
Autor-------------: Alex Wallauer
Data da Criacao---: 07/02/2018
Descrição---------: Programa para gerar e enviar o relatório de Estoque x Pedido em Carteira diário.
Parametros--------: oproc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS021P(oproc)

Local nI		:= 0
Local _cAlias    := ""
Local _aMail     := {}
Local _aSubGr    := {}
Local _aDados    := {}
Local  _cFilial  := AllTrim( GetMV("IT_FILWEP") )//01/05/10/11/20/23/30/40/90/91

If ValType(oproc) = "O"
   oproc:cCaption := "Lendo usuarios"
   ProcessMessages()
EndIf
// Verifica para quais usuários deverá ser enviado
_cAlias := GetNextAlias()
If _lUserLogado
   _cFiltro:="% AND ZZL_CODUSU = '"+__cUserId+"' %"
   BeginSql alias _cAlias
		SELECT
			ZZL_EMAIL	AS EMAIL,
			ZZL_FILWEP	AS FILIAIS
		FROM
			%Table:ZZL%
		WHERE
				D_E_L_E_T_	= ' '
			AND	ZZL_ENVEXP	= 'S' 
				%Exp:_cFiltro%
   EndSql
Else
   BeginSql alias _cAlias
		SELECT
			ZZL_EMAIL	AS EMAIL,
			ZZL_FILWEP	AS FILIAIS
		FROM
			%Table:ZZL%
		WHERE
				D_E_L_E_T_	= ' '
			AND	ZZL_ENVEXP	= 'S' 
   EndSql
EndIf

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

u_itconout( 'Leitura dos usuários destinatários' )

// Realiza o processamento e envio dos e-mails
If !(_cAlias)->( Eof() )
    
   If ValType(oproc) = "O"
      oproc:cCaption := 'Monta os dados do WF'
      ProcessMessages()
   EndIf

   u_itconout( 'Monta os dados do WF' )
   _aDados := MOMS021MNT( _cFilial , oproc)
	
   If ValType(oproc) = "O"
      oproc:cCaption := 'Recupera os dados de Sub-Grupos'
      ProcessMessages()
   EndIf
   
   u_itconout( 'Recupera os dados de Sub-Grupos' )
   _aSubGr := MOMS021SUB( _cFilial )
    
   While !(_cAlias)->( Eof() )
	  aAdd( _aMail , { AllTrim( (_cAlias)->EMAIL ) , AllTrim( (_cAlias)->FILIAIS ) } )
	  (_cAlias)->( DBSkip() )
   EndDo
	
	// Realiza o processamento e envio dos e-mails
	For nI := 1 To Len( _aMail )
		
        If ValType(oproc) = "O"
           oproc:cCaption := 'Enviando email  para : '+LOWER(AllTrim(_aMail[nI][01]))
           ProcessMessages()
        EndIf
        
		If !_lCriaAmb .And. !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
		     MOMS021HTM( _aMail[nI][01] , _aMail[nI][02] , _aDados , _aSubGr , oproc)
		Else

		   u_itconout( 'Enviando email para o usuário: '+ _aMail[nI][01] )
		   MOMS021HTM( _aMail[nI][01] , _aMail[nI][02] , _aDados , _aSubGr , oproc)

		EndIf

	Next nI

Else

	u_itconout( 'Não localizados usuários para enviar email!' )

EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS021HTM
Autor-------------: Guilherme Diogo
Data da Criacao---: 26/09/2012
Descrição---------: Funcao desenvolvida para realizar a geracao do arquivo HTML para posterior envio aos usuarios.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS021HTM( _cEmailDes , _cFilMail , _aDados , _aSubGr , oproc)

Local _cArqHtml		:= "\spool\estoque_"+ DToS( Date() ) +"_"+ StrTran( Time() , ":" , "" ) +".html"	// Nome do arquivo anexo a ser enviado ao usuario
Local _nHdl			:= ""
Local _cMsgEmail	:= ""
Local _cGeracao		:= DToC( Date() )
Local cMailLog		:= ""
Local cCabAux		:= ""

Local nPosSub		:= 0
Local lCriaTb		:= .F.

Local _aFilWf		:= StrTokArr( _cFilMail , ";" )

Local _nEstDis		:= 0
Local _nPedCar		:= 0
Local _nExpDa		:= 0
Local _nPrdDa		:= 0
Local _nPrcPed		:= 0
Local _nPrcFat		:= 0
Local _nPrcMix		:= 0 
Local _nQtdTer		:= 0
Local _nTotTer		:= 0

Local _nQtdPed		:= 0 
Local _nValPed		:= 0
Local _nQtdFat		:= 0
Local _nValFat		:= 0

Local _aFilDados	:= {}
Local _aDadFul		:= {} 

Local nPosGer		:= 0
Local _nPosAux		:= 0
Local _aDadosGer	:= {}
Local _aDadPrt		:= {}
Local _aDadFil		:= {}
Local _aDadAux		:= {}
Local _nDadAux		:= 0
Local _nTotAux		:= 0
Local _aTotFil		:= {}
Local _aDadTer		:= {}
Local _nJ			:= 0
Local nR			:= 0
Local _nI			:= 0
Local _nG			:= 0
Local _nF			:= 0
Local cConfig		:= GetMV( "IT_CMWFEP" ,, "001" )
Local aConfig		:= U_ITCFGEML( cConfig )

//Verifica as configurações do serviço de e-mail
If Empty(aConfig)
	u_itconout( 'Não foi possível carregar as configurações do serviço de e-mail!' )
	Return
EndIf

// Tenta criar o arquivo em área temporária do Server
_nHdl := FCreate( _cArqHtml )

If _nHdl == -1

	u_itconout( 'Não foi possível criar o arquivo de Estoque x Pedidos: '+ _cArqHtml )
	Return
	
Else
	
	u_itconout( 'Gravando o cabeçalho do arquivo.' )
	
	// Grava o cabeçalho do arquivo
	_cBuffer := '<!DOCTYPE HTML Public "-//W3C//DTD HTML 4.0 Transitional//EN">'
	_cBuffer += '<HTML>' 
	_cBuffer += '<HEAD><TITLE>Estoque x Pedido em Carteira</TITLE></HEAD>' 
	_cBuffer += '<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">' 
	_cBuffer += '<style>' 
	_cBuffer += 'table.bordasimples { border-collapse: collapse; } ' 
	_cBuffer += 'table.bordasimples tr td { border:1px solid #777777; } ' 
	_cBuffer += 'td.grupos	{ font-family:VERDANA; font-size:18px; V-align:middle; background-color: #000099; color:#FFFFFF; } ' 
	_cBuffer += 'td.titulos	{ font-family:VERDANA; font-size:16px; V-align:middle; background-color: #FFCC33; } ' 
	_cBuffer += 'td.itens	{ font-family:VERDANA; font-size:10px; V-align:middle; } '
	_cBuffer += 'td.totais	{ font-family:VERDANA; font-size:12px; V-align:middle; background-color: #AAAAAA; } ' 
	_cBuffer += '</style>' 
	_cBuffer += '<body>' 
	
	// Grava o Título Geral da tabela
	_cBuffer += '<br>' 
	_cBuffer += '<table width="100%" align="center" cellpadding="0" cellspacing="0">' 
	_cBuffer += '<tr>' 
	_cBuffer += '<td width="100%" align="center" class="grupos"><b>Estoque x Pedido em Carteira</b></td>' 
	_cBuffer += '</tr>' 
	_cBuffer += '</table>' 
	
	FWrite( _nHdl , _cBuffer )
	_cBuffer := ""
	
	// Processa o Controle de Filiais
	u_itconout( 'Processa os dados por Filial.' )
	
	For _nF := 1 To Len(_aFilWf)
	
		_aFilDados	:= {}
		_aDadFil	:= {}
		
		For _nJ := 1 To Len(_aSubGr)
		
			If _aSubGr[_nJ,1] == _aFilWf[_nF]
			
				aAdd( _aFilDados , { _aSubGr[_nJ,1] , _aSubGr[_nJ,2] , _aSubGr[_nJ,3] } )
				
			EndIf
		
		Next _nJ
		
		// Processa os dados da Filial
		For _nG := 1 To Len(_aFilDados)
			
			If _nG == 1
			
				u_itconout( 'Gravando o cabeçalho do arquivo por Filial: '+ AllTrim(Posicione("SM0",1,SM0->M0_CODIGO+_aFilWf[_nF],"M0_FILIAL")) )
				// Guarda Linha do Cabeçalho
				aAdd( _aDadFil ,	'<br>'  +;
									'<table width="100%" align="center" cellpadding="0" cellspacing="0">'  +;
									'	<tr>'  +;
									'		<td width="100%" align="center" class="grupos"><b>'+AllTrim(Posicione("SM0",1,SM0->M0_CODIGO+_aFilWf[_nF],"M0_FILIAL"))+'</b></td>'  +;
									'	</tr>'  +;
									'</table>'  )
				
			EndIf
			
			cCabAux		:= ''
			_aDadAux	:= {}
			_nDadAux	:= 0
			
			If cCabAux <> AllTrim( _aFilDados[_nG,03] )
			
				cCabAux := AllTrim( _aFilDados[_nG,03] )
				
				// Monta tabela que contém todos os dados de Estoque x Pedidos
				aAdd( _aDadAux ,	'<br>'  +;
									'<table align="center" width="100%" cellpadding="0" cellspacing="0" class="bordasimples">'   +;
									'	<tr>'   +;
									'		<td width="100%" align="center" colspan="15" class="titulos"><b>'+ AllTrim( _aFilDados[_nG,03] ) +'</b></td>' +;
									'	</tr>'   +;
									'	<tr>'   +;
									'		<td width="29%" bgcolor="#D8D8D8" rowspan="2" align="center" align="center" class="itens"><b>Produtos</b></td>' +;
									'		<td width="09%" bgcolor="#D8D8D8" colspan="2" align="center" align="center" class="itens"><b>Estoque</b></td>' +;
									'		<td width="09%" bgcolor="#D8D8D8" colspan="2" align="center" align="center" class="itens"><b>Estoque 3ºs</b></td>' +;
									'		<td width="09%" bgcolor="#D8D8D8" colspan="2" align="center" align="center" class="itens"><b>Pedido em Carteira</b></td>' +;
									'		<td width="09%" bgcolor="#D8D8D8" colspan="2" align="center" align="center" class="itens"><b>Exp. - Dia Anterior</b></td>' +;
									'		<td width="09%" bgcolor="#D8D8D8" colspan="2" align="center" align="center" class="itens"><b>Prd. - Dia Anterior</b></td>' +;
									'		<td width="26%" bgcolor="#D8D8D8" colspan="4" align="center" align="center" class="itens"><b>Prc. Médio/Mês - NET</b></td>' +;
									'	</tr>' +;
									'	<tr>' +;
									'		<td width="07%" bgcolor="#D8D8D8" align="center" class="itens">Qtd.</td>' +;
									'		<td width="02%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</td>' +;
									'		<td width="07%" bgcolor="#D8D8D8" align="center" class="itens">Qtd.</td>' +;
									'		<td width="02%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</td>' +;
									'		<td width="07%" bgcolor="#D8D8D8" align="center" class="itens">Qtd.</td>' +;
									'		<td width="02%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</td>' +;
									'		<td width="07%" bgcolor="#D8D8D8" align="center" class="itens">Qtd.</td>' +;
									'		<td width="02%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</td>' +;
									'		<td width="07%" bgcolor="#D8D8D8" align="center" class="itens">Qtd.</td>' +;
									'		<td width="02%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</td>' +;
									'		<td width="02%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</td>' +;
									'		<td width="08%" bgcolor="#D8D8D8" align="center" class="itens">Ped.Pend.</td>' +;
									'		<td width="08%" bgcolor="#D8D8D8" align="center" class="itens">Faturado</td>' +;
									'		<td width="08%" bgcolor="#D8D8D8" align="center" class="itens">Mix</td>' +;
									'	</tr>'  )
				
			EndIf
			
			_nEstDis	:= 0
			_nEstTer	:= 0
			_nPedCar	:= 0
			_nExpDa		:= 0
			_nPrdDa		:= 0
			_nPrcPed	:= 0
			_nPrcFat	:= 0
			_nPrcMix	:= 0
			_nQtdPed	:= 0
			_nValPed	:= 0
			_nQtdFat	:= 0
			_nValFat	:= 0
			_nQtdTer	:= 0
			_nTotTer	:= 0
			nPosSub		:= aScan( _aDados , {|x| AllTrim(x[1]) + AllTrim(x[2]) == _aFilDados[_nG,1] + _aFilDados[_nG,2] } )
			
			If nPosSub > 0
			    
			    For nR := 1 To Len(_aDados)
			    
			    	If	_aDados[nR,1] + _aDados[nR,2] == _aFilDados[_nG,1] + _aFilDados[_nG,2] .And. ( ( _aDados[nR,5] + _aDados[nR,6] - _aDados[nR,7] ) > 0 .Or. _aDados[nR,9] > 0 )
			    	
			    		nPosGer := aScan( _aDadosGer , {|x| AllTrim(x[2]) == AllTrim(_aDados[nR,3]) } )
			    		
			    		If nPosGer > 0
			    		
			    			_aDadosGer[nPosGer,04] += _aDados[nR,05]
			    			_aDadosGer[nPosGer,05] += _aDados[nR,06]
			    			_aDadosGer[nPosGer,06] += _aDados[nR,07]
			    			_aDadosGer[nPosGer,08] += _aDados[nR,09]
			    			_aDadosGer[nPosGer,10] += _aDados[nR,11]
			    			_aDadosGer[nPosGer,12] += _aDados[nR,13]
			    			_aDadosGer[nPosGer,15] += _aDados[nR,16]
			    			_aDadosGer[nPosGer,16] += _aDados[nR,17]
			    			_aDadosGer[nPosGer,17] += _aDados[nR,18]
			    			_aDadosGer[nPosGer,18] += _aDados[nR,19]
			    			
			    		Else
			    		    
			    			aAdd( _aDadosGer , {	_aDados[nR,02]	, _aDados[nR,03]	, _aDados[nR,04]	, _aDados[nR,05]	, _aDados[nR,06]	,;
			    			                 		_aDados[nR,07]	, _aDados[nR,08]	, _aDados[nR,09]	, _aDados[nR,10]	, _aDados[nR,11]	,;
			    			                 		_aDados[nR,12]	, _aDados[nR,13]	, _aDados[nR,14]	, _aDados[nR,15]	, _aDados[nR,16]	,;
			    			                 		_aDados[nR,17]	, _aDados[nR,18]	, _aDados[nR,19]	, _aDados[nR,20]						})
			    			
			    		EndIf
			    	    
						_nPedCar	+= _aDados[nR,09]
						_nEstDis	+= _aDados[nR,05] 
						_nExpDa		+= _aDados[nR,11]
						_nPrdDa		+= _aDados[nR,13]
						_nQtdTer	:= MOMS021TER( AllTrim( _aDados[nR][01] ) , AllTrim( _aDados[nR][03] ) , AllTrim( _aDados[nR][20] ) )
						
						If ( _nPosAux := aScan( _aDadTer , {|x| x[01] == _aDados[nR][03] } ) ) > 0
							_aDadTer[_nPosAux][02] += _nQtdTer
						Else
							aAdd( _aDadTer , { _aDados[nR][03] , _nQtdTer } )
						EndIf
						
						aAdd( _aDadAux ,	'	<tr>'  +;
											'		<td align="left"   width="29%" class="itens">'+	AllTrim( SubStr( _aDados[nR,4] , 1 , 50 ) ) +'</td>' +;
											'		<td align="right"  width="07%" class="itens">'+	AllTrim( Transform(_aDados[nR,5],"@E 999,999,999,999.99") ) +'</td>' +;
											'		<td align="center" width="02%" class="itens">'+	AllTrim( _aDados[nR,8] ) +'</td>' +;
											'		<td align="right"  width="07%" class="itens">'+	AllTrim( Transform( _nQtdTer , "@E 999,999,999,999.99" ) ) +'</td>' +;
											'		<td align="center" width="02%" class="itens">'+	AllTrim( _aDados[nR,8] ) +'</td>' +;
											'		<td align="right"  width="07%" class="itens">'+	AllTrim( Transform(_aDados[nR,9],"@E 999,999,999,999.99") ) +'</td>' +;
											'		<td align="center" width="02%" class="itens">'+	AllTrim( _aDados[nR,10] ) +'</td>' +;
											'		<td align="right"  width="07%" class="itens">'+	AllTrim( Transform(_aDados[nR,11],"@E 999,999,999,999.99") ) +'</td>' +;
											'		<td align="center" width="02%" class="itens">'+	AllTrim( _aDados[nR,12] ) +'</td>' +;
											'		<td align="right"  width="07%" class="itens">'+	AllTrim( Transform(_aDados[nR,13],"@E 999,999,999,999.99") ) +'</td>' +;
											'		<td align="center" width="02%" class="itens">'+	AllTrim( _aDados[nR,14] ) +'</td>' +;
											'		<td align="center" width="02%" class="itens">'+ AllTrim( _aDados[nR,15] ) +'</td>' +;
											'		<td align="right"  width="08%" class="itens">R$ '+ Transform(_aDados[nR,17]/_aDados[nR,16],"@E 999,999,999,999.9999") +'</td>' +;
											'		<td align="right"  width="08%" class="itens">R$ '+ Transform(_aDados[nR,19]/_aDados[nR,18],"@E 999,999,999,999.9999") +'</td>' +;
											'		<td align="right"  width="08%" class="itens">R$ '+ Transform((_aDados[nR,17]+_aDados[nR,19])/(_aDados[nR,16]+_aDados[nR,18]),"@E 999,999,999,999.9999") +'</td>' +;
											'	</tr>'  )
						                
						_nQtdPed += _aDados[nR,16]
						_nValPed += _aDados[nR,17]
						_nQtdFat += _aDados[nR,18]
						_nValFat += _aDados[nR,19]
						_nTotTer += _nQtdTer
						_nDadAux++
						
					EndIf
				
				Next nR
				
				_nPrcPed := _nValPed / _nQtdPed
				_nPrcFat := _nValFat / _nQtdFat 
				_nPrcMix := (_nValPed + _nValFat)/(_nQtdPed + _nQtdFat)
				
				If _nDadAux > 0
				
					aAdd( _aDadAux ,	'	<tr>' +;
										'		<td align="left"  width="29%" class="totais"><b>TOTAL</b></td>' +;
										'		<td align="right" width="07%" class="totais"><b>'+ Transform(_nEstDis,"@E 999,999,999,999.99") +'</b></td>' +;
										'		<td align="right" width="02%" class="totais"><b>&nbsp</b></td>' +;
										'		<td align="right" width="07%" class="totais"><b>'+ Transform(_nTotTer,"@E 999,999,999,999.99") +'</b></td>' +;
										'		<td align="right" width="02%" class="totais"><b>&nbsp</b></td>' +;
										'		<td align="right" width="07%" class="totais"><b>'+ Transform(_nPedCar,"@E 999,999,999,999.99") +'</b></td>' +;
										'		<td align="right" width="02%" class="totais"><b>&nbsp</b></td>' +;
										'		<td align="right" width="07%" class="totais"><b>'+ Transform(_nExpDa,"@E 999,999,999,999.99") +'</b></td>' +;
										'		<td align="right" width="02%" class="totais"><b>&nbsp</b></td>' +;
										'		<td align="right" width="07%" class="totais"><b>'+ Transform(_nPrdDa,"@E 999,999,999,999.99") +'</b></td>' +;
										'		<td align="right" width="02%" class="totais"><b>&nbsp</b></td>' +;
										'		<td align="right" width="02%" class="totais"><b>&nbsp</b></td>' +;
										'		<td align="right" width="08%" class="totais"><b>R$ '+ Transform(_nPrcPed,"@E 999,999,999,999.9999") +'</b></td>' +;
										'		<td align="right" width="08%" class="totais"><b>R$ '+ Transform(_nPrcFat,"@E 999,999,999,999.9999") +'</b></td>' +;
										'		<td align="right" width="08%" class="totais"><b>R$ '+ Transform(_nPrcMix,"@E 999,999,999,999.9999") +'</b></td>' +;
										'	</tr>'  )
					
					For _nI := 1 To Len( _aDadAux )
						aAdd( _aDadFil , _aDadAux[_nI] )
					Next _nI
					
					aAdd( _aDadFil , '</table>'  )
					
					_nTotAux++
					
					If aScan( _aDadFul , {|x| x[1] == 'GERAL' .And. x[2] == _aFilDados[_nG,2] .And. x[3] == _aFilDados[_nG,3] } ) == 0
						aAdd( _aDadFul , { 'GERAL' , _aFilDados[_nG,2] , _aFilDados[_nG,3] } )
					EndIf
					
				EndIf
			
			EndIf
			
		Next _nG
		
		If _nTotAux > 0
			
			For _nI := 1 To Len( _aDadFil )
				
				aAdd( _aDadPrt , _aDadFil[_nI] )
				
			Next _nI
			
		EndIf
		
	Next _nF
	
	u_itconout( 'Gravação do Cabeçalho do Resumo de Todas as Filiais.' )
	// Inicializa a seção Geral de Todas as Unidades
	_cBuffer += '<br>' 
	_cBuffer += '<table width="100%" align="center" cellpadding="0" cellspacing="0">' 
	_cBuffer += '	<tr>' 
	_cBuffer += '		<td width="100%" align="center" class="grupos"><b>GERAL - TODAS AS UNIDADES</b></td>' 
	_cBuffer += '	</tr>' 
	_cBuffer += '</table>' 
	
	FWrite( _nHdl	, _cBuffer )
	aAdd( _aTotFil	, _cBuffer )
	_cBuffer := ""
	
	// Processa os dados de Todas as Unidades
	u_itconout( 'Gravação dos dados do Resumo de Todas as Filiais.' )
	
	_aDadFul := aSort( _aDadFul ,,, {|x, y| x[2] < y[2] } )
	
	For _nG := 1 To Len( _aDadFul )
	
		_nEstDis    := 0
		_nPedCar    := 0
		_nExpDa     := 0
		_nPrdDa     := 0
		_nPrcPed    := 0
		_nPrcFat    := 0
		_nPrcMix    := 0
		_nQtdPed    := 0
		_nValPed    := 0
		_nQtdFat    := 0
		_nValFat    := 0
		_nQtdTer	:= 0
		_nTotTer	:= 0
		
		lCriaTb		:= .F.
		nPosSub		:= aScan( _aDadosGer , {|x| AllTrim(x[1]) == AllTrim( _aDadFul[_nG,2] ) } )
			
		If nPosSub > 0 
			    
		    For nR := 1 To Len(_aDadosGer)  
			    
		    	If AllTrim(_aDadosGer[nR,1]) == AllTrim(_aDadFul[_nG,2]) .And. (_aDadosGer[nR,4]+_aDadosGer[nR,5]-_aDadosGer[nR,6]) + _aDadosGer[nR,8] + _aDadosGer[nR,10] + _aDadosGer[nR,12] + _aDadosGer[nR,15] + _aDadosGer[nR,16] + _aDadosGer[nR,17] + _aDadosGer[nR,18] <> 0
			    	       
			        If !lCriaTb
			        
						// Cria o cabeçalho da tabela principal
						_cBuffer += '<br>'
						_cBuffer += '<table align="center" width="100%" cellpadding="0" cellspacing="0" class="bordasimples">' 
						_cBuffer += '	<tr>' 
						_cBuffer += '		<td width="100%" align="center" colspan="15" class="titulos"><b>'+_aDadFul[_nG,3]+'</b></td>' 
						_cBuffer += '	<tr>'   
						_cBuffer += '		<td width="29%" bgcolor="#D8D8D8" rowspan="2" align="center" align="center" class="itens"><b>Produtos</b></td>' 
						_cBuffer += '		<td width="09%" bgcolor="#D8D8D8" colspan="2" align="center" align="center" class="itens"><b>Estoque</b></td>' 
						_cBuffer += '		<td width="09%" bgcolor="#D8D8D8" colspan="2" align="center" align="center" class="itens"><b>Estoque 3ºs</b></td>' 
						_cBuffer += '		<td width="09%" bgcolor="#D8D8D8" colspan="2" align="center" align="center" class="itens"><b>Pedido em Carteira</b></td>' 
						_cBuffer += '		<td width="09%" bgcolor="#D8D8D8" colspan="2" align="center" align="center" class="itens"><b>Exp. - Dia Anterior</b></td>' 
						_cBuffer += '		<td width="09%" bgcolor="#D8D8D8" colspan="2" align="center" align="center" class="itens"><b>Prd. - Dia Anterior</b></td>' 
						_cBuffer += '		<td width="26%" bgcolor="#D8D8D8" colspan="4" align="center" align="center" class="itens"><b>Prc. Médio/Mês - NET</b></td>' 
						_cBuffer += '	</tr>' 
						_cBuffer += '	<tr>' 
						_cBuffer += '		<td width="07%" bgcolor="#D8D8D8" align="center" class="itens">Qtd.</td>' 
						_cBuffer += '		<td width="02%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</td>' 
						_cBuffer += '		<td width="07%" bgcolor="#D8D8D8" align="center" class="itens">Qtd.</td>' 
						_cBuffer += '		<td width="02%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</td>' 
						_cBuffer += '		<td width="07%" bgcolor="#D8D8D8" align="center" class="itens">Qtd.</td>' 
						_cBuffer += '		<td width="02%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</td>' 
						_cBuffer += '		<td width="07%" bgcolor="#D8D8D8" align="center" class="itens">Qtd.</td>' 
						_cBuffer += '		<td width="02%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</td>' 
						_cBuffer += '		<td width="07%" bgcolor="#D8D8D8" align="center" class="itens">Qtd.</td>' 
						_cBuffer += '		<td width="02%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</td>' 
						_cBuffer += '		<td width="02%" bgcolor="#D8D8D8" align="center" class="itens">U.M.</td>' 
						_cBuffer += '		<td width="08%" bgcolor="#D8D8D8" align="center" class="itens">Ped.Pend.</td>' 
						_cBuffer += '		<td width="08%" bgcolor="#D8D8D8" align="center" class="itens">Faturado</td>' 
						_cBuffer += '		<td width="08%" bgcolor="#D8D8D8" align="center" class="itens">Mix</td>' 
						_cBuffer += '	</tr>' 
						
						FWrite( _nHdl	, _cBuffer )
						aAdd( _aTotFil	, _cBuffer )
						_cBuffer := ""
						
						lCriaTb := .T.
						
					EndIf
			    	 
					_nEstDis	+= ( _aDadosGer[nR,04] + _aDadosGer[nR,05] - _aDadosGer[nR,06] )
					_nPedCar	+= _aDadosGer[nR,08]
					_nExpDa		+= _aDadosGer[nR,10]
					_nPrdDa		+= _aDadosGer[nR,12]
					_nQtdPed	+= _aDadosGer[nR,15]
			   		_nValPed	+= _aDadosGer[nR,16]
					_nQtdFat	+= _aDadosGer[nR,17]
					_nValFat	+= _aDadosGer[nR,18]
					
					If ( _nPosAux := aScan( _aDadTer , {|x| x[01] == _aDadosGer[nR][02] } ) ) > 0
						_nQtdTer := _aDadTer[_nPosAux][02]
					Else
						_nQtdTer := 0
					EndIf
					
					_nTotTer	+= _nQtdTer
					
					_cBuffer := '	<tr>' 
					_cBuffer += '		<td align="left"   width="29%" class="itens">'+ AllTrim( SubStr( _aDadosGer[nR,3] , 1 , 50 ) ) +'</td>' 
					_cBuffer += '		<td align="right"  width="07%" class="itens">'+	AllTrim( Transform(_aDadosGer[nR,4]+_aDadosGer[nR,5]-_aDadosGer[nR,6],"@E 999,999,999,999.99") ) +'</td>' 
					_cBuffer += '		<td align="center" width="02%" class="itens">'+	AllTrim( _aDadosGer[nR,7] ) +'</td>' 
					_cBuffer += '		<td align="right"  width="07%" class="itens">'+	AllTrim( Transform( _nQtdTer , "@E 999,999,999,999.99" ) ) +'</td>' 
					_cBuffer += '		<td align="center" width="02%" class="itens">'+	AllTrim( _aDadosGer[nR,7] ) +'</td>' 
					_cBuffer += '		<td align="right"  width="07%" class="itens">'+	AllTrim( Transform(_aDadosGer[nR,8],"@E 999,999,999,999.99") ) +'</td>' 
					_cBuffer += '		<td align="center" width="02%" class="itens">'+	AllTrim( _aDadosGer[nR,9] ) +'</td>' 
					_cBuffer += '		<td align="right"  width="07%" class="itens">'+	AllTrim( Transform(_aDadosGer[nR,10],"@E 999,999,999,999.99") ) +'</td>' 
					_cBuffer += '		<td align="center" width="02%" class="itens">'+	AllTrim( _aDadosGer[nR,11] ) +'</td>' 
					_cBuffer += '		<td align="right"  width="07%" class="itens">'+	AllTrim( Transform(_aDadosGer[nR,12],"@E 999,999,999,999.99") ) +'</td>' 
					_cBuffer += '		<td align="center" width="02%" class="itens">'+	AllTrim( _aDadosGer[nR,13] ) +'</td>' 
					_cBuffer += '		<td align="center" width="02%" class="itens">'+ AllTrim( _aDadosGer[nR,14] ) +'</td>' 
					_cBuffer += '		<td align="right"  width="08%" class="itens">R$ '+ Transform(_aDadosGer[nR,16]/_aDadosGer[nR,15],"@E 999,999,999,999.9999") +'</td>' 
					_cBuffer += '		<td align="right"  width="08%" class="itens">R$ '+ Transform(_aDadosGer[nR,18]/_aDadosGer[nR,17],"@E 999,999,999,999.9999") +'</td>' 
					_cBuffer += '		<td align="right"  width="08%" class="itens">R$ '+ Transform((_aDadosGer[nR,16]+_aDadosGer[nR,18])/(_aDadosGer[nR,15]+_aDadosGer[nR,17]),"@E 999,999,999,999.9999") +'</td>' 
					_cBuffer += '	</tr>' 
					
					FWrite( _nHdl	, _cBuffer )
					aAdd( _aTotFil	, _cBuffer )
					_cBuffer := ""
								
				EndIf
				
			Next nR
				
			_nPrcPed	:= _nValPed / _nQtdPed
			_nPrcFat	:= _nValFat / _nQtdFat 
			_nPrcMix	:= ( _nValPed + _nValFat ) / ( _nQtdPed + _nQtdFat )
			
			If _nEstDis + _nPedCar + _nExpDa + _nPrdDa + _nPrcPed + _nPrcFat + _nPrcMix <> 0
				
				_cBuffer := '	<tr>' 
				_cBuffer += '		<td align="left"  width="29%" class="totais"><b>TOTAL</b></td>' 
				_cBuffer += '		<td align="right" width="07%" class="totais"><b>'+ Transform(_nEstDis,"@E 999,999,999,999.99") +'</b></td>' 
				_cBuffer += '		<td align="right" width="02%" class="totais"><b>&nbsp</b></td>' 
				_cBuffer += '		<td align="right" width="07%" class="totais"><b>'+ Transform(_nTotTer,"@E 999,999,999,999.99") +'</b></td>' 
				_cBuffer += '		<td align="right" width="02%" class="totais"><b>&nbsp</b></td>' 
				_cBuffer += '		<td align="right" width="07%" class="totais"><b>'+ Transform(_nPedCar,"@E 999,999,999,999.99") +'</b></td>' 
				_cBuffer += '		<td align="right" width="02%" class="totais"><b>&nbsp</b></td>' 
				_cBuffer += '		<td align="right" width="07%" class="totais"><b>'+ Transform(_nExpDa ,"@E 999,999,999,999.99") +'</b></td>' 
				_cBuffer += '		<td align="right" width="02%" class="totais"><b>&nbsp</b></td>' 
				_cBuffer += '		<td align="right" width="07%" class="totais"><b>'+ Transform(_nPrdDa ,"@E 999,999,999,999.99") +'</b></td>' 
				_cBuffer += '		<td align="right" width="02%" class="totais"><b>&nbsp</b></td>' 
				_cBuffer += '		<td align="right" width="02%" class="totais"><b>&nbsp</b></td>' 
				_cBuffer += '		<td align="right" width="08%" class="totais"><b>R$ '+ Transform(_nPrcPed,"@E 999,999,999,999.9999") +'</b></td>' 
				_cBuffer += '		<td align="right" width="08%" class="totais"><b>R$ '+ Transform(_nPrcFat,"@E 999,999,999,999.9999") +'</b></td>' 
				_cBuffer += '		<td align="right" width="08%" class="totais"><b>R$ '+ Transform(_nPrcMix,"@E 999,999,999,999.9999") +'</b></td>' 
				_cBuffer += '	</tr>' 
				
				FWrite( _nHdl	, _cBuffer )
				aAdd( _aTotFil	, _cBuffer )
				_cBuffer := ""
				
			EndIf
			
			// Finaliza Tabela de Todas as Unidades
			_cBuffer := '</table>' 
						
			
			FWrite( _nHdl	, _cBuffer )
			aAdd( _aTotFil	, _cBuffer )
			_cBuffer := ""
						
		EndIf
				
	Next _nG
	
	// Imprime relatório por Filial
	u_itconout( 'Gravação do relatório por Filial.' )
	
	For _nF := 1 To Len( _aDadPrt )
		
		_cBuffer := _aDadPrt[_nF]
		FWrite( _nHdl , _cBuffer )
		_cBuffer := ""
		
		_cBuffer := ""
		
	Next _nF
	
	// Finaliza Arquivo
	u_itconout( 'Encerrando arquivo.' )
	
	_cBuffer := '</body>' 
	_cBuffer += '</html>' 
	
	FWrite( _nHdl , _cBuffer )
	_cBuffer := ""

	// Encerra o arquivo e Processa o envio por e-mail
	FClose(_nHdl)
	
	u_itconout( 'Monta o corpo do e-mail.' )
	
	_cMsgEmail := '<style Type="text/css"><!--'
	_cMsgEmail += 'table.bordasimples { border-collapse: collapse; } '
	_cMsgEmail += 'table.bordasimples tr td { border:1px solid #777777; } '
	_cMsgEmail += 'td.grupos	{ font-family:VERDANA; font-size:18px; V-align:middle; background-color: #000099; color:#FFFFFF; } '
	_cMsgEmail += 'td.titulos	{ font-family:VERDANA; font-size:16px; V-align:middle; background-color: #FFCC33; } '
	_cMsgEmail += 'td.itens		{ font-family:VERDANA; font-size:12px; V-align:middle; } '
	_cMsgEmail += 'td.totais	{ font-family:VERDANA; font-size:12px; V-align:middle; background-color: #AAAAAA; } '
	_cMsgEmail += '--></style>'
	_cMsgEmail += "<B>Senhor Diretor</B><BR><BR>"
	_cMsgEmail += "Segue anexo relatório diário da relação [ Estoque x Pedidos em Carteira ].<BR><BR>"
	_cMsgEmail += "<I>Essa é uma mensagem automática, favor não responder a este e-mail.</I><BR><BR>"
	
	// Indica ambiente de execução do relatório
	If !(_lCriaAmb)
		_cMsgEmail += '<BR><BR>Executado no ambiente ' + Upper( GetEnvServer() )  + " via smartclient [MOMS021] <BR><BR>"
	Else
		_cMsgEmail += '<BR><BR>Executado no ambiente ' + Upper( GetEnvServer() ) + " via schedule, debug ou webservice [MOMS021] <BR><BR>"
	EndIf
	
	For _nF := 1 To Len( _aTotFil )
		_cMsgEmail += _aTotFil[_nF]
	Next _nF
	
	u_itconout( 'Processa o envio do e-mail.' )
	U_ITENVMAIL( aConfig[01] , _cEmailDes ,,, "Estoque X Pedidos em Carteira - "+ _cGeracao , _cMsgEmail , _cArqHtml , aConfig[01] , aConfig[02] , aConfig[03] , aConfig[04] , aConfig[05] , aConfig[06] , aConfig[07] , @cMailLog )
	
	If !Empty( cMailLog )
		u_itconout( 'Status do envio de e-mail: '+ cMailLog )
	EndIf
	
	If FERASE(_cArqHtml) == -1
	   u_itconout('[MOMS012]['+ DToC(Date()) +" - "+ Time() +'] - Não foi possível excluir o Arquivo HTML: '+ _cArqHtml )
	EndIf
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS021MNT
Autor-------------: Guilherme Diogo
Data da Criacao---: 26/09/2012
Descrição---------: Funcao desenvolvida para buscar e estruturar os dados necessários para o Workflow
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS021MNT( _cFilial , oproc )

Local _aDados	:= {}
Local cQuery    := ""
Local cAlias	:= GetNextAlias()
Local _nX		:= 0
Local nPosEnt	:= 0
Local nPosSai	:= 0
Local nPosPed	:= 0 
Local nPosExp	:= 0
Local nPosPda	:= 0
Local nPosPP 	:= 0
Local nPosPF 	:= 0
Local _nQtdMin	:= GetMV( 'IT_QMINEST' ,, 10 )
Local x			:= 0
Local _cArmz	:= GetMV( 'IT_PAARMW' ,, '20;30;01' )
Local nArm		:= 0
Local cCfops 	:= U_ITCFOPS('V/B') 
Local _aFilial	:= StrTokArr(_cFilial,"/")
Local _aArm		:= StrTokArr(_cArmz,";") 
Local _cListaCod:= SuperGetMV("IT_M021EXC",.T.,"08000000061")
//===========================================================================
//| Posicoes do array _aDados                                               |
//===========================================================================
//| Estoque Disponivel                                                      |
//| 01 - Filial                                                             |
//| 02 - Sub Grupo                                                          |
//| 03 - Codigo do Produto                                                  |
//| 04 - Descricao do Produto                                               |
//| 05 - Saldo Anterior                                                     |
//| 06 - Quantidade entrada na primeira unidade de medida --> ED.QUANT      |
//| 07 - Quantidade saida na primeira unidade de medida --> ED.QUANT        |
//| 08 - Primeira unidade de medida --> ED.UM                               |
//===========================================================================
//| Pedido em Carteira                                                      |
//| 09 - Quantidade                                                         |
//| 10 - UM                                                                 |
//===========================================================================
//| Expedicao - Dia Anterior                                                |
//| 11 - Quantidade                                                         |
//| 12 - UM                                                                 |
//===========================================================================
//| Producao - Dia Anterior                                                 |
//| 13 - Quant                                                              |
//| 14 - UM                                                                 |
//===========================================================================
//| Prc Medio                                                               |
//| 15 - UM Principal                                                       |
//| 16 - Quant. Pedido Pend.                                                |
//| 17 - Valor Pedido Pend.                                                 |
//| 18 - Quant. Faturado                                                    |
//| 19 - Valor Faturado                                                     |
//===========================================================================
//| 20 - Troca de unidade de Medida?                                        |
//===========================================================================

// Query que retorna todos os produtos do tipo PA
cQuery := " SELECT "
cQuery += 	" B1.B1_I_SUBGR AS SUBGRUPO, "
cQuery += 	" B1.B1_COD     AS PRODUTO, "
cQuery += 	" B1.B1_TIPO    AS TIPO, "
cQuery += 	" B1.B1_I_DESCD AS DESCPRODUT, "
cQuery += 	" B1.B1_UM      AS UM, "
cQuery += 	" B1.B1_SEGUM   AS SEGUM, "
cQuery += 	" B1.B1_I_WFUM  AS WFUM, "
cQuery += 	" B1.B1_MSBLQL  AS MSBLQL "
cQuery += " FROM "+ RetSqlName("SB1") + " B1 "
cQuery += " WHERE B1.D_E_L_E_T_ = ' ' "
cQuery += "	AND ( B1.B1_TIPO  = 'PA' OR ( B1.B1_TIPO = 'PP' AND B1.B1_I_SUBGR IN ('023','028') ) OR B1_COD IN " + FormatIn(_cListaCod,",") + " ) "
cQuery += " AND	  B1.B1_I_WFUM <> ' ' "
cQuery += "	AND   B1.B1_MSBLQL <> '1' "
cQuery += " ORDER BY SUBGRUPO , PRODUTO "

If ValType(oproc) = "O"
   oproc:cCaption := 'Consulta a tabela de Produtos'
   ProcessMessages()
EndIf
u_itconout( 'Consulta a tabela de Produtos' )

If Select(cAlias) > 0
	(cAlias)->(DBCloseArea())
EndIf

dbUseArea( .T., "TOPCONN",TcGenQry(,,cQuery),cAlias,.T.,.F.)                                  
	
DBSelectArea(cAlias)
(cAlias)->(DBGoTop())		

u_itconout( 'Gravação dos dados de Produtos' )	
While (cAlias)->(!Eof())

	For _nX := 1 To Len(_aFilial)
		
		// Verifica se segunda unidade de medida e KG e grava na posicao 14 do array ('S'/'N')
		If (cAlias)->WFUM == "1"
					
			aAdd(_aDados,{_aFilial[_nX],(cAlias)->subgrupo,(cAlias)->produto,(cAlias)->descprodut,0,0,0,(cAlias)->um   ,0,"",0,"",0,"",(cAlias)->um,0,0,0,0,"N"})
	
		ElseIf (cAlias)->WFUM == "2"
					
			aAdd(_aDados,{_aFilial[_nX],(cAlias)->subgrupo,(cAlias)->produto,(cAlias)->descprodut,0,0,0,(cAlias)->segum,0,"",0,"",0,"",(cAlias)->um,0,0,0,0,"S"})
					
		EndIf
		
	Next _nX
				

(cAlias)->(DBSkip())
	
EndDo	              

(cAlias)->( DBCloseArea() )

// Query que retorna os dados das entradas normais
cQuery := " SELECT "
cQuery += 	" DADOS.FILIAL       AS FILIAL, "
cQuery += 	" DADOS.PRODUTO      AS PRODUTO, "
cQuery += 	" DADOS.UM           AS UM, "
cQuery += 	" DADOS.SEGUM        AS SEGUM, "
cQuery += 	" SUM(DADOS.QUANT)   AS QUANT, "
cQuery += 	" SUM(DADOS.QTSEGUM) AS QTSEGUM "
cQuery += " FROM ( SELECT "
cQuery += 			" D1.D1_FILIAL       AS FILIAL, "
cQuery += 			" D1.D1_COD          AS PRODUTO, "
cQuery += 			" D1.D1_UM           AS UM, "
cQuery += 			" D1.D1_SEGUM        AS SEGUM, "
cQuery += 			" SUM(D1.D1_QUANT)   AS QUANT, "
cQuery += 			" SUM(D1.D1_QTSEGUM) AS QTSEGUM "
cQuery += 		" FROM "+ RetSqlName("SD1") +" D1 "
cQuery += 		" JOIN "+ RetSqlName("SF4") +" F4 ON D1.D1_FILIAL	= F4.F4_FILIAL AND D1.D1_TES = F4.F4_CODIGO "
cQuery += 		" JOIN "+ RetSqlName("SB1") +" B1 ON D1.D1_COD    = B1.B1_COD "
cQuery += 		" WHERE "
cQuery += 			" D1.D_E_L_E_T_ = ' ' "
cQuery += 		" AND F4.D_E_L_E_T_ = ' ' "
cQuery += 		" AND B1.D_E_L_E_T_ = ' ' "
cQuery += 		" AND F4.F4_ESTOQUE = 'S' "
cQuery += 		" AND D1.D1_DTDIGIT = '"+ DToS(DDATABASE) +"' "
cQuery += 		" AND D1.D1_LOCAL   IN "+ FormatIn(_cArmz,";")
cQuery += 		" AND ( B1.B1_TIPO   = 'PA' OR ( B1.B1_TIPO = 'PP' AND B1.B1_I_SUBGR IN ('023','028') ) OR B1_COD IN " + FormatIn(_cListaCod,",") + " ) "
cQuery += 		" AND B1.B1_I_WFUM  <> ' ' "
cQuery += 		" AND B1.B1_MSBLQL  <> '1' "     
cQuery += 		" GROUP BY D1.D1_FILIAL, D1.D1_COD, D1.D1_UM, D1.D1_SEGUM "

cQuery += 		" UNION ALL "

cQuery += 		" SELECT "
cQuery += 			" D3.D3_FILIAL       AS FILIAL, "
cQuery += 			" D3.D3_COD          AS PRODUTO, "
cQuery += 			" D3.D3_UM           AS UM, "
cQuery += 			" D3.D3_SEGUM        AS SEGUM, "
cQuery += 			" SUM(D3.D3_QUANT)   AS QUANT, "
cQuery += 			" SUM(D3.D3_QTSEGUM) AS QTSEGUM "
cQuery += 		" FROM "+ RetSqlName("SD3") + " D3 "
cQuery += 		" JOIN "+ RetSqlName("SB1") + " B1 ON D3.D3_COD = B1.B1_COD "
cQuery += 		" WHERE "
cQuery += 			" D3.D_E_L_E_T_	= ' ' "
cQuery += 		" AND B1.D_E_L_E_T_	= ' ' "
cQuery += 		" AND D3.D3_TM		<= '500' "
cQuery += 		" AND D3.D3_ESTORNO	<> 'S' "
cQuery += 		" AND D3.D3_EMISSAO	= '"+ DToS(DDATABASE) +"' "
cQuery += 		" AND D3.D3_LOCAL   IN "+ FormatIn(_cArmz,";")
cQuery += 		" AND ( B1.B1_TIPO   = 'PA'  OR ( B1.B1_TIPO = 'PP' AND B1.B1_I_SUBGR IN ('023','028') ) OR B1_COD IN " + FormatIn(_cListaCod,",") + " ) "
cQuery += 		" AND B1.B1_I_WFUM	<> ' ' "
cQuery += 		" AND B1.B1_MSBLQL  <> '1' "
cQuery += 		" GROUP BY D3.D3_FILIAL, D3.D3_COD, D3.D3_UM, D3.D3_SEGUM ) DADOS "
cQuery += " GROUP BY DADOS.FILIAL,DADOS.PRODUTO,DADOS.UM,DADOS.SEGUM "
cQuery += " ORDER BY FILIAL, PRODUTO "

If ValType(oproc) = "O"
   oproc:cCaption := 'Consulta os dados de Entradas normais'
   ProcessMessages()
EndIf
u_itconout( 'Consulta os dados de Entradas normais' )

If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , cAlias , .T. , .F. )

DBSelectArea(cAlias)
(cAlias)->(DBGoTop())

u_itconout( 'Grava os dados das Entradas' )
While (cAlias)->(!Eof())
	
	nPosEnt := aScan(_aDados,{|x| AllTrim(x[1]) + AllTrim(x[3]) == AllTrim( (cAlias)->filial ) + AllTrim( (cAlias)->produto ) } )
	
	If nPosEnt > 0
		  
		// Verifica qual unidade de medida eh usada no workflow
		If _aDados[nPosEnt,20] == "N"
			_aDados[nPosEnt,6] += IIf( _nQtdMin > (cAlias)->quant   , 0 , (cAlias)->quant   )
		ElseIf _aDados[nPosEnt,20] == "S"
		    _aDados[nPosEnt,6] += IIf( _nQtdMin > (cAlias)->qtsegum , 0 , (cAlias)->qtsegum )
		EndIf
		
	EndIf
	
(cAlias)->(DBSkip())
EndDo

(cAlias)->( DBCloseArea() )

nCountRec := 0

// Query que retorna os dados das saídas normais
cQuery := " SELECT "
cQuery += 	" DADOS.FILIAL, "
cQuery += 	" DADOS.PRODUTO, "
cQuery += 	" DADOS.UM, "
cQuery += 	" DADOS.SEGUM, "
cQuery += 	" SUM(DADOS.QUANT) QUANT, "
cQuery += 	" SUM(DADOS.QTSEGUM) QTSEGUM "
cQuery += " FROM ( "
cQuery += 		" SELECT "
cQuery += 			" D2.D2_FILIAL       AS FILIAL, "
cQuery += 			" D2.D2_COD          AS PRODUTO, "
cQuery += 			" D2.D2_UM           AS UM, "
cQuery += 			" D2.D2_SEGUM        AS SEGUM, "
cQuery += 			" SUM(D2.D2_QUANT)   AS QUANT, "
cQuery += 			" SUM(D2.D2_QTSEGUM) AS QTSEGUM "
cQuery += 		" FROM "+ RetSqlName("SD2") +" D2 "
cQuery += 		" JOIN "+ RetSqlName("SF4") +" F4 ON D2.D2_FILIAL = F4.F4_FILIAL AND D2.D2_TES = F4.F4_CODIGO "
cQuery += 		" JOIN "+ RetSqlName("SB1") +" B1 ON D2.D2_COD = B1.B1_COD "
cQuery += 		" WHERE "
cQuery += 			" D2.D_E_L_E_T_ = ' ' "
cQuery += 		" AND F4.D_E_L_E_T_ = ' ' "
cQuery += 		" AND B1.D_E_L_E_T_ = ' ' "
cQuery += 		" AND D2.D2_FILIAL  IN "+ FormatIn(_cFilial,"/")
cQuery += 		" AND F4.F4_FILIAL  IN "+ FormatIn(_cFilial,"/")
cQuery += 		" AND F4.F4_ESTOQUE = 'S' "
cQuery += 		" AND D2.D2_EMISSAO = '"+ DToS(DDATABASE) +"' "
cQuery += 		" AND D2.D2_LOCAL   IN "+ FormatIn(_cArmz,";")
cQuery += 		" AND B1.B1_TIPO    = 'PA' "
cQuery += 		" AND B1.B1_I_WFUM  <> ' ' "
cQuery += 		" AND B1.B1_MSBLQL  <> '1' "     
cQuery += 		" GROUP BY D2.D2_FILIAL, D2.D2_COD, D2.D2_UM, D2.D2_SEGUM "                                         

cQuery += 		" UNION ALL "    

cQuery += 		" SELECT "
cQuery += 			" D3.D3_FILIAL       AS FILIAL, "
cQuery += 			" D3.D3_COD          AS PRODUTO, "
cQuery += 			" D3.D3_UM           AS UM, "
cQuery += 			" D3.D3_SEGUM        AS SEGUM, "
cQuery += 			" SUM(D3.D3_QUANT)   AS QUANT, "
cQuery += 			" SUM(D3.D3_QTSEGUM) AS QTSEGUM "
cQuery += 		" FROM "+ RetSqlName("SD3") +" D3 "
cQuery += 		" JOIN "+ RetSqlName("SB1") +" B1 ON D3.D3_COD = B1.B1_COD "
cQuery += 		" WHERE "
cQuery += 			" D3.D_E_L_E_T_ = ' ' "
cQuery += 		" AND B1.D_E_L_E_T_ = ' ' "
cQuery += 		" AND D3.D3_FILIAL  IN "+ FormatIn(_cFilial,"/")
cQuery += 		" AND D3.D3_TM      > '500' "
cQuery += 		" AND D3_ESTORNO    <> 'S' "
cQuery += 		" AND D3.D3_EMISSAO = '"+ DToS(DDATABASE) +"' "
cQuery += 		" AND D3.D3_LOCAL   IN "+ FormatIn(_cArmz,";")
cQuery += 		" AND B1.B1_TIPO    = 'PA' "
cQuery += 		" AND B1.B1_I_WFUM  <> ' ' "
cQuery += 		" AND B1.B1_MSBLQL  <> '1' "
cQuery += 		" GROUP BY D3.D3_FILIAL, D3.D3_COD, D3.D3_UM, D3.D3_SEGUM ) DADOS "
cQuery += " GROUP BY DADOS.FILIAL, DADOS.PRODUTO, DADOS.UM, DADOS.SEGUM "
cQuery += " ORDER BY FILIAL, PRODUTO "

If ValType(oproc) = "O"
   oproc:cCaption := 'Consulta os dados de Saidas normais'
   ProcessMessages()
EndIf
u_itconout( 'Consulta os dados de Saidas normais' )

If Select(cAlias) > 0
	(cAlias)->(DBCloseArea())
EndIf

dbUseArea( .T., "TOPCONN",TcGenQry(,,cQuery),cAlias,.T.,.F.)  
                               
DBSelectArea(cAlias)
(cAlias)->(DBGoTop())	
	
While (cAlias)->(!Eof())	                     
    
	nPosSai := aScan(_aDados,{|x| AllTrim(x[1])+AllTrim(x[3]) == AllTrim((cAlias)->filial)+AllTrim((cAlias)->produto) })
	
	If nPosSai > 0
	    
	    // Verifica qual unidade de medida eh usada no workflow
		If _aDados[nPosSai,20] == "N"
	    	_aDados[nPosSai,7] += IIf( _nQtdMin > (cAlias)->quant   , 0 , (cAlias)->quant   )
	    ElseIf _aDados[nPosSai,20] == "S"
	        _aDados[nPosSai,7] += IIf( _nQtdMin > (cAlias)->qtsegum , 0 , (cAlias)->qtsegum )
	    EndIf
	    
	EndIf

(cAlias)->( DBSkip() )
EndDo

(cAlias)->( DBCloseArea() )

// Query que retorna os dados dos pedidos pendentes
cQuery := " SELECT "
cQuery += 	" C6.C6_FILIAL      AS FILIAL, "
cQuery += 	" C6.C6_PRODUTO     AS PRODUTO, "
cQuery += 	" SUM(C6.C6_QTDVEN) AS QUANT, "
cQuery += 	" C6.C6_UM          AS UM, "
cQuery += 	" SUM(C6.C6_UNSVEN) AS QTSEGUM, "
cQuery += 	" C6.C6_SEGUM       AS SEGUM "
cQuery += " FROM "+ RetSqlName("SC6") +" C6 "
cQuery += " JOIN "+ RetSqlName("SC5") +" C5 ON C6.C6_NUM     = C5.C5_NUM AND C6.C6_FILIAL = C5.C5_FILIAL "
cQuery += " JOIN "+ RetSqlName("SB1") +" B1 ON C6.C6_PRODUTO = B1.B1_COD "
cQuery += " WHERE "
cQuery +=     " C5.D_E_L_E_T_ = ' ' "
cQuery += " AND C6.D_E_L_E_T_ = ' ' "
cQuery += " AND B1.D_E_L_E_T_ = ' ' "
cQuery += " AND C5.C5_FILIAL  IN "+ FormatIn(_cFilial,"/")
cQuery += " AND C5.C5_NOTA    = ' ' "
cQuery += " AND B1.B1_TIPO    = 'PA' "
cQuery += " AND B1.B1_I_WFUM  <> ' ' "
cQuery += "	AND B1.B1_MSBLQL  <> '1' "    
cQuery += " AND C6.C6_CF      IN "+ FormatIn(cCfops,";")
cQuery += " GROUP BY C6.C6_FILIAL, C6.C6_PRODUTO, C6.C6_UM, C6.C6_SEGUM "
cQuery += " ORDER BY FILIAL, PRODUTO "

If ValType(oproc) = "O"
   oproc:cCaption := 'Consulta os dados de Pedidos Pendentes'
   ProcessMessages()
EndIf
u_itconout( 'Consulta os dados de Pedidos Pendentes' )

If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T., "TOPCONN",TcGenQry(,,cQuery),cAlias,.T.,.F.)  
                               
DBSelectArea(cAlias)
(cAlias)->(DBGoTop())
	
While (cAlias)->(!Eof())	                     
	    
	nPosPed:=aScan(_aDados,{|x| AllTrim(x[1])+AllTrim(x[3]) == AllTrim((cAlias)->filial)+AllTrim((cAlias)->produto) })

	If nPosPed > 0
	
		// Verifica qual unidade de medida eh usada no workflow
		If _aDados[nPosPed,20] == "N"
			_aDados[nPosPed,09]	+= IIf( _nQtdMin > (cAlias)->QUANT   , 0 , (cAlias)->QUANT   )
	    	_aDados[nPosPed,10]	:= (cAlias)->UM
	    ElseIf _aDados[nPosPed,20] == "S"
	    	_aDados[nPosPed,09]	+= IIf( _nQtdMin > (cAlias)->QTSEGUM , 0 , (cAlias)->QTSEGUM )
	    	_aDados[nPosPed,10]	:= (cAlias)->SEGUM
	    EndIf	        
    
	EndIf                                                                                                     
	        
(cAlias)->( DBSkip() )
EndDo

(cAlias)->( DBCloseArea() )

// Query que retorna os dados das expedições do dia anterior
cQuery := " SELECT "
cQuery += 	" D2.D2_FILIAL       AS FILIAL ,"
cQuery += 	" D2.D2_COD          AS PRODUTO,"
cQuery += 	" SUM(D2.D2_QUANT)   AS QUANT  ,"
cQuery += 	" D2.D2_UM           AS UM     ,"
cQuery += 	" SUM(D2.D2_QTSEGUM) AS QTSEGUM,"
cQuery += 	" D2.D2_SEGUM        AS SEGUM   "
cQuery += " FROM "+ RetSqlName("SD2") +" D2 " 
cQuery += " JOIN "+ RetSqlName("SF2") +" F2 ON D2.D2_FILIAL = F2.F2_FILIAL AND D2.D2_DOC = F2.F2_DOC AND D2.D2_SERIE = F2.F2_SERIE "
cQuery += " JOIN "+ RetSqlName("SF4") +" F4 ON D2.D2_FILIAL = F4.F4_FILIAL AND D2.D2_TES = F4.F4_CODIGO "
cQuery += " JOIN "+ RetSqlName("SB1") +" B1 ON D2.D2_COD    = B1.B1_COD "
cQuery += " WHERE "
cQuery +=     " D2.D_E_L_E_T_ = ' ' "
cQuery += " AND F4.D_E_L_E_T_ = ' ' "
cQuery += " AND B1.D_E_L_E_T_ = ' ' "
cQuery += " AND F2.D_E_L_E_T_ = ' ' "
cQuery += " AND F2.F2_CARGA   <> ' ' "
cQuery += " AND F4.F4_ESTOQUE = 'S' "
cQuery += " AND B1.B1_TIPO    = 'PA' "
cQuery += " AND B1.B1_I_WFUM  <> ' ' "
cQuery += "	AND B1.B1_MSBLQL  <> '1' "
cQuery += " AND D2.D2_FILIAL  IN "+ FormatIn(_cFilial,"/")
cQuery += " AND D2.D2_EMISSAO = '"+ DToS((DDATABASE-1)) +"' "
cQuery += " GROUP BY D2.D2_FILIAL, D2.D2_COD, D2.D2_UM, D2.D2_SEGUM "
cQuery += " ORDER BY FILIAL, PRODUTO "

If ValType(oproc) = "O"
   oproc:cCaption := 'Consulta os dados da expedição do dia anterior'
   ProcessMessages()
EndIf
u_itconout( 'Consulta os dados da expedição do dia anterior' )

If Select(cAlias) > 0
	(cAlias)->(DBCloseArea())
EndIf

dbUseArea( .T., "TOPCONN",TcGenQry(,,cQuery),cAlias,.T.,.F.)  
                               
DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )

u_itconout( 'Gravando os dados da expedição do dia anterior' )

While (cAlias)->(!Eof())

	nPosExp := aScan( _aDados , {|x| AllTrim(x[1]) + AllTrim(x[3]) == AllTrim( (cAlias)->filial ) + AllTrim( (cAlias)->produto ) } )
	
	If nPosExp > 0
	
		If _aDados[nPosExp,20] == "N"
		
	    	_aDados[nPosExp,11]	+= (cAlias)->QUANT
	    	_aDados[nPosExp,12]	:= (cAlias)->UM
		
	    ElseIf _aDados[nPosExp,20] == "S"
		
	       	_aDados[nPosExp,11]	+= (cAlias)->QTSEGUM
	       	_aDados[nPosExp,12]	:= (cAlias)->SEGUM
		
	    EndIf

	EndIf                                                                                                     
	    
(cAlias)->( DBSkip() )
EndDo

(cAlias)->(DBCloseArea()) 
	
// Query que retorna os dados da produção do dia anterior
cQuery := " SELECT "
cQuery += 	" D3.D3_FILIAL       AS FILIAL, "
cQuery += 	" D3.D3_COD          AS PRODUTO, "
cQuery += 	" B1.B1_I_DESCD      AS DESCPRODUT, "
cQuery += 	" SUM(D3.D3_QUANT)   AS QUANT, "
cQuery += 	" D3.D3_UM           AS UM, "
cQuery += 	" SUM(D3.D3_QTSEGUM) AS QTSEGUM, "
cQuery += 	" D3.D3_SEGUM        AS SEGUM "
cQuery += " FROM "+ RetSqlName("SD3") +" D3 "
cQuery += " JOIN "+ RetSqlName("SB1") +" B1 ON B1.B1_COD = D3.D3_COD "
cQuery += " WHERE "
cQuery +=     " D3.D_E_L_E_T_ = ' ' "
cQuery += " AND B1.D_E_L_E_T_ = ' ' "
cQuery += " AND D3.D3_FILIAL  IN "+ FormatIn(_cFilial,"/")
cQuery += " AND D3.D3_TIPO    = 'PA' "
cQuery += " AND B1.B1_I_WFUM  <> ' ' "
cQuery += "	AND B1.B1_MSBLQL  <> '1' "   
cQuery += " AND D3.D3_EMISSAO = '"+ DToS((DDATABASE-1)) +"' "
cQuery += " AND D3.D3_TM      IN ('001','003','004') "
cQuery += " AND D3.D3_ESTORNO <> 'S' "
cQuery += " GROUP BY D3.D3_FILIAL, D3.D3_COD, B1.B1_I_DESCD, D3.D3_UM, D3.D3_SEGUM "  
cQuery += " ORDER BY FILIAL, PRODUTO "

If ValType(oproc) = "O"
   oproc:cCaption := 'Consulta os dados da Produção do dia anterior'
   ProcessMessages()
EndIf
u_itconout( 'Consulta os dados da Produção do dia anterior' )

If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , cAlias , .T. , .F. )

DBSelectArea( cAlias )
(cAlias)->( DBGoTop() )

u_itconout( 'Consulta os dados da Produção do dia anterior' )

While (cAlias)->(!Eof())
	    
	nPosPda := aScan( _aDados , {|x| AllTrim(x[1]) + AllTrim(x[3]) == AllTrim((cAlias)->filial) + AllTrim((cAlias)->produto) } )
	
	If nPosPda > 0
	    
		If _aDados[nPosPda,20] == "N"
		        
	    	_aDados[nPosPda,13]	+= (cAlias)->QUANT                                                                                                      
	       	_aDados[nPosPda,14]	:= (cAlias)->UM
		    	    
	    ElseIf _aDados[nPosPda,20] == "S"
		    	     
	       	_aDados[nPosPda,13]	+= (cAlias)->QTSEGUM
	       	_aDados[nPosPda,14]	:= (cAlias)->SEGUM
		    	    
	    EndIf
	    
	EndIf                                                                                                     
	
(cAlias)->( DBSkip() )
EndDo

(cAlias)->( DBCloseArea() )

// Query que retorna os dados dos preços médios dos pedidos pendentes
cQuery := " SELECT " 
cQuery += 	" C6.C6_FILIAL FILIAL, "
cQuery += 	" C6.C6_PRODUTO PRODUTO, "
cQuery += 	" C6.C6_UM UM, " 
cQuery += 	" SUM(C6.C6_QTDVEN) QUANT, "
cQuery += 	" SUM(C6.C6_VALOR*(1-(C6.C6_I_PDESC/100))) VALOR "
cQuery += " FROM "+ RetSqlName("SC6") +" C6 "
cQuery += " JOIN "+ RetSqlName("SC5") +" C5 ON C6.C6_NUM     = C5.C5_NUM AND C6.C6_FILIAL = C5.C5_FILIAL "
cQuery += " JOIN "+ RetSqlName("SB1") +" B1 ON C6.C6_PRODUTO = B1.B1_COD "
cQuery += " WHERE "
cQuery +=     " C5.D_E_L_E_T_ = ' ' "
cQuery += " AND C6.D_E_L_E_T_ = ' ' "
cQuery += " AND B1.D_E_L_E_T_ = ' ' "
cQuery += " AND C6.C6_FILIAL  IN "+ FormatIn(_cFilial,"/")
cQuery += " AND C5.C5_I_DTENT <= '"+DToS(DDATABASE+30)+"' " 
cQuery += " AND C5.C5_NOTA    = ' ' "
cQuery += " AND B1.B1_TIPO    = 'PA' "
cQuery += " AND B1.B1_I_WFUM  <> ' ' " 
cQuery += "	AND B1.B1_MSBLQL  <> '1' "  
cQuery += " AND C6.C6_CF      IN "+ FormatIn(cCfops,";")
cQuery += " GROUP BY C6.C6_FILIAL, C6.C6_PRODUTO, C6.C6_UM "
cQuery += " ORDER BY FILIAL, PRODUTO "

If ValType(oproc) = "O"
   oproc:cCaption := 'Consulta os dados do preço médio dos pedidos de venda'
   ProcessMessages()
EndIf
u_itconout( 'Consulta os dados do preço médio dos pedidos de venda' )

If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , cAlias , .T. , .F. )

DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )

u_itconout( 'Gravação dos dados do preço médio dos pedidos de venda' )

While (cAlias)->(!Eof())

	nPosPP := aScan( _aDados , {|x| AllTrim(x[1]) + AllTrim(x[3]) == AllTrim((cAlias)->filial) + AllTrim((cAlias)->produto) } )
    
    If nPosPP > 0
        
    	_aDados[nPosPP,16]	:= (cAlias)->QUANT
    	_aDados[nPosPP,17]	:= (cAlias)->VALOR
	
	EndIf

(cAlias)->( DBSkip() )
EndDo

(cAlias)->( DBCloseArea() )

// Query que retorna os dados dos preços médios faturados
cQuery := " SELECT " 
cQuery +=	" DADOS.FILIAL     AS FILIAL, "
cQuery +=	" DADOS.PRODUTO    AS PRODUTO, "
cQuery +=	" DADOS.UM         AS UM, "
cQuery +=	" SUM(DADOS.QUANT) AS QUANT, "
cQuery +=	" SUM(DADOS.VALOR) AS VALOR "
cQuery += " FROM ( "
cQuery +=			" SELECT "
cQuery +=				" F2.F2_FILIAL AS FILIAL, "
cQuery +=				" B1.B1_COD    AS PRODUTO, "
cQuery +=				" D2.D2_UM     AS UM, "
cQuery +=				" COALESCE( SUM( D2.D2_QUANT - RESULTD1.QUANT1UM ) , 0 ) QUANT, "
cQuery +=				" COALESCE( SUM( ( D2.D2_TOTAL - RESULTD1.VLRTOT ) - ( ( D2.D2_VALBRUT - RESULTD1.VLRBRT ) * ( D2_I_PRCDC / 100 ) ) ) , 0 ) VALOR "
cQuery +=				" FROM "+ RetSqlName("SF2") +" F2 "
cQuery +=				" JOIN "+ RetSqlName("SD2") +" D2 "
cQuery +=				" ON  F2.F2_FILIAL     = D2.D2_FILIAL "
cQuery +=				" AND F2.F2_DOC        = D2.D2_DOC "
cQuery +=				" AND F2.F2_SERIE      = D2.D2_SERIE "
cQuery +=				" AND F2.F2_CLIENTE    = D2.D2_CLIENTE "
cQuery +=				" AND F2.F2_LOJA       = D2.D2_LOJA "
cQuery +=				" JOIN "+ RetSqlName("SB1") +" B1 "
cQuery +=				" ON B1.B1_COD = D2.D2_COD, "
cQuery +=				" (  SELECT "
cQuery +=					" D1.D1_FILIAL, "
cQuery +=					" D1.D1_NFORI, "
cQuery +=					" D1.D1_SERIORI, "
cQuery +=					" D1.D1_FORNECE, "
cQuery +=					" D1.D1_LOJA, "
cQuery +=					" D1.D1_COD, "
cQuery +=					" COALESCE(SUM(D1.D1_QUANT),0) QUANT1UM, "
cQuery +=					" COALESCE(SUM(D1.D1_TOTAL),0) VLRTOT, "
cQuery +=					" COALESCE(SUM(D1.D1_TOTAL + D1.D1_ICMSRET),0) VLRBRT "
cQuery +=				" FROM "+ RetSqlName("SD1") +" D1 "
cQuery +=				" WHERE D1.D_E_L_E_T_ = ' ' "
cQuery +=				" AND D1.D1_TIPO      = 'D' "
cQuery +=				" GROUP BY D1.D1_FILIAL, D1.D1_NFORI, D1.D1_SERIORI, D1.D1_FORNECE, D1.D1_LOJA, D1.D1_COD ) RESULTD1 "
cQuery +=			" WHERE "
cQuery +=				" F2.D_E_L_E_T_ = ' ' "
cQuery +=			" AND D2.D_E_L_E_T_ = ' ' "
cQuery +=			" AND B1.D_E_L_E_T_ = ' ' "
cQuery +=			" AND D2.D2_FILIAL  IN "+ FormatIn(_cFilial,"/")
cQuery +=			" AND D2.D2_EMISSAO BETWEEN '"+ DToS(FirstDay(DDATABASE)) +"' AND '"+ DToS(DDATABASE-1) +"' "
cQuery +=			" AND D2.D2_CF      IN "+ FormatIn(cCfops,";")
cQuery +=			" AND ( B1.B1_TIPO   = 'PA'  OR ( B1.B1_TIPO = 'PP' AND B1.B1_I_SUBGR IN ('023','028') ) OR B1_COD IN " + FormatIn(_cListaCod,",") + " ) "
cQuery +=			" AND B1.B1_I_WFUM  <> ' ' "   
cQuery +=			" AND B1.B1_MSBLQL  <> '1' "  
cQuery +=			" AND RESULTD1.D1_FILIAL  = D2.D2_FILIAL "
cQuery +=			" AND RESULTD1.D1_NFORI   = D2.D2_DOC "
cQuery +=			" AND RESULTD1.D1_SERIORI = D2.D2_SERIE "
cQuery +=			" AND RESULTD1.D1_FORNECE = D2.D2_CLIENTE "
cQuery +=			" AND RESULTD1.D1_LOJA    = D2.D2_LOJA "
cQuery +=			" AND RESULTD1.D1_COD     = D2.D2_COD "
cQuery +=			" GROUP BY F2.F2_FILIAL, B1.B1_COD, D2.D2_UM, D2.D2_SEGUM "
cQuery +=			" HAVING SUM(D2.D2_QUANT - RESULTD1.QUANT1UM) > 0 "

cQuery +=			" UNION ALL "

cQuery += 			" SELECT "
cQuery +=				" F2.F2_FILIAL FILIAL, "
cQuery +=				" B1.B1_COD PRODUTO, "
cQuery +=				" D2.D2_UM UM, "
cQuery +=				" SUM(D2.D2_QUANT) QUANT, "
cQuery +=				" SUM(D2.D2_TOTAL - D2.D2_I_VLRDC) VALOR "
cQuery +=			" FROM "+ RetSqlName("SF2") +" F2 "
cQuery +=			" JOIN "+ RetSqlName("SD2") +" D2 "
cQuery +=			" ON "
cQuery +=				" F2.F2_FILIAL     = D2.D2_FILIAL "
cQuery +=			" AND F2.F2_DOC        = D2.D2_DOC "
cQuery +=			" AND F2.F2_SERIE      = D2.D2_SERIE "
cQuery +=			" AND F2.F2_CLIENTE    = D2.D2_CLIENTE "
cQuery +=			" AND F2.F2_LOJA       = D2.D2_LOJA "
cQuery +=			" JOIN "+ RetSqlName("SB1") +" B1 "
cQuery +=			" ON "
cQuery +=				" B1.B1_COD = D2.D2_COD "
cQuery +=			" WHERE "
cQuery +=				" F2.D_E_L_E_T_ = ' ' "
cQuery +=			" AND D2.D_E_L_E_T_ = ' ' "
cQuery +=			" AND B1.D_E_L_E_T_ = ' ' "
cQuery +=			" AND D2.D2_FILIAL  IN "+ FormatIn(_cFilial,"/")
cQuery +=			" AND D2.D2_EMISSAO BETWEEN '"+DToS(FirstDay(DDATABASE))+"' AND '"+DToS(DDATABASE-1)+"' "
cQuery +=			" AND D2.D2_CF      IN "+ FormatIn(cCfops,";")
cQuery +=			" AND ( B1.B1_TIPO   = 'PA'  OR ( B1.B1_TIPO = 'PP' AND B1.B1_I_SUBGR IN ('023','028') ) OR B1_COD IN " + FormatIn(_cListaCod,",") + " ) "
cQuery +=			" AND B1.B1_I_WFUM  <> ' ' "
cQuery +=			" AND B1.B1_MSBLQL  <> '1' "   
cQuery +=			" AND NOT EXISTS (    SELECT 1 "
cQuery +=								" FROM " + RetSqlName("SD1") + " D1 "
cQuery +=								" WHERE "
cQuery +=									" D1.D_E_L_E_T_ = ' ' "
cQuery +=								" AND D1.D1_TIPO    = 'D' "
cQuery +=								" AND D1.D1_FILIAL  = D2.D2_FILIAL "
cQuery +=								" AND D1.D1_NFORI   = D2.D2_DOC "
cQuery +=								" AND D1.D1_SERIORI = D2.D2_SERIE "
cQuery +=								" AND D1.D1_FORNECE = D2.D2_CLIENTE "
cQuery +=								" AND D1.D1_LOJA    = D2.D2_LOJA "
cQuery +=								" AND D1.D1_COD     = D2.D2_COD ) "
cQuery +=			" GROUP BY F2.F2_FILIAL, B1.B1_COD, D2.D2_UM "
cQuery += " ) DADOS "
cQuery += " GROUP BY DADOS.FILIAL, DADOS.PRODUTO, DADOS.UM "
cQuery += " ORDER BY FILIAL, PRODUTO "

If ValType(oproc) = "O"
   oproc:cCaption := 'Consulta dos dados do preço médio faturado'
   ProcessMessages()
EndIf
u_itconout( 'Consulta dos dados do preço médio faturado' )

If Select(cAlias) > 0
	(cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , cAlias , .T. , .F. )

DBSelectArea(cAlias)
(cAlias)->(DBGoTop())

u_itconout( 'Gravação dos dados do preço médio faturado' )
	
While (cAlias)->(!Eof())
	    
	nPosPF:=aScan(_aDados,{|x| AllTrim(x[1])+AllTrim(x[3]) == AllTrim((cAlias)->filial)+AllTrim((cAlias)->produto) })
    
    If nPosPF > 0
        
    	_aDados[nPosPF,18] := (cAlias)->QUANT
    	_aDados[nPosPF,19] := (cAlias)->VALOR
	              
	EndIf
	
(cAlias)->( DBSkip() )
EndDo

(cAlias)->( DBCloseArea() )

// Calcula saldos anteriores dos produtos
If ValType(oproc) = "O"
   oproc:cCaption := 'Calcula saldo anterior dos produtos'
   ProcessMessages()
EndIf
u_itconout( 'Calcula saldo anterior dos produtos' )

For x := 1 To Len(_aDados)
	
	//Calcula Saldo Anterior
	//Parametros da funcao calcEst
	//1 - Codigo do Produto
	//2 - Lote Padrao
	//3 - Data para verificao
	//4 - Filial
	
	// Calcula saldos anteriores dos produtos
	If ValType(oproc) = "O"
		oproc:cCaption := 'Calcula saldo anterior dos produtos ' + StrZero(x,6) + " de " + StrZero(Len(_aDados),6)
		ProcessMessages()
	EndIf
	u_itconout( 'Calcula saldo anterior dos produtos ' + StrZero(x,6) + " de " + StrZero(Len(_aDados),6) )
	
	
	For nArm := 1 To Len(_aArm)
		
		_cfil := cfilant
		cfilant := AllTrim(_aDados[x,1])
		
		SM0->(DBSetOrder(1))
		SM0->(DBSeek('01' + AllTrim(_aDados[x,1]))) 
		
		aSaldo := CalcEst( _aDados[x,3] , _aArm[nArm] , DDATABASE , AllTrim(_aDados[x,1]) )
		
		cfilant := _cfil
		SM0->(DBSetOrder(1))
		SM0->(DBSeek('01' + _cfil))
		
		// Verifica se houve troca de unidade de medida para gravacao do saldo anterior no array _aDados
		If _aDados[x,20] == "N"
		              
			_aDados[x,5] += aSaldo[1]
		
		ElseIf _aDados[x,20] == "S"
		
			_aDados[x,5] += aSaldo[7]
		
		EndIf
		
	Next nArm

Next x

_aDados := aSort( _aDados ,,, {|x, y| x[1] < y[1] , x[2] < y[2] , x[3] < y[3] } )

u_itconout( 'Finalizando o processamento dos dados...' )

Return( _aDados )

/*
===============================================================================================================================
Programa----------: MOMS021SUB
Autor-------------: Guilherme Diogo
Data da Criacao---: 26/09/2012
Descrição---------: Funcao desenvolvida para buscar e estruturar os dados de SubGrupos de Produtos
Parametros--------: _cFilial - Filial a ser considerada
------------------: _aSubGr  - Array contendo os SubGrupos de produtos
Retorno-----------: _aSubGr  - Array contendo os SubGrupos de produtos
===============================================================================================================================
*/
Static Function MOMS021SUB( _cFilial )

Local _cQuery	:= "" 
Local cAlias	:= GetNextAlias() 
Local _aFilial	:= StrTokArr( _cFilial , "/" )
Local _aSubGr	:= {}
Local _nX		:= 0
 
// Query que retorna todos os Sub-Grupos
_cQuery := " SELECT "
_cQuery += " 	ZB9_SUBGRU AS COD, "
_cQuery += " 	ZB9_DESSUB AS DESCR "
_cQuery += " FROM "+ RetSqlName("ZB9")
_cQuery += " WHERE D_E_L_E_T_ = ' ' "
_cQuery += " ORDER BY COD "

u_itconout( 'Leitura dos dados dos Sub-Grupos' )

If Select(cAlias) > 0
	(cAlias)->(DBCloseArea())
EndIf

dbUseArea( .T., "TOPCONN",TcGenQry(,,_cQuery),cAlias,.T.,.F.)  
	
DBSelectArea(cAlias)
(cAlias)->(DBGoTop())

u_itconout( 'Gravação dos dados dos Sub-Grupos' )

While (cAlias)->( !Eof() )

	For _nX := 1 To Len(_aFilial)
	
		aAdd( _aSubGr , { _aFilial[_nX] , (cAlias)->COD , (cAlias)->DESCR } )
		
	Next _nX

(cAlias)->( DBSkip() )
EndDo

DBSelectArea(cAlias)
(cAlias)->( DBCloseArea() )

u_itconout( 'Fim da Gravação dos dados dos Sub-Grupos' )

Return( _aSubGr )

/*
===============================================================================================================================
Programa----------: MOMS021TER
Autor-------------: Alexandre Villar
Data da Criacao---: 14/05/2015
Descrição---------: Verifica e retorna o saldo de protudos em poder de terceiros
Parametros--------: _cFilTer - Filial a ser considerada
------------------: _cCodPrd - Código do produto a ser verificado
------------------: _cTrcUM  - Identifica se deve trocar a unidade de medida
Retorno-----------: _nQtd    - Quantidade de produto em poder de terceiros
===============================================================================================================================
*/
Static Function MOMS021TER( _cFilTer , _cCodPrd , _cTrcUM )

Local _nQtd		:= 0
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()

_cQuery := " SELECT "
_cQuery += "     SB6.B6_FILIAL, "
_cQuery += "     SB6.B6_PRODUTO, "
_cQuery += "     SUM( SB6.B6_SALDO ) AS SALDO_1UM, "
_cQuery += "     Case WHEN SB1.B1_TIPCONV = 'D' AND SB1.B1_CONV > 0 THEN SUM(SB6.B6_SALDO)/SB1.B1_CONV Else SUM(SB6.B6_SALDO) * SB1.B1_CONV END AS SALDO_2UM "
_cQuery += " FROM "+ RetSqlName('SB6') +" SB6 "
_cQuery += " JOIN "+ RetSqlName('SB1') +" SB1 ON SB1.B1_COD = SB6.B6_PRODUTO "
_cQuery += " WHERE "
_cQuery += "     SB6.D_E_L_E_T_ = ' ' "
_cQuery += " AND SB1.D_E_L_E_T_ = ' ' "
If !Empty(_cFilTer)
   _cQuery += " AND SB6.B6_FILIAL  = '"+ _cFilTer +"' "
EndIf
_cQuery += " AND SB6.B6_PRODUTO = '"+ _cCodPrd +"' "
_cQuery += " AND SB6.B6_TPCF    = 'F' "
_cQuery += " GROUP BY B6_FILIAL , B6_PRODUTO , SB1.B1_TIPCONV , SB1.B1_CONV "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() ) .And. (_cAlias)->SALDO_1UM > 0
	
	If _cTrcUM == 'N'
		_nQtd := (_cAlias)->SALDO_1UM
	Else
		_nQtd := (_cAlias)->SALDO_2UM
	EndIf
	
EndIf

(_cAlias)->( DBCloseArea() )

Return( _nQtd )

/*
===============================================================================================================================
Programa----------: MOMS021W
Autor-------------: Josué Danich Prestes
Data da Criacao---: 12/09/2016
Descrição---------: WebService de execução do workflow
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
WSSTRUCT U_MOMS021G //Solicitação de execução do workflow
 
 WSDATA EXECUTA as STRING 
 
ENDWSSTRUCT

WSSERVICE U_MOMS021 DESCRIPTION "WebService Workflow Pedidos x Carteira" NAMESPACE "http://10.60.1.4:11726/ws/U_MOMS021.apw"

	WSDATA U_EXECUTA AS U_MOMS021G
	WSDATA U_STATUS AS STRING
	
	WSMETHOD U_EXECWF DESCRIPTION "Workflow Pedidos x Carteiras"
 
ENDWSSERVICE 

WSMETHOD U_EXECWF WSRECEIVE U_EXECUTA WSSEND U_STATUS WSSERVICE U_MOMS021  

	startjob("U_MOMS021",getenvserver(),.F.)
	u_itconout("Iniciada execução de  Pedidos x Carteira via webservice")
	::U_STATUS := "Iniciada execução de workfow Pedidos x Carteira via webservice"

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS021Y
Autor-------------: Josué Danich Prestes
Data da Criacao---: 12/09/2016
Descrição---------: Chamada de workflow via webservice 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS021Y()

  _cEndereco:=SuperGetMV("IT_WEBLNK",.T.,"http://10.7.0.55:1026/ws/")

  u_itconout("Solicitando Webservice de WorkFlow de Pedidos x Carteira")

   oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.
   oWsdl:nTimeout := 60          // Timeout de 10 segundos                                                               
   
   oWsdl:ParseURL(_cEndereco+"U_MOMS021.apw?WSDL") // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. 
   oWsdl:SetOperation("U_EXECWF") // Define qual operação será realizada.
                       
      //Monta XML
      _cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:u="'+_cEndereco+'U_MOMS021.apw">'
      _cXML += '<soapenv:Header/><soapenv:Body><u:U_EXECWF><u:U_EXECUTA><u:EXECUTA>teste</u:EXECUTA></u:U_EXECUTA></u:U_EXECWF></soapenv:Body></soapenv:Envelope>'
  		    
      // Envia para o servidor
      _cOk := oWsdl:SendSoapMsg(_cXML) // Este comando pega o XML e envia para o servidor da RDC.  
            
Return
