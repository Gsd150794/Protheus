/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |22/05/2022| Chamado 40178. Ajuste na gravação do Tipo de Operação. 
Alex Wallauer |21/11/2024| Chamado 48952. Retirado o tratamento para os produtos com rastro / lotes, pq foi para o MT100GRV.PRW.
Lucas Borges  |23/05/2025| Chamado 50754. Incluído tratamento para CT-e Simplificado
==============================================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: COLF1D1
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 20/04/2018
Descrição-------: O Ponto de Entrada COLF1D1 permite adicionar acrescentar campos customizados na SF1 e SD1 antes da geração 
				  do documento. O Ponto de entrada é executado antes do execauto.
Parametros------: ParamIXB -> Array -> Cabeçalho da NF (SF1)[1] -> Obrigatorio
				  ParamIXB -> Array -> Itens da NF (SD1)[2]		-> Obrigatorio
Retorno---------: aCab 	 -> Array	-> Cabeçalho da NF (SF1)[1]	-> Obrigatorio
				  aItens -> Array	-> Itens da NF (SD1)[2]		-> Obrigatorio
===============================================================================================================================
*/
User Function COLF1D1

Local _aCab 	:= ParamIXB[1] As Array
Local _aItens	:= ParamIXB[2] As Array
Local _aRet 	:= {} As Array
Local _cMensFis := '' As Character
Local _cMensCli := ''As Character
Local _cError	:= '' As Character
Local _cWarning	:= '' As Character
Local _nX		:= 0 As Numeric
Local _cXML		:= '' As Character
Local _oXML     := Nil As Object
Local _oFullXML := Nil As Object
Local _nI		:= 0 As Numeric
Local _cNature	:= '' As Character
Local _nEntSai  := 1 As  Numeric//Documento de 1-Entrada / 2-Saida
Local _cTpOper  := '' As Character //Código da TES Inteligente
Local _cClieFor := SDS->DS_FORNEC As Character//Codigo do Cliente ou Fornecedor
Local _cLoja    := SDS->DS_LOJA As Character//Codigo da Loja do Cli/Forn 
Local _cTipoCF  := IIf(SDS->DS_TIPO $ 'B/D','C','F') As Character //Tipo Cliente / Fornecedor
Local _cProduto := '' As Character//Codigo do produto
Local _cCampo   := '' As Character//Campo que contem a TES
Local _cTipoCli := '' As Character//Tipo Cliente (F=Cons.Final;L=Prod.Rural;R=Revendedor;S=Solidario;X=Exportacao/Importacao)
Local _cEstOrig := '' As Character//Estado de Origem do documento
Local _cOrigem  := '' As Character
//====================================================================================================
// Verifica o arquivo XML e realiza a leitura para gravação de mensagens fiscais e do cliente
//====================================================================================================
DBSelectArea('CKO')
CKO->( DBSetOrder(1) )
If CKO->( DBSeek( SDS->DS_ARQUIVO ) )
	_cXML := AllTrim( CKO->CKO_XMLRET  )
EndIf

