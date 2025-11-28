/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
===============================================================================================================================
*/ 

#Include "TOTVS.ch"

Static _lScheduler := FWGetRunSchedule() .Or. SELECT("SX3") <= 0

/*
===============================================================================================================================
Programa----------: MFIN025
Autor-------------: Igor Melgaço
Data da Criacao---: 21/02/2024
Descrição---------: Workflow de Boletos - Envio de e-mail/notificações para clientes com Títulos a Vencer ou Vencidos.
                    Chamado: 36304.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN025()
Local _aTables		:= {"SA1","SA2","SE1","SE2","ZP1","AC8"}
Local _LigaDesWS  := ""

   If _lScheduler
      FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MFIN025"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN02501"/*cMsgId*/, "MFIN02501 - Inicio do Workflow de Boletos"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      
      //====================
      //Nao consome licensas
      //====================
      RPCSetType(2)

      //==========================================
      //seta o ambiente com a empresa 01 filial 01
      //==========================================   	 
      RpcSetEnv("01","01",,,,"SCHEDULE_WF_BOLETOS ",_aTables)

      //====================================================================
      // Liga ou Desliga a integração Workflow de Cobranças.
      //====================================================================
      _LigaDesWS := U_ITGETMV('IT_MF25LIG', .T.) 

      If _LigaDesWS
         MFIN025A()
      EndIf 

      //============================================================
      //Limpa o ambiente, liberando a licença e fechando as conexoes
      //============================================================
      RpcClearEnv()  
   Else

      _LigaDesWS := U_ITGETMV('IT_LIGAWCB', .T.) 

      If _LigaDesWS
         Processa( {|| MFIN025A() } , 'Aguarde!' , 'Processando Titulos...' )
      EndIf

   EndIf

Return


/*
===============================================================================================================================
Programa----------: MFIN025
Autor-------------: Igor Melgaço
Data da Criacao---: 22/02/2024
Descrição---------: Workflow de Boletos - Envio de e-mail/notificações para clientes com Títulos a Vencer ou Vencidos.
                    Chamado: 36304.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN025A()
Local _cAlias	:= GetNextAlias()
Local _cQry := ""
Local _nTotRegs := 0
Local _nRegAtu  := 0
Local _nDias   := U_ITGETMV( 'IT_MF25DIA' , 1)

Begin Sequence

   _cQry := " SELECT E1_FILIAL, E1_PREFIXO, E1_NUM, E1_CLIENTE, E1_LOJA, MIN(SE1.R_E_C_N_O_) R_E_C_N_O_ " 
   _cQry += " FROM " + RetSqlName("SE1") + " SE1 "
   _cQry += " INNER JOIN " + RetSqlName("SA1") + " SA1 ON A1_COD = E1_CLIENTE AND A1_LOJA = E1_LOJA AND SE1.D_E_L_E_T_ = ' ' AND A1_I_IBOLE <> 'N' " 
   _cQry += " WHERE E1_EMISSAO = '" + DToS(Date()-_nDias) + "' "
   _cQry += " AND E1_SALDO > 0 AND E1_TIPO = 'NF' " 
   _cQry += " AND E1_ORIGEM = 'MATA460' " // Linha de Filtro solicitada pelo Antônio
   _cQry += " GROUP BY E1_FILIAL, E1_PREFIXO, E1_NUM, E1_CLIENTE, E1_LOJA" 
   _cQry += " ORDER BY E1_FILIAL, E1_PREFIXO, E1_NUM, E1_CLIENTE, E1_LOJA" 

   If Select(_cAlias) <> 0
      (_cAlias)->(DBCloseArea())
   EndIf

   DbUseArea(.T., "TOPCONN", TcGenQry(,,_cQry), _cAlias, .T., .F.)

   DBSelectArea(_cAlias)
   Count to _nTotRegs

   If !_lScheduler .And. ! U_ITMsg("Confirma envio dos Boletos?","Inicio de processamento",,4,2,2) 
      Break
   EndIf

   (_cAlias)->(DBGoTop())
   While !(_cAlias)->(Eof())

      _nRegAtu++

      DBSelectArea("SE1")
      SE1->(DBSetOrder(1))
      SE1->(DBGoTo((_cAlias)->R_E_C_N_O_))

      If _lScheduler
         FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MFIN025"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MFIN02502"/*cMsgId*/, "MFIN02502 - Enviando o Boleto ref. ao Titulo "+SE1->E1_NUM+" Prefixo "+SE1->E1_PREFIXO+" Parcela "+SE1->E1_PARCELA+" - Registro : " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
      Else
         IncProc("Enviando o Boleto ref. ao Titulo "+SE1->E1_NUM+" Prefixo "+SE1->E1_PREFIXO+" Parcela "+SE1->E1_PARCELA+" - Registro : " + AllTrim(Str(_nRegAtu)) + " de " + AllTrim(Str(_nTotRegs)))  
      EndIf

      U_RFIN002()

      (_cAlias)->(DBSkip())

   EndDo

End Sequence

If Select(_cAlias) <> 0
   (_cAlias)->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Programa----------: MFIN025S
Autor-------------: Igor Melgaço
Data da Criacao---: 22/02/2024
Descrição---------: Workflow de Boletos - Envio de e-mail/notificações para clientes com Títulos a Vencer ou Vencidos.
                    Chamado: 36304.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN025S()

Return _lScheduler
