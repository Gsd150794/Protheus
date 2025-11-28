/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |23/01/2025| Chamado 49641. Implementada faixa de início e fim para pagamento do excedente de matéria gorda
Lucas Borges  |11/02/2025| Chamado 49877. Removido tratamento sobre a versão do Mix
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: XFUNCOM
Autor-------------: ITALAC
Data da Criacao---: 30/03/2012                                   .
Descrição---------: Funções genéricas do modulo Compras
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/

/*
===============================================================================================================================
Programa----------: C_CONTABIL
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 30/03/2012                                   .
Descrição---------: Retorna a conta contábil de acordo com a linha/rota informada.
 					  Ao cadastrar um fornecedor do tipo Produtor e preencher o campo A2_L_LI_RO, é chamado o gatilho.
Parametros--------: Nenhum
Retorno-----------: _cConta = Numero da conta contábil.
===============================================================================================================================
*/  
User Function C_CONTABIL As Character

Local _oObj		:= FwModelActivete() As Object
Local _cConta	:= _oObj:GetValue( 'SA2MASTER', 'A2_CONTA',) As Character
Local _cCod		:= SubStr(_oObj:GetValue( 'SA2MASTER', 'A2_COD',),1,1) As Character
Local _cLinRot	:= SubStr(_oObj:GetValue( 'SA2MASTER', 'A2_L_LI_RO',),1,2) As Character

Do Case
	Case _cCod == "P" .And. _cLinRot $  "01/02/03/04/05/06/07/08/09/0A/0B"
		_cConta := "2101050001"
	Case _cCod == "P" .And. _cLinRot $  "10/11/12/13/14/15/16/17/18/19/1A/1B/1C"
		_cConta := "2101050008"
	Case _cCod == "P" .And. _cLinRot $  "20/21/22/24/25"
		_cConta := "2101050016"
	Case _cCod == "P" .And. _cLinRot $ "30/31/32/33"
		_cConta := "2101050015"
	Case _cCod == "P" .And. _cLinRot == "23"
		_cConta := "2101050017"
	Case _cCod == "P" .And. _cLinRot == "40"
		_cConta := "2101050005"
	Case _cCod == "P" .And. _cLinRot == "93"
		_cConta := "2101050018"
EndCase

Return _cConta

/*
===============================================================================================================================
Programa----------: CCusto
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 27/06/2023
Descrição---------: Retorna Centro de Custo de acordo com filial informada. Utilizado no CT5_CCC e CT5_CCD
Parametros--------: Nenhum
Retorno-----------: _cCusto - Centro de Custo
===============================================================================================================================
*/  
User Function CCusto As Character

Local _cCusto:= "" As Character

If cFilAnt == '01'
	_cCusto:= '13001002'
ElseIf cFilAnt == '02'
	_cCusto:= '18001003'
ElseIf cFilAnt == '03'
	_cCusto:= '18001005'
ElseIf cFilAnt == '04'
	_cCusto:= '18001002'
ElseIf cFilAnt == '05'
	_cCusto:= '53001002'
ElseIf cFilAnt == '06'
	_cCusto:= '18001006'
ElseIf cFilAnt == '07'
	_cCusto:= '18001004'
ElseIf cFilAnt == '08'
	_cCusto:= '18002009'
ElseIf cFilAnt == '09'
	_cCusto:= '18001007'
ElseIf cFilAnt == '0A'
	_cCusto:= '18001008'
ElseIf cFilAnt == '0B'
	_cCusto:= '18002011'
ElseIf cFilAnt == '10'
	_cCusto:= '23001002'
ElseIf cFilAnt == '11'
	_cCusto:= '28001008'
ElseIf cFilAnt == '12'
	_cCusto:= '28001009'
ElseIf cFilAnt == '13'
	_cCusto:= '28001006'
ElseIf cFilAnt == '14'
	_cCusto:= '28001002'
ElseIf cFilAnt == '15'
	_cCusto:= '28001003'
ElseIf cFilAnt == '16'
	_cCusto:= '28001004'
ElseIf cFilAnt == '17'
	_cCusto:= '28001010'
ElseIf cFilAnt == '18'
	_cCusto:= '28001005'
ElseIf cFilAnt == '19'
	_cCusto:= '28001012'
ElseIf cFilAnt == '1A'
	_cCusto:= '28001011'
ElseIf cFilAnt == '1B'
	_cCusto:= '28001007'
ElseIf cFilAnt == '1C'
	_cCusto:= '28001013'
ElseIf cFilAnt == '20'
	_cCusto:= '43001002'
ElseIf cFilAnt == '21'
	_cCusto:= '48001002'
ElseIf cFilAnt == '22'
	_cCusto:= '48001003'
ElseIf cFilAnt == '23'
	_cCusto:= '93001002'
ElseIf cFilAnt == '24'
	_cCusto:= '48001005'
ElseIf cFilAnt == '25'
	_cCusto:= '48001006'
ElseIf cFilAnt == '30'
	_cCusto:= '33001002'
ElseIf cFilAnt == '31'
	_cCusto:= '38001002'
ElseIf cFilAnt == '32'
	_cCusto:= '38001003'
ElseIf cFilAnt == '33'
	_cCusto:= '38001004'
ElseIf cFilAnt == '40'
	_cCusto:= '83001002'
ElseIf cFilAnt == '90'
	_cCusto:= '53001002'
ElseIf cFilAnt == '91'
	_cCusto:= '68001001'
ElseIf cFilAnt == '92'
	_cCusto:= '58001002'
ElseIf cFilAnt == '93'
	_cCusto:= 'A8001001'
ElseIf cFilAnt == '94'
	_cCusto:= 'B8001001'
ElseIf cFilAnt == '95'
	_cCusto:= 'A8001003'
ElseIf cFilAnt == '96'
	_cCusto:= 'A8001005'
ElseIf cFilAnt == '97'
	_cCusto:= 'A8001002'
ElseIf cFilAnt == '98'
	_cCusto:= 'A8001004'
EndIf

Return _cCusto

/*
===============================================================================================================================
Programa----------: lstCF
Autor-------------: Lucas Crevilari
Data da Criacao---: 28/10/2014                                 .
Descrição---------: Monta Tela para consulta das CFOPs
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function lstCF As Logical

Local _cAlias		:= GetNextAlias() As Character
Local _nI			:= 0 As Numeric

Private nTam		:= 0 As Numeric
Private nMaxSelect	:= 0 As Numeric
Private aCat		:= {} As Array
Private MvRet		:= AllTrim( ReadVar() ) As Variant
Private MvPar		:= "" As Variant
Private cTitulo		:= "" As Character
Private MvParDef	:= "" As Variant

#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam		:= 4
nMaxSelect	:= 19
cTitulo		:= "CFOP"

BeginSql alias _cAlias
	SELECT DISTINCT X5_CHAVE CHAVE ,X5_DESCRI DESCRI
	FROM %Table:SX5%
	WHERE D_E_L_E_T_ = ' '
	AND X5_TABELA  = '13'
	ORDER BY X5_CHAVE
EndSql

While (_cAlias)->( !Eof() )
	MvParDef += PadR((_cAlias)->CHAVE , 4 )
	aAdd( aCat , AllTrim((_cAlias)->DESCRI ) )
	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->(DBCloseArea())

//Trativa abaixo para no caso de uma alteracao do campo trazer todos
//os dados que foram selecionados anteriormente
If Len(AllTrim(&MvRet)) == 0
	MvPar	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )
	&MvRet	:= PadR( AllTrim( StrTran( &MvRet , ";" , "" ) ) , Len(aCat) )
Else
	MvPar	:= AllTrim( StrTran( &MvRet , ";" , "/" ) )
EndIf

//Somente altera o conteudo caso o usuario clique no botao ok		 |
// Executa funcao que monta tela de opcoes                             
If F_Opcoes( @MvPar , cTitulo , aCat , MvParDef , 12 , 49 , .F. , nTam , nMaxSelect )

	//Tratamento para separar retorno com ";"
	&MvRet := ""
	
	For _nI := 1 To Len(MvPar) step nTam
	
		If !(SubStr( MvPar , _nI , 1 ) $ " |*" )
			&MvRet += SubStr( MvPar , _nI , nTam ) + ";"
		EndIf
		
	Next _nI
	
	//Trata para tirar o ultimo caracter
	&MvRet := SubStr( &MvRet , 1 , Len(&MvRet) - 1 )

EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: VLDDTFAT
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 30/06/2015                                 .
Descrição---------: Função de validação da data digitada
Parametros--------: Lógico -> .T. caso não haja nenhum problema com a data digitada, .F. caso contrário
Retorno-----------: Lógico -> .T. caso não haja nenhum problema com a data digitada, .F. caso contrário
===============================================================================================================================
*/
User Function VLDDTFAT(_dData As Date, _nOpca As Numeric,_aRecnos As Array) As Logical

Local _aArea	:= FWGetArea() As Array
Local _aAreaSC7	:= SC7->(FWGetArea()) As Array
Local _lRet		:= .T. As Logical
Local _nDtLimFt	:= SuperGetMV("IT_DTLIMFT",.F.,180)	As Numeric// Limite de dias para data de Faturamento
Local _dLimFt	:= Date() + _nDtLimFt As Date// Data limite maximo para data de Faturamento
Local _dLimAnt	:= Date() - _nDtLimFt As Date// Data limite minimo para data de Faturamento
Local _nI		:= 0 As Numeric

