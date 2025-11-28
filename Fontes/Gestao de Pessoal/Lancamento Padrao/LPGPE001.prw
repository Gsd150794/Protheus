/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |04/10/2024| Chamado 47735. Incluídas regras para a filial 33
Lucas Borges  |16/12/2024| Chamado 49384. Ajustada variável de 13
Lucas Borges  |16/12/2024| Chamado 50398. Contas alteradas
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: LPGPE001
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 01/09/2011
Descrição---------: Regras chamadas nos LPs de contabilização do GPE
Parametros--------: cTipo: CD (Conta Débito), CC (Conta Crédito), CPD (Conta Débito)
Retorno-----------: _cRetorno = Retorna a conta
===============================================================================================================================
*/
User Function LPGPE001(_cCod)

Local _aArea	:= FWGetArea()
Local _cRetorno := ""
Local _nSaldo	:= 0
Local _lParc13	:= (Month(dDataBase) == 12 .Or. Month(dDataBase) == 11) .And. MV_PAR02 == 2 .And. SRZ->RZ_TIPO == "13"//Apenas segunda parcela do 13o
Local _cFil01	:= '01/02/03/04/05/06/07/08/09/0A/0B/' 
Local _cFil10	:= '10/11/12/13/14/15/16/17/18/19/1A/1B/1C/'
Local _cFil20	:= '20/21/22/24/25/'
Local _cFil23	:= '23/'
Local _cFil30	:= '30/31/32/33'
Local _cFil40	:= '40/'
Local _cFil93	:= '93/'
Local _cEstagio	:= '192/193/201/319' //Estágio
Local _cAjdCusto:= '297' //Diárias e Ajuda de Custo
Local _cAbonoPec:= '131/136'//Abono Pecuniário
Local _cAvisoPre:= '160/203/283/314' //Aviso Prévio
Local _cINSS	:= '747/748/749/867/868/869'//INSS
Local _cFGTS	:= '708/723'//FGTS
Local _cProvFer	:= '729/769/771/801/807'//Provisão de Férias
Local _cProv13	:= '096/382/735/770/812/813'//Provisão de Décimo Terceiro Salário
Local _cProvTerc:= '802/824'//Provisão 1/3 de Férias
Local _cRecupera:= '402/406/407/408/413/414/426/437/438/441/443/444/445/446/447/448/452/453/454/455/456/459/460/467/468/472/474/489/502/510/512/535' //Recuperações
Local _lCCGrp01	:= ""
Local _lCCGrp02	:= ""
Local _lCCGrp03	:= ""
Local _lCCGrp04	:= "10103007/11101002/13001003/20103007/21101002/23001003/31101002/33001003/40103007/41101002/43001003/50103007/51101002/51101008/60103007/61101002/61101008/70103007/73001003/80103007/81101002/83001003/90103007/91101002/93001003/B0103007"
Local _lCCGrp05 := (AllTrim(SRZ->RZ_CC) >="09000000" .And. AllTrim(SRZ->RZ_CC) <="09999999") .Or.  AllTrim(SRZ->RZ_CC) $ "10103010/20103010/30103010/40103010/70103010/80103010/90103010"

If SRZ->RZ_FILIAL $ _cFil01
	_lCCGrp01	:= _lCCGrp05.Or. (AllTrim(SRZ->RZ_CC) >="12100000" .And. AllTrim(SRZ->RZ_CC) <="13999999") .Or. (AllTrim(SRZ->RZ_CC) >="18000000" .And. AllTrim(SRZ->RZ_CC) <="18999999")
	_lCCGrp02	:= AllTrim(SRZ->RZ_CC) >="14000000" .And. AllTrim(SRZ->RZ_CC) <="14999999"
	_lCCGrp03	:= (AllTrim(SRZ->RZ_CC) >="00100000" .And. AllTrim(SRZ->RZ_CC) <="02999999") .Or. (AllTrim(SRZ->RZ_CC) >="10100000" .And. AllTrim(SRZ->RZ_CC) <="11999999");//Corporativo ou Administrativo
					.Or. (SRA->RA_CATFUNC == 'A' .Or. SRZ->RZ_MAT == 'zzzzzz')//CC dos autônomos podem ter qualquer faixa e todos são cadastrados na Matriz
