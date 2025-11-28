/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |03/07/2025| Chamado 51251. Inclusão da natureza 221034 nas regras genéricas
Lucas Borges  |28/08/2025| Chamado 51910. Inclusão da natureza 221034 nas 121017 genéricas
Lucas Borges  |21/11/2025| Chamado 53063. Inclusão da natureza 222052 na Antecipação de Produtores
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: LPFIN002
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 31/12/2015
Descrição---------: Retorna conta contabil para LP do Financeiro
Parametros--------: _ccod = Tipo de Conta (630001CC=Conta Credito, 630001CD= Conta Debito)
Retorno-----------: _xRetorno = Retorna a conta/item contabil
===============================================================================================================================
*/
User Function LPFIN002(_cCod) As Character

Local _aArea	:= FWGetArea() As Array
Local _aAreaSE1	:= SE1->(FWGetArea()) As Array
Local _cAlias 	:= GetNextAlias() As Character
Local _xRetorno	:= Nil As Variant
Local _cItem	:= '' As Character
Local _cCCusto	:= '' As Character
Local _cNaturez	:= 'SE5->E5_NATUREZ' As Character
Local _cFil01	:= '01/02/03/04/06/07/08/09/0A/0B/' As Character
Local _cFil05	:= '05/' As Character
Local _cFil10	:= '10/11/12/13/14/15/16/17/18/19/1A/1B/1C/' As Character
Local _cFil20	:= '20/21/22/24/25/' As Character
Local _cFil23	:= '23/' As Character
Local _cFil30	:= '30/31/32/33' As Character
Local _cFil40	:= '40/' As Character
Local _cFil90	:= '90/92/' As Character//92 tem que estar no _cFil90 e _cFil91
Local _cFil93	:= '93/' As Character
Local _cFil91	:= '91/92/94/95/96/97/98/' As Character

//===========================================================================================
//520001CD - Baixa Contas a Receber Carteira Nomal - Conta Debito
//521001CD - Baixa Contas a Receber Carteira Simples - Conta Debito
//527001CC - Cancelamento Baixa Contas a Receber Carteira Normal e Simples - Conta Credito
//520001ID - Baixa Contas a Receber Carteira Nomal - Item Debito
//521001ID - Baixa Contas a Receber Carteira Simples - Item Debito
//527001IC - Cancelamento Baixa Contas a Receber Carteira Normal e Simples - Item Credito
//===========================================================================================

If _cCod $ '520001CD/521001CD/527001CC/520001ID/521001ID/527001IC'

	If AllTrim(SE5->E5_MOTBX) $ 'DCT' .And. AllTrim(SE5->E5_TIPO) == 'RA'
		_xRetorno := '2101119999'
	ElseIf AllTrim(SE5->E5_MOTBX) $ 'DCT/VBC'//Descontos Contratuais
		_xRetorno := '3301010012'
	ElseIf SE5->E5_MOTBX == 'LIQ'//Liquidações
		_xRetorno := '110206G001'
		_cItem := 'SA1'+ Posicione("SE1",15,SE5->(E5_FILIAL+E5_DOCUMEN),"E1_CLIENTE")
		FWRestArea(_aAreaSE1)
	ElseIf AllTrim(SE5->E5_MOTBX) $ 'CEC'//Compensacao entre Carteiras

		BeginSql alias _cAlias
			SELECT SE5.E5_CLIFOR, SE5.E5_LOJA, SA2.A2_CONTA
			FROM %Table:SE5% SE5, %Table:SA2% SA2
			WHERE SE5.D_E_L_E_T_ = ' '
				AND SA2.D_E_L_E_T_ = ' 
				AND SE5.E5_RECPAG = 'P'
				AND SE5.E5_FILIAL =  %exp:SE5->E5_FILIAL%
				AND SA2.A2_FILIAL =  %xFilial:SA2%
				AND SE5.E5_CLIFOR = SA2.A2_COD
				AND SE5.E5_LOJA = SA2.A2_LOJA
				AND SE5.E5_IDENTEE = %exp:SE5->E5_IDENTEE%
		EndSql

		If 	(_cAlias)->(!Eof())
			
			If SubStr((_cAlias)->E5_CLIFOR,1,1)== "A"//Regra especifica para quando o titulo a pagar refere-se a um autonomo
				_xRetorno := '3401020011'
			ElseIf SubStr((_cAlias)->A2_CONTA,1,6) $ '210105/210106'
				_xRetorno := (_cAlias)->A2_CONTA
			Else
				_xRetorno := "210101D001"
			EndIf
			_cItem := 'SA2'+SA2->A2_COD
		EndIf
		(_cAlias)->(DBCloseArea())

	ElseIf AllTrim(SE5->E5_MOTBX) == 'NOR' .And. AllTrim(SE5->E5_TIPO) == 'NCC'
		If AllTrim(SE5->E5_NATUREZ) $ '231018/231002/231009'
			If _cCod $ '527001CC'
				_xRetorno	:= '3301010022'
			Else
				_xRetorno	:= '3301010002'
			EndIf
		Else
            _xRetorno	:= '1102100004'
		EndIf
	ElseIf !Empty(SE5->E5_BANCO)
		_xRetorno := SA6->A6_CONTA
	ElseIf AllTrim(SE5->E5_MOTBX) == 'BPD' .And. AllTrim(SE5->E5_TIPO) $ 'NF/ICM' .And. AllTrim(SE5->E5_NATUREZ) == '232078'
            _xRetorno	:= '1102100001'
	ElseIf AllTrim(SE5->E5_MOTBX) == 'BPD' .And. AllTrim(SE5->E5_TIPO) == 'NCC' .And. AllTrim(SE1->E1_NATUREZ) == '410001'
            _xRetorno	:= '1102100004'
	EndIf

//======================================================================
//520001CC - Baixa Contas a Receber Carteira Nomal - Conta Credito
//521001CC - Baixa Contas a Receber Carteira Simples - Conta Credito
//527001CD - Cancelamento Baixa Contas a Receber Carteira Normal e Simples - Conta Debito
//520001ID - Baixa Contas a Receber Carteira Nomal - Item Credito
//521001ID - Baixa Contas a Receber Carteira Simples - Item Credito
//527001ID - Cancelamento Baixa Contas a Receber Carteira Normal e Simples - Item Debito
//======================================================================
	
ElseIf AllTrim(_cCod) $ '520001CC/521001CC/527001CD/520001IC/521001IC/527001ID'

	If SE5->E5_MOTBX == "DCT" .And. AllTrim(SE5->E5_TIPO) == "RA"
		_xRetorno	:=  '3401010002'

	ElseIf SE5->E5_MOTBX == "NOR" .And. SE5->E5_TIPO == "NCC"
		_xRetorno	:=  SA6->A6_CONTA

	ElseIf SE5->E5_MOTBX == "LIQ"
		_xRetorno:=  '110206G001'
		_cItem	 :=  'SA1'+SA1->A1_COD

	ElseIf AllTrim(SE5->E5_MOTBX) == 'BPD' .And. AllTrim(SE5->E5_TIPO) == 'NCC' .And. AllTrim(SE1->E1_NATUREZ) == '410001'
            _xRetorno	:= '3301020049'

	ElseIf !(AllTrim(SE5->E5_MOTBX) == "NOR" .And. AllTrim(SE5->E5_TIPO) == "NCC") .And. AllTrim(SE5->E5_NATUREZ) == "121005"
		_xRetorno	:=  '1102150006'

	ElseIf AllTrim(SE5->E5_MOTBX) == "NOR" .And. AllTrim(SE5->E5_TIPO) == "NDC" .And. AllTrim(SE5->E5_NATUREZ) $ "112015/112002"
		_xRetorno	:=  '3401010001'
		
	ElseIf AllTrim(SE5->E5_MOTBX) == "NOR" .And. AllTrim(SE5->E5_NATUREZ) $ "112015/112001/112002/112019"
		_xRetorno	:=  SED->ED_CREDIT
	Else 
		If AllTrim(SA1->A1_CONTA) $ "1102069992/1102069993/1102069995/1102069996/1102069998/1102069999"
			_xRetorno := SA1->A1_CONTA
		Else
			_xRetorno := "110206G001"
		EndIf
		_cItem		:= 'SA1'+SA1->A1_COD
	EndIf

//======================================================================
//530001CD - Baixa Contas a Pagar - Automatico - Borderos - Conta Debito
//531001CC - Cancelamento Baixa Contas a Pagar - Conta Crédito
//532001CD - Baixa Contas a Pagar - Conta Debito
//590001CD - Geração de Cheque - Conta Debito
//530001ID - Baixa Contas a Pagar - Automatico - Borderos - Item Debito
//532001ID - Baixa Contas a Pagar - Item Debito
//590001ID - Geração de Cheque - Item Debito
//======================================================================
	
