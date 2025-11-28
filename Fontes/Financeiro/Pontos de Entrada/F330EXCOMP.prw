/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaco  |09/01/2024| Chamado 45466. Ajustes para novo staus de contrato compensado.
Igor Melgaço  |26/08/2025| Chamado 51091. Ajuste para exclusão de instrução bancária.
Igor Melgaço  |22/09/2025| Chamado 52172. Ajuste para exibição de mensagem validação qdo período estiver fechado.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F330EXCOMP
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 08/04/2011
Descrição---------: Ponto de Entrada utilizado para validar a exclusao ou estorno de uma compensacao para que seja verificado
					se foi gerada comissao para os titulos que compoem a baixa e se esta encontra-se com o status fechada.
					O ponto de entrada F330EXCOMP efetua validações adicionais na exclusão/estorno da compensação de Contas a 
					receber. Este ponto de entrada identifica através do terceiro parâmetro em qual operação está sendo realizada 
					(5=Estorno e 4=Exclusão).
Parametros--------: Array contendo na sua estrura dois arrays (aTitulos, aRegistros e nOpcao). O array aTitulos corresponde aos 
					títulos marcados para estorno/exclusão da compensação, enquanto o aRegistros armazena o recno de cada 
					registro na tabela SE5 com relação à compensação.E a variável nOpcao contém o número referente a operação 
					que está sendo executada (5=Estorno e 4=Exclusão).Cada array contém a seguinte estrutura:
					ParamIXB:[01] - aTitulos[02] - aRegistros
					aTitulos:[01] - Prefixo[02] - Número[03] - Parcela[04] - Tipo[05] - Loja[06] - Data[07] - Documento 
							(Pref.+Num.+Parc.+Tipo) compensado[08] - Sequência (E5_SEQ)[09] - Valor líquido[10] - 
							Valor compensado[11] - Lógico (true)[12] - FilialaRegistros:[01] - Recno do registro na tabela SE5
Retorno-----------: Retorno da validação quando efetuado o estorno/exclusão da compensação. Caso o retorno seja verdadeiro, 
					a operação de exclusão/estorno será efetivada. Caso seja falso, a operação é abortada e os registros 
					permanecem íntegros.
===============================================================================================================================
*/
User Function F330EXCOMP() As Logical

Local _aTitulos  := ParamIXB[1] As Array
Local _aRegistros:= ParamIXB[2] As Array //Armazena os R_E_C_N_O_ dos titulos que foram baixados para realizar a compensacao
Local _aTitSE3   := {} As Array //Armazena os dados dos titulos que serao utilizados para checar se foi gerada comissao e este se encontra fechada
Local _cRecnoSE5 := "" As Character
Local _cAliasSE5 := GetNextAlias() As Character
Local _cAliasSE3 := "" As Character
Local _cFilial   := xFilial("SE1") As Character
Local _cPrefixo	:= "" As Character
Local _cDoc	:= "" As Character
Local _cParcela := "" As Character
Local _cTipo := "" As Character
Local x			:= 0 As Numeric
Local _cTitComis := "" As Character
Local _lRet      := .T. As Logical
Local _nRecnoSE1 := SE1->(Recno()) As Numeric
Local _cTipoSE1 := SE1->E1_TIPO As Character
Local _cCodCli := "" As Character
Local _cLojaCli := "" As Character
Local _nI := 0 As Integer
Local _cQuery := "" As Character
Local _cAlias := "" As Character
Local _nOptMov  := ParamIXB[3]
Local _dDtMov   := CTOD(ParamIXB[1][1][6])
Local _dDtFech  := GETMV("MV_DATAFIN")

If _nOptMov = 4
    If _dDtMov <= _dDtFech
        U_ITMsg("MV_DATAFIN", 'Atenção!',"Período Fechado!",1)
		Return .F.     
    EndIf
