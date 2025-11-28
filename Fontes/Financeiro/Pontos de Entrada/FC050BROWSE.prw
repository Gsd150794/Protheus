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
Programa----------: FC050BROWSE
Autor-------------: Alexandre Villar
Data da Criacao---: 12/06/2014
Descrição---------: P.E. para tratar a inclusão de campos na tela de posição do Contas a Pagar
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function FC050BROWSE

Local aTeste2 := ParamIXB

aAdd( aTeste2 , { 'Vlr. Juros'		, 'E5_VLJUROS'	} )
aAdd( aTeste2 , { 'Vlr. Multa'		, 'E5_VLMULTA'	} )
aAdd( aTeste2 , { 'Vlr. Correção'	, 'E5_VLCORRE'	} )
aAdd( aTeste2 , { 'Vlr. Desconto'	, 'E5_VLDESCO'	} )

Return( aTeste2 )