Default _dData		:= Date()
Default _nOpca		:= 1
Default _aRecnos	:= {}

If !Empty(_dData)
	If _nOpca == 1
		If _lRet
			If _dData > _dLimFt .Or. _dData < _dLimAnt
				U_ITMsg("A Data de Faturamento informada não é vaílda. A data digitada foi: " + DToC(_dData) + ".",;
                      "Data de Faturamento Informada Invalida!",;
                      "Favor informar uma data maior ou igual a: " + DToC(_dLimAnt) + " ou menor ou igual a " + DToC(_dLimFt) + ".",3) 
				_lRet := .F.
			EndIf
		EndIf
		
		If _lRet
			If (SC7->C7_QUJE >= SC7->C7_QUANT) .And. SC7->C7_I_DTFAT <> _dData
				U_ITMsg("Não é possível alterar este Pedido de Compras, pois o mesmo já foi atendido.",;
                      "Atenção",;
                      "Verifique o status no parâmetro MV_ALTPEDC.",3)
				_lRet := .F.
			EndIf
		EndIf
		
		If _lRet
			If SC7->C7_RESIDUO == "S" .And. SC7->C7_I_DTFAT <> _dData
			   U_ITMsg("Este item do Pedido de compras foi encerrado por Eliminação de Residuo e não poderá ser alterado.",;
                      "Atenção",;
                      "",3)
				_lRet := .F.
			EndIf
		EndIf
		
		If _lRet
			If (SC7->C7_QTDACLA + SC7->C7_QUJE) > SC7->C7_QUANT .And. SC7->C7_I_DTFAT <> _dData
				U_ITMsg("Pedido não pode ser alterado, pois já esta totalmente/parcialmente entregue ou foi eliminado por residuo.",;
                      "Atenção",;
                      "Selecione outro item a ser alterado.",3)
				_lRet := .F.
			EndIf
		EndIf
	Else
		For _nI := 1 To Len(_aRecnos)
			DBSelectArea("SC7")
			DBGoTo(_aRecnos[_nI])
			
			If _lRet
				If _dData > _dLimFt .Or. _dData < _dLimAnt					
					U_ITMsg("A Data de Faturamento informada não é vaílda. A data digitada foi: " + DToC(_dData) +".",;
                         "Data de Faturamento Informada Invalida!",;
                         "Favor informar uma data maior ou igual a: " + DToC(_dLimAnt) + " ou menor ou igual a " + DToC(_dLimFt) + ".",3)		
					_lRet := .F.
				EndIf
			EndIf
			
			If _lRet
				If (SC7->C7_QUJE >= SC7->C7_QUANT) .And. SC7->C7_I_DTFAT <> _dData
					U_ITMsg("Não é possível alterar este Pedido de Compras, pois o mesmo já foi atendido.",;
                          "Atenção",;
                          "Verifique o status no parâmetro MV_ALTPEDC.",3)
					_lRet := .F.
				EndIf
			EndIf
			
			If _lRet
				If SC7->C7_RESIDUO == "S" .And. SC7->C7_I_DTFAT <> _dData
				   U_ITMsg("Este item do Pedido de compras foi encerrado por Eliminação de Residuo e não poderá ser alterado.",;
                         "Atenção",;
                         "",3)
					_lRet := .F.
				EndIf
			EndIf
			
			If _lRet
				If (SC7->C7_QTDACLA + SC7->C7_QUJE) > SC7->C7_QUANT .And. SC7->C7_I_DTFAT <> _dData
					U_ITMsg("Pedido não pode ser alterado, pois já esta totalmente/parcialmente entregue ou foi eliminado por residuo.",;
                         "Atenção",;
                         "Selecione outro item a ser alterado.",3)
					_lRet := .F.
				EndIf
			EndIf
		Next _nI
	EndIf
EndIf

//===============================================================
// Grava log de validação de datas Pedidos de Compras
//=============================================================== 
U_ITLOGACS('VLDDTFAT')

FWRestArea(_aArea)
FWRestArea(_aAreaSC7)

Return _lRet

/*
===============================================================================================================================
Programa----------: Nomeclifor
Autor-------------: Josué Danich Prestes
Data da Criacao---: 10/11/2016                                .
Descrição---------: Retorna nome do fornecedor ou cliente
Parametros--------:  cTipoNF -Tipo de nota ( D - Devolução, B - Beneficiamento, N - Normal)
					    cTab - Tabela da nota ( SF1 ou SF2)
Retorno-----------: String com nome do cliente ou fornecedor
===============================================================================================================================
*/
User Function NomeCliFor(cTipoNF As Character,cTab As Character) As Character

Local cNomeFC := "" As Character

Do Case  
	Case cTipoNF $ "DB" .And. cTab=="SF2"  
		cNomeFC := Posicione("SA2",1,xFilial("SA2")+SF2->(F2_CLIENTE+F2_LOJA),"A2_NOME") 
	Case !cTipoNF $ "DB" .And. cTab=="SF2"  
		cNomeFC := Posicione("SA1",1,xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA),"A1_NOME") 
	Case cTipoNF $ "DB" .And. cTab=="SF1"  
		cNomeFC := Posicione("SA1",1,xFilial("SA1")+SF1->(F1_FORNECE+F1_LOJA),"A1_NOME") 
	Case !cTipoNF $ "DB" .And. cTab=="SF1"  
		cNomeFC := Posicione("SA2",1,xFilial("SA2")+SF1->(F1_FORNECE+F1_LOJA),"A2_NOME")
EndCase

Return cNomeFC

/*
===============================================================================================================================
Programa----------: ColErro
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 02/04/2018
Descrição---------: Retorna descrição do erro no TOTVS Colaboração complementado dos erros customizados
Parametros--------: _cCodErro: String com o código de erro customizado ou padrão
Retorno-----------: _cRet: String com a descrição do erro
===============================================================================================================================
*/
User Function ColErro(_cCodErro As Character) As Character

Local _cRet := "" As Character

If _cCodErro == 'MCOM01'
	_cRet := 'MD-e com 210220-Operação Desconhecida'
ElseIf _cCodErro == 'MCOM02'
	_cRet := 'MD-e com 21040-Operação Não realizada'
ElseIf _cCodErro == 'MCOM03'
	_cRet := 'CT-e com 610110-Prestação de Serviço em Desacordo'
ElseIf _cCodErro == 'MCOM04'
	_cRet := 'CT-e de Anulação'
ElseIf _cCodErro == 'MCOM05'
	_cRet := 'Excluído Fiscal Com validação'
ElseIf _cCodErro == 'MCOM06'
	_cRet := 'Excluído Fiscal Sem validação'
ElseIf _cCodErro == 'MCOM07'
	_cRet := 'Manutenção Automática XML'
Else
	_cRet := ColErroErp(_cCodErro)
EndIf

Return _cRet

