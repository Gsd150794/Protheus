/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |14/04/2025| Chamado 50417. Implementada regra para considerar Centro de Custo
Lucas Borges  |13/11/2025| Chamado 52977. Corrigida regra para o crédito presumido
Lucas Borges  |19/11/2025| Chamado 53054. Alterada conta do ICMS sob Transferências 
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MCTB002
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 09/05/2023
Descrição---------: Retorna conta contábil para os Lançamentos Padrões do Compras, Estoque e Faturamento
Parametros--------: _ccod = Tipo de Conta (650002CC=Conta Credito, 650002CD= Conta Debito)
Retorno-----------: _cRetorno = Retorna a conta contabil
===============================================================================================================================
*/
User Function MCTB002(_cCod)

Local _cRetorno := ' ' as String
Local _aArea 	:= FWGetArea() as Array
Local _cAlias	:= '' as String
Local _cFil01	:= '01/02/03/04/07/08/09/0A/' as String
Local _cFil05	:= '05/' as String
Local _cFil10	:= '10/11/12/13/14/15/16/17/18/19/1A/1B/1C/' as String
Local _cFil20	:= '20/21/22/24/' as String
Local _cFil23	:= '23/' as String
Local _cFil30	:= '30/31/32/33' as String
Local _cFil40	:= '40/' as String
Local _cFil90	:= '90/92/' as String //92 tem que estar no _cFil90 e _cFilAdm
Local _cFil93	:= '93/' as String
Local _cFil94	:= '94/' as String
Local _cFilAdm	:= '06/0B/25/91/92/94/95/96/97/98/' as String
Local _cFil95	:= '95/' as String
Local _cFil96	:= '96/' as String
Local _cFil97	:= '97/' as String
Local _cFil98	:= '98/' as String
Local _cCCusto	:= "" as String
Local _lCCusto	:= .F. as Logical
//_cGEst01 -> Incluir apenas LPs do Estoque que usam a SD3. Os que usam SD1 ou SD2 não devem ser incluídos
Local _cGEst01	:= '666001CC/666002CC/666004CC/666006CC/666007CC/666008CC/666009CC/668001CD/668002CD/668003CD/668004CD/' as String
Local _lHigiene := .F. as Logical
Local _lPeqValor:= .F. as Logical
Local _lUniforme:= .F. as Logical
Local _lConsumo	:= .F. as Logical
Local _lProdProp:= .F. as Logical //Produtos de Produção Própria
Local _lProdRev := SB1->B1_GRUPO $ '0008/0011/0015/0016/0017/0018/0019/0021/0023/0100/0800/0813' .Or. AllTrim(SB1->B1_COD) $ '00060071501/00070070301/00070080301'/*Produtos para revenda*/ as Logical

_lProdProp := ((SB1->B1_GRUPO $ '0001/0002/0003/0004/0005/0006/0007/0009/0010/0012/0013/0014/0020/0022' .Or. AllTrim(SB1->B1_COD) $ '08000000056/10030001911');
	.And. !AllTrim(SB1->B1_COD) $ '00060071501/00070070301/00070080301')

If Select("QRYSD2") > 0
	_cCCusto := 'SD2->D2_CCUSTO'
ElseIf SELECT("QRYSD1") > 0
	_cCCusto := 'SD1->D1_CC'
Else
	_cCCusto := 'SD3->D3_CC'
EndIf
If cFilant $ _cFil01
	_lCCusto	:= (AllTrim(&_cCCusto) >="00100000" .And. AllTrim(&_cCCusto) <="02999999") .Or. (AllTrim(&_cCCusto) >="10100000" .And. AllTrim(&_cCCusto) <="11999999");//Corporativo ou Administrativo
					.Or. (SRA->RA_CATFUNC == 'A' .Or. SRZ->RZ_MAT == 'zzzzzz')//CC dos autônomos podem ter qualquer faixa e todos são cadastrados na Matriz
ElseIf cFilant $ _cFil10
	_lCCusto	:= (AllTrim(&_cCCusto) >="00100000" .And. AllTrim(&_cCCusto) <="02999999") .Or. (AllTrim(&_cCCusto) >="20100000" .And. AllTrim(&_cCCusto) <="21999999")//Corporativo ou Administrativo
ElseIf cFilant $ _cFil20
	_lCCusto	:= (AllTrim(&_cCCusto) >="00100000" .And. AllTrim(&_cCCusto) <="02999999") .Or. (AllTrim(&_cCCusto) >="40100000" .And. AllTrim(&_cCCusto) <="41999999")//Corporativo ou Administrativo
ElseIf cFilant $ _cFil23
	_lCCusto	:= (AllTrim(&_cCCusto) >="00100000" .And. AllTrim(&_cCCusto) <="02999999") .Or. (AllTrim(&_cCCusto) >="90100000" .And. AllTrim(&_cCCusto) <="91999999")//Corporativo ou Administrativo
ElseIf cFilant $ _cFil30
	_lCCusto	:= (AllTrim(&_cCCusto) >="00100000" .And. AllTrim(&_cCCusto) <="02999999") .Or. (AllTrim(&_cCCusto) >="30100000" .And. AllTrim(&_cCCusto) <="31999999")//Corporativo ou Administrativo
ElseIf cFilant $ _cFil40
	_lCCusto	:= (AllTrim(&_cCCusto) >="00100000" .And. AllTrim(&_cCCusto) <="02999999") .Or. (AllTrim(&_cCCusto) >="80100000" .And. AllTrim(&_cCCusto) <="81999999")//Corporativo ou Administrativo
ElseIf cFilant $ _cFil93
	_lCCusto	:= (AllTrim(&_cCCusto) >="00100000" .And. AllTrim(&_cCCusto) <="02999999") .Or. (AllTrim(&_cCCusto) >="A0100000" .And. AllTrim(&_cCCusto) <="A1999999")//Corporativo ou Administrativo
EndIf

//=================================================
//650001CC - Compras Normais - Credito
//=================================================
If _cCod == '650001CC' .And. !Empty(SF1->F1_L_MIX)
	_cRetorno := SA2->A2_CONTA

//=================================================
//650006CC - Compras ISS - Credito
//=================================================
ElseIf _cCod == '650006CC'
	If cFilAnt == '01'
		_cRetorno := '2101020030' //ISS RETIDO A RECOLHER
	ElseIf cFilAnt $ _cFil05
		_cRetorno := '2101020078'
	ElseIf cFilAnt == '06'
		_cRetorno := '2101020094'
	ElseIf cFilAnt == '0B'
		_cRetorno := '2101020093'
	ElseIf cFilAnt == '10'
		_cRetorno := '2101020079'
	ElseIf cFilAnt == '20'
		_cRetorno := '2101020080'
	ElseIf cFilAnt == '23'
		_cRetorno := '2101020081'
	ElseIf cFilAnt == '24'
		_cRetorno := '2101020095'
	ElseIf cFilAnt == '25'
		_cRetorno := '2101020092'
	ElseIf cFilAnt $ _cFil30
		_cRetorno := '2101020099'
	ElseIf cFilAnt $ _cFil40
		_cRetorno := '2101020082'
	ElseIf cFilAnt $ _cFil90
		_cRetorno := '2101020083'
	ElseIf cFilAnt == '91'
		_cRetorno := '2101020084'
	ElseIf cFilAnt $ _cFil93
		_cRetorno := '2101020096'
	EndIf

//=================================================
//640002CD - Devolução Venda ICMS Retido - Débito
//610003CC - Vendas ICMS Substituição - Crédito
//=================================================
ElseIf _cCod $ '640002CD/610003CC'
	If cFilAnt == '01'
		_cRetorno := '2101020065' //ICMS SUB TRIB A PAGAR RJ -CBBA
	ElseIf cFilAnt == '05'
		_cRetorno := '2101020067'
	ElseIf cFilAnt == '10'
		_cRetorno := '2101020012'
	ElseIf cFilAnt == '20'
		_cRetorno := '2101020054'
	ElseIf cFilAnt == '23'
		_cRetorno := '2101020077'
	ElseIf cFilAnt == '31'
		_cRetorno := '2101020114'
	ElseIf cFilAnt == '32'
		_cRetorno := '2101020116'
	ElseIf cFilAnt == '33'
		_cRetorno := '2101020119'
	ElseIf cFilAnt == '40'
		_cRetorno := '2101020073'
	ElseIf cFilAnt == '90'
		_cRetorno := '2101020051'
	ElseIf cFilAnt == '91'
		_cRetorno := '2101020062'
	ElseIf cFilAnt == '93'
		_cRetorno := '2101020098'
	ElseIf cFilAnt == '94'
		_cRetorno := '2101020104'
	ElseIf cFilAnt == '95'
		_cRetorno := '2101020106'
	ElseIf cFilAnt == '96'
		_cRetorno := '2101020108'
	ElseIf cFilAnt == '97'
		_cRetorno := '2101020110'
	ElseIf cFilAnt == '98'
		_cRetorno := '2101020112'
	EndIf

//=================================================
//650011CC - Compras Funrural - Credito
//610012CD - Devolução Compras Funrural - Debito
//=================================================
ElseIf _cCod $ '650011CC/610012CD'
	If cFilAnt == '01'
		_cRetorno := '2101030013' //FUNRURAL A PAGAR-MATRIZ
	ElseIf cFilAnt == '02'
		_cRetorno := '2101030031'
	ElseIf cFilAnt == '04'
		_cRetorno := '2101030014'
	ElseIf cFilAnt == '05'
		_cRetorno := '2101030016'
	ElseIf cFilAnt == '06'
		_cRetorno := '2101030018'
	ElseIf cFilAnt == '09'
		_cRetorno := '2101030093'
	ElseIf cFilAnt == '0A'
		_cRetorno := '2101030094'
	ElseIf cFilAnt == '0B'
		_cRetorno := '2101030100'
	ElseIf cFilAnt == '10'
		_cRetorno := '2101030032'
	ElseIf cFilAnt == '11'
		_cRetorno := '2101030035'
	ElseIf cFilAnt == '12'
		_cRetorno := '2101030074'
	ElseIf cFilAnt == '13'
		_cRetorno := '2101030046'
	ElseIf cFilAnt == '14'
		_cRetorno := '2101030033'
	ElseIf cFilAnt == '15'
		_cRetorno := '2101030034'
	ElseIf cFilAnt == '16'
		_cRetorno := '2101030042'
	ElseIf cFilAnt == '17'
		_cRetorno := '2101030076'
	ElseIf cFilAnt == '18'
		_cRetorno := '2101030043'
	ElseIf cFilAnt == '19'
		_cRetorno := '2101030072'
	ElseIf cFilAnt == '1A'
		_cRetorno := '2101030015'
	ElseIf cFilAnt == '1B'
		_cRetorno := '2101030048'
	ElseIf cFilAnt == '1C'
		_cRetorno := '2101030056'
	ElseIf cFilAnt == '20'
		_cRetorno := '2101030068'
	ElseIf cFilAnt == '21'
		_cRetorno := '2101030065'
	ElseIf cFilAnt == '22'
		_cRetorno := '2101030071'
	ElseIf cFilAnt == '23'
		_cRetorno := '2101030082'
	ElseIf cFilAnt == '24'
		_cRetorno := '2101030088'
	ElseIf cFilAnt == '25'
		_cRetorno := '2101030085'
	ElseIf cFilAnt $ _cFil30
		_cRetorno := '2101030057'
	ElseIf cFilAnt == '40'
		_cRetorno := '2101030079'
	ElseIf cFilAnt == '93'
		_cRetorno := '2101030104'
	EndIf
	
//=================================================
//650013CC - Compras INSS - Credito
//=================================================
ElseIf _cCod == '650013CC'
	If SF1->F1_FORNECE == 'F08828'
		If cFilAnt == '01'
			_cRetorno := '2101030001' //INSS A PAGAR-MATRIZ
		ElseIf cFilAnt == '02'
			_cRetorno := '2101030021'
		ElseIf cFilAnt == '04'
			_cRetorno := '2101030002'
		ElseIf cFilAnt == '05'
			_cRetorno := '2101030005'
		ElseIf cFilAnt == '06'
			_cRetorno := '2101030006'
		ElseIf cFilAnt == '08'
			_cRetorno := '2101030026'
		ElseIf cFilAnt == '09'
			_cRetorno := '2101030089'
		ElseIf cFilAnt == '0A'
			_cRetorno := '2101030091'
		ElseIf cFilAnt == '0B'
			_cRetorno := '2101030098'
		ElseIf cFilAnt == '10'
			_cRetorno := '2101030022'
		ElseIf cFilAnt == '11'
			_cRetorno := '2101030025'
		ElseIf cFilAnt == '12'
			_cRetorno := '2101030073'
		ElseIf cFilAnt == '13'
			_cRetorno := '2101030041'
		ElseIf cFilAnt == '14'
			_cRetorno := '2101030023'
		ElseIf cFilAnt == '15'
			_cRetorno := '2101030024'
		ElseIf cFilAnt == '16'
			_cRetorno := '2101030038'
		ElseIf cFilAnt == '18'
			_cRetorno := '2101030040'
		ElseIf cFilAnt == '19'
			_cRetorno := '2101030049'
		ElseIf cFilAnt == '1A'
			_cRetorno := '2101030003'
		ElseIf cFilAnt == '1B'
			_cRetorno := '2101030017'
		ElseIf cFilAnt == '1C'
			_cRetorno := '2101030052'
		ElseIf cFilAnt == '20'
			_cRetorno := '2101030066'
		ElseIf cFilAnt == '21'
			_cRetorno := '2101030062'
		ElseIf cFilAnt == '22'
			_cRetorno := '2101030069'
		ElseIf cFilAnt == '23'
			_cRetorno := '2101030081'
		ElseIf cFilAnt == '24'
			_cRetorno := '2101030087'
		ElseIf cFilAnt == '25'
			_cRetorno := '2101030084'
		ElseIf cFilAnt $ _cFil30
			_cRetorno := '2101030053'
		ElseIf cFilAnt == '40'
			_cRetorno := '2101030077'
		ElseIf cFilAnt == '90'
			_cRetorno := '2101030058'
		ElseIf cFilAnt == '91'
			_cRetorno := '2101030064'
		ElseIf cFilAnt == '93'
			_cRetorno := '2101020102'
		EndIf
	Else
		_cRetorno := '2101030004' //INSS RETIDO A RECOLHER -PJ
	EndIf
	
