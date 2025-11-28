/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |10/04/2018| Chamado 23960. Realização de ajustes nas rotinas de entrega e devolução de EPI, para impressão correta
              |          | dos comprovantes.
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MDTA6957
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/11/2017
Descrição---------: Ponto de entrada da impressão de recibos de devolução de EPIs
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MDTA6957()

Begin Sequence
   aDevEPI := U_MDT6954H("RETORNA_ARRAY_RECNOS_TNF")
   If Len( aDevEPI ) > 0
      U_RMDT004( , , aDevEPI , .T. )	
   EndIf
End Sequence

Return

/*
===============================================================================================================================
Programa----------: MDT6957I
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/11/2017
Descrição---------: Imprime os EPIs de Troca ou Reuso.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MDT6957I()

Local _aRecEPIs := {}
Local _aOrd := SaveOrd({"TNF"})
Local _nRegAtu := TNF->(Recno())

Begin Sequence
   If !  MsgYesNo("Confirm a emissão dos recibos de devolução de EPIs destinados a Troca ou Reuso?","MDTA695701")
      Break
   EndIf

   //================================================================================
   // Carrega o array _aRecEPIs com os EPIs liberados na rotina de estoques e custos.
   //================================================================================
   TNF->(DBSetOrder(3)) // TNF_FILIAL+TNF_MAT+TNF_CODEPI+DToS(TNF_DTENTR)+TNF_HRENTR                                                                                                       
   TNF->(DBSeek(xFilial("TNF")+M->RA_MAT))
   
   While !TNF->(Eof()) .And. TNF->TNF_FILIAL+TNF->TNF_MAT == xFilial("TNF")+M->RA_MAT
      
      If TNF->TNF_I_IMPR == "1" // Sim
         aAdd(_aRecEPIs,TNF->(Recno()))
               
         TNF->(RecLock("TNF",.F.))
         TNF->TNF_I_IMPR := "2" // Não
         TNF->(MSUnLock())
      EndIf
      
      TNF->(DBSkip())
   EndDo
   
   If Len(_aRecEPIs) > 0
      U_RMDT004( , , _aRecEPIs , .T. )	
   Else
      MsgAlert("Não existem dados para a impressão dos recibos de devolução de EPIs destinados a troca ou reuso.","MDTA695702")
   EndIf

End Sequence

RestOrd(_aOrd)
TNF->(DBGoTo(_nRegAtu))

Return
