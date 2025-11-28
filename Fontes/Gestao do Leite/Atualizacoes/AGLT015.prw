/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |06/02/2020| Chamado 31927. Corrigido nome da tabela na função AGLT015T.
Lucas Borges  |21/07/2021| Chamado 37147. Melhorada a exclusão dos movimentos importados.
Lucas Borges  |05/08/2021| Chamado 37381. Corrigida validação de exclusão.
===============================================================================================================================
*/

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Programa----------: AGLT015
Autor-------------: Wodson Reis
Data da Criacao---: 12/09/2008
Descrição---------: Rotina desenvolvida para possibilitar o cadastramento de Análise de Qualidade utilizados na coleta de
					leite nos retiros.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT015

Private cCadastro	:= "Cadastro Analise da Qualidade"
Private aRotina		:= MenuDef()
Private cAlias		:= "ZLB"

mBrowse( 6, 1,22,75,cAlias,,,,,,)

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 02/08/2018
Descrição---------: Utilizacao de Menu Funcional
Parametros--------: aRotina
					1. Nome a aparecer no cabecalho
					2. Nome da Rotina associada
					3. Reservado
					4. Tipo de Transa‡„o a ser efetuada:
						1 - Pesquisa e Posiciona em um Banco de Dados
						2 - Simplesmente Mostra os Campos
						3 - Inclui registros no Bancos de Dados
						4 - Altera o registro corrente
						5 - Remove o registro corrente do Banco de Dados
						6 - Altera determinados campos sem incluir novos Regs
					5. Nivel de acesso
					6. Habilita Menu Funcional
Retorno-----------: Array com opcoes da rotina
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina := {	{ "Pesquisar"		, "AxPesqui" 		, 0 , 1 } ,;
					{ "Visualizar"		, "AxVisual" 		, 0 , 2 } ,;
					{ "Incluir"			, "AxInclui" 		, 0 , 3 } ,;
					{ "Alterar"			, "AxAltera" 		, 0 , 4 } ,;
					{ "Excluir"			, "U_AGLT015E" 		, 0 , 5 } ,;
					{ "Excluir Todos"	, "U_AGLT015T"		, 0 , 2 }  }

Return( aRotina )

/*
===============================================================================================================================
Programa----------: AGLT015E
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 08/08/2018
Descrição---------: Funcao usada para apagar todos os registro da ZLB
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT015E(cAlias,nReg,nOpc)
Local bAxParam 	:= {|| .T.}
Local bVldExc	:= {|| chkZLF(ZLB->ZLB_SETOR,ZLB->ZLB_LINROT,ZLB->ZLB_RETIRO,ZLB->ZLB_RETIRO,ZLB->ZLB_RETILJ,ZLB->ZLB_RETILJ,ZLB->ZLB_DATA,ZLB->ZLB_DATA)}

AxDeleta(cAlias,nReg,nOpc,/*cTransact*/,/*aCpos*/,/*aButtons*/,{bAxParam,bVldExc,bAxParam,bAxParam},/*aAuto*/,/*lMaximized*/)

Return

/*
===============================================================================================================================
Programa----------: chkZLF
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 20/07/2018
Descrição---------: Valida se já foram gerados eventos no MIX de acordo com os parâmetros passados
Parametros--------: _cSetor,_cLinha,_cForIni,_cForFim,_cLojaIni,_cLojaFim,_dDtIni,_dDtFim
Retorno-----------: _lRet -> L -> .T. - Não encontrou registros que impedem a exclusão - .F. - Encontrou registros que impedem
===============================================================================================================================
*/
Static Function chkZLF(_cSetor,_cLinha,_cForIni,_cForFim,_cLojaIni,_cLojaFim,_dDtIni,_dDtFim)

Local _lRet := .T.
Local _cAlias	:= GetNextAlias()
Local _cFiltro := "% "
If !Empty(_cSetor)
	_cFiltro+=" AND ZLF_SETOR IN " + FormatIn( AllTrim(_cSetor) , ';' )
EndIf
If !Empty(_cLinha)
	_cFiltro+=" AND ZLF_LINROT IN " + FormatIn( AllTrim(_cLinha) , ';' )
