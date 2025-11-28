/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "APWEBSRV.CH"  

/*
===============================================================================================================================
Programa----------: MGPE017
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 24/05/2017
Descrição---------: Fonte criado para atualizar dados Suricato.
Parametros--------: _lweb - indica se está sendo chamado a partir do webservice.
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE017(_lweb,_lLe_So_SA2)

Local oproc
Local _cfils 
Local _afils 
Local _nI := 1

Default _lweb := .F. 
Default _lLe_So_SA2:=.F.

If !(isincallstack("MDIEXECUTE") .Or. isincallstack("SIGAADV")) //Detecta se está sendo chamao na tela
	If _lweb
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01701"/*cMsgId*/, "MGPE01701 - Iniciando processo MGPE017 no web service..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		
        If _lLe_So_SA2
		   U_MGPE017M()
        Else
		   U_MGPE017Y()
        EndIf
		
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01702"/*cMsgId*/, "MGPE01702 - Iniciado processo MGPE017 no web service, encerrando processo local."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01703"/*cMsgId*/, "MGPE01703 - Verificando semaforo..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		If !LockByName("MGPE017",.F.,.F.,.T.)
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01704"/*cMsgId*/, "MGPE01704 - Rotina ja em execução..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			Return
		EndIf

		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01705"/*cMsgId*/, "MGPE01705 - Abrindo o ambiente..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
   
		RPCSetType(3)
		RpcSetEnv( "01" , '01' ,,,"COM", "SCHEDULE_SURICATO" , {'ZP1','SRA'} )
		Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.

		_cfils := SuperGetMV("IT_FILSUR",.T.,"01;10")
		_afils := StrTokArr(_cfils,";")
		_lVersao_Nova:=SuperGetMV("IT_SURNV",.T.,.F.)
		
		If _lLe_So_SA2
		   U_MGPE017M()
			Return
		EndIf

		For _nI := 1 to Len(_afils)
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01706"/*cMsgId*/, "MGPE01706 - Atualizando dados para filial " + _afils[_nI]/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			cfilant := _afils[_nI]

			U_MGPE017P(oproc)
			U_MGPE017P(oproc) //Executa duas vezes para garantir a atualização de cracha de funcionário novo

			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01707"/*cMsgId*/, "MGPE01707 - Completou atualização de dados para filial " + _afils[_nI]/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		Next
	 
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01708"/*cMsgId*/, "MGPE01708 - Verificando Demitidos x Cad. Cliente para todas filiais"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		U_MGPE0177()//Verificando Demitidos x Cad. Cliente
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01709"/*cMsgId*/, "MGPE01709 - Completou a verificação Demitidos x Cad. Cliente"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		
		UnLockByName("MGPE017",.F.,.F.,.T.)
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01710"/*cMsgId*/, "MGPE01710 - Completou a execução da rotina"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		
	EndIf
Else
	If U_ITMsg("Deseja atualizar dados do Suricato?","Exportação",,3,2,2)
      _lVersao_Nova:=SuperGetMV("IT_SURNV",.T.,.F.)
	   FWMsgRun(,{|oProc|  U_MGPE017P(oProc) },'Aguarde processamento...','Lendo dados a serem exportados...')
		U_ITMsg("Processo completado!","Atenção",,2)
	Else
		If U_ITMsg("Deseja veridicar Demitidos x Clientes?","Atenção",,3,2,2)
	  		FWMsgRun(,{|oproc|  U_MGPE0177(oproc)},'Aguarde processamento...','Lendo dados...')
		Else
			If U_ITMsg("Deseja atualizar dados do Suricato com os dados do Motoristas (ZL0)? ","Atenção",,3,2,2)
				 _cMotoristas:=MGPE17F3()
				If !Empty(_cMotoristas)
					FWMsgRun(,{|oproc|  U_MGPE017M(oproc,_cMotoristas)},'Aguarde processamento...','Lendo dados...')
				EndIf   
			Else
				U_ITMsg("Processo cancelado!","Atenção",,1)
			EndIf
		EndIf
	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: MGPE017P
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 24/05/2017
Descrição---------: Rotina de execução principal
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE017P(oproc)

Default oproc := nil

If ValType(oproc) = "O"
   oproc:cCaption := ("1/3 - Atualizando colaboradores no Suricato...")
   ProcessMessages()
EndIf

U_MGPE0171(oproc)

If ValType(oproc) = "O"
   oproc:cCaption := ("2/3 - Atualizando crachas no Suricato...")
   ProcessMessages()
EndIf

U_MGPE0172(oproc)

//Atualiza afastamentos
If ValType(oproc) = "O"
   oproc:cCaption := ("3/3 - Atualizando afastamentos no Suricato...")
   ProcessMessages()
EndIf

U_MGPE0175(oproc)

If !ValType(oproc) = "O"//Só roda no Schedule
   U_MGPE0177()//Verificando Demitidos x Cad. Cliente
EndIf

Return

/*
===============================================================================================================================
Programa----------: MGPE0171
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 24/05/2017
Descrição---------: Função responsável pela exportação dos dados de colaboradores
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE0171(oproc)

Local _cQry		:= ""
Local _ntot := 0
Local _npos := 1
Local _ngrprep := SuperGetMV("IT_SURREP",.T.,1)
Local _nusabio := SuperGetMV("IT_SURBIO",.T.,1)
Default oproc := nil

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01711"/*cMsgId*/, "MGPE01711 - 1/3 -Atualizando dados de colaboradores, lendo dados de funcionários..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

_cQry := "SELECT RA_FILIAL,RA_SITFOLH, RA_DEMISSA,RA_MAT, RA_NOME, RA_DEMISSA,RA_ADMISSA,RA_SEXO,RA_NASC,RA_PIS,RA_I_PSIT,RA_I_ENVD,RA_I_SURIC, RA_SEXO, RA_CIC,R_E_C_N_O_ REC "
_cQry += "FROM " + RetSqlName("SRA") + " SRA "
_cQry += "WHERE RA_FILIAL = '" + xFilial("SRA") + "' "
_cQry += "  AND RA_CATFUNC IN ('M') "
_cQry += "  AND D_E_L_E_T_ = ' ' "
_cQry += "  AND RA_SITFOLH <> 'D' "
_cQry += "  AND RA_PIS > ' ' "
_cQry += " ORDER BY RA_FILIAL, RA_MAT "	


If Select ("TRBSRA") > 0
	TRBSRA->(DBCloseArea())
EndIf

dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBSRA" , .T., .F. )

DBSelectArea("TRBSRA")
Count to _ntot
TRBSRA->(DBGoTop())

