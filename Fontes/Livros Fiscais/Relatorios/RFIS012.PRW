/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |25/09/2024| Chamado 48619. Acompanhamento dos envios e retornos do evento REINF 4020.
=============================================================================================================================== 
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RFIS012
Autor-------------: 
Data da Criacao---: 
Descrição---------: 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function RFIS012()

   Local _aParRet :={}
   Local _aParAux :={} , nI
   Local _bOK     :={|| If(MV_PAR02 >= MV_PAR01,.T.,(U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo",3),.F.) ) }

	Private _aDados := {}

   MV_PAR01 := dDataBase
   MV_PAR02 := dDataBase
   MV_PAR03 := "1"

   aAdd( _aParAux , { 1 , "Data de"	           , MV_PAR01, "@D"	, ""	, ""		, "" , 050 , .F. } )
   aAdd( _aParAux , { 1 , "Data ate"	        , MV_PAR02, "@D"	, ""	, ""		, "" , 050 , .F. } )
   aAdd( _aParAux , { 2 , "Exibir apenas o ultimo recibo", MV_PAR03, {"1-Sim","2-Nao"}          , 060 ,".T.",.T.,".T."}) 

   For nI := 1 To Len( _aParAux )
   	aAdd( _aParRet , _aParAux[nI][03] )
   Next nI

   If !ParamBox( _aParAux , "Intervalo de Datas" , @_aParRet, _bOK )
      Return
   EndIf

	Begin Sequence


		//=============================================
		// Criando Tabela Temporária.
		//=============================================
		_aStruct := {}
		aAdd(_aStruct,{"WK_RECIBO" ,"C",30 ,0})  // Recibo Sped
		aAdd(_aStruct,{"WK_DATA"   ,"D",8  ,0})  // Data Sped
		aAdd(_aStruct,{"WK_HORA"   ,"C",8  ,0})  // Hora Sped
		aAdd(_aStruct,{"WK_RECNO"  ,"N",10 ,0})  // Recno Sped500

		If Select("SPEDTRB") > 0
			SPEDTRB->(DBCloseArea())
		EndIf

		//================================================================================
		// Abre o arquivo TRBCABA criado dentro do banco de dados protheus.
		//================================================================================
		_oTemp := FWTemporaryTable():New( "SPEDTRB",  _aStruct )

		//================================================================================
		// Cria os indices para o arquivo.
		//================================================================================
		_oTemp:AddIndex( "01", {"WK_RECIBO"} )
		_oTemp:Create()

		DBSelectArea("SPEDTRB")

		//=============================================
		// Emite o relatório.
		//=============================================
		Processa( {|| RFIS012D()} , 'Lendo Dados do Relatório...' , 'Aguarde!' )

		If Len(_aDados) == 0
			U_ITMsg("Não existem dados para emissão do relatório.","Atenção",1)
			Break
		EndIf



		_aTitulos := {"Filial",;
			"Evento",;
			"Inscrição",;
			"CNPJ",;
			"Fornecedor",;
			"Base de Calculo",;
			"Valor IR",;
			"Valor PIS",;
			"Valor COFINS",;
			"Valor CSLL",;
			"IR Retorno",;
			"PIS Retorno",;
			"COFINS Retorno",;
			"CSLL Retorno",;
			"Data Transmissao",;
			"Status",;
			"Desc Status",;
			"Recibo",;
			"Cod.Resposta",;
			"Desc.Resposta",;
			"Local do Erro"}


		U_ITListBox("Retorno REINF" , _aTitulos , _aDados , .T. , 1 , "Exportação excel/arquivo")

	End Sequence

	If Select("SPEDTRB") > 0
		SPEDTRB->(DBCloseArea())
	EndIf

Return

/*
===============================================================================================================================
Programa----------: RFIS012D
Autor-------------: 
Data da Criacao---: 
Descrição---------: Gera os dados do relatório e grava em tabelas temporárias para emissão do relatorio em Excel.
Parametros--------: Nenhum
Retorno-----------: .T. OU .F.
===============================================================================================================================
*/  
Static Function RFIS012D()
	Local _cQry
	Local _nTOTREGS
	Local _nI, _cXmlEnvio, _cXmlRetorno
	Local _lNovoReg, _lAtualiza, _nReglidos

	Begin Sequence

		_cQry := " SELECT SPED.RECIBO , SPED.DTPROC, SPED.HRPROC, SPED.DTENTRADA, SPED.R_E_C_N_O_ NRREC "
		_cQry += " FROM SPED500 SPED"
		_cQry += " WHERE  SPED.D_E_L_E_T_ = ' ' "

		If ! Empty(MV_PAR01)
			_cQry +=  " AND DTENTRADA >= '"+DToS(MV_PAR01)+"' "
		EndIf

		If ! Empty(MV_PAR02)
			_cQry +=  " AND DTENTRADA <= '"+DToS(MV_PAR02)+"' "
		EndIf

		_cQry+=  " AND CODEVENTO = 'R-4020' "

		_cQry += " ORDER BY DTENTRADA "

		If Select("QRYSPED") > 0
			QRYSPED->(DBCloseArea())
		EndIf

		_cQry := ChangeQuery(_cQry)

		DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry), "QRYSPED", .F., .T.)

		COUNT TO _nTOTREGS

		If _nTOTREGS == 0
			Break
		EndIf

		//===================================================================================================
		// Abre o arquivo de Sped para leitura dos XML e Envio para o RDC.
		//===================================================================================================
		If Select("SPED500") > 0
			SPED500->( DBCloseArea() )
		EndIf

		USE SPED500 ALIAS "SPED500" SHARED NEW VIA "TOPCONN"

		//===================================================================================================
		// Inicia leitura e gravação dos dados
		//===================================================================================================

		ProcRegua(_nTOTREGS)

		If Subs(MV_PAR03,1,1) ==  "2" // Exibe recibos repetidos
			QRYSPED->(DBGoTop())

			_nI := 1

			While ! QRYSPED->(Eof())
				IncProc( "Favor Aguardar... Processando registro: " + AllTrim( Str(_nI,5) ) +"/"+AllTrim(Str(_nTOTREGS,5)))

				_nI += 1

				SPED500->(DBGoTo(QRYSPED->NRREC))

				_cXmlEnvio := AllTrim(SPED500->XMLEVENTO)

				_cXmlRetorno := AllTrim(SPED500->XMLRETEVEN)

				U_RFIS012R(_cXmlEnvio,_cXmlRetorno)

				_cXmlEnvio   := Nil
				_cXmlRetorno := Nil
				DelClassIntf()  // Remove da memória da Thread todos os objetos.

				QRYSPED->(DBSkip())
			EndDo

		Else // Exibe apena o último recibo quando registrado mais de uma vez.

			QRYSPED->(DBGoTop())

			_nI := 1
			_nReglidos := 0

			While ! QRYSPED->(Eof())
				IncProc( "Favor Aguardar... Processando registro: " + AllTrim( Str(_nI,5) ) +"/"+AllTrim(Str(_nTOTREGS,5)))
				_nI += 1
				_nReglidos += 1

				_lNovoReg :=  .T.
				If SPEDTRB->(MSSEEK(SubStr(QRYSPED->RECIBO,1,30)))
					_lNovoReg := .F.
				EndIf

				If ! _lNovoReg
					If DToS(SPEDTRB->WK_DATA) < QRYSPED->DTPROC .Or. (DToS(SPEDTRB->WK_DATA) == QRYSPED->DTPROC .And. SPEDTRB->WK_HORA < QRYSPED->HRPROC)
						_lAtualiza := .T.
					Else
						_lAtualiza := .F.
					EndIf

					If ! _lAtualiza
						QRYSPED->(DBSkip())
						Loop
					EndIf
				EndIf

				If _lNovoReg
					SPEDTRB->(RecLock("SPEDTRB", .T.))
				Else
					SPEDTRB->(RecLock("SPEDTRB", .F.))
				EndIf

				SPEDTRB->WK_RECIBO := QRYSPED->RECIBO       // Recibo Sped
				SPEDTRB->WK_DATA   := SToD(QRYSPED->DTPROC) // Data Sped
				SPEDTRB->WK_HORA   := QRYSPED->HRPROC       // Hora Sped
				SPEDTRB->WK_RECNO  := QRYSPED->NRREC        // Recno Sped500
				SPEDTRB->(MSUnLock())

				QRYSPED->(DBSkip())
			EndDo

			ProcRegua(_nReglidos)

			SPEDTRB->(DBGoTop())

			_nI := 1

			While ! SPEDTRB->(Eof())

				IncProc( "Favor Aguardar... Processando XMLs (Sped): " + AllTrim( Str(_nI,10) ) + "/" + AllTrim(Str(_nReglidos,10)))
				_nI += 1

				SPED500->(DBGoTo(SPEDTRB->WK_RECNO))

				_cXmlEnvio := AllTrim(SPED500->XMLEVENTO)

				_cXmlRetorno := AllTrim(SPED500->XMLRETEVEN)

				U_RFIS012R(_cXmlEnvio,_cXmlRetorno)

				_cXmlEnvio   := Nil
				_cXmlRetorno := Nil
				DelClassIntf()  // Remove da memória da Thread todos os objetos.

				SPEDTRB->(DBSkip())
			EndDo

		EndIf

	End Sequence

	If Select("QRYSPED") > 0
		QRYSPED->( DBCloseArea() )
	EndIf

	If Select("SPED500") > 0
		SPED500->( DBCloseArea() )
	EndIf

	If Select("SPEDTRB") > 0
		SPEDTRB->( DBCloseArea() )
	EndIf

Return

/*
===============================================================================================================================
Programa----------: RFIS012R
Autor-------------: 
Data da Criacao---: 
Descrição---------: Faz a leitura dos XMLs passados por parâmetro e gera os dados do relatório.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function RFIS012R(_cXmlEnvio,_cXmlRetorno)
	Local _cXmlEnv, _cXmlRet
	Local _cError, _cWarning
	Local _nI, _nTotLin

	Begin Sequence
		_cFilial        := ""
		_cEvento        := ""
		_cNrInscr       := ""
		_cCnpj          := ""
		_cFornecedor    := ""
		_nBaseCalculo   := ""
		_nValorIR       := ""
		_nValorPIS      := ""
		_nValorCOF      := ""
		_nValorCSL      := ""
		_nIRRetorno     := ""
		_nPISRetorno    := ""
		_nCOFRetorno    := ""
		_nCSLRetorno	:= ""
		_dDataTransmissao := Ctod("  /  /  ")
		_cStatus        := ""
		_cDescStatus    := ""
		_cRecibo        := ""
		_cCodResp       := ""
		_cDescResp      := ""
		_cLocalErro     := ""

		_cError   := ""
		_cWarning := ""

		_cXmlEnv := AllTrim(StrTran(_cXmlEnvio,"???",""))

		_oXmlE := ""
		If ! Empty(_cXmlEnv)
			_oXmlE := XmlParser(_cXmlEnv, "_" , @_cError , @_cWarning )
		EndIf

		If ValType(_oXmlE) == "O"

         If AttIsMemberOf(_oXmlE:_REINF:_EVTRETPJ,"_IDEESTAB")

            _cEvento := _oXmlE:_REINF:_EVTRETPJ:_IDEEVENTO:_PERAPUR:TEXT 
         
            If AttIsMemberOf(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB,"_InrInscEstab")
					_cNrInscr := _oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_nrInscEstab:TEXT
				EndIf

            If AttIsMemberOf(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF,"_CNPJBENEF")
					_cCNPJ := _oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_CNPJBENEF:TEXT
				EndIf

            If AttIsMemberOf(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB,"_IDEBENEF") 
               If AttIsMemberOf(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF,"_IDEPGTO")  
      				If ValType( XmlChildEx(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO,"_INFOPGTO")) == "A" //.and. ValType( XmlChildEx(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO[1]:_INFOPGTO,"_RETENCOES")) <> "U"

                     If AttIsMemberOf(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO[1],"_VLRBRUTO")
         					_nBaseCalculo := _oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO[1]:_VLRBRUTO:TEXT
         				EndIf

                     If AttIsMemberOf(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO[1]:_RETENCOES,"_VLRIR")
      						_nValorIR := _oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO[1]:_RETENCOES:_VLRIR:TEXT
      					EndIf

                     If AttIsMemberOf(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO[2]:_RETENCOES,"_VLRPP")
      						_nValorPIS := _oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO[2]:_RETENCOES:_VLRPP:TEXT
      					EndIf

                     If AttIsMemberOf(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO[2]:_RETENCOES,"_VLRCOFINS")
      						_nValorCOF := _oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO[2]:_RETENCOES:_VLRCOFINS:TEXT
      					EndIf

                     If AttIsMemberOf(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO[2]:_RETENCOES,"_VLRCSLL")
      						_nValorCSL := _oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO[2]:_RETENCOES:_VLRCSLL:TEXT
      					EndIf

      				ElseIf ValType( XmlChildEx(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO,"_INFOPGTO")) == "O" .And. ValType( XmlChildEx(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO,"_RETENCOES")) == "O"

                     If AttIsMemberOf(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO:_RETENCOES,"_VLRIR")
      						_nValorIR := _oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO:_RETENCOES:_VLRIR:TEXT
      					EndIf

                     If AttIsMemberOf(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO:_RETENCOES,"_VLRPP")
      						_nValorPIS := _oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO:_RETENCOES:_VLRPP:TEXT
      					EndIf

                     If AttIsMemberOf(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO:_RETENCOES,"_VLRCOFINS")
      						_nValorCOF := _oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO:_RETENCOES:_VLRCOFINS:TEXT
      					EndIf
                     If AttIsMemberOf(_oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO:_RETENCOES,"_VLRCSLL")
      						_nValorCSL := _oXmlE:_REINF:_EVTRETPJ:_IDEESTAB:_IDEBENEF:_IDEPGTO:_INFOPGTO:_RETENCOES:_VLRCSLL:TEXT
      					EndIf

      				EndIf
               EndIf
            EndIf
			EndIf
		EndIf
		_cError   := ""
		_cWarning := ""

		_cXmlRet := AllTrim(StrTran(_cXmlRetorno,"???",""))

		_oXmlR := ""
		If ! Empty(_cXmlRet)
			_oXmlR := XmlParser(_cXmlRet, "_" , @_cError , @_cWarning )
		EndIf

		If ValType(_oXmlR) == "O"
			If Type( "_oXmlR:_REINF") == "O"
            If AttIsMemberOf(_oXmlR:_REINF:_EVTRET:_INFOTOTAL:_IDEESTAB,"_TOTAPURMEN")
               If AttIsMemberOf(_oXmlR:_REINF:_EVTRET:_INFOTOTAL:_IDEESTAB,"_TOTAPURMEN")
   					If ValType( XmlChildEx(_oXmlR:_REINF:_EVTRET:_INFOTOTAL:_IDEESTAB,"_TOTAPURMEN")) == "A"  //ESTES
   						_nTotlin := Len(_oXmlR:_REINF:_EVTRET:_INFOTOTAL:_IDEESTAB:_TOTAPURMEN)
   						If _nTotLin > 0
   							For _nI := 1 To _nTotLin

   								If AllTrim(_oXmlR:_REINF:_EVTRET:_INFOTOTAL:_IDEESTAB:_TOTAPURMEN[_nI]:_CRMEN:TEXT) $  "170806|804506" //IR
   									_nIRRetorno := AllTrim(_oXmlR:_REINF:_EVTRET:_INFOTOTAL:_IDEESTAB:_TOTAPURMEN[_nI]:_TOTAPURTRIBMEN:_VLRCRMENINF:TEXT)
   								EndIf

   								If AllTrim(_oXmlR:_REINF:_EVTRET:_INFOTOTAL:_IDEESTAB:_TOTAPURMEN[_nI]:_CRMEN:TEXT)  == "597907"
   									_nPISRetorno := AllTrim(_oXmlR:_REINF:_EVTRET:_INFOTOTAL:_IDEESTAB:_TOTAPURMEN[_nI]:_TOTAPURTRIBMEN:_VLRCRMENINF:TEXT)
   								EndIf

   								If AllTrim(_oXmlR:_REINF:_EVTRET:_INFOTOTAL:_IDEESTAB:_TOTAPURMEN[_nI]:_CRMEN:TEXT)  == "596007"
   									_nCOFRetorno := AllTrim(_oXmlR:_REINF:_EVTRET:_INFOTOTAL:_IDEESTAB:_TOTAPURMEN[_nI]:_TOTAPURTRIBMEN:_VLRCRMENINF:TEXT)
   								EndIf

   								If AllTrim(_oXmlR:_REINF:_EVTRET:_INFOTOTAL:_IDEESTAB:_TOTAPURMEN[_nI]:_CRMEN:TEXT)  == "598707" // CSLL
   									_nCSLRetorno := AllTrim(_oXmlR:_REINF:_EVTRET:_INFOTOTAL:_IDEESTAB:_TOTAPURMEN[_nI]:_TOTAPURTRIBMEN:_VLRCRMENINF:TEXT)
   								EndIf

   							Next
   						EndIf
   					EndIf
               EndIf
				EndIf
			EndIf

		EndIf

		_cFilial        := U_RFIS012F(_cNrInscr)
		_cFornecedor    := Posicione("SA2",3,xFilial("SA2")+_cCNPJ,"A2_NOME")

		_dDataTransmissao := SPED500->DTTRANS
		_cStatus          := AllTrim(SPED500->STATUS)
		_cDescStatus      := SPED500->DETSTATUS
		_cRecibo          := SPED500->RECIBO


		aAdd(_aDados,{_cFilial,;
			_cEvento,;
			_cNrInscr,;
			_cCNPJ,;
			_cFornecedor,;
			_nBaseCalculo,;
			_nValorIR,;
			_nValorPIS,;
			_nValorCOF,;
			_nValorCSL,;
			_nIRRetorno,;
			_nPISRetorno,;
			_nCOFRetorno,; // _cEnvRet164603,;
			_nCSLRetorno,;
			_dDataTransmissao,;
			_cStatus,;
			_cDescStatus,;
			_cRecibo,;
			_cCodResp,;
			_cDescResp,;
			_cLocalErro})

		_oXmlR := Nil
		_oXmlE := Nil

		DelClassIntf()

	End Sequence

Return

/*
===============================================================================================================================
Programa----------: RFIS007F
Autor-------------: Julio de Paula Paz
Data da Criacao---: 27/08/2021
Descrição---------: Retorna a filial com base no cadastro de filiais Scheduller.
Parametros--------: _cCnpj = CNPJ da unidade
Retorno-----------: _cRet = Código da filia + Nome
===============================================================================================================================
*/  
User Function RFIS012F(_cCnp)
	Local _cRet := ""
	Local _cQry

	Begin Sequence

		_cQry := " SELECT ZZM_CODIGO, ZZM_DESCRI "
		_cQry += " FROM " + RetSqlName("ZZM") + " ZZM "
		_cQry += " WHERE  ZZM.D_E_L_E_T_ = ' ' "
		_cQry += " AND ZZM_CGC = '" + AllTrim(_cCnp) + "' "

		If Select("QRYZZM") > 0
			QRYZZM->(DBCloseArea())
		EndIf

		_cQry := ChangeQuery(_cQry)

		DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry), "QRYZZM", .F., .T.)

		If ! QRYZZM->(Eof()) .And. ! QRYZZM->(Bof())
			_cRet := AllTrim(QRYZZM->ZZM_CODIGO) + "-" + AllTrim(QRYZZM->ZZM_DESCRI)
		EndIf

	End Sequence

	If Select("QRYZZM") > 0
		QRYZZM->( DBCloseArea() )
	EndIf

Return _cRet
