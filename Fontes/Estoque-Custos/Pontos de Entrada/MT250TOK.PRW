/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |14/11/2019| Chamado 31146. Novo parametro IT_NAOVLDPC p/ não permitir a qtde em 2a UM caso não controle. 
Alex Wallauer |18/01/2023| Chamado 42590. Novo validacao para armazens do almoxarifado (00, 02). 
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT250TOK
Autor-------------: Carlos Cleber A.Silva
Data da Criacao---: 03/12/2013
Descrição---------: Este pe permite validar algo digitado dependendo da necessidade do usuário, ele valida a tela toda
------------------  http://tdn.totvs.com.br/display/Public/mp/MT250TOK+-+Valida+valor+digitado+ou+tela+toda
------------------: Impedir de criar producao com o centro de custo em branco forcando a informar o centro de custo        	 	
------------------  Chamado 4356
Parametros--------: Nenhum
Retorno-----------: .T. = Permite confirmar lancamento
------------------: .F. = Nao Permite confirmar lancamento 
===============================================================================================================================*/
User Function MT250TOK()  

Local lRet     := .T. 
Local dDtServ  := dDataBase
Local dDtAtual := Date() 
Local dDtEms   := (M->D3_EMISSAO)
Local nQuantOP := Posicione("SC2",1,xFilial("SC2")+M->D3_OP,"C2_QUANT")
Local nQuantPr := (M->D3_QUANT)
Local nQtdeSeg := (M->D3_QTSEGUM)	
Local nResult  := 0 ,Y
Local nQtFator := Posicione("SB1",1,xFilial("SB1")+M->D3_COD,"B1_CONV")
Local _lValidFrac1UM:=.T.
Local nQtde1UN:=M->D3_QUANT
Local nQtde2UN:=M->D3_QTSEGUM

	//Verifica se o centro de custo esta em branco        ³
	If  Empty(M->D3_CC)  
		lRet := .F. 
		U_ITMsg("O centro de custo,não pode ficar em branco!","PROBLEMA CENTRO DE CUSTO",;
		        "O centro de custo é obrigatório, para concluir a operação favor informar corretamente atentando a FILIAL e PRODUTO!",1) 
	EndIf
	
	//Verifica se a Data Base eh maior que a data atual   
	If dDtServ > dDtAtual .Or. dDtEms > dDtServ  
		lRet := .F. 
		U_ITMsg("Para incluir Produção a 'Data de emissão' não pode ser maior que a 'Data atual do servidor ou Data base do sistema'. Não é permitido criar Produção com data futura! ","PROBLEMA DATA BASE",;
		        +CRLF+"Data Atual(SO): "+DToC(dDtAtual)+" "+CRLF+"Data Base(Sistema): "+DToC(dDtServ)+" "+CRLF+"Data Emissão: "+DToC(dDtEms),; 
		        "Conferir a 'Data Base do sistema' e ajustar a 'Data de emissão' se necessário.",1)
	EndIf
    
	//Verifica a qtde na 2aUM dos produtos	           
 	If nQtdeSeg == 0 .And. !Empty(nQtFator)
 		lRet := .F.
		U_ITMsg("Quantidade na 2a. UM zerada para produto que controla conversão para a 2a. UM","PROBLEMA 2A.UM",;
		        "Favor verificar o apontamento ou o cadastro do produto.",1 )
	EndIf	

	//Verifica a qtde na 2aUM dos produtos	           
 	If nQtdeSeg <> 0 .And. Empty(nQtFator) .And. !AllTrim(M->D3_COD) $ SuperGetMV("IT_NAOVLDP",.F.," ")//!LEFT(M->D3_COD,4)=="0006" 
 		lRet := .F.
		U_ITMsg("Quantidade na 2a. UM preenchida para produto que não controla conversão para a 2a. UM","PROBLEMA 2A.UM",;
		        "Favor verificar o apontamento ou o cadastro do produto.",1 )
	EndIf	
    // Verifica se a quantidade apontada é maior que a quantidade da OP   
	nResult		:= nQuantPr - nQuantOP
	nTotal 		:= (nResult/nQuantOP)*100
	nPctPrd 	:= GETMV("IT_PCTPRD" ,, "" )
	
	If nResult > 0
		If nTotal > nPctPrd .And. !Empty(M->D3_CC)  //Trim(M->D3_COD) $ cPrdPerm//cTipo <> "PA" .And.
			//"Apontamento de produção com quantidade acima da quantidade original da OP!")
			If ! MsgYesNo("Apontamento de produção com acima da quantidade informada na OP! ("+Transform(Round(nTotal,2),"E@ 99.99")+"%"+")"+ ", Confirma ? ") // " +Transform(nPctPrd,"E@ 99.99")+ "
			   lRet := .F.
			Else
			   If !Empty(M->D3_CC)
			      Motivo()
			      lRet := .T.
			   EndIf   
			EndIf
	    EndIf
	EndIf	

