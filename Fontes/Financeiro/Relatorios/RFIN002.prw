/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |26/08/2025| Chamado 47930. Ajuste para impressão do QrCode.
Igor Melgaço  |05/09/2025| Chamado 52032. Ajuste para gravação do Numbco
Igor Melgaço  |18/09/2025| Chamado 52114. Ajuste nas definições do banco do titulo
===============================================================================================================================
Analista         - Programador       - Inicio     - Envio      - Chamado - Motivo da Alteração
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Antonio Ramos    - Julio Paz         - 06/11/25   - 07/11/25   - 52540   - Ajutar rotina para enviar boleto também para o Vendedor, no envio manual de boletos.
==========================================================================================================================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FWPrintSetup.ch"
#Include "RPTDEF.CH"

Static _lCallNfe   := FWIsInCallStack("U_PrtNfeSef") As Logical
Static _cFileName  := "" As Character
Static _lEmail     := FWIsInCallStack("U_FI040EM") As Logical
Static _lWorkFlow  := FWIsInCallStack("U_MFIN025") As Logical
Static _lGerPDF  := .F. As Logical //(FWIsInCallStack("U_AFIN037") .Or. FWIsInCallStack("U_NGFBXBOL"))
Static _lScheduler := .F. As Logical

/*
===============================================================================================================================
Programa----------: RFIN002
Autor-------------: Cleiton
Data da Criacao---: 08/09/2008
Descrição---------: Rotina para impressão do Boleto Gráfico
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RFIN002()

Local _aArea      := FWGetArea() As Array
Local aMarked     := {} As Array
Local oPanel      := Nil As Object
Local oDlg1       := Nil As Object
Local oQtda       := Nil As Object
Local oValor      := Nil As Object
Local nHeight    	:= 0 As Numeric
Local nWidth     	:= 0 As Numeric
Local nOpca      	:= 0 As Numeric
Local aSize      	:= {} As Array
Local aBotoes    	:= {} As Array
Local aCoors     	:= {} As Array
Local _cExpr      := "" As Character


Private cMarkado  	:= GetMark() As Character
Private lInverte  	:= .F. As Logical
Private cCadastro 	:= "Títulos" As Character
Private bProcessa 	:= {|| xProcessa()} As CodeBlock
Private bLegenda  	:= {|| xLegenda()} As CodeBlock
Private aRotina   	:= {} As Array
Private cCodBco   	:= "" As Character
Private cCodAge   	:= "" As Character
Private cCodCta   	:= "" As Character
Private oMark			:= Nil As Object
Private oBrowse		:= Nil As Object
Private nValor  		:= 0 As Numeric
Private nQtdTit 		:= 0 As Numeric
Private Exec			:= .F. As Logical
Private cIndexName	:= '' As Character
Private cIndexKey		:= '' As Character
Private cFilter		:= '' As Character
Private cPerg			:= "RFIN002" As Character
Private _cDocumento	:= "" As Character
Private _cFilial		:= "" As Character
Private _lCliAvul		:= .F. As Logical		//Define se vai ser o cliente da nf ou vai ser outro
Private _cNomeAvul	:= "" As Character		//cliente avulso
Private _cCodAvul		:= "" As Character		//Cliente avulso
Private _lReimprime	:=.F. As Logical
Private _cEndAvul		:= "" As Character
Private _cMunAvul		:= "" As Character
Private _cCGCAvul		:= "" As Character
Private _cCepAvul		:= "" As Character
Private _cEstAvaul	:= "" As Character
Private cBitMap		:= "bradesco.bmp" As Character
Private _lBcoCorresp	:= .F. As Logical
Private _cCicsac     := "" As Character

//===================================================================================================
// Declara as variaveis padroes do sistema, para compatibilizacao na chamada da funcao FA070Tit() 
//===================================================================================================

Private oFontLbl	:= Nil As Object
Private nTotAGer	:= 0 As Numeric
Private nTotADesc	:= 0 As Numeric
Private nTotAMul	:= 0 As Numeric
Private nTotAJur	:= 0 As Numeric
Private nTotADesp	:= 0 As Numeric
Private cLoteFin	:= Space(4) As Character
Private cMarca		:= GetMark() As Character
Private cOld		:= cCadastro As Character
Private aCampos   := {} As Array
Private cLote		:= "" As Character
Private aCaixaFin	:= xCxFina() As Array
Private lF070Auto	:= .F. As Logical
Private lValidou	:= .F. As Logical
Private _cBancoP	:= "" As Character
//Private _cAgencP	:= ""
Private _cContaP	:= "" As Character
Private _cSubcoP	:= "" As Character
Private _cAgencP	:= "" As Character
Private _cOperP	:= "" As Character

//===================================================================================================
// Variaveis de restauracao do ambiente. 
//===================================================================================================

Private nRecTRB   := 0 As Numeric
Private nRecSE1   := 0 As Numeric
Private _nNumReg  := 0 As Numeric

SET DATE FORMAT TO "DD/MM/YYYY"

Define Font oFontLbl Name "Arial" Size 0,-09 Bold  // Tamanho 11

If _lWorkFlow
   _lScheduler := U_MFIN025S()
EndIf

//===================================================================================================
// Faz o calculo automatico de dimensoes de objetos     
//===================================================================================================
aSize := MSADVSIZE()
 
If Upper(AllTrim(FunName())) == "MATA460A"
   
   Pergunte(cPerg,.F.)
   
   If !RFIN002V(1)  //Carrega variáveis Private para bco/ag/cont/subconta, opção 1 para não apresentar dial se tiver mais de uma conta na filial
   
      Return
      
   EndIf

ElseIf _lCallNfe .Or. _lEmail .Or. _lWorkFlow .Or. _lGerPDF //Chamado pela D

   Pergunte(cPerg,.F.)

   MV_PAR01 := IIf(_lCallNfe,aParamDanf[3],SE1->E1_PREFIXO)  // De Prefixo
   MV_PAR02 := IIf(_lCallNfe,aParamDanf[3],SE1->E1_PREFIXO)  // Até Prefixo
   MV_PAR03 := IIf(_lCallNfe,aParamDanf[1],SE1->E1_NUM)  // Do Título
   MV_PAR04 := IIf(_lCallNfe,aParamDanf[2],SE1->E1_NUM)  // Até Título
   MV_PAR05 := "           "  // Do Bordero
   MV_PAR06 := "ZZZZZZZZZZZ"  // Até Bordero
   MV_PAR07 := Space(50)      // Texto 1 da Istrução
   MV_PAR08 := Space(50)      // Texto 1 da Istrução
   MV_PAR09 := Space(50)      // Texto 2 da Istrução
   MV_PAR10 := Space(50)      // Texto 2 da Istrução
   MV_PAR11 := Space(50)      // Texto 3 da Istrução
   MV_PAR12 := Space(50)      // Texto 3 da Istrução
   MV_PAR13 := 0              // %Desc. Antec. Ao Mes
   MV_PAR14 := 0              // Vlr TarIfa Bancaria
   MV_PAR15 := CTOD("")       // De Data Carga
   MV_PAR16 := CTOD("")       // Ate Data Carga
   MV_PAR17 := Space(50)      // Cargas
   MV_PAR18 := IIf(_lCallNfe,aParamDanf[16],MV_PAR18)  // Impressora  
   //========================= Inicializando novos Parâmetros
   MV_PAR19 := CTOD("  /  /  ")
   MV_PAR20 := CTOD("  /  /  ")
   MV_PAR21 := Space(6)
   MV_PAR22 := Space(4)
   MV_PAR23 := Space(6)
   MV_PAR24 := Space(4)

   If !RFIN002V(1)  //Carrega variáveis Private para bco/ag/cont/subconta, opção 1 para não apresentar dial se tiver mais de uma conta na filial
   
      Return
      
   EndIf

Else

   If !Pergunte(cPerg,.T.)

      Return

   EndIf
   
   //Log de utilização
   U_ITLOGACS()
   
   If !RFIN002V(2)  //Carrega variáveis Private para bco/ag/cont/subconta, opção 2 para  apresentar dial se tiver mais de uma conta na filial
   
      Return
      
   EndIf

EndIf

//===================================================================================================           
// Posiciona na tabela de configuracao de impressoras
//===================================================================================================

DBSelectArea("ZB1")
ZB1->( DBSetOrder(1) )
ZB1->( DBSeek(xFilial("ZB1")+MV_PAR18) )
If !_lScheduler
   FWMsgRun( , {|| RFIN002J() } ,'VerIficando os dados...' , 'Aguarde!' )
Else
   RFIN002J()
EndIf

DBSelectArea("TRB")
TRB->( DBGoTop() )

If TRB->(RecCount()) = 0 .And. _lCallNfe
   Return
EndIf

_aCores	:= {}
bped	:= {|| RFIN002L()}
aAdd( _aCores , {'Eval(bped)==""'	,"BR_VERDE"		} )
aAdd( _aCores , {'Eval(bped)=="1"'	,"BR_AMARELO"	} )

If !_lCallNfe .And. !_lEmail .And. !_lWorkFlow .And. !_lGerPDF

   //===================================================================================================
   // Cria a tela para selecao dos titulos.                             
   //===================================================================================================

   DEFINE MSDIALOG oDlg1 TITLE OemToAnsi("Impressao de boletos") From aSize[7],0 To aSize[6],aSize[5] OF oMainWnd PIXEL

   oPanel       := TPanel():New(0,0,'',oDlg1,, .T., .T.,, ,315,20,.T.,.T. )

   @ 0.8 ,00.8 Say OemToAnsi("Valor Total:")									OF oPanel
   @ 0.8 ,0007 Say oValor VAR nValor Picture "@E 999,999,999.99" SIZE 60,8		OF oPanel
   @ 0.8 ,0021 Say OemToAnsi("Quantidade:")									OF oPanel
   @ 0.8 ,0032 Say oQtda VAR nQtdTit Picture "@E 99999" SIZE 50,8				OF oPanel

   If FlatMode()
      aCoors	:= GetScreenRes()
      nHeight	:= aCoors[2]
      nWidth	:= aCoors[1]
   Else
      nHeight	:= 143
      nWidth	:= 315
   EndIf

   DBSelectArea("TRB")
   TRB->( DBGoTop() )

   oMark					:= MsSelect():New("TRB","E1_OK","",aCampos,@lInverte,@cMarkado,{35,1,nHeight,nWidth},,,,,_aCores)//oMark := MsSelect():New("TRB","E1_OK","E1_SALDO<=0",aCampos,@lInverte,@cMarkado,{35,1,nHeight,nWidth},,,,,)//ALTERADO POR ERICH BUTTNER DIA 19/03/13 PARA TRAZER SOMENTE TITULOS COM SALDO ACIMA DE ZERO E ACRESCENTADO A LEGENDA DOS TITULOS. CHAMADO 2898
   oMark:bMark				:= {|| RFIN002W(cMarkado,oValor,oQtda) }
   oMark:oBrowse:bAllMark	:= {|| MFIN002I(cMarkado,oValor,oQtda) }

   ACTIVATE MSDIALOG oDlg1 ON INIT (EnchoiceBar(oDlg1,{|| nOpca := 1,oDlg1:End(),Exec := .T. },{|| nOpca := 2,oDlg1:End()},,aBotoes),oPanel:Align:= CONTROL_ALIGN_TOP,oMark:oBrowse:Align:= CONTROL_ALIGN_ALLCLIENT,oMark:oBrowse:Refresh())
   
   If nOpca <> 1
      Return
   EndIf

   _cExpr := 'Marked("E1_OK")'
Else
   //Não Abre Janela de Seleção de Titulos
   MFIN002I(cMarkado,oValor,oQtda)
   Exec := .T.

   _cExpr := "TRB->E1_OK == cMarkado"
EndIf

TRB->( DBGoTop() )
While !Eof()
   If &_cExpr
      aAdd(aMarked,.T.)   
      _nNumReg++
   Else
      aAdd(aMarked,.F.)
   EndIf
   TRB->( DBSkip() )
EndDo


TRB->( DBGoTop() )

//===================================================================================================
//Seleciona Cliente Boleto
//===================================================================================================

If _lCliAvul
   Pergunte("CLIAVU",.T.)
   _cQuery := "SELECT A1_COD,A1_NOME, A1_CGC, A1_END, A1_BAIRRO, A1_MUN, A1_EST, A1_CEP,A1_ENDCOB,A1_BAIRROC,A1_CEPC,A1_ESTC, A1_MUNC, A1_CGC "+chr(13)
   _cQuery += " FROM "+RetSqlName("SA1")+chr(13)
   _cQuery += " WHERE "+chr(13)
   _cQuery += "D_E_L_E_T_ = ' ' "+chr(13)
   _cQuery += "AND A1_COD = '"+MV_PAR01+"' "+chr(13)
   
   MPSysOpenQuery( _cQuery , "AVUL")
   _aArea := FWGetArea()
   DBSelectArea("AVUL")
   
   //Formata cnpj/cpf
   _cCGC := ""
   If Len(AllTrim(AVUL->A1_CGC)) == 14
      
      _cCGC := TRANSFORM(Val(AllTrim(AVUL->A1_CGC)),"@R 99.999.999.9999/99")
         
   ElseIf Len(AllTrim(AVUL->A1_CGC)) == 11 
      
      _cCGC := TRANSFORM(Val(AllTrim(AVUL->A1_CGC)),"@R 999.999.999-99")
      
   EndIf
      
   If Empty(AllTrim(AVUL->A1_ENDCOB))
      _cNomeAvul	:= AllTrim(AVUL->A1_NOME)
      _cCodAvul	:= AVUL->A1_COD
      _cEndAvul	:= AllTrim(AVUL->A1_END)+" - "+AVUL->A1_BAIRRO
      _cMunAvul	:= AVUL->A1_MUN
      _cCGCAvul	:= AVUL->A1_CGC
      _cCepAvul	:= AVUL->A1_CEP
      _cEstAvul	:= AVUL->A1_EST
      _cCicsac    := _cCGC
      
   Else
      _cNomeAvul	:= AllTrim(AVUL->A1_NOME)
      _cCodAvul	:= AVUL->A1_COD
      _cEndAvul	:= AllTrim(AVUL->A1_ENDCOB)+" - "+AVUL->A1_BAIRROC
      _cMunAvul	:= AVUL->A1_MUNC
      _cCGCAvul	:= AVUL->A1_CGC
      _cCepAvul	:= AVUL->A1_CEPC
      _cEstAvul	:= AVUL->A1_ESTC
      _cCicsac    := _cCGC
      
   EndIf
   DBSelectArea("AVUL")
   AVUL->( DBCloseArea() )
EndIf

DBSelectArea("TRB")
If Exec
   If !_lScheduler
      FWMsgRun(,{|oproc|RFIN002M(aMarked,oproc)},"Montando dados...","Aguarde...")  //MONTA RELATORIO DOS MARCADOS
   Else
      RFIN002M(aMarked)
   EndIf
EndIf

DBSelectArea("TRB")

Return

/*
===============================================================================================================================
Programa----------: RFIN002M
Autor-------------: Renato de Morcerf
Data da Criacao---: 08/09/2008
Descrição---------: Rotina para processamento da impressão do Boleto Gráfico
Parametros--------: aMarked - titulos marcados
					oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN002M( aMarked, oproc ) As Logical

Local oPrint			:= Nil As Object
Local nX             := 0 As Numeric
Local aBitmap			:= {	"" 						,; //Banner publicitário
                        "\system\bradesco.bmp"	 } As Array  //Logo da empresa

Local aDadosEmp		:= {	SM0->M0_NOMECOM																	,; //Nome da Empresa
                           SM0->M0_ENDCOB																		,; //Endereco
                           AllTrim(SM0->M0_BAIRCOB)+", "+AllTrim(SM0->M0_CIDCOB)+", "+SM0->M0_ESTCOB  ,; //Complemento
                           "CEP: "+Subs(SM0->M0_CEPCOB,1,5)+"-"+Subs(SM0->M0_CEPCOB,6,3)					,; //CEP
                           "PABX/FAX: "+SM0->M0_TEL                                                   ,; 	//Telefones
                           "C.G.C.: "+ Transform(SM0->M0_CGC,PesqPict("SA1","A1_CGC"))						,; 	//CGC
                           "I.E.: "+ Transform(SM0->M0_INSC,"999.999.999.999") } As Array		//I.E

Local aDadosTit		:= {} As Array
Local aDadosBanco		:= {} As Array
Local aDatSacado		:= {} As Array
Local aBolText       := { MV_PAR07+MV_PAR08 , MV_PAR09+MV_PAR10 , MV_PAR11+MV_PAR12 } As Array
Local aBMP				:= aBitMap As Array
Local nI             := 0 As Numeric
Local CB_RN_NN			:= {} As Array
Local nRec				:= 0 As Numeric
Local _nVlrAbat		:= 0 As Numeric
Local _nJuros			:= 0 As Numeric
Local _cNumFaixa		:= "" As Character
Local _cMens 			:= "" As Character
Local _aBco 			:= {} As Array
Local _nOpc          := 0 As Numeric
Local _cNosNumBco    := "" As Character

Local _cAssunto      := "Boleto bancario referente a fatura" As Character
Local _aConfig       := U_ITCFGEML(' ') As Array //Configuração de e-mail a ser considerada para o envio (Tabela Z02)
Local _cLog          := "" As Character
Local _cEmail        := "" As Character
Local cFrom          := "" As Character
Local cHtml          := "" As Character
Local lRet           := .F. As Logical
Local _cEmailMod     := "" As Character
Local lOk            := .F. As Logical
Local	oDlg           := Nil As Object
Local oBtnCancel     := Nil As Object
Local oBtnOk         := Nil As Object
Local oEmail         := Nil As Object
Local aFilePrint     := {} As Array
Local aCodDig        := {} As Array
Local oJson 			:= Nil As Object
Local _cJson 			:= "" As Character
Local _cQrCodePix 	:= "" As Character
Local _cMmailVen     := "" As Character

Default oproc := nil

_cFileName := "Boleto_Laser_" + DToS(DATE()) + Time()
_cFileName := StrTran(_cFileName,":","")

If _lCallNfe

   _cPathSrv := cPathfNfe //"C:\Temp\"

   If cPrtTpNfe == "IMP_PDF"
              //FWMsPrinter():New(< cFilePrintert >, [ nDevice], [ lAdjustToLegacy], [ cPathInServer], [ lDisabeSetup ], [ lTReport], [ @oPrintSetup], [ cPrinter], [ lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] )
      oPrint := FWMsPrinter():New(_cFileName       , IMP_PDF   , .T.               ,                 , .T.             ,            ,                ,            , .F.       ,             ,        , .T.        ,             )
      oPrint:cPathPDF := _cPathSrv
   Else
              //FWMsPrinter():New(< cFilePrintert >, [ nDevice], [ lAdjustToLegacy], [ cPathInServer], [ lDisabeSetup ], [ lTReport], [ @oPrintSetup], [ cPrinter], [ lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] )
      oPrint := FWMsPrinter():New(_cFileName       , IMP_SPOOL , .T.               ,                 , .T.             ,            ,                ,  _cPathSrv , .F.       ,             ,        , .T.        ,             )
   EndIf
Else
   If !_lEmail .And. !_lWorkFlow .And. !_lGerPDF
      oPrint:= FwMSPrinter():New( _cFileName )	//INSTANCIA O OBJETO
      If !(oPrint:nModalResult == PD_OK)
         oPrint:Deactivate() 
         Return
      EndIf
   EndIf
EndIf

If !_lEmail .And. !_lWorkFlow .And. !_lGerPDF
   oPrint:SetPortrait() 							//Define pagina como Retrato
   oPrint:SetPaperSize(DMPAPER_A4)
   
   //Ajuste para impressão pos geração em excel de qualquer outro relatório do protheus 
   oPrint:nFactorHor := 4.04721754
   oPrint:nFactorVert := 3.61643836
EndIf

DBSelectArea("ZZJ")
DBSetOrder(1)
If ZZJ->(DBSeek(xFilial("ZZJ")+AllTrim(cfilant)))
   While AllTrim(ZZJ->ZZJ_FILIAL) == AllTrim(xFilial("ZZJ")) .And. AllTrim(ZZJ->ZZJ_FILACE) == AllTrim(cfilant)
      aAdd(_aBco, {ZZJ->ZZJ_BANCO,ZZJ->ZZJ_CONTA,ZZJ->ZZJ_AGENCI,ZZJ->ZZJ_SUBCON,ZZJ->ZZJ_OPER,ZZJ->ZZJ_DEFAUL})
               //      1             2               3               4                5           6
      ZZJ->( DBSkip() )
   EndDo
EndIf

TRB->( DBGoTop() )
TRB->( DBEval( {|| nRec++ }) )
TRB->( DBGoTop() )

While TRB->(!Eof())
   
   nI++ //Controle de Execucao
   
   If aMarked[nI]

      //============================================================
      //procura se o cliente tem um banco padrão
      //============================================================
      _cpadrao := Posicione("SA1", 1,xFilial("SA1") + TRB->E1_CLIENTE + TRB->E1_LOJA, "A1_I_BOLE")
   
      If Empty(AllTrim(_cpadrao))

         _cPortado  := IIf( Empty( TRB->E1_PORTADO )	    , _cBancoP , TRB->E1_PORTADO	)
         _cAgencia  := IIf( Empty( TRB->E1_AGEDEP )		, _cAgencP , TRB->E1_AGEDEP		)
         _cConta    := IIf( Empty( TRB->E1_CONTA ) 		, _cContaP , TRB->E1_CONTA      )
      
      Else
         _nOpc := aScan(_aBco,{|_vAux|_vAux[1]== SubStr(_cpadrao,1,3) })
         
         If _nOpc > 0 
         
            _cPortado :=	AllTrim(_aBco[_nOpc][1])
            _cConta   :=	AllTrim(_aBco[_nOpc][2])
            _cAgencia :=	AllTrim(_aBco[_nOpc][3])

         Else

            _cPortado  := IIf( Empty( TRB->E1_PORTADO )	    , _cBancoP , TRB->E1_PORTADO	)
            _cAgencia  := IIf( Empty( TRB->E1_AGEDEP )		, _cAgencP , TRB->E1_AGEDEP		)
            _cConta    := IIf( Empty( TRB->E1_CONTA ) 		, _cContaP , TRB->E1_CONTA      )
             
         EndIf			
      
      EndIf	


      DBSelectArea("AC8")
      DBSetOrder(2)
      If DBSeek(xFilial("AC8")+"SA1"+xFilial("SA1")+TRB->E1_CLIENTE+TRB->E1_LOJA)
         While xFilial("AC8")+"SA1"+xFilial("SA1")+TRB->E1_CLIENTE+TRB->E1_LOJA == Rtrim(AC8->(AC8_FILIAL + "SA1" + AC8_FILENT + AC8_CODENT)) .And. AC8->(!Eof())
            DBSelectArea("SU5")
            DBSetOrder(1)
            If DBSeek(AC8->(AC8_FILIAL+AC8_CODCON))
               If !(AllTrim(SU5->U5_EMAIL) $ _cEmail)
                  _cEmail += IIf(Empty(AllTrim(_cEmail)),"",";") + AllTrim(SU5->U5_EMAIL)
               EndIf
            EndIf
            AC8->(DBSkip())
         EndDo

         If Empty(AllTrim(_cEmail))
            _cEmail := TRB->A1_EMAIL
         EndIf
      Else
         _cEmail := TRB->A1_EMAIL
      EndIf

      //==============================================================
      // Incluindo o e-mail do vendedor para envio de boleto manual.     
      //==============================================================
      If _lEmail
         If ! Empty(TRB->E1_VEND1)
            _cMmailVen := Posicione("SA3",1,xFilial("SA3")+TRB->E1_VEND1,"A3_EMAIL")
            _cEmail := AllTrim(_cEmail) + ";" + AllTrim(_cMmailVen)
         EndIf 
      EndIf 

      If _lEmail .Or. _lWorkFlow .Or. _lGerPDF

         _cEmailMod := _cEmail + Space(200)
         lOk := .F.

         If _lWorkFlow .Or. _lGerPDF
            lOk := .T.
         Else

            DEFINE DIALOG oDlg TITLE OemToAnsi("Envio de Boleto por e-mail") FROM 0,0 TO 10,83
            
            @ 001  ,002 Say OemToAnsi("Emails:")									OF oDlg
            @ 01.5 ,002 Get oEmail VAR _cEmailMod Picture "@&" SIZE 300,8		OF oDlg

            @ 050,200 BUTTON oBtnOk PROMPT "&Ok"       SIZE 43,12 PIXEL ACTION ((lOk := .T.),oDlg:End()) of oDlg
            @ 050,250 BUTTON oBtnCancel PROMPT "&Cancelar" SIZE 43,12 PIXEL ACTION ((lOk := .F.),oDlg:End()) of oDlg

            ACTIVATE DIALOG oDlg CENTERED

         EndIf

         If lOk
            _cEmail := _cEmailMod

            If Empty(AllTrim(_cEmail)) .And. !_lGerPDF
               If _lWorkFlow
                  FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "RFIN00201"/*cMsgId*/, "RFIN00201 - Cliente sem e-mail cadastrado!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
               Else
                  U_ITMsg("Cliente sem e-mail cadastrado!","Atenção",,1)
               EndIf

               Return
            EndIf
         Else
            Return
         EndIf
      EndIf

      DBSelectArea("ZZJ")
      DBSetOrder(1)
      If DBSeek(xFilial("ZZJ")+AllTrim(cfilant)+U_ITKEY(_cPortado, "A6_COD")+U_ITKEY(_cAgencia, "A6_AGENCIA")+U_ITKEY(_cConta, "A6_NUMCON"))
         _cSubConta := ZZJ->ZZJ_SUBCON	
      Else
         If _lScheduler
            FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "RFIN00202"/*cMsgId*/, "RFIN00202 - Banco : "+ _cPortado +" Agencia : "+ _cAgencia +" Conta : "+ _cConta +" não encontrado. VerIfique o cadastro de banco informado como padrão."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
         Else
            U_ITMsg("Banco : "+ _cPortado +" Agencia : "+ _cAgencia +" Conta : "+ _cConta +" não encontrado. VerIfique o cadastro de banco informado como padrão.","Atenção",,1)
         EndIf
         Return
      EndIf
      
      //Posiciona o SA6 (Bancos)
      DBSelectArea("SA6")
      SA6->( DBSetOrder(1) )
      If !SA6->( DBSeek(xFilial("SA6")+U_ITKEY(_cPortado, "A6_COD")+U_ITKEY(_cAgencia, "A6_AGENCIA")+U_ITKEY(_cConta, "A6_NUMCON")) )
         If _lScheduler
            FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "RFIN00203"/*cMsgId*/, "RFIN00203 - Banco : "+ _cPortado +" Agencia : "+ _cAgencia +" Conta : "+ _cConta +" não encontrado. VerIfique o cadastro do banco."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
         Else
            U_ITMsg("Banco : "+ _cPortado +" Agencia : "+ _cAgencia +" Conta : "+ _cConta +" não encontrado. VerIfique o cadastro do banco.","Atenção",,1)
         EndIf
         Return
      EndIf
      
      //Posiciona o SA1 (Cliente)
      DBSelectArea("SA1")
      SA1->( DBSetOrder(1) )
      SA1->( DBSeek(xFilial("SA1")+TRB->E1_CLIENTE+TRB->E1_LOJA) )
      
      //Posiciona o SEE (Parametros banco)
      DBSelectArea("SEE")
      SEE->( DBSetOrder(1) )
      If !SEE->( DBSeek(xFilial("SA6");
              +U_ITKEY(_cPortado, "A6_COD");
              +U_ITKEY(_cAgencia, "A6_AGENCIA");
              +U_ITKEY(_cConta, "A6_NUMCON");
              +AllTrim(_cSubConta)) )
         
         If _lScheduler
            FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "RFIN00204"/*cMsgId*/, "RFIN00204 - Banco : "+ _cPortado +" Agencia : "+ _cAgencia +" Conta : "+ _cConta +" Subconta : "+ _cSubcoP +" não encontrado. VerIfique os parâmetros informados."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
         Else
            U_ITMsg("Banco : "+ _cPortado +" Agencia : "+ _cAgencia +" Conta : "+ _cConta +" Subconta : "+ _cSubcoP +" não encontrado. VerIfique os parâmetros informados.","Atenção",,1)
         EndIf

         Return
   
      Else   
         
         _cNumFaixa := TRB->E1_NUMBCO
                  
         DBSelectArea("TRB")
         If !Empty(AllTrim(TRB->E1_NUMBCO)) .And. aMarked[nI] 
      
            _lReimprime := .T.
      
         ElseIf Empty(AllTrim(TRB->E1_NUMBCO)) .And. aMarked[nI] 
         
            //Se tem incosistência entre campos de idcnab e nosso numero e parâmetro
            // de bloqueio estiver ativo vai impedir a geração do boleto
            If !Empty(AllTrim(TRB->E1_IDCNAB)) .Or. !Empty(AllTrim(TRB->E1_I_NUMBC))
            
               If U_ITGETMV("ITBLCNAB",.F.)
                  
                  If _lScheduler
                     FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "RFIN00205"/*cMsgId*/, "RFIN00205 - Título " + AllTrim(TRB->E1_NUM)+"/"+AllTrim(TRB->E1_PARCELA) + " apresenta inconsistência!","Atenção","Acesse tela de bloqueio cnab para ajustar título"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
                  Else
                     U_ITMsg("Título " + AllTrim(TRB->E1_NUM)+"/"+AllTrim(TRB->E1_PARCELA) + " apresenta inconsistência!","Atenção","Acesse tela de bloqueio cnab para ajustar título",1)
                  EndIf

                  Return
                              
               EndIf
               
            EndIf
         
         EndIf
         
         If !_lReimprime //SE OPCAO REIMPRESSAO For VERDADEIRA SERA MONTADO O BOLETO SEM GERAR UM NOVO NUMERO		                			
         
         
            //===================================================================================================
            //Codigo abaixo para que nao gere dois boletos com o mesmo numero.              
            //===================================================================================================
            Begin Transaction  
                     
               _cNumFaixa := StrZero(Val(SEE->EE_FAXATU) + 1,10)		       
                     
               While !MayIUseCode(_cPortado + _cAgencia + _cConta + xFilial("SEE") + _cNumFaixa)	//verIfica se esta sendo usado na memoria
                  _cNumFaixa := StrZero(Val(_cNumFaixa) + 1,10)							  		//busca o proximo numero disponivel 						
               EndDo  
               
               DBSelectArea("SEE")
               SEE->( RecLock( "SEE" , .F. ) )
                  SEE->EE_FAXATU := _cNumFaixa
               SEE->( MSUnLock() )
            
            End Transaction
            
         Else
         
            //===================================================================================================
            //VerIfica se não está mudando o banco do último banco usado para imprimir boleto
            //===================================================================================================
            If !Empty(AllTrim(TRB->E1_I_ULBCO)) .and.;
                  !Empty(AllTrim(TRB->E1_I_ULCTA)) .and.;
                  !Empty(AllTrim(TRB->E1_I_ULAGE)) .and.;
                  !Empty(AllTrim(TRB->E1_I_ULSUB)) 
         
            
               If !(	AllTrim(TRB->E1_I_ULBCO) == AllTrim(_cPortado) .and.;
                     AllTrim(TRB->E1_I_ULCTA) == AllTrim(_cconta) .and.;
                     AllTrim(TRB->E1_I_ULAGE) == AllTrim(_cAgencia) .and.;
                     AllTrim(TRB->E1_I_ULSUB) == AllTrim(_cSubConta))
                     
                     _cMens := "Não é possível reimprimir boleto com banco/ag/conta/subcon dIferentes de "
                     _cMens += AllTrim(_cPortado) + "/" + AllTrim(_cAgencia) + "/" + AllTrim(_cconta) + "/" + AllTrim(_cSubcoP) + "!"
                  
                     If _lScheduler
                        FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "RFIN00206"/*cMsgId*/, "RFIN00206 - "+_cMens/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
                     Else
                        U_ITMsg(_cMens,"Alerta",,1)
                     EndIf

                     Return
                  
               EndIf
      
            EndIf
            
         EndIf 
      
      EndIf
   
      _cDocumento	:= TRB->E1_NUM		//NUMERO DA NF
      _cFilial	:= xFilial("TRB")	//PEGA FILAL DA NF
      _cPrefixo	:= TRB->E1_PREFIXO
      
      DBSelectArea("TRB")
      aDadosBanco  := {	SA6->A6_COD																											,; 	//Numero do Banco
                     Left( SA6->A6_NOME , AT("-",SA6->A6_NOME)-1 )																		,; 	//Nome do Banco
                     IIf( SA6->A6_COD=="479" , StrZero(Val(AllTrim(SEE->EE_AGBOSTO)),7),u_agencia(SA6->A6_COD,SA6->A6_AGENCIA))			,; 	//Agência
                     IIf( SA6->A6_COD=="479" , AllTrim(SEE->EE_CODEMP), u_conta(SA6->A6_COD,SA6->A6_NUMCON) )							,; 	//Conta Corrente
                     IIf( SA6->A6_COD $ "479/033" , "" ,SubStr( AllTrim(SA6->A6_NUMCON) ,Len(AllTrim(SA6->A6_NUMCON)) , 1 ) )	,; 	//Dígito da conta corrente
                     AllTrim(SEE->EE_I_CARTE)																					,; 	//Carteira
                     0																											 } 	//VARIACAO //AllTrim(SEE->EE_VARIACA)}
      
      //Formata cnpj/cpf
      _cCGC := ""
      If Len(AllTrim(SA1->A1_CGC)) == 14
      
         _cCGC := TRANSFORM(AllTrim(SA1->A1_CGC),"@R! NN.NNN.NNN/NNNN-99")
         
      ElseIf Len(AllTrim(SA1->A1_CGC)) == 11 
      
         _cCGC := TRANSFORM(Val(AllTrim(SA1->A1_CGC)),"@R 999,999,999-99")
      
      EndIf
      
      aDatSacado   := {	AllTrim( SA1->A1_NOME )						,; //Razão Social
                     AllTrim( SA1->A1_COD )						,; //Código
                     AllTrim( SA1->A1_END )+"-"+SA1->A1_BAIRRO	,; //Endereço
                     AllTrim( SA1->A1_MUN )						,; //Cidade
                     SA1->A1_EST									,; //Estado
                     SA1->A1_CEP									,; //CEP
                     _cCGC  										 } //CPF/CNPJ
      
      //VALOR DOS TITULOS TIPO "AB-"
      _nVlrAbat   := SomaAbat( TRB->E1_PREFIXO , TRB->E1_NUM , TRB->E1_PARCELA , "R" , 1 ,, TRB->E1_CLIENTE , TRB->E1_LOJA )
      
      If _lReimprime   //SE OPCAO REIMPRESSAO For VERDADEIRA SERA MONTADO O BOLETO SEM GERAR UM NOVO NUMERO

         If SA6->A6_COD="001"
            _cNosNumBco := Subs(TRB->E1_NUMBCO,7,5)
         ElseIf SA6->A6_COD="033"
            _cNosNumBco := _cNumFaixa
         ElseIf SA6->A6_COD="341"
            If !(AllTrim(aDadosBanco[6]) $ "126,131,146,150,168")
               _cNosNumBco := Subs(TRB->E1_NUMBCO,4,8)
            Else
               _cNosNumBco := Subs(TRB->E1_NUMBCO,4,6)
            EndIf
         Else
            _cNosNumBco := Subs(TRB->E1_NUMBCO,5,8)
         EndIf

         CB_RN_NN    := u_Ret_cBarra(Subs(aDadosBanco[1],1,3)+"9",;
                                 Subs(aDadosBanco[3],1,4),;
                                 aDadosBanco[4],;
                                 aDadosBanco[5],;
                                 aDadosBanco[6],;
                                 AllTrim(E1_NUM)+AllTrim(E1_PARCELA),;
                                 (E1_SALDO-_nVlrAbat),;
                                 TRB->E1_VENCTO,;
                                 SEE->EE_CODEMP,;
                                 _cNosNumBco,; //If(SA6->A6_COD="001",Subs(TRB->E1_NUMBCO,7,5),IIf(SA6->A6_COD="033",_cNumFaixa,IIf(SA6->A6_COD="341",Subs(TRB->E1_NUMBCO,4,8),Subs(TRB->E1_NUMBCO,5,8)))),;
                                 IIf(TRB->E1_DECRESC > 0,.T.,.F.),;
                                 TRB->E1_PARCELA)
      Else
         CB_RN_NN    := u_Ret_cBarra(Subs(aDadosBanco[1],1,3)+"9",;
                                 Subs(aDadosBanco[3],1,4),;
                                 aDadosBanco[4],;
                                 aDadosBanco[5],;                                                     
                                 aDadosBanco[6],;
                                 AllTrim(E1_NUM)+AllTrim(E1_PARCELA),;
                                 (E1_SALDO-_nVlrAbat),;
                                 TRB->E1_VENCTO,;
                                 SEE->EE_CODEMP,;
                                 _cNumFaixa,;
                                 IIf(TRB->E1_DECRESC > 0,.T.,.F.),;
                                 TRB->E1_PARCELA)
      EndIf
      
      _nJuros := GetNewPar("MV_A_TXJUR",0.003)

      oJson := Nil
      _cJson := ""
      _cQrCodePix := ""
      _cJson := AllTrim(TRB->EA_APIMSG)

      If !Empty(_cJson)
         FWJsonDeserialize(_cJson, @oJson)
         If AttIsMemberOf(oJson:response, "QrCode")
            If AttIsMemberOf(oJson:response:QrCode, "emv")
               _cQrCodePix := oJson:response:QrCode:emv
            EndIf
         EndIf
      EndIf
      
      aDadosTit	:= {	IIf(AllTrim(TRB->E1_PARCELA)<>'',AllTrim(TRB->E1_NUM)+"-"+AllTrim(TRB->E1_PARCELA),AllTrim(TRB->E1_NUM))	,; //1-Número do título
                     TRB->E1_EMISSAO																								,; //2-Data da emissão do título
                     Date()																										,; //3-Data da emissão do boleto
                     TRB->E1_VENCTO																								,; //4-Data do vencimento
                     (TRB->E1_SALDO - _nVlrAbat)																					,; //5-Valor do título
                     AllTrim(CB_RN_NN[3])																						,; //6-Nosso número (Ver fórmula para calculo)
                     TRB->E1_DESCFIN																								,; // 7-VAlor do Desconto do titulo
                     (TRB->E1_SALDO - _nVlrAbat)*_nJuros																			,; // 8-Valor dos juros do titulo
                     MV_PAR14																									,; // 9-Valor Acrescimo
                     IIf( Empty(AllTrim(TRB->E1_NUMBOR)), " ", "Num. Borderô : "+TRB->E1_NUMBOR )								,; // 10-Número do borderô
                     TRB->E1_I_DESCO																								,; // 11-Valor desconto contratual
                     _cQrCodePix                                                                                                   } //12-QR Code para pagamento via Pix
      //MONTAGEM DO BOLETO
      If aMarked[nI]
         If _lEmail .Or. _lWorkFlow .Or. _lGerPDF

            cNomeCli := AllTrim(Posicione("SA1",1,xFilial("SA1")+TRB->E1_CLIENTE+TRB->E1_LOJA,"A1_NOME")) 

            _cFileName := AjustaPath("Boleto_" + AllTrim(TRB->E1_FILIAL) + "_" + AllTrim(TRB->E1_PREFIXO) + "_" + AllTrim(TRB->E1_NUM)+ "_"  + AllTrim(TRB->E1_PARCELA) + "_"+AllTrim(SA1->A1_CGC)+ "_"+ StrTran(DToS(DATE()) + "_" + TIME(),":","") )
            
            _cPathSrv := AjustaPath("\SPOOL\") //AjustaPath("C:\Temp\")  //"\data\Igor\" //"\data\Italac\docs\"

                  //FWMsPrinter():New (< cFilePrintert >     , [ nDevice], [ lAdjustToLegacy], [ cPathInServer], [ lDisabeSetup ], [ lTReport], [ @oPrintSetup], [ cPrinter], [ lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] )
            oPrint  := FWMsPrinter():New(_cFileName, IMP_PDF   , .T.       , _cPathSrv         , .T.             ,                 ,            ,                , .T. )
            oPrint:SetPortrait() 							//Define pagina como Retrato
            oPrint:SetPaperSize(DMPAPER_A4)
            oPrint:SetViewPDF(.F.)
            oPrint:cPathPDF := _cPathSrv
            
            //Ajuste para impressão pos geração em excel de qualquer outro relatório do protheus 
            oPrint:nFactorHor := 4.04721754
            oPrint:nFactorVert := 3.61643836
         EndIf

         RFIN002I(oPrint,aBMP,aDadosEmp,aDadosTit,aDadosBanco,aDatSacado,aBolText,CB_RN_NN)
         nX++
         If !_lReimprime   //SE OPCAO REIPRESSAO For VERDADEIRA SERA MONTADO O BOLETO SEM GERAR UM NOVO NUMERO
            
            Begin Transaction
      
               DBSelectArea("SE1")
               SE1->( DBSetOrder(1) )
               SE1->( DBSeek(TRB->E1_FILIAL+TRB->E1_PREFIXO+TRB->E1_NUM+TRB->E1_PARCELA+TRB->E1_TIPO) )
               SE1->( RecLock( "SE1" , .F. ) )
      
                  //SE1->E1_NUMBCO	:= StrTran(StrTran(CB_RN_NN[3],"/",""),"-","")	//GRAVA NOSSO NUMERO NO TITULO
                  SE1->E1_NUMBCO	   := StrTran(StrTran(CB_RN_NN[4],"/",""),"-","")	//GRAVA NOSSO NUMERO NO TITULO
                  SE1->E1_I_NUMBC   := SE1->E1_NUMBCO                            //Backup do nosso numero
                  SE1->E1_DESCFIN	:= MV_PAR13                                  //GRAVA o % desconto de antecipacao ao mes
                  SE1->E1_TIPODES	:= '2'                                       //Grava valor 2 para desconto proporcional
                  SE1->E1_I_ULBCO	:= AllTrim(_cBancoP)                         //Grava ultimo banco usado para boleto
                  SE1->E1_I_ULCTA	:= AllTrim(_cContaP)									//Grava ultima conta usada para boleto
                  SE1->E1_I_ULAGE	:= AllTrim(_cAgencP)									//Grava ultima agencia usada para boleto
                  SE1->E1_I_ULSUB	:= AllTrim(_cSubcoP)									//Grava ultima subconta usada para boleto
      
               SE1->( MSUnLock() )
               
            End Transaction
         
         EndIf
         
         If _lEmail .Or. _lWorkFlow .Or. _lGerPDF
 
            oPrint:EndPage()     // Finaliza a página
            cFilePrint := _cPathSrv + _cFileName + ".PDF" //"C:\Temp\Boleto "+DToS(Date())+TIME()+".PD_"

            oPrint:lViewPDF := .F. 
            oPrint:Preview() 

            If _lEmail .Or. _lGerPDF
               _cAssunto	:= "Boleto bancario referente a fatura "+ AllTrim(TRB->E1_NUM) + IIf(Empty(AllTrim(TRB->E1_PARCELA)),""," Parcela "+AllTrim(TRB->E1_PARCELA))
            ElseIf _lWorkFlow
               _cAssunto	:= "Boleto bancario referente a fatura "+ AllTrim(TRB->E1_NUM)
            EndIf

            aAdd(aFilePrint,cFilePrint)
            aAdd(aCodDig,{TRB->E1_NUM,TRB->E1_PARCELA,DToC(aDadosTit[4]),AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99")),CB_RN_NN[2]})

         EndIf
      EndIf
      
   EndIf
   
   _lReimprime := .F.
   

   If ValType(oproc) = "O"

      oproc:cCaption := ("Processando registro ["+ StrZero(nI,6) +"] de ["+ StrZero(_nNumReg,6) +"]...")
      ProcessMessages()

   EndIf
   
   
   TRB->( DBSkip() )
EndDo


If (_lEmail .Or. _lWorkFlow) .And. ! _lGerPDF 

   cHtml := 'Prezado Cliente,'
   cHtml += '<br><br>'
   cHtml += '&nbsp;&nbsp;&nbsp;'+SA1->A1_NOME+'.'
   cHtml += '&nbsp;&nbsp;&nbsp;CNPJ '+TRANSFORM(AllTrim(SA1->A1_CGC),"@R! NN.NNN.NNN/NNNN-99")+'.'
   cHtml += '<br><br>'
   cHtml += '&nbsp;&nbsp;&nbsp;Segue em anexo o(s) boleto(s) solicitado(s).'
   cHtml += '<br><br>'

   For nI := 1 To Len(aCodDig)
      cHtml += '<br><br>'
      cHtml += '&nbsp;&nbsp;&nbsp;Titulo:'+aCodDig[nI,1]+IIf(Empty(AllTrim(aCodDig[nI,2])),'', '  - Parcela: '+ aCodDig[nI,2])+' - Vencimento: '+ aCodDig[nI,3]+' - Valor: '+ aCodDig[nI,4]
      cHtml += '<br><br>'
      cHtml += '&nbsp;&nbsp;&nbsp; Linha Digitavel: '
      cHtml += '<br><br>'
      cHtml += '&nbsp;&nbsp;&nbsp; '+aCodDig[nI,5]
      cHtml += '<br><br>'
   Next

   cHtml += '<br><br>'
   cHtml += '&nbsp;&nbsp;&nbsp;Para prevenção a fraudes, antes de efetuar o pagamento confira o CNPJ e os Dados do Fornecedor.'
   cHtml += '<br><br>'
   cHtml += '&nbsp;&nbsp;&nbsp;Por favor não responda a este email.'
   cHtml += '<br><br>'

   cHtml += '<br><br>'
   cHtml += '&nbsp;&nbsp;&nbsp;A disposição!'
   cHtml += '<br><br>'
   cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
   cHtml += '<tr>'
   cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">'
   cHtml +=         '<p class=MsoNormal align=center style="text-align:center">'
   cHtml +=             '<b><span style="font-size:18.0pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serIf'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">'+ "Contas a receber" +'</span></b>'
   cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serIf'+"'"+';mso-fareast-language:PT-BR"></span></p>
   cHtml +=     '</td>'
   cHtml +=     '<td style="background:#A2CFF0;padding:.75pt .75pt .75pt .75pt">&nbsp;</td>'
   cHtml +=     '<td style="padding:.75pt .75pt .75pt .75pt">
   cHtml +=         '<table class=MsoNormalTable border=0 cellpadding=0>'
   cHtml +=              '<tr>'
   cHtml +=                  '<td style="padding:.75pt .75pt .75pt .75pt">'
   cHtml +=                      '<p class=MsoNormal><b><span style="font-size:13.5pt;font-family:'+"'"+'Arial'+"'"+','+"'"+'sans-serIf'+"'"+';color:#6FB4E3;mso-fareast-language:PT-BR">' + "Depto Financeiro" + '</span></b>'
   cHtml +=                      '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serIf'+"'"+';mso-fareast-language:PT-BR"></span></b>
   cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serIf'+"'"+';mso-fareast-language:PT-BR"><br></span>
   cHtml +=                      '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serIf'+"'"+';mso-fareast-language:PT-BR"></span></p>
   cHtml +=                  '</td>'
   cHtml +=              '</tr>'
   cHtml +=         '</table>'
   cHtml +=     '</td>'
   cHtml += '</tr>'
   cHtml += '</table>'
   cHtml += '<table class=MsoNormalTable border=0 cellpadding=0 width=437 style="width:327.75pt">'
   cHtml +=     '<tr>'
   cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
   cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
   cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serIf'+"'"+';mso-fareast-language:PT-BR">'
   cHtml +=                 '<img width=400 height=51 src="http://www.italac.com.br/assinatura-italac/images/marcas-goiasminas-industria-de-laticinios-ltda.jpg">'
   cHtml +=             '</span>
   cHtml +=             '</p>'
   cHtml +=         '</td>'
   cHtml +=     '</tr>'
   cHtml += '</table>'
   cHtml += '<p class=MsoNormal><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serIf'+"'"+';display:none;mso-fareast-language:PT-BR">&nbsp;</span></p>'
   cHtml += '<table class=MsoNormalTable border=0 cellpadding=0>'
   cHtml +=     '<tr>'
   cHtml +=         '<td style="padding:.75pt .75pt .75pt .75pt">'
   cHtml +=             '<p class=MsoNormal align=center style="text-align:center">'
   cHtml +=             '<b><span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serIf'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">Política de Privacidade </span></b>'
   cHtml +=             '<span style="font-size:12.0pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serIf'+"'"+';mso-fareast-language:PT-BR"></span></p>
   cHtml +=             '<p class=MsoNormal style="mso-margin-top-alt:auto;mso-margin-bottom-alt:auto;text-align:justIfy">'
   cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serIf'+"'"+';color:#1D2668;mso-fareast-language:PT-BR">
   cHtml +=                 'Esta mensagem é destinada exclusivamente para fins profissionais, para a(s) pessoa(s) a quem For dirigida, podendo conter informação confidencial e legalmente privilegiada. '
   cHtml +=                 'Ao recebê-la, se você não For destinatário desta mensagem, fica automaticamente notIficado de abster-se a divulgar, copiar, distribuir, examinar ou, de qualquer forma, utilizar '
   cHtml +=                 'sua informação, por configurar ato ilegal. Caso você tenha recebido esta mensagem indevidamente, solicitamos que nos retorne este e-mail, promovendo, concomitantemente sua '
   cHtml +=                 'eliminação de sua base de dados, registros ou qualquer outro sistema de controle. Fica desprovida de eficácia e validade a mensagem que contiver vínculos obrigacionais, expedida '
   cHtml +=                 'por quem não detenha poderes de representação, bem como não esteja legalmente habilitado para utilizar o referido endereço eletrônico, configurando falta grave conforme nossa '
   cHtml +=                 'política de privacidade corporativa. As informações nela contidas são de propriedade da Italac, podendo ser divulgadas apenas a quem de direito e devidamente reconhecido pela empresa.'
   cHtml += '<BR>Ambiente: ['+ GETENVSERVER() +'] / Fonte: [RFIN002] </BR>'
   cHtml +=             '</span>'
   cHtml +=             '<span style="font-size:7.5pt;font-family:'+"'"+'Times New Roman'+"'"+','+"'"+'serIf'+"'"+';mso-fareast-language:PT-BR"></span></p>'
   cHtml +=         '</td>'
   cHtml +=     '</tr>
   cHtml += '</table>'

   cTo    := _cEmail 
   cGetCco := "" //cEmailVend

   cFrom := U_ITGETMV("ITRFIN2EM",'cobranca@italac.com.br') 
   cGetCco := U_ITGETMV("ITRFIN2CO","") 

   cFilePrint := ""

   For nI := 1 To Len(aFilePrint)
      cFilePrint += IIf(Empty(AllTrim(cFilePrint)),"",";") + aFilePrint[nI]
   Next
   
   U_ITENVMAIL( cFrom , cTo ,  ,cGetCco  , _cAssunto , cHtml , cFilePrint , _aConfig[01] , _aConfig[02] , _aConfig[03] , _aConfig[04] , _aConfig[05] , _aConfig[06] , _aConfig[07] , @_cLog ) 
   lRet :=  ("Sucesso" $ _cLog)
   If _lScheduler
      FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "RFIN00207"/*cMsgId*/, "RFIN00207 - "+IIf(lRet,"Email enviado com sucesso para "+cTo+"!","Falha no Envio do email: "+_cLog)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   Else
      U_ItMsg(IIf(lRet,"Email enviado com sucesso para "+cTo+"!","Falha no Envio do email: "+_cLog),"Atenção",,IIf(lRet,2,1))
   EndIf

   For nI := 1 To Len(aFilePrint)
      cFilePrint := aFilePrint[nI]
      If File(cFilePrint)
         fErase(cFilePrint)
      EndIf
   Next

EndIf

//FIM DA PARTE QUE GERA O NUMERO DO BORDERO

If !_lEmail .And. !_lWorkFlow .And. !_lGerPDF 
   oPrint:EndPage()     // Finaliza a página
   If !_lCallNfe
      oPrint:Preview()     // Visualiza antes de imprimir
   Else
      cFilePrint := cPathfNfe + _cFileName + ".PD_" //"C:\Temp\Boleto "+DToS(Date())+TIME()+".PD_"
      If cPrtTpNfe == "IMP_PDF" 
         File2Printer(cFilePrint,"PDF")
         oPrint:Preview()
      Else
         oPrint:Print()
      EndIf
   EndIf
EndIf

Return 

/*
===============================================================================================================================
Programa----------: RFIN002I
Autor-------------: Renato de Morcerf
Data da Criacao---: 08/09/2008
Descrição---------: Rotina para processamento da impressão do corpo do Boleto Gráfico
Parametros--------: oPrint
                    aBitmap
                    aDadosEmp
                    aDadosTit
                    aDadosBanco
                    aDatSacado
                    aBolText
                    CB_RN_NN
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN002I(oPrint As Object, aBitmap As Array, aDadosEmp As Array, aDadosTit As Array, aDadosBanco As Array, aDatSacado As Array, aBolText As Array, CB_RN_NN As Array)
Local oFont08     := TFont():New("Arial",,08,.T.,.F., ,.T., ,.T.,.F.) As Object
Local oFont08N    := TFont():New("Arial",,08,.T.,.T., ,.T., ,.T.,.T.) As Object
Local oFont10     := TFont():New("Arial",,10,.T.,.T., ,.T., ,.T.,.F.) As Object
Local oFont12     := TFont():New("Arial",,12,.T.,.T., ,.T., ,.T.,.F.) As Object
Local oFont14n    := TFont():New("Arial",,14,.T.,.F., ,.T., ,.T.,.F.) As Object
Local oFont20     := TFont():New("Arial",,20,.T.,.T., ,.T., ,.T.,.F.) As Object
Local oFont30     := TFont():New("Arial",,24,.T.,.T., ,.T., ,.T.,.F.) As Object
Local nI          := 0 As Numeric
Local nLinIni     := 0 As Numeric
Local nFator      := 0 As Numeric
Local aTxtPad     := {} As Array
Local i           := 0 As Numeric
Local _cPathImg   := GetSrvProfString("Startpath","") As Character
Local _cFileImg   := "" As Character
Local _nDescLin   := 2 As Numeric
Local nAjust      := 0 As Numeric
Local nAjuBarPix  := 0 As Numeric

_cFileImg := _cPathImg + "logoboleto.BMP"

oPrint:StartPage() //Inicia uma nova página

nLinIni	:= 001

//===================================================================================================
//-- Desenha o QRCODE para o PIX --//
//===================================================================================================

   nAjuBarPix := 50 
   If File( _cFileImg )
      oPrint:SayBitmap( 030+nAjuBarPix , 130 , _cFileImg ,  340 , 140 )
   EndIf

If !Empty(AllTrim(aDadosTit[12]))
   //Cria o objeto FwQrCode
   oPrint:QRCode(280+nAjuBarPix,2000,aDadosTit[12],80)

   oPrint:Say(  84 +nAjuBarPix, 1100 , "PAGUE AGORA COM PIX" , oFont30 )
   oPrint:Say( 130 +nAjuBarPix, 1100 , "Para pagar, basta pegar o smartphone, acessar o aplicativo" , oFont10 )
   oPrint:Say( 160 +nAjuBarPix, 1100 , "onde esta o seu PIX ativo, acione a opção de pagamento e"   , oFont10 )
   oPrint:Say( 190 +nAjuBarPix, 1100 , "aponte a camera do aparelho para realizar a transação."     , oFont10 )

   
EndIf

nAjust := 270

//===================================================================================================
//-- Desenha a Caixa Superior do Boleto --//
//===================================================================================================
If aDadosBanco[1] == "389"
   oPrint:Say( 84 , 100 , aDadosBanco[2] , oFont10 )
ElseIf aDadosBanco[1] == "237"
   oPrint:SayBitMap(44,100,aBitMap[2],200,100)
Else
   oPrint:Say( 84 , 100 , aDadosBanco[2] , oFont12 )
EndIf

//===================================================================================================
//-- Linhas Horizontais - De cima para baixo --//
//===================================================================================================
nLinIni += 110 + nAjust
oPrint:Line(nLinIni,0100,nLinIni,2300)
nLinIni += 80 //190
oPrint:Line(nLinIni,0100,nLinIni,1300)
nLinIni += 80 //270
oPrint:Line(nLinIni,0100,nLinIni,1300)
nLinIni += 60 //330
oPrint:Line(nLinIni-1,0100,nLinIni-1,2300)
nLinIni += 60 //380
oPrint:Line(nLinIni,0100,nLinIni,2300)
//===================================================================================================
//-- Linhas Verticais - Da esquerda para a direita--//
//===================================================================================================
oPrint:Line(0270+nAjust,0400,0330+nAjust,0400)
oPrint:Line(0330+nAjust,0500,0390+nAjust,0500)
oPrint:Line(0270+nAjust,0625,0330+nAjust,0625)
oPrint:Line(0270+nAjust,0750,0330+nAjust,0750)
oPrint:Line(0270+nAjust,0980,0330+nAjust,0980)
oPrint:Line(0110+nAjust,1300,0390+nAjust,1300)
oPrint:Line(0330+nAjust,1700,0390+nAjust,1700)
oPrint:Line(0330+nAjust,1900,0390+nAjust,1900)
oPrint:Line(0110+nAjust,2300,0390+nAjust,2300)


oPrint:Say( 80 +nAjust, 1850 , "Comprovante de Entrega" 																, oFont10 )
oPrint:Say( 420 - _nDescLin +nAjust, 0100 , "Codigo Baixa"																			, oFont08 )
oPrint:Say( 420 - _nDescLin +nAjust, 0350 , aDadosTit[1]	  	  																	, oFont08 )
oPrint:Say( 420 - _nDescLin +nAjust, 0995 , aDadosTit[10]	  	  																	, oFont08 )

oPrint:Say( 130 - _nDescLin +nAjust, 1310 , "MOTIVOS DE NÃO ENTREGA (para uso do entregador)"										, oFont08 )
oPrint:Say( 180 - _nDescLin +nAjust, 1310 , "|   | Mudou-se"																		, oFont08 )
oPrint:Say( 230 - _nDescLin +nAjust, 1310 , "|   | Recusado"																		, oFont08 )
oPrint:Say( 280 - _nDescLin +nAjust, 1310 , "|   | Desconhecido"																	, oFont08 )

oPrint:Say( 180 - _nDescLin +nAjust, 1580 , "|   | Ausente"																		, oFont08 )
oPrint:Say( 230 - _nDescLin +nAjust, 1580 , "|   | Não Procurado"																	, oFont08 )
oPrint:Say( 280 - _nDescLin +nAjust, 1580 , "|   | Endereço insuficiente"															, oFont08 )

oPrint:Say( 180 - _nDescLin +nAjust, 1930 , "|   | Não existe o Número"															, oFont08 )
oPrint:Say( 230 - _nDescLin +nAjust, 1930 , "|   | Falecido"																		, oFont08 )
oPrint:Say( 280 - _nDescLin +nAjust, 1930 , "|   | Outros(anotar no verso)"														, oFont08 )

oPrint:Say( 350 - _nDescLin +nAjust, 1310 , "Recebí(emos) o bloqueto"																, oFont08 )
oPrint:Say( 380 - _nDescLin +nAjust, 1310 , "com os dados ao lado."																, oFont08 )
oPrint:Say( 350 - _nDescLin +nAjust, 1705 , "Data"																					, oFont08 )
oPrint:Say( 350 - _nDescLin +nAjust, 1905 , "Assinatura"  																			, oFont08 )

oPrint:Say( 130 - _nDescLin +nAjust, 0100 , "Cedente"																  				, oFont08 )
oPrint:Say( 170 - _nDescLin +nAjust, 0100 , IIf(_lBcoCorrespondente,aDadosBanco[8],AllTrim(aDadosEmp[1]) + " - " + aDadosEmp[6] /*+Space(10)+ aDadosTit[10]*/)			, oFont10 )

oPrint:Say( 210 - _nDescLin +nAjust, 0100 , "Sacado"																				, oFont08 )

If _lCliAvul
   oPrint:Say( 250 - _nDescLin +nAjust, 0100 , _cNomeAvul + " - " + _ccicsac + " ("+ _cCodAvul +")"									, oFont10 )
Else
   oPrint:Say( 250 - _nDescLin +nAjust, 0100 , aDatSacado[1] + " - " + aDatSacado[7] + " ("+ aDatSacado[2] +")"						, oFont10 )
EndIf

oPrint:Say( 290 - _nDescLin +nAjust, 0100 , "Data do Vencimento"																	, oFont08 )
oPrint:Say( 320 - _nDescLin +nAjust, 0100 , DToC( aDadosTit[4] )																	, oFont10 )

oPrint:Say( 290 - _nDescLin +nAjust, 0405 , "Nro.Documento"																		, oFont08 )
oPrint:Say( 320 - _nDescLin +nAjust, 0405 , aDadosTit[1]																			, oFont10 )

oPrint:Say( 290 - _nDescLin +nAjust, 0630 , "Moeda"																				, oFont08 )
oPrint:Say( 320 - _nDescLin +nAjust, 0655 , "R$"			   																		, oFont10 )

oPrint:Say( 290 - _nDescLin +nAjust, 0755 , "Valor/Quantidade"																		, oFont08 )
oPrint:Say( 320 - _nDescLin +nAjust, 0765 , AllTrim( Transform( aDadosTit[5] , "@E 999,999,999.99" ) )								, oFont10 )

oPrint:Say( 290 - _nDescLin +nAjust, 0985 , "Data do Processamento"																, oFont08 )
oPrint:Say( 320 - _nDescLin +nAjust, 0995 , DToC( aDadosTit[2] )																	, oFont10 )

oPrint:Say( 350 - _nDescLin +nAjust, 0100 , "Agencia/Cod. Cetente"																	, oFont08 )
oPrint:Say( 380 - _nDescLin +nAjust, 0100 , aDadosBanco[3]+"/"+aDadosBanco[4]+IIf(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],"")	, oFont10 )