/*
===============================================================================================================================
Programa----------: GrvLT3
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 14/12/2020
Descrição---------: Função para gravar o movimento do Leite de Terceiros e Contra Nota no Leite Próprio
Parametros--------: SA2,SF1 e SD1 deve estar posicionada
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function GrvLT3

Local _aArea	:= FWGetArea() As Array
Local _cAlias	:= GetNextAlias() As Character
Local _lRet		:= .T. As Logical
Local _lSemNota	:= IIf(SA2->A2_L_NFPRO == "S", .T.,.F.) As Logical//Produtor que emite a própria NF-e no fechamento
Local _nQtd		:= 0 As Numeric

If SF1->F1_TIPO == "N" .And. !FWIsInCallStack("U_AGLT036")
	//Gravação do Movimento no Leite de Terceiros
	BeginSql alias _cAlias
		SELECT D1_COD, SUM(D1_QUANT) D1_QUANT, Round(AVG(D1_VUNIT),8) D1_VUNIT, C7_PRECO, C7_L_PMGB, C7_L_PMGB2, C7_L_PMEST,
			NVL((SELECT ZLY_DFECHA
					FROM %Table:ZLY% ZLY
					WHERE ZLY.D_E_L_E_T_ = ' '
					AND ZLY.ZLY_REFINI <= SD1.D1_DTDIGIT
					AND ZLY.ZLY_REFFIM >= SD1.D1_DTDIGIT),
				'ABORTA') FECHAMENTO
		FROM %Table:SD1% SD1, %Table:SC7% SC7
		WHERE SD1.D_E_L_E_T_ = ' '
		AND SC7.D_E_L_E_T_ = ' '
		AND SC7.C7_FILIAL = SD1.D1_FILIAL
		AND SC7.C7_NUM = SD1.D1_PEDIDO
		AND SC7.C7_ITEM = SD1.D1_ITEMPC
		AND SD1.D1_FILIAL = %exp:SF1->F1_FILIAL%
		AND SD1.D1_DOC = %exp:SF1->F1_DOC%
		AND SD1.D1_SERIE = %exp:SF1->F1_SERIE%
		AND SD1.D1_FORNECE = %exp:SF1->F1_FORNECE%
		AND SD1.D1_LOJA = %exp:SF1->F1_LOJA%
		AND SD1.D1_NFORI = ' '
		AND SD1.D1_SERIORI = ' '
		AND EXISTS (SELECT 1 FROM %Table:ZA7% ZA7
			WHERE ZA7.D_E_L_E_T_ = ' '
				AND ZA7.ZA7_FILIAL = SD1.D1_FILIAL
				AND ZA7.ZA7_CODPRD = SD1.D1_COD)
		GROUP BY D1_COD, C7_PRECO, C7_L_PMGB, C7_L_PMGB2, C7_L_PMEST, D1_DTDIGIT
	EndSql
	Count to _nQtd
	If _nQtd > 1
		If l103Auto
			AutoGRLog("XFUNCOM01"+CRLF+"O documento de entrada possui mais de um item. Para o Leite de Terceiros o documento deve conter apenas um item.")
		Else
			MsgStop("O documento de entrada possui mais de um item. Para o Leite de Terceiros o documento deve conter apenas um item.","XFUNCOM01")
		EndIf
		_lRet := .F.
	ElseIf _nQtd == 1
		(_cAlias)->(DBGoTop())

		If !Empty((_cAlias)->FECHAMENTO)
			If l103Auto
				AutoGRLog("XFUNCOM01"+CRLF+"Período  "+IIf(AllTrim((_cAlias)->FECHAMENTO)=="ABORTA","não cadastrado", "fechado") +" na Recepção de Leite de Terceiros."+;
							"Procure o departamento do Leite da Matriz.")
			Else
				MsgStop("Período "+IIf(AllTrim((_cAlias)->FECHAMENTO)=="ABORTA","não cadastrado", "fechado") +" na Recepção de Leite de Terceiros."+;
						"Procure o departamento do Leite da Matriz.","XFUNCOM01")
			EndIf
			_lRet := .F.
		Else
			Begin Transaction
				DBSelectArea('ZLX')
				ZLX->( DBSetOrder(2) )
				//Quando posicionado, o registro já foi gerado pela pre-nota, então, só atualizo alguns dados
				If ZLX->( DBSeek( xFilial('ZLX') + SD1->( D1_DOC + D1_SERIE + D1_FORNECE + D1_LOJA ) ) )
					ZLX->( RecLock( "ZLX" , .F. ) )
				Else
					ZLX->( RecLock( "ZLX" , .T. ) )
					ZLX->ZLX_FILIAL	:= xFilial("ZLX")
					ZLX->ZLX_CODIGO	:= GetSxeNum( "ZLX" , "ZLX_CODIGO" )
					ZLX->ZLX_DTENTR	:= SF1->F1_DTDIGIT
					ZLX->ZLX_PGFRT	:= 'N'
					ZLX->ZLX_STATUS	:= '1'
				EndIf
				ZLX->ZLX_TIPOLT	:= IIf( AllTrim( SF1->F1_FORNECE ) == 'F00001' , 'F' , 'T' ) //F00001 - CODIGO DA ITALAC PARA TRANSFERÊNCIAS
				ZLX->ZLX_PRODLT	:= (_cAlias)->D1_COD
				ZLX->ZLX_FORNEC	:= SF1->F1_FORNECE
				ZLX->ZLX_LJFORN	:= SF1->F1_LOJA
				ZLX->ZLX_NRONF	:= SF1->F1_DOC
				ZLX->ZLX_SERINF	:= SF1->F1_SERIE
				ZLX->ZLX_ESPECI	:= SF1->F1_ESPECIE
				ZLX->ZLX_VOLNF	:= (_cAlias)->D1_QUANT
				ZLX->ZLX_PRCNF	:= (_cAlias)->D1_VUNIT //Saber se na nota e kg ou Litro
				ZLX->ZLX_PRCPRE	:= (_cAlias)->C7_PRECO
				ZLX->ZLX_PMGB	:= (_cAlias)->C7_L_PMGB
				ZLX->ZLX_PMGB2	:= (_cAlias)->C7_L_PMGB2
				ZLX->ZLX_PMEST	:= (_cAlias)->C7_L_PMEST
				ZLX->ZLX_DIFPRC	:= (_cAlias)->D1_VUNIT - (_cAlias)->C7_PRECO
				ZLX->ZLX_VLRNF	:= SF1->F1_VALBRUT
				ZLX->ZLX_ICMSNF	:= SF1->F1_VALICM
				ZLX->( MSUnLock() )
						
				If __lSX8
					ConfirmSX8()
				EndIf
			End Transaction
		EndIf
	EndIf
	(_cAlias)->(DBCloseArea())
	//========================================================================================================
	//Gera informações na rotina que controla as notas de produtores utilizadas no fechamento do Leite Próprio
	//========================================================================================================
	If 	SubStr(SF1->F1_FORNECE,1,1)=='P' .And. !_lSemNota .And. !Empty(SF1->F1_L_MIX) .And. !FWIsInCallStack("U_AGLT036").And. ;
		(FWIsInCallStack("U_SF1140I")  .Or. FWIsInCallStack("U_SF1100I"))
		DBSelectArea("ZZ4")
		ZZ4->(DBSetOrder(1))
		//Quando posicionado, o registro já foi gerado pela pre-nota, então, só atualizo alguns dados
		If ZZ4->(DBSeek( SF1->(F1_FILIAL+F1_L_MIX+F1_FORNECE+F1_LOJA+F1_SERIE+F1_DOC)))
			ZZ4->(RecLock("ZZ4",.F.))
		Else
			ZZ4->(RecLock("ZZ4",.T.))
		EndIf
		ZZ4->ZZ4_FILIAL	:= SF1->F1_FILIAL
		ZZ4->ZZ4_CODMIX	:= SF1->F1_L_MIX
		ZZ4->ZZ4_EMISSA	:= SF1->F1_EMISSAO
		ZZ4->ZZ4_CODPRO	:= SF1->F1_FORNECE
		ZZ4->ZZ4_LOJPRO	:= SF1->F1_LOJA
		ZZ4->ZZ4_SERIE	:= SF1->F1_SERIE
		ZZ4->ZZ4_NUMCNF	:= SF1->F1_DOC
		ZZ4->ZZ4_QTDE	:= SD1->D1_QUANT
		ZZ4->ZZ4_VALOR	:= SD1->D1_VUNIT
		ZZ4->ZZ4_STATUS	:= "2"
		ZZ4->( MSUnLock() )
	EndIf
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: ValLT3
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 14/12/2020
Descrição---------: Função para gravar o movimento do Leite de Terceiros e Contra Nota no Leite Próprio. Chamado nos pontos de 
					entrada de validação (MT100TOK e MT140TOK) do documento de entrada.
Parametros--------: aCols -> A -> Array com os dados dos itens
					_cDtRef -> C -> Data de digitação do documento
					_nPosPrd -> N -> Posição do código do produto no array de itens
					_nPosNOri -> N -> Posição do código da nota de origem no array de itens
					_nPosSOri -> N -> Posição do código da serie de origem no array de itens
					SA2,SF1 e SD1 deve estar posicionada
Retorno-----------: _lRet -> indica se permite ou não a gravação do documento de entrada
===============================================================================================================================
*/
User Function ValLT3(aCols As Array,_cDtRef As Character,_nPosPrd As Numeric,_nPosNOri As Numeric,_nPosSOri As Numeric) As Logical

Local _cAlias	:= GetNextAlias() As Character
Local _lRet		:= .T. As Logical

//Para o Leite de terceiros a nota deve possuir um item, logo, só preciso validar o primeiro.
If Empty( aCols[1][_nPosNOri] ) .And. Empty( aCols[1][_nPosSOri] )
	BeginSql alias _cAlias
		SELECT NVL((SELECT ZLY_DFECHA
					FROM %Table:ZLY% ZLY
					WHERE ZLY.D_E_L_E_T_ = ' '
					AND ZLY.ZLY_REFINI <= %exp:_cDtRef%
					AND ZLY.ZLY_REFFIM >= %exp:_cDtRef%),
				'ABORTA') FECHAMENTO
		FROM %Table:ZA7% ZA7
		WHERE ZA7.D_E_L_E_T_ = ' '
		AND ZA7.ZA7_CODPRD = %exp:aCols[1][_nPosPrd]%
		AND ZA7.ZA7_FILIAL = %xFilial:ZA7%
	EndSql
	While (_cAlias)->(!Eof())
		If !Empty((_cAlias)->FECHAMENTO)
			If l103Auto
				AutoGRLog("XFUNCOM01"+CRLF+"Período " +IIf(AllTrim((_cAlias)->FECHAMENTO)=="ABORTA","não cadastrado", "fechado") +" na Recepção de Leite de Terceiros."+;
							"Procure o departamento do Leite da Matriz.")
			Else
				MsgStop("Período " +IIf(AllTrim((_cAlias)->FECHAMENTO)=="ABORTA","não cadastrado", "fechado") +" na Recepção de Leite de Terceiros."+;
						"Procure o departamento do Leite da Matriz.","XFUNCOM01")
			EndIf
			_lRet := .F.
		EndIf
		(_cAlias)->(DBSkip())
	EndDo
	(_cAlias)->(DBCloseArea())
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MaNatInt
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 27/04/2022
Descrição---------: Réplica da função MaTESInt alterada para retornar a Natureza Inteligente. Atualizar sempre que o MATA089
					for atualizado.
