/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |18/07/2025| Chamado 49758. Ajustes nas telas de solicitações de justificativas para alterações de tipo de agendamento e data de entrega.
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
Julio Paz     |18/09/2025| Chamado 51806. Não permitir alterar o tipo de agendamento para R e N.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AOMS026
Autor-------------: Wodson Reis Silva
Data da Criacao---: 16/07/2009
Descrição---------: Rotina de alteracao de campos especificos do PV, sem perder liberação de estoque
Parametros--------: ExpC01 - Nome do alias em uso no Browse.
                    ExpN02 - Numero do Recno do alias em uso no Browse.
                    ExpN03 - Numero da opcao selecionada no menu lateral do Browse.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS026(cAlias,nReg,nOpc)

//Declaracao de Variaveis.                                
	Local oDlg
	Local oSay1
	Local oSay2
	Local oSay3
	Local oSay4
	Local oGetD
	Local aPosObj   := {}
	Local aObjects  := {}
	Local aSize     := {}
	Local aPosGet   := {}
	Local aRegSC6   := {}
	Local aInfo     := {}
	Local aButtons  := {}
	Local nCntFor   := 0
	Local lContinua := .T.
	Local nOpcA     := 0
	Local nLinGet   := 0
	Local nTamAcols := 1
	Local cCampo    := ""
	Local cArqQry   := ""
	Local aArea     := FWGetArea()
	Local lFreeze   := (SuperGetMv("MV_PEDFREZ",.F.,0) <> 0)
	Local nColFreeze:= SuperGetMv("MV_PEDFREZ",.F.,0)
	Local _lRet     := .T.
	Local oproc

	nOpc:=4//Força a linha de alteração do aRotina, pq a linha 13 vem como visualizar

	Private aCols     := {}
	Private aHeader   := {}
	Private aTES      := {}
	Private aNewTES   := {}
	Private aCpos1    := {}
	Private aCpos2    := {}
	Private aTELA[0][0]
	Private aGETS[0]

	Private aAreaSC5 := SC5->(GetArea())
	Private aAreaSC6 := SC6->(GetArea())
	Private aAreaSC9 := SC9->(GetArea())

	Private _cOperTriangular:= AllTrim(SuperGetMV("IT_OPERTRI",.F.,"05,42"))// Tipos de operações da operação trigular
	Private _cOperFat       := LEFT(_cOperTriangular,2)
	Private _cOperRemessa   := RIGHT(_cOperTriangular,2)
	Private _nRecOrigem     := SC5->(RECNO())

//============================================================================
//Roda processo de validação
//============================================================================
	FWMsgRun( ,{|oproc| _lRet := AOMS026V(oproc)}				, 'Aguarde!' , 'Verificando os dados...'  )
	If !_lRet

		Return

	EndIf

//============================================================================
//Indica as rotinas abaixo que se trata de alteracao                         
//=============================================================================
	ALTERA := .T.

//============================================================================
// Inicializa desta forma para criar uma nova instancia de variaveis Private 
//=============================================================================
	RegToMemory( "SC5", .F., .F. )

//============================================================================
//Montagem do aheader                                                        
//=============================================================================
	FillGetDados(1,"SC6",1,,,{||.T.},,,,,,.T.)

