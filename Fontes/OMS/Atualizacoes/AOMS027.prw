/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |23/01/2024| Chamado 46145. Jerry. Troca da função de U_ITMsg() para U_MT_ITMSG().
Alex Wallauer |10/04/2025| Chamado 49894. Alterado para preencher o campo C6_I_PTBRU sempre com (SB1->B1_PESBRU * aCols[N,_nPosQtd1]).
Lucas Borges  |18/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Programa----------: AOMS027
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 22/07/2009  
Descrição---------: Validação do campo C6_PRODUTO
Parametros--------: Nenhum
Retorno-----------: _lRet -> campo validado ou não
===============================================================================================================================
*/
User Function AOMS027

Local _lReturn	:= .T.  
Local _nCont	:= 1 
Local _nPos, _cProd, _cCodProd  
Local _npreco    := 0  
Local _aArea     := FWGetArea()
Local _cfildest  := ""
Local _cfilmed   := ""
Local _ndiamed   := 15
Local _nfatortra := 1.0476
Local _dinicial  := SToD('20010101')
Local _dfinal    := SToD('20010101')  
Local _cmens     := "" 
Local _cSvFilAnt := cFilAnt //Salva a Filial Anterior
Local _atabelas  := {}
Local _cOpPMedio := "" 
Local _lAoms112  := .F. 

//Se esta sendo chamado via AOMS112/MOMS050 (Central Pedido Portal / Efetivaççao Automatica)
If IsInCallStack("U_AOMS112") .Or. IsInCallStack("U_MOMS050")
	_lAoms112 := .T.
EndIf
  
//Se For Exclusão de Documento Troca nota não efetuar as validações abaixo

If  (FunName() $ "MATA140,MATA521B,MATA460B" .Or. _lAoms112  ) 
	Return .T.
EndIf 

//verifica se o produto não está presente em outra linha já, mesmo que deletado

If (FunName() == "MATA410" .And. M->C5_TIPO <> 'D' .And. Posicione("SB1",1,xFilial("SB1")+C6_PRODUTO,"B1_TIPO") == 'PA') 
	If Len(aCols) > 1 //1o produto
		_cProd		:= AllTrim(aCols[n,aScan(aHeader,{|X| rTrim(Upper(X[2]))=="C6_DESCRI"})])
		
		_nPos		:= aScan(aHeader,{|X| rTrim(Upper(X[2]))=="C6_PRODUTO"})
		_cCodProd	:= M->C6_PRODUTO
		
		For _nCont := 1 To Len(aCols)
			
			If _nCont <> n .And. _cCodProd == aCols[_nCont,_nPos]
				
				If !aCols[_nCont,Len(acols[_nCont])]
	
					U_MT_ITMSG("Atenção: O item: " + _cProd + " já foi digitado...",,,1)
					Return .F.
	
				ElseIf _nCont <> n .And. !Empty(aCols[_nCont,aScan(aHeader,{|x|AllTrim(Upper(x[2]))==Trim('C6_I_LIBPE')})]) .And. !aCols[n,Len(aHeader)+1]
	
					Return .T.
	
				Else
	
					U_MT_ITMSG("Atenção: O item: " + _cProd + " já foi digitado, porem se encontra deletado. Favor reativar a linha...",,,1)
					Return .F.
				EndIf
			EndIf
		Next
	EndIf
EndIf

//--------------------------------------------------------------------
//Validacao da tabela de preco de NOTAS FISCAIS de transferencia chamdo 2068 
//Ajustada de acordo com chamado 11064 para que em caso de filial destino que usa média de preço
//ao invés de tabela de preço aceite o preço 
//-------------------------------------------------------------------
DBSelectArea("Z09")
Z09->( DBSetOrder(2) )

