/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |23/05/2023| Chamado 43234. Problema na gravação do DT_CLASFIS resolvido.
Lucas Borges  |30/11/2023| Chamado 45717. Gravação de novos campos de imposto que a TOTVS não quer fazer.
Lucas Borges  |01/07/2024| Chamado 47711. Incluída gravação na C00 para os casos em que não passou pelo A140ICFOP.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: A140IGRV
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/12/2020
Descrição---------: Ponto de entrada após a gravação dos dados do XML nas tabelas de importação (SDS,SDT). Funcao para leitura 
					de XMLs de NFe no diretorio de download e geracao da pre-nota de entrada. Em que ponto: Após a gravação dos 
					registros importados na tabela SDS e SDT, permite manipular os dados importados para a tabela SDS e SDT.
Parametros--------: ParamIXB[1]	-> C -> Número do documento
					ParamIXB[2]	-> C -> Série do documento
					ParamIXB[3]	-> C -> Código do Fornecedor
					ParamIXB[4]	-> C -> Loja do Fornecedor
					ParamIXB[5]	-> O -> XML referente ao documento
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function A140IGRV

Local _cQuery	:= ''
Local _aItens	:= IIf(ValType(ParamIXB[5]:_InfNfe:_Det) == "O",{ParamIXB[5]:_InfNfe:_Det},ParamIXB[5]:_InfNfe:_Det)
Local _nX		:= 0
Local _cCSTCOF	:= ""
Local _cCSTPIS	:= ""
Local _aArea	:= FWGetArea()
Local _aAreaSA2 := SA2->(GetArea())

