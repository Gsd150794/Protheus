/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
Lucas Borges  |21/03/2025| Chamado 50221. Rotina refeita e ncluído valor no movimento interno
Lucas Borges  |03/04/2025| Chamado 50336. Corrigida a forma de gravação do Custo
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MEST021
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 11/08/2022
Descrição---------: Rotina de geração de movimentação de mão de obra. Chamado 40988
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST021

Local _oSelf as Object

//============================================
//Cria interface principal
//============================================
tNewProcess():New(	"MEST021"							/*cFunction*/	,; //Função inicial
					"Gera Movimento MOD"				/*cTitle*/		,; //Descrição da Rotina
					{|_oSelf| MEST021P(_oSelf) }		/*bProcess*/	,; //Função do processamento
					"Rotina para gerar os movimentos de MODs nas ordens de produção visando atribuir"+;
					" corretamente os custos de produção"/*cDescription*/,; //Descrição da Funcionalidade
					"MEST021"							/*cPerg*/		,; //Configuração dos Parâmetros
					{}									/*aInfoCustom*/	,; //Opções adicionais para o painel lateral
					.F.									/*lPanelAux*/	,; //Define criação do Painel auxiliar
					0									/*nSizePanelAux*/,; //Tamanho do Painel Auxiliar
					''									/*cDescriAux*/	,; //Descrição do Painel Auxiliar
					.F.									/*lViewExecute*/,; //Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
                    .T.                                 /*lOneMeter*/	,; //Se .T. cria apenas uma regua de processamento.
					.F.									/*lSchedAuto*/	)  //Se .T. habilita o botão de processamento em segundo plano (execução ocorre pelo Scheduler)

Return

