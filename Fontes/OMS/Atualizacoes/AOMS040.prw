/*
======================================================================================================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
======================================================================================================================================================================================================
 Analista     - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
======================================================================================================================================================================================================
 Jerry        - Alex Wallauer - 18/12/24 - 05/08/25 - 37652   - Acerto para sempre fechar os Alias dos Selects das 2 funções.
======================================================================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "RwMake.ch"

/*
===============================================================================================================================
Programa--------: AOMS040
Autor-----------: Fabiano Dias
Data da Criacao-: 21/06/2010
Descrição-------: Funcao utilizada para identificar se determinado cliente e loja possui acordo comercial
Parametros------: cCodclient , cLojacli
Retorno---------: .T. ou .F.
===============================================================================================================================
*/
User Function AOMS040(cCodclient As char,cLojacli As char) As logical

	Local cQuery    As Char
	Local cAliasSC5 As Char
	Local nreg      As Numeric
	Local lRetorno  As Logical
	Local lcontrato As Logical
	Local aGetArea  As Array
	aGetArea := FWGetArea()
	cAliasSC5:= GetNextAlias()
	cQuery   := ""
	nreg     := 0
	lRetorno := .F.
	lcontrato:= .F.

	//Verifica se o codigo e a loja do cliente foram informados
	If Len(AllTrim(cCodclient)) > 0 .And. Len(AllTrim(cLojacli)) > 0

		cQuery := "SELECT ZAZ_COD,ZAZ_LOJA,ZAZ_STATUS,ZAZ_DTFIM"
		cQuery += " FROM " + RetSqlName("ZAZ")
		cQuery += " WHERE D_E_L_E_T_  = ' '  AND ZAZ_FILIAL = '" + xFilial("ZAZ") + "'"
		cQuery += " AND ZAZ_CLIENT = '" + cCodclient + "'"
		cQuery += " AND ZAZ_MSBLQL = '2'"

		MPSysOpenQuery( cQuery , cAliasSC5)
		DBSelectArea(cAliasSC5)//NÃO TIRAR
		Count to nreg
		//Contabiliza o numero de registros encontrados pela query

		(cAliasSC5)->(DBGoTop())

		//Se encontrar um contrato nao bloqueado para um cliente sem considerar a loja, caso ela tenha sido especificada no contrato
		//If !Empty(TMP10->ZAZ_COD)
		If nreg > 0

			While (cAliasSC5)->(!Eof())

				If !Empty((cAliasSC5)->ZAZ_LOJA)
					//Verifica se a loja informada no contrato e a mesma loja informada no pedido
					If (cAliasSC5)->ZAZ_LOJA == cLojacli

						//Possui contrato especifico para este cliente e loja
						lcontrato:= .T.

						//verifica se o contrato encontra-se vigente
						If (cAliasSC5)->ZAZ_DTFIM >= DToS(date())
							//Se o contrato estiver ativo
							If (cAliasSC5)->ZAZ_STATUS == 'S'

								//Possui contrato especifico para este cliente e loja
								lRetorno:=.T.

							EndIf
						EndIf
						Exit
					EndIf
				EndIf

				(cAliasSC5)->(DBSkip())
			EndDo

			//Quando nao encontrar um contrato que tenha cliente + loja, ele vai buscar um mais generico somente por cliente
			If !lcontrato

				(cAliasSC5)->(DBGoTop())

				While (cAliasSC5)->(!Eof())

					If Empty((cAliasSC5)->ZAZ_LOJA)

						//possui contrato para o cliente sem loja especificada no contrato
						lcontrato:=.T.

						//verifica se o contrato encontra-se vigente
						If (cAliasSC5)->ZAZ_DTFIM >= DToS(date())
							//Se o contrato estiver ativo
							If (cAliasSC5)->ZAZ_STATUS == 'S'
								lRetorno:= .T.
							EndIf
						EndIf
						Exit
					EndIf

					(cAliasSC5)->(DBSkip())
				EndDo


			EndIf
		EndIf

		If  !lcontrato
			//Se o cliente informado no pedido de vendas nao possuir um contrato(ou que este esteja bloqueado)procura pela rede
			lRetorno:= VerContRede(cCodclient,cLojacli)

		EndIf

	EndIf

	If Select(cAliasSC5) > 0
		(cAliasSC5)->(DBCloseArea())
	EndIf
	FWRestArea(aGetArea)

