/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Darcio Spörl  |24/06/2016| Chamado 15934. Foi criada uma validação de usuário, caso este não tenho acesso através do configurador
			  |			 | Italac, a rotina não será executada, e se tiver acesso o usuário poderá efetivar o fechamento do 
			  |          | fluxo de caixa, foi alterado o parâmetro de data, pois agora o usuário deverá informar um período 
			  |			 | MM/AAAA para o fechamento do fluxo, pois o sistema fará automaticamente o controle das datas de início
			  |			 | e fim do período, e também foi incluída uma validação, que verifica se para o período informado já
			  |			 | não teve fechamento.
Lucas Borges  |10/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Lucas Borges  |04/11/2019| Chamado 31077. Corrigido nome da tabela.
===============================================================================================================================
*/

#Include "Totvs.Ch"

/*
===============================================================================================================================
Programa----------: MFIN012
Autor-------------: Julio de Paula Paz
Data da Criacao---: 31/05/2016
Descrição---------: Fechamento de Fluxo de Caixa - Chamado 15605
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN012()         

Local _bProcess    
Local _lRet := .T.

DBSelectArea("ZZL")
ZZL->(DBSetOrder(3))
If ZZL->(DBSeek(xFilial("ZZL") + __cUserId))
	If ZZL->ZZL_FCHFLX == "S"

		Begin Sequence    
			//================================================================================
			// Cria tela principal com o dicinário de perguntas
			//================================================================================   
			_bProcess    := {|_oSelf| MFIN012P(_oSelf) }
			TNewProcess():New( "MFIN012", "Fechamento de Fluxo de Caixa", _bProcess, "Rotina de fechamento de fluxo de caixa...","MFIN012",,,,,,.T.)
		   
		End Sequence
	Else
		MsgStop("Usuário sem permissão para utilizar a rotina de Fechamento de Fluxo, favor contatar a equipe de TI.","MFIN012001")
	EndIf
Else
	MsgStop("Usuário sem permissão para utilizar a rotina de Fechamento de Fluxo, favor contatar a equipe de TI.","MFIN012002")
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MFIN012V()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 31/05/2016
Descrição---------: Validação da digitação dos dados da tela de parâmetros iniciais.
Parametros--------: _cChamada = campo ou rotina que chamou a validação.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN012V(_cChamada)                                                            

Local _lRet		:= .T.
Local _cMeses	:= "01|02|03|04|05|06|07|08|09|10|11|12"

Begin Sequence
	If _cChamada == "MV_PAR03" .Or. _cChamada == "PROCESSAMENTO"
		If Len(MV_PAR03) < 7 .Or. !("/" $ MV_PAR03)
			MsgInfo("Favor digitar o período corretamente, utilizar o formato MM/AAAA","MFIN012003")
			_lRet := .F.
		ElseIf !(SubStr(MV_PAR03,1,2) $ _cMeses)
			MsgInfo("Favor digitar um mês válido.","MFIN012004")
			_lRet := .F.
		EndIf
	EndIf

End Sequence

Return _lRet     

/*
===============================================================================================================================
Programa----------: MFIN012P()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 31/05/2016
Descrição---------: Rotina principal do fechamento do fluxo de caixa.
Parametros--------: _oself = objeto da tela.
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN012P(_oself)                                                            

Local _cFiltro	:= "%"
Local _cAlias	:= ""
Local _nTotreg	:= 0
Local _dDtAtu	:= "01/" + MV_PAR03
Local _dDtIni	:= FirstDate(CtoD(_dDtAtu))
Local _dDtFim	:= LastDay(CtoD(_dDtAtu))

Begin Sequence
	If !U_MFIN012V("PROCESSAMENTO")
		MsgStop("Para que seja possível realizar o fechamento do fluxo de caixa, preencha corretamente os parâmetros de filtro do relatório no botão 'Perguntas'.","MFIN012005")
		Break      
	EndIf   

	If !U_MFIN012D(DToS(_dDtIni), DToS(_dDtFim))
		MsgStop("Não foi possível realizar o fechamento do fluxo de caixa, pois o período selecionado já foi fechado.","MFIN012006")
		Break
	EndIf

	If ! Empty(MV_PAR01)
		_cFiltro += " AND E1_FILIAL BETWEEN '"+MV_PAR01+"' AND  '"+MV_PAR02+"' "
	ElseIf Empty(MV_PAR01) .And. !Empty(MV_PAR02)
		_cFiltro += " AND E1_FILIAL <= '"+MV_PAR02+"' "
	EndIf
	_cFiltro += "%"
	_cAlias := GetNextAlias()
	
	BeginSql alias _cAlias
		SELECT SE1.R_E_C_N_O_ NRECNO
		  FROM %Table:SE1% SE1
		 WHERE SE1.D_E_L_E_T_ = ' '
		   %exp:_cFiltro%
		   AND E1_VENCREA BETWEEN %exp:_dDtIni% AND %exp:_dDtFim%
	EndSql

	COUNT TO _nTotreg
	(_cAlias)->( DBGoTop() )
   
	If _nTotreg == 0
		MsgInfo("Não foram encontrados dados para o fechamento de fluxo de caixa.","MFIN012007")
		(_cAlias)->(DBCloseArea())
		Break
	EndIf   
   
	_oself:SetRegua1( _nTotreg ) // Determina o tamanho da regua de processamento.   
   
	While ! (_cAlias)->(Eof())    
		SE1->(DBGoTo((_cAlias)->NRECNO))
		_oself:IncRegua1( "PREFIXO - TITULO: " + AllTrim(SE1->E1_PREFIXO) + " - " +  AllTrim(SE1->E1_NUM) )
		SE1->(RecLock("SE1",.F.))
		SE1->E1_I_VCFLU := SE1->E1_VENCREA
		SE1->E1_I_FCFLU := Date()
		SE1->(MSUnLock())
                             
		(_cAlias)->(DBSkip())
	EndDo

	_oself:SaveLog( "REALIZADO FECHAMENTO DE FLUXO DE CAIXA." )

	MsgInfo("Processamento finalizado com sucesso!","MFIN012008")

End Sequence

(_cAlias)->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa----------: MFIN012D
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 24/06/2016
Descrição---------: Rotina responsável por validar se já houve fechamento no período solicitado
Parametros--------: _dDtIni - Data início do período de fechamento
------------------: _dDtFim - Data final do período de fechamento
Retorno-----------: _lRet - .T. Processo continuará, pois não existe fechamento no período / .F. Processo interrompido, pois
------------------:			existe fechamento no período
===============================================================================================================================
*/
User Function MFIN012D(_dDtIni, _dDtFim)

Local _lRet := .T.
Local _cAlias := GetNextAlias()

BeginSql alias _cAlias
	SELECT COUNT(1) QTD
	  FROM %Table:SE1%
	 WHERE E1_VENCREA BETWEEN %exp:_dDtIni% AND %exp:_dDtFim%
	   AND (E1_I_FCFLU <> ' ' AND E1_I_FCFLU > %exp:_dDtIni%)
	   AND D_E_L_E_T_ = ' '
EndSql

If (_cAlias)->QTD > 0
	_lRet := .F.
EndIf

(_cAlias)->(DBCloseArea())

Return(_lRet)
