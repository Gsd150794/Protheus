/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alexandre V.  |13/03/2015| Chamado 9378. Conforme solicitação foi feito o ajuste para a validação da quantidade ficar com 
              |          | '== 0' ao invés de '< 0'.
Lucas Borges  |10/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST040
Autor-------------: Lucas Crevilari
Data da Criacao---: 10/09/2014
Descrição---------: Verifica se existe saldo de empenho para a OP
Parametros--------:
Retorno-----------:
===============================================================================================================================
*/               
User Function AEST040(_cOP)
      
Local _aArea	:= FWGetArea()
Local _lOk 		:= .T.
Local _cAlias	:= GetNextAlias()

Default _cOP := ''

_cOp := AllTrim(_cOp)

BeginSql alias _cAlias
	SELECT D4_QUANT FROM %Table:SD4% 
	WHERE D_E_L_E_T_ = ' ' AND D4_FILIAL = %xFilial:SD4% AND D4_OP = %exp:_cOP%
EndSql

If (_cAlias)->(!Eof())
	If (_cAlias)->D4_QUANT == 0
		FWAlertWarning('Não existe saldo nos empenhos para essa OP! Verifique os saldos dos Empenhos. Sem Saldo','AEST04001')
		_lOk := .F.
	EndIf 
Else
	FWAlertWarning('Não foi encontrada a Requisição de Empenho com o código de OP informado ['+ _cOp +']!', 'AEST04002')
	_lOk := .F.
EndIf

(_cAlias)->( DBCloseArea() )

FWRestArea(_aArea)

Return(_lOk)