ElseIf AllTrim(_cCod) $ '530001CD/532001CD/590001CD/530001ID/532001ID/590001ID/531001CC'

	If AllTrim(_cCod) == '590001CD'
		_cNaturez:='SE2->E2_NATUREZ'
	EndIf
	
	//Adiantamentos
	If AllTrim( &(_cNaturez) ) == '222003'
		If SE2->E2_FILIAL $ _cFil01+_cFil05
			_xRetorno := '1102040001'
		ElseIf SE2->E2_FILIAL $ _cFil10
			If SE2->E2_PREFIXO == 'GCO'
				_xRetorno := '2101050208'
			Else
				_xRetorno := '1102040009'
			EndIf
		ElseIf SE2->E2_FILIAL $ _cFil20+_cFil23
			_xRetorno := '1102040017'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '1102040015'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '1102040018'
		EndIf
		_cItem	  := "SA2" + SA2->A2_COD
		
	//ICMS Normal
	ElseIf AllTrim( &(_cNaturez)) == '212001'
		If SE2->E2_FILIAL == '01'
			_xRetorno := '2101020004'
		ElseIf SE2->E2_FILIAL == '02'
			_xRetorno := '2101020018'
		ElseIf SE2->E2_FILIAL == '04'
			_xRetorno := '2101020005'
		ElseIf SE2->E2_FILIAL == '05'
			_xRetorno := '2101020007'
		ElseIf SE2->E2_FILIAL == '06'
			_xRetorno := '2101020006'
		ElseIf SE2->E2_FILIAL == '08'
			_xRetorno := '2101020072'
		ElseIf SE2->E2_FILIAL == '09'
			_xRetorno := '2101020087'
		ElseIf SE2->E2_FILIAL == '0A'
			_xRetorno := '2101020089'
		ElseIf SE2->E2_FILIAL == '0B'
			_xRetorno := '2101020091'
		ElseIf SE2->E2_FILIAL == '10'
			_xRetorno := '2101020019'
		ElseIf SE2->E2_FILIAL $ '11/12'
			_xRetorno := '2101020029'
		ElseIf SE2->E2_FILIAL == '13'
			_xRetorno := '2101020023'
		ElseIf SE2->E2_FILIAL == '14'
			_xRetorno := '2101020022'
		ElseIf SE2->E2_FILIAL == '15'
			_xRetorno := '2101020021'
		ElseIf SE2->E2_FILIAL == '16'
			_xRetorno := '2101020019'
		ElseIf SE2->E2_FILIAL $ '17/18'
			_xRetorno := '2101020024'
		ElseIf SE2->E2_FILIAL == '19'
			_xRetorno := '2101020016'
		ElseIf SE2->E2_FILIAL == '1A'
			_xRetorno := '2101020015'
		ElseIf SE2->E2_FILIAL == '1B'
			_xRetorno := '2101020033'
		ElseIf SE2->E2_FILIAL == '20'
			_xRetorno := '2101020053'
		ElseIf SE2->E2_FILIAL == '23'
			_xRetorno := '2101020075'
		ElseIf SE2->E2_FILIAL == '24'
			_xRetorno := '2101020085'
		ElseIf SE2->E2_FILIAL == '25'
			_xRetorno := '2101020076'
		ElseIf SE2->E2_FILIAL == '30'
			_xRetorno := '2101020034'
		ElseIf SE2->E2_FILIAL == '31'
			_xRetorno := '2101020113'
		ElseIf SE2->E2_FILIAL == '32'
			_xRetorno := '2101020115'
		ElseIf SE2->E2_FILIAL == '33'
			_xRetorno := '2101020118'
		ElseIf SE2->E2_FILIAL == '40'
			_xRetorno := '2101020069'
		ElseIf SE2->E2_FILIAL == '90'
			_xRetorno := '2101020035'
		ElseIf SE2->E2_FILIAL == '91'
			_xRetorno := '2101020046'
		ElseIf SE2->E2_FILIAL == '92'
			_xRetorno := '2101020066'
		ElseIf SE2->E2_FILIAL == '93'
			_xRetorno := '2101020097'
		ElseIf SE2->E2_FILIAL == '94'
			_xRetorno := '2101020103'
		ElseIf SE2->E2_FILIAL == '95'
			_xRetorno := '2101020105'
		ElseIf SE2->E2_FILIAL == '96'
			_xRetorno := '2101020107'
		ElseIf SE2->E2_FILIAL == '97'
			_xRetorno := '2101020109'
		ElseIf SE2->E2_FILIAL == '98'
			_xRetorno := '2101020111'
		EndIf

	//ICMS Substituição Tributaria
	ElseIf AllTrim( &(_cNaturez)) == '212002'
		If SE2->E2_FILIAL == '01'
			_xRetorno	:= '2101020065'
		ElseIf SE2->E2_FILIAL == '10'
			_xRetorno	:= '2101020012'
		ElseIf SE2->E2_FILIAL == '20'
			_xRetorno	:= '2101020054'
		ElseIf SE2->E2_FILIAL == '23'
			_xRetorno	:= '2101020077'
		ElseIf SE2->E2_FILIAL == '31'
			_xRetorno	:= '2101020114'
		ElseIf SE2->E2_FILIAL == '32'
			_xRetorno	:= '2101020116'
		ElseIf SE2->E2_FILIAL == '33'
			_xRetorno	:= '2101010119'
		ElseIf SE2->E2_FILIAL == '40'
			_xRetorno	:= '2101020073'
		ElseIf SE2->E2_FILIAL == '90'
			_xRetorno	:= '2101020051'
		ElseIf SE2->E2_FILIAL == '91'
			_xRetorno	:= '2101020062'
		ElseIf SE2->E2_FILIAL == '93'
			_xRetorno	:= '2101020098'
		ElseIf SE2->E2_FILIAL == '94'
			_xRetorno	:= '2101020104'
		ElseIf SE2->E2_FILIAL == '95'
			_xRetorno	:= '2101020106'
		ElseIf SE2->E2_FILIAL == '96'
			_xRetorno	:= '2101020108'
		ElseIf SE2->E2_FILIAL == '97'
			_xRetorno	:= '2101020110'
		ElseIf SE2->E2_FILIAL == '98'
			_xRetorno	:= '2101020112'
		EndIf

	//ICMS Substituição Tributária Frete
	ElseIf AllTrim( &(_cNaturez)) == '212029'
		If SE2->E2_FILIAL == '01'
			_xRetorno := '2101020008'
		ElseIf SE2->E2_FILIAL == '04'
			_xRetorno := '2101020014'
		ElseIf SE2->E2_FILIAL == '05'
			_xRetorno := '2101020013'
		ElseIf SE2->E2_FILIAL == '06'
			_xRetorno := '2101020016'
		ElseIf SE2->E2_FILIAL == '10'
			_xRetorno := '2101020026'
		ElseIf SE2->E2_FILIAL == '20'
			_xRetorno := '1102070011'
		ElseIf SE2->E2_FILIAL == '23'
			_xRetorno := '1102070085'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '3301010006'
		ElseIf SE2->E2_FILIAL == '40'
			_xRetorno := '2101020073'
		ElseIf SE2->E2_FILIAL == '93'
			_xRetorno := '2101020098'
		EndIf

	//ICMS Substituição Tributária Leite Cru
	ElseIf AllTrim( &(_cNaturez)) == '212030'
		If SE2->E2_FILIAL $ '04/40'
			_xRetorno := '1102070010'
		EndIf

	//ICMS Substituição Tributária Queijo
	ElseIf AllTrim( &(_cNaturez)) == '212031'
		If SE2->E2_FILIAL == '01'
			_xRetorno := '1102070007'
		ElseIf SE2->E2_FILIAL == '05'
			_xRetorno := '1102070013'
		EndIf

	//ICMS Substituição Tributária Energia Elétrica
	ElseIf AllTrim( &(_cNaturez)) == '212041'
		_xRetorno := '2101020090'

	//ICMS Diferencial de aliquotas
	ElseIf AllTrim( &(_cNaturez)) == '212035'
		_xRetorno := '3301020063'

	//INSS s/ Folha
	ElseIf AllTrim( &(_cNaturez)) == '221018'
		If SE2->E2_FILIAL == '01'
			_xRetorno := '2101030001'
		ElseIf SE2->E2_FILIAL == '02'
			_xRetorno := '2101030021'
		ElseIf SE2->E2_FILIAL == '04'
			_xRetorno := '2101030002'
		ElseIf SE2->E2_FILIAL == '05'
			_xRetorno := '2101030005'
		ElseIf SE2->E2_FILIAL == '06'
			_xRetorno := '2101030006'
		ElseIf SE2->E2_FILIAL == '08'
			_xRetorno := '2101030096'
		ElseIf SE2->E2_FILIAL == '09'
			_xRetorno := '2101030089'
		ElseIf SE2->E2_FILIAL == '0A'
			_xRetorno := '2101030091'
		ElseIf SE2->E2_FILIAL == '0B'
			_xRetorno := '2101030098'
		ElseIf SE2->E2_FILIAL == '10'
			_xRetorno := '2101030022'
		ElseIf SE2->E2_FILIAL == '11'
			_xRetorno := '2101030025'			
		ElseIf SE2->E2_FILIAL == '12'
			_xRetorno := '2101030073'
		ElseIf SE2->E2_FILIAL == '13'
			_xRetorno := '2101030041'
		ElseIf SE2->E2_FILIAL == '14'
			_xRetorno := '2101030023'
		ElseIf SE2->E2_FILIAL == '15'
			_xRetorno := '2101030024'
		ElseIf SE2->E2_FILIAL == '16'
			_xRetorno := '2101030038'
		ElseIf SE2->E2_FILIAL == '17'
			_xRetorno := '2101030075'
		ElseIf SE2->E2_FILIAL == '18'
			_xRetorno := '2101030040'			
		ElseIf SE2->E2_FILIAL == '19'
			_xRetorno := '2101030049'
		ElseIf SE2->E2_FILIAL == '1A'
			_xRetorno := '2101030003'
		ElseIf SE2->E2_FILIAL == '1B'
			_xRetorno := '2101030017'
		ElseIf SE2->E2_FILIAL == '1C'
			_xRetorno := '2101030052'
		ElseIf SE2->E2_FILIAL == '20'
			_xRetorno := '2101030066'
		ElseIf SE2->E2_FILIAL == '21'
			_xRetorno := '2101030062'
		ElseIf SE2->E2_FILIAL == '22'
			_xRetorno := '2101030069'
		ElseIf SE2->E2_FILIAL == '23'
			_xRetorno := '2101030081'
		ElseIf SE2->E2_FILIAL == '24'
			_xRetorno := '2101030087'
		ElseIf SE2->E2_FILIAL == '25'
			_xRetorno := '2101030084'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '2101030053'
		ElseIf SE2->E2_FILIAL == '40'
			_xRetorno := '2101030077'
		ElseIf SE2->E2_FILIAL $ _cFil90
			_xRetorno := '2101030058'
		ElseIf SE2->E2_FILIAL == '91'
			_xRetorno := '2101030064'
		ElseIf SE2->E2_FILIAL == '93'
			_xRetorno := '2101030102'
		EndIf

	//Funrural INSS
	ElseIf AllTrim( &(_cNaturez)) $ '221028/212033/SENAR'
		If SE2->E2_FILIAL == '01'
			_xRetorno := '2101030013'
		ElseIf SE2->E2_FILIAL == '02'
			_xRetorno := '2101030031'
		ElseIf SE2->E2_FILIAL == '04'
			_xRetorno := '2101030014'
		ElseIf SE2->E2_FILIAL == '05'
			_xRetorno := '2101030016'
		ElseIf SE2->E2_FILIAL == '06'
			_xRetorno := '2101030018'
		ElseIf SE2->E2_FILIAL == '09'
			_xRetorno := '2101030093'
		ElseIf SE2->E2_FILIAL == '0A'
			_xRetorno := '2101030094'
		ElseIf SE2->E2_FILIAL == '0B'
			_xRetorno := '2101030100'
		ElseIf SE2->E2_FILIAL == '10'
			_xRetorno := '2101030032'
		ElseIf SE2->E2_FILIAL == '11'
			_xRetorno := '2101030035'
		ElseIf SE2->E2_FILIAL == '12'
			_xRetorno := '2101030074'
		ElseIf SE2->E2_FILIAL == '13'
			_xRetorno := '2101030046'
		ElseIf SE2->E2_FILIAL == '14'
			_xRetorno := '2101030033'
		ElseIf SE2->E2_FILIAL == '15'
			_xRetorno := '2101030034'
		ElseIf SE2->E2_FILIAL == '16'
			_xRetorno := '2101030042'
		ElseIf SE2->E2_FILIAL $ '17/18'
			_xRetorno := '2101030043'
		ElseIf SE2->E2_FILIAL == '19'
			_xRetorno := '2101030072'
		ElseIf SE2->E2_FILIAL == '1A'
			_xRetorno := '2101030015'
		ElseIf SE2->E2_FILIAL == '1B'
			_xRetorno := '2101030048'
		ElseIf SE2->E2_FILIAL == '1C'
			_xRetorno := '2101030056'
		ElseIf SE2->E2_FILIAL == '20'
			_xRetorno := '2101030068'
		ElseIf SE2->E2_FILIAL == '21'
			_xRetorno := '2101030065'
		ElseIf SE2->E2_FILIAL == '22'
			_xRetorno := '2101030071'
		ElseIf SE2->E2_FILIAL == '23'
			_xRetorno := '2101030082'
		ElseIf SE2->E2_FILIAL == '24'
			_xRetorno := '2101030088'
		ElseIf SE2->E2_FILIAL == '25'
			_xRetorno := '2101030085'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '2101030057'
		ElseIf SE2->E2_FILIAL == '40'
			_xRetorno := '2101030079'
		ElseIf SE2->E2_FILIAL == '93'
			_xRetorno := '2101030104'
		EndIf

    //FGTS
	ElseIf AllTrim( &(_cNaturez)) == '221019'
		If SE2->E2_FILIAL == '01'
			_xRetorno := '2101030007'
		ElseIf SE2->E2_FILIAL == '02'
			_xRetorno := '2101030026'
		ElseIf SE2->E2_FILIAL == '04'
			_xRetorno := '2101030008'
		ElseIf SE2->E2_FILIAL == '05'
			_xRetorno := '2101030010'
		ElseIf SE2->E2_FILIAL == '06'
			_xRetorno := '2101030012'
		ElseIf SE2->E2_FILIAL == '08'
			_xRetorno := '2101030097'
		ElseIf SE2->E2_FILIAL == '09'
			_xRetorno := '2101030090'
 		ElseIf SE2->E2_FILIAL == '0A'
			_xRetorno := '2101030092'
 		ElseIf SE2->E2_FILIAL == '0B'
			_xRetorno := '2101030099'
		ElseIf SE2->E2_FILIAL == '10'
			_xRetorno := '2101030027'
		ElseIf SE2->E2_FILIAL == '11'
			_xRetorno := '2101030011'
		ElseIf SE2->E2_FILIAL == '12'
			_xRetorno := '2101030044'
		ElseIf SE2->E2_FILIAL == '13'
			_xRetorno := '2101030036'
		ElseIf SE2->E2_FILIAL == '14'
			_xRetorno := '2101030028'
		ElseIf SE2->E2_FILIAL == '15'
			_xRetorno := '2101030029'
		ElseIf SE2->E2_FILIAL == '16'
			_xRetorno := '2101030039'
		ElseIf SE2->E2_FILIAL == '17'
			_xRetorno := '2101030045'
		ElseIf SE2->E2_FILIAL == '18'
			_xRetorno := '2101030037'			
		ElseIf SE2->E2_FILIAL == '19'
			_xRetorno := '2101030060'
		ElseIf SE2->E2_FILIAL == '1A'
			_xRetorno := '2101030009'
		ElseIf SE2->E2_FILIAL == '1B'
			_xRetorno := '2101030047'
		ElseIf SE2->E2_FILIAL == '1C'
			_xRetorno := '2101030054'
		ElseIf SE2->E2_FILIAL == '20'
			_xRetorno := '2101030067'
		ElseIf SE2->E2_FILIAL == '21'
			_xRetorno := '2101030061'
		ElseIf SE2->E2_FILIAL == '22'
			_xRetorno := '2101030070'
		ElseIf SE2->E2_FILIAL == '23'
			_xRetorno := '2101030080'
		ElseIf SE2->E2_FILIAL == '24'
			_xRetorno := '2101030086'
		ElseIf SE2->E2_FILIAL == '25'
			_xRetorno := '2101030083'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '2101030055'
		ElseIf SE2->E2_FILIAL == '40'
			_xRetorno := '2101030078'
		ElseIf SE2->E2_FILIAL $ _cFil90
			_xRetorno := '2101030059'
		ElseIf SE2->E2_FILIAL == '91'
			_xRetorno := '2101030063'
		ElseIf SE2->E2_FILIAL == '93'
			_xRetorno := '2101030103'
		EndIf

	//Adiantamento de Salarios
	ElseIf AllTrim( &(_cNaturez)) == '221004' .Or.  (AllTrim(SE2->E2_TIPO) $ 'NDF/PA/RPA/FT/RC/BOL' .And. AllTrim( &(_cNaturez)) == '121004')
		If SE2->E2_FILIAL $ '01/02/03/05/06/07'
			_xRetorno := '1102030001'
		ElseIf SE2->E2_FILIAL == '04'
			_xRetorno := '1102030002'
		ElseIf SE2->E2_FILIAL == '08'
			_xRetorno := '1102030033'
		ElseIf SE2->E2_FILIAL == '09'
			_xRetorno := '1102030031'
		ElseIf SE2->E2_FILIAL == '0A'
			_xRetorno := '1102030030'
		ElseIf SE2->E2_FILIAL == '0B'
			_xRetorno := '1102030034'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '1102030008'
		ElseIf SE2->E2_FILIAL $ _cFil20+_cFil23
			_xRetorno := '1102030026'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '1102030020'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '1102030028'
		ElseIf SE2->E2_FILIAL $ _cFil90
			_xRetorno := '1102030021'
		ElseIf SE2->E2_FILIAL == '91'
			_xRetorno := '1102030027'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '1102030035'
		EndIf

	//Antecipação Produtores
	ElseIf AllTrim( &(_cNaturez) ) == '222068' .Or.;
		(AllTrim( &(_cNaturez)) == '222052'  .And. SubStr(SE2->E2_FORNECE,1,1) == "P" .And. SE2->E2_PREFIXO == 'GLN';
		 .And. SE2->E2_FILIAL <> '10')
		If SE2->E2_FILIAL $ _cFil01+_cFil05
			_xRetorno := '2101050201'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '2101050208'
		ElseIf SE2->E2_FILIAL $ _cFil20
			_xRetorno := '2101050216'
		ElseIf SE2->E2_FILIAL == '23'
			_xRetorno := '2101050217'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '2101050215'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '2101050205'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '2101050218'
		EndIf

	//ISS
	ElseIf AllTrim( &(_cNaturez)) == '212019'
		If SE2->E2_FILIAL $ '01/02/03/04/07/08/09/0A/0B'
			_xRetorno := '2101020030'
		ElseIf SE2->E2_FILIAL == '06'
			_xRetorno := '2101020094'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '2101020079'
		ElseIf SE2->E2_FILIAL == '20'
			_xRetorno := '2101020080'
		ElseIf SE2->E2_FILIAL $ _cFil23
			_xRetorno := '2101020081'
		ElseIf SE2->E2_FILIAL == '24'
			_xRetorno := '2101020095'
		ElseIf SE2->E2_FILIAL == '25'
			_xRetorno := '2101020092'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '2101020082'
		ElseIf SE2->E2_FILIAL $ _cFil90
			_xRetorno := '2101020083'
		ElseIf SE2->E2_FILIAL == '91'
			_xRetorno := '2101020084'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '2101020096'
		EndIf

	//Impostos retidos
	ElseIf AllTrim(SE5->E5_NATUREZ) $ '212007/212012/212013/212014/212015'
		_xRetorno := SED->ED_DEBITO

	//Paytrack
	ElseIf AllTrim(SE2->E2_ORIGEM) == 'MFIN021'
		_xRetorno := '2101080019'

	//Convênios
	ElseIf AllTrim(SE5->E5_NATUREZ) == '222039'
		If AllTrim(_cCod) == '531001CC'
			_xRetorno := SED->ED_CREDIT
		Else
			_xRetorno := SED->ED_DEBITO
			_cItem := 'SA2'+SA2->A2_COD
		EndIf

	//Ajuda de Custo Produtor
	ElseIf AllTrim( &(_cNaturez)) $ '222017/222018'
		If SE2->E2_FILIAL $ _cFil01
			_xRetorno := '3299010042'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '3299030027'
		ElseIf SE2->E2_FILIAL == '20'
			_xRetorno := '3299080040'
		ElseIf SE2->E2_FILIAL $ _cFil23
			_xRetorno := '3299170042'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '3299130042'
		ElseIf SE2->E2_FILIAL == '90'
			_xRetorno := '3299150042'
		EndIf

	//Fretes e Carretos - trecho existe 2 vezes
	ElseIf !AllTrim(_cCod) == '531001CC' .And. AllTrim(SE2->E2_TIPO) $ 'RPA/FT' .And. AllTrim( &(_cNaturez)) $ '222037'
		If SE2->E2_FILIAL $ _cFil01
			_xRetorno := '3299020015'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '3299040015'
		ElseIf SE2->E2_FILIAL $ _cFil20
			_xRetorno := '3299080015'
		ElseIf SE2->E2_FILIAL $ _cFil23
			_xRetorno := '3299180015'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '3299060015'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '3299140015'
		ElseIf SE2->E2_FILIAL == '90'
			_xRetorno := '3299160015'
		ElseIf SE2->E2_FILIAL $ '91/92'
			_xRetorno := '3301020017'
		ElseIf SE2->E2_FILIAL == '93'
			_xRetorno := '3299200015'
		EndIf

	//FGTS Rescisorio
	ElseIf AllTrim(SE2->E2_TIPO) == 'FGT' .And. AllTrim( &(_cNaturez)) == '221035'
		If AllTrim(_cCod) == '531001CC'
			_xRetorno := '3301020049'
		Else
			_xRetorno := '3301020080'
		EndIf

	//Rescisoes trabalhadores
	ElseIf AllTrim( &(_cNaturez)) == '221035'
		If AllTrim(_cCod) == '531001CC'
			_xRetorno := '3301020049'
		Else
			_xRetorno := '1102030099'
		EndIf
		
	//Lanches e refeições
	ElseIf !AllTrim(_cCod) == '531001CC' .And. AllTrim(SE2->E2_ORIGEM) == 'FINA050' .And. AllTrim( &(_cNaturez)) == '221023'
		If SE2->E2_FILIAL $ _cFil01
			_xRetorno := '3299020025'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '3299040025'
		ElseIf SE2->E2_FILIAL $ _cFil20
			_xRetorno := '3299080025'
		ElseIf SE2->E2_FILIAL $ _cFil23
			_xRetorno := '3299180025'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '3299060025'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '3299140025'
		ElseIf SE2->E2_FILIAL == '90'
			_xRetorno := '3299160025'
		ElseIf SE2->E2_FILIAL $ '91/92'
			_xRetorno := '3301020038'
		EndIf

	//Aluguéis de máquinas
	ElseIf !AllTrim(_cCod) == '531001CC' .And. AllTrim(SE2->E2_ORIGEM) == 'FINA050' .And. AllTrim( &(_cNaturez)) $ '222034/222053/222057'
		If SE2->E2_FILIAL $ _cFil01+_cFil05
			_xRetorno := '3299040025'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '3299040021'
		ElseIf SE2->E2_FILIAL $ _cFil20
			_xRetorno := '3299080021'
		ElseIf SE2->E2_FILIAL $ _cFil23
			_xRetorno := '3299180021'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '3299060021'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '3299140021'
		ElseIf SE2->E2_FILIAL == '90'
			_xRetorno := '3299160021'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '3299200021'
		EndIf

	//Aluguéis
	ElseIf !AllTrim(_cCod) == '531001CC' .And. AllTrim(SE2->E2_ORIGEM) == 'FINA050' .And. AllTrim( &(_cNaturez)) $ '222035/222036/222054/232051/232007'
		If SE2->E2_FORNECE == "F07492" .Or. SE2->E2_FILIAL == '40'
			_xRetorno := '3299140020'
		ElseIf SE2->E2_FILIAL $ _cFil01+_cFil05
			_xRetorno := '3299020020'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '3299040020'
		ElseIf SE2->E2_FILIAL $ _cFil20
			_xRetorno := '3299080020'
		ElseIf SE2->E2_FILIAL $ _cFil23
			_xRetorno := '3299180020'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '3299060020'
		ElseIf SE2->E2_FILIAL $ _cFil90+_cFil91
			_xRetorno := '3301020018'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '3299200020'
		EndIf

	//Recup. Custos
	ElseIf AllTrim(_cCod) == '531001CC' .And. ;
	((AllTrim(SE2->E2_TIPO) $ 'RPA/FT' .And. AllTrim( &(_cNaturez)) $ '222037');	//Fretes e Carretos
	 .Or. (AllTrim(SE2->E2_ORIGEM) == 'FINA050' .And. AllTrim( &(_cNaturez)) == '221023');	//Lanches e refeições
	 .Or. (AllTrim(SE2->E2_ORIGEM) == 'FINA050' .And. AllTrim( &(_cNaturez)) $ '222034/222053/222057');	//Aluguéis de máquinas
	 .Or. (AllTrim(SE2->E2_ORIGEM) == 'FINA050' .And. AllTrim( &(_cNaturez)) $ '222035/22036/222054/232051');	//Aluguéis
	 .Or. (AllTrim(SE2->E2_ORIGEM) == 'FINA050' .And. AllTrim( &(_cNaturez)) $ '221021/221041'); //Serviços Terceiros PF
	 )  
		If SE2->E2_FILIAL $ _cFil01
			_xRetorno := '3299020030'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '3299040030'
		ElseIf SE2->E2_FILIAL $ _cFil20
			_xRetorno := '3299080030'
		ElseIf SE2->E2_FILIAL $ _cFil23
			_xRetorno := '3299180030'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '3299060030'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '3299140030'
		ElseIf SE2->E2_FILIAL $ '90/91/92'
			_xRetorno := '3301020049'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '3299200030'
		EndIf

	//Antecipação Fretitas Leite
	ElseIf AllTrim( &(_cNaturez)) == '222052'  .And. SubStr(SE2->E2_FORNECE,1,1) == "G" .And. SE2->E2_PREFIXO == 'GLN'
		_xRetorno := '1102110058'

	//Antecipação Fretitas - Pagamento
	ElseIf AllTrim( &(_cNaturez)) == '222071'  .And. SubStr(SE2->E2_FORNECE,1,1) == "G" .And. SE2->E2_PREFIXO == 'GLN'
		If SE2->E2_FILIAL $ _cFil01+_cFil05
			_xRetorno := '1102050001'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '1102050008'
		ElseIf SE2->E2_FILIAL $ _cFil20+_cFil23
			_xRetorno := '1102050016'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '1102050015'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '1102050017'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '1102050018'
		EndIf
			
	//Adiantamentos Fretitas Leite
	ElseIf AllTrim( &(_cNaturez)) == '222005'  .Or. (AllTrim( &(_cNaturez)) == '222038' .And. SE2->E2_PREFIXO == 'GLN')
		If SE2->E2_FILIAL $ _cFil01+_cFil05
			_xRetorno := '1102050001'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '1102050008'
		ElseIf SE2->E2_FILIAL $ _cFil20+_cFil23
			_xRetorno := '1102050016'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '1102050015'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '1102050017'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '1102050018'
		EndIf

	//Lenha
	ElseIf AllTrim(SE2->E2_TIPO) $ 'NDF/PA/RPA/FT/RC/BOL' .And. AllTrim( &(_cNaturez)) == '222020'
		_xRetorno := SED->ED_DEBITO
		_cItem	  := "SA2" + SA2->A2_COD

	//Vale Transporte
	ElseIf AllTrim(SE2->E2_ORIGEM) == 'FINA050' .And. AllTrim( &(_cNaturez)) == '221033'
		_xRetorno := '1102030023'

	//Serviços Terceiros PF
	ElseIf !AllTrim(_cCod) == '531001CC' .And. AllTrim(SE2->E2_ORIGEM) == 'FINA050' .And. AllTrim( &(_cNaturez)) $ '221021/221041'
		If SE2->E2_FILIAL $ _cFil01+_cFil05
			_xRetorno := '3299020026'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '3299040026'
		ElseIf SE2->E2_FILIAL $ _cFil20
			_xRetorno := '3299080026'
		ElseIf SE2->E2_FILIAL $ _cFil23
			_xRetorno := '3299180026'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '3299060026'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '3299140026'
		ElseIf SE2->E2_FILIAL == '90'
			_xRetorno := '3299160026'
		ElseIf SE2->E2_FILIAL $ '91/92'
			_xRetorno := '3301020013'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '3299200026'
		EndIf
		
	//Serviços Terceiros PJ
	ElseIf AllTrim(SE2->E2_ORIGEM) == 'FINA050' .And. AllTrim( &(_cNaturez)) == '221022'
		If SE2->E2_FILIAL $ _cFil10+_cFil05
			_xRetorno := '3299020027'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '3299040027'
		ElseIf SE2->E2_FILIAL $ _cFil20
			_xRetorno := '3299080027'
		ElseIf SE2->E2_FILIAL $ _cFil23
			_xRetorno := '3299180027'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '3299060027'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '3299140027'
		ElseIf SE2->E2_FILIAL == '90'
			_xRetorno := '3299160027'
		ElseIf SE2->E2_FILIAL $ '91/92'
			_xRetorno := '3301020014'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '3299200027'
		EndIf
	
	//Fundoleite - Parte Despesa
	ElseIf AllTrim( &(_cNaturez)) == '212049'
		If SE2->E2_FILIAL == '20'
			_xRetorno := '3299070040'
		Else
			_xRetorno := '3299170040'
		EndIf

	//Naturezas Diversas
	ElseIf ((AllTrim( &(_cNaturez)) >= '212003' .And. AllTrim( &(_cNaturez)) <= '212011');
	.Or. (AllTrim( &(_cNaturez)) >= '212017' .And. AllTrim( &(_cNaturez)) <= '212028'));
	 .Or. (!AllTrim(SE2->E2_TIPO) $ 'FT'.AND.;
	(AllTrim( &(_cNaturez)) $ '112005/112012/121005/121009/121010/121017/211022';
	.Or. AllTrim( &(_cNaturez)) $ '212032/212034/212037/212038/212040/212047/212048/212050';
	.Or. (AllTrim( &(_cNaturez)) >= '213001' .And. AllTrim( &(_cNaturez)) <= '213003') ;
	.Or. (AllTrim( &(_cNaturez)) >= '214001' .And. AllTrim( &(_cNaturez)) <= '214002') ;
	.Or. (AllTrim( &(_cNaturez)) >= '221001' .And. AllTrim( &(_cNaturez)) <= '221003') ;
	.Or. (AllTrim( &(_cNaturez)) >= '221005' .And. AllTrim( &(_cNaturez)) <= '221008') ;
	.Or. AllTrim( &(_cNaturez)) $ '221013/221014/221017/221020/221023/221025/221029/221032/221034/221038/221041/221043/221047';
	.Or. (AllTrim( &(_cNaturez)) >= '222009' .And. AllTrim( &(_cNaturez)) <= '222010') ;
	.Or. ( AllTrim( &(_cNaturez)) >= '231000' .And. AllTrim( &(_cNaturez)) <='233999') ;
	.Or. AllTrim( &(_cNaturez)) $ '222026/222030/222036/222056/222058/222059/232001/232002/232005/232007/232012/232013/232015/232018/232019/232022/';
	.Or. AllTrim( &(_cNaturez)) $ '232023/232032/232040/232046/232050/232058/232059/232067/232071/232075/232079/313001/321001/321004/399002/399008/399013'))
		If AllTrim(SE2->E2_ORIGEM) $ 'FINA050/FINA565/GPEM670' .Or. AllTrim(SE2->E2_TIPO) = 'TX';
		 .Or. (AllTrim(SE2->E2_ORIGEM) $ 'FINA290' .And. !AllTrim( &(_cNaturez)) $ '221013/222026/231007/231030/232002/232025/232030/232058/232072')
			If AllTrim(_cCod) == '531001CC'
				_xRetorno := '3301020049'
			Else
				If AllTrim( &(_cNaturez)) == '221013' .And. SubStr(SE2->E2_FORNECE,1,1) == 'J'//Pagamento de despesas de funcionários
					_xRetorno := '3301020038'
				ElseIf AllTrim( &(_cNaturez)) == '231022' .And. SubStr(SE2->E2_FORNECE,1,1) == 'J' //Pagamento de despesas de funcionários
					_xRetorno := '3301020011'
				Else
					_xRetorno := SED->ED_DEBITO
				EndIf
			EndIf
		Else
			If AllTrim(_cCod) == '531001CC' .And. !Empty(SED->ED_CREDIT)
				_xRetorno := SED->ED_CREDIT
			Else
				_xRetorno := "210101D001"
				_cItem := 'SA2'+SA2->A2_COD
			EndIf
		EndIf
	Else
		If SubStr(SA2->A2_CONTA,1,6) $ '210105/210106'
			_xRetorno := SA2->A2_CONTA
		Else
			_xRetorno := "210101D001"
		EndIf
		_cItem	  := "SA2" + SA2->A2_COD
	EndIf

