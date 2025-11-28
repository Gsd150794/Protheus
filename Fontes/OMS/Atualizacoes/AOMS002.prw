/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |29/08/2023| Chamado 43598. Alteracao da validação do PV quando For Operação de Transferência (código 20).
Julio Paz     |25/04/2024| Chamado 46904. Desenvolver rotina p/buscar ultimo preço de compra p/ operações 22 e filias 20;23;93
Lucas Borges  |18/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TbiCode.ch"
#Include "FONT.CH"

/*
===============================================================================================================================
Programa----------: AOMS002
Autor-------------: Josué Prestes
Data da Criacao---: 28/07/2015  
Descrição---------: Gatilho para preencher o preço em pedido de venda de transferência - Chamado 11064
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS002(_cCpoGatilho)

Local _npreco := 0 
Local _aArea     := FWGetArea()
Local _cfildest  := ""
Local _cfiltab   := ""
Local _cfilmed   := ""
Local _ndiamed   := 15
Local _nfatortra := 1.0476
Local _dinicial  := SToD('20010101')
Local _dfinal    := SToD('20010101') 
Local _cmens     := ""
Local _cSvFilAnt := cFilAnt //Salva a Filial Anterior
Local _adatas    := {} , A
Local _nPosArm   := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "C6_LOCAL"  } ) // Código do Armazém
Local _nPosProd  := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "C6_PRODUTO"} )
Local _nPosPreco := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "C6_PRCVEN"} )
Local _cOpPMedio := SuperGetMV("IT_OPMEDIO",.F.,'20|22') //Operacao do que busca o preco medio do SB2
Local _lRet      := .T.
Local _cFilBxEst, _cCFOBxEst 

Default _cCpoGatilho:="C6_PRODUTO"

Begin Sequence 

   U_ITLOGACS()//Grava log de utilização da rotina

   //====================================================================================  
   // Busca no item da nota de entrada o ultimo valor de compra para retornar 
   // para o item do pedido de vendas, para tipos de operações Baixa de Estoques. 
   //====================================================================================
   _cFilBxEst := SuperGetMV('IT_FILBXES',.F.,"20;23;93") // Filiais de Baixa de Estoques.
   If "/" $ _cFilBxEst
      _cFilBxEst := StrTran(_cFilBxEst,'/',";")
   EndIf 

   If M->C5_I_OPER == "22" .And. AllTrim(SM0->M0_CODFIL) $ _cFilBxEst
      _cCFOBxEst := SuperGetMV('IT_CFOBXES',.F.,"1101;1102;1122;1151;1152;1403;2101;2102;2122;2151;2152;2403;") // CFOPs de Baixa de Estoques. 
      
	  If "/" $ _cCFOBxEst
         _cCFOBxEst := StrTran(_cCFOBxEst,'/',";")
      EndIf 

      _cCodProd := AllTrim(aCols[n][_nPosProd])

      //_nPreco := U_AOMS002B(_cCodProd, _cFilBxEst, _cCFOBxEst,  dDataBase)
	  _nPreco := U_AOMS002B(_cCodProd, AllTrim(SM0->M0_CODFIL), _cCFOBxEst,  dDataBase)

      If _nPreco > 0
		 Break
	  EndIf 
   EndIf 
   
   //====================================================================================
   // Para tipo de operações 22 verificar se as filiais de origem e destino na tabela Z09
   // são iguais a filial de login do usuário, e se o produto informado é igual  
   // ao produto da tabela Z09, e o codigo de operação da tabela Z09 é igual a 22.
   // Caso esta condição seja afirmativa, retornar o preço da tabela Z09.
   //==================================================================================
   Z09->( DBSetOrder(3) ) // Z09_FILIAL+Z09_FILORI+Z09_FILDES+Z09_CODOPE+Z09_CODPRO   

   If (M->C5_I_OPER $ _cOpPMedio) .And. Z09->(DBSeek(xFilial("Z09")+AllTrim(SM0->M0_CODFIL)+AllTrim(SM0->M0_CODFIL)+M->C5_I_OPER+aCols[n][_nPosProd])) 
      If (Date() >= Z09->Z09_INIVIG .And. Date() <= Z09->Z09_FIMVIG)
         _npreco := Z09->Z09_PRECO  // Return Z09->Z09_PRECO
		 Break
      Else
         If ! U_ITMsg('Não será possível sugerir preço para o produto "'+AllTrim(aCols[n][_nPosProd])+'" pois a data atual '+DToC(Date())+;
            ' está fora do período de vigencia da tabela de preço para o tipo de operação 22.'+;
            ' O atual período de vigencia da tabela de preços para este produto vai de '+ DToC(Z09->Z09_INIVIG) +' até ' + DToC(Z09->Z09_FIMVIG) + '.', 'Atenção!' ,;
            'Para que seja possível sugerir um preço para o produto "'+AllTrim(aCols[n][_nPosProd])+;
            '", é necessário cadastrar um novo período de vigência para este produto e para o tipo de operação 22. Deseja usar o custo médio mesmo assim?' ,1,2 )
            _lRet := .F.
         EndIf
      EndIf 
   EndIf
 
   If _lRet .And. M->C5_I_OPER $ _cOpPMedio// "22"
   
      _nPreco:=Posicione( "SB2" , 1 , xFilial("SB2") + aCols[n][_nPosProd] + aCols[n][_nPosArm] , "B2_CM1" )
      If _nPreco # 0
         Break //Return _nPreco
      EndIf 

      _cTpProd:=Posicione("SB1",1,xFilial("SB1")+aCols[n][_nPosProd],"B1_TIPO")
      If _cTpProd = "PA"
         _aArm:={'20','30','31','21'}
      Else
         _aArm:={'04','02','00'}
      EndIf 

      For A := 1 To Len(_aArm)
          _nPreco:=Posicione( "SB2" , 1 , xFilial("SB2") + aCols[n][_nPosProd] + _aArm[A] , "B2_CM1" )
          If _nPreco # 0
             Exit 
          EndIf 
      Next 

      If _nPreco = 0
	     xMagHelpFis("AOMS002"	,;
	      		  "Custo médio do produto não encontrado",;
				  "favor entrar em contato com o departamento de Custos para verificar o custo médio do produto")      
      EndIf

      Break //Return _nPreco

   ElseIf _cCpoGatilho == "C6_LOCAL"

      _nPreco := aCols[n][_nPosPreco] // Return aCols[n][_nPosPreco]
	  Break 

   EndIf 

   DBSelectArea("Z09")
   Z09->( DBSetOrder(2) )

   If M->C5_I_OPER = "20" .And. ;//Posicione("SB1",1,xFilial("SB1")+AllTrim(M->C6_PRODUTO),"B1_TIPO") == 'PA' .Or. Posicione("SB1",1,xFilial("SB1")+AllTrim(M->C6_PRODUTO),"B1_GRUPO") == '0813') .And. ;
      Z09->(DBSeek(xFilial("Z09")+M->C5_I_OPER))
	
	  //só verifica se o produto é PA ou Pallet e  existir pelo menos um cadastro da operação na z09

	  //verifica se cliente tem campo filial origem válido
	  DBSelectArea("SA1")
	  SA1->( DBSetOrder(1) )
	
	  If SA1->( DBSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI) )
	  
	 	 If !(AllTrim(SA1->A1_I_FILOR) >= '01' .And. AllTrim(SA1->A1_I_FILOR) <= 'ZZ')
		
		    xMagHelpFis("AOMS002"	,;
		    "Cliente não é filial válida para receber transferência",;
		    "Favor solicitar apoio ao Departamento Fiscal.")
	        _nPreco := 0 // Return 0
  		    Break 
  	     EndIf
  		
  	  EndIf
  		
  	  _cfildest  := AllTrim(Posicione("SA1",1,xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI,"SA1->A1_I_FILOR")) //filial destino do cliente selecionado

	  _cfiltab   := SuperGetMV("IT_FILTABT",.F.,_cfildest) //filiais que usam tabela de preço
	  _cfilmed   := SuperGetMV("IT_FILMEDT",.F.,"") //filiais que usam média de preço   
	  _ndiamed   := SuperGetMV("IT_DIASTRA",.F.,15)  //dias corridos para fazer a média de preço
	  _nfatortra := 0 //fator a ser aplicado a média de preço
	  _cproduto  := AllTrim(M->C6_PRODUTO)
   
	  //muda para filial destino para pegar o parâmetro
	  cFilAnt := _cfildest

	  _nfatortra := SuperGetMV("IT_FATORTR",.F.,1.0476) //fator a ser aplicado a média de preço
	
	  //volta a filial local
	  cFilAnt := _cSvFilAnt

	  //Se filial destino pertence ao IT_FILMEDTRA usa média de preço
	  If AllTrim(_cfildest) $ _cfilmed

		  //calcula faixa de análise de média de vendas
    	  //ultimo dia de venda desde que não seja o dia atual (que não está completo) menos a quantidade de dias do IT_DIASTRA
          _adatas := U_AOMS002C(_cfildest,_cproduto,_ndiamed)
          _dinicial := _adatas[1]
          _dfinal   := _adatas[2]     	  
	  
	      //calcula média de preco de vendas
	      _npreco := U_AOMS002M(_dinicial,_dfinal,_cfildest,_cproduto,_nfatortra)
	 
	 	  If _npreco == 0
  		  
    		 //se não achar vendas do produto na filial destino avisa e usa tabela de preços de transferência
    		 _cmens := "tabela"
     
  		  EndIf
  	
	  Else
  	     //marca flag para executa cálculo por tabela de preço de transferência
  		 _cmens     := "tabela"
	  EndIf

	  If Len(_cmens) > 1
  		 //carrega preço da tabela de precos de transferencia para a operação do pedido de vendas
  	     _npreco := U_AOMS002P(M->C6_PRODUTO,xFilial("SC5"),_cfildest,M->C5_I_OPER)[1]
	  EndIf
   EndIf
   
End Sequence 

FWRestArea(_aArea)	
	
Return	_npreco

/*
===============================================================================================================================
Programa----------: AOMS002C 
Autor-------------: Josué Prestes
Data da Criacao---: 30/07/2015  
Descrição---------: Cálcula faixa de datas a partir de ultima venda e tamanho do período  - Chamado 11064	
Parametros--------: 	_cfildest	Filial
						_cproduto	Produto
						_ndiamed	Quantidade de dias da faixa de datas
Retorno-----------: _npreco  Preço médio com fator aplicado
===============================================================================================================================
*/	
User Function AOMS002C(_cfildest,_cproduto,_ndiamed)

