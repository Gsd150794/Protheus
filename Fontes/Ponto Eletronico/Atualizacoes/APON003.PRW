/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |21/06/2019| Chamado 29608. Retirados acessos ao servidor ODA
Lucas Borges  |17/09/2019| Chamado 28346. Retirada chamada da função itputx1.
Lucas Borges  |27/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: APON003
Autor-------------: Josué Danich Prestes
Data da Criacao---: 18/05/2018
Descrição---------: Leitura AFD Telematica - Chamado 24911
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function APON003

Local oproc 	:= Nil As Object
Local _cPerg 	:= 'APON003' As Character
Local _alog 	:= {} As Array
Local _acab 	:= {"Filial","Relogio","Desc Relogio","Arquivo","Resultado"} As Array
Local _nI		:= 0 As Numeric

If !Pergunte(_cPerg)
	FWAlertInfo("Processo cancelado pelo usuário.","APON00301")
	Return
EndIf

If ";" $ MV_PAR01
	_afiliais := StrTokArr(MV_PAR01,";")
ElseIf Empty(MV_PAR01)
	FWAlertWarning("Obrigatório selecionar pelo menos uma filial.","APON00301")
	Return
Else
	_afiliais := {AllTrim(MV_PAR01)}
EndIf

For _nI := 1 To Len(_afiliais)
	FWMsgRun(,{|oproc| U_APON003I(oproc,MV_PAR02,MV_PAR03,.T.,_afiliais[_nI], @_alog),"Aguarde...","Iniciando processamento..."})
Next _nI

If Len(_alog) > 0
	U_ITListBox( 'Processamento concluído' , _acab , _alog , .T. )
Else
	FWAlertInfo("Não foram localizadas marcações para gerar arquivos","APON00302")
EndIf

Return

/*
===============================================================================================================================
Programa----------: APON003I
Autor-------------: Josué Danich Prestes
Data da Criacao---: 18/05/2018
Descrição---------: Importa registros do Conex/Controlid
Parametros--------: oproc - objeto da barra de processamento
					_dtini - data inicial
					_dtfim - data final
					_cfilial - filial de processamento
					_alog - Array de retorno de dados de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function APON003I(oproc As Object,_dtini As Date,_dtfim As Date,_lshow As Logical,_cfilial As Character,_alog As Array)

Local _ncon		:= 0 As Numeric
Local _oFile	:= Nil As Object
Local _cAlias	:= '' As Character
Default _lshow := .T.
Default _alog := {}

//Roda todos os relógios da filial
SP0->(DBSetOrder(1))
SP0->(DBGoTop())
SP0->(DBSeek(_cfilial))

While AllTrim(SP0->P0_FILIAL) == AllTrim(_cfilial) .And. SP0->(!Eof())
	If SP0->P0_I_TIPO != "R"
		SP0->(DBSkip())
		Loop
	EndIf

	If _lshow
		oproc:cCaption := ("Gravando arquivo AFD do relógio " + AllTrim(SP0->P0_FILIAL) + "/" + SP0->P0_RELOGIO + " - " + AllTrim(SP0->P0_DESC) + "...")
		ProcessMessages()
	EndIf

	If SP0->P0_I_CTRID == "T" 
		//Envia comando de leitura
		_oFile:= FWFileWriter():New(AllTrim(SP0->P0_ARQUIVO))

		If _oFile:Exists()
			If !_oFile:Erase()
				If _lshow
					FWAlertError("Falha ao atualizar o arquivo " + AllTrim(SP0->P0_ARQUIVO) + " do relógio " + AllTrim(SP0->P0_FILIAL) + "/" + SP0->P0_RELOGIO + " - " + AllTrim(SP0->P0_DESC)+". Verifique bloqueios do arquivo","APON00303")
				EndIf
				
				aAdd(_alog,{SP0->P0_FILIAL,SP0->P0_RELOGIO,AllTrim(SP0->P0_DESC),AllTrim(SP0->P0_ARQUIVO),"Erro de acesso ao arquivo"})		 			
				SP0->(DBSkip())
				Loop
			EndIf
		EndIf
			
		
			
		If !_oFile:Create()
			If _lshow
				FWAlertError("Falha ao atualizar o arquivo " + AllTrim(SP0->P0_ARQUIVO) + " do relógio " + ;
					 			AllTrim(SP0->P0_FILIAL) + "/" + SP0->P0_RELOGIO + " - " + AllTrim(SP0->P0_DESC)+". Verifique bloqueios do arquivo","APON00304")
			EndIf
			
			aAdd(_alog,{SP0->P0_FILIAL,SP0->P0_RELOGIO,AllTrim(SP0->P0_DESC),AllTrim(SP0->P0_ARQUIVO),"Erro de acesso ao arquivo"})		 			
			SP0->(DBSkip())
			Loop
		EndIf
	
		_ncon := 0
		_nposori := SM0->(Recno())
		
		SM0->(DBGoTop())
		
		While SM0->(!Eof()) 
			If AllTrim(SM0->M0_CODFIL) == AllTrim(_cfilial)
				_ccnpj := SM0->M0_CGC
				_crazao := SM0->M0_NOMECOM
			EndIf
			SM0->(DBSkip())
		EndDo
		
		SM0->(DBGoTo(_nposori))
		
		_ddtini := SubStr(DToS(MV_PAR02),7,2) + SubStr(DToS(MV_PAR02),5,2) + SubStr(DToS(MV_PAR02),1,4) 
		_ddtFIM := SubStr(DToS(MV_PAR03),7,2) + SubStr(DToS(MV_PAR03),5,2) + SubStr(DToS(MV_PAR03),1,4)
		_ddtGER := SubStr(DToS(date()),7,2) + SubStr(DToS(date()),5,2) + SubStr(DToS(date()),1,4)
		_chger := SubStr(time(),1,2) + SubStr(time(),4,2) 
		_cpri := "00000000011" + _ccnpj + "000000000000" + PadR(_crazao, 150) +  AllTrim(SP0->P0_REP) + _ddtini + _ddtFIM + _ddtGER + _chger
		
		_oFile:Write(_cpri + CRLF)
		_cAlias := GetNextAlias()
		BeginSql alias _cAlias
			SELECT * FROM SURICATO.TBAFD 
			WHERE TIPO_REG = 3 
			AND NROCODINREP = %exp:AllTrim(SP0->P0_REP)%
			AND DATAMARC >= TO_DATE(%exp:MV_PAR02%,'YYYYMMDD') 
			AND DATAMARC <= TO_DATE(%exp:MV_PAR03%,'YYYYMMDD')
			ORDER BY INFORM
		EndSql
		
		While (_cAlias)->(!Eof())
			_oFile:Write(AllTrim((_cAlias)->INFORM) + CRLF)
			(_cAlias)->(DBSkip())
			_ncon++
		EndDo
		
		_cult := "999999999000000000" + StrZero(_ncon,9) + "0000000000000000009" + CRLF
		
		_oFile:Write(_cult + CRLF)
		
		_oFile:Close()
		_oFile:= Nil
		(_cAlias)->(DBCloseArea())
		
		aAdd(_alog,{SP0->P0_FILIAL,SP0->P0_RELOGIO,AllTrim(SP0->P0_DESC),AllTrim(SP0->P0_ARQUIVO),"Arquivo gravado com " + StrZero(_ncon,6) + " apontamentos."})
	EndIf
	SP0->(DBSkip())
EndDo

Return
