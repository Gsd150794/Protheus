/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges      | 15/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: AOMS053
Autor-----------: Fabiano Dias da Silva
Data da Criacao-: 08/08/2011
===============================================================================================================================
Descrição-------: Cadastro de Filiais para uso via Schedule(JOB), pelo fato do uso do schedule ter que estar uma empresa e filial
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS053()

	Local cVldAlt := "U_VLDINCZZM()" // Validacao para permitir a inclusao. Pode-se utilizar ExecBlock.
	Local cVldExc := ".T." // Validacao para permitir a exclusao. Pode-se utilizar ExecBlock.
	
	Private cString := "ZZM"
	
	DBSelectArea(cString)
	DBSetOrder(1)
	
	AxCadastro(cString,"Cadastro de Filiais",cVldExc,cVldAlt)

Return

/*
===============================================================================================================================
Programa--------: VLDINCZZMº
Autor-----------: Fabiano Dias da Silva
Data da Criacao-: 15/09/2011
===============================================================================================================================
Descrição-------: Funcao para realizar a validacao da inclusao de uma nova filial
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function VLDINCZZM()  

Local _cFiltro:= "%"
Local _cAlias := "" 

Local _lRet   := .T.

If Inclui
     
	_cAlias:= GetNextAlias()

	_cFiltro += " AND ZZM_CODIGO = '" + M->ZZM_CODIGO + "'"                            
	_cFiltro += "%"

	BeginSql alias _cAlias	
		SELECT
	      COUNT(*) NUMREG
		FROM
		      %Table:ZZM%
		WHERE
		      D_E_L_E_T_ = ' '
		      %Exp:_cFiltro%	
	EndSql

	DBSelectArea(_cAlias)           
	(_cAlias)->(DBGoTop())
	
	If (_cAlias)->NUMREG > 0
	   
		MsgAlert("Ja existe uma filial cadastrada no sistema com o codigo: " + M->ZZM_CODIGO,"AOMS05301")
		_lRet   := .F.
	
	EndIf
	
	DBSelectArea(_cAlias)           
	(_cAlias)->(DBCloseArea())

EndIf

Return _lRet