//=================================================
//650009CD - Compras ICMS - Debito
//650010CD - Compras ICMS - Debito
//640007CD - Devolução ICMS - Debito
//=================================================
ElseIf _cCod $ '650009CD/650010CD/640007CD'
	If cFilAnt == '01'
		_cRetorno := '1102070001' //ICMS NORMAL RECUP.-MATRIZ
	ElseIf cFilAnt == '02'
		_cRetorno := '1102070027'
	ElseIf cFilAnt == '04'
		_cRetorno := '1102070002'
	ElseIf cFilAnt $ _cFil05
		_cRetorno := '1102070004'
	ElseIf cFilAnt == '06'
		_cRetorno := '1102070003'
	ElseIf cFilAnt == '08'
		_cRetorno := '1102070080'
	ElseIf cFilAnt == '0A'
		_cRetorno := '1102070093'
	ElseIf cFilAnt == '0B'
		_cRetorno := '1102070091'
	ElseIf cFilAnt == '10'
		_cRetorno := '1102070024'
	ElseIf cFilAnt == '11'
		_cRetorno := '1102070036'
	ElseIf cFilAnt == '12'
		_cRetorno := '1102070034'
	ElseIf cFilAnt == '13'
		_cRetorno := '1102070028'
	ElseIf cFilAnt == '14'
		_cRetorno := '1102070025'
	ElseIf cFilAnt == '15'
		_cRetorno := '1102070026'
	ElseIf cFilAnt == '17'
		_cRetorno := '1102070035'
	ElseIf cFilAnt == '18'
		_cRetorno := '1102070030'
	ElseIf cFilAnt == '19'
		_cRetorno := '1102070006'
	ElseIf cFilAnt == '1A'
		_cRetorno := '1102070005'
	ElseIf cFilAnt == '1B'
		_cRetorno := '1102070038'
	ElseIf cFilAnt == '20'
		_cRetorno := '1102070052'
	ElseIf cFilAnt == '21'
		_cRetorno := '1102070047'
	ElseIf cFilAnt == '22'
		_cRetorno := '1102070051'
	ElseIf cFilAnt == '23'
		_cRetorno := '1102070082'
	ElseIf cFilAnt == '24'
		_cRetorno := '1102070084'
	ElseIf cFilAnt == '25'
		_cRetorno := '1102070083'
	ElseIf cFilAnt $ _cFil30
		_cRetorno := '1102070039'
	ElseIf cFilAnt $ _cFil40
		_cRetorno := '1102070075'
	ElseIf cFilAnt == '90'
		_cRetorno := '1102070040'
	ElseIf cFilAnt == '91'
		_cRetorno := '1102070049'
	ElseIf cFilAnt == '92'
		_cRetorno := '1102070072'
	ElseIf cFilAnt $ _cFil93
		_cRetorno := '1102070089'
	ElseIf cFilAnt == '94'
		_cRetorno := '1102070097'
	ElseIf cFilAnt == '95'
		_cRetorno := '1102070098'
	ElseIf cFilAnt == '96'
		_cRetorno := '1102070099'
	ElseIf cFilAnt == '97'
		_cRetorno := '1102070100'
	ElseIf cFilAnt == '98'
		_cRetorno := '1102070101'
	EndIf

//=================================================
//650019CC - Entrada ICMS Complementar - Crédito
//610002CC - Vendas ICMS - Crédito
//610011CC - Devolução Compras ICMS - Crédito
//=================================================
ElseIf _cCod $ '650019CC/610002CC/610011CC'
	If cFilAnt == '01'
		_cRetorno := '2101020004' //ICMS NORMAL-MATRIZ
	ElseIf cFilAnt == '02'
		_cRetorno := '2101020018'
	ElseIf cFilAnt == '04'
		_cRetorno := '2101020005'
	ElseIf cFilAnt $ _cFil05
		_cRetorno := '2101020007'
	ElseIf cFilAnt == '06'
		_cRetorno := '2101020006'
	ElseIf cFilAnt == '08'
		_cRetorno := '2101020072'
	ElseIf cFilAnt == '09'
		_cRetorno := '2101020087'
	ElseIf cFilAnt == '0A'
		_cRetorno := '2101020089'
	ElseIf cFilAnt == '0B'
		_cRetorno := '2101020091'
	ElseIf cFilAnt $ '10/16'
		_cRetorno := '2101020019'
	ElseIf cFilAnt $ '11/12'
		_cRetorno := '2101020029'
	ElseIf cFilAnt == '13'
		_cRetorno := '2101020023'
	ElseIf cFilAnt == '14'
		_cRetorno := '2101020022'
	ElseIf cFilAnt == '15'
		_cRetorno := '2101020021'
	ElseIf cFilAnt $ '17/18'
		_cRetorno := '2101020024'
	ElseIf cFilAnt == '19'
		_cRetorno := '2101020016'
	ElseIf cFilAnt == '1A'
		_cRetorno := '2101020015'
	ElseIf cFilAnt == '1B'
		_cRetorno := '2101020033'
	ElseIf cFilAnt == '20'
		_cRetorno := '2101020053'
	ElseIf cFilAnt == '23'
		_cRetorno := '2101020075'
	ElseIf cFilAnt == '24'
		_cRetorno := '2101020085'
	ElseIf cFilAnt == '25'
		_cRetorno := '2101020076'
	ElseIf cFilAnt $ '30'
		_cRetorno := '2101020034'
	ElseIf cFilAnt == '31'
		_cRetorno := '2101020113'
	ElseIf cFilAnt == '32'
		_cRetorno := '2101020115'
	ElseIf cFilAnt == '33'
		_cRetorno := '2101020118'
	ElseIf cFilAnt $ _cFil40
		If _cCod $ '650019CC' //ICMS Complementar
			_cRetorno := '2101020060'
		Else
			_cRetorno := '2101020069'
		EndIf
	ElseIf cFilAnt == '90'
		_cRetorno := '2101020035'
	ElseIf cFilAnt == '91'
		_cRetorno := '2101020046'
	ElseIf cFilAnt == '92'
		_cRetorno := '2101020066'
	ElseIf cFilAnt $ _cFil93
		_cRetorno := '2101020097'
	ElseIf cFilAnt == '94'
		_cRetorno := '2101020103'
	ElseIf cFilAnt == '95'
		_cRetorno := '2101020105'
	ElseIf cFilAnt == '96'
		_cRetorno := '2101020107'
	ElseIf cFilAnt == '97'
		_cRetorno := '2101020109'
	ElseIf cFilAnt == '98'
		_cRetorno := '2101020111'
	EndIf

//=================================================
//650015CC - PIS - Crédito
//=================================================
ElseIf _cCod == '650015CC'
	If cFilAnt $ _cFil01+_cFil05
		_cRetorno := '3299010016' //(-) PIS S/COMPRAS
	ElseIf cFilAnt $ _cFil10
		_cRetorno := '3299030016'
	ElseIf cFilAnt $ _cFil20
		_cRetorno := '3299070016'
	ElseIf cFilAnt $ _cFil23
		_cRetorno := '3299170016'
	ElseIf cFilAnt $ _cFil30
		_cRetorno := '3299050016'
	ElseIf cFilAnt $ _cFil40
		_cRetorno := '3299130016'
	ElseIf cFilAnt == '90'
		_cRetorno := '3299150016'
	ElseIf cFilAnt $ _cFil93
		_cRetorno := '3299190016'
	EndIf
	
//=================================================
//650016CC - COFINS - Crédito
//=================================================
ElseIf _cCod == '650016CC'
	If cFilAnt $ _cFil01+_cFil05
		_cRetorno := '3299010017' //(-) COFINS S/COMPRAS
	ElseIf cFilAnt $ _cFil10
		_cRetorno := '3299030017'
	ElseIf cFilAnt $ _cFil20
		_cRetorno := '3299070017'
	ElseIf cFilAnt $ _cFil23
		_cRetorno := '3299170017'
	ElseIf cFilAnt $ _cFil30
		_cRetorno := '3299050017'
	ElseIf cFilAnt $ _cFil40
		_cRetorno := '3299130017'
	ElseIf cFilAnt == '90'
		_cRetorno := '3299150017'
	ElseIf cFilAnt $ _cFil93
		_cRetorno := '3299190017'
	EndIf

//=================================================
//650020CD - IPI - Débito
//=================================================
ElseIf _cCod == '650020CD'
	If cFilAnt $ _cFil01+_cFil05
		_cRetorno := '1102070019' //IPI A RECUPERAR MATRIZ
	ElseIf cFilAnt $ _cFil10
		_cRetorno := '1102070400'
	ElseIf cFilAnt $ _cFil20
		_cRetorno := '1102070401'
	ElseIf cFilAnt $ _cFil23
		_cRetorno := '1102070402'
	ElseIf cFilAnt $ _cFil30
		_cRetorno := '1102070406'
	ElseIf cFilAnt $ _cFil40
		_cRetorno := '1102070403'
	ElseIf cFilAnt == '90'
		_cRetorno := '1102070404'
	ElseIf cFilAnt $ _cFil93
		_cRetorno := '1102070405'
	ElseIf cFilAnt $ _cFil95
		_cRetorno := '1102070407'
	ElseIf cFilAnt $ _cFil96
		_cRetorno := '1102070408'
	ElseIf cFilAnt $ _cFil98
		_cRetorno := '1102070409'
	EndIf

//=================================================
//610013CC - IPI - Crédito
//=================================================
ElseIf _cCod == '610013CC'
	If cFilAnt $ _cFil01+_cFil05
		_cRetorno := '2101020400' //IPI A RECOLHER MATRIZ
	ElseIf cFilAnt $ _cFil10
		_cRetorno := '2101020401'
	ElseIf cFilAnt $ _cFil20
		_cRetorno := '2101020402'
	ElseIf cFilAnt $ _cFil23
		_cRetorno := '2101020403'
	ElseIf cFilAnt $ _cFil40
		_cRetorno := '2101020404'
	ElseIf cFilAnt == '90'
		_cRetorno := '2101020405'
	ElseIf cFilAnt $ _cFil93
		_cRetorno := '2101020406'
	ElseIf cFilAnt $ _cFil95
		_cRetorno := '2101020407'
	ElseIf cFilAnt $ _cFil96
		_cRetorno := '2101020408'
	ElseIf cFilAnt $ _cFil98
		_cRetorno := '2101020409'
	EndIf

//============================================================================
//668001CC - Movimento de estoque - Entrada de Produtos - Credito
//666001CD - Movimento de estoque - Saida de Produtos - Debito - Ordem de Produção
//============================================================================
ElseIf _cCod $ '668001CC/666001CD'
	If cFilAnt $ _cFil01
		If SB1->B1_GRUPO =='0014'
			_cRetorno := '1102010139' //ORDEM DE PRODUCAO EM ANDAMENTO MATRIZ TE
		Else
			_cRetorno := '1102010131' //ORDEM DE PRODUCAO EM ANDAMENTO MATRIZ
		EndIf
	ElseIf cFilAnt $ _cFil05
		_cRetorno := '1102010132' //ORDEM DE PRODUCAO EM ANDAMENTO SGH
	ElseIf cFilAnt $ _cFil10
		_cRetorno := '1102010133'
	ElseIf cFilAnt $ _cFil20
		_cRetorno := '1102010134'
	ElseIf cFilAnt $ _cFil23
		_cRetorno := '1102010135'
	ElseIf cFilAnt $ _cFil30
		_cRetorno := '1102010136'
	ElseIf cFilAnt $ _cFil40
		_cRetorno := '1102010137'
	ElseIf cFilAnt == '90'
		_cRetorno := '1102010138'
	ElseIf cFilAnt $ _cFil93
		_cRetorno := '1102010162'
	ElseIf cFilAnt == '94'
		_cRetorno := '1102010172'
	EndIf

//============================================================================
//666002CD - Movimento de estoque - Saida de Produtos - Debito - TM 550/551/552
//============================================================================
ElseIf _cCod $ '666002CD'
	If cFilAnt $ _cFil01
		_cRetorno := '3299029994' //PERDA POR ARMAZENAGEM MATRIZ
	ElseIf cFilAnt $ _cFil05
		_cRetorno := '3299129994'
	ElseIf cFilAnt $ _cFil10
		_cRetorno := '3299049994'
	ElseIf cFilAnt $ _cFil20
		_cRetorno := '3299089994'
	ElseIf cFilAnt $ _cFil23
		_cRetorno := '3299189994'
	ElseIf cFilAnt $ _cFil30
		_cRetorno := '3299069994'
	ElseIf cFilAnt $ _cFil40
		_cRetorno := '3299149994'
	ElseIf cFilAnt == '90'
		_cRetorno := '3299169994'
	ElseIf cFilAnt $ _cFilAdm
		_cRetorno := '3299090005'
	ElseIf cFilAnt $ _cFil93
		_cRetorno := '3299209994'
	EndIf

//============================================================================
//666008CD - Movimento de estoque - Saida de Produtos Inventário - Debito - TM 998/999
//============================================================================
ElseIf _cCod $ '666008CD' .Or. (_cCod $ '666007CD' .And. SD3->D3_TM $ '997')
	If cFilAnt $ _cFil01
		_cRetorno := '3299029993' //AJUSTE DE INVENTARIO MATRIZ
	ElseIf cFilAnt $ _cFil05
		_cRetorno := '3299129993'
	ElseIf cFilAnt $ _cFil10
		_cRetorno := '3299049993'
	ElseIf cFilAnt $ _cFil20
		_cRetorno := '3299089993'
	ElseIf cFilAnt $ _cFil23
		_cRetorno := '3299189993'
	ElseIf cFilAnt $ _cFil30
		_cRetorno := '3299069993'
	ElseIf cFilAnt $ _cFil40
		_cRetorno := '3299149993'
	ElseIf cFilAnt == '90'
		_cRetorno := '3299169993'
	ElseIf cFilAnt $ _cFilAdm
		_cRetorno := '3301010023'
	ElseIf cFilAnt $ _cFil93
		_cRetorno := '3299209993'
	EndIf

