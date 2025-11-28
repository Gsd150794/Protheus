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
Programa----------: AEST004
Autor-------------: Josué Danich Prestes
Data da Criacao---: 15/10/2015
Descrição---------: Rotina de explosão de estrutura de 1 nivel na tela de desmontagem ( MATA242 ) - Chamado 12268
Parametros--------: 	__cProduto - Produto
						_nquant - quantidade do produto
						__oGet - objeto da tela
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST004(_cProduto,_nquant,_oGet)

Local _aEstrutura	:= {}
Local _nI        	:= 0
Local _nx        	:= 0
Local _lContinua 	:= .T.
Local _nPospro 	:= GDFieldPos("D3_COD")
Local _arateio	:= {}

Private nEstru:=0

//verifica se produto e quantidade foram preenchidos
If Empty(_cproduto)
	MessageBox("Preencha produto!","Atenção",0)
	Return
EndIf

If _nquant == 0
	MessageBox("Preencha quantidade!","Atenção",0)
	Return
EndIf


If _lContinua
	// Verifica se ja existe informacao digitada no aCols
	For _nI:=1 to Len(acols)
		If !(acols[_nI][Len(aheader)+1]) .And. !(Empty(acols[_nI][_npospro]))
			_lContinua := .F.
		EndIf
	Next _nI

	// Pergunta ao usuario se deve sobrescrever informacoes digitadas
	If !_lContinua 
		If MessageBox("Ja existem informacoes digitadas para a desmontagem. Substitui?","Atenção",4) == 6
			_lContinua := .T.
		EndIf
	EndIf
EndIf

If _lContinua .And. !Empty(_cProduto) .And. _nquant > 0
	// Le estrutura do produto origem da desmontagem
	_aEstrutura:=Estrut(_cProduto,_nquant,.T.)

	// Se o produto tiver estrutura cria um novo aCols e monta matriz de rateio
	If Len(_aEstrutura) > 0
		aCols:={}
		_arateio := AEST004ES(_aEstrutura,_cproduto,_nquant)
	Else
		MessageBox("Não foi localizada estrutura para o produto!","Atenção",0)
		Return
	EndIf

	If Len(_arateio) == 0
		MessageBox("Não foi localizada produção para o produto! Rateios virão zerados","Atenção",0)
	EndIf
		
	// Le somente os itens de primeiro nivel
	For _nI:=1 to Len(_aEstrutura)
		// Adiciona item no acols
		aAdd(aCols,Array(Len(aHeader)+1))
		// Preenche conteudo do acols
		For _nx:=1 to Len(aHeader)
			cCampo:=AllTrim(aHeader[_nx,2])
			If IsHeadRec(cCampo)
				aCols[Len(aCols)][_nx] := 0
			ElseIf IsHeadAlias(cCampo)
				aCols[Len(aCols)][_nx] := "SD3"
			Else
				aCols[Len(aCols)][_nx] := CriaVar(cCampo,.F.)
			EndIf
		Next _nx

		aCOLS[Len(aCols)][Len(aHeader)+1] := .F.

		If aScan(_arateio,{|x| AllTrim(x[1])== AllTrim(_aEstrutura[_nI,3]) }) > 0
			_nrateio := (_arateio[aScan(_arateio,{|x| AllTrim(x[1])== AllTrim(_aEstrutura[_nI,3]) })][2]) * 100
		Else
			_nrateio := 0
		EndIf
		
		// Preenche campos especificos
		SB1->(DBSetOrder(1))
		SB1->(DBSeek(xFilial("SB1")+_aEstrutura[_nI,3]))
		GDFieldPut("D3_COD",_aEstrutura[_nI,3],Len(aCols))
		GDFieldPut("D3_I_DESPR",SB1->B1_I_DESCD,Len(aCols))
		GDFieldPut("D3_QUANT",_aEstrutura[_nI,4],Len(aCols))
		GDFieldPut("D3_RATEIO",_nrateio,Len(aCols))
		GDFieldPut("D3_LOCAL",RetFldProd(SB1->B1_COD,"B1_LOCPAD"),Len(aCols))
		GDFieldPut("D3_QTSEGUM",ConvUm(_aEstrutura[_nI,3],_aEstrutura[_nI,4],0,2),Len(aCols))
	Next _nI
EndIf

Return 

/*
===============================================================================================================================
Programa----------: AEST004ES
Autor-------------: Josué Danich Prestes
Data da Criacao---: 15/10/2015
Descrição---------: Rotina de carregamento de rateio de valor da estrutura de produto - Chamado 12268
Parametros--------: _aestrut - Estrutura do produto
Retorno-----------: _arateio - Matriz de rateios em sequência
===============================================================================================================================
*/
Static Function AEST004ES(_aestrut, _cproduto,_nquant)

Local _nni 		:= 1
Local _arateio 	:= {}
Local _cQuery 	:= ""
Local _nvalorpro:= 0
Local _nmaior 	:= 0
Local _nsoma	:= 0
Local _nind		:= 0

//localiz ultima producao
_cQuery := "SELECT MAX(D3_NUMSEQ) AS SEQ"
_cQuery += " FROM " + RetSqlName("SD3") + " D3"
_cQuery += " WHERE D3.D_E_L_E_T_ = ' ' AND D3.D3_COD = '"+_cproduto+"'"
_cQuery += " AND D3.D3_FILIAL = '" + xFilial("SD3") + "'"
_cQuery += " AND D3.D3_CF = 'PR0'"

dbUseArea( .T., "TOPCONN", TcGenQry(,,_cQuery), "SD3T", .T., .F. )
DBSelectArea("SD3T")

If .Not. SD3T->( Eof() )
	DBSelectArea("SD3")
	SD3->( DBSetOrder(4) ) //D3_FILIAL + D3_NUMSEQ
	If SD3->( DBSeek( xFilial("SD3") + AllTrim( SD3T->SEQ ) ) )
		//roda registro de produção para pegar dados de valores totais
		While  AllTrim(SD3->D3_NUMSEQ) == AllTrim(SD3T->SEQ) .And. !(SD3->( Eof() ))
				//se é o PA pega o valor total para  a desmontagem e o original da produção
				If AllTrim(SD3->D3_COD) == AllTrim(_cproduto)
					_nvalorpro	:= SD3->D3_CUSTO1
				Else
					aAdd(_arateio,{SD3->D3_COD,SD3->D3_CUSTO1})
				EndIf
				SD3->( DBSkip() )
		EndDo 
	Else
		Return {}
	EndIf
Else
	Return {}
EndIf

SD3T->( DBCloseArea() )

//muda de valor para proporção

For _nni := 1 to Len(_arateio)
	_arateio[_nni][2] := _arateio[_nni][2]/_nvalorpro
	//guarda maior rateio para ajuste
	If _arateio[_nni][2] > _nmaior
		_nmaior 	:= 	_arateio[_nni][2]
		_nind		:=	_nni
	EndIf
	//faz somatorio para saber tamanho do ajuste
	_nsoma += _arateio[_nni][2]
Next _nni

//faz ajuste no maior item do rateio
If _nsoma <> 1
	_arateio[_nind][2] := 1 - _nsoma + _arateio[_nind][2]
EndIf

Return _arateio
