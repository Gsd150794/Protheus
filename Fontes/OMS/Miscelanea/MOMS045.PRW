/*
===================================================================================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===================================================================================================================================================================================
Analista        - Programador     - Inicio     - Envio      - Chamado - Motivo de Alteração
===================================================================================================================================================================================
Antonio Ramos   - Igor Melgaço    - 18/12/2024 - 23/01/2025 - 49056   - Ajustes para gravação de historico de alterações de campo da SE1
Antonio Ramos   - Julio Paz       - 23/01/2025 - 27/01/2025 - 49597   - Inclusão de Nova Opções de Filtro por Rede e Região no Relatório Monitor de Devoluções [OMS]
Antonio Ramos   - Igor Melgaço    - 18/07/2025 - 18/07/2025 - 50861   - Inclusão coluna informação NF Troca Nota
Antonio Ramos   - Igor Melgaço    - 18/07/2025 - 18/07/2025 - 51258   - Inclusão coluna NF de Remessa
Antonio Ramos   - Igor Melgaço    - 11/09/2025 - 11/09/2025 - 51939   - Adição do Local de Embarque
Guilherme       - Alex Wallauer   - 01/10/2025 - 15/10/2025 - 52088   - Incluido filtros para o Browse Principal e mais 2 campos virtuais ZDS_NOMOPE/ZDS_NOMTRA.
Antonio Ramos   - Igor Melgaço    - 20/10/2025 - 20/10/2025 - 51316   - Ajuste no calculo do campo de valor total.
Antonio Ramos   - Igor Melgaço    - 11/11/2025 - 17/11/2025 - 52544   - Ajuste para gravação da nota de origem
Antonio Ramos   - Igor Melgaço    - 11/11/2025 - 17/11/2025 - 52558   - Ajuste para gravação do ZDS_VLRTOT 
Antonio Ramos   - Igor Melgaço    - 17/11/2025 - 17/11/2025 - 53024   - Ajuste para conteudo do combo dos campos ZDS_STUEMI e ZDS_STUSIT
===================================================================================================================================================================================
*/
#Include "rwmake.ch"
#Include "APWEBSRV.CH"
#Include "TOTVS.ch"
#Include "TBICONN.CH"
#Include "FWMVCDef.Ch"
#Include "topconn.Ch"

Static _aDadAlt := {}
/*
===============================================================================================================================
Programa----------: MOMS045
Autor-------------: ALEX WALLAUER
Data da Criacao---: 06/09/2019
Descrição---------: Monitor de devoluções Italac - CHAMADO 30406
===============================================================================================================================
*/
User Function MOMS045()
 Local cExprFiltro:=" " As Character
 Local _cAlias    :=" " As Character
 Local nI         := 00 As Numeric
 Local _cStEmi    := "" As Character
 Local _cStSit    := "" As Character
 Local _aParAux   := {} As Array
 Local _aParRet   := {} As Array

 Private cCadastro  := " "  As Character
 Private _bLegend   := {||} As Block
 Private _aStatu    := {} As Array
 Private _aStEmi    := {} As Array
 Private _aRegiao   := {} As Array
 Private _aItalac_F3:= {} As Array
 
 _cAlias  := "ZDS"
 cCadastro:= "Monitor de devoluções ITALAC"

