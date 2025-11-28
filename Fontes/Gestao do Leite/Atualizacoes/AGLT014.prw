/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |03/08/2018| Chamado 25767. Incluído MenuDef para padronização
Lucas Borges  |29/06/2021| Chamado 37004. Criada função para replicar cadastro para outras filiais.
Lucas Borges  |29/12/2022| Chamado 42208. Tratamento para incluir mais de 999 faixas.
===============================================================================================================================
*/

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Programa----------: AGLT014
Autor-------------: Wodson Reis
Data da Criacao---: 02/10/2008
Descrição---------: Rotina desenvolvida para possibilitar o cadastramento de Faixas de Analises do Leite Toda Faixa de Analise 
					possui um codigo de Tipo de Analise, as faixas sao utilizadas para bonificar ou penalizar os produtores de 
					acordo com a Analise de Qualidade do Leite.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT014

Private cCadastro	:= "Cadastro Faixas de Analise"
Private aRotina		:= MenuDef()
Private cAlias		:= "ZLA"

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
					{ "Excluir"			, "AxDeleta"		, 0 , 5 } ,;
					{ "Replicar Filiais", "U_AGLT014R"		, 0 , 4 }  }

Return( aRotina )

/*
===============================================================================================================================
Programa----------: AGLT014R
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 29/06/2021
Descrição---------: Função usada para replicar o evento para todas as filiais
Parametros--------: cAlias,nReg,nOpc
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT014R(cAlias,nReg,nOpc)

Local _aArea	:= FWGetArea()
Local _aSelFil	:= AdmGetFil(.F.,.F.,cAlias)
Local _nX, _nI	:= 0
Local _aFields	:= FWSX3Util():GetAllFields( cAlias , .F. )
Local _aOrig	:= {}
Local _lRet		:= .F.
Local _cAlias	:= GetNextAlias()
If Len(_aSelFil) > 0
	//Adiciono todos os campos no array
	For _nX	:= 1 To Len(_aFields)
		aAdd(_aOrig,&(_aFields[_nX]))
	Next _nX
	_cCampos := "% " + Replace(Replace(AsString(_aFields),"{",""),"}","") + " %"
	BeginSql alias _cAlias
		SELECT ZL2_DESCRI, %exp:_cCampos% FROM %Table:ZLA% ZLA, %Table:ZL2% ZL2
		WHERE ZLA.D_E_L_E_T_ = ' '
		AND ZL2.D_E_L_E_T_ = ' '
		AND ZL2_FILIAL = ZLA_FILIAL
		AND ZL2_COD = ZLA_SETOR
		AND ZLA_FILIAL = %exp:ZLA->ZLA_FILIAL%
		AND ZLA_SETOR = %exp:ZLA->ZLA_SETOR%
		AND ZLA_COD = %exp:ZLA->ZLA_COD%
	EndSql
	DBSelectArea("ZL2")
	ZL2->(DBSetOrder(1))

	For _nX := 1 To Len(_aSelFil)
		If ZL2->(DBSeek(_aSelFil[_nX]))
			While ZL2->(!Eof()) .And. ZL2->ZL2_FILIAL == _aSelFil[_nX]
				(_cAlias)->(DBGoTop())
				While (_cAlias)->(!Eof())
					If !(cAlias)->(DBSeek(_aSelFil[_nX] + ZL2->ZL2_COD + (_cAlias)->(ZLA_COD+ZLA_SEQ)))
						(cAlias)->(RecLock(cAlias, .T.))
							For _nI := 1 To Len(_aFields)
								If "FILIAL" $ _aFields[_nI]
									(cAlias)->&(_aFields[_nI]) := _aSelFil[_nX]
								ElseIf "SETOR" $ _aFields[_nI]
									(cAlias)->&(_aFields[_nI]) := ZL2->ZL2_COD
								ElseIf "DCRSET" $ _aFields[_nI]
									(cAlias)->&(_aFields[_nI]) := (_cAlias)->ZL2_DESCRI
								Else
									(cAlias)->&(_aFields[_nI]) := (_cAlias)->&(_aFields[_nI])
								EndIf
							Next _nI
						(cAlias)->(MSUnLock())
						_lRet := .T.
					EndIf
					(_cAlias)->(DBSkip())
				EndDo
				ZL2->(DBSkip())
			EndDo
		EndIf
	Next _nX
EndIf

If _lRet
	MsgInfo("Registro replicado para as filiais selecionadas que não possuiam o registro.","AGLT01401")
Else
	MsgAlert("Não foram identificadas filiais aptas para a réplica do registro.","AGLT01402")
EndIf

FWRestArea(_aArea)
Return

/*
===============================================================================================================================
Programa----------: AGLT014S
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 26/12/2022
Descrição---------: Gera próximo sequencial na ZLA. Utilizado no gatilho do ZLA_COD -> ZLA_SEQ
Parametros--------: _cFilial, _cSetor, _cCod
Retorno-----------: _cSeq
===============================================================================================================================
*/
User Function AGLT014S(_cFilial, _cSetor, _cCod)

Local _aArea	:= FWGetArea()
Local _cSeq		:= ""
Local _cAlias	:= GetNextAlias()

BeginSql alias _cAlias
	SELECT NVL(MAX(ZLA_SEQ),'0000') SEQ
	  FROM %Table:ZLA%
	 WHERE D_E_L_E_T_ = ' '
	   AND ZLA_FILIAL = %exp:_cFilial%
	   AND ZLA_SETOR = %exp:_cSetor%
	   AND ZLA_COD = %exp:_cCod%
EndSql

_cSeq := Soma1((_cAlias)->SEQ)
(_cAlias)->(DBCloseArea())

FWRestArea(_aArea)

Return(_cSeq)
