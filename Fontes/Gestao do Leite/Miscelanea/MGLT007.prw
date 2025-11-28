/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |14/09/2023| Chamado 45039. Retirada duas colunas que foram excluídas do layout
Lucas Borges  |19/12/2023| Chamado 45856. Modificada regra para Mix fechados com atraso
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGLT007
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 04/04/2023
Descrição---------: Mapa de Recebimento de Leite Eletrônico - Chamado 43433
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT007

Local _cPerg		:= "MGLT007"
Local _oSelf		:= nil

//============================================
//Cria interface principal
//============================================
tNewProcess():New(	_cPerg											,; // Função inicial
					"Mapa de Recebimento de Leite Eletrônico"		,; // Descrição da Rotina
					{|_oSelf| MGLT007P(_oSelf) }					,; // Função do processamento
					"Este programa irá gerar um arquivo XML com as informações de compra e venda de leite"+;
					"para ser importado no sistema da SEFAZ-MG. "	,; // Descrição da Funcionalidade
					_cPerg											,; // Configuração dos Parâmetros
					{}												,; // Opções adicionais para o painel lateral
					.F.												,; // Define criação do Painel auxiliar
					0												,; // Tamanho do Painel Auxiliar
					''												,; // Descrição do Painel Auxiliar
					.T.												,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
                    .F.                                              ) // Se .T. cria apenas uma regua de processamento.

Return

