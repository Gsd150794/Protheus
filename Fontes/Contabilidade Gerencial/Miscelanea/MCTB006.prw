/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |23/12/2024| Chamado 49436. Agrupado os registros por documento para que sejam feitas menos alterações
Lucas Borges  |08/08/2025| Chamado 51702. Incluído tratamento para Item Contábil e Centro de Custo
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MCTB006
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 18/12/2024
Descrição---------: Rotina para alterar lançamentos contábeis com base em CSV separado por vírgula. Chamado 49408
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCTB006

Local _oSelf := Nil As Object

//Cria interface principal
tNewProcess():New('MCTB006'			,; // cFunction. Nome da função que está chamando o objeto
				'Ajusta Lançamentos Contábeis',; // cTitle. Título da árvore de opções
				{|_oSelf| MCTB006P(_oSelf) },; // bProcess. Bloco de execução que será executado ao confirmar a tela
				"Rotina para ajuste das contas de Débito e Crédito nos lançamentos contábeis"+;
				" com base em CSV separado por vírgula",; // cDescription. Descrição da rotina
				'MCTB006'				,; // cPerg. Nome do Pergunte (SX1) a ser utilizado na rotina
				{}						,; // aInfoCustom. Informações adicionais carregada na árvore de opções. Estrutura:[1] - Nome da opção[2] - Bloco de execução[3] - Nome do bitmap[4] - Informações do painel auxiliar.
				.F.						,; // lPanelAux. Se .T. cria um novo painel auxiliar ao executar a rotina
				0						,; // nSizePanelAux. Tamanho do painel auxiliar, utilizado quando lPanelAux = .T.
				''						,; // cDescriAux. Descrição a ser exibida no painel auxiliar
				.F.						,; // lViewExecute. Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento
				.T.						,; // lOneMeter. Se .T. cria apenas uma régua de processamento
				.T.						)  // lSchedAuto. Se .T. habilita o botão de processamento em segundo plano (execução ocorre pelo Scheduler)

Return

