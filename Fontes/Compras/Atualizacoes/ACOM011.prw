/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |27/05/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
Alex Wallauer |05/06/2025| Chamado 50929. Ajustes para salvar a área do SC7 e restaurar ela e o recno.
Lucas Borges  |19/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACOM011
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 02/12/2015
Descrição---------: Rotina desenvolvida para Liberação Gestor de Compras
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM011

Local aArea		:= FWGetArea() As Array
Local cFilPC	:= SuperGetMV("IT_FILWFPC",.F.,"01") As Character
Local lFilPC	:= IIf(cFilAnt $ cFilPC,.T.,.F.) As Logical
Local nUsado 	:= 0 As Numeric
Local cPedido	:= SC7->C7_NUM As Character
Local oGetGrpA 	:= Nil As Object
Local oGetGrpN	:= Nil As Object
Local cGetGrpN	:= Space(TamSX3("AL_NOME")[1]) As Character
Local oGroupA	:= Nil As Object
Local oSayGrpA	:= Nil As Object
Local oSButton1	:= Nil As Object
Local oSButtonOk:= Nil As Object
Local nX,nA		:= 0 As Numeric
Local aFields		:= {"AL_ITEM","AL_COD","AL_USER","AL_NOME","AL_NIVEL","AL_TPLIBER"} As Array
Local aAlterFields	:= {} As Array
Local aColsAux		:= {} As Array
Local nOpca			:= 0 As Numeric
Local dEmissao		:= CtoD("//") As Date
Local lContinua		:= .T. As Logical

Private aHeader		:= {} As Array
Private aCols		:= {} As Array
Private oDlgApr		:= Nil As Object
Private oMSNewApr	:= Nil As Object
Private _aHeaderSAL := {} As Array
Private cGetGrpA	:= Space(TamSX3("AL_COD")[1]) As Character

