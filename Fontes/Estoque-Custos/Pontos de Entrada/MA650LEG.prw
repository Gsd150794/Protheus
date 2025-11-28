/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Jonathan      |17/08/2020| Chamado 33840. Correção de error log
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MA650LEG
Autor-------------: Alexandre Villar
Data da Criacao---: 25/09/2014
Descrição---------: Rotina para manutenção da legenda da tela de Ordem de Produção
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MA650LEG()

Local _aCorAux  := aClone( ParamIXB ) //Recupera Conteúdo da Legenda Padrão
Local _nPosAux	:= aScan( _aCorAux[1] , {|x| x[2] == 'BR_VERDE' } )

If _nPosAux > 0
	_aCorAux[01][_nPosAux][01] += ' .And. SC2->C2_STATUS <> "U" '
EndIf

aAdd( _aCorAux[1] , { ' SC2->C2_STATUS == "U" ' , 'BR_PRETO' , 'Suspensa' } )

Return( _aCorAux[1] )
