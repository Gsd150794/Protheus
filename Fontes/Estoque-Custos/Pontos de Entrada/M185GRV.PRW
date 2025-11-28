/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
André Lisboa  |28/11/2017| Chamado 22688. Validar se a baixa é por item ou por toda SA
Alex Wallauer |04/09/2018| Chamado 26146. Coloquei a gravação do campo D3_I_NUMCP
Julio Paz     |25/04/2025| Chamado 50005. Desenvolvimento de novos controles na rotina de baixa de EPI. Limpar o conteúdo do 
			  |			 | campo TNF_I_OBS na Entrega do EPI.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: M185GRV
Autor-------------: Josué Danich Prestes	
Data da Criacao---: 14/11/2017
Descrição---------: Ponto de entrada após gravação da baixa de solicitação ao armazém - Chamado 22385
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function M185GRV( )
Local _nI 

If isincallstack("A185GERAAUT")
	If !Empty(CCC) .Or. Empty(SD3->D3_I_NUMCP)

		RecLock("SD3",.F.)
	    If !Empty(CCC)
		   SD3->D3_CC :=  AllTrim(CCC)
		EndIf   
        If Empty(SD3->D3_I_NUMCP)
	  	   SD3->D3_I_NUMCP := SCP->CP_NUM
        EndIf
		SD3->(MSUnLock())

	EndIf
	
	//===================================================================
	// Desenvolvimento de novos controles na rotina de entrega de EPIs. 
	// Limpar o conteúdo do campo TNF_I_OBS na entrega do EPI. 
	//===================================================================
	TNF->(DBSetOrder(6)) // TNF_FILIAL+TNF_NUMSA+TNF_ITEMSA
    For _nI := 1 To Len(aDadosCQ)
	                  // Filial       + Codigo SA     + Item SA    
        If TNF->(MsSeek(xFilial("TNF")+aDadosCQ[_nI,2]+aDadosCQ[_nI,3]))
           If TNF->TNF_INDDEV == "2"
              TNF->(RecLock("TNF",.F.))
              TNF->TNF_I_OBS := ""
              TNF->(MSUnLock())
		   EndIf 
		EndIf 
	Next 
	
EndIf

Return
