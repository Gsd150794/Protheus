/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |02/10/2018| Chamado 26488. Corrigido tratamento para códigos com ponto (.).
Lucas Borges  |20/04/2022| Chamado 39844. Tratamento para XMLs com código do produto minúsculo.
Lucas Borges  |08/04/2024| Chamado 46875. Retirado tratamento para a SA5 pois o padrão trata o cenário.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: A140IPRD
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 14/11/2014
Descrição---------: O Ponto de Entrada A140IPRD é utilizado para manipular produto que será importado na NF-e. Usado quando 
					existem vários códigos do fornecedor para o mesmo produto no Protheus.
Parametros--------: cCodigo: Caracter, Código do fornecedor/cliente.
					cLoja: Caracter, Código da loja do fornecedor/cliente.
					cPrdXML: Caracter, Código do produto contido no arquivo xml.
					oDetItem: Objeto, Objeto contendo a Tag principal: InfNFE /subtag det nItem com os nós referente ao item 
						posicionado no XML recebido de acordo com o Manual de Orientação ao Contribuinte da NFe.
					cAlias: Caracter, Código da tabela "SA5" ou "SA7" para identificar se o código que está vindo como parâmetro
						é de um fornecedor ou de um cliente para os casos de notas do tipo devolução e beneficiamento.
Retorno-----------: cPrdNew: Caracter, Retorna o código do produto da tabela SB1
===============================================================================================================================
*/
User Function A140IPRD

Local _cCodFor	:= ParamIXB[1]
Local _cLoja	:= ParamIXB[2]
Local _cPrdXML	:= ParamIXB[3]
Local _aTab		:= {}
Local _cQuery	:= ''
Local _cRet		:= ''
Local _cAlias	:= GetNextAlias()


aAdd(_aTab,{ParamIXB[5],SubStr(ParamIXB[5],2,2),IIf(ParamIXB[5]=="SA5","A5_FORNECE","A7_CLIENTE"),IIf(ParamIXB[5]=="SA5","A5_CODPRF","A7_CODCLI") })

_cQuery := " SELECT "
_cQuery += "     " + _aTab[1][2]+"_PRODUTO	PRODUTO, "
_cQuery += "     " + _aTab[1][2]+"_I_CDPRX	PRODALT"
_cQuery += " FROM "+ RetSqlName(_aTab[1][1])
_cQuery += " WHERE "
_cQuery += "     D_E_L_E_T_ = ' ' "
_cQuery += " AND "+_aTab[1][2]+"_FILIAL  = '"+ xFilial(_aTab[1][1])	+"' "
_cQuery += " AND "+_aTab[1][3]+" = '"+ _cCodFor			+"' "
_cQuery += " AND "+_aTab[1][2]+"_LOJA    = '"+ _cLoja  			+"' "
_cQuery += " AND REPLACE(Upper("+_aTab[1][4]+"),' ','') = '"+ _cPrdXML			+"' "

DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

_cRet:= (_cAlias)->PRODUTO

(_cAlias)->( DBCloseArea() )

If Empty(_cRet) .And. ParamIXB[5] == "SA7"
	_cPrdXML	:= Upper(StrTran(StrTran(ParamIXB[3]," "),".","\."))	
	_cAlias	:= GetNextAlias()
	
	_cQuery := " SELECT "
	_cQuery += "     " + _aTab[1][2]+"_PRODUTO	PRODUTO, "
	_cQuery += "     " + _aTab[1][2]+"_I_CDPRX	PRODALT"
	_cQuery += " FROM "+ RetSqlName(_aTab[1][1])
	_cQuery += " WHERE "
	_cQuery += "     D_E_L_E_T_ = ' ' "
	_cQuery += " AND "+_aTab[1][2]+"_FILIAL  = '"+ xFilial(_aTab[1][1])	+"' "
	_cQuery += " AND "+_aTab[1][3]+" = '"+ _cCodFor			+"' "
	_cQuery += " AND "+_aTab[1][2]+"_LOJA    = '"+ _cLoja  			+"' "
	_cQuery += " AND REGEXP_LIKE(REPLACE(Upper("+_aTab[1][2]+"_I_CDPRX),' ',''),'^(" + _cPrdXML + ")|([a-zA-Z0-9]/(" + _cPrdXML + "))')"
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry( ,, _cQuery ) , _cAlias , .T. , .F. )

	_cRet := (_cAlias)->PRODUTO

	(_cAlias)->( DBCloseArea() )
EndIf

Return( _cRet )