//=====================================================================
//530002CD - Baixa Contas a Pagar - Juros e Multas - Conta Debito
//532002CD - Baixa Contas a Pagar Automática - Juros e Multas - Conta Debito
//597002CD - Compensação Contas a Pagar - Juros e Multas - Conta Débito
//=====================================================================
ElseIf _cCod $ '530002CD/532002CD/597002CD'

	//Adiantamentos
	If AllTrim(SE5->E5_NATUREZ) == '222003'
		If SE2->E2_FILIAL $ _cFil01+_cFil05
			_xRetorno := '1102040001'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '1102040009'
		ElseIf SE2->E2_FILIAL $ _cFil20+_cFil23
			_xRetorno := '1102040017'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '1102040015'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '1102040018'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '1102040019'
		EndIf
		
	//Adiantamentos Fretista Leite
	ElseIf AllTrim(SE5->E5_NATUREZ) == '222005'  .Or. (AllTrim( SE5->E5_NATUREZ) $ '222038/222071' .And. SE2->E2_PREFIXO == 'GLN')
		If SE2->E2_FILIAL $ _cFil01+_cFil05
			_xRetorno := '1102050001'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '1102050008'
		ElseIf SE2->E2_FILIAL $ _cFil20+_cFil23
			_xRetorno := '1102050016'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '1102050015'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '1102050017'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '1102050018'
		EndIf

	//Antecipação de produtores
	ElseIf AllTrim(SE5->E5_NATUREZ) $ '222068/222052'
		If SE2->E2_FILIAL $ _cFil01+_cFil05
			_xRetorno := '2101050201'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '2101050208'
		ElseIf SE2->E2_FILIAL $ _cFil20
			_xRetorno := '2101050216'
		ElseIf SE2->E2_FILIAL $ _cFil23
			_xRetorno := '2101050217'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '2101050215'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '2101050205'
		EndIf
	
	//Empréstimo
	ElseIf AllTrim(SE5->E5_NATUREZ) == '222009'
		_xRetorno := '1102119999'

	ElseIf AllTrim(SE5->E5_NATUREZ) $ "121005/212001/212002/212007/212013/212018/212019/212020/221018/221019"
		_xRetorno := '3401020006'
	Else 
		_xRetorno := '3401020001'
	EndIf

