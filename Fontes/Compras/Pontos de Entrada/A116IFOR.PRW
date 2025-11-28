/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/04/2019| Chamado 28802. Informado tipos de fornecedores disponíveis para CT-e
Lucas Borges  |28/04/2022| Chamado 39923. Tratamento para demais tags de fornecedores
Lucas Borges  |20/12/2022| Chamado 42163. Compatibilizada validação da Incrição Estadual usando a função da TOTVS
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "XMLXFUN.CH"

/*
===============================================================================================================================
Programa----------: A116IFOR
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/07/2015
Descrição---------: PE Selecao de fornecedor para carga de xml de cte no SDS e SDT - Chamado 15090
					Esse PE só é chamado caso exista mais de um fornecedor valido, ou seja, se existirem 3 cadastros e apenas 
					1 desbloqueado, o PE não será chamado.
Parametros--------: ParamIXB[1] = Objeto contendo a estrutura do XML de CTe
					ParamIXB[2] = Entidade posicionada (SA1/SA2)
					ParamIXB[3] = tag analisada para identificação do CNPJ (R-Remetente,D-Destinatário, E-Emitente, B-Recebedor,
								 X-Expedidor e T-toma4.)
Retorno-----------: _aRet = Array contendo obrigatoriamente três elementos.
					Elemento 1 = Código da tabela onde consta o fornecedor/cliente (SA1 ou SA2).
					Elemento 2 = Código do fornecedor/cliente da mercadoria.
					Elemento 3 = Código da loja do fornecedor/cliente da mercadoria.
===============================================================================================================================
*/
User Function A116IFOR()

Local _aArea 	:= FWGetArea()
Local _aRet 	:= {}
Local _oXML 	:= ParamIXB[1]
Local _cTab 	:= ParamIXB[2]
Local _cCampo 	:= _cTab + " ->" + SubStr(ParamIXB[2],2,2)
Local _cTag 	:= ParamIXB[3]
Local _cIE 		:= ""
Local _cCNPJ 	:= ""
Local _lComp	:= .F.
Local _aAux1	:= {}
Local _cChaveNF := ""
Local _lForOri  := .F.
Local _nI		:= 0
Local _cAux		:= ""

//Verifica qual a TAG do XML devemos analisar, visto que o PE pode ser chamado uma vez para cada
If _cTag =="R"//Remetente
	_cAux := "_REM"
ElseIf 	_cTag =="E"//Emitente
	_cAux := "_EMIT"
ElseIf 	_cTag =="D"//Destinatário
	_cAux := "_DEST"
ElseIf 	_cTag =="B"//Recebedor
	_cAux := "_RECEB"
ElseIf 	_cTag =="X"//Expedidor
	_cAux := "_EXPED"
EndIf

If !Empty(_cAux)
	_cIE := If(ValType(XmlChildEx(_oXML:_InfCte,_cAux)) == "O", If(ValType(XmlChildEx(&("_oXML:_InfCte:"+_cAux),"_IE")) == "O","_IE",""),"")
EndIf
//Se o CT-e é Normal 0, posso escolher o fornecedor, mas se For diferente, preciso usar o que foi informado
//na operação de origem, independe se está bloqueado
If ValType(XmlChildEx(_oXML:_InfCte,"_INFCTECOMP")) != "U"
	_lComp	:= .T.
EndIf

If _lComp .And. _cTag $"E/R"

	//Para CT-e Complementar tpCTE = 1, pego a chave da nota complementada e verifico qual é o fornecedor que foi utilizado
	_aAux1 := If(ValType(_oXML:_InfCte:_InfCTeComp) == "O",{_oXML:_InfCte:_InfCTeComp},_oXML:_InfCte:_InfCTeComp)
	If ValType( XmlChildEx(	_oXML:_INFCTE:_InfCTeComp , "_CHAVE" ) ) <> 'U'
		_cChaveNF := PadR(AllTrim(_aAux1[1]:_chave:Text),TamSX3("F1_CHVNFE")[1])
	Else
		_cChaveNF := PadR(AllTrim(_aAux1[1]:_chCte:Text),TamSX3("F1_CHVNFE")[1])
	EndIf

	DBSelectArea("SF1")
	("SF1")->( DBSetOrder(8))
	
	If ("SF1")->( DBSeek( xFilial("SF1") + _cChaveNF ) )	
		_aRet := { 	_cTab			,;
					SF1->F1_FORNECE	,;
					SF1->F1_LOJA 	}
		_lForOri := .T.
	EndIf
	
	("SF1")->( DBCloseArea() )
	
EndIf

