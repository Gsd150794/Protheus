/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

#Define TITULO	"Relatório de Bloqueio de Cracha"

/*
===============================================================================================================================
Programa----------: RPON017
Autor-------------: Alex Wallauer
Data da Criacao---: 08/02/2022
Descrição---------: Relatório de Bloqueio de Cracha - Chamado 39079
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RPON017

Local _aDados	:= {}
Local oproc     := nil
Local nI		:= 0 
Local _aParRet	:= {}
Local _aParAux  := {}
Local _nTamFil	:= ( U_ITCONREG( "SM0" ) * 2 )
Local _nTamCat	:= ( U_ITCONREG( "SX5" , "28" ) )
Local _nTamSit	:= ( U_ITCONREG( "SX5" , "31" ) )


SET DATE FORMAT TO "DD/MM/YYYY"

aAdd( _aParAux , { 1 , "Filiais"		, Space(_nTamFil)				, "@!" , "U_RPON017P(1)", "LSTFIL"	, "" , 100 , .F. } )//MV_PAR01  LSTFIL SM0001
aAdd( _aParAux , { 1 , "Data Inicial"	, CTOD(Space(8))				, "@D" , ""				, ""		, "" , 050 , .T. } )//MV_PAR02
aAdd( _aParAux , { 1 , "Data Final"		, CTOD(Space(8))				, "@D" , ""				, ""		, "" , 050 , .T. } )//MV_PAR03
aAdd( _aParAux , { 1 , "Matrícula De"	, Space( TamSX3("RA_MAT")[01] ) , "@!" , ""				, "SRA"		, "" , 050 , .F. } )//MV_PAR04
aAdd( _aParAux , { 1 , "Matrícula Até"	, Space( TamSX3("RA_MAT")[01] )	, "@!" , ""				, "SRA"		, "" , 050 , .F. } )//MV_PAR05
aAdd( _aParAux , { 1 , "Categorias"		, Space(_nTamCat)				, "@!" , "U_RPON017P(2)", "LSTCAT"	, "" , 080 , .F. } )//MV_PAR06
aAdd( _aParAux , { 1 , "Situações"		, Space(_nTamSit)				, "@!" , "U_RPON017P(3)", "SX5L31"	, "" , 050 , .F. } )//MV_PAR07

For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next nI

While .T.

     //ParamBox( _aParAux , cTitle                                    , @aRet     ,[bOk]    , [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
   If !ParamBox( _aParAux , "Digite os filtros dos dados dos Crachás" , @_aParRet ,{||.T.}  , /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
       Exit
   EndIf

   If Empty(MV_PAR02) .Or.  Empty(MV_PAR03) .Or.  MV_PAR02 > MV_PAR03
      U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo com as 2 datas preenchidas",3)
      Loop
   EndIf
   //Log de utilização
   U_ITLOGACS()

	//============================================================================
	//| Verifica o registro de ponto em busca das informações                    |
	//============================================================================
	FWMsgRun( ,{|oproc| _aDados := RPON017SEL(oproc) } , "Aguarde!" , "Selecionando dados..." )
	
    If Empty(_aDados)
    	U_ITMsg(  "Não foram encontrados registros para exibir! Verifique os parâmetros e tente novamente." , "Atenção" ,,1 )
    	Loop
    EndIf
    
    _aCabec  := { "Filial"	, "Matrícula"	, "Funcionário"	, "Data de Bloqueio", "Hora de Bloqueio", "Data de Desbloqueio", "Hora de Desbloqueio","Motivo","Observação"}
    
    FWMsgRun( , {|| U_ITListBox( TITULO , _aCabec , _aDados , .T. ) },"Exportando dados para planilha, aguarde..." , TITULO  )

EndDo

Return.T.

/*
===============================================================================================================================
Programa----------: RPON017SEL
Autor-------------: Alex Wallauer
Data da Criacao---: 08/02/2022
Descrição---------: Carga de dados para o relatório
Parametros--------: oproc - objeto da barra de processmento
Retorno-----------: _aRet - dados coletados do banco
===============================================================================================================================
*/
Static Function RPON017SEL(oproc)

Local _aRet			:= {}
Local _cAlias		:= GetNextAlias()
Local _cAlias2		:= GetNextAlias()
Local _cAlias3		:= GetNextAlias()
Local _cAlias4		:= GetNextAlias()
Local _aFiliais		:= {}
Local _cQuery		:= ""
Local _nTot			:= 0
Local _nI			:= 0 , nI
Local _nnj			:= 0

