/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |16/01/2023| Chamado 42553. Inclusão de novas informações no layout UPF
Lucas Borges  |12/01/2024| Chamado 46061. Incluído A2_EST no layout UPF
Lucas Borges  |04/06/2025| Chamado 50617. Corrgida a exportação do arquivo usando ProtheusWeb
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGLT005
Autor-------------: Wodson Reis
Data da Criacao---: 03/10/2008
Descrição---------: Exportação dos dados do Retiro e dos Tanques para importação no Sistema LQL.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT005

Local _cPerg := "MGLT005" As Character
Local _oSelf := nil As Object

//Cria interface principal
tNewProcess():New(	_cPerg						,; // cFunction. Nome da função que está chamando o objeto
					"Exporta Movimento LQL/UPF"		,; // cTitle. Título da árvore de opções
					{|_oSelf| MGLT005P(_oSelf) },; // bProcess. Bloco de execução que será executado ao confirmar a tela
					"Este programa irá gerar um arquivo CSV, para ser importado no programa LQL ou UPF. "+;
					"O programa LQL é utilizado para impressão das etiquetas, coladas nos tubos de ensaio "+;
					"enviados  para análise do Leite entregue pelos produtores.",; // cDescription. Descrição da rotina
					_cPerg						,; // cPerg. Nome do Pergunte (SX1) a ser utilizado na rotina
					{}							,; // aInfoCustom. Informações adicionais carregada na árvore de opções. Estrutura:[1] - Nome da opção[2] - Bloco de execução[3] - Nome do bitmap[4] - Informações do painel auxiliar.
					.F.							,; // lPanelAux. Se .T. cria um novo painel auxiliar ao executar a rotina
					0							,; // nSizePanelAux. Tamanho do painel auxiliar, utilizado quando lPanelAux = .T.
					''							,; // cDescriAux. Descrição a ser exibida no painel auxiliar
					.T.							,; // lViewExecute. Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento
					.T.							,; // lOneMeter. Se .T. cria apenas uma régua de processamento
					.T.							)  // lSchedAuto. Se .T. habilita o botão de processamento em segundo plano (execução ocorre pelo Scheduler)

Return

