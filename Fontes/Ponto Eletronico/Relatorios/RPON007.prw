/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25. 
Alex Wallauer |30/08/2021| Chamado 37601. Trazer o conteúdo do campo RA_NSOCIAL, quando preenchido no lugar do RA_NOME. 
Igor Melgaço  |20/06/2023| Chamado 44223. Ajustes para inclusão de opções no campo Z10_TIPO.
===============================================================================================================================
*/

#Include "Totvs.Ch"

/*
===============================================================================================================================
Programa----------: RPON007
Autor-------------: Xavier
Data da Criacao---: 20/05/2015
Descrição---------: Emissão do modelo de ocorrencias de horarios no ponto
Parametros--------: cTpModelo = Tipo do modelo para emitir (Comunicado ou Advertencia)
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RPON007(_lauto)

Local _aDados		:= {}
Local _cPerg		:= "RPON007"
Local _lroda    	:= .F.

Private _ncolini 	:= 100
Private _ncolfim 	:= 2300

Default _lauto := .F.

SET DATE FORMAT TO "DD/MM/YYYY"

_lroda := _lauto

If !(_lauto)

	_lroda := Pergunte( _cPerg )
	
EndIf

If _lroda

	Processa( {|| _aDados := RPON007SEL(_lauto) } , "Aguarde!" , "Selecionando registros das recepções..." )
	
	If Empty(_aDados)
	
		MessageBox( "Não foram encontrados registros para exibir! Verifique os parâmetros e tente novamente." , "Atenção" , 48 )
		
	Else
	
		Processa( {|| RPON007PRT( _aDados ) } , 'Aguarde!' , 'Imprimindo registros...' )
		
	EndIf

Else
	
	MsgInfo( 'Operação cancelada pelo usuário!' , 'Atenção!' )
	
EndIf

Return

/*
===============================================================================================================================
Programa--------: RPON007SEL
Autor-----------: Josué Danich Pretses
Data da Criacao-: 18/08/2015
Descrição-------: Função para consulta e preparação dos dados do relatório
Parametros------: Nenhum
Retorno---------: _aRet - Dados do relatório
===============================================================================================================================
*/
Static Function RPON007SEL(_lauto)

Local _aRet			:= {}
Local _cAlias		:= GetNextAlias()
Local _cQuery		:= ''
Local _nTotReg	:= 0
Local _nRegAtu	:= 0

Default _lauto 		:= .T.

//faz automatico com Z10 posicionado
If _lauto
   Private MV_PAR01 	:= AllTrim(Z10->Z10_FILIAL)
   Private MV_PAR02 	:= Z10->Z10_DATA
   Private MV_PAR03 	:= Z10->Z10_DATA
   Private MV_PAR04 	:= AllTrim(Z10->Z10_MATRIC)
   Private MV_PAR05 	:= AllTrim(Z10->Z10_MATRIC)
   Private MV_PAR07 	:= 3 
   Private MV_PAR06 	:= 3
   Private MV_PAR08 	:= 3
   Private MV_PAR09 	:= "                   "
   Private MV_PAR10	:= "ZZZZZZZZZZZZZZZZZZZ"
   Private MV_PAR11 	:= "                   "
   Private MV_PAR12	:= "ZZZZZZZZZZZZZZZZZZZ"
EndIf