Parametros--------:
Retorno-----------:
===============================================================================================================================
*/
/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ MATA089  ³ Autor ³ Aline Correa do Vale  ³ Data ³ 09.08.2002 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ MaTesInt(ExpN1,ExcC1,ExpC2,ExpC3,ExpC4,ExpC5,ExpC6,ExpC7,    ³±±
±±																	  ExpC8)³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ ExpN1 = Documento de 1-Entrada / 2-Saida                     ³±±
±±³          ³ ExpC1 = Tipo de Operacao Tabela "DF" do SX5                  ³±±
±±³          ³ ExpC2 = Codigo do Cliente ou Fornecedor                      ³±±
±±³          ³ ExpC3 = Codigo da Loja do Cli/Forn                           ³±±
±±³          ³ ExpC4 = Tipo Cliente / Fornecedor                            ³±±
±±³          ³ ExpC5 = Codigo do produto	                                ³±±
±±³          ³ ExpC6 = Campo que contem a TES                               ³±±
±±³          ³ ExpC7 = Tipo Cliente (F=Cons.Final;L=Prod.Rural;R=Revendedor;³±±
±±³                                  S=Solidario;X=Exportacao/Importacao)   ³±±
±±³          ³ ExpC8 = Estado de Origem do documento                        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ ATUALIZACOES SOFRIDAS DESDE A CONSTRUCAO INICIAL.                       ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ PROGRAMADOR  ³ DATA   ³ BOPS ³  MOTIVO DA ALTERACAO                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß*/
User Function MaNatInt(nEntSai,cTpOper,cClieFor,cLoja,cTipoCF,cProduto,cCampo,cTipoCli,cEstOrig,cOrigem)
Local aArea		:= GetArea()
Local aAreaSA1	:= SA1->(GetArea())
Local aAreaSA2	:= SA2->(GetArea())
Local aAreaSB1	:= SB1->(GetArea())
Local aAreaSX3	:= SX3->(GetArea())
Local aTes		:= {}
Local cNatRet	:= "   "
Local cGrupo	:= ""
Local cGruProd	:= ""
Local cQuery	:= ""
Local cQuery1	:= ""
Local cNCM		:= ""
Local cEstado	:= ""
Local cAliasSFM	:= "SFM"
Local cTabela	:= ""
Local lQuery	:= .F.
Local nPosCpo	:= 0
Local nFM_POSIPI:= SFM->(FieldPos("FM_POSIPI"))
Local nFM_EST	:= SFM->(FieldPos("FM_EST"))
Local nFM_MSBLQL:= SFM->(FieldPos("FM_MSBLQL"))
Local nFM_TIPOMO:= SFM->(FieldPos("FM_TIPOMOV"))
Local cAlias	:= ""	//Tabela a ser utiliza para informacoes do produto
Local c_GRTRIB	:= ""	//SBI->BI_GRTRIB	/	SB1->B1_GRTRIB
Local c_POSIPI	:= ""	//SBI->BI_POSIPI	/	SB1->B1_POSIPI
Local c_TS		:= ""
Local c_TE		:= ""
Local cSb1Sbz	:= SuperGetMV("MV_ARQPROD",.F.,"SB1")
Local lArqProp	:= SuperGetMV("MV_ARQPROP",.F.,.F.)
Local bCond		:= {||.T.}
Local bCondAux	:= {||.T.}
Local lAddTes	:= .F.
Local bSort		:= {||}
Local bAddTes	:= {||.T.}
Local bAtTes	:= {||.T.}
Local bIFWhile	:= {||.T.}
Local aRet		:= {}
Local lRet		:= .T.
Local cTesSaiB1	:= ""
Local cTesEntB1	:= ""
Local lGrade	:= MaGrade()
Local nFM_GRPTI	:= SFM->(ColumnPos("FM_GRPTI"))
Local nFM_TPCLI	:= IIF(cPaisLoc == "BRA",SFM->(ColumnPos("FM_TIPOCLI")),0)
Local nB1_GRPTI	:= IIF(cPaisLoc == "BRA",SB1->(ColumnPos("B1_GRPTI")),0)
Local nFM_GRPCST:= SFM->(ColumnPos("FM_GRPCST"))
Local nB1_GRPCST:= IIF(cPaisLoc == "BRA",SB1->(ColumnPos("B1_GRPCST")),0)
Local cGrpcst	:= ""
Local c_GRPCST 	:= "" 
Local c_GRPTI	:= ""
Local cGrpTi	:= ""
Local lTipPed	:= Type("M->C5_TIPO") <> "U"
Local aCndTesInt	:= {} //Array com informações da condição do Tes inTeligente.
Local nQtdeEnq	:= 0
Local cPrOrdClie	:= "{1,2,3,4,5,6,7,8,9,10,11,12}" 
Local cPrOrdForn	:= "{1,2,3,4,5,6,7,8,9,10}" 
Local cOrdClie	:= GetNewPar("MV_OTICLI",cPrOrdClie) //Ordem dos campos da SFM Cliente
Local cOrdForn	:= GetNewPar("MV_OTIFOR",cPrOrdForn) //Ordem dos campos da SFM Fornecedor
Local aOrdSFM	:= {}
Local nCont		:= 0
Local cLogTes	:= ""
Local nQtdEmp	:= 0
Local nPosQtdEnq	:= 0
Local lFmId			:= SFM->(FieldPos("FM_ID")) > 0
Local cIdFM		:= '' 
Local cRecno	:= ''
Local nFM_ORIGEM:= SFM->(FieldPos("FM_ORIGEM"))
Local oStatement 
Local aSetParam := {}
Local nJ := 0

DEFAULT cTpOper  := &(ReadVar())
DEFAULT cClieFor := ""
DEFAULT cProduto := ""
DEFAULT nEntSai  := 0
DEFAULT cTipoCF  := "C"
DEFAULT cCampo   := ""
DEFAULT cTipoCli := Iif(Type("M->C5_TIPOCLI")<>"U",M->C5_TIPOCLI,"")
DEFAULT cEstOrig := ""
DEFAULT cOrigem  := "" 	

//---------------------------------------------------
//Para nova regra irá buscar ordem dos campos da SFM.
//---------------------------------------------------
If cTipoCF	== 'C'
	If len(cOrdClie) >= 3 .AND. substr(cOrdClie,1,1) == '{' .AND. substr(cOrdClie,Len(cOrdClie),1) == '}'
		aOrdSFM	:= &(cOrdClie)
	EndIF
	
ElseIf len(cOrdForn) >= 3 .AND. substr(cOrdForn,1,1) == '{' .AND. substr(cOrdForn,Len(cOrdForn),1) == '}'
	aOrdSFM	:= &(cOrdForn)	
EndIF

If !Empty(cCampo) .AND. ValType(aHeader) == "A"
	nPosCpo := aScan(aHeader,{|x| AllTrim(x[2]) == AllTrim(cCampo)})
	If nPosCpo > 0
		cTabela := GetSx3Cache(AllTrim(aHeader[nPosCpo,2]),"X3_ARQUIVO")
		RestArea(aAreaSX3)
	EndIf
EndIf
//-----------------------------------------------------
//Verifica o grupo de tributacao do cliente/fornecedor
//-----------------------------------------------------

dbSelectArea(IIf(cTipoCF == "C","SA1","SA2"))
dbSetOrder(1)
MsSeek(xFilial()+cClieFor+cLoja)
If cTipoCF == "C"
	cGrupo  := SA1->A1_GRPTRIB
	cEstado := SA1->A1_EST
	If Empty(cTipoCli)
		cTipoCli := SA1->A1_TIPO
	EndIf	
Else
	cGrupo  := SA2->A2_GRPTRIB
	cEstado := SA2->A2_EST
EndIf
//Verifica se cEstOrig foi carregado na chamada da função. Se sim substitui o valor que há em cEstado pelo valor de cEstOrig
If !Empty(cEstOrig) .and. cEstado <> cEstOrig
	cEstado := cEstOrig
EndIf

dbSelectArea("SB1")
dbSetOrder(1)
If dbSeek(xFilial("SB1") + cProduto)
    cAlias   := "SB1"
    c_GRTRIB := "SB1->B1_GRTRIB"
    c_POSIPI := "SB1->B1_POSIPI"
    c_TS     := "SB1->B1_TS"
    c_TE     := "SB1->B1_TE"
    If nB1_GRPTI > 0
        c_GRPTI := "SB1->B1_GRPTI"
    EndIf
    If nB1_GRPCST > 0
        c_GRPCST := "SB1->B1_GRPCST"
    EndIf
    
    If cSb1Sbz == "SBZ"
        // Se existir registro no SBZ (Indicadores de Produtos) busca as informacoes desta tabela 
        c_GRTRIB  := "SBZ->BZ_GRTRIB"
        dbSelectArea("SBZ")
        SBZ->(dbSetOrder(1)) //BZ_FILIAL+BZ_PRODUTO
        If DbSeek(xFilial("SBZ") + cProduto) .And. lArqProp .And.!Empty(SBZ->BZ_GRTRIB)//O parametro eh true e o campo esta preenchido?
            // sim
            cGruProd := &(c_GRTRIB)
        ElseIf !lArqProp  // O parametro eh false busca o conteudo vazio da tabela SBZ
            cGruProd := &(c_GRTRIB)
        Else // Neste caso o parametro eh true e busca as informacoes na Tabela SB1
            c_GRTRIB := "SB1->B1_GRTRIB"
            cGruProd := &(c_GRTRIB)
        EndIf
    Else // neste caso busca as informacoes na tabela SB1 apenas
        cGruProd := &(c_GRTRIB)
        cTesSaiB1:= &(c_TS)
        cTesEntB1:= &(c_TE)
        If nB1_GRPTI > 0
            cGrpTI := &(c_GRPTI)
        EndIf
        If nB1_GRPCST > 0
            cGrpcst := &(c_GRPCST)
        EndIf
    EndIf
    // Como não existe o campo NCM na SBZ, não sendo o módulo 23, será verificado na SB1
    If !Empty(c_POSIPI)
        cNCM := &(c_POSIPI)
    Endif
    // Como não existe o campo GRUPO TI na SBZ, não sendo o módulo 23, será verificado na SB1
    If !Empty(c_GRPTI)
        cGrpTI := &(c_GRPTI)
    Endif

