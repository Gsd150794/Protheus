/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |18/06/2018| Chamado 25235. Alterado produto padrão para todas a operações.
Lucas Borges  |10/01/2019| Chamado 23984. Incluído tratamento para CTeOS.
Lucas Borges  |28/04/2022| Chamado 39923. Tratamento para demais tags de fornecedores.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: A116PRDF
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 21/05/2018
Descrição-------: Ponto de entrada utilizado na rotina de importação de XML de nota fiscal eletrônica, referente ao conhecimento
				 do transporte, para alterar o código do produto que identifica o  frete que será gravado na nota fiscal de 
				 entrada.
				 LOCALIZAÇÃO: Função ImpXML_Cte - responsável pelo processamento do arquivo xml CT-e para gravar os registros 
				 nas tabelas SDS e SDT.
				 EM QUE PONTO: Após a leitura do arquivo na pasta xmlnfe/new e identificação se a Empresa é remetente ou desti-
				 natária da nota. Chamado 13990
Parametros------: oXML := Objeto contendo a estrutura do arquivo XML referente ao conhecimento do transporte
Retorno---------: cPrdFrete - Retorna o código do produto que deve ser considerado para gravação da nota fiscal de entrada.
===============================================================================================================================
*/
User Function A116PRDF

Local _aArea 	:= FWGetArea()
Local _oXML 	:= ParamIXB[1]
Local _aPrdFrete:= {}
Local _cPrdFrete:= ""
Local _aAux1	:= {}
Local _cAlias	:= ""
Local _cCGCDes	:= ''
Local _cTagDest := ''
Local _nI		:= 0
Local _cChaveNF	:= ''

_aPrdFrete := StrTokArr(SuperGetMV("MV_XMLPFCT",.F.,""),";")

If Upper(_oXML:RealName) == "CTEOS" // Garanto que não executará nenhuma validação para CTeOs
	//Produto exclusivo para o CTeOS
	_cPrdFrete := _aPrdFrete[4]
Else //CTe
	//Definido que a operação padrão é um frete sobre compras
	_cPrdFrete := _aPrdFrete[2]
	
	If ValType( XmlChildEx( _oXML:_InfCte:_Ide , "_TOMA4" ) ) <> "U" .And. AllTrim( _oXML:_InfCte:_Ide:_Toma4:_TOMA:Text ) == "4"
		_cTagDest	:= If( ValType( XmlChildEx(	_oXML:_InfCte:_Ide:_Toma4	, "_CNPJ" ) ) == "O" , "_CNPJ" , "_CPF" )
		_cCGCDes	:= AllTrim( XmlChildEx(_oXML:_InfCte:_Ide:_Toma4	, _cTagDest ):Text )
	ElseIf ValType(XmlChildEx(_oXML:_InfCte,"_DEST")) == "O"
		_cTagDest	:= If(ValType(XmlChildEx(_oXML:_InfCte:_Dest , "_CNPJ" ) ) == "O","_CNPJ","_CPF")
		_cCGCDes 	:= AllTrim( XmlChildEx(_oXML:_InfCte:_Dest , _cTagDest ):Text )
	ElseIf ValType(XmlChildEx(_oXML:_InfCte,"_EXPED")) == "O"
		_cTagDest	:= If(ValType(XmlChildEx(_oXML:_InfCte:_Exped , "_CNPJ" ) ) == "O","_CNPJ","_CPF")
		_cCGCDes 	:= AllTrim( XmlChildEx(_oXML:_InfCte:_Exped , _cTagDest ):Text )
	EndIf

	//====================================================================================================	
	// Se o tomador do serviço é uma filial diferente da que está sendo processada, indica que o CT-e é
	// referente à uma transferência. Produto 10000000014
	//====================================================================================================	
	If SubStr( SM0->M0_CGC , 1 , 8 ) == SubStr( _cCGCDes , 1 , 8 ) .And. AllTrim(SM0->M0_CGC) <> AllTrim(_cCGCDes)
		_cPrdFrete := _aPrdFrete[3]
	Else
	    _aAux1 := {}
	    If ValType( XmlChildEx(	_oXML:_INFCTE , "_INFCTENORM" ) ) <> 'U'
	       	If ValType( XmlChildEx(	_oXML:_INFCTE:_INFCTENORM , '_INFDOC' ) ) <> 'U'
		    	If ValType( XmlChildEx(	_oXML:_INFCTE:_INFCTENORM:_INFDOC , '_INFNFE' ) ) <> 'U'
		    		_aAux1 := IIf( ValType( XmlChildEx(	_oXML:_INFCTE:_INFCTENORM:_INFDOC , "_INFNFE" ) ) == "O" , { _oXML:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE } , _oXML:_INFCTE:_INFCTENORM:_INFDOC:_INFNFE )
		    	EndIf
	    	EndIf
		ElseIf ValType( XmlChildEx(	_oXML:_INFCTE , "_INFCTESUB" ) ) <> 'U'
			_aAux1 := IIf( ValType( XmlChildEx(	_oXML:_INFCTE , "_INFCTESUB"	) ) == "O" , { _oXML:_INFCTE:_INFCTESUB	} , _oXML:_INFCTE:_INFCTESUB	)
		ElseIf ValType( XmlChildEx(	_oXML:_INFCTE , "_INFCTECOMP" ) ) <> 'U'
			_aAux1 := IIf( ValType( XmlChildEx(	_oXML:_INFCTE , "_INFCTECOMP"	) ) == "O" , { _oXML:_INFCTE:_INFCTECOMP	} , _oXML:_INFCTE:_INFCTECOMP	)
		ElseIf ValType( XmlChildEx(	_oXML:_INFCTE , "_INFCTEANU" ) ) <> 'U'
			_aAux1 := IIf( ValType( XmlChildEx(	_oXML:_INFCTE , "_INFCTEANU"	) ) == "O" , { _oXML:_INFCTE:_INFCTEANU	} , _oXML:_INFCTE:_INFCTEANU	)
		EndIf
		
		If !Empty( _aAux1 )
			For _nI := 1 To Len( _aAux1 )
				If ValType(XmlChildEx(_aAux1[_nI],"_CHAVE")) == "O"
					_cChaveNF := PadR( AllTrim( _aAux1[_nI]:_chave:Text ) , TamSX3("F1_CHVNFE")[1] )
				ElseIf ValType(XmlChildEx(_aAux1[_nI],"_CHCTE")) == "O"
					_cChaveNF := PadR( AllTrim( _aAux1[_nI]:_chCTE:Text ) , TamSX3("F1_CHVNFE")[1] )
				EndIf
				//====================================================================================================
				// Se alguma chave estiver referenciada no documento de saída, é um frete sobre venda.
				// Não é necessário se preocupar com a filial nesse PE. Produto 10000000005
				//====================================================================================================
				_cAlias := GetNextAlias()
				BeginSql Alias _cAlias
					SELECT COUNT(1) QTDREG
					  FROM %Table:SF2% SF2
					 WHERE SF2.D_E_L_E_T_ = ' '
					   AND SF2.F2_CHVNFE = %exp:_cChaveNF%
				EndSql
				If (_cAlias)->QTDREG > 0
					_cPrdFrete := _aPrdFrete[1]
					(_cAlias)->(DBCloseArea())
					Exit
				EndIf
				(_cAlias)->(DBCloseArea())
			Next _nI
		EndIf
	EndIf
EndIf

_cPrdFrete := PadR(_cPrdFrete,TamSX3("B1_COD")[1])
FWRestArea(_aArea)

Return _cPrdFrete
