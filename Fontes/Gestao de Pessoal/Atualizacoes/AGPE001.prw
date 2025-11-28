/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |18/09/2019| Chamado 28346. Incluído MenuDef para padronização
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AGPE001
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 10/12/2008
Descrição---------: Cadastro do Pagamentos e Descontos Customizados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGPE001

Private cCadastro	:= "Cad. Pagamentos e Descontos"
Private aRotina		:= MenuDef()
Private cAlias		:= "ZAJ"

mBrowse( 6, 1,22,75,cAlias,,,,,,)

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 18/09/2019
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
					{ "Excluir"			, "AxDeleta"		, 0 , 5 }  }

Return( aRotina )

/*
===============================================================================================================================
Programa----------: GerMnem
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 11/12/2008
Descrição---------: Função chamada no mnemonico buscando dados do cadastro para avaliar a geracao da verba
Parametros--------: Codigo -> vide cadastro ZAJ
					Tipo de Pagamento/Desconto -> Hora / Valor / Percentual / Dia
					Info para geracao: 	1 -> buscar configuracao para calculo
										2 -> buscar data para pagamento
					Caso haja mais de um retorno para um mesmo tipo de pagto/desconto
										-> Informar as possiveis respostas separadas por "/"
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function GerMnem(cCod, cTipo, nFlag, nPos )

Local aArea	:= FWGetArea()
Local cCont	:= ""
Local aAux	:= {}
Local cTemp	:= ""
Local uRet	:= 0
Local _nX	:= 0

DBSelectArea("ZAJ")
ZAJ->(DBSetOrder(1))

If ( nFlag == 1)
	uRet := 0
	If ZAJ->(DBSeek(xFilial("ZAJ") + cCod + cTipo))
		cCont := ZAJ->ZAJ_CONTEU
	EndIf
	
	If ( nPos < 1 )
		uRet := Val(cCont)
	Else
		For _nX := 1 to Len(cCont)
			If ( SubStr(cCont,_nX,1) == "/" )
				aAdd(aAux, cTemp)
				cTemp := ""
			Else
				cTemp += SubStr(cCont,_nX,1)
				
				If ( _nX == Len(cCont) )
					aAdd(aAux, cTemp)
					cTemp := ""
				EndIf
			EndIf	
		Next _nX
			
		If ( nPos <= Len(aAux) )
			uRet := Val( aAux[nPos] )
		EndIf
	EndIf
Else
	If ( DBSeek(xFilial("ZAJ")+cCod) )
		If ( ZAJ->ZAJ_REPEAT == "S")
			uRet := DToS(dDataBase)
		Else
			uRet := DToS(ZAJ->ZAJ_REFERE)
		EndIf
	EndIf
EndIf
	
FWRestArea(aArea)
	
Return uRet