If !_lForOri .And. _cTag =="R"

	//Se a entidade é o remetente, preciso ver se a nota referenciada existe na base. Se existir, preciso usar
	//esse cadastro, independe se está bloqueado
	If ValType( XmlChildEx(	_oXML:_INFCTE , "_INFCTENORM" ) ) <> 'U'
	   	If ValType( XmlChildEx(	_oXML:_INFCTE:_INFCTENORM , '_INFDOC' ) ) <> 'U'
	   		If ValType( XmlChildEx(	_oXML:_INFCTE:_INFCTENORM:_INFDOC , '_INFNFE' ) ) <> 'U'
	   			_aAux1 := IIf( ValType( XmlChildEx(	_oXML:_INFCTE:_INFCTENORM:_INFDOC , "_INFNFE" ) ) == "O" , { _oXML:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE } , _oXML:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE )
	   		EndIf
	   	EndIf
			    	
	ElseIf ValType( XmlChildEx(	_oXML:_INFCTE , "_INFCTECOMP" ) ) <> 'U'
		_aAux1 := IIf( ValType( XmlChildEx(	_oXML:_INFCTE , "_INFCTECOMP"	) ) == "O" , { _oXML:_INFCTE:_INFCTECOMP	} , _oXML:_INFCTE:_INFCTECOMP	)
	ElseIf ValType( XmlChildEx(	_oXML:_INFCTE , "_INFCTEANU" ) ) <> 'U'
		_aAux1 := IIf( ValType( XmlChildEx(	_oXML:_INFCTE , "_INFCTEANU"	) ) == "O" , { _oXML:_INFCTE:_INFCTEANU	} , _oXML:_INFCTE:_INFCTEANU	)
	EndIf
				
	If !Empty( _aAux1 )
		For _nI := 1 To 1//Len( _aAux1 )
			If ValType( XmlChildEx(	_oXML:_INFCTE , "_INFCTEANU" ) ) <> 'U'
				_cChaveNF := PadR( AllTrim( _aAux1[_nI]:_CHCTE:Text ) , TamSX3("F1_CHVNFE")[1] )
			ElseIf ValType( XmlChildEx(	_oXML:_INFCTE , "_INFCTECOMP" ) ) <> 'U'
				If ValType( XmlChildEx(	_oXML:_INFCTE:_InfCTeComp , "_CHAVE" ) ) <> 'U'
					_cChaveNF := PadR(AllTrim(_aAux1[1]:_chave:Text),TamSX3("F1_CHVNFE")[1])
				Else
					_cChaveNF := PadR(AllTrim(_aAux1[1]:_chCte:Text),TamSX3("F1_CHVNFE")[1])
				EndIf
			ElseIf ValType( XmlChildEx(	_oXML:_INFCTE , "_INFCTENORM" ) ) <> 'U'
				_cChaveNF := PadR(AllTrim(_aAux1[1]:_chave:Text),TamSX3("F1_CHVNFE")[1])
			EndIf
	
			//Realiza a primeira busca da chave referenciada na SF1. Caso não ache, busca na SF2
			DBSelectArea("SF1")
			("SF1")->( DBSetOrder(8))
			If ("SF1")->( DBSeek( xFilial("SF1") + _cChaveNF ) )	
				_aRet := { 	_cTab			,;
							SF1->F1_FORNECE	,;
							SF1->F1_LOJA 	}
				_lForOri := .T.
			Else
				DBSelectArea("SF2")
				("SF2")->( DbOrderNickName("IT_CHVNF2"))
				If ("SF2")->( DBSeek( _cChaveNF ) )	
					_aRet := { 	_cTab			,;
								SF2->F2_CLIENTE	,;
								SF2->F2_LOJA 	}
					_lForOri := .T.
				EndIf
				("SF2")->( DBCloseArea() )
			EndIf
			("SF1")->( DBCloseArea() )
		Next _nI
	EndIf
EndIf       

If !_lForOri .And. !Empty(_cAux)//evito que processe o _TOMA4 pois não é necessário
	//Carrega cnpj do xml do cte
	If ValType(XmlChildEx(&("_oXML:_InfCte:"+_cAux),"_CNPJ")) <> "U"
		_cCNPJ := AllTrim(&("_oXML:_InfCte:"+_cAux+":_CNPJ:Text"))
	Else
		_cCNPJ := AllTrim(&("_oXML:_InfCte:"+_cAux+":_CPF:Text"))
	EndIf

	If ValType(XmlChildEx(&("_oXML:_InfCte:"+_cAux),_cIE)) == "O"
		_cIE 	:= AllTrim(XmlChildEx(&("_oXML:_InfCte:"+_cAux),_cIE):Text)
	EndIf

	DBSelectArea(_cTab)
	(_cTab)->( DBSetOrder(3))
	
	//Procura registro com CNPJ
	If (_cTab)->( DBSeek( xFilial(_cTab) + _cCNPJ ) )	
		//Roda todos os registros com cnpj válido. Só retorna se achar um que esteja desbloqueado
		//e tenha a mesma inscrição estadual
		While AllTrim( &(_cCampo + "_CGC") ) == _cCNPJ
			//Pàra CT-e só será permitido fornecedores do tipo T/G/C
			If &(_cCampo + "_MSBLQL") <> '1' .And. A140INSC(_cIE,&(_cCampo + "_INSCR")) .And. SubStr(&(_ccampo + "_COD"),1,1) $ "T/G/C"
				_aRet := { 	_cTab				,;
							&(_ccampo + "_COD"),;
							&(_ccampo + "_LOJA")}
				Exit
			EndIf
			(_cTab)->( DBSkip() )
		EndDo
	EndIf
	(_cTab)->( DBCloseArea() )
	
EndIf           

FWRestArea(_aArea)

Return _aRet