If SuperGetMV("IT_VLDCUS",.F.,.T.) .And. !MTVusto() 
   lRet := .F.
EndIf

If lRet
   aLogErro:= U_MTnTotalIt()[3] //Função dentro da User Function MT250SAL()
   If Len(aLogErro) > 0
      lRet := .F.

     aBotoes:={}
	 aAdd( aBotoes , { "" , {|| AVISO("ATENCAO",oLbxAux:aArray[oLbxAux:nAt][ 3 ],{"Fechar"},3) }	, "" , "Ver Erro"		  } )

	//    ITListBox(_cTitAux               , _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
      U_ITListBox( 'Relação dos Produtos com Problemas' ,;
	             {"Codigo","Produto","Erro"} , aLogErro , .T. , 1 , "Verifique o saldo dos Empenhos",,;
	             {      35,      090,   200} ,/*_nCampo*/ ,/*bOk*/,/*bCancel*/, aBotoes)
   EndIf
EndIf

SB1->(DBSetOrder(1))
SB1->(DBSeek(xFilial("SB1") + M->D3_COD ))

If lRet
	
	ZZL->( DBSetOrder(3) )
	If ZZL->( DBSeek( xFilial("ZZL") + RetCodUsr() ) )
		If ZZL->(FIELDPOS("ZZL_PEFRPA")) = 0 .Or. ZZL->ZZL_PEFRPA == "S"
			_lValidFrac1UM:=.F.
		EndIf
	EndIf
	ZZL->( DBSetOrder(1) )
	
	If _lValidFrac1UM .And. SB1->B1_TIPO == "PA"
		If (SB1->B1_UM == "UN" .And. M->D3_QUANT <> Int(M->D3_QUANT))
			U_ITMsg("Não é permitido fracionar a quantidade da 1a. UM de produto onde a Unid. Medida For UN.",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
		            "Validação Fracionado",;
			        "Favor informar apenas quantidades inteiras na Primeira Unidade de Medida. Valor digitado: "+AllTrim(Str(Int(M->D3_QUANT),22)),1)
			
			lRet := .F.
		EndIf
		If ( SB1->B1_SEGUM = "PC" .And. AllTrim(M->D3_COD) $ SuperGetMV("IT_NAOVLDP",.F.," ") .And. M->D3_QTSEGUM <> Int(M->D3_QTSEGUM) )//LEFT(M->D3_COD,4)=="0006"
			U_ITMsg("Não é permitido fracionar a quantidade da 2a. UM para produtos onde a Unid. Medida For PC.",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
			        "Validação Fracionado",;
			        "Favor informar apenas quantidades inteiras na Segunda Unidade de Medida. Valor digitado: "+AllTrim(Str(Int(M->D3_QTSEGUM),22)),1)
			lRet := .F.
		EndIf
	EndIf                                                                                    	
	
EndIf


If lRet .And. nQtde1UN # 0 .And. AllTrim(M->D3_COD) $ SuperGetMV("IT_NAOVLDP",.F.," ")//LEFT(M->D3_COD,4)=="0006" 
	
	nFtMin   := SB1->B1_I_FTMIN
	nFtMax   := SB1->B1_I_FTMAX
	c1UM     := SB1->B1_UM
	c2UM     := SB1->B1_SEGUM
	nVlrPeca := nQtde1UN / nQtde2UN
	
	If nFtMin > 0 .And. nFtMax > 0 .And. (nVlrPeca < nFtMin .Or. nVlrPeca > nFtMax) //Fora dos limites: menor que o Minimo ou maior que o Maximo
		
		cItens := "Conversão: "
		cItens += CVALTOCHAR( nQtde1UN ) +" "+c1UM+" / "
		cItens += CVALTOCHAR( nQtde2UN ) +" "+c2UM+" = "
		cItens += CVALTOCHAR( nVlrPeca ) +" "+c1UM+" / "+c2UM+CHR(13)+CHR(10)
		cItens += "Fatores do Cadastro do Produto:"+CHR(13)+CHR(10)
		cItens += "Fator Minimo: "+CVALTOCHAR( nFtMin )+" "+c1UM+" / "+c2UM+CHR(13)+CHR(10)
		cItens += "Fator Maximo: "+CVALTOCHAR( nFtMax )+" "+c1UM+" / "+c2UM

        bBloco:={||  AVISO("ATENCAO","Verifique as quantidades informadas para esse produto:"+ CHR(13) + CHR(10) + cItens,{"Fechar"},3) }

		U_ITMsg("Quantidades informadas (Quantidade/Qtd. 2a UM) para produto "+AllTrim(SB1->B1_DESC)+" não correspondem aos limites de fator de conversão.",;
		        "Validação fator conversão",;
		        "Verifique as quantidades informadas para esse produto: Clique em mais detalhes",1,,,,,,bBloco )
		
		lRet := .F.
		
	EndIf
