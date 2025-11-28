/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |03/11/2017| Chamados 22140/22154/19329. Realização de ajustes nas rotinas de devolução de EPIs para que permitam 
              |          | a impressão dos recibos de entrega de EPI. 
Julio Paz     |10/04/2018| Chamado 23960. Realização de ajustes nas rotinas de entrega e devolução de EPI, para impressão 
              |          | correta dos comprovantes.
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AMDT003
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 08/06/2016
Descrição---------: Devoluções de EPI's
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AMDT003

Local _cAlias		:= "TNF"
Local _aCores 		:=	{	{'TNF_I_TPDV == "T"'	, 'BR_BRANCO'	},;
							{'TNF_I_TPDV == "R"'	, 'BR_AMARELO'	} }

Private _aFixe 		:= { 	{ "Status Epi", "TNF_I_TPST"}	}
Private _cFiltro	:= " TNF_I_TPDV = 'T' OR TNF_I_TPDV = 'R' "
Private cCadastro	:= "Devolução de Epis"
Private aRotina		:= MenuDef()

mBrowse( 6, 1,22,75,_cAlias,_aFixe,,,,,_aCores,,,,,,,,_cFiltro)

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Darcio Ribeiro Sporl
Data da Criacao---: 25/04/2016
Descrição---------: Rotina responsavel pela criação das opções de menu
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()

Private aRotina	:=  {	{"Pesquisar"		,"AxPesqui"		, 0, 1, 0, .F.},;
						{"Devolução"		,"U_AMD003D"	, 0, 2, 0, .F.},;
						{"Exclusão"			,"U_AMD003E"	, 0, 2, 0, .F.},;
						{"Visualizar"		,"AxVisual"		, 0, 2, 0, .F.},;
						{"Legenda"			,"U_AMD003LEG"	, 0, 2, 0, .F.} }

Return (aRotina)