//==============================================================================
//530004TC - Baixa Contas a Pagar - Deducoes Fretistas - Centro de Custo Crédito
//==============================================================================
ElseIf _cCod $ '530004TC'

	If _cCod == '530004TC' .And. AllTrim(SE5->E5_NATUREZ) == '222040'
		If SE5->E5_FILIAL $ _cFil01+_cFil05
			_cCCusto := '13001002'
		ElseIf SE5->E5_FILIAL $ _cFil10
			_cCCusto := '23001002'
		ElseIf SE5->E5_FILIAL $ _cFil20
			_cCCusto := '43001002'
		ElseIf SE5->E5_FILIAL $ _cFil23
			_cCCusto := '93001002'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_cCCusto := '33001002'
		ElseIf SE5->E5_FILIAL $ _cFil40
			_cCCusto := '83001002'
		ElseIf SE5->E5_FILIAL $ _cFil93
			_cCCusto := 'A8001001'
		EndIf
	EndIf

//=====================================================================
//530004CC - Baixa Contas a Pagar - Deducoes Fretistas - Conta Credito
//531004CD - Cancelmento Baixa Contas a Pagar - Deducoes Fretistas - Conta Débito
//=====================================================================
ElseIf _cCod $ '530004CC/531004CD'

	//Desconto inventário Castrolanda
	If _cCod == '530004CC' .And. SE2->E2_FORNECE == 'F04620'
		_xRetorno := '3401010002'

	//Antecipação Fretitas Leite
	ElseIf AllTrim(SE5->E5_NATUREZ) == '222052'  .And. SubStr(SE2->E2_FORNECE,1,1) == "G" .And. SE2->E2_PREFIXO == 'GLN'
		_xRetorno := '1102110058'
					
	//Adiantamentos Fretitas Leite
	ElseIf AllTrim(SE5->E5_NATUREZ) == '222005'  .Or. (AllTrim( SE5->E5_NATUREZ) $ '222038/222071' .And. SE2->E2_PREFIXO == 'GLN')
		If SE5->E5_FILIAL $ _cFil01+_cFil05
			_xRetorno := '1102050001'
		ElseIf SE5->E5_FILIAL $ _cFil10
			_xRetorno := '1102050008'
		ElseIf SE5->E5_FILIAL $ _cFil20+_cFil23
			_xRetorno := '1102050016'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '1102050015'
		ElseIf SE5->E5_FILIAL $ _cFil40
			_xRetorno := '1102050017'
		ElseIf SE5->E5_FILIAL $ _cFil93
			_xRetorno := '1102050018'
		EndIf
		
	//Convênios
	ElseIf AllTrim(SE5->E5_NATUREZ) == '222039'
		_xRetorno := '2101080012'

	//Compras produtores Fretitas Leite
	ElseIf AllTrim(SE5->E5_NATUREZ) == '222040' .And. SE2->E2_PREFIXO == 'GN1'
		If SE5->E5_FILIAL $ _cFil01+_cFil05
			_xRetorno := '1102069998'
		ElseIf SE5->E5_FILIAL $ _cFil10
			_xRetorno := '1102069999'
		ElseIf SE5->E5_FILIAL $ _cFil20+_cFil23
			_xRetorno := '1102069993'
		ElseIf SE5->E5_FILIAL $ _cFil40
			_xRetorno := '1102069995'
		EndIf
		
	//Recup. Custos / Falta de Leite
	ElseIf _cCod == '530004CC' .And. AllTrim(SE5->E5_NATUREZ) $ '222040/222042/222043/222045' 
		If SE5->E5_FILIAL $ _cFil01+_cFil05
			_xRetorno := '3299020030'
		ElseIf SE5->E5_FILIAL $ _cFil10
			_xRetorno := '3299040030'
		ElseIf SE5->E5_FILIAL $ _cFil20
			_xRetorno := '3299080030'
		ElseIf SE5->E5_FILIAL $ _cFil23
			_xRetorno := '3299180030'
		ElseIf SE5->E5_FILIAL $ _cFil30
			_xRetorno := '3299060030'
		ElseIf SE5->E5_FILIAL $ _cFil40
			_xRetorno := '3299140030'
		ElseIf SE5->E5_FILIAL $ _cFil93
			_xRetorno := '3299200030'
		EndIf

	//Recup. Custos / Falta de Leite
	ElseIf _cCod == '531004CD' .And. AllTrim(SE5->E5_NATUREZ) $ '112206/222040/222042/222043/222045' 
		If SE5->E5_FILIAL $ _cFil01+_cFil05
			_xRetorno := '3299020015'
		ElseIf SE5->E5_FILIAL $ _cFil10
			_xRetorno := '3299040015'
		ElseIf SE5->E5_FILIAL $ _cFil20
			_xRetorno := '3299080015'
		ElseIf SE5->E5_FILIAL $ _cFil23
			_xRetorno := '3299180015'
		ElseIf SE5->E5_FILIAL $ _cFil30
			_xRetorno := '3299060015'
		ElseIf SE5->E5_FILIAL $ _cFil40
			_xRetorno := '3299140015'
		ElseIf SE5->E5_FILIAL == '90'
			_xRetorno := '3299160015'
		ElseIf SE5->E5_FILIAL $ '91/92'
			_xRetorno := '3301020017'
		ElseIf SE5->E5_FILIAL $ _cFil93
			_xRetorno := '3299200015'
		EndIf	

	//Seguros Transportador
	ElseIf _cCod == '530004CC' .And. AllTrim(SE5->E5_NATUREZ) == '112006' 
		_xRetorno := '3301020049'

	//Penalização Transportador
	ElseIf AllTrim(SE5->E5_NATUREZ) $ '112021/112010'
		_xRetorno := '3301010022'
	EndIf
	