/*
===============================================================================================================================
Programa----------: MGLT007P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 04/04/2023
Descrição---------: Realiza o processamento da rotina.
Parametros--------: _oSelf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT007P(_oSelf)

Local _oExcel := NIL
Local _cAlias := GetNextAlias()
Local _cArquivo	:= ""

If Empty(MV_PAR03)
	//Diretório padrão de instalação do Software da SEFAZ
	_cArquivo :=  "C:\Arquivos de Programas(86)\SEF\mapa_de_recebimento_de_leite\Arquivos_FonteDados\"
Else
	_cArquivo := AllTrim(MV_PAR03)
EndIf

_cArquivo += "MRL_P_01_"+PadL(FWSM0Util():GetSM0Data(cEmpAnt,cFilAnt,{"M0_INSC"})[1][2],13,"0")+"_"+ANOMES(MV_PAR01)+".xlsx"

//Criando o objeto que irá gerar o conteúdo do Excel
_oExcel := FwMsExcelXlsx():New()

_oSelf:SetRegua1(3)
_oSelf:IncRegua1("Gerando Produtores...")
//Criando Aba 1
_oExcel:AddworkSheet("Produtores")
//Criando a Tabela
_oExcel:AddTable ("Produtores","Table1",.F.)
//Criando Colunas
_oExcel:AddColumn("Produtores","Table1","CD_PRODUTOR_IE"	,1,1,.F.,)
_oExcel:AddColumn("Produtores","Table1","CD_PRODUTOR_CPF"	,1,1,.F.,)
_oExcel:AddColumn("Produtores","Table1","NM_PRODUTOR"		,1,1,.F.,)

BeginSql alias _cAlias
	SELECT A2_INSCR, A2_CGC, A2_NOME 
	FROM %Table:SA2% 
	WHERE D_E_L_E_T_ = ' '
	AND EXISTS (SELECT 1 FROM %Table:SF1%
	WHERE D_E_L_E_T_ = ' '
	AND A2_COD = F1_FORNECE
	AND A2_LOJA = F1_LOJA
	AND F1_FILIAL = %xFilial:SF1%
	AND A2_TIPO = 'F'
	AND F1_FORMUL = 'S'
	AND F1_DTDIGIT BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%)
	ORDER BY A2_INSCR
EndSql

_oSelf:SetRegua2(2)
_oSelf:IncRegua2("")
//Criando as Linhas
While (_cAlias)->(!Eof())
	_oExcel:AddRow("Produtores","Table1",{(_cAlias)->A2_INSCR,;
                                          (_cAlias)->A2_CGC,;
                                          (_cAlias)->A2_NOME })
	(_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())

_oSelf:IncRegua1("Gerando Recebimento-Leite...")
//Criando Aba 1
_oExcel:AddworkSheet("Recebimento-Leite")
//Criando a Tabela
_oExcel:AddTable ("Recebimento-Leite","Table2",.F.)
//Criando Colunas
_oExcel:AddColumn("Recebimento-Leite","Table2","CD_PRODUTOR_IE"	,1,1,.F.,)
_oExcel:AddColumn("Recebimento-Leite","Table2","DT_RECEBIMENTO"	,1,4,)
_oExcel:AddColumn("Recebimento-Leite","Table2","QT_LITROS"		,3,2,)
_oExcel:AddColumn("Recebimento-Leite","Table2","CD_PLACA"		,1,1,)

_cAlias := GetNextAlias()
BeginSql alias _cAlias
	SELECT A2_INSCR, ZLD_DTCOLE, ZLD_QTDBOM, ZL1_PLACA,
		Round(F1_VALBRUT / VOL_TOT * ZLD_QTDBOM, 2) VR_BRUTO,
		Round(F1_VALMERC / VOL_TOT * ZLD_QTDBOM, 2) VR_LIQUIDO
	FROM (SELECT A2_INSCR, ZLD_DTCOLE, SUM(ZLD_QTDBOM) ZLD_QTDBOM, ZL1_PLACA,
				(SELECT SUM(F1_VALMERC)
					FROM %Table:SF1% F
					WHERE D_E_L_E_T_ = ' '
					AND A.F1_FILIAL = F.F1_FILIAL
					AND A.A2_COD = F.F1_FORNECE
					AND A.A2_LOJA = F.F1_LOJA
					AND A.F1_DTDIGIT = F.F1_DTDIGIT
					AND F1_FORMUL = 'S') F1_VALMERC,
				(SELECT SUM(F1_VALBRUT)
					FROM %Table:SF1% F
					WHERE D_E_L_E_T_ = ' '
					AND A.F1_FILIAL = F.F1_FILIAL
					AND A.A2_COD = F.F1_FORNECE
					AND A.A2_LOJA = F.F1_LOJA
					AND A.F1_DTDIGIT = F.F1_DTDIGIT
					AND F1_FORMUL = 'S') F1_VALBRUT,
				(SELECT SUM(ZLD_QTDBOM)
					FROM %Table:ZLD% ZLD, %Table:ZLE% ZLE, %Table:SF1% SF1
					WHERE ZLD.D_E_L_E_T_ = ' '
					AND SF1.D_E_L_E_T_ = ' '
					AND ZLE.D_E_L_E_T_ = ' '
					AND A.F1_FILIAL = SF1.F1_FILIAL
					AND A2_COD = F1_FORNECE
					AND A2_LOJA = F1_LOJA
					AND F1_FORMUL = 'S'
					AND F1_FILIAL = ZLD_FILIAL
					AND F1_FORNECE = ZLD_RETIRO
					AND F1_LOJA = ZLD_RETILJ
					AND F1_L_SETOR = ZLD_SETOR
					AND F1_L_LINHA = ZLD_LINROT
					AND F1_L_MIX = ZLE_COD
					AND F1_DTDIGIT BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
					AND ZLD_DTCOLE BETWEEN ZLE_DTINI AND ZLE_DTFIM) VOL_TOT
			FROM (SELECT F1_FILIAL, F1_DTDIGIT, A2_COD, A2_LOJA, A2_INSCR,
						Case WHEN ZLD_DTCOLE < %exp:MV_PAR01% THEN %exp:MV_PAR01% Else ZLD_DTCOLE END ZLD_DTCOLE,
						SUM(ZLD_QTDBOM) ZLD_QTDBOM, ZL1_PLACA
					FROM %Table:ZLD% ZLD, %Table:SA2% SA2, %Table:ZL1% ZL1, %Table:ZLE% ZLE, %Table:SF1% SF1
					WHERE ZLD.D_E_L_E_T_ = ' '
					AND SF1.D_E_L_E_T_ = ' '
					AND SA2.D_E_L_E_T_ = ' '
					AND ZL1.D_E_L_E_T_ = ' '
					AND ZLE.D_E_L_E_T_ = ' '
					AND A2_COD = F1_FORNECE
					AND A2_LOJA = F1_LOJA
					AND F1_FILIAL = ZLD_FILIAL
					AND F1_FORNECE = ZLD_RETIRO
					AND F1_LOJA = ZLD_RETILJ
					AND F1_L_SETOR = ZLD_SETOR
					AND F1_L_LINHA = ZLD_LINROT
					AND F1_L_MIX = ZLE_COD
					AND F1_FORMUL = 'S'
					AND F1_DTDIGIT BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
					AND ZLD_FILIAL = %xFilial:SF1%
					AND ZLD_FILIAL = ZL1_FILIAL
					AND ZLD_VEICUL = ZL1_COD
					AND ZLD_DTCOLE BETWEEN ZLE_DTINI AND ZLE_DTFIM
					AND A2_TIPO = 'F'
					GROUP BY F1_FILIAL, F1_DTDIGIT, A2_INSCR, A2_COD, A2_LOJA, ZLE_DTINI, ZLE_DTFIM, ZLD_DTCOLE, ZL1_PLACA, F1_L_SETOR, F1_L_LINHA) A
			GROUP BY A2_INSCR, ZLD_DTCOLE, ZL1_PLACA, F1_FILIAL, A2_COD, A2_LOJA, F1_DTDIGIT)
	ORDER BY A2_INSCR, ZLD_DTCOLE
EndSql

_oSelf:SetRegua2(2)
_oSelf:IncRegua2("")
//Criando as Linhas
While (_cAlias)->(!Eof())
	_oExcel:AddRow("Recebimento-Leite","Table2",{(_cAlias)->A2_INSCR,;
                                          SToD((_cAlias)->ZLD_DTCOLE),;
                                          (_cAlias)->ZLD_QTDBOM,;
										  (_cAlias)->ZL1_PLACA})
	(_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())


_oSelf:IncRegua1("Gerando Notas Fiscais - Globais...")
//Criando Aba 3
_oExcel:AddworkSheet("Notas Fiscais - Globais")
//Criando a Tabela
_oExcel:AddTable("Notas Fiscais - Globais","Table3",.F.)
//Criando Colunas
_oExcel:AddColumn("Notas Fiscais - Globais","Table3","CD_PRODUTOR_IE"		,1,1,)
_oExcel:AddColumn("Notas Fiscais - Globais","Table3","DT_NF"				,1,4,)
_oExcel:AddColumn("Notas Fiscais - Globais","Table3","NR_NF"				,1,1,)
_oExcel:AddColumn("Notas Fiscais - Globais","Table3","CD_SERIE"				,1,1,)
_oExcel:AddColumn("Notas Fiscais - Globais","Table3","CD_CHAVE"				,1,1,)
_oExcel:AddColumn("Notas Fiscais - Globais","Table3","FL_RESPONSABILIDADE"	,1,1,)
_oExcel:AddColumn("Notas Fiscais - Globais","Table3","QT_LITROS"			,3,2,)
_oExcel:AddColumn("Notas Fiscais - Globais","Table3","VR_TOTAL_NF"			,3,2,)
_oExcel:AddColumn("Notas Fiscais - Globais","Table3","VR_MERCADORIA"		,3,2,)
_oExcel:AddColumn("Notas Fiscais - Globais","Table3","VR_FRETE"				,3,2,)
_oExcel:AddColumn("Notas Fiscais - Globais","Table3","VR_BC"				,3,2,)
_oExcel:AddColumn("Notas Fiscais - Globais","Table3","VR_DEDUCOES"			,3,2,)
_oExcel:AddColumn("Notas Fiscais - Globais","Table3","VR_INCENTIVO"			,3,2,)
_oExcel:AddColumn("Notas Fiscais - Globais","Table3","VR_ICMS"				,3,2,)

_cAlias := GetNextAlias()
BeginSql alias _cAlias
	SELECT A2_INSCR, F1_EMISSAO, F1_DOC, F1_SERIE, F1_CHVNFE, 'L' RESPONSABILIDADE, F1_VALBRUT, F1_VALMERC, 
	(SELECT NVL(SUM(Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else ZLF_TOTAL * -1 END), 0) FROM %Table:ZLF%
		WHERE D_E_L_E_T_ = ' '
		AND ZLF_FILIAL = F1_FILIAL
		AND ZLF_CODZLE = ZLE_COD
		AND ZLF_RETIRO = A2_COD
		AND ZLF_RETILJ = A2_LOJA
		AND ZLF_SETOR = F1_L_SETOR
		AND ZLF_LINROT = F1_L_LINHA
		AND ZLF_ENTMIX = 'S'
		AND ZLF_A2COD LIKE 'G%') FRETE, F1_BASEICM, F1_BASEICM
		F1_DESCONT, SUM(D1_VLINCMG) D1_VLINCMG, F1_VALICM,
		(SELECT SUM(ZLD_QTDBOM) FROM %Table:ZLD%
		WHERE D_E_L_E_T_ = ' ' 
		AND ZLD_FILIAL = F1_FILIAL
		AND ZLD_DTCOLE BETWEEN ZLE_DTINI AND ZLE_DTFIM
		AND ZLD_RETIRO = A2_COD
		AND ZLD_RETILJ = A2_LOJA
		AND ZLD_SETOR = F1_L_SETOR
		AND ZLD_LINROT = F1_L_LINHA) VOLUME
	FROM %Table:SF1% SF1, %Table:SD1% SD1, %Table:SA2% SA2, %Table:ZLE% ZLE
	WHERE SF1.D_E_L_E_T_ = ' '
	AND SA2.D_E_L_E_T_ = ' '
	AND SD1.D_E_L_E_T_ = ' '
	AND ZLE.D_E_L_E_T_ = ' '
	AND F1_L_MIX = ZLE_COD
	AND A2_COD = F1_FORNECE
	AND A2_LOJA = F1_LOJA
	AND F1_FILIAL = %xFilial:SF1%
	AND F1_FILIAL = D1_FILIAL
	AND F1_DOC = D1_DOC
	AND F1_SERIE = D1_SERIE
	AND F1_FORNECE = D1_FORNECE
	AND F1_LOJA = D1_LOJA
	AND F1_FORMUL = D1_FORMUL
	AND F1_DTDIGIT BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	AND F1_FORNECE LIKE 'P%'
	AND F1_FORMUL = 'S'
	AND A2_TIPO = 'F'
	GROUP BY F1_FILIAL, A2_INSCR, A2_COD, A2_LOJA, F1_EMISSAO, F1_DOC, F1_SERIE, F1_CHVNFE, F1_VALBRUT, F1_VALMERC, F1_L_SETOR, F1_L_LINHA, F1_DESCONT, F1_VALICM, ZLE_COD, ZLE_DTINI, ZLE_DTFIM, F1_BASEICM
	ORDER BY  A2_INSCR, F1_EMISSAO
EndSql

_oSelf:SetRegua2(2)
_oSelf:IncRegua2("")
//Criando as Linhas
While (_cAlias)->(!Eof())
	_oExcel:AddRow("Notas Fiscais - Globais","Table3",{(_cAlias)->A2_INSCR,;//CD_PRODUTOR_IE
                                          SToD((_cAlias)->F1_EMISSAO),;//DT_NF
                                          (_cAlias)->F1_DOC,;//NR_NF
										  (_cAlias)->F1_SERIE,;//CD_SERIE
										  (_cAlias)->F1_CHVNFE,;//CD_CHAVE
										  (_cAlias)->RESPONSABILIDADE,;//FL_RESPONSABILIDADE
										  (_cAlias)->VOLUME,;//QT_LITROS
										  (_cAlias)->F1_VALBRUT,;//VR_TOTAL_NF
										  (_cAlias)->F1_VALMERC,;//VR_MERCADORIA
										  (_cAlias)->FRETE,;//VR_FRETE
										  (_cAlias)->F1_BASEICM,;//VR_BC
										  (_cAlias)->F1_DESCONT,;//VR_DEDUCOES
										  (_cAlias)->D1_VLINCMG,;//VR_INCENTIVO
										  (_cAlias)->F1_VALICM})//VR_ICMS
	(_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())

//Ativando o arquivo e gerando o xml
_oExcel:Activate()
_oExcel:GetXMLFile(_cArquivo)

_oExcel:DeActivate()

//Abrindo o excel e abrindo o arquivo xml
_oExcel := MsExcel():New() 			//Abre uma nova conexão com Excel
_oExcel:WorkBooks:Open(_cArquivo) 	//Abre uma planilha
_oExcel:SetVisible(.T.) 			//Visualiza a planilha
_oExcel:Destroy()					//Encerra o processo do gerenciador de tarefas

Return
