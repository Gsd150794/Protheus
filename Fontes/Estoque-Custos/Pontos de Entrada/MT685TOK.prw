/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |21/02/2024| Chamado 46236. André. Novas validações de campos dos produtos.
André Lisboa  |13/03/2024| Chamado 46587. Incluida permissão de informar produto destino com OP aberta para varredura.
André Lisboa  |13/03/2024| Chamado 46870. VAlidações de informações do lote para produtos com rastreabilidade.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT685TOK
Autor-------------: Carlos Cleber A.Silva
Data da Criacao---: 08/01/2014
Descrição---------: Ponto de entrada para validar gravação de apontamento de perdas - Chamado 5018
Parametros--------: Nenhum
Retorno-----------: _lRet := .T. Prossegue com apontamento de Perdas
                  		     .F. Nao Prossegue com apontamento de Perdas 	   
===============================================================================================================================
*/
User Function MT685TOK()  

Local _lRet     	:= .T.
Local _dDtServ  	:= dDataBase
Local _dDtAtual 	:= Date()  
Local _nDtPos   	:= aScan(aHeader,{|X| Upper(AllTrim(X[2]))=="BC_DATA"}) 
Local _nPrdPos		:= aScan(aHeader,{|X| Upper(AllTrim(X[2]))=="BC_PRODUTO"}) 
Local _nQtdPos		:= aScan(aHeader,{|X| Upper(AllTrim(X[2]))=="BC_QUANT"}) 
Local _nLocPos  	:= aScan(aHeader,{|X| Upper(AllTrim(X[2]))=="BC_LOCORIG"})   
Local _dDtPer   	:= aCols[N][_nDtPos]
Local _nI		 	:= 1
Local _asaldos 		:= {}
Local _nquant  		:= 0
Local _asaldos2 	:= {}
Local _nquant2  	:= 0
Local _cPrdSuc		:= GETMV( "IT_PRDSUCA" )
Local _lInc 		:= ParamIXB[1]
Private _aLog :={}

