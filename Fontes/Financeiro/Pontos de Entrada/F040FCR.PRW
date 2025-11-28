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
Programa--------: F040FCR
Autor-----------: Josué Danich Prestes
Data da Criacao-: 03/11/2017
Descrição-------: Ponto de entrada para manipulação de dados gravados após a inclusão de um título a receber - Chamado 22079
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function F040FCR()

Local _aareaSA1 := SA1->(Getarea())
Local _aareaSE1 := SE1->(Getarea())
Local _cgrup := Posicione("SA1",1,xFilial("SA1")+SE1->E1_CLIENTE+SE1->E1_LOJA,'A1_I_GRCLI')
Local _cindice := SE1->E1_FILIAL+SE1->E1_NUM+SE1->E1_SERIE+SE1->E1_CLIENTE+SE1->E1_LOJA 

If _cgrup == '23' .Or. _cgrup == '24'

	//Posicione e modifica todos os registros relacionados ao SE1 pois no faturamento não passa por esse ponto de entrada
	
	SE1->(DbOrderNickName("IT_QUERY2") ) //E1_FILIAL+E1_NUM+E1_SERIE+E1_CLIENTE+E1_LOJA                                                                                                                    
	
	If SE1->(DBSeek(_cindice))
	
		While SE1->E1_FILIAL+SE1->E1_NUM+SE1->E1_SERIE+SE1->E1_CLIENTE+SE1->E1_LOJA == _cindice
		
			SE1->(RecLock("SE1", .F.))
			SE1->E1_I_CART := '12'
			SE1->(MSUnLock())
			
			SE1->(DBSkip())
			
		EndDo
		
	EndIf
 	
EndIf

SA1->(FWRestArea(_aareaSA1))
SE1->(FWRestArea(_aareaSE1))

Return