//=================================================================
//513001CD - Inclusão Pagamento Antecipado - PA - Conta Debito
//514001CC - Cancelamento Pagamento Antecipado - PA - Conta Credito
//=================================================================
ElseIf _cCod $ '513001CD/514001CC'
	If SE2->E2_FORNECE == 'F00010'
		_xRetorno := '1102110001'
	ElseIf SE2->E2_FORNECE == 'F03257'
		_xRetorno := '1102110002'
	ElseIf SE2->E2_FORNECE == 'F01890'
		_xRetorno := '1102110003'
	ElseIf SE2->E2_FORNECE == 'F03988'
		_xRetorno := '1102110004'
	ElseIf SE2->E2_FORNECE == 'L00021'
		_xRetorno := '1102110005'
	ElseIf SE2->E2_FORNECE == 'L00010'
		_xRetorno := '1102110007'
	ElseIf SE2->E2_FORNECE == 'F00918'
		_xRetorno := '1102110010'
	ElseIf SE2->E2_FORNECE == 'F01013'
		_xRetorno := '1102110011'
	ElseIf SE2->E2_FORNECE == 'F00756'
		_xRetorno := '1102110012'
	ElseIf SE2->E2_FORNECE == 'L00029'
		_xRetorno := '1102110014'
	ElseIf SE2->E2_FORNECE == 'L00024'
		_xRetorno := '1102110015'
	ElseIf SE2->E2_FORNECE == 'L00004'
		_xRetorno := '1102110016'
	ElseIf SE2->E2_FORNECE == 'L00020'
		_xRetorno := '1102110017'
	ElseIf SE2->E2_FORNECE == 'F00943'
		_xRetorno := '1102110018'
	ElseIf SE2->E2_FORNECE == 'F01123'
		_xRetorno := '1102110019'
	ElseIf SE2->E2_FORNECE == 'F01662'
		_xRetorno := '1102110020'
	ElseIf SE2->E2_FORNECE == 'T01180'
		_xRetorno := '1102110022'
	ElseIf SE2->E2_FORNECE == 'F09136'
		_xRetorno := '1102110024'
	ElseIf SE2->E2_FORNECE == 'P34160'
		_xRetorno := '1102110025'
	ElseIf SE2->E2_FORNECE == 'L00020'
		_xRetorno := '1102110026'
	ElseIf SE2->E2_FORNECE == 'F00196'
		_xRetorno := '1102110027'
	ElseIf SE2->E2_FORNECE == 'F00798'
		_xRetorno := '1102110028'
	ElseIf SE2->E2_FORNECE == 'F00210'
		_xRetorno := '1102110030'
	ElseIf SE2->E2_FORNECE == 'F07899'
		_xRetorno := '1102110033'
	ElseIf SE2->E2_FORNECE == 'F04856'
		_xRetorno := '1102110034'
	ElseIf SE2->E2_FORNECE == 'T00398'
		_xRetorno := '1102110037'
	ElseIf SE2->E2_FORNECE == 'L00014'
		_xRetorno := '1102110038'
	ElseIf SE2->E2_FORNECE == 'L00018'
		_xRetorno := '1102110043'
	ElseIf SE2->E2_FORNECE == 'F00026'
		_xRetorno := '1102110044'
	ElseIf SE2->E2_FORNECE == 'T00584'
		_xRetorno := '1102110045'
	ElseIf SE2->E2_FORNECE == 'F02821'
		_xRetorno := '1102110048'
	ElseIf SE2->E2_FORNECE == 'T00021'
		_xRetorno := '1102110049'
	ElseIf SE2->E2_FORNECE == 'F00277'
		_xRetorno := '1102110056'
	ElseIf SE2->E2_FORNECE == 'F00280'
		_xRetorno := '1102110061'
	ElseIf SE2->E2_FORNECE == 'L00016'
		_xRetorno := '1102110062'
	ElseIf SE2->E2_FORNECE == 'L00008'
		_xRetorno := '1102110065'
	ElseIf SE2->E2_FORNECE == 'F00335'
		_xRetorno := '1102110067'
	ElseIf SE2->E2_FORNECE == 'L00056'
		_xRetorno := '1102110068'
	ElseIf SE2->E2_FORNECE == 'F01023'
		_xRetorno := '1102110069'
	ElseIf SE2->E2_FORNECE == 'L00135'
		_xRetorno := '1102110070'
	ElseIf SE2->E2_FORNECE == 'F02631'
		_xRetorno := '1102110072'
	ElseIf SE2->E2_FORNECE == 'F02575'
		_xRetorno := '1102110073'
	ElseIf SE2->E2_FORNECE == 'F00737'
		_xRetorno := '1102110074'
	ElseIf SE2->E2_FORNECE == 'P13989'
		_xRetorno := '1102110075'
	ElseIf SE2->E2_FORNECE == 'P13951'
		_xRetorno := '1102110076'
	ElseIf SE2->E2_FORNECE == 'F01591'
		_xRetorno := '1102110077'
	ElseIf SE2->E2_FORNECE == 'L00031'
		_xRetorno := '1102110078'
	ElseIf SE2->E2_FORNECE == 'L00070'
		_xRetorno := '1102110079'
	ElseIf SE2->E2_FORNECE == 'L00022'
		_xRetorno := '1102110080'
	ElseIf SE2->E2_FORNECE == 'L00063'
		_xRetorno := '1102110081'
	ElseIf SE2->E2_FORNECE == 'F00815'
		_xRetorno := '1102110082'
	ElseIf SE2->E2_FORNECE == 'F00520'
		_xRetorno := '1102110083'
	ElseIf SE2->E2_FORNECE == 'F00698'
		_xRetorno := '1102110084'
	ElseIf SE2->E2_FORNECE == 'F02094'
		_xRetorno := '1102110085'
	ElseIf SE2->E2_FORNECE == 'F00721'
		_xRetorno := '1102110086'
	ElseIf SE2->E2_FORNECE == 'F02740'
		_xRetorno := '3301010006'
	ElseIf SE2->E2_FORNECE == 'F15053'
		_xRetorno := '1102110088'
	ElseIf SE2->E2_FORNECE == 'F00004'
		_xRetorno := '1102110089'
	ElseIf AllTrim(SE2->E2_NATUREZ) == '341002'
		_xRetorno := '1102180008'
	ElseIf AllTrim(SE2->E2_NATUREZ) == '341005'
		_xRetorno := '1102180011'
	Else
		_xRetorno := '1102119999'
    EndIf

