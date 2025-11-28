/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------

===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TOPCONN.CH"
#Include "TBICONN.CH"

/*
===============================================================================================================================
Programa----------: ROMS059
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 06/03/2020
===============================================================================================================================
Descrição---------: Relatório/schedule de Faturamento de Vendas - Chamado 32060
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS059()

    If	Select('SX3') == 0
        U_ITConOut("Inciando schedule de monitoramento dos pedidos de vendas")
        RPCSetType( 3 )						//Não consome licensa de uso
        RpcSetEnv('01','01',,,,GetEnvServer(),{ "SC5","SC6","SB1","SA1","SA3","SBM","ACY", "DAI"})
        sleep( 5000 )						//Aguarda 5 segundos para que as jobs IPC subam.
        ROMS059E() //Chamada para Pedidos Pendente - Produtos Resumidos
        ROMS059EI() //Chamda para Pedidos Faturados - Produtos Sintéticos
        RpcClearEnv()
    Else
        U_ITConOut("TESTE")
    EndIf

Return


/*
===============================================================================================================================
Programa----------: ROMS059E
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 06/03/2020
===============================================================================================================================
Descrição---------: Envio por e-mail do Pedidos Pendentes em pedidos de venda ROMS002 ORDEM produto - resumido
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS059E()
    Local _nX           := 0
    Local _nY           := 0
    Local _cQry         := ""
    Local aPedCood      := {}
    Local aPedGeren     := {}
    Local _cNomeArq     := ""
    Local _cDataHora    := ""
    Local _cTitulo      := "Pedidos Pendentes - Produto Resumido "
    Local _cDirExcel    := "\spool"
    Local _cEmailCoord  := ""
    Local _cEmailGer    := ""
    Local _cNomeGer     := ""
    Local _cNomeCoord   := ""

    Private aGeren      := {}


    //=============================================================================
    // Obtem Cabeçalho do Relatório
    //=============================================================================
    _aCabec := {} // Array com o cabeçalho das colunas do relatório.
    // Alinhamento( 1-Left,2-Center,3-Right )
    // Formatação( 1-General,2-Number,3-Monetário,4-DateTime )
    //                  Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
    aAdd(_aCabec,{"Cod"			          ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Filial"	              ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Cod Coord"             ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Nome"                  ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Produto"	              ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Descricao"	          ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Quantidade"	          ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Prc Unitario"	      ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Preco Net"	          ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Un. M"	              ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Qtd Ven 2 UM"	      ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Seg. UM"	              ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Armazem"	              ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Qtd.Entregue"	      ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Qtd. Pendente"	      ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Valor Total"           ,1           ,1         ,.F.})

    //=============================================================================
    // Obtem dados dos coordenadores e gerentes para envio dos e-mails.
    //=============================================================================
    _cQry := "SELECT A3_COD, A3_GEREN, A3_EMAIL, A3_NOME FROM " + RETSQLNAME("SA3") + " SA3 "
    _cQry += " WHERE SA3.D_E_L_E_T_ = ' ' AND A3_I_TIPV = 'C' AND A3_MSBLQL = '2' " // A3_I_TIPV // V=VENDEDOR;C=COORDENADOR;G=GERENTE;S=SUPERVISOR
    _cQry += " ORDER BY A3_GEREN, A3_COD "

    If Select("TRBSA3") > 0
        TRBSA3->(DBCloseArea())
    EndIf

    TCQUERY _cQry NEW ALIAS "TRBSA3"

    _cQry := "SELECT DISTINCT(A3_GEREN) FROM " + RETSQLNAME("SA3") + " SA3"
    _cQry += " WHERE SA3.D_E_L_E_T_ = ' ' AND A3_I_TIPV = 'C' AND A3_MSBLQL = '2' "
    _cQry += " ORDER BY A3_GEREN"

    TCQUERY _cQry NEW ALIAS "TRBSA32"

    While TRBSA32->(!Eof())
        aAdd(aGeren, TRBSA32->A3_GEREN)
        TRBSA32->(DBSkip())
    EndDo
    //=================================================================
    // Gera os dados do relatório e preenche aPedCood
    //=================================================================
    For _nX := 1 to Len(aGeren)
        aPedGeren := {}
        While TRBSA3->(!Eof()) .And. TRBSA3->A3_GEREN == aGeren[_nX]
            aPedCood := ROMS059Ger(TRBSA3->A3_COD)

            //ENVIO DO E-MAIL PARA OS COORDENADORES
            _cEmailCoord  := TRBSA3->A3_EMAIL
            _cNomeCoord   := TRBSA3->A3_NOME

            _cDataHora := "_Dt_" + StrZero(Day(Date()),2) + "_" + StrZero(Month(Date()),2) + "_" + StrZero(Year(Date()),4) + "_Hr_" + StrTran(Time(),":","_")
            _cNomeArq := "Relatorio_Pedidos_Pendentes_" + TRBSA3->A3_COD + _cDataHora + ".xls"
            If aPedCood <> Nil .And. Len(aPedCood) > 0
                If _cEmailCoord <> " "
                    U_ITGEREXCEL(_cNomeArq,_cDirExcel,_cTitulo,"Produto Resumido",_aCabec,aPedCood,.F.,,,.T.)
                    //Verifica se o arquivo foi gerado corretamente
                    If File(_cDirExcel+"\"+_cNomeArq) .And. ROMS059P(_cDirExcel+"\"+_cNomeArq)
                        U_ItConOut("[ROMS059] - Arquivo: " + _cDirExcel + "\" + _cNomeArq + ", gerado com sucesso!" )
                        ROMS059R(TRBSA3->A3_COD,_cNomeCoord, _cEmailCoord, _cDirExcel+"\"+_cNomeArq, .T.)//Envio de e-mail
                    Else
                        U_ItConOut("[ROMS059] - Falha na Geração do Arquivo: " + _cDirExcel + "\" + _cNomeArq + "." )
                    EndIf
                    //===========================================================================
                    // Exclui relatório Excel após envio de e-mail.
                    //===========================================================================
                    If File(_cDirExcel+"\"+_cNomeArq)
                        FErase(_cDirExcel+"\"+_cNomeArq)
                    EndIf
                EndIf
                For _nY := 1 TO Len(aPedCood)
                    aAdd(aPedGeren, aPedCood[_nY])
                Next

            EndIf
            TRBSA3->(DBSkip())
        EndDo
        //ENVIO DO E-MAIL PARA O GERENTE
        _cEmailGer    := Posicione("SA3",1,xFilial("SA3")+TRBSA3->A3_GEREN,"A3_EMAIL")
        _cNomeGer     := Posicione("SA3",1,xFilial("SA3")+TRBSA3->A3_GEREN,"A3_NOME")

        _cDataHora := "_Dt_" + StrZero(Day(Date()),2) + "_" + StrZero(Month(Date()),2) + "_" + StrZero(Year(Date()),4) + "_Hr_" + StrTran(Time(),":","_")
        _cNomeArq := "Relatorio_Pedidos_Pendentes__" + TRBSA3->A3_GEREN + _cDataHora + ".xls"
        If aPedGeren <> Nil .And. Len(aPedGeren) > 0
            If _cEmailGer <> " "
                U_ITGEREXCEL(_cNomeArq,_cDirExcel,_cTitulo,"Produto Resumido",_aCabec,aPedGeren,.F.,,,.T.)
                //Verifica se o arquivo foi gerado corretamente
                If File(_cDirExcel+"\"+_cNomeArq) .And. ROMS059P(_cDirExcel+"\"+_cNomeArq)
                    U_ItConOut("[ROMS059] - Arquivo: " + _cDirExcel + "\" + _cNomeArq + ", gerado com sucesso!" )

                    ROMS059R(TRBSA3->A3_GEREN,_cNomeGer, _cEmailGer, _cDirExcel+"\"+_cNomeArq, .T.)//Envio de e-mail
                Else
                    U_ItConOut("[ROMS059] - Falha na Geração do Arquivo: " + _cDirExcel + "\" + _cNomeArq + "." )
                EndIf
                //===========================================================================
                // Exclui relatório Excel após envio de e-mail.
                //===========================================================================
                If File(_cDirExcel+"\"+_cNomeArq)
                    FErase(_cDirExcel+"\"+_cNomeArq)
                EndIf
            EndIf
        EndIf
    Next
    TRBSA3->(DBCloseArea())
    TRBSA32->(DBCloseArea())
Return


/*
===============================================================================================================================
Programa----------: ROMS059Ger
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 06/03/2020
===============================================================================================================================
Descrição---------: Executa relatório - Pedidos Pendente -- sintético -- produtos resumido
===============================================================================================================================
Parametros--------: _Coordenador = Código do coordenador
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS059Ger(_Coordenador)
    Local aPedCoord     := {}
    Local _nQtdDias     := U_ITGETMV("IT_QTDDIAS",30)

    Private cFiltro     := "%"
    Private cFilBloqueio:= "%"

    //Filtra Emissao da SC5
    cFiltro += " AND SC5.C5_EMISSAO BETWEEN '" + DToS(DATE()-_nQtdDias) + "' AND '" + DToS(DATE()) + "'"
    cFiltro += " AND SC5.C5_VEND2 = '"+ _Coordenador +"'"
    cFiltro += "%"

    cFilBloqueio += "%"

    BeginSql alias "QRY6"
   		SELECT 		    
			SUM(SC6.C6_QTDVEN) AS C6_QTDVEN,
			AVG(SC6.C6_PRCVEN) AS C6_PRCVEN,
			SUM(SC6.C6_UNSVEN) AS C6_UNSVEN,
			SUM(SC6.C6_QTDENT) AS C6_QTDENT,
			SUM(SC6.C6_VALOR) AS C6_VALOR,
			SUM((SC6.C6_QTDVEN - SC6.C6_QTDENT)*SC6.C6_PRCVEN) AS VLRPENDEN,
			(Round(avg(SC6.C6_PRCVEN - ((SC6.C6_PRCVEN*SC6.C6_I_PDESC)/100)),4)) AS C6_PRCNET,
			SC6.C6_LOCAL, SC6.C6_UM,SC6.C6_SEGUM,	SC6.C6_PRODUTO,SB1.B1_I_DESCD,SC6.C6_FILIAL,SC6.C6_I_DQESP,SB1.B1_COD, SC6.C6_NUM 
		FROM 
			%Table:SC5% SC5
			JOIN %Table:SC6% SC6 ON SC6.C6_NUM = SC5.C5_NUM  AND SC6.C6_FILIAL = SC5.C5_FILIAL
            %exp:cFilBloqueio%	 							
			JOIN %Table:SA1% SA1 ON SC5.C5_CLIENT = SA1.A1_COD AND SC5.C5_LOJAENT = SA1.A1_LOJA
			JOIN %Table:SB1% SB1 ON SC6.C6_PRODUTO = SB1.B1_COD 
			JOIN %Table:SA3% SA3 ON SC5.C5_VEND1 = SA3.A3_COD
			JOIN %Table:SBM% SBM ON SB1.B1_GRUPO = SBM.BM_GRUPO
			JOIN %Table:ACY% ACY ON SA1.A1_GRPVEN = ACY.ACY_GRPVEN				
		WHERE 
			SC5.%notDel%  
			AND SC6.%notDel%  
			AND SA1.%notDel%  		
			AND SB1.%notDel%  					
			AND SA3.%notDel%  											
			AND SBM.%notDel%				
			AND ACY.%notDel%			
			AND SC6.C6_QTDVEN <> SC6.C6_QTDENT
			AND SC6.C6_BLQ <> 'R'
		    %exp:cFiltro%
		GROUP BY 		 		    
			SC6.C6_LOCAL, SC6.C6_UM,SC6.C6_SEGUM,	SC6.C6_PRODUTO,SB1.B1_I_DESCD,SC6.C6_FILIAL,SC6.C6_I_DQESP,SB1.B1_COD, SC6.C6_NUM 
		ORDER BY 
			SC6.C6_FILIAL,SB1.B1_COD,SB1.B1_I_DESCD
    EndSql

    While QRY6->(!Eof()) .And. BusCoord(QRY6->C6_FILIAL,QRY6->C6_NUM) == _Coordenador
        aAdd(aPedCoord,{QRY6->C6_FILIAL,;                                   //"Cod "
        FWFilialName(,QRY6->C6_FILIAL),;                                    //"Filial "
        _Coordenador,;                                                      //"Cod. Coordernador"
        Posicione("SA3",1, xFilial("SA3")+_Coordenador,"A3_NOME"),;         //"Nome do coordenador"
        QRY6->C6_PRODUTO,;                                                  //"Produto "
        QRY6->B1_I_DESCD,;                                                  //"Descição"
        QRY6->C6_QTDVEN,;                                                   //"Quantidade"
        QRY6->C6_PRCVEN,;                                                   //"Prc Unitario"
        QRY6->C6_PRCNET,;                                                   //"Preco Net"
        QRY6->C6_UM,;                                                       //"Un. M"
        QRY6->C6_UNSVEN,;                                                   //"Qtd Ven 2 UM"
        QRY6->C6_SEGUM,;                                                    //"Seg. UM"
        QRY6->C6_LOCAL,;                                                    //"Armazen"
        QRY6->C6_QTDENT,;                                                   //"Qtd.Entregue"
        (QRY6->C6_QTDVEN - QRY6->C6_QTDENT),;                               //"Qtd. Pendente"
        QRY6->VLRPENDEN;                                                    //"Valor Total"
        })
        QRY6->(DBSkip())
    EndDo

    If Select("QRY6") > 0
        QRY6->( DBCloseArea() )
    EndIf

Return aPedCoord

/*
===============================================================================================================================
Programa----------: BusCoord
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 06/03/2020
===============================================================================================================================
Descrição---------: Busca coordenador com base no pedido de venda
===============================================================================================================================
Parametros--------: _cFil: Filial de busca
                    _cPedVen: Pedido de venda
===============================================================================================================================
Retorno-----------: _cRet: Codigo do coordenador
===============================================================================================================================
*/
Static Function BusCoord(_cFil,_cPedVen)
    Local _cRet := ""
    If SC5->(DBSeek(_cFil+_cPedVen))
        _cRet := SC5->C5_VEND2
    EndIf
