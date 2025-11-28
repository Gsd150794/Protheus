/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |22/08/2018| Chamado 25937. Incluida validação de TES quanto a movimento de estoque.
Lucas Borges  |09/10/2018| Chamado 26587, 26586, 26585, 26583. Incluído tratamento para PE não ser chamado no TOTVS Colaboração.
Lucas Borges  |09/07/2020| Chamado 33422. Tratado para não ser executado quando chamado pelo Reprocessar.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MT116OK
Autor-----------: Alexandre Villar
Data da Criacao-: 28/01/2016
Descrição-------: P.E. após a confirmação do lançamento do CTE na geração da NF
Parametros------: ParamIXB[1] - .T. = Exclusão / .F. = Inclusão
Retorno---------: ( .T. ) Dados validos para inclusao. / ( .F. ) Dados não validados.
===============================================================================================================================
*/
User Function MT116OK

Local _lExclui	:= ParamIXB[1]
Local _lRet		:= .T.
Local _cQuery	:= ''
Local _cAlias	:= ''

//====================================================================================================
// Se não For exclusão verifica se já foi incluída uma NF com a mesma chave
//====================================================================================================
If !_lExclui .And. !FWIsInCallStack("SCHEDCOMCOL")
	If CFORMUL <> 'S'
		If !Empty( aNfeDanfe[13] )
			_cQuery := " SELECT "
			_cQuery += " 	SF1.F1_FILIAL	,"
			_cQuery += " 	SF1.F1_DOC		,"
			_cQuery += " 	SF1.F1_SERIE	,"
			_cQuery += " 	SF1.F1_FORNECE	,"
			_cQuery += " 	SF1.F1_LOJA		,"
			_cQuery += " 	SF1.F1_ESPECIE	,"
			_cQuery += "	SF1.F1_CHVNFE	 "
			_cQuery += " FROM "+ RetSqlName("SF1") +" SF1 "
			_cQuery += " WHERE "
			_cQuery += " 		SF1.D_E_L_E_T_	= ' ' "
			_cQuery += " AND	SF1.F1_CHVNFE	= '"+ aNfeDanfe[13] +"' "
			
			_cAlias := GetNextAlias()
			
			If Select(_cAlias) > 0
				(_cAlias)->( DBCloseArea() )
			EndIf
			
			DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )
			
			DBSelectArea(_cAlias)
			(_cAlias)->( DBGoTop() )
			If (_cAlias)->( !Eof() )
				U_ITMsg(	"A chave: "+ (_cAlias)->F1_CHVNFE +" já existe em outro documento! "+ CRLF										+;
							"Filial: "+  (_cAlias)->F1_FILIAL +"/ Documento: "+ (_cAlias)->F1_DOC +"/ Série: "+ (_cAlias)->F1_SERIE , 'Lançamento duplicado!',;
						 	"Verifique os dados e caso necessário informe a área de TI/Sistemas. O documento atual não será processado!",1 )
				
				_lRet := .F.
			EndIf
			(_cAlias)->( DBCloseArea() )
		EndIf
	EndIf

	//Verifica se TES do documento vinculado é compatível quanto a movimentação de estoque com o CTE sendo incluso
	_nposori := SD1->(Recno())
	_asd1 := SD1->(GetArea())
	_alog := {}
	
	SD1->(DBSetOrder(1))
	If SD1->(DBSeek(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA))
		While SF1->F1_FILIAL == SD1->D1_FILIAL .AND.;
		 			SF1->F1_DOC == SD1->D1_DOC .AND.;
		 			SF1->F1_SERIE == SD1->D1_SERIE .AND.;
		 			SF1->F1_FORNECE == SD1->D1_FORNECE .AND.;
		 			SF1->F1_LOJA == SD1->D1_LOJA
		 	
		 	_nPosTes := aScan( aHeader , {|X| Upper( AllTrim( X[2] ) ) == "D1_TES"     } ) // Código da TES
		 	_ctes := acols[1][_nPosTes]
		 	_cmvestnf := Posicione("SF4",1,SD1->D1_FILIAL+SD1->D1_TES,"F4_ESTOQUE")
		 	_cmvestct := Posicione("SF4",1,cfilant+_ctes,"F4_ESTOQUE")
		 	 		
		 	If !(AllTrim(_cmvestct) == AllTrim(_cmvestnf)) .And. _cmvestnf == "N"
		 		aAdd(_alog,{SD1->D1_FILIAL,SD1->D1_DOC+"/"+SD1->D1_SERIE,SD1->D1_ITEM,SD1->D1_FORNECE+"/"+SD1->D1_LOJA, SD1->D1_TES + " - Estoque  " + _cmvestnf, _ctes + " - Estoque " + _cmvestct })
		 	EndIf
		 	SD1->(DBSkip())
		EndDo
		
		If Len(_alog) > 0
			U_ITMsg("Divergência entre a TES do conhecimento e a utilizada na Nota Fiscal de Origem quanto a movimentação de estoque.",;
					"Atenção","Documento não será gravado, verifique a TES na próxima tela.",1)
			_ahead := {"Filial","Nota origem","Item","Fornecedor","TES NF","TES CTE"}
			U_ITListBox( 'Existem divergências de TES' , _ahead , _aLog , .T. , 1 )
			_lRet := .F.
		EndIf
	EndIf
	
	SD1->(FWRestArea(_asd1))
	SD1->(DBGoTo(_nposori)) 
EndIf

Return( _lRet )
