/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor   |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich  | 30/08/2018 | Chamado 26085. Bloqueado desmembramento de PV de operação triangular.  
 Josué Danich  | 11/04/2019 | Chamado 28694. Validação de bloqueio de logística.  
 Lucas Borges  | 14/10/2019 | Chamado 28346. Removidos os Warning na compilação da release 12.1.25. 
 Jonathan      | 04/05/2020 | Chamado 32763. Alterar chamada "MsgBox" para "U_ITMsg". 
 Igor Melgaço  | 15/07/2021 | Chamado 37170. Retirada de validação de data de entrega devido a error.log. 
 Julio Paz     | 21/09/2021 | Chamado 31101. Alterar rotina p/considerar fator conversão Italac quando fator padrão For zero.
 Julio Paz     | 20/09/2022 | Chamado 41205. Alteração na forma de validar a terceira unidade de medida, para Qtde Fracionada.
 Julio Paz     | 13/03/2023 | Chamado 43219. Permitir desmembramento de Pedidos de Vendas operação Triangular (Tipo oper.42).  
 Alex Wallauer | 22/08/2023 | Chamado 44799. Ajuste da função ITMSG de erro para receber um texto do botão "Mais Detalhes".
===============================================================================================================================
===================================================================================================================================================================
Analista         - Programador     - Inicio     - Envio    - Chamado - Motivo da Alteração
===================================================================================================================================================================
Vanderlei Alves  - Alex Wallauer   - 09/06/25   - 10/06/25 - 45229   - Ajustes da mensagem de bloqueio para desmembramento de pedido de vendas.
===================================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "FONT.CH"
#Include 'totvs.ch'
#Include "RwMake.ch"

