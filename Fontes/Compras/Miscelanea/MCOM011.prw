/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |13/11/2020| Chamado 34667. Ajustes no controle de Transação p/ cada linha.
Alex Wallauer |10/01/2023| Chamado 42485. Alteracao no calculo do campo ZZH_VALOR.
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MCOM011
Autor-----------: Alex Wallauer
Data da Criacao-: 27/06/2019
Descrição-------: Rotina de reprocessamento de tabela ZZH a partir de pedidos de compra - Chamado 29776
Parametros------: NENHUM
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function MCOM011()

Local cTimeInicial:=Time()
Local _aParRet :={}
Local _aParAux :={} , nI 
Local _bOK     :={|| If(MV_PAR02 >= MV_PAR01 .Or. MV_PAR02 > DATE(),.T.,(U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo ate a data de hoje",3),.F.) ) }


Private _lTela   := .T.	                 
Private aLog := {}
                                   	
//Testa se esta sendo rodado do menu
If	Select('SX3') == 0

	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MCOM011"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM01101"/*cMsgId*/, "MCOM01101 - Gerando ZZH..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

	RPCSetType( 3 )						//Não consome licensa de uso
	RpcSetEnv('01','01',,,,GetEnvServer(),{ "SC7","ZZH" })
	sleep( 5000 )						//Aguarda 5 segundos para que as jobs IPC subam.
	_lTela := .F.

    MV_PAR01:=CTOD("01/01/2000")
    MV_PAR02:=CTOD("31/12/2049")
    MV_PAR03:=2//Efetivar
    MV_PAR04:=2//Somente PC sem ZZH

Else

    MV_PAR01:=dDataBase
    MV_PAR02:=dDataBase
    MV_PAR03:=1
    MV_PAR04:=1

    aAdd( _aParAux , { 1 , "Data de:"	, MV_PAR01, "@D"	, ""	, ""		, "" , 050 , .F. } )
    aAdd( _aParAux , { 1 , "Data ate:"	, MV_PAR02, "@D"	, ""	, ""		, "" , 050 , .F. } )
    aAdd( _aParAux , { 3 , "Tipo Processamento", MV_PAR03, {"Analise","Efetivar"}, 40, "", .T., .T. , .T. } )
    aAdd( _aParAux , { 3 , "Somente PC sem ZZH", MV_PAR04, {"Sim","Nao"}         , 40, "", .T., .T. , .T. } )

    For nI := 1 To Len( _aParAux )
	    aAdd( _aParRet , _aParAux[nI][03] )
    Next nI

    If !ParamBox( _aParAux , "Intervalo de Datas" , @_aParRet, _bOK )
		Return .F.
    EndIf

EndIf

cTimeInicial:=Time()
_lEfetivar:=(MV_PAR03 = 2)
_lQqPC    :=(MV_PAR04 = 2)
lRet:=.T.
_nOK:=0
_nErro:=0

If _lTela
    FWMsgRun( ,{|oProc|  lRet:=CORRZZHP(oProc) } , "Hora Inicial: "+cTimeInicial+" Lendo: "+DToC(MV_PAR01)+", Ate "+DToC(MV_PAR02) )
	If !lRet
	   Return .T.
	EndIf

    If Len(aLog) > 0
	   cTitulo:="Quantidade de Registros: "+AllTrim(Str(_nOK))+" OK / "+AllTrim(Str(_nErro))+" Ocorrencias / Hora Inicial: "+cTimeInicial+" - Hora Final: "+Time()
	   U_ITListBox( 'Log de Atualizacao da ZZH (MCOM011)' ,;
	                     {'','Filial','Pedido','Item','Condicao','Data','Valor','Prop.','Observacao'},aLog,.T.,4,cTitulo,,;
	                     {15,      25,      35,   40,         25,   35 ,     55,     20,     150} )
    Else
	   U_ITMsg("Nao foi encontrado dados para essa selecao","Atencao!",,1)
    EndIf

Else
	//Atualização tabela SM2
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MCOM011"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM01102"/*cMsgId*/, "MCOM01102 - INICIO DO PROCESSAMENTO - ZZH..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	
    lRet:=CORRZZHP()
	
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MCOM011"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MCOM01103"/*cMsgId*/, "MCOM01103 - FIM DO PROCESSAMENTO - ZZH - Hora Inicial: "+cTimeInicial/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	
    RpcClearEnv()		   				//Libera o Ambiente

EndIf

Return lRet

/*
===============================================================================================================================
Programa----------: CORRZZHP
Autor-------------: Alex Walauer Ferreira
Data da Criacao---: 27/06/2018
Descrição---------: Rotina de reprocessamento da ZZH
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CORRZZHP(OPROC)
Local _nTot := 0
Local _nConta := 0 , _nI
Local _aDadVenc := {}
Default oproc := nil

If oproc <> nil
   oproc:cCaption := ("Lendo pedidos...")
   ProcessMessages()
EndIf

_cQry := " SELECT SC7.R_E_C_N_O_ AS NRECNO FROM " + RetSqlName("SC7") + " SC7 "   
_cQry += " WHERE SC7.D_E_L_E_T_ = ' ' "
If !Empty(MV_PAR01)
   _cQry += " AND C7_EMISSAO >= '"+DToS(MV_PAR01)+"' "
EndIf
If !Empty(MV_PAR02)
   _cQry += " AND C7_EMISSAO <= '"+DToS(MV_PAR02)+"' "
EndIf
_cQry += " AND C7_QUJE <> C7_QUANT "
_cQry += " AND C7_I_DTFAT <> ' ' "
//_cQry += " AND C7_COND NOT IN ('001','969','979','99X','99Y','99Z')    "
If !_lQqPC//Somente PC sem ZZH
   _cQry += " AND C7_RESIDUO <> 'S' "
   _cQry += " AND NOT EXISTS (SELECT 'Y' FROM " + RetSqlName("ZZH") + " ZZH WHERE ZZH.D_E_L_E_T_ = ' ' AND ZZH_FILIAL = C7_FILIAL AND ZZH_PEDIDO = C7_NUM AND ZZH_ITEMPC = C7_ITEM ) "
EndIf   
_cQry += " ORDER BY  C7_FILIAL , C7_NUM "

 If Select("SC7T") > 0
    SC7T->(DBCloseArea())
EndIf
           
 _cQry := ChangeQuery(_cQry) 
DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry), "SC7T", .F., .T.)   

COUNT TO _nTot

If oproc <> nil .And. _nTot > 0
   If !U_ITMsg("Serão processado "+AllTrim(Str(_nTot))+" itens. Continua?",'Atenção!',,3,2,2)
       Return .F.
   EndIf
EndIf

SC7T->(DBGoTop())                           
ZZH->( DBSetOrder(1) )

While !(SC7T->(Eof()))

	SC7->(DBGoTo(SC7T->NRECNO))
	_cPC:=AVKEY(SC7->C7_NUM,"ZZH_PEDIDO")
   	_nConta++
    If oproc <> nil
	   oproc:cCaption := ("Gerando ZZH pedido: "+ SC7->C7_FILIAL + "/" + SC7->C7_NUM+" - "+ StrZero(_nConta,6) + " de " + StrZero(_nTot,6)) 
	   ProcessMessages()
    EndIf
	//         QQ PC   e  EFETIVAR   
    If _lQqPC //.AND. _lEfetivar
   	   If ZZH->( DBSeek(SC7->C7_FILIAL + _cPC + SC7->C7_ITEM ) )
  	      BEGIN TRANSACTION
       	  While ZZH->ZZH_FILIAL+ZZH->ZZH_PEDIDO == SC7->C7_FILIAL+_cPC .And. ZZH->ZZH_ITEMPC == SC7->C7_ITEM

    	    If _lEfetivar
		       aAdd(aLog,{.F.,SC7->C7_FILIAL,SC7->C7_NUM,SC7->C7_ITEM,SC7->C7_COND,ZZH->ZZH_DATA,ZZH->ZZH_VALOR,ZZH->ZZH_PRORP,'Excluido'})
     		   ZZH->(RecLock("ZZH",.F.))
       		   ZZH->(DBDelete())
			Else   
		       aAdd(aLog,{.F.,SC7->C7_FILIAL,SC7->C7_NUM,SC7->C7_ITEM,SC7->C7_COND,ZZH->ZZH_DATA,ZZH->ZZH_VALOR,ZZH->ZZH_PRORP,'Sera Excluido'})
			EndIf	  
            //_nErro++
       		ZZH->(DBSkip())
          EndDo   
  	      END TRANSACTION
   	 	EndIf	
	EndIf
	
	//  SE QQ PC
	If _lQqPC .And. SC7->C7_RESIDUO = 'S'
	   SC7T->(DBSkip())
	   Loop	   
	EndIf
    
	  //  QQ PC E    ANALISAR
    If (_lQqPC .And. !_lEfetivar) .Or. !ZZH->( DBSeek(SC7->C7_FILIAL + _cPC+ SC7->C7_ITEM) )  
       
		_nTOTAL   := ( ( ( (SC7->C7_PRECO * SC7->C7_QUANT )+SC7->C7_VALIPI+SC7->C7_DESPESA) - SC7->C7_VLDESC ) / SC7->C7_QUANT ) * ( SC7->C7_QUANT - SC7->C7_QUJE )
		_aCond	  := Condicao( _nTOTAL , SC7->C7_COND , 0 , SC7->C7_I_DTFAT )
		_ligual   := .T.
		_aDadVenc := {}
        
		If Len( _aCond ) = 0
		   aAdd(aLog,{.F.,SC7->C7_FILIAL,SC7->C7_NUM,SC7->C7_ITEM,SC7->C7_COND,"",ZZH->ZZH_VALOR,0,'Condicao sem parcelas'})
		   _nErro++
        EndIf
		//Arruma datas, proporcionalidade e monta matriz de vencimentos
		For _nI := 1 To Len( _aCond )
	
			_dDtVenc   := DataValida( _aCond[_nI][01] ) //só dias úteis
			_nContarorp:= Round( _aCond[_nI][2]/_nTOTAL , 2 )  //indica proporcionalidade da parcela
 	    
			//se é primeira passagem grava a primeira proporção para comparar com as seeguintes
    		If _nI == 1
 	      
        		_ccondi := _nContarorp
 	      
	 		Else
 	    
	     		If _ccondi != _nContarorp  //compara para ver se tem proporção diferente da primeira
 	      
	        		_ligual := .F.
 	        
	     		EndIf
 	      
			EndIf  
			
			aAdd( _aDadVenc , { _dDtVenc , Round( _aCond[_nI][2] , 2 ), _nContarorp, SC7->C7_ITEM } )
    
		Next _nI
      
    	//verifica se _nContarorp é igual para todas as parcelas
    	// se For deixa zerado para o BI calcular o valor com menor margemd e erro por arredondamento
    	If _ligual
        
    		For _nI := 1 To Len( _aDadVenc )
        
     		    _aDadVenc[_nI][3] := 0'
        
    		Next _nI
        
    	EndIf

    	For _nI := 1 To Len( _aDadVenc ) 

    	    If _lEfetivar .And. _aDadVenc[_nI][2] <> 0
			   BEGIN TRANSACTION
    	    	     ZZH->(RecLock( "ZZH" , .T. ) )
    	    	     ZZH->ZZH_FILIAL := SC7->C7_FILIAL
    	    	     ZZH->ZZH_PEDIDO := SC7->C7_NUM
    	    	     ZZH->ZZH_DATA   := _aDadVenc[_nI][1]
    	    	     ZZH->ZZH_PRORP  := _aDadVenc[_nI][3]  
    	    	     ZZH->ZZH_ITEMPC := _aDadVenc[_nI][4]
    	    	     ZZH->ZZH_VALOR  := _aDadVenc[_nI][2]
    	    	     ZZH->(MSUnLock())
			   END TRANSACTION
			   aAdd(aLog,{.T.,SC7->C7_FILIAL,SC7->C7_NUM,_aDadVenc[_nI][4],SC7->C7_COND,_aDadVenc[_nI][1],_aDadVenc[_nI][2],_aDadVenc[_nI][3] ,'Gravado'})
            Else
    	        If _aDadVenc[_nI][2] <> 0
			       aAdd(aLog,{.T.,SC7->C7_FILIAL,SC7->C7_NUM,_aDadVenc[_nI][4],SC7->C7_COND,_aDadVenc[_nI][1],_aDadVenc[_nI][2],_aDadVenc[_nI][3] ,'Analisado OK'})
				Else   
			       aAdd(aLog,{.F.,SC7->C7_FILIAL,SC7->C7_NUM,_aDadVenc[_nI][4],SC7->C7_COND,_aDadVenc[_nI][1],_aDadVenc[_nI][2],_aDadVenc[_nI][3] ,'Valor ZERADO'})
		           _nErro++
				EndIf
			EndIf 
			
			_nOK++
    	Next 
    
  	EndIf
    
	SC7T->(DBSkip())
	
EndDo

Return .T.