Begin Sequence

	If lFilPC
		ZZL->(DBSetOrder(3))
	  	If ZZL->(DBSeek(xFilial("ZZL") + __cUserId))
			//===============================================================
			// Grava log da rotina liberação Gestor de Compras 
			//=============================================================== 
			U_ITLOGACS('ACOM011')
		
			If ZZL->ZZL_GCOM == "S"
				SC7->(DBSetOrder(1))
				If SC7->(DBSeek(xFilial("SC7") + cPedido))
					lContinua := U_ACOM011V(xFilial("SC7"), cPedido, .T.)
					If lContinua
						SC7->(DBSeek(xFilial("SC7") + cPedido))
						While SC7->(!Eof()) .And. cPedido == SC7->C7_NUM .And. SC7->C7_FILIAL == xFilial("SC7")
			         		If SC7->C7_CONAPRO == "B" .And. SC7->C7_QUJE < SC7->C7_QUANT .And. SC7->C7_APROV == "PENLIB" .And. SC7->C7_RESIDUO != 'S'
								//                     1            2         3           4          5        6        7       8       9       10          11      12        13       14         15        16   17
								// aAdd(aHeader,{trim(x3_titulo),x3_campo,x3_picture,x3_tamanho,x3_decimal,x3_valid,x3_usado,x3_tipo, x3_f3,x3_context,	x3_cbox,x3_relacao,x3_when,X3_TRIGGER,	X3_PICTVAR,.F.,.F.})
								aHeader := {}

								aCols   := {}
								For nUsado := 1 to Len(aFields)
									_cCampo:=aFields[nUsado]
									_cUsado:=Getsx3cache(_cCampo,"X3_USADO")
									If X3USO(_cUsado)
										aAdd( aHeader , {Getsx3cache(_cCampo,"X3_TITULO") ,;
														Getsx3cache(_cCampo,"X3_CAMPO") ,;
														Getsx3cache(_cCampo,"X3_PICTURE") ,;
														Getsx3cache(_cCampo,"X3_TAMANHO") ,;
														Getsx3cache(_cCampo,"X3_DECIMAL") ,;
														Getsx3cache(_cCampo,"X3_VALID") ,;
														_cUsado                         ,;
														Getsx3cache(_cCampo,"X3_TIPO") ,;
														Getsx3cache(_cCampo,"X3_F3") ,;
														Getsx3cache(_cCampo,"X3_CONTEXT") })
									EndIf
								Next nUsado
								aColsAux:= {}
      
								For nX := 1 To Len(aHeader)
									If aScan(aFields, AllTrim(aHeader[nX,2])) > 0
										aAdd(_aHeaderSAL,aHeader[nX])
										If aHeader[nX,8] == "C"      // SX3->X3_TIPO == "C"
											aAdd(aColsAux, "")
										ElseIf aHeader[nX,8] == "N"  // SX3->X3_TIPO == "N"
											aAdd(aColsAux, 0)
										ElseIf aHeader[nX,8] == "D"  // SX3->X3_TIPO == "D"
											aAdd(aColsAux, SToD(""))
										EndIf
									EndIf
								Next nX
			
								aAdd(aColsAux, .F.)
								aAdd(aCols, aColsAux)
								aHeader := AClone(_aHeaderSAL)
								_cF3:="SAL"

								SY1->(DBSetOrder(3))
								If SY1->(DBSeek(xFilial("SY1") + SC7->C7_USER))
									_cGrpLeite:= ACOM11_ZP1("IT_GRPLEIT")
									If SY1->Y1_GRUPCOM $ _cGrpLeite
										_cGrpALeite:= AllTrim(SuperGetMV("IT_GRPALEI",.F.,""))							  
										If !Empty(_cGrpALeite)
											_cF3:="F3ITLC"
											_cSelecSAL:="SELECT DISTINCT AL_COD , AL_DESC  , AL_USER , AL_NIVEL  FROM "+RETSQLNAME("SAL")+" SAL WHERE D_E_L_E_T_ = ' ' AND AL_MSBLQL <> '1'  AND  AL_COD IN " + FormatIn(_cGrpALeite,";") +" ORDER BY AL_COD , AL_NIVEL " 
											_aItalac_F3:={}//       1           2         3                      4                      5                                          6                   7         8          9         10         11        12
											//  (_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave            , _nCpoDesc              ,_bCondTab                               , _cTitAux           , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
											aAdd(_aItalac_F3,{"cGetGrpA" ,_cSelecSAL,{|Tab| (Tab)->AL_COD }, {|Tab| UsrRetName((Tab)->AL_USER)  +" // "+AllTrim((Tab)->AL_DESC)+" // "+(Tab)->AL_NIVEL}  , ,"Grupo Aprovadores" ,          ,          , 1        ,.F.        ,       , } )
										EndIf
									EndIf						   
								EndIf
								SAJ->(DBSetOrder(1))
		
								DEFINE MSDIALOG oDlgApr TITLE "Grupos de Aprovação" FROM 000, 000  TO 205, 500 COLORS 0, 16777215 PIXEL

									@ 005, 006 Say oSayGrpA PROMPT "Grupo Aprovador" SIZE 044, 007 OF oDlgApr COLORS 0, 16777215 PIXEL
									@ 005, 054 MSGET oGetGrpA VAR cGetGrpA SIZE 032, 010 OF oDlgApr COLORS 0, 16777215 F3 _cF3 VALID {|| ACOM011F(cGetGrpA, @cGetGrpN)} PIXEL
									@ 017, 054 MSGET oGetGrpN VAR cGetGrpN SIZE 158, 010 OF oDlgApr COLORS 0, 16777215 PIXEL
									@ 031, 003 GROUP oGroupA TO 086, 246 PROMPT "Aprovadores" OF oDlgApr COLOR 0, 16777215 PIXEL
									oMSNewApr := MsNewGetDados():New( 038, 007, 083, 242, 0, "AllwaysTrue", "AllwaysTrue", "", aAlterFields,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlgApr, aHeader, aCols)
									DEFINE SBUTTON oSButtonOk FROM 089, 091 Type 01 OF oDlgApr ENABLE Action (nOpca := 1, oDlgApr:End())
									DEFINE SBUTTON oSButton1 FROM 089, 120 Type 02 OF oDlgApr ENABLE Action oDlgApr:End()
			
								ACTIVATE MSDIALOG oDlgApr CENTERED
									
								If nOpca == 1
									Begin Transaction
										DBSelectArea("SC7")
										SC7->(DBSetOrder(1))
				
										If SC7->(DBSeek(xFilial("SC7") + cPedido))
											//Grava aprovador no Sc7
											_nTotPed:=0
											_nItem:=0
											MaFisEnd()
											aRefImp	:= MaFisRelImp('MT100',{"SC7"})
											aStru		:= FWFormStruct(3,"SC7")[1]

											While SC7->(!Eof()) .And. cPedido == SC7->C7_NUM .And. SC7->C7_FILIAL == xFilial("SC7")
												MaFisIni(SC7->C7_FORNECE,SC7->C7_LOJA,"F","N","R",aRefImp)						
												MaFisIniLoad(1)
												_nItem++
												For nA := 1 To Len(aRefImp)
													nPos := aScan(aStru,{|x| AllTrim(x[3]) == AllTrim(aRefImp[nA][2])})
													If nPos > 0 .And. !aStru[nPos,14]
														MaFisLoad(aRefImp[nA][3],SC7->(&(aRefImp[nA][2])),1)
													EndIf
												Next nA
												MaFisRecal("",1)
												MaFisEndLoad(1)
												MaFisAlt("IT_ALIQIPI",SC7->C7_IPI    ,1)
												MaFisAlt("IT_ALIQICM",SC7->C7_PICM   ,1)
												MaFisAlt("IT_VALSOL" ,SC7->C7_ICMSRET,1)
												MaFisWrite(1,"SC7",1)
												_nTotPed += MaFisRet(1,"IT_TOTAL")
												MaFisEnd()
		
												dEmissao := SC7->C7_EMISSAO
												SC7->(RecLock("SC7",.F.))
												SC7->C7_APROV   := cGetGrpA
												SC7->C7_I_GCOM  := __cUserId
												SC7->C7_I_DTLIB := Date()
												SC7->C7_I_HRLIB := Time()
												SC7->(MSUnLock())
												SC7->(DBSkip())
											EndDo

											//Inclui linhas de aprovador no SCR
											SAL->(DBSetOrder(2))//AL_FILIAL+AL_COD+AL_NIVEL
											If SAL->(DBSeek(xFilial("SAL")+cGetGrpA))
												nConta:=0
												While !(SAL->(Eof())) .And. AllTrim(cGetGrpA) == SAL->AL_COD
													If SAL->AL_MSBLQL = '1' 
														SAL->(DBSkip())  
														Loop									   
													EndIf										     
													nConta++
													SCR->(RecLock("SCR",.T.))
													SCR->CR_FILIAL := xFilial("SCR")
													SCR->CR_num 	:= cPedido
													SCR->CR_TIPO 	:= "PC"
													SCR->CR_USER	:= SAL->AL_USER
													SCR->CR_APROV	:= SAL->AL_APROV
													SCR->CR_NIVEL	:= SAL->AL_NIVEL
													SCR->CR_STATUS	:= If(nConta > 1 ,'01','02')//Não olhamos o nivel mais pq o aprovador anterior pode esta bloqueado
													SCR->CR_EMISSAO:= DDATABASE
													SCR->CR_MOEDA	:= 1
													SCR->CR_TXMOEDA:= 1
													SCR->CR_GRUPO 	:= cGetGrpA
													SCR->CR_TOTAL 	:= _nTotPed
													SCR->(MSUnLock())
														
													SAL->(DBSkip())
												EndDo
											EndIf
										EndIf
										FWAlertSuccess('Processo concluído com sucesso.',"ACOM01101")
									End Transaction
								Else
									FwRestArea(aArea)
									Break 
								EndIf
							ElseIf SC7->C7_RESIDUO == 'S'
								FWAlertInfo("Pedido de Compras eliminado por residuo. Verifique a Situação atual do Pedido de Compras.","Liberação PC - Gestor de Compras - ACOM01102")
								FwRestArea(aArea)
								Break 
							Else
								FWAlertInfo("Pedido de Compras já liberado pelo Gestor de Compras. Verifique a Situação atual do Pedido de Compras.","Liberação PC - Gestor de Compras - ACOM01103")
								FWRestArea(aArea)
								break
							EndIf
				
							SC7->(DBSkip())
						EndDo
					EndIf
			 	EndIf
		  Else
			 FWAlertWarning( __cUserId + " - " + cUserName + ", sem permissão para utilizar esta funcionalidade. "+;
					"Por favor comunicar a área de Compras que é responsável por solicitar para TI a liberação desta funcionalidade.","Liberação PC - Gestor de Compras - ACOM01104")
			 FWRestArea(aArea)
			 Break
		  EndIf
	   Else
		  FWAlertWarning( __cUserId + " - " + cUserName + ", sem permissão para utilizar esta funcionalidade. "+;
			       "Por favor comunicar a área de Compras que é responsável por solicitar para TI a liberação desta funcionalidade.","Liberação PC - Gestor de Compras - ACOM01105")
		  FwRestArea(aArea)
	  	  Break // Return
	   EndIf
    Else
	     FWAlertWarning("Filial não habilitada para aprovação de pedido de compras. "+;
				 "Filial não habilitada para aprovação de pedido de compras para TI a liberação desta filial.","Liberação PC - Gestor de Compras - ACOM01106")
    EndIf