Begin Sequence
   _cQuery :=	" SELECT Z10_FILIAL, "
   _cQuery +=	" Z10_DATA,   "
   _cQuery +=	" Z10_MATRIC, "
   _cQuery +=	" Z10_TIPO,   "
   _cQuery +=	" Z10_MOTIVO, "
   _cQuery +=	" Z10_IMPRES, "
   _cQuery +=	" Z10_HORAIN, "
   _cQuery +=	" Z10_HORAFI, "
   _cQuery +=	" Z10_TEMPOD, "
   _cQuery +=	" R_E_C_N_O_, "
   _cQuery +=	" Z10_ORIGEM FROM "+ retsqlname("Z10") 
   _cQuery +=	" WHERE Z10_DATA BETWEEN '" + DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "'"
   _cQuery += IIf( !Empty( MV_PAR01 ) , " AND Z10_FILIAL IN "+ FormatIn( AllTrim( MV_PAR01 ) , ';' )	, "" )
   _cQuery += " AND Z10_MATRIC BETWEEN '" + MV_PAR04 + "' AND '" +  MV_PAR05 + "'"
   _cQuery += " AND D_E_L_E_T_ <> '*'"

   //Filtra advertência e notificação
   If MV_PAR06 == 1
	  _cQuery += " AND Z10_TIPO = 'N'
   ElseIf MV_PAR06 == 2
	  _cQuery += " AND Z10_TIPO = 'A'
   EndIf

   //Filtra impressos
   If MV_PAR08 == 1
	  _cQuery += " AND Z10_IMPRES = 'S'
   ElseIf MV_PAR08 == 2
	  _cQuery += " AND Z10_IMPRES = 'N'
   EndIf
 
   If Select(_cAlias) > 0
	  (_cAlias)->( DBCloseArea() )
   EndIf

   DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )

   DBSelectArea(_cAlias)
   (_cAlias)->( DBGoTop() )
   (_cAlias)->( DBEval( {|| _nTotReg++ } ) )
   (_cAlias)->( DBGoTop() )

   SRA->( DBSetOrder( 1 ) )
   ProcRegua(_nTotReg)
   While (_cAlias)->( !Eof() )
	
	  _nRegAtu++
	  IncProc( "Lendo registros: ["+ StrZero( _nRegAtu , 6 ) +"] de ["+ StrZero( _nTotReg , 6 ) +"]" )

	       If Posicione("SRA",1,(_cAlias)->Z10_FILIAL + (_cAlias)->Z10_MATRIC, "RA_CC") >= AllTrim(MV_PAR09) .AND.;
		        Posicione("SRA",1,(_cAlias)->Z10_FILIAL + (_cAlias)->Z10_MATRIC, "RA_CC") <= AllTrim(MV_PAR10) .AND.;
		        Posicione("SRA",1,(_cAlias)->Z10_FILIAL + (_cAlias)->Z10_MATRIC, "RA_I_SETOR") >= AllTrim(MV_PAR11) .AND.;
		        Posicione("SRA",1,(_cAlias)->Z10_FILIAL + (_cAlias)->Z10_MATRIC, "RA_I_SETOR") <= AllTrim(MV_PAR12)

				_cNomeFunc := SRA->RA_NOMECMP
		        If !Empty(SRA->RA_NSOCIAL)
		           _cNomeFunc:=SRA->RA_NSOCIAL
		        EndIf

        
		        aAdd( _aRet ,{(_cAlias)->Z10_FILIAL																                           ,; //01 - Filial
					  	            (_cAlias)->Z10_DATA																	                           ,; //02 - Data    
						              (_cAlias)->Z10_MATRIC															                             ,; //03 - Matricula
						              _cNomeFunc		 ,; //04 - Nome
						              (_cAlias)->Z10_TIPO																	                           ,; //05 - Advertencia ou Notificacao
						              (_cAlias)->Z10_MOTIVO																                           ,; //06 - mOTIVO
						              (_cAlias)->Z10_ORIGEM																                           ,; //07 - HE , DSR, Interjornada ou Intrajornada
						              (_cAlias)->Z10_IMPRES    	 														                         ,; //08 - Impresso
						              (_cAlias)->R_E_C_N_O_                                                          ,; //09 - Registro
		                      (_cAlias)->Z10_HORAIN                                                          ,; //10 - Hora Inicial da Ocorrencia 
						              (_cAlias)->Z10_HORAFI                                                          ,; //11 - Hora Final da Ocorrencia    
						              (_cAlias)->Z10_TEMPOD})                                                           //12 - Tempo Decorrido
	       EndIf
	   
	   (_cAlias)->( DBSkip() )
   EndDo

   (_cAlias)->( DBCloseArea() )

   //organiza matriz
   If MV_PAR07 == 1
	  _aRet := aSort(_aRet, , , {|x,y | y[2]+y[3]+y[4] > x[2]+x[3]+x[4]})
   ElseIf MV_PAR07 == 2
      _aRet := aSort(_aRet, , , {|x,y | y[4]+y[2] > x[4]+x[2]})
   ElseIf MV_PAR07 == 3
	  _aRet := aSort(_aRet, , , {|x,y | y[2]+y[4] > x[2]+x[4]})
   EndIf

End Sequence

Return( _aRet )

