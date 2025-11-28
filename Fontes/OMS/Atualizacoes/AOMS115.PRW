/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
Julio Paz     |27/08/2025| Chamado 51271. Ajustar a rotina para marcar e desmarcar todos os registros apenas quando For clicado 
			  |			 | na coluna de marca e desmarca.
Lucas Borges  |17/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "RWMAKE.CH"
#Include "AP5MAIL.CH"
#Include "TOTVS.ch"
#Include "RPTDEF.CH"
#Include "COLORS.CH"

/*
===============================================================================================================================
Programa----------: AOMS115
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2019
Descrição---------: Central de Geracao de Faturas - Chamado 29372
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS115()

	Private _oTRBF := nil
	Private _aTRBF := {}
	Private nQtdTit:= 0
	Private nValTit:= 0
	Private _dDtVenc:= dDataBase
	Private _nDesconto:=0
	Private _cLojaFor := "0001"
	Private _cHistoric:=Space(Len(SE2->E2_HIST))

If DAY(dDataBase) >  23//24 a 31
   _dDtVenc:=CTOD("08/"+StrZero( Month(Date())+1 , 2 ) +'/'+ StrZero( Year(Date()) , 4 ))
ElseIf DAY(dDataBase) >  8 //9 a 23
   _dDtVenc:=CTOD("23/"+StrZero( Month(Date())   , 2 ) +'/'+ StrZero( Year(Date()) , 4 ))
Else//1 a 8
   _dDtVenc:=CTOD("08/"+StrZero( Month(Date())   , 2 ) +'/'+ StrZero( Year(Date()) , 4 ))
EndIf

If Select("TRBSE2") > 0
   MsErase("TRBSE2")// O MsErase() pq ao contrario dá erro
   TRBSE2->(DBCloseArea())
EndIf 

If Select("TRBSE2ABT") > 0
   MsErase("TRBSE2")// O MsErase() pq ao contrario dá erro
   TRBSE2ABT->(DBCloseArea())
EndIf 

AOMS115INI()

If Select("TRBF") > 0
	If ValType(_oTRBF) == "O"
	   TRBF->(DBCloseArea())
	    _oTRBF:Delete()
	Else
	   TRBF->(DBCloseArea())
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS115INI
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2019
Descrição---------: Funcao que controla o processamento 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS115INI()

Local nI
Private _bOKPrin:= {|| U_AOMS115Val(2) }
Private _cMV_ZP1:= "ITAOMS115TR"
Private _cMV2ZP1:= "ITAOMS115T2"
Private _cMarca := GetMark()
Private _aParAux:= {}
Private _aParRet:= {}
Private _nPosColDesconto:=13
Private _nPosColHistoric:=18
Private _nPosDesconto:=16
Private _nPosHistoric:=13
Private _lLockZP1	 :=.F.
Private _cChaveFAT   :=""
Private _aChaveFAT   :={}


Private MV_PAR81:=Space(Len(SA2->A2_COD))
Private MV_PAR82:="NAO: Nao geradas"//1
Private MV_PAR83:=CTOD("")
Private MV_PAR84:=CTOD("")
Private MV_PAR85:=_dDtVenc

aAdd( _aParAux , { 1 , "Transportador"  , MV_PAR81, "@!", ""    , "SA2_05", ""          ,100      , .F. } )
aAdd( _aParAux , { 2 , "Faturas Geradas", MV_PAR82, {"NAO: Nao geradas","SIM: Geradas"} ,070 , "" , .T. } )
aAdd( _aParAux , { 1 , "Dt Emissao de"  , MV_PAR83, "@D", ""	, ""	  , ""          ,050      , .T. } )
aAdd( _aParAux , { 1 , "Dt Emissao Ate" , MV_PAR84, "@D", ""	, ""	  , ""          ,050      , .T. } )
aAdd( _aParAux , { 1 , "Vencimento"     , MV_PAR85, "@D", ""	, ""	  , ""          ,050      , .T. } )

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next

While .T.

	nOpca:=0
	//aParametros, cTitle                                  , @aRet     ,[bOk]    , [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ]
	If ParamBox( _aParAux , "Geração de Fatura para o Transportador" , @_aParRet , _bOKPrin, /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
		MV_PAR81:=MV_PAR01
		MV_PAR82:=If(MV_PAR02="NAO: Nao geradas",1,2)
		MV_PAR83:=MV_PAR03
		MV_PAR84:=MV_PAR04
		MV_PAR85:=MV_PAR05
		If !AOM115Trava(.T.)
			Loop
		EndIf
		_lTemReg:=.F.
		// Cria o arquivo Temporario para insercao dos dados selecionados.
		FWMsgRun( , {|oProc| _lTemReg:=AOMS115ArQ(oProc) }, "Aguarde!" , 'Lendo Dados das Notas...' )
		If _lTemReg
			nOpca:=AOMS115TRS()//TELA PRICIPAL
		Else
			U_ITMsg("Não há registros, altere o filtro!","ATENCAO",,3)
			nOpca:=3
		EndIf

	EndIf

	AOM115Trava(.F.)

	If nOpca <> 3
		Exit
	EndIf

EndDo

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS115TRS
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2019
Descrição---------: Função que monta a tela para processar
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS115TRS()

Local oPanel		:= Nil
Local oDlg1			:= Nil
Local nHeight		:= 0
Local nWidth		:= 0
Local aSize			:= {}
Local aBotoes		:= {}
Local aCoors		:= {}
Local _bValD  := {|| If(_dDtVenc >= dDataBase,.T.,(U_ITMsg("Data de VENCIMENTO INVALIDA",'Atenção!',"Tente novamente com a data de vencimento MAIOR OU IGUAL QUE HOJE",3),.F.) ) }
Local _bValV:={|| If(POSITIVO(_nDesconto),(oValor:Refresh(),.T.),.F.) }

Private nOpca	 := 2
Private oMark	 := Nil
Private oQtda	 := Nil
Private oValor   := Nil
Private _nPos    :=1
// Botoes da tela.
aAdd( aBotoes , { "" , {|| AOMS115LEG() }   , "" , "LEGENDA"          } )
aAdd( aBotoes , { "" , {|| AOMS115ALL() }   , "" , "DES / MARCA TODOS"} )
aAdd( aBotoes , { "" , {|| AOMS115C(2) 	}	, "" , "PESQUISAR"		  } )
aAdd( aBotoes , { "" , {|| AOMS115C(5) 	}	, "" , "Exporta Excel"    } )
// Faz o calculo automatico de dimensoes de objetos
aSize := MSADVSIZE()


While .T.

	nOpca:= 2
	If MV_PAR82 = 2//JÁ GERADOS
		_nDesconto:=0//Zera o descont opor causa da tela de estorno
	EndIf
	DEFINE MSDIALOG oDlg1 TITLE "CENTRAL DE GERACAO DE FATURAS "+If(MV_PAR82=1,"[ FATURAS NAO GERADAS ]","[ FATURAS GERADAS ]")+If(Empty(MV_PAR81),"","[ Cod. Forn. : "+AllTrim(MV_PAR81)+" ]") From 0,0 To aSize[6],aSize[5] PIXEL

	oPanel:= TPanel():New(30,0,'',oDlg1,, .T., .T.,, ,315,20,.T.,.T. )
	oFont := TFont():New('Times New Roman',,-15,.T.)

	_nCol :=10
	_nSize:=60
	_nPula:=64

	If MV_PAR82 = 2//JÁ GERADOS                //Loop   ,SAI
		_bOK:={|| nOpca:= 2,oDlg1:End() }//{|| If(AOMS115C(8),(If(AOMS115C(1),nOpca:=1,nOpca:=3),oDlg1:End()),) } //SEM PERGUNTE()
		_bEF:={|| If(AOMS115C(8),(If(AOMS115C(1),nOpca:=1,nOpca:=3),oDlg1:End()),) } //SEM PERGUNTE()
		@003,_nCol BUTTON "ESTORNA FATURA"   SIZE _nSize, 015 PIXEL OF oPanel ACTION EVAL(_bEF)
	Else //NÃO GERADOS                //Loop   ,SAI
		_bOK:={|| If(AOMS115C(6),(If(AOMS115C(1),nOpca:=1,nOpca:=3),oDlg1:End()),) }//SEM PERGUNTE()
		@003,_nCol BUTTON "GERA FATURA"      SIZE _nSize, 015 PIXEL OF oPanel ACTION EVAL(_bOK)
	EndIf

	_nCol+=_nPula
	//Loop               ,NADA
	@003,_nCol BUTTON "PESQUISAR" SIZE _nSize, 015 PIXEL OF oPanel ACTION ( If(AOMS115C(2),(nOpca:=1,oDlg1:End()),   ) )
	_nCol+=_nPula
	//Loop   ,SAI
	//    @003,_nCol BUTTON "ATUALIZAR" SIZE _nSize, 015 PIXEL OF oPanel ACTION ( If(AOMS115C(3),nOpca:=1,nOpca:=3),oDlg1:End() )//COM PERGUNTE()
	//	_nCol+=_nPula
	@003,_nCol BUTTON "EXPORTA EXCEL"   SIZE _nSize, 015 PIXEL OF oPanel ACTION (AOMS115C(5))
	_nCol+=_nPula

	If MV_PAR82 = 2//JÁ GERADOS
		@003,_nCol BUTTON "RE-ENVIA E-MAIL" SIZE _nSize, 015 PIXEL OF oPanel ACTION (AOMS115C(7))
		_nCol+=_nPula
	EndIf

	If MV_PAR82 = 2//JÁ GERADOS

		@003,_nCol BUTTON "VER TITULOS" SIZE _nSize, 015 PIXEL OF oPanel ACTION (AOMS115C(4))
		_nCol+=_nPula

	Else

		TSay():New(06,_nCol,{||'Vencimento:'},oPanel,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,200,18)
		_nCol+=_nPula
		_nCol-=25
		_dDtVenc:=MV_PAR85
		@ 05,_nCol MSGET _dDtVenc Size 050,10 COLORS CLR_RED,CLR_WHITE Picture "@D" PIXEL OF oPanel FONT oFont  VALID Eval(_bValD) WHEN .F.
		_nCol+=_nPula
		_nCol-=10

		TSay():New(06,_nCol,{||"Desconto Fatura:"},oPanel,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,100,15)
		_nCol+=_nPula
		_nCol-=10

		@ 05,_nCol MSGET _nDesconto Size 060,10 COLORS CLR_RED,CLR_WHITE Picture "@E 999,999.99" PIXEL OF oPanel	FONT oFont VALID EVAL(_bValV)
		_nCol+=_nPula

	EndIf

	oValor:= TSay():New(06,_nCol,{||'Valor: '+AllTrim(TRANSFORM(nValTit-_nDesconto,"@E 999,999,999,999,999,999,999.99"))},oPanel,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)//560
	_nCol+=_nPula

	oQtda := TSay():New(06,_nCol,{||'Quant.: '+AllTrim(TRANSFORM(nQtdTit,"@E 999,999,999,999,999"))},oPanel,,oFont,,,,.T.,CLR_BLACK,CLR_WHITE,200,20)//470


	If FlatMode()
		aCoors	:= GetScreenRes()
		nHeight	:= aCoors[2]
		nWidth	:= aCoors[1]
	Else
		nHeight	:= 143
		nWidth	:= 315
	EndIf

	//TCBrowse():New( [ nRow ], [ nCol ], [ nWidth ], [ nHeight ], [ bLine ], [ aHeaders ], [ aColSizes ], [ oWnd ], [ cField ], [ uValue1 ], [ uValue2 ], [ bChange ], [ bLDblClick ]  , [ bRClick ], [ oFont ], [ oCursor ], [ nClrFore ], [ nClrBack ], [ cMsg ], [ uParam20 ], [ cAlias ], [ lPixel ], [ bWhen ], [ uParam24 ], [ bValid ], [ lHScroll ], [ lVScroll ] )
	oMark:= TCBrowse():New(35,  01   , 35+nHeight, 01+nwidth  ,          ,             ,              , oDlg1   ,           ,            ,            ,            ,                 ,            ,          ,            ,             ,             ,         ,    .F.      ,           ,   .T.     ,          ,    .F.      ,           ,             ,              )
	oMark:SetArray(_aTRBF)
	oMark:bHeaderClick := {|| If(oMark:ColPos()==1,AOMS115ALL(),"") } 
	oMark:bLDblClick   := {|| AOMS115INV()}
	oMark:AddColumn(TCColumn():New(" "       ,{|| LoadBitmap(GetResources(), If(Len(_aTRBF)>0,If(_aTRBF[oMark:nat,01]==_cMarca,"LBOK","LBNO"),"LBNO") ) },,,,,,.T.,.F.,,,,.F., ) )              //01
	oMark:AddColumn(TCColumn():New(" "       ,{|| LoadBitmap(GetResources(), If(Len(_aTRBF)>0,U_AO115Tipo(_aTRBF[oMark:nat,19],.T.),' '))  },    ,,,,,.T.,.F.,,,,.F., ) )                       //02
	oMark:AddColumn(TCColumn():New(Getsx3cache("E2_PREFIXO","X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,02], ' ') },Getsx3cache("E2_PREFIXO","X3_PICTURE"),,,"LEFT"  ,025,.F.,.F.,,,,,)) //03
	oMark:AddColumn(TCColumn():New(Getsx3cache("E2_NUM"    ,"X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,03], ' ') },Getsx3cache("E2_NUM"    ,"X3_PICTURE"),,,"CENTER",030,.F.,.F.,,,,,)) //04
	oMark:AddColumn(TCColumn():New(Getsx3cache("E2_PARCELA","X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,04], ' ') },Getsx3cache("E2_PARCELA","X3_PICTURE"),,,"CENTER",030,.F.,.F.,,,,,)) //05
	oMark:AddColumn(TCColumn():New(Getsx3cache("E2_TIPO"   ,"X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,05], ' ') },Getsx3cache("E2_TIPO"   ,"X3_PICTURE"),,,"LEFT"  ,020,.F.,.F.,,,,,)) //06
	oMark:AddColumn(TCColumn():New(Getsx3cache("E2_NATUREZ","X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,06], ' ') },Getsx3cache("E2_NATUREZ","X3_PICTURE"),,,"CENTER",025,.F.,.F.,,,,,)) //07
	If MV_PAR82 = 2//JÁ GERADOS
		oMark:AddColumn(TCColumn():New(Getsx3cache("E2_FORNECE","X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,18]+" "+_aTRBF[oMark:nat,07]+'-'+_aTRBF[oMark:nat,20], ' ') },Getsx3cache("E2_FORNECE","X3_PICTURE"),,,"LEFT"  ,150,.F.,.F.,,,,,))//08
	Else
		oMark:AddColumn(TCColumn():New(Getsx3cache("E2_LOJA"   ,"X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,07], ' ') },Getsx3cache("E2_LOJA"   ,"X3_PICTURE"),,,"CENTER",030,.F.,.F.,,,,,))//08
	EndIf
	oMark:AddColumn(TCColumn():New(Getsx3cache("E2_EMISSAO","X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,08], ' ') },Getsx3cache("E2_EMISSAO","X3_PICTURE"),,,"CENTER",040,.F.,.F.,,,,,))//09
	oMark:AddColumn(TCColumn():New(Getsx3cache("E2_VENCREA","X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,09], ' ') },Getsx3cache("E2_VENCREA","X3_PICTURE"),,,"CENTER",040,.F.,.F.,,,,,))//10
	oMark:AddColumn(TCColumn():New(Getsx3cache("E2_VALOR"  ,"X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,10], ' ') },Getsx3cache("E2_VALOR"  ,"X3_PICTURE"),,,"RIGHT" ,040,.F.,.F.,,,,,))//11
	oMark:AddColumn(TCColumn():New(Getsx3cache("E2_SALDO"  ,"X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,11], ' ') },Getsx3cache("E2_SALDO"  ,"X3_PICTURE"),,,"RIGHT" ,040,.F.,.F.,,,,,))//12
	oMark:AddColumn(TCColumn():New(Getsx3cache("E2_SDDECRE","X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,16], ' ') },Getsx3cache("E2_SDDECRE","X3_PICTURE"),,,"RIGHT" ,040,.F.,.F.,,,,,))//13  _nPosColDesconto se mudar atere essa variavel
	oMark:AddColumn(TCColumn():New("Valor na Fatura"                    ,{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,17], ' ') },Getsx3cache("E2_VALOR"  ,"X3_PICTURE"),,,"RIGHT" ,050,.F.,.F.,,,,,))//14
	oMark:AddColumn(TCColumn():New(Getsx3cache("E2_BAIXA"  ,"X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,12], ' ') },Getsx3cache("E2_BAIXA"  ,"X3_PICTURE"),,,"CENTER",040,.F.,.F.,,,,,))//15
	oMark:AddColumn(TCColumn():New(Getsx3cache("E2_DATALIB","X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,14], ' ') },Getsx3cache("E2_DATALIB","X3_PICTURE"),,,"CENTER",040,.F.,.F.,,,,,))//16
	oMark:AddColumn(TCColumn():New(Getsx3cache("E2_USUALIB","X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,15], ' ') },Getsx3cache("E2_USUALIB","X3_PICTURE"),,,"LEFT"  ,045,.F.,.F.,,,,,))//17
	oMark:AddColumn(TCColumn():New(Getsx3cache("E2_HIST"   ,"X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,13], ' ') },Getsx3cache("E2_HIST"   ,"X3_PICTURE"),,,"LEFT"  ,110,.F.,.F.,,,,,))//18 _nPosColHistoric se mudar atere essa variavel
	If MV_PAR82 <> 2
		oMark:AddColumn(TCColumn():New(Getsx3cache("E2_FORNECE","X3_TITULO"),{|| If(Len(_aTRBF)>0,_aTRBF[oMark:nat,18], ' ') },Getsx3cache("E2_FORNECE","X3_PICTURE"),,,"LEFT"  ,040,.F.,.F.,,,,,))//19
	EndIf
	oMark:GOPOSITION(_nPos)
	oDlg1:lMaximized:=.T.

	ACTIVATE MSDIALOG oDlg1 ON INIT ( EnchoiceBar(oDlg1,_bOK,;
		{|| nOpca:= 2,oDlg1:End() },,aBotoes),;
		oPanel:Align:=CONTROL_ALIGN_TOP ,;
		oMark:Align:=CONTROL_ALIGN_ALLCLIENT ,;
		oMark:Refresh())
	If nOpca = 1
		Loop
	ElseIf nOpca = 2  //.AND. !U_ITMsg("Confirmar Sair ?",'Atenção!',,3,2,2)                         //ESC //0    //1       //2     //3
		nRet:=Aviso("AOMS115 - Selecao de Opções" , "Escolha Sair para o menu , Filtrar novamente ou Voltar? ", {"Voltar","Filtrar","Sair"} ,1 )
		If nRet = 3//Sair
			nOpca:=2
			Exit
		ElseIf nRet = 2 //Filtrar
			nOpca:=3
			Exit
		EndIf
		Loop//Voltar
	EndIf

	Exit

EndDo

Return nOpca

/*
===============================================================================================================================
Programa----------: AOMS115INV
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2019
Descrição---------: Rotina de duplo clique na linha do browse
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS115INV()

	Local _nlinpos  := oMark:nat//, nI
	Local _bOK      :={|| If(POSITIVO(_nDescTtit).AND. TRBF->E2_SALDO > _nDescTtit ,.T.,(U_ITMsg("Valor de desconto INVALIDO",'Atenção!',"Tente novamente com valor maior que zero e menor que o saldo",3),.F.) ) }
	Private _nDescTtit:=0

	TRBF->(DBGoTo(_aTRBF[_nlinpos, Len(_aTRBF[1]) ]))

	If oMark:nColPos == _nPosColDesconto .And. TRBF->E2_TIPO <> "NDF" .And. AllTrim(_cMarca)==AllTrim(_aTRBF[_nlinpos,01]) .And. MV_PAR82 = 1//NÃO GERADOS
		If !TRBF->PODALT
			U_ITMsg("Título já contém desconto.",'Atenção!',"Para alterar entre em contato com o setor Financeiro.",1)
			Return
		EndIf
		_nDescTtit:=_aTRBF[_nlinpos,_nPosDesconto]
		lOK:=.F.
		@ 00,00 To 100,280 Dialog oDlgDes Title "Desconto do Titulo Posicionado"
		@ 11,10 Say "DESCONTO:" Pixel of oDlgDes
		@ 10,50 MsGet _nDescTtit Picture "@E 999,999,999.99"  Pixel Of oDlgDes
		@ 30,50 BMPBUTTON Type 1 ACTION (If(EVAL(_bOK),(lOK:=.T.,Close(oDlgDes)),))
		@ 30,82 BMPBUTTON Type 2 ACTION Close(oDlgDes)
		Activate Dialog oDlgDes Center

		If lOK
			nValTit+= _aTRBF[_nlinpos,_nPosDesconto]//ACRESCENTA O ANTERIOR
			nValTit-= _nDescTtit//DESCONTA O ATUAL
			TRBF->E2_SDDECRE:=_nDescTtit
			TRBF->VLR_FAT   :=TRBF->E2_SALDO-_nDescTtit
			_aTRBF[_nlinpos,_nPosDesconto]  :=_nDescTtit   //TRBF->E2_SDDECRE
			_aTRBF[_nlinpos,_nPosDesconto+1]:=TRBF->VLR_FAT//TRBF->VLR_FAT
			oValor:Refresh()
			oMark:Refresh()
			oMark:Setarray(_aTRBF)
			ProcessMessages()
		EndIf

	ElseIf oMark:nColPos == _nPosColHistoric .And. AllTrim(_cMarca)==AllTrim(_aTRBF[_nlinpos,01]) .And. MV_PAR82 = 1//NÃO GERADOS

		_cHisTit:=_aTRBF[_nlinpos,_nPosHistoric]
		lOK:=.F.
		@ 00,00 To 100,300 Dialog oDlgDes Title "Historico do Titulo Posicionado"
		@ 12,10 Say "HISTORICO:" Pixel of oDlgDes
		@ 10,48 MsGet _cHisTit Picture "@!"  Pixel Of oDlgDes SIZE 090, 010
		@ 30,50 BMPBUTTON Type 1 ACTION (If(EVAL(_bOK),(lOK:=.T.,Close(oDlgDes)),))
		@ 30,82 BMPBUTTON Type 2 ACTION Close(oDlgDes)
		Activate Dialog oDlgDes Center

		If lOK
			TRBF->E2_HIST:=_cHisTit
			_aTRBF[_nlinpos,_nPosHistoric]:=_cHisTit
			oMark:Refresh()
			oMark:Setarray(_aTRBF)
			ProcessMessages()
		EndIf

	ElseIf (TRBF->E2_TIPO <> "NDF" .Or. MV_PAR82 = 2)//GERADOS

		//Duplo clique na marcação

		If AllTrim(_cMarca)==AllTrim(_aTRBF[_nlinpos,01])
			nQtdTit--
			nValTit-= TRBF->VLR_FAT
			_aTRBF[_nlinpos,01] := "  "
		Else
			nQtdTit++
			nValTit+= TRBF->VLR_FAT
			_aTRBF[_nlinpos,01] := _cMarca
		EndIf

		TRBF->OK := _aTRBF[_nlinpos,01]

	Else

		U_ITMsg("Tipo NDF não pode ser desmarcado",'Atenção!',,1)

	EndIf

	oQtda:Refresh()
	oValor:Refresh()

Return

/*
===============================================================================================================================
Programa----------: AOMS115ALL
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2019
Descrição---------: Rotina para inverter a marcacao de todos os registros.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS115ALL()

Local nReg     := _aTRBF[oMark:nAt, Len(_aTRBF[1]) ]
Local _nnp     := 1
Local _cMarcALL:= If(_aTRBF[oMark:nAt,1]==_cMarca,Space(2),_cMarca)//OU MARCA TODOS OU DESMARCA TODOS

For _nnp := 1 To Len(_aTRBF)

	TRBF->(DBGoTo(_aTRBF[_nnp, Len(_aTRBF[1]) ]))
	If TRBF->E2_TIPO = "NDF"
		Loop
	EndIf

	If !Empty(_aTRBF[_nnp,1]) .And.  Empty(_cMarcALL)

		TRBF->OK       := Space(2)
		_aTRBF[_nnp,01]:= Space(2)
		nQtdTit--
		nValTit-= TRBF->VLR_FAT

	ElseIf Empty(_aTRBF[_nnp,1]) .And. !Empty(_cMarcALL)

		TRBF->OK       := _cMarca
		_aTRBF[_nnp][1]:= _cMarca
		nQtdTit++
		nValTit+= TRBF->VLR_FAT

	EndIf

	nQtdTit := IIf( nQtdTit < 0 , 0 , nQtdTit )

Next

TRBF->( DBGoTo(nReg) )
oQtda:Refresh()
oValor:Refresh()
oMark:Refresh()
ProcessMessages()

Return

/*
===============================================================================================================================
Programa----------: AOMS115Arq
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2019
Descrição---------: Rotina para criação do arquivo temporário
Parametros--------: oProc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS115Arq(oProc)

Local _cQuery1:= ""  , nUsado
Local _npv    := 0
Local _lTemReg:=.F.
Local aEstru  := {}
Local _aSE2   := {}

aAdd(_aSE2,"E2_PREFIXO")
aAdd(_aSE2,"E2_NUM"    )
aAdd(_aSE2,"E2_PARCELA")
aAdd(_aSE2,"E2_TIPO"   )
aAdd(_aSE2,"E2_NATUREZ")
aAdd(_aSE2,"E2_FORNECE")
aAdd(_aSE2,"E2_LOJA"   )
aAdd(_aSE2,"E2_EMISSAO")
aAdd(_aSE2,"E2_VENCREA")
aAdd(_aSE2,"E2_VALOR"  )
aAdd(_aSE2,"E2_SALDO"  )
aAdd(_aSE2,"E2_BAIXA"  )
aAdd(_aSE2,"E2_HIST"   )
aAdd(_aSE2,"E2_DATALIB")
aAdd(_aSE2,"E2_USUALIB")
aAdd(_aSE2,"E2_SDDECRE")
aAdd(_aSE2,"A2_NOME")
For nUsado := 1 To Len(_aSE2)
	aAdd( aEstru , {Getsx3cache(_aSE2[nUsado],"X3_CAMPO")  ,;
		Getsx3cache(_aSE2[nUsado],"X3_TIPO")   ,;
		Getsx3cache(_aSE2[nUsado],"X3_TAMANHO"),;
		Getsx3cache(_aSE2[nUsado],"X3_DECIMAL")})
Next
aAdd(aEstru,{"REC_SE2","N",10,0})
aAdd(aEstru,{"OK"     ,"C",02,0})
aAdd(aEstru,{"VLR_FAT","N",15,5})
aAdd(aEstru,{"TIPO"   ,"C",01,0})
aAdd(aEstru,{"PODALT" ,"L",01,0})
aAdd(aEstru,{"PODEST" ,"L",01,0})

//================================================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
//================================================================================
If Select("TRBF") > 0
	If ValType(_oTRBF) == "O"
		TRBF->(DBCloseArea())
		_oTRBF:Delete()
	Else
		TRBF->(DBCloseArea())
	EndIf
EndIf

oProc:cCaption := ("Criando arquivo temporário...")
ProcessMessages()

_oTRBF:=FWTemporaryTable():New( "TRBF", aEstru )
_oTRBF:AddIndex( "TR", {"E2_NUM"       } )
_oTRBF:AddIndex( "CO", {"TIPO","E2_NUM"} )
_oTRBF:AddIndex( "DT", {"E2_EMISSAO","E2_NUM"} )
_oTRBF:Create()

oProc:cCaption := ("Lendo dados dos Titulos...")
ProcessMessages()

_cQuery1+= " SELECT SE2.R_E_C_N_O_ SE2_REC  "
_cQuery1+= "		FROM " + RetSqlName("SE2")+" SE2         "
_cQuery1+= "  WHERE SE2.D_E_L_E_T_ = ' ' "

If MV_PAR82 = 2//SIM JÁ GERADOS
	// Filtra Emissao
	If !Empty(MV_PAR84)
		_cQuery1 += "  AND ( E2_TIPO <> 'NDF' AND SE2.E2_EMISSAO BETWEEN '" + DToS(MV_PAR83) + "' AND '" + DToS(MV_PAR84) + "' ) "
	ElseIf !Empty(MV_PAR83)
		_cQuery1 += "  AND ( E2_TIPO <> 'NDF' AND SE2.E2_EMISSAO >= '" + DToS(MV_PAR83) + "' )  "
	EndIf

	// _cQuery1+= " AND SE2.E2_SALDO = SE2.E2_VALOR "
	_cQuery1+= " AND SE2.E2_PREFIXO = 'MAN' "
	_cQuery1+= " AND SE2.E2_TIPO = 'FT ' "
	_cQuery1+= " AND SE2.E2_ORIGEM = 'AOMS115' "
Else
	// Filtra Emissao
	If !Empty(MV_PAR84)
		_cQuery1 += "  AND (( E2_TIPO <> 'NDF' AND SE2.E2_EMISSAO BETWEEN '" + DToS(MV_PAR83) + "' AND '" + DToS(MV_PAR84) + "' ) "
	ElseIf !Empty(MV_PAR83)
		_cQuery1 += "  AND (( E2_TIPO <> 'NDF' AND SE2.E2_EMISSAO >= '" + DToS(MV_PAR83) + "' )  "
	EndIf
	_cQuery1+= " OR (SE2.E2_TIPO = 'NDF' AND SE2.E2_VENCREA <= '" + DToS(MV_PAR85) + "' ) ) "

	_cQuery1+= " AND SE2.E2_SALDO > 0 "
	_cQuery1+= " AND E2_FATURA ='" + Space(Len(SE2->E2_FATURA)) + "'"
	_cQuery1+= " AND E2_NUMBOR ='" + Space(Len(SE2->E2_NUMBOR)) + "'"
	_cQuery1+= " AND E2_IDDARF = '" + Space(Len(SE2->E2_IDDARF)) + "' "
	//Titulos originados no SIGAEFF não devem ser alterados
	_cQuery1+= " AND E2_ORIGEM NOT IN ('SIGAEFF ', 'FINA667 ', 'FINA677 ', 'FINI055 ') "
EndIf
_cQuery1 += "   AND SE2.E2_FILIAL  = '" + cFilAnt + "'"

If !Empty(MV_PAR81)
	If Len(AllTrim(MV_PAR81)) > 6
		_cQuery1+= " AND SE2.E2_FORNECE IN " + FormatIn(AllTrim(MV_PAR81),";")
	Else
		_cQuery1+= " AND SE2.E2_FORNECE = '" + MV_PAR81 + "'"
	EndIf
EndIf
_cQuery1+= " ORDER BY E2_EMISSAO, E2_NUM "

_cAlias:=GetNextAlias()
MPSysOpenQuery( _cQuery1 , _cAlias )

oProc:cCaption := ("Contando os dados lidos...")
ProcessMessages()
DBSelectArea(_cAlias)
(_cAlias)->(DBGoTop())
_cTot := 0
COUNT To _cTot
_cTot:=AllTrim(Str(_cTot))
_nTam:=Len(_cTot)
(_cAlias)->(DBGoTop())

_aTRBF := {}
nQtdTit:= 0
nValTit:= 0
SA2->(DBSetOrder(1))
ZZN->(DBSetOrder(9))

While (_cAlias)->(!Eof())

	//Atualiza régua
	_npv++
	oProc:cCaption := ("Processando Dados: "+ StrZero(_npv,_nTam) +" de "+ _cTot)
	ProcessMessages()

	SE2->(DBGoTo( (_cAlias)->SE2_REC ))
	SA2->(DBSeek(xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA))

	TRBF->(DBAPPEND())
	AVREPLACE("SE2","TRBF")
	TRBF->A2_NOME:= SA2->A2_NOME
	TRBF->REC_SE2:= (_cAlias)->SE2_REC
	TRBF->VLR_FAT:= SE2->E2_SALDO-SE2->E2_SDDECRE

	TRBF->PODALT := (SE2->E2_DECRESC = 0)

	If SE2->E2_SALDO == SE2->E2_VALOR .And. MV_PAR82 == 2
		TRBF->PODEST := .T.
	EndIf

	_cOK:="  "
	If MV_PAR82 = 2//SIM JÁ GERADOS
		TRBF->TIPO:="0" //FATURA GERADA //VERMELHO
	ElseIf TRBF->E2_TIPO = "NDF"
		TRBF->TIPO:="9" //Nota de debito //AZUL
		TRBF->E2_SALDO := SE2->E2_SALDO*(-1)
		TRBF->E2_VALOR := SE2->E2_VALOR*(-1)
		TRBF->VLR_FAT  := TRBF->VLR_FAT*(-1)
		_cOK:=_cMarca
	ElseIf ZZN->(DBSeek(cFilant+SE2->E2_NUM+SE2->E2_PREFIXO+SE2->E2_FORNECE+SE2->E2_LOJA))
		TRBF->TIPO:="1" //Com canhoto com zzn //VERDE
		_cOK:=_cMarca
	Else
		TRBF->TIPO:="5" //Sem canhoto //AMARELO
	EndIf
	TRBF->OK:=_cOK

	If !Empty(_cOK)
		nQtdTit++
		nValTit+= TRBF->VLR_FAT
	EndIf
	_lTemReg:=.T.

	(_cAlias)->( DBSkip() )

EndDo

(_cAlias)->( DBCloseArea())
ZZN->(DBSetOrder(1))

oProc:cCaption := ("Re-Ordenando por Tipo + Numero...")
ProcessMessages()
_aTRBF:={}
TRBF->(DBSetOrder(2))
TRBF->(DBGoTop())
While TRBF->(!Eof())
	_aItens:={}
	aAdd(_aItens,TRBF->OK        )//01
	aAdd(_aItens,TRBF->E2_PREFIXO)//02
	aAdd(_aItens,TRBF->E2_NUM    )//03
	aAdd(_aItens,TRBF->E2_PARCELA)//04
	aAdd(_aItens,TRBF->E2_TIPO   )//05
	aAdd(_aItens,TRBF->E2_NATUREZ)//06
	aAdd(_aItens,TRBF->E2_LOJA   )//07
	aAdd(_aItens,TRBF->E2_EMISSAO)//08
	aAdd(_aItens,TRBF->E2_VENCREA)//09
	aAdd(_aItens,TRBF->E2_VALOR  )//10
	aAdd(_aItens,TRBF->E2_SALDO  )//11
	aAdd(_aItens,TRBF->E2_BAIXA  )//12
	aAdd(_aItens,TRBF->E2_HIST   );_nPosHistoric:=Len(_aItens)//13   _nPosHistoric se mudar atera essa variavel
	aAdd(_aItens,TRBF->E2_DATALIB)//14
	aAdd(_aItens,TRBF->E2_USUALIB)//15
	aAdd(_aItens,TRBF->E2_SDDECRE);_nPosDesconto:=Len(_aItens)//16 	_nPosDesconto se mudar atera essa variavel
	aAdd(_aItens,TRBF->VLR_FAT   )//17
	aAdd(_aItens,TRBF->E2_FORNECE)//18
	aAdd(_aItens,TRBF->TIPO      )//19
	aAdd(_aItens,TRBF->A2_NOME   )//20
	aAdd(_aItens,TRBF->(RECNO()) )//21 - ULITMO SEMPRE
	aAdd(_aTRBF,_aItens)
	TRBF->( DBSkip() )
EndDo
TRBF->(DBGoTop())

Return _lTemReg

/*
===============================================================================================================================
Programa----------: AOMS115C()
Autor-------------: Alex Wallauer 
Data da Criacao---: 02/10/2019
Descrição---------: Chamada de itens do menu
Parametros--------: _nOpcao - Opção do menu
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS115C(_nOpcao)

If Len(_aTRBF) > 0
	TRBF->(DBGoTo(_aTRBF[oMark:NAT, Len(_aTRBF[1]) ]))
ElseIf _nOpcao <> 3
	U_ITMsg("Não há registros, altere o filtro!")
	Return .F.
EndIf

Do Case

Case _nOpcao == 1 //Atualizar AÇÕES RELACIONADAS SEM PERGUNTE()

	_lTemReg:=.F.
	FWMsgRun(,{ |oProc| _lTemReg:=AOMS115Arq(oProc) }, "Aguarde...","Carregando dados...")
	If !_lTemReg
		U_ITMsg("Não há registros, altere o filtro!","ATENCAO",,3)
	EndIf
	Return _lTemReg

Case _nOpcao == 2 //Pesquisa

	_lRet:=AOMS115PSQ()
	Return _lRet

Case _nOpcao == 3 //Atualizar BOTÃO COM PERGUNTE()

	_lRet:=.F.
	FWMsgRun(,{ |oProc| _lRet:=AOMS115Atu(oProc) }, "Aguarde...","Carregando dados...")
	Return _lRet

Case _nOpcao == 4 //VER TITULOS

	FWMsgRun(,{ |oProc| AOMS115Tit(oProc) }, "Aguarde...","Carregando dados...")

Case _nOpcao == 5	//Exporta Excel

	FWMsgRun(,{ |oProc| AOMS115XC(oProc) }, "Aguarde...","Carregando dados...")

Case _nOpcao == 6	//Gera NDF

	If (nValTit-_nDesconto) <= 0
		U_ITMsg("O Valor Total da Fatura deve ser maior que zero",'Atenção!',,3)
		Return .F.
	EndIf

	_lOK  :=.F.
	_cHistoric:=Space(Len(SE2->E2_HIST))
	_nTam1:=245
	_nTam2:=155
	_nColA:=009
	_nColB:=50
	_nColC:=_nColB+80
	_nLin1:=005
	_nLin2:=040
	DEFINE MSDIALOG oDlgH TITLE "GERACAO DA FATURA" From 0,0 To _nTam2,500 Of oMainWnd PIXEL

	oTPanel1:= TPanel():New(0,0,"",oDlgH,NIL,.T.,.F.,NIL,NIL,(_nTam2+150),200,.T.,.F.)

	@ _nLin1,_nColA Say "CONFIRMA A GERACAO DA FATURA ?"	Of oTPanel1 Pixel
	_nLin1+=11

	oTFolder1 := TFolder():New( _nLin1,005,{"Historico se desejar :"},,oTPanel1,,,,.T.,,_nTam1,_nLin2 )

	@ 005,010 MSGET _cHistoric Size 212,009 COLOR CLR_BLACK PICTURE "@!" OF oTFolder1:aDialogs[1] PIXEL

	_nLin1+=(_nLin2+5)
	TButton():New(_nLin1,_nColB, ' CONFIRMA ', oTPanel1,{|| _lOK:=.T. , oDlgH:END() },70,15,,,,.T.)
	TButton():New(_nLin1,_nColC, ' CANCELA ' , oTPanel1,{|| _lOK:=.F. , oDlgH:END() },70,15,,,,.T.)

	ACTIVATE MSDIALOG oDlgH Centered

	If _lOK//U_ITMsg("Confirmar Geracao de Faturas ?",'Atenção!',,3,2,2)
		_lRet:=.F.
		FWMsgRun(,{ |oProc| _lRet:=AOMS115GE(oProc,.F.,.T.) }, "Aguarde...","Gerando Fatura...")//ENVIA E-MAIL SEM TELA
		Return _lRet
	Else
		Return .F.
	EndIf

Case _nOpcao == 7	//ENVIA - EMAIL

	FWMsgRun(,{ |oProc| _lRet:=AOMS115GE(oProc,.T.,.T.) }, "Aguarde...","Lendo Fatura...")//ENVIA E-MAIL COM TELA

Case _nOpcao == 8	//Estorna NDF

	If U_ITMsg("Confirmar Estorno de Faturas ?",'Atenção!',,3,2,2)
		_lRet:=.F.
		FWMsgRun(,{ |oProc| _lRet:=AOMS115GE(oProc,.F.,.F.) }, "Aguarde...","Estorno Fatura...")//ENVIA E-MAIL SEM TELA
		Return _lRet
	Else
		Return .F.
	EndIf

EndCase

If Len(_aTRBF) > 0
	TRBF->(DBGoTo(_aTRBF[oMark:NAT, Len(_aTRBF[1]) ]))
EndIf

Return .T.
/*
===============================================================================================================================
Programa----------: AOMS115LEG
Autor-------------: Alex Wallauer 
Data da Criacao---: 02/10/2019
Descrição-------: Exibe a tela de detalhes da legenda
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function AOMS115LEG()
Local _aLegenda:={}
aAdd(_aLegenda,{"BR_VERDE"   ,"1-COM CANHOTO"   })
aAdd(_aLegenda,{"BR_AMARELO" ,"5-SEM CANHOTO"   })
aAdd(_aLegenda,{"BR_AZUL"    ,"9-NOTA DE DEBITO"})
aAdd(_aLegenda,{"BR_VERMELHO","0-FATURA GERADA" })

BrwLegenda("Faturas","Legenda" ,_aLegenda)

Return(.T.)
/*
===============================================================================================================================
Programa----------: AO115Tipo
Autor-------------: Alex Wallauer 
Data da Criacao---: 02/10/2019
Descrição-------: Retorna cor e legenda
Parametros------: _cCampo de controle da legenda
Retorno---------: string com cor da legenda da linha posicionada no TRBF
===============================================================================================================================
*/
User Function AO115Tipo(_cCampo,lTela)
If lTela
	If _cCampo = "1"
		Return "BR_VERDE"
	ElseIf _cCampo = "5"
		Return "BR_AMARELO"
	ElseIf _cCampo = "9"
		Return "BR_AZUL"
	EndIf
	Return "BR_VERMELHO"
