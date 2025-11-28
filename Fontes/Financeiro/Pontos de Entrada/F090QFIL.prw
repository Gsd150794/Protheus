/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F090QFIL
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 21/12/2017
Descrição---------: Ponto de entrada para retornar a cláusula Where para a query que filtra os registros da SE2 para a seleção 
					na rotina FINA090 em substituição do ponto de entrada F090AFIL.
Parametros--------: ParamIXB[1] -> cláusula Where atual da rotina
Retorno-----------: cFiltro -> Caracter -> Sintaxe da cláusula WHERE (SQL) que será utilizado para filtrar os registros para 
					seleção para a baixa automática -> Obrigatório
===============================================================================================================================
*/
User Function F090QFIL()

Local _cFiltro   := ParamIXB[1]     
Local _cPerg	:= 'FIN090ITA'
Local _aParam	:= {}

//Salva parâmetros utilizados na rotina padrão
aAdd( _aParam , MV_PAR01 )
aAdd( _aParam , MV_PAR02 )
aAdd( _aParam , MV_PAR03 )
aAdd( _aParam , MV_PAR04 )
aAdd( _aParam , MV_PAR05 )
aAdd( _aParam , MV_PAR06 )

If Pergunte( _cPerg )

	_cFiltro += " AND E2_FORNECE BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR03 + "'" 
	_cFiltro += " AND E2_LOJA BETWEEN '" + MV_PAR02 + "' AND '" + MV_PAR04 + "'"
	_cFiltro += " AND E2_NATUREZ BETWEEN '" + MV_PAR05 + "' AND '" + MV_PAR06 + "'"

EndIf

//Restaura parâmetros utilizados na rotina padrão
MV_PAR01 := _aParam[1]
MV_PAR02 := _aParam[2]
MV_PAR03 := _aParam[3]
MV_PAR04 := _aParam[4]
MV_PAR05 := _aParam[5]
MV_PAR06 := _aParam[6]

Return _cFiltro