//============================================================================
//Montagem do aCols                                                          
//=============================================================================
	aCols := {}

	If ( lContinua )

		DBSelectArea("SC6")
		DBSetOrder(1)
		cArqQry := "SC6"
		MsSeek(xFilial("SC6")+SC5->C5_NUM)

		While ( (cArqQry)->(!Eof()) .And. (cArqQry)->C6_FILIAL == xFilial("SC6") .And.;
				(cArqQry)->C6_NUM == SC5->C5_NUM .And. lContinua )

			//============================================================================
			// Adiciona os campos no Acols.
			//=============================================================================
			aAdd(aCols,Array(Len(aHeader)+1))
			For nCntFor := 1 To Len(aHeader)
				cCampo := AllTrim(aHeader[nCntFor,2])
				If ( aHeader[nCntFor,10] # "V" .And. ! (cCampo $ "C6_QTDLIB/C6_ALI_WT/C6_REC_WT")) // cCampo <> "C6_QTDLIB"
					aCols[Len(aCols)][nCntFor] := FieldGet(FieldPos(cCampo))
				Else
					If cCampo == "C6_ALI_WT"
						aCols[Len(aCols)][nCntFor] := "SC6"
					ElseIf cCampo == "C6_REC_WT"
						aCols[Len(aCols)][nCntFor] := (cArqQry)->(RecNo())
					Else
						aCols[Len(aCols)][nCntFor] := CriaVar(cCampo)
					EndIf
				EndIf
			Next nCntFor

			aCols[Len(aCols)][Len(aHeader)+1] := .F.

			//=========================================================================
			//Guarda os registros do SC6 para posterior gravacao
			//==========================================================================
			aAdd(aRegSC6, (cArqQry)->(RecNo()) )

			(cArqQry)->(DBSkip())
		EndDo
	EndIf


//============================================================================
//Valida os itens do aCols                                                   
//=============================================================================
	If ( Len(aCols) == 0 )
		U_ITMsg("Não foram encontrdos itens nesse Pedido "+xFilial("SC6")+" "+SC5->C5_NUM,"Atenção","Contate a area de TI",1)//HELP(" ",1,"A440S/ITEM")
		lContinua := .F.
	EndIf

//============================================================================
// Verifica o tamanho do aCols para nao permitir inclusao de novas linhas.   
//=============================================================================
	nTamAcols := Len(aCols)

	While ( lContinua )

		lContinua:=.F.
		nOpcA:= 0
		aTela:={}
		aGets:={}
		//============================================================================
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

		DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],0 To aSize[6],aSize[5] of oMainWnd PIXEL

		EnChoice( cAlias, nReg, nOpc, , , , , aPosObj[1], aCPos1, 3 )

		oGetd := MsGetDados():New(aPosObj[2,1],aPosObj[2,2],aPosObj[2,3],aPosObj[2,4],nOpc,,,"",,aCPos2,nColFreeze,,nTamAcols,,,,,,lFreeze)

		nLinGet := aPosObj[3,1]

		@ nLinGet,aPosGet[1,1] Say oSAY1 VAR Space(40)             SIZE 120,09 PICTURE "@!"	OF oDlg PIXEL
		@ nLinGet,aPosGet[1,2] Say OemToAnsi("Total: ")            SIZE 020,09 OF oDlg	PIXEL
		@ nLinGet,aPosGet[1,3] Say oSAY2	VAR 0 PICTURE TM(0,16,2)  SIZE 040,09 OF oDlg PIXEL
		@ nLinGet,aPosGet[1,4] Say OemToAnsi("Desc. :")            SIZE 020,09 OF oDlg PIXEL
		@ nLinGet,aPosGet[1,5] Say oSAY3 VAR 0	PICTURE TM(0,16,2)  SIZE 040,09 OF oDlg PIXEL
		@ nLinGet + 10,aPosGet[1,4] Say OemToAnsi("=")             SIZE 020,09 OF oDlg PIXEL
		@ nLinGet + 10,aPosGet[1,5] Say oSAY4 VAR 0                SIZE 040,09 PICTURE TM(0,16,2) 	OF oDlg PIXEL
		oDlg:Cargo	:= {|c1,n2,n3,n4|  oSay1:SetText(c1),;
			oSay2:SetText(n2),;
			oSay3:SetText(n3),;
			oSay4:SetText(n4) }
		Ma410Rodap(oGetD)
		ACTIVATE MSDIALOG oDlg ON INIT EnchoiceBar(oDlg,{||nOpca:=1,If(oGetd:TudoOk(),oDlg:End(),nOpca := 0)},{||oDlg:End()},,aButtons)

		If ( nOpcA == 1 )
			_lOK:=.T.
			FWMsgRun(,{|oproc| _lOK:=AOMS026G(oproc) },"Processando","Aguarde....Gravando dados...")
			If !_lOK
				lContinua:=.T.
			EndIf
		EndIf

	EndDo

//=========================================================================
//Destravamento dos Registros                                             
//==========================================================================
	MSUnLockAll()
	FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa----------: AOMS026G
Autor-------------: Wodson Reis Silva
Data da Criacao---: 16/07/2009
Descrição---------: Gravacao dos dados alterados. 
Parametros--------: oproc - obejto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS026G(oproc As Object) As Logical