/*
===============================================================================================================================
Programa----------: AOMS099
Autor-------------: Josué Danich Prestes
Data da Criacao---: 06/04/2017
===============================================================================================================================
Descrição---------: Rotina desmembramento de Pedido de Vendas - Chamado 16681
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS099()

Local cAlias 	:= "SC5"
Local nReg 		:= SC5->(RECNO())
Local nOpc		:= 6
Local aPosObj   := {}
Local aObjects  := {}
Local aSize     := {}
Local aPosGet   := {}
Local aCpos1    := {;
	"C5_TRANSP ",;
	"C5_REDESP ",;
	"C5_FRETE  ",;
	"C5_VOLUME1",;
	"C5_VOLUME2",;
	"C5_VOLUME3",;
	"C5_VOLUME4",;
	"C5_ESPECI1",;
	"C5_ESPECI2",;
	"C5_ESPECI3",;
	"C5_ESPECI4",;
	"C5_PESOL  ",;
	"C5_PBRUTO ",;
	"C5_MENNOTA",;
	"C5_MENPAD ",;
	"C5_DESPESA",;
	"C5_SEGURO ",;
	"C5_FRETAUT",;
	"C5_RECFAUT",;	
	"C5_TPFRETE"}
Local aCpos2    := {}
Local aAddCpo   := {}
Local aInfo     := {}
Local _aitens	:= {}
Local lContinua := .T.
Local lQuery    := .F.
Local lFreeze   := (SuperGetMv("MV_PEDFREZ",.F.,0) <> 0)
Local nOpcA     := 0
Local nLinGet   := 0
Local nColFreeze:= SuperGetMv("MV_PEDFREZ",.F.,0)
Local cArqQry   := "SC6"
Local cQuery    := ""              
Local oDlg
Local oSay1
Local oSay2
Local oSay3
Local oSay4
Local oGetD

Local bCond     := {|| .T. }
Local bAction1  := {|| .T. }	
Local bAction2  := {|| .T. }
Local cSeek     := ""
Local aNoFields := {"C6_NUM","C6_QTDEMP","C6_QTDENT"}		// Campos que nao devem entrar no aHeader e aCols
Local bWhile    := {|| }  
Local nNumDec   := TamSX3("C6_VALOR")[2]
Local _nqtdven	:= 0
Local _nunsven	:= 0
Local _ndesm1	:= 0
Local _ndesm2	:= 0
Local _nprod	:= 0
Local _nitem	:= 0
Local _aRet 	:= {}
Local _nI		:= 0

Private aCols     := {}
Private aHeader   := {}
Private aTELA[0][0]
Private aGETS[0]   

//Valida Bloqueio Logístico
If SC5->C5_I_BLOG == "S"

	ZZL->(DBSetOrder(3))
	If !(ZZL->(DBSeek(xFilial("ZZL") + RetCodUsr()))) .Or. ZZL->ZZL_PVLOG != "S"

     	U_ITMsg("Usuário sem permissão para Desmembrar Pedido em Planejamento Logístico. Por favor entrar em contato com área de Logística","Atenção",,1)    	  	  
    	Return

	EndIf

EndIf

//=============================================================================
//Valida se é pedido que pode desmenbrar                      
//=============================================================================
If !Empty(SC5->C5_NOTA) .Or. !Empty(SC5->C5_LIBEROK) .Or. SC5->C5_I_ENVRD == "S"  .Or. SC5->C5_I_OPER == '05' //.OR. SC5->C5_I_OPER == '42' 

	U_ITMsg("Este pedido de venda não pode ser Desmembrado",;
			"ATENÇÃO",;
			"Favor selecionar um pedido de venda que esteja com o status verde (Em aberto) "+;
			"ou que não seja Pedido de Venda / Remessa da Operação Triangular e não esteja enviado para o TMS.",2,1)// ou que não tenha Pedido Vinculado
	
	Return
	
EndIf


//==========================================
//Grava log de utilização da rotina
//==========================================
U_ITLOGACS()

//=============================================================================
//Valida crédito
//=============================================================================
If  SC5->C5_TIPO = 'N' 

   _nTotPV:=0
   _lValCredito:=.T.
   
   SC6->(DBSetOrder(1))
   SC6->(DBGoTop())
   SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

   While SC6->C6_NUM == SC5->C5_NUM .And. SC5->C5_FILIAL == SC6->C6_FILIAL
	   
	      
	      _nTotPV += SC6->C6_VALOR

          If SC6->C6_PRODUTO == AllTrim(GetMV("IT_CCHEP")) .Or. SC6->C6_CF $ '5910/6910/5911/6911'//NÃO VALIDA CRÉDITO PARA PALLET CHEP E PARA BONIFICAÇÃO
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
	 
	 RecLock("SC5",.F.)
	 
	
	 If _aRetCre[2] = "B"//Se bloqueou
			
			If SC5->C5_I_BLCRE == "R"
				U_ITMsg("Avaliação de crédito do pedido não foi aprovada - " +;
						"O pedido continuará marcado como REJEITADO.","Atenção!", "(AOMS099-"+AllTrim(Str(ProcLine()))+") Ped.: "+SC5->C5_NUM,1)
						
				lBlq2			:= .T.
				SC5->C5_I_BLCRE	:= "R"
				SC5->C5_I_DTAVA := Date()
				SC5->C5_I_HRAVA := Time()
				SC5->C5_I_USRAV := cUserName
				SC5->C5_I_MOTBL := _cBlqCred
							
						
			Else
				U_ITMsg("Avaliação de crédito do pedido não foi aprovada - "	+;
						"O pedido será marcado como bloqueado para posterior avaliação.","Atenção!", "(AOMS099-"+AllTrim(Str(ProcLine()))+") Ped.: "+SC5->C5_NUM)
						
				lBlq2			:= .T.
				SC5->C5_I_BLCRE	:= "B"
				SC5->C5_I_DTAVA := Date()
				SC5->C5_I_HRAVA := Time()
				SC5->C5_I_USRAV := cUserName
				SC5->C5_I_MOTBL := _cBlqCred
								
            EndIf

	 EndIf

	 SC5->C5_I_MOTBL := _cBlqCred//Sempre grava a descrição
	 SC5->(MSUnLock())
  
  EndIf
  
EndIf


//=============================================================================
//Indica as rotinas abaixo que se trata de alteracao                         
//=============================================================================
ALTERA := .T.

//=============================================================================
//Arrays de controle dos campos que deverao ser alterados                    
//=============================================================================
aCpos2 := {"C6_I_DESM1 ","C6_I_DESM2"}

aAddCpo := {}


//=============================================================================
// Inicializa desta forma para criar uma nova instancia de variaveis Private 
//=============================================================================
RegToMemory( "SC5", .F., .F. )

//=============================================================================
//Trava os Registros                                                         
//=============================================================================
If ( !SoftLock(cAlias) )
	lContinua := .F.
EndIf                


//=============================================================================
//Montagem do aCols                                                          
//=============================================================================
If ( lContinua )
	DBSelectArea("SC6")
	DBSetOrder(1)
	If  aScan(aHeader,{|x| x[8] == "M"}) == 0
			lQuery  := .T.
			cQuery := "SELECT SC6.*,SC6.R_E_C_N_O_ SC6RECNO "
			cQuery += "FROM "+RetSqlName("SC6")+" SC6 "
			cQuery += "WHERE SC6.C6_FILIAL='"+xFilial("SC6")+"' AND "
			cQuery += "SC6.C6_NUM='"+SC5->C5_NUM+"' AND "
			cQuery += "SC6.D_E_L_E_T_<>'*' "
			cQuery += "ORDER BY "+SqlOrder(SC6->(IndexKey()))

			DBSelectArea("SC6")
			DBCloseArea()

	EndIf

	cSeek  := xFilial("SC6")+SC5->C5_NUM
	bWhile := {|| C6_FILIAL+C6_NUM }
	
	//=========================================================
	// Montagem do aHeader e aCols                           
	//=========================================================
	//==============================================================================================================
	//FillGetDados( nOpcx, cAlias, nOrder, cSeekKey, bSeekWhile, uSeekFor, aNoFields, aYesFields, lOnlyYes,       
	//				  cQuery, bMountFile, lInclui )                                                                
	//nOpcx			- Opcao (inclusao, exclusao, etc).                                                         
	//cAlias		- Alias da tabela referente aos itens                                                          
	//nOrder		- Ordem do SINDEX                                                                              
	//cSeekKey		- Chave de pesquisa                                                                            
	//bSeekWhile	- Loop na tabela cAlias                                                                        
	//uSeekFor		- Valida cada registro da tabela cAlias (retornar .T. para considerar e .F. para desconsiderar 
	//				  o registro)                                                                                  
	//aNoFields	- Array com nome dos campos que serao excluidos na montagem do aHeader                         
	//aYesFields	- Array com nome dos campos que serao incluidos na montagem do aHeader                         
	//lOnlyYes		- Flag indicando se considera somente os campos declarados no aYesFields + campos do usuario   
	//cQuery		- Query para filtro da tabela cAlias (se For TOP e cQuery estiver preenchido, desconsidera     
	//	           parametros cSeekKey e bSeekWhiele)                                                              
	//bMountFile	- Preenchimento do aCols pelo usuario (aHeader e aCols ja estarao criados)                     
	//lInclui		- Se inclusao passar .T. para qua aCols seja incializada com 1 linha em branco                 
	//aHeaderAux	-                                                                                              
	//aColsAux		-                                                                                              
	//bAfterCols	- Bloco executado apos inclusao de cada linha no aCols                                         
	//bBeforeCols	- Bloco executado antes da inclusao de cada linha no aCols                                     
	//bAfterHeader -                                                                                              
	//cAliasQry	- Alias para a Query                                                                           
	//==============================================================================================================
	FillGetDados(4,"SC6",1,cSeek,bWhile,{{bCond,bAction1,bAction2}},aNoFields,/*aYesFields*/,/*lOnlyYes*/,cQuery,/*bMontCols*/,Inclui,/*aHeaderAux*/,/*aColsAux*/,,/*bBeforeCols*/,/*bAfterHeader*/,"SC6")
		
	nProduto := aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})
	
	asize(aHeader,Len(aHeader)+2)
	ains(aHeader,8)
	ains(aHeader,8)
	
	aHeader[8] := aHeader[1]
	aHeader[9] := aHeader[1]
	
	ndesm1   := aScan(aHeader,{|x| AllTrim(x[2])=="C6_I_DESM1"})
	ndesm2   := aScan(aHeader,{|x| AllTrim(x[2])=="C6_I_DESM2"})
	
	nold1 := ndesm1
	nold2 := ndesm2 
	
	aHeader[8] := aHeader[ndesm2]
	aHeader[9] := aHeader[ndesm1]
	
	adel(aheader,ndesm2)
	asize(aHeader,Len(aHeader)-1)

	adel(aheader,ndesm1)
	asize(aHeader,Len(aHeader)-1)
	
	ndesm1   := aScan(aHeader,{|x| AllTrim(x[2])=="C6_I_DESM1"})
	ndesm2   := aScan(aHeader,{|x| AllTrim(x[2])=="C6_I_DESM2"})
	
	For _nI := 1 to Len(acols)
	
		asize(acols[_nI],Len(acols[_nI])+2)
		ains(acols[_nI],8)
		ains(acols[_nI],8)
		
		adel(acols[_nI],nold1)
		asize(acols[_nI],Len(acols[_nI])-1)
		
		adel(acols[_nI],nold2)
		asize(acols[_nI],Len(acols[_nI])-1)
		
		acols[_nI][8] := 0
		acols[_nI][9] := 0
		
	Next
		
	
	If ( lQuery )
		DBSelectArea(cArqQry)
		DBCloseArea()
		ChkFile("SC6",.F.)
		DBSelectArea("SC6")
	EndIf