//=============================================================
//597001CC - Compesação Contas a Pagar - PA/NDF - Conta Credito
//597002CC - Compesação Contas a Pagar - Juros Multa - Conta Credito
//589001CD - Cancelamento Compesação Contas a Pagar - PA/NDF - Conta Débito
//589002CD - Cancelamento Compesação Contas a Pagar - Juros Multa - Conta Débito
//=============================================================
ElseIf _cCod $ '597001CC/597002CC/589001CD/589002CD'

	//MPRIMESP-19787 - Compensação passou a ser posicionada sempre na NF e não mais
	//no registro que originou a compensação, que podia ser a NF ou PA
	BeginSql alias _cAlias
		SELECT E5_CLIFOR, E5_NATUREZ, ED_CREDIT, ED_DEBITO
		FROM %Table:SE5% SE5, %Table:SED% SED
		WHERE SE5.D_E_L_E_T_ = ' '
			AND SED.D_E_L_E_T_ = ' '
			AND SE5.E5_FILIAL = %exp:SE5->E5_FILIAL%
			AND SED.ED_FILIAL = %xFilial:SED%
			AND SED.ED_CODIGO = SE5.E5_NATUREZ
			AND SE5.E5_PREFIXO = %exp:SubStr(SE5->E5_DOCUMEN,1,3)%
			AND SE5.E5_NUMERO = %exp:SubStr(SE5->E5_DOCUMEN,4,9)%
			AND SE5.E5_PARCELA = %exp:SubStr(SE5->E5_DOCUMEN,13,2)%
			AND SE5.E5_TIPO = %exp:SubStr(SE5->E5_DOCUMEN,15,3)%
			AND SE5.E5_CLIFOR = %exp:SubStr(SE5->E5_DOCUMEN,18,6)%
			AND SE5.E5_LOJA = %exp:SubStr(SE5->E5_DOCUMEN,24,4)%
			AND SE5.E5_SEQ = %exp:SE5->E5_SEQ%
	EndSql

	If (_cAlias)->E5_CLIFOR == 'F00010'
		_xRetorno := '1102110001'
	ElseIf (_cAlias)->E5_CLIFOR == 'F03257'
		_xRetorno := '1102110002'
	ElseIf (_cAlias)->E5_CLIFOR == 'F01890'
		_xRetorno := '1102110003'
	ElseIf (_cAlias)->E5_CLIFOR == 'F03988'
		_xRetorno := '1102110004'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00021'
		_xRetorno := '1102110005'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00010'
		_xRetorno := '1102110007'
	ElseIf (_cAlias)->E5_CLIFOR == 'F00918'
		_xRetorno := '1101020010'
	ElseIf (_cAlias)->E5_CLIFOR == 'F01013'
		_xRetorno := '1102110011'
	ElseIf (_cAlias)->E5_CLIFOR == 'F00756'
		_xRetorno := '1102110012'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00029'
		_xRetorno := '1102110014'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00024'
		_xRetorno := '1102110015'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00004'
		_xRetorno := '1102110016'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00020'
		_xRetorno := '1102110017'
	ElseIf (_cAlias)->E5_CLIFOR == 'F00943'
		_xRetorno := '1102110018'
	ElseIf (_cAlias)->E5_CLIFOR == 'F01123'
		_xRetorno := '1102110019'
	ElseIf (_cAlias)->E5_CLIFOR == 'F01662'
		_xRetorno := '1102110020'
	ElseIf (_cAlias)->E5_CLIFOR == 'T01180'
		_xRetorno := '1102110022'
	ElseIf (_cAlias)->E5_CLIFOR == 'F09136'
		_xRetorno := '1102110024'
	ElseIf (_cAlias)->E5_CLIFOR == 'P34160'
		_xRetorno := '1102110025'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00020'
		_xRetorno := '1102110026'
	ElseIf (_cAlias)->E5_CLIFOR == 'F00196'
		_xRetorno := '1102110027'
	ElseIf (_cAlias)->E5_CLIFOR == 'F00798'
		_xRetorno := '1102110028'
	ElseIf (_cAlias)->E5_CLIFOR == 'F00210'
		_xRetorno := '1102110030'
	ElseIf (_cAlias)->E5_CLIFOR == 'F07899'
		_xRetorno := '1102110033'
	ElseIf (_cAlias)->E5_CLIFOR == 'F04856'
		_xRetorno := '1102110034'
	ElseIf (_cAlias)->E5_CLIFOR == 'T00398'
		_xRetorno := '1102110037'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00014'
		_xRetorno := '1102110038'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00018'
		_xRetorno := '1102110043'
	ElseIf (_cAlias)->E5_CLIFOR == 'F00026'
		_xRetorno := '1102110044'
	ElseIf (_cAlias)->E5_CLIFOR == 'T00584'
		_xRetorno := '1102110045'
	ElseIf (_cAlias)->E5_CLIFOR == 'F02821'
		_xRetorno := '1102110048'
	ElseIf (_cAlias)->E5_CLIFOR == 'T00021'
		_xRetorno := '1102110049'
	ElseIf (_cAlias)->E5_CLIFOR == 'F00277'
		_xRetorno := '1102110056'
	ElseIf (_cAlias)->E5_CLIFOR == 'F00280'
		_xRetorno := '1102110061'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00016'
		_xRetorno := '1102110062'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00008'
		_xRetorno := '1102110065'
	ElseIf (_cAlias)->E5_CLIFOR == 'F00335'
		_xRetorno := '1102110067'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00056'
		_xRetorno := '1102110068'
	ElseIf (_cAlias)->E5_CLIFOR == 'F01023'
		_xRetorno := '1102110069'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00135'
		_xRetorno := '1102110070'
	ElseIf (_cAlias)->E5_CLIFOR == 'F02631'
		_xRetorno := '1102110072'
	ElseIf (_cAlias)->E5_CLIFOR == 'F02575'
		_xRetorno := '1102110073'
	ElseIf (_cAlias)->E5_CLIFOR == 'F00737'
		_xRetorno := '1102110074'
	ElseIf (_cAlias)->E5_CLIFOR == 'P13989'
		_xRetorno := '1102110075'
	ElseIf (_cAlias)->E5_CLIFOR == 'P13951'
		_xRetorno := '1102110076'
	ElseIf (_cAlias)->E5_CLIFOR == 'F01591'
		_xRetorno := '1102110077'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00031'
		_xRetorno := '1102110078'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00070'
		_xRetorno := '1102110079'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00022'
		_xRetorno := '1102110080'
	ElseIf (_cAlias)->E5_CLIFOR == 'L00063'
		_xRetorno := '1102110081'
	ElseIf (_cAlias)->E5_CLIFOR == 'F00815'
		_xRetorno := '1102110082'
	ElseIf (_cAlias)->E5_CLIFOR == 'F00520'
		_xRetorno := '1102110083'
	ElseIf (_cAlias)->E5_CLIFOR == 'F00698'
		_xRetorno := '1102110084'
	ElseIf (_cAlias)->E5_CLIFOR == 'F02094'
		_xRetorno := '1102110085'
	ElseIf (_cAlias)->E5_CLIFOR == 'F00721'
		_xRetorno := '1102110086'
	ElseIf _cCod $ '597001CC/597002CC' .And. AllTrim((_cAlias)->E5_NATUREZ) $ '341002/341005/112006/112020'
		_xRetorno := (_cAlias)->ED_CREDIT
	ElseIf _cCod $ '589001CD/589002CD' .And. AllTrim((_cAlias)->E5_NATUREZ) $ '341002/341005/112006/112020'
		_xRetorno := (_cAlias)->ED_DEBITO

	//Adiantamentos
	ElseIf AllTrim((_cAlias)->E5_NATUREZ) == '222003' 
		If _cCod $ '597002CC'
			_xRetorno := '3401010001'
		Else
			If SE2->E2_FILIAL $ _cFil01+_cFil05
				_xRetorno := '1102040001'
			ElseIf SE2->E2_FILIAL $ _cFil10
				_xRetorno := '1102040009'
			ElseIf SE2->E2_FILIAL $ _cFil20+_cFil23
				_xRetorno := '1102040017'
			ElseIf SE2->E2_FILIAL $ _cFil30
				_xRetorno := '1102040015'
			ElseIf SE2->E2_FILIAL $ _cFil40
				_xRetorno := '1102040018'
			ElseIf SE2->E2_FILIAL $ _cFil93
				_xRetorno := '1102040019'
			EndIf
		EndIf
		
	ElseIf AllTrim((_cAlias)->E5_NATUREZ) == '222040'
		If _cCod $ '597001CC/597002CC'
			If SE5->E5_FILIAL $ _cFil01
				_xRetorno := '3299020030'
			ElseIf SE5->E5_FILIAL $ _cFil10
				_xRetorno := '3299040030'
			ElseIf SE5->E5_FILIAL $ _cFil20
				_xRetorno := '3299080030'
			ElseIf SE5->E5_FILIAL $ _cFil23
				_xRetorno := '3299180030'
			ElseIf SE5->E5_FILIAL $ _cFil30
				_xRetorno := '3299060030'
			ElseIf SE5->E5_FILIAL $ _cFil40
				_xRetorno := '3299140030'
			ElseIf SE5->E5_FILIAL $ '90/91/92'
				_xRetorno := '3301020049'
			ElseIf SE5->E5_FILIAL $ _cFil93
				_xRetorno := '3299200030'
			EndIf
		ElseIf _cCod $ '589001CD/589002CD'
			If SE5->E5_FILIAL $ _cFil01+_cFil05
				_xRetorno := '3299020015'
			ElseIf SE5->E5_FILIAL $ _cFil10
				_xRetorno := '3299040015'
			ElseIf SE5->E5_FILIAL $ _cFil20
				_xRetorno := '3299080015'
			ElseIf SE5->E5_FILIAL $ _cFil23
				_xRetorno := '3299180015'
			ElseIf SE5->E5_FILIAL $ _cFil30
				_xRetorno := '3299060015'
			ElseIf SE5->E5_FILIAL $ _cFil40
				_xRetorno := '3299140015'
			ElseIf SE5->E5_FILIAL == '90'
				_xRetorno := '3299160015'
			ElseIf SE5->E5_FILIAL $ '91/92'
				_xRetorno := '3301020017'
			ElseIf SE5->E5_FILIAL $ _cFil93
				_xRetorno := '3299200015'
			EndIf
		EndIf

	ElseIf AllTrim((_cAlias)->E5_NATUREZ) == '112021' 
		If _cCod $ '597001CC/597002CC'
			_xRetorno := '3301010022'
		Else
			_xRetorno := '3301010011'
		EndIf
	Else
		_xRetorno := '1102119999'
    EndIf
	(_cAlias)->(DBCloseArea())

