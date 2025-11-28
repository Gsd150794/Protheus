/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |16/02/2016| Chamado 14099. Incluida pergunta de continua caso seja liberação completa
Josué Danich  |19/02/2016| Chamado 14097. Ajuste de campo de liberação completa
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT450MAN
Autor-------------: Talita Teixeira
Data da Criacao---: 14/02/2014    
Descrição---------: Validacao do usuario para liberação de credito manual através da rotina Analise Credito Pedido 
Parametros--------: Lógico - Procede ou não a liberação de crédito do pedido
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT450MAN

Local _aArea 	:= FWGetArea()
Local _lRet		:= .F.

DBSelectArea("ZZL")  
ZZL->( DBSetOrder(1) )
If ZZL->( DBSeek(xFilial("ZZL")+FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]) ) .And. ZZL->ZZL_LIBCRE == 'S'
	_lRet := .T.		
Else
	xMagHelpFis("MT450MAN01","Usuário sem acesso para liberação de pedido por crédito ","Favor contactar o departamento de informática informando do erro ocorrido.")
EndIf	

//Verifica se é liberação completa e se usuário confirma
SC5->( DBSetOrder(1))
SC5->( DBSeek(SC9->C9_FILIAL+SC9->C9_PEDIDO) )

If _lRet .And. SC5->C5_I_LIBC == 1 //Se teve liberação completa inicial
	//Alerta usuário
	If FWAlertYesNo("Esse pedido terá o crédito liberado de forma permanente! Confirma?","MT450MAN02")
		_lRet := .F.
		SC5->(RecLock("SC5",.F.))

		//Marca C5_I_LIBC sem liberação completa
		SC5->C5_I_LIBC := 0
		SC5->( MSUnLock() )
	Else
		SC5->(RecLock("SC5",.F.))
		//Marca C5_I_LIBC com liberação completa
		SC5->C5_I_LIBC := 2
		SC5->( MSUnLock() )
	EndIf
EndIf
	
FWRestArea(_aArea)

Return _lRet
