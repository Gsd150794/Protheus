/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Josué Danich     | 14/12/2017 | Retirada apresentação de tela de log para webservice - Chamado 22888         
 Josué Danich     | 12/09/2018 | Separação de tela de log para depois da transação - Chamado 26257             
 Lucas Borges     | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===================================================================================================================================================================
Analista         - Programador     - Inicio     - Envio    - Chamado - Motivo da Alteração
===================================================================================================================================================================
Vanderlei Alves  - Alex Wallauer   - 09/06/25   - 10/06/25 - 45229   - Tratamento para validar FWIsInCallStack("U_AOMS085B") junto com FWIsInCallStack("U_ALTERAP")
===================================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "RwMake.ch"

/*
===============================================================================================================================
Programa----------: M440SC9I
Autor-------------: Josué Danich Prestes
Data da Criacao---: 15/02/2016
===============================================================================================================================
Descrição---------: PE na Liberação do Pedidos de Vendas
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function M440SC9I()

Local _aSC5			:= GetArea("SC5") 
Local _aSC6			:= GetArea("SC6") 
Local _aSC9			:= GetArea("SC9") 
Local _lvalida		:= .T.

SC5->( DBSetOrder(1))
SC5->( DBSeek(SC9->C9_FILIAL+SC9->C9_PEDIDO) )

If _lvalida .And. (SC5->C5_I_BLCRE == 'L' .Or. SC5->C5_I_BLCRE == " ")//Se teve liberação ou passou na avaliação de crédito na  garante que não tem bloqueio de crédito 

   SC6->( DBSetOrder(1))
   SC6->( DBSeek(SC5->C5_FILIAL+SC5->C5_NUM) )

	//Garante que vai gravar o c5_liberok
	SC5->(RecLock("SC5",.F.))
   	SC5->C5_LIBEROK := "S"
   	SC5->(MSUnLock())

	SC6->( DBSetOrder(1))
	SC6->( DBSeek(SC5->C5_FILIAL+SC5->C5_NUM) )


	If !(Empty(SC9->C9_BLCRED))
				
		  SC9->(RecLock("SC9",.F.))
    
		  SC9->C9_BLCRED := " "
   
		  SC9->(MSUnLock("SC9"))
   		
		  //Faz análise e liberação de estoque pois o padrão não analisa estoque se o crédito está bloqueado
		  //Posiciona SC6 pois a função A440VerSb2 depende do SC6 posicionado para analisar o estoque
		  SC6->(DBSetOrder(1))
   				   				
		  If SC6->(DBSeek(SC9->C9_FILIAL+SC9->C9_PEDIDO+SC9->C9_ITEM)) .And. A440VerSB2(SC9->C9_QTDLIB)
   				
			  If !(Empty(SC9->C9_BLEST))
					  
			    SC6->(RecLock("SC6",.F.))
			    SC9->(RecLock("SC9",.F.))
    
			    MaAvalSC9("SC9",5,{{ "","","","",SC9->C9_QTDLIB,SC9->C9_QTDLIB2,Ctod(""),"","","",SC9->C9_LOCAL}})
			    SC9->C9_BLEST := ""
   
		        SC9->(MSUnLock())
		        SC6->(MSUnLock())
   				        
		      EndIf
   	
   					
		  EndIf	
   	
	EndIf

EndIf	

If  !FWIsInCallStack("U_ALTERAP") .And. !FWIsInCallStack("U_INCLUIC") .And. !FWIsInCallStack("U_AOMS085B") 
 	U_ENVSITPV() //Envia interface de situação do pedido para o RDC se For pedido RDC e grava campo de situação do pedido XFUNOMS
EndIf

FWRestArea(_aSC5)	
FWRestArea(_aSC6)	
FWRestArea(_aSC9)	
						
Return
