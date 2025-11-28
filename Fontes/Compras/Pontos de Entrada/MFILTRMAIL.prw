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
Programa----------: MFILTRMAIL
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 23/07/2018
Descrição---------: Esse ponto de entrada é utilizado para filtrar os e-mails, usuários e grupos que devem ser considerados no 
					envio do Messenger.
Parametros--------: cParUsuario -> C -> ParamIXB[1]- String com os usuários que devem receber o e-mail do Messenger
					cParGrUsuario -> C -> ParamIXB[2]-String com os grupos de usuários que devem receber o e-mail do Messenger
					cParEmails -> C -> ParamIXB[3]- String com as contas de e-mail avulsas que devem receber o e-mail do Messenger
					Existem duas variáveis privadas que podem ser utilizadas para consulta, mas NÂO PODE SEREM ALTERADAS:
					cFormEvent - Contém o codigo do evento
					aFormDados - Array com os dados relativos ao evento
Retorno-----------: aRetorMail -> A -> aRetorMail[1] - String com os usuários que devem receber o e-mail do Messenger.
									aRetorMail[2] - String com os grupos de usuários que devem receber o e-mail do Messenger.
									aRetorMail[3] - String com as contas de e-mail avulsas que deve m receber o e-mail do Messenger.
===============================================================================================================================
*/
User Function MFILTRMAIL

Local _aArea 	:= FWGetArea()
Local _aAreaSC7 := SC7->(GetArea())
Local _aAreaSC1 := SC1->(GetArea())
Local _aAreaSAN := SAN->(GetArea())
Local _aRetorMail := {}

//====================================================================================================
// Verifico se quem incluiu a SC está cadastrado para receber o workflow. Se estiver, disparo o e-mail
// somente para ele. Preciso usar esse e o PE MAVALMMAIL em conjunto. Aqui defini para quem vai ser 
// enviado o e-mail e no outro faço a mesma validação para dizer que pode enviar.
//====================================================================================================
If cFormEvent == '030' .And. !Empty(SD1->D1_PEDIDO)
	SC7->(DBSetOrder(1))
	SC7->(DBSeek(SD1->(D1_FILIAL+D1_PEDIDO+D1_ITEMPC)))
	If !Empty(SC7->C7_NUMSC)
		DBSelectArea("SC1")
		SC1->(DBSetOrder(1))
		SC1->(DBSeek(SC7->(C7_FILIAL+C7_NUMSC+C7_ITEMSC))) 
		SAN->(DBSetOrder(3))
		If SAN->(DBSeek(xFilial("SAN")+cFormEvent+SC1->C1_USER)) 
			aAdd(_aRetorMail,SC1->C1_USER)
			aAdd(_aRetorMail,"")
			aAdd(_aRetorMail,"")
		EndIf
	EndIf
EndIf

FWRestArea(_aAreaSC7)
FWRestArea(_aAreaSC1)
FWRestArea(_aAreaSAN)
FWRestArea(_aArea)

Return _aRetorMail