EndIf

If lRet
   _aProdAlmo:= U_MTnTotalIt()[4] //Função dentro da User Function MT250SAL()
   If Len(_aProdAlmo) > 0    
      cItens:=""
      cItensB:=""
	  _cSpcC:=13
	  _cSpcT:=15
	  For y := 1 To Len(_aProdAlmo)
	      If Empty(_aProdAlmo[y,2])
             cItensB+=AllTrim(_aProdAlmo[y,1])+", "
	  	  Else
   	  	     cItens +=AllTrim(_aProdAlmo[y,1])+Space(_cSpcT)+_aProdAlmo[y,2]+CHR(13)+CHR(10)
	  	  EndIf
	  Next

      If !Empty(cItensB)
	     U_ITMsg("Existem produtos sem armazem, preencha-os na tela de ajuste de empenhos.","Atenção","Produtos: "+cItensB,1)
  
         Return .F.
  
	  EndIf

      bBloco:={||  AVISO("ATENCAO","  PRODUTO"+Space(_cSpcC)+"ARMAZEM"+CHR(13)+CHR(10)+cItens,{"Fechar"},3) }
  
	  If !(lRet:=U_ITMsg("Armazéns a serem consumidos não estão no pulmão de fábrica, deseja prosseguir o consumo do armazéns do almoxarifado?",;
	                     "Atenção","Clique em mais detalhes para ver os produtos",3,2,2,,,,bBloco))
  
	  	U_ITMsg("Altere os empenhos dos produtos para o armazém pulmão",;
	  	        "Atenção","Clique em mais detalhes para ver os produtos",1,,,,,,bBloco)
  
	  EndIf
   EndIf
EndIf

Return(lRet)