//============================================================================
//668002CC - Entrada Saldo em Estoque - Inventário - Credito - TM 498/499
//668003CC - Entrada Saldo em Estoque - Recepção Leite - Credito - TM 001/002/497 (menos a 494)
//============================================================================
ElseIf _cCod $ '668002CC' .Or. (_cCod $ '668003CC' .And. !SD3->D3_TM $ '493/494/495')
	If SD3->D3_TM == '497' .Or. _cCod $ '668002CC'
		If cFilAnt $ _cFil01
			_cRetorno := '3299029991' //( - ) AJUSTE DE INVENTARIO
		ElseIf cFilAnt $ _cFil05
			_cRetorno := '3299129991'
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '3299049991'
		ElseIf cFilAnt $ _cFil20
			_cRetorno := '3299089991'
		ElseIf cFilAnt $ _cFil23
			_cRetorno := '3299189991'
		ElseIf cFilAnt $ _cFil30
			_cRetorno := '3299069991'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '3299149991'
		ElseIf cFilAnt $ _cFil90
			_cRetorno := '3299169991'
		ElseIf cFilAnt $ _cFilAdm
			_cRetorno := '3301010031'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '3299209991'
		EndIf
	Else
		If cFilAnt $ _cFil01
			_cRetorno := '1102010004' //LEITE IN NATURA-MATRIZ
		ElseIf cFilAnt $ _cFil05
			_cRetorno := '1102010093'
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '1102010094'
		ElseIf cFilAnt $ _cFil20
			_cRetorno := '1102010095'
		ElseIf cFilAnt $ _cFil23
			_cRetorno := '1102010096'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '1102010016'
		ElseIf cFilAnt $ _cFil90
			_cRetorno := '1102010098'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '1102010161'
		ElseIf cFilAnt == '94'
			_cRetorno := '1102010168'
		EndIf
	EndIf
//============================================================================
//670001CD - Saida de Saldo Estoque (REQ) Transf Orig - Desmontagem - Débito (SD3)
//672001CC - Entrada de Saldo em Estoque -(Devolução) - Desmontagem - Crédito (SD3)
//============================================================================
ElseIf _cCod $ '670001CD/672001CC'
	_cRetorno := '1102010183' //ESTOQUES TRANSICAO

