/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/ 

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AGLT003
Autor-------------: Jeovane
Data da Criacao---: 15/09/2008
Descrição---------: Rotina para possibilitar o cadastro da Recepção do Leite
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT003()

Local _cFilter		:= "" As Character
Public _lvalida := .T. As Logical

Private cCadastro	:= "Recepção de Leite - Próprio" As Character
Private aRotina		:= MenuDef() As Array
Private cAlias		:= "ZLD" As Character

Private _culticket  := Space(Len(ZLD->ZLD_TICKET)) As Character
Private lMsErroAuto := .F. As Logical
Private bVisual 	:= {|| AGLT003U( 'ZLD' , Recno() , 2 ) } As Codeblock
Private bInclui 	:= {|| AGLT003U( 'ZLD' , Recno() , 3 ) } As Codeblock
Private bAltera 	:= {|| AGLT003U( 'ZLD' , Recno() , 4 ) } As Codeblock
Private bExclui 	:= {|| AGLT003U( 'ZLD' , Recno() , 5 ) } As Codeblock
Private bLegenda	:= {|| AGLT003P() } As Codeblock
Private aCores		:=  {{ 'ZLD->ZLD_STATUS==" "'	, 'BR_VERDE'		} ,;
                   { 'ZLD->ZLD_STATUS=="F"'	, 'BR_VERMELHO'		}  } As Array

ZLD->(DBSetOrder(3))
MBrowse(,,,,cAlias,,,,,,aCores,,,,,,,,_cFilter)

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 18/09/2018
Descrição---------: Utilizacao de Menu Funcional
Parametros--------: aRotina
               1. Nome a aparecer no cabecalho
               2. Nome da Rotina associada
               3. Reservado
               4. Tipo de Transa‡„o a ser efetuada:
                  1 - Pesquisa e Posiciona em um Banco de Dados
                  2 - Simplesmente Mostra os Campos
                  3 - Inclui registros no Bancos de Dados
                  4 - Altera o registro corrente
                  5 - Remove o registro corrente do Banco de Dados
                  6 - Altera determinados campos sem incluir novos Regs
               5. Nivel de acesso
               6. Habilita Menu Funcional
Retorno-----------: Array com opcoes da rotina
===============================================================================================================================
*/
Static Function MenuDef()

Local aRotina := {	{ "Pesquisar"	, "AxPesqui" 		, 0 , 1 } ,;
                     { "Visualizar"	, "Eval(bVisual)" , 0 , 2 } ,;
                     { "Incluir"		, "Eval(bInclui)" , 0 , 3 } ,;
                     { "Alterar"		, "Eval(bAltera)" , 0 , 4 } ,;
                     { "Excluir"		, "Eval(bExclui)"	, 0 , 5 } ,;
                     { "Legenda"		, "Eval(bLegenda)", 0 , 2 }  } As Array

Return( aRotina )