Local _dinicial 	:= Date()- 180
Local _dfinal   	:= Date() 
Local _adatas   	:= {}
Local _cSvFilAnt	:= ""
Local _cfilzay 	:= ""
Default _cfildest	:= '99'
Default _cproduto	:= "   "
Default _ndiamed 	:= 1

//pega filial destino para a tabela zay
//muda para filial destino 
_cSvFilAnt := cFilAnt
cFilAnt    := _cfildest

_cfilzay := xFilial("ZAY")
	
//volta a filial local
cFilAnt := _cSvFilAnt

//calcula faixa de análise de média de vendas
//ultimo dia de venda desde que não seja o dia atual (que não está completo) menos a quantidade de dias do IT_DIASTRA
    
_cAlias := GetNextAlias()
  
BeginSql alias _cAlias
			   	
   	SELECT 
	 	max(d.d2_emissao) as dt 
	FROM 
		%Table:SD2% d inner join %Table:ZAY% z 
	ON d.d2_cf = z.zay_cf
	WHERE 
	   d.d2_nfori < '0' 
	   and d.d2_tipo <> 'D' 
	   and z.zay_filial = %exp:_cfilzay%
	   and z.zay_tpoper = 'V' 
	   and d.d2_filial = %exp:_cfildest%											     //filial da média
	   and d.d2_emissao between %exp:_dinicial% and %exp:_dfinal%
	   and d.d2_cod =    %exp:_cproduto%                                            //produto da média
	   and d.d_e_l_e_t_ = ' ' and z.d_e_l_e_t_ = ' ' 