Local nX   := 0 As Numeric
Local _dDtAnt := SC5->C5_I_DTENT As Date
Local _cAgAnt := SC5->C5_I_AGEND As Character
Local _antsc5 := {} As Array
Local _oproc := Nil As Object
Local _nValorPedido := 0 As Numeric
Local _lOk := .T. As Logical
Local _cFilCarreg := "" As Character
Local _nPerSegFob := SuperGetMV('IT_PERSEGF',.F.,0.013) As Numeric
Local _cOperFret := SuperGetMV("IT_OPERFRE",.F.,"") As Character
Local _dDtCalcFr := Ctod(SuperGetMV("IT_DTCALCF",.F.,"23/06/2022")) As Date

Private _aLogSC5 := {} As Array
Private _aLogSC6 := {} As Array 
Private _cJustAG  := " " As Character // preenchido na função MT410_JA()
Private _cJustDE  := " " As Character // preenchido na função MT410_JA()
Private _cObseAG  := " " As Character // preenchido na função MT410_JA()
Private _cObseDE  := " " As Character // preenchido na função MT410_JA()
Private _lGrvMon  := .F. As Logical // preenchido no retorno da função MT410_JA() //GRAVA O MONITOR DEPOIS DE TODAS AS VALIDAÇÕES 
Private _lAltData := M->C5_I_DTENT <> _ddtant .And. M->C5_I_AGEND <> "I" As Logical //não é necessário justificar a alteração da data de entrega do pedido quando o pedido For Tp Entrega imediato (M->C5_I_AGEND = I)
Private _lAltAgen := M->C5_I_AGEND <> _cAgAnt As Logical
Private _lContOk  := ((SC5->C5_I_AGEND = "P" .And. _cAgAnt = "A") .Or. (SC5->C5_I_AGEND = "R" .And. _cAgAnt = "A") .Or. (SC5->C5_I_AGEND = "P" .And. _cAgAnt = "M") .Or. (SC5->C5_I_AGEND = "N" .And. _cAgAnt = "A")) As Logical

Default oproc := nil

SA1->( DBSetOrder(1) )
SA1->( DBSeek( xFilial('SA1') + M->( C5_CLIENTE + C5_LOJACLI ) ) )

Begin Sequence
	//============================================================================================================
	// Validação data de entrega.
	//============================================================================================================
	If DToS(M->C5_I_DTENT) < DToS(Date())
		U_MT_ITMSG("A data de entrega não pode ser menor que a data atual.","Atencao!","Informe uma data de entrega maior ou igual a data atual.",1)
		_lOk := .F.

		Break 
	EndIf 
	If M->C5_I_AGEND = 'M' .And. SA1->A1_I_AGEND <> M->C5_I_AGEND//Quando o PV é M o Cliente tem que ser tb

		U_MT_ITMSG('Pedido '+M->C5_NUM + " Tipo de Entrega do Cliente ["+SA1->A1_I_AGEND+"] diferente do informado no Pedido [M].", 'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM, ;
			'Cliente não pode ser Agendado c/ multa. Altere o Tipo de Entrega do Pedido para DIFERENTE de [M – AGENDADA C/ MULTA]',1)
		
		_lOk := .F.

		Break 
	EndIf

    If SC5->C5_I_AGEND <> M->C5_I_AGEND
       If M->C5_I_AGEND == "N" .Or. M->C5_I_AGEND == "R"
	      U_MT_ITMSG("Nesta rotina o tipo de agendamento não pode ser alterado para R-Reagendar ou N-Reagendar com Multa.", 'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM, ;
		             "Utilize a rotina de alteração de pedidos de vendas para alterar o tipo de agendamento para R-Reagendar ou N-Reagendar com Multa.",1)
	      _lOk := .F.
   	      Break  
       EndIf 
    EndIf 

	_lPrecisaPedir:=!(AllTrim(M->C5_I_OPER) $ AllTrim(SuperGetMV('IT_MPVOP',.T.,'50/51/02')))
	If _lPrecisaPedir .And. (_lAltData .Or. _lAltAgen)//Se é alteração valida com tela, vê se alterou a data de entrega ou o tipo de agendamento e pergunta o codigo e a obeservaçao da justificativa,  TEM TELA 

		//Se não For usuário autorizado faz validação de data de entrega
		If ! U_ITVACESS( 'ZZL' , 3 , 'ZZL_MNTDTE' , 'N' )
			
			_cFilCarreg := xFilial("SC5")
			If ! Empty(M->C5_I_FLFNC)
				_cFilCarreg := M->C5_I_FLFNC
			EndIf 
					//OMSVLDENT(_ddent       ,_cclient     ,_cloja        ,_cfilft       ,_cpedido  ,_nret,_lshow,_cFilCarreg,_cOperPedV  ,_cTipoVenda)
			If !(  u_omsvldent(M->C5_I_DTENT, M->C5_CLIENT, M->C5_LOJACLI, M->C5_I_FILFT, M->C5_NUM,0    ,      ,_cFilCarreg,M->C5_I_OPER,M->C5_I_TPVEN) ) //Valida data de entrega

				Break

			EndIf

		EndIf

		If _lAltData .Or. _lAltAgen//Se é alteração valida com tela, vê se alterou a data de entrega ou o tipo de agendamento e pergunta o codigo e a obeservaçao da justificativa,  TEM TELA 
			_lGrvMon:=MT410_JA()//PARA GRAVA NO ZY3 NA FUNÇÃO GrvMonitor() (XFUNOMS.PRW)
		EndIf

		If !_lGrvMon//nOpc == 0
			Break
			_lOk := .F.
		EndIf
	EndIf

	//=================================================================================
	// Inicia a gravação de Log, Tabelas SC5 e SC6.
	//=================================================================================
	_aLogSC5 := U_ITIniLog( 'SC5' )
	INILOG6(4 , _oproc, .F., .T.)

	//=========================
	// Gravacao do cabecalho.
	//==========================
	FWRestArea(aAreaSC5)
	RecLock("SC5",.F.)
	For nX := 1 To FCount() //Conta as colunas da tabela no banco, nao considera os campos virtuais
		aAdd(_antsc5,SC5->&(FieldName(nX)))
		If aScan(aCpos1,FieldName(nX)) > 0 .Or. fieldname(nx) == "C5_FECENT" //Verifica se o campo existe no array aCpos1 ou se é o fecent
			FieldPut(nX,M->&(FieldName(nX)))
		EndIf
	Next nX
	MSUnLock()

	//=================================================
	//Valida Desconto FOB
	//=================================================