oPrint:Say( 350 - _nDescLin +nAjust, 0505 , "Nosso Número"                             								      		, oFont08 )
oPrint:Say( 380 - _nDescLin +nAjust, 0520 , aDadosTit[6]								                                     		, oFont10 )

_nLin := ZB1->ZB1_LINSAC 
_nLin -= 150

For nI := 100 to 2300 step 50
   oPrint:Line( _nLin-150 , nI , _nLin-150 , nI + 30 )
Next nI

//===================================================================================================
// Ficha do Sacado                                                     
//===================================================================================================
_nLin += 0 //170 //_nLin := 1270 // alterar para um parametro

oPrint:Line( _nLin-30 , 100 , _nLin-30			, 2300 )
oPrint:Line( _nLin-30 , 650 , (_nLin-30-100)	, 0650 )
oPrint:Line( _nLin-30 , 900 , (_nLin-30-100)	, 0900 )

If aDadosBanco[1] == "389"
   oPrint:Say( (_nLin-66) - _nDescLin , 100 , aDadosBanco[2] , oFont10 )  			// (_nLin - 066) = 1204
ElseIf aDadosBanco[1] == "237"
   oPrint:SayBitMap( (_nLin - 106) - _nDescLin , 100 , aBitMap[2] , 300 , 100 )	// (_nLin - 106) = 1164
