/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |08/03/2024| Chamado 45006. Ajustar variável __cUserId em ambiente Scheduller p/ Protheus criar e preencher
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "report.ch"
#Include 'TOPCONN.CH'
#Include "TBICONN.CH"

/*
===============================================================================================================================
Programa----------: MOMS054
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/05/2020
Descrição---------: Relatorio de Monitoramento de Cargas. Chamado 32918.
Parametros--------: _cChamada  = "M" = Chamada do menu.
                                 "S" = Chamada do Scheduller.
                    _cQrySched = Query do Scheduller.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS054(_cChamada, _cQrySched)
Local _cPerg := "MOMS054"

Default _cChamada := "M"

Begin Sequence
   //==================================================================
   // Processamento via Scheduller
   //==================================================================
   If _cChamada == "S"
      U_MOMS054A(_cChamada, _cQrySched)
      Break  // Finaliza a rotina 
   EndIf 

   //==================================================================
   // Exibe tela de parâmetros inicias.
   //==================================================================
   If ! Pergunte(_cPerg , .T.)	
      Break 
   EndIf 
   
   Processa( {|| _lRet := U_MOMS054A() }, "Aguarde...", "Emitindo o Relatório...",.F.)
   

End Sequence 

Return

/*
===============================================================================================================================
Programa----------: MOMS054A
Autor-------------: Julio de Paula Paz
Data da Criacao---: 13/05/2020
Descrição---------: Gera os dados e emite o relatório.
Parametros--------: _cChamada  = "M" = Chamada do menu.
                                 "S" = Chamada do Scheduller.
                    _cQrySched = Query do Scheduller.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS054A(_cChamada, _cQrySched)
Local _cQry, _nI, _nJ  
Local _nValorCarga := U_ItGetMv("IT_VALCARKR",100000)  
Local _nTotRegs, _aRetKrona, _cPlacaVeic
Local _aCargalida
Local _cNrProtoc, _cNrCliente, _cStatus
Local _cNomeTrans, _aDadosRelat, _aTitulos
Local _cInicPrev, _cUserIncl, _cTipoRelatorio
Local _cRetTpPesq := "" // Tipo de Pesquisa e Chave Pesquisa
Local _cRetLink   := "" // Link
Local _cRetUsrPsw := "" // Usuário e Senha,
Local _cRetPesq   := "" // Retorno da Pesquisa
Local _cFilCarga

Private _cRetPkrona := "" // Retorno das Pesquisas no sistema Krona.

Default _cChamada := "M" // Chamada via menu

Begin Sequence
   //==================================================================
   // Filtra os dados da carga para emissão do relatório.
   //==================================================================
   If _cChamada == "S"
      _cQry := _cQrySched 
   Else 
      _cQry := " SELECT DAK.R_E_C_N_O_ NRRECDAK, DAI.R_E_C_N_O_ NRRECDAI, DAK_FILIAL CODFILIAL, DAK_COD CODCARGA FROM " + RetSqlName("DAK") + " DAK, " + RetSqlName("DAI") + " DAI "   
      _cQry += " WHERE DAK.D_E_L_E_T_ = ' ' AND DAI.D_E_L_E_T_ = ' ' " 
      _cQry += " AND DAI_FILIAL = DAK_FILIAL AND DAI_COD = DAK_COD "
      _cQry += " AND DAK_VALOR  >= " + StrZero(_nValorCarga,16,2) + " "
      _cQry += " AND DAK_I_PREC <> '1' "
    
      If ! Empty(MV_PAR01)
         _cQry += " AND DAK_FILIAL IN " + FormatIn(AllTrim(MV_PAR01),";") 
      EndIf 

      If ! Empty(MV_PAR02)
         _cQry += " AND DAK_DATA >= '" + DToS(MV_PAR02) + "' "
      EndIf 

      If ! Empty(MV_PAR03)
         _cQry += " AND DAK_DATA <= '" + DToS(MV_PAR03) + "' "
      EndIf 

      If ! Empty(MV_PAR04)
         _cQry += " AND DAK_VALOR >= " + StrZero(MV_PAR04,16,2) + " "
      EndIf 

      If ! Empty(MV_PAR05)
         _cQry += " AND DAK_VALOR <= " + StrZero(MV_PAR05,16,2) + " "
      EndIf 

      _cQry += " ORDER BY DAK_FILIAL, DAK_COD "

   EndIf 

   If Select("QRYDAK") > 0
      QRYDAK->(DBCloseArea())
   EndIf
           
   _cQry := ChangeQuery(_cQry) 
   DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry), "QRYDAK", .F., .T.)                              

   If _cChamada == "M" // Chamada via menu   
      Count To _nTotRegs

      If _nTotRegs == 0  
         Break 
      EndIf 

      ProcRegua(_nTotRegs)
   EndIf

   DA3->(DBSetOrder(1)) // DA3_FILIAL+DA3_COD
   DA4->(DBSetOrder(1)) // DA4_FILIAL+DA4_COD   
   SC5->(DBSetOrder(1)) // C5_FILIAL+C5_NUM 

   QRYDAK->(DBGoTop())
    
   _nI := 0 
   _aCargalida := {}
   _aDadosRelat := {}

   _cTransp    := ""
   _cLjTransp  := ""
   _cNomeTrans := ""
   _cFilCarga  := ""
   While ! QRYDAK->(Eof() )
      DAK->(DBGoTo(QRYDAK->NRRECDAK))

      If _cChamada == "M" // Chamada via menu
         DAI->(DBGoTo(QRYDAK->NRRECDAI))

         SC5->(DBSeek(DAI->DAI_FILIAL+DAI->DAI_PEDIDO))
      Else // Chamada via Scheduller
         SC5->(DBSeek(DAK->DAK_FILIAL+QRYDAK->F2_I_PEDID))
      EndIf 

      If _cChamada == "M" // Chamada via menu
         _nI += 1
         IncProc("Lendo dados da Carga: " + AllTrim(DAK->DAK_COD) + " - Item: " + StrZero(_nI,6) + "/" + StrZero(_nTotRegs,6))
      EndIf 

      If _cFilCarga <> QRYDAK->CODFILIAL + QRYDAK->CODCARGA
         _cFilCarga := QRYDAK->CODFILIAL + QRYDAK->CODCARGA
         _aRetKrona := {}
         
         _cRetPkrona := "" // Retorno das Pesquisas no sistema Krona. 

      EndIf

      _nJ := aScan(_aCargalida, {|x| x[1] = DAK->DAK_FILIAL .And. x[2] = DAK->DAK_COD})
      If _nJ == 0
         //================================================================
         // Obtendo Transportadora
         //================================================================ 
         _cCodMotor := DAK->DAK_MOTORI
      
         _cTransp    := ""
         _cLjTransp  := ""
         _cNomeTrans := ""
             
         If DA4->(DBSeek(xFilial("DA4")+_cCodMotor))
            _cTransp   := DA4->DA4_FORNECE
            _cLjTransp := DA4->DA4_LOJA   
            If ! Empty(_cTransp)
               _cNomeTrans := Posicione("SA2",1,xFilial("SA2")+_cTransp + _cLjTransp ,'A2_NOME')
            EndIf
         EndIf
   
         aAdd(_aCargalida, {DAK->DAK_FILIAL, DAK->DAK_COD})
        
         _cPlacaVeic := ""

         If DA3->(DBSeek(xFilial("DA3")+DAK->DAK_CAMINH))
            If DA3->DA3_I_TPVC $ "2/4" // 1=CARRETA;2=CAMINHAO;3=BI-TREM;4=UTILITARIO;5=RODOTREM
               _cPlacaVeic := DA3->DA3_PLACA 
            Else 
               _cPlacaVeic := DA3->DA3_I_PLCV
            EndIf 
            _cPlacaVeic := SubStr(_cPlacaVeic,1,3) + "-" + SubStr(_cPlacaVeic,4,4) 
         EndIf 
         
         _cRetPkrona := "" // Retorno das Pesquisas no sistema Krona. 

         If Empty(DAK->DAK_I_PROT) 
            If ! Empty(_cPlacaVeic)
               _aRetKrona := U_MOMS054P(_cPlacaVeic, "P")
            Else
               _aRetKrona := {}
            EndIf 
         Else
            _aRetKrona := U_MOMS054P(DAK->DAK_I_PROT, "V")  
         EndIf 
      EndIf 

      _cNrProtoc  := ""
      _cNrCliente := ""
      _cStatus    := ""
      _cUserIncl  := ""
      _cInicPrev  := "" 
      //---------------------//
      _cRetTpPesq := "" // Tipo de Pesquisa e Chave Pesquisa
      _cRetLink   := "" // Link
      _cRetUsrPsw := "" // Usuário e Senha,
      _cRetPesq   := "" // Retorno da Pesquisa

      //=============================================================================================
      // As query deste relatório podem repetir várias linhas para cada Filial + Carga.
      // Isso pode ocorrer porque podemos ter mais de um pedido de vendas por filial + carga,
      // ou mais de uma nota fiscal por filial + carga (um pedido de vendas por nota fiscal).
      // O array _aRetKrona é alimentado uma única vez para cada Filial + Carga.
      // Quando muda a Filial + Carga, o array _aRetKrona é zerado e iniciado novamente.
      //=============================================================================================
      If Len(_aRetKrona) > 0
         _cNrProtoc  := _aRetKrona[1]         
         _cNrCliente := _aRetKrona[2]
         _cStatus    := _aRetKrona[3]
         _cUserIncl  := _aRetKrona[4]
         _cInicPrev  := _aRetKrona[5]
         //----------------------------------------//
         _cRetTpPesq := _aRetKrona[6] // Tipo de Pesquisa e Chave Pesquisa
         _cRetLink   := _aRetKrona[7] // Link
         _cRetUsrPsw := _aRetKrona[8] // Usuário e Senha,
         _cRetPesq   := _aRetKrona[9] // Retorno da Pesquisa

      EndIf

      If _cChamada == "M" .And. MV_PAR06 == 1  // Sintetico
         If _nJ == 0
            aAdd(_aDadosRelat, {DAK->DAK_FILIAL,; // Filial
                                DAK->DAK_COD,;    // Cod.Carga
                                DAK->DAK_PESO,;   // Peso
                                DAK->DAK_VALOR,;  // Valor Carga
                                DAK->DAK_DATA,;   // Data Criação
                                DAK->DAK_HORA,;   // Hora Criação
                                _cNrProtoc,;      // Nr.Viagem/Protocolo 
                                _cTransp,;        // Código da Transportadora  
                                _cLjTransp,;      // Loja da Transportadora
                                _cNomeTrans,;     // Nome Transportadora
                                _cNrCliente,;     // Numero cliente Krona
                                _cPlacaVeic,;     // Placa Veiculo Pesquisa
                                _cUserIncl,;      // Usuario Inclusão Viagem
                                _cInicPrev,;      // Inicio Previsto  
                                _cStatus} )       // Status
         EndIf 
      Else // Analítico 
         aAdd(_aDadosRelat, {DAK->DAK_FILIAL,; // Filial
                             DAK->DAK_COD,;    // Cod.Carga
                             DAK->DAK_PESO,;   // Peso
                             DAK->DAK_VALOR,;  // Valor Carga
                             DAK->DAK_DATA,;   // Data Criação
                             DAK->DAK_HORA,;   // Hora Criação
                             DAI->DAI_PEDIDO,; // Pedido Venda
                             SC5->C5_CLIENT,;  // Cliente
                             SC5->C5_LOJACLI,; // Loja
                             SC5->C5_I_NOME,;  // Nome cliente
                             SC5->C5_I_DTENT,; // Data Entrega
                             If(SC5->C5_I_TRCNF=="S","Sim","Nao"),; // Pv Troca Nota     
                             _cNrProtoc,;      // Nr.Viagem/Protocolo 
                             _cTransp,;        // Código da Transportadora  
                             _cLjTransp,;      // Loja da Transportadora
                             _cNomeTrans,;     // Nome Transportadora
                             _cNrCliente,;     // Numero cliente Krona
                             _cPlacaVeic,;     // Placa Veiculo Pesquisa
                             _cUserIncl,;      // Usuario Inclusão Viagem
                             _cInicPrev,;      // Inicio Previsto  
                             _cStatus} )       // Status
      EndIf 

      //===================================================================================
      // Atualiza a Tabela DAK com o numero do protocolo localizado. 
      // Caso o campo protocolo esteja vazio.
      //===================================================================================
      If ! Empty(_cNrProtoc) .And. Empty(DAK->DAK_I_PROT) .And. ! (AllTrim(_cStatus) $ "FINALIZADA/ENCERRADA/FINAL/CANCELADA")
         DAK->(RecLock("DAK",.F.))
         DAK->DAK_I_PROT := _cNrProtoc 
         DAK->DAK_I_MSGK := "PROTOCOLO ATUALIZADO ATRAVES DO RELATORIO DE MONITORAMENTO DE CARGAS [MOMS054]."
         DAK->DAK_I_JSON := "PROTOCOLO ATUALIZADO ATRAVES DO RELATORIO DE MONITORAMENTO DE CARGAS [MOMS054]."+ CRLF +;
                            "USUARIO/INCLUSAO VIAGEM " + _cUserIncl + CRLF +;
                            "INICIO PREVISTO: " +  _cInicPrev + CRLF +;
                            "PROTOCOLO DA CARGA: ESTAVA VAZIO, AGORA O NUMERO É: "+ _cNrProtoc + CRLF + ;
                            "MOTORISTA: " + DAK->DAK_MOTORI + CRLF + ;
                            "VEICULO: " + DAK->DAK_CAMINH  + CRLF + ;
                            _cRetTpPesq  + CRLF + ;   // Tipo de Pesquisa e Chave Pesquisa
                            _cRetLink + CRLF + ;      // Link
                            _cRetUsrPsw + CRLF + ;    // Usuário e Senha,
                            _cRetPesq + CRLF          // Retorno da Pesquisa

         DAK->DAK_I_ENVK := "S"
         DAK->(MSUnLock())
      ElseIf ! Empty(DAK->DAK_I_PROT) .And. AllTrim(_cStatus) = "CANCELADA"
         DAK->(RecLock("DAK",.F.))
         DAK->DAK_I_MSGK := "PROTOCOLO ATUALIZADO ATRAVES DO RELATORIO DE MONITORAMENTO DE CARGAS [MOMS054]. VIAGEM CANCELADA. PROTOCOLO REMOVIDO: " + DAK->DAK_I_PROT
         DAK->DAK_I_JSON := "PROTOCOLO ATUALIZADO ATRAVES DO RELATORIO DE MONITORAMENTO DE CARGAS [MOMS054]." + CRLF +;
                            "USUARIO/INCLUSAO VIAGEM " + _cUserIncl + CRLF +;
                            "INICIO PREVISTO: " + _cInicPrev + CRLF +;
                            "VIAGEM CANCELADA. PROTOCOLO REMOVIDO: " + DAK->DAK_I_PROT + CRLF + ;
                            "MOTORISTA: " + DAK->DAK_MOTORI + CRLF + ;
                            "VEICULO: " + DAK->DAK_CAMINH  + CRLF + ;
                            _cRetTpPesq  + CRLF + ;   // Tipo de Pesquisa e Chave Pesquisa
                            _cRetLink + CRLF + ;      // Link
                            _cRetUsrPsw + CRLF + ;    // Usuário e Senha,
                            _cRetPesq + CRLF          // Retorno da Pesquisa

         DAK->DAK_I_ENVK := "S"
         DAK->DAK_I_PROT := ""
         DAK->(MSUnLock())
//-----------------------------------//
      Else
         DAK->(RecLock("DAK",.F.))
         DAK->DAK_I_MSGK := "RELATORIO E ROTINA DE MONITORAMENTO DE CARGAS [MOMS054]. SEM ATUALIZAÇÃO DA CARGA. SIMPLES GRAVAÇÃO DA PESQUISA REALIZADA NO SISTEMA KRONA."
         DAK->DAK_I_JSON := "RELATORIO E ROTINA DE MONITORAMENTO DE CARGAS [MOMS054]. SEM ATUALIZAÇÃO DA CARGA. SIMPLES GRAVAÇÃO DA PESQUISA REALIZADA NO SISTEMA KRONA." + CRLF +;
                            _cRetPkrona + CRLF          // Retorno da Pesquisa
         DAK->(MSUnLock())

//-----------------------------------//
   
      EndIf 

      QRYDAK->(DBSkip())
   EndDo

   If _cChamada == "S" // Chamada via Scheduller
      Break 
   EndIf 

   If MV_PAR06 == 1  // Sintetico
      _aTitulos := {"Filial", "Cod.Carga", "Peso", "Valor Carga", "Data Criação", "Hora Criação",;
                    "Nr.Viagem/Protocolo", "Código Transportadora","Loja Transportadora",;
                    "Nome Transportadora", "Numero cliente",;
                    "Placa Veiculo Pesquisa", "Usuario Inclusão Viagem", "Inicio Previsto","Status"} 
   Else // Analítico
      _aTitulos := {"Filial", "Cod.Carga", "Peso", "Valor Carga", "Data Criação", "Hora Criação",;
                    "Pedido Venda", "Cliente", "Loja Cliente", "Nome cliente", "Data Entrega",;
                    "Pv Troca Nota","Nr.Viagem/Protocolo", "Código Transportadora","Loja Transportadora",;
                    "Nome Transportadora", "Numero cliente",;
                    "Placa Veiculo Pesquisa", "Usuario Inclusão Viagem", "Inicio Previsto","Status"}
   EndIf 

   If MV_PAR06 == 1
      _cTipoRelatorio := "Sintetico"
   Else 
      _cTipoRelatorio := "Analitico" 
   EndIf 

   U_ITListBox( 'Relatorio de Monitoramento de Cargas - ' + _cTipoRelatorio,  _aTitulos , _aDadosRelat , .T. ,1)

End Sequence

If Select("QRYDAK") > 0
   QRYDAK->(DBCloseArea())
EndIf

If _cChamada == "M" // Chamada via menu
   U_ITMsg("Rotina de emissão do relatório finalizada.","Atenção",,1)
Else
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS05401"/*cMsgId*/,"MOMS05401 - Rotina de emissão do relatório finalizada."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf 

