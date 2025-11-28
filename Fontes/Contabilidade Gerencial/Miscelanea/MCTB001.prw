/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |12/08/2022| Chamado 40932. Corrigido filtro para produtores que emitem a própria nota.
Lucas Borges  |16/08/2022| Chamado 41037. Corrigida query para não considerar pre-notas.
Lucas Borges  |24/08/2022| Chamado 41130. Retirado caracter inserido pelo notebook defeituoso.
==============================================================================================================================
*/

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Programa----------: MCTB001
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 21/06/2017
Descrição---------: Rotina para Contabilizar Fechamento do Leite. Criada rotina para contabilizar os descontos dos produtores 
					de leite apurados na rotina de fechamento. Os créditos geram itens nas notas fiscais, sendo assim, já são 
					contabilizados pelo Compras.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCTB001

Local _oSelf		:= nil
Local _cPerg		:= "MCTB001"

//============================================
//Cria interface principal
//============================================
tNewProcess():New(	"MCTB001"									,; // Função inicial
					"Contabilização Fechamento do Leite"		,; // Descrição da Rotina
					{|_oSelf| MCTB01P(_oSelf, _cPerg) }			,; // Função do processamento
					"Rotina para geração da Contabilização do Fechamento do Leite",; // Descrição da Funcionalidade
					_cPerg										,; // Configuração dos Parâmetros
					{}											,; // Opções adicionais para o painel lateral
					.F.											,; // Define criação do Painel auxiliar
					0											,; // Tamanho do Painel Auxiliar
					''											,; // Descrição do Painel Auxiliar
					.T.											,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
					.F.									 		) // Opção para criação de apenas uma régua de processamento

Return

