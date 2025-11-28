/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |07/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
Alex Wallauer |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST046
Autor-------------: Alex Wallauer
Data da Criacao---: 27/03/2019
Descrição---------: Cadastro de Regras de Calculo de custo do ICMS - CHAMADO 28650
Parametros--------: Nenhum 
Retorno-----------: Nenhum 
===============================================================================================================================
*/
User Function AEST046

Private cCadastro 	:= "Calculo de custo do ICMS"
Private aRotina   	:= {}
Private aCores    	:= {}
Private aLegenda 	:= {} 

aLegenda 	:= {{"BR_VERMELHO","Bloqueado"}, {"BR_VERDE", "Ativo"}} 

aAdd(aRotina,{"Pesquisar" 	,"AxPesqui"  	 ,0,1 })//1
aAdd(aRotina,{"Executar"	,"U_AEST046I"   ,0,2 })//2
aAdd(aRotina,{"Incluir"		,"U_AEST046I"	 ,0,3 })//3
aAdd(aRotina,{"Alterar"		,"U_AEST046I"   ,0,4 })//4
aAdd(aRotina,{"Visualizar"	,"U_AEST046I"   ,0,2 })//5
aAdd(aRotina,{"Excluir"		,"U_AEST046I"   ,0,5 })//6
aAdd(aRotina,{"Copiar"		,"U_AEST046I"   ,0,4 })//7
aAdd(aRotina,{"Historico"  ,"U_AEST046I"   ,0,4 })//8
aAdd(aRotina,{"Legenda"		,"BrwLegenda('Status das regras','Legenda',aLegenda)",0,7 })
aAdd(aCores,{"ZM0_MSBLQL <> '1'","BR_VERDE" })   
aAdd(aCores,{"ZM0_MSBLQL = '1'" ,"BR_VERMELHO" })    

_aItalac_F3:={}
_cSelectSB1:="SELECT B1_COD, B1_DESC FROM "+RETSQLNAME("SB1")+" SB1 WHERE B1_TIPO IN ('MP','PP','PI') AND D_E_L_E_T_ = ' ' ORDER BY B1_COD " 
//   _aItalac_F3:={}         1           2         3                                4             5          6                             7         8          9         10         11        12
//DD(_aItalac_F3,{"1CPO_CAMPO1"  ,_cTabela   ,_nCpoChave                     , _nCpoDesc     , _bCondTab , _cTitAux                   , _nTamChv , _aDados , _nMaxSel , _lFilAtual,_cMVRET,_bValida})  
aAdd(_aItalac_F3,{"M->ZM0_MPCONS",_cSelectSB1,{|Tab| AllTrim((Tab)->B1_COD) }, {|Tab| (Tab)->B1_DESC } , ,"Produtos Tipos: [MP,PP,PI]",          ,         , 40       ,.F.        ,       , } )

DBSelectArea("ZM0")
ZM0->(DBSetOrder(1))
ZM0->(DBGoTop())

mBrowse(,,,,"ZM0",,,,, ,aCores)

Return(.T.)

/*
===============================================================================================================================
Programa----------: AEST046I
Autor-------------: Alex Wallauer
Data da Criacao---: 27/03/2019
Descrição---------: Rotina de ações do mbrowse 
Parametros--------: _nOpc: 1 - Ececutar / 7 - Copiar
Retorno-----------: .T.
===============================================================================================================================
*/
User Function AEST046I(cAlias,nReg,_nOpc)

