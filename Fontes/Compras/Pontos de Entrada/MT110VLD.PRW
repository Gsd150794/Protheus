/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |19/10/2017| Chamado: 22048. Inclusão de validação na rotina de cópia de solicitação de compras, para não permitir
              |          | a cópia de solicitação de compras por usuários que não estejam cadastrados como aprovadores/solicitantes
              |          | e com situação igual a normal.
Jonathan      |04/05/2020| Chamado 32763. Alterar chamada "MsgBox" para "U_ITMsg".
Julio Paz     |27/09/2022| Chamado 41388. Ajustar mensagens nas validações das solicitação de compras.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT110VLD
Autor-------------: Guilherme D. Gesualdo
Data da Criacao---: 15/08/2012
Descrição---------: Ponto de Entrada para verificar a linha posicionada na Solicitacao de Compra antes da selecao da acao.
                    Bloqueio de alteracao de solicitacao de compra efetuada por outro usuario.    
                    ------------------------------------------------------------------------------------------------------
                    ExecBlock: MT110VLD                   
                    Ponto: Verifica o registro posicionado antes das operacoes.
                    Parametros Enviados: Retorno Logico .T. ou .F.             
                    Observacoes: Bloqueia a alteracao da solicitacao por outro usuario
                    Retorno Esperado: .T. ou .F. 
                    ------------------------------------------------------------------------------------------------------
                    Ponto de entrada chamado na cópia da solicitação de compras quando a variável lCopia == .T.
                    Realiza uma Pré-Validação permitindo ou não a cópia da solicitação de compras.
Parametros--------: Nenhum
Retorno-----------: Retorno Logico (.T. ou .F.) permitindo ou nao a alteracao.
===============================================================================================================================
*/
User Function MT110VLD

Local ExpN1		:= ParamIXB[1]
Local ExpL1		:= .T.   //Validações do ClienteReturn ExpL1
Local _aArea	:=	FWGetArea()
Local _cUsuAlt	:= 	__cUserId
Local _cSolic	:= SC1->C1_I_CDSOL 
Local cPedido	:= SC1->C1_NUM
Local nRecAtu	:= SC1->(Recno())
Local aMensagem	:= {}
Local aProbl	:= {}
Local aSoluc	:= {}
Local lContinua	:= .T.

Private NCONTT	:= 0

//==============================================================================
//Verifica se foi utilizada a opção de cópia, se sim, desconsidera as validações
//==============================================================================
If !lCopia 
	If ExpN1 == 6
		If SC1->C1_APROV <> 'B'
			lContinua	:= .F.
			ExpL1		:= .F.
			
			aProbl := {}
			aAdd(aProbl, "Esta solicitação não pode ser excluída.")
			
			aSoluc := {}
			aAdd(aSoluc, "Solicitações com status Rejeitada ou Aprovada, não podem ser excluídas.")
			
			aMensagem := {"Ação Não Permitida", aProbl, aSoluc}
		
			U_ITMsHTML(aMensagem)
		EndIf
	EndIf
	
	If lContinua
		//=====================================================================================================================
		// Valida se o usuário corrente existe na tabela de cadastro de solicitante e aprovadores, e se este não está bloqueado
		//=====================================================================================================================
		DBSelectArea("ZZ7")
		DBSetOrder(1)
		If !DBSeek(xFilial("ZZ7") + _cUsuAlt)
			ExpL1 := .F.
			U_ITMsg("O usuário logado não está cadastrado como Solicitante ou Aprovador, usuario: " + __cUserId + " - " + AllTrim(UsrFullName(__cUserId)),"ATENCAO", "Solicitar ao Depto. de compras que realize o cadastro do solicitante/aprovador para usuário citado: " + __cUserId + " - " + AllTrim(UsrFullName(__cUserId)),1)
		Else
			If ZZ7->ZZ7_STATUS == "B"
				ExpL1 := .F.
				U_ITMsg("O usuário logado está Bloqueado no cadastrado de Solicitante / Aprovador, usuario: " + __cUserId + " - " + AllTrim(UsrFullName(__cUserId)),"ATENCAO", "Solicitar ao Depto. de compras que desbloqueie o usuário citado no cadastro de solicitantes/aprovadores: " + __cUserId + " - " + AllTrim(UsrFullName(__cUserId)),1)
			EndIf
		EndIf
		
		If ExpN1 = 4 .And. ExpL1 //ALTERACAO
		   	If _cSolic <> _cUsuAlt 
			 	ExpL1 := .F. 
		   	   	FWRestArea(_aArea)
		   		U_ITMsg("Solicitacao nao podera ser alterada, pois a mesma foi incluida pelo usuario: "+SC1->C1_I_CDSOL + " - "+AllTrim(UsrFullName(SC1->C1_I_CDSOL)),"ATENCAO","Solicitacao nao podera ser alterada, pois a mesma foi incluida pelo usuario: "+SC1->C1_I_CDSOL + " - "+AllTrim(UsrFullName(SC1->C1_I_CDSOL)),1)
		   	EndIf        
		   	
			If _cSolic = _cUsuAlt // 29/01/13 - Inicio da validação para bloquear a alteração dos pedidos que tenham sidos liberados.
		   	   
				DBSelectArea("SC1") 
		   	 	DBSetOrder (1)	   
		   	 	DBSeek (xFilial("SC1")+SC1->C1_NUM)
		   	 	
				While SC1->(!Eof()) .And. SC1->C1_NUM = cPedido
					If SC1->C1_QUJE==0.And.(SC1->C1_COTACAO==Space(Len(SC1->C1_COTACAO)).Or.SC1->C1_COTACAO=="IMPORT").And. SC1->C1_APROV="B" 
						SC1->( DBSkip()) 
					Else  
						SC1->( DBSkip())
						NCONTT:=NCONTT+1  	
					EndIf  
				EndDo
		      
				If NCONTT >=1
					ExpL1 := .F.
					U_ITMsg("Esse pedido não pode ser alterado pois possui itens liberado.","ATENCAO","Esse pedido não pode ser alterado pois possui itens liberado.",1)
				Else
					ExpL1 := .T.
				EndIf 
			EndIf   //Fim da validação
		EndIf
		
		DBSelectArea("SC1")
		DBGoTo(nRecAtu)
		
		If !Empty(SC1->C1_CODCOMP) .And. ExpN1 == 4 .And. ExpL1
			ExpL1 := .F.
			U_ITMsg("Solicitação não poderá ser alterada, pois a mesma já possui comprador indicado.","ATENCAO","Solicitação não poderá ser alterada, pois a mesma já possui comprador indicado.",1)
		EndIf
	EndIf
Else
   //=========================================================================
   // Quando For uma cópia, valida se o usuário está cadastrado no cadastro 
   // de solicitantes.
   //=========================================================================   
   ZZ7->(DBSetOrder(1)) // ZZ7_FILIAL+ZZ7_CODUSR                                                                                                                                           
   If ! ZZ7->(DBSeek(xFilial("ZZ7")+AllTrim(__cUserId)))
      U_ITMsg("Para copiar uma solicitação de compras, você deve estar cadastrado no cadastro de Aprovadores/Solicitantes.","Atenção", ,1) 
      ExpL1 := .F.
   ElseIf AllTrim(ZZ7->ZZ7_STATUS) <> "N"
      U_ITMsg("Para copiar uma solicitação de compras, você deve estar cadastrado no cadastro de Aprovadores/Solicitantes e deve estar com situação igual a normal.","Atenção", ,1) 
      ExpL1 := .F.
   EndIf
EndIf

FWRestArea(_aArea)
             
Return(ExpL1)
