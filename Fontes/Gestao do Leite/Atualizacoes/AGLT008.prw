/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |27/02/2023| Chamado 43120. Migrada função AtCusto do GLTXFUN. Ajustada apuração do custo contábil do MIX.
Lucas Borges  |11/05/2023| Chamado 43777. Ajustado status da ZLD para os registros que não podem ser identificados no MGLT009.
Lucas Borges  |30/06/2023| Chamado 44347. Modificada query que atualiza custo do mix e incluído relatório de conferência.
===============================================================================================================================
*/

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Programa----------: AGLT008
Autor-------------: Renato de Morcerf
Data da Criacao---: 15/09/2008
Descrição---------: Trata Inclusao/alteracao/exclusao da tabela tabela do Mix.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT008()

Local aCores := {	{ "ZLE_STATUS == 'A'" , "BR_VERDE"		},;  //Mix pronto para Fechamento
					{ "ZLE_STATUS == 'F'" , "BR_VERMELHO"	},;  //Mix ja encerrado
					{ "ZLE_STATUS == 'P'" , "BR_AMARELO"	} }  //Mix em manutencao

Private cCadastro	:= "Mix do Leite"
Private aRotina		:= MenuDef()
Private cAlias		:= "ZLE"

mBrowse( 6, 1,22,75,cAlias,,,,,,aCores)

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 18/09/2018
Descrição---------: Utilizacao de Menu Funcional
Parametros--------: aRotina
					1. Nome a aparecer no cabecalho
					2. Nome da Rotina associada
					3. Reservado
					4. Tipo de Transa‡„o a ser efetuada:
						1 - Pesquisa e Posiciona em um Banco de Dados
						2 - Simplesmente Mostra os Campos
						3 - Inclui registros no Bancos de Dados
						4 - Altera o registro corrente
						5 - Remove o registro corrente do Banco de Dados
						6 - Altera determinados campos sem incluir novos Regs
					5. Nivel de acesso
					6. Habilita Menu Funcional
Retorno-----------: Array com opcoes da rotina
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina := {	{ "Pesquisar"		, "AxPesqui"		, 0 , 1 } ,;
					{ "Incluir"			, "U_AGLT020(1)"	, 0 , 3 } ,;
					{ "Visualizar"		, "U_AGLT020(10)"	, 0 , 10} ,;
					{ "Manutenção"		, "U_AGLT020(2)"	, 0 , 11} ,;
					{ "Exclusão"		, "U_AGLT020(5)"	, 0 , 5 } ,;
					{ "Fechar"			, "U_AGLT008S(1)"	, 0 , 5 } ,;
					{ "Reabrir"			, "U_AGLT008S(2)"	, 0 , 5 } ,;
					{ "Atu Custo"		, "U_AGLT008C()"	, 0 , 8 } ,;
					{ "Legenda"			, "U_AGLT008L()"	, 0 , 8 } }
Return( aRotina )

