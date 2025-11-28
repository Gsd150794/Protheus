/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |05/04/2023| Chamado 43473. Poder escolher "F" ou "S" para a condicional If(cAplicDireta="S" e cAplic <> "I").
Alex Walaluer |20/03/2025| Chamado 50253. Incluir nome do comprador na tela da solicitação de compras.
Alex Wallauer |04/09/2025| Chamado 51785. Ajustes dos campos custumizados da capa para não sobrepor e para o tema Dark.
================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT110TEL
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 24/08/2015
Descrição---------: Ponto de Entrada desenvolvido para colocar nos campos na enchoice da Solicitação de Compras.
Parametros--------: ParamIXB[1] = Objeto da tela/Dialog.
                    ParamIXB[2] = Array das coordenadas do objeto da dialog da Solicitação de Compras
                    ParamIXB[3] = Opção selecionada na Solicitação de Compras (inclusão, alteração, exclusão, etc.)
                    ParamIXB[4] = Posição do registro atual na tela(Tabela SC1).
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT110TEL

Local aArea      := FWGetArea()   As Array
Local oNewDialog := PARAMIXB[1] As Object
Local aPosGet    := PARAMIXB[2] As Array
Local nOpcx      := PARAMIXB[3] As Numeric
Local nReg       := PARAMIXB[4] As Numeric
Local _nLin2   As Numeric
Local _nLin3   As Numeric
Local _nLin4   As Numeric
Local nColAlt  As Numeric
Local nColLag  As Numeric
Local nComLag  As Numeric
Local nLarg    As Numeric
Local nLarg1   As Numeric
Local nSoma    As Numeric
Local _nI      As Numeric
Local _nPosDATPRF := aScan(aHeader, {|x| Alltrim(x[2]) == "C1_DATPRF"})  As Numeric
Local _nPosULTPR  := aScan(aHeader, {|x| Alltrim(x[2]) == "C1_I_ULTPR"}) As Numeric
Local _nPosULTDT  := aScan(aHeader, {|x| Alltrim(x[2]) == "C1_I_ULTDT"}) As Numeric
Local _nPosProd   := aScan(aHeader, {|x| Alltrim(x[2]) == "C1_PRODUTO"}) As Numeric
Local _lWhen:=.F. As Logical

Public cAplicDireta := "N" //ALEX CHAMADO 31462 - Tirar se esse chamado nao For para producao
Public cAplic		:= ""
Public cCCust		:= Space(TamSX3("C1_CC")[1])
Public cDsCus		:= Space(TamSX3("CTT_DESC01")[1])
Public cUrgen		:= "N"//ALEX CHAMADO 31462 - Tirar se esse chamado nao For para producao
Public cAprov		:= Space(TamSX3("ZZ7_CODUSR")[1])   
Public cDsApr		:= Space(TamSX3("ZZ7_NOME")[1])
Public cCInve		:= Space(TamSX3("C1_I_CDINV")[1])
Public cCInve2		:= Space(TamSX3("C1_I_CDINV")[1])
Public cCInve3		:= Space(TamSX3("C1_I_CDINV")[1])
Public cDsInv		:= Space(TamSX3("C1_I_DSINV")[1])
Public cDsInv2		:= Space(TamSX3("C1_I_DSINV")[1])
Public cDsInv3		:= Space(TamSX3("C1_I_DSINV")[1])
Public cObsSC		:= Space(100)
Public cClaim		:= "2"//CLAIM
Public _cNomeCompr  := Space(100)

Private oSInve
Private oCInve
Private oDsInv
Private oSInve2
Private oCInve2
Private oDsInv2	
Private oSInve3
Private oCInve3
Private oDsInv3

_cSelZZI_N2 := {||"SELECT ZZI_CODINV , ZZI_DESINV FROM "+RETSQLNAME("ZZI")+" ZZI WHERE D_E_L_E_T_ = ' ' AND ZZI_MSBLQL <> '1' AND ZZI_INVPAI = '" + cCInve + "' AND ZZI_TIPO = '2'  ORDER BY ZZI_CODINV  "}
_aItalac_F3 := {} //       1           2         3                      4                      5               6                    7         8          9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela ,_nCpoChave              , _nCpoDesc              ,_bCondTab    , _cTitAux         , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3    ,{"CCINVE2" ,_cSelZZI_N2 ,{|Tab|(Tab)->ZZI_CODINV},{|Tab|(Tab)->ZZI_DESINV}, ,"Investimento Nivel 2"        ,          ,          ,1        ,.F.        ,       , } )

