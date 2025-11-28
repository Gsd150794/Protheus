/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/04/2019| Chamado 28802. Informado tipos de fornecedores disponíveis para NF-e
Lucas Borges  |05/08/2021| Chamado 37395. Informado tipos de fornecedores disponíveis para NF-e
Lucas Borges  |20/12/2022| Chamado 42163. Compatibilizada validação da Incrição Estadual usando a função da TOTVS
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: A140IFOR
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/07/2015
Descrição---------: Ponto de Entrada para informar o fornecedor/cliente da NFe, caso exista duplicidade de CNPJ e Inscrição 
					Estadual nos cadastros de Cliente e/ou Fornecedor.
					Esse PE só é chamado caso exista mais de um fornecedor valido, ou seja, se existirem 3 cadastros e apenas 
					1 desbloqueado, o PE não será chamado.
					Executado no momento da leitura do xml de NF-e para gravação na SDS e SDT - Chamado 15090
Parametros--------: 	ParamIXB[1] - Tabela de origem dos dados: SA1 ou SA2
					  	ParamIXB[2] - CNPJ do Cliente / Fornecedor
					  	ParamIXB[3] - Inscrição Estadual do Cliente / Fornecedor
					  	ParamIXB[4] - Objeto para obtenção das informações das TAGS do XML
Retorno-----------: _aRet = Array "aRet" de três posições, contendo obrigatoriamente três elementos.
						Elemento 1 = Código do fornecedor/cliente
						Elemento 2 = Loja do fornecedor/cliente
						Elemento 3 = Nome do fornecedor/cliente
===============================================================================================================================
*/
User Function A140IFOR

Local _aRet		:= {}
Local _cAlias	:= ParamIXB[1]
Local _cCampo	:= _cAlias + " ->" + SubStr(ParamIXB[1],2,2)
Local _nX		:= 0
Local _lTroca	:= .F.
Local _cForn	:= SuperGetMV("IT_XMLCFOR",.F.,"L001050020;L001050014;F090570001;L001930002;P285100002")
Local _cCGC		:= SuperGetMV("IT_XMLFFOR",.F.,"76108349002076;76108349001428;06203406000158;07510884000254;14351004000129")
Local _cCFOP	:= SuperGetMV("IT_XMLTCFO",.F.,"5102;6102;6122;6101")
Local _cTipoForn:= SuperGetMV("IT_XMLTFOR",.F.,"F/L/P/0")
Local _cForOri	:= ""

DBSelectArea(_cAlias)
(_cAlias)->( DBSetOrder(3))
	
//Procura registro com CNPJ
If (_cAlias)->( DBSeek(xFilial(_cAlias) + AllTrim(ParamIXB[2]) ) )
	//Roda todos os registros com cnpj válido. Só retorna se achar um que esteja desbloqueado e tenha a mesma inscrição estadual
	While AllTrim( &(_cCampo + "_CGC") ) == AllTrim(ParamIXB[2])
		//Tratamentto específico para determinado fornecedor/tipo de operação
		If !_lTroca .And. AllTrim(&(_cCampo + "_CGC")) $ _cCGC
			_aItens := IIf(ValType(ParamIXB[4]:_InfNfe:_Det) == "O",{ParamIXB[4]:_InfNfe:_Det},ParamIXB[4]:_InfNfe:_Det)
			//-- Valida o tipo da nf
			For _nX := 1 To Len(_aItens)
				If _aItens[_nX]:_PROD:_CFOP:TEXT $ _cCFOP
					_lTroca := .T.
					Exit
				EndIf
			Next _nX
		EndIf
		//Pàra NF-e só será permitido fornecedores do tipo F/L/P ou Clientes (0)
		If &(_cCampo + "_MSBLQL") <> '1' .And. A140INSC(ParamIXB[3],&(_cCampo + "_INSCR")) .And. SubStr(&(_cCampo + "_COD"),1,1) $ _cTipoForn
			_aRet := { 	&(_cCampo + "_COD"),;
						&(_cCampo + "_LOJA"),;
						&(_cCampo + "_NOME")}
						
			_cForOri := &(_cCampo + "_COD") + &(_cCampo + "_LOJA")

			If !_lTroca .Or. (_lTroca .And. _cForOri $ _cForn)
				Exit
			EndIf 
		EndIf
		(_cAlias)->( DBSkip() )
	EndDo
EndIf

Return _aRet
