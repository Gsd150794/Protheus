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
Programa----------: F050MCP
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 04/07/2019
Descrição---------: O ponto de entrada F050MCP permite incluir novos campos na opção Alterar da rotina FINA050. Será executado 
					ao exibir a tela após clicar no botão Alterar da rotina FINA050. Desta forma, os campos que forem incluídos
					por este Ponto de Entrada também poderão ser editados na opção Alterar.
					Nota 1: O campo E2_VALOR possui em sua validação a função FA050Nat2() que impede a alteração do mesmo quando
					este é do tipo TX. Devido a isso, o ponto de entrada não funcionará para este campo, nesta situação.
					Nota 2: Para o módulo de Transporte (SIGATMS) e o módulo Gestão de Frete Embarcador (TOTVSGFE - SIGAGFE), 
					este ponto de entrada não é válido.
					Os campos permitidos para alteração de títulos gerados pelo SIGATMS são: E2_VENCTO e E2_VENCREA
					Os campos permitidos para alteração de títulos gerados pelo TOTVSGFE são: E2_VENCTO, E2_VENCREA, E2_HIST e 
					E2_CODBAR. Chamado 29866
Parametros--------: aCpos -> A -> Array contendo os campos que serão permitidos alterar
Retorno-----------: aCpos -> A -> Array contendo os campos que serão permitidos alterar -> Obrigatório
===============================================================================================================================
*/
User Function F050MCP

Local _aCpos:= ParamIXB
Local _nPos	:= 0
//Registros originados do Gestão do Leite não podem ter o valor alterado.
If AllTrim(SE2->E2_ORIGEM) $ "AGLT009/AGLT010/AGLT011/AGLT012/AGLT016/MGLT009/MGLT011/MGLT027" .And.(_nPos := aScan(_aCpos, "E2_VALOR")) <> 0
	ADEL(_aCpos,_nPos)
	ASIZE(_aCpos,Len(_aCpos)-1)
EndIf

Return _aCpos
