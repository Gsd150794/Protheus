/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACOM040
Autor-------------: Igor Melgaço
Data da Criacao---: 22/03/2023
Descrição---------: Validação de campos do Cadastro de Indicador de Produto Mod. 2 - Chamado 41686
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM040

Local lReturn  := .T.
Local nPosOrig := GDFieldPos("BZ_ORIGEM") 
Local nPosFCI  := GDFieldPos("BZ_I_FCICO") 
Local cVar     := ReadVar()

Do Case
	Case cVar == "M->BZ_I_FCICO"

		If !Empty(AllTrim(aCols[n][nPosFCI] ))
			If aCols[n][nPosOrig] == '0' .Or. Empty(AllTrim(aCols[n][nPosOrig]))
				lReturn := .F.
				U_ITMsg("Para preencher o código da FCI, o conteudo do campo Origem deve ser diferente de 0 - Nacional.","Atenção","Para operaçoes de produtos com  conteudo de importação a origem deve conter um destes valores 1, 2, 3, 4, 5, 6 ou 8",2,,,.T.)
			EndIf
		EndIf
	
	Case cVar == "M->BZ_ORIGEM"

		If !Empty(AllTrim(aCols[n][nPosFCI]))
			If aCols[n][nPosOrig] == '0' .Or. Empty(AllTrim(aCols[n][nPosOrig]))
				lReturn := .F.
				U_ITMsg("Não é permitido colocar origem zero enquanto houver informação preenchida no campo Código FCI.","Atenção","Apague o código da FCI ou informe uma origem compativel com o conteúdo de importação.",2,,,.T.)
			EndIf
		EndIf
EndCase

Return lReturn
