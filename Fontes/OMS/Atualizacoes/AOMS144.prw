/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |10/06/2025| Chamado 45229. Ajuste do parâmetro p/determinar se a integração WebS.será TMS Multiembarcador ou RDC
Lucas Borges  |01/08/2025| Chamado 51453. Substituir função EncodeUtf8 por FWHttpEncode
Lucas Borges  |18/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "APWEBSRV.CH"

Static _lWsTms := .F. // Indica se rotina de integração WebService é TMS Multi-Embarcador ou RDC.
Static _lScheduler := FWGetRunSchedule() .Or. SELECT("SX3") <= 0

/*
===============================================================================================================================
Programa----------: AOMS144
Autor-------------: Igor Melgaço
Data da Criacao---: 19/02/2024
Descrição---------: Rotina de integração e envio de dados de vinculação Nota Fiscal Eletrônica com Pedidos de Vendas 
                    via webservice para o sistema TMS.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS144

Local _aCores   := {}
Local _cFiltro  := ""

Private aRotina := {}
Private cCadastro 

//Grava Log de execução da rotinaFI040EM
U_ITLOGACS()

cCadastro := "Integrações Italac <---> TMS"
//cCadastro := "Integração dos Dados de Vinculação Cargas e NFE Via Webservice: Italac <---> TMS"

aAdd(aRotina,{"Pesquisar"                                ,"AxPesqui"   ,0,1})
aAdd(aRotina,{"Visualizar"                               ,"AxVisual"   ,0,2})
aAdd(aRotina,{"NFe\Integrar Notas Fiscais"               ,"U_AOMS144C" ,0,4})   
aAdd(aRotina,{'NFe\Enviar Arquivos XML NFe'              ,"U_AOMS144E" ,0,4})
aAdd(aRotina,{'NFe\Informar Cancelamento de Nota Fiscal' ,"U_AOMS144A" ,0,4})
aAdd(aRotina,{'Cargas\Liberar Emissao Sem NFe (Carga Gerada)'         ,"U_AOMS144B" ,0,4})
aAdd(aRotina,{'Cargas\Liberar Emissao Sem NFe (Carga Integrada)'      ,"U_AOMS144N" ,0,4})
aAdd(aRotina,{"Legenda"                                  ,"U_AOMS144L" ,0,6})

aAdd(_aCores,{"ZFK_SITUAC == 'N'" ,"BR_VERDE" })
aAdd(_aCores,{"ZFK_SITUAC == ' '" ,"BR_VERDE" })
aAdd(_aCores,{"ZFK_SITUAC == 'P'" ,"BR_VERMELHO" })
aAdd(_aCores,{"ZFK_SITUAC == 'R'" ,"BR_AMARELO" })

DBSelectArea("ZFK")
ZFK->(DBSetOrder(1)) 
ZFK->(DBGoTop())

_cFiltro := "ZFK_TIPOI <> '1' AND ZFK_TIPOI <> ' '"

MBrowse(6,1,22,75,"ZFK" ,,,,,,_aCores,,,,,,,,_cFiltro)

Return

/*
===============================================================================================================================
Função------------: AOMS144L
Autor-------------: Igor Melgaço
Data da Criacao---: 19/02/2024
Descrição---------: Rotina de Exibição da Legenda do MBrowse.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS144L

Local _aLegenda := {}

aAdd(_aLegenda,{"BR_VERDE"    ,"Não Processado" })
aAdd(_aLegenda,{"BR_AMARELO"  ,"Rejeitada" })
aAdd(_aLegenda,{"BR_VERMELHO" ,"Processado" })

BrwLegenda(cCadastro, "Legenda", _aLegenda)

Return

/*
===============================================================================================================================
Programa--------: AOMS144C
Autor-----------: Igor Melgaço
Data da Criacao-: 23/01/2024
Descrição-------: Integrar Notas Fiscais com o TMS 
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS144C

If _lScheduler

   U_ItConout("[AOMS144] - Abrindo o ambiente..." )
   
   RpcSetType(3) //Nao consome licensas
   RpcSetEnv( "01" , "01" ,,,"OMS", "SCHEDULE_INT_CARGAS_TMS" , {'DAK','DAI','SF2','ZFK','SA1','SA2'} )
   Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.

   cFilAnt := "01"

   
   U_AOMS144P()
   U_AOMS144I()
   

   //============================================================
   //Limpa o ambiente, liberando a licença e fechando as conexoes
   //============================================================
   RpcClearEnv() 

Else

   Processa( {|| U_AOMS144P(),U_AOMS144I() } , 'Aguarde!' , 'Processando Cargas...' )

EndIf

Return .F.

/*
===============================================================================================================================
Programa----------: AOMS144P
Autor-------------: Igor Melgaço
Data da Criacao---: 23/01/2024
Descrição---------: Rotina de carga de dados das Cargas para Integração de Notas Fiscais
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS144P

Local _cQuery      := ""
Local _cTimeIni    := Time()
Local _cAlias      := "DAK"
Local _cAliasTMP   := "TRBAOMS144P"
Local _aAlias      := {}
Local _nRegAtu     := 0
Local _nTotRegs    := 0
Local _aCabec      := {}
Local _aPosCpo     := {}
Local _aSizes      := {}
Local _aCampos     := {}
Local _aLinha      := {}
Local _aDados      := {}
Local _lReturn     := .F.
Local _lOk         := .T.
Local _cMsg        := ""
Local _aLog        := {}
Local _aCabecLog   := {"Processado","Filial","Pedido","Chave NFe","Retorno", "Recno SF2"}
Local _cTextoFim   := ""
Local _nEnviados   := 0
Local _dDataIntTMS := SuperGetMV("IT_DTINTMS",.F.,Ctod("01/01/2024"))
Local _nI          := 0
Local _cTitulo     := ""
Local _cMsgTop     := ""
Local _cCodEmpWS   := SuperGetMV('IT_EMPTMSM',.F.,"000005")
Local _lSC5_PEDPA  := .F.
Local _cFilHabilit := SuperGetMV('IT_FILINTW',.F.,'')

Begin Sequence

   If !_lScheduler .And. ! U_ITMsg("Confirma carga de registros para integração de Notas Fiscais >> Italac <---> TMS Multi-Embarcador?","Inicio de processamento",,4,2,2) 
      Break
   EndIf

   _aAlias := AOMS144MA(_cAlias,_cAliasTMP, .T.,.T.)

   _aCabec  := _aAlias[1]
   _aPosCpo := _aAlias[2]
   _aSizes  := _aAlias[3]
   _aCampos := _aAlias[4]

   _cQuery := "SELECT * "
   _cQuery += "FROM "+RetSqlName("DAK")+" DAK "
   _cQuery += "WHERE DAK_FILIAL IN ('" + StrTran(AllTrim(_cFilHabilit) ,";","','") + "') "
   _cQuery += "  AND DAK_DATA >= '" + DToS(_dDataIntTMS) + "' "
   _cQuery += "  AND DAK_I_RECR <> ' ' "
   _cQuery += "  AND DAK_I_PTMS =  ' ' "
   _cQuery += "  AND DAK.D_E_L_E_T_ = ' ' "
   _cQuery += " AND NVL ( "
   _cQuery += "             (SELECT COUNT (1) "
   _cQuery += "              FROM "+RetSqlName("DAI")+" DAI "
   _cQuery += "              WHERE DAI_FILIAL = DAK_FILIAL "
   _cQuery += "                AND DAI_COD = DAK_COD "
   _cQuery += "                AND DAI.D_E_L_E_T_ = ' '),0) = NVL ( "
   _cQuery += "                                                      (SELECT COUNT (1) "
   _cQuery += "                                                       FROM "+RetSqlName("DAI")+" DAI, "
   _cQuery += "                                                            "+RetSqlName("SF2")+" SF2 "
   _cQuery += "                                                       WHERE DAI_FILIAL = DAK.DAK_FILIAL "
   _cQuery += "                                                         AND DAI_COD = DAK.DAK_COD "
   _cQuery += "                                                         AND DAI.D_E_L_E_T_ = ' ' "
   _cQuery += "                                                         AND F2_FILIAL = DAI_FILIAL "
   _cQuery += "                                                         AND F2_DOC = DAI_NFISCA "
   _cQuery += "                                                         AND F2_SERIE = DAI_SERIE "
   _cQuery += "                                                         AND F2_I_PRTMS <> ' ' "
   _cQuery += "                                                         AND SF2.D_E_L_E_T_ = ' '),0) "
   _cQuery += "   AND EXISTS "
   _cQuery += "              (SELECT 'X' "
   _cQuery += "                 FROM "+RetSqlName("DAI")+" DAI, "+RetSqlName("SF2")+" SF2 "
   _cQuery += "                WHERE     DAI_FILIAL = DAK.DAK_FILIAL "
   _cQuery += "                      AND DAI_COD = DAK.DAK_COD "
   _cQuery += "                      AND DAI.D_E_L_E_T_ = ' ' "
   _cQuery += "                      AND F2_FILIAL = DAI_FILIAL "
   _cQuery += "                      AND F2_DOC = DAI_NFISCA "
   _cQuery += "                      AND F2_SERIE = DAI_SERIE "
   _cQuery += "                      AND F2_I_PRTMS <> ' ' "
   _cQuery += "                      AND F2_I_SITUA = 'P' "
   _cQuery += "                      AND SF2.D_E_L_E_T_ = ' ' )"

   _cQuery := ChangeQuery(_cQuery)

   If Select(_cAliasTMP) > 0
      DBSelectArea(_cAliasTMP)
      DBCloseArea()
   EndIf

   MPSysOpenQuery(_cQuery,_cAliasTMP)

   DBSelectArea(_cAliasTMP)
   Count To _nTotRegs

   If !_lScheduler 
      ProcRegua(_nTotRegs)
   EndIf

   _cTotal := AllTrim(Str(_nTotRegs))

   If _nTotRegs > 0

      DBSelectArea(_cAliasTMP)
      (_cAliasTMP)->(DBGoTop())
      While (_cAliasTMP)->(!Eof())
         
         _nRegAtu++
         
         If !u_IT_TMS((_cAliasTMP)->DAK_I_LEMB )
            Loop
         EndIf

         If !_lScheduler 
            IncProc("Lendo dados de Carga - Registro : " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
         EndIf

         _aLinha := {}
         For _nI := 1 To Len(_aCampos)
            aAdd(_aLinha, &(_aCampos[_nI]))
         Next

         aAdd(_aDados,_aLinha)

         (_cAliasTMP)->(DBSkip())

      EndDo

      If _lScheduler
      
         _lReturn := .T.
      
      Else
      
         _cTitulo := "Cargas que foram geradas a partir de integração com o TMS Multiembarcador "
         _cMsgTop := _cTitulo

                     //ITListBox( _cTitAux , _aHeader    , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda ,_lHasOk,_bHeadClk,_aSX1)
         _lReturn := U_ITListBox( _cTitulo , _aCabec     , _aDados   , .T.      , 2      , _cMsgTop ,          , _aSizes ,         ,     ,        ,          ,       ,         ,          ,           ,          ,       ,         ,     )
      
      EndIf

      If _lReturn
         
         For _nI := 1 To Len(_aDados) 

            If _lScheduler   
               U_ItConout("[AOMS144P] Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)  
            Else
               IncProc("Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)   
            EndIf

            If _aDados[_nI][1] .Or. _lScheduler
               
               _cFilial := _aDados[_nI][aScan(_aPosCpo,{|x|x="DAK_FILIAL"})]
               _cCarga := _aDados[_nI][aScan(_aPosCpo,{|x|x="DAK_COD"})]

               DBSelectArea("DAI")
               DAI->( DBSetOrder(1) ) //DAI_FILIAL+DAI_COD+DAI_SEQCAR+DAI_SEQUEN+DAI_PEDIDO
               If DAI->( DBSeek( _cFilial + _cCarga ) )
                  While DAI->(!Eof()) .And. DAI->DAI_COD == _cCarga .And. DAI->DAI_FILIAL == _cFilial

                     DBSelectArea("SF2")
                     SF2->( DBSetOrder(1) )
                     If SF2->( DBSeek( DAI->DAI_FILIAL + DAI->DAI_NFISCA + DAI->DAI_SERIE ) )

                        _nEnviados++ 
                        
                        If !_lScheduler 
                           IncProc("Gerando dados da Carga: " + _cCarga)  
                        Else
                           ConOut("[AOMS144P] - Gerando dados da Carga: " + _cCarga )
                        EndIf

                        _lSC5_PEDPA := .F.
      
                        If !Empty(AllTrim(SF2->F2_I_PEDID ))
                           DBSelectArea("SC5")
                           SC5->( DBSetOrder(1) )
                           If SC5->( DBSeek( SF2->F2_FILIAL + SF2->F2_I_PEDID ) )
                              _lSC5_PEDPA   := (SC5->C5_I_PEDPA == "S")
                              _cSC5_I_CDTMS := SC5->C5_I_CDTMS
                           Else
                              _lSC5_PEDPA   := .F.
                              _cSC5_I_CDTMS := ""
                           EndIf
                        EndIf

                        Begin Transaction

                           If !_lScheduler 
                              IncProc("Carregando Carga: " + DAK->DAK_COD)  
                           Else
                              ConOut("[AOMS144P] - Carregando Carga: " + DAK->DAK_COD )
                           EndIf

                           RecLock("ZFK",.T.)
                              ZFK->ZFK_FILIAL  := _aDados[_nI][aScan(_aPosCpo,{|x|x="DAK_FILIAL"})]     //	Filial do Sistema
                              ZFK->ZFK_CARGA   := _aDados[_nI][aScan(_aPosCpo,{|x|x="DAK_COD"})]
                              ZFK->ZFK_DATA    := _aDados[_nI][aScan(_aPosCpo,{|x|x="DAK_DATA"})]
                              ZFK->ZFK_CARTMS  := _aDados[_nI][aScan(_aPosCpo,{|x|x="DAK_I_RECR"})]
                              ZFK->ZFK_PRTPED  := _cSC5_I_CDTMS
                              ZFK->ZFK_HORA    := Time()             // Hora de inclusão do registro na tabela de muro.
                              ZFK->ZFK_DATA    := Date()	            //	Data de Emissão
                              ZFK->ZFK_CGC     := Posicione("SA1",1,xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA),"A1_CGC")             //	CNPJ FORNECEDOR
                              ZFK->ZFK_CHVNFE  := SF2->F2_CHVNFE     //	Chave da NFe SEFAZ
                              ZFK->ZFK_PEDIDO  := SF2->F2_I_PEDID           //	Numero do Pedido(Na Italac há um pedido por nota) // SF2->F2_I_PEDID
                              ZFK->ZFK_COD	  := SF2->F2_CLIENTE    // Código Cliente    // SA2->A2_COD  - Fornecedor    // O correto é: A1_COD
                              ZFK->ZFK_LOJA    := SF2->F2_LOJA       // Loja Cliente      // SA2->A2_LOJA - Fornecedor    //              A1_LOJA
                              ZFK->ZFK_NOME    := Posicione("SA1",1,xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA),"A1_NOME")   // Nome Cliente      // SA2->A2_NOME - Fornecedor   //              A1_NOME
                              ZFK->ZFK_PRTMS   := SF2->F2_I_PRTMS
                              ZFK->ZFK_USUARI  := __cUserId	         //	Codigo do Usuário
                              ZFK->ZFK_DATAAL  := Date()	            //	Data de Alteração
                              ZFK->ZFK_SITUAC  := "N"                //	Situação do Registro
                              
                              If _lSC5_PEDPA                //  "S" = é um pedido de pallet.
                                 ZFK->ZFK_PEDPAL  := "S"             //  Grava dados informando que é um pedido de pallet.
                                 ZFK->ZFK_NRPPAL  := SF2->F2_I_PEDID //  Grava o numero do pedido de Pallet.
                              Else
                                 ZFK->ZFK_PEDPAL  := "N"             //  Não é um pedido de Pallet.
                              EndIf

                              ZFK->ZFK_TIPOI   := "4"
                              ZFK->ZFK_CODEMP  := _cCodEmpWS         //	Codigo Empresa WebServer 
                           ZFK->(MSUnLock())

                           RecLock("SF2",.F.)
                              SF2->F2_I_SITUA := "I"
                           SF2->(MSUnLock())

                        End Transaction

                        _cMsg := "Carregado para Integração"

                     Else
                        _lOk := .F.
                        _cMsg := "Nota Fiscal não encontrada! Filial " + DAI->DAI_FILIAL + " Nota " + DAI->DAI_NFISCA + " Serie " + DAI->DAI_SERIE 
                     EndIf

                     aAdd(_aLog,{_lOk, SF2->F2_FILIAL,SF2->F2_I_PEDID,SF2->F2_CHVNFE,_cMsg,SF2->(Recno())})

                     DAI->(DBSkip())
                  EndDo
               Else
                  _lOk := .F.
                  _cMsg := "Carga não encontrada! Filial " + _cFilial + " Carga " + _cCarga
                  
                  aAdd(_aLog,{_lOk, SF2->F2_FILIAL,SF2->F2_I_PEDID,SF2->F2_CHVNFE,_cMsg,SF2->(Recno())})
               EndIf
               
            EndIf
         
         Next

         _cTextoFim := "Registros carregados para Integração de Notas Fiscais: "+Str(_nEnviados)+Chr(10)

         U_ItConout("[AOMS144P] >> Carregamento concluído << Italac <---> TMS Multi-Embarcador "+_cTextoFim)
         
         If !_lScheduler
            U_ITMsg(">> Carregamento concluído << "+Chr(10)+;
                  "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+_cTextoFim+Chr(10),;
                  "Fim de Carregamento",,2)
            
            If Len(_aLog) > 0

               U_ITListBox( 'Log de Processamento do carregamento de registros para Integração de Notas Fiscais',;
               _aCabecLog, _aLog , .T. , 1 ,;
               "Abaixo segue a relação de Carregamento" )

            EndIf
         EndIf

      EndIf
   Else
      If _lScheduler
         ConOut("[AOMS144] - Não foram encontrados dados para integração." )
      Else
         U_ITMsg(">> Processamento concluído << "+Chr(10)+;
         "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
         "Atenção",,3)
      EndIf
   EndIf

End Sequence

If Select(_cAliasTMP) > 0
   (_cAliasTMP)->( DBCloseArea() )
EndIf

Return _lReturn

/*
===============================================================================================================================
Função------------: AOMS144I
Autor-------------: Igor Melgaço
Data da Criacao---: 19/02/2024
Descrição---------: Integrar Notas Fiscais  TMS.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS144I

Local _cQry             := ""
Local _aOrd             := SaveOrd({"SX3","ZFK"})
Local _cAlias           := "ZFK"
Local _cAliasTMP        := "TRBZFK"
Local _cTimeIni         := Time()
Local _nI               := 0
Local _nRegAtu          := 0
Local _nTotRegs         := 0
Local _nEnviados        := 0
Local _aDados           := {}
Local _aSizes           := {}
Local _aCabec           := {}
Local _aAlias           := {}
Local _aCampos          := {}
Local _aLinha           := {}
Local _aPosCpo          := {}
Local _cToken           := ""
Local _cLink            := ""
Local _cXML             := ""
Local _cCodEmpWS   := SuperGetMV('IT_EMPTMSM',.F.,"000005")
Local _aLog          := {}
Local _aCabecLog        := {"Processado","Filial","Chave NFe","Pedido","CNPJ","Retorno", "Recno ZFK"}
Local _cTextoFim     := ""
Local _lOk              := .F.
Local _cResult          := ""
Local _cFilHabilit      := SuperGetMV('IT_FILINTW',.F.,'')
Local _cResposta        := ""
Local cReplace          := ""
Local cErros            := ""
Local cAvisos           := ""
Local _nRecnoZFK        := 0
Local oWSDL
Local _aCargaLibSNFe     := {}

Begin Sequence

   If !_lScheduler .And. ! U_ITMsg("Confirma integração de Notas Fiscais >> Italac <---> TMS Multi-Embarcador?","Inicio de processamento",,4,2,2) 
      Break
   EndIf

   _aAlias := AOMS144MA(_cAlias,_cAliasTMP, .T.,.T.,.T.)

   _aCabec  := _aAlias[1]
   _aPosCpo := _aAlias[2]
   _aSizes  := _aAlias[3]
   _aCampos := _aAlias[4]

   //===================================================================================================
   // Montagem de query com os numeros de registros das notas fiscais a serem enviadas para o RDC.
   //===================================================================================================
   _cQry := " SELECT ZFK.*,  ZFK.R_E_C_N_O_ R_E_C_N_O_ "
   _cQry += " FROM "+RetSqlName("ZFK")+" ZFK "
   _cQry += " WHERE ZFK.D_E_L_E_T_ = ' ' "
   _cQry += "   AND ZFK_TIPOI = '4' "
   _cQry += "   AND (ZFK_SITUAC = 'N' OR  ZFK_SITUAC = 'R') "
   _cQry += "   AND ZFK_FILIAL IN "+FormatIn(AllTrim(_cFilHabilit),";")

   _cQry := ChangeQuery(_cQry)          

   If Select(_cAliasTMP) > 0
      (_cAliasTMP)->( DBCloseArea() )
   EndIf

   MPSysOpenQuery(_cQry,_cAliasTMP)

   DBSelectArea(_cAliasTMP)
   Count To _nTotRegs

   If !_lScheduler 
      ProcRegua(_nTotRegs)
   EndIf
   
   _cTotal := AllTrim(Str(_nTotRegs))

   If _nTotRegs > 0

      DBSelectArea(_cAliasTMP)
      (_cAliasTMP)->(DBGoTop())

      While (_cAliasTMP)->(!Eof())

         _nRegAtu++

         If !_lScheduler 
            IncProc("Lendo dados de Carga - Registro : " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
         EndIf

         _aLinha := {}
         For _nI := 1 To Len(_aCampos)
            aAdd(_aLinha, &(_aCampos[_nI]))
         Next

         aAdd(_aDados,_aLinha)

         (_cAliasTMP)->(DBSkip())

      EndDo

      If _lScheduler
      
         _lReturn := .T.
      
      Else
      
         _cTitulo := "Cargas que foram geradas a partir de integração com o TMS Multiembarcador "
         _cMsgTop := _cTitulo

         If Len(_aDados) > 0
                        //ITListBox( _cTitAux , _aHeader    , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda ,_lHasOk,_bHeadClk,_aSX1)
            _lReturn := U_ITListBox( _cTitulo , _aCabec     , _aDados   , .T.      , 2      , _cMsgTop ,          , _aSizes ,         ,     ,        ,          ,       ,         ,          ,           ,          ,       ,         ,     )
         Else
            U_ITMsg(">> Processamento concluído << "+Chr(10)+;
            "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
            "Atenção!!!",,3)
            Break
         EndIf            
      EndIf

      If _lReturn

         //=====================================================================
         // Obtem o token de acesso ao sistema multi embarcador.
         //=====================================================================
         _cToken := SuperGetMV('IT_TOKMUTE',.F.,"a78e0523d3794843855e8d95c2bff8d4")

         If !_lScheduler 
            ProcRegua(Len(_aDados))
         EndIf

         _cTotal := AllTrim(Str(Len(_aDados)))

         For _nI := 1 To Len(_aDados)

            If _lScheduler   
               U_ItConout("[AOMS144I] Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)  
            Else
               IncProc("Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)   
            EndIf

            If _aDados[_nI][1] .Or. _lScheduler

               Begin Sequence
               
                  _nRecnoZFK := _aDados[_nI][aScan(_aPosCpo,{|x|x="R_E_C_N_O_"})]

                  ZFK->(DBGoTo(_nRecnoZFK))
                  
                  ZFM->(DBSetOrder(1))
                  If ZFM->(DBSeek(ZFK->ZFK_FILIAL+_cCodEmpWS))
                     _cLink   := AllTrim(ZFM->ZFM_LINK02)
                  Else
                     _cMsg := "Empresa WebService para envio dos dados não localizada."          
                     If ! _lScheduler
                        MsgInfo(_cMsg,"Atenção")
                     Else
                        u_itconout("[AOMS144I] "+_cMsg)
                     EndIf
                     _lOk := .F.
                     Break   
                  EndIf                        

                  If Empty(_cLink)
                     _cMsg := "O Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+"."
                     If !_lScheduler
                        U_ITMsg(_cMsg,"Atenção",,1)
                     Else
                        U_ItConout("[AOMS144I] "+_cMsg)
                     EndIf
                     _lOk := .F.
                     Break                                     
                  EndIf

                  DBSelectArea("DAK")
                  DBSetOrder(1)
                  If DBSeek(ZFK->ZFK_FILIAL+ZFK->ZFK_CARGA)

                     If ! _lScheduler
                        IncProc("Integrando Carga: "+DAK->DAK_COD)                    
                     Else
                        u_itconout("[AOMS144I] Integrando Carga: "+DAK->DAK_COD) 
                     EndIf  

                     _cProtIntC := AllTrim(DAK->DAK_I_RECR)  //'446' 
                     _cProtIntP := AllTrim(ZFK->ZFK_PRTPED) // '2335'
                     _cTokenNF  := AllTrim(ZFK->ZFK_PRTMS) //'74998224-5997-4343-9621-7cf0c2cd4b61'

                     _cXml := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns:dom="http://schemas.datacontract.org/2004/07/Dominio.ObjetosDeValor.WebService.Carga" xmlns:dom1="http://schemas.datacontract.org/2004/07/Dominio.ObjetosDeValor.Embarcador.Pessoas" xmlns:dom2="http://schemas.datacontract.org/2004/07/Dominio.ObjetosDeValor.Embarcador.Localidade" xmlns:dom3="http://schemas.datacontract.org/2004/07/Dominio.ObjetosDeValor" xmlns:dom4="http://schemas.datacontract.org/2004/07/Dominio.ObjetosDeValor.Embarcador.Carga" xmlns:arr="http://schemas.microsoft.com/2003/10/Serialization/Arrays" xmlns:dom5="http://schemas.datacontract.org/2004/07/Dominio.ObjetosDeValor.WebService" xmlns:dom6="http://schemas.datacontract.org/2004/07/Dominio.ObjetosDeValor.Embarcador.NFe">'
                     _cXml += '  <soapenv:Header>'
                     _cXml += '		<Token xmlns="Token">'+_cToken+'</Token>'
                     _cXml += '	</soapenv:Header>'
                     _cXml += '   <soapenv:Body>'
                     _cXml += '      <tem:IntegrarNotasFiscais>'
                     _cXml += '         <tem:protocolo>'
                     _cXml += '            <dom:protocoloIntegracaoCarga>'+_cProtIntC+'</dom:protocoloIntegracaoCarga>'
                     _cXml += '            <dom:protocoloIntegracaoPedido>'+_cProtIntP+'</dom:protocoloIntegracaoPedido>'
                     _cXml += '         </tem:protocolo>'
                     _cXml += '         <tem:TokensXMLNotasFiscais>'
                     _cXml += '            <dom6:TokenNF>'
                     _cXml += '               <dom6:Token>'+_cTokenNF+'</dom6:Token>'
                     _cXml += '            </dom6:TokenNF>'
                     _cXml += '         </tem:TokensXMLNotasFiscais>'
                     _cXml += '      </tem:IntegrarNotasFiscais>'
                     _cXml += '   </soapenv:Body>'
                     _cXml += '</soapenv:Envelope>'

                     oWsdl := tWSDLManager():New() // Cria o objeto da WSDL.  
                     oWsdl:nTimeout := 60          // Timeout de xx segundos                                                               
                     oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo                                                               
                     
                     oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da TMS.   
                     oWsdl:SetOperation( "IntegrarNotasFiscais") // Define qual operação será realizada.   

                     // Envia para o servidor
                     _lOk := oWsdl:SendSoapMsg(_cXML) // Este comando pega o XML e envia para o servidor da TMS.     
                     
                     If _lOk 

                        _cResult := oWsdl:GetParsedResponse() // Pega o resultado de envio já no formato em string.  
                        oResult := XmlParser(oWsdl:GetSoapResponse(), cReplace, @cErros, @cAvisos)
                     If oResult:_S_ENVELOPE:_S_BODY:_INTEGRARNOTASFISCAISRESPONSE:_INTEGRARNOTASFISCAISRESULT:_A_STATUS:TEXT == "false"
                           _lOk := .F.
                        Else
                           _cResult := "Integração Processada"
                        EndIf

                     Else
                        _cResult := oWsdl:cError 
                        _cProtocolo := ""
                     EndIf   

                     _cResposta := AllTrim(StrTran(_cResult,Chr(10)," "))
                     _cResposta := Upper(_cResposta)
                     
                     //grava resultado // sempre como processado
                     ZFK->(RecLock("ZFK",.F.))
                        ZFK->ZFK_SITUAC  := IIf(_lOk, "P", "N")
                        ZFK->ZFK_USUARI  := __cUserId
                        ZFK->ZFK_DATAAL  := Date()
                        ZFK->ZFK_RETORN  := _cResposta // AllTrim(StrTran(_cResult,Chr(10)," ")) // grava o resultado da integração na tabela ZFK,dizendo que deu certo ou não.
                        ZFK->ZFK_XML     := _cXML
                     ZFK->(MSUnLock()) 

                     If _lOk
                        DBSelectArea("DAI")
                        DAI->( DBSetOrder(1) ) //DAI_FILIAL+DAI_COD+DAI_SEQCAR+DAI_SEQUEN+DAI_PEDIDO
                        If DAI->( DBSeek( DAK->(DAK_FILIAL+DAK_COD) ) )
                           While DAI->(!Eof()) .And. DAI->DAI_COD == DAK->DAK_COD .And. DAI->DAI_FILIAL == DAK->DAK_FILIAL
                              DBSelectArea("SF2")
                              SF2->( DBSetOrder(1) )
                              If SF2->( DBSeek( DAI->DAI_FILIAL + DAI->DAI_NFISCA + DAI->DAI_SERIE ) )
                                 RecLock("SF2",.F.)
                                    SF2->F2_I_SITUA := "V"
                                 SF2->(MSUnLock())
                              EndIf
                              DAI->(DBSkip())
                           EndDo
                        EndIf
                        
                        If aScan(_aCargaLibSNFe,{|x|x = DAK->(Recno())}) = 0
                           aAdd(_aCargaLibSNFe,DAK->(Recno()))
                        EndIf   
                     EndIf
                  Else
                     _cResposta := "Não encontrada a carga '"+ZFK->ZFK_CARGA+"' para efetuar a integração"
                     _lOk := .F.
                  EndIf   
               End Sequence

               aAdd(_aLog,{_lOk,ZFK->ZFK_FILIAL,ZFK->ZFK_CHVNFE,ZFK->ZFK_PEDIDO,ZFK->ZFK_CGC,_cResposta,ZFK->(Recno())}) // adicona em um array para fazer um item list, exibir os resultados.
               Sleep(100) //Espera para não travar a comunicação com o webservice da TMS
            EndIf

            FreeObj(oWsdl)
         Next
      EndIf

      _cTextoFim := "Notas Fiscais integradas pelo metodo IntegrarNotasFiscais : "+Str(_nEnviados)+Chr(10)
      
      U_ItConout("[AOMS144F] >> Processamento concluído << Italac <---> TMS Multi-Embarcador "+_cTextoFim)
      
      If !_lScheduler
         U_ITMsg(">> Processamento concluído << "+Chr(10)+;
               "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+_cTextoFim+Chr(10),;
               "Fim de processamento",,2)
         
         If Len(_aLog) > 0

            U_ITListBox( 'Log de Processamento da Integração',;
            _aCabecLog, _aLog , .T. , 1 ,;
            "Abaixo segue a relação de processamento do método IntegrarNotasFiscais" )

         EndIf
      EndIf
   Else
      If _lScheduler
         ConOut("[AOMS144I] - Não foram encontrados dados para integração." )
      Else
         U_ITMsg(">> Processamento concluído << "+Chr(10)+;
         "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
         "Atenção",,3)
      EndIf
   EndIf

End Sequence

If Select(_cAliasTMP) > 0
   (_cAliasTMP)->( DBCloseArea() )
EndIf

RestOrd(_aOrd)

Return

/*
===============================================================================================================================
Função-------------: AOMS144X
Aut2or-------------: Igor Melgaço
Data da Criacao---: 19/02/2024
Descrição---------: Lê o arquivo XML modelo no diretório informado e retorna os dados no formato de String.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS144X(_cArq)

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

  
   While !FT_FEof()   
      _cLine  := FT_FReadLn() 
      
      _cRet +=  _cLine
   
      FT_FSKIP()
   End

   // Fecha o Arquivo
   FT_FUSE()

End Sequence

Return _cRet       

/*
===============================================================================================================================
Programa----------: AOMS144A
Autor-------------: Igor Melgaço
Data da Criacao---: 23/01/2024
Descrição---------: Rotina de Informar Cancelamento de Nota Fiscal para o sistema TMS Mulit-Embarcador.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS144A()

If _lScheduler 
   //=====================================================================
   // Limpa o ambiente, liberando a licença e fechando as conexões
   //=====================================================================
   RpcClearEnv() 
   RpcSetType(2)
   
   //================================================================================
   // Prepara ambiente abrindo tabelas e incializando variaveis.
   //================================================================================   
   RpcSetEnv("01", "01",,,,, {"CKO","ZG0","SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6","ZP1"})
   
   cFilAnt := "01"

   AOMS144H()
   AOMS144Y()

   //============================================================
   //Limpa o ambiente, liberando a licença e fechando as conexoes
   //============================================================
   RpcClearEnv() 

Else
   
   Processa( {|| AOMS144H(),AOMS144Y()},"Hora Ini: "+Time()+", Aguarde...")
   
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS144E
Autor-------------: Igor Melgaço
Data da Criacao---: 14/02/2024
Descrição---------: Rotina de Envio do XML da nota fiscal para o sistema TMS Mulit-Embarcador.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS144E()

If _lScheduler 
   //=====================================================================
   // Limpa o ambiente, liberando a licença e fechando as conexões
   //=====================================================================
   RpcClearEnv() 
   RpcSetType(2)
   
   //================================================================================
   // Prepara ambiente abrindo tabelas e incializando variaveis.
   //================================================================================   
   RpcSetEnv("01", "01",,,,, {"CKO","ZG0","SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6","ZP1"})

   cFilAnt := "01"

   AOMS144G()
   AOMS144F()

   //============================================================
   //Limpa o ambiente, liberando a licença e fechando as conexoes
   //============================================================
   RpcClearEnv() 

Else
   
   Processa( {|| AOMS144G(),AOMS144F()},"Hora Ini: "+Time()+", Aguarde...")
   
EndIf

Return .F.

/*
===============================================================================================================================
Programa----------: AOMS144G
Autor-------------: Igor Melgaço
Data da Criacao---: 23/01/2024
Descrição---------: Rotina para carga de registros para Enviar Arquivos XML NFe, Italac <---> TMS Multi-Embarcador.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function AOMS144G()

Local _cQry        := ""
Local _cTimeIni    := Time()
Local _cAlias      := "SF2"
Local _cAliasTMP   := "TRBAOMS144G"
Local _aAlias      := {}
Local _nRegAtu     := 0
Local _nTotRegs    := 0
Local _aCabec      := {}
Local _aPosCpo     := {}
Local _aSizes      := {}
Local _aCampos     := {}
Local _aLinha      := {}
Local _aDados      := {}
Local _lReturn     := .F.
Local _lOk         := .T.
Local _cMsg        := ""
Local _aLog        := {}
Local _aCabecLog   := {"Processado","Filial","Pedido","Chave NFe","Retorno", "Recno SF2"}
Local _dDataIntTMS := SuperGetMV("IT_DTINTRD",.F.,CToD("25/10/2016"))
Local _cXmlNfe     := ""
Local _cProtNfe    := ""
Local _cXmlEnv     := ""
Local _cPart1Xml   := ""
Local _cPart2Xml   := ""
Local _nI          := 0
Local _nIni        := 0
Local _nFim        := 0
Local _cFilHabilit := SuperGetMV('IT_FILINTW',.F.,'') // Filiais habilitadas na integracao Webservice Italac x TMS Multi-Embarcador
Local _cTextoFim   := ""
Local _nEnviados   := 0
Local _nRecnoSF2   := 0
Local _nRecno54    := 0
Local _nRecno50    := 0

Begin Sequence 
   
   If !_lScheduler .And. ! U_ITMsg("Confirma a carga de registros para Enviar Arquivos XML NFe >> Italac <---> TMS Multi-Embarcador?","Inicio de processamento",,4,2,2) 
      Break
   EndIf

   _aAlias := AOMS144MA(_cAlias,_cAliasTMP, .T.,.T.,.T.)

   _aCabec  := _aAlias[1]
   _aPosCpo := _aAlias[2]
   _aSizes  := _aAlias[3]
   _aCampos := _aAlias[4]

   aAdd(_aCabec,"Recno SF2")
   aAdd(_aPosCpo,"NRECSF2")
   aAdd(_aSizes,10)
   aAdd(_aCampos,"NRECSF2")

   aAdd(_aCabec,"Recno 50")
   aAdd(_aPosCpo,"NREC50")
   aAdd(_aSizes,10)
   aAdd(_aCampos,"NREC50")

   aAdd(_aCabec,"Recno 54")
   aAdd(_aPosCpo,"NREC54")
   aAdd(_aSizes,10)
   aAdd(_aCampos,"NREC54")

   aAdd(_aCabec,"Recno DAK")
   aAdd(_aPosCpo,"NRECDAK")
   aAdd(_aSizes,10)
   aAdd(_aCampos,"NRECDAK")

   If !_lScheduler
      ProcRegua(0)
      IncProc("Lendo dados da SPED50/SF2...")
   EndIf
   
   //===================================================================================================
   // Montagem de query com os numeros de registros das notas fiscais a serem enviadas para o RDC.
   //===================================================================================================
   _cQry := " SELECT SF2.* ,SPED50.R_E_C_N_O_ NREC50, SF2.R_E_C_N_O_ NRECSF2, SPED54.R_E_C_N_O_ NREC54, DAK.R_E_C_N_O_ NRECDAK, DAK.DAK_I_LEMB   "
   _cQry += " FROM "+RetSqlName("SF2")+" SF2, SPED050 SPED50, SPED054 SPED54, "+RetSqlName("DAK")+" DAK "
   _cQry += " WHERE SF2.D_E_L_E_T_ = ' ' "
   _cQry += "   AND SPED50.D_E_L_E_T_ = ' ' "
   _cQry += "   AND SPED54.D_E_L_E_T_ = ' ' "
   _cQry += "   AND DAK.D_E_L_E_T_ = ' ' "
   _cQry += "   AND F2_I_SITUA = ' ' "
   _cQry += "   AND DOC_CHV = F2_CHVNFE "
   _cQry += "   AND NFE_CHV = F2_CHVNFE "
   _cQry += "   AND F2_ESPECIE = 'SPED' "
   _cQry += "   AND F2_EMISSAO >= '" + DToS(_dDataIntTMS) + "' "
   _cQry += "   AND F2_CHVNFE <> ' ' "
   _cQry += "   AND SPED50.STATUS = '6' "
   _cQry += "   AND SPED54.CSTAT_SEFR = '100' "     
   _cQry += "   AND DAK_FILIAL = F2_FILIAL "
   _cQry += "   AND DAK_COD = F2_CARGA "
   _cQry += "   AND DAK_I_RECR <> ' ' " 
   _cQry += "   AND F2_FILIAL IN "+FormatIn(AllTrim(_cFilHabilit),";")
   _cQry += "   AND NOT EXISTS ( SELECT 'X' FROM "+RetSqlName("ZFK")+ " ZFK WHERE ZFK.D_E_L_E_T_ = ' ' AND ZFK.ZFK_TIPOI = '2' AND ZFK.ZFK_CHVNFE = SF2.F2_CHVNFE)"
   
   _cQry := ChangeQuery(_cQry)         

   If Select(_cAliasTMP) > 0
      (_cAliasTMP)->( DBCloseArea() )
   EndIf
   
   MPSysOpenQuery(_cQry,_cAliasTMP)
      
   DBSelectArea(_cAliasTMP)                                                                               
   COUNT To _nTotRegs

   If !_lScheduler 
      ProcRegua(_nTotRegs)
   EndIf

   _cTotal := AllTrim(Str(_nTotRegs))
                          
      DBSelectArea(_cAliasTMP)
      (_cAliasTMP)->(DBGoTop())
   
   If _nTotRegs > 0
      While !(_cAliasTMP)->(Eof()) 

         _nRegAtu++

         If !u_IT_TMS((_cAliasTMP)->DAK_I_LEMB )
            (_cAliasTMP)->(DBSkip())
            Loop
         EndIf

         If !_lScheduler 
            IncProc("Lendo dados de Carga - Registro : " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
         EndIf

         _aLinha := {}
         For _nI := 1 To Len(_aCampos)
            aAdd(_aLinha, &(_aCampos[_nI]))
         Next

         aAdd(_aDados,_aLinha)

         (_cAliasTMP)->(DBSkip())
         
      EndDo

      If _lScheduler
      
         _lReturn := .T.
      
      Else
      
         _cTitulo := "Cargas que foram geradas a partir de integração com o TMS Multiembarcador "
         _cMsgTop := _cTitulo

         If Len(_aDados) > 0
                     //ITListBox( _cTitAux , _aHeader    , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda ,_lHasOk,_bHeadClk,_aSX1)
            _lReturn := U_ITListBox( _cTitulo , _aCabec     , _aDados   , .T.      , 2      , _cMsgTop ,          , _aSizes ,         ,     ,        ,          ,       ,         ,          ,           ,          ,       ,         ,     )
         Else
            U_ITMsg(">> Carregamento concluído << "+Chr(10)+;
            "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
            "Atenção!!!",,3)
            Break
         EndIf

      EndIf

      If _lReturn
         
         //===================================================================================================
         // Abre o arquivo de Sped para leitura dos XML e Envio para o RDC.
         //===================================================================================================
         If Select("SPED050") > 0
            SPED050->( DBCloseArea() )
         EndIf     
         
         USE SPED050 ALIAS SPED050 SHARED NEW VIA "TOPCONN" 
         
         If Select("SPED054") > 0
            SPED054->( DBCloseArea() )
         EndIf     
         
         USE SPED054 ALIAS SPED054 SHARED NEW VIA "TOPCONN" 
         
         SC5->(DBSetOrder(1)) // C5_FILIAL+C5_NUM                                                                                                                                                

         For _nI := 1 To Len(_aDados)

            If _lScheduler   
               U_ItConout("[AOMS144G] Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)  
            Else
               IncProc("Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)   
            EndIf

            If _aDados[_nI][1] .Or. _lScheduler

               _nRecnoSF2 := _aDados[_nI][aScan(_aPosCpo,{|x|x="NRECSF2"})]
               _nRecno54  := _aDados[_nI][aScan(_aPosCpo,{|x|x="NREC54"})]
               _nRecno50  := _aDados[_nI][aScan(_aPosCpo,{|x|x="NREC50"})]
               _nRecnoDAK  := _aDados[_nI][aScan(_aPosCpo,{|x|x="NRECDAK"})]
               
               _cMsg := ""
               _lOk  := .T.

               SF2->(DBGoTo(_nRecnoSF2)) //Com a SF2 devidamente posicionada
               DAK->(DBGoTo(_nRecnoDAK))

               AOMS144VN(@_lOk,@_cMsg)

               If _lOk
                  
                  _nEnviados++ 

                  If _lScheduler
                     U_ItConout("[AOMS144G] Gravando Tabela Muro ZFK o arquivo XML: " +SPED050->DOC_CHV)
                  EndIf

                  SPED054->(DBGoTo(_nRecno54))
                  SPED050->(DBGoTo(_nRecno50))

                  _lSC5_PEDPA   := .F.

                  If !Empty(AllTrim(SF2->F2_I_PEDID ))
                     DBSelectArea("SC5")
                     SC5->( DBSetOrder(1) )
                     If SC5->( DBSeek( SF2->F2_FILIAL + SF2->F2_I_PEDID ) )
                        _lSC5_PEDPA   := (SC5->C5_I_PEDPA == "S")
                        _cSC5_I_CDTMS := SC5->C5_I_CDTMS
                     Else
                        _lSC5_PEDPA   := .F.
                        _cSC5_I_CDTMS := ""
                     EndIf
                  EndIf

                  //===================================================================================================
                  // Monta XML para envio ao RDC
                  //===================================================================================================   
                                 
                  _cXmlNfe := SPED050->XML_SIG
            
                  _cProtNfe := SPED054->XML_PROT
                                                         
            
                  _nIni := AT( "<infNFe", _cXmlNfe ) 
                  _nFim := AT( "</NFe>", _cXmlNfe ) 
                  _cPart1Xml := SubStr(_cXmlNfe,_nIni,_nFim - _nIni)
                                                            
                  _nIni := AT( "<protNFe", _cProtNfe ) 
                  _nFim := AT( "</protNFe>", _cProtNfe ) 
                  _cPart2Xml := SubStr(_cProtNfe,_nIni,_nFim + 11)
            
                  _cXmlEnv := '<?xml version="1.0" encoding="UTF-8"?> <nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="3.10"> <NFe>  '
                  _cXmlEnv := _cXmlEnv + _cPart1Xml + "</NFe>" + _cPart2Xml + '   </nfeProc> '
                  
                  _cXML_Nfe := _cXmlEnv

                  ZFK->(RecLock("ZFK",.T.))
                     ZFK->ZFK_FILIAL := SF2->F2_FILIAL
                     ZFK->ZFK_CARGA  := DAK->DAK_COD
                     ZFK->ZFK_CARTMS := DAK->DAK_I_RECR 
                     ZFK->ZFK_PRTPED := _cSC5_I_CDTMS
                     ZFK->ZFK_DATA   := Date()  
                     ZFK->ZFK_HORA   := Time()
                     ZFK->ZFK_TIPOI  := "2"
                     ZFK->ZFK_CHVNFE := SF2->F2_CHVNFE
                     ZFK->ZFK_PEDPAL := IIf(_lSC5_PEDPA ,"S","N") 
                     ZFK->ZFK_NRPPAL := IIf(_lSC5_PEDPA ,SF2->F2_I_PEDID ,"")    
                     ZFK->ZFK_CGC    := Posicione("SA1",1,xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA),"A1_CGC") 
                     ZFK->ZFK_PEDIDO := SC5->C5_NUM
                     ZFK->ZFK_COD	 := SF2->F2_CLIENTE    // Código Cliente    // SA2->A2_COD  - Fornecedor    // O correto é: A1_COD
                     ZFK->ZFK_LOJA   := SF2->F2_LOJA       // Loja Cliente      // SA2->A2_LOJA - Fornecedor    //              A1_LOJA
                     ZFK->ZFK_NOME   := Posicione("SA1",1,xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA),"A1_NOME")   // Nome Cliente      // SA2->A2_NOME - Fornecedor   //              A1_NOME
                     ZFK->ZFK_USUARI := __cUserId
                     ZFK->ZFK_SITUAC := "N" 
                     ZFK->ZFK_XML    := _cXML_Nfe
                  ZFK->(MSUnLock())

                  _cMsg := "Carregado para Integração"

               Else
               
                  SF2->(RecLock("SF2",.F.))
                     SF2->F2_I_SITUA := 'N'    
                     SF2->F2_I_DTENV := Date()
                     SF2->F2_I_HRENV := Time()
                  SF2->(MSUnLock())
                     
               EndIf
               
               aAdd(_aLog,{_lOk, SF2->F2_FILIAL,SC5->C5_NUM,SF2->F2_CHVNFE,_cMsg,SF2->(Recno())})

            EndIf

         Next _nI

         _cTextoFim := "Notas Fiscais carregadas para Enviar Arquivo XML NFe : "+Str(_nEnviados)+Chr(10)

         U_ItConout("[AOMS144G] >> Carregamento concluído << Italac <---> TMS Multi-Embarcador "+_cTextoFim)
         
         If !_lScheduler
            U_ITMsg(">> Carregamento concluído << "+Chr(10)+;
                  "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+_cTextoFim+Chr(10),;
                  "Fim de Carregamento",,2)
            
            If Len(_aLog) > 0

               U_ITListBox( 'Log de Processamento do carregamento de registros para Enviar Arquivos XML NFe',;
               _aCabecLog, _aLog , .T. , 1 ,;
               "Abaixo segue a relação de Carregamento" )

            EndIf
         EndIf
      EndIf
   Else
      If _lScheduler
         ConOut("[AOMS144G] - Não foram encontrados dados para integração." )
      Else
         U_ITMsg(">> Processamento concluído << "+Chr(10)+;
         "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
         "Atenção",,3)
      EndIf
   EndIf

End Sequence

If Select(_cAliasTMP) > 0
   (_cAliasTMP)->( DBCloseArea() )
EndIf

If Select("SPED050") > 0
   SPED050->( DBCloseArea() )
EndIf     

If Select("SPED054") > 0
   SPED054->( DBCloseArea() )
EndIf  

Return

/*
===============================================================================================================================
Programa----------: AOMS144H
Autor-------------: Igor Melgaço
Data da Criacao---: 23/01/2024
Descrição---------: Rotina para carga de registros para Informar Cancelamento >> Italac <---> TMS Multi-Embarcador
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function AOMS144H()

Local _cQry          := ""
Local _cTimeIni      := Time()
Local _nTotRegs      := 0
Local _cTotal        := ""
Local _cFilHabilit   := SuperGetMV('IT_FILINTW',.F.,'') // Filiais habilitadas na integracao Webservice Italac x TMS Multi-Embarcador
Local _lOk           := .T.
Local _aLog          := {}
Local _aCabecLog     := {"Processado","Filial","Chave NFe","Retorno", "Recno SF2"}
Local _cMsg          := ""
Local _nEnviados     := 0

Local _cAliasTMP     := "TRBAOMS144H"
Local _cAlias        := "SF2"
Local _nRegAtu       := 0
Local _aCabec        := {}
Local _aPosCpo       := {}
Local _aSizes        := {}
Local _aCampos       := {}
Local _aDados        := {}
Local _nI            := 0

Local _nRecnoSF2 := 0
Local _nRecno54 := 0

Begin Sequence 
   
   If !_lScheduler .And. ! U_ITMsg("Confirma carga de registros para Informar Cancelamento de Nota Fiscal >> Italac <---> TMS Multi-Embarcador?","Inicio de processamento",,4,2,2) 
      Break
   EndIf

   _aAlias := AOMS144MA(_cAlias,_cAliasTMP, .T.,.T.,.T.)

   _aCabec  := _aAlias[1]
   _aPosCpo := _aAlias[2]
   _aSizes  := _aAlias[3]
   _aCampos := _aAlias[4]

   aAdd(_aCabec,"Recno SF2")
   aAdd(_aPosCpo,"NRECSF2")
   aAdd(_aSizes,10)
   aAdd(_aCampos,"NRECSF2")

   aAdd(_aCabec,"Recno 54")
   aAdd(_aPosCpo,"NREC54")
   aAdd(_aSizes,10)
   aAdd(_aCampos,"NREC54")

   If !_lScheduler
      ProcRegua(0)
      IncProc("Lendo dados da SPED50/SF2...")
   EndIf
   
   //===================================================================================================
   // Montagem de query com os numeros de registros das notas fiscais a serem enviadas para o RDC.
   //===================================================================================================

   _cQry := " SELECT SF2.*,SF2.R_E_C_N_O_ NRECSF2, F2_FILIAL, F2_DOC, F2_SERIE, SPED054.R_E_C_N_O_ NREC54 "
   _cQry += " FROM SPED054, SPED001, SYS_COMPANY SM0, "+RetSqlName("SF2")+" SF2 "
   _cQry += " WHERE DTREC_SEFR >= TO_CHAR(SYSDATE -5,'YYYYMMDD') "
   _cQry += "   AND CSTAT_SEFR = '101' "
   _cQry += "   AND SPED054.D_E_L_E_T_ = ' ' "
   _cQry += "   AND SPED001.D_E_L_E_T_ = ' ' "
   _cQry += "   AND SM0.D_E_L_E_T_ = ' ' "
   _cQry += "   AND SPED001.IE = SM0.M0_INSC "
   _cQry += "   AND SPED001.ID_ENT = SPED054.ID_ENT "
   _cQry += "   AND SM0.M0_CGC = SPED001.CNPJ "
   _cQry += "   AND F2_FILIAL = M0_CODFIL "
   _cQry += "   AND F2_SERIE = SubStr (NFE_ID, 1, 3) "
   _cQry += "   AND F2_DOC = SubStr (NFE_ID, 4, 9) "
   _cQry += "   AND F2_I_SITUA = 'P' "
   _cQry += "   AND F2_I_PRTMS <> ' '  "
   _cQry += "   AND F2_FILIAL IN "+FormatIn(AllTrim(_cFilHabilit),";")

   _cQry := ChangeQuery(_cQry)         

   If Select(_cAliasTMP) > 0
      (_cAliasTMP)->( DBCloseArea() )
   EndIf

   MPSysOpenQuery(_cQry,_cAliasTMP)
                                                                                  
   COUNT To _nTotRegs

   If !_lScheduler
      ProcRegua(_nTotRegs)
   EndIf

   _cTotal := AllTrim(Str(_nTotRegs))
                          
   (_cAliasTMP)->(DBGoTop())

   If _lScheduler   
      U_ItConout("[AOMS144H] Programa AOMS144, gerando registros para Informar Cancelamento de Nota Fiscal >> Italac <---> TMS Multi-Embarcador.")
      U_ItConout("[AOMS144H] Data: "+DToC(Date())+" Hora: "+Time())
      U_ItConout("[AOMS144H] Total de registros: "+Str(_nTotRegs,8))
   EndIf

   While !(_cAliasTMP)->(Eof()) 

      _nRegAtu++

      DAK->(DBSetOrder(1)) // DAK_FILIAL+DAK_COD
      If DAK->(DBSeek(SF2->F2_FILIAL+SF2->F2_CARGA))
         If !u_IT_TMS(DAK->DAK_I_LEMB )
            (_cAliasTMP)->(DBSkip())
            Loop
         EndIf
      EndIf

      If !_lScheduler 
         IncProc("Lendo dados de Carga - Registro : " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
      EndIf

      _aLinha := {}
      For _nI := 1 To Len(_aCampos)
         aAdd(_aLinha, &(_aCampos[_nI]))
      Next

      aAdd(_aDados,_aLinha)

      (_cAliasTMP)->(DBSkip())
      
   EndDo

   If _lScheduler
   
      _lReturn := .T.
   
   Else
   
      _cTitulo := "Cargas que foram geradas a partir de integração com o TMS Multiembarcador "
      _cMsgTop := _cTitulo

      If Len(_aDados) > 0
                  //ITListBox( _cTitAux , _aHeader    , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda ,_lHasOk,_bHeadClk,_aSX1)
         _lReturn := U_ITListBox( _cTitulo , _aCabec     , _aDados   , .T.      , 2      , _cMsgTop ,          , _aSizes ,         ,     ,        ,          ,       ,         ,          ,           ,          ,       ,         ,     )
      Else
         U_ITMsg(">> Carregamento concluído << "+Chr(10)+;
         "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
         "Atenção!!!",,3)
         Break
      EndIf
   EndIf

   If _lReturn
      //===================================================================================================
      // Abre o arquivo de Sped para leitura dos XML e Envio para o RDC.
      //===================================================================================================
      If Select("SPED001") > 0
         SPED001->( DBCloseArea() )
      EndIf     
      
      USE SPED001 ALIAS SPED001 SHARED NEW VIA "TOPCONN" 
      
      If Select("SPED054") > 0
         SPED054->( DBCloseArea() )
      EndIf     
      
      USE SPED054 ALIAS SPED054 SHARED NEW VIA "TOPCONN" 
      
      SC5->(DBSetOrder(1)) // C5_FILIAL+C5_NUM                                                                                                                                                

      _cTotal := AllTrim(Str(Len(_aDados)))

      For _nI := 1 To Len(_aDados)

         If _lScheduler   
            U_ItConout("[AOMS144H] Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)  
         Else
            IncProc("Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)   
         EndIf

         If _aDados[_nI][1] .Or. _lScheduler
            
            _nRecnoSF2 := _aDados[_nI][aScan(_aPosCpo,{|x|x="NRECSF2"})]
            _nRecno54 := _aDados[_nI][aScan(_aPosCpo,{|x|x="NREC54"})]

            _cMsg := ""
            _lOk  := .T.

            SF2->(DBGoTo(_nRecnoSF2))

            AOMS144VN(@_lOk,@_cMsg) //Com a SF2 devidamente posicionada

            If _lOk
               
               _nEnviados++

               SPED054->(DBGoTo(_nRecno54))

               _cProtNfe := SPED054->XML_PROT

               ZFK->(RecLock("ZFK",.T.))
                  ZFK->ZFK_FILIAL := SF2->F2_FILIAL
                  ZFK->ZFK_DATA   := Date()  
                  ZFK->ZFK_HORA   := Time()
                  ZFK->ZFK_TIPOI  := "3"
                  ZFK->ZFK_CHVNFE := SF2->F2_CHVNFE
                  ZFK->ZFK_PEDPAL := IIf(SC5->C5_I_PEDPA == "S","S","N")  
                  ZFK->ZFK_CGC    := Posicione("SA1",1,xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA),"A1_CGC") 
                  ZFK->ZFK_PEDIDO := SC5->C5_NUM
                  ZFK->ZFK_COD	 := SF2->F2_CLIENTE    // Código Cliente    // SA2->A2_COD  - Fornecedor    // O correto é: A1_COD
                  ZFK->ZFK_LOJA   := SF2->F2_LOJA       // Loja Cliente      // SA2->A2_LOJA - Fornecedor    //              A1_LOJA
                  ZFK->ZFK_NOME   := Posicione("SA1",1,xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA),"A1_NOME")   // Nome Cliente      // SA2->A2_NOME - Fornecedor   //              A1_NOME
                  ZFK->ZFK_USUARI := __cUserId
                  ZFK->ZFK_SITUAC := "N" 
                  ZFK->ZFK_XML    := _cProtNfe
               ZFK->(MSUnLock())

               _cMsg := "Carregado para Integração"

            Else
            
               SF2->(RecLock("SF2",.F.))
                  SF2->F2_I_SITUA := 'N'    
                  SF2->F2_I_DTENV := Date()
                  SF2->F2_I_HRENV := Time()
               SF2->(MSUnLock())
                  
            EndIf

            aAdd(_aLog,{_lOk, SF2->F2_FILIAL,SF2->F2_I_PEDID,SF2->F2_CHVNFE,_cMsg,SF2->(Recno())})

         EndIf
         
      Next

      _cTextoFim := "Notas Fiscais carregadas para Informar Cancelamento: "+Str(_nEnviados)+Chr(10)

      U_ItConout("[AOMS144H] >> Carregamento concluído << Italac <---> TMS Multi-Embarcador "+_cTextoFim)
      
      If !_lScheduler
         U_ITMsg(">> Carregamento concluído << "+Chr(10)+;
               "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+_cTextoFim+Chr(10),;
               "Fim de Carregamento",,2)
         
         If Len(_aLog) > 0

            U_ITListBox( 'Log de Processamento do carregamento de registros para Informar Cancelamento de Nota Fiscal',;
            _aCabecLog, _aLog , .T. , 1 ,;
            "Abaixo segue a relação de Carregamento" )

         EndIf
      EndIf
   EndIf
End Sequence

If Select(_cAliasTMP) > 0
   (_cAliasTMP)->( DBCloseArea() )
EndIf

If Select("SPED001") > 0
   SPED001->( DBCloseArea() )
EndIf     

If Select("SPED054") > 0
   SPED054->( DBCloseArea() )
EndIf     

Return

/*
===============================================================================================================================
Programa----------: AOMS144F
Autor-------------: Igor Melgaço
Data da Criacao---: 15/02/2024
Descrição---------: Rotina de envio do XML para o sistema TMS Multi-Embarcador.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function AOMS144F

Local _cQry          := ""
Local _cAliasTMP     := "TRBAOMS144F"
Local _cAlias        := "ZFK"
Local _cTimeIni      := Time()
Local _nI            := 0
Local _nRegAtu       := 0
Local _nTotRegs      := 0
Local _nEnviados     := 0
Local _aDados        := {}
Local _aSizes        := {}
Local _aCabec        := {}
Local _aAlias        := {}
Local _aCampos       := {}
Local _aLinha        := {}
Local _aPosCpo       := {}
Local _cToken        := ""
Local _cLink         := ""
Local _cXML          := ""
Local _cCodEmpWS     := SuperGetMV('IT_EMPTMSM',.F.,"000005")
Local _aLog          := {}
Local _aCabecLog        := {"Processado","Filial","Pedido","Chave NFe","Retorno", "Recno ZFK"}
Local _cTextoFim     := ""
Local _lOk           := .F.
Local _cResult       := ""
Local _cFilHabilit      := SuperGetMV('IT_FILINTW',.F.,'')
Local _cProtocolo    := ""
Local _nPosi         := 0
Local _nPosf         := 0
Local _cXML_Nfe      := ""
Local _nRecnoZFK     := 0
Local oWsdl

Begin Sequence 
   
   If !_lScheduler .And. ! U_ITMsg("Confirma envio de arquivos XML das NFe >> Italac <---> TMS Multi-Embarcador?","Inicio de processamento",,4,2,2) 
      Break
   EndIf

   _aAlias := AOMS144MA(_cAlias,_cAliasTMP, .T.,.T.,.T.)

   _aCabec  := _aAlias[1]
   _aPosCpo := _aAlias[2]
   _aSizes  := _aAlias[3]
   _aCampos := _aAlias[4]

   //===================================================================================================
   // Montagem de query com os numeros de registros das notas fiscais a serem enviadas para o RDC.
   //===================================================================================================
   _cQry := " SELECT ZFK.*, ZFK.R_E_C_N_O_ R_E_C_N_O_ "
   _cQry += " FROM "+RetSqlName("ZFK")+" ZFK "
   _cQry += " WHERE ZFK.D_E_L_E_T_ = ' ' "
   _cQry += "   AND ZFK_TIPOI = '2' "
   _cQry += "   AND (ZFK_SITUAC = 'N' OR  ZFK_SITUAC = 'R') "
   _cQry += "   AND ZFK_FILIAL IN "+FormatIn(AllTrim(_cFilHabilit),";")

   _cQry := ChangeQuery(_cQry)          

   If Select(_cAliasTMP) > 0
      (_cAliasTMP)->( DBCloseArea() )
   EndIf

   MPSysOpenQuery(_cQry,_cAliasTMP)
   
   DBSelectArea(_cAliasTMP)                                                                                  
   COUNT To _nTotRegs

   If !_lScheduler
      ProcRegua(_nTotRegs)
   EndIf

   _cTotal := AllTrim(Str(_nTotRegs))

   If _nTotRegs > 0

      DBSelectArea(_cAliasTMP)                       
      (_cAliasTMP)->(DBGoTop())

      While !(_cAliasTMP)->(Eof()) 

         _nRegAtu++

         If !_lScheduler 
            IncProc("Lendo dados de Carga - Registro : " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
         EndIf

         _aLinha := {}
         For _nI := 1 To Len(_aCampos)
            aAdd(_aLinha, &(_aCampos[_nI]))
         Next

         aAdd(_aDados,_aLinha)

         (_cAliasTMP)->(DBSkip())
         
      EndDo
      
      If _lScheduler
      
         _lReturn := .T.
      
      Else
      
         _cTitulo := "Cargas que foram geradas a partir de integração com o TMS Multiembarcador "
         _cMsgTop := _cTitulo

         If Len(_aDados) > 0
                     //ITListBox( _cTitAux , _aHeader    , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda ,_lHasOk,_bHeadClk,_aSX1)
            _lReturn := U_ITListBox( _cTitulo , _aCabec     , _aDados   , .T.      , 2      , _cMsgTop ,          , _aSizes ,         ,     ,        ,          ,       ,         ,          ,           ,          ,       ,         ,     )
         Else
            U_ITMsg(">> Carregamento concluído << "+Chr(10)+;
            "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
            "Atenção!!!",,3)
            Break
         EndIf
      EndIf

      If _lReturn

         //=====================================================================
         // Obtem o token de acesso ao sistema multi embarcador.
         //=====================================================================
         _cToken := SuperGetMV('IT_TOKMUTE',.F.,"a78e0523d3794843855e8d95c2bff8d4")

         If !_lScheduler 
            ProcRegua(Len(_aDados))
         EndIf

         _cTotal := AllTrim(Str(Len(_aDados)))

         For _nI := 1 To Len(_aDados)
            
            If _lScheduler   
               U_ItConout("[AOMS144F] Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)  
            Else
               IncProc("Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)   
            EndIf

            If _aDados[_nI][1] .Or. _lScheduler

               Begin Sequence

                  _nRecnoZFK := _aDados[_nI][aScan(_aPosCpo,{|x|x="R_E_C_N_O_"})]

                  ZFK->(DBGoTo(_nRecnoZFK))   

                  ZFM->(DBSetOrder(1))
                  If ZFM->(DBSeek(ZFK->ZFK_FILIAL+_cCodEmpWS))
                     //_cDirXML := ZFM->ZFM_LOCXML 
                     _cLink   := AllTrim(ZFM->ZFM_LINK02)
                  Else
                     _cMsg := "Empresa WebService para envio dos dados não localizada. Tabela ZFM."     
                     If !_lScheduler
                        U_ITMsg(_cMsg,"Atenção",,1)
                     Else
                        U_ITCONOUT("[AOMS144F] "+_cMsg)
                     EndIf
                     _lOk := .F.
                     Break   
                  EndIf                        

                  If Empty(_cLink)
                     _cMsg := "O Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+"."
                     If !_lScheduler
                        U_ITMsg(_cMsg,"Atenção",,1)
                     Else
                        U_ItConout("[AOMS144F] "+_cMsg)
                     EndIf
                     _lOk := .F.
                     Break                                     
                  EndIf

                  DBSelectArea("SF2")
                  DBSetOrder(21)
                  If DBSeek(ZFK->ZFK_CHVNFE)

                     If ! _lScheduler
                        IncProc("Integrando a Chave NFe: "+ZFK->ZFK_CHVNFE)                    
                     Else
                        u_itconout("[AOMS144F] Integrando a Chave NFe: "+ZFK->ZFK_CHVNFE) 
                     EndIf  
                     
                     _cXML_Nfe := ZFK->ZFK_XML 

                     _cXml := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                     _cXml += '   <soapenv:Header>'
                     _cXml += '      <Token xmlns="Token">'+Eval({|| FWHttpEncode(AllTrim(_cToken))})+'</Token>'
                     _cXml += '   </soapenv:Header>'
                     _cXml += '   <soapenv:Body>'
                     _cXml += '      <tem:EnviarArquivoXMLNFe>'
                     _cXml += '<tem:arquivo>'+Eval({|| Encode64(AllTrim(_cXML_Nfe))})+'</tem:arquivo>'
                     _cXml += '      </tem:EnviarArquivoXMLNFe>'
                     _cXml += '   </soapenv:Body>'
                     _cXml += '</soapenv:Envelope>'

                     _nIniCarre := 1   // Inicio da leitura das cargas pendentes no TMS.
                     _nLimCarre := 100 // Número Máximo de Registros Lidos.

                     oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.
                     oWsdl:nTimeout := 10          // Timeout de 10 segundos 
                     oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo                                                                    

                     oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.  
                     oWsdl:SetOperation( "EnviarArquivoXMLNFe") // Define qual operação será realizada.

                     // Envia para o servidor
                     _lOk := oWsdl:SendSoapMsg(_cXML) // Este comando pega o XML e envia para o servidor da RDC.  
                        
                     If _lOk 
                        _cResult := oWsdl:GetSoapResponse()

                        _nPosi := AT("<a:Objeto>", _cResult)
                        _nPosf := AT("</a:Objeto>", _cResult)	
                        
                        If _nPosi == 0
                           _cProtocolo := ""
                        Else
                           _cProtocolo := SubStr(_cresult,_nposi+Len("<a:Objeto>"),_nposf-_nposi-Len("<a:Objeto>"))
                        EndIf
                        
                        _cResult := "Integração Processada"
                     Else
                        _cResult := oWsdl:cError
                        _cProtocolo := ""
                     EndIf   

                     If _lOk 
                        SF2->(RecLock("SF2",.F.))
                           SF2->F2_I_SITUA := 'P'    
                           SF2->F2_I_DTENV := Date()
                           SF2->F2_I_HRENV := Time()
                           SF2->F2_I_PRTMS := _cProtocolo      //Protocolo TMS
                        SF2->(MSUnLock())
                        _nEnviados++
                     EndIf 

                     ZFK->(RecLock("ZFK",.F.))
                        ZFK->ZFK_DATA   := Date()  
                        ZFK->ZFK_HORA   := Time()
                        ZFK->ZFK_SITUAC := IIf(_lOk,"P","R")
                        ZFK->ZFK_CODEMP := _cCodEmpWS
                        ZFK->ZFK_RETORN := _cResult
                        ZFK->ZFK_PRTMS  := _cProtocolo
                        If _lOk
                           ZFK->ZFK_XML    := _cXML
                        EndIf
                     ZFK->(MSUnLock())

                     _cMsg := _cResult

                  Else
                     _lOk  := .F.
                     _cMsg := "Não encontrado a Nota da Chave "+ ZFK->ZFK_CHVNFE +" gravada na ZFK referente ao Recno "+AllTrim(Str(_nRecnoZFK))
                     If _lScheduler   
                        U_ItConout("[AOMS144F] "+_cMsg)  
                     Else
                        IncProc(_cMsg)   
                     EndIf
                  EndIf   
                     
               End Sequence

               aAdd(_aLog,{_lOk, ZFK->ZFK_FILIAL,ZFK->ZFK_PEDIDO,ZFK->ZFK_CHVNFE,_cMsg,ZFK->(Recno())})
               Sleep(100) //Espera para não travar a comunicação com o webservice da TMS

            EndIf
               
            FreeObj(oWsdl)

         Next

      EndIf

      _cTextoFim := "Arquivos XML NFe enviados pelo método EnviarArquivoXMLNFe: "+Str(_nEnviados)+Chr(10)

      If _lScheduler
         U_ItConout("[AOMS144F] >> Processamento concluído << Italac <---> TMS Multi-Embarcador "+_cTextoFim)
      Else
         U_ITMsg(">> Processamento concluído << "+Chr(10)+;
               "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+_cTextoFim+Chr(10),;
               "Fim de processamento",,2)
         
         If Len(_aLog) > 0

            U_ITListBox( 'Log de Processamento da Integração',;
            _aCabecLog, _aLog , .T. , 1 ,;
            "Abaixo segue a relação de processamento do método EnviarArquivoXMLNFe" )

         EndIf
      EndIf

   Else
      If _lScheduler
         ConOut("[AOMS144F] - Não foram encontrados dados para integração." )
      Else
         U_ITMsg(">> Processamento concluído << "+Chr(10)+;
         "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
         "Atenção",,3)
      EndIf
   EndIf

End Sequence

If Select(_cAliasTMP) > 0
   (_cAliasTMP)->( DBCloseArea() )
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS144Y
Autor-------------: Igor Melgaço
Data da Criacao---: 23/01/2024
Descrição---------: Rotina de Informar Cancelamento para o sistema TMS Multi-Embarcador.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function AOMS144Y()

Local _cQry          := ""
Local _cTimeIni      := Time()
Local _nTotRegs      := 0
Local _nEnviados     := 0
Local _cLink         := ""
Local _cCodEmpWS     := SuperGetMV('IT_EMPTMSM',.F.,"000005")
Local _cToken        := ""
Local _cXML          := ""
Local _cResult       := ""
Local _cProtocolo    := ""
Local _nPosi         := 0
Local _nPosf         := 0
Local _lOk           := .F.
Local _cProtNfe      := ""
Local _aLog          := {}
Local _aCabecLog        := {"Processado","Filial","Pedido","Chave NFe","Retorno", "Recno ZFK"}
Local _cTextoFim     := ""
Local _aAlias   := {}
Local _cAliasTMP     := "TRBAOMS144Y"
Local _cAlias        := "ZFK"
Local _nRegAtu := 0
Local _aCabec  := {}
Local _aPosCpo := {}
Local _aSizes  := {}
Local _aCampos := {}
Local _aDados  := {}
Local _nI := 0
Local _cFilHabilit      := SuperGetMV('IT_FILINTW',.F.,'')
Local _nRecnoZFK := 0
Local oWSDL

Begin Sequence 
   
   If !_lScheduler .And. ! U_ITMsg("Confirma Informar Cancelamento de Nota Fiscal >> Italac <---> TMS Multi-Embarcador?","Inicio de processamento",,4,2,2) 
      Break
   EndIf

   _aAlias := AOMS144MA(_cAlias,_cAliasTMP, .T.,.T.,.T.)

   _aCabec  := _aAlias[1]
   _aPosCpo := _aAlias[2]
   _aSizes  := _aAlias[3]
   _aCampos := _aAlias[4]

   //===================================================================================================
   // Montagem de query com os numeros de registros das notas fiscais a serem enviadas para o RDC.
   //===================================================================================================
   _cQry := " SELECT ZFK.R_E_C_N_O_ R_E_C_N_O_ "
   _cQry += " FROM "+RetSqlName("ZFK")+" ZFK "
   _cQry += " WHERE ZFK.D_E_L_E_T_ = ' ' "
   _cQry += "   AND ZFK_TIPOI = '3' "
   _cQry += "   AND (ZFK_SITUAC = 'N' OR ZFK_SITUAC = 'R')"
   _cQry += "   AND ZFK_FILIAL IN "+FormatIn(AllTrim(_cFilHabilit),";")

   _cQry := ChangeQuery(_cQry)         

   If Select(_cAliasTMP) > 0
      (_cAliasTMP)->( DBCloseArea() )
   EndIf

   MPSysOpenQuery(_cQry,_cAliasTMP)

   DBSelectArea(_cAliasTMP)                                                                                
   COUNT To _nTotRegs

   If !_lScheduler
      ProcRegua(_nTotRegs)
   EndIf

   _cTotal := AllTrim(Str(_nTotRegs))

   If _nTotRegs > 0      
      DBSelectArea(_cAliasTMP)                    
      (_cAliasTMP)->(DBGoTop())

      While (_cAliasTMP)->(!Eof())

         _nRegAtu++

         If !_lScheduler 
            IncProc("Lendo dados de Carga - Registro : " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
         EndIf

         _aLinha := {}
         For _nI := 1 To Len(_aCampos)
            aAdd(_aLinha, &(_aCampos[_nI]))
         Next

         aAdd(_aDados,_aLinha)

         (_cAliasTMP)->(DBSkip())

      EndDo

      If _lScheduler
      
         _lReturn := .T.
      
      Else
      
         _cTitulo := "Cargas que foram geradas a partir de integração com o TMS Multiembarcador "
         _cMsgTop := _cTitulo

         If Len(_aDados) > 0
                     //ITListBox( _cTitAux , _aHeader    , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda ,_lHasOk,_bHeadClk,_aSX1)
            _lReturn := U_ITListBox( _cTitulo , _aCabec     , _aDados   , .T.      , 2      , _cMsgTop ,          , _aSizes ,         ,     ,        ,          ,       ,         ,          ,           ,          ,       ,         ,     )
         Else
            U_ITMsg(">> Carregamento concluído << "+Chr(10)+;
            "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
            "Atenção",,3)
            Break
         EndIf
      EndIf

      If _lReturn
         //=====================================================================
         // Obtem o token de acesso ao sistema multi embarcador.
         //=====================================================================
         _cToken := SuperGetMV('IT_TOKMUTE',.F.,"a78e0523d3794843855e8d95c2bff8d4")

         If !_lScheduler 
            ProcRegua(Len(_aDados))
         EndIf

         _cTotal := AllTrim(Str(Len(_aDados)))

         For _nI := 1 To Len(_aDados)

            If _lScheduler   
               U_ItConout("[AOMS144Y] Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)  
            Else
               IncProc("Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)   
            EndIf

            If _aDados[_nI][1] .Or. _lScheduler

               Begin Sequence

                  _nRecnoZFK := _aDados[_nI][aScan(_aPosCpo,{|x|x="R_E_C_N_O_"})]

                  ZFK->(DBGoTo(_nRecnoZFK))

                  ZFM->(DBSetOrder(1))
                  If ZFM->(DBSeek(ZFK->ZFK_FILIAL+_cCodEmpWS))
                     _cLink   := AllTrim(ZFM->ZFM_LINK02)
                  Else
                     _cMsg := "Empresa WebService para envio dos dados não localizada."     
                     If !_lScheduler
                        U_ITMsg(_cMsg,"Atenção",,1)
                     Else
                        U_ITCONOUT("[AOMS144Y] "+_cMsg)
                     EndIf
                     _lOk := .F.
                     Break     
                  EndIf
                  
                  If Empty(_cLink)
                     _cMsg := "O Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+"."
                     If !_lScheduler
                        U_ITMsg(_cMsg,"Atenção",,1)
                     Else
                        U_ItConout("[AOMS144Y] "+_cMsg)
                     EndIf
                     _lOk := .F.
                     Break                                     
                  EndIf

                  DBSelectArea("SF2")
                  DBSetOrder(21)
                  If DBSeek(ZFK->ZFK_CHVNFE)

                     If ! _lScheduler
                        IncProc("Informando o Cancelamento da Chave NFe: "+ZFK->ZFK_CHVNFE)                    
                     Else
                        u_itconout("[AOMS144Y] Informando o Cancelamento da Chave NFe: "+ZFK->ZFK_CHVNFE) 
                     EndIf  

                     _cProtNfe := ZFK->ZFK_XML

                     _nposi := AT( "<nProt>", _cProtNfe ) 
                     _nposf := AT( "</nProt>", _cProtNfe ) 

                     _cProtocolo := SubStr(_cProtNfe,_nposi+Len("<nProt>"),_nposf-_nposi-Len("<nProt>"))

                     _cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                     _cXML += '<soapenv:Header>'
                     _cXML += '<Token xmlns="Token">'+FWHttpEncode(AllTrim(_cToken))+'</Token>'
                     _cXML += '</soapenv:Header>'
                     _cXML += '<soapenv:Body>'
                     _cXML += '<tem:InformarCancelamentoNotaFiscal>'
                     _cXML += '<tem:protocoloNFe>'+ FWHttpEncode(AllTrim(_cProtocolo)) +'</tem:protocoloNFe>'
                     _cXML += '</tem:InformarCancelamentoNotaFiscal>'
                     _cXML += '</soapenv:Body>'
                     _cXML += '</soapenv:Envelope>'

                     _nIniCarre := 1   // Inicio da leitura das cargas pendentes no TMS.
                     _nLimCarre := 100 // Número Máximo de Registros Lidos.

                     oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.
                     oWsdl:nTimeout := 10          // Timeout de 10 segundos 
                     oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo                                                                    

                     //oWsdl:ParseURL( "http://10.3.0.201/wsitf18/Service.svc?wsdl") // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.  
                     oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.  
                     oWsdl:SetOperation( "InformarCancelamentoNotaFiscal") // Define qual operação será realizada.

                     _lOk := oWsdl:SendSoapMsg(_cXML) // Este comando pega o XML e envia para o servidor da RDC.  
                        
                     If _lOk 
                        _cResult := oWsdl:GetSoapResponse()

                        _nPosi := AT("<a:Objeto>", _cResult)             
                        _nPosf := AT("</a:Objeto>", _cResult)	
                        
                        If _nPosi == 0
                           _cProtocolo := ""
                        Else
                           _cProtocolo := SubStr(_cresult,_nposi+Len("<a:Objeto>"),_nposf-_nposi-Len("<a:Objeto>"))
                        EndIf

                        _cResult := "Integração Processada"
                     Else
                        _cResult := oWsdl:cError
                        _cProtocolo := ""
                     EndIf   

                     If _lOk 
                        SF2->(RecLock("SF2",.F.))
                           SF2->F2_I_SITUA := 'P'    
                           SF2->F2_I_DTENV := Date()
                           SF2->F2_I_HRENV := Time()
                        SF2->(MSUnLock())

                        _nEnviados++
                     EndIf 

                     ZFK->(RecLock("ZFK",.F.))
                        ZFK->ZFK_USUARI := __cUserId
                        ZFK->ZFK_SITUAC := IIf(_lOk,"P","R")
                        ZFK->ZFK_RETORN := _cResult
                        ZFK->ZFK_CODEMP := _cCodEmpWS
                        ZFK->ZFK_PRTMS  := _cProtocolo
                        ZFK->ZFK_XML    := _cXML
                     ZFK->(MSUnLock())

                     _cMsg := _cResult
                     
                  Else
                     _lOk := .F.
                     _cMsg := "Não encontrado a Nota da Chave "+ ZFK->ZFK_CHVNFE +" Gravada na ZFK referente ao Recno "+AllTrim(Str(_nRecnoZFK))
                     If _lScheduler
                        U_ItConout("[AOMS144Y] "+_cMsg)
                     Else
                        IncProc(_cMsg)
                     EndIf
                  EndIf

               End Sequence     

               aAdd(_aLog,{_lOk, ZFK->ZFK_FILIAL,ZFK->ZFK_PEDIDO,ZFK->ZFK_CHVNFE,_cMsg,ZFK->(Recno())})
               Sleep(100) //Espera para não travar a comunicação com o webservice da TMS
 
            EndIf

            FreeObj(oWsdl)

         Next

         _cTextoFim := "Notas Fiscais enviadas do método InformarCancelamentoNotaFiscal: "+Str(_nEnviados)+Chr(10)
         
         If _lScheduler
            U_ItConout("[AOMS144Y] >> Processamento concluído <<  Italac <---> TMS Multi-Embarcador "+_cTextoFim)
         Else
            U_ITMsg(">> Processamento concluído << "+Chr(10)+;
                  "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+_cTextoFim+Chr(10),;
                  "Fim de processamento",,2)

            If Len(_aLog) > 0

               U_ITListBox( 'Log de Processamento da Integração',;
               _aCabecLog, _aLog , .T. , 1 ,;
               "Abaixo segue a relação de processamento do  método InformarCancelamentoNotaFiscal" )

            EndIf

         EndIf
      EndIf
   Else
      If _lScheduler
         ConOut("[AOMS144F] - Não foram encontrados dados para integração." )
      Else
         U_ITMsg(">> Processamento concluído << "+Chr(10)+;
         "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
         "Atenção",,3)
      EndIf
   EndIf

End Sequence

If Select(_cAliasTMP) > 0
   (_cAliasTMP)->( DBCloseArea() )
EndIf

Return

/*
===============================================================================================================================
Programa----------: AOMS144VN
Autor-------------: Igor Melgaço
Data da Criacao---: 15/02/2024
Descrição---------: Valida dados da SF2, SC5 e DAK antes da Integração
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS144VN(_lOk,_cMsg)

Local _cFilHabilit   := SuperGetMV('IT_FILINTW',.F.,'') // Filiais habilitadas na integracao Webservice Italac x TMS Multi-Embarcador
Local _cListaFiliais := ""

_cListaFiliais := AllTrim(_cFilHabilit)                             
_cListaFiliais := StrTran(_cListaFiliais,";","','")    

//Com a SF2 devidamente posicionada
DAK->(DBSeek(SF2->F2_FILIAL+SF2->F2_CARGA))
SC5->(DBSeek(SF2->F2_FILIAL+SF2->F2_I_PEDID))

Begin Sequence

   If !(SF2->F2_FILIAL $ _cListaFiliais) // Ignora todas as filiais das notas fiscais que não estão no parâmetro e as filiais dos pedidos de origem da troca de nota que não estão no parâmetro.
      If Empty(SC5->C5_I_FLFNC) .Or. ! (SC5->C5_I_FLFNC $ _cListaFiliais) 
         _lOk := .F.
         _cMsg := "A Filial "+SC5->C5_I_FLFNC+" do pedido de venda "+SC5->C5_NUM+ " não está no parâmetro de filiais válidas para integração com o TMS"
         Break
      EndIf 
   EndIf
   
   If Empty(SC5->C5_I_FLFNC) // É um pedido de vendas normal. Não é um pedido de troca nota.
      // Validar a existência de cargas apenas para Pedidos de Vendas Normais.      
      If Empty(DAK->DAK_I_CARG)
         _lOk := .F.
         _cMsg := "O pedido de venda "+SC5->C5_NUM+ " pedido de vendas normal. Não é um pedido de troca nota e não existe cargas para ele."
         Break
      EndIf
   EndIf
   
   If AllTrim(SC5->C5_TIPO) <> "N" // Diferente de um pedido normal.
      _lOk := .F.
      _cMsg := "O pedido de venda "+SC5->C5_NUM+ " possui tipo (C5_TIPO) diferente de normal "
      Break
   EndIf
   
   If SC5->C5_I_TRCNF != "S" .And. Empty(DAK->DAK_I_CARG)  //Se não é troca nota e carga não foi montada pelo RDC 
      _lOk := .F.
      _cMsg := "Se não é troca nota e carga não foi montada pelo TMS "
      Break
   EndIf
   
   If SC5->C5_I_TRCNF == "S" .And. SC5->C5_NUM == SC5->C5_I_PDPR .And. Empty(DAK->DAK_I_CARG)  //Se é troca nota, pedido de carregamento e carga não foi montada pelo RDC 
      _lOk := .F.
      _cMsg := "Se é troca nota, pedido de carregamento e carga não foi montada pelo TMS"
      Break
   EndIf
   
   If SC5->C5_I_TRCNF == "S" .And. SC5->C5_NUM == SC5->C5_I_PDFT   //Se é troca nota, pedido de faturamento

      _nSC5 := SC5->(Recno())
      _nSF2 := SF2->(Recno())
      _nDAK := DAK->(Recno())
      
      _lOk := .F.
      
      If SC5->(DBSeek(SC5->C5_I_FLFNC+SC5->C5_I_PDPR))
      
         If SF2->(DBSeek(SC5->C5_FILIAL+SC5->C5_NOTA))
         
            If DAK->(DBSeek(SF2->F2_FILIAL+SF2->F2_CARGA))
            
               If !Empty(DAK->DAK_I_CARG) //Se achou a carga de carregamento e foi gerada pelo rdc deixa enviar o xml
               
                  _lOk := .T.
                  
               EndIf
               
            EndIf
            
         EndIf
         
         SC5->(DBGoTo(_nSC5))
         SF2->(DBGoTo(_nSF2))
         DAK->(DBGoTo(_nDAK))

         If !_lOk
            Break
         EndIf
      EndIf
   EndIf

End Sequence

Return 

/*
===============================================================================================================================
Programa----------: AOMS144VN
Autor-------------: Igor Melgaço
Data da Criacao---: 15/02/2024
Descrição---------: Valida dados da SF2, SC5 e DAK
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS144MA(_cAlias,_cAliasTmp,_lMark,_lFilial,_lRecno)

Local _aCabec := {}
Local _aPosCpo := {}
Local _aSizes := {}
Local _aCampos := {}
Local _nI := 0
Local _cAliasCMP := ""

Default  _lMark := .F.
Default  _lFilial := .F.
Default  _lRecno := .F.

Private aCols := {}
Private aHeader := {}

If _lMark
   aAdd(_aCabec,"")
   aAdd(_aPosCpo,"MARK")
   aAdd(_aSizes,10)
   aAdd(_aCampos,'.F.')
EndIf

If _lFilial
   If (_cAlias)->(FieldPos(_cAlias+"_FILIAL")) > 0
      _cAliasCMP := _cAlias
   Else
      _cAliasCMP := Subs(_cAlias,2,2)
   EndIf

   aAdd(_aCabec,"Filial")
   aAdd(_aPosCpo,_cAliasCMP+"_FILIAL")
   aAdd(_aSizes,10)
   aAdd(_aCampos,_cAliasCMP+"_FILIAL")
EndIf

aHeader := {}
FillGetDados(1,_cAlias,1,,,{||.T.},,,,,,.T.)

For _nI := 1 To Len(aHeader)

   If X3USO(GetSx3Cache(aHeader[_nI,2],"X3_USADO")) .And. cNivel >= GetSx3Cache(aHeader[_nI,2],"X3_NIVEL") .And. !(GetSx3Cache(aHeader[_nI,2],"X3_TIPO") = "M") .And. GetSx3Cache(aHeader[_nI,2],"X3_BROWSE") == "S"

      If AllTrim(GetSx3Cache(aHeader[_nI,2],"X3_CONTEXT"))  == "V"
         aAdd(_aCampos,StrTran(AllTrim(GetSx3Cache(aHeader[_nI,2],"X3_INIBRW")),"DAK->",_cAliasTmp+"->"))
      Else
         If AllTrim(GetSx3Cache(aHeader[_nI,2],"X3_TIPO")) == "D"
            aAdd(_aCampos,"SToD("+AllTrim(GetSx3Cache(aHeader[_nI,2],"X3_CAMPO"))+")")
         Else
            aAdd(_aCampos,AllTrim(GetSx3Cache(aHeader[_nI,2],"X3_CAMPO")))
         EndIf
      EndIf
      
      aAdd(_aPosCpo,AllTrim(GetSx3Cache(aHeader[_nI,2],"X3_CAMPO")))
      aAdd(_aCabec ,AllTrim(GetSx3Cache(aHeader[_nI,2],"X3_TITULO")))
      aAdd(_aSizes ,GetSx3Cache(aHeader[_nI,2],"X3_TAMANHO")* 3)
   EndIf
Next

If _lRecno
   aAdd(_aCabec,"Recno")
   aAdd(_aPosCpo,"R_E_C_N_O_")
   aAdd(_aSizes,10)
   aAdd(_aCampos,"R_E_C_N_O_")
EndIf

Return {_aCabec,_aPosCpo,_aSizes,_aCampos,}

/*
===============================================================================================================================
Programa----------: AOMS144B
Autor-------------: Igor Melgaço
Data da Criacao---: 23/01/2024
Descrição---------: Rotina de Informar Cancelamento de Nota Fiscal para o sistema TMS Mulit-Embarcador.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS144B()

If _lScheduler 
   //=====================================================================
   // Limpa o ambiente, liberando a licença e fechando as conexões
   //=====================================================================
   RpcClearEnv() 
   RpcSetType(2)
   
   //================================================================================
   // Prepara ambiente abrindo tabelas e incializando variaveis.
   //================================================================================   
   //PREPARE ENVIRONMENT EMPRESA '01' FILIAL "01"; 
   //        TABLES "CKO","ZG0","SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6","ZP1";
   //        MODULO 'OMS'
   RpcSetEnv("01", "01",,,,, {"CKO","ZG0","SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6","ZP1"})
   
   cFilAnt := "01"
      
   AOMS144R()
   AOMS144K()

   //============================================================
   //Limpa o ambiente, liberando a licença e fechando as conexoes
   //============================================================
   RpcClearEnv() 
   
Else
   
   Processa( {|| AOMS144R(),AOMS144K()},"Hora Ini: "+Time()+", Aguarde...")
   
EndIf

Return .F.

/*
===============================================================================================================================
Programa----------: AOMS144R
Autor-------------: Igor Melgaço
Data da Criacao---: 23/01/2024
Descrição---------: Rotina de carga de dados das Cargas para Integração de Notas Fiscais
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS144R()

Local _cQuery      := ""
Local _cTimeIni    := Time()
Local _cAlias      := "DAK"
Local _cAliasTMP   := "TRBAOMS144R"
Local _aAlias      := {}
Local _nRegAtu     := 0
Local _nTotRegs    := 0
Local _aCabec      := {}
Local _aPosCpo     := {}
Local _aSizes      := {}
Local _aCampos     := {}
Local _aLinha      := {}
Local _aDados      := {}
Local _lReturn     := .F.
Local _cMsg        := ""
Local _aLog        := {}
Local _aCabecLog   := {"Processado","Filial","Pedido","Chave NFe","Retorno", "Recno SF2"}
Local _cTextoFim     := ""
Local _nEnviados     := 0
Local _dDataIntTMS   := SuperGetMV("IT_DTINTMS",.F.,Ctod("01/01/2024"))
Local _nI          := 0
Local _cTitulo     := ""
Local _cMsgTop     := ""
Local _cCodEmpWS   := SuperGetMV('IT_EMPTMSM',.F.,"000005")
Local _cFilHabilit := SuperGetMV('IT_FILINTW',.F.,'')

Begin Sequence

   If !_lScheduler .And. ! U_ITMsg("Confirma carga de registros para Liberar Emissao Sem NFe >> Italac <---> TMS Multi-Embarcador?","Inicio de processamento",,4,2,2) 
      Break
   EndIf

   _aAlias := AOMS144MA(_cAlias,_cAliasTMP, .T.,.T.,.T.)

   _aCabec  := _aAlias[1]
   _aPosCpo := _aAlias[2]
   _aSizes  := _aAlias[3]
   _aCampos := _aAlias[4]

   _cQuery := "   SELECT DAK.*,   "
   _cQuery += "          DAK.R_E_C_N_O_ R_E_C_N_O_   "
   _cQuery += "   FROM DAK010 DAK   "
   _cQuery += "  WHERE DAK.DAK_FILIAL IN ('" + StrTran(AllTrim(_cFilHabilit) ,";","','") + "') "
   _cQuery += "      AND DAK.DAK_DATA >= '" + DToS(_dDataIntTMS) + "' "
   _cQuery += "     AND DAK.DAK_I_TRNF IN (' ',   "
   _cQuery += "                            'N')   "
   _cQuery += "     AND DAK.D_E_L_E_T_ = ' '   "
   _cQuery += "     AND NVL (   "
   _cQuery += "                (SELECT COUNT (1)   "
   _cQuery += "                 FROM DAI010 DAI   "
   _cQuery += "                 WHERE DAI.DAI_FILIAL = DAK.DAK_FILIAL   "
   _cQuery += "                   AND DAI.DAI_COD = DAK.DAK_COD   "
   _cQuery += "                   AND DAI.D_E_L_E_T_ = ' ') , 0) = NVL (   "
   _cQuery += "                                                           (SELECT COUNT (1)   "
   _cQuery += "                                                            FROM DAI010 DAIB,   "
   _cQuery += "                                                                 SF2010 SF2A   "
   _cQuery += "                                                            WHERE DAIB.DAI_FILIAL = DAK.DAK_FILIAL   "
   _cQuery += "                                                              AND DAIB.DAI_COD = DAK.DAK_COD   "
   _cQuery += "                                                              AND DAIB.D_E_L_E_T_ = ' '   "
   _cQuery += "                                                              AND SF2A.F2_FILIAL = DAIB.DAI_FILIAL   "
   _cQuery += "                                                              AND SF2A.F2_DOC = DAIB.DAI_NFISCA   "
   _cQuery += "                                                              AND SF2A.F2_SERIE = DAIB.DAI_SERIE   "
   _cQuery += "                                                              AND SF2A.F2_I_SITUA = 'V'   "
   _cQuery += "                                                              AND SF2A.D_E_L_E_T_ = ' ') , 0)   "
   _cQuery += "     AND NOT EXISTS   "
   _cQuery += "       (SELECT 'X'   "
   _cQuery += "        FROM ZFK010 ZFKA   "
   _cQuery += "        WHERE ZFKA.ZFK_FILIAL = DAK.DAK_FILIAL   "
   _cQuery += "          AND ZFKA.ZFK_TIPOI = '5'   "
   _cQuery += "          AND ZFKA.ZFK_CARTMS = DAK.DAK_I_RECR   "
   _cQuery += "          AND ZFKA.ZFK_SITUAC = 'P'   "
   _cQuery += "          AND ZFKA.D_E_L_E_T_ = ' ')   "

   _cQuery += "   AND NOT EXISTS ( SELECT 'X' FROM "+RetSqlName("ZFK")+ " ZFKJ WHERE ZFKJ.D_E_L_E_T_ = ' ' AND ZFKJ.ZFK_TIPOI = '5' AND DAK.DAK_FILIAL = ZFKJ.ZFK_FILIAL AND DAK.DAK_COD = ZFKJ.ZFK_CARGA)"  
   _cQuery += "   UNION ALL   "
   _cQuery += "   SELECT DAKC.*,   "
   _cQuery += "          DAKC.R_E_C_N_O_ R_E_C_N_O_   "
   _cQuery += "   FROM DAK010 DAKC   "
   _cQuery += "   WHERE DAKC.DAK_FILIAL IN ('" + StrTran(AllTrim(_cFilHabilit) ,";","','") + "') "
   _cQuery += "     AND DAKC.DAK_DATA >= '" + DToS(_dDataIntTMS) + "' "
   _cQuery += "     AND DAKC.DAK_I_TRNF = 'C'   "
   _cQuery += "     AND DAKC.D_E_L_E_T_ = ' '   "
   _cQuery += "     AND NVL (   "
   _cQuery += "                (SELECT COUNT (1)   "
   _cQuery += "                 FROM DAI010 DAIC   "
   _cQuery += "                 WHERE DAIC.DAI_FILIAL = DAKC.DAK_FILIAL   "
   _cQuery += "                   AND DAIC.DAI_COD = DAKC.DAK_COD   "
   _cQuery += "                   AND DAIC.D_E_L_E_T_ = ' ') , 0) = NVL (   "
   _cQuery += "                                                            (SELECT COUNT (1)   "
   _cQuery += "                                                             FROM DAI010 DAIC,   "
   _cQuery += "                                                                  SF2010 SF2C   "
   _cQuery += "                                                             WHERE DAIC.DAI_FILIAL = DAKC.DAK_FILIAL   "
   _cQuery += "                                                               AND DAIC.DAI_COD = DAKC.DAK_COD   "
   _cQuery += "                                                               AND DAIC.D_E_L_E_T_ = ' '   "
   _cQuery += "                                                               AND SF2C.F2_FILIAL = DAIC.DAI_FILIAL   "
   _cQuery += "                                                               AND SF2C.F2_DOC = DAIC.DAI_NFISCA   "
   _cQuery += "                                                               AND SF2C.F2_SERIE = DAIC.DAI_SERIE   "
   _cQuery += "                                                               AND SF2C.F2_I_SITUA = 'V'   "
   _cQuery += "                                                               AND SF2C.D_E_L_E_T_ = ' ') , 0)   "
   _cQuery += "     AND NVL (   "
   _cQuery += "                (SELECT COUNT (1)   "
   _cQuery += "                 FROM DAI010 DAIf   "
   _cQuery += "                 WHERE DAIF.DAI_FILIAL = DAKC.DAK_I_FITN   "
   _cQuery += "                   AND DAIF.DAI_COD = DAKC.DAK_I_CATN   "
   _cQuery += "                   AND DAIF.D_E_L_E_T_ = ' ') , 0) = NVL (   "
   _cQuery += "                                                            (SELECT COUNT (1)   "
   _cQuery += "                                                             FROM DAI010 DAIF,   "
   _cQuery += "                                                                  SF2010 SF2F   "
   _cQuery += "                                                             WHERE DAIF.DAI_FILIAL = DAKC.DAK_I_FITN   "
   _cQuery += "                                                               AND DAIF.DAI_COD = DAKC.DAK_I_CATN   "
   _cQuery += "                                                               AND DAIF.D_E_L_E_T_ = ' '   "
   _cQuery += "                                                               AND SF2F.F2_FILIAL = DAIF.DAI_FILIAL   "
   _cQuery += "                                                               AND SF2F.F2_DOC = DAIF.DAI_NFISCA   "
   _cQuery += "                                                               AND SF2F.F2_SERIE = DAIF.DAI_SERIE   "
   _cQuery += "                                                               AND SF2F.F2_I_SITUA = 'V'   "
   _cQuery += "                                                               AND SF2F.D_E_L_E_T_ = ' ') , 0)   "
   _cQuery += "     AND NOT EXISTS   "
   _cQuery += "       (SELECT 'X'   "
   _cQuery += "        FROM ZFK010 ZFKB   "
   _cQuery += "        WHERE ZFKB.ZFK_FILIAL = DAKC.DAK_FILIAL   "
   _cQuery += "          AND ZFKB.ZFK_TIPOI = '5'   "
   _cQuery += "          AND ZFKB.ZFK_CARTMS = DAKC.DAK_I_RECR   "
   _cQuery += "          AND ZFKB.ZFK_SITUAC = 'P'   "
   _cQuery += "          AND ZFKB.D_E_L_E_T_ = ' ')   "

   _cQuery += "     AND NOT EXISTS ( SELECT 'X' FROM "+RetSqlName("ZFK")+ " ZFKW WHERE ZFKW.D_E_L_E_T_ = ' ' AND ZFKW.ZFK_TIPOI = '5' AND DAKC.DAK_FILIAL =  ZFKW.ZFK_FILIAL AND ZFKW.ZFK_CARGA = DAKC.DAK_COD)"

   _cQuery := ChangeQuery(_cQuery)

   If Select(_cAliasTMP) > 0
      DBSelectArea(_cAliasTMP)
      DBCloseArea()
   EndIf

   MPSysOpenQuery(_cQuery,_cAliasTMP)

   DBSelectArea(_cAliasTMP)
   Count To _nTotRegs

   If !_lScheduler 
      ProcRegua(_nTotRegs)
   EndIf

   _cTotal := AllTrim(Str(_nTotRegs))

   If _nTotRegs > 0

      DBSelectArea(_cAliasTMP)
      (_cAliasTMP)->(DBGoTop())
      While (_cAliasTMP)->(!Eof())
         
         _nRegAtu++
         
         If !u_IT_TMS((_cAliasTMP)->DAK_I_LEMB )
            (_cAliasTMP)->(DBSkip())
            Loop
         EndIf

         If !_lScheduler 
            IncProc("Lendo dados de Carga - Registro : " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
         EndIf

         _aLinha := {}
         For _nI := 1 To Len(_aCampos)
            aAdd(_aLinha, &(_aCampos[_nI]))
         Next

         aAdd(_aDados,_aLinha)

         (_cAliasTMP)->(DBSkip())

      EndDo

      If _lScheduler
      
         _lReturn := .T.
      
      Else
      
         _cTitulo := "Cargas que foram geradas a partir de integração com o TMS Multiembarcador "
         _cMsgTop := _cTitulo

                     //ITListBox( _cTitAux , _aHeader    , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda ,_lHasOk,_bHeadClk,_aSX1)
         _lReturn := U_ITListBox( _cTitulo , _aCabec     , _aDados   , .T.      , 2      , _cMsgTop ,          , _aSizes ,         ,     ,        ,          ,       ,         ,          ,           ,          ,       ,         ,     )
      
      EndIf

      If _lReturn
         
         For _nI := 1 To Len(_aDados) 

            If _lScheduler   
               U_ItConout("[AOMS144R] Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)  
            Else
               IncProc("Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)   
            EndIf

            If _aDados[_nI][1] .Or. _lScheduler
               
               _nEnviados++
               _nRecnoDAK := _aDados[_nI][aScan(_aPosCpo,{|x|x="R_E_C_N_O_"})]

               DAK->(DBGoTo(_nRecnoDAK))

               Begin Transaction

                  If !_lScheduler 
                     IncProc("Carregando Carga: " + DAK->DAK_COD)  
                  Else
                     ConOut("[AOMS144R] - Carregando Carga: " + DAK->DAK_COD )
                  EndIf
                  RecLock("ZFK",.T.)
                     ZFK->ZFK_FILIAL  := DAK->DAK_FILIAL    //	Filial do Sistema
                     ZFK->ZFK_CARGA   := DAK->DAK_COD
                     ZFK->ZFK_CARTMS  := DAK->DAK_I_RECR
                     ZFK->ZFK_HORA    := Time()             // Hora de inclusão do registro na tabela de muro.
                     ZFK->ZFK_DATA    := Date()	            //	Data de Emissão
                     ZFK->ZFK_USUARI  := __cUserId	         //	Codigo do Usuário
                     ZFK->ZFK_DATAAL  := Date()	            //	Data de Alteração
                     ZFK->ZFK_SITUAC  := "N"                //	Situação do Registro
                     ZFK->ZFK_TIPOI   := "5"
                     ZFK->ZFK_CODEMP  := _cCodEmpWS         //	Codigo Empresa WebServer 
                  ZFK->(MSUnLock())     

               End Transaction

               _cMsg := "Carregado para Integração"
            EndIf
         
         Next

         _cTextoFim := "Registros carregados para Liberar Emissão sem NFe: "+Str(_nEnviados)+Chr(10)

         U_ItConout("[AOMS144R] >> Carregamento concluído << Italac <---> TMS Multi-Embarcador "+_cTextoFim)
         
         If !_lScheduler
            U_ITMsg(">> Carregamento concluído << "+Chr(10)+;
                  "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+_cTextoFim+Chr(10),;
                  "Fim de Carregamento",,2)
            
            If Len(_aLog) > 0

               U_ITListBox( 'Log de Processamento do carregamento de registros para Liberar Emissão sem NFe',;
               _aCabecLog, _aLog , .T. , 1 ,;
               "Abaixo segue a relação de Carregamento" )

            EndIf
         EndIf

      EndIf
   Else
      If _lScheduler
         ConOut("[AOMS144R] - Não foram encontrados dados para integração." )
      Else
         U_ITMsg(">> Processamento concluído << "+Chr(10)+;
         "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
         "Atenção",,3)
      EndIf
   EndIf

End Sequence

If Select(_cAliasTMP) > 0
   (_cAliasTMP)->( DBCloseArea() )
EndIf

Return _lReturn

/*
===============================================================================================================================
Programa----------: AOMS144U
Autor-------------: Igor Melgaço
Data da Criacao---: 22/02/2024
Descrição---------: Rotina de carga de Registros do Tipo de Integração (ZFK_TIPOI) = 5 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS144U

Local _cQuery := ""
Local _cAliasTMP := "TRBAOMS144U"
Local _lReturn := .F.
Local _nTotRegs := 0
Local _cFilialCar := ""
Local _cCargaCar  := ""
Local _cFilialFat := ""
Local _cCargaFat  := ""
Local _cFilHabilit := SuperGetMV('IT_FILINTW',.F.,'')
Local _dDataIntTMS   := SuperGetMV("IT_DTINTMS",.F.,Ctod("01/01/2024"))

If DAK->DAK_I_TRNF == ' ' .Or. DAK->DAK_I_TRNF == 'N'

   _cQuery := "SELECT DAK.*, DAK.R_E_C_N_O_  R_E_C_N_O_"
   _cQuery += "   FROM "+RetSqlName("DAK")+" DAK"
   _cQuery += " WHERE DAK_FILIAL IN ('" + StrTran(AllTrim(_cFilHabilit) ,";","','") + "') "
   _cQuery += "   AND DAK_DATA >= '" + DToS(_dDataIntTMS) + "' "
   _cQuery += "   AND DAK_FILIAL = '"+ZFK->ZFK_CARGA+"'"
   _cQuery += "   AND DAK_COD = '"+ZFK->ZFK_CARGA+"'"
   _cQuery += "   AND DAK.D_E_L_E_T_ = ' '"
   _cQuery += "   AND NVL ("
   _cQuery += "              (SELECT COUNT (1)"
   _cQuery += "                 FROM "+RetSqlName("DAI")+" DAI"
   _cQuery += "                WHERE     DAI_FILIAL = DAK_FILIAL"
   _cQuery += "                      AND DAI_COD = DAK_COD"
   _cQuery += "                      AND DAI.D_E_L_E_T_ = ' '),"
   _cQuery += "              0) ="
   _cQuery += "              NVL ("
   _cQuery += "                 (SELECT COUNT (1)"
   _cQuery += "                    FROM "+RetSqlName("DAI")+" DAI, "+RetSqlName("SF2")+" SF2"
   _cQuery += "                   WHERE     DAI_FILIAL = DAK.DAK_FILIAL"
   _cQuery += "                         AND DAI_COD = DAK.DAK_COD"
   _cQuery += "                         AND DAI.D_E_L_E_T_ = ' '"
   _cQuery += "                         AND F2_FILIAL = DAI_FILIAL"
   _cQuery += "                         AND F2_DOC = DAI_NFISCA"
   _cQuery += "                         AND F2_SERIE = DAI_SERIE"
   _cQuery += "                         AND F2_I_SITUA = 'V'"
   _cQuery += "                         AND SF2.D_E_L_E_T_ = ' '),"
   _cQuery += "                 0)"
   _cQuery += "   AND NOT EXISTS ( SELECT 'X' FROM "+RetSqlName("ZFK")+ " ZFK WHERE ZFK.D_E_L_E_T_ = ' ' AND ZFK.ZFK_TIPOI = '5' AND DAK.DAK_FILIAL = ZFK.ZFK_FILIAL AND DAK.DAK_COD = ZFK.ZFK_CARGA)"

Else

   If DAK->DAK_I_TRNF = 'F'
      _cFilialCar = DAK->DAK_I_FITN
      _cCargaCar  = DAK->DAK_I_CATN
      _cFilialFat = DAK->DAK_FILIAL
      _cCargaFat  = DAK->DAK_COD
   Else
      _cFilialCar = DAK->DAK_FILIAL
      _cCargaCar  = DAK->DAK_COD
      _cFilialFat = DAK->DAK_I_FITN
      _cCargaFat  = DAK->DAK_I_CATN
   EndIf

   _cQuery := "SELECT DAK_I_RECR "
   _cQuery += "   FROM "+RetSqlName("DAK")+" DAKC "
   _cQuery += " WHERE DAKC.DAK_FILIAL IN ('" + StrTran(AllTrim(_cFilHabilit) ,";","','") + "') "
   _cQuery += "   AND DAKC.DAK_DATA >= '" + DToS(_dDataIntTMS) + "' "
   _cQuery += "   AND DAKC.DAK_FILIAL = '"+_cFilialCar+"'"
   _cQuery += "   AND DAKC.DAK_COD = '"+_cCargaCar+"'"
   _cQuery += "   AND DAKC.D_E_L_E_T_ = ' '"
   _cQuery += "   AND NVL ("
   _cQuery += "              (SELECT COUNT (1)"
   _cQuery += "                 FROM "+RetSqlName("DAI")+" DAIC"
   _cQuery += "                WHERE     DAIC.DAI_FILIAL = DAKC.DAK_FILIAL"
   _cQuery += "                      AND DAIC.DAI_COD = DAKC.DAK_COD"
   _cQuery += "                      AND DAIC.D_E_L_E_T_ = ' '),"
   _cQuery += "              0) ="
   _cQuery += "              NVL ("
   _cQuery += "                 (SELECT COUNT (1)"
   _cQuery += "                    FROM "+RetSqlName("DAI")+" DAIC, "+RetSqlName("SF2")+" SF2C"
   _cQuery += "                   WHERE     DAIC.DAI_FILIAL = DAKC.DAK_FILIAL"
   _cQuery += "                         AND DAIC.DAI_COD = DAKC.DAK_COD"
   _cQuery += "                         AND DAIC.D_E_L_E_T_ = ' '"
   _cQuery += "                         AND SF2C.F2_FILIAL = DAIC.DAI_FILIAL"
   _cQuery += "                         AND SF2C.F2_DOC = DAIC.DAI_NFISCA"
   _cQuery += "                         AND SF2C.F2_SERIE = DAIC.DAI_SERIE"
   _cQuery += "                         AND SF2C.F2_I_SITUA = 'V'"
   _cQuery += "                         AND SF2C.D_E_L_E_T_ = ' '),"
   _cQuery += "                 0)"
   _cQuery += "   AND NVL ("
   _cQuery += "              (SELECT COUNT (1)"
   _cQuery += "                 FROM "+RetSqlName("DAI")+" DAIF"
   _cQuery += "                WHERE     DAIF.DAI_FILIAL = '"+_cFilialFat+"'"
   _cQuery += "                      AND DAIF.DAI_COD = '"+_cCargaFat+"'"
   _cQuery += "                      AND DAIF.D_E_L_E_T_ = ' '),"
   _cQuery += "              0) ="
   _cQuery += "              NVL ("
   _cQuery += "                 (SELECT COUNT (1)"
   _cQuery += "                    FROM "+RetSqlName("DAI")+" DAIF, "+RetSqlName("SF2")+" SF2F"
   _cQuery += "                   WHERE     DAIF.DAI_FILIAL = '"+_cFilialFat+"'"
   _cQuery += "                         AND DAIF.DAI_COD = '"+_cCargaFat+"'"
   _cQuery += "                         AND DAIF.D_E_L_E_T_ = ' '"
   _cQuery += "                         AND SF2F.F2_FILIAL = DAIF.DAI_FILIAL"
   _cQuery += "                         AND SF2F.F2_DOC = DAIF.DAI_NFISCA"
   _cQuery += "                         AND SF2F.F2_SERIE = DAIF.DAI_SERIE"
   _cQuery += "                         AND SF2F.F2_I_SITUA = 'V'"
   _cQuery += "                         AND SF2F.D_E_L_E_T_ = ' '),"
   _cQuery += "                 0)"
   _cQuery += "   AND NOT EXISTS ( SELECT 'X' FROM "+RetSqlName("ZFK")+ " ZFK WHERE ZFK.D_E_L_E_T_ = ' ' AND ZFK.ZFK_TIPOI = '5' AND DAKC.DAK_FILIAL = ZFK.ZFK_FILIAL AND DAKC.DAK_COD = ZFK.ZFK_CARGA)"

EndIf

_cQuery := ChangeQuery(_cQuery)

If Select(_cAliasTMP) > 0
   DBSelectArea(_cAliasTMP)
   DBCloseArea()
EndIf

MPSysOpenQuery(_cQuery,_cAliasTMP)

DBSelectArea(_cAliasTMP)
Count To _nTotRegs

_lReturn := (_nTotRegs > 0)

Return _lReturn

/*
===============================================================================================================================
Programa----------: AOMS144K
Autor-------------: Igor Melgaço
Data da Criacao---: 22/02/2024
Descrição---------: Rotina de Informar Cancelamento para o sistema TMS Multi-Embarcador.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function AOMS144K

Local _cQry          := ""
Local _cTimeIni      := Time()
Local _nTotRegs      := 0
Local _nEnviados     := 0
Local _cLink         := ""
Local _cCodEmpWS     := SuperGetMV('IT_EMPTMSM',.F.,"000005")
Local _cToken        := ""
Local _cXML          := ""
Local _cResult       := ""
Local _cProtocolo    := ""
Local _lOk           := .F.
Local _aLog          := {}
Local _aCabecLog        := {"Processado","Filial","Carga","Retorno", "Recno ZFK"}
Local _cTextoFim     := ""
Local _aAlias   := {}
Local _cAliasTMP     := "TRBAOMS144K"
Local _cAlias        := "ZFK"
Local _nRegAtu := 0
Local _aCabec  := {}
Local _aPosCpo := {}
Local _aSizes  := {}
Local _aCampos := {}
Local _aDados  := {}
Local _nI      := 0
Local _cFilHabilit      := SuperGetMV('IT_FILINTW',.F.,'')
Local _nRecnoZFK := 0
Local oWSDL

Begin Sequence 
   
   If !_lScheduler .And. ! U_ITMsg("Confirma Liberar Emissao sem NFe >> Italac <---> TMS Multi-Embarcador?","Inicio de processamento",,4,2,2) 
      Break
   EndIf

   _aAlias := AOMS144MA(_cAlias,_cAliasTMP, .T.,.T.,.T.)

   _aCabec  := _aAlias[1]
   _aPosCpo := _aAlias[2]
   _aSizes  := _aAlias[3]
   _aCampos := _aAlias[4]

   //===================================================================================================
   // Montagem de query com os numeros de registros das notas fiscais a serem enviadas para o RDC.
   //===================================================================================================
   _cQry := " SELECT ZFK.*, ZFK.R_E_C_N_O_ R_E_C_N_O_ "
   _cQry += " FROM "+RetSqlName("ZFK")+" ZFK "
   _cQry += " WHERE ZFK.D_E_L_E_T_ = ' ' "
   _cQry += "   AND ZFK_TIPOI = '5' "
   _cQry += "   AND (ZFK_SITUAC = 'N' OR ZFK_SITUAC = 'R')"
   _cQry += "   AND ZFK_FILIAL IN "+FormatIn(AllTrim(_cFilHabilit),";")

   _cQry := ChangeQuery(_cQry)         

   If Select(_cAliasTMP) > 0
      (_cAliasTMP)->( DBCloseArea() )
   EndIf

   MPSysOpenQuery(_cQry,_cAliasTMP)

   DBSelectArea(_cAliasTMP)                                                                                
   COUNT To _nTotRegs

   If !_lScheduler
      ProcRegua(_nTotRegs)
   EndIf

   _cTotal := AllTrim(Str(_nTotRegs))

   If _nTotRegs > 0      
      DBSelectArea(_cAliasTMP)                    
      (_cAliasTMP)->(DBGoTop())

      While (_cAliasTMP)->(!Eof())

         _nRegAtu++

         If !_lScheduler 
            IncProc("Lendo dados de Carga - Registro : " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
         EndIf

         _aLinha := {}
         For _nI := 1 To Len(_aCampos)
            aAdd(_aLinha, &(_aCampos[_nI]))
         Next

         aAdd(_aDados,_aLinha)

         (_cAliasTMP)->(DBSkip())

      EndDo

      If _lScheduler
      
         _lReturn := .T.
      
      Else
      
         _cTitulo := "Cargas que foram geradas a partir de integração com o TMS Multiembarcador "
         _cMsgTop := _cTitulo

         If Len(_aDados) > 0
                     //ITListBox( _cTitAux , _aHeader    , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda ,_lHasOk,_bHeadClk,_aSX1)
            _lReturn := U_ITListBox( _cTitulo , _aCabec     , _aDados   , .T.      , 2      , _cMsgTop ,          , _aSizes ,         ,     ,        ,          ,       ,         ,          ,           ,          ,       ,         ,     )
         Else
            U_ITMsg(">> Carregamento concluído << "+Chr(10)+;
            "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
            "Atenção",,3)
            Break
         EndIf
      EndIf

      If _lReturn
         //=====================================================================
         // Obtem o token de acesso ao sistema multi embarcador.
         //=====================================================================
         _cToken := SuperGetMV('IT_TOKMUTE',.F.,"a78e0523d3794843855e8d95c2bff8d4")

         If !_lScheduler 
            ProcRegua(Len(_aDados))
         EndIf

         _cTotal := AllTrim(Str(Len(_aDados)))

         For _nI := 1 To Len(_aDados)

            If _lScheduler   
               U_ItConout("[AOMS144Y] Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)  
            Else
               IncProc("Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)   
            EndIf

            If _aDados[_nI][1] .Or. _lScheduler

               Begin Sequence

                  _nRecnoZFK := _aDados[_nI][aScan(_aPosCpo,{|x|x="R_E_C_N_O_"})]

                  ZFK->(DBGoTo(_nRecnoZFK))

                  ZFM->(DBSetOrder(1))
                  If ZFM->(DBSeek(ZFK->ZFK_FILIAL+_cCodEmpWS))
                     _cLink   := AllTrim(ZFM->ZFM_LINK01) //Link de Cargas
                  Else
                     _cMsg := "Empresa WebService para envio dos dados não localizada."     
                     If !_lScheduler
                        U_ITMsg(_cMsg,"Atenção",,1)
                     Else
                        U_ITCONOUT("[AOMS144Y] "+_cMsg)
                     EndIf
                     _lOk := .F.
                     Break     
                  EndIf
                  
                  If Empty(_cLink)
                     _cMsg := "O Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+"."
                     If !_lScheduler
                        U_ITMsg(_cMsg,"Atenção",,1)
                     Else
                        U_ItConout("[AOMS144Y] "+_cMsg)
                     EndIf
                     _lOk := .F.
                     Break                                     
                  EndIf

                     If ! _lScheduler
                        IncProc("LiberarEmissaoSemNFe: "+ZFK->ZFK_CARGA)                    
                     Else
                        u_itconout("[AOMS144Y] LiberarEmissaoSemNFe: "+ZFK->ZFK_CARGA) 
                     EndIf  

                     _cProtocolo := ZFK->ZFK_CARTMS

                     _cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                     _cXML += '<soapenv:Header>'
                     _cXML += '<Token xmlns="Token">'+FWHttpEncode(AllTrim(_cToken))+'</Token>'
                     _cXML += '</soapenv:Header>'
                     _cXML += '<soapenv:Body>'
                     _cXML += '<tem:LiberarEmissaoSemNFe>'
                     _cXML += '<tem:protocoloIntegracaoCarga>'+ FWHttpEncode(AllTrim(_cProtocolo)) +'</tem:protocoloIntegracaoCarga>'
                     _cXML += '</tem:LiberarEmissaoSemNFe>'
                     _cXML += '</soapenv:Body>'
                     _cXML += '</soapenv:Envelope>'

                     _nIniCarre := 1   // Inicio da leitura das cargas pendentes no TMS.
                     _nLimCarre := 100 // Número Máximo de Registros Lidos.

                     oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.
                     oWsdl:nTimeout := 10          // Timeout de 10 segundos 
                     oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo                                                                    

                     oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.  
                     oWsdl:SetOperation( "LiberarEmissaoSemNFe") // Define qual operação será realizada.

                     _lOk := oWsdl:SendSoapMsg(_cXML) // Este comando pega o XML e envia para o servidor da RDC.  
                        
                     If _lOk 
                        _cResult := oWsdl:GetSoapResponse()

                        _cResult := "Integração Processada"
                     Else
                        _cResult := oWsdl:cError
                        _cProtocolo := ""
                     EndIf   

                     ZFK->(RecLock("ZFK",.F.))
                        ZFK->ZFK_USUARI := __cUserId
                        ZFK->ZFK_SITUAC := IIf(_lOk,"P","R")
                        ZFK->ZFK_RETORN := _cResult
                        ZFK->ZFK_CODEMP := _cCodEmpWS
                        ZFK->ZFK_XML    := _cXML
                     ZFK->(MSUnLock())

                     _cMsg := _cResult 

               End Sequence     

               aAdd(_aLog,{_lOk, ZFK->ZFK_FILIAL,ZFK->ZFK_CARGA,_cMsg,ZFK->(Recno())})
               Sleep(100) //Espera para não travar a comunicação com o webservice da TMS
 
            EndIf

            FreeObj(oWsdl)

         Next

         _cTextoFim := "Cargas enviadas do método LiberarEmissaoSemNFe: "+Str(_nEnviados)+Chr(10)
         
         If _lScheduler
            U_ItConout("[AOMS144Y] >> Processamento concluído <<  Italac <---> TMS Multi-Embarcador "+_cTextoFim)
         Else
            U_ITMsg(">> Processamento concluído << "+Chr(10)+;
                  "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+_cTextoFim+Chr(10),;
                  "Fim de processamento",,2)

            If Len(_aLog) > 0

               U_ITListBox( 'Log de Processamento da Integração',;
               _aCabecLog, _aLog , .T. , 1 ,;
               "Abaixo segue a relação de processamento do  método LiberarEmissaoSemNFe" )

            EndIf

         EndIf
      EndIf
   Else
      If _lScheduler
         ConOut("[AOMS144F] - Não foram encontrados dados para integração." )
      Else
         U_ITMsg(">> Processamento concluído << "+Chr(10)+;
         "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
         "Atenção",,3)
      EndIf
   EndIf

End Sequence

Return

/*
===============================================================================================================================
Função------------: AOMS114T
Autor-------------: Julio de Paula Paz
Data da Criacao---: 15/03/2024
Descrição---------: Tela para informar o numero da Carga para obtenção do Protocolo de integração de notas fiscais.
Parametros--------: Nenhum
Retorno-----------: _aRet = {_lRet , _cNumeroCarga}
                             _lRet = .T. = Numero da Carga informado e integração confirmada.
							                .F. = Numero da Carga não informado ou integração de Notas Fiscais cancelada.
							 _cNumeroCarga= Numero do Carga para obetenção do Protocolo de Integração de Notas Fiscais.
===============================================================================================================================
*/  
User Function AOMS144T

