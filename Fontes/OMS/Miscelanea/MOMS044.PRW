/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor     |    Data    |                                             Motivo                                           
------------------------------------------------------------------------------------------------------------------------------- 
                 |            |
=============================================================================================================================== 
*/
#Include "TOTVS.ch"  
#Include "TBICONN.CH"   

/*
===============================================================================================================================
Programa----------: MOMS044
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/06/2019
===============================================================================================================================
Descrição---------: Rotina de alteração do Status do Pedidos de Vendas do Portal, de "A" para "L" e alteração do armazem. 
                    Chamado 29599.
===============================================================================================================================
Parametros--------: _nRecno = Recno da tabela SZW.
===============================================================================================================================
Retorno-----------: Nenhum 
===============================================================================================================================
*/
User Function MOMS044(_nRecno)
Local _cRet := ""
Local _aRetCriter 
Local _cBrooker := ""
Local _cLocalSBZ := ""  

Begin Sequence
   //=================================================================
   // ZW_STATUS => L=Liberado
   //              I=Importado
   //              R=Reprovado 
   //              A=Aguardando a Aprovacao                                                                   
   //=================================================================
  
   SZW->(DBGoTo(_nRecno))
   
   _aRetCriter := U_MOMS044C()

   If ! _aRetCriter[1]
      _cRet := "SUCESSO:FALSO; " + _aRetCriter[2]
      Break
   EndIf
   
   _cBrooker  := Posicione("SA3",1,xFilial("SA3")+SZW->ZW_VEND1,"A3_I_VBROK") 
   _cLocalSBZ := Posicione("SBZ",1,SZW->ZW_FILIAL+SZW->ZW_PRODUTO,"BZ_LOCPAD") 
   
   Begin Transaction        
      SZW->(RecLock("SZW",.F.))
      
      If _cBrooker == "B"      
         If AllTrim(_cLocalSBZ) == "20"  // Alterar para 50
            SZW->ZW_LOCAL := "50"
         ElseIf AllTrim(_cLocalSBZ) == "22"
            SZW->ZW_LOCAL := "52"
         EndIf
      ElseIf _cBrooker == "V"      
         If AllTrim(_cLocalSBZ) == "20"  // Alterar para 70
            SZW->ZW_LOCAL := "70"
         ElseIf AllTrim(_cLocalSBZ) == "22"
            SZW->ZW_LOCAL := "72"
         EndIf
      EndIf
      
      SZW->ZW_DATAAPR := Date()
      SZW->ZW_HORAAPR := Time()
      SZW->ZW_OBSIMP  := "LIBERADO AUTOMATICAMENTE"
      SZW->ZW_STATUS  := "L" 
      SZW->(MSUnLock())
   End Transaction

   _cRet := "SUCESSO:TRUE; Estatus do pedido de vendas atualizado para 'L=Liberado'. "

End Sequence

Return _cRet

/*
===============================================================================================================================
Programa----------: MOMS044C
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/06/2019
===============================================================================================================================
Descrição---------: Valida a liberação dos pedidos de vendas do portal, conforme critérios estabelecidos.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _aRet[1] = .T. = Sucesso nas validações dos critérios de libaração.
                             = .F. = Falha nas validações dos critérios de libaração.
                    _aRet[2] = Mensagem de retorno das validações.
===============================================================================================================================
*/
User Function MOMS044C()
Local _aRet := {.T.,""}

Begin Sequence
   /*
   //======================================================================================================================================
   Elaborar Função no Protheus com execução via JOB, que efetue a liberação do Coordenador (ZW_STATUS de "A" para "L") automaticamente, 
   dependendo dos critérios da Tabela de Preço e do Percentual de Leite magro.

   Critérios:

   Somente Coordenador habilitado;

   Pedidos com ZW_STATUS = “A”;

   Data/Hora de Inclusão do Pedido menor que a Data/Hora do processamento;

   Preço do Pedido valido, conforme Regras da Tabela de Preço;

   Percentual de Leite Magro valido, conforme parâmetro estabelecido.

   Gravar no Pedido do Portal que o pedido foi Liberado automaticamente.
   //======================================================================================================================================
   */

End Sequence

Return _aRet

/*
===============================================================================================================================
Programa----------: MOMS044S
Autor-------------: Julio de Paula Paz
Data da Criacao---: 17/06/2019
===============================================================================================================================
Descrição---------: Rotina de processamento da liberação dos pedidos de vendas do portal em Scheduller.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS044S()
Local _cQry
Local _cFilAtual := "01" 
Local _cLibCoord 

Begin Sequence
   U_ItConOut("[MOMS044S] Alteração Status Pedido Vendas Portal Scheduller: "+DToC(DATE())+" - "+TIME())
   
   //=====================================================================
   // Limpa o ambiente, liberando a licença e fechando as conexões
   //=====================================================================
   RpcClearEnv() 

   //===========================================================================================
   // Preparando o ambiente com a filial da carga recebida
   //===========================================================================================
   U_ItConOut("[MOMS044S] Preparando Ambiente - Alteração Status Pedido Vendas Portal Scheduller: "+DToC(DATE())+" - "+TIME())
   PREPARE ENVIRONMENT EMPRESA '01' FILIAL '01'; 
           TABLES "SC9","SA1","SC5","SC6","ZP1","SZW","SB1";
           MODULO 'OMS'
   cFilAnt := _cFilAtual
   
   _cLibCoord := U_ItGetMv("IT_LIBCOORD","") 
   
   //===========================================================================================
   // Query de seleção de pedidos de vendas do portal com situação "A-Aguardando a Aprovação"
   //===========================================================================================
   _cQry := " SELECT DISTINCT SZW.R_E_C_N_O_ NRRECNO, SZW.ZW_FILIAL , SZW.ZW_IDPED "
   _cQry += " FROM " + RetSqlName('SZW') + " SZW, " + RetSqlName('SA3') + " SA3 "
   _cQry += " WHERE "+ RetSqlDel('SZW') + " AND " + RetSqlDel('SA3') 
   _cQry += " AND ZW_VEND1 = A3_COD AND A3_SUPER IN " + FormatIn(AllTrim(_cLibCoord),";")
   _cQry += " AND ZW_STATUS = 'A' "
   _cQry += " ORDER BY SZW.ZW_FILIAL, SZW.ZW_IDPED "

   If Select("TRBSZW") <> 0
	  TRBSZW->( DBCloseArea(  ) )
   EndIf
   
   U_ItConOut("[MOMS044S] Rodando Query - Alteração Status Pedido Vendas Portal Scheduller: "+DToC(DATE())+" - "+TIME())
   DBUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry) , "TRBSZW" , .T. , .F. )

   While !(TRBSZW->(Eof()))    
            
      U_ItConOut("[MOMS044S] Alterando Status - Alteração Status Pedido Vendas Portal: " + StrZero(TRBSZW->NRRECNO,10) + " - " + DToC(DATE())+" - "+TIME()) 
      _cRetorno := U_MOMS044(TRBSZW->NRRECNO)  
      U_ItConOut("[MOMS044S] Retorno Alteração Status Pedido Vendas Portal Scheduller: " + _cRetorno+" - "+DToC(DATE())+" - "+TIME()) 

      TRBSZW->(DBSkip())
   EndDo 

End Sequence    

If Select("TRBSZW") <> 0
   TRBSZW->( DBCloseArea(  ) )
EndIf

Return