/*
===============================================================================================================================
Programa--------: RPON007PRT
Autor-----------: Josué Danich Prestes
Data da Criacao-: 03/08/2015
Descrição-------: Função para controlar e imprimir os dados do relatório
Parametros------: _aDados  - Dados do relatório
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RPON007PRT( _aDados )
                   // 1      2      3      4      5      6   
Local _aColCab	:= { 0020 , 0220 , 0440 , 0675 , 0875 , 1100 , 1750 , 1800 } // { 0020 , 0180 , 0300 , 0675 , 1875 , 1500 , 1750 , 1800 }
Local _aColItn	:= { 0010 , 0220 , 0440 , 0675 , 0875 , 1100 , 1750 , 1925 } // { 0010 , 0180 , 0300 , 0675 , 1875 , 1700 , 1950 , 1925 }
Local _nLinha	:= 300
Local _nI		:= 0
Local _oPrint	:= Nil
Local _nulin :=0

Private _oFont02	:= TFont():New( "Tahoma" ,, 18 , .F. , .T. ,, .T. ,, .T. , .F. )
Private _oFont03	:= TFont():New( "Tahoma" ,, 14 , .F. , .F. ,, .T. ,, .T. , .F. )
Private _oFont04	:= TFont():New( "Tahoma" ,, 12 , .F. , .T. ,, .T. ,, .T. , .F. )
Private _oFont04B	:= TFont():New( "Tahoma" ,, 11 , .F. , .T. ,, .T. ,, .T. , .F. )
Private _oFont05	:= TFont():New( "Tahoma" ,, 10 , .F. , .F. ,, .T. ,, .T. , .F. )
Private _npagi := 1
Private _cTitulo := "Notificação/Advertência - Ocorrências de ponto"

//====================================================================================================
// Inicializa o objeto do relatório
//====================================================================================================
_oPrint := TMSPrinter():New( _cTitulo )
_oPrint:Setup()
_oPrint:SetPortrait()
_oPrint:SetPaperSize(9)

//====================================================================================================
// Processa a impressão dos dados
//====================================================================================================
For _nI := 1 To Len( _aDados )
	
	//====================================================================================================
	// Imprime ocorrências
	//====================================================================================================
	If _nI == 1 

		//cabeçalho para primeira folha
		
		_nulin  := _nLinha
		_nLinha := 5000
		
		_nLinha := RPON007VPG( _oPrint , _nLinha , .F., _aDados, _nI,_nulin)
	
	    _oPrint:Say(  _nLinha + 0020 , _ncolini + _aColCab[01]		, 'Data'	  , _oFont04B )
		_oPrint:Say(  _nLinha + 0020 , _ncolini + _aColCab[02]		, 'Hora Inic.', _oFont04B )
		_oPrint:Say(  _nLinha + 0020 , _ncolini + _aColCab[03]		, 'Hora Final', _oFont04B )
		_oPrint:Say(  _nLinha + 0020 , _ncolini + _aColCab[04]		, 'Tempo'	  , _oFont04B )
		_oPrint:Say(  _nLinha + 0020 , _ncolini + _aColCab[05]		, 'Motivo'	  , _oFont04B ) 
		_oPrint:Say(  _nLinha + 0020 , _ncolini + _aColCab[06]		, 'Observação', _oFont04B ) 

		_nLinha += 075
		
		_culdata 	:= _aDados[_nI][02]
		_culmat 	:=	_aDados[_nI][03]
		
		
	ElseIf _culdata != _aDados[_nI][02] .Or. _culmat !=  _aDados[_nI][03]
		
		//cabeçalho quando mudar data e/ou matricula
		_nulin  := _nLinha
		_nLinha := 5000
		
		_nLinha := RPON007VPG( _oPrint , _nLinha , .T., _aDados, _nI,_nulin)
	
		_oPrint:Say(  _nLinha + 0020 , _ncolini + _aColCab[01]	    , 'Data'	  , _oFont04B )  
		_oPrint:Say(  _nLinha + 0020 , _ncolini + _aColCab[02]		, 'Hora Inic.', _oFont04B )
		_oPrint:Say(  _nLinha + 0020 , _ncolini + _aColCab[03]		, 'Hora Final', _oFont04B )
		_oPrint:Say(  _nLinha + 0020 , _ncolini + _aColCab[04]		, 'Tempo'	  , _oFont04B )
		_oPrint:Say(  _nLinha + 0020 , _ncolini + _aColCab[05]		, 'Motivo'	  , _oFont04B ) 
		_oPrint:Say(  _nLinha + 0020 , _ncolini + _aColCab[06]		, 'Observação', _oFont04B ) 

		_nLinha += 075
		
		_culdata 	:= _aDados[_nI][02]
		_culmat 	:=	_aDados[_nI][03]
	 
	EndIf	

	_oPrint:Line( _nLinha        , _ncolini              		 	, _nLinha        , _ncolfim		      )
	_oPrint:Line( _nLinha + 0075 , _ncolini             			, _nLinha + 0075 , _ncolfim	          )
	_oPrint:Line( _nLinha        , _ncolini              		 	, _nLinha + 0075 , _ncolini           )
	_oPrint:Line( _nLinha        , _ncolfim	       		 	        , _nLinha + 0075 , _ncolfim	          )
	_oPrint:Line( _nLinha        , _ncolini + _aColCab[02] - 015 	, _nLinha + 0075 , _ncolini + _aColCab[02] - 015 )
	_oPrint:Line( _nLinha        , _ncolini + _aColCab[03] - 015 	, _nLinha + 0075 , _ncolini + _aColCab[03] - 015 )
	_oPrint:Line( _nLinha        , _ncolini + _aColCab[04] - 015 	, _nLinha + 0075 , _ncolini + _aColCab[04] - 015 )
	_oPrint:Line( _nLinha        , _ncolini + _aColCab[05] - 015 	, _nLinha + 0075 , _ncolini + _aColCab[05] - 015 )
	_oPrint:Line( _nLinha        , _ncolini + _aColCab[06] - 015 	, _nLinha + 0075 , _ncolini + _aColCab[06] - 015 )
	
	_ctipo := U_APON001Y(_aDados[_nI][07]+"A")
		
	_oPrint:Say( _nLinha + 10 , _ncolini + _aColItn[01] , DToC(SToD(_aDados[_nI][02]))	          , _oFont05			) // _oFont03
	_oPrint:Say( _nLinha + 10 , _ncolini + _aColItn[02] , _aDados[_nI][10]	                      , _oFont05			)
	_oPrint:Say( _nLinha + 10 , _ncolini + _aColItn[03] , _aDados[_nI][11]	                      , _oFont05			)
	_oPrint:Say( _nLinha + 10 , _ncolini + _aColItn[04] , _aDados[_nI][12]	                      , _oFont05			)
	_oPrint:Say( _nLinha + 10 , _ncolini + _aColItn[05] , _ctipo	                              , _oFont05			)
	_oPrint:Say( _nLinha + 10 , _ncolini + _aColItn[06] , SubStr(AllTrim(_aDados[_nI][06]),1,50)  , _oFont05			)
	
	_nLinha += 075
	
Next _nI


//Finaliza folha
_nulin  := _nLinha
_nLinha := 5000
_nLinha := RPON007VPG( _oPrint , _nLinha , .T., _aDados, _nI-1,_nulin, .F.)


//=============================================================================
//| Starta o objeto de impressão                                              |
//=============================================================================
_oPrint:Preview()

//marca registros como impressos
DBSelectArea("Z10")

For _nI := 1 to Len(_aDados)

	Z10->(DBGoTo(_aDados[_nI][09]))
	RecLock("Z10", .F.)
	Z10->Z10_IMPRES := "S"
	MSUnLock()
	
Next

Return

/*
===============================================================================================================================
Programa--------: RPON007VPG
Autor-----------: Josué Danich Prestes
Data da Criacao-: 03/08/2014
Descrição-------: Validação do posicionamento da página atual para quebras
Parametros------: oPrint	- Objeto de Impressão do Relatório
----------------: nLinha	- Variável de controle do posicionamento
Retorno---------: Nenhum
===============================================================================================================================
 */
