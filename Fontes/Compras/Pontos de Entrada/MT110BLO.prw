/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Jerry Santiago|26/08/2015| Nova tratativa da validação do Aprovador da SC através do ID o Usuário logado
              |          | Retirado a busca do usuário Aprovador pela função U_UCFG001(1)
Darcio Ribeiro|14/10/2015| Chamado 12293. Incluído tratamento, onde o sistema validará se a SC está no status Aprovado ou Rejeitado,
              |          | caso esteja, o sistema não permitirá nenhum tipo de alteração.
Lucas Borges  |03/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
===============================================================================================================================
*/

#Include "TOTVS.ch"
            
/*
===============================================================================================================================
Programa----------: MT110BLO
Autor-------------: Tiago Correa Castro
Data da Criacao---: 31/07/2008
Descrição---------: Ponto de Entrada para validacao da Aprovacao da Solicitacao de Compra    
					Localização: Function A110APROV - Função da Solicitação de Compras responsavel pela aprovação das SCs.
					Em que Ponto: Após a montagem da dialog de aprovação da Solicitação de compras. É acionado quando o usuario
					clica nos botões Solicitação Aprovada, Rejeita ou Bloqueada, deve ser utilizado para continuar estas ações 
					retorno .T.' ou interromper  'retorno .F.' , após clicar os botões.
Parametros--------: ParamIXB -> A -> ParamIXB[1] = 1 = Aprovar; 2 = Rejeitar; 3 = Bloquear
Retorno-----------: lContinua -> L -> .T. = Continua o processo / .F. = Interrompe o processo
===============================================================================================================================
*/
User Function MT110BLO

Local	_aArea	:=	FWGetArea()
Local 	_lRet	:=	.T. 
Local  _cUsu	:= __cUserId
Local aMensagem	:= {}
Local aProbl	:= {}
Local aSoluc	:= {}
Local lContinua	:= .T.
                   
If SC1->C1_APROV <> 'B'
	lContinua	:= .F.
	_lRet		:= .F.
	
	aProbl := {}
	aAdd(aProbl, "Esta solicitação não pode ser alterada.")
	
	aSoluc := {}
	aAdd(aSoluc, "Solicitações com status Rejeitada ou Aprovada, não podem ser alteradas.")
	
	aMensagem := {"Ação Não Permitida", aProbl, aSoluc}

	U_ITMsHTML(aMensagem)
EndIf

If lContinua
	//================================================================================
	//| Verifica se o usuário Logado é o Aprovador da SC posicionada                 |
	//================================================================================ 
	If  SC1->C1_I_CODAP <> _cUsu 
		DBSelectArea("ZZ7")
		ZZ7->(DBSetOrder(1))
		If ZZ7->(DBSeek(xFilial("ZZ7") + SC1->C1_I_CODAP))
			If _cUsu == ZZ7->ZZ7_APRSUB
				If DDATABASE < ZZ7->ZZ7_DTSUBI .Or. DDATABASE > ZZ7->ZZ7_DTSUBF
					_lRet := .F.
	
					aProbl := {}
					aAdd(aProbl, "Usuário logado está fora da vigência no cadastro de Aprovadores.")
	
					aSoluc := {}
					aAdd(aSoluc, "Favor verificar o cadastro de Aprovadores.")
	
					aMensagem := {"Aprovador Inválido", aProbl, aSoluc}
	
					U_ITMsHTML(aMensagem)
				EndIf
			Else
				_lRet := .F.
	
				aProbl := {}
				aAdd(aProbl, "Usuário logado não possui permissão para aprovar esta solicitação.")
	
				aSoluc := {}
				aAdd(aSoluc, "Favor verificar o cadastro de Aprovadores.")
	
				aMensagem := {"Aprovador Inválido", aProbl, aSoluc}
	
				U_ITMsHTML(aMensagem)
			EndIf
		Else
			_lRet := .F. 
	
			aProbl := {}
			aAdd(aProbl, "Usuário logado não existe no cadastro de Aprovadores.")
	
			aSoluc := {}
			aAdd(aSoluc, "Favor verificar o cadastro de Aprovadores.")
	
			aMensagem := {"Aprovador Inválido", aProbl, aSoluc}
	
			U_ITMsHTML(aMensagem)
		EndIf
	EndIf
EndIf

FWRestArea(_aArea)

Return (_lRet)
