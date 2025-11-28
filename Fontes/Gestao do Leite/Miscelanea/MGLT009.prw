/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |30/06/2025| Chamado 51183. Corrigida tipagem da verilável _nVlrNF
Lucas Borges  |08/07/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
Lucas Borges  |05/10/2025| Chamado 52148. Permitido executar a previsão para Mix Aprovado além do Efetivado
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include 'FWEVENTVIEWCONSTS.CH'

/*
===============================================================================================================================
Programa--------: MGLT009
Autor-----------: Alexandre Villar (Rotina reescrita a partir da versão de 26/09/2014)
Data da Criacao-: 15/01/2015
Descrição-------: Rotina para processamento do fechamento do Leite para Acerto com os Produtores
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MGLT009

Local _cPerg  	:= 'MGLT009' As Character
Local _oProces	:= Nil As Object

tNewProcess():New(	_cPerg						,; // cFunction. Nome da função que está chamando o objeto
					"Fechamento do Leite Próprio"	,; // cTitle. Título da árvore de opções
					{|_oProces| MGLT009R(_oProces) },; // bProcess. Bloco de execução que será executado ao confirmar a tela
					"Essa rotina tem por objetivo processar o 'Fechamento do Leite' "+;
					"realizando os cálculos para acerto dos Produtores!",; // cDescription. Descrição da rotina
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
Programa--------: MGLT009R
Autor-----------: Alexandre Villar
Data da Criacao-: 15/01/2015
Descrição-------: Rotina que controla o processamento do fechamento
Parametros------: _oProces
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function MGLT009R(_oProces As Object)

Local _aDados		:= {} As Array
Local _cArqLog		:= "LOG_FECHAMENTO_LEITE_"+ DToS(Date()) +"_"+ StrTran(Time(),":","") +"_"+ RetCodUsr() +".log" As Character
Local _cPthLog		:= "\data\italac\MGLT009\" As Character
Local _cFilMsg		:= SuperGetMV("LT_FILMSGN",.F.,"20/21/23/24/25") As Character
Local _cDirTmp		:= GetTempPath() As Character
Local _cHoraIni		:= '' As Character
Local _cHoraFim		:= '' As Character
Local _cMsFSul		:= '' As Character
Local _cDesMsg		:= '' As Character
Local _cMovMsg		:= '' As Character
Local _cCmpMsg		:= '' As Character
Local _lOk			:= .T. As Logical
Local _nTotReg		:= 0 As Numeric
Local _nRegNFP		:= 0 As Numeric
Local _nTotPrd		:= 0 As Numeric
Local _nI			:= 0 As Numeric
Local _aParam		:= {} As Array
Local _dDtAux		:= SToD('//') As Date
Local _lVldNfp		:= SuperGetMV("LT_VLDNFP",.F.,.F.) As Logical
Local _lSemNota		:= .F. As Logical
Local _cLoja2		:= "" As Character
Local _cParam		:= "" As Character
Local _cMenAux		:= "" As Character
Local _nVolIncP		:= SuperGetMV("LT_VOLINCP",.F.,657000) As Numeric
Local _lCalIncP		:= !Empty(Posicione('F28',1,xFilial('F28')+SuperGetMV("LT_INCINCP",.F.,""),'F28_CODIGO')) As Logical
Local _nRecPrd		:= 0 As Numeric
Local _nRecINS		:= 0 As Numeric
Local _nRecGil		:= 0 As Numeric
Local _cUpdate		:= "" As Character
Local _cEveInc		:= AllTrim(SuperGetMV("LT_EVEIPRO",.F.,"")) As Character
Local _nDifTotNF	:= SuperGetMV("LT_DIFNFPR",.F.,10) As Numeric
Local _ARETVLD		:= {} As Array
Local _lNf1Item		:= If(SM0->M0_ESTENT == 'RO',.F.,.T.) As Logical
Local _cAcao		:= "" As Character

Private _nTempM		:= 0 As Numeric
Private _oFile		:= Nil As Object
Private _cCodMix	:= "" As Character
Private _cVersao	:= "" As Character
Private _cSetores	:= "" As Character
Private _lDefini	:= "" As Character
Private _nSldPro	:= 0 As Numeric
Private _cNroNota	:= '' As Character
Private _cParc		:= StrZero(1 , TamSX3("E2_PARCELA")[1]) As Character // Parcela do titulo do evento(NDF)
Private _cSerie		:= PadR(AllTrim(SuperGetMV('IT_SERDLEI',.F.,'')),TamSX3('F1_PREFIXO')[1]) As Character // Serie da NF
Private _cPrefixo	:= PadR(AllTrim(SuperGetMV("LT_PRESER",.F.,"GLT")),TamSX3("E2_PREFIXO")[1]) As Character // Prefixo do titulo e serie da Nota do produtor
Private _cMotBaixa	:= AllTrim(SuperGetMV("LT_MOTBX",.F.,"GLT")) As Character// Motivo de baixa utilizado para a rotina do Leite
Private _cNatureza	:= AllTrim(SuperGetMV("LT_NATGLT",.F.,"222001")) As Character// Natureza dos titulos do Produtor
Private _cCODSA2	:= '' As Character
Private _cLOJSA2	:= '' As Character
Private _cCODZL2	:= '' As Character
Private _cCODZL3	:= '' As Character
Private _cThread	:= CValToChar(ThreadID()) As Character
Private lMsErroAuto := .F.
Private lMsHelpAuto := .T.

_cParam := "Filial: " + cFilAnt
_cParam += "Acerto: " + IIf(MV_PAR01 == 1 , 'Previsão' , 'Definitivo')
_cParam += "Mix: " + MV_PAR02
_cParam += "Setor: " + AllTrim(MV_PAR03)
_cParam += "Fornecedor: " + MV_PAR04 +"-"+MV_PAR05
_cParam += "Loja: " + MV_PAR06 +"-"+MV_PAR07
_cParam += "Linha: " + MV_PAR08 +"-"+MV_PAR09
_cParam += "Pagamento: " + DToC(MV_PAR10)
_cParam += "Vencto: " + DToC(MV_PAR11)
_cParam += "Tipo Forn.: " + CValToChar(MV_PAR12)
_cParam += "Usuario: " + UsrFullName(__cUserId)
EventInsert(FW_EV_CHANEL_ENVIRONMENT, FW_EV_CATEGORY_MODULES, "Z00", FW_EV_LEVEL_INFO, "", "Início Fechamento do Leite",_cParam , .T.) //CHAMADA DO EVENTO

_oProces:SaveLog("Thread:"+_cThread+" Iniciando a rotina. Parâmetros: "+CValToChar(MV_PAR01)+"-"+MV_PAR02+"-"+AllTrim(MV_PAR03)+"-"+MV_PAR04+"-"+MV_PAR05+"-"+MV_PAR06+"-"+MV_PAR07+"-"+MV_PAR08+"-"+MV_PAR09+"-"+DToC(MV_PAR10)+"-"+DToC(MV_PAR11)+"-"+CValToChar(MV_PAR01))

_oProces:SetRegua1(4)//01-Inicializando/02-Excluindo previsões/03-Selecionando produtores/04-Concluindo Fechamento
_oProces:IncRegua1('Processo [01] - Inicializando a rotina... [Aguarde!]')
_oProces:SetRegua2(1)
_oProces:IncRegua2('Verificando a configuração dos parâmetros no MIX...')

//====================================================================================================
// Verifica e Processa as perguntas para parametrização da rotina
//====================================================================================================
If MV_PAR01 <> 1
	//====================================================================================================
	// dDataBase deve ser maior que o MV_DATAFIS e maior ou igual a MV_DATAFIN no fechamento definitivo
	//====================================================================================================
	_dDtAux := GetMV('MV_DATAFIS' ,, SToD(''))
	
	If dDataBase <= _dDtAux
		_cMenAux:= "Database do Sistema menor/igual ao bloqueio para operações Fiscais. Solicite o desbloqueio à Contabilidade."
		_oProces:SaveLog("Thread:"+_cThread+" MGLT00901 - Fim do processamento. "+_cMenAux)
		MsgStop(_cMenAux,"MGLT00901")
		Return
	EndIf
	
	_dDtAux := GetMV('MV_DATAFIN' ,, SToD(''))
		
	If dDataBase < _dDtAux
		_cMenAux := "Database do Sistema menor que bloqueio para operações Financeiras. Solicite o desbloqueio à Contabilidade."
		_oProces:SaveLog("Thread:"+_cThread+" MGLT00902 - Fim do processamento. " + _cMenAux)
		MsgStop(_cMenAux,"MGLT00902")
		Return
	EndIf
EndIf

_aParam := { IIf(	MV_PAR01 == 1 , 'Previsão' , 'Definitivo')			,; // 01 - Tipo de processamento
					MV_PAR02											,; // 02 - Código do Mix
					'1'													,; // 03 - Versão do MIX
					AllTrim(MV_PAR03)									,; // 04 - Setores selecionados
					MV_PAR04											,; // 05 - Cód. do Fornecedor Inicial
					MV_PAR05											,; // 06 - Cód. do Fornecedor Final
					MV_PAR06											,; // 07 - Loja do Fornecedor Inicial
					MV_PAR07											,; // 08 - Loja do Fornecedor Final
					MV_PAR08											,; // 09 - Linha/Rota Inicial
					MV_PAR09											,; // 10 - Linha/Rota Final
					MV_PAR10											,; // 11 - Data de Vencimento
					MV_PAR11											,; // 12 - Data de Vencimento limite para financeiro
					MV_PAR12											,; // 13 - Tipo de Pessoa - 1-Ambos, 2 Jurídica, 3-Física
					MV_PAR13											 } // 14 - Cálculo do incetivo - 1-Produção, 2-Folha, 3-Ambos

If Posicione("ZZL",3,xFilial("ZZL")+RetCodUsr(),"ZZL_ALDTEM") <> 'S'
	_cMenAux := "Usuário sem acesso para incluir Documento de Entrada com data retroativa. Solicite à TI a liberação do campo ZZL_ALDTEM."
	_oProces:SaveLog("Thread:"+_cThread+" MGLT00903 - Fim do processamento. " + _cMenAux)
	MsgStop(_cMenAux,"MGLT00903")
	Return
EndIf

//====================================================================================================
// Verifica se os parametros obrigatórios estão em branco
//====================================================================================================
_cAcao		:= Upper(AllTrim(_aParam[01]))// Ação do Fechamento
_cCodMix	:= MV_PAR02	// Código do MIX
_cVersao	:= '1'// Versão do MIX

//Se não preencheu e não tem acesso a todos, aborta processamento
If !Empty(MV_PAR03) .Or. Empty(MV_PAR03) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") == 'S'
	_cSetores	:= AllTrim(MV_PAR03) // Setores de Referência
Else
	_cMenAux := "Não foram informados setores válidos para o usuário."
	_oProces:SaveLog("Thread:"+_cThread+" MGLT00904 - Fim do processamento. " + _cMenAux)
	MsgStop(_cMenAux,"MGLT00904")
	Return
EndIf

_lDefini	:= (_cAcao == 'DEFINITIVO')


_oFile:= FWFileWriter():New(_cPthLog + _cArqLog)

If !_oFile:Create()
	_cMenAux := "O Arquivo de Log não foi criado! Favor acionar a TI."
	_oProces:SaveLog("Thread:"+_cThread+" MGLT00905 - Fim do processamento. " + _cMenAux)
	MsgStop(_cMenAux,"MGLT00905")
	Return
Else
	_oFile:Write('====================================================================================================' + CRLF)
	_oFile:Write(' Log de Processamento - Fechamento do Leite - Data: '+ DToC(Date()) +' / Tipo: '+ _cAcao            + CRLF)
	_oFile:Write(' [ Para abrir o LOG no Excel, exclua os comentários do início e fim e salve o arquivo como ".CSV" ] ' + CRLF)
	_oFile:Write(' [ Se não existirem registros, todos foram processados com sucesso ou nenhum foi processado ] '       + CRLF)
	_oFile:Write('====================================================================================================' + CRLF)
	_oFile:Write('Produtor;Loja;Setor;Linha/Rota;Processo;Erro;Tempo' + CRLF)
EndIf

//====================================================================================================
// Posiciona no cadastro de MIX
//====================================================================================================
DBSelectArea("ZLE")
ZLE->(DBSetOrder(1))
If ZLE->(DBSeek(xFilial("ZLE") + _cCodMix))
	If ZLE->ZLE_STATUS == 'F'
		_cMenAux := "O MIX "+ _cCodMix +" não pode ser processado pois o mesmo já foi fechado!"
		_oProces:SaveLog("Thread:"+_cThread+" MGLT00906 - Fim do processamento. " + _cMenAux)
		MsgStop(_cMenAux,"MGLT00906")
		Return
	EndIf
	If dDatabase < ZLE->ZLE_DTFIM
		_cMenAux := "A data do sistema é menor que a data final do Mix."
		_oProces:SaveLog("Thread:"+_cThread+" MGLT00908 - Fim do processamento. " + _cMenAux)
		MSgStop(_cMenAux,"MGLT00908")
		Return
	EndIf
	
	If _lDefini
		If Empty(_cSerie)
			_cMenAux := "Falha ao inicializar a Série para a geração do documento! Verifique a configuração do parâmetro [IT_SERDLEI]."
			_oProces:SaveLog("Thread:"+_cThread+" MGLT00909 - Fim do processamento. " + _cMenAux)
			MsgStop(_cMenAux,"MGLT00909")
			Return
		EndIf
		If !Sx5NumNota(_cSerie)
			_cMenAux := "Falha ao gerar o número do documento para o processamento em Definitivo! Verifique a configuração do parâmetro [IT_SERDLEI]."
			_oProces:SaveLog("Thread:"+_cThread+" MGLT00910 - Fim do processamento. " + _cMenAux)
			MsgStop(_cMenAux,"MGLT00910")
			Return
		EndIf
	EndIf
	
	_oProces:IncRegua1('Processo [02] - Excluindo previsões geradas... [Aguarde!]')
	_oProces:IncRegua2('Processando...')
	_cHoraIni := Time()

	_lOk := ITDELZLF(_aParam, _oProces, , _cEveInc)
	If _lOk .And. !MsgYesNo("Previsão excluída com sucesso. Deseja prosseguir com o fechamento?","MGLT00937")
		_cMenAux := "Fim do processamento com a exclusão da previsão."
		_oFile:Write(_cMenAux + '- MGLT00937'+ CRLF)
		_oProces:SaveLog("Thread:"+_cThread+" MGLT00937 - Fim do processamento. " + _cMenAux)
		_lOk := .F.
	ElseIf _lOk
		//====================================================================================================
		// Seleciona os registros da ZLF de acordo com os parâmetros
		//====================================================================================================
		_oProces:IncRegua1('Processo [03] - Selecionando Produtores... [Aguarde!]')
		_oProces:IncRegua2('Processando...')
		
		ITSELZLF(_aParam,@_aDados,_oProces,_cEveInc,_lDefini)

		If Empty(_aDados)
			_cMenAux := "Não foram encontrados dados para o processamento! Verifique os parâmetros informados e tente novamente."
			_oProces:SaveLog("Thread:"+_cThread+" MGLT00911 - Fim do processamento. " + _cMenAux)
			MsgAlert(_cMenAux,"MGLT00911")
		Else
			DBSelectArea("ZL2")
			DBSelectArea("SA2")
			DBSelectArea("ZL3")
			DBSelectArea("SF1")
			DBSelectArea("ZLF")
			DBSelectArea("ZL8")

			_nTotReg := Len(_aDados)
			_oProces:SetRegua1(_nTotReg)
			
			For _nI := 1 To _nTotReg
				_nTempM	:= Seconds()
				_oProces:SetRegua2(11)
				_oProces:IncRegua1('Produtor ['+ StrZero(_nI,6) +'] de ['+ StrZero(_nTotReg,6) +'] - '+ _aDados[_nI][03] +'/'+ _aDados[_nI][04] +' - Setor: '+ _aDados[_nI][01] +' - Linha/Rota: '+ _aDados[_nI][02])
				_oProces:IncRegua2('Processo [01] - Inicializando...')
				
				_lOk := .T.
				//====================================================================================================
				// Verifica se o processamento é uma Previsão ou se o Fornecedor já foi preparado para o Fechamento
				//====================================================================================================
				If !_lDefini .Or. ITVALPRP(_lDefini,_aDados[_nI][01],_aDados[_nI][02],_aDados[_nI][03],_aDados[_nI][04]) 
					_oProces:IncRegua2('Processo [02] - Validando os dados do fechamento...')
					//====================================================================================================
					// Verifica se o Setor do Produtor exige o lançamento de CNF conforme legislação
					//====================================================================================================
					ZL2->(DBSetOrder(1))
					If ZL2->(DBSeek(xFilial("ZL2") + _aDados[_nI][01]))
						//====================================================================================================
						// Obtem parametrização no SETOR para gerar NF do produtor
						//====================================================================================================
						_cPrefixo	:= ZL2->ZL2_SERIE
						_cSerie		:= ZL2->ZL2_SERIE
						_cCODZL2	:= ZL2->ZL2_COD
						
						SA2->(DBGoTo(_aDados[_nI][06]))
						If SA2->A2_COD == _aDados[_nI][03] .And. SA2->A2_LOJA == _aDados[_nI][04]
							_cCODSA2	:= SA2->A2_COD
							_cLOJSA2	:= SA2->A2_LOJA
							//Indica se o fechamento vai gerar a nota ou se o produtor irá emitir a NFe
							_lSemNota := IIf(SA2->A2_L_NFPRO == "S", .T.,.F.)
							
							//====================================================================================================
							// Posiciona na Linha/Rota do Produtor.
							//====================================================================================================
							ZL3->(DBSetOrder(1))
							If ZL3->(DBSeek(xFilial("ZL3") + _aDados[_nI][02]))
								_cCODZL3 := ZL3->ZL3_COD
							Else
								_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _aDados[_nI][02] +';Posicionando registros;Falha ao posicionar no cadastro da Linha/Rota!'
								_oProces:SaveLog("Thread:"+_cThread+" MGLT00912 - " + _cMenAux)
								_oFile:Write(_cMenAux + '- MGLT00912;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
								_lOk := .F.
							EndIf
						Else
							_cMenAux := _aDados[_nI][03] +';'+ _aDados[_nI][04] +';'+ _cCODZL2 +';'+ _aDados[_nI][02] +';Posicionando registros;Falha ao posicionar no cadastro do Produtor!'
							_oProces:SaveLog("Thread:"+_cThread+" MGLT00913 - " + _cMenAux)
							_oFile:Write(_cMenAux + ' - MGLT00913;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
							_lOk := .F.
						EndIf
						
						If _lOk .And. _lDefini
							//Valida as duas situações que exigem nota do produtor
							If ZL2->ZL2_VLDNFP == "1" .Or. _lSemNota// 1 = SIM
								_aRetVld := {}
								_aRetVld := ITVALCNF(_cCodMix,_cCODSA2,_cLOJSA2,1,_lSemNota)
								
								If Empty(_aRetVld) .Or. _aRetVld[01][01] == .F.
									If !_lVldNfp
										_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Posicionando registros;Não foram encontradas as "NFP" do Produtor!'
										_oProces:SaveLog("Thread:"+_cThread+" MGLT00914 - " + _cMenAux)
										_oFile:Write(_cMenAux + ' - MGLT00914;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
										_lOk := .F.
									EndIf
								ElseIf _aRetVld[01][01] .And. _aRetVld[01][02] == "M1"
									_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Posicionando registros;Existe mais de uma "NFP" do Produtor! O Fechamento não será realizado!'
									_oProces:SaveLog("Thread:"+_cThread+" MGLT00915 - " + _cMenAux)
									_oFile:Write(_cMenAux + '- MGLT00915;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
									_lOk := .F.
								EndIf
								If _lOk .And. _lSemNota
									//Valida se todos os créditos do fornecedor, independente da loja batem com os valores de todas as NFs, independente da loja
									_lOk := ValTotNF(_oProces,_cCodMix,_cCODSA2,_cLOJSA2,_cCODZL2,_cCODZL3,_nDifTotNF)
								EndIf
							EndIf
						EndIf
					Else
						_cMenAux := _aDados[_nI][03] +';'+ _aDados[_nI][04] +';'+ _aDados[_nI][01] +';'+ _aDados[_nI][02] +';Posicionando registros;Falha ao posicionar no cadastro do Setor!'
						_oProces:SaveLog("Thread:"+_cThread+" MGLT00916 - " + _cMenAux)
						_oFile:Write(_cMenAux + ' - MGLT00916;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
						_lOk := .F.
					EndIf
					
					If _lOk
						_oProces:IncRegua2('Processo [03] - Verificando o tipo de fechamento...')
						_nSldPro := _aDados[_nI][05]

						If _lOk .And. _lDefini .And. !_lSemNota
							_cNroNota := NxtSX5Nota(_cSerie)
						ElseIf _lSemNota
							_aRetVld := ITVALCNF(_cCodMix,_cCODSA2,_cLOJSA2,2,_lSemNota)
							_cNroNota := _aRetVld[01][01]
							_cSerie := _aRetVld[01][02]
							_cPrefixo := _aRetVld[01][02]
							_cLoja2 := _aRetVld[01][03]//Essa loja pode ser diferente da loja que está sendo fechada.Ex: Nota emitida pelo fornecedor Loja 0001 e usada no fechamento de todas as outras lojas
						EndIf
						//====================================================================================================
						// Se tiver que gerar uma Notas por produtor pega o próximo número na sequência
						//====================================================================================================
						If _lDefini .And. Empty(_cNroNota)
							_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Verificando o Fechamento;Não foi possível gerar um número de Documento para o Produtor atual!'
							_oProces:SaveLog("Thread:"+_cThread+" MGLT00917 - " + _cMenAux)
							FWrit_oFile:Write(_cMenAux + ' - MGLT00917;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
							_lOk := .F.
						EndIf

						BEGIN TRANSACTION
						
						//Realiza tratamentos para Incentivo à Produção em MG
						If _lCalIncP
							U_CalcInc(1,_nVolIncP,@_lCalIncP,@_nRecPrd,@_nRecINS,@_nRecGil)
						EndIf
						_oProces:IncRegua2('Processo [04] - Gerando os documentos do fechamento...')
						If _lOk .And. _lDefini
							If _lSemNota
								//====================================================================================================
								// O produtor PJ é quem emita a nota. Gero apenas o financeiro
								//====================================================================================================
								_lOk := ITINCSE2(_oProces,_nSldPro,_cPrefixo,_cNroNota,PadR(" ", TamSX3("E2_PARCELA")[1]),"NF ",xFilial("ZLF")+_cCodMix+_cVersao+_cCODSA2+_cLOJSA2,_cNatureza,_lSemNota,_aParam[11])
							Else
								//====================================================================================================
								// Uma Nota por produtor - Acerto Fiscal(Gera NF produtor)
								//====================================================================================================
								_lOk := ITGNFPRD(_oProces,_aParam,@_nRegNFP,_cEveInc,_lNf1Item)
							EndIf
						EndIf
						//====================================================================================================
						// Acerto de Eventos Automatico(Verifica a ZL8 , gera ZLF e SE2 e baixa SE2)
						// Primeiro abato os impostos porque tenho certeza que terei saldo para compensá-los. 
						// Eles são sempre prioridade.
						//====================================================================================================
						_oProces:IncRegua2('Processo [06] - Processando os Eventos do Setor/Linha - Impostos...')
						If _lOk
							ITACTEVE(_oProces,@_lOk,_aParam,_lSemNota)
						EndIf
						//====================================================================================================
						// Acerto de Eventos de Debito incluidos pelo Mix(Verifica a ZLF, gera e baixa na SE2).
						//====================================================================================================
						_oProces:IncRegua2('Processo [05] - Processando o fechamento do MIX...')
						If _lOk
							ITACTMIX(_oProces, @_lOk , _aParam, _lSemNota)
						EndIf
						//====================================================================================================
						// Acerto Financeiro(Baixa e gera Contas a Pagar e ZLF)
						//====================================================================================================
						_oProces:IncRegua2('Processo [07] - Processando os acertos do Financeiro...')
						If _lOk
							ITACTFIN(_oProces,@_lOk,_aParam,_lDefini)
						EndIf
						_oProces:IncRegua2('Processo [08] - Atualizando Status e Flags de processamento...')
						If _lOk .And. !_lSemNota
							//====================================================================================================
							// Grava Descricao dos Descontos na NF
							//====================================================================================================
							If _lDefini
								//====================================================================================================
								// Mensagem utilizada somente para as Filias: 20 Passo Fundo e 21 Rondinha
								//====================================================================================================
								If xFilial("ZLF") $ _cFilMsg
									If Empty(_aRetVld) .Or. _aRetVld[01][01] == .F.
										_cMsFSul := ";CONFORME DECRETO 58.122/25 FICA SUSPENSA A EMISSAO DA NOTA FISCAL DO PRODUTOR NO PERIODO DE 24 DE ABRIL DE 2024 A 30 DE JUNHO DE 2025"
										_cMsFSul += " NOS TERMOS DO LIVRO II ARTIGO 44 INCISO XXII DO RICMS/RS."
									Else
										_cMsFSul := ";Sr. Produtor, favor emitir a Nota Fiscal conforme determina o art. 35 inciso I e inciso III alinea a Livro II do RICMS-RS."
										_cMsFSul += ";Emissão de uma unica NFP no final do periodo conforme art. 37 inciso II alinea a nota 01 Livro II do RICMS-RS."
									EndIf
								EndIf
								
								//====================================================================================================
								// Grava Descontos na NF
								//====================================================================================================
								SF1->(DBGoTo(_nRegNFP))
								_cDesMsg := ITGETDES(_cCodMix,_cCODSA2,_cLOJSA2,_nSldPro,_cCODZL3,_cCODZL2)
								If !_lNf1Item
									_cMovMsg := ITGETMOV(_cCodMix,_cCODSA2,_cLOJSA2,_nSldPro,_cCODZL3,_cCODZL2)
								EndIf
								_cCmpMsg := ";NF referente a movimentacoes do mes "
								_cCmpMsg += StrZero(Month(ZLE->ZLE_DTINI) , 2) +"/"+ StrZero(Year(ZLE->ZLE_DTINI) , 4) +"."+ _cMsFSul
								_cCmpMsg += AllTrim(SF1->F1_I_MENSA)
								RecLock('SF1' , .F.)
								SF1->F1_I_MENSA	:= _cDesMsg + _cMovMsg + _cCmpMsg
								SF1->(MSUnLock())
							EndIf
						EndIf
						
						If _lOk
							
							//====================================================================================================
							// Apos processar todas as funcoes, marca flag na ZLF informando que os eventos foram processados.
							//====================================================================================================
							If _lDefini
								_cUpdate := " UPDATE  "+ RetSqlName("ZLF") +" SET ZLF_ACERTO = 'S' , ZLF_STATUS = 'F', ZLF_DTFECH = '"+ DToS(dDataBase) +"' "
								If _lSemNota
									_cUpdate += ", ZLF_F1SEEK = '"+ cFilAnt + _cNroNota + _cSerie + _cCODSA2 + _cLoja2 + "N" +"' "
								EndIf
								_cUpdate += " WHERE ZLF_FILIAL = '"+ xFilial("ZLF")	+"' "
								_cUpdate += " AND ZLF_A2COD  =  '"+ _cCODSA2 +"' "
								_cUpdate += " AND ZLF_A2LOJA =  '"+ _cLOJSA2 +"' "
								_cUpdate += " AND ZLF_CODZLE =  '"+ _cCodMix +"' "
								_cUpdate += " AND ZLF_SETOR  =  '"+ _cCODZL2 +"' "
								_cUpdate += " AND ZLF_LINROT =  '"+ _cCODZL3 +"' "
								_cUpdate += " AND ZLF_ACERTO NOT IN ('B','S') "
								_cUpdate += " AND ZLF_TP_MIX =  'L' "
								_cUpdate += " AND D_E_L_E_T_ = ' ' "
								
								_lOk := !(TCSqlExec(_cUpdate) < 0)
								
								If _lOk
									_cUpdate := " UPDATE "+ RetSqlName("ZLD") +" SET ZLD_STATUS = 'F' "
									_cUpdate += " WHERE ZLD_FILIAL = '"+ xFilial("ZLD")	+"' "
									_cUpdate += " AND ZLD_RETIRO = '"+ _cCODSA2    +"' "
									_cUpdate += " AND ZLD_RETILJ = '"+ _cLOJSA2   +"' "
									_cUpdate += " AND ZLD_SETOR  = '"+ _cCODZL2   +"' "
									_cUpdate += " AND ZLD_LINROT = '"+ _cCODZL3   +"' "
									_cUpdate += " AND ZLD_DTCOLE BETWEEN '"+ DToS(ZLE->ZLE_DTINI) +"' AND '"+ DToS(ZLE->ZLE_DTFIM) +"' "
									_cUpdate += " AND D_E_L_E_T_ = ' ' "
									
									_lOk := !(TCSqlExec(_cUpdate) < 0)
									
									If !_lOk
										_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Atualização do Status na Recepção de Leite;Falhou ao rodar o UPDATE: ['+ DToS(ZLE->ZLE_DTINI) +'/'+ DToS(ZLE->ZLE_DTFIM) +']!'
										_oProces:SaveLog("Thread:"+_cThread+" MGLT00918 - " + _cMenAux)
										_oFile:Write(_cMenAux + ' - MGLT00918;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
									EndIf
								Else
									_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Atualização do Status nos Itens do MIX;Falhou ao rodar o UPDATE: ['+ _cCodMix +']!
									_oProces:SaveLog("Thread:"+_cThread+" MGLT00919 - " + _cMenAux)
									_oFile:Write(_cMenAux + ' - MGLT00919;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
								EndIf
							EndIf
							//Realiza tratamentos para Incentivo à Produção em MG
							If _lCalIncP
								U_CalcInc(2,_nVolIncP,_lCalIncP,_nRecPrd,_nRecINS,_nRecGil)
							EndIf
						EndIf
						
						If !_lOk
							DisarmTransaction()
							Break
						Else
							_oFile:Write(_cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Concluído!;Processamento em '+ _cAcao +' realizado com sucesso!;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
						EndIf
						END TRANSACTION
					EndIf
				EndIf
				
				_oProces:IncRegua2('Processo [09] - Finalizando o processamento do Produtor...')
				_nTotPrd++
				MSUnLockAll()
			Next _nI
		EndIf
		
		_oProces:SetRegua1(1)
		_oProces:IncRegua1('Processo [04] - Concluindo Fechamento... [Aguarde!]')
		_oProces:IncRegua2('Atualizando Status do Mix...')
		//====================================================================================================
		// Altera o Status da ZLE
		//====================================================================================================
		If _lDefini
			ZLE->(DBSetOrder(1))
			If ZLE->(DBSeek(xFilial('ZLE') + _cCodMix))
				RecLock("ZLE" , .F.)
				ZLE->ZLE_STATUS := 'P'
				ZLE->(MSUnLock())
			EndIf
		EndIf
	EndIf
EndIf
_cHoraFim := ElapTime(_cHoraIni , Time())
MsgInfo("Processamento Concluido! "+ CRLF +"[ Tempo gasto: "+ _cHoraFim +" ]","MGLT00921")

_oFile:Write('====================================================================================================' + CRLF)
_oFile:Write(' Processamento Concluido......: [ Tempo gasto: '+ _cHoraFim +' ]'                                     + CRLF)
_oFile:Write(' Registros processados........: ['+ StrZero(_nTotPrd , 9) +']'                                      + CRLF)
_oFile:Write(' Média por registro...........: ['+ PadL(Round((((Val(SubStr(_cHoraFim , 1 , 2)) * 60) * 60) + (Val(SubStr(_cHoraFim , 4 , 2)) * 60) + Val(SubStr(_cHoraFim , 7 , 2))) / _nTotPrd , 3) , 7 , '0') +'] segundos' + CRLF)
_oFile:Write('====================================================================================================' + CRLF)

_oFile:Close()
_oFile:= Nil

If GetRemoteType() == 5 //SmartClient HTML sem WebAgent
	CpyS2TW(_cPthLog + _cArqLog)  // Copia o arquivo para o Browse de navegação Web do usuário
Else	
	CpyS2T(_cPthLog + _cArqLog,_cDirTmp)
	If ShellExecute("open" , _cDirTmp + _cArqLog , "" , "" , 1) <= 32
		FWAlertError("Não foi possivel abrir o Arquivo: " + CRLF + _cDirTmp,"MGLT00922")
	EndIf
EndIf

_oProces:SaveLog("Thread:"+_cThread+" Fim Fechamento do Leite")
EventInsert(FW_EV_CHANEL_ENVIRONMENT, FW_EV_CATEGORY_MODULES, "Z00", FW_EV_LEVEL_INFO, "", "Fim Fechamento do Leite",_cParam , .T.) //CHAMADA DO EVENTO

Return

/*
===============================================================================================================================
Programa--------: ITDELZLF
Autor-----------: Alexandre Villar
Data da Criacao-: 16/01/2015
Descrição-------: Rotina para excluir os registros de processamentos de Previsão
Parametros------: _aParam - Parâmetros de configuração do processamento
Retorno---------: _lSqlOk - Informa se processou com sucesso o comando de exclusão
===============================================================================================================================
*/
Static Function ITDELZLF(_aParam As Array,_oProces As Object,_cSetorDeb As Character,_cEveInc As Character)