Return _cRet


/*
===============================================================================================================================
Programa----------: ROMS059P
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 09/03/2020
===============================================================================================================================
Descrição---------: Realiza uma pausa e tenta abrir o arquivo passado por parâmetro para ver se já está disponível 
                    para ser enviado por e-mail.
===============================================================================================================================
Parametros--------: _cArqRelat = Arquivo de relatório a ser testado.
===============================================================================================================================
Retorno-----------: _lRet = .T. - arquivo aberto com sucesso.
                            .F. - não conseguiu abrir o arquivo.
===============================================================================================================================
*/

Static Function ROMS059P(_cArqRelat)
    Local _lRet     := .F.
    Local _nHandle
    Local _nTempo   := 0 , _nTempoTot := 30000

    Begin Sequence
        While _nTempo <= _nTempoTot
            // Abre o arquivon
            _nHandle := FT_FUse(_cArqRelat)

            If _nHandle <> -1
                _lRet := .T.
                Break
            EndIf

            _nTempo += 1000
            Sleep(1000)  // Faz uma pausa de 1 segundo.
        EndDo

    End Sequence

// Fecha o Arquivo
    FT_FUSE()

Return _lRet

/*
===============================================================================================================================
Programa----------: ROMS059R
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 09/03/2020
===============================================================================================================================
Descrição---------: Rotina de envio de e-mail para coordenador e gerente, com relatório em Excel anexo.
===============================================================================================================================
Parametros--------: _cCod   = Codigo do Coordenador / Gerente
                    _cNome  = Nome do Coordenador / Gerente
                    _cEmail = E-mail Coordenador / Gerente
                    _cArqEnv= Diretório + Nome do arquivo a ser enviado.
                    lRelat  = Indica se será e-mail para Pedidos pendentes ou Pedidos faturados.
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

Static Function ROMS059R(_cCod,_cNome, _cEmail,_cArqEnv, lRelat)
    Local _aConfig	:= U_ITCFGEML('') // Configurações do servidor de envio de e-mail.
    Local _cEmlLog  := ""
    Local _cDesc    := ""
    Local _cMsgEml  := ""
    Local _cAssunto := ""
    Local _nQtdDias := U_ITGETMV("IT_QTDDIAS",30)
    Local cDataI    := StrZero(Day(Date()),2) + "/" + StrZero(Month(Date()),2) + "/" + StrZero(Year(Date()),4)
    Local cDataF    := StrZero(Day(Date()-_nQtdDias),2) + "/" + StrZero(Month(Date()-_nQtdDias),2) + "/" + StrZero(Year(Date()-_nQtdDias),4)

    If lRelat
        _cDesc := " Relatório de Pedidos Pendentes - Produto Resumido "
    Else
        _cDesc := " Relatório de Pedidos Faturados - Produto Sintético "
    EndIf

    If lRelat
        _cAssunto :="Relatório de Pedidos Pendentes - Produto Resumido "
    Else
        _cAssunto :="Relatório de Pedidos Faturados - Produto Sintético "

    EndIf

    If !lRelat
        cDataF    := StrZero(Day(Date()-7),2) + "/" + StrZero(Month(Date()-7),2) + "/" + StrZero(Year(Date()-7),4)
    EndIf


    _cMsgEml := '<html>'
    _cMsgEml += '<head><title>'+_cAssunto+'</title></head>'
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
    _cMsgEml += '	     <td class="titulos"><center>'+_cAssunto+'</center></td>'
    _cMsgEml += '	 </tr>'
    _cMsgEml += '</table>'
    _cMsgEml += '<br>'
    _cMsgEml += '<table class="bordasimples" width="600">'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td align="center" colspan="2" class="grupos">Dados do documento</b></td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Responsável: </b></td>'
    _cMsgEml += '      <td class="itens" >'+ _cCod +" - "+ _cNome +'</td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Descrição: </b></td>'
    _cMsgEml += '      <td class="itens" >'+ _cDesc +'</td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Período:</b></td>'
    _cMsgEml += '      <td class="itens" >'+ cDataF + " - " + cDataI +'</td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '</table>'
    _cMsgEml += '</center>'
    _cMsgEml += '<br>'
    _cMsgEml += '<br>'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
    _cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [ROMS059]</td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '</body>'
    _cMsgEml += '</html>'

    U_ITENVMAIL( "workflow@italac.com.br", _cEmail,,, _cAssunto+cDataI, _cMsgEml     , _cArqEnv, _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

    _cEmlLog := Upper(_cEmlLog)

    If !Empty( _cEmlLog ) .And. "SUCESSO" $ _cEmlLog
        If lRelat
            U_ItConOut("[ROMS059] - Envio de e-mail Relatório Pedidos Pendentes - Produto resumido realizado com sucesso.")
        Else
            U_ItConOut("[ROMS059] - Envio de e-mail Relatório Pedidos faturados - Produto sintético realizado com sucesso.")
        EndIf
        U_ItConOut(_cEmlLog)
    Else
        If lRelat
            U_ItConOut("[ROMS059] - Falha no envio de e-mail Relatório Pedidos Pendentes - Produto resumido.")
        Else
            U_ItConOut("[ROMS059] - Falha no envio de e-mail Relatório Pedidos faturados - Produto resumido.")
        EndIf
        U_ItConOut("[ROMS059] - " + _cAssunto+cDataI )
        U_ItConOut(_cEmlLog)
    EndIf

Return


/*
===============================================================================================================================
Programa----------: ROMS059EI
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 06/03/2020
===============================================================================================================================
Descrição---------: Envio por e-mail do Pedidos Faturados ROMS003 ORDEM produto - sintético
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS059EI()
    Local _nX           := 0
    Local _nY           := 0
    Local _cQry         := ""
    Local aPedCood      := {}
    Local aPedGeren     := {}
    Local _cNomeArq     := ""
    Local _cDataHora    := ""
    Local _cTitulo      := "Pedidos Faturados - Produto Sintético "
    Local _cDirExcel    := "\spool"
    Local _cEmailCoord  := ""
    Local _cEmailGer    := ""
    Local _cNomeGer     := ""
    Local _cNomeCoord   := ""

    Private aGeren      := {}


    //=============================================================================
    // Obtem Cabeçalho do Relatório
    //=============================================================================
    _aCabec := {} // Array com o cabeçalho das colunas do relatório.
    // Alinhamento( 1-Left,2-Center,3-Right )
    // Formatação( 1-General,2-Number,3-Monetário,4-DateTime )
    //                  Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
    aAdd(_aCabec,{"Filial"	              ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Nome Filial"           ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Cod Coordenador"       ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Nome Coordenador"      ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Produto"	              ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Descricao Produto"	  ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Quantidade"	          ,1           ,1         ,.F.})
    aAdd(_aCabec,{"1a U.M."	              ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Qtde 2a U.M."	      ,1           ,1         ,.F.})
    aAdd(_aCabec,{"2a U.M."	              ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Vlr.Unit"	          ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Vlr.Total"	          ,1           ,1         ,.F.})
    aAdd(_aCabec,{"Vlr.Bruto"	          ,1           ,1         ,.F.})

    //=============================================================================
    // Obtem dados dos coordenadores e gerentes para envio dos e-mails.
    //=============================================================================
    _cQry := "SELECT A3_COD, A3_GEREN, A3_EMAIL, A3_NOME FROM " + RETSQLNAME("SA3") + " SA3 "
    _cQry += " WHERE SA3.D_E_L_E_T_ = ' ' AND A3_I_TIPV = 'C' AND A3_MSBLQL = '2' " // A3_I_TIPV // V=VENDEDOR;C=COORDENADOR;G=GERENTE;S=SUPERVISOR
    _cQry += " ORDER BY A3_GEREN, A3_COD "

    If Select("TRBSA3") > 0
        TRBSA3->(DBCloseArea())
    EndIf

    TCQUERY _cQry NEW ALIAS "TRBSA3"

    _cQry := "SELECT DISTINCT(A3_GEREN) FROM " + RETSQLNAME("SA3") + " SA3"
    _cQry += " WHERE SA3.D_E_L_E_T_ = ' ' AND A3_I_TIPV = 'C' AND A3_MSBLQL = '2' "
    _cQry += " ORDER BY A3_GEREN"

    TCQUERY _cQry NEW ALIAS "TRBSA32"

    While TRBSA32->(!Eof())
        aAdd(aGeren, TRBSA32->A3_GEREN)
        TRBSA32->(DBSkip())
    EndDo
    //=================================================================
    // Gera os dados do relatório e preenche aPedCood
    //=================================================================
    For _nX := 1 to Len(aGeren)
        aPedGeren := {}
        While TRBSA3->(!Eof()) .And. TRBSA3->A3_GEREN == aGeren[_nX]
            aPedCood := ROMS059G(TRBSA3->A3_COD)

            //ENVIO DO E-MAIL PARA OS COORDENADORES
            _cEmailCoord  := TRBSA3->A3_EMAIL
            _cNomeCoord   := TRBSA3->A3_NOME

            _cDataHora := "_Dt_" + StrZero(Day(Date()),2) + "_" + StrZero(Month(Date()),2) + "_" + StrZero(Year(Date()),4) + "_Hr_" + StrTran(Time(),":","_")
            _cNomeArq := "Relatorio_Pedidos_Faturados_" + TRBSA3->A3_COD + _cDataHora + ".xls"
            If aPedCood <> Nil .And. Len(aPedCood) > 0
                If _cEmailCoord <> " "
                    U_ITGEREXCEL(_cNomeArq,_cDirExcel,_cTitulo,"Produto Sintético",_aCabec,aPedCood,.F.,,,.T.)
                    //Verifica se o arquivo foi gerado corretamente
                    If File(_cDirExcel+"\"+_cNomeArq) .And. ROMS059P(_cDirExcel+"\"+_cNomeArq)
                        U_ItConOut("[ROMS059] - Arquivo: " + _cDirExcel + "\" + _cNomeArq + ", gerado com sucesso!" )
                        ROMS059R(TRBSA3->A3_COD,_cNomeCoord, _cEmailCoord, _cDirExcel+"\"+_cNomeArq, .F.)//Envio de e-mail
                    Else
                        U_ItConOut("[ROMS059] - Falha na Geração do Arquivo: " + _cDirExcel + "\" + _cNomeArq + "." )
                    EndIf
                    //===========================================================================
                    // Exclui relatório Excel após envio de e-mail.
                    //===========================================================================
                    If File(_cDirExcel+"\"+_cNomeArq)
                        FErase(_cDirExcel+"\"+_cNomeArq)
                    EndIf
                EndIf
                For _nY := 1 TO Len(aPedCood)
                    aAdd(aPedGeren, aPedCood[_nY])
                Next

            EndIf
            TRBSA3->(DBSkip())
        EndDo
        //ENVIO DO E-MAIL PARA O GERENTE
        _cEmailGer    := Posicione("SA3",1,xFilial("SA3")+TRBSA3->A3_GEREN,"A3_EMAIL")
        _cNomeGer     := Posicione("SA3",1,xFilial("SA3")+TRBSA3->A3_GEREN,"A3_NOME")

        _cDataHora := "_Dt_" + StrZero(Day(Date()),2) + "_" + StrZero(Month(Date()),2) + "_" + StrZero(Year(Date()),4) + "_Hr_" + StrTran(Time(),":","_")
        _cNomeArq := "Relatorio_Pedidos_Faturados_" + TRBSA3->A3_GEREN + _cDataHora + ".xls"
        If aPedGeren <> Nil .And. Len(aPedGeren) > 0
            If _cEmailGer <> " "
                U_ITGEREXCEL(_cNomeArq,_cDirExcel,_cTitulo,"Produto Resumido",_aCabec,aPedGeren,.F.,,,.T.)
                //Verifica se o arquivo foi gerado corretamente
                If File(_cDirExcel+"\"+_cNomeArq) .And. ROMS059P(_cDirExcel+"\"+_cNomeArq)
                    U_ItConOut("[ROMS059] - Arquivo: " + _cDirExcel + "\" + _cNomeArq + ", gerado com sucesso!" )

                    ROMS059R(TRBSA3->A3_GEREN,_cNomeGer, _cEmailGer, _cDirExcel+"\"+_cNomeArq, .F.)//Envio de e-mail
                Else
                    U_ItConOut("[ROMS059] - Falha na Geração do Arquivo: " + _cDirExcel + "\" + _cNomeArq + "." )
                EndIf
                //===========================================================================
                // Exclui relatório Excel após envio de e-mail.
                //===========================================================================
                If File(_cDirExcel+"\"+_cNomeArq)
                    FErase(_cDirExcel+"\"+_cNomeArq)
                EndIf
            EndIf
        EndIf
    Next
    TRBSA3->(DBCloseArea())
    TRBSA32->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa----------: ROMS059G
Autor-------------: Jonathan Everton Torioni de Oliveira
Data da Criacao---: 09/03/2020
===============================================================================================================================
Descrição---------: Executa relatório - Pedidos Faturados -- sintético -- Produto Sintético
===============================================================================================================================
Parametros--------: _Coordenador = Código do coordenador
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ROMS059G(_Coordenador)
    Local oAlias    := GetNextAlias()
    Local aPedCoord := {}
    Local _dQtdDias := Date() - 7 //Números de dias cravados por segrança pois o volume de dados é muito alto para o processamento.
    Local nQtde1    := 0
    Local nQtde2    := 0
    Local nTotal    := 0
    Local nVlBru    := 0
    Local _cFil     := ""

    Private _cFiltro:= "%"


    _cFiltro += " AND SD2.D2_EMISSAO BETWEEN '" + DToS(_dQtdDias) + "' AND '" + DToS(date()) + "'"
    //_cFiltro += " AND SD2.D2_EMISSAO BETWEEN '" + "20200101" + "' AND '" + "20200101" + "'"  //Para testes dinâmicos

    _cFiltro += " AND SF2.F2_VEND2 = '" +_Coordenador+ "'"

    _cFiltro += "%"

    BeginSql alias oAlias
	  	 SELECT 			
			SUM(SD2.D2_QUANT)AS D2_QUANT,
			AVG(SD2.D2_PRCVEN) AS D2_PRCVEN,
			SUM(SD2.D2_TOTAL) AS D2_TOTAL,				
			SUM(SD2.D2_VALBRUT) AS D2_VALBRUT,								
			SUM(SD2.D2_QTSEGUM) AS D2_QTSEGUM,
			SUM(((SD2.D2_COMIS1+SD2.D2_COMIS2+SD2.D2_COMIS3)/100)*SD2.D2_TOTAL) AS D2_COMIS1,
			SUM(SD2.D2_I_FRET) AS D2_I_FRET,
			SUM(SD2.D2_CUSTO1) AS D2_CUSTO1,
			SUM(SD2.D2_QTDEDEV) AS D2_QTDEDEV,
			SUM(SD2.D2_VALDEV) AS D2_VALDEV,				
			SUM(SD2.D2_ICMSRET) AS D2_ICMSRET,	  		
			SD2.D2_UM,SD2.D2_SEGUM,SB1.B1_I_DESCD,SB1.B1_COD,SD2.D2_FILIAL, D2_PEDIDO
		 FROM 
			%Table:SF2% SF2
			JOIN %Table:SD2% SD2 ON SD2.D2_DOC = SF2.F2_DOC AND SD2.D2_SERIE = SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL 
			JOIN %Table:SA1% SA1 ON SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA = SA1.A1_LOJA
			JOIN %Table:SB1% SB1 ON SD2.D2_COD = SB1.B1_COD 
			JOIN %Table:SA3% SA3 ON SF2.F2_VEND1 = SA3.A3_COD
			JOIN %Table:SBM% SBM ON SB1.B1_GRUPO = SBM.BM_GRUPO
			JOIN %Table:ACY% ACY ON SA1.A1_GRPVEN = ACY.ACY_GRPVEN
			JOIN %Table:SF4% SF4 ON sd2.d2_filial = SF4.f4_filial AND sd2.d2_tes = SF4.f4_codigo
			LEFT JOIN %Table:DAI% DAI ON DAI.DAI_FILIAL = SF2.F2_FILIAL AND DAI.DAI_PEDIDO = SF2.F2_I_PEDID AND DAI.DAI_NFISCA = SF2.F2_DOC AND DAI.DAI_SERIE = SF2.F2_SERIE   
		 WHERE 
			SF2.%notDel%  
			AND SD2.%notDel%  
			AND SA1.%notDel%  		
			AND SB1.%notDel%  					
			AND SA3.%notDel%  											
			AND SBM.%notDel%				
			AND ACY.%notDel%
			AND SF4.%notDel%
		   	%exp:_cFiltro%
		 GROUP BY 
 			SD2.D2_UM,SD2.D2_SEGUM,SB1.B1_I_DESCD,SB1.B1_COD,SD2.D2_FILIAL,D2_PEDIDO
		 ORDER BY 
			SD2.D2_FILIAL,SB1.B1_COD
    EndSql

    If (oAlias)->D2_FILIAL = " "
        (oAlias)->(DBCloseArea())
        Return
    EndIf

    While (oAlias)->(!Eof()) .And. BusCoord((oAlias)->D2_FILIAL,(oAlias)->D2_PEDIDO) == _Coordenador

        _cFil  := (oAlias)->D2_FILIAL
        nQtde1 := (oAlias)->D2_QUANT-ROMS059Q3((oAlias)->D2_UM,(oAlias)->D2_SEGUM,(oAlias)->B1_COD,(oAlias)->D2_FILIAL,'D2_QTDEDEV') //Considera abatimentos de devoluções
        nQtde2 := ((oAlias)->D2_QTSEGUM,(oAlias)->D2_QTSEGUM - ROMS059Q3((oAlias)->D2_UM,(oAlias)->D2_SEGUM,(oAlias)->B1_COD,(oAlias)->D2_FILIAL,'D2_QTSEGUM')) //Considera abatimentos de devoluções
        nTotal := ((oAlias)->D2_TOTAL,(oAlias)->D2_TOTAL-ROMS059QG((oAlias)->D2_UM,(oAlias)->D2_SEGUM,(oAlias)->B1_COD,(oAlias)->D2_FILIAL,.F.)) //Considera abatimentos de devoluções
        nVlBru := ((oAlias)->D2_VALBRUT,(oAlias)->D2_VALBRUT-ROMS059QG((oAlias)->D2_UM,(oAlias)->D2_SEGUM,(oAlias)->B1_COD,(oAlias)->D2_FILIAL,.T.))  //Considera abatimentos de devoluções

        If (nPos:=aScan(aPedCoord, {|x| x[1] == (oAlias)->D2_FILIAL .And. x[5] == (oAlias)->B1_COD}))== 0
            aAdd(aPedCoord,{(oAlias)->D2_FILIAL,;                       //"Cod "
            FWFilialName(,(oAlias)->D2_FILIAL),;                        //"Filial "
            _Coordenador,;                                              //Cod. Coordernador
            Posicione("SA3",1, xFilial("SA3")+_Coordenador,"A3_NOME"),; //Nome do vendedor
            (oAlias)->B1_COD,;                                          //"Produto "
            (oAlias)->B1_I_DESCD,;                                      //"Descição produto"
            nQtde1,;                                                    //"Quantidade"
            (oAlias)->D2_UM,;                                           //"Primeira unidade de Medida "
            nQtde2,;                                                    //"Quantidade na segunda unidade de Medida"
            (oAlias)->D2_SEGUM,;                                        //"Segunda unidade de Medida "
            nTotal / nQtde1,;                                           //"Valor Unitario "
            nTotal,;                                                    //"Valor Total"
            nVlBru;                                                     //Valor Bruto
            })
        Else
            aPedCoord[nPos][7] += nQtde1
            aPedCoord[nPos][9] += nQtde2
            aPedCoord[nPos][12] += nTotal
            aPedCoord[nPos][13] += nVlBru
        EndIf
        (oAlias)->(DBSkip())
    EndDo

    If Select(oAlias) > 0
        (oAlias)->( DBCloseArea() )
    EndIf

Return aPedCoord

/*
===============================================================================================================================
Programa--------: ROMS059Q3
Autor-----------: Jonathan Everton Torioni de Oliveira
Data da Criacao-: 09/03/2020
===============================================================================================================================
Descrição-------: Funcao usada para verificar e retornar a quantidade de devoluções
===============================================================================================================================
Parametros------: _cUm			- Primeira unidade de medida
----------------: _cSegUm		- Segunda unidade de medida
----------------: _cCod			- Código do Produto
----------------: _cFil			- Filial do documento
----------------: _cCampo		- Campo da tabela
===============================================================================================================================
Retorno---------: _nRet			- Quantidade das devoluções
===============================================================================================================================
*/
Static Function ROMS059Q3( _cUm , _cSegUm , _cCod , _cFil , _cCampo )

    Local _nRet			:= 0
    Local _cFilLocal	:= "%"