If !TRBSRA->(Eof())
	While !TRBSRA->(Eof())
		If ValType(oproc) = "O"
			oproc:cCaption := ("1/3 - Atualizando dados de colaboradores - " + StrZero(_npos,9) + " de " + StrZero(_ntot,9))
			ProcessMessages()
		EndIf
		_npos++
		
		If !Val(AllTrim(TRBSRA->RA_PIS)) > 0
			TRBSRA->(DBSkip())
			Loop
		EndIf
		
		//Verifica se existe cadastro do funcionário no Suricato
		_cQry := "select idcolab,situafas,dataafas,horaafas,numepis,numecpf from SURICATO.tbcolab WHERE  "
		_cQry += " codimatr = " + AllTrim(Str(Val(TRBSRA->RA_MAT))) + " AND CODIEMPR = " + AllTrim(Str(Val(TRBSRA->RA_FILIAL)))

		If Select ("TRBCOL") > 0
			DBSelectArea("TRBCOL")
			TRBCOL->(DBCloseArea())
		EndIf

		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBCOL" , .T., .F. )
		DBSelectArea("TRBCOL")

		//Se não existir cria cadastro cria novo
		If TRBCOL->(Eof())
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01712"/*cMsgId*/, "MGPE01712 - 1/3 - Atualizando dados de colaboradores, incluindo pessoa para matricula " + TRBSRA->RA_FILIAL + "/" + TRBSRA->RA_MAT + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
		
			//Inclui cadastro de pessoa
			_cQry := "insert into suricato.tbpessoa (nomepess) values ('" + AllTrim(TRBSRA->RA_NOME) +  "')"
			_nres := TCSqlExec(_cQry)
			
			RecLock("ZGV",.T.)
			ZGV->ZGV_FILIAL := TRBSRA->RA_FILIAL
			ZGV->ZGV_MAT    := TRBSRA->RA_MAT
			ZGV->ZGV_DATA   := Date()
			ZGV->ZGV_HORA   := Time()
			ZGV->ZGV_COMAND := _cQry
			ZGV->ZGV_RESULT := _nres
			ZGV->ZGV_COMENT := "1/3 - Atualizando dados de colaboradores, incluindo pessoa para matricula " + TRBSRA->RA_FILIAL + "/" + TRBSRA->RA_MAT
			ZGV->(MSUnLock())					
			
			If _nres == 0 //Se incluiu cadastro de pessoa com sucesso
				_cQry := "select idpessoa, nomepess from suricato.tbpessoa where nomepess = '" + AllTrim(TRBSRA->RA_NOME) +  "' ORDER BY idpessoa desc"
				If Select ("TRBPES") > 0
					DBSelectArea("TRBPES")
					TRBPES->(DBCloseArea())
				EndIf

				dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBPES" , .T., .F. )
				DBSelectArea("TRBPES")
				
				If !TRBPES->(Eof()) .And. AllTrim(TRBPES->nomepess) == AllTrim(TRBSRA->RA_NOME) 
					FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01713"/*cMsgId*/, "MGPE01713 - 1/3 - Atualizando dados de colaboradores, incluindo funcionário para matricula " + TRBSRA->RA_FILIAL + "/" + TRBSRA->RA_MAT + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
					
					_cQry :=  "insert into suricato.tbcolab (idpessoa,codiempr,tipocola,codimatr,apelcola,dataadmi,sexocola,datanasc,numecpf,numepis) "
					_cQry +=  " values (" + AllTrim(Str(TRBPES->idpessoa)) 
					_cQry +=  " , " + AllTrim(Str(Val(TRBSRA->RA_FILIAL))) 
					_cQry +=  " ,1  , " + AllTrim(Str(Val(TRBSRA->RA_MAT))) 
					_cQry +=  " ,'" + AllTrim(SubStr(TRBSRA->RA_NOME,1,10)) + "' "
					_cQry +=  " ,TO_DATE('" + AllTrim(TRBSRA->RA_ADMISSA) + "','YYYYMMDD') "
					_cQry +=  " ,'" + AllTrim(TRBSRA->RA_SEXO) + "' "
					_cQry +=  " ,TO_DATE('" + AllTrim(TRBSRA->RA_NASC) + "','YYYYMMDD') "
					_cQry +=  " ,'" + AllTrim(TRBSRA->RA_CIC) + "' "
					_cQry +=  " ," + AllTrim(Str(Val(TRBSRA->RA_PIS))) + ")"
					
					_nres := TCSqlExec(_cQry)

					RecLock("ZGV",.T.)
					ZGV->ZGV_FILIAL := TRBSRA->RA_FILIAL
					ZGV->ZGV_MAT    := TRBSRA->RA_MAT
					ZGV->ZGV_DATA   := Date()
					ZGV->ZGV_HORA   := Time()
					ZGV->ZGV_COMAND := _cQry
					ZGV->ZGV_RESULT := _nres
					ZGV->ZGV_COMENT := "1/3 - Atualizando dados de colaboradores, incluindo funcionario para matricula " + TRBSRA->RA_FILIAL + "/" + TRBSRA->RA_MAT
					ZGV->(MSUnLock())					
					
					If _nres == 0
						FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01714"/*cMsgId*/, "MGPE01714 - 1/3 -Atualizando dados de colaboradores, incluido com sucesso funcionário para matricula " + TRBSRA->RA_FILIAL + "/" + TRBSRA->RA_MAT + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
					Else
						FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01715"/*cMsgId*/, "MGPE01715 - 1/3 - Atualizando dados de colaboradores, FALHA ao incluir funcionário para matricula " + TRBSRA->RA_FILIAL + "/" + TRBSRA->RA_MAT + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
					EndIf
				Else
					FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01716"/*cMsgId*/, "MGPE01716 - 1/3 - Atualizando dados de colaboradores, FALHA ao incluir pessoa para matricula " + TRBSRA->RA_FILIAL + "/" + TRBSRA->RA_MAT + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				EndIf
			Else
				FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01717"/*cMsgId*/, "MGPE01717 - 1/3 - Atualizando dados de colaboradores, FALHA ao incluir pessoa para matricula " + TRBSRA->RA_FILIAL + "/" + TRBSRA->RA_MAT + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			EndIf
		
		 //Se já existe cadastro verifica se precisa atualizar
		ElseIf !(TRBCOL->NUMEPIS == Val(TRBSRA->RA_PIS) ) .Or. !(TRBCOL->NUMECPF == Val(TRBSRA->RA_CIC) )
			_cQry := " UPDATE SURICATO.TBCOLAB SET NUMEPIS = " + AllTrim(TRBSRA->RA_PIS) + ", NUMECPF = " + AllTrim(TRBSRA->RA_CIC) 
			_cQry += " WHERE IDCOLAB = " + AllTrim(Str(TRBCOL->IDCOLAB))
			_nres := TCSqlExec(_cQry)
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01718"/*cMsgId*/, "MGPE01718 - 1/3 - Atualizando dados de colaboradores, atualizando dados do colaborador - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

			RecLock("ZGV",.T.)
			ZGV->ZGV_FILIAL := TRBSRA->RA_FILIAL
			ZGV->ZGV_MAT    := TRBSRA->RA_MAT
			ZGV->ZGV_DATA   := Date()
			ZGV->ZGV_HORA   := Time()
			ZGV->ZGV_COMAND := _cQry
			ZGV->ZGV_RESULT := _nres
			ZGV->ZGV_COMENT := "1/3 - Atualizando dados de colaboradores, atualizando dados do colaborador - "  + AllTrim(Str(TRBCOL->IDCOLAB))
			ZGV->(MSUnLock())					
		EndIf
				
		//verifica na tabela de colaboradores e se tiver verifica e atualiza tabela de acessos
		_cQry := "select idcolab,situafas,dataafas,horaafas,numepis from SURICATO.tbcolab WHERE  "
		_cQry += " codimatr = " + AllTrim(Str(Val(TRBSRA->RA_MAT))) + " AND CODIEMPR = " + AllTrim(Str(Val(TRBSRA->RA_FILIAL)))

		If Select ("TRBCOL") > 0
			TRBCOL->(DBCloseArea())
		EndIf

		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBCOL" , .T., .F. )

		DBSelectArea("TRBCOL")

		//se existe verifica se tem tabela de acesso
		If !TRBCOL->(Eof())
			_cQry := "select idcolab,veripermaces,codiperm,permacesferi,permacessaba,permacesdomi,permacesvisi,faixhoraaces,contantidupl, "
            _cQry += " colarecevisi,veriafas,autosaidcola,autohoraextr,colautilveic,grauconfbiom,colaretibene,datavaliaso,datatreisegu, "
            _cQry += " datapendplan,codiplan,contcredrefe,tempminialmo,tempminiperm,tolecontperm,contbiom,idcolabsubs, regiponto, gruprepid "
            _cQry += " from SURICATO.tbacesscolab WHERE idcolab =  " + AllTrim(Str(TRBCOL->IDCOLAB))

			If Select ("TRBACE") > 0
				TRBACE->(DBCloseArea())
			EndIf

			dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBACE" , .T., .F. )
			DBSelectArea("TRBACE")

			//se existe verifica se tem tabela de acesso
			If !TRBACE->(Eof())
				//Verifica se precisa atualizar campos
				If !( TRBACE->VERIPERMACES = 'S' .AND.;
					  TRBACE->AUTOSAIDCOLA = 'N' .AND.;
					  TRBACE->CODIPERM = 1 .AND.;
					  TRBACE->PERMACESFERI = 1 .AND.;
					  TRBACE->PERMACESSABA = 1 .AND.;
					  TRBACE->PERMACESDOMI = 1 .AND.;
					  TRBACE->PERMACESVISI = 1 .AND.;
					  TRBACE->FAIXHORAACES = 0 .AND.;
					  TRBACE->CONTANTIDUPL = 'S' .AND.;
					  TRBACE->COLARECEVISI = 'S' .AND.;
					  TRBACE->VERIAFAS = 'S' .AND.;
					  TRBACE->AUTOSAIDCOLA = 'N' .AND.;
					  TRBACE->AUTOHORAEXTR = 'N' .AND.;
					  TRBACE->COLAUTILVEIC = 'N' .AND.;
					  TRBACE->GRAUCONFBIO = 0 .AND.;
					  TRBACE->COLARETIBENE = 'S' .AND.;
					  TRBACE->DATAVALIASO = SToD("19001231") .AND.;
					  TRBACE->DATATREISEGU = SToD("19001231") .AND.;
					  TRBACE->DATAPENDPLAN = SToD("19001231") .AND.;
					  TRBACE->CODIPLAN = 0 .AND.; //  TRBACE->CONTCREDREFE = IIf(cfilant $ '01,10',3,0) .AND.;  // IIf(cfilant ='01',3,0)
					  TRBACE->TEMPMINIALMO = 0 .AND.;
					  TRBACE->TEMPMINIPERM = 0 .AND.;
					  TRBACE->TOLECONTPERM = 0 .AND.;
					  TRBACE->CONTBIOM = _nusabio .AND.;
					  TRBACE->GRUPREPID = _ngrprep.AND.;
					  TRBACE->REGIPONTO = 'S' .And. ;
					  TRBACE->IDCOLABSUBS = 0 )
					  
					  _cQry := " update SURICATO.tbacesscolab set veripermaces = 'S' ,codiperm = 1,permacesferi = 1,permacessaba = 1,permacesdomi = 1,permacesvisi = 1,faixhoraaces = 0, "
					  _cQry += " contantidupl = 'S',colarecevisi = 'S',veriafas = 'S',autosaidcola = 'N',autohoraextr='N',colautilveic='N',grauconfbiom=0,colaretibene='S', " 
					  _cQry += " datavaliaso = TO_DATE('19001231','YYYYMMDD'),datatreisegu = TO_DATE('19001231','YYYYMMDD'),datapendplan = TO_DATE('19001231','YYYYMMDD'), "
					  //_cQry += " codiplan = 0 ,contcredrefe = " + IIf(cfilant $ '01,10',"3","0") + ", tempminialmo = 0,tempminiperm = 0,tolecontperm = 0,contbiom = "   
					  _cQry += " codiplan = 0 , tempminialmo = 0,tempminiperm = 0,tolecontperm = 0,contbiom = "   
					  _cQry +=  AllTrim(Str(_nusabio)) + " ,idcolabsubs = 0, regiponto = 'S', gruprepid = " + AllTrim(Str(_ngrprep))
					  _cQry += " where idcolab =  " + AllTrim(Str(TRBCOL->IDCOLAB))
                
					  _nres := TCSqlExec(_cQry)
					  FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01719"/*cMsgId*/, "MGPE01719 - 1/3 - Atualizando dados de colaboradores, atualizando tabela de acesso do colaborador - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

					  RecLock("ZGV",.T.)
					  ZGV->ZGV_FILIAL := TRBSRA->RA_FILIAL
					  ZGV->ZGV_MAT    := TRBSRA->RA_MAT
					  ZGV->ZGV_DATA   := Date()
					  ZGV->ZGV_HORA   := Time()
					  ZGV->ZGV_COMAND := _cQry
					  ZGV->ZGV_RESULT := _nres
					  ZGV->ZGV_COMENT := "1/3 - Atualizando dados de colaboradores, atualizando tabela de acesso do colaborador - "  + AllTrim(Str(TRBCOL->IDCOLAB))
					  ZGV->(MSUnLock())		
				EndIf
			Else
		
				_cQry := " insert into SURICATO.tbacesscolab (idcolab,veripermaces,codiperm,permacesferi,permacessaba,permacesdomi,permacesvisi,faixhoraaces,contantidupl, "
		        _cQry += " colarecevisi,veriafas,autosaidcola,autohoraextr,colautilveic,grauconfbiom,colaretibene,datavaliaso,datatreisegu, "
		        _cQry += " datapendplan,codiplan,contcredrefe,tempminialmo,tempminiperm,tolecontperm,contbiom,idcolabsubs,gruprepid,regiponto) "
		        _cQry += " values (" + AllTrim(Str(TRBCOL->IDCOLAB)) + ",'S',1, 1,1,1,1,0,'S', "
		        _cQry += " 'S','S','N','N','N',0,'S',TO_DATE('19001231','YYYYMMDD'),TO_DATE('19001231','YYYYMMDD'), "
		        _cQry += " TO_DATE('19001231','YYYYMMDD'),0," + IIf(cfilant == '01',"3","0") + ",0,0,0," + AllTrim(Str(_nusabio)) + ",0," + AllTrim(Str(_ngrprep)) + ",'S') "
               
		        _nres := TCSqlExec(_cQry)
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01720"/*cMsgId*/, "MGPE01720 - 1/3 - Atualizando dados de colaboradores, incluindo tabela de acesso do colaborador - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
								
  			    RecLock("ZGV",.T.)
        		ZGV->ZGV_FILIAL := TRBSRA->RA_FILIAL
        		ZGV->ZGV_MAT    := TRBSRA->RA_MAT
        		ZGV->ZGV_DATA   := Date()
        		ZGV->ZGV_HORA   := Time()
        		ZGV->ZGV_COMAND := _cQry
        		ZGV->ZGV_RESULT := _nres
        		ZGV->ZGV_COMENT := "1/3 - Atualizando dados de colaboradores, incluindo tabela de acesso do colaborador - "  + AllTrim(Str(TRBCOL->IDCOLAB))
        		ZGV->(MSUnLock())		
   		   EndIf
		
      		//verifica se campo STATATUACONT está atualizado
      		_cQry := "select STATATUACONT from SURICATO.tbhistocrach CRACH  "
      		_cQry += " WHERE (SELECT SITUAFAS FROM SURICATO.TBCOLAB COL WHERE CRACH.IDCOLAB = COL.IDCOLAB ) = 1 AND STATATUACONT <> 1 AND CRACH.IDCOLAB = " + AllTrim(Str(TRBCOL->IDCOLAB))

      		If Select ("TRBCRC") > 0
      			TRBCRC->(DBCloseArea())
  		    EndIf

      		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBCRC" , .T., .F. )
      		DBSelectArea("TRBCRC")

    		//se existe verifica se tem tabela de acesso
      		If !TRBCRC->(Eof())
     			//Garante que campo STATATUACONT está atualizado
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01721"/*cMsgId*/, "MGPE01721 - 1/3 - Atualizando dados de colaboradores, ajustando campo STATATUACONT  - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
     			_cQry := " UPDATE suricato.TBHISTOCRACH CRACH SET STATATUACONT = 1 WHERE (SELECT SITUAFAS FROM suricato.TBCOLAB COL WHERE CRACH.IDCOLAB = COL.IDCOLAB ) = 1 "
     			_cQry += " AND STATATUACONT <> 1 AND CRACH.IDCOLAB = " + AllTrim(Str(TRBCOL->IDCOLAB))
     			_nres := TCSqlExec(_cQry)
      		EndIf

			//Verifica se existe registro na TBGRUPOREPCOLAB para o colaborador
			_cQry := "select gruprepid, idcolab "
 		    _cQry += " from SURICATO.TBGRUPOREPCOLAB WHERE idcolab =  " + AllTrim(Str(TRBCOL->IDCOLAB))

			If Select ("TRBREP") > 0
				TRBREP->(DBCloseArea())
			EndIf

			dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBREP" , .T., .F. )
			DBSelectArea("TRBREP")

			//se existe verifica se tem grupo está correto
			If !TRBREP->(Eof())
				If TRBREP->GRUPREPID != _ngrprep
					//Faz update
	  				_cQry := " update SURICATO.TBGRUPOREPCOLAB set gruprepid = " + AllTrim(Str(_ngrprep))
					_cQry += " where idcolab =  " + AllTrim(Str(TRBCOL->IDCOLAB))
                
					_nres := TCSqlExec(_cQry)
					FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01722"/*cMsgId*/, "MGPE01722 - 1/3 - Atualizando dados de colaboradores, atualizando tabela de grupo de rep do colaborador - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

					RecLock("ZGV",.T.)
					ZGV->ZGV_FILIAL := TRBSRA->RA_FILIAL
					ZGV->ZGV_MAT    := TRBSRA->RA_MAT
					ZGV->ZGV_DATA   := Date()
					ZGV->ZGV_HORA   := Time()
					ZGV->ZGV_COMAND := _cQry
					ZGV->ZGV_RESULT := _nres
					ZGV->ZGV_COMENT := "1/3 - Atualizando dados de colaboradores, atualizando tabela de grupo de rep do colaborador - "  + AllTrim(Str(TRBCOL->IDCOLAB))
					ZGV->(MSUnLock())		
				EndIf
			Else //Se não existe inclui registro com grupo de rep
				_cQry := " insert into SURICATO.TBGRUPOREPCOLAB (idcolab,gruprepid) "
        		_cQry += " values (" + AllTrim(Str(TRBCOL->IDCOLAB)) + "," + AllTrim(Str(_ngrprep)) + ") "
               
        		_nres := TCSqlExec(_cQry)
        		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01723"/*cMsgId*/, "MGPE01723 - 1/3 - Atualizando dados de colaboradores, incluindo tabela de grupo de rep do colaborador - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
								
        		RecLock("ZGV",.T.)
        		ZGV->ZGV_FILIAL := TRBSRA->RA_FILIAL
        		ZGV->ZGV_MAT    := TRBSRA->RA_MAT
        		ZGV->ZGV_DATA   := Date()
        		ZGV->ZGV_HORA   := Time()
        		ZGV->ZGV_COMAND := _cQry
        		ZGV->ZGV_RESULT := _nres
        		ZGV->ZGV_COMENT := "1/3 - Atualizando dados de colaboradores, incluindo tabela de grupo de rep do colaborador - "  + AllTrim(Str(TRBCOL->IDCOLAB))
        		ZGV->(MSUnLock())		
			EndIf
		EndIf
		TRBSRA->(DBSkip())
	EndDo
