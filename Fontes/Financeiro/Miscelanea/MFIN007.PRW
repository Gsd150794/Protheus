/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Jonathan      |25/03/2020| Chamado 32378. Corrigido error.log
Lucas Borges  |17/12/2020| Chamado 35014. Rotina totalmente reescrita
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MFIN007
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 13/03/2013
Descrição-------: Funcao desenvolvida para o envio para o Banco do Brasil e Santander
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MFIN007

Local _cPerg  		:= 'MFIN007'
Local _oProces		:= NIL

TNewProcess():New(	_cPerg											,; // Função inicial
					"Geração Arquivo FGPP"							,; // Descrição da Rotina
					{|_oProces| MFIN007R(_oProces) }				,; // Função do processamento
					"Essa rotina tem por objetivo gerar um arquivo conforme layout do banco selecionado' "+;
					"para conprovação de movimentação de produtores do Leite!",; // Descrição da Funcionalidade
					_cPerg											,; // Configuração dos Parâmetros
					{}												,; // Opções adicionais para o painel lateral
					.F.												,; // Define criação do Painel auxiliar
					0												,; // Tamanho do Painel Auxiliar
					''												,; // Descrição do Painel Auxiliar
					.T.												,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
	                .T.                                              ) // Se .T. cria apenas uma regua de processamento.

Return

