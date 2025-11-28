/*
===============================================================================================================================
                          ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |    Data    |                                             Motivo                                          
-------------------------------------------------------------------------------------------------------------------------------
              |            |
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "TopConn.ch"

/*
===============================================================================================================================
Programa----------: MOMS063
Autor-------------: Julio de Paula Paz
Data da Criacao---: 22/12/2021
===============================================================================================================================
Descrição---------: Ajusta rede de acordo com cadastro de desconto contratual. Chamado 30177.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS063()

Begin Sequence 

   If ! U_ITMsg("Confirma os ajutes da Rede com base no cadastro de desconto contratual?","Atenção" , , ,2, 2)
      Break 
   EndIf 

   Processa( {|| U_MOMS063P() }, "Aguarde...", "Ajuste Rede x Desconto Contratual...",.F.)

   U_ITMsg("Processamento Finalizado...","Atenção", , 2)

End Sequence 

Return

/*
===============================================================================================================================
Programa----------: MOMS063
Autor-------------: Julio de Paula Paz
Data da Criacao---: 22/12/2021
===============================================================================================================================
Descrição---------: Lê o cadastro de Redes, verifica se há desconto contratual e ajusta a tabela.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS063P()
Local _nI 
Local _cQry 
Local _nTotRegs 

Begin Sequence 

   ACY->(DBGoTop())

   _nTotRegs := ACY->(RecCount())

   ProcRegua(_nTotRegs)

   ACY->(DBGoTop())
   _nI := 1

   While ! ACY->(Eof())
      IncProc("Processando registros cadastro Grupo de Vendas: " + StrZero(_nI,8) +" / " + StrZero(_nTotRegs,8) )
      
      _cQry := " SELECT Count(*) AS TOTREGS "
      _cQry += " FROM " + RetSqlName("ZAZ") + " ZAZ "
      _cQry += " WHERE ZAZ.D_E_L_E_T_ = ' ' "
      _cQry += " AND ZAZ_GRPVEN = '" + ACY->ACY_GRPVEN +"' "

      If Select("QRYZAZ") > 0
         QRYZAZ->(DBCloseArea())
      EndIf
      
      DbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "QRYZAZ" , .T., .F. )

      ACY->(RecLock("ACY",.F.))
      If QRYZAZ->TOTREGS > 0
         ACY->ACY_I_DESC := "S" // S=Sim = Possui desconto contratual 
      Else 
         ACY->ACY_I_DESC := "N" // N=Nao = possui desconto contratual
      EndIf 
      ACY->(MSUnLock())

      ACY->(DBSkip())
      _nI += 1

   EndDo 

End Sequence 

If Select("QRYZAZ") > 0
   QRYZAZ->(DBCloseArea())
EndIf

Return