EndIf

TRBSRA->(DBCloseArea())
	
Return

/*
===============================================================================================================================
Programa----------: MGPE0172
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 24/05/2017
Descrição---------: Função responsável pela atualização de dados de crachás
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE0172(oproc)
Local _cQry		:= ""
Local _cCracha	:= Space(30)
Local _npos := 1
Local _ntot := 0
Default oproc := nil

If ValType(oproc) = "O"
	oproc:cCaption := ("2/3 - Atualizando dados de crachas, lendo dados...")
	ProcessMessages()
EndIf

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01724"/*cMsgId*/, "MGPE01724 - 2/3 - Atualizando dados de crachas, lendo dados..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

_cQry := "SELECT RA_MAT MAT, RA_I_CRACH CRACHA, 'SRA' TIPO, RA_PIS PIS,RA_FILIAL FILIAL, RA_CIC CPF "
_cQry += "FROM " + RetSqlName("SRA") + " SRA "
_cQry += "WHERE RA_FILIAL = '" + xFilial("SRA") + "' "
_cQry += "  AND RA_CATFUNC IN ('M')"
_cQry += "  AND RA_SITFOLH <> 'D'"
_cQry += "  AND RA_PIS > ' ' "
_cQry += "  AND D_E_L_E_T_ = ' ' "
_cQry += " UNION ALL "
_cQry += "SELECT PE_MAT MAT, PE_I_CRACH CRACHA, 'SPE' TIPO, 'PIS' PIS,PE_FILIAL FILIAL, ' ' CPF "
_cQry += "FROM " + RetSqlName("SPE") + " SPE "
_cQry += "WHERE PE_FILIAL = '" + xFilial("SPE") + "' "
_cQry += "  AND (PE_I_CRACH <> ' ' AND PE_I_CRACH NOT IN (	SELECT RA_I_CRACH "
_cQry += "													FROM " + RetSqlName("SRA") + " SRA "
_cQry += "    	            	                            WHERE RA_FILIAL = '" + xFilial("SRA") + "' "
_cQry += "        	            	                          AND RA_I_CRACH <> ' ' "
_cQry += "            	            	                      AND SRA.D_E_L_E_T_ = ' ')) "

If Select ("TRBSRA") > 0
	TRBSRA->(DBCloseArea())
EndIf

dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBSRA" , .T., .F. )

DBSelectArea("TRBSRA")
Count to _ntot
TRBSRA->(DBGoTop())

