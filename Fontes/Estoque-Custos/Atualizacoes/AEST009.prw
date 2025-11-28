/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |10/09/2024| Chamado 48465. Removendo warning de compilação.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST009
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 28/08/2008
Descrição---------: Validar se campo SB1->B1_LOCPAD pode ser editavel. Se produto possuir movimentacao na SB2, nao deixar 
					alterar o Armazem
Parametros--------: Nenhum
Retorno-----------: .T. se pode alterar o armazem do produto - .F. se nao pode alterar o armazem do produto
===============================================================================================================================
*/
User Function AEST009

Local _aArea 	:= FWGetArea()
Local _lRet		:= .F.
Local _cAlias	:= GetNextAlias()

BeginSql alias _cAlias
	SELECT COUNT(1) QTD FROM %Table:SB2% 
	WHERE D_E_L_E_T_ = ' ' AND B2_COD = %exp:M->B1_COD% AND  B2_LOCAL = %exp:M->B1_LOCPAD%
EndSql

If (_cAlias)->QTD == 0
	_lRet	:= .T.
EndIf

(_cAlias)->(DBCloseArea())
FWRestArea(_aArea)

Return _lRet
