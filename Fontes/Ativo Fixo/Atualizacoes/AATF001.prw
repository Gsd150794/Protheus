/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |26/09/2019| Revisão do fonte. Chamado 28346
Lucas Borges  |26/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include 'Protheus.ch'

/*
===============================================================================================================================
Programa----------: AATF001
Autor-------------: Luciana Ribeiro Rosa
Data da Criacao---: 19/08/2008                                    .
Descrição---------: Codificacao de cadastro de ativos fixos para Gerar o campo N1_CBASE de forma automatica.
                    Rotina chamada através do Gatilho := N1_GRUPO - 001.
Parametros--------: _cCod = Grupo de ativo fixo
Retorno-----------: _cRetorno = Retorna codigo para cadastro de produtos		                               				
                    Sendo o codigo do produto composto do grupo mais um numero sequencial de 5 digitos.
===============================================================================================================================
*/
User Function AATF001(_cCod As Character)

Local _aArea    := FWGetArea() As Array
Local _cAlias	:= GetNextAlias() As Character
Local _cRetorno := "" As Character
Local _cCodigo	:= "" As Character

BeginSql alias _cAlias
	SELECT MAX(N1_CBASE) CODIGO
	  FROM %Table:SN1%
	 WHERE D_E_L_E_T_ = ' '
	   AND N1_GRUPO = %exp:AllTrim(_cCod)%
EndSql

_cCodigo := Soma1(Right((_cAlias)->CODIGO,6))
_cRetorno := AllTrim(_cCod)+_cCodigo

While !MayIUseCode( "N1_CBASE"+_cRetorno)	// verifica se esta na memoria, sendo usado e busca o proximo numero disponivel
	_cRetorno := AllTrim(_cCod)+Soma1(_cCodigo)
EndDo

M->N1_ITEM	:= StrZero(1,4)
M->N1_CHAPA	:= _cRetorno + "-" + StrZero(1,4)

(_cAlias)->(DBCloseArea())
FWRestArea(_aArea)

Return(_cRetorno)
