/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges |17/09/2019| Chamado 28346. Retirada chamada da função itputx1.
 Lucas Borges |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
 Alex Wallauer|07/09/2021| Chamado 37671. Alterado p/ o parametro ITCATRAC pegar filial(is) do filtro e não da Atual
===============================================================================================================================
*/

#Include "TOTVS.ch"

#Define TITULO	"Relatório de acompanhamento de jornadas"

/*
===============================================================================================================================
Programa----------: RPON011
Autor-------------: Josué Danich Prestes
Data da Criacao---: 24/03/2014
Descrição---------: Relatório de acompanhamento de jornadas - Chamado 25179
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RPON011

Local _aColAux		:= { 0050		, 0000			, 0050			, 0300  			, 0600 	  , 1200		  	, 1800	            , 1980			, 2800		, 2950			}
Local _aCabec		:= { "Filial"	, "Setor"		, "Matrícula"	, "Funcionário"		, "Função",  "Setor"        , "Data do Apont."	, "Marcações"	, "Jornada"	, "Intervalo"	}
Local _aColAjs		:= { 0000		, 0000			, 0015			, -0100 			, 0000   , 0010		  	    , 0000	            , 0020			, 0020		, 0020			}
Local _aCabec2      := { "Filial"	, "Setor"		, "Matrícula"	, "Funcionário"		, "Função", "Data do Apont."	, "Marcações"	, "Jornada", "Intervalo"	}
Local _aDados		:= {}
Local _cPerg		:= "RPON011"
Local oproc         := nil
Local _nnh			:= 0

SET DATE FORMAT TO "DD/MM/YYYY"

While .T.

   If !Pergunte( _cPerg )
      Return
   EndIf

   If Empty(MV_PAR02) .Or.  Empty(MV_PAR03) .Or.  MV_PAR02 > MV_PAR03
      U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo com as 2 datas preenchidas",3)
      Loop
   EndIf

	//============================================================================
	//| Verifica o registro de ponto em busca das informações                    |
	//============================================================================
	FWMsgRun( ,{|oproc| _aDados := RPON011SEL(oproc) } , "Aguarde!" , "Selecionando dados..." )
	
    If Empty(_aDados)
    	U_ITMsg(  "Não foram encontrados registros para exibir! Verifique os parâmetros e tente novamente." , "Atenção" ,,1 )
    	Loop
    EndIf
    
    Exit

EndDo

If MV_PAR11 == 1

	_adados2 := {}
	
	For _nnh := 1 to Len(_aDados)
	
		aAdd(_adados2, {_aDados[_nnh][1],_aDados[_nnh][7],_aDados[_nnh][3],_aDados[_nnh][4],_aDados[_nnh][5],_aDados[_nnh][9],_aDados[_nnh][10],_aDados[_nnh][11],_aDados[_nnh][12] })
	
	Next
	
	FWMsgRun( , {|| U_ITListBox( TITULO , _aCabec2 , _aDados2 , .T. ) },"Exportando dados para planilha, aguarde..." , TITULO  )
	
ElseIf MV_PAR11 == 2

	_adados2 := {}
	
	For _nnh := 1 to Len(_aDados)
	
		aAdd(_adados2, {_aDados[_nnh][1],_aDados[_nnh][2],_aDados[_nnh][3],_aDados[_nnh][4],_aDados[_nnh][5],_aDados[_nnh][7],_aDados[_nnh][9],_aDados[_nnh][10],_aDados[_nnh][11],_aDados[_nnh][12] })
	
	Next
	
	FWMsgRun( , {|oproc| RPON011PRT( _aCabec , _aColAux , _aColAjs , _aDados2) }, "Imprimindo dados, aguarde..." , TITULO  )
	
ElseIf MV_PAR11 == 3

	FWMsgRun( , {|oproc| RPON011W() }, "Enviando dados, aguarde..." , TITULO  )
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: RPON011SEL
Autor-------------: Alexandre Villar
Data da Criacao---: 24/03/2014
Descrição---------: Carga de dados para o relatório
Parametros--------: oproc - objeto da barra de processmento
Retorno-----------: _aRet - dados coletados do banco
===============================================================================================================================
*/
Static Function RPON011SEL(oproc)

Local _aRet			:= {}
Local _cAlias		:= GetNextAlias()
Local _cAlias2		:= GetNextAlias()
Local _cAlias3		:= GetNextAlias()
Local _cAlias4		:= GetNextAlias()
Local _aFiliais		:= {}
Local _cQuery		:= ""
Local _nTot			:= 0
Local _nI			:= 0
Local _nnj			:= 0
Local _nnd			:= 0

Default oproc := nil


_aFiliais			:= StrTokArr( AllTrim(MV_PAR01) , ";" )

If Empty(_aFiliais)

	U_ITMsg(  "Não foram informadas Filiais válidas para o processamento!" , "Atenção!" ,,1 )

EndIf