//============================================================================
//610001CD - Vendas Normais - Débito (SD2)
//610001CC - Vendas Normais - Crédito (SD2)
//610002CD - Vendas ICMS - Débito (SD2)
//610003CD - Vendas ICMS Substituição - Débito (SD2)
//610006CD - Vendas Despesas acessórias - Débito (SD2)
//610013CD - Vendas IPI - Débito (SD2)
//610008CC - Devolução de Compras - Crédito (SD2)
//640001CD - Devolução Venda Débito (SD1) - Total
//641001CD - Devolução Venda Débito (SD1) - Custo
//641001CC - Devolução Venda Crédito (SD1) - Custo
//650001CC - Compras Normais - Credito (SD1)
//650002CD - Compras Normais - Debito (SD1)
//650010CC - Compras ICMS - Crédito (SD1)
//666001CC - Movimento de estoque - Saida de Produtos - Credito - Ordem de Produção (SD3)
//666002CC - Movimento de estoque - Saida de Produtos - Credito - TM 550/551/552 (SD3)
//666004CD - Movimento de estoque - Saida de Produtos - Debito - TM 553 (SD3)
//666004CC - Movimento de estoque - Saida de Produtos - Credito - TM 553 (SD3)
//666006CD - Movimento de estoque - Saida de Produtos - Debito - TM 560 (SD3)
//666006CC - Movimento de estoque - Saida de Produtos - Credito - TM 560 (SD3)
//666007CD - Movimento de estoque - Saida de Produtos - Debito - TM 993/997 (SD3)
//666007CC - Movimento de estoque - Saida de Produtos - Credito - TM 993/997 (SD3)
//666008CC - Movimento de estoque - Saida de Produtos Inventário - Credito - TM 998/999 (SD3)
//666009CD - Saída Recurepação de Custo - Débito - TM 601
//666009CC - Saída Recurepação de Custo - Crédito - TM 601 (SD3)
//668001CD - Movimento de estoque - Entrada de Produtos - Debito (SD3)
//668002CD - Entrada Saldo em Estoque - Inventário - Débito - TM 498/499 (SD3)
//668003CD - Entrada Saldo em Estoque - Recepção Leite - Débito - TMs de entrada (SD3)
//668004CD - Entrada Saldo em Estoque - Débito - TM 300/301/302/304 (SD3)
//668004CC - Entrada Saldo em Estoque - Crédito - TM 300/301/302/304 (SD3)
//670001CC - Saida de Saldo Estoque (REQ) Transf Orig - Desmontagem - Credito (SD3)
//672001CD - Entrada de Saldo em Estoque -(Devolução) - Desmontagem - Débito (SD3)
//678001CD - Documento de saída - Custo de Mercadoria Vendida - Débito (SD2)
//678001CC - Documento de saída - Custo de Mercadoria Vendida - Crédito (SD2)
//681001CD - Compras/ Remessa Poder de Terceiros - Custo de Mercadoria Vendida - Débito (SD1)
//681001CC - Compras/ Remessa Poder de Terceiros - Custo de Mercadoria Vendida - Crédito (SD1)
//682001CD - Retorno Poder de Terceiros - Custo de Mercadoria Vendida - Débito (SD1)
//682001CC - Retorno Poder de Terceiros - Custo de Mercadoria Vendida - Crédito (SD1)
//============================================================================
Else	
	_lHigiene := SB1->B1_GRUPO == '0802' .Or. AllTrim(SB1->B1_COD) $ '09990000071/09990000243/09990000308/09990000323/10000000048/10000000063/10000000098/10030000234/10030000654/10030000655';
			.Or. (AllTrim(SB1->B1_COD) >= '10030001124' .And. AllTrim(SB1->B1_COD) <= '10030001126');
			.Or. (AllTrim(SB1->B1_COD) >= '10030001418' .And. AllTrim(SB1->B1_COD) <= '10030001420');
			.Or. (AllTrim(SB1->B1_COD) >= '10030001494' .And. AllTrim(SB1->B1_COD) <= '10030001496')
	
	_lConsumo := ((SB1->B1_GRUPO == '0999' .And. !(AllTrim(SB1->B1_TIPO) == 'MN') );
		.Or. (SB1->B1_GRUPO $ '0808/0812' .And. !AllTrim(SB1->B1_COD) $ '08120000040/08120000041/08120000072/08120000073/08120000074') ;
		.Or. AllTrim(SB1->B1_COD) $ '03010010134/06000000305/06000008546/07990001993/08000000001/08030000878/08030000879/08040000030/08050000407/08070000001';
		.Or. (AllTrim(SB1->B1_COD) >= '08070000009' .And. AllTrim(SB1->B1_COD) <= '08070000013');
		.Or. AllTrim(SB1->B1_COD) $ '08070000015/08070000016/08070000020/08070000022/08070000023/08070000025/08090000006/08090000064/08090000119/08110000174/'+;
		'08120000001/08120000002/10000000082/10020000013/10020000028/10020000100/10020000112/08120000124/10030000061';
		.Or. (AllTrim(SB1->B1_COD) >= '10030000063' .And. AllTrim(SB1->B1_COD) <= '10030000065');
		.Or. (AllTrim(SB1->B1_COD) >= '10030000683' .And. AllTrim(SB1->B1_COD) <= '10030001536');
		.Or. AllTrim(SB1->B1_COD) $ '10030000070/10030000074/10030000083/10030000095/10030000152/10030000475/10030000080/10030000186/10030000218/10030000350/10030000503/'+;
		'10030000557/10030000614/10030000851/10030000961/10030001041/10030001150/10030001643/10030001236/10030001238/10030001240/10030001244/10030001307/10030001615/'+;
		'10030001539/10030001540/10030001570/10030001573/10030001587/10030001609/10030001741/10030001831/10030001854/10030001881/10030001883/10030001999/10030002005/10030002052/'+;
		'10030001758/10030001920/10030001925/10030001927/10030002084/10030002136/10030002292/10030002357/10030002375/10030002484/10030002584/10030002485/10030002491/10030002671/'+;
		'10030002828/10030003055/10030003085/10030003288/10030003305/10020000922/08130000047';
		)

	_lPeqValor := ((SB1->B1_GRUPO $ '0811/0813' .And. !AllTrim(SB1->B1_COD) =='08130000002');
		.Or. AllTrim(SB1->B1_COD) $ '10020000100/10020000112/10020000137/10020000172/10020000241/10020000262/10020000561/10020001898/10030000035/10030000195/10030000445/'+;
			'10020001993/10030000189/10030000466/10030000531/10030000544/10030000566/10030000636')
	_lUniforme := (SB1->B1_GRUPO == '0805' .Or. AllTrim(SB1->B1_COD) $ '10030000038/10030000069/10030002901/10030003054')

	If _cCod $ '666009CD' .Or. (_cCod $ '668002CD' .And.  SD3->D3_TM == '498') .Or. (_cCod $ '668003CC' .And.  SD3->D3_TM == '495')
		If _cCod $ '666009CD' .And. SD3->D3_TM == '600' .Or. _cCod $ '668003CC'
			_cRetorno := '1102150020'
		Else
			If cFilAnt $ _cFil01
				_cRetorno := '3283110101' //ABSORCAO - MATRIZ
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '3283110102'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3283110103'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3283110104'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3283110105'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3283110106'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3283110107'
			ElseIf cFilAnt $ _cFil90
				_cRetorno := '3283110108'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3283110109'
			ElseIf cFilAnt == '94'
				_cRetorno := '3283110110'
			EndIf
		EndIf
	
	//Remessa para conserto
	ElseIf (_cCod $ '678001CD' .And. AllTrim(SF4->F4_CF)$ '5915');
			.Or. (_cCod $ '681001CC' .And. AllTrim(SF4->F4_CF)$ '1915/1916')
			_cRetorno := '1102010915' //BENS REMETIDOS PARA CONSERT

	ElseIf _cCod $ '666004CD' ;
		.Or. (_cCod $ '678001CD' .And. AllTrim(SF4->F4_CF)$ '5101/5102/5105/5106/5109/5110/5116/5118/5119/5401/5403/5405/5411/5501/5923');
		//Devolução de Venda
		If _cCod $ '666004CD' .Or. (_cCod $ '678001CD' .And. _lProdProp)
			If cFilAnt $ _cFil01
				_cRetorno := '3281100001' //CPV - MATRIZ
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '3281100002'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3281100003'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3281100004'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3281100005'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3281100006'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3281100007'
			ElseIf cFilAnt $ _cFil90
				If _cCod $ '678001CD'
					_cRetorno := '3281100008' //CPV- SAO PAULO
				Else
					_cRetorno := '3282110008' //CMV - SAO PAULO
				EndIf
			ElseIf cFilAnt == '91'
				_cRetorno := '3282110009'
			ElseIf cFilAnt $ _cFil93
				If _cCod $ '678001CD'
					_cRetorno := '3281100010' //CPV - PARANA
				Else
					_cRetorno := '3282110010' //CMV - PARANA
				EndIf
			ElseIf cFilAnt == '94'
				If _cCod $ '678001CD'
					_cRetorno := '3281100011' //CPV - CARIACICA
				Else
					_cRetorno := '3282110011' //CMV - CARIACICA
				EndIf
			ElseIf cFilAnt $ _cFil95
				_cRetorno := '3281100102' 
			ElseIf cFilAnt $ _cFil96
				_cRetorno := '3281100104'
			ElseIf cFilAnt $ _cFil97
				_cRetorno := '3281100101'
			ElseIf cFilAnt $ _cFil98
				_cRetorno := '3281100103'
			EndIf
		Else
			If cFilAnt $ _cFil01
				_cRetorno := '3282110001' //CMV - MATRIZ
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '3282110002'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3282110003'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3282110004'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3282110005'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3282110006'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3282110007'
			ElseIf cFilAnt $ _cFil90
				_cRetorno := '3282110008'
			ElseIf cFilAnt == '91'
				_cRetorno := '3282110009'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3282110010'
			ElseIf cFilAnt == '94'
				_cRetorno := '3282110011'
			ElseIf cFilAnt $ _cFil95
				_cRetorno := '3282110102' 
			ElseIf cFilAnt $ _cFil96
				_cRetorno := '3282110104'
			ElseIf cFilAnt $ _cFil97
				_cRetorno := '3282110101'
			ElseIf cFilAnt $ _cFil98
				_cRetorno := '3282110103'
			EndIf
		EndIf

	//Produtos
	ElseIf /*Regra 01*/(((_cCod $ '641001CD/681001CD/682001CD/668003CC/666007CD/');//Custo
	.Or. (_cCod $ '610001CC' .And. AllTrim(SF4->F4_CF) $ '5101/5102/5105/5106/5109/5110/5116/5118/5119/5123/5401/5402/5403/5405/5501'); //Saída
	.Or. (_cCod $ '678001CD' .And. AllTrim(SF4->F4_CF) $ '5905');//Custo
	.Or. (_cCod $ '678001CC' .And. AllTrim(SF4->F4_CF) $ '5101/5102/5105/5106/5109/5110/5116/5118/5119/5151/5152/5123/5155/5208/5209/5401/5402/'+;
		'5403/5405/5408/5501/5557/5905/5910/5911/5914/5923/5927/5949'); //Custo
	.Or. (_cCod $ '682001CC' .And. !AllTrim(SF4->F4_CF) $ '1914'));//Custo
	.And. _lProdProp);
	 .Or. /*Regra 02*/(_cCod $ _cGEst01+'/670001CC/672001CD' .And. SB1->B1_TIPO == 'PA')
		If _cCod $ _cGEst01+'/641001CD/670001CC/672001CD/678001CC/681001CD/682001CD' ;
			.Or. (_cCod $ '678001CD' .And. AllTrim(SF4->F4_CF) $ '5914')
			If cFilAnt $ _cFil01
				_cRetorno := '1102010001' //PRODUTOS ACABADOS-MATRIZ
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '1102010035'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '1102010019'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '1102010032'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '1102010061'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '1102010022'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '1102010060'
			ElseIf cFilAnt $ _cFil90
				_cRetorno := '1102010025'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '1102010154'
			ElseIf cFilAnt $ _cFil94
				_cRetorno := '1102010166'
			ElseIf cFilAnt $ _cFil95
				_cRetorno := '1102010177'
			ElseIf cFilAnt $ _cFil96
				_cRetorno := '1102010181'
			ElseIf cFilAnt $ _cFil97
				_cRetorno := '1102010175'
			ElseIf cFilAnt $ _cFil98
				_cRetorno := '1102010179'
			EndIf
		ElseIf _cCod $ '610001CC'
			If cFilAnt == '01'
				_cRetorno := '3101010001' //VENDAS - MATRIZ
			ElseIf cFilAnt == '02'
				_cRetorno := '3101010007'
			ElseIf cFilAnt == '04'
				_cRetorno := '3101010002'
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '3101010003'
			ElseIf cFilAnt == '06'
				_cRetorno := '3101010005'
			ElseIf cFilAnt == '09'
				_cRetorno := '3101010019'
			ElseIf cFilAnt == '0A'
				_cRetorno := '3101010018'
			ElseIf cFilAnt == '0B'
				_cRetorno := '3101010021'
			ElseIf cFilAnt == '10'
				_cRetorno := '3101010008'
			ElseIf cFilAnt == '11'
				_cRetorno := '3101010009'
			ElseIf cFilAnt == '20'
				_cRetorno := '3101010015'
			ElseIf cFilAnt == '21'
				_cRetorno := '3101010013'
			ElseIf cFilAnt == '22'
				_cRetorno := '3101010014'
			ElseIf cFilAnt == '23'
				_cRetorno := '3101010016'
			ElseIf cFilAnt == '24'
				_cRetorno := '3101010017'
			ElseIf cFilAnt == '25'
				_cRetorno := '3101010020'
			ElseIf cFilAnt $ '30'
				_cRetorno := '3101010010'
			ElseIf cFilAnt $ '31'
				_cRetorno := '3101010028'
			ElseIf cFilAnt $ '32'
				_cRetorno := '3101010029'
			ElseIf cFilAnt $ '33'
				_cRetorno := '3101010030'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3101010004'
			ElseIf cFilAnt $ _cFil90
				_cRetorno := '3101010011'
			ElseIf cFilAnt == '91'
				_cRetorno := '3101010012'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3101010022'
			ElseIf cFilAnt == '94'
				_cRetorno := '3101010023'
			ElseIf cFilAnt == '95'
				_cRetorno := '3101010024'
			ElseIf cFilAnt == '96'
				_cRetorno := '3101010025'
			ElseIf cFilAnt == '97'
				_cRetorno := '3101010026'
			ElseIf cFilAnt == '98'
				_cRetorno := '3101010027'
			EndIf
		ElseIf _cCod $ '678001CD/682001CC/668003CC/666007CD'
			If cFilAnt $ _cFil01+_cFil05
				_cRetorno := '1102010054' //PROD ACABADOS - CBBA - EM PODER DE TERCE
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '1102010052' //PROD ACABADOS - RS - EM PODER DE TERCEIR
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '1102010153'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '1102010157'
			ElseIf cFilAnt == '90'
				_cRetorno := '1102010050'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '1102010148'
			EndIf
		EndIf

	ElseIf _cCod $ '610001CC' .And. AllTrim(SF4->F4_CF) $ '5102/5106/5110/5119/5403/5405'
		If cFilAnt == '01'
			_cRetorno := '3101020001' //VENDAS - MATRIZ
		ElseIf cFilAnt == '02'
			_cRetorno := '3101020007'
		ElseIf cFilAnt == '04'
			_cRetorno := '3101020002'
		ElseIf cFilAnt $ _cFil05
			_cRetorno := '3101020003'
		ElseIf cFilAnt == '06'
			_cRetorno := '3101020005'
		ElseIf cFilAnt == '09'
			_cRetorno := '3101020019'
		ElseIf cFilAnt == '0A'
			_cRetorno := '3101020018'
		ElseIf cFilAnt == '0B'
			_cRetorno := '3101020021'
		ElseIf cFilAnt == '10'
			_cRetorno := '3101020008'		
		ElseIf cFilAnt == '11'
			_cRetorno := '3101020009'
		ElseIf cFilAnt == '20'
			_cRetorno := '3101020015'
		ElseIf cFilAnt == '21'
			_cRetorno := '3101020013'
		ElseIf cFilAnt == '22'
			_cRetorno := '3101020014'
		ElseIf cFilAnt == '23'
			_cRetorno := '3101020016'
		ElseIf cFilAnt == '24'
			_cRetorno := '3101020017'
		ElseIf cFilAnt == '25'
			_cRetorno := '3101020020'
		ElseIf cFilAnt $ '30'
			_cRetorno := '3101020010'
		ElseIf cFilAnt $ '31'
			_cRetorno := '3101020028'
		ElseIf cFilAnt $ '32'
			_cRetorno := '3101020029'
		ElseIf cFilAnt $ '33'
			_cRetorno := '3101020030'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '3101020004'
		ElseIf cFilAnt $ _cFil90
			_cRetorno := '3101020011'
		ElseIf cFilAnt == '91'
			_cRetorno := '3101020012'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '3101020022'
		ElseIf cFilAnt == '94'
			_cRetorno := '3101020023'
		ElseIf cFilAnt == '95'
			_cRetorno := '3101020024'
		ElseIf cFilAnt == '96'
			_cRetorno := '3101020025'
		ElseIf cFilAnt == '97'
			_cRetorno := '3101020026'
		ElseIf cFilAnt == '98'
			_cRetorno := '3101020027'
		EndIf

	//Produto em Processo
	ElseIf (_cCod $ _cGEst01+'610008CC/650002CD/670001CC/672001CD/681001CD' ;
	.Or. (_cCod $ '678001CC' .And. AllTrim(SF4->F4_CF) $ '5108/5208/5927'));
	.And. SB1->B1_TIPO $ 'PP/PI/SP'
		If cFilAnt $ _cFil01
			_cRetorno := '1102010121' //PRODUTOS EM PROCESSO - MATRIZ
		ElseIf cFilAnt $ _cFil05
			_cRetorno := '1102010122'
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '1102010123'
		ElseIf cFilAnt $ _cFil20
			_cRetorno := '1102010124'
		ElseIf cFilAnt $ _cFil23
			_cRetorno := '1102010125'
		ElseIf cFilAnt $ _cFil30
			_cRetorno := '1102010126'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '1102010127'
		ElseIf cFilAnt $ _cFil90
			_cRetorno := '1102010130'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '1102010160'
		EndIf
	
	//Devolução Produto Acabado e Mercadoria p Revenda
	ElseIf _cCod == '640001CD' .And. (_lProdProp .Or. _lProdRev)
		_cRetorno := '3105010004' //DEVOLUCOES DE VENDAS
	
	//Imobilizado
	ElseIf _cCod $ '650002CD/610001CC/610008CC' .And. SB1->B1_TIPO $ 'AT/AI' .And. SD1->D1_VUNIT > 326.61 .And.;
		((AllTrim(SF4->F4_CF) $ '1551/2551/1556/2556' .And. !cFilAnt $ _cFil20);
		.Or. (AllTrim(SF4->F4_CF) $ '1551/2551/1949/2949' .And. cFilAnt $ _cFil20))
		_cAlias := GetNextAlias()
		BeginSql alias _cAlias
			SELECT SED.ED_DEBITO
			  FROM %Table:SE2% SE2, %Table:SED% SED
			 WHERE SE2.D_E_L_E_T_ = ' '
			   AND SED.D_E_L_E_T_ = ' '
			   AND SED.ED_FILIAL = %xFilial:SED%
			   AND SED.ED_CODIGO = SE2.E2_NATUREZ
			   AND SE2.E2_FILIAL = %exp:cFilAnt%
			   AND SE2.E2_PREFIXO = %exp:SF1->F1_PREFIXO%
			   AND SE2.E2_NUM = %exp:SF1->F1_DUPL%
			   AND SE2.E2_FORNECE = %exp:SF1->F1_FORNECE%
			   AND SE2.E2_LOJA = %exp:SF1->F1_LOJA%
			 GROUP BY SED.ED_DEBITO
		EndSql
		_cRetorno := (_cAlias)->ED_DEBITO
		(_cAlias)->( DBCloseArea() )

	//Exames Admissionais/Periodicos/Demissionais
	ElseIf _cCod $ '650002CD' .And. AllTrim(SB1->B1_COD) $ '10000000030/10000000031/10000000032'
		_cAlias := GetNextAlias()
		BeginSql alias _cAlias
			SELECT SE2.E2_NATUREZ
			  FROM %Table:SE2% SE2
			 WHERE SE2.D_E_L_E_T_ = ' '
			   AND SE2.E2_FILIAL = %exp:cFilAnt%
			   AND SE2.E2_PREFIXO = %exp:SF1->F1_PREFIXO%
			   AND SE2.E2_NUM = %exp:SF1->F1_DUPL%
			   AND SE2.E2_FORNECE = %exp:SF1->F1_FORNECE%
			   AND SE2.E2_LOJA = %exp:SF1->F1_LOJA%
		EndSql

		If AllTrim((_cAlias)->E2_NATUREZ) == '232068'
			If _lCCusto .Or. cFilAnt $ '0B/25/91/92'
				_cRetorno := '3301020028'
			ElseIf cFilAnt $ _cFil01+_cFil05
				_cRetorno := '3299020005' //EXAMES ADIM./DEMI./PERIODIC
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3299030005'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3299070005'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3299170005'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3299050005'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3299130005'
			ElseIf cFilAnt == '90'
				_cRetorno := '3299160005'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3299190005'
			EndIf
		Else
			_cRetorno := '3301020067' //ASSISTENCIA MEDICA E SOCIAL
		EndIf

		(_cAlias)->( DBCloseArea() )
	
	//Produto Acabado e Insumos
	ElseIf (_cCod $ '666006CD' .And. (SB1->B1_TIPO $ 'PA' .Or. SB1->B1_GRUPO == '0801'))
		If _lCCusto .Or. cFilAnt $ _cFilAdm
			_cRetorno := '3201020027'
		ElseIf cFilAnt $ _cFil01
			_cRetorno := '3299029992' //USO E CONSUMO MATRIZ
		ElseIf cFilAnt $ _cFil05
			_cRetorno := '3299129992'
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '3299049992'
		ElseIf cFilAnt $ _cFil20
			_cRetorno := '3299089992'
		ElseIf cFilAnt $ _cFil23
			_cRetorno := '3299189992'
		ElseIf cFilAnt $ _cFil30
			_cRetorno := '3299069992'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '3299149992'
		ElseIf cFilAnt == '90'
			_cRetorno := '3299169992'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '3299209992'
		EndIf

	//Perdas de produção
	ElseIf _cCod $ '666006CD' .And. SB1->B1_GRUPO $ '0800/0814'
		If cFilAnt $ _cFil01
			_cRetorno := '3299020018' //PERDAS DE PRODUCAO
		ElseIf cFilAnt $ _cFil05
			_cRetorno := '3299120018'
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '3299040018'
		ElseIf cFilAnt $ _cFil20
			_cRetorno := '3299080018'
		ElseIf cFilAnt $ _cFil23
			_cRetorno := '3299180018'
		ElseIf cFilAnt $ _cFil30
			_cRetorno := '3299060018'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '3299140018'
		ElseIf cFilAnt == '90'
			_cRetorno := '3299160018'
		ElseIf cFilAnt $ _cFilAdm
			_cRetorno := '3299090005'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '3299200018'
		EndIf

	//Venda Energia Elétrica
	ElseIf _cCod $ '610001CC' .And. AllTrim(SF4->F4_CF) == '5251'
		_cRetorno := '3102010009' //VENDA DE ENERGIA ELETRICA
	
	//Venda Ativo Imobilizado
	ElseIf _cCod $ '610001CC' .And. AllTrim(SF4->F4_CF) == '5551'
		_cRetorno := '3501010002' //APURACAO PERDAS OU GANHOS-BAIXA IMOBILIZ
	
	//Recebimento/Retorno de bens para Industrialização
	ElseIf (_cCod $ '610001CC/610008CC/610001CD' .And. AllTrim(SF4->F4_CF) $ '5902/5925');
		.Or. ((_cCod $ '650002CD' .Or. (_cCod $ '650001CC' .And. Empty(SF1->F1_L_MIX))) .And. AllTrim(SF4->F4_CF) $ '1901/1924')
		If _cCod $ '650002CD/610001CC/610008CC'
			_cRetorno := '1102010701' //BENS RECEBIDOS P/INDUSTRIAL
		ElseIf _cCod $ '610001CD/650001CC'
			_cRetorno := '1102010702' //(-)BENS RECEBIDOS P/INDUSTR
		EndIf

	//Remessa/Devolução de Bonificação e Amostra Grátis
	ElseIf ((_cCod $ '610003CD/610006CD/610002CD');
		 .And. AllTrim(SF4->F4_CF) $ '5910/5911')
		If _cCod $ '610006CD/610003CD' .Or. (_cCod $ '610002CD' .And. AllTrim(SF4->F4_CF) $ '5911')
			_cRetorno := '3301010020' //ICMS S/AMOSTRA GRATIS
		ElseIf _cCod $ '610002CD' .And. AllTrim(SF4->F4_CF) $ '5910'
			_cRetorno := '3301010004' //ICMS S/BONIFICACOES CONCEDI
		EndIf
		
	//Recebimento/Retorno de bens em Comodato
	ElseIf (_cCod $ '610001CC/610008CC/610001CD' .And. AllTrim(SF4->F4_CF) $ '5909') ;
			.Or. ((_cCod $ '650002CD' .Or. (_cCod == '650001CC' .And. Empty(SF1->F1_L_MIX))) .And. AllTrim(SF4->F4_CF) $ '1908')
		If _cCod $ '650002CD/610001CC/610008CC'
			_cRetorno := '1102010707' //BENS RECEBIDOS EM COMODATO
		ElseIf _cCod $ '610001CD/650001CC'
			_cRetorno := '1102010708' //(-) BENS RECEBIDOS EM COMOD
		EndIf
		
	//Recebimento de Bens em Comodato/ Retorno de Bens recebidos em Demonstração
	ElseIf (_cCod $ '610001CC/610008CC/610001CD' .And. AllTrim(SF4->F4_CF) $ '5913');
		.Or. (_cCod $ '650002CD' .And. AllTrim(SF4->F4_CF) $ '1912')
		_cRetorno := '1102010711' //RECEBIMENTO DE BENS EM DEMO
		
	//Bens remetidos para Industrialização
	ElseIf (_cCod $ '610001CC/610008CC/610001CD' .And. AllTrim(SF4->F4_CF) $ '5901/5924') ;
			.Or. ((_cCod $ '650002CD' .Or. (_cCod == '650001CC' .And. Empty(SF1->F1_L_MIX))) .And. AllTrim(SF4->F4_CF) $ '1902/1925')
		If _cCod $ '650002CD/610001CC/610008CC'
			_cRetorno := '1102010902' //(-)BENS REMET. P/INDUSTRIZA
		ElseIf _cCod $ '610001CD/650001CC'
			_cRetorno := '1102010712' //(-) BENS RECEBIDOS EM DEMON
		EndIf

	//Remessa/Retorno de Bens cedidos em Comodato
	ElseIf (_cCod $ '610001CC/610008CC/610001CD' .And. AllTrim(SF4->F4_CF) $ '5908') ;
			.Or. ((_cCod $ '650002CD' .Or. (_cCod == '650001CC' .And. Empty(SF1->F1_L_MIX))) .And. AllTrim(SF4->F4_CF) $ '1909')
		If AllTrim(SF4->F4_CF) == '5908'
			If _cCod $ '610001CD'
				_cRetorno := '1102010909' //BENS CEDIDOS EM COMODATO
			ElseIf _cCod $ '610001CC/610008CC'
				_cRetorno := '1102010910' //(-) BENS CEDIDOS EM COMODAT
			EndIf
		ElseIf AllTrim(SF4->F4_CF) == '1909'
			If _cCod $ '650002CD'
				_cRetorno := '1102010010' //EMBALAGENS-F1 (ARAGUARI)
			ElseIf _cCod == '650001CC'
				_cRetorno := '1102010009' //INSUMOS PRODUCAO-F1 (ARAGUA
			EndIf
		EndIf
	
	//Transferências Saídas
	ElseIf _cCod $ '610003CD/610006CD/610002CD/610013CD' .And. AllTrim(SF4->F4_CF) $ '5151/5152/5153/5155/5156/5208/5209/5408/5409/5552/5557'
		If _cCod $ '610006CD/610003CD'
			_cRetorno := '3301010029' //ICMS ST TRANSFERENCIA
		ElseIf _cCod $ '610002CD'
			If (cFilAnt == '01' .And. (IIf(SD2->D2_TIPO $ 'B/D',SA2->A2_CGC,SA1->A1_CGC) == '01257995001458'));
				.Or. IIf(SD2->D2_TIPO $ 'B/D',SA2->A2_CGC,SA1->A1_CGC) $ '01257995001610/01257995003744';
				.Or. ( cFilAnt == '01' .And. (IIf(SD2->D2_TIPO $ 'B/D',SA2->A2_CGC,SA1->A1_CGC) == '01257995002853') .And. AllTrim(SF4->F4_CF) $ '5408');
				.Or. AllTrim(SF4->F4_CF) $ '5557'
				_cRetorno := '3301010033' //ICMS TRANSFERENCIA
			Else
				_cRetorno := '1102070067' //ICMS TRANSFERENCIA DE MERCADORIA
			EndIf
		ElseIf _cCod $ '610013CD'
			_cRetorno := '1102070104' //IPI TRANSFERENCIA DE MERCADORIA
		EndIf
	
	//Outras saídas IPI
	ElseIf _cCod $ '610013CD' .And. AllTrim(SF4->F4_CF) $ '5910/5911/5556/5949'
		_cRetorno:= '3301020102' //IPI OUTRAS SAIDAS

	//Transferencias	
	ElseIf (_cCod $ '681001CC/641001CC' .And. AllTrim(SF4->F4_CF) $ '1151/1152/1208/1209/1408/1409/1557');
		.Or. (_cCod $ '678001CD' .And. AllTrim(SF4->F4_CF) $ '5151/5152/5155/5208/5209/5408/5409/5557')
		_cRetorno := '1102010077' //TRANSFERENCIAS EM TRANSITO
	
	ElseIf _cCod $ '681001CC' .Or. (_cCod $ '641001CC' .And. !AllTrim(SF4->F4_CF) $ '1914')
		If _lProdProp
			If cFilAnt $ _cFil01
				_cRetorno := '3281200001' //(-) CPV - MATRIZ
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '3281200002'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3281200003'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3281200004'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3281200005'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3281200006'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3281200007'
			ElseIf cFilAnt $ _cFil90
				_cRetorno := '3281200008'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3281200010'
			ElseIf cFilAnt $ _cFil94
				_cRetorno := '3281200011'
			ElseIf cFilAnt $ '95'
				_cRetorno := '3281200102'
			ElseIf cFilAnt $ '96'
				_cRetorno := '3281200104'
			ElseIf cFilAnt $ '97'
				_cRetorno := '3281200101'
			ElseIf cFilAnt $ '98'
				_cRetorno := '3281200103'
			EndIf
		Else //Devoluções Revenda
			If cFilAnt $ _cFil01
				_cRetorno := '3282210001' //(-) CMV - MATRIZ
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '3282210002'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3282210003'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3282210004'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3282210005'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3282210006'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3282210007'
			ElseIf cFilAnt $ _cFil90
				_cRetorno := '3282210008'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3282210010'
			ElseIf cFilAnt $ _cFil94
				_cRetorno := '3282210011'
			ElseIf cFilAnt $ _cFil95
				_cRetorno := '3282210102'			
			ElseIf cFilAnt $ _cFil96
				_cRetorno := '3282210104'
			ElseIf cFilAnt $ _cFil97
				_cRetorno := '3282210101'
			ElseIf cFilAnt $ _cFil98
				_cRetorno := '3282210103'
			EndIf
		EndIf

	//Doação e Brindes
	ElseIf _cCod $ '678001CD' .And. AllTrim(SF4->F4_CF)$ '5910/5911'
		_cRetorno := '3105010024' //BONIFICACOES CONCEDIDAS
	
	//Analises Laboratoriais
	ElseIf _cCod $ '678001CD' .And. AllTrim(SF4->F4_CF)== '5949' .And. SB1->B1_TIPO = 'MP'
		_cRetorno := '3301020053' //ANALISES LABORATORIAIS LEITE

	//Perdas
	ElseIf _cCod $ '678001CD' .And. AllTrim(SF4->F4_CF)== '5927'
		_cRetorno := '3301020111' //PERDAS ESTOQUE

	//Amostra Grátis
	ElseIf (_cCod $ '650010CC' .Or. (_cCod == '650001CC' .And. Empty(SF1->F1_L_MIX))) .And. AllTrim(SF4->F4_CF) $ '1911'
		If _cCod $ '650001CC'
			_cRetorno := '3102010004' //REC.AMOSTRA GRATIS
		ElseIf _cCod == '650010CC'
			_cRetorno := '3102010008' //ICMS S/AMOSTRA GRATIS RECEBIDA
		EndIf
	
	//Retorno de Bens para Depósito Fechado
	ElseIf _cCod == '650010CC' .And. AllTrim(SF4->F4_CF) $ '1906'
		_cRetorno := '3301010026' //(-) ICMS RETORNO DEP FECHADO

	//Transferências Entradas ICMS
	ElseIf _cCod == '650010CC' .And. AllTrim(SF4->F4_CF) $ '1151/1152/1208/1209'
		_cRetorno := '1102070067' //ICMS TRANSFERENCIA DE MERCADORIA

	//Rmessa Produtos em feira exposição
	ElseIf _cCod $ '678001CD' .And. AllTrim(SF4->F4_CF) $ '5914'
		_cRetorno := '3301020037' //EVENTOS E FEIRAS PROMOCIONAIS
	
	//Retorno Produtos em feira exposição
	ElseIf _cCod $ '681001CC/682001CC/641001CC' .And. AllTrim(SF4->F4_CF) $ '1914'
		_cRetorno := '3301020049' //(-)RECUPERACOES DE DESPESAS

	//Recebimento/Retorno de Kit Manutenção
	ElseIf (_cCod $ '610001CC/610008CC/610001CD' .And. AllTrim(SF4->F4_CF) $ '5555');
			.Or. ((_cCod $ '650002CD' .Or. (_cCod == '650001CC' .And. Empty(SF1->F1_L_MIX))) .And. AllTrim(SF4->F4_CF) $ '1555')
		If _cCod $ '650002CD/610001CC/610008CC'
			_cRetorno := '1102010715' //RECEBIMENTO DE KIT MANUTENC
		ElseIf _cCod $ '610001CD/650001CC'
			_cRetorno := '1102010716' //(-) KIT DE MANUTENCAO RECEB
		EndIf

	//Retorno de Bens em Locação
	ElseIf _cCod $ '610001CC/610008CC/610001CD'  .And. AllTrim(SF4->F4_CF) == '5949' .And. SF4->F4_CODIGO == '791'
		If _cCod $ '610001CC/610008CC'
			_cRetorno := '1102010717' //RECEBIMENTO DE BEM EM LOCAC
		ElseIf '610001CD'
			_cRetorno := '1102010718' //(-) BEM RECEBIDO EM LOCACAO
		EndIf

	//Anulação de serviço de transporte de vendas
	ElseIf _cCod $ '610001CD/610008CC' .And. AllTrim(SF4->F4_CF) $ '5206' .And. AllTrim(SB1->B1_COD) $ '10000000005'
		_cRetorno := '3301010024' //( - ) ANULACAO DE SERVICO DE TRANSPORTE
	
	//Anulação de serviço de transporte de transferência e remessa
	ElseIf _cCod $ '610001CC/610008CC' .And. AllTrim(SF4->F4_CF) $ '5206' .And. AllTrim(SB1->B1_COD) $ '10000000014'
		_cRetorno := '3301020051' //(-)DEVOLUCAO DE COMPRAS

	//Devoluções de Compras
	ElseIf _cCod == '610002CD' .And. AllTrim(SF4->F4_I_GTES)$'S00011' .And. SD2->D2_TIPO=='D'
		If cFilAnt $ _cFil01+_cFil05
			_cRetorno := '3299010048' //ICMS S/DEVOLUCAO DE COMPRAS IND
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '3299030046'
		ElseIf cFilAnt $ '20/24/25'
			_cRetorno := '3299070047'
		ElseIf cFilAnt $ _cFil23
			_cRetorno := '3299170048'
		ElseIf cFilAnt $ _cFil30
			_cRetorno := '3299050046'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '3299130047'
		ElseIf cFilAnt == '90'
			_cRetorno := '3299990003'
		ElseIf cFilAnt == '91'
			_cRetorno := '3299980002'
		ElseIf cFilAnt == '92'
			_cRetorno := '3299150048'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '3299190048'
		ElseIf cFilAnt == '94'
			_cRetorno := '3299980003'
		ElseIf cFilAnt == '95'
			_cRetorno := '3299980004'
		ElseIf cFilAnt == '96'
			_cRetorno := '3299980005'
		ElseIf cFilAnt == '97'
			_cRetorno := '3299980006'
		ElseIf cFilAnt == '98'
			_cRetorno := '3299980007'
		EndIf

	//Remessa de Bens para Depósito Fechado
	ElseIf _cCod == '610002CD' .And. AllTrim(SF4->F4_CF)== '5905'
		_cRetorno:= '3301010025' //ICMS REMESSAS P DEP FECHADO
	
	//Vendas Normais
	ElseIf _cCod == '610002CD' .And. AllTrim(SF4->F4_I_GTES)$'S00001'
		_cRetorno:= '3105010001' //I C M S

	//Devolução de compra de bem para o ativo imobilizado
	ElseIf _cCod $ '610001CC/610008CC' .And. AllTrim(SF4->F4_CF) $ '5553/5206' .And. ;
		AllTrim(SB1->B1_COD) $ '10020000031/10020000032/10020000033/10020000054/10020000057/10020000058/10020000059/10020000060/10020000062/10020000063/10020000064/10020000073/10020000074/10020000075/10020000076/10020000084/10020000085/10020000086/10020000087/10020000088/10020000089/10020000090/10020000091/10020000092/10020000093/10020000094/10020000095/10020000096/10020000102/10020000104/10020000105/10020000109/10020000115/10020000118/10020000119/10020000120/10020000121/10020000122/10020000123/10020000124'
		_cRetorno := '1302030001' //MAQUINAS E EQUIPAMENTOS INDUSTRIAIS
	
	//Devolução de compra de bem para o ativo imobilizado
	ElseIf _cCod $ '610001CC/610008CC' .And. AllTrim(SF4->F4_CF) $ '5553/5206' .AND.;
		 AllTrim(SB1->B1_COD) $ '10020000021/10020000022/10020000023/10020000024/10020000025/10020000026/10020000027/10020000061/10020000078/10020000098/10020000099/10020000101/10020000103/10020000107/10020000110/10020000111/10020000112/10020000113/10020000114/10020000126'
		_cRetorno := '1302050001' //MOVEIS E UTENSILIOS

	//Credito CIAP
	ElseIf ((_cCod $ '650002CD' .Or. (_cCod == '650001CC' .And. Empty(SF1->F1_L_MIX))) .And. AllTrim(SF4->F4_CF) $ '1604')
		If _cCod $ '650002CD'
			If cFilAnt $ _cFil10
				_cRetorno := '1102070024' //ICMS NORMAL REC.-F7 (JARU)
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '1102070052'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '1102070082'
			EndIf
		ElseIf _cCod == '650001CC'
			_cRetorno := '3301020050' //(-)ICMS S/ COMPRAS
		EndIf

	//Pedágios sem movimentação financeira
	ElseIf ((_cCod $ '650001CC' .And. SF4->F4_DUPLIC == 'N' ) .Or. (_cCod $ '650002CD' .And. SubStr(SA2->A2_COD,1,1) <> "C")) .And. AllTrim(SB1->B1_COD) $ '09990000672'
		If _cCod $ '650002CD'
			_cRetorno := '3301010017' //PEDAGIOS NOS TRANSP DE VENDAS
		Else
			_cRetorno := '3301010022' //(-) RECUPERACOES DE DESPESAS
		EndIf
	//Transporte de Materiais de Consumo e de Expediente
	ElseIf _cCod $ '650002CD' .And. AllTrim(SF4->F4_CF) $ '1352/1353/1933' .And. (SB1->B1_GRUPO $ '0631/0805/0808/0809/0812/0999' .Or. AllTrim(SB1->B1_COD) $ '10000000015/10000000023')
		_cRetorno := '3301020017' //FRETES E CARRETOS

	//Transporte de Materia Prima/ Leite Cru, Leite em pó/Soro de Leite
	ElseIf (((_cCod $ '650002CD/610001CC/610008CC');
			.Or. (_cCod $ '641001CD/681001CD/682001CD/682001CC') ;
			.Or. (_cCod $ '678001CC' .And. AllTrim(SF4->F4_CF) $ '5102/5151/5152/5901/5905/5927');
			.Or. (_cCod $ '678001CD' .And. AllTrim(SF4->F4_CF) $ '5905/5901'));
			.And. (SB1->B1_GRUPO $ '0800/0814/1005';
			.Or. IIf(AllTrim(SF4->F4_CF) < '5000', SubStr(SA2->A2_COD,1,1) == "G" ;
			.Or. (SA2->A2_COD == "T00443" .And. AllTrim(SB1->B1_COD) $ '10000000006' .And. cFilAnt == '90') ;
			.Or. (SubStr(SA2->A2_COD,1,1) == "C" .And. AllTrim(SB1->B1_COD) $ '09990000672') ; //Pedágio de matéria prima
			.Or. (SubStr(SA2->A2_COD,1,1) <> "T" .And. AllTrim(SB1->B1_COD) $ '10000000006' .And. cFilAnt == '93') ;
			.Or. !Empty(SF1->F1_L_MIX),.F.);
			.Or. AllTrim(SB1->B1_COD) $ '10040000004'));
			/*Regra 02*/;
			.Or. (_cCod $ _cGEst01 + '/670001CC/672001CD' .And. (SB1->B1_TIPO == 'MP' .Or. AllTrim(SB1->B1_COD) $ '08000000039/08000000049'))
		If _cCod $ _cGEst01 + '650002CD/610001CC/610008CC/670001CC/672001CD/678001CC/641001CD/681001CD/682001CD'
			If cFilAnt $ _cFil01
				_cRetorno := '1102010005' //LEITE CRU RESFRIADO-MATRIZ
			ElseIf cFilAnt $ _cFil05
			_cRetorno := '1102010036'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '1102010015' //MATERIA PRIMA - (JARU)
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '1102010031'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '1102010059'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '1102010023'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '1102010058'
			ElseIf cFilAnt == '90'
				_cRetorno := '1102010089'
			ElseIf cFilAnt $ '0B/25/91/92'
				_cRetorno := '3301020017' //FRETES E CARRETOS
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '1102010161'
			EndIf
		ElseIf _cCod $ "678001CD/682001CC"
			If cFilAnt $ _cFil01+_cFil05
				_cRetorno := '1102010055' //MAT PRIMA - CBBA - EM PODER DE TERCEIROS
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '1102010078'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '1102010053'
			ElseIf cFilAnt == '90'
				_cRetorno := '1102010051'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '1102010163'
			EndIf
		EndIf

    //Mercadorias e Bonificações para revenda
	ElseIf /*Regra 01*/(_cCod $ '678001CC' .And. AllTrim(SF4->F4_CF) $ '5102/5106/5110/5152/5209/5403/5405/5411/5557/5905/5910/5911/5923/5927/5949/5914' .And. _lProdRev);//custo
		.Or.  (_cCod $ '650002CD' .And. AllTrim(SF4->F4_CF) $ '1102/1403/1910/1911' .And. _lProdRev); //Entrada
		.Or. (_cCod $ '681001CD' .And. AllTrim(SF4->F4_CF) $ '1151/1152/1201/1202/1203/1204/1208/1209/1409/1410/1411/1914/1949' .And. _lProdRev);
		.Or. (_cCod $ '641001CD/682001CD/682001CC/668003CC/666007CD' .And. _lProdRev);
		.Or. (_cCod $ '678001CD' .And. AllTrim(SF4->F4_CF) $ '5905' .And. _lProdRev);
		/*Regra 03*/;
		.Or. (_cCod $ '610001CC/610008CC/610001CD' .And. AllTrim(SF4->F4_CF) $ '5202/5206/5411' .And. SB1->B1_GRUPO $ '0008/0011/0015/0016/0017/0018/0019/0021/0023')
		//Bonificações Mercadorias para revenda ou //Mercadorias para revenda
		If _cCod $ '610001CD/682001CC/668003CC/666007CD' ;
				.Or. (_cCod $ '678001CD' .And. AllTrim(SF4->F4_CF) $ '5905')
			If cFilAnt $ _cFil20
				_cRetorno := '1102010152' //MERCADORIA P REVENDA PODER TERC- P FUNDO
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '1102010158'
			EndIf
		ElseIf _cCod $ '650002CD/610001CC/610008CC/641001CD/681001CD/682001CD/678001CC/678001CD'
			If cFilAnt $ _cFil01
				_cRetorno := '1102010080' //ESTOQUE MERCADORIAS P REVENDA - MATRIZ
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '1102010083'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '1102010081'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '1102010084'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '1102010088'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '1102010082'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '1102010087'
			ElseIf cFilAnt $ _cFil90
				_cRetorno := '1102010085'
			ElseIf cFilAnt == '91'
				_cRetorno := '1102010086'
			ElseIf cFilAnt == '93'
				_cRetorno := '1102010173'
			ElseIf cFilAnt == '94'
				_cRetorno := '1102010174'
			ElseIf cFilAnt == '95'
				_cRetorno := '1102010178'
			ElseIf cFilAnt == '96'
				_cRetorno := '1102010182'
			ElseIf cFilAnt == '97'
				_cRetorno := '1102010176'
			ElseIf cFilAnt == '98'
				_cRetorno := '1102010180'
			EndIf
		EndIf

	//Bonificação (geral)
	ElseIf (_cCod $ '650010CC' .Or. (_cCod == '650001CC' .And. Empty(SF1->F1_L_MIX))) .And. AllTrim(SF4->F4_CF) $ '1910/1911'
		If _cCod $ '650001CC'
			_cRetorno := '3102010001' //BONIFICACOES RECEBIDAS
		ElseIf _cCod $ '650010CC'
			_cRetorno := '3102010002' //ICMS S/BONIFICACOES RECEBID
		EndIf

	//Transporte de Transferências
	ElseIf _cCod $ '650002CD' .And. AllTrim(SB1->B1_COD) == '10000000014'
		_cRetorno := '3301020083' //FRETES DE TRANSFERENCIAS E REMESSAS
			
	//Transporte de Vendas
	ElseIf _cCod $ '650002CD' .And. AllTrim(SB1->B1_COD) == '10000000005'
		_cRetorno := '3301010001' //FRETES S/ VENDAS

	//Degustação
	ElseIf _cCod $ '650002CD' .And. AllTrim(SB1->B1_COD) $ '10000000008/10000000082/10000000133' .And. SD1->D1_FORNECE = 'F01645'
		If cFilAnt $ _cFil90
			_cRetorno := '3301020014' //SERVICOS TERCEIROS PJ
		EndIf	

	//Convenio a repassar
	ElseIf _cCod $ '650002CD' .And. AllTrim(SB1->B1_COD) $ '10000000158' .And. SD1->D1_FORNECE = 'F23411'
		_cRetorno := '2101140005' //CONVENIO  A REPASSAR

	//Transporte de Embalagens, Embalagens
	ElseIf ((_cCod $ '610001CC/610008CC/610001CD' .And. AllTrim(SF4->F4_CF) $ '5201/5206');
		  	.Or. _cCod $ _cGEst01 + '666006CD/650002CD/681001CD/682001CD/682001CC';
			.Or. (_cCod $ '678001CD' .And. AllTrim(SF4->F4_CF)$ '5901');
		  	.Or. (_cCod $ '678001CC' .And. AllTrim(SF4->F4_CF)$ '5152/5208/5901/5915/5927');
			.Or. (_cCod $ '668003CC' .And. AllTrim(SD3->D3_TM)$ '493');
			.Or. _cCod $ '666007CD');
		  .And.;
	 	((SB1->B1_GRUPO >= '0300' .And. SB1->B1_GRUPO <= '0599') .Or. SB1->B1_GRUPO == '0806';
	 	.Or. AllTrim(SB1->B1_COD) $ '06000008620/06000008738/06000008087/06000004466/06020000246/06250000151/06250000336/06250000933/07990001993/08120000040/08120000041/08120000072/08120000073/08120000074/10030000863')
		If _cCod $ _cGEst01 + '650002CD/610001CC/610008CC/678001CC/681001CD/682001CD'
			If cFilAnt $ _cFil01+_cFil05
				If SB1->B1_GRUPO $'0332/0333' .And. _cCod $ _cGEst01 + '678001CC'
					_cRetorno := '1102010075' //EMBALAGENS MTZ - PODER DE TERCEIROS
				Else
					_cRetorno := '1102010003' //EMBALAGENS-MATRIZ
				EndIf									
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '1102010021' //EMBALAGENS-F8 (JARU)
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '1102010034'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '1102010072'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '1102010024'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '1102010067'
			ElseIf cFilAnt == '90'
				_cRetorno := '1102010049'
			ElseIf cFilAnt $ '91/92'
				//Embalagens
				If AllTrim(SB1->B1_COD) $ '06000008620/06000008738/06000008087/06000004466' .And. !AllTrim(SF4->F4_CF) $ '1352/1353'
					_cRetorno := '3301010008' //EMBALAGENS
				Else
					_cRetorno := '3301020017' //FRETES E CARRETOS
				EndIf
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '1102010150' //EMBALAGENS PARANA
			EndIf

		ElseIf _cCod $ '610001CD/678001CD/682001CC/666007CD/668003CC'
			If cFilAnt $ _cFil01+_cFil05
				_cRetorno := '1102010075' //EMBALAGENS MTZ - PODER DE TERCEIROS
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '1102010144'
			ElseIf cFilAnt $ _cFil20
				If _cCod $ '678001CD'
					_cRetorno := '1102010143' //EMBALAGENS RS - PODER DE TERCEIROS
				Else
					_cRetorno := '1102010155' //EMBALAGENS PODER TERC - PASSO FUNDO
				EndIf
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '1102010185' 
			ElseIf cFilAnt == '90'
				_cRetorno := '1102010073' //EMBALAGENS SP - PODER DE TERCEIROS
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '1102010147' //EMBALAGENS PARANA - PODER TERCEIROS
			EndIf
		ElseIf _cCod $ '666006CD'
			If cFilAnt $ _cFil01
				_cRetorno := '3299020017' //PERDA DE EMBALAGEM
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '3299120017'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3299040017'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3299080017'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3299180017'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3299060017'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3299140017'
			ElseIf cFilAnt $ '90/91/92'
				_cRetorno := '3299160017'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3299200017'
			EndIf
		EndIf
 
	//Mão de Obra e Gastos Gerais de Fabricação - GGF
	ElseIf (_cCod $ _cGEst01 + '668004CC/678001CC' .And. SB1->B1_TIPO $ 'MO/GG/DE') ;
			.Or. (_cCod $ '668004CC' .And. SB1->B1_GRUPO $'0800') ;
			.Or. (_cCod $ '666001CC' .And. AllTrim(SB1->B1_COD) $ '10000000026/10000000168/10000000169')
		If cFilAnt $ _cFil01
			_cRetorno := '3283110001' //(-) ABSORCAO - MATRIZ
		ElseIf cFilAnt $ _cFil05
			_cRetorno := '3283110002'
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '3283110003'
		ElseIf cFilAnt $ _cFil20
			_cRetorno := '3283110004'
		ElseIf cFilAnt $ _cFil23
			_cRetorno := '3283110005'
		ElseIf cFilAnt $ _cFil30
			_cRetorno := '3283110006'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '3283110007'
		ElseIf cFilAnt $ _cFil90
			_cRetorno := '3283110008'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '3283110009'
		ElseIf cFilAnt == '94'
			_cRetorno := '3283110010'
		EndIf

	//Material de consumo, Produtos Químicos, Higienização e Limpeza
	ElseIf (_cCod $ _cGEst01 + '650002CD/610001CC/610008CC/678001CC/666006CD/670002CC/681001CD') .And. (_lConsumo .Or. _lPeqValor .Or. _lHigiene .Or. _lUniforme;
		.Or. (SB1->B1_GRUPO $ '0803/0804' .And. !AllTrim(SB1->B1_COD) $ '08040000004/08040000219/') )
		//Higienização e Limpeza
		If  (_cCod $ '666006CD' .Or. (_cCod $ '650002CD' .And. SF4->F4_ESTOQUE == 'N')) .And._lHigiene
			If _lCCusto .Or. cFilAnt $ _cFil90+_cFilAdm
				_cRetorno := '3301020042' //HIGIENIZACAO / LIMPEZA
			ElseIf cFilAnt $ _cFil01
				_cRetorno := '3299020043' //HIGIENIZACAO / LIMPEZA
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '3299120043'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3299040043'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3299080043'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3299180043'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3299060043'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3299140043'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3299200043'
			EndIf
			
		//Produtos Químicos
		ElseIf (_cCod $ '666006CD' .Or. (_cCod $ '650002CD' .And. SF4->F4_ESTOQUE == 'N')) .And. SB1->B1_GRUPO == '0804' 
			If _lCCusto .Or. cFilAnt $ _cFil90+_cFilAdm
				_cRetorno := '3301020027' //MATERIAL DE CONSUMO/LIMPEZA
			ElseIf cFilAnt $ _cFil01
				_cRetorno := '3299020011' //MATERIAL DE LIMPEZA/CONSUMO
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '3299120011'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3299040011'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3299080011'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3299180011'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3299060011'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3299140011'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3299200011'		
			EndIf

		//Material de consumo
		ElseIf (_cCod $ '666006CD' .Or. (_cCod $ '650002CD' .And. SF4->F4_ESTOQUE == 'N')).And. _lConsumo
			If _lCCusto .Or. cFilAnt $ _cFil90+_cFilAdm
				_cRetorno := '3301020027' //MATERIAL DE CONSUMO/LIMPEZA
			ElseIf cFilAnt $ _cFil01
				_cRetorno := '3299029992' //USO E CONSUMO MATRIZ
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '3299129992'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3299049992'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3299089992'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3299189992'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3299069992'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3299149992'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3299209992'
			EndIf
			
		//Bens de pequeno valor
		ElseIf (_cCod $ '666006CD' .Or. (_cCod $ '650002CD' .And. SF4->F4_ESTOQUE == 'N')).And. _lPeqValor
			If _lCCusto .Or. cFilAnt $ _cFilAdm
				_cRetorno := '3301020019' //BENS PEQUENO VALOR
			ElseIf cFilAnt $ _cFil01
				_cRetorno := '3299020014' //BENS DE PEQUENO VALOR
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '3299120014'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3299040014'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3299080014'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3299180014'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3299060014'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3299140014'
			ElseIf cFilAnt == '90'
				_cRetorno := '3299160014'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3299200014'
			EndIf
			
		//Pordutos de Laboratório
		ElseIf (_cCod $ '666006CD' .Or. (_cCod $ '650002CD' .And. SF4->F4_ESTOQUE == 'N')).And. SB1->B1_GRUPO == '0803'
			If _lCCusto .Or. cFilAnt $ _cFilAdm
				_cRetorno := '3301020027' //MATERIAL DE CONSUMO/LIMPEZA
			ElseIf cFilAnt $ _cFil01
				_cRetorno := '3299020013' //PRODUTOS DE LABORATORIO
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '3299120013'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3299040013'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3299080013'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3299180013'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3299060013'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3299140013'
			ElseIf cFilAnt == '90'
				_cRetorno := '3299160013'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3299200013'
			EndIf
				
		//Uniformes
		ElseIf (_cCod $ '666006CD' .Or. (_cCod $ '650002CD' .And. SF4->F4_ESTOQUE == 'N')) .And. _lUniforme
			If _lCCusto .Or. cFilAnt $ _cFil90+_cFilAdm
				_cRetorno := '3301020024' //UNIFORMES / MATERIAIS ESPORTIVOS
			ElseIf cFilAnt $ _cFil01
				_cRetorno := '3299020007' //UNIFORMES/MATERIAIS ESPORTI VOS
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '3299120007'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3299040007'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3299080007'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3299180007'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3299060007'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3299140007'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3299200007'
			EndIf
		ElseIf !(SubStr(_cCod,1,3)=='650' .And. SF4->F4_ESTOQUE == 'N')
			If cFilAnt $ _cFil01+_cFil05
				If !_cCod $ _cGEst01 + '678001CC' .And. _lConsumo
					_cRetorno := '1102010017' //MATERIAL DE CONSUMO MATRIZ
				Else
					_cRetorno := '1102010007' //MATERIAL DE LIMPEZA-MATRIZ
				EndIf
			ElseIf cFilAnt $ _cFil10
				If !_cCod $ _cGEst01 + '678001CC' .And. _lConsumo
					_cRetorno := '1102010047' //ESTOQUE MATERIAL DE LABORATORIO - JARU
				Else
					_cRetorno := '1102010018' //MATERIAL LIMPEZA/CONS-F8 JA
				EndIf
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '1102010043' //MATERIAL DE CONSUMO - RIO G DO SUL
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '1102010070'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '1102010044'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '1102010065'
			ElseIf cFilAnt == '90'
				_cRetorno := '1102010140'
			ElseIf cFilAnt $ _cFilAdm
				_cRetorno := '3301020027' //MATERIAL DE CONSUMO/LIMPEZA
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '1102010159' //ESTOQUE MAT USO E CONSUMO - PARANA
			EndIf
		EndIf
	
	//PAT - Programa de alimentação ao trabalhador
	ElseIf _cCod $ '666006CD' .And. AllTrim(SB1->B1_COD) $ '08090000008/08090000011/08090000013/08090000014/08090000017/08090000018/08090000021/08090000022/08090000030/08090000031/08090000034/08090000074/08090000125/08090000298/08090000333/08090000359/08090000362'
		If _lCCusto .Or. cFilAnt $ _cFil90+_cFilAdm
			_cRetorno := '3301020052' //PAT-PROGR  ALIMENTACAO TRABALHADOR
		ElseIf cFilAnt $ _cFil01
			_cRetorno := '3299020042' //PAT-PROG ALIMENT TRABALHADOR
		ElseIf cFilAnt $ _cFil05
			_cRetorno := '3299120042'
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '3299040039'
		ElseIf cFilAnt $ _cFil20
			_cRetorno := '3299080039'
		ElseIf cFilAnt $ _cFil23
			_cRetorno := '3299180042'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '3299140042'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '3299200042'
		EndIf

	//Convenio Odontologico
	ElseIf _cCod $ '650002CD' .And. AllTrim(SB1->B1_COD) $ '10000000046' 
		_cAlias := GetNextAlias()
		BeginSql alias _cAlias
			SELECT SE2.E2_NATUREZ
			  FROM %Table:SE2% SE2
			 WHERE SE2.D_E_L_E_T_ = ' '
			   AND SE2.E2_FILIAL = %exp:cFilAnt%
			   AND SE2.E2_PREFIXO = %exp:SF1->F1_PREFIXO%
			   AND SE2.E2_NUM = %exp:SF1->F1_DUPL%
			   AND SE2.E2_FORNECE = %exp:SF1->F1_FORNECE%
			   AND SE2.E2_LOJA = %exp:SF1->F1_LOJA%
		EndSql

		If AllTrim((_cAlias)->E2_NATUREZ) == '221042'
			_cRetorno := '2101140006' //ADTO PLANO DE SAUDE.
		Else
			_cRetorno := SB1->B1_CONTA	
		EndIf
			
		(_cAlias)->( DBCloseArea() )

	//Outras saídas
	ElseIf _cCod $ '640001CD/610002CD'
		_cRetorno:= '3301020088' //ICMS OUTRAS SAIDAS

	//Regras paras produtos com conta preenchida
	ElseIf _cCod $ '650002CD/666006CD' .And. !Empty(SB1->B1_CONTA)
		_cRetorno := SB1->B1_CONTA
	
	//Transporte de Peças, Manutenção, Construção Civil e Instalação Industrial em Andamento
	ElseIf (_cCod $ _cGEst01 + '650002CD/610001CC/610008CC/666006CD/678001CC/681001CD/670002CC') .And. (((SB1->B1_GRUPO >= '0600' .And. SB1->B1_GRUPO <= '0799' .Or. SB1->B1_GRUPO = '0810') ;
	.And. !AllTrim(SB1->B1_COD) $ '06350000001/06410000018' .And. !SB1->B1_GRUPO $ '0630/0641') ;
	.Or. AllTrim(SB1->B1_COD) $ '08070000018/08070000019/10020000006/10020000077/10020000097/10020000106/10020000108/10020000116/10020000125/10020000567/10020000929';
	.Or. AllTrim(SB1->B1_COD) $ '10000000001/10000000002/10000000012/10000000021/10000000027/10000000036/10000000045/10000000053/10000000054/10000000055/10000000092/10000000094/10000000095/10000000110/10000000129/10000000132/10000000134/10000000143/10000000148';
	.Or. AllTrim(SB1->B1_COD) $ '10020001703/10030000021/10030000022/10030000031/10030000060/10030000081/10030000342/10030000380/10030000410/10030001575/10030001678/10030001691/10030001885/10030001997/10030002004';
	.Or. AllTrim(SB1->B1_COD) $ '10020000854/06410000081/10030001692/06410000015/06410000014/06410000013/06410000075/10030001888/';
	.Or. (AllTrim(SB1->B1_COD) >= '10020000028' .And. AllTrim(SB1->B1_COD) <= '10020000030') ;
	.Or. (AllTrim(SB1->B1_COD) >= '10020000034' .And. AllTrim(SB1->B1_COD) <= '10020000053') ;
	.Or. (AllTrim(SB1->B1_COD) >= '10020000065' .And. AllTrim(SB1->B1_COD) <= '10020000072') ;
	.Or. (AllTrim(SB1->B1_COD) >= '10020000079' .And. AllTrim(SB1->B1_COD) <= '10020000083') ;
	.Or. (AllTrim(SB1->B1_COD) >= '10030000013' .And. AllTrim(SB1->B1_COD) <= '10030000015') ;
	.Or. (SB1->B1_GRUPO == '0999' .And. AllTrim(SB1->B1_TIPO) == 'MN') )
		If (_cCod $ '650002CD' .And. SF4->F4_ESTOQUE == 'N') .Or._cCod $ '666006CD' .Or. AllTrim(SB1->B1_COD) $ '10000000001/10000000002/10000000012/10000000021/10000000027/10000000036/10000000045/10000000053/10000000054/10000000055/10000000092/10000000094/10000000095/10000000110/10000000129/10000000132/10000000134/10000000143/10000000148'
			If _lCCusto .Or. cFilAnt $ _cFil90+_cFilAdm
				_cRetorno := '3301020010' //MANUTENCAO E REPAROS
			ElseIf cFilAnt $ _cFil01
				_cRetorno := '3299020010' //MANUTENCOES
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '3299120010'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3299040010'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3299080010'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3299180010'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3299060010'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3299140010'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3299200010'
			EndIf
		Else
			If cFilAnt $ _cFil01
				_cRetorno := '1102010029' //ESTOQUE PECAS P/MAQUINAS E
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '1102010041'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '1102010046'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '1102010048'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '1102010069'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '1102010092'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '1102010064'
			ElseIf cFilAnt $ _cFil90+_cFilAdm
				If AllTrim(SF4->F4_CF) $ '1352/1353' .And. (SB1->B1_GRUPO >= '0600' .And. SB1->B1_GRUPO <= '0799')
					_cRetorno := '3301020017' //FRETES E CARRETOS
				ElseIf _cCod $ _cGEst01
					_cRetorno := '1102010184'
				Else	
					_cRetorno := '3301020010' //MANUTENCAO E REPAROS
				EndIf
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '1102010164' //ESTOQUE MATERIAL DE LABORATORIO - PARANA
			EndIf
		EndIf

	//Lanches e Refeições
	ElseIf _cCod $ '650002CD/610001CC/666006CD' .And. (SB1->B1_GRUPO == '0809' ;
	.Or. AllTrim(SB1->B1_COD) $ '00010010101/00010110101/00020010301/00040010101/00040010201/00080010401/00150020401' ;
	.Or. (SD1->D1_FORNECE == 'F01645' .And. AllTrim(SB1->B1_COD) == '10000000078'))
		_cRetorno := '3301020038' //LANCHES E REFEICOES
	
	//Transporte de Insumos, Insumos/Lactose/Açucar/Pre Mix Chocolate
	ElseIf ((_cCod $ _cGEst01 + '610008CC/681001CD/682001CD/682001CC/650002CD/650010CC/670002CC');
		 .Or. (_cCod $ '678001CD' .And. AllTrim(SF4->F4_CF) $      '5206/5901/5905/5927') ;
		 .Or. (_cCod $ '678001CC' .And. AllTrim(SF4->F4_CF) $ '5152/5206/5901/5905/5927')) ;
			.And. ((SB1->B1_TIPO == 'IN' .And. SB1->B1_GRUPO $ '0800/0801');
			.Or. AllTrim(SB1->B1_COD) $ '06000008620/06000008738/06000008087/06000004466/06020000246/06250000151/06250000336/06250000933/07990001993/08000000079/08040000004/08040000219/10030000863')
		If _cCod $ '650002CD' .And. SF4->F4_ESTOQUE == 'N'
			If cFilAnt $ _cFil01
				_cRetorno := '3299010014'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3299030014'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3299070014'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3299170014'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3299050014'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3299130014'
			ElseIf cFilAnt $ _cFil90
				_cRetorno := '3299150014'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3299190014'
			EndIf
		ElseIf _cCod $ _cGEst01 + '610008CC/650002CD/650010CC/678001CC/681001CD/682001CD/670002CC'
			If cFilAnt $ _cFil01
				_cRetorno := '1102010002' //INSUMOS DE PRODUCAO-MATRIZ
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '1102010037'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '1102010020'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '1102010033'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '1102010071'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '1102010090'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '1102010066'
			ElseIf _cCod $ _cGEst01 + '678001CC' .And. cFilAnt $ _cFil90
				_cRetorno := '1102010074'
			ElseIf cFilAnt == '90'
				_cRetorno := '1102010062'
			ElseIf AllTrim(SF4->F4_CF) $ '1352/1353' .And. cFilAnt $ _cFilAdm
				_cRetorno := '3301020017' //FRETES E CARRETOS
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '1102010151'
			EndIf
		ElseIf _cCod $ '678001CD/682001CC'
			If cFilAnt $ _cFil01+_cFil05
				_cRetorno := '1102010076' //INSUMOS MTZ - PODER DE TERCEIROS
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '1102010146'
			ElseIf cFilAnt $ _cFil20
				If _cCod $ '678001CD'
					_cRetorno := '1102010145' //INSUMOS RS - PODER DE TERCEIROS
				Else
					_cRetorno := '1102010156' //INSUMOS PODER TERC - PASSO FUNDO
				EndIf
			ElseIf cFilAnt == '90'
				_cRetorno := '1102010074'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '1102010149'
			EndIf
		EndIf

	//Combustiveis e Lubrificantes
	ElseIf ((_cCod $ '610001CC/610008CC' .And. AllTrim(SF4->F4_CF) $ '5556/5206');
		.Or. _cCod $ _cGEst01 + '650002CD/610001CC/610008CC/666006CD/678001CC/681001CD');
		.And. (SB1->B1_GRUPO == '0630' ;
		.Or. (AllTrim(SB1->B1_COD) >= '08070000003' .And. AllTrim(SB1->B1_COD) <= '08070000006');
		.Or. AllTrim(SB1->B1_COD) $ '08070000016/08070000020/08070000021/08070000024/08070000026/08070000033/08070000035/08070000036/08070000038/08070000039/08070000040/08070000043/08070000050/08070000063/08070000071';
		.Or. (AllTrim(SB1->B1_COD) >= '08070000029' .And. AllTrim(SB1->B1_COD) <= '08070000031'))
		If _cCod $ '666006CD' .Or. (_cCod $ '650002CD' .And. SF4->F4_ESTOQUE == 'N')
			If _lCCusto .Or. cFilAnt $ _cFilAdm
				_cRetorno := '3301020008' //COMBUSTIVEIS E LUBRIFICANTE
			ElseIf cFilAnt $ _cFil01
				_cRetorno := '3299020012' //COMBUSTIVEIS E LUBRIFICANTE
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '3299120012'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3299040012'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3299080012'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3299180012'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3299060012'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3299140012'
			ElseIf cFilAnt == '90'
				_cRetorno := '3299160012'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3299200012'
			EndIf
		Else
			If cFilAnt $ _cFil01
				_cRetorno := '1102010006' //COMBUST.E LUBRIFICANTES-MAT
			ElseIf cFilAnt $ _cFil05
				_cRetorno := '1102010039'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '1102010045'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '1102010042'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '1102010068'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '1102010091'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '1102010063'
			ElseIf cFilAnt $ _cFil90+_cFilAdm
				_cRetorno := '3301020008' //COMBUSTIVEIS E LUBRIFICANTE
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '1102010165'
			EndIf
		EndIf

	//Energia Elétrica
	ElseIf _cCod $ '650002CD' .And. AllTrim(SB1->B1_COD) $ '08070000014/08070000048'
		If _lCCusto .Or. cFilAnt $ _cFilAdm
			_cRetorno := '3301020062' //ENERGIA ELETRICA
		ElseIf cFilAnt $ _cFil01+_cFil05
			_cRetorno := '3299020008' //ENERGIA ELETRICA
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '3299040008'
		ElseIf cFilAnt $ _cFil20
			_cRetorno := '3299080008'
		ElseIf cFilAnt $ _cFil23
			_cRetorno := '3299180008'
		ElseIf cFilAnt $ _cFil30
			_cRetorno := '3299060008'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '3299140008'
		ElseIf cFilAnt == '90'
			_cRetorno := '3299160008'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '3299200008'
		EndIf
			
	//Vale transporte
	ElseIf _cCod $ '650002CD' .And. AllTrim(SB1->B1_COD) $ '10000000015/10000000142'
		If _lCCusto .Or. cFilAnt $ _cFilAdm
			_cRetorno := '3301020056' //VALE TRANSPORTE
		ElseIf cFilAnt $ _cFil01+_cFil05
			_cRetorno := '3299020058' //VALE TRANSPORTE
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '3299040058'
		ElseIf cFilAnt $ _cFil20
			_cRetorno := '3299080058'
		ElseIf cFilAnt $ _cFil23
			_cRetorno := '3299180058'
		ElseIf cFilAnt $ _cFil30
			_cRetorno := '3299060058'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '3299140058'
		ElseIf cFilAnt == '90'
			_cRetorno := '3299160058'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '3299200058'
		EndIf
	
	//Alugueis e locações
	ElseIf _cCod $ '650002CD' .And. AllTrim(SB1->B1_COD) $ '10000000020/10000000021/10000000073/10000000081/10030000024/10000000145'
		If _lCCusto .Or. cFilAnt $ _cFilAdm
			_cRetorno := '3301020018' //ALUGUEIS
		ElseIf cFilAnt $ _cFil01+_cFil05
			_cRetorno := '3299020021' //ALUGUEIS DE MAQUINAS
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '3299040021'
		ElseIf cFilAnt $ _cFil20
			_cRetorno := '3299080021'
		ElseIf cFilAnt $ _cFil23
			_cRetorno := '3299180021'
		ElseIf cFilAnt $ _cFil30
			_cRetorno := '3299060021'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '3299140021'
		ElseIf cFilAnt == '90'
			_cRetorno := '3299160021'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '3299200021'
		EndIf

	//Benfeitorias
	ElseIf _cCod $ '650002CD' .And. (AllTrim(SB1->B1_COD) $ '10020000007/10030000007/10030000008/10030000020/10030000039/10030000040/10030000067/10030000068/10030000071/10030000079';
		.Or. (AllTrim(SB1->B1_COD) >= '10030000044' .And. AllTrim(SB1->B1_COD) <= '10030000056'))
		If cFilAnt $ '05/91/92/0A'
			_cRetorno := '1304010001' //BENFEITORIAS IMOVEIS DE TER
		Else
			_cRetorno := '1302100002' //CONSTRUCOES CIVIS EM ANDAME
		EndIf

	//Serviços Terceiros PJ
	ElseIf _cCod $ '650002CD' .And. AllTrim(SB1->B1_COD) $ '10000000008/10000000040/10000000048/10000000049/10000000056/10000000063/10000000074/10000000082/10000000087/10000000133/10000000137/10000000146/10000000159/10000000165'
		If _lCCusto .Or. cFilAnt $ _cFilAdm
			_cRetorno := '3301020014' //SERVICOS TERCEIROS PJ
		ElseIf cFilAnt $ _cFil01+_cFil05
			_cRetorno := '3299020027' //SERVICOS TERCEIROS PJ
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '3299040027'
		ElseIf cFilAnt $ _cFil20
			_cRetorno := '3299080027'
		ElseIf cFilAnt $ _cFil23
			_cRetorno := '3299180027'
		ElseIf cFilAnt $ _cFil30
			_cRetorno := '3299060027'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '3299140027'
		ElseIf cFilAnt == '90'
			_cRetorno := '3299160027'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '3299200027'
		EndIf

	//Industrialização Efetuada por Terceiros
	ElseIf _cCod $ '650002CD' .And. (AllTrim(SB1->B1_COD) $ '10000000026' .Or. AllTrim(SF4->F4_CF) == '1125')
		If cFilAnt $ _cFil01+_cFil05
			_cRetorno := '3299010055' //INDUSTRIALIZACAO EFETUADA POR TERCEIROS
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '3299030055'
		ElseIf cFilAnt $ _cFil20
			_cRetorno := '3299070055'
		ElseIf cFilAnt $ _cFil23
			_cRetorno := '3299170055'
		ElseIf cFilAnt $ _cFil30
			_cRetorno := '3299050055'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '3299130055'
		ElseIf cFilAnt == '90'
			_cRetorno := '3299150055'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '3299190055'
		EndIf
		
	//ICMS ST Frete, Estorno de Débito e Crédito Presumido
	ElseIf (_cCod $ '650002CD/610001CC/610008CC/610001CD' .Or. (_cCod == '650001CC' .And. Empty(SF1->F1_L_MIX))) .And. ;
		AllTrim(SB1->B1_COD) $ '10070000004/10070000008/10070000009/10070000010/10070000019/10070000024/10070000032/10070000033/10070000035/10070000036/10070000038'
		If _cCod $ '650002CD/610001CC/610008CC/'
			If cFilAnt == '20'
				_cRetorno := '1102070052' //ICMS NORMAL A RECUP-RIO G.
			ElseIf cFilAnt == '23'
				_cRetorno := '1102070082'
			ElseIf cFilAnt == '24'
				_cRetorno := '1102070084'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '1102070089'
			EndIf
		ElseIf _cCod $ '610001CD' .Or. (_cCod == '650001CC' .And. Empty(SF1->F1_L_MIX))
			//ICMS ST Frete
			If AllTrim(SB1->B1_COD) == '10070000004'
				If cFilAnt == '20'
					_cRetorno := '1102070011' //ICMS S.TRIB.A REC.FRETE P F
				ElseIf cFilAnt == '23'
					_cRetorno := '1102070085'
				End
			//ICMS ST Frete
			ElseIf AllTrim(SB1->B1_COD) == '10070000009'
				If cFilAnt $ '20/24'
					_cRetorno := '3299080033' //(-) ICMS S/ OUTRAS ENTRADAS
				ElseIf cFilAnt $ _cFil23
					_cRetorno := '3301020050' //(-)ICMS S/ COMPRAS
				End
			//Crédito Presumido
			ElseIf AllTrim(SB1->B1_COD) $ '10070000008/10070000019/10070000024/10070000033/10070000036/10070000038'
				If cFilAnt $ '20/21/22/23/24/25'
					_cRetorno := '3105010016' //(-)ICMS CRED PRESUMIDO R.G.
				ElseIf cFilAnt $ _cFil93
					_cRetorno := '3105010029' //( - ) ICMS CRED PRESUMIDO PARANA
				End
			//Fundopem
			ElseIf AllTrim(SB1->B1_COD) == '10070000032'
				_cRetorno := '2203010004' //INCENTIVO FUNDOPEM-RS
			//Credito Antecipado/Simples Nacional
			ElseIf AllTrim(SB1->B1_COD) $ '10070000010/10070000035'
				If cFilAnt == '20'
					_cRetorno := '3299080029' //(-) ICMS S/ COMPRAS
				ElseIf cFilAnt == '23'
					_cRetorno := '3299180029'
				End
			EndIf
		EndIf

	//Água
	ElseIf _cCod $ '650002CD' .And. AllTrim(SB1->B1_COD) $ '10000000126/10000000127'
		If cFilAnt $ '01/03/05/06/07/08/09/0A'
			_cRetorno := '3299020009' //AGUA E ESGOTO
		ElseIf cFilAnt $ '02/04/0B/20/23/24/25/30/90/91/92/93'
			_cRetorno := '3301020005'
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '3299040009'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '3299140009'
		EndIf
	
	//ICMS Custo Direto
	ElseIf _cCod == '650010CC' .And. SF4->F4_I_GTES $ 'E00002'
		If cFilAnt $ _cFil01+_cFil05
			_cRetorno := '3299010015' //(-) ICMS S/COMPRAS
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '3299030015'
		ElseIf cFilAnt $ _cFil20
			_cRetorno := '3299070015'
		ElseIf cFilAnt $ _cFil23
			_cRetorno := '3299170015'
		ElseIf cFilAnt $ _cFil30
			_cRetorno := '3299050015'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '3299130015'
		ElseIf cFilAnt == '90'
			_cRetorno := '3299150015'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '3299190015'
		EndIf
	//Outras entradas
	ElseIf _cCod == '650010CC'
		If cFilAnt $ _cFil01+_cFil05
			_cRetorno := '3299020033' //(-) ICMS S/OUTRAS ENTRADAS
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '3299040033'
		ElseIf cFilAnt $ _cFil20
			_cRetorno := '3299080033'
		ElseIf cFilAnt $ _cFil23
			_cRetorno := '3299180033'
		ElseIf cFilAnt $ _cFil30
			_cRetorno := '3299060033'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '3299140033'
		ElseIf cFilAnt == '90'
			_cRetorno := '3299160033'
		ElseIf cFilAnt $ _cFilAdm
			_cRetorno := '3301020050' //(-)ICMS S/ COMPRAS
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '3299200033'
		EndIf

	//Transporte Diversos
	ElseIf _cCod $ '650002CD' .And. AllTrim(SF4->F4_CF) $ '1352/1353' 
		_cRetorno := '3301020017' //FRETES E CARRETOS

	ElseIf _cCod $ '610001CD/610003CD/610006CD/610013CD' .Or. (_cCod == '650001CC' .And. Empty(SF1->F1_L_MIX))
		If AllTrim(SF4->F4_CF) > '5000' .And. !SD2->D2_TIPO $ 'B/D' //Saídas
			If AllTrim(SA1->A1_CONTA) $ '1102069992/1102069993/1102069995/1102069996/1102069998/1102069999'
				_cRetorno := SA1->A1_CONTA
			Else
				_cRetorno := '110206G001' //CLIENTES DIVERSOS GERAL
			EndIf
		ElseIf (AllTrim(SF4->F4_CF) > '5000' .And. SD2->D2_TIPO $ 'B/D') .Or. AllTrim(SF4->F4_CF) < '5000' //Entradas e Devolução de Compras
			If SubStr(SA2->A2_CONTA,1,6) $ '210105/210106' .Or. AllTrim(SA2->A2_CONTA) == '2101019999'
				_cRetorno := SA2->A2_CONTA
			Else
				_cRetorno := '210101D001' //FORNECEDORES DIVERSOS GERAL
			EndIf
		EndIf
	EndIf