Return lRetorno


/*
===============================================================================================================================
Programa--------: AOMS040
Autor-----------: Fabiano Dias
Data da Criacao-: 21/06/2010
Descrição-------: Verifica se o cliente e loja possui contrato de acordo comercial para a rede
Parametros------: cCodclient , cLojacli
Retorno---------: .T. ou .F.
===============================================================================================================================
*/
Static Function VerContRede(cCodclient As char,cLojacli As char) As logical

	Local aGetArea  As Array
	Local cQuery    As Char
	Local cRede	    As Char
	Local cAliasSA1 As Char
	Local cAliasZAZ As Char
	Local nreg      As Numeric
	Local nreg2     As Numeric
	Local lRetorno  As Logical
	aGetArea  := FWGetArea()
	cQuery    := ""
	cRede	  := ""
	cAliasSA1 := GetNextAlias()
	cAliasZAZ := GetNextAlias()
	nreg      := 0
	nreg2     := 0
	lRetorno  := .F.

	cQuery := "SELECT A1_GRPVEN"
	cQuery += " FROM " + RetSqlName("SA1")
	cQuery += " WHERE D_E_L_E_T_  = ' '  AND A1_FILIAL = '" + xFilial("SA1") + "'"
	cQuery += " AND A1_COD = '"  + cCodclient + "'"
	cQuery += " AND A1_LOJA = '" + cLojacli   + "'"
	cQuery += " AND A1_GRPVEN IS NOT NULL"

	MPSysOpenQuery( cQuery , cAliasSA1)
	DBSelectArea(cAliasSA1)//NÃO TIRAR
	Count to nreg //Contabiliza o numero de registros encontrados pela query

	(cAliasSA1)->(DBGoTop())

    //Caso o cliente tenha um grupo de vendas(Rede) especificado no seu cadastro
	If nreg > 0

		//Armazena grupo de vendas e estado para liberar TMP11
		cRede:=(cAliasSA1)->A1_GRPVEN

		//Pesquisa na tabela de desconto contratual se existe contrato para a rede do cliente especificado no pedido de vendas
		cQuery := "SELECT ZAZ_COD,ZAZ_DTFIM,ZAZ_STATUS"
		cQuery += " FROM " + RetSqlName("ZAZ")
		cQuery += " WHERE D_E_L_E_T_  = ' '  AND ZAZ_FILIAL = '" + xFilial("ZAZ") + "'"
		cQuery += " AND ZAZ_GRPVEN = '" + cRede + "'"
		cQuery += " AND ZAZ_MSBLQL = '2'"//Caso ele nao esteja bloqueado

	    MPSysOpenQuery( cQuery , cAliasZAZ)
		DBSelectArea(cAliasZAZ)//NÃO TIRAR
		Count to nreg2 //Contabiliza o numero de registros encontrados pela query

		(cAliasZAZ)->(DBGoTop())

		//Se encontrar um contrato para um cliente sem considerar a loja, caso ela tenha sido especificada no contrato
		If nreg2 > 0
			//Se o contrato estiver com a data de vigencia em vigor
			If (cAliasZAZ)->ZAZ_DTFIM >= DToS(date())
				//Se o contrato estiver ativo
				If (cAliasZAZ)->ZAZ_STATUS == 'S'
					lRetorno:= .T.
				EndIf

			EndIf

		EndIf

	EndIf

    (cAliasSA1)->(DBCloseArea())
	If Select(cAliasZAZ) > 0
		(cAliasZAZ)->(DBCloseArea())
	EndIf
	FWRestArea(aGetArea)

Return lRetorno