_cSelZZI_N3 := {||"SELECT ZZI_CODINV , ZZI_DESINV FROM "+RETSQLNAME("ZZI")+" ZZI WHERE D_E_L_E_T_ = ' ' AND ZZI_MSBLQL <> '1' AND ZZI_INVPAI = '" + cCInve + "' AND ZZI_NIVEL2 = '" + cCInve2 + "' AND ZZI_TIPO = '3' ORDER BY ZZI_CODINV  "}
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela ,_nCpoChave              , _nCpoDesc              ,_bCondTab    , _cTitAux         , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3    ,{"CCINVE3" ,_cSelZZI_N3 ,{|Tab|(Tab)->ZZI_CODINV},{|Tab|(Tab)->ZZI_DESINV}, ,"Investimento Nivel 3"        ,          ,          ,1        ,.F.        ,       , } )

If nOpcx <> 3 
    SC1->(DBGoTo(nReg))
	cAplic	:= SC1->C1_I_APLIC
	cCCust	:= SC1->C1_CC
	cDsCus	:= Posicione("CTT",1,xFilial("CTT") + SC1->C1_CC, "CTT_DESC01")
	cUrgen	:= SC1->C1_I_URGEN
	cAprov	:= SC1->C1_I_CODAP
	cDsApr	:= Posicione("ZZ7",1,xFilial("ZZ7") + SC1->C1_I_CODAP, "ZZ7_NOME")
	cCInve	:= SC1->C1_I_CDINV
	cDsInv	:= Posicione("ZZI",1,xFilial("ZZI") + SC1->C1_I_CDINV, "ZZI_DESINV")
	cObsSC	:= SC1->C1_I_OBSSC
    cClaim	:= SC1->C1_I_CLAIM//CLAIM
    _lWhen  := .T.
    _cNomeCompr:=AllTrim(Posicione("SY1",1,xFilial("SY1")+cCodCompr,"Y1_NOME"))
Else
    _lWhen  := !MT110WIZ() //Criação do WizardControl(). Chamado 31472 - Tirar se esse chamado nao For para producao
EndIf
If Empty(cClaim) 
   cClaim:= "2"
EndIf

//===================================================================================
// Limpa o conteúdo dos campos abaixo quando For cópia de solicitação de compras. 
// Carregar da tabela SBZ, quando localizado, o ultimo preço do item e data da 
// ultima compra:
// C1_DATPRF  - Necessidade   - tipo data
// C1_I_ULTPR - Ultimo preço  - tipo numerico
// C1_I_ULTDT - Ultima compra - tipo data
//===================================================================================
If nOpcx <> 2 .And. !Inclui .And. !Altera .And. lCopia
   SBZ->(DBSetOrder(1))
   For _nI := 1 To Len(aCols)
       aCols[_nI,_nPosDATPRF] := Ctod("  /  /  " ) 

       If SBZ->(DBSeek(xFilial("SBZ")+aCols[_nI,_nPosProd]))
          aCols[_nI,_nPosULTPR]  := SBZ->BZ_UPRC
          aCols[_nI,_nPosULTDT]  := SBZ->BZ_UCOM
       Else
          aCols[_nI,_nPosULTPR]  := 0
          aCols[_nI,_nPosULTDT]  := Ctod("  /  /  " ) 
       EndIf
   Next
EndIf

//=========================================================
// Define as posições das linhas
//=========================================================
//_nLin1:=037 // caso precise essa é a linha 1 
_nLin2 :=049  // NOME DO COMPRADOR / Urgente
_nLin3 :=063  // Aplicação / Código Projeto // Obs. Generica 
_nLin4 :=075  // C. Custo / Aprovador  / CLAIM
nColAlt:=012  // comboboxs
nColLag:=040  // comboboxs / URGENTE
nComLag:=057  // comboboxs / Aplicação / CLAIM
nLarg  :=163  // Obs. Generica / Aprovador
nLarg1 :=110  // NOME DO COMPRADOR / Código Projeto / C. Custo
nSoma  :=045  // NOME DO COMPRADOR / Código Projeto / C. Custo

@ _nLin2, aPosGet[1,4]+nSoma MSGET _cNomeCompr PIXEL SIZE nLarg1,10 Of oNewDialog WHEN WhenNomeComp()

//Posição referente ao Urgente
@ _nLin2, aPosGet[1,7]  SAY 'Urgente' PIXEL SIZE 28,9 Of oNewDialog
@ _nLin2, aPosGet[1,8]  MSCOMBOBOX  cUrgen ITEMS {"","S=Sim","N=Não","F=NF"} SIZE nColLag, nColAlt OF oNewDialog PIXEL WHEN _lWhen

//Posição referente a aplicação
@ _nLin3, aPosGet[1,1] SAY 'Aplicação' PIXEL SIZE 28,9 Of oNewDialog
@ _nLin3, aPosGet[1,2] MSCOMBOBOX cAplic ITEMS {"C=Consumo","I=Investimento","M=Manutenção","S=Serviço"} SIZE nComLag, 010 OF oNewDialog PIXEL Valid {|| U_VldInf("A1") .AND. Pertence('CIMS')} WHEN _lWhen

