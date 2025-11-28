/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/10/2024| Chamado 48759. Revertidas as últimas alterações para melhor análise do André
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
Lucas Borges  |18/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"
 
/*
===============================================================================================================================
Programa----------: A261TOK
Autor-------------: Guilherme Diogo
Data da Criacao---: 19/10/2012
Descrição---------: Ponto de Entrada que valida movimento de transferencia modelo II
Parametros--------: Nenhum
Retorno-----------: Lógico validando o lançamento 
===============================================================================================================================
*/     
User Function  A261TOK()

Local _oDlg    
Local _oMainWnd
Local _oProd
Local _cVarQ
Local _lRet    := .T.    
Local _aProd   := {}
Local _cDesc1  :=""
Local _cDesc2  :=""
Local _aErro1   := {}    
Local _aErro2   := {}    
Local _cItens   := ""  
Local _lErro1   := .F.
Local _lErro2   := .F.
Local _aErro    := {} 
Local _aSldNeg  := {} 
Local _lErro    := .F.
Local _nDifCM	:= 0
Local _nDifCM2	:= 0
Local _nI		:= 0  , nX  , x  , y
Local _nCMorig	:= 0
Local _nCMdest	:= 0
Local _nDifPrd	:= 0
Local _nLocalOrig, _nLocalDest     
Local _aOrd := SaveOrd({"ZZL"})
Local _lmt103fim := .F.
Local _laglt003 := .F.
Local _cLinhas:=""
Local _cArmVirtual:=""
Local _cArmFisico:=""
Local _lValidFrac1UM:=.T.
Local _cUM_NO_Fracionada:=SuperGetMV("IT_UMNOFRAC",.F.,"PC,UN")
Local _cARM_MATA311:=SuperGetMV("IT_ARMAT31",.F.,"")//20,22,31,61
Local _nDsctptrs

Local _nMotTrRef, _nDscMTrRf 
Local _cFilVld34 := SuperGetMV('IT_FILVLD3',.F.,'') // Filiais Habilitadas para Validação de Transferência para o Armazém 34.

Local _cPRD_MATA311:=SuperGetMV("IT_PRDMT31",.F.,"")//00020010501,00020020501,08140000045,08140000046,00090020501,00090010501
//00020010501, - LEITE EM PO INTEGRAL 25 KG ITALAC
//00020020501, - LEITE EM PO DESNATADO 25 KG ITALAC
//08140000045, - LEITE EM PÓ INTEGRAL IMPORTADO (CONAPROLE)
//08140000046, - LEITE EM PÓ DESNATADO IMPORTADO (CONAPROLE)
//00090020501, - SORO EM PO PARC. DESMINERALIZADO 25 KG ITALAC
//00090010501, - SORO EM PO 25 KG ITALAC

//Verifica se está sendo executado automaticamente a partir do mt103fim
If isincallstack("U_MT103FIM")
	_lmt103fim := .T.
EndIf

//Verifica se está sendo executado automaticamente a partir do aglt003
If isincallstack("U_AGLT003G")
	_laglt003 := .T.
EndIf

_lAOMS116S:=IsInCallStack("U_AOMS116S")
_lMCOM004:=IsInCallStack("MCOM4Trans")
_lMATA311:=IsInCallStack("MATA311")