If !TRBSRA->(Eof())
	While !TRBSRA->(Eof())
		If ValType(oproc) = "O"
			oproc:cCaption := ("2/3 - Atualizando dados de crachas - " + StrZero(_npos,9) + " de " + StrZero(_ntot,9))
			ProcessMessages()
		EndIf
		_npos++

		//Verifica se existe o crachá na tabela de crachas
		_cCracha := StrTran(AllTrim(TRBSRA->CRACHA),",","")
		_cCracha := StrTran(_cCracha,".","")
		_cCracha := AllTrim(Str(Val(_cCracha)))
		
		If _cCracha == "0"
			_cCracha := AllTrim(TRBSRA->CPF)
		EndIf

		If !Empty(_cCracha) .And. Val(_cCracha) > 0
			_cQry := " select * from suricato.tbcadascrach WHERE ICARD = " + _cCracha
			If Select ("TRBCRH") > 0
				TRBCRH->(DBCloseArea())
			EndIf

			dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBCRH" , .T., .F. )
			DBSelectArea("TRBCRH")

			//Se não existir cria cadastro cria novo
			If TRBCRH->(Eof())
				_cQry := "insert into suricato.tbcadascrach (icard,usofaixcrac,numecrac) values ('" + _cCracha +  "',1,'" + _cCracha +  "')"
				_nres := TCSqlExec(_cQry)
			
				RecLock("ZGV",.T.)
				ZGV->ZGV_FILIAL := TRBSRA->FILIAL
				ZGV->ZGV_MAT    := TRBSRA->MAT
				ZGV->ZGV_DATA   := Date()
				ZGV->ZGV_HORA   := Time()
				ZGV->ZGV_COMAND := _cQry
				ZGV->ZGV_RESULT := _nres
				ZGV->ZGV_COMENT := "2/3 - Atualizando dados de crachas, incluindo cracha " + _cCracha
				ZGV->(MSUnLock())	
			
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01725"/*cMsgId*/, "MGPE01725 - 2/3 - Atualizando dados de crachas, incluindo cracha " + _cCracha/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			EndIf
		EndIf
		
		//Verifica se o funcionario está ativo
		_lativo  := .F.
		
		If AllTrim(TRBSRA->TIPO) == "SRA"
			_cQry := "select idcolab,situafas,dataafas,horaafas from SURICATO.tbcolab WHERE NUMEPIS = " + AllTrim(TRBSRA->PIS)
			_cQry += " and codimatr = " + AllTrim(Str(Val(TRBSRA->MAT))) + " AND CODIEMPR = " + AllTrim(Str(Val(TRBSRA->FILIAL)))

			If Select ("TRBCOL") > 0
				TRBCOL->(DBCloseArea())
			EndIf

			dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBCOL" , .T., .F. )
			DBSelectArea("TRBCOL")

			If !TRBCOL->(Eof())
				If TRBCOL->SITUAFAS = 1 
					_lativo := .T.
				EndIf
			EndIf
		EndIf

		//Se For registro da SRA com cracha vinculado e ativo confere e ajusta Suricato se necessário
		If AllTrim(TRBSRA->TIPO) == "SRA" .And. !Empty(_cCracha) .And. _lativo .And. Val(_cCracha) > 0
			//Verifica se existe registro antigo com mesmo cracha e idcolab diferente, se tiver fecha datafim e stathist
			_cQry :=  " SELECT COUNT(*) CONTA FROM SURICATO.TBHISTOCRACH WHERE ICARD = " + _cCracha 
            _cQry +=  "  AND TIPOCRAC = 1 "
            _cQry +=  "  AND DATAINIC <= TO_DATE('" + DToS(date()) + "', 'YYYYMMDD') "
            _cQry +=  "  AND (DATAFINA >= TO_DATE('" + DToS(date()) + "', 'YYYYMMDD') OR DATAFINA = TO_DATE('19001231', 'YYYYMMDD')) "
            _cQry +=  "  AND IDCOLAB <> (SELECT IDCOLAB FROM suricato.TBCOLAB where codiempr = " + AllTrim(Str(Val(xFilial("SRA")))) 
			_cQry +=  "                                                                and TIPOCOLA = TIPOCRAC " 
  			_cQry +=  "                                                                and CODIMATR = " + AllTrim(Str(Val(TRBSRA->MAT))) + ") "
 
 			If Select ("TRBCR1") > 0
				TRBCR1->(DBCloseArea())
			EndIf

			dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBCR1" , .T., .F. )
			DBSelectArea("TRBCR1")

			//Se existir muda stathist para 2 e datafina para dia anterior
			If TRBCR1->CONTA > 0
				_cQry := "UPDATE suricato.tbhistocrach SET DATAFINA = TO_DATE('" + DToS(date()-1) + "', 'YYYYMMDD'), STATHIST = 2"
				_cQry += " WHERE ICARD = " + _cCracha 
				_cQry +=  "  AND TIPOCRAC = 1 "
				_cQry +=  "  AND DATAINIC <= TO_DATE('" + DToS(date()) + "', 'YYYYMMDD') "
				_cQry +=  "  AND (DATAFINA >= TO_DATE('" + DToS(date()) + "', 'YYYYMMDD') OR DATAFINA = TO_DATE('19001231', 'YYYYMMDD')) "
				_cQry +=  "  AND IDCOLAB <> (SELECT IDCOLAB FROM suricato.TBCOLAB where codiempr = " + AllTrim(Str(Val(xFilial("SRA")))) 
				_cQry +="                                                                and CODIMATR = " + AllTrim(Str(Val(TRBSRA->MAT))) +  " ) " 
							
				_nres := TCSqlExec(_cQry)
				
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01726"/*cMsgId*/, "MGPE01726 - 2/3 - Atualizando dados de crachas - Desativando cracha para funcionario - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

				RecLock("ZGV",.T.)
				ZGV->ZGV_FILIAL := TRBSRA->FILIAL
				ZGV->ZGV_MAT    := TRBSRA->MAT
				ZGV->ZGV_DATA   := Date()
				ZGV->ZGV_HORA   := Time()
				ZGV->ZGV_COMAND := _cQry
				ZGV->ZGV_RESULT := _nres
				ZGV->ZGV_COMENT := "2/3 - Atualizando dados de crachas - Desativando cracha para funcionario - "  + AllTrim(Str(TRBCOL->IDCOLAB))
				ZGV->(MSUnLock())		
			EndIf
			
			//Verifica se existe registro antigo com mesmo idcolab e cracha diferente, se tiver fecha datafim e stathist
			_cQry :=  " SELECT COUNT(*) CONTA FROM SURICATO.TBHISTOCRACH WHERE idcolab = (SELECT IDCOLAB FROM suricato.TBCOLAB where codiempr = " 
			_cQry +=                                  AllTrim(Str(Val(xFilial("SRA")))) + " and CODIMATR = " + AllTrim(Str(Val(TRBSRA->MAT))) 
			_cQry +=  "                               and TIPOCOLA = TIPOCRAC ) " 
            _cQry +=  "  AND TIPOCRAC = 1 "
            _cQry +=  "  AND DATAINIC <= TO_DATE('" + DToS(date()) + "', 'YYYYMMDD') "
            _cQry +=  "  AND (DATAFINA >= TO_DATE('" + DToS(date()) + "', 'YYYYMMDD') OR DATAFINA = TO_DATE('19001231', 'YYYYMMDD')) "
            _cQry +=  "  AND ICARD <> " + _cCracha 
	
			If Select ("TRBCR2") > 0
				TRBCR2->(DBCloseArea())
			EndIf

			dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBCR2" , .T., .F. )
			DBSelectArea("TRBCR2")

			//Se existir muda stathist para 2 e datafina para dia anterior
			If TRBCR2->CONTA > 0
				_cQry := "UPDATE suricato.tbhistocrach SET DATAFINA = TO_DATE('" + DToS(date()-1) + "', 'YYYYMMDD'), STATHIST = 2"
				_cQry += " WHERE idcolab = (SELECT IDCOLAB FROM suricato.TBCOLAB where codiempr = " 
				_cQry +=                                  AllTrim(Str(Val(xFilial("SRA")))) + " and CODIMATR = " + AllTrim(Str(Val(TRBSRA->MAT))) + " ) " 
				_cQry +=  "  AND TIPOCRAC = 1 "
				_cQry +=  "  AND DATAINIC <= TO_DATE('" + DToS(date()) + "', 'YYYYMMDD') "
				_cQry +=  "  AND (DATAFINA >= TO_DATE('" + DToS(date()) + "', 'YYYYMMDD') OR DATAFINA = TO_DATE('19001231', 'YYYYMMDD')) "
				_cQry +=  "  AND ICARD <> " + _cCracha 	
				_nres := TCSqlExec(_cQry)
				
				If _nres < 0 //Erro de update, provavelmente duplicando chave unica, então apaga o registro
					_cQry := "delete from suricato.tbhistocrach "
					_cQry += " WHERE idcolab = (SELECT IDCOLAB FROM suricato.TBCOLAB where codiempr = " 
					_cQry +=                                  AllTrim(Str(Val(xFilial("SRA")))) + " and CODIMATR = " + AllTrim(Str(Val(TRBSRA->MAT))) + " ) "  
					_cQry +=  "  AND TIPOCRAC = 1 "
					_cQry +=  "  AND DATAINIC <= TO_DATE('" + DToS(date()) + "', 'YYYYMMDD') "
					_cQry +=  "  AND (DATAFINA >= TO_DATE('" + DToS(date()) + "', 'YYYYMMDD') OR DATAFINA = TO_DATE('19001231', 'YYYYMMDD')) "
					_cQry +=  "  AND ICARD <> " + _cCracha 	
					_nres := TCSqlExec(_cQry)
				EndIf
				
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01727"/*cMsgId*/, "MGPE01727 - 2/3 - Atualizando dados de crachas - Desativando cracha para funcionario - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

				RecLock("ZGV",.T.)
				ZGV->ZGV_FILIAL := TRBSRA->FILIAL
				ZGV->ZGV_MAT    := TRBSRA->MAT
				ZGV->ZGV_DATA   := Date()
				ZGV->ZGV_HORA   := Time()
				ZGV->ZGV_COMAND := _cQry
				ZGV->ZGV_RESULT := _nres
				ZGV->ZGV_COMENT := "2/3 - Atualizando dados de crachas - Desativando cracha para funcionario - "  + AllTrim(Str(TRBCOL->IDCOLAB))
				ZGV->(MSUnLock())
			EndIf

			//Verifica se existe registro com idcolab e cracha, se não existir inclui, se existir verifica diferenças e atualiza se necessário
			_cQry :=  " SELECT idcolab, DATAFINA, icard FROM SURICATO.TBHISTOCRACH WHERE idcolab = (SELECT IDCOLAB FROM suricato.TBCOLAB where codiempr = " 
			_cQry +=                                  AllTrim(Str(Val(xFilial("SRA")))) + " and CODIMATR = " + AllTrim(Str(Val(TRBSRA->MAT))) 
			_cQry +=  "                               and TIPOCOLA = TIPOCRAC ) "  
            _cQry +=  "  AND TIPOCRAC = 1 "
            _cQry +=  "  AND DATAINIC <= TO_DATE('" + DToS(date()) + "', 'YYYYMMDD') "
            _cQry +=  "  AND (DATAFINA >= TO_DATE('" + DToS(date()) + "', 'YYYYMMDD') OR DATAFINA = TO_DATE('19001231', 'YYYYMMDD')) "
            _cQry +=  "  AND ICARD = " + _cCracha 

 			If Select ("TRBCR3") > 0
				TRBCR3->(DBCloseArea())
			EndIf

			dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBCR3" , .T., .F. )
			DBSelectArea("TRBCR3")

			//Se não existir insere
			If TRBCR3->(Eof())
				_cminutos := AllTrim(Str((Val(SubStr(time(),1,2))*60) + (Val(SubStr(time(),4,2)))))

				_cQry := "insert into suricato.tbhistocrach (tipocrac,datainic,horainic,idcolab,numeviacrac,icard,datafina,horafina,stathist,statatuacont,codiusua) "
				_cQry += " values ( 1, TO_DATE('" + DToS(date()) + "', 'YYYYMMDD')," + _cminutos  +  ", (SELECT IDCOLAB FROM suricato.TBCOLAB where codiempr = " 
			    _cQry +=   AllTrim(Str(Val(xFilial("SRA")))) + " and CODIMATR = " + AllTrim(TRBSRA->MAT) + " ) "  + ",0," + _cCracha
			    _cQry += ",TO_DATE('19001231', 'YYYYMMDD'),0,1,1,0 )"
		
				_nres := TCSqlExec(_cQry)
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01728"/*cMsgId*/, "MGPE01728 - 2/3 - Atualizando dados de crachas - Incluindo cracha para funcionario - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

				RecLock("ZGV",.T.)
				ZGV->ZGV_FILIAL := TRBSRA->FILIAL
				ZGV->ZGV_MAT    := TRBSRA->MAT
				ZGV->ZGV_DATA   := Date()
				ZGV->ZGV_HORA   := Time()
				ZGV->ZGV_COMAND := _cQry
				ZGV->ZGV_RESULT := _nres
				ZGV->ZGV_COMENT := "2/3 - Atualizando dados de crachas - Incluindo cracha para funcionario - "  + AllTrim(Str(TRBCOL->IDCOLAB))
				ZGV->(MSUnLock())
			
			//Se existir com data limitada ou cracha errado muda para data final sem limite e para o cracha certo
			ElseIf TRBCR3->DATAFINA != SToD("19001231") .Or. AllTrim(Str(TRBCR3->ICARD)) != AllTrim(Str(Val(_cCracha)))
			  	_cQry := "UPDATE suricato.tbhistocrach SET DATAFINA = TO_DATE('19001231', 'YYYYMMDD'), STATHIST = 1, ICARD = " + _cCracha 
			  	_cQry += " WHERE IDCOLAB =  " + AllTrim(Str(TRBCR3->IDCOLAB))		
			  	_cQry +=  "  AND TIPOCRAC = 1 "
			  	_cQry +=  "  AND DATAINIC <= TO_DATE('" + DToS(date()) + "', 'YYYYMMDD') "
			  	_cQry +=  "  AND (DATAFINA >= TO_DATE('" + DToS(date()) + "', 'YYYYMMDD') OR DATAFINA = TO_DATE('19001231', 'YYYYMMDD')) "
			  	_cQry +=  "  AND ICARD = " + AllTrim(Str(Val(_cCracha)))
				
				_nres := TCSqlExec(_cQry)
				
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01729"/*cMsgId*/, "MGPE01729 - 2/3 - Atualizando dados de crachas - Atualizando cracha para funcionario - "  + AllTrim(Str(TRBCR3->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

				RecLock("ZGV",.T.)
				ZGV->ZGV_FILIAL := TRBSRA->FILIAL
				ZGV->ZGV_MAT    := TRBSRA->MAT
				ZGV->ZGV_DATA   := Date()
				ZGV->ZGV_HORA   := Time()
				ZGV->ZGV_COMAND := _cQry
				ZGV->ZGV_RESULT := _nres
				ZGV->ZGV_COMENT := "2/3 - Atualizando dados de crachas - Atualizando cracha para funcionario - "  + AllTrim(Str(TRBCR3->IDCOLAB))
				ZGV->(MSUnLock())
			EndIf
		EndIf
		TRBSRA->(DBSkip())
	End
EndIf

TRBSRA->(DBCloseArea())

Return

/*
===============================================================================================================================
Programa----------: MGPE0175
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 26/05/2017
Descrição---------: Função responsável pela atualização de afastamentos no Suricato
Parametros--------: oproc - objeto de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE0175(oproc)

Local _cQry		:= ""
Local _ntot := 0
Local _npos := 1

Default oproc := nil

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01730"/*cMsgId*/, "MGPE01730 - 3/3 - Atualizando dados de afastamentos, lendo dados de funcionários..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

_cQry := "SELECT R_E_C_N_O_ AS RECNO "
_cQry += "FROM " + RetSqlName("SRA") + " SRA "
_cQry += "WHERE RA_FILIAL = '" + xFilial("SRA") + "' "
_cQry += "  AND RA_CATFUNC IN ('M','E') "
_cQry += "  AND D_E_L_E_T_ = ' ' "

If Select ("TRBSRA") > 0
	TRBSRA->(DBCloseArea())
EndIf

dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBSRA" , .T., .F. )

DBSelectArea("TRBSRA")
Count to _ntot
TRBSRA->(DBGoTop())