For _nI := 1 To Len( _aFiliais )

	If ValType(oproc) = "O"

		oproc:cCaption := ("Lendo funcionários para filial " + _aFiliais[_nI] + "...")
		ProcessMessages()
 
	EndIf
	
	_cQuery := " SELECT "
	_cQuery += " R_E_C_N_O_ RECNO  "	  
	_cQuery += " FROM "+ RetSqlName("SRA") +" SRA "
	_cQuery += " WHERE "
	_cQuery += " 	RA_FILIAL = '"+ _aFiliais[_nI] +"' "
	_cQuery += " AND D_E_L_E_T_	= ' ' "
	   
	
	If !Empty(MV_PAR04) .And. !Empty(MV_PAR05)
	
		_cQuery += " AND RA_MAT >= '" + MV_PAR04 + "' AND RA_MAT <= '" + MV_PAR05 + "' "
		
	EndIf
	
	If !Empty(MV_PAR06)
	
		_cQuery += "						AND trim(SRA.RA_CATFUNC)	IN "+ FormatIn( RTrim( MV_PAR06 ) , ";" )
		
	EndIf 
	
	If !Empty(MV_PAR07)
	
		_cQuery += "						AND TRIM(SRA.RA_CARGO)	IN "+ FormatIn( RTrim( MV_PAR07 ) , ";" )
		
	EndIf 
	
	If !Empty(MV_PAR08)
	
		_cQuery += "						AND TRIM(SRA.RA_CODFUNC)	IN "+ FormatIn( RTrim( MV_PAR08 ) , ";" )
		
	EndIf 
	
	If !Empty(MV_PAR09)
	
		_cQuery += "						AND TRIM(SRA.RA_I_SETOR)	IN "+ FormatIn( RTrim( MV_PAR09 ) , ";" )
		
	EndIf 
	
	If !Empty(MV_PAR10)
	
		If " " $ rtrim(MV_PAR10)
		
			_cQuery += " 						AND (trim(SRA.RA_SITFOLH)  IN "+ FormatIn( RTrim( MV_PAR10 ) , ";" ) + " OR SRA.RA_SITFOLH = ' ') "
			
		Else
		
			_cQuery += " 						AND trim(SRA.RA_SITFOLH)  IN "+ FormatIn( RTrim( MV_PAR10 ) , ";" )
		
		EndIf 
	
	EndIf
	
	If Select(_cAlias) > 0

		(_cAlias)->( DBCloseArea() )

	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
	(_cAlias)->( DBEval( {|| _nTot++ } ) )
	(_cAlias)->( DBGoTop() )
	_nni := 1

	While (_cAlias)->( !Eof() )	
		If ValType(oproc) = "O"

			oproc:cCaption := ("Lendo funcionários para filial " + _aFiliais[_nI] + ", funcionário " + StrZero(_nni,6) + " de " + StrZero(_nTot,6) + "...")
			ProcessMessages()
 
		EndIf
		
		_nni++
	
		SRA->(DBGoTo((_cAlias)->RECNO))
		
		//carrega id do funcionário
		_cQuery :=  "select idcolab from suricato.tbcolab where numepis = '" + AllTrim(SRA->RA_PIS) + "'"
		
		If Select(_cAlias2) > 0
			DBSelectArea(_cAlias2)
			(_cAlias2)->(DBCloseArea())
		EndIf
		
		DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias2 , .T. , .F. )
		DBSelectArea(_cAlias2)
		
		If (_cAlias2)->( !Eof() )
		
			//Carrega crachas do funcionario no periodo
			_cQuery :=  "select icard,datainic,horainic,datafina,horafina from suricato.tbhistocrach where idcolab = " + AllTrim(Str((_cAlias2)->idcolab))   + " and datainic <= TO_DATE('" + DToS(MV_PAR03) + "', 'yyyymmdd') 
			_cQuery +=  "and (datafina >= TO_DATE('" + DToS(MV_PAR03) + "', 'yyyymmdd') or datafina = TO_DATE('19001231', 'yyyymmdd'))
		
			If Select(_cAlias3) > 0
		
				DBSelectArea(_cAlias3)
				(_cAlias3)->(DBCloseArea())
			
			EndIf
		
			DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias3 , .T. , .F. )
			DBSelectArea(_cAlias3)
			
			_acrachas := {}
		
			While (_cAlias3)->( !Eof() )
			
				aAdd(_acrachas, {(_cAlias3)->icard,(_cAlias3)->datainic,(_cAlias3)->horainic,(_cAlias3)->datafina,(_cAlias3)->horafina} )
				
				(_cAlias3)->(DBSkip())
				
			EndDo
					
			If Len(_acrachas) > 0
			
				//Carrega marcações do funcionario no periodo
				For _nnj := 1 to Len(_acrachas)
				
					_cQuery :=	" select dataaces,horaaces,direaces,CODICOLE from suricato.tbmarcaacess where " 
					_cQuery +=	" dataaces >= TO_DATE('" + DToS(MV_PAR02) + "', 'yyyymmdd') " //data inicio do relatorio 
					_cQuery +=	" and dataaces <= TO_DATE('" + DToS(MV_PAR03) + "', 'yyyymmdd') " //data fim do relatorio 
					_cQuery +=	" and ( ( dataaces = TO_DATE('" + DToS(_acrachas[_nnj][2]) + "', 'yyyymmdd') and horaaces >= 1) "
					_cQuery +=	"                        or dataaces > TO_DATE('" + DToS(_acrachas[_nnj][2]) + "', 'yyyymmdd')) " //data inicio do cracha
					
					//inclui filtro de data final do cracha só se a data final For diferente 31/12/1900
					If DToS(_acrachas[_nnj][4]) != "19001231"
					
						_cQuery +=	" and ( ( dataaces = TO_DATE('" + DToS(_acrachas[_nnj][4]) + "', 'yyyymmdd') and horaaces <= 1) "
						_cQuery +=	"                         or dataaces < TO_DATE('" + DToS(_acrachas[_nnj][4]) + "', 'yyyymmdd')) " //data final do cracha
						
					EndIf
					
					_cQuery +=	" and icard = " + AllTrim(Str(_acrachas[_nnj][1])) 
					_cQuery +=  " and tipoaces = 1 " //Acesso com sucesso na catraca
                    cFilSalva:=cFilAnt
                    cFilAnt  :=SRA->RA_FILIAL
					_cQuery +=  " and codicole in  " + FormatIn(u_itgetmv("ITCATRAC","1;2"),";") 
                    cFilAnt  :=cFilSalva
					_cQuery +=  " ORDER BY dataaces,horaaces"
		
					If Select(_cAlias4) > 0
		
						DBSelectArea(_cAlias4)
						(_cAlias4)->(DBCloseArea())
			
					EndIf
		
					DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias4 , .T. , .F. )
					DBSelectArea(_cAlias4)
					
					ajorns := {}
					_dultima := (_cAlias4)->dataaces
					
					While (_cAlias4)->( !Eof() )
					
						_nhoras := int((_cAlias4)->horaaces / 60)
						_nminutos :=  (_cAlias4)->horaaces - ((int((_cAlias4)->horaaces / 60))*60) 
						_choras := (_cAlias4)->direaces +"("+AllTrim(Str((_cAlias4)->CODICOLE))+") "+ StrZero(_nhoras,2) + ":" + StrZero(_nminutos,2)
					
						If (_cAlias4)->dataaces == _dultima
					
							If (_cAlias4)->direaces == "E"
							
								If Len(ajorns) = 0 .Or. (Len(ajorns) > 0 .And. ajorns[Len(ajorns)][2] >= 0) //Validação contra dupla marcação de entrada
						
									aAdd(ajorns,{(_cAlias4)->horaaces,-1})
									
								EndIf
								
							ElseIf (_cAlias4)->direaces == "S" .And. Len(ajorns) > 0 .And. ajorns[Len(ajorns)][2] = -1
							
								ajorns[Len(ajorns)][2] := (_cAlias4)->horaaces
								
							EndIf
							
						Else
						
							//Se virou o dia sem sair da fabrica marca final da jornada do dia as 23:59
							If (_cAlias4)->direaces == "S" .And. Len(ajorns) > 0 .And. ajorns[Len(ajorns)][2] = -1
							
								ajorns[Len(ajorns)][2] := 1439
								
							EndIf
							
							//Soma total da jornada e intervalo do dia
							_ntotdia := 0
							_nintdia := 0
							
							For _nnd := 1 to Len(ajorns)
							
								If ajorns[_nnd][1] >= 0 .And. ajorns[_nnd][2] >= 0
								
									_ntotdia := _ntotdia + ajorns[_nnd][2] - ajorns[_nnd][1]
									
									If _nnd > 1
									
										_nintdia := _nintdia + ajorns[_nnd][1] - ajorns[_nnd-1][2]
									
									EndIf
									
								EndIf
							
							Next
							
							//Registra jornada do dia e reinicia contador 
							_nnk := aScan(_aRet,{|_vAux| _vAux[1]==AllTrim(SRA->RA_FILIAL) .And.  _vAux[3]==AllTrim(SRA->RA_MAT) .And. _vAux[9]==AllTrim(DToC(_dultima)) }) 
							
							_aRet[_nnk][11] :=   StrZero(int(_ntotdia/60),2) + ":" + StrZero(_ntotdia-(int(_ntotdia/60)*60),2)
							_aRet[_nnk][12] :=   StrZero(int(_nintdia/60),2) + ":" + StrZero(_nintdia-(int(_nintdia/60)*60),2)
							
							ajorns := {}
							
							//Se virou o dia sem sair da fabrica registra entrada à 12:00 
							If (_cAlias4)->direaces == "S" 
							
								aAdd(ajorns,{0,(_cAlias4)->horaaces})
								
							Else
							
								aAdd(ajorns,{(_cAlias4)->horaaces,-1})
							
							EndIf
							
							//vira ultimo dia
							_dultima := (_cAlias4)->dataaces
						
						EndIf
					
						_nnp := aScan(_aRet,{|_vAux| _vAux[1]==AllTrim(SRA->RA_FILIAL) .And.  _vAux[3]==AllTrim(SRA->RA_MAT) .And. _vAux[9]==AllTrim(DToC((_cAlias4)->dataaces)) }) 
					
						If Len(AllTrim(_choras)) > 45
						
							_choras := SubStr(AllTrim(_choras),1,45) + "..."
							
						EndIf
					
						If _nnp == 0
					
							aAdd( _aRet , {	AllTrim(SRA->RA_FILIAL)	,; //Filial
							AllTrim(SRA->RA_I_SETOR)						,; //Setor
							AllTrim(SRA->RA_MAT)						,; //Matrícula
							AllTrim(Capital(AllTrim(SRA->RA_NOME )))    ,; //Funcionário
							AllTrim(Posicione("SRJ",1,xFilial("SRJ")+SRA->RA_CODFUNC,"RJ_DESC")) + Space(5)	,; //Desc. Funçao 
							AllTrim(Posicione("ZAK",1,xFilial("ZAK")+SRA->RA_I_SETOR,"ZAK_COD")) 	,; //Codigo Setor 
							AllTrim(ZAK->ZAK_DESCRI) + Space(5)					,; //Desc. Setor
							AllTrim(DToC(SRA->RA_ADMISSA))				,; //Dt Admissao 
							AllTrim(DToC((_cAlias4)->dataaces))				      ,; //Data do Apontamento
							AllTrim(_choras)						,; //Marcações da Data
							AllTrim(" ")						,; //Jornada
							AllTrim(" ")				}) 				   //Intervalo
						
						Else
						
							_aRet[_nnp][10] := _aRet[_nnp][10] + " - " + _choras
						
						EndIf
						
						(_cAlias4)->(DBSkip())
						
					EndDo
		
					//Faz ultima jornada
							
					//Soma total da jornada do dia
					_ntotdia := 0
					_nintdia := 0
							
					For _nnd := 1 to Len(ajorns)
							
						If ajorns[_nnd][1] >= 0 .And. ajorns[_nnd][2] >= 0
								
							_ntotdia := _ntotdia + ajorns[_nnd][2] - ajorns[_nnd][1]
							
							If _nnd > 1
									
								_nintdia := _nintdia + ajorns[_nnd][1] - ajorns[_nnd-1][2]
									
							EndIf
									
						EndIf
							
					Next
							
					//Registra jornada do dia e reinicia contador 
					_nnk := aScan(_aRet,{|_vAux| _vAux[1]==AllTrim(SRA->RA_FILIAL) .And.  _vAux[3]==AllTrim(SRA->RA_MAT) .And. _vAux[9]==AllTrim(DToC(_dultima)) }) 
							
					If _ntotdia > 0 .And. _nnk > 0
					
						_aRet[_nnk][11] :=   StrZero(int(_ntotdia/60),2) + ":" + StrZero(_ntotdia-(int(_ntotdia/60)*60),2)
						_aRet[_nnk][12] :=   StrZero(int(_nintdia/60),2) + ":" + StrZero(_nintdia-(int(_nintdia/60)*60),2)
						
					ElseIf _nnk > 0
					
						_aRet[_nnk][11] := " "
						_aRet[_nnk][12] := " "
					
					EndIf					
		
				Next
		
			EndIf
		
		EndIf
		
		(_cAlias)->(DBSkip())
		
	EndDo

