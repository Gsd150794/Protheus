/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |01/12/2017| Chamado 22690. Inclusão de regra por fornecedor
Josué Danich  |31/08/2017| Chamado 26044. Inclusão de regra por cliente
Lucas Borges  |27/05/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: ACOM034
Autor-------------: Julio de Paula Paz
Data da Criacao---: 05/12/2016
Descrição---------: Rotina de manutenção no cadastro de vinculação de filial x centro de custo x produtos.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function ACOM034()  

Local _cTitulo := "Cadastro de Vinculação Filial x Centro de Custo x Produtos/Fornecedor" As Character
Local _bok := {||U_ACOM034O()} As Codeblock

AxCadastro("ZFX",_cTitulo,,,,,_bok)

Return

/*
===============================================================================================================================
Programa----------: ACOM034V
Autor-------------: Julio de Paula Paz
Data da Criacao---: 05/12/2016
Descrição---------: Validar a digitação dos dados no cadastro de vinculação de filial x centro de custo x produtos.
Parametros--------: _cCampo = Campo ou trecho da rotina que chamou a validação.
Retorno-----------: True ou False
===============================================================================================================================
*/  
User Function ACOM034V(_cCampo As Character) 

Local _lRet := .T. As Logical
Local _aOrd := SaveOrd({"ZFX"}) As Array
Local _cnome := "" As Character

Begin Sequence
   If _cCampo == "ZFX_CCUSTO" 
      ZFX->(DBSetOrder(1))
      
      If M->ZFX_TIPO == "P" .And. ZFX->(DBSeek(xFilial("ZFX")+M->ZFX_PRODUT+M->ZFX_CCUSTO)) 
         FWAlertWarning("Produto x Centro de Custo já cadastrado para esta filial.","ACOM03401")
         _lRet := .F.    
         Break
      EndIf
   
   EndIf

   SA1->(DBSetOrder(1))
   If SA1->(DBSeek(xFilial("SA1")+M->ZFX_CLIENT+M->ZFX_LOJC))
      _cnome := SA1->A1_NOME
   EndIf

   If !Empty(M->ZFX_CLIENT) .And. !Empty(M->ZFX_LOJC)
	  M->ZFX_NOMEC := _cnome
   EndIf
   
End Sequence

RestOrd(_aOrd)

Return _lRet

/*
===============================================================================================================================
Programa----------: ACOM034O
Autor-------------: Josué Danich Prestes
Data da Criacao---: 05/12/2016
Descrição---------: Validação do cadastro
Parametros--------: Nenhum
Retorno-----------: True ou False
===============================================================================================================================
*/  
User Function ACOM034O

Local _lRet := .T. As Logical

Begin Sequence

If M->ZFX_TIPO == 'P' 
	If Empty(M->ZFX_PRODUT)
		FWAlertWarning("Para regra tipo produto o campo produto é obrigatório!","ACOM03402")
 		_lRet := .F.
 		Break
 	EndIf
 	
 	ZFX->(DBSetOrder(1))
    If (inclui .Or. M->ZFX_PRODUT != ZFX->ZFX_PRODUT) .And. ZFX->(DBSeek(xFilial("ZFX")+M->ZFX_PRODUT)) 
 		FWAlertInfo("Regra para esse produto já cadastrada nessa filial.","ACOM03403")
 		_lRet := .F.    
 		Break
 	EndIf
 
 	If !(Empty(M->ZX_FORNEC) .And. Empty(M->ZX_LOJA) .And. Empty(M->ZX_CLIENT) .And. Empty(M->ZX_LOJC) )
 		If FWAlertYesNo("Para registro do tipo produto os campos Fornecedor e Cliente devem estar vazios, apagar campos e confirmar gravação?","ACOM03404")
 			M->ZX_FORNEC := ""
 			M->ZX_LOJA := ""
 			M->ZX_CLIENT := ""
 			M->ZX_LOJC := ""
 		Else
			_lRet := .F.    
 			Break
 		EndIf
 	EndIf
EndIf