/*
===============================================================================================================================
Programa----------: AMD003LEG
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 08/06/2016
Descrição---------: Função utilizada para montar a legenda
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AMD003LEG()

aLegenda :=	{	{"BR_BRANCO"	, "Epi para Troca"		},;
				{"BR_AMARELO"	, "Epi para Reúso"		} }

BrwLegenda("Situação das Epi's","Legenda",aLegenda)
Return

/*
===============================================================================================================================
Programa----------: AMD003C
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 08/06/2016
Descrição---------: Função para marcar devolução dos EPI's
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AMD003C()

Local _aArea	:= FWGetArea()
Local _cMatric	:= SRA->RA_MAT
Local _nPosEpi	:= aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_CODEPI"}	)
Local _nPosFor	:= aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_FORNEC"}	)
Local _nPosLoj	:= aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_LOJA"}		)
Local _nPosCap	:= aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_NUMCAP"}	)
Local _nPosDte	:= aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_DTENTR"}	)
Local _nPosHre	:= aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_HRENTR"}	)
Local _nPosInd	:= aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_INDDEV"}	)
Local _oPnlSup, _oDlgQ
Local _nQtdEntr, _nQtdDevolv, _nSaldo, _nQtdADev
Local _nPosQEntr := aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_QTDENT"}	)
Local _nPosQDev  := aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_QTDEVO"}	)
Local _nLin := 2.5
Local _nOpcTNF := 0

Begin Sequence
   n:= ogettnf695:nat

   If aCols[n][_nPosInd] == "2"
	  If MsgYesNo("Deseja realmente confirmar a Devolução deste EPI?","AMDT00301")
	     _nQtdEntr := aCols[n][_nPosQEntr]
	     _nQtdDevolv := aCols[n][_nPosQDev]
	     _nSaldo := _nQtdEntr - _nQtdDevolv
	     _nQtdADev := 0
	     
	     If _nSaldo <= 0
	        MsgStop("Não há quantidades disponíveis para devolução de EPIs.","AMDT00302 - Devolução de EPI")
	        Break
	     EndIf
	     
	     DEFINE MSDIALOG _oDlgQ TITLE "Devolução de EPIs" From 0,0 To 200,587 OF oMainWnd PIXEL // 440,587

	        @ 0.5+_nLin,1 Say OemToAnsi("Qtd Entregue") Of _oDlgQ  
	        @ 0.5+_nLin,8.2  MSGET _nQtdEntr SIZE 20,10 Of _oDlgQ WHEN .F.   
	
	        @ 1.7+_nLin ,1 Say OemToAnsi("Qtd Devolvida") Of _oDlgQ
	        @ 1.7+_nLin ,8.2  MSGET _nQtdDevolv SIZE 20,10 Of _oDlgQ WHEN .F.
	
	        @ 2.9+_nLin ,1 Say OemToAnsi("Saldo") Of _oDlgQ
	        @ 2.9+_nLin ,8.2  MSGET _nSaldo SIZE 50,10 Of _oDlgQ WHEN .F.
	                                
	        @ 4.1+_nLin ,1 Say OemToAnsi("Qtd a Devolver") Of _oPnlSup
	        @ 4.1+_nLin ,8.2  MSGET _nQtdADev SIZE 45,10 PICTURE "@E 999.99" VALID U_AMD003V(_nSaldo,_nQtdADev) Of _oDlgQ 

         ACTIVATE MSDIALOG _oDlgQ CENTERED ON INIT EnchoiceBar(_oDlgQ,{||_nOpcTNF:=1,_oDlgQ:End()},{||_nOpcTNF := 0,_oDlgQ:End()}) VALID U_AMD003V(_nSaldo,_nQtdADev)
	     
	     If _nOpcTNF <> 1
	        MsgStop("Rotina de Devolução de EPIs cancelada pelo usuário.","AMDT00303 - Devolução de EPI")
	        Break
	     EndIf
	     
         //=============================================	
         U_MDT6954G(.T.)
         
	  	 If Aviso("AMDT00304 - Reposicao do Estoque", "O EPI Será?", { "TROCA", "REÚSO" }, 1) = 1
			DBSelectArea("TNF")
			DBSetOrder(1)
			If DBSeek(xFilial("TNF") + aCols[n][_nPosFor] + aCols[n][_nPosLoj] + aCols[n][_nPosEpi] + aCols[n][_nPosCap] + _cMatric + DToS(aCols[n][_nPosDte]) + aCols[n][_nPosHre])
				RecLock("TNF",.F.)
				TNF->TNF_I_TPDV := "T"
				TNF->TNF_I_QTDD := _nQtdADev
				TNF->(MSUnLock())
			    MsgInfo("O processo de devolução de EPI foi conluído com sucesso.","AMDT00305 - Devolução de EPI")
			 EndIf
		  Else
			 DBSelectArea("TNF")
			 DBSetOrder(1)
			 If DBSeek(xFilial("TNF") + aCols[n][_nPosFor] + aCols[n][_nPosLoj] + aCols[n][_nPosEpi] + aCols[n][_nPosCap] + _cMatric + DToS(aCols[n][_nPosDte]) + aCols[n][_nPosHre])
	            RecLock("TNF",.F.)
				TNF->TNF_I_TPDV := "R"
				TNF->TNF_I_QTDD := _nQtdADev
				TNF->(MSUnLock())
				MsgInfo("O processo de devolução de EPI foi conluído com sucesso.","AMDT00306 - Devolução de EPI")
			 EndIf
		  EndIf
		  U_ITLOGACS('AMD003C')
	   EndIf
    Else
	   MsgAlert("Favor selecionar um EPI válido.","AMDT00307 - Devolução de EPI")
   EndIf
End Sequence

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: AMD003D
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 08/06/2016
Descrição---------: Função efetivar a Devolução dos Epi's
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AMD003D()

Local _aArea	:= FWGetArea()
Local cMatricEn	:= TNF->TNF_MAT
Local cNomeFuEn	:= NGSeek("SRA",cMatricEn,1,"RA_NOME")
Local cFornecEn	:= TNF->TNF_FORNEC
Local cLojaSvEn	:= TNF->TNF_LOJA
Local cEpiSvoEn := TNF->TNF_CODEPI
Local cDesSb1En	:= NGSEEK("SB1",cEpiSvoEn,1,"B1_DESC")
Local cNumCapEn	:= TNF->TNF_NUMCAP
Local dDataSvEn	:= TNF->TNF_DTENTR
Local cHoraSvEn := TNF->TNF_HRENTR
Local nQtdadeEn	:= TNF->TNF_QTDENT
Local _nIQtdDev := TNF->TNF_I_QTDD
Local _nQtdSaldo:= nQtdadeEn - _nIQtdDev - TNF->TNF_QTDEVO
Local aNaoTLW	:= {}
Local nOpcTLW	:= 0
Local aAlter	:= {"TLW_QTDEVO"}
Local _cNUMSEQ	:= ""
Local _nPosDt	:= 0
Local _nPosHr	:= 0
Local _nPosQt	:= 0
Local _nPosAr	:= 0
Local _cTmpLote	:= ""
Local _cTmpSubL	:= ""
Local _cTmpLocz	:= ""
Local _cTmpNSer	:= ""
Local _nLocTipoDV, _nI 

Private aHeadTLW	:= {} //Cabeçalho da TLW
Private aHeader		:= {}
Private aCols		:= {}

Private lSigaMdtPS	:= If( SuperGetMv("MV_MDTPS",.F.,"N") == "S", .T. , .F. )
Private aDevEpi		:= {}
Private oPnlSup
Private oDlg

aHeadTLW	:= CABECGETD("TLW", aNaoTLW )
aHeader		:= aClone(aHeadTLW)

If TNF->TNF_I_TPDV == "T"
	aAdd(aCols,{Date(),Time(),0,"00","2","S",.F.})
ElseIf TNF->TNF_I_TPDV == "R"
	aAdd(aCols,{Date(),Time(),0,"05","2","S",.F.})
EndIf

_nLocTipoDV := aScan(aHeader, {|x| AllTrim(Upper(X[2])) == "TLW_TIPODV" })
For _nI := 1 To Len(aCols)
    aCols[_nI][_nLocTipoDV] := "1" // SIM
Next


DEFINE MSDIALOG oDlg TITLE cCadastro From 0,0 To 440,587 OF oMainWnd PIXEL

	oPnlSup := TPanel():New(0,0,,oDlg,,,,,,0,90,.F.,.F.) // 70
	oPnlSup:Align := CONTROL_ALIGN_TOP

	@ 0.5 ,.8 Say OemToAnsi("Matricula") Of oPnlSup
	@ 0.5 ,5  MSGET cMatricEn SIZE 20,10 Of oPnlSup WHEN .F.
	@ 0.5 ,9  Say OemToAnsi("Nome") Of oPnlSup
	@ 0.5 ,12 MSGET cNomeFuEn SIZE 196,10 Of oPnlSup WHEN .F.
	
	@ 1.7 ,.8 Say OemToAnsi("Fornecedor") Of oPnlSup
	@ 1.7 ,5  MSGET cFornecEn SIZE 20,10 Of oPnlSup WHEN .F.
	@ 1.7 ,9  Say OemToAnsi("Loja") Of oPnlSup
	@ 1.7 ,12 MSGET cLojaSvEn SIZE 15,10 Of oPnlSup WHEN .F.
	@ 1.7 ,17 Say OemToAnsi("Nome Fornecedor") Of oPnlSup
	@ 1.7 ,24 MSGET Eval({|| Posicione("SA2",1,xFilial("SA2")+cFornecEn+cLojaSvEn,"A2_NOME")}) SIZE 100,10 Of oPnlSup WHEN .F.
	
	@ 2.9 ,.8 Say OemToAnsi("Epi") Of oPnlSup
	@ 2.9 ,5  MSGET cEpiSvoEn SIZE 50,10 Of oPnlSup WHEN .F.
	@ 2.9 ,12 Say OemToAnsi("Descricao") Of oPnlSup
	@ 2.9 ,17 MSGET cDesSb1En SIZE 65,10 Of oPnlSup WHEN .F.

	@ 2.9 ,26 Say OemToAnsi("Num. C.A.") Of oPnlSup
	@ 2.9 ,30 MSGET cNumCapEn SIZE 40,10 Of oPnlSup WHEN .F.
	                                
	@ 4.1 ,.8 Say OemToAnsi("Data Entrega") Of oPnlSup
	@ 4.1 ,5  MSGET dDataSvEn SIZE 45,10 Of oPnlSup WHEN .F. HASBUTTON
	
	@ 4.1 ,12 Say OemToAnsi("Hora Entrega") Of oPnlSup
	@ 4.1 ,17 MSGET cHoraSvEn SIZE 18,10 Of oPnlSup WHEN .F.
	
	@ 4.1 ,24 Say OemToAnsi("Qtde. Entregue") Of oPnlSup
	@ 4.1 ,29 MSGET nQtdadeEn Picture "@E 999.99" SIZE 25,10 Of oPnlSup WHEN .F. HASBUTTON
	
	@ 5.3 ,.8 Say OemToAnsi("Qtd Devolvida") Of oPnlSup
	@ 5.3 ,5  MSGET _nIQtdDev SIZE 45,10 Of oPnlSup WHEN .F. 
	
	@ 5.3 ,12 Say OemToAnsi("Saldo") Of oPnlSup
	@ 5.3 ,17 MSGET _nQtdSaldo SIZE 18,10 Of oPnlSup WHEN .F.
	
	DBSelectArea("TLW")
	oGet1 := MsNewGetDados():New( 090, 005, 205, 292, GD_UPDATE, "AllwaysTrue", "AllwaysTrue", "",aAlter,, 999, "AllwaysTrue", "", "AllwaysTrue", oDlg, aHeader, aCols)  // 070, 005, 205, 292
	oGet1:oBrowse:Align := CONTROL_ALIGN_ALLCLIENT
	
ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,{||nOpcTLW:=1,oDlg:End()},{||nOpcTLW := 0,oDlg:End()}) VALID U_AMDTTOK(oGet1, nQtdadeEn, cMatricEn, cFornecEn, cLojaSvEn, cEpiSvoEn, cNumCapEn, dDataSvEn, cHoraSvEn,_nIQtdDev)

If nOpcTLW == 1

	_nPosDt	:= aScan(oGet1:aHeader,{|x| AllTrim(x[2]) == "TLW_DTDEVO"}	)
	_nPosHr	:= aScan(oGet1:aHeader,{|x| AllTrim(x[2]) == "TLW_HRDEVO"}	)
	_nPosQt	:= aScan(oGet1:aHeader,{|x| AllTrim(x[2]) == "TLW_QTDEVO"}	)
	_nPosAr	:= aScan(oGet1:aHeader,{|x| AllTrim(x[2]) == "TLW_LOCAL"}	)

	DBSelectArea("NNR")
	DBSetOrder(1)
	If DBSeek(xFilial("NNR") + oGet1:aCols[oGet1:nAt][_nPosAr])

		If TNF->TNF_I_TPDV == "T" .Or. TNF->TNF_I_TPDV == "R"
	
			aAdd( aDevEpi , TNF->(Recno()) )
		
			RecLock("TNF",.F.)
			If TNF->TNF_QTDENT == (TNF->TNF_QTDEVO + oGet1:aCols[oGet1:nAt][_nPosQt])
				TNF->TNF_INDDEV := "1"
				TNF->TNF_I_TPDV := "E"
			Else
			    TNF->TNF_I_TPDV := " " 
			EndIf
			TNF->TNF_DTDEVO := oGet1:aCols[oGet1:nAt][_nPosDt]
			TNF->TNF_QTDEVO	:= TNF->TNF_QTDEVO + oGet1:aCols[oGet1:nAt][_nPosQt]
			TNF->TNF_I_QTDD := 0 // Este campo deve ser zerado toda vez que as tabela TNF e TLW forem atualizadas.
			TNF->TNF_I_IMPR := "1"  // 1=Sim, deve ser impresso o recibo.
			TNF->(MSUnLock())
		
			DBSelectArea("TLW")
			DBSetOrder(1)
			If DBSeek(xFilial("TLW") + cFornecEn + cLojaSvEn + cEpiSvoEn + cNumCapEn + cMatricEn + ;
					DToS(dDataSvEn) + cHoraSvEn ) // + DToS(oGet1:aCols[oGet1:nAt][_nPosDt]) + oGet1:aCols[oGet1:nAt][_nPosHr] )
				RecLock("TLW",.F.)
			Else
				RecLock("TLW",.T.)
			EndIf
		
			TLW->TLW_FILIAL := xFilial("TLW")
			TLW->TLW_FORNEC := cFornecEn
			TLW->TLW_LOJA   := cLojaSvEn
			TLW->TLW_CODEPI := cEpiSvoEn
			TLW->TLW_NUMCAP := cNumCapEn
			TLW->TLW_MAT    := cMatricEn
			TLW->TLW_DTENTR := dDataSvEn
			TLW->TLW_HRENTR := cHoraSvEn
			TLW->TLW_QTDEVO	:= oGet1:aCols[oGet1:nAt][_nPosQt]
			TLW->TLW_LOCAL	:= oGet1:aCols[oGet1:nAt][_nPosAr]
			TLW->TLW_DTDEVO	:= oGet1:aCols[oGet1:nAt][_nPosDt]
			TLW->TLW_HRDEVO	:= oGet1:aCols[oGet1:nAt][_nPosHr]
			TLW->TLW_TIPODV := "1" // Epi Devolvido  
			TLW->(MSUnLock())
						
			_cTmpLote	:= TNF->TNF_LOTECT
			_cTmpSubL	:= TNF->TNF_LOTESB
			_cTmpLocz	:= TNF->TNF_ENDLOC
			_cTmpNSer	:= TNF->TNF_NSERIE
			_cNUMSEQ	:= MdtMovEst("DE0", oGet1:aCols[oGet1:nAt][_nPosAr], cEpiSvoEn, oGet1:aCols[oGet1:nAt][_nPosQt], oGet1:aCols[oGet1:nAt][_nPosDt], " " , cMatricEn , nil ,;
								nil, TNF->TNF_NUMSEQ , _cTmpLote , _cTmpSubL , _cTmpLocz , _cTmpNSer )
			RecLock("TLW",.F.)
			TLW->TLW_NUMSEQ := _cNUMSEQ
			TLW->(MSUnLock())

			RecLock("SD3", .F.)
			SD3->D3_I_OBS := "RETORNO DE EPI DE REUSO SESMT."
			SD3->(MSUnLock())
			MsgInfo("O processo de devolução de EPI foi conluído com sucesso.", "AMDT00308 - Devolução de EPI")

		Else
			MsgAlert("Favor selecionar um EPI disponível para Devolução.","AMDT00309 - Devolução de EPI")

		EndIf
	Else
		MsgStop("O armazém " + oGet1:aCols[oGet1:nAt][_nPosAr] + " não está criado no sistema. Crie o armazém " + oGet1:aCols[oGet1:nAt][_nPosAr] + ", depois volte a executar esta rotina.","AMDT00310 - Devolução de EPI")

	EndIf
Else
	MsgStop("O processo de devolução de EPI foi cancelado pelo usuário.", "AMDT00311 - Devolução de EPI")
EndIf

FWRestArea(_aArea)
Return

/*
===============================================================================================================================
Programa----------: AMDTTOK
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 13/06/2016
Descrição---------: Função de validação da quantidade devolvida
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/                 //   1       2           3          4          5         6          7         8          9          10
User Function AMDTTOK(oGet1, nQtdadeEn, cMatricEn, cFornecEn, cLojaSvEn, cEpiSvoEn, cNumCapEn, dDataSvEn, cHoraSvEn,_nIQtdDev)

Local _aArea	:= FWGetArea()
Local _lRet		:= .T.
Local _nPosQtd	:= aScan(oGet1:aHeader,{|x| AllTrim(x[2]) == "TLW_QTDEVO"	})

If oGet1:aCols[oGet1:nAt][_nPosQtd] > nQtdadeEn
	MsgAlert("A quantidade devolvida não pode ser maior que a quantidade entregue.","AMDT00312")
	_lRet := .F.
EndIf

If oGet1:aCols[oGet1:nAt][_nPosQtd] == 0
	MsgAlert("A quantidade devolvida tem que ser maior que 0(zero).","AMDT00313")
	_lRet := .F.
EndIf

DBSelectArea("TNF")
TNF->(DBSetOrder(1))
If TNF->(DBSeek(xFilial("TNF") + cFornecEn + cLojaSvEn + cEpiSvoEn + cNumCapEn + cMatricEn + DToS(dDataSvEn) + cHoraSvEn))
	If oGet1:aCols[oGet1:nAt][_nPosQtd] > (TNF->TNF_QTDENT - TNF->TNF_QTDEVO)
		MsgStop('A quantidade a devolver deve ser menor ou igual ao saldo. Saldo: ' + AllTrim(Transform(TNF->TNF_QTDENT - TNF->TNF_QTDEVO,"@E 9,999,999.99")),"AMDT00314")
		_lRet := .F.
	EndIf
EndIf

If oGet1:aCols[oGet1:nAt][_nPosQtd] > _nIQtdDev
	MsgStop("A quantidade devolvida não pode ser maior que a quantidade de devolução informata na tela da rotina 'Dev.Almox.'."+;
	        "A quantidade disponível para devolução está visivel na parte superior da tela, no campo 'Qtd Devolvida', ao lado do campo 'Saldo'.","AMDT00315")
	_lRet := .F.
EndIf

FWRestArea(_aArea)
Return(_lRet)

/*
===============================================================================================================================
Programa----------: AMD003E
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 16/06/2016
Descrição---------: Função para excluir a EPI do Monitor
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AMD003E()

Local _aArea	:= FWGetArea()

If MsgYesNo("Deseja realmente confirmar a Devolução deste EPI?","AMDT00316")
	RecLock("TNF",.F.)
		TNF->TNF_I_TPDV := " "
	TNF->(MSUnLock())
	MsgInfo("O processo de exclução de EPI foi conluído com sucesso.","AMDT00317")
Else
	MsgAlert("Processo de exclusão canelado pelo usuário.","AMDT00318")
EndIf

FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: AMD003F
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 19/09/2016
Descrição---------: Função para validar o descarte do EPI
Parametros--------: Nenhum
Retorno-----------: _lRet - .T. continua com o descarte, .F. caso contrário
===============================================================================================================================
*/
User Function AMD003F()

