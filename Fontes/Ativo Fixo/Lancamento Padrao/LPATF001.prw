/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |23/12/2024| Chamado 49442. Criada regra para contabilização da inclusão do ativo
Lucas Borges  |26/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
Lucas Borges  |17/10/2025| Chamado 52549. Ajustada filiais para a conta 3301020020
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: LPATF001
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 04/03/2011
Descrição---------: Retorna conta contabil para LP do Ativo Fixo
Parametros--------: _cCod = LP+Sequencia+Entidade (820001CC-Conta Credito, 820002CD-Conta Debito, 820001VL-Valor)
Retorno-----------: _xRetorno = Retorna a Conta/Valor contábil
===============================================================================================================================
*/
User Function LPATF001(_cCod As Character)

Local _cFil01	:= '01/02/03/04/07/08/09/0A/' As Character
Local _cFil05	:= '05/' As Character
Local _cFil10	:= '10/11/12/13/14/15/16/17/18/19/1A/1B/1C/' As Character
Local _cFil20	:= '20/21/22/24/' As Character
Local _cFil23	:= '23/' As Character
Local _cFil30	:= '30/31/32/33' As Character
Local _cFil40	:= '40/' As Characteras
Local _cFil90	:= '90/92/' As Character //92 tem que estar no _cFil90 e _cFilAdm
Local _cFil93	:= '93/' As Character
Local _cFilAdm	:= '06/0B/25/91/92/94/95/96/97/98/' As Character
Local _aAreaSB1 := SB1->(FWGetArea()) As Array
Local _aArea 	:= FWGetArea() As Array
Local _lConsumo	:= .F. As Logical
Local _xRetorno := Nil As Variant
Local _cAlias 	:= '' As Character

//Depreciação
If _cCod == "820001CD"
	//Edificações, Ferramentas, Instalações Industriauis e Máquinas e Equipamentos
	If AllTrim(SN1->N1_GRUPO) $ 'CC01/CC02/F001/II01/ME01/ME02'
		If SN1->N1_FILIAL $ '01/02/03/04/06/07/08/09/0A/0B'
			_xRetorno := '3299020019'
		ElseIf SN1->N1_FILIAL == '05'
			_xRetorno := '3299120019'
		ElseIf SN1->N1_FILIAL $ '10/11/12/13/14/15/16/17/18/19/1A/1B/1C'
			_xRetorno := '3299040019'
		ElseIf SN1->N1_FILIAL $ '20/21/22/24/25'
			_xRetorno := '3299080019'
		ElseIf SN1->N1_FILIAL == '23'
			_xRetorno := '3299180019'
		ElseIf SN1->N1_FILIAL $ '30/31/32/33'
			_xRetorno := '3299060019'
		ElseIf SN1->N1_FILIAL == '40'
			_xRetorno := '3299140019'
		ElseIf SN1->N1_FILIAL $ _cFil90+_cFilAdm
			_xRetorno := '3301020020'
		ElseIf SN1->N1_FILIAL == '93'
			_xRetorno := '3299200019'
		EndIf

	//Benfeitorias em Imóveis ou Instalações de 3OS
	ElseIf AllTrim(SN1->N1_GRUPO) $ 'B001/LB01'
		If SN1->N1_FILIAL $ '01/02/03/04/06/07/08/09/0A/0B'
			_xRetorno := '3299020045'
		ElseIf SN1->N1_FILIAL == '05'
			_xRetorno := '3299120045'
		ElseIf SN1->N1_FILIAL $ '10/11/12/13/14/15/16/17/18/19/1A/1B/1C'
			_xRetorno := '3299040045'
		ElseIf SN1->N1_FILIAL $ '20/21/22/24/25'
			_xRetorno := '3299080045'
		ElseIf SN1->N1_FILIAL == '23'
			_xRetorno := '3299180045'
		ElseIf SN1->N1_FILIAL $ '30/31/32/33'
			_xRetorno := '3299060045'
		ElseIf SN1->N1_FILIAL == '40'
			_xRetorno := '3299140045'
		ElseIf SN1->N1_FILIAL $ _cFil90+_cFilAdm
			_xRetorno := '3301020020'
		ElseIf SN1->N1_FILIAL == '93'
			_xRetorno := '3299200045'
		EndIf

	Else
		_xRetorno := Posicione("SNG",1,xFilial("SNG")+SN1->N1_GRUPO,"NG_CDEPREC")
	EndIf
