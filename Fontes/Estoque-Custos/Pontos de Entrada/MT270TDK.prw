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
Programa----------: MT270TDK
Autor-------------: André Lisboa
Data da Criacao---: 22/10/2014
Descricao---------: Ponto de Entrada que valida exclusão registro de inventário. Chamado apos confirmação de exclusão do registro 
                  de inventário, irá verificar se para o item já foi rodado acerto de inventário, caso esteja como Sim, não 
                  permitira a exclusão
Caminho-----------: SIGAEST -> ATUALIZACOES -> MOVIMENTAOCES -> INTERNAS -> RASTREABILIDADE -> BLOQUEIO
Parametros--------: Nenhum
Retorno-----------: .T. = Permite confirmar exclusão - .F. = Nao Permite confirmar exclusão
===============================================================================================================================
*/ 
User Function MT270TDK

Local lRet :=.T.
Local cProces := SB7->B7_I_ACERT //campo que registra se foi rodado acerto de inventário

If cProces == "1"
	lRet := .F.
	Alert("Inventário já executado! Não poderá ser excluído.")
EndIf

Return lRet