Else
	If _cCampo = "1"
		Return "COM CANHOTO"
	ElseIf _cCampo = "5"
		Return "SEM CANHOTO"
	ElseIf _cCampo = "9"
		Return "NOTA DE DEBITO"
	ElseIf _cCampo = "0"
		Return "FATURA GERADA"
	EndIf
	Return "OUTROS"
EndIf

Return ""

/*
===============================================================================================================================
Programa----------: AOMS115Atu
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2019
Descrição---------: Função que refaz filtro da tela
Parametros--------: oProc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS115Atu(oProc)
Local _lTemReg:=.T.//INICIA COM .T. PQ NA PRIMIERA FEZ QUE ENTRA ESTA COM REGISTROS, e o usuario pode cancelar o ParamBox
While .T.
	MV_PAR01:=MV_PAR81
	MV_PAR02:=If(MV_PAR82=1,"NAO: Nao geradas","SIM: Geradas")
	MV_PAR03:=MV_PAR83
	MV_PAR04:=MV_PAR84
	MV_PAR05:=MV_PAR05
	If ParamBox( _aParAux , "Geração de Fatura para o Transportador" , @_aParRet , _bOKPrin)
		AOM115Trava(.F.)
		MV_PAR81:=MV_PAR01
		MV_PAR82:=If(MV_PAR02="NAO: Nao geradas",1,2)
		MV_PAR83:=MV_PAR03
		MV_PAR84:=MV_PAR04
		MV_PAR85:=MV_PAR05
		If !AOM115Trava(.T.)
			Loop
		EndIf
		_lTemReg:=.F.
		// Cria o arquivo Temporario para insercao dos dados selecionados.
		FWMsgRun( , {|oProc| _lTemReg:=AOMS115ArQ(oProc) }, "Aguarde!" , 'Lendo Dados das Notas...' )
		If _lTemReg
			Return .T.
		Else
			U_ITMsg("Não há registros, altere o filtro!","ATENCAO",,3)
			Loop
		EndIf
	EndIf
	Exit
EndDo

Return _lTemReg

/*
===============================================================================================================================
Programa----------: AOMS115PSQ
Autor-------------: Alex Wallauer
Data da Criacao---: 20/07/2019
Descrição---------: Funcao para pesquisa no arquivo temporario.
Parametros--------: oProc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS115PSQ( oProc)

Local oGet1		:= Nil ,nI
Local oDlg		:= Nil
Local cGet1		:= Space(40)
Local nOpca		:= 0
Local cComboBx1	:= ""
Local nIndAtual := TRBF->(IndexOrd())
Local aComboBx1	:= {"Numero do Titulo",;
	"Tipo + No. Tit.",;
	"Data de Emissao" }

DEFINE MSDIALOG oDlg TITLE "Pesquisar" FROM 178,181 To 259,697 PIXEL

@004,003 ComboBox	cComboBx1	Items aComboBx1 Size 213,010 OF oDlg PIXEL
@020,003 MsGet		oGet1		Var cGet1		Size 212,009 OF oDlg PIXEL COLOR CLR_BLACK Picture "@!"

DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( nOpca := 1 , oDlg:End() ) OF oDlg
DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( nOpca := 0 , oDlg:End() ) OF oDlg

ACTIVATE MSDIALOG oDlg CENTERED

If nOpca == 1
	For nI := 1 To Len(aComboBx1)
		If AllTrim(cComboBx1) == AllTrim(aComboBx1[nI])
			TRBF->( DBSetOrder(nI) )
			If TRBF->(DBSeek( AllTrim(cGet1) ))
				_nPos:=aScan(_aTRBF,{|x| x[ Len(_aTRBF[1]) ] == TRBF->(RECNO())})
				If _nPos = 0
					_nPos:=1
				EndIf
				oMark:GOPOSITION(_nPos)
				oMark:REFRESH()
			Else
				U_ITMsg("Registro não encontrado","Atenção",,1)
			EndIf
			Exit
		EndIf
	Next nI
EndIf

If nIndAtual <> nI
	If nI = 1
		_aTRBF := aSort( _aTRBF ,,, {|x, y| x[3] < y[3] } )
	ElseIf nI = 2
		_aTRBF := aSort( _aTRBF ,,, {|x, y| x[19]+x[3] < Y[19]+Y[3] } )
	ElseIf nI = 3
		_aTRBF := aSort( _aTRBF ,,, {|x, y| DToS(x[8]) < DToS(y[8]) } )
	EndIf
	oMark:SetArray(_aTRBF)
	_nPos:=aScan(_aTRBF,{|x| x[ Len(_aTRBF[1]) ] == TRBF->(RECNO())})
	If _nPos = 0
		_nPos:=1
	EndIf
	oMark:GOPOSITION(_nPos)
	oMark:REFRESH()
	Return .F.
EndIf

Return .F.

/*
===============================================================================================================================
Programa----------: AOMS115XC()
Autor-------------: Alex Wallauer 
Data da Criacao---: 20/07/2019
Descrição---------: Exporta browse para o excel
Parametros--------: oProc - objeto de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS115XC(oProc)

Local _aExcel := {}
Local _aCab   := {}
Local _aItens := {}
Local _cTot:=AllTrim(Str(Len(_aTRBF)))
Local _nTam:=Len(_cTot)
Local _npv :=0

aAdd(_aCab,"Tipo Titulo")//01
aAdd(_aCab,Getsx3cache("E2_PREFIXO","X3_TITULO"))//02
aAdd(_aCab,Getsx3cache("E2_NUM"    ,"X3_TITULO"))//03
aAdd(_aCab,Getsx3cache("E2_PARCELA","X3_TITULO"))//04
aAdd(_aCab,Getsx3cache("E2_TIPO"   ,"X3_TITULO"))//05
aAdd(_aCab,Getsx3cache("E2_NATUREZ","X3_TITULO"))//06
aAdd(_aCab,Getsx3cache("E2_FORNECE","X3_TITULO"))//18
aAdd(_aCab,Getsx3cache("E2_EMISSAO","X3_TITULO"))//08
aAdd(_aCab,Getsx3cache("E2_VENCREA","X3_TITULO"))//09
aAdd(_aCab,Getsx3cache("E2_VALOR"  ,"X3_TITULO"))//10
aAdd(_aCab,Getsx3cache("E2_SALDO"  ,"X3_TITULO"))//11
aAdd(_aCab,Getsx3cache("E2_SDDECRE","X3_TITULO"))//12
aAdd(_aCab,"Valor na Fatura")                    //13
aAdd(_aCab,Getsx3cache("E2_BAIXA"  ,"X3_TITULO"))//14
aAdd(_aCab,Getsx3cache("E2_HIST"   ,"X3_TITULO"))//15
aAdd(_aCab,Getsx3cache("E2_DATALIB","X3_TITULO"))//16
aAdd(_aCab,Getsx3cache("E2_USUALIB","X3_TITULO"))//17

_aExcel:={}
TRBF->(DBSetOrder(2))
TRBF->(DBGoTop())
While TRBF->(!Eof())
	_npv++
	oProc:cCaption := ("Lendo dados: "+StrZero(_npv,_nTam) +" de "+ _cTot)
	ProcessMessages()
	_aItens:={}
	aAdd(_aItens,U_AO115Tipo(TRBF->TIPO,.F.))//01
	aAdd(_aItens,TRBF->E2_PREFIXO)//02
	aAdd(_aItens,TRBF->E2_NUM    )//03
	aAdd(_aItens,TRBF->E2_PARCELA)//04
	aAdd(_aItens,TRBF->E2_TIPO   )//05
	aAdd(_aItens,TRBF->E2_NATUREZ)//06
	aAdd(_aItens,TRBF->E2_FORNECE+" "+TRBF->E2_LOJA+"-"+TRBF->A2_NOME)//07
	aAdd(_aItens,TRBF->E2_EMISSAO)//08
	aAdd(_aItens,TRBF->E2_VENCREA)//09
	aAdd(_aItens,TRBF->E2_VALOR  )//10
	aAdd(_aItens,TRBF->E2_SALDO  )//11
	aAdd(_aItens,TRBF->E2_SDDECRE)//12
	aAdd(_aItens,TRBF->VLR_FAT   )//13
	aAdd(_aItens,TRBF->E2_BAIXA  )//14
	aAdd(_aItens,TRBF->E2_HIST   )//15
	aAdd(_aItens,TRBF->E2_DATALIB)//16
	aAdd(_aItens,TRBF->E2_USUALIB)//17
	aAdd(_aExcel,_aItens)
	TRBF->( DBSkip() )

EndDo
TRBF->(DBGoTop())

If Len(_aExcel) > 0
	If MV_PAR82 = 1//NÃO GERADOS
		_cTitulo:="Titulos para geração de Fatura"
		_cMsgTop:=AllTrim(Str(Len(_aTRBF))+" Titulos. Valor DESCONTO "+AllTrim(TRANSFORM(_nDesconto,"@E 999,999,999.99")))
	Else
		_cTitulo:="Faturas Geradas"
		_cMsgTop:=AllTrim(Str(Len(_aTRBF))+" Faturas.")
	EndIf
//    ITListBox(_cTitAux, _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
	U_ITLISTBOX(_cTitulo, _aCab    , _aExcel   , .T.      , 1      ,_cMsgTop)
Else
	U_ITMsg("Nenhum registro encontrado!","Atenção",,1)
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS115GE()
Autor-------------: Alex Wallauer 
Data da Criacao---: 20/07/2019
Descrição---------: Le Titulos marcados para gera os Faturas
Parametros--------: oProc,_lEMail,_lGera
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS115GE(oProc,_lEMail,_lGera)

Local T
Local _aCab :={}
Local _aSize:={}
Local _lRet:=.T.
Local _cNrTitulos := ""

Default _lEMail:=.F.
//Default _cHistoric:=""
Private _aTLinhas:={}

oProc:cCaption := ("Processando Titulos...")
ProcessMessages()
_nConta:=0
TRBF->(DBGoTop())
While TRBF->(!Eof())
	If _lEMail
		If !Empty(TRBF->OK)
			_nConta++
		EndIf
	ElseIf _lGera .And. !Empty(TRBF->OK)//GERACAO
		_nConta++
	ElseIf !_lGera .And. !Empty(TRBF->OK)//ESTORNO
		_nConta++
	EndIf

	If ! Empty(TRBF->OK) .And. ! TRBF->PODEST .And. !_lGera // Titulos que não podem ser estornados.
		_cNrTitulos += If(Empty(_cNrTitulos),"",", ") + AllTrim(TRBF->E2_NUM) + If(!Empty(TRBF->E2_PARCELA),"-","") + AllTrim(TRBF->E2_PARCELA)
	EndIf

	TRBF->(DBSkip())
EndDo

If _nConta = 0
	If _lEMail
		U_ITMsg("Nenhum Fatura Selecionada","Atenção",,1)
	Else
		U_ITMsg("Nenhum Titulo Selecionado","Atenção",,1)
	EndIf
	Return .F.
EndIf

If ! Empty(_cNrTitulos)
	U_ITMsg("Os títulos: " + _cNrTitulos + ", não podem ser estornados pois estão compensados parcialmente ou totalmente. ","Atenção",,1)
	Return .F.
EndIf

_cTot:=AllTrim(Str(_nConta))
_nTam:=Len(_cTot)+1
_nConta:=0

SE2->( DBSetOrder(1) ) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA

aTitulos:={}
aTitAlt :={}

If _lEMail //REENVIO DE E-MAIL
	TRBF->(DBSetOrder(3))
EndIf

SA2->( DBSetOrder(1) )

TRBF->(DBGoTop())
SE2->(DBGoTo(TRBF->REC_SE2))
Private _dDtIni :=""//SE2->E2_EMISSAO//PRIMEIRO DA LISTA
Private _dDtFim :=""//SE2->E2_EMISSAO//PRIMEIRO DA LISTA
_aChaveFAT:={}

While TRBF->(!Eof())

	SE2->(DBGoTo(TRBF->REC_SE2))
	If _lEMail //REENVIO DE E-MAIL

		If !Empty(TRBF->OK)
			_nConta++
			oProc:cCaption := ("Lendo Fatura: "+AllTrim(Str(_nConta,_nTam)) +" de "+ _cTot)
			ProcessMessages()
			AOMS115Tit(oProc,TRBF->REC_SE2,.T.)//CARREGA OS TITULOS DA FATURA NO _aTLinhas
			_aItens:={}//REENVIO _lEmail TIRULOS + FATURA
			aAdd(_aItens,.T.              )//01
			aAdd(_aItens,TRBF->E2_PREFIXO )//02
			aAdd(_aItens,TRBF->E2_NUM     )//03
			aAdd(_aItens,TRBF->E2_PARCELA )//04
			aAdd(_aItens,TRBF->E2_TIPO    )//05
			aAdd(_aItens,TRBF->E2_NATUREZ )//06
			aAdd(_aItens,TRBF->E2_FORNECE )//07
			aAdd(_aItens,TRBF->E2_LOJA    )//08
			aAdd(_aItens,DToC(TRBF->E2_EMISSAO))//09
			aAdd(_aItens,DToC(TRBF->E2_VENCREA))//10
			aAdd(_aItens,AllTrim(TRANSFORM((TRBF->E2_SALDO-TRBF->E2_SDDECRE)*If(TRBF->E2_TIPO="NDF",-1,1),"@E 999,999,999,999.99")))//11 // tira o desocnto para ficar = ao envio
			aAdd(_aItens,AllTrim(TRANSFORM(TRBF->E2_SDDECRE,"@E 999,999,999,999.99")))//12
			aAdd(_aItens,TRBF->E2_HIST)         //13
			aAdd(_aItens,"Gerado com sucesso")  //14
			aAdd(_aItens,(TRBF->E2_SALDO-TRBF->E2_SDDECRE)*If(TRBF->E2_TIPO="NDF",-1,1))//15
			aAdd(_aItens,TRBF->E2_SDDECRE)//16
			aAdd(_aTLinhas,_aItens)
			aAdd(_aChaveFAT, TRBF->REC_SE2 )//RENNO DA FATURA NO SE2 P/ O ANEXO

		EndIf

	ElseIf _lGera .And. !Empty(TRBF->OK)//GERACAO
		_nConta++
		oProc:cCaption := ("Gerando Fatura: "+AllTrim(Str(_nConta,_nTam))+" de "+ _cTot)
		ProcessMessages()

		If Empty(_dDtIni) .Or. SE2->E2_EMISSAO < _dDtIni
			_dDtIni := SE2->E2_EMISSAO
		EndIf
		If Empty(_dDtFim) .Or. SE2->E2_EMISSAO > _dDtFim
			_dDtFim := SE2->E2_EMISSAO
		EndIf

		// Considerar Loja do Fornededor 08/04/2021  aAdd(aTitulos,{SE2->E2_PREFIXO, SE2->E2_NUM, SE2->E2_PARCELA , SE2->E2_TIPO,.F.})//,SE2->E2_FORNECE,SE2->E2_LOJA
		aAdd(aTitulos,{SE2->E2_PREFIXO, SE2->E2_NUM, SE2->E2_PARCELA , SE2->E2_TIPO,.F.,SE2->E2_FORNECE,SE2->E2_LOJA	  })

		If aScan(aTitAlt,{|A|A[5]==TRBF->E2_FORNECE}) = 0 .And. SA2->(DBSeek(xFilial("SA2")+TRBF->E2_FORNECE))
			If Empty(SA2->A2_BANCO) .Or. Empty(SA2->A2_AGENCIA) .Or. Empty(SA2->A2_NUMCON)
				U_ITMsg("Banco ou agencia ou conta do cadastro do fornecedor não preenchido","Atenção",;
					"Cadastre para o fornecedor+loja: "+TRBF->E2_FORNECE+" "+SA2->A2_LOJA+" - "+SA2->A2_NREDUZ,1)
				Return .F.
			EndIf
		EndIf

		aAdd(aTitAlt ,{TRBF->REC_SE2   ,;//1
		TRBF->E2_SDDECRE,;//2
		(TRBF->E2_SDDECRE <> SE2->E2_SDDECRE .Or. TRBF->E2_HIST <> SE2->E2_HIST ),;//3
		TRBF->E2_HIST   ,;//4
		TRBF->E2_FORNECE})//5


	ElseIf !_lGera .And. !Empty(TRBF->OK) //ESTORNO
		_nConta++
		oProc:cCaption := ("Estornando Fatura: "+SE2->E2_NUM+" - "+AllTrim(Str(_nConta,_nTam))+" de "+ _cTot)
		ProcessMessages()

		AOM115Estorno(oProc)//ESTORNO DA FATURA
	EndIf

	TRBF->(DBSkip())

EndDo
TRBF->(DBGoTop())

_cTot:=AllTrim(Str(Len(aTitAlt)))
_nTam:=Len(_cTot)+1
_nConta:=0

_lAlterouTodas:=.T.
If _lGera .And. Len(aTitulos) > 0
	For T:= 1 To Len(aTitAlt)
		SE2->(DBGoTo( aTitAlt[T,1] ))
		_nConta++
		oProc:cCaption := ("Alterando Titulo: "+SE2->E2_NUM+" - "+AllTrim(Str(_nConta,_nTam)) +" de "+ _cTot)
		ProcessMessages()
		If aTitAlt[T,3] .And. !AOM114Altera(oProc,aTitAlt[T])//ALTERA E APROVEITA LIBERA OS TITULOS COM ALTERACAO DO DESCONTO E HISTORICO
			_lRet:=_lAlterouTodas:=.F.
			Exit
		EndIf
	Next
	If _lAlterouTodas
		_nConta:=0
		For T:= 1 To Len(aTitAlt)
			_nConta++
			oProc:cCaption := ("Liberando Titulo - "+AllTrim(Str(_nConta,_nTam)) +" de "+ _cTot)
			ProcessMessages()
			If !aTitAlt[T,3] //SÓ LIBERA OS SEM ALTERACAO DO DESCONTO
				SE2->(DBGoTo( aTitAlt[T,1] ))
				SE2->(RecLock("SE2",.F.))
				SE2->E2_DATALIB := dDataBase
				SE2->E2_USUALIB := cUserName
				SE2->(MSUnLock())

				_aItens:={}//_lEmail TITULOS
				aAdd(_aItens,.T.)
				aAdd(_aItens,SE2->E2_PREFIXO)
				aAdd(_aItens,SE2->E2_NUM)
				aAdd(_aItens,SE2->E2_PARCELA)
				aAdd(_aItens,SE2->E2_TIPO)
				aAdd(_aItens,SE2->E2_NATUREZ)
				aAdd(_aItens,SE2->E2_FORNECE)
				aAdd(_aItens,SE2->E2_LOJA   )
				aAdd(_aItens,DToC(SE2->E2_EMISSAO))
				aAdd(_aItens,DToC(SE2->E2_VENCREA))
				aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_SALDO*If(SE2->E2_TIPO="NDF",-1,1),"@E 999,999,999,999.99")))//11
				aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_DECRESC,"@E 999,999,999,999.99")))//12
				aAdd(_aItens,SE2->E2_HIST   )//13
				aAdd(_aItens,"Liberado com sucesso")  //14
				aAdd(_aItens,SE2->E2_SALDO*If(SE2->E2_TIPO="NDF",-1,1))//15
				aAdd(_aItens,SE2->E2_DECRESC)//16
				aAdd(_aTLinhas,_aItens)

			EndIf
		Next
		oProc:cCaption := "GERANDO FATURA..."
		ProcessMessages()
//**********************  GERACAO DA FATURA AQUI *************************************************
		_lRet:=AOMS115SE(oProc,aTitulos,aTitAlt[1,1])
//**********************  GERACAO DA FATURA AQUI *************************************************
	EndIf
EndIf

//Monta aheader
aAdd(_aCab,"")//01
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_PREFIXO","X3_TITULO"))//02
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_NUM"    ,"X3_TITULO"))//03
aAdd(_aSize,12)
aAdd(_aCab,Getsx3cache("E2_PARCELA","X3_TITULO"))//04
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_TIPO"   ,"X3_TITULO"))//05
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_NATUREZ","X3_TITULO"))//06
aAdd(_aSize,8)
aAdd(_aCab,Getsx3cache("E2_FORNECE","X3_TITULO"))//07
aAdd(_aSize,35)
aAdd(_aCab,Getsx3cache("E2_LOJA"   ,"X3_TITULO"))//08
aAdd(_aSize,5)
aAdd(_aCab,"Emissão")//09
aAdd(_aSize,40)
aAdd(_aCab,Getsx3cache("E2_VENCREA" ,"X3_TITULO"))//10
aAdd(_aSize,40)
aAdd(_aCab,"Valor Total")//11
aAdd(_aSize,40)
aAdd(_aCab,Getsx3cache("E2_SDDECRE","X3_TITULO"))//12
aAdd(_aSize,30)
aAdd(_aCab,Getsx3cache("E2_HIST"   ,"X3_TITULO"))//13
aAdd(_aSize,70)
aAdd(_aCab,"Resultado / Histórico")//14
aAdd(_aSize,70)
//_aSize:=NIL
If Len(_aTLinhas) > 0

	AOMS115Email(_aTLinhas,_lEMail,oProc,_lGera,_aCab)

	If _lEMail
		Return  .T.
	EndIf
	nPosResu:=Len(_aCab)//Posiçao do "Resultado"

	aBotoes:={}
	If _lGera  .And. _lRet
		_nRegSE2:=SE2->(RECNO())//Guardo o recno em uma variavel pq o SE2 vai ser desposionado
		aAdd( aBotoes , { "" , {|| FWMsgRun(,{ |oProc| AOMS115Tit(oProc,_nRegSE2)}, "","") },"","Ver Titulos"} )
	EndIf
	aAdd( aBotoes , { "" , {|| AVISO("ATENCAO",oLbxAux:aArray[oLbxAux:nAt][ nPosResu ],{"Fechar"},3) }	, "" , "Ver Resultado"		  } )
//    ITListBox(_cTitAux               , _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
	U_ITLISTBOX("Faturas Processados: ", _aCab    , _aTLinhas , .T.      , 4      ,          ,          , _aSize  ,         ,     ,        , aBotoes)
Else
	U_ITMsg("Nenhum registro localizado","Atenção",,1)
EndIf

Return .T.//_lRet .T. Sempre para recarregar a tela sempre
/*
===============================================================================================================================
Programa----------: AOMS115SE()
Autor-------------: Alex Wallauer 
Data da Criacao---: 23/07/2019
Descrição---------: Gera os Faturas dos Transportadores marcaods
Parametros--------: oProc,_aTitulos,nRecSE2
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS115SE(oProc,_aTitulos,nRecSE2)

Local _nModAux  := nModulo
Local _cModAux  := cModulo
Local _lRet     := .T.
Local _cNatureza:= SuperGetMV("IT_NATFAT",.F.,"231007")
Local _cFornece :=TRBF->E2_FORNECE
Local _cLoja    :="0001"  // se For autoriza
Local _cNome    :=TRBF->A2_NOME
Local _cCondicao:="001" //, nSeq
Local _dDtorig  := dDataBase
Local _nTit

SA2->( DBSetOrder(1) )
If SA2->(DBSeek(xFilial("SA2")+_cFornece))
	_cLoja:=SA2->A2_LOJA
	_cNome:=SA2->A2_NREDUZ
EndIf

If U_ITVACESS( 'ZZL' , 3 , 'ZZL_ALTLJT' , 'S' )

	_cLojaFor := _cLoja
	If U_AOMS115R(_cFornece)//A PERGUNTA FOI PARA DENTRO DA FUNÇÃO
		_cLoja := _cLojaFor // Atribui na variável _cLoja, a loja selecionada na tela da função U_AOMS115R().
	EndIf

EndIf

_aItens:={}//_lEmail FATURA
aAdd(_aItens,.T.)       //01
aAdd(_aItens,"MAN")     //02
aAdd(_aItens,""       ) //03  PREENCHIDO APOS A GERAÇÃO
aAdd(_aItens,'01')      //04
aAdd(_aItens,"FT ")     //05
aAdd(_aItens,_cNatureza)//06
aAdd(_aItens,_cFornece) //07
aAdd(_aItens,_cLoja)    //08
aAdd(_aItens,DToC(DataValida( _dDtVenc )))//09
aAdd(_aItens,DToC(DataValida( _dDtVenc )))//10
aAdd(_aItens,"" )              //11  PREENCHIDO APOS A GERAÇÃO // 11
aAdd(_aItens,AllTrim(TRANSFORM(_nDesconto,"@E 999,999,999,999.99")))//12
aAdd(_aItens,_cHistoric)//13
aAdd(_aItens,"")//14 - _cErro
aAdd(_aItens,0) //15 - SE2->E2_VALOR-_nDesconto
aAdd(_aItens,_nDesconto)//16

cLog:=""
_cFatura2 := Soma1(GetMV( 'MV_NUMFATP' ,, '0' ))
_cChaveFAT:=cFilAnt + "MAN" + _cFatura2  + '01' + "FT " + _cFornece+_cLoja
SE2->( DBSetOrder(1) )
While SE2->( DBSeek( _cChaveFAT ) )
	cLog+=" / Achou: [ "+_cChaveFAT+" ] "
	PutMV("MV_NUMFATP", _cFatura2)
	_cFatura2:=Soma1(_cFatura2)
	_cChaveFAT:=cFilAnt + "MAN" + _cFatura2  + '01' + "FT " + _cFornece+_cLoja
EndDo

//Cria Fatura no financeiro
aArray:={}
aAdd(aArray,"MAN")     //01
aAdd(aArray,"FT" )     //02
aAdd(aArray,' ')       //03 //Em branco para seguir sequência de fatura do Protheus
aAdd(aArray,_cNatureza)//04
aAdd(aArray,_dDtIni)   //05
aAdd(aArray,_dDtFim)   //06
aAdd(aArray,_cFornece) //07
aAdd(aArray,"    ")    //08 //Loja em branco para trazer todos os títulos do fornecedor
aAdd(aArray,_cFornece) //09
aAdd(aArray,_cLoja)    //10
aAdd(aArray,_cCondicao)//11
aAdd(aArray,1)         //12
aAdd(aArray,_aTitulos) //13
aAdd(aArray,_nDesconto)//14
aAdd(aArray,0)         //15

nModulo	   := 6
cModulo	   := "FIN"
lMsErroAuto:=.F.
dDataBase  := DataValida( _dDtVenc )

SE2->(DBGoTo( nRecSE2 ))//POSICIONA NO PRIMEIRO TITULO DA LISTA

Begin Sequence

	BEGIN TRANSACTION
		DBSelectArea( "SE5" )
		MsExecAuto( { |x,y| FINA290(x,y)},3,aArray,) //INCLUSAO DA FATURA

		_cErro:="FATURA Gerada com Sucesso"
		If lMsErroAuto

			_cErro:=AllTrim(MOSTRAERRO())//GETTEMPPATH()))
			_cErro:="Não Gerou. Acesse Ver Resultado: "+CHR(13)+CHR(10)+AllTrim(_cErro)
			_aItens[1]:=.F.
			_lRet:= .F.
			DisarmTransaction()

		Else

			_cChaveFAT:=cFilAnt + "MAN" + _cFatura2  + '01' + "FT " + _cFornece+_cLoja

			SE2->( DBSetOrder(1) )
			If SE2->( DBSeek( _cChaveFAT ) )

				SE2->( RecLock('SE2',.F.) )
				SE2->E2_VENCTO	:= _dDtVenc
				SE2->E2_VENCORI	:= _dDtVenc
				SE2->E2_VENCREA	:= DataValida( _dDtVenc )
				SE2->E2_HIST    := _cHistoric
				SE2->E2_ORIGEM  := "AOMS115"
				SE2->( MSUnLock() )

				_aItens[03]:=_cFatura2
				_aItens[11]:=AllTrim(TRANSFORM(SE2->E2_VALOR-SE2->E2_SDDECRE,"@E 999,999,999,999.99"))
				_aItens[15]:=SE2->E2_VALOR-_nDesconto
				aAdd(_aChaveFAT, SE2->(RECNO()) )

				AOMSGRVFI8(_aTitulos)

			Else

				_cChaveFAT:=cFilAnt + "MAN [ " + _cFatura2  + ' ] 01' + "FT " + _cFornece+_cLoja
				_cErro:="NÃO GEROU FATURA. Acesse Ver Resultado: "+CHR(13)+CHR(10)+"Titulo da fatura não localizado: "+_cChaveFAT+" / MV_NUMFATP = [ "+GetMV('MV_NUMFATP')+" ] "+cLog
				_aItens[01]:=.F.
				_aItens[03]:=_cFatura2
				_cChaveFAT :=""
				_lRet:= .F.
				DisarmTransaction()
				Break

			EndIf

		EndIf

	END TRANSACTION
End Sequence

DBSelectArea("SE5")
DBSetOrder(2)  // FILIAL + TIPODOC + PREFIXO + NUMERO + PARCELA

For _nTit := 1 To Len(_aTitulos)
	If SE5->(DBSeek(xFilial("SE5")+"DC"+_aTitulos[_nTit][1]+_aTitulos[_nTit][2]+_aTitulos[_nTit][3]+_aTitulos[_nTit][4]+DToS(dDataBase)+_aTitulos[_nTit][6]+_aTitulos[_nTit][7]))		
		RecLock("SE5",.F.)
		SE5->E5_TPDESC ="I"
		SE5->(MSUnLock())
	EndIf
Next _nTit
SE5->(DBCloseArea())


_aItens[14]:=_cErro//14
aAdd(_aTLinhas,_aItens)

nModulo  := _nModAux
cModulo  := _cModAux
dDataBase:= _dDtorig

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS115Email()
Autor-------------: Alex Wallauer
Data da Criacao---: 25/07/2019
Descrição---------: Monta e envia email 
Parametros--------: _aTLinhas,_lTela,oProc,_lGera,_aCab
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS115Email(_aTLinhas,_lTela,oProc,_lGera,_aCab)

Local _aConfig	:= U_ITCFGEML('')
Local _cEmlLog	:= ""
Local _cMsgEml	:= ""
Local nOpcA		:= 2   , _nI , oDlgMail , _aSizes:={}
Local cGetCc	:= Space(200)
Local cGetMens	:= Space(999)//Esta é uma mensagem automática
Local cGetPara	:= SuperGetMV("IT_NDFEMAI",.F.,"") + Space(150)
Local _cTot     := AllTrim(Str(Len(_aTLinhas)))
Local _nTam     := Len(_cTot)
Local _cNome	:= ""
Local _cNomeFil := cFilAnt+" - "+AllTrim( Posicione('SM0',1,"01"+cFilAnt,'M0_FILIAL') )
Local cGetAssun	:= ""
Local cPathLocal    := GetTempPath()

SA2->( DBSetOrder(1) )
If !Empty(MV_PAR81) .And. SA2->(DBSeek(xFilial("SA2")+LEFT(MV_PAR81,Len(SA2->A2_COD))+_aTLinhas[Len(_aTLinhas)][08]))
	_cNome:=': '+LEFT(MV_PAR81,Len(SA2->A2_COD))+" - "+AllTrim(SA2->A2_NREDUZ)
ElseIf Len(_aChaveFAT) = 1
	SE2->( DBGoTo( _aChaveFAT[1] ) )
	If SA2->(DBSeek(xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA))
		_cNome:=': '+SE2->E2_FORNECE+" - "+AllTrim(SA2->A2_NREDUZ)
	EndIf
EndIf

If (Len(PSWRET()) # 0) // Quando nao For rotina automatica do configurador
	PswOrder(1)
	PswSeek(__cUserId,.T.)
	aUsuario:= PswRet()
	cGetCc  := LOWER(AllTrim(aUsuario[1,14]))+Space(150)// Pega e-mail do usuario
EndIf
If Empty(cGetPara)
	cGetPara:=cGetCc
EndIf
If _lGera
	cGetAssun:= "Geração de Fatura do Transportador"+_cNome+" / Filial:  "+_cNomeFil+" - ["+DToC(dDataBase)+"]"
Else
	If !Empty(MV_PAR81) .Or. Len(_aChaveFAT) = 1
		cGetAssun:= "Estorno de Fatura do Transportador"+_cNome+" / Filial:  "+_cNomeFil+" - ["+DToC(dDataBase)+"]"
	Else
		cGetAssun:= "Estorno de Faturas de Transportadores - Filial: "+_cNomeFil+" - ["+DToC(Date())+"]"
	EndIf
EndIf
_cMsgEml := '<html>'
_cMsgEml += '<head><title>'+cGetAssun+'</title></head>'
_cMsgEml += '<body>'
_cMsgEml += '<style Type="text/css"><!--'
_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
_cMsgEml += 'td.itens2  { font-family:VERDANA; font-size:13px; V-align:middle; margin-right: 16px; margin-left: 16px; background-color: #FFFFFF; }'
_cMsgEml += '--></style>'
_cMsgEml += '<center>'
_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
_cMsgEml += '<table class="bordasimples" width="800">'
_cMsgEml += '    <tr>'
_cMsgEml += '	     <td class="titulos"><center>'+cGetAssun+'</center></td>'
_cMsgEml += '	 </tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="800">'
_cMsgEml += '    <tr>'
If MV_PAR82 = 1//NÃO GERADOS
	_cMsgEml += '      <td align="center" colspan="2" class="grupos">DADOS DE ENVIO</b></td>'
Else//GERADOS
	_cMsgEml += '      <td align="center" colspan="2" class="grupos">DADOS DE REENVIO</b></td>'
EndIf
_cAlinha:="left"
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="'+_cAlinha+'" width="35%"><b>Enviado por: </b></td>'
_cMsgEml += '      <td class="itens" >'+ UsrFullName(__cUserId) +'</td>'
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="'+_cAlinha+'" width="35%"><b>Filial:</b></td>'
_cMsgEml += '      <td class="itens" >'+ _cNomeFil +'</td>'
_cMsgEml += '    </tr>'

If !Empty(MV_PAR81) .Or. Len(_aChaveFAT) = 1
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="'+_cAlinha+'" width="35%"><b>Valor Total dos Titulos a pagar:</b></td>'
	_cMsgEml += '      <td class="itens" >#VLRTOTIT#</td>'
	_cMsgEml += '    </tr>'

	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="'+_cAlinha+'" width="35%"><b>Valor Total dos Titulos NDF:</b></td>'
	_cMsgEml += '      <td class="itens" >#VLRTOTNDF#</td>'
	_cMsgEml += '    </tr>'

	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="'+_cAlinha+'" width="35%"><b>Valor Total dos Decréscimos</b></td>'
	_cMsgEml += '      <td class="itens" >#DESCTOTIT#</td>'
	_cMsgEml += '    </tr>'

	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="'+_cAlinha+'" width="35%"><b>Valor do Desconto da Fatura:</b></td>'
	_cMsgEml += '      <td class="itens" >#DESCFAT#</td>'
	_cMsgEml += '    </tr>'

	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="'+_cAlinha+'" width="35%"><b>Valor Liquido da Fatura:</b></td>'
	_cMsgEml += '      <td class="itens2" ><b>#VLRLIQFAT#</b></td>'
	_cMsgEml += '    </tr>'
EndIf

_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="'+_cAlinha+'" width="30%"><b>Observações:</b></td>'
_cMsgEml += '      <td class="itens" >#OBS#</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="1250">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="10" class="grupos">Faturas do Transportador<b>'+_cNome+'</b></td>'
_cMsgEml += '    </tr>'

_cMsgEml += '    <tr>'
//        02   03   04  05   06   07   08  09  10  11  12   13 
_aSizes:={"2","7", "2","4" ,"  ","  ","7","7","7","12","7","50"}
//        01  02   03  04    05    06  07  08  09  10  11  12 
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[01]+'%"><b>Pref.</b></td>'//01
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[02]+'%"><b>'+_aCab[03]+'</b></td>'//02
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[03]+'%"><b>Parc.</b></td>'//03
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[04]+'%"><b>'+_aCab[05]+'</b></td>'//04
//_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[05]+'%"><b>'+_aCab[06]+'</b></td>'
//_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[06]+'%"><b>'+_aCab[07]+'</b></td>'
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[07]+'%"><b>'+_aCab[08]+'</b></td>'//05
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[08]+'%"><b>'+_aCab[09]+'</b></td>'//06 emissao
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[09]+'%"><b>Venct.Real</b></td>'//07 VECTO
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[10]+'%"><b>Vlr Total</b></td>'  //08 VALOR TOTAL
_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[11]+'%"><b>'+_aCab[12]+'</b></td>'//09 DESCONTO
If !Empty(MV_PAR81) .Or. Len(_aChaveFAT) = 1
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[12]+'%"><b>Resultado / Histórico</b></td>'//10
Else
	_cMsgEml += '      <td class="itens" align="center" width="'+_aSizes[12]+'%"><b>Fornecedor / Histórico</b></td>'//10
EndIf

_cMsgEml += '    </tr>'
_cMsgEml += '    #LISTA#'
_cMsgEml += '</table>'
_cMsgEml += '</center>'
_cMsgEml += '<br>'
_cMsgEml += '<br>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [AOMS115]</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'

Private cGetAnx	:= ""
Private cGetAnxl:= ""
Private nVlrTotit := nDesTotit:=nVlrLiqFat:=nDescFat:=nVlrNDF:=0

For _nI := 1 To Len(_aTLinhas)
	If _aTLinhas[_nI][05] = "FT "
		nVlrLiqFat+=_aTLinhas[_nI][15]
		nDescFat  +=_aTLinhas[_nI][16]
	Else
		If _aTLinhas[_nI][15] > 0
			nVlrTotit+=_aTLinhas[_nI][15]
		Else
			nVlrNDF  +=_aTLinhas[_nI][15]
		EndIf
		nDesTotit   +=_aTLinhas[_nI][16]
	EndIf
Next

nVlrNDF:=(nVlrNDF*-1)

If Len(_aChaveFAT) = 1
	SE2->( DBSetOrder(1) )
	SE2->( DBGoTo( _aChaveFAT[1] ) )
	oProc:cCaption:="Gerando PDF da Fatura: "+SE2->E2_NUM
	ProcessMessages()
	AOMSRel7E(_aTLinhas,_aChaveFAT,oProc)
EndIf

If _lTela
	oMainWnd:ReadClientCoords()//So precisa declarar uma fez para o Programa todo

	DEFINE MSDIALOG oDlgMail TITLE "E-Mail" FROM 000, 000  To 415,999 COLORS 0, 16777215 PIXEL
	_nLinha:=05
	_nPula :=16
	_nWidth:=((oDlgMail:nClientWidth-6)/2)-8
	_nSize :=_nWidth-24
	// Para:
	@ _nLinha+2, 005 Say "Para:" SIZE 015, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ _nLinha  , 030 MSGET cGetPara SIZE _nSize, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL
	_nLinha+=_nPula

	// Com cópia:
	@ _nLinha+2, 005 Say "Cc:" SIZE 015, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ _nLinha  , 030 MSGET cGetCc SIZE _nSize, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL
	_nLinha+=_nPula

	// Assunto:
	@ _nLinha+2, 005 Say "Assunto:" SIZE 022, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ _nLinha  , 030 MSGET cGetAssun SIZE _nSize, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL
	_nLinha+=_nPula

	// Mensagem:
	@ _nLinha+2, 005 Say "Observ.:" SIZE 030, 007 OF oDlgMail COLORS 0, 16777215 PIXEL
	@ _nLinha  , 030 MSGET cGetMens SIZE _nSize, 010 OF oDlgMail PICTURE "@x" COLORS 0, 16777215 PIXEL
	_nLinha+=_nPula

	// LISTA
	//TCBrowse():New( [ nRow ], [ nCol ], [ nWidth ], [ nHeight ], [ bLine ], [ aHeaders ], [ aColSizes ], [ oWnd ], [ cField ], [ uValue1 ], [ uValue2 ], [ bChange ], [ bLDblClick ]  , [ bRClick ], [ oFont ], [ oCursor ], [ nClrFore ], [ nClrBack ], [ cMsg ], [ uParam20 ], [ cAlias ], [ lPixel ], [ bWhen ], [ uParam24 ], [ bValid ], [ lHScroll ], [ lVScroll ] )
	oMark2:= TCBrowse():New(070 , 006  ,_nWidth , 110  ,          ,             ,              , oDlgMail ,           ,            ,            ,            ,                 ,            ,          ,            ,             ,             ,         ,    .F.      ,           ,   .T.     ,          ,    .F.      ,           ,             ,              )
	oMark2:SetArray(_aTLinhas)
	oMark2:AddColumn(TCColumn():New(_aCab[01],{|| LoadBitmap(GetResources(), If(_aTLinhas[oMark2:nat,01],"BR_VERDE","BR_VERMELHO")) },,,,,,.T.,.F.,,,,.F., ) )
	oMark2:AddColumn(TCColumn():New(_aCab[02],{|| If(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,02], ' ') },"@!"       	,,,"LEFT" ,020,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[03],{|| If(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,03], ' ') },"@!"       	,,,"LEFT" ,020,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[04],{|| If(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,04], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[05],{|| If(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,05], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[06],{|| If(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,06], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[07],{|| If(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,07], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[08],{|| If(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,08], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[09],{|| If(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,09], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[10],{|| If(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,10], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[11],{|| If(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,11], ' ') },"@!"         ,,,"RIGHT",050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[12],{|| If(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,12], ' ') },"@!"         ,,,"RIGHT",050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[14],{|| If(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,14], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))
	oMark2:AddColumn(TCColumn():New(_aCab[13],{|| If(Len(_aTLinhas)>0,_aTLinhas[oMark2:nat,13], ' ') },"@!"       	,,,"LEFT" ,050,.F.,.F.,,,,,))

	@ 189, 005 BUTTON "ENVIAR"		 SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 1 , oDlgMail:End() ) PIXEL
	@ 189, 050 BUTTON "CANCELAR"	 SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 2 , oDlgMail:End() ) PIXEL
	If File(cGetAnxl)
		@ 189,095 BUTTON "Visualizar" SIZE 037, 012 OF oDlgMail ACTION ( ShellExecute("open", cGetAnxl, "", cPathLocal, 1) ) PIXEL
	EndIf
	ACTIVATE MSDIALOG oDlgMail CENTERED

Else
	cGetMens:="Esta é uma mensagem automática"
EndIf

If nOpcA == 1 .Or. !_lTela

	_cMsgEml:=StrTran(_cMsgEml,"#OBS#",AllTrim(cGetMens))
	_cGetLista:=""
	_lEnvio:=.F.
	_cNegI:=""
	_cNegF:=""

	For _nI := 1 To Len(_aTLinhas)

		If _aTLinhas[_nI][05] = "FT "
			_cNegI:="<b>"
			_cNegF:="</b>"
		Else
			_cNegI:=""
			_cNegF:=""
		EndIf
		oProc:cCaption := ("Lendo dados da Fatura: "+AllTrim(Str(_nI,_nTam))+" de "+ _cTot)
		ProcessMessages()
		_cGetLista += '    <tr>'
		_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[01]+'%">'+_cNegI+_aTLinhas[_nI][02]+_cNegF+'</td>'
		_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[02]+'%">'+_cNegI+_aTLinhas[_nI][03]+_cNegF+'</td>'
		_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[03]+'%">'+_cNegI+_aTLinhas[_nI][04]+_cNegF+'</td>'
		_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[04]+'%">'+_cNegI+_aTLinhas[_nI][05]+_cNegF+'</td>'
		_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[07]+'%">'+_cNegI+_aTLinhas[_nI][08]+_cNegF+'</td>'
		_cGetLista += '      <td class="itens2" align="center" width="'+_aSizes[08]+'%">'+_cNegI+_aTLinhas[_nI][09]+_cNegF+'</td>'
		_cGetLista += '      <td class="itens" align="center" width="'+_aSizes[09]+'%">'+_cNegI+_aTLinhas[_nI][10]+_cNegF+'</td>'
		_cGetLista += '      <td class="itens" align="right" width="' +_aSizes[10]+'%">'+_cNegI+_aTLinhas[_nI][11]+_cNegF+'</td>'
		_cGetLista += '      <td class="itens" align="right" width="' +_aSizes[11]+'%">'+_cNegI+_aTLinhas[_nI][12]+_cNegF+'</td>'
		If !Empty(MV_PAR81) .Or. Len(_aChaveFAT) = 1
			_cGetLista += '      <td class="itens" align="left" width="'+_aSizes[12]+'%">'+_cNegI+_aTLinhas[_nI][14]+If( !Empty(_aTLinhas[_nI][13]) ," / "+_aTLinhas[_nI][13],"" )+_cNegF+'</td>'
		Else
			SA2->(DBSeek(xFilial("SA2")+LEFT(_aTLinhas[_nI][07],Len(SA2->A2_COD))+_aTLinhas[_nI][08]))
			_cGetLista += '      <td class="itens" align="left" width="'  +_aSizes[12]+'%">'+_cNegI+ _aTLinhas[_nI][07]+" - "+AllTrim(SA2->A2_NREDUZ)+If( !Empty(_aTLinhas[_nI][14]) ," / "+_aTLinhas[_nI][14],"" )+_cNegF+'</td>'
		EndIf
		_cGetLista += '    </tr>'
		_lEnvio:=.T.

	Next

	If _lEnvio
		_cMsgEml:=StrTran(_cMsgEml,"#LISTA#"    ,_cGetLista)
		_cMsgEml:=StrTran(_cMsgEml,"#VLRTOTIT#" ,"R$ "+TRANSFORM(nVlrTotit ,"@E 999,999,999,999.99"))
		_cMsgEml:=StrTran(_cMsgEml,"#VLRTOTNDF#","R$ "+TRANSFORM(nVlrNDF   ,"@E 999,999,999,999.99"))
		_cMsgEml:=StrTran(_cMsgEml,"#DESCTOTIT#","R$ "+TRANSFORM(nDesTotit ,"@E 999,999,999,999.99"))
		_cMsgEml:=StrTran(_cMsgEml,"#DESCFAT#"  ,"R$ "+TRANSFORM(nDescFat  ,"@E 999,999,999,999.99"))
		_cMsgEml:=StrTran(_cMsgEml,"#VLRLIQFAT#","R$ "+TRANSFORM(nVlrLiqFat,"@E 999,999,999,999.99"))

		U_ITENVMAIL( Lower(AllTrim(UsrRetMail(RetCodUsr()))), cGetPara, cGetCc, "", cGetAssun, _cMsgEml, cGetAnx, _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

		U_ITMsg(Upper(_cEmlLog)+CHR(13)+CHR(10)+;
			"E-mail para: "+cGetPara +CHR(13)+CHR(10)+;
			"Com Copia: "+cGetCc+CHR(13)+CHR(10),"Envio do E-MAIL",,3)

	EndIf

EndIf

If File(cGetAnxl)
	nRet := fErase(cGetAnxl)
	If nRet <> 0
		u_itconout("Erro ao excluir o arquivo: " + cGetAnxl + " - Erro: " + Str(FError()))
	Else
		u_itconout("Arquivo: " + cGetAnxl + " foi excluído com sucesso.")
	EndIf
EndIf

If File(cGetAnx)
	nRet := fErase(cGetAnx)
	If nRet <> 0
		u_itconout("Erro ao excluir o arquivo: " + cGetAnx + " - Erro: " + Str(FError()))
	Else
		u_itconout("Arquivo: " + cGetAnx + " foi excluído com sucesso.")
	EndIf
EndIf

_aChaveFAT:={}

Return .T.

/*
===============================================================================================================================
Programa----------: AOM115Trava()
Autor-------------: Alex Wallauer 
Data da Criacao---: 31/07/2019
Descrição---------: Travaa tela para um usuario por filial
Parametros--------: lTrava
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOM115Trava(lTrava)

Local _nCnt01  	:= 0
Local _lLockZP1	:= .F.
Local _lLock2ZP1:= .F.
Local _cSalva:= ""
Return .T.//DESATIVADO POR ENQUANTO 
If !lTrava//DESTRAVA
    DBSelectArea("ZP1")
	ZP1->(DBSetOrder(2))
	If ZP1->(MSSEEK( xFilial('ZP1') + cFilant + _cMV_ZP1 ))//TRAVA POR FILIAL
	   If ZP1->(MsRLock())
	      ZP1->(RecLock("ZP1",.F.))
	      ZP1->ZP1_CONTEU:=""
	      ZP1->(MSRUNLOCK())
	      _lLockZP1:=.T.
	   EndIf   
	EndIf
	If _lLockZP1 .And. ZP1->(MSSEEK( xFilial('ZP1') + cFilant + _cMV2ZP1 ))//TRAVA POR FILIAL
		ZP1->(RecLock("ZP1",.F.))
		ZP1->ZP1_CONTEU:=""
		ZP1->ZP1_CONTEU:=StrTran(AllTrim(ZP1->ZP1_CONTEU),MV_PAR81+"/","")
		ZP1->(MSRUNLOCK())
	EndIf
    ZP1->(MSUnLockALL())
	ZP1->(DBSetOrder(1))

	Return .T.

EndIf

DBSelectArea( "ZP1" )
ZP1->( DBSetOrder(2) )
If ZP1->( MsSeek( xFilial('ZP1') + cFilAnt + _cMV_ZP1 ) )//TRAVA POR FILIAL
   While !_lLockZP1 .And. (++_nCnt01 < 03)
	  If InTransact()
	  	_lLockZP1 := RecLock("ZP1")
	  Else
	 	_lLockZP1 := MsRLock()
	  EndIf
	  If !_lLockZP1
	     Inkey(1)
	  EndIf
   EndDo
Else
   ZP1->(RecLock("ZP1",.T.))
   ZP1->ZP1_FILIAL:=xFilial("ZP1")
   ZP1->ZP1_MODULO:="39"
   ZP1->ZP1_GRUPO :="P"
   ZP1->ZP1_ROTINA:="AOMS115"
   ZP1->ZP1_DESROT:="Central de Faturas do Transportador"
   ZP1->ZP1_FILPAR:=cFilAnt
   ZP1->ZP1_PARAM :=_cMV_ZP1
   ZP1->ZP1_DESCRI:="Trava por filial + usuario do Programa AOMS115"
   ZP1->ZP1_TIPO  :="C"
   _lLockZP1:=.T.
EndIf
If _lLockZP1 
   ZP1->ZP1_CONTEU:=UsrFullName(__cUserId)+" - "+DToC(dDataBase)+" - "+Time()
Else
   _cSalva:=ZP1->ZP1_CONTEU
EndIf 
_nCnt01:=0
If ZP1->( MsSeek( xFilial('ZP1') + cFilAnt + _cMV2ZP1 ) )//TRAVA POR FILIAL
   While !_lLock2ZP1 .And. (++_nCnt01 < 10)
	  If InTransact()
	  	_lLock2ZP1 := RecLock("ZP1")
	  Else
	 	_lLock2ZP1 := MsRLock()
	  EndIf
	  If !_lLock2ZP1
	     Inkey(1)
	  EndIf
   EndDo
Else
   ZP1->(RecLock("ZP1",.T.))
   ZP1->ZP1_FILIAL:=xFilial("ZP1")
   ZP1->ZP1_MODULO:="39"
   ZP1->ZP1_GRUPO :="P"
   ZP1->ZP1_ROTINA:="AOMS115"
   ZP1->ZP1_DESROT:="Central de Faturas do Transportador"
   ZP1->ZP1_FILPAR:=cFilAnt
   ZP1->ZP1_PARAM :=_cMV2ZP1
   ZP1->ZP1_DESCRI:="Lista de Trasportadores em Uso do Programa AOMS115"
   ZP1->ZP1_TIPO  :="C"
   _lLock2ZP1:=.T.
EndIf
ZP1->( DBSetOrder(1) )
If _lLockZP1 .And. _lLock2ZP1
   ZP1->ZP1_CONTEU:=MV_PAR81+"/"
ElseIf !_lLockZP1 .And. _lLock2ZP1 .And. !(MV_PAR81+"/" $ ZP1->ZP1_CONTEU)
   ZP1->ZP1_CONTEU:=AllTrim(ZP1->ZP1_CONTEU)+MV_PAR81+"/"
ElseIf !_lLockZP1 .Or. !_lLock2ZP1 .Or. (MV_PAR81+"/" $ ZP1->ZP1_CONTEU)
   U_ITMsg( "O Programa esta sendo utilizado pelo Usuario: "+AllTrim(_cSalva)+" com o transportador: "+ZP1->ZP1_CONTEU,"Parametro "+_cMV_ZP1+" na ZP1","Aguarde o usuario finalizar",1) 
   Return .F.
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AOM115Estorno()
Autor-------------: Alex Wallauer 
Data da Criacao---: 31/07/2019
Descrição---------: Estorna Fatura
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOM115Estorno(oProc)

Local _nModAux  := nModulo
Local _cModAux  := cModulo
Local _lRet     := .T.  
					
_aItens:={}//_lEmail FATURA
aAdd(_aItens,.T.)            //01
aAdd(_aItens,SE2->E2_PREFIXO)//02
aAdd(_aItens,SE2->E2_NUM)    //03
aAdd(_aItens,SE2->E2_PARCELA)//04
aAdd(_aItens,SE2->E2_TIPO)   //05 
aAdd(_aItens,SE2->E2_NATUREZ)//06 
aAdd(_aItens,SE2->E2_FORNECE)//07	
aAdd(_aItens,SE2->E2_LOJA   )//08		 	
aAdd(_aItens,DToC(SE2->E2_EMISSAO))//09
aAdd(_aItens,DToC(SE2->E2_VENCREA))//10
aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_VALOR-SE2->E2_SDDECRE,"@E 999,999,999,999.99")))//11
aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_SDDECRE,"@E 999,999,999,999.99")))//12
aAdd(_aItens,SE2->E2_HIST   )//13
aAdd(_aItens,"")//14 
aAdd(_aItens,SE2->E2_VALOR-SE2->E2_SDDECRE)//15
aAdd(_aItens,SE2->E2_SDDECRE)   //16
aAdd(_aItens,TRBF->(RECNO()))   //17

//Exclui Fatura no financeiro
aArray:={}
aAdd(aArray,"MAN")
aAdd(aArray,"FT")
aAdd(aArray,"   ") //Em branco para seguir sequência de fatura do Protheus
aAdd(aArray,SE2->E2_NATUREZA)
aAdd(aArray,SE2->E2_EMISSAO)
aAdd(aArray,SE2->E2_EMISSAO)
aAdd(aArray,SE2->E2_FORNECE)
aAdd(aArray,"    ")   //Loja em branco para trazer todos os títulos do fornecedor
aAdd(aArray,SE2->E2_FORNECE)
aAdd(aArray,SE2->E2_LOJA )
aAdd(aArray,)
aAdd(aArray,01)
aAdd(aArray,{SE2->E2_PREFIXO,SE2->E2_NUM,SE2->E2_PARCELA,SE2->E2_TIPO,.F.,SE2->E2_FORNECE,SE2->E2_LOJA})
aAdd(aArray,)
aAdd(aArray,)

nModulo	   := 6
cModulo	   := "FIN"
lMsErroAuto:= .F.
DBSelectArea( "SE5" )
MsExecAuto( { |x,y| FINA290(x,y)},4,aArray,)//ESTORNO DA FATURA

_cErro:="Estornado com Sucesso"  		  		
If lMsErroAuto
   _cErro:=AllTrim(MOSTRAERRO())//GETTEMPPATH()))
   _cErro:="Não Estornou. Acesse Ver Resultado: "+CHR(13)+CHR(10)+_cErro
   _lRet:=_aItens[1]:=.F.
Else
   _nPos:=aScan(_aTRBF,{|x| x[ Len(_aTRBF[1]) ] == TRBF->(RECNO()) })
   If _nPos <> 0
      _aTRBF[_nPos,01]:=Space(2)
   EndIf
   TRBF->OK:=Space(2)
EndIf
_aItens[14]:=_cErro//14 

aAdd(_aTLinhas,_aItens)

nModulo:= _nModAux
cModulo:= _cModAux

Return _lRet

/*
===============================================================================================================================
Programa----------: AOM114 Altera()
Autor-------------: Alex Wallauer 
Data da Criacao---: 31/07/2019
Descrição---------: Estorna Titulo do seguro
Parametros--------: oProc,
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOM114Altera(oProc,_aCpos)

Local _aAutoSE2:= {}
Local _nModAux  := nModulo
Local _cModAux  := cModulo
Local _lRet     := .T.  
Local nE2_DECRES:=_aCpos[2]
Local cE2_HIST  :=_aCpos[4]
					
aAdd( _aAutoSE2 , { "E2_FILIAL"		, SE2->E2_FILIAL	, nil } )	
aAdd( _aAutoSE2 , { "E2_PREFIXO"	, SE2->E2_PREFIXO	, nil } )		
aAdd( _aAutoSE2 , { "E2_NUM"		, SE2->E2_NUM		, nil } )
aAdd( _aAutoSE2 , { "E2_PARCELA"	, SE2->E2_PARCELA	, nil } )	
aAdd( _aAutoSE2 , { "E2_TIPO"		, SE2->E2_TIPO		, nil } )
aAdd( _aAutoSE2 , { "E2_NATUREZ"	, SE2->E2_NATUREZ	, nil } ) 
aAdd( _aAutoSE2 , { "E2_FORNECE"	, SE2->E2_FORNECE	, nil } )	
aAdd( _aAutoSE2 , { "E2_LOJA"		, SE2->E2_LOJA		, nil } )	
aAdd( _aAutoSE2 , { "E2_EMISSAO"	, SE2->E2_EMISSAO	, nil } )
aAdd( _aAutoSE2 , { "E2_VENCTO"		, SE2->E2_VENCTO	, nil } )
aAdd( _aAutoSE2 , { "E2_VALOR"		, SE2->E2_VALOR		, nil } )
aAdd( _aAutoSE2 , { "E2_HIST"		, cE2_HIST   		, Nil } )
aAdd( _aAutoSE2 , { "E2_DATALIB"	, dDataBase         , nil } )//APROVEITO E JÁ LIBERO
aAdd( _aAutoSE2 , { "E2_USUALIB"	, cUserName         , nil } )//APROVEITO E JÁ LIBERO
aAdd( _aAutoSE2 , { "E2_DECRESC"	, nE2_DECRES		, nil } )
aAdd( _aAutoSE2 , { "E2_SDDECRE"	, nE2_DECRES		, nil } )

_aItens:={}//_lEmail TITULOS
aAdd(_aItens,.T.)
aAdd(_aItens,SE2->E2_PREFIXO)
aAdd(_aItens,SE2->E2_NUM)
aAdd(_aItens,SE2->E2_PARCELA)
aAdd(_aItens,SE2->E2_TIPO) 
aAdd(_aItens,SE2->E2_NATUREZ) 
aAdd(_aItens,SE2->E2_FORNECE)	
aAdd(_aItens,SE2->E2_LOJA   )		 	
aAdd(_aItens,DToC(SE2->E2_EMISSAO))
aAdd(_aItens,DToC(SE2->E2_VENCREA))
aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_SALDO,"@E 999,999,999,999.99")))//11
aAdd(_aItens,AllTrim(TRANSFORM(nE2_DECRES,"@E 999,999,999,999.99")))//12
aAdd(_aItens,cE2_HIST   )//13
   
nModulo	   := 6
cModulo	   := "FIN"
lMsErroAuto:=.F.

//MSExecAuto({|v,h,k,l,m,n,o| Fina050(v,h,k,l,m,n,o)},_aAutoSE2,,4,,,.F.,.T.)//Alteracao DOS TITULOS 
SE2->(RecLock("SE2",.F.))
SE2->E2_HIST := cE2_HIST
SE2->E2_DATALIB := dDataBase
SE2->E2_USUALIB := cUserName
SE2->E2_DECRESC := nE2_DECRES
SE2->E2_SDDECRE := nE2_DECRES
SE2->(MSUnLock())

_cErro:="Alterado e Liberado com Sucesso"  		  		
If lMsErroAuto
   _cErro:=(MOSTRAERRO(GETTEMPPATH()))
   _cErro:="Não Alterou. Acesse Ver Resultado: "+CHR(13)+CHR(10)+_cErro
   _aItens[1]:=.F.
Else
   _nPos:=aScan(_aTRBF,{|x| x[ Len(_aTRBF[1]) ] == TRBF->(RECNO()) })
   If _nPos <> 0
      _aTRBF[_nPos,01]:=Space(2)
   EndIf
   TRBF->OK:=Space(2)  
EndIf
aAdd(_aItens,_cErro)         //14
aAdd(_aItens,SE2->E2_SALDO)  //15
aAdd(_aItens,nE2_DECRES)     //16
aAdd(_aItens,TRBF->(RECNO()))//17
aAdd(_aTLinhas,_aItens)

nModulo:= _nModAux
cModulo:= _cModAux

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS115 Tit()
Autor-------------: Alex Wallauer 
Data da Criacao---: 10/07/2019
Descrição---------: Visualiza Titulos
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS115Tit(oProc,_nRegSE2,_lEmail)
Local _aLinhas := {}
Local _aCab    := {}
Local _aSize   := {}
Local _cNome   := ""
Local _npv     := 0
Local _cFat    := ""
Local _cForn   := ""
Local _cLoja   := ""
Local _nDescAux:= 0
Local _nValor  := 0
Local nRegTRBF := _aTRBF[oMark:nAt, Len(_aTRBF[1]) ]
Default _lEmail:=.F.
If !_lEmail
	TRBF->(DBGoTo(nRegTRBF))
	Default _nRegSE2:=TRBF->REC_SE2
EndIf
oProc:cCaption:="Lendo Titulos da Fatura..."
ProcessMessages()

SE2->(DBGoTo(_nRegSE2))//POSICIONA NA FATURA PARA GUARDAR OS DADOS DELA
SA2->(DBSetOrder(1))
If SA2->(DBSeek(xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA))
	_cNome:=SA2->A2_NREDUZ
EndIf
_cFat     := SE2->E2_NUM
_cForn    := SE2->E2_FORNECE
_cLoja    := SE2->E2_LOJA
_nDescAux := SE2->E2_DECRESC
_nValor   :=(SE2->E2_VALOR-_nDescAux)

_cQuery1:= " SELECT SE2.R_E_C_N_O_ SE2_REC FROM " + RetSqlName("SE2")+" SE2 "
_cQuery1+= "  WHERE SE2.D_E_L_E_T_ = ' ' "
_cQuery1+= "    AND SE2.E2_FILIAL  = '" + cFilAnt + "'"
_cQuery1+= "    AND SE2.E2_FATURA  = '" + _cFat + "'"
_cQuery1+= "    AND SE2.E2_FORNECE = '" + _cForn + "'"
_cQuery1+= "  ORDER BY E2_EMISSAO,E2_NUM "

_cAlias:=GetNextAlias()
MPSysOpenQuery( _cQuery1 , _cAlias )

oProc:cCaption:="Contando os dados lidos..."
ProcessMessages()

DBSelectArea(_cAlias)
_cTot2 := 0
COUNT To _cTot2
_cTot2:=AllTrim(Str(_cTot2))
_nTam2:=Len(_cTot2)
(_cAlias)->(DBGoTop())

_aTotais:={0,0,0,0,0,0,0,0,0,0}

While (_cAlias)->(!Eof())

	SE2->(DBGoTo( (_cAlias)->SE2_REC ))
	_npv++

	_aItens:={}
	If _lEmail

		oProc:cCaption := ("Lendo Fatura: "+AllTrim(Str(_nConta,_nTam)) +" de "+ _cTot+" Tit.: "+StrZero(_npv,_nTam2) +" de "+ _cTot2)
		ProcessMessages()

		aAdd(_aItens,.T.)//_lEmail TITULOS
		aAdd(_aItens,SE2->E2_PREFIXO)
		aAdd(_aItens,SE2->E2_NUM)
		aAdd(_aItens,SE2->E2_PARCELA)
		aAdd(_aItens,SE2->E2_TIPO)
		aAdd(_aItens,SE2->E2_NATUREZ)
		aAdd(_aItens,SE2->E2_FORNECE)
		aAdd(_aItens,SE2->E2_LOJA   )
		aAdd(_aItens,DToC(SE2->E2_EMISSAO))
		aAdd(_aItens,DToC(SE2->E2_VENCREA))
		aAdd(_aItens,AllTrim(TRANSFORM((SE2->E2_VALLIQ+SE2->E2_DECRESC)*If(SE2->E2_TIPO="NDF",-1,1),"@E 999,999,999,999.99")))//11 //soma desconto para ter o valor total = do envio
		aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_DECRESC,"@E 999,999,999,999.99"))) //12
		aAdd(_aItens,SE2->E2_HIST)                                                //13
		aAdd(_aItens,"Liberado com sucesso")                                      //14
		aAdd(_aItens,(SE2->E2_VALLIQ+SE2->E2_DECRESC)*If(SE2->E2_TIPO="NDF",-1,1))//15
		aAdd(_aItens,SE2->E2_DECRESC)                                             //16
		aAdd(_aTLinhas,_aItens)
		(_cAlias)->(DBSkip())
		Loop
	EndIf
	oProc:cCaption := ("Lendo Titulo: "+SE2->E2_NUM+" - "+StrZero(_npv,_nTam2) +" de "+ _cTot2)
	ProcessMessages()

	aAdd(_aItens,.T.)            //01
	aAdd(_aItens,SE2->E2_PREFIXO)//02
	aAdd(_aItens,SE2->E2_NUM)    //03
	aAdd(_aItens,SE2->E2_PARCELA)//04
	aAdd(_aItens,SE2->E2_TIPO)   //05
	aAdd(_aItens,SE2->E2_NATUREZ)//06
	aAdd(_aItens,SE2->E2_FORNECE)//07
	aAdd(_aItens,SE2->E2_LOJA   )//08
	aAdd(_aItens,DToC(SE2->E2_EMISSAO))//09
	aAdd(_aItens,DToC(SE2->E2_VENCREA))//10
	aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_VALOR*If(SE2->E2_TIPO="NDF",-1,1),"@E 999,999,999,999.99")))//11
	aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_SALDO*If(SE2->E2_TIPO="NDF",-1,1),"@E 999,999,999,999.99")))//12
	aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_DECRESC,"@E 999,999,999,999.99")))//13
	aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_SDDECRE,"@E 999,999,999,999.99")))//14
	aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_VALOR-SE2->E2_DECRESC,"@E 999,999,999,999.99")))//15
	aAdd(_aItens,DToC(SE2->E2_BAIXA))  //16
	aAdd(_aItens,DToC(SE2->E2_DATALIB))//17
	aAdd(_aItens,SE2->E2_USUALIB)      //18
	aAdd(_aItens,SE2->E2_HIST   )      //19

	aAdd(_aLinhas,_aItens)
	If SE2->E2_TIPO = "NDF"
		_aTotais[1]-=SE2->E2_VALOR
		_aTotais[4]-=SE2->E2_VALOR
	Else
		_aTotais[1]+=SE2->E2_VALOR
		_aTotais[4]+=(SE2->E2_VALOR-SE2->E2_DECRESC)
	EndIf
	_aTotais[2]+=SE2->E2_DECRESC//13
	_aTotais[3]++
	(_cAlias)->(DBSkip())

EndDo

(_cAlias)->( DBCloseArea())

If _lEmail
	If Len(_aTLinhas) = 0//_lEmail TITULOS
		aAdd(_aItens,.F.)//01
		aAdd(_aItens,"")//02
		aAdd(_aItens,"")//03
		aAdd(_aItens,"")//04
		aAdd(_aItens,"")//05
		aAdd(_aItens,"")//06
		aAdd(_aItens,SE2->E2_FORNECE)//07
		aAdd(_aItens,"")//08
		aAdd(_aItens,"")//09
		aAdd(_aItens,"")//10
		aAdd(_aItens,"")//11
		aAdd(_aItens,"")//12
		aAdd(_aItens,"")//13
		aAdd(_aItens,"Não foram encontrados os titulos da Fatura: "+_cFat)  //14
		aAdd(_aItens,00)//15
		aAdd(_aItens,00)//16
		aAdd(_aTLinhas,_aItens)
	EndIf
	Return .T.
EndIf

If Len(_aLinhas) = 0
	U_ITMsg("Nenhum Titulo localizado","Atenção",,1)
	Return .F.
EndIf

_aItens:={}

aAdd(_aItens,.T.)//01
aAdd(_aItens,"TOTAIS:")//02
aAdd(_aItens,AllTrim(Str(_aTotais[3]))+" Titulos")//03
aAdd(_aItens,"")//04
aAdd(_aItens,"")//05
aAdd(_aItens,"")//06
aAdd(_aItens,"")//07
aAdd(_aItens,"")//08
aAdd(_aItens,"")//09
aAdd(_aItens,"")//10
aAdd(_aItens,AllTrim(TRANSFORM(_aTotais[1],"@E 999,999,999,999.99")) )//11
aAdd(_aItens,"")//12
aAdd(_aItens,AllTrim(TRANSFORM(_aTotais[2],"@E 999,999,999,999.99")) )//13
aAdd(_aItens,"")//14
aAdd(_aItens,AllTrim(TRANSFORM(_aTotais[4],"@E 999,999,999,999.99")) )//15
aAdd(_aItens,"")//16
aAdd(_aItens,"")//17
aAdd(_aItens,"")//18
aAdd(_aItens,"")//19
aAdd(_aLinhas,_aItens)

//Monta _aCab
aAdd(_aCab,"")//01
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_PREFIXO","X3_TITULO"))//02
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_NUM"    ,"X3_TITULO"))//03
aAdd(_aSize,12)
aAdd(_aCab,Getsx3cache("E2_PARCELA","X3_TITULO"))//04
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_TIPO"   ,"X3_TITULO"))//05
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_NATUREZ","X3_TITULO"))//06
aAdd(_aSize,8)
aAdd(_aCab,Getsx3cache("E2_FORNECE","X3_TITULO"))//07
aAdd(_aSize,35)
aAdd(_aCab,Getsx3cache("E2_LOJA"   ,"X3_TITULO"))//08
aAdd(_aSize,5)
aAdd(_aCab,Getsx3cache("E2_EMISSAO","X3_TITULO"))//09
aAdd(_aSize,40)
aAdd(_aCab,Getsx3cache("E2_VENCREA","X3_TITULO"))//10
aAdd(_aSize,40)
aAdd(_aCab,Getsx3cache("E2_VALOR"  ,"X3_TITULO"))//11
aAdd(_aSize,45)
aAdd(_aCab,Getsx3cache("E2_SALDO"  ,"X3_TITULO"))//12
aAdd(_aSize,45)
aAdd(_aCab,Getsx3cache("E2_DECRESC","X3_TITULO"))//13
aAdd(_aSize,45)
aAdd(_aCab,Getsx3cache("E2_SDDECRE","X3_TITULO"))//14
aAdd(_aSize,45)
aAdd(_aCab,"Valor Total")//15
aAdd(_aSize,45)
aAdd(_aCab,Getsx3cache("E2_BAIXA"  ,"X3_TITULO"))//16
aAdd(_aSize,40)
aAdd(_aCab,Getsx3cache("E2_DATALIB","X3_TITULO"))//17
aAdd(_aSize,40)
aAdd(_aCab,Getsx3cache("E2_USUALIB","X3_TITULO"))//18
aAdd(_aSize,40)
aAdd(_aCab,Getsx3cache("E2_HIST"   ,"X3_TITULO"))//19
aAdd(_aSize,150)

If Len(_aLinhas) > 0
	_cTitulo:="Titulos da Fatura:" +_cFat+" / "+_cForn+" "+_cLoja+" - "+_cNome
	_cMsgTop:=AllTrim(Str(_aTotais[3]))+" Titulos: Valor Total da Fatura com desconto R$ "+AllTrim(TRANSFORM(_aTotais[4]-_nDescAux,"@E 999,999,999.99"))
	If _nValor <> (_aTotais[4]-_nDescAux)
		_cMsgTop+=". Diferença de Saldos R$ "+AllTrim(TRANSFORM( (_aTotais[4]-_nDescAux) - _nValor,"@E 999,999,999.99"))
	EndIf
//    ITListBox(_cTitAux, _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
	U_ITLISTBOX(_cTitulo, _aCab    , _aLinhas  , .F.      , 4      ,_cMsgTop  ,          , _aSize)
EndIf

Return (Len(_aLinhas) > 0)

/*
===============================================================================================================================
Programa----------: AOMS115 Tit()
Autor-------------: Alex Wallauer 
Data da Criacao---: 10/07/2019
Descrição---------: Visualiza Titulos
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS115Val(nVal)

If Empty(MV_PAR01) .And. MV_PAR02 = "NAO: Nao geradas"
	U_ITMsg("Para Geracao deve ser informado um Fornecedor",'Atenção!',,3)
	Return .F.
EndIf
If nVal = 1
	Return .T.
EndIf

If MV_PAR04 < MV_PAR03
	U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo",3)
	Return .F.
EndIf

If !MV_PAR05 >= dDataBase .And. MV_PAR02 = "NAO: Nao geradas"
	U_ITMsg("Data de VENCIMENTO INVALIDA",'Atenção!',"Tente novamente com a data de vencimento MAIOR OU IGUAL QUE HOJE",3)
	Return .F.
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AOMSRel7E
Autor-------------: Alex Wallauer 
Data da Criacao---: 20/09/2019
Descrição---------: Rotina responsável por emitir Fatura gerada em PDF 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMSRel7E(_aTLinhas,_aChaveFAT,oProc)

Local _aArea		:= FWGetArea()   , _nI
Local cPathSrvJ		:= GETMV("MV_RELT")
Local cPathLocal    := GetTempPath()
Local nLinIni		:= 10		// Linha Lateral (inicial) Esquerda
Local nCont			:= 0
Local lPagina		:= .T.
Local nTotItens     := 75

Private oPrint		:= Nil
Private nLinAux		:= 0
Private nColIni		:= 10		// Coluna Lateral (inicial) Esquerda
Private _nColTit2   := 210
Private nColMax		:= 0590		// Para implementar layout A4

// Define fontes do Relatorio
Private oFont14	 := TFont():New("Arial",,14,,.F.,,,,,.F.,.F.)
Private oFont14b := TFont():New("Arial",,14,,.T.,,,,,.F.,.F.)
Private oFont07	 := TFont():New("Arial",,07,,.F.,,,,,.F.,.F.)
Private oFont08	 := TFont():New("Arial",,08,,.F.,,,,,.F.,.F.)
Private oFont08B := TFont():New("Arial",,08,,.T.,,,,,.F.,.F.)
Private oFont09B := TFont():New("Arial",,10,,.T.,,,,,.F.,.F.)
Private oFont11B := TFont():New("Arial",,13,,.T.,,,,,.F.,.F.)
Private oFont12B := TFont():New("Arial",,13,,.T.,,,,,.F.,.F.)

SE2->( DBSetOrder(1) )
SE2->( DBGoTo( _aChaveFAT[1] ) )
oProc:cCaption:="Gerando PDF da Fatura: "+SE2->E2_NUM
ProcessMessages()
cFileName := "fatura_" + AllTrim(SE2->E2_NUM) + "_" + AllTrim(SE2->E2_FILIAL)+"_" + AllTrim(SE2->E2_FORNECE) + ".pdf"

If Empty(_cHistoric)
	_cHistoric:=SE2->E2_HIST
EndIf

// Cria Arquivo do Relatorio  
lDisabeSetup:=.T.
oPrint := FWMSPrinter():New( cFileName , IMP_PDF , .F. , cPathSrvJ , lDisabeSetup ,,,, .T. )

// Configura modo Retrato de Impressao
oPrint:SetPortrait()

//=============================
// Define impressao em papel A4
//=============================
oPrint:SetPaperSize(9)
oPrint:SetMargin(0,0,0,0)	// nEsquerda, nSuperior, nDireita, nInferior

//=========================================================
// Se enviar por e-mail nao abre o arquivo apos a impressao
//=========================================================
oPrint:SetViewPDF(.F.)////****
oPrint:cPathPDF := cPathSrvJ	// Caso seja utilizada impressão em IMP_PDF

oPrint:StartPage()
//==================================
// Chama função para desenhar o grid
//==================================
AOMSRel7G(0)

nLinIni	:= 005
nColIni	:= 000
nCont++

If nLinAux > (nLinIni+590)
	lPagina := .T.
	oPrint:EndPage()
	oPrint:StartPage()
	AOMSRel7G(0)

	nLinIni	:= 005
	nColIni	:= 000
	nCont++
EndIf

_ntot    := Len(_aTLinhas)
_ntpags  := NOROUND((_ntot)/nTotItens,0) + 1
_npag    := 1

oPrint:Say( (nLinIni+025) , (nColIni+_nColTit2) , "FATURA "  + SE2->E2_NUM  , oFont14b )
//oPrint:Say( (nLinIni+025) , (nColIni+500) , "Pag " + StrZero(_npag,3) + "/" + StrZero(_ntpags,3)  , oFont14 )
oPrint:Say( (nLinIni+025) , (nColIni+500) , "Pag " + StrZero(_npag,3)   , oFont14 )

nLinAux := nLinIni+065
oPrint:Say( (nLinIni+075) , (nColIni+020) , Posicione("ZZM",1,xFilial("ZZM")+cFilAnt,"ZZM_DESCRI") , oFont14b )//DESCRICAO DA FILAIL
oPrint:Say( (nLinIni+095) , (nColIni+020) , "Emissão: " + DToC(SE2->E2_EMISSAO) , oFont14b )
oPrint:Say( (nLinIni+110) , (nColIni+020) , "Vencimento: " + DToC(SE2->E2_VENCTO) , oFont14b )
oPrint:Say( (nLinIni+125) , (nColIni+020) , "Elaborado por: ", oFont14b )
oPrint:Say( (nLinIni+140) , (nColIni+020) , SubStr(Capital(AllTrim(UsrFullName(__cUserId))),1,30), oFont14b )

SA2->(DBSetOrder(1))
SA2->(DBSeek(xFilial("SA2") + SE2->E2_FORNECE+SE2->E2_LOJA))

nLinAux := nLinIni+045
oPrint:Say( nLinAux , (nColIni+_nColTit2) , AllTrim(SA2->A2_NOME) + " - " + SA2->A2_COD + "/" + SA2->A2_LOJA , oFont08 )
nLinAux+=10
oPrint:Say( nLinAux , (nColIni+_nColTit2) ,  AllTrim(SA2->A2_END) , oFont08 )
nLinAux+=10
oPrint:Say( nLinAux , (nColIni+_nColTit2) , "CEP: " + SubStr(AllTrim(SA2->A2_CEP),1,2) + "." + SubStr(AllTrim(SA2->A2_CEP),3,3) + "-" + SubStr(AllTrim(SA2->A2_CEP),6,3) + " - " + AllTrim(SA2->A2_MUN) + " - " + SA2->A2_EST , oFont08 )
nLinAux+=10
//oPrint:Say( nLinAux , (nColIni+_nColTit2) , "TEL:(" + AllTrim(SA2->A2_DDD) + ") " + SubStr(AllTrim(SA2->A2_TEL),1,4) + "-" + SubStr(AllTrim(SA2->A2_TEL),5,4), oFont08 )
//nLinAux+=10
oPrint:Say( nLinAux , (nColIni+_nColTit2) , "CNPJ/CPF: " + AOMSRel7CN(SA2->A2_CGC) + " - I.E.: " + AllTrim(SA2->A2_INSCR)+ " - TEL:(" + AllTrim(SA2->A2_DDD) + ") " + SubStr(AllTrim(SA2->A2_TEL),1,4) + "-" + SubStr(AllTrim(SA2->A2_TEL),5,4) , oFont08 )
nLinAux+=10
oPrint:Say( nLinAux , (nColIni+_nColTit2) , "BANCO: " + SA2->A2_BANCO + " - AGENCIA: " + SA2->A2_AGENCIA	 + " - CONTA: " + SA2->A2_NUMCON , oFont08B )
nLinAux+=10
oPrint:Say( nLinAux , (nColIni+_nColTit2) ,"Valor Total dos Titulos a pagar : R$ "+AllTrim(TRANSFORM(nVlrTotit ,"@E 999,999,999,999.99")), oFont08  )
nLinAux+=10
oPrint:Say( nLinAux , (nColIni+_nColTit2) ,"Valor Total dos Titulos NDF..... : R$ "+AllTrim(TRANSFORM(nVlrNDF   ,"@E 999,999,999,999.99")), oFont08  )
nLinAux+=10
oPrint:Say( nLinAux , (nColIni+_nColTit2) ,"Valor Total dos Decréscimos .. : R$ "+AllTrim(TRANSFORM(nDesTotit ,"@E 999,999,999,999.99")), oFont08  )
nLinAux+=10
oPrint:Say( nLinAux , (nColIni+_nColTit2) ,"Valor do Desconto da Fatura .. : R$ "+AllTrim(TRANSFORM(nDescFat  ,"@E 999,999,999,999.99")), oFont08  )
nLinAux+=10
oPrint:Say( nLinAux , (nColIni+_nColTit2) ,"VALOR LIQUIDO DA FATURA : R$ "+AllTrim(TRANSFORM(nVlrLiqFat,"@E 999,999,999,999.99")), oFont09B )
nLinAux+=08
oPrint:Say( nLinAux , (nColIni+_nColTit2) ,"Historico da Fatura : "+_cHistoric, oFont07  )

nLinAux := nLinIni + 160

//SUBTITULO 1
nCol1:=nColIni+015
nCol2:=nCol1+050
nCol3:=nCol2+070
nCol4:=nCol3+050
nCol5:=nCol4+050
nCol6:=nCol5+085
nCol7:=nCol6+090
nCol8:=nCol7+090
//SUBTITULO 2
AOMSRel7G(3)//SUBTITULO

_ntot  := 0
_natual:= 0

For _nI := 1 To Len(_aTLinhas)
	If _aTLinhas[_nI][02] = "MAN" .And. _aTLinhas[_nI][05] = "FT "
		Loop
	EndIf
	oPrint:Say( (nLinAux) , nCol1   , _aTLinhas[_nI][02], oFont08 )//"Pref
	oPrint:Say( (nLinAux) , nCol2+05, _aTLinhas[_nI][03], oFont08 )//"No
	oPrint:Say( (nLinAux) , nCol3+05, _aTLinhas[_nI][05], oFont08 )//"Tipo"
	oPrint:Say( (nLinAux) , nCol4+05, _aTLinhas[_nI][04], oFont08 )//"Parc
	oPrint:Say( (nLinAux) , nCol5+09, _aTLinhas[_nI][09], oFont08 )//"Emissão"
	oPrint:Say( (nLinAux) , nCol6+17, _aTLinhas[_nI][10], oFont08 )//"Vencimento"
	oPrint:SayAlign(nLinAux-7,nCol7 , _aTLinhas[_nI][11], oFont08, 55, 05, CLR_BLACK, 1, 1)
	oPrint:SayAlign(nLinAux-7,nCol8 , _aTLinhas[_nI][12], oFont08, 55, 05, CLR_BLACK, 1, 1)

	nlinAux += 10
	_natual++

	//Quebra de página
	If (_natual == (nTotItens-10) .And. _npag == 1) .Or. (_npag > 1 .And. _natual == nTotItens)

		_natual := 0
		_npag++
		oPrint:EndPage()
		oPrint:StartPage()

		// Chama função para desenhar o grid
		AOMSRel7G(1)

		nLinIni	:= 005
		nColIni	:= 000
		nLinAux := nLinIni + 040
		nCont++

		oPrint:Say( (nLinIni+025) , (nColIni+210) , "FATURA "  + SE2->E2_NUM  , oFont14b )
//		oPrint:Say( (nLinIni+025) , (nColIni+500) , "Pag " + StrZero(_npag,3) + "/" + StrZero(_ntpags,3)  , oFont14 )
		oPrint:Say( (nLinIni+025) , (nColIni+500) , "Pag " + StrZero(_npag,3) , oFont14 )
		oPrint:Say( (nLinIni+045) , (nColIni+210) , AllTrim(SA2->A2_NOME) + " - " + SA2->A2_COD + "/" + SA2->A2_LOJA , oFont14b )

		nLinAux := nLinIni + 075
		AOMSRel7G(3)//SUBTITULO

	EndIf

Next
_nTotNDFs:=0
_aNLinhas:=AOMSLeNDF(SA2->A2_COD,oProc)

If Len(_aNLinhas) > 0 // titulos de NDF em aberto para esse fornececedor  ***********************************

	nColN1:=nColIni+015//FILIAL
	nColN2:=nColN1+040//"Loja
	nColN3:=nColN2+040//"Pref
	nColN4:=nColN3+040//"No
	nColN5:=nColN4+065//"Tipo"
	nColN6:=nColN5+060//"Parc
	nColN7:=nColN6+060//"Emissão"
	nColN8:=nColN7+075//"Vencimento"
	nColN9:=nColN8+099//SALDO

	nlinAux += 10
	_natual++
	oPrint:Say( (nLinAux) , nCol1   , "Obs.: TOTAL de titulos de NDF em aberto para esse fornececedor: "+AllTrim(TRANSFORM(_nTotNDFs,"@E 999,999,999,999.99")), oFont08B )
	nlinAux += 15
	_natual++

	//Quebra de página
	If (_natual == (nTotItens-10) .And. _npag == 1) .Or. (_npag > 1 .And. _natual == nTotItens)

		_natual := 0
		_npag++
		oPrint:EndPage()
		oPrint:StartPage()

		// Chama função para desenhar o grid
		AOMSRel7G(1)

		nLinIni:= 005
		nColIni:= 000
		nColSub:= nColIni+198
		nLinAux:= nLinIni + 040
		nCont++

		oPrint:Say( (nLinIni+025) , nColSub , "FATURA "  + SE2->E2_NUM  , oFont14b )
		oPrint:Say( (nLinIni+025) , (nColIni+500) , "Pag " + StrZero(_npag,3) , oFont14 )
		oPrint:Say( (nLinIni+042) , nColSub , AllTrim(SA2->A2_NOME) + " - " + SA2->A2_COD + "/" + SA2->A2_LOJA , oFont11B )
		oPrint:Say( (nLinIni+057) , nColSub , "Esta transportadora possui débitos pendentes em outras filiais, conforme abaixo", oFont12B, /*[ nWidth]*/,CLR_HRED /*[ nClrText]*/, /*[nAngle]*/  )
		nLinAux := nLinIni + 080
	Else

		// Linha Horizontal
		oPrint:Line( nlinAux    , nColIni + 010 , nlinAux    , nColMax)
		// Linha Horizontal
		oPrint:Line( nlinAux+25 , nColIni + 010 , nlinAux+25 , nColMax)
		nlinAux += 15
	EndIf

	AOMSRel7G(4)//SUBTITULO 2

	For _nI := 1 To Len(_aNLinhas)

		oPrint:Say( (nLinAux)    , nColN1+05, _aNLinhas[_nI][01], oFont08 )//"Filial
		oPrint:Say( (nLinAux)    , nColN2+05, _aNLinhas[_nI][02], oFont08 )//"Loja
		oPrint:Say( (nLinAux)    , nColN3+05, _aNLinhas[_nI][03], oFont08 )//"Pref
		oPrint:Say( (nLinAux)    , nColN4+05, _aNLinhas[_nI][04], oFont08 )//"No
		oPrint:Say( (nLinAux)    , nColN5+05, _aNLinhas[_nI][05], oFont08 )//"Tipo"
		oPrint:Say( (nLinAux)    , nColN6+05, _aNLinhas[_nI][06], oFont08 )//"Parc
		oPrint:Say( (nLinAux)    , nColN7+09, _aNLinhas[_nI][07], oFont08 )//"Emissão"
		oPrint:Say( (nLinAux)    , nColN8+16, _aNLinhas[_nI][08], oFont08 )//"Vencimento"
		oPrint:SayAlign(nLinAux-7, nColN9   , _aNLinhas[_nI][09], oFont08, 55, 05, CLR_BLACK, 1, 1)//SALDO

		nlinAux += 10
		_natual++

		//Quebra de página
		If (_natual == (nTotItens-10) .And. _npag == 1) .Or. (_npag > 1 .And. _natual == nTotItens)

			_natual := 0
			_npag++
			oPrint:EndPage()
			oPrint:StartPage()

			// Chama função para desenhar o grid
			AOMSRel7G(1)

			nLinIni	:= 005
			nColIni	:= 000
			nLinAux := nLinIni + 040
			nCont++

			oPrint:Say( (nLinIni+025) , (nColIni+210) , "FATURA "  + SE2->E2_NUM  , oFont14b )