Local _bOk, _bCancel
Local _lRet := .T.
Local _cNrCarga, _cFilCarga 
Local _oDlgCarga

Begin Sequence
   _cNrCarga  := Space(6)
   _cFilCarga := Space(2)
   _oNrCarga  := Nil
   _oFilCarga := Nil

   _bOk := {|| If(AOMS144T_A(_cFilCarga,_cNrCarga),(_lRet := .T., _oDlgCarga:End()),_lRet := .F.)}
   _bCancel := {|| _lRet := .F., _oDlgCarga:End()}
                                                
   _cTitulo := "Integração de Notas Fiscais Informando o um Numero de Carga "
      
   Define MsDialog _oDlgCarga Title _cTitulo From 9,0 To 22,65 Of oMainWnd      

      @ 15,10 Say "Filial da Carga" Pixel of _oDlgCarga                                                 
      @ 15,100 Get _oFilCarga  Var _cFilCarga Picture "@!" Size 20,10 Pixel Of _oDlgCarga  

      @ 30,10 Say "Nr. Carga" Pixel of _oDlgCarga                                                 
      @ 30,100 Get _oNrCarga   Var _cNrCarga Picture "@!" Size 30,10 Pixel Of _oDlgCarga  
        
      @ 75,060  Button "Integrar Nota Fiscal" Size 50,16  Of _oDlgCarga Pixel Action EVAL(_bOk)
      @ 75,145  Button "Cancelar"      Size 50,16  Of _oDlgCarga Pixel Action EVAL(_bCancel)
      
   Activate MsDialog _oDlgCarga CENTERED 

   If _lRet 
      If U_ITMsg("Confirma a Integração de Notas Fiscais para obtenção do Token da nota?","",,4,2,2) 
         
         Processa( {|| U_AOMS144O(_cFilCarga,_cNrCarga) } , 'Aguarde!' , 'Processando Integração de NF para Carga Informada...' ) 

      EndIf
   Else
      U_ITMsg("Rotina encerrada pelo usuário.","Atenção",,1)    
   EndIf 