Else
   oPrint:Say( (_nLin-66) - _nDescLin , 100 , aDadosBanco[2] , oFont12 )			// (_nLin - 066) = 1204
EndIf

If aDadosBanco[1] == "033" //Santander

   oPrint:Say( (_nLin - 66) , 680 , aDadosBanco[1]+"-7"	, oFont20 ) //(_nLin - 88)  = 1182

Else

   oPrint:Say( (_nLin - 66) , 680 , aDadosBanco[1]+"-"+u_modulo11(aDadosBanco[1],aDadosBanco[1])						, oFont20 ) //(_nLin - 88)  = 1182

EndIf
oPrint:Say( (_nLin - 66) - _nDescLin , 920 , CB_RN_NN[2]																	, oFont14n) //LINHA DIGITAVEL // (_nLin - 66)  = 1204

oPrint:Line( (_nLin +  40)  , 0100 , (_nLin +  40) , 2300 )  // (_nLin + 100)  = 1370
oPrint:Line( (_nLin + 120)  , 0100 , (_nLin + 120) , 2300 )  // (_nLin + 200)  = 1470
oPrint:Line( (_nLin + 180)  , 0100 , (_nLin + 180) , 2300 )  // (_nLin + 270)  = 1540
oPrint:Line( (_nLin + 240)  , 0100 , (_nLin + 240) , 2300 )  // (_nLin + 340)  = 1610