//====================================================================================================
// Processa se conseguir ler os dados do arquivo XML
//====================================================================================================
If !Empty( _cXML )
	
	_cXML := SubStr( _cXML , At( '<' , _cXML ) )

	//====================================================================================================
	// Inicializa o objeto do XML
	//====================================================================================================
	_oFullXML := XmlParser( _cXML , "_" , @_cError , @_cWarning )
	
	If !Empty(_oFullXML) .And. ValType(_oFullXML)=="O"

		If ValType( XmlChildEx( _oFullXML , "_NFEPROC" ) ) == "O" //-- Nota normal, devolucao, beneficiamento, bonificacao
			If ValType( XmlChildEx( _oFullXML:_NFeProc , "_NFE" ) ) == "O"
				_oXML := _oFullXML:_NFeProc:_Nfe    
			Else
				_oXML := _oFullXML:_NFeProc:_NFeProc:_Nfe
			EndIf
		ElseIf ValType(XmlChildEx(_oFullXML,"_CTE")) == "O" //-- Nota de transporte
			_oXML := _oFullXML:_CTe
		ElseIf ValType(XmlChildEx(_oFullXML,"_CTESIMPPROC")) == "O"
			_oXML := _oFullXML:_CTeSimpProc:_CTeSimp
		ElseIf ValType(XmlChildEx(_oFullXML,"_CTEPROC")) == "O" //-- Nota de transporte
			If ValType(XmlChildEx(_oFullXML:_CTEPROC,"_ENVICTE")) == "O"
				_oXML := _oFullXML:_CTeProc:_ENVICTE:_Cte
			ElseIf ValType(XmlChildEx(_oFullXML:_CTEPROC,"_CTEOS")) == "O" //-- Nota de transporte CTEOS
				_oXML := _oFullXML:_CTeProc:_CTEOS
			Else
				_oXML := _oFullXML:_CTeProc:_Cte
			EndIf
		ElseIf ValType(XmlChildEx(_oFullXML,"_CTEOSPROC")) == "O" //-- Nota de transporte CTEOS
			_oXML := _oFullXML:_CTeOSProc:_CteOS
		EndIf

		If ValType(XmlChildEx(_oXml,"_INFNFE")) == "O" //NF-e - Nota normal, devolucao, beneficiamento, bonificacao
			If ValType(XmlChildEx(_oXML:_InfNfe,"_INFADIC")) != "U"
				If ValType(XmlChildEx(_oXML:_InfNfe:_infAdic,"_INFADFISCO")) != "U"
					If Type("_oXML:_InfNfe:_infAdic:_infAdFisco:TEXT")!="U"
						_cMensFis := _oXML:_InfNfe:_infAdic:_infAdFisco:TEXT
						aAdd(_aCab,{"F1_I_MENFI",NoAcento(_cMensFis),NIL})
					EndIf
				EndIf
				If ValType(XmlChildEx(_oXML:_InfNfe:_infAdic,"_INFCPL")) != "U"
					If Type("_oXML:_InfNfe:_infAdic:_infCpl:TEXT")!="U"
						_cMensCli := _oXML:_InfNfe:_infAdic:_infCpl:TEXT
						aAdd(_aCab,{"F1_I_MENSA",NoAcento(_cMensCli),NIL})
					EndIf
				EndIf
			EndIf
		ElseIf ValType(XmlChildEx(_oXML,"_INFCTE")) == "O" //CT-e, CT-eOS, Ct-e Simplificado
			If ValType(XmlChildEx(_oXML:_InfCte:_Imp,"_INFADFISCO")) == "O" .And. !Empty(_oXML:_INFCTE:_IMP:_INFADFISCO:TEXT)
				_cMensFis := _oXML:_INFCTE:_IMP:_INFADFISCO:TEXT
			EndIf
			If ValType(XmlChildEx(_oXML:_InfCte,"_COMPL")) != "U" .And. ValType(XmlChildEx(_oXML:_InfCte:_Compl,"_XOBS")) != "U"
				_cMensCli := If(ValType(XmlChildEx(_oXML:_InfCte:_Compl,"_XOBS")) == "O",_oXML:_INFCTE:_COMPL:_XOBS:TEXT ,"")
			EndIf
			If ValType(XmlChildEx(_oXML:_InfCte,"_COMPL")) != "U" .And. ValType(XmlChildEx(_oXML:_InfCte:_Compl,"_OBSCONT")) == "A"
				For _nX := 1 to Len(_oXML:_INFCTE:_COMPL:_OBSCONT)
					_cMensCli += _oXML:_INFCTE:_COMPL:_OBSCONT[_nX]:_XCAMPO:TEXT + ": " + _oXML:_INFCTE:_COMPL:_OBSCONT[_nX]:_XTEXTO:TEXT + ". "+ CRLF
				Next _nX
			ElseIf ValType(XmlChildEx(_oXML:_InfCte,"_COMPL")) != "U" .And. ValType(XmlChildEx(_oXML:_InfCte:_Compl,"_OBSCONT")) == "O" .And. !Empty(_oXML:_INFCTE:_COMPL:_OBSCONT:TEXT)//ValType("_oXML:_INFCTE:_COMPL:_OBSCONT:_XTEXTO:TEXT") == "O" //ver
				_cMensCli := _oXML:_INFCTE:_COMPL:_OBSCONT:_XCAMPO:TEXT + ": "+ _oXML:_INFCTE:_COMPL:_OBSCONT:_XTEXTO:TEXT + ". "
			EndIf
			If ValType(XmlChildEx(_oXML:_InfCte,"_COMPL")) != "U" .And. ValType(XmlChildEx(_oXML:_InfCte:_Compl,"_OBSFISCO")) == "A"
				For _nX := 1 to Len(_oXML:_INFCTE:_COMPL:_OBSFISCO)
					_cMensFis += _oXML:_INFCTE:_COMPL:_OBSFISCO[_nX]:_XCAMPO:TEXT + ": " + _oXML:_INFCTE:_COMPL:_OBSFISCO[_nX]:_XTEXTO:TEXT + ". " + CRLF
				Next _nX
			ElseIf ValType(XmlChildEx(_oXML:_InfCte,"_COMPL")) != "U" .And. ValType(XmlChildEx(_oXML:_InfCte:_Compl,"_OBSFISCO")) == "O" .And. !Empty(_oXML:_INFCTE:_COMPL:_OBSFISCO:TEXT) //ValType("_oXML:_INFCTE:_COMPL:_OBSFISCO:_XTEXTO:TEXT") <> "U" //ver
				_cMensFis := _oXML:_INFCTE:_COMPL:_OBSFISCO:_XCAMPO:TEXT + ": "+ _oXML:_INFCTE:_COMPL:_OBSFISCO:_XTEXTO:TEXT + ". "
			EndIf
		EndIf
    
	EndIf

	If !Empty(_cMensCli)
		aAdd(_aCab,{"F1_I_MENSA",NoAcento(_cMensCli),NIL})
	EndIf
	If !Empty(_cMensFis)
		aAdd(_aCab,{"F1_I_MENFI",NoAcento(_cMensFis),NIL})
	EndIf
	_oXML := Nil
	_oFullXML:= Nil
	DelClassIntF()