ElseIf SRZ->RZ_FILIAL $ _cFil10
	_lCCGrp01	:= _lCCGrp05 .Or. (AllTrim(SRZ->RZ_CC) >="22100000" .And. AllTrim(SRZ->RZ_CC) <="23999999") .Or. (AllTrim(SRZ->RZ_CC) >="28000000" .And. AllTrim(SRZ->RZ_CC) <="28999999")
	_lCCGrp02	:= AllTrim(SRZ->RZ_CC) >="24000000" .And. AllTrim(SRZ->RZ_CC) <="24999999"
	_lCCGrp03	:= (AllTrim(SRZ->RZ_CC) >="00100000" .And. AllTrim(SRZ->RZ_CC) <="02999999") .Or. (AllTrim(SRZ->RZ_CC) >="20100000" .And. AllTrim(SRZ->RZ_CC) <="21999999")//Corporativo ou Administrativo
ElseIf SRZ->RZ_FILIAL $ _cFil20
	_lCCGrp01	:= _lCCGrp05 .Or. (AllTrim(SRZ->RZ_CC) >="42100000" .And. AllTrim(SRZ->RZ_CC) <="43999999") .Or. (AllTrim(SRZ->RZ_CC) >="48000000" .And. AllTrim(SRZ->RZ_CC) <="48999999")
	_lCCGrp02	:= AllTrim(SRZ->RZ_CC) >="44000000" .And. AllTrim(SRZ->RZ_CC) <="44999999"
	_lCCGrp03	:= (AllTrim(SRZ->RZ_CC) >="00100000" .And. AllTrim(SRZ->RZ_CC) <="02999999") .Or. (AllTrim(SRZ->RZ_CC) >="40100000" .And. AllTrim(SRZ->RZ_CC) <="41999999")//Corporativo ou Administrativo
ElseIf SRZ->RZ_FILIAL $ _cFil23
	_lCCGrp01	:= _lCCGrp05 .Or. (AllTrim(SRZ->RZ_CC) >="92100000" .And. AllTrim(SRZ->RZ_CC) <="93999999") .Or. (AllTrim(SRZ->RZ_CC) >="98000000" .And. AllTrim(SRZ->RZ_CC) <="98999999")
	_lCCGrp02	:= AllTrim(SRZ->RZ_CC) >="94000000" .And. AllTrim(SRZ->RZ_CC) <="94999999"
	_lCCGrp03	:= (AllTrim(SRZ->RZ_CC) >="00100000" .And. AllTrim(SRZ->RZ_CC) <="02999999") .Or. (AllTrim(SRZ->RZ_CC) >="90100000" .And. AllTrim(SRZ->RZ_CC) <="91999999")//Corporativo ou Administrativo
ElseIf SRZ->RZ_FILIAL $ _cFil30
	_lCCGrp01	:= _lCCGrp05 .Or. (AllTrim(SRZ->RZ_CC) >="32100000" .And. AllTrim(SRZ->RZ_CC) <="33999999") .Or. (AllTrim(SRZ->RZ_CC) >="38000000" .And. AllTrim(SRZ->RZ_CC) <="38999999")
	_lCCGrp02	:= AllTrim(SRZ->RZ_CC) >="34000000" .And. AllTrim(SRZ->RZ_CC) <="34999999"	
	_lCCGrp03	:= (AllTrim(SRZ->RZ_CC) >="00100000" .And. AllTrim(SRZ->RZ_CC) <="02999999") .Or. (AllTrim(SRZ->RZ_CC) >="30100000" .And. AllTrim(SRZ->RZ_CC) <="31999999")//Corporativo ou Administrativo
ElseIf SRZ->RZ_FILIAL $ _cFil40
	_lCCGrp01	:= _lCCGrp05 .Or. (AllTrim(SRZ->RZ_CC) >="82100000" .And. AllTrim(SRZ->RZ_CC) <="83999999") .Or. (AllTrim(SRZ->RZ_CC) >="88000000" .And. AllTrim(SRZ->RZ_CC) <="88999999")
	_lCCGrp02	:= AllTrim(SRZ->RZ_CC) >="84000000" .And. AllTrim(SRZ->RZ_CC) <="84999999"
	_lCCGrp03	:= (AllTrim(SRZ->RZ_CC) >="00100000" .And. AllTrim(SRZ->RZ_CC) <="02999999") .Or. (AllTrim(SRZ->RZ_CC) >="80100000" .And. AllTrim(SRZ->RZ_CC) <="81999999")//Corporativo ou Administrativo