Return 

/*
===============================================================================================================================
Função-------------: MOMS054P
Autor--------------: Julio de Paula Paz
Data da Criacao----: 10/01/2020
Descrição----------: Pesquisa e retorna o status da viagem integrada para o Sistema Krona, por placa de veículo.
Parametros---------: _cChavePesq = Chave de Pesquisa 
                     _cTipoPesq  = "P" = Placa do veículo                   
                                   "V" = Numero Viagem/Protocolo
Retorno------------: _aRet = Retorna vazio ou   { numero de protocolo/viagem Krona,         // 1     
                                                  Numero Cliente/Filial+Codigo Carga,       // 2 
                                                  Status,                                   // 3
                                                  Operacao / Usuário que incluiu a viagem,  // 4
                                                  Inicio Previsto = Data e Hora,            // 5
                                                  Tipo de Pesquisa e Chave Pesquisa,        // 6
                                                  Link,                                     // 7
                                                  Usuário e Senha,                          // 8
                                                  Retorno da Pesquisa }                     // 9                       
===============================================================================================================================
*/  
User Function MOMS054P(_cChavePesq,_cTipoPesq)  
Local _aRet := {}
Local _nI
Local _oRetJSon, _cMsgErro 
Local _cEmpWebService   := U_ItGetMv("ITEMPWEBKRO","000002")  
Local _cDirJSon, _cPesqViagem
Local _cLoginStatus
Local _cUsuario, _cSenha
Local _cLinha