Local _aArea	:= FWGetArea()
Local _lRet		:= .F.
Local _nPosForn
Local _nPosLoja
Local _nPosCodEPI
Local _nPosNumCap
Local _aOrd := SaveOrd({"TNF"})
Local _nRegAtu := TNF->(Recno())

If FUNNAME() == 'MDTA695'
	If MsgYesNo("Essa movimentação será de DESCARTE do EPI, deseja continuar?","AMDT00319")
		_lRet := .T.
		//============================================================================
		// TLW_FILIAL+TLW_FORNEC+TLW_LOJA+TLW_CODEPI+TLW_NUMCAP+TLW_MAT 
		//============================================================================
		_nPosForn   := aScan(aHeadPrin, {|x| AllTrim(Upper(X[2])) == "TNF_FORNEC" })
        _nPosLoja   := aScan(aHeadPrin, {|x| AllTrim(Upper(X[2])) == "TNF_LOJA" })
        _nPosCodEPI := aScan(aHeadPrin, {|x| AllTrim(Upper(X[2])) == "TNF_CODEPI" })
        _nPosNumCap := aScan(aHeadPrin, {|x| AllTrim(Upper(X[2])) == "TNF_NUMCAP" })
		
		TNF->(DBSetOrder(1)) // TNF_FILIAL+TNF_FORNEC+TNF_LOJA+TNF_CODEPI+TNF_NUMCAP+TNF_MAT+DToS(TNF_DTENTR)+TNF_HRENTR
		If TNF->(DBSeek(xFilial("TNF")+aOldTNF[nSalTNF][_nPosForn]+aOldTNF[nSalTNF][_nPosLoja]+aOldTNF[nSalTNF][_nPosCodEPI]+aOldTNF[nSalTNF][_nPosNumCap]+M->RA_MAT))
		    aAdd(ADevEPI,TNF->(Recno()))
		EndIf
		
		RestOrd(_aOrd)
        TNF->(DBGoTo(_nRegAtu))
	EndIf
