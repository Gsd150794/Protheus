/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |25/04/2025| Chamado 50005. Gravacao do campo TNF->TNF_INDDEV com "2" e TNF->TNF_DTRECI com CTOD("") apenas para 
			  |			 | as filiais do parâmetro IT_EPIBIO. Impressão do Recibo para filiais diferente que não estiverem no 
			  |			 | parâmetro IT_EPIBIO.
Julio Paz     |06/05/2025| Chamado 50565. Habilitar a impressão do recibo de entrega de EPI para todas as filiais. Independente 
			  |			 | do conteúdo do parâmetro IT_EPIBIO.
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TOTVS.ch"

Static _cTNF_MATRIC
Static _cTNF_FILIAL
Static _aTNF_RECNO
Static _cTNFcA105Num

/*
===============================================================================================================================
Programa----------: MDTA6955
Autor-------------: Josué Danich Prestes
Data da Criacao---: 01/09/2015
Descrição---------: Ponto de entrada chamado após gravação e entrega de EPI ao funcionário via rotinas MDTA695 ou MDTA630
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static cNumSA:="XXXXXX"

User Function MDTA6955()

Local _aArea    := FWGetArea()
Local _cMat 	:= ""
Local _cnumcap 	:= ""
Local _cnumsem	:= ""
Local _cArm		:= ""
Local _nori	    := 0
Local _cMotivo  := ""     
Local _nPosMat, _nPosNumCap, _nPosNumSem
Local _aEpis	:= {}

n:= ogettnf695:nat
aColsAux:= ogettnf695:aCols
_nori := n

// Mantém posição da SCP/TNF para não interferir na gravação
_nPosSCP := SCP->( Recno() )
_nPosTNF := TNF->( Recno() )


//Commito os dados na SCP para validar o seek
SCP->(DBCOMMIT())
SCP->(FkCommit()) 

//Se For a função Funcionário x EPI
If AllTrim(funname()) == "MDTA695"
	
	_ccpfilial := cFilAnt//SCP->CP_FILIAL
	_ccpnum := cNumSA //:= SCP->CP_NUM // o SPC não esta posicionado porido devemos usar a variavel Private "cNumSA" do padrão 

 //  MsgInfo("SA Posicionada, cNumSA: [ "+cNumSA+" ]","MDTA6955")

	SCP->(DBSetOrder(1))

	If !_l655CTR .And. Len(aColsAux) == 1
		_aEpis := MTDAAUX(aColsAux)
		lRet := MDT695AUTO( _aEpis[1], 3 )
		SCP->(DBCOMMIT())
		SCP->(FkCommit())
	EndIf

	//------------------------------------------------------------------------------------------------------------------------------------------------
	SCP->( DBGoTo( _nPosSCP ) )
	//ORDEM 1 CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL

	//VERIFICA A EXISTENCIA DO REGISTRO NA SCR, CASO EXISTA, ELE DELETA CHAMADO: 33790
	DBSelectArea('SCR')
	SCR->(DBSetOrder(1))

	If SCR->(DBSeek(cFilAnt+"SA"+cNumSA))
		While SCR->(!Eof()) .And. SCR->CR_FILIAL == cFilAnt .And. AllTrim(SCR->CR_TIPO) == "SA" .And. AllTrim(SCR->CR_NUM) == AllTrim(cNumSA)
		   SCR->(RecLock('SCR',.F.))
		   SCR->(DBDelete())
		   SCR->(DBSkip())
		EndDo
	EndIf
	//------------------------------------------------------------------------------------------------------------------------------------------------
	//Posicina novamente para não gerar
	SCP->( DBGoTo( _nPosSCP ) )
	TNF->( DBGoTo( _nPosTNF ) )	

	If SCP->(DBSeek(_ccpfilial+_ccpnum))
	
		//Roda SCP atualizando campos
		While SCP->CP_FILIAL == _ccpfilial .And. SCP->CP_NUM == _ccpnum
	
			//roda todo o aColsAux atualizando campos 
			n := 1
	        nLinSalva:=0
			While n <= Len(aColsAux)
	
				If 	!aColsAux[n,Len(aHeader)+1] .And. ;
					AllTrim(aColsAux[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_CODEPI" })]) == AllTrim(SCP->CP_PRODUTO) .And. ;
					(aColsAux[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_QTDENT" })]) == SCP->CP_QUANT .And. ;
					Empty(AllTrim((aColsAux[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_ITEMSA"})]))) .And. ;
					Empty(AllTrim((aColsAux[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_NUMSA" })]))) .And. Empty(SCP->CP_I_DTSOL)//Para controle de itens repetido com mesm qtde
			
						//atualiza aColsAux para não repetir mesma linha na gravação da SA
			
						(aColsAux[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_NUMSA" })]) := AllTrim(SCP->CP_NUM)
						(aColsAux[n][aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_ITEMSA" })]) := AllTrim(SCP->CP_ITEM)
						nLinSalva:=n//Salva a linha que acabou de gravar os campos acima , no proximo não vai entra nesse item de novo pq os camos já estão preenchidos
						Exit // sai pq o proximo produto e qtde pode ser igual 
				Else
					n++
				EndIf 
			EndDo 
         
          _cMat:=cMatricula//Variavel do padrão
	      If nLinSalva <> 0//Controla qual item não gravou os campos abaixo ainda
		   	 n := nLinSalva
	
			//grava observação a partir do campo TNF_MAT2 que contém a matricula do funcionario
			_nPosMat := aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_I_MAT2" })
			_cmat := AllTrim(aColsAux[n][_nPosMat]) 
		
			//grava CA na solicitação ao armazém
			_nPosNumCap := aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_NUMCAP" })
			_cnumcap := AllTrim(aColsAux[n][_nPosNumCap])
	
			//pega número da semana
			_nPosNumSem := aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_I_NSEM" })
			_cnumsem := AllTrim(aColsAux[n][_nPosNumSem])

			//pega número da semana
			_nPosMot := aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_MOTIVO" })
		    _cMotivo := AllTrim(aColsAux[n][_nPosMot])

			// Se For material de reuso grava na observação
			_cArm := AllTrim(aColsAux[n][ aScan(aHEADER, {|x| AllTrim(Upper(X[2])) == "TNF_LOCAL" }) ])
 	
	    EndIf
			//Centro de Custo
//			_cCC := TNF_I_CC
	
			DBSelectArea("SCP")
			RecLock("SCP",.F.) 

   	        If nLinSalva <> 0//Controla qual item não gravou os campos abaixo ainda
			   SCP->CP_OBS := "FUNCIONARIO: " + SubStr(AllTrim(Posicione("SRA",1,xFilial("SRA") + _cMat, "RA_NOME")),1,25);
			     	       +  "  -  SETOR: " +  AllTrim(Posicione("ZAK",1,xFilial("ZAK") + Posicione("SRA",1,xFilial("SRA") + _cMat, "RA_I_SETOR"),"ZAK_DESCRI"))
 	        EndIf
			//se tiver campo de número de semana preenchido exporta para SA
			If !Empty(_cnumsem) .And. nLinSalva <> 0
 	
				SCP->CP_OBS := AllTrim(SCP->CP_OBS) + " - Letra Dia: " + AllTrim(_cnumsem)
 		
			EndIf
 	
			// Se o destino do material For para Reuso
			If _cArm == "05" .And. nLinSalva <> 0
				SCP->CP_OBS := AllTrim(SCP->CP_OBS) + " - REUSO"
			EndIf	
 	
//       	SCP->CP_CC		:= _cCC//Já ta gravado
			SCP->CP_I_DTSOL := Date()
			SCP->CP_I_RSSOL := Time()
			SCP->CP_I_CDUSU := FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
			SCP->CP_I_GRAPR := Posicione("ZZL",4,xFilial("ZZL")+Trim(SCP->CP_SOLICIT),"ZZL_GRPAPR")
			SCP->CP_STATSA	:= "L"
			SCP->CP_I_DTAPR :=	Date()
			SCP->CP_I_HRAPR	:=	Time()
			SCP->CP_I_CDAPR	:= 	SRA->RA_MAT
	        If nLinSalva <> 0
			   SCP->CP_I_TNFMT:=_cMotivo
			   SCP->CP_I_NUMCA:=_cnumcap
            EndIf
			SCP->( MSUnLock() )  
	
			SCP->( DBSkip() )
			
		EndDo
		
	EndIf
	
EndIf

//se For a função EPI x funcionário
If AllTrim(funname()) == "MDTA630"

	//grava observação a partir do obs gravado por padrão
	_cmat := right(AllTrim(SCP->CP_OBS),6)
	
	DBSelectArea("SCP")
	RecLock("SCP",.F.) 

	SCP->CP_OBS := "FUNCIONARIO: " + SubStr(AllTrim(Posicione("SRA",1,xFilial("SRA") + _cMat, "RA_NOME")),1,25);
 	+  "  -  SETOR: " +  AllTrim(Posicione("ZAK",1,xFilial("ZAK") + Posicione("SRA",1,xFilial("SRA") + _cMat, "RA_I_SETOR"),"ZAK_DESCRI"))
 	
 	//se tiver campo de número de semana preenchido exporta para SA
 	If !Empty(TNF->TNF_I_NSEM)
 	
 		SCP->CP_OBS := AllTrim(SCP->CP_OBS) + " - Letra Dia: " + AllTrim(TNF->TNF_I_NSEM)
 		
 	EndIf
 	
 	//grava CA na solicitação ao armazém
 	SCP->CP_I_NUMCA := TNF->TNF_NUMCAP

	SCP->( MSUnLock() )

EndIf

SCP->( DBGoTo (_nPosSCP ) )
TNF->( DBGoTo (_nPosTNF ) )

//chama ponto de entrada pós gravação de SCP
cA105Num := SCP->CP_NUM
//U_MT105GRV(SCP->CP_NUM) não precisa chamar já grva tudo aqui 

// Existe inclusão de EPIs sem impressão do Recibo de entrega.  
// Mantém posição da SCP/TNF para não interferir na gravação
_nPosSCP := SCP->( Recno() )
_nPosTNF := TNF->( Recno() )	
     
// Gera os dados para emissão do recibo de entrega de EPI.   
U_MDTA695T()   

SCP->( DBGoTo (_nPosSCP ) )
TNF->( DBGoTo (_nPosTNF ) )
   
//Limpa variável de processamento
PutGlbValue("MDTA6954","")
   
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: MDTA695R
Autor-------------: Julio de Paula Paz
Data da Criacao---: 23/10/2017
Descrição---------: Esta função carega o almoxarifado posicionado no msgetdados principal para outro secundário, através da
                    do incializador padrão do campo
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MDTA695R()

Local _cRet := "  " 
Local _nLocalT 
Local _nPosLoc, _cAlmox,_nPosRepEst 

Begin Sequence
   If Type("aHeadPrin") == "A" .And. Type("aOldTNF") == "A" .And. Type("nSalTNF") == "N"
      _nLocalT := aScan(aHeadPrin, {|x| AllTrim(Upper(X[2])) == "TNF_LOCAL" })
      _nPosRepEst := aScan(aHeader, {|x| AllTrim(Upper(X[2])) == "TLW_TIPODV" }) 
      
      _cAlmox := aOldTNF[nSalTNF,_nLocalT]
      
      _cRet := _cAlmox
      
      aCols[N,_nPosRepEst] := "2"
   Else
      _nPosLoc := aScan(aHeader, {|x| AllTrim(Upper(X[2])) == "TLW_LOCAL" })
      _cRet := aCols[N,_nPosLoc]
   EndIf

End Sequence

Return _cRet

/*
===============================================================================================================================
Programa----------: MDTA695T
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/04/2018
Descrição---------: Esta função inicia a leitura de dados para a impressão dos documentos de entrega.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MDTA695T()

Local _cQry
Local _nTotRegs
Local _aRecnoTNF := {}

Begin Sequence
   _cQry := "SELECT TNF.R_E_C_N_O_ AS NRRECNO FROM " + RetSqlName("TNF") + " TNF " 
   _cQry += " WHERE TNF.D_E_L_E_T_ = ' ' AND TNF_FILIAL = '" + xFilial("TNF") + "' "
   _cQry += " AND TNF_MAT = '" +M->RA_MAT+ "' AND TNF_DTRECI = '        ' "

   If Select("QRYTNF2") > 0
	  QRYTNF2->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "QRYTNF2" , .T. , .F. )

   QRYTNF2->(DBGoTop())

   _nTotRegs := 0
   While ! QRYTNF2->(Eof())
      _nTotRegs += 1
      
      aAdd(_aRecnoTNF,QRYTNF2->NRRECNO)
      
      QRYTNF2->(DBSkip())
   EndDo
   
   If Select("QRYTNF2") > 0
	  QRYTNF2->( DBCloseArea() )
   EndIf

   If _nTotRegs == 0
      Break
   EndIf
   
   _cTNF_MATRIC := M->RA_MAT
   _cTNF_FILIAL := xFilial("TNF")
   _aTNF_RECNO  := AClone(_aRecnoTNF)
   _cTNFcA105Num := cA105Num   
              
End Sequence

Return

/*
===============================================================================================================================
Programa----------: MDTA695U
Autor-------------: Julio de Paula Paz
Data da Criacao---: 05/04/2018
Descrição---------: Esta função chama  a rotina customizada de entregas de EPIs.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MDTA695U

Local _aRecnoTNF  := _aTNF_RECNO  
Local _nI
Local _lNrSAPreenchido
Local _cFilAsDig := SUPERGETMV('IT_EPIBIO',.F.,"01")

If !Empty(_cTNFcA105Num) .Or. Type("cA105Num") <> "C"
   cA105Num := _cTNFcA105Num
EndIf

Begin Sequence
   _nPosSCP := SCP->( Recno() )
   _nPosTNF := TNF->( Recno() )	

   _lNrSAPreenchido := .T.
   For _nI := 1 To Len(_aRecnoTNF)
       TNF->(DBGoTo(_aRecnoTNF[_nI]))
	   If Empty(TNF->TNF_NUMSA)
          _lNrSAPreenchido := .F.
       EndIf
   Next

   If ! _lNrSAPreenchido
      Break   
   EndIf

   M->RA_MAT := _cTNF_MATRIC

   //=================================
   //Emite recibo de entrega do EPI	
   //=================================	
   U_RMDT001() 
   
   //===============================================================================================
   // Habilitar a biometria apenas para as filiais diferentes das filiais do parâmetro IT_EPIBIO.
   //===============================================================================================
   If cFilAnt $ _cFilAsDig 
      For _nI := 1 To Len(_aRecnoTNF)
	      TNF->(DBGoTo(_aRecnoTNF[_nI]))
		  
          TNF->(RecLock("TNF",.F.))
          If TNF->TNF_INDDEV == "3"
             TNF->TNF_I_OBS  := "Epi em Solic. Armazem" // "Em solicitação ao armazém" 
		  EndIf 
          TNF->TNF_INDDEV := "2"   // VERIFICAR SE O INDDEV É 3 ANTES DE ALTERAR O CAMPO TNF_I_OBS.
          TNF->TNF_DTRECI := CTOD("")
          TNF->(MSUnLock())       
      Next
   EndIf 

   _cTNF_MATRIC := ""
   _cTNF_FILIAL := ""
   _aTNF_RECNO  := {}
   _cTNFcA105Num := ""
      
End Sequence

SCP->( DBGoTo (_nPosSCP ) )
TNF->( DBGoTo (_nPosTNF ) )

Return

/*
===============================================================================================================================
Programa----------: MDTA695X
Autor-------------: Julio de Paula Paz
Data da Criacao---: 05/04/2018
Descrição---------: Esta verifica se existem documentos de entrega de EPIs para serem impressos.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MDTA695X()

Local _lRet := .F.

Begin Sequence
   If ValType(_aTNF_RECNO) == "A"
      If Len(_aTNF_RECNO) > 0
         _lRet := .T.
      EndIf
   EndIf
   
End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: MTDAAUX
Autor-------------: Julio de Paula Paz
Data da Criacao---: 05/04/2018
Descrição---------: Esta verifica se existem documentos de entrega de EPIs para serem impressos.
Parametros--------: aCols -> aCols auxiliar.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MTDAAUX(_aColls)

Local _nPosB1		:= SB1->(RECNO())
Local _nItem		:= 1
Local _aEpis		:= {}
Local _nX			:= 0

For _nX := 1 TO Len(_aColls)
	aAdd( _aEpis , {{_aColls[_nX][2],; 
					Posicione("SB1",1,xFilial("SB1")+_aColls[_nX][2], "B1_UM"),;
					_aColls[_nX][11],;
					SB1->B1_LOCPAD,;
					dDataBase,;
					dDataBase,;
					cUserName,;
					cCCSCP,;
					SB1->B1_DESC,;
					cObsSCP,;
					cNumSA,; 
					StrZero( _nItem, 2 ) }} )
	_nItem++
Next _nX

SB1->(DBGoTo( _nPosB1 ))

Return _aEpis

User Function MDTA6959()

Local aCab:=ParamIXB[1]

cNumSA:=aCab[1,2]

Return .T.