If !TRBSRA->(Eof())
	While !TRBSRA->(Eof())
		If ValType(oproc) = "O"
			oproc:cCaption := ("3/3 - Atualizando dados de afastamentos - " + StrZero(_npos,9) + " de " + StrZero(_ntot,9))
			ProcessMessages()
		EndIf
		_npos++
		
		SRA->(DBGoTo(TRBSRA->RECNO))
		If !(Val(AllTrim(SRA->RA_PIS))) > 0 //Nao tem pis valido
			TRBSRA->(DBSkip())
			Loop
		EndIf
		
		//Verifica se existe cadastro do funcionário no Suricato
		_cQry := "select idcolab,situafas,dataafas,horaafas from SURICATO.tbcolab WHERE NUMEPIS = " + AllTrim(SRA->RA_PIS)
		_cQry += " and codimatr = " + AllTrim(Str(Val(SRA->RA_MAT))) + " AND CODIEMPR = " + AllTrim(Str(Val(SRA->RA_FILIAL)))

		If Select ("TRBCOL") > 0
			TRBCOL->(DBCloseArea())
		EndIf

		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBCOL" , .T., .F. )
		DBSelectArea("TRBCOL")

		If !TRBCOL->(Eof())
			If SRA->RA_SITFOLH == "D"  //Bloqueia demitidos se existirem no suricato
				//Ajusta afastamentos fechando todos em aberto e mantendo/gravando/ajustando o de demissão se necessário
				_cQry := "select idcolab,dataafas,horaafas,dataterm,horaterm,situafas,stathist from SURICATO.tbafast where idcolab = " + AllTrim(Str(TRBCOL->IDCOLAB))
				If Select ("TRBAFA") > 0
					TRBAFA->(DBCloseArea())
				EndIf

				dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBAFA" , .T., .F. )
				DBSelectArea("TRBAFA")
		
				_lafadem := .F.
		
				While  !TRBAFA->(Eof())
			
					//Registro de afastamento de demissao 
					If TRBAFA->SITUAFAS = 2  .And. !_lafadem
						If TRBAFA->DATAAFAS = SRA->RA_DEMISSA .And. TRBAFA->HORAAFAS = 1 .And. TRBAFA->STATHIST = 1;
									.And. TRBAFA->DATATERM = SToD("19001231")
							_lafadem := .T. //Registro de afastametnto por demissao ok
						Else
							//Atualiza registro para ficar ok
							_cQry := " UPDATE SURICATO.TBAFAST SET DATAAFAS = TO_DATE('" + DToS(SRA->RA_DEMISSA ) + "','YYYYMMDD'), "
							_cQry += " HORAAFAS = 1, "
							_cQry += " SITUAFAS = 2, "
							_cQry += " STATHIST = 1, "
							_cQry += " DATATERM = TO_DATE('19001231','YYYYMMDD'), "
							_cQry += " HORATERM = 1 "
							_cQry += " WHERE idcolab =  " + AllTrim(Str(TRBAFA->IDCOLAB)) 
							_cQry += " AND DATAAFAS = TO_DATE('" + AllTrim(DToS(TRBAFA->DATAAFAS)) + "','YYYYMMDD') "
							_cQry += " AND HORAAFAS =  " + AllTrim(Str(TRBAFA->HORAAFAS))
							_cQry += " AND SITUAFAS =  " + AllTrim(Str(TRBAFA->SITUAFAS))
							_cQry += " AND STATHIST =  " + AllTrim(Str(TRBAFA->STATHIST))
							
							_nres := TCSqlExec(_cQry)
							
							_lafadem := .T. //Registro de afastamento por demissao ok
							FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01731"/*cMsgId*/, "MGPE01731 - 3/3 - Atualizando dados de afastamentos - Atualizando bloqueio de demitido - "  + AllTrim(Str(TRBAFA->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
							
							RecLock("ZGV",.T.)
							ZGV->ZGV_FILIAL := SRA->RA_FILIAL
							ZGV->ZGV_MAT    := SRA->RA_MAT
							ZGV->ZGV_DATA   := Date()
							ZGV->ZGV_HORA   := Time()
							ZGV->ZGV_COMAND := _cQry
							ZGV->ZGV_RESULT := _nres
							ZGV->ZGV_COMENT := "3/3 - Atualizando dados de afastamentos - Atualizando bloqueio de demitido - "  + AllTrim(Str(TRBAFA->IDCOLAB))
							ZGV->(MSUnLock())
						EndIf
												
					ElseIf (TRBAFA->SITUAFAS = 4 .Or. TRBAFA->SITUAFAS = 3)
						//Ajusta registros ativos e com data final em branco ou posterior a data demissa
						If (TRBAFA->STATHIST = 1 .And. (TRBAFA->DATATERM >= SRA->RA_DEMISSA .Or. TRBAFA->DATATERM = SToD('19001231')) ) 
							_cQry := " UPDATE SURICATO.TBAFAST SET  "
							_cQry += " STATHIST = 2, "             		
							_cQry += " DATATERM = TO_DATE('" + DToS(SRA->RA_DEMISSA-1) + "','YYYYMMDD') "
							_cQry += " WHERE idcolab =  " + AllTrim(Str(TRBAFA->IDCOLAB)) 
							_cQry += " AND DATAAFAS = TO_DATE('" + AllTrim(DToS(TRBAFA->DATAAFAS)) + "','YYYYMMDD') "
							_cQry += " AND HORAAFAS =  " + AllTrim(Str(TRBAFA->HORAAFAS))
							_cQry += " AND SITUAFAS =  " + AllTrim(Str(TRBAFA->SITUAFAS))
							_cQry += " AND STATHIST =  " + AllTrim(Str(TRBAFA->STATHIST))
							
							_nres := TCSqlExec(_cQry)
							FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01732"/*cMsgId*/, "MGPE01732 - 3/3 - Atualizando dados de afastamentos - Limpando afastamentos de demitido - "  + AllTrim(Str(TRBAFA->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
							
							RecLock("ZGV",.T.)
							ZGV->ZGV_FILIAL := SRA->RA_FILIAL
							ZGV->ZGV_MAT    := SRA->RA_MAT
							ZGV->ZGV_DATA   := Date()
							ZGV->ZGV_HORA   := Time()
							ZGV->ZGV_COMAND := _cQry
							ZGV->ZGV_RESULT := _nres
							ZGV->ZGV_COMENT := "3/3 - Atualizando dados de afastamentos - Limpando afastamentos de demitido - "  + AllTrim(Str(TRBAFA->IDCOLAB))
							ZGV->(MSUnLock())
						EndIf							
					EndIf
					TRBAFA->(DBSkip())
				EndDo
			
				If !_lafadem  //Se não achou registro de afastamento de demissão inclui registro
				
					//Finaliza qualquer afastamento em aberto
					_cQry := " DELETE FROM  SURICATO.TBAFAST "						
					_cQry += " WHERE idcolab =  " + AllTrim(Str(TRBCOL->IDCOLAB)) 
							
					_nres := TCSqlExec(_cQry)
				
					_cQry := " Insert into SURICATO.TBAFAST "
					_cQry += " (IDCOLAB, DATAAFAS, HORAAFAS, DATATERM, HORATERM, " 
					_cQry += " SITUAFAS, STATHIST) "
					_cQry += " Values "
					_cQry += " (" + AllTrim(Str(TRBCOL->IDCOLAB)) +  ", TO_DATE('" + DToS(SRA->RA_DEMISSA) + "', 'YYYYMMDD'), 1, TO_DATE('31/12/1900', 'DD/MM/YYYY'), 1, " 
					_cQry += " 2, 1) "
					
					_nres := TCSqlExec(_cQry)
					FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01733"/*cMsgId*/, "MGPE01733 - 3/3 - Atualizando dados de afastamentos - Incluindo bloqueio de demitido - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
					
					RecLock("ZGV",.T.)
					ZGV->ZGV_FILIAL := SRA->RA_FILIAL
					ZGV->ZGV_MAT    := SRA->RA_MAT
					ZGV->ZGV_DATA   := Date()
					ZGV->ZGV_HORA   := Time()
					ZGV->ZGV_COMAND := _cQry
					ZGV->ZGV_RESULT := _nres
					ZGV->ZGV_COMENT := "3/3 - Atualizando dados de afastamentos - Incluindo bloqueio de demitido - "  + AllTrim(Str(TRBCOL->IDCOLAB))
					ZGV->(MSUnLock())
				EndIf
			
				//Verifica e atualiza se necessário a situação do colaborador
				If !(TRBCOL->SITUAFAS = 2 .And. TRBCOL->DATAAFAS = SRA->RA_DEMISSA .And. TRBCOL->HORAAFAS = 1)
					//Ajusta campos de afastamento do colaborador
					_cQry := " UPDATE suricato.TBCOLAB SET SITUAFAS = 2, " 
					_cQry += " DATAAFAS = TO_DATE('" + DToS(SRA->RA_DEMISSA) + "', 'YYYYMMDD'), "
					_cQry += " HORAAFAS = 1 "
					_cQry += " WHERE IDCOLAB = " + AllTrim(Str(TRBCOL->IDCOLAB))
					
					_nres := TCSqlExec(_cQry)
					FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01734"/*cMsgId*/, "MGPE01734 - 3/3 - Atualizando dados de afastamentos - Atualizando status de demitido - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
					
					RecLock("ZGV",.T.)
					ZGV->ZGV_FILIAL := SRA->RA_FILIAL
					ZGV->ZGV_MAT    := SRA->RA_MAT
					ZGV->ZGV_DATA   := Date()
					ZGV->ZGV_HORA   := Time()
					ZGV->ZGV_COMAND := _cQry
					ZGV->ZGV_RESULT := _nres
					ZGV->ZGV_COMENT := "3/3 - Atualizando dados de afastamentos - Atualizando status de demitido - "  + AllTrim(Str(TRBCOL->IDCOLAB))
					ZGV->(MSUnLock())
				EndIf
			Else
				//Verifica se afastamento ainda/já está ativo
				_cQry := " select r8_dataini,r8_datafim  "
				_cQry += " FROM " + RetSqlName("SR8") + " SR8 "
				_cQry += " where d_e_l_e_t_ = ' ' and (r8_datafim >= '" + DToS(date()) + "' or r8_datafim = ' ') and r8_dataini <= '" + DToS(date()) + "'"
				_cQry += " AND R8_FILIAL = '" + SRA->RA_FILIAL + "' AND R8_MAT = '" + SRA->RA_MAT + "'"

				If Select ("TRBSR8") > 0
					TRBSR8->(DBCloseArea())
				EndIf

				dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBSR8" , .T., .F. )
				DBSelectArea("TRBSR8")
					
				If TRBSR8->(Eof())  //Desbloqueia se necessário quando ativos
					//Ajusta afastamentos fechando todos em aberto e mantendo/gravando/ajustando o de afastamento atual se necessário
					_cQry := "select idcolab,dataafas,horaafas,dataterm,horaterm,situafas,stathist from SURICATO.tbafast where idcolab = " + AllTrim(Str(TRBCOL->IDCOLAB))
					_cQry += " and stathist = 1"

					If Select ("TRBAFAL") > 0
						TRBAFAL->(DBCloseArea())
					EndIf

					dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBAFAL" , .T., .F. )
					DBSelectArea("TRBAFAL")
	
					If TRBAFAL->(!Eof())
						//Finaliza qualquer afastamento em aberto
						_cQry := " DELETE FROM  SURICATO.TBAFAST "						
						_cQry += " WHERE idcolab =  " + AllTrim(Str(TRBCOL->IDCOLAB)) 
								
						_nres := TCSqlExec(_cQry)
						
						FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01735"/*cMsgId*/, "MGPE01735 - 3/3 - Atualizando dados de afastamentos - Atualizando afastamentos de ativo - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						
						RecLock("ZGV",.T.)
						ZGV->ZGV_FILIAL := SRA->RA_FILIAL
						ZGV->ZGV_MAT    := SRA->RA_MAT
						ZGV->ZGV_DATA   := Date()
						ZGV->ZGV_HORA   := Time()
						ZGV->ZGV_COMAND := _cQry
						ZGV->ZGV_RESULT := _nres
						ZGV->ZGV_COMENT := "3/3 - Atualizando dados de afastamentos - Atualizando afastamentos de ativo - "  + AllTrim(Str(TRBCOL->IDCOLAB))
						ZGV->(MSUnLock())					
					EndIf
	
					//Verifica e atualiza se necessário a situação do colaborador
					If !(TRBCOL->SITUAFAS = 1) .Or. DToS(TRBCOL->DATAAFAS) >= '19000101' .Or. TRBCOL->horaafas > 0

						//Ajusta campos de afastamento do colaborador
						_cQry := " UPDATE suricato.TBCOLAB SET SITUAFAS = 1, DATAAFAS = '', HORAAFAS = 0 " 
						_cQry += " WHERE IDCOLAB = " + AllTrim(Str(TRBCOL->IDCOLAB))
						
						_nres := TCSqlExec(_cQry)
						FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01736"/*cMsgId*/, "MGPE01736 - 3/3 - Atualizando dados de afastamentos - Atualizando status de ativo - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						
						RecLock("ZGV",.T.)
						ZGV->ZGV_FILIAL := SRA->RA_FILIAL
						ZGV->ZGV_MAT    := SRA->RA_MAT
						ZGV->ZGV_DATA   := Date()
						ZGV->ZGV_HORA   := Time()
						ZGV->ZGV_COMAND := _cQry
						ZGV->ZGV_RESULT := _nres
						ZGV->ZGV_COMENT := "3/3 - Atualizando dados de afastamentos - Atualizando status de ativo - "  + AllTrim(Str(TRBCOL->IDCOLAB))
						ZGV->(MSUnLock())
					EndIf
				Else
					//Ajusta afastamentos fechando todos em aberto e mantendo/gravando/ajustando o de afastamento atual se necessário
					_cQry := "select idcolab,dataafas,horaafas,dataterm,horaterm,situafas,stathist from SURICATO.tbafast where idcolab = " + AllTrim(Str(TRBCOL->IDCOLAB))

					If Select ("TRBAFA") > 0
						TRBAFA->(DBCloseArea())
					EndIf

					dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBAFA" , .T., .F. )
					DBSelectArea("TRBAFA")

					If SRA->RA_SITFOLH = 'A'
						_cSIT := "4"
						_CHORAS := "1"
						nDias:=1
					Else
						_cSIT := "3"
						_CHORAS := "420" 
						If SRA->RA_FILIAL = "01" 
							nDias:=2
						Else
							nDias:=1
						EndIf
					EndIf
					_lafaafa := .F.
			
					While  !TRBAFA->(Eof())
						//Registro de afastamento atual
						If (TRBAFA->SITUAFAS = 4 .Or. TRBAFA->SITUAFAS = 3)  .And. !_lafaafa
							If TRBAFA->DATAAFAS = SToD(TRBSR8->R8_DATAINI) .AND.;
								TRBAFA->HORAAFAS = IIf(SRA->RA_SITFOLH='A',1,420) .AND.;
								TRBAFA->STATHIST = 1 .AND.;
								(TRBAFA->DATATERM = SToD("19001231") .Or. TRBAFA->DATATERM = SToD(TRBSR8->R8_DATAFIM)+nDias)
								_lafaafa := .T. //Registro de afastametnto atual ok
							EndIf
						EndIf
						TRBAFA->(DBSkip())
					EndDo
			
					If !_lafaafa  //Se não achou registro de afastamento atual inclui registro
						//Finaliza qualquer afastamento em aberto
						_cQry := " DELETE FROM  SURICATO.TBAFAST "						
						_cQry += " WHERE idcolab =  " + AllTrim(Str(TRBCOL->IDCOLAB)) 
							
						_nres := TCSqlExec(_cQry)
				
						FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01737"/*cMsgId*/, "MGPE01737 - 3/3 - Atualizando dados de afastamentos - Incluindo afastamento de afastado - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						
						_cQry := " Insert into SURICATO.TBAFAST "
						_cQry += " (IDCOLAB, DATAAFAS, HORAAFAS, DATATERM, HORATERM, " 
						_cQry += " SITUAFAS, STATHIST) "
						_cQry += " Values "
						_cQry += " (" + AllTrim(Str(TRBCOL->IDCOLAB)) +  ", TO_DATE('" + AllTrim(TRBSR8->R8_DATAINI) + "', 'YYYYMMDD'), " +  _CHORAS 
					
						If SToD(TRBSR8->R8_DATAFIM) >= Date()
							_cQry += " , TO_DATE('" + DToS(SToD(TRBSR8->R8_DATAFIM)+nDias) + "', 'YYYYMMDD'),  1,  " + _CSIT + ", 1) "
						Else
							_cQry += " , TO_DATE('31/12/1900', 'DD/MM/YYYY'),  1,  " + _CSIT + ", 1) "
						EndIf
						
						_nres := TCSqlExec(_cQry)
						
						FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01738"/*cMsgId*/, "MGPE01738 - 3/3 - Atualizando dados de afastamentos - Disparando gatilhos do afastamento de afastado - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						
						//Zera data final de afastamento para ativar gatilhos de travamento da catraca
						_cQry := " UPDATE suricato.TBCOLAB SET SITUAFAS = " + _cSIT + ", " 
						_cQry += " DATAAFAS = TO_DATE('" + AllTrim(TRBSR8->R8_DATAINI) + "', 'YYYYMMDD'), "
						_cQry += " HORAAFAS = " + _choras + " "
						_cQry += " WHERE IDCOLAB = " + AllTrim(Str(TRBCOL->IDCOLAB))
					
						_nres := TCSqlExec(_cQry)
					
						RecLock("ZGV",.T.)
						ZGV->ZGV_FILIAL := SRA->RA_FILIAL
						ZGV->ZGV_MAT    := SRA->RA_MAT
						ZGV->ZGV_DATA   := Date()
						ZGV->ZGV_HORA   := Time()
						ZGV->ZGV_COMAND := _cQry
						ZGV->ZGV_RESULT := _nres
						ZGV->ZGV_COMENT := "3/3 - Atualizando dados de afastamentos - Incluindo afastamento de afastado - "  + AllTrim(Str(TRBCOL->IDCOLAB))
						ZGV->(MSUnLock())
					EndIf
					
					If SRA->RA_SITFOLH = 'A'
						_cSIT := "4"
						_CHORAS := "1"
					Else
						_cSIT := "3"
						_CHORAS := "420"
					EndIf
					
					//Verifica e atualiza se necessário a situação do colaborador
					If !(TRBCOL->SITUAFAS = Val(_cSIT) .And. TRBCOL->DATAAFAS = SToD(TRBSR8->R8_DATAINI) .And. TRBCOL->HORAAFAS = Val(_choras))
						//Ajusta campos de afastamento do colaborador
						_cQry := " UPDATE suricato.TBCOLAB SET SITUAFAS = " + _cSIT + ", " 
						_cQry += " DATAAFAS = TO_DATE('" + AllTrim(TRBSR8->R8_DATAINI) + "', 'YYYYMMDD'), "
						_cQry += " HORAAFAS = " + _choras + " "
						_cQry += " WHERE IDCOLAB = " + AllTrim(Str(TRBCOL->IDCOLAB))
					
						_nres := TCSqlExec(_cQry)
						
						FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01739"/*cMsgId*/, "MGPE01739 - 3/3 - Atualizando dados de afastamentos - Atualizando situação de afastado - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
						
						RecLock("ZGV",.T.)
						ZGV->ZGV_FILIAL := SRA->RA_FILIAL
						ZGV->ZGV_MAT    := SRA->RA_MAT
						ZGV->ZGV_DATA   := Date()
						ZGV->ZGV_HORA   := Time()
						ZGV->ZGV_COMAND := _cQry
						ZGV->ZGV_RESULT := _nres
						ZGV->ZGV_COMENT := "3/3 - Atualizando dados de afastamentos - Atualizando situação de afastado - "  + AllTrim(Str(TRBCOL->IDCOLAB))
						ZGV->(MSUnLock())					
					EndIf
				EndIf						
			EndIf
		EndIf
		TRBSRA->(DBSkip())
	EndDo