EndIf
If  ( lContinua )

	//=============================================================================
	//Calculo das dimensoes da Janela                                            
	//=============================================================================
	aSize    := MsAdvSize()
	aObjects := {}
	aAdd( aObjects, { 100, 100, .T., .T. } )
	aAdd( aObjects, { 100, 100, .T., .T. } )
	aAdd( aObjects, { 100, 015, .T., .F. } )

	aInfo   := { aSize[ 1 ],aSize[ 2 ],aSize[ 3 ],aSize[ 4 ],03,03 }
	aPosObj := MsObjSize( aInfo, aObjects )
	aPosGet := MsObjGetPos(aSize[3]-aSize[1],315,{{003,157,189,236,268}})

	DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],0 to aSize[6],aSize[5] of oMainWnd PIXEL

	EnChoice( cAlias, nReg, nOpc, , , , , aPosObj[1], aCPos1, 3 )
	
	oGetd   :=  MsGetDados():New(aPosObj[2,1],aPosObj[2,2],aPosObj[2,3],aPosObj[2,4],nOpc,,,"",,aCPos2,nColFreeze,,,,,,,,lFreeze)	

	nLinGet := aPosObj[3,1]

	@ nLinGet,aPosGet[1,1] Say oSAY1 VAR Space(40)               	SIZE 120,09 PICTURE "@!"	OF oDlg PIXEL
	@ nLinGet,aPosGet[1,2] Say "Total :"                         	SIZE 020,09 OF oDlg	PIXEL  //
	@ nLinGet,aPosGet[1,3] Say oSAY2 VAR 0 PICTURE TM(0,16,nNumDec) SIZE 040,09 OF oDlg PIXEL
	@ nLinGet,aPosGet[1,4] Say "Desc. :"                         	SIZE 020,09 OF oDlg PIXEL 	
	@ nLinGet,aPosGet[1,5] Say oSAY3 VAR 0 PICTURE TM(0,16,nNumDec) SIZE 040,09 OF oDlg PIXEL
	@ nLinGet + 10,aPosGet[1,4] Say OemToAnsi("=")               	SIZE 020,09 OF oDlg PIXEL
	@ nLinGet + 10,aPosGet[1,5] Say oSAY4 VAR 0                  	SIZE 040,09 PICTURE TM(0,16,nNumDec) OF oDlg PIXEL
	oDlg:Cargo	:= {|c1,n2,n3,n4|  oSay1:SetText(c1),;
		oSay2:SetText(n2),;
		oSay3:SetText(n3),;
		oSay4:SetText(n4) }											
	Ma410Rodap(oGetD)
	ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,{||nOpca:=1,If(oGetd:TudoOk(),oDlg:End(),nOpca := 0)},{||oDlg:End()})

	SetKey(VK_F4,)

	If ( nOpcA == 1 )
	
		_nqtdven	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_QTDVEN"})
		_nunsven	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_UNSVEN"})
		_ndesm1		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_I_DESM1"})
		_ndesm2		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_I_DESM2"})
		_nprod		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})
		_nitem		:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_ITEM"})	
	
		//Monta array para função de desmembramento
		_aitens := {}
		_nI := 1
				
		
		While _nI <= Len(acols)
		
		
			aAdd(_aitens,{acols[_nI][_nitem],acols[_nI][_ndesm1]})
			
			_nI++
			
		EndDo
		
		Begin Transaction

		   Processa({|| _aRet := U_AOMS098(SC5->C5_FILIAL,SC5->C5_NUM,_aitens) }, "Desmembrando pedido...")
		
		   If _aRet[1]
		
			  U_ITMsg("Pedido desmembrado com sucesso, novo pedido criado: " + AllTrim(_aRet[2]),"NOVO PEDIDO",,2)
			
		   Else
		      DisarmTransaction()
		      _cErro:=If(!Empty(_aRet[4]),AllTrim(_aRet[4]),AllTrim(_aRet[3]))
			  //U_ITMsg("Falha ao desmembrar pedido, Erro: " + _cErro,"Problemas","Clique mais detalhes e verifique o(s) erro(s) e Tente novamente",1)

              U_ITMsg("Falha ao desmembrar pedido. Clique em mais detalhes",;//,_ntipo,_nbotao,_nmenbot,_lHelpMvc,_cbt1,_cbt2,_bMaisDetalhes
                      "Validação Fracionado","Verifique o(s) erro(s) e Tente novamente"         ,1     ,       ,        ,         ,     ,     ,;
                      {|| U_ITMsgLog("Validação Italac (_cAOMS074Vld)"+CHR(13)+CHR(10)+_aRet[5] +CHR(13)+CHR(10)+;
					                 "Validação Padrão (MostraErro())"+CHR(13)+CHR(10)+_aRet[6], "ATENCAO",1,.F.)   } )
			
		   EndIf
	    End Transaction      
	
	EndIf