// 	  	oPrint:Say( (nLinIni+025) , (nColIni+500) , "Pag " + StrZero(_npag,3) + "/" + StrZero(_ntpags,3)  , oFont14 )
			oPrint:Say( (nLinIni+025) , (nColIni+500) , "Pag " + StrZero(_npag,3) , oFont14 )
			oPrint:Say( (nLinIni+045) , (nColIni+210) , AllTrim(SA2->A2_NOME) + " - " + SA2->A2_COD + "/" + SA2->A2_LOJA , oFont14b )

			nLinAux := nLinIni + 075
			AOMSRel7G(4)//SUBTITULO

		EndIf

	Next

	If _nTotNDFs > 0
		oPrint:Say( (nLinAux)    , nColN8+16, "TOTAL:" , oFont08B )
		oPrint:SayAlign(nLinAux-7, nColN9   , AllTrim(TRANSFORM(_nTotNDFs,"@E 999,999,999,999.99")), oFont08B, 55, 05, CLR_BLACK, 1, 1)
	EndIf

Else

	nlinAux += 10
	oPrint:Say( (nLinAux) , nCol1   , "Obs.: Não há titulos de NDF em aberto para esse fornececedor.", oFont08B )

EndIf

oProc:cCaption:="Gerando PDF: "+cPathSrvJ + cFileName
ProcessMessages()
oPrint:EndPage()
oPrint:lViewPDF := .F.
oPrint:Preview()
FreeObj(oPrint)

