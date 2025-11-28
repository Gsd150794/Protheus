/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: FI040MNCP
Autor-------------: Alexandre Villar
Data da Criacao---: 12/06/2014
Descrição---------: P.E. para tratar a inclusão de campos na tela de posição do Contas a Receber
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function FI040MNCP

Local _aCampos := aClone( ParamIXB[01] )

aAdd( _aCampos , { 'Vlr. Juros'		, 'E5_VLJUROS'	} )
aAdd( _aCampos , { 'Vlr. Multa'		, 'E5_VLMULTA'	} )
aAdd( _aCampos , { 'Vlr. Correção'	, 'E5_VLCORRE'	} )
aAdd( _aCampos , { 'Vlr. Desconto'	, 'E5_VLDESCO'	} )

Return( _aCampos )
