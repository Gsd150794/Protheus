/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 06/09/2017 | Usa __cUserId quando possível - Chamado 21323
 Jose Gavetti     |  27/11/2025| Chamado 53163. Correção Problema de Gravaçao Alt/Desmembramento PV via WS do RDC 
=============================================================================================================================== 
*/
#Include "TOTVS.ch"  


/*
===============================================================================================================================
Programa----------: MT410ALT
Autor-------------: Alexandre Villar
Data da Criacao---: 24/02/2014
===============================================================================================================================
Descrição---------: Ponto de entrada antes de operações de Exclusão/Cópia/Alteração no Pedido de Vendas para validar acesso
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function MT410ALT()

Local _aDadAux	:= {}
Local _cCodUsr	:= RetCodUsr()

//Se tiver a variável __cUserId válida usa ao invés da função RetCodUsr para funcionar com os webservices
If Type('__cUserId') == 'C'
	_cCodUsr := __cUserId
EndIf	

If Type("_cCodUsuario") = "C" .And. !Empty(_cCodUsuario)
	_cCodUsr := _cCodUsuario
EndIf

If Type('_cActLog') == 'C' .And. !Empty(_cActLog)
	
	If _cActLog == 'A'
		
		If Type('_aLogSC5') == 'A' .And. !Empty( _aLogSC5 )
			U_ITGrvLog( _aLogSC5 , "SC5" , 1 , SC5->( C5_FILIAL + C5_NUM ) , _cActLog , _cCodUsr , _dDtLgC5 , _cTmLgC5 )
		EndIf
		
		If Type('_aLogSC6') == 'A' .And. !Empty( _aLogSC6 )
			U_ITGrvLog( _aLogSC6 , "SC6" , 1 , SC5->( C5_FILIAL + C5_NUM ) , _cActLog , _cCodUsr , _dDtLgC5 , _cTmLgC5 )
		EndIf
	
	Else
		
		aAdd( _aDadAux , { 'C5_FILIAL'	, SC5->C5_FILIAL	, ''		} )
		aAdd( _aDadAux , { 'C5_NUM'		, SC5->C5_NUM		, ''		} )
		aAdd( _aDadAux , { 'C5_CLIENTE'	, SC5->C5_CLIENTE	, ''		} )
		aAdd( _aDadAux , { 'C5_LOJACLI'	, SC5->C5_LOJACLI	, ''		} )
		aAdd( _aDadAux , { 'C5_EMISSAO'	, SC5->C5_EMISSAO	, SToD('')	} )
		aAdd( _aDadAux , { 'C5_I_DTENT'	, SC5->C5_I_DTENT	, SToD('')	} )
		
		U_ITGrvLog( _aDadAux , "SC5" , 1 , SC5->( C5_FILIAL + C5_NUM ) , _cActLog , _cCodUsr , _dDtLgC5 , _cTmLgC5 )
		
	EndIf
	
EndIf

_aLogSC5 := {}
_aLogSC6 := {}
_cActLog := ''

Return