EndIf

//Retorna sempre uma conta genérica quando não identificar a conta correta
If Empty(_cRetorno) .And. SubStr(_cCod,7,1) $ 'IC'
	If (FWIsInCallStack('CTBANFE') .Or. ((FWIsInCallStack('MATA331') .Or. FWIsInCallStack('MATA330') .Or. FWIsInCallStack('M330JCTB')) .And. !_cCod $ '678001CD/641001CD/681001CD/682001CD'));
		.Or. _cCod $ '610008CC'
		If FWIsInCallStack('CTBANFE') .And. SF4->F4_ESTOQUE == 'N'
			If _lCCusto .Or. cFilAnt $ _cFil90+_cFilAdm
				_cRetorno := '3301020027'
			ElseIf cFilAnt $ _cFil01+_cFil05
				_cRetorno := '3299020011'
			ElseIf cFilAnt $ _cFil10
				_cRetorno := '3299040011'
			ElseIf cFilAnt $ _cFil20
				_cRetorno := '3299080011'
			ElseIf cFilAnt $ _cFil23
				_cRetorno := '3299180011'
			ElseIf cFilAnt $ _cFil30
				_cRetorno := '3299060011'
			ElseIf cFilAnt $ _cFil40
				_cRetorno := '3299140011'
			ElseIf cFilAnt $ _cFil93
				_cRetorno := '3299200011'
			EndIf

		ElseIf cFilAnt $ _cFil01+_cFil05+'0B'
			_cRetorno := '1102010017' //MATERIAL DE CONSUMO MATRIZ
		ElseIf cFilAnt $ _cFil10
			_cRetorno := '1102010018'
		ElseIf cFilAnt $ _cFil20
			_cRetorno := '1102010043'
		ElseIf cFilAnt $ _cFil23+'25'
			_cRetorno := '1102010070'
		ElseIf cFilAnt $ _cFil30
			_cRetorno := '1102010044'
		ElseIf cFilAnt $ _cFil40
			_cRetorno := '1102010065'
		ElseIf cFilAnt == '90'
			_cRetorno := '1102010140'
		ElseIf cFilAnt == '91'
			_cRetorno := '1102010142'
		ElseIf cFilAnt $ _cFil93
			_cRetorno := '1102010159'
		EndIf
	ElseIf FWIsInCallStack('CTBANFS')
		_cRetorno := '1101010020' //PENDENCIAS BANCO
	Else
		_cRetorno:= '3301020027'
	EndIf
EndIf

FWRestArea(_aArea)

Return (_cRetorno)