/*
===============================================================================================================================
Programa----------: AGLT003U
Autor-------------: Jeovane
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para dar manutencao - Inclusao/Alteracao/Exclusao da tabela ZLD - Recepcao de Leite
Parametros--------: cAlias: Tebela , nReg: Registro , nOpc: Opção
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT003U(cAlias As Character,nReg As Numeric,nOpc As Numeric)

Local cTitulo		:= "Recepcao de Leite" As Character
Local aObjects		:= {} As Array
Local aPosObj		:= {} As Array
Local aSize			:= MsAdvSize() As Array
Local aInfo			:= {aSize[1],aSize[2],aSize[3],aSize[4],3,3} As Array
Local aNoFields	:= {"ZLD_TICKET","ZLD_DTLANC","ZLD_SETOR","ZLD_LINROT","ZLD_FRETIS","ZLD_LJFRET","ZLD_VEICUL","ZLD_MOTOR","ZLD_KM","ZLD_CODREC","ZLD_TOTBOM","ZLD_DTCOLE"} As Array//campos que não devem ir para o grid pois estão no cabeçalho
Local aYesFields	:= {"ZLD_RETIRO","ZLD_RETILJ","ZLD_DCRRET","ZLD_QTDBOM","ZLD_TQ_LT",}  As Array//Lista todos os campos para o grid de inclusão
Local _nI         := 0 As Numeric
Private oDlg		:= Nil As Object
Private oLteBom	:= Nil As Object
Private oSetor		:= Nil As Object
Private oLinRota	:= Nil As Object
Private nDIf		:= Nil As Numeric
Private cCodRec 	:= If( nOpc==3 , Space( TamSX3("ZLD_CODREC")[1] )		, ZLD->ZLD_CODREC ) As Character//Codigo Recebimento
Private cTicket	:= If( nOpc==3 , Space(Len(ZLD->ZLD_TICKET))			   , ZLD->ZLD_TICKET ) As Character//Codigo Entrada
Private dData		:= If( nOpc==3 , Date()									      , ZLD->ZLD_DTLANC ) As Date//Data Entrada
Private cSetor		:= If( nOpc==3 , criaVar("ZLD_SETOR")					   , ZLD->ZLD_SETOR )  As Character//Space(TamSX3("ZLD_SETOR")[1])
Private cDescSet	:= If( nOpc==3 , Space(20)								      , SubStr(Posicione("ZL2",1,xFilial("ZL2")+cSetor,"ZL2_DESCRI"),1,20) ) As Character
Private cLinRot	:= If( nOpc==3 , Criavar("ZLD_LINROT")					   , ZLD->ZLD_LINROT ) As Character //Space(TamSX3("ZLD_LINROT")[1])
Private cDescLin	:= If( nOpc==3 , Space( TamSX3("ZL3_DESCRI")[1]-20 )	, LEFT(Posicione("ZL3",1,xFilial("ZL3")+cLinRot,"ZL3_DESCRI"),20) ) As Character
Private cFretist	:= If( nOpc==3 , Space( TamSX3("ZLD_FRETIS")[1] )		, ZLD->ZLD_FRETIS ) As Character
Private cLjFret	:= If( nOpc==3 , Space( TamSX3("ZLD_LJFRET")[1] )		, ZLD->ZLD_LJFRET ) As Character
Private cDescFret	:= If( nOpc==3 , Space( TamSX3("A2_NOME")[1]-4 )		, SubStr(Posicione("SA2",1,xFilial("SA2")+cFretist+cLjFret,"A2_NOME"),1,TamSX3("A2_NOME")[1]-4) ) As Character
Private cVeicul	:= If( nOpc==3 , Space( TamSX3("ZLD_VEICUL")[1] )		, ZLD->ZLD_VEICUL ) As Character
Private cMotor		:= If( nOpc==3 , Space( TamSX3("ZLD_MOTOR")[1] )		, ZLD->ZLD_MOTOR ) As Character
Private cDescMot	:= If( nOpc==3 , Space( TamSX3("ZL0_NOME")[1]-20 )		, LEFT(Posicione("ZL0",1,xFilial("ZL0")+cMotor,"ZL0_NOME"),20) ) As Character
Private cPlacaVeic:= If( nOpc==3 , Space( TamSX3("ZL1_PLACA")[1] )		, Posicione("ZL1",1,xFilial("ZL1")+ZLD->ZLD_VEICUL,"ZL1_PLACA") ) As Character
Private nTotKm    := If( nOpc==3 , 0										      , ZLD->ZLD_KM ) As Numeric
Private nLeiteBom := 0 As Numeric
Private dDtcoleta	:= If( nOpc == 3 , dDataBase	, ZLD->ZLD_DTCOLE ) As Date//Data DA COLETA
Private nTotBom	:= If( nOpc == 3 , 0			, ZLD->ZLD_TOTBOM ) As Numeric
Private nLtDIf		:= 0 As Numeric
Private bVldLin	:= {|| AGLT003L(.F.)} As Codeblock
Private bVldTela	:= {|| AGLT003T()	 } As Codeblock
Private lConfirmou:= .F. As Logical
Private nPosRetiro:= 0 As Numeric
Private nPosLoja	:= 0 As Numeric
Private nPosQtdBom:= 0 As Numeric
Private nPosTqLt	:= 0 As Numeric
Private nPosNomRet:= 0 As Numeric
Private nPosAtendi:= 0 As Numeric
Private nPosCodZLX:= 0 As Numeric
Private cSeek	   := xFilial("ZLD")+ZLD->ZLD_CODREC As Character
Private bSeekFor	:= {|| ZLD->ZLD_CODREC == cCodRec  .And. cTicket == ZLD->ZLD_TICKET } As Codeblock
Private bSeekWhile:= {|| ZLD->ZLD_FILIAL + ZLD->ZLD_CODREC } As Codeblock//Condicao While para montar o aCols
Private aColsAux 	:= {} As Array//Armazena aCols para Controle de Alteracao/Exclusao
Private nVolAnt	:= If( nOpc==3 , 0 , AGLT003W( cCodRec , cTicket , cSetor ) ) As Numeric// Volume do ticket lancado (anteriores)
Private lAbleTicke:= .T. As Logical
Private nTotCodRec:= 0 As Numeric
Private oTotCodRec:= Nil As Object
Private crotaori  := "" As Character

// Validacao - O ticket nao pode sofrer alteracoes caso ja tenha sido fechado
If nOpc == 4 .Or. nOpc == 5

   If ZLD->ZLD_STATUS == "F"
      FWAlertWarning("Ticket não pode ser alterado/excluído por já estar fechado! Esse Ticket somente pode ser alterado/excluído se o Fechamento do Leite For cancelado.","AGLT00301")
      Return
   EndIf

   If nOpc == 5 
      If !Empty(ZLD->ZLD_ATENDI)
         FWAlertWarning("Ticket não pode ser excluído por ser integrado do SmartQuestion! Tickets somente podem ser excluídos se a inclusão For manual.","AGLT00302")
         Return .F.
      EndIf

      If !Empty(ZLD->ZLD_CODZLX)//VALIDACAO DO SETOR SEGUNDARIO = "2"
         FWAlertWarning("Ticket não pode ser excluído por estar vinculado a Recepção de Leite de Terceiros. Desvincule as Recepção de Leite de terceiros: "+ZLD->ZLD_CODZLX,"AGLT00303")
         Return .F.
      EndIf

       ZLX->(dbOrderNickname("IT_I_TISET"))//ZLX_FILIAL+ZLX_TICKET+ZLX_SETOR// INDICE 10
       If ZLX->( DBSeek(xFilial()+ZLD->ZLD_TICKET+ZLD->ZLD_SETOR)) .And. ZLX->ZLX_STATUS $ '2,3' //VALIDACAO DO SETOR PRIMARIO  = "1"
        FWAlertWarning("Ticket não pode ser excluído por estar vinculado à Recepção de Leite de Terceiros NÃO PENDENTE. Altere o status para pendente da Recepção de Leite de terceiros: "+ZLX->ZLX_CODIGO,"AGLT004")
          ZLX->(DBSetOrder(1))
         Return .F.
      EndIf
       ZLX->(DBSetOrder(1))
   EndIf
EndIf

aButtons  := If(Type("aButtons") == "U", {}, aButtons)
                                  
//================================================================================
// Esta rotina de inclusao dos produtores de um outro ticket em um ticket que está
// sendo incluido no momento somente podera ser realizada nas unidades de JARU e 
// quando a opcao For de inclusao.
//================================================================================
If SubStr(cFilAnt,1,1) == '1' .And. nOpc == 3
   aAdd( aButtons, {"RESPONSA" ,{|| MsgRun("Aguarde...Selecionando Produtores...",,{||CursorWait(),AGLT003Z(),CursorArrow()})},"Inserir Produtores de um ticket..."    ,"Produtores"})
EndIf

// Monta a entrada de dados do arquivo
cSeek := xFilial("ZLD") + cCodRec

// Monta aHeader e aCols utilizando a funcao FillGetDados
Private aHeader[0]
Private aCols[0]

// Variaveis privadas para montagem da tela
SetPrvt("aRotina,CCADASTRO,CALIAS")
SetPrvt("NOPCE,NOPCG,NUSADO")
SetPrvt("CTITULO,CALIASENCHOICE,CLINOK,CTUDOK,CFIELDOK")
SetPrvt("NREG,NOPC")

// Inclusao
If nOpc == 3
   cTitulo+=" - INCLUSAO"
   FillGetDados( nOpc , cAlias , 1 ,,,,, aYesFields ,,,, .T. ,,,,,, )

// Alteracao,Visualizacao,Exclusao
Else
   If nOpc == 4
      cTitulo+=" - ALTERACAO"
   ElseIf nOpc == 5
      cTitulo+=" - EXCLUSAO"
   ElseIf nOpc == 2
      cTitulo+=" - VISUALIZAR"
   EndIf

   FillGetDados( nOpc , cAlias , 1 , cSeek , bSeekWhile , bSeekFor , aNoFields ,,,,,,,,, )
EndIf

aAdd( aObjects , { 100 , 055 , .T. , .F. , .T. } )
aAdd( aObjects , { 100 , 100 , .T. , .T. } )
aAdd( aObjects , { 100 , 002 , .T. , .F. } )

// Obte posicao dos campos no cabecalho os itens
nPosRecno 	:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_REC_WT"	} )
nPosRetiro	:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_RETIRO"	} )
nPosLoja	:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_RETILJ"	} )
nPosQtdBom	:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_QTDBOM"	} )
nPosTqLt 	:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_TQ_LT"	} )
nPosNomRet	:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_DCRRET"	} )
nPosAtendi	:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_ATENDI" 	} )
nPosCodZLX	:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_CODZLX" 	} )
aPosObj := MsObjSize( aInfo , aObjects )

nLeiteBom	:= nVolAnt + U_AGLT003S()
nTotCodRec	:= U_AGLT003S()
nLtDIf		:= nTotBom - nLeiteBom
_lacols := Type( "aCols" ) <> "U"

While .T.
   // Tela do model 2 - Rececpcao de Leite
   DEFINE MSDIALOG oDlg TITLE cTitulo OF oMainWnd PIXEL FROM aSize[7],0 TO aSize[6],aSize[5]

    oPanel := TPanel():New(0,0,'',oDlg,,.F.,.F.,,,300,100,.T.,.T. )
   
   @ 1.3 , 0.3 TO 2.3 , 43.0 OF oPanel
   @ 5.9 , 0.3 TO 7.0 , 43.0 OF oPanel

   @ 1.6 , 00.7 Say	"Data Coleta" OF oPanel
   @ 1.5 , 04.7 MSGET	dDtColeta		Valid CheckSX3("ZLD_DTLANC") WHEN (nOpc==3 .And. lAbleTicket) OF oPanel
   @ 1.6 , 12.2 Say	"Data Lanc." OF oPanel
   @ 1.5 , 16.0 MSGET	dData			Valid CheckSX3("ZLD_DTLANC") WHEN .F. OF oPanel
      
   @ 2.6 , 00.7 Say	"Transport." OF oPanel
   @ 2.5 , 04.7 MSGET	cFretist		Valid CheckSX3("ZLD_FRETIS") .And. IIf( Empty(cFretist)	, .T. , AGLT003C() .And. AGLT003F() ) WHEN ((nOpc==3)) F3 GetSX3Cache("ZLD_FRETIS","X3_F3") OF oPanel
   @ 2.5 , 09.5 MSGET	cLjFret			Valid CheckSX3("ZLD_LJFRET") .And. IIf( Empty(cLjFret)	, .T. , AGLT003C() .And. AGLT003F() ) WHEN ((nOpc==3)) OF oPanel
   @ 2.5 , 12.8 MSGET	cDescFret		WHEN .F. OF oPanel
   
   @ 3.6 , 00.5 Say	"Setor" OF oPanel
   @ 3.5 , 04.7 MSGET	oSetor			VAR cSetor Valid CheckSX3("ZLD_SETOR") .And. Eval({||cDescSet:= Posicione("ZL2",1,xFilial("ZL2")+cSetor,"ZL2_DESCRI"),.T.});
                                          .And. U_getNwTicket(.T.) WHEN (nOpc==3) F3 GetSX3Cache("ZLD_SETOR","X3_F3") OF oPanel
   @ 3.5 , 09.5 MSGET	cDescSet		WHEN .F. OF oPanel

   @ 4.6 , 00.7 Say	"Linha/Rota" OF oPanel
   @ 4.5 , 04.7 MSGET	oLinRota		VAR cLinRot  Valid CheckSX3("ZLD_LINROT") .And. IIf(Empty(cLinRot),.T., AGLT003N(cLinRot,nOpc,lAbleticket)) WHEN (nOpc==3) F3 GetSX3Cache("ZLD_LINROT","X3_F3") OF oPanel
   @ 4.5 , 09.5 MSGET	cDescLin		WHEN .F. OF oPanel

   @ 4.6 , 26.5 Say	"Total KM" 	OF oPanel
   @ 4.5 , 29.3 MSGET	nTotKm 			Picture GetSX3Cache("ZLD_KM","X3_PICTURE") Valid (nTotKm >= 0 ) WHEN (nOpc==3.Or.nOpc==4)  OF oPanel
   
   @ 5.6 , 00.7 Say	"Motorista" OF oPanel
   @ 5.5 , 04.7 MSGET	cMotor			Valid CheckSX3("ZLD_MOTOR") .And. IIf(Empty(cMotor),.T., AGLT003M(cMotor) ) WHEN (nOpc==3.Or.nOpc==4) F3 GetSX3Cache("ZLD_MOTOR","X3_F3") OF oPanel
   @ 5.5 , 09.5 MSGET	cDescMot		WHEN .F. OF oPanel
   
   @ 5.6 , 26.7 Say	"Veiculo" OF oPanel
   @ 5.5 , 29.2 MSGET	cVeicul		Picture GetSX3Cache("ZLD_VEICUL","X3_PICTURE") Valid CheckSX3("ZLD_VEICUL") .And. IIf(Empty(cVeicul),Eval({||cPlacaVeic:="" ,.T.}), Eval({||cPlacaVeic:= Posicione("ZL1",1,xFilial("ZL1")+cVeicul,"ZL1_PLACA"),.T.}));
                           WHEN (nOpc==3.Or.nOpc==4)  F3 GetSX3Cache("ZLD_VEICUL","X3_F3") OF oPanel
   @ 5.5 , 34.2 MSGET	cPlacaVeic	WHEN .F. OF oPanel
      
   
   DEFINE FONT oFont1 NAME "Tahoma" BOLD
   
   @ 6.6 , 00.7 Say	"Ticket"			FONT oFont1 OF oPanel
   @ 6.5 , 04.7 MSGET	cTicket							Valid CheckSX3("ZLD_TICKET") .And. !AGLT003B(cTicket) WHEN (nOpc==3) FONT oFont1 SIZE 50,7 OF oPanel
   @ 6.5 , 12.0 Say	"Vol. Veiculo" OF oPanel
   @ 6.5 , 15.7 MSGET	nTotBom							Picture "@E 999,999,999" Valid (nTotBom >= 0 ) WHEN ((nOpc==3).and.lAbleTicket) SIZE 50,7 OF oPanel
   
   @ 6.5 , 22.6 Say	"Vol. Coletado" OF oPanel
   @ 6.5 , 27.1 MSGET	oLteBom			var nLeiteBom	Picture GetSX3Cache("ZLD_QTDBOM","X3_PICTURE")  WHEN .F. SIZE 50,7 OF oPanel
   @ 6.5 , 33.5 Say	"DIferenca" OF oPanel
   @ 6.5 , 36.8 MSGET	nDIf			var nLtDIf		Picture GetSX3Cache("ZLD_TOTBOM","X3_PICTURE")  WHEN .F.  SIZE 50,7 OF oPanel
      
   _lDeleta:=((nOpc == 3) .Or. (nOpc == 4))
   _nLINHAS:=999
   If nOpc = 4 .And. !Empty(ZLD->ZLD_ATENDI)
   _nLINHAS:=Len(aCols)
   EndIf

   //      MsGetDados():New( < nTop>       , < nLeft>   , < nBottom>    ,< nRight>,< nOpc>,[ cLinhaOk]    , [ cTudoOk],[cIniCpos],[ lDeleta],[aAlter],[nFreeze],[lEmpty], [ nMax], [ cFieldOk], [ cSuperDel], [ uPar], [ cDelOk]  , [ oWnd], [ lUseFreeze], [ cTela] )
     oGet := MSGetDados():New(aPosObj[2,1]+40,aPosObj[2,2],aPosObj[2,3]-10,aPosObj[2,4],nOpc,"Eval(bVldLin)","Eval(bVldTela)",""   ,_lDeleta  ,NIL     ,NIL      ,NIL     ,_nLINHAS,            ,             ,        ,"U_AGLT003L",        ,              ,         ) 
   
   // RODAPE DA TELA
    oPanelRoda := TPanel():New(aPosObj[2,3],0,'',oDlg,, .F., .F.,,,300,20,.F.,.F. )
   @4,005 Say "Total de Volume do Lancamento:"  Pixel   OF oPanelRoda
   @2,090 MSGET oTotCodRec var nTotCodRec Picture GetSX3Cache("ZLD_TOTBOM","X3_PICTURE")  WHEN .F. Pixel of oPanelRoda 
   
   If _lacols 
      aColsAux := aClone( aCols )
   EndIf
   // Atualiza campo nomeRetiro na getdados
   For _nI := 1 To Len(aCols)
      If !Empty( aCols[_nI][nPosRetiro] ) .And. !Empty( aCols[_nI][nPosLoja] )
         aCols[_nI][nPosNomRet] := Posicione( "SA2" , 1 , xFilial("SA2") + aCols[_nI][nPosRetiro] + aCols[_nI][nPosLoja] , "A2_NOME" )
      EndIf
   Next _nI

   ACTIVATE MSDIALOG oDlg ON INIT (EnchoiceBar(oDlg,{|| lConfirmou := AGLT003T(nOpc) ,If(lConfirmou,oDlg:End(),)},{||oDlg:End()},,aButtons),;
                                   oPanel:Align:=CONTROL_ALIGN_TOP,oPanelRoda:Align:=CONTROL_ALIGN_BOTTOM,;
                                   oGet:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT,oGet:oBrowse:Refresh())
   
   // Grava dados da ZLD
   If lConfirmou
      
      DBSelectArea("ZLD")
      
      Begin Sequence
      
      _lprocesso := .T.
      
      BEGIN TRANSACTION
      
      If nOpc == 3
         If !(AGLT003I( aCols ))
            _lprocesso := .F.
            Break
         EndIf
      ElseIf nOpc == 4
         If AGLT003D( aCols , .F. )
            If !(AGLT003I( aCols ))
               _lprocesso := .F.
               Break
            EndIf
         Else
            _lprocesso := .F.
            Break
         EndIf
      ElseIf nOpc == 5
         If !(AGLT003D( aColsAux , .T. ))
            _lprocesso := .F.
            Break
         EndIf
      EndIf
      
      ConfirmSx8() 

      END TRANSACTION
   
      End Sequence
      
      If !_lprocesso //Se falhou o processamento faz rollback de tudo e dá aviso
         Disarmtransaction()
         FWAlertError("Falha de gravação! Dados não foram atualizados!!!","AGLT00305")
      EndIf
      
   Else
      If (nOpc == 3 .Or. nOpc == 4) .And. !FWAlertYesNo("Confirma saída sem salvar?","AGLT00306")
         Loop
      EndIf
   EndIf
   
   Exit
   
EndDo

Return

/*
===============================================================================================================================
Programa----------: AGLT003L
Autor-------------: Jeovane
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para validar linha da getDados na tela de Recepcao de leite
Parametros--------: lDel: .T. OU .F.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT003L(nSource As Numeric)//A totvs resolveu forçar um parametros deles U_AGLT003L(nSource) no oGet:CDELOK
Return AGLT003L(.T.)

Static Function AGLT003L(lDel)

Local lRet		:= .T. As Logical
Local aAux		:= aCols[n] As Array//Pega Linha Atual
Local aAux1		:= {} As Array
Local nIndex	:= 0 As Numeric
Local cAtivo	:= "" As Character
Local _nX		:= 0 As Numeric

// Atualiza Variaveis de Totais
nleiteant   := nLeiteBom
nLeiteBom	:= nVolAnt + U_AGLT003S()
nTotCodRec	:= U_AGLT003S()
nLtDIf		:= nTotBom - nLeiteBom

If ValType(oLteBom) == 'O'
   oLteBom:Refresh()  
EndIf

If ValType(nDIf) == 'O'
   nDIf:Refresh()
EndIf

If ValType(oTotCodRec) == 'O'
   oTotCodRec:Refresh()
EndIf

If ValType(oDlg) == 'O'
   oDlg:Refresh()
EndIf

If lDel .And. Altera .And. !Empty(ZLD->ZLD_ATENDI)
   If nleiteant == nLeiteBom .And. !aTail(aCols[n])
         If _lvalida .And. !MsgYesNo("Atendimento integrado do SmartQuestion, confirma exclusão? Atendimento continuará ativo no SmartQuestion","AGLT00307")
           _lvalida := .F.
           Return .F.
         EndIf
      EndIf
      _lvalida := .T.
   Return .T.
EndIf

// VerIfica se a linha foi excluida
If aTail(aCols[n])
   Return( .T. )
EndIf

If Len( aCols ) > 1 .And. !(Altera .And. !Empty(ZLD->ZLD_ATENDI))
   For _nX := 1 to Len(aCols)
      If _nX != n .And. !aTail(aCols[_nX])
         aAdd(aAux1,aCols[_nX])
      EndIf
   Next _nX
   
   nIndex	:= aScan(aAux1,{|x| x[nPosRetiro] == aAux[nPosRetiro] .And. x[nPosLoja] == aAux[nPosLoja] })
   lRet	:= nIndex == 0
   
   If !lRet
      FWAlertInfo("Produtor já incluído neste recebimento. Não pode haver dois produtores na mesma coleta! Lance todos os volumes num só Produtor!","AGLT00308")
      Return lRet
   EndIf
EndIf

// VerIfica se o retiro esta dentro da linha informada
If !aTail( aCols[n] ) .And. !lDel
   
   cLinhaRota	:= Posicione("SA2",1,xFilial("SA2")+aAux[nPosRetiro]+aAux[nPosLoja],"A2_L_LI_RO")
   lRet		:= (cLinhaRota == cLinRot) .Or. (Altera .And. !Empty(ZLD->ZLD_ATENDI))
   
   If !lRet
      FWAlertWarning("Produtor informado não pertence a linha/rota informada, linha/rota do Produtor: "+cLinhaRota+ ". Selecione um Produtor que seja da linha informada.","AGLT00309")
      Return( lRet )
   EndIf
   
   If !Empty(aAux[nPosLoja])
      cAtivo	:= Posicione("SA2",1,xFilial("SA2")+aAux[nPosRetiro]+aAux[nPosLoja],"A2_L_ATIVO")
      lRet	:= cAtivo == "S"
      
      If !lRet
         FWAlertWarning('O produtor ['+ aAux[nPosRetiro] +'/'+ aAux[nPosLoja] +'] não está ativo no cadastro de Fornecedores! '+;
               'VerIfique o cadastro ou informe outro código de produtor.',"AGLT00310")
         Return( lRet )
      EndIf
   EndIf
   
   If Len( AllTrim(aAux[nPosRetiro]) ) > 0 .And. aAux[nPosQtdBom] == 0  .And. !(Altera .And. !Empty(ZLD->ZLD_ATENDI))
      FWAlertWarning("Ao informar um código de produtor deverá ser fornecida a sua litragem de coleta. Favor informa a litragem do produtor corrente.","AGLT00311")
      Return( .F. )
   EndIf
   
   //================================================================================
   // Efetua validacao no produtor corrente para verIficar se nao foi lancado nenhum 
   // evento para ele, se o mix nao esta fechado e de acordo com a data de coleta
   //================================================================================
   If lRet
      If AGLT003R( dDtcoleta , aAux[nPosRetiro] , aAux[nPosLoja] , cSetor , cLinRot )
          lRet := .F.
         Return( lRet )
      EndIf
   EndIf
EndIf

Return lRet

/*
===============================================================================================================================
Programa----------: AGLT003T
Autor-------------: Jeovane
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para validar todos os dados da tela na confirmação
Parametros--------: nOpcao: Opcao
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT003T(nOpcao As Numeric)

Local _lRet		:= .T. As Logical
Local _lRetLitr:= .T. As Logical
Local _nX		:= 0 As Numeric
Local _nI		:= 0 As Numeric

// Obte posicao dos campos no cabecalho os itens
nPosRetiro	:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_RETIRO"	} )
nPosLoja	:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_RETILJ"	} )
nPosQtdBom	:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_QTDBOM"	} )
nPosTqLt 	:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_TQ_LT"	} )
nPosNomRet	:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_DCRRET"	} )
nPosAtendi	:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_ATENDI" 	} )
nPosCodZLX	:= aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_CODZLX" 	} )

// Valida se foi lancado algum evento para o fretista do lancamento da recepcao
If AGLT003R( dDtcoleta , cFretist , cLjFret , cSetor , cLinRot )
   _lRet := .F.
   Return(_lRet)
EndIf

//================================================================================
// Efetua validacao no produtor corrente para verIficar se foi lancado um evento
// para ele, se o mix nao esta fechado e de acordo com a data de coleta
//================================================================================
If _lRet
   For _nX := 1 To Len( aCols )
      If !aTail( aCols[_nX] ) .And. !(Len( aCols ) == 1 .And. Empty( aCols[1][nPosRetiro] ) .And. Empty( aCols[1][nPosQtdBom] ))
         If AGLT003R( dDtcoleta , aCols[_nX,nPosRetiro] , aCols[_nX,nPosLoja] , cSetor , cLinRot )
            _lRet := .F.
         EndIf
         If Len(AllTrim(aCols[_nX,nPosRetiro])) > 0 .And. aCols[_nX,nPosQtdBom] == 0
            _lRetLitr := .F.
            Exit
         EndIf
      EndIf
   Next _nX
EndIf

If !_lRetLitr .And. !(Altera .And. !Empty(ZLD->ZLD_ATENDI))
   _lRet := .F.
   FWAlertWarning("Ao informar um codigo de produtor devera ser fornecida a sua litragem de coleta."+;
              "Existe(m) produtor(es) sem litragem informada, favor verIficar os registros de dados da recepção.","AGLT00312")
EndIf

If _lRet

   If nOpcao == 5
      Return( .T. )
   EndIf
   
   _lRet := ( AGLT003Q() .And. (!Empty(cFretist)) .And. (!Empty(cMotor)) .And.  (!Empty(cLjFret)) .And. (!Empty(dDtColeta))  .And.  (!Empty(cLinRot)) .And.  (!Empty(cSetor))   )
   
   If !_lRet
      If nOpcao == 3 .Or. nOpcao == 4
         FWAlertWarning("Existem campos obrigatórios não preenchidos, ou produtores de linhas/rotas dIferentes!"+;
               "Preencha os campos obrigatorios e verIfique se nao existe nenhum produtor de outra linha/rota!","AGLT00313")
      Else
         _lRet := .T.
      EndIf
   EndIf
   
   If _lRet .And. !(Altera .And. !Empty(ZLD->ZLD_ATENDI))
      // Valida a insercao de um mesmo produtor e loja na mesma recepcao de leite
      For _nX := 1 To Len(aCols)
         If !aTail(aCols[_nX])  
            For _nI := 1 To Len(aCols)       
               If !aTail(aCols[_nI]).And. _nX <> _nI
                  If aCols[_nX,nPosRetiro] == aCols[_nI,nPosRetiro] .And. aCols[_nX,nPosLoja] == aCols[_nI,nPosLoja]
                     FWAlertWarning("Produtor já incluído neste recebimento. Na linha: " + AllTrim(Str(_nX,3)) + " e " + AllTrim(Str(_nI,3))	+;
                           ". Nao pode haver dois produtores na mesma coleta! Lance todos os volumes num só Produtor!","AGLT00314")
                     _lRet := .F.
                     Exit
                  EndIf        
               EndIf
            Next _nI
         EndIf
         
         If !_lRet
            Exit
         EndIf
      Next _nX
   EndIf

EndIf

If _lRet .And. dDtcoleta > dDataBase
   _lRet := .F.
   FWAlertWarning("A Data de Coleta informada, é maior que "+DToC(dDataBase)+". VerIficar o conteúdo informado na Data de Coleta.","AGLT00315")
EndIf
//Valida se o usuário tem acesso ao setor informado.
If _lRet .And. (nOpcao == 3 .Or. nOpcao == 4)
   _lRet := U_VSetor(.T.,cSetor)
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: AGLT003N
Autor-------------: Jeovane
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para validar linha rota digitado na tela de Recepcao de leite
Parametros--------: cLinRot: cosigo da rota , nOpcao: opcao
Retorno-----------: lRet
===============================================================================================================================
*/
Static Function AGLT003N(cLinRot As Character,nOpcao As Numeric,lAbleticket As Logical)