End Sequence

FwRestArea(aArea)

Return

/*
===============================================================================================================================
Programa----------: ACOM011F
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 02/12/2015
Descrição---------: Função criada para carregamento do grid
Parametros--------: cGetGrpA - Código do grupo
                    cGetGrpN - Nome do grupo
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ACOM011F(cGetGrpA As Character, cGetGrpN As Character)

Local aArea	    := FWGetArea() As Array
Local cQuery    := "" As Character
Local cAlias	:= GetNextAlias() As Character
Local nX		:= 0 As Numeric
Local aColsAux	:= {} As Array
Local aForaLim	:= {} As Array
Local lRet		:= .T. As Logical
Local _cNome	:= "" As Character
Local _cObs		:= "" As Character
Local _cAlias   := GetNextAlias() As Character
Local _cPV      := SC7->C7_NUM As Character
Local _bGetMv   := {|x| GETMV("MV_SIMB"+x )} As Codeblock

cQuery := "SELECT R_E_C_N_O_ SALREC "
cQuery += "FROM " + RetSqlName("SAL") + " "
cQuery += "WHERE AL_FILIAL = '" + xFilial("SAL") + "' "
cQuery += "  AND AL_COD = '" + cGetGrpA + "' "
cQuery += "  AND AL_MSBLQL = '2' "
cQuery += "  AND D_E_L_E_T_ = ' ' "
cQuery += "  ORDER BY AL_COD, AL_NIVEL  "
cQuery := ChangeQuery(cQuery)
MPSysOpenQuery(cQuery,cAlias)

(cAlias)->( DBGoTop() )

If (cAlias)->( !Eof() )
	oMSNewApr:aCols := {}
	
	BeginSql Alias _cAlias
		SELECT SUM(SC7.C7_TOTAL) C7TOTAL
		FROM %Table:SC7% SC7
		WHERE SC7.C7_FILIAL=%xFilial:SC7% AND	SC7.C7_NUM = %Exp:_cPV% AND
		SC7.%NotDel%
	EndSql
	_nTotal:=(_cAlias)->C7TOTAL
	(_cAlias)->(DBCloseArea())
	DHL->(DBSetOrder(1))
	
	While (cAlias)->( !Eof() )
		
		SAL->(DBGoTo( (cAlias)->SALREC) )
		cGetGrpN := SAL->AL_DESC
		_cNome:=Posicione("SAK",2,xFilial("SAK")+SAL->AL_USER,"AK_NOME")

		_nLimPerfil:=0
		_cMoePV :=AllTrim(Eval(_bGetMV, Str(SC7->C7_MOEDA,1)))
		_cMoeDHL:=""
		If DHL->(MsSeek(xFilial("DHL")+SAL->AL_PERFIL))//Perfil
			_nLimPerfil:=DHL->DHL_LIMMAX
			_cMoeDHL:=AllTrim(Eval(_bGetMv,Str(DHL->DHL_MOEDA,1)))
			_cObs:=""
			If _nTotal > _nLimPerfil
				_cObs:=" - Acima do Limite"
			EndIf
			If SC7->C7_MOEDA <> DHL->DHL_MOEDA
				_cObs+=" - Moeda diferente"
			EndIf
	    Else
	       _cObs:=" - Perfil não encontrado nessa filial: "+xFilial("DHL")+" "+SAL->AL_PERFIL
	    EndIf
		If !Empty(_cObs)
			aAdd(aForaLim,{.F. , _cNome , _cMoeDHL+" "+Str(_nLimPerfil,15,2) , _cMoePV+" "+Str(_nTotal,15,2), _cObs})
			lRet := .F.
		Else
			aAdd(aForaLim,{.T. , _cNome , _cMoeDHL+" "+Str(_nLimPerfil,15,2) , _cMoePV+" "+Str(_nTotal,15,2), "OK" })
		EndIf
		
		aColsAux := {}
		For nX := 1 To Len(aHeader)
			If AllTrim(aHeader[nX,2]) == "AL_NOME"
				aAdd(aColsAux, _cNome)
			ElseIf aHeader[nX,8] == "D" 
				aAdd(aColsAux, SToD(SAL->&(aHeader[nX,2])))
			Else
				aAdd(aColsAux, SAL->&(aHeader[nX,2]) )
			EndIf
		Next nX
		aAdd(aColsAux, .F.)
		aAdd(oMSNewApr:aCols, aColsAux)
		
		(cAlias)->(DBSkip())
	EndDo
Else
	FWAlertWarning("Grupo informado não existe, favor informar um código de grupo existente.","Liberação PC - Gestor de Compras - ACOM01107")
	lRet := .F.
EndIf

If Len(aForaLim) > 0 .And. !lRet
	
	bBloco:={|| U_ITListBox('Lista de aprovadores com limite de aprovação',;
	        {" ",'Aprovador','Limite','Total PV',"Observação"},aForaLim,.F.,4,,,;
	        { 10,         90,      50,        50,         90}) }
	
	U_ITMsg("A indicação não poderá ser feita para este grupo de aprovação...",'Atenção!',;
	        "Pois existe aprovador que não tem limite suficiente para aprovar o valor do pedido ou a moeda do perfil é diferente: VER Mais Detalhes",1,,,,,,bBloco)
	
	lRet := .F.
	
EndIf

(cAlias)->( DBCloseArea() )

oMSNewApr:oBrowse:Refresh()
oMSNewApr:Refresh()
FWRestArea(aArea)

Return(lRet)

/*
===============================================================================================================================
Programa----------: ACOM011V
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 26/02/2016
Descrição---------: Função criada para exibir as inconsistências entre Valor Unitário x Última Compra
Parametros--------: _cFilial - Filial do Pedido de Compras
                    _cPedido - Número do Pedido de Comrpas
                    _lLibera - .T. Mostra a tela de liberação, .F. caso contrário
Retorno-----------: lRet	- .T. continua com o processo de liberação pelo gestor, .F. caso contrário
===============================================================================================================================
*/
User Function ACOM011V(_cFilial As Character, _cPedido As Character, _lLibera As Logical)