EndIf
_cFiltro += " %"
BeginSql alias _cAlias
	SELECT COUNT(1) QTD
	FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
	WHERE ZLF.D_E_L_E_T_ = ' '
	AND ZL8.D_E_L_E_T_ = ' '
	AND ZLF.ZLF_FILIAL = ZL8.ZL8_FILIAL
	AND ZLF.ZLF_EVENTO = ZL8.ZL8_COD
	AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
	AND ZL8.ZL8_COMPGT <> 'S'
	AND ZL8.ZL8_ADICOM <> 'S'
	%exp:_cFiltro%
	AND ZLF_A2COD BETWEEN %exp:_cForIni% AND %exp:_cForFim%
	AND ZLF_A2LOJA BETWEEN %exp:_cLojaIni% AND %exp:_cLojaFim%
	AND %exp:_dDtIni% >= ZLF_DTINI
	AND %exp:_dDtFim% <= ZLF_DTFIM
	AND ZLF_DTCALC >= ZLF_DTFIM
EndSql

If (_cAlias)->QTD > 0
	_lRet := .F.
	MsgStop("Foram identificados no MIX, eventos gerados para o período em questão de acordo com os parâmetros informados. A exclusão não será realizada.","AGLT01501")
EndIf

(_cAlias)->( DBCloseArea() )
Return(_lRet)

/*
===============================================================================================================================
Programa----------: AGLT015T
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 08/08/2018
Descrição---------: Funcao usada para apagar todos os registro da ZLB conforme parâmetros
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT015T

Local _cQuery	:= ""
Local _cFiltro	:= "% "
Local _cAlias	:= GetNextAlias()

If !Pergunte("AGLT015",.T.)
	Return                                        
EndIf                                             

_cFiltro+=" AND ZLB_FILIAL = '" + xFilial("ZLB") + "'"
_cFiltro+=" AND ZLB_RETIRO BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR05 + "' "
_cFiltro+=" AND ZLB_RETILJ BETWEEN '" + MV_PAR06 + "' AND '" + MV_PAR07 + "' "
_cFiltro+=" AND ZLB_DATA BETWEEN '" + DToS(MV_PAR09) + "' AND '" + DToS(MV_PAR10) + "' "
If !Empty(MV_PAR01)
	_cFiltro+=" AND ZLB_LAUDO = '" + MV_PAR01 + "'"
EndIf
If !Empty(MV_PAR02)
	_cFiltro+=" AND ZLB_SETOR IN " + FormatIn( AllTrim(MV_PAR02) , ';' )
EndIf
If !Empty(MV_PAR03)
	_cFiltro+=" AND ZLB_LINROT IN " + FormatIn( AllTrim(MV_PAR03) , ';' )
EndIf
If !Empty(MV_PAR08)
	_cFiltro += " AND ZLB_TIPOFX IN "+ FormatIn( AllTrim(MV_PAR08) , ';' )
EndIf
_cFiltro += " %"

BeginSql alias _cAlias
	SELECT COUNT(1) QTD FROM %Table:ZLB%
	WHERE D_E_L_E_T_ = ' '
	%exp:_cFiltro%
EndSql

If (_cAlias)->QTD == 0
	MsgAlert("Nao foram localizados registros de acordo com os parâmetros informados. Verifique!","AGLT01502")
ElseIf chkZLF(MV_PAR02, MV_PAR03, MV_PAR04, MV_PAR05, MV_PAR06, MV_PAR07, MV_PAR09, MV_PAR10)
	If MsgYesNo("Serão apagados "+AllTrim(Str((_cAlias)->QTD))+" registros. Deseja continuar?","AGLT01503")
		_cQuery:=" UPDATE "+ RetSQLName("ZLB")
		_cQuery+=" SET D_E_L_E_T_ = '*'"
		_cQuery+=" WHERE D_E_L_E_T_ = ' ' "
		_cQuery+= StrTran(_cFiltro,"%","")
		If TCSqlExec( _cQuery ) < 0
			MsgStop( "Erro ao atualizar Registros: "+AllTrim(TCSQLError()),"AGLT01504")
		Else
			MsgInfo("Registros excluídos com sucesso!","AGLT01505")
		EndIf
	Else
		MsgAlert("Operação abortada!","AGLT01506")
	EndIf
EndIf
(_cAlias)->(DBCloseArea())

Return
