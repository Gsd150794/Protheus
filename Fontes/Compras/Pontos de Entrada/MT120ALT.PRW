/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |01/11/2019| Chamado 30987. Validação de existe a taxa na copia tb. 
Alex Wallauer |18/12/2023| Chamado 45875. Nova validação para pedidos bloqueados e Rejeitados pelo Worflow de Compras
Julio Paz     |13/05/2024| Chamado 47221. Ajustar Rotina de Compras para tabalhar com a nova moeda Libras Esterlinas. 
===============================================================================================================================
*/

#Include "TOTVS.ch"

Static nAviso

/*
===============================================================================================================================
Programa--------: MT120ALT
Autor-----------: Talita Teixeira
Data da Criacao-: 20/02/2014
Descrição-------: P.E. que valida antes das telas de manutenção do Pedido de compra. (MATA120)
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function MT120ALT(_cRetorno)

Local aArea		:= FWGetArea()
Local lExecuta 	:= .T. 
Local cPedido	:= SC7->C7_NUM
Local nContador	:= 0   
Local _cMensagem:= ""
DEFAULT _cRetorno:="PADRAO"

If _cRetorno = "RETORNA_OPCAO_AVISO" 
   Return nAviso
EndIf

If ParamIXB[1] == 4 .And. !IsInCallStack('A120COPIA') //ProcName(3) <> 'A120COPIA'  //05/03/14 - Talita Teixeira - Incluida validação para que se permita a copia de pedidos finalizados, sendo assim o bloqueio só acontecerá na alteração do pedido. Chamado: 5603 
	   
	DBSelectArea("SC7")
	DBSetOrder(1)//Filial+Numero+Item+Sequencia 
	SC7->(DBGoTop())
	DBSeek (xFilial("SC7")+cPedido) 
		
	While (!Eof()) .And. cPedido == SC7->C7_NUM
		If SC7->C7_QUANT <> (SC7->C7_QUJE + SC7->C7_QTDACLA) .And. SC7->C7_RESIDUO <> "S"
			nContador++ 
		EndIf
		SC7->(DBSkip())
	EndDo 
	   
	If nContador == 0
		U_ITMsg("Não é permitida a alteração de pedido finalizado.",,,3)
		lExecuta:= .F.
	EndIf    
	DBSeek(xFilial("SC7")+cPedido)
    _cMensagem:=""
    If lExecuta .And. SCR->(DBSeek(xFilial("SCR")+"PC"+AllTrim(cPedido) ))
       While SCR->(!Eof()) .And. xFilial("SCR")+"PC"+AllTrim(cPedido) == SCR->CR_FILIAL+SCR->CR_TIPO+AllTrim(SCR->CR_NUM)
          If SCR->CR_STATUS = "04"
             _cMensagem:="Bloqueado pelo Worflow de Compras. (Bloqueado por "+AllTrim(Posicione("SAK",1,xFilial("SAK")+SCR->CR_APROV,"AK_NOME"))+" ("+SCR->CR_GRUPO+")"
	    	 Exit
          EndIf
          If SCR->CR_STATUS = "06"
             _cMensagem:="Rejeitado pelo Worflow de Compras. (Rejeitado por "+AllTrim(Posicione("SAK",1,xFilial("SAK")+SCR->CR_APROV,"AK_NOME"))+" ("+SCR->CR_GRUPO+")"
	    	 Exit
          EndIf
          SCR->(DBSkip()) 
       EndDo
	   If !Empty(_cMensagem)
          U_ITMsg("Não é permitida a alteração de Pedido "+_cMensagem,"Atenção","Procure o Gestor de compras.",1)
          lExecuta:= .F.
	   EndIf
	EndIf

ElseIf ParamIXB[1] == 3 .Or. IsInCallStack('A120COPIA') //ProcName(3) <> 'A120COPIA'//INCLUSAO E COPIA DE PC     

    nAviso:=AVISO("MOEDAS","Qual será a moeda do Pedido de Compras?",{"REAL","DOLAR","EURO","GBP","FECHAR"},3)
    
    If nAviso = 5
       lExecuta:= .F.
    EndIf  	  

    nAviso:=If(nAviso>2,(nAviso+1),nAviso)
    
    If nAviso <> 1 .And. (!SM2->(DBSeek(DToS(dDataBase))) .Or.  SM2->(FIELDGET( FIELDPOS( "M2_MOEDA"+Str(nAviso,1) ) ))  = 0)
	    U_ITMsg('Taxa da moeda selecionada não casdastrada na data do sistema: '+DToC(dDataBase),"ATENÇÃO",;
		   	    'Cadastre a taxa da moeda selecionada para data do sistema.',3)    
       lExecuta:= .F.
    EndIf
    
EndIf  	  

FWRestArea(aArea)

Return (lExecuta) 