EndIf

Return

/*
===============================================================================================================================
Programa----------: MGPE017S
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 27/06/2017
Descrição---------: Função responsável por limpar o registro enviado ao suricato, caso o número do crachá seja alterado
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE017S()
Local _lRet 	:= .T.
Local _aArea	:= FWGetArea()

RecLock("SRA", .F.)
	Replace SRA->RA_I_SURIC With " "
SRA->(MSUnLock())

FWRestArea(_aArea)
Return(_lRet)

/*
===============================================================================================================================
Programa----------: SchedDef
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 25/05/2017
Descrição---------: DefiniçStaticStatic Function SchedDef para o novo Schedule
Uso---------------: No novo Schedule existe uma forma para a definição dos Perguntes para o botão Parâmetros, além do cadastro 
					das funções no SXD. Ao definir em sua rotinStaticatic Function SchedDef(), no cadastro da rotina no Agenda-
					mento do Schedule será verificado se existe estStaticic Function e irá executá-la habilitando o botão Parâ-
					metros com as informações do retorno da SchedDef(), deixando de verificar assim as informações na SXD. O 
					retorno da SchedDef deverá ser um array.
					Válido para Function e User Function, lembrando que uma vez definido a SchedDef, ao chamar a rotina o ambi-
					ente já está inicializado.
					Uma vez definido a Static Function SchedDef(), a rotina deixa de ser uma execução como processo especial, 
					ou seja, não se deve cadastrá-la no Agendamento passando parâmetros de linha. Ex: Funcao("A","B") ou 
					U_Funcao("A","B").
Parametros--------: aReturn[1] - Tipo: "P" - para Processo, "R" -  para Relatórios
					aReturn[2] - Nome do Pergunte, caso nao use passar ParamDef
					aReturn[3] - Alias  (para Relatório)
					aReturn[4] - Array de ordem  (para Relatório)
					aReturn[5] - Título (para Relatório)
Retorno-----------: aParam
===============================================================================================================================
*/
Static Function SchedDef()

Local aParam  := {}
Local aOrd := {}

aParam := { "P",;
            "PARAMDEFF",;
            "",;
            aOrd,;
            }

Return aParam

/*
===============================================================================================================================
Programa----------: MGPE0175
Autor-------------: Alex Wallauer
Data da Criacao---: 14/12/2017
Descrição---------: Função que bloqueia os cadastros de clientes dos funionarios demitidos
Parametros--------: oproc - objeto de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE0177(oproc)

Local _cQry,_nPos:=0
Local _nDias:=SuperGetMV("IT_DEMIDIA",.T.,0)
Local _cCodSA1:=""

_cQry := "SELECT SA1.R_E_C_N_O_ REC_SA1 "
_cQry += "FROM " + RetSqlName("SRA") + " SRA , "+ RetSqlName("SA1") + " SA1 "
_cQry += "WHERE SRA.RA_FILIAL = '" + xFilial("SRA") + "' "
_cQry += "  AND SRA.RA_CATFUNC = 'M' "
_cQry += "	AND SRA.RA_SITFOLH = 'D' "
_cQry += "	AND SRA.RA_DEMISSA >= '" + DToS(dDataBase-_nDias) + "' "
_cQry += "  AND SRA.D_E_L_E_T_ = ' ' "
_cQry += "  AND SA1.A1_CGC = RA_CIC "
_cQry += "  AND SA1.A1_MSBLQL = '2' "
_cQry += "  AND SA1.D_E_L_E_T_ = ' ' "
_cQry += "  AND NOT EXISTS (SELECT 'Y' FROM " + RetSqlName("SRA") + " SRA2
_cQry += "  	            WHERE SRA2.D_E_L_E_T_ = ' ' AND SRA2.RA_CIC = SRA.RA_CIC AND  SRA2.RA_SITFOLH <> 'D' ) "

If Select ("TRBSRA") > 0
	TRBSRA->(DBCloseArea())
EndIf

dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBSRA" , .T., .F. )

DBSelectArea("TRBSRA")
Count to _ntot
TRBSRA->(DBGoTop())

While !TRBSRA->(Eof())
	_nPos++
	If ValType(oproc) = "O"
		oproc:cCaption := ("Verificando Demitido - " + StrZero(_npos,9) + " de " + StrZero(_ntot,9))
		ProcessMessages()
	EndIf
	
	SA1->(DBGoTo(TRBSRA->REC_SA1))
	SA1->(RecLock("SA1",.F.))
	SA1->A1_MSBLQL:='1'
	SA1->(MSUnLock())
	_cCodSA1+=AllTrim(SA1->A1_COD)+", "
		
	TRBSRA->(DBSkip())
EndDo

TRBSRA->(DBCloseArea())
DBSelectArea("SRA")

If ValType(oproc) = "O"
   _cCodSA1:=LEFT(_cCodSA1,Len(_cCodSA1)-2)
   U_ITMsg(AllTrim(Str(_npos,9))+" registros atualizados: "+_cCodSA1,"CONCLUIDO",,2)
Else
   FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01740"/*cMsgId*/, "MGPE01740 - "+AllTrim(Str(_npos,9))+" registros de Demitido X clientes atualizados: "+_cCodSA1/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
EndIf
Return

/*
===============================================================================================================================
Programa----------: MGPE017W
Autor-------------: Josué Danich Prestes
Data da Criacao---: 12/09/2016
Descrição---------: WebService de execução do workflow
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
WSSTRUCT U_MGPE017G //Solicitação de execução do workflow
 
 WSDATA EXECUTA as STRING 
 
ENDWSSTRUCT


WSSERVICE U_MGPE017 DESCRIPTION "Exportação Suricato" NAMESPACE "http://10.3.0.57:4043/ws/U_MGPE017.apw"

	WSDATA U_EXECUTA AS U_MGPE017G
	WSDATA U_STATUS AS STRING
	
	WSMETHOD U_EXECWF DESCRIPTION "Workflow Pedidos x Carteiras"
 
ENDWSSERVICE 

WSMETHOD U_EXECWF WSRECEIVE U_EXECUTA WSSEND U_STATUS WSSERVICE U_MGPE017  

	startjob("U_MGPE017",getenvserver(),.F.)
	FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01741"/*cMsgId*/, "MGPE01741 - Iniciada  exportação Suricato"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	::U_STATUS := "Iniciada exportação Suricato"

Return .T.

/*
===============================================================================================================================
Programa----------: MGPE017Y
Autor-------------: Josué Danich Prestes
Data da Criacao---: 12/09/2016
Descrição---------: Chamada de workflow via webservice 
Parametros--------: Nenhum
Retorno-----------: Nenhum
*/
User Function MGPE017Y()

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01742"/*cMsgId*/, "MGPE01742 - Abrindo o ambiente..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

RPCSetType(3)
RpcSetEnv( "01" , '01' ,,,"COM", "SCHEDULE_SURICATO" , {'ZP1','SRA'} )
Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01743"/*cMsgId*/, "MGPE01743 - Solicitando Webservice de exportação Suricato"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

oWsdl := tWSDLManager():New() // Cria o objeto da WSDL.
oWsdl:nTimeout := 60          // Timeout de 10 segundos                                                               

oWsdl:ParseURL(SuperGetMV("IT_WEBLNK",.T.,"") + "U_MGPE017.apw?WSDL") // Manda para dentro do Objeto qual é o link do WSDL de integração Webservice. 
oWsdl:SetOperation("U_EXECWF") // Define qual operação será realizada.
				