Local aArea	  	:= FWGetArea() As Array
Local aSC7Area	:= SC7->(FWGetArea()) As Array
Local lRet		:= .T. As Logical
Local nPtol		:= SuperGetMV("IT_PTOLP3",.F.,0) As Numeric

Local aCampPla	:= {	'Índice',;
						'Filial',;
						'Num PC',;
						'Item',;
						'Quantidade',;
						'Prc Unitário',;
						'Vlr. Total',;
						'Ult. Preço',;
						'Diferença %',;
						'Dt. Emissão',;
						'Urgente',;
						'Aplicação',;
						'Produto',;
						'Descrição',;
						'Unidade',;
						'Dt Ult. Compra',;
						'Fornecedor',;
						'N Fantasia',;
						'Dt Faturado',;
						'Cod.Investim',;
						'Des.Investim',;
						'Observações'} As Array

Local aLogPla	:= {} As Array
Local nCont		:= 1 As Numeric
Local _cGrupoItem  := '' as Character
Local _cGrpNaoObrigat :=SuperGetMV("IT_GRPNOBR",.F.,"1000") As Character

DBSelectArea('SC7')
SC7->(DBSetOrder(1))
SC7->(DBSeek(_cFilial + _cPedido))

While !SC7->(Eof()) .And. SC7->C7_FILIAL == _cFilial .And. SC7->C7_NUM == _cPedido

	DBSelectArea("SBZ")
	SBZ->(DBSetOrder(1))
	SBZ->(DBSeek(xFilial("SBZ") + SC7->C7_PRODUTO))
	
	_cGrupoItem := Posicione("SB1",1,xFilial("SB1")+SC7->C7_PRODUTO,"B1_GRUPO") 

	If SBZ->BZ_UPRC > 0  .And. !(_cGrupoItem $ _cGrpNaoObrigat) 
        _nPrecoRS:=SC7->C7_PRECO
        If SC7->C7_MOEDA <> 1
           _nPrecoRS:=SC7->C7_PRECO*SC7->C7_TXMOEDA
        EndIf

		If IIf( SBZ->BZ_UPRC > _nPrecoRS, ( ( SBZ->BZ_UPRC * 100 ) / _nPrecoRS ) - 100 > nPtol, ( ( SBZ->BZ_UPRC * 100 ) / _nPrecoRS ) - 100 < ( - nPtol ) )
			aAdd( aLogPla , {	StrZero(nCont++,4),;																						//[1]Índice
								SC7->C7_FILIAL + " - " + AllTrim(FWFilialName(cEmpAnt,SC7->C7_FILIAL,1)),;									//[2]Filial
								SC7->C7_NUM,;																								//[3]Num PC
								SC7->C7_ITEM,;												 												//[4]Item
								AllTrim(Transform(SC7->C7_QUANT,PesqPict("SC7","C7_QUANT"))),;												//[5]Quantidade
								AllTrim(Transform(_nPrecoRS,PesqPict("SBZ","BZ_UPRC"))),;												//[6]Preço Unitário
								AllTrim(Transform(SC7->C7_TOTAL,PesqPict("SC7","C7_TOTAL"))),;												//[7]Valor Total
								AllTrim(Transform(SBZ->BZ_UPRC,PesqPict("SBZ","BZ_UPRC"))),;												//[8]Último Preço
								AllTrim(Transform((((_nPrecoRS - SBZ->BZ_UPRC) / SBZ->BZ_UPRC) * 100), PesqPict("SBZ","BZ_UPRC"))),;	//[9]Diferença
								DToC(SC7->C7_EMISSAO),;																						//[10]Emissão
								SC7->C7_I_URGEN,;												  											//[11]Urgente
								SC7->C7_I_APLIC,;												  											//[12]Aplicação
								SC7->C7_PRODUTO,;																							//[13]Produto
								SC7->C7_DESCRI,;																							//[14]Descrição
								SC7->C7_UM,;																								//[15]Unidade
								DToC(SBZ->BZ_UCOM),;																						//[16]Data Última Compra
								SC7->C7_FORNECE,;										   													//[17]Fornecedor
								Posicione("SA2",1,xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA,"A2_NREDUZ"),;								//[18]Nome Reduzido
								DToC(SC7->C7_I_DTFAT),;											 											//[19]Dt Faturado
								SC7->C7_I_CDINV,;												 											//[20]Código Investimento
								Posicione("ZZI",1,xFilial("ZZI")+SC7->C7_I_CDINV,"ZZI_DESINV"),;											//[21]Descrição Investimento
								SC7->C7_OBS})														   										//[22]Observação
		EndIf
	EndIf
	SC7->(DBSkip())