/*
===============================================================================================================================
Programa----------: Motivo()
Autor-------------: 
Data da Criacao---: 
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function Motivo()

Local  oTELA01
Local  cMotivo := SC2->C2_I_MOTIV
Local  lRet := .T.         
Local  oMotivo
Local  cNumOP := M->D3_OP

DEFINE MSDIALOG oTELA01 TITLE "Motivo de Ganho de produção/Produção a maior " FROM 000, 000  To 200, 400 Of oTELA01 Pixel
	@ 001,004 Say "Motivo: "
	@ 006,004 GET oMotivo Var cMotivo MEMO Size C(336),C(033) When .T. of oTELA01 PIXEL
	@ 056,067 BUTTON "&Confirma" SIZE 030,13 Pixel ACTION (GrvMotiv(cMotivo,cNumOP),oTELA01:End())
	@ 056,107 BUTTON "&Cancela"  SIZE 030,13 Pixel ACTION (lRet:=.F.,oTELA01:End())
ACTIVATE MSDIALOG oTELA01 CENTERED        

Return
 	
/*
===============================================================================================================================
Programa----------: GrvMotiv(cMotivo,cNumOP)
Autor-------------: 
Data da Criacao---: 
Descrição---------: 
Parametros--------: cMotivo,cNumOP
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function GrvMotiv(cMotivo,cNumOP)

DBSelectArea("SC2")
DBSetOrder(1)
DBSeek(xFilial("SC2")+cNumOP)

RecLock("SC2",.F.)
SC2->C2_I_MOTIV := cMotivo   
MSUnLock()

Return

/*
===============================================================================================================================
Programa----------: MTVusto()
Autor-------------: Alex Wallauer
Data da Criacao---: 19/12/2017
Descrição---------: Validação do custo medio
Parametros--------: Nenhum
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
Static Function MTVusto()
                         			
Local _nTotalIt:= U_MTnTotalIt()[1] //Função dentro da User Function MT250SAL()
Local _aMostaIt:= U_MTnTotalIt()[2] //Função dentro da User Function MT250SAL()
Local nCMAtu   := _nTotalIt / M->D3_QUANT//Custo medio de Produção
Local aCMLib   := U_VldCust(M->D3_COD, M->D3_LOCAL, dDataBase)
Local nCMLib   := aCMLib[1]//percentual liberado de diferença
Local nDifCM   := SuperGetMV("IT_DIFCMP",.F.,"00")
Local nDifCM2  := SuperGetMV("IT_DIFCMP2",.F.,50)
Local lRetorno := .T.

If _nTotalIt <= 0

   If U_ITMsg("Apontamento não permitido, o custo total da produção esta "+If(_nTotalIt=0,"zerado","menor que zero "+AllTrim(Str(_nTotalIt,15,2)))+"."+CHR(13)+CHR(10)+;
              "DESEJA  ANALISAR OS VALORES DOS PRODUTOS?","Atenção",;
	          "Favor analisar o Kardex! Se necessário, entre em contato com o Depto. de Custos.",1,2,2)
	       If Len(_aMostaIt) > 0
	
		      U_ITListBox( 'Relação dos Produtos' ,;
		             {"Codigo","Produto","Quantidade","Valor","Total"} , _aMostaIt , .F. , 1 , 'Análise dos valores dos Produtos: ',,;
		             {      35,       40,          35,     35,     35} )
           Else
              U_ITMsg("Não foram encotrados produtos para analizar","Atenção","Favor analisar os Empenhos! Se necessário, entre em contato com o Depto. de Custos.",1)
	       EndIf
    EndIf

	lRetorno := .F.

ElseIf nCMLib > 0
         //C M producao  //Custo medio atual
	nDifCus:= (nCMAtu - nCMLib) / nCMLib

	If nDifCus < 0
	   nDifCus := (nDifCus * (-1))
	EndIf

	nDifCus := nDifCus * 100
	
	If nDifCus >= nDifCM .And. nDifCus <= nDifCM2 //Diferenca entre 15% e 30%

		If U_ITMsg("Diferença entre valor de Custo Medio da producao e custo atual é "+AllTrim(TRANSFORM(nDifCus, "@E 999,999,999.99999"))+"%.",;
		           "Atençao","DESEJA  ANALISAR OS VALORES DOS PRODUTOS?",3,2,2)
	       If Len(_aMostaIt) > 0
		      U_ITListBox( 'Relação dos Produtos' ,;
		             {"Codigo","Produto","Quantidade","Valor","Total"} , _aMostaIt , .F. , 1 , 'Análise dos valores dos Produtos: ',,;
		             {      35,       40,          35,     35,     35} )
           Else
              U_ITMsg("Não foram encotrados produtos para analizar","Atenção","Favor analisar os Empenhos! Se necessário, entre em contato com o Depto. de Custos.",1)
			  lRetorno := .F.
	       EndIf
		EndIf

		If lRetorno .And. !U_ITMsg("Diferença entre valor de Custo Medio da producao e custo atual é "+AllTrim(TRANSFORM(nDifCus, "@E 999,999,999.99999"))+"%.","Atençao","DESEJA CONFIRMAR O APONTAMENTO?",3,2,2)
			lRetorno := .F.
		EndIf

	ElseIf nDifCus >= nDifCM2 //Diferenca maior que 30%

		If U_ITMsg("Produção não permitida! Diferença entre valor de Custo Medio da produção e o atual é "+AllTrim(TRANSFORM(nDifCus,"@E 999,999,999.9999"))+" %"+CHR(13)+CHR(10)+;
		           "Custo Unitário Atual: R$ "+AllTrim(TRANSFORM(nCMLib,"@E 999,999,999.99999"))+CHR(13)+CHR(10)+;
		           "Custo Unitário Produção: R$ "+AllTrim(TRANSFORM(nCMAtu,"@E 999,999,999.99999"))+CHR(13)+CHR(10)+;
		           "DESEJA  ANALISAR OS VALORES DOS PRODUTOS?",;
		           "Atenção",;
		           "Favor analisar o Kardex! Se necessário, entre em contato com o Depto. de Custos.",1,2,2)

	       If Len(_aMostaIt) > 0
		      U_ITListBox( 'Relação dos Produtos' ,;
		             {"Codigo","Produto","Quantidade","Valor","Total"} , _aMostaIt , .F. , 1 , 'Análise dos valores dos Produtos: ',,;
		             {      35,       40,          35,     35,     35} )
           Else
              U_ITMsg("Não foram encotrados produtos para analizar","Atenção","Favor analisar os Empenhos! Se necessário, entre em contato com o Depto. de Custos.",1)
	       EndIf

		EndIf           

		lRetorno := .F.
	EndIf
EndIf

Return lRetorno