//Filtro do agrupamento da linha do report
    _cFilLocal += " AND SD2.D2_UM     = '"+ _cUm    +"' "
    _cFilLocal += " AND SD2.D2_SEGUM  = '"+ _cSegUm +"' "
    _cFilLocal += " AND SB1.B1_COD    = '"+ _cCod   +"' "
    _cFilLocal += " AND SD2.D2_FILIAL = '"+ _cFil   +"' "
    _cFilLocal += "%"

    _nRet := ROMS059Y( _cFilLocal , _cCampo , .F. )

Return( _nRet )

/*
===============================================================================================================================
Programa--------: ROMS059QG
Autor-----------: Jonathan Everton Torioni de Oliveira
Data da Criacao-: 09/03/2020
===============================================================================================================================
Descrição-------: Funcao usada para verificar e retornar o valor de devoluções
===============================================================================================================================
Parametros------: _cUm			- Primeira unidade de medida
----------------: _cSegUm		- Segunda unidade de medida
----------------: _cCod			- Código do Produto
----------------: _cFil			- Filial do documento
----------------: _lValBrut		- Flag de Valor Bruto
===============================================================================================================================
Retorno---------: _nRet			- Quantidade das devoluções
===============================================================================================================================
*/

Static Function ROMS059QG(_cUm, _cSegUm, _cCod, _cFil, _lValBrut)

    Local _nRet := 0
    Local _cFilLocal := "%"