If File(cPathSrvJ + cFileName)
	cGetAnx := cPathSrvJ + cFileName
	cGetAnxl:= StrTran( cGetAnx, cPathSrvJ, cPathLocal )
	//Copia anexo para estação local
	If !CpyS2T(cGetAnx,cPathLocal)
		U_ITMsg("Não foi possivel copiar o arquivo "+cGetAnx+" para "+cPathLocal,'Atenção!',"Feche o arquivo "+cGetAnx+", caso aberto, e tente novamente",1)
	EndIf
EndIf

FWRestArea(_aArea)

Return .T.
/*
===============================================================================================================================
Programa----------: AOMSRel7G
Autor-------------: Alex Wallauer 
Data da Criacao---: 20/09/2019
Descrição---------: Rotina responsável por criar o layout de impressão
Parametros--------: _nopc - 1 para segunda página em diante
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMSRel7G(_nopc)

Local nLinIni		:= 0		// Linha Lateral (inicial) Esquerda
Local nColIni		:= 0		// Coluna Lateral (inicial) Esquerda
Local nLinMax		:= 0835		// Para implementar layout A4
Local cPathImg		:= GetSrvProfString("Startpath","")
Local cFileImg		:= ""

Default _nopc := 0

If _nopc = 3//SUBTITULO 1
	oPrint:Say( nLinAux , nCol1   , "Pref."           , oFont14b )
	oPrint:Say( nLinAux , nCol2   , "No. Titulo"      , oFont14b )
	oPrint:Say( nLinAux , nCol3   , "Tipo"            , oFont14b )
	oPrint:Say( nLinAux , nCol4   , "Parc."           , oFont14b )
	oPrint:Say( nLinAux , nCol5   , "Emissão"         , oFont14b )
	oPrint:Say( nLinAux , nCol6   , "Vencimento"      , oFont14b )
	oPrint:Say( nLinAux , nCol7+09, "Vlr. Total"      , oFont14b )
	oPrint:Say( nLinAux , nCol8-06, "Decréscimo"      , oFont14b )
	nLinAux+=20
	Return .T.
ElseIf _nopc = 4//SUBTITULO 2
	oPrint:Say( nLinAux , nColN1   , "Filial"          , oFont14b )
	oPrint:Say( nLinAux , nColN2   , "Loja"            , oFont14b )
	oPrint:Say( nLinAux , nColN3   , "Pref."           , oFont14b )
	oPrint:Say( nLinAux , nColN4   , "No. Titulo"      , oFont14b )
	oPrint:Say( nLinAux , nColN5   , "Tipo"            , oFont14b )
	oPrint:Say( nLinAux , nColN6   , "Parc."           , oFont14b )
	oPrint:Say( nLinAux , nColN7   , "Emissão"         , oFont14b )
	oPrint:Say( nLinAux , nColN8   , "Vencimento"      , oFont14b )
	oPrint:Say( nLinAux , nColN9+09, "Saldo"           , oFont14b )
	nLinAux+=20
	Return .T.
EndIf

nLinIni	:= 005
nColIni	:= 000

cFileImg := cPathImg + "logoboleto.BMP"//179 X 86

// Box Principal
oPrint:Box( nLinIni + 008, nColIni + 010, nLinMax, nColMax, "-4")

// Logotipo
_nLinLogo:=nLinIni+9
oPrint:SayBitmap( _nLinLogo , nColIni + 018 , cFileImg , 179 , 060 )

If _nopc == 0//pafina 1

	// Linha Vertical
	oPrint:Line( nLinIni + 008 , nColIni + 200 , nLinIni + 145 , nColIni + 200	)

	// Linha Vertical
	oPrint:Line( nLinIni + 008 , nColIni + 650 , nLinIni + 145 , nColIni + 650	)

	// Linha Horizontal
	oPrint:Line( nLinIni + 035 , nColIni + 200 , nLinIni + 035 , nColMax	) //nColIni + 650

	// Linha Horizontal
	oPrint:Line( nLinIni + 145 , nColIni + 010 , nLinIni + 145 , nColMax	)

	// Linha Horizontal
	oPrint:Line( nLinIni + 170 , nColIni + 010 , nLinIni + 170 , nColMax	)

Else//Pagina > 1

	_nLinlAux:=65
	// Linha Vertical
	oPrint:Line( nLinIni + 008 , _nColTit2-15 ,nLinIni + _nLinlAux  , _nColTit2-15	)

	// Linha Horizontal
	oPrint:Line( nLinIni + _nLinlAux    , nColIni + 010 , nLinIni + _nLinlAux    , nColMax)

	// Linha Horizontal
	oPrint:Line( nLinIni + _nLinlAux+25 , nColIni + 010 , nLinIni + _nLinlAux+25 , nColMax)

EndIf

Return
/*
===============================================================================================================================
Programa----------: AOMSRel7CN
Autor-------------: Alex Wallauer 
Data da Criacao---: 02/10/2019
Descrição---------: Função criada para formatar CPF/CNPJ
Parametros--------: cCPFCNPJ	- Texto a ser quebrado
Retorno-----------: cCampFormat	- Retorna o campo formatado conforme CPF/CNPJ
===============================================================================================================================
*/
Static Function AOMSRel7CN(cCPFCNPJ)

