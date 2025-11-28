/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |09/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F050ATP
Autor-------------: Alexandre Villar
Data da Criacao---: 24/11/2014
Descrição---------: P.E. para validar a natureza e verificar se utiliza tabela de progressiva de IRRF para pessoa física
Parametros--------: Nenhum
Retorno-----------: _lRet -- define se usa tabela progressiva ou configuração da natureza
===============================================================================================================================
*/
User Function F050ATP()

Local _lRet		:= .T.
Local _cNatAux	:= AllTrim( M->E2_NATUREZ )
Local _cNatExc	:= GetMV( 'IT_NATEXCF' ,, '232046' )

_lRet := !( _cNatAux $ _cNatExc )

Return( _lRet )