EndIf

If cTipoCF == "C" 	
    bAddTes		:=	{||aAdd(aTes, {(cAliasSFM)->FM_PRODUTO,;
                (cAliasSFM)->FM_GRPROD,;
                IIf(nFM_POSIPI>0,(cAliasSFM)->FM_POSIPI,""),;
                (cAliasSFM)->FM_CLIENTE,;
                (cAliasSFM)->FM_LOJACLI,;
                (cAliasSFM)->FM_GRTRIB,;
                IIf(nFM_EST>0,(cAliasSFM)->FM_EST,""),;
                (cAliasSFM)->FM_TE,;
                (cAliasSFM)->FM_TS,;
                Iif(lGrade,(cAliasSFM)->FM_REFGRD,""),;
                Iif(nFM_GRPTI > 0, (cAliasSFM)->FM_GRPTI, ""),;
                Iif(nFM_TPCLI > 0, (cAliasSFM)->FM_TIPOCLI, ""),;
                Iif(nFM_GRPCST > 0, (cAliasSFM)->FM_GRPCST, ""),;
                nQtdeEnq,;
                Iif(nFM_TIPOMO > 0, (cAliasSFM)->FM_TIPOMOV, ""),;
                Iif(lFmId,(cAliasSFM)->FM_ID ,''),;
                (cAliasSFM)->R_E_C_N_O_,;
                Iif(nFM_ORIGEM > 0, (cAliasSFM)->FM_ORIGEM, ""),;
                Iif(nFM_ORIGEM > 0, (cAliasSFM)->FM_L_NATUR, "")})}

    bSort		:=	{|x,y| x[14] > y[14]}
Else
    bAddTes		:=	{|| aAdd(aTes,{(cAliasSFM)->FM_PRODUTO,;
                (cAliasSFM)->FM_GRPROD,;
                IIf(nFM_POSIPI>0,(cAliasSFM)->FM_POSIPI,""),;
                (cAliasSFM)->FM_FORNECE,;
                (cAliasSFM)->FM_LOJAFOR,;
                (cAliasSFM)->FM_GRTRIB,;
                IIf(nFM_EST>0,(cAliasSFM)->FM_EST,""),;
                (cAliasSFM)->FM_TE,;
                (cAliasSFM)->FM_TS,;
                Iif(lGrade,(cAliasSFM)->FM_REFGRD,""),;
                Iif(nFM_GRPTI > 0, (cAliasSFM)->FM_GRPTI, ""),;
                Iif(nFM_GRPCST > 0, (cAliasSFM)->FM_GRPCST, ""),;
                nQtdeEnq,;
                Iif(lFmId,(cAliasSFM)->FM_ID ,''),;
                (cAliasSFM)->R_E_C_N_O_,;
                Iif(nFM_ORIGEM > 0, (cAliasSFM)->FM_ORIGEM, ""),;
                Iif(nFM_ORIGEM > 0, (cAliasSFM)->FM_L_NATUR, "")})}

	bSort		:=	{|x,y| x[13] > y[13]}
EndIf

bIRWhile		:=	{||((cAliasSFM)->(!Empty(FM_GRTRIB) .And. !Empty(FM_GRPROD)) .And. AllTrim(cGrupo)+AllTrim(cGruProd)==(cAliasSFM)->(AllTrim(FM_GRTRIB)+AllTrim(FM_GRPROD))) .Or.;
					(cAliasSFM)->(Empty(FM_GRTRIB) .Or. Empty(FM_GRPROD))}

//----------------------------------------------------------------
//Ponto de entrada que permite alterar a regra de selecao do TES,
//alterar a ordem do array com os elementos encontrados pela
//rotina e alterar o conteudo do array com os campos do SFM.
//Todos os retornos tem que ser em forma de CodBlock.
//Caso seja incluido campo novo para ser tratado na regra, se faz
//necessario incluir no X2_UNICO do SFM.
//----------------------------------------------------------------
If ExistBlock("MT089CD")
	aRet		:= Execblock("MT089CD",.T.,.T.,{bCond,bSort,bIRWhile,bAddTes,cTabela,cTpOper})
	bCondAux	:= aRet[1]
	bSort		:= aRet[2]
	bIFWhile	:= aRet[3]
	bAtTes		:= aRet[4]
	If Len(aRet) > 4
		cTpOper	:= aRet[5]
	EndIf
EndIf

//---------------------------------------------------
//Pesquisa por todas as regras validas para este caso
//---------------------------------------------------

//--------------------------------------------------------
//Ponto de entrada para tratar seleção da tes inteligente
//--------------------------------------------------------
If (ExistBlock("MT089TES"))
    cRet := ExecBlock("MT089TES",.F.,.F.,{nEntSai,cTpOper,cClieFor,cLoja,cProduto})
    If Valtype( cRet ) == "C"
        cQuery := cRet
        lQuery := .T.
        lRet := .F.
    EndIf
EndIf
If(lRet)
    lQuery := .T.
    cAliasSFM := GetNextAlias()
    oStatement := FwPreparedStatement():new()
    cQuery += "SELECT  
    If !Empty(cProduto)
        cQuery1 += Iif(EMPTY(cQuery1)," ( ","")+" (CASE "
        cQuery1 += "		WHEN SFM.FM_PRODUTO = ?"
        cQuery1 += "		THEN 1
        cQuery1 += "		ELSE 0
        cQuery1 += "	END)
        Aadd(aSetParam, cProduto)
    EndIf
    If !Empty(cGruProd)
        cQuery1 += Iif(!EMPTY(cQuery1)," + "," ( ")+" (CASE
        cQuery1 += "	  WHEN SFM.FM_GRPROD = ?"
        cQuery1 += "	  THEN 1
        cQuery1 += "	  ELSE 0
        cQuery1 += "  END)
        Aadd(aSetParam, cGruProd)
    EndIf
    If !Empty(cGrupo)
        cQuery1 += Iif(!EMPTY(cQuery1)," + "," ( ")+" (CASE
        cQuery1 += "  WHEN SFM.FM_GRTRIB = ?"
        cQuery1 += "  THEN 1
        cQuery1 += "  ELSE 0
        cQuery1 += " END)
        Aadd(aSetParam, cGrupo)
    EndIf
    If cTipoCF == "C" .And. !Empty(cClieFor) .And. !Empty(cLoja)
        cQuery1 += Iif(!EMPTY(cQuery1)," + "," ( ")+" (CASE
        cQuery1 += "	WHEN SFM.FM_CLIENTE = ? AND SFM.FM_LOJACLI = ?"
        cQuery1 += "	THEN 1
        cQuery1 += "	ELSE 0
        cQuery1 += " END)
        Aadd(aSetParam, cClieFor)
        Aadd(aSetParam, cLoja)
    EndIf
    If cTipoCF == "F" .And. !Empty(cClieFor) .And. !Empty(cLoja)
        cQuery1 += Iif(!EMPTY(cQuery1)," + "," ( ")+" (CASE
        cQuery1 += "	WHEN SFM.FM_FORNECE = ? AND SFM.FM_LOJAFOR = ?"
        cQuery1 += "	THEN 1
        cQuery1 += "	ELSE 0
        cQuery1 += " END)
        Aadd(aSetParam, cClieFor)
        Aadd(aSetParam, cLoja)
    EndIf
    If !Empty(cEstado)
        cQuery1 += Iif(!EMPTY(cQuery1)," + "," ( ")+" (CASE 
        cQuery1 += "	WHEN SFM.FM_EST = ?"
        cQuery1 += "	THEN 1
        cQuery1 += "	ELSE 0
        cQuery1 += " END)
        Aadd(aSetParam, cEstado)
    EndIf
    If lTipPed .And. !Empty(M->C5_TIPO) .And. nFM_TIPOMO > 0
        cQuery1 += Iif(!EMPTY(cQuery1)," + "," ( ")+" (CASE 
        cQuery1 += "	WHEN SFM.FM_TIPOMOV = ?"
        cQuery1 += "	THEN 1
        cQuery1 += "	ELSE 0
        cQuery1 += " END)
        Aadd(aSetParam, M->C5_TIPO)
    EndIf
    If !Empty(cNCM)
        cQuery1 += Iif(!EMPTY(cQuery1)," + "," ( ")+" (CASE 
        cQuery1 += "	WHEN SFM.FM_POSIPI = ?"
        cQuery1 += "	THEN 1
        cQuery1 += "	ELSE 0
        cQuery1 += " END)
        Aadd(aSetParam, cNCM)
    EndIf
    If !Empty(cGrpTi)
        cQuery1 += Iif(!EMPTY(cQuery1)," + "," ( ")+" (CASE 
        cQuery1 += "	WHEN SFM.FM_GRPTI = ?"
        cQuery1 += "	THEN 1
        cQuery1 += "	ELSE 0
        cQuery1 += " END)
        Aadd(aSetParam, cGrpTi)
    EndIf
    If !Empty(cTipoCli)
        cQuery1 += Iif(!EMPTY(cQuery1)," + "," ( ")+" (CASE 
        cQuery1 += "	WHEN SFM.FM_TIPOCLI = ?"
        cQuery1 += "	THEN 1
        cQuery1 += "	ELSE 0
        cQuery1 += " END)
        Aadd(aSetParam, cTipoCli)
    EndIf
    If !Empty(cGrpcst)
        cQuery1 += Iif(!EMPTY(cQuery1)," + "," ( ")+" (CASE 
        cQuery1 += "	WHEN SFM.FM_GRPCST = ?"
        cQuery1 += "	THEN 1
        cQuery1 += "	ELSE 0
        cQuery1 += " END)
        Aadd(aSetParam, cGrpcst)
    EndIf
    If !Empty(cOrigem)
        cQuery1 += Iif(!EMPTY(cQuery1)," + "," ( ")+" (CASE 
        cQuery1 += "	WHEN SFM.FM_ORIGEM = ?"
        cQuery1 += "	THEN 1
        cQuery1 += "	ELSE 0
        cQuery1 += " END)
        Aadd(aSetParam, cOrigem)
    EndIf

    cQuery += Iif(!Empty(cQuery1),cQuery1+") QTDREGRA, ","")+"SFM.* FROM " + RetSqlName("SFM") + " SFM "
    cQuery += "WHERE SFM.FM_FILIAL = '" + xFilial("SFM") + "' "
    If nFM_MSBLQL > 0
        cQuery += "AND FM_MSBLQL <> '1'"
    EndIf
    cQuery += "AND SFM.FM_TIPO = ?"
    cQuery += "AND SFM.D_E_L_E_T_=' ' "
    cQuery += "ORDER BY "+Iif(!Empty(cQuery1),"QTDREGRA DESC,","")+SqlOrder(SFM->(IndexKey()))
    Aadd(aSetParam, cTpOper)