/*
===============================================================================================================================
Programa----------: AGLT008
Autor-------------: Renato de Morcerf
Data da Criacao---: 15/09/2008
Descrição---------: Legenda do MIX
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT008L()

Local aCores_ := {	{ 'ENABLE'		, "Mix Aberto"		},;
					{ 'BR_AMARELO'	, "Mix Pendente"	},;
					{ 'DISABLE'		, "Mix Fechado"		} }

BrwLegenda( cCadastro , "Legenda" , aCores_ )

Return

/*
===============================================================================================================================
Programa----------: AGLT008S
Autor-------------: Renato de Morcerf
Data da Criacao---: 15/09/2008
Descrição---------: Rotina que promove a Abertura/Fechanmento do Mix Selecionado
Parametros--------: nOpc	- Opção de Processamentp: 1 = Fechamento / 2 = Abertura
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT008S(nOpc)

Local _aFecPen	:= {}
Local _aHdrPen	:= {'Filial','Setor','Linha','Produtor','Loja','Nome','Status','Acerto'}
Local _cAlias	:= GetNextAlias()
Local cStatus	:= ""
Local cOperac	:= ""
Local _cUpdate	:= ""

Default nOpc	:= 0

Do Case
	Case nOpc == 1
		cStatus := "F"
		cOperac	:= "o Fechamento"
	Case nOpc == 2
		cStatus := "A"
		cOperac	:= "a Abertura"
EndCase

If Empty( cStatus )
	MsgStop("Falha ao identificar a operação! Informe a área de TI/ERP.","ALGT0801")
	Return
EndIf

If cStatus == 'F'

	BeginSql Alias _cAlias
		SELECT DISTINCT ZLF.ZLF_FILIAL, ZLF.ZLF_SETOR, ZLF.ZLF_LINROT, ZLF.ZLF_A2COD, ZLF.ZLF_A2LOJA, SA2.A2_NOME, ZLF.ZLF_STATUS, ZLF.ZLF_ACERTO
		FROM %Table:ZLF% ZLF, %Table:SA2% SA2
		WHERE ZLF.D_E_L_E_T_ =' '
		AND SA2.D_E_L_E_T_ =' '
		AND SA2.A2_FILIAL = %xFilial:SA2%
		AND ZLF.ZLF_A2COD = SA2.A2_COD
		AND ZLF.ZLF_A2LOJA = SA2.A2_LOJA
		AND ZLF.ZLF_CODZLE = %exp:ZLE->ZLE_COD%
		AND ZLF.ZLF_STATUS NOT IN ('F','B')
		AND ZLF.ZLF_ACERTO NOT IN ('S','B')
		ORDER BY ZLF.ZLF_FILIAL, ZLF.ZLF_SETOR, ZLF.ZLF_LINROT, ZLF.ZLF_A2COD, ZLF.ZLF_A2LOJA
	EndSql

	While (_cAlias)->(!Eof()) .And. !Empty( (_cAlias)->ZLF_A2COD )
		
		aAdd( _aFecPen , {	(_cAlias)->ZLF_FILIAL																	,;
							(_cAlias)->ZLF_SETOR 																	,;
							(_cAlias)->ZLF_LINROT																	,;
							(_cAlias)->ZLF_A2COD																	,;
							(_cAlias)->ZLF_A2LOJA																	,;
							(_cAlias)->A2_NOME																	,;
							U_ITRetBox( (_cAlias)->ZLF_STATUS , 'ZLF_STATUS' )										,;
							U_ITRetBox( (_cAlias)->ZLF_ACERTO , 'ZLF_ACERTO' )										})
		
	(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBCloseArea() )

EndIf

If cStatus == 'F' .And. !Empty( _aFecPen )
	MsgAlert("O MIX não pode ser fechado enquanto houverem registros pendentes de processamento!","AGLT00801")
	U_ITListBox( 'Relação de registros pendentes do MIX' , _aHdrPen , _aFecPen , .F. , 1 , 'Verifique os registros pendentes antes de Fechar o Mix:' )
Else
	If MsgYesNo( "Confirma "+ cOperac +" do Mix ["+ ZLE->ZLE_COD +"]?" )
		_cUpdate := " UPDATE "+ RetSqlName("ZLD") +" ZLD SET ZLD_STATUS = 'F' "
		_cUpdate += " WHERE  D_E_L_E_T_ = ' ' "
		_cUpdate += " AND ZLD_RETIRO = ' ' "
		_cUpdate += " AND ZLD_STATUS = ' ' "
		_cUpdate += " AND ZLD_DTCOLE BETWEEN '"+ DToS(ZLE->ZLE_DTINI) +"' AND '"+ DToS(ZLE->ZLE_DTFIM) +"' "
		
		If TCSqlExec(_cUpdate) < 0
			MsgStop("Erro ao atualizar o status das Recepções de Leite que não possuem produtor vinculado. Acione a TI. Erro: "+AllTrim(TCSQLError()),"GLTXFUN013")
		Else		
			ZLE->( RecLock( "ZLE" , .F. ) )
			ZLE->ZLE_STATUS := cStatus
			ZLE->( MSUnLock() )
		EndIf
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: AGLT008C
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 08/11/2022
Descrição---------: Função para buscar o custo do MIX nos documentos de entrada. A informação deve ser gravada no cadastro de 
					setor para que as rotinas que buscam um custo para os movimentos internos possam ter o valor real.
					O custo precisa ser por filial mas não deve ser por setor, logo, será gravada a mesma informação em todos 
					os setores
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT008C()

Local _aArea := FWGetArea()
Local _oSelf := Nil

tNewProcess():New(	"RGLT074"										,; // Função inicial
					"Atualiza Custo do Mix"							,; // Descrição da Rotina
					{|_oSelf| AtCustoP(_oSelf) }					,; // Função do processamento
					"Atualiza custo do Mix no cadastro de setor para que as movimentações internas das recepções "+;
					"sejam valorizada corretamente.",;				 // Descrição da Funcionalidade
					"RGLT074"										,; // Configuração dos Parâmetros
					{}												,; // Opções adicionais para o painel lateral
					.F.												,; // Define criação do Painel auxiliar
					0												,; // Tamanho do Painel Auxiliar
					''												,; // Descrição do Painel Auxiliar
					.T.												,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
					.F.                                              ) // Se .T. cria apenas uma regua de processamento.

FWRestArea(_aArea)

Return

Static Function AtCustoP(_oSelf)

Local _aSelFil	:= {}
Local _cFiltro := ""
Local _cUpdate := ""

//Chama função que permitirá a seleção das filiais
If MV_PAR01 == 1
	If Empty(_aSelFil)
		_aSelFil := AdmGetFil(.F.,.F.,"ZL2")
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf
_cFiltro += " AND ZL2_FILIAL "+ GetRngFil( _aSelFil, "ZL2", .T.,)

_cUpdate:="UPDATE "+RetSqlName("ZL2")+" ZL2 SET ZL2_DTUMIX = '"+DToS(Date())+"' , ZL2_HRUMIX = '"+Time()+"', ZL2_ULTMIX = "
_cUpdate+="NVL((SELECT Round(SUM(D1_CUSTO)/SUM(VOL),4) FROM ( "
_cUpdate+="		SELECT D1_FILIAL, D1_CUSTO,  "
_cUpdate+="       Case "
_cUpdate+="         WHEN SubStr(F1_FORNECE, 1, 1) = 'P' AND D1_ITEM = '0001' AND F1_L_SETOR <> ' ' THEN "
_cUpdate+="          (SELECT NVL(SUM(ZLD_QTDBOM), 0) "
_cUpdate+="             FROM "+RetSQLName("ZLD")+" ZLD, "+RetSQLName("ZLE")+" ZLE "
_cUpdate+="            WHERE ZLD.D_E_L_E_T_ = ' ' "
_cUpdate+="              AND ZLE.D_E_L_E_T_ = ' ' "
_cUpdate+="              AND ZLD_FILIAL = F1_FILIAL "
_cUpdate+="              AND ZLD_DTCOLE BETWEEN ZLE_DTINI AND ZLE_DTFIM "
_cUpdate+="              AND F1_FILIAL = ZLD_FILIAL "
_cUpdate+="              AND F1_FORNECE = ZLD_RETIRO "
_cUpdate+="              AND F1_LOJA = ZLD_RETILJ "
_cUpdate+="              AND F1_L_MIX = ZLE_COD "
_cUpdate+="              AND F1_L_SETOR = ZLD_SETOR "
_cUpdate+="              AND SF1.F1_L_LINHA = ZLD_LINROT) "
_cUpdate+="         WHEN SubStr(F1_FORNECE, 1, 1) = 'P' AND D1_ITEM = '0001' AND F1_L_SETOR = ' ' THEN D1_QUANT "
_cUpdate+="         Else 0 END VOL "
_cUpdate+="  FROM "+RetSQLName("SD1")+" SD1, "+RetSQLName("SF1")+" SF1 "
_cUpdate+=" WHERE SD1.D_E_L_E_T_ = ' ' "
_cUpdate+="   AND SF1.D_E_L_E_T_ = ' ' "
_cUpdate+="   AND F1_FILIAL = D1_FILIAL "
_cUpdate+="   AND F1_DOC = D1_DOC "
_cUpdate+="   AND F1_SERIE = D1_SERIE "
_cUpdate+="   AND F1_FORNECE = D1_FORNECE "
_cUpdate+="   AND F1_LOJA = D1_LOJA "
_cUpdate+="   AND F1_FILIAL = ZL2_FILIAL "
_cUpdate+="   AND F1_STATUS = 'A' "
_cUpdate+="   AND F1_DTDIGIT BETWEEN '"+DToS(MV_PAR02)+"' AND '"+DToS(MV_PAR03)+"' "
_cUpdate+="   AND ((F1_L_MIX <> ' ' AND NOT EXISTS "
_cUpdate+="        (SELECT 1 FROM "+RetSQLName("ZZ4")
_cUpdate+="           WHERE D_E_L_E_T_ = ' ' "
_cUpdate+="             AND ZZ4_FILIAL = F1_FILIAL "
_cUpdate+="             AND ZZ4_CODMIX = F1_L_MIX "
_cUpdate+="             AND ZZ4_CODPRO = F1_FORNECE "
_cUpdate+="             AND ZZ4_LOJPRO = F1_LOJA "
_cUpdate+="             AND ZZ4_NUMCNF = F1_DOC "
_cUpdate+="             AND ZZ4_SERIE = F1_SERIE))  "
_cUpdate+="        OR F1_FORNECE LIKE 'G%' "
_cUpdate+="        OR (F1_ESPECIE = 'CTE' AND EXISTS "
_cUpdate+="        (SELECT 1 FROM ZLX010 ZLX, ZA7010 ZA7"
_cUpdate+="           WHERE ZLX.D_E_L_E_T_ = ' ' "
_cUpdate+="             AND ZA7.D_E_L_E_T_ = ' ' "
_cUpdate+="             AND ZLX_FILIAL = F1_FILIAL "
_cUpdate+="             AND ZLX_TRANSP = F1_FORNECE "
_cUpdate+="             AND ZLX_LJTRAN = F1_LOJA "
_cUpdate+="             AND ZA7_CODPRD = ZLX_PRODLT "
_cUpdate+="             AND ZA7_FILIAL = ZLX_FILIAL "
_cUpdate+="             AND ZLX_PGFRT = 'S' "
_cUpdate+="             AND ZLX_TIPOLT = 'P' "
_cUpdate+="             AND ZLX_ORIGEM = '3' "
_cUpdate+="             AND ZA7_TIPPRD = '001')) "
_cUpdate+="        ))),0) "
_cUpdate+=" WHERE D_E_L_E_T_ = ' ' "
_cUpdate+= _cFiltro

If TCSqlExec(_cUpdate) < 0
	MsgStop("Erro ao atualizar o custo do Mix. Acione a TI. Erro: "+AllTrim(TCSQLError()),"GLTXFUN013")
EndIf

Return