Local _NrViagem    //      "numero_viagem":"3637591",
Local _NrCliente   //      "numero_cliente":"01151381",
Local _NrPamcary   //      "numero_pamcary":"0",
Local _Status      //      "status":"AGENDADA",
Local _operacao    //      "operacao":"ITALAC.TRANS LAG (LAGOINHA)"
Local _EveDataH    //      "evento_datahora":null,
Local _EveTipo     //      "evento_tipo":null,
Local _Referencia  //      "referencia":null,
Local _Latitude    //      "latitude":null,
Local _Longitude   //      "longitude":null,
Local _Distancia   //      "distancia":null,
Local _Direcao     //      "direcao":null,
Local _InicPrev    //      "inicio_previsto":"31\/08\/2019 00:00:00",
Local _InicReal    //      "inicio_real":"",
Local _ChegDest    //      "chegada_destino_datahora":"",
Local _SaidaDest   //      "saida_destino_datahora":"",
Local _tempoEntr   //      "tempo_entrega":"",
Local _FimPrev     //      "fim_previsto":"31\/08\/2019 08:00:00",
Local _FimReal     //      "fim_real":"",
Local _TempoTot    //      "tempo_total":"", 
Local _NomeDest    //      "destinos":["nome":"ITALAC - PASSO FUNDO\/RS - PASSO FUNDO\/RS",
Local _TempCheSaid //      "tempo_chegada_saida_destino":null,
Local _ordem       //      "ordem":"1"