//================================================================================
// Verifica se Desconto é mais que 10% do Total
//================================================================================

	SC6->( DBSetOrder(1) )
	If 	SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )

		While SC6->(!Eof()) .And. SC6->C6_FILIAL+SC6->C6_NUM == SC5->C5_FILIAL + SC5->C5_NUM

			_nValorPedido := (_nValorPedido + SC6->C6_VALOR)

			SC6->( DBSkip() )

		EndDo

	EndIf

	If M->C5_DESCONT >= _nValorPedido

		U_MT_ITMSG("Valor de desconto não pode ser maior que o valor total do pedido!",'Atencao! (MT410TOK-'+AllTrim(Str(ProcLine()))+') Ped.: '+M->C5_NUM,"Revise valor do desconto",1)
		_lOk := .F.

	EndIf

	//=================================================
	//Envia Interface de manutenção de pedido de vendas
	//=================================================
	If SC5->C5_I_ENVRD == "S" .And. GETMV("IT_ENVSIPV",,.T.)

		U_ENVSITPV(,.F.)   //Envia interface de alteração de situação do pedido atual

		If ZGA->ZGA_SITUAC != "P"

			U_ITMsg("Não foi possível alterar pedido no RDC, Alterações NAO seram salvas. Retorno  ["+AllTrim(ZGA->ZGA_RETORN)+"]","Falha de integração",,1)

			_lOk := .F.
		EndIf

	EndIf

	If _lOk 
		//==========================================================================================
		// Verifica e grava valor de seguro calculado sobre valor do pedido de vendas com impostos. 
		//==========================================================================================
		_lHabTpFFb := Posicione('SA1',1,xFilial("SA1")+SC5->(C5_CLIENTE+C5_LOJACLI),'A1_I_FOB')  
		
		If ValType(_lHabTpFFb) == "L" .And. _lHabTpFFb .And. SC5->C5_TPFRETE $ "F/D" .And. ! (SC5->C5_I_OPER $ _cOperFret) .And. DToS(SC5->C5_EMISSAO) >= DToS(_dDtCalcFr)
			MV_PAR04 := 2
			INCLUI := .F.
			ALTERA := .F.
			_nValTotImp := Ma410Impos( 6, .T., {}) // Total do Pedido de Vendas com impostos.
			_nValSeguro := _nValTotImp * _nPerSegFob / 100
			
			SC5->( RecLock( "SC5", .F. ) )
			SC5->C5_SEGURO := Round(_nValSeguro,2)
			SC5->( MSUnLock() )
		Else
			SC5->( RecLock( "SC5", .F. ) )
			SC5->C5_SEGURO := 0 
			SC5->( MSUnLock() )
		EndIf 
	EndIf

	If !_lOk
		//=========================
		// Estorno do cabecalho.
		//==========================
		FWRestArea(aAreaSC5)
		RecLock("SC5",.F.)
		For nX := 1 To FCount() //Conta as colunas da tabela no banco, nao considera os campos virtuais
			If aScan(aCpos1,FieldName(nX)) > 0 //Verifica se o campo existe no array aCpos1
				FieldPut(nX,_antsc5[nX])
			EndIf
		Next nX
		MSUnLock()

		Break // Return .F.

	EndIf

	//========================================
	// Gravação da data de entrega se alterou e se deu certo o envio do RDC
	//========================================
	If M->C5_I_DTENT != _ddtant
		M->C5_FECENT := M->C5_I_DTENT
		SC6->( DBSetOrder(1) )
		SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
		While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
			SC6->(RecLock("SC6",.F.))
			SC6->C6_ENTREG:=M->C5_I_DTENT
			SC6->(MSUnLock())
			SC6->( DBSkip() )
		EndDo
	EndIf

	If _lGrvMon//GRAVA O MONITOR AQUI POR JÁ PASSOU POR TODAS AS VALIDAÇÕES 
		//_cJustAG / _cJustDE / _cObseAG / _cObseDE  preenchidoS na função MT410_JA()
		SC5->( RecLock( "SC5", .F. ) )
		If _lContOk
			SC5->C5_I_QTDA := SC5->C5_I_QTDA+1//SOMA PARA CADA ALTERACAO EFETIVADA
		EndIf
		SC5->( MSUnLock() )

		_cFilCarreg := xFilial("SC5")
		If ! Empty(M->C5_I_FLFNC)
			_cFilCarreg := M->C5_I_FLFNC
		EndIf 
		_dDTNECE := M->C5_I_DTENT - (U_OMSVLDENT(M->C5_I_DTENT,M->C5_CLIENTE,M->C5_LOJACLI,M->C5_I_FILFT,M->C5_NUM,1, ,_cFilCarreg,M->C5_I_OPER,M->C5_I_TPVEN))

		If _lAltData
			_cCOMENT := "Data de entrega modificada de " + DToC(_ddtant) + " para " + DToC(M->C5_I_DTENT) + " via alteração de pedido de vendas."
						//_cFilial,_cNum,_cJUSCOD,_cCOMENT,_cLENCMON,_dDTNECE,_dDTFAT      ,_dDTFOLD, _cObserv, _cVinculoTb, _dDtSugAgen        
			U_GrvMonitor(        ,     ,_cJustDE,_cCOMENT,""       ,_dDTNECE,M->C5_I_DTENT,_ddtant ,_cObseDE)     
		EndIf
		If _lAltAgen
			_cCOMENT := "Tipo de Agendamento modificada de " + _cAgAnt + " para " + M->C5_I_AGEND + " via alteração de pedido de vendas."
						//_cFilial,_cNum,_cJUSCOD,_cCOMENT,_cLENCMON,_dDTNECE,_dDTFAT      ,_dDTFOLD, _cObserv, _cVinculoTb, _dDtSugAgen
			U_GrvMonitor(        ,     ,_cJustAG,_cCOMENT,""       ,_dDTNECE,M->C5_I_DTENT,_ddtant ,_cObseAG)     
		EndIf
	EndIf


	//======================================================================
	// Chama rotina de atualização das tabelas de muro para integração
	// com o RDC e atualização do pedido de vendas.
	//======================================================================
	U_AOMS084P(, ,"MANUTENCAO")

	//======================================================================
	// Grava log de alterações
	//======================================================================
	If Type('_aLogSC5') == 'A' .And. !Empty( _aLogSC5 )
		U_ITGrvLog( _aLogSC5 , "SC5" , 1 , SC5->( C5_FILIAL + C5_NUM ) , "A" , __cUserId , Date() , Time() )
	EndIf

	If Type('_aLogSC6') == 'A' .And. !Empty( _aLogSC6 )
		U_ITGrvLog( _aLogSC6 , "SC6" , 1 , SC5->( C5_FILIAL + C5_NUM ) , "A" , __cUserId , Date() , Time() )
	EndIf