EndSql

DBSelectArea(_cAlias)
(_cAlias)->(  DBGoTop() )
  
//se achou venda define datas
If .not. (_cAlias)->( Eof() )
	_dinicial  := SToD((_cAlias)->dt) - _ndiamed
	_dfinal    := SToD((_cAlias)->dt)
	If _dfinal == Date() //não considera o dia atual por não ter as vendas completas e distorcer média
		_dinicial  := _dinicial - 1				   	
		_dfinal    := _dfinal  - 1
	EndIf 
Else
	//se não achou nem em 6 meses define data inválida para procurar por tabela
	_dinicial := SToD('20010101')
	_dfinal   := SToD('20010101')
EndIf

(_cAlias)->(  DBCloseArea() )

_adatas := { _dinicial, _dfinal }

Return _adatas

/*
===============================================================================================================================
Programa----------: AOMS002M 
Autor-------------: Josué Prestes
Data da Criacao---: 30/07/2015  
Descrição---------: Calcula média de preco de venda em uma filial  - Chamado 11064	
Parametros--------: 	_dinicial	Data inicial de análise
						_dfinal	Data final de análise
						_cfildest	Filial
						_cproduto	Produto
						_nfatortra	Fator a ser aplicado sobre a média
Retorno-----------: _npreco  Preço médio com fator aplicado
===============================================================================================================================
*/
User Function AOMS002M(_dinicial,_dfinal,_cfildest,_cproduto,_nfatortra)