Local _cRetTpPesq := "" // Tipo de Pesquisa e Chave Pesquisa
Local _cRetLink   := "" // Link
Local _cRetUsrPsw := "" // Usuário e Senha,
Local _cRetPesq   := "" // Retorno da Pesquisa

Private _cIdPesquisa   

Default _cTipoPesq := "P", _lExibeTela := .T. 

Begin Sequence        
   
   If Type("_cUsrMaster") == "U" .Or. Empty(_cUsrMaster)
      _cUsrMaster    := U_ItGetMv("ITUSRMASTKR","ITALAC.INTEGRACAO")  // Usuário Master da Integração com o Sistema Krona
      _cSenhaMaster  := U_ItGetMv("ITPSWMASTKR","123456")             // Senha do usuário master da integração com o sistem krona.
   EndIf
                        
   _cLinkWS := ""
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(xFilial("ZFM")+_cEmpWebService))
      _cDirJSon := ZFM->ZFM_LOCXML 
      _cLinkWS  := ZFM->ZFM_LINK02
   Else
      FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS05402"/*cMsgId*/,"MOMS05402 - Empresa WebService para envio dos dados não localizada."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      Break
   EndIf
   
   //=======================================================
   // Para pesquisa, o usuário e senha sempre são a Master.
   //=======================================================
   _cUsuario := _cUsrMaster 
   _cSenha   := _cSenhaMaster

   If Empty(_cDirJSon)
      FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS05403"/*cMsgId*/,"MOMS05403 - Diretório dos arquivos JSON modelos ou o Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+"."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      Break                                     
   EndIf
      
   _cDirJSon := AllTrim(_cDirJSon)
   If Right(_cDirJSon,1) <> "\"
      _cDirJSon := _cDirJSon + "\"
   EndIf
   
   //================================================================================
   // Lê o arquivo modelo JSON de Login e o transforma em String.
   //================================================================================
   _cLoginStatus := U_MOMS054X(_cDirJSon+"Krona1_Login_2.txt") 
   If Empty(_cLoginStatus)
      FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS05404"/*cMsgId*/,"MOMS05404 - Erro na leitura do arquivo modelo JSON modelo de Login da integração Krona."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      Break
   EndIf

   //================================================================================
   // Lê os arquivos modelo JSON e os transforma em String.
   //================================================================================
   _cPesqViagem := U_MOMS054X(_cDirJSon+"Krona1_Requisicao_Status.txt") 
   If Empty(_cPesqViagem)
      FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS05405"/*cMsgId*/,"MOMS05405 - Erro na leitura do arquivo modelo JSON modelo de Requisição de Status da integração Krona."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      Break
   EndIf
   
   //========================================================================
   // Inicia a Transmissão de dados.
   //========================================================================
   _nStart 		:= 0
   _nRetry 		:= 0
   _cJSonRet 	:= Nil 
   _nTimOut	 	:= 120
   _cJSonEnv    := &(_cPesqViagem)     
   
   _cRetHttp    := ''
   
   _aHeadOut := {}              
   
   aAdd(_aHeadOut,'Content-Type: application/json') 
     
   aAdd(_aHeadOut,"usuario: " + AllTrim(_cUsuario))
   aAdd(_aHeadOut,"senha: "+ AllTrim(_cSenha)) 
   
   If _cTipoPesq == "P" // Pesquisa por placa de veículo
      _cLinkWS := AllTrim(_cLinkWS) + "?id_pesquisa="+AllTrim(_cChavePesq) +"&tipo_entrada=placa"  
   Else // Pesquisa por numero de protocolo/numero de viagem
      _cLinkWS := AllTrim(_cLinkWS) + "?id_pesquisa="+AllTrim(_cChavePesq) +"&tipo_entrada=plano_k1" 
   EndIf 

   _cGetParms := "" 
   
   _cRetHttp := AllTrim(HttpGet( _cLinkWS, _cGetParms, _nTimOut, _aHeadOut, @_cJSonRet))   

   _cRetTpPesq := "Tipo de Pesquisa: " + If(_cTipoPesq == "P","Placa","Protocolo/Id Viagem") // Tipo de Pesquisa e Chave Pesquisa
   _cRetTpPesq += " - Chave Pesquisa: " + _cChavePesq
   _cRetLink   := "Link: " + _cLinkWS // Link
   _cRetUsrPsw := "Usuário = " + _cUsuario + " - Senha: " + _cSenha // Usuário e Senha,
   _cRetPesq   := "JSON de Retorno Krona: " + _cRetHttp // Retorno da Pesquisa
   
   _cRetPkrona := _cRetTpPesq + CRLF + ; // Retorno das Pesquisas no sistema Krona.
                  _cRetLink   + CRLF + ; // Para simples gravação de histórico da pesquisa.     
                  _cRetUsrPsw + CRLF + ;
                  _cRetPesq

   If ! Empty(_cRetHttp)
      varinfo("WebPage-http ret.", _cRetHttp)
   EndIf
   
   If ! Empty(_cJSonRet)
      varinfo("WebPage-json ret.", _cJSonRet)
   EndIf
   
   //===========================================================================
   // Verifica retorno de erros na integração.
   //===========================================================================
   _cMsgErro := ""

   If ! ("NUMERO_VIAGEM" $ Upper(_cRetHttp) )
      If Empty(_cRetHttp) 
         _cMsgErro := "[FALSO] Erro na consulta de Status Viagem no sistema Krona. Não houve nenhum retorno de dados do sistema Krona. "
      Else
         _cMsgErro := "[FALSO] Erro na consulta de Status Viagem no sistema Krona: " + AllTrim(_cRetHttp) + ". " 
      EndIf
      Break                                          
   EndIf
   
   FWJSonDeserialize(DecodeUtf8(_cRetHttp),@_oRetJSon)
   
   _nI := Len(_oRetJSon)   
   
   If ! _nI > 0
      _cMsgErro := "[FALSO] Erro na leitura dos dados da consulta de Status Viagem no sistema Krona." 
      Break                                          
   EndIf

   _NrViagem    := Space(20)  //      "numero_viagem":"3637591",
   _NrCliente   := Space(20)  //      "numero_cliente":"01151381",
   _NrPamcary   := Space(20)  //      "numero_pamcary":"0",
   _Status      := Space(20)  //      "status":"AGENDADA",
   _operacao    := Space(40)  //      "operacao":"ITALAC.TRANS LAG (LAGOINHA)"
   _EveDataH    := Space(20)  //      "evento_datahora":null,
   _EveTipo     := Space(20)  //      "evento_tipo":null,
   _Referencia  := Space(20)  //      "referencia":null,
   _Latitude    := "0"        //Space(20)  //      "latitude":null,
   _Longitude   := "0"        //Space(20)  //      "longitude":null,
   _Distancia   := Space(20)  //      "distancia":null,
   _Direcao     := Space(20)  //      "direcao":null,
   _InicPrev    := Space(20)  //      "inicio_previsto":"31\/08\/2019 00:00:00",
   _InicReal    := Space(20)  //      "inicio_real":"",
   _ChegDest    := Space(20)  //      "chegada_destino_datahora":"",
   _SaidaDest   := Space(20)  //      "saida_destino_datahora":"",
   _tempoEntr   := Space(20)  //      "tempo_entrega":"",
   _FimPrev     := Space(20)  //      "fim_previsto":"31\/08\/2019 08:00:00", 
   _FimReal     := Space(20)  //      "fim_real":"",
   _TempoTot    := Space(20)  //      "tempo_total":"", 

   _NomeDest    := Space(20)   //      "destinos":["nome":"ITALAC - PASSO FUNDO\/RS - PASSO FUNDO\/RS",
   _ChegDest    := Space(20)   //      "chegada_destino_datahora":null,
   _SaidaDest   := Space(20)   //      "saida_destino_datahora":null,  
   _TempCheSaid := Space(20)   //      "tempo_chegada_saida_destino":null,
   _ordem       := Space(20)   //      "ordem":"1"

   If ! Empty(_oRetJSon[1]:numero_viagem)
      _NrViagem    := _oRetJSon[1]:numero_viagem                           //      "numero_viagem":"3637591",
      _aRet        := {AllTrim(_oRetJSon[1]:numero_viagem), _oRetJSon[1]:numero_cliente, _oRetJSon[1]:status }
   EndIf 

   If ! Empty(_oRetJSon[1]:numero_cliente)
      _NrCliente   := _oRetJSon[1]:numero_cliente                          //      "numero_cliente":"01151381",
   EndIf

   If ! Empty(_oRetJSon[1]:numero_pamcary)
      _NrPamcary   := _oRetJSon[1]:numero_pamcary                          //      "numero_pamcary":"0",
   EndIf

   If ! Empty(_oRetJSon[1]:status)
      _Status      := _oRetJSon[1]:status                                  //      "status":"AGENDADA",
   EndIf

   If ! Empty(_oRetJSon[1]:operacao)
      _operacao    := _oRetJSon[1]:operacao                                //      "operacao":"ITALAC.TRANS LAG (LAGOINHA)"
   EndIf 
   
   If ! Empty(_oRetJSon[1]:evento_datahora)
      _EveDataH    := _oRetJSon[1]:evento_datahora                         //      "evento_datahora":null,
   EndIf

   If ! Empty(_oRetJSon[1]:evento_tipo)
      _EveTipo     := _oRetJSon[1]:evento_tipo                             //      "evento_tipo":null,
   EndIf

   If ! Empty(_oRetJSon[1]:referencia)
      _Referencia  := _oRetJSon[1]:referencia                              //      "referencia":null,
   EndIf

   If ! Empty(_oRetJSon[1]:latitude)
      _Latitude    := _oRetJSon[1]:latitude                                //      "latitude":null,
   EndIf

   If ! Empty(_oRetJSon[1]:longitude)
      _Longitude   := _oRetJSon[1]:longitude                               //      "longitude":null,
   EndIf

   If ! Empty(_oRetJSon[1]:distancia)
      _Distancia   := _oRetJSon[1]:distancia                               //      "distancia":null,
   EndIf

   If ! Empty(_oRetJSon[1]:direcao)
      _Direcao     := _oRetJSon[1]:direcao                                 //      "direcao":null,
   EndIf

   If ! Empty(_oRetJSon[1]:inicio_previsto)
      _InicPrev    := _oRetJSon[1]:inicio_previsto                         //      "inicio_previsto":"31\/08\/2019 00:00:00",
   EndIf

   If ! Empty(_oRetJSon[1]:inicio_real)
      _InicReal    := _oRetJSon[1]:inicio_real                             //      "inicio_real":"",
   EndIf

   If ! Empty(_oRetJSon[1]:chegada_destino_datahora)
      _ChegDest    := _oRetJSon[1]:chegada_destino_datahora                //      "chegada_destino_datahora":"",
   EndIf

   If ! Empty(_oRetJSon[1]:saida_destino_datahora)
      _SaidaDest   := _oRetJSon[1]:saida_destino_datahora                  //      "saida_destino_datahora":"",
   EndIf

   If ! Empty(_oRetJSon[1]:tempo_entrega)
      _tempoEntr   := _oRetJSon[1]:tempo_entrega                           //      "tempo_entrega":"",
   EndIf

   If ! Empty(_oRetJSon[1]:fim_previsto)
      _FimPrev     := _oRetJSon[1]:fim_previsto                            //      "fim_previsto":"31\/08\/2019 08:00:00",
   EndIf

   If ! Empty(_oRetJSon[1]:fim_real)
      _FimReal     := _oRetJSon[1]:fim_real                                //      "fim_real":"",
   EndIf

   If ! Empty(_oRetJSon[1]:tempo_total)
      _TempoTot    := _oRetJSon[1]:tempo_total                             //      "tempo_total":"",
   EndIf

   _cLinha := ""

   For _nI := 1 To Len(_oRetJSon[1]:destinos)
       _NomeDest    := ""   //      "destinos":["nome":"ITALAC - PASSO FUNDO\/RS - PASSO FUNDO\/RS",
       _ChegDest    := ""   //      "chegada_destino_datahora":null,
       _SaidaDest   := ""   //      "saida_destino_datahora":null,  
       _TempCheSaid := ""   //      "tempo_chegada_saida_destino":null,
       _ordem       := ""   //      "ordem":"1"
       
       If ! Empty(_oRetJSon[1]:destinos[_nI]:nome)
          _NomeDest    := _oRetJSon[1]:destinos[_nI]:nome                        //      "destinos":["nome":"ITALAC - PASSO FUNDO\/RS - PASSO FUNDO\/RS",
       EndIf       
       
       If ! Empty(_oRetJSon[1]:destinos[_nI]:chegada_destino_datahora)
          _ChegDest    := _oRetJSon[1]:destinos[_nI]:chegada_destino_datahora    //      "chegada_destino_datahora":null,
       EndIf
       
       If ! Empty(_oRetJSon[1]:destinos[_nI]:saida_destino_datahora)
          _SaidaDest   := _oRetJSon[1]:destinos[_nI]:saida_destino_datahora      //      "saida_destino_datahora":null,  
       EndIf
       
       If ! Empty(_oRetJSon[1]:destinos[_nI]:tempo_chegada_saida_destino )
          _TempCheSaid := _oRetJSon[1]:destinos[_nI]:tempo_chegada_saida_destino //      "tempo_chegada_saida_destino":null,
       EndIf
       
       If ! Empty(_oRetJSon[1]:destinos[_nI]:ordem)
          _Ordem       := _oRetJSon[1]:destinos[_nI]:ordem                       //      "ordem":"1"
       EndIf
       
       _cLinha      += "Nome: " + _NomeDest + " - Chegada ao Destino: " + _ChegDest + " - Saida Destino: " + _SaidaDest + " - Tempo Entre Chegada e Saída Dest.: " + ;
                       _TempCheSaid + " - Ordem: " + _Ordem + CRLF
   Next

   If ! Empty(_oRetJSon[1]:numero_viagem)
      aAdd(_aRet, _operacao)
      aAdd(_aRet, _InicPrev)
      aAdd(_aRet, _cRetTpPesq) // Tipo de Pesquisa e Chave Pesquisa
      aAdd(_aRet, _cRetLink)   // Link
      aAdd(_aRet, _cRetUsrPsw) // Usuário e Senha,
      aAdd(_aRet, _cRetPesq)   // Retorno da Pesquisa
   EndIf

   If Upper(AllTrim(_Status)) $ "FINALIZADA/ENCERRADA/FINAL/CANCELADA" .And. _cTipoPesq == "P" 
      _aRet := {} 
   EndIf

