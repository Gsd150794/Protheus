/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

Static _lScheduler:= FWGetRunSchedule() .Or. SELECT("SX3") <= 0

/*
===============================================================================================================================
Programa----------: MGPE027
Autor-------------: Igor Melgaço
Data da Criacao---: 31/10/2023
Descrição---------: Rotina de leitura de equipamentos de ponto via API - Chamado 45400
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE027()
Local _oSelf     := Nil
Local _aParRet   := {}
Local _aParAux   := {}
Local _bOK       := {||.T.  }
Local _nTamFun   := 0
Local _nI        := 0

Default nOper := 0

If _lScheduler //Cria ambiente se For schedule
   
	MV_PAR01 := Space(99)
   MV_PAR02 := dDatabase
   MV_PAR03 := Space(20)

	RPCSetType(3)
	RpcSetEnv( "01" , "01" ,,,"GPE", "SCHEDULE_ATUA" , {'SRA','SP0'} )
	Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.

   MGPE027P(_oSelf)

Else

   _nTamFun   := TamSX3("RA_MAT")[1]

   MV_PAR01 := Space(99)
   MV_PAR02 := CTOD("")
   MV_PAR03 := Space(20)

	aAdd( _aParAux , { 1 , "Equipamentos:              "	, MV_PAR01, ""	   , ""	, "LS2SP0"  , "" , 099, .F. } )
	aAdd( _aParAux , { 1 , "Data Inicial de Marcações: "	, MV_PAR02, "@D"	, ""  , ""	      , "" , 050, .F. } )
	aAdd( _aParAux , { 1 , "NSU de:                    "	, MV_PAR03, ""	   , ""	, ""  		, "" , 020, .F. } )

	For _nI := 1 To Len( _aParAux )
		aAdd( _aParRet , _aParAux[_nI][03] )
	Next _nI

	If ParamBox( _aParAux , " Integração de Dados com o sistema ControlID " , @_aParRet, _bOK )
		FWMsgRun( ,{|_oSelf|  MGPE027P(_oSelf)  } , "Hora Inicial: "+Time()+" Processando integração Control ID... " )
	EndIf
      
EndIf

Return

/*
===============================================================================================================================
Programa----------: MGPE027P
Autor-------------: Igor Melgaço
Data da Criacao---: 31/10/2023
Descrição---------: Lê equipamentos de ponto
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE027P(_oSelf)

Local _nconta	:= 0 
Local _nproce	:= 0
Local _cAlias	:= GetNextAlias()
Local _nHandle	:= 0
Local i        := 0
Local aArquivo := {}
Local _lExec   := .F.
Local _nconti  := 0
Local _dult    := CTOD("")

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
	ConOut("[MGPE027] - Lendo equipamentos" )
EndIf


DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , _cAlias , .T. , .F. )
	
_nconta := (_cAlias)->TOT

cQuery := " SELECT P0_RELOGIO,P0_FILIAL,P0_I_IP, P0_I_CTRID, P0_I_TIPO, P0_ARQUIVO, P0_TPREP   from " 
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
		U_ItConout("Não foram encontrados relógios com os parâmetros informados!")
	EndIf
	
	Return
	
Else
	While .not. (_cAlias)->(Eof())
				
		//Bloco de leitura de equipamentos REP
		_nproce++

		If !_lScheduler
			_oself:cCaption := "Lendo equipamento " + StrZero(_nproce,3) + " de " + StrZero(_nconta,3)
		Else
			U_ItConout("Lendo equipamento " + StrZero(_nproce,3) + " de " + StrZero(_nconta,3))
		EndIf

		If Val(MV_PAR03) == 0 
			NNSU := 1
		Else
			NNSU := Val(MV_PAR03)
		EndIf

		//Prepara dados para conexão com o Relogio
		l671 := !((_cAlias)->P0_TPREP == "1" .Or. Empty(AllTrim((_cAlias)->P0_TPREP)))
		cUrl   := "https://"+AllTrim((_cAlias)->P0_I_IP)
		cParms := '/login.fcgi'

		aHeader := {}
		aAdd(aHeader, "Content-Type: application/json")

		cBodyJson :=  '{'
		cBodyJson +=  '"login": "admin",'
		cBodyJson +=  '"password": "admin"'
		cBodyJson +=  '}'

		cResult := "" 
		
		//Tenta conexão com o relogio
		If U_MGPE026RES(cUrl,cParms,aHeader,cBodyJson,@cResult,5)

			cSession := cResult

			cUrl      := "https://"+AllTrim((_cAlias)->P0_I_IP)
			cParms    := '/get_afd.fcgi?session='+cSession+IIf(l671,'&mode=671','')
			If Empty(AllTrim(MV_PAR03))
				cBodyJson := '{"initial_date":{"day": '+AllTrim(Str(Day(MV_PAR02)))+',"month": '+AllTrim(Str(Month(MV_PAR02)))+',	"year": '+AllTrim(Str(Year(MV_PAR02)))+'}}'
			Else
				cBodyJson := '{"initial_nsr":'+AllTrim(MV_PAR03)+'}'
			EndIf
			U_MGPE026RES(cUrl,cParms,aHeader,cBodyJson,@cResult,6)

			cResult := StrTran(cResult,(_cAlias)->P0_ARQUIVO+".txt","")

			aArquivo := StrTokArr(cResult,Chr(13)+Chr(10))

			aDel(aArquivo,Len(aArquivo))
			aSize(aArquivo,Len(aArquivo)-1)

			_dult := SToD("20010101")

			_nconti := 0

			For i := 1 To Len(aArquivo)
				_clinha := aArquivo[i]

				If SToD(SubStr(_clinha,15,4)+SubStr(_clinha,13,2)+SubStr(_clinha,11,2)) > _dult
					_dult := SToD(SubStr(_clinha,15,4)+SubStr(_clinha,13,2)+SubStr(_clinha,11,2))
				EndIf

				//Filtra só registros de marcação e dentro do filtro de data
				If SubStr(_clinha,10,1) == "3" //.and. SToD(SubStr(_clinha,15,4)+SubStr(_clinha,13,2)+SubStr(_clinha,11,2)) >= MV_PAR02 //.AND. SToD(SubStr(_clinha,15,4)+SubStr(_clinha,13,2)+SubStr(_clinha,11,2)) <= MV_PAR02
					_nconti++
				EndIf

			Next
			aAdd(aArquivo,"999999999000000000" + StrZero(_nconti,9) + "0000000000000000009" + chr(13) + chr(10)) 


			_ctemp := "\temp\" + cUserName + "_temp_"+DToS(Date())+"_"+StrTran(TIME(),":","")+"_temp.txt"

   		_nHandle := FCreate(_ctemp)
	
   		_nI := 1
	
   		While _nI <= Len(aArquivo)
	
				FWrite(_nHandle,aArquivo[_nI]+CHR(13)+CHR(10) )
				_nI++

				If !_lScheduler
					_oself:cCaption := "Gravando arquivo  " + AllTrim((_cAlias)->P0_ARQUIVO) + "linha " + StrZero(_nI,15) + " de " + StrZero(Len(aArquivo),15)
				Else
					U_ItConout("Gravando arquivo  " + AllTrim((_cAlias)->P0_ARQUIVO) + "linha " + StrZero(_nI,15) + " de " + StrZero(Len(aArquivo),15))
				EndIf

   		EndDo
	
   		FClose(_nHandle)	

   		_lExec := __CopyFile(_ctemp, AllTrim((_cAlias)->P0_ARQUIVO))

			If !_lExec
				cLocal := "c:\smartclient\" + cUserName + "_temp_"+DToS(Date())+"_"+StrTran(TIME(),":","")+".txt"

				__CopyFile(_ctemp, cLocal)
				
				_lExec := __CopyFile(cLocal, AllTrim((_cAlias)->P0_ARQUIVO))

				If !_lExec

					cMsg := "Falha ao copiar o arquivo AFD "+ AllTrim((_cAlias)->P0_ARQUIVO)+CHR(13)+CHR(10)+CHR(13)+CHR(10)
					cMsg += "Arquivo temporário gerado na pasta " + _ctemp

					If !_lScheduler
						U_ITMsg(,"Erro",cMsg,1)
					Else
						U_ItConout(cMsg)
					EndIf

				EndIf

			Else
				cMsg := "Arquivo baixado :"+AllTrim((_cAlias)->P0_ARQUIVO)
				If _oSelf <> Nil
					_oSelf:cCaption := cMsg
					ProcessMessages() 
				Else
					U_ItConout(cMsg)           
				EndIf
			EndIf 
		Else
			cMsg := "Eq. " + StrZero(_nProce,3) + " de " + StrZero(_nConta,3) +  " Filial: " + (_cAlias)->P0_FILIAL + " Rel: " + AllTrim((_cAlias)->P0_RELOGIO) + " IP: " + AllTrim((_cAlias)->P0_I_IP) + " Falha de Login: " + Time()

			If _oSelf <> Nil
				_oSelf:cCaption := cMsg
				ProcessMessages() 
			Else
				U_ItConout(cMsg)           
			EndIf
		EndIf

		(_cAlias)->(DBSkip())
	EndDo

EndIf

If !_lScheduler
	U_ITMsg("Arquivos atualizados","Processo concluído",,2)
Else
	U_ItConout("Arquivos atualizados")
EndIf
  
_lcontinua := .F.

Return