ElseIf SRZ->RZ_FILIAL $ _cFil93
	_lCCGrp01	:= (AllTrim(SRZ->RZ_CC) >="A9000000" .And. AllTrim(SRZ->RZ_CC) <="A9999999") .Or. (AllTrim(SRZ->RZ_CC) >="82100000" .And. AllTrim(SRZ->RZ_CC) <="83999999") .Or. (AllTrim(SRZ->RZ_CC) >="A8000000" .And. AllTrim(SRZ->RZ_CC) <="A8999999")  .Or. AllTrim(SRZ->RZ_CC) $ "10103010/20103010/30103010/40103010/70103010/80103010/90103010"
	_lCCGrp02	:= AllTrim(SRZ->RZ_CC) >="A4000000" .And. AllTrim(SRZ->RZ_CC) <="A4999999"
	_lCCGrp03	:= (AllTrim(SRZ->RZ_CC) >="00100000" .And. AllTrim(SRZ->RZ_CC) <="02999999") .Or. (AllTrim(SRZ->RZ_CC) >="A0100000" .And. AllTrim(SRZ->RZ_CC) <="A1999999")//Corporativo ou Administrativo
EndIf

If _cCod $ "A99001CD/A97001CD/A97001CC/A96001CD/A96001CC"
	If _cCod $ "A96001CD/A96001CC"
		_nSaldo := SaldoProv()
	Else
		_nSaldo := SRZ->RZ_VAL
	EndIf
	If _cCod $ "A99001CD" .Or. (_nSaldo>0 .And. _cCod $ "A97001CD") .Or. (_nSaldo<0 .And. _cCod $ "A97001CC").Or. (_nSaldo>0 .And. _cCod $ "A96001CD").Or. (_nSaldo<0 .And. _cCod $ "A96001CC")
		If Empty(SRV->RV_DEBITO)
			If SRZ->RZ_FILIAL $ _cFil01
				If SRZ->RZ_PD $ _cEstagio
					_cRetorno := IIf(_lCCGrp01,"3299020054",IIf(_lCCGrp02,"3299010034",IIf(_lCCGrp03,"3301020074",IIf(_lCCGrp04,"3301010042",""))))
				ElseIf SRZ->RZ_PD $ _cAjdCusto
					_cRetorno := IIf(_lCCGrp01,"3299020055",IIf(_lCCGrp02,"3299010035",IIf(_lCCGrp03,"3301020075",IIf(_lCCGrp04,"3301010043",""))))
				ElseIf SRZ->RZ_PD $ _cAbonoPec
					_cRetorno := IIf(_lCCGrp01,"3299020056",IIf(_lCCGrp02,"3299010036",IIf(_lCCGrp03,"3301020076",IIf(_lCCGrp04,"3301010044",""))))
				ElseIf SRZ->RZ_PD $ _cAvisoPre
					_cRetorno := IIf(_lCCGrp01,"3299020057",IIf(_lCCGrp02,"3299010037",IIf(_lCCGrp03,"3301020077",IIf(_lCCGrp04,"3301010040",""))))
				ElseIf SRZ->RZ_PD $ _cINSS
					If _lParc13
						_cRetorno := "2101150005"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299020002",IIf(_lCCGrp02,"3299010002",IIf(_lCCGrp03,"3301020001",IIf(_lCCGrp04,"3301010035",""))))
					EndIf
				ElseIf SRZ->RZ_PD $ _cFGTS
					If _lParc13
						_cRetorno := "2101150006"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299020003",IIf(_lCCGrp02,"3299010003",IIf(_lCCGrp03,"3301020002",IIf(_lCCGrp04,"3301010036",""))))
					EndIf
				ElseIf SRZ->RZ_PD $ _cProvFer
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299020051","3299020059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299010031","3299010049"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020071","3301020089"),IIf(_lCCGrp04,"3301010037",""))))
				ElseIf SRZ->RZ_PD $ _cProv13
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299020052","3299020059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299010032","3299010049"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020072","3301020089"),IIf(_lCCGrp04,"3301010039",""))))
				ElseIf SRZ->RZ_PD $ _cProvTerc
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299020053","3299020059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299010033","3299010049"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020071","3301020089"),IIf(_lCCGrp04,"3301010038",""))))
				Else
					If _lParc13
						_cRetorno := "2101150004"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299020001",IIf(_lCCGrp02,"3299010001",IIf(_lCCGrp03,"3301020003",IIf(_lCCGrp04,"3301010034",""))))
					EndIf
				EndIf
			ElseIf SRZ->RZ_FILIAL $ _cFil10
				If SRZ->RZ_PD $ _cEstagio
					_cRetorno := IIf(_lCCGrp01,"3299040054",IIf(_lCCGrp02,"3299030034",IIf(_lCCGrp03,"3301020074",IIf(_lCCGrp04,"3301010042",""))))
				ElseIf SRZ->RZ_PD $ _cAjdCusto
					_cRetorno := IIf(_lCCGrp01,"3299040055",IIf(_lCCGrp02,"3299030035",IIf(_lCCGrp03,"3301020075",IIf(_lCCGrp04,"3301010043",""))))
				ElseIf SRZ->RZ_PD $ _cAbonoPec
					_cRetorno := IIf(_lCCGrp01,"3299040056",IIf(_lCCGrp02,"3299030036",IIf(_lCCGrp03,"3301020076",IIf(_lCCGrp04,"3301010044",""))))
				ElseIf SRZ->RZ_PD $ _cAvisoPre
					_cRetorno := IIf(_lCCGrp01,"3299040057",IIf(_lCCGrp02,"3299030037",IIf(_lCCGrp03,"3301020077",IIf(_lCCGrp04,"3301010040",""))))
				ElseIf SRZ->RZ_PD $ _cINSS
					If _lParc13
						_cRetorno := "2101150005"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299040002",IIf(_lCCGrp02,"3299030002",IIf(_lCCGrp03,"3301020001",IIf(_lCCGrp04,"3301010035",""))))
					EndIf
				ElseIf SRZ->RZ_PD $ _cFGTS
					If _lParc13
						_cRetorno := "2101150006"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299040003",IIf(_lCCGrp02,"3299030003",IIf(_lCCGrp03,"3301020002",IIf(_lCCGrp04,"3301010036",""))))
					EndIf
				ElseIf SRZ->RZ_PD $ _cProvFer
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299040051","3299040059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299030031","3299030047"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020071","3301020089"),IIf(_lCCGrp04,"3301010037",""))))
				ElseIf SRZ->RZ_PD $ _cProv13
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299040052","3299040059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299030032","3299030047"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020072","3301020089"),IIf(_lCCGrp04,"3301010039",""))))
				ElseIf SRZ->RZ_PD $ _cProvTerc
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299040053","3299040059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299030033","3299030047"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020071","3301020089"),IIf(_lCCGrp04,"3301010038",""))))
				Else
					If _lParc13
						_cRetorno := "2101150004"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299040001",IIf(_lCCGrp02,"3299030001",IIf(_lCCGrp03,"3301020003",IIf(_lCCGrp04,"3301010034",""))))
					EndIf
				EndIf
			ElseIf SRZ->RZ_FILIAL $ _cFil20
				If SRZ->RZ_PD $ _cEstagio
					_cRetorno := IIf(_lCCGrp01,"3299080054",IIf(_lCCGrp02,"3299070034",IIf(_lCCGrp03,"3301020074",IIf(_lCCGrp04,"3301010042",""))))
				ElseIf SRZ->RZ_PD $ _cAjdCusto
					_cRetorno := IIf(_lCCGrp01,"3299080055",IIf(_lCCGrp02,"3299070035",IIf(_lCCGrp03,"3301020075",IIf(_lCCGrp04,"3301010043",""))))
				ElseIf SRZ->RZ_PD $ _cAbonoPec
					_cRetorno := IIf(_lCCGrp01,"3299080056",IIf(_lCCGrp02,"3299070036",IIf(_lCCGrp03,"3301020076",IIf(_lCCGrp04,"3301010044",""))))
				ElseIf SRZ->RZ_PD $ _cAvisoPre
					_cRetorno := IIf(_lCCGrp01,"3299080057",IIf(_lCCGrp02,"3299070037",IIf(_lCCGrp03,"3301020077",IIf(_lCCGrp04,"3301010040",""))))
				ElseIf SRZ->RZ_PD $ _cINSS
					If _lParc13
						_cRetorno := "2101150005"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299080002",IIf(_lCCGrp02,"3299070002",IIf(_lCCGrp03,"3301020001",IIf(_lCCGrp04,"3301010035",""))))
					EndIf
				ElseIf SRZ->RZ_PD $ _cFGTS
					If _lParc13
						_cRetorno := "2101150006"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299080003",IIf(_lCCGrp02,"3299070003",IIf(_lCCGrp03,"3301020002",IIf(_lCCGrp04,"3301010036",""))))
					EndIf
				ElseIf SRZ->RZ_PD $ _cProvFer
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299080051","3299080060"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299070031","3299070048"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020071","3301020089"),IIf(_lCCGrp04,"3301010037",""))))
				ElseIf SRZ->RZ_PD $ _cProv13
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299080052","3299080060"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299070032","3299070048"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020072","3301020089"),IIf(_lCCGrp04,"3301010039",""))))
				ElseIf SRZ->RZ_PD $ _cProvTerc
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299080051","3299080060"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299070031","3299070048"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020071","3301020089"),IIf(_lCCGrp04,"3301010038",""))))
				Else
					If _lParc13
						_cRetorno := "2101150004"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299080001",IIf(_lCCGrp02,"3299070001",IIf(_lCCGrp03,"3301020003",IIf(_lCCGrp04,"3301010034",""))))
					EndIf
				EndIf
			ElseIf SRZ->RZ_FILIAL $ _cFil23
				If SRZ->RZ_PD $ _cEstagio
					_cRetorno := IIf(_lCCGrp01,"3299180054",IIf(_lCCGrp02,"3299170034",IIf(_lCCGrp03,"3301020074",IIf(_lCCGrp04,"3301010042",""))))
				ElseIf SRZ->RZ_PD $ _cAjdCusto
					_cRetorno := IIf(_lCCGrp01,"3299180055",IIf(_lCCGrp02,"3299170035",IIf(_lCCGrp03,"3301020075",IIf(_lCCGrp04,"3301010043",""))))
				ElseIf SRZ->RZ_PD $ _cAbonoPec
					_cRetorno := IIf(_lCCGrp01,"3299180056",IIf(_lCCGrp02,"3299170036",IIf(_lCCGrp03,"3301020076",IIf(_lCCGrp04,"3301010044",""))))
				ElseIf SRZ->RZ_PD $ _cAvisoPre
					_cRetorno := IIf(_lCCGrp01,"3299180057",IIf(_lCCGrp02,"3299170037",IIf(_lCCGrp03,"3301020077",IIf(_lCCGrp04,"3301010040",""))))
				ElseIf SRZ->RZ_PD $ _cINSS
					If _lParc13
						_cRetorno := "2101150005"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299180002",IIf(_lCCGrp02,"3299170002",IIf(_lCCGrp03,"3301020001",IIf(_lCCGrp04,"3301010035",""))))
					EndIf
				ElseIf SRZ->RZ_PD $ _cFGTS
					If _lParc13
						_cRetorno := "2101150006"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299180003",IIf(_lCCGrp02,"3299170003",IIf(_lCCGrp03,"3301020002",IIf(_lCCGrp04,"3301010036",""))))
					EndIf
				ElseIf SRZ->RZ_PD $ _cProvFer
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299180051","3299180059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299170031","3299170049"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020071","3301020089"),IIf(_lCCGrp04,"3301010037",""))))
				ElseIf SRZ->RZ_PD $ _cProv13
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299180052","3299180059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299170032","3299170049"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020072","3301020089"),IIf(_lCCGrp04,"3301010039",""))))
				ElseIf SRZ->RZ_PD $ _cProvTerc
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299180053","3299180059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299170031","3299170049"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020071","3301020089"),IIf(_lCCGrp04,"3301010038",""))))
				Else
					If _lParc13
						_cRetorno := "2101150004"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299180001",IIf(_lCCGrp02,"3299170001",IIf(_lCCGrp03,"3301020003",IIf(_lCCGrp04,"3301010034",""))))
					EndIf
				EndIf
			ElseIf SRZ->RZ_FILIAL $ _cFil30
				If SRZ->RZ_PD $ _cEstagio
					_cRetorno := IIf(_lCCGrp01,"3299060054",IIf(_lCCGrp02,"3299050034",IIf(_lCCGrp03,"3301020074",IIf(_lCCGrp04,"3301010042",""))))
				ElseIf SRZ->RZ_PD $ _cAjdCusto
					_cRetorno := IIf(_lCCGrp01,"3299060055",IIf(_lCCGrp02,"3299050035",IIf(_lCCGrp03,"3301020075",IIf(_lCCGrp04,"3301010043",""))))
				ElseIf SRZ->RZ_PD $ _cAbonoPec
					_cRetorno := IIf(_lCCGrp01,"3299060056",IIf(_lCCGrp02,"3299050036",IIf(_lCCGrp03,"3301020076",IIf(_lCCGrp04,"3301010044",""))))
				ElseIf SRZ->RZ_PD $ _cAvisoPre
					_cRetorno := IIf(_lCCGrp01,"3299060057",IIf(_lCCGrp02,"3299050037",IIf(_lCCGrp03,"3301020077",IIf(_lCCGrp04,"3301010040",""))))
				ElseIf SRZ->RZ_PD $ _cINSS
					If _lParc13
						_cRetorno := "2101150005"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299060002",IIf(_lCCGrp02,"3299050002",IIf(_lCCGrp03,"3301020001",IIf(_lCCGrp04,"3301010035",""))))
					EndIf
				ElseIf SRZ->RZ_PD $ _cFGTS
					If _lParc13
						_cRetorno := "2101150006"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299060003",IIf(_lCCGrp02,"3299050003",IIf(_lCCGrp03,"3301020002",IIf(_lCCGrp04,"3301010036",""))))
					EndIf
				ElseIf SRZ->RZ_PD $ _cProvFer
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299060051","3299050047"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299060031","3299060059"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020071","3301020089"),IIf(_lCCGrp04,"3301010037",""))))
				ElseIf SRZ->RZ_PD $ _cProv13
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299060052","3299060059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299060032","3299060059"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020072","3301020089"),IIf(_lCCGrp04,"3301010039",""))))
				ElseIf SRZ->RZ_PD $ _cProvTerc
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299060053","3299060059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299050033","3299050047"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020071","3301020089"),IIf(_lCCGrp04,"3301010038",""))))
				Else
					If _lParc13
						_cRetorno := "2101150004"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299060001",IIf(_lCCGrp02,"3299050001",IIf(_lCCGrp03,"3301020003",IIf(_lCCGrp04,"3301010034",""))))
					EndIf
				EndIf
			ElseIf SRZ->RZ_FILIAL $ _cFil40
				If SRZ->RZ_PD $ _cEstagio
					_cRetorno := IIf(_lCCGrp01,"3299140054",IIf(_lCCGrp02,"3299130034",IIf(_lCCGrp03,"3301020074",IIf(_lCCGrp04,"3301010042",""))))
				ElseIf SRZ->RZ_PD $ _cAjdCusto
					_cRetorno := IIf(_lCCGrp01,"3299140055",IIf(_lCCGrp02,"3299130035",IIf(_lCCGrp03,"3301020075",IIf(_lCCGrp04,"3301010043",""))))
				ElseIf SRZ->RZ_PD $ _cAbonoPec
					_cRetorno := IIf(_lCCGrp01,"3299140056",IIf(_lCCGrp02,"3299130036",IIf(_lCCGrp03,"3301020076",IIf(_lCCGrp04,"3301010044",""))))
				ElseIf SRZ->RZ_PD $ _cAvisoPre
					_cRetorno := IIf(_lCCGrp01,"3299140057",IIf(_lCCGrp02,"3299130037",IIf(_lCCGrp03,"3301020077",IIf(_lCCGrp04,"3301010040",""))))
				ElseIf SRZ->RZ_PD $ _cINSS
					If _lParc13
						_cRetorno := "2101150005"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299140002",IIf(_lCCGrp02,"3299130002",IIf(_lCCGrp03,"3301020001",IIf(_lCCGrp04,"3301010035",""))))
					EndIf
				ElseIf SRZ->RZ_PD $ _cFGTS
					If _lParc13
						_cRetorno := "2101150006"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299140003",IIf(_lCCGrp02,"3299130003",IIf(_lCCGrp03,"3301020002",IIf(_lCCGrp04,"3301010036",""))))
					EndIf
				ElseIf SRZ->RZ_PD $ _cProvFer
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299140051","3299140059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299130031","3299130049"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020071","3301020089"),IIf(_lCCGrp04,"3301010037",""))))
				ElseIf SRZ->RZ_PD $ _cProv13
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299140052","3299140059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299130032","3299130049"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020072","3301020089"),IIf(_lCCGrp04,"3301010039",""))))
				ElseIf SRZ->RZ_PD $ _cProvTerc
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299140051","3299140059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299130031","3299130049"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020071","3301020089"),IIf(_lCCGrp04,"3301010038",""))))
				Else
					If _lParc13
						_cRetorno := "2101150004"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299140001",IIf(_lCCGrp02,"3299130001",IIf(_lCCGrp03,"3301020003",IIf(_lCCGrp04,"3301010034",""))))
					EndIf
				EndIf
			ElseIf SRZ->RZ_FILIAL $ _cFil93
				If SRZ->RZ_PD $ _cEstagio
					_cRetorno := IIf(_lCCGrp01,"3299200054",IIf(_lCCGrp02,"3299190034",IIf(_lCCGrp03,"3301020074",IIf(_lCCGrp04,"3301010042",""))))
				ElseIf SRZ->RZ_PD $ _cAjdCusto
					_cRetorno := IIf(_lCCGrp01,"3299200055",IIf(_lCCGrp02,"3299190035",IIf(_lCCGrp03,"3301020075",IIf(_lCCGrp04,"3301010043",""))))
				ElseIf SRZ->RZ_PD $ _cAbonoPec
					_cRetorno := IIf(_lCCGrp01,"3299200056",IIf(_lCCGrp02,"3299190036",IIf(_lCCGrp03,"3301020076",IIf(_lCCGrp04,"3301010044",""))))
				ElseIf SRZ->RZ_PD $ _cAvisoPre
					_cRetorno := IIf(_lCCGrp01,"3299200057",IIf(_lCCGrp02,"3299190037",IIf(_lCCGrp03,"3301020077",IIf(_lCCGrp04,"3301010040",""))))
				ElseIf SRZ->RZ_PD $ _cINSS
					If _lParc13
						_cRetorno := "2101150005"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299200002",IIf(_lCCGrp02,"3299190002",IIf(_lCCGrp03,"3301020001",IIf(_lCCGrp04,"3301010035",""))))
					EndIf
				ElseIf SRZ->RZ_PD $ _cFGTS
					If _lParc13
						_cRetorno := "2101150006"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299200003",IIf(_lCCGrp02,"3299190003",IIf(_lCCGrp03,"3301020002",IIf(_lCCGrp04,"3301010036",""))))
					EndIf
				ElseIf SRZ->RZ_PD $ _cProvFer
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299200051","3299200059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299190031","3299190049"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020071","3301020089"),IIf(_lCCGrp04,"3301010037",""))))
				ElseIf SRZ->RZ_PD $ _cProv13
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299200052","3299200059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299190032","3299190049"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020072","3301020089"),IIf(_lCCGrp04,"3301010039",""))))
				ElseIf SRZ->RZ_PD $ _cProvTerc
					_cRetorno := IIf(_lCCGrp01,IIf(_nSaldo>0,"3299200051","3299200059"),IIf(_lCCGrp02,IIf(_nSaldo>0,"3299190031","3299190049"),IIf(_lCCGrp03,IIf(_nSaldo>0,"3301020071","3301020089"),IIf(_lCCGrp04,"3301010038",""))))
				Else
					If _lParc13
						_cRetorno := "2101150004"
					Else
						_cRetorno := IIf(_lCCGrp01,"3299200001",IIf(_lCCGrp02,"3299190001",IIf(_lCCGrp03,"3301020003",IIf(_lCCGrp04,"3301010034",""))))
					EndIf
				EndIf
			Else
				If SRZ->RZ_PD $ _cEstagio
					_cRetorno := "3301020074"
				ElseIf SRZ->RZ_PD $ _cAjdCusto
					_cRetorno := "3301020075"
				ElseIf SRZ->RZ_PD $ _cAbonoPec
					_cRetorno := "3301020076"
				ElseIf SRZ->RZ_PD $ _cAvisoPre
					_cRetorno := "3301020077"
				ElseIf SRZ->RZ_PD $ _cINSS
					If _lParc13
						_cRetorno := "2101150005"
					Else
						_cRetorno := "3301020001"
					EndIf
				ElseIf SRZ->RZ_PD $ _cFGTS
					If _lParc13
						_cRetorno := "2101150006"
					Else
						_cRetorno := "3301020002"
					EndIf
				ElseIf SRZ->RZ_PD $ _cProvFer
					_cRetorno := IIf(_nSaldo>0,"3301020071","3301020089")
				ElseIf SRZ->RZ_PD $ _cProv13
					_cRetorno := IIf(_nSaldo>0,"3301020072","3301020089")
				ElseIf SRZ->RZ_PD $ _cProvTerc
					_cRetorno := IIf(_nSaldo>0,"3301020073","3301020089")
				Else
					If _lParc13
						_cRetorno := "2101150004"
					Else
						_cRetorno := "3301020003"
					EndIf
				EndIf
			EndIf
		Else
			_cRetorno	:=	SRV->RV_DEBITO
		EndIf
	Else //O A99001CD nunca entra no crédito
		_cRetorno := SRV->RV_CREDITO
	EndIf	