Local cCampFormat := ""	//Armazena o CPF ou CNPJ formatado

If Len(AllTrim(cCPFCNPJ)) == 11			//CPF
	cCampFormat:=SubStr(cCPFCNPJ,1,3) + "." + SubStr(cCPFCNPJ,4,3) + "." + SubStr(cCPFCNPJ,7,3) + "-" + SubStr(cCPFCNPJ,10,2)
Else									//CNPJ
	cCampFormat:=SubStr(cCPFCNPJ,1,2)+"."+SubStr(cCPFCNPJ,3,3)+"."+SubStr(cCPFCNPJ,6,3)+"/"+SubStr(cCPFCNPJ,9,4)+"-"+ SubStr(cCPFCNPJ,13,2)
EndIf

Return cCampFormat

/*
===============================================================================================================================
Programa----------: AOMSGRVFI8
Autor-------------: Alex Wallauer 
Data da Criacao---: 26/03/2020
Descrição---------: Função criada para GRAVAR OS CAMPOS EM BRANCO DO FI8 POS GERACAO DA FATURA
Parametros--------: _aTitulos
Retorno-----------: NENHUM
===============================================================================================================================
*/
Static Function AOMSGRVFI8(_aTitulos)

Local _cQuery1:=""
Local _cAlias:=GetNextAlias()
Local cTtits:="" , T

