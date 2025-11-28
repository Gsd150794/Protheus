/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |11/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MBRWBTN
Autor-------------: Talita Teixeira
Data da Criacao---: 17/02/2014
Descrição---------: Ponto de Entrada generico utilizado para validar as execução das rotinas de liberação de crédito
					Valida a permissao para liberacao automatica das rotinas de liberação de crédito: MA450CLAUT, A450LIBAUT.
					Foi bloqueado também o uso da rotina de liberação credito/estoque conforme solicitado pelo Tiago
Parametros--------: Nenhum
Retorno-----------: .T. = Permite liberacao manual do Estoque
					.F. = Nao Permite liberacao manual do Estoque
===============================================================================================================================
*/
User Function MBRWBTN

Local aArea 	:= FWGetArea() As Array
Local lRet 		:= .T. As Logical

If ParamIXB[4] == "MA450CLAUT" .Or. ParamIXB[4] == "A450LIBAUT" 
	DBSelectArea("ZZL")
	ZZL->(DBSetOrder(1))
	If ZZL->(DBSeek(xFilial("ZZL")+FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3])) .And. ZZL->ZZL_LIBCRE == 'S'
		lRet := .T.	
	Else   
		xMagHelpFis("MBRWBTN01","Usuário sem acesso para liberação de pedido por crédito ","Favor contactar o departamento de informática informando do erro ocorrido.")
		lValid:= .F.
		lRet := .F.		
	EndIf	
ElseIf ParamIXB[4] == "A456LIBAUT" .Or. ParamIXB[4] == "A456LIBMAN"
	xMagHelpFis("MBRWBTN02","Rotina bloqueada pelo administrador do sistema ","Favor utilizar as rotinas de Liberação de Estoque e/ou Liberação de Crédito para a liberação do pedido.")
	lRet:= .F.	  
EndIf
FWRestArea(aArea)

Return lRet