//Filtro do agrupamento da linha do report
    _cFilLocal += " AND SD2.D2_UM = '"     + _cUm    + "' "
    _cFilLocal += " AND SD2.D2_SEGUM = '"  + _cSegUm + "' "
    _cFilLocal += " AND SB1.B1_COD = '"    + _cCod   + "' "
    _cFilLocal += " AND SD2.D2_FILIAL = '" + _cFil   + "' "

    _cFilLocal += "%"
    _nRet := ROMS059Y(_cFilLocal,"D2_VALDEV",_lValBrut)

Return _nRet

/*
===============================================================================================================================
Programa--------: ROMS059Y
Autor-----------: Jonathan Everton Torioni de Oliveira
Data da Criacao-: 09/03/2020
===============================================================================================================================
Descrição-------: Funcao usada para verificar e retornar o valor de devoluções
===============================================================================================================================
Parametros------: _cFil			- Filial do documento
----------------: _cCampo		- Campo do Formulário
----------------: _lValBrut		- Flag de Valor Bruto
===============================================================================================================================
Retorno---------: _nRet			- Quantidade das devoluções
===============================================================================================================================
*/

Static Function ROMS059Y( _cFilLocal , _cCampo , _lValBrut )

    Local _nRet     := 0
    Local _aDadosDev:= {}//Array que armazenara os dados da devolucao

    If Select("QRYTMP") > 0
        QRYTMP->( DBCloseArea() )
    EndIf