For T := 1 To Len(_aTitulos)
	cTtits+=_aTitulos[T,2]+","
Next

_cQuery1+= " SELECT FI8.R_E_C_N_O_ FI8_REC FROM " + RetSqlName("FI8")+" FI8 "
_cQuery1+= "  WHERE FI8.D_E_L_E_T_ = ' ' "
_cQuery1+= "    AND FI8.FI8_FILIAL  = '" + cFilAnt + "'"
_cQuery1+= "    AND FI8.FI8_NUMORI  IN "+FormatIn(cTtits,",")
_cQuery1+= "    AND FI8.FI8_FORORI = '" + SE2->E2_FORNECE + "'"
_cQuery1+= "    AND FI8.FI8_LOJORI = '" + SE2->E2_LOJA + "'"
_cQuery1+= "    AND FI8_NUMDES = ' ' "

MPSysOpenQuery( _cQuery1 , _cAlias )

BEGIN TRANSACTION

	While (_cAlias)->(!Eof())

		FI8->(DBGoTo((_cAlias)->FI8_REC))
		FI8->(RecLock("FI8",.F.))
		FI8->FI8_PARDES := SE2->E2_PARCELA
		FI8->FI8_FILDES := SE2->E2_FILIAL
		FI8->FI8_PRFDES := SE2->E2_PREFIXO
		FI8->FI8_NUMDES := SE2->E2_NUM //(Número da Fatura)
		FI8->FI8_TIPDES := SE2->E2_TIPO
		FI8->FI8_FORDES := SE2->E2_FORNECE
		FI8->FI8_LOJDES := SE2->E2_LOJA
		FI8->(MSUnLock())
		(_cAlias)->(DBSkip())

	EndDo