End Sequence

If ! Empty(_cMsgErro) 
   FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS05406"/*cMsgId*/,"MOMS05406 - "+ _cMsgErro/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf

Return _aRet     

/*
===============================================================================================================================
Função-------------: MOMS054S
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/05/2018
Descrição----------: Rotina para rodar em Scheduller e para fazer automaticamente a emissão do relatório de Monitoramento de
                     Cargas.
Parametros---------: Nenhum
Retorno------------: Nenhum
===============================================================================================================================
*/  
User Function MOMS054S()
Local _cQry
Local _nPrcMinCarga
Local _nDiasDescDt, _dDtInicInteg

Begin Sequence

   //=============================================================================
   // Ativa a filial "01" apenas para leitura das filiais do parâmetro.
   //=============================================================================
   RESET ENVIRONMENT
   RpcSetType(3)
   
    //=============================================================================
    // Inicia processamento com base nas filiais do parâmetro.
    //=============================================================================
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS05407"/*cMsgId*/,"MOMS05407 - Abrindo o ambiente para filial 01..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
 
   //===========================================================================================
   // Preparando o ambiente com a filial 01
   //===========================================================================================
   PREPARE ENVIRONMENT EMPRESA '01' FILIAL "01" ; //USER 'Administrador' PASSWORD '' ;
               TABLES 'SC5','SC6',"DAK","DAI","SA2","SA1",'ZP1', "SF2", "SD2", "ZFM" MODULO 'OMS'
    
   Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.
                   
   _cfilial := "01"
      
   cFilAnt := _cfilial 
    
	cUSUARIO := Space(06)+"Administrador  "
	cUserName:= "Schedule"

   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS05408"/*cMsgId*/,"MOMS05408 - Iniciando schedule de integração de carga para o sistema Krona. "/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

   _nPrcMinCarga := U_ItGetMv("ITPRCMINCAR",100000) 
   _nDiasDescDt  := U_ItGetMv("ITDIASDESKR",5)  
   _dDtInicInteg := Date() - _nDiasDescDt

   _cQry := " SELECT DISTINCT F2_FILIAL CODFILIAL, F2_CARGA CODCARGA, DAK.R_E_C_N_O_ NRRECDAK, F2_I_PEDID "
   _cQry += " FROM " + RetSqlName("SF2") + " SF2, " + RetSqlName("DAK") + " DAK "
   _cQry += " WHERE SF2.D_E_L_E_T_ = ' ' AND DAK.D_E_L_E_T_ = ' ' "
   _cQry += " AND F2_EMISSAO >= '" + DToS(_dDtInicInteg) +"' AND DAK_FILIAL = F2_FILIAL "
   _cQry += " AND DAK_COD = F2_CARGA "  // AND DAK_I_PROT = ' ' 
   _cQry += " AND DAK_VALOR >= " + AllTrim(Str(_nPrcMinCarga,16,2))
   _cQry += " AND NOT EXISTS (SELECT 'X' FROM " + RetSqlName("DAI") + " DAI "
   _cQry += "                 WHERE DAI_FILIAL = DAK_FILIAL "
   _cQry += "                       AND DAI_COD= DAK_COD "
   _cQry += "                       AND DAI_NFISCA = ' ' "
   _cQry += "                       AND DAI.D_E_L_E_T_ = ' ' ) "
   _cQry += " ORDER BY F2_FILIAL, F2_CARGA "

   U_MOMS054("S", _cQry)

   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS05409"/*cMsgId*/,"MOMS05409 - Finalizado scheduller de integração de cargas para o sistema Krona."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "SCHEDULE"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MOMS05410"/*cMsgId*/,"MOMS05410 - Processo finalizado."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
 
 End Sequence 

 Return 

 /*
===============================================================================================================================
Função-------------: MOMS054X
Autor--------------: Julio de Paula Paz
Data da Criacao----: 28/05/2020
Descrição---------: Lê o arquivo JSON modelo no diretório informado e retorna os dados no formato de String.
Parametros--------: _cArq = diretório + nome do arquivo a ser lido.
Retorno-----------: _cRet
===============================================================================================================================
*/  
User Function MOMS054X(_cArq)
Local _cRet := ""
Local _nStatusArq 
Local _cLine 

Begin Sequence
   _nStatusArq := FT_FUse(_cArq)
      
   // Se houver erro de abertura abandona processamento
   If _nStatusArq = -1  
      Break
   EndIf
   
   // Posiciona na primeria linha
   FT_FGoTop()

  
   While !FT_FEOF()   
      _cLine  := FT_FReadLn() 
      
      _cRet +=  _cLine
   
      FT_FSKIP()
   End

   // Fecha o Arquivo
   FT_FUSE()

End Sequence

Return _cRet      