Default oproc := nil

_aFiliais			:= StrTokArr( AllTrim(MV_PAR01)+";" , ";" )

If Empty(_aFiliais)

	U_ITMsg(  "Não foram informadas Filiais válidas para o processamento!" , "Atenção!" ,,1 )

EndIf

For _nI := 1 To Len( _aFiliais )

	If ValType(oproc) = "O"

		oproc:cCaption := ("Lendo funcionários da filial " + _aFiliais[_nI] + "...")
		ProcessMessages()
 
	EndIf
	
	_cQuery := " SELECT "
	_cQuery += " R_E_C_N_O_ RECNO  "	  
	_cQuery += " FROM "+ RetSqlName("SRA") +" SRA "
	_cQuery += " WHERE "
	_cQuery += " 	RA_FILIAL = '"+ _aFiliais[_nI] +"' "
	_cQuery += " AND D_E_L_E_T_	= ' ' "
	
	If !Empty(MV_PAR04) 
		_cQuery += " AND RA_MAT >= '" + MV_PAR04 + "'  "
	EndIf
	If !Empty(MV_PAR05)
		_cQuery += " AND RA_MAT <= '" + MV_PAR05 + "' "
	EndIf
	
	If !Empty(MV_PAR06)
		cCatFun:=AllTrim(MV_PAR06)
		_cQuery += "AND trim(SRA.RA_CATFUNC)	IN "+ FormatIn( RTrim( cCatFun ) , ";" )
	EndIf 
	
	If !Empty(MV_PAR07)
		cSitFol:=""
	    For nI := 1 To Len( AllTrim(MV_PAR07) )
	    	If SubStr( AllTrim(MV_PAR07) , nI , 1 ) <> "*"
	    		cSitFol += SubStr( AllTrim(MV_PAR07) , nI , 1 ) + ";"
	    	EndIf
	    Next nI
	    cSitFol := SubStr( cSitFol , 1 , Len(cSitFol) - 1 )
		If " " $ RTRIM(MV_PAR07)
			_cQuery += " AND (trim(SRA.RA_SITFOLH)  IN "+ FormatIn( RTRIM( cSitFol ) , ";" ) + " OR SRA.RA_SITFOLH = ' ') "
		Else
			_cQuery += " AND trim(SRA.RA_SITFOLH)  IN "+ FormatIn( RTRIM( cSitFol ) , ";" )
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

			oproc:cCaption := ("Lendo funcionários, filial " + _aFiliais[_nI] + " : " + StrZero(_nni,6) + " de " + StrZero(_nTot,6))
			ProcessMessages()
 
		EndIf
		
		_nni++
	
		SRA->(DBGoTo((_cAlias)->RECNO))
		
		
		//carrega id do funcionário
		_cQuery :=  "SELECT IDCOLAB FROM SURICATO.TBCOLAB WHERE NUMEPIS = '" + AllTrim(SRA->RA_PIS) + "'"
		
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
				
					_cQuery :=	" SELECT ICARD , DATABLOQ, HORABLOQ, DATALIBE , HORALIBE ,OBSEBLOQLIBE , DESCMOTI , MOT.CODIMOTI MOT_CM , TBB.CODIMOTI MOT_TB"
					_cQuery +=	" FROM SURICATO.TBBLOQUCRACH TBB , SURICATO.TBMOTIVBLOQU MOT WHERE " 
					_cQuery +=	" DATABLOQ >= TO_DATE('" + DToS(MV_PAR02) + "', 'yyyymmdd') " //data inicio do relatorio 
					_cQuery +=	" and DATABLOQ <= TO_DATE('" + DToS(MV_PAR03) + "', 'yyyymmdd') " //data fim do relatorio 
					_cQuery +=	" AND ICARD = " + AllTrim(Str(_acrachas[_nnj][1])) 
					_cQuery +=	" AND MOT.CODIMOTI = TBB.CODIMOTI "
					_cQuery +=  " ORDER BY DATABLOQ,HORABLOQ"
		
					If Select(_cAlias4) > 0
		
						DBSelectArea(_cAlias4)
						(_cAlias4)->(DBCloseArea())
			
					EndIf
		
					DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias4 , .T. , .F. )
					DBSelectArea(_cAlias4)
					
					While (_cAlias4)->( !Eof() )
					
						_nBhoras   := int((_cAlias4)->HORABLOQ / 60)
						_nBminutos :=  (_cAlias4)->HORABLOQ - ((int((_cAlias4)->HORABLOQ / 60))*60) 
						_cBhoras   :=  StrZero(_nBhoras,2) + ":" + StrZero(_nBminutos,2)

						_nhoras   := int((_cAlias4)->HORALIBE / 60)
						_nminutos :=  (_cAlias4)->HORALIBE - ((int((_cAlias4)->HORALIBE / 60))*60) 
						_choras   :=  StrZero(_nhoras,2) + ":" + StrZero(_nminutos,2)

					
						aAdd( _aRet , {	AllTrim(SRA->RA_FILIAL)	        ,; //Filial
							AllTrim(SRA->RA_MAT)						,; //Matrícula
							AllTrim(Capital(AllTrim(SRA->RA_NOME )))    ,; //Funcionário
							AllTrim(DToC((_cAlias4)->DATABLOQ))		    ,; //Data do bloqueio
							AllTrim(_cBhoras)						    ,; //Hora de bloquio
							AllTrim(DToC((_cAlias4)->DATALIBE))		    ,; //Data de liberacao
							AllTrim(_choras)		   					,; //hora de liberacao
							AllTrim((_cAlias4)->DESCMOTI)				,; //MOTIVO //AllTrim(Str(MOT_CM))+"="+AllTrim(Str(MOT_TB))+"/"+
							AllTrim((_cAlias4)->OBSEBLOQLIBE)			}) //OBS
						
						
						(_cAlias4)->(DBSkip())
						
					EndDo
							
				Next
		
			EndIf
		
		EndIf
		
		(_cAlias)->(DBSkip())
		
	EndDo

