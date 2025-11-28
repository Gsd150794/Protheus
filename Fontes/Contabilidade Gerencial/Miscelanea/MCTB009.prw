/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |26/06/2017| Chamado 20598. Corrigida mensagem de aviso.
Lucas Borges  |03/09/2019| Chamado 28346. Revisão do fonte.
===============================================================================================================================
*/

#Include "TOTVS.ch" 

/*
===============================================================================================================================
Programa----------: MCTB009
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 22/03/2017
Descrição---------: Rotina para remover caracteres inválidos no histórico das contabiliações evitando erros nos arquivos magnéticos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MCTB009

Local _cPerg		:= "MCTB009"
Local _oSelf		:= nil

//============================================
//Cria interface principal
//============================================
tNewProcess():New(	_cPerg								,; // Função inicial
					"Gera arquivo Banco do Brasil"		,; // Descrição da Rotina
					{|_oSelf| MCTB09P(_oSelf) }			,; // Função do processamento
					"Rotina para remover caracteres inválidos no histórico das contabiliações evitando erros " +;
					" nos arquivos magnéticos" 			,; // Descrição da Funcionalidade
					_cPerg								,; // Configuração dos Parâmetros
					{}									,; // Opções adicionais para o painel lateral
					.F.									,; // Define criação do Painel auxiliar
					0									,; // Tamanho do Painel Auxiliar
					''									,; // Descrição do Painel Auxiliar
					.T.									,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
					.T.									 ) // Opção para criação de apenas uma régua de processamento

Return

/*
===============================================================================================================================
Programa----------: MGPE06P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 27/08/2019
Descrição---------: Realiza o processamento da rotina.
Parametros--------: _oSelf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MCTB09P(_oSelf)

Local 	_cQuery:= " "

_oSelf:SaveLog("Iniciando a rotina. Parâmetros: "+DToC(MV_PAR01)+"-"+DToC(MV_PAR02))

_cQuery := "UPDATE "
_cQuery += RETSQLNAME("CT2")
_cQuery += " SET	CT2_HIST = REGEXP_REPLACE (CT2_HIST , '(/|'||CHR(39)||'|&|%|'||CHR(34)||'|§||'||CHR(9)||')',' ')"
_cQuery += " WHERE "
_cQuery += " D_E_L_E_T_ = ' '" 
_cQuery += " AND CT2_DATA BETWEEN '"+ DToS(MV_PAR01) +"' AND '"+ DToS(MV_PAR02) +"'"
_cQuery += " AND REGEXP_LIKE (CT2_HIST , '(/|'||CHR(39)||'|&|%|'||CHR(34)||'|§||'||CHR(9)||')','i')"
	
If TCSqlExec( _cQuery ) < 0
	MsgStop("Processamento com erro. " + TCSQLError(),"MCTB00901")
Else
	MsgInfo("Processamento concluído com sucesso!","MCTB00902")
EndIf

Return