//810 - Inclusão Ativo Fixo - usado para estornar o custo do produto da SA caso ele seja utilizado como ativo
ElseIf _cCod == "801001CD"
	SB1->(DBSetOrder(1))
	SB1->(DBSeek(xFilial("SB1")+SN1->N1_PRODUTO))
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
	If cFilAnt $ _cFil01+_cFil05
		If _lConsumo
			_xRetorno := '1102010017' //MATERIAL DE CONSUMO MATRIZ
		Else
			_xRetorno := '1102010007' //MATERIAL DE LIMPEZA-MATRIZ
		EndIf
	ElseIf cFilAnt $ _cFil10
		If _lConsumo
			_xRetorno := '1102010047' //ESTOQUE MATERIAL DE LABORATORIO - JARU
		Else
			_xRetorno := '1102010018' //MATERIAL LIMPEZA/CONS-F8 JA
		EndIf
	ElseIf cFilAnt $ _cFil20
		_xRetorno := '1102010043' //MATERIAL DE CONSUMO - RIO G DO SUL
	ElseIf cFilAnt $ _cFil23
		_xRetorno := '1102010070'
	ElseIf cFilAnt $ _cFil30
		_xRetorno := '1102010044'
	ElseIf cFilAnt $ _cFil40
		_xRetorno := '1102010065'
	ElseIf cFilAnt == '90'
		_xRetorno := '1102010140'
	ElseIf cFilAnt $ _cFilAdm
		_xRetorno := '3301020027' //MATERIAL DE CONSUMO/LIMPEZA
	ElseIf cFilAnt $ _cFil93
		_xRetorno := '1102010159' //ESTOQUE MAT USO E CONSUMO - PARANA
	EndIf
ElseIf _cCod == "801001CC"
	If cFilAnt $ _cFil01
		_xRetorno := '3299029991' //( - ) AJUSTE DE INVENTARIO
	ElseIf cFilAnt $ _cFil05
		_xRetorno := '3299129991'
	ElseIf cFilAnt $ _cFil10
		_xRetorno := '3299049991'
	ElseIf cFilAnt $ _cFil20
		_xRetorno := '3299089991'
	ElseIf cFilAnt $ _cFil23
		_xRetorno := '3299189991'
	ElseIf cFilAnt $ _cFil30
		_xRetorno := '3299069991'
	ElseIf cFilAnt $ _cFil40
		_xRetorno := '3299149991'
	ElseIf cFilAnt $ _cFil90
		_xRetorno := '3299169991'
	ElseIf cFilAnt $ _cFilAdm
		_xRetorno := '3301010031'
	ElseIf cFilAnt $ _cFil93
		_xRetorno := '3299209991'
	EndIf
ElseIf _cCod == "801001VL"
	_cAlias := GetNextAlias()
	BeginSql alias _cAlias
		SELECT B2_CM1, B9_CM1
		FROM %Table:SD1% SD1, %Table:SF4% SF4, %Table:SB2% SB2, %Table:SB9% SB9
		WHERE SD1.D_E_L_E_T_ = ' '
		AND SF4.D_E_L_E_T_ = ' '
		AND SB2.D_E_L_E_T_ = ' '
		AND SB9.D_E_L_E_T_ (+) = ' '
		AND D1_FILIAL = %exp:SN1->N1_FILIAL%
		AND D1_DOC = %exp:SN1->N1_NFISCAL%
		AND D1_SERIE = %exp:SN1->N1_NSERIE%
		AND D1_FORNECE = %exp:SN1->N1_FORNEC%
		AND D1_LOJA = %exp:SN1->N1_LOJA%
		AND D1_COD = %exp:SN1->N1_PRODUTO%
		AND D1_ITEM = %exp:SN1->N1_NFITEM%
		AND D1_FILIAL = F4_FILIAL
		AND D1_TES = F4_CODIGO
		AND D1_FILIAL = B2_FILIAL
		AND D1_COD = B2_COD
		AND D1_LOCAL = B2_LOCAL
		AND B9_FILIAL (+)= B2_FILIAL
		AND B9_COD (+)= B2_COD
		AND B9_LOCAL (+)= B2_LOCAL
		AND B9_DATA (+)= %exp:SN4->N4_DATA%
		AND F4_ESTOQUE = 'S'
	EndSql
	_xRetorno := IIf(Empty((_cAlias)->B9_CM1),(_cAlias)->B2_CM1*SN4->N4_QUANTD,(_cAlias)->B9_CM1*SN4->N4_QUANTD)
	(_cAlias)->( DBCloseArea() )
EndIf

SB1->(FWRestArea(_aAreaSB1))
FWRestArea(_aArea)

Return (_xRetorno)
