/*
================================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
================================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
--------------------------------------------------------------------------------------------------------------------------------
 Julio Paz        | 12/07/2018 | Incluir validações, bloquear carga de pedidos vendas bloqueados e sem liberação. Chamado 25479.  
-------------------------------------------------------------------------------------------------------------------------------- 
 Josué Danich     | 04/09/2018 | Ajuste e posição de arrParamIXBramIXB - Chamado 26152 
--------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges     | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
 -------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 01/02/2021 | Remoção de bugs apontados pelo Totvs CodeAnalysis. Chamado: 34262
================================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================

/*
===============================================================================================================================
Programa--------: OM200OK
Autor-----------: Fabiano Dias
Data da Criacao-: 16/06/2010                			
===============================================================================================================================
Descricao-------: Ponto de Entrada executado antes da conclusao da montagem da carga quando o usuario clica no botao ok
					Possibilita efetuar validacoes antes da efetivacao da montagem da carga
===============================================================================================================================
Parametros------: Nenhum  
===============================================================================================================================
Retorno---------: Nenhum  
===============================================================================================================================
*/
User Function OM200OK()

Local _nPosCarga := ParamIXB[3]
Local _aDadoCarg := ParamIXB[2][_nPosCarga]
Local _lRet      := .T.
Local _lPreCarga := .F.
Local _aPedidos  := ParamIXB[01]
Local _aSC5		 := GetArea("SC5") 
Local _alog 	 := {}
Local oproc      := nil

//====================================================================================
//Verifica versão do OMSA200 pois mudou a posição do arrParamIXBramIXB a partir 
// do fontes depois de 06/08/2018 sem documentação no TDN
//====================================================================================
Local aTipo := {}
Local aArquivo := {}
Local aLinha := {}
Local aData := {}
Local aHora := {}
Local _npos := 12 //posição antiga do codigo do motorista
Local _npos2 := 9 //posição antiga do codigo do caminhao

GetFuncArray( "OMSA200", aTipo, aArquivo, aLinha, aData, aHora )

If AARQUIVO[1] == "OMSA200.PRW" .And. ADATA[1] > SToD("20180805")

	_npos := 13 //posicao nova do codigo do motorista
	_npos2 := 10 //posicao nova do codigo do caminhao
	
EndIf

//====================================================================================
//Verifica se o veiculo ou motorista foram informados na opcao veiculo da carga  
//====================================================================================

If Empty(_aDadoCarg[_npos2]) .Or. Empty(_aDadoCarg[_npos])
	        
   If !U_ITMsg("Voce esta fazendo uma Pre-Carga?","Atencao",,2,2,2)	
	   U_ITMsg("Favor informar um veiculo antes de concluir a montagem da carga.","Atenção! (OM200OK)",;
				     "Botão disponivel na montagem da carga em Associar veiculo",1)         
				     
	   _lRet:= .F.
   Else
       _lPreCarga:= .T.
   EndIf
	
EndIf 

//=================================================================
// Valida se existe pedidos de vendas com bloqueio de crédito e 
// de estoque.
//=================================================================
If _lRet
   _lRet := OM200VLD(_aPedidos)
EndIf

//=================================================================
// Analisa crédito dos pedidos selecionados
//=================================================================
If _lRet
	_aRetorno:={.T.,{}}//A variavel do retorno da funcão verpeds() tem que se PRIVATE
	FWMsgRun(,{|oproc| _aRetorno := verpeds(_aPedidos, oproc) }, "Aguarde", "OM200OK - Analisando crédito dos pedidos...")
	_lRet:=_aRetorno[1]
	_aLog:=_aRetorno[2]

	If !_lRet .And. Len(_aLog) > 0
	
		U_ITListBox( 'Relação de Pedidos que não podem montar carga: (OM200OK)' ,;
		             {"Pedido","Cod Cli","Nome do Cliente","Resultado da Analise"} , _aLog , .F. , 1 , 'Resultado da Análise dos pedidos: ',,;
		             {      30,       30,               80,                   200} )

	EndIf

