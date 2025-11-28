/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |06/11/2023| Chamado 45399. Incluída regra para RS020301 - 222
Lucas Borges  |23/04/2024| Chamado 47036. Incluída regra para RS020301 - 221
Lucas Borges  |04/10/2024| Chamado 47735. Incluídas regras para a filial 33
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MCTB004
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 21/06/2017
Descrição---------: Rotina para Contabilizar Apuração de ICMS - Chamado 20520
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function MCTB004

Private _cPerg	:= "MCTB004"
Private _oSelf	:= nil
Private _aSelFil	:= {}
Private _aButtons	:={}

ProcLogIni( _aButtons )

//============================================
//Cria interface principal
//============================================
tNewProcess():New(	"MCTB004"										,; // Função inicial
					"Contabilização Apuração ICMS"					,; // Descrição da Rotina
					{|_oSelf| MCTB04P(_oSelf) }						,; // Função do processamento
					"Rotina para geração da Contabilização da Apuração de ICMS",; // Descrição da Funcionalidade
					_cPerg											,; // Configuração dos Parâmetros
					{}												,; // Opções adicionais para o painel lateral
					.F.												,; // Define criação do Painel auxiliar
					0												,; // Tamanho do Painel Auxiliar
					''												,; // Descrição do Painel Auxiliar
					.T.												,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
					.T.									 ) // Opção para criação de apenas uma régua de processamento

Return