Next _nI

Return( _aRet )

/*
===============================================================================================================================
Programa----------: RPON011PRT
Autor-------------: Alexandre Villar
Data da Criacao---: 28/04/2014
Descrição---------: Chamada de Impressao de Relatório dos dados de marcação de Ponto manual
Parametros--------: _aCabec	- Cabeçalho do Relatório
------------------: _aColAux	- Posicionamento das Colunas
------------------: _aColAjs	- Ajuste de posicionamento dos conteúdos
------------------: _aDados	- Dados do Relatório
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RPON011PRT( _aCabec , _aColAux , _aColAjs , _aDados )

Local _aResTot	:= {}
Local _nLinha		:= 300
Local _nTotCol	:= Len(_aCabec)
Local _nI			:= 0
Local _nX			:= 0
Local _nCont		:= 0
Local _nConFil	:= 0
Local _nTotFun	:= 0
Local _nConTot	:= 0
Local _nJornada	:= 0
Local _nInterv	:= 0
Local _nJorSet	:= 0
Local _nIntSet	:= 0
Local _cChvAux	:= ""
Local _cSetAux	:= ""
Local _cTxtCab	:= ""
Local _oPrint		:= Nil
Local _oFont01	:= TFont():New( "Arial" , 9 , 14 ,.F.,.T.,,.T.,,.T.,.F.)
Local _oFont02	:= TFont():New( "Arial" , 9 , 08 ,.F.,.T.,,.T.,,.T.,.F.)
Local _oFont03	:= TFont():New( "Arial" , 9 , 08 ,.F.,.F.,,.T.,,.T.,.F.)
Local _oFont04	:= TFont():New( "Arial" , 9 , 10 ,.F.,.T.,,.T.,,.T.,.F.)

//| Inicializa o objeto do relatório                                          |
_oPrint := TMSPrinter():New( TITULO )
_oPrint:Setup()
_oPrint:SetLandscape()
_oPrint:SetPaperSize(9)

//| Processa a impressão dos dados                                            |
For _nI := 1 To Len(_aDados)
	
	//| Inicializa as variáveis de controle                                       |
	_cChvAux		:= _aDados[_nI][01] + _aDados[_nI][02] + _aDados[_nI][03]
	_nJornada	:= 0
	_nInterv		:= 0
	
	//| Valida o controle do Setor atual                                          |
	If Empty(_cSetAux)
		
		//| Inicializa a primeira página do relatório                                 |
		_cSetAux := _aDados[_nI][01] + _aDados[_nI][02]
		
		_cTxtCab	:= "Filial: "+	_aDados[_nI][01] +" - "+ AllTrim( Posicione("ZZM",1,xFilial("ZZM")+_aDados[_nI][01],"ZZM_DESCRI") ) +" | "
		_cTxtCab	+= "Setor: "+	_aDados[_nI][02] +" - "+ AllTrim( Posicione("ZAK",1,xFilial("ZAK")+_aDados[_nI][02],"ZAK_DESCRI") )
		
		_nLinha	:= 50000
		_nTotFun	:= 1
		
		//| Verifica o posicionamento da página                                       |
		RPON011VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 , .F. )
		
		//| Encerra Lote do Setor atual                                               |
	ElseIf (_cSetAux <> _aDados[_nI][01] + _aDados[_nI][02])
		
		If _nLinha > 2900
			
			_nLinha := 50000
			//| Verifica o posicionamento da página                                       |
			RPON011VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
			
		EndIf
		
		//| Formata a informação para a impressão                                     |
		_nJorSet		:= Round( ( _nJorSet / _nTotFun )	, 0 )
		_nIntSet		:= Round( ( _nIntSet / _nTotFun )	, 0 )
		
		__cMedInt		:= StrZero( Int( _nJorSet / 60 ) , 2 ) +":"+ StrZero( Mod( _nJorSet , 60 ) , 2 )
		cMedInt		:= StrZero( Int( _nIntSet / 60 ) , 2 ) +":"+ StrZero( Mod( _nIntSet , 60 ) , 2 )
		
		//| Formata a informação para a impressão                                     |
		aAdd( _aResTot , {	SubStr(_cSetAux,1,2) +" - "+ AllTrim( Posicione("ZZM",1,xFilial("ZZM")+_aDados[_nI][01],"ZZM_DESCRI") )	,;
		AllTrim( Posicione( "ZAK" , 1 , xFilial("ZAK") + SubStr(_cSetAux,3,6) , "ZAK_DESCRI" ) )					,;
		StrZero( _nTotFun , 6 )																					,;
		StrZero( _nConFil , 6 )																					,;
		__cMedInt																									,;
		cMedInt																									})
		
		_oPrint:Say( _nLinha , 0050 , "Setor: "+ AllTrim(Posicione("ZAK",1,xFilial("ZAK")+SubStr(_cSetAux,3,6),"ZAK_DESCRI"))	, _oFont02 )
		_nLinha += 040
		_oPrint:Say( _nLinha , 0050 , "Total de Funcionários: "+ StrZero( _nTotFun , 6 )								 		, _oFont02 )
		_oPrint:Say( _nLinha , 1000 , "Total de Marcações: "+ StrZero( _nConFil , 6 )									 		, _oFont02 )
		_nLinha += 040
		_oPrint:Say( _nLinha , 0050 , "Média de Jornadas: "+ __cMedInt															, _oFont02 )
		_oPrint:Say( _nLinha , 1000 , "Média de Intervalos: "+ cMedInt														, _oFont02 )
		_nLinha += 040
		_oPrint:Line( _nLinha + 020 , 0 , _nLinha + 020 , 5000 )
		_oPrint:Line( _nLinha + 021 , 0 , _nLinha + 021 , 5000 )
		_oPrint:Line( _nLinha + 022 , 0 , _nLinha + 022 , 5000 )
		_oPrint:Line( _nLinha + 023 , 0 , _nLinha + 023 , 5000 )
		_oPrint:Line( _nLinha + 024 , 0 , _nLinha + 024 , 5000 )
		
		//| Reinicia as variáveis de controle                                         |
		_nConFil	:= 0
		_nJorSet	:= 0
		_nIntSet	:= 0
		_nLinha	:= 50000
		_nTotFun	:= 1
		
		_cSetAux	:= _aDados[_nI][01] + _aDados[_nI][02]
		
		_cTxtCab	:= "Filial: "+	_aDados[_nI][01] +" - "+ AllTrim( Posicione("ZZM",1,xFilial("ZZM")+_aDados[_nI][01],"ZZM_DESCRI") ) +" | "
		_cTxtCab	+= "Setor: "+	_aDados[_nI][02] +" - "+ AllTrim( Posicione("ZAK",1,xFilial("ZAK")+_aDados[_nI][02],"ZAK_DESCRI") )
		
	Else
		
		_nLinha += 020
		_nTotFun++
		
	EndIf
	
	//| Processa os dados do Funcionário Atual                                    |
	While _nI <= Len(_aDados) .And. _cChvAux == _aDados[_nI][01] + _aDados[_nI][02] + _aDados[_nI][03]
		
		//| Registra o processamento                                                  |
		_nCont++
		_nConFil++
		
		//| Verifica o posicionamento da página                                       |
		RPON011VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
		
		//| Guarda valores para o cálculo das médias                                  |
		_nJornada	+= ( Val( SubStr( _aDados[_nI][09] , 1 , 2 ) ) * 60 ) + Val( SubStr( _aDados[_nI][09] , 4 , 2 ) )
		_nInterv		+= ( Val( SubStr( _aDados[_nI][10] , 1 , 2 ) ) * 60 ) + Val( SubStr( _aDados[_nI][10] , 4 , 2 ) )
		
		//| Imprime os registros do Funcionário atual                                 |
		For _nX := 3 To _nTotCol
			_oPrint:Say( _nLinha , _aColAux[_nX] + _aColAjs[_nX] , _aDados[_nI][_nX] , _oFont03 )
		Next _nX
		_nLinha += 030
		
		_nI++
	EndDo
	
	//| Verifica o posicionamento da página                                       |
	RPON011VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
	
	//| Calcula a média dos apontamentos                                          |
	_nJornada	:= Round( ( _nJornada / _nCont )	, 0 )
	_nInterv		:= Round( ( _nInterv / _nCont )	, 0 )
	
	//| Grava a média dos apontamentos para totalizador do Setor                  |
	_nJorSet		+= _nJornada
	_nIntSet		+= _nInterv
	
	//| Formata a informação para a impressão                                     |
	__cMedInt		:= StrZero( Int( _nJornada / 60 )	, 2 ) +":"+ StrZero( Mod( _nJornada	, 60 ) , 2 )
	cMedInt		:= StrZero( Int( _nInterv / 60 )		, 2 ) +":"+ StrZero( Mod( _nInterv	, 60 ) , 2 )
	
	//| Imprime o totalizador do Funcionário                                      |
	_oPrint:Line( _nLinha + 020 , 0 , _nLinha + 020 , 5000 )
	_oPrint:Line( _nLinha + 021 , 0 , _nLinha + 021 , 5000 )
	_oPrint:Line( _nLinha + 022 , 0 , _nLinha + 022 , 5000 )
	_nLinha += 030
	_oPrint:Say( _nLinha , _aColAux[01] , "Total de registros do Funcionário: "+ AllTrim( Transform( _nCont , "@E 999,999,999,999" ) )	, _oFont02 )
	_oPrint:Say( _nLinha , _aColAux[08] , "Média de Apontamento: "																		, _oFont02 )
	_oPrint:Say( _nLinha , _aColAux[09] + 015 , __cMedInt																				, _oFont02 )
	_oPrint:Say( _nLinha , _aColAux[10] + 020 , cMedInt																				, _oFont02 )
	_nLinha += 030
	_oPrint:Line( _nLinha + 020 , 0 , _nLinha + 020 , 5000 )
	_oPrint:Line( _nLinha + 021 , 0 , _nLinha + 021 , 5000 )
	_oPrint:Line( _nLinha + 022 , 0 , _nLinha + 022 , 5000 )
	_nLinha += 030
	
	//| Ajusta as variáveis de controle                                           |
	_nI--
	_nCont := 0
	
Next _nI

//| Considera o único ou último setor na totalização - Início|
If _nLinha > 2900
			
	_nLinha := 50000
	//| Verifica o posicionamento da página                                       |
	RPON011VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
			
EndIf
		
//| Formata a informação para a impressão                                     |
_nJorSet		:= Round( ( _nJorSet / _nTotFun )	, 0 )
_nIntSet		:= Round( ( _nIntSet / _nTotFun )	, 0 )
		
__cMedInt		:= StrZero( Int( _nJorSet / 60 ) , 2 ) +":"+ StrZero( Mod( _nJorSet , 60 ) , 2 )
cMedInt		:= StrZero( Int( _nIntSet / 60 ) , 2 ) +":"+ StrZero( Mod( _nIntSet , 60 ) , 2 )
		
//| Formata a informação para a impressão                                     |
aAdd( _aResTot , {	SubStr(_cSetAux,1,2) +" - "+ AllTrim( Posicione("ZZM",1,xFilial("ZZM")+SubStr(_cChvAux,1,2),"ZZM_DESCRI") )	,;
					AllTrim( Posicione( "ZAK" , 1 , xFilial("ZAK") + SubStr(_cSetAux,3,6) , "ZAK_DESCRI" ) )					,;
					StrZero( _nTotFun , 6 )																					,;
					StrZero( _nConFil , 6 )																					,;
					__cMedInt																									,;
					cMedInt																									})
		
_oPrint:Say( _nLinha , 0050 , "Setor: "+ AllTrim(Posicione("ZAK",1,xFilial("ZAK")+SubStr(_cSetAux,3,6),"ZAK_DESCRI"))	, _oFont02 )
_nLinha += 040
_oPrint:Say( _nLinha , 0050 , "Total de Funcionários: "+ StrZero( _nTotFun , 6 )								 		, _oFont02 )
_oPrint:Say( _nLinha , 1000 , "Total de Marcações: "+ StrZero( _nConFil , 6 )									 		, _oFont02 )
_nLinha += 040
_oPrint:Say( _nLinha , 0050 , "Média de Jornadas: "+ __cMedInt															, _oFont02 )
_oPrint:Say( _nLinha , 1000 , "Média de Intervalos: "+ cMedInt														, _oFont02 )
_nLinha += 040
_oPrint:Line( _nLinha + 020 , 0 , _nLinha + 020 , 5000 )
_oPrint:Line( _nLinha + 021 , 0 , _nLinha + 021 , 5000 )
_oPrint:Line( _nLinha + 022 , 0 , _nLinha + 022 , 5000 )
_oPrint:Line( _nLinha + 023 , 0 , _nLinha + 023 , 5000 )
_oPrint:Line( _nLinha + 024 , 0 , _nLinha + 024 , 5000 )

//|========================================================
//| Considera o único ou último setor na totalização - Fim|
//|========================================================
		
//| Reinicia as variáveis de controle                                         |
_nConFil	:= 0
_nJorSet	:= 0
_nIntSet	:= 0
_nLinha	:= 50000
_nTotFun	:= 1
		
_cTxtCab	:= "Filial: "+	SubStr(_cChvAux,1,2) +" - "+ AllTrim( Posicione("ZZM",1,xFilial("ZZM")+SubStr(_cChvAux,1,2),"ZZM_DESCRI") ) +" | "
_cTxtCab	+= "Setor: "+	SubStr(_cSetAux,3,6) +" - "+ AllTrim( Posicione("ZAK",1,xFilial("ZAK")+SubStr(_cSetAux,3,6),"ZAK_DESCRI") )

_nLinha	:= 50000
_cTxtCab	:= "Resumo Geral do Relatório por Filial/Setor"
_aColAux := { ,, 0050 , 0600 , 1350 , 1650 , 1900 , 2150 }
_aColAjs := { ,, 0000 , 0000 , 0090 , 0080 , 0065 , 0080 }
_aCabec	:= { ,, "Filial" , "Setor" , "Total Funcionários" , "Total Marcações" , "Média Jornada" , "Média Intervalos" }
_cSetAux	:= ""
_nTotFun	:= 0
_nConTot := 0
_nCont	:= 0
_nConFil	:= 0

//| Verifica o posicionamento da página                                       |
RPON011VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )

If !Empty(_aResTot)
	
	For _nI := 1 To Len( _aResTot )
		
		If !Empty(_cSetAux) .And. _cSetAux <> SubStr( _aResTot[_nI][01] , 1 , 2 )
			
			//| Verifica o posicionamento da página                                       |
			RPON011VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
			
			//| Grava o fechamento da Filial no relatório                                 |
			_nLinha += 020
			_oPrint:Say( _nLinha , _aColAux[03] , "Total Geral da Filial ================= [ Funcionários: "+ StrZero( _nCont , 6 ) +" ] / [ Marcações: "+ StrZero( _nConFil , 6 ) +" ]" , _oFont02 )
			_nLinha += 040
			_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
			_nLinha += 050
			
			_nCont	:= 0
			_nConFil	:= 0
			
		EndIf
		
		_cSetAux := SubStr( _aResTot[_nI][01] , 1 , 2 )
		
		If _nLinha > 3100
			
			_nLinha := 50000
			
			//| Verifica o posicionamento da página                                       |
			RPON011VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
			
		EndIf
		
		//| Imprime o resumo do relatório                                             |
		For _nX := 1 To Len( _aResTot[_nI] )
			_oPrint:Say( _nLinha , _aColAux[_nX+2] + _aColAjs[_nX+2] , _aResTot[_nI][_nX] , _oFont02 )
		Next _nX
		
		//| Registra o total geral do relatório                                       |
		_nTotFun += Val( _aResTot[_nI][03] )
		_nCont	+= Val( _aResTot[_nI][03] )
		_nConTot	+= Val( _aResTot[_nI][04] )
		_nConFil	+= Val( _aResTot[_nI][04] )
		
		_nLinha += 035
		_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
		_nLinha += 020
		
	Next _nI
	
	//| Verifica o posicionamento da página                                       |
	RPON011VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
	
	//| Grava o fechamento da última Filial do relatório                          |
	_nLinha += 020
	_oPrint:Say( _nLinha , _aColAux[03] , "Total Geral da Filial ================= [ Funcionários: "+ StrZero( _nCont , 6 ) +" ] / [ Marcações: "+ StrZero( _nConFil , 6 ) +" ]" , _oFont02 )
	_nLinha += 040
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
	_nLinha += 050
	
	//| Verifica o posicionamento da página                                       |
	RPON011VPG( @_oPrint , @_nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 )
	
	//| Grava o fechamento do relatório                                           |
	_nLinha += 050
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
	_nLinha += 020
	_oPrint:Say( _nLinha , _aColAux[03] , "==== Total Geral ==== [ Funcionários: "+ StrZero( _nTotFun , 6 ) +" ] / [ Marcações: "+ StrZero( _nConTot , 6 ) +" ] ====" , _oFont02 )
	_nLinha += 040
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 )
	
	
Else
	//| Imprime o total geral do relatório                                        |
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha += 7
	_oPrint:Say( _nLinha , _aColAux[01] , "Não foram encontrados registros para gerar o resumo do relatório." , _oFont01 ) ; _nLinha += 060
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha++
	_oPrint:Line( _nLinha , 0 , _nLinha , 5000 ) ; _nLinha += 7
	
EndIf

//| Starta o objeto de impressão                                              |
_oPrint:Preview()

Return

/*
===============================================================================================================================
Programa----------: RPON011P
Autor-------------: Alexandre Villar
Data da Criacao---: 29/04/2014
===============================================================================================================================
Descrição---------: Validação das Perguntas da Rotina
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RPON011P( _nOpc )

Local _lRet		:= .T. //Se retornar .F. nao deixa sair do campo
Local _cNomeVar	:= ReadVar()
Local _xVarAux	:= &(_cNomeVar)
Local _aArea	:= FWGetArea()
Local _cEmpAux	:= cEmpAnt
Local _aAcesso	:= FWEmpLoad(.F.)
Local _aDadAux	:= {}
Local _nI		:= 0
Local _nX		:= 0

Do Case
	
	Case _nOpc == 1 //Filiais Consideradas ?
		
		//-- Verifica se o campo esta vazio --//
		If Empty(_xVarAux)
			
			U_ITMsg(  "É obrigatório informar o filtro de Filiais, clique em 'selecionar todas' para utilizar todas as Filiais." , "Atenção!" ,,1 )
			_lRet := .F.
			
			//-- Verifica se o campo foi preenchido com conteudo valido --//
		Else
			
			_aDadAux := U_ITLinDel( AllTrim(_xVarAux) )
			
			For _nI := 1 To Len(_aDadAux)
				
				_lRet := .F.
				
				For _nX := 1 To Len(_aAcesso)
					
					If _aDadAux[_nI] == _aAcesso[_nX][03]
						_lRet := .T.
					EndIf
					
				Next _nX
				
				If !_lRet
					U_ITMsg(  "O usuário não tem acesso às 'Filiais' informadas! Verifique os dados digitados." ,"Atenção!" ,,1 )
					Exit
				EndIf
				
				_lRet := .F.
				
				DBSelectArea("SM0")
				SM0->( DBGoTop() )
				While SM0->(!Eof())
					
					If SM0->M0_CODIGO == _cEmpAux .And. AllTrim(SM0->M0_CODFIL) == _aDadAux[_nI]
						_lRet := .T.
						Exit
					EndIf
					
					SM0->( DBSkip() )
				EndDo
				
				If !_lRet
					U_ITMsg(  "As 'Filiais' informadas não são válidas! Verifique os dados digitados." , "Atenção!" ,,1)
					Exit
				EndIf
				
			Next _nI
			
		EndIf
		
	Case _nOpc == 2 //Categorias a Imp. ?
		
		If Empty(_xVarAux)
			
			U_ITMsg(  "É obrigatório informar o filtro de Categorias Funcionais, clique em 'selecionar todas' para utilizar todas as Categorias." , "Atenção!" ,,1 )
			_lRet := .F.
			
		Else
			
			_aDadAux := U_ITLinDel( AllTrim(_xVarAux) )
			
			For _nI := 1 To Len(_aDadAux)
				
				DBSelectArea("SX5")
				SX5->( DBSetOrder(1) )
				SX5->( DBGoTop() )
				If !SX5->( DBSeek( xFilial("SX5") + "28" + _aDadAux[_nI] ) )
					
					U_ITMsg(  "As 'Categorias Funcionais' informadas não são válidas! Verifique os dados digitados." ,"Atenção!" ,,1 )
					_lRet := .F.
					Exit
					
				EndIf
				
			Next _nI
			
		EndIf
		
	Case _nOpc == 3 //Situações ?
		
		If Empty(_xVarAux)
			
			&(_cNomeVar) := " ;"
			
		Else
			
			_aDadAux := U_ITLinDel( _xVarAux )
			
			For _nI := 1 To Len(_aDadAux)
				
				DBSelectArea("SX5")
				SX5->( DBSetOrder(1) )
				SX5->( DBGoTop() )
				If !SX5->( DBSeek( xFilial("SX5") + "31" + _aDadAux[_nI] ) )
					
					U_ITMsg( "As 'Situações na Folha' informadas não são válidas! Verifique os dados digitados." ,"Atenção!" , ,1)
					_lRet := .F.
					Exit
					
				EndIf
				
			Next _nI
			
		EndIf
		
		//| Verifica se o campo "Time()" foi preenchido corretamente                  |
	Case _nOpc == 4
		
		If	!( SubStr(	_xVarAux , 1 , 1 ) $ '0123456789' )	.Or.;
			!( SubStr(	_xVarAux , 2 , 1 ) $ '0123456789' )	.Or.;
			SubStr(		_xVarAux , 3 , 1 ) <> ':'			.Or.;
			!( SubStr(	_xVarAux , 4 , 1 ) $ '0123456789' )	.Or.;
			!( SubStr(	_xVarAux , 5 , 1 ) $ '0123456789' )
			
			U_ITMsg(  "A hora digitada não é válida, informar o campo no formato correto: '00:00' ('HH:MM')" , "Atenção!" ,,1 )
			_lRet := .F.
			
		EndIf
		
		If _lRet .And. Val( SubStr(_xVarAux,4,2) ) > 59
			U_ITMsg(  "A hora digitada não é válida, informar valores válidos entre: '00:00' e '99:59'. (Formato:'HH:MM')" , "Atenção!" ,,1 )
			_lRet := .F.
		EndIf
		
EndCase

FWRestArea(_aArea)

Return(_lRet)

/*
===============================================================================================================================
Programa----------: RPON011VPG
Autor-------------: Alexandre Villar
Data da Criacao---: 29/04/2014
===============================================================================================================================
Descrição---------: Validação do pocicionamento da página atual para quebras
===============================================================================================================================
Parametros--------: _oPrint	- Objeto de Impressão do Relatório
------------------: _nLinha	- Variável de controle do posicionamento
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RPON011VPG( _oPrint , _nLinha , _aCabec , _cTxtCab , _aColAux , _oFont01 , _oFont02 , _oFont03 , _oFont04 , _lFinPag )

Local _nTotCol	:= Len( _aCabec )
Local _nLimPag	:= 2600
Local _nX		:= 0

Default _lFinPag := .T.

If _nLinha > _nLimPag
	
	//| Encerra página atual e abre uma nova                                      |
	If _lFinPag
		_oPrint:EndPage()
	EndIf
	
	_oPrint:StartPage()
	
	//| Reinicia o posicionamento da linha                                        |
	_nLinha	:= 280
	
	//| Insere logo no cabecalho                                                  |
	If File( "LGRL01.BMP" )
		_oPrint:SayBitmap( 050 , _aColAux[01] , "LGRL01.BMP" , 300 , 130 )
	EndIf
	
	//| Desenha quadro do Título                                                  |
	_oPrint:Line( 050 , 0400 , 050 , 2450 )
	_oPrint:Line( 240 , 0400 , 240 , 2450 )
	_oPrint:Line( 050 , 0400 , 240 , 0400 )
	_oPrint:Line( 050 , 2450 , 240 , 2450 )
	
	//| Insere Informações no cabecalho                                           |
	_oPrint:Say( 060 , 420 , TITULO +" ( "+ DToC(Date()) +" - "+ Time() +")" , _oFont01 )
	_oPrint:Say( 120 , 420 , "Período: "+ DToC( MV_PAR02 ) +" - "+ DToC( MV_PAR03 ) +" | Filiais: "+ AllTrim( MV_PAR01 )											, _oFont02 )
	_oPrint:Say( 150 , 420 ,	"Categorias: "+ AllTrim( MV_PAR06 ) +" | Sit. Folha: "+ AllTrim( MV_PAR07 ) +" | Intervalo: "+ MV_PAR08, _oFont02 )
	
	_oPrint:Say( 190 , 420 , _cTxtCab , _oFont04 )
	
	//| Adiciona cabecalho do conteúdo                                            |
	_nLinha := 255
	
	For _nX := 3 To _nTotCol
		_oPrint:Say( _nLinha , _aColAux[_nX] , _aCabec[_nX] , _oFont02 )
	Next _nX
	
	//| Adiciona linha separadora e posiciona abaixo                              |
	_oPrint:Line( 290 , 0 , 290 , 5000 )
	_nLinha := 300
	
EndIf

Return

/*
===============================================================================================================================
Programa----------: RPON011W
Autor-------------: Josue Danich Prestes
Data da Criacao---: 12/06/2018
Descrição---------: Envio de relatorio por email
Parametros--------: 
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RPON011W()

	U_ITMsg("Rotina de envio de email ainda não foi desenvolvida","Atenção",,1)
	
Return