DbSelectArea("SX3")
 SX3->(dbSetOrder(2))
 If SX3->(dbSeek("ZDS_STUEMI"))
		_cStEmi := X3Cbox()
 EndIf     
 _cStEmi := StrTran(_cStEmi,"=","-")

 If SX3->(dbSeek("ZDS_STUSIT"))
		_cStSit := X3Cbox()
 EndIf     
 _cStSit := StrTran(_cStSit,"=","-")

 DBSelectArea(_cAlias)
 DBSetOrder(1)

 _aStatu  := {"D-Nao Gerado    ",;
              "P-Gerado        ",;
              "E-Com Ocorrencia",;
              "X-Excluido      "}
 
 _aStEmi  := StrTokArr(_cStEmi, ';')  //{"1-Ato da Entrega" ,"2-Pós Venda"       ,"3-Transferencia"       ,"4-Pallet"      ,"5-Vazio"}
 _aStSit  := StrTokArr(_cStSit, ';') //{"1-Canhoto Cobrado","2-Canhoto Recebido","3-Solicitado Recusa"   ,"4-Check List"  ,"5-Com Fiscal"     ,"6-Com Logistica"   ,"7-Com Comercial","8-Com Estoque"}
 _aRegiao := {"1-Regio Sudeste"  ,"2-Região Sul"      ,"3-Região Centro Oeste" ,"4-Região Norte","5-Região Nordeste","6-Todas as Regiões"}
 


 //  (_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave              , _nCpoDesc                   ,_bCondTab , _cTitAux        , _nTamChv , _aDados , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
 AAdd(_aItalac_F3,{"MV_PAR04",     ,                              ,                             ,          ,"Status"         , 1        ,_aStatu  , Len(_aStatu)                              } )
 AAdd(_aItalac_F3,{"MV_PAR05",     ,                              ,                             ,          ,"Status Emissao" , 1        ,_aStEmi  , Len(_aStEmi)                              } )
 AAdd(_aItalac_F3,{"MV_PAR11",     ,                              ,                             ,          ,"Região"         , 1        ,_aRegiao , Len(_aRegiao)                             } )
 
 
 _bOK    := {|| If(MV_PAR02 >= MV_PAR01 ,.T.,(U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo",3),.F.) ) }
 MV_PAR01:= dDataBase
 MV_PAR02:= dDataBase
 MV_PAR03:= Space(200)
 MV_PAR04:= Space(015)
 MV_PAR05:= Space(015)
 MV_PAR06:= Space(6)
 MV_PAR07:= Space(4)
 MV_PAR08:= Space(6)
 MV_PAR09:= Space(4)
 MV_PAR10:= Space(100)
 MV_PAR11:= _aRegiao[6]
 
 AAdd( _aParAux , { 1 , "Data de"       , MV_PAR01, "@D"  , ""  , ""      , "" , 050 , .F. } )
 AAdd( _aParAux , { 1 , "Data ate"      , MV_PAR02, "@D"  , ""  , ""      , "" , 050 , .F. } )
 AAdd( _aParAux , { 1 , "Filial"        , MV_PAR03, "@S99", ""  ,"LSTFIL" , "" , 100 , .F. } )
 AAdd( _aParAux , { 1 , "Status"        , MV_PAR04, "@!"  , ""  ,"F3ITLC" , "" , 050 , .F. } )
 AAdd( _aParAux , { 1 , "Status Emissao", MV_PAR05, "@!"  , ""  ,"F3ITLC" , "" , 050 , .F. } )
 AAdd( _aParAux , { 1 , "Cliente De:"   , MV_PAR06, "@!"  , ""  ,"SA1"    , "" , 050 , .F. } )
 AAdd( _aParAux , { 1 , "Loja De:"      , MV_PAR07, "@!"  , ""  ,""       , "" , 050 , .F. } )
 AAdd( _aParAux , { 1 , "Cliente Até:"  , MV_PAR08, "@!"  , ""  ,"SA1"    , "" , 050 , .F. } )
 AAdd( _aParAux , { 1 , "Loja Até:"     , MV_PAR09, "@!"  , ""  ,""       , "" , 050 , .F. } )
 AAdd( _aParAux , { 1 , "UF's"          , MV_PAR10, "@!"  , ""  ,"LSTEST" , "MV_PAR11='6'"   , 100 , .F. } ) 
 AAdd( _aParAux , { 1 , "Região"        , MV_PAR11, "@!"  , ""  ,"F3ITLC" , "Empty(MV_PAR10)", 100 , .F. } )

 For nI := 1 To Len( _aParAux )
     AAdd( _aParRet , _aParAux[nI][03] )
 Next nI

 //         aParametros,cTitle,aRet     ,bOk ,aButtons,lCentered,nPosX,nPosY,oDlgWizard,cLoad,lCanSave,lUserSave
 If !ParamBox( _aParAux , ""   ,@_aParRet,_bOK,        ,         ,     ,     ,          ,     ,.T.     ,.T.      )//Intervalo de Datas e Filial
    cExprFiltro :=NIL
 Else
    cExprFiltro:=""
    
    If !Empty(MV_PAR01)
        cExprFiltro += " .And. DToS(ZDS_EMISSA) >= '" + DToS(MV_PAR01) + "'"
    EndIf

    If !Empty(MV_PAR02)
        cExprFiltro += " .And. DToS(ZDS_EMISSA) <= '" + DToS(MV_PAR02) + "'"
    EndIf

    If !Empty(MV_PAR03)
        cExprFiltro += " .And. ZDS_FILIAL $ '" + AllTrim(MV_PAR03)+"' "
    EndIf

    If !Empty(MV_PAR04) 
        cExprFiltro += " .And. (U_MOMS045L()) $ '" + AllTrim(MV_PAR04)+"' "
    EndIf    

    If !Empty(MV_PAR05)
        cExprFiltro += " .And. ZDS_STUEMI $ '" + AllTrim(MV_PAR05)+"' "
    EndIf

    // Filtro por cliente
    If !Empty(MV_PAR06)
       cExprFiltro += " .And. ZDS_FORNEC >= '" + MV_PAR06 + "' "
    EndIf

    If !Empty(MV_PAR07)
       cExprFiltro += " .And. ZDS_LOJA >= '" + MV_PAR07 + "' "
    EndIf

    If !Empty(MV_PAR08)
       cExprFiltro += " .And. ZDS_FORNEC <= '" + MV_PAR08 + "' "
    EndIf

    If !Empty(MV_PAR09)
       cExprFiltro += " .And. ZDS_LOJA <= '" + MV_PAR09 + "' "
    EndIf

    // Filtro por UFs
    If ! Empty(MV_PAR10)
       cExprFiltro += " .And. ZDS_EST $ '" + AllTrim(MV_PAR10)+"' "
   
    Elseif !Empty(MV_PAR11)// Filtro por Região
   
       _cRegioes := ""
       If "1" $ MV_PAR11 //"1-Regio Sudeste"
           _cRegioes += "SP;RJ;MG;ES;"
       EndIf

       If "2" $ MV_PAR11 //"2-Região Sul"
           _cRegioes += "SC;RS;PR;"
       EndIf

       If "3" $ MV_PAR11 //"3-Região Centro Oeste"
          _cRegioes += "MS;MT;TO;GO;DF;
       EndIf

       If "4" $ MV_PAR11 //"4-Região Norte"
          _cRegioes += "AC;AM;AP;MA;PA;RO;RR;"
       EndIf

       If "5" $ MV_PAR11 //"5-Região Nordeste"
          _cRegioes += "AL;BA;CE;PB;PE;PI;RN;SE;"
       EndIf

       If ! Empty(_cRegioes)
          cExprFiltro += " .And. ZDS_EST $ '" + AllTrim(_cRegioes)+"' "
       EndIf

    EndIf
    cExprFiltro:=SUBSTR(cExprFiltro,7)
 EndIf

 _bLegend := {|| U_MOMS045L()} //Função que Devolve o Status do Documento
 
 _oBrowse:=FWMBrowse():New()
 _oBrowse:SetAlias(_cAlias)
 _oBrowse:SetMenuDef('MOMS045')
 _oBrowse:SetDescription(cCadastro)
 _oBrowse:AddLegend( 'Eval(_bLegend)=="D"',"BR_AMARELO" ,"Documento Nao Gerado")
 _oBrowse:AddLegend( 'Eval(_bLegend)=="P"',"BR_VERDE"   ,"Documento Gerado")
 _oBrowse:AddLegend( 'Eval(_bLegend)=="E"','BR_PRETO'   ,"Documento com Ocorrencia")
 _oBrowse:AddLegend( 'Eval(_bLegend)=="X"','BR_VERMELHO',"Documento Excluido")
 _oBrowse:SetFilterDefault( cExprFiltro )
 _oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Alex Wallauer
Data da Criacao---: 30/09/2025
Descrição---------: Menu do programa
===============================================================================================================================
*/
Static Function MenuDef() As Array
 Local aRotina  := {}
 
 AAdd(aRotina,{"Pesquisar"              ,"AxPesqui" ,0,1})
 AAdd(aRotina,{"Visualizar"             ,"AxVisual" ,0,2})
 AAdd(aRotina,{"Importar"               ,"FWMsgRun( ,{|oProc| U_MOMS045P(oProc,1) },,'Iniciando o processamento...' )",0,4})
 AAdd(aRotina,{"Alterar"                ,"U_MOMS045A()" ,0,4})
 AAdd(aRotina,{"Alterar em Massa"       ,"FWMsgRun( ,{|oProc| U_MOMS045P(oProc,4) },,'Iniciando o processamento...' )",0,2})
 AAdd(aRotina,{"Gera XML"               ,"FWMsgRun( ,{|oProc| U_MOMS045P(oProc,3,.F.) },,'Iniciando o processamento...' )",0,2})
 AAdd(aRotina,{"Legenda"                ,"U_MOMS45LE",0,2})
 AAdd(aRotina,{"Gera Excel"             ,"FWMsgRun( ,{|oProc| U_MOMS045P(oProc,3,.T.) },,'Iniciando o processamento...' )",0,2})
 AAdd(aRotina,{"Historico de Alteracoes","FWMsgRun( ,{|oProc| U_MOMS045H() },,'Iniciando o processamento...' )",0,2})

Return(aRotina)

/*
===============================================================================================================================
Programa----------: MOMS045P
Autor-------------: Alex Wallauer
Data da Criacao---: 28/02/2018
Descrição---------: Processamento de Importação de DADOS DO SDS
===============================================================================================================================
*/
User Function MOMS045P(oProc As Object,nOpcao As Numeric,_lXLSX As Logical) As Logical
 Local nI         As Numeric
 Local _nCpo      As Numeric
 Local nInc       As Numeric
 Local nAlt       As Numeric
 Local _aParAux   As Array
 Local _aParRet   As Array
 Local aArea      As Array
 Local _bOK       As Block
 Local _cAlias    As Character
 Local _cQuery1   As Character
 Local _cDevFab   As Character
 Local _cNfDeb    As Character
 Local _cNomeGVen As Character
 Local _cNumNFTN  As Character
 Local _cNumPVTN  As Character
 Local _cNumFilTN As Character
 Local _cNumNFRM  As Character
 Local _cLocEmb   As Character
 Local _cCodStSit As Character
 Local _cCodStEmi As Character
 
 _cQuery1 := ""
 nI       := 0
 _nCpo    := 0
 nInc     := 0
 nAlt     := 0
 _aParAux := {}
 _aParRet := {}
 _cAlias  := GetNextAlias()
 _bOK     := {|| .T. }
 aArea    := ZDS->(GetArea())
 _cDevFab := "N"
 _cNfDeb  := "N"
 _cLocEmb := ""
 _cCodStSit := ""
 _cCodStEmi := ""

 oProc:cCaption := ("Filtrar dados de devoluções...")
 ProcessMessages()
 
 MV_PAR06 := Space(6)
 MV_PAR07 := Space(4)
 MV_PAR08 := Space(6)
 MV_PAR09 := Space(4)
 
 If nOpcao <> 4//Gera Excel / Gera XML   / Importar *********************************************************
    _bOK    := {|| If(MV_PAR02 >= MV_PAR01 ,.T.,(U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo",3),.F.) ) }
    MV_PAR01:= dDataBase
    MV_PAR02:= dDataBase
    MV_PAR03:= Space(200)
    MV_PAR04:= Space(015)
    MV_PAR05:= Space(015)
    MV_PAR10:= Space(100)
    MV_PAR11:= Space(100)
    MV_PAR12:= Space(150)
    AAdd( _aParAux , { 1 , "Data de"        , MV_PAR01, "@D"  , ""  , ""		, "" , 050 , .F. } )
    AAdd( _aParAux , { 1 , "Data ate"       , MV_PAR02, "@D"  , ""  , ""		, "" , 050 , .F. } )
    AAdd( _aParAux , { 1 , "Filial"         , MV_PAR03, "@S99", ""  ,"LSTFIL" , "" , 100 , .F. } )
    AAdd( _aParAux , { 1 , "Status"         , MV_PAR04, "@!"  , ""  ,"F3ITLC" , "" , 050 , .F. } )
    AAdd( _aParAux , { 1 , "Status Emissao" , MV_PAR05, "@!"  , ""  ,"F3ITLC" , "" , 050 , .F. } )
    AAdd( _aParAux , { 1 , "Cliente De:"    , MV_PAR06, "@!"  , ""  ,"SA1"    , "" , 035 , .F. } )
    AAdd( _aParAux , { 1 , "Loja De:"       , MV_PAR07, "@!"  , ""  ,""       , "" , 035 , .F. } )
    AAdd( _aParAux , { 1 , "Cliente Até:"   , MV_PAR08, "@!"  , ""  ,"SA1"    , "" , 035 , .F. } )
    AAdd( _aParAux , { 1 , "Loja Até:"      , MV_PAR09, "@!"  , ""  ,""       , "" , 035 , .F. } )
    AAdd( _aParAux , { 1 , "Rede"           , MV_PAR10, "@!"  , ""  ,"REDE50" , "" , 100 , .F. } )
    AAdd( _aParAux , { 1 , "Região"         , MV_PAR11, "@!"  , ""  ,"F3ITLC" , "" , 50  , .F. } )
    AAdd( _aParAux , { 1 , "Transportadores", MV_PAR12, "@S99", ""  ,"LSTSA2" , "" , 100 , .F. } )
    

 Else //Alterar em Massa ************************************************************************************
     MV_PAR01:=Space(200)
     AAdd( _aParAux , { 1 , "Selecione arquivo .CSV:",MV_PAR01, "@!"	, "", "DIR","", 100, .T. } )
 EndIf
 
 For nI := 1 To Len( _aParAux )
     AAdd( _aParRet , _aParAux[nI][03] )
 Next nI
 
 //          aParametros,cTitle,aRet     ,bOk ,aButtons,lCentered,nPosX,nPosY,oDlgWizard,cLoad,lCanSave,lUserSave
 If !ParamBox( _aParAux , ""   ,@_aParRet,_bOK,        ,         ,     ,     ,          ,     ,.T.     ,.T.      )//Intervalo de Datas e Filial
     Return .F.
 EndIf
 
 oProc:cCaption := ("Lendo dados de devoluções...")
 ProcessMessages()
 
 If nOpcao = 4     //ALTERAR EM MASSA ***********************************************************************************************************************

    _cArq := AllTrim(MV_PAR01)
    If Upper(RIGHT(_cArq,3)) <> "CSV" .Or. FT_FUSE(_cArq) == -1
        U_ITMsg("Não foi possível abrir o arquivo informado.",;
                "Arquivo inválido","O arquivo informado deve ser .CSV ou verificar se o arquivo informado esta correto.",1)
        Return .F.
    EndIf

    _cTot:=FT_FLASTREC()-1
    _cTot:=AllTrim(Str(_cTot))
    _nTam:=Len(_cTot)

    FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
    _cDados := FT_FREADLN()

    If ! "CHAVE DE ACESSO;STATUS EMISSAO;SITUACAO;OBS FISCAL;OBS GERAIS;OBS ABAT NF" $ Upper(AllTrim(_cDados))
        U_ITMsg("Arquivo informado com o cabeçalho incorreto.",;
                "Arquivo inválido","O arquivo deve conter o cabeçalho: CHAVE DE ACESSO;STATUS EMISSAO;SITUACAO;OBS FISCAL;OBS GERAIS;OBS ABAT NF",1)
        Return .F.
    EndIf

    FT_FSKIP()
    _aDados:={}
    _nCont:=_nConta:=0
    _nErro:=0

    For nI := 1 to Len(_aStEmi)
       _cCodStEmi += Iif(Empty(_cCodStEmi),"","/") + Subs(_aStEmi[nI],1,1)
    Next

    For nI := 1 to Len(_aStSit)
       _cCodStSit += Iif(Empty(_cCodStSit),"","/") + Subs(_aStSit[nI],1,1)
    Next

    ZDS->(DBSetOrder(5)) //ZDS_CHAVNF
    While !FT_FEOF()  //FACA ENQUANTO NAO For FIM DE ARQUIVO

        _nCont++
        oProc:cCaption := ("Processando Dados: "+ StrZero(_nCont,_nTam) +" de "+ _cTot)
        ProcessMessages()

        _cDados := FT_FREADLN()
        _cDados := StrTran(_cDados,'"','')//Tem que ter ate 6 colunas

        //Verifica se é final de arquivo
        If AllTrim(_cDados) = ';;;;;' .And. _nConta > 10
           _nConta++
           Exit
        EndIf

        _aLinhas:= StrTokArr2(_cDados,";",.T.)//Tem que ter ate 6 colunas
        _aItens:={}

        If Len(_aLinhas) < 6
           _aLinhas:=U_ITTXTARRAY(_cDados,"",6)
        EndIf

        AAdd(_aItens,.T.)//1
        AAdd(_aItens,If(Len(_aLinhas) > 0,_aLinhas[1],""))//2
        AAdd(_aItens,If(Len(_aLinhas) > 1,_aLinhas[2],""))//3
        AAdd(_aItens,If(Len(_aLinhas) > 2,_aLinhas[3],""))//4
        AAdd(_aItens,If(Len(_aLinhas) > 3,_aLinhas[4],""))//5
        AAdd(_aItens,If(Len(_aLinhas) > 4,_aLinhas[5],""))//6
        AAdd(_aItens,If(Len(_aLinhas) > 5,_aLinhas[6],""))//7
        AAdd(_aItens,"" )//8 - Erro

        If Empty(_aItens[2]) .Or. !ZDS->(DBSeek(_aItens[2]))
           _aItens[1]:=.F.
           _aItens[Len(_aItens)]:="[Chave não informada ou não encontrada] "
        Else
           _aItens[2]:=ZDS->ZDS_FILIAL+" "+_aItens[2]
        EndIf
        
        If !Empty(_aItens[3]) .And. !LEFT(_aItens[3],1) $ _cCodStEmi //"0/1/2/3/4/5"//"1=Ato da Entrega;2=Pós Venda;3=Transferencia;4=Pallet;5=Vazio" 0-Em branco
           _aItens[1]:=.F.
           _aItens[Len(_aItens)]+="[Status deve ser entre 0 e "+Subs(_aStEmi[Len(_aStEmi)],1,1)+"] "
        ElseIf LEFT(_aItens[3],1) = "0"
           _aItens[3]:="0"
        ElseIf !Empty(_aItens[3])
           _aItens[3]:=_aStEmi[Val(_aItens[3])]
        EndIf

        If !Empty(_aItens[4]) .And. !LEFT(_aItens[4],1) $ _cCodStSit //"0/1/2/3/4/5/6/7"//"1=Canhoto Cobrado;2=Canhoto Recebido;3=Solicitado Recusa;4=Check List;5=Com Fiscal;6=Com Logistica;7=Com Comercial" 0-Em branco
           _aItens[1]:=.F.
           _aItens[Len(_aItens)]+="[Situacao deve ser entre 0 e "+Subs(_aStSit[Len(_aStSit)],1,1)+"] "
        ElseIf LEFT(_aItens[4],1) ="0"
           _aItens[4]:="0"
        ElseIf !Empty(_aItens[4])
           _aItens[4]:=_aStSit[Val(_aItens[4])]
        EndIf
        
        If _aItens[1] = .F.
           _nErro++
        EndIf
        AAdd(_aDados,_aItens)

        FT_FSKIP()

   EndDo

   FT_FUSE()

    If Len(_aDados) > 0
        //Monta _aCab
        _aCab:={}
        _aSize:={}
        AAdd(_aCab,"")//01
        AAdd(_aSize,5)
        AAdd(_aCab,"Filial + Chave de Acesso")//02
        AAdd(_aSize,110)
        AAdd(_aCab,"Status Emissao")//03
        AAdd(_aSize,45)
        AAdd(_aCab,"Situacao")//04
        AAdd(_aSize,45)
        AAdd(_aCab,"Obs Fiscal")//05
        AAdd(_aSize,150)
        AAdd(_aCab,"Obs. Financeira")//06
        AAdd(_aSize,150)
        AAdd(_aCab,"Obs. Logística")//07
        AAdd(_aSize,150)
        AAdd(_aCab,"Erros")//08
        AAdd(_aSize,150)

        _cTitulo:="Dados do Arquivo "+_cArq
        _cMsgTop:="Alteracao em Massa, Registros Lidos: "+AllTrim(TRANSFORM(Val(_cTot),"@E 999,999,999"))+", Com Erros: "+AllTrim(TRANSFORM(_nErro,"@E 999,999,999"))
        While .T.
        //        ITListBox(_cTitAux, _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
           lOK:=U_ITLISTBOX(_cTitulo, _aCab    , _aDados   , .T.      , 4      ,_cMsgTop  ,          , _aSize)

           If lOK .And. U_ITMsg("Confirma alteração dos registros válidos",'Atenção!',,3,2,3,,"CONFIRMA","Voltar")
              MOMS45AM(oProc)//GRAVA OS DADOS DO CSV
              Exit
           ElseIf !lOK .And. U_ITMsg("Confirma SAIR",'Atenção!',"Todos os registros de válidações serão perdidos",3,2,3,,"CONFIRMA","Voltar")
              Exit
           EndIf

        EndDo
    Else
       U_ITMsg("Nenhum registro válido",'Atenção!',"Dados do Arquivo "+_cArq,1)
    EndIf
   ZDS->(DBSetOrder(1))

 ElseIf nOpcao = 2 .Or. nOpcao = 3 //GERA .CSV (2-NÃO USA MAIS) OU GERA XML *********************************************************************************

    _aZDS:={}
    _aNFO:={}

    _cQuery1+= " SELECT ZDS.R_E_C_N_O_ ZDS_REC, A1_GRPVEN, A1_I_REGIA "
    _cQuery1+= "		FROM " + RetSqlName("ZDS")+" ZDS, " + RetSqlName("SA1")+" SA1 "
    _cQuery1+= "  WHERE ZDS.D_E_L_E_T_ = ' ' AND SA1.D_E_L_E_T_ = ' ' "
    _cQuery1+= "  AND ZDS_FORNEC = A1_COD AND ZDS_LOJA = A1_LOJA "

    If !Empty(MV_PAR02)
        _cQuery1 += "  AND ZDS.ZDS_EMISSA BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "'"
    ElseIf !Empty(MV_PAR01)
        _cQuery1 += "  AND ZDS.ZDS_EMISSA >= '" + DToS(MV_PAR01) + "'"
    EndIf
    If !Empty(MV_PAR03)
        If Len(AllTrim(MV_PAR03)) > 2
            _cQuery1 += " AND ZDS.ZDS_FILIAL IN " + FormatIn(AllTrim(MV_PAR03),";")
        Else
            _cQuery1 += " AND ZDS.ZDS_FILIAL = '"+AllTrim(MV_PAR03)+"' "
        EndIf
    EndIf

    // Filtro por cliente
    If !Empty(MV_PAR06)
       _cQuery1 += " AND ZDS.ZDS_FORNEC >= '" + MV_PAR06 + "' "
    EndIf

    If !Empty(MV_PAR07)
       _cQuery1 += " AND ZDS.ZDS_LOJA >= '" + MV_PAR07 + "' "
    EndIf

    If !Empty(MV_PAR08)
       _cQuery1 += " AND ZDS.ZDS_FORNEC <= '" + MV_PAR08 + "' "
    EndIf

    If !Empty(MV_PAR09)
       _cQuery1 += " AND ZDS.ZDS_LOJA <= '" + MV_PAR09 + "' "
    EndIf

    // Filtro por Rede
    If ! Empty(MV_PAR10)
       _cQuery1 += " AND A1_GRPVEN IN " + FormatIn(AllTrim(MV_PAR10),";")

    EndIf

    // Filtro por Região
    If ! Empty(MV_PAR11)
       _cRegioes := ""
       If "1" $ MV_PAR11 //"1-Regio Sudeste"
           _cRegioes += "SP;RJ;MG;ES;"
       EndIf

       If "2" $ MV_PAR11 //"2-Região Sul"
           _cRegioes += "SC;RS;PR;"
       EndIf

       If "3" $ MV_PAR11 //"3-Região Centro Oeste"
          _cRegioes += "MS;MT;TO;GO;DF;
       EndIf

       If "4" $ MV_PAR11 //"4-Região Norte"
          _cRegioes += "AC;AM;AP;MA;PA;RO;RR;"
       EndIf

       If "5" $ MV_PAR11 //"5-Região Nordeste"
          _cRegioes += "AL;BA;CE;PB;PE;PI;RN;SE;"
       EndIf

       If ! Empty(_cRegioes)
          _cQuery1 += " AND ZDS_EST IN " + FormatIn(AllTrim(_cRegioes),";")
       EndIf

    EndIf

    MPSysOpenQuery( _cQuery1 , _cAlias )

    oProc:cCaption := ("Contando os dados lidos...")
    ProcessMessages()
    DBSelectArea(_cAlias)
    (_cAlias)->(DBGoTop())
    _nConta:=_cTot := 0
    COUNT TO _cTot
    _cTot:=AllTrim(Str(_cTot))
    _nTam:=Len(_cTot)
    _lXMLTambem:=.F.//Decide se poe o Status por ultimo no XML Tambem
    If _lXMLTambem .Or. nOpcao = 2 .Or. nOpcao = 3  //.CSV (2-NÃO USA MAIS)*********************************************
       _aSX3:={}
       AAdd(_aSX3,"ZDS_OBSGER")
       AAdd(_aSX3,"ZDS_OBSABA")
       AAdd(_aSX3,"ZDS_STUEMI")
       AAdd(_aSX3,"ZDS_STUSIT")
       AAdd(_aSX3,"ZDS_OBSCOM")
       AAdd(_aSX3,"ZDS_FILIAL")
       AAdd(_aSX3,"ZDS_DOC")
       AAdd(_aSX3,"ZDS_SERIE")
       AAdd(_aSX3,"ZDS_FORNEC")
       AAdd(_aSX3,"ZDS_LOJA")
       AAdd(_aSX3,"ZDS_CNPJ") //*
       AAdd(_aSX3,"ZDS_NOMFOR")
       AAdd(_aSX3,"ZDS_EMISSA")
       AAdd(_aSX3,"ZDS_CHAVNF")//*
       AAdd(_aSX3,"ZDS_NFORIG")
       AAdd(_aSX3,"ZDS_VLRTOT")
       AAdd(_aSX3,"ZDS_EST")
       AAdd(_aSX3,"ZDS_CLIMUN")
       AAdd(_aSX3,"ZDS_CLIEMA")


    Else//XML ******************************************
       _aSX3:= FWSX3Util():GetAllFields( "ZDS" , .T. )
    EndIf
    SF2->(DBSetOrder(1))
    (_cAlias)->(DBGoTop())
    While (_cAlias)->(!Eof())

        _nConta++
        oProc:cCaption := ("Processando Dados: "+ StrZero(_nConta,_nTam) +" de "+ _cTot)
        ProcessMessages()

        ZDS->(DBGoTo((_cAlias)->ZDS_REC))

        _cStatus:=U_MOMS045L()//Status Atual
        // Filtro por Status
        If !Empty(MV_PAR04) .And. !_cStatus $ AllTrim(MV_PAR04)
           (_cAlias)->(DBSkip())
           Loop
        EndIf
        
        // Filtro por Status de Emissão
        If  !Empty(MV_PAR05) .And. !ZDS->ZDS_STUEMI $ AllTrim(MV_PAR05)
           (_cAlias)->(DBSkip())
           Loop
        EndIf

        // Filtro por Transportadoras
        If  !Empty(MV_PAR12) 
            If SF2->(DBSeek(ZDS->ZDS_FILIAL+SubStr(ZDS->ZDS_NFORIG,1,9)+SubStr(ZDS->ZDS_NFORIG,11,3))) .And.;
               !SF2->F2_I_NTRAN $ AllTrim(MV_PAR12)
               (_cAlias)->(DBSkip())
               Loop
            EndIf
        EndIf

        _aItens:={}

        If !_lXMLTambem .And. nOpcao = 3//XML ******************************************
           If (nPos:=aScan(_aStatu,{|S| LEFT(S,1) = _cStatus} )) > 0
              AAdd(_aItens, _aStatu[nPos] )
           Else
              AAdd(_aItens, "Sem Status" )
           EndIf
        EndIf

        For _nCpo:= 1 TO Len(_aSX3)

              _nPos:=ZDS->( FIELDPOS(_aSX3[_nCpo]) )


            If AllTrim(_aSX3[_nCpo]) == "ZDS_NOMFOR"
               AAdd(_aItens,Space(30) )
            Else
               AAdd(_aItens,ZDS->( FIELDGET(_nPos) ) )
            EndIf

            If ZDS->( FIELD(_nPos) ) = "ZDS_STUEMI"
               nPos:=Val(_aItens[ Len(_aItens) ])
               If nPos > 0 .And. nPos <= Len(_aStEmi)
                 _aItens[ Len(_aItens) ]:=_aStEmi[nPos]
               EndIf

            ElseIf  nOpcao = 2 .And. ZDS->( FIELD(_nPos) ) $ "ZDS_FILIAL /ZDS_CNPJ /ZDS_CHAVNF /ZDS_DOC /ZDS_FORNEC /ZDS_LOJA " // Se .CSV (2-NÃO USA MAIS)
               _aItens[ Len(_aItens) ]:="'"+_aItens[ Len(_aItens) ]

            ElseIf  nOpcao = 2 .And. ZDS->( FIELD(_nPos) ) = "ZDS_NFORIG" // Se .CSV (2-NÃO USA MAIS)
               If (RIGHT(AllTrim(_aItens[ Len(_aItens)]), 2 ) = CHR(13)+CHR(10))
                   _aItens[ Len(_aItens) ]:=LEFT( _aItens[ Len(_aItens) ] , Len(AllTrim(_aItens[ Len(_aItens)] )) - 2 )
               EndIf

            ElseIf ZDS->( FIELD(_nPos) ) = "ZDS_STUSIT"
               nPos:=Val(_aItens[ Len(_aItens) ])
               If nPos > 0 .And. nPos <= Len(_aStSit)
                  _aItens[ Len(_aItens) ]:=_aStSit[Val(_aItens[ Len(_aItens) ])]
               EndIf
            ElseIf AllTrim(_aSX3[_nCpo]) == "ZDS_NOMFOR"// ZDS->( FIELD(_nPos) ) = "ZDS_NOMFOR"
               _aItens[ Len(_aItens) ] := Posicione("SA1",1,xFilial("SA1")+ZDS->ZDS_FORNEC+ZDS->ZDS_LOJA,"A1_NOME")


            EndIf

        Next

        If SF2->(DBSeek(ZDS->ZDS_FILIAL+SubStr(ZDS->ZDS_NFORIG,1,9)+SubStr(ZDS->ZDS_NFORIG,11,3)))
           AAdd(_aItens, SF2->F2_I_NTRAN)//CAMPOS NOVOS
           If nOpcao = 2 //(2-NÃO USA MAIS)
              AAdd(_aItens, "'"+SF2->F2_CARGA  )//CAMPOS NOVOS
           Else
              AAdd(_aItens, SF2->F2_CARGA  )//CAMPOS NOVOS
           EndIf
        Else
           AAdd(_aItens, Space(Len(SF2->F2_I_NTRAN)))//CAMPOS NOVOS
           AAdd(_aItens, Space(Len(SF2->F2_CARGA  )))//CAMPOS NOVOS
        EndIf


        AAdd(_aItens, DToC(SF2->F2_I_DENCL))//DATA ENTREGA

        ZGJ->(DBSetOrder(1))
        If ZGJ->(DBSeek(SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE))
            AAdd(_aItens,DToC(_cDtCanh := ZGJ->ZGJ_DTENT))//DATA CANHOTO
        Else
            AAdd(_aItens,DToC(_cDtCanh := SF2->F2_I_DTRC))
        EndIf

        If !Empty(_cDtCanh) //SF2->F2_I_DTRC //DATA CANHOTO
            If ZDS->ZDS_EMISSA == _cDtCanh //SF2->F2_I_DTRC
                AAdd(_aItens, "ATO ENTREGA") //ATO ENTREGA OU POS-VENDA
            ElseIf ZDS->ZDS_EMISSA > _cDtCanh //SF2->F2_I_DTRC
                AAdd(_aItens, "POS-VENDA") //ATO ENTREGA OU POS-VENDA
            ElseIf ZDS->ZDS_EMISSA < _cDtCanh //SF2->F2_I_DTRC
                AAdd(_aItens, "INCONSISTENCIA") //ATO ENTREGA OU POS-VENDA
            EndIf
        Else
            AAdd(_aItens, "SEM INFORMACAO") //ATO ENTREGA OU POS-VENDA
        EndIf
        _cCodOper := Posicione("SC5",1,SF2->F2_FILIAL+SF2->F2_I_PEDID,"C5_I_OPER") //COD.OPER.TRIANG
        _cLocEmb  := RTRIM(Posicione("ZEL",1,xFilial("ZEL")+SC5->C5_I_LOCEM,"ZEL_DESCRI"))
        _cNumNFRM := " "
        If _cCodOper == "42" //OPERCAO REMESSA
            _cNumPvFt := SC5->C5_I_PVFAT
            _cCodLogt := Posicione("SC5",1,SF2->F2_FILIAL+_cNumPvFt,"C5_CLIENTE")
            _cLojLogt := SC5->C5_LOJACLI
            AAdd(_aItens, SubStr(Posicione("SA1",1,xFilial("SA1")+_cCodLogt+_cLojLogt,"A1_NOME"),1,20)) // OPERADOR TRIANGULAR
        ElseIf _cCodOper == "05"
            _cNumPvFt := SC5->C5_I_PVREM
            _cCodLogt := Posicione("SC5",1,SF2->F2_FILIAL+_cNumPvFt,"C5_CLIENTE")
            _cLojLogt := SC5->C5_LOJACLI
            _cNumNFRM := SC5->C5_NOTA
            AAdd(_aItens, SubStr(Posicione("SA1",1,xFilial("SA1")+_cCodLogt+_cLojLogt,"A1_NOME"),1,20)) // OPERADOR TRIANGULAR
        Else
            AAdd(_aItens," ")
        EndIf
        AAdd(_aItens,If(Posicione("SC5",1,SF2->F2_FILIAL+SF2->F2_I_PEDID,"C5_I_TRCNF")=="S","S","N")) //TROCA NOTA S/N
        _cNumPVTN := SC5->C5_I_PDPR
        _cNumFilTN:= SC5->C5_I_FLFNC

        AAdd(_aItens,_cNumFilTN) //FILIAAL ORIGEM TROCA NOTA

        If !Empty(SF2->F2_I_OPER)
           AAdd(_aItens,AllTrim(Posicione("SA2",1,xFilial("SA2")+SF2->F2_I_OPER+SF2->F2_I_OPLO,"A2_NOME"))) //OPERADOR
       ElseIf !Empty(SF2->F2_I_REDP)
           AAdd(_aItens,AllTrim(Posicione("SA2",1,xFilial("SA2")+SF2->F2_I_REDP+SF2->F2_I_RELO,"A2_NOME"))) //Redespacho
       Else
           AAdd(_aItens," ")
       EndIf

        _cNumNFTN := Posicione("SC5",1,_cNumFilTN+_cNumPVTN,"C5_NOTA")
        AAdd(_aItens,_cNumPVTN+" - "+_cNumNFTN)
        //ADICAO CAMPOS NOVOS
        DBSelectArea("ZF5")
        ZF5->(DBSetOrder(1))
        If ZF5->(DBSeek(SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE))

            While ZF5->(!Eof()) .And. SF2->F2_FILIAL == ZF5->ZF5_FILIAL .And. SF2->F2_DOC == ZF5->ZF5_DOCOC;
                                   .And. SF2->F2_SERIE == ZF5->ZF5_SEROC
                If ZF5->ZF5_STATUS == "000008"
                    _cDevFab := "S"
                EndIf

                If ZF5->ZF5_NDEBIT == "S"
                    _cNfDeb := "S"
                EndIf

                ZF5->(DBSkip())
            EndDo
        EndIf
        ZF5->(DBCloseArea())

        AAdd(_aItens,_cDevFab) //FILIAL ORIGEM TROCA NOTA
        AAdd(_aItens,_cNfDeb) //OPERADOR
        _cNomeGVen := Posicione("ACY",1,xFilial("ACY")+(_cAlias)->A1_GRPVEN,"ACY_DESCRI")
        AAdd(_aItens,(_cAlias)->A1_GRPVEN+"-"+AllTrim(_cNomeGVen))
        AAdd(_aItens,(_cAlias)->A1_I_REGIA)
        AAdd(_aItens,_cNumNFRM)
        AAdd(_aItens,_cLocEmb)

        _cDevFab := "N"
        _cNfDeb  := "N"

        AAdd(_aZDS,_aItens)//.CSV e XML *********************************************

        aMemo :=StrTokArr(AllTrim(ZDS->ZDS_NFORIG),CHR(13)+CHR(10))
        If Len(aMemo) > 0 .And. nOpcao = 3 // XML ******************************************
            For _nCpo := 1 TO Len(aMemo)
                _aItens:={}
                AAdd(_aItens,ZDS->ZDS_FILIAL)
                AAdd(_aItens,ZDS->ZDS_DOC   )
                AAdd(_aItens,ZDS->ZDS_SERIE )
                AAdd(_aItens,ZDS->ZDS_FORNEC)
                AAdd(_aItens,ZDS->ZDS_LOJA  )
                aDados:=StrTokArr(AllTrim(aMemo[_nCpo]),"-")
                If Len(aDados) > 4//As veses tem traço [-] no nome do vendedor
                    AAdd(_aItens,aDados[1])
                    AAdd(_aItens,AllTrim(aDados[2]))
                    AAdd(_aItens,AllTrim(aDados[3]))
                    AAdd(_aItens,AllTrim(aDados[4])+" - "+aDados[5])//As veses tem traço [-] no nome do vendedor
                ElseIf Len(aDados) > 3
                    AAdd(_aItens,aDados[1])
                    AAdd(_aItens,aDados[2])
                    AAdd(_aItens,aDados[3])
                    AAdd(_aItens,aDados[4])
                Else
                    AAdd(_aItens,"")
                    AAdd(_aItens,"")
                    AAdd(_aItens,"")
                    AAdd(_aItens,"")
                EndIf
                If Len(_aItens) = 9
                   AAdd(_aNFO,_aItens)//SÓ XML ******************************************
                EndIf
            Next
        EndIf

        (_cAlias)->(DBSkip())

    EndDo

    (_cAlias)->(DBCloseArea())

    If Len(_aZDS) > 0

        _aCab:={}

        If nOpcao = 2//.CSV (2-NÃO USA MAIS)*********************************************

            For _nCpo:= 1 TO Len(_aSX3)
                If _aSX3[_nCpo] = "ZDS_STATUS"
                   AAdd(_aCab,"Status")
                EndIf
                AAdd(_aCab,Getsx3cache(_aSX3[_nCpo],"X3_TITULO"))
            Next
            AAdd(_aCab,"Transportadora")//CAMPOS NOVOS
            AAdd(_aCab,"Carga")         //CAMPOS NOVOS

            DlgToExcel( { { "ARRAY" , cCadastro , _aCab , _aZDS } } )//GERA ARQUIVO .CSV *********************************************

        ElseIf nOpcao = 3//XML ******************************************
            If !_lXMLTambem
               AAdd(_aCab,"Status")
            EndIf
            For _nCpo:= 1 TO Len(_aSX3)
                If _lXMLTambem .And. _aSX3[_nCpo] = "ZDS_STATUS"
                   AAdd(_aCab,"Status")
                EndIf
                AAdd(_aCab,Getsx3cache(_aSX3[_nCpo],"X3_TITULO"))
                If _aSX3[_nCpo] = "ZDS_OBSGER"
                   _aCab[Len(_aCab)]:="Obs. Financeira"
                ElseIf _aSX3[_nCpo] = "ZDS_OBSABA"
                   _aCab[Len(_aCab)]:="Obs. Fiscal"
                EndIf
            Next

            _aCab2:={}
            For _nCpo := 1 to Len(_aCab)
                // Alinhamento: 1-Left   ,2-Center,3-Right
                // Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
                //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
                If AllTrim(_aCab[_nCpo]) = AllTrim( Getsx3cache("ZDS_VLRTOT","X3_TITULO") )
                   AAdd(_aCab2,{_aCab[_nCpo]   ,3           ,3         ,.T.})
                Else
                   AAdd(_aCab2,{_aCab[_nCpo]   ,1           ,1         ,.F.})
                EndIf
            Next
            AAdd(_aCab2,{"Transportadora"      ,1           ,1         ,.F.})//CAMPOS NOVOS
            AAdd(_aCab2,{"Carga"               ,2           ,1         ,.F.})//CAMPOS NOVOS
            AAdd(_aCab2,{"Dt.Entrega"          ,2           ,1         ,.F.})//CAMPOS NOVOS
            AAdd(_aCab2,{"Dt.Canhoto"          ,2           ,1         ,.F.})//CAMPOS NOVOS
            AAdd(_aCab2,{"Anal.Devolução"      ,1           ,1         ,.F.})//CAMPOS NOVOS CANHOTO
            AAdd(_aCab2,{"Oper. Triangular"    ,2           ,1         ,.F.})//CAMPOS OPERACAO TRIANGULAR
            AAdd(_aCab2,{"Troca Nota"          ,2           ,1         ,.F.})//CAMPOS NOVOS TROCA NOTA S/N
            AAdd(_aCab2,{"Fil.Carreg."         ,2           ,1         ,.F.})//CAMPOS NOVOS TROCA FILIAL CARREGAMENTO
            AAdd(_aCab2,{"Operador Logist."    ,1           ,1         ,.F.})//CAMPOS NOVOS OPERADOR LOGISTICO
            AAdd(_aCab2,{"NF Troca Nota"       ,2           ,1         ,.F.})//CAMPOS NOVOS
            AAdd(_aCab2,{"Dev.Fabric?."        ,2           ,1         ,.F.})//CAMPOS NOVOS DEV.FÁBRICA?
            AAdd(_aCab2,{"NF.Deb?"             ,2           ,1         ,.F.})//CAMPOS NOVOS NF DÉBITO?
            AAdd(_aCab2,{"Rede"                ,1           ,1         ,.F.})//CAMPOS NOVOS
            AAdd(_aCab2,{"Região"              ,2           ,1         ,.F.})//CAMPOS NOVOS
            AAdd(_aCab2,{"NF Remessa"          ,2           ,1         ,.F.})//CAMPOS NOVOS
            AAdd(_aCab2,{"Fil.Emb. NFD/NF"     ,1           ,1         ,.F.})

            //AAdd(_aCab,"Rede")
            //AAdd(_aCab,"Região")


            _aCab3:={}
            // Alinhamento: 1-Left   ,2-Center,3-Right
            // Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
            //           Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
            AAdd(_aCab3,{"Filial"           ,2           ,1         ,.F.})
            AAdd(_aCab3,{"Numero"           ,2           ,1         ,.F.})
            AAdd(_aCab3,{"Serie"            ,2           ,1         ,.F.})
            AAdd(_aCab3,{"Cliente"          ,2           ,1         ,.F.})
            AAdd(_aCab3,{"Loja"             ,2           ,1         ,.F.})
            AAdd(_aCab3,{"Nota/Serie Origem",2           ,1         ,.F.})
            AAdd(_aCab3,{"Emisssao"         ,2           ,1         ,.F.})
            AAdd(_aCab3,{"Cod. Vend."       ,2           ,1         ,.F.})
            AAdd(_aCab3,{"Nome do Vendedor" ,1           ,1         ,.F.})

            _aCab1:={}
            AAdd(_aCab1,{"Documentos"  ,_aCab2})
            AAdd(_aCab1,{"Notas Origem",_aCab3})
            _aDetalhe:={_aZDS,_aNFO}
                     //  _cNomeArq,_cDiretorio,_cTitulo,_cNomePlan,_aCabecalho,_aDetalhe,_lLeTabTemp,_cAliasTab,_aCampos,_lScheduller,_lCriaPastas,_aPergunte,_lEnviaEmail,_lXLSX)
            U_ITGEREXCEL(         ,           ,cCadastro,          ,_aCab1     ,_aDetalhe,           ,          ,        ,            ,.T.         ,         ,            ,_lXLSX)
            //XML ******************************************
        EndIf
    Else
        U_ITMsg("Não há registros para o filtro informado",'Atenção!',,3)
    EndIf

 ElseIf nOpcao = 1 //IMPORTAR DADOS *************************************************************************************************************************

    _cQuery1+= " SELECT SDS.R_E_C_N_O_ SDS_REC  "
    _cQuery1+= "		FROM " + RetSqlName("SDS")+" SDS "
    _cQuery1+= "  WHERE SDS.D_E_L_E_T_ = ' ' "
    _cQuery1+= "    AND SDS.DS_TIPO     = 'D' "
    _cQuery1+= "    AND SDS.DS_FORMUL   = 'N' "
    _cQuery1+= "    AND SDS.DS_STATUS  <> 'E' "//Só ignora as com ocorrecias

    // Filtra Emissao
    If !Empty(MV_PAR02)
        _cQuery1 += "  AND SDS.DS_EMISSA BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "'"
    ElseIf !Empty(MV_PAR01)
        _cQuery1 += "  AND SDS.DS_EMISSA >= '" + DToS(MV_PAR01) + "'"
    EndIf
    If !Empty(MV_PAR03)
        If Len(AllTrim(MV_PAR03)) > 2
            _cQuery1 += " AND SDS.DS_FILIAL IN " + FormatIn(AllTrim(MV_PAR03),";")
        Else
            _cQuery1 += " AND SDS.DS_FILIAL = '"+AllTrim(MV_PAR03)+"' "
        EndIf
    EndIf

    // Filtro por cliente
    If !Empty(MV_PAR06)
       _cQuery1 += " AND SDS.DS_FORNEC >= '" + MV_PAR06 + "' "
    EndIf

    If !Empty(MV_PAR07)
       _cQuery1 += " AND SDS.DS_LOJA >= '" + MV_PAR07 + "' "
    EndIf

    If !Empty(MV_PAR08)
       _cQuery1 += " AND SDS.DS_FORNEC <= '" + MV_PAR08 + "' "
    EndIf

    If !Empty(MV_PAR09)
       _cQuery1 += " AND SDS.DS_LOJA <= '" + MV_PAR09 + "' "
    EndIf

    _cQuery1 += " ORDER BY R_E_C_N_O_ "

    MPSysOpenQuery( _cQuery1 , _cAlias )

    oProc:cCaption := ("Contando os dados lidos...")
    ProcessMessages()
    DBSelectArea(_cAlias)
    (_cAlias)->(DBGoTop())
    _nConta:=_cTot := 0
    COUNT TO _cTot
    _cTot:=AllTrim(Str(_cTot))
    _nTam:=Len(_cTot)
    (_cAlias)->(DBGoTop())

    SA3->(DBSetOrder(1))
    SF2->(DBSetOrder(1)) //F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
    ZDS->(DBSetOrder(4)) //ZDS_FILIAL+ZDS_CHAVNF
    SDT->(DBSetOrder(2)) //SDT->DS_FILIAL+SDT->DT_FORNEC+SDT->DT_LOJA+SDT->DT_DOC+SDT->DT_SERIE

    While (_cAlias)->(!Eof())

        _nConta++
        oProc:cCaption := ("Processando Dados: "+ StrZero(_nConta,_nTam) +" de "+ _cTot)
        ProcessMessages()

        SDS->(DBGoTo((_cAlias)->SDS_REC))
        If !(lAchou:=ZDS->(DBSeek(SDS->DS_FILIAL+SDS->DS_CHAVENF)))
            If SDS->DS_STATUS $ 'P/E'//Não inclui Com Ocorrecias e Geradas, só le na alteração
                (_cAlias)->(DBSkip())
                Loop//Loop Tem que ser fora do Begin Transaction
            EndIf
        EndIf

        Begin Transaction

        If lAchou
            nAlt++
            ZDS->(RecLock("ZDS",.F.))
        Else
            nInc++
            ZDS->(RecLock("ZDS",.T.))
            ZDS->ZDS_FILIAL:=SDS->DS_FILIAL
            ZDS->ZDS_STATUS:=SDS->DS_STATUS
            ZDS->ZDS_DOC   :=SDS->DS_DOC
            ZDS->ZDS_SERIE :=SDS->DS_SERIE
            ZDS->ZDS_EMISSA:=SDS->DS_EMISSA
            ZDS->ZDS_FORNEC:=SDS->DS_FORNEC
            ZDS->ZDS_LOJA  :=SDS->DS_LOJA
            ZDS->ZDS_CNPJ  :=SDS->DS_CNPJ
            ZDS->ZDS_EST   :=SDS->DS_EST
            ZDS->ZDS_CHAVNF:=SDS->DS_CHAVENF
            ZDS->ZDS_STUEMI:= "5" // 5=Vazio
        EndIf
        If SA1->(DBSeek(xFilial("SA1")+SDS->DS_FORNEC+SDS->DS_LOJA))
            ZDS->ZDS_CLIEMA:=SA1->A1_I_EMAIL
            ZDS->ZDS_CLIMUN:=SA1->A1_MUN
        EndIf
        cDS_NFORIG:=""
        If SDT->(DBSeek(SDS->DS_FILIAL+SDS->DS_FORNEC+SDS->DS_LOJA+SDS->DS_DOC+SDS->DS_SERIE))
            Do While SDT->(!Eof()) .And. SDT->DT_FILIAL+SDT->DT_FORNEC+SDT->DT_LOJA+SDT->DT_DOC+SDT->DT_SERIE ==;
                                         SDS->DS_FILIAL+SDS->DS_FORNEC+SDS->DS_LOJA+SDS->DS_DOC+SDS->DS_SERIE
               If  !Empty(SDT->DT_NFORI)
                  SF2->(DBSeek(SDT->DT_FILIAL+SDT->DT_NFORI+SDT->DT_SERIORI))
                  SA3->(DBSeek(xFilial("SA3")+SF2->F2_VEND1))
                  
                  cDS_NFORIG += Iif(!Empty(cDS_NFORIG),CHR(13)+CHR(10),"")
                  cDS_NFORIG += SDT->DT_NFORI+" "+SDT->DT_SERIORI+" - "+DToC(SF2->F2_EMISSAO)
               EndIf
               
               SDT->(DBSkip())
            EndDo
        EndIf
        ZDS->ZDS_NFORIG := cDS_NFORIG
        ZDS->ZDS_STATUS := SDS->DS_STATUS
        ZDS->ZDS_VLRTOT := SDS->DS_TOTAL
        ZDS->(MSUnLock())

        End Transaction

        (_cAlias)->(DBSkip())

    EndDo

    (_cAlias)->(DBCloseArea())

    U_ITMsg(AllTrim(Str(nInc))+" Regitros Incluidos"+CHR(13)+CHR(10)+;
            AllTrim(Str(nAlt))+" Regitros Atualizados"+CHR(13)+CHR(10),'Atenção!',,2)

 EndIf

 FWRestArea(aArea)

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS45AM()
Autor-------------: ALEX WALLAUER
Data da Criacao---: 06/09/2019
Descrição---------: Alteração em Massa
===============================================================================================================================
*/
Static Function MOMS45AM(oProc) As Logical
 Local nAlt As Numeric
 Local _nCpo As Numeric
 Local _nCont As Numeric
 Local _cTot As Character
 Local _nTam As Numeric
 
 nAlt   := 0
 _nCpo  := 0
 _nCont :=0
 _cTot  := AllTrim(Str(Len(_aDados)))
 _nTam  := Len(_cTot)
 
 ZDS->(DBSetOrder(4))
 
 For _nCpo := 1 TO Len(_aDados)

    _nCont++
    oProc:cCaption := ("Processando Dados: "+ StrZero(_nCont,_nTam) +" de "+ _cTot)
    ProcessMessages()

    If _aDados[_nCpo,1]
       _aDados[_nCpo,2]:=StrTran(_aDados[_nCpo,2]," ","")
       If ZDS->(DBSeek( _aDados[_nCpo,2] ))

         _aDadAlt:= {}//Variavel Static

         AAdd( _aDadAlt , { "ZDS_FILIAL"   ,ZDS->ZDS_FILIAL   ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_DOC"      ,ZDS->ZDS_DOC      ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_SERIE"    ,ZDS->ZDS_SERIE    ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_EMISSA"   ,ZDS->ZDS_EMISSA   ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_FORNEC"   ,ZDS->ZDS_FORNEC   ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_LOJA"     ,ZDS->ZDS_LOJA     ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_CNPJ"     ,ZDS->ZDS_CNPJ     ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_EST"      ,ZDS->ZDS_EST      ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_CLIMUN"   ,ZDS->ZDS_CLIMUN   ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_CLIEMA"   ,ZDS->ZDS_CLIEMA   ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_VLRTOT"   ,ZDS->ZDS_VLRTOT   ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_CHAVNF"   ,ZDS->ZDS_CHAVNF   ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_NFORIG"   ,ZDS->ZDS_NFORIG   ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_STUEMI"   ,ZDS->ZDS_STUEMI   ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_STUSIT"   ,ZDS->ZDS_STUSIT   ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_OBSABA"   ,ZDS->ZDS_OBSABA   ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_OBSGER"   ,ZDS->ZDS_OBSGER   ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_OBSCOM"   ,ZDS->ZDS_OBSCOM   ,00,.F.} )
         AAdd( _aDadAlt , { "ZDS_STATUS"   ,ZDS->ZDS_STATUS   ,00,.F.} )

          ZDS->(RecLock("ZDS",.F.))

          If !Empty(_aDados[_nCpo,3])
             If _aDados[_nCpo,3] = "0"
                ZDS->ZDS_STUEMI := "5" // "" // 5=Vazio
             Else
                ZDS->ZDS_STUEMI := If(Empty(_aDados[_nCpo,3]),"5",_aDados[_nCpo,3])
             EndIf
          Else
             ZDS->ZDS_STUEMI := "5" // 5=Vazio
          EndIf

          If !Empty(_aDados[_nCpo,4])
             If _aDados[_nCpo,4] = "0"
                ZDS->ZDS_STUSIT:=""
             Else
                ZDS->ZDS_STUSIT:=_aDados[_nCpo,4]
             EndIf
          EndIf
          If !Empty(_aDados[_nCpo,5])
             ZDS->ZDS_OBSABA:=_aDados[_nCpo,5] // StrTran(_aDados[_nCpo,5],CHR(13)+CHR(10)," ")//
          EndIf
          If !Empty(_aDados[_nCpo,6])
             ZDS->ZDS_OBSGER:=_aDados[_nCpo,6] // StrTran(_aDados[_nCpo,6],CHR(13)+CHR(10)," ")//
          EndIf
          If !Empty(_aDados[_nCpo,7])
             ZDS->ZDS_OBSCOM:=_aDados[_nCpo,7] // StrTran(_aDados[_nCpo,7],CHR(13)+CHR(10)," ")//
          EndIf
          ZDS->(MSUnLock())

          If !(Empty(_aDados[_nCpo,3]+_aDados[_nCpo,4]+_aDados[_nCpo,5]+_aDados[_nCpo,6]+_aDados[_nCpo,7]))
             nAlt++
          EndIf

        U_ITGrvLog( _aDadAlt , 'ZDS' , 1 , _cChave , "A" , RetCodUsr(),Date(),Time() )
       EndIf
    EndIf

 Next
 
 U_ITMsg(AllTrim(Str(Len(_aDados)))+" Regitros Lidos"+CHR(13)+CHR(10)+;
         AllTrim(Str(nAlt))+" Regitros Atualizados"+CHR(13)+CHR(10),'Atenção!',,2)

Return .T.


/*
===============================================================================================================================
Programa----------: MOMS45LE()
Autor-------------: ALEX WALLAUER
Data da Criacao---: 06/09/2019
Descrição---------: LEGENDA DO Monitor de devoluções Italac
===============================================================================================================================
*/
User Function MOMS45LE()
 Local aCores As Array
 
 aCores	:= {}
 
 AAdd(aCores,{'BR_AMARELO'  ,"Documento Nao Gerado"   })
 AAdd(aCores,{'BR_VERDE'    ,"Documento Gerado"       })
 AAdd(aCores,{'BR_PRETO'    ,"Documento com Ocorrencia"})
 AAdd(aCores,{'BR_VERMELHO' ,"Documento Excluido"     })
 
 BrwLegenda("Legenda","Legenda",aCores) //-- Legenda

Return

/*
===============================================================================================================================
Programa----------: MOMS045 ()
Autor-------------: ALEX WALLAUER
Data da Criacao---: 06/09/2019
Descrição---------: Devolve o Status do Documento
===============================================================================================================================
*/
User Function MOMS045L() As Character
 Local cStatus:= "D" As Character// Documento Nao Gerado
 
 SDS->(DBSetOrder(2)) //DS_FILIAL+DS_CHAVENF
 
 If !SDS->(DBSeek(ZDS->ZDS_FILIAL+ZDS->ZDS_CHAVNF))
    cStatus:="X"// Documento Excluido
 ElseIf SDS->DS_STATUS = "P"
    cStatus:="P"// Documento Gerado
 ElseIf SDS->DS_STATUS = "E"
    cStatus:="E"// Documento c/ Ocorrência
 EndIf

Return cStatus


/*
===============================================================================================================================
Programa----------: MOMS045T
Autor-------------: Igor Melgaço
Data da Criacao---: 20/09/2024
Descrição---------: Rotina de Alteração do Registro
===============================================================================================================================
*/
User Function MOMS045A()
 Local aBtnUsr := {} As Array
 
 _aDadAlt := {}//Variavel Static
 
 AAdd( aBtnUsr , { "Historico de Alteracoes","Historico de Alteracoes", {|| U_MOMS045() } } )
 
 AAdd( _aDadAlt , { "ZDS_FILIAL"   ,ZDS->ZDS_FILIAL   ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_DOC"      ,ZDS->ZDS_DOC      ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_SERIE"    ,ZDS->ZDS_SERIE    ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_EMISSA"   ,ZDS->ZDS_EMISSA   ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_FORNEC"   ,ZDS->ZDS_FORNEC   ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_LOJA"     ,ZDS->ZDS_LOJA     ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_CNPJ"     ,ZDS->ZDS_CNPJ     ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_EST"      ,ZDS->ZDS_EST      ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_CLIMUN"   ,ZDS->ZDS_CLIMUN   ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_CLIEMA"   ,ZDS->ZDS_CLIEMA   ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_VLRTOT"   ,ZDS->ZDS_VLRTOT   ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_CHAVNF"   ,ZDS->ZDS_CHAVNF   ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_NFORIG"   ,ZDS->ZDS_NFORIG   ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_STUEMI"   ,ZDS->ZDS_STUEMI   ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_STUSIT"   ,ZDS->ZDS_STUSIT   ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_OBSABA"   ,ZDS->ZDS_OBSABA   ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_OBSGER"   ,ZDS->ZDS_OBSGER   ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_OBSCOM"   ,ZDS->ZDS_OBSCOM   ,00,.F.} )
 AAdd( _aDadAlt , { "ZDS_STATUS"   ,ZDS->ZDS_STATUS   ,00,.F.} )

 //Altera( <cAlias>, <nReg>         , <nOpc>, <aAcho>, <aCpos>, <nColMens>, <cMensagem>, <cTudoOk>, <cTransact>       , <cFunc>, <aButtons>, <aParam>, <aAuto>, <lVirtual>, <lMaximized>)
 AxAltera( "ZDS"   , ZDS->(Recno()) , 4     ,        ,        ,           ,            ,          ,  "U_MOMS045T()"   ,        ,  )

Return

/*
===============================================================================================================================
Programa----------: MOMS045T
Autor-------------: Igor Melgaço
Data da Criacao---: 20/09/2024
Descrição---------: Rotina de Gravção do Log
===============================================================================================================================
*/
User Function MOMS045T()
 Local  _cChave As Character
 
 _cChave := ZDS->(ZDS_FILIAL+ZDS_DOC+ZDS_SERIE+ZDS_FORNEC+ZDS_LOJA )
 
 //ITGrvLog( _aAux , _cAlias , _nOrdem , _cChave , _cOpcLog , _cCodUsr , _dDatLog , _cHorLog )
 U_ITGrvLog( _aDadAlt , 'ZDS' , 1 , _cChave , "A" , RetCodUsr(),Date(),Time() )

Return

/*
===============================================================================================================================
Programa----------: MOMS045H
Autor-------------: Igor Melgaço
Data da Criacao---: 20/09/2024
Descrição---------: Rotina de Consulta do  Histórico
===============================================================================================================================
*/
User Function MOMS045H()
 Local _cChave As Character
 Local _cTexto As Character

 _cChave := ZDS->(ZDS_FILIAL+ZDS_DOC+ZDS_SERIE+ZDS_FORNEC+ZDS_LOJA )
 _cTexto := "Documento "+AllTrim(ZDS->ZDS_DOC)+" Serie "+ZDS->ZDS_SERIE+" Fornecedor "+ZDS->ZDS_FORNEC+"-"+ZDS->ZDS_LOJA

 U_MOMS045G( _cChave,_cTexto,"ZDS",1  )

Return

/*
===============================================================================================================================
Programa----------: MOMS045HIS
Autor-------------: Igor Melgaço
Data da Criacao---: 20/09/2024
Descrição---------: Monta a tela detalhada do Histórico de Alterações do Cadastro
===============================================================================================================================
*/
User Function MOMS045G( _cChave As Character, _cTexto  As Character,cAlias  As Character,_nOrdem As Numeric)
 Local oDlg As Object
 Local oLbxTOP As Object
 Local oLbxDET As Object
 Local aPosObj As Array
 Local aObjects As Array
 Local aSize  As Array
 Local bMontaTOP As Block
 Local bMontaDET As Block
 Local oBar As Object
 Local oBold	As Object
 Local oScrPanel As Object
 Local aBtn As Array
 Local aCabLbxTOP As Array
 Local aCabLbxDET As Array
 
 Default  cAlias   := "ZDS"
 Default _nOrdem   := 1
 
 Private	nDvPosAnt As Numeric
 Private	cCadastro As Character
 
 oDlg		:= Nil
 oLbxTOP		:= Nil
 oLbxDET		:= Nil
 aPosObj   	:= {}
 aObjects  	:= {}
 aSize     	:= MsAdvSize()
 bMontaTOP	:= Nil
 bMontaDET	:= Nil
 
 oBar			:= Nil
 aBtn 	    	:= Array(02)
 oBold			:= Nil
 oScrPanel		:= Nil
 
 aCabLbxTOP	:= { "Chave", "Campo" , "Descrição" , "Última Alt." } // 04
 
 aCabLbxDET	:= { "Data"				,; // 01
                          "Hora"				,; // 02
                          "Usuário"			,; // 03
                          "Nome Usr."		,; // 04
                          "Cont. Orig."		,; // 05
                          "Cont. Alt."		 } // 06
 
 nDvPosAnt := 0
 cCadastro := "Histórico de Alterações da chave de registro - ["+ _cChave +"]"
 
 
 bMontaTOP		:= { || Processa({|lEnd| MOMS045LOG( @oLbxTOP , _cChave, cAlias ) }) }
 bMontaDET		:= { || MOMS045DET( @oLbxDET ,cAlias, oLbxTOP:aArray[oLbxTOP:nAt][01] , oLbxTOP:aArray[oLbxTOP:nAt][02] ) }
 
 //================================================================================
 //| Verifica se existe histórico de alterações                                   |
 //================================================================================
 DBSelectArea("Z07")
 Z07->( DBSetOrder(1) )
 If !Z07->( DBSeek( xFilial("Z07") + cAlias + Str(_nOrdem,2,0) + _cChave ) )
     MessageBox( "A Chave ["+ _cChave +"] não possui histórico de alterações." , "Atenção!" , 0 )
     Return
 EndIf
 
 AAdd( aObjects, { 100 , 025 , .T. , .F. , .T. } )
 AAdd( aObjects, { 100 , 070 , .T. , .F. } )
 AAdd( aObjects, { 100 , 100 , .T. , .T. } )
 
 aInfo   := { aSize[1] , aSize[2] , aSize[3] , aSize[4] , 3 , 2 }
 aPosObj := MsObjSize( aInfo , aObjects )
 
 DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD
 
 DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],00 to aSize[6],aSize[5] Of oMainWnd Pixel
 
     aPosObj[01][01] += 12
     aPosObj[02][01] += 10
     aPosObj[02][03] += 10
     aPosObj[03][01] += 10
     aPosObj[03][03] += 10
 
     //Imprime o código e o nome do Cliente
     @ aPosObj[01][01],aPosObj[01][02] MSPANEL oScrPanel PROMPT "" SIZE aPosObj[01][03],aPosObj[01][04] OF oDlg LOWERED
 
     @ 004 , 004 Say _cTexto 		SIZE 300,07 OF oScrPanel PIXEL FONT oBold 
 
     //Monta o resumo das alterações do cadastro
     @aPosObj[02][01],aPosObj[02][02] To aPosObj[02][03],aPosObj[02][04] LABEL "Campos Alterados"  OF oDlg PIXEL
 
     @aPosObj[02][01]+7,aPosObj[02][02]+4 	Listbox oLbxTOP Fields	;
                                             HEADER 	""		 		;
                                             On DbLCLICK ( Nil )		;
                                             Size aPosObj[02][04]-10,( aPosObj[02][03] - aPosObj[02][01] ) - 10 Of oDlg Pixel
 
     oLbxTOP:AHeaders	:= aClone(aCabLbxTOP)
     oLbxTOP:bChange		:= { || Eval(bMontaDET) }
 
     Eval(bMontaTOP)
 
     //================================================================================
     //| Monta os detalhes das alterações do cadastro                                 |
     //================================================================================
     @aPosObj[03][01],aPosObj[03][02] To aPosObj[03][03],aPosObj[03][04] LABEL "Histórico dos Campos" OF oDlg PIXEL
 
     @aPosObj[03][01]+7,aPosObj[03][02]+4 	Listbox oLbxDET Fields;
                                             HEADER 	""		 		;
                                             On DbLCLICK ( Nil )		;
                                             Size aPosObj[03][04]-10,( aPosObj[03][03] - aPosObj[03][01] ) - 10 Of oDlg Pixel
 
     oLbxDET:AHeaders := aClone(aCabLbxDET)
 
     Eval(bMontaDET)
 
     //================================================================================
     //| Monta a barra de botões da tela                                              |
     //================================================================================
     DEFINE BUTTONBAR oBar SIZE 25,25 3D OF oDlg
 
     DEFINE BUTTON aBtn[01] RESOURCE PmsBExcel()[1] OF oBar GROUP ACTION DlgToExcel({{"ARRAY","",oLbxPM7:AHeaders,oLbxPM7:aArray}})	TOOLTIP "Exportar para Planilha..."
     aBtn[01]:cTitle := ""
 
     DEFINE BUTTON aBtn[02] RESOURCE "FINAL" 		OF oBar GROUP ACTION oDlg:End() 													TOOLTIP "Sair da Tela..."
     aBtn[02]:cTitle := ""
 
     oDlg:lMaximized := .T.
 
 ACTIVATE MSDIALOG oDlg CENTERED

Return


/*
===============================================================================================================================
Programa----------: MOMS045LOG
Autor-------------: Igor Melgaço
Data da Criacao---: 20/09/2024
Descrição---------: Monta estrutura do Log de Alterações
===============================================================================================================================
*/
Static Function MOMS045LOG( oLbxAux As Object, cChave As Character,cAlias As Character)
 Local _cQuery As Character
 Local _cAlias As Character
 Local _aLbxAux As Array
 Local _nTotReg As Numeric
 Local _nCont As Numeric
 
 Default cAlias := "ZDS"
 
 _cQuery	 := ""
 _cAlias	 := GetNextAlias()
 _aLbxAux := {}
 _nTotReg := 0
 _nCont	 := 0
 
 //Consulta para buscar o resumo das alterações do cadastro
 _cQuery := " SELECT "
 _cQuery += "	Z07.Z07_CHAVE		AS CHAVE,	"
 _cQuery += " 	Z07.Z07_CAMPO 		AS CAMPO,	"
 _cQuery += " 	MAX( Z07.Z07_DATA )	AS DT_ULT	"
 _cQuery += " FROM "+ RetSqlName("Z07") +" Z07 "
 _cQuery += " WHERE "
 _cQuery += " 		Z07.D_E_L_E_T_  = ' ' "
 _cQuery += " AND	Z07.Z07_ALIAS	= '"+ cAlias +"' "
 _cQuery += " AND	Z07.Z07_CHAVE	= '"+ cChave +"' "
 _cQuery += " GROUP BY Z07.Z07_CHAVE,  Z07.Z07_DATA,  Z07.Z07_CAMPO "
 _cQuery += " ORDER BY Z07.Z07_CHAVE , Z07.Z07_DATA,  Z07.Z07_CAMPO "
 
 _cQuery	:= ChangeQuery(_cQuery)
 
 MPSysOpenQuery( _cQuery , _cAlias)
 
 TCSetField( _cAlias , "Z07.Z07_DATA" , "D" , 8 , 0 )
 
 DBSelectArea(_cAlias)
 (_cAlias)->(DBGoTop())
 
 (_cAlias)->( DBEval( { || _nTotReg++ } ) )
 
 ProcRegua(_nTotReg)
 
 (_cAlias)->(DBGoTop())
 
 //Grava os dados do Resumo
 While (_cAlias)->(!Eof())
 
     AAdd( _aLbxAux , {	(_cAlias)->CHAVE								   		   ,; // 01
                               (_cAlias)->CAMPO							   		      ,; // 02
                               Posicione("SX3",2,(_cAlias)->CAMPO,"X3_DESCRIC")	,; // 03
                            (_cAlias)->DT_ULT									         }) // 04
 
    _nCont++
    IncProc("Montando estrutura "+StrZero(_nCont,6)+" de "+StrZero(_nTotReg,6)  )
    (_cAlias)->( DBSkip() )
 EndDo
 
 (_cAlias)->( DBCloseArea() )
 
 //Monta o objeto do ListBox
 If	Len(_aLbxAux) > 0 .And. ValType(oLbxAux) == "O"
 
     oLbxAux:SetArray(_aLbxAux)
     oLbxAux:bLine:={||{	_aLbxAux[oLbxAux:nAt][01]	,; // 01
                         _aLbxAux[oLbxAux:nAt][02]	,; // 02
                         _aLbxAux[oLbxAux:nAt][03]	,; // 03
                         _aLbxAux[oLbxAux:nAt][04]	}} // 04
 
     oLbxAux:Refresh()
 
 EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS045DET
Autor-------------: Igor Melgaço
Data da Criacao---: 20/09/2024
Descrição---------: Monta estrutura de Detalhes do Log de Alterações do Campo
===============================================================================================================================
*/
Static Function MOMS045DET( oLbxAux As Object,cAlias As Character, cChave As Character , cCampo As Character )
 Local _cQuery As Character
 Local _cAlias As Character
 Local _aLbxAux As Array
 Local _nTotReg As Numeric
 Local _nCont As Numeric
 
 _cQuery	 := ""
 _cAlias	 := GetNextAlias()
 _aLbxAux := {}
 _nTotReg := 0
 _nCont	 := 0
 
 //Consulta para buscar os detalhes das alterações dos campos
 _cQuery := " SELECT "
 _cQuery += " 	Z07.Z07_DATA	AS DT_ALT	, "
 _cQuery += " 	Z07.Z07_HORA	AS HORA		, "
 _cQuery += " 	Z07.Z07_CODUSU	AS CODUSU	, "
 _cQuery += " 	Z07.Z07_CONORG	AS CONT_ORG	, "
 _cQuery += " 	Z07.Z07_CONALT	AS CONT_ALT	  "
 _cQuery += " FROM "+ RetSqlName("Z07") +" Z07 "
 _cQuery += " WHERE "
 _cQuery += " 	Z07.D_E_L_E_T_  = ' ' "
 _cQuery += " AND	Z07.Z07_ALIAS	= '"+ cAlias +"' "
 _cQuery += " AND	Z07.Z07_CAMPO	= '"+ cCampo +"' "
 _cQuery += " AND	Z07.Z07_CHAVE	= '"+ cChave +"' "
 _cQuery += " ORDER BY Z07.Z07_DATA , Z07.Z07_HORA , Z07.Z07_CODUSU , Z07.Z07_CONORG "
 _cQuery	:= ChangeQuery(_cQuery)
 
 MPSysOpenQuery( _cQuery , _cAlias)
 
 TCSetField( _cAlias , "Z07.Z07_DATA" , "D" , 8 , 0 )
 
 DBSelectArea(_cAlias)
 (_cAlias)->(DBGoTop())
 
 (_cAlias)->( DBEval( { || _nTotReg++ } ) )
 
 ProcRegua(_nTotReg) // Regua
 
 (_cAlias)->(DBGoTop())
 
 //Grava o resultado dos detalhes das alterações dos campos
 While (_cAlias)->(!Eof())
   AAdd( _aLbxAux , {(_cAlias)->DT_ALT,; // 01
                     (_cAlias)->HORA  ,; // 02
                     (_cAlias)->CODUSU,; // 03
   AllTrim( Capital( UsrFullName(	(_cAlias)->CODUSU ) )),; // 04
                           AllTrim(	(_cAlias)->CONT_ORG ) ,; // 05
                           AllTrim(	(_cAlias)->CONT_ALT ) }) // 06
   
   _nCont++
   IncProc("Montando estrutura "+StrZero(_nCont,6)+" de "+StrZero(_nTotReg,6)  )
   (_cAlias)->( DBSkip() )
 EndDo
 
 (_cAlias)->( DBCloseArea() )
 
 //Monta o objeto do ListBox com os dados dos detalhes
 If Len(_aLbxAux) > 0 .And. ValType(oLbxAux) == "O"
    oLbxAux:SetArray(_aLbxAux)
    oLbxAux:bLine:={||{ _aLbxAux[oLbxAux:nAt][01]	,; // 01
                        _aLbxAux[oLbxAux:nAt][02]	,; // 02
                        _aLbxAux[oLbxAux:nAt][03]	,; // 03
                        _aLbxAux[oLbxAux:nAt][04]	,; // 04
                        _aLbxAux[oLbxAux:nAt][05]	,; // 05
                        _aLbxAux[oLbxAux:nAt][06]	}} // 06
 
    oLbxAux:Refresh()
 
 EndIf
Return

/*
===============================================================================================================================
Programa----------: MOMS045Rel
Autor-------------: Alex Wallauer
Data da Criacao---: 10/10/2025
Descrição---------: Retorna a conteudo do campo Visual
===============================================================================================================================
*/
User Function MOMS045Rel(_cCampo As Character) As Character
 Local _cRet := "" As Character
 
 If _cCampo == "ZDS_NOMTRA"
    SF2->(DBSetOrder(1))
    If SF2->(DBSeek(ZDS->ZDS_FILIAL+SubStr(ZDS->ZDS_NFORIG,1,9)+SubStr(ZDS->ZDS_NFORIG,11,3)))
       If !Empty(SF2->F2_I_CTRA)
          _cRet :=SF2->F2_I_CTRA+" "+SF2->F2_I_LTRA+"-"+AllTrim(SF2->F2_I_NTRAN)
       EndIf  
    EndIf
    
 ElseIf _cCampo == "ZDS_NOMOPE"
    SF2->(DBSetOrder(1))
    If SF2->(DBSeek(ZDS->ZDS_FILIAL+SubStr(ZDS->ZDS_NFORIG,1,9)+SubStr(ZDS->ZDS_NFORIG,11,3))) 
       If !Empty(SF2->F2_I_OPER)
          _cRet :=SF2->F2_I_OPER+" "+SF2->F2_I_OPLO+"-"+AllTrim(Posicione("SA2",1,xFilial("SA2")+SF2->F2_I_OPER+SF2->F2_I_OPLO,"A2_NOME"))
       ElseIf !Empty(SF2->F2_I_REDP)
          _cRet :=SF2->F2_I_REDP+" "+SF2->F2_I_RELO+"-"+AllTrim(Posicione("SA2",1,xFilial("SA2")+SF2->F2_I_REDP+SF2->F2_I_RELO,"A2_NOME"))
       EndIf
    EndIf
 EndIf
 
Return _cRet