//=================================================
//590001CC - Geração de Cheque - Conta Credito
//=================================================
ElseIf _cCod == '590001CC'
	If AllTrim(SA6->A6_CONTA) == '1101020001'
		_xRetorno := '1101050001'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020002'
		_xRetorno := '1101050002'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020003'
		_xRetorno := '1101050003'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020004'
		_xRetorno := '1101050004'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020005'
		_xRetorno := '1101050005'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020006'
		_xRetorno := '1101050006'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020008'
		_xRetorno := '1101050008'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020011'
		_xRetorno := '1101050011'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020013'
		_xRetorno := '1101050024'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020014'
		_xRetorno := '1101050014'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020018'
		_xRetorno := '1101050018'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020019'
		_xRetorno := '1101050019'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020020'
		_xRetorno := '1101050020'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020021'
		_xRetorno := '1101050021'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020022'
		_xRetorno := '1101050022'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020023'
		_xRetorno := '1101050023'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020025'
		_xRetorno := '1101050025'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020026'
		_xRetorno := '1101050026'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020027'
		_xRetorno := '1101050027'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020029'
		_xRetorno := '1101050029'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020043'
		_xRetorno := '1101050043'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020044'
		_xRetorno := '1101050044'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020048'
		_xRetorno := '1101050048'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020049'
		_xRetorno := '1101050049'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020050'
		_xRetorno := '1101050050'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020051'
		_xRetorno := '1101050051'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020052'
		_xRetorno := '1101050052'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020053'
		_xRetorno := '1101050053'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020054'
		_xRetorno := '1101050057'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020058'
		_xRetorno := '1101050058'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020059'
		_xRetorno := '1101050059'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020100'
		_xRetorno := '1101050100'
	ElseIf AllTrim(SA6->A6_CONTA) == '1101020070'
		_xRetorno := '1101050060'
    EndIf

//===================================================
//597001CD - Compesação Contas a Pagar - Conta Debito
//597001ID - Compesação Contas a Pagar - Item Debito 
//589001CC - Cancelamento Compesação Contas a Pagar - Conta Credito
//===================================================
ElseIf _cCod $ '597001CD/597001ID/589001CC'
	//MPRIMESP-19787 - Compensação passou a ser posicionada sempre na NF e não mais
	//no registro que originou a compensação, que podia ser a NF ou PA
	If AllTrim(SE2->E2_NATUREZ) == '221004'
		If SE2->E2_FILIAL $ '01/02/03/05/06/07/08/09/0A/0B'
			_xRetorno := '1102030001'
		ElseIf SE2->E2_FILIAL == '04'
			_xRetorno := '1102030002'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '1102030008'
		ElseIf SE2->E2_FILIAL $ _cFil20+_cFil23
			_xRetorno := '1102030026'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '1102030020'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '1102030028'
		ElseIf SE2->E2_FILIAL $ '90/92'
			_xRetorno := '1102030021'
		ElseIf SE2->E2_FILIAL == '91'
			_xRetorno := '1102030027'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '1102030035'
		EndIf
	
	//Nota de Debito Tetra Pak
	ElseIf AllTrim(SE2->E2_NATUREZ) == '222069'
		If SE2->E2_FILIAL $ _cFil01+_cFil05
			_xRetorno := '3299020010'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '3299040010'
		ElseIf SE2->E2_FILIAL $ _cFil20
			_xRetorno := '3299080010'
		ElseIf SE2->E2_FILIAL $ _cFil23
			_xRetorno := '3299180010'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '3299140010'
		ElseIf SE2->E2_FILIAL == '90'
			_xRetorno := '3299160010'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '3299200010'
		EndIf

	//Bonificações Produtores
	ElseIf AllTrim(SE2->E2_NATUREZ) == '222052'
		If SE2->E2_FILIAL $ _cFil01+_cFil05
			_xRetorno := '3299010043'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '3299030026'
		ElseIf SE2->E2_FILIAL $ _cFil20
			_xRetorno := '3299080044'
		ElseIf SE2->E2_FILIAL $ _cFil23
			_xRetorno := '3299170043'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '3299130043'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '3299190043'
		EndIf        

	//Adiantamento produtores
	ElseIf AllTrim(SE2->E2_NATUREZ) == '222003'
		_xRetorno := SA2->A2_CONTA

	//Fretes e Carretos - trecho existe 2 vezes
	ElseIf _cCod == '597001CD' .And. AllTrim(SE2->E2_NATUREZ) $ '222037'
		If SE2->E2_FILIAL $ _cFil01+_cFil05
			_xRetorno := '3299020015'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '3299040015'
		ElseIf SE2->E2_FILIAL $ _cFil20
			_xRetorno := '3299080015'
		ElseIf SE2->E2_FILIAL $ _cFil23
			_xRetorno := '3299180015'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '3299060015'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '3299140015'
		ElseIf SE2->E2_FILIAL == '90'
			_xRetorno := '3299160015'
		ElseIf SE2->E2_FILIAL $ '91/92'
			_xRetorno := '3301020017'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '3299200015'
		EndIf
		
	//Inclusão manual e gerados pelo RPA avulso e sob cargas, adiantamento fretes autonomos
	ElseIf AllTrim(SE2->E2_ORIGEM) $ 'FINA050/AOMS042/GERAZZ3' .Or. AllTrim(SE2->E2_NATUREZ) == '231010'
		If _cCod == '597001CD'
			_xRetorno := SED->ED_DEBITO
		ElseIf _cCod == '589001CC'
			_xRetorno := SED->ED_CREDIT
		EndIf
	Else
		If SubStr(SA2->A2_CONTA,1,6) $ '210105/210106'
			_xRetorno := SA2->A2_CONTA
		Else
			_xRetorno := "210101D001"
		EndIf
		_cItem	  := "SA2"+ SA2->A2_COD
	EndIf

//===================================================================
//597001VL - Compesação Contas a Pagar - Valor
//589001VL - Cancelamento Compesação Contas a Pagar - Valor
//597002VL - Compesação Contas a Pagar Juros Multa - Valor
//589002VL - Cancelamento Compesação Contas a Pagar Juros Multa - Valor
//597003VL - Compesação Contas a Pagar Desconto - Valor
//589003VL - Cancelamento Compesação Contas a Pagar Desconto - Valor
//589HIST - Cancelamento Compesação Contas a Pagar - Histórico
//597HIST - Compesação Contas a Pagar - Histórico
//===================================================================
ElseIf _cCod $ '597001VL/589001VL/597002VL/589002VL/597003VL/589003VL/589HIST/597HIST'
	//MPRIMESP-19787 - Compensação passou a ser posicionada sempre na NF e não mais
	//no registro que originou a compensação, que podia ser a NF ou PA
	BeginSql alias _cAlias
		SELECT E5_NUMERO, E5_TIPO, E5_NATUREZ, E5_CLIFOR, A2_NOME, E5_VLJUROS, E5_VLMULTA, E5_VLDESCO
		FROM %Table:SE5% SE5, %Table:SE2% SE2, %Table:SA2% SA2, %Table:SED% SED
		WHERE SE5.D_E_L_E_T_ = ' '
			AND SE2.D_E_L_E_T_ = ' '
			AND SA2.D_E_L_E_T_ = ' '
			AND SED.D_E_L_E_T_ = ' '
			AND SE5.E5_FILIAL = %exp:SE5->E5_FILIAL%
			AND SED.ED_FILIAL = %xFilial:SED%
			AND SA2.A2_FILIAL = %xFilial:SA2%
			AND SE5.E5_PREFIXO = %exp:SubStr(SE5->E5_DOCUMEN,1,3)%
			AND SE5.E5_NUMERO = %exp:SubStr(SE5->E5_DOCUMEN,4,9)%
			AND SE5.E5_PARCELA = %exp:SubStr(SE5->E5_DOCUMEN,13,2)%
			AND SE5.E5_TIPO = %exp:SubStr(SE5->E5_DOCUMEN,15,3)%
			AND SE5.E5_CLIFOR = %exp:SubStr(SE5->E5_DOCUMEN,18,6)%
			AND SE5.E5_LOJA = %exp:SubStr(SE5->E5_DOCUMEN,24,4)%
			AND SE5.E5_SEQ = %exp:SE5->E5_SEQ%
			AND SE2.E2_FILIAL = SE5.E5_FILORIG
			AND SE2.E2_NATUREZ = SED.ED_CODIGO
			AND SE2.E2_PREFIXO = SE5.E5_PREFIXO
			AND SE2.E2_NUM = SE5.E5_NUMERO
			AND SE2.E2_PARCELA = SE5.E5_PARCELA
			AND SE2.E2_TIPO = SE5.E5_TIPO
			AND SE2.E2_FORNECE = SE5.E5_CLIFOR
			AND SE2.E2_LOJA = SE5.E5_LOJA
			AND SA2.A2_COD = SE5.E5_FORNECE
			AND SA2.A2_LOJA = SE5.E5_LOJA
	EndSql
	If _cCod $ '597001VL/589001VL/597002VL/589002VL/597003VL/589003VL'
		If (_cAlias)->E5_TIPO=="PA " .Or.((_cAlias)->E5_TIPO == "NDF" .And. !AllTrim((_cAlias)->E5_NATUREZ)$"420001/420002")
			If _cCod $ '597001VL/589001VL'
				_xRetorno := SE5->(E5_VALOR)-((_cAlias)->(E5_VLJUROS+E5_VLMULTA))
			ElseIf _cCod $ '597002VL/589002VL'
				_xRetorno := (_cAlias)->(E5_VLJUROS+E5_VLMULTA)
			ElseIf _cCod $ '597003VL/589003VL'
				_xRetorno := (_cAlias)->E5_VLDESCO
			EndIf
		EndIf
	ElseIf _cCod $ '589HIST/597HIST'
		_xRetorno := (_cAlias)->E5_NUMERO + " " + (_cAlias)->E5_CLIFOR + " " + (_cAlias)->A2_NOME
    EndIf
    (_cAlias)->(DBCloseArea())

//===================================================
//596001CD - Compesação Contas a Receber - Conta Débito
//588001CC - Estorno Compesação Contas a Receber - Conta Credito
//===================================================
ElseIf _cCod $ '596001CD/588001CC'

	BeginSql alias _cAlias
		SELECT SE5.E5_NATUREZ
		FROM %Table:SE5% SE5
		WHERE SE5.D_E_L_E_T_ = ' '
			AND SE5.E5_FILIAL = %exp:SE5->E5_FILIAL%
			AND SE5.E5_PREFIXO = %exp:SubStr(SE5->E5_DOCUMEN,1,3)%
			AND SE5.E5_NUMERO = %exp:SubStr(SE5->E5_DOCUMEN,4,9)%
			AND SE5.E5_PARCELA = %exp:SubStr(SE5->E5_DOCUMEN,13,2)%
			AND SE5.E5_TIPO = %exp:SubStr(SE5->E5_DOCUMEN,15,3)%
			AND SE5.E5_CLIFOR = %exp:SE5->E5_FORNADT%
			AND SE5.E5_LOJA = %exp:SE5->E5_LOJAADT%
			AND SE5.E5_SEQ = %exp:SE5->E5_SEQ%
	EndSql
	
	_cNaturez:=AllTrim(IIf(Empty((_cAlias)->E5_NATUREZ),SE1->E1_NATUREZ,(_cAlias)->E5_NATUREZ))
	
	If SubStr(SE5->E5_DOCUMEN,15,3) $ "NDC/NCC/NF " .And. SE5->E5_TIPO $ "NDC/NCC/NF " .And. (_cNaturez $'410001' .Or. AllTrim(SE5->E5_NATUREZ)$'410001')
		_xRetorno := "1102100004"
	ElseIf SubStr(SE5->E5_DOCUMEN,15,3) $ "NDC/NCC/NF " .And. SE5->E5_TIPO $ "NDC/NCC/NF " .And. (_cNaturez $'231002/111001/231009/231018/231019' .And. AllTrim(SE5->E5_NATUREZ)$'231002/111001/231009/231018/231019')
		_xRetorno := IIf(_cCod == '596001CD',"3301010012","3301010022")
	ElseIf SubStr(SE5->E5_DOCUMEN,15,3) $ "NDC/NCC/NF " .And. SE5->E5_TIPO $ "NDC/NCC/NF " .And. (_cNaturez $'231025/111001/231026/231027' .And. AllTrim(SE5->E5_NATUREZ)$'231025/111001/231026/231027')
		_xRetorno := IIf(_cCod == '596001CD',"3301010019","3301010022")
	ElseIf SubStr(SE5->E5_DOCUMEN,15,3) $ "NDC/NCC/NF " .And. SE5->E5_TIPO $ "NDC/NCC/NF " .And. (_cNaturez $'231015/111001' .And. AllTrim(SE5->E5_NATUREZ)$'231015/111001')
		_xRetorno := IIf(_cCod == '596001CD',"3401020011","3401020010")  
	Else		
		_xRetorno := "2101119999"
	EndIf
	(_cAlias)->(DBCloseArea())
	