ElseIf _cCod == 'A98001CC'
	If Empty(SRV->RV_CREDITO)
		If SRV->RV_TIPOCOD == "3" .And. SRZ->RZ_PD =="713"// '1','Provento','2','Desconto','3','Base(Provento)','4','Base(Desconto)'
			_cRetorno	:= IIf(SRA->RA_CATFUNC=='P',"2101040002",(IIf(SRA->RA_CATFUNC == 'A',"2101040007","2101040001")))
		ElseIf SRV->RV_TIPOCOD == "2" // "2"Desconto
			If SRZ->RZ_PD $ _cRecupera
				If SRZ->RZ_FILIAL $ _cFil01
					_cRetorno := IIf(_lCCGrp01,"3299020064",IIf(_lCCGrp02,"3299010018",IIf(_lCCGrp03,"3301020049",IIf(_lCCGrp04,"3301010022",""))))
				ElseIf SRZ->RZ_FILIAL $ _cFil10
					_cRetorno := IIf(_lCCGrp01,"3299040064",IIf(_lCCGrp02,"3299030018",IIf(_lCCGrp03,"3301020049",IIf(_lCCGrp04,"3301010022",""))))
				ElseIf SRZ->RZ_FILIAL $ _cFil20
					_cRetorno := IIf(_lCCGrp01,"3299080062",IIf(_lCCGrp02,"3299070018",IIf(_lCCGrp03,"3301020049",IIf(_lCCGrp04,"3301010022",""))))
				ElseIf SRZ->RZ_FILIAL $ _cFil23
					_cRetorno := IIf(_lCCGrp01,"3299180064",IIf(_lCCGrp02,"3299170018",IIf(_lCCGrp03,"3301020049",IIf(_lCCGrp04,"3301010022",""))))
				ElseIf SRZ->RZ_FILIAL $ _cFil30
					_cRetorno := IIf(_lCCGrp01,"3299060064",IIf(_lCCGrp02,"3299050018",IIf(_lCCGrp03,"3301020049",IIf(_lCCGrp04,"3301010022",""))))
				ElseIf SRZ->RZ_FILIAL $ _cFil40
					_cRetorno := IIf(_lCCGrp01,"3299140064",IIf(_lCCGrp02,"3299130018",IIf(_lCCGrp03,"3301020049",IIf(_lCCGrp04,"3301010022",""))))
				ElseIf SRZ->RZ_FILIAL $ _cFil93
					_cRetorno := IIf(_lCCGrp01,"3299200064",IIf(_lCCGrp02,"3299190018",IIf(_lCCGrp03,"3301020049",IIf(_lCCGrp04,"3301010022",""))))
				Else
					_cRetorno := "3301020049"
				EndIf
			EndIf
		EndIf
	Else
		_cRetorno	:=	SRV->RV_CREDITO
	EndIf
