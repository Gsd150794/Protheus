/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |14/09/2020| Chamado 34141. Correção do ERROR.LOG do pergunte.
Lucas Borges  |25/03/2022| Chamado 39465. Migração das informações financeiras para as tabelas FKs.
Lucas Borges  |12/04/2024| Chamado 46931. Corrigida a exclusão das baixas.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "TOPCONN.CH"

/*
===============================================================================================================================
Programa----------: MGLT012
Autor-------------: Wodson Reis
Data da Criacao---: 03/12/2008
Descrição---------: Rotina desenvolvida para possibilitar o CANCELAMENTO do Acerto do Frete junto aos Fretistas.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT012()

Local _cPerg  		:= 'MGLT012'
Local _oProces		:= NIL

TNewProcess():New(	_cPerg											,; // Função inicial
					"Cancelamento Fechamento de Transportadores de Leite Próprio",; // Descrição da Rotina
					{|_oProces| MGLT012R(_oProces) }				,; // Função do processamento
					"Essa rotina tem por objetivo processar o 'Cancelamento do Fechamento do Frete sob Leite Próprio' "+;
					"excluindo os eventos e baixas dos Transportadores!",; // Descrição da Funcionalidade
					_cPerg											,; // Configuração dos Parâmetros
					{}												,; // Opções adicionais para o painel lateral
					.F.												,; // Define criação do Painel auxiliar
					0												,; // Tamanho do Painel Auxiliar
					''												,; // Descrição do Painel Auxiliar
					.T.												,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
	                .F.                                              ) // Se .T. cria apenas uma regua de processamento.

Return

/*
===============================================================================================================================
Programa----------: MGLT012R
Autor-------------: Wodson Reis
Data da Criacao---: 03/12/2008
Descrição---------: Rotina que controla o processamento do cancelamento
Parametros--------: _oProces
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT012R( _oProces )

Local _cAlias	:= GetNextAlias()
Local _cQuery	:= ""
Local nCont   	:= 1
Local _nReg   	:= 0
Local _cPrefixo := AllTrim(SuperGetMV("LT_EMPPRE",.F.,"GLE"))

Local _lDeuErro	:= .F.
Local _cCodSetor	:= ""
Local _cCodMix	:= MV_PAR01
Local _cSetores	:= ""
Local _cMotBaixa 	:= AllTrim(SuperGetMV("LT_MOTBX",.F.,"GLT"))
Local _cThread	:= CValToChar(ThreadID())

_oProces:SaveLog("Thread:"+_cThread+" Iniciando a rotina. Parâmetros: "+MV_PAR01+"-"+AllTrim(MV_PAR02)+"-"+MV_PAR03+"-"+MV_PAR04+"-"+MV_PAR05+"-"+MV_PAR06)//+"-"+DToC(MV_PAR07)

//Se não preencheu e não tem acesso a todos, aborta processamento
If !Empty(MV_PAR02) .Or. Empty(MV_PAR02) .And. Posicione("ZLU",1,xFilial("ZLU")+RetCodUsr(),"ZLU_SETALL") == 'S'
	_cSetores	:= AllTrim(MV_PAR02)												// Setores de Referência
Else
	_oProces:SaveLog("Thread:"+_cThread+" MGLT01201 - Fim do processamento. Não foram informados setores válidos para o usuário.")
	MsgStop("Não foram informados setores válidos para o usuário.","MGLT01201")
	Return
EndIf

_oProces:SetRegua1(1)
_oProces:IncRegua1( "Aguarde - Iniciando a rotina de processamento..." )

//====================================================================================================
// Filtra os Fretistas do MIX para iniciar o processamento
//====================================================================================================
_cQuery := "%"
If !Empty( _cSetores )
	_cQuery += "AND ZLF_SETOR  IN "+ FormatIn( _cSetores , ';' )
EndIf
_cQuery += "%"
BeginSql alias _cAlias
     SELECT ZLF_SETOR, ZLF_A2COD, ZLF_A2LOJA
       FROM %Table:ZLF%
      WHERE D_E_L_E_T_ = ' '
        AND ZLF_FILIAL = %xFilial:ZLF%
        AND ZLF_A2COD BETWEEN %exp:MV_PAR03% AND %exp:MV_PAR04%
        AND ZLF_A2LOJA BETWEEN %exp:MV_PAR05% AND %exp:MV_PAR06%
        AND ZLF_CODZLE = %exp:_cCodMix%
        AND SubStr(ZLF_A2COD,1,1) = 'G'
        AND ZLF_ACERTO = 'S'
        AND ZLF_TP_MIX = 'F'
        %exp:_cQuery%
        AND ZLF_DTFECH = %exp:dDataBase%
      GROUP BY ZLF_SETOR, ZLF_A2COD, ZLF_A2LOJA
      ORDER BY ZLF_SETOR, ZLF_A2COD, ZLF_A2LOJA
EndSql

Count To _nReg
(_cAlias)->( DBGoTop() )
_oProces:SetRegua1( _nReg )

If _nReg <= 0
	(_cAlias)->( DBCloseArea() )
	_oProces:SaveLog("Thread:"+_cThread+" MGLT01202 - Fim do processamento. Não foram encontrados registros para processar")
	MsgStop("Não foram encontrados registros para processar! Verifique os parâmetros e tente novamente.","MGLT01202")
	Return
EndIf	

Begin Transaction
	While (_cAlias)->( !Eof() )
		
		DBSelectArea("SA2")
		SA2->(DBSetOrder(1))
		If SA2->(DBSeek(xFilial("SA2")+(_cAlias)->ZLF_A2COD+(_cAlias)->ZLF_A2LOJA))
			_cCodSetor := (_cAlias)->ZLF_SETOR
			
			_oProces:IncRegua1( "Fretista "+AllTrim(Str(nCont))+" de "+AllTrim(Str(_nReg))+" -> "+SA2->A2_COD +"/"+SA2->A2_LOJA +" - "+AllTrim(SA2->A2_NOME) )
			
			If !_lDeuErro
				MGLT012C(_oProces,_cThread,_cMotBaixa,_cCodMix,_cCodSetor,@_lDeuErro)
			EndIf
			If !_lDeuErro
				MGLT012E(_oProces,_cThread,_cCodMix,_cCodSetor,@_lDeuErro)
			EndIf
			
			//================================================================================
			//Apos processar todas as funcoes, flag a ZLF informando que os eventos do
			//Fretista foram todos processados.
			//================================================================================
			If !_lDeuErro
				
				_cQuery := " UPDATE "+RetSqlName("ZLF")
				_cQuery += " SET ZLF_ACERTO = 'N', ZLF_L_SEEK = ' ', ZLF_STATUS = 'E', ZLF_DTFECH = ' ' "
				_cQuery += " WHERE D_E_L_E_T_ = ' ' "
				_cQuery += " AND ZLF_FILIAL = '"+xFilial("ZLF")+"' "
				_cQuery += " AND ZLF_A2COD	= '"+SA2->A2_COD+"' "
				_cQuery += " AND ZLF_A2LOJA = '"+SA2->A2_LOJA+"' "
				_cQuery += " AND ZLF_CODZLE = '"+_cCodMix+"' "
				_cQuery += " AND ZLF_SETOR	= '"+_cCodSetor+"' "
				_cQuery += " AND ZLF_TP_MIX = 'F' "
				
				If TCSqlExec(_cQuery) < 0
					_lDeuErro := .T.
					_oProces:SaveLog("Thread:"+_cThread+" MGLT01203 - Erro - Não foi possível atualizar status ZLF - "+ SA2->A2COD+"/"+SA2->A2_LOJA)
					MsgStop("Erro ao atualizar flags da tabela ZLF. Favor acionar a TI/Sistemas." + CRLF + AllTrim(TCSQLError()),"MGLT01203")
				EndIf
				
				//================================================================================
				//Ajusta acrescimos dos emprestimos!
				//================================================================================
				If !_lDeuErro
					_cQuery := " UPDATE "+ RetSqlName("SE2")
					_cQuery += " SET E2_DATALIB = '"+DToS(dDataBase)+"', E2_USUALIB = '"+cUserName+"' ,"
					_cQuery += " 	E2_BAIXA = ' ', E2_MOVIMEN = ' ', E2_SDACRES = E2_ACRESC"
					_cQuery += " WHERE D_E_L_E_T_ = ' ' "
					_cQuery += " AND E2_PREFIXO = '"+_cPrefixo+"'"
					_cQuery += " AND E2_L_MIX = '"+_cCodMix+"' "
					_cQuery += " AND E2_FORNECE = '"+SA2->A2_COD+"' "
					_cQuery += " AND E2_LOJA = '"+SA2->A2_LOJA+"' "
					_cQuery += " AND E2_VALOR = E2_SALDO "
					_cQuery += " AND E2_SALDO > 0 "
					_cQuery += " AND E2_L_SETOR = '"+_cCodSetor+"'"

					If TCSqlExec(_cQuery) < 0
						_lDeuErro := .T.
						_oProces:SaveLog("Thread:"+_cThread+" MGLT01204 - Erro - Não foi possível atualizar campos na SE2 - "+ SA2->A2COD+"/"+SA2->A2_LOJA)
						MsgStop("Erro ao cancelar baixa dos emprestimos!. Favor acionar a TI/Sistemas." + CRLF + AllTrim(TCSQLError()),"MGLT01204")
					EndIf
				EndIf
				//================================================================================
				//Chama funcao para deletar na ZLF os eventos gerados pela rotina de Fechamento
				//================================================================================
				If !_lDeuErro
					_cQuery := " DELETE FROM "+RetSqlName("ZLF")
					_cQuery += " WHERE D_E_L_E_T_ = ' ' "
					_cQuery += " AND ZLF_FILIAL = '"+xFilial("ZLF")+"' "
					_cQuery += " AND ZLF_CODZLE = '"+_cCodMix+"' "
					_cQuery += " AND ZLF_A2COD = '"+SA2->A2_COD+"' "
					_cQuery += " AND ZLF_A2LOJA = '"+SA2->A2_LOJA+"' "
					_cQuery += " AND ZLF_ORIGEM = 'F' "		//So deleta originados pela rotina do Acerto
					_cQuery += " AND ZLF_ACERTO <> 'S' "	//Deleta se nao realizou acerto definitivo
					_cQuery += " AND ZLF_TP_MIX = 'F' "		//Deleta apenas registros do Frete
					_cQuery += " AND ZLF_SETOR = '"+_cCodSetor+"'"
					
					If TCSqlExec(_cQuery) < 0
						_lDeuErro := .T.
						_oProces:SaveLog("Thread:"+_cThread+" MGLT01205 - Erro - Não foi possível atualizar campos na SE2 - "+ SA2->A2COD+"/"+SA2->A2_LOJA)
						MsgStop("Não foi possível deletar registros da ZLF! Favor acionar o Suporte." + CRLF + AllTrim(TCSQLError()),"MGLT01205")
					EndIf
				EndIf
			EndIf
		Else
			_oProces:SaveLog("Thread:"+_cThread+" MGLT01206 - Erro - Não foi possível localizar o fretista - "+ SA2->A2COD+"/"+SA2->A2_LOJA)
			MsgStop("Fretista não localizado: "+ SA2->A2COD+"/"+SA2->A2_LOJA,"MGLT01206")
		EndIf
			
		//================================================================================
		//Se houve alguma falha, desfaz todas as transacoes
		//================================================================================
		If _lDeuErro
			DisarmTransaction()
			_lDeuErro := .F.
		EndIf
		
		nCont++
		(_cAlias)->( DBSkip() )
	EndDo
		
	(_cAlias)->(DBCloseArea())

	_oProces:SetRegua1(1)
	_oProces:IncRegua1( "Fim do Acerto - Verificando Status..." )
	      
	//================================================================================
	// Altera o Status da ZLE
	//================================================================================
	_cAlias := GetNextAlias()
	BeginSql alias _cAlias
		SELECT COUNT(1) QTD
		  FROM %Table:ZLF%
		 WHERE D_E_L_E_T_ = ' '
		   AND ZLF_CODZLE = %exp:_cCodMix%
		   AND ZLF_ACERTO <> 'S'
	EndSql
	
	If (_cAlias)->QTD > 0
		ZLE->( RecLock( "ZLE" , .F. ) )
		ZLE->ZLE_STATUS := 'P'
		ZLE->( MSUnLock() )
	EndIf
	
	(_cAlias)->(DBCloseArea())
		
	_oProces:SaveLog("Thread:"+_cThread+" Processamento concluído com sucesso")

End Transaction
  
Return

/*
===============================================================================================================================
Programa----------: MGLT012C
Autor-------------: Wodson Reis
Data da Criacao---: 03/12/2008
Descrição---------: Cancela Baixa de titulo no contas a pagar via SigaAuto.
Parametros--------: _oProces,_cThread,_cMotBaixa,_cCodMix,_cCodSetor,_lDeuErro
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT012C(_oProces,_cThread,_cMotBaixa,_cCodMix,_cCodSetor,_lDeuErro)

Local _cAlias		:= GetNextAlias()
Local _cQuery		:= ""
Local _nCont		:= 1
Local _nTotReg		:= 0
Local nModAnt		:= nModulo
Local cModAnt		:= cModulo
Local _aArea		:= FWGetArea()
Local _aAutoSE2		:= {}
Local _nX		:= 0
Local _nSeq		:= 0
Private aBaixaSE5	:= {} //Declarada como Private para ser usada no Sel080Baixa
Private lMsErroAuto	:= .F.
Private lMsHelpAuto	:= .T.

//================================================================================
//Seleciona os titulos do Fretista para terem sua baixas canceladas
//================================================================================
BeginSql alias _cAlias
	SELECT E2_FILIAL, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, FK2_VALOR, FK2_SEQ, FK2_MOTBX, FK2_DATA, SE2.R_E_C_N_O_ REGSE2
	FROM %Table:SE2% SE2, %Table:FK7% FK7, %Table:FK2% FK2
	WHERE SE2.D_E_L_E_T_ = ' '
	AND FK7.D_E_L_E_T_ = ' '
	AND FK2.D_E_L_E_T_ = ' '
	AND E2_FILIAL = FK7_FILTIT
	AND E2_PREFIXO = FK7_PREFIX
	AND E2_NUM = FK7_NUM
	AND E2_PARCELA = FK7_PARCEL
	AND E2_TIPO = FK7_TIPO
	AND E2_FORNECE = FK7_CLIFOR
	AND E2_LOJA = FK7_LOJA
	AND FK2_IDDOC = FK7_IDDOC
	AND FK7_ALIAS = 'SE2'
	AND E2_FILIAL = %xFilial:SE2%
	AND E2_TIPO IN ('NDF', 'NF ')
	AND E2_SALDO <> E2_VALOR
	AND SE2.E2_FORNECE = %exp:SA2->A2_COD%
	AND SE2.E2_LOJA = %exp:SA2->A2_LOJA%
	AND FK2_MOTBX = %exp:_cMotBaixa%
	AND FK2_DATA = %exp:dDatabase%
	AND FK2_L_MIX = %exp:_cCodMix%
	AND FK2_L_SETO = %exp:_cCodSetor%
	AND NOT EXISTS (SELECT 1 FROM FK2010 EST
			WHERE EST.D_E_L_E_T_ = ' '
			AND FK2.FK2_IDDOC = EST.FK2_IDDOC
			AND FK2.FK2_SEQ = EST.FK2_SEQ
			AND EST.FK2_TPDOC = 'ES')
	ORDER BY E2_FILIAL, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, FK2_SEQ DESC
EndSql		

Count To _nTotReg
(_cAlias)->( DBGoTop() )
_oProces:SetRegua2(_nTotReg)
DBSelectArea("SE2")
	
While (_cAlias)->( !Eof() ) .And. !_lDeuErro
	//Manter SE2 posicionada pois as rotinas padrões possuem essa premissa
	SE2->( DBGoTo((_cAlias)->REGSE2) )
	lMsErroAuto	:= .F.
	lMsHelpAuto	:= .T.

	_oProces:IncRegua2( "Cancelamento Baixa - Tarefa "+ AllTrim( Str( _nCont ) ) +" de "+ AllTrim( Str( _nTotReg ) ) )
	_nSeq := 0

	_aAutoSE2 := {	{ "E2_PREFIXO"		, (_cAlias)->E2_PREFIXO						, Nil },;
					{ "E2_NUM"			, (_cAlias)->E2_NUM	     					, Nil },;
					{ "E2_PARCELA"		, (_cAlias)->E2_PARCELA  					, Nil },;
					{ "E2_TIPO"	    	, (_cAlias)->E2_TIPO    					, Nil },;
					{ "E2_FORNECE"		, SA2->A2_COD            					, Nil },;
					{ "E2_LOJA"	    	, SA2->A2_LOJA           					, Nil },;
					{ "AUTJUROS"		, 0				       						, Nil },;
					{ "AUTDESCONT"		, 0		 		        					, Nil },;
					{ "AUTMOTBX"		, (_cAlias)->FK2_MOTBX    					, Nil },;
					{ "AUTDTBAIXA" 		, (_cAlias)->FK2_DATA	    				, Nil },;
					{ "AUTDTCREDITO"	, (_cAlias)->FK2_DATA    					, Nil },;
					{ "AUTHIST"			, "Cancto Bx - "+SA2->A2_COD+SA2->A2_LOJA	, Nil },;
					{ "AUTVLRPG"		, (_cAlias)->FK2_VALOR						, Nil },;
					{ "AUTVALREC"		, (_cAlias)->FK2_VALOR						, Nil } }
	
	//Altera o modulo para Financeiro, senao o SigaAuto nao executa.
	nModulo := 6
	cModulo := "FIN"
	
	//================================================================================
	//Busca o numero da Baixa.
	//================================================================================
	aBaixaSE5 := Sel080Baixa("VL /BA /CP /",SE2->E2_PREFIXO,SE2->E2_NUM,SE2->E2_PARCELA,SE2->E2_TIPO,0,0,SE2->E2_FORNECE,SE2->E2_LOJA,.F.,.F.,.F.,0,.F.,.T.)
	For _nX := 1 To Len(aBaixaSE5)
		If SubStr(aBaixaSE5[_nX],Len(aBaixaSE5[_nX])-1,2) == (_cAlias)->FK2_SEQ
			_nSeq := _nX
			Exit
		EndIf
	Next _nX
	
	//================================================================================
	//SigaAuto de Cancelamento de Baixa de Contas a Pagar.
	//================================================================================
	MSExecAuto( {|x,y,z,k| Fina080(x,y,z,k)} , _aAutoSE2 , 6 ,, _nSeq )
	
	//Verifica se houve erro no SigaAuto, caso haja mostra o erro.
	If lMsErroAuto
		_lDeuErro := .T.
		_oProces:SaveLog("Thread:"+_cThread+" MGLT01207 - Erro - Execauto de baixa - "+xFilial("SE2")+(_cAlias)->(E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO)+SA2->(A2_COD+A2_LOJA))
		MsgStop("Existe uma não conformidade no SigaAuto de Baixa de Contas a Pagar! Chave "+;
				xFilial("SE2")+(_cAlias)->(E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO)+SA2->(A2_COD+A2_LOJA) +;
				" Após confirmar esta tela, sera apresentada a tela de Não Conformidade do SigaAuto. Favor acionar o Suporte.","MGLT01207")
		MostraErro()
		
		//Restaura o modulo em uso
		nModulo := nModAnt
		cModulo := cModAnt
		
	Else
	
		//Restaura o modulo em uso.
		nModulo := nModAnt
		cModulo := cModAnt
		
		_cQuery := " UPDATE " + RetSqlName("SE2")
		_cQuery += " SET E2_L_MIX = '"+_cCodMix+"', E2_DATALIB = ' ' "
		_cQuery += " WHERE D_E_L_E_T_	= ' ' "
		_cQuery += " AND E2_FILIAL = '"+xFilial("SE2")+"' "
		_cQuery += " AND E2_PREFIXO = '"+(_cAlias)->E2_PREFIXO+"' "
		_cQuery += " AND E2_NUM = '"+(_cAlias)->E2_NUM+"' "
		_cQuery += " AND E2_PARCELA = '"+(_cAlias)->E2_PARCELA+"' "
		_cQuery += " AND E2_TIPO = '"+(_cAlias)->E2_TIPO+"' "
		_cQuery += " AND E2_FORNECE = '"+SA2->A2_COD+"' "
		_cQuery += " AND E2_LOJA = '"+SA2->A2_LOJA+"' "
		
		If TCSqlExec(_cQuery) < 0
			_lDeuErro := .T.
			_oProces:SaveLog("Thread:"+_cThread+" MGLT01208 - Erro - Update E2_L_MIX - "+xFilial("SE2")+(_cAlias)->(E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO)+SA2->(A2_COD+A2_LOJA))
			MsgStop("Não Conformidade ao executar o Update de gravacao do cod. MIX no E2_MIX!. Favor acionar o Suporte." + CRLF + AllTrim(TCSQLError()),"MGLT01208")
		Else
		
			_cQuery := " UPDATE " + RetSqlName("ZLL")
			_cQuery += " SET ZLL_STATUS = 'A' "
			_cQuery += " WHERE D_E_L_E_T_ = ' ' "
			_cQuery += " AND ZLL_FILIAL = '"+ xFilial("SE2")+"' "
			_cQuery += " AND ZLL_COD = '"+SubStr((_cAlias)->E2_NUM,1,6)+"' "
			_cQuery += " AND ZLL_SEQ = '"+SubStr((_cAlias)->E2_NUM,7,3)+"' "
			_cQuery += " AND ZLL_RETIRO = '"+SA2->A2_COD+"' "
			_cQuery += " AND ZLL_RETILJ = '"+SA2->A2_LOJA+"' "
			
			If ( TCSqlExec(_cQuery) < 0 )
				_lDeuErro := .T.
				_oProces:SaveLog("Thread:"+_cThread+" MGLT01209 - Erro - Update ZZL_STATUS - "+xFilial("SE2")+(_cAlias)->(E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO)+SA2->(A2_COD+A2_LOJA))
				MsgStop("Não Conformidade ao executar o Update de gravacao do Status do Convenio! . Favor acionar o Suporte." + CRLF + AllTrim(TCSQLError()),"MGLT01209")
			EndIf
		EndIf
	EndIf
	_nCont++
	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa----------: MGLT012E
Autor-------------: Wodson Reis
Data da Criacao---: 03/12/2008
Descrição---------: Exlcui titulo no contas a pagar via SigaAuto.
Parametros--------: Objeto de Processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT012E(_oProces,_cThread,_cCodMix,_cCodSetor,_lDeuErro)

Local _cAlias		:= GetNextAlias()
Local _nCont		:= 1
Local _nTotReg		:= 0
Local nModAnt		:= nModulo
Local cModAnt		:= cModulo
Local _aArea		:= FWGetArea()
Local _aAutoSE2		:= {}

Private lMsErroAuto	:= .F.
Private lMsHelpAuto	:= .T.

//================================================================================
//Seleciona os titulos do Fretista que foram gerados automaticamente
//================================================================================
BeginSql alias _cAlias
	SELECT E2_FILIAL, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO
	  FROM %Table:SE2%
	 WHERE D_E_L_E_T_ = ' '
	   AND E2_FILIAL = %xFilial:SE2%
	   AND E2_L_MIX = %exp:_cCodMix%
	   AND E2_FORNECE = %exp:SA2->A2_COD%
	   AND E2_LOJA = %exp:SA2->A2_LOJA%
	   AND E2_L_SITUA = 'I'
	   AND E2_TIPO IN ('NDF', 'NF ')
	   AND E2_SALDO > 0
	   AND E2_L_SETOR = %exp:_cCodSetor%
EndSql
		
Count To _nTotReg
(_cAlias)->( DBGoTop() )
_oProces:SetRegua2(_nTotReg)
DBSelectArea("SE2")

While (_cAlias)->(!Eof()) .And. !_lDeuErro
	_oProces:IncRegua2("Exclusao Titulo - Tarefa "+AllTrim(Str(_nCont))+" de "+AllTrim(Str(_nTotReg)))
	SE2->(DBSetOrder(1))
	If SE2->(DBSeek(xFilial("SE2")+(_cAlias)->(E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO)+SA2->(A2_COD+A2_LOJA)))
		
		//================================================================================
		//Array com os dados a serem passados para o SigaAuto.
		//================================================================================
	   _aAutoSE2 := {	{ "E2_PREFIXO"	, SE2->E2_PREFIXO	, Nil },;
						{ "E2_NUM"		, SE2->E2_NUM		, Nil },;
						{ "E2_TIPO"		, SE2->E2_TIPO		, Nil },;
						{ "E2_PARCELA"	, SE2->E2_PARCELA	, Nil },;
						{ "E2_NATUREZ"	, SE2->E2_NATUREZ	, Nil },;
						{ "E2_FORNECE"	, SA2->A2_COD		, Nil },;
						{ "E2_LOJA"		, SA2->A2_LOJA		, Nil } }
		
		//Altera o modulo para Financeiro, senao o SigaAuto nao executa.
		nModulo := 6
		cModulo := "FIN"
		
		//================================================================================
		//Roda SigaAuto de Exclusao de Titulos a Pagar.
		//================================================================================
		MSExecAuto({|x,y,z| Fina050(x,y,z)},_aAutoSE2,,5)
		
		// Restaura o modulo em uso.                                                    |
		nModulo := nModAnt
		cModulo := cModAnt
	Else
		_lDeuErro := .T.
		_oProces:SaveLog("Thread:"+_cThread+" MGLT01210 - Erro - Título não encontrado para exclusão - "+xFilial("SE2")+(_cAlias)->(E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO)+SA2->(A2_COD+A2_LOJA))
		MsgStop("O titulo "+xFilial("SE2")+(_cAlias)->(E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO)+;
				" não foi encontrado! Fretista: "+SA2->A2_COD+"/"+SA2->A2_LOJA+"-"+SA2->A2_NOME	,;
				"Verifique no financeiro se este titulo existe, pois o mesmo não foi encontrado. Favor acionar o Suporte.","MGLT01210")
	EndIf
	
	//================================================================================
	//Verifica se houve erro no SigaAuto, caso haja mostra o erro.
	//================================================================================
	If lMsErroAuto
		_lDeuErro := .T.
		_oProces:SaveLog("Thread:"+_cThread+" MGLT01211 - Erro - Execauto de exclusão Contas a Pagar - "+xFilial("SE2")+(_cAlias)->(E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO)+SA2->(A2_COD+A2_LOJA))
		MsgStop("O titulo "+ xFilial("SE2") + SE2->(E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO )+;
						" não foi excluido! Fretista: "+ SA2->A2_COD +"/"+ SA2->A2_LOJA +" - "+ SA2->A2_NOME,;
						"Verifique no financeiro se este titulo ja foi baixado ou o motivo pelo qual não pode ser excluído. Favor acionar o Suporte.","MGLT01211")
		Mostraerro()
	EndIf
	_nCont++	
	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )
FWRestArea( _aArea )

Return
