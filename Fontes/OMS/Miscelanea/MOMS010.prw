/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |25/02/2024| Chamado 49894. Novos rateios de peso bruto por itens de nota fiscal
Lucas Borges  |15/09/2025| Chamado 50617. Retirada manipulação do SX1
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
==============================================================================================================================================================
*/

// Definicoes de Includes da Rotina.
#Include "TOTVS.CH"
#Include "TOTVS.ch"
#Include "RWMAKE.CH"
#Include "Colors.ch"

/*
===============================================================================================================================
Programa----------: MOMS010
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 09/11/2010
Descrição---------: Funcao utilizada para realizar a alteração do peso bruto mediante alguns produtos especificos que diferem
                    da pesagem do sistema com relacao ao peso real da balanca, para que nao exista divergencias entre o valor
                    pago pelo frete.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS010()

 Private cPerg := "MOMS010" As Character
 Private _dFatInic As Date
 Private _dFatFinal As Date

 _aHelp := { 'Informe a(s) Carga(s).'}

 While Pergunte(cPerg,.T.)
    _dFatInic := MV_PAR01
    _dFatFinal:= MV_PAR02
    _cCargas  := AllTrim(MV_PAR03)
    MOMS010A()
 EndDo

Return

/*
===============================================================================================================================
Programa----------: MOMS010A
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 09/11/2010
Descrição---------: Funcao usada para processar as notas ficais faturadas
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS010A()
 Local oPanel As Object
 Local nHeight := 0 As Numeric
 Local nWidth := 0 As Numeric
 Local aSize := {} As Array
 Local aBotoes := {} As Array
 Local aCoors := {} As Array
 Local x := 0 As Numeric
 Local oOK := LoadBitmap(GetResources(), "LBOK") As Object
 Local oNO := LoadBitmap(GetResources(), "LBNO") As Object
 Local _nContReg := 0 As Numeric
 Local cTab := "INF" As Character

 Private _cGrupoProd:= SuperGetMv("IT_GRPPESB") As Character //Armazena o codigo dos grupos de produtos que possibilitam efetuar a alteracao do peso bruto
 Private _nTolerPeso:= SuperGetMv("IT_TOLEPES") As Numeric   //Armazena a porcentatem permitida para alterar o peso bruto, tanto para cima quanto para baixo
 Private oDlg1 As Object
 Private _nOpca := 0 As Numeric
 Private nQtdTit := 0 As Numeric  // Quantidade de registros selecionados na tela
 Private _cAliasSF2 := GetNextAlias() As Character
 Private aStruct := {} As Array
 Private aTitulo := {} As Array
 Private aObjects := {} As Array
 Private _aPosObj1 := {} As Array
 Private aInfo := {} As Array
 Private oBrowse As Object
 Private _nPosAtu:=0 As Numeric
 Private _nPosNew:=0 As Numeric
 Private oVerde  := LoadBitmap(GetResources(),'br_verde') As Object
 Private oVerme  := LoadBitmap(GetResources(),'br_vermelho') As Object
 Private oQtda As Object
 Private _otemp As Object
 Private _oFont1 As Object
 Private _oFont2 As Object

 FWMsgRun( , {||  _nContReg:= MOMS010B() }, "AGUARDE...", "NOTA(S) ESTAO SENDO SELECIONADOS... ")

 If _nContReg == 0
    U_ITMsg("Não foram encontrada(s) nota(s) fiscal(is).",;
            "Informação",;
            "Favor checar os parâmetros de pesquisa informados.",1)
 Else
    //INSERE OS DADOS NO ARQUIVO TEMPORARIO CRIADO
    FWMsgRun( , {|oProc|  MOMS010D(cTab,oProc,_nContReg) }, "AGUARDE...", "Inserindo os dados selecionados: "+AllTrim(Str(_nContReg))+" registros" )

    //FAZ O CALCULO AUTOMATICO DE DIMENSOES DE OBJETOS
    aSize := MSADVSIZE()

    //OBTEM TAMANHOS DAS TELAS
    aAdd( aObjects, { 0, 0, .T., .T., .T. } )
    aInfo    := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 3, 3 }
    _aPosObj1 := MsObjSize( aInfo, aObjects,  , .T. )

    //BOTOES DA TELA.
    aAdd( aBotoes, {"PESQUISA" ,{|| MOMS010H(cTab)                                                                                 },"Pesquisar..."      })
    aAdd( aBotoes, {"S4WB005N" ,{|| FWMsgRun(,{|oProc| MOMS010J(cTab) } ,"Aguarde...","GERANDO VISUALIZACAO DA CARGA AGUARDE..."  )},"Visualizar Carga"  })
    aAdd( aBotoes, {'RELATORIO',{|| FWMsgRun(,{|oProc| MOMS010K(cTab) } ,"Aguarde...","GERANDO VISUALIZACAO DA N.F. AGUARDE..."   )},"Visualizar N.F."   })
    aAdd( aBotoes, {"RESPONSA" ,{|| FWMsgRun(,{|oProc| MOMS010L(cTab) } ,"Aguarde...","AGUARDE MONTANDO TELA PARA ALTERAR PESO...")},"Alterar Peso Bruto"})

    _oFont1:=TFont():New('Courier new',,14,,.T.)
    _oFont2:=TFont():New("Arial"      ,,18,,.T.)

    _aGardaPesos:= {}
    nCol1:=1
    nQtdTotal:=(cTab)->(LastRec())

    DEFINE MSDIALOG oDlg1 TITLE ("ROTINA PARA ALTERAÇÃO DE PESO BRUTO") From 0,0 To aSize[6],aSize[5] OF oMainWnd PIXEL

       oPanel:= TPanel():New(0,0,'',oDlg1,, .T., .T.,, ,315,25,.T.,.T. )
       @ 0.8 ,nCol1 Say ("Qtdade. de NFs:")           OF oPanel FONT _oFont1
       nCol1+= 6
       @ 0.8 ,nCol1 Say           nQtdTotal           OF oPanel Picture "@E 999,999" SIZE 60,8
       nCol1+= 6
       @ 0.8 ,nCol1 Say ("Qtdade. NFs alteradas:")    OF oPanel FONT _oFont1
       nCol1+= 9
       @ 0.8 ,nCol1 Say oQtda VAR nQtdTit             OF oPanel Picture "@E 999,999" SIZE 60,8
       nCol1+= 5
       @ 0.8 ,nCol1 Say "Duplo clique na linha para alterar o peso dos itens da NF e marcar."  OF oPanel  FONT _oFont2
       If FlatMode()
          aCoors := GetScreenRes()
          nHeight	:= aCoors[2]
          nWidth	:= aCoors[1]
       Else
          nHeight	:= 143
          nWidth	:= 315
       EndIf

       (cTab)->(DBGoTop())
       oBrowse := TCBrowse():New( 35,01,_aPosObj1[1,3] + 7,_aPosObj1[1,4] - 10,,;
                                ,{20,20,20,02,09,02,02,10,06,04,54,08,08},;
                                oDlg1,,,,,{||},,,,,,,.F.,cTab,.T.,,.F.,,.T.,.T.)

       oBrowse:AddColumn(TCColumn():New("",{|| If(&(cTab + '->' + cTab+"_PESBRU") <> &(cTab + '->' + cTab+"_NVPBRU"),overde,overme) },,,,"CENTER",    ,.T.,.F.,,,,.F.,))

       For x:=1 to Len(aStruct)
          If aStruct[x,1] == cTab + "_STATUS"
              oBrowse:AddColumn(TCColumn():New("",{|| If(&(cTab + '->' + cTab + "_STATUS") == Space(2),oNO,oOK)},,,,"CENTER",,.T.,.F.,,,,.F.,))
          ElseIf aStruct[x,1] <> "WK_RECNO"
              oBrowse:AddColumn(TCColumn():New((aTitulo[x,2]),&("{ || " + cTab + '->' + aStruct[x,1]+"}"),aTitulo[x,3],,,If(aStruct[x,2]=="N","RIGHT","LEFT"),,.F.,.F.,,,,.F.,))
          EndIf
       Next x
       //Insere imagem em colunas que os dados poderao ser ordenados
       MOMS010E(4)

       // Evento de duplo click na celula
       oBrowse:bLDblClick   := {|| MOMS010L(cTab,.F.) }

       //Evento quando o usuario clica na coluna desejada
       oBrowse:bHeaderClick := { |oBrowse, nCol| nColuna:= nCol,MsgRun("FAVOR AGUARDE, REALIZANDO OPERAÇÃO...",,{|| MOMS010G(cTab,nColuna) }) }

       oDlg1:lMaximized:=.T.

    ACTIVATE MSDIALOG oDlg1 ON INIT (EnchoiceBar(oDlg1,{|| If(MOMS010N(cTab),(_nOpca := 1,oDlg1:End()),) },;
                                                                          {|| _nOpca := 2,oDlg1:End()},,aBotoes),;
                                     oPanel:Align:=CONTROL_ALIGN_TOP,;
                                     oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT,;
                                     oBrowse:Refresh())

    If _nOpca == 1

       FWMsgRun( ,{|oProc| MOMS010O(cTab,oProc)  } , "Processando..." , "Acerto de Pesos e Rateios..." )

    EndIf

 EndIf

 If Select(cTab) > 0 .And. ValType(_otemp) = "O"
    _otemp:delete()
 EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS010B
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 09/11/2010
Descrição---------: Funcao usada para selecionar as notas fiscais faturadas de acordo com os parametros fornecidos pelo
                    usuario que ainda nao foram transmitidas e que possuam pelo menos um produto que se enquadre no grupo de pro-
                    especificos que poderam ter seu peso bruto alterado.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS010B() As Numeric

 Local _cQuery  := "" As Character
 Local nCountRec:= 0 As Numeric

 _cQuery := "SELECT"
 _cQuery += " F2.F2_CARGA,F2.F2_DOC,F2.F2_SERIE,F2.F2_CLIENTE,F2.F2_LOJA,A1.A1_NOME,F2_FIMP,"
 _cQuery += " F2.F2_EMISSAO,F2.F2_I_PEDID,F2.F2_I_PLACA,F2.F2_I_NTRAN,F2.F2_PLIQUI,F2.F2_PBRUTO, F2.R_E_C_N_O_ F2RECNO "
 _cQuery += "FROM " + RetSqlName("SF2") + " F2 "
 _cQuery += "JOIN " + RetSqlName("SA1") + " A1 ON A1.A1_COD = F2.F2_CLIENTE AND A1.A1_LOJA = F2.F2_LOJA "
 _cQuery += "WHERE"
 _cQuery += " F2.D_E_L_E_T_ = ' '"
 _cQuery += " AND A1.D_E_L_E_T_ = ' '"
 _cQuery += " AND F2.F2_FILIAL = '" + xFilial("SF2") + "'"
 If AllTrim(GETENVSERVER()) == "PRODUCAO"
    _cQuery += " AND F2.F2_FIMP = ' '"
 Else
    _cGrupoProd:=""
 EndIf
 _cQuery += " AND F2.F2_EMISSAO BETWEEN '" + DToS(_dFatInic) + "' AND '" + DToS(_dFatFinal) + "'"
 If !Empty((_cCargas))
	 _cQuery += " AND F2_CARGA IN "+ FormatIn(_cCargas,";")
 EndIf
 _cQuery += " AND F2.F2_DOC IN ( "
 _cQuery += "SELECT"
 _cQuery += " D2.D2_DOC "
 _cQuery += "FROM " + RetSqlName("SD2") + " D2 "
 _cQuery += "WHERE"
 _cQuery += " D2.D_E_L_E_T_ = ' '"
 _cQuery += " AND D2.D2_FILIAL = '" + xFilial("SD2") + "'"
 If !Empty(_cGrupoProd)
    _cQuery += " AND D2_GRUPO IN " + FormatIn(_cGrupoProd,",")
 EndIf
 _cQuery += " AND F2.F2_FILIAL  = D2.D2_FILIAL "
 _cQuery += " AND F2.F2_DOC     = D2.D2_DOC "
 _cQuery += " AND F2.F2_SERIE   = D2.D2_SERIE "
 _cQuery += " AND F2.F2_CLIENTE = D2.D2_CLIENTE "
 _cQuery += " AND F2.F2_LOJA    = D2.D2_LOJA )"

 MPSysOpenQuery(_cQuery,_cAliasSF2)
 DBSelectArea(_cAliasSF2)
 COUNT TO nCountRec //Contabiliza o numero de registros encontrados pela query

Return nCountRec

/*
===============================================================================================================================
Programa----------: MOMS010C
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 09/11/2010
Descrição---------: Cria tabela temporaria para montagem da tela
Parametros--------: cTab
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS010C(cTab As Char)

 aStruct  := {}
 aTitulo  := {}

 //================================================================================
 // Criando estrutura da tabela temporaria das unidades
 //================================================================================
 aAdd(aStruct,{cTab+"_STATUS"  ,"C",2,0})
 aAdd(aStruct,{cTab+"_CARGA"   ,"C",TamSX3("F2_CARGA")[1]    ,TamSX3("F2_CARGA")[2]  })
 aAdd(aStruct,{cTab+"_DOC"     ,"C",TamSX3("F2_DOC")[1]      ,TamSX3("F2_DOC")[2]    })
 aAdd(aStruct,{cTab+"_SERIE"   ,"C",TamSX3("F2_SERIE")[1]    ,TamSX3("F2_SERIE")[2]  })
 aAdd(aStruct,{cTab+"_CLIENT"  ,"C",TamSX3("F2_CLIENTE")[1]+2,TamSX3("F2_CLIENTE")[2]})
 aAdd(aStruct,{cTab+"_LOJA"    ,"C",TamSX3("F2_LOJA")[1]     ,TamSX3("F2_LOJA")[2]   })
 aAdd(aStruct,{cTab+"_NOMCLI"  ,"C",TamSX3("A1_NOME")[1]     ,TamSX3("A1_NOME")[2]   })
 aAdd(aStruct,{cTab+"_EMIS"    ,"D",TamSX3("F2_EMISSAO")[1]  ,TamSX3("F2_EMISSAO")[2]})
 aAdd(aStruct,{cTab+"_PEDIDO"  ,"C",TamSX3("F2_I_PEDID")[1]+2,TamSX3("F2_I_PEDID")[2]})
 aAdd(aStruct,{cTab+"_PLACA"   ,"C",TamSX3("F2_I_PLACA")[1]  ,TamSX3("F2_I_PLACA")[2]})
 aAdd(aStruct,{cTab+"_NOMTRA"  ,"C",TamSX3("F2_I_NTRAN")[1]  ,TamSX3("F2_I_NTRAN")[2]})
 aAdd(aStruct,{cTab+"_PESLIQ"  ,"N",TamSX3("F2_PLIQUI")[1]   ,TamSX3("F2_PLIQUI")[2] })
 aAdd(aStruct,{cTab+"_PESBRU"  ,"N",TamSX3("F2_PBRUTO")[1]   ,TamSX3("F2_PBRUTO")[2] })
 _nPosAtu:=Len(aStruct)
  aAdd(aStruct,{cTab+"_NVPBRU"  ,"N",TamSX3("F2_PBRUTO")[1]   ,TamSX3("F2_PBRUTO")[2] })
 _nPosNew:=Len(aStruct)
 aAdd(aStruct,{"WK_FIMP"       ,"C",03,0})
 aAdd(aStruct,{"WK_RECNO"      ,"N",10,0})

 //================================================================================
 // Armazena no array aCampos o nome, descricao dos campos e picture
 //================================================================================
 aAdd(aTitulo,{cTab+"_STATUS"  ,"  "               ," "							})
 aAdd(aTitulo,{cTab+"_CARGA"   ,"CARGA"            ,PesqPict("SF2","F2_CARGA")  })
 aAdd(aTitulo,{cTab+"_DOC"     ,"NOTA FISCAL"      ,PesqPict("SF2","F2_DOC")    })
 aAdd(aTitulo,{cTab+"_SERIE"   ,"SERIE"            ,PesqPict("SF2","F2_SERIE")  })
 aAdd(aTitulo,{cTab+"_CLIENT"  ,"CLIENTE"          ,PesqPict("SF2","F2_CLIENTE")})
 aAdd(aTitulo,{cTab+"_LOJA"    ,"LOJA"             ,PesqPict("SF2","F2_LOJA")   })
 aAdd(aTitulo,{cTab+"_NOMCLI"  ,"DESCRICAO CLIENTE","@!" })
 aAdd(aTitulo,{cTab+"_EMIS"    ,"EMISSAO"          ,PesqPict("SF2","F2_EMISSAO")})
 aAdd(aTitulo,{cTab+"_PEDIDO"  ,"PEDIDO"           ,PesqPict("SF2","F2_I_PEDID")})
 aAdd(aTitulo,{cTab+"_PLACA"   ,"PLACA"            ,PesqPict("SF2","F2_I_PLACA")})
 aAdd(aTitulo,{cTab+"_NOMTRA"  ,"TRANSPORTADORA"   ,"@!" })
 aAdd(aTitulo,{cTab+"_PESLIQ"  ,"PESO LIQUIDO"     ,PesqPict("SF2","F2_PLIQUI") })
 aAdd(aTitulo,{cTab+"_PESBRU"  ,"PESO BRUTO"       ,PesqPict("SF2","F2_PBRUTO") })
 aAdd(aTitulo,{cTab+"_NVPBRU"  ,"NOVO PESO"        ,PesqPict("SF2","F2_PBRUTO") })
 aAdd(aTitulo,{"WK_FIMP"       ,"Enviada?"         ,"@!" })

If Select(cTab) > 0
   (cTab)->(DBCloseArea())
EndIf
 // Permite o uso do arquivo criado dentro do protheus.
 _otemp := FWTemporaryTable():New( cTab, aStruct )

 _otemp:AddIndex( "01", {cTab + "_DOC",cTab + "_SERIE"} )
 _otemp:AddIndex( "02", {cTab + "_CARGA"} )
 _otemp:AddIndex( "03", {cTab + "_CLIENT",  cTab + "_LOJA"} )
 _otemp:AddIndex( "04", {cTab + "_NOMCLI"} )
 _otemp:AddIndex( "05", {cTab + "_EMIS"} )
 _otemp:AddIndex( "06", {cTab + "_PEDIDO"} )
 _otemp:AddIndex( "07", {cTab + "_NOMTRA"} )
 _otemp:AddIndex( "08", {cTab + "_PESBRU"} )

 _otemp:Create()

Return

/*
===============================================================================================================================
Programa----------: MOMS010D
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 09/11/2010
Descrição---------: Funcao usada para inserir os dados selecionados atraves da pesquisa no arquivo temporario criado anteriormente
Parametros--------: cTab,oProc,_nContReg
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS010D(cTab As Char,oProc As Object,_nContReg As Numeric)
 Local nConta := 0 As Numeric
 Local _cTot := AllTrim(Str(_nContReg)) As Character

 MOMS010C(cTab)//CRIA AQUIVO TEMPORARIO

 (_cAliasSF2)->(DBGoTop())

 While !(_cAliasSF2)->(Eof())
    nConta++
    oProc:cCaption := ('Processando: '+AllTrim(Str(nConta))+" de "+_cTot )
    ProcessMessages()
    (cTab)->(DbAppend())
    &(cTab+'->'+cTab+'_STATUS') := Space(2)
    &(cTab+'->'+cTab+'_CARGA')  := (_cAliasSF2)->F2_CARGA
    &(cTab+'->'+cTab+'_DOC')    := (_cAliasSF2)->F2_DOC
    &(cTab+'->'+cTab+'_SERIE')  := (_cAliasSF2)->F2_SERIE
    &(cTab+'->'+cTab+'_CLIENT') := (_cAliasSF2)->F2_CLIENTE
    &(cTab+'->'+cTab+'_LOJA')   := (_cAliasSF2)->F2_LOJA
    &(cTab+'->'+cTab+'_NOMCLI') := Upper((_cAliasSF2)->A1_NOME)
    &(cTab+'->'+cTab+'_EMIS')   := SToD((_cAliasSF2)->F2_EMISSAO)
    &(cTab+'->'+cTab+'_PEDIDO') := (_cAliasSF2)->F2_I_PEDID
    &(cTab+'->'+cTab+'_PLACA' ) := (_cAliasSF2)->F2_I_PLACA
    &(cTab+'->'+cTab+'_NOMTRA') := Upper((_cAliasSF2)->F2_I_NTRAN)
    &(cTab+'->'+cTab+'_PESLIQ') := (_cAliasSF2)->F2_PLIQUI
    &(cTab+'->'+cTab+'_PESBRU') := (_cAliasSF2)->F2_PBRUTO
    &(cTab+'->'+cTab+'_NVPBRU') := (_cAliasSF2)->F2_PBRUTO
    (cTab)->WK_FIMP             := If((_cAliasSF2)->F2_FIMP="S","SIM","NAO")
    (cTab)->WK_RECNO            := (_cAliasSF2)->F2RECNO

    (_cAliasSF2)->(DBSkip())

 EndDo

 (_cAliasSF2)->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa----------: MOMS010E
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 09/11/2010
Descrição---------: Funcao para setar a coluna com uma imagem que significa que ela esta ordenada ou nao
Parametros--------: nCol
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS010E(nCol As Numeric)

 Local _aColunas:= {} As Array
 Local x:= 0 As Numeric

 aAdd(_aColunas,{03})
 aAdd(_aColunas,{04})
 aAdd(_aColunas,{06})
 aAdd(_aColunas,{08})
 aAdd(_aColunas,{09})
 aAdd(_aColunas,{10})
 aAdd(_aColunas,{12})
 aAdd(_aColunas,{14})

 For x:=1 To Len(_aColunas)
    _aColunas[x,1]:=(_aColunas[x,1])
    //Seta as demais colunas como nao ordenadas
    If nCol <> _aColunas[x,1]
       oBrowse:SetHeaderImage(_aColunas[x,1],"COLRIGHT")
    Else
       //Seta a coluna com a imagem que significa que ela foi ordenada
       oBrowse:SetHeaderImage(_aColunas[x,1],"COLDOWN")
    EndIf

 Next x

Return

/*
===============================================================================================================================
Programa----------: MOMS010F
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 09/11/2010
Descrição---------: Inverte marcação
Parametros--------: cTab,_cStatus
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS010F(cTab As Char,_cStatus As Char)

 If _cStatus == Space(2)
    &(cTab+'->'+cTab+'_STATUS'):= 'XX'
    nQtdTit++
 Else
    &(cTab+'->'+cTab+'_STATUS'):= Space(2)
    nQtdTit--
 EndIf

 nQtdTit:= IIf(nQtdTit<0,0,nQtdTit)
 oQtda:Refresh()
 oBrowse:DrawSelect()
 oBrowse:Refresh(.T.)

Return

/*
===============================================================================================================================
Programa----------: MOMS010G
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 09/11/2010
Descrição---------: Orden tabela temporaria
Parametros--------: cTab As Character,nColuna As Numeric
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS010G(cTab As Character,nColuna As Numeric)
 Do Case
    //Marca ou desmarca todos
    Case nColuna = 1 .Or. nColuna = 2
         (cTab)->(DBGoTop())
         While (cTab)->(!Eof())
            //Se o titulo nao estiver selecionado
            If &(cTab+'->'+cTab+'_STATUS') == Space(2)
               &(cTab+'->'+cTab+'_STATUS'):= 'XX'
               nQtdTit++
                //Titulo selecionado
            Else
                &(cTab+'->'+cTab+'_STATUS'):= Space(2)
                nQtdTit--
            EndIf
            oQtda:Refresh()
            (cTab)->(DBSkip())
         EndDo
         nQtdTit:= IIf(nQtdTit<0,0,nQtdTit)
         oQtda:Refresh()
         (cTab)->(DBGoTop())
    //Carga
    Case nColuna == 3
         (cTab)->(DBSetOrder(2))
         (cTab)->(DBGoTop())

    //Numero do documento + Serie
    Case nColuna == 4
         (cTab)->(DBSetOrder(1))
         (cTab)->(DBGoTop())

     //Codigo do Cliente + Loja
     Case nColuna == 6
          (cTab)->(DBSetOrder(3))
          (cTab)->(DBGoTop())

     //Nome do Cliente
     Case nColuna == 8
          (cTab)->(DBSetOrder(4))
          (cTab)->(DBGoTop())

     //Emissao
     Case nColuna == 9
          (cTab)->(DBSetOrder(5))
          (cTab)->(DBGoTop())

     //Pedido
     Case nColuna == 10
          (cTab)->(DBSetOrder(6))
          (cTab)->(DBGoTop())

     //Nome da Transportadora
     Case nColuna == 12
          (cTab)->(DBSetOrder(7))
          (cTab)->(DBGoTop())

     //Peso Bruto
     Case nColuna == 14
          (cTab)->(DBSetOrder(8))
          (cTab)->(DBGoTop())
 EndCase

 MOMS010E(nColuna)

 oBrowse:DrawSelect()
 oBrowse:Refresh(.T.)

Return

/*
===============================================================================================================================
Programa----------: MOMS010H
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 09/11/2010
Descrição---------: Funcao para pesquisa no arquivo temporario.
Parametros--------: cTab As Character
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS010H(cTab As Character)

 Local oDlg
 Local aComboBx1:= {"Numero da Nota + Serie","Carga","Cliente + Loja","Nome do Cliente","Emissao","Pedido","Nome da Transportadora","Peso Bruto"}
 Local _nOpca   := 0
 Local nI       := 0
 Private cGet1  := Space(TamSX3("F2_DOC")[1] + TamSX3("F2_SERIE")[2])
 Private oGet1
 Private cComboBx1:= ""

 @ 178,181 TO 259,697 Dialog oDlg Title "Pesquisar"

 @ 004,003 ComboBox cComboBx1 Items aComboBx1 Size 213,010 PIXEL OF oDlg ON CHANGE MOMS010I()
 @ 020,003 MsGet oGet1 Var cGet1 Size 212,009 COLOR CLR_BLACK Picture "999999999999" PIXEL OF oDlg

 DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION (_nOpca:=1,oDlg:End()) OF oDlg
 DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION (_nOpca:=0,oDlg:End()) OF oDlg

 ACTIVATE MSDIALOG oDlg CENTERED

 If _nOpca == 1

    If (Len(AllTrim(cGet1)) > 0 .And. Type("cGet1") == 'C') .Or. (Type("cGet1") == 'N' .And. cGet1 > 0 ) .Or. (Type("cGet1") == 'D' .And. cGet1 <> CtoD(" ") )

       For nI := 1 To Len(aComboBx1)
           If cComboBx1 == aComboBx1[nI]
              (cTab)->(DBSetOrder(nI))
              (cTab)->(MsSeek(cGet1,.T.))
              oBrowse:DrawSelect()
              oBrowse:Refresh(.T.)
           EndIf
       Next nI
    Else
         U_ITMsg("Favor informar um conteúdo a ser pesquisado.",;
                 "Pesquisa Dados",;
                 "Para realizar a pesquisa é necessário que se forneça o conteúdo a ser pesquisado.",3)
     EndIf

 EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS010I
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 09/11/2010
Descrição---------: Altera campos do cabecalho
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS010I()

 If cComboBx1 == "Numero da Nota + Serie"
    cGet1:= Space(TamSX3("F2_DOC")[1] + TamSX3("F2_SERIE")[2])
    oGet1:Picture:= "999999999999"

 ElseIf cComboBx1 == "Carga"
    cGet1:= Space(TamSX3("F2_CARGA")[1])
    oGet1:Picture:= PesqPict("SF2","F2_CARGA")

 ElseIf cComboBx1 == "Cliente + Loja"
    cGet1:= Space(10)
    oGet1:Picture:= "@!"

 ElseIf cComboBx1 == "Nome do Cliente"
    cGet1:= Space(40)
    oGet1:Picture:= "@!"

 ElseIf cComboBx1 == "Emissao"
    cGet1:= CtoD(" ")
    oGet1:Picture:= PesqPict("SF2","F2_EMISSAO")

 ElseIf cComboBx1 == "Pedido"
    cGet1:= Space(6)
    oGet1:Picture:= PesqPict("SF2","F2_I_PEDID")

 ElseIf cComboBx1 == "Nome da Transportadora"
    cGet1:= Space(40)
    oGet1:Picture:= "@!"

 ElseIf cComboBx1 == "Peso Bruto"
    cGet1:= Space(TamSX3("F2_PBRUTO")[1])
    oGet1:Picture:= PesqPict("SF2","F2_PBRUTO")
    cGet1:= 0

 EndIf
 oGet1:SetFocus()

Return

/*
===============================================================================================================================
Programa----------: MOMS010K
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010
Descrição---------: Prepara nota de saida
Parametros--------: cTab
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS010K(cTab As Character)
 Local _aArea   := FwGetArea() As Array
 Local _cCliente:= AllTrim(&(cTab+'->'+cTab+'_CLIENT')) As Character
 Local _cLoja   := &(cTab+'->'+cTab+'_LOJA') As Character
 Local _cDoc    := &(cTab+'->'+cTab+'_DOC') As Character
 Local _cSerie  := &(cTab+'->'+cTab+'_SERIE') As Character
 Local aRotBack := {} As Array
 Local cCadBack := "" As Character
 Local nBack    := 00 As Numeric

 If Type( "N" ) == "N"
    nBack := n
    n     := 1
 EndIf

 // Caso exista, faz uma copia do aRotina
 If Type( "aRotina" ) == "A"
    aRotBack := AClone( aRotina )
 EndIf

 // Caso exista, faz uma copia do cCadastro
 If Type( "cCadastro" ) == "C"
    cCadBack := cCadastro
 EndIf

 SD2->(DBSetOrder(3))
 If SD2->(DBSeek(xFilial("SD2") + _cDoc + _cSerie + _cCliente + _cLoja ))

    aRotina := {{ "", "AxPesqui", 2 },{ "" ,"a920NFSAI", 0, 2}}
    A920NFSAI( "SD2", SD2->( Recno() ),2)

 EndIf

 // Restaura o aRotina
 If ValType( aRotBack ) == "A"
    aRotina := AClone( aRotBack )
 EndIf

 // Caso exista, faz uma copia do cCadastro
 If Type( "cCadBack" ) == "C"
    cCadastro := cCadBack
 EndIf

 If ValType( nBack ) == "N"
    n := nBack
 EndIf

 FwRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: MOMS010J
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010
Descrição---------: Visualiza carga
Parametros--------: cTab
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS010J(cTab As Character)
 Local _aArea  := FwGetArea() As Array
 Local _cCarga := &(cTab+'->'+cTab+'_CARGA') As Character
 Local aRotBack:= {} As Array
 Local cCadBack:= "" As Character
 Local nBack   := 0 As Numeric

 If Len(AllTrim(_cCarga)) > 0

    If Type( "N" ) == "N"
        nBack := n
        n     := 1
    EndIf

    // Caso exista, faz uma copia do aRotina
    If Type( "aRotina" ) == "A"
        aRotBack := AClone( aRotina )
    EndIf

    // Caso exista, faz uma copia do cCadastro
    If Type( "cCadastro" ) == "C"
        cCadBack := cCadastro
    EndIf

    DAK->(DBSetOrder(1))
    If DAK->(DBSeek(xFilial("DAK") + _cCarga))
       cCadastro := "Montagem de Carga - Visualizar"
       aRotina := { { "", "AxPesqui", 2 },{ "Carga Vis","Os200Visual",0,2} }
       Os200Visual("DAK",DAK->(Recno()),2)
    EndIf

    // Restaura o aRotina
    If ValType( aRotBack ) == "A"
        aRotina := AClone( aRotBack )
    EndIf

    // Caso exista, faz uma copia do cCadastro
    If Type( "cCadBack" ) == "C"
        cCadastro := cCadBack
    EndIf

    If ValType( nBack ) == "N"
        n := nBack
    EndIf

 Else

    U_ITMsg("Nao existe carga na linha posicionada.","Alerta",,1)

 EndIf

 FwRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: MOMS010L
Autor-------------: Alex Wallauer
Data da Criacao---: 30/07/2010
Descrição---------: Função dos 2 cliques do Browse
Parametros--------: cTab , _lBotao
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS010L(cTab As Character, _lBotao As Logical)
 Local _nOpc:=0 As Numeric
 Local I    :=0 As Numeric
 Local oDlg     As Object
 Local _cCliente   := AllTrim(&(cTab+'->'+cTab+'_CLIENT')) As Character
 Local _cLoja      := &(cTab+'->'+cTab+'_LOJA')    As Character
 Local _cDoc       := &(cTab+'->'+cTab+'_DOC')     As Character
 Local _cSerie     := &(cTab+'->'+cTab+'_SERIE')   As Character
 Local _nGetNvPes  := &(cTab+'->'+cTab+'_NVPBRU')  As Numeric
 Local _cPedido    := &(cTab+'->'+cTab+'_PEDIDO')  As Character
 Local _cPictQtde  := PesqPict("SF2","F2_PBRUTO ") As Character
 Local _cPictPBru  := PesqPict("SD2","D2_I_PTBRU") As Character
 Local _aItem      := {} As Array
 Local _aSize      := {} As Array
 Local _aInfo      := {} As Array
 Local _aObjects   := {} As Array
 Local _aPosObj    := {} As Array
 Default _lBotao   := .T.
 Private nPosPBN   := 0 As Numeric
 Private nPosPBA   := 0 As Numeric
 Private nPosRec   := 0 As Numeric
 Private nPesBNFAtu:= 0 As Numeric
 Private nPesBNFNew:= 0 As Numeric

 If &(cTab+'->'+cTab+'_STATUS') == 'XX' .And. !_lBotao
    &(cTab+'->'+cTab+'_STATUS') := Space(2)
    nQtdTit--
    oQtda:Refresh()
    Return
 EndIf
 // PEGA TAMANHOS DAS TELAS
 _aObjects := {}
 aAdd( _aObjects, { 315, 50, .T., .T. } )
 _aSize  := MsAdvSize()
 _aInfo  := { _aSize[ 1 ], _aSize[ 2 ], _aSize[ 3 ], _aSize[ 4 ], 3, 3 }
 _aPosObj:= MsObjSize( _aInfo, _aObjects,  , .T. )

 nGDAction:=  GD_UPDATE
 Private aHeader:={}
 //                          1           2            3   4 5       6          7        8       9           10    11       12         13         14          15        16             17
 //aHeader,{AllTrim(SX3->X3_TITULO)  , X3_CAMPO   , PICT ,TA,D, AllwaysTrue(),  USADO,X3_TIPO,ARQUIVO,X3_CONTEXT,X3_CBOX,X3_RELACAO,X3_WHEN   ,X3_VISUAL ,X3_VLDUSER,X3_PICTVAR,X3_OBRIGAT
 aAdd(aHeader,{""                   ,"MARCA"     ,"@BMP",04,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})//01
 aAdd(aHeader,{"Cod.Prod."          ,"WK_CODPROD","@!"       ,09,0,""            ,"","C"    ,""     ,""        ,""     ,""        ,".F."})//01 //02
 aAdd(aHeader,{"Descricao Prod."    ,"WK_DESCRIC","@!"       ,02,0,""            ,"","C","","","","",".F."})//02 //03 //Numeracao antiga  // numeracao nova
 aAdd(aHeader,{"Quantidade"         ,"D2_QUANT"  ,_cPictQtde ,16,3,""            ,"","N","","","","",".F."})//03 //04
 aAdd(aHeader,{"Peso Bruto Novo"    ,"WK_I_PTBRU",_cPictPBru ,15,3,"U_MOMS010M()","","N","","","","",".T."})//04 //05
 nPosPBN:=Len(aHeader)
 aAdd(aHeader,{"Peso Bruto Atual"   ,"WK_PBATUAL",_cPictPBru ,15,3,""            ,"","N","","","","",".F."})//05 //06
 nPosPBA:=Len(aHeader)
 aAdd(aHeader,{"Peso Liquido"       ,"D2_PESO"   ,_cPictPBru ,15,3,""            ,"","N","","","","",".F."})//06 //07
 nPosPL :=Len(aHeader)
 aAdd(aHeader,{"Peso Bruto Cadastro","B1_PESBRU" ,_cPictPBru ,15,3,""            ,"","N","","","","",".F."})//07 //08
 nPosRec:=Len(aHeader)+1//SD2->(Recno()) //09

 aCols := {}
 SD2->(DBSetOrder(3))
 If SD2->(DBSeek( xFilial("SD2") + _cDoc + _cSerie + _cCliente + _cLoja ))
    While SD2->(!Eof()) .And. SD2->D2_FILIAL+SD2->D2_DOC+SD2->D2_SERIE+SD2->D2_CLIENTE+SD2->D2_LOJA == xFilial("SD2")+_cDoc+_cSerie+_cCliente+_cLoja
       _aItem:={}
       SB1->(DBSeek(xFilial("SB1")+SD2->D2_COD))

       aAdd(_aItem,oVerme       )
       aAdd(_aItem,SD2->D2_COD  )
       aAdd(_aItem,SB1->B1_DESC )
       aAdd(_aItem,SD2->D2_QUANT)
       If (nPos:=aScan(_aGardaPesos , {|G| G[1] = SD2->(Recno())  } )) > 0
          aAdd(_aItem,_aGardaPesos[nPos,2] )//Peso Bruto Novo
          nPesBNFNew+=_aGardaPesos[nPos,2]
          If _aGardaPesos[nPos,2] <> SD2->D2_I_PTBRU
             _aItem[1]:=oVerde
          EndIf
       Else
          aAdd(_aItem,SD2->D2_I_PTBRU)//Peso Bruto Atual
          nPesBNFNew+=SD2->D2_I_PTBRU
       EndIf
       aAdd(_aItem,SD2->D2_I_PTBRU)//Peso Bruto Atual
       aAdd(_aItem,(SD2->D2_PESO*SD2->D2_QUANT))
       aAdd(_aItem,SB1->B1_PESBRU )
       aAdd(_aItem,SD2->(Recno()) )
       aAdd(_aItem,.F.)

       aAdd(aCols,_aItem)

       nPesBNFAtu+=SD2->D2_I_PTBRU

       SD2->(DBSkip())
    EndDo
 Else
    U_ITMsg("Nao existem itens para o NF selecionada.","Atenção",,1)
    Return
 EndIf

 Private _lPedPallet:= MOMS010P(_cPedido) As Logical  // Armazena se o pedido eh somente de pallet para que desta forma seja alterado o peso liquido de acordo com o peso Bruto alterado

 While .T.

   _nOpc:=0
   nQtdItem:=Len(aCols)
   nCol1:=1

   DEFINE MSDIALOG oDlg TITLE "ALTERAR PESO BRUTO POR ITEM" FROM 1,1 TO _aSize[6],_aSize[5] OF oMainWnd PIXEL

     oPanel:= TPanel():New(0,0,'',oDlg,, .T., .T.,, ,315,25,.T.,.T. )

     @ 0.8 ,nCol1 Say ("Qtdade Itens:")      OF oPanel FONT _oFont1
     nCol1+=6
     @ 0.8 ,nCol1 Say nQtdItem               OF oPanel Picture "@E 999,999" SIZE 60,8
     nCol1+=5
     @ 0.8 ,nCol1 Say ("% Permitido:")       OF oPanel FONT _oFont1
     nCol1+=6
     @ 0.8 ,nCol1 Say _nTolerPeso            OF oPanel Picture "@E 9999.99" SIZE 60,8
     nCol1+=5
     @ 0.8 ,nCol1 Say "Peso NF Atual:"       OF oPanel FONT _oFont1
     nCol1+=6
     @ 0.8 ,nCol1 Say nPesBNFAtu             OF oPanel Picture "@E 9999,999.99" SIZE 60,8
     nCol1+=5
     @ 0.8 ,nCol1 Say "Peso NF Novo:"        OF oPanel FONT _oFont1
     nCol1+=6
     @ 0.8 ,nCol1 Say oPBNew VAR nPesBNFNew  OF oPanel Picture "@E 9999,999.99" SIZE 60,8
     nCol1+=5
     @ 0.8 ,nCol1 Say 'Duplo clique na coluna "Peso Bruto Novo" para alterar o peso bruto do item.'  OF oPanel FONT _oFont2

                               //[ nTop] , [ nLeft], [ nBottom]  , [ nRight ]  , [ nStyle],cLinhaOk,cTudoOk,cIniCpos, [ aAlter], [ nFreeze], [ nMax], [ cFieldOk], [ cSuperDel], [ cDelOk], [ oWnd], [ aPartHeader], [aParCols], [ uChange], [ cTela], [ aColsSize]
     oMsMGet:= MsNewGetDados():New( 10  ,1        ,_aPosObj[1,3],_aPosObj[1,4],nGDAction ,        ,       ,        ,          ,           ,        ,            ,             ,          ,oDlg    ,aHeader        , aCols     ,)

   ACTIVATE MSDIALOG oDlg CENTERED ON INIT (EnchoiceBar(oDlg,{|| _nOpc:=1,oDlg:End()},;
                                                             {|| _nOpc:=0,oDlg:End()},,) ,;
                                            oPanel:Align:=CONTROL_ALIGN_TOP,;
                                            oMsMGet:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT,;
                                            oMsMGet:oBrowse:Refresh())
   aCols:=oMsMGet:aCols
   If _nOpc = 1
       _nGetNvPes:=0
       For I := 1 TO Len(aCols)
           If (nPos:=aScan(_aGardaPesos , {|G| G[1] = aCols[I,nPosRec] } )) > 0
              _aGardaPesos[nPos,2]:= aCols[I,nPosPBN]  //coloca o valor do peso bruto de novo pq pode ter sido alterado mais de 1 vez na mesma tela
           ElseIf aCols[I,nPosPBN] > 0
              aAdd(_aGardaPesos,{ aCols[I,nPosRec] ,;//01 - Recno do SD2
                                  aCols[I,nPosPBN] ,;//02 - Peso bruto novo digitado
                                  (cTab)->WK_RECNO })//03 - Recno DO SF2
           EndIf
           _nGetNvPes+=If(aCols[I,nPosPBN]>0,aCols[I,nPosPBN],aCols[I,nPosPBA])
       Next I
       //If !U_MOMS010M(_nGetNvPes, _nGetPesBru, _nPesLiquid)
       //   Loop
       //EndIf
       If _lPedPallet//VERIFICA SE O PEDIDO SE EH SOMENTE DE PALLET
          &(cTab+'->'+cTab+'_NVPBRU') := _nGetNvPes
          &(cTab+'->'+cTab+'_PESLIQ') := _nGetNvPes
       Else
          &(cTab+'->'+cTab+'_NVPBRU') := _nGetNvPes
       EndIf
       If &(cTab+'->'+cTab+'_STATUS') == Space(2)
          &(cTab+'->'+cTab+'_STATUS'):= 'XX'
          nQtdTit++
          oQtda:Refresh()
       EndIf
    Else
       If U_ITMsg("Confirma SAIR ?  Todos as alterações feitas nessa entrada serão perdidas.",'Atenção!',"As alterações feitas anteriormente não serão perdidas.",3,2,3,,"CONFIRMA","Voltar")
          Exit
       EndIf
    EndIf

    Exit
 EndDo

Return

/*
===============================================================================================================================
Programa----------: MOMS010M
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010
Descrição---------: Valida peso bruto
Parametros--------: _nGetNvPes As Numeric, _nGetPesBru As Numeric, _nPesLiquid As Numeric
Retorno-----------: _lRet As Logical
===============================================================================================================================
*/
User Function MOMS010M(_nGetNvPes As Numeric, _nGetPesBru As Numeric, _nPesLiquid As Numeric) As Logical
 Local _lRet:= .T. As Logical
 Local _nPorcent As Numeric
 Local _nPesoMax As Numeric
 Local _nPesoMin As Numeric
 DEFAULT _nGetNvPes := M->WK_I_PTBRU//aCols[N,nPosPBN]
 DEFAULT _nGetPesBru:= aCols[N,nPosPBA]
 DEFAULT _nPesLiquid:= aCols[N,nPosPL]

 If _nGetNvPes <= 0
    U_ITMsg("Favor fornecer um novo peso bruto posisitivo antes de efetuar a confirmação!","Atenção",,3)
    _lRet:= .F.
 Else
    //Pedidos que nao sejam somente de Pallet, passaram pelas validacoes abaixo
    //Nos pedidos que contem somente Pallet eh desprezada a questao do limite de porcentagem permitida
    If !_lPedPallet
       If _nGetNvPes >= _nPesLiquid//Verifica se o novo peso bruto eh maior ou igual ao peso liquido
          _nPorcent:=ABS(((_nGetNvPes-_nGetPesBru)/_nGetPesBru)*100)
          If _nPorcent > _nTolerPeso
             _nPesoMax:= _nGetPesBru*((_nTolerPeso/100)+1)
             _nPesoMin:= _nGetPesBru*(100-_nTolerPeso)/100
             _cTextoPL:=""
             If _nPesLiquid >= _nPesoMin
                _nPesoMin:=_nPesLiquid
                _cTextoPL:=" (Peso Liquido)"
             EndIf
             U_ITMsg("O valor informado para o novo peso bruto esta incorreto."+CRLF+;
                     "Valor Maximo: "+AllTrim(Transform( (_nPesoMax) ,"@E 999,999,999,999.9999"))+CRLF+;
                     "Valor Atual: "+AllTrim(Transform( (_nGetPesBru),"@E 999,999,999,999.9999"))+CRLF+;
                     "Valor Minimo: "+AllTrim(Transform( (_nPesoMin) ,"@E 999,999,999,999.9999"))+_cTextoPL,;
                     "Valor do Peso Bruto Incorreto",;
                     "Favor digitar um valor cujo a variação não pode ser superior à " + AllTrim(Str(_nTolerPeso)) + " % do valor do peso bruto de origem, isto tanto para um valor acima quanto para um valor abaixo da porcentagem indicada sobre o peso bruto original.",1)
             _lRet:= .F.
          EndIf
       Else
          U_ITMsg("O novo peso bruto não pode ser menor que o peso líquido: " + AllTrim(Transform(_nPesLiquid,"@E 999,999,999,999.9999"))+".","Alerta",,1)
          _lRet:= .F.
       EndIf
    EndIf
 EndIf

 If _lRet
    nPesBNFNew-=aCols[N,nPosPBN]//tira o que tava antes no peso bruto novo 
    nPesBNFNew+=_nGetNvPes//soma o novo peso bruto
    oPBNew:Refresh()
 EndIf
 aCols[N,1]:=If(_nGetNvPes<>_nGetPesBru,oVerde,oVerme)