Begin Sequence
	If !_lmt103fim .And. !_laglt003 .And. !_lAOMS116S .And. !_lMCOM004 .And.  !U_ITVACESS( 'ZZL' , 3 , 'ZZL_AUTMUL' , 'S' ) 
		U_ITMsg("Usuário sem permissão para realizar transferência multipla. Não será possível realizar a transferência.",;
		"Permissões de Acesso Italac",;
		"Entre em contato com o suporte do TI.",1)
		_lRet := .F.
		Break                                                  
	EndIf       

	_nLocalOrig := aScan(aHeader,{|x| x[1] = 'Armazem Orig.'})
	_nLocalDest := aScan(aHeader,{|x| x[1] = 'Armazem Destino'})

	If ! xFilial("SD3") $ _cFilVld34
		_nTPTRS     := aScan(aHeader,{|x| x[2] = 'D3_I_TPTRS'})  
		_nDsctptrs  := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_DSCTM"})  
	EndIf 

	_nSetor     := aScan(aHeader,{|x| x[2] = 'D3_I_SETOR'})
	_nD3_I_OBS  := aScan(aHeader,{|x| x[2] = 'D3_I_OBS'  })
	nPosOCod    := 1//aScan(aHeader,{|x| x[2] = 'D3_COD' })
	nPosDCod    := 6//aScan(aHeader,{|x| x[2] = 'D3_COD' }) 
	nPosQtd     := aScan(aHeader,{|x| x[2] = 'D3_QUANT'  }) 
	nPosQtd2    := aScan(aHeader,{|x| x[2] = 'D3_QTSEGUM'}) 
		
	_nMotTrRef  := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_MOTTR"})
	_nDscMTrRf  := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_DSCMT"})

	_cFilEAcesso:=""
	_cArmEAcesso:=""

	If !_lmt103fim .And. !_laglt003 .And. !_lAOMS116S .And. !_lMCOM004 
		_cAliasZZL:= GetNextAlias()
		_cQuery := " SELECT ZZL.R_E_C_N_O_ AS REG_ZZL "
		_cQuery += " FROM  "+ RetSQLName("ZZL") +" ZZL "
		_cQuery += " WHERE D_E_L_E_T_ = ' ' "
		_cQuery += " AND ZZL_ARMEFE <> ' '"

		DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQuery ) , _cAliasZZL , .T. , .F. )

		(_cAliasZZL)->( DBGoTop() )
		While (_cAliasZZL)->(!Eof())
		ZZL->(DBGoTo((_cAliasZZL)->REG_ZZL))
			If (_nPos:=AT("/",ZZL->ZZL_ARMEFE)) > 0 
				If cFilant <> LEFT(ZZL->ZZL_ARMEFE, _nPos-1 )
					(_cAliasZZL)->(DBSkip())	   
					Loop
				EndIf
				_cFilEAcesso+=LEFT(ZZL->ZZL_ARMEFE, _nPos )+";"
				_cArmEAcesso+=AllTrim(SubStr(ZZL->ZZL_ARMEFE, _nPos ))+"; "
			Else
				_cArmEAcesso+=AllTrim(ZZL->ZZL_ARMEFE)+"; "
			EndIf
		
			(_cAliasZZL)->(DBSkip())
		EndDo
		(_cAliasZZL)->(DBCloseArea())
	EndIf

	ZZL->(DBSetOrder(3))  
	ZZL->(DBSeek(xFilial("ZZL")+RetCodUsr()))
	If ZZL->ZZL_PEFRPA == "S"  .Or. ZZL->ZZL_PEFROU == "S"
		_lValidFrac1UM:=.F.
	EndIf

	For _nI := 1 To Len(aCols)
			
		If aTail(aCols[_nI]) // Se Linha Deletada
			Loop
		EndIf

		If !_lmt103fim .And. !_laglt003 .And. !_lAOMS116S .And. !_lMCOM004 .And. !_lMATA311 .And. Empty(_cPRD_MATA311+_cARM_MATA311)
		
			If ZZL->ZZL_PERTRA <> "S" .And. cFilant $ _cFilEAcesso .And. aCols[_nI,_nLocalOrig] $ _cArmEAcesso .And. aCols[_nI,_nLocalDest] $ _cArmEAcesso
				U_ITMsg("TRANSFERÊNCIA NÃO PERMITIDA!" ,;
						"Permissões de Acesso Italac",;
						"Para transferir usando os armazéns " +AllTrim(_cArmEAcesso)+ " usar a rotina Solicitação de Transferência.",1)
				_lRet := .F.
				Break  
			EndIf
		
		ElseIf !_lmt103fim .And. !_laglt003 .And. !_lAOMS116S .And. !_lMCOM004 .And. !_lMATA311 

			If !AllTrim(aCols[_nI,nPosOCod]) $ _cPRD_MATA311 .And. (aCols[_nI,_nLocalOrig]  $ _cArmEAcesso  .Or.  aCols[_nI,_nLocalDest] $ _cArmEAcesso ) .AND.;
																(!aCols[_nI,_nLocalOrig] $ _cARM_MATA311 .Or. !aCols[_nI,_nLocalDest] $ _cARM_MATA311)
			
				If ZZL->ZZL_PERTRA <> "S" .And. cFilant $ _cFilEAcesso .And. aCols[_nI,_nLocalOrig] $ _cArmEAcesso .And. aCols[_nI,_nLocalDest] $ _cArmEAcesso
					U_ITMsg("TRANSFERÊNCIA NÃO PERMITIDA!" ,;
							"Permissões de Acesso Italac",;
							"Para transferir usando os armazéns " +AllTrim(_cArmEAcesso)+ " usar a rotina Solicitação de Transferência.",1)
					_lRet := .F.
					Break  
				EndIf
			Else			 
				If ((AllTrim(aCols[_nI,nPosOCod]) $ _cPRD_MATA311 .And. aCols[_nI,_nLocalOrig] $ _cARM_MATA311) .Or. ;
					(AllTrim(aCols[_nI,nPosDCod]) $ _cPRD_MATA311 .And. aCols[_nI,_nLocalDest] $ _cARM_MATA311)) .AND.;
					(aCols[_nI,_nLocalDest] <> "34") 
		
					_cProds:="PRODUTOS:"+CHR(13)+CHR(10)
					_aProds:=StrToArray(AllTrim(_cPRD_MATA311),",")
					For x := 1 To Len(_aProds)
						_cProds+=_aProds[x]+" - "+AllTrim(Posicione("SB1",1,xFilial("SB1")+_aProds[x],"B1_I_DESCD"))+CHR(13)+CHR(10)
					Next
		
					U_ITMsg("TRANSFERÊNCIA NÃO PERMITIDA!" ,;
							"Permissões de Acesso Italac",;
							"Para transferir usando os armazéns " +AllTrim(_cARM_MATA311)+ " e produtos (Ver detalhes) usar a rotina Solicitação de Transferência.",1,,,,,,;
							{||  U_ITMsgLog(_cProds, "ATENCAO",1,.F.) })
		
					_lRet := .F.
					Break  
				EndIf
			EndIf
		EndIf
			
		If !(aCols[_nI,_nLocalOrig] $ ZZL->ZZL_ARMAZE) .And. !_lmt103fim .And. !_laglt003 .And. !_lAOMS116S .And. !_lMCOM004
			U_ITMsg("Usuário sem permissão para utilizar este armazem de origem. Não será possível realizar a transferência multipla. Armazens permitidos ao usuário: '"+AllTrim(ZZL->ZZL_ARMAZE)+"'.",;
					"Permissões de Acesso Italac",;
					"Entre em contato com o suporte do TI.",1)
			_lRet := .F.
			Break  
		EndIf
			
		If ! (aCols[_nI,_nLocalDest] $ ZZL->ZZL_ARMAZE) .And. !_lmt103fim .And. !_laglt003 .And. !_lAOMS116S .And. !_lMCOM004
			U_ITMsg("Usuário sem permissão para utilizar este armazem de destino. Não será possível realizar a transferência multipla. Armazens permitidos ao usuário: '"+AllTrim(ZZL->ZZL_ARMAZE)+"'.",;
					"Permissões de Acesso Italac",;
					"Entre em contato com o suporte do TI.",1)
			_lRet := .F.
			Break  
		EndIf

		If ! xFilial("SD3") $ _cFilVld34
			If (aCols[_nI,_nLocalDest] $ "34") .And. Empty(aCols[_nI,_nTPTRS]) .And. !_lmt103fim .And. !_laglt003 .And. !_lAOMS116S .And. !_lMCOM004
				U_ITMsg("Preencha o campo Tp TRS (Tipo de tranferencia)",;  
						"Campo obrigatorio condicional",;
						"Esse campo é obrigatório quando o armazem de destino é 34",1)
				_lRet := .F.
				Break  
			ElseIf (aCols[_nI,_nLocalDest] $ "34") .And. !Empty(aCols[_nI,_nTPTRS]) 
				U_MT261VLD("A261TOK",_nI) // Atribui a descrição do tipo de movimentação/transferência.
			EndIf
		EndIf 

		If _lValidFrac1UM //.AND. SB1->B1_TIPO == "PA"
			SB1->(DBSeek(xFilial("SB1") + AllTrim(aCols[_nI,nPosOCod])))
			If SB1->B1_UM $ _cUM_NO_Fracionada
				If aCols[_nI,nPosQtd] <> Int(aCols[_nI,nPosQtd])
					aAdd(_aProd,{aCols[_nI,nPosOCod],SB1->B1_I_DESCD,aCols[_nI,nPosDCod],Posicione("SB1",1,xFilial("SB1")+aCols[_nI,nPosDCod],"B1_I_DESCD"),;
					"Não é permitido fracionar a quantidade da 1a. UM de produto onde a Unid. Medida For "+_cUM_NO_Fracionada})
				EndIf
			EndIf

			SB1->(DBSeek(xFilial("SB1") + AllTrim(aCols[_nI,nPosOCod])))
			If SB1->B1_SEGUM  $ _cUM_NO_Fracionada//= "PC" .And. LEFT( AllTrim(aCols[_nI,nPosOCod]),4)=="0006"
				If aCols[_nI,nPosQtd2] <> Int(aCols[_nI,nPosQtd2])
					aAdd(_aProd,{aCols[_nI,nPosOCod],SB1->B1_I_DESCD,aCols[_nI,nPosDCod],Posicione("SB1",1,xFilial("SB1")+aCols[_nI,nPosDCod],"B1_I_DESCD"),;
					"Não é permitido fracionar a quantidade da 2a. UM de produto onde a Unid. Medida For "+_cUM_NO_Fracionada})
				EndIf
			EndIf
		EndIf

		//=============================================================================
		// Validações Exclusiva para destino Armazém 34.
		//=============================================================================
		_nPosLocDe  := aScan( aHeader, { |x| AllTrim(x[1])== "Armazem Destino" } )
		//_cLocalDest := aCols[_nI,_nPosMotiv] 
		_cLocalDest := aCols[_nI ,_nPosLocDe] 

		If _cLocalDest == "34" .And. xFilial("SD3") $ _cFilVld34 // Valida apenas para as filiais contidas no Parâmetro IT_FILVLD3
			//- Não permitir gravar a transferência sem que seja preenchido o campo origem; D3_L_ORIG = Origem // Descrição: D3_I_SETOR 
			
			//================  1 - Validação
			_cMotTrRef  := aCols[_nI,_nMotTrRef]
			
			If Empty(_cMotTrRef)
				U_ITMsg("Favor preencher campo do motivo da transferência. Obrigatório preenchimento para transferências para o armazém 34.","Atenção",;
						"Verificar preenchimento do campo 'Mot. Tran. Ref.' (D3_I_MOTTR)." ,1) 
				_lRet := .F.  
			EndIf

			//================ 2 - Validação
			_nPosOrig  := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_SETOR"})   // 2  
			_cOrig     := aCols[_nI,_nPosOrig]

			If Empty(_cOrig)
				U_ITMsg("Favor preencher campo da origem da transferência. Obrigatório preenchimento para transferências para o armazém 34.","Atenção",;
						"Verificar preenchimento do campo 'Origem'. Trf. (D3_I_SETOR)." ,1)
				
				_lRet := .F.
			EndIf 

			// ===============  3 - Validação
			//- Não permitir gravar a transferência sem que seja preenchido o campo destino ; D3_I_DESTI = Destinacao    
			_nPosDest  := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_DESTI"})  // 3
			_cDestino  := aCols[_nI,_nPosDest]      
			If Empty(_cDestino)
				U_ITMsg("Favor preencher campo do destino da transferência. Obrigatório preenchimento para transferências para o armazém 34.","Atenção",;
						"Verificar preenchimento do campo 'Destino' (D3_I_DESTI).",1) 
				_lRet := .F. 
			EndIf 
		
			If ! _lRet
				Break
			EndIf  
		EndIf 

		//============================================================================
		// Validação Exclusiva para Produtos com controle de Rasteabilidade por lotes
		//============================================================================
		//- Não permitir gravar a transferência quando o produto controlar rastro por lote (B1_RASTRO = 'L') e que os campos lote origem e lote destino esteja idênticos;
		_nPosProd  := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_COD"}) 
		_cCodProd  := aCols[_nI,_nPosProd]  
		_cRastro   := Posicione("SB1",1,xFilial("SB1")+U_ITKEY(_cCodProd,"B1_COD"),"B1_RASTRO")

		If _cRastro == "L" // Rastreado por controle de lotes.
			_nPosLote  := aScan(aHeader,{|x| x[1]=="Lote"}) 
			_cLote     := aCols[_nI,_nPosLote] 
		
			_nPosLoteD := aScan(aHeader,{|x| x[1]=="Lote Destino"})
			_cLoteDest := aCols[_nI,_nPosLoteD] 
			If AllTrim(_cLote) <> AllTrim(_cLoteDest) .And. aCols[_nI,_nLocalOrig] <> aCols[_nI,_nLocalDest]
				U_ITMsg("Para produtos com rastreabilidade por lotes, o lote de origem não pode ser diferente do lote de destino.","Atenção", ,1)
				_lRet := .F. 
				Break 
			EndIf 
		EndIf 
	Next

	For nX := 1 To Len(aCols)
		If aTail(aCols[nX]) // Se Linha Deletada
			Loop
		EndIf

		If aCols[nX,1] <> aCols[nX,6] .And. !_lmt103fim .And. !_laglt003 .And. !_lMCOM004 //Validação de produto divergente com exceção para leite a granel

			If !(trim(aCols[nX,1]) $ (SuperGetMV("IT_LTGRN",.F.,'08000000062')+SuperGetMV("IT_LTMP",.F.,'08000000034')+SuperGetMV("IT_CRGRN",.F.,'08000000064;08000000063')+SuperGetMV("IT_CRMP",.F.,'08000000007')) .and.;
				trim(aCols[nX,6]) $ (SuperGetMV("IT_LTGRN",.F.,'08000000062')+SuperGetMV("IT_LTMP",.F.,'08000000034')+SuperGetMV("IT_CRGRN",.F.,'08000000064;08000000063')+SuperGetMV("IT_CRMP",.F.,'08000000007')) )
		
				_cDesc1 := AllTrim(Posicione("SB1",1,xFilial("SB1")+aCols[nX,1],"B1_I_DESCD"))
				_cDesc2 := AllTrim(Posicione("SB1",1,xFilial("SB1")+aCols[nX,6],"B1_I_DESCD"))  

				aAdd(_aProd,{aCols[nX,1],_cDesc1,aCols[nX,6],_cDesc2,"produtos de origem e destino divergentes"})

			EndIf

		
		EndIf   

			If !_lmt103fim .And. !_laglt003 .And. !_lMCOM004
				NNR->(DBSetOrder(1))
				NNR->(DBSeek(xFilial()+aCols[nX,_nLocalOrig]))
				_cTipoOrigem :=NNR->NNR_I_TPFV
				NNR->(DBSeek(xFilial()+aCols[nX,_nLocalDest]))
				_cTipoDestino:=NNR->NNR_I_TPFV
				If _cTipoOrigem  <> _cTipoDestino .And. Len(AllTrim(aCols[nX,_nD3_I_OBS])) < 10//"1=Fisico;2=Virtual"
					If !aCols[nX,_nLocalOrig] $ _cArmVirtual .And. _cTipoOrigem = "2"
						_cArmVirtual+=aCols[nX,_nLocalOrig]+", "
					EndIf   
				If !aCols[nX,_nLocalDest] $ _cArmFisico .And. _cTipoOrigem = "1"
					_cArmFisico +=aCols[nX,_nLocalDest]+", "
				EndIf   
				_cLinhas+=StrZero(nX,3)+", "
				EndIf
			EndIf
	Next nX 

	If Len(_aProd) > 0

		//==============================================================
		//| Monta tela para seleção dos arquivos contidos no diretório |
		//==============================================================
		If FwGetRunSchedule() .Or. GetRemoteType() == -1
			_lRet := .F.
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "A261TOK01"/*cMsgId*/, "A261TOK01 - A operação não pode ser concluída com produtos com Problemas!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		Else
			oMainWnd:ReadClientCoords()//So precisa declarar uma fez para o Programa todo
			DEFINE MSDIALOG _oDlg TITLE "Produtos com Problemas"  From 150,0 To 440,oMainWnd:nRight-20 OF _oMainWnd PIXEL
				_oDlg:lEscClose := .F.
				_nTam:=(_oDlg:nClientWidth-4)/2

				@ 02,02 LISTBOX _oProd VAR _cVarQ Fields HEADER "Cod. Prod. Origem","Desc. Prod. Origem","Cod. Prod. Destino","Desc. Prod. Destino","Problemas" SIZE _nTam,110 OF _oDlg PIXEL
				_oProd:SetArray(_aProd)
				_oProd:bLine := {|| {;
				_aProd[_oProd:nAt][1],;
				AllTrim(_aProd[_oProd:nAt][2]),; 
				_aProd[_oProd:nAt][3],;
				AllTrim(_aProd[_oProd:nAt][4]),;
				_aProd[_oProd:nAt][5];
				}}
				@120,010 BUTTON "SAIR" SIZE 40,11 ACTION (_lRet := .F.,U_ITMsg("A operação não pode ser concluída com produtos com Problemas!","Atenção",,1), _oDlg:End()) OF _oDlg PIXEL
				
			ACTIVATE MSDIALOG _oDlg CENTERED
		EndIf
	EndIf 

	If NNR->(FIELDPOS("NNR_I_TPFV")) <> 0 .And. !_lmt103fim .And. !_laglt003 .And. !_lMCOM004 .And. !Empty(_cArmVirtual) .And. !Empty(_cArmFisico)
		_cLinhas    :=LEFT(_cLinhas,Len(_cLinhas)-2)
		_cArmVirtual:="["+LEFT(_cLinhas,Len(_cArmVirtual)-2)+"]"
		_cArmFisico :="["+LEFT(_cLinhas,Len(_cArmFisico)-2)+"]"
		If !Empty(_cLinhas)
			U_ITMsg("Para tranferir produtos entre armazens virtuais "+_cArmVirtual+" e armazens fisicos "+_cArmFisico+" nessa rotina,"+;
			" o campo de observação deve ser preenchido detalhando o motivo da transferencia nas linha "+_cLinhas,;
			"ATENÇÃO",;
			"Preencha a observação da linha com uma descrição minima de 10 caracteres",1)
			_lRet := .F.
		EndIf
	EndIf

	If GETMV("IT_BLQMOV") .And. DA261DATA > Date()
		U_ITMsg("Os movimentos com data maior que a data atual estão bloqueados.",;
				"Movimento com data maior que a data atual",;
				"Entre em contato com o departamento de TI para maiores informações.",1)
		_lRet := .F.
	EndIf
	//=====================================================
	//Verifica saldo do produto. Chamado 7816 			  |
	//=====================================================
	If _lRet 
		For x := 1 To Len(aCols)
			If aTail(aCols[x]) // Se Linha Deletada
				Loop
			EndIf
			_aSldNeg := U_VldEstRetrNeg(aCols[x,1], aCols[x,4], aCols[x,16], DA261DATA)	
			If Len(_aSldNeg) > 0
				nDIf := _aSldNeg[2] - aCols[x,16]
				aAdd(_aErro,{aCols[x,1],aCols[x,4],DToC(_aSldNeg[1]),nDif})
				_lErro := .T.
				_lRet := .F.
			EndIf
		Next x                                   
	EndIf

	If _lErro .And. !_lmt103fim
		_cItens := ""
		For y := 1 To Len(_aErro)
			_cItens += _aErro[y,3]+Space(3)+AllTrim(_aErro[y,1])+"-"+_aErro[y,2]+Space(5)+AllTrim(TRANSFORM(_aErro[y,4], "@E 999,999,999,999.99"))+CHR(13)+CHR(10)
		Next y                              
		U_ITMsg( "Quantidade requisitada é maior que o saldo no dia para o(s) produto(s): "+CHR(13)+CHR(10);
					+"DIA"+Space(13)+"PRODUTO"+Space(16)+"DIFERENCA"+CHR(13)+CHR(10)+_cItens,"Saldo Insuficiente",;
					"Verifique o saldo no Kardex.",1)
	EndIf

	//=====================================================
	//Verificacao do CM origem e Destino                  |
	//=====================================================
	If _lRet .And. !_lmt103fim .And. !_laglt003 .And. !_lMCOM004

		_nDifCM 	:= GetMV( "IT_DIFCM"  ,, 70 ) //Percentual minimo de diferenca de CM para bloquear processo. (71%)
		_nDifCM2	:= GetMV( "IT_DIFCM2" ,, 50 ) //Percentual minimo de diferenca de CM para exibir mensagem se continua ou nao. (51%)
		SB2->(DBSetOrder(1))

		For _nI := 1 To Len(aCols)
			If aTail(aCols[_nI]) // Se Linha Deletada
				Loop
			EndIf

			_nCMorig := Posicione( "SB2" , 1 , xFilial("SB2") + aCols[_nI][01] + aCols[_nI][04] , "B2_CM1" )//SEEK NO PRODUTO DE ORIGEM
			SB2->(DBSeek(xFilial("SB2") + aCols[_nI][06] + aCols[_nI][09]))//SEEK NO PRODUTO DE DESTINO
			_nCMdest := SB2->B2_CM1
		
			If _nCMdest > 0 .And. !( SB2->B2_QATU = 0 .And. SB2->B2_VATU1 = 0 )//PRODUTO DE DESTINO
		
				_nDifPrd := (_nCMdest - _nCMorig) / _nCMorig
			
				If _nDifPrd < 0
					_nDifPrd := (_nDifPrd * (-1))
				EndIf
			
				_nDifPrd := _nDifPrd * 100
			
				//====================================================================================================
				// Diferenca entre a % para exibição da mensagem e a % de bloqueio
				//====================================================================================================
				If _nDifPrd > _nDifCM2 .And. _nDifPrd <= _nDifCM
			
					aAdd( _aErro1 , { _nI , AllTrim( aCols[_nI][02] ) , _nDifPrd } )
					_lErro1 := .T.
			
				//====================================================================================================
				// Diferença maior ou igual à % de bloqueio
				//====================================================================================================
				ElseIf _nDifPrd > _nDifCM
					aAdd( _aErro2 , { _nI , AllTrim( aCols[_nI][02] ) , _nDifPrd } )
					_lErro2 := .T.
				EndIf
			EndIf
		Next _nI

		If _lErro2 .And. !_lmt103fim .And. !_laglt003 .And. !_lMCOM004
			For x := 1 To Len(_aErro2)
				_cItens += CVALTOCHAR(_aErro2[x][1])+" - "
				_cItens += CVALTOCHAR(_aErro2[x][2])+": "
				_cItens += AllTrim(TRANSFORM(_aErro2[x][3], "@E 999,999,999.9999"))+"% "+CHR(13)+CHR(10)		                  
			Next x

			U_ITMsg("Diferença entre valor de Custo Medio de Origem e Destino no(s) item(ns):"+CHR(13)+CHR(10)+_cItens,"Transferência não permitida!",;
						"Favor analisar o Kardex! Se necessário, entre em contato com o Depto. de TI.",1)
			_lRet := .F.
		ElseIf _lErro1
			For x := 1 To Len(_aErro1)
				_cItens += CVALTOCHAR( _aErro1[x][1] ) +" - "
				_cItens += CVALTOCHAR( _aErro1[x][2] ) +": "
				_cItens += AllTrim(TRANSFORM(  _aErro1[x][3] , "@E 999,999,999.9999" )) +"% "+ CHR(13) + CHR(10)
			Next x
		
			If !U_ITMsg("Diferença entre valor de Custo Medio de Origem e Destino no(s) item(ns):"+CHR(13)+CHR(10)+_cItens+"Deseja prosseguir?","ATENÇÃO!",,2,2,2)
				_lRet := .F.		
			EndIf
		EndIf
	EndIf
End Sequence

If Type("lMsErroAuto") = "L" .And. !_lRet .And. !lMsErroAuto//Só altera o conteudo do lMsErroAuto se ele tiver Falso e o retorno For falso
   lMsErroAuto:=!_lRet//Só Joga verdadeiro de For o caso
EndIf

RestOrd(_aOrd)

Return (_lRet)