EndDo

If Len(aLogPla) > 0
	lRet := .F.
	FWAlertWarning('Este pedido contém inconsistência entre o Valor Unitário x Última Compra. Serão apresentadas as inconsistências na próxima tela.',"ACOM01108")
	U_ITListBox( 'Inconsistência Valor Unitário x Última Compra (Tolerância: ' + AllTrim(Str(nPtol)) + ' %)' , aCampPla , aLogPla , .T. , 1 )
	If _lLibera
		If FWAlertYesNo('Este Pedido contém diferenças fora da tolerância entre os valores da última compra e o preço unitário. Deseja Liberar este pedido mesmo assim ?',"ACOM01109")
			lRet := .T.
		EndIf
	EndIf
EndIf

FwRestArea(aArea)
FwRestArea(aSC7Area)
Return(lRet)

/*
===============================================================================================================================
Programa----------: ACOM11_ZP1
Autor-------------: Alex Walluer
Data da Criacao---: 29/03/2022
Descrição---------: Rotina que faz a leitura do parâmetro do ZP1 de todas as filiais
Parametros--------: Parâmetro: parâmetro
Retorno-----------: _cLista
===============================================================================================================================
*/
Static Function ACOM11_ZP1(_cParam As Character)

Local _cLista	:= "" As Character
Local _cQuery	:= "" As Character
Local _cAlias	:= GetNextAlias() As Character

