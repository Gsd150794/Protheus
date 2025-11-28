/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |08/05/2025| Chamado 50588. Ajuste para execução de compensação de títulos somente qdo ocorrencia = '06'
===============================================================================================================================
*/

#Include "TOTVS.ch"

Static _aErro := {} As Array

/*
===============================================================================================================================
Programa----------: F200TIT
Autor-------------: Igor Melgaço
Data da Criacao---: 24/04/2025
Descrição---------: Ponto de Entrada para tratamentos de dados após baixa de títulos do retorno de cobrança da rotina FINA200 - Chamado 50292
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function F200TIT()
Local cParam   := SE1->(E1_FILIAL+E1_CLIENTE+E1_LOJA+'DCT'+E1_NUM+E1_PARCELA+'NCC') 
//Variáveis usadas na Compensacao
Local lRet         := .T. As Logical
Local aRecSE1      := {} As Array
Local aRecRA   	   := {} As Array
Local nOperacao    := 0 As Numeric
Local lAglutina    := .F. As Logical
Local lContabiliza := .F. As Logical
Local aTxMoeda     := {} As Array
Local nTaxaCM      := 0 As Numeric
Local nSaldoComp   := 0 As Numeric
Local aAreaSE1     := {} As Array

If (SE1->E1_I_DESCO > 0) .And. AllTrim(COCORR)=="06"
	aAdd(aRecSE1, SE1->(Recno()))
	aAreaSE1 := SE1->(GetArea())
	DBSelectArea("SE1")
	DBSetOrder(2)
	If DBSeek(cParam)
		If SE1->E1_VALOR > 0 

			nOperacao := 3 //Exclusao
			
			aAdd(aRecRA, SE1->(Recno()))

			PERGUNTE("FIN330",.F.)
            lContabiliza    := (MV_PAR09 == 1) // Contabiliza On Line ?
            lDigita         := (MV_PAR07 == 1) // Mostra Lanc Contab ?
            lAglutina       := .F.
			
			aTxMoeda        := {}
			nTaxaCM         := RecMoeda(dDataBase,SE1->E1_MOEDA)
			nSaldoComp      := SE1->E1_SALDO
			aAdd(aTxMoeda, {1, 1} )
			aAdd(aTxMoeda, {2, nTaxaCM} )

			lRet := MaIntBxCR(3, aRecSE1,,aRecRA ,,{lContabiliza,lAglutina,lDigita,.F.,.F.,.F.},,,,,nSaldoComp,,,, nTaxaCM, aTxMoeda)

			PERGUNTE("AFI200",.F.)

		EndIf
	EndIf

	FWRestArea(aAreaSE1)

	If !lRet
		aAdd(_aErro,{SE1->E1_FILIAL,SE1->E1_PREFIXO,SE1->E1_NUM,SE1->E1_PARCELA,SE1->E1_TIPO,SE1->E1_CLIENTE,SE1->E1_LOJA,Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,"A1_NOME")})
	EndIf 
EndIf

Return

/*
===============================================================================================================================
Programa----------: F200TITE
Autor-------------: Igor Melgaço
Data da Criacao---: 24/04/2025
Descrição---------: Retorna o Array de Registros com falha na compensação
Parametros--------: Nenhum
Retorno-----------: _aErro
===============================================================================================================================
*/
User Function F200TITE()

Return _aErro