EndIf

MSUnLockAll()

Return

/*

/*
===============================================================================================================================
Programa----------: AOMS099V
Autor-------------: Josué Danich Prestes
Data da Criacao---: 06/04/2017
===============================================================================================================================
Descrição---------: Valida quantidade a desmembrar e gatilha unidades
===============================================================================================================================
Parametros--------: _ncampo - 1 para campo de unidade e 2 para campo de 2a. unidade
===============================================================================================================================
Retorno-----------: Valida valor no campo
===============================================================================================================================
*/
User Function AOMS099V(_ncampo)

Local _lRet 	:= .T.
Local _n1UM   	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_UM" })
Local _n2UM   	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_SEGUM"  })
Local _nqtdven	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_QTDVEN" })
Local _nunsven	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_UNSVEN" })
Local _ndesm1	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_I_DESM1"})
Local _ndesm2	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_I_DESM2"})
Local _nprod	:= aScan(aHeader,{|x| AllTrim(x[2])=="C6_PRODUTO"})
Local _nLocal   := aScan(aHeader,{|x| AllTrim(x[2])=="C6_LOCAL"  })
Local _nFatConv 

SB1->(DBSetOrder(1))
SB1->(MsSeek(xFilial("SB1")+acols[n][_nprod]))

_nFatConv := SB1->B1_CONV 

