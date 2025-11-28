/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |03/04/2024| Chamado 46819. Inclusão do total da apuração.
Lucas Borges  |18/04/2024| Chamado 46993. Corrigida data do movimento quando existe apenas o totalizador.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MCTB005
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 20/03/2024
Descrição---------: Rotina para Contabilizar Apuração de IPI - Chamado 46677
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function MCTB005

Private _cPerg	:= "MCTB005"
Private _oSelf	:= nil
Private _aSelFil	:= {}
Private _aButtons	:={}

ProcLogIni( _aButtons )

//============================================
//Cria interface principal
//============================================
tNewProcess():New(	"MCTB005"										,; // Função inicial
					"Contabilização Apuração IPI"					,; // Descrição da Rotina
					{|_oSelf| MCTB05P(_oSelf) }						,; // Função do processamento
					"Rotina para geração da Contabilização da Apuração de IPI",; // Descrição da Funcionalidade
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
Programa----------: MCTB05P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 20/03/2024
Descrição---------: Processa registros
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
Static Function MCTB05P(_oSelf)

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
Local _cPadrao  := "Z03" //Código do Lançamento Padrão que será utilizado nessa rotina
Local _nHdlPrv, _nX := 0 
Local _aSelFil	:= {}
Local _cFilAnt	:= cFilAnt //Salva filial corrente
Local _aFlagCTB := {}
Local _lUsaFlag := GetNewPar("MV_CTBFLAG",.F.)
Local _aTotais  := {}
Local _oTempTable
Local _cQuery	:= ""

aAdd(_aTotais,{'014','015'})
aAdd(_aTotais,{0,0})

//Chama função que permitirá a seleção das filiais
If MV_PAR05 == 1
	_aSelFil := AdmGetFil(.F.,.F.,"CDP")
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
aAdd(_aStru,{"CDP_FILIAL"	,"C",GetSX3Cache("CDP_FILIAL","X3_TAMANHO"),00})
aAdd(_aStru,{"CDP_DTFIM"	,"D",08,00})
aAdd(_aStru,{"CDP_LINHA"	,"C",03,00})
aAdd(_aStru,{"CDP_CODLAN"	,"C",22,00})
aAdd(_aStru,{"CDP_DESC"		,"C",50,00})
aAdd(_aStru,{"CDP_VALOR"	,"N",GetSX3Cache("CDP_VALOR","X3_TAMANHO"),GetSX3Cache("CDP_VALOR","X3_DECIMAL")})
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
    SELECT CDP.CDP_FILIAL, CDP.CDP_DTFIM, CDP.CDP_LINHA, CDP.CDP_CODLAN, CDP.CDP_DESC, CDP.CDP_VALOR, CDP.R_E_C_N_O_
		  FROM %Table:CDP% CDP
		 WHERE CDP.D_E_L_E_T_ = ' '
		   AND CDP.CDP_FILIAL = %exp:_aSelFil[_nX]%
		   AND CDP.CDP_DTINI = %exp:SubStr( MV_PAR03 , 3 , 4 ) + SubStr( MV_PAR03 , 1 , 2 )+'01'%
		   AND CDP.CDP_PERIOD = '1'
		   AND CDP.CDP_VALOR > 0
	       /*AND CDP.CDP_LA <> 'S'*/
	       AND CDP.CDP_CODLAN <> ' '
    	   AND (CDP.CDP_TIPOIP = 'IP' AND CDP.CDP_LINHA IN ('005')  )
		   AND CDP.CDP_SEQUEN = (SELECT MAX(CDP_SEQUEN)
		                         FROM %Table:CDP% B
		                        WHERE B.D_E_L_E_T_ = ' '
		                          AND CDP.CDP_FILIAL = B.CDP_FILIAL
		                          AND CDP.CDP_DTINI = B.CDP_DTINI
		                          AND CDP.CDP_PERIOD = B.CDP_PERIOD)
		 ORDER BY  CDP.CDP_FILIAL, CDP.CDP_TIPOIP, CDP.CDP_LINHA
	EndSql
	
	_dData:= SToD((_cAlias)->CDP_DTFIM)

	While (_cAlias)->( !Eof() )
		If VerPadrao(_cPadrao)

			If _lUsaFlag
				aAdd(_aFlagCTB,{"CDP_LA","S","CDP",(_cAlias)->R_E_C_N_O_,0,0,0})
			EndIf
			
		     //gera linha da contabilização de acordo com as regras do LP passado
	     	_nTotal += DetProva(_nHdlPrv,_cPadrao,_cPerg,_cLote,,,,,,,,@_aFlagCTB,{"CDP",(_cAlias)->R_E_C_N_O_}) 
			
			//Atualiza Flag de Lançamento Contábil
			If _lUsaFlag
				aFlagCTB := {}  // Limpa o coteudo apos a efetivacao do lancamento
			Else 
				DBSelectArea("CDP")
				DBGoTo((_cAlias)->R_E_C_N_O_)
				RecLock("CDP")
				REPLACE CDP_LA With "S"
				MSUnLock( )
				CDP->(DBCloseArea())
			EndIf
			
	     EndIf
	     (_cAlias)->( DBSkip() )
	EndDo 

	(_cAlias)->(DBCloseArea())
  	
	//Levanta os totais da apuração
	_cQuery:= "    SELECT CDP.CDP_FILIAL, "
	_cQuery+= "           CDP.CDP_DTFIM, "
	_cQuery+= "           CDP.CDP_LINHA, "
	_cQuery+= "           CDP.CDP_CODLAN, "
	_cQuery+= "           'IPI APURACAO '||SubStr(CDP.CDP_DTFIM,5,2)||' '|| SubStr(CDP.CDP_DTFIM,1,4) CDP_DESC, "
	_cQuery+= "           CDP.CDP_VALOR, "
	_cQuery+= "           CDP.R_E_C_N_O_ RECNO"
	_cQuery+= "		  FROM " + RetSQLName("CDP") + " CDP "
	_cQuery+= "		 WHERE CDP.D_E_L_E_T_ = ' ' "
	_cQuery+= "		   AND CDP.CDP_FILIAL = '" + _aSelFil[_nX] +"' "
	_cQuery+= "		   AND CDP.CDP_DTINI = '" + SubStr( MV_PAR03 , 3 , 4 ) + SubStr( MV_PAR03 , 1 , 2 )+"01' "
	_cQuery+= "		   AND CDP.CDP_PERIOD = '1' "
	_cQuery+= "		   AND CDP.CDP_VALOR > 0 "
	_cQuery+= "		   AND CDP.CDP_TIPOIP = 'IP' "
	//_cQuery+= "	       AND CDP.CDP_LA <> 'S' "
	_cQuery+= "    	   AND CDP.CDP_LINHA IN ('014','015') "
	_cQuery+= "		   AND CDP.CDP_SEQUEN = (SELECT MAX(CDP_SEQUEN) "
	_cQuery+= "		                         FROM  " + RetSQLName("CDP") + " B "
	_cQuery+= "		                        WHERE B.D_E_L_E_T_ = ' ' "
	_cQuery+= "		                          AND CDP.CDP_FILIAL = B.CDP_FILIAL "
	_cQuery+= "		                          AND CDP.CDP_DTINI = B.CDP_DTINI "
	_cQuery+= "		                          AND CDP.CDP_PERIOD = B.CDP_PERIOD) "

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
	_dData:= (_cAlias)->CDP_DTFIM

	While (_cAlias)->( !Eof() )
		_aTotais[2][aScan(_aTotais[1],(_cAlias)->CDP_LINHA)] :=(_cAlias)->CDP_VALOR
		RecLock(_cAlias,.F.)
		Replace (_cAlias)->CDP_VALOR With 0
		MSUnLock()
		(_cAlias)->( DBSkip() )
	EndDo
	
	(_cAlias)->( DBGoTop() )
	While (_cAlias)->( !Eof() ) 
		If VerPadrao(_cPadrao)
			If (_cAlias)-> CDP_LINHA == IIf(_aTotais[2][1] < _aTotais[2][2],_aTotais[1][1],_aTotais[1][2])
				If _lUsaFlag
					aAdd(_aFlagCTB,{"CDP_LA","S","CDP",(_cAlias)->RECNO,0,0,0})
				EndIf
				RecLock(_cAlias,.F.)
				Replace (_cAlias)->CDP_VALOR With IIf(_aTotais[2][1] > _aTotais[2][2],_aTotais[2][2],_aTotais[2][1])
				MSUnLock()
			EndIf
			
	     	//gera linha da contabilização de acordo com as regras do LP passado
	     	_nTotal += DetProva(_nHdlPrv,_cPadrao,_cPerg,_cLote,,,,,,,,@_aFlagCTB,{"CDP",(_cAlias)->RECNO}) 
			
			//Atualiza Flag de Lançamento Contábil
			If _lUsaFlag
				aFlagCTB := {}  // Limpa o coteudo apos a efetivacao do lancamento
			Else 
				DBSelectArea("CDP")
				DBGoTo((_cAlias)->RECNO)
				RecLock("CDP")
				REPLACE CDP_LA With "S"
				MSUnLock( )
				CDP->(DBCloseArea())
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
Programa----------: MCTB05CC
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 20/03/2024
Descrição---------: Retorna conta contábil
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function MCTB05CC(_cCod)

Local _aArea	:= FWGetArea()
Local _cRetorno	:= ''
//===========================================================================================
//Z03001CD - Apuração de IPI - Débito
//Z03001CC - Apuração de IPI - Crédito
//===========================================================================================
If (_cCod == 'Z03001CD' .And. AllTrim(CTBAPUR->CDP_CODLAN) $ '001')
	If CTBAPUR->CDP_FILIAL $ '01/02/03/04/05/06/07/08/09/0A/0B'
		_cRetorno := '3299020046' //IPI A RECUPERAR MATRIZ
	ElseIf CTBAPUR->CDP_FILIAL $ '10/11/12/13/14/15/16/17/18/19/1A/1B/1C'
		_cRetorno := '3299040046'
	ElseIf CTBAPUR->CDP_FILIAL $ '20/21/22/24/25'
		_cRetorno := '3299080046'
	ElseIf CTBAPUR->CDP_FILIAL == '23'
		_cRetorno := '3299180046'
	ElseIf CTBAPUR->CDP_FILIAL $ '30/31'
		_cRetorno := '3299060046'
	ElseIf CTBAPUR->CDP_FILIAL == '40'
		_cRetorno := '3299140046'
	ElseIf CTBAPUR->CDP_FILIAL == '90'
		_cRetorno := '3299160046'
	ElseIf CTBAPUR->CDP_FILIAL == '93'
		_cRetorno := '3299200046'
	EndIf
ElseIf (_cCod == 'Z03001CD' .And. CTBAPUR->CDP_LINHA $ '014') .Or. (_cCod == 'Z03001CC' .And. CTBAPUR->CDP_LINHA $ '015')
	If CTBAPUR->CDP_FILIAL $ '01/02/03/04/05/06/07/08/09/0A/0B'
		_cRetorno := '2101020400' //IPI A RECOLHER MATRIZ
	ElseIf CTBAPUR->CDP_FILIAL $ '10/11/12/13/14/15/16/17/18/19/1A/1B/1C'
		_cRetorno := '2101020401'
	ElseIf CTBAPUR->CDP_FILIAL $ '20/21/22/24/25'
		_cRetorno := '2101020402'
	ElseIf CTBAPUR->CDP_FILIAL == '23'
		_cRetorno := '2101020403'
	ElseIf CTBAPUR->CDP_FILIAL == '30'
		_cRetorno := '2101020410'
	ElseIf CTBAPUR->CDP_FILIAL == '40'
		_cRetorno := '2101020404'
	ElseIf CTBAPUR->CDP_FILIAL == '90'
		_cRetorno := '2101020405'
	ElseIf CTBAPUR->CDP_FILIAL == '93'
		_cRetorno := '2101020406'
	ElseIf CTBAPUR->CDP_FILIAL == '95'
		_cRetorno := '2101020407'
	ElseIf CTBAPUR->CDP_FILIAL == '96'
		_cRetorno := '2101020408'
	ElseIf CTBAPUR->CDP_FILIAL == '98'
		_cRetorno := '2101020409'
	EndIf
ElseIf (_cCod == 'Z03001CC' .And. (AllTrim(CTBAPUR->CDP_CODLAN) $ '001' .Or. CTBAPUR->CDP_LINHA $ '014')) .Or. (_cCod == 'Z03001CD' .And. CTBAPUR->CDP_LINHA $ '015')
	If CTBAPUR->CDP_FILIAL $ '01/02/03/04/05/06/07/08/09/0A/0B'
		_cRetorno := '1102070019' //IPI A RECUPERAR MATRIZ
	ElseIf CTBAPUR->CDP_FILIAL $ '10/11/12/13/14/15/16/17/18/19/1A/1B/1C'
		_cRetorno := '1102070400'
	ElseIf CTBAPUR->CDP_FILIAL $ '20/21/22/24/25'
		_cRetorno := '1102070401'
	ElseIf CTBAPUR->CDP_FILIAL == '23'
		_cRetorno := '1102070402'
	ElseIf CTBAPUR->CDP_FILIAL $ '30/31'
		_cRetorno := '1102070406'
	ElseIf CTBAPUR->CDP_FILIAL == '40'
		_cRetorno := '1102070403'
	ElseIf CTBAPUR->CDP_FILIAL == '90'
		_cRetorno := '1102070404'
	ElseIf CTBAPUR->CDP_FILIAL == '93'
		_cRetorno := '1102070405'
	ElseIf CTBAPUR->CDP_FILIAL == '95'
		_cRetorno := '1102070407'
	ElseIf CTBAPUR->CDP_FILIAL == '96'
		_cRetorno := '1102070408'
	ElseIf CTBAPUR->CDP_FILIAL == '98'
		_cRetorno := '1102070409'
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
Programa----------: MCTB05VL
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 20/03/2024
Descrição---------: Valida data informada nos parâmetros
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
User Function MCTB05VL()

Local _lRet:= .T. 
Private _cMesAnoCtab := MV_PAR03
Private _aMesValid:= { "01","02","03","04","05","06","07","08","09","10","11","12" }

//Verifica se a competencia informada e invalida e exibe uma mensagem de alerta
If aScan( _aMesValid, Subst( _cMesAnoCtab, 1 , 2 ) ) == 0 
	_lRet := .F.
	Help(NIL, NIL, "MCTB00501", NIL, "Data informada " + _cMesAnoCtab + " inválida!", 1, 0, NIL, NIL, NIL, NIL, NIL, {"Corrija a informação!"})//Formato Invalido
EndIf

Return (_lRet)