If M->ZFX_TIPO == 'F' 
 	If Empty(M->ZFX_FORNEC)
 		FWAlertWarning("Para regra tipo fornecedor o campo fornecedor é obrigatório!","ACOM03405")
 		_lRet := .F.
 		Break
 	EndIf
 	
 	ZFX->(DBSetOrder(3))
      
 	If  (inclui .Or. M->ZFX_FORNEC+M->ZFX_LOJA != ZFX->ZFX_FORNEC+ZFX->ZFX_LOJA) .And. ZFX->(DBSeek(xFilial("ZFX")+M->ZFX_FORNEC+M->ZFX_LOJA)) 
 		FWAlertInfo("Regra de para esse fornecedor já cadastrada nessa filial.","ACOM03406")
 		_lRet := .F.    
 		Break
 	EndIf
 	
 	If !(Empty(M->ZX_PRODUT) .And. Empty(M->ZX_CLIENT) .And. Empty(M->ZX_LOJC) )
 		If FWAlertYesNo("Para registro do tipo fornecedor os campos Produto e Cliente devem estar vazios, apagar campos e confirmar gravação?","ACOM03407")
 			M->ZX_PRODUT := ""
 			M->ZX_CLIENT := ""
 			M->ZX_LOJC := ""
 		Else
 			_lRet := .F.    
 			Break
 		EndIf
 	EndIf
EndIf

If M->ZFX_TIPO == 'C' 
 	If Empty(M->ZFX_CLIENT)
 		FWAlertWarning("Para regra tipo cliente o campo cliente é obrigatório!","ACOM03408")
 		_lRet := .F.
 		Break
 	EndIf
 	
 	ZFX->(DBSetOrder(4))
 	If (inclui .Or. M->ZFX_CLIENT+M->ZFX_LOJC != ZFX->ZFX_CLIENT+ZFX->ZFX_LOJC) .And. ZFX->(DBSeek(xFilial("ZFX")+M->ZFX_CLIENT+M->ZFX_LOJC)) 
 		FWAlertInfo("Regra de para esse cliente já cadastrada nessa filial.","ACOM03409")
 		_lRet := .F.    
 		Break
 	EndIf
 	
 	If !(Empty(M->ZX_PRODUT) .And. Empty(M->ZX_CLIENT) .And. Empty(M->ZX_LOJC) )
 		If FWAlertYesNo("Para registro do tipo cliente os campos Produto e Fornecedor devem estar vazios, apagar campos e confirmar gravação?","ACOM03410")
 			M->ZX_PRODUT := ""
 			M->ZX_FORNEC := ""
 			M->ZX_LOJA := ""
 		Else
 			_lRet := .F.    
 			Break
 		EndIf
 	EndIf
EndIf

End Sequence

Return _lRet

/*
===============================================================================================================================
Programa----------: ACOM034O
Autor-------------: Josué Danich Prestes
Data da Criacao---: 05/12/2016
Descrição---------: Gatilho do campo C6_CC
Parametros--------: Nenhum
Retorno-----------: _cCC - string com valor para o C6_CC
===============================================================================================================================
*/  
User Function ACOM034G

Local _cCC := Posicione('SB1',1,xFilial('SB1')+M->C6_PRODUTO, 'B1_CC') As Character//(só usa se não achar regra)
Local _cordem := SuperGetMV("IT_ORDCC",.F.,"C") As Character //Define ordem de prioridade de regra, C para cliente primeiro e P para produto primeiro
Local _lachou := .F. As Logical

//Atualiza com regra de produto 
ZFX->(DBSetOrder(1))

If ZFX->(DBSeek(xFilial("ZFX")+M->C6_PRODUTO))
	_cCC := ZFX->ZFX_CCUSTO
	_lachou := .F.
EndIf

//Atualiza com regra de cliente se For prioridade ou se não achou regra de produto
ZFX->(DBSetOrder(4))
If (_cordem == "C" .Or. !_lachou ) .And. ZFX->(DBSeek(xFilial("ZFX")+M->C5_CLIENTE+M->C5_LOJACLI))
	_cCC := ZFX->ZFX_CCUSTO
EndIf

Return _cCC