//Posição referente ao Código de Investimento
@ _nLin3, aPosGet[1,3]       SAY 'Código Projeto' PIXEL SIZE 60,9 Of oNewDialog
@ _nLin3, aPosGet[1,4]       MSGET cCInve F3 'ZZI' PIXEL SIZE 10,08 Of oNewDialog Valid {|| U_VldInf("I")} WHEN (cAplic = "I" .AND. _lWhen)
@ _nLin3, aPosGet[1,4]+nSoma MSGET cDsInv PIXEL SIZE nLarg1,08 Of oNewDialog WHEN .F.

//Posição referente a Observação
@ _nLin3, aPosGet[1,5]       SAY 'Obs. Generica' PIXEL SIZE 40,9    Of oNewDialog
@ _nLin3, aPosGet[1,6]-1     MSGET cObsSC        PIXEL SIZE nLarg,08 Of oNewDialog WHEN _lWhen

//Posição referente a CLAIM
@ _nLin4  , aPosGet[1,1] SAY 'CLAIM' PIXEL SIZE 28,9 Of oNewDialog
@ _nLin4  , aPosGet[1,2] MSCOMBOBOX cClaim ITEMS {"1=Sim","2=Não"} SIZE nComLag, nColAlt OF oNewDialog  PIXEL Valid {|| Pertence('12')} WHEN _lWhen

//Posição referente ao centro de custo
@ _nLin4, aPosGet[1,3]       SAY 'C. Custo' PIXEL SIZE 28,9 Of oNewDialog
@ _nLin4, aPosGet[1,4]       MSGET cCCust F3 'CTTZLH' PIXEL SIZE 10,08 OF oNewDialog Valid {|| U_VldInf("C") .AND. U_VldZLH(cFilAnt) .AND.  Ctb105CC()} WHEN _lWhen
@ _nLin4, aPosGet[1,4]+nSoma MSGET cDsCus PIXEL SIZE nLarg1,08 Of oNewDialog WHEN .F.

//Posição referente ao Aprovador
@ _nLin4, aPosGet[1,5]       SAY 'Aprovador' PIXEL SIZE 28,9 Of oNewDialog
@ _nLin4,(aPosGet[1,6]-40)   MSGET cAprov F3 'ZZ7APR' PIXEL SIZE 10,08 Of oNewDialog Valid {|| U_VldInf("A")} WHEN _lWhen
@ _nLin4, aPosGet[1,6]       MSGET cDsApr PIXEL SIZE nLarg,08 Of oNewDialog WHEN .F.

// Grava log da rotina de Solicitação de Compras 
// Entrada nas telas de inclusão, alteração e exclusão.
U_ITLOGACS('MT110TEL')

FWRestArea(aArea)

Return

/*
===============================================================================================================================
Programa----------: VldInf
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 24/08/2015
Descrição---------: Rotina criada para trazer as descrições de centro de custo, aprovador e investimento, e fazer suas 
                    validações
Parametros--------: cTipo (C - Centro de Custo / A - Aprovador / I - Investimento)
Retorno-----------: lRet (.T. - Passa pela validação / .F. - Caso contrário)
===============================================================================================================================
*/
User Function VldInf(cTipo,lWiz)

Local aArea			:= FWGetArea()
Local lRet			:= .T.
Local aMensagem		:= {}
Local aProbl		:= {}
Local aSoluc		:= {} , _nX

Default lWiz := .F.

If cTipo == "C"
	DBSelectArea("CTT")
	DBSetOrder(1)
	If DBSeek(xFilial("CTT") + cCCust)
		cDsCus := CTT->CTT_DESC01
	Else
		aProbl := {}
		aAdd(aProbl, "Centro de Custo em branco ou digitado errado.")

		aSoluc := {}
		aAdd(aSoluc, "Favor informar um Centro de Custo válido, ou acessar a consulta via [F3].")

		aMensagem := {"Centro de Custo Inválido", aProbl, aSoluc}

		U_ITMsHTML(aMensagem)

		lRet := .F.
	EndIf
ElseIf cTipo == "A"
	DBSelectArea("ZZ7")
	DBSetOrder(1)
	If DBSeek(xFilial("ZZ7") + cAprov)
		If ZZ7->ZZ7_TIPO == 'S'
			aProbl := {}
			aAdd(aProbl, "O usuário selecionado é um Solicitante, e este não poderá ser utilizado como Aprovador.")
	
			aSoluc := {}
			aAdd(aSoluc, "Favor informar um Aprovador válido, ou acessar a consulta via [F3].")
	
			aMensagem := {"Aprovador Inválido", aProbl, aSoluc}
	
			U_ITMsHTML(aMensagem)
			
			lRet := .F.
		Else
			cDsApr := ZZ7->ZZ7_NOME
		EndIf
	Else

		aProbl := {}
		aAdd(aProbl, "Aprovador em branco ou digitado errado.")

		aSoluc := {}
		aAdd(aSoluc, "Favor informar um Aprovador válido, ou acessar a consulta via [F3].")

		aMensagem := {"Aprovador Inválido", aProbl, aSoluc}

		U_ITMsHTML(aMensagem)

		lRet := .F.
	EndIf

