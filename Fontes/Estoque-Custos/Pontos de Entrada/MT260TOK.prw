/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |15/04/2019| Chamado 28685. Validação p/ não permitir fracionamento de UM que são inteiras.
Lucas Borges  |19/09/2024| Chamado 48569. Incluir a rotina de Desconto Tetra Pak nas exceções para validação de acesso
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT260TOK
Autor-------------: Tiago Correa Castro
Data da Criacao---: 25/04/2009
Descrição---------: Ponto de Entrada que valida movimento de transferencia modelo I
Parametros--------: 
Retorno-----------: Lógico validando o lançamento 
===============================================================================================================================
*/ 
User Function MT260TOK

Local _aArea    := FWGetArea()
Local _aAreaZZL := ZZL->(FWGetArea())
Local _aAreaSB1 := SB1->(FWGetArea())
Local _aAreaSB2 := SB2->(FWGetArea())
Local _lRet		:=	.T.  
Local _nDifPrd	:= 0                                                             
Local _nDifCM	:= 0   
Local _nCMorig	:= 0    
Local _nCMdest	:= 0  
Local _aSldNeg	:= 0 
Local _nDif		:= 0
Local _lValidFrac1UM:= .T.
Local _cUmNoFra		:= SuperGetMV("IT_UMNOFRAC",.F.,"PC,UN")