/*
===============================================================================================================================
Programa--------: MFIN007R
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 13/03/2013
Descrição-------: Funcao desenvolvida para o envio para o Banco do Brasil e Santander
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function MFIN007R(_oProces) 

Local _cFiltro		:= '%'
Local _cAlias		:= GetNextAlias()
Local _aSelFil		:= {}
Local _nSequencia	:= GetMv("IT_NUMBB",,0)
Local _cNome		:= ""
Local _nHdlLog		:= 0
Local _nCountRec 	:= 0
Local _nTamLin		:= 130
Local _cLin			:= ''
Local _nCont		:= 0
Local _nTotFin		:= 0
Local _nQuant		:= 0
Local _nValorFin	:= 0
Local _nSoma		:= 0
Local _nTotPag		:= 0
Local _lUltimo		:= .F.

If MV_PAR23 == 1
	If MV_PAR22 > 0
		_nSequencia := StrZero( MV_PAR22, 09 )
	Else
		_nSequencia := Soma1( StrZero(_nSequencia, 09 ) )
	EndIf   

	_cNome := AllTrim(MV_PAR19)+"BB"+ cValToChar(_nSequencia)+".txt"
Else
	_cNome := AllTrim(MV_PAR19)+AllTrim(MV_PAR24)+".csv"
EndIf

_nHdlLog := FCreate(_cNome)

If _nHdlLog == -1
	MsgStop("Erro ao criar aqruivo. A rotina não será executada!", "MFIN00701")
	Return
EndIf

_oProces:SetRegua1(2)
_oProces:IncRegua1('Buscando registros no banco de dados...')

//Chama função que permitirá a seleção das filiais
If MV_PAR09 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"SE2")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

_cFiltro += " AND E2.E2_FILIAL "+ GetRngFil( _aSelFil, "SE2", .T.,)
_cFiltro += " AND E2.E2_L_MIX IN "+ FormatIn( AllTrim(MV_PAR10) , ";" )

If Len( AllTrim( MV_PAR21 ) ) > 0
	_cFiltro += " AND E2.E2_FORNECE NOT IN "+ FormatIn( AllTrim(MV_PAR21)+";"+AllTrim(MV_PAR27) , ";" )
EndIf

//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR12) .Or. Empty(MV_PAR12) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND E2.E2_L_SETOR IN "+ FormatIn( AllTrim(MV_PAR12) , ';' )
EndIf
   		
_cFiltro += IIf( MV_PAR17 == 1 , " AND A2.A2_TIPO = 'F' ", IIf( MV_PAR17 == 2 , " AND A2.A2_TIPO = 'J' "  , "" ))
_cFiltro += "%"

BeginSql alias _cAlias
	SELECT * FROM (SELECT E2.E2_FILIAL, E2.E2_FORNECE, E2.E2_LOJA, A2.A2_NOME, A2.A2_CGC, A2.A2_TIPO, E2.E2_NUM, E2.E2_PREFIXO, E2.E2_EMISSAO,
		Round((SELECT SUM(ZLD.ZLD_QTDBOM)
				FROM %Table:ZLD% ZLD
				WHERE ZLD.D_E_L_E_T_ = ' '
					AND ZLD_FILIAL = E2_FILIAL
					AND ZLD.ZLD_RETIRO = E2.E2_FORNECE
					AND ZLD.ZLD_RETILJ = E2.E2_LOJA
					AND ZLD.ZLD_SETOR = E2.E2_L_SETOR
					AND ZLD.ZLD_LINROT = E2.E2_L_LINRO
					AND ZLD.ZLD_DTCOLE BETWEEN ZLE.ZLE_DTINI AND ZLE.ZLE_DTFIM),
				3) VOLLEITE,
		SUM(E2_VALOR) VLRPAGO, SubStr(X5_DESCRI, 2, 2) || SubStr(A2.A2_COD_MUN, 1, 4) COD_MUN, CC2.CC2_MUN, A2.A2_EST
	FROM %Table:SE2% E2, %Table:SA2% A2, %Table:CC2% CC2, %Table:SX5% SX5, %Table:ZLE% ZLE
	WHERE E2.D_E_L_E_T_ = ' '
	AND A2.D_E_L_E_T_ = ' '
	AND CC2.D_E_L_E_T_ = ' '
	AND SX5.D_E_L_E_T_ = ' '
	AND ZLE.D_E_L_E_T_ = ' '
	AND A2.A2_COD = E2.E2_FORNECE
	AND A2.A2_LOJA = E2.E2_LOJA
	AND CC2.CC2_EST = A2.A2_EST
	AND CC2.CC2_CODMUN = A2.A2_COD_MUN
	AND SX5.X5_FILIAL = ' '
	AND SX5.X5_TABELA = 'AA'
	AND SX5.X5_CHAVE = A2.A2_EST
	AND E2.E2_L_MIX = ZLE.ZLE_COD
	AND E2.E2_FORNECE LIKE 'P%'
	AND E2.E2_TIPO = 'NF '
	%exp:_cFiltro%
	AND E2.E2_FORNECE BETWEEN %exp:MV_PAR13% AND %exp:MV_PAR15%
	AND E2.E2_LOJA BETWEEN %exp:MV_PAR14% AND %exp:MV_PAR16%
	GROUP BY E2.E2_FILIAL, E2.E2_FORNECE, E2.E2_LOJA, A2.A2_NOME, A2.A2_CGC, A2.A2_TIPO, E2.E2_EMISSAO,
			SubStr(X5_DESCRI, 2, 2) || SubStr(A2.A2_COD_MUN, 1, 4), E2.E2_L_MIX, E2.E2_L_SETOR, E2.E2_L_LINRO,
			CC2.CC2_MUN, A2.A2_EST, E2.E2_NUM, E2.E2_PREFIXO, ZLE.ZLE_DTINI, ZLE.ZLE_DTFIM
	ORDER BY SUM(E2_VALOR) DESC, E2.E2_FORNECE, A2.A2_CGC)
	WHERE VLRPAGO >= VOLLEITE * %exp:MV_PAR20%
EndSql

Count To _nCountRec
(_cAlias)->( DBGoTop() )

_oProces:SetRegua1(_nCountRec)

//====================================================================================================
// Impressao do Cabecalho
//====================================================================================================
If MV_PAR23 == 1
	_cLin := Space(_nTamLin)								// Variavel para criacao da linha do registros para gravacao
	_cLin := Stuff(_cLin,01,02,"00") 						// Código que identifica  cabeçalho com dados fixos do arquivo.
	_cLin := Stuff(_cLin,03,10,PadR("RCOF310",08))			// Nome do arquivo enviado.
	_cLin := Stuff(_cLin,11,18,PadL(Day2Str(dDataBase)+Month2Str(dDataBase)+Year2Str(dDataBase),08))// Data da remessa.
	_cLin := Stuff(_cLin,19,27,StrZero(Val(_nSequencia),09))// Número da remessa.
	_cLin := Stuff(_cLin,28,41,StrZero(Val(MV_PAR01),14))	// Número do CNPJ da empresa.
	_cLin := Stuff(_cLin,42,50,StrZero(Val(MV_PAR02),09))	// Agência com a qual a empresa assinou o contrato de utilização do gerenciador financeiro.
	_cLin := Stuff(_cLin,51,59,StrZero(Val(MV_PAR03),09))	// Conta-corrente, pertencente à empresa, na agência onde foi assinado o contrato, que vincula à utilização do gerenciador financeiro
	_cLin := Stuff(_cLin,60,68,StrZero(Val(MV_PAR04),09))	// Número do contrato no RCO para Intercâmbio Eletrônico de Dados(IED).
	_cLin := Stuff(_cLin,69,77,StrZero(Val(MV_PAR05),09))	// Número da Unidade Organizacional)
	_cLin := Stuff(_cLin,78,130,PadL(" ",53))				// Espaços em branco.
	_cLin += CRLF
	FWrite( _nHdlLog , _cLin , Len(_cLin) )

	//====================================================================================================
	// Impressao do detalhe 1
	//====================================================================================================
	_cLin := Space(_nTamLin)
	_cLin := Stuff(_cLin,01,02,"01")			// Código que identifica conteúdo1(detalhe1), contendo dados para exclusão de lote previamente gravado.
	_cLin := Stuff(_cLin,03,13,PadL(" ",11))	// Número do lote cadastrado no BB.
	_cLin := Stuff(_cLin,14,130,PadL(" ",117))	// Espaços em branco.
	_cLin += CRLF
	FWrite( _nHdlLog , _cLin , Len(_cLin) )

	//====================================================================================================
	// Impressao do detalhe 2
	//====================================================================================================
	_cLin := Stuff(_cLin,01,02,"02") 						// Código que identifica conteúdo2(detalhe2), contendo dados fixos para inclusão de fornecedores.
	_cLin := Stuff(_cLin,03,07,StrZero(Val("30"),05))		// Número da Linha de Crédito. FGPP ou FAC.
	_cLin := Stuff(_cLin,08,12,StrZero(Val(MV_PAR06),05))	// Produto conforme um dos códigos de Produto Bacen.
	_cLin := Stuff(_cLin,13,21,PadL(MV_PAR07,09))			// Informação referente a safra do crédito.
	_cLin := Stuff(_cLin,22,26,StrZero(Val(MV_PAR08),05))	// Agência com a qual a empresa efetuará a operação.
	_cLin := Stuff(_cLin,27,130,PadL(" ",104))				// Espaços em branco.
	_cLin += CRLF

Else
	_cLin := ";;RELAÇÃO PARA COMPROVAÇÃO DA AQUISIÇÃO DE PRODUTO OBJETO DE FINANCIAMENTO FGPP/FEPM/FAC/ESTOCAGEM"+CRLF
	_cLin += "NOME DO MUTUARIO;"+ SM0->M0_NOMECOM+CRLF
	_cLin += "CNPJ MUTUARIO;"+ Transform((MV_PAR01),'@R! NN.NNN.NNN/NNNN-99')+CRLF
	_cLin += "PRODUTO;"+ MV_PAR06+CRLF
	_cLin += "SAFRA;"+ MV_PAR07+CRLF
	_cLin += "VALOR OPERAÇÃO: R$;"+ AllTrim( Transform( MV_PAR18 , '@E 9999999.99' ) )+CRLF
	_cLin += "AGRONOMO RESPONSÁVEL (NÃO PREENCHER);"+CRLF
	_cLin += ""+CRLF
	_cLin += "FORNECEDOR;;;;NOTA FISCAL"+CRLF
	_cLin += "NOME;CPF/CNPJ;MUNICIPIO DE ORIGEM DO PRODUTO;UF;NUMERO;DATA DE EMISSAO;QUANTIDADE/KG/L;VALOR UNITARIO - R$;VALOR TOTAL - R$" +CRLF
EndIf
FWrite( _nHdlLog , _cLin , Len(_cLin) )

//====================================================================================================
// Impressao da linha detalhe3
//====================================================================================================
While (_cAlias)->( !Eof() ) .And. !_lUltimo

	_oProces:IncRegua1('Gerando arquivo...')
	_nValorFin += (_cAlias)->VOLLEITE * MV_PAR20
	
	If _nValorFin < MV_PAR18
		_nTotFin += (_cAlias)->VOLLEITE * MV_PAR20
	Else
		_nSoma := MV_PAR18 - _nTotFin
		_nTotFin += _nSoma
		_lUltimo := .T.
	EndIf
	
	If MV_PAR23 == 1
		//====================================================================================================
		// Código que identifica conteúdo 3, contendo dados complementares para inclusão de fornecedores.
		//====================================================================================================
		_cLin := Space(_nTamLin) 										// Variavel para criacao da linha do registros para gravacao 
		_cLin := Stuff(_cLin,01,02,"03")
		_cLin := Stuff(_cLin,03,16,StrZero(Val((_cAlias)->A2_CGC),14))	// CPF/CNPJ do produtor rural.
		_cLin := Stuff(_cLin,17,17,(_cAlias)->A2_TIPO)					// Determina se o conteúdo do campo Código do CNPJ CPF do Produtor Rural é um CNPJ.
		_cLin := Stuff(_cLin,18,20,(_cAlias)->E2_PREFIXO) 							// Série da Nota Fiscal
		_cLin := Stuff(_cLin,21,37,StrZero(Val((_cAlias)->E2_NUM),17)) 				// Número da Nota Fiscal. 
		_cLin := Stuff(_cLin,38,45,PadL((SubStr((_cAlias)->E2_EMISSAO,7,2) + SubStr((_cAlias)->E2_EMISSAO,5,2) + SubStr((_cAlias)->E2_EMISSAO,1,4)),08)) // Data da compra.
		If _lUltimo
			_cLin := Stuff(_cLin,46,63,StrZero(((Int(_nSoma/MV_PAR20))*1000),18)) 		// Quantidade adquirida.
			_cLin := Stuff(_cLin,64,80,StrZero(((_cAlias)->VLRPAGO*100),17)) 			// Valor pago.
			_cLin := Stuff(_cLin,81,97,StrZero((_nSoma*100),17)) 						// Total ou parcela do valor pago a ser financiado.
		Else
			_cLin := Stuff(_cLin,46,63,StrZero((_cAlias)->VOLLEITE*1000,18))			// Quantidade adquirida.
			_cLin := Stuff(_cLin,64,80,StrZero(((_cAlias)->VLRPAGO*100),17)) 			// Valor pago.
			_cLin := Stuff(_cLin,81,97,StrZero((((_cAlias)->VOLLEITE*MV_PAR20)*100),17))// Total ou parcela do valor pago a ser financiado.
		EndIf
		
		_cLin := Stuff(_cLin,98,117,PadR("L",20))										// Unidade de medida a qual deve estar vinculada a quantidade, quando apresentada para o produto.
		_cLin := Stuff(_cLin,118,124,StrZero(Val((_cAlias)->COD_MUN),07))				// O município da origem do produto. 
		_cLin := Stuff(_cLin,125,130,PadL(" ",06))										// Espaços em branco.
		_cLin += CRLF
	
	Else

		_cLin := SubStr(AllTrim((_cAlias)->A2_NOME),1,60)+";"				//Nome Produtor
		If Len( AllTrim((_cAlias)->A2_CGC) ) = 11
			_cLin += Transform((_cAlias)->A2_CGC,'@R 999.999.999-99')+";"	//CPF/CNPJ
		Else
			_cLin += Transform((_cAlias)->A2_CGC,'@R! NN.NNN.NNN/NNNN-99')+";"//CPF/CNPJ
		EndIf
		_cLin += SubStr(AllTrim((_cAlias)->CC2_MUN),1,20)+";"				//Município
		_cLin += (_cAlias)->A2_EST+";"										//UF
		_cLin += (_cAlias)->E2_NUM+";"										//Número da Nota
		_cLin += SubStr((_cAlias)->E2_EMISSAO,7,2)+"/"+SubStr((_cAlias)->E2_EMISSAO,5,2)+"/"+SubStr((_cAlias)->E2_EMISSAO,1,4)+";"	//Emissão
		_cLin += AllTrim(Transform((_cAlias)->VOLLEITE,'@E 99,999.99'))+";"								// Quantidade/KG/L
		_cLin += AllTrim(Transform(( (_cAlias)->VLRPAGO / (_cAlias)->VOLLEITE ),'@E 9999999.9999'))+";"	//Valor Unitário
		_cLin += AllTrim(Transform((_cAlias)->VLRPAGO,'@E 99999999.99'))+";"							//Valor total
		_cLin += CRLF
	EndIf
	FWrite( _nHdlLog , _cLin , Len(_cLin) )
	_nCont++
	
	If _lUltimo
		_nQuant += (int(_nSoma/MV_PAR20))
		_nTotPag += (_cAlias)->VLRPAGO
	Else
		_nQuant += (_cAlias)->VOLLEITE
		_nTotPag += (_cAlias)->VLRPAGO
	EndIf

	(_cAlias)->( DBSkip() )
EndDo


If MV_PAR23 == 1
	//====================================================================================================
	// Impressao do detalhe4
	//====================================================================================================
	_cLin := Space(_nTamLin)
	_cLin := Stuff(_cLin,01,02,"04")						// Código que identifica conteúdo4(detalhe4), contendo dados complementares para inclusão de informações de fornecedores.
	_cLin := Stuff(_cLin,03,09,StrZero(_nCont+2,07))		// Quantidade de registros somados do detalhe2 ao detalhe4.
	_cLin := Stuff(_cLin,10,27,StrZero(_nQuant*1000,18)) 	//Soma das quantidades adquiridas em todos os registros detalhe3 entre o detalhe2 e o detalhe4
	_cLin := Stuff(_cLin,28,44,StrZero((_nTotPag*100),17))	// Soma dos valores pagos em todos os registros detalhe1 entre o detalhe2 e o detalhe4.
	_cLin := Stuff(_cLin,45,61,StrZero((_nTotFin*100),17))	// Soma dos valores financiados em todos os registros detalhe1 entre o detalhe2 e o detalhe4.
	_cLin := Stuff(_cLin,62,130,PadL(" ",69))				// Espaços em branco.
	_cLin += CRLF

	FWrite( _nHdlLog , _cLin , Len(_cLin) )

	//====================================================================================================
	// Ultima Linha
	//====================================================================================================
	_cLin := Space(_nTamLin)
	_cLin := Stuff(_cLin,01,02,"99")				// Código que identifica a última linha do arquivo.
	_cLin := Stuff(_cLin,03,09,StrZero(_nCont+5,07))// Quantidade de registros somados do Header até o Trailer.
	_cLin := Stuff(_cLin,10,130,PadL(" ",121))		// Espaços em branco.
	_cLin += CRLF
Else
	_cLin := ";;;;TOTAL"+";;;"+AllTrim(Transform((_nQuant),'@E 9999999.9999'))+";"+AllTrim(Transform((_nTotPag),'@E 99999999.99')) +";"+CRLF
	_cLin += "(*) INDICAR A UNIÃO FEDERATIVA (SIGLA DO ESTADO) ONDE SE OBTEVE A PRODUÇÃO"+";"+CRLF
	_cLin += ""+";"+CRLF
	_cLin += "DECLARAÇÕES:"+";"+CRLF
	_cLin += "DECLARAMOS QUE O PRODUTO ACIMA RELACIONADO É ORIUNDO DA SAFRA 2012/2013 E NÃO É OBJETO DE QUALQUER OUTRO FINANCIAMENTO."+";"+CRLF
	_cLin += "DECLARAMOS QUE DE ACORDO COM OS NORMATIVOS VIGENTES, O VALOR DAS AQUISIÇÕES POR PRODUTOR RURAL NÃO EXTRAPOLA O LIMITE ESTABELECIDO, NESTA INSTITUIÇÃO FINANCEIRA."+";"+CRLF
	_cLin += "AUTORIZAMOS O ENVIO DAS INFORMAÇÕES CONSTANTES NESTA RELAÇÃO AO MAPA (MINISTÉRIO DA AGRICULTURA PECUÁRIA E ABASTECIMENTO), AO BACEN (BANCO CENTRAL DO BRASIL) E AO MF (MINISTÉRIO DA FAZENDA)."+";"+CRLF
	_cLin += "QUANDO O PRODUTO For ADQUIRIDO DE COOPERATIVAS, ESTAS DEVERÃO ANEXAR RELAÇÃO COMPROBATÓRIA DAS AQUISIÇÕES DE PRODUTORES RURAIS COM OS MESMOS CAMPOS/INFORMAÇÕES DESTA PLANILHA."+";"+CRLF
	_cLin += ";"+CRLF+";"+CRLF+";"+CRLF
	_cLin += AllTrim(SM0->M0_CIDCOB)+'/'+AllTrim(SM0->M0_ESTENT)+', '+StrZero(Day(dDatabase),2)+' DE '+Upper(MesExtenso(Month(dDatabase))) +' DE '+StrZero(Year(dDatabase),4)+CRLF
	_cLin += ";"+CRLF+";"+CRLF+";"+CRLF
	_cLin += "_____________________________________________"+";"+CRLF
	_cLin += "NOME: "+Upper(MV_PAR26)+";"+CRLF
	_cLin += "CPF/CNPJ: "+Transform((MV_PAR25),'@R 999.999.999-99')+";"+CRLF
EndIf
FWrite(_nHdlLog,_cLin,Len(_cLin))

If MV_PAR23 == 1 .And. _nTotFin > 0
   PutMV("IT_NUMBB",_nSequencia)
EndIf

(_cAlias)->( DBCloseArea() )
FClose( _nHdlLog )

Return