ElseIf cTipo == "A1"////ALEX CHAMADO 35745 - Tirar se esse chamado nao For para producao
	If cAplic <> "I"
       _nPosCdInv  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C1_I_CDINV"})
       _nPosDsInv  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C1_I_DSINV"})
       _nPosCdSInv := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C1_I_SUBIN"})
       _nPosDsSInv := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C1_I_SUIND"})
       cCInve := Space(TamSX3("C1_I_CDINV")[1])
       cDsInv := Space(TamSX3("C1_I_DSINV")[1])      
       For _nX := 1 To Len( aCols )
           aCols[_nX,_nPosCdInv ]:=cCInve
           aCols[_nX,_nPosDsInv ]:=cDsInv
           aCols[_nX,_nPosCdSInv]:=cCInve
           aCols[_nX,_nPosDsSInv]:=cDsInv
       Next
    EndIf

ElseIf cTipo == "I" 
	If cAplic == "I"
	   If Empty(cCInve)

	      aProbl := {}
		  aAdd(aProbl, "Código de Projeto em branco.")

		  aSoluc := {}
		  aAdd(aSoluc, "Favor informar um Código de Projeto válido, ou acessar a consulta via [F3].")

		  aMensagem := {"Código de Projeto Inválido", aProbl, aSoluc}

		  U_ITMsHTML(aMensagem)

		  lRet := .F.
       EndIf
    EndIf
    If !Empty(cCInve)
		DBSelectArea("ZZI")
		DBSetOrder(1)
		If DBSeek(xFilial("ZZI") + cCInve)
		   cDsInv := ZZI->ZZI_DESINV // CHAMADO 31462 - ALEX - Tirar se esse chamado nao For para producao
		   If ZZI->ZZI_MSBLQL = "1"  // CHAMADO 31462 - ALEX - Tirar se esse chamado nao For para producao
              U_ITMsg("Projeto BLOQUEADO ",'Atenção!',"Selecione um projeto ativo",1)
		      lRet := .F.
	   	   ElseIf ZZI->ZZI_DTINIC > Date() .Or. ZZI->ZZI_DTFIM < Date()
              U_ITMsg("Projeto em periodo inativo, Dt. Ini. : "+DToC(ZZI->ZZI_DTINIC)+" e Dt. Fim : "+DToC(ZZI->ZZI_DTFIM),'Atenção!',"Selecione um projeto com o periodo ativo",1)
		      lRet := .F.
	   	   EndIf
		Else
		   aProbl := {}
		   aAdd(aProbl, "Código de Projeto digitado errado.")
	
		   aSoluc := {}
		   aAdd(aSoluc, "Favor informar um Código de Projeto válido, ou acessar a consulta via [F3].")
	
		   aMensagem := {"Código de Projeto Inválido", aProbl, aSoluc}
	
		   U_ITMsHTML(aMensagem)

		   lRet := .F.
		EndIf
        If lRet  //CHAMADO 31462  - ALEX  - Tirar se esse chamado nao For para producao
			cDsInv := ZZI->ZZI_DESINV
			cCInve := ZZI->ZZI_CODINV //PARA ALINHAR O TAMANHO
		
			ZZI->(DBSetOrder(4))//ZZI_FILIAL+ZZI_INVPAI+ZZI_TIPO
			If IsInCallStack("U_MT110TOK") .And. ZZI->(DBSeek(xFilial()+cCInve2+"3"))
				_nPosCdSInv:= aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C1_I_SUBIN"})
				For _nX := 1 To Len( aCols )
					If Empty(aCols[_nX,_nPosCdSInv])
						lRet := .F.
						Exit
					EndIf
				Next
				If !lRet  //CHAMADO 31462  - ALEX  - Tirar se esse chamado nao For para producao
					U_ITMsg("Produto da linha "+cValToChar(_nX)+" nao esta com o campo de nivel 3 de investimento preenchido",'Atenção!',;
							"EM TODOS OS ITENS DEVE SER PREENCHIDO O CAMPO DE NIVEL 3 DE INVESTIMENTO PARA O PROJETO "+AllTrim(cDsInv)+" INFORMADO NA CAPA",1)
					lRet := .F.
				EndIf
			EndIf

			If lWiz
				If !Empty(AllTrim(cCInve))
					ZZI->(DBSetOrder(3))//ZZI_FILIAL+ZZI_INVPAI+ZZI_TIPO
					If ZZI->(DBSeek(xFilial()+cCInve+"2"))
						lExibe := .T.
					Else
						lExibe := .F.
					EndIf
				Else
					lExibe := .F.
				EndIf

				If lExibe
					oSInve2:Show()
					oCInve2:Show()
					oDsInv2:Show()
				Else
					cCInve2 := Space(Len(ZZI->ZZI_CODINV))
					cDsInv2 := Space(Len(ZZI->ZZI_DESINV))
					
					cCInve3 := Space(Len(ZZI->ZZI_CODINV))
					cDsInv3 := Space(Len(ZZI->ZZI_DESINV))
					
					oSInve2:Hide()
					oCInve2:Hide()
					oDsInv2:Hide()

					oSInve3:Hide()
					oCInve3:Hide()
					oDsInv3:Hide()
				EndIf
			EndIf
	    EndIf
    Else
		
		cDsInv  := Space(Len(ZZI->ZZI_DESINV))
		cCInve2 := Space(Len(ZZI->ZZI_CODINV))
		cDsInv2 := Space(Len(ZZI->ZZI_DESINV))			
		cCInve3 := Space(Len(ZZI->ZZI_CODINV))
		cDsInv3 := Space(Len(ZZI->ZZI_DESINV))

		If IsInCallStack("A120PEDIDO")
		    _nPosCdInv  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_CDINV"})
			_nPosDsInv  := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_DSINV"})
			_nPosCdSInv := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_SUBIN"})
			_nPosDsSInv := aScan(aHeader,{|x| AllTrim(Upper(x[2]))=="C7_I_SUIND"})

			For _nX := 1 To Len( aCols )
				aCols[_nX,_nPosCdInv ]:=cCInve
				aCols[_nX,_nPosDsInv ]:=cDsInv
				aCols[_nX,_nPosCdSInv]:=cCInve
				aCols[_nX,_nPosDsSInv]:=cDsInv
			Next
		EndIf

		If lWiz
			oSInve2:Hide()
			oCInve2:Hide()
			oDsInv2:Hide()

			oSInve3:Hide()
			oCInve3:Hide()
			oDsInv3:Hide()
		EndIf
    EndIf
