/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |04/09/2015| Chamado 11726. Gravar campos de data/hora e usuário de liberação de SA
Josué Danich  |10/07/2017| Chamado 20625. Modificada leitura de usuário da função ITRETMAT para padrão Totvs
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT107LIB
Autor-------------: Andre Lisboa
Data da Criacao---: 03/02/2015
Descrição---------: Ponto de entrada valida e efetua liberação das SAs
Parametros--------: Nenhum
Retorno-----------: _lRet -> valor logico que permite ou não a liberação
===============================================================================================================================
*/
User Function MT107LIB()

Local _lRet 	   	:= .F.  
Local _nCodA		:= RetCodUsr()
Local _cGrpP		:= SB1->B1_GRUPO
Local _cSolic  	:= AllTrim(SCP->CP_SOLICIT)
	
    
DBSelectArea("ZZL")
DBSetOrder(3)
//Verifica se usuário tem permissão de liberar SA
If DBSeek(xFilial("ZZL") + _nCodA) .And. ZZL->ZZL_LIBSAS <> 'S'

		xMagHelpFis("Específicos Italac","Liberação não permitida.Usuário não tem permIssão para liberar SAs",;
						"Favor solicitar ao responsável pelas aprovações do seu departamento.")
Else

	cGrpA := ZZL->ZZL_GRPAPR
	cGrpU := Posicione("ZZL",4,"  "+_cSolic,"ZZL->ZZL_GRPAPR")

	//Verifica se usuário pode liberar o grupo de produto escolhido
	If cGrpA == '5'

		If _cGrpP == '0805'

			_lRet := .T.

		Else

			xMagHelpFis("Específicos Italac","Liberação não permitida.",;
			"Usuários do grupo SESMT podem liberar somente produto do grupo Indumentaria (0805) .")	

		EndIf

   	Else

		//Verifica se SA é do mesmo grupo de aprovação do usuário
		If cGrpU == cGrpA .And. _cGrpP <> '0805'

			_lRet := .T.

		Else

			If cGrpA = '0'

				_lRet := .T.

			Else	

				xMagHelpFis("Específicos Italac","Liberação não permitida.",;
				"Solicitação não pertence ao grupo do aprovador.")

			EndIf

		EndIf	

	EndIf						

EndIf
	
//Se está liberado grava campos de usuário e data/hora de liberação
If _lRet

	//Determina matricula do usuário
	PswOrder(1)
	If PswSeek( _nCodA )
		aUsrAux := PswRet(1)
		cMatric := SubStr( aUsrAux[01][22] , 3 , 8 )
	Else
		cMatric := " "
	EndIf
	
	DBSelectArea("SCP")
	RecLock("SCP",.F.)
	
	SCP->CP_I_DTAPR 	:=	Date()
	SCP->CP_I_HRAPR		:=	Time()
	SCP->CP_I_CDAPR		:= 	cMatric
		
	MSUnLock()
		
EndIf
		
Return(_lRet)