End Sequence

//=======================================
// Restaura a area do cabecalho e item. 
//========================================
	FWRestArea(aAreaSC5)
	FWRestArea(aAreaSC6)

	If _lOk
		U_ITMsg("DADOS GRAVADOS COM SUCESSO - " + 'PEDIDO: '+SC5->C5_NUM, "Concluído", ,2)
	Else
		U_ITMsg("DADOS ALTERADOS NÃO FORAM GRAVADOS - " + 'PEDIDO: '+SC5->C5_NUM, "Concluído", ,2)
	EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS026V
Autor-------------: Wodson Reis Silva
Data da Criacao---: 16/07/2009
===============================================================================================================================
Descrição---------: Realiza validação do pedido
===============================================================================================================================
Parametros--------: oproc - obejto da barra de processamento
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS026V(oproc)

	Local _lRet := .T.
	Default oproc := nil

	ProcRegua(3)

//============================================================================
// Verifica se o Pedido ja foi faturado.                                     
//=============================================================================

	If ValType(oproc) = "O"

		oproc:cCaption := ("Verificando se pedido já foi faturado...")
		ProcessMessages()

	EndIf

//Verifica permissão de ajuste de bloqueio logístico
	If SC5->C5_I_BLOG == "S"

		ZZL->(DBSetOrder(3))
		If !(ZZL->(DBSeek(xFilial("ZZL") + RetCodUsr()))) .Or. ZZL->ZZL_PVLOG != "S"

			U_ITMsg("Usuário sem permissão para efetuar Manutenção, Pedido em Planejamento Logístico. Por favor entrar em contato com a área de Logística.","Atenção",,1)
			Return .F.

		EndIf

	EndIf

	If SC5->(FIELDPOS("C5_I_OPTRI")) # 0  .And. SC5->C5_I_OPER = _cOperFat

		U_ITMsg("Manutenção não permitida, Pedido de  Faturamento da Operação Triangular.",'Atenção! Ped.: '+SC5->C5_NUM,;
			"Acesse o Pedido de Remessa "+SC5->C5_I_PVREM+" para efetuar a manutenção",1)
		Return .F.

	EndIf

	If !Empty(SC5->C5_NOTA).Or.SC5->C5_LIBEROK=='E'

		U_ITMsg("Manutenção não permitida, Pedido já faturado.",'Atenção! Ped.: '+SC5->C5_NUM,,1)
		Return .F.
		//===================================================================================================
		//Arrays de controle dos campos que deverao ser alterados no cabecalho qdo Pedido ja Faturado.
		//====================================================================================================
		aCpos1 := AllTrim(GetMv("IT_CMPCAB1"))
		aCpos1 := If(Empty(aCpos1),{},&aCpos1)

		//================================================================================================
		//Arrays de controle dos campos que deverao ser alterados nos itens qdo Pedido ja Faturado.
		//=================================================================================================
		aCpos2 := AllTrim(GetMv("IT_CMPITE1"))
		aCpos2 := If(Empty(aCpos2),{},&aCpos2)
	Else
		//===================================================================================================
		//Arrays de controle dos campos que deverao ser alterados no cabecalho qdo Pedido Nao Faturado.
		//====================================================================================================
		aCpos1 := AllTrim(GetMv("IT_CMPCAB2"))
		aCpos1 := If(Empty(aCpos1),{},&aCpos1)

		//================================================================================================
		//Arrays de controle dos campos que deverao ser alterados nos itens qdo Pedido Nao Faturado.
		//=================================================================================================
		aCpos2 := AllTrim(GetMv("IT_CMPITE2"))
		aCpos2 := If(Empty(aCpos2),{},&aCpos2)
	EndIf