/*
===============================================================================================================================
Programa----------: MCTB004P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 08/06/2017
Descrição---------: Processa registros
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
Static Function MCTB04P(_oSelf)

Local _aStru	:= {}
Local _cAlias	:= "CTBAPUR"
Local _aArea 	:= FWGetArea()
Local _cArquivo := " "
Local _cLote  	:= AvKey(AllTrim(MV_PAR04),"CT2_LOTE")
Local _nTotal   := 0 
Local _dData	:= dDatabase
Local _lDigita  := (MV_PAR01==1)
Local _lAglut	:= (MV_PAR02==1)
Local _cOnLine	:= "N"
Local _cPadrao  := "Z01" //Código do Lançamento Padrão que será utilizado nessa rotina
Local _nHdlPrv, _nX := 0 
Local _aSelFil	:= {}
Local _cFilAnt	:= cFilAnt //Salva filial corrente
Local _aFlagCTB := {}
Local _lUsaFlag := GetNewPar("MV_CTBFLAG",.F.)
Local _aTotais  := {}
Local _oTempTable
Local _cQuery	:= ""

aAdd(_aTotais,{'004','010'})
aAdd(_aTotais,{0,0})

//Chama função que permitirá a seleção das filiais
If MV_PAR05 == 1
	_aSelFil := AdmGetFil(.F.,.F.,"CDH")
	If Empty(_aSelFil)
		aAdd(_aSelFil,cFilAnt)
	EndIf
Else
	aAdd(_aSelFil,cFilAnt)
EndIf

_oSelf:SetRegua1(Len(_aSelFil))

//----------------------------------------------------------------------
// Montra estrutura para ser usada na tabela temporária
//----------------------------------------------------------------------
aAdd(_aStru,{"CDH_FILIAL"	,"C",GetSX3Cache("CDH_FILIAL","X3_TAMANHO"),00})
aAdd(_aStru,{"CDH_DTFIM"	,"D",08,00})
aAdd(_aStru,{"CDH_LINHA"	,"C",03,00})
aAdd(_aStru,{"CDH_SUBITE"	,"C",10,00})
aAdd(_aStru,{"CDH_CODLAN"	,"C",22,00})
aAdd(_aStru,{"CDH_DESC"		,"C",50,00})
aAdd(_aStru,{"CDH_VALOR"	,"N",GetSX3Cache("CDH_VALOR","X3_TAMANHO"),GetSX3Cache("CDH_VALOR","X3_DECIMAL")})
aAdd(_aStru,{"RECNO"		,"N",08,00})

For _nX:=1 to Len(_aSelFil)

	cFilAnt := _aSelFil[_nX]
	ProcLogAtu("INICIO")
	_oSelf:IncRegua1("Processando Filial: "+cFilAnt)
	
	//Este função cria o cabeçalho da contabilização
	_nHdlPrv:= HeadProva(_cLote,_cPerg,AllTrim(cUserName),@_cArquivo) 
	
	If _nHdlPrv <= 0
	     Help(" ",,1,"A100NOPRV")
	     ProcLogAtu(_cPerg,"A100NOPRV",Ap5GetHelp("A100NOPRV"))
	     Return
	EndIf 

	//Levanta os itens da apuração	
	BeginSql Alias _cAlias
    SELECT CDH.CDH_FILIAL, CDH.CDH_DTFIM, CDH.CDH_LINHA, CDH.CDH_SUBITE, CDH.CDH_CODLAN, CDH.CDH_DESC, CDH.CDH_VALOR, CDH.R_E_C_N_O_
		  FROM %Table:CDH% CDH
		 WHERE CDH.D_E_L_E_T_ = ' '
		   AND CDH.CDH_FILIAL = %exp:_aSelFil[_nX]%
		   AND CDH.CDH_DTINI = %exp:SubStr( MV_PAR03 , 3 , 4 ) + SubStr( MV_PAR03 , 1 , 2 )+'01'%
		   AND CDH.CDH_PERIOD = '1'
		   AND CDH.CDH_VALOR > 0
	       AND CDH.CDH_LA <> 'S'
	       AND CDH.CDH_CODLAN <> ' '
    	   AND ((CDH.CDH_TIPOIP = 'IC' AND CDH.CDH_LINHA IN ('002','003','006','007','012')  )
    	   OR   (CDH.CDH_TIPOIP = 'ST' AND CDH.CDH_LINHA = '014' )
    	   OR   (CDH.CDH_LINHA = '900' AND CDH.CDH_CODLAN = 'RO050004'))
		   AND CDH.CDH_CODLAN <> 'RS10009906'
		   AND CDH.CDH_SEQUEN = (SELECT MAX(CDH_SEQUEN)
		                         FROM %Table:CDH% B
		                        WHERE B.D_E_L_E_T_ = ' '
		                          AND CDH.CDH_FILIAL = B.CDH_FILIAL
		                          AND CDH.CDH_DTINI = B.CDH_DTINI
		                          AND CDH.CDH_PERIOD = B.CDH_PERIOD)
		 ORDER BY  CDH.CDH_FILIAL, CDH.CDH_TIPOIP, CDH.CDH_LINHA, CDH.CDH_SUBITE
	EndSql
	
	_dData:= SToD((_cAlias)->CDH_DTFIM)

	While (_cAlias)->( !Eof() )
		If VerPadrao(_cPadrao)

			If _lUsaFlag
				aAdd(_aFlagCTB,{"CDH_LA","S","CDH",(_cAlias)->R_E_C_N_O_,0,0,0})
			EndIf
			
		     //gera linha da contabilização de acordo com as regras do LP passado
	     	_nTotal += DetProva(_nHdlPrv,_cPadrao,_cPerg,_cLote,,,,,,,,@_aFlagCTB,{"CDH",(_cAlias)->R_E_C_N_O_}) 
			
			//Atualiza Flag de Lançamento Contábil
			If _lUsaFlag
				aFlagCTB := {}  // Limpa o coteudo apos a efetivacao do lancamento
			Else 
				DBSelectArea("CDH")
				DBGoTo((_cAlias)->R_E_C_N_O_)
				RecLock("CDH")
				REPLACE CDH_LA With "S"
				MSUnLock( )
				CDH->(DBCloseArea())
			EndIf
			
	     EndIf
	     (_cAlias)->( DBSkip() )
	EndDo 

	(_cAlias)->(DBCloseArea())
  
	//Levanta os totais da apuração
	_cQuery:= "    SELECT CDH.CDH_FILIAL, "
	_cQuery+= "           CDH.CDH_DTFIM, "
	_cQuery+= "           CDH.CDH_LINHA, "
	_cQuery+= "           CDH.CDH_SUBITE, "
	_cQuery+= "           CDH.CDH_CODLAN, "
	_cQuery+= "           'ICMS APURACAO '||SubStr(CDH.CDH_DTFIM,5,2)||' '|| SubStr(CDH.CDH_DTFIM,1,4) CDH_DESC, "
	_cQuery+= "           CDH.CDH_VALOR, "
	_cQuery+= "           CDH.R_E_C_N_O_ RECNO"
	_cQuery+= "		  FROM " + RetSQLName("CDH") + " CDH "
	_cQuery+= "		 WHERE CDH.D_E_L_E_T_ = ' ' "
	_cQuery+= "		   AND CDH.CDH_FILIAL = '" + _aSelFil[_nX] +"' "
	_cQuery+= "		   AND CDH.CDH_DTINI = '" + SubStr( MV_PAR03 , 3 , 4 ) + SubStr( MV_PAR03 , 1 , 2 )+"01' "
	_cQuery+= "		   AND CDH.CDH_PERIOD = '1' "
	_cQuery+= "		   AND CDH.CDH_VALOR > 0 "
	_cQuery+= "		   AND CDH.CDH_TIPOIP = 'IC' "
	_cQuery+= "	       AND CDH.CDH_LA <> 'S' "
	_cQuery+= "    	   AND CDH.CDH_LINHA IN ('004','010') "
	_cQuery+= "		   AND CDH.CDH_SEQUEN = (SELECT MAX(CDH_SEQUEN) "
	_cQuery+= "		                         FROM  " + RetSQLName("CDH") + " B "
	_cQuery+= "		                        WHERE B.D_E_L_E_T_ = ' ' "
	_cQuery+= "		                          AND CDH.CDH_FILIAL = B.CDH_FILIAL "
	_cQuery+= "		                          AND CDH.CDH_DTINI = B.CDH_DTINI "
	_cQuery+= "		                          AND CDH.CDH_PERIOD = B.CDH_PERIOD) "

	//----------------------------------------------------------------------
	// Cria arquivo de dados temporário
	//----------------------------------------------------------------------
	_oTempTable := FWTemporaryTable():New( _cAlias, _aStru )
	//------------------
	//Criação da tabela
	//------------------
	_oTempTable:Create()
	SQLToTrb(_cQuery, _aStru, _cAlias)

	(_cAlias)->( DBGoTop() )
	While (_cAlias)->( !Eof() )
		_aTotais[2][aScan(_aTotais[1],(_cAlias)->CDH_LINHA)] :=(_cAlias)->CDH_VALOR
		RecLock(_cAlias,.F.)
		Replace (_cAlias)->CDH_VALOR With 0
		MSUnLock()
		(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBGoTop() )
	While (_cAlias)->( !Eof() ) 
		If VerPadrao(_cPadrao)
			If (_cAlias)-> CDH_LINHA == IIf(_aTotais[2][1] > _aTotais[2][2],_aTotais[1][1],_aTotais[1][2])
				If _lUsaFlag
					aAdd(_aFlagCTB,{"CDH_LA","S","CDH",(_cAlias)->RECNO,0,0,0})
				EndIf
				RecLock(_cAlias,.F.)
				Replace (_cAlias)->CDH_VALOR With IIf(_aTotais[2][1] > _aTotais[2][2],_aTotais[2][2],_aTotais[2][1])
				MSUnLock()
			EndIf
			
	     	//gera linha da contabilização de acordo com as regras do LP passado
	     	_nTotal += DetProva(_nHdlPrv,_cPadrao,_cPerg,_cLote,,,,,,,,@_aFlagCTB,{"CDH",(_cAlias)->RECNO}) 
			
			//Atualiza Flag de Lançamento Contábil
			If _lUsaFlag
				aFlagCTB := {}  // Limpa o coteudo apos a efetivacao do lancamento
			Else 
				DBSelectArea("CDH")
				DBGoTo((_cAlias)->RECNO)
				RecLock("CDH")
				REPLACE CDH_LA With "S"
				MSUnLock( )
				CDH->(DBCloseArea())
			EndIf
			
	    EndIf
		(_cAlias)->( DBSkip() )
	EndDo
	
	If _nTotal > 0
		//Esta função irá cria a finalização da contabilização.
		RodaProva(_nHdlPrv,_nTotal)
		// Envia para Lancamento Contabil. Essa e a funcao do quadro dos lancamentos.
		cA100Incl(_cArquivo,_nHdlPrv,3,_cLote,_lDigita,_lAglut,_cOnLine,_dData,,@_aFlagCTB)
	EndIf

	//---------------------------------
	//Exclui a tabela
	//---------------------------------
	(_cAlias)->(DBCloseArea())
	_oTempTable:Delete()
	
	If Select("TMP") > 0 //Fecho a tabela caso o cA100Incl tenha mantido ela aberta
		TMP->(DBCloseArea())
	EndIf
	ProcLogAtu("FIM")
Next _nX
	
cFilAnt := _cFilAnt //Restaura filial

FWRestArea(_aArea)
Return

/*
===============================================================================================================================
Programa----------: MCTB04CC
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 27/06/2017
Descrição---------: Retorna conta contábil
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function MCTB04CC(_cCod)

Local _aArea	:= FWGetArea()
Local _cRetorno	:= ''
//===========================================================================================
//Z01001CD - Apuração de ICMS - Débito
//===========================================================================================
If _cCod == 'Z01001CD'
	If AllTrim(CTBAPUR->CDH_CODLAN) $ 'GO40000029/GO000027/RS40000113'
		_cRetorno := '3301020063'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'GO010041/GO010026/GO010057/GO010004/GO010044'
		_cRetorno := '3299010022'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'GO020079/GO020083/GO020069/GO020124/GO020021/GO020125/GO10009029'
		If CTBAPUR->CDH_FILIAL == '01'
			_cRetorno := '1102070001'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'GO040007/GO040096'
		If CTBAPUR->CDH_FILIAL == '01'
			_cRetorno := '2101020004'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RJ140001'
		If CTBAPUR->CDH_FILIAL == '01'
			_cRetorno := '2101020065'
		ElseIf CTBAPUR->CDH_FILIAL == '40'
			_cRetorno := '2101020073'
		ElseIf CTBAPUR->CDH_FILIAL == '20'
			_cRetorno := '2101020054'
		ElseIf CTBAPUR->CDH_FILIAL == '23'
			_cRetorno := '2101020077'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS40001010'
		If CTBAPUR->CDH_FILIAL == '20'
			_cRetorno := '1102070011'
		ElseIf CTBAPUR->CDH_FILIAL == '23'
			_cRetorno := '1102070085'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS40000213'
		_cRetorno := '3301020063'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS000013/PA019999/PR019999'
		_cRetorno := '3105010026'
	ElseIf (AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS10000106/RS10009269/RS10009280/RS10009314/RS10009240/RS10009376/RS020100') ;
		.Or. (AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS020006' .And. '099' $ CTBAPUR->CDH_DESC);
		.Or. AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS020301'
		If CTBAPUR->CDH_FILIAL == '20'
			_cRetorno := '1102070052'
		ElseIf CTBAPUR->CDH_FILIAL == '23'
			_cRetorno := '1102070082'
		ElseIf CTBAPUR->CDH_FILIAL == '24'
			_cRetorno := '1102070084'
		ElseIf CTBAPUR->CDH_FILIAL == '25'
			_cRetorno := '1102070083'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS40000313'
		_cRetorno := '1102070073'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS40009913'
		If '001' $ CTBAPUR->CDH_DESC// Diferencial de Alíquota
			_cRetorno := '3301020063'
		ElseIf '003' $ CTBAPUR->CDH_DESC//Antecipação de ICMS
			_cRetorno := '1102070073'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'MG029999'
		If CTBAPUR->CDH_FILIAL == '04'
			_cRetorno := '1102070002'
		ElseIf CTBAPUR->CDH_FILIAL == '40'
			_cRetorno := '1102070075'
		End
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'MG019999'
		If CTBAPUR->CDH_FILIAL == '04'
			_cRetorno := '3299010022'
		ElseIf CTBAPUR->CDH_FILIAL == '40'
			_cRetorno := '3299130022'
		End
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'MG020004/MG10990002'
		If CTBAPUR->CDH_FILIAL == '40'
			_cRetorno := '1102070075'
		End
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'PA10000009'
		_cRetorno := '1102070039'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RO000008/RO40000001/RO40000002'
		_cRetorno := '3301020063'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RO010005/RO010008'
		_cRetorno := '3105010026'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RO10000003/RO10000006/RO10000007/RO020005/RO20000004/RO030002/RO020021/RO10000021/RO10000024/RO10000025/RO030001'
		If CTBAPUR->CDH_FILIAL == '10'
			_cRetorno := '1102070024'
		ElseIf CTBAPUR->CDH_FILIAL == '11'
			_cRetorno := '1102070036'
		ElseIf CTBAPUR->CDH_FILIAL == '1A'
			_cRetorno := '1102070005'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RO050004'
		_cRetorno := '3105010014'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RO010013'
		_cRetorno := '3105010026'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RO010017'
		_cRetorno := '3299040028'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'AM010001'
		_cRetorno := '3299980002'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'AM020003'
		_cRetorno := '1102070049'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'SP010399/SP40090207'
		If CTBAPUR->CDH_FILIAL == '90'
			_cRetorno := '3299980001'
		ElseIf CTBAPUR->CDH_FILIAL == '92'
			_cRetorno := '3301020063'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'SP000207'
		_cRetorno := '3301020063'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'SP020737/SP020799/SP10090718/SP10090762/SP030899'
		If CTBAPUR->CDH_FILIAL == '90'
			_cRetorno := '1102070040'
		ElseIf CTBAPUR->CDH_FILIAL == '92'
			_cRetorno := '1102070072'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'PR020037/PR020212/PR020039'
		_cRetorno := '1102070089'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'PR010023'
		_cRetorno := '3105010026'
	ElseIf AllTrim(CTBAPUR->CDH_LINHA) $ '004/010'
		If CTBAPUR->CDH_FILIAL == '01'
			_cRetorno := '2101020004'
		ElseIf CTBAPUR->CDH_FILIAL == '02'
			_cRetorno := '2101020018'
		ElseIf CTBAPUR->CDH_FILIAL == '04'
			_cRetorno := '2101020005'
		ElseIf CTBAPUR->CDH_FILIAL == '05'
			_cRetorno := '2101020007'
		ElseIf CTBAPUR->CDH_FILIAL == '06'
			_cRetorno := '2101020006'
		ElseIf CTBAPUR->CDH_FILIAL == '08'
			_cRetorno := '2101020072'
		ElseIf CTBAPUR->CDH_FILIAL == '09'
			_cRetorno := '2101020087'
		ElseIf CTBAPUR->CDH_FILIAL == '0A'
			_cRetorno := '2101020089'
		ElseIf CTBAPUR->CDH_FILIAL == '10'
			_cRetorno := '2101020019'
		ElseIf CTBAPUR->CDH_FILIAL == '11'
			_cRetorno := '2101020029'
		ElseIf CTBAPUR->CDH_FILIAL == '1A'
			_cRetorno := '2101020015'
		ElseIf CTBAPUR->CDH_FILIAL == '20'
			_cRetorno := '2101020053'
		ElseIf CTBAPUR->CDH_FILIAL == '23'
			_cRetorno := '2101020075'
		ElseIf CTBAPUR->CDH_FILIAL == '24'
			_cRetorno := '2101020085'
		ElseIf CTBAPUR->CDH_FILIAL == '25'
			_cRetorno := '2101020076'
		ElseIf CTBAPUR->CDH_FILIAL == '30'
			_cRetorno := '2101020034'
		ElseIf CTBAPUR->CDH_FILIAL == '32'
			_cRetorno := '2101020115'
		ElseIf CTBAPUR->CDH_FILIAL == '33'
			_cRetorno := '2101020118'
		ElseIf CTBAPUR->CDH_FILIAL == '40'
			_cRetorno := '2101020069'
		ElseIf CTBAPUR->CDH_FILIAL == '90'
			_cRetorno := '2101020035'
		ElseIf CTBAPUR->CDH_FILIAL == '91'
			_cRetorno := '2101020046'
		ElseIf CTBAPUR->CDH_FILIAL == '92'
			_cRetorno := '2101020066'
		ElseIf CTBAPUR->CDH_FILIAL == '93'
			_cRetorno := '2101020097'
		EndIf
	EndIf

//===========================================================================================
//Z01001CC - Apuração de ICMS - Crédito
//===========================================================================================
ElseIf _cCod == 'Z01001CC'
	If AllTrim(CTBAPUR->CDH_CODLAN) $ 'GO40000029/GO000027/GO010041/GO010026/GO010057/GO010004/GO010044'
		If CTBAPUR->CDH_FILIAL == '01'
			_cRetorno := '2101020004'
		ElseIf CTBAPUR->CDH_FILIAL == '02'
			_cRetorno := '2101020018'
		ElseIf CTBAPUR->CDH_FILIAL == '05'
			_cRetorno := '2101020007'
		ElseIf CTBAPUR->CDH_FILIAL == '06'
			_cRetorno := '2101020006'
		ElseIf CTBAPUR->CDH_FILIAL == '08'
			_cRetorno := '2101020072'
		ElseIf CTBAPUR->CDH_FILIAL == '09'
			_cRetorno := '2101020087'
		ElseIf CTBAPUR->CDH_FILIAL == '0A'
			_cRetorno := '2101020089'
		ElseIf CTBAPUR->CDH_FILIAL == '0B'
			_cRetorno := '2101020091'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'GO020079/GO020083/MG020004/MG029999/RO020021/SP020799/SP10090718/SP10090762/SP030899'
		If CTBAPUR->CDH_FILIAL == '04'
			_cRetorno := '1102070010'
		ElseIf CTBAPUR->CDH_FILIAL == '90' .And. AllTrim(CTBAPUR->CDH_CODLAN) $ 'SP10090762'
			_cRetorno := '3105010021'
		ElseIf CTBAPUR->CDH_FILIAL == '90' .And. AllTrim(CTBAPUR->CDH_CODLAN) $ 'SP10090718SP030899'
			_cRetorno := '3299990001'
		ElseIf !AllTrim(CTBAPUR->CDH_CODLAN) $ 'SP10090762/SP030899'
			_cRetorno := '3301020050'
		End
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'GO020069'
		If CTBAPUR->CDH_FILIAL == '01'
			_cRetorno := '1102070015'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'GO020124/GO020021/GO020125'
		_cRetorno := '3105010008'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'GO040007'
		_cRetorno := '2203010001'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'GO040096'
		If CTBAPUR->CDH_FILIAL == '01'
			_cRetorno := '1102070081'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RJ140001'
		_cRetorno := '2101020068'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'GO10009029'
		_cRetorno := '3299010015'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS10000106'
		If CTBAPUR->CDH_FILIAL == '20'
			_cRetorno := '1102070073'
		ElseIf CTBAPUR->CDH_FILIAL == '23'
			_cRetorno := '3301010015'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS10009269/RS10009314/RS10009240/RS10009376';
	 .Or. (AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS020301' .And.('114' $ CTBAPUR->CDH_DESC .Or. '185' $ CTBAPUR->CDH_DESC .Or. '69' $ CTBAPUR->CDH_DESC .Or. '176' $ CTBAPUR->CDH_DESC .Or. '40' $ CTBAPUR->CDH_DESC .Or. '221' $ CTBAPUR->CDH_DESC .Or. '222' $ CTBAPUR->CDH_DESC))
		_cRetorno := '3105010016'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS10009280' .Or. (AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS020301' .And.'80' $ CTBAPUR->CDH_DESC)
		_cRetorno := '2203010004'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS020301' .And. '161' $ CTBAPUR->CDH_DESC
		_cRetorno := '1102070076'
	ElseIf (AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS020006' .And. '099' $ CTBAPUR->CDH_DESC) .Or. AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS020100'
			If CTBAPUR->CDH_FILIAL == '20'
				_cRetorno := '3299080033'
			ElseIf CTBAPUR->CDH_FILIAL $ '23/24/25'
				_cRetorno := '3299180033'
			EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS40000213/RS40000113/RS40001010/RS000013/RS40000313' .Or.;
         (AllTrim(CTBAPUR->CDH_CODLAN) $ 'RS40009913' .And. ('001' $ CTBAPUR->CDH_DESC .Or. '003' $ CTBAPUR->CDH_DESC))//001-Diferencial de Alíquota/003-Antecipação de ICMS)
		If CTBAPUR->CDH_FILIAL == '20'
			_cRetorno := '2101020053'
		ElseIf CTBAPUR->CDH_FILIAL == '23'
			_cRetorno := '2101020075'
		ElseIf CTBAPUR->CDH_FILIAL == '24'
			_cRetorno := '2101020085'
		ElseIf CTBAPUR->CDH_FILIAL == '25'
			_cRetorno := '2101020076'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'MG019999'
		If CTBAPUR->CDH_FILIAL == '04'
			_cRetorno := '2101020005'
		ElseIf CTBAPUR->CDH_FILIAL == '40'
			_cRetorno := '2101020069'
		End
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'MG10990002'
		If CTBAPUR->CDH_FILIAL == '40'
			_cRetorno := '3105010022'
		End
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'PA10000009'
			_cRetorno := '3105010017'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'PA019999'
		_cRetorno := '2101020034'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RO000008/RO40000001/RO40000002/RO010005/RO010008'
		If CTBAPUR->CDH_FILIAL == '10'
			_cRetorno := '2101020019'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RO10000003/RO10000006/RO10000007/RO10000021/RO10000024/RO10000025'
		_cRetorno := '3105010012'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RO020005'
		_cRetorno := '3103010002'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RO20000004/RO030002/RO030001'
		_cRetorno := '3299030018'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RO050004'
		_cRetorno := '2101020020'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'RO010013/RO010017'
		_cRetorno := '2101020019'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'AM010001'
		_cRetorno := '2101020046'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'AM020003'
		_cRetorno := '1102070050'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'SP020737'
		_cRetorno := '3105010021'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'SP010399/SP000207/SP40090207'
		If CTBAPUR->CDH_FILIAL == '90'
			_cRetorno := '2101020035'
		ElseIf CTBAPUR->CDH_FILIAL == '92'
			_cRetorno := '2101020066'
		EndIf
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'PR020037/PR020039'
		_cRetorno := '3105010029'
	ElseIf AllTrim(CTBAPUR->CDH_CODLAN) $ 'PR010023/PR019999/PR020212'
		_cRetorno := '2101020097'
	ElseIf AllTrim(CTBAPUR->CDH_LINHA) $ '004/010'
		If CTBAPUR->CDH_FILIAL == '01'
			_cRetorno := '1102070001'
		ElseIf CTBAPUR->CDH_FILIAL == '02'
			_cRetorno := '1102070027'
		ElseIf CTBAPUR->CDH_FILIAL == '04'
			_cRetorno := '1102070002'
		ElseIf CTBAPUR->CDH_FILIAL == '05'
			_cRetorno := '1102070004'
		ElseIf CTBAPUR->CDH_FILIAL == '06'
			_cRetorno := '1102070003'
		ElseIf CTBAPUR->CDH_FILIAL == '08'
			_cRetorno := '1102070080'
		ElseIf CTBAPUR->CDH_FILIAL == '09'
			_cRetorno := '1102070080'
		ElseIf CTBAPUR->CDH_FILIAL == '0A'
			_cRetorno := '1102070087'
		ElseIf CTBAPUR->CDH_FILIAL == '10'
			_cRetorno := '1102070024'
		ElseIf CTBAPUR->CDH_FILIAL == '11'
			_cRetorno := '1102070036'
		ElseIf CTBAPUR->CDH_FILIAL == '1A'
			_cRetorno := '1102070005'
		ElseIf CTBAPUR->CDH_FILIAL == '20'
			_cRetorno := '1102070052'
		ElseIf CTBAPUR->CDH_FILIAL == '23'
			_cRetorno := '1102070082'
		ElseIf CTBAPUR->CDH_FILIAL == '24'
			_cRetorno := '1102070084'
		ElseIf CTBAPUR->CDH_FILIAL == '25'
			_cRetorno := '1102070083'
		ElseIf CTBAPUR->CDH_FILIAL == '30'
			_cRetorno := '1102070039'
		ElseIf CTBAPUR->CDH_FILIAL == '32'
			_cRetorno := '1102070106'
		ElseIf CTBAPUR->CDH_FILIAL == '33'
			_cRetorno := '1102070107'
		ElseIf CTBAPUR->CDH_FILIAL == '40'
			_cRetorno := '1102070075'
		ElseIf CTBAPUR->CDH_FILIAL == '90'
			_cRetorno := '1102070040'
		ElseIf CTBAPUR->CDH_FILIAL == '91'
			_cRetorno := '1102070049'
		ElseIf CTBAPUR->CDH_FILIAL == '92'
			_cRetorno := '1102070072'
		ElseIf CTBAPUR->CDH_FILIAL == '93'
			_cRetorno := '1102070089'
		EndIf
	EndIf
EndIf

//Retorna sempre uma conta genérica quando não identificar a conta correta
If Empty(_cRetorno)
	_cRetorno := "1101010020"
EndIf 

FWRestArea(_aArea)

Return (_cRetorno)

/*
===============================================================================================================================
Programa----------: MCTB04VL
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 21/06/2017
Descrição---------: Valida data informada nos parâmetros
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function MCTB04VL()

Local _lRet:= .T. 

Private _cMesAnoCtab := MV_PAR03
Private _aMesValid:= { "01","02","03","04","05","06","07","08","09","10","11","12" }

//Verifica se a competencia informada e invalida e exibe uma mensagem de alerta
If aScan( _aMesValid, Subst( _cMesAnoCtab, 1 , 2 ) ) == 0 
	_lRet := .F.
	Help(NIL, NIL, "MCTB00401", NIL, "Data informada " + _cMesAnoCtab + " inválida!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Corrija a informação!"})//Formato Invalido
EndIf 

Return (_lRet)
