/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
Alex Wallauer |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RCOM019
Autor-------------: Jonathan Torioni
Data da Criacao---: 19/06/2020
Descrição---------: Romaneio Pedido de compra X NFs
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM019()
    Private nHandle       := 0
    Private cNomArq       := "RCOM019D"+DToS(Date())+"N000"
    Private cExt          := ".XML"
    Private oBj           := Nil

    Private cCab        := "\data\italac\RCOM019\RCOM019_CAB.txt"
    Private cRodp       := "\data\italac\RCOM019\RCOM019_RODP.txt"
    Private cPedido     := SC7->C7_NUM
    Private aArq        := {}
    Private cPathSrv    := GetTempPath()

    If !File(cCab)
        U_ITMsg("Layout XML não encontrado","Falha", "Entre em contato com a equipe de TI.",1)
        Return
    EndIf

    //===============================================
    // Montagem do corpo do XML
    //===============================================
    FWMsgRun(,{|oBj|  ROMS019B(oBj) },'Aguarde processamento...','Carregando dados...')

Return

/*
===============================================================================================================================
Programa----------: RCOM019B
Autor-------------: Jonathan Torioni
Data da Criacao---: 19/06/2020
Descrição---------: Monta o corpo do XML no array aArq
Parametros--------: Obj - Processamento visual
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ROMS019B(Obj)
    Local cQuery        := ""
    Local cNwAlias      := GetNextAlias()
    Local cConsumo      := 's86'
    Local cServ         := 's87'
    Local cManut        := 's87'
    Local cInvest       := 's87'
    Local cStlyP        := 's95'
    Local cOBS          := ""
    Local cCodP         := ""
    Local cNfs          := ""
    Local nX            := 0
    Local nI            := 0
    Local nZ            := 0
    Local nSaldo        := 0
    Local nQuant        := 0
    Local aSaldo        := {}
    Local aProds        := {}
    Local cProdA        := ""
    Local cResid        := ""

    FT_FUSE(cCab)
    nTotal := FT_FLASTREC()
    FT_FGOTOP()
    //===============================================
    // Gravo todas as linhas do arquivo no aArq
    //===============================================
    While !FT_FEOF() 
        aAdd(aArq, FT_FREADLN())
        FT_FSKIP()
    EndDo
    FT_FUSE()

    Obj:cCaption := ("Gerando arquivo...")
    ProcessMessages()

    cQuery += " SELECT                                           "
    cQuery += " C7.C7_NUM,                                       "
    cQuery += " C7.C7_RESIDUO,                                   "
    cQuery += " D1.D1_PEDIDO,                                    "
    cQuery += " D1.D1_COD,                                       "
    cQuery += " B1.B1_I_DESCD,                                   "
    cQuery += " B1.B1_DESC,                                      "
    cQuery += " B1.B1_FILIAL,                                    "
    cQuery += " B1.B1_LOCPAD,                                    "
    cQuery += " C7.C7_UM,                                        "
    cQuery += " C7.C7_QUANT,                                     "
    cQuery += " D1.D1_QUANT,                                     "
    cQuery += " D1.D1_ITEMPC,                                    "
    cQuery += " C7.C7_ITEM,                                      "
    cQuery += " D1.D1_DOC,                                       "
    cQuery += " D1.D1_SERIE,                                     "
    cQuery += " D1.D1_DTDIGIT,                                   "
    cQuery += " BZ.BZ_I_LOCAL,                                   "
    cQuery += " C7.C7_OBS,                                       "
    cQuery += " C7.C7_LOCAL,                                     "
    cQuery += " C7.C7_I_APLIC                                    "
    cQuery += " FROM                                             "
    cQuery += " " + RetSqlName("SD1") + " D1,                    "
    cQuery += " " + RetSqlName("SC7") + " C7,                    "
    cQuery += " " + RetSqlName("SB1") + " B1,                    "
    cQuery += " " + RetSqlName("SBZ") + " BZ                     "
    cQuery += " WHERE                                            "
    cQuery += " D1.D_E_L_E_T_ = ' '                              "
    cQuery += " AND D1.D1_FILIAL = '" + cFilAnt + "'             "
    cQuery += " AND D1.D1_PEDIDO = '" + cPedido + "'             "
    cQuery += " AND C7.C7_NUM = D1.D1_PEDIDO                     "
    cQuery += " AND C7.C7_ITEM = D1.D1_ITEMPC                    "
    cQuery += " AND C7.C7_FILIAL = D1.D1_FILIAL                  "
    cQuery += " AND C7.D_E_L_E_T_ = ' '                          "
    cQuery += " AND C7.C7_PRODUTO = D1.D1_COD                    "
    cQuery += " AND B1.D_E_L_E_T_ = ' '                          "
    cQuery += " AND B1.B1_COD = D1.D1_COD                        "
    cQuery += " AND BZ.D_E_L_E_T_ = ' '                          "
    cQuery += " AND BZ.BZ_FILIAL = D1.D1_FILIAL                  "
    cQuery += " AND BZ.BZ_COD = D1.D1_COD                        "
    cQuery := ChangeQuery(cQuery)

    MPSysOpenQuery(cQuery,cNwAlias)

    If (cNwAlias)->(Eof())
        U_ITMsg("Pedido não possui notas vinculadas!", "Falha",,1)
        Return 
    EndIf
    //===========================================================
    // Montagem do Corpor do XML
    //===========================================================
    Do Case
        Case (cNwAlias)->C7_I_APLIC == 'C'
            cConsumo      := cStlyP
            cServ         := 's87'
            cManut        := 's87'
            cInvest       := 's87' 
        Case (cNwAlias)->C7_I_APLIC == 'M'
            cConsumo      := 's86'
            cServ         := 's87'
            cManut        := cStlyP
            cInvest       := 's87' 
        Case (cNwAlias)->C7_I_APLIC == 'I'
            cConsumo      := 's86'
            cServ         := 's87'
            cManut        := 's87'
            cInvest       := cStlyP  
        Case (cNwAlias)->C7_I_APLIC == 'S'
            cConsumo      := 's86'
            cServ         := cStlyP
            cManut        := 's87'
            cInvest       := 's87' 
    EndCase 

    cOBS := (cNwAlias)->C7_OBS

    aAdd(aArq, '<Row ss:AutoFitHeight="0" ss:Height="15">' )
    aAdd(aArq, '    <Cell ss:MergeAcross="8" ss:StyleID="s66"><Data ss:Type="String">ROMANEIO DE LANCAMENTO DE NOTA FISCAL</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="s68"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s69"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s69"/>' )
    aAdd(aArq, '   </Row>' )
    aAdd(aArq, '   <Row ss:AutoFitHeight="0" ss:Height="15.75">' )
    aAdd(aArq, '    <Cell ss:StyleID="s68"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s68"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s68"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s68"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s68"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s68"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s68"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s68"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s70"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s70"/>' )
    aAdd(aArq, '   </Row>' )
    aAdd(aArq, '   <Row ss:AutoFitHeight="0" ss:Height="15.45" ss:StyleID="s71">' )
    aAdd(aArq, '    <Cell ss:Index="3" ss:MergeAcross="1" ss:StyleID="m406893492"><Data' )
    aAdd(aArq, '      ss:Type="String">PEDIDO DE COMPRA </Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="s78"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s78"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s78"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s78"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s79"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s79"/>' )
    aAdd(aArq, '   </Row>' )
    aAdd(aArq, '   <Row ss:AutoFitHeight="0" ss:Height="18">' )
    aAdd(aArq, '    <Cell ss:Index="3" ss:MergeAcross="1" ss:StyleID="m406893512"><Data' )
    aAdd(aArq, '      ss:Type="String">'+cPedido+'</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="s68"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s68"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s68"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s68"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s70"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s70"/>' )
    aAdd(aArq, '   </Row>' )
    aAdd(aArq, '   <Row ss:AutoFitHeight="0" ss:Height="15.45" ss:StyleID="s71">' )
    aAdd(aArq, '    <Cell ss:Index="3" ss:StyleID="s80"><Data ss:Type="String">CONSUMO</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="'+cConsumo+'"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s78"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s78"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s78"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s78"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s79"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s79"/>' )
    aAdd(aArq, '   </Row>' )
    aAdd(aArq, '   <Row ss:AutoFitHeight="0" ss:Height="15.45" ss:StyleID="s71">' )
    aAdd(aArq, '    <Cell ss:Index="3" ss:StyleID="s80"><Data ss:Type="String">SERVICO</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="'+cServ+'"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s88"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s88"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s88"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s88"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s79"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s79"/>' )
    aAdd(aArq, '   </Row>' )
    aAdd(aArq, '   <Row ss:AutoFitHeight="0" ss:Height="15.45" ss:StyleID="s71">' )
    aAdd(aArq, '    <Cell ss:Index="3" ss:StyleID="s80"><Data ss:Type="String">MANUTENCAO</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="'+cManut+'"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s88"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s88"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s88"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s88"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s79"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s79"/>' )
    aAdd(aArq, '   </Row>' )
    aAdd(aArq, '   <Row ss:AutoFitHeight="0" ss:Height="15.45" ss:StyleID="s71">' )
    aAdd(aArq, '    <Cell ss:Index="3" ss:StyleID="s80"><Data ss:Type="String">INVESTIMENTO</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="'+cInvest+'"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s88"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s88"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s88"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s88"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s79"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s79"/>' )
    aAdd(aArq, '   </Row>' )
    aAdd(aArq, '   <Row ss:AutoFitHeight="0" ss:Height="18" ss:StyleID="s70">' )
    aAdd(aArq, '    <Cell ss:StyleID="s89"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s89"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s89"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s89"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s89"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s89"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s89"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s89"/>' )
    aAdd(aArq, '   </Row>' )
    aAdd(aArq, '   <Row ss:AutoFitHeight="0" ss:Height="15.45" ss:StyleID="s71">' )
    aAdd(aArq, '    <Cell ss:StyleID="s90"><Data ss:Type="String">CODIGO</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="s90"><Data ss:Type="String">DESC DETALH.</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="s90"><Data ss:Type="String">DESCRICAO</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="s90"><Data ss:Type="String">U.M.</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="s90"><Data ss:Type="String">QUANT PC</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="s90"><Data ss:Type="String">QUANT NF</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="s90"><Data ss:Type="String">ENDERECO</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="s90"><Data ss:Type="String">ESTOQUE</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="s90"><Data ss:Type="String">RESID</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="s79"/>' )
    aAdd(aArq, '   </Row>' )

    While (cNwAlias)->(!Eof())
        Obj:cCaption := ("Gerando arquivo...")
        ProcessMessages()
        aAdd(aProds, {;
            (cNwAlias)->D1_COD,;
            (cNwAlias)->D1_ITEMPC,;
            (cNwAlias)->C7_ITEM,;
            (cNwAlias)->D1_DOC,;
            (cNwAlias)->D1_SERIE,;
            (cNwAlias)->D1_DTDIGIT,;
            (cNwAlias)->D1_QUANT})
        (cNwAlias)->(DBSkip())
    EndDo

    (cNwAlias)->(DBGoTop())

    While (cNwAlias)->(!Eof())

        If (cNwAlias)->D1_COD == cProdA
            (cNwAlias)->(DBSkip())
            Loop
        EndIf

        Obj:cCaption := ("Gerando arquivo...")
        ProcessMessages()
        nX++
        cCodP := (cNwAlias)->D1_COD

        aSaldo := CalcEst(cCodP,(cNwAlias)->C7_LOCAL,DATE()+1, cFilAnt)
        nSaldo := aSaldo[1]

        For nI := 1 TO Len(aProds)
            If aProds[nI][1] == (cNwAlias)->D1_COD .And. aProds[nI][2] == (cNwAlias)->C7_ITEM
                cNfs += aProds[nI][4] +"/"+aProds[nI][5] + " - " +  StrZero(Day(SToD(aProds[nI][6])),2)+"/"+StrZero(Month(SToD(aProds[nI][6])),2)+"/"+SubStr(Str(Year(SToD(aProds[nI][6])),4),3,2) + "; "
                nQuant += aProds[nI][7]
                cResid := IIf(!Empty((cNwAlias)->C7_RESIDUO), "SIM","NAO" )
            EndIf
        Next nI

        (cNwAlias)->(DBGoTo(nX))

        aAdd(aArq, '<Row ss:AutoFitHeight="0">' )
        aAdd(aArq, '    <Cell ss:StyleID="s91"><Data ss:Type="String">'+(cNwAlias)->D1_COD+'</Data></Cell>' )
        aAdd(aArq, '    <Cell ss:StyleID="s91"><Data ss:Type="String">'+(cNwAlias)->B1_I_DESCD+'</Data></Cell>' )
        aAdd(aArq, '    <Cell ss:StyleID="s91"><Data ss:Type="String">'+(cNwAlias)->B1_DESC+'</Data></Cell>' )
        aAdd(aArq, '    <Cell ss:StyleID="s91"><Data ss:Type="String">'+(cNwAlias)->C7_UM+'</Data></Cell>' )
        aAdd(aArq, '    <Cell ss:StyleID="s93"><Data ss:Type="Number">'+cValToChar((cNwAlias)->C7_QUANT)+'</Data></Cell>' )
        aAdd(aArq, '    <Cell ss:StyleID="s93"><Data ss:Type="Number">'+cValToChar(nQuant)+'</Data></Cell>' )
        aAdd(aArq, '    <Cell ss:StyleID="s91"><Data ss:Type="String">'+(cNwAlias)->BZ_I_LOCAL+'</Data></Cell>' )
        aAdd(aArq, '    <Cell ss:StyleID="s93"><Data ss:Type="Number">'+cValToChar(nSaldo)+'</Data></Cell>' )
        aAdd(aArq, '    <Cell ss:StyleID="s94"><Data ss:Type="String">'+cResid+'</Data></Cell>' )
        aAdd(aArq, '    <Cell ss:StyleID="s70"/>' )
        aAdd(aArq, '   </Row>' )
        aAdd(aArq, '   <Row ss:AutoFitHeight="0">' )
        aAdd(aArq, '    <Cell ss:MergeAcross="8" ss:StyleID="m406893532"><Data ss:Type="String">'+cNfs+'</Data></Cell>' )
        aAdd(aArq, '    <Cell ss:StyleID="s70"/>' )
        aAdd(aArq, '   </Row>' )

        cNfs := ""
        cResid:= ""
        nQuant := 0
        cProdA := (cNwAlias)->D1_COD
        (cNwAlias)->(DBSkip())
    EndDo
    aAdd(aArq, ' <Row ss:AutoFitHeight="0" ss:Height="15" ss:StyleID="s70">' )
    aAdd(aArq, '    <Cell ss:StyleID="s102"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s102"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s102"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s102"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s102"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s102"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s102"/>' )
    aAdd(aArq, '    <Cell ss:StyleID="s102"/>' )
    aAdd(aArq, '   </Row>' )
    aAdd(aArq, '   <Row ss:AutoFitHeight="0" ss:Height="15.75" ss:StyleID="s70">' )
    aAdd(aArq, '    <Cell ss:MergeAcross="8" ss:StyleID="s104"><Data ss:Type="String">OBSERVACAO</Data></Cell>' )
    aAdd(aArq, '   </Row>' )
    aAdd(aArq, '   <Row ss:AutoFitHeight="0">' )
    aAdd(aArq, '    <Cell ss:MergeAcross="8" ss:MergeDown="4" ss:StyleID="m406893572"><Data' )
    aAdd(aArq, '      ss:Type="String">'+cOBS+'</Data></Cell>' )
    aAdd(aArq, '    <Cell ss:StyleID="s70"/>' )
    aAdd(aArq, '   </Row>' )
    aAdd(aArq, '   <Row ss:AutoFitHeight="0">' )
    aAdd(aArq, '    <Cell ss:Index="10" ss:StyleID="s70"/>' )
    aAdd(aArq, '   </Row>' )
    aAdd(aArq, '   <Row ss:AutoFitHeight="0">' )
    aAdd(aArq, '    <Cell ss:Index="10" ss:StyleID="s70"/>' )
    aAdd(aArq, '   </Row>' )
    aAdd(aArq, '   <Row ss:AutoFitHeight="0">' )
    aAdd(aArq, '    <Cell ss:Index="10" ss:StyleID="s70"/>' )
    aAdd(aArq, '   </Row>' )
    aAdd(aArq, '   <Row ss:AutoFitHeight="0" ss:Height="15">' )
    aAdd(aArq, '    <Cell ss:Index="10" ss:StyleID="s70"/>' )
    aAdd(aArq, '   </Row>' )

    (cNwAlias)->(DBCloseArea())

    FT_FUSE(cRodp)
    nTotal := FT_FLASTREC()
    FT_FGOTOP()

    //===============================================
    // Grava todas as linhas do arquivo no aArq
    //===============================================
    While !FT_FEOF()
        Obj:cCaption := ("Gerando arquivo...")
        ProcessMessages()
        aAdd(aArq, FT_FREADLN())
        FT_FSKIP()
    EndDo
    FT_FUSE()

    //===============================================
    // Garava o arquivo
    //===============================================
    While File(cPathSrv+cNomArq+cExt)
        cNomArq := Soma1(cNomArq)
    EndDo
    
    nHandle := FCreate(cPathSrv+cNomArq+cExt)
    If nHandle = -1
        U_ITMsg("Nã foi possível gerar o arquivo "+cPathSrv+" "+cNomArq+cExt,"Falha","Entre em contato com a equipe de TI",1)
    Else
        For nZ := 1 TO Len(aArq)
            FWrite(nHandle, aArq[nZ] + CRLF)
        Next nZ
        FClose(nHandle)
        U_ITMsg("Arquvio "+cPathSrv+" "+cNomArq+cExt+" gerado com sucesso!","Processo concluído!",,2)
    EndIf

     //Tentando abrir o objeto
    nRet := shellExecute("Open", cNomArq+cExt, "", cPathSrv, 1 )
    //Se houver algum erro
    If nRet <= 32
        MsgStop("Não foi possível abrir o arquivo " +cDirP+" "+cNomeArqP+ "!", "Atenção")
    EndIf
Return
