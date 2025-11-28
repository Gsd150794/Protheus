/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |10/07/2024| Chamado 47820. Incluída exportação para planilha.
Lucas Borges  |01/10/2025| Chamado 52143. Incluido filtro para fornecedore Centro Leite
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGLT008
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 19/12/2023
Descrição---------: Fechamento de terceiros (RGLT020) por e-mail. Chamado 45906
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT008

Local _cPerg	:= "MGLT008" As Character
Local _oSelf	:= Nil As Object

//============================================
//Cria interface principal
//============================================
tNewProcess():New(	_cPerg											,; // Função inicial
					"Envio do Fechamento de Terceiros - RGLT020 por e-mail"		,; // Descrição da Rotina
					{|_oSelf| MGLT008P(_oSelf,_cPerg) }					,; // Função do processamento
					"Este programa irá enviar por e-mail o Fechamento de terceiros individualmente para cada transportador.",; // Descrição da Funcionalidade
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
Programa----------: MGLT008P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 19/12/2023
Descrição---------: Realiza o processamento da rotina.
Parametros--------: _oSelf, _cPerg
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT008P(_oSelf As Object,_cPerg As Character)

Local _cAlias 	:= GetNextAlias() As Character
Local _cReplyTo	:= AllTrim(MV_PAR13) As Character
Local _cFrom	:= Lower(FWSFAllUsers({RetCodUsr()})[1][5]) As Character//retorna o e-mail do usuário
Local _cAssunto	:= "" As Character
Local _cMensagem:= "" As Character
Local _aAttach 	:= {} As Array
Local _cDtIni 	:= "" As Character
Local _cDtFim 	:= "" As Character
Local _cFiltro	:= "%" As Character
Local _lJob 	:= .T. As Logical
Local _aPergunte:= {} As Array
Local _nX 		:= 1 As Numeric
Local _nCountRec:= 0 As Numeric
Local _cDirPlan := "" As Character
Local _lEnvMail := .F. As Logical

For _nX := 1 To 12//Tamanho do pergunte do RGLT020
	aAdd(_aPergunte, &("MV_PAR"+StrZero(_nX,2,0)))
Next _nX

_oSelf:SetRegua1(1)
_oSelf:IncRegua1("Buscando registros no banco de dados...")

If MV_PAR01 == 1
	_cDtIni := SubStr( MV_PAR02 , 3 , 4 ) + SubStr( MV_PAR02 , 1 , 2 ) + '01'
	_cDtFim := SubStr( MV_PAR02 , 3 , 4 ) + SubStr( MV_PAR02 , 1 , 2 ) + '15'
Else
	_cDtIni := SubStr( MV_PAR02 , 3 , 4 ) + SubStr( MV_PAR02 , 1 , 2 ) + '16'
	_cDtFim := DToS( LastDay( SToD( SubStr( MV_PAR02 , 3 , 4 ) + SubStr( MV_PAR02 , 1 , 2 ) + '01' ) ) )
EndIf


_cFiltro += IIf( MV_PAR03 == 1 , " AND SC7.C7_FORNECE  = 'F00001' ", "" )
_cFiltro += IIf( MV_PAR03 == 2 , " AND SC7.C7_FORNECE <> 'F00001' AND SubStr(SC7.C7_FORNECE,1,1) <> 'Z' ", "" )
_cFiltro += IIf( MV_PAR03 == 3 , " AND SubStr(SC7.C7_FORNECE,1,1) = 'Z' ", "" )
_cFiltro += IIf( !Empty(MV_PAR04) , " AND ZA7.ZA7_TIPPRD IN "+ FormatIn( MV_PAR04 , ';' ), "" )
//Centro Leite
If MV_PAR11 == 1
	_cFiltro += " AND A2_L_CENTR = '1' "
ElseIf MV_PAR11 == 2
	_cFiltro += " AND A2_L_CENTR = '2' "
EndIf
_cFiltro += "%"

BeginSql alias _cAlias
SELECT A2_COD, A2_LOJA, A2_EMAIL, A2_NOME
          FROM %Table:SC7% SC7, %Table:ZA7% ZA7, %Table:SD1% SD1, %Table:ZLX% ZLX, %Table:SA2% SA2, %Table:ZZX% ZZX
         WHERE SC7.D_E_L_E_T_ = ' '
           AND ZA7.D_E_L_E_T_ = ' '
           AND SD1.D_E_L_E_T_ = ' '
           AND ZLX.D_E_L_E_T_ = ' '
		   AND SA2.D_E_L_E_T_ = ' '
           AND SC7.C7_FILIAL = %xFilial:SC7%
           AND ZA7.ZA7_FILIAL = %xFilial:ZA7%
           AND SD1.D1_FILIAL = %xFilial:SD1%
           AND ZLX.ZLX_FILIAL = %xFilial:ZLX%
		   AND ZA7.ZA7_FILIAL = ZZX.ZZX_FILIAL
           AND ZA7_TIPPRD = ZZX.ZZX_CODPRD
           AND ZA7.ZA7_CODPRD = ZLX_PRODLT
           AND ZZX_CODIGO = ZLX.ZLX_CODANA
           AND SD1.D1_FILIAL = ZLX.ZLX_FILIAL
           AND SD1.D1_FILIAL = ZLX.ZLX_FILIAL
		   AND SA2.A2_COD = SC7.C7_FORNECE
		   AND SA2.A2_LOJA = SC7.C7_LOJA
           %exp:_cFiltro%
           AND SC7.C7_EMISSAO BETWEEN %exp:_cDtIni% AND %exp:_cDtFim%
           AND SC7.C7_FORNECE BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR07%
           AND SC7.C7_LOJA BETWEEN %exp:MV_PAR06% AND %exp:MV_PAR08%
           AND D1_FORNECE = SC7.C7_FORNECE
           AND D1_LOJA = SC7.C7_LOJA
           AND D1_PEDIDO = SC7.C7_NUM
           AND D1_COD = SC7.C7_PRODUTO
           AND ZLX_FORNEC = SC7.C7_FORNECE
           AND ZLX_LJFORN = SC7.C7_LOJA
           AND ZLX_PRODLT = SC7.C7_PRODUTO
           AND ZLX_NRONF = D1_DOC
           AND ZLX_SERINF = D1_SERIE
         GROUP BY A2_COD, A2_LOJA,A2_EMAIL, A2_NOME
		 ORDER BY A2_COD, A2_LOJA
EndSql

Count To _nCountRec
(_cAlias)->( DBGoTop() )

_oSelf:SetRegua1(_nCountRec)
_oSelf:IncRegua1("Processando fornecedor "+(_cAlias)->A2_COD+"\"+(_cAlias)->A2_LOJA)
//Criando as Linhas
While (_cAlias)->(!Eof())
	_aAttach := {}
	_aPergunte[5] := (_cAlias)->A2_COD
	_aPergunte[7] := (_cAlias)->A2_COD
	_aPergunte[6] := (_cAlias)->A2_LOJA
	_aPergunte[8] := (_cAlias)->A2_LOJA

	_cErro := ""
	_cAssunto := "Fechamento da "+If(MV_PAR01==1,"1ª","2ª")+ " quinzena de "+MesExtenso(SToD(_cDtIni))+" "+SubStr(MV_PAR02,3,4)+" - "+AllTrim((_cAlias)->A2_NOME)
	_cMensagem := "<HTML><HEAD></HEAD><BODY><Font face='arial' Style='font-size:14px'>"
	_cMensagem += "O fechamento da "+If(MV_PAR01==1,"1ª","2ª")+ " quinzena de "+MesExtenso(SToD(_cDtIni))+" "+SubStr(MV_PAR02,3,4)+" está anexo.<br>"
	_cMensagem += "    Favor emitir e nos enviar as notas fiscais complementares, se houver.<br>"
	_cMensagem += "    Essas notas devem ser enviadas respondendo este e-mail, até o dia "+AllTrim(Str(Day(DaySum(Date(),5))))+" de "+MesExtenso(DaySum(Date(),5))+ ", para evitarmos transtornos para ambas as partes.<br><br>"
	_cMensagem += "  *Os complementos que não forem enviados respondendo este e-mail, estão sujeitos a serem pagos no dia 10 do mês seguinte.<br><br>"
	_cMensagem += "    As notas que não forem emitidas no padrão abaixo serão recusadas/devolvidas.<br><br><br>"
	_cMensagem += "·        Natureza da operação – nota fiscal complementar;<br><br>"
	_cMensagem += "·        Para notas fiscais complementares de valor – Volume igual a 0 (zero);<br><br>"
	_cMensagem += "·        Referenciar o xml de uma NF de origem, emitida durante a quinzena que está sendo acertada. (Não basta descrever a NF de referência no campo informações complementares, é necessário amarrar o xml da NF de origem ao xml da NF complementar de valor que está sendo emitida).<br><br>"
	_cMensagem += "    * A referência do mês e quinzena deve ser incluída no campo das 'informações complementares' indicando , ao menos , uma nota de origem.<br>"
	_cMensagem += "            (exemplo 1: Nota fiscal complementar de litragem referente a "+If(MV_PAR01==1,"1ª","2ª")+ " quinzena de "+If(MV_PAR01==1,MesExtenso(SToD(_cDtIni),1),MesExtenso(MonthSum(SToD(_cDtIni),1)))+ " "+SubStr(MV_PAR02,3,4)+" ref.  Nfs: 000.000 , 000.000 , 000.000).<br>"
	_cMensagem += "               (exemplo 2: Nota fiscal complementar de valor referente a "+If(MV_PAR01==1,"1ª","2ª")+ " quinzena de "+If(MV_PAR01==1,MesExtenso(SToD(_cDtIni),1),MesExtenso(MonthSum(SToD(_cDtIni),1)))+ " "+SubStr(MV_PAR02,3,4)+" ref.  Nfs: 000.000 , 000.000 , 000.000).<br>"
	
	_cMensagem += "</Font></BODY></HTML>"
	If MV_PAR14 == 1
		_lEnvMail := .T.
	EndIf
	If MV_PAR12 <> 2
		_cDirPlan := __RelDir+(_cAlias)->A2_COD+(_cAlias)->A2_LOJA+"_RGLT020.pdf"
		aAdd(_aAttach,_cDirPlan)
		U_RGLT020(_lJob,_aPergunte,.T.,_lEnvMail,_cDirPlan,MV_PAR15)
	EndIf
	If MV_PAR12 <> 1
		_cDirPlan := __RelDir+(_cAlias)->A2_COD+(_cAlias)->A2_LOJA+"_RGLT020.xlsx"
		aAdd(_aAttach,_cDirPlan)
		U_RGLT020(_lJob,_aPergunte,.F.,_lEnvMail,_cDirPlan,MV_PAR15)
	EndIf

	If _lEnvMail
		U_EnvMail(_cMensagem/*_cMensagem*/,_cFrom/*_cFrom*/,(_cAlias)->A2_EMAIL /*_cTO*/,;
				_cReplyTo/*_cCC*/,/*_cBCC*/,_cReplyTo/*_cReplyTo*/,_cAssunto/*_cAssunto*/,@_cErro/*_cErro*/,_aAttach/*_aAttach*/)
		If !Empty(_cErro)
			MsgStop("MGLT00801 - E-mail:" + (_cAlias)->A2_EMAIL + " Resultado: " +AllTrim(_cErro),"MGLT00801")
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGLT00801"/*cMsgId*/, "E-mail:" + (_cAlias)->A2_EMAIL + " Resultado: " +AllTrim(_cErro)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
	EndIf
	For _nX := 1 To Len(_aAttach)
		FErase(_aAttach[_nX])
	Next _nX
	(_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())

Return