END TRANSACTION

(_cAlias)->( DBCloseArea())
DBSelectArea("SE2")

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS115R
Autor-------------: Julio de Paula Paz
Data da Criacao---: 12/08/2022
Descrição---------: Rotina para permitir selecionar a loja da transportadora para geração da fatura de frete.
Parametros--------: _cFornece
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS115R(_cFornece)

Local _nI
Local _cItem, _aItens := {}
Local _cCnpj, _cEstado, _cMunicip
Local _aDadosLoj := {} 

Begin Sequence

//=============================================================================
// Monta Array com os dados para seleção da loja da transportadora. 
// Para ser selecionada no momento da geração das notas fiscais de transporte.
//=============================================================================
SA2->(DBSetOrder(1))
SA2->(MsSeek(xFilial("SA2")+U_ItKey(_cFornece,"A2_COD")))

While ! SA2->(Eof()) .And. SA2->(A2_FILIAL+A2_COD) == xFilial("SA2")+U_ItKey(_cFornece,"A2_COD")
	If SA2->A2_MSBLQL == "2" .And. ! Empty(SA2->A2_BANCO) .And. !Empty(SA2->A2_AGENCIA) .And. !Empty(SA2->A2_NUMCON)
		aAdd(_aDadosLoj, {SA2->A2_COD,SA2->A2_LOJA,SA2->A2_NREDUZ,SA2->A2_BANCO,SA2->A2_AGENCIA,SA2->A2_NUMCON} )
	EndIf
	SA2->(DBSkip())