//Executa a mesma query principal, com as colunas numdoc e serie para filtrar as devolucoes contidas no grupo
    BeginSql alias "QRYTMP"
	SELECT 			
	    SF2.F2_DOC,SF2.F2_SERIE,SD2.D2_VALDEV,SD2.D2_QTDEDEV,SD2.D2_FILIAL,SD2.D2_ICMSRET,SD2.D2_TOTAL,SD2.D2_QTSEGUM,SD2.D2_QUANT,SD2.D2_COD
	FROM 
		%Table:SF2% SF2
		JOIN %Table:SD2% SD2 ON SD2.D2_DOC = SF2.F2_DOC AND SD2.D2_SERIE = SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL 
		JOIN %Table:SA1% SA1 ON SD2.D2_CLIENTE = SA1.A1_COD AND SD2.D2_LOJA = SA1.A1_LOJA
		JOIN %Table:SB1% SB1 ON SD2.D2_COD = SB1.B1_COD 
		JOIN %Table:SA3% SA3 ON SF2.F2_VEND1 = SA3.A3_COD
		JOIN %Table:SBM% SBM ON SB1.B1_GRUPO = SBM.BM_GRUPO
		JOIN %Table:ACY% ACY ON SA1.A1_GRPVEN = ACY.ACY_GRPVEN 
		JOIN %Table:SF4% SF4 ON sd2.d2_filial = SF4.f4_filial AND sd2.d2_tes = SF4.f4_codigo
	WHERE 
		SF2.%notDel%  
		AND SD2.%notDel%  
		AND SA1.%notDel%  		
		AND SB1.%notDel%  					
		AND SA3.%notDel%  											
    	%exp:_cFilLocal%
		AND SBM.%notDel%				
		AND ACY.%notDel%		
		AND SF4.%notDel%
    	%exp:_cFiltro%    	
    EndSql

    DBSelectArea("QRYTMP")
    QRYTMP->(DBGoTop())
    While QRYTMP->(!Eof())

        //Chama funcao filDev que retorna os dados da devolucao das notas fiscais de saida, caso estas possuam devolucao
        _aDadosDev:= ROMS059I(QRYTMP->F2_DOC,QRYTMP->F2_SERIE,QRYTMP->D2_FILIAL,QRYTMP->D2_COD)

        //Se existe uma devolucao e ela se enquadra nos filtros dispostos na funcao fildev
        If _aDadosDev[1,1]

            If 	_cCampo == "D2_VALDEV" .And. _lValBrut

                //D1_TOTAL + D1_ICMSRET
                _nRet += _aDadosDev[1,3] + _aDadosDev[1,4]

            ElseIf _cCampo == "D2_VALDEV" .And. !_lValBrut

                //D1_TOTAL
                _nRet += _aDadosDev[1,3]

            ElseIf _cCampo == 'D2_QTDEDEV'

                //D1_QUANT
                _nRet += _aDadosDev[1,2]

            ElseIf _cCampo == 'D2_QTSEGUM'

                //D1_QTSEGUM
                _nRet += _aDadosDev[1,5]

            EndIf

        EndIf

        QRYTMP->(DBSkip())
    EndDo

    DBSelectArea("QRYTMP")
    QRYTMP->(DBCloseArea())