/*
===============================================================================================================================
Programa----------: MCTB001P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 08/06/2017
Descrição---------: Processa registros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCTB01P(_oSelf, _cPerg)

Local _cAlias	:= "CTBALT"//GetNextAlias()
Local _aArea 	:= FWGetArea()
Local _cArquivo := " "
Local _cLote  	:= AvKey(AllTrim(MV_PAR05),"CT2_LOTE")
Local _nTotal   := 0 
Local _dData	:= MV_PAR04
Local _lDigita  := (MV_PAR01==1)
Local _lAglut	:= (MV_PAR02==1)
Local _cOnLine	:= "N"
Local _cPadrao  := "Z02" //Código do Lançamento Padrão que será utilizado nessa rotina
Local _nHdlPrv, _nX	:= 0 
Local _aSelFil	:= {}
Local _cFilAnt	:= cFilAnt //Salva filial corrente
Local _aFlagCTB := {}
Local _lUsaFlag := GetNewPar("MV_CTBFLAG",.F.)
Local _cThread	:= CValToChar(ThreadID())

_oSelf:SetRegua1(1)
_oSelf:IncRegua1("Buscando registros...")

//Chama função que permitirá a seleção das filiais
If MV_PAR06 == 1
	_aSelFil := AdmGetFil(.F.,.F.,"ZLF")
	If Empty(_aSelFil)
		aAdd(_aSelFil,cFilAnt)
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

_oSelf:SaveLog("Thread:"+_cThread+" Iniciando a rotina. Parâmetros: "+CValToChar(MV_PAR01)+"-"+CValToChar(MV_PAR02)+"-"+DToC(MV_PAR03)+"-"+DToC(MV_PAR04)+"-"+MV_PAR05+"-"+AsString(_aSelFil))
_oSelf:SetRegua1(Len(_aSelFil))

For _nX:=1 to Len(_aSelFil)

	cFilAnt := _aSelFil[_nX]
	_oSelf:SaveLog("Iniciando filial "+ _aSelFil[_nX])
	_oSelf:IncRegua1("Processando Filial: "+cFilAnt)
	
	//Este função cria o cabeçalho da contabilização
	_nHdlPrv:= HeadProva(_cLote,_cPerg,AllTrim(cUserName),@_cArquivo) 
	
	If _nHdlPrv <= 0
	     Help(" ",,1,"A100NOPRV")
	     ProcLogAtu(_cPerg,"A100NOPRV",Ap5GetHelp("A100NOPRV"))
	     Return
	EndIf 
	//Necessária a segunda query para pegar as notas dos produtores que emitem a própria nota. Além de serem várias notas por mix, elas se referem à todos
	//os setore e linha, logo, não é possível fazer a referência 1x1. Ainda não encontrei uma forma de pegar corretamente os casos onde esse tipo de produtor
	//For fechado apenas no mês seguinte. A nota emitida é para o mesmo código mas a loja pode ser diferente por isso não deve ser amarrada.
	//Visto que a nota emitida pelo produtor não tem data para ser emitida, não será feito um filtro de data, pegando todo o passado e não ficando nada sem contabilizar.
	BeginSql Alias _cAlias
		SELECT ZLF.ZLF_FILIAL, ZLF.ZLF_A2COD, ZLF.ZLF_A2LOJA, ZLF.ZLF_SETOR, ZLF.ZLF_LINROT, ZLF.ZLF_DEBCRE, ZLF.ZLF_EVENTO,
				ZLF.ZLF_DTFIM, ZLF.ZLF_L_SEEK, SA2.A2_CONTA, ZL8.ZL8_CONTA, ZLF.R_E_C_N_O_,
				'NF ' || SF1.F1_DOC || ' ' || ZLF.ZLF_A2COD || ' ' || SA2.A2_NOME HISTORICO, ZLF.ZLF_TOTAL
			FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8, %Table:SA2% SA2, %Table:SF1% SF1
		WHERE ZLF.D_E_L_E_T_ = ' '
			AND ZL8.D_E_L_E_T_ = ' '
			AND SA2.D_E_L_E_T_ = ' '
			AND SF1.D_E_L_E_T_ = ' '
			AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
			AND ZLF.ZLF_FILIAL = ZL8.ZL8_FILIAL
			AND ZLF.ZLF_FILIAL = SF1.F1_FILIAL
			AND ZLF.ZLF_EVENTO = ZL8.ZL8_COD
			AND ZLF.ZLF_A2COD = SA2.A2_COD
			AND ZLF.ZLF_A2LOJA = SA2.A2_LOJA
			AND ZLF.ZLF_A2COD = SF1.F1_FORNECE
			AND ZLF.ZLF_A2LOJA = SF1.F1_LOJA
			AND ZLF.ZLF_CODZLE = SF1.F1_L_MIX
			AND ZLF.ZLF_SETOR = SF1.F1_L_SETOR
			AND ZLF.ZLF_LINROT = SF1.F1_L_LINHA
			AND SF1.F1_DTDIGIT BETWEEN %exp:DToS(MV_PAR03)% AND %exp:DToS(MV_PAR04)%
			AND ZLF.ZLF_A2COD LIKE 'P%'
			AND ZLF.ZLF_DEBCRE = 'D'
			AND ZLF.ZLF_TOTAL > 0
			AND ZLF.ZLF_LA <> 'S'
			AND ZLF.ZLF_STATUS = 'F'
			AND ZL8.ZL8_COD NOT IN ('000013','000016','000019')
		UNION
		SELECT ZLF.ZLF_FILIAL, ZLF.ZLF_A2COD, ZLF.ZLF_A2LOJA, ZLF.ZLF_SETOR, ZLF.ZLF_LINROT, ZLF.ZLF_DEBCRE, ZLF.ZLF_EVENTO,
				ZLF.ZLF_DTFIM, ZLF.ZLF_L_SEEK, SA2.A2_CONTA, ZL8.ZL8_CONTA, ZLF.R_E_C_N_O_,
				'NF DIVERSAS' /*|| SF1.F1_DOC */ ||' ' || ZLF.ZLF_A2COD || ' ' || SA2.A2_NOME HISTORICO, ZLF.ZLF_TOTAL
			FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8, %Table:SA2% SA2, %Table:SF1% SF1
		WHERE ZLF.D_E_L_E_T_ = ' '
			AND ZL8.D_E_L_E_T_ = ' '
			AND SA2.D_E_L_E_T_ = ' '
			AND SF1.D_E_L_E_T_ = ' '
			AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
			AND ZLF.ZLF_FILIAL = ZL8.ZL8_FILIAL
			AND ZLF.ZLF_FILIAL = SF1.F1_FILIAL
			AND ZLF.ZLF_EVENTO = ZL8.ZL8_COD
			AND ZLF.ZLF_A2COD = SA2.A2_COD
			AND ZLF.ZLF_A2LOJA = SA2.A2_LOJA
			AND ZLF.ZLF_A2COD = SF1.F1_FORNECE
			AND ZLF.ZLF_CODZLE = SF1.F1_L_MIX
			AND ZLF.ZLF_A2COD LIKE 'P%'
			AND ZLF.ZLF_DEBCRE = 'D'
			AND ZLF.ZLF_TOTAL > 0
			AND ZLF.ZLF_LA <> 'S'
			AND ZLF.ZLF_STATUS = 'F'
			AND SA2.A2_L_NFPRO = 'S'
			AND SF1.F1_STATUS = 'A'
			AND ZL8.ZL8_COD NOT IN ('000013','000016','000019')
			AND SF1.F1_FORMUL <> 'S'
			GROUP BY ZLF.ZLF_FILIAL, ZLF.ZLF_A2COD, ZLF.ZLF_A2LOJA, ZLF.ZLF_SETOR, ZLF.ZLF_LINROT, ZLF.ZLF_DEBCRE, ZLF.ZLF_EVENTO,
				ZLF.ZLF_DTFIM, ZLF.ZLF_L_SEEK, SA2.A2_CONTA, ZL8.ZL8_CONTA, ZLF.R_E_C_N_O_, ZLF.ZLF_TOTAL, SA2.A2_NOME
		ORDER BY ZLF_FILIAL, ZLF_SETOR, ZLF_A2COD
	EndSql
	
	While (_cAlias)->( !Eof() )
		If VerPadrao(_cPadrao)

			If _lUsaFlag
				aAdd(_aFlagCTB,{"ZLF_LA","S","ZLF",(_cAlias)->R_E_C_N_O_,0,0,0})
			EndIf
			
		     //gera linha da contabilização de acordo com as regras do LP passado
	     	_nTotal += DetProva(_nHdlPrv,_cPadrao,_cPerg,_cLote,,,,,,,,@_aFlagCTB,{"ZLF",(_cAlias)->R_E_C_N_O_}) 
			
			//Atualiza Flag de Lançamento Contábil
			If _lUsaFlag
				aFlagCTB := {}  // Limpa o coteudo apos a efetivacao do lancamento
			Else 
				DBSelectArea("ZLF")
				ZLF->(DBGoTo((_cAlias)->R_E_C_N_O_))
				ZLF->(RecLock("ZLF", .F.))
				REPLACE ZLF_LA With "S"
				ZLF->(MSUnLock())
				ZLF->(DBCloseArea())
			EndIf
			
	     EndIf
	     (_cAlias)->( DBSkip() )
	EndDo 
	
	If _nTotal > 0
		//Esta função irá cria a finalização da contabilização.
		RodaProva(_nHdlPrv,_nTotal)
		// Envia para Lancamento Contabil. Essa e a funcao do quadro dos lancamentos.
		cA100Incl(_cArquivo,_nHdlPrv,3,_cLote,_lDigita,_lAglut,_cOnLine,_dData,,@_aFlagCTB)
	EndIf

	(_cAlias)->(DBCloseArea())
	_oSelf:SaveLog("Thread:"+_cThread+" Término filial "+ _aSelFil[_nX])
Next _nX

cFilAnt := _cFilAnt //Restaura filial
_oSelf:SaveLog("Thread:"+_cThread+" Término normal")
FWRestArea(_aArea)
Return