Local nI
Local _lRetMod3:= .F.
Local _aarea	:= FWGetArea()
Local _nReg		:= ZM0->( Recno() )
Local aObjects := {}
Local _aParRet :={}
Local _aParAux :={} 
Local _bOK     :={|| If(MV_PAR02 >= MV_PAR01,.T.,(U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo",3),.F.) ) }
Private _lLog  := .F.

If _nOpc = 2

   MV_PAR01:=dDataBase
   MV_PAR02:=dDataBase
   MV_PAR03:="1–Estornar cred x Estrutura "
   MV_PAR04:="212020;212021"+Spave(100)
   MV_PAR05:="232016"+Spave(100)
   MV_PAR06:=Spave(100)//"313001"+
   MV_PAR07:="4–Nenhum                  "
   MV_PAR08:=0
   MV_PAR09:=0
   MV_PAR10:=0
   MV_PAR11:=Spave(100)
   MV_PAR12:=Spave(100)
   MV_PAR13:="1–Geral           "
   MV_PAR14:="4–Nenhum             "
   MV_PAR15:="2–Nao"
   MV_PAR16:="2–Nao"
   
   _aOpcao3:={}
   aAdd( _aOpcao3 , "1–Estornar cred x Estrutura ")
   aAdd( _aOpcao3 , "2–Estornar cred x Percentual")
   aAdd( _aOpcao3 , "3–Nenhum                    ") 

   _aOpcoes:={}
   aAdd( _aOpcoes , "1–Estorna cred x Estrutura")
   aAdd( _aOpcoes , "2–Estorna cred x operacao ")
   aAdd( _aOpcoes , "3–Credita pela operacao   ")
   aAdd( _aOpcoes , "4–Nenhum                  ") 
   
   _aOpca13:={}
   aAdd( _aOpca13 , "1–Geral           ")
   aAdd( _aOpca13 , "2–Somente Produção")

   _aOpca14:={}
   aAdd( _aOpca14 , "1–Anulacao de Credito")
   aAdd( _aOpca14 , "2–Glosa de Credito   ")
   aAdd( _aOpca14 , "3–Ambos              ")
   aAdd( _aOpca14 , "4–Nenhum             ")

   _aOpca15:={}
   aAdd( _aOpca15 , "1–Sim")
   aAdd( _aOpca15 , "2–Nao")

   aAdd( _aParAux , { 1 , "Data de" 	             , MV_PAR01, "@D", "", ""	    , "", 050, .T.})
   aAdd( _aParAux , { 1 , "Data ate"	             , MV_PAR02, "@D", "", ""	    , "", 050, .T.})
   aAdd( _aParAux , { 2 , "Quanto a perda"           , MV_PAR03, _aOpcao3         ,090,".T.",.T.}) 
   aAdd( _aParAux , { 1 , "Naturezas Desp. Programa ", MV_PAR04, "@!", "", "LSTNAT","", 100, .T.}) 
   aAdd( _aParAux , { 1 , "Naturezas Multas Fiscais ", MV_PAR05, "@!", "", "LSTNAT","", 100, .T.}) 
   aAdd( _aParAux , { 1 , "Naturezas Bolsa Garantia ", MV_PAR06, "@!", "", "LSTNAT","", 100, .F.}) 
   aAdd( _aParAux , { 2 , "Quanto a ZFM?"            , MV_PAR07, _aOpcoes         ,090,".T.",.T.}) 
   aAdd( _aParAux , { 1 , "% Programa financiado "   , MV_PAR08, "@E 999.99","","","",040 ,  .F.})
   aAdd( _aParAux , { 1 , "% Bolsa Garantia s/ finan", MV_PAR09, "@E 999.99","","","",040 ,  .F.})
   aAdd( _aParAux , { 1 , "% Protege s/ financiado " , MV_PAR10, "@E 999.99","","","",040 ,  .F.})
   aAdd( _aParAux , { 1 , "Debito / Codigo Apur ICMS", MV_PAR11, "@!"      , "", "","", 100, .F.}) 
   aAdd( _aParAux , { 1 , "Credito/ Codigo Apur ICMS", MV_PAR12, "@!"      , "", "","", 100, .F.}) 
   aAdd( _aParAux , { 2 , "Rateio Codigo Apur ICMS"  , MV_PAR13, _aOpca13         ,090,".T.",.F.}) 
   aAdd( _aParAux , { 2 , "Soma em Outros Debitos"   , MV_PAR14, _aOpca14         ,090,".T.",.T.}) 
   aAdd( _aParAux , { 2 , "Ratear Sobra Cred.Producao",MV_PAR15, _aOpca15         ,090,".T.",.T.}) 
   aAdd( _aParAux , { 2 , "Desc. Benef. LP recebido Transf.",MV_PAR16, _aOpca15   ,090,".T.",.T.}) 

   
   For nI := 1 To Len( _aParAux )
   	aAdd( _aParRet , _aParAux[nI][03] )
   Next nI

             //aParametros, cTitle       , @aRet    ,[bOk], [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
   If !ParamBox( _aParAux , "Parametros" , @_aParRet, _bOK, /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
	  Return .T.
   EndIf
   //MsNewProcess(): New ( [ bAction], [ cTitle], [ cMsg], [ lAbort] )    
   cHoraIni:=Time()
   oProcess:= MsNewProcess():New({|_lEnd,oProcess| AEST046E(@oProcess, @_lEnd) },"Calculo de custo do ICMS - H.I.: "+cHoraIni,"Processando",.T.) 
   oProcess:Activate()

   Return .T.

 ElseIf _nOpc = 8

   DBSelectArea("ZM1")
   ZM1->(DBSetOrder(1))
   ZM1->(DBGoTop())

   aOldRotina:=aClone(aRotina)
   aRotina:={}
   aAdd(aRotina,{"Pesquisar" 	,"AxPesqui"  	 ,0,1 })
   aAdd(aRotina,{"Visualizar"	,"AxVisual"     ,0,2 })

   mBrowse(,,,,"ZM1")

   aRotina:=aOldRotina

   Return .T.

EndIf

cCadastro:= "Calculo de custo do ICMS - "+If(_nOpc = 8,"COPIA","") 
Private cAlias1:="ZM0"
Private aGets:={}
Private aTela:={}

Regtomemory(cAlias1,(_nOpc=3))

If _nOpc <> 3

     DBSelectArea("ZM0")
     If Bof() .And. Eof()
        Return _nOpc
     EndIf
     For nI := 1 To FCount()
        M->&(FIELDNAME(nI)) := FieldGet(nI)
     Next
	If _nOpc == 7 // Copia
	   M->ZM0_CODEVE:= U_AEST046G() //Caso seja copia valida ultimo cod. de numero do evento
	EndIf	
EndIf 

aSize:= MsAdvSize()
aInfo:= { aSize[1] , aSize[2] , aSize[3] , aSize[4] , 3 , 3 }
aAdd( aObjects , { 100 , 050 , .T. , .F. , .F. } )
aAdd( aObjects , { 100 , 100 , .T. , .T. , .F. } )
aPosObj := MsObjSize( aInfo , aObjects )
//====================================================================
//Abre tela de visulização do registro
//====================================================================
DEFINE MSDIALOG oDlg TITLE cCadastro From 9,0 To 35,170 //of oMainWnd

	oEnCh1:=MsMget():New(cAlias1,_nReg,_nOpc,,,,,{15,aPosObj[2,2],aPosObj[2,3],aPosObj[2,4]},,3,,,,,,.F.)
	oDlg:lMaximized:=.T.
	
ACTIVATE MSDIALOG oDlg ON INIT (EnchoiceBar(oDlg,{|| If(Obrigatorio(aGets,aTela) .And. AEST46Val(),(oDlg:End(),_lRetMod3:=.T.),.F.)},{||oDlg:End()},,) , oEnCh1:oBox:Align:=CONTROL_ALIGN_ALLCLIENT)


If _lRetMod3 .And. ( (_nOpc == 3 ) /* Inclusão */ .Or. (_nOpc == 7 )) // Copia
   If ZM0->(DBSeek(xFilial("ZM0")+M->ZM0_CODEVE))
      M->ZM0_CODEVE:= U_AEST046G() //Caso seja copia valida ultimo cod. de numero do evento
   EndIf
   ZM0->(RecLock("ZM0",.T.))
   AVREPLACE("M","ZM0")
	ZM0->ZM0_FILIAL:=xFilial("ZM0") 
	ZM0->(MSUnLock())
ElseIf _lRetMod3 .And. (_nOpc == 4 ) // Alteração
   ZM0->(RecLock("ZM0",.F.))
   AVREPLACE("M","ZM0")
	ZM0->ZM0_FILIAL:=xFilial("ZM0") 
	ZM0->(MSUnLock())
ElseIf _lRetMod3 .And. (_nOpc == 6 ) // Exclusão
   ZM0->(RecLock("ZM0",.F.))
	ZM0->(DbDelete())
	ZM0->(MSUnLock())
Else
	If _nOpc == 3 .Or. _nOpc == 7
		RollBackSX8()
	EndIf
EndIf

FWRestArea(_aarea)

Return .T.

/*
===============================================================================================================================
Programa----------: AEST046G
Autor-------------: Alex Wallauer
Data da Criacao---: 27/03/2019
Descrição---------: Rotina para retornar próximo código , usada no dicionario campo "ZM0_CODEVE"
Parametros--------: Ver descrição abaixo
Retorno-----------: _ccod - próximo valor 
===============================================================================================================================
*/
User Function AEST046G

Local _ccod 	:= "000001"
Local _cAlias  := GetNextAlias()
Local _aarea	:= FWGetArea()

BeginSql alias _cAlias
   SELECT MAX(ZM0_CODEVE) CODI
   FROM %Table:ZM0%
   WHERE ZM0_FILIAL = %xFilial:ZM0%
   AND ZM0.D_E_L_E_T_ = ' '
EndSql
	
If (_cAlias)->(!Eof())
	_ccod := StrZero( ( Val((_cAlias)->CODI) + 1 ), Len(ZM0->ZM0_CODEVE) )
EndIf

(_cAlias)->(DBCloseArea())

FWRestArea(_aarea)

Return _ccod

/*
===============================================================================================================================
Programa----------: AEST046E()
Autor-------------: Alex Wallauer
Data da Criacao---: 27/03/2019
Descricao---------: Calcula e Grava dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================*/
Static Function AEST046E(_oSelf,_lEnd)

Local nConta := 0 , I  , T
Local nTotal := 0 , _nQtde
Private aDadosCalc :={}
Private aDadosTela :={}
Private _cEstFilAnt:= Posicione("ZZM",1,xFilial("ZZM")+cFilAnt,"ZZM_EST")
Private _cValores:=""

_oSelf:SetRegua1( 0 )
_oSelf:SetRegua2( 0 )
_oSelf:IncRegua1("Iniciando os trabalhos, Aguarde..." )
_oSelf:IncRegua2("Iniciando os trabalhos, Aguarde..." )

DBSelectArea("ZM0")
ZM0->(DBSetOrder(1))
ZM0->(DBSeek(xFilial()))

MV_PAR01 := AllTrim(Str(Year(MV_PAR01))) + StrZero((Month(MV_PAR01)),2)+"01"
If Month(SToD(MV_PAR01)) < 12
   MV_PAR02 := DToS(SToD( AllTrim(Str(Year(SToD(MV_PAR01)))) + StrZero( Month(SToD(MV_PAR01))+1 ,2)+"01" ) - 1)
Else
   MV_PAR02 := AllTrim(Str((Year(SToD(MV_PAR01)))) + "1231")
EndIf

aCampos:={}
aAdd(aCampos,{"ZM1_DATARQ","Periodo"     ,035})//01
aAdd(aCampos,{"ZM1_CODEVE","Evento"      ,070})//02
//Valores
aAdd(aCampos,{"ZM1_VLROP" ,"B-Vlr Saidas",050})//03
aAdd(aCampos,{"ZM1_ICMSAI","D-ICMS saida",050})//04
aAdd(aCampos,{"ZM1_CREDS" ,"C-Beneficio" ,050})//05
aAdd(aCampos,{"ZM1_VLROPD","B-Devolucoes",050})//06
aAdd(aCampos,{"ZM1_ICMSD" ,"C-Cred Dev"  ,050})//07
aAdd(aCampos,{"ZM1_ESTCRD","D-Estorn bnf",050})//08
aAdd(aCampos,{"ZM1_ICMAPG","D-Icm a Pagr",050})//09
aAdd(aCampos,{"ZM1_DBBENF","D-Deb s/ Bnf",050})//10
aAdd(aCampos,{"ZM1_DBVND" ,"D-Deb s/ Vnd",050})//11
aAdd(aCampos,{"ZM1_ESTPRD","D-Estn perda",050})//12
aAdd(aCampos,{"ZM1_JUROSI","D-Desp progr",050})//13
aAdd(aCampos,{"ZM1_MTFISC","D-Multa Fisc",050})//14
aAdd(aCampos,{"ZM1_BGARAN","D-Bls Garant",050})//15
aAdd(aCampos,{"ZM1_OCRED" ,"C-Outros Crd",050})//16
aAdd(aCampos,{"ZM1_DESP"  ,"Total Despes",050})//17
aAdd(aCampos,{"ZM1_CUSICM","% Custo ICMS",050})//18
//NOVOS
aAdd(aCampos,{"ZM1_PRSPRD","C-Presm Prod",050})//19
aAdd(aCampos,{"ZM1_PRSOPE","C-Presm Oper",050})//20
aAdd(aCampos,{"ZM1_CDBENF","C-Crd S/ Bnf",050})//21
aAdd(aCampos,{"ZM1_ODEB"  ,"D-Outros Deb",050})//22

// VARIAVEIS DE LOG
_cLogQuerys:=CRLF
_cTeste:=CRLF
_cVal2:=CRLF
_cVal2+="ZM0->ZM0_CODEVE;_nZM1_PRSOPE:=; ((_nQuantVLROP;-_nQuant); * _nRen ); * _nMix ;* (ZM0->ZM0_PRSOPE/100);ou ZM0->ZM0_LMT1P"+CRLF
_cVal3:=CRLF
_cVal3+="ZM0->ZM0_CODEVE+;+aProComprados[T,1]+;+Str(aTp_EM_IN[nPos,2],22,7)+;+Str(aProComprados[T,2],22,7)+;+Str((aProComprados[T,3]),22,7)"+CRLF
// VARIAVEIS DE LOG

cTot:="/16"
_oSelf:SetRegua1( 15 )
_oSelf:SetRegua2( 00 )
nSeq:=1

nSeq++
_cSeq:=StrZero(nSeq,2)+cTot
_oSelf:IncRegua1(_cSeq+" - Executando Leitura de Valores para Rateio" )

_nEPSE :=0 
If MV_PAR03 = "1" //Estornar cred x estrutura
   _oSelf:SetRegua2( 3 )
   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno de perda sem estrutura1/3" )
   aProdutos:=AEST046R(_oSelf,_lEnd,"SELECT_EPSE_MV03=1")//SEM ESTRUTURA

   cProd_EN_IN:=""//Preenchido ABAIXO e Variavel cProd_EN_IN usa na AEST046R(_oSelf,_lEnd,"SELECT_05_COM_DT")
   For T := 1 To Len(aProdutos)
       If !aProdutos[T,1]  $ cProd_EN_IN
          cProd_EN_IN+=aProdutos[T,1]+";"
       EndIf   
   Next T
   aTp_EM_IN:=aClone(aProdutos)

   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno Credito x Estrutura 2/3" )
   _cValores+="SELECT_EPSE_MV03=1;cProd_EN_IN: ; "+cProd_EN_IN+";"+Str(Len(aTp_EM_IN),22)+CRLF
   aProCompDT:=AEST046R(_oSelf,_lEnd,"SELECT_05_COM_DT")

   cProd_SEM_DT:=""
   For T := 1 To Len(aTp_EM_IN)
       If aScan(aProCompDT , {|P| P[1] == aTp_EM_IN[T,1]  })  = 0
          cProd_SEM_DT+=aTp_EM_IN[T,1]+";"
       EndIf   
   Next T

   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno Credito x Estrutura 3/3" )
   _cValores+="SELECT_EPSE_MV03=1;cProd_SEM_DT: ; "+cProd_SEM_DT+CRLF
   cProd_EN_IN:=cProd_SEM_DT//Variavel cProd_EN_IN Usa na AEST046R(_oSelf,_lEnd,"SELECT_05_SEM_DT")
   aProComprados:=AEST046R(_oSelf,_lEnd,"SELECT_05_SEM_DT")//SELECT SEM FILTRO DE DATA
   For T := 1 To Len(aProCompDT)
       aAdd(aProComprados,aProCompDT[T])
   Next T
   _nEPSE :=0 
   For T := 1 To Len(aProComprados)
       If (nPos:=aScan(aTp_EM_IN , {|P| P[1] == aProComprados[T,1]  } )) <> 0       
          _nEPSE +=  ( aTp_EM_IN[nPos,2] * aProComprados[T,2] * aProComprados[T,3] )
          _cValores+="SELECT_EPSE_MV03=1;"+aProComprados[T,1]+";"+Str(aTp_EM_IN[nPos,2],22,7)+";"+Str(aProComprados[T,2],22,7)+";"+Str((aProComprados[T,3]),22,7)+CRLF
       EndIf
   Next T

ElseIf MV_PAR03 = "2"
   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno de perda sem estrutura..." )
   _nEPSE:=AEST046R(_oSelf,_lEnd,"SELECT_EPSE")//SEM ESTRUTURA
EndIf
_oSelf:SetRegua2( 0 )

nSeq++
_cSeq:=StrZero(nSeq,2)+cTot
_oSelf:IncRegua1(_cSeq+" - Executando Leitura de Valores para Rateio" )
_oSelf:IncRegua2(_cSeq+" - Lendo Anulacao de Credito..." )
_nAnulaCred:=0
If MV_PAR14 = "1" .Or. MV_PAR14 = "3"
   _nAnulaCred:=AEST046R(_oSelf,_lEnd,"SELECT_ANULACAO_CREDITO")
EndIf

nSeq++
_cSeq:=StrZero(nSeq,2)+cTot
_oSelf:IncRegua1(_cSeq+" - Executando Leitura de Valores para Rateio" )
_oSelf:IncRegua2(_cSeq+" - Lendo Glosa de Credito..." )
_nGlosaCred:=0
If MV_PAR14 = "2" .Or. MV_PAR14 = "3"
   _nGlosaCred:=AEST046R(_oSelf,_lEnd,"SELECT_GLOSA_CREDITO")
EndIf

nSeq++
_cSeq:=StrZero(nSeq,2)+cTot
_oSelf:IncRegua1(_cSeq+" - Executando Leitura de Valores para Rateio" )
_oSelf:IncRegua2(_cSeq+" - Lendo Deb/cod apur ICMS..." )

_nDebApurICMS:=0
If !Empty(MV_PAR11)
   _nDebApurICMS:=AEST046R(_oSelf,_lEnd,"SELECT_DEB_COD_APUR_ICMS")
EndIf

_nCredApurICMS:=0
If !Empty(MV_PAR12)
   _nCredApurICMS:=AEST046R(_oSelf,_lEnd,"SELECT_CRE_COD_APUR_ICMS")
EndIf

nSeq++
_cSeq:=StrZero(nSeq,2)+cTot
_oSelf:IncRegua1(_cSeq+" - Executando Leitura de Valores para Rateio" )
_oSelf:IncRegua2(_cSeq+" - Lendo Despesas do programa..." )
_nDP:=AEST046R(_oSelf,_lEnd,"SELECT_DP")

nSeq++
_cSeq:=StrZero(nSeq,2)+cTot
_oSelf:IncRegua1(_cSeq+"- Executando Leitura de Valores para Rateio" )
_oSelf:IncRegua2(_cSeq+"- Lendo Multas fiscais..." )
_nMF:=AEST046R(_oSelf,_lEnd,"SELECT_MF")

nSeq++
_cSeq:=StrZero(nSeq,2)+cTot
_oSelf:IncRegua1(_cSeq+" - Executando Leitura de Valores para Rateio" )
_oSelf:IncRegua2(_cSeq+" - Lendo Bolsa Garantia..." )

_nBG:=0
If !Empty(MV_PAR06)
   _nBG:=AEST046R(_oSelf,_lEnd,"SELECT_BG_SE5")
   If _nBG = 0
      _nBG:=AEST046R(_oSelf,_lEnd,"SELECT_BG_SE2")
   EndIf   
EndIf

nSeq++
_cSeq:=StrZero(nSeq,2)+cTot
_oSelf:IncRegua1(_cSeq+" - Executando Leitura de Valores para Rateio" )
_oSelf:IncRegua2(_cSeq+" - Lendo Valor do Mix do Leite..." )
_nMixVLR:=AEST046R(_oSelf,_lEnd,"SELECT_MIX_VLR")

nSeq++
_cSeq:=StrZero(nSeq,2)+cTot
_oSelf:IncRegua1(_cSeq+" - Executando Leitura de Valores para Rateio" )
_oSelf:IncRegua2(_cSeq+"- Lendo Volme do Mix do Leite..." )
_nMixVOL:=AEST046R(_oSelf,_lEnd,"SELECT_MIX_VOL")
_nMix:=_nMixVLR / _nMixVOL

nSeq++
_cSeq:=StrZero(nSeq,2)+cTot
_oSelf:IncRegua1(_cSeq+" - Executando Leitura de Valores" )
_oSelf:IncRegua2(_cSeq+" - Lendo Rendimento do integral..." )
_cTipo:= "INTEGRAL"
_aRenUnt:=AEST046R(_oSelf,_lEnd,"SELECT_GRUPO_002")

nSeq++
_cSeq:=StrZero(nSeq,2)+cTot
_oSelf:IncRegua1(_cSeq+" - Executando Leitura de Valores" )
_oSelf:IncRegua2(_cSeq+" - Lendo Rendimento do desnatado..." )
_cTipo:= "DESNATADO"
_aRenDes:=AEST046R(_oSelf,_lEnd,"SELECT_GRUPO_002")

nSeq++
_cSeq:=StrZero(nSeq,2)+cTot
_oSelf:IncRegua1(_cSeq+" - Executando Leitura de Valores" )
_oSelf:IncRegua2(_cSeq+" - Lendo Rendimento do desnatado..." )
_cTipo:= "LEITE CONDESADO"
_aRenLCon:=AEST046R(_oSelf,_lEnd,"SELECT_GRUPO_002")

nSeq++
_cSeq:=StrZero(nSeq,2)+cTot
_oSelf:IncRegua1(_cSeq+" - Executando Calculo da Necessidade" )

nTotLP   :=0
If MV_PAR16 = "1"//Valor Desconciderado LP Recebido em Transferencia

   nQtdBaseI:=0
   nQtdBaseD:=0
   nTotLP   :=0
   _aNeceI  :={}
   _aNeceD  :={}

   _oSelf:SetRegua2( 4 )

   _oSelf:IncRegua2(_cSeq+" - Lendo Desc Benef LP Integral 1/4" )
   nQtdBaseI:=AEST046R(_oSelf,_lEnd,"SELECT_DESC_BENEF_LP_INTEGRAL")

   If nQtdBaseI > 0

		_oSelf:IncRegua2(_cSeq+" - Lendo Necessidade Integral 2/4" )

		aTab:=AEST046R(_oSelf,_lEnd,"SELECT_NECESSIDADE_INTEGRAL")
		//aAdd(_aTab,{TRB->D3_COD,     //1
		//            TRB->PERC_PRD,   //2
		//            TRB->MINVENDA,   //3
		//            TRB->B1_CONV,    //4
		//            TRB->B1_TIPCONV})//5
        _aNeceI:=AEST046Necess( nQtdBaseI , aTab )
   EndIf

   _oSelf:IncRegua2(_cSeq+" - Lendo Desc Desc Benef LP Desnatado 3/4" )
   nQtdBaseD:=AEST046R(_oSelf,_lEnd,"SELECT_DESC_BENEF_LP_DESNATADO")

   If nQtdBaseD > 0
       _oSelf:IncRegua2(_cSeq+" - Lendo Necessidade Desnatado 4/4" )

       aTab:=AEST046R(_oSelf,_lEnd,"SELECT_NECESSIDADE_DESNATADO")
		//aAdd(_aTab,{TRB->D3_COD,     //1
		//            TRB->PERC_PRD,   //2
		//            TRB->MINVENDA,   //3
		//            TRB->B1_CONV,    //4
		//            TRB->B1_TIPCONV})//5
       _aNeceD:= AEST046Necess( nQtdBaseD , aTab )
   EndIf

   nTotLP:=0
   If Len(_aNeceI) > 0
      For I := 1 To Len(_aNeceI) 
          //FCalcVlrLPI_noBenfic( aTab[I,1] , ( nPerQtde + _aNece[Len(_aNece),2] ) - nResto , _nMINVENDA )
          _aNeceI[I,5] := FCalcVlrLPI_noBenfic(_aNeceI[I,1] , _aNeceI[I,3], _aNeceI[I,4])
          nTotLP+=_aNeceI[I,5]
      Next I   
   EndIf

   If Len(_aNeceD) > 0
      For I := 1 To Len(_aNeceD) 
          //FCalcVlrLPI_noBenfic( aTab[I,1] , ( nPerQtde + _aNece[Len(_aNece),2] ) - nResto , _nMINVENDA )
          _aNeceD[I,5] := FCalcVlrLPI_noBenfic(_aNeceD[I,1] , _aNeceD[I,3], _aNeceD[I,4])
          nTotLP+=_aNeceD[I,5]
      Next I 
   EndIf
EndIf

_cSeq:=StrZero(nSeq,2)+cTot
_oSelf:IncRegua1(_cSeq+" - Executando Leitura de Valores para Rateio" )

_nEPCE :=0 
If MV_PAR03 = "1" //Estornar cred x estrutura
   _oSelf:SetRegua2( 4 )
   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno de perda com estrutura 1/4" )
   aProdutos:=AEST046R(_oSelf,_lEnd,"SELECT_EPCE")//COM ESTRUTURA
   
   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno de perda com estrutura 2/4" )
   
   cProd_EN_IN:=""//Preenchido na função AEST46EStr(aProdutos) e Variavel cProd_EN_IN usa na AEST046R(_oSelf,_lEnd,"SELECT_05_COM_DT")
   aTp_EM_IN:=AEST46EStr(aProdutos)///EXPLODE A ESTRURA
   aProdutos:=AEST046R(_oSelf,_lEnd,"SELECT_EPCE_2")//('IN','EM','MC') //COM ESTRUTURA
   
   For T := 1 To Len(aProdutos)
       If aScan(aTp_EM_IN , {|P| P[1] == aProdutos[T,1]  })  = 0
          cProd_EN_IN+=aProdutos[T,1] +";"
          _cValores+="LISTA1 da SELECT_05_COM_DT cProd_EN_IN: ;"+aProdutos[T,1]+";"+Str(aProdutos[T,2],22,7)+CRLF
       EndIf   
       aAdd(aTp_EM_IN,aProdutos[T])
   Next T
   
   If _lLog
      For T := 1 To Len(aTp_EM_IN)
          _cValores+="LISTA2 DA JUNTA1 aTp_EM_IN;"+aTp_EM_IN[T,1]+";"+Str(aTp_EM_IN[T,2],22,7)+CRLF//OK
      Next T
   EndIf
   
   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno de perda com estrutura 3/4" )
   
   _cValores+="SELECT_EPCE;cProd_EN_IN: ; "+cProd_EN_IN+";"+Str(Len(aTp_EM_IN),22,7)+CRLF
   aProCompDT:=AEST046R(_oSelf,_lEnd,"SELECT_05_COM_DT")
   
   cProd_SEM_DT:=""
   For T := 1 To Len(aTp_EM_IN)
       If aScan(aProCompDT , {|P| P[1] == aTp_EM_IN[T,1]  })  = 0
          cProd_SEM_DT+=aTp_EM_IN[T,1]+";"
          _cValores+="LISTA3 da SELECT_05_SEM_DT cProd_SEM_DT:;"+aTp_EM_IN[T,1]+";"+Str(aTp_EM_IN[T,2],22,7)+CRLF
       EndIf
   Next T
   
   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno de perda com estrutura 4/4..." )
   _cValores+="SELECT_EPCE;cProd_SEM_DT: ; "+cProd_SEM_DT+CRLF
   cProd_EN_IN:=cProd_SEM_DT//Variavel cProd_EN_IN Usa na AEST046R(_oSelf,_lEnd,"SELECT_05_SEM_DT")
   aProComprados:=AEST046R(_oSelf,_lEnd,"SELECT_05_SEM_DT")
   For T := 1 To Len(aProCompDT)
       aAdd(aProComprados,aProCompDT[T])
   Next T
   If _lLog
      For T := 1 To Len(aProComprados)
          _cValores+="LISTA4 da JUNTA2 aProComprados:;"+aProComprados[T,1]+";"+Str(aProComprados[T,2],22,7)+";"+Str(aProComprados[T,3],22,7)+CRLF
      Next T
   EndIf
   _nEPCE :=0 
   For T := 1 To Len(aTp_EM_IN)
       If (nPos:=aScan(aProComprados , {|P| P[1] == aTp_EM_IN[T,1]  } )) <> 0       
          _nEPCE +=  ( aTp_EM_IN[T,2] * aProComprados[nPos,2] * aProComprados[nPos,3] )
          _cValores+="LISTA5 SOMA DO _nEPCE;"+aProComprados[nPos,1]+";"+Str(aTp_EM_IN[T,2],22,7)+";"+Str(aProComprados[nPos,2],22,7)+";"+Str((aProComprados[nPos,3]),22,7)+CRLF
       EndIf
   Next T

ElseIf MV_PAR03 = "2"//b.	2 - Estornar cred x percentual
   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno de perda com estrutura" )
   _nEPCE:=AEST046R(_oSelf,_lEnd,"SELECT_EPCE_5")//COM ESTRUTURA
EndIf
//CALCULOS PARA MANAUS
_oSelf:SetRegua2( 0 )
_cSeq:=StrZero(nSeq,2)+cTot
_oSelf:IncRegua1(_cSeq+" - Executando Leitura de Valores para MANAUS" )

_nODEB :=0 
_nODEB2:=0 
If MV_PAR07 = "2" .Or.  MV_PAR07 = "3" //2 – Estorna cred x operação .Or. //3 – Credita pela operação 
   _oSelf:SetRegua2( 3 )
   _oSelf:IncRegua2(_cSeq+" - Lendo Estorna / Credita pela Operacao  1/3" )
   nVlrCreditos:=AEST046R(_oSelf,_lEnd,"SELECT_ODEB_1")

   _oSelf:IncRegua2(_cSeq+" - Lendo Estorna / Credita pela Operacaoa 2/3" )
   nVlrZFM     :=AEST046R(_oSelf,_lEnd,"SELECT_ODEB_2")

   _oSelf:IncRegua2(_cSeq+" - Lendo Estorna / Credita pela Operacao 3/3..." )
   nVlrTotal   :=AEST046R(_oSelf,_lEnd,"SELECT_ODEB_3")
   _nODEB:=nVlrCreditos * (nVlrZFM/nVlrTotal)

   _cValores+="SELECT_ODEB;nVlrCreditos * (nVlrZFM/nVlrTotal): ; "+Str(nVlrCreditos,22,7)+";"+Str(nVlrZFM,22,7)+";"+Str(nVlrTotal,22,7)+CRLF
ElseIf MV_PAR07 = "1" 
   //_nODEB-- MANAUS
   _oSelf:SetRegua2( 4 )
   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno Credito x Estrutura 1/4" )
   aProdutos:=AEST046R(_oSelf,_lEnd,"SELECT_EPCE_3")

   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno Credito x Estrutura 2/4" )
   cProd_EN_IN:=""//Preenchido na função AEST46EStr(aProdutos) e Variavel cProd_EN_IN usa na AEST046R(_oSelf,_lEnd,"SELECT_05_COM_DT")
   aTp_EM_IN:=AEST46EStr(aProdutos)///EXPLODE A ESTRURA

   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno Credito x Estrutura 3/4" )
   _cValores+="SELECT_ODEB;cProd_EN_IN: ; "+cProd_EN_IN+";"+Str(Len(aTp_EM_IN),22)+CRLF
   aProCompDT:=AEST046R(_oSelf,_lEnd,"SELECT_05_COM_DT")

   cProd_SEM_DT:=""
   For T := 1 To Len(aTp_EM_IN)
       If aScan(aProCompDT , {|P| P[1] == aTp_EM_IN[T,1]  })  = 0
          cProd_SEM_DT+=aTp_EM_IN[T,1]+";"
       EndIf   
   Next T

   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno Credito x Estrutura 4/4" )
   _cValores+="SELECT_ODEB;cProd_SEM_DT: ; "+cProd_SEM_DT+CRLF
   cProd_EN_IN:=cProd_SEM_DT//Variavel cProd_EN_IN Usa na AEST046R(_oSelf,_lEnd,"SELECT_05_SEM_DT")
   aProComprados:=AEST046R(_oSelf,_lEnd,"SELECT_05_SEM_DT")//SELECT SEM FILTRO DE DATA
   For T := 1 To Len(aProCompDT)
       aAdd(aProComprados,aProCompDT[T])
   Next T
   _nODEB :=0 
   For T := 1 To Len(aProComprados)
       If (nPos:=aScan(aTp_EM_IN , {|P| P[1] == aProComprados[T,1]  } )) <> 0       
          _nODEB +=  ( aTp_EM_IN[nPos,2] * aProComprados[T,2] * aProComprados[T,3] )
          _cValores+="SELECT_ODEB;"+aProComprados[T,1]+";"+Str(aTp_EM_IN[nPos,2],22,7)+";"+Str(aProComprados[T,2],22,7)+";"+Str((aProComprados[T,3]),22,7)+CRLF
       EndIf
   Next T

   //_nODEB2 -- MANAUS
   _oSelf:SetRegua2( 3 )
   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno Credito x Estrutura 1/3" )
   aProdutos:=AEST046R(_oSelf,_lEnd,"SELECT_EPCE_4")

   
   cProd_EN_IN:=""//Preenchido ABAIXO e Variavel cProd_EN_IN usa na AEST046R(_oSelf,_lEnd,"SELECT_05_COM_DT")
   For T := 1 To Len(aProdutos)
       If !aProdutos[T,1]  $ cProd_EN_IN
          cProd_EN_IN+=aProdutos[T,1]+";"
       EndIf   
   Next T
   aTp_EM_IN:=aClone(aProdutos)

   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno Credito x Estrutura 2/3" )
   _cValores+="SELECT_ODEB2;cProd_EN_IN: ; "+cProd_EN_IN+";"+Str(Len(aTp_EM_IN),22)+CRLF
   aProCompDT:=AEST046R(_oSelf,_lEnd,"SELECT_05_COM_DT")

   cProd_SEM_DT:=""
   For T := 1 To Len(aTp_EM_IN)
       If aScan(aProCompDT , {|P| P[1] == aTp_EM_IN[T,1]  })  = 0
          cProd_SEM_DT+=aTp_EM_IN[T,1]+";"
       EndIf   
   Next T

   _oSelf:IncRegua2(_cSeq+" - Lendo Estorno Credito x Estrutura 3/3" )
   _cValores+="SELECT_ODEB2;cProd_SEM_DT: ; "+cProd_SEM_DT+CRLF
   cProd_EN_IN:=cProd_SEM_DT//Variavel cProd_EN_IN Usa na AEST046R(_oSelf,_lEnd,"SELECT_05_SEM_DT")
   aProComprados:=AEST046R(_oSelf,_lEnd,"SELECT_05_SEM_DT")//SELECT SEM FILTRO DE DATA
   For T := 1 To Len(aProCompDT)
       aAdd(aProComprados,aProCompDT[T])
   Next T
   _nODEB2 :=0 
   For T := 1 To Len(aProComprados)
       If (nPos:=aScan(aTp_EM_IN , {|P| P[1] == aProComprados[T,1]  } )) <> 0       
          _nODEB2 +=  ( aTp_EM_IN[nPos,2] * aProComprados[T,2] * aProComprados[T,3] )
          _cValores+="SELECT_ODEB2;"+aProComprados[T,1]+";"+Str(aTp_EM_IN[nPos,2],22,7)+";"+Str(aProComprados[T,2],22,7)+";"+Str((aProComprados[T,3]),22,7)+CRLF
       EndIf
   Next T 

EndIf
//CALCULOS PARA MANAUS

_oself:IncRegua1("Calculando Regra...")
_oself:IncRegua2("Calculando Regra...")

ZM0->(DBSeek(xFilial()))
ZM0->(DBEval({|| nTotal++},Nil,	{||	xFilial("ZM0")	 ==	ZM0->ZM0_FILIAL },Nil,Nil,.T.))
ZM0->(DBSeek(xFilial()))
_cTotReg:=AllTrim(Str(nTotal))
_oSelf:SetRegua1( nTotal )
_oSelf:SetRegua2( nTotal )

_nBaseGeral:=0
_nBaseCFinan:=0
_nBaseT1Geral:=0
_nBaseT2Geral:=0
_aBasePresumido:={}
_nBaseLPOGeral:=0

_nRatGeral:=0
_nRatT1Geral:=0
_nRatT2Geral:=0

_nQuant:=0
_nQuantVLROP:=0
_nVLROPDQuant:=0

If _lLog
   _cValores+=_cLogQuerys
   _cValores+=_cVal2
   _cValores+=_cVal3
   _cValores+=_cTeste
   _cValores:=StrTran(_cValores,".",",")
   _cValores+="MIX:; "+Str(_nMix,22,7)+CRLF+CRLF
   _cValores+="REGRA;GRUPO;PERC;SOMA;VLR SD3"+CRLF
   _cValores+="ZM0->ZM0_CODEVE+;+ZM0->ZM0_GRPPRS+;+Str(ZM0->ZM0_PRSPRD,5,2)+;+Str((aCalc[03]-aCalc[06]),22,7)+;+Str(_aBasePresumido[_nPos,3],22,7)"+CRLF
EndIf

While ZM0->(!Eof()) .And. ZM0->ZM0_FILIAL == xFilial("ZM0")
   nConta++
   _oself:IncRegua1("Calculando Regra: "+LEFT(ZM0->ZM0_EVDESC,25))
   _oself:IncRegua2("Calculando Regra: "+AllTrim(Str(nConta,6))+" de "+_cTotReg)
    ProcessMessages()
    If _lEnd 
       If (_lEnd:=U_ITMsg("Confirma Cancelamento? .","Atenção",,3,2,2))
          Return .F.
       EndIf   
    EndIf

    aCalc:=ARRAY(Len(aCampos)+1)

    If ZM0->ZM0_MSBLQL <> '1'

       aCalc[01]:=SubStr(MV_PAR01,5,2)+SubStr(MV_PAR01,1,4)  //01-ZM1_DATARQ 
       aCalc[02]:=ZM0->ZM0_CODEVE+"-"+Posicione("ZM0",1,xFilial("ZM0")+ZM0->ZM0_CODEVE,"ZM0_EVDESC")//02-ZM1_CODEVE

       aCalc[03]:=AEST046R(_oSelf,_lEnd,"SELECT_01")         //03-ZM1_VLROP
       _nQuantVLROP:=_nQuant//Variavel _nQuant preenchida na função AEST046R(_oSelf,_lEnd,"SELECT_01")  

       aCalc[04]:=aCalc[03]*(ZM0->ZM0_ALIQ/100)              //04-ZM1_ICMSAI :=ZM1_VLROP * ZM0->ZM0_ALIQ
       aCalc[05]:=aCalc[03]*(ZM0->ZM0_BENEF/100)             //05-ZM1_CREDS  :=ZM1_VLROP * ZM0->ZM0_BENEF

       aCalc[06]:=AEST046R(_oSelf,_lEnd,"SELECT_02")         //06-ZM1_VLROPD    
       _nVLROPDQuant:=_nQuant//Variavel _nQuant preenchida na função AEST046R(_oSelf,_lEnd,"SELECT_02")  

       aCalc[07]:=aCalc[06]*(ZM0->ZM0_ALIQ/100)              //07-ZM1_ICMSD  :=ZM1_VLROPD * ZM0->ZM0_ALIQ
       aCalc[08]:=aCalc[06]*(ZM0->ZM0_BENEF/100)             //08-ZM1_ESTCRD :=ZM1_VLROPD * ZM0->ZM0_BENEF
       aCalc[09]:=aCalc[04]-aCalc[05]-aCalc[07]+aCalc[08]    //09-ZM1_ICMAPG :=(ZM1_ICMSAI - ZM1_CREDS - ZM1_ICMSD + ZM1_ESTCRD)
       aCalc[10]:=(aCalc[05]-aCalc[08])*(ZM0->ZM0_DEBBNF/100)//10-ZM1_DBBENF :=(ZM1_CREDS  - ZM1_ESTCRD) * ZM0->ZM0_DEBBNF
       aCalc[11]:=(aCalc[03]-aCalc[06])*(ZM0->ZM0_DEBVND/100)//11-ZM1_DBVND  :=(ZM1_VLROP  - ZM1_VLROPD) * ZM0->ZM0_DEBVND
       aCalc[16]:=0//"ZM1_OCRED" ,"C-Outros Crd"
       aCalc[19]:=0//"ZM1_PRSPRD","C-Presm Prod"
       aCalc[20]:=0//"ZM1_PRSOPE","C-Presm Oper"
       aCalc[21]:=0//"ZM1_CDBENF","C-Crd S/ Bnf"
       aCalc[22]:=0//"ZM1_ODEB"  ,"D-Outros Deb

       _nZM1_PRSOPE:=0

       If ZM0->ZM0_PRSPRD > 0
          If (_nPos:=aScan(_aBasePresumido , {|G| G[1] = ZM0->ZM0_GRPPRS } )) = 0 
             _nQtde:=AEST046R(_oSelf,_lEnd,"SELECT_03")//ZM1_PRSPRD = 
             aAdd(_aBasePresumido, {ZM0->ZM0_GRPPRS , (aCalc[03]-aCalc[06])  , _nQtde } )//SOMA: ZM1_VLROP-ZM1_VLROPD
             _nPos:=Len(_aBasePresumido)
          Else
              _aBasePresumido[_nPos,2]+=(aCalc[03]-aCalc[06]) //SOMA: ZM1_VLROP-ZM1_VLROPD
          EndIf
           _cValores+=ZM0->ZM0_CODEVE+";"+ZM0->ZM0_GRPPRS+";"+Str(ZM0->ZM0_PRSPRD,5,2)+";"+Str((aCalc[03]-aCalc[06]),22,7)+";"+Str(_aBasePresumido[_nPos,3],22,7)+CRLF
       EndIf
       
       If  ZM0->ZM0_PRSOPE > 0  
          _nRen:=0
          If Empty(ZM0->ZM0_OPREN) .And. !Empty(ZM0->ZM0_MPCONS) .And. !Empty(ZM0->ZM0_CCCONS)
             aRegra:=StrTran(AllTrim(ZM0->ZM0_BASREN),"/",";")
             aRegra:=StrTokArr(aRegra,';')
             _aRendim:=AEST046R(_oSelf,_lEnd,"SELECT_04")//ZM1_PRSOPE =
             _nRen:=AEST46Ren(_aRendim,aRegra)//PADRAO DAS REGRAS ZM0

          ElseIf ZM0->ZM0_OPREN = "1"
             aRegra:=StrTokArr(AllTrim(SuperGetMV("IT_EST4601",.F.,"08000000028;RE1;08140000001;PR0;08140000011;PR0" )) ,';')
             _nRen:=AEST46Ren(_aRenUnt,aRegra)

             aRegra:=StrTokArr(AllTrim(SuperGetMV("IT_EST4602",.F.,"00020010501;RE1" )) ,';')
             nValor1:=0
             AEST46Ren(_aRenLCon,aRegra)
             nLeiteLPI:=nValor1*_nRen

             aRegra:=StrTokArr(AllTrim(SuperGetMV("IT_EST4603",.F.,"08000000051;RE1;08140000026;PR0" )) ,';')
             nValor1:=0
             nValor2:=0
             AEST46Ren(_aRenLCon,aRegra)
             _nRen:= (nValor1 + nLeiteLPI) / nValor2
             
          ElseIf ZM0->ZM0_OPREN = "2"
             aRegra:=StrTokArr(AllTrim(SuperGetMV("IT_EST4604",.F.,"08000000028;RE1;08140000001;PR0;08140000011;PR0" )) ,';')
             nValor1:=0
             nValor2:=0
             nValor3:=0
             AEST46Ren(_aRenUnt,aRegra)
             nValorA:=nValor1
             nValorB:=nValor2
             nValorC:=nValor3

             aRegra:=StrTokArr(AllTrim(SuperGetMV("IT_EST4605",.F.,"08000000050;RE1;08140000002;PR0;08140000012;PR0" )) ,';')
             nValor1:=0
             nValor2:=0
             nValor3:=0
             AEST46Ren(_aRenDes,aRegra)
             nValorA:=nValor1+nValorA
             nValorB:=nValorB+nValor2+nValorC+nValor3
             _nRen:= nValorA / nValorB

          ElseIf ZM0->ZM0_OPREN = "3"//INTEGRAL
             aRegra:=StrTokArr(AllTrim(SuperGetMV("IT_EST4606",.F.,"08000000028;RE1;08140000001;PR0;08140000011;PR0" )) ,';')
             _nRen:=AEST46Ren(_aRenUnt,aRegra)

          ElseIf ZM0->ZM0_OPREN = "4"//DESNATADO
             aRegra:=StrTokArr(AllTrim(SuperGetMV("IT_EST4607",.F.,"08000000050;RE1;08140000002;PR0;08140000012;PR0" )) ,';')/////////////
             _nRen:=AEST46Ren(_aRenDes,aRegra)

          ElseIf ZM0->ZM0_OPREN = "5"//1 POR 1
             _nZM1_PRSOPE:= (_nQuantVLROP-_nVLROPDQuant) * _nMix * (ZM0->ZM0_PRSOPE/100)

          EndIf

          If ZM0->ZM0_OPREN <> "5"
             _nZM1_PRSOPE:= ((_nQuantVLROP-_nVLROPDQuant) * _nRen ) * _nMix * (ZM0->ZM0_PRSOPE/100)
          EndIf

          _cVal2+=ZM0->ZM0_CODEVE+";"+Str(_nZM1_PRSOPE,22,7)+";"+Str(_nQuantVLROP,22,7)+";"+Str(_nVLROPDQuant,22,7)+";"+Str((_nRen),22,7)+";"+Str(_nMix,22,7)+";"+Str((ZM0->ZM0_PRSOPE/100),22,7)+";"+Str((ZM0->ZM0_LMT1P),22,7)+CRLF

          If !Empty(ZM0->ZM0_LMT1P)
         
             //Limitador = (ZM1_ICMSAI - ZM1_ICMSD) * ZM0_LMT1P
             nLimitador := (aCalc[04] - aCalc[07]) * (ZM0->ZM0_LMT1P/100)
             //Resultado = Se cálculo > Limitador, mantém limitador, se não mantém o Cálculo
             If _nZM1_PRSOPE > nLimitador
                _nZM1_PRSOPE:= nLimitador
             EndIf
         
         ElseIf ZM0->ZM0_LMT2C = '1'
         
             aProdutos:=AEST046R(_oSelf,_lEnd,"SELECT_01_B")
             aProdSD1:=AEST046R(_oSelf,_lEnd,"SELECT_02_B")

             For T := 1 To Len(aProdSD1)
                 nQTSD2:=0
                 If (nPos:=aScan(aProdutos , {|P| P[1] == aProdSD1[T,1]  })  ) <> 0
                    aProdutos[nPos,2]:=aProdutos[nPos,2] - aProdSD1[T,2]
                    nQTSD2:=aProdutos[nPos,2] 
                  Else
                    aAdd(aProdutos,aProdSD1[T])  
                    aProdutos[Len(aProdutos),2]:=(aProdutos[Len(aProdutos),2] * -1)
                 EndIf   
                 _cVal3+="RG: "+ZM0->ZM0_CODEVE+";"+aProdSD1[T,1] +"; SD2: "+Str(nQTSD2,22) +"; - SD1: "+Str(aProdSD1[T,2],22) +CRLF
             Next

             cProd_EN_IN:=""//Preenchido na função AEST46EStr(aProdutos) e Variavel cProd_EN_IN usa na AEST046R(_oSelf,_lEnd,"SELECT_05_COM_DT")
             aTp_EM_IN:=AEST46EStr(aProdutos)///EXPLODE A ESTRURA

             _cVal3+="RG: "+ZM0->ZM0_CODEVE+";cProd_EN_IN: ; "+cProd_EN_IN+";"+Str(Len(aTp_EM_IN),22)+CRLF

             aProCompDT:=AEST046R(_oSelf,_lEnd,"SELECT_05_COM_DT")
             
             cProd_SEM_DT:=""
             For T := 1 To Len(aTp_EM_IN)
                 If aScan(aProCompDT , {|P| P[1] == aTp_EM_IN[T,1]  })  = 0
                    cProd_SEM_DT+=aTp_EM_IN[T,1]+";"
                 EndIf   
             Next
             _cVal3+="RG: "+ZM0->ZM0_CODEVE+";cProd_SEM_DT: ; "+cProd_SEM_DT+CRLF
             
             cProd_EN_IN:=cProd_SEM_DT//Variavel cProd_EN_IN Usa na AEST046R(_oSelf,_lEnd,"SELECT_05_SEM_DT")
             aProComprados:=AEST046R(_oSelf,_lEnd,"SELECT_05_SEM_DT")

             For T := 1 To Len(aProCompDT)
                 aAdd(aProComprados,aProCompDT[T])
             Next

             nLimitador :=0 //(ZM1_ICMSAI - ZM1_ICMSD)  - ((QTD_ZM1_VLROP - QTD_ZM1_VLROPD)  (Estrutura)  preço compra * Alíq. ICMS )

             For T := 1 To Len(aProComprados)
                 If (nPos:=aScan(aTp_EM_IN , {|P| P[1] == aProComprados[T,1]  } )) <> 0
                    nLimitador +=  ( aTp_EM_IN[nPos,2] * aProComprados[T,2] * aProComprados[T,3] )
                    _cVal3+="RG: "+ZM0->ZM0_CODEVE+";"+aProComprados[T,1]+";"+Str(aTp_EM_IN[nPos,2],22,7)+";"+Str(aProComprados[T,2],22,7)+";"+Str((aProComprados[T,3]),22,7)+CRLF
                 EndIf   
             Next T
             _cVal3+="RG: "+ZM0->ZM0_CODEVE+";TOTAL: ; +Str((aCalc[04] - aCalc[07]),22,7)+;+Str(nLimitador,22,7)"+CRLF
             _cVal3+="RG: "+ZM0->ZM0_CODEVE+";TOTAL: ; "+Str((aCalc[04] - aCalc[07]),22,7)+";"+Str(nLimitador,22,7)+CRLF
             
             nLimitador := (aCalc[04] - aCalc[07])  - nLimitador

             If _nZM1_PRSOPE > nLimitador
                _nZM1_PRSOPE:= nLimitador
             EndIf

          ElseIf ZM0->ZM0_OPREN = "6" //d.	Quando "ZM0_OPREN" estiver como "6 - % direto VLR operação"
             
	          If ZM0->ZM0_RDBASE = "1"  //                  (aCalc[03]-aCalc[06]) 
                //i.	(((ZM0_ALIQ - ZM0_BENEF)/ZM0_ALIQ) * (ZM1_VLROP - ZM1_VLROPD)) * (ZM0_PRSOPE/100)
                _nZM1_PRSOPE:=(((ZM0->ZM0_ALIQ - ZM0->ZM0_BENEF)/ZM0->ZM0_ALIQ)  * (aCalc[03]-aCalc[06]) ) * (ZM0->ZM0_PRSOPE/100)
	          ElseIf ZM0->ZM0_RDBASE = "2"
                //i.	(ZM0_ALIQ * (ZM1_VLROP - ZM1_VLROPD)) * (ZM0_PRSOPE/100)
                _nZM1_PRSOPE:=((ZM0->ZM0_ALIQ/100) * (aCalc[03]-aCalc[06]) ) * (ZM0->ZM0_PRSOPE/100)
	          EndIf
          EndIf

          aCalc[20]:=_nZM1_PRSOPE//ZM1_PRSOPE =  ((ZM1_VLROP - ZM1_VLROPD) * rendimento Leite) * MIX * _nRen*/
       Else
          aCalc[20]:=0
       EndIf   

       aCalc[21]:=(aCalc[05]-aCalc[08])*(ZM0->ZM0_CRDBNF/100)//21-ZM1_CDBENF := (ZM1_CREDS - ZM1_ESTCRD) * ZM0_CRDBNF           

       _nBaseGeral+=(aCalc[03]-aCalc[06])     //SOMA: ZM1_VLROP-ZM1_VLROPD
       If ZM0->ZM0_TIPO = '1'
          _nBaseT1Geral+=(aCalc[03]-aCalc[06])//SOMA: ZM1_VLROP-ZM1_VLROPD
       ElseIf ZM0->ZM0_TIPO = '2'
          _nBaseT2Geral+=(aCalc[03]-aCalc[06])//SOMA: ZM1_VLROP-ZM1_VLROPD
       EndIf   
       
       If If(ZM0->(FIELDPOS("ZM0_DSCBNT"))=0,(ZM0->ZM0_CODEVE $ "000022/000006"),(ZM0->ZM0_DSCBNT = '1'))
          _nBaseLPOGeral+=(aCalc[03]-aCalc[06])
       EndIf   

	    If ZM0->ZM0_RDBASE = "1"
//        _nBaseCFinan += ((ZM1_CREDS - ZM1_ESTCRD) - ((ZM1_VLROP - ZM1_VLROPD) * (ZM0_BENEF/100))) 
          _nBaseCFinan += ((aCalc[05]-aCalc[08]) - ((aCalc[03]-aCalc[06]) * (ZM0->ZM0_BENEF/100))) 
       ElseIf ZM0->ZM0_RDBASE = "2"
//        _nBaseCFinan += (ZM1_CREDS - ZM1_ESTCRD)
          _nBaseCFinan += (aCalc[05]-aCalc[08])
	    EndIf

	   aCalc[Len(aCalc)]:=ZM0->(RECNO())//ULTIMA POSICAO  Len(aCampos)+1

    Else
       aCalc:=ARRAY(Len(aCampos)+1)//{"","",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	   For T := 1 To Len(aCampos)
	      aCalc[T]:=0
	   Next T
      aCalc[01]:=SubStr(MV_PAR01,5,2) +  SubStr(MV_PAR01,1,4) 
      aCalc[02]:="RG: "+ZM0->ZM0_CODEVE+" - [BLOQUEADO]"//+Posicione("ZM0",1,xFilial("ZM0")+ZM0->ZM0_CODEVE,"ZM0_EVDESC")//ZM1_CODEVE
	   aCalc[Len(aCalc)]:=ZM0->(RECNO())//ULTIMA POSICAO  Len(aCampos)+1
    EndIf
    
    aAdd(aDadosCalc,aCalc)   
   
    _cVal3+=CRLF

    ZM0->(DBSkip())
EndDo

_cSegfOR:=CRLF+"For 2"+CRLF

If Empty(MV_PAR06) .And. !Empty(MV_PAR08) .And. (!Empty(MV_PAR09) .Or. !Empty(MV_PAR10))
   _oSelf:SetRegua1( 2 )
   _oSelf:SetRegua2( 2 )
   _oSelf:IncRegua1("Executando Leitura de Valores para Rateio" )
   _oSelf:IncRegua2("Lendo Bolsa Garantia..." )
   _nBG_Ori:=AEST046R(_oSelf,_lEnd,"SELECT_BG_GIGANTE")

   If !Empty(MV_PAR09)
//    _nBG := (Resultado * (% Programa financiado/100)) * (% Bolsa Garantia sobre financiado/100) 
      _cSegfOR+="(_nBG_Ori * (MV_PAR08/100)) * (MV_PAR09/100) ;"+Str(_nBG_Ori,22,7)+";"+Str(MV_PAR08,5,2)+";"+Str(MV_PAR09,5,2)+CRLF
      _nBG := (_nBG_Ori * (MV_PAR08/100)) * (MV_PAR09/100) 
   EndIf
 
   If !Empty(MV_PAR10)
//    _nBG += (Resultado * (% Programa financiado/100)) * (% Protege sobre financiado/100)
      _nBG += (_nBG_Ori * (MV_PAR08/100)) * (MV_PAR10/100) 
      _cSegfOR+="(_nBG_Ori * (MV_PAR08/100)) * (MV_PAR10/100) ;"+Str(_nBG_Ori,22,7)+";"+Str(MV_PAR08,5,2)+";"+Str(MV_PAR10,5,2)+CRLF
   EndIf
   _cSegfOR+="_nBG: ;"+Str(_nBG,22,7)+CRLF

EndIf

nConta:=0
nTotal:=Len(aDadosCalc)
_cTotReg:=AllTrim(Str(nTotal))
_oSelf:SetRegua1( nTotal )
_oSelf:SetRegua2( nTotal )

If _lLog
   _cValores+=_cLogQuerys
   _cValores+=_cVal2
   _cValores+=_cVal3
   _cValores+=_cTeste
   _cValores:=StrTran(_cValores,".",",")
   _cValores+=CRLF+"For 2"+CRLF
   _cValores+=CRLF+"REGRA;GRUPO;PERC;RATEIO;VLR SD3"+CRLF
EndIf

Private nTotal17:=0
nVlrDesLPRecTrans:=0

For T :=  1 To Len(aDadosCalc)
	
    nConta++
    _oself:IncRegua2("Recalculando Regra: "+AllTrim(Str(nConta,6))+" de "+_cTotReg)

	aCalc:=aDadosCalc[T]
	If aCalc[Len(aCalc)] = 0
       _oself:IncRegua1("Recalculando Regra: ")
	   Loop
	Else
	   ZM0->(DBGoTo(aCalc[Len(aCalc)]))
	EndIf
    _oself:IncRegua1("Recalculando Regra: "+LEFT(ZM0->ZM0_EVDESC,25))
    ProcessMessages()

   If (_nPos:=aScan(_aBasePresumido , {|G| G[1] = ZM0->ZM0_GRPPRS } )) <> 0 
      _nRatPresumido:=((aCalc[03]-aCalc[06])/_aBasePresumido[_nPos,2] )//Rateio
      aCalc[19] := (_nRatPresumido * (_nMix * _aBasePresumido[_nPos,3] )) * (ZM0->ZM0_PRSPRD/100) //ZM1_PRSPRD = Rateio * Preco Unt MIX * Qtde MP consumida
      _cValores+="RG: "+ZM0->ZM0_CODEVE+";"+ZM0->ZM0_GRPPRS+";"+Str(ZM0->ZM0_PRSPRD,5,2)+";"+Str(_nRatPresumido,22,7)+";"+Str(_aBasePresumido[_nPos,3],22,7)+CRLF
   EndIf
   aCalc[09] := (aCalc[09] - aCalc[19] - aCalc[20] ) //09-ZM1_ICMAPG - ZM1_PRSPRD - ZM1_PRSOPE

	_nRatGeral   :=((aCalc[03]-aCalc[06]) / _nBaseGeral)//Rateio
	_nRatT1Geral :=((aCalc[03]-aCalc[06]) / _nBaseT1Geral)//Rateio
	_nRatT2Geral :=((aCalc[03]-aCalc[06]) / _nBaseT2Geral)//Rateio
	_nRatT3Geral :=((aCalc[03]-aCalc[06]) / (_nBaseGeral-_nBaseT1Geral-_nBaseT2Geral))//Rateio
	_nRatGerT1Sem:=((aCalc[03]-aCalc[06]) / (_nBaseGeral-_nBaseT2Geral))//Rateio
	_nRatGerT2Sem:=((aCalc[03]-aCalc[06]) / (_nBaseGeral-_nBaseT1Geral))//Rateio
	_nRatLPOGeral:=((aCalc[03]-aCalc[06]) / _nBaseLPOGeral)
   
   aCalc[12]:=0
   aCalc[13]:=0
   aCalc[15]:=0
   aCalc[16]:=0
   aCalc[22]:=0
	
   If ZM0->ZM0_TIPO = '1'//1=Producao Propria
      If MV_PAR03 = "1" //1 – Estorna cred x Estrutura 
		   aCalc[12]:=_nEPCE * _nRatT1Geral //12-ZM1_ESTPRD:=
      ElseIf MV_PAR03 = "2"//b.	2 - Estornar cred x percentual
		   aCalc[12]:=_nEPCE * _nRatT1Geral * (ZM0->ZM0_ESPERD/100)  //12-ZM1_ESTPRD:=
      EndIf   
	   aCalc[13]:=(_nDP*_nRatT1Geral)//13-ZM1_JUROSI:=	
	   aCalc[15]:=(_nBG*_nRatT1Geral)//15-ZM1_BGARAN:=

      If MV_PAR07 = "1" //1 – Estorna cred x Estrutura 
		   aCalc[22]:=_nODEB * _nRatT1Geral //22-ZM1_ODEB:=
      EndIf   

   ElseIf ZM0->ZM0_TIPO = '2'//2=Mercadoria Adquirida
      If MV_PAR03 = "1" //1 – Estorna cred x Estrutura 
		   aCalc[12]:= (_nEPSE - (_nEPSE * ((_nBaseGeral-_nBaseT1Geral-_nBaseT2Geral) / (_nBaseGeral - _nBaseT1Geral) ))) * _nRatT2Geral //12-ZM1_ESTPRD:=   
      ElseIf MV_PAR03 = "2"//b.	2 - Estornar cred x percentual
		   aCalc[12]:= (_nEPSE - (_nEPSE * ((_nBaseGeral-_nBaseT1Geral-_nBaseT2Geral) / (_nBaseGeral - _nBaseT1Geral) ))) * _nRatT2Geral * (ZM0->ZM0_ESPERD/100) //12-ZM1_ESTPRD:=
      EndIf   
      If MV_PAR07 = "1" //1 – Estorna cred x Estrutura 
		   aCalc[22]:= (_nODEB2 - (_nODEB2 * ((_nBaseGeral-_nBaseT1Geral-_nBaseT2Geral) / (_nBaseGeral - _nBaseT1Geral) ))) * _nRatT2Geral //22-ZM1_ODEB:=
      EndIf
  
   Else //ZM0->ZM0_TIPO = '3'//3=Ambas	
      If _nBaseT1Geral = 0
         If MV_PAR03 = "1" //1 – Estorna cred x Estrutura 
		      aCalc[12]:=(_nEPCE * _nRatGerT1Sem) //12-ZM1_ESTPRD:=
         ElseIf MV_PAR03 = "2"//b.	2 - Estornar cred x percentual
		      aCalc[12]:=(_nEPCE * _nRatGerT1Sem * (ZM0->ZM0_ESPERD/100))  //12-ZM1_ESTPRD:=
         EndIf   
	   	 aCalc[13]:=(_nDP * _nRatGerT1Sem)//13-ZM1_JUROSI:=
   	     aCalc[15]:=(_nBG * _nRatGerT1Sem)  //15-ZM1_BGARAN:=
	   	 If MV_PAR07 = "1" //1 – Estorna cred x Estrutura 
	   		aCalc[22]:=(_nODEB * _nRatGerT1Sem) // 22-ZM1_ODEB:=
	   	 EndIf
	  EndIf
   
	  If _nBaseT2Geral = 0
         If MV_PAR03 = "1" //1 – Estorna cred x Estrutura 
		      aCalc[12]+=(_nEPSE * _nRatGerT2Sem) //12-ZM1_ESTPRD:=
         ElseIf MV_PAR03 = "2"//b.	2 - Estornar cred x percentual
		      aCalc[12]+=(_nEPSE * _nRatGerT2Sem * (ZM0->ZM0_ESPERD/100)) //12-ZM1_ESTPRD:=
         EndIf   
	   	If MV_PAR07 = "1" //1 – Estorna cred x Estrutura
	   		aCalc[22]+=(_nODEB2 * _nRatGerT2Sem)  //22-ZM1_ODEB:=
	   	EndIf
	  EndIf   

      If _nBaseT1Geral > 0 .And. _nBaseT2Geral > 0
         If MV_PAR03 = "1" //1 – Estorna cred x Estrutura 
		      aCalc[12]+=((_nEPSE - (_nEPSE * (_nBaseT2Geral / (_nBaseGeral - _nBaseT1Geral) ))) * _nRatT3Geral) //12-ZM1_ESTPRD:=
         ElseIf MV_PAR03 = "2"//b.	2 - Estornar cred x percentual
		      aCalc[12]+=((_nEPSE - (_nEPSE * (_nBaseT2Geral / (_nBaseGeral - _nBaseT1Geral) ))) * _nRatT3Geral * (ZM0->ZM0_ESPERD/100)) //12-ZM1_ESTPRD:=
         EndIf             
   	    
	   	 If MV_PAR07 = "1" //1 – Estorna cred x Estrutura 
	   		aCalc[22]+=((_nODEB2 - (_nODEB2 * (_nBaseT2Geral / (_nBaseGeral - _nBaseT1Geral) ))) * _nRatT3Geral)  //22-ZM1_ODEB:=
	   	 EndIf
	  EndIf
   EndIf

   If If(ZM0->(FIELDPOS("ZM0_DSCBNT"))=0,(ZM0->ZM0_CODEVE $ "000022/000006"),(ZM0->ZM0_DSCBNT = '1')) .And. nTotLP > 0//ou "Sim"
      nTotLPAux:=  ( (nTotLP * _nRatLPOGeral) * (ZM0->ZM0_BENEF/100) ) - ( ((nTotLP * _nRatLPOGeral) * (ZM0->ZM0_BENEF/100)) * (ZM0->ZM0_DEBBNF/100) )  + ( ((nTotLP * _nRatLPOGeral) * (ZM0->ZM0_BENEF/100)) * (ZM0->ZM0_CRDBNF/100) ) 
      aCalc[22]+= nTotLPAux           //já possui várias valores/rateios
      nVlrDesLPRecTrans += nTotLPAux  //para informar na aDadosTela
   EndIf

   aCalc[14]:=(_nMF*_nRatGeral)//14-ZM1_MTFISC:=
   aCalc[22]+=(_nAnulaCred * _nRatGeral)//22-ZM1_ODEB :=      
   aCalc[22]+=(_nGlosaCred * _nRatGeral)//22-ZM1_ODEB :=    

   If MV_PAR13 = "1"  // Geral
      aCalc[22]+=(_nDebApurICMS  * _nRatGeral)//22-ZM1_ODEB :=
      aCalc[16]+=(_nCredApurICMS * _nRatGeral)//16- ZM1_OCRED :=
   ElseIf MV_PAR13 = "2"//Somente Produção
      If ZM0->ZM0_TIPO = '1'//1=Producao Propria
         aCalc[22]+=(_nDebApurICMS  * _nRatT1Geral)//22-ZM1_ODEB :=
         aCalc[16]+=(_nCredApurICMS * _nRatT1Geral)//16- ZM1_OCRED :=
      EndIf   
   EndIf

   If MV_PAR07 = "2" //2 – Estorna cred x operação
      aCalc[22]+=(_nODEB * _nRatGeral) //22-ZM1_ODEB :=         
   ElseIf MV_PAR07 = "3" //3 – Credita pela operação 
      aCalc[16]+=(_nODEB * _nRatGeral) //16-ZM1_OCRED:=
   EndIf

   //17-ZM1_DESP:=(ZM1_ICMAPG+ZM1_DBBENF+ZM1_DBVND+ZM1_ESTPRD+ZM1_JUROSI+ZM1_MTFISC+ZM1_BGARAN-ZM1_OCRED-ZM1_CDBENF+ZM1_ODEB)
   aCalc[17]:=(aCalc[09] +aCalc[10] +aCalc[11]+aCalc[12] +aCalc[13] +aCalc[14] +aCalc[15] -aCalc[16] - aCalc[21] +aCalc[22]  )
   aCalc[18]:=( (aCalc[17]/ (aCalc[03]-aCalc[06] )) *100 ) //18-ZM1_CUSICM:=( (ZM1_DESP / (ZM1_VLROP-ZM1_VLROPD)) *100 )
	
   aDadosCalc[T]:=aCalc
   
   If ZM0->ZM0_TIPO = '1'//1=Producao Propria
      nTotal17+=aCalc[17]//17-ZM1_DESP
   EndIf   
Next

lRecalc:=.F.
If MV_PAR15 = "1" .And. nTotal17 < 0
   nTotal17:= nTotal17 * -1
   lRecalc:=.T.
EndIf

nConta:=0
nTotal:=Len(aDadosCalc)
_cTotReg:=AllTrim(Str(nTotal))
_oSelf:SetRegua1( nTotal )
_oSelf:SetRegua2( nTotal )
	
For T :=  1 To Len(aDadosCalc)
	
	nConta++
	_oself:IncRegua2("Recalculando Regra: "+AllTrim(Str(nConta,6))+" de "+_cTotReg)
	
	aCalc:=aDadosCalc[T]
	If aCalc[Len(aCalc)] = 0
		_oself:IncRegua1("Recalculando Regra: ")
		Loop
	Else
		ZM0->(DBGoTo(aCalc[Len(aCalc)]))
	EndIf
	_oself:IncRegua1("Recalculando Regra: "+LEFT(ZM0->ZM0_EVDESC,25))
	ProcessMessages()
	
	If lRecalc
		_nRatGeral   :=((aCalc[03]-aCalc[06]) / _nBaseGeral)//Rateio
		_nRatT1Geral :=((aCalc[03]-aCalc[06]) / _nBaseT1Geral)//Rateio
		_nRatT2Geral :=((aCalc[03]-aCalc[06]) / _nBaseT2Geral)//Rateio
		_nRatT3Geral :=((aCalc[03]-aCalc[06]) / (_nBaseGeral-_nBaseT1Geral-_nBaseT2Geral))//Rateio
		_nRatGerT1Sem:=((aCalc[03]-aCalc[06]) / (_nBaseGeral-_nBaseT2Geral))//Rateio
		_nRatGerT2Sem:=((aCalc[03]-aCalc[06]) / (_nBaseGeral-_nBaseT1Geral))//Rateio
		
		If ZM0->ZM0_TIPO = '1'//1=Producao Propria /DEBITO
			
			aCalc[22]+=nTotal17 * _nRatT1Geral //22-ZM1_ODEB :=
			aCalc[17]+=nTotal17 * _nRatT1Geral//17-ZM1_DESP
			
		ElseIf ZM0->ZM0_TIPO = '2'//2=Mercadoria Adquirida //CREDITO
			
			aCalc[16]+= (nTotal17 - (nTotal17 * ((_nBaseGeral-_nBaseT1Geral-_nBaseT2Geral) / (_nBaseGeral - _nBaseT1Geral) ))) * _nRatT2Geral //16-ZM1_OCRED :=
			aCalc[17]-= (nTotal17 - (nTotal17 * ((_nBaseGeral-_nBaseT1Geral-_nBaseT2Geral) / (_nBaseGeral - _nBaseT1Geral) ))) * _nRatT2Geral//17-ZM1_DESP
			
		Else //ZM0->ZM0_TIPO = '3'//3=Ambas	//CREDITO
			If _nBaseT2Geral = 0
				aCalc[16]+= (nTotal17 * _nRatGerT2Sem)  //16-ZM1_OCRED :=
				aCalc[17]-= (nTotal17 * _nRatGerT2Sem)//17-ZM1_DESP
			EndIf
			If _nBaseT1Geral > 0 .And. _nBaseT2Geral > 0
				aCalc[16]+=((nTotal17 - (nTotal17 * (_nBaseT2Geral / (_nBaseGeral - _nBaseT1Geral) ))) * _nRatT3Geral)   //16-ZM1_OCRED :=
				aCalc[17]-=((nTotal17 - (nTotal17 * (_nBaseT2Geral / (_nBaseGeral - _nBaseT1Geral) ))) * _nRatT3Geral)//17-ZM1_DESP
			EndIf
		EndIf
        aCalc[18]:=( (aCalc[17]/ (aCalc[03]-aCalc[06] )) *100 ) //18-ZM1_CUSICM:=( (ZM1_DESP / (ZM1_VLROP-ZM1_VLROPD)) *100 )
	EndIf
	
	aCalcTela:=ARRAY(Len(aCampos))
	For I := 1 To Len(aCampos)
		If ValType(aCalc[I]) = "N" //I > 2 // NUMERICOS
			aCalcTela[I]:=Transform(aCalc[I],"@E 999,999,999,999.99")
		ElseIf I = 2
			aCalcTela[I]:=ZM0->ZM0_TIPO+"-"+aCalc[I]
		Else
			aCalcTela[I]:=aCalc[I]
		EndIf
	Next
	aAdd(aDadosTela,aCalcTela)
Next

If _lLog
   _cValores+=_cSegfOR
   _cValores:=StrTran(_cValores,".",",")
EndIf

_cMsgTop:='AEST046 - Calculo de custo do ICMS da filial atual / H.I.: '+cHoraIni+" - H.F.: "+TIME()+" / Dt Inicial: "+DToC(SToD(MV_PAR01))+" - Dt Final: "+DToC(SToD(MV_PAR02))

aTitAux:={}
aSizesAux:={}
For I := 1 To Len(aCampos)
    aAdd(aTitAux,aCampos[I,2])
    aAdd(aSizesAux,aCampos[I,3])
Next I

aTit:={}
aSizes:={}
For I := 1 To (Len(aTitAux)-4)
    aAdd(aTit,aTitAux[I])
    aAdd(aSizes,aSizesAux[I])
    If I = 8
       aAdd(aTit,aTitAux[19])
       aAdd(aSizes,aSizesAux[19])
       aAdd(aTit,aTitAux[20])
       aAdd(aSizes,aSizesAux[20])
    ElseIf I = 10
       aAdd(aTit,aTitAux[21])
       aAdd(aSizes,aSizesAux[21])
    ElseIf I = 16
       aAdd(aTit,aTitAux[22])
       aAdd(aSizes,aSizesAux[22])
    EndIf
Next I

aDadosAux:=aClone(aDadosTela)
aDadosTela:={}
For I := 1 To Len(aDadosAux)
    aDadosTAux:={}
    For T := 1 To (Len(aDadosAux[I])-4)
        aAdd(aDadosTAux,aDadosAux[I][T])
        If T = 8
           aAdd(aDadosTAux,aDadosAux[I][19])
           aAdd(aDadosTAux,aDadosAux[I][20])
        ElseIf T = 10
           aAdd(aDadosTAux,aDadosAux[I][21])
        ElseIf T = 16
           aAdd(aDadosTAux,aDadosAux[I][22])
        EndIf
    Next
    aAdd(aDadosTela,aDadosTAux)
Next I

aAdd(aDadosTela,ARRAY(Len(aCalcTela)))
nPos:=Len(aDadosTela)
aDadosTela[nPos,1]:=aCalc[01]
aDadosTela[nPos,2]:="Valor Estorno de perda com estrutura:"
aDadosTela[nPos,3]:=Transform(_nEPCE,"@E 999,999,999,999.99")

aAdd(aDadosTela,ARRAY(Len(aCalcTela)))
nPos:=Len(aDadosTela)
aDadosTela[nPos,1]:=aCalc[01]
aDadosTela[nPos,2]:="Valor Estorno de perda sem estrutura:"
aDadosTela[nPos,3]:=Transform(_nEPSE,"@E 999,999,999,999.99")

aAdd(aDadosTela,ARRAY(Len(aCalcTela)))
nPos:=Len(aDadosTela)
aDadosTela[nPos,1]:=aCalc[01]
aDadosTela[nPos,2]:="Valor Despesas do programa:"
aDadosTela[nPos,3]:=Transform(_nDP,"@E 999,999,999,999.99")

aAdd(aDadosTela,ARRAY(Len(aCalcTela)))
nPos:=Len(aDadosTela)
aDadosTela[nPos,1]:=aCalc[01]
aDadosTela[nPos,2]:="Valor Multas fiscais:" 
aDadosTela[nPos,3]:=Transform(_nMF,"@E 999,999,999,999.99")

aAdd(aDadosTela,ARRAY(Len(aCalcTela)))
nPos:=Len(aDadosTela)
aDadosTela[nPos,1]:=aCalc[01]
aDadosTela[nPos,2]:="Valor Bolsa Garantia:"
aDadosTela[nPos,3]:=Transform(_nBG,"@E 999,999,999,999.99")

aAdd(aDadosTela,ARRAY(Len(aCalcTela)))
nPos:=Len(aDadosTela)
aDadosTela[nPos,1]:=aCalc[01]
aDadosTela[nPos,2]:="Valor Anulacao de Credito:"
aDadosTela[nPos,3]:=Transform(_nAnulaCred,"@E 999,999,999,999.99")

aAdd(aDadosTela,ARRAY(Len(aCalcTela)))
nPos:=Len(aDadosTela)
aDadosTela[nPos,1]:=aCalc[01]
aDadosTela[nPos,2]:="Valor Glosa de Credito:"
aDadosTela[nPos,3]:=Transform(_nGlosaCred,"@E 999,999,999,999.99")

aAdd(aDadosTela,ARRAY(Len(aCalcTela)))
nPos:=Len(aDadosTela)
aDadosTela[nPos,1]:=aCalc[01]
aDadosTela[nPos,2]:="Valor Debito / codigo apuracao ICMS:"
aDadosTela[nPos,3]:=Transform(_nDebApurICMS,"@E 999,999,999,999.99")

aAdd(aDadosTela,ARRAY(Len(aCalcTela)))
nPos:=Len(aDadosTela)
aDadosTela[nPos,1]:=aCalc[01]
aDadosTela[nPos,2]:="Valor Credito / codigo apuracao ICMS:"
aDadosTela[nPos,3]:=Transform(_nCredApurICMS,"@E 999,999,999,999.99")

aAdd(aDadosTela,ARRAY(Len(aCalcTela)))
nPos:=Len(aDadosTela)
aDadosTela[nPos,1]:=aCalc[01]
aDadosTela[nPos,2]:="Valor Operacao Manaus:"
aDadosTela[nPos,3]:=Transform(_nODEB+_nODEB2,"@E 999,999,999,999.99")

If MV_PAR15 = "1"
	aAdd(aDadosTela,ARRAY(Len(aCalcTela)))
	nPos:=Len(aDadosTela)
	aDadosTela[nPos,1]:=aCalc[01]
	aDadosTela[nPos,2]:="Valor da compensação Sobras de Credito:"
	aDadosTela[nPos,3]:=Transform(If(lRecalc,nTotal17,0),"@E 999,999,999,999.99")
EndIf

If MV_PAR16 = "1"
	aAdd(aDadosTela,ARRAY(Len(aCalcTela)))
	nPos:=Len(aDadosTela)
	aDadosTela[nPos,1]:=aCalc[01]
	aDadosTela[nPos,2]:="Valor Desconciderado LP Recebido em Transferencia"
	aDadosTela[nPos,3]:=Transform(nVlrDesLPRecTrans,"@E 999,999,999,999.99")
EndIf

While Len(aDadosTela) > 0
                                  // , _aCols   ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,aSizes, _nCampo , bOk , bCancel, _abuttons )
   lRet:=U_ITListBox( _cMsgTop, aTit ,aDadosTela, .T.    , 1    ,_cMsgTop,          ,aSizes , 1       ,     ,        , )
                                                                                                 
   If  lRet 
       If !U_ITMsg("Confirmar gravar os dados calculados ?",'Atenção!',,2,2,2)
          Loop
       EndIf   
       AEST46Grv(_oSelf,_lEnd)
   ElseIf !U_ITMsg("TODOS OS CALCULOS SERÃO PERDIDOS, Confirmar SAIDA ?",'Atenção!',,3,2,2)
       Loop
   EndIf
   Exit
EndDo

Return .T.

/*
===============================================================================================================================
Programa----------: AEST046R()
Autor-------------: Alex Wallauer
Data da Criacao---: 27/03/2019
Descricao---------: Executa as SELECTs
Parametros--------: _oSelf,_lEnd,cSelect
Retorno-----------: Valor
===============================================================================================================================
*/
Static Function AEST046R(_oSelf,_lEnd,cSelect)

Local _nVlr:=0
Local _aTab:={}
Local _cQuery:=""

_nQuant:=0

If cSelect == "SELECT_01_B" .Or.  cSelect == "SELECT_01"
   If cSelect == "SELECT_01_B"
	   _cQuery:=" SELECT D2_COD D_COD, SUM(D2_QUANT) AS QTDE  "
   ElseIf cSelect == "SELECT_01"
	   _cQuery:=" SELECT SUM(D2_QUANT * SB1.B1_PESO) AS QTDE , SUM(D2_TOTAL) AS VLR "
   EndIf
   _cQuery+="       FROM "+RETSQLNAME("SD2")+" SD2"
   _cQuery+="       JOIN "+RetSqlName("SB1")+" SB1 ON SD2.D2_COD = SB1.B1_COD "
	_cQuery+=" WHERE SD2.D2_EMISSAO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND "
	_cQuery+="       SD2.D2_TP = 'PA' AND " 

	If !Empty(ZM0->ZM0_FILIS)
	   _cQuery+="    SD2.D2_FILIAL  IN " + FormatIn(AllTrim(ZM0->ZM0_FILIS),";")+" AND "
    Else
	   _cQuery+="    SD2.D2_FILIAL  = '"+cFilAnt+"' AND "
	EndIf

	If	!Empty(ZM0->ZM0_PROD)
		_cQuery+="    SD2.D2_COD     IN " + FormatIn(AllTrim(ZM0->ZM0_PROD),";")+" AND "
	ElseIf !Empty(ZM0->ZM0_NPROD)
		_cQuery+="    SD2.D2_COD NOT IN " + FormatIn(AllTrim(ZM0->ZM0_NPROD),";")+" AND "
	EndIf

	If	!Empty(ZM0->ZM0_ARMZ)
		_cQuery+="    SD2.D2_LOCAL  IN " + FormatIn(AllTrim(ZM0->ZM0_ARMZ),";")+" AND "
	EndIf

	If	!Empty(ZM0->ZM0_GRUPO)
		_cQuery+="    SD2.D2_GRUPO     IN " + FormatIn(AllTrim(ZM0->ZM0_GRUPO),";")+" AND "
	ElseIf !Empty(ZM0->ZM0_NGRUPO)
		_cQuery+="    SD2.D2_GRUPO NOT IN " + FormatIn(AllTrim(ZM0->ZM0_NGRUPO),";")+" AND "
	EndIf

	If	!Empty(ZM0->ZM0_CFOPV)
		_cQuery+="    SD2.D2_CF  IN " + FormatIn(AllTrim(ZM0->ZM0_CFOPV),";")+" AND "
	EndIf

	If	!Empty(ZM0->ZM0_TES)
		_cQuery+="    SD2.D2_TES     IN " + FormatIn(AllTrim(ZM0->ZM0_TES),";")+" AND "
	EndIf

	If	!Empty(ZM0->ZM0_NTES)
		_cQuery+="    SD2.D2_TES NOT IN " + FormatIn(AllTrim(ZM0->ZM0_NTES),";")+" AND "
	EndIf
	
	If	!Empty(ZM0->ZM0_UF)
		_cQuery+="    SD2.D2_EST      IN " + FormatIn(AllTrim(ZM0->ZM0_UF),";")+" AND "
	ElseIf !Empty(ZM0->ZM0_NUF)
		_cQuery+="    SD2.D2_EST  NOT IN " + FormatIn(AllTrim(ZM0->ZM0_NUF),";")+" AND "
	EndIf
	
	If ZM0->ZM0_RDBASE = "1"
  		_cQuery+=" ((SD2.D2_EST = '"+_cEstFilAnt+"' AND D2_TOTAL <> D2_BASEICM) OR SD2.D2_EST <> '"+_cEstFilAnt+"') AND "
	ElseIf ZM0->ZM0_RDBASE = "2"
  		_cQuery+=" ((SD2.D2_EST = '"+_cEstFilAnt+"' AND D2_TOTAL =  D2_BASEICM) OR SD2.D2_EST <> '"+_cEstFilAnt+"') AND "
	EndIf
	
	If ZM0->ZM0_TIPO = "1"
		_cQuery+=" D2_COD     IN (SELECT DISTINCT G1_COD FROM "+RETSQLNAME("SG1")+" WHERE D_E_L_E_T_ = ' ' AND G1_FILIAL = '"+cFilAnt+"') AND "
	ElseIf ZM0->ZM0_TIPO = "2"
		_cQuery+=" D2_COD NOT IN (SELECT DISTINCT G1_COD FROM "+RETSQLNAME("SG1")+" WHERE D_E_L_E_T_ = ' ' AND G1_FILIAL = '"+cFilAnt+"') AND "
	EndIf
	_cQuery+=" SD2.D_E_L_E_T_ = ' '  AND  SB1.D_E_L_E_T_ = ' ' "//NÃO PONHA O DELETE PARA CIMA DEIXE SEMPRE POR ULTIMO POR CAUSA DOS AND

   If cSelect == "SELECT_01_B"
	   _cQuery+=" GROUP BY D2_COD "
   EndIf

ElseIf cSelect == "SELECT_02" .Or. cSelect == "SELECT_02_B"

   If cSelect == "SELECT_02_B"
	   _cQuery:=" SELECT D1_COD D_COD, SUM(D1_QUANT) AS QTDE  "
   ElseIf cSelect == "SELECT_02"
	   _cQuery:="SELECT SUM(D1_QUANT * SB1.B1_PESO) AS QTDE, SUM(D1_TOTAL) AS VLR 
   EndIf   
   _cQuery+="       FROM "+RETSQLNAME("SD1")+" SD1"
   _cQuery+="       JOIN "+RetSqlName("SB1")+" SB1 ON SD1.D1_COD = B1_COD "
	_cQuery+="       JOIN "+RETSQLNAME("SF1")+" SF1 ON SD1.D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE AND D1_FORNECE = F1_FORNECE AND D1_LOJA = F1_LOJA "  
	_cQuery+=" WHERE SD1.D1_DTDIGIT BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND "
	_cQuery+="       SD1.D1_TP = 'PA' AND " 

	If !Empty(ZM0->ZM0_FILIS)
	   _cQuery+="    SD1.D1_FILIAL  IN " + FormatIn(AllTrim(ZM0->ZM0_FILIS),";")+" AND "
    Else
	   _cQuery+="    SD1.D1_FILIAL  = '"+cFilAnt+"' AND "
	EndIf

	If	!Empty(ZM0->ZM0_PROD)
		_cQuery+="    SD1.D1_COD     IN " + FormatIn(AllTrim(ZM0->ZM0_PROD),";")+" AND "
	ElseIf !Empty(ZM0->ZM0_NPROD)
		_cQuery+="    SD1.D1_COD NOT IN " + FormatIn(AllTrim(ZM0->ZM0_NPROD),";")+" AND "
	EndIf

	If	!Empty(ZM0->ZM0_ARMZ)
		_cQuery+="    SD1.D1_LOCAL  IN " + FormatIn(AllTrim(ZM0->ZM0_ARMZ),";")+" AND "
	EndIf

	If !Empty(ZM0->ZM0_GRUPO)
	   _cQuery+="   SD1.D1_GRUPO     IN " + FormatIn(AllTrim(ZM0->ZM0_GRUPO ),";")+" AND "
	ElseIf !Empty(ZM0->ZM0_NGRUPO)
		_cQuery+="   SD1.D1_GRUPO NOT IN " + FormatIn(AllTrim(ZM0->ZM0_NGRUPO),";")+" AND "
	EndIf
	
	If !Empty(ZM0->ZM0_CFOPD)
	   _cQuery+="   SD1.D1_CF IN " + FormatIn(AllTrim(ZM0->ZM0_CFOPD),";")+" AND "
	EndIf

	If	!Empty(ZM0->ZM0_TES)
		_cQuery+="    SD1.D1_TES     IN " + FormatIn(AllTrim(ZM0->ZM0_TES),";")+" AND "
	EndIf

	If	!Empty(ZM0->ZM0_NTES)
		_cQuery+="    SD1.D1_TES NOT IN " + FormatIn(AllTrim(ZM0->ZM0_NTES),";")+" AND "
	EndIf
	
	If !Empty(ZM0->ZM0_UF)
	   _cQuery+="   SF1.F1_EST     IN " + FormatIn(AllTrim(ZM0->ZM0_UF),";")+" AND "
	ElseIf !Empty(ZM0->ZM0_NUF)
	   _cQuery+="   SF1.F1_EST NOT IN " + FormatIn(AllTrim(ZM0->ZM0_NUF),";")+" AND "
	EndIf
	
	If ZM0->ZM0_RDBASE = "1"
  	   _cQuery+=" ((SF1.F1_EST = '"+_cEstFilAnt+"' AND SD1.D1_TOTAL <> SD1.D1_BASEICM) OR SF1.F1_EST <> '"+_cEstFilAnt+"') AND "
	ElseIf ZM0->ZM0_RDBASE = "2"
  	   _cQuery+=" ((SF1.F1_EST = '"+_cEstFilAnt+"' AND SD1.D1_TOTAL =  SD1.D1_BASEICM) OR SF1.F1_EST <> '"+_cEstFilAnt+"') AND "
	EndIf
	
	If ZM0->ZM0_TIPO = "1"
	   _cQuery+=" D1_COD     IN (SELECT DISTINCT G1_COD FROM "+RETSQLNAME("SG1")+" WHERE D_E_L_E_T_ = ' ' AND G1_FILIAL = '"+cFilAnt+"') AND "
	ElseIf ZM0->ZM0_TIPO = "2"
	   _cQuery+=" D1_COD NOT IN (SELECT DISTINCT G1_COD FROM "+RETSQLNAME("SG1")+" WHERE D_E_L_E_T_ = ' ' AND G1_FILIAL = '"+cFilAnt+"') AND "
	EndIf
	_cQuery+=" SD1.D_E_L_E_T_ = ' ' AND  SF1.D_E_L_E_T_ = ' '  AND  SB1.D_E_L_E_T_ = ' ' "//NÃO PONHA O DELETE PARA CIMA DEIXE SEMPRE POR ULTIMO POR CAUSA DOS AND

   If cSelect == "SELECT_02_B"
	   _cQuery+=" GROUP BY D1_COD "
   EndIf

ElseIf cSelect == "SELECT_03"

	_cQuery:=" SELECT SUM(SD3.D3_QUANT) AS VLR FROM " + RetSqlName("SD3") + " SD3 "
	_cQuery+=" WHERE SD3.D3_EMISSAO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND "
	_cQuery+="       SD3.D3_FILIAL = '" + cFilAnt + "' AND "
   _cQuery+="       SD3.D3_CF = 'RE1' AND "

	If	!Empty(ZM0->ZM0_MPCONS)
		_cQuery+="    SD3.D3_COD     IN " + FormatIn(AllTrim(ZM0->ZM0_MPCONS),";")+" AND "
	EndIf
	If	!Empty(ZM0->ZM0_CCCONS)
		_cQuery+="    SD3.D3_CC      IN " + FormatIn(AllTrim(ZM0->ZM0_CCCONS),";")+" AND "
	EndIf
	_cQuery  += "    SD3.D3_ESTORNO <> 'S' AND  SD3.D_E_L_E_T_ = ' '	"

ElseIf cSelect == "SELECT_04"

	_cQuery:="SELECT  D3_COD, D3_CF, SUM(D3_QUANT) QTDE FROM  " + RetSqlName("SD3") + " SD3 "
	_cQuery+=" WHERE  SD3.D_E_L_E_T_ = ' ' AND D3_FILIAL = '"+cFilAnt+"' AND "
	_cQuery+="       (SD3.D3_CF = 'RE1'  OR SD3.D3_CF = 'PR0') AND "
	_cQuery+="        SD3.D3_ESTORNO <> 'S' AND SD3.D3_I_ORIGE <> 'MATA685' AND "
	If	!Empty(ZM0->ZM0_MPCONS)
		_cQuery+="    SD3.D3_COD     IN " + FormatIn(AllTrim(ZM0->ZM0_MPCONS),";")+" AND "
	EndIf
	If	!Empty(ZM0->ZM0_CCCONS)
		_cQuery+="    SD3.D3_CC      IN " + FormatIn(AllTrim(ZM0->ZM0_CCCONS),";")+" AND "
	EndIf
	_cQuery+="        SD3.D3_EMISSAO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' "
	_cQuery+="  GROUP BY D3_COD, D3_CF "

ElseIf cSelect == "SELECT_05_COM_DT" .Or. cSelect == "SELECT_05_SEM_DT"

   _cQuery+=" SELECT D1_COD, MAX(D1_PICM) PICM, MAX(D1_VUNIT) VUNIT, MAX(D1_DTDIGIT) MAXDAT "
   _cQuery+=" FROM  " + RetSqlName("SD1") + " SD1 "  
   _cQuery+=" WHERE SD1.D_E_L_E_T_ = ' ' AND " 
   _cQuery+="       SD1.D1_FILIAL  = '" + cFilAnt + "' AND "
   _cQuery+="       SD1.D1_CF NOT IN ('1910', '2910', '1911', '2911', '1949', '2949','1920','1921','2920','2921') AND "
   _cQuery+="       SD1.D1_TIPO = 'N' AND "
   _cQuery+="       SD1.D1_DTDIGIT = (SELECT MAX(D1_DTDIGIT) "
   _cQuery+="                         FROM  " + RetSqlName("SD1") + " SD1 " 
   _cQuery+="                         WHERE SD1.D_E_L_E_T_ = ' ' AND "
   _cQuery+="                               SD1.D1_FILIAL  = '" + cFilAnt + "' AND " 
   _cQuery+="                               SD1.D1_CF NOT IN ('1910', '2910', '1911', '2911', '1949', '2949','1920','1921','2920','2921') AND "
   _cQuery+="                               SD1.D1_TIPO = 'N' AND "
   _cQuery+="                               SD1.D1_DTDIGIT <= '"+ MV_PAR02 + "' AND "
   _cQuery+="                               SD1.D1_COD IN " + FormatIn(AllTrim(cProd_EN_IN),";") + " AND " 
   _cQuery+="                               SD1.D_E_L_E_T_ = ' ') AND "
   _cQuery+="       SD1.D1_COD IN " + FormatIn(AllTrim(cProd_EN_IN),";") + " AND " 
   _cQuery+="       SD1.D_E_L_E_T_ = ' ' "
   _cQuery+=" GROUP BY D1_COD "

ElseIf cSelect == "SELECT_GRUPO_002"

	_cQuery:="SELECT  D3_COD, D3_CF, SUM(D3_QUANT) QTDE FROM  " + RetSqlName("SD3") + " SD3 "
	_cQuery+=" WHERE  SD3.D_E_L_E_T_ = ' ' AND D3_FILIAL = '"+cFilAnt+"' AND "
	_cQuery+="       (SD3.D3_CF = 'RE1'  OR SD3.D3_CF = 'PR0') AND "
	_cQuery+="        SD3.D3_ESTORNO <> 'S' AND SD3.D3_I_ORIGE <> 'MATA685' AND "
	If _cTipo = "INTEGRAL"
       _cItens:=AllTrim(SuperGetMV("IT_EST46IN",.F.,"08000000028;08140000001;08140000011" ))
   	   _cQuery+="     SD3.D3_COD IN "+FormatIn(_cItens,";")+" AND "
    ElseIf _cTipo = "DESNATADO"
       _cItens:=AllTrim(SuperGetMV("IT_EST4601DE",.F.,"08000000050;08140000002;08140000012" ))
   	   _cQuery+="     SD3.D3_COD IN "+FormatIn(_cItens,";")+" AND "
    ElseIf _cTipo = "LEITE CONDESADO"
       _cItens:=AllTrim(SuperGetMV("IT_EST46CO",.F.,"00030041402;08000000051" ))
   	   _cQuery+="     SD3.D3_COD IN "+FormatIn(_cItens,";")+" AND "
    EndIf
	_cQuery+="        SD3.D3_EMISSAO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' "
	_cQuery+="  GROUP BY D3_COD, D3_CF "

ElseIf cSelect == "SELECT_EPCE" .Or. cSelect == "SELECT_EPCE_2" .Or. cSelect == "SELECT_EPCE_3" .Or. cSelect == "SELECT_EPCE_4" .Or. cSelect == "SELECT_EPCE_5" 

   If cSelect == "SELECT_EPCE_5"
      _cQuery:=" SELECT SUM(D2_TOTAL) AS VLR  "
   Else 
      _cQuery:=" SELECT D2_COD D_COD, SUM(D2_QUANT) AS QTDE  "
   EndIf
	_cQuery+=" FROM "+RETSQLNAME("SD2")+" SD2"
	_cQuery+=" WHERE SD2.D2_FILIAL = '"+cFilAnt+"' AND "
	_cQuery+="       SD2.D2_EMISSAO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND "
   If cSelect == "SELECT_EPCE_3"
	   
      _cQuery+="    SD2.D2_CF = '6109' AND "
   
   ElseIf cSelect == "SELECT_EPCE_4"
	   
      _cQuery+="    SD2.D2_CF = '6110' AND "
   Else
	   
      _cQuery+="    SD2.D2_CF = '5927' AND "
   EndIf
   If cSelect == "SELECT_EPCE" .Or. cSelect == "SELECT_EPCE_5"
	    
      _cQuery+="    SD2.D2_COD IN " 
	   _cQuery+="    (SELECT G1_COD FROM "+RETSQLNAME("SG1")+" SG1 WHERE SG1.D_E_L_E_T_ = ' ' AND SG1.G1_FILIAL IN '"+cFilAnt+"' GROUP BY G1_COD "
	   _cQuery+="     UNION "
	   _cQuery+="     SELECT G1_COMP FROM "+RETSQLNAME("SG1")+" SG1 JOIN "+RETSQLNAME("SB1")+" SB1 ON G1_COMP = B1_COD "
	   _cQuery+="            WHERE SG1.D_E_L_E_T_ = ' ' AND SB1.D_E_L_E_T_ = ' ' AND SG1.G1_FILIAL IN '"+cFilAnt+"' AND B1_TIPO IN ('MP','PP','PI','EM','IN','MC') GROUP BY G1_COMP "
      _cQuery+="    ) AND "
   
   ElseIf cSelect == "SELECT_EPCE_2"
	    
      _cQuery+="    SD2.D2_TP IN  ('IN','EM','MC') AND "
   EndIf    
	_cQuery+="       SD2.D_E_L_E_T_ = ' ' "

   If cSelect <> "SELECT_EPCE_5"
      _cQuery+="  GROUP BY D2_COD "
   EndIf   

ElseIf cSelect == "SELECT_ODEB_1"// VALOR DOS CRÉDITOS:

   _cQuery:=" SELECT (NVL(T.VLR1,0) - NVL(D.VLR2,0)) AS VLR "
	_cQuery+="       FROM (SELECT D1_FILIAL, DECODE(SUM(D1_VALICM),NULL,0,SUM(D1_VALICM)) AS VLR1
   _cQuery+="                    FROM "+RETSQLNAME("SD1")+" SD1 "
   _cQuery+="                    JOIN "+RETSQLNAME("SF4")+" SF4 ON F4_FILIAL = D1_FILIAL AND F4_CODIGO = D1_TES "
   _cQuery+="                    WHERE  SD1.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' AND  "
   _cQuery+="                           SD1.D1_FILIAL = '"+cFilAnt+"'  AND D1_DTDIGIT BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND F4_CREDICM = 'S' GROUP BY D1_FILIAL) T "
   _cQuery+="            FULL OUTER JOIN "
	_cQuery+="            (SELECT D1_FILIAL, DECODE(SUM(D1_VALICM),NULL,0,SUM(D1_VALICM))  AS VLR2 "
   _cQuery+="                    FROM "+RETSQLNAME("SD1")+" SD1 "
   _cQuery+="                    JOIN "+RETSQLNAME("SF4")+" SF4 ON F4_FILIAL = D1_FILIAL AND F4_CODIGO = D1_TES "
   _cQuery+="                    WHERE  SD1.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' AND  "
   _cQuery+="                           SD1.D1_FILIAL = '"+cFilAnt+"'  AND D1_DTDIGIT BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND F4_CREDICM = 'S' AND F4_SITTRIB = '90' "
   _cQuery+="                           AND D1_CF IN ('1101', '2101') AND D1_TIPO = 'N' GROUP BY D1_FILIAL) D "
   _cQuery+="       ON D.D1_FILIAL = T.D1_FILIAL "

ElseIf cSelect == "SELECT_ODEB_2" //VALOR ZONA FRANCA DE MANAUS:

   _cQuery:=" SELECT SUM(D2_VALBRUT) AS VLR "
   _cQuery+="        FROM "+RETSQLNAME("SD2")+" SD2 "
   _cQuery+="        WHERE  SD2.D_E_L_E_T_ = ' ' AND D2_FILIAL  = '"+cFilAnt+"'  AND "
   _cQuery+="               SD2.D2_EMISSAO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND D2_CF IN ('6109', '6110') "

ElseIf cSelect == "SELECT_ODEB_3" //VALOR TOTAL:

   _cQuery:=" SELECT SUM(D2_VALBRUT) AS VLR "
   _cQuery+="        FROM "+RETSQLNAME("SD2")+" SD2 "
   _cQuery+="        WHERE  SD2.D_E_L_E_T_ = ' ' AND D2_FILIAL  = '"+cFilAnt+"'  AND "
   _cQuery+="               SD2.D2_EMISSAO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' "
   
ElseIf cSelect == "SELECT_EPSE" .Or. cSelect == "SELECT_EPSE_MV03=1"

   If cSelect == "SELECT_EPSE"
	   _cQuery:="SELECT SUM(D2_TOTAL) AS VLR FROM "+RETSQLNAME("SD2")+" SD2"
   Else //cSelect == "SELECT_EPSE_MV03=1"
      _cQuery:="SELECT D2_COD D_COD, SUM(D2_QUANT) AS QTDE FROM "+RETSQLNAME("SD2")+" SD2"
   EndIf

	_cQuery+=" WHERE SD2.D2_FILIAL = '"+cFilAnt+"' AND
	_cQuery+="       SD2.D2_EMISSAO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND "
	_cQuery+="       SD2.D_E_L_E_T_ = ' ' AND "
	_cQuery+="       SD2.D2_CF = '5927' AND "
	_cQuery+="       SD2.D2_COD NOT IN " 
	_cQuery+="   (SELECT G1_COD FROM "+RETSQLNAME("SG1")+" SG1 WHERE SG1.D_E_L_E_T_ = ' ' AND SG1.G1_FILIAL IN '"+cFilAnt+"' GROUP BY G1_COD "
   _cQuery+="     UNION "
	_cQuery+="     SELECT G1_COMP FROM "+RETSQLNAME("SG1")+" SG1 JOIN "+RETSQLNAME("SB1")+" SB1 ON G1_COMP = B1_COD "
	_cQuery+="            WHERE SG1.D_E_L_E_T_ = ' ' AND SB1.D_E_L_E_T_ = ' ' AND SG1.G1_FILIAL IN '"+cFilAnt+"' AND B1_TIPO IN ('MP','PP','PI','EM','IN','MC') GROUP BY G1_COMP "
   _cQuery+="    )"
   If cSelect = "SELECT_EPSE_MV03=1"
      _cQuery+="  GROUP BY D2_COD "
   EndIf   

// * ZM0_ESPERD

ElseIf cSelect == "SELECT_DP"

	_cQuery:="SELECT SUM(E5_VALOR) AS VLR FROM "+RETSQLNAME("SE5")+" SE5 " 
	_cQuery+=" WHERE SE5.E5_FILIAL = '"+cFilAnt+"' AND "
	_cQuery+="       SE5.E5_DATA BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND "
	_cQuery+="       SE5.D_E_L_E_T_ = ' ' AND "
	_cQuery+="       SE5.E5_NATUREZ IN " + FormatIn(AllTrim(MV_PAR04),";")

ElseIf cSelect == "SELECT_MF"

	_cQuery:="SELECT SUM(E5_VALOR) AS VLR FROM "+RETSQLNAME("SE5")+" SE5 " 
	_cQuery+=" WHERE SE5.E5_FILIAL = '"+cFilAnt+"' AND "
	_cQuery+="       SE5.E5_DATA BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND "
 	_cQuery+="       SE5.D_E_L_E_T_ = ' ' AND "
	_cQuery+="       SE5.E5_NATUREZ IN " + FormatIn(AllTrim(MV_PAR05),";")+" AND "
	_cQuery+="       SE5.E5_TIPO = 'ICM' "

ElseIf cSelect == "SELECT_BG_SE5"

	_dInicial := DToS(MonthSum(SToD(MV_PAR01),1)) //Soma Meses em Uma Data
	_dFinal	  := DToS(MonthSum(SToD(MV_PAR02),1)) //Soma Meses em Uma Data	 

	_cQuery:="SELECT SUM(E5_VALOR) AS VLR FROM "+RETSQLNAME("SE5")+" SE5 " 
	_cQuery+=" WHERE SE5.E5_FILIAL = '"+cFilAnt+"' AND "
	_cQuery+="       SE5.E5_DATA BETWEEN '"+_dInicial+"' AND '"+_dFinal+"' AND "
   If !Empty(MV_PAR06)
	   _cQuery+="    SE5.E5_NATUREZ IN " + FormatIn(AllTrim(MV_PAR06),";")+" AND "
   EndIf   
	_cQuery+="       SE5.D_E_L_E_T_ = ' '"

ElseIf cSelect == "SELECT_BG_SE2"

	_dInicial := DToS(MonthSum(SToD(MV_PAR01),1)) //Soma Meses em Uma Data
	_dFinal	  := DToS(MonthSum(SToD(MV_PAR02),1)) //Soma Meses em Uma Data	 

	_cQuery:="SELECT SUM(E2_VALOR) AS VLR FROM "+RETSQLNAME("SE2")+" SE2 " 
	_cQuery+=" WHERE SE2.E2_FILIAL = '"+cFilAnt+"' AND "
	_cQuery+="       SE2.E2_VENCREA  BETWEEN '"+_dInicial+"' AND '"+_dFinal+"' AND "
   If !Empty(MV_PAR06)
	   _cQuery+="    SE2.E2_NATUREZ IN " + FormatIn(AllTrim(MV_PAR06),";")+" AND "
   EndIf
	_cQuery+="       SE2.D_E_L_E_T_ = ' '"

ElseIf cSelect == "SELECT_ANULACAO_CREDITO"

	_cQuery:="SELECT NVL(DECODE(SUM(SD2.D2_VALICM),0,SUM(D1_VALICM),SUM(D2_VALICM)),0) AS VLR "
 	_cQuery+="       FROM "+RETSQLNAME("SD2")+" SD2 INNER JOIN "+RETSQLNAME("SD1")+"  SD1 "
   _cQuery+="         ON SD2.D2_FILIAL = SD1.D1_FILIAL AND SD2.D2_NFORI = SD1.D1_DOC AND "
   _cQuery+="            SD2.D2_COD = SD1.D1_COD  AND SD2.D2_CLIENTE = SD1.D1_FORNECE "
	_cQuery+=" WHERE SD2.D2_FILIAL = '"+cFilAnt+"' AND "
	_cQuery+="       SD2.D2_EMISSAO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND "
	_cQuery+="       SD2.D_E_L_E_T_ = ' ' AND SD1.D_E_L_E_T_ = ' ' AND "
	_cQuery+="       SD2.D2_CF IN ('5206', '6206') "

ElseIf cSelect == "SELECT_GLOSA_CREDITO"

	_cQuery:="SELECT NVL(SUM(D2_TOTAL),0) AS VLR "
 	_cQuery+="     FROM "+RETSQLNAME("SD2")+" SD2 "
   _cQuery+="     JOIN "+RETSQLNAME("SF4")+" SF4 ON F4_FILIAL = D2_FILIAL  AND F4_CODIGO = D2_TES "
   _cQuery+="     WHERE SD2.D_E_L_E_T_ = ' ' AND  SF4.D_E_L_E_T_ = ' ' AND "
	_cQuery+="           SD2.D2_FILIAL = '"+cFilAnt+"' AND "
	_cQuery+="           SD2.D2_EMISSAO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND "
 	_cQuery+="           SF4.F4_FINALID LIKE '%GLOSA%' "


ElseIf cSelect == "SELECT_DEB_COD_APUR_ICMS"

	_cQuery:="SELECT NVL(SUM(CDH_VALOR),0) AS VLR "
 	_cQuery+="     FROM "+RETSQLNAME("CDH")+" CDH "
    _cQuery+="     WHERE CDH.D_E_L_E_T_ = ' ' AND CDH_LA = 'S' AND "
	_cQuery+="           CDH_FILIAL = '"+cFilAnt+"' AND "
	_cQuery+="           CDH_DTINI = '"+MV_PAR01+"' AND CDH_DTFIM  = '"+MV_PAR02+"' AND "
	_cQuery+="           CDH_CODLAN IN " + FormatIn(AllTrim(MV_PAR11),";") 

ElseIf cSelect == "SELECT_CRE_COD_APUR_ICMS"

	_cQuery:="SELECT NVL(SUM(CDH_VALOR),0) AS VLR "
 	_cQuery+="     FROM "+RETSQLNAME("CDH")+" CDH "
    _cQuery+="     WHERE CDH.D_E_L_E_T_ = ' ' AND CDH_LA = 'S' AND "
	_cQuery+="           CDH_FILIAL = '"+cFilAnt+"' AND "
	_cQuery+="           CDH_DTINI = '"+MV_PAR01+"' AND CDH_DTFIM  = '"+MV_PAR02+"' AND "
	_cQuery+="           CDH_CODLAN IN " + FormatIn(AllTrim(MV_PAR12),";") 

ElseIf cSelect == "SELECT_DESC_BENEF_LP_INTEGRAL"

	_cQuery:="  SELECT (NVL(ENTRLP.QTD, 0) - NVL(SAIDLP.QTD, 0) ) AS VLR"//NQTD 
 	_cQuery+="     FROM
 	_cQuery+="  (SELECT DECODE(SUM(D1_QUANT),NULL,0,SUM(D1_QUANT)) AS QTD FROM "+RETSQLNAME("SD1")+" SD1 " 
 	_cQuery+="     WHERE SD1.D_E_L_E_T_ = ' ' AND D1_FILIAL = '"+cFilAnt+"' AND 
 	_cQuery+="           D1_DTDIGIT BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND "
 	_cQuery+="           D1_CF = '2151' AND 
 	_cQuery+="           SubStr(D1_COD,1,9) = '000200105') ENTRLP, 
 	_cQuery+="  (SELECT DECODE(SUM(D2_QUANT),NULL,0,SUM(D2_QUANT)) AS QTD FROM "+RETSQLNAME("SD2")+" SD2 " 
 	_cQuery+="     WHERE SD2.D_E_L_E_T_ = ' ' AND " 
 	_cQuery+="           D2_FILIAL = '"+cFilAnt+"' AND 
    _cQuery+="         	 D2_EMISSAO BETWEEN '"+MV_PAR01+"' AND  '"+MV_PAR02+"' AND "
    _cQuery+="           D2_CF = '6102' AND "
 	_cQuery+="           SubStr(D2_COD,1,9) = '000200105') SAIDLP   "

ElseIf cSelect == "SELECT_DESC_BENEF_LP_DESNATADO"

	_cQuery:="  SELECT (NVL(ENTRLP.QTD, 0) - NVL(SAIDLP.QTD, 0) ) AS VLR"//NQTD 
 	_cQuery+="     FROM
 	_cQuery+="  (SELECT DECODE(SUM(D1_QUANT),NULL,0,SUM(D1_QUANT)) AS QTD FROM "+RETSQLNAME("SD1")+" SD1 " 
 	_cQuery+="     WHERE SD1.D_E_L_E_T_ = ' ' AND D1_FILIAL = '"+cFilAnt+"' AND 
 	_cQuery+="           D1_DTDIGIT BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' AND "
 	_cQuery+="           D1_CF = '2151' AND 
 	_cQuery+="           SubStr(D1_COD,1,9) = '000200205') ENTRLP, 
 	_cQuery+="  (SELECT DECODE(SUM(D2_QUANT),NULL,0,SUM(D2_QUANT)) AS QTD FROM "+RETSQLNAME("SD2")+" SD2 " 
 	_cQuery+="     WHERE SD2.D_E_L_E_T_ = ' ' AND " 
 	_cQuery+="           D2_FILIAL = '"+cFilAnt+"' AND 
    _cQuery+="         	 D2_EMISSAO BETWEEN '"+MV_PAR01+"' AND  '"+MV_PAR02+"' AND "
    _cQuery+="           D2_CF = '6102' "
 	_cQuery+="     AND SubStr(D2_COD,1,9) = '000200205') SAIDLP   "

ElseIf cSelect == "SELECT_NECESSIDADE_INTEGRAL"

	_cQuery:="  SELECT D3_COD, "
	_cQuery+="         (RATIO_TO_REPORT(SUM(D3_QTSEGUM)) OVER () ) AS PERC_PRD, "
	_cQuery+="         B1_I_QT3UM AS MINVENDA, B1_CONV, " 
	_cQuery+="         B1_TIPCONV "
	_cQuery+="         FROM "+RETSQLNAME("SD3")+" SD3 JOIN "+RETSQLNAME("SB1")+" SB1  ON D3_COD = B1_COD "
	_cQuery+="         WHERE SD3.D_E_L_E_T_ = ' ' AND SB1.D_E_L_E_T_ = ' ' "
	_cQuery+="         AND D3_FILIAL IN ('01') AND SubStr(D3_COD,1,7) = '0002001' AND D3_SEGUM = 'KG' "
	_cQuery+="         AND D3_EMISSAO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"' "
	_cQuery+="         AND D3_ESTORNO <> 'S' AND D3_CF = 'PR0' AND D3_LOCAL = '30' "
	_cQuery+="         GROUP BY D3_COD, B1_I_QT3UM, B1_CONV, B1_TIPCONV  " 
	_cQuery+="         ORDER BY B1_I_QT3UM DESC "

ElseIf cSelect == "SELECT_NECESSIDADE_DESNATADO"

	_cQuery:="  SELECT D3_COD, "
	_cQuery+="         (RATIO_TO_REPORT(SUM(D3_QTSEGUM)) OVER () ) AS PERC_PRD, "
	_cQuery+="         B1_I_QT3UM AS MINVENDA, B1_CONV, " 
	_cQuery+="         B1_TIPCONV "
	_cQuery+="         FROM "+RETSQLNAME("SD3")+" SD3 JOIN "+RETSQLNAME("SB1")+" SB1  ON D3_COD = B1_COD "
	_cQuery+="         WHERE SD3.D_E_L_E_T_ = ' ' AND SB1.D_E_L_E_T_ = ' ' "
	_cQuery+="         AND D3_FILIAL IN ('01') AND SubStr(D3_COD,1,7) = '0002002' AND D3_SEGUM = 'KG' "
	_cQuery+="         AND D3_EMISSAO BETWEEN '"+MV_PAR01+"' AND  '"+MV_PAR02+"' "
	_cQuery+="         AND D3_ESTORNO <> 'S' AND D3_CF = 'PR0' AND D3_LOCAL = '30' "
	_cQuery+="         GROUP BY D3_COD, B1_I_QT3UM, B1_CONV, B1_TIPCONV  " 
	_cQuery+="         ORDER BY B1_I_QT3UM DESC "

ElseIf cSelect == "SELECT_BG_GIGANTE"

   _cQuery:=AEST46BG()

ElseIf cSelect == "SELECT_MIX_VLR"

   _cQuery:=GetVlrMix()

ElseIf cSelect == "SELECT_MIX_VOL"

   _cQuery:=VolLeite()

EndIf

Begin Sequence

   _cQValores:=""
   _lRetTab:=(cSelect == "SELECT_GRUPO_002" .Or. cSelect == "SELECT_04"        .Or. cSelect == "SELECT_01_B" .Or. cSelect == "SELECT_EPCE"   .OR.;
              cSelect == "SELECT_05_COM_DT" .Or. cSelect == "SELECT_05_SEM_DT" .Or. cSelect == "SELECT_02_B" .Or. cSelect == "SELECT_EPCE_2" .OR.;
              cSelect == "SELECT_EPCE_3"    .Or. cSelect == "SELECT_EPCE_4"    .Or. cSelect == "SELECT_EPSE_MV03=1" .Or. "SELECT_NECESSIDADE" $ cSelect)

   _lRetCOD_QTDE:=(cSelect == "SELECT_01_B"   .Or. cSelect == "SELECT_02_B"   .Or. cSelect == "SELECT_EPCE"  .Or. cSelect == "SELECT_EPCE_2" .OR.;
                   cSelect == "SELECT_EPCE_3" .Or. cSelect == "SELECT_EPCE_4" .Or. cSelect == "SELECT_EPSE_MV03=1")
   
   MPSysOpenQuery( ChangeQuery(_cQuery) ,"TRB" ) 

   If _lRetTab//QUANDO O RETORNO É UMA TABELA DE VARIAS COLUNAS E LINHAS
      While .Not. TRB->( Eof() )
         If _lRetCOD_QTDE//DEVOLVE CODIGO + QTDE
            aAdd(_aTab,{TRB->D_COD,TRB->QTDE})
            _cQValores+= "RG: "+ZM0->ZM0_CODEVE+" ; "+TRB->D_COD+" ; "+Str(TRB->QTDE,22,7)+CRLF
         
         ElseIf cSelect == "SELECT_05_COM_DT" .Or. cSelect == "SELECT_05_SEM_DT"// DEVOLVE CODIGO + VLR UNIT + ICMS
            aAdd(_aTab,{TRB->D1_COD,TRB->VUNIT,(TRB->PICM/100)})
            _cQValores+= "RG: "+ZM0->ZM0_CODEVE+" ; "+TRB->D1_COD+" ; "+Str(TRB->VUNIT,22,7)+" ; "+Str(TRB->PICM/100,22,7)+CRLF

         ElseIf "SELECT_NECESSIDADE" $ cSelect
         
            aAdd(_aTab,{TRB->D3_COD,TRB->PERC_PRD,TRB->MINVENDA,TRB->B1_CONV,TRB->B1_TIPCONV})

            _cQValores+= "RG: "+ZM0->ZM0_CODEVE+" ; "+TRB->D3_COD+" ; "+Str(TRB->PERC_PRD,22,7)+" ; "+Str(TRB->MINVENDA,22,7)+" ; "+Str(TRB->B1_CONV,22,7)+" ; "+TRB->B1_TIPCONV+CRLF

         Else //DEVOLVE CODIGO + CF + QTDE
            aAdd(_aTab,{TRB->D3_COD,TRB->D3_CF,TRB->QTDE})
            _cQValores+= "RG: "+ZM0->ZM0_CODEVE+" ; "+TRB->D3_COD+" ; "+TRB->D3_CF+" ; "+Str(TRB->QTDE,22,7)+CRLF
         EndIf
         TRB->( DBSkip() )
      EndDo
   
   Else//RETORNA UM VALOR OU/E UMA QUANTIDADE 
      If .NOT. TRB->( Eof() )
         _nVlr:=TRB->VLR
         If cSelect == "SELECT_01" .Or. cSelect == "SELECT_02"
            _nQuant:=TRB->QTDE
            _cQValores+="RG: "+ZM0->ZM0_CODEVE+"; "+Str(_nQuant,22,7)+CRLF
         EndIf
      EndIf
      _cQValores+="RG: "+ZM0->ZM0_CODEVE+"; "+Str(_nVlr,22,7)+CRLF
   EndIf

RECOVER
   
End Sequence

_cLogQuerys+="RG: "+ZM0->ZM0_CODEVE+"; "+cSelect+"; "+_cQuery+CRLF+_cQValores
_cLogQuerys+="********************************************************************************************************"+CRLF

TRB->( DBCloseArea() )

If _lRetTab
   Return _aTab
Else
   Return _nVlr
EndIf

/*
===============================================================================================================================
Programa----------: AEST46Grv()
Autor-------------: Alex Wallauer
Data da Criacao---: 27/03/2019
Descricao---------: Grava dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================*/
Static Function AEST46Grv(_oSelf,_lEnd)

Local nConta:= 0 , I , C
Local nTotal:=Len(aDadosCalc)

If nTotal = 0
   U_ITMsg("Não tem registros para gravação",'Atenção!',,1)
   Return .F.
EndIf
_oSelf:SetRegua1( nTotal+1 )
_oSelf:SetRegua2( nTotal+1 )
_oSelf:IncRegua1("Gravando Dados, Aguarde..." )
_oSelf:IncRegua2("Gravando Dados, Aguarde..." )
_cTotReg:=AllTrim(Str(nTotal))

ZM1->(DBSetOrder(1))//ZM1_FILIAL+ZM1_DATARQ+ZM1_CODEVE
ZM0->(DBSetOrder(1))//"ZM0_FILIAL+ZM0_CODEVE"

For I := 1 To nTotal
    nConta++
    _oself:IncRegua1("Gravando Regra: "+LEFT(aDadosCalc[I,2],25))
    _oself:IncRegua2("Gravando Regra: "+AllTrim(Str(nConta,6))+" de "+_cTotReg)
    ProcessMessages()
    If "[BLOQUEADO]" $ aDadosCalc[I,2]//ZM0->(DBSeek( xFilial()+ LEFT(aDadosCalc[I,2],Len(ZM0->ZM0_CODEVE)))) .And. ZM0->ZM0_MSBLQL = "1"
       Loop
    EndIf    

    If ZM1->(DBSeek( xFilial()+ aDadosCalc[I,1] + LEFT(aDadosCalc[I,2],Len(ZM1->ZM1_CODEVE))))
       ZM1->(RecLock("ZM1",.F.))
    Else
       ZM1->(RecLock("ZM1",.T.))   
    EndIf
    ZM1->ZM1_FILIAL:=xFilial("ZM1")
    For C := 1 To Len(aCampos)
        ZM1->(FieldPut( FieldPos(aCampos[C][1]),aDadosCalc[I,C]))
    Next C
    ZM1->(MSUnLock())
Next I
nConta:=0
ZM1->(DBSeek( xFilial()+ aDadosCalc[1,1]))
While ZM1->(!Eof()) .And. ZM1->ZM1_FILIAL == xFilial("ZM0") .And. ZM1->ZM1_DATARQ == aDadosCalc[1,1] 
   nConta++
    _oself:IncRegua2("Limpando Regras: "+AllTrim(Str(nConta,6)) )
    ProcessMessages()
    If !ZM0->(DBSeek( xFilial()+ZM1->ZM1_CODEVE)) .Or. ZM0->ZM0_MSBLQL = "1"
       ZM1->(RecLock("ZM1",.F.))
       ZM1->(DBDELETE())
       ZM1->(MSUnLock())
    EndIf
    ZM1->(DBSkip())
EndDo

U_ITMsg("Dados gravados com sucesso",'Atenção!',_cTotReg+" regras gravadas para "+aDadosCalc[1,1],2)

Return

/*
===============================================================================================================================
Programa----------: GetVlrMix
Autor-------------: Alex Wallauer
Data da Criacao---: 14/05/2019
Descrição---------: Retorna total de movimentos na ZLF de determinado evento
Parametros--------: Nenhum
Retorno-----------: Valor Total do volume de leite
===============================================================================================================================*/
Static Function GetVlrMix()

Local cQuery := '' , _nI
Local _cSetor:= ""

ZLT->(DBSetOrder(1))
ZLT->(DBSeek(xFilial()+cFilant))
_cSetor:=AllTrim(ZLT->ZLT_SETOR)

If RIGHT(_cSetor,1) = ";"
   _cSetor:=LEFT(_cSetor, Len(_cSetor)-1 )
EndIf

_aSetor :=StrTokArr(_cSetor,';')
_cSetor:=""
For _nI := 1 To Len(_aSetor)
    If LEFT(_aSetor[_nI],2) = cFilant
       _cSetor+=_aSetor[_nI]+";"
    EndIf   
Next _nI
If Right(_cSetor,1) = ";"
   _cSetor:=Left(_cSetor, Len(_cSetor)-1 )
EndIf

// Obtendo movimentos na ZLF do grupo corrente                                  |
cQuery := " SELECT SUM(ZLF.ZLF_TOTAL) AS VLR "
cQuery += " FROM "+ RetSqlName("ZLF") +" ZLF "
cQuery += " WHERE D_E_L_E_T_	= ' ' "
cQuery += "  AND ZLF.ZLF_DTINI BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"'"
cQuery += "  AND ZLF.ZLF_DTFIM BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"'"
cQuery += "  AND ZLF_SETOR IN " + FormatIn(AllTrim(_cSetor),";")
cQuery += "  AND ZLF.ZLF_TP_MIX = 'L' "
cQuery += "  AND ZLF.ZLF_ENTMIX = 'S' "
cQuery += "  AND ZLF.ZLF_DEBCRE = 'C' "
cQuery += "  AND EXISTS ( SELECT ZL8.ZL8_COD "
cQuery += "              FROM "+ RetSqlName("ZL8") +" ZL8 "
cQuery += "              WHERE ZL8.D_E_L_E_T_ = ' '  "
cQuery += "              AND ZL8.ZL8_FILIAL = ZLF.ZLF_FILIAL "
cQuery += "              AND ZL8.ZL8_COD    = ZLF.ZLF_EVENTO "
cQuery += "              AND ZL8.ZL8_MIX    = 'S' ) "
Return( cQuery )

/*
===============================================================================================================================
Programa----------: VolLeite(()
Autor-------------: Alex Wallauer
Data da Criacao---: 14/05/2019
Descrição---------: Retorna volume de leite (ZLD)
Parametros--------: Nenhum
Retorno-----------: Total do volume de leite
===============================================================================================================================*/
Static Function VolLeite()

Local _cQuery	:= '' , _nI
Local _cSetor  := ""
ZLT->(DBSetOrder(1))
ZLT->(DBSeek(xFilial()+cFilant))
_cSetor:=AllTrim(ZLT->ZLT_SETOR)
If Right(_cSetor,1) = ";"
   _cSetor:=Left(_cSetor, Len(_cSetor)-1 )
EndIf
_aSetor :=StrTokArr(_cSetor,';')
_cSetor:=""
For _nI := 1 To Len(_aSetor)
    If Left(_aSetor[_nI],2) = cFilant
       _cSetor+=_aSetor[_nI]+";"
    EndIf   
Next _nI
If Right(_cSetor,1) = ";"
   _cSetor:=Left(_cSetor, Len(_cSetor)-1 )
EndIf

_cQuery := " SELECT 	SUM(ZLD_QTDBOM) AS VLR "
_cQuery += " FROM  "+ RETSQLNAME( 'ZLD' ) +" ZLD "
_cQuery += " WHERE ZLD_SETOR  IN " + FormatIn(AllTrim(_cSetor),";")
_cQuery += " AND ZLD_DTCOLE BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'"
_cQuery += " AND ZLD.D_E_L_E_T_ = ' ' "

Return _cQuery

/*
===============================================================================================================================
Programa----------: AEST46Ren
Autor-------------: Alex Wallauer
Data da Criacao---: 14/05/2019
Descrição---------: Retorna volume de leite (ZLD)
Parametros--------: Nenhum
Retorno-----------: Total do volume de leite
===============================================================================================================================*/
Static Function AEST46Ren(_aRendim,aRegra)

Local _nRen:=0
nValor1:=0
nValor2:=0
nValor3:=0

If (nPos:=aScan(_aRendim, { |R| R[1] = aRegra[1] .And. R[2] = aRegra[2]  })) <> 0
   nValor1:=_aRendim[nPos,3]
EndIf
If Len(aRegra) > 2
   If (nPos:=aScan(_aRendim, { |R| R[1] = aRegra[3] .And. R[2] = aRegra[4]  })) <> 0
      nValor2:=_aRendim[nPos,3]
   EndIf
EndIf
If Len(aRegra) > 4
   If (nPos:=aScan(_aRendim, { |R| R[1] = aRegra[5] .And. R[2] = aRegra[6]  })) <> 0
      nValor3:=_aRendim[nPos,3]
   EndIf 
EndIf 

_nRen:=nValor1/(nValor2+nValor3)

Return _nRen

/*
===============================================================================================================================
Programa----------: AEST46Val
Autor-------------: Alex Wallauer
Data da Criacao---: 14/05/2019
Descrição---------: Retorna volume de leite (ZLD)
Parametros--------: Nenhum
Retorno-----------: Total do volume de leite
===============================================================================================================================*/
Static Function AEST46Val()

Local aRegra:=StrTran(AllTrim(M->ZM0_BASREN),"/",";")

aRegra:=StrTokArr(aRegra,';')
If !Empty(M->ZM0_PRSOPE) .And. Empty(M->ZM0_OPREN) .And. (Len(aRegra) < 4 .Or. (!aRegra[1] $ M->ZM0_MPCONS .Or. !aRegra[3] $ M->ZM0_MPCONS))
   U_ITMsg("Campo Base Rendimento [ZM0_BASREN] preenchido incorretamente. Formato [ Produto ; Tipo de movimento / Produto ; Tipo de movimento ] ","Atenção!",;
           "Os 2 produtos desse campo tambem devem estar no campo MP Consumo [ZM0_MPCONS].",1 )
   Return .F.    
EndIf

Return .T.
/*
===============================================================================================================================
Programa----------: AEST46Estr
Autor-------------: Alex Wallauer
Data da Criacao---: 14/05/2019
Descrição---------: Itens da explosao
Parametros--------: _aProdutos: codigos pai para explosão da estrutura
Retorno-----------: aTp_EM_IN: tabela com os itens da explosao / cProd_EN_IN: codigos dos itens da explosao
===============================================================================================================================
*/
Static Function AEST46EStr(_aProdutos)

Local E , P
Local aEstrProd:={}
Local _nQtde := 0
Local aTp_EM_IN:={}
Private nEstru:= 0

_cTeste+="REGRA;ITEM PAI ; QTDE ; ITEM FILHO ; QTDE "+CRLF
aTp_EM_IN:={}
For E := 1 To Len(_aProdutos)
	_cCodAux:=_aProdutos[E,1]
  	_nQtde:=_aProdutos[E,2]
  	nEstru:= 0
	aEstrProd:=Estrut(AVKEY(_cCodAux,"G1_COD"),_nQtde)
	
	For P := 1 To Len(aEstrProd)

		SB1->(DBSeek(xFilial()+aEstrProd[P,3]))
		If SB1->B1_TIPO $ "EM,IN,MC"  //aEstrProd[P,1] = 1 .And. 
         _nQtde:=aEstrProd[P,4] 
         If (nPos:=aScan(aTp_EM_IN, {|S| S[1] == aEstrProd[P,3] } )) = 0
			   aAdd(aTp_EM_IN,{aEstrProd[P,3],_nQtde})
            cProd_EN_IN+=aEstrProd[P,3]+";"
         Else
            aTp_EM_IN[nPos,2]+=_nQtde
         EndIf   
			_cTeste += "RG: "+ZM0->ZM0_CODEVE+";"+_cCodAux+";"+Str(_aProdutos[E,2],22,7)+";"+aEstrProd[P,3]+";"+Str(_nQtde,22,7) + CRLF
		EndIf

	Next
Next

cProd_EN_IN:=LEFT(cProd_EN_IN,Len(cProd_EN_IN)-1)
_cTeste += cProd_EN_IN + CRLF
_cTeste += "*************************************************************************************************************************"

Return aTp_EM_IN

/*
===============================================================================================================================
Programa----------: AEST46BG()
Autor-------------: Alex Wallauer
Data da Criacao---: 24/05/2019
Descrição---------: Retorna SELECT GIGANTE
Parametros--------: Nenhum
Retorno-----------: Retorna SELECT GIGANTE
===============================================================================================================================*/
Static Function AEST46BG()

Local _cQuery := " "

_cQuery+=" SELECT (NVL(INCENT.VLR,0)- ((NVL(CREDAPUR.VLR,0)+ "+Str(_nBaseCFinan,22,7)+"+ NVL(CIAP.VLR,0) + NVL(LENHA.VLR,0) + NVL(RTNCRD.VLR,0) + NVL(SIMPLN.VLR,0))* NVL(FATOR.VLR,0))) AS VLR FROM "

_cQuery+="   ( SELECT D2_FILIAL, DECODE(SUM(D2_VALICM),NULL,0,SUM(D2_VALICM)) AS VLR "
_cQuery+="            FROM "+RETSQLNAME('SD2')+" SD2 "
_cQuery+="            WHERE SD2.D_E_L_E_T_ =  ' ' AND D2_FILIAL  = '"+cFilAnt+"'  AND D2_EMISSAO BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'" 
_cQuery+="              AND D2_CF IN ('5101', '5103', '5105', '5109', '5116', '5118', '5122', '5124', '5125', '5151', '5153', '5155', '5201', '5207', '5208', '5251', '5252', '5253', '5254', '5255', '5256', '5257', '5258', '5401', '5402', '5408', '5410', '5501', '5651', '5652', '5653', '5658', '5660', '5917', '5918', '5925', '5927', '5928', '6101', '6103', '6105', '6107', '6109', '6116', '6118', '6122', '6124', '6125', '6151', '6153', '6155', '6201', '6207', '6208', '6251', '6252', '6253', '6254', '6255', '6256', '6257', '6258', '6401', '6402', '6408', '6410', '6501', '6651', '6652', '6653', '6658', '6660', '6905', '6917', '6918', '6925') "
_cQuery+="     GROUP BY D2_FILIAL) INCENT "

_cQuery+="     FULL OUTER JOIN "

_cQuery+=" ( ( SELECT T1.D2_FILIAL AS FILIAL, Round(T1.VLR/(T2.VLR+ T3.VLR),4) as VLR FROM "
_cQuery+="           (SELECT D2_FILIAL, DECODE(SUM(D2_VALBRUT), null, 0, SUM(D2_VALBRUT)) AS VLR, SUM(D2_VALICM) as ICM FROM "+RETSQLNAME('SD2')+" SD2 "// SD2  
_cQuery+="                  WHERE SD2.D_E_L_E_T_ = ' ' AND D2_FILIAL  = '"+cFilAnt+"'  AND D2_EMISSAO BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'" 
_cQuery+="                    AND D2_CF IN ('5101', '5103', '5105', '5109', '5116', '5118', '5122', '5124', '5125', '5151', '5153', '5155', '5201', '5207', '5208', '5251', '5252', '5253', '5254', '5255', '5256', '5257', '5258', '5401', '5402', '5408', '5410', '5501', '5651', '5652', '5653', '5658', '5660', '5917', '5918', '5925', '5927', '5928', '6101', '6103', '6105', '6107', '6109', '6116', '6118', '6122', '6124', '6125', '6151', '6153', '6155', '6201', '6207', '6208', '6251', '6252', '6253', '6254', '6255', '6256', '6257', '6258', '6401', '6402', '6408', '6410', '6501', '6651', '6652', '6653', '6658', '6660', '6905', '6917', '6918', '6925') "
_cQuery+="     GROUP BY D2_FILIAL) T1 "

_cQuery+="     FULL OUTER JOIN "

_cQuery+="     (SELECT D2_FILIAL, DECODE(SUM(D2_VALBRUT), null, 0, SUM(D2_VALBRUT)) AS VLR FROM "+RETSQLNAME('SD2')+" SD2 "// SD2  
_cQuery+="             WHERE SD2.D_E_L_E_T_ = ' ' AND D2_FILIAL  = '"+cFilAnt+"'  AND D2_EMISSAO BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'" 
_cQuery+="               AND D2_CF NOT IN ('5112','5113','5114','5119','5120','5205','5206','5301','5302','5303','5304','5305','5306','5307','5351','5352','5353','5354','5355','5356','5357','5359','5414','5415','5451','5554','5601','5602','5603','5605','5606','5657','5663','5664','5665','5666','5901','5904','5905','5906','5907','5908','5909','5912','5915','5916','5919','5920','5921','5922','5923','5924','5926','5929','5931','5932','5933','5949','6111','6112','6113','6114','6120','6205','6206','6301','6302','6303','6304','6305','6306','6307','6351','6352','6353','6354','6355','6356','6357','6359','6414','6415','6554','6603','6657','6663','6664','6665','6666','6901','6904','6906','6907','6908','6909','6912','6914','6915','6916','6919','6920','6921','6922','6923','6924','6929','6931','6932','6933', '6949') "
_cQuery+="     GROUP BY D2_FILIAL) T2 "
_cQuery+="   ON t1.D2_FILIAL = t2.D2_FILIAL "

_cQuery+="     FULL OUTER JOIN "

_cQuery+="   (SELECT D2_FILIAL, DECODE(SUM(D2_VALBRUT), null, 0, SUM(D2_VALBRUT)) AS VLR FROM "+RETSQLNAME('SD2')+" SD2 "// SD2  
_cQuery+="             WHERE SD2.D_E_L_E_T_ = ' ' AND D2_FILIAL  = '"+cFilAnt+"'  AND D2_EMISSAO BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'" 
_cQuery+="               AND D2_CF IN ('5949', '6949') AND D2_VALICM > 0  "
_cQuery+="               GROUP BY D2_FILIAL) T3 "
_cQuery+="   ON T1.D2_FILIAL = T3.D2_FILIAL) FATOR  "
_cQuery+=" )  ON INCENT.D2_FILIAL = FATOR.FILIAL  "

_cQuery+="     FULL OUTER JOIN "

_cQuery+=" ( (SELECT T.D1_FILIAL, (T.VLR - NVL(D.VLR,0)) AS VLR FROM "
_cQuery+="          (SELECT D1_FILIAL, DECODE(SUM(D1_VALICM),NULL,0,SUM(D1_VALICM)) AS VLR "
_cQuery+="                  FROM "+RETSQLNAME('SD1')+" SD1 " 
_cQuery+="                  JOIN "+RETSQLNAME('SF4')+" SF4 ON F4_FILIAL = D1_FILIAL AND F4_CODIGO = D1_TES "
_cQuery+="                  WHERE   SD1.D_E_L_E_T_ = ' ' AND  SF4.D_E_L_E_T_ = ' ' "
_cQuery+="                      AND D1_FILIAL  = '"+cFilAnt+"'  AND D1_DTDIGIT BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'" 
_cQuery+="                      AND F4_CREDICM = 'S' GROUP BY D1_FILIAL) T "

_cQuery+="     FULL OUTER JOIN "

_cQuery+="   (SELECT D1_FILIAL, SUM(D1_VALICM) AS VLR "
_cQuery+="          FROM  "+RETSQLNAME('SD1')+" SD1 "
_cQuery+="          JOIN  "+RETSQLNAME('SF4')+" SF4 ON F4_FILIAL = D1_FILIAL AND F4_CODIGO = D1_TES "
_cQuery+="          WHERE   SD1.D_E_L_E_T_ = ' ' AND  SF4.D_E_L_E_T_ = ' ' "
_cQuery+="              AND D1_FILIAL  = '"+cFilAnt+"'  AND D1_DTDIGIT BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'" 
_cQuery+="              AND F4_CREDICM = 'S' AND F4_SITTRIB = '90' AND D1_CF in ('1101', '2101') AND D1_TIPO = 'N' GROUP BY D1_FILIAL) D "
_cQuery+="          ON D.D1_FILIAL = T.D1_FILIAL) CREDAPUR "
_cQuery+=" )  ON INCENT.D2_FILIAL = CREDAPUR.D1_FILIAL  "

_cQuery+="     FULL OUTER JOIN "

_cQuery+="  (SELECT CDH_FILIAL, DECODE(SUM(CDH_VALOR),NULL,0,SUM(CDH_VALOR))  AS VLR "
_cQuery+="          FROM "+RETSQLNAME('CDH')+" CDH "
_cQuery+="          WHERE CDH.D_E_L_E_T_ = ' ' AND CDH_FILIAL  = '"+cFilAnt+"'  AND CDH_LA = 'S' "
_cQuery+="            AND CDH_DTINI = '" + MV_PAR01 + "' AND CDH_DTFIM = '" + MV_PAR02 + "'"  //AND CDH_DTINI = '20190401' AND CDH_DTFIM = '20190430' 
_cQuery+="            AND CDH_DESC LIKE '%CIAP%' GROUP BY CDH_FILIAL) CIAP  "
_cQuery+="    ON INCENT.D2_FILIAL = CIAP.CDH_FILIAL " 

_cQuery+="     FULL OUTER JOIN "

_cQuery+="  (SELECT D1_FILIAL, DECODE(SUM(D1_VALICM),NULL,0, SUM(D1_VALICM))  AS VLR "
_cQuery+="          FROM "+RETSQLNAME('SD1')+" SD1 "
_cQuery+="          JOIN "+RETSQLNAME('SF4')+" SF4 ON F4_FILIAL = D1_FILIAL AND F4_CODIGO = D1_TES "
_cQuery+="          WHERE SD1.D_E_L_E_T_ = ' ' AND  SF4.D_E_L_E_T_ = ' '  "
_cQuery+="            AND D1_FILIAL  = '"+cFilAnt+"'  AND D1_DTDIGIT BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'" 
_cQuery+="            AND D1_GRUPO = '0807' AND F4_CREDICM = 'N' AND D1_CF in ('1101', '2101') "
_cQuery+="   GROUP BY D1_FILIAL) LENHA "
_cQuery+="    ON INCENT.D2_FILIAL = LENHA.D1_FILIAL" 

_cQuery+="     FULL OUTER JOIN "

_cQuery+="  (SELECT D2_FILIAL, DECODE(SUM(D2_VALICM),NULL,0,SUM(D2_VALICM))  as VLR  
_cQuery+="            FROM  "+RETSQLNAME('SD2')+" SD2 "//SD2  
_cQuery+="            WHERE SD2.D_E_L_E_T_ = ' '  "
_cQuery+="              AND D2_FILIAL  = '"+cFilAnt+"'  "
_cQuery+="              AND D2_EMISSAO BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'" 
_cQuery+="              AND (D2_CF IN ('5556','6556','5557','6557') "
_cQuery+="              OR (D2_CF IN ('6949') AND D2_CLIENTE = 'F00004' AND D2_NFORI > '         ') "
_cQuery+="              OR (D2_CF IN ('5949', '6949') AND D2_CLIENTE NOT IN ('000001', 'F00004') AND D2_UM = 'PC' AND D2_TP = 'AI' AND D2_GRUPO <> '0600'))  "
_cQuery+="   GROUP BY D2_FILIAL) RTNCRD "
_cQuery+="    ON INCENT.D2_FILIAL = RTNCRD.D2_FILIAL " 

_cQuery+="     FULL OUTER JOIN "

_cQuery+="  (SELECT D1_FILIAL, DECODE(SUM(D1_VALICM),NULL,0,SUM(D1_VALICM)) AS VLR "
_cQuery+="     FROM "+RETSQLNAME('SD1')+" SD1 "
_cQuery+="     JOIN "+RETSQLNAME('SF4')+" SF4 ON F4_FILIAL = D1_FILIAL AND F4_CODIGO = D1_TES "
_cQuery+="            WHERE SD1.D_E_L_E_T_ = ' ' AND  SF4.D_E_L_E_T_ = ' ' "
_cQuery+="              AND D1_FILIAL  = '"+cFilAnt+"'  AND D1_DTDIGIT BETWEEN '" + MV_PAR01 + "' AND '" + MV_PAR02 + "'" 
_cQuery+="              AND F4_CREDICM = 'S' AND F4_SITTRIB = '90' AND D1_CF in ('1101', '2101') AND D1_TIPO = 'N' "
_cQuery+="   GROUP BY D1_FILIAL) SIMPLN "
_cQuery+="    ON INCENT.D2_FILIAL = SIMPLN.D1_FILIAL" 

Return  _cQuery

/*
===============================================================================================================================
Programa----------: AEST046Necess()
Autor-------------: Alex Wallauer
Data da Criacao---: 14/10/2019
Descrição---------: _aNece
Parametros--------: nQtdBase , aTab
Retorno-----------: Retorna Valor das notas
===============================================================================================================================*/
Static Function AEST046Necess( nQtdBase , aTab )

Local I,_nMINVENDA,nPerQtde,nResto
Local _aNece:={}

For I := 1 To Len(aTab)                        
	
	If aTab[I,5] == 'D'
		_nMINVENDA := Round( aTab[I,3] / aTab[I,4] , 0 )
	Else
		_nMINVENDA := Round( aTab[I,3] * aTab[I,4] , 0 )
	EndIf
	
	If Len(_aNece) = 0//SE Loop está na linha 0, executa:
		//ARRAY[i][1] = D3_COD
		//ARRAY[i][2] /*Resto*/ ]      = Round(PERC_PRD * QTDBASE) MOD (_nMINVENDA)
		//ARRAY[i][3] /*Necessidade*/] = Round(PERC_PRD * QTDBASE) -array[i][1]
		nPerQtde:=Round(aTab[I,2] * nQtdBase,0)
		                nResto  :=MOD(nPerQtde,_nMINVENDA)
		                aAdd(_aNece,{aTab[I,1],;       //1
		                nResto,;           //2
		                nPerQtde- nResto,; //3
		                _nMINVENDA,;       //4
		                0})                //5
	Else//Se não, executa:
		//ARRAY[i][1] = D3_COD
		//ARRAY[i][2] /*Resto*// ]      = ( Round(PERC_PRD * QTDBASE) + array[I -1][2] ) MOD (MINVENDA * B1_CONV)
		//ARRAY[i][3]  /*Necessidade/*] =   Round(PERC_PRD * QTDBASE) + array[I -1][2] ) - array[i][2]
		nPerQtde:=Round(aTab[I,2] * nQtdBase,0)
		nResto  :=MOD( ( nPerQtde + _aNece[Len(_aNece),2] ) , _nMINVENDA )
		aAdd(_aNece,{aTab[I,1],;  //1
		             nResto,;     //2
		             ( nPerQtde + _aNece[Len(_aNece),2] ) - nResto,;//3
		             _nMINVENDA,;//4
		             0})         //5
	EndIf
Next

Return _aNece
/*
===============================================================================================================================
Programa----------: FCalcVlrLPI_noBenfic()
Autor-------------: Alex Wallauer
Data da Criacao---: 09/10/2019
Descrição---------: Retorna Valor das notas
Parametros--------: CodProd_Size9 , NecsLp_1UndMed , _nMINVENDA
Retorno-----------: Retorna Valor das notas
===============================================================================================================================*/
Static Function FCalcVlrLPI_noBenfic( CodProd_Size9 , NecsLp_1UndMed , _nMINVENDA )

Local QtdAcumulada:=0
Local VlrAcumulado:=0
Local Tp_Cf , I
Local QtdDistinct:={}
Local cFListAux:= AllTrim(SuperGetMV("IT_EST4608",.F.,"6151;6101;6118;6401;6402;6404"))
Local _cValores:="FILIAL;COD.PRODUTO;DOCUMENTO;QUANTIDADE;VALOR;CFOP"+CRLF

For Tp_Cf := 1 To 2
	
	//	'Prioriza Transferências, depois Vendas
	If Tp_Cf = 1 
	   If "6151" $ cFListAux
		  cFList := "6151"
	   Else
	      Loop
	   EndIf	  
	Else
	   If "6151" $ cFListAux
	      cFList:=StrTran(cFListAux,"6151;","")
	      cFList:=StrTran(cFList,"6151","")
	   Else   
	      cFList:=cFListAux
	   EndIf
	EndIf
	
	//	'VERIFICA NECESSIDADE DE CONTINUAR: Caso chame a função com Qtd. 0 ou quando alterar de Transf. para Venda
	If NecsLp_1UndMed <= 0
		Exit
	EndIf
	
	cQuery := " SELECT DISTINCT(D2_QTSEGUM) AS QTD  "
	cQuery += " FROM "+ RetSqlName("SD2") +" SD2 "
	cQuery += " WHERE D_E_L_E_T_	= ' ' "
	cQuery += "  AND D2_FILIAL  = '"+cFilAnt+"'  "
	cQuery += "  AND D2_EMISSAO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"'"
	cQuery += "  AND D2_CF IN " + FormatIn(AllTrim(CFList),";")
	cQuery += "  AND SubStr(D2_COD,1,9) = SubStr('"+CodProd_Size9+"',1,9)"
	cQuery += "  ORDER BY D2_QTSEGUM DESC "
   cQuery := ChangeQuery(cQuery)
	MPSysOpenQuery( cQuery ,"TRB" )
	
	//	'Armazena quantidades distintas
	QtdDistinct:={}
	While TRB->(!Eof())
		aAdd(QtdDistinct, TRB->QTD )
		TRB->(DBSkip())
	EndDo
	TRB->( DBCloseArea() )
	
	//	'Contador de registros
	NumRegProd:=Len(QtdDistinct)
	NFsRel:=""
	For I = 1 To NumRegProd
		
		If NecsLp_1UndMed > 0   ///51.380
			
			If (NecsLp_1UndMed < QtdDistinct[I] .And. NecsLp_1UndMed >= _nMINVENDA )
				Loop
			EndIf
			
			If (NecsLp_1UndMed < _nMINVENDA) 
							
				//consulta Nfs
				cQuery := " SELECT D2_FILIAL,D2_COD,D2_DOC,D2_CF"
				cQuery += "        ((D2_TOTAL/D2_QTSEGUM) * "+AllTrim(Str(NecsLp_1UndMed,15))+"  as VLR "//????? tem decimais
				cQuery += " FROM "+ RetSqlName("SD2") +" SD2 "
				cQuery += " WHERE D_E_L_E_T_	= ' ' "
				cQuery += "  AND D2_FILIAL  = '"+cFilAnt+"'  "
				cQuery += "  AND D2_EMISSAO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"'"
				cQuery += "  AND D2_CF IN " + FormatIn(AllTrim(CFList),";")
				cQuery += "  AND SubStr(D2_COD,1,9) = SubStr('"+CodProd_Size9+"',1,9)"
				cQuery += "  AND D2_DOC NOT IN " + FormatIn(AllTrim(NFsRel),";")
				cQuery += "  AND ROWNUM <= 1 "
				cQuery += "  ORDER BY D2_DOC "
            cQuery := ChangeQuery(cQuery)
            MPSysOpenQuery( cQuery ,"TRB2" ) 
				
   		    _cValores    += "F"+TRB2->D2_FILIAL+";"+TRB2->D2_COD+";"+TRB2->D2_DOC+";"+Str(NecsLp_1UndMed,22,7)+";"+Str(TRB2->VLR,22,7)+";"+TRB2->D2_CF+CRLF
            QtdAcumulada += NecsLp_1UndMed
            VlrAcumulado += TRB2->VLR
            NecsLp_1UndMed = 0
            TRB2->( DBCloseArea() )
				
			Else
				// 51.100 / 101 =  51,1
				
				N_INTEIRO:= INT( NecsLp_1UndMed / QtdDistinct[I]) //51
				N_RESTO  := MOD( NecsLp_1UndMed , QtdDistinct[I]) // ,1'Dif. Qtd em unidades, necessárias de LPi
				
				//'Select Limitando qtd de linhas conforme necessidade de N_INTEIRO
				cQuery := " SELECT D2_FILIAL,D2_COD,D2_DOC,D2_QTSEGUM,D2_TOTAL,D2_CF"
				cQuery += " FROM "+ RetSqlName("SD2") +" SD2 "
				cQuery += " WHERE D_E_L_E_T_	= ' ' "
				cQuery += "  AND D2_FILIAL  = '"+cFilAnt+"'  "
				cQuery += "  AND D2_EMISSAO BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"'"
				cQuery += "  AND D2_CF IN " + FormatIn(AllTrim(CFList),";")
				cQuery += "  AND SubStr(D2_COD,1,9) = SubStr('"+CodProd_Size9+"',1,9)"
				cQuery += "  AND D2_QTSEGUM = "+AllTrim(Str(QtdDistinct[I],15))///??? decimais
				cQuery += "  AND ROWNUM <= "+AllTrim(Str(N_INTEIRO))
				cQuery += "  ORDER BY D2_DOC "
            cQuery := ChangeQuery(cQuery)
            MPSysOpenQuery( cQuery ,"TRB2" ) 
				
				//'Contador de registros
				NumReg = 0
				TRB2->(DBGoTop())				
				While TRB2->(!Eof())
					If NumReg < N_INTEIRO
						
						QtdAcumulada += TRB2->D2_QTSEGUM
						VlrAcumulado += TRB2->D2_TOTAL
						If Empty(NFsRel)
							NFsRel:= TRB2->D2_DOC
						Else
							NFsRel:= NFsRel+';'+TRB2->D2_DOC //'posterior consulta
						EndIf
						_cValores+=TRB2->D2_FILIAL+";"+TRB2->D2_COD+";"+TRB2->D2_DOC+";"+Str(TRB2->D2_QTSEGUM,22,7)+";"+Str(TRB2->D2_TOTAL,22,7)+";"+TRB2->D2_CF+CRLF
						NumReg++
					Else
						Exit
					EndIf
					
					TRB2->(DBSkip())
					
				EndDo
				TRB2->( DBCloseArea() )
			EndIf
			
			If (NumReg < N_INTEIRO)
				NecsLp_1UndMed:=N_RESTO + ((N_INTEIRO - NumReg) * QtdDistinct[I])
			Else
				NecsLp_1UndMed:=N_RESTO
			EndIf
		Else
			Exit
		EndIf
		
	Next i
	
Next Tp_Cf

Return VlrAcumulado
