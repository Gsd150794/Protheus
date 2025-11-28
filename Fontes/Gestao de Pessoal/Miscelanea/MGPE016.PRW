/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |04/10/2022| Chamado 41279. Ajuste para funcionamento via Schedule.
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
Igor Melgaço  |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TBICONN.CH"   

Static _lScheduler:= FWGetRunSchedule() .Or. SELECT("SX3") <= 0

/*
===============================================================================================================================
Programa----------: MGPE016
Autor-------------: Josué Danich Prestes
Data da Criacao---: 21/12/2016
Descrição---------: Rotina de leitura de equipamentos de ponto - Chamado 18026
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE016()

Private _lcontinua:= .T.
   
If _lScheduler

	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE016"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01601"/*cMsgId*/, "MGPE01601 - Inicio Workflow de leitura de equipamentos de ponto."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

	PREPARE ENVIRONMENT EMPRESA '01' FILIAL '01';
	TABLES "SX2, SX5, SP0 ";
	MODULO 'GPE'

	MV_PAR01 := ""
	MV_PAR02 := dDatabase - 31
	MV_PAR03 := dDatabase
	MV_PAR04 := "0"
	MV_PAR05 := 1

	U_MGPE016P()

	RESET ENVIRONMENT
	
Else
	While _lcontinua

		_lcontinua := .F.
		//_bProcess    := {|_oSelf| U_MGPE016P(_oSelf)  }
		_bProcess    := {|| _lcontinua:=.T.  }

		tNewProcess():New( "MGPE016", "Lê equipamentos ponto", _bProcess, "Rotina de leitura de equipamentos de ponto","MGPE016")
		
		If _lcontinua
			FWMsgRun(,{|_oself| U_MGPE016P(_oself)},"Aguarde...","Processando relatório...")
		EndIf
		
	EndDo
EndIf
Return

/*
===============================================================================================================================
Programa----------: MGPE016P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 21/12/2016
Descrição---------: Lê equipamentos de ponto
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE016P(_oSelf)

Local _nconta	:=0 
Local _nproce	:=0
Local _nconta2	:= 0
Local _cAlias	:= GetNextAlias()
Local _nHandle	:= 0
Local _cDirTemp	:= ""

cQuery := " SELECT count(*) TOT  from " 
cQuery += retsqlname("SP0") + " SP0 WHERE SP0.D_E_L_E_T_ = ' '  " 

If !_lScheduler .And. !Empty(AllTrim(MV_PAR01))
	cQuery +=  " and SP0.P0_FILIAL = '" + cfilant + "'"
EndIf

cQuery += " AND (SP0.P0_I_CTRID ='W' OR SP0.P0_I_CTRID ='A') " 

If !Empty(AllTrim(MV_PAR01))
	cQuery += " AND SP0.P0_RELOGIO IN " + FormatIn( MV_PAR01 , ";" )
EndIf

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

If !_lScheduler
	_oself:cCaption := "Lendo equipamentos"
	ProcessMessages()
Else
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE016"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01602"/*cMsgId*/, "MGPE01602 - Lendo equipamentos"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf


DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , _cAlias , .T. , .F. )
	
_nconta := (_cAlias)->TOT

cQuery := " SELECT P0_RELOGIO,P0_FILIAL,P0_I_IP, P0_I_CTRID, P0_I_TIPO, P0_ARQUIVO   from " 
cQuery += retsqlname("SP0") + " SP0 WHERE SP0.D_E_L_E_T_ = ' '  "

If !_lScheduler .And. !Empty(AllTrim(MV_PAR01))
	cQuery +=  " and SP0.P0_FILIAL = '" + cfilant + "'"
EndIf

cQuery += " AND (SP0.P0_I_CTRID ='W' OR SP0.P0_I_CTRID ='A') " 

If !Empty(AllTrim(MV_PAR01)) 
	cQuery += " AND SP0.P0_RELOGIO IN " + FormatIn( MV_PAR01 , ";" )
EndIf
 
If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , _cAlias , .T. , .F. )

If (_cAlias)->(Eof())

	If !_lScheduler
		U_ITMsg("Não foram encontrados relógios com os parâmetros informados!","Atenção",,1)
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE016"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01603"/*cMsgId*/, "MGPE01603 - Não foram encontrados relógios com os parâmetros informados!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
	
	Return
	