EndIf
cAliasSFM := GetNextAlias()
//	cQuery := ChangeQuery(cQuery)
oStatement:SetQuery(cQuery)

for nJ := 1 to LEN(aSetParam)
    oStatement:SetString(nJ,aSetParam[nJ])
next

cQuery:= oStatement:GetFixQuery()

dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliasSFM,.T.,.T.)

lQuery1 := Iif(!Empty(cQuery1), .T., .F.) 
nQTDREGRA := Iif(lQuery1,(cAliasSFM)->QTDREGRA,0)

If ValType(nQTDREGRA) == "C"
	nQTDREGRA := Val(nQTDREGRA)
EndIf

While (cAliasSFM)->(!Eof()) .And. (cAliasSFM)->FM_TIPO==cTpOper
	// Caso a quantidade de regras atendidas seja igual a zero, significa que
	// não existe regra de TES Inteligente que atenda ao cenário informado.
	If ( lQuery1 .AND. (cAliasSFM)->QTDREGRA == 0 ) .AND. ( !Empty( aTes ) .OR. ( Empty( aTes ) .AND. !RegraGener( cAliasSFM ) ) )
		If Empty( aTes )
			(cAliasSFM)->( dbSkip() )
			Loop
		else
			Exit
		EndIf
	EndIf
	
	//Será considerado como prioridade a maior quantidade de campos enquadrados
	lAddTes	:= .F.
	nQtdeEnq	:= 0			
	If !Empty((cAliasSFM)->FM_TS) .Or. !Empty((cAliasSFM)->FM_TE)

		aCndTesInt	:= Condicao(cAliasSFM,	nFM_EST,	nFM_TIPOMO,	nFM_POSIPI,	nFM_GRPTI,;
								nFM_TPCLI,	nFM_GRPCST,	lGrade,		cTipoCF,	cProduto,;
								cGruProd,	cClieFor,	cLoja,		cGrupo,		cEstado,;
								cNCM,		cGrpTi,		cTipoCli,	cGrpcst,	lTipPed,;
								nFM_ORIGEM, cOrigem)

		nQtdeEnq	:= aCndTesInt[2]
		lAddTes	:= aCndTesInt[1]
	EndIF

	IF lAddTes .AND. Eval(bCondAux)
		If Eval(bIRWhile) .And. Eval(bIFWhile)
			Eval(bAddTes)//Adiciono o conteudo original da rotina
			Eval(bAtTes) //Caso o ponto de entrada MT089CD esteja ativo, adiciono o retorno dele
		EndIf
	EndIf

	(cAliasSFM)->( dbSkip() )
EndDo

If ( lQuery )
	(cAliasSFM)->( dbCloseArea() )
	dbSelectArea("SFM")
EndIf
//---------------------------------------------------
//Pesquisa por todas as regras validas para este caso
//---------------------------------------------------
aSort(aTES,,,bSort) //Ordena o array conforme passado na regra do bSort, podendo ser alterardo pelo PE MT089CD

//Caso utilize ponto de entrada, mantenho o legado do sistema
If !ExistBlock("MT089CD")	
	//------------------------------------------------------------------
	//Para nova regra, deverá verificar se houve empate de enquadramento
	//------------------------------------------------------------------
	//Verifica se existe empate, se existir irá desempatar pela regra do cliente	
	If !Desempate(@aTes,cTipoCF,aOrdSFM, Iif(cTipoCF == 'C',cPrOrdClie ,cPrOrdForn ))
		
		//Se não conseguiu desempatar pela regra do cliente irá tentar desempatar pela regra padrão
		IF !Desempate(@aTes,cTipoCF,,Iif(cTipoCF == 'C',cPrOrdClie ,cPrOrdForn ))
			//Se ainda assim não conseguiu desempatar, pela regra do cliente e pela regra padrão
			//é porque existem regras cadastradas na SFM somente com tipo de movimento igual copm TES diferente ou
			//regras com mesmo campos chaves iguais, neste caso não irei sugerir nenhum TES pois este cadastro está duplicado.
			//Por este motivo irei zerar o aTES  
			//Abaixo trecho de LOG para incidar regras de TES que estão empatadas e que a rotina não irá sugerir por falta de critério
			//o usuário deverá analisar estes empates para rever as regras e eliminar regras conflitantes.			
			
			nPosQtdEnq	:= Iif(cTipoCF == "C",14,13)			
			nQtdEmp	:= aTES[1][nPosQtdEnq]  
			
		//	ProcLogIni({})
		//	ProcLogAtu("INICIO","--- Regras Empradas TES Inteligente ---",,'MaNatInt')
			For nCont := 1 to len(aTES)
				
				cIdFM	:= ''
				If lFmId
					cIdFM	:= aTES[nCont][Iif(cTipoCF == "C",16,14)]					
				EndIF
				
				cRecno	:= cvaltochar(aTES[nCont][Iif(cTipoCF == "C",17,15)]) 			
							
				//Somente irei guardar LOG dos empates com maior número de enquadramento
				IF nQtdEmp ==  aTES[nCont][nPosQtdEnq]
					cLogTes	+= Iif(!Empty(cIdFM),'Código da Regra de TES Inteligente: ' + cIdFM ,'' ) + " TES: " + aTES[nCont][ Iif(nEntSai==1,8,9) ] + " Tipo de Movimentação: " +  cTpOper +" Rotina: " + FunName() + " RECNO: " + cRecno +  CHR(10)+CHR(13)	+  CHR(10)+CHR(13)				
				Else					 
					Exit
				EndIF 
				
			Next nCont			
			
			//ProcLogAtu("ERRO","Existem Regras de Tes inteligente Empatadas!",cLogTes,'MaNatInt')
			//ProcLogAtu("FIM","--- Regras Empradas TES Inteligente ---",,'MaNatInt')
			aTES	:= {}
		EndIF		
	EndIF
EndIF

If Len(aTes) <> 0
	//cTesRet := If(nEntSai==1,aTes[1][8],aTes[1][9])
    cNatRet := If(nEntSai==1,aTes[1][17],aTes[1][19])
EndIf
//---------------------------------
//Restaura a integridade da rotina
//---------------------------------
RestArea(aAreaSA2)
RestArea(aAreaSA1)
RestArea(aAreaSB1)
RestArea(aArea)
Return(cNatRet)

//-------------------------------------------------------------------
/*/{Protheus.doc} Condicao
 
Esta função irá definir se as regras da SFM processada deverá ou não ser considerada
para sugestão de TES.
Serão consideradas as regras que tiverem informações IGUAIS da nota  


@return	{lRet , nQtdeEnq}   - Array onde a primeira posição é se SFM deverá ou não ser considerada			
@return	{lRet , nQtdeEnq}   - Array onde a segunda posição é a quantidade de campos enquadrados
@author Erick G. Dias
@since 12/05/2016
@version 11.80

/*/
//-------------------------------------------------------------------
Static Function Condicao(cAliasSFM,	nFM_EST,	nFM_TIPOMO,	nFM_POSIPI,	nFM_GRPTI,;
						nFM_TPCLI,	nFM_GRPCST,	lGrade,		cTipoCF,	cProduto,;
						cGruProd,	cClieFor,	cLoja,		cGrupo,		cEstado,;
						cNCM,		cGrpTi,		cTipoCli,	cGrpcst,	lTipPed,;
						nFM_ORIGEM, cOrigem)

