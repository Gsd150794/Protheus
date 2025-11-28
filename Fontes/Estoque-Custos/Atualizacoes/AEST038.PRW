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
Programa----------: AEST038
Autor-------------: Lucas Crevilari
Data da Criacao---: 22/08/2014
Descrição---------: Gatilho para verificar se o produto na inclusão da OP tem estrutura cadastrada. Chamado 7197
Parametros--------:
Retorno-----------:
===============================================================================================================================
*/               
User Function AEST038( cProduto )
      
Local aArea		:= FWGetArea()
Local lOk 		:= .T.

Default cProduto := ''

cProduto := Posicione("SG1",1,xFilial("SG1")+cProduto,"G1_COD")       

If Empty(AllTrim(cProduto))
	xMagHelpFis("Estrutura não cadastrada","Não foi encontrado estrutura cadastrada para este produto.",;
				"Cadastre a estrutura deste produto. Se necessário, entre em contato com Depto. TI/ERP.")
	lOk := .F.
EndIf

FWRestArea(aArea)
Return(lOk)