Local lRet	:= .T. As Logical
Local aArea	:= FWGetArea() As Array

If !Empty( AllTrim(cLinRot) )
   ZL3->( DBSetOrder(1) )
   If ZL3->( DBSeek( xFilial("ZL3") + cLinRot ) )
      lRet := ZL3->ZL3_SETOR == cSetor
      
      If !lRet
         FWAlertWarning("A Linha selecionada nao pertence ao Setor Atual, Linha/Rota pertence ao Setor: "+ZL3->ZL3_SETOR+". Selecione uma linha/rota que pertence ao setor informado!","AGLT00317")
         oLinRota:SetFocus()
         FWRestArea(aArea)
         Return .F.
      EndIf
      
      If nOpcao == 3
         cVeicul		:= ZL3->ZL3_VEICUL
         If !Empty( cVeicul )
            DBSelectArea("ZL1")
            ZL1->( DBSetOrder(1) )
            If ZL1->( DBSeek( xFilial("ZL1") + cVeicul ) )
               cPlacaVeic := ZL1->ZL1_PLACA
            Else
               FWAlertWarning("O Veiculo selecionado não foi localizado! Selecione um veiculo relacionado ao Transportador!","AGLT00319")
               _lRet := .F.
            EndIf
         EndIf
         
         cMotor		:= Posicione( "ZL1" , 1 , xFilial("ZL1") + cVeicul	, "ZL1_MOTORI"	)
         cDescMot	:= Posicione( "ZL0" , 1 , xFilial("ZL0") + cMotor	, "ZL0_NOME"	)
      EndIf
      
      cDescLin := ZL3->ZL3_DESCRI
      
      If nOpcao == 3
         nTotKm := ZL3->ZL3_KM
      EndIf
   Else
      FWAlertWarning("Linha/Rota NÃO cadastrada. Selecione uma linha/rota que pertence ao setor informado!","AGLT00318")
      oLinRota:SetFocus()
      FWRestArea(aArea)
      Return .F.
   EndIf
EndIf

FWRestArea(aArea)

Return lRet

/*
===============================================================================================================================
Programa----------: AGLT003F
Autor-------------: Jeovane
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para validar Fretista digitado na tela de Recepcao de leite
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT003F()

Local _lRet			:= .T. As Logical
Local _aArea		:= FWGetArea() As Array

If !Empty( cFretist ) .And. Empty(cLjFret)
   cLjFret := Posicione( 'SA2' , 1 , xFilial('SA2') + cFretist , 'A2_LOJA' )
EndIf

If !Empty( cFretist ) .And. !Empty(cLjFret)
   cDescFret := Posicione( 'SA2' , 1 , xFilial('SA2') + cFretist + cLjFret , 'A2_NOME' )
EndIf

FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: AGLT003M
Autor-------------: Jeovane
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para validar motorista digitado na tela de Recepcao de leite
Parametros--------: cMotor: codigo do motor
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT003M( cMotor )

Local _lRet		:= .T.
Local _aArea	:= FWGetArea()

If Altera
   Return( .T. )
EndIf

If !Empty(cMotor)

   DBSelectArea("ZL0")
   ZL0->( DBSetOrder(1) )
   ZL0->( DBGoTop() )
   If ZL0->( DBSeek( xFilial("ZL0") + cMotor ) )
      cDescMot := ZL0->ZL0_NOME
      ZL1->( DBSetOrder(3) )
      If ZL1->( DBSeek( xFilial("ZL1") + cMotor ) )
         cPlacaVeic	:= ZL1->ZL1_PLACA
         cVeicul		:= ZL1->ZL1_COD
      EndIf
      If ZL0->ZL0_FRETIS != cFretist
         FWAlertWarning("O Motorista selecionado nao pertence ao Transportador! Selecione um motorista relacionado ao Transportador!","AGLT00320")
         _lRet := .F.
      EndIf
   
   Else
      FWAlertWarning("O Motorista selecionado nao foi localizado! Selecione um motorista relacionado ao Transportador!","AGLT00321")
      _lRet := .F.
   EndIf
EndIf

FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: AGLT003P
Autor-------------: Jeovane
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para criar legenda na tela de Recepcao de leite
Parametros--------: aCores: array
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT003P(aCores As Array)

Local aLegenda := {	{"BR_VERDE"		, "Aberto"		} ,; //Sem Status
               {"BR_VERMELHO"	, "Faturado"	}  } As Array //Sem Status

BrwLegenda( cCadastro , "Legenda" , aLegenda )

Return

/*
===============================================================================================================================
Programa----------: AGLT003S
Autor-------------: Jeovane
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para calcular total de uma coluna da getDados
Parametros--------: _lgat - chamada como gatilho
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AGLT003S(_lgat As Logical)

Local _nRet	:= 0 As Numeric
Local _nI	:= 0 As Numeric
Local _nCol	:= 0 As Numeric

Default _lgat := .F.

// Obtem posicao da coluna de quantidade de leite
_nCol := aScan( aHeader , {|x| AllTrim(x[2]) == "ZLD_QTDBOM" } )

// Se exist aCols e Linha nao deletada soma qtd
If Type("aCols") <> "U"
   For _nI := 1 To Len( aCols )
      If !aTail( aCols[_nI] )
         If ValType( aCols[_nI][_nCol] ) == "N"
            If _lgat
               If _nI == n
                  _nRet += M->ZLD_QTDBOM
               Else
                  _nRet += aCols[_nI][_nCol]					
               EndIf
            Else
               _nRet += aCols[_nI][_nCol]
            EndIf
         EndIf
      EndIf
   Next _nI
EndIf

Return _nRet

/*
===============================================================================================================================
Programa----------: AGLT003I
Autor-------------: Jeovane
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para inserir registros na ZLD
Parametros--------: aregs - arrays com dados a incluir
Retorno-----------: _lRet - se completou o processamento
===============================================================================================================================
*/
Static Function AGLT003I(aRegs As Array)

Local bOk			:= .T. As Logical
Local _nI			:= 0 As Numeric
Local _lRet       := .T. As Logical
Local _lGrava_ZLX := .F. As Logical
Local aDados      := {} As Array
Local _oDlg			:= Nil As Logical
Local _oMemoKM		:= Nil As Logical
Local _oBtnCon		:= Nil As Logical
Local _cJustKM		:= ZLD->ZLD_KMJUST As Character
Local _cDivKM		:= ZLD->ZLD_KMDIVE As Character
Local _nTolerKM	:= SuperGetMv("LT_KMTOLER",.F.,5) As Numeric

DBSelectArea("ZL3")
ZL3->( DBSetOrder(1) )
ZL3->( DBSeek( xFilial("ZL3") + cLinRot ) )

//Valida divergência entre o KM informado na recepção e o definido na Linha/Rota
If nTotKm - ZL3->ZL3_KM > _nTolerKM
   If FWAlertYesNo("O KM informado: " + AllTrim(Str(nTotKm))+" está fora da faixa de tolerância ("+AllTrim(Str(_nTolerKM))+") baseado no valor informado na Linha: " +AllTrim(Str(ZL3->ZL3_KM))+;
         " Deseja confirmar mesmo assim?","AGLT00343")
      DEFINE MSDIALOG _oDlg TITLE "JustIficativa" FROM 000,000 TO 180,500 PIXEL
         @005,005 Get _oMemoKM var _cJustKM MEMO Size 230,060 WHEN .T. OF _oDlg PIXEL
         @070,090 BUTTON _oBtnCon PROMPT "&Confirma" SIZE 38,11 PIXEL ACTION (IIf(!Empty(_cJustKM),_oDlg:End(),.F.), )
      ACTIVATE MSDIALOG _oDlg CENTERED
      _cDivKM := "S"
   Else
      Return .F.
   EndIf
Else
   _cDivKM := IIf(_cDivKM==" "," ","N")
   _cJustKM := " "
EndIf
Begin Sequence

// Projeto Automação das Recepções Tipo Plataforma
Private _lGerou_ZLX:=.F. //Alterada na Funcao U_AGLTGrv_ZLX()
ZLX->(dbOrderNickname("IT_I_TISET"))//ZLX_FILIAL+ZLX_TICKET+ZLX_SETOR //ZLX->(DBSetOrder(10))
_lGrava_ZLX:=_lGerou_ZLX:=ZLX->( DBSeek(xFilial()+cTicket+cSetor))
ZLX->(DBSetOrder(1))

If Inclui 
   // Projeto Automação das Recepções Tipo Plataforma
   _lGrava_ZLX:=ZL2->( DBSeek(xFilial()+cSetor)) .And. ZL2->ZL2_CRIRT = "1"
   If _lGrava_ZLX .And. !_lGerou_ZLX .And. Empty( (aDados:=U_AGLTTela_ZLX("ORI_ZLD")) )//Se o setor é para gerar e o Ticket não tem ainda no ZLX mostra a tela
      Return .F.
   EndIf

   // Grava Mov. Interno caso For inclusao
   FWMsgRun(,{|| bOk := U_AGLT003G( cTicket , 3 ) }, "Aguarde...", "Gravando entrada de estoque...")
EndIf


// Valida movimento interno para inclusão
If Inclui .And. !(bOk .And. SD3->D3_QUANT == nTotBom) .And. lAbleTicket //não teve movimento de estoque por ser complemento de ticket
   _lRet := .F.
   FWAlertWarning("Movimento de estoque não foi efetuado!","AGLT00322")
   Break
EndIf

