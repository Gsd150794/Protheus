/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |10/01/2024| Chamado 46030. Corrigido a atulização do status dos convênios
Lucas Borges  |11/02/2025| Chamado 49877. Removido tratamento sobre a versão do Mix
Lucas Borges  |26/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include 'FWEVENTVIEWCONSTS.CH'

/*
===============================================================================================================================
Programa----------: MGLT010
Autor-------------: Wodson Reis
Data da Criacao---: 14/10/2008
Descrição---------: Rotina desenvolvida para possibilitar o CANCELAMENTO do Acerto do Leite junto aos produtores.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT010

Local _cPerg  		:= 'MGLT010' As Character
Local _oProces		:= NIL As Object

tNewProcess():New(	_cPerg						,; // cFunction. Nome da função que está chamando o objeto
					"Cancelamento Fechamento do Leite Próprio"	,; // cTitle. Título da árvore de opções
					{|_oProces| MGLT010R(_oProces) },; // bProcess. Bloco de execução que será executado ao confirmar a tela
					"Essa rotina tem por objetivo processar o 'Cancelamento do Fechamento do Leite Próprio' "+;
					"excluindo todos os títulos e notas emitidos.",; // cDescription. Descrição da rotina
					_cPerg						,; // cPerg. Nome do Pergunte (SX1) a ser utilizado na rotina
					{}							,; // aInfoCustom. Informações adicionais carregada na árvore de opções. Estrutura:[1] - Nome da opção[2] - Bloco de execução[3] - Nome do bitmap[4] - Informações do painel auxiliar.
					.F.							,; // lPanelAux. Se .T. cria um novo painel auxiliar ao executar a rotina
					0							,; // nSizePanelAux. Tamanho do painel auxiliar, utilizado quando lPanelAux = .T.
					''							,; // cDescriAux. Descrição a ser exibida no painel auxiliar
					.T.							,; // lViewExecute. Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento
					.F.							,; // lOneMeter. Se .T. cria apenas uma régua de processamento
					.T.							)  // lSchedAuto. Se .T. habilita o botão de processamento em segundo plano (execução ocorre pelo Scheduler)

Return

/*
===============================================================================================================================
Programa----------: MGLT5Exec
Autor-------------: Wodson Reis
Data da Criacao---: 14/10/2008
Descrição---------: Função para chamar as Rotinas de cancelamento do acerto.
Parametros--------: _oProces - Objeto de controle do processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT010R(_oProces As Object)

Local _cArqLog	:= "LOG_FECHAMENTO_LEITE_"+ DToS( Date() ) +"_"+ StrTran( Time() , ":" , "" ) +"_"+ RetCodUsr() +".log" As Character
Local _cPthLog	:= "\data\italac\MGLT010\" As Character
Local _cDirTmp	:= GetTempPath() As Character
Local _cHoraIni	:= '' As Character
Local _cHoraFim	:= '' As Character
Local _nTempM	:= 0 As  Numeric
Local _cAlias	:= GetNextAlias() As Character
Local _cFiltro	:= "%" As Character
Local _nCont	:= 1 As Numeric
Local _nTotPrd	:= 0 As Numeric
Local _nProd	:= 0 As Numeric
Local _cSetor	:= "" As Character
Local _cLinha	:= "" As Character
Local _cUpdate	:= "" As Character
Local _lSemNota	:= .F. As Logical
Local _lOk		:= .T. As Logical
Local _cSetores	:= AllTrim(MV_PAR02) As Character
Local _cCodMix	:= MV_PAR01 As Character
Local _cProdDe	:= MV_PAR03 As Character
Local _cProdAte	:= MV_PAR04 As Character
Local _cLojaDe	:= MV_PAR05 As Character
Local _cLojaAte	:= MV_PAR06 As Character
Local _cRotaDe	:= MV_PAR07 As Character
Local _cRotaAte	:= MV_PAR08 As Character
Local _cMotBaixa:= AllTrim(SuperGetMV("LT_MOTBX",.F.,"GLT")) As Character// Motivo de baixa utilizado para a rotina do Leite
Local _cParam	:= "" As Character
Local _cMenAux	:= "" As Character
Local _nReg		:= 0 As Numeric
Local _aCab		:= {} As Array
Local _aItens	:= {} As Array
Local _oFile	:= Nil As Object

Private lMsErroAuto	:= .F. As Logical
Private lMsHelpAuto	:= .T. As Logical
Private _cThread:= CValToChar(ThreadID()) As Character

_cParam := "Filial: " + cFilAnt
_cParam += "Mix: " + MV_PAR01
_cParam += "Setor: " + AllTrim(MV_PAR02)
_cParam += "Fornecedor: " + MV_PAR03 +"-"+MV_PAR04
_cParam += "Loja: " + MV_PAR05 +"-"+MV_PAR06
_cParam += "Linha: " + MV_PAR07 +"-"+MV_PAR08
_cParam += "Usuario: " + UsrFullName(__cUserId)
EventInsert(FW_EV_CHANEL_ENVIRONMENT, FW_EV_CATEGORY_MODULES, "Z01", FW_EV_LEVEL_INFO, "", "Início Cancelamento do Leite",_cParam , .T.) //CHAMADA DO EVENTO

_oProces:SaveLog("Thread:"+_cThread+" Iniciando a rotina. Parâmetros: "+MV_PAR01+"-"+AllTrim(MV_PAR02)+"-"+MV_PAR03+"-"+MV_PAR04+"-"+MV_PAR05+"-"+MV_PAR06+"-"+MV_PAR07+"-"+MV_PAR08)

_oProces:SetRegua1(3)//01-Inicializando/02-Selecionando produtores/03-Concluindo Fechamento
_oProces:SetRegua2(1)
_oProces:IncRegua1('Processo [01] - Inicializando a rotina... [Aguarde!]')
_oProces:IncRegua2('Verificando a configuração dos parâmetros no MIX...')

//Se não preencheu e não tem acesso a todos, aborta processamento
If !(!Empty(_cSetores) .Or. Empty(_cSetores) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") == 'S')
	_cMenAux:= "Não foram informados setores válidos para o usuário."
	_oProces:SaveLog("Thread:"+_cThread+" MGLT01001 - Fim do processamento. "+_cMenAux)
	FWAlertWarning(_cMenAux,"MGLT01001")
	Return
EndIf

_oFile:= FWFileWriter():New(_cPthLog + _cArqLog)

If !_oFile:Create()
	_cMenAux:= "O Arquivo de Log não foi criado! Favor acionar a TI."
	_oProces:SaveLog("Thread:"+_cThread+" MGLT01002 - Fim do processamento. "+_cMenAux)
	FWAlertError(_cMenAux,"MGLT01002")
	Return
Else
	_oFile:Write('====================================================================================================' + CRLF )
	_oFile:Write(' Log de Processamento - Cancelamento do Fechamento do Leite - Data: '+ DToC( Date() )				  + CRLF )
	_oFile:Write(' [ Para abrir o LOG no Excel, exclua os comentários do início e fim e salve o arquivo como ".CSV" ] ' + CRLF )
	_oFile:Write(' [ Se não existirem registros, todos foram processados com sucesso ou nenhum foi processado ] '       + CRLF )
	_oFile:Write('====================================================================================================' + CRLF )
	_oFile:Write('Produtor;Loja;Setor;Linha/Rota;Processo;Erro;Tempo' + CRLF )
EndIf

_cHoraIni := Time()

If !Empty(_cSetores)
	_cFiltro += " AND E2_L_SETOR IN "+ FormatIn(AllTrim(_cSetores),';')
EndIf
_cFiltro += '%'
//================================================================================
// Query para constatar se existem dados a serem excluidos na database posicionada
// pelo usuario, para que nao ocorra problemas no cancelamento
//================================================================================
BeginSql alias _cAlias
	SELECT COUNT(1) NUMREG
	  FROM %Table:SE2%
	 WHERE E2_FILIAL = %xFilial:SE2%
	   AND E2_TIPO = 'NF '
	   AND E2_FORNECE LIKE 'P%'
	   %exp:_cFiltro%
	   AND E2_FORNECE BETWEEN %exp:_cProdDe% AND %exp:_cProdAte%
	   AND E2_LOJA BETWEEN %exp:_cLojaDe% AND %exp:_cLojaAte%
	   AND E2_L_MIX = %exp:_cCodMix%
	   AND E2_L_LINRO BETWEEN %exp:_cRotaDe% AND %exp:_cRotaAte%
	   AND E2_EMISSAO = %exp:dDataBase%
	   AND D_E_L_E_T_ = ' '
EndSql

If (_cAlias)->NUMREG == 0
	_cMenAux:= 'Não foram encontrados dados no financeiro para realizar o cancelamento dos produtores.'
	_oProces:SaveLog("Thread:"+_cThread+" MGLT01017 - Fim do processamento. "+_cMenAux)
	_oFile:Write(_cMenAux +' Favor checar se os dados fornecidos para o cancelamento estão corretos, e se a database informada é a mesma'+;
	 	' da realização do fechamento que esta sendo solicitado o cancelamento. - MGLT01017'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF )
	_lOk := .F.
EndIf  

(_cAlias)->(DBCloseArea())

//================================================================================
// Posiciona no cadastro de MIX
//================================================================================
DBSelectArea("SF1")
DBSelectArea("SD1")
DBSelectArea("SE2")
DBSelectArea("ZLE")
ZLE->( DBSetOrder(1) )
If _lOk .And. ZLE->( DBSeek( xFilial("ZLE") + _cCodMix) )
	
	//================================================================================
	// Chama funcao para criar tabela Temporaria
	//================================================================================
	_oProces:IncRegua1('Processo [02] - Selecionando Produtores... [Aguarde!]')
	_oProces:IncRegua2('Processando...')
	_cFiltro := "%"
	If !Empty(_cSetores) //Se o parametro com os setores estiver vazio considera todos.
		_cFiltro += " AND ZLF_SETOR IN "+ FormatIn(AllTrim(_cSetores),';')
	EndIf
	_cFiltro += "%"

	BeginSql alias _cAlias
		SELECT ZLF_SETOR, ZLF_LINROT, ZLF_A2COD, ZLF_A2LOJA
		  FROM %Table:ZLF%
		 WHERE ZLF_FILIAL = %xFilial:ZLF%
		   %exp:_cFiltro%
		   AND ZLF_A2COD BETWEEN %exp:_cProdDe% AND %exp:_cProdAte%
		   AND ZLF_A2LOJA BETWEEN %exp:_cLojaDe% AND %exp:_cLojaAte%
		   AND ZLF_LINROT BETWEEN %exp:_cRotaDe% AND %exp:_cRotaAte%
		   AND ZLF_CODZLE = %exp:_cCodMix%
		   AND ZLF_A2COD LIKE 'P%'
		   AND ZLF_ACERTO = 'S'
		   AND ZLF_TP_MIX = 'L'
		   AND D_E_L_E_T_ = ' '
		   AND EXISTS (
			   	SELECT 1
					FROM %Table:SF1%
					WHERE F1_FILIAL = %xFilial:SF1%
					AND F1_FORNECE = ZLF_A2COD
					AND F1_LOJA = ZLF_A2LOJA
					AND F1_L_MIX = %exp:_cCodMix%
					AND F1_L_SETOR = ZLF_SETOR
					AND F1_L_LINHA = ZLF_LINROT
					AND F1_EMISSAO = %exp:dDataBase%
					AND F1_FORMUL = 'S' 
					AND D_E_L_E_T_ = ' ')
		 GROUP BY ZLF_SETOR, ZLF_LINROT, ZLF_A2COD, ZLF_A2LOJA
		 UNION
		SELECT ZLF_SETOR, ZLF_LINROT, ZLF_A2COD, ZLF_A2LOJA
		  FROM %Table:ZLF%
		 WHERE ZLF_FILIAL = %xFilial:ZLF%
		   %exp:_cFiltro%
		   AND ZLF_A2COD BETWEEN %exp:_cProdDe% AND %exp:_cProdAte%
		   AND ZLF_A2LOJA BETWEEN %exp:_cLojaDe% AND %exp:_cLojaAte%
		   AND ZLF_LINROT BETWEEN %exp:_cRotaDe% AND %exp:_cRotaAte%
		   AND ZLF_CODZLE = %exp:_cCodMix%
		   AND ZLF_A2COD LIKE 'P%'
		   AND ZLF_ACERTO = 'S'
		   AND ZLF_TP_MIX = 'L'
		   AND ZLF_F1SEEK <> ' '
		   AND D_E_L_E_T_ = ' '
		   GROUP BY ZLF_SETOR, ZLF_LINROT, ZLF_A2COD, ZLF_A2LOJA
		 ORDER BY ZLF_SETOR, ZLF_LINROT, ZLF_A2COD, ZLF_A2LOJA
	EndSql

	Count To _nProd
	(_cAlias)->(DBGoTop())
	_oProces:SetRegua1(_nProd)
	
	DBSelectArea("SA2")
	While (_cAlias)->( !Eof() )
		_nTempM	:= Seconds()
		_oProces:SetRegua2(1)//01-Inicializando/02-Cancelando Baixas a Pagar/03-Excluindo documento de entrada/04-Atualizando Status nas tabelas do Leite
		_oProces:IncRegua1('Produtor ['+ StrZero(_nCont,6) +'] de ['+ StrZero(_nProd,6) +'] - '+ (_cAlias)->ZLF_A2COD +'/'+ (_cAlias)->ZLF_A2LOJA +' - Setor: '+ (_cAlias)->ZLF_SETOR +' - Linha/Rota: '+ (_cAlias)->ZLF_LINROT)
		_oProces:IncRegua2('Processo [01] - Inicializando...')

		SA2->( DBSetOrder(1) )
		If SA2->( DBSeek( xFilial("SA2") + (_cAlias)->ZLF_A2COD + (_cAlias)->ZLF_A2LOJA ) )
			//Indica se o fechamento vai gerar a nota ou se o produtor irá emitir a NFe
			_lSemNota := IIf(SA2->A2_L_NFPRO == "S", .T.,.F.)
			_cSetor := (_cAlias)->ZLF_SETOR
			_cLinha := (_cAlias)->ZLF_LINROT
		Else		
			_lOk := .F.
			_cMenAux:= SA2->A2_COD +';'+ SA2->A2_LOJA +';'+ _cSetor +';'+ _cLinha +';Posicionando registros;Falha ao posicionar no cadastro do Produtor!'
			_oProces:SaveLog("Thread:"+_cThread+" MGLT01003 - Fim do processamento. "+_cMenAux)
			_oFile:Write(_nHdlLog , _cMenAux + ' - MGLT01003;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF )
		EndIf
		
		If _lOk
			BEGIN TRANSACTION
			//================================================================================
			// Cancela Baixas
			//================================================================================
			_oProces:SetRegua2(1)
			_oProces:IncRegua2('Processo [02] - Cancelando Baixas a Pagar... [Aguarde!]')
			_lOk := CancBxSE2( _oProces, _cCodMix, _cSetor, _cLinha, _cMotBaixa, _nTempM )
			
			//================================================================================
			// Exclui documento de entrada
			//================================================================================
			_oProces:SetRegua2(1)
			_oProces:IncRegua2('Processo [03] - Excluindo documento de entrada...')
			If _lOk .And. _lSemNota
				//Os títulos manuais incluídos no fechamento já foram excluídos pela CancBxSE2
			ElseIf _lOk
				_cAliasSF1	:= GetNextAlias()
				BeginSql Alias _cAliasSF1
					SELECT R_E_C_N_O_
					FROM %Table:SF1%
					WHERE F1_FILIAL = %xFilial:SF1%
					AND F1_FORNECE = %exp:SA2->A2_COD%
					AND F1_LOJA = %exp:SA2->A2_LOJA%
					AND F1_L_MIX = %exp:_cCodMix%
					AND F1_L_SETOR = %exp:_cSetor%
					AND F1_L_LINHA = %exp:_cLinha%
					AND F1_EMISSAO = %exp:dDataBase%
					AND F1_FORMUL = 'S'
					AND D_E_L_E_T_ = ' '
				EndSql
				
				SF1->(DBGoTo((_cAliasSF1)->R_E_C_N_O_))
				Count To _nReg
				(_cAliasSF1)->(DBCloseArea())

				If _nReg > 1
					_lOk := .F.
					_cMenAux:= SA2->A2_COD +';'+ SA2->A2_LOJA +';'+ _cSetor +';'+ _cLinha +';Exclusão do Documento de Entrada!;Foram identificadas mais de uma nota para o produtor'
					_oProces:SaveLog("Thread:"+_cThread+" MGLT01013 - Fim do processamento. "+_cMenAux)
					_oFile:Write(_cMenAux + ' - MGLT01013;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF )
				Else
					_aCab := {	{ "F1_DOC"		, SF1->F1_DOC		, NIL } ,;
								{ "F1_SERIE"	, SF1->F1_SERIE		, NIL } ,;
								{ "F1_FORNECE"	, SF1->F1_FORNECE	, NIL } ,;
								{ "F1_LOJA"	  	, SF1->F1_LOJA		, NIL } ,;
								{ "F1_TIPO"		, SF1->F1_TIPO		, NIL } }
			
					//Não seria necessário passar os itens, mas se isso não For feito, é necessirio ajustar o MT103EXC pois o aCols estará vazio. 
					//Seu conteúdo estará no aColSD1.
					SD1->(DBSetOrder(1))
					SD1->(DBSeek(SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA), .T. ))
					While SD1->(!Eof()) .And. SD1->(D1_FILIAL+D1_DOC+D1_SERIE+D1_FORNECE+D1_LOJA) == SF1->(F1_FILIAL+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA)
						aAdd( _aItens , {	{ "D1_ITEM"		, SD1->D1_ITEM	, NIL } ,; // Sequencia Item Pedido
											{ "D1_COD"		, SD1->D1_COD	, NIL } ,; // Codigo do Produto
											{ "D1_QUANT"	, SD1->D1_QUANT	, NIL } ,; // Quantidade
											{ "D1_VUNIT"	, SD1->D1_VUNIT	, NIL } ,; // Valor Unitario
											{ "D1_TOTAL"	, SD1->D1_TOTAL	, NIL } }) // Valor Total
						SD1->( DBSkip() )
					EndDo
					MSExecAuto( { |x,y,z| MATA103(x,y,z) }, _aCab,_aItens,5) //Exclusão
						
					If lMsErroAuto
						_lOk := .F.
						_cMenAux:= SA2->A2_COD +';'+ SA2->A2_LOJA +';'+ _cSetor +';'+ _cLinha +';Exclusão do Documento de Entrada!;Falha no ExecAuto ['+SF1->(F1_DOC+F1_SERIE)+'] '+MostraErro()
						_oProces:SaveLog("Thread:"+_cThread+" MGLT01014 - Fim do processamento. "+_cMenAux)
						_oFile:Write(_cMenAux + ' - MGLT01014;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF )
					EndIf
				EndIf
			EndIf

			//================================================================================
			// Apos processar todas as funcoes, flag a ZLF informando que os eventos do 
			// produtor foram todos processados
			//================================================================================
			_oProces:SetRegua2(1)
			_oProces:IncRegua2('Processo [04] - Atualizando Status nas tabelas do Leite...')
			If _lOk
				_cUpdate := " UPDATE "+ RetSqlName("ZLF")
				_cUpdate += " SET ZLF_ACERTO = 'N',ZLF_VLRPAG = 0, ZLF_L_SEEK = ' ', ZLF_STATUS = 'E', ZLF_F1SEEK = ' ', ZLF_DTFECH = ' ', ZLF_SEQBX = ' ' "
				_cUpdate += " WHERE ZLF_FILIAL = '"+ xFilial("ZLF")	+"' "
				_cUpdate += " AND ZLF_A2COD  = '"+ SA2->A2_COD		+"' "
				_cUpdate += " AND ZLF_A2LOJA = '"+ SA2->A2_LOJA		+"' "
				_cUpdate += " AND ZLF_CODZLE = '"+ _cCodMix			+"' "
				_cUpdate += " AND ZLF_SETOR = '"+ _cSetor			+"' "
				_cUpdate += " AND ZLF_LINROT = '"+ _cLinha			+"' "
				_cUpdate += " AND ZLF_TP_MIX = 'L' "
				_cUpdate += " AND D_E_L_E_T_ = ' ' "
				
				If TCSqlExec(_cUpdate) < 0
					_lOk := .F.
					_cMenAux:= SA2->A2_COD +';'+ SA2->A2_LOJA +';'+ _cSetor +';'+ _cLinha +';Atualização do Status no Mix - ZLF;Falhou ao rodar o UPDATE: ZLF_STATUS!'
					_oProces:SaveLog("Thread:"+_cThread+" MGLT01004 - Fim do processamento. "+_cMenAux)
					_oFile:Write(_cMenAux + ' - MGLT01004;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF )
				EndIf
			EndIf
			If _lOk
				_cUpdate := " UPDATE " + RetSqlName("ZLD")
				_cUpdate += " SET ZLD_STATUS = ' ' "
				_cUpdate += " WHERE ZLD_FILIAL = '"+ xFilial("ZLF")	+"' "
				_cUpdate += " AND ZLD_RETIRO = '"+ SA2->A2_COD 		+"' "
				_cUpdate += " AND ZLD_RETILJ = '"+ SA2->A2_LOJA		+"' "
				_cUpdate += " AND ZLD_SETOR = '"+ _cSetor			+"' "
				_cUpdate += " AND ZLD_LINROT = '"+ _cLinha			+"' "
				_cUpdate += " AND ZLD_DTCOLE BETWEEN '"+ DToS(ZLE->ZLE_DTINI) +"' AND '"+ DToS(ZLE->ZLE_DTFIM) +"' "
				_cUpdate += " AND D_E_L_E_T_ = ' ' "

				If TCSqlExec(_cUpdate) < 0
					_lOk := .F.
					_cMenAux:= SA2->A2_COD +';'+ SA2->A2_LOJA +';'+ _cSetor +';'+ _cLinha +';Atualização do Status na Recepção de Leite - ZLD;Falhou ao rodar o UPDATE: ZLD_STATUS!'
					_oProces:SaveLog("Thread:"+_cThread+" MGLT01005 - Fim do processamento. "+_cMenAux)
					_oFile:Write(_cMenAux + ' - MGLT01005;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF )
				EndIf
			EndIf
			//================================================================================
			// Chama funcao para deletar na ZLF os eventos gerados pela rotina de Fechamento
			//================================================================================
			If _lOk
				_cUpdate := " UPDATE " + RetSqlName("ZLF")
				_cUpdate += " SET D_E_L_E_T_ = '*' "
				_cUpdate += " WHERE ZLF_FILIAL = '"+ xFilial("ZLF")	+"' "
				_cUpdate += " AND ZLF_CODZLE = '"+ _cCodMix			+"' "
				_cUpdate += " AND ZLF_A2COD  = '"+ SA2->A2_COD		+"' "
				_cUpdate += " AND ZLF_A2LOJA = '"+ SA2->A2_LOJA		+"' "
				_cUpdate += " AND ZLF_ORIGEM =  'F' " //So deleta originados pela rotina do Acerto
				_cUpdate += " AND ZLF_ACERTO <> 'S' " //Deleta se nao realizou acerto definitivo
				_cUpdate += " AND ZLF_TP_MIX =  'L' " //Deleta apenas registros do leite
				_cUpdate += " AND ZLF_SETOR = '"+ _cSetor		+"' "
				_cUpdate += " AND ZLF_LINROT = '"+ _cLinha		+"' "
				_cUpdate += " AND D_E_L_E_T_ = ' ' "
						
				If TCSqlExec(_cUpdate) < 0
					_lOk := .F.
					_cMenAux:= SA2->A2_COD +';'+ SA2->A2_LOJA +';'+ _cSetor +';'+ _cLinha +';Falha na deleção dos registros do Mix - ZLF;Falhou ao rodar o DELETE!'
					_oProces:SaveLog("Thread:"+_cThread+" MGLT01005 - Fim do processamento. "+_cMenAux)
					_oFile:Write(_cMenAux + ' - MGLT01006;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF )
				EndIf
			EndIf

			If !_lOk
				DisarmTransaction()
				Break
			Else
				_oFile:Write(SA2->A2_COD +';'+ SA2->A2_LOJA +';'+ _cSetor +';'+ _cLinha +';Concluído!;Cancelamento realizado com sucesso!;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF )
			EndIf
			END TRANSACTION
		EndIf
		MSUnLockAll()	
		_nCont++
		_nTotPrd++
		(_cAlias)->( DBSkip() )
	EndDo
	SA2->(DBCloseArea())
	(_cAlias)->(DBCloseArea())

	//Recomenda-se que após o processamento dos Execautos, seja chamada a função F080ClearM() que faz a limpeza de variáveis e objetos de controle na rotina FINA080.
	//Havendo processamento em lote (mais de uma execução da rotina automática), a rotina F080ClearM() poderá ser chamada somente ao final do processamento.
	F080ClearM()

	_oProces:SetRegua1(1)
	_oProces:SetRegua2(1)
	_oProces:IncRegua1('Processo [03] - Concluindo Cancelamento... [Aguarde!]')
	_oProces:IncRegua2('Atualizando Status do Mix...')
	//================================================================================
	// Altera o Status da ZLE
	//================================================================================
	_cAlias := GetNextAlias()
	BeginSql alias _cAlias
		SELECT COUNT(1) QTD
		  FROM %Table:ZLF%
		 WHERE ZLF_CODZLE = %exp:_cCodMix%
		   AND ZLF_ACERTO <> 'S'
		   AND D_E_L_E_T_ = ' '
	EndSql
		
	If (_cAlias)->QTD > 0
		ZLE->( RecLock( "ZLE" , .F. ) )
		ZLE->ZLE_STATUS := 'P'
		ZLE->( MSUnLock() )
	EndIf
		
	(_cAlias)->(DBCloseArea())
		
EndIf

_cHoraFim := ElapTime( _cHoraIni , Time() )
FWAlertSuccess("Processamento Concluido! "+ CRLF +"[ Tempo gasto: "+ _cHoraFim +" ]","MGLT01007")

_oFile:Write('====================================================================================================' + CRLF )
_oFile:Write(' Processamento Concluido......: [ Tempo gasto: '+ _cHoraFim +' ]'                                     + CRLF )
_oFile:Write(' Registros processados........: ['+ StrZero( _nTotPrd , 9 ) +']'                                      + CRLF )
_oFile:Write(' Média por registro...........: ['+ PadL( Round( ( ( ( Val( SubStr( _cHoraFim , 1 , 2 ) ) * 60 ) * 60 ) + ( Val( SubStr( _cHoraFim , 4 , 2 ) ) * 60 ) + Val( SubStr( _cHoraFim , 7 , 2 ) ) ) / _nTotPrd , 3 ) , 7 , '0' ) +'] segundos' + CRLF )
_oFile:Write('====================================================================================================' + CRLF )

_oFile:Close()
_oFile:= Nil

If GetRemoteType() == 5 //SmartClient HTML sem WebAgent
	CpyS2TW(_cPthLog + _cArqLog)  // Copia o arquivo para o Browse de navegação Web do usuário
Else	
	CpyS2T(_cPthLog + _cArqLog,_cDirTmp)
	If ShellExecute( "open" , _cDirTmp + _cArqLog , "" , "" , 1 ) <= 32
		FWAlertError("Não foi possivel abrir o Arquivo: " + CRLF + _cDirTmp,"MGLT01010")
	EndIf
EndIf

_oProces:SaveLog("Thread:"+_cThread+" Fim Cancelamento do Leite")
EventInsert(FW_EV_CHANEL_ENVIRONMENT, FW_EV_CATEGORY_MODULES, "Z01", FW_EV_LEVEL_INFO, "", "Fim Cancelamento do Leite",_cParam , .T.) //CHAMADA DO EVENTO

Return

/*
===============================================================================================================================
Programa----------: CancBxSE2
Autor-------------: Wodson Reis
Data da Criacao---: 14/10/2008
Descrição---------: Cancela Baixa de titulo no contas a pagar via SigaAuto.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CancBxSE2(_oProces As Object,_cCodMix As Character,_cSetor As Character,_cLinha As Character,_cMotBaixa As Character,_nTempM As Numeric)

Local _lRet		:= .T. As Logical
Local _cAlias	:= GetNextAlias() As Character
Local _nCont	:= 1 As Numeric
Local _nTotReg	:= 0 As Numeric
Local _nReg		:= 0 As Numeric
Local nModAnt	:= nModulo As Numeric
Local cModAnt	:= cModulo As Numeric
Local _aArea	:= FWGetArea() As Array
Local _aDados	:= {} As Array
Local _cMenAux	:= "" As Character
Local _nX		:= 0 As Numeric
Local _nSeq		:= 0 As Numeric
Private aBaixaSE5	:= {} As Array//Declarada como Private para ser usada no Sel080Baixa
Private lMsErroAuto	:= .F. As Logical
Private lMsHelpAuto	:= .T. As Logical
//A busca do título deve ser feita pelo movimento pois existem baixas parciais onde o título é de uma linha e a baixa
//pertence a mais de uma linha.
BeginSql alias _cAlias
	SELECT '01' COD_ACAO, E2_FILIAL, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_FORNECE, E2_LOJA, FK2_VALOR, FK2_SEQ, FK2_MOTBX, FK2_DATA, SE2.R_E_C_N_O_ REGSE2, FK2.R_E_C_N_O_ REGFK2
	FROM %Table:SE2% SE2, %Table:FK7% FK7, %Table:FK2% FK2
	WHERE E2_FILIAL = FK7_FILTIT
	AND E2_PREFIXO = FK7_PREFIX
	AND E2_NUM = FK7_NUM
	AND E2_PARCELA = FK7_PARCEL
	AND E2_TIPO = FK7_TIPO
	AND E2_FORNECE = FK7_CLIFOR
	AND E2_LOJA = FK7_LOJA
	AND FK2_IDDOC = FK7_IDDOC
	AND FK7_ALIAS = 'SE2'
	AND E2_FILIAL = %xFilial:SE2%
	AND E2_TIPO IN ('NDF', 'NF ')
	AND E2_SALDO <> E2_VALOR
	AND SE2.E2_FORNECE = %exp:SA2->A2_COD%
  	AND ((E2_TIPO = 'NF ' AND SE2.E2_LOJA = %exp:SA2->A2_LOJA% )
       OR ( E2_TIPO = 'NDF' AND EXISTS (SELECT 1 FROM %Table:ZLF%
                   WHERE FK2_L_MIX = ZLF_CODZLE
                  AND FK2_L_SETO = ZLF_SETOR
                  AND FK2_L_LINR = ZLF_LINROT
                  AND E2_FORNECE = ZLF_A2COD
                  AND ZLF_A2LOJA = %exp:SA2->A2_LOJA% 
                  AND E2_PREFIXO = SubStr(ZLF_L_SEEK,3,3)
                  AND E2_NUM = SubStr(ZLF_L_SEEK,6,9)
                  AND E2_PARCELA = SubStr(ZLF_L_SEEK,15,2)
                  AND E2_TIPO = SubStr(ZLF_L_SEEK,17,3)
                  AND E2_LOJA = SubStr(ZLF_L_SEEK,26,4)
                  AND FK2_SEQ = ZLF_SEQBX
				  AND D_E_L_E_T_ = ' ')))
	AND FK2_MOTBX = %exp:_cMotBaixa%
	AND FK2_DATA = %exp:dDatabase%
	AND FK2_L_MIX = %exp:_cCodMix%
	AND FK2_L_SETO = %exp:_cSetor%
	AND FK2_L_LINR = %exp:_cLinha%
	AND NOT EXISTS (SELECT 1 FROM %Table:FK2% EST
					WHERE FK2.FK2_IDDOC = EST.FK2_IDDOC
					AND FK2.FK2_SEQ = EST.FK2_SEQ
					AND EST.FK2_TPDOC = 'ES'
					AND EST.D_E_L_E_T_ = ' ')
	AND SE2.D_E_L_E_T_ = ' '
	AND FK7.D_E_L_E_T_ = ' '
	AND FK2.D_E_L_E_T_ = ' '
	UNION ALL
	SELECT '02' COD_ACAO, E2_FILIAL, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, E2_FORNECE, E2_LOJA, 0 FK2_VALOR, ' ' FK2_SEQ, ' ' FK2_MOTBX, ' ' FK2_DATA, R_E_C_N_O_ REGSE2, 0
	FROM %Table:SE2%
	WHERE E2_FILIAL = %xFilial:SE2%
	AND E2_L_MIX = %exp:_cCodMix%
	AND E2_FORNECE = %exp:SA2->A2_COD%
	AND E2_LOJA = %exp:SA2->A2_LOJA%
	AND E2_L_SITUA = 'I'
	AND E2_TIPO IN ('NDF', 'NF ')
	AND E2_EMISSAO = %exp:dDatabase%
	AND E2_L_SETOR = %exp:_cSetor%
	AND E2_L_LINRO = %exp:_cLinha%
	AND D_E_L_E_T_ = ' '
	ORDER BY COD_ACAO, REGFK2 DESC
EndSql
Count To _nReg
(_cAlias)->(DBGoTop())

_nTotReg := _nReg
_oProces:SetRegua2( _nTotReg )

// Altera o modulo para Financeiro, senao o SigaAuto nao executa
nModulo := 6
cModulo := "FIN"

While (_cAlias)->( !Eof() ) .And. _lRet
	//Manter SE2 posicionada pois as rotinas padrões possuem essa premissa
	SE2->( DBGoTo((_cAlias)->REGSE2) )
	lMsErroAuto	:= .F.
	lMsHelpAuto	:= .T.
	
	If (_cAlias)->COD_ACAO == '01'
		_oProces:IncRegua2( "Cancelamento Baixa - Tarefa "+ AllTrim( Str(_nCont) ) +" de "+ AllTrim( Str(_nTotReg) ) )
		_nSeq := 0
		
		_aDados := {	{ "E2_PREFIXO"		, SE2->E2_PREFIXO							, Nil } ,;
						{ "E2_NUM"	    	, SE2->E2_NUM								, Nil } ,;
						{ "E2_PARCELA"  	, SE2->E2_PARCELA							, Nil } ,;
						{ "E2_TIPO"	    	, SE2->E2_TIPO								, Nil } ,;
						{ "E2_FORNECE"  	, SE2->E2_FORNECE							, Nil } ,;
						{ "E2_LOJA"	    	, SE2->E2_LOJA								, Nil } ,;
						{ "AUTJUROS"		, 0											, Nil } ,;
						{ "AUTDESCONT"		, 0											, Nil } ,;
						{ "AUTMOTBX"		, (_cAlias)->FK2_MOTBX						, Nil } ,;
						{ "AUTDTBAIXA"		, (_cAlias)->FK2_DATA						, Nil } ,;
						{ "AUTDTCREDITO"	, (_cAlias)->FK2_DATA						, Nil } ,;
						{ "AUTHIST"			, "Cancto Bx - "+SE2->(E2_FORNECE+E2_LOJA)	, Nil } ,;
						{ "AUTVLRPG"		, (_cAlias)->FK2_VALOR						, Nil } ,;
						{ "AUTVALREC"		, (_cAlias)->FK2_VALOR						, Nil }  }
		
		//================================================================================
		// Busca o numero da Baixa
		//================================================================================
		aBaixaSE5 := Sel080Baixa("VL /BA /CP /",SE2->E2_PREFIXO,SE2->E2_NUM,SE2->E2_PARCELA,SE2->E2_TIPO,0,0,SE2->E2_FORNECE,SE2->E2_LOJA,.F.,.F.,.F.,0,.F.,.T.)
		For _nX := 1 To Len(aBaixaSE5)
			If SubStr(aBaixaSE5[_nX],Len(aBaixaSE5[_nX])-1,2) == (_cAlias)->FK2_SEQ
				_nSeq := _nX
				Exit
			EndIf
		Next _nX
		_nSeq:= _nSeq

		// ExecAuto de Cancelamento de Baixa de Contas a Pagar
		MSExecAuto( {|x,y,z,k| Fina080(x,y,z,k) } , _aDados , 6 ,, _nSeq )
		
	    If lMsErroAuto
			_lRet := .F.
			_cMenAux:= SA2->A2_COD +';'+ SA2->A2_LOJA +';'+ _cSetor +';'+ _cLinha +';Cancelamento de baixa de Título!;Falha no ExecAuto ['+SE2->(E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA )+'] '+MostraErro()
			_oProces:SaveLog("Thread:"+_cThread+" MGLT01009 - Fim do processamento. "+_cMenAux)
			_oFile:Write(_cMenAux + ' - MGLT01009;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF )
		EndIf
		If _lRet
			RecLock( "SE2" , .F. )
			SE2->E2_DATALIB := CToD("  /  /  ")
			SE2->E2_USUALIB := " "
			SE2->E2_STATLIB := "01"
			SE2->( MSUnLock() )
		EndIf
		
		//Atualizo o Status dos Convênios
		If _lRet .And. AllTrim(SE2->E2_ORIGEM) == "AGLT010"
			_cUpdate := " UPDATE "+ RetSqlName("ZLL")
			_cUpdate += " SET ZLL_STATUS = 'A' "
			_cUpdate += " WHERE ZLL_FILIAL = '"+ SE2->E2_FILIAL			+"' "
			_cUpdate += " AND ZLL_COD    = '"+ SubStr(SE2->E2_NUM,1,6)	+"' "
			_cUpdate += " AND ZLL_SEQ    = '"+ SubStr(SE2->E2_NUM,7,3)	+"' "
			_cUpdate += " AND ZLL_RETIRO = '"+ SE2->E2_FORNECE			+"' "
			_cUpdate += " AND ZLL_RETILJ = '"+ SE2->E2_LOJA				+"' "
			_cUpdate += " AND D_E_L_E_T_ = ' ' "				
			If TCSqlExec(_cUpdate) < 0
				_lRet := .F.
				_cMenAux:= SA2->A2_COD +';'+ SA2->A2_LOJA +';'+ _cSetor +';'+ _cLinha +';Atualização Convênio - ZZL;Falha no Update ZLL_STATUS'+TcSqlError()
				_oProces:SaveLog("Thread:"+_cThread+" MGLT01011 - Fim do processamento. "+_cMenAux)
				_oFile:Write(_cMenAux + ' - MGLT01011;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF )
			EndIf
		EndIf
    
	ElseIf (_cAlias)->COD_ACAO == '02'
		_oProces:IncRegua2( "Exclusao Titulo - Tarefa "+ AllTrim( Str(_nCont) ) +" de "+ AllTrim( Str(_nTotReg) ) )
		
		_aDados := {	{ "E2_PREFIXO"	, SE2->E2_PREFIXO	, Nil } ,;
						{ "E2_NUM"		, SE2->E2_NUM		, Nil } ,;
						{ "E2_PARCELA"	, SE2->E2_PARCELA	, Nil } ,;
						{ "E2_TIPO"		, SE2->E2_TIPO		, Nil } ,;
						{ "E2_FORNECE"	, SE2->E2_FORNECE	, Nil } ,;
						{ "E2_LOJA"		, SE2->E2_LOJA		, Nil }  }
		
		MsExecAuto( { |x,y,z| FINA050(x,y,z)}, _aDados,, 5)  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão
		
	    If lMsErroAuto
			_lRet := .F.
			_cMenAux:= SA2->A2_COD +';'+ SA2->A2_LOJA +';'+ _cSetor +';'+ _cLinha +';Exclusão de Título!;Falha no ExecAuto ['+SE2->(E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA)+'] '+MostraErro()
			_oProces:SaveLog("Thread:"+_cThread+" MGLT01012 - Fim do processamento. "+_cMenAux)
			_oFile:Write(_cMenAux + ' - MGLT01012;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF )
		EndIf
	EndIf
	_nCont++
	(_cAlias)->( DBSkip() )
EndDo

// Restaura o modulo em uso
nModulo := nModAnt
cModulo := cModAnt

(_cAlias)->(DBCloseArea())
FWRestArea( _aArea )

Return( _lRet )