Static Function RPON007VPG( _oPrint , _nLinha , _lFinPag, _aDados, _nI,_nulin, _lnovpag)

Local _nLimPag		:= 3350

Default _lFinPag	:= .T.
Default _lnovpag	:= .T.


If _nLinha > _nLimPag

	//====================================================================================================
	// Verifica se encerra a página atual
	//====================================================================================================
	If _lFinPag
		//faz texto do final da página
		_nLinha := _nulin + 90
		_oPrint:Say( _nLinha, _ncolini, "Esclarecemos, ainda que a repetição de procedimentos como este poderá ser considerado como" , _oFont03			) 
		_nLinha += 75

		//Muda frase se é advertência ou notificação
		_ctipo := ""
		If _aDados[_nI][5] == 'A'
			_ctipo := "ato faltoso, passível de nova advertência e suspensão."
		ElseIf _aDados[_nI][5] == 'O'
			_ctipo := "ato faltoso, passível de nova ocorrência e notificação."
		ElseIf _aDados[_nI][5] == 'S'
			_ctipo := "ato faltoso, passível de demissão por justa causa."
		Else
			_ctipo := "ato faltoso, passível de advertência e suspensão."
		EndIf
		
		_oPrint:Say( _nLinha, _ncolini, _ctipo  , _oFont03			) 
		_nLinha += 75
		_oPrint:Say( _nLinha, _ncolini, "Para que não tenhamos, no futuro, de tomar as medidas que nos facultam a legislação vigente," , _oFont03			) 
		_nLinha += 75
		_oPrint:Say( _nLinha, _ncolini, "solicitamos que observe as normas internas definidas e amplamente divulgadas anteriormente." , _oFont03			)
		_nLinha += 75
		_oPrint:Say( _nLinha, _ncolini, "Favor dar o seu ciente," , _oFont03			) 

		_nLinha += 300       
		_oPrint:Line( _nLinha        , _ncolini               , _nLinha        , 1500              )
		_nLinha += 30       
		
		If _lnovpag
			_oPrint:Say( _nLinha, _ncolini,_aDados[_nI-1][4] )
		Else
			_oPrint:Say( _nLinha, _ncolini,_aDados[_nI][4] )
		EndIf

		_nLinha += 300       
		_oPrint:Line( _nLinha        , _ncolini               , _nLinha        , 1500              )
		_nLinha += 30       
		_oPrint:Say( _nLinha, _ncolini, AllTrim(SM0->M0_NOMECOM))
      
		_nLinha += 150  
		_oPrint:Say( _nLinha, _ncolini, "Testemunha: (caso o colaborador advertido negue-se a assinar o documento. Serve para" , _oFont04			) 
		_nLinha += 75
		_oPrint:Say( _nLinha, _ncolini, " testemunhar que o colaborador foi advertido)" , _oFont04			) 

		_nLinha += 300       
		_oPrint:Line( _nLinha        , _ncolini               , _nLinha        , 925              )
		_oPrint:Say( _nLinha + 030, _ncolini, "Nome:")
		_oPrint:Say( _nLinha + 105, _ncolini, "CPF:")     
		
		_oPrint:Line( _nLinha        , 1200               , _nLinha        , _ncolfim              )
		_oPrint:Say( _nLinha + 030, 1200, "Nome:")
		_oPrint:Say( _nLinha + 105, 1200, "CPF:")     
	
		_oPrint:EndPage()
	EndIf

	If _lnovpag
		//====================================================================================================
		// Inicializa a nova página e o posicionamento
		//====================================================================================================
		_oPrint:StartPage()
		_nLinha	:= 280
	
		//====================================================================================================
		// Insere logo no cabecalho
		//====================================================================================================
		If File( "LGRL01.BMP" )
			_oPrint:SayBitmap( 050 , 1020 , "LGRL01.BMP" , 410 , 170 )
		EndIf
		
		If _aDados[_nI][5] == 'A'
		
			_oPrint:Say( 290 , _ncolini + 970 , "Advertência   " 								, _oFont02 )
			
			_npagi++
				
			//====================================================================================================
			// Adiciona cabecalho de conteúdo
			//====================================================================================================
			_nLinha := 405
			
		
    	   _oPrint:Say(  _nLinha , _ncolini, AllTrim(SM0->M0_CIDCOB) + ", " + StrZero(DAY(DATE()),2) + " de " + AllTrim(MESEXTENSO(Date())) + " de " + StrZero(YEAR(DDATABASE),4) + "." 	, _oFont03			)
			_nLinha += 150
			_oPrint:Say(  _nLinha , _ncolini, "Ao Sr.(a): " + AllTrim(_aDados[_nI][4]) + ", Filial/Matrícula: " + _aDados[_nI][1] + "/" + _aDados[_nI][3] , _oFont03			)
			_nLinha += 90
			_oPrint:Say(  _nLinha , _ncolini, "Esta carta tem a finalidade de advertir-lhe, em razão da(s) Notificação(ões) recebida(s) referente a(s)", _oFont03			)
			_nLinha += 90
			_oPrint:Say(  _nLinha,  _ncolini, "seguinte(s) ocorrência(s) e irregularidade(s) abaixo discriminada(s):", _oFont03			)
			_nLinha += 90
   	 
		ElseIf _aDados[_nI][5] == 'O' 
		
			_oPrint:Say( 290 , _ncolini + 970 , "Ocorrência   " 								, _oFont02 )
			
			_npagi++
				
			//====================================================================================================
			// Adiciona cabecalho de conteúdo
			//====================================================================================================
			_nLinha := 405
		
		    _oPrint:Say(  _nLinha , _ncolini, AllTrim(SM0->M0_CIDCOB) + ", " + StrZero(DAY(DATE()),2) + " de " + AllTrim(MESEXTENSO(Date())) + " de " + StrZero(YEAR(DDATABASE),4) + "." 	, _oFont03			)
			_nLinha += 150
			_oPrint:Say(  _nLinha , _ncolini, "Ao Sr.(a): " + AllTrim(_aDados[_nI][4]) + ", Filial/Matrícula: " + _aDados[_nI][1] + "/" + _aDados[_nI][3] , _oFont03			)
			_nLinha += 75
			_oPrint:Say(  _nLinha , _ncolini, "Esta carta tem a finalidade de notificar-lhe, em razão da(s) seguinte(s) ocorrência(s) e irregularidade(s) ", _oFont03			)
			_nLinha += 75
			_oPrint:Say(  _nLinha,  _ncolini, "abaixo discriminada(s):", _oFont03			)
			_nLinha += 90
    
		ElseIf _aDados[_nI][5] == 'S' 
		
			_oPrint:Say( 290 , _ncolini + 970 , "Suspenção   " 								, _oFont02 )
			
			_npagi++
				
			//====================================================================================================
			// Adiciona cabecalho de conteúdo
			//====================================================================================================
			_nLinha := 405
		
		    _oPrint:Say(  _nLinha , _ncolini, AllTrim(SM0->M0_CIDCOB) + ", " + StrZero(DAY(DATE()),2) + " de " + AllTrim(MESEXTENSO(Date())) + " de " + StrZero(YEAR(DDATABASE),4) + "." 	, _oFont03			)
			_nLinha += 150
			_oPrint:Say(  _nLinha , _ncolini, "Ao Sr.(a): " + AllTrim(_aDados[_nI][4]) + ", Filial/Matrícula: " + _aDados[_nI][1] + "/" + _aDados[_nI][3] , _oFont03			)
			_nLinha += 75
			_oPrint:Say(  _nLinha , _ncolini, "Esta carta tem a finalidade de suspenção, em razão da(s) seguinte(s) ocorrencia(s) e irregularidade(s)", _oFont03			)
			_nLinha += 75
			_oPrint:Say(  _nLinha,  _ncolini, "abaixo discriminada(s):", _oFont03			)
			_nLinha += 90
    		
		Else
		
			_oPrint:Say( 290 , _ncolini + 970 , "Notificação   " 								, _oFont02 )
			
			_npagi++
				
			//====================================================================================================
			// Adiciona cabecalho de conteúdo
			//====================================================================================================
			_nLinha := 405
		
		    _oPrint:Say(  _nLinha , _ncolini, AllTrim(SM0->M0_CIDCOB) + ", " + StrZero(DAY(DATE()),2) + " de " + AllTrim(MESEXTENSO(Date())) + " de " + StrZero(YEAR(DDATABASE),4) + "." 	, _oFont03			)
			_nLinha += 150
			_oPrint:Say(  _nLinha , _ncolini, "Ao Sr.(a): " + AllTrim(_aDados[_nI][4]) + ", Filial/Matrícula: " + _aDados[_nI][1] + "/" + _aDados[_nI][3] , _oFont03			)
			_nLinha += 75
			_oPrint:Say(  _nLinha , _ncolini, "Esta carta tem a finalidade de notificar-lhe, em razão da(s) seguinte(s) ocorrência(s) e irregularidade(s) ", _oFont03			)
			_nLinha += 75
			_oPrint:Say(  _nLinha,  _ncolini, "abaixo discriminada(s):", _oFont03			)
			_nLinha += 90
    
		
		EndIf
	
	EndIf
		
EndIf

Return _nLinha