Else
	_lRet := .T.
EndIf
If IsInCallStack("U_AMD003D")
   aCols[n][5] := '1' // Ficou definido (Analista André Carvalho) que o campo TLW_TIPODV (Repor Estoque) sempre será Sim='1', quando For a rotina AMD003D.
Else
   aCols[n][5] := '2' // Ficou definido (Analista André Carvalho) que o campo TLW_TIPODV (Repor Estoque) sempre será Não='2'.
EndIf

FWRestArea(_aArea)

Return(_lRet)


/*
===============================================================================================================================
Programa----------: AMD003V
Autor-------------: Julio de Paula Paz
Data da Criacao---: 25/10/2017
Descrição---------: Valida a digitação da quantidade de devolução de EPI.
Parametros--------: _nSaldo = Saldo disponível para devolução.
                    _nQtdADev = Quantidade a ser devolvida.
Retorno-----------: _lRet - .T. = Validação correta. /  .F. = foram encontrados problemas na validação.
===============================================================================================================================
*/
User Function AMD003V(_nSaldo,_nQtdADev)

Local _lRet := .T.

Begin Sequence
   If _nQtdADev <= 0
      MsgAlert("Informe uma quantidade de devolução maior que zero.","AMDT00320")
      _lRet := .F.
      Break
   EndIf
   
   If _nSaldo <_nQtdADev
      MsgAlert("A quantidade de devolução deve ser inferior ou igual ao saldo disponível.","AMDT00321")
      _lRet := .F.
      Break
   EndIf

End Sequence

Return _lRet
