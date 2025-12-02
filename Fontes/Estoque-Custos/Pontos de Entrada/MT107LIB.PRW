#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT107LIB
Autor-------------: Andre Lisboa
Data da Criacao---: 03/02/2015
===============================================================================================================================
Descrição---------: Ponto de entrada valida e efetua liberação das SAs
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _lRet -> valor logico que permite ou não a liberação
===============================================================================================================================
*/
User Function MT107LIB()

Local _lRet 	   	:= .F.  
Local _nCodA		:= RetCodUsr()
Local _cGrpP		:= SB1->B1_GRUPO
Local _cSolic  		:= AllTrim(SCP->CP_SOLICIT)
Local cMatric       := ""


DBSelectArea("ZZL")
DBSetOrder(3)
//Verifica se usuário tem permissão de liberar SA
If DBSeek(xFilial("ZZL") + _nCodA) .and. ZZL->ZZL_LIBSAS <> 'S'

		xmaghelpfis("Específicos Italac","Liberação não permitida.Usuário não tem permIssão para liberar SAs",;
						"Favor solicitar ao responsável pelas aprovações do seu departamento.")
Else

	cGrpA := ZZL->ZZL_GRPAPR
	cGrpU := Posicione("ZZL",4,"  "+_cSolic,"ZZL->ZZL_GRPAPR")

	//Verifica se usuário pode liberar o grupo de produto escolhido
	If cGrpA == '5'

		If _cGrpP == '0805'

			_lRet := .T.

		Else

			xmaghelpfis("Específicos Italac","Liberação não permitida.",;
			"Usuários do grupo SESMT podem liberar somente produto do grupo Indumentaria (0805) .")	

		Endif

   	Else

		//Verifica se SA é do mesmo grupo de aprovação do usuário
		If cGrpU == cGrpA .and. _cGrpP <> '0805'

			_lRet := .T.

		Else

			If cGrpA = '0'

				_lRet := .T.

			Else	

				xmaghelpfis("Específicos Italac","Liberação não permitida.",;
				"Solicitação não pertence ao grupo do aprovador.")

			Endif

		Endif	

	Endif						

Endif
	
//Se está liberado grava campos de usuário e data/hora de liberação
If _lRet

	If Type('__cUserId') == 'C'
		cMatric := FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3] // MATRICULA
	Else
		cMatric := " "
	EndIf
				
	DBSelectArea("SCP")
	RecLock("SCP",.F.)
	
	SCP->CP_I_DTAPR 	:=	date()
	SCP->CP_I_HRAPR		:=	time()
	SCP->CP_I_CDAPR		:= 	cMatric
		
	MsUnlock()
		
Endif
		
Return(_lRet)