EndIf
aAdd(_aCab,{"F1_L_MIX",SDS->DS_L_MIX,NIL})//Campo usado para gerar contra-notas e fechamento do leite de Pessoa Jurídica

//=======================================
//Tratamento para gravação da Natureza
//=======================================
If SDS->DS_TIPO == "D"
    _cNature := SuperGetMV("IT_DEVNATU",.F.,"410001")
Else
    For _nI := 1 To Len( _aItens )
        _cProduto	:= _aItens[_nI][aScan(_aItens[_nI],{|x| Upper(AllTrim(x[1])) == "D1_COD"})][2]
        //CT-e não tem CFOP, logo, a regra deve ser explicida.
        If AllTrim(SDS->DS_ESPECI) == 'CTE'//Operações com CT-e
            If SDS->DS_UFORITR == SDS->DS_UFDESTR//SDS->DS_EST == SM0->M0_ESTENT
                _cTpOper := '10'
            Else
                _cTpOper := '11'
            EndIf
        Else//Demais documentos consigo buscar o tipo de operação pelo CFOP
            If aScan(_aItens[_nI],{|x| Upper(AllTrim(x[1])) == "D1_OPER"}) > 0
                _cTpOper := _aItens[_nI][aScan(_aItens[_nI],{|x| Upper(AllTrim(x[1])) == "D1_OPER"})][2]
            Else
                _cTpOper := ColConDHJ(_aItens[_nI][aScan(_aItens[_nI],{|x| Upper(AllTrim(x[1])) == "CFOP"})][2])
            EndIf
        EndIf
        
        If !Empty(_cTpOper)
            _cNature:= U_MaNatInt(_nEntSai,_cTpOper,_cClieFor,_cLoja,_cTipoCF,_cProduto,_cCampo,_cTipoCli,_cEstOrig,_cOrigem)
        EndIf
        If !Empty(_cNature)
            Exit
        EndIf
    Next _nI
EndIf
If !Empty(_cNature)
    aAdd(_aCab,{"E2_NATUREZ",_cNature,NIL})
EndIf
_aRet := {_aCab,_aItens}

Return _aRet