//Monta XML
_cXML := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:u="http://10.3.0.55:4043/ws/U_MGPE017.apw">'
_cXML += '<soapenv:Header/><soapenv:Body><u:U_EXECWF><u:U_EXECUTA><u:EXECUTA>teste</u:EXECUTA></u:U_EXECUTA></u:U_EXECWF></soapenv:Body></soapenv:Envelope>'
	
// Envia para o servidor
_cOk := oWsdl:SendSoapMsg(_cXML) // Este comando pega o XML e envia para o servidor da RDC.  
            
Return _cOk

/*
===============================================================================================================================
Programa----------: MGPE17SA2
Autor-------------: Alex Wallauer
Data da Criacao---: 03/08/2018
Descrição---------: Fonte criado para atualizar dados Suricato somente com o SA2.
Parametros--------: _lweb - indica se está sendo chamado a partir do webservice
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE17SA2(_lweb)//chamado do shedule ou do wse service
Default _lweb := .F. 
Return U_MGPE017(_lweb,.T.)

/*
===============================================================================================================================
Programa----------: MGPE0171
Autor-------------: Alex Wallauer
Data da Criacao---: 03/08/2018
Descrição---------: Função responsável pela exportação dos dados de colaboradores com os dados dos motoristas ZL0
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE017M(oproc,_cMotoristas)

Local _cQry		:= ""
Local _ntot := 0
Local _npos := 1
Local _cAlias:= GetNextAlias()
Local _cFils := SuperGetMV("IT_FILSUR",.T.,"01;10")

DEFAULT oproc := NIL
DEFAULT _cMotoristas:=""

_cFils := FormatIn(AllTrim(_cFils),";")

FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01744"/*cMsgId*/, "MGPE01744 - 1/1 -Atualizando dados de motoristas, lendo dados de motoristas..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)

_cQry := "SELECT DISTINCT ZL0_CGC, MAX(R_E_C_N_O_) REC FROM " + RetSqlName("ZL0") + " ZL0 WHERE "
_cQry += " ZL0_ATIVO <> 'N' AND "
_cQry += " LENGTH(TRIM(ZL0_CGC)) = 11 AND  "
_cQry += " D_E_L_E_T_ = ' '  "
_cQry += " AND ZL0_FILIAL IN "+_cFils
If !Empty(_cMotoristas)
   _cQry += " AND ZL0_FILIAL||ZL0_COD IN "+_cMotoristas
ElseIf !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
   _cQry += " AND  ROWNUM <= 6 "//PARA TESTE TIRAR
EndIf
_cQry += " GROUP BY ZL0_CGC "

DBUSEAREA( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , _cAlias , .T., .F. )

COUNT TO _ntot
(_cAlias)->(DBGoTop())

