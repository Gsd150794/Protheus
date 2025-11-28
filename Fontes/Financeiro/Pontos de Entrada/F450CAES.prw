/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: F450CAES
Autor-------------: Fabiano Dias
Data da Criacao---: 20/04/2011
Descrição---------: Ponto de entrada utilizada para verificar no momento de um cancelamento ou estorno de uma compensacao em
					carteira se os titulos a receber geraram comissao e esta se encontra com o status fechada, para que desta
					forma seja inviabilizado este estorno ou cancelamento.
Parametros--------: Nenhum
Retorno-----------: 0 - Nao podera ser realizada a exclusao ou estorno da compensacao entre carteiras
					1 - Gravar o Cancelamento/Estorno
===============================================================================================================================
*/
User Function F450CAES()     
                                
Local _aArea    := FWGetArea()    

Local _cAliasSE5:= ""
Local _cAliasSE3:= ""

Local _cTitComis:= ""

Local _cNumComp := ParamIXB[1]//Numero da Compensacao
Local _nRetorno := ParamIXB[2]//0 - Nao podera ser realizada a exclusao ou estorno da compensacao entre carteiras

If _nRetorno <> 0
	//Verifica os dados dos titulos a receber na tabela SE5 de acordo
	//com a compensacao informada para cancelamento ou estorno
	_cAliasSE5:= GetNextAlias()   
	
	querys(1,_cAliasSE5,_cNumComp,"","","","","","")
	
	DBSelectArea(_cAliasSE5)
	(_cAliasSE5)->(DBGoTop())	                          	
	//Percorre todos os titulos que compoem a compensacao para
	//verificar o status da comissao.
	While (_cAliasSE5)->(!Eof())      
	
		_cAliasSE3:= GetNextAlias()
	    
		querys(2,_cAliasSE3,"",(_cAliasSE5)->E5_NUMERO,(_cAliasSE5)->E5_PARCELA,;
		      (_cAliasSE5)->E5_PREFIXO,(_cAliasSE5)->E5_TIPO,(_cAliasSE5)->E5_CLIFOR,(_cAliasSE5)->E5_LOJA)    
		      
		DBSelectArea(_cAliasSE3)		      
		(_cAliasSE3)->(DBGoTop())		                           		
		//Nao podera ser realizado o estorno ou cancelamento da compensacao
		//entre carteiras uma vez que a comissao gerarada a partir da compensacao
		//ja se encontra com o status fechada.
		If (_cAliasSE3)->NUMREG > 0
		
			_cTitComis += CRLF + '[Filial]:'   + xFilial("SE5") +;
			                       ' [Prefixo]:' + AllTrim((_cAliasSE5)->E5_PREFIXO) +;
			                       ' [Tipo]:'    + AllTrim((_cAliasSE5)->E5_TIPO) +;
			                       ' [Titulo]:'  + (_cAliasSE5)->E5_NUMERO +;
			                       ' [Parcela]:' + (_cAliasSE5)->E5_PARCELA		
		EndIf    		                            		
		//Finaliza a area criada anteriormente para consulta das comissoes.
		DBSelectArea(_cAliasSE3)		      
		(_cAliasSE3)->(DBCloseArea())
	     
	(_cAliasSE5)->(DBSkip()) 
	EndDo	        	
	//Finaliza a area criada anteriormente para consulta dos dados do
	//titulo a receber referente a compensacao informada.
	DBSelectArea(_cAliasSE5)
	(_cAliasSE5)->(DBCloseArea()) 
	
	If Len(AllTrim(_cTitComis)) > 0           

		xMagHelpFis("INFORMAÇÃO",;
		            "O(s) titulo(s) listado(s) abaixo possui(em) comissão gerada e esta se encontra com o status fechada, desta forma não será possível realizar o cancelamento ou estorno da compensação entre carteiras.",;
		            "Titulos que se encontram com problema:" + CRLF + _cTitComis)   
		            
		_nRetorno := 0   
			Else
            	_nRetorno := 1 
	EndIf

EndIf

FWRestArea(_aArea)

Return(_nRetorno)

/*
===============================================================================================================================
Programa----------: querys
Autor-------------: Fabiano Dias
Data da Criacao---: 20/04/2011
Descrição---------: Funcao utilizada para gerar as querys do fonte F450CAES.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function querys(_nOpcao,_cAlias,_cNumComp,_cNumTit,_cParcela,_cPrefixo,_cTipo,_cCliente,_cLoja)  

Local _cFiltro:= "%"

	Do Case
		//Query utilizada para verificar os dados dos titulos que compoem a compensacao.
		Case _nOpcao == 1    
		
		    _cFiltro += " AND E5_FILIAL =  '"  + xFilial("SE5") + "'"
		    _cFiltro += " AND E5_IDENTEE =  '" + _cNumComp      + "'"
		    _cFiltro += "%"
		   
			BeginSql alias _cAlias 
				SELECT
				      E5_NUMERO,E5_PARCELA,E5_PREFIXO,E5_TIPO,E5_CLIFOR,E5_LOJA
				FROM
				      %Table:SE5%
				WHERE
				      D_E_L_E_T_ = ' '
				      AND E5_RECPAG = 'R'
				      AND E5_MOTBX = 'CEC'
				      AND E5_SITUACA <> 'C'
					  %exp:_cFiltro%
			EndSql
			     				            			
		//Query para verifica se foi gerada comissao para o titulo corrente
		//e se esta encontra-se com o status fechada.
		Case _nOpcao == 2 	
		
			_cFiltro += " AND E3_FILIAL = '"  + xFilial("SE3") + "'"  
			_cFiltro += " AND E3_NUM = '"     + _cNumTit       + "'"
		    _cFiltro += " AND E3_PARCELA = '" + _cParcela      + "'"
			_cFiltro += " AND E3_PREFIXO = '" + _cPrefixo      + "'"
		    _cFiltro += " AND E3_TIPO = '"    + _cTipo         + "'"
		    _cFiltro += " AND E3_CODCLI = '"  + _cCliente      + "'"
		    _cFiltro += " AND E3_LOJA = '"    + _cLoja         + "'"
		    _cFiltro += "%"
		
			BeginSql alias _cAlias			
				SELECT
				      COUNT(*) NUMREG
				FROM
				      %Table:SE3%
				WHERE
				      D_E_L_E_T_ = ' '
				      AND E3_I_FECH = 'S'
			          %exp:_cFiltro%
			EndSql
	
	EndCase

Return