End Sequence

Return 

/*
===============================================================================================================================
Função------------: AOMS114T_A
Autor-------------: Julio de Paula Paz
Data da Criacao---: 15/03/2024
Descrição---------: Tela para informar o numero da Carga para obtenção do Protocolo de integração de notas fiscais.
Parametros--------: _cFilCarga = Filial da Carga.
                    _cNrCarga  = Numero da Carga Protheus.
Retorno-----------: _lRet = .T. = Numero de carga informado Ok.
                            .F. = Numero de carga informado não existe.
===============================================================================================================================
*/  
Static Function AOMS144T_A(_cFilCarga,_cNrCarga)

Local _lRet := .T.

Begin Sequence 

   DAK->(DBSetOrder(1)) // DAK_FILIAL+DAK_COD+DAK_SEQCAR
   
   If Empty(_cFilCarga)
      _cFilCarga := xFilial("DAK")
   EndIf 

   If Empty(_cNrCarga)
      U_ITMsg("O preenchimento do numero de carga é obrigatório.","Atenção",,1)
      _lRet := .F.
      Break
   EndIf 

   If ! DAK->(MsSeek(_cFilCarga+_cNrCarga))
      U_ITMsg("O numero de carga informado não existe.","Atenção",,1)
      _lRet := .F.
      Break
   EndIf 