ElseIf cTipo == "I2"
	If cAplic == "I"
		If !Empty(cCInve2)
			DBSelectArea("ZZI")
			DBSetOrder(1)
			If DBSeek(xFilial("ZZI") + cCInve2)
				cDsInv2 := ZZI->ZZI_DESINV // CHAMADO 31462 - ALEX - Tirar se esse chamado nao For para producao
				If ZZI->ZZI_MSBLQL = "1"  // CHAMADO 31462 - ALEX - Tirar se esse chamado nao For para producao
					U_ITMsg("Projeto BLOQUEADO ",'Atenção!',"Selecione um projeto ativo",1)
					lRet := .F.
				ElseIf ZZI->ZZI_DTINIC > Date() .Or. ZZI->ZZI_DTFIM < Date()
					U_ITMsg("Investimento em periodo inativo, Dt. Ini. : "+DToC(ZZI->ZZI_DTINIC)+" e Dt. Fim : "+DToC(ZZI->ZZI_DTFIM),'Atenção!',"Selecione um projeto com o periodo ativo",1)
					lRet := .F.
				EndIf
			Else
				aProbl := {}
				aAdd(aProbl, "Código de Investimento digitado errado.")
			
				aSoluc := {}
				aAdd(aSoluc, "Favor informar um Código de Investimento válido, ou acessar a consulta via [F3].")
			
				aMensagem := {"Código de Investimento Inválido", aProbl, aSoluc}
			
				U_ITMsHTML(aMensagem)

				lRet := .F.
			EndIf
			If lRet  //CHAMADO 31462  - ALEX  - Tirar se esse chamado nao For para producao
				cDsInv2 := ZZI->ZZI_DESINV
				cCInve2 := ZZI->ZZI_CODINV//PARA ALINHAR O TAMANHO

				If lWiz
					If !Empty(AllTrim(cCInve))
						ZZI->(DBSetOrder(6))//ZZI_FILIAL+ZZI_CHAVE
						If ZZI->(DBSeek(xFilial("ZZI")+cCInve+cCInve2))
							lExibe := .F.
							While (xFilial("ZZI") + cCInve + cCInve2) == (ZZI->ZZI_FILIAL + Subs(ZZI->ZZI_CHAVE,1,Len(cCInve+cCInve2))) .And. ZZI->(!Eof())
								If ZZI->ZZI_TIPO = "3"
									lExibe := .T.
									Exit
								EndIf
								ZZI->(DBSkip())
							EndDo
						Else
							lExibe := .F.
						EndIf
					Else
						lExibe := .F.
					EndIf

					If lExibe
						oSInve3:Show()
						oCInve3:Show()
						oDsInv3:Show()
					Else
						oSInve3:Hide()
						oCInve3:Hide()
						oDsInv3:Hide()
					EndIf
				EndIf
			EndIf
		Else
			cDsInv2 := Space(Len(ZZI->ZZI_DESINV))
			cCInve3 := Space(Len(ZZI->ZZI_CODINV))
			cDsInv3 := Space(Len(ZZI->ZZI_DESINV))
			If lWiz
				oSInve3:Hide()
				oCInve3:Hide()
				oDsInv3:Hide()
			EndIf
		EndIf
    EndIf
