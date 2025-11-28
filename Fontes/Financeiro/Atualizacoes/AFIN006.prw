/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |07/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
Lucas Borges  |09/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN006
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 05/09/2008
Descrição---------: Validar qual supervisor esta amarrado no vendedor preenchido na Regra de Comissao. 
                    Validar se vendedor selecionado possui supervisor ou gerente.
                    Funcao chamada na Consulta Padrao: SA3_01 e SA3_02.   
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AFIN006(_nTipo)

Local _aArea 	:= FWGetArea()
Local _cRet		:= "ZZZZZZ"
Local _cCampo	:= "% " + IIf(_nTipo == 1,"A3_GEREN","A3_SUPER") + " %"

BeginSql alias _cAlias
	SELECT %exp:_cCampo%
	  FROM %Table:SA3%
	 WHERE A3_COD = %exp:cCodVend%
	   AND D_E_L_E_T_ = ' '
EndSql

If (_cAlias)->(!Eof())
	_cRet := (_cAlias)->A3_SUPER
EndIf

(_cAlias)->(DBCloseArea())
FWRestArea(_aArea)

Return _cRet
