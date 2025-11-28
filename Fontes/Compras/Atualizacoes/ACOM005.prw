/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |17/07/2017| Chamado 20777. Virada de versão da P11 para a versão P12. Ajustes no fonte para a versão P12
Lucas Borges  |11/03/2022| Chamado 39460. Incluído tratamento para Z-Plataformas
Lucas Borges  |09/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACOM005
Autor-------------: Cleiton Campos
Data da Criacao---: 14/07/2008                                  .
Descrição---------: Codificação do Cadastro de Fornecedores
Parametros--------: _pcClasse = Devera ser passado o conteudo do campo A2_I_CLASS.
                    _pcTipo   = Devera ser passado o conteudo do campo A2_TIPO.
                    _pcCGC    = Devera ser passado o conteudo do campo A2_CGC.
Retorno-----------: _cRet     = Código que deverá ser gravado no campo A2_COD.
===============================================================================================================================
*/
User Function ACOM005( _pcClasse , _pcTipo , _pcCGC )

Local _aArea    := FWGetArea()
Local _cAlias	:= GetNextAlias()
Local _cQuery   := ""
Local _cCodigo  := ""

Local _lNew		:= .F.
Local _lTemCod	:= .F.

_cQuery := " SELECT DISTINCT A2_COD AS CODIGO "
_cQuery += " FROM  "+ RetSqlName("SA2") +" SA2 "
_cQuery += " WHERE "+ RetSqlCond("SA2")

If AllTrim(_pcTipo) == "J" .And. _pcClasse == 'Z'
	_cQuery += " AND LTrim(RTrim(A2_CGC)) = '"+ AllTrim(_pcCGC) +"' AND A2_TIPO = 'J'"
ElseIf AllTrim(_pcTipo) == "J"
	_cQuery += " AND SubStr( A2_CGC , 1 , 8 ) = '"+ Left( _pcCGC , 8 ) +"' AND A2_TIPO = 'J' "
Else
	_cQuery += " AND LTrim(RTrim(A2_CGC)) = '"+ AllTrim(_pcCGC) +"' AND A2_TIPO = 'F'"
EndIf

_cQuery := ChangeQuery(_cQuery)
MPSysOpenQuery(_cQuery,_cAlias)

(_cAlias)->( DBGoTop() )
If (_cAlias)->( !Eof() )

	While (_cAlias)->( !Eof() )
		
		If !Empty( (_cAlias)->CODIGO )
		
			If SubStr( (_cAlias)->CODIGO , 1 , 1 ) == AllTrim( _pcClasse ) // validar se ja existe codigo para a classe
				_cCodigo := (_cAlias)->CODIGO
			EndIf
			
			_lTemCod := .T.
			
		EndIf
		
	(_cAlias)->( DBSkip() )
	EndDo
	
	If _lTemCod .And. Empty(_cCodigo)
	
		If MsgYesNo(	" Este "+ IIf(AllTrim(_pcTipo)=="J","CNPF","CPF") +'/'+ AllTrim(_pcCGC) +" ja foi cadastrado para um fornecedor, "	+;
						" porem este fornecedor possui outra classe." + Chr(13) + Chr(10)													+;
						" Se deseja criar este fornecedor utilizando a nova classe, tecle SIM. Caso contrario, se desejar manter"			+;
						" a mesma codificação utilizada na outra classe, tecle NÃO.", "Codificação de Fornecedor"							 )
			
			_lNew := .T.
		
		EndIf
	
	Else
	
		_lNew := !_lTemCod
	
	EndIf

Else

	_lNew := .T.
	
EndIf

(_cAlias)->( DBCloseArea() )

If _lNew

	_cQuery := " SELECT MAX(SA2.A2_COD) AS CODIGO "
	_cQuery += " FROM  "+ RetSqlName("SA2") +" SA2 "
	_cQuery += " WHERE "+ RetSqlCond("SA2")
	_cQuery += " AND SubStr( SA2.A2_COD , 1 , 1 ) = '"+ AllTrim(_pcClasse) +"' "
	_cQuery := ChangeQuery(_cQuery)
	MPSysOpenQuery(_cQuery,_cAlias)
	
	(_cAlias)->( DBGoTop() )
	
	_cCodigo := AllTrim(_pcClasse) + Soma1(   Right( (_cAlias)->CODIGO , 5 )  )  
	
	(_cAlias)->( DBCloseArea() )

EndIf

While !MayIUseCode( "A2_COD"+ xFilial("SA2") + _cCodigo )	// verifica se esta na memoria, sendo usado
	_cCodigo := AllTrim(_pcClasse) + Soma1(   Right( _cCodigo , 5 )  )  							// busca o proximo numero disponivel
EndDo

//======================================================================
// Grava log de acesso a rotina Cadastro de Fornecedores. 
// Geração do código do fornecedor.
//====================================================================== 
U_ITLOGACS('ACOM005')

FWRestArea(_aArea)

Return(_cCodigo)