Local _cQuery		:= "" As Character
Local _lSqlOk		:= .F. As Logical
Local _cMenAux		:= "" As Character
Default _cSetorDeb	:= ""
Default _cEveInc	:= ""

_cQuery := " DELETE "
_cQuery += " FROM  "+ RETSQLNAME('ZLF')
_cQuery += " WHERE ZLF_FILIAL = '"+ xFilial("ZLF")	+"' "
_cQuery += " AND ZLF_CODZLE = '"+ _cCodMix +"' "
_cQuery += " AND (ZLF_ORIGEM =  'F' "			//Somente originados pela rotina do Acerto
If !Empty(_cEveInc)//Apago o evento provisório 000121 gerado no MIX apenas para precificação
	_cQuery += " OR ZLF_EVENTO =  '"+_cEveInc+"' " 
EndIf
_cQuery += ") AND ZLF_ACERTO NOT IN ('B','S') "	//Somente se não estiver bloqueado e se não realizou acerto definitivo
_cQuery += " AND ZLF_TP_MIX =  'L' "			//Somente registros do Leite
_cQuery += " AND ZLF_A2COD BETWEEN '" + _aParam[05] + "' AND '" + _aParam[06] + "' " 
_cQuery += " AND ZLF_A2LOJA BETWEEN '" + _aParam[07] + "' AND '" + _aParam[08] + "' "
_cQuery += " AND ZLF_LINROT BETWEEN '" + _aParam[09] + "' AND '" + _aParam[10] + "' "

If !Empty(_cSetorDeb)
	_cQuery += " AND ZLF_SETOR = '"+ _cSetorDeb +"' "
ElseIf !Empty(_cSetores) //Se o parametro com os setores estiver vazio considera todos.
	_cQuery += " AND ZLF_SETOR  IN "+ FormatIn(_cSetores,';')
EndIf
_cQuery += " AND D_E_L_E_T_ = ' ' "

_lSqlOk := !(TCSqlExec(_cQuery) < 0)