// Se gravou Mi entrao grava recepcao
If bOk .Or. Altera
   If Inclui .And. lAbleTicket  //só grava como nova recepção se For novo ticket
      cCodRec := u_GetNumRec()
   ElseIf Inclui  //Se é complemento vê se precisa gerar novo número de recepção para rota dIferente na mesma viagem
      If !(AllTrim(crotaori) == AllTrim(cLinRot))
         cCodRec := u_GetNumRec()
      EndIf
   EndIf

    // Se nao houver nenhum item grava um registro em branco apenas para gerar estoque
   If Len( aRegs ) == 1 .And. Empty( aRegs[1][nPosRetiro] ) .And. Empty( aRegs[1][nPosQtdBom] )
      If aRegs[1][nPosRecno] = 0
         ZLD->( RecLock( "ZLD" , .T. ) )
      Else
         ZLD->( DBGoTo( aRegs[1][nPosRecno] ) ) 
         ZLD->( RecLock( "ZLD" , .F. ) )
      EndIf
      ZLD->ZLD_FILIAL	:= xFilial("ZLD")
      ZLD->ZLD_CODREC	:= cCodRec
      ZLD->ZLD_TICKET	:= cTicket
      ZLD->ZLD_DTLANC	:= dData
      ZLD->ZLD_DTCOLE	:= dDtColeta
      ZLD->ZLD_SETOR	:= cSetor
      ZLD->ZLD_LINROT	:= cLinRot
      ZLD->ZLD_FRETIS	:= cFretist
      ZLD->ZLD_LJFRET	:= cLjFret
      ZLD->ZLD_VEICUL	:= cVeicul
      ZLD->ZLD_MOTOR	:= cMotor
      ZLD->ZLD_KM		:= nTotKm
      ZLD->ZLD_STATUS	:= ' '
      ZLD->ZLD_USER	:= FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
      ZLD->ZLD_TOTBOM	:= nTotBom
      If nPosAtendi # 0 .And. !Empty(aRegs[1][nPosAtendi])
         ZLD->ZLD_ATENDI:=aRegs[1][nPosAtendi]
      EndIf
      If nPosCodZLX # 0 .And. !Empty(aRegs[1][nPosCodZLX])
         ZLD->ZLD_CODZLX:=aRegs[1][nPosCodZLX]
      EndIf
      ZLD->ZLD_KMDIVE := _cDivKM
      ZLD->ZLD_KMJUST	:= _cJustKM
      ZLD->( MSUnLock() )
   EndIf

   _lPrimieraVez:=.T.
   
   For _nI := 1 To Len( aRegs )
      If !aTail( aRegs[_nI] )	 //VerIfica se item esta deletado OS DELETADOS JÁ APAGADOS NA FUNCAO AGLT003D()
         If  !Empty( aRegs[_nI][nPosRetiro] ) .And. !Empty( aRegs[_nI][nPosLoja] )//aRegs[_nI][nPosQtdBom] <> 0 .And.
            If aRegs[_nI][nPosRecno] = 0
               ZLD->( RecLock( "ZLD" , .T. ) )
            Else
               ZLD->( DBGoTo( aRegs[_nI][nPosRecno] ) )//OS DELETADOS JÁ APAGADOS NA FUNCAO AGLT003D()
               ZLD->( RecLock( "ZLD" , .F. ) )
            EndIf
            
            ZLD->ZLD_FILIAL	:= xFilial("ZLD")
            ZLD->ZLD_CODREC	:= cCodRec
            ZLD->ZLD_TICKET	:= cTicket
            ZLD->ZLD_DTLANC	:= dData
            ZLD->ZLD_DTCOLE	:= dDtColeta
            ZLD->ZLD_SETOR 	:= cSetor
            ZLD->ZLD_LINROT	:= cLinRot
            ZLD->ZLD_RETIRO	:= aRegs[_nI][nPosRetiro]
            ZLD->ZLD_RETILJ	:= aRegs[_nI][nPosLoja]
            ZLD->ZLD_FRETIS	:= cFretist
            ZLD->ZLD_LJFRET	:= cLjFret
            ZLD->ZLD_VEICUL	:= cVeicul
            ZLD->ZLD_MOTOR	:= cMotor
            ZLD->ZLD_QTDBOM	:= aRegs[_nI][nPosQtdBom]
            ZLD->ZLD_TQ_LT	:= aRegs[_nI][nPosTqLt]
            ZLD->ZLD_KM		:= nTotKm
            ZLD->ZLD_STATUS	:= ' '
            ZLD->ZLD_USER 	:= FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
            ZLD->ZLD_TOTBOM	:= nTotBom
            If nPosAtendi # 0
               ZLD->ZLD_ATENDI:=aRegs[_nI][nPosAtendi]
            EndIf
            If nPosCodZLX # 0 .And. !Empty(aRegs[_nI][nPosCodZLX])
               ZLD->ZLD_CODZLX:=aRegs[_nI][nPosCodZLX]
            EndIf
            ZLD->ZLD_KMDIVE := _cDivKM
            ZLD->ZLD_KMJUST	:= _cJustKM
            // Projeto Automação das Recepções Tipo Plataforma
            If _lGrava_ZLX .And. _lPrimieraVez
               _lPrimieraVez:=.F.
               U_AGLTGrv_ZLX("ORI_ZLD",aDados)//Essa funcao esta no rdmake AGLT021.PRW
            EndIf
            ZLD->( MSUnLock() )
         EndIf
      EndIf
   Next _nI
EndIf

End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: AGLT003G
Autor-------------: Jeovane
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para gravar o movimento interno no estoque
Parametros--------: cCod......: TICKET DO MOVIMENTO
                    nOption...: 3 INCLUIR, 5 EXCLUIR
                    lSchedule.: SE ESTÁ RODANDO VIA SCHEDULE
                    nCusto....: CUSTO POR LITRO DO MOVIMENTO
Retorno-----------: _lRet.....: SE MOVIMENTO FOI GRAVADO COM SUCESSO
===============================================================================================================================
*/
User Function AGLT003G( cCod As Character, noption As Numeric, lSchedule As Logical, nCusto As Numeric) As Logical