/*
===============================================================================================================================
Programa----------: MCTB006P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 18/12/2024
Descrição---------: Realiza o processamento da rotina.
Parametros--------: _oSelf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCTB006P(_oSelf As Object)

Local _oFile	:= Nil As Object
Local _aDados	:= {} As Array
Local _aAux		:= {} As Array
Local _nQtdReg	:= 0 As Numeric
Local _aCab		:= {} As Array
Local _aItens	:= {} As Array
Local _nI		:= 0 As Numeric
Local _cChave	:= '' As Character

Private lMsErroAuto := .F. As Logical
Private lMsHelpAuto := .T. As Logical
Private CTF_LOCK := 0 As Numeric

_oFile	:= FwFileReader():New(MV_PAR01)

If _oFile:Open()
	_aAux := _oFile:GetAllLines() //Acessa todas as Linhas
	//Caso tenha cabeçalho, separo ele
	//Layout do arquivo: DEBITO;CREDITO;CCD;CCC;ITEMD;ITEMC;RECNO;DELETA
	If "DEBITO"$ Upper(_aAux[1])
		ADel(_aAux, 1)
		ASize(_aAux, Len(_aAux) - 1)
	EndIf

	//Separa o Vetor em Nível conforme Token
	AEval(_aAux, {|x| aAdd(_aDados, StrTokArr2(x, ";", .T.))})

	_oFile:Close()
	If Empty(_aDados)
		FWAlertError("O arquivo está vazio! Verifique o arquivo e tente novamente.","MCTB00601")
	ElseIf Len(_aDados[1]) <> 8
		FWAlertError("Layout inválido para o arquivo! Verifique o arquivo e tente novamente.","MCTB00602")
	Else
		DBSelectArea("CT2")
		_nQtdReg := Len(_aDados)
		_oSelf:SetRegua1(_nQtdReg)
		For _nI := 1 To _nQtdReg
			_oSelf:IncRegua1("Lendo registros...["+ StrZero(_nI,6) +"] de ["+ StrZero(_nQtdReg,6) +"]" ) 
			CT2->(DBGoTo(Val(_aDados[_nI][7])))
			If Val(_aDados[_nI][7]) == CT2->(RECNO())
				aAdd(_aDados[_nI],CT2->CT2_DATA)//9
				aAdd(_aDados[_nI],CT2->CT2_LOTE)//10
				aAdd(_aDados[_nI],CT2->CT2_SBLOTE)//11
				aAdd(_aDados[_nI],CT2->CT2_DOC)//12
				aAdd(_aDados[_nI],CT2->CT2_LINHA)//13
				aAdd(_aDados[_nI],CT2->CT2_DEBITO)//14
				aAdd(_aDados[_nI],CT2->CT2_CREDIT)//15
				aAdd(_aDados[_nI],CT2->CT2_CCD)//16
				aAdd(_aDados[_nI],CT2->CT2_CCC)//17
				aAdd(_aDados[_nI],CT2->CT2_ITEMD)//18
				aAdd(_aDados[_nI],CT2->CT2_ITEMC)//19
			Else
				FWAlertError("Não foi encontrado registro na CT2 referente ao Recno "+_aDados[_nI][7]+". Linha ignorada.","MCTB00603")
			EndIf
		Next _nI
		
		aSort(_aDados,,,{|x,y| DToS(x[9])+x[10]+x[11]+x[12]+x[13] < DToS(y[9])+y[10]+y[11]+y[12]+y[13]}) //Ordena itens

		_oSelf:SetRegua1(_nQtdReg)

		For _nI := 1 To _nQtdReg
			_oSelf:IncRegua1("Gravando registros...["+ StrZero(_nI,6) +"] de ["+ StrZero(_nQtdReg,6) +"]" )
			
			If _cChave <> DToS(_aDados[_nI][9])+_aDados[_nI][10]+_aDados[_nI][11]+_aDados[_nI][12]
				_aCab := {}
				_aItens := {}
			
				aAdd(_aCab, {'DDATALANC',_aDados[_nI][09],NIL} )//CT2->CT2_DATA
				aAdd(_aCab, {'CLOTE' 	,_aDados[_nI][10],NIL} )//CT2->CT2_LOTE
				aAdd(_aCab, {'CSUBLOTE' ,_aDados[_nI][11],NIL} )//CT2->CT2_SBLOTE
				aAdd(_aCab, {'CDOC' 	,_aDados[_nI][12],NIL} )//CT2->CT2_DOC
			EndIf
				
			If Upper(_aDados[_nI][8]) $ "DELETA"
				aAdd(_aItens,{{'LINPOS'	,'CT2_LINHA',_aDados[_nI][13]},;//CT2->CT2_LINHA - Necessário para qualquer alteração
							{'AUTDELETA','S'		, NIL			} })//Indica se é para deletar a linha
			Else //Se não For deleção, adiciono indicativo para alteração
				aAdd(_aItens,{{'CT2_DEBITO'	,IIf(Empty(_aDados[_nI][1]),_aDados[_nI][14],_aDados[_nI][1]), NIL},;//CT2->CT2_DEBITO
							{'CT2_CREDIT'	,IIf(Empty(_aDados[_nI][2]),_aDados[_nI][15],_aDados[_nI][2]), NIL},;//CT2->CT2_CREDIT
							{'CT2_CCD'		,IIf(Empty(_aDados[_nI][3]),_aDados[_nI][16],_aDados[_nI][3]), NIL},;//CT2->CT2_CCD
							{'CT2_CCC'		,IIf(Empty(_aDados[_nI][4]),_aDados[_nI][17],_aDados[_nI][4]), NIL},;//CT2->CT2_CCC
							{'CT2_ITEMD'	,IIf(Empty(_aDados[_nI][5]),_aDados[_nI][18],_aDados[_nI][5]), NIL},;//CT2->CT2_ITEMD
							{'CT2_ITEMC'	,IIf(Empty(_aDados[_nI][6]),_aDados[_nI][19],_aDados[_nI][6]), NIL},;//CT2->CT2_ITEMC
							{'LINPOS'		,'CT2_LINHA',_aDados[_nI][13]} } )//CT2->CT2_LINHA
			EndIf
			_cChave := DToS(_aDados[_nI][9])+_aDados[_nI][10]+_aDados[_nI][11]+_aDados[_nI][12]

			//Se a chave For mudar ou se For o último registro, gravo as alterações
			If _nI == _nQtdReg .Or. _cChave <> DToS(_aDados[_nI+1][9])+_aDados[_nI+1][10]+_aDados[_nI+1][11]+_aDados[_nI+1][12]
				lMsErroAuto := .F.
				lMsHelpAuto := .T.

				MSExecAuto({|x, y,z| CTBA102(x,y,z)}, _aCab ,_aItens, 4)

				If lMsErroAuto
					lMsErroAuto := .F.
					MostraErro()
				EndIf
			EndIf
			
		Next _nI
	EndIf
Else
	FWAlertError("O arquivo está vazio ou é inválido para análise! Verifique o arquivo e tente novamente.","MCTB00604")
	Return
EndIf	

Return