EndDo
//================================================================================================//
If Len(_aDadosLoj) = 0
	Return .F.
EndIf

If !U_ITMsg("Deseja indicar Geração de fatura em outra loja ?",'Atenção!',,3,2,2)
	Return .F.
EndIf

For _nI := 1 To Len(_aDadosLoj)
	//SE2->E2_FORNECE,  // 1
	//SE2->E2_LOJA,     // 2
	//SE2->E2_NOMFOR,   // 3
	//SE2->E2_L_BANCO,  // 4
	//SE2->E2_L_AGENC,  // 5
	//SE2->E2_L_CONTA   // 6
	_cCnpj    := Posicione("SA2", 1 , xFilial("SA2")+_aDadosLoj[_nI,1]+_aDadosLoj[_nI,2],"A2_CGC")
	_cEstado  := Posicione("SA2", 1 , xFilial("SA2")+_aDadosLoj[_nI,1]+_aDadosLoj[_nI,2],"A2_EST")
	_cMunicip := Posicione("SA2", 1 , xFilial("SA2")+_aDadosLoj[_nI,1]+_aDadosLoj[_nI,2],"A2_MUN")
	//      1                          2                          3                           4                          5                              6
	_cItem := _aDadosLoj[_nI,1] + " | " + _aDadosLoj[_nI,2] + " | " + _aDadosLoj[_nI,3] + " | " +_aDadosLoj[_nI,4] + " | " + _aDadosLoj[_nI,5] + " |" + _aDadosLoj[_nI,6] + "| " + _cCnpj + " | " + _cEstado + " | " + _cMunicip
	aAdd(_aItens, _cItem)
Next _nI

_cItem := _aItens[1]

//================================================================================
// Tela de Alteração do Armazem do item de Pedido de Vendas
//================================================================================
_lRet := .F.
_cTitulo := "Tela de Seleção da Loja para geração das Faturas de Frete"
_bOk := {|| _lRet := .T., _oDlgLoja:End()}
_bCancel := {|| _lRet := .F., _oDlgLoja:End()}
_nAjusteLin := 30

Define MsDialog _oDlgLoja Title _cTitulo From 9,0 To 20,92 Of oMainWnd // 22,55

	@ 3, 9 To 3.8, 44 of _oDlgLoja   //3.2
	//@ 06.8 +_nAjusteLin,80 Say "Codigo | Loja  | Nome                                  | Bco | Agenc   | Conta      | CNPJ              | UF | Municipio " Of _oDlgLoja Pixel
	@ 03.5, 09.5  Say " Codigo | Loja  | Nome                                   |Bco |Agenc| Conta        | CNPJ                     | UF | Municipio " Of _oDlgLoja
	_nAjusteLin += 10

	@ 06+_nAjusteLin,06 Say "Loja para Geração Fatura: " Of _oDlgLoja Pixel
	//@ 06+_nAjusteLin,75 ComboBox _cItem Items _aItens Of _oDlgLoja Size 100,080 // Pixel // 280,010
	@ 04,09 ComboBox _cItem Items _aItens Of _oDlgLoja Size 280,060 // Pixel // 280,010

Activate MsDialog _oDlgLoja On Init EnchoiceBar(_oDlgLoja,_bOk,_bCancel) CENTERED

If _lRet
	_cLojaFor := SubStr(_cItem,10,4)
	If Empty(_cLojaFor)
		_cLojaFor := "0001"
	EndIf
EndIf

End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMSLeNDF
Autor-------------: Alex Wallauer 
Data da Criacao---: 03/05/2023
Descrição---------: Retorna a relação de NDFs em aberto de todas as unidades, exceto Jaru.
Parametros--------: _cForn,oProc
Retorno-----------: _aNLinhas
===============================================================================================================================
*/
Static Function AOMSLeNDF(_cForn,oProc)

Local _cQuery1:=""
Local _cFilExceto:=AllTrim(SuperGetMV("IT_EXFILND",.F.,"10"))

_cQuery1:= " SELECT SE2.R_E_C_N_O_ SE2_REC FROM " + RetSqlName("SE2")+" SE2 "
_cQuery1+= "  WHERE SE2.D_E_L_E_T_ = ' ' "
If !Empty(_cFilExceto)
	_cQuery1+= "    AND SE2.E2_FILIAL NOT IN "+FormatIn(_cFilExceto,";")
EndIf
_cQuery1+= "    AND SE2.E2_FORNECE = '" + _cForn + "'"
_cQuery1+= "    AND SE2.E2_TIPO    = 'NDF' "
_cQuery1+= "    AND SE2.E2_SALDO   > 0     "
_cQuery1+= "  ORDER BY E2_EMISSAO , E2_NUM , E2_PARCELA "

_cAlias:=GetNextAlias()
MPSysOpenQuery( _cQuery1 , _cAlias )

oProc:cCaption:="Contando os dados lidos..."
ProcessMessages()

DBSelectArea(_cAlias)
_npv :=_cTot2 := 0
COUNT To _cTot2
_cTot2:=AllTrim(Str(_cTot2))
_nTam2:=Len(_cTot2)
(_cAlias)->(DBGoTop())
_aNLinhas:={}
While (_cAlias)->(!Eof())

	SE2->(DBGoTo( (_cAlias)->SE2_REC ))
	_npv++

	_aItens:={}

	oProc:cCaption := ("Lendo Titulo: "+StrZero(_npv,_nTam2) +" de "+ _cTot2)
	ProcessMessages()

	aAdd(_aItens,SE2->E2_FILIAL)
	aAdd(_aItens,SE2->E2_LOJA)
	aAdd(_aItens,SE2->E2_PREFIXO)
	aAdd(_aItens,SE2->E2_NUM)
	aAdd(_aItens,SE2->E2_TIPO)
	aAdd(_aItens,SE2->E2_PARCELA)
	aAdd(_aItens,DToC(SE2->E2_EMISSAO))
	aAdd(_aItens,DToC(SE2->E2_VENCREA))
	aAdd(_aItens,AllTrim(TRANSFORM(SE2->E2_SALDO,"@E 999,999,999,999.99")))
	_nTotNDFs+=SE2->E2_SALDO
	aAdd(_aNLinhas,_aItens)
	(_cAlias)->(DBSkip())

EndDo

(_cAlias)->( DBCloseArea())

Return _aNLinhas