If !(_cAlias)->(Eof())
	While !(_cAlias)->(Eof())     
		ZL0->(DBGoTo( (_cAlias)->REC ))
		_cMatSuricato:="9"+ZL0->ZL0_COD+ZL0->ZL0_FILIAL
		If ValType(oproc) = "O"
			oproc:cCaption := ("Atualizando dados de motoristas - " + StrZero(_npos,9) + " de " + StrZero(_ntot,9))
			ProcessMessages()
	   EndIf
	   _npos++
		
		If !Val(AllTrim(ZL0->ZL0_CGC)) > 0
			(_cAlias)->(DBSkip())
			Loop
		EndIf

		//Verifica se existe cadastro TBPESSOA no Suricato ****************************************************************
	    _cQryS := "SELECT IDPESSOA , NOMEPESS FROM SURICATO.TBPESSOA WHERE NOMEPESS = '"+AllTrim(ZL0->ZL0_NOME)+"'
	    If Select("TRBPES") > 0 ; TRBPES->(DBCloseArea()) ; EndIf
	    DBUSEAREA( .T. , "TOPCONN" , TcGenQry(,, _cQryS ) , "TRBPES" , .T., .F. )

	    If TRBPES->(Eof()) .And. Empty(TRBPES->IDPESSOA)
			//Inclui cadastro de TBPESSOA
		   _cQry := "INSERT INTO SURICATO.TBPESSOA (NOMEPESS) VALUES ('" + AllTrim(ZL0->ZL0_NOME) +  "')"
		   _nres := TCSqlExec(_cQry)

		   ZGV->(RecLock("ZGV",.T.))
		   ZGV->ZGV_FILIAL := ZL0->ZL0_FILIAL
		   ZGV->ZGV_MAT    := _cMatSuricato
		   ZGV->ZGV_DATA   := Date()
		   ZGV->ZGV_HORA   := Time()
		   ZGV->ZGV_COMAND := _cQry
		   ZGV->ZGV_RESULT := _nres
		   ZGV->ZGV_COMENT := "Atualizando dados de motoristas, incluindo motorista " +ZGV->ZGV_FILIAL+ "/" + ZGV->ZGV_MAT
		   ZGV->(MSUnLock())					
		   
			If Select ("TRBPES") > 0 ; TRBPES->(DBCloseArea()) ; EndIf
			dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQryS ) , "TRBPES" , .T., .F. )//Executa de novo pq pode ter incluido
		EndIf
        _cIDPESSOA:=AllTrim(Str(TRBPES->IDPESSOA))
		If Empty(_cIDPESSOA) 
			FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01745"/*cMsgId*/, "MGPE01745 - Atualizando dados de motoristas, FALHA ao incluir pessoa para MOTORISTA " + ZL0->ZL0_FILIAL + "/" + _cMatSuricato + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
			(_cAlias)->(DBSkip())
			Loop
		EndIf
		_nres:=0
		//Verifica se existe cadastro TBPESSOA no Suricato ****************************************************************
		
		//Verifica se existe cadastro do TBCOLAB no Suricato ***************************************************************
		_cQryC := "SELECT IDCOLAB,CODIMATR FROM SURICATO.TBCOLAB WHERE  "
		_cQryC += " CODIMATR = " + AllTrim(Str(Val( _cMatSuricato ))) + " AND CODIEMPR = "+AllTrim(Str(Val(ZL0->ZL0_FILIAL)))
		If Select("TRBCOL") > 0 ; TRBCOL->(DBCloseArea()) ; EndIf
		DBUSEAREA( .T. , "TOPCONN" , TcGenQry(,, _cQryC ) , "TRBCOL" , .T., .F. )

		//Se não existir inclui cadastro
		If TRBCOL->(Eof()) .And. Empty(TRBCOL->CODIMATR) 
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01746"/*cMsgId*/, "MGPE01746 - Atualizando dados de motoristas, incluindo pessoa para matricula " + ZL0->ZL0_FILIAL + "/" + _cMatSuricato + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
  			If _nres == 0 //Se incluiu cadastro de pessoa com sucesso
				FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01747"/*cMsgId*/, "MGPE01747 - Atualizando dados de motoristas, incluindo funcionário para MOTORISTA " + ZL0->ZL0_FILIAL + "/" + _cMatSuricato + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	    		_cIDPESSOA:=AllTrim(Str(TRBPES->IDPESSOA))
						
				_cQry :=  " INSERT INTO SURICATO.TBCOLAB (IDPESSOA,CODIEMPR,TIPOCOLA,CODIMATR,APELCOLA,NUMECPF,DATAADMI)"
				_cQry +=  " VALUES (" + _cIDPESSOA                      //IDPESSOA
				_cQry +=  " ,"+AllTrim(Str(Val(ZL0->ZL0_FILIAL)))       //CODIEMPR
				_cQry +=  " ,3 " //Parceiro                             //TIPOCOLA
				_cQry +=  " ," + _cMatSuricato                          //CODIMATR
				_cQry +=  " ,'"+AllTrim(SubStr(ZL0->ZL0_NOME,1,10))+"'" //APELCOLA
				_cQry +=  " ," + AllTrim(ZL0->ZL0_CGC)                  //NUMECPF
				_cQry +=  " ,TO_DATE('"+DToS(dDataBase)+"','YYYYMMDD') "//DATAADM
  				_cQry +=  " )"
				
				_nres := TCSqlExec(_cQry)
					
				ZGV->(RecLock("ZGV",.T.))
				ZGV->ZGV_FILIAL := ZL0->ZL0_FILIAL
				ZGV->ZGV_MAT    := _cMatSuricato
				ZGV->ZGV_DATA   := Date()
				ZGV->ZGV_HORA   := Time()
				ZGV->ZGV_COMAND := _cQry
				ZGV->ZGV_RESULT := _nres
				ZGV->ZGV_COMENT := "Atualizando dados de motoristas, incluindo motorista " +ZGV->ZGV_FILIAL+ "/" + ZGV->ZGV_MAT
				ZGV->(MSUnLock())										
					
				If _nres == 0
					FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01701"/*cMsgId*/, "MGPE01748 - Atualizando dados de motoristas, incluido com sucesso motorista para matricula " + ZL0->ZL0_FILIAL + "/" + _cMatSuricato + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				Else
					FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01749"/*cMsgId*/, "MGPE01749 - Atualizando dados de motoristas, FALHA ao incluir motorista para matricula " + ZL0->ZL0_FILIAL + "/" + _cMatSuricato + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
				EndIf
				
  			Else
				FWLogMsg("WARN"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01750"/*cMsgId*/, "MGPE01750 - Atualizando dados de motoristas, FALHA ao incluir pessoa para matricula " + ZL0->ZL0_FILIAL + "/" + _cMatSuricato + "..."/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
  			EndIf
  		
		//SE Já EXISTE CADASTRO VERIFICA SE PRECISA ATUALIZAR A TABELA  TBCOLAB
  		ElseIf TRBCOL->CODIMATR = Val( _cMatSuricato )
  	
			_cQry := " UPDATE SURICATO.TBCOLAB SET "
			_cQry += " APELCOLA = '"+AllTrim(SubStr(ZL0->ZL0_NOME,1,10))+"'" //APELCOLA
			_cQry += ",NUMECPF  = " +AllTrim(ZL0->ZL0_CGC)                   //NUMECPF
			_cQry += ",DATAADMI = TO_DATE('"+DToS(dDataBase)+"','YYYYMMDD') "//DATAADM
			_cQry += ",IDPESSOA = " + _cIDPESSOA					 	     //IDPESSOA
			_cQry += " WHERE  CODIMATR = " + AllTrim(Str(Val( _cMatSuricato ))) + " AND CODIEMPR = "+AllTrim(Str(Val(ZL0->ZL0_FILIAL)))
   		
			_nres := TCSqlExec(_cQry)
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01751"/*cMsgId*/, "MGPE01751 - Atualizando dados de motoristas, atualizando dados do motorista - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
								
			ZGV->(RecLock("ZGV",.T.))
			ZGV->ZGV_FILIAL := ZL0->ZL0_FILIAL
			ZGV->ZGV_MAT    := _cMatSuricato
			ZGV->ZGV_DATA   := Date()
			ZGV->ZGV_HORA   := Time()
			ZGV->ZGV_COMAND := _cQry
			ZGV->ZGV_RESULT := _nres
			ZGV->ZGV_COMENT := "Atualizando dados de motoristas, atualizando dados do motorista - "  + AllTrim(Str(TRBCOL->IDCOLAB))
			ZGV->(MSUnLock())
  		EndIf
		
		//Verifica se existe cadastro do TBCOLAB no Suricato ***************************************************************
	
		//verifica na tabela de colaboradores e se tiver verifica e atualiza tabela de acessos
		_cQry := "SELECT IDCOLAB,CODIMATR FROM SURICATO.TBCOLAB WHERE  "
		_cQry += " CODIMATR = " + AllTrim(Str(Val(_cMatSuricato))) + " AND CODIEMPR = "+AllTrim(Str(Val(ZL0->ZL0_FILIAL)))
		If Select ("TRBCOL") > 0 ; TRBCOL->(DBCloseArea()) ; EndIf
		DBUSEAREA( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBCOL" , .T., .F. )

		//se existe verifica se tem TABELA DE ACESSO *********************************************************
		If !TRBCOL->(Eof()) .And. !Empty(TRBCOL->IDCOLAB)
		
			_cQry := "SELECT IDCOLAB,VERIPERMACES,CODIPERM,PERMACESFERI,PERMACESSABA,PERMACESDOMI,PERMACESVISI,FAIXHORAACES,CONTANTIDUPL, "
        	_cQry += " COLARECEVISI,VERIAFAS,AUTOSAIDCOLA,AUTOHORAEXTR,COLAUTILVEIC,GRAUCONFBIOM,COLARETIBENE,DATAVALIASO,DATATREISEGU, "
        	_cQry += " DATAPENDPLAN,CODIPLAN,CONTCREDREFE,TEMPMINIALMO,TEMPMINIPERM,TOLECONTPERM,CONTBIOM,IDCOLABSUBS "
        	_cQry += " FROM SURICATO.TBACESSCOLAB WHERE IDCOLAB =  " + AllTrim(Str(TRBCOL->IDCOLAB))
 					
			If Select ("TRBACE") > 0 ; TRBACE->(DBCloseArea()) ; EndIf
			dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBACE" , .T., .F. )

			//se existe verifica se tem tabela de acesso
			If !TRBACE->(Eof()) .And. !Empty(TRBACE->IDCOLAB)
		
				//Verifica se precisa atualizar campos
				If !( TRBACE->VERIPERMACES = 'S' .AND.;
			 			TRBACE->CODIPERM     = 1   .AND.;
			  			TRBACE->PERMACESFERI = 1   .AND.;
			  			TRBACE->PERMACESSABA = 1   .AND.;
			  			TRBACE->PERMACESDOMI = 1   .AND.;
			  			TRBACE->PERMACESVISI = 1   .AND.;
			  			TRBACE->FAIXHORAACES = 0   .AND.;
			  			TRBACE->CONTANTIDUPL = 'S' .AND.;
			  			TRBACE->COLARECEVISI = 'S' .AND.;
			  			TRBACE->VERIAFAS     = 'S' .AND.;
  			  			TRBACE->AUTOSAIDCOLA = 'N' .AND.;
			  			TRBACE->AUTOHORAEXTR = 'N' .AND.;
			  			TRBACE->COLAUTILVEIC = 'N' .AND.;
			  			TRBACE->GRAUCONFBIO  = 0   .AND.;
			  			TRBACE->COLARETIBENE = 'S' .AND.;
			  			TRBACE->DATAVALIASO  = SToD("19001231") .AND.;
			  			TRBACE->DATATREISEGU = SToD("19001231") .AND.;
			  			TRBACE->DATAPENDPLAN = SToD("19001231") .AND.;
			  			TRBACE->CODIPLAN     = 0 .AND.; // TRBACE->CONTCREDREFE = 0 .AND.;//Cedito para refetorio
			  			TRBACE->TEMPMINIALMO = 0 .AND.;
			  			TRBACE->TEMPMINIPERM = 0 .AND.;
			  			TRBACE->TOLECONTPERM = 0 .AND.;
			  			TRBACE->CONTBIOM     = 1 .AND.; 
			  			TRBACE->IDCOLABSUBS  = 0 )
					  
					_cQry := " UPDATE SURICATO.TBACESSCOLAB set veripermaces = 'S' ,codiperm = 1,permacesferi = 1,permacessaba = 1,permacesdomi = 1,permacesvisi = 1,faixhoraaces = 0, "
					_cQry += " contantidupl = 'S',colarecevisi = 'S',veriafas = 'S',autosaidcola = 'N',autohoraextr='N',colautilveic='N',grauconfbiom=0,colaretibene='S', " 
					_cQry += " datavaliaso = TO_DATE('19001231','YYYYMMDD'),datatreisegu = TO_DATE('19001231','YYYYMMDD'),datapendplan = TO_DATE('19001231','YYYYMMDD'), "
					//_cQry += " codiplan = 0 ,contcredrefe = 0, tempminialmo = 0,tempminiperm = 0,tolecontperm = 0,contbiom = 1,idcolabsubs = 0 "
					_cQry += " codiplan = 0 , tempminialmo = 0,tempminiperm = 0,tolecontperm = 0,contbiom = 1,idcolabsubs = 0 "
					_cQry += " where idcolab =  " + AllTrim(Str(TRBCOL->IDCOLAB))
               
					_nres := TCSqlExec(_cQry)
					FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01752"/*cMsgId*/, "MGPE01752 - Atualizando dados de motoristas, atualizando tabela de acesso do motorista - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
								
					RecLock("ZGV",.T.)
			  		ZGV->ZGV_FILIAL := ZL0->ZL0_FILIAL
		  			ZGV->ZGV_MAT    := _cMatSuricato
		  			ZGV->ZGV_DATA   := Date()
		  			ZGV->ZGV_HORA   := Time()
		  			ZGV->ZGV_COMAND := _cQry
		  			ZGV->ZGV_RESULT := _nres
		  			ZGV->ZGV_COMENT := "Atualizando dados de motorista, atualizando tabela de acesso do motorista - "  + AllTrim(Str(TRBCOL->IDCOLAB))
		  			ZGV->(MSUnLock())		
				EndIf
			Else
				_cQry := " INSERT INTO SURICATO.TBACESSCOLAB (idcolab,veripermaces,codiperm,permacesferi,permacessaba,permacesdomi,permacesvisi,faixhoraaces,contantidupl, "
        		_cQry += " colarecevisi,veriafas,autosaidcola,autohoraextr,colautilveic,grauconfbiom,colaretibene,datavaliaso,datatreisegu, "
        		_cQry += " datapendplan,codiplan,contcredrefe,tempminialmo,tempminiperm,tolecontperm,contbiom,idcolabsubs) "
        		_cQry += " values (" + AllTrim(Str(TRBCOL->IDCOLAB)) + ",'S',1, 1,1,1,1,0,'S', "
        		_cQry += " 'S','S','N','N','N',0,'S',TO_DATE('19001231','YYYYMMDD'),TO_DATE('19001231','YYYYMMDD'), "
        		_cQry += " TO_DATE('19001231','YYYYMMDD'),0,0,0,0,0,1,0) "
                
        		_nres := TCSqlExec(_cQry)
        		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE017"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01753"/*cMsgId*/, "MGPE01753 - Atualizando dados de motorista, incluindo tabela de acesso do motorista - "  + AllTrim(Str(TRBCOL->IDCOLAB))/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
								
        		RecLock("ZGV",.T.)
           		ZGV->ZGV_FILIAL := ZL0->ZL0_FILIAL
           		ZGV->ZGV_MAT    := _cMatSuricato
           		ZGV->ZGV_DATA   := Date()
           		ZGV->ZGV_HORA   := Time()
           		ZGV->ZGV_COMAND := _cQry
           		ZGV->ZGV_RESULT := _nres
           		ZGV->ZGV_COMENT := "Atualizando dados de motorista, incluindo tabela de acesso do motorista - "  + AllTrim(Str(TRBCOL->IDCOLAB))
           		ZGV->(MSUnLock())		
   			EndIf
		EndIf  
		(_cAlias)->(DBSkip())
	EndDo
EndIf

(_cAlias)->(DBCloseArea())
	
Return

/*
===============================================================================================================================
Programa----------: MGPE0171
Autor-------------: Alex Wallauer
Data da Criacao---: 07/08/2018
Descrição---------: F3 dos dados dos motoristas ZL0
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE17F3()

Local _lRet			:= .F.
Local _aDados		:= {}
Local _cMVRET		:= ""//AllTrim( ReadVar() )
Local _cTitAux		:= ''
Local _cParDef		:= ''
Local _nTamChv		:= 0
Local _nMaxSel		:= 0
Local _cAlias       := GetNextAlias()
Local _cRetorno     := ""
Local _cQuery       := ""
Local _cFils        := SuperGetMV("IT_FILSUR",.T.,"01;10")
_cFils := FormatIn(AllTrim(_cFils),";")

_cQuery += " SELECT TRIM(ZL0_NOME) , R_E_C_N_O_ REC FROM "+RetSqlName('ZL0')+" ZL01 , ( "
_cQuery += " SELECT DISTINCT ZL0_CGC, MAX(R_E_C_N_O_) REC "
_cQuery += " FROM "+RetSqlName('ZL0')+" ZL0 "
_cQuery += " WHERE D_E_L_E_T_ = ' ' AND ZL0_ATIVO <> 'N' AND LENGTH(TRIM(ZL0_CGC)) = 11 "
_cQuery += " AND ZL0_FILIAL IN "+_cFils
_cQuery += " GROUP BY ZL0_CGC "
_cQuery += " ) ZL0AUX WHERE ZL01.R_E_C_N_O_ = ZL0AUX.REC ORDER BY TRIM(ZL0_NOME) "

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAlias , .F. , .T. )
COUNT TO _nMaxSel
_nTamChv := Len(ZL0->ZL0_FILIAL+ZL0->ZL0_COD)
_cMVRET  := Space(_nTamChv)
_cTitAux := "Motoristas"

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )
    ZL0->(DBGoTo((_cAlias)->REC))
	_cParDef += AllTrim( ZL0->ZL0_FILIAL+ZL0->ZL0_COD )
	aAdd( _aDados , AllTrim( ZL0->ZL0_NOME )+" CPF: "+AllTrim(ZL0->ZL0_CGC) )
	(_cAlias)->( DBSkip() )
EndDo
(_cAlias)->( DBCloseArea() )  

If !Empty( _aDados )
	_lRet    := .T.
	_cRetorno:= MGPE017C( _nTamChv , _nMaxSel , _cMVRET , _cTitAux , _cParDef , _aDados )
EndIf

If !Empty(_cRetorno)
   _cRetorno := FormatIn(AllTrim(_cRetorno),";")
EndIf

Return _cRetorno

/*
===============================================================================================================================
Programa--------: MGPE017C
Autor-----------: Alexandre Villar
Data da Criacao-: 22/03/2015
Descrição-------: Função que monta a tela para seleção de ítens via F3 de acordo com parâmetros recebidos
Parametros------: _nTamChv - Tamanho da Chave dos registros
----------------: _nMaxSel - Número máximo de registros que podem ser selecionados ao mesmo tempo
----------------: _cMVRET  - Nome da variável ou campo onde será gravado o retorno
----------------: _cTitAux - Título que será exibido na janela de seleção dos itens
----------------: _cParDef - String contendo os códigos dos itens que serão listados
----------------: _aDados  - Array contendo a descrição dos itens que serão listados
Retorno---------: _cRetAux - Lista de registros selecionados
===============================================================================================================================
*/
Static Function MGPE017C( _nTamChv , _nMaxSel , _cMVRET , _cTitAux , _cParDef , _aDados )
Local _cRetAux	:= _cMVRET
Local i

Private nTam       := _nTamChv //Tratamento para carregar variaveis da lista de opcoes
Private nMaxSelect := _nMaxSel //Define a quantidade máxima de itens que podem ser selecionados ao mesmo tempo
Private aCat       := aClone( _aDados )
Private MvPar      := ""
Private cTitulo    := _cTitAux
Private MvParDef   := _cParDef       

// Tratativa para carregar selecionados registros já marcados anteriormente
If Len( AllTrim( _cRetAux ) ) == 0
	MvPar		:= PadR( AllTrim( StrTran( _cRetAux , ";" , "" ) ) , Len(aCat) )
	_cRetAux	:= PadR( AllTrim( StrTran( _cRetAux , ";" , "" ) ) , Len(aCat) )
Else
	MvPar  := AllTrim( StrTran( _cRetAux , ";" , "/" ) )
EndIf

// Função que chama a tela de opções e só registra se usuário confirmar com "Ok"
If F_Opcoes( @MvPar , cTitulo , aCat , MvParDef , 12 , 49 , .F. , nTam , nMaxSelect )
	_cRetAux := ""
	For i := 1 To Len(MvPar) Step nTam
		If !( SubStr( MvPar , i , 1 ) $ " |*" )
			_cRetAux += SubStr( MvPar , i , nTam ) +";" //Separa os registros selecionados com ';'
		EndIf
	Next i
	_cRetAux := SubStr( _cRetAux , 1 , Len( _cRetAux ) - 1 ) //Trata para tirar o ultimo caracter
EndIf     

Return( _cRetAux )
