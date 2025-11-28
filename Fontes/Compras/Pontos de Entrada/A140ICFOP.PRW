/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |21/06/2023| Chamado 44236. Incluído tratamento para buscar da CKO as exceções no tipo de NF-e.
Lucas Borges  |02/07/2023| Chamado 44340. Corrgido Posicione na CKO.
Lucas Borges  |30/11/2023| Chamado 45717. Corrigida leitura do campo CKO_I_TIPO.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: A140ICFOP
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 15/02/2019
Descrição-------: O ponto de entrada A140ICFOP é utilizado na rotina TOTVS Colaboração que identifica o tipo da nota fiscal por 
				meio do código CFOP constante na NF-e, caso não seja possível a identificação por meio dos parâmetros MV_XMLCFPC,
				MV_XMLCFBN e MV_XMLCFDV.
				LOCALIZAÇÃO: Função ImpXML_NFe - Função para leitura de XMLs de NF-e no diretório de download e geração da pré-
				nota de entrada.
				EM QUE PONTO: Na identificação do tipo da nota. Chamado 28136
Parametros------: oXML := Objeto contendo a estrutura do arquivo XML referente ao conhecimento do transporte
Retorno---------: cTipoNF = Tipo caracter contendo o tipo da nota a ser considerada, sendo:
					O = Bonificação
					B = Beneficiamento
					D = Devolução
					N = Normal
===============================================================================================================================
*/
User Function A140ICFOP

Local _aArea	:= FWGetArea()
Local _aAreaCKO :=CKO->(GetArea())
Local _oXML 	:= ParamIXB[1]
Local _cTipoNF 	:= ""
Local _aItens	:= {}
Local _cNFECFAP	:= SuperGetMV("MV_XMLCFPC",.F.,"")
Local _cNFECFBN	:= SuperGetMV("MV_XMLCFBN",.F.,"")
Local _cNFECFDV	:= SuperGetMV("MV_XMLCFDV",.F.,"")
Local _cNFECFNO	:= SuperGetMV("MV_XMLCFNO",.F.,"")
Local _cNFEPALL	:= SuperGetMV("IT_XMLPALL",.F.,"")
Local _cDevCFOP	:= SuperGetMV("IT_XMLCFDV",.F.,"5949/6949/5909/6909") //CFOPs que devem ser considerados quando a operação é uma devolução mas a NF-e não pode ser emitida com essa finalidade.
Local _nX		:= 0
Local _cCGC		:= ""
Local _dDtEmis	:= " / / "
Local _lPallet	:= .F.

DBSelectArea("CKO")
CKO->(DBSetOrder(1))
CKO->(DBSeek("109"+Right(AllTrim(_oXML:_InfNfe:_Id:Text),44)+".xml"))

If !Empty(CKO->CKO_I_TIPO)
	_cTipoNF := CKO->CKO_I_TIPO
Else
	//Armazeno o emitente
	If XmlChildEx(_oXML:_InfNfe:_EMIT,"_CNPJ") # NIL
		_cCGC := _oXML:_InfNfe:_EMIT:_CNPJ:TEXT
	ElseIf XmlChildEx(_oXML:_InfNfe:_EMIT,"_CPF") # NIL
		_cCGC := _oXML:_InfNfe:_EMIT:_CPF:TEXT
	EndIf

	//Armazeno os Itens
	_aItens := IIf(ValType(_oXML:_InfNfe:_Det) == "O",{_oXML:_InfNfe:_Det},_oXML:_InfNfe:_Det)

	If AllTrim(_oXML:_InfNfe:_Ide:_finNFe:Text) == "1"
		_cTipoNF := "N"
		//-- Valida o tipo da nf
		For _nX := 1 To Len(_aItens)
			_lPallet := "PALLET" $ Upper(_aItens[_nX]:_PROD:_XPROD:TEXT) .Or. "PALETE" $ Upper(_aItens[_nX]:_PROD:_XPROD:TEXT).OR. "PALETT" $ Upper(_aItens[_nX]:_PROD:_XPROD:TEXT)
			If _aItens[_nX]:_PROD:_CFOP:TEXT $ '5949/6949' .And. _lPallet .And. !(SubStr(_cCGC,1,8) $ _cNFEPALL)
				_cTipoNF := "D"
			//Esse tipo de nota não pode ser emitida como Devolução e além desse possível texto na natureza da operação, só alguma observação na nota que poderá indicar que é uma devolução
			ElseIf _aItens[_nX]:_PROD:_CFOP:TEXT $ _cDevCFOP .And. !_lPallet .And. ("RETORNO" $ Upper(AllTrim(_oXML:_InfNfe:_Ide:_natOp:Text)) .Or. "DEV" $ Upper(AllTrim(_oXML:_InfNfe:_Ide:_natOp:Text)));
					.And. !"REMESSA" $ Upper(AllTrim(_oXML:_InfNfe:_Ide:_natOp:Text))
				_cTipoNF := "D"
			ElseIf _aItens[_nX]:_PROD:_CFOP:TEXT $ _cNFECFAP
				_cTipoNF := "O"
			ElseIf _aItens[_nX]:_PROD:_CFOP:TEXT $ _cNFECFBN
				_cTipoNF := "B"
			ElseIf _aItens[_nX]:_PROD:_CFOP:TEXT $ _cNFECFDV
				_cTipoNF := "D"
			EndIf
			If _cTipoNF <> "N"
				Exit
			EndIf
		Next _nX

	ElseIf AllTrim(_oXML:_InfNfe:_Ide:_finNFe:Text) == "4"
		For _nX := 1 To Len(_aItens)
			If _aItens[_nX]:_PROD:_CFOP:TEXT $ _cNFECFNO // Tratamento para modificar o tipo da nota para N = Normal, quando TAG FINNFE = 4.
				_cTipoNF := "N"
				Exit
			ElseIf _aItens[_nX]:_PROD:_CFOP:TEXT $ _cNFECFBN
				_cTipoNF := "B"
				Exit
			EndIf
		Next _nX

		If Empty(_cTipoNF)
			_cTipoNF := "D"
		EndIf

	EndIf