oPrint:Line( (_nLin + 120) , 0500 , (_nLin + 240) , 0500 )  // (_nLin + 200)  = 1470 , (_nLin + 340)  = 1610
oPrint:Line( (_nLin + 180) , 0750 , (_nLin + 240) , 0750 )  // (_nLin + 270)  = 1540 , (_nLin + 340)  = 1610
oPrint:Line( (_nLin + 120) , 1000 , (_nLin + 240) , 1000 )  // (_nLin + 200)  = 1470 , (_nLin + 340)  = 1610
oPrint:Line( (_nLin + 120) , 1350 , (_nLin + 180) , 1350 )  // (_nLin + 200)  = 1470 , (_nLin + 270)  = 1540
oPrint:Line( (_nLin + 120) , 1550 , (_nLin + 240) , 1550 )  // (_nLin + 200)  = 1470 , (_nLin + 340)  = 1610

oPrint:Say( _nLin - _nDescLin , 100 , "Local de Pagamento"																			, oFont08 ) // _nLin = 1270

If aDadosBanco[1] == "237"

   oPrint:Say( (_nLin+030) - _nDescLin , 100 , "Pagável preferencialmente em qualquer Agência Bradesco"										, oFont10 ) // (_nLin + 40) = 1310

ElseIf aDadosBanco[1] == "341"

   oPrint:Say( (_nLin+030) - _nDescLin , 100 , "Até o vencimento, preferencialmente no Itau e Após o vencimento, somente no Itau."				, oFont10 ) // (_nLin + 40) = 1310

ElseIf aDadosBanco[1] == "033"

   oPrint:Say( (_nLin+030) - _nDescLin , 100 , "PAGAVEL PREFERENCIALMENTE NO BANCO SANTANDER"										, oFont10 ) // (_nLin + 40) = 1310
   
Else

   oPrint:Say( (_nLin+030) - _nDescLin , 100 , "Até o vencimento pagável em qualquer Banco."		  											, oFont10 ) // (_nLin + 40) = 1310

EndIf

oPrint:Say( _nlin - _nDescLin       , 1910 , "Vencimento"																					, oFont08 ) // _nLin = 1270
oPrint:Say( (_nLin+030) - _nDescLin , 2000 , AllTrim(DToC(aDadosTit[4]))																	, oFont10 ) // (_nLin + 40) = 1310

oPrint:Say( (_nLin+060) - _nDescLin , 0100 , "Cedente"																						, oFont08 ) // (_nLin + 100) = 1370
oPrint:Say( (_nLin+090) - _nDescLin , 0100 , IIf(_lBcoCorrespondente,aDadosBanco[8],AllTrim(aDadosEmp[1]) + " - " + aDadosEmp[6])					, oFont10 ) // (_nLin + 140) = 1410
oPrint:Say( (_nLin+060) - _nDescLin , 1910 , "Agência/Código Cedente"																		, oFont08 ) // (_nLin + 100) = 1370
oPrint:Say( (_nLin+090) - _nDescLin , 2000 , AllTrim(aDadosBanco[3]+"/"+aDadosBanco[4]+IIf(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],""))	, oFont10 ) // (_nLin + 140) = 1410

oPrint:Say( (_nLin+140) - _nDescLin , 0100 , "Data do Documento"																			, oFont08 ) // (_nLin + 200) = 1470
oPrint:Say( (_nLin+170) - _nDescLin , 0100 , DToC(aDadosTit[3])																				, oFont10 ) // (_nLin + 230) = 1500

