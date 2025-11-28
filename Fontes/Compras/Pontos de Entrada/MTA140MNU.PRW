/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |14/06/2019| Chamado 29654. Valida estoque negativo retroativo.
Lucas Borges  |04/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Lucas Borges  |14/09/2025| Chamado 50617. Modificada a chamada dos parâmetros para a SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MTA140MNU
Autor-------------: Alex Wallauer
Data da Criacao---: 17/02/2017
Descrição---------: PE de ajuste do menu de ações relacionadas da tela de pré notas de entrada
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MTA140MNU

Local _nPos:=aScan(aRotina, {|R| Upper(R[2]) == Upper("A140EstCla") } )

If _nPos # 0
   aRotina[_nPos][2] := "U_MA140EstCla"
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MA140EstCla
Autor-------------: Alex Wallauer
Data da Criacao---: 17/02/2017
Descrição---------: Chamada de função de validação e estorno de documento de entrada
Parametros--------: Nenhum
===============================================================================================================================
*/
User Function MA140EstCla(cAlias,nReg,nOpc)

Local oproc

FWMsgRun(,{|oproc| U_MA140EXE(cAlias,nReg,nOpc, oproc) }, "Aguarde...","Validando estorno de documento de entrada...")

Return .T.

/*
===============================================================================================================================
Programa----------: MA140EXE
Autor-------------: Alex Wallauer
Data da Criacao---: 17/02/2017
Descrição---------: Validação e exclusão de estorno de classificação de documento de entrada
Parametros--------: Nenhum
===============================================================================================================================
*/
User Function MA140EXE(cAlias,nReg,nOpc,oproc)

Local _lRet:=.T.
Private _lUsuConfirmou:=.F.//Variavel Private usada do rdmake MT100GRV.PRW

Begin Sequence

//Valida se não vai gerar saldos negativos
_agetsd1 := SD1->(Getarea())
SD1->(DBSetOrder())
_aerros := {}
	   
If SD1->(DBSeek(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))

	_cchav := SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA

	While SD1->D1_FILIAL+SD1->D1_DOC+SD1->D1_SERIE+SD1->D1_FORNECE+SD1->D1_LOJA == _cchav
    	If  Posicione("SF4",1,xFilial("SF4")+SD1->D1_TES,"F4_ESTOQUE") = "S" 
			_aneg := U_VldEstRetrNeg(SD1->D1_COD,SD1->D1_LOCAL,SD1->D1_QUANT,SD1->D1_DTDIGIT)
			If Len(_aneg) > 0
				nDif := _aNeg[2] - SD1->D1_QUANT
			 	aAdd(_aErros,{SD1->D1_COD,Posicione("SB1",1,xFilial("SB1")+SD1->D1_COD,"B1_DESC"),SD1->D1_LOCAL,DToC(_aNeg[1]),Transform(nDif,"@E 999,999,999.99")})
				_lRet := .F.
			EndIf
 		EndIf
		SD1->(DBSkip())
	EndDo

	If !_lRet
		aCampPla := {"Produto","Descr","Armazém","Data","Diferença"}
		_odet := {|| U_ITListBox( 'Produtos com saldo negativo' , aCampPla , _aerros , .T. , 1 )}
		 U_ITMsg( "Quantidade a estornar é maior que o saldo diário em um ou mais produtos","MTA140MNU001",;
		 			"Verique os produtos e datas no botão mais detalhes e confira com o kardex",2,,,,,,_odet)
 		Break
	EndIf
EndIf

SD1->(FWRestArea(_agetsd1))

BEGIN Transaction

	//Estorna transferências de leite cru
	//Localiza movimento de estorno
	oproc:cCaption := ("Verificando transferência de produto a granel...")
	ProcessMessages()
		
	SD3->(DBSetOrder(13)) //D3_FILIAL + D3_CHAVEF1
	If SD3->(DBSeek(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_TIPO))  
		While AllTrim(SD3->D3_FILIAL + SD3->D3_CHAVEF1) == AllTrim(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_TIPO)
			If SD3->D3_ESTORNO != 'S'
				oproc:cCaption := ("Estornando transferência de produto a granel...")
				ProcessMessages()
			
				//Faz estorno
				_ddataori := ddatabase
				ddatabase := SD3->D3_EMISSAO
				aAuto := {}   
				lMsErroAuto  := .F.                       
				MSExecAuto({|x,y| mata261(x,y)},aAuto,6) 
				
				ddatabase := _ddataori
				
				If lMsErroAuto .Or. SD3->D3_ESTORNO != 'S'  
					U_ITMsg( 'Existe transferência de leite cru a granel e não foi possível estornar', 'MTAA140MNU002',;
						'Realize o estorno da transferência manualmente -> DOC ' + SD3->D3_DOC  , 1 )
					_lRet := .F.			
				EndIf
			Else
				SD3->(DBSkip())
			EndIf
		EndDo
	EndIf

	If !_lRet 
		Disarmtransaction() //Se falhou estorno de transferência ou não completou eexclusão do documento de entrada faz rollback
		BREAK
	EndIf

	//Verifica troca nota relacionado
	oproc:cCaption := ("Verificando pedidos de troca nota...")
	ProcessMessages()

	_cRetorno:=U_PosPedFaT( SF1->F1_FORNECE+SF1->F1_LOJA , SF1->F1_DOC+SF1->F1_SERIE )//Essa funcao (MT100TOK.PRW) deve ser executa quando vc tá na filial de faturmento SEMPRE

	If _cRetorno == "ACHOU_PF"
		oproc:cCaption := ("Estornando liberação de pedidos de troca nota...")
		ProcessMessages()

		_lRet:=U_MT100PedAlt( SC5->(RECNO()) )//Estorna a liberação do pedido

		Pergunte("MTA140",.F.)//Restaura as variaveis MV_PAR?? do programa "MTA140"

		If !_lRet
			DisarmTransaction()
			BREAK
		EndIf
	Else
		_lUsuConfirmou:=.T.//.T. pq se não For troca nota nunca vai executar DisarmTransaction()
	EndIf

	oproc:cCaption := ("Estornando classificação do documento de entrada...")
	ProcessMessages()

	A140EstCla(cAlias,nReg,nOpc)//Função Padrão

	If !_lUsuConfirmou
		DisarmTransaction()
	EndIf

END Transaction

End Sequence

//Garante desbloqueio de locks e final de transações abertas
//Se For do mglt009 não faz aqui pois está dentro da transação
If !IsInCallStack("U_MGLT009") .And. SuperGetMV("IT_F1UNL",.T.,.T.)
	Dbcommit()
	Dbcommitall()
	Dbunlock()
EndIf
   
Return.T.