EndIf
//===============================================================================================================================================
//Utilizo um ponto de entrada qualquer para poder gerar a C00 visto que não é possível mais utilizar o sincronismo da rotina de MD-e (SPEDMANIFE).
//Conforme NT 2014.002, 1.12 de Março 2022, a SEFAZ responde pelo sincronismo independente de quem solicita e ela controla os documentos entregues.
//Como utilizamos o ITGS para sincronismo, não conseguimos mais usar o Protheus.
//===============================================================================================================================================
DBSelectArea("C00")
C00->(DBSetOrder(1))
//Se o Documento já foi marcado como cancelado, não preciso inclúí-lo, pois outra função fará a exclusão. Sem isso ficará um Loop de incluir/excluir sempre que reprocessar os documentos.
If !C00->(DBSeek(xFilial("C00")+Right(AllTrim(_oXML:_InfNfe:_Id:Text),44))) .And. !CKO->CKO_CODERR == 'COM040'
	If ValType(XmlChildEx(_oXML:_InfNfe:_Ide,"_DEMI")) == "O"
		_dDtEmis := SToD(StrTran(AllTrim(_oXML:_InfNfe:_Ide:_DEmi:Text),"-",""))
	ElseIf ValType(XmlChildEx(_oXML:_InfNfe:_Ide,"_DHEMI")) == "O"
		_dDtEmis := SToD(StrTran(SubStr((_oXML:_InfNfe:_Ide:_DhEmi:Text),1,10),"-",""))
	EndIf

	RecLock("C00",.T.)
	C00_FILIAL	:= xFilial("C00")
	C00_CHVNFE	:= Right(AllTrim(_oXML:_InfNfe:_Id:Text),44)
	C00_SERNFE	:= StrZero(Val(AllTrim(_oXML:_InfNfe:_Ide:_Serie:Text)),SerieNfId("SF1",6,"F1_SERIE"))
	C00_NUMNFE	:= StrZero(Val(AllTrim(_oXML:_InfNfe:_Ide:_nNF:Text)),TamSX3("F1_DOC")[1])
	C00_VLDOC	:= Val(_oXML:_InfNfe:_Total:_IcmsTot:_vNF:TEXT)
	C00_DTEMI	:= _dDtEmis
	C00_DTREC	:= _dDtEmis
	C00_NOEMIT	:= Upper(NoAcento(AllTrim(_oXML:_InfNfe:_Emit:_xNome:Text)))
	C00_CNPJEM	:= _cCGC
	C00_IEEMIT	:= IIf(XmlChildEx(_oXML:_InfNfe:_EMIT,"_IE") # NIL,_oXML:_InfNfe:_EMIT:_IE:TEXT,"")
	C00_STATUS	:= '0'
	C00_CODRET	:= '999'
	C00_DESRES	:= 'Documento incluido manualmente'
	C00_MESNFE	:= StrZero(Month(_dDtEmis),2)
	C00_ANONFE	:= StrZero(Year(_dDtEmis),4)
	C00_SITDOC	:= '1' //"Uso autorizado da NFe"
	C00_CODEVE	:= '1'//"Envio de Evento não realizado"_

	C00->(MSUnLock())
EndIf
_oXML	:=Nil

FWRestArea(_aAreaCKO)
FWRestArea(_aArea)

Return _cTipoNF
