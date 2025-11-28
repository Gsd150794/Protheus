/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |03/12/2021| Chamado: 38508. Criacao da opcao de Reenvio de WF
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT105MNU
Autor-------------: Tiago Correa Castro
Data da Criacao---: 05/03/2009  
Descrição---------: Ponto de entrada com o objetivo de incluir novas opcoes nao rotina de Solicitacao ao Almoxarifado.
Parametros--------: Nenhum
Retorno-----------: _aRet: Opcoes de menu
===============================================================================================================================
*/
User Function MT105MNU()
Local _aRet:={}
	
aAdd(_aRet,{"Imp. Solic.",'U_REST001()',0,2})
aAdd(_aRet,{"Reenvio WF" ,'U_REEVIOWF()',0,2})

Return(_aRet)                       
/*
===============================================================================================================================
Programa----------: REEVIOWF
Autor-------------: Alex Wallauer
Data da Criacao---: 03/12/2021
Descrição---------: Rotina responsável por atualizar a flag de reenvio do workflow
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function REEVIOWF()
Local aArea	:= SCP->(GetArea())
Local cFilSP:= SCP->CP_FILIAL
Local cNumSP:= SCP->CP_NUM

If SCP->CP_STATSA == 'B'

   SCP->(DBSetOrder(1))
   SCP->(DBSeek(cFilSP+cNumSP))        
   While (!SCP->(Eof()) .And. ( cFilSP+cNumSP == SCP->CP_FILIAL+SCP->CP_NUM )) 
   	  SCP->(RecLock("SCP",.F.))
   	  SCP->CP_I_SITWF:= "1"//para enviar
        SCP->CP_I_HTMWF:= ""
   	  SCP->(MSUnLock())    		
      SCP->(DBSkip())
   EndDo
   U_ITMsg("Solicitação ao armazem preparada para reenvio.",'REENVO DE SOLICITACAO',,2) // OK
Else
   U_ITMsg("Esta solicitação  ao armazem não pode ser reenviada, pois esta encontra-se Liberada ou Rejeitada.",'Atenção!',,3) // ALERT
EndIf

FWRestArea(aArea)
Return