EndIf

While .not. (_cAlias)->(Eof())
	_nproce++

	If !_lScheduler
		_oself:cCaption := "Lendo equipamento " + StrZero(_nproce,3) + " de " + StrZero(_nconta,3)
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE016"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01604"/*cMsgId*/, "MGPE01604 - Lendo equipamento " + StrZero(_nproce,3) + " de " + StrZero(_nconta,3)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
	
	If Val(MV_PAR04) == 0 
		NNSU := 1
	Else
		NNSU := Val(MV_PAR04)
	EndIf
	
	ZG6->(DBGoTop())
	
	If ZG6->(DBSeek((_cAlias)->P0_FILIAL+(_cAlias)->P0_RELOGIO))
		If ZG6->ZG6_DATA <= MV_PAR02
			NNSU := ZG6->ZG6_NSRI
			ZG6->(DBSkip())
			
			While (_cAlias)->P0_FILIAL == ZG6->ZG6_FILIAL .And. (_cAlias)->P0_RELOGIO == ZG6->ZG6_RELOGI .And. ZG6->ZG6_DATA < MV_PAR02
				NNSU := ZG6->ZG6_NSRI
				ZG6->(DBSkip())
			EndDo
		EndIf
	EndIf
	_cDirTemp := GetTempPath()
	_narqle := ferase(_cDirTemp+"temp.txt")
		
	If _narqle == -1 .And. file(_cDirTemp+"temp.txt")
		If !_lScheduler
			U_ITMsg("Falha ao preparar o arquivo AFD","Erro",,1)
		Else
			FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "MGPE016"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01605"/*cMsgId*/, "MGPE01605 - Falha ao preparar o arquivo AFD"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
		Return
	EndIf 

	//Tipo de processamento, usar o seguro para computadores que travarem com waitrun
	If MV_PAR05 = 2
		shellexecute("Open", "C:\Windows\System32\cmd.exe"," /c "+_cDirTemp+"LE.BAT " +  AllTrim((_cAlias)->P0_I_IP)+ " " + AllTrim(Str(nnsu))  + _cDirTemp + "temp.txt",_cDirTemp,1)
		If !_lScheduler
			While !(U_ITMsg("O processo de leitura terminou?","Continua?",,3,2,2))
			EndDo
		EndIf
	Else
		waitrun(_cDirTemp+"le.bat " +  AllTrim((_cAlias)->P0_I_IP)  + " " + AllTrim(Str(nnsu))  + _cDirTemp + "temp.txt", 3 )
	EndIf
	
	//Copia arquivo para o servidor para usar
	
	_ctemp := "\spool\" + "temp.txt"
	_narqle := ferase(_ctemp)
		
	If _narqle == -1 .And. file(_ctemp)
		If !_lScheduler
			U_ITMsg("Falha ao copiar o arquivo AFD","Erro",,1)
		Else
			FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "MGPE016"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01606"/*cMsgId*/, "MGPE01606 - Falha ao copiar o arquivo AFD"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
		Return
	EndIf 
	
	_narqle := CpyT2S(_cDirTemp + "temp.txt","\spool")
	
	If !(_narqle)
		If !_lScheduler
			U_ITMsg("Falha ao copiar o arquivo AFD","Erro",,1)
		Else
			FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "MGPE016"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01607"/*cMsgId*/, "MGPE01607 - Falha ao copiar o arquivo AFD"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
		Return
	EndIf 
	
	_narqle := FT_FUSE(_ctemp)
		
	If _narqle == -1
		If !_lScheduler
			U_ITMsg("Falha ao copiar o arquivo AFD","Erro",,1)
		Else
			FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "MGPE016"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01608"/*cMsgId*/, "MGPE01608 - Falha ao copiar o arquivo AFD"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
		Return
	EndIf 

	_nconta2 := FT_FLastRec()

	If !_lScheduler
		_oself:cCaption := "Lendo arquivo resposta"
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE016"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01609"/*cMsgId*/, "MGPE01609 - Lendo arquivo resposta"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
		
	//Detecta layout de client
	FT_FGOTOP() //POSICIONA NO TOPO DO ARQUIVO
	_clinha := FT_FREADLN()

	_anovo := {}
	aAdd(_anovo,_clinha + chr(13) + chr(10))	
	FT_FSKIP()
	_nconti := 0
	_nposi := 0
	_dult := SToD("20010101")

	While .not. FT_FEOF()
		_clinha := FT_FREADLN()
		If SToD(SubStr(_clinha,15,4)+SubStr(_clinha,13,2)+SubStr(_clinha,11,2)) > _dult
			_dult := SToD(SubStr(_clinha,15,4)+SubStr(_clinha,13,2)+SubStr(_clinha,11,2))
			//Atualiza índice de nsr
			If ZG6->(DBSeek((_cAlias)->P0_FILIAL+(_cAlias)->P0_RELOGIO+DToS(_dult)))
				RecLock("ZG6",.F.)
				ZG6->ZG6_NSRI := Val(SubStr(_clinha,1,9))
			Else
				RecLock("ZG6",.T.)
				ZG6->ZG6_FILIAL := (_cAlias)->P0_FILIAL
				ZG6->ZG6_RELOGI := (_cAlias)->P0_RELOGIO
				ZG6->ZG6_DATA := _dult
				ZG6->ZG6_NSRI := Val(SubStr(_clinha,1,9))
			EndIf
			ZG6->(MSUnLock())
		EndIf
	
		//Filtra só registros de marcação e dentro do filtro de data
		If SubStr(_clinha,10,1) == "3" .And. SToD(SubStr(_clinha,15,4)+SubStr(_clinha,13,2)+SubStr(_clinha,11,2)) >= MV_PAR02 .And. SToD(SubStr(_clinha,15,4)+SubStr(_clinha,13,2)+SubStr(_clinha,11,2)) <= MV_PAR03
			aAdd(_anovo,SubStr(_clinha,1,Len(_clinha)-1)+ chr(13) + chr(10))
			_nconti++
		EndIf

		FT_FSKIP()
		_nposi++

		If !_lScheduler
			_oself:cCaption :="Lendo arquivo resposta, posicao " + StrZero(_nposi,15) + " de " + StrZero(_nconta2,15)
		Else
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE016"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01610"/*cMsgId*/, "MGPE01610 - Lendo arquivo resposta, posicao " + StrZero(_nposi,15) + " de " + StrZero(_nconta2,15)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
	EndDo

	FT_FUSE() //Fecha arquivo temp.txt

	aAdd(_anovo,"999999999000000000" + StrZero(_nconti,9) + "0000000000000000009" + chr(13) + chr(10)) 

	//Cria arquivo temporario
	
	If _narqle == -1 .And. file(_ctemp)
		If !_lScheduler
			U_ITMsg("Falha ao criar arquivo temporario","Erro",,1)
		Else
			FWLogMsg("ERROR"/*cSeverity*/, /*cTransactionId*/, "MGPE016"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01611"/*cMsgId*/, "MGPE01611 - Falha ao criar arquivo temporario"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf
		Return
	EndIf 

	_nHandle := FCreate(_ctemp)
	_nI := 1

	While _nI <= Len(_anovo)
		FWrite(_nHandle,_anovo[_nI])
		_nI++

		If !_lScheduler
			//_oself:incregua2("Gravando arquivo  " + AllTrim((_cAlias)->P0_ARQUIVO) + "linha " + StrZero(_nI,15) + " de " + StrZero(Len(_anovo),15))
			_oself:cCaption :="Gravando arquivo  " + AllTrim((_cAlias)->P0_ARQUIVO) + "linha " + StrZero(_nI,15) + " de " + StrZero(Len(_anovo),15)
		Else
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE016"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01612"/*cMsgId*/, "MGPE01612 - Gravando arquivo  " + AllTrim((_cAlias)->P0_ARQUIVO) + "linha " + StrZero(_nI,15) + " de " + StrZero(Len(_anovo),15)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		EndIf

	EndDo

	FClose(_nHandle)	

	//copia arquivo definitivo
	__CopyFile(_ctemp, AllTrim((_cAlias)->P0_ARQUIVO))

	(_cAlias)->(DBSkip())
EndDo

If !_lScheduler
	U_ITMsg("Arquivos atualizados","Processo concluído",,2)
Else
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE016"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01613"/*cMsgId*/, "MGPE01613 - Arquivos atualizados"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf
  
_lcontinua := .F.

Return