//============================================================================
//Verifica se pedido pode sofrer manutenção pelo RDC
//============================================================================
	If ValType(oproc) = "O"

		oproc:cCaption := ("Verificando se pode sofrer manutenção no RDC")
		ProcessMessages()

	EndIf

	If SC5->C5_I_ENVRD == "S" .And. GETMV("IT_ENVSIPV",,.T.)

		U_ENVSITPV(,.F.)   //Envia interface de alteração de situação do pedido atual

		If ZGA->ZGA_SITUAC != "P"

			U_ITMsg("Manutenção não permitida, Pedido já incluso em carga no RDC.",'Atenção! Ped.: '+SC5->C5_NUM,,1)

			Return .F.

		EndIf

	EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: INILOG6
Autor-----------: Julio de Paula Paz
Data da Criacao-: 22/10/2018
Descrição-------: Grava situação inicial do SC6 para log e alterações
Parametros------: _nopc - tipo de operação
				  oproc - objeto da barra de processamento
				  _lshow - se exibe objetos gráficos de interface
				  _lRet - status da validação geral
Retorno---------: _lRet - validação da condição
===============================================================================================================================
*/
Static Function INILOG6(_nopc,oproc,_lshow,_lRet)

Local _aCampos	:= {'C6_ITEM','C6_PRODUTO','C6_PRCVEN','C6_TES','C6_QTDVEN','C6_LOCAL','C6_PEDCLI'}
Local _lRetorno := .F.
Local _nI
Local _nTotCampos
Local _cCampo, _cCpoAux