ElseIf _nOptMov = 3
    If DDATABASE() <= _dDtFech
        U_ITMsg("MV_DATAFIN",'Atenção!',"Período Fechado!",1)
		Return .F.
    EndIf
EndIf

If Len(_aTitulos) > 0  //25/03/2013 - Talita - Incluida a validação para que retorne mensagem de informação para quando não For selecionado nenhum titulo. Conforme chamado: 2952
	_cPrefixo  := _aTitulos[1][1]
	_cDoc	   := _aTitulos[1][2]
	_cParcela  := _aTitulos[1][3]
	_cTipo     := _aTitulos[1][4]
	_cSeq		:= _aTitulos[1][8]  // INCLUSO POR ERICH BUTTNER DIA 06/09/13 - VERIFICAR SEQUENCIA DAS BAIXAS DOS TITULOS

Else

	xMagHelpFis("F330EXCOMP001",;
	            "Não foram selecionados tÍtulos para exclusão",;
	            "Para excluir a compensação é necessario selecionar ao menos um título")   
	            
	_lRet := .F.
                        

	Return _lRet     

EndIf

aAdd(_aTitSE3,{_cFilial,_cPrefixo,_cDoc,_cParcela,_cTipo,_cSeq})// ADICIONADO POR ERICH BUTTNER DIA 06/09/13 - CAMPO DE SEQUENCIA DAS BAIXAS DE TITULOS//aAdd(_aTitSE3,{_cFilial,_cPrefixo,_cDoc,_cParcela,_cTipo}) 
     
For x:=1 To Len(_aRegistros)
	_cRecnoSE5 += ";" + AllTrim(Str(_aRegistros[x])) 
Next x 

_cRecnoSE5:= SubStr(_cRecnoSE5,2,Len(_cRecnoSE5)) 
     
//Seleciona os dados dos titulos que compoem a baixa por compensacao no titulo indicado acima
querys(1,_cAliasSE5,_cRecnoSE5)

DBSelectArea(_cAliasSE5)  
(_cAliasSE5)->(DBGoTop())

While (_cAliasSE5)->(!Eof()) 

	aAdd(_aTitSE3,{;
				       (_cAliasSE5)->E5_FILORIG,;              //Filial de Origem do titulo
				       SubStr((_cAliasSE5)->E5_DOCUMEN,1,3) ,;//Prefixo do titulo
				       SubStr((_cAliasSE5)->E5_DOCUMEN,4,9) ,;//Numero do titulo
				       SubStr((_cAliasSE5)->E5_DOCUMEN,13,2),;//Parcela do titulo
				       SubStr((_cAliasSE5)->E5_DOCUMEN,15,3),; //Tipo do Titulo
				       _cSeq;
					  })

	(_cAliasSE5)->(DBSkip())
EndDo            

DBSelectArea(_cAliasSE5)  
(_cAliasSE5)->(DBCloseArea())

//================================================================
//Query para verificar se foi gerada comissao para algum titulo
//que compoem a compensacao e se esta comissao encontra-se
//com o status fechada
//================================================================
For x:=1 To Len(_aTitSE3) 

	  _cAliasSE3:= GetNextAlias()	

	  querys(2,_cAliasSE3,"",_aTitSE3[x,1],_aTitSE3[x,2],_aTitSE3[x,3],_aTitSE3[x,4],_aTitSE3[x,5],_aTitSE3[x,6])// ADICIONADO POR ERICH BUTTNER DIA 06/09/13 - CAMPO DE SEQUENCIA DAS BAIXAS DE TITULOS//querys(2,_cAliasSE3,"",_aTitSE3[x,1],_aTitSE3[x,2],_aTitSE3[x,3],_aTitSE3[x,4],_aTitSE3[x,5])
	  
	  DBSelectArea(_cAliasSE3)
	  (_cAliasSE3)->(DBGoTop())
	  
	  If (_cAliasSE3)->NUMREG > 1
	  
        	_cTitComis += CRLF + '[Filial]:' + _aTitSE3[x,1] + ' [Prefixo]:' + AllTrim(_aTitSE3[x,2]) + ' [Tipo]:' + AllTrim(_aTitSE3[x,5]) + ' [Titulo]:' + _aTitSE3[x,3] + ' [Parcela]:' + _aTitSE3[x,4]
	  
	  EndIf       
	  
	  DBSelectArea(_cAliasSE3)
	  (_cAliasSE3)->(DBCloseArea())

