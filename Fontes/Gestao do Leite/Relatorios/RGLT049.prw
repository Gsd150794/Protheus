/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |26/03/2019| Chamado 11132. Ajuste para imprimir empréstimos do Leite de Terceiros
Lucas Borges  |25/06/2019| Chamado 28346. Revisão de fontes
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"      

/*
===============================================================================================================================
Programa----------: RGLT049
Autor-------------: Fabiano Dias
Data da Criacao---: 02/05/2011
Descrição---------: Recibo de pagamento emitido ao incluir ou alterar uma solicitacao de emprestimo/adiantamento/antecipacao.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT049

Private oPrint
Private nLinha      := 0100
Private nColInic    := 0030
Private nColFinal   := 2360
Private nLinInBox
Private nLinFiBox
Private nSaltoLinha := 50
Private nAjuAltLi1  := 20 //ajusta a altura de impressao dos dados do relatorio
Private _cPerg      := "RGLT049"

Define Font oFont12    Name "Courier New"       Size 0,-10       // Tamanho 12
Define Font oFont12b   Name "Courier New"       Size 0,-10 Bold  // Tamanho 12 Negrito
Define Font oFont16b   Name "Courier New"       Size 0,-16 Bold  // Tamanho 16 Negrito

oPrint:= TMSPrinter():New("RECIBO DE PAGAMENTO")
oPrint:SetPortrait() 	// Retrato  oPrint:SetLandscape() - Paisagem
oPrint:SetPaperSize(9)	// Seta para papel A4

// startando a impressora
oPrint:Say(0,0," ",oFont12,100)

Processa({|| ImpRecibo() })

Return

/*
===============================================================================================================================
Programa----------: ImpRecibo
Autor-------------: Fabiano Dias
Data da Criacao---: 02/05/2011
Descrição---------: Processa impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ImpRecibo()

Local cRaizServer	:= If(issrvunix(), "/", "\")
Local _cAlias		:= GetNextAlias()
Local _cTipoReci	:= ""
Local _cDtRefer		:= ""
Local _cCampo		:= "%"
Local _cTabela		:= "%"
Local _cOrder		:= "%"
Local _cFiltro		:= "%"
Local _cAux			:= IIf(FUNNAME() == "AGLT012","ZLM","ZLN")
Local _cMsg			:= ""
Local _nX			:= 0

//====================================================================================================
// Monta filtro de acordo com a tabela de origem
//====================================================================================================
_cCampo += _cAux +"_TOTAL TOTAL, "+ _cAux +"_TIPO TIPO, "+ _cAux +"_DTLIB DTLIB, "+ _cAux +"_DTCRED DTCRED, "+ _cAux +"_STATUS STATUS"
_cTabela += RetSqlName(_cAux) +" "+ _cAux + " "
If _cAux == "ZLM"
	_cCampo += ", ZL2_COD, ZL2_DESCRI"
	_cTabela += ", " +RetSqlName("ZL2") +" ZL2 "
	_cFiltro += " AND ZL2.D_E_L_E_T_ = ' ' "
	_cFiltro += " AND ZL2_COD = ZLM_SETOR "
EndIf

_cFiltro += " AND "+ _cAux +".D_E_L_E_T_ = ' '"
_cFiltro += " AND "+ _cAux +"_Filial = '" + xFilial(_cAux) + "'"
_cFiltro += " AND A2_COD = "+ _cAux +"_SA2COD "
_cFiltro += " AND A2_LOJA = "+ _cAux +"_SA2LJ "
If  MsgYesNo("Deseja imprimir o recibo de pagamento posicionado?","RGLT04901")
	_cFiltro += " AND "+ _cAux +"_COD = '" + &(_cAux+"->"+_cAux+"_COD") + "'"
//Chama tela de parametros para que o usuario possa informar um intervalo de recibos de impressao
Else
	If !Pergunte(_cPerg,.T.)
		Return
    EndIf
   	_cFiltro += " AND "+ _cAux +"_COD BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'"
EndIf
_cCampo += "%"
_cTabela += "%"
_cFiltro += "%"
_cOrder += _cAux +"_COD %"

BeginSql alias _cAlias
	SELECT A2_COD, A2_LOJA, A2_NOME, A2_CGC, %exp:_cCampo%
	FROM %Table:SA2% SA2, %exp:_cTabela%
	WHERE SA2.D_E_L_E_T_ = ' '
	      %exp:_cFiltro%
	ORDER BY %exp:_cOrder%
EndSql

//==================================================================================
//Verifica se foi encontrado o registro para impressao do recibo de pagamento
//==================================================================================
If (_cAlias)->(!Eof()) .And. !Empty((_cAlias)->STATUS) .And. (_cAlias)->STATUS <> '1'
 
	While (_cAlias)->(!Eof()) .And. !Empty((_cAlias)->STATUS) .And. (_cAlias)->STATUS <> '1'

	 	oPrint:StartPage()
		//==================================================================================
		//Para que seja realizada duas impressoes em uma mesma pagina do recibo de pagamento
		//==================================================================================
		For _nX:=1 to 2
			If _nX == 1//Primeiro recibo
				nLinha      := 0100
				nLinInBox   := 0100
				nLinFiBox   := 1550
				nLinPosEx   := 0700
			Else//Segundo recibo
				nLinha      := 1850
				nLinInBox   := 1850
				nLinFiBox   := 3300		
				nLinPosEx   := 2450
			EndIf     		                 			

			//==========================================================
			//Verifica o tipo do recibo de pagamento a ser impresso
			//==========================================================
			If (_cAlias)->TIPO == 'E'
				_cTipoReci:= 'EMPRÉSTIMO'
			ElseIf (_cAlias)->TIPO == 'A'
				_cTipoReci:= 'ADIANTAMENTO'
			Else
				_cTipoReci:= 'ANTECIPAÇÃO'
			EndIf

			//==========================================================
			//Pega a data de referencia no formato mes/ano
			//==========================================================
			If !Empty((_cAlias)->DTLIB)
				_cDtRefer := AllTrim(MesExtenso(Month(SToD((_cAlias)->DTLIB)))) + "/" + cValToChar(Year(SToD((_cAlias)->DTLIB)))
			EndIf

			oPrint:SayBitmap(nlinha + nAjuAltLi1,nColInic + 20,cRaizServer + "system/lgrl01.bmp",200,080)
			oPrint:Say (nlinha + nAjuAltLi1,nColFinal / 2,'RECIBO DE ' + _cTipoReci,oFont16b,nColFinal,,,2)
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			oPrint:Line(nLinha,nColInic,nLinha,nColFinal)
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			oPrint:Say (nlinha,nColFinal - 500,'R$: ' + AllTrim(Transform((_cAlias)->TOTAL,"@E 999,999,999.99")),oFont12b)
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			oPrint:Say (nlinha,nColInic + 20,"Recebi(emos) de: " + SM0->M0_NOMECOM,oFont12)
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			vlrExtenso((_cAlias)->TOTAL)
			//==================================================================
			//Linha que sera posicionada posteriormente a impressao do valor
			//por extenso isso para que independente do valor o restante do
			//relatorio seja impresso sempre a partir da posicao especificada
			//==================================================================

			nlinha:= nLinPosEx
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			_cMsg:= "Provenientes de: " + _cTipoReci + " CONCEDIDO AO "
			If _cAux == "ZLM"
				_cMsg+= IIf(SubStr((_cAlias)->A2_COD,1,1) == "P","PRODUTOR","FRETISTA") + " DA FOLHA DE LEITE RELATIVA A "
			Else
				_cMsg+= "AO FORNECEDOR REFERENTE AO SUPRIMENTO RELATIVO A " 
			EndIf
			oPrint:Say (nlinha,nColInic + 20,_cMsg+ _cDtRefer + ".",oFont12)
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			oPrint:Say (nlinha,nColFinal / 2,AllTrim(IIf(_cAux == "ZLM",(_cAlias)->ZL2_DESCRI,SM0->M0_CIDCOB)) + ", " + cValToChar(Day(SToD((_cAlias)->DTCRED))) + " de " +;
			AllTrim(MesExtenso(Month(SToD((_cAlias)->DTCRED)))) + "  de " + cValToChar(Year(SToD((_cAlias)->DTCRED))) + ".",oFont12,nColFinal,,,2)
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			oPrint:Say (nlinha,nColFinal / 2,'__________________________________',oFont16b,nColFinal,,,2)
			nlinha+=nSaltoLinha
			nlinha+=nSaltoLinha
			oPrint:Say (nlinha,nColFinal / 2,(_cAlias)->A2_COD + '/' + (_cAlias)->A2_LOJA + ' - '  + AllTrim((_cAlias)->A2_NOME),oFont12b,nColFinal,,,2)
			nlinha+=nSaltoLinha
			oPrint:Say (nlinha,nColFinal / 2,IIf(Len(AllTrim((_cAlias)->A2_CGC)) == 11,Transform(AllTrim((_cAlias)->A2_CGC),"@R 999.999.999-99"),Transform(AllTrim((_cAlias)->A2_CGC),"@R! NN.NNN.NNN/NNNN-99")),oFont12b,nColFinal,,,2)
			oPrint:Box(nLinInBox,nColInic,nLinFiBox,nColFinal) //Box do relatorio
	    Next _nX

		  oPrint:EndPage()	// Finaliza a Pagina.
		  (_cAlias)->(DBSkip())
	  EndDo		        

	  oPrint:Preview()	// Visualiza antes de Imprimir.

//===================================================================
//Caso nao encontre o registro para impressao do recibo de pamento
//===================================================================
Else                                                                
	MsgAlert("Não foram encontrados recibos para impressão referente aos dados informados.","RGLT04902")
EndIf

Return

/*
===============================================================================================================================
Programa----------: vlrExtenso
Autor-------------: Fabiano Dias
Data da Criacao---: 02/05/2011
Descrição---------: Tranforma valor em texto por extenso
Parametros--------: nValor
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function vlrExtenso(nValor)

Local cValor   := "A quantia de: (" + AllTrim(extenso(nValor)) + ")"
Local nNunCarac:= 85
Local nCont    := 1

While nCont <= Len(cValor)
	oPrint:Say (nlinha,nColInic + 20 ,AllTrim(SubStr(cValor,nCont,nNunCarac)),oFont12b)
	nlinha+=nSaltoLinha
	nCont+= nNunCarac
EndDo

Return
