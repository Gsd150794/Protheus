
/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"   

/*
===============================================================================================================================
Programa----------: MTA650E 
Autor-------------: Carlos Cleber A.Silva
Data da Criacao---: 29/11/2013
Descrição---------: Ponto de entrada para verificar se existe apontamento de perda na ordem de producao.
					http://tdn.totvs.com.br/pages/releaseview.action?pageId=6089302
					Caso exista apontamento de perda, na OP sera solicitado que exclua o apontamento de perda primeiro para
					depois fazer a exclusao da op Chamado 4442
Parametros--------: Nenhum
Retorno-----------: .T. = Permite confirmar 
------------------: .F. = Nao Permite confirmar 
===============================================================================================================================
*/
User Function MTA650E() 

 Local aAreaSBC	:= SBC->(GetArea())
 Local aAreaSC2	:= SC2->(GetArea())   
 Local lRet     := .T.

 DBSelectArea("SBC")
 DBSetOrder(1)
 DBGoTop()

 If DBSeek(xFilial("SBC")+SC2->C2_NUM)  
 
 lRet := .F. //Se Falso (.F.)nao executa a exclusao da Op. 

    	If AllTrim(SC2->C2_NUM) == SubStr(SBC->BC_OP,1,6)  
    	
	       MsgAlert("Existem apontamentos de perda para esta OP " +SC2->C2_NUM+ " , estes devem ser excluídos para continuar a operação.","MTA650E")    
    	    	
    	EndIf
 Else
 
 lRet := .T. //Se verdadeiro (.T.), prossegue com a exclusao da Op
 
 EndIf 

 FWRestArea(aAreaSC2)
 FWRestArea(aAreaSBC)

Return(lRet)