Begin Sequence
	//Se validação não está mais válida já retorna false
	If !_lRet
		_lRetorno := .F.
		Break
	EndIf

	SC6->( DBSetOrder(1) )

	_nTotCampos := SC6->(FCount())

	If SC6->( DBSeek( SC5->( C5_FILIAL + C5_NUM ) ) )
		While SC6->(!Eof()) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->( C5_FILIAL + C5_NUM )
			For _nI := 1 To _nTotCampos
				_cCampo := AllTrim(SC6->(FieldName(_nI)))
				If !Empty(_aCampos) .And. aScan( _aCampos , _cCampo) == 0
					Loop
				Else
					_cCpoAux := "SC6->"+ _cCampo
					aAdd( _aLogSC6 , { SC6->( C6_FILIAL + C6_NUM + SC6->C6_ITEM ) , _cCampo , &_cCpoAux } )
				EndIf
			Next

			SC6->( DBSkip() )
		EndDo

	EndIf

End Sequence

Return _lRet

/*=============================================================================================================================
Programa----------: MT410_JA()
Autor-------------: Alex Wallauer
Data da Criacao---: 25/10/2023
Descrição---------: Ao alterar os campos C5_I_AGEND ou C5_I_DTENT, obrigar preenchimento do campo justificativa (ZY3_JUSCOD) 
                    especifica para esses campos e observação (ZY3_OBSERV) da justificativa com texto minimo de 10 caracteres
Parametros--------: Nenhum
Retorno-----------: Se .T. continua a as outras validações, se .F. nao volta pra tela de pedido sem fazer nada.
===============================================================================================================================*/
Static Function MT410_JA()

Local _lRet    := .F.
Local nLinha   := 10
Local _nCol1   := 05
Local _nCol2   := 40
Local _nCol3   := 90
Local _nTam    := 300

_cJustAG := Space(3)  // _aJustAG[1]
_cJustDE := Space(3)  // _aJustDE[1]
_cObseAG := Space(Len(ZY3->ZY3_OBSERV))
_cObseDE := Space(Len(ZY3->ZY3_OBSERV))

_cTitJus:="Justificativas das alterações"
_aFoders:={}
If _lAltAgen
   aAdd(_aFoders,"Tipo de Agendamento")
   _cTitJus+="de Data de Entrega"
EndIf
If _lAltData
   aAdd(_aFoders,"Data de Entrega")
   If _lAltAgen
      _cTitJus+=" e "
   EndIf
   _cTitJus+="do Tipo de Agendamento"
EndIf

