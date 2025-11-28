/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Talita   	  |19/07/2013| Chamado 3804. Alterado a validação que era feita pelo parametro IT_NFDUSU para que seja feito pelo 
			  |			 | campo ZZL_NFDUSUda rotina de gestão de usuario.
Erich Buttner |16/09/2013| Chamado 4224. Alterado para verificar outros tipos de notas e para contemplar os pedidos de vendas
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AEST025
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 11/02/2011
Descrição---------: Rotina utilizada no item modo de edicao dos campos: D1_NFORI,D1_SERIORI,D1_ITEMORI para possibilitar somente
					aos usuarios cadastrados no parametro IT_NFDUSU efetuar a alteracao dos campos citados acima.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AEST025()   

Local _lRet:= .F.
Local cUser:=""  
Local cTip:= If (FunName() == 'MATA410', M->C5_TIPO, cTipo) // ACRESCENTADO POR ERICH BUTTNER DIA 13/09/13 - VERIFICAR QUAL A FUNÇÃO ESTA CHAMANDO A VALIDAÇÃO E GRAVAR O TIPO NA VARIAVEL cTipo

If cTip == "D"	//"Até o momento não é possível bloquear os complementos, pois não foi possível separar os complementos de compra/venda dos de 
					//devolução de compras/vendas. Para os complementos de devolução de compra/venda, o fornecedor é cadastrado como cliente e 
					//vice-versa, fazendo com que a rotina para buscar a nota de origem não consiga localizar a informação, sendo necessário informá-la 
					//manualmente."
			cUser := FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
	
	DBSelectArea("ZZL")  // Alteração - Talita - 19/07/13 - Alterado a validação que era feita pelo parametro IT_NFDUSU para que seja feito pelo campo ZZL_NFDUSU da rotina de gestão de usuario. Chamado: 3804
	DBSetOrder(1)
	DBSeek(xFilial("ZZL")+cUser)
	If ZZL->ZZL_NFDUSU == 'S'
		_lRet:= .T.    	
	EndIf  
	
Else      	
	_lRet:= .T.
EndIf

Return _lRet