End Sequence 

Return _lRet 

/*
===============================================================================================================================
Programa----------: AOMS144O
Autor-------------: Julio de Paula Paz
Data da Criacao---: 15/03/2024
Descrição---------: Rotina de obtenção do Token da Nota Fiscal e gravação na tabela SF2.
Parametros--------: _cFilCarga = Filial da Carga 
                    _cNrCarga  = Numero da Carga
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS144O(_cFilCarga,_cNrCarga)

Local _cQry := ""
Local _cToken
Local _lIntegrou := .F.
Local _nTotRegs
Local _nI 
Local _nIni := 0
Local _nFim := 0
Local _cPart1Xml := "" 
Local _cPart2Xml := ""
Local _cXmlEnv   := ""
Local _cXmlNfe   := ""
Local _cProtNfe  := ""
Local _cCodEmpWS := SuperGetMV('IT_EMPTMSM',.F.,"000005")
Local _cFilHabilit := SuperGetMV('IT_FILINTW',.F.,'')
Local _cXml,_lOk,_cResult,_nPosi, _nPosf, _cProtocolo

Begin Sequence 
   //=====================================================================
   // Obtem o token de acesso ao sistema multi embarcador.
   //=====================================================================
   _cToken := SuperGetMV('IT_TOKMUTE',.F.,"a78e0523d3794843855e8d95c2bff8d4")

   //=====================================================================
   // Obtem o Link do Webservice para integração de notas fiscais.
   //=====================================================================
   ZFM->(DBSetOrder(1))
   If ZFM->(DBSeek(ZFK->ZFK_FILIAL+_cCodEmpWS))
      _cLink := AllTrim(ZFM->ZFM_LINK02)
   Else
      U_ITMsg("Empresa TMS Multi-Embarcador para envio dos dados não localizada, no cadastro de empresas Webservice." ,"Atenção",,1)
      Break   
   EndIf                        

   If Empty(_cLink)
      U_ITMsg("O Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+".","Atenção",,1)
      Break                                     
   EndIf

   //=====================================================================
   // Lendo dados da carga e montando a tabela ZFK.
   //=====================================================================
   _cQry := " SELECT SF2.* ,SPED50.R_E_C_N_O_ NREC50, SF2.R_E_C_N_O_ NRECSF2, SPED54.R_E_C_N_O_ NREC54, DAK.R_E_C_N_O_ NRECDAK "
   _cQry += " FROM "+RetSqlName("SF2")+" SF2, SPED050 SPED50, SPED054 SPED54, "+RetSqlName("DAK")+" DAK "
   _cQry += " WHERE SF2.D_E_L_E_T_ = ' ' "
   _cQry += "   AND SPED50.D_E_L_E_T_ = ' ' "
   _cQry += "   AND SPED54.D_E_L_E_T_ = ' ' "
   _cQry += "   AND DAK.D_E_L_E_T_ = ' ' "
   _cQry += "   AND DOC_CHV = F2_CHVNFE "
   _cQry += "   AND NFE_CHV = F2_CHVNFE "
   _cQry += "   AND F2_ESPECIE = 'SPED' "
   _cQry += "   AND F2_CHVNFE <> ' ' "
   _cQry += "   AND SPED50.STATUS = '6' "
   _cQry += "   AND SPED54.CSTAT_SEFR = '100' "     
   _cQry += "   AND DAK_FILIAL = F2_FILIAL "
   _cQry += "   AND DAK_COD = F2_CARGA "
   _cQry += "   AND DAK_I_RECR <> ' ' " 
   _cQry += "   AND DAK_FILIAL = '" + _cFilCarga + "' "
   _cQry += "   AND DAK_COD = '" + _cNrCarga + "' "
   _cQry += "   AND F2_FILIAL IN "+FormatIn(AllTrim(_cFilHabilit),";")

   _cQry := ChangeQuery(_cQry)         

   If Select("QRYDAK") > 0
      QRYDAK->( DBCloseArea() )
   EndIf

   MPSysOpenQuery(_cQry,"QRYDAK")
   
   DBSelectArea("QRYDAK")                                                                               
   COUNT To _nTotRegs

   If _nTotRegs == 0
      U_ITMsg("Não foram encontrados dados para integração da carga: Filial: " + _cFilCarga + " - Numero: " + _cNrCarga,"Atenção",,1)
      Break 
   EndIf 
   
   ProcRegua(_nTotRegs)

   //===================================================================================================
   // Abre o arquivo de Sped para leitura dos XML e Envio para o RDC.
   //===================================================================================================
   If Select("SPED050") > 0
      SPED050->( DBCloseArea() )
   EndIf     
         
   USE SPED050 ALIAS SPED050 SHARED NEW VIA "TOPCONN" 
         
   If Select("SPED054") > 0
      SPED054->( DBCloseArea() )
   EndIf     
         
   USE SPED054 ALIAS SPED054 SHARED NEW VIA "TOPCONN" 
         
   SC5->(DBSetOrder(1)) // C5_FILIAL+C5_NUM                                                                                                                                                

   _nI := 1

   QRYDAK->(DBGoTop())
   
   While ! QRYDAK->(Eof()) 
      
      IncProc("Lendo dados da Carga: " + AllTrim(Str(_nI,10)) + " de " + AllTrim(Str(_nTotRegs,10)))  

      SF2->(DBGoTo(QRYDAK->NRECSF2))

      DAK->(DBGoTo(QRYDAK->NRECDAK))

      SPED054->(DBGoTo(QRYDAK->NREC54))

      SPED050->(DBGoTo(QRYDAK->NREC50))

      SC5->( DBSeek( SF2->F2_FILIAL + SF2->F2_I_PEDID ) )
      
      IncProc("Lendo dados da Carga: " + DAK->DAK_FILIAL + "-" + DAK->DAK_COD + " - Registro: [" + AllTrim(Str(_nI,10)) + " de " + AllTrim(Str(_nTotRegs,10))+"]")

      //===================================================================================================
      // Monta XML para envio ao TMS Multi-Embarcador
      //===================================================================================================   
      _cXmlNfe := SPED050->XML_SIG
            
      _cProtNfe := SPED054->XML_PROT
                                                         
      _nIni := AT( "<infNFe", _cXmlNfe ) 
      _nFim := AT( "</NFe>", _cXmlNfe ) 
      _cPart1Xml := SubStr(_cXmlNfe,_nIni,_nFim - _nIni)
                                                            
      _nIni := AT( "<protNFe", _cProtNfe ) 
      _nFim := AT( "</protNFe>", _cProtNfe ) 
      _cPart2Xml := SubStr(_cProtNfe,_nIni,_nFim + 11)
            
      _cXmlEnv := '<?xml version="1.0" encoding="UTF-8"?> <nfeProc xmlns="http://www.portalfiscal.inf.br/nfe" versao="3.10"> <NFe>  '
      _cXmlEnv := _cXmlEnv + _cPart1Xml + "</NFe>" + _cPart2Xml + '   </nfeProc> '

      //======================================================
      // Grava os dados na tabela de muro ZFK
      //======================================================                  
      ZFK->(RecLock("ZFK",.T.))
      ZFK->ZFK_FILIAL := SF2->F2_FILIAL
      ZFK->ZFK_CARGA  := DAK->DAK_COD
      ZFK->ZFK_CARTMS := DAK->DAK_I_RECR 
      ZFK->ZFK_PRTPED := SC5->C5_I_CDTMS
      ZFK->ZFK_DATA   := Date()  
      ZFK->ZFK_HORA   := Time()
      ZFK->ZFK_TIPOI  := "2"
      ZFK->ZFK_CHVNFE := SF2->F2_CHVNFE
      ZFK->ZFK_PEDPAL := IIf(SC5->C5_I_PEDPA == "S","S","N") 
      ZFK->ZFK_NRPPAL := IIf(SC5->C5_I_PEDPA == "S",SF2->F2_I_PEDID ,"")    
      ZFK->ZFK_CGC    := Posicione("SA1",1,xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA),"A1_CGC") 
      ZFK->ZFK_PEDIDO := SC5->C5_NUM
      ZFK->ZFK_COD	 := SF2->F2_CLIENTE    // Código Cliente    // SA2->A2_COD  - Fornecedor    // O correto é: A1_COD
      ZFK->ZFK_LOJA   := SF2->F2_LOJA       // Loja Cliente      // SA2->A2_LOJA - Fornecedor    //              A1_LOJA
      ZFK->ZFK_NOME   := Posicione("SA1",1,xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA),"A1_NOME")   // Nome Cliente      // SA2->A2_NOME - Fornecedor   //              A1_NOME
      ZFK->ZFK_USUARI := __cUserId
      ZFK->ZFK_SITUAC := "N" 
      ZFK->ZFK_XML    := _cXmlEnv
      ZFK->(MSUnLock())

      //=============================================================
      // Inicia a transmissão para obtenção do Token da nota fiscal
      //=============================================================
      _cXml := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
      _cXml += '   <soapenv:Header>'
      _cXml += '      <Token xmlns="Token">'+Eval({|| FWHttpEncode(AllTrim(_cToken))})+'</Token>'
      _cXml += '   </soapenv:Header>'
      _cXml += '   <soapenv:Body>'
      _cXml += '      <tem:EnviarArquivoXMLNFe>'
      _cXml += '<tem:arquivo>'+Eval({|| Encode64(AllTrim(_cXmlEnv))})+'</tem:arquivo>'
      _cXml += '      </tem:EnviarArquivoXMLNFe>'
      _cXml += '   </soapenv:Body>'
      _cXml += '</soapenv:Envelope>'

      oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.
      oWsdl:nTimeout := 10          // Timeout de 10 segundos 
      oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo                                                                    

      oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.  
      oWsdl:SetOperation( "EnviarArquivoXMLNFe") // Define qual operação será realizada.

      // Envia para o servidor
      _lOk := oWsdl:SendSoapMsg(_cXML) 
                        
      If _lOk 
         _cResult := oWsdl:GetSoapResponse()

         _nPosi := AT("<a:Objeto>", _cResult)
         _nPosf := AT("</a:Objeto>", _cResult)	
                        
         If _nPosi == 0
            _cProtocolo := ""
         Else
            _cProtocolo := SubStr(_cresult,_nposi+Len("<a:Objeto>"),_nposf-_nposi-Len("<a:Objeto>"))
         EndIf

         _lIntegrou := .T.               
         _cResult := "Integração Processada"
      Else
         _cResult := oWsdl:cError
         _cProtocolo := ""
      EndIf   

      If _lOk 
         SF2->(RecLock("SF2",.F.))
         SF2->F2_I_SITUA := 'P'    
         SF2->F2_I_DTENV := Date()
         SF2->F2_I_HRENV := Time()
         SF2->F2_I_PRTMS := _cProtocolo      //Protocolo TMS
         SF2->(MSUnLock())
      EndIf 

      ZFK->(RecLock("ZFK",.F.))
      ZFK->ZFK_DATA   := Date()  
      ZFK->ZFK_HORA   := Time()
      ZFK->ZFK_SITUAC := IIf(_lOk,"P","R")
      ZFK->ZFK_CODEMP := _cCodEmpWS
      ZFK->ZFK_RETORN := _cResult
      ZFK->ZFK_PRTMS  := _cProtocolo
      If _lOk
         ZFK->ZFK_XML    := _cXML
      EndIf
      ZFK->(MSUnLock())

      QRYDAK->(DBSkip())
         
   EndDo

End Sequence

If _lIntegrou
   U_ITMsg("Protocolo de nota fiscal obtido com sucesso para a carga: Filial: " + _cFilCarga + " - Numero: " + _cNrCarga ,"Atenção",,2)
Else
   U_ITMsg("Falha na obtenção do protocolo de nota fiscal para a carga: Filial: " + _cFilCarga + " - Numero: " + _cNrCarga ,"Atenção",,1)
EndIf 

//================================================================================
// Fecha as tabelas temporárias
//================================================================================                    
If Select("QRYDAK") > 0
   QRYDAK->( DBCloseArea() )
EndIf

If Select("SPED050") > 0
   SPED050->( DBCloseArea() )
EndIf     

If Select("SPED054") > 0
   SPED054->( DBCloseArea() )
EndIf  

Return

/*
===============================================================================================================================
Programa----------: AOMS144N
Autor-------------: Igor Melgaço
Data da Criacao---: 23/01/2024
Descrição---------: Rotina de Informar Cancelamento de Nota Fiscal para o sistema TMS Mulit-Embarcador.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS144N()

If _lScheduler 
   //=====================================================================
   // Limpa o ambiente, liberando a licença e fechando as conexões
   //=====================================================================
   RpcClearEnv() 
   RpcSetType(2)
   
   //================================================================================
   // Prepara ambiente abrindo tabelas e incializando variaveis.
   //================================================================================   
   //PREPARE ENVIRONMENT EMPRESA '01' FILIAL "01"; 
   //        TABLES "CKO","ZG0","SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6","ZP1";
   //        MODULO 'OMS'
   RpcSetEnv("01", "01",,,,, {"CKO","ZG0","SA7","SB1","SB2","SB5","SB8","SBJ","SB9","SBE","SBF","SC0","SD5","SBK","SD7","SDC","SF4","SGA","SM2","SDA","SDB","SBM","ADA","SA2","DAK","DAI","DA4","ZFU","ZFV","SC9","SA1","SC5","SC6","ZP1"})
   
   cFilAnt := "01"
   
   AOMS144Q()
   AOMS144D()

   //============================================================
   //Limpa o ambiente, liberando a licença e fechando as conexoes
   //============================================================
   RpcClearEnv() 
   
Else
   
   Processa( {|| AOMS144Q(),AOMS144D()},"Hora Ini: "+Time()+", Aguarde...")

EndIf

Return .F.

/*
===============================================================================================================================
Programa----------: AOMS144Q
Autor-------------: Igor Melgaço
Data da Criacao---: 23/01/2024
Descrição---------: Rotina de carga de dados das Cargas para Integração de Notas Fiscais
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS144Q

Local _cQuery      := ""
Local _cTimeIni    := Time()
Local _cAlias      := "DAK"
Local _cAliasTMP   := "TRBAOMS144Q"
Local _aAlias      := {}
Local _nRegAtu     := 0
Local _nTotRegs    := 0
Local _aCabec      := {}
Local _aPosCpo     := {}
Local _aSizes      := {}
Local _aCampos     := {}
Local _aLinha      := {}
Local _aDados      := {}
Local _lReturn     := .F.
Local _cMsg        := ""
Local _aLog        := {}
Local _aCabecLog   := {"Processado","Filial","Pedido","Chave NFe","Retorno", "Recno SF2"}
Local _cTextoFim   := ""
Local _nEnviados   := 0
Local _nI          := 0
Local _cTitulo     := ""
Local _cMsgTop     := ""
Local _cCodEmpWS   := SuperGetMV('IT_EMPTMSM',.F.,"000005")

Begin Sequence

   If !_lScheduler .And. ! U_ITMsg("Confirma carga de registros para Liberar Emissao Sem NFe >> Italac <---> TMS Multi-Embarcador?","Inicio de processamento",,4,2,2) 
      Break
   EndIf

   _aAlias := AOMS144MA(_cAlias,_cAliasTMP, .T.,.T.,.T.)

   _aCabec  := _aAlias[1]
   _aPosCpo := _aAlias[2]
   _aSizes  := _aAlias[3]
   _aCampos := _aAlias[4]

_cQuery := "   SELECT   DAK.*,   "
_cQuery += "            DAK.R_E_C_N_O_ R_E_C_N_O_	,"
_cQuery += "	         DAK_FILIAL  FILIAL,	"
_cQuery += "	         DAK_COD     CARGA,	"
_cQuery += "	         DAK_I_TRNF  TIPO,	"
_cQuery += "            DAK_I_FITN  FILIAL_TN,   "
_cQuery += "            DAK_I_CATN  CARGA_TN   "
_cQuery += "    FROM "+RetSqlName("DAK")+" DAK   "
_cQuery += "   WHERE  DAK_DATA >= '20240101'   "
_cQuery += "            AND DAK_I_TRNF NOT IN ('C', 'F')   "
_cQuery += "            AND DAK_I_RECR <> ' '   "
_cQuery += "            AND DAK.D_E_L_E_T_ = ' '   "
_cQuery += "            AND NVL (   "
_cQuery += "                     (SELECT COUNT (1)   "
_cQuery += "                       FROM "+RetSqlName("DAI")+" DAI   "
_cQuery += "                      WHERE  DAI_FILIAL = DAK_FILIAL   "
_cQuery += "                           AND DAI_COD = DAK_COD   "
_cQuery += "                           AND DAI.D_E_L_E_T_ = ' '),   "
_cQuery += "                     0) =   "
_cQuery += "             NVL (   "
_cQuery += "                     (SELECT COUNT (1)   "
_cQuery += "                       FROM "+RetSqlName("DAI")+" DAI, "+RetSqlName("SF2")+" SF2, "+RetSqlName("ZFK")+" ZFK   "
_cQuery += "                      WHERE  DAI_FILIAL = DAK_FILIAL   "
_cQuery += "                           AND DAI_COD = DAK_COD   "
_cQuery += "                           AND DAI.D_E_L_E_T_ = ' '   "
_cQuery += "                           AND F2_FILIAL = DAI_FILIAL   "
_cQuery += "                           AND F2_DOC = DAI_NFISCA   "
_cQuery += "                           AND F2_SERIE = DAI_SERIE   "
_cQuery += "                           AND F2_I_PRTMS <> ' '   "
_cQuery += "                           AND SF2.D_E_L_E_T_ = ' '   "
_cQuery += "                           AND ZFK_FILIAL = DAK_FILIAL   "
_cQuery += "                           AND ZFK_CHVNFE = F2_CHVNFE   "
_cQuery += "                           AND ZFK_TIPOI = '4'   "
_cQuery += "                           AND ZFK_SITUAC = 'P'   "
_cQuery += "                           AND ZFK.D_E_L_E_T_ = ' '),   "
_cQuery += "                     0)   "
_cQuery += "            AND NOT EXISTS   "
_cQuery += "                     (SELECT 'X'   "
_cQuery += "                       FROM "+RetSqlName("ZFK")+" ZFK   "
_cQuery += "                      WHERE  ZFK_FILIAL = DAK_FILIAL   "
_cQuery += "                           AND ZFK_CARGA = DAK_COD   "
_cQuery += "                           AND ZFK_TIPOI = '6'   "
_cQuery += "                           AND ZFK.D_E_L_E_T_ = ' ')   "
_cQuery += "   UNION ALL   "
_cQuery += "   SELECT DAKC.*,   "
_cQuery += "          DAKC.R_E_C_N_O_ R_E_C_N_O_	,"
_cQuery += "	         DAK_FILIAL FILIAL,	"
_cQuery += "	         DAK_COD  CARGA,	"
_cQuery += "	         DAK_I_TRNF  TIPO,	"
_cQuery += "	         DAK_I_FITN  FILIAL_TN,	"
_cQuery += "	         DAK_I_CATN  CARGA_TN	"
_cQuery += "    FROM "+RetSqlName("DAK")+" DAKC   "
_cQuery += "   WHERE  DAKC.DAK_DATA >= '20240101'   "
_cQuery += "            AND DAKC.DAK_I_TRNF IN ('C')   "
_cQuery += "            AND DAKC.DAK_I_CATN <> ' '   "
_cQuery += "            AND DAKC.DAK_I_RECR <> ' '   "
_cQuery += "            AND DAKC.D_E_L_E_T_ = ' '   "
_cQuery += "            AND EXISTS   "
_cQuery += "                     (SELECT 'x'   "
_cQuery += "                       FROM "+RetSqlName("DAK")+" DAKF   "
_cQuery += "                      WHERE  DAKF.DAK_FILIAL = DAKC.DAK_I_FITN   "
_cQuery += "                           AND DAKF.DAK_COD = DAKC.DAK_I_CATN   "
_cQuery += "                           AND DAKF.D_E_L_E_T_ = ' ')   "
_cQuery += "            AND NVL (   "
_cQuery += "                     (SELECT COUNT (1)   "
_cQuery += "                       FROM "+RetSqlName("DAI")+" DAIC   "
_cQuery += "                      WHERE  DAIC.DAI_FILIAL = DAKC.DAK_FILIAL   "
_cQuery += "                           AND DAIC.DAI_COD = DAKC.DAK_COD   "
_cQuery += "                           AND DAIC.D_E_L_E_T_ = ' '),   "
_cQuery += "                     0) =   "
_cQuery += "             NVL (   "
_cQuery += "                     (SELECT COUNT (1)   "
_cQuery += "                       FROM "+RetSqlName("DAI")+" DAIC, "+RetSqlName("SF2")+" SF2, "+RetSqlName("ZFK")+" ZFKC   "
_cQuery += "                      WHERE  DAIC.DAI_FILIAL = DAKC.DAK_FILIAL   "
_cQuery += "                           AND DAIC.DAI_COD = DAKC.DAK_COD   "
_cQuery += "                           AND DAIC.D_E_L_E_T_ = ' '   "
_cQuery += "                           AND F2_FILIAL = DAIC.DAI_FILIAL   "
_cQuery += "                           AND F2_DOC = DAIC.DAI_NFISCA   "
_cQuery += "                           AND F2_SERIE = DAIC.DAI_SERIE   "
_cQuery += "                           AND F2_I_PRTMS <> ' '   "
_cQuery += "                           AND SF2.D_E_L_E_T_ = ' '   "
_cQuery += "                           AND ZFKC.ZFK_FILIAL = DAKC.DAK_FILIAL   "
_cQuery += "                           AND ZFKC.ZFK_CHVNFE = F2_CHVNFE   "
_cQuery += "                           AND ZFKC.ZFK_TIPOI = '4'   "
_cQuery += "                           AND ZFKC.ZFK_SITUAC = 'P'   "
_cQuery += "                           AND ZFKC.D_E_L_E_T_ = ' '),   "
_cQuery += "                     0)   "
_cQuery += "            AND NVL (   "
_cQuery += "                     (SELECT COUNT (1)   "
_cQuery += "                       FROM "+RetSqlName("DAI")+" DAIf   "
_cQuery += "                      WHERE  DAIF.DAI_FILIAL = DAKC.DAK_I_FITN   "
_cQuery += "                           AND DAIF.DAI_COD = DAKC.DAK_I_CATN   "
_cQuery += "                           AND DAIF.D_E_L_E_T_ = ' '),   "
_cQuery += "                     0) =   "
_cQuery += "             NVL (   "
_cQuery += "                     (SELECT COUNT (1)   "
_cQuery += "                       FROM "+RetSqlName("DAI")+" DAIF, "+RetSqlName("SF2")+" SF2, "+RetSqlName("ZFK")+" ZFKF   "
_cQuery += "                      WHERE  DAIF.DAI_FILIAL = DAKC.DAK_I_FITN   "
_cQuery += "                           AND DAIF.DAI_COD = DAKC.DAK_I_CATN   "
_cQuery += "                           AND DAIF.D_E_L_E_T_ = ' '   "
_cQuery += "                           AND F2_FILIAL = DAIF.DAI_FILIAL   "
_cQuery += "                           AND F2_DOC = DAIF.DAI_NFISCA   "
_cQuery += "                           AND F2_SERIE = DAIF.DAI_SERIE   "
_cQuery += "                           AND F2_I_PRTMS <> ' '   "
_cQuery += "                           AND SF2.D_E_L_E_T_ = ' '   "
_cQuery += "                           AND ZFKF.ZFK_FILIAL = DAIF.DAI_FILIAL   "
_cQuery += "                           AND ZFKF.ZFK_CHVNFE = F2_CHVNFE   "
_cQuery += "                           AND ZFKF.ZFK_TIPOI = '4'   "
_cQuery += "                           AND ZFKF.ZFK_SITUAC = 'P'   "
_cQuery += "                           AND ZFKF.D_E_L_E_T_ = ' '),   "
_cQuery += "                     0)   "
_cQuery += "            AND NOT EXISTS   "
_cQuery += "                     (SELECT 'X'   "
_cQuery += "                       FROM "+RetSqlName("ZFK")+" ZFK   "
_cQuery += "                      WHERE  ZFK_FILIAL = DAKC.DAK_FILIAL   "
_cQuery += "                           AND ZFK_CARGA = DAKC.DAK_COD   "
_cQuery += "                           AND ZFK_TIPOI = '6'   "
_cQuery += "                           AND ZFK.D_E_L_E_T_ = ' ')   "
_cQuery += "   ORDER BY FILIAL, CARGA, TIPO   "

   _cQuery := ChangeQuery(_cQuery)

   If Select(_cAliasTMP) > 0
      DBSelectArea(_cAliasTMP)
      DBCloseArea()
   EndIf

   MPSysOpenQuery(_cQuery,_cAliasTMP)

   DBSelectArea(_cAliasTMP)
   Count To _nTotRegs

   If !_lScheduler 
      ProcRegua(_nTotRegs)
   EndIf

   _cTotal := AllTrim(Str(_nTotRegs))

   If _nTotRegs > 0

      DBSelectArea(_cAliasTMP)
      (_cAliasTMP)->(DBGoTop())
      While (_cAliasTMP)->(!Eof())
         
         _nRegAtu++
         
         If !u_IT_TMS((_cAliasTMP)->DAK_I_LEMB )
            (_cAliasTMP)->(DBSkip())
            Loop
         EndIf

         If !_lScheduler 
            IncProc("Lendo dados de Carga - Registro : " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
         EndIf

         _aLinha := {}
         For _nI := 1 To Len(_aCampos)
            aAdd(_aLinha, &(_aCampos[_nI]))
         Next

         aAdd(_aDados,_aLinha)

         (_cAliasTMP)->(DBSkip())

      EndDo

      If _lScheduler
      
         _lReturn := .T.
      
      Else
      
         _cTitulo := "Cargas que foram geradas a partir de integração com o TMS Multiembarcador "
         _cMsgTop := _cTitulo

                     //ITListBox( _cTitAux , _aHeader    , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda ,_lHasOk,_bHeadClk,_aSX1)
         _lReturn := U_ITListBox( _cTitulo , _aCabec     , _aDados   , .T.      , 2      , _cMsgTop ,          , _aSizes ,         ,     ,        ,          ,       ,         ,          ,           ,          ,       ,         ,     )
      
      EndIf

      If _lReturn
         
         For _nI := 1 To Len(_aDados) 

            If _lScheduler   
               U_ItConout("[AOMS144Q] Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)  
            Else
               IncProc("Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)   
            EndIf

            If _aDados[_nI][1] .Or. _lScheduler
               
               _nEnviados++
               _nRecnoDAK := _aDados[_nI][aScan(_aPosCpo,{|x|x="R_E_C_N_O_"})]

               DAK->(DBGoTo(_nRecnoDAK))

               Begin Transaction

                  If !_lScheduler 
                     IncProc("Carregando Carga: " + DAK->DAK_COD)  
                  Else
                     ConOut("[AOMS144Q] - Carregando Carga: " + DAK->DAK_COD )
                  EndIf

                  RecLock("ZFK",.T.)
                     ZFK->ZFK_FILIAL  := DAK->DAK_FILIAL    //	Filial do Sistema
                     ZFK->ZFK_CARGA   := DAK->DAK_COD
                     ZFK->ZFK_CARTMS  := DAK->DAK_I_RECR
                     ZFK->ZFK_HORA    := Time()             // Hora de inclusão do registro na tabela de muro.
                     ZFK->ZFK_DATA    := Date()	            //	Data de Emissão
                     ZFK->ZFK_USUARI  := __cUserId	         //	Codigo do Usuário
                     ZFK->ZFK_DATAAL  := Date()	            //	Data de Alteração
                     ZFK->ZFK_SITUAC  := "N"                //	Situação do Registro
                     ZFK->ZFK_TIPOI   := "6"
                     ZFK->ZFK_CODEMP  := _cCodEmpWS         //	Codigo Empresa WebServer 
                  ZFK->(MSUnLock())     

               End Transaction

               _cMsg := "Carregado para Integração"
            EndIf
         
         Next

         _cTextoFim := "Registros carregados para Liberar Emissão sem NFe: "+Str(_nEnviados)+Chr(10)

         U_ItConout("[AOMS144Q] >> Carregamento concluído << Italac <---> TMS Multi-Embarcador "+_cTextoFim)
         
         If !_lScheduler
            U_ITMsg(">> Carregamento concluído << "+Chr(10)+;
                  "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+_cTextoFim+Chr(10),;
                  "Fim de Carregamento",,2)
            
            If Len(_aLog) > 0

               U_ITListBox( 'Log de Processamento do carregamento de registros para Liberar Emissão sem NFe',;
               _aCabecLog, _aLog , .T. , 1 ,;
               "Abaixo segue a relação de Carregamento" )

            EndIf
         EndIf

      EndIf
   Else
      If _lScheduler
         ConOut("[AOMS144Q] - Não foram encontrados dados para integração." )
      Else
         U_ITMsg(">> Processamento concluído << "+Chr(10)+;
         "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
         "Atenção",,3)
      EndIf
   EndIf

End Sequence

If Select(_cAliasTMP) > 0
   (_cAliasTMP)->( DBCloseArea() )
EndIf

Return _lReturn

/*
===============================================================================================================================
Programa----------: AOMS144K
Autor-------------: Igor Melgaço
Data da Criacao---: 22/02/2024
Descrição---------: Rotina de Informar Cancelamento para o sistema TMS Multi-Embarcador.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
Static Function AOMS144D

Local _cQry          := ""
Local _cTimeIni      := Time()
Local _nTotRegs      := 0
Local _nEnviados     := 0
Local _cLink         := ""
Local _cCodEmpWS     := SuperGetMV('IT_EMPTMSM',.F.,"000005")
Local _cToken        := ""
Local _cXML          := ""
Local _cResult       := ""
Local _cProtocolo    := ""
Local _lOk           := .F.
Local _aLog          := {}
Local _aCabecLog        := {"Processado","Filial","Carga","Retorno", "Recno ZFK"}
Local _cTextoFim     := ""
Local _aAlias   := {}
Local _cAliasTMP     := "TRBAOMS144D"
Local _cAlias        := "ZFK"
Local _nRegAtu := 0
Local _aCabec  := {}
Local _aPosCpo := {}
Local _aSizes  := {}
Local _aCampos := {}
Local _aDados  := {}
Local _nI      := 0
Local _cFilHabilit      := SuperGetMV('IT_FILINTW',.F.,'')
Local _nRecnoZFK := 0
Local oWSDL

Begin Sequence 
   
   If !_lScheduler .And. ! U_ITMsg("Confirma Liberar Emissao sem NFe >> Italac <---> TMS Multi-Embarcador?","Inicio de processamento",,4,2,2) 
      Break
   EndIf

   _aAlias := AOMS144MA(_cAlias,_cAliasTMP, .T.,.T.,.T.)

   _aCabec  := _aAlias[1]
   _aPosCpo := _aAlias[2]
   _aSizes  := _aAlias[3]
   _aCampos := _aAlias[4]

   //===================================================================================================
   // Montagem de query com os numeros de registros das notas fiscais a serem enviadas para o RDC.
   //===================================================================================================
   _cQry := " SELECT ZFK.*, ZFK.R_E_C_N_O_ R_E_C_N_O_ "
   _cQry += " FROM "+RetSqlName("ZFK")+" ZFK "
   _cQry += " WHERE ZFK.D_E_L_E_T_ = ' ' "
   _cQry += "   AND ZFK_TIPOI = '6' "
   _cQry += "   AND (ZFK_SITUAC = 'N' OR ZFK_SITUAC = 'R')"
   _cQry += "   AND ZFK_FILIAL IN "+FormatIn(AllTrim(_cFilHabilit),";")

   _cQry := ChangeQuery(_cQry)         

   If Select(_cAliasTMP) > 0
      (_cAliasTMP)->( DBCloseArea() )
   EndIf

   MPSysOpenQuery(_cQry,_cAliasTMP)

   DBSelectArea(_cAliasTMP)                                                                                
   COUNT To _nTotRegs

   If !_lScheduler
      ProcRegua(_nTotRegs)
   EndIf

   _cTotal := AllTrim(Str(_nTotRegs))

   If _nTotRegs > 0      
      DBSelectArea(_cAliasTMP)                    
      (_cAliasTMP)->(DBGoTop())

      While (_cAliasTMP)->(!Eof())

         _nRegAtu++

         If !_lScheduler 
            IncProc("Lendo dados de Carga - Registro : " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
         EndIf

         _aLinha := {}
         For _nI := 1 To Len(_aCampos)
            aAdd(_aLinha, &(_aCampos[_nI]))
         Next

         aAdd(_aDados,_aLinha)

         (_cAliasTMP)->(DBSkip())

      EndDo

      If _lScheduler
      
         _lReturn := .T.
      
      Else
      
         _cTitulo := "Cargas que foram geradas a partir de integração com o TMS Multiembarcador "
         _cMsgTop := _cTitulo

         If Len(_aDados) > 0
                     //ITListBox( _cTitAux , _aHeader    , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda ,_lHasOk,_bHeadClk,_aSX1)
            _lReturn := U_ITListBox( _cTitulo , _aCabec     , _aDados   , .T.      , 2      , _cMsgTop ,          , _aSizes ,         ,     ,        ,          ,       ,         ,          ,           ,          ,       ,         ,     )
         Else
            U_ITMsg(">> Carregamento concluído << "+Chr(10)+;
            "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
            "Atenção",,3)
            Break
         EndIf
      EndIf

      If _lReturn
         //=====================================================================
         // Obtem o token de acesso ao sistema multi embarcador.
         //=====================================================================
         _cToken := SuperGetMV('IT_TOKMUTE',.F.,"a78e0523d3794843855e8d95c2bff8d4")

         If !_lScheduler 
            ProcRegua(Len(_aDados))
         EndIf

         _cTotal := AllTrim(Str(Len(_aDados)))

         For _nI := 1 To Len(_aDados)

            If _lScheduler   
               U_ItConout("[AOMS144D] Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)  
            Else
               IncProc("Registros Lidos: "+AllTrim(Str(_nI))+" de "+_cTotal)   
            EndIf

            If _aDados[_nI][1] .Or. _lScheduler

               Begin Sequence
                  
                  _nEnviados++
                  _nRecnoZFK := _aDados[_nI][aScan(_aPosCpo,{|x|x="R_E_C_N_O_"})]

                  ZFK->(DBGoTo(_nRecnoZFK))

                  ZFM->(DBSetOrder(1))
                  If ZFM->(DBSeek(ZFK->ZFK_FILIAL+_cCodEmpWS))
                     _cLink   := AllTrim(ZFM->ZFM_LINK01) //Link de Cargas
                  Else
                     _cMsg := "Empresa WebService para envio dos dados não localizada."     
                     If !_lScheduler
                        U_ITMsg(_cMsg,"Atenção",,1)
                     Else
                        U_ITCONOUT("[AOMS144D] "+_cMsg)
                     EndIf
                     _lOk := .F.
                     Break     
                  EndIf
                  
                  If Empty(_cLink)
                     _cMsg := "O Link de envio de dados não informado para a empresa: "+AllTrim(ZFM->ZFM_NOME)+"."
                     If !_lScheduler
                        U_ITMsg(_cMsg,"Atenção",,1)
                     Else
                        U_ItConout("[AOMS144D] "+_cMsg)
                     EndIf
                     _lOk := .F.
                     Break                                     
                  EndIf

                  //-----------------------------------------------
                     If ! _lScheduler
                        IncProc("LiberarEmissaoSemNFe: "+ZFK->ZFK_CARGA)                    
                     Else
                        u_itconout("[AOMS144D] LiberarEmissaoSemNFe: "+ZFK->ZFK_CARGA) 
                     EndIf  

                     _cProtocolo := ZFK->ZFK_CARTMS

                     _cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">'
                     _cXML += '<soapenv:Header>'
                     _cXML += '<Token xmlns="Token">'+FWHttpEncode(AllTrim(_cToken))+'</Token>'
                     _cXML += '</soapenv:Header>'
                     _cXML += '<soapenv:Body>'
                     _cXML += '<tem:LiberarEmissaoSemNFe>'
                     _cXML += '<tem:protocoloIntegracaoCarga>'+ FWHttpEncode(AllTrim(_cProtocolo)) +'</tem:protocoloIntegracaoCarga>'
                     _cXML += '</tem:LiberarEmissaoSemNFe>'
                     _cXML += '</soapenv:Body>'
                     _cXML += '</soapenv:Envelope>'

                     _nIniCarre := 1   // Inicio da leitura das cargas pendentes no TMS.
                     _nLimCarre := 100 // Número Máximo de Registros Lidos.

                     oWSDL := tWSDLManager():New() // Cria o objeto da WSDL.
                     oWsdl:nTimeout := 10          // Timeout de 10 segundos 
                     oWsdl:lSSLInsecure := .T. //   Acessa com certificado anônimo                                                                    

                     oWsdl:ParseURL( _cLink) // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. Este link é o da RDC.  
                     oWsdl:SetOperation( "LiberarEmissaoSemNFe") // Define qual operação será realizada.

                     _lOk := oWsdl:SendSoapMsg(_cXML) // Este comando pega o XML e envia para o servidor da RDC.  
                        
                     If _lOk 
                        _cResult := oWsdl:GetSoapResponse()

                        _cResult := "Integração Processada"
                     Else
                        _cResult := oWsdl:cError
                        _cProtocolo := ""
                     EndIf   

                     ZFK->(RecLock("ZFK",.F.))
                        ZFK->ZFK_USUARI := __cUserId
                        ZFK->ZFK_SITUAC := IIf(_lOk,"P","R")
                        ZFK->ZFK_RETORN := _cResult
                        ZFK->ZFK_CODEMP := _cCodEmpWS
                        ZFK->ZFK_XML    := _cXML
                     ZFK->(MSUnLock())

                     _cMsg := _cResult 
   
               End Sequence     

               aAdd(_aLog,{_lOk, ZFK->ZFK_FILIAL,ZFK->ZFK_CARGA,_cMsg,ZFK->(Recno())})
               Sleep(100) //Espera para não travar a comunicação com o webservice da TMS
 
            EndIf

            FreeObj(oWsdl)

         Next

         _cTextoFim := "Cargas enviadas do método LiberarEmissaoSemNFe: "+Str(_nEnviados)+Chr(10)
         
         If _lScheduler
            U_ItConout("[AOMS144D] >> Processamento concluído <<  Italac <---> TMS Multi-Embarcador "+_cTextoFim)
         Else
            U_ITMsg(">> Processamento concluído << "+Chr(10)+;
                  "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+_cTextoFim+Chr(10),;
                  "Fim de processamento",,2)

            If Len(_aLog) > 0

               U_ITListBox( 'Log de Processamento da Integração',;
               _aCabecLog, _aLog , .T. , 1 ,;
               "Abaixo segue a relação de processamento do  método LiberarEmissaoSemNFe" )

            EndIf

         EndIf
      EndIf
   Else
      If _lScheduler
         ConOut("[AOMS144D] - Não foram encontrados dados para integração." )
      Else
         U_ITMsg(">> Processamento concluído << "+Chr(10)+;
         "Hora Inicial: "+_cTimeIni+" / Hora Final: "+TIME()+Chr(10)+"Sem dados para integração",;
         "Atenção",,3)
      EndIf
   EndIf

End Sequence

Return