While .T.

   DEFINE MSDIALOG _oDlg2 TITLE _cTitJus From 0,0 To 280, 700 PIXEL
                                                                       
	_nColFolder:=350
    _nLinFolder:=100
	nLinha:=1

    oTFolder1:= TFolder():New( nLinha,1,_aFoders,,_oDlg2,,,,.T., , _nColFolder,_nLinFolder )

    If _lAltAgen
        nLinha:=5
        @ nLinha,_nCol1 Say "Tipo de Agendamento de: "+U_TipoEntrega(SC5->C5_I_AGEND) OF oTFolder1:aDialogs[1] PIXEL

        nLinha+=15
        @ nLinha,_nCol1 Say "Tipo de Agendamento para: "+U_TipoEntrega(M->C5_I_AGEND) OF oTFolder1:aDialogs[1] PIXEL

        nLinha+=15
        @ nLinha+4,_nCol1 Say "Justificativas:"       OF oTFolder1:aDialogs[1] PIXEL
        @ nLinha,_nCol2 MSGET _cJustAG F3 "ZY5"   SIZE 30,010  Valid(MT410VLJUS(_cJustAG , "C5_I_AGEND")) PIXEL OF oTFolder1:aDialogs[1] WHEN _lAltAgen //MULTILINE
                
        nLinha+=20
        @ nLinha+2,_nCol1 Say  "Observação:" SIZE 060  ,007  PIXEL OF oTFolder1:aDialogs[1]
        @ nLinha,_nCol2 MSGet _cObseAG       SIZE _nTam,010  PIXEL OF oTFolder1:aDialogs[1] WHEN .F. 
    EndIf

///***********************  FOLDER 2 *************************************************
    If _lAltData
        nLinha:=5
        @ nLinha,_nCol1 Say "Data de Entrega de: "+DToC(SC5->C5_I_DTENT) OF oTFolder1:aDialogs[Len(_aFoders)] PIXEL

          nLinha+=15
        @ nLinha,_nCol1 Say "Data de Entrega para: "+DToC(M->C5_I_DTENT) OF oTFolder1:aDialogs[Len(_aFoders)] PIXEL

        nLinha+=15
        @ nLinha+4,_nCol1 Say "Justificativas:"           OF oTFolder1:aDialogs[Len(_aFoders)] PIXEL
        @ nLinha,_nCol2 MSGet _cJustDE  F3 "ZY5"  Valid(MT410VLJUS(_cJustDE , "C5_I_DTENT")) SIZE 030,010 PIXEL OF oTFolder1:aDialogs[Len(_aFoders)] WHEN _lAltData //MULTILINE

        nLinha+=20
        @ nLinha+2,_nCol1 Say  "Observação:" SIZE 060  ,007 PIXEL OF oTFolder1:aDialogs[Len(_aFoders)]
        @ nLinha,_nCol2 Get _cObseDE       SIZE _nTam,010 PIXEL OF oTFolder1:aDialogs[Len(_aFoders)] WHEN .F.
    EndIf
    nLinha+=60
    @ nLinha,_nCol3    Button "CONTINUAR" SIZE 50,15 ACTION ( _lRet := .T. ,_oDlg2:End()) PIXEL
       @ nLinha,_nCol3+99 Button "VOLTAR"    SIZE 50,15 ACTION ( _lRet := .F. ,_oDlg2:End()) PIXEL

   ACTIVATE MSDIALOG _oDlg2 

   If ! _lRet
   	  U_MT_ITMSG("Não foi selecionada/Digitada a Justificativa/Observação, alteração do Pedido NÃO será efetuada.","Atenção",,1)
   EndIf

   Exit
EndDo		

Return _lRet

/*
===============================================================================================================================
Programa----------: MT410VLJUS
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/05/2025
Descrição---------: Valida a digitação da justificativa de alteração de tipo de agendamenteo e alteração de data de entrega.
Parametros--------: _cDado  = Informação a ser validada
                    _cCampo = Campo que chamou a validação.
Retorno-----------: _lRet := .T. = Dados corretos
                             .F. = Erro nos dados
===============================================================================================================================
*/
Static Function MT410VLJUS(_cDado, _cCampo)

Local _lRet := .T.

Begin Sequence 
   
   If (_lAltData .And. Empty(_cDado)) .Or. (_lAltAgen .And. Empty(_cDado))
      U_MT_ITMSG("O código de justificativa não foi informado.","Atenção",,1)
      _lRet := .F.
      Break 
   EndIf 

   ZY5->(DBSetOrder(1))
   If ! ZY5->(MsSeek(xFilial("ZY5")+_cDado))
      U_MT_ITMSG("O código de justificativa informado não existe.","Atenção",,1)
      _lRet := .F.
   Else
      If _cCampo == "C5_I_AGEND"
         _cObseAG := ZY5->ZY5_DESCR
      Else
         _cObseDE := ZY5->ZY5_DESCR
      EndIf 
   EndIf 

End Sequence 

Return _lRet 