If SB1->B1_CONV == 0      
   _nFatConv := SB1->B1_I_FATCO
EndIf 

If _ncampo == 1 //Campo 1a. unidade

  //valida quantidade
  If M->C6_I_DESM1 < 0 .Or. M->C6_I_DESM1 > acols[n][_nqtdven]
  	 alert("Quantidade a desmontar negativa ou maior que a quantidade vendida!")
  	 Return .F.
  EndIf
  
  //If Posicione("SB1",1,xFilial("SB1")+acols[n][_nprod],"B1_TIPCONV") == "D"
  If SB1->B1_TIPCONV == "D"
 	 _nfc := 1 / _nFatConv // SB1->B1_CONV
  Else
 	 _nfc := _nFatConv //SB1->B1_CONV
  EndIf
  	
  //Se é valor válido gatilha segunda unidade
  If _nfc # 0 .Or. M->C6_I_DESM1 = 0
     acols[n][_ndesm2] := M->C6_I_DESM1 * _nfc
  EndIf

  _lRet:=AOMS99Val(acols[n][_nprod] , acols[n][_nLocal] , M->C6_I_DESM1 , acols[n][_ndesm2] , acols[n][_n1UM] , acols[n][_n2UM] , _nfc , _ncampo   )

  If !_lRet
     acols[n][_ndesm2] := 0
  EndIf
  