Return _nRet

/*
===============================================================================================================================
Programa--------: ROMS059I
Autor-----------: Jonathan Everton Torioni de Oliveira
Data da Criacao-: 09/03/2020
===============================================================================================================================
Descrição-------: Funcao usada para verificar e retornar dados de devoluções
===============================================================================================================================
Parametros------: _cDoc			- Documento fiscal de saída
----------------: _cSerie		- Série do documento
----------------: _nValDev		- Valor da devolução
----------------: _cFil			- Filial do documento
----------------: _cProduto		- Código do produto
===============================================================================================================================
Retorno---------: _aDadosDev	- Dados das devoluções
===============================================================================================================================
*/

Static Function ROMS059I( _cDoc , _cSerie , _cFil , _cProduto )

    Local _lRet 		:= .F.
    Local _cQuant1		:= 0
    Local _cTotal		:= 0
    Local _cICMSRet		:= 0
    Local _cQuant2		:= 0
    Local _aAreaSF1 	:= SF1->(getArea())
    Local _aAreaSD1 	:= SD1->(getArea())
    Local _cQuery		:= " "
    Local _cDocEnt		:= " "
    Local _cSerieEnt	:= " "
    Local _aDadosDev	:= {}
    Local _cFornece     := " "
    Local _cLoja        := " "
    Local _cTipo        := "D"

    _cQuery := " SELECT "
    _cQuery += "     D1_DOC,"
    _cQuery += "     D1_SERIE,"
    _cQuery += "     D1_FORNECE,"
    _cQuery += "     D1_LOJA,"
    _cQuery += "     D1_TIPO,"
    _cQuery += "     SUM(D1_QUANT)   AS D1_QUANT,"
    _cQuery += "     SUM(D1_TOTAL)   AS D1_TOTAL,"
    _cQuery += "     SUM(D1_ICMSRET) AS D1_ICMSRET,"
    _cQuery += "     SUM(D1_QTSEGUM) AS D1_QTSEGUM "
    _cQuery += " FROM  "+ RetSqlName("SD1") +" SD1 "
    _cQuery += " WHERE "+ RetSqlDel('SD1')
    _cQuery += " AND   D1_NFORI   = '"+ _cDoc     +"' "
    _cQuery += " AND   D1_SERIORI = '"+ _cSerie   +"' "
    _cQuery += " AND   D1_FILIAL  = '"+ _cFil     +"' "
    _cQuery += " AND   D1_COD     = '"+ _cProduto +"' "
    _cQuery += " AND   D1_TIPO    = 'D' "
    _cQuery += " GROUP BY D1_DOC , D1_SERIE, D1_FORNECE,   D1_LOJA, D1_TIPO   "

    If Select("TRB") > 0
        TRB->( DBCloseArea() )
    EndIf

    DBUseArea( .T. , "TOPCONN" , TCGenQry(,, _cQuery ) , 'TRB' , .F. , .T. )

    DBSelectArea("TRB")
    TRB->( DBGoTop() )
    While TRB->( !Eof() )

        _cDocEnt	:= TRB->D1_DOC
        _cSerieEnt	:= TRB->D1_SERIE
        _cFornece 	:= TRB->D1_FORNECE
        _cLoja      := TRB->D1_LOJA
        _cTipo      := TRB->D1_TIPO

        _lRet		:= .T.

        //Posicione SF1
        DBSelectArea("SF1")
        SF1->( DBSetOrder(1) )
        If SF1->( DBSeek( _cFil + _cDocEnt + _cSerieEnt + _cFornece + _cLoja + _cTipo ) )

            If _lRet
                _cQuant1	+= TRB->D1_QUANT
                _cTotal		+= TRB->D1_TOTAL
                _cICMSRet	+= TRB->D1_ICMSRET
                _cQuant2	+= TRB->D1_QTSEGUM
            EndIf

        EndIf

        TRB->( DBSkip() )
    EndDo

    TRB->( DBCloseArea() )

    If _cQuant1 > 0
        _lRet := .T.
    Else
        _lRet := .F.
    EndIf

    //Restaura ambiente
    FWRestArea( _aAreaSF1 )
    FWRestArea( _aAreaSD1 )

    //Adiciona os dados devolvios ao array
    aAdd( _aDadosDev , { _lRet , _cQuant1 , _cTotal , _cICMSRet , _cQuant2 } )

Return( _aDadosDev )