//===================================================
//596001CC - Compesação Contas a Receber - Conta Crédito
//588001CD - Estorno Compesação Contas a Receber - Conta Débito
//===================================================
ElseIf _cCod $ '596001CC/588001CD'

	BeginSql alias _cAlias
		SELECT SE5.E5_NATUREZ, SA1.A1_CONTA
		FROM %Table:SE5% SE5, %Table:SA1% SA1
		WHERE SE5.D_E_L_E_T_ = ' '
			AND SA1.D_E_L_E_T_ = ' '
			AND SA1.A1_FILIAL = %xFilial:SA1%
			AND SE5.E5_FILIAL = %exp:SE5->E5_FILIAL%
			AND SE5.E5_PREFIXO = %exp:SubStr(SE5->E5_DOCUMEN,1,3)%
			AND SE5.E5_NUMERO = %exp:SubStr(SE5->E5_DOCUMEN,4,9)%
			AND SE5.E5_PARCELA = %exp:SubStr(SE5->E5_DOCUMEN,13,2)%
			AND SE5.E5_TIPO = %exp:SubStr(SE5->E5_DOCUMEN,15,3)%
			AND SE5.E5_CLIFOR = %exp:SE5->E5_FORNADT%
			AND SE5.E5_LOJA = %exp:SE5->E5_LOJAADT%
			AND SE5.E5_SEQ = %exp:SE5->E5_SEQ%
			AND SE5.E5_CLIFOR = SA1.A1_COD
			AND SE5.E5_LOJA = SA1.A1_LOJA
	EndSql
	
	_cNaturez:=AllTrim(IIf(Empty((_cAlias)->E5_NATUREZ),SE1->E1_NATUREZ,(_cAlias)->E5_NATUREZ))
	
	If SubStr(SE5->E5_DOCUMEN,15,3) $ "NDC" .And. AllTrim(SE5->E5_NATUREZ)$'112012'
		_xRetorno := SED->ED_CREDIT
	ElseIf (SubStr(SE5->E5_DOCUMEN,15,3) $ "NDC/NCC" .And. SE5->E5_TIPO $ "NDC/NCC" .And. (_cNaturez $'410001' .And. AllTrim(SE5->E5_NATUREZ)$'410001'));
		.Or. (SE5->E5_TIPO == 'NCC' .And. !(SE5->E5_PREFIXO=='DCT') .And. AllTrim(SE5->E5_NATUREZ) == '410001' .And. SubStr(SE5->E5_DOCUMEN,15,3) == 'NDC' .And. SubStr(SE5->E5_DOCUMEN,1,3)=='DCI' .And. _cNaturez == '231002');
		.Or. (SubStr(SE5->E5_DOCUMEN,15,3) == 'NCC' .And. !(SubStr(SE5->E5_DOCUMEN,1,3)=='DCT') .And. _cNaturez == '410001' .And. SE5->E5_TIPO == 'NDC' .And. SE5->E5_PREFIXO=='DCI' .And. AllTrim(SE5->E5_NATUREZ) == '231002');
		.Or. (SE5->E5_TIPO == 'RA ' .And. !(SE5->E5_PREFIXO=='DCT') .And. AllTrim(SE5->E5_NATUREZ) == '111001' .And. SubStr(SE5->E5_DOCUMEN,15,3) == 'NDC' .And. SubStr(SE5->E5_DOCUMEN,1,3)=='DCI' .And. _cNaturez == '231002')
		_xRetorno := IIf(_cCod == '596001CC',"3401010002","3401020011")
	ElseIf SubStr(SE5->E5_DOCUMEN,15,3) $ "NDC/NCC" .And. SE5->E5_TIPO $ "NDC/NCC" .And. (_cNaturez $'410001/231002' .And. AllTrim(SE5->E5_NATUREZ)$'410001/231002')
		_xRetorno := IIf(_cCod == '596001CC',"3301010022","3401020011")
	ElseIf SubStr(SE5->E5_DOCUMEN,15,3) $ "NDC/RA" .And. SE5->E5_TIPO $ "NDC/RA " .And. (_cNaturez $'112015/121001' .And. AllTrim(SE5->E5_NATUREZ)$'112015/121001')
		_xRetorno := IIf(_cCod == '596001CC',"3401010001","3401020011")
	ElseIf AllTrim((_cAlias)->A1_CONTA) $ "1102069992/1102069993/1102069995/1102069996/1102069998/1102069999"
		_xRetorno := (_cAlias)->A1_CONTA
	Else
		_xRetorno := "110206G001"
	EndIf
	(_cAlias)->(DBCloseArea())
	
//===================================================
//596001VL - Compesação Contas a Receber - Valor
//588001VL - Estorno Compesação Contas a Receber - Valor
//===================================================
ElseIf _cCod $ '596001VL/588001VL'
	
	BeginSql alias _cAlias
		SELECT SE5.E5_NATUREZ
		FROM %Table:SE5% SE5
		WHERE SE5.D_E_L_E_T_ = ' '
			AND SE5.E5_FILIAL = %exp:SE5->E5_FILIAL%
			AND SE5.E5_PREFIXO = %exp:SubStr(SE5->E5_DOCUMEN,1,3)%
			AND SE5.E5_NUMERO = %exp:SubStr(SE5->E5_DOCUMEN,4,9)%
			AND SE5.E5_PARCELA = %exp:SubStr(SE5->E5_DOCUMEN,13,2)%
			AND SE5.E5_TIPO = %exp:SubStr(SE5->E5_DOCUMEN,15,3)%
			AND SE5.E5_CLIFOR = %exp:SE5->E5_FORNADT%
			AND SE5.E5_LOJA = %exp:SE5->E5_LOJAADT%
			AND SE5.E5_SEQ = %exp:SE5->E5_SEQ%
	EndSql
	
	_cNaturez:=AllTrim(IIf(Empty((_cAlias)->E5_NATUREZ),SE1->E1_NATUREZ,(_cAlias)->E5_NATUREZ))
	
	If SubStr(SE5->E5_DOCUMEN,15,3) $ "NDC/NCC" .And. SE5->E5_TIPO $ "NDC/NCC" .And. _cNaturez $ '231002' .And. AllTrim(SE5->E5_NATUREZ) $ '231002'
		_xRetorno := 0
	Else	
		_xRetorno := SE5->E5_VALOR
	EndIf

	(_cAlias)->(DBCloseArea())

//=====================================================================
//510001CC - Inclusão manual Contas a Pagar - Conta Credito
//=====================================================================
ElseIf _cCod == '510001CC'
		
	If 	AllTrim(SE2->E2_NATUREZ) == '222069' .And. SE2->E2_TIPO == 'NCF'
		_xRetorno := '210101D001'
	Else
		_xRetorno := '1102150020'
	EndIf

//=====================================================================
//510001CD - Inclusão manual Contas a Pagar - Conta Débito
//=====================================================================
ElseIf _cCod == '510001CD'
		
	If 	AllTrim(SE2->E2_NATUREZ) == '222069' .And. SE2->E2_TIPO == 'NCF'
		If SE2->E2_FILIAL $ _cFil01+_cFil05
			_xRetorno := '3299020010'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '3299040010'
		ElseIf SE2->E2_FILIAL $ _cFil20
			_xRetorno := '3299080010'
		ElseIf SE2->E2_FILIAL $ _cFil23
			_xRetorno := '3299180010'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '3299060010'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '3299140010'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '3299200010
		EndIf
	Else
		_xRetorno := '1102150018'
	EndIf

//=====================================================================
//530009CC - Baixa Contas a Pagar - Automatico - Borderos - Conta Credito
//532009CC - Baixa Contas a Pagar - Conta Debito
//531009CD - Cancelamento Baixa Contas a Pagar - Conta Débito
//=====================================================================
ElseIf _cCod $ '530009CC/532009CC/531009CD'
		
	If 	AllTrim(SE2->E2_NATUREZ) == '222040'
		If SE2->E2_FILIAL $ _cFil01+_cFil05
			_xRetorno := '3299020030'
		ElseIf SE2->E2_FILIAL $ _cFil10
			_xRetorno := '3299040030'
		ElseIf SE2->E2_FILIAL $ _cFil20
			_xRetorno := '3299080030'
		ElseIf SE2->E2_FILIAL $ _cFil23
			_xRetorno := '3299180030'
		ElseIf SE2->E2_FILIAL $ _cFil30
			_xRetorno := '3299060030'
		ElseIf SE2->E2_FILIAL $ _cFil40
			_xRetorno := '3299140030'
		ElseIf SE2->E2_FILIAL $ '90/91/92'
			_xRetorno := '3301020049'
		ElseIf SE2->E2_FILIAL $ _cFil93
			_xRetorno := '3299200030'
		EndIf
	Else
		_xRetorno := '1102119999'
	EndIf
	
//===================================================
//520001VL - Baixa Contas a Receber - Valor
//527001VL - Estorno Baixa Contas a Receber - Valor
//===================================================
ElseIf _cCod $ '520001VL/527001VL'

	If SE5->E5_MOTBX $"DAC,CMP,FAT" .Or. Empty(SE1->E1_CLIENTE)
		_xRetorno := 0
	ElseIf SE5->E5_MOTBX == "LIQ"
		BeginSql alias _cAlias
			SELECT COUNT(1) QTD
			FROM %Table:SE1% SE1
			WHERE SE1.D_E_L_E_T_ = ' '
				AND SE1.E1_FILIAL = %exp:SE5->E5_FILIAL%
				AND SE1.E1_ORIGEM = 'FINA460'
				AND SE1.E1_NUMLIQ = %exp:SE5->E5_DOCUMEN%
				AND SE1.E1_CLIENTE = %exp:SE5->E5_CLIFOR%
		EndSql
		
		If (_cAlias)->QTD > 0
			_xRetorno := 0
		Else
			_xRetorno := SE5->(E5_VALOR-E5_VLJUROS-E5_VLMULTA)
		EndIf
	
		(_cAlias)->(DBCloseArea())	
	Else
		_xRetorno :=  SE5->(E5_VALOR-E5_VLJUROS-E5_VLMULTA)
	EndIf

EndIf
//Retorna sempre uma conta genérica quando não identificar a conta correta
If Empty(_xRetorno) .And. SubStr(_cCod,7,1) $ 'IC'
	_xRetorno := "1101010020"
EndIf 

If SubStr(_cCod,7,1) == 'I'
	_xRetorno := _cItem
ElseIf 'HIST' $ _cCod
	_xRetorno := _xRetorno	
ElseIf SubStr(_cCod,7,1) == 'T'	
	_xRetorno := _cCCusto
EndIf

FWRestArea(_aAreaSE1)
FWRestArea(_aArea)

Return(_xRetorno)