Next x 

If Len(AllTrim(_cTitComis)) > 0           

	xMagHelpFis("F330EXCOMP002",;
	            "O(s) titulo(s) listado(s) abaixo possui(em) comissão gerada e esta se encontra com o status fechada, desta forma não será possível realizar a exclusão ou estorno da compensação.",;
	            "Titulos que se encontram com problema:" + CRLF + _cTitComis)   
	            
	_lRet := .F.
            
EndIf            

If _lRet

	U_MOMS68CS(_nRecnoSE1)

	For x:=1 To Len(_aRegistros)
		U_MOMS68CS(_aRegistros[x])
	Next x 

EndIf

If _lRet
	Begin Transaction
		If _cTipoSE1 == 'NF '

			If SE1->(Recno()) <> _nRecnoSE1
				SE1->(DBGoTo(_nRecnoSE1))
			EndIf
		
			_cPrefixo  := SE1->E1_PREFIXO
			_cDoc	   := SE1->E1_NUM
			_cParcela  := SE1->E1_PARCELA
			_cTipo     := SE1->E1_TIPO
			_cCodCli   := SE1->E1_CLIENTE //Codigo do Cliente
			_cLojaCli  := SE1->E1_LOJA //Loja do Cliente
			
			_cAlias    := GetNextAlias() //Cria um alias para a tabela FI2

			_cQuery := "SELECT FI2_GERADO, FI2.R_E_C_N_O_ AS RECNO "
			_cQuery += "FROM "+ RetSqlName("FI2") +" FI2 "
			_cQuery += "WHERE FI2_FILIAL = '"+xFilial("FI2")+"' "
			_cQuery += "AND FI2_GERADO IN ('1','2') "
			_cQuery += "AND FI2_OCORR = '04' "
			_cQuery += "AND FI2_PREFIX = '"+_cPrefixo+"' "
			_cQuery += "AND FI2_TITULO = '"+_cDoc+"' "
			_cQuery += "AND FI2_PARCEL = '"+_cParcela+"' "
			_cQuery += "AND FI2_TIPO = '"+_cTipo+"' "
			_cQuery += "AND FI2_CODCLI = '"+_cCodCli+"' "
			_cQuery += "AND FI2_LOJCLI = '"+_cLojaCli+"' "
			_cQuery += "AND FI2.D_E_L_E_T_ = ' ' "

			MPSysOpenQuery( _cQuery,_cAlias )
			DBSelectArea(_cAlias)

			If (_cAlias)->(!Eof())
				If (_cAlias)->FI2_GERADO = "1" //Verifica se a instrução bancária foi gerada
			   		U_ITMsg("Instrução Bancária gerada!",;
					         'Atenção!',;
					         "Verificar junto ao banco se a instrução já está processada e ajustar.",1)
					_lRet := .T.
				Else
					DBSelectArea("FI2")
					FI2->(DBGoTo((_cAlias)->RECNO))
					If RecLock("FI2", .F.)
						//Exclui o registro na tabela FI2
						FI2->(DbDelete())
						FI2->(MSUnLock())
					EndIf
				EndIf
			EndIf

			(_cAlias)->(DBCloseArea())

		Else
			For _nI := 1 To Len(_aTitulos)

				If _aTitulos[1][11] 
					_cPrefixo  := _aTitulos[_nI][1]
					_cDoc	   := _aTitulos[_nI][2]
					_cParcela  := _aTitulos[_nI][3]
					_cTipo     := _aTitulos[_nI][4]
					_cCodCli   := _aTitulos[_nI][5] //Codigo do Cliente
					_cLojaCli  := _aTitulos[_nI][6] //Loja do Cliente
					
					_cAlias    := GetNextAlias() //Cria um alias para a tabela FI2

					_cQuery := "SELECT FI2_GERADO, FI2.R_E_C_N_O_ AS RECNO "
					_cQuery += "FROM "+ RetSqlName("FI2") +" FI2 "
					_cQuery += "WHERE FI2_FILIAL = '"+xFilial("FI2")+"' "
					_cQuery += "AND FI2_GERADO IN ('1','2') "
					_cQuery += "AND FI2_OCORR = '04' "
					_cQuery += "AND FI2_PREFIX = '"+_cPrefixo+"' "
					_cQuery += "AND FI2_TITULO = '"+_cDoc+"' "
					_cQuery += "AND FI2_PARCEL = '"+_cParcela+"' "
					_cQuery += "AND FI2_TIPO = '"+_cTipo+"' "
					_cQuery += "AND FI2_CODCLI = '"+_cCodCli+"' "
					_cQuery += "AND FI2_LOJCLI = '"+_cLojaCli+"' "
					_cQuery += "AND FI2.D_E_L_E_T_ = ' ' "

					MPSysOpenQuery( _cQuery,_cAlias )
					DBSelectArea(_cAlias)

					If (_cAlias)->(!Eof())
						If (_cAlias)->FI2_GERADO = "1" //Verifica se a instrução bancária foi gerada
					   		U_ITMsg("Instrução Bancária gerada!",;
							         'Atenção!',;
							         "Verificar junto ao banco se a instrução já está processada e ajustar.",1)

						Else
							DBSelectArea("FI2")
							FI2->(DBGoTo((_cAlias)->RECNO))
							If RecLock("FI2", .F.)
								//Exclui o registro na tabela FI2
								FI2->(DbDelete())
								FI2->(MSUnLock())
							EndIf
						EndIf
					EndIf

					(_cAlias)->(DBCloseArea())
				EndIf
			Next
		EndIf
	End Transaction