ElseIf _cCod $ "A96001VL"
	_cRetorno := Abs(SaldoProv())
ElseIf _cCod $ "A96001HS"
	If SaldoProv() < 0
		_cRetorno := "REVERSAO"
	Else
		_cRetorno := "COMPLEMENTO"
	EndIf
EndIf

//Retorna sempre uma conta genérica quando não identificar a conta correta
If Empty(_cRetorno)
	_cRetorno := "1101010020"
EndIf

FWRestArea(_aArea)

Return(_cRetorno)

Static Function SaldoProv

Local _aArea	:= FWGetArea()
Local _nSaldo := 0
Local _cAlias := GetNextAlias()

BeginSql alias _cAlias
	SELECT (SELECT NVL(SUM(SRZ1.RZ_VAL), 0) BXPROVISAO
	          FROM %Table:SRZ% SRZ1
	         WHERE SRZ1.D_E_L_E_T_ = ' '
	           AND SRZ1.RZ_FILIAL = %exp:SRZ->RZ_FILIAL%
	           AND SRZ1.RZ_CC = %exp:SRZ->RZ_CC%
	           AND SRZ1.RZ_MAT = 'zzzzzz'
	           AND SRZ1.RZ_PD IN ('144', '170')) -
	       (SELECT NVL(SUM(SRZ2.RZ_VAL), 0) PROVISAO
	          FROM %Table:SRZ% SRZ2
	         WHERE SRZ2.D_E_L_E_T_ = ' '
	           AND SRZ2.RZ_FILIAL = %exp:SRZ->RZ_FILIAL%
	           AND SRZ2.RZ_MAT = 'zzzzzz'
	           AND SRZ2.RZ_CC = %exp:SRZ->RZ_CC%
	           AND SRZ2.RZ_PD IN ('807', '808', '809')) SALDO
	  FROM DUAL
EndSql

_nSaldo:= (_cAlias)->SALDO
(_cAlias)->(DBCloseArea())
FWRestArea(_aArea)

Return(_nSaldo)