EndIf

	
If _lRet

   _cCaminDAK := _aDadoCarg[_npos2]
   _cMotorDAK := _aDadoCarg[_npos]
   _lRet:=U_OM200Tela(.F.,_lPreCarga)

EndIf

FWRestArea(_aSC5)	

Return If(_lRet,NIL,.F.)//nao pode retornar um valor logico se For .T. pq ele mata a validacao padrao se For .F. //Return _lRet


/*/
===============================================================================================================================
Programa--------: Verpeds
Autor-----------: Josué Danich Prestes
Data da Criacao-: 30/05/2017                			
===============================================================================================================================
Descricao-------: Verifica crédito dos pedidos selecionados
===============================================================================================================================
Parametros------: _aPedidos - Array com pedidos selecionados
				  oproc - objeto de processamento
===============================================================================================================================
Retorno---------: _lRet - Se passaram ou não na análise de crédito 
===============================================================================================================================
/*/
Static Function Verpeds(_aPedidos, oproc)

Local _lRet := .T.
Local _nI   := 1
Local _alog := {}
Local _cChep:= AllTrim(GetMV("IT_CCHEP"))

SA1->(DBSetOrder(1))
SC5->(DBSetOrder(1))
SC6->(DBSetOrder(1))

For _nI := 1 TO Len(_aPedidos)

	oproc:ccaption := ("OM200OK - Analisando Pedido: "+_aPedidos[_nI][5])
    ProcessMessages()

	//Valida crédito do pedido
		If SC5->(DBSeek(_aPedidos[_nI][12]+_aPedidos[_nI][5]))

           If SA1->( DBSeek( xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI ) ) .And. SA1->A1_MSBLQL == '1'
		   	  aAdd(_aLog,{SC5->C5_NUM,SC5->C5_CLIENTE,Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME"),"Cliente Bloqueado"})
              Loop
           EndIf

		   If  SC5->C5_TIPO = 'N' 

		   		_nTotPV:=0
		   		_lValCredito:=.T.
   
		   		SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

		   		While SC6->C6_NUM == SC5->C5_NUM .And. SC5->C5_FILIAL == SC6->C6_FILIAL .And. SC6->(!Eof())
	   
		   			_nTotPV += SC6->C6_VALOR

		   			If SC6->C6_PRODUTO == _cChep .Or. SC6->C6_CF $ '5910/6910/5911/6911'//NÃO VALIDA CRÉDITO PARA PALLET CHEP E PARA BONIFICAÇÃO
		   				_lValCredito:=.F.
		   				Exit
		   			EndIf

		   			If Posicione("SF4",1,xFilial("SF4")+SC6->C6_TES,"F4_DUPLIC") != 'S' //NÃO VALIDA CRÉDITO PARA PEDIDO SEM DUPLICATA
		   				_lValCredito:=.F.
		   				Exit
		   			EndIf
    
		   			If Posicione("ZAY",1,xFilial("ZAY")+ SC6->C6_CF ,"ZAY_TPOPER") != 'V' //NÃO VALIDA CRÉDITO PARA PEDIDO COM CFOP QUE NÃO SEJA DE VENDA
		   				_lValCredito:=.F.
		   				Exit
		   			EndIf
      
		   			SC6->(DBSkip())
  
		   		EndDo

		   		If _lValCredito

		   			_aRetCre := U_ValidaCredito( _nTotPV , SC5->C5_CLIENTE , SC5->C5_LOJACLI , .T. , , , , SC5->C5_MOEDA,,SC5->C5_NUM)
		   			_cBlqCred:=_aRetCre[1]
		   			aAdd(_alog,{SC5->C5_NUM,SC5->C5_CLIENTE,Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME"),_Aretcre[1]})
        	
		   			SC5->(RecLock("SC5",.F.))
	
		   				If _aRetCre[2] = "B"//Se bloqueou
		   						   				
		   					If SC5->C5_I_BLCRE == "R"
  			   		
		   						_lBlq2			:= .F.
		   						SC5->C5_I_BLCRE	:= "R"
		   						SC5->C5_I_DTAVA := Date()
		   						SC5->C5_I_HRAVA := Time()
		   						SC5->C5_I_USRAV := cUserName
		   						SC5->C5_I_MOTBL := _cBlqCred
							
						
		   					Else
						
		   						_lBlq2			:= .F.
		   						SC5->C5_I_BLCRE	:= "B"
		   						SC5->C5_I_DTAVA := Date()
		   						SC5->C5_I_HRAVA := Time()
		   						SC5->C5_I_USRAV := cUserName
		   						SC5->C5_I_MOTBL := _cBlqCred
								
		   					EndIf
		   					
		   					_lRet := .F.  
	
		   				EndIf

		   				SC5->C5_I_MOTBL := _cBlqCred//Sempre grava a descrição
		   				SC5->(MSUnLock())
  
		   		Else
		   		
		   			aAdd(_alog,{SC5->C5_NUM,SC5->C5_CLIENTE,Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME"),"Não necessita de avaliação de crédito"})
		   		
		   		EndIf
		   		
		   		U_ENVSITPV() //Envia interface de situação do pedido para o RDC
  
		   Else

   			  aAdd(_alog,{SC5->C5_NUM,SC5->C5_CLIENTE,Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_NOME"),"Não necessita de avaliação de crédito"})

		   EndIf

		 EndIf
		 
Next

Return {_lRet,_aLog}

/*/
===============================================================================================================================
Programa--------: OM200VLD
Autor-----------: Julio de PAula Paz
Data da Criacao-: 12/07/2018
===============================================================================================================================
Descricao-------: Verifica se existe pedidos de vendas com bloqueio de credito e de estoque.
===============================================================================================================================
Parametros------: _aPedidos = Array com os dados dos pedidos de vendas.
===============================================================================================================================
Retorno---------: _lRet = .T./ .F. 
===============================================================================================================================
/*/
Static Function OM200VLD(_aPedCarga)
Local _lRet := .T.
Local _aOrd := SaveOrd({"SC9"})
Local _nI, _aDadosVld := {}
Local _cMsg

Begin Sequence
   //SC5->(DBSeek(_aPedidos[_nI][12]+_aPedidos[_nI][5])) // ordem 1
   // C9_FILIAL+C9_PEDIDO+C9_ITEM+C9_SEQUEN+C9_PRODUTO+C9_BLEST+C9_BLCRED                                                                                             
   SC9->(DBSetOrder(1))
   
   For _nI := 1 To Len(_aPedCarga)
       _cMsg := ""
       If SC9->(DBSeek(_aPedCarga[_nI][12]+_aPedCargas[_nI][5]))  
          While ! SC9->(Eof()) .And. SC9->(C9_FILIAL+C9_PEDIDO) == _aPedCarga[_nI][12]+_aPedCargas[_nI][5] 
             If !Empty(SC9->C9_BLEST)
                _cMsg += " Pedido de vendas com bloqueio de estoque. Item: " + SC9->C9_ITEM + ". "  
             EndIf
          
             If !Empty(sc9->C9_BLCRED )
                _cMsg += " Pedido de vendas com bloqueio de crédito. Item: " + SC9->C9_ITEM + ". "
             EndIf
          
             If ! Empty(_cMsg)
                aAdd(_aDadosVld,{_aPedCarga[_nI][12], _aPedCarga[_nI][5], _cMsg})          
                _lRet := .F.
                _cMsg := ""
             EndIf
             
             SC9->(DBSkip())
          EndDo
       Else
          aAdd(_aDadosVld,{_aPedCarga[_nI][12],_aPedCarga[_nI][5], "Pedido de Vendas sem liberação."})
          _lRet := .F.
       EndIf
   Next
   
   If ! _lRet
   
      U_ITListBox( 'Relação de Pedidos que não podem montar carga: (OM200VLD)' ,;
		             {"Filial","Pedido de Vendas","Mensagem"} , _aDadosVld , .F. , 1 , 'Resultado da Análise dos pedidos: ',,;
		             {      30,       30,               80,                   200} )
   
   EndIf

End Sequence

RestOrd(_aOrd)

Return _lRet