/*
===============================================================================================================================
Programa----------: MEST021P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 18/12/2024
Descrição---------: Realiza o processamento da rotina.
Parametros--------: _oSelf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST021P(_oSelf as Object)

Local _aArea	:= FWGetArea() as Array
Local _nQtdReg	as Numeric
Local _nI		:= 0 as Numeric
Local _dMvUlMes	:= SuperGetMV("MV_ULMES",.T.,Date()) as Date
Local _dDtIni	:= SToD(SubStr( MV_PAR01 , 3 , 4 ) + SubStr( MV_PAR01 , 1 , 2 ) + '01') as Date
Local _dDtFim	:= LastDay(_dDtIni) as Date
Local _cAlias 	:= GetNextAlias() as String
Local _cUpdate	:= "" as String
Local _lRet		:= .T. as Logical
Local _aStruct	:= {} as Array
Local _oBulk	as Object
Local _nRound	:= GetSX3Cache("D3_CUSTO1","X3_DECIMAL") as Number
Local _nRndQtd	:= GetSX3Cache("D3_QUANT","X3_DECIMAL") as Number
Local _nTamPrd	:= GetSX3Cache("D3_COD","X3_TAMANHO") as Number
Local _cProd	:= "" as String
Local _cProdOld := "" as String

If _dMvUlMes < _dDtIni
	_oSelf:SetRegua1(2)
	_oSelf:IncRegua1("Exclindo movimentos anteriores...")
	_cUpdate 	:= "UPDATE "+RetSQLName("SD3") + " SD3  SET SD3.D_E_L_E_T_ = '*'"
	_cUpdate	+= " WHERE SD3.D_E_L_E_T_ = ' ' "
	_cUpdate	+= "   AND D3_GRUPO IN ('MOD','GGF','DEP')
	_cUpdate	+= "   AND D3_FILIAL = '" + xFilial("SD3") + "' "
	_cUpdate	+= "   AND D3_EMISSAO BETWEEN '"+DToS(_dDtIni)+"' AND '"+DToS(_dDtFim)+"' "
	If TCSqlExec( _cUpdate ) < 0
		FWAlertError("Erro na exclusão dos movimentos. Favor acionar a TI. Erro: "+AllTrim(TCSQLError()),"MEST001001")
	Else
		_oSelf:SetRegua1(2)
		_oSelf:IncRegua1("Consultando registros no Banco de Dados")
		aAdd( _aStruct, {'D3_FILIAL'})
		aAdd( _aStruct, {'D3_TM'})
		aAdd( _aStruct, {'D3_EMISSAO'})
		aAdd( _aStruct, {'D3_COD'})
		aAdd( _aStruct, {'D3_CC'})
		aAdd( _aStruct, {'D3_LOCAL'})
		aAdd( _aStruct, {'D3_QUANT'})
		aAdd( _aStruct, {'D3_CUSTO1'})
		aAdd( _aStruct, {'D3_CUSTO3'})
		aAdd( _aStruct, {'D3_I_OBS'})
		aAdd( _aStruct, {'D3_OP'})
		aAdd( _aStruct, {'D3_CF'})
		aAdd( _aStruct, {'D3_DOC'})
		aAdd( _aStruct, {'D3_NUMSEQ'})
		aAdd( _aStruct, {'D3_USUARIO'})
		aAdd( _aStruct, {'D3_CHAVE'})
		aAdd( _aStruct, {'D3_IDENT'})
		aAdd( _aStruct, {'D3_UM'})
		aAdd( _aStruct, {'D3_GRUPO'})
		aAdd( _aStruct, {'D3_TIPO'})

		BeginSql alias _cAlias
			SELECT D3_FILIAL, D3_OP, D3_TM, D3_COD, D3_LOCAL, D3_QUANT, D3_EMISSAO, D3_DOC, D3_NUMSEQ, D3_USUARIO, D3_IDENT, D3_CC, 
			PBZ_CUSTO, PBZ_CONVER, B1_GRUPO, B1_UM, B1_TIPO,
				(SELECT SUM(D3_QUANT*PBZ_CONVER)
					FROM %Table:SD3% D3, %Table:PBZ% BZ
					WHERE D3.D_E_L_E_T_ = ' '
					AND BZ.D_E_L_E_T_ = ' '
					AND D3.D3_FILIAL = %xFilial:SD3%
					AND BZ.PBZ_CODIGO = D3.D3_COD
					AND BZ.PBZ_CUSTO = PBZ.PBZ_CUSTO
					AND D3.D3_CF = 'PR0'
					AND D3.D3_ESTORNO <> 'S'
					AND D3.D3_EMISSAO BETWEEN %exp:_dDtIni% AND %exp:_dDtFim%) QTD,
					NVL((SELECT SUM(CT2_VALOR) *-1
					FROM %Table:CTT% CTT, %Table:CTT% S,
						(SELECT CT1_I_UNIF,
								CT2_CCD CCUSTO,
								SUM(CT2_VALOR) * -1 CT2_VALOR
							FROM %Table:CT2% CT2, %Table:CT1% CT1
							WHERE CT2.D_E_L_E_T_ = ' '
							AND CT1.D_E_L_E_T_ = ' '
							AND CT1_CONTA = CT2_DEBITO
							AND CT1_I_UNIF <> 'NAO'
							AND CT2_FILORI = %xFilial:SD3%
							AND CT2_DATA BETWEEN %exp:_dDtIni% AND %exp:_dDtFim%
							AND CT2_DEBITO BETWEEN '3299' AND '3299ZZZZZZ'
							GROUP BY CT1_I_UNIF, CT2_CCD
							UNION
							SELECT CT1_I_UNIF, CT2_CCC CCUSTO, SUM(CT2_VALOR) CT2_VALOR
							FROM %Table:CT2% CT2, %Table:CT1% CT1
							WHERE CT2.D_E_L_E_T_ = ' '
							AND CT1.D_E_L_E_T_ = ' '
							AND CT1_CONTA = CT2_CREDIT
							AND CT1_I_UNIF <> 'NAO'
							AND CT2_FILORI = %xFilial:SD3%
							AND CT2_DATA BETWEEN %exp:_dDtIni% AND %exp:_dDtFim%
							AND CT2_CREDIT BETWEEN '3299' AND '3299ZZZZZZ'
							GROUP BY CT1_I_UNIF, CT2_CCC) MOV
					WHERE CTT.D_E_L_E_T_ = ' '
					AND S.D_E_L_E_T_ = ' '
					AND S.CTT_DESC01 = CT1_I_UNIF || CTT.CTT_I_UNIF
					AND MOV.CCUSTO = CTT.CTT_CUSTO
					AND S.CTT_CUSTO = PBZ.PBZ_CUSTO
					GROUP BY CT1_I_UNIF, S.CTT_CUSTO, S.CTT_DESC01),0) CT2_VALOR
			FROM %Table:SD3% SD3, %Table:PBZ% PBZ, %Table:SB1% SB1
			WHERE SD3.D_E_L_E_T_ = ' '
			AND PBZ.D_E_L_E_T_ = ' '
			AND SB1.D_E_L_E_T_ = ' '
			AND SB1.B1_FILIAL = %xFilial:SB1%
			AND SB1.B1_COD = 'MOD'||PBZ_CUSTO
			AND D3_FILIAL = %xFilial:SD3%
			AND D3_CF = 'PR0'
			AND D3_ESTORNO <> 'S'
			AND D3_EMISSAO BETWEEN %exp:_dDtIni% AND %exp:_dDtFim%
			AND PBZ_FILIAL = %xFilial:PBZ%
			AND PBZ_CODIGO = D3_COD
			AND PBZ_CONVER > 0
		EndSql
		COUNT TO _nQtdReg
		(_cAlias)->( DBGoTop() )
		_oSelf:SetRegua1(_nQtdReg)
		_oBulk := FwBulk():New(RetSQLName("SD3"))
		_oBulk:SetFields(_aStruct)

		While (_cAlias)->(!Eof()) .And. _lRet
			_nI++
			_oSelf:IncRegua1("Processando...["+ StrZero(_nI,6) +"] de ["+ StrZero(_nQtdReg,6) +"]" )
			_cProd := PadR(AllTrim('MOD'+(_cAlias)->PBZ_CUSTO),_nTamPrd)
			_nCusto := Round((_cAlias)->D3_QUANT*(_cAlias)->PBZ_CONVER * ((_cAlias)->CT2_VALOR / ((_cAlias)->QTD*(_cAlias)->PBZ_CONVER)),_nRound)
			_oBulk:AddData({(_cAlias)->D3_FILIAL,;//D3_FILIAL
							"999",;//SD3->D3_TM
							SToD((_cAlias)->D3_EMISSAO),;//D3_EMISSAO
							'MOD'+(_cAlias)->PBZ_CUSTO,;//D3_COD
							(_cAlias)->PBZ_CUSTO,;//D3_CC
							'00',;//D3_LOCAL
							Round((_cAlias)->D3_QUANT*(_cAlias)->PBZ_CONVER,_nRndQtd),;//D3_QUANT
							Round(((_cAlias)->D3_QUANT*(_cAlias)->PBZ_CONVER) * ((_cAlias)->CT2_VALOR / (_cAlias)->QTD),_nRound),;//D3_CUSTO1
							Round(((_cAlias)->D3_QUANT*(_cAlias)->PBZ_CONVER) * ((_cAlias)->CT2_VALOR / (_cAlias)->QTD),_nRound),;//D3_CUSTO3
							"MEST021",;//D3_I_OBS
							(_cAlias)->D3_OP,;//D3_OP
							"RE1",;//D3_CF
							(_cAlias)->D3_DOC,;//D3_DOC
							(_cAlias)->D3_NUMSEQ,;//D3_NUMSEQ
							cUserName,;//D3_USUARIO
							"E0",;//D3_CHAVE
							(_cAlias)->D3_IDENT,;//D3_IDENT
							(_cAlias)->B1_UM,;//D3_UM
							(_cAlias)->B1_GRUPO,;//D3_GRUPO
							(_cAlias)->B1_TIPO;//D3_TIPO
							})
			If _cProdOld <> _cProd 
				If SB2->(DBSeek((_cAlias)->(D3_FILIAL)+_cProd+"00"))
					SB2->(RecLock("SB2",.F.))
					SB2->B2_CM1 := Round((_cAlias)->CT2_VALOR / (_cAlias)->QTD,_nRound)
					SB2->B2_CM3 := Round((_cAlias)->CT2_VALOR / (_cAlias)->QTD,_nRound)
					SB2->(MSUnLock())
				Else
					FWAlertError("Erro ao posicionar no produto na SB2. Chave: "+(_cAlias)->(D3_FILIAL)+'MOD'+(_cAlias)->PBZ_CUSTO+"00","MEST02106")
				EndIf
				_cProdOld := _cProd
			EndIf
			(_cAlias)->(DBSkip())
		EndDo)

		If !_oBulk:Close()
			FWAlertError("Erro ao realizar o flush dos registros no banco de dados. Erro: "+ CRLF + _oBulk:GetError(), ,"MEST02104")
		EndIf
		_oBulk:Destroy()
		_oBulk:= Nil
		(_cAlias)->(DBCloseArea())
	EndIf
Else
	FWAlertError("A data do último fechamento (MV_ULMES  - "+DToC(_dMvulMes)+" ) não pode ser menor que a data inicial "+;
	"de processamento: "+DToC(_dDtIni)+". Informe um período válido.","MEST02105")
EndIf	

FWRestArea(_aArea)

Return