_cQuery := " SELECT * "
_cQuery += " FROM  "+ RetSqlName('SX6') +" SX6 "
_cQuery += " WHERE X6_VAR = '"+ _cParam +"' "
_cQuery += "   AND D_E_L_E_T_ = ' ' "
_cQuery := ChangeQuery(_cQuery)
MPSysOpenQuery(_cQuery,_cAlias)

(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() ) 
   _cLista+=AllTrim((_cAlias)->X6_CONTEUD)+";"
   (_cAlias)->( DBSkip() )
EndDo
(_cAlias)->( DBCloseArea() )

Return( _cLista )

/*
===============================================================================================================================
Programa----------: ACOM11QBG
Autor-------------: Alex Wallauer
Data da Criacao---: 12/04/2022
Descrição---------: Gravção do campo CR_TOTAL
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ACOM11QBG()

Local nA 		:= 0 As Numeric
Local _aParRet	:= {} As Array
Local _aParAux	:= {} As Array
Local _bOK		:= {|| .T. } As Codeblock
Local _cTimeIni	:= Time() As Character
Local _cTitAux	:= "QBG de Aprovações" As Character
Local _aStatus	:= {"1-Todos     ","2-Abertos   ","3-Encerrados"} As Array

MV_PAR01:=CTOD("01/01/2020")
MV_PAR02:=DDATABASE
MV_PAR03:=Space(100)
MV_PAR04:=_aStatus[1]

aAdd( _aParAux , { 1 , "Data Inicial", MV_PAR01, "@D", "", ""	, "" , 050 , .F.  })
aAdd( _aParAux , { 1 , "Data Final"	 , MV_PAR02, "@D", "", ""	, "" , 050 , .F.  })
aAdd( _aParAux , { 1 , "Filial"      , MV_PAR03, "@!"  , ""  ,"LSTFIL", "" , 100 , .F. } ) 
aAdd( _aParAux , { 2 , "Status PC"   , MV_PAR04, _aStatus, 060   ,".T.",.T. ,".T."}) 

For nA := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nA][03] )
Next nA

While .T.
							//aParametros, cTitle                                , @aRet    ,[bOk], [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
	If !ParamBox( _aParAux , _cTitAux, @_aParRet, _bOK, /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
		Return .F.
	EndIf

	_aDados:={}

	FWMsgRun( ,{|oproc| _aDados := ACOM11QBG(oproc) } , "Aguarde!" , "Hor Inicial: "+_cTimeIni+" / Executando a SELECT Andre..." )

	If Len(_aDados) > 0
		aCab:={}
		aAdd(aCab," ")
		aAdd(aCab,"Filial")
		aAdd(aCab,"Pedido")
		aAdd(aCab,"Dt Emissao")
		aAdd(aCab,"Status")
		aAdd(aCab,"Dt Liberacao")
		aAdd(aCab,"Cod. User")
		aAdd(aCab,"Cod. Aprov")
		aAdd(aCab,"Valor SCR")
		aAdd(aCab,"Valor PC")
		aAdd(aCab,"Reg SCR")
		
		_cTitulo2:=_cTitAux+' - Data: ' + DToC(Date()) 
		_cMsgTop:="Par. 1: "+AllTrim(AllToChar(MV_PAR01))+"; Par. 2: "+AllTrim(AllToChar(MV_PAR02))+" -  H.I.: "+_cTimeIni+" H.F.: "+Time()

		If U_ITListBox( _cTitulo2 , aCab , _aDados , .T. , 2 , _cMsgTop)
			_nConta:=0
			For nA := 1 To Len( _aDados )
				
				If _aDados[nA,1] .And. !Empty(_aDados[nA,Len(_aDados[nA] )-1])
					SCR->(DBGoTo( _aDados[nA,Len(_aDados[nA] )]) )
					If MV_PAR04 = "3" // ENCERRADOS
						If SCR->CR_STATUS  = "03" .And. !Empty(_aDados[nA,Len(_aDados[nA] )-1])// APROVADO - "Nível Aprovado"
							SCR->(RecLock("SCR",.F.))
							SCR->CR_TOTAL   := _aDados[nA,Len(_aDados[nA] )-1]
							SCR->CR_TIPOLIM := Posicione("SAK",1,xFilial("SAK")+SCR->CR_LIBAPRO,"AK_TIPO")
							SCR->(MSUnLock())
							_nConta++
						EndIf
					Else
						SCR->(RecLock("SCR",.F.))
						SCR->CR_TOTAL:=_aDados[nA,Len(_aDados[nA] )-1]
						SCR->(MSUnLock())
						_nConta++
					EndIf
				EndIf
			Next nA
			FWAlertSuccess('Processo concluído com sucesso. Registros atualizados: '+CValToChar(_nConta),"ACOM01110")
		EndIf
	Else
		FWAlertInfo('Não há registros.',"ACOM01111")
	EndIf
EndDo

Return

/*
===============================================================================================================================
Programa----------: ACOM11QBG
Autor-------------: Alex Wallauer
Data da Criacao---: 12/04/2022
Descrição---------: Gravção do campo CR_TOTAL
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ACOM11QBG(oproc As Object)

Local _cQuery	:= "" As Character
Local _cAlias	:= GetNextAlias() As Character
Local nA 		:= 0 As Numeric
Local _cPict 	:= PesqPict("SCR","CR_TOTAL") As Character

_cQuery := " SELECT "
_cQuery += " DISTINCT CR_FILIAL, CR_NUM  "	  
_cQuery += " FROM "+ RetSqlName("SCR") +" SCR "+ CRLF
_cQuery += " WHERE D_E_L_E_T_ = ' ' "
If MV_PAR04 = "2"     // ABERTOS
   _cQuery += " AND CR_DATALIB = '  ' "
ElseIf MV_PAR04 = "3"     // ENCERRADOS
   _cQuery += " AND CR_DATALIB <> '  ' "
EndIf
_cQuery += "    AND CR_TIPO = 'PC' "
_cQuery += "    AND CR_TOTAL <= 0 "
If !Empty(MV_PAR01)
   _cQuery += "   AND CR_EMISSAO >= '" + DToS(MV_PAR01) + "' "
EndIf
If !Empty(MV_PAR02)
   _cQuery += "   AND CR_EMISSAO <= '" + DToS(MV_PAR02) + "' "
EndIf
If !Empty(MV_PAR03)
   _cQuery += "   AND CR_FILIAL IN "+FormatIn(AllTrim(MV_PAR03),";")"
EndIf

_cQuery += "   ORDER BY CR_FILIAL, CR_NUM  "
_cQuery := ChangeQuery(_cQuery)

MPSysOpenQuery( _cQuery,_cAlias )

DBSelectArea(_cAlias)
_nTot:=nConta:=0
COUNT TO _nTot
_cTot:=AllTrim(Str(_nTot))
_cAlias->(DBGoTop())

SC7->(DBSetOrder(1))
SCR->(DBSetOrder(1)) //CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
_aDados:={}
While (_cAlias)->(!Eof())
	_cFilial:=(_cAlias)->CR_FILIAL
	cPedido:=AllTrim((_cAlias)->CR_NUM )
	nConta++
	oproc:cCaption := ("Lendo PC: "+_cFilial+" "+cPedido+" - "+StrZero(nConta,5) +" de "+ _cTot )
	ProcessMessages()

	If SC7->(DBSeek(_cFilial + cPedido))
		If MV_PAR04 = "3" // ENCERRADOS
			If !SC7->C7_ENCER = 'E'//IGNORA ABERTOS
				(_cAlias)->(DBSkip())
				Loop	
			EndIf
		EndIf

		_nTotPed:=0
		MaFisEnd()
		aRefImp	:= MaFisRelImp('MT100',{"SC7"})
		aStru		:= FWFormStruct(3,"SC7")[1]
		While (!Eof()) .And. cPedido == SC7->C7_NUM .And. SC7->C7_FILIAL == _cFilial
		
			MaFisIni(SC7->C7_FORNECE,SC7->C7_LOJA,"F","N","R",aRefImp)						
			MaFisIniLoad(1)
			For nA := 1 To Len(aRefImp)
				nPos := aScan(aStru,{|x| AllTrim(x[3]) == AllTrim(aRefImp[nA][2])})
				If nPos > 0 .And. !aStru[nPos,14]
					MaFisLoad(aRefImp[nA][3],SC7->(&(aRefImp[nA][2])),1)
				EndIf
			Next nA
			
			MaFisRecal("",1)
			MaFisEndLoad(1)
			MaFisAlt("IT_ALIQIPI",SC7->C7_IPI    ,1)
			MaFisAlt("IT_ALIQICM",SC7->C7_PICM   ,1)
			MaFisAlt("IT_VALSOL" ,SC7->C7_ICMSRET,1)
			MaFisWrite(1,"SC7",1)
			_nTotPed += MaFisRet(1,"IT_TOTAL")
			MaFisEnd()

			SC7->(DBSkip())
		EndDo
		
		SC7->(DBSeek(_cFilial + cPedido))
		If SCR->(DBSeek(SC7->C7_FILIAL+"PC"+AllTrim(SC7->C7_NUM)))
			While !(SCR->(Eof())) .And. SC7->C7_FILIAL == SCR->CR_FILIAL .And. SCR->CR_TIPO == 'PC' .And. AllTrim(SCR->CR_NUM) == AllTrim(SC7->C7_NUM)

				_aItem:={}
				aAdd(_aItem,.T.)                             //01
				aAdd(_aItem,SCR->CR_FILIAL)                  //02
				aAdd(_aItem,AllTrim(SCR->CR_NUM))            //03
				aAdd(_aItem,DToC(SCR->CR_EMISSAO))           //04
				aAdd(_aItem,SCR->CR_STATUS)                  //04
				aAdd(_aItem,DToC(SC7->C7_I_DTLIB))           //05
				aAdd(_aItem,SCR->CR_USER)                    //06
				aAdd(_aItem,SCR->CR_APROV)                   //07
				aAdd(_aItem,Transform(SCR->CR_TOTAL,_cPict) )//08 
				aAdd(_aItem,0 )                              //09
				aAdd(_aItem,SCR->(RECNO()))                  //10      
				
				aAdd(_aDados,_aItem)

				SCR->(DBSkip())
			EndDo
		EndIf

		If MV_PAR04 = "3" // ENCERRADOS
			If _aDados[ Len(_aDados) , 04 ] = "03"// CR_STATUS -> APROVADO - "Nível Aprovado"
				_aDados[ Len(_aDados) , 09 ] := _nTotPed
			EndIf
		EndIf
	EndIf
	(_cAlias)->(DBSkip())
EndDo

Return _aDados