Return _lRet

/*
===============================================================================================================================
Programa----------: MOMS010N
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010
Descrição---------: Valida seleção de registros
Parametros--------: cTab
Retorno-----------: _lRet As Logical
===============================================================================================================================
*/
Static Function MOMS010N(cTab As Char) As Logical
 Local _lRet     := .T.
 Local _aArea    := FwGetArea()
 Local _nLinha   := 1
 Local _nLinhaMsg:=""

 //Se tiver pelo menos uma linha de registros selecionada
 If nQtdTit > 0
    (cTab)->(DBGoTop())
    While !(cTab)->(Eof())
       //Verifica se a linha foi selecionada
       If &(cTab+'->'+cTab+'_STATUS') == 'XX'
          If &(cTab+'->'+cTab+'_NVPBRU') == 0
            _nLinhaMsg+= AllTrim(Str(_nLinha)) + ','
            _lRet := .F.
         EndIf
      EndIf
      _nLinha++
      (cTab)->(DBSkip())
   EndDo
 Else
   U_ITMsg("Favor selecionar um ou mais registros para realizar a alteração do peso bruto..",;
              "Alerta",,3)
   _lRet := .F.
 EndIf
 If Len(AllTrim(_nLinhaMsg)) > 0
    U_ITMsg("Existem linhas selecionadas para alteração do peso bruto mas sem o fornecimento do novo peso.",;
               "ERRO",;
               "Favor informar o novo peso bruto para todas as linhas selecionadas, as linhas que se encontram com o problema são: " + SubStr(_nLinhaMsg,1,Len(_nLinhaMsg) - 1)+".",1)
 EndIf

 FwRestArea(_aArea)

