/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges  |26/09/2019| Chamado 28346. Revisão do fonte
Lucas Borges  |26/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AATF002
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 15/11/2008                                     .
Descrição---------: Gerar Codificacao automatica do ITEM, com base o Codigo do Bem. Gerar o campo N1_ITEM de forma automatica. 
                    Rotina acionada através do Gatilho := N1_CBASE - 001.
Parametros--------: _cCod = Grupo de ativo fixo	
Retorno-----------: _cRetorno = Retorna codigo do Item
===============================================================================================================================
*/
User Function AATF002(_cCod As Character)

Local _aArea    := FWGetArea() As Array
Local _cAlias	:= GetNextAlias() As Character
Local _cRetorno := '' As Character

BeginSql alias _cAlias
	SELECT MAX(N1_ITEM) CODIGO
	  FROM %Table:SN1%
	 WHERE D_E_L_E_T_ = ' '
	   AND N1_CBASE = %exp:AllTrim(_cCod)%
EndSql
_cRetorno := Soma1((_cAlias)->CODIGO)
M->N1_CHAPA	:= _cCod + "-" + _cRetorno

(_cAlias)->(DBCloseArea())	
FWRestArea(_aArea)

Return(_cRetorno)