If !_lSqlOk
	_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +IIf(Empty(_cEveInc),';Exclusão de Dados da Previsão','Exclusão do Incentivo à Produção')+';Falhou ao rodar o UPDATE: ['+ _cCodMix +']!'
	_oProces:SaveLog("Thread:"+_cThread+" MGLT00923 - " + _cMenAux)
	_oFile:Write(_cMenAux + '- MGLT00923;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
EndIf

Return(_lSqlOk)

/*
===============================================================================================================================
Programa--------: ITSELZLF
Autor-----------: Alexandre Villar
Data da Criacao-: 16/01/2015
Descrição-------: Rotina para selecionar os produtores na ZLF que possuem eventos de Crédito referentes ao MIX
Parametros------: _aParam - Parâmetros de configuração do processamento
Retorno---------: 
===============================================================================================================================
*/
Static Function ITSELZLF(_aParam As Array,_aDados As Array,_oProces As Object,_cEveInc As Character,_lDefini As Character)

Local _cFilZLF	:= '%' As Character
Local _cFilSE2	:= '%' As Character
Local _cAlias	:= GetNextAlias() As Character
Local _cOrder	:= '' As Character

_aDados	:= {}
If SM0->M0_ESTENT $ "RS/PR"
	_cOrder := "% ZLF_SETOR, ZLF_LINROT, A2_COD, A2_LOJA, A2_L_TANQ, A2_L_TANLJ %"
Else
	_cOrder := "% ZLF_SETOR, ZLF_LINROT, A2_L_TANQ, A2_L_TANLJ, A2_COD, A2_LOJA %"
EndIf	

If !Empty(_cSetores) //Se o parametro com os setores estiver vazio considera todos.
	_cFilZLF += " AND ZLF.ZLF_SETOR IN "+ FormatIn(_cSetores,';')
	_cFilSE2 += " AND E2_L_SETOR IN "+ FormatIn(_cSetores,';')
EndIf
If _aParam[13] == 1
	_cFilZLF += " AND SA2.A2_TIPO = 'F' "
	_cFilSE2 += " AND SA2.A2_TIPO = 'F' "
ElseIf _aParam[13] == 2
	_cFilZLF += " AND SA2.A2_TIPO = 'J' "
	_cFilSE2 += " AND SA2.A2_TIPO = 'J' "
EndIf
If _aParam[14] == 1
	_cFilZLF += " AND SA2.A2_INDCP = '1' "
	_cFilSE2 += " AND SA2.A2_INDCP = '1' "
ElseIf _aParam[14] == 2
	_cFilZLF += " AND SA2.A2_INDCP = '2' "
	_cFilSE2 += " AND SA2.A2_INDCP = '2' "
EndIf
_cFilZLF+= '%'
_cFilSE2+= '%'

BeginSql Alias _cAlias
	SELECT A2_COD, A2_LOJA, ZLF_SETOR, ZLF_LINROT, REGSA2, SUM(CREDITO) CREDITO FROM (
	SELECT A2_COD, A2_LOJA, A2_L_TANQ, A2_L_TANLJ, ZLF_SETOR, ZLF_LINROT, SA2.R_E_C_N_O_ REGSA2,
			Case WHEN ZL8_DEBCRE = 'C' THEN ZLF_TOTAL Else 0 END CREDITO
		FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8, %Table:SA2% SA2
	WHERE ZLF.ZLF_FILIAL = %xFilial:ZLF%
		AND ZL8.ZL8_FILIAL = ZLF.ZLF_FILIAL
		AND ZLF.ZLF_EVENTO = ZL8.ZL8_COD
		AND ZLF.ZLF_A2COD = SA2.A2_COD
		AND ZLF.ZLF_A2LOJA = SA2.A2_LOJA
		AND SA2.A2_COD LIKE 'P%'
		AND SA2.A2_COD BETWEEN %exp:_aParam[5]% AND %exp:_aParam[6]%
		AND SA2.A2_LOJA BETWEEN %exp:_aParam[7]% AND %exp:_aParam[8]%
		AND ZLF.ZLF_LINROT BETWEEN %exp:_aParam[9]% AND %exp:_aParam[10]%
		AND ZLF.ZLF_CODZLE = %exp:_cCodMix%
		AND ZLF.ZLF_ACERTO NOT IN ('B', 'S')
		AND ZLF.ZLF_ORIGEM = 'M'
		AND ZLF.ZLF_TP_MIX = 'L'
		AND ZL8.ZL8_IMPNF = 'S'
		AND (ZL8.ZL8_SB1COD <> ' ' OR ZL8.ZL8_PREFIX <> ' ')
		%exp:_cFilZLF%
		AND ZLF.D_E_L_E_T_ = ' '
		AND ZL8.D_E_L_E_T_ = ' '
		AND SA2.D_E_L_E_T_ = ' '
		UNION ALL
		SELECT A2_COD, A2_LOJA, A2_L_TANQ, A2_L_TANLJ, E2_L_SETOR, A2_L_LI_RO, SA2.R_E_C_N_O_ REGSA2, 0
		FROM %Table:SE2% SE2, %Table:ZL8% ZL8, %Table:SA2% SA2
	WHERE SE2.E2_FILIAL = %xFilial:SE2%
		AND ZL8.ZL8_FILIAL = SE2.E2_FILIAL
		AND ZL8.ZL8_PREFIX = SE2.E2_PREFIXO
		AND SA2.A2_COD = SE2.E2_FORNECE
		AND SA2.A2_LOJA = SE2.E2_LOJA
		AND SE2.E2_FORNECE BETWEEN %exp:_aParam[5]% AND %exp:_aParam[6]%
		AND SE2.E2_LOJA BETWEEN %exp:_aParam[7]% AND %exp:_aParam[8]%
		AND ZL8.ZL8_TPEVEN = 'F'
		AND SE2.E2_TIPO = 'NDF'
		AND SE2.E2_SALDO > 0
		AND SE2.E2_VENCTO <= %exp:_aParam[12]%
		AND SE2.E2_FORNECE LIKE 'P%'
		%exp:_cFilSE2%
		AND SE2.D_E_L_E_T_ = ' '
		AND ZL8.D_E_L_E_T_ = ' '
		AND SA2.D_E_L_E_T_ = ' '
		AND NOT EXISTS (SELECT 1 FROM %Table:ZLF% A
           WHERE A.D_E_L_E_T_ = ' '
           AND A.ZLF_FILIAL = E2_FILIAL
           AND A.ZLF_A2COD = E2_FORNECE
           AND A.ZLF_A2LOJA = E2_LOJA
           AND A.ZLF_SETOR = E2_L_SETOR
           AND A.ZLF_CODZLE = %exp:_cCodMix%
           AND A.ZLF_ACERTO NOT IN ('B', 'S')
           AND A.ZLF_ORIGEM = 'M'
           AND A.ZLF_TP_MIX = 'L'
           AND ZL8.ZL8_IMPNF = 'S')
		  )
	GROUP BY A2_COD, A2_LOJA, A2_L_TANQ, A2_L_TANLJ, ZLF_SETOR, ZLF_LINROT, REGSA2
	ORDER BY %exp:_cOrder%
EndSql

While (_cAlias)->(!Eof())
	//Na previsão eu busco débitos indepente da linha informada pois não tenho essa informação no financeiro. Cenário: Solicito o processamento
	//para a linha A. O produtor não tem movimento nessa linha. Na busca pelos débitos, ele atribuirá os débitos na linha do cadastro (B). Apesar
	//de informar para fechar a linha A, a previsão vai ser rodada para a linha B. A função de exclusão de previsão foi feita para a linha A, logo,
	//na segunda tentativa de rodar a rotina, os eventos gerados para a linha B não serão excluídos, por isso a necessidade de se chamar a função 
	//novamente nesse ponto. Se acho uma linha diferente da que defini para fechar, tenho que apagar a previsão dela para não duplicar
	//1-Tipo de Processamento 2-Mix 3-Versão 4-Setores 5-Fornecedor inicial 6-Fornecedor Final 7-Loja Inicial 8-Loja Final 9-Linha inicial 10-Linha Final 11-Vencimento 12-Data limite financeiro 13-Tipo de Pessoa
	//Apaga evento de Incentivo à produção gerado apenas para fechar o MIX para aprovação. Ele será substituído pelo evento correto
	If !_lDefini .And. !ITDELZLF({_aParam[01],_aParam[02],_aParam[03],_aParam[04],_aParam[05],_aParam[06],_aParam[07],_aParam[08],(_cAlias)->ZLF_LINROT,(_cAlias)->ZLF_LINROT},_oProces,(_cAlias)->ZLF_SETOR,_cEveInc)
		(_cAlias)->(DBSkip())
	EndIf
	aAdd(_aDados , {	(_cAlias)->ZLF_SETOR	,;
						(_cAlias)->ZLF_LINROT	,;
						(_cAlias)->A2_COD 		,;
						(_cAlias)->A2_LOJA		,;
						(_cAlias)->CREDITO		,;
						(_cAlias)->REGSA2		})
	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

Return(_aDados)

/*
===============================================================================================================================
Programa--------: ITVALPRP
Autor-----------: Alexandre Villar
Data da Criacao-: 16/01/2015
Descrição-------: Rotina para validar se o Fornecedor atual já foi preparado para o Fechamento
Parametros------: _cSetor  - Código do Setor do registro atual
				  _cLinha  - Código da Linha/Rota do registro atual
				  _cRetiro - Código do Fornecedor
				  _cLoja   - Código da Loja
Retorno---------: _lRet    - Informa se o Fornecedor está com todos os registros efetivados
===============================================================================================================================
*/
Static Function ITVALPRP(_lDefini As Logical,_cSetor As Character,_cLinha As Character,_cRetiro As Character,_cLoja As Character)

Local _lRet		:= .F. As Logical
Local _cFiltro	:= '%' As Character
Local _cAlias	:= GetNextAlias() As Character
Local _nEfet	:= 0 As Numeric
Local _nOutros	:= 0 As Numeric

If !Empty(_cSetor)
	_cFiltro += " AND ZLF_SETOR  = '"+ _cSetor+"' "
EndIf
If !Empty(_cLinha)
	_cFiltro += " AND ZLF_LINROT = '"+ _cLinha+"' "
EndIf
If !Empty(_cRetiro)
	_cFiltro += " AND ZLF_A2COD  = '"+ _cRetiro+"' "
EndIf
If !Empty(_cLoja)
	_cFiltro += " AND ZLF_A2LOJA = '"+ _cLoja+"' "
EndIf
_cFiltro += '%'

BeginSql Alias _cAlias
	SELECT ZLF_STATUS
	  FROM %Table:ZLF%
	 WHERE ZLF_FILIAL = %xFilial:ZLF%
	   AND ZLF_CODZLE = %exp:_cCodMix%
	   AND ZLF_TP_MIX = 'L'
	   %exp:_cFiltro%
	   AND D_E_L_E_T_ = ' '
	 GROUP BY ZLF_STATUS
EndSql

While (_cAlias)->(!Eof())
	If (_lDefini .And. (_cAlias)->ZLF_STATUS == "E") .Or.(!_lDefini .And.((_cAlias)->ZLF_STATUS == "E" .Or. (_cAlias)->ZLF_STATUS == "A"))
		_nEfet++
	Else
		_nOutros++
	EndIf
(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

_lRet := (_nEfet > 0 .And. _nOutros == 0)

Return _lRet

/*
===============================================================================================================================
Programa--------: ITVALCNF
Autor-----------: Alexandre Villar
Data da Criacao-: 16/01/2015
Descrição-------: Rotina para validar se foram feitos os lançamentos da Nota Fiscal do Produtor e qual o número da nota
Parametros------: _cMix - MIX do processamento atual
				  _cRetiro - Código do Fornecedor
				  _cLoja - Código da Loja
				  _nTipo - Informa se deve retornar a contagem de documentos ou o número do documento
Retorno---------: _aRet    - Retorna a configuração atual referente ao lançamento de NFP ou número da NF-e Pessoa Jurídica
===============================================================================================================================
*/
Static Function ITVALCNF(_cMIX As Character,_cRetiro As Character,_cLoja As Character,_nTipo As Numeric,_lSemNota As Logical)

Local _aRet		:= {} As Array
Local _cAlias	:= GetNextAlias() As Character
Local _cFiltro	:= "% "+ IIf(_lSemNota,"","AND F1_LOJA = '"+_cLoja+"'") +" %" As Character
Local _cCampo	:= "%" + IIf(_nTipo == 1," COUNT(1) QTDCNF "," F1_DOC, F1_SERIE, F1_LOJA ") + "%" As Character

BeginSql Alias _cAlias
	SELECT %exp:_cCampo%
	  FROM %Table:SF1%
	 WHERE F1_FILIAL = %xFilial:SF1%
	   %exp:_cFiltro%
	   AND F1_FORNECE = %exp:_cRetiro%
	   AND F1_FORMUL <> 'S'
	   AND F1_STATUS = 'A'
	   AND F1_L_MIX = %exp:_cMIX%
	   AND D_E_L_E_T_ = ' '
	   ORDER BY F1_DOC
EndSql

If _nTipo == 2
	//Para NFP já validou na primeira passagem e só vai haver 1 NFP. Para NF-e dos produtores que emitem a própria nota,
	//pego a última nota emitida para usar no número da fatura quando aglutinar todas as notas
	aAdd(_aRet , { (_cAlias)->F1_DOC,(_cAlias)->F1_SERIE,(_cAlias)->F1_LOJA })
ElseIf (_cAlias)->QTDCNF <= 0 //Se não encontrar NFP lançada para o produtor não permite o fechamento
	aAdd(_aRet , { .F. , "  " })
ElseIf (_cAlias)->QTDCNF >= 1 .And. _lSemNota//Achou mais de uma NF-e para produtores que emitem a própria nota
	aAdd(_aRet , { .T. , "  " })
ElseIf (_cAlias)->QTDCNF == 1 //Achou uma NFP lançada para o produtor estando assim OK para o fechamento
	aAdd(_aRet , { .T. , "  " })
ElseIf (_cAlias)->QTDCNF >= 2 //Achou mais de uma NFP lançada para o produtor avisando ao Usuario
	aAdd(_aRet , { .T. , "M1" })
EndIf

(_cAlias)->(DBCloseArea())

Return _aRet

/*
===============================================================================================================================
Programa--------: ITGNFPRD
Autor-----------: Alexandre Villar
Data da Criacao-: 16/01/2015
Descrição-------: Rotina para gerar a NF por Produtor
Parametros------: _oProces - 
				  _aParam  - Dados de configuração do processamento da rotina
				  _aDados  - Dados do processamento atual
Retorno---------: _aRet    - Retorna a configuração atual referente ao lançamento de NFP
===============================================================================================================================
*/
Static Function ITGNFPRD(_oProces As Object,_aParam As Array,_nRegNFP As Numeric,_cEveInc As Character,_lNf1Item As Logical)

Local _aArea		:= FWGetArea() As Array
Local _aCab			:= {} As Array
Local _aItens		:= {} As Array
Local _aDadNFP		:= {} As Array
Local _cCondPgto	:= StrZero((_aParam[11] - dDataBase) + 1 , 3) As Character
Local _cAlias		:= GetNextAlias() As Character
Local _cItem		:= '0000' As Character
Local _cSeekZLF		:= '' As Character
Local _cSeekSD1		:= '' As Character
Local _cTES			:= '' As Character
Local _lRet			:= .T. As Logical
Local _nQtde		:= 0 As Numeric
Local _nVlrUnit		:= 0 As Numeric
Local _nTotalNf		:= 0 As Numeric
Local _cMenAux		:= "" As Character
Local _nRegZLF		:= 0 As Numeric
Local _cGroup 		:= '' As Character

_nRegNFP := 0

//Apaga evento de Incentivo à produção gerado apenas para fechar o MIX para aprovação. Ele será substituído pelo evento correto
//1-Tipo de Processamento 2-Mix 3-Versão 4-Setores 5-Fornecedor inicial 6-Fornecedor Final 7-Loja Inicial 8-Loja Final 9-Linha inicial 10-Linha Final 11-Vencimento 12-Data limite financeiro 13-Tipo de Pessoa
If !Empty(_cEveInc) .And.!ITDELZLF({_aParam[01],_aParam[02],_aParam[03],_aParam[04],_cCODSA2,_cCODSA2,_cLOJSA2,_cLOJSA2,_cCODZL3,_cCODZL3},_oProces,_cCODZL2,_cEveInc)
		_lRet := .F.
		_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Geração da NF do Produtor;Falhou ao apagar o Incentivo à Produção'
		_oProces:SaveLog("Thread:"+_cThread+" MGLT00938 - " + _cMenAux)
		_oFile:Write(_cMenAux +'- MGLT00938;'+LTrim(Str(Seconds()-_nTempM)) +' segundos' + CRLF)
	Return(_lRet)
EndIf

aAdd(_aCab , { "F1_TIPO"		, "N"					, NIL }) // Tipo da Nota = Beneficiamento.
aAdd(_aCab , { "F1_FORMUL"		, "S"					, NIL }) // Formulario Proprio = Sim.
aAdd(_aCab , { "F1_DOC"		, _cNroNota				, NIL }) // Numero do Documento.
aAdd(_aCab , { "F1_SERIE"		, _cSerie  				, NIL }) // Serie do Documento.
aAdd(_aCab , { "F1_PREFIXO"	, _cPrefixo				, NIL }) // Serie do Documento.
aAdd(_aCab , { "F1_DTDIGIT"	, dDataBase				, NIL }) // Data de Digitação.
aAdd(_aCab , { "F1_EMISSAO"	, dDataBase				, NIL }) // Data de Emissao.
aAdd(_aCab , { "F1_DESPESA"	, 0						, NIL }) // Despesa
aAdd(_aCab , { "F1_FORNECE"	, _cCODSA2				, NIL }) // Codigo do Fornecedor.
aAdd(_aCab , { "F1_LOJA"	  	, _cLOJSA2				, NIL }) // Loja do Fornecedor.
aAdd(_aCab , { "F1_ESPECIE"	, "SPED"				, NIL }) // Especie do Documento.
aAdd(_aCab , { "F1_COND"		, _cCondPgto			, NIL }) // Condicao de Pagamento.
aAdd(_aCab , { "F1_DESCONT"	, 0						, NIL }) // Desconto
aAdd(_aCab , { "F1_SEGURO"		, 0						, NIL }) // Seguro
aAdd(_aCab , { "F1_FRETE"		, 0						, NIL }) // Frete
aAdd(_aCab , { "E2_NATUREZ"	, _cNatureza			, NIL }) // Frete
aAdd(_aCab , { "F1_PESOL"		, 0						, NIL }) // Peso Liquido
aAdd(_aCab , { "E2_PARCELA"	, "01"					, NIL }) // Parcela
aAdd(_aCab , { "F1_TPFRETE"	, 'C'					, NIL }) // TP Frete
aAdd(_aCab , { "F1_L_MIX"		, _cCodMix				, NIL }) // Código do Mix
aAdd(_aCab , { "F1_L_SETOR"	, _cCODZL2				, NIL }) // Código do Setor
aAdd(_aCab , { "F1_L_LINHA"	, _cCODZL3				, NIL }) // Código da Linha/Rota
aAdd(_aCab , { "F1_L_TPNF"		, 'P'					, NIL }) // Tipo de NF - P = Produtor

If _lNf1Item
	_cCampos := '% MAX(ZLF_QTDBOM) ZLF_QTDBOM, Round(SUM(ZLF_TOTAL)/MAX(ZLF_QTDBOM),8) ZLF_VLRLTR, SUM(ZLF_TOTAL) ZLF_TOTAL %'
	_cGroup := '%GROUP BY B1_COD, B1_LOCPAD, A2_COD, A2_LOJA, A2_TIPO, ZLF_SETOR, ZL8_TES, ZL8_TESSEN, ZL8_TESIP1, ZL8_TESSE2, A2_INDCP, ZL8_DEBCRE, A2_INCLTMG %'
Else
	_cCampos := '% ZLF_EVENTO, ZL8_COD, ZLF_SEQ, ZL8_DESCRI, ZL8_QTUNIC, ZLF_QTDBOM,'
	_cCampos += ' ZLF_VLRLTR, ZLF_TOTAL %'
	_cGroup := '% ORDER BY ZLF_EVENTO %'
EndIf
//====================================================================================================
// Verifica pagamento para ser efetuado no mesmo dia do fechamento
//====================================================================================================
BeginSql Alias _cAlias
	SELECT B1_COD, B1_LOCPAD, A2_COD, A2_LOJA, A2_TIPO, ZLF_SETOR, ZL8_TES, ZL8_TESSEN, ZL8_TESIP1, ZL8_TESSE2, A2_INDCP, ZL8_DEBCRE, A2_INCLTMG, %exp:_cCampos%
	  FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8, %Table:SB1% SB1, %Table:SA2% SA2
	 WHERE ZLF.ZLF_FILIAL = %xFilial:ZLF%
	   AND ZL8.ZL8_FILIAL = ZLF.ZLF_FILIAL
	   AND ZLF.ZLF_A2COD = SA2.A2_COD
	   AND ZLF.ZLF_A2LOJA = SA2.A2_LOJA
	   AND ZLF.ZLF_EVENTO = ZL8.ZL8_COD
	   AND ZL8.ZL8_SB1COD = SB1.B1_COD
	   AND ZLF.ZLF_ORIGEM <> 'F'
	   AND ZLF.ZLF_ACERTO NOT IN ('B', 'S')
	   AND ZLF.ZLF_TP_MIX = 'L'
	   AND ZL8.ZL8_SB1COD <> ' '
	   AND ZL8.ZL8_IMPNF = 'S'
	   AND ZLF.ZLF_CODZLE = %exp:_cCodMix%
	   AND ZLF.ZLF_LINROT = %exp:_cCODZL3%
	   AND ZLF.ZLF_SETOR = %exp:_cCODZL2%
	   AND SA2.A2_COD = %exp:_cCODSA2%
	   AND SA2.A2_LOJA = %exp:_cLOJSA2%
	   AND ZLF.D_E_L_E_T_ = ' '
	   AND ZL8.D_E_L_E_T_ = ' '
	   AND SA2.D_E_L_E_T_ = ' '
	   AND SB1.D_E_L_E_T_ = ' '
	   %exp:_cGroup%
EndSql

While (_cAlias)->(!Eof())
	If _lNf1Item
		_nQtde := (_cAlias)->ZLF_QTDBOM
		_nVlrUnit := (_cAlias)->ZLF_VLRLTR
	Else
		If (_cAlias)->ZLF_QTDBOM > 0
			If AllTrim(Upper((_cAlias)->ZL8_QTUNIC)) == 'N'
				_nQtde := (_cAlias)->ZLF_QTDBOM
				_nVlrUnit := (_cAlias)->ZLF_VLRLTR
			Else
				_nQtde := 1
				_nVlrUnit := (_cAlias)->ZLF_TOTAL
			EndIf
		Else
			_nQtde := 1
		EndIf
	EndIf
	
	If (_cAlias)->A2_INDCP == '1' .And. (_cAlias)->A2_INCLTMG <> '1'//Cálculo sobre a produção (Calcula Gilrat e Senar) e sem TES de Incentivo à produção (ICMS Isento)
		_cTES := (_cAlias)->ZL8_TES// TES Sem ICMS e com Gilrat
	ElseIf (_cAlias)->A2_INDCP == '2' .And. (_cAlias)->A2_INCLTMG <> '1'//Cálculo sobre a folha (Calcula apenas Senar) e sem TES de Incentivo à produção (ICMS Isento)
		_cTES := (_cAlias)->ZL8_TESSEN// TES Sem ICMS e sem Gilrat
	ElseIf (_cAlias)->A2_INDCP == '1' .And. (_cAlias)->A2_INCLTMG == '1'//Cálculo sobre a produção (Calcula Gilrat e Senar) e TES de Incentivo à produção (calcula ICMS Tributado ou Outros)
		_cTES := (_cAlias)->ZL8_TESIP1// TES com ICMS e com Gilrat
	ElseIf (_cAlias)->A2_INDCP == '2' .And. (_cAlias)->A2_INCLTMG == '1'//Cálculo sobre a folha (Calcula apenas Senar) e TES de Incentivo à produção (calcula ICMS Tributado ou Outros)
		_cTES := (_cAlias)->ZL8_TESSE2// TES com ICMS e sem Gilrat
	ElseIf (_cAlias)->A2_TIPO == 'J'// PJ usa a TES "padrão"
		_cTES := (_cAlias)->ZL8_TES// TES Sem ICMS e com Gilrat
	EndIf
	If Empty(_cTes)
		_cMenAux := "TES não localizada. Verifique configurações de Impostos no cadastro do Produtor e cadastro do Evento."
		_lRet := .F.
		Exit
	EndIf
	_cItem    := Soma1(_cItem)
	If !_lNf1Item
		_cSeekSD1 := xFilial("SD1") + _cNroNota + _cSerie + _cCODSA2 + _cLOJSA2 + (_cAlias)->B1_COD + _cItem
		_cSeekZLF := ITGRVZLF(_oProces,(_cAlias)->ZL8_COD,0,_cSeekSD1,.F./*_lGrvZLF*/,.T./*_lAltZLF*/,(_cAlias)->ZLF_SEQ,/*_cLinha*/,/*_cSetor*/,_aParam,@_nRegZLF,/*_lImp*/,(_cAlias)->ZL8_DEBCRE,@_lRet)
	EndIf

	If _lRet
		_aDadNFP := {}
		If ZL2->ZL2_VLDNFP == "1" .And. _cItem == "0001"// SIM - O SETOR EXIGE A AMARRACAO DA CONTRANOTA(NFP)
			_aDadNFP := ITRETNFP(_cCodMix, _cCODSA2,_cLOJSA2)
		Else
			aAdd(_aDadNFP , { " " , " " , " " })
		EndIf
		aAdd(_aItens , {	{ "D1_ITEM"		, _cItem				, NIL },;	// Sequencia Item Pedido
							{ "D1_COD"		, (_cAlias)->B1_COD		, NIL },;	// Codigo do Produto
							{ "D1_QUANT"	, _nQtde				, NIL },;	// Quantidade
							{ "D1_VUNIT"	, _nVlrUnit				, NIL },;	// Valor Unitario
							{ "D1_TOTAL"	, (_cAlias)->ZLF_TOTAL	, NIL },;	// Valor Total
							{ "D1_TES"		, _cTes					, NIL },;	// Tipo de Entrada - TES //
							{ "D1_LOCAL"	, (_cAlias)->B1_LOCPAD	, NIL },;	// Armazem Padrao do Produto
							{ "D1_SEGURO"	, 0						, NIL },;	// Seguro
							{ "D1_VALFRE"	, 0						, NIL },;	// Frete
							{ "D1_DESPESA"	, 0						, NIL },;	// Despesa
							{ "D1_NFORI"	, _aDadNFP[01][01]		, NIL },;	// NF de Origem (ContraNota - NFP) para alguns setores devido a legislacao da SEFAZ
							{ "D1_SERIORI"	, _aDadNFP[01][02]		, NIL },;	// SERIE de Origem (ContraNota - NFP) para alguns setores devido a legislacao da SEFAZ
							{ "D1_ITEMORI"	, _aDadNFP[01][03]		, NIL },;	// ITEM de Origem (ContraNota - NFP) para alguns setores devido a legislacao da SEFAZ
							{ "E2_NATUREZ"	, _cNatureza			, NIL },;	// Natureza
							{ "D1_L_DESCR"	, If(_lNf1Item,'',(_cAlias)->ZL8_DESCRI)	, NIL },;	// Descricao do Evento na NF
							{ "D1_L_EVENT"	, If(_lNf1Item, '',(_cAlias)->ZLF_EVENTO)	, NIL },;	// Descricao do Evento na NF
							{ "D1_L_SEEK"	, _cSeekZLF				, NIL },;	// Chave de pesquisa da SD1 na ZLF
							{ "AUTDELETA"	, "N"					, NIL }})	// Incluir sempre no último elemento do array de cada item
								
		_nTotalNf += (_cAlias)->ZLF_TOTAL
	EndIf
		
	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

//====================================================================================================
// SigaAuto de Geracao da Nota.
//====================================================================================================
If _lRet .And. !Empty(_aCab) .And. !Empty(_aItens)
    
	lMsErroAuto	:= .F.
	lMsHelpAuto	:= .T.
	
	_oProces:IncRegua2('Processo [04] - Processando a inclusão (ExecAuto)...')
	
	MSExecAuto({ |x,y,z| MATA103(x,y,z) }, _aCab,_aItens,3) //Inclusao
	
	_oProces:IncRegua2('Processo [04] - Verificando documento incluído (ExecAuto)...')
	
	If lMsErroAuto
		_lRet := .F.
		_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Geração da NF do Produtor;Falhou ao processar o ExecAuto: '+ MostraErro()
		_oProces:SaveLog("Thread:"+_cThread+" MGLT00927 - " + _cMenAux)
		_oFile:Write(_cMenAux +'- MGLT00927;'+LTrim(Str(Seconds()-_nTempM)) +' segundos' + CRLF)
	Else
		_nRegNFP := SF1->(Recno())
	EndIf
Else
	_lRet := .F.
	_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Geração da NF do Produtor;Não foi possível gerar a NF do Produtor: Dados incompletos, verifique com o Suporte! '+ _cMenAux
	_oProces:SaveLog("Thread:"+_cThread+" MGLT00924 - " + _cMenAux)
	_oFile:Write(_cMenAux + ' - MGLT00924;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
EndIf

FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa--------: ITGRVZLF
Autor-----------: Alexandre Villar
Data da Criacao-: 16/01/2015
Descrição-------: Rotina para gravar os dados na Tabela ZLF
Parametros------: 
Retorno---------: _aRet    - Retorna a configuração atual referente ao lançamento de NFP
===============================================================================================================================
*/
Static Function ITGRVZLF(_oProces As Object,_cEvento As Character,_nValor As Numeric,_cSeek As Character,_lGrvZLF As Logical,;
						_lAltZLF As Logical,_cSeq As Character,_cLinha As Character,_cSetor As Character,_aParam As Array,;
						_nRegZLF As Numeric,_lImp As Logical,_cDebCre As Character,_lOk As Logical)

Local _aArea		:= FWGetArea() As Array
Local _aDadZLF		:= {} As Array
Local _cRet			:= '' As Character
Local _cDesSet		:= '' As Character
Local _cDesLin		:= '' As Character
Local _cUpdate		:= '' As Character
Local _cMenAux		:= '' As Character
Local _lNovo		:= .T. As Logical
Default _cSeq		:= ITNEWZLF(_cCodMix,_cCODSA2,_cLOJSA2)
Default _cSeek		:= ''
Default _lGrvZLF	:= .T.
Default _lAltZLF	:= .F.
Default _cLinha		:= ''
Default _cSetor		:= ''

// Se For um imposto gerado pela NF-e, ele será "descontado" do saldo antes de qualquer coisa,
// garantindo que haja saldo suficiente, logo, já atualizo o valor pago para o evento
Default _lImp		:= .F. 

If !Empty(_cSetor)
	_cDesSet := Posicione('ZL2',1,xFilial('ZL2')+_cSetor,'ZL2_DESCRI')
EndIf

If !Empty(_cLinha)
	_cDesLin := Posicione('ZL3',1,xFilial('ZL3')+_cLinha,'ZL3_DESCRI')
EndIf

FWRestArea(_aArea)

//====================================================================================================
// Se altera a ZLF. Usado quando o Evento foi lancado na ZLF.
//====================================================================================================
If _lAltZLF
	//Quando a chave possuir NDF a ZLF está posicionada e preciso manter ela assim. Se trata de evevntos de débito gerados pelo Mix
	If 'NDF' $ _cSeek
		RecLock("ZLF",.F.)
	        ZLF->ZLF_L_SEEK := _cSeek
        ZLF->(MSUnLock())
	Else //Quando não houver, a chamada foi feita para gravar dados das notas fiscais.
		_cUpdate := " UPDATE "+ RETSQLNAME('ZLF') +" SET ZLF_L_SEEK = '"+ _cSeek +"' "
		_cUpdate += " WHERE ZLF_FILIAL = '"+ xFilial("ZLF")	+"' "
		_cUpdate += " AND ZLF_CODZLE = '"+ _cCodMix +"' "
		_cUpdate += " AND ZLF_A2COD  = '"+ _cCODSA2 +"' "
		_cUpdate += " AND ZLF_A2LOJA = '"+ _cLOJSA2 +"' "
		_cUpdate += " AND ZLF_EVENTO = '"+ _cEvento +"' "
		_cUpdate += " AND ZLF_SETOR = '"+ _cSetor +"' "
		_cUpdate += " AND ZLF_SEQ    = '"+ _cSeq    +"' "
		_cUpdate += " AND D_E_L_E_T_ = ' ' "
		
		_lOk := !(TCSqlExec(_cUpdate) < 0)
	EndIf	
	If !_lOk
        _cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Erro na atualização do ZLF_L_SEEK ['+ _cCodMix +']!'
        _oProces:SaveLog("Thread:"+_cThread+" MGLT00942 - " + _cMenAux)
		_oFile:Write(_cMenAux + ' - MGLT00942;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
	EndIf
//Em situações de baixas parciais onde o saldo é zerado não deve ser gravado movimento com valor 0
ElseIf _nValor > 0
    //====================================================================================================
    // Posiciona na ZLF para verificar se ja existe um registro para o mesmo evento. Se existir e a 
    // variavel lGrvZLF estiver como .T., ele grava um novo registro para o mesmo evento.
    //====================================================================================================
    ZLF->(DBSetOrder(3))
    _lAchou := ZLF->(DBSeek(xFilial("ZLF") + _cCodMix + _cVersao + _cCODZL2 + _cCODZL3 + _cEvento + _cCODSA2 + _cLOJSA2))
    If _lAchou .And. !_lGrvZLF
        _lNovo := .F.//Não grava ZLF. Apenas usa o que está posicionado. Válido apenas para o índice 3
    EndIf
    If !_lAchou
        ZLF->(DBSetOrder(8))
        _lAchou := ZLF->(DBSeek(xFilial("ZLF") + _cCodMix + _cVersao + _cCODZL2 + _cCODZL3 + _cCODSA2 + _cLOJSA2))
    EndIf
    //Se posicionou pelo índice 3 e era para gravar (_lGrvZLF=.T.), grava. Se posicinou mas não é para gravar, não faz nada.
    //O posicionamento será usado apenas para montar a chave a ser referenciada no futuro
    If _lAchou .And. _lNovo 
        _aDadZLF := {	{ 'ZLF_FILIAL'	, xFilial("ZLF")										} ,;
                        { 'ZLF_CODZLE'	, ZLF->ZLF_CODZLE										} ,;
                        { 'ZLF_VERSAO'	, ZLF->ZLF_VERSAO										} ,;
                        { 'ZLF_DTINI'	, ZLF->ZLF_DTINI										} ,;
                        { 'ZLF_DTFIM'	, ZLF->ZLF_DTFIM										} ,;
                        { 'ZLF_SETOR'	, IIf(Empty(_cSetor) , ZLF->ZLF_SETOR  , _cSetor )	} ,;
                        { 'ZLF_LINROT'	, IIf(Empty(_cLinha) , ZLF->ZLF_LINROT , _cLinha )	} ,;
                        { 'ZLF_A2COD'	, ZLF->ZLF_A2COD										} ,;
                        { 'ZLF_A2LOJA'	, ZLF->ZLF_A2LOJA										} ,;
                        { 'ZLF_EVENTO'	, _cEvento												} ,;
                        { 'ZLF_SEQ'		, _cSeq													} ,;
                        { 'ZLF_DEBCRE'	, _cDebCre  											} ,;
                        { 'ZLF_TOTAL'	, _nValor												} ,;
                        { 'ZLF_VLRPAG'	, IIf(_lImp,_nValor,0) 									} ,;
                        { 'ZLF_ORIGEM'	, 'F'													} ,;
                        { 'ZLF_RETIRO'	, ZLF->ZLF_RETIRO										} ,;
                        { 'ZLF_RETILJ'	, ZLF->ZLF_RETILJ										} ,;
                        { 'ZLF_ACERTO'	, ZLF->ZLF_ACERTO										} ,;
                        { 'ZLF_TP_MIX'	, ZLF->ZLF_TP_MIX										} ,;
                        { 'ZLF_TIPO'	, ZLF->ZLF_TIPO											} ,;
                        { 'ZLF_ENTMIX'	, ZL8->ZL8_MIX											} ,;
                        { 'ZLF_STATUS'	, ZLF->ZLF_STATUS										} ,;
                        { 'ZLF_L_SEEK'	, _cSeek												} ,;
                        { 'ZLF_EST'		, ZLF->ZLF_EST											} ,;
                        { 'ZLF_MUN'		, ZLF->ZLF_MUN											} ,;
                        { 'ZLF_F1SEEK'	, ZLF->ZLF_F1SEEK										} ,;
                        { 'ZLF_DTCALC'	, ZLF->ZLF_DTCALC										} ,;
                        { 'ZLF_DTFECH'	, ZLF->ZLF_DTFECH										}  }
    ElseIf !_lAchou //Se não posicinou pelo índice 3 ou 8, retorna erro
        _lOk := .F.
        _cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Geração dos Itens do MIX;Não foram encontrados registros do Produtor no MIX ['+ _cCodMix +']!'
        _oProces:SaveLog("Thread:"+_cThread+" MGLT00926 - " + _cMenAux)
		_oFile:Write(_cMenAux + ' - MGLT00926;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
    EndIf

    If _lOk
        If !Empty(_aDadZLF)
            RecLock("ZLF" , .T.)
                ZLF->ZLF_FILIAL := _aDadZLF[01][02] // xFilial("ZLF")
                ZLF->ZLF_CODZLE := _aDadZLF[02][02] // ZLF->ZLF_CODZLE
                ZLF->ZLF_VERSAO := _aDadZLF[03][02] // ZLF->ZLF_VERSAO
                ZLF->ZLF_DTINI  := _aDadZLF[04][02] // ZLF->ZLF_DTINI
                ZLF->ZLF_DTFIM  := _aDadZLF[05][02] // ZLF->ZLF_DTFIM
                ZLF->ZLF_SETOR  := _aDadZLF[06][02] // IIf(Empty(_cSetor) , ZLF->ZLF_SETOR  , _cSetor )
                ZLF->ZLF_LINROT := _aDadZLF[07][02] // IIf(Empty(_cLinha) , ZLF->ZLF_LINROT , _cLinha )
                ZLF->ZLF_A2COD  := _aDadZLF[08][02] // ZLF->ZLF_A2COD
                ZLF->ZLF_A2LOJA := _aDadZLF[09][02] // ZLF->ZLF_A2LOJA
                ZLF->ZLF_EVENTO := _aDadZLF[10][02] // ZL8->ZL8_COD
                ZLF->ZLF_SEQ    := _aDadZLF[11][02] // _cSeq
                ZLF->ZLF_DEBCRE := _aDadZLF[12][02] // 'D'
                ZLF->ZLF_TOTAL  := _aDadZLF[13][02] // _nValor
                ZLF->ZLF_VLRPAG := _aDadZLF[14][02] // 0
                ZLF->ZLF_ORIGEM := _aDadZLF[15][02] // 'F'
                ZLF->ZLF_RETIRO := _aDadZLF[16][02] // ZLF->ZLF_RETIRO
                ZLF->ZLF_RETILJ := _aDadZLF[17][02] // ZLF->ZLF_RETILJ
                ZLF->ZLF_ACERTO := _aDadZLF[18][02] // ZLF->ZLF_ACERTO
                ZLF->ZLF_TP_MIX := _aDadZLF[19][02] // ZLF->ZLF_TP_MIX
                ZLF->ZLF_TIPO   := _aDadZLF[20][02] // ZLF->ZLF_TIPO
                ZLF->ZLF_ENTMIX := _aDadZLF[21][02] // ZL8->ZL8_MIX
                ZLF->ZLF_STATUS := _aDadZLF[22][02] // ZLF->ZLF_STATUS
                ZLF->ZLF_L_SEEK := _aDadZLF[23][02] // _cSeek
                ZLF->ZLF_EST    := _aDadZLF[24][02] // ZLF->ZLF_EST
                ZLF->ZLF_MUN    := _aDadZLF[25][02] // ZLF->ZLF_MUN
                ZLF->ZLF_F1SEEK := _aDadZLF[26][02] // ZLF->ZLF_F1SEEK
                ZLF->ZLF_DTCALC	:= _aDadZLF[27][02] //ZLF->ZLF_DTCALC
                ZLF->ZLF_DTFECH := _aDadZLF[28][02] // ZLF->ZLF_DTFECH
            ZLF->(MSUnLock())
        EndIf
    EndIf
EndIf

_cRet := ZLF->(ZLF_FILIAL+ZLF_CODZLE+ZLF_VERSAO+ZLF_A2COD+ZLF_A2LOJA+ZLF_EVENTO+ZLF_SEQ)
_nRegZLF:= ZLF->(Recno())

FWRestArea(_aArea)

Return(_cRet)

/*
===============================================================================================================================
Programa--------: ITNEWZLF
Autor-----------: Alexandre Villar
Data da Criacao-: 16/01/2015
Descrição-------: Rotina para retornar o próximo código sequencial para a tabela ZLF
Parametros------: _cCodMIX - Código do MIX
				  _cCodFor - Código do Fornecedor
				  _cLojFor - Loja do Fornecedor
Retorno---------: _cRet    - Retorna o próximo código sequencial para cadastro na tabela ZLF
===============================================================================================================================
*/
Static Function ITNEWZLF(_cCodMix As Character,_cCodFor As Character,_cLojFor As Character)

Local _cRet		:= "" As Character
Local _cAlias	:= GetNextAlias() As Character

BeginSql Alias _cAlias
	SELECT MAX(ZLF_SEQ) COD
	  FROM %Table:ZLF%
	 WHERE ZLF_FILIAL = %xFilial:ZLF%
	   AND ZLF_CODZLE = %exp:_cCodMIX%
	   AND ZLF_A2COD = %exp:_cCodFor%
	   AND ZLF_A2LOJA = %exp:_cLojFor%
	   AND D_E_L_E_T_ = ' '
EndSql

If !Empty((_cAlias)->COD)
	_cRet := Soma1((_cAlias)->COD)
Else
	_cRet := StrZero(1 , TamSX3('ZLF_SEQ')[01])
EndIf

(_cAlias)->(DBCloseArea())

Return(_cRet)

/*
===============================================================================================================================
Programa--------: ITRETNFP
Autor-----------: Alexandre Villar
Data da Criacao-: 16/01/2015
Descrição-------: Rotina para retornar os dados da NFP
Parametros------: _cFilial - Filial do Fornecedor
				  _cCodFor - Código do Fornecedor
				  _cLojFor - Loja do Fornecedor
Retorno---------: _aRet    - Retorna array com os dados da NFP se existir
===============================================================================================================================
*/
Static Function ITRETNFP(_cCodMix As Character,_cCodFor As Character,_cLojFor As Character)

Local _aRet		:= {} As Array
Local _cAlias	:= GetNextAlias() As Character

//====================================================================================================
// Obtem se teve Contra Nota(NFP) lançada via Documento de Entrada no mês de emissão da NF
//====================================================================================================
BeginSql Alias _cAlias
SELECT F1_DOC, F1_SERIE
  FROM %Table:SF1%
 WHERE F1_FILIAL = %xFilial:SF1%
   AND F1_FORNECE = %exp:_cCodFor%
   AND F1_LOJA = %exp:_cLojFor%
   AND F1_FORMUL <> 'S'
   AND F1_STATUS = 'A'
   AND F1_L_MIX = %exp:_cCodMix%
   AND D_E_L_E_T_ = ' '
EndSql

If (_cAlias)->(!Eof())
	aAdd(_aRet , { (_cAlias)->F1_DOC , (_cAlias)->F1_SERIE , "0001" })
EndIf

(_cAlias)->(DBCloseArea())

If Empty(_aRet)
	_aRet := {{'','',''}}
EndIf

Return(_aRet)

/*
===============================================================================================================================
Programa--------: ITINCSE2
Autor-----------: Alexandre Villar
Data da Criacao-: 19/01/2015
Descrição-------: Rotina para Incluir títulos no Financeiro
Parametros------: _cCodFor  - Código do Fornecedor
				  _cLojFor  - Loja do Fornecedor
				  _nVlrTit  - Valor do título a ser gerado
				  _cPrefixo - Prefixo do título
				  _cNroTit  - Número do título
				  _cParcela - Parcela do título
				  _cTipo    - Tipo do título
				  _cSeek    - Chave de busca
				  _cNatz 	- Natureza financeira
				  _lSemNota	- Indica se o fechamento não gera NF-e
Retorno---------: _lRet     - Retorna se o título foi gerado com sucesso
===============================================================================================================================
*/
Static Function ITINCSE2(_oProces As Object,_nVlrTit As Numeric,_cPrefix As Character,_cNroTit As Character,_cParcel As Character,_cTipo As Character,;
						 _cSeek As Character, _cNatz As Character,_lSemNota As Logical,_dVencto As Date)

Local _aAutoSE2 := {} As Array
Local _nModAnt  := nModulo As Numeric
Local _cModAnt  := cModulo As Character
Local _cChvAux	:= '' As Character
Local _lRet		:= .T. As Logical
Local _cMenAux	:= "" As Character
Local _cAlias	:= GetNextAlias() As Character
Local _cHist	:= "GLT"+ StrZero(Month(ZLE->ZLE_DTINI),2) +"/"+ StrZero(Year(ZLE->ZLE_DTINI),4) +'-'+ _cCodMix As Character

//====================================================================================================
// Verifica se o titulo ja existe na base, para nao duplicar.
//====================================================================================================
BeginSql alias _cAlias
	SELECT COUNT(1) QTD
	FROM %Table:SE2%
	WHERE E2_FILIAL = %xFilial:SE2%
	AND E2_PREFIXO = %exp:_cPrefix%
	AND E2_NUM = %exp:_cNroTit%
	AND E2_PARCELA = %exp:_cParcel%
	AND E2_TIPO = %exp:_cTipo%
	AND E2_FORNECE = %exp:_cCODSA2%
	AND E2_LOJA = %exp:_cLOJSA2%
	AND E2_L_MIX = %exp:_cCodMIX%
	AND E2_L_SETOR = %exp:_cCODZL2%
	AND E2_L_LINRO = %exp:_cCODZL3%
	AND D_E_L_E_T_ = ' '
EndSql

If (_cAlias)->QTD == 1
	_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Geração dos Itens do MIX;Já existe um título com a chave atual para o Produtor ['+ _cChvAux +']!'
	_oProces:SaveLog("Thread:"+_cThread+" MGLT00935 - " + _cMenAux)
	_oFile:Write(' - MGLT00935;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
	_lRet := .F.
EndIf
(_cAlias)->(DBCloseArea())

If _lRet .And. _lSemNota
	_cAlias	:= GetNextAlias()
	BeginSql alias _cAlias
		SELECT MAX(E2_PARCELA) PARC, COUNT(1) QTD
		FROM %Table:SE2%
		WHERE E2_FILIAL = %xFilial:SE2%
		AND E2_PREFIXO = %exp:_cPrefix%
		AND E2_NUM = %exp:_cNroTit%
		AND E2_TIPO = %exp:_cTipo%
		AND E2_FORNECE = %exp:_cCODSA2%
		AND E2_LOJA = %exp:_cLOJSA2%
		AND E2_L_MIX = %exp:_cCodMIX%
		AND D_E_L_E_T_ = ' '
	EndSql
	If (_cAlias)->QTD > 0 
		_cParcel := Soma1(SubStr((_cAlias)->PARC,1,Len(_cParcel)))
	EndIf
	(_cAlias)->(DBCloseArea())
EndIf

If _lRet

	// Array com os dados a serem passados para o SigaAuto.
	aAdd(_aAutoSE2 , { "E2_PREFIXO"	, _cPrefix							, Nil })
	aAdd(_aAutoSE2 , { "E2_NUM"		, _cNroTit							, Nil })
	aAdd(_aAutoSE2 , { "E2_TIPO"		, _cTipo							, Nil })
	aAdd(_aAutoSE2 , { "E2_PARCELA"	, _cParcel							, Nil })
	aAdd(_aAutoSE2 , { "E2_NATUREZ"	, IIf(Empty(_cNatz),_cNatureza,_cNatz), Nil })//Recebe natureza do evento. Quando estiver em branco, usa a natureza genérica
	aAdd(_aAutoSE2 , { "E2_FORNECE"	, _cCODSA2							, Nil })
	aAdd(_aAutoSE2 , { "E2_LOJA"		, _cLOJSA2							, Nil })
	aAdd(_aAutoSE2 , { "E2_EMISSAO"	, dDataBase							, Nil })
	aAdd(_aAutoSE2 , { "E2_VENCTO"		, _dVencto							, Nil })
	aAdd(_aAutoSE2 , { "E2_VENCREA"	, DataValida(_dVencto)				, Nil })
	aAdd(_aAutoSE2 , { "E2_HIST"		, _cHist							, Nil })
	aAdd(_aAutoSE2 , { "E2_VALOR"		, _nVlrTit							, Nil })
	aAdd(_aAutoSE2 , { "E2_PORCJUR"	, 0									, Nil })
	aAdd(_aAutoSE2 , { "E2_DATALIB"	, dDataBase							, Nil })
	aAdd(_aAutoSE2 , { "E2_USUALIB"	, cUserName							, Nil })
	aAdd(_aAutoSE2 , { "E2_L_LINRO"	, _cCODZL3							, Nil })
	aAdd(_aAutoSE2 , { "E2_L_SETOR"	, _cCODZL2							, Nil })
	aAdd(_aAutoSE2 , { "E2_L_MIX"		, _cCodMix							, Nil })
	aAdd(_aAutoSE2 , { "E2_L_SITUA"	, "I"	  							, Nil })
	aAdd(_aAutoSE2 , { "E2_L_SEEK"		, _cSeek							, Nil })
	aAdd(_aAutoSE2 , { "E2_ORIGEM"		, "MGLT009"							, Nil })
	If SA2->A2_L_TPPAG == 'B'
		aAdd(_aAutoSE2 , { "E2_L_TPPAG"	, SA2->A2_L_TPPAG					, Nil })
		aAdd(_aAutoSE2 , { "E2_L_BANCO"	, SA2->A2_BANCO						, Nil })
		aAdd(_aAutoSE2 , { "E2_L_AGENC"	, SA2->A2_AGENCIA					, Nil })
		aAdd(_aAutoSE2 , { "E2_L_CONTA"	, SA2->A2_NUMCON					, Nil })
	EndIf
	// Altera o modulo para Financeiro, senao o SigaAuto nao executa.
	nModulo := 6
	cModulo := "FIN"
	lMsErroAuto	:= .F.
	lMsHelpAuto	:= .T.

	MSExecAuto({|x,y| FINA050(x,y) } , _aAutoSE2 , 3)
	
	// Verifica se houve erro no SigaAuto e mostra o erro.
	If lMsErroAuto
		_lRet := .F.
		_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Geração de títulos no Financeiro;Erro na inclusão de título ' + MostraErro()
		_oProces:SaveLog("Thread:"+_cThread+" MGLT00936 - " + _cMenAux)
		_oFile:Write(_cMenAux+' - MGLT00936;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
	EndIf
	// Restaura o modulo em uso.
	nModulo := _nModAnt
	cModulo := _cModAnt
EndIf

Return(_lRet)

/*
===============================================================================================================================
Programa--------: ITACTMIX
Autor-----------: Alexandre Villar
Data da Criacao-: 19/01/2015
Descrição-------: Rotina para efetuar acerto do MIX referente aos eventos de Débitos
Parametros------: _lOk - Variável de controle do processamento
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ITACTMIX(_oProces As Object,_lOk As Logical,_aParam As Array, _lSemNota As Logical)

Local _aArea		:= FWGetArea() As Array
Local _cAlias		:= GetNextAlias() As Character
Local _cNroTit		:= '' As Character
Local _cSeekZLF		:= '' As Character
Local _cSeekSE2		:= '' As Character
Local _cParAux		:= StrZero(1,TamSX3("E2_PARCELA")[1]) As Character//Parcela do titulo do evento
Local _nVlrEve		:= 0 As Numeric
Local _nRegZLF		:= 0 As Numeric

BeginSql Alias _cAlias
	SELECT ZLF.R_E_C_N_O_ REGZLF, ZL8.R_E_C_N_O_ REGZL8
	  FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
	 WHERE ZLF.ZLF_FILIAL = %xFilial:ZLF%
	   AND ZL8.ZL8_FILIAL = ZLF.ZLF_FILIAL
	   AND ZLF.ZLF_CODZLE = %exp:_cCodMix%
	   AND ZLF.ZLF_SETOR = %exp:_cCODZL2%
	   AND ZLF.ZLF_LINROT = %exp:_cCODZL3%
	   AND ZLF.ZLF_A2COD = %exp:_cCODSA2%
	   AND ZLF.ZLF_A2LOJA = %exp:_cLOJSA2%
	   AND ZLF.ZLF_EVENTO = ZL8.ZL8_COD
	   AND ZLF.ZLF_A2COD LIKE 'P%'
	   AND ZLF.ZLF_ORIGEM = 'M'
	   AND ZLF.ZLF_DEBCRE = 'D'
	   AND ZLF.ZLF_ACERTO NOT IN ('B', 'S')
	   AND ZLF.ZLF_TP_MIX = 'L'
	   AND ZL8.ZL8_PREFIX <> ' '
	   AND ZL8.D_E_L_E_T_ = ' '
	   AND ZLF.D_E_L_E_T_ = ' '
EndSql

While (_cAlias)->(!Eof()) .And. _lOk
	ZLF->(DBGoTo((_cAlias)->REGZLF))
	_nVlrEve := ZLF->ZLF_TOTAL
	
	If _nVlrEve > 0 .And. _lDefini
		ZL8->(DBGoTo((_cAlias)->REGZL8))
		
		_cNroTit := Right(_cCodMix , 3) + StrZero(Val(_cVersao) , 2) + Right(_cCODZL3 , 4)
		//====================================================================================================
		// Altera o registro na ZLF de Debito referente ao valor do evento lido.
		//====================================================================================================
		_cSeekSE2 := xFilial("SE2") + ZL8->ZL8_PREFIX + _cNroTit + _cParAux + "NDF" + _cCODSA2 + _cLOJSA2
		_cSeekZLF := ITGRVZLF(_oProces,ZL8->ZL8_COD,0,_cSeekSE2,.F./*_lGrvZLF*/,.T./*_lAltZLF*/,ZLF->ZLF_SEQ,_cCODZL3,_cCODZL2,_aParam,@_nRegZLF,/*_lImp*/,ZL8->ZL8_DEBCRE,@_lOk)

		//====================================================================================================
		// Inclui o titulo relacionado ao evento
		//====================================================================================================
        If _lOk
		    _lOk := ITINCSE2(_oProces, _nVlrEve , ZL8->ZL8_PREFIX , _cNroTit , _cParAux , "NDF" , _cSeekZLF , ZL8->ZL8_NATPRD,_lSemNota,_aParam[11])
        EndIf
		If _lOk
			If (_nSldPro - _nVlrEve) >= 0
				//====================================================================================================
				// Baixa o titulo incluido atraves do evento
				//====================================================================================================
				_lOk := ITBXASE2(_oProces,_nVlrEve,ZL8->ZL8_PREFIX,_cNroTit,_cParAux,"NDF",ZL8->ZL8_PREFIX,_cSeekZLF,.T./*_lVlPago*/,_nRegZLF,_aParam,_cMotBaixa,ZL8->ZL8_COD,_cCODSA2,_cLOJSA2)
				//====================================================================================================
				// Baixa no titulo de valor bruto do produtor o valor da baixa do evento.
				//====================================================================================================
				If _lOk
					_lOk := ITBXASE2(_oProces,_nVlrEve,_cPrefixo,_cNroNota,PadR(" ", TamSX3("E2_PARCELA")[1]), "NF ", "" ,/*_cSeekZLF*/,.F./*_lVlPago*/,0/*_nRegZLF*/,_aParam,_cMotBaixa,ZL8->ZL8_COD,_cCODSA2,_cLOJSA2)
				Else
					Exit
				EndIf
				//====================================================================================================
				// Incrementa a parcela para o proximo titulo de evento e abate o saldo do produtor.
				//====================================================================================================
				If _lOk
					_cParAux := Soma1(_cParAux)
					_nSldPro -= _nVlrEve
				Else
					Exit
				EndIf
			ElseIf _nSldPro > 0
				//====================================================================================================
				// Baixa o titulo incluido atraves do evento
				//====================================================================================================
				_lOk := ITBXASE2(_oProces,_nSldPro,ZL8->ZL8_PREFIX,_cNroTit,_cParAux,"NDF",ZL8->ZL8_PREFIX,_cSeekZLF,.T./*_lVlPago*/,_nRegZLF,_aParam,_cMotBaixa,ZL8->ZL8_COD,_cCODSA2,_cLOJSA2)
				If _lOk
					_lOk := ITALTZLF(_oProces,_nRegZLF,_nSldPro)
				Else
					Exit
				EndIf
				//====================================================================================================
				// Baixa no titulo de valor bruto do produtor o saldo do produtor
				//====================================================================================================
				If _lOk
					_lOk := ITBXASE2(_oProces,_nSldPro,_cPrefixo,_cNroNota,PadR(" ", TamSX3("E2_PARCELA")[1]),"NF ", "",/*_cSeekZLF*/,.F./*_lVlPago*/,0/*_nRegZLF*/,_aParam,_cMotBaixa,ZL8->ZL8_COD,_cCODSA2,_cLOJSA2)
				Else
					Exit
				EndIf
				
				//====================================================================================================
				// Grava o valor baixado na ZLF (baixa parcial)
				//====================================================================================================
				If _lOk
					_lOk := ITALTZLF(_oProces,_nRegZLF,_nSldPro)
					//====================================================================================================
					// Incrementa a parcela para o proximo titulo de evento e abate o saldo do produtor
					//====================================================================================================
					If _lOk
						_cParAux	:= Soma1(_cParAux)
						_nSldPro	-= _nSldPro
					Else
						Exit
					EndIf
				Else
					Exit
				EndIf
			EndIf
		Else
			Exit
		EndIf
	EndIf
	FWRestArea(_aArea)
	
	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa--------: ITBXASE2
Autor-----------: Alexandre Villar
Data da Criacao-: 19/01/2015
Descrição-------: Rotina para efetuar acerto do MIX referente aos eventos de Débitos
Parametros------: _nVlrBx    - Valor a ser baixado no titulo.
				  _cPrefixo  - Prefixo do titulo a ser baixado.
				  _cNroTit   - Numero do titulo a ser baixado.
				  _cParcela  - Parcela do titulo a ser baixado.
				  _cTipo     - Tipo do titulo a ser baixado.
				  _cConvPref - Prefixo dos titulos de convenio(Param. LT_CONVPRE)
				  _cSeek     - Chave de pesquisa para vincular a Baixa na ZLF.
				  _lVlPago   - Indica se deve gravar o campo ZLF_VLRPAG.
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ITBXASE2(_oProces As Object,_nVlrBx As Numeric,_cPrefix As Character,_cNroTit As Character,_cParcel As Character,;
						_cTipo As Character,_cConvPrf As Character,_cSeek As Character,_lVlPago As Logical,_nRegZLF As Numeric,;
						_aParam As Array,_cMotBx As Character,_cCodZL8 As Character,_cFornece As Character,_cLoja As Character)

Local _aTitulo		:= {} As Array
Local _nModAnt		:= nModulo As Numeric
Local _cModAnt		:= cModulo As Character
Local _cOrigem		:= '' As Character
Local _cUpdate		:= '' As Character
Local _lRet			:= .T. As Logical
Local _cMenAux		:= '' As Character
Local _cSequencia	:= Space(TamSX3("E5_SEQ")[1]) As Character
Local _cHist		:= "GLT"+ StrZero(Month(ZLE->ZLE_DTINI),2) +"/"+ StrZero(Year(ZLE->ZLE_DTINI),4) +'-'+ _cCodMix As Character
Private aBaixaSE5	:= {} As Array//Necessário para a função Sel080Baixa

DEFAULT _cConvPrf	:= ""
DEFAULT _cSeek		:= ""
DEFAULT _lVlPago	:= .F. //atualiza valor pago e incluia a sequencia de baixa no ZLF_L_SEEK
Default _nRegZLF	:= 0

//====================================================================================================
// Tratamento para liberar o titulo para baixa no Financeiro
//====================================================================================================
SE2->(DBSetOrder(1))
If SE2->(DBSeek(xFilial("SE2") + _cPrefix + _cNroTit + _cParcel + _cTipo + _cFornece + _cLoja))

	_cOrigem := SE2->E2_ORIGEM
	
	RecLock('SE2' , .F.)
		If Empty(SE2->E2_DATALIB)//Se nao foi liberado ainda
			SE2->E2_DATALIB := dDataBase
			SE2->E2_USUALIB := cUserName
			SE2->E2_STATLIB := "03"
		EndIf
		
		SE2->E2_L_MIX	:= _cCodMix
		If !Empty(_cSeek)
			SE2->E2_L_SEEK	:= _cSeek
		EndIf
	SE2->(MSUnLock())
Else
	_lRet := .F.
	_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Atualização do Título;Falha no Update do Título ['+ _cPrefix+_cNroTit+_cParcel+_cTipo+_cFornece+_cLoja +'/'+ _cSeek +']!'
	_oProces:SaveLog("Thread:"+_cThread+" MGLT00928 - " + _cMenAux)
	_oFile:Write(_cMenAux + ' - MGLT00928;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
EndIf

If _lRet
	//====================================================================================================
	// Monta array com os dados do título do Financeiro
	//====================================================================================================
	_aTitulo := {	{ "E2_PREFIXO"		, _cPrefix											, Nil },;
					{ "E2_NUM"			, _cNroTit											, Nil },;
					{ "E2_PARCELA"		, _cParcel											, Nil },;
					{ "E2_TIPO"			, _cTipo											, Nil },;
					{ "E2_FORNECE"		, _cFornece											, Nil },;
					{ "E2_LOJA"			, _cLoja	  										, Nil },;
					{ "AUTBANCO"		, ""												, Nil },;
					{ "AUTAGENCIA"		, ""												, Nil },;
					{ "AUTCONTA"		, ""												, Nil },;
					{ "AUTCHEQUE"		, ""												, Nil },;
					{ "AUTMOTBX"		, _cMotBx											, Nil },;
					{ "AUTDTBAIXA"		, dDataBase											, Nil },;
					{ "AUTDTCREDITO"	, dDataBase											, Nil },;
					{ "AUTBENEF"		, _cCODSA2 +" - "+ AllTrim(SA2->A2_NOME)			, Nil },;
					{ "AUTHIST"			, _cHist											, Nil },;
					{ "AUTVLRPG"		, _nVlrBx											, Nil } }
	
	//====================================================================================================
	// Altera o modulo para Financeiro, senao o SigaAuto nao executa
	//====================================================================================================
	nModulo := 6
	cModulo := "FIN"
	lMsErroAuto	:= .F.
	lMsHelpAuto	:= .T.	
	//====================================================================================================
	// SigaAuto de Baixa de Contas a Pagar
	//====================================================================================================
	MSExecAuto({|x,y| Fina080(x,y) } , _aTitulo , 3)
	
	//====================================================================================================
	// Restaura o modulo em uso e atualiza a tabela de movimentos (SE5)
	//====================================================================================================
	nModulo := _nModAnt
	cModulo := _cModAnt
	
	//====================================================================================================
	// Verifica se houve erro no SigaAuto e mostra o erro.
	//====================================================================================================
	If lMsErroAuto
		_lRet := .F.
		_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Baixa de Títulos;Falha no ExecAuto ['+ xFilial("SE2")+_cPrefix+_cNroTit+_cParcel+_cTipo+_cFornece+_cLoja +'/'+ cValToChar(_nVlrBx) +']!'
		_oProces:SaveLog("Thread:"+_cThread+" MGLT00929 - " + _cMenAux)
		_oFile:Write(_cMenAux + ' - MGLT00929;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
	Else
		If _lRet
			//====================================================================================================
			// Se o titulo originou de um Convenio então seta como fechado
			//====================================================================================================
			If Upper(AllTrim(_cOrigem)) == "AGLT010"
			
				_cUpdate := " UPDATE "+ RetSqlName('ZLL') +" ZLL SET ZLL.ZLL_STATUS = 'P' "
				_cUpdate += " WHERE  "+ RetSqlCond('ZLL')
				_cUpdate += " AND ZLL.ZLL_COD    = '"+ SubStr(_cNroTit , 1 , 6) +"' "
				_cUpdate += " AND ZLL.ZLL_SEQ    = '"+ SubStr(_cNroTit , 7 , 3) +"' "
				_cUpdate += " AND ZLL.ZLL_RETIRO = '"+ _cFornece +"' "
				_cUpdate += " AND ZLL.ZLL_RETILJ = '"+ _cLoja +"' "
				
				_lRet := !(TCSqlExec(_cUpdate) < 0)
				If !_lRet
					_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Atualização do Convênio;Não encontrou o registro do Convênio ['+xFilial('ZLL')+'/'+SubStr(_cNroTit,1,6)+'/'+SubStr(_cNroTit,7,3)+'/'+_cFornece+'/'+_cLoja+']!'
					_oProces:SaveLog("Thread:"+_cThread+" MGLT00930 - " + _cMenAux)
					_oFile:Write(_cMenAux + ' - MGLT00930;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
				EndIf
			EndIf
		Else
			_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Atualização de Movimentos;Falha na atualização do (SE5): ['+ xFilial("SE2")+_cPrefix+_cNroTit+_cParcel+_cTipo+_cFornece+_cLoja +']!'
			_oProces:SaveLog("Thread:"+_cThread+" MGLT00931 - " + _cMenAux)
			_oFile:Write(_cMenAux + ' - MGLT00931;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
		EndIf

		//====================================================================================================
		// Se _lVlPago = .T. deve atualizar o campo ZLF_VLRPG. Este campo existe para diferenciar o valor 
		// original do evento em relacao ao valor que foi pago nesse evento. Isso ocorre em baixas parciais.
		// As baixas parciais existem qdo o produtor nao possui credito suficiente.
		//====================================================================================================
		If _lVlPago
			If _nRegZLF == ZLF->(RECNO()) //A ZLF já deveria estar posicionada, logo, apenas confiro. Não realizar nenhum Seek ou DBGoTo para não forçar um flush dos dados pois o recno irá se alterar
				//Preciso identificar a sequencia de baixa para que no cancelamento eu possa localizar a baixa correta a ser estornada, uma vez que agora eu posso compensar títulos de lojas diferentes.
				Sel080Baixa("VL /BA /CP /",SubStr(ZLF->ZLF_L_SEEK,3,3),SubStr(ZLF->ZLF_L_SEEK,6,9),SubStr(ZLF->ZLF_L_SEEK,15,2),SubStr(ZLF->ZLF_L_SEEK,17,3),0,0,SubStr(ZLF->ZLF_L_SEEK,20,6),SubStr(ZLF->ZLF_L_SEEK,26,4),.F.,.F.,.F.,0,.F.,.T.)
				aSort(aBaixaSE5,,, {|x,y| x[9] < y[9] }) //Ordena por sequencia
				_cSequencia := aBaixaSE5[Len(aBaixaSE5),09]

				RecLock("ZLF" , .F.)
				ZLF->ZLF_VLRPAG := _nVlrBx
				ZLF->ZLF_SEQBX := _cSequencia
				ZLF->(MSUnLock())
			Else
				_lRet := .F.
				_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Atualização do Item do MIX (ZLF_VLRPAG);Não encontrou o ítem do MIX ['+xFilial("SE2")+_cPrefix+_cNroTit+_cParcel+_cTipo+_cFornece+_cLoja+_cCodZL8+']!'
				_oProces:SaveLog("Thread:"+_cThread+" MGLT00932 - " + _cMenAux)
				_oFile:Write(_cMenAux + ' - MGLT00932;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
			EndIf
		EndIf
	EndIf
EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: ITALTZLF
Autor-----------: Alexandre Villar
Data da Criacao-: 19/01/2015
Descrição-------: Rotina para efetuar acerto do MIX referente aos eventos de Débitos
Parametros------: _cSeek  - Chave de pesquisa da ZLF
				  _nValor - Valor a ser atualizado
Retorno---------: _lRet   - Retorna se o conteúdo foi atualizado corretamente
===============================================================================================================================
*/
Static Function ITALTZLF(_oProces As Object,_nRegZLF As Numeric,_nValor As Numeric)

Local _lRet		:= .T. As Logical
Local _cMenAux	:= "" As Character

Default _nRegZLF	:= 0

If _nRegZLF == 0
	_lRet := .F.
	_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Não posicionou na ZLF para atualizar o valor do evento para o caso de saldo insuficiente.'
	_oProces:SaveLog("Thread:"+_cThread+" MGLT00941 - " + _cMenAux)
	_oFile:Write(_cMenAux + ' - MGLT00941;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
Else
	ZLF->(DBGoTo(_nRegZLF))
	RecLock("ZLF" , .F.)
		ZLF->ZLF_TOTAL	:= _nValor
		ZLF->ZLF_VLRLTR	:= _nValor / ZLF->ZLF_QTDBOM
	ZLF->(MSUnLock())
EndIf

Return _lRet

/*
===============================================================================================================================
Programa--------: ITACTEVE
Autor-----------: Alexandre Villar
Data da Criacao-: 19/01/2015
Descrição-------: Rotina para efetuar acerto de Eventos referentes ao MIX
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ITACTEVE(_oProces As Object,_lOk As Logical,_aParam As Array,_lSemNota As Logical)

Local _aArea	:= FWGetArea() As Character
Local _cAlias	:= GetNextAlias() As Character
Local _cNroTit	:= StrZero(Day(dDataBase) , 2) + StrZero(Month(dDataBase) , 2) + SubStr(DToS(dDataBase) , 3 , 2) + SubStr(_cCodMix , 4 , 3) As Character
Local _cSeekZLF	:= "" As Character
Local _cParAux	:= StrZero(1 , TamSX3("E2_PARCELA")[1]) As Character//Parcela do titulo do evento
Local _nCont    := 0 As Numeric
Local _nVlrEve	:= 0 As Numeric
Local _nRegZLF	:= 0 As Numeric

BeginSql Alias _cAlias
	SELECT ZL8_CONDIC CONDIC, R_E_C_N_O_ REGZL8
	  FROM %Table:ZL8%
	 WHERE ZL8_FILIAL = %xFilial:ZL8%
	   AND ZL8_TPEVEN = 'A'
	   AND ZL8_PERTEN IN ('P', 'T')
	   AND ZL8_MSBLQL <> '1'
	   AND D_E_L_E_T_ = ' '
	 ORDER BY ZL8_PRIORI
EndSql

While (_cAlias)->(!Eof())
	_nCont ++
	//====================================================================================================
	// Verifica se a condicao do Evento eh satisfatoria.
	//====================================================================================================
	If &(AllTrim((_cAlias)->CONDIC))
		ZL8->(DBGoTo((_cAlias)->REGZL8))
		//====================================================================================================
		// Busca o valor a ser gravado no Evento e no titulo.
		//====================================================================================================
		_nVlrEve := &(ZL8->ZL8_FORMUL)
		_nVlrEve := Round(_nVlrEve , 2) //Arredonda pra nao dar erro na baixa do SE2
		
		If _nVlrEve > 0
			If _lDefini
				If Empty(ZL8-> ZL8_NATPRD)// Uso esse campo para identificar os impostos já gerados pelo documento de entrada
					_cSeekSE2 := SF1->(F1_FILIAL+F1_PREFIXO+F1_DUPL)+ _cParAux + ZL8->ZL8_PREFIX + SF1->(F1_FORNECE+F1_LOJA)
					_cSeekZLF := ITGRVZLF(_oProces,ZL8->ZL8_COD,_nVlrEve,_cSeekSE2,.T./*_lGrvZLF*/,/*_lAltZLF*/,/*_cSeq*/,_cCODZL3,_cCODZL2,_aParam,@_nRegZLF,.T./*_lImp*/,ZL8->ZL8_DEBCRE,@_lOk)
					
                    If _lOk
					    _nSldPro -= IIf(ZL8->ZL8_DEBCRE=="D",_nVlrEve,_nVlrEve*-1)//Inverto o sinal para que eventos de crédito com o incentivo à produção seja somado
                    Else
                        Exit
                    EndIf
				Else
					_cNroTit := Right(_cCodMix , 3) + StrZero(Val(_cVersao) , 2) + Right(_cCODZL3 , 4)
					//====================================================================================================
					// Inclui um registro na ZLF de Debito referente ao valor do evento lido.
					//====================================================================================================
					_cSeekSE2 := xFilial("SE2")+ZL8->ZL8_PREFIX+_cNroTit+_cParAux+"NDF"+_cCODSA2+_cLOJSA2
					_cSeekZLF := ITGRVZLF(_oProces,ZL8->ZL8_COD,_nVlrEve,_cSeekSE2,.T./*_lGrvZLF*/,/*_lAltZLF*/,/*_cSeq*/,_cCODZL3,_cCODZL2,_aParam,@_nRegZLF,/*_lImp*/,ZL8->ZL8_DEBCRE,@_lOk)

                    //====================================================================================================
					// Inclui o titulo relacionado ao evento lido.
					//====================================================================================================
					If _lOk .And. ITINCSE2(_oProces, _nVlrEve , ZL8->ZL8_PREFIX , _cNroTit , _cParAux , "NDF" , _cSeekZLF ,ZL8->ZL8_NATPRD,_lSemNota,_aParam[11])
						If (_nSldPro - _nVlrEve) >= 0
							//====================================================================================================
							// Baixa o titulo incluido atraves do evento
							//====================================================================================================
							_lOk := ITBXASE2(_oProces,_nVlrEve,ZL8->ZL8_PREFIX,_cNroTit,_cParAux,"NDF",ZL8->ZL8_PREFIX,_cSeekZLF,.T./*_lVlPago*/,_nRegZLF,_aParam,_cMotBaixa,ZL8->ZL8_COD,_cCODSA2,_cLOJSA2)
							//====================================================================================================
							// Baixa no titulo de valor bruto do produtor o valor da baixa do evento.
							//====================================================================================================
							If _lOk
								_lOk := ITBXASE2(_oProces,_nVlrEve,_cPrefixo,_cNroNota,PadR(" ", TamSX3("E2_PARCELA")[1]),"NF ","",/*_cSeekZLF*/,.F./*_lVlPago*/,0/*_nRegZLF*/,_aParam,_cMotBaixa,ZL8->ZL8_COD,_cCODSA2,_cLOJSA2)
							Else
								Exit
							EndIf
							//====================================================================================================
							// Abate o saldo do produtor
							//====================================================================================================
							If _lOk
								_nSldPro -= _nVlrEve
							Else
								Exit
							EndIf
							
						ElseIf _nSldPro > 0
							//====================================================================================================
							// Baixa o titulo incluido atraves do evento
							//====================================================================================================
							_lOk := ITBXASE2(_oProces,_nSldPro,ZL8->ZL8_PREFIX,_cNroTit,_cParAux,"NDF",ZL8->ZL8_PREFIX,_cSeekZLF, .T./*_lVlPago*/,_nRegZLF,_aParam,_cMotBaixa,ZL8->ZL8_COD,_cCODSA2,_cLOJSA2)
							//====================================================================================================
							// Baixa no titulo de valor bruto do produtor o valor da baixa do evento.
							//====================================================================================================
							If _lOk
								_lOk := ITBXASE2(_oProces,_nSldPro,_cPrefixo,_cNroNota,PadR(" ", TamSX3("E2_PARCELA")[1]),"NF ","",/*_cSeekZLF*/,.F./*_lVlPago*/,0/*_nRegZLF*/,_aParam,_cMotBaixa,ZL8->ZL8_COD,_cCODSA2,_cLOJSA2)
							Else
								Exit
							EndIf

						    If _lOk
						    	//====================================================================================================
						    	// Grava o valor baixado na ZLF (baixa parcial)
						    	//====================================================================================================
		    					ITALTZLF(_oProces,_nRegZLF,_nSldPro)
								//====================================================================================================
								// Abate o saldo do produtor
								//====================================================================================================
								If _lOk
									_nSldPro -= _nSldPro
								Else
									Exit
								EndIf
							Else
								Exit
							EndIf
						EndIf
					Else
						_lOk := .F.
						Exit
					EndIf
				EndIf				
			Else
				//====================================================================================================
				// Grava um registro na ZLF de Debito referente ao valor do evento lido.
				//====================================================================================================
				ITGRVZLF(_oProces,ZL8->ZL8_COD,_nVlrEve,"PREVISAO",.T./*_lGrvZLF*/,/*_lAltZLF*/,/*_cSeq*/,_cCODZL3,_cCODZL2,_aParam,@_nRegZLF,/*_lImp*/,ZL8->ZL8_DEBCRE,@_lOk)
				
                If !_lOk
                    Exit
                EndIf
			EndIf
		EndIf
	EndIf
	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa--------: ITACTFIN
Autor-----------: Alexandre Villar
Data da Criacao-: 19/01/2015
Descrição-------: Rotina para efetuar acerto de Eventos referentes ao MIX
				  Não é possível filtrar a linha nesse trecho, uma vez que todas as rotinas que geram as informações na SE2, 
				  não informam a linha, consequentemente não é possível filtrar isso. Logo, todas as débitos serão retornados e
				  descontados na primeira linha que For fechada. As linhas podem ser alteradas e ser informado um setor dife-
				  rente do original, logo, não é possível vincular com a ZL3.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ITACTFIN(_oProces As Object,_lOk As Logical,_aParam As Array,_lDefini As Logical)

Local _aArea	:= FWGetArea() As Character
Local _cAlias	:= GetNextAlias() As Character
Local _nSldTit	:= 0 As Numeric
Local _nJurTit	:= 0 As Numeric
Local _nVlrBx	:= 0 As Numeric
Local _cSeekSE2	:= "" As Character
Local _cSeekZLF	:= "" As Character
Local _nRegZLF	:= 0 As Numeric
Local _cMenAux	:= "" As Character
Local _cFiltro	:= "%%" As Character
Local _cFilStat	:= "% " As Character

//===================================================================================================================================
//Diferente das antecipações, os convênios precisam ser descontados em sua totalidade. Na hierarquia do que deve ser descontado 
//primeiro, eles vem em último lugar e não podem ser compensados parcialmente (ZL8_SITUAC = 'D'). Dessa forma, preciso verificar 
//se à princípio eu tenho saldo para fazer todos os descontos (convênios e antecipações). Caso não tenha, devo priorizar as antecipações,
//dessa forma, baixo o que der delas e na última loja do produtor, o fechamento não será realizado ficando o convênio pendente.
//Caso tenha saldo para todos os descontos, preciso tratar de uma forma que eu isole a loja que tem saldo para o convênio para que ele
//seja compensado nela, visto que não pode ter baixas parciais. Se uma loja tem saldo para o convênio, começo por ele. Ex. O produtor
//tem 5 lojas e a primeira loja que tem saldo para compensar o convênio, é a 0002. Quando rodar o fechamento da 0001 vou ignorar esse 
//título e pega-lo apenas na 0002. Caso nenhuma loja tenha saldo, ele será retornado em todas, dessa forma, o usuário terá que ajustar.
//Como ele será pego por último nesse cenário de saldo total insuficiente, os empréstimos serão compensados nas primeiras lojas.
//Montei um extrato em uma coluna, onde, após ordenar todos os títulos na ordem que deveriam ser baixados, vou verificando o saldo
//restante e quando encontro um tipo 'D' e o saldo de todas as lojas é suficiente para baixar tudo, ignoro ele para ele ser pego
//na próxima loja
//====================================================================================================================================
If !_lDefini
	_cFiltro := "% AND SE2.E2_LOJA = '"+_cLOJSA2+"' %"
	_cFilStat += "IN ('E','A', 'P') %"
Else
	_cFilStat += "= 'E' %"
EndIf

BeginSql Alias _cAlias
	SELECT Case 
      WHEN ZL8_SITUAC = 'B' THEN 'Processa'
      WHEN ZL8_SITUAC = 'D' AND SALDO_ZLF > SALDO_SE2 AND SALDO_LOJA - SUM(SALDO) OVER (ORDER BY ORDEM, E2_VENCTO ROWS UNBOUNDED PRECEDING) < 0 THEN 'IGNORA'
      Else 'Processa'
      END Processa,
    SALDO_LOJA - SUM(SALDO) OVER (ORDER BY ORDEM, E2_VENCTO ROWS UNBOUNDED PRECEDING) PARCIAL,
    BASE.*
	FROM (SELECT E2_VENCTO, ZL8_SITUAC, CONDIC, SALDO, E2_LOJA, REGSE2, REGZL8, SALDO_ZLF, SALDO_LOJA, SALDO_SE2,
		Case WHEN SALDO_ZLF > SALDO_SE2 AND ZL8_SITUAC = 'D' THEN 1
		WHEN SALDO_ZLF > SALDO_SE2 AND ZL8_SITUAC <> 'D' THEN 2
		WHEN SALDO_ZLF < SALDO_SE2 AND ZL8_SITUAC = 'D' THEN 2 
		Else 1 END ORDEM
	FROM (SELECT ZL8.ZL8_SITUAC, ZL8.ZL8_CONDIC CONDIC, SE2.E2_SALDO + SE2.E2_SDACRES - SE2.E2_SDDECRE SALDO,
					SE2.E2_LOJA, SE2.E2_VENCTO, SE2.R_E_C_N_O_ REGSE2, ZL8.R_E_C_N_O_ REGZL8,
					(SELECT NVL(SUM(Case WHEN ZLF.ZLF_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END),0)
					FROM %Table:ZLF% ZLF
					WHERE ZLF.D_E_L_E_T_ = ' '
						AND ZLF_FILIAL = ZL8_FILIAL
						AND ZLF_CODZLE = %exp:_cCodMix%
						AND ZLF_A2COD = E2_FORNECE
						AND ZLF_SETOR = E2_L_SETOR
						AND ZLF_STATUS %exp:_cFilStat%) SALDO_ZLF,
					(SELECT NVL(SUM(Case WHEN ZLF.ZLF_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END), 0)
					FROM %Table:ZLF% ZLF
					WHERE ZLF.D_E_L_E_T_ = ' '
						AND ZLF_FILIAL = ZL8_FILIAL
						AND ZLF_CODZLE = %exp:_cCodMix%
						AND ZLF_A2COD = E2_FORNECE
						AND ZLF_A2LOJA = %exp:_cLOJSA2%
						AND ZLF_SETOR = E2_L_SETOR
						AND ZLF_STATUS %exp:_cFilStat%) SALDO_LOJA,
					(SELECT SUM(E2_SALDO + E2_SDACRES - E2_SDDECRE)
					FROM %Table:SE2% SE22, %Table:ZL8% ZL88
						WHERE SE22.E2_FILIAL = %xFilial:SE2%
						AND ZL88.ZL8_FILIAL = SE22.E2_FILIAL
						AND ZL88.ZL8_PREFIX = SE22.E2_PREFIXO
						AND SE22.E2_VENCTO <= %exp:_aParam[12]%
						AND SE22.E2_FORNECE = %exp:_cCODSA2%
						AND SE22.E2_L_SETOR = %exp:_cCODZL2%
						AND SE22.E2_TIPO = 'NDF'
						%exp:_cFiltro%
						AND SE22.E2_SALDO > 0
						AND ZL88.ZL8_TPEVEN = 'F'
						AND ZL88.ZL8_DEBCRE = 'D'
						AND ZL88.ZL8_PREFIX <> ' '
						AND ZL88.ZL8_SITUAC <> ' '
						AND ZL88.ZL8_MSBLQL <> '1'
						AND SE22.D_E_L_E_T_ = ' '
						AND ZL88.D_E_L_E_T_ = ' ') SALDO_SE2
			FROM %Table:SE2% SE2, %Table:ZL8% ZL8
			WHERE SE2.E2_FILIAL = %xFilial:SE2%
				AND ZL8_FILIAL = E2_FILIAL
				AND ZL8.ZL8_PREFIX = SE2.E2_PREFIXO
				AND SE2.E2_VENCTO <= %exp:_aParam[12]%
				AND SE2.E2_FORNECE = %exp:_cCODSA2%
				AND SE2.E2_L_SETOR = %exp:_cCODZL2%
				AND SE2.E2_TIPO = 'NDF'
				%exp:_cFiltro%
				AND SE2.E2_SALDO > 0
				AND ZL8.ZL8_TPEVEN = 'F'
				AND ZL8.ZL8_DEBCRE = 'D'
				AND ZL8.ZL8_PREFIX <> ' '
				AND ZL8.ZL8_SITUAC <> ' '
				AND ZL8.ZL8_MSBLQL <> '1'
				AND SE2.D_E_L_E_T_ = ' '
				AND ZL8.D_E_L_E_T_ = ' ')
	ORDER BY ORDEM, E2_VENCTO) BASE
		ORDER BY ORDEM, E2_VENCTO
EndSql

While (_cAlias)->(!Eof()) 
	If &(AllTrim((_cAlias)->CONDIC)) .And. (_cAlias)->Processa == 'Processa'
		ZL8->(DBGoTo((_cAlias)->REGZL8))
		SE2->(DBGoTo((_cAlias)->REGSE2))
		
		_nSldTit := SE2->(E2_SALDO + E2_SDACRES - E2_SDDECRE)
		_nJurTit := FaJuros(SE2->E2_VALOR,SE2->E2_SALDO,SE2->E2_VENCTO,SE2->E2_VALJUR,SE2->E2_PORCJUR,SE2->E2_MOEDA,SE2->E2_EMISSAO,dDataBase,SE2->E2_TXMOEDA,SE2->E2_BAIXA)
		//====================================================================================================
		// Valor atualizado a ser baixado no titulo.
		//====================================================================================================
		_nVlrBx := _nSldTit + _nJurTit
		//====================================================================================================
		// Se o saldo do produtor For maior que zero, baixa os titulos no SE2.
		//====================================================================================================
		If _nSldPro > 0
			//====================================================================================================
			// Se o saldo do produtor menos o saldo do titulo For maior ou igual a zero, baixa o SE2.
			//====================================================================================================
			If (_nSldPro - _nVlrBx) >= 0
				//====================================================================================================
				// Verifica se grava registro na ZLF, com o valor do saldo do titulo.
				//====================================================================================================
				If _lDefini
					_cSeekSE2 := SE2->(E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA)
					_cSeekZLF := ITGRVZLF(_oProces,ZL8->ZL8_COD,_nSldTit,_cSeekSE2,.T./*_lGrvZLF*/,/*_lAltZLF*/,/*_cSeq*/,_cCODZL3,_cCODZL2,_aParam,@_nRegZLF,/*_lImp*/,ZL8->ZL8_DEBCRE,@_lOk)
					
					//================================================================================================================================================
					// Baixa o titulo incluido atraves do evento. Baixa da NDF. Alterado para que os debitos posssam ser compensados com a primeira loja a ser fechada,
					// logo, a NDF pode não ser da mesma loja que o produtor que está sendo fechado. Por isso passo o código e loja de quem posicionei na SE2
					//==================================================================================================================================================
					If _lOk
                        _lOk := ITBXASE2(_oProces,_nVlrBx,SE2->E2_PREFIXO,SE2->E2_NUM,SE2->E2_PARCELA,SE2->E2_TIPO,ZL8->ZL8_PREFIX,_cSeekZLF,.T./*_lVlPago*/,_nRegZLF,_aParam,_cMotBaixa,ZL8->ZL8_COD,SE2->E2_FORNECE,SE2->E2_LOJA)
                    EndIf
					//====================================================================================================
					// Baixa no titulo de valor bruto do produtor o valor da baixa do evento. Baixa da NF. Já na NF a loja precisa ser a do produtor que estou fechando, 
					// diferente da NDF que pode ser de uma loja diferente.
					//====================================================================================================
					If _lOk
						_lOk := ITBXASE2(_oProces,_nVlrBx,_cPrefixo,_cNroNota,PadR(" ", TamSX3("E2_PARCELA")[1]),"NF ","",/*_cSeekZLF*/,.F./*_lVlPago*/,0/*_nRegZLF*/,_aParam,_cMotBaixa,ZL8->ZL8_COD,_cCODSA2,_cLOJSA2)
					Else
						Exit
					EndIf
				Else
					//====================================================================================================
					// Validacao do evento de previsao caso o produtor tenha mudado de linha no mesmo MIX
					//====================================================================================================
					If ITVLDEVE(_cCodMix,_cCODZL2,SE2->E2_FORNECE,SE2->E2_LOJA,ZL8->ZL8_COD,_nSldTit,_cCODZL3)
						_cSeekZLF := ITGRVZLF(_oProces,ZL8->ZL8_COD,_nSldTit,"PREVISAO",.T./*_lGrvZLF*/,/*_lAltZLF*/,/*_cSeq*/,_cCODZL3,_cCODZL2,_aParam,@_nRegZLF,/*_lImp*/,ZL8->ZL8_DEBCRE,@_lOk)
					EndIf
				EndIf
				//====================================================================================================
				// Abate do saldo do produtor.
				//====================================================================================================
				If _lOk
					_nSldPro -= _nVlrBx
				Else
					Exit
				EndIf
			//====================================================================================================
			// Se o saldo do produtor menos o saldo do titulo eh menor que zero, faz baixa parcial.
			//====================================================================================================
			Else
				//====================================================================================================
				// Grava registro na ZLF, com o valor do saldo do titulo mesmo fazendo baixa parcial.
				//====================================================================================================
				If _lDefini
					_cSeekSE2 := SE2->(E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA)
					_cSeekZLF := ITGRVZLF(_oProces,ZL8->ZL8_COD,_nSldTit,_cSeekSE2,.T./*_lGrvZLF*/,/*_lAltZLF*/,/*_cSeq*/,_cCODZL3,_cCODZL2,_aParam,@_nRegZLF,/*_lImp*/,ZL8->ZL8_DEBCRE,@_lOk)

					If !_lOk
						Exit
					//====================================================================================================
					// Se o acerto é definitivo e a situacao do evento eh de baixa parcial quando não há saldo suficiente
					//====================================================================================================
					ElseIf ZL8->ZL8_SITUAC == 'B'
						//====================================================================================================
						// Baixa o titulo incluido atraves do evento. Baixa da NDF. Alterado para que os debitos posssam ser compensados com a primeira loja a ser fechada,
						// logo, a NDF pode não ser da mesma loja que o produtor que está sendo fechado. Por isso passo o código e loja de quem posicionei na SE2
						//====================================================================================================
						_lOk := ITBXASE2(_oProces,_nSldPro,SE2->E2_PREFIXO,SE2->E2_NUM,SE2->E2_PARCELA,SE2->E2_TIPO,ZL8->ZL8_PREFIX,_cSeekZLF,.T./*_lVlPago*/,_nRegZLF,_aParam,_cMotBaixa,ZL8->ZL8_COD,SE2->E2_FORNECE,SE2->E2_LOJA)
						//====================================================================================================
						// Baixa no titulo de valor bruto do produtor o valor da baixa do evento. Baixa da NF. Já na NF a loja precisa ser a do produtor que estou fechando, 
						// diferente da NDF que pode ser de uma loja diferente.
						//====================================================================================================
						If _lOk
							_lOk := ITBXASE2(_oProces,_nSldPro,_cPrefixo,_cNroNota,PadR(" ", TamSX3("E2_PARCELA")[1]),"NF ","",/*_cSeekZLF*/,.F./*_lVlPago*/,0/*_nRegZLF*/,_aParam,_cMotBaixa,ZL8->ZL8_COD,_cCODSA2,_cLOJSA2)
						Else
							Exit
						EndIf
						//====================================================================================================
						// Grava o valor baixado na ZLF (baixa parcial)
						//====================================================================================================
						If _lOk
							_lOk := ITALTZLF(_oProces,_nRegZLF,_nSldPro)
							//====================================================================================================
							// Abate do saldo do produtor
							//====================================================================================================
							If _lOk
								_nSldPro -= _nSldPro
							Else
								Exit
							EndIf
						Else
							Exit
						EndIf
					//====================================================================================================
					// Se o acerto é definitivo, o evento é de Deleção do Titulo e não há saldo suficiente para baixar
					//====================================================================================================
					ElseIf ZL8->ZL8_SITUAC == 'D'
						//====================================================================================================
						// Não Processa o fechamento de produtores com convênio se não existir saldo a baixar
						//====================================================================================================
						_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Atualização de Convênio;O Produtor não tem saldo para baixar o convênio! O Fornecedor não terá o Fechamento realizado até que o convênio seja regularizado.'
						_oProces:SaveLog("Thread:"+_cThread+" MGLT00933 - " + _cMenAux)
						_oFile:Write(_cMenAux + ' - MGLT00933;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
						_lOk := .F.
						Exit
					EndIf
				Else
					//====================================================================================================
					// Validacao do evento de previsao caso o produtor tenha mudado de linha no mesmo MIX
					//====================================================================================================
					If ITVLDEVE(_cCodMix,_cCODZL2,SE2->E2_FORNECE,SE2->E2_LOJA,ZL8->ZL8_COD,_nSldTit,_cCODZL3)
						_cSeekZLF := ITGRVZLF(_oProces,ZL8->ZL8_COD,_nSldTit,"PREVISAO",.T./*_lGrvZLF*/,/*_lAltZLF*/,/*_cSeq*/,_cCODZL3,_cCODZL2,_aParam,@_nRegZLF,/*_lImp*/,ZL8->ZL8_DEBCRE,@_lOk)
						
						If !_lOk
							Exit
						EndIf
					EndIf
				EndIf
				//====================================================================================================
				// Valor a ser baixado parcialmente no titulo.
				//====================================================================================================
				_nVlrBx := _nSldPro
			EndIf
		//====================================================================================================
		// Se o saldo do produtor esta zerado, NÃO baixa os titulos no SE2.
		//====================================================================================================
		Else
			//====================================================================================================
			// Mesmo nao baixando o SE2 grava na ZLF o debito que o produtor possui.
			//====================================================================================================
			If _lDefini
				_cSeekSE2 := SE2->(E2_FILIAL + E2_PREFIXO + E2_NUM + E2_PARCELA + E2_TIPO + E2_FORNECE + E2_LOJA)
				_cSeekZLF := ITGRVZLF(_oProces,ZL8->ZL8_COD,0,_cSeekSE2,.T./*_lGrvZLF*/,/*_lAltZLF*/,/*_cSeq*/,_cCODZL3,_cCODZL2,_aParam,@_nRegZLF,/*_lImp*/,ZL8->ZL8_DEBCRE,@_lOk)
			Else
				//====================================================================================================
				// Validacao do evento de previsao caso o produtor tenha mudado de linha no mesmo MIX
				//====================================================================================================
				If ITVLDEVE(_cCodMix , _cCODZL2 , SE2->E2_FORNECE , SE2->E2_LOJA , ZL8->ZL8_COD , _nSldTit , _cCODZL3)
					_cSeekZLF := ITGRVZLF(_oProces,ZL8->ZL8_COD,_nSldTit,"PREVISAO",.T./*_lGrvZLF*/,/*_lAltZLF*/,/*_cSeq*/,_cCODZL3,_cCODZL2,_aParam,@_nRegZLF,/*_lImp*/,ZL8->ZL8_DEBCRE,@_lOk)
				EndIf
			EndIf
			If !_lOK
				Exit
			EndIf
			//====================================================================================================
			// Se o acerto eh definitivo, a situacao do evento é exclusão do titulo e não há saldo para baixar
			//====================================================================================================
			If _lDefini .And. ZL8->ZL8_SITUAC == 'D'
				_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Atualização de Convênio;O Produtor não tem saldo para baixar o convênio! O Título será excluído e o convênio suspenso!'
			 	_oProces:SaveLog("Thread:"+_cThread+" MGLT00934 - " + _cMenAux)
				_oFile:Write(_cMenAux + ' - MGLT00934;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
				_lOk := .F.
				Exit
			EndIf
		EndIf
	EndIf
	(_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa--------: ITVLDEVE
Autor-----------: Alexandre Villar
Data da Criacao-: 19/01/2015
Descrição-------: Rotina para efetuar acerto de Eventos referentes ao MIX
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ITVLDEVE(_cCodMix As Character,_cCodSetor As Character,_cCodProd As Character,_cCodLoja As Character,_cCodEvent As Character,_nValor As Numeric,_clinRot As Character)
                         
Local _cAlias	:= GetNextAlias() As Character
Local _lRet		:= .T.

BeginSql Alias _cAlias
	SELECT COUNT(1) NUMREG
	  FROM %Table:ZLF%
	 WHERE ZLF_FILIAL = %xFilial:ZLF%
	   AND ZLF_A2COD = %exp:_cCodProd%
	   AND ZLF_A2LOJA = %exp:_cCodLoja%
	   AND ZLF_CODZLE = %exp:_cCodMix%
	   AND ZLF_SETOR = %exp:_cCodSetor%
	   AND ZLF_EVENTO = %exp:_cCodEvent%
	   AND ZLF_LINROT <> %exp:_clinRot%
	   AND ZLF_TOTAL = %exp:_nValor%
	   AND D_E_L_E_T_ = ' '
EndSql

If (_cAlias)->NUMREG > 0
	_lRet := .F.
EndIf

(_cAlias)->(DBCloseArea())

Return(_lRet)

/*
===============================================================================================================================
Programa--------: ITGETDES
Autor-----------: Alexandre Villar
Data da Criacao-: 19/01/2015
Descrição-------: Rotina que retorna a descrição dos valores referentes aos itens do MIX
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ITGETDES(_cMix As Character,_cCodProd As Character,_cLoja As Character,_nVlrNF As Numeric,_cLinha As Character,_cSetor As Character)

Local _cAlias	:= GetNextAlias() As Character
Local _cRet		:= "Produtor: "+_cCodProd+"-"+_cLoja+"; Relacao de Descontos:; " As Character
Local _nTotDesc	:= 0 As Numeric

//====================================================================================================
// Obtendo Eventos de Desconto
//====================================================================================================
BeginSql Alias _cAlias
	SELECT ZLF_TOTAL,
		Case WHEN ZL8_PREFIX = 'GLE' THEN  ZLF_EVENTO || '-' || RTRIM(ZL8_DESCRI) || ' PARC. ' ||
			(SELECT SubStr(E2_HIST, 24, 5)
				FROM %Table:SE2% SE2
				WHERE E2_FILIAL = ZLF_FILIAL
				AND E2_PREFIXO = SubStr(ZLF_L_SEEK, 3, 3)
				AND E2_NUM = SubStr(ZLF_L_SEEK, 6, 9)
				AND E2_PARCELA = SubStr(ZLF_L_SEEK, 15, 2)
				AND E2_TIPO = SubStr(ZLF_L_SEEK, 17, 3)
				AND E2_FORNECE = SubStr(ZLF_L_SEEK, 20, 6)
				AND E2_LOJA = SubStr(ZLF_L_SEEK, 26, 4)
				AND SE2.D_E_L_E_T_ = ' ')
			Else ZLF_EVENTO || '-' || ZL8_DESCRI END DESCRI
	FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
	WHERE ZLF_FILIAL = ZL8_FILIAL
	AND ZLF_EVENTO = ZL8_COD
	AND ZLF_FILIAL = %xFilial:ZLF%
	AND ZLF_CODZLE = %exp:_cMix%
	AND ZLF_LINROT = %exp:_cLinha%
	AND ZLF_SETOR = %exp:_cSetor%
	AND ZLF_A2COD = %exp:_cCodProd%
	AND ZLF_A2LOJA = %exp:_cLoja%
	AND ZLF_DEBCRE = 'D'
	AND ZLF.D_E_L_E_T_ = ' '
	AND ZL8.D_E_L_E_T_ = ' '
EndSql

While (_cAlias)->(!Eof())
	_cRet		+= PadR(Left((_cAlias)->DESCRI,40),39) +":"+ Transform((_cAlias)->ZLF_TOTAL , "@E 9,999,999.99") +";"
	_nTotDesc	+= (_cAlias)->ZLF_TOTAL
	(_cAlias)->(DBSkip())
EndDo

_cRet += PadR("Total de Descontos ------" , 46 , "-") + Transform(_nTotDesc	, "@E 9,999,999.99") +";"
_cRet += PadR("Total a Receber ---------" , 46 , "-") + Transform(_nVlrNF	, "@E 9,999,999.99") +";"

(_cAlias)->(DBCloseArea())

Return(_cRet)

/*
===============================================================================================================================
Programa--------: ITGETMOV
Autor-----------: Alexandre Villar
Data da Criacao-: 19/01/2015
Descrição-------: Rotina que retorna a descrição dos valores referentes aos itens do MIX
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ITGETMOV(_cMix As Character,_cCodProd As Character,_cLoja As Character,_nVlrNF As Numeric,_cLinha As Character,_cSetor As Character)

Local _aArea	:= FWGetArea() As Array
Local _aTemp	:= {} As Array
Local _cRet		:= "" As Character
Local _dDtAtual	:= SToD('') As Date

//====================================================================================================
// Obtendo movimentacao Diaria
//====================================================================================================
_dDtAtual	:= ZLE->ZLE_DTINI
_aTemp		:= {}

While _dDtAtual <= ZLE->ZLE_DTFIM
	aAdd(_aTemp , { SubStr(DToS(_dDtAtual) , 7 , 2) , Transform(U_GetVolDay(_cCodProd , _cLoja , DToS(_dDtAtual)) , "@E 99999") })
	_dDtAtual++
EndDo

_cRet += ITDESLEI(_aTemp)

FWRestArea(_aArea)

Return(_cRet)

/*
===============================================================================================================================
Programa--------: ITDESLEI
Autor-----------: Alexandre Villar
Data da Criacao-: 19/01/2015
Descrição-------: Rotina que retorna os dados do Array formatados como texto simples
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function ITDESLEI(_aTemp As Array)

Local _cRet		:= "" As Character
Local _cCabec	:= "" As Character
Local _cStr01	:= "" As Character
Local _cStr02	:= "" As Character
Local _cStr03	:= "" As Character
Local _cStr04	:= "" As Character
Local _nAux		:= 0 As Numeric
Local _nI		:= 0 As Numeric

For _nI := 1 to Len(_aTemp)
	_nAux++
	Do Case
		Case _nAux == 1
			_cStr01 += _aTemp[_nI][01] +"-"+ _aTemp[_nI][02] +"  "
			_cCabec += "Dia  Vol  "
		Case _nAux == 2
			_cStr02 += _aTemp[_nI][01] +"-"+ _aTemp[_nI][02] +"  "
		Case _nAux == 3
			_cStr03 += _aTemp[_nI][01] +"-"+ _aTemp[_nI][02] +"  "
		Case _nAux == 4
			_cStr04 += _aTemp[_nI][01] +"-"+ _aTemp[_nI][02] +"  "
			_nAux   := 0
	EndCase
Next _nI

_cRet := AllTrim(_cCabec) +";"+ AllTrim(_cStr01) +";"+ AllTrim(_cStr02) +";"+ AllTrim(_cStr03) +";"+ AllTrim(_cStr04) +";"

Return(_cRet)

/*
===============================================================================================================================
Programa--------: ValTotNF
Autor-----------: Lucas Borges
Data da Criacao-: 27/05/2022
Descrição-------: Função para validar se os valores das notas do produtores PJ está de acordo com o MIX
Parametros------: Nenhum
Retorno---------: .T. -> Permite prosseguir com o fechamento pois a diferença entre o valor do fechamento e o credito está 
					dentro do limite de tolerância.
===============================================================================================================================
*/
Static Function ValTotNF(_oProces As Object,_cCodMix As Character,_cCODSA2 As Character,_cLOJSA2 As Character,_cCODZL2 As Character,_cCODZL3 As Character,_nDifTotNF As Numeric)

Local _cAlias	:= GetNextAlias() As Character
Local _lRet		:= .T. As Logical

BeginSql Alias _cAlias
	SELECT SUM(ZLF_TOTAL) CREDITO,
       (SELECT SUM(F1_VALMERC) FROM %Table:SF1% WHERE D_E_L_E_T_ = ' '
           AND F1_FILIAL = ZLF_FILIAL
           AND F1_L_MIX = ZLF_CODZLE
           AND ZLF_A2COD = F1_FORNECE) NF
		FROM %Table:ZLF%
		WHERE ZLF_FILIAL = %xFilial:ZLF%
		AND ZLF_A2COD =%exp:_cCODSA2%
		AND ZLF_CODZLE = %exp:_cCodMix%
		AND ZLF_TP_MIX = 'L'
		AND ZLF_ENTMIX = 'S'
		AND ZLF_DEBCRE = 'C'
		AND D_E_L_E_T_ = ' '
		GROUP BY ZLF_FILIAL, ZLF_CODZLE, ZLF_A2COD
EndSql

If (_cAlias)->CREDITO > (_cAlias)->NF
	_lRet := .F.
	_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Validação Créditos X NF-e;Somatório das notas fiscais no documento de entrada são inferiores aos créditos de todos os produtores (mesmo código, lojas diferentes).'
	_oProces:SaveLog("Thread:"+_cThread+" MGLT00939 - " + _cMenAux)
	_oFile:Write(_cMenAux + ' - MGLT00939;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
ElseIf (_cAlias)->NF-(_cAlias)->CREDITO > _nDifTotNF
	_lRet := .F.
	_cMenAux := _cCODSA2 +';'+ _cLOJSA2 +';'+ _cCODZL2 +';'+ _cCODZL3 +';Validação Créditos X NF-e;Somatório das notas fiscais no documento de entrada menos os créditos de todos os produtores (mesmo código, lojas diferentes) é superior à 1.'
	_oProces:SaveLog("Thread:"+_cThread+" MGLT00940 - " + _cMenAux)
	_oFile:Write(_cMenAux + ' - MGLT00940;'+LTrim(Str(Seconds()-_nTempM)) +' segundos'+ CRLF)
EndIf

Return _lRet