ElseIf cTipo == "I3"
	If cAplic == "I"
		If !Empty(cCInve3)
			DBSelectArea("ZZI")
			DBSetOrder(1)
			If DBSeek(xFilial("ZZI") + cCInve3)
				cDsInv3 := ZZI->ZZI_DESINV // CHAMADO 31462 - ALEX - Tirar se esse chamado nao For para producao
				If ZZI->ZZI_MSBLQL = "1"  // CHAMADO 31462 - ALEX - Tirar se esse chamado nao For para producao
					U_ITMsg("Projeto BLOQUEADO ",'Atenção!',"Selecione um projeto ativo",1)
					lRet := .F.
				ElseIf ZZI->ZZI_DTINIC > Date() .Or. ZZI->ZZI_DTFIM < Date()
					U_ITMsg("Investimento em periodo inativo, Dt. Ini. : "+DToC(ZZI->ZZI_DTINIC)+" e Dt. Fim : "+DToC(ZZI->ZZI_DTFIM),'Atenção!',"Selecione um projeto com o periodo ativo",1)
					lRet := .F.
				EndIf
			Else
				aProbl := {}
				aAdd(aProbl, "Código de Investimento digitado errado.")
			
				aSoluc := {}
				aAdd(aSoluc, "Favor informar um Código de Investimento válido, ou acessar a consulta via [F3].")
			
				aMensagem := {"Código de Investimento Inválido", aProbl, aSoluc}
			
				U_ITMsHTML(aMensagem)

				lRet := .F.
			EndIf
			If lRet  //CHAMADO 31462  - ALEX  - Tirar se esse chamado nao For para producao
				cCInve3 := ZZI->ZZI_CODINV
				cDsInv3 := ZZI->ZZI_DESINV
			EndIf
		Else
			cDsInv3 := Space(Len(ZZI->ZZI_DESINV))
		EndIf
	EndIf
EndIf

FWRestArea(aArea)