/*
===============================================================================================================================
Programa----------: MGLT005P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 09/01/2019
Descrição---------: Realiza o processamento da rotina.
Parametros--------: _oSelf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT005P(_oSelf As Object)

Local _cTabela		:= " " As Character
Local _cFiltro		:= "%" As Character
Local _cAlias		:= GetNextAlias() As Character
Local _nCountRec	:= 0 As Numeric
Local _cAux			:= IIf( MV_PAR09 == 1 , "ZLD" , "ZLW" ) As Character
Local _dFMesAnt		:= CToD('//') As Date
Local _cFMesAnt		:= '' As Character
Local _nVol			:= 0 As Numeric
Local _cBuffer		:= '' As Character
Local _oFile		:= Nil As Object
Local _cDrive		:= '' As Character
Local _cDir			:= '' As Character
Local _cNome		:= '' As Character
Local _cExt			:= '' As Character

SplitPath(AllTrim(MV_PAR03), @_cDrive, @_cDir, @_cNome, @_cExt )
_oFile:= FWFileWriter():New(__RelDir+_cNome+_cExt)

If !_oFile:Create()
	FWAlertError("Erro ao criar aqruivo. A rotina não será executada!", "MGLT00501")
	Return
EndIf

//================================================================================
//| Define oabecalho de acordo com o tipo do relatorio escolhido 1 - LQL 2 - UPF |
//================================================================================
If MV_PAR08 == 1
	_cBuffer+= "NOME DO PRODUTOR;CEP MUNICIPIO;CPF/CNPJ;COD. PROD. INDUST;FILTRO;ORIGEM;OBSERVACOES;NRP SIGSIF;DATA_REF;PRODUCAO MENSAL"+ CRLF
ElseIf MV_PAR08 == 2
	_cBuffer+= "NOME DO PRODUTOR;ENDERECO;CIDADE;CEP;ESTADO;CPF/CNPJ;MATRICULA PROD. EMPRESA;PRODUCAO MENSAL;CODIGO PROD. MINISTERIO;NIRF;ROTA;LATITUDE;LONGITUDE;MES REF;INSCRICAO ESTADUAL"+ CRLF
Else
	_cBuffer+= "CODIGO;NOME;LINHA;NRP;CPF/CNPJ;ESTADO;LATITUDE;LONGITUDE;REGIONAL"+ CRLF
EndIf

_oSelf:SetRegua1(2)
_oSelf:IncRegua1("Buscando produtores...")

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cTabela := "%" + RetSqlName(_cAux) +" "+ _cAux + " %"
_cFiltro += " AND "+ _cAux +".D_E_L_E_T_ = ' '"
_cFiltro += " AND "+ _cAux +"_SETOR = ZL2.ZL2_COD"
_cFiltro += " AND "+ _cAux +"_LINROT = ZL3.ZL3_COD"
_cFiltro += " AND "+ _cAux +"_DTCOLE	BETWEEN '"+ DToS(MV_PAR01) +"' AND '"+ DToS(MV_PAR02) +"' "
_cFiltro += " AND "+ _cAux +"_FILIAL	= '"+ xFilial(_cAux)+"' "
//Se preencheu os setores, já fiz a validação de acesso no SX1
//Se não preencheu e não tem acesso a todos, filtra de forma que não retorme registros
If !Empty(MV_PAR04) .Or. Empty(MV_PAR04) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") <> 'S'
	_cFiltro += " AND "+ _cAux +"_SETOR	IN "+ FormatIn( AllTrim(MV_PAR04) , ';' )
EndIf
_cFiltro += " AND "+ _cAux +"_LINROT	BETWEEN '"+ MV_PAR05 +"' AND '"+ MV_PAR06 +"' "
_cFiltro += " AND "+ _cAux +"_RETIRO = A2.A2_COD"
_cFiltro += " AND "+ _cAux +"_RETILJ = A2.A2_LOJA"

//================================================================================
// Somente Donos de Tanque?                                                     |
//================================================================================
If MV_PAR07 == 1
	_cFiltro += " AND A2_COD = A2_L_TANQ AND A2_LOJA = A2_L_TANLJ "
EndIf

_cFiltro += "%"
//====================================================================================================
// SQL para verificar os produtores dos Setores que movimentaram entrada de leite no periodo
//====================================================================================================
BeginSql Alias _cAlias
SELECT A2.A2_COD, A2.A2_LOJA, A2.A2_NOME, A2.A2_CGC, A2.A2_L_TIPPR, A2.A2_L_NIRF, A2.A2_L_SIGSI, A2.A2_END, A2.A2_MUN, A2.A2_CEP, A2.A2_EST,
		A2.A2_L_ATIVO, A2.A2_L_TIPPR, ZL3.ZL3_COD, ZL3.ZL3_DESCRI, ZL2.ZL2_COD, ZL2.ZL2_DESCRI, A2_L_LONGI, A2_L_LATIT, A2_EST, A2_INSCR,
		Case 
			WHEN A2.A2_L_CLASS = 'I' THEN 'Tanque Individual'
			WHEN A2.A2_L_CLASS IN('C','U') THEN 'Tanque Coletivo'
			WHEN A2.A2_L_CLASS = 'N' THEN 'Latao'
			WHEN A2.A2_L_CLASS = 'F' THEN 'Familiar'
		END CLASSIF
  FROM %Table:SA2% A2, %Table:ZL3% ZL3, %Table:ZL2% ZL2, %exp:_cTabela%
 WHERE A2.D_E_L_E_T_ = ' '
   AND ZL3.D_E_L_E_T_ = ' '
   AND ZL2.D_E_L_E_T_ = ' '
   AND A2.A2_FILIAL = %xFilial:SA2%
   AND ZL3.ZL3_FILIAL = %xFilial:ZL3%
   AND ZL2.ZL2_FILIAL = %xFilial:ZL2%
   AND A2.A2_COD LIKE 'P%'
   AND A2_MSBLQL <> '1'
   %exp:_cFiltro%
 GROUP BY A2.A2_COD, A2.A2_LOJA, A2.A2_NOME, A2.A2_CGC, A2.A2_L_TIPPR, A2.A2_L_NIRF, A2.A2_L_SIGSI, A2.A2_END, A2.A2_MUN, A2.A2_CEP, A2.A2_EST,
 		A2.A2_L_ATIVO, A2.A2_L_TIPPR, A2.A2_L_CLASS, ZL3.ZL3_COD, ZL3.ZL3_DESCRI, ZL2.ZL2_COD, ZL2.ZL2_DESCRI, A2_L_LONGI, A2_L_LATIT, A2_EST, A2_INSCR
 ORDER BY ZL3.ZL3_DESCRI, A2.A2_NOME
EndSql

Count To _nCountRec
(_cAlias)->( DBGoTop() )
_oSelf:SetRegua1(_nCountRec)
_oSelf:IncRegua1("Gerando arquivo...")

If MV_PAR10 == 1	
	_dFMesAnt	:= FirstDay(MV_PAR01) - 1
Else
	_dFMesAnt	:= FirstDay(MV_PAR01)
EndIf

_cFMesAnt	:= MesExtenso( Month(_dFMesAnt) ) +"/"+ StrZero( Year(_dFMesAnt) , 4 )

//====================================================================================================
// Processa registros encontrados
//====================================================================================================
If _nCountRec > 0
	While (_cAlias)->(!Eof())
		//================================================================================
		//| Exporta somente produtores ativos  se considera apenas ativos                |
		//================================================================================
		If MV_PAR10 == 2
			If (_cAlias)->A2_L_ATIVO <> "S"
				(_cAlias)->(DBSkip())
				Loop
			Else
				If MV_PAR09 == 1
					If !((_cAlias)->A2_L_TIPPR $ "P|A")
						(_cAlias)->(DBSkip())
						Loop
					EndIf
				ElseIf MV_PAR09 == 2
					If !((_cAlias)->A2_L_TIPPR $ "C|A")
						(_cAlias)->(DBSkip())
						Loop
					EndIf
				EndIf
			EndIf
		EndIf

		_nVol := U_VolLeite( xFilial(_cAux) , FirstDay(_dFMesAnt) , LastDay(_dFMesAnt) , (_cAlias)->ZL2_COD ,, (_cAlias)->A2_COD , (_cAlias)->A2_LOJA ,, MV_PAR09, MV_PAR11 )
		If _nVol == 0
			_nVol++
		EndIf
		//================================================================================
		//| Define os dados para o tipo de relatorio LQL                                 |
		//================================================================================
		If MV_PAR08 == 1
			
			_cBuffer+= AllTrim((_cAlias)->A2_NOME)+";"
			_cBuffer += (_cAlias)->A2_CEP+";"
			_cBuffer += (_cAlias)->A2_CGC+";"
			_cBuffer += (_cAlias)->A2_COD +'-'+ (_cAlias)->A2_LOJA+";"
			_cBuffer += (_cAlias)->ZL3_COD +'-'+ AllTrim(SubStr((_cAlias)->ZL3_DESCRI,1,30))+";"
			_cBuffer += (_cAlias)->CLASSIF+";"
			_cBuffer += AllTrim((_cAlias)->ZL2_DESCRI)+";"
			_cBuffer += AllTrim((_cAlias)->A2_L_SIGSI)+";"
			_cBuffer += AllTrim(_cFMesAnt)+";"
			_cBuffer += Str( _nVol )+";" + CRLF
		
		//================================================================================
		//Define os dados para o tipo de relatorio UPF
		//================================================================================
		ElseIf MV_PAR08 == 2

			_cBuffer += AllTrim((_cAlias)->A2_NOME)+";"
			_cBuffer += AllTrim((_cAlias)->A2_END)+";"
			_cBuffer += SubStr(AllTrim((_cAlias)->A2_MUN), 1 , 20 )+";"
			_cBuffer += (_cAlias)->A2_CEP+";"
			_cBuffer += (_cAlias)->A2_EST+";"
			_cBuffer += (_cAlias)->A2_CGC+";"
			_cBuffer += (_cAlias)->A2_COD +'-'+ (_cAlias)->A2_LOJA+";"
			_cBuffer += Str(_nVol)+";"
			_cBuffer += IIf(Empty((_cAlias)->A2_L_SIGSI),'-',(_cAlias)->A2_L_SIGSI)+";"
			_cBuffer += IIf(Empty((_cAlias)->A2_L_NIRF),'-',(_cAlias)->A2_L_NIRF)+";"
			_cBuffer += (_cAlias)->ZL3_COD +'-'+ AllTrim(SubStr((_cAlias)->ZL3_DESCRI,1,30))+";"
			_cBuffer += StrTran(Str((_cAlias)->A2_L_LATIT),'.',',')+";"
			_cBuffer += StrTran(Str((_cAlias)->A2_L_LONGI),'.',',')+";"
			_cBuffer += Str(Month(_dFMesAnt))+";"
			_cBuffer += (_cAlias)->A2_INSCR+";"+CRLF
		Else
			//================================================================================
			//Define os dados para o tipo de relatorio Clinica do Leite
			//================================================================================
			_cBuffer += (_cAlias)->A2_COD +'-'+ (_cAlias)->A2_LOJA+";"
			_cBuffer += AllTrim((_cAlias)->A2_NOME)+";"
			_cBuffer += (_cAlias)->ZL3_COD +'-'+ AllTrim(SubStr((_cAlias)->ZL3_DESCRI,1,30))+";"
			_cBuffer += AllTrim((_cAlias)->A2_L_SIGSI)+";"
			_cBuffer += (_cAlias)->A2_CGC+";"
			_cBuffer += (_cAlias)->A2_EST+";"
			_cBuffer += Str((_cAlias)->A2_L_LATIT)+";"
			_cBuffer += Str((_cAlias)->A2_L_LONGI)+";"
			_cBuffer += AllTrim((_cAlias)->ZL2_DESCRI)+";"+ CRLF
		EndIf
			
		(_cAlias)->( DBSkip() )
	EndDo
	(_cAlias)->( DBCloseArea() )
	
	//Grava linha no arquivo
	_oFile:Write(_cBuffer)
Else
	FWAlertWarning("Não foram encontrados registros para processar com os filtros informados! Verifique os parâmetros digitados.","MGLT00502")
	Return
EndIf

_oFile:Close()
If GetRemoteType() == 5 //SmartClient HTML sem WebAgent
	CpyS2TW(__RelDir+_cNome+_cExt)  // Copia o arquivo para o Browse de navegação Web do usuário
Else	
	CpyS2T(__RelDir+_cNome+_cExt,_cDrive+_cDir)
EndIf
_oFile:Erase()
_oFile:= Nil

Return