//==========================================================================================
//Valida saldos de produtos consumidos pela perda na data de apontamento
//==========================================================================================
If _lRet .And. _lInc

    //==========================================================================================
    //Valida database contra Date()
    //==========================================================================================
    If _dDtServ > _dDtAtual .Or. _dDtPer > _dDtServ  		
    	_lRet := .F. 	
    	_cMensagem := "Para incluir Apontamento de Perda a 'Data de emissão' não pode ser maior que a 'Data atual do servidor ou Data base do sistema. "
    	_cMensagem += "Não é permitido criar Apontamento de Perda com data futura! "
    	_cMensagem += "Conferir a 'Data Base do sistema' e ajustar a 'Data de emissão' se necessário. "
    	cSolucao := "Data Atual (SO): "+DToC(_dDtAtual)+" "+CRLF+"Data Base (Sistema): "+DToC(_dDtServ)+" "+CRLF+"Data Emissão: "+DToC(_dDtPer)
    	U_ITMsg(_cMensagem,'Atenção!',cSolucao,1) // Cancel
    EndIf


   _lOPAberta:=.T.
   If xFilial("SC2")+CORDEMP <> SC2->C2_FILIAL+SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN
      SC2->(DBSetOrder(1))//SC2->C2_FILIAL+SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN
      If SC2->(DBSeek(xFilial("SC2")+CORDEMP)) 
         _lOPAberta:=Empty(SC2->C2_DATRF)
      EndIf
   Else
      _lOPAberta:=Empty(SC2->C2_DATRF)
   EndIf
   
   lUsaRastr := AllTrim(SuperGetMv( "MV_RASTRO"  , .F. , ""  )) = "S"
   SB1->(DBSetOrder(1))
   _cPerg2um:="NAO_TEM_QUEIJO"
   _cProdQue:=""

   For _nI := 1 to Len(acols)

		If !acols[_nI][Len(aHeader)+1] //se não é linha deletada
		    
            cCodProd:= GdFieldGet("BC_PRODUTO",_nI)
			cLinha  := StrZero(_nI,2)
			cSolucao:=""

		    If acols[_nI][_nQtdPos] == 0
		    	//aAdd( _aprob2, { AllTrim(acols[_nI][_nPrdPos]), StrZero(_nI,2) } )
				cProb:="É obrigatório que o produto tenha uma quantidade maior que 0 (zero)!"
				cSolucao:="A quantidade deve ser informada, maior que zero."				
				GRVLog(cCodProd,cLinha,cProb,cSolucao)
		    EndIf			

		    If Empty(GdFieldGet("BC_I_NPROD",_nI))
		    	//aAdd( _aprob3, { GdFieldGet("BC_PRODUTO",_nI) , StrZero(_nI,2) } )
				cProb:="É obrigatório que o produto tenha a descricao preenchida!"
				cSolucao:="Edite o codigo do produto e tecle ENTER para gatilhar a descricao do mesmo."
				GRVLog(cCodProd,cLinha,cProb,cSolucao)
		    EndIf			
		    
		    If Empty(GdFieldGet("BC_MOTIVO",_nI))
		    	//aAdd( _aprob3, { GdFieldGet("BC_PRODUTO",_nI) , StrZero(_nI,2) } )
				cProb:="É obrigatório que o produto tenha o motivo preenchido!"
				cSolucao:="O motivo deve ser informado."
				GRVLog(cCodProd,cLinha,cProb,cSolucao)
		    EndIf			

		    If GdFieldGet("BC_LOCORIG",_nI) = "34"
				cProb:="Armazem de origem não pode ser igual a 34 !"
				cSolucao:="Escolha um armazem de origem diferente de 34."
				GRVLog(cCodProd,cLinha,cProb,cSolucao)
		    EndIf			

			SB1->( DBSeek( xFilial("SB1") + cCodProd ) ) 
            nQTSEGUM:=GdFieldGet("BC_QTSEGUM",_nI)    
            nQTDDES2:=GdFieldGet("BC_QTDDES2",_nI)    

			//VALIDACAO DOS QUEIJOS
			If SubStr(cCodProd,1,4) = "0006" .And. SB1->B1_CONV = 0 .And. SB1->B1_I_SFCON = "1"
			   
			    If Empty(nQTSEGUM) .And. Empty(nQTDDES2)
                   If _cPerg2um = "NAO_TEM_QUEIJO"
				      _cPerg2um:="SO_TEM_QUEIJO_OK"//SÓ ATIVA A PERGUNTA SE TIVER UMA LINHA COM OS 2 EM BRANCO
				   EndIf
				   _cProdQue+=" ["+cCodProd+"("+cLinha+")]"
			    ElseIf !Empty(nQTSEGUM) .Or. !Empty(nQTDDES2)
				   nQUANT  :=GdFieldGet("BC_QUANT"  ,_nI)  
                   nQTDDEST:=GdFieldGet("BC_QTDDEST",_nI)
  				   _nFtMin := SB1->B1_I_FTMIN
				   _nFtMax := SB1->B1_I_FTMAX
				   cProb:=""
				   
				   _nVlrPeca := nQUANT / nQTSEGUM
					If _nVlrPeca < _nFtMin .Or. _nVlrPeca > _nFtMax //Fora dos limites: menor que o Minimo ou maior que o Maximo
						cProb:="Quantidade Origem da 2 UM fora da faixa - "+ cValToChar( nQUANT ) +" / "+ cValToChar( nQTSEGUM ) +" = "+ cValToChar( _nVlrPeca ) + CRLF
					EndIf
				   
				   _nVlrPeca := nQTDDEST / nQTDDES2
					If _nVlrPeca < _nFtMin .Or. _nVlrPeca > _nFtMax //Fora dos limites: menor que o Minimo ou maior que o Maximo
						cProb:="Quantidade Destino da 2 UM fora da faixa - "+ cValToChar( nQTDDEST ) +" / "+ cValToChar( nQTDDES2 ) +" = "+ cValToChar( _nVlrPeca ) + CRLF
					EndIf

                    If !Empty(cProb)
				       _cPerg2um:="TEM_QUEIJO_COM_PROBLEMA"
				       cSolucao:="Digite uma quantidade dentro da faixa de conversao entre "+cValToChar( _nFtMin )+" e "+cValToChar( _nFtMax )+" ."
				       GRVLog(cCodProd,cLinha,cProb,cSolucao)
					EndIf
			    EndIf
			
			ElseIf SB1->B1_CONV = 0 .And. (!Empty(nQTSEGUM) .Or. !Empty(nQTDDES2))

		    	cProb:="Produto não tem conversão de unidade de medida!"
		    	cSolucao:="Os campos de segunda unidade devem ser zerados."
		    	GRVLog(cCodProd,cLinha,cProb,cSolucao)

			//VALIDAÇÃO PRODUTOS COM CONTROLE DE LOTES
			ElseIf lUsaRastr .And. SB1->B1_RASTRO = 'L'  .And. Empty(TRIM(GdFieldGet("BC_LOTECTL",_nI)))
				cProb:="Produto com controle de lotes ativado"
		    	cSolucao:="Informar o campo Lote."
		    	GRVLog(cCodProd,cLinha,cProb,cSolucao)
			EndIf

            If _lOPAberta // OP ABERTA
		        If (!TRIM(GdFieldGet("BC_CODDEST",_nI)) == TRIM(_cPrdSuc))
					If  (!Empty(GdFieldGet("BC_LOCAL",_nI)) .Or. !Empty(GdFieldGet("BC_CODDEST",_nI)))
			    		cProb:="Para OP aberta não pode preencher os campos de Local e Produto de destino!"
			    		cSolucao:="Limpe os campos de Local e Produto de destino."
			    		GRVLog(cCodProd,cLinha,cProb,cSolucao)
		        	EndIf
				ElseIf Empty(GdFieldGet("BC_LOCAL",_nI))
					cProb:="Quando produto destino preenchido, obrigatório preencher o armazém destino"
			    	cSolucao:="Informe o armazém destino."
			    	GRVLog(cCodProd,cLinha,cProb,cSolucao)	
				EndIf			
			Else// OP ENCERRADA
		        If GdFieldGet("BC_LOCAL",_nI) <> "34"
			    	cProb:="Para OP encerrada o Armazem de destino deve ser igual a 34 !"
			    	cSolucao:="Selecione o armazem de destino igual a 34."
			    	GRVLog(cCodProd,cLinha,cProb,cSolucao)
		        
				//lote origem e destino deverão ser iguais
				
				ElseIf 	TRIM(GdFieldGet("BC_LOTECTL",_nI)) <> TRIM(GdFieldGet("BC_LOTDEST",_nI))
					cProb:="Lotes origem e destino divergentes"
			    	cSolucao:="Favor informar o mesmo lote origem e destino."
			    	GRVLog(cCodProd,cLinha,cProb,cSolucao)
				

				ElseIf GdFieldGet("BC_QUANT"  ,_nI)  <> GdFieldGet("BC_QTDDEST",_nI)
					cProb:="Quantidade origem e destino divergentes"
			    	cSolucao:="Favor verificar as quatidades de perda e destino informadas, elas devem ser iguais."
			    	GRVLog(cCodProd,cLinha,cProb,cSolucao)
				EndIf	

									
			EndIf
			If 	TRIM(GdFieldGet("BC_CODDEST",_nI)) == TRIM(_cPrdSuc)
				If !U_ITMsg('Produto destino "Resíduo lácteo"','Atenção!','Gravar dados para destino "Resíduo lácteo"?',3,2,2,,"GRAVAR","VOLTAR")
					_lRet:=.F.
				EndIf	
			EndIf

			//calcula saldo final do produto na data
			_aSaldos:=	CalcEst(PadR(AllTrim(acols[_nI][_nPrdPos]),15),AllTrim(acols[_nI][_nLocPos]), acols[_nI][_nDtPos]+1)
			_nQuant	:= _aSaldos[1]
			
			//calcula saldo final do produto na data atual do servidor
			_aSaldos2:=	CalcEst(PadR(AllTrim(acols[_nI][_nPrdPos]),15),AllTrim(acols[_nI][_nLocPos]), Date() + 1)
			_nQuant2 := _aSaldos2[1]

			cProb:="É obrigatório que o produto tenha saldo no dia da perda e no dia atual!"
			cSolucao:=""

			If _nquant < acols[_nI][_nQtdPos]
			    cSolucao := "Esse produto no armazém " + AllTrim(acols[_nI][_nLocPos]) + " possui saldo de " + AllTrim(TRANSFORM(_nquant,"@E 999,999,999.99"))
			    cSolucao += " em " + DToC(acols[_nI][_nDtPos]) + " com perda de " + AllTrim(TRANSFORM(acols[_nI][_nQtdPos],"@E 999,999,999.99"))
				GRVLog(cCodProd,cLinha,cProb,cSolucao)
				
			EndIf
			
			If _nquant2 < acols[_nI][_nQtdPos] .And. Date() <> acols[_nI][_nDtPos] 
			    cSolucao := "Esse produto no armazém " + AllTrim(acols[_nI][_nLocPos]) + " possui saldo de " + AllTrim(TRANSFORM(_nquant2,"@E 999,999,999.99"))
			    cSolucao += " em " + DToC(DATE()) + " com perda de " + AllTrim(TRANSFORM(acols[_nI][_nQtdPos],"@E 999,999,999.99"))
				GRVLog(cCodProd,cLinha,cProb,cSolucao)

			EndIf
			
		EndIf
		
	Next
	
    If Len(_aLog) > 0
        _aTit:={"Produto","Linha","Problema","Solucao"}
    	_cTitulo:="LOG DE PROBLEMAS ENCONTRADOS NOS PRODUTOS:"
    	_cMsgTop:= "APONTAMENTO NÃO SERÁ CONCLUIDO!"
    	_lRet:=.F.
       //                           ,_aCols ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _aBbuttons )
          U_ITListBox(_cTitulo,_aTit,_aLog  , .T.    , 3    ,_cMsgTop,          ,        ,         ,     ,        ,            )
    
    ElseIf _lRet
    
       If _cPerg2um = "SO_TEM_QUEIJO_OK"
    	  
    	  _cMensagem:="Esse(s) produto(s):"+_cProdQue+" não esta(ao) com a 2um preenchida!"
    	  cSolucao:="DESEJA GRAVAR MESMO ASSIM ?"
    	  If !U_ITMsg(_cMensagem,'Atenção!',cSolucao,3,2,3,,"GRAVAR","VOLTAR")
    	     _lRet:=.F.
    	  EndIf
       
       EndIf
    
    EndIf

EndIf

Return(_lRet)

/*
===============================================================================================================================
Programa----------: GRVLog
Autor-------------: Alex Wallauer
Data da Criacao---: 21/02/2024
Descrição---------: Grava o log com 4 colunas
Parametros--------: CodPod,Linha,Prob,Solucao
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function GRVLog(CodPod,Linha,Prob,Solucao)
Local _aItens:={}

aAdd(_aItens,CodPod)
aAdd(_aItens,Linha)
aAdd(_aItens,Prob)
aAdd(_aItens,Solucao)

aAdd(_aLog,_aItens)

Return