Return(lRet)
/*
===============================================================================================================================
Programa--------: MT110WIZ
Autor-----------: Alex Wallauer
Data da Criacao-: 17/12/2019
Descrição-------: Exibe tela passo a passo para o usuário informar os dados
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function MT110WIZ

Local oStepWiz	As Object
Local o1stPage	As Object
Local o2ndPage	As Object
Local o5rdPage	As Object
Local lRet := .F.

oStepWiz := FWWizardControl():New(,{400,600})//Instancia a classe FWWizardControl
oStepWiz:ActiveUISteps()

//----------------------------
// Pagina 1 
//----------------------------
o1stPage := oStepWiz:AddStep("1STSTEP",{|oPanel| cria_pn(oPanel,1) }) // Adiciona um Step
o1stPage:SetStepDescription("Aplicação Investimento")
o1stPage:SetNextTitle("Avançar") 		 						  // Define o título do botão de avanço --
o1stPage:SetNextAction(  {|| U_MT110VPg() }) 	 							  // Define o bloco ao clicar no botão Próximo
o1stPage:SetCancelAction({|| lRet=!MsgYesNo("Confirma Cancelar?", "Atenção") })// Define o bloco ao clicar no botão Cancelar

//----------------------------
// Pagina 2 
//----------------------------
o2ndPage := oStepWiz:AddStep("2RDSTEP", {|oPanel| cria_pn(oPanel,2) })
o2ndPage:SetStepDescription("Centro de custo Aprovador")
o2ndPage:SetNextTitle("Avançar")
o2ndPage:SetPrevTitle("Retornar")
o2ndPage:SetNextAction({|| U_VldInf("C") .And. U_VldInf("A") })
o2ndPage:SetPrevWhen(  {|| .T. })
o2ndPage:SetCancelAction({|| lRet=!MsgYesNo("Confirma Cancelar?", "Atenção") })

//----------------------------
// Pagina 3
//----------------------------
o5rdPage := oStepWiz:AddStep("5RDSTEP", {|oPanel| cria_pn(oPanel,3) })
o5rdPage:SetStepDescription("Estoque Urgencia")
o5rdPage:SetNextTitle("Confirmar") 							          //
o5rdPage:SetPrevTitle("Retornar") 									  //
o5rdPage:SetNextAction({|| .T. })
o5rdPage:SetPrevAction({|| .T. })
o5rdPage:SetCancelAction({|| lRet=!MsgYesNo("Confirma Cancelar?", "Atenção") })

oStepWiz:Activate()
oStepWiz:Destroy()

Return(lRet)

/*
===============================================================================================================================
Programa--------: Cria_pn
Autor-----------: Alex Wallauer
Data da Criacao-: 17/12/2019
Descrição-------: Rotina para montar a páginas do Wizard
Parametros------: _oPanel - objeto da janela de execução
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function Cria_pn(_oPanel,_nPag)

Local _nLinA:=05
Local _nColA:=10


DEFINE FONT oBold NAME "Courier New" SIZE 8, 15 BOLD

If _nPag = 1
	
	@ _nLinA, _nColA Say 'A SC será referente a ?' PIXEL SIZE 199,99 Of _oPanel 
	_nLinA+=9
    @ _nLinA, _nColA MSCOMBOBOX cAplic ITEMS {"C=Consumo","I=Investimento","M=Manutenção","S=Serviço"} SIZE 065, 010 OF _oPanel PIXEL Valid {|| U_VldInf("A1") .AND. Pertence('CIMS')}
	
	_nLinA+=15
	
	@ _nLinA, _nColA	Say 'Código do Projeto' PIXEL SIZE 199,99 Of _oPanel 
	_nLinA+=10
	@ _nLinA, _nColA 	MSGET cCInve F3 'ZZI_P' PIXEL SIZE 10,10 Of _oPanel Valid {|| U_VldInf("I",.T.)} WHEN (cAplic = "I")
	@ _nLinA, _nColA+40	MSGET cDsInv PIXEL SIZE 200,08 Of _oPanel WHEN .F.
	
	_nLinA+=15

	@ _nLinA, _nColA	Say oSInve2 Prompt 'Investimento Nivel 2' PIXEL SIZE 199,99 Of _oPanel  
	_nLinA+=9
	@ _nLinA, _nColA 	MSGET oCInve2 VAR cCInve2 F3 'F3ITLC' PIXEL SIZE 10,10 Of _oPanel Valid {|| U_VldInf("I2",.T.)} WHEN (cAplic = "I")
	@ _nLinA, _nColA+40	MSGET oDsInv2 VAR cDsInv2 PIXEL SIZE 200,08 Of _oPanel WHEN .F.
	
	_nLinA+=15

	@ _nLinA, _nColA	Say oSInve3 Prompt 'Investimento Nivel 3' PIXEL SIZE 199,99 Of _oPanel 
	_nLinA+=9
	@ _nLinA, _nColA 	MSGET oCInve3 VAR cCInve3 F3 'F3ITLC' PIXEL SIZE 10,10 Of _oPanel Valid {|| U_VldInf("I3",.T.)} WHEN (cAplic = "I")
	@ _nLinA, _nColA+40	MSGET oDsInv3 VAR cDsInv3 PIXEL SIZE 200,08 Of _oPanel WHEN .F.
	
	oSInve2:Hide()
	oCInve2:Hide()
	oDsInv2:Hide()
	
	oSInve3:Hide()
	oCInve3:Hide()
	oDsInv3:Hide()

ElseIf _nPag = 2
	
	@ _nLinA,_nColA		Say 'Centro de Custo?' PIXEL SIZE 99,50 Of _oPanel 
	_nLinA+=15
	@ _nLinA, _nColA	MSGET cCCust F3 'CTTZLH' PIXEL SIZE 40,10 OF _oPanel Valid {|| U_VldInf("C") .And. U_VldZLH(cFilAnt) .And. Ctb105CC()}
	@ _nLinA, _nColA+50	MSGET cDsCus PIXEL SIZE 200,10 Of _oPanel WHEN .F.
	_nLinA+=25

    @ _nLinA,_nColA  	Say 'Aprovador da Solicitação?' PIXEL SIZE 199,99 Of _oPanel 
	_nLinA+=15
    @ _nLinA, _nColA	MSGET cAprov F3 'ZZ7APR' PIXEL SIZE 45,10 Of _oPanel Valid {|| U_VldInf("A") } 
    @ _nLinA, _nColA+50	MSGET cDsApr PIXEL SIZE 200,10 Of _oPanel WHEN .F.
	
ElseIf _nPag = 3

	@ _nLinA, _nColA  Say 'Produto será consumido automaticamente? (Aplicação Direta)' PIXEL SIZE 299,50 Of _oPanel FONT oBold 
	_nLinA+=12
	@ _nLinA, _nColA   MSCOMBOBOX  cAplicDireta ITEMS {"S=Sim","N=Não"} SIZE 056, 010 OF _oPanel PIXEL VALID {|| If(cAplicDireta="S" .And. cAplic <> "I",cUrgen:="S",) } WHEN (cAplic <> "S")
	_nLinA+=22

	@ _nLinA, _nColA  Say 'Urgente?' PIXEL SIZE 99,50 Of _oPanel FONT oBold 
	_nLinA+=12
	@ _nLinA, _nColA   MSCOMBOBOX oCbx VAR cUrgen ITEMS {"S=Sim","N=Não","F=NF"} SIZE 056, 010 OF _oPanel  PIXEL  Valid {|| Pertence(If(cAplicDireta="S".AND.cAplic <> "I",'SF','SNF'))}  //WHEN (cAplicDireta <> "S" .Or. cAplic = "I")
	_nLinA+=22

	@ _nLinA, _nColA  Say 'Informe aqui observações gerais para a solicitação:' PIXEL SIZE 300,100 OF _oPanel FONT oBold 
	_nLinA+=12
	@ _nLinA, _nColA  MSGET cObsSC PIXEL SIZE 250,10 Of _oPanel 
	
EndIf

Return

/*
===============================================================================================================================
Programa--------: MT110VPg
Autor-----------: Igor Melgaco
Data da Criacao-: 12/07/2022
Descrição-------: Rotina para validar a Pag 1 do Wizard
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MT110VPg

Local lReturn := .T.

If cAplic == "I"
	If !Empty(cCInve)
		If !Empty(cCInve2)
			If Empty(cCInve3)
				ZZI->(DBSetOrder(6))//ZZI_FILIAL+ZZI_INVPAI+ZZI_TIPO
				If ZZI->(DBSeek(xFilial("ZZI")+cCInve+cCInve2))
					lReturn := .T.
					While (xFilial("ZZI") + cCInve + cCInve2) == (ZZI->ZZI_FILIAL + Subs(ZZI->ZZI_CHAVE,1,Len(cCInve+cCInve2))) .And. ZZI->(!Eof())
						If ZZI->ZZI_TIPO = "3"
							U_ITMsg("O campo Investimento 3 é obrigatório o seu preenchimento! ",'Atenção!',"",1)
							lReturn := .F.
							Exit
						EndIf
						ZZI->(DBSkip())
					EndDo
				EndIf
			EndIf
		Else
			ZZI->(DBSetOrder(3))//ZZI_FILIAL+ZZI_INVPAI+ZZI_TIPO
			If ZZI->(DBSeek(xFilial("ZZI")+cCInve+"2"))
				U_ITMsg("O campo Investimento 2 é obrigatório o seu preenchimento! ",'Atenção!',"",1)
				lReturn := .F.
			EndIf
		EndIf
	Else
		U_ITMsg("O campo Projeto é obrigatório o seu preenchimento! ",'Atenção!',"",1)
		lReturn := .F.
	EndIf
EndIf

Return lReturn

/*
===============================================================================================================================
Programa--------: MT110SUB
Autor-----------: Igor Melgaco
Data da Criacao-: 12/07/2022
Descrição-------: Rotina para Gatilhar o campo C1_PRODUTO
Parametros------: cCampo - Campo para retorno de seu conteudo na tela do wizard 
Retorno---------: cReturn - Retorno do Conteudo a preencher no acol
===============================================================================================================================
*/
User Function MT110SUB(cCampo)

