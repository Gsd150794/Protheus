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
Programa----------: MFIS006
Autor-------------: Lucas Borges Ferrreira
Data da Criacao---: 03/08/2020
Descrição---------: Permite ajustar a sequência de numeração das Notas Formulário Próprio. Chamado 33714
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIS006

Local _oSelf	:= nil
Local _aButtons	:={}

ProcLogIni( _aButtons )
//============================================
//Cria interface principal
//============================================
tNewProcess():New(	"MFIS006"							,; // Função inicial
					"Atualiza Númeração da NF-e"		,; // Descrição da Rotina
					{|_oSelf| MFIS06P(_oSelf) }   		,; // Função do processamento
					"Rotina para permitir alterar o número da próxima Nota Forumlário Próprio",; // Descrição da Funcionalidade
														,; // Configuração dos Parâmetros
					{}									,; // Opções adicionais para o painel lateral
					.F.									,; // Define criação do Painel auxiliar
					0									,; // Tamanho do Painel Auxiliar
					''									,; // Descrição do Painel Auxiliar
					.F.									,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
                    .F.                                 ) // Se .T. cria apenas uma regua de processamento.

ProcLogAtu("FIM")

Return

/*
===============================================================================================================================
Programa----------: MFIS06P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 03/08/2020
Descrição---------: Monta rotina para alteração da numeração das notas
Parametros--------: _oSelf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIS06P(_oSelf)

Local _cSerie := ""
If !Sx5NumNota(@_cSerie)
    ProcLogAtu("MENSAGEM","ERRO ao alterar numeracao de nota serie "+_cSerie,"","MFIS006")
Else
	ProcLogAtu("MENSAGEM","Alterada a numeracao de nota serie "+_cSerie,"","MFIS006")
EndIf

Return