If (Posicione("SB1",1,xFilial("SB1")+AllTrim(M->C6_PRODUTO),"B1_TIPO") == 'PA' ;
	.Or. Posicione("SB1",1,xFilial("SB1")+AllTrim(M->C6_PRODUTO),"B1_GRUPO") == '0813') .And. ;
	Z09->(DBSeek(xFilial("Z09")+M->C5_I_OPER) )   
	
	_cOpPMedio := SuperGetMV("IT_OPMEDIO",.F.,'20|22') //Operacao do que busca o preco medio do SB2

	//verifica se cliente tem campo filial origem válido
	DBSelectArea("SA1")
	SA1->( DBSetOrder(1) )
	 
	If SA1->( DBSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI) )
		If !(AllTrim(SA1->A1_I_FILOR) >= '01' .And. AllTrim(SA1->A1_I_FILOR) <= 'ZZ')
				U_MT_ITMSG( "Cliente não é filial válida para receber transferência","Alerta",;
				"Favor solicitar apoio ao Departamento Fiscal/Comercial.",1)
				Return .F.
  		EndIf
  	EndIf
  		
  	_cfildest  := AllTrim(Posicione("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"SA1->A1_I_FILOR")) //filial destino do cliente selecionado
	_cfilmed   := SuperGetMV("IT_FILMEDT",.F.,"") //filiais que usam média de preço   
	_ndiamed   := SuperGetMV("IT_DIASTRA",.F.,15)  //dias corridos para fazer a média de preço
	_nfatortra := 0 //fator a ser aplicado a média de preço
	_cProduto  := AllTrim(M->C6_PRODUTO)

 	//muda para filial destino para pegar o parâmetro
	cFilAnt := _cfildest

	_nfatortra := SuperGetMV("IT_FATORTR",.F.,1.0476) //fator a ser aplicado a média de preço
	
	//volta a filial local
	cFilAnt := _cSvFilAnt

	//Se filial destino pertence ao IT_FILMEDTRA usa média de preço
	If AllTrim(_cfildest) $ _cfilmed .And. !M->C5_I_OPER $ _cOpPMedio

		//calcula faixa de análise de média de vendas
    	//ultimo dia de venda desde que não seja o dia atual (que não está completo) menos a quantidade de dias do IT_DIASTRA
       _adatas := U_AOMS002C(_cfildest,_cproduto,_ndiamed)
       _dinicial := _adatas[1]
       _dfinal   := _adatas[2]     	  
	  
	    //calcula média de preco de vendas
	    _npreco := U_AOMS002M(_dinicial,_dfinal,_cfildest,_cproduto,_nfatortra)
	   
  	Else
  		//marca flag para executa cálculo por tabela de preço de transferência
  		_cmens     := "tabela"
	EndIf

	If Len(_cmens) > 1.And. !M->C5_I_OPER $ _cOpPMedio
		_atabelas := _npreco := U_AOMS002P(AllTrim(M->C6_PRODUTO),xFilial("SC5"),_cfildest,AllTrim(M->C5_I_OPER)) 
   		_npreco := _atabelas[1]
   	
		If _npreco == 0 
    		//Não tem tabela de preço de transferência para o produto
    		U_MT_ITMSG("Para o tipo de operação "+AllTrim(M->C5_I_OPER)+", o produto "+AllTrim(M->C6_PRODUTO)+" e Fil.Dest. "+_cfildest+", não está cadastrado na Tabela de Preço de Transferência (Z09).",;
    		"Validação de preço de transferência",;
			"Favor solicitar apoio ao Departamento Comercial.",1)
			Return .F.
  		EndIf

    ElseIf M->C5_I_OPER $ _cOpPMedio
        _lReturn:=u_ITVLPRTR(M->C5_I_OPER,M->C6_PRODUTO,0,1)
  	EndIf
EndIf
 
FWRestArea(_aArea)

Return _lReturn
 
/* 
===============================================================================================================================
Programa----------: AOMS027W 
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/04/2022
Descrição---------: Habilita e desabilita a edição do campo C6_I_PTBRU. Quando o produto possuir peso variável a edição pode
                    ser realizada. Caso contrário, o Peso não poderá ser alterado.
Parametros--------: _cCampo = Do Whem que chamou a rotina.
Retorno-----------: _lRet -> campo validado ou não
===============================================================================================================================
*/
User Function AOMS027W(_cCampo)

Local _lRet := .F.
Local _nPosPrd, _nPosPBTI 

Begin Sequence 
   
   If _cCampo =="C6_I_PTBRU"
      _nPosPrd	:= aScan(aHeader,{|X| AllTrim(Upper(X[2]))=="C6_PRODUTO"})
      _nPosPBTI := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_I_PTBRU"})  

	  SB1->(DBSetOrder(1))
	  SB1->(DBSeek(xFilial("SB1")+aCols[N,_nPosPrd]))
	  If SB1->B1_I_PCCX > 0 // Possui peso variável. Habilita a edição.
         _lRet := .T.
	  EndIf 

   EndIf 

End Sequence 

Return _lRet 

/*
===============================================================================================================================
Programa----------: AOMS027G 
Autor-------------: Julio de Paula Paz
Data da Criacao---: 19/04/2022
Descrição---------: Trigger de preenchimento do campo C6_I_PTBRU, quando as quantidades na primeira e segunda unidade de 
                    medida forem alterados e o produto possuir o peso variável.
Parametros--------: _cCampo = Do Whem que chamou a rotina.
Retorno-----------: _nRet   = Valor a ser retornado para o campo C6_I_PTBRU.
===============================================================================================================================
*/
User Function AOMS027G(_cCampo)

Local _nRet := 0
Local _nPosPrd, _nPosPBTI 

Begin Sequence 
   
   If _cCampo == "C6_QTDVEN" .Or. _cCampo == "C6_UNSVEN" 
      _nPosPrd	:= aScan(aHeader,{|X| AllTrim(Upper(X[2]))=="C6_PRODUTO"})
      _nPosPBTI := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_I_PTBRU"}) 
	  _nPosQtd1 := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C6_QTDVEN" }) 

	  SB1->(DBSetOrder(1))
	  SB1->(DBSeek(xFilial("SB1")+aCols[N,_nPosPrd]))
	  If SB1->B1_I_PCCX > 0 // Possui peso variável. Habilita a edição.
         _nRet := (SB1->B1_PESBRU * aCols[N,_nPosQtd1])
	  Else
         _nRet := (SB1->B1_PESBRU * aCols[N,_nPosQtd1]) // Agora preenche o campo C6_I_PTBRU sempre.
	  EndIf 

   EndIf 
   
End Sequence 

Return _nRet   