Local lPRODUTO := .F.
Local lREFGRD  := .F.
Local lGRPROD  := .F.
Local lCLILOJA := .F.
Local lFORLOJA := .F.
Local lGRTRIB  := .F.
Local lEST     := .F.
Local lTIPOMOV := .F.
Local lPOSIPI  := .F.
Local lGRPTI   := .F.
Local lTIPOCLI := .F.
Local lGRPCST  := .F.
Local lRet     := .F.
Local lORIGEM  := .F. 
Local nQtdeEnq := 0

//---------------------------------------------------------------------------
//INICIALIZA AS TODAS VARIÁVEIS COM .T. CASO A INFORMAÇÃO DA SFM ESTEJA VAZIA
//---------------------------------------------------------------------------
lPRODUTO := Empty((cAliasSFM)->FM_PRODUTO)
lGRPROD  := Empty((cAliasSFM)->FM_GRPROD)
lGRTRIB  := Empty((cAliasSFM)->FM_GRTRIB)
lCLILOJA := Empty((cAliasSFM)->(FM_CLIENTE+FM_LOJACLI))
lFORLOJA := Empty((cAliasSFM)->(FM_FORNECE+FM_LOJAFOR))
lREFGRD  := Iif (cPaisLoc == "BRA" .And. Empty((cAliasSFM)->FM_REFGRD),.T.,.F.)
lEST     := Iif((nFM_EST    > 0 .AND. Empty((cAliasSFM)->FM_EST))     .OR. nFM_EST    == 0,.T.,.F.)
lTIPOMOV := Iif((cPaisLoc == "BRA" .And. nFM_TIPOMO > 0 .AND. Empty((cAliasSFM)->FM_TIPOMOV)) .OR. nFM_TIPOMO == 0,.T.,.F.)
lPOSIPI  := IIf((nFM_POSIPI > 0 .AND. Empty((cAliasSFM)->FM_POSIPI))  .OR. nFM_POSIPI == 0,.T.,.F.)
lGRPTI   := Iif((nFM_GRPTI  > 0 .AND. Empty((cAliasSFM)->FM_GRPTI))   .OR. nFM_GRPTI  == 0,.T.,.F.)
lTIPOCLI := Iif((cPaisLoc == "BRA" .And. nFM_TPCLI  > 0 .AND. EmptY((cAliasSFM)->FM_TIPOCLI)) .OR. nFM_TPCLI  == 0,.T.,.F.)
lGRPCST  := Iif((nFM_GRPCST > 0 .AND. Empty((cAliasSFM)->FM_GRPCST))  .OR. nFM_GRPCST == 0,.T.,.F.)
lREFGRD  := Iif (cPaisLoc <> "BRA" ,.T.,lREFGRD)
lORIGEM  := Iif(nFM_ORIGEM > 0,Iif(Empty((cAliasSFM)->FM_ORIGEM),.T.,.F.),.T.)

//----------------------------------------------------------------------------------------------------------------------
//SE TODOS OS CAMPOS DA SFM ESTIVEREM VAZIOS, ENTÃO IRÁ ADICIONAR E NÃO TERÁ NENHUM ENQUADRAMENTO, É UMA REGRA GENÉRICA
//----------------------------------------------------------------------------------------------------------------------
If lCLILOJA .AND. lFORLOJA .AND. lEST   	.AND. lGRTRIB  .AND. lPRODUTO .AND. lGRPROD  .AND. ;
	lPOSIPI .AND. lREFGRD  .AND. lTIPOMOV  .AND. lGRPTI  .AND. lTIPOCLI .AND. lGRPCST .AND. lORIGEM
	lRet	:= .T.
EndIF
//------------------------------------------------------------------------
//VERIFICA CAMPO POR CAMPO DA SFM COMPARANDO COM INFORMAÇÃO DA NOTA FISCAL
//SOMENTE SE ALGUM CAMPO DA SFM ESTIVER PREENCHIDO
//------------------------------------------------------------------------

If !lRet

	If !lPRODUTO .And. Alltrim(cProduto) == Alltrim((cAliasSFM)->FM_PRODUTO)
		nQtdeEnq	++
		lPRODUTO	:= .T.
	EndIF
	
	If lGrade .AND. !lREFGRD .And. Alltrim((cAliasSFM)->FM_REFGRD) 	== Alltrim(cProduto)
		nQtdeEnq	++
		lREFGRD	:= .T.
	EndIF
	
	If !lGRPROD .AND. Alltrim(cGruProd) == Alltrim((cAliasSFM)->FM_GRPROD)
		nQtdeEnq	++
		lGRPROD	:= .T.
	EndIF
	
	If cTipoCF == 'C'
		If !lCLILOJA .AND. Alltrim(cClieFor+cLoja)  == Alltrim((cAliasSFM)->(FM_CLIENTE+FM_LOJACLI))
			nQtdeEnq	++
			lCLILOJA	:= .T.
		EndIF
	Else
		If !lFORLOJA .AND. Alltrim(cClieFor+cLoja) == Alltrim((cAliasSFM)->(FM_FORNECE+FM_LOJAFOR)) 
			nQtdeEnq	++
			lFORLOJA	:= .T.
		EndIF
	EndIF
	
	If !lGRTRIB .And. AllTrim(cGrupo) == AllTrim((cAliasSFM)->FM_GRTRIB)
		nQtdeEnq	++
		lGRTRIB	:= .T.
	EndIF
	
	If nFM_EST> 0 .And. !lEST .And. Alltrim(cEstado) == Alltrim((cAliasSFM)->FM_EST)
		nQtdeEnq	++
		lEST	:= .T.
	EndIF
	
	If !lTipPed .Or.(nFM_TIPOMO > 0 .And. lTipPed .And. !lTIPOMOV .And. Alltrim(M->C5_TIPO) == Alltrim((cAliasSFM)->FM_TIPOMOV))
		nQtdeEnq	++
		lTIPOMOV	:= .T.
	EndIF
	
	If nFM_POSIPI >0 .And. !lPOSIPI .And. Alltrim(cNCM) == Alltrim((cAliasSFM)->FM_POSIPI)
		nQtdeEnq	++
		lPOSIPI	:= .T.
	EndIF
	
	If nFM_GRPTI > 0 .And. !lGRPTI .And. Alltrim(cGrpTi) == Alltrim((cAliasSFM)->FM_GRPTI)
		nQtdeEnq	++
		lGRPTI	:= .T.
	EndIF
	
	If cTipoCF == 'C'
		If nFM_TPCLI > 0 .And. !lTIPOCLI .And. Alltrim(cTipoCli) == Alltrim((cAliasSFM)->FM_TIPOCLI)
			nQtdeEnq	++  
			lTIPOCLI	:= .T.
		EndIF
	EndIF
	
	If nFM_GRPCST > 0 .And. !lGRPCST .And. Alltrim(cGrpcst) == Alltrim((cAliasSFM)->FM_GRPCST)
		nQtdeEnq	++
		lGRPCST	:= .T.
	EndIF

	If nFM_ORIGEM > 0 .And. !lORIGEM .And. Alltrim(cOrigem) == Alltrim((cAliasSFM)->FM_ORIGEM) 
		nQtdeEnq	++
		lORIGEM	:= .T.
	EndIF

	//------------------------------------------------------------
	//FAZ VERIFICAÇÃO SE AS INFORMAÇÕES DA SFM PODERÁ SER SUGERIDA
	//------------------------------------------------------------
	If (Iif(cTipoCF == 'C',lCLILOJA,lFORLOJA)).AND. lEST   .AND. lGRTRIB  .AND. lPRODUTO .AND. lGRPROD  .AND. ;
		lPOSIPI .AND. lREFGRD  .AND. Iif(cTipoCF == 'C',lTIPOMOV,.T.) .AND. lGRPTI  .AND. Iif(cTipoCF == 'C',lTIPOCLI,.T.) .AND. lGRPCST .AND. lORIGEM 
		
		lRet	:= .T.	
	EndIF
	
EndIF

Return {lRet , nQtdeEnq}

//-------------------------------------------------------------------
/*/{Protheus.doc} Desempate
 
Esta função é responsável por resolver possível empate das regras,
caso existam duas ou mais Tes com a mesma quantidade de campos enquadrados,
caso exista, irá definir a Tes considerando ordem dos campos prioritários da SFM,
seja pela ordem padrão ou pela ordem definida pelo cliente 
  
@param  	aTes      - Array com informações dos Tes enquadrados
			cTipoCF   -Indca operação com Cliente 'C' ou fornecedor 'F'
			lRet      - Booleano indicando que houve desempate.
			

@return	lRet 	   - Retornar booleano, indicando que campo em questão está preenchido no aTes			
@author Erick G. Dias
@since 12/05/2016
@version 11.80

/*/
//-------------------------------------------------------------------
Static Function Desempate(aTes,cTipoCF,aOrdemTes, cOrdSFM)