ZZL->(DBSetOrder(3))
If ZZL->(DBSeek(xFilial("ZZL")+RetCodUsr()))
	If ZZL->ZZL_AUTSIM <> 'S' .And. !FWIsInCallStack("DESCTETRAE") .And. !FWIsInCallStack("DESCTETRAE") //Não validar quando For estorno de NF-e da Tetra Pak
    	FWAlertWarning("Usuário sem permissão para realizar transferência simples. Não será possível realizar a transferência. Entre em contato com o suporte do TI.", "MT260TOK01")
    	_lRet := .F.
	ElseIf !(cLocOrig $ ZZL->ZZL_ARMAZE)
    	FWAlertWarning("Usuário sem permissão para utilizar este armazem de origem. Não será possível realizar o estorno da transferência simples. Armazens permitidos ao usuário: '"+;
						AllTrim(ZZL->ZZL_ARMAZE)+"'. Entre em contato com o suporte do TI.","MT260TOK02")
      	_lRet := .F.
    ElseIf !(cLocDest $ ZZL->ZZL_ARMAZE)
       	FWAlertWarning("Usuário sem permissão para utilizar este armazem de destino. Não será possível realizar a transferência simples. Armazens permitidos ao usuário: '"+;
         				AllTrim(ZZL->ZZL_ARMAZE)+"'. Entre em contato com o suporte do TI.","MT260TOK03")
         _lRet := .F.
	ElseIf SubStr(cCodOrig,1,4) == "0006" .And. nQuant260D == 0
		 FWAlertWarning("Para esse produto e obrigatório o preenchimento da segunda unidade de medida (Peças).","MT260TOK04")
		 _lRet := .F.
	ElseIf SuperGetMV("IT_BLQMOV",.F., "") .And. Demis260 > Date()
	  FWAlertWarning("Movimento com data maior que a data atual, os movimentos com data maior que a data atual estão bloqueados. Entre em contato com o suporte do TI.","MT260TOK05")
	  _lRet := .F.
	ElseIf cLocOrig == '34' .Or. cLocDest == '34'
   		FWAlertWarning("Não é permitida transferência simples usando armazém 34. Utilize a rotina de transferência multipla","MT260TOK06")
		_lRet := .F.	
	Else
		NNR->(DBSetOrder(1))
		NNR->(DBSeek(xFilial("NNR")+cLocOrig))
		_cTipoOrigem := NNR->NNR_I_TPFV
		NNR->(DBSeek(xFilial("NNR")+cLocDest))
		_cTipoDestino := NNR->NNR_I_TPFV
		//Virtual               //Fisico
		If _cTipoOrigem <> _cTipoDestino 
			FWAlertWarning("Não é permitido tranferir produtos entre armazem virtual "+cLocOrig+" e armazem fisico "+cLocDest+" nessa rotina. "+;
					"Utilize a rotina tranferencia multipla para prencher o campo de observação","MT260TOK07")
			_lRet := .F.
		EndIf

		If cCodOrig <> cCodDest
			If AllTrim(cCodOrig) $ (SuperGetMV("IT_LTGRN",.F.,'08000000062')+SuperGetMV("IT_LTMP",.F.,'08000000034')+SuperGetMV("IT_CRGRN",.F.,'08000000064;08000000063')+SuperGetMV("IT_CRMP",.F.,'08000000007'));
				.And. AllTrim(cCodDest) $ (SuperGetMV("IT_LTGRN",.F.,'08000000062')+SuperGetMV("IT_LTMP",.F.,'08000000034')+SuperGetMV("IT_CRGRN",.F.,'08000000064;08000000063')+SuperGetMV("IT_CRMP",.F.,'08000000007'))
				If AllTrim(cLocOrig) == "03" .And. AllTrim(cLocDest) == "03"
					_lRet := .T.
				Else
					FWAlertWarning("Para a transferência entre esses produtos favor utilizar somente o armazém 03 para origem e destino!","MT260TOK08")
					_lRet := .F.
				EndIf
			Else
				FWAlertWarning("A operação não pode ser concluída com produtos de origem e destino divergentes!","MT260TOK09")
				_lRet := .F.
			EndIf
		EndIf
		//Verifica saldo do produto. Chamado 7816
		If _lRet
			_aSldNeg := U_VldEstRetrNeg(cCodOrig, cLocOrig, nQuant260, Demis260)	
			If Len(_aSldNeg) > 0
				_nDIf := _aSldNeg[2] - nQuant260
				FWAlertWarning("Quantidade requisitada é maior que o saldo no dia "+DToC(_aSldNeg[1])	+" para o produto: "+CHR(13)+CHR(10)+AllTrim(cCodOrig)+"-"+cLocOrig+". Diferenca: ";
						+AllTrim(TRANSFORM(_nDif, "@E 999,999,999,999.99")), "Saldo Insuficiente. Verifique o saldo no Kardex.","MT260TOK10")
				_lRet := .F.
			EndIf
		EndIf
		//=====================================================
		//Verificacao do CM origem e Destino                  |
		//=====================================================
		If _lRet
			_nDifCM 	:= SuperGetMV("IT_DIFCM",.F., 0) //Percentual minimo de diferenca de CM para bloquear processo. (71%)
			_nDifCM2	:= SuperGetMV("IT_DIFCM2",.F., 0) //Percentual minimo de diferenca de CM para exibir mensagem se continua ou nao. (51%)
			_nCMorig 	:= Posicione("SB2",1,xFilial("SB2")+cCodOrig+cLocOrig,"B2_CM1")//SEEK NO PRODUTO DE DESTINO

			SB2->(DBSeek(xFilial("SB2")+cCodDest+cLocDest))//Produto de destino
			_nCMdest := SB2->B2_CM1
			
			If _nCMdest > 0 .And. !(SB2->B2_QATU == 0 .And. SB2->B2_VATU1 == 0)//Produto de Destino
				_nDifPrd := (_nCMdest - _nCMorig) / _nCMorig
				If _nDifPrd < 0 
					_nDifPrd := (_nDifPrd * (-1))
				EndIf 
				_nDifPrd := _nDifPrd * 100
			
				If _nDifPrd >= _nDifCM2 .And. _nDifPrd < _nDifCM //Diferenca entre 51% e 70%
					If !FWAlertYesNo("ATENÇÃO! Diferença entre valor de Custo Medio de Origem e Destino é "+TRANSFORM(_nDifPrd, "@E 999.9999")+"%. Deseja prosseguir?","MT260TOK11")
					_lRet := .F.		
					EndIf
				ElseIf _nDifPrd >= _nDifCM //Diferenca maior que 70%
					FWAlertWarning("Transferência não permitida! Diferença entre valor de Custo Medio de Origem e Destino é "+TRANSFORM(_nDifPrd, "@E 999.9999")+"%"+;
								"Favor analisar o Kardex! Se necessário, entre em contato com o Depto. de TI.","MT260TOK12")
					_lRet := .F.	
				EndIf
			EndIf   
		EndIf
	
		If _lRet
			If ZZL->ZZL_PEFRPA == "S"
				_lValidFrac1UM:=.F.
			EndIf
			
			SB1->(DBSetOrder(1))
			If _lValidFrac1UM .And. SB1->(DBSeek(xFilial("SB1") + cCodOrig))
				If (SB1->B1_UM $ _cUmNoFra .And. nQuant260 <> Int(nQuant260))
					FWAlertWarning("Não é permitido fracionar a quantidade da 1a. UM de produto onde a Unid. Medida For "+_cUmNoFra+". "+;
							"Favor informar apenas quantidades inteiras na Primeira Unidade de Medida.","MT260TOK13")
					_lRet := .F.
				EndIf
				If (SB1->B1_SEGUM $ _cUmNoFra .And. nQuant260D <> Int(nQuant260D))
					FWAlertWarning("Não é permitido fracionar a quantidade da 2a. UM de produto onde a Unid. Medida For "+_cUmNoFra+". "+;
							"Favor informar apenas quantidades inteiras na Segunda Unidade de Medida.","MT260TOK14")
					_lRet := .F.
				EndIf
			EndIf
		EndIf
	EndIf
Else
   FWAlertWarning("Usuário sem cadastro na ZZL. Entre em contato com o suporte do TI.","MT260TOK15")
   _lRet := .F.
EndIf

SB2->(FwRestArea(_aAreaSB2))
SB1->(FwRestArea(_aAreaSB1))
ZZL->(FwRestArea(_aAreaZZL))
FwRestArea(_aArea)

Return _lRet