EndIf

Return _lRet       

/*
===============================================================================================================================
Programa----------: querys
Autor-------------: Fabiano Dias da Silva
Data da Criacao---: 08/04/2011
Descrição---------: Funcao utilizada para gerar as querys do fonte F330EXCOMP
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function querys(_nOpcao As Numeric, _cAlias As Character, _cRecnoSE5 As Character, _cFilial As Character, _cPrefixo As Character, _cDoc As Character, _cParcela As Character, _cTipo As Character, _cSeq As Character) As Logical

Local _cFiltro := "%" As Character


	Do Case
		//Query utilizada para verificar os dados dos titulos que compoem a compensacao.
		Case _nOpcao == 1    
		    _cFiltro += " AND R_E_C_N_O_ IN " + FormatIn(_cRecnoSE5,";")
		    _cFiltro += "%"
		
			BeginSql alias _cAlias 
				SELECT E5_FILORIG, E5_DOCUMEN
				  FROM %Table:SE5%
				 WHERE D_E_L_E_T_ = ' '
				   %exp:_cFiltro%
			EndSql		      				            			
		//Query para verifica se foi gerada comissao para o titulo corrente e se esta encontra-se com o status fechada
		Case _nOpcao == 2 	
			BeginSql alias _cAlias			
				SELECT COUNT(1) NUMREG
				  FROM %Table:SE3%
				 WHERE D_E_L_E_T_ = ' '
				   AND E3_I_FECH = 'S'
				   AND E3_FILIAL = %exp:_cFilial%
				   AND E3_PREFIXO = %exp:_cPrefixo%
				   AND E3_TIPO = %exp:_cTipo%
				   AND E3_NUM = %exp:_cDoc%
				   AND E3_PARCELA = %exp:_cParcela%
				   AND E3_SEQ = %exp:_cSeq%
			EndSql
	
	EndCase

Return