Else//Campo 2a. unidade

 //valida quantidade
  If M->C6_I_DESM2 < 0 .Or. M->C6_I_DESM2 > acols[n][_nunsven]
	 alert("Quantidade a desmontar negativa ou maior que a quantidade vendida!")
	 Return .F.  		
  EndIf
  
  //If Posicione("SB1",1,xFilial("SB1")+acols[n][_nprod],"B1_TIPCONV") == "D"
  If SB1->B1_TIPCONV == "D"
  	 _nfc := _nFatConv // SB1->B1_CONV
  Else
  	 _nfc := 1 / _nFatConv // SB1->B1_CONV
  EndIf
  	
  //Se é valor válido gatilha primeira unidade  
  If _nfc # 0 .Or. M->C6_I_DESM2 = 0
     acols[n][_ndesm1] := M->C6_I_DESM2 * _nfc
  EndIf

  _lRet:=AOMS99Val(acols[n][_nprod] , acols[n][_nLocal] , acols[n][_ndesm1] , M->C6_I_DESM2 , acols[n][_n1UM] , acols[n][_n2UM] , _nfc ,_ncampo )

  If !_lRet
     acols[n][_ndesm1] := 0
  EndIf

EndIf



Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS099E
Autor-------------: Josué Danich Prestes
Data da Criacao---: 06/04/2017
===============================================================================================================================
Descrição---------: Determinar se quantidade a desmembrar é editável
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _lRet - Abre ou nção campo para edição
===============================================================================================================================
*/
User Function AOMS099E()

Local _lRet := FWIsInCallStack("U_AOMS099") //Só habilita na tela de desmembramento

Return _lRet


//=====================================================================================
//
//=====================================================================================

