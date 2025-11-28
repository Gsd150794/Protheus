/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |07/05/2018| Chamado 24726. Padronização dos cabeçalhos dos fontes e funções do módulo financeiro.
Julio Paz     |17/11/2022| Chamado 41853. Validar campo data de prorrogação e não permitir data inferior a data atual.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: AFIN003
Autor-------------: Frederico O. C. Jr
Data da Criacao---: 28/08/2008  
Descrição---------: Validação dos campos E1_PREFICO e E2_PREFIXO para verificar se estes tem amarração na ZAB.
Parametros--------: _nOpc = 1 - Pagar  /	2- Receber	
                    _cPref1	= Prefixo			                                        						
Retorno-----------: lRet = .T. = Se possui amarracao na ZAB 
                         = .F. = Se não possuir amarração na ZBA
===============================================================================================================================
*/
User Function AFIN003(_nOpc, _cPref)

Local aArea 	:= FWGetArea()
Local lRet		:= 	.F.

DBSelectArea("ZAB")
ZAB->(DBSetOrder(1))
If ( DBSeek(xFilial("ZAB") + _cPref ) )
	If ( ZAB->ZAB_TIPO == "3" )
		lRet := .T.
	ElseIf ( _nOpc == 1 )
		ZAB->(DBSetOrder(2))
		If ( ZAB->(DBSeek(xFilial("ZAB") + "1" + _cPref )) )
			lRet := .T.
		EndIf
	Else
		ZAB->(DBSetOrder(2))
		If ( ZAB->(DBSeek(xFilial("ZAB") + "2" + _cPref )) )
			lRet := .T.
		EndIf
	EndIf
Else
	lRet :=	.F. 
	xMagHelpFis("Consulta Prefixo",;
				"Nao existe esse Prefixo na tabela de Prefixos",;
				"Cadastrar primeiramente o Prefixo na tabela de Prefixos")
EndIf

FWRestArea(aArea)

Return lRet 

/*
===============================================================================================================================
Programa----------: AFIN003V
Autor-------------: Julio de Paula Paz
Data da Criacao---: 16/11/2022
Descrição---------: Validação a digitação dos campos informados na variável _cCampo, na inclusão/alteração de titulos de contas 
                    a receber.
Parametros--------: _cCampo = Campo que chamou a validação.	                                        						
Retorno-----------: lRet = .T. = Validação Ok. 
                         = .F. = Inconsistencia na validação.
===============================================================================================================================
*/
User Function AFIN003V(_cCampo)

Local _lRet := .T.

If _cCampo == "E1_I_DTPRO"
	If ! Empty(M->E1_I_DTPRO) .And. DToS(M->E1_I_DTPRO) < DToS(Date()) 
		_lRet := .F.
		U_ITMsg( 'A data de prorrogação do título não pode ser menor que a data atual do sistema.' , 'Atenção!' , , 1)
	EndIf 
EndIf

Return _lRet 