Local _npreco := 0
Local _cfilzay := ""
Local _cSvFilAnt := ""
Default _dinicial := SToD('20010101')
Default _dfinal   := SToD('20010101')
Default _cfildest := '99'
Default _cproduto:= "   "
Default _nfatortra := 1

//pega filial destino para a tabela zay
//muda para filial destino 
_cSvFilAnt := cFilAnt
cFilAnt    := _cfildest
_cfilzay := xFilial("ZAY")
//volta a filial local
cFilAnt := _cSvFilAnt

_cAlias := GetNextAlias()
 
BeginSql alias _cAlias  	   	
   	SELECT 
	 	sum(d.d2_quant) as quant, sum(d.d2_total) as total, sum(d.d2_total) / sum(d.d2_quant) as VLRMEDIO
	FROM %Table:SD2% d  inner join %Table:ZAY% z 
    ON d.d2_cf = z.zay_cf
    WHERE	d.d2_tipo <> 'D' 
    		and z.zay_filial = %exp:_cfilzay%
			and z.zay_tpoper = 'V' 
			and d.d2_emissao between %exp:_dinicial% and %exp:_dfinal%
			and d.d2_filial = %exp:_cfildest%
			and d.d2_cod =    %exp:_cproduto%                                            //produto da média
			and d.d_e_l_e_t_ = ' ' and z.d_e_l_e_t_ = ' ' 
EndSql

DBSelectArea(_cAlias)
(_cAlias)->(  DBGoTop() )
 
//se achou média define o preço
If .not. (_cAlias)->( Eof() ) .And. (_cAlias)->VLRMEDIO > 0
	_npreco := Round(((_cAlias)->VLRMEDIO / _nfatortra),2) 
EndIf

DBSelectArea(_cAlias)
(_cAlias)->(DBCloseArea())

Return _npreco

/*
===============================================================================================================================
Programa----------: AOMS002P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/09/2015
Descrição---------: Retorna preço de tabela de transferência para um produtoxFilial orixFilial destx operação
Parametros--------: _cprod - Produto
					  _cfilori - Filial origem
					  _cfildes - Filial Destino
					  _coper - Operação
Retorno-----------: _apreco - matriz:
							posição 1: Preço de tabela para o produtoxfiliaisxoperação, se não tiver cadastro retorna 0
							posição 2: margem de variação do preço permitida
===============================================================================================================================
*/
User Function AOMS002P(_cprod,_cfilori,_cfildes,_coper)

Local _apreco := {0,0}

DBSelectArea("Z09")
Z09->( DBSetOrder(3) )

If Z09->( DBSeek(xFilial("Z09")+_cfilori+_cfildes+_coper+_cprod) )
	//procura preço com vigência ativa
	While Z09->Z09_FILIAL == xFilial("Z09") .And. Z09->Z09_CODOPE == _coper;
			.And. Z09->Z09_FILORI == _cfilori .And. Z09->Z09_FILDES == _cfildes
		If Z09->Z09_INIVIG <=  Date() .And. Z09->Z09_FIMVIG >= Date() .And. AllTrim(Z09->Z09_CODPRO) == AllTrim(_cprod)
	       	_apreco := {Z09->Z09_PRECO,(Z09->Z09_DESVIO/100)}
       	EndIf
		Z09->( DBSkip() )
    EndDo