/*
===============================================================================================================================
Programa----------: AOMS099E
Autor-------------: Josué Danich Prestes
Data da Criacao---: 06/04/2017
===============================================================================================================================
Descrição---------: Validação de quantidade fracionada e limite de converção do queijo
===============================================================================================================================
Parametros--------: cProd,cLocal,nQtde1UN,nQtde2UN,c1UM,c2UM,_nfc,_ncampo
===============================================================================================================================
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
Static Function AOMS99Val(cProd,cLocal,nQtde1UN,nQtde2UN,c1UM,c2UM,_nfc,_ncampo)

Local _cFilOper:= U_ITGETMV( "IT_FILOPE" , "  ")//Filiais a serem validadas
Local _cOperEst:= U_ITGETMV( "IT_OPEEST" , "  ")//Tipos de operações a serem validados
Local _cProdPe := U_ITGETMV( "IT_PRODPE" , "  ")//Produtos permitidos
//Local _cPrd3Um := U_ITGETMV( "IT_PRD3UM" , "  ")//Produtos a validar pela 3ª unidade de medida
Local _cLocval := U_ITGETMV( "IT_LOCFRA" , "  ")//Armazéns que não valida quantidade fracionada
Local lRet     := .T.
Local _cCrtl3Um := "N" // Produtos a validar quantidade fracionada na terceira unidade de medida.

If cFilAnt $ _cFilOper
	If !(M->C5_I_OPER $ _cOperEst)
		If !(AllTrim(cProd) $ _cProdPe)
			If !(AllTrim(cLocal) $ _cLocval)
	           
	            SB1->(DBSetOrder(1))
				SB1->(DBSeek(xFilial("SB1") + AllTrim(cProd)))

                //==============================================================
                // Validar as quantidades fracionadas 3 unidade de medida. 
                //==============================================================
                _cCrtl3Um := Posicione("SBZ",1,cFilAnt+cProd,"BZ_I_PR3UM")
                If _cCrtl3Um == "S"
                   If Mod(nQtde1UN , SB1->B1_I_QT3UM) <> 0    
				     //If (AllTrim(cProd) $ _cPrd3Um)
					 // If nQtde1UN / SB1->B1_I_QT3UM <> Int(nQtde1UN / SB1->B1_I_QT3UM)
			           cItens := "Calculo: "
			           cItens += CVALTOCHAR( nQtde2UN ) +" "+c2UM
                       If SB1->B1_TIPCONV == "D"//Como é segunda unidade o operador é invertido
			              cItens += " x " + CVALTOCHAR( SB1->B1_CONV ) +" "+c2UM+"/"+c1UM+" = "
                       Else
			              cItens += " / " + CVALTOCHAR( SB1->B1_CONV ) +" "+c2UM+"/"+c1UM+" = "
                       EndIf			           
			           cItens += CVALTOCHAR( nQtde1UN ) +" "+c1UM+" / "
			           cItens += CVALTOCHAR( SB1->B1_I_QT3UM ) +" "+c1UM+"/"+SB1->B1_I_3UM+" = "
			           cItens += CVALTOCHAR( nQtde1UN / SB1->B1_I_QT3UM )+" "+SB1->B1_I_3UM

						U_ITMsg("O produto "+AllTrim(SB1->B1_DESC)+" não pode ser vendido com quantidade fracionada na Terceira Unidade de Medida.",;
						        "Validação Fracionado",;
						        "Verificar calculo da Terceira Unidade de Medida [ " + SB1->B1_I_3UM + " ], pois não pode haver quantidades fracionadas:"+ CHR(13) + CHR(10) + cItens,1)
						lRet := .F.
					EndIf
				Else
					If nQtde2UN <> Int(nQtde2UN)
						U_ITMsg("O produto " +AllTrim(SB1->B1_DESC)+" não pode ser vendido com quantidade fracionada na Segunda Unidade de Medida.",;
						        "Validação Fracionado",;
						        "Favor informar apenas quantidades inteiras na Segunda Unidade de Medida.",1)
						lRet := .F.
					EndIf
				EndIf

			EndIf
		EndIf
	EndIf
EndIf

If lRet
	
	SB1->( DBSetOrder(1) )
	SB1->( DBSeek( xFilial("SB1") + cProd ) )
	
	If SB1->B1_I_SFCON == "1" 
		
		If nQtde2UN <> Int(nQtde2UN)
			U_ITMsg("O produto " +AllTrim(SB1->B1_DESC)+" não pode ser vendido com quantidade fracionada na Segunda Unidade de Medida.",;
			"Validação Fracionado",;
			"Favor informar apenas quantidades inteiras na Segunda Unidade de Medida.",1)
			lRet := .F.
			
		EndIf
		
		If lRet .And. nQtde1UN # 0 .And. nQtde2UN # 0
			
			nFtMin   := SB1->B1_I_FTMIN
			nFtMax   := SB1->B1_I_FTMAX
			nVlrPeca := nQtde1UN / nQtde2UN
			
			If (nVlrPeca < nFtMin .Or. nVlrPeca > nFtMax) //Fora dos limites: menor que o Minimo ou maior que o Maximo
				
				cItens := "Conversão: "
				cItens += CVALTOCHAR( nQtde1UN ) +" "+c1UM+" / "
				cItens += CVALTOCHAR( nQtde2UN ) +" "+c2UM+" = "
				cItens += CVALTOCHAR( nVlrPeca ) +" "+c1UM+"/"+c2UM+CHR(13)+CHR(10)
				cItens += "Fator Minimo: "+CVALTOCHAR( nFtMin )+" "+c1UM+"/"+c2UM+CHR(13)+CHR(10)
				cItens += "Fator Maximo: "+CVALTOCHAR( nFtMax )+" "+c1UM+"/"+c2UM
				
				U_ITMsg("Quantidades informadas (Quantidade/Qtd. 2a UM) para produto "+AllTrim(SB1->B1_DESC)+" não correspondem aos limites de fator de conversão.",;
				"Validação fator conversão",;
				"Verifique as quantidades informadas para esse produto:"+ CHR(13) + CHR(10) + cItens,1 )
				
				If SB1->B1_CONV # 0 .Or. _nCampo = 1 //Para não travar o campo quando tiver fator de conversão maxima e minima no campo qtd 2n Desm
					lRet := .F.
				EndIf
				
			EndIf
		EndIf
		
	EndIf
	
EndIf

//================================================================================
//  Valida o preenchimento da segunda unidade de medida
//================================================================================
Return lRet