//Verifico se os parâmetros vieram preenchidos pois o PE está sendo chamado indevidamente, faltando parâmetros
//e posicionando nos registros errados
If !Empty(ParamIXB[1]) .And. !Empty(ParamIXB[2]) .And. !Empty(ParamIXB[3]) .And. !Empty(ParamIXB[4])
	_cQuery:=" UPDATE "+RetSQLName('SDT')+" SET DT_LOCAL = '31' "
	_cQuery+="  WHERE D_E_L_E_T_ = ' ' "
	_cQuery+="  AND DT_FILIAL = '"+cFilAnt+"'"
	_cQuery+="  AND DT_DOC = '"+ParamIXB[1]+"'"
	_cQuery+="  AND DT_SERIE = '"+ParamIXB[2]+"'"
	_cQuery+="  AND DT_FORNEC = '"+ParamIXB[3]+"'"
	_cQuery+="  AND DT_LOJA = '"+ParamIXB[4]+"'"
	_cQuery+="  AND EXISTS (SELECT 1 FROM "+RetSQLName('SDS')
	_cQuery+="         WHERE D_E_L_E_T_ = ' '"
	_cQuery+="         AND DS_FILIAL = DT_FILIAL"
	_cQuery+="         AND DS_DOC = DT_DOC"
	_cQuery+="         AND DS_SERIE = DT_SERIE"
	_cQuery+="         AND DS_FORNEC = DT_FORNEC"
	_cQuery+="         AND DS_LOJA = DT_LOJA"
	_cQuery+="         AND DS_CNPJ = DT_CNPJ"
	_cQuery+="         AND DS_TIPO = 'D')"
	_cQuery+="  AND EXISTS (SELECT 1 FROM "+RetSQLName('SB1')
	_cQuery+="         WHERE D_E_L_E_T_ = ' '"
	_cQuery+="         AND DT_COD = B1_COD"
	_cQuery+="         AND B1_TIPO = 'PA')"

	If TCSqlExec( _cQuery ) < 0
		FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "A140IGRV01"/*cMsgId*/, "Filial: "+cFilant+"] - Erro: "+AllTrim(TCSQLError())/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
	
	DBSelectArea("SDT")
	SDT->(DBSetOrder(3))
	SDT->(DBSeek(cFilAnt+ParamIXB[3]+ParamIXB[4]+ParamIXB[1]+ParamIXB[2]))
	While !SDT->(Eof()) .And. SDT->(DT_FILIAL+DT_FORNEC+DT_LOJA+DT_DOC+DT_SERIE) == cFilAnt+ParamIXB[3]+ParamIXB[4]+ParamIXB[1]+ParamIXB[2]
		For _nX := 1 To Len(_aItens)
			If AllTrim(_aItens[_nX]:_PROD:_CPROD:TEXT) == AllTrim(SDT->DT_PRODFOR)
				//--PIS
				_cCSTPIS := ""
				If ValType(XmlChildEx(_aItens[_nX]:_Imposto,"_PIS")) == "O"
					If ValType(XmlChildEx(_aItens[_nX]:_Imposto:_PIS,"_PISALIQ")) == "O"//Grupo PIS tributado pela alíquota
						_cCSTPIS := _aItens[_nX]:_Imposto:_PIS:_PISAliq:_CST:Text
					ElseIf ValType(XmlChildEx(_aItens[_nX]:_Imposto:_PIS,"_PISQTDE")) == "O"//Grupo PIS tributado por Qtde
						_cCSTPIS := _aItens[_nX]:_Imposto:_PIS:_PISQtde:_CST:Text
					ElseIf ValType(XmlChildEx(_aItens[_nX]:_Imposto:_PIS,"_PISNT")) == "O"//Grupo PIS não tributado
						_cCSTPIS := _aItens[_nX]:_Imposto:_PIS:_PISNT:_CST:Text
					ElseIf ValType(XmlChildEx(_aItens[_nX]:_Imposto:_PIS,"_PISOUTR")) == "O"//Grupo PIS Outras Operações
						_cCSTPIS := _aItens[_nX]:_Imposto:_PIS:_PISOutr:_CST:Text
					EndIf
				EndIf
				//--COFINS
				_cCSTCOF := ""
				If ValType(XmlChildEx(_aItens[_nX]:_Imposto,"_COFINS")) == "O"
					If ValType(XmlChildEx(_aItens[_nX]:_Imposto:_COFINS,"_COFINSALIQ")) == "O"//Grupo PIS tributado pela alíquota
						_cCSTCOF := _aItens[_nX]:_Imposto:_COFINS:_COFINSAliq:_CST:Text
					ElseIf ValType(XmlChildEx(_aItens[_nX]:_Imposto:_COFINS,"_COFINSQTDE")) == "O"//Grupo PIS tributado por Qtde
						_cCSTCOF := _aItens[_nX]:_Imposto:_COFINS:_COFINSQtde:_CST:Text
					ElseIf ValType(XmlChildEx(_aItens[_nX]:_Imposto:_COFINS,"_COFINSNT")) == "O"//Grupo PIS não tributado
						_cCSTCOF := _aItens[_nX]:_Imposto:_COFINS:_COFINSNT:_CST:Text
					ElseIf ValType(XmlChildEx(_aItens[_nX]:_Imposto:_COFINS,"_COFINSOUTR")) == "O"//Grupo PIS Outras Operações
						_cCSTCOF := _aItens[_nX]:_Imposto:_COFINS:_COFINSOutr:_CST:Text
					EndIf
				EndIf
				
				RecLock("SDT",.F.)
				SDT->DT_I_POSIP := If(ValType(XmlChildEx(_aItens[_nX]:_Prod,"_NCM")) == "O", AllTrim(_aItens[_nX]:_PROD:_NCM:TEXT),"")
				SDT->DT_I_XCEST := If(ValType(XmlChildEx(_aItens[_nX]:_Prod,"_CEST")) == "O", AllTrim(_aItens[_nX]:_PROD:_CEST:TEXT),"")
				SDT->DT_I_XFCI := If(ValType(XmlChildEx(_aItens[_nX]:_Prod,"_CBENEF")) == "O", AllTrim(_aItens[_nX]:_PROD:_CBENEF:TEXT),"")
				SDT->DT_I_XCPIS:= _cCSTPIS
				SDT->DT_I_XCCOF:= _cCSTCOF
				SDT->(MSUnLock())
				Exit
			EndIf
		Next _nX
		SDT->(DBSkip())
	EndDo

	DBSelectArea("C00")
	C00->(DBSetOrder(1))
	//Se o Documento já foi marcado como cancelado, não preciso inclúí-lo, pois outra função fará a exclusão. Sem isso ficará um Loop de incluir/excluir sempre que reprocessar os documentos.
	If !C00->(DBSeek(xFilial("C00")+SDS->DS_CHAVENF))
		SA2->(DBSetOrder(1))
		SA2->(DBSeek(xFilial("SA2")+SDS->(DS_FORNEC+DS_LOJA)))
		RecLock("C00",.T.)
		C00_FILIAL	:= SDS->DS_FILIAL
		C00_CHVNFE	:= SDS->DS_CHAVENF
		C00_SERNFE	:= SDS->DS_SERIE
		C00_NUMNFE	:= SDS->DS_DOC
		C00_VLDOC	:= SDS->DS_VALMERC
		C00_DTEMI	:= SDS->DS_EMISSA
		C00_DTREC	:= SDS->DS_DATAIMP
		C00_NOEMIT	:= SA2->A2_NOME
		C00_CNPJEM	:= SDS->DS_CNPJ
		C00_IEEMIT	:= SA2->A2_INSCR
		C00_STATUS	:= '0'
		C00_CODRET	:= '999'
		C00_DESRES	:= 'Documento incluido manualmente'
		C00_MESNFE	:= StrZero(Month(SDS->DS_EMISSA),2)
		C00_ANONFE	:= StrZero(Year(SDS->DS_EMISSA),4)
		C00_SITDOC	:= '1' //"Uso autorizado da NFe"
		C00_CODEVE	:= '1'//"Envio de Evento não realizado"_

		C00->(MSUnLock())
	EndIf
EndIf

FWRestArea(_aAreaSA2)
FWRestArea(_aArea)

Return
