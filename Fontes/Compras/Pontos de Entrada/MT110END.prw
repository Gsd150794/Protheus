/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Darcio Ribeiro|21/09/2015| Chamado 10999. Foi implementada a gravação do Aprovador da Solicitação de Compras.
Darcio Ribeiro|24/11/2015| Chamado 12838. Foi inserido o tratamento do novo campo de Observação no cabeçalho da SC.
Lucas Borges  |03/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT110END
Autor-------------: Tiago Correa Castro
Data da Criacao---: 31/07/2008
Descrição---------: Ponto de Entrada para gravar dados da Aprovacao da Solicitacao de Compras
					Localização: Function A110APROV - Função da Solicitação de Compras responsavel pela aprovação das SCs
					Em que Ponto: Após o acionamento dos botões Solicitação Aprovada, Rejeita ou Bloqueada, deve ser utilizado 
					para validações do usuario após a execução das ações dos botões.
Parametros--------: ParamIXB[1] -> C -> Numero da Solicitação de compras
					ParamIXB[2] -> N -> 1 = Aprovar; 2 = Rejeitar; 3 = Bloquear
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT110END

Local _aArea	:= FWGetArea()
Local nOpca		:= ParamIXB[2]       // 1 = Aprovar; 2 = Rejeitar; 3 = Bloquear
Local _cUsu		:= __cUserId

If nOpca == 1
	RecLock("SC1",.F.)
		SC1->C1_APROV	:= "L"
		SC1->C1_I_DTAPR	:= Date()
		SC1->C1_I_HRAPR	:= Time()
		SC1->C1_I_APROV	:= _cUsu
		SC1->C1_I_OBSAP	:= "SC Aprovada via acesso ao Protheus"
	MSUnLock()
ElseIf nOpca == 2
	RecLock("SC1",.F.)
		SC1->C1_APROV	:= "R"
		SC1->C1_I_DTAPR	:= Date()
		SC1->C1_I_HRAPR	:= Time()
		SC1->C1_I_APROV	:= _cUsu
		SC1->C1_I_OBSAP	:= "SC Rejeitada via acesso ao Protheus"
	MSUnLock()
ElseIf nOpca == 3
	RecLock("SC1",.F.)
		SC1->C1_APROV	:= "B"
		SC1->C1_I_DTAPR	:= SToD("")
		SC1->C1_I_HRAPR	:= ""
		SC1->C1_I_OBSAP	:= "SC Bloqueada via acesso ao Protheus"
	MSUnLock()
EndIf

FWRestArea(_aArea)

Return
