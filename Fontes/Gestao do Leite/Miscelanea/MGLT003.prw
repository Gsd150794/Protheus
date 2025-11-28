/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |21/07/2021| Chamado 37147. Replicação dos dados importados para os produtores filhos e tratamento da linha.
Lucas Borges  |20/02/2023| Chamado 43052. Alterado para permitir importar o layout 1 várias vezes.
Lucas Borges  |30/04/2024| Chamado 47117. Correção na conversão da linha.
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "FILEIO.CH"

/*
===============================================================================================================================
Programa----------: MGLT003
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 10/12/2018
Descrição---------: Rotina para imporação dos dados de análises de Leite a partir de arquivo recebido do Laboratório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT003()

Private _cPerg		:= "MGLT003"
Private _oSelf		:= nil

//============================================
//Cria interface principal
//============================================
tNewProcess():New(	_cPerg											,; // Função inicial
					"Importa Análise de Qualidade"		,; // Descrição da Rotina
					{|_oSelf| MGLT003P(_oSelf) }					,; // Função do processamento
					"Rotina para efetuar a importação das Análises de Qualidade recebidos dos laboratórios. ",; // Descrição da Funcionalidade
					_cPerg											,; // Configuração dos Parâmetros
					{}												,; // Opções adicionais para o painel lateral
					.F.												,; // Define criação do Painel auxiliar
					0												,; // Tamanho do Painel Auxiliar
					''												,; // Descrição do Painel Auxiliar
					.F.												,; // Se .T. exibe o painel de execução. Se falso, apenas executa a função sem exibir a régua de processamento.
                    .F.                                              ) // Se .T. cria apenas uma regua de processamento.

Return

/*
===============================================================================================================================
Programa----------: MGLT003P
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 10/12/2018
Descrição---------: Realiza o processamento da rotina.
Parametros--------: _oSelf
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT003P(_oSelf)

Local _nHandle		:= 0
Local _aDados		:= {}
Local _aTemp		:= {}
Local _aArq			:= {}
Local _aArqTmp		:= {}
Local _cEOL 		:= CHR(13) + CHR(10)
Local _nBuffer		:= 300
Local _nFilePos		:= 0
Local _nPos			:= 0
Local _cLine		:= "" 
Local _cBuffer		:=''
Local _nTamArq		:= 0
Local _nLidos		:= 0
Local _nProc		:= 0
Local _nX,_nZ		:= 0
Local _nI,_nJ		:= 0
Local _nLayout		:= 0
Local _lRet			:= .T.
Local _nQtdReg		:= 0
Local _nLimGor		:= SuperGetMV('LT_LIMGORI',.F., 5.5 )
Local _aNaoPrc		:= {}
Local _cCodPrd		:= ""
Local _cLojPrd		:= ""
Local _cSetor		:= ""
Local _cLinha		:= ""
Local _aUTC			:= {}
Local _cAlias		:= ""
Local _cMsg			:= ""
Local _cLaudo		:= ""
Local _cData		:= ""
Local _cHora		:= ""
Local _nVlrFx		:= 0

_aArqTmp := Directory(AllTrim(MV_PAR01)+"*.*")
For _nX := 1 to Len(_aArqTmp)
	If ".FAT" $ Upper(_aArqTmp[_nX][01]) .Or. ".CSV" $ Upper(_aArqTmp[_nX][01]) .Or. ".TXT" $ Upper(_aArqTmp[_nX][01])
		aAdd( _aArq ,AllTrim(MV_PAR01)+_aArqTmp[_nX][01])
	EndIf
Next _nX
If Empty(_aArq)
	MsgStop("Não foram encontrados arquivos válidos no diretório informado.", "MGLT00301")
EndIf

For _nJ := 1 to Len(_aArq)
	//Reinicio as variáveis a cada arquivo
	_aDados		:= {}
	_nLidos		:= 0
	_nProc		:= 0
	_nLayout	:= 0
	_lRet		:= .T.
	_nQtdReg	:= 0
	_aNaoPrc	:= {}
	_cSetor		:= ""
	_cLinha		:= ""
	_aUTC		:= {}
	_cLaudo		:= ""
	_cData		:= ""
	_cHora		:= ""
	_oSelf:SetRegua2(1)
	_oSelf:IncRegua2("")
	//Abre arquivo de texto
	If (_nHandle := FOpen(_aArq[_nJ])) >= 0
	    _oSelf:SetRegua1(1)
		_oSelf:IncRegua1("Abrindo arquivo...")
		_nTamArq:= FSeek(_nHandle, 0, 2) //Posiciona no fim do arquivo para pegar o tamanho
	    _nFilePos:= FSeek(_nHandle, 0, 0) // Posiciona no início do arquivo, no primeiro caracter
		_oSelf:SetRegua1(_nTamArq)
	
		DBSelectArea("ZLB")
		ZLB->( DBSetOrder(1) )
	
		While !(_nFilePos < 0 .Or. _nFilePos >= _nTamArq) .And. _lRet
		    _cBuffer	:= Space(_nBuffer) //Aloca Buffer
			FRead(_nHandle, _cBuffer, _nBuffer) //Lê os primeiros 100 caracteres do arquivo
			_nPos	:= AT(_cEOL, _cBuffer) // Procura o primeiro final de linha
			For _nX:= 1 To _nPos
				_oSelf:IncRegua1("Lendo arquivo "+_aArq[_nJ]+"...")
			Next _nX
			
		    If _nPos == 0
				MsgStop("Arquivo + "+_aArq[_nJ]+" + inconsistênte. Favor acionar o área de TI.","MGLT00302")
				Return
			EndIf	    	
		    // Leitura dos campos e gravação dos dados na tabela
		    _cLine := SubStr(_cBuffer, 0, _nPos)
			_aTemp:= StrTokArr(Upper(_cLine),';')
			
			//Evito de importar as possíveis linhas em branco que esquecem no fim do arquivo
	        If Len(_cLine)>1
				If _aTemp[1] == 'LAUDO'
					_cLaudo	:= ValTexto(_aTemp[2],"Laudo",@_lRet,@_aNaoPrc)
				ElseIf _aTemp[1]  == 'DATA LAUDO'
					_cData	:= _aTemp[2]
				ElseIf _aTemp[1] == 'HORA LAUDO'
					_cHora	:= _aTemp[2]
				ElseIf "ETIQUETA;CODIGO INDUSTRIA;PRODUTOR;GORDURA;PROTEINA;LACTOSE;EST;ESD;CCS;CBT CFU;CRIOSCOPIA" $ _cLine
					_nLayout:= 1
				ElseIf "                ROTA     COLETA    ANALISE  ORCOL          IDPROD PRODUC     GORD     PROT     LACT      SOL      CCS       Nº RELAT ROTA_AMOSTRA" $ _cLine
					_nLayout:= 2
				ElseIf "                ROTA     COLETA    ANALISE  ORCOL          IDPROD PRODUC      CPP TEMPER       Nº RELAT ROTA_AMOSTRA" $ _cLine
					_nLayout:= 3
				ElseIf "DATA;CODIGO;PRODUTOR;RESULTADO DE CRIOSCOPIA" $ _cLine //Importa as crioscopias
					_nLayout:= 4
				ElseIf "DATA;CODIGO;PRODUTOR;VOLUME CONDENADO (LITROS)" $ _cLine //Importa as condenações
					_nLayout:= 5
				ElseIf "DATA;CODIGO;PRODUTOR;VALOR;FAIXA;LINHA" $ _cLine //Importa valor genérico de acordo com o evento
					_nLayout:= 6
				ElseIf _nLayout == 1 .Or. _nLayout == 4 .Or. _nLayout == 5 .Or. _nLayout == 6
					aAdd(_aDados, StrTokArr(Upper(_cLine),';'))
				ElseIf _nLayout == 2
					aAdd(_aDados,{AllTrim(SubStr(_cLine,001,20)) ,; //01
								AllTrim(SubStr(_cLine,022,10)),; //02
								AllTrim(SubStr(_cLine,033,10)),; //03
								AllTrim(SubStr(_cLine,044,06)),; //04
								AllTrim(SubStr(_cLine,051,15)),; //05
								AllTrim(SubStr(_cLine,067,06)),; //06
								AllTrim(SubStr(_cLine,074,08)),; //07
								AllTrim(SubStr(_cLine,083,08)),; //08
								AllTrim(SubStr(_cLine,092,08)),; //09
								AllTrim(SubStr(_cLine,101,08)),; //10
								AllTrim(SubStr(_cLine,110,08)),; //11
								AllTrim(SubStr(_cLine,119,14)),; //12
								AllTrim(SubStr(_cLine,134,51))}) //13
				ElseIf _nLayout == 3
					aAdd(_aDados,{AllTrim( SubStr(_cLine,001,20)),;//01
								AllTrim(SubStr(_cLine,022,10)),;//02
								AllTrim(SubStr(_cLine,033,10)),;//03
								AllTrim(SubStr(_cLine,044,06)),;//04
								AllTrim(SubStr(_cLine,051,15)),;//05
								AllTrim(SubStr(_cLine,067,06)),;//06
								AllTrim(SubStr(_cLine,074,08)),;//07
								AllTrim(SubStr(_cLine,083,06)),;//08
								AllTrim(SubStr(_cLine,090,14)),;//09
								AllTrim(SubStr(_cLine,105,51))})//10
				EndIf
			EndIf
			_nLidos+=_nPos+1 //Salvo até qual posição do arquivo já foi lido desde a primeira posição
			_nFilePos:=FSeek(_nHandle, _nLidos,0) //Posiciono na próxima linha a partir do início do arquivo
		EndDo
	    
		If !_lRet
			MsgStop("Arquivo: "+_aArq[_nJ]+" . Campo Laudo com conteúdo inválido.", "MGLT00303")
		ElseIf _nLayout == 0
				MsgStop("Arquivo: "+_aArq[_nJ]+" . Layout incompatível com a rotina. Caso o arquivo esteja correto, favor acionar a TI/Sistemas.", "MGLT00304")
			_lRet := .F.
		ElseIf _nLayout == 1 .And. (Empty(_cLaudo) .Or. Empty(_cData) .Or. Empty(_cHora))
			MsgStop("Arquivo: "+_aArq[_nJ]+" . Não é possível processar o arquivo selecionado! Não foi possível verificar corretamente as informações do Laudo, data " +;
					"e/ou hora do arquivo. Verifique o arquivo informado e tente novamente.", "MGLT00305")
			_lRet := .F.
		EndIf
		
		If _lRet
			_nQtdReg := Len(_aDados)
		    _oSelf:SetRegua2(_nQtdReg)
		
			DBSelectArea('ZL3')
			ZL3->( DBSetOrder(1) )
			DBSelectArea("SA2")
			SA2->( DBSetOrder(1) )
			DBSelectArea("ZLD")
			ZLD->( DBSetOrder(1) )
		
			Begin Transaction
				For _nI := 1 To _nQtdReg

					_cLinha := ""//reinicio a variável para o caso de não ser informada a linha no arquivo

					_oSelf:IncRegua2("Gravando registros...["+ StrZero(_nI,6) +"] de ["+ StrZero(_nQtdReg,6) +"]" ) 
					If _nLayout == 1
						_cCodPrd := SubStr(_aDados[_nI][02],1,GetSx3Cache("A2_COD","X3_TAMANHO"))
						_cLojPrd := SubStr(_aDados[_nI][02],GetSx3Cache("A2_COD","X3_TAMANHO")+2,GetSx3Cache("A2_COD","X3_TAMANHO")+1+GetSx3Cache("A2_LOJA","X3_TAMANHO"))
						
						If Val( AllTrim( StrTran( StrTran( _aDados[_nI][04] , '.' , '' ) , ',' , '.' ) ) ) > _nLimGor
							aAdd( _aNaoPrc , { _cCodPrd , _cLojPrd , 'Resultado da análise de gordura acima do limite permitido!' } )
							Loop
						EndIf
					ElseIf _nLayout == 4 .Or. _nLayout == 5 .Or. _nLayout == 6
						_cCodPrd := SubStr(_aDados[_nI][02],1,GetSx3Cache("A2_COD","X3_TAMANHO"))
						_cLojPrd := SubStr(_aDados[_nI][02],GetSx3Cache("A2_COD","X3_TAMANHO")+2,GetSx3Cache("A2_COD","X3_TAMANHO")+1+GetSx3Cache("A2_LOJA","X3_TAMANHO"))
						_cData := _aDados[_nI][01]
					Else
						_cCodPrd:= SubStr(_aDados[_nI][05],1,GetSx3Cache("A2_COD","X3_TAMANHO"))
						_cLojPrd:= SubStr(_aDados[_nI][05],GetSx3Cache("A2_COD","X3_TAMANHO")+2,GetSx3Cache("A2_COD","X3_TAMANHO")+1+GetSx3Cache("A2_LOJA","X3_TAMANHO"))
						_cData := _aDados[_nI][02]
						_cHora := '00:00:00'
		
						If _nLayout == 2
							_cLaudo	:= SubStr( _aDados[_nI][12] , 1 , AT( "/" , _aDados[_nI][12] ) - 1 )
							If Val( AllTrim( StrTran( StrTran( _aDados[_nI][07] , '.' , '' ) , ',' , '.' ) ) ) > _nLimGor
								aAdd( _aNaoPrc , { _cCodPrd , _cLojPrd , 'Resultado da análise de gordura acima do limite permitido!' } )
								Loop
							EndIf
						ElseIf _nLayout == 3
							_cLaudo := SubStr( _aDados[_nI][09] , 1 , AT( "/" , _aDados[_nI][09] ) - 1 )
						EndIf
						
						If Empty( _cLaudo )
							MsgStop("Arquivo: "+_aArq[_nJ]+" . Não é possível processar o arquivo selecionado! Não foi possível verificar corretamente as informações do Laudo, data " +;
									"e/ou hora do arquivo. Verifique o arquivo informado e tente novamente.","MGLT00306")
							_lRet := .F.
						EndIf
						
						If _lRet .And. _nLayout == 3
							If !ZLB->( DBSeek( xFilial('ZLB') + _cCodPrd + _cLojPrd + DToS( CtoD( _cData ) ) ) )
								aAdd( _aNaoPrc , { _cCodPrd , _cLojPrd , 'Não foi importada a análise do arquivo tipo "1" para esse produtor!' } )
								Loop
							EndIf
						EndIf
						
					EndIf
					
					//====================================================================================================
					// Verifica se o Produtor atual pertence ao Setor informado
					//====================================================================================================
					If _lRet .And. SA2->( DBSeek( xFilial('SA2') + _cCodPrd + _cLojPrd ) )
						_cAlias := GetNextAlias()
						
						_cFiltro := "% "
						If MV_PAR02 == 1// Somente Donos de Tanque?
							_cFiltro += " AND A2_COD = A2_L_TANQ AND A2_LOJA = A2_L_TANLJ "
						EndIf
						//Nesses layouts sempre são informados os filhos, manualmente
						If _nLayout == 4 .Or. _nLayout == 5 .Or. _nLayout == 6
							_cFiltro += " AND A2_COD = '" + _cCodPrd +"' "
							_cFiltro += " AND A2_LOJA = '" + _cLojPrd +"' "
						Else
							_cFiltro += " AND A2_L_TANQ = '" + _cCodPrd +"' "
							_cFiltro += " AND A2_L_TANLJ = '" + _cLojPrd +"' "
						EndIf
						_cFiltro += " %"

						BeginSql alias _cAlias
							SELECT A2_COD, A2_LOJA, A2_NOME
							FROM %Table:SA2% SA2
							WHERE SA2.D_E_L_E_T_ = ' '
							%exp:_cFiltro%
							AND A2_MSBLQL <> '1' 
							AND A2_L_ATIVO = 'S'
						EndSql
						While (_cAlias)->(!Eof())
							_cLinha := Space(6)
							_cSetor := ""
							If _nLayout == 6 .And. !Empty(_aDados[_nI][06]) .And. ZL3->( DBSeek( xFilial('ZL3') + PadR(AllTrim(_aDados[_nI][6]),6,'0')) )//Conversão burra necessária porque apesar do tipo ser reconhecido como caracter, as validações retornam F para a última coluna do arquivo
								_cLinha := ZL3->ZL3_COD
								_cSetor := ZL3->ZL3_SETOR
								aAdd(_aUTC,{(_cAlias)->A2_COD,(_cAlias)->A2_LOJA , (_cAlias)->A2_NOME, _cSetor, _cLinha})
							ElseIf ZLD->( DBSeek( xFilial('ZLD') + _cCodPrd + _cLojPrd + _cData) )
								_cSetor:= ZLD->ZLD_SETOR
								If _nLayout == 4 .Or. _nLayout == 5 .Or. _nLayout == 6
									_cLinha := ZLD->ZLD_LINROT
								EndIf
								aAdd(_aUTC,{(_cAlias)->A2_COD,(_cAlias)->A2_LOJA , (_cAlias)->A2_NOME, _cSetor, _cLinha})
							ElseIf ZL3->( DBSeek( xFilial('ZL3') + SA2->A2_L_LI_RO ) )
								_cSetor:= ZL3->ZL3_SETOR
								If _nLayout == 4 .Or. _nLayout == 5 .Or. _nLayout == 6
									_cLinha := ZL3->ZL3_COD
								EndIf
								aAdd(_aUTC,{(_cAlias)->A2_COD,(_cAlias)->A2_LOJA , (_cAlias)->A2_NOME, _cSetor, _cLinha})
							Else
								aAdd( _aNaoPrc , { (_cAlias)->A2_COD , (_cAlias)->A2_LOJA , 'Produtor não possui um setor válido para essa Filial no cadastro do Sistema (SA2)!' } )
							EndIf

							(_cAlias)->( DBSkip() )
						EndDo
						(_cAlias)->( DBCloseArea() )
						For _nX := 1 to 7
							If _nLayout == 3
								_cDCRTPF := Posicione("ZL9",1,xFilial("ZL9")+'000007',"ZL9_DESCRI")
								If _nX > 1
									Exit
								EndIf
							ElseIf _nLayout == 4// Importa apenas Crioscopia
								_cDCRTPF := Posicione("ZL9",1,xFilial("ZL9")+'000012',"ZL9_DESCRI")
								If _nX > 1
									Exit
								EndIf
							ElseIf _nLayout == 5// Importa apenas Condenações
								_cDCRTPF := Posicione("ZL9",1,xFilial("ZL9")+'000013',"ZL9_DESCRI")
								If _nX > 1
									Exit
								EndIf
							ElseIf _nLayout == 6// Importa apenas Materia Gorda
								_cDCRTPF := Posicione("ZL9",1,xFilial("ZL9")+_aDados[_nI][05],"ZL9_DESCRI")
								If _nX > 1
									Exit
								EndIf
							Else
								_cDCRTPF := Posicione("ZL9",1,xFilial("ZL9")+StrZero(_nX,6),"ZL9_DESCRI")
							EndIf
	
							For _nZ := 1 To Len(_aUTC)
								_lGrava := .T.
								If ZLB->(DBSeek( xFilial('ZLB') + _aUTC[_nZ][01] + _aUTC[_nZ][02] + DToS(CtoD(_cData))))
									While ZLB->(ZLB_FILIAL+ZLB_RETIRO+ZLB_RETILJ+ZLB_SETOR+ZLB_LINROT) + DToS( ZLB->ZLB_DATA ) == xFilial('ZLB') + _aUTC[_nZ][01] + _aUTC[_nZ][02] + _aUTC[_nZ][04] + _aUTC[_nZ][05]+ DToS(CtoD(_cData))
										If ( _nLayout == 2 .And. ZLB->ZLB_TIPOFX == StrZero(_nX,6));
											.Or. (_nLayout == 3 .And. ZLB->ZLB_TIPOFX == '000007');
											.Or. (_nLayout == 4 .And. ZLB->ZLB_TIPOFX == '000012');
											.Or. (_nLayout == 5 .And. ZLB->ZLB_TIPOFX == '000013');
											.Or. (_nLayout == 6 .And. ZLB->ZLB_TIPOFX == _aDados[1][5])
											aAdd( _aNaoPrc , { _aUTC[_nZ][01] , _aUTC[_nZ][02] , 'Laudo do produtor já importado para ['+ _cDCRTPF +'] com a data ['+ DToC( ZLB->ZLB_DATA ) +']!' } )
											_lGrava := .F.
											Exit
										EndIf
										ZLB->( DBSkip() )
									EndDo
								EndIf
								
								If _lGrava
									If _nLayout == 1
										ZLB->( RecLock( 'ZLB' , .T. ) )
										ZLB->ZLB_FILIAL	:= xFilial('ZLB')
										ZLB->ZLB_LAUDO	:= _cLaudo
										ZLB->ZLB_SETOR	:= _aUTC[_nZ][04]
										ZLB->ZLB_DATA	:= CtoD( _cData )
										ZLB->ZLB_HORA	:= _cHora
										ZLB->ZLB_ETIQTA	:= _aDados[_nI][01]
										ZLB->ZLB_RETIRO	:= _aUTC[_nZ][01]
										ZLB->ZLB_RETILJ	:= _aUTC[_nZ][02]
										ZLB->ZLB_TIPOFX	:= StrZero( _nX , 6 )
										ZLB->ZLB_VLRFX	:= Val( AllTrim( StrTran( StrTran( _aDados[_nI][_nX+3] , '.' , '' ) , ',' , '.' ) ) )
										ZLB->ZLB_DTINCL	:= Date()
										ZLB->ZLB_HRINCL	:= Time()
										ZLB->( MSUnLock() )
										_nProc++
									ElseIf _nLayout == 2
										If _nX > 6
											Exit
										EndIf
										ZLB->( RecLock( 'ZLB' , .T. ) )
										ZLB->ZLB_FILIAL	:= xFilial('ZLB')
										ZLB->ZLB_LAUDO	:= _cLaudo
										ZLB->ZLB_SETOR	:= _aUTC[_nZ][04]
										ZLB->ZLB_DATA	:= CtoD( _cData )
										ZLB->ZLB_HORA	:= _cHora
										ZLB->ZLB_RETIRO	:= _aUTC[_nZ][01]
										ZLB->ZLB_RETILJ	:= _aUTC[_nZ][02]
										ZLB->ZLB_TIPOFX	:= StrZero( _nX , 6 )
										If _nX == 5
											ZLB->ZLB_VLRFX	:= Val(AllTrim(StrTran(StrTran(_aDados[_nI][10],'.',''),',','.'))) - Val(AllTrim(StrTran(StrTran(_aDados[_nI][07],'.',''),',','.')))
										ElseIf _nX > 5
											ZLB->ZLB_VLRFX	:= Val(AllTrim(StrTran(StrTran(_aDados[_nI][_nX+5],'.',''),',','.')))
										Else
											ZLB->ZLB_VLRFX	:= Val(AllTrim(StrTran(StrTran(_aDados[_nI][_nX+6],'.',''),',','.')))
										EndIf
										ZLB->ZLB_DTINCL	:= Date()
										ZLB->ZLB_HRINCL	:= Time()
										ZLB->( MSUnLock() )
										_nProc++
									ElseIf _nLayout == 3
										If _nX > 1
											Exit
										EndIf
										
										ZLB->( RecLock( 'ZLB' , .T. ) )
										ZLB->ZLB_FILIAL	:= xFilial('ZLB')
										ZLB->ZLB_LAUDO	:= _cLaudo
										ZLB->ZLB_SETOR	:= _aUTC[_nZ][04]
										ZLB->ZLB_DATA	:= CtoD( _cData )
										ZLB->ZLB_HORA	:= _cHora
										ZLB->ZLB_RETIRO	:= _aUTC[_nZ][01]
										ZLB->ZLB_RETILJ	:= _aUTC[_nZ][02]
										ZLB->ZLB_TIPOFX	:= '000007'
										ZLB->ZLB_VLRFX	:= Val(AllTrim(StrTran(StrTran(_aDados[_nI][07],'.',''),',','.')))
										ZLB->ZLB_DTINCL	:= Date()
										ZLB->ZLB_HRINCL	:= Time()
										ZLB->( MSUnLock() )
										_nProc++
									ElseIf _nLayout == 4
										_nVlrFx := Val( AllTrim( StrTran( StrTran( _aDados[_nI][4] , '.' , '' ) , ',' , '.' ) ) )
										//Busco no cadastro de faixas e já calculo o valor a ser abatido na litragem do dia
										_cAlias	:= GetNextAlias()
										BeginSql alias _cAlias
										SELECT  Round(SUM(ZLD_QTDBOM)* ZLA_VALOR /100,0) DESCLT
											FROM %Table:ZLD% ZLD, %Table:ZLA% ZLA
										  WHERE ZLD.D_E_L_E_T_ = ' '
										  AND ZLA.D_E_L_E_T_ = ' '
										  AND ZLD.ZLD_FILIAL = %xFilial:ZLD%
										  AND ZLA.ZLA_FILIAL = %xFilial:ZLA%
										  AND ZLD.ZLD_RETIRO = %exp:_aUTC[_nZ][01]%
										  AND ZLD.ZLD_RETILJ = %exp:_aUTC[_nZ][02]%
										  AND ZLD.ZLD_SETOR = ZLA.ZLA_SETOR
										  AND ZLD.ZLD_SETOR = %exp:_aUTC[_nZ][04]%
										  AND ZLD.ZLD_LINROT = %exp:_aUTC[_nZ][05]%
										  AND ZLA.ZLA_FXINI <= %exp:_nVlrFx%
										  AND ZLA.ZLA_FXFIM >= %exp:_nVlrFx%
										  AND ZLD.ZLD_DTCOLE = %exp:CtoD(_cData)%
										  AND ZLA.ZLA_COD = '000012'
										  GROUP BY ZLA_VALOR
										EndSql
										
										ZLB->( RecLock( 'ZLB' , .T. ) )
										ZLB->ZLB_FILIAL	:= xFilial('ZLB')
										ZLB->ZLB_LAUDO	:= ''
										ZLB->ZLB_SETOR	:= _aUTC[_nZ][04]
										ZLB->ZLB_LINROT	:= _aUTC[_nZ][05]
										ZLB->ZLB_DATA	:= CtoD( _aDados[_nI][01] )
										ZLB->ZLB_HORA	:= ''
										ZLB->ZLB_ETIQTA	:= ''
										ZLB->ZLB_RETIRO	:= _aUTC[_nZ][01]
										ZLB->ZLB_RETILJ	:= _aUTC[_nZ][02]
										ZLB->ZLB_TIPOFX	:= '000012'
										ZLB->ZLB_VLRFX	:= _nVlrFx
										ZLB->ZLB_VOLCRI	:= (_cAlias)->DESCLT
										ZLB->ZLB_DTINCL	:= Date()
										ZLB->ZLB_HRINCL	:= Time()
										ZLB->( MSUnLock() )
										
										(_cAlias)->(DBCloseArea())
										_nProc++
									ElseIf _nLayout == 5 .Or. _nLayout == 6
										ZLB->( RecLock( 'ZLB' , .T. ) )
										ZLB->ZLB_FILIAL	:= xFilial('ZLB')
										ZLB->ZLB_LAUDO	:= ''
										ZLB->ZLB_SETOR	:= _aUTC[_nZ][04]
										ZLB->ZLB_LINROT	:= _aUTC[_nZ][05]
										ZLB->ZLB_DATA	:= CtoD( _aDados[_nI][01] )
										ZLB->ZLB_HORA	:= ''
										ZLB->ZLB_ETIQTA	:= ''
										ZLB->ZLB_RETIRO	:= _aUTC[_nZ][01]
										ZLB->ZLB_RETILJ	:= _aUTC[_nZ][02]
										ZLB->ZLB_TIPOFX	:= IIf(_nLayout == 5,'000013',_aDados[_nI][05])
										ZLB->ZLB_VLRFX	:= IIf(_nLayout == 5,0,Val(AllTrim(StrTran(StrTran(_aDados[_nI][04],'.',''),',','.'))))
										ZLB->ZLB_VOLCRI	:= IIf(_nLayout == 5,Int(Val( AllTrim( StrTran( StrTran( _aDados[_nI][4] , '.' , '' ) , ',' , '.' ) ) )),0)
										ZLB->ZLB_DTINCL	:= Date()
										ZLB->ZLB_HRINCL	:= Time()
										ZLB->( MSUnLock() )
										_nProc++
									EndIf
								EndIf
							Next _nZ
						Next _nX
					Else
						aAdd( _aNaoPrc , { _cCodPrd , _cLojPrd , 'Produtor não encontrado no cadastro do Sistema (SA2)!' } )
						Loop
					EndIf
					
					_aUTC := {}
					
				Next _nI		
			End Transaction
		
			// Fecha arquivo	
		    FClose(_nHandle)
		    _cMsg := "Arquivo: "+_aArq[_nJ]+". Foram atualizados "+AllTrim(Str(_nProc))+" produtores com sucesso."
		    If Len( _aNaoPrc ) > 0
			    _cMsg := "Arquivo: "+_aArq[_nJ]+". Foram encontrados "+AllTrim(Str(Len( _aNaoPrc )))+" registros relacionados ao arquivo que não puderam ser gravados corretamente!"
			EndIf
			MsgInfo(_cMsg,"MGLT00307")
			If Len( _aNaoPrc ) > 0
				U_ITListBox( "Arquivo: "+_aArq[_nJ]+". Lista de Produtores não processados/gravados:" , {'Código','Loja','Descrição'} , _aNaoPrc , .F. , 1 )
			EndIf
		EndIf
	Else
		MsgAlert("Arquivo: "+_aArq[_nJ]+". O arquivo está vazio ou é inválido para análise! Verifique o arquivo e tente novamente.","MGLT00308")
	EndIf
Next _nJ
Return

/*
===============================================================================================================================
Programa----------: ValTexto
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 10/12/2018
Descrição---------: Valido se o conteúdo do campo informado é válido.
Parametros--------: _cString,_cTipo,_lRet,_aNaoPrc
Retorno-----------: _cRet
===============================================================================================================================
*/
Static Function ValTexto(_cString,_cTipo,_lRet,_aNaoPrc)
Local _cChar:= ""
Local _nX	:= 0 
Local _cRet	:= ""

For _nX:= 1 To Len(_cString)
	_cChar:=SubStr(_cString, _nX, 1)
	If !IsDigit(_cChar)
		aAdd( _aNaoPrc , { "" ,"" , "Código do "+_cTipo+" possui caracteres alfanuméricos." } )
		_lRet := .F.
		Exit
	EndIf
Next _nX
If _lRet
	_cRet := _cString
EndIf
Return(_cRet)