Local _aCab1      :={} As Array
Local _aSD31      :={} As Array
Local _aToSD31    :={} As Array
Local cTm         := AllTrim(SuperGetMv("LT_ENTTM",.F.,"002")) As Character
Local cProduto    := AllTrim(SuperGetMv("LT_ENTPRO",.F.,"08000000004")) As Character
Local cLocal      := "" As Character
Local nVlrMix     := Posicione("ZL2",1,xFilial("ZL2")+cSetor,"ZL2_ULTMIX") As Numeric
Local bret        := .T. As Logical
Local _cArmaz     := "" As Character
Local _nmodant    := nModulo As Numeric
Local _cmodant    := cModulo As Character
Local _cTextoLog  := "" As Character
Local _cFileLog   := "" As Character
Local _aOrd       := SaveOrd({"ZLJ","ZLD"}) As Array
Local _cFiltro    :="%" As Character
Local _cDirLog    := SuperGetMV("IT_DIRLOG",.F.,"\temp\") + "AGLT003\" As Character
Local _cAlias     := "" As Character
Local _cFilVld34  := SuperGetMV('IT_FILVLD3',.F.,'') As Character
Local cChave      := "" As Character
Local _nRec04     := 0 As Numeric
Local _nRec34     := 0 As Numeric
Local _aTLinhas   := {} As Array
Local _lAchouTransf := .F. As Logical
Local _lEnvEmailErro:= .F. As Logical
Local _cPicD3QUAN   := PesqPict("SD3","D3_QUANT") As Character
Local _cPicB2QATU   := "@E 999,999,999,999,999.999"  As Character
Private _cFilTer    := AllTrim(SuperGetMV('IT_EST3FIL',.F.,'')) As Character // VerIfica parâmetro de configurações das Filiais que usam estoque em poder de terceiros
Private _cLocTer    := AllTrim(SuperGetMV('IT_EST3LOC',.F.,'')) As Character // VerIfica parâmetro de configurações dos Armazéns que usam estoque em poder de terceiros
Private _eccod      := ccod As Character
Private _lAmbTeste  := !totvs.framework.environment.Type.get() == '1' As Logical //1-Produção, 2-Homologação,3-Desenvolvimento
Private _cITFLNGRA  := SuperGetMV('IT_FLNGRA',.F.,'10') As Character

DEFAULT nCusto  := 0
DEFAULT lSchedule:=.F.    

If nVlrMix <= 0
   If !lSchedule
      FWAlertWarning("O valor do ultimo MIX nao foi preenchido no Cadastro de Setores. Preencha o valor do ultimo MIX no Cadastro de Setores.","AGLT00323")
   Else
      _cErroSche:="O valor do ultimo MIX nao foi preenchido no Cadastro de Setores. Preencha o valor do ultimo MIX no Cadastro de Setores."
      FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "AGLT00323"/*cMsgId*/, _cErroSche/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   EndIf
   Return(.F.)
EndIf

_cArmaz		:= Posicione( "ZL2" , 1 , xFilial("ZL2") + cSetor , "ZL2_LOCAL" )
cProduto	   := Posicione( "SB1" , 1 , xFilial("SB1") + cProduto , "B1_COD" )
nModulo		:= 4
cModulo		:= "EST"

// Cria o armazém se nao existir
cLocal		:= Posicione( "ZL2" , 1 , xFilial("ZL2") + cSetor , "ZL2_LOCAL" )

SB2->( DBSetOrder(1) )
If !SB2->( DBSeek( xFilial("SB2") + cProduto + cLocal ) )
   CriaSB2( cProduto , cLocal )
EndIf
//***********  INCLUSAO ***************************************************************//
If !Empty(cTm) .And. !Empty(cProduto) .And. nOption == 3 // INCLUIR ESTOQUE
//***********  INCLUSAO ***************************************************************//
_CDOC := GetSxeNum("SD3","D3_DOC")	

_aCab1 := {	{ "D3_FILIAL"	, xFilial("SD3"), Nil },;
            { "D3_TM"		   , cTm   			 , NIL },;//ENTRADA			{ "D3_DOC"		, _CDOC 			, NIL },;
            { "D3_EMISSAO"	, dDtcoleta		 , NIL } }

_aSD31 := {	{ "D3_COD"		, cProduto		, NIL },;
            { "D3_LOCAL"	, cLocal			   , NIL },;
            { "D3_QUANT"	, nTotBom			, NIL },;
            { "D3_CUSTO1"	, If(nCusto#0,nCusto,(nVlrMix*nTotBom))	, NIL },;
            { "D3_CUSTO3"	, If(nCusto#0,nCusto,(nVlrMix*nTotBom))	, NIL },; 
            { "D3_L_ORIG"	, cCod 									, nil },;	// Origem do documento - ticket
            { "D3_L_SETOR"	, cSetor								, nil },;	// Origem do documento - Setor
            { "D3_I_ORIGE"	, FUNNAME()                   , nil } }
   
aAdd(_aToSD31,_aSD31)

lMsErroAuto:= .F.
_cErroSche :="Não gravou a Recepcao de Leite devido a um erro ocorrido ao gerar Estoque: "

If !AGLT003O( cCod , If(ISALPHA(cCod),"",cSetor) )//Tirei o parametro de setor para não duplicar quando vir do SQ 
      MSExecAuto( {|x,y,z| mata241(x,y,z) } , _aCab1 , _aToSD31 , 3 ) //INCLUSAO DE ESTOQUE
      _CDOC:=SD3->D3_DOC
ElseIf ISALPHA(cCod)//quando vir do SQ    
   _cErroSche+="[ Ticket "+cCod+" + Setor "+cSetor+" já possui entrada no Estoque ]"
   If !lSchedule 
      FWAlertWarning(_cErroSche,"AGLT00325")
   EndIf
   bret := .F.
EndIf

If lMsErroAuto   //Para recepção automatica esta dentro de transacao
   If !lSchedule 
      _cErroSche+="[ MostraErro(): "+AllTrim(MostraErro())+" ]"
      FWAlertWarning(_cErroSche+". Tente novamente, se o erro persistir comunique urgentemente ao Suporte!","AGLT00325")
   Else
      _cErroSche+="[ MostraErro(): "+MostraErro(_cDirLog,'aglt003_'+AllTrim(cCod)+"_"+(DToS(DATE())+"_"+StrTran(Time(),":",""))+"_mostraerro.log")+" ]"
      FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "AGLT00325"/*cMsgId*/, _cErroSche/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   EndIf

   bret := .F.
ElseIf !bret
   FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "AGLT00344"/*cMsgId*/, _cErroSche/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   //PARA ter certeza que não vai entrar no ElseIf de baixo se der erro
ElseIf SD3->D3_DOC == _CDOC //Se completou o movimento interno com sucesso já faz a transferência para produto consumível
   ConfirmSX8() //Confirma movimento anterior
   If !(cFilAnt $ _cITFLNGRA ); //Filiais que não fazem transferência de leite a granel 
      .And. !(AllTrim(SuperGetMV("IT_LTMP",.F.,'08000000034')) == AllTrim(cProduto)) //Produto destino igual ao produto origem não precisa de transferência

      //****** Cabecalho a Incluir ***
      cDoc:=GetSxENum("SD3","D3_DOC",1)
      aAuto:={}
      aAdd(aAuto,{cDoc,dDtcoleta})  //Cabecalho

      //****** Cabecalho a Incluir ***

      //****** Itens a Incluir  ******
      SB1->(DBSetOrder(1))
      SB1->(DBSeek(xFilial()+cProduto)) // ORIGEM
      aItem:={}
      aAdd(aItem,cProduto)//D3_COD
      aAdd(aItem,SB1->B1_DESC)//D3_DESCRI
      aAdd(aItem,SB1->B1_UM)  //D3_UM
      aAdd(aItem,Posicione("ZL2",1,xFilial("ZL2")+cSetor,"ZL2_LOCAL"))  //D3_LOCAL
      aAdd(aItem,"")		    //D3_LOCALIZ //Endereço Orig

      _cDesCodProd := AVKEY(SuperGetMV("IT_LTMP",.F.,'08000000034'),"D3_COD")
      SB1->(DBSeek(xFilial()+_cDesCodProd)) // DESTINO
      aAdd(aItem,_cDesCodProd)//D3_COD
      aAdd(aItem,SB1->B1_DESC)//D3_DESCRI
      aAdd(aItem,SB1->B1_UM)  //D3_UM
      aAdd(aItem,Posicione("ZL2",1,xFilial("ZL2")+cSetor,"ZL2_LOCAL"))  //D3_LOCAL
      aAdd(aItem,"")		    //D3_LOCALIZ //Endereço Dest
      aAdd(aItem,"")          //D3_NUMSERI
      aAdd(aItem,"")  	    //D3_LOTECTL
      aAdd(aItem,"")         	//D3_NUMLOTE
      aAdd(aItem,CTOD(""))	    //D3_DTVALID
      aAdd(aItem,0)		    //D3_POTENCI
      aAdd(aItem,nTotBom)      //D3_QUANT
      aAdd(aItem,0)		    //D3_QTSEGUM
      aAdd(aItem,"")          //D3_ESTORNO
      aAdd(aItem,"")      	//D3_NUMSEQ
      aAdd(aItem,"")  	    //D3_LOTECTL
      aAdd(aItem,CTOD(""))	    //D3_DTVALID
      aAdd(aItem,"")	 	    //D3_ITEMGRD
      aAdd(aItem,"")	 	    //D3_OBSERVA  //Observação C        30
      //Campos Customizados:
      aAdd(aItem,"")	 	    //D3_I_OBS    // Observação C       254 		
      If ! cFilant $ _cFilVld34 // Este campo não deve estar disponível para filiais de validação do armazém 34 (Descarte).
         aAdd(aItem,"")	 	              //D3_I_TPTRS  // Mot.Tran.R C  1
         aAdd(aItem,"")	 	              //D3_I_DSCTM  // Des.Mot.Tr C  1
      EndIf 
      If cFilant $ _cFilVld34 // Este campo não deve estar disponível para filiais de validação do armazém 34 (Descarte).
         aAdd(aItem,"")	 	          //D3_I_MOTTR  // Mot.Tran.R C         8 
         aAdd(aItem,"")	 	          //D3_I_DSCMT  // Des.Mot.Tr C        40 
         aAdd(aItem,"")	 	          //D3_I_SETOR  // Origem Trf C        40 
         aAdd(aItem,"")	 	          //D3_I_DESTI  // Destino    C        40 
      EndIf 
      //****** Itens a Incluir  ******

      aAdd(aAuto,aItem)

      lMsErroAuto := .F.
      MSExecAuto({|x,y| MATA261(x,y)},aAuto,3)//INCLUSAO DA TRANSFERENCIA 
      If lMsErroAuto   //Para recepção automatica esta dentro de transacao
         If __lSx8
            RollBackSX8()
         EndIf
         If !lSchedule
            FWAlertWarning("Erro na transferência de produto " + cProduto + " para o produto " + _cDesCodProd + "!"+;
                  "Realize a transferência manualmente para garantir saldo para as OPs","AGLT00327")
            _cErroSche:="[ MostraErro(): "+AllTrim(MostraErro())+" ]"
         Else
            _cErroSche+="[ MostraErro(): "+MostraErro(_cDirLog,'aglt003_'+AllTrim(cCod)+"_"+(DToS(DATE())+"_"+StrTran(Time(),":",""))+"_mostraerro.log")+" ]"
            FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "AGLT00327"/*cMsgId*/, _cErroSche/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
         EndIf
         bret := .F.
      Else
         ConfirmSX8()
      EndIf
   EndIf
Else
   _cErroSche+="[ Caso seja troca de data do estoque, será necessário desfazer o estorno do movimento realizado. Entre em contato com o TI. ]"
   FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "AGLT00325"/*cMsgId*/, _cErroSche/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   If !lSchedule 
      FWAlertWarning(_cErroSche,"AGLT00325")
   EndIf
   bret:=.F.
EndIf

Else
   If !Empty(cTm) .And. !Empty(cProduto) .And. noption == 3
      _cErroSche:="Parâmetros LT_ENTPRO e LT_ENTTM não foram preenchidos ou já existe esse Ticket de Recepcao de Leite! Não foi possível gerar estoque!"
      FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "AGLT00329"/*cMsgId*/, _cErroSche/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      If !lSchedule
         FWAlertWarning(_cErroSche+" Comunique urgentemente ao Suporte!","AGLT00329")
      EndIf
      bret := .F.
   EndIf
EndIf

_lEnvEmailErro:=.F.
//************************************ ESTORNO DO ESTOQUE  ************************************************************************
If nOption == 5 // EXCLUIR ESTOQUE
   //************************************ ESTORNO DO ESTOQUE  ************************************************************************
   Begin Sequence

   //Localiza movimento de estorno
   _lAchouTransf:= .F.
   cChave :=""
   _nRec04:=0
   _nRec34:=0
   _aTLinhas:={}
   _cUserName:= UsrFullName(__cUserId)
   _cMostraCalls:=MostraCalls()
   //             1  2  3  4  5  6  7  8  9
   _aDadosEmail:={"","","","","","","","",""}
   _aDadosEmail[8]:=StrTran(AllTrim(ZLJ->ZLJ_MOTIVO),"<br>")
   _aDadosEmail[9]:=StrTran(_cMostraCalls,CRLF,"<br>")

   _cTextoLog+="[ ddatabase: "+DToC(ddatabase)+" - "+_cUserName+" - DATE(): "+DToC(DATE())+" ]"+CRLF
   _cTextoLog+="Caminho da chamada [ "+CRLF+_cMostraCalls+" ]"+CRLF+CRLF
   _cTextoLog+="ZLJ_MOTIVO: [ "+AllTrim(ZLJ->ZLJ_MOTIVO)+" ]"+CRLF+CRLF

   SD3->(DBSetOrder(13)) //D3_FILIAL + D3_CHAVEF1
   If SD3->(DBSeek(CFILANT + "AGLT003" + ccod+cSetor)) 
      cChave:="AGLT003" + ccod+cSetor
   ElseIf SD3->(DBSeek(CFILANT + "AGLT003" + ccod))
      cChave:="AGLT003" + ccod
   EndIf   

   If !Empty(cChave)
      While SD3->D3_FILIAL == CFILANT .And. AllTrim(SD3->D3_CHAVEF1) = AllTrim(cChave)
         If SD3->D3_ESTORNO != 'S'
            _lAchouTransf := .T.
            If SD3->D3_COD = "08000000004"
               _nRec04:=SD3->(RECNO())
               _aDadosEmail[1]:="("+SD3->D3_COD+" / "+SD3->D3_NUMSEQ+" / "+CFILANT+" / "+AllTrim(SD3->D3_CHAVEF1)+" / D3_ESTORNO='"+SD3->D3_ESTORNO+"') foi encontrado"
               _cTextoLog+="[ Lançamento de transferencia origem: ( "+SD3->D3_COD+" / "+SD3->D3_NUMSEQ+" / "+CFILANT+" / "+AllTrim(SD3->D3_CHAVEF1)+" / D3_ESTORNO='"+SD3->D3_ESTORNO+"') FOI ENCONTRADO ]"+CRLF+CRLF
            EndIf
            If SD3->D3_COD = "08000000034"
               _nRec34:=SD3->(RECNO())
               _aDadosEmail[2]:="("+SD3->D3_COD+" / "+SD3->D3_NUMSEQ+" / "+CFILANT+" / "+AllTrim(SD3->D3_CHAVEF1)+" / D3_ESTORNO='"+SD3->D3_ESTORNO+"') foi encontrado "
               _cTextoLog+="[ Lançamento de transferencia destino: ( "+SD3->D3_COD+" / "+SD3->D3_NUMSEQ+" / "+CFILANT+" / "+AllTrim(SD3->D3_CHAVEF1)+" / D3_ESTORNO='"+SD3->D3_ESTORNO+"') FOI ENCONTRADO ]"+CRLF+CRLF
            EndIf
         EndIf
         SD3->(DBSkip())
      EndDo
   Else 
      _aDadosEmail[1]:="Essa filial não possui movimento de transferência de leite a granel."
      _aDadosEmail[2]:="Filiais que não fazem transferência de leite a granel : "+_cITFLNGRA//Filiais que não fazem transferência de leite a granel 
      cChave:="AGLT003 / " + ccod+" / "+cSetor
   EndIf
   _cErroSche:=""
   ZLJ->(DBSetOrder(2))
   
   If ZLJ->( DBSeek( xFilial() + cCod) )
      _cErroSche+="Achou na ZLJ c/ Status: "+ZLJ->ZLJ_STATUS+CRLF+CRLF
      _aDadosEmail[3]:="Achou na ZLJ c/ Status: "+ZLJ->ZLJ_STATUS
   Else
      _cErroSche+="Não Achou na ZLJ"+CRLF+CRLF
      _aDadosEmail[3]:="Não Achou na ZLJ"
   EndIf
   ZLD->(DBSetOrder(3))
   If ZLD->( DBSeek( xFilial() + cCod) )
      _cErroSche+="Achou na ZLD c/ Status: "+ZLD->ZLD_STATUS+CRLF+CRLF
      _aDadosEmail[4]:="Achou na ZLD c/ Status: "+ZLD->ZLD_STATUS
   Else
      _cErroSche+="Não Achou na ZLD"+CRLF+CRLF
      _aDadosEmail[4]:="Não Achou na ZLD"
   EndIf
   _cTextoLog+=_cErroSche
   _cCab1:=_cCab2:=""

   If _lAchouTransf
      
      _cCab1:="Transferencia;Filial;D3_NUMSEQ;Cod.Produto;Local;D3_EMISSAO;Qtde.SD3;B2_QATU;Saldo;D3_ESTORNO;Usuario.SD3"
      _cTextoLog+=_cCab1 + CRLF

      SB2->(DBSetOrder(1))
      If _nRec04 > 0
         SD3->(DBGoTo(_nRec04))

         SB2->(DBSeek(xFilial("SB2")+SD3->D3_COD+SD3->D3_LOCAL))
         _lSomaPTer :=(SB2->B2_FILIAL $ _cFilTer .And. SB2->B2_LOCAL $ _cLocTer)
         _nSaldoDisp:=SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP + If(_lSomaPTer,SB2->B2_QNPT,0)

         _cLinha:="Antes.mata261;"+xFilial("SD3")+";"+SD3->D3_NUMSEQ+";"+SD3->D3_COD+";"+SD3->D3_LOCAL+";"+DToC(SD3->D3_EMISSAO)+";"+TRANS((SD3->D3_QUANT),_cPicD3QUAN)+";"+TRANS((SB2->B2_QATU),_cPicB2QATU)+";"+TRANS((_nSaldoDisp),_cPicB2QATU)+";"+SD3->D3_ESTORNO+";"+SD3->D3_USUARIO
         aAdd(_aTLinhas,_cLinha)
         _cTextoLog+=_cLinha
         _cTextoLog+=CRLF
      EndIf

      If _nRec34 > 0
         SD3->(DBGoTo(_nRec34))
         SB2->(DBSeek(xFilial()+SD3->D3_COD+SD3->D3_LOCAL))
         _lSomaPTer :=(SB2->B2_FILIAL $ _cFilTer .And. SB2->B2_LOCAL $ _cLocTer)
         _nSaldoDisp:=SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP + If(_lSomaPTer,SB2->B2_QNPT,0)

         _cLinha:="Antes.mata261;"+xFilial("SD3")+";"+SD3->D3_NUMSEQ+";"+SD3->D3_COD+";"+SD3->D3_LOCAL+";"+DToC(SD3->D3_EMISSAO)+";"+TRANS((SD3->D3_QUANT),_cPicD3QUAN)+";"+TRANS((SB2->B2_QATU),_cPicB2QATU)+";"+TRANS((_nSaldoDisp),_cPicB2QATU)+";"+SD3->D3_ESTORNO+";"+SD3->D3_USUARIO
         aAdd(_aTLinhas,_cLinha)
         _cTextoLog+=_cLinha
         _cTextoLog+=CRLF
      EndIf

      If _nRec04 > 0//DEIXA POSICIONADO NA PRODUTO 08000000004
         SD3->(DBGoTo(_nRec04))
      EndIf

      //FAZ ESTORNO DA TRANSFERÊNCIA
      _ddataori := ddatabase
      ddatabase := SD3->D3_EMISSAO
      aAuto := {}   
      lMsErroAuto  := .F.
      MSExecAuto({|x,y| mata261(x,y)},aAuto,6) //ESTORNO DA TRANSFERÊNCIA
      ddatabase := _ddataori

      SB2->(DBSetOrder(1))//Reordeno pq o mata261 pode pode tirar da ordem 1
      _lEstonornou:=.T.
      If _nRec04 > 0
         SD3->(DBGoTo(_nRec04))
         SB2->(DBSeek(xFilial()+SD3->D3_COD+SD3->D3_LOCAL))
         _lSomaPTer :=(SB2->B2_FILIAL $ _cFilTer .And. SB2->B2_LOCAL $ _cLocTer)
         _nSaldoDisp:=SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP + If(_lSomaPTer,SB2->B2_QNPT,0)

         _cLinha:="Depois.mata261;"+xFilial("SD3")+";"+SD3->D3_NUMSEQ+";"+SD3->D3_COD+";"+SD3->D3_LOCAL+";"+DToC(SD3->D3_EMISSAO)+";"+TRANS((SD3->D3_QUANT),_cPicD3QUAN)+";"+TRANS((SB2->B2_QATU),_cPicB2QATU)+";"+TRANS((_nSaldoDisp),_cPicB2QATU)+";"+SD3->D3_ESTORNO+";"+SD3->D3_USUARIO
         aAdd(_aTLinhas,_cLinha)
         _cTextoLog+=_cLinha+CRLF
         _lEstonornou:=(SD3->D3_ESTORNO = 'S')
      EndIf
      
      If _nRec34 > 0
         SD3->(DBGoTo(_nRec34))
         SB2->(DBSeek(xFilial()+SD3->D3_COD+SD3->D3_LOCAL))
         _lSomaPTer :=(SB2->B2_FILIAL $ _cFilTer .And. SB2->B2_LOCAL $ _cLocTer)
         _nSaldoDisp:=SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP + If(_lSomaPTer,SB2->B2_QNPT,0)

         _cLinha:="Depois.mata261;"+xFilial("SD3")+";"+SD3->D3_NUMSEQ+";"+SD3->D3_COD+";"+SD3->D3_LOCAL+";"+DToC(SD3->D3_EMISSAO)+";"+TRANS((SD3->D3_QUANT),_cPicD3QUAN)+";"+TRANS((SB2->B2_QATU),_cPicB2QATU)+";"+TRANS((_nSaldoDisp),_cPicB2QATU)+";"+SD3->D3_ESTORNO+";"+SD3->D3_USUARIO
         aAdd(_aTLinhas,_cLinha)
         _cTextoLog+=_cLinha+CRLF+CRLF
         _lEstonornou:=(_lEstonornou .And. (SD3->D3_ESTORNO = 'S'))
      EndIf

      If lMsErroAuto .Or. !_lEstonornou//Se ainda está posicionado em um SD3 válido com mesmo número de sequência é porque a exclusão não deu certo
         _lEnvEmailErro:=.T.
         _cErroSche:="( "+CFILANT+" / "+SD3->D3_NUMSEQ+" / "+AllTrim(SD3->D3_CHAVEF1)+" / D3_ESTORNO='"+SD3->D3_ESTORNO+"' ) NÃO foi estornado."+CRLF
         If lMsErroAuto			
            _cErroME:=AllTrim(MostraErro())
            While RIGHT(_cErroME,2) = CRLF .And. Len(_cErroME) > 0
               _cErroME:=LEFT(_cErroME,Len(_cErroME)-2)//TIRA OS ENTERs FINAIS
            EndDo
            _cErroSche+="[ MostraErro(): "+AllTrim(_cErroME)+" ]"
            _aDadosEmail[5]:=StrTran(_cErroSche,CRLF,"<br>")
         Else
            _aDadosEmail[5]:=StrTran(_cErroSche,CRLF,"  ")
         EndIf
         _cTextoLog += CRLF+CRLF+"Resultado do estorno da tranferencia: "+_cErroSche+CRLF+CRLF
         If !lSchedule
            FWAlertWarning("Erro ao excluir Recepcao de Leite devido a um erro ocorrido ao excluir transferência de Estoque: "+_cErroSche +;
                     "Tente novamente, se o erro persistir comunique urgentemente ao Suporte de TI","AGLT00331")
         EndIf
         bret := .F.
         // *************************  SAI AQUI NEM TENTA O PROXIMO ******************************
         BREAK// ********************  SAI AQUI NEM TENTA O PROXIMO ******************************
         // *************************  SAI AQUI NEM TENTA O PROXIMO ******************************
      Else
         _cErroSche:="( "+CFILANT+" / "+SD3->D3_NUMSEQ+" / "+AllTrim(SD3->D3_CHAVEF1)+" / D3_ESTORNO='"+SD3->D3_ESTORNO+"') FOI ESTORNADO."
         _cTextoLog+="Resultado do estorno da tranferencia: "+_cErroSche+CRLF
      EndIf
   Else
      _cErroSche:="( Filial: "+CFILANT+" /  Chave: "+cChave+"' ) NAO foi encontrado."
      _cTextoLog+="Resultado do estorno da tranferencia: "+_cErroSche+CRLF+CRLF
   EndIf
   _aDadosEmail[5]:=StrTran(_cErroSche,CRLF,"<br>")

   SD3->(DBSetOrder(1))
   _cAlias := GetNextAlias()

   If !Empty(cSetor)
      _cFiltro += " AND D3_L_SETOR = '"+ cSetor+"' "
   EndIf
   _cFiltro += "%"
      
   BeginSql alias _cAlias
      SELECT R_E_C_N_O_ SD3REC
      FROM %Table:SD3% SD3
      WHERE D_E_L_E_T_ = ' '
      %exp:_cFiltro%
      AND D3_FILIAL = %xFilial:SD3%
      AND D3_ESTORNO <> 'S'
      AND D3_L_ORIG  = %exp:cCod%
   EndSql	

   _cTextoLog+=CRLF
   _aDadosEmail[6]:="[ "+GETLASTQUERY()[2] +" ]"
   _cCab2:="Estoque;Filial;D3_NUMSEQ;Cod.Produto;Local;D3_EMISSAO;Qtde.SD3;B2_QATU;Saldo;D3_ESTORNO;Usuario.SD3"
   If !_lAchouTransf
      _cCab1:=_cCab2
   EndIf

   While (_cAlias)->( !Eof() )

      _aDadosEmail[6]:=_aDadosEmail[6]+" foi encontrado. "
      _cTextoLog+="SELECT da busca do Estoque: "+_aDadosEmail[6]+CRLF+CRLF
      _cTextoLog+=_cCab2 + CRLF

      SD3->(DBSetOrder(1))
      _aAutoSD3 := {}
      SD3->(DBGoTo((_cAlias)->SD3REC))

      aAdd( _aAutoSD3,{"D3_NUMSEQ"  , SD3->D3_NUMSEQ	, nil } )	// Sequencia
      aAdd( _aAutoSD3,{"D3_CHAVE"	, SD3->D3_CHAVE   , nil } )	// Chave de indexação
      aAdd( _aAutoSD3,{"D3_COD"		, SD3->D3_COD	   , nil } )	// Codigo do Produto
      aAdd( _aAutoSD3,{"D3_DOC"	   , SD3->D3_DOC	   , nil } )	// Documento
      aAdd( _aAutoSD3,{"D3_CF"	   , SD3->D3_CF      , nil } )	// Tipo da Movimentacao Interno
      aAdd( _aAutoSD3,{"INDEX"	   , 4               , nil } )	// indexação
      
      lMsErroAuto := .F.

      SB2->(DBSeek(xFilial()+SD3->D3_COD+SD3->D3_LOCAL))
      _lSomaPTer :=(SB2->B2_FILIAL $ _cFilTer .And. SB2->B2_LOCAL $ _cLocTer)
      _nSaldoDisp:=SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP + If(_lSomaPTer,SB2->B2_QNPT,0)

      _cLinha:="Antes.mata240;"+xFilial("SD3")+";"+SD3->D3_NUMSEQ+";"+SD3->D3_COD+";"+SD3->D3_LOCAL+";"+DToC(SD3->D3_EMISSAO)+";"+TRANS((SD3->D3_QUANT),_cPicD3QUAN)+";"+TRANS((SB2->B2_QATU),_cPicB2QATU)+";"+TRANS((_nSaldoDisp),_cPicB2QATU)+";"+SD3->D3_ESTORNO+";"+SD3->D3_USUARIO
      _cTextoLog+=_cLinha
      _cTextoLog+=CRLF
      aAdd(_aTLinhas,_cLinha)
      MSExecAuto( {|x,y| Mata240(x,y) } , _aAutoSD3 , 5 ) //ESTORNO DO ESTOQUE
      SD3->(DBGoTo((_cAlias)->SD3REC))

      SB2->(DBSetOrder(1))//Reordeno pq o Mata240 pode pode tirar da ordem 1
      SB2->(DBSeek(xFilial()+SD3->D3_COD+SD3->D3_LOCAL))
      _lSomaPTer :=(SB2->B2_FILIAL $ _cFilTer .And. SB2->B2_LOCAL $ _cLocTer)
      _nSaldoDisp:=SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP + If(_lSomaPTer,SB2->B2_QNPT,0)
      
      _cLinha:="Depois.mata240;"+xFilial("SD3")+";"+SD3->D3_NUMSEQ+";"+SD3->D3_COD+";"+SD3->D3_LOCAL+";"+DToC(SD3->D3_EMISSAO)+";"+TRANS((SD3->D3_QUANT),_cPicD3QUAN)+";"+TRANS((SB2->B2_QATU),_cPicB2QATU)+";"+TRANS((_nSaldoDisp),_cPicB2QATU)+";"+SD3->D3_ESTORNO+";"+SD3->D3_USUARIO
      _cTextoLog+=_cLinha
      aAdd(_aTLinhas,_cLinha)
      
      If lMsErroAuto .Or. SD3->D3_ESTORNO <> 'S'//Se ainda está posicionado em um SD3 válido com mesmo número de sequência é porque a exclusão não deu certo
         _lEnvEmailErro:=.T.
         _cErroSche:="( "+CFILANT+" / "+SD3->D3_NUMSEQ+" / "+AllTrim(SD3->D3_L_ORIG)+" / D3_ESTORNO='"+SD3->D3_ESTORNO+"') NÃO foi estornado. "+CRLF
         If lMsErroAuto			
            _cErroME:=AllTrim(MostraErro())
            While RIGHT(_cErroME,2) = CRLF .And. Len(_cErroME) > 0
               _cErroME:=LEFT(_cErroME,Len(_cErroME)-2)//TIRA OS ENTERs FINAIS
            EndDo
            _cErroSche +="[ MostraErro(): "+_cErroME+" ]"
            _aDadosEmail[7]:=StrTran(_cErroSche,CRLF,"<br>")
         Else
            _aDadosEmail[7]:=StrTran(_cErroSche,CRLF,"  ")
         EndIf
         _cTextoLog += CRLF+CRLF+"Resultado do estorno do estoque: "+_cErroSche
         bret := .F.
         If !lSchedule
            MsgStop("Erro ao excluir Recepcao de Leite devido a um erro ocorrido ao excluir Estoque: "+_cErroSche +;
                     "Tente novamente, se o erro persistir comunique urgentemente ao Suporte de TI","AGLT00332")
         EndIf
         Exit
      Else
         _cErroSche:="( "+CFILANT+" / "+SD3->D3_NUMSEQ+" / "+AllTrim(SD3->D3_L_ORIG)+" / D3_ESTORNO='"+SD3->D3_ESTORNO+"') FOI ESTORNADO."
         _aDadosEmail[7]:=_cErroSche
         _cTextoLog+=CRLF+CRLF+"Resultado do estorno do estoque: "+_cErroSche
      EndIf
            
      (_cAlias)->( DBSkip() )
   EndDo

   If (_cAlias)->( Eof() ) .And. (_cAlias)->( Bof() )
      If !lSchedule
         FWAlertWarning("Não foram encontrados movimentos de estoque para essa Viagem: "+cCod+;
                  ". A recusa ou exclusão da viagem será feita mesmo sem os movimentos!","AGLT00333")
      EndIf
      
      _cErroSche:="( "+CFILANT+" / "+SD3->D3_NUMSEQ+" / "+AllTrim(SD3->D3_L_ORIG)+" / D3_ESTORNO='"+SD3->D3_ESTORNO+"') NÃO FOI ENCONTRADO. A recusa ou exclusão da viagem foi feita mesmo sem os movimentos. ] "
      _cTextoLog+=CRLF+CRLF+"Resultado do estorno do estoque: "+_cErroSche
      _aDadosEmail[7]:=_cErroSche

      bret := .T.// Nao retorna falso se não achou pq não teve entrada no estoque, portanto vai
      _lEnvEmailErro:=.T.
   EndIf

   (_cAlias)->( DBCloseArea() )

   End Sequence

   _cFileLog:= _cDirLog+'aglt003_'+AllTrim(cCod)+"_"+(DToS(DATE())+"_"+StrTran(Time(),":",""))+".csv" 
   MemoWrite(LOWER(_cFileLog),_cTextoLog)
EndIf

If nOption == 5 .And. !lSchedule .And. ( _lEnvEmailErro .Or. !_lAmbTeste  )
   
   _aConfig:= U_ITCFGEML('') 
   _cEmail:="sistema@italac.com.br"
   _cEmlLog:=""
   _cAssunto:="AGLT0003 - Envio do LOG de estorno de Estoque do Leite, Filial "+cFilAnt+" Viagem: "+cCod

   _cMsgEml:=AGLT003Mail(_cAssunto,_cCab1,_cCab2,_aTLinhas,_aDadosEmail)
   
   //    ITEnvMail(cFrom     ,cEmailTo ,cEmailCo,cEmailBcc,cAssunto ,cMensagem,cAttach   ,cAccount    ,cPassword   ,cServer      ,cPortCon    ,lRelauth     ,cUserAut     ,cPassAut     ,cLogErro)
   U_ITENVMAIL( _aConfig[01] , _cEmail ,        ,         ,_cAssunto, _cMsgEml,_cFileLog,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
   If _lAmbTeste
      If !lSchedule
         MsgInfo( _cEmlLog+CRLF+"E-mails: "+_cEmail+CRLF+" Anexo: "+_cFileLog, "AGLT0003 - Envio do Erro por e-mail")
      EndIf
   EndIf
EndIf

nModulo := _nmodant
cModulo := _cmodant
RestOrd(_aOrd,.T.)

Return bret

/*
===============================================================================================================================
Programa----------: AGLT003O
Autor-------------: Abrahao
Data da Criacao---: 09/10/2008
Descrição---------: Funcao usada verIficar se existe um movimento interno relativo a entrada
Parametros--------: ccod - ticket do movimento
               cpsetor - setor do movimento
Retorno-----------: _lRet - se existe ou não o movimento
===============================================================================================================================
*/
Static Function AGLT003O(cCod As Character,cpSetor As Character)

Local _lRet		:= .F. As Logical
Local _cAlias	:= GetNextAlias() As Character
Local _cFiltro	:= "%" As Character

If !Empty(cpSetor)
   _cFiltro += " AND D3_L_SETOR = '"+ cpSetor +"' "
EndIf
_cFiltro += "%"

BeginSql alias _cAlias
   SELECT COUNT(1) QTD_D3
   FROM %Table:SD3%
   WHERE D_E_L_E_T_ = ' '
   %exp:_cFiltro%
   AND D3_ESTORNO <> 'S'
   AND D3_L_ORIG  = %exp:cCod%
EndSql

_lRet := ( (_cAlias)->QTD_D3 > 0 )

(_cAlias)->( DBCloseArea() )

Return(_lRet)

/*
===============================================================================================================================
Programa----------: AGLT003D
Autor-------------: Jeovane
Data da Criacao---: 15/09/2008
Descrição---------: Funcao usada para apagar registros na ZLD
Parametros--------: aregs - array com registros a apagar
               lDelestoque - Se faz estorno do estoque ou não
Retorno-----------: _lRet - Se gravou os movimentos com sucesso ou não
===============================================================================================================================
*/
Static Function AGLT003D(aRegs As Array,lDelEstoque As Logical)

Local aArea		:= FWGetArea() As Array
Local lContinue:= .F. As Logical
Local _nI		:= 0 As Numeric
Private _llret	:= .F. As Logical

//================================================================================
// Se nao houver mais nenhum lançamento com esse ticket, entao Deleta o Movimento
// Interno e continua exclusao
//================================================================================
If AGLT003A( cTicket , cSetor ) .And. lDelEstoque
   FWMsgRun(,{|| _llret := U_AGLT003G( cTicket , 5 ) }, "Aguarde...", "Gravando estorno de estoque...")

   If _llret
      lContinue := .T.
   EndIf
Else
   lContinue := .T.
EndIf

_lPrimieraVez:=.T.
If lContinue
   DBSelectArea("ZLD")
   ZLD->( DBSetOrder(2) ) //ZLD_FILIAL+ZLD_CODREC+ZLD_RETIRO+ZLD_RETILJ
   For _nI := 1 To Len( aRegs )
      If  aRegs[_nI][nPosRecno] # 0 //ZLD->( DBSeek( xFilial("ZLD")+cCodRec + aRegs[_nI][nPosRetiro] + aRegs[_nI][nPosLoja] ) )
            If lDelEstoque .Or. aTail( aRegs[_nI] )//VerIfica se é exlcusao do Ticket OU se o item foi deletado
              ZLD->( DBGoTo( aRegs[_nI][nPosRecno] ) ) 
              ZLD->( RecLock( "ZLD" , .F. ) )
              ZLD->( DBDelete() )
              ZLD->( MSUnLock() )
            EndIf

            If _lPrimieraVez
               If lDelEstoque
                  U_AGLTGrv_ZLX("EXCLUI")//Essa funcao esta no rdmake AGLT021.PRW
               ElseIf !Empty( aRegs[_nI][nPosRetiro] ) .And. !Empty( aRegs[_nI][nPosLoja] )
                  U_AGLTGrv_ZLX("LIMPA")//Essa funcao esta no rdmake AGLT021.PRW
               EndIf
            EndIf
          _lPrimieraVez:=.F.
      EndIf
   Next _nI
EndIf

FWRestArea(aArea)

Return lContinue

/*
===============================================================================================================================
Programa----------: AGLT003C
Autor-------------: Abrahao
Data da Criacao---: 17/10/2008
Descrição---------: Funcao que busca setor,linha,veiculo padroes do Fretista e lanca nas variaveis
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT003C

Local _aArea	:= FWgetArea() As Character
Local _lRet		:= .F. As Logical
Local _cAlias	:= GetNextAlias() As Character

If Empty( cLjFret )
   Return( .T. )
EndIf

If nOpc == 4
   Return(_lRet)
EndIf

BeginSql alias _cAlias
   SELECT ZL3_COD, ZL3_DESCRI, ZL3_SETOR, ZL3_VEICUL, ZL3_KM, ZL2_DESCRI
   FROM %Table:ZL3% ZL3, %Table:ZL2% ZL2
   WHERE ZL3.D_E_L_E_T_ = ' '
   AND ZL2.D_E_L_E_T_ = ' '
   AND ZL3.ZL3_FILIAL = %xFilial:ZL3%
   AND ZL2.ZL2_FILIAL = %xFilial:ZL2%
   AND ZL2.ZL2_COD = ZL3.ZL3_SETOR
   AND ZL3.ZL3_FRETIS = %exp:cFretist%
   AND ZL3.ZL3_FRETLJ = %exp:cLjFret%
EndSql

If (_cAlias)->( !Eof() )
   cLinRot		:= (_cAlias)->ZL3_COD
   cDescLin	:= (_cAlias)->ZL3_DESCRI
   cSetor		:= (_cAlias)->ZL3_SETOR
   cDescSet	:= (_cAlias)->ZL2_DESCRI
   cVeicul		:= (_cAlias)->ZL3_VEICUL
   cMotor		:= Posicione( "ZL1" , 1 , xFilial("ZL1") + cVeicul	, "ZL1_MOTORI"	)
   cPlacaVeic	:= Posicione( "ZL1" , 1 , xFilial("ZL1") + cVeicul	, "ZL1_PLACA"	)
   cDescMot	:= Posicione( "ZL0" , 1 , xFilial("ZL0") + cMotor	, "ZL0_NOME"	)
   nTotKm		:= (_cAlias)->ZL3_KM
   _lRet		:= .T.
   
   u_getNwTicket(.T.)
Else
   If MsgYesNo("Esse Transportador não está vinculado a nenhuma linha! Continuar assim mesmo?","AGLT00334")
      _lRet := .T.
   EndIf
EndIf

(_cAlias)->(DBCloseArea())

FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: AGLT003B
Autor-------------: Abrahao
Data da Criacao---: 24/12/2008
Descrição---------: VerIfica se ticket existe na ZLD para o setor posicionado
Parametros--------: cpVlr - ticket a ser verIficado
Retorno-----------: cret - Se existe o ticket ou não
===============================================================================================================================
*/
Static Function AGLT003B(cpVlr As Character)

Local _lRet		:= .F. As Logical
Local _cFiltro	:= "%" As Character
Local _aArea	:= FWGetArea() As Array
Local _nT1		:= 0 As Numeric
Local _nT2		:= 0 As Numeric
Local _cAlias	:= GetNextAlias() As Character

If Empty(cpVlr)
   u_getNwTicket(.T.)
   cpVlr := cTicket
Else
   If Inclui .And. ISALPHA(cpVlr)//LEFT(cpVlr,1) = "S"
      FWAlertWarning("Ticket nao pode começar com letras, reservado para o SmartQuestion","AGLT00335")
      Return .T.//.T. BLOQUEIA
   EndIf
EndIf

If !Empty(cpVlr)
   cTicket:=cpVlr:=StrZero(Val(cpVlr),Len(ZLD->ZLD_TICKET))
   _culticket := cticket
EndIf

If !Empty(csetor)
   _cFiltro += " AND ZLD_SETOR  = '"+ cSetor +"' "
EndIf

_cFiltro +="%"

BeginSql alias _cAlias
   SELECT ZLD_QTDBOM, ZLD_TOTBOM, ZLD_DTCOLE, ZLD_DTLANC, ZLD_SETOR, ZLD_LINROT, ZLD_CODREC
   FROM %Table:ZLD% ZLD
   WHERE ZLD.D_E_L_E_T_ = ' '
   %exp:_cFiltro%
   AND ZLD_FILIAL = %xFilial:ZLD%
   AND ZLD_TICKET = %exp:cpVlr%
EndSql

While (_cAlias)->( !Eof() )

   _nT1	+= (_cAlias)->ZLD_QTDBOM
   _nT2	:= (_cAlias)->ZLD_TOTBOM
   _lRet	:= .T.
   
   (_cAlias)->( DBSkip() )
EndDo

//================================================================================
// Zera variaveis - Caso mude o num. do ticket
//================================================================================
nVolAnt		:= 0
nLeiteBom	:= 0 
nTotBom		:= 0

If _lRet
   If FWAlertYesNo("O Ticket digitado já existe! Deseja complementar os lancamentos desse Ticket?","AGLT00336")
      (_cAlias)->(DBGoTop())
      //Atualiza campos de cabeçalho e muda condição para inclusão de complemento 
       nVolAnt		:= _nT1
      nLeiteBom	:= _nT1
       nTotBom		:= _nT2
      nLtDIf		:= nTotBom - nLeiteBom   
       _lRet		:= .F.
       lAbleTicket := .F. //Flag que indica se é complemento ou não, .F. é complemento
       cCodRec     := (_cAlias)->ZLD_CODREC
       dDtcoleta   := SToD((_cAlias)->ZLD_DTCOLE)
       dData       := SToD((_cAlias)->ZLD_DTLANC)
       csetor      := (_cAlias)->ZLD_SETOR
       cDescSet    := SubStr(Posicione("ZL2",1,xFilial("ZL2")+cSetor,"ZL2_DESCRI"),1,20) 
       _culticket  := cTicket
       crotaori    := (_cAlias)->ZLD_LINROT
   Else
      lAbleTicket := .T.
      _lRet := .T. //.T. Bloqueia pois só pode usar ticket novo
   EndIf

ElseIf AllTrim(_culticket) != cticket 
   FWAlertWarning("Ticket não localizado! Utilize o campo de seleção de fretista para gerar novo numero de ticket automaticamente.","AGLT00337")
   _lRet := .T. //.T. Bloqueia pois não achou o ticket digitado e ticket precisa ser gerado automaticamente
Else
   _lRet := .F. //Mantendo mesmo valor de ticket, só enter no campo
EndIf

(_cAlias)->( DBCloseArea() )

FWRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: AGLT003A
Autor-------------: Abrahao
Data da Criacao---: 09/01/2009
Descrição---------: VerIfica se o ticket nao existe no setor apontado
Parametros--------: CCOD - Ticket
               cpsetor - Setor
Retorno-----------: retorno - Se o ticket existe no setor
===============================================================================================================================
*/
Static Function AGLT003A(cCod As Character,cpSetor As Character)

Local _lRet		:= .F. As Logical
Local _nCt		:= 0 As Numeric
Local _cAlias	:= GetNextAlias() As Character

BeginSql alias _cAlias
   SELECT ZLD_TICKET,ZLD_CODREC
   FROM %Table:ZLD% ZLD
   WHERE ZLD.D_E_L_E_T_ = ' '
   AND ZLD_TICKET = %exp:cCod%
   AND ZLD_SETOR  = %exp:cpSetor%
   GROUP BY ZLD_TICKET,ZLD_CODREC
EndSql

While (_cAlias)->( !Eof() )
   _nCt++
   (_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

If _nCt == 1
   _lRet := .T.
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: AGLT003W
Autor-------------: Abrahao
Data da Criacao---: 09/01/2009
Descrição---------: Obtem volume fisico dos ticket lancados anteriormente
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT003W(cpCodRec As Character,cpTicket As Character,cpSetor As Character)

Local _aArea	:= FWGetArea() As Array
Local _nRet		:= 0 As Numeric
Local _cAlias	:= GetNextAlias() As Character

BeginSql alias _cAlias
   SELECT SUM(ZLD_QTDBOM) QTDVOL
   FROM %Table:ZLD% ZLD
   WHERE ZLD.D_E_L_E_T_ = ' '
   AND ZLD_FILIAL = %xFilial:ZLD%
   AND ZLD_CODREC <> %exp:cpCodRec%
   AND ZLD_TICKET = %exp:cpTicket%
   AND ZLD_SETOR  = %exp:cpSetor%
EndSql

_nRet := (_cAlias)->QTDVOL

(_cAlias)->( DBCloseArea() )

FWRestArea(_aArea)

Return _nRet

/*
===============================================================================================================================
Programa----------: AGLT003Q
Autor-------------: Abrahao
Data da Criacao---: 09/01/2009
Descrição---------: VerIfica se todos produtores no aCols pertencem a linha da recepcao
Parametros--------: Nenhum
Retorno-----------: _lRet - Se produtores pertecem a linha da recepção
===============================================================================================================================
*/
Static Function AGLT003Q

Local _lRet	:= .T. As Logical
Local _nI	:= 0 As Numeric
Local _cAux	:= '' As Character

For _nI := 1 To Len( aCols )
   If !aTail( aCols[_nI] ) .And. !(Len( aCols ) == 1 .And. Empty( aCols[1][nPosRetiro] ) .And. Empty( aCols[1][nPosQtdBom] ))
      _cAux := Posicione( "SA2" , 1 , xFilial("SA2") + aCols[_nI][nPosRetiro] + aCols[_nI][nPosLoja] , "A2_L_LI_RO" )
      If _cAux != cLinRot .And. Empty( aCols[_nI][nPosAtendi] )
           _lRet := .F.  
           Exit
      EndIf
   EndIf
Next _nI

Return _lRet

/*
===============================================================================================================================
Programa----------: AGLT003R
Autor-------------: Abrahao
Data da Criacao---: 09/01/2009
Descrição---------: VerIfica se Ticket nao pode ser incluido/alterado/excluido por ja possuir lançamento de algum evento.
Parametros--------: ddatacol - Data do ticket
               ccodprod - Código de fornecedor do produtor
               cljprod - código de loja do produtor
               csetor - setor do ticket
               clinha - linha do ticket
Retorno-----------: lret - se pode sofer movimentação ou não
===============================================================================================================================
*/
Static Function AGLT003R(dDataCol As Date,cCodProd As Character,cLjProd As Character,cSetor As Character,cLinha As Character)

Local cAliasZLF	:= GetNextAlias() As Character
Local nCountRec	:= 0 As Numeric
Local lRet		   := .F. As Logical
Local aArea		   := FWGetArea() As Array

DBSelectArea('SA2')
SA2->( DBSetOrder(1) )
If SA2->( DBSeek( xFilial('SA2') + cCodProd + cLjProd ) )

   If SA2->A2_MSBLQL == '1' .Or. SA2->A2_L_ATIVO == 'N'
      lRet := .T.
      FWAlertYesNo("Cadastro do Produtor/Fretista ["+ SA2->A2_COD +"/"+ SA2->A2_LOJA +"] está Bloqueado ou Inativo no cadastro de fornecedores.","AGLT00338")
   Else
      BeginSql alias cAliasZLF
         SELECT ZLF_CODZLE
         FROM %Table:ZLF% ZLF, %Table:ZL8% ZL8
         WHERE ZLF.D_E_L_E_T_ = ' '
         AND ZL8.D_E_L_E_T_ = ' '
         AND ZLF.ZLF_FILIAL = %xFilial:ZLF%
         AND ZLF.ZLF_FILIAL = ZL8.ZL8_FILIAL
         AND ZLF.ZLF_EVENTO = ZL8.ZL8_COD
         AND ZL8.ZL8_COMPGT <> 'S'
         AND ZL8.ZL8_ADICOM <> 'S'
         AND %exp:DToS(dDataCol)% >= ZLF_DTINI
         AND %exp:DToS(dDataCol)% <= ZLF_DTFIM
         AND ZLF_A2COD  = %exp:cCodProd%
         AND ZLF_A2LOJA = %exp:cLjProd%
         AND ZLF_DTCALC >= ZLF_DTFIM
      EndSql
      
      DBSelectArea( cAliasZLF )
      (cAliasZLF)->( DBGoTop() )
      
      COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query
      (cAliasZLF)->( DBGoTop() )
      
      If nCountRec > 0
         lRet := .T.
         FWAlertYesNo("Ticket nao pode ser incluido/alterado/excluido por ja possuir lançamento de algum evento. " +;
                     "Favor contactar o responsável pelo lançamento dos eventos e pedir para excluir os eventos gerados no mix: " 	+;
                     (cAliasZLF)->ZLF_CODZLE +" para o produtor/fretista: "+ cCodProd +"/"+ cLjProd	,"AGLT00339")
      EndIf
      (cAliasZLF)->( DBCloseArea() )
   EndIf

Else
   lRet := .T.
   FWAlertYesNo("Código do Produtor/Fretista não foi encontrado no cadastro de fornecedores.","AGLT00340")
EndIf

FWRestArea(aArea)

Return lRet

/*
===============================================================================================================================
Programa----------: AGLT003Z
Autor-------------: Fabiano Dias
Data da Criacao---: 15/07/2011
Descrição---------: Funcao usada para realizar a insercao dos produtores de um determinado ticket informado pelo usuario, que
------------------: esteja no mesmo setor e linha informados no cabecalho da recepcao de leite atual e com a data de coleta
------------------: do ticket a ser pesquisa deve compreender a data de inicio e final do mes atual, esta rotina somente sera
------------------: utilizada pela filiais da unidade de Jaru.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AGLT003Z

Local _sDtInic		:= "" As Character
Local _sDtFina		:= "" As Character
Local _cAlias		:= "" As Character
Local _aAreaZLM	:= ZLM->( FWGetArea() ) As Array
Local _nPosCodig	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "ZLD_RETIRO"	} ) As Numeric
Local _nPosLoja	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "ZLD_RETILJ"	} ) As Numeric
Local _nPosNome	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "ZLD_DCRRET"	} ) As Numeric
Local _nqtdeLeit	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "ZLD_QTDBOM"	} ) As Numeric
Local _cTipTanq	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "ZLD_TQ_LT"	} ) As Numeric
Local _cAliasWT	:= aScan( aHeader , {|x| AllTrim( Upper(x[2]) ) == "ZLD_ALI_WT"	} ) As Numeric

Private _cPerg		:= "AGLT003" As Character

//================================================================================
// VerIfica campos obrigatorios para a realizacao desta rotina
//================================================================================
If Empty(cSetor) .Or. Empty(cLinRot)
   FWAlertWarning("Para realizar a execução desta rotina é necessário o preenchimento dos campos Setor e Linha situados no cabeçalho da recepção de leite.","AGLT00341")
   Return	            
EndIf

//================================================================================
// Somente serao aceitos tickets que estejam compreendidos dentro do intervalo de
// dia inicial e final do mes corrente.
//================================================================================
_sDtInic := DToS( firstDay( Date()	) )
_sDtFina := DToS( lastday( Date()	) )

If !Pergunte( _cPerg , .T. )
     Return
EndIf

_cAlias := GetNextAlias()

BeginSql alias _cAlias
   SELECT SA2.A2_COD CODIGO, SA2.A2_LOJA LOJA, SubStr(SA2.A2_NOME,1,40) NOME, SA2.A2_L_CLASS
   FROM %Table:ZLD% ZLD, %Table:SA2% SA2 
   WHERE ZLD.D_E_L_E_T_ = ' '
   AND SA2.D_E_L_E_T_ = ' '
   AND ZLD.ZLD_FILIAL =  %exp:cFilAnt%
   AND ZLD.ZLD_SETOR  =  %exp:cSetor%
   AND ZLD.ZLD_LINROT =  %exp:cLinRot%
   AND SA2.A2_L_LI_RO =  %exp:cLinRot%
   AND ZLD.ZLD_DTLANC >= %exp:_sDtInic% AND ZLD.ZLD_DTLANC <= %exp:_sDtFina%
   AND ZLD.ZLD_TICKET =  %exp:MV_PAR01%
   AND SA2.A2_COD = ZLD.ZLD_RETIRO 
   AND SA2.A2_LOJA = ZLD.ZLD_RETILJ
   ORDER BY ZLD.R_E_C_N_O_
EndSql

If (_cAlias)->(!Eof())             	

   //================================================================================
   // Seta o acols, para que nao exista a possibilidade de insercao de varias vezes 
   // os mesmos produtores
   //================================================================================
   aCols := {}

   While (_cAlias)->(!Eof())
      // Inicializa o Acols com uma linha em Branco.
      aAdd( aCols , Array( Len(aHeader) + 1 ) )
      
      // Seta a linha corrente como nao deletada.
      aCols[ Len(aCols) ][ Len(aHeader)+1 ] := .F.
      
      // Insere os dados selecionados em banco.
      aCols[ Len(aCols) ][ _nPosCodig	] := (_cAlias)->CODIGO
      aCols[ Len(aCols) ][ _nPosLoja	] := (_cAlias)->LOJA
      aCols[ Len(aCols) ][ _nPosNome	] := (_cAlias)->NOME
      aCols[ Len(aCols) ][ _nqtdeLeit	] := 0
      aCols[ Len(aCols) ][ _cTipTanq	] := IIf( (_cAlias)->A2_L_CLASS != "N" , "T" , "L" )
      aCols[ Len(aCols) ][ _cAliasWT	] := "ZLD"
   
      (_cAlias)->( DBSkip() )
   EndDo

Else
   FWAlertWarning("Não foram encontrados os produtores do ticket informado. Favor checar se os dados do ticket atual estao corretos "+;
         "e se a data de coleta do ticket informado para realizar a pesquisa esta compreendida entre a data inicial e final do mes corrente.","AGLT00342")
EndIf

(_cAlias)->(DBCloseArea())

FWRestArea(_aAreaZLM)

Return

/*
===============================================================================================================================
Programa----------: AGLT003K
Autor-------------: Fabiano Dias
Data da Criacao---: 15/07/2011
Descrição---------: Atualiza campos de volume do cabeçalho
Parametros--------: _lgat - Chamado como gatilho
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AGLT003K(_lgat As Logical)

Default _lgat := .F.

// Atualiza Variaveis de Totais
nleiteant   := nLeiteBom
nLeiteBom	:= nVolAnt + U_AGLT003S(_lgat)
nTotCodRec	:= U_AGLT003S(_lgat)
nLtDIf		:= nTotBom - nLeiteBom

If ValType(oLteBom) == 'O'
   oLteBom:Refresh()  
EndIf

If ValType(nDIf) == 'O'
   nDIf:Refresh()
EndIf

If ValType(oTotCodRec) == 'O'
   oTotCodRec:Refresh()
EndIf

If ValType(oDlg) == 'O'
   oDlg:Refresh()
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: AGLT003Mail
Autor-------------: Alex Wallauer
Data da Criacao---: 19/02/2015
Descrição---------: Cria o corpo do e-mail a ser enviado quado ococre erro no estoque do leite
Parametros--------: cGetAssun,_cCab1,_cCab2,_aLinhas,_aDadosEmail:={}
Retorno-----------: _cMsgEml
===============================================================================================================================
*/
Static Function AGLT003Mail(cGetAssun As Character,_cCab1 As Character,_cCab2 As Character,_aLinhas As Array, _aDadosEmail As Array ) As Character

Local _cMsgEml    := "" As Character
Local _cNomeFil   := cFilAnt+" - "+AllTrim( Posicione('SM0',1,"01"+cFilAnt,'M0_FILIAL') ) As Character
Local _nI         := 0 As Numeric
Local _n1         := 0 As Numeric
Local _nC         := 0 As Numeric 
Local _aCab       := {} As Array

_cMsgEml := '<html>'
_cMsgEml += '<head><title>'+cGetAssun+'</title></head>'
_cMsgEml += '<body>'
_cMsgEml += '<style Type="text/css"><!--'
_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
_cMsgEml += '--></style>'
_cMsgEml += '<center>'
_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
_cMsgEml += '<table class="bordasimples" width="600">'
_cMsgEml += '    <tr>'
_cMsgEml += '	     <td class="titulos"><center>'+cGetAssun+'</center></td>'
_cMsgEml += '	 </tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="999">'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="2" class="grupos">Dados detalhados do estorno da tranferencia e/ou do estoque </b></td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Feito por: </b></td>'
_cMsgEml += '      <td class="itens" >'+ UsrFullName(__cUserId) +'</td>' 
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Filial:</b></td>'
_cMsgEml += '      <td class="itens" >'+ _cNomeFil +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Data / Hora:</b></td>'
_cMsgEml += '      <td class="itens" >'+ DToC(DATE())+" / "+Time() +'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Lançamento de transferencia origem:</b></td>'
_cMsgEml += '      <td class="itens" >'+_aDadosEmail[1]+'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Lançamento de transferencia destino:</b></td>'
_cMsgEml += '      <td class="itens" >'+_aDadosEmail[2]+'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Status do ZLJ:</b></td>'
_cMsgEml += '      <td class="itens" >'+_aDadosEmail[3]+'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Status do ZLD:</b></td>'
_cMsgEml += '      <td class="itens" >'+_aDadosEmail[4]+'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Resultado do estorno da transferencia:</b></td>'
_cMsgEml += '      <td class="itens" >'+_aDadosEmail[5]+'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>SELECT da busca do Estoque:</b></td>'
_cMsgEml += '      <td class="itens" >'+_aDadosEmail[6]+'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Resultado do estorno do estoque:</b></td>'
_cMsgEml += '      <td class="itens" >'+_aDadosEmail[7]+'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
If FWIsInCallStack("AGLT021VL")
   _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Motivo da recusa:</b></td>'
Else
   _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Alteracao de data de estoque:</b></td>'
EndIf
_cMsgEml += '      <td class="itens" >'+_aDadosEmail[8]+'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="center" width="30%"><b>Caminho da Chamada:</b></td>'
_cMsgEml += '      <td class="itens" >'+_aDadosEmail[9]+'</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</table>'
_cMsgEml += '<br>'
_cMsgEml += '<table class="bordasimples" width="1200">'

_cMsgEml += '    <tr>'

_aCab:=StrToKarr2(_cCab1,";",.T.)

_cMsgEml += '    <tr>'
_cMsgEml += '      <td align="center" colspan="'+Str(Len(_aCab),2)+'" class="grupos">Detalhamento dos dados do SD3 antes e depois do estorno da tranferencia e/ou do estoque</b></td>'
_cMsgEml += '    </tr>'

_cSize:= Str(INT(100/Len(_aCab)),2,0)//deixa o % igual para todos os campos

_cMsgEml += '<tr>'
For _nI := 1 To Len(_aCab)
   _cMsgEml += ' <td class="itens" align="center" width="'+_cSize+'%"><b>'+_aCab[_nI]+'</b></td>'
Next _nI
_aCab:=StrToKarr2(_cCab2,";",.T.)
_cMsgEml += '</tr>'

For _n1 := 1 To Len(_aLinhas)
   _cMsgEml += '<tr>'
   If _n1 >= 5 .And. Len(_aCab) > 0
      _cMsgEml += '</tr>'
      _cMsgEml += '<tr>'
      For _nC := 1 To Len(_aCab)
            _cMsgEml += '<td class="itens" align="center" width="'+_cSize+'%"><b>'+_aCab[_nC]+'</b></td>'
      Next _nC
      _aCab    := {}//ZERA PARA NÃO POR DE NOVO O CABEC
      _cMsgEml += '</tr>'
      _cMsgEml += '<tr>'
   EndIf
   _aILinhas:=StrToKarr2(_aLinhas[_n1],";",.T.)
   For _nI := 1 To Len(_aILinhas)
      //StrTran(_cTextoLog,CRLF,"<br><br>")
      _cMsgEml += '<td class="itens" align="center" width="'+_cSize+'%">'+_aILinhas[_nI]+'</td>'
   Next _nI
   _cMsgEml += '    </tr>'
Next _n1

_cMsgEml += '</table>'
_cMsgEml += '</center>'
_cMsgEml += '<br>'
_cMsgEml += '<br>'
_cMsgEml += '    <tr>'
_cMsgEml += '      <td class="itens" align="left" ><b>Ambiente:</b></td>'
_cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [AGLT003]</td>'
_cMsgEml += '    </tr>'
_cMsgEml += '</body>'
_cMsgEml += '</html>'
 
Return _cMsgEml

/*
===============================================================================================================================
Programa--------: MostraCalls
Autor-----------: Alex Wallauer
Data da Criacao-: 21/02/2025
Descrição-------: Mostra os caminho ate o momento
Parametros------: Nenhum
Retorno---------: cPilhas
===============================================================================================================================*/
Static Function MostraCalls

Local _bType   := {|x| Type(x)} As Codeblock
Local nConta   := 1 As Numeric
Local aRet     := {} As Array
Local cPilha   := "" As Character
Local cPilhas  := "" As Character
Local cProcName:= "XX" As Character

While !Empty(cProcName) .And. nConta < 25
   cProcName:=Upper(AllTrim(ProcName(nConta)))
   cPilha:=""
   If !Empty(cProcName) .And. !cProcName $ "ACTIVATE/FWMsgRun/Processa/__EXECUTE/FWPREEXECUTE/SIGAIXB/{|SELF|(EVAL(OSELF:BINIT))}"
      aTipo:={};   aArquivo:={};   aLinha:={};   aData:={};   aHora:={}
      aRet :=GetFuncArray( ProcName(nConta),aTipo,aArquivo,aLinha,aData,aHora)       
      cPilha+=StrTran(ProcName(nConta),"  ","")
      If Eval(_bType,"aArquivo[1]") = "C" 
         cPilha+=" Fonte: ("+aArquivo[1]+")"
      EndIf
      If Eval(_bType,"aData[1]") = "D" 
         cPilha+=" "+DToC(aData[1])
      EndIf
      If Eval(_bType,"aHora[1]") = "C" 
         cPilha+=" "+aHora[1]
      EndIf
      If Eval(_bType,"aLinha[1]") = "C"
         cPilha+=" linha " +aLinha[1]
      EndIf
      cPilhas+=cPilha+=CRLF
   EndIf
   nConta++   
EndDo
cPilhas:=LEFT(cPilhas,Len(cPilhas)-2)//Tira o último enter

Return cPilhas
