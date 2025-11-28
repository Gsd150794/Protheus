/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |01/11/2021| Chamado 37771. Alteracao para deixar o estoque negativo para a filial 40 Operações: 06/10/41
André Lisboa  |08/11/2022| Chamado 41775. Incluir tipo de operação "31" nas permissões de liberar o pedido sem estoque para filial 40
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MTA440L
Autor-----------: Alexandre Villar
Data da Criacao-: 16/07/2015
Descrição-------: P.E. na validação da quantidade disponível em estoque para liberação de pedidos de vendas
				Incrementar o saldo disponível com o estoque em poder de terceiros para as Filiais/Armazens configuradas.
Parametros------: Nenhum
Retorno---------: _nValEst - Valor de estoque disponível em poder de terceiros (valor deve ser negativo para tratativa do P.E.)
===============================================================================================================================
*/
User Function MTA440L

Local _nRet		:= 0
Local _cAlias	:= GetNextAlias()
Local _cFilTer	:= AllTrim(SuperGetMV('IT_EST3FIL',.F.,'')) // Verifica parâmetro de configurações das Filiais que usam estoque em poder de terceiros
Local _cLocTer	:= AllTrim(SuperGetMV('IT_EST3LOC',.F.,'')) // Verifica parâmetro de configurações dos Armazéns que usam estoque em poder de terceiros

//====================================================================================================
// Considera estoque em poder de terceiros apenas nas Filiais/Armazéns configurados
//====================================================================================================
If SC6->C6_FILIAL $ _cFilTer .And. SC6->C6_LOCAL $ _cLocTer
	BeginSql alias _cAlias
		SELECT B2_QNPT
		FROM  %Table:SB2%
		WHERE D_E_L_E_T_ = ' '
		AND B2_FILIAL = %xFilial:SB2%
		AND B2_COD   = %exp:SC6->C6_PRODUTO%
		AND B2_LOCAL = %exp:SC6->C6_LOCAL%
	EndSql

	//====================================================================================================
	// Se tiver saldo em poder de terceiros, devolver valor para ser utilizado na validação de estoque
	//====================================================================================================
	If (_cAlias)->( !Eof() ) .And. (_cAlias)->B2_QNPT > 0
		_nRet := -(_cAlias)->B2_QNPT // O valor deve ser devolvido negativo por tratativas do P.E.
	EndIf
	
	(_cAlias)->(DBCloseArea())
EndIf

If (SC5->C5_FILIAL = "40" .And. SC5->C5_I_OPER $ "06/10/31/41" .And. SC6->C6_LOCAL $ "50/52")
    _nRet :=-10000000
EndIf

Return _nRet