Next _nI

Return( _aRet )

/*
===============================================================================================================================
Programa----------: RPON017P
Autor-------------: Alex Wallauer
Data da Criacao---: 08/02/2022
Descrição---------: Validação das Perguntas da Rotina
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RPON017P( _nOpc )

Local _lRet		:= .T. //Se retornar .F. nao deixa sair do campo
Local _cNomeVar	:= ReadVar()
Local _xVarAux	:= &(_cNomeVar)
Local _aArea	:= FWGetArea()
Local _cEmpAux	:= cEmpAnt
Local _aDadAux	:= {}
Local _nI		:= 0

Do Case
	
	Case _nOpc == 1 //Filiais Consideradas ?
		
		//-- Verifica se o campo esta vazio --//
		If Empty(_xVarAux)
			
			U_ITMsg(  "É obrigatório informar o filtro de Filiais, clique em 'selecionar todas' para utilizar todas as Filiais." , "Atenção!" ,,1 )
			_lRet := .F.
			
			//-- Verifica se o campo foi preenchido com conteudo valido --//
		Else
			
			_aDadAux := U_ITLinDel( AllTrim(_xVarAux),";" )
			For _nI := 1 To Len(_aDadAux)
				
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
		
		If !Empty(_xVarAux)
			_aDadAux := U_ITLinDel( AllTrim(_xVarAux),";",1)
			DBSelectArea("SX5")
			SX5->( DBSetOrder(1) )
			SX5->( DBGoTop() )
			
			For _nI := 1 To Len(_aDadAux)
				
				If _aDadAux[_nI] <> "*" .And. !SX5->( DBSeek( xFilial("SX5") + "28" + _aDadAux[_nI] ) )
					
					U_ITMsg(  "As 'Categorias Funcionais' informadas não são válidas! Verifique os dados digitados." ,"Atenção!" ,,1 )
					_lRet := .F.
					Exit
					
				EndIf
				
			Next _nI
			
		EndIf
		
	Case _nOpc == 3 //Situações ?
		
		If !Empty(_xVarAux)
		
			_aDadAux := U_ITLinDel( _xVarAux,,1 )
			DBSelectArea("SX5")
			SX5->( DBSetOrder(1) )
			SX5->( DBGoTop() )
			
			For _nI := 1 To Len(_aDadAux)
				
				If _aDadAux[_nI] <> "*" .And. !SX5->( DBSeek( xFilial("SX5") + "31" + _aDadAux[_nI] ) )
					
					U_ITMsg( "As 'Situações na Folha' informadas não são válidas! Verifique os dados digitados." ,"Atenção!" , ,1)
					_lRet := .F.
					Exit
				EndIf
			Next _nI
		EndIf
EndCase

FWRestArea(_aArea)

Return(_lRet)