oPrint:Say( (_nLin+140) - _nDescLin , 0505 , "Nro.Documento"																				, oFont08 ) // (_nLin + 200) = 1470
oPrint:Say( (_nLin+170) - _nDescLin , 0605 , aDadosTit[1]																					, oFont10 ) // (_nLin + 230) = 1500
oPrint:Say( (_nLin+140) - _nDescLin , 1005 , "Espécie Doc."																					, oFont08 ) // (_nLin + 200) = 1470
oPrint:Say( (_nLin+170) - _nDescLin , 1105 , "DM"																							, oFont10 ) // (_nLin + 230) = 1500
oPrint:Say( (_nLin+140) - _nDescLin , 1355 , "Aceite"																						, oFont08 ) // (_nLin + 200) = 1470
oPrint:Say( (_nLin+170) - _nDescLin , 1455 , "N"																							, oFont10 ) // (_nLin + 230) = 1500

oPrint:Say( (_nLin+140) - _nDescLin , 1555 , "Data do Processamento"																		, oFont08 ) // (_nLin + 200) = 1470
oPrint:Say( (_nLin+170) - _nDescLin , 1655 , DToC(aDadosTit[2])																				, oFont10 ) // (_nLin + 230) = 1500

oPrint:Say( (_nLin+140) - _nDescLin , 1910 ,"Nosso Número"																					, oFont08 ) // (_nLin + 200) = 1470
oPrint:Say( (_nLin+170) - _nDescLin , 2000 ,AllTrim(aDadosTit[6])																			, oFont10 ) // (_nLin + 230) = 1500