EndIf

//Se não achou preço válido procura com filial origem e filial destino em branco
If _apreco[1] == 0
	If Z09->( DBSeek(xFilial("Z09")+"  "+"  "+_coper+_cprod) )
		//procura preço com vigência ativa
		While Z09->Z09_FILIAL == xFilial("Z09") .And. Z09->Z09_CODOPE == _coper; 
				.And. Z09->Z09_FILORI == "  " .And. Z09->Z09_FILDES == "  "
  
			If Z09->Z09_INIVIG <=  Date() .And. Z09->Z09_FIMVIG >= Date() .And. AllTrim(Z09->Z09_CODPRO) == AllTrim(_cprod)
   
   		 	   	_apreco := {Z09->Z09_PRECO,(Z09->Z09_DESVIO/100)}
    
		   	EndIf

    		Z09->( DBSkip() )
		EndDo
	EndIf
EndIf

Return _apreco

/*
===============================================================================================================================
Programa----------: AOMS002B 
Autor-------------: Josué Prestes
Data da Criacao---: 28/07/2015  
Descrição---------: Retorna o ultimo preco de compra do produto no mes de emissão do pedido de vendas.
Parametros--------: _cCodProd = Código do Produto
                    _cCFOPs   = CFOPs da nota de compra
					_dDtEmiss = Data de emissão do Pedido de compras
Retorno-----------: _nRet = Ultimo valor de compras do item do pedido de vendas.
===============================================================================================================================
*/
User Function AOMS002B(_cCodProd, _cFilBxEst , _cCFOPs, _dDtEmiss)

Local _nRet := 0
Local _cQry 
Local _cAnoMes
Local _nI
Local _nTotRegs, _cDtQry, _dDtQry

Begin Sequence
   _cAnoMes := StrZero(Year(_dDtEmiss),4)+ StrZero(Month(_dDtEmiss),2)

   For _nI := 1 To 24 // Busca o ultimo Preço até os ultimos 2 anos.
       _cQry := " SELECT D1_DTDIGIT, Max(SD1.R_E_C_N_O_) REGSD1 " // "SELECT D1_DTDIGIT, D1_VUNIT " 
       _cQry += " FROM  "+ RetSqlName("SD1") +" SD1 "
       _cQry += " WHERE "
       _cQry += "     SD1.D_E_L_E_T_  = ' ' "
       //_cQry += " AND D1_FILIAL IN " + FormatIn(_cFilBxEst,";")    
	   _cQry += " AND D1_FILIAL = '" + _cFilBxEst + "' "   
       _cQry += " AND TRIM(D1_CF) IN " + FormatIn(_cCFOPs,";")  
       _cQry += " AND SubStr(D1_DTDIGIT,1,6) = '" + _cAnoMes +"' " 
       _cQry += " AND D1_COD = '" + _cCodProd + "' "    
       _cQry += " GROUP BY D1_DTDIGIT "
       _cQry += " ORDER BY D1_DTDIGIT DESC "

       If Select("QRYSD1") > 0
	      QRYSD1->( DBCloseArea() )
       EndIf

       DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQry) , "QRYSD1" , .T. , .F. )
   
       Count To _nTotRegs
       
	   If _nTotRegs > 0 
	      Exit 
	   EndIf

       _cDtQry := _cAnoMes+"01"
       _dDtQry := SToD(_cDtQry)
	   _dDtQry := _dDtQry - 1 // Muda a data para o Mes Anterior
	   _cAnoMes := StrZero(Year(_dDtQry),4)+ StrZero(Month(_dDtQry),2)
	
   Next

   QRYSD1->(DBGoTop())
   
   While ! QRYSD1->(Eof()) 
      SD1->(DBGoTo(QRYSD1->REGSD1))

      If SD1->D1_VUNIT > 0      // QRYSD1->D1_VUNIT > 0
         _nRet := SD1->D1_VUNIT // QRYSD1->D1_VUNIT
		 Exit
	  EndIf 

      QRYSD1->(DBSkip())
   EndDo 

End Sequence 

If Select("QRYSD1") > 0
   QRYSD1->( DBCloseArea() )
EndIf

Return _nRet