Local cReturn := Space(Len(cCInve2))

If cAplic == "I"
	If cCampo = "C1_I_SUBIN" //Retrona o Código
		If !Empty(cCInve)
			If !Empty(cCInve3)
				cReturn := cCInve3
			ElseIf !Empty(cCInve2)
				cReturn := cCInve2
			EndIf
		EndIf
	ElseIf cCampo = "C1_I_SUIND" //Retorna a Descrição
		If !Empty(cCInve)
			If !Empty(cCInve3)
				cReturn := cDsInv3
			ElseIf !Empty(cCInve2)
				cReturn := cDsInv2
			EndIf
		EndIf
	ElseIf cCampo = "C1_I_CDINV" //Retrona o Código
		If !Empty(cCInve)
			cReturn := cCInve
		EndIf
	ElseIf cCampo = "C1_I_DSINV" //Retrona o Código
		If !Empty(cCInve)
			cReturn := cDsInv
		EndIf
	EndIf
EndIf

Return cReturn
/*
===============================================================================================================================
Programa--------: WhenNomeComp
Autor-----------: Alex Wallauer
Data da Criacao-: 08/09/2025
Descrição-------: Preenche o nome do comprador 
Parametros------: Nenhum
Retorno---------: .F.
===============================================================================================================================
*/
Static Function WhenNomeComp

If !Empty(cCodCompr)
   _cNomeCompr:=AllTrim(Posicione("SY1",1,xFilial("SY1")+cCodCompr,"Y1_NOME"))
EndIf

Return .F.