oPrint:Say( (_nLin+200) - _nDescLin , 0100 ,"Uso do Banco"																					, oFont08 ) // (_nLin + 270) = 1540
oPrint:Say( (_nLin+200) - _nDescLin , 0505 ,"Carteira"																						, oFont08 ) // (_nLin + 270) = 1540
oPrint:Say( (_nLin+230) - _nDescLin , 0555 ,aDadosBanco[6]+If(Empty(AllTrim(aDadosBanco[7])),"","-"+aDadosBanco[7])							, oFont10 ) // (_nLin + 300) = 1570
oPrint:Say( (_nLin+200) - _nDescLin , 0755 ,"Espécie"																						, oFont08 ) // (_nLin + 270) = 1540
oPrint:Say( (_nLin+230) - _nDescLin , 0805 ,"R$"																							, oFont10 ) // (_nLin + 300) = 1570
oPrint:Say( (_nLin+200) - _nDescLin , 1005 ,"Quantidade"																					, oFont08 ) // (_nLin + 270) = 1540
oPrint:Say( (_nLin+200) - _nDescLin , 1555 ,"Valor"																							, oFont08 ) // (_nLin + 270) = 1540
oPrint:Say( (_nLin+200) - _nDescLin , 1910 ,"(=)Valor do Documento"																			, oFont08 ) // (_nLin + 270) = 1540
oPrint:Say( (_nLin+230) - _nDescLin , 2000 ,AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99"))											, oFont10 ) // (_nLin + 300) = 1570

If aDadosBanco[1] == "341"
   oPrint:Say( (_nLin+261) - _nDescLin , 0100 , "Instruções/Todos as informações deste bloqueto são de exclusiva responsabilidade do cedente"	, oFont08 ) // (_nLin + 340) = 1610
Else
   oPrint:Say( (_nLin+261) - _nDescLin , 0100 , "Instruções/Texto de responsabilidade do cedente"												, oFont08 ) // (_nLin + 340) = 1610
EndIf

//Alteracao para padronizacao da mensagem do boleto -- [Chamado: 5453]
aTxtPad := RFIN002S( AllTrim(aDadosBanco[1]) , aDadosTit )

nLinIni	:= 287

oprint:Say( (_nLin + nLinIni) - _nDescLin , 100 , Upper("A ITALAC não tem o procedimento de alterar boletos. Caso receba algum contato nesse sentido ou extravio dos boletos,"), oFont08N)
nLinIni += 27
oprint:Say( (_nLin + nLinIni) - _nDescLin , 100 , Upper(" orientamos entrar em contato com o Dpto Financeiro da ITALAC para maiores informações através do telefone (11) 2889-5959."), oFont08N)
nLinIni += 27
oprint:Say( (_nLin + nLinIni) - _nDescLin , 100 , Upper("Em caso de necessidade de 2 via solicitar com antecedência mínima de 3 dias antes do respectivo vencimento, no contato acima."), oFont08N)
nLinIni += 27
oprint:Say( (_nLin + nLinIni) - _nDescLin , 100 , Upper("Depósitos bancários efetuados em conta corrente da credora não estão autorizados, bem como não dão quitação ao presente boleto"), oFont08N)
nLinIni += 27

//Imprime Linha de Desconto quando existir
oPrint:Say( (_nLin + nLinIni) - _nDescLin,100 ,IIf( aDadosTit[11] > 0 , "Desconto: Valor Fixo Ate Data "+ DToC(aDadosTit[4]) +" - R$ "+ AllTrim(Transform(aDadosTit[11],"@E 999,999.99")) , "" )	, oFont08 )
nLinIni += 20
oPrint:Say( (_nLin + nLinIni) - _nDescLin,100 ,IIf( MV_PAR13 > 0      , "Desconto dia por antecipacao R$ "+ AllTrim(Transform((aDadosTit[5]*MV_PAR13/100)/30,"@E 999,999.99")) , "" )				, oFont08 )
nLinIni += 20

//Juros de....
For nI := 1 To Len( aTxtPad ) //443
   oPrint:Say( (_nLin + nLinIni) , 100 , aTxtPad[nI] , oFont08 )
   nLinIni += 20
Next nI

oPrint:Say( (_nLin + 505) - _nDescLin , 100 ,aBolText[1]																		,oFont08) //(_nLin + 530) = 1800
oPrint:Say( (_nLin + 540) - _nDescLin , 100 ,aBolText[2]																		,oFont08) //(_nLin + 580) = 1850
oPrint:Say( (_nLin + 575) - _nDescLin , 100 ,aBolText[3]																		,oFont08) //(_nLin + 630) = 1900

oPrint:Say( (_nLin + 262) - _nDescLin , 1910 , "(-)Desconto/Abatimento"																,oFont08) //(_nLin + 340) = 1610
oPrint:Say( (_nLin + 320) - _nDescLin , 1910 , "(-)Outras Deduções"																	,oFont08) //(_nLin + 410) = 1680
oPrint:Say( (_nLin + 380) - _nDescLin , 1910 , "(+)Mora/Multa"					   													,oFont08) //(_nLin + 480) = 1750
oPrint:Say( (_nLin + 440) - _nDescLin , 1910 , "(+)Outros Acréscimos"																,oFont08) //(_nLin + 550) = 1820
oPrint:Say( (_nLin + 470) - _nDescLin , 2000 , IIf(aDadosTit[9]=0,"" , AllTrim(Transform(aDadosTit[9],"@E 999,999,999.99")))		,oFont10) //(_nLin + 580) = 1850
oPrint:Say( (_nLin + 500) - _nDescLin , 1910 , "(=)Valor Cobrado"																	,oFont08) //(_nLin + 620) = 1890

oPrint:Say( (_nLin + 557) - _nDescLin , 0100 , "Sacado:"																			,oFont08) // 690

If _lCliAvul
   oPrint:Say( (_nLin + 580) - _nDescLin , 210 ,  _cNomeAvul + " - " + _ccicsac + " ("+ _cCodAvul +")"		  							,oFont08) // (_nLin + 718) = 1988
   oPrint:Say( (_nLin + 602) - _nDescLin , 210 , _cEndAvul																				,oFont08) // (_nLin + 760) = 2030
   oPrint:Say( (_nLin + 624) - _nDescLin , 210 , _cCepAvul+"  "+_cMunAvul+" - "+_cEstAvul                                              ,oFont08) // (_nLin + 800) = 2070
Else
   oPrint:Say( (_nLin + 570) - _nDescLin , 210 , aDatSacado[1] + " - " + aDatSacado[7] + " ("+ aDatSacado[2] +")"						,oFont08) // (_nLin + 718) = 1988
   oPrint:Say( (_nLin + 592) - _nDescLin , 210 , aDatSacado[3]																			,oFont08) // (_nLin + 760) = 2030
   oPrint:Say( (_nLin + 614) - _nDescLin , 210 , aDatSacado[6]+"  "+aDatSacado[4]+" - "+aDatSacado[5]									,oFont08) // (_nLin + 800) = 2070
EndIf

oPrint:Say( (_nLin + 630) - _nDescLin , 1905 , "Codigo Baixa"																		,oFont08) // (_nLin + 800) = 2070
oPrint:Say( (_nLin + 630) - _nDescLin , 2100 , aDadosTit[1]														  					,oFont08) // (_nLin + 800) = 2070

oPrint:Say( (_nLin + 525) - _nDescLin , 0100 , "Sacador/Avalista "+IIf(_lBcoCorrespondente,AllTrim(aDadosEmp[1]) + " - " + aDadosEmp[6],"")							,oFont08) // (_nLin + 655) = 1925
oPrint:Say( (_nLin + 660) - _nDescLin , 1500 , "Autenticação Mecânica"																,oFont08) // 840
oPrint:Say( (_nLin + 660) - _nDescLin , 2000 , "Recibo do Sacado"																	,oFont10) // 840

oPrint:Line( _nLin - 30     , 1900 , (_nLin + 530) , 1900 ) // _nLin = 1270 ,  (_nLin + 690) = 1960
oPrint:Line( (_nLin + 300)	, 1900 , (_nLin + 300) , 2300 ) // (_nLin + 410) = 1680, (_nLin + 410) = 1680
oPrint:Line( (_nLin + 360)	, 1900 , (_nLin + 360) , 2300 ) // (_nLin + 480) = 1750
oPrint:Line( (_nLin + 420)	, 1900 , (_nLin + 420) , 2300 ) // (_nLin + 550) = 1820 , 
oPrint:Line( (_nLin + 480)	, 1900 , (_nLin + 480) , 2300 ) // (_nLin + 620) = 1890

oPrint:Line( (_nLin + 530)	, 0100 , (_nLin + 530) , 2300 ) // (_nLin + 690) = 1960
oPrint:Line( (_nLin + 635)	, 0100 , (_nLin + 635) , 2300 ) // (_nLin + 835) = 2105

//-- Definicao do posicionamento do codigo de barras --//
_nLinha			:= ZB1->ZB1_LINCB1 //18.8 // 18.5 
_nColuna		:= ZB1->ZB1_COLCB1 //1.2  // 1.5 
_nComprimento	:= ZB1->ZB1_COMCB1 //0.0253
_nAltura		:= ZB1->ZB1_ALTCB1 //1.0
nFator			:= 0

//-- Aplicacao do Fator de correcao para Boletos do Bradesco --
If aDadosBanco[1] == "237" 
   nFator := 0.5
EndIf

_nLinha += 18
_nColuna += 1 

oPrint:FWMSBAR("INT25" /*cTypeBar*/,(_nLinha - nFator) /*nRow*/ ,(_nColuna - nFator) /*nCol*/, CB_RN_NN[1] /*cCode*/,oPrint/*oPrint*/,.F./*lCheck*/,/*Color*/,.T./*lHorz*/,_nComprimento/*nWidth*/,_nAltura/*nHeigth*/,.F./*lBanner*/,"Arial"/*cFont*/,NIL/*cMode*/,.F./*lPrint*/,2/*nPFWidth*/,2/*nPFHeigth*/,.F./*lCmtr2Pix*/) 

_nLin2 := ZB1->ZB1_LINFCP // 2270 
_nLin2 -= 460

//_nLin2    := 1815
_nDescLin := 6

// PONTILHAMENTO
For i := 100 to 2300 step 50
   oPrint:Line( _nLin2 -20 , i , _nLin2-20 , i + 30 ) // _nLin2 = 2270
Next i

//===================================================================================================
// Ficha de Compensacao                                                
//===================================================================================================
oPrint:Line( (_nLin2 + 90) , 100 , (_nLin2 + 90) , 2300 ) // (_nLin2 + 120) = 2390
oPrint:Line( (_nLin2 + 90) , 650 , (_nLin2 - 10) , 0650 ) // (_nLin2 + 120), (_nLin2 + 20) = 2290
oPrint:Line( (_nLin2 + 90) , 900 , (_nLin2 - 10) , 0900 ) // (_nLin2 + 120), (_nLin2 + 20) = 2290


If aDadosBanco[1] == "389"
   oPrint:Say( (_nLin2 + 54) - _nDescLin , 100			,aDadosBanco[2]		, oFont10	) // (_nLin2 + 54) = 2324
ElseIf aDadosBanco[1] == "237"
   oPrint:SayBitMap( (_nLin2 + 14) - _nDescLin , 100	, aBitMap[2]		, 300 , 100	) // (_nLin2 + 14) = 2284
Else
   oPrint:Say( (_nLin2 + 54) - _nDescLin , 100			, aDadosBanco[2]	, oFont12	) // (_nLin2 + 54) = 2324
EndIf

If aDadosBanco[1] == "033"

   oPrint:Say( (_nLin2 + 54) - _nDescLin	, 680 , aDadosBanco[1]+"-7"		,oFont20 ) // (_nLin2 + 32) = 2302 

Else

   oPrint:Say( (_nLin2 + 54) - _nDescLin	, 680 , aDadosBanco[1]+"-"+u_modulo11(aDadosBanco[1],aDadosBanco[1])		,oFont20 ) // (_nLin2 + 32) = 2302 

EndIf

oPrint:Say( (_nLin2 + 54) - _nDescLin	, 920 , CB_RN_NN[2]														,oFont14n) //linha digitavel // (_nLin2 + 54) = 2324

oPrint:Line( (_nLin2 + 190) , 0100 , (_nLin2 + 190) , 2300 ) // (_nLin2 + 220) = 2490
oPrint:Line( (_nLin2 + 290) , 0100 , (_nLin2 + 290) , 2300 ) // (_nLin2 + 320) = 2590
oPrint:Line( (_nLin2 + 360) , 0100 , (_nLin2 + 360) , 2300 ) // (_nLin2 + 390) = 2660 
oPrint:Line( (_nLin2 + 430) , 0100 , (_nLin2 + 430) , 2300 ) // (_nLin2 + 460) = 2730 

oPrint:Line( (_nLin2 + 290) , 0500 , (_nLin2 + 430) , 0500 ) // (_nLin2 + 320) = 2590 , (_nLin2 + 460) = 2730
oPrint:Line( (_nLin2 + 360) , 0750 , (_nLin2 + 430) , 0750 ) // (_nLin2 + 390) = 2660 , (_nLin2 + 460) = 2730
oPrint:Line( (_nLin2 + 290) , 1000 , (_nLin2 + 430) , 1000 ) // (_nLin2 + 320) = 2590 , (_nLin2 + 460) = 2730
oPrint:Line( (_nLin2 + 290) , 1350 , (_nLin2 + 360) , 1350 ) // (_nLin2 + 320) = 2590 , (_nLin2 + 390) = 2660 
oPrint:Line( (_nLin2 + 290) , 1550 , (_nLin2 + 430) , 1550 ) // (_nLin2 + 320) = 2590 , (_nLin2 + 460) = 2730

oPrint:Say( (_nLin2 + 120) - _nDescLin		, 100 , "Local de Pagamento"																   			,oFont08)  // (_nLin2 + 120) = 2390

If aDadosBanco[1] == "237"  //SE BRADESCO
   oPrint:Say( (_nLin2 + 160) - _nDescLin	, 100 , "Pagável preferencialmente em qualquer Agência Bradesco."							 			,oFont10) // (_nLin2 + 160) = 2430
ElseIf aDadosBanco[1] == "341"
   oPrint:Say( (_nLin2 + 160) - _nDescLin	, 100 , "Até o vencimento, preferencialmente no Itau e Após o vencimento, somente no Itau."	 			,oFont10) // (_nLin2 + 160) = 2430
Else
   oPrint:Say( (_nLin2 + 160) - _nDescLin	, 100 , "Até o vencimento pagável em qualquer Banco."											 		,oFont10) // (_nLin2 + 160) = 2430
EndIf

oPrint:Say( (_nLin2 + 120) - _nDescLin , 1910 , "Vencimento"																						,oFont08) // (_nLin2 + 120) = 2390 
If aDadosBanco[1] $ "341,237"  //SE ITAU,BRADESCO
   oPrint:Say( (_nLin2 + 160) - _nDescLin , 2000 , AllTrim(Substring(DToS(aDadosTit[4]),7,2)+"/"+Substring(DToS(aDadosTit[4]),5,2)+"/"+Substring(DToS(aDadosTit[4]),1,4)),oFont10) // (_nLin2 + 160) = 2430
Else
   oPrint:Say( (_nLin2 + 160) - _nDescLin , 2000 , AllTrim(DToC(aDadosTit[4]))																		,oFont10) // (_nLin2 + 160) = 2430
EndIf

oPrint:Say( (_nLin2 + 220) - _nDescLin , 0100 , "Cedente"																							,oFont08) // (_nLin2 + 220) = 2490
oPrint:Say( (_nLin2 + 260) - _nDescLin , 0100 , IIf(_lBcoCorrespondente,aDadosBanco[8],AllTrim(aDadosEmp[1]) + " - " + aDadosEmp[6])							,oFont10) // (_nLin2 + 260) = 2530
oPrint:Say( (_nLin2 + 220) - _nDescLin , 1910 , "Agência/Código Cedente"																			,oFont08) // (_nLin2 + 220) = 2490
oPrint:Say( (_nLin2 + 260) - _nDescLin , 2000 , AllTrim(aDadosBanco[3]+"/"+aDadosBanco[4]+IIf(!Empty(aDadosBanco[5]),"-"+aDadosBanco[5],""))	,oFont10) // (_nLin2 + 260) = 2530
oPrint:Say( (_nLin2 + 320) - _nDescLin , 0100 , "Data do Documento"                      ,oFont08)  // (_nLin2 + 320) = 2590

If aDadosBanco[1] == "237"   //SE BRADESCO
   oPrint:Say( (_nLin2 + 350) - _nDescLin , 100 , Substring(DToS(aDadosTit[3]),7,2)+"/"+Substring(DToS(aDadosTit[3]),5,2)+"/"+Substring(DToS(aDadosTit[3]),1,4)  ,oFont10) // (_nLin2 + 350) = 2620
Else
   oPrint:Say( (_nLin2 + 350) - _nDescLin , 100 , DToC(aDadosTit[3])																				,oFont10) // (_nLin2 + 350) = 2620
EndIf

oPrint:Say( (_nLin2 + 320) - _nDescLin , 0505 , "Nro.Documento"												   										,oFont08) // (_nLin2 + 320) = 2590
oPrint:Say( (_nLin2 + 350) - _nDescLin , 0605 , aDadosTit[1]																						,oFont10) // (_nLin2 + 350) = 2620 
oPrint:Say( (_nLin2 + 320) - _nDescLin , 1005 , "Espécie Doc."																						,oFont08) // (_nLin2 + 320) = 2590
oPrint:Say( (_nLin2 + 350) - _nDescLin , 1105 , "DM"																								,oFont10) // (_nLin2 + 350) = 2620 
oPrint:Say( (_nLin2 + 320) - _nDescLin , 1355 , "Aceite"																							,oFont08) // (_nLin2 + 320) = 2590
oPrint:Say( (_nLin2 + 350) - _nDescLin , 1455 , "N"															 										,oFont10) // (_nLin2 + 350) = 2620 
oPrint:Say( (_nLin2 + 320) - _nDescLin , 1555 , "Data do Processamento"																				,oFont08) // (_nLin2 + 320) = 2590

If aDadosBanco[1] == "237"   //SE BRADESCO
   oPrint:Say( (_nLin2 + 350) - _nDescLin , 1655 , Substring(DToS(aDadosTit[2]),7,2)+"/"+Substring(DToS(aDadosTit[2]),5,2)+"/"+Substring(DToS(aDadosTit[2]),1,4)  ,oFont10) // (_nLin2 + 350) = 2620 
Else
   oPrint:Say( (_nLin2 + 350) - _nDescLin , 1655 , DToC(aDadosTit[2])																				,oFont10) // (_nLin2 + 350) = 2620 
EndIf

oPrint:Say( (_nLin2 + 320) - _nDescLin	, 1910 , "Nosso Número"																						,oFont08) // (_nLin2 + 320) = 2590
oPrint:Say( (_nLin2 + 350) - _nDescLin	, 2000 , AllTrim(aDadosTit[6])																				,oFont10) // (_nLin2 + 350) = 2620 
oPrint:Say( (_nLin2 + 390) - _nDescLin	, 0100 , "Uso do Banco"																						,oFont08) // (_nLin2 + 390) = 2660
oPrint:Say( (_nLin2 + 390) - _nDescLin	, 0505 , "Carteira"																							,oFont08) // (_nLin2 + 390) = 2660
oPrint:Say( (_nLin2 + 420) - _nDescLin	, 0555 , aDadosBanco[6]+If(Empty(AllTrim(aDadosBanco[7])),"","-"+aDadosBanco[7])							,oFont10)
oPrint:Say( (_nLin2 + 390) - _nDescLin	, 0755 , "Espécie"																							,oFont08) // (_nLin2 + 390) = 2660
oPrint:Say( (_nLin2 + 420) - _nDescLin	, 0805 , "R$"																								,oFont10) // (_nLin2 + 420) = 2690
oPrint:Say( (_nLin2 + 390) - _nDescLin	, 1005 , "Quantidade"																						,oFont08) // (_nLin2 + 390) = 2660
oPrint:Say( (_nLin2 + 390) - _nDescLin	, 1555 , "Valor"																							,oFont08) // (_nLin2 + 390) = 2660
oPrint:Say( (_nLin2 + 390) - _nDescLin	, 1910 , "(=)Valor do Documento"																			,oFont08) // (_nLin2 + 390) = 2660
oPrint:Say( (_nLin2 + 420) - _nDescLin	, 2000 , AllTrim(Transform(aDadosTit[5],"@E 999,999,999.99"))												,oFont10) // (_nLin2 + 420) = 2690

If aDadosBanco[1] == "341"
   oPrint:Say( (_nLin2 + 460) - _nDescLin , 100 , "Instruções/Todos as informações deste bloqueto são de exclusiva responsabilidade do cedente"	,oFont08) // (_nLin2 + 460) = 2730
Else
   oPrint:Say( (_nLin2 + 460) - _nDescLin , 100 , "Instruções/Texto de responsabilidade do cedente"												,oFont08) // (_nLin2 + 460) = 2730
EndIf

//-- Alteracao para padronizacao da mensagem do boleto --// [Chamado: 5453]
nLinIni := 490

oprint:Say( (_nLin2 + nLinIni) - _nDescLin , 100 , Upper("A ITALAC não tem o procedimento de alterar boletos. Caso receba algum contato nesse sentido ou extravio dos boletos,"), oFont08N)
nLinIni += 27
oprint:Say( (_nLin2 + nLinIni) - _nDescLin , 100 , Upper(" orientamos entrar em contato com o Dpto Financeiro da ITALAC para maiores informações através do telefone (11) 2889-5959."), oFont08N)
nLinIni += 27
oprint:Say( (_nLin2 + nLinIni) - _nDescLin , 100 , Upper("Em caso de necessidade de 2 via solicitar com antecedência mínima de 3 dias antes do respectivo vencimento, no contato acima."), oFont08N)
nLinIni += 27
oprint:Say( (_nLin2 + nLinIni) - _nDescLin , 100 , Upper("Depósitos bancários efetuados em conta corrente da credora não estão autorizados, bem como não dão quitação ao presente boleto"), oFont08N)
nLinIni += 27

oPrint:Say( (_nLin2 + nLinIni) - _nDescLin , 0100 ,IIf(aDadosTit[11] > 0, "Desconto: Valor Fixo Ate Data " + DToC(aDadosTit[4]) + " - R$ "+AllTrim(Transform(aDadosTit[11],"@E 999,999.99")), "") ,oFont08)
nLinIni += 20
oPrint:Say( (_nLin2 + nLinIni) - _nDescLin , 0100 ,IIf(MV_PAR13>0,"Desconto dia por antecipacao R$ "+AllTrim(Transform((aDadosTit[5]*MV_PAR13/100)/30,"@E 999,999.99")),"") ,oFont08) // (_nLin2 + 510) = 2780
nLinIni += 20

//Juros de....
For nI := 1 To Len( aTxtPad )
   oPrint:Say( (_nLin2 + nLinIni) , 100 , aTxtPad[nI] , oFont08 )
   nLinIni += 20
Next nI

oPrint:Say( (_nLin2 + 705) - _nDescLin , 0100 , aBolText[1]									 												,oFont08) // (_nLin2 + 650) = 2920
oPrint:Say( (_nLin2 + 740) - _nDescLin , 0100 , aBolText[2]																					,oFont08) // (_nLin2 + 700) = 2970
oPrint:Say( (_nLin2 + 775) - _nDescLin , 0100 , aBolText[3]																					,oFont08) // (_nLin2 + 750) = 3020

oPrint:Say( (_nLin2 + 460) - _nDescLin , 1910 , "(-)Desconto/Abatimento"																			,oFont08) // (_nLin2 + 460) = 2730
oPrint:Say( (_nLin2 + 530) - _nDescLin , 1910 , "(-)Outras Deduções"																				,oFont08) // (_nLin2 + 530) = 2800
oPrint:Say( (_nLin2 + 600) - _nDescLin , 1910 , "(+)Mora/Multa"																						,oFont08) // (_nLin2 + 600) = 2870
oPrint:Say( (_nLin2 + 670) - _nDescLin , 1910 , "(+)Outros Acréscimos"																				,oFont08) // (_nLin2 + 670) = 2940
oPrint:Say( (_nLin2 + 700) - _nDescLin , 2000 , IIf(aDadosTit[9] = 0," ", AllTrim(Transform(aDadosTit[9],"@E 999,999,999.99")))						,oFont10) // (_nLin2 + 700) = 2970
oPrint:Say( (_nLin2 + 740) - _nDescLin , 1910 , "(=)Valor Cobrado"																					,oFont08) // (_nLin2 + 740) = 3010
oPrint:Say( (_nLin2 + 810) - _nDescLin , 0100 , "Sacado"																							,oFont08) // (_nLin2 + 810) = 3080

If _lCliAvul
   oPrint:Say( (_nLin2 + 838) - _nDescLin , 0210 , _cNomeAvul + " - " + _ccicsac + " ("+ _cCodAvul +")"											,oFont08)  // (_nLin2 + 838) = 3108
   oPrint:Say( (_nLin2 + 863) - _nDescLin , 0210 , _cEndAvul																						,oFont08)  // (_nLin2 + 878) = 3148
   oPrint:Say( (_nLin2 + 888) - _nDescLin , 0210 , _cCepAvul+"  "+_cMunAvul+" - "+_cEstAvul														,oFont08) // (_nLin2 + 918) = 3188
Else
   oPrint:Say( (_nLin2 + 838) - _nDescLin , 0210 , aDatSacado[1] + " - " + aDatSacado[7] + " ("+ aDatSacado[2] +")"								,oFont08) // (_nLin2 + 838) = 3108
   oPrint:Say( (_nLin2 + 863) - _nDescLin , 0210 , aDatSacado[3]																					,oFont08) // (_nLin2 + 878) = 3148
   oPrint:Say( (_nLin2 + 888) - _nDescLin , 0210 , aDatSacado[6]+"  "+aDatSacado[4]+" - "+aDatSacado[5]											,oFont08) // (_nLin2 + 918) = 3188
EndIf

oPrint:Say( (_nLin2 + 918) - _nDescLin , 1905 , "Codigo Baixa"																						,oFont08) // (_nLin2 + 918) = 3188
oPrint:Say( (_nLin2 + 918) - _nDescLin , 2100 , aDadosTit[1]																						,oFont08) // (_nLin2 + 918) = 3188

oPrint:Say( (_nLin2 + 775) - _nDescLin , 0100 , "Sacador/Avalista"+IIf(_lBcoCorrespondente,AllTrim(aDadosEmp[1]) + " - " + aDadosEmp[6],"")											,oFont08) // (_nLin2 + 775) = 3045
oPrint:Say( (_nLin2 + 950) - _nDescLin , 1500 , "Autenticação Mecânica"																				,oFont08) // (_nLin2 + 960) = 3230

If aDadosBanco[1] == "341"
   oPrint:Say( (_nLin2 + 950) - _nDescLin , 2000 , "Ficha de Compensação"																			,oFont08) // (_nLin2 + 960) = 3230
Else
   oPrint:Say( (_nLin2 + 950) - _nDescLin , 2000 , "Ficha de Compensação"																			,oFont10) // (_nLin2 + 960) = 3230
EndIf

oPrint:Line( (_nLin2 +  90) , 1900 , (_nLin2 + 810 -30) , 1900 ) // (_nLin2 + 120) = 2390 , (_nLin2 + 810) = 3080
oPrint:Line( (_nLin2 + 500) , 1900 , (_nLin2 + 530 -30) , 2300 ) // (_nLin2 + 530) = 2800
oPrint:Line( (_nLin2 + 570) , 1900 , (_nLin2 + 600 -30) , 2300 ) // (_nLin2 + 600) = 2870
oPrint:Line( (_nLin2 + 640) , 1900 , (_nLin2 + 670 -30) , 2300 ) // (_nLin2 + 670) = 2940   
oPrint:Line( (_nLin2 + 710) , 1900 , (_nLin2 + 740 -30) , 2300 ) // (_nLin2 + 740) = 3010
oPrint:Line( (_nLin2 + 780) , 0100 , (_nLin2 + 810 -30) , 2300 ) // (_nLin2 + 810) = 3080
oPrint:Line( (_nLin2 + 915) , 0100 , (_nLin2 + 955 -40) , 2300 ) // (_nLin2 + 955) = 3225

//-- Definicao do posicionamento do codigo de barras --//
_nLinha			:=  ZB1->ZB1_LINCB2 //28.3//27.9  // 28
_nColuna		:=  ZB1->ZB1_COLCB2 //1.2 //1.5
_nComprimento	:=  ZB1->ZB1_COMCB2 //0.0253
_nAltura		:=  ZB1->ZB1_ALTCB2 //1.3
nFator			:= 0

//-- Aplicacao do Fator de correcao para Boletos do Bradesco --// 
If aDadosBanco[1] == "237" 
   nFator := 0.5
EndIf

_nLinha += 35
_nColuna += 1 

oPrint:FWMSBAR("INT25" /*cTypeBar*/,(_nLinha - nFator) /*nRow*/ ,(_nColuna - nFator) /*nCol*/, CB_RN_NN[1] /*cCode*/,oPrint/*oPrint*/,.F./*lCheck*/,/*Color*/,.T./*lHorz*/,_nComprimento/*nWidth*/,_nAltura/*nHeigth*/,.F./*lBanner*/,"Arial"/*cFont*/,NIL/*cMode*/,.F./*lPrint*/,2/*nPFWidth*/,2/*nPFHeigth*/,.F./*lCmtr2Pix*/) 

oPrint:EndPage() // Finaliza a página

Return

/*
===============================================================================================================================
Programa----------: MFIN002I
Autor-------------: Cleiton Campos
Data da Criacao---: 17/03/2009
Descrição---------: Rotina que inverte a seleção dos registros
Parametros--------: cMarca , oValor , oQtda
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN002I( cMarca As Character, oValor As Object, oQtda As Object ) 

Local nReg     := TRB->( Recno() ) As Numeric
Local lMarcado := .F. As Logical

DBSelectArea("TRB")
TRB->( DBGoTop() )
While TRB->( !Eof() )
   
   lMarcado := IsMark( "E1_OK" , cMarca , lInverte )
   
   RecLock( "TRB" , .F. )
   
   If (lMarcado .Or. lInverte)  .And. !_lCallNfe  .And. !_lEmail   .And. !_lWorkFlow .And. !_lGerPDF
   
      TRB->E1_OK	:= Space(2)
      nValor		-= TRB->E1_SALDO		
      nQtdTit--
      
   Else
   
      TRB->E1_OK	:= cMarca
      nValor		+= TRB->E1_SALDO
      nQtdTit++
      
   EndIf
   
   MSUnLock()
   
   nQtdTit	:= IIf( nQtdTit < 0 , 0 , nQtdTit )
   nValor	:= IIf( nValor < 0  , 0 , nValor  )
   
   TRB->( DBSkip() )
EndDo

TRB->( DBGoTo(nReg) )

If !_lCallNfe .And. !_lEmail  .And. !_lWorkFlow .And. !_lGerPDF
   oValor:Refresh()
   oQtda:Refresh()
   oMark:oBrowse:Refresh(.T.)
EndIf

Return

/*
===============================================================================================================================
Programa----------: RFIN002W
Autor-------------: Cleiton Campos
Data da Criacao---: 17/03/2009
Descrição---------: Rotina que inverte a seleção do registro selecionado
Parametros--------: cMarca , oValor , oQtda
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN002W(cMarca As Character,oValor As Object,oQtda As Object)
Local lMarcado := IsMark("E1_OK",cMarca,lInverte) As Logical

If lMarcado
   nValor += TRB->E1_SALDO
   nQtdTit++
Else
   nValor -= TRB->E1_SALDO
   nQtdTit--
EndIf

oValor:Refresh()
oQtda:Refresh()

Return

/*
===============================================================================================================================
Programa----------: RFIN002J
Autor-------------: Cleiton Campos
Data da Criacao---: 17/03/2009
Descrição---------: Rotina que cria o arquivo temporário
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN002J()

Local aEstru := {} As Array
Local cQuery := "" As Character
Local _lContintua := .F. As Logical

//===================================================================================================
// Armazena no array aEstru a estrutura dos campos da tabela.      
//===================================================================================================
aAdd( aEstru , { "E1_OK"        , 'C' , 02 , 0 } )
aAdd( aEstru , { "E1_FILIAL"    , 'C' , 02 , 0 } )
aAdd( aEstru , { "E1_PREFIXO"   , 'C' , 03 , 0 } )
aAdd( aEstru , { "E1_NUM"       , 'C' , 09 , 0 } )
aAdd( aEstru , { "E1_PARCELA"   , 'C' , 02 , 0 } )
aAdd( aEstru , { "E1_TIPO"      , 'C' , 02 , 0 } )
aAdd( aEstru , { "E1_PORTADO"   , 'C' , 03 , 0 } )
aAdd( aEstru , { "E1_AGEDEP"    , 'C' , 05 , 0 } )
aAdd( aEstru , { "E1_CONTA"     , 'C' , 10 , 0 } )
aAdd( aEstru , { "E1_NUMBCO"    , 'C' , 17 , 0 } )
aAdd( aEstru , { "E1_NUMBOR"    , 'C' , 06 , 0 } )

aAdd( aEstru , { "E1_I_CARGA"   , 'C' , 06 , 0 } )
aAdd( aEstru , { "E1_CLIENTE"   , 'C' , 06 , 0 } )
aAdd( aEstru , { "E1_LOJA"      , 'C' , 04 , 0 } )
aAdd( aEstru , { "E1_NOMCLI"    , 'C' , 20 , 0 } )
aAdd( aEstru , { "E1_EMISSAO"   , 'D' , 08 , 0 } )
aAdd( aEstru , { "E1_VENCTO"    , 'D' , 08 , 0 } )
aAdd( aEstru , { "E1_VENCREA"   , 'D' , 08 , 0 } )
aAdd( aEstru , { "E1_VALOR"     , 'N' , 14 , 2 } )
aAdd( aEstru , { "E1_SALDO"     , 'N' , 14 , 2 } )
aAdd( aEstru , { "E1_DESCFIN"   , 'N' , 05 , 2 } )
aAdd( aEstru , { "E1_TIPODES"   , 'C' , 01 , 0 } )
aAdd( aEstru , { "E1_DECRESC"   , 'N' , 14 , 2 } )

aAdd( aEstru , { "E1_I_DESCO"   , 'N' , 17 , 2 } )

aAdd( aEstru , { "E1_I_ULBCO"   , 'C' , 30 , 0 } )
aAdd( aEstru , { "E1_I_ULCTA"   , 'C' , 30 , 0 } )
aAdd( aEstru , { "E1_I_ULAGE"   , 'C' , 30 , 0 } )
aAdd( aEstru , { "E1_I_ULSUB"   , 'C' , 30 , 0 } )
aAdd( aEstru , { "E1_I_NUMBC"   , 'C' , 17 , 0 } )
aAdd( aEstru , { "E1_IDCNAB"    , 'C' , 17 , 0 } )
aAdd( aEstru , { "A1_EMAIL"     , 'C' , 100 , 0 } )
aAdd( aEstru , { "E1_VEND1"     , 'C' , 100 , 0 } )
aAdd( aEstru , { "E1_I_CHPIX"   , 'C' , 100 , 0 } )
aAdd( aEstru , { "EA_APIMSG"    , 'M' , 10  , 0 } )

//===================================================================================================
// Armazena no array aCampos o nome, picture e descricao dos campos. 
//===================================================================================================
aAdd( aCampos , { "E1_OK"       ,  ,                , " "                                         } )
aAdd( aCampos , { "E1_FILIAL"   ,"", "Filial"       , PesqPict( "SE1" , "E1_FILIAL" )             } )
aAdd( aCampos , { "E1_PREFIXO"  ,"", "Prefixo"      , PesqPict( "SE1" , "E1_PREFIXO" )            } )
aAdd( aCampos , { "E1_NUM"      ,"", "Numero"       , PesqPict( "SE1" , "E1_NUM" )                } )
aAdd( aCampos , { "E1_PARCELA"  ,"", "Parcela"      , PesqPict( "SE1" , "E1_PARCELA" )            } )
aAdd( aCampos , { "E1_TIPO"     ,"", "Tipo"         , PesqPict( "SE1" , "E1_TIPO" )               } )
aAdd( aCampos , { "E1_PORTADO"  ,"", "Banco"        , PesqPict( "SE1" , "E1_PORTADO" )            } )
aAdd( aCampos , { "E1_AGEDEP"   ,"", "Agencia"      , PesqPict( "SE1" , "E1_AGEDEP" )             } )
aAdd( aCampos , { "E1_CONTA"    ,"", "Conta"        , PesqPict( "SE1" , "E1_CONTA" )              } )
aAdd( aCampos , { "E1_NUMBCO"   ,"", "Nº no Banco"  , PesqPict( "SE1" , "E1_NUMBCO" )             } )
aAdd( aCampos , { "E1_NUMBOR"   ,"", "Bordero"      , PesqPict( "SE1" , "E1_NUMBOR" )             } )

aAdd( aCampos , { "E1_I_CARGA"  ,"", "Carga"        , PesqPict( "SE1" , "E1_I_CARGA" )            } )
aAdd( aCampos , { "E1_CLIENTE"  ,"", "Cliente"      , PesqPict( "SE1" , "E1_CLIENTE" )            } )
aAdd( aCampos , { "E1_LOJA"     ,"", "Loja"         , PesqPict( "SE1" , "E1_LOJA" )               } )
aAdd( aCampos , { "E1_NOMCLI"   ,"", "Nome"         , PesqPict( "SE1" , "E1_NOMCLI" )             } )
aAdd( aCampos , { "E1_EMISSAO"  ,"", "Emissao"      , PesqPict( "SE1" , "E1_EMISSAO" )            } )
aAdd( aCampos , { "E1_VENCTO"   ,"", "Vencto"       , PesqPict( "SE1" , "E1_VENCTO" )             } )
aAdd( aCampos , { "E1_VENCREA"  ,"", "Vencto Real"  , PesqPict( "SE1" , "E1_VENCREA" )            } )
aAdd( aCampos , { "E1_VALOR"    ,"", "Valor"        , PesqPict( "SE1" , "E1_VALOR"     , 14 , 2 ) } )
aAdd( aCampos , { "E1_SALDO"    ,"", "Saldo"        , PesqPict( "SE1" , "E1_SALDO"     , 14 , 2 ) } )
aAdd( aCampos , { "E1_DESCFIN"  ,"", "% Desconto"   , PesqPict( "SE1" , "E1_DESCFIN"   , 05 , 2 ) } )
aAdd( aCampos , { "E1_TIPODES"  ,"", "Tipo Descont" , PesqPict( "SE1" , "E1_TIPODES" )            } )
aAdd( aCampos , { "E1_DECRESC"  ,"", "Decrescimo"   , PesqPict( "SE1" , "E1_DECRESC"   , 14 , 2 ) } )

aAdd( aCampos , { "E1_I_DESCO"  ,"", "Desc Contrat" , PesqPict( "SE1" , "E1_I_DESCO"   , 17 , 2 ) } )

aAdd( aCampos , { "E1_I_ULBCO"  ,"", "Ult Bco Usad" , PesqPict( "SE1" , "E1_I_ULBCO"            ) } )
aAdd( aCampos , { "E1_I_ULCTA"  ,"", "Ult Cta Usad" , PesqPict( "SE1" , "E1_I_ULCTA"            ) } )
aAdd( aCampos , { "E1_I_ULAGE"  ,"", "Ult Age Usad" , PesqPict( "SE1" , "E1_I_ULAGE"            ) } )
aAdd( aCampos , { "E1_I_ULSUB"  ,"", "Ult Sub Usad" , PesqPict( "SE1" , "E1_I_ULSUB"            ) } )
aAdd( aCampos , { "E1_I_NUMBC" ,"", "Bkp Nosso Num" , PesqPict( "SE1" , "E1_I_NUMBC"            ) } )
aAdd( aCampos , { "E1_IDCNAB"  ,"", "Id Cnab      " , PesqPict( "SE1" , "E1_IDCNAB"             ) } )
aAdd( aCampos , { "EA_APIMSG"  ,"", "Api Msg      " , PesqPict( "SEA" , "EA_APIMSG"             ) } )

//===================================================================================================
// Verifica se ja existe um arquivo com mesmo nome, se sim deleta. 
//===================================================================================================
If Select("TRB") <> 0
   TRB->( DBCloseArea() )
EndIf


//Cria tabela temporária
_otemp := FWTemporaryTable():New( "TRB", aEstru )

_otemp:AddIndex( "01", {"E1_PREFIXO","E1_NUM","E1_PARCELA","E1_TIPO"} )
_otemp:AddIndex( "02", {"E1_CLIENTE","E1_LOJA","E1_PREFIXO","E1_NUM"} )
_otemp:AddIndex( "03", {"E1_NOMCLI"} )
_otemp:AddIndex( "04", {"E1_VALOR"} )

_otemp:Create()

//===================================================================================================
// Query para selecao dos dados.                                   
//===================================================================================================
cQuery := "SELECT "
cQuery += "     E1_FILIAL		, E1_PREFIXO		, E1_NUM		, "
cQuery += "     E1_PARCELA		, E1_PORTADO		, E1_AGEDEP		, "
cQuery += "     E1_CONTA		, E1_TIPO			, E1_NATUREZ	, "
cQuery += "     E1_CLIENTE		, E1_LOJA			, E1_NOMCLI		, "
cQuery += "     E1_EMISSAO		, E1_VENCTO			, E1_VENCREA	, "
cQuery += "     E1_VALOR		, E1_SALDO			, E1_DESCFIN	, "
cQuery += "     E1_TIPODES		, E1_NUMBCO			, E1_DECRESC	, "
cQuery += "     E1_NUMBOR		, E1_I_CARGA		, E1_I_DESCO, E1_I_NUMBC, "
cQuery += "     E1_I_ULBCO		, E1_I_ULCTA		, E1_I_ULAGE, E1_I_ULSUB, E1_IDCNAB, SA1_2.A1_EMAIL AS A1_EMAIL, E1_VEND1"

If SE1->(FIELDPOS("E1_I_DTPRO")) <> 0
   cQuery += " , E1_I_DTPRO"
EndIf
cQuery += " , EA_APIMSG "

cQuery += " FROM  "+ RetSqlName("SE1") +" SE1 " 
cQuery += "     LEFT JOIN "+ RetSqlName("SA1") +" SA1_2 ON SA1_2.A1_COD = SE1.E1_CLIENTE AND SA1_2.A1_LOJA = SE1.E1_LOJA AND SA1_2.D_E_L_E_T_ =' ' "
cQuery += "     LEFT JOIN "+ RetSqlName("SEA") +" SEA ON SEA.EA_FILIAL = SE1.E1_FILIAL AND SEA.EA_NUMBOR = SE1.E1_NUMBOR AND SEA.EA_PREFIXO = SE1.E1_PREFIXO AND SEA.EA_NUM = SE1.E1_NUM AND SEA.EA_PARCELA = SE1.E1_PARCELA AND SEA.EA_TIPO = SE1.E1_TIPO AND SEA.D_E_L_E_T_ =' ' "

If ! Empty(MV_PAR15) .Or. ! Empty(MV_PAR16) .Or. ! Empty(MV_PAR17)
   cQuery += "     LEFT JOIN " + RetSqlName("DAK") +" DAK ON " + RetSqlCond("SE1") + " AND " + RetSqlCond("DAK")
   cQuery += " AND E1_FILIAL = DAK_FILIAL AND E1_I_CARGA = DAK_COD "
EndIf 

cQuery += " WHERE SE1.D_E_L_E_T_ =' '  "

cQuery += " AND SE1.E1_FILIAL = '" + cFilAnt + "' "

If _lEmail  .Or. _lGerPDF
   cQuery += " AND SE1.E1_NUM = '" + SE1->E1_NUM + "' "
   cQuery += " AND SE1.E1_PARCELA = '" + SE1->E1_PARCELA + "' "
ElseIf _lWorkFlow
   cQuery += " AND SE1.E1_NUM = '" + SE1->E1_NUM + "' "
ElseIf !_lCallNfe 

   If !Empty(MV_PAR01) 
      cQuery += " AND E1_PREFIXO >= '" + MV_PAR01 +"' "
   EndIf   
    
   If !Empty(MV_PAR02) 
      cQuery += " AND E1_PREFIXO <= '" + MV_PAR02 +"' "
   EndIf   

   If !Empty(MV_PAR03)  
      cQuery += " AND E1_NUM >= '"+ MV_PAR03 +"' "
   EndIf   

   If !Empty(MV_PAR04)  
      cQuery += " AND E1_NUM <= '"+ MV_PAR04 +"' "
   EndIf   

   If !Empty(MV_PAR05)  
      cQuery += " AND E1_NUMBOR >= '"+ MV_PAR05 +"' "
   EndIf

   If !Empty(MV_PAR06)  
      cQuery += " AND E1_NUMBOR <= '"+ MV_PAR06 +"' "
   EndIf      

   If !Empty(MV_PAR15)
      cQuery += " AND DAK_DATA >= '"+ DToS(MV_PAR15) +"' " 
   EndIf 
    
   If !Empty(MV_PAR16)
      cQuery += " AND DAK_DATA <= '"+ DToS(MV_PAR16) +"' "
   EndIf 

ElseIf _lCallNfe
   cQuery += " AND CONCAT(SE1.E1_PREFIXO,SE1.E1_NUM) IN " + FormatIn(cDanNumNfe,";")
EndIf

cQuery += " AND SubStr(E1_TIPO,3,1) <> '-' "
cQuery += " AND (E1_TIPO = 'NF' OR E1_TIPO = 'ICM') " // "Tipo ICM foi incluído para atender os títulos gerados manualmente com o valor do ICMS ST pago antecipadamente pela Italac."
cQuery += " AND EXISTS (SELECT 1 FROM SA1010  SA1 "
cQuery += "             JOIN ACY010  ACY ON ACY.ACY_GRPVEN = SA1.A1_GRPVEN  AND ACY_I_BOLE  <> 'N' AND ACY.D_E_L_E_T_  = ' ' "
cQuery += "             WHERE A1_I_IBOLE <> 'N' AND SA1.D_E_L_E_T_  = ' ' AND SE1.E1_CLIENTE = SA1.A1_COD AND SE1.E1_LOJA = SA1.A1_LOJA ) "
cQuery += " AND (SELECT E4_I_IBOLE FROM " + RetSqlName('SE4') + " SE4, "  + RetSqlName('SF2') + " SF2 " 
cQuery += " WHERE SF2.D_E_L_E_T_ = ' ' AND SE4.D_E_L_E_T_ = ' ' " 
cQuery += "   AND SF2.F2_COND = SE4.E4_CODIGO  "
cQuery += "   AND SF2.F2_FILIAL  = SE1.E1_FILIAL "
cQuery += "   AND SF2.F2_DOC     = SE1.E1_NUM "
cQuery += "   AND (SF2.F2_SERIE   = SE1.E1_PREFIXO OR SE1.E1_PREFIXO = 'R' OR SE1.E1_PREFIXO = 'MAN') "
cQuery += "   AND SF2.F2_CLIENTE = SE1.E1_CLIENTE "
cQuery += "   AND SF2.F2_LOJA    = SE1.E1_LOJA) <> 'N' "

If !Empty(AllTrim(MV_PAR17)) .And. !_lCallNfe .And. !_lEmail  .And. !_lWorkFlow .And. !_lGerPDF
   cQuery += " AND E1_I_CARGA          IN "+ FormatIn(MV_PAR17,";") 
EndIf

cQuery += " AND E1_SALDO > 0 "

If !Empty( AllTrim(MV_PAR14) ) .And. !_lCallNfe .And. !_lEmail .And. !_lWorkFlow .And. !_lGerPDF
   cQuery += " AND E1_I_FCOB = '"+ MV_PAR14 +"' "
EndIf

If ! Empty(MV_PAR19)
   cQuery += " AND E1_EMISSAO >= '"+ DToS(MV_PAR19) +"' "  
EndIf 

If ! Empty(MV_PAR20)
   cQuery += " AND E1_EMISSAO <= '"+ DToS(MV_PAR20) +"' "  
EndIf 

If ! Empty(MV_PAR21)
   cQuery += " AND E1_CLIENTE >= '"+ MV_PAR21 +"' "     
EndIf 

If ! Empty(MV_PAR22)
   cQuery += " AND E1_LOJA >= '"+ MV_PAR22 +"' " 
EndIf 

If ! Empty(MV_PAR23) 
   cQuery += " AND E1_CLIENTE <= '"+ MV_PAR23 +"' "
EndIf 

If ! Empty(MV_PAR24)
   cQuery += " AND E1_LOJA <= '"+ MV_PAR24 +"' " 
EndIf 

If _lCallNfe .Or. !Empty(AllTrim(MV_PAR17)) .Or. _lEmail .Or. _lWorkFlow .Or. _lGerPDF
   cQuery += " ORDER BY E1_FILIAL, E1_NUM, E1_PARCELA"
Else
   cQuery += " ORDER BY E1_FILIAL, E1_I_CARGA, E1_NUM, E1_PARCELA"
EndIf

MPSysOpenQuery( cQuery , "FIN")

DBSelectArea("FIN")
FIN->( DBGoTop() )

While FIN->(!Eof())

   _lContintua := U_F150EXCCli(FIN->E1_CLIENTE,FIN->E1_FILIAL,FIN->E1_NUM,FIN->E1_PREFIXO)
   
   If _lContintua
      DBSelectArea("TRB")
      RecLock( "TRB" , .T. )
      
      TRB->E1_OK       := Space(02)
      TRB->E1_FILIAL   := FIN->E1_FILIAL
      TRB->E1_PREFIXO  := FIN->E1_PREFIXO
      TRB->E1_NUM      := FIN->E1_NUM
      TRB->E1_PARCELA  := FIN->E1_PARCELA
      TRB->E1_TIPO     := FIN->E1_TIPO
      TRB->E1_I_CARGA  := FIN->E1_I_CARGA
      TRB->E1_CLIENTE  := FIN->E1_CLIENTE
      TRB->E1_LOJA     := FIN->E1_LOJA
      TRB->E1_NOMCLI   := FIN->E1_NOMCLI
      TRB->E1_EMISSAO  := SToD(FIN->E1_EMISSAO)
      TRB->E1_VENCTO   := SToD(FIN->E1_VENCTO)
      If SE1->(FIELDPOS("E1_I_DTPRO")) <> 0
         If !Empty(FIN->E1_I_DTPRO)
            TRB->E1_VENCTO:= SToD(FIN->E1_I_DTPRO)
         EndIf
      EndIf
      TRB->E1_VENCREA  := SToD(FIN->E1_VENCREA)
      TRB->E1_VALOR    := FIN->E1_VALOR
      TRB->E1_SALDO    := FIN->E1_SALDO
      TRB->E1_NUMBCO   := FIN->E1_NUMBCO
      TRB->E1_PORTADO  := FIN->E1_PORTADO
      TRB->E1_AGEDEP   := FIN->E1_AGEDEP
      TRB->E1_CONTA    := FIN->E1_CONTA
      TRB->E1_DESCFIN  := FIN->E1_DESCFIN
      TRB->E1_TIPODES  := FIN->E1_TIPODES
      TRB->E1_DECRESC  := FIN->E1_DECRESC
      TRB->E1_NUMBOR   := FIN->E1_NUMBOR
      TRB->E1_I_DESCO  := FIN->E1_I_DESCO
      TRB->E1_I_ULBCO  := FIN->E1_I_ULBCO
      TRB->E1_I_ULCTA  := FIN->E1_I_ULCTA
      TRB->E1_I_ULAGE  := FIN->E1_I_ULAGE
      TRB->E1_I_ULSUB  := FIN->E1_I_ULSUB
      TRB->E1_I_NUMBC  := FIN->E1_I_NUMBC
      TRB->E1_IDCNAB   := FIN->E1_IDCNAB
      TRB->A1_EMAIL    := FIN->A1_EMAIL
      TRB->E1_VEND1    := FIN->E1_VEND1
      TRB->EA_APIMSG   := FIN->EA_APIMSG
      MSUnLock("TRB")
   EndIf

   FIN->(DBSkip())
EndDo

FIN->( DBCloseArea() )

Return

/*
===============================================================================================================================
Programa----------: RFIN002L
Autor-------------: Erick Buttner
Data da Criacao---: 19/03/2013
Descrição---------: Retorna a legenda de Status dos títulos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN002L() As Character

Local cRet	:= "" As Character
Local aArea	:= FWGetArea() As Array

If TRB->E1_SALDO == TRB->E1_VALOR
   cRet := ""
ElseIf TRB->E1_VALOR > TRB->E1_SALDO
   cRet := "1"
EndIf

FWRestArea(aArea)

Return( cRet )

/*
===============================================================================================================================
Programa----------: RFIN002S
Autor-------------: Alexandre Villar
Data da Criacao---: 19/02/2014
Descrição---------: Retorna as mensagens para imprimir no Boleto
Parametros--------: cCodBco , aDadosTit
Retorno-----------: aTxtMsg - Array com as mensagens de acordo com a configuração para o banco atual
===============================================================================================================================
*/
Static Function RFIN002S( cCodBco As Character, aDadosTit As Array ) As Array

Local aTxtMsg	:= {} As Array
Local cMsgAux	:= "" As Character
Local _lConfig	:= .F. As Logical

Default cCodBco	:= ""

//-- Se nao For informado o Banco, carregar mensagens padrao --//
If Empty( cCodBco )
   cCodBco := "000"
EndIf

//-- Procura o cadastro de Mensagens para o Banco atual --//
DBSelectArea("ZB2")
ZB2->( DBSetOrder(1) )
If ZB2->( DBSeek(xFilial("ZB2") + cCodBco ) )

   cMsgAux := AllTrim( &( MSMM( ZB2->ZB2_CDMSG1 ) ) )
   IIf( !Empty( cMsgAux ) , aAdd( aTxtMsg , cMsgAux ) , Nil )
   
   cMsgAux := AllTrim( &( MSMM( ZB2->ZB2_CDMSG2 ) ) )
   IIf( !Empty( cMsgAux ) , aAdd( aTxtMsg , cMsgAux ) , Nil )
   
   cMsgAux := AllTrim( &( MSMM( ZB2->ZB2_CDMSG3 ) ) )
   IIf( !Empty( cMsgAux ) , aAdd( aTxtMsg , cMsgAux ) , Nil )
   
   _lConfig := .T.
   
ElseIf !(cCodBco == "000")

   DBSelectArea("ZB2")
   ZB2->( DBSetOrder(1) )
   If ZB2->( DBSeek(xFilial("ZB2") + "000" ) )
      
      cMsgAux := AllTrim( &( MSMM( ZB2->ZB2_CDMSG1 ) ) )
      IIf( !Empty( cMsgAux ) , aAdd( aTxtMsg , cMsgAux ) , Nil )
      
      cMsgAux := AllTrim( &( MSMM( ZB2->ZB2_CDMSG2 ) ) )
      IIf( !Empty( cMsgAux ) , aAdd( aTxtMsg , cMsgAux ) , Nil )
      
      cMsgAux := AllTrim( &( MSMM( ZB2->ZB2_CDMSG3 ) ) )
      IIf( !Empty( cMsgAux ) , aAdd( aTxtMsg , cMsgAux ) , Nil )
      
      _lConfig := .T.
   
   EndIf
   
EndIf

If _lConfig
   
   If ZB2->ZB2_IMPDNF == 'S'
      
      cMsgAux := 'Referente ao Documento: '+ TRB->E1_FILIAL +'.'+ TRB->E1_PREFIXO +'.'+ TRB->E1_NUM +'.'+ TRB->E1_PARCELA +'.'+ TRB->E1_TIPO
      aAdd( aTxtMsg , cMsgAux )
      
   EndIf
   
EndIf

Return( aTxtMsg )

/*
===============================================================================================================================
Programa----------: RFIN002V
Autor-------------: Josué Danich Prestes
Data da Criacao---: 23/10/2015
Descrição---------: Retorna variáveis de banco/ag/conta/subconta a partir de cadastro  - Chamado 12253
Parametros--------: _ntipo : 	1 -	função chamada a partir de rotina automática, não deve apresentar perguntas
										mesmo que tiver mais de uma conta na filial pega automática a conta marcada com ZZJ_DEFAULT
										igual a "S"
									2 -	função chamada a partir da emissão manual de boleto, se tiver mais de uma conta para a filial
										deve apresentar o dial para o usuário escolher qual conta será usada
Retorno-----------: _lRet - Lógico, indica se usuário cancelou ou não seleção de conta e também se tem bco válido
===============================================================================================================================
*/
Static Function RFIN002V( _ntipo As Numeric )

Local _lRet := .T. As Logical
Local _aBco := {} As Array

Default _ntipo := 1   //1 não apresenta pergunta de dial para mais de uma conta na filial 

//============================================================
//Carrega bancos cadastrados para boleto para a filial atual
//============================================================

DBSelectArea("ZZJ")

If ZZJ->(DBSeek(xFilial("ZZJ")+AllTrim(cfilant)))

   While AllTrim(ZZJ->ZZJ_FILIAL) == AllTrim(xFilial("ZZJ")) .And. AllTrim(ZZJ->ZZJ_FILACE) == AllTrim(cfilant)
   
      aAdd(_aBco, {ZZJ->ZZJ_BANCO,ZZJ->ZZJ_CONTA,ZZJ->ZZJ_AGENCI,ZZJ->ZZJ_SUBCON,ZZJ->ZZJ_OPER,ZZJ->ZZJ_DEFAUL})
               //      1             2               3               4                5           6
      
      //Se tiver banco default nunca apresenta o Dial
      If ZZJ->ZZJ_DEFAUL == "S"
      
         _ntipo := 1
         
      EndIf
      
      ZZJ->( DBSkip() )
      
   EndDo
   
Else
   If !_lScheduler
      U_ITMsg("Não há banco/agenc/conta cadastrada para essa filial!","Alerta",,1)
   Else
      FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "RFIN00208"/*cMsgId*/, "RFIN00208 - Não há banco/agenc/conta cadastrada para essa filial!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   EndIf

   _lRet := .F.
   
EndIf

If Len(_aBco) == 0 .And. _lRet
   If !_lScheduler
      U_ITMsg("Não há banco/agenc/conta cadastrada para essa filial!","Alerta",,1)
   Else	
      FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "RFIN00209"/*cMsgId*/, "RFIN00209 - Não há banco/agenc/conta cadastrada para essa filial!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   EndIf

   _lRet := .F.	
   
EndIf

If Len(_aBco) > 1 .And. _lRet .And. _ntipo == 2

   //============================================================
   //Apresenta dial para escolha 
   //============================================================
   _nOpc := RFIN002C(_aBco)
   
   If _nOpc == 0
   
      _lRet := .F.
      
   EndIf
   
ElseIf Len(_aBco) > 1 .And. _lRet .And. _ntipo == 1

   //============================================================
   //Busca se têm bco default
   //============================================================
   _nOpc := aScan(_aBco,{|_vAux|_vAux[6]== "S"})
   
   //============================================================
   //se não achou nenhum default pega o primeiro
   //============================================================
   If _nOpc == 0
   
      _nOpc := 1
      
   EndIf
         
   
ElseIf Len(_aBco) == 1 .And. _lRet

   //============================================================
   //se só tem um resultado usa direto
   //============================================================
   _nOpc := 1
   
EndIf


//============================================================
//Se está tudo ok, carrega variáveis
//============================================================
If _lRet

   _cBancoP := AllTrim(_aBco[_nOpc][1])
   _cContaP :=	AllTrim(_aBco[_nOpc][2])
   _cSubcoP :=	AllTrim(_aBco[_nOpc][4])
   _cAgencP := AllTrim(_aBco[_nOpc][3])
   _cOperP  :=	AllTrim(_aBco[_nOpc][5])
   
EndIf

Return _lRet


/*
===============================================================================================================================
Programa----------: RFIN002C
Autor-------------: Josué Danich Prestes
Data da Criacao---: 26/10/2015
Descrição---------: Monta tela para consulta e seleção de banco do boleto
Parametros--------: _abancos - array com bancos encontrados para a filial
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN002C(_abancos As Array) As Numeric

Local _aParAux := {} As Array
Local _aParRet := {} As Array
Local _nNi     := 0 As Numeric
Local _aLista  := {} As Array
Local _cAntmv1 := MV_PAR01 As Character  //guarda MV_PAR01 para não atrapalhar a outra rotina

For _nNi := 1 to Len(_abancos)

   //		aAdd(_aBco, {ZZJ->ZZJ_BANCO,ZZJ->ZZJ_CONTA,ZZJ->ZZJ_AGENCI,ZZJ->ZZJ_SUBCON,ZZJ->ZZJ_OPER,ZZJ->ZZJ_DEFAUL})
   aAdd( _aLista, 	"Bco: " 		+ AllTrim(_abancos[_nNi][1])+;
                  " / Ag: "		+ AllTrim(_abancos[_nNi][3])+;
                  " / Cta:" 		+ AllTrim(_abancos[_nNi][2])+;
                  " / Sub: "		+ AllTrim(_abancos[_nNi][4])+;	
                  " /  "			+ SubStr(AllTrim(_abancos[_nNi][5]),1,14))
Next _nNi

aAdd( _aParAux , { 3 , "Selecione banco para o boleto:"		, 1						, _aLista			, 250 , ""	, .F. } )

For _nNi := 1 To Len( _aParAux )
   aAdd( _aParRet , _aParAux[_nNi][03] )
Next _nNI

If _lScheduler
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "RFIN00201"/*cMsgId*/, "RFIN00201 - Operação cancelada! Mais de um banco para selecao."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   Return(0)
Else
   If !ParamBox( _aParAux , "Parametrização do Relatório:" , @_aParRet )
      
      U_ITMsg("Operação cancelada pelo usuário!","Alerta",,1)
      Return(0)
      
   EndIf
EndIf

_nNi 		:= MV_PAR01
MV_PAR01 	:= _cAntmv1

Return(_nNi) 

/*
===============================================================================================================================
Programa----------: RFIN002D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 30/11/2021
Descrição---------: Validação da Digitação das opções de filtro.
Parametros--------: _cChamada = Parâmetro que chamou a validação.
Retorno-----------: _lRet = .T. = Validação Ok
                          = .F. = Erro nas validações.
===============================================================================================================================
*/
User Function RFIN002D(_cChamada As Character) As Logical
Local _lRet := .T. As Logical

Begin Sequence 

   If _cChamada == "DATACARGA1"
      
      If ! Empty(MV_PAR15 )
         If _lScheduler
            lRet := .F.
         Else
            //U_ITMsg(“Mensagem”, , , ,2, 2)
            If U_ITMsg("Quando uma opção de filtro de carga é selecionado as opções de filtro por data de emissão são desativadas. Confirma o filtro por data de carga Inicial?","Atenção" ,;
                        "As opções de filtros por data de emissão não serão considerados." , ,2, 2)
               MV_PAR19 := Ctod("  /  /  ")
               MV_PAR20 := Ctod("  /  /  ")
            Else 
               _lRet := .F.
            EndIf 
         EndIf
      EndIf 

   ElseIf _cChamada ==  "DATACARGA2"
      If ! Empty(MV_PAR16 )
         If _lScheduler
            _lRet := .F.
         Else
            If U_ITMsg("Quando uma opção de filtro de carga é selecionado as opções de filtro por data de emissão são desativadas. Confirma o filtro por data de carga Final?","Atenção" ,;
                        "As opções de filtros por data de emissão não serão considerados." , ,2, 2)
               MV_PAR19 := Ctod("  /  /  ")
               MV_PAR20 := Ctod("  /  /  ")
            Else 
                  _lRet := .F.
            EndIf
         EndIf
      EndIf 

   ElseIf _cChamada ==  "CARGA"
      If ! Empty(MV_PAR17)
         If _lScheduler
            _lRet := .F.
         Else
            If U_ITMsg("Quando uma opção de filtro de carga é selecionado as opções de filtro por data de emissão são desativadas. Confirma o filtro por carga?","Atenção" ,;
                        "As opções de filtros por data de emissão não serão considerados." , ,2, 2)
               MV_PAR19 := Ctod("  /  /  ")
               MV_PAR20 := Ctod("  /  /  ")
            Else 
                  _lRet := .F.
            EndIf 
         EndIf
      EndIf 

   ElseIf _cChamada ==  "DTEMISSAO1"
      If ! Empty(MV_PAR19)
         If !_lScheduler
            If U_ITMsg("Quando uma opção de filtro por data de emissão do título é selecionada, as opções de filtro por carga são desativadas. Confirma o filtro por data de emissão inicial?","Atenção" ,;
                        "As opções de filtros por carga não serão consideradas." , ,2, 2)
                  MV_PAR15 := Ctod("  /  /  ")
               MV_PAR16 := Ctod("  /  /  ")
               MV_PAR17 := Space(6)
            Else 
                  _lRet := .F.
            EndIf 
         EndIf
      EndIf 

   ElseIf _cChamada ==  "DTEMISSAO2"
      If ! Empty(MV_PAR20)
         If !_lScheduler
            If U_ITMsg("Quando uma opção de filtro por data de emissão do título é selecionada, as opções de filtro por carga são desativadas. Confirma o filtro por data de emissão final?","Atenção" ,;
                     "As opções de filtros por carga não serão consideradas." , ,2, 2)
                  MV_PAR15 := Ctod("  /  /  ")
               MV_PAR16 := Ctod("  /  /  ")
               MV_PAR17 := Space(6)
            Else 
                  _lRet := .F.
            EndIf 
         EndIf
      EndIf 
     
   EndIf 

End Sequence 

Return _lRet 

/*
===============================================================================================================================
Programa----------: AjustaPath
Autor-------------: Igor Melgaco
Data da Criacao---: 27/02/2024
Descrição---------: Trata endereço de diretorio de acordo com o SO
Parametros--------: _cCaminho
Retorno-----------: _cCaminho
===============================================================================================================================
*/
Static Function AjustaPath(_cCaminho As Character) As Character
Local _nAux := 0 As Numeric

If IsSrvUnix()
   _cCaminho := AllTrim(Lower(_cCaminho))
   For _nAux := 1 to Len(_cCaminho)
       If SubStr(_cCaminho,_nAux,1) = "\"
            _cCaminho := Stuff(_cCaminho,_nAux,1,"/")
       EndIf
   Next _nAux
EndIf

Return _cCaminho

/*
===============================================================================================================================
Programa----------: RFIN002P
Autor-------------: Julio Paz
Data da Criacao---: 07/07/25
Descrição---------: Rotina para impressão do Boleto Gráfico
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RFIN002P()
Local _cRet := ""
Private cFilePrint := "" As Character

Begin Sequence 

   _lGerPDF := .T.

   U_RFIN002() // Chama a rotina de geração de Boletos.

   _lGerPDF := .F.

   If ValType(cFilePrint) <> "C"
      cFilePrint := ""
   EndIf

   _cRet := AllTrim(cFilePrint)

End Sequence 

Return _cRet 