Return _lRet

/*
===============================================================================================================================
Programa----------: MOMS010O
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 30/07/2010
Descrição---------: Grava alterações
Parametros--------: cTab, oProc As Object
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS010O(cTab As Char, oProc As Object)
 Local _aArea   := FwGetArea() As Array
 Local _aAreaSD2:= SD2->(FwGetArea()) As Array
 Local _cDoc        As Character
 Local _cSerie      As Character
 Local _cCliente    As Character
 Local _cLojaCli    As Character
 Local _nPesBrtAnt  As Numeric
 Local _nNvPesBru   As Numeric
 Local _nNvPesLiq   As Numeric
 Local _cCarga      As Character
 Local I := 0       As Numeric
 Local _nConta := 0 As Numeric
 Local _aCargas:={} As Array

 //ProcRegua(nQtdTit)

 DAK->(DBSetOrder(1))
 DAI->(DBSetOrder(3))
 SC5->(DBSetOrder(1))
 SC6->(DBSetOrder(1)) // C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
 SF2->(DBSetOrder(1))
 SD2->(DBSetOrder(3))
 (cTab)->(DBGoTop())
 While !(cTab)->(Eof())

    _cDoc         := &(cTab+'->'+cTab+'_DOC')
    oProc:cCaption := "Acertando pesos, NF: "+_cDoc+" - "+AllTrim(Str(_nConta))+" gravadas..."
    ProcessMessages()

    If &(cTab+'->'+cTab+'_STATUS') == 'XX'
       _nConta++

       _cSerie    := &(cTab+'->'+cTab+'_SERIE')
       _cCliente  := AllTrim(&(cTab+'->'+cTab+'_CLIENT'))
       _cLojaCli  := &(cTab+'->'+cTab+'_LOJA')
       _nPesBrtAnt:= &(cTab+'->'+cTab+'_PESBRU')
       _nNvPesLiq := &(cTab+'->'+cTab+'_PESLIQ')
       _cCarga    := &(cTab+'->'+cTab+'_CARGA')
       _cPedido   := &(cTab+'->'+cTab+'_PEDIDO')

       Begin Transaction
         Begin Sequence

           _aItensPesos:={}//Itens do SF2 posicionado
           For I := 1 TO Len(_aGardaPesos)//{ RECNO DO SD2 , PESO BRUTO NOVO DIGITADO , RECNO DO SF2 })
               If _aGardaPesos[I,3] = (cTab)->WK_RECNO// RECNO DO SF2 iguais
                  aAdd(_aItensPesos,{_aGardaPesos[I,1],_aGardaPesos[I,2]})
               EndIf
           Next I
           _lAcerto:= .F.
           If Len(_aItensPesos) = 0 // pq foi marcado pelo cabeçario
              SD2->(DBSetOrder(3))
              If SD2->(DBSeek(xFilial("SD2")+_cDoc + _cSerie + _cCliente + _cLojaCli))
                 _lAcerto:= .T.
                 While SD2->(!Eof()) .And. SD2->(D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA ) == xFilial("SD2")+_cDoc + _cSerie + _cCliente + _cLojaCli
                    aAdd(_aItensPesos,{ SD2->(RECNO()) , SD2->D2_I_PTBRU })//{ RECNO DO SD2 , PESO BRUTO ATUAL  })
                    SD2->(DBSkip())
                 EndDo
              EndIf
           EndIf
           _nNvPesBru:=0
           For I := 1 TO Len(_aItensPesos)// { RECNO DO SD2 , PESO BRUTO NOVO DIGITADO  })
               SD2->(DBGoTo(_aItensPesos[I,1]))
               If !_lAcerto .And. !Empty(_aItensPesos[I,2])
                   SD2->(RecLock("SD2",.F.))
                   SD2->D2_I_PTBRU:=_aItensPesos[I,2]
                   SD2->(MSUnLock())
               EndIf
               If SC6->(DBSeek(SD2->D2_FILIAL+SD2->D2_PEDIDO+SD2->D2_ITEMPV+SD2->D2_COD))
                  SC6->(RecLock("SC6",.F.))
                  SC6->C6_I_PTBRU:=SD2->D2_I_PTBRU
                  SC6->(MSUnLock())
               EndIf
               _nNvPesBru+=SD2->D2_I_PTBRU
           Next I

           If _nNvPesBru > 0 .And. SC5->(DBSeek( SD2->D2_FILIAL+SD2->D2_PEDIDO))
              SC5->(RecLock("SC5", .F.))
              SC5->C5_I_PESBR:=_nNvPesBru
              SC5->C5_PBRUTO :=_nNvPesBru
              SC5->(MSUnLock())
           EndIf

           // Atualiza a tabela SF2 com o novo peso bruto e os dados de log da alteracao
           If _nNvPesBru > 0 .And. SF2->(DBSeek(xFilial("SF2") + _cDoc + _cSerie + _cCliente + _cLojaCli))

              SF2->(RecLock("SF2", .F.))

              If SF2->F2_I_PBRUT == 0
                 SF2->F2_I_PBRUT := _nPesBrtAnt // Armazena o peso bruto original
              EndIf
              SF2->F2_PBRUTO  := _nNvPesBru    // Armazena o novo peso bruto, que sera utilizado na impressao do DANFE
              SF2->F2_PLIQUI  := _nNvPesLiq    // Armazena o novo peso liquido, que sera utilizado na impressao do DANFE
              SF2->F2_I_MATUS := FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]  // Armazena o filial + matricula do usuario que realizou a alteracao
              SF2->F2_I_DTALT := Date()        // Armazena a data em que foi realizada a alteracao
              SF2->F2_I_HORA  := Time()        // Armazena a hora em que foi realizada a alteracao
              SF2->(MSUnLock())

              // Verifica se tem carga, para diante disto alterar os pesos das tabelas DAK e DAI
              If !Empty(_cCarga)
                 If aScan(_aCargas,_cCarga) = 0
                    aAdd(_aCargas,_cCarga)
                 EndIf
                 If DAI->(DBSeek(SF2->F2_FILIAL+ _cDoc + _cSerie + _cCliente + _cLojaCli))
                    DAI->(RecLock("DAI", .F.))
                    DAI->DAI_PESO := _nNvPesBru // Armazena o novo peso bruto
                    DAI->(MSUnLock())
                 Else
                    U_ITMsg("Não foi possível encontrar a Nota (DAI): " + SF2->F2_FILIAL+ _cDoc + _cSerie + _cCliente + _cLojaCli + " na tabela DAI para efetuar a alteração do peso bruto.",;
                            "ERRO",;
                            "Favor contactar a TI informando o problema.", 1)
                 EndIf
              Else
                 
                 U_NotaRatVlrs( SF2->F2_I_FRET , SF2->F2_PBRUTO ) //FUNÇÃO DO M460FIM para refazer o Reteio do Frete 1o percurso
                             //_lGrava,_lCalcSeguro, _nPesoTotC    ,_nPesoSoPallet , _nTotPedagio   ,_nVlrCHEPTot ,_nVlrFretOL    ,_nPesTotOL
                 U_GrvRatVlrs( .T.    , .F.        , SF2->F2_PBRUTO,0              , SF2->F2_I_VLPED,             ,SF2->F2_I_FREOL,SF2->F2_PBRUTO) //FUNÇÃO DO M460FIM para refazer o Reteio do Frete 2o percurso e pedagio no SF2 e SD2// Rateia o frete do 2o percurso e pedagio
              EndIf

           EndIf

          End Sequence
        End Transaction
     EndIf

     (cTab)->(DBSkip())
 EndDo


 _nConta:=0
 DAK->(DBSetOrder(1)) // DAK_FILIAL+DAK_COD+DAK_SEQCAR
 DAI->(DBSetOrder(1)) // DAI_FILIAL+DAI_COD+DAI_SEQCAR+DAI_SEQUEN+DAI_PEDIDO
 For I := 1 TO Len(_aCargas)
     _cCarga:=_aCargas[I]
     oProc:cCaption := "Acertando rateios, Carga: "+_cCarga+" - "+AllTrim(Str(_nConta))+" Acertadas..."
     ProcessMessages()
     If DAK->(DBSeek(xFilial("DAK") + _cCarga))

        Begin Transaction
           Begin Sequence

              DAI->(DBSetOrder(1)) // Seto de novo por causa das funções de rateios que troca a ordem
              If DAI->(DBSeek(DAK->(DAK_FILIAL+DAK_COD+DAK_SEQCAR)))
                 _nSomaPesoDAK:=0
                 While !DAI->(Eof()) .And. DAI->(DAI_FILIAL+DAI_COD) == DAK->(DAK_FILIAL+DAK_COD)
                    _nSomaPesoDAK+=DAI->DAI_PESO
                    DAI->(DBSkip())
                 EndDo
                 DAK->(RecLock("DAK", .F.))
                 DAK->DAK_PESO := _nSomaPesoDAK
                 DAK->(MSUnLock())
              EndIf

              U_CargaRatVlrs(DAK->DAK_COD)//FUNÇÃO DO OM200FIM.PRW para refazer o Reteio do FRETE 1o PERCURSO e PEDAGIO no DAI / FRETE 2o PERCURSO NÃO é RATEIO É SOMATORIA DOS ITENS DA CARGA (PEDIDOS)

              DAI->(DBSetOrder(1)) // Seto de novo por causa das funções de rateios que troca a ordem
              If DAI->(DBSeek(DAK->(DAK_FILIAL+DAK_COD+DAK_SEQCAR)))
                 While !DAI->(Eof()) .And. DAI->(DAI_FILIAL+DAI_COD) == DAK->(DAK_FILIAL+DAK_COD)
                    If !Empty(DAI->DAI_NFISCA)
                       
                       If SF2->(MsSeek(DAI->DAI_FILIAL+DAI->DAI_NFISCA+DAI->DAI_SERIE))
                          U_NotaRatVlrs( DAI->DAI_I_FRET , DAK->DAK_PESO ) //FUNÇÃO DO M460FIM.PRW para refazer o Reteio do FRETE 1O PERCURSO
   
                                     //_lGrava,_lCalcSeguro, _nPesoTotC,_nPesoSoPallet , _nTotPedagio,_nVlrCHEPTot ,_nVlrFretOL,_nPesTotOL
                          U_GrvRatVlrs( .T.   , .F.        )//FUNÇÃO DO M460FIM para refazer o Reteio do FRETE 2o PERCURSO e PEDAGIO no SF2 e SD2
                       EndIf
                    EndIf
                    DAI->(DBSkip())
                 EndDo
              EndIf
              _nConta++

          End Sequence
       End Transaction
     Else
        U_ITMsg("Não foi possível encontrar a carga: " + _cCarga + " na tabela DAK para efetuar a alteração do peso bruto.",;
                   "ERRO",;
                   "Favor contactar a TI informando o problema.", 1)
     EndIf
 Next I

 U_ITMsg("ToTal de cargas Acertadas: " + AllTrim(Str(_nConta) )+ " .","CONCLUIDO COM SUCESSO",, 2)

 FwRestArea(_aArea)
 FwRestArea(_aAreaSD2)

Return

/*
===============================================================================================================================
Programa----------: MOMS010P
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 09/12/2010
Descrição---------: Funcao utilizada para verificar se um determinado pedido de venda eh somente produtos do tipo unitizadores (pallet)
Parametros--------: _cPedido
Retorno-----------: _lRet := .T. - Pedido somente de Pallet
===============================================================================================================================
*/
Static Function MOMS010P(_cPedido As Character) As Logical
 Local _cQuery    := "" As Character
 Local _cAliasSC6 := GetNextAlias() As Character
 Local nCountRec  := 0 As Numeric
 Local _lRet      := .F. As Logical
 Local _cGrpUnit  :=GetMV( "IT_GRPUNIT",,"0813") As Character

 _cQuery := "SELECT COUNT(C6_PRODUTO) AS QTD "
 //_cQuery += " SubStr(C6_PRODUTO,1,4) GRUPOPROD "
 _cQuery += " FROM " + RetSqlName("SC6") + " C6 "
 _cQuery += " JOIN " + RetSqlName("SB1") + " SB1 ON C6.C6_PRODUTO = SB1.B1_COD AND SB1.D_E_L_E_T_ = ' ' "
 _cQuery += " WHERE C6.D_E_L_E_T_ = ' '"
 _cQuery += " AND C6_FILIAL = '" + xFilial("SC6") + "'"
 //_cQuery+=" AND SubStr(C6_PRODUTO,1,4) <> '0813'"
 _cQuery += " AND	SB1.B1_GRUPO NOT IN "+ FormatIn( _cGrpUnit , ";" )  //EXCLUI GRUPOS UNITIZADORES
 _cQuery += " AND C6_NUM = '" + _cPedido + "'"

 MPSysOpenQuery( _cQuery,_cAliasSC6)
 DBSelectArea(_cAliasSC6)
 nCountRec:=(_cAliasSC6)->QTD  //Contabiliza o numero de registros encontrados pela query

 (_cAliasSC6)->( DBCloseArea() )
 If nCountRec = 0
    _lRet := .T.
 EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MOMS10Rateio
Autor-------------: Alex Wallauer
Data da Criacao---: 11/03/2025
Descrição---------: Refaz os rateios por peso bruto
Parametros--------: _cPedido
Retorno-----------: .T.
===============================================================================================================================
*/
//Static Function MOMS10Rateio(_cPedido As Character) As Logical
//Return .T.