Local nCont		:= 0
Local nQtde		:= 0
Local nContTes	:= 0
Local bSort		:=	Iif(cTipoCF == 'C',{|x,y| x[14] > y[14]},{|x,y| x[13] > y[13]})
Local lAlt			:= .F.
Local lRet			:= .F.
Local nPosATes	:= Iif(cTipoCF == 'C',14,13)

Default aOrdemTes	:= &(cOrdSFM)  //Ordem padrão do sistema

//Verifica se existem regras empatadas no array aTes
//A variável nQtde terá a quantidade de TES empatadas
If CheckEmpate(aTes,@nQtde,cTipoCF)

	//Aqui existem pelo menos duas regras empatadas.	Irá então processar a ordem dos campos de prioridade para desempatar e sugerir o TES
	For nCont := 1 to Len(aOrdemTes)
		lAlt	:= .F.
		//Irá verificar em todos os tes empatados a ordem dos campos
		For nContTes	:= 1 to nQtde		
			
			If ChkOrdSFM(aTes[nContTes],aOrdemTes[nCont],cTipoCF)
				//Se atendeu a regra da ordem prioritária, irá incrementar o número de enquadramento
				aTes[nContTes][nPosATes] ++
				lAlt	:= .T.
			EndIF
		
		Next nContTes
		
		//Somente irá processar se houve alteração em alguma regra 
		If lAlt		
			//Após verificar o campo em todos as regras empatadas, irá então ordenar novamente para ver se
			//ainda resta regras empatadas
			aSort(aTES,,,bSort)
			//Deverá verificar aqui se desempatou
			If !CheckEmpate(aTes,,cTipoCF)
				//Não há mais empate, foi resolvido com o processamento da ordem dos campos e não deverá mais verificar os
				//demais campos da ordem de prioridade
				lRet	:= .T.
				Exit
			Endif
		EndIF	
									
	Next nCont		
Else
	//Não houve empate, não será necessário processar ordem prioritária dos campos
	lRet	:= .T.
EndIf

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} CheckEmpate
 
Função que irá percorrer o array aTes, verifica se existe regras com o 
mesmo número de campos enquadrados, ou seja, estão empatados.
  
@param  	aTes      - Array com informações dos Tes enquadrados
			nQtde     - Quantidade de Tes empatadas
			cTipoCF   -Indca operação com Cliente 'C' ou fornecedor 'F'
@return	(nQtde>1)  - Retornar booleano, indicando que existem Tes empatadas			
@author Erick G. Dias
@since 12/05/2016
@version 11.80

/*/
//-------------------------------------------------------------------
Static Function CheckEmpate(aTes,nQuantidad,cTipoCF)
Local nContEmp		:= 0
Local nQtdeEnq	:= 0
Local nPosATes	:= Iif(cTipoCF == 'C',14,13)
Default nQuantidad		:= 0

//Verifica se existem regras empatadas
For nContEmp	:= 1 to Len(aTes)	
	If  aTes[nContEmp][nPosATes] >= nQtdeEnq
		nQtdeEnq	:= aTes[nContEmp][nPosATes]
		nQuantidad++
	Else
		Exit
	EndIF
	
Next nContEmp

Return (nQuantidad>1)


//-------------------------------------------------------------------
/*/{Protheus.doc} ChkOrdSFM
 
Função que faz a verificação se determinado campo do aTes está preenhido.
Esta função é utilizada para processar ´critério de desempate,
verificando campo por campo se está prenhido, considerando ordem de 
prioridade dos campos da SFM, seja ordem padrão ou ordem definida pelo Cliente
  
@param  	aTes      - Array com informações dos Tes enquadrados
			nOrdem    - Número que corresponde ao campo da tabela SFM
			cTipoCF   -Indca operação com Cliente 'C' ou fornecedor 'F'

@return	lRet 	   - Retornar booleano, indicando que campo em questão está preenchido no aTes			
@author Erick G. Dias
@since 12/05/2016
@version 11.80

/*/
//-------------------------------------------------------------------
Static Function ChkOrdSFM(aTes,nOrdem,cTipoCF)

Local lRet	:= .F.

If cTipoCF == 'C'
	//CLIENTE
	//1==FM_PRODUTO				 	== aTes 01
	//2==FM_GRPROD  					== aTes 02
	//3==FM_POSIPI 					== aTes 03
	//4==FM_CLIENTE+FM_LOJACLI		== aTes4 + aTes5  
	//5==FM_GRTRIB 				 	== aTes6
	//6==FM_EST 					 	== aTes7
	//7==FM_REFGRD 			     	== aTes10
	//8==FM_GRPTI                  == aTes11
	//9==FM_TIPOCLI                == aTes 12
	//10==FM_GRPCST                == aTes 13	
	//11==FM_TIPOMOV				   ==aTes 15
	//12==FM_ORIGEM                == aTes 18
	
	Do Case
		Case nOrdem == 1	
			lRet	:= !Empty(aTes[1]) //FM_PRODUTO 				
		Case nOrdem == 2
			lRet	:= !Empty(aTes[2]) //FM_GRPROD				
		Case nOrdem == 3
			lRet	:= !Empty(aTes[3]) //FM_POSIPI								
		Case nOrdem == 4
			lRet	:= !Empty(aTes[4]+aTes[5]) //FM_CLIENTE+FM_LOJACLI
		Case nOrdem == 5
			lRet	:= !Empty(aTes[6]) //FM_GRTRIB			
		Case nOrdem == 6
			lRet	:= !Empty(aTes[7])//FM_EST				
		Case nOrdem == 7
			lRet	:= !Empty(aTes[10])//FM_REFGRD				
		Case nOrdem == 8
			lRet	:= !Empty(aTes[11])//FM_GRPTI				
		Case nOrdem == 9
			lRet	:= !Empty(aTes[12])//FM_TIPOCLI
		Case nOrdem == 10
			lRet	:= !Empty(aTes[13])//FM_GRPCST
		Case nOrdem == 11
			lRet	:= !Empty(aTes[15])//FM_TIPOMOV						
		Case nOrdem == 12 
			lRet	:= !Empty(aTes[18])//FM_ORIGEM 				
	EndCase
Else	
	//FORNECEDOR
	//1==FM_PRODUTO 			  	  	== aTes 01
	//2==FM_GRPROD  			   		== aTes 02
	//3==FM_POSIPI  			  	    == aTes 03
	//4==FM_FORNECE+FM_LOJAFOR  	== aTes 4 + aTes 5  
	//5==FM_GRTRIB 			   		== aTes 6
	//6==FM_EST                   	== aTes 7
	//7==FM_REFGRD              	== aTes 10
	//8==FM_GRPTI               	== aTes 11
	//9==FM_GRPCST              	== aTes 12
	//10==FM_ORIGEM                 == aTes 16
		
	Do Case
		Case nOrdem == 1	
			lRet	:= !Empty(aTes[1]) //FM_PRODUTO				
		Case nOrdem == 2
			lRet	:= !Empty(aTes[2]) //FM_GRPROD				
		Case nOrdem == 3
			lRet	:= !Empty(aTes[3]) //FM_POSIPI								
		Case nOrdem == 4
			lRet	:= !Empty(aTes[4]+aTes[5]) //FM_FORNECE+FM_LOJAFOR				
		Case nOrdem == 5
			lRet	:= !Empty(aTes[6]) //FM_GRTRIB				
		Case nOrdem == 6
			lRet	:= !Empty(aTes[7]) //FM_EST				
		Case nOrdem == 7
			lRet	:= !Empty(aTes[10]) //FM_REFGRD				
		Case nOrdem == 8
			lRet	:= !Empty(aTes[11]) //FM_GRPTI				
		Case nOrdem == 9
			lRet	:= !Empty(aTes[12]) //FM_GRPCST		
		Case nOrdem == 10 
			lRet	:= !Empty(aTes[16]) //FM_ORIGEM
	EndCase
EndIF

Return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} RegraGener
Retorna se a regra de TES Inteligente é uma regra genérica
@author  Yuri F. Palacio
@since   07.05.2021
@version v1.0
/*/
//-------------------------------------------------------------------
Static Function RegraGener( cAliasSFM )
	Local lRet := .F.

	If Empty( (cAliasSFM)->FM_PRODUTO ) .AND.;
		Empty( (cAliasSFM)->FM_REFGRD ) .AND.;
		Empty( (cAliasSFM)->FM_GRPROD ) .AND.;
		Empty( (cAliasSFM)->( FM_CLIENTE + FM_LOJACLI) ) .AND.;
		Empty( (cAliasSFM)->( FM_FORNECE + FM_LOJAFOR) ) .AND.;
		Empty( (cAliasSFM)->FM_GRTRIB ) .AND.;
		Empty( (cAliasSFM)->FM_EST ) .AND.;
		Empty( (cAliasSFM)->FM_TIPOMOV ) .AND.;
		Empty( (cAliasSFM)->FM_POSIPI ) .AND.;
		Empty( (cAliasSFM)->FM_GRPTI ) .AND.;
		Empty( (cAliasSFM)->FM_TIPOCLI ) .AND.;
		Empty( (cAliasSFM)->FM_GRPCST ) .AND.;
		Empty( (cAliasSFM)->FM_ORIGEM )

		lRet := .T.
	EndIf
Return lRet
