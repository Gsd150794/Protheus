/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |09/06/2022| Chamado 40412. Mostrar as horas com separador de decimmais com "," .
Alex Wallauer |21/09/2023| Chamado 45102. Fernando. Correção de error.log: variable does not exist _ABUTTONS. 
Alex Wallauer |19/10/2023| Chamado 45371. Fernando. Correção de error.log: array out of bounds [1] of [0].
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RPON018
Autor-------------: Alex Wallauer
Data da Criacao---: 16/02/2022
Descrição---------: Chamado 39218 - Fernando. Relatório de Acompanhamento de Hora Extra. 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RPON018()

Local _cTitulo    := "Relatório de Acompanhamento de Hora Extra" 
Local _aDados	:= {}
Local oproc     := nil
Local nI		:= 0 
Local _aParRet	:= {}
Local _aParAux  := {}
Local _nTamFil	:= ( 2 )
Local _nTamCat	:= ( U_ITCONREG( "SX5" , "28" ) )
Local _nTamSit	:= ( U_ITCONREG( "SX5" , "31" ) )
Local _nTamSet	:= ( 16 * TamSX3("ZAK_COD")[01] )

SET DATE FORMAT TO "DD/MM/YYYY"

//Incluir o Pergunte - Tipo de Evento = 1 - Hora Extra, 2 - Atraso/Falta, 3 - Outros
//1 - Hora Extra = SP9_CLASEV = 01
//2 - Atraso/Falta = SP9_CLASEV = 02,03,04,05
//3 - Outros = SP9_CLASEV = ZZ

_BSelecSP9:={|| "SELECT P9_CODIGO,P9_DESC FROM "+RETSQLNAME("SP9")+" SP9 "+;
                " WHERE  D_E_L_E_T_ = ' ' AND P9_CLASEV "+  If(MV_PAR09="1"," = '01' ",If(MV_PAR09="2"," IN ('02','03','04','05') "," = 'ZZ' "))+" AND "+;
				" P9_FILIAL = '"+cFilAnt+"' ORDER BY P9_CODIGO " }

_aItalac_F3:={}//       1           2         3                      4                      5          6                      7         8          9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave            , _nCpoDesc              ,_bCondTab    , _cTitAux           , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR10" ,_BSelecSP9,{|Tab| (Tab)->P9_CODIGO }, {|Tab|(Tab)->P9_DESC              },,"Eventos"         ,          ,          ,          ,.T.        ,       , } ) 

aAdd( _aParAux , { 1 , "Filiais"		, Space(_nTamFil)			 , "@!" , "U_RPON018P(1)", "LSTFIL"	, "" , 100 , .F. }) // MV_PAR01
aAdd( _aParAux , { 1 , "Data Inicial"	, CTOD(Space(8))			 , "@D" , ""			 , ""		, "" , 050 , .T. }) // MV_PAR02
aAdd( _aParAux , { 1 , "Data Final"		, CTOD(Space(8))			 , "@D" , ""			 , ""		, "" , 050 , .T. }) // MV_PAR03
aAdd( _aParAux , { 1 , "Matrícula De"	, Space(Len(SRA->RA_MAT))    , "@!" , ""			 , "SRA"    , "" , 050 , .F. }) // MV_PAR04
aAdd( _aParAux , { 1 , "Matrícula Até"	, Space(Len(SRA->RA_MAT))    , "@!" , ""			 , "SRA"    , "" , 050 , .F. }) // MV_PAR05
aAdd( _aParAux , { 1 , "Categorias"		, Space(_nTamCat)			 , "@!" , "U_RPON018P(2)", "LSTCAT"	, "" , 080 , .F. }) // MV_PAR06
aAdd( _aParAux , { 1 , "Situações"		, Space(_nTamSit)			 , "@!" , "U_RPON018P(3)", "SX5L31"	, "" , 050 , .F. }) // MV_PAR07
aAdd( _aParAux , { 1 , "Setores"		, Space(_nTamSet)			 , "@!" , "" 			 , "ZAK001"	, "" , 100 , .F. }) // MV_PAR08
aAdd( _aParAux , { 2 , "Tipo Eventos"	, "1"		      		     , {"1-Hora Extra","2-Atraso/Falta", "3-Outros"}, 060,".T.",.T. ,".T."}) // MV_PAR09
aAdd( _aParAux , { 1 , "Eventos"		, Space(100)      		     , "@!" , "" 			 , "F3ITLC"	, "" , 100 , .T. })                  // MV_PAR10
aAdd( _aParAux , { 2 , "Lista por"      , "1"		      		     , {"1-Função","2-Setor","3-Funcionario","4-Funcionario Dia"}, 060,".T.",.T. ,".T."}) // MV_PAR11

For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next nI

While .T.

     //ParamBox( _aParAux , cTitle                                  , @aRet     ,[bOk]    , [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
   If !ParamBox( _aParAux , "Digite os filtros dos dados das Horas" , @_aParRet ,{||.T.}  , /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
       Exit
   EndIf

   If Empty(MV_PAR02) .Or.  Empty(MV_PAR03) .Or.  MV_PAR02 > MV_PAR03
      U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo com as 2 datas preenchidas",3)
      Loop
   EndIf
   //Log de utilização
   U_ITLOGACS()

   _aDados  := {}
   _aColXML := {}
  _aAuxExtra:= {}
   _lSair   := .F.
   cTimeInicial:=Time()

   FWMsgRun( ,{|oproc| _aDados := RPON018SEL(oproc) } , "Aguarde!" , "Lendo dados..." )

    If Len(_aDados) > 0

        aCab:={}
        _aCabXML:={}
		// Alinhamento: 1-Left   ,2-Center,3-Right
		// Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
	    If MV_PAR11 = "1"
           aAdd(aCab,"Setor")
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})
           aAdd(aCab,"Função")           
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})
           aAdd(aCab,"No. Colaboradores") 
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})
           aAdd(aCab,"No. Horas")                    
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],3           ,2         ,.F.})
           aAdd(aCab,"Medias de Horas")
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],3           ,2         ,.F.})

	    ElseIf MV_PAR11 = "2"
           aAdd(aCab,"Setor")
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})
           aAdd(aCab,"No. Colaboradores") 
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})
           aAdd(aCab,"No. Horas")
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],3           ,2         ,.F.})
           aAdd(aCab,"Medias de Horas")
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],3           ,2         ,.F.})
	    ElseIf MV_PAR11 = "3"
           aAdd(aCab,"Matricula")
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})
           aAdd(aCab,"Funcionario")
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})
           aAdd(aCab,"No. Horas")
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],3           ,2         ,.F.})
	    ElseIf MV_PAR11 = "4"
           aAdd(aCab,"Matricula")
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})
           aAdd(aCab,"Funcionario")
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})
           aAdd(aCab,"Departamento")
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})
           aAdd(aCab,"Data")
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})
           aAdd(aCab,"Eventos")
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],1           ,1         ,.F.})
           aAdd(aCab,"No. Horas")
		   //          Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
		   aAdd(_aCabXML,{aCab[Len(aCab)],3           ,2         ,.F.})
        EndIf

        _cTitulo2:=_cTitulo+' - Data: ' + DToC(Date()) +" -  H.I.: "+cTimeInicial+" H.F.: "+Time()
        _cMsgTop:="Par. 1: "+AllTrim(AllToChar(MV_PAR01))+"; Par. 2: "+AllTrim(AllToChar(MV_PAR02))+"; Par. 3: "+AllTrim(AllToChar(MV_PAR03))+"; Par. 4: "+AllTrim(AllToChar(MV_PAR04))+;
                "; Par. 5: "+AllTrim(AllToChar(MV_PAR05))+"; Par. 6: "+AllTrim(AllToChar(MV_PAR06))+"; Par. 7: "+AllTrim(AllToChar(MV_PAR07))+"; Par. 7: "+AllTrim(AllToChar(MV_PAR08))+;
                "; Par. 9: "+AllTrim(AllToChar(MV_PAR09))+"; Par. 10: "+AllTrim(AllToChar(MV_PAR10))+"; Par. 11: "+AllTrim(AllToChar(MV_PAR11))
        _aButtons:=NIL
        If Len(_aAuxExtra) > 0
		   _aCabAux:={"Data","Horas","Evento","Filial + Matricula"}
           _aButtons:={}
           aAdd(_aButtons,{"BUDGET",{||  U_ITListBox( _cMsgTop , _aCabAux , _aAuxExtra , .F.      , 1 )  },"Detalhar Horas", "Detalhar Horas" }) 
        EndIf
                                //        ,_aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab  , bDblClk , _aColXML , bCondMarca )
       _lSair:=!U_ITListBox(_cTitulo2,aCab,_aDados , .T.    , 1    ,_cMsgTop,          ,        ,         ,     ,        , _aButtons,_aCabXML,         , _aColXML ,            )
    
    Else
      
      U_ITMsg("Não á registro para esses filtros",'Atenção!',"Tente novamente com outros filtros",3)
      
      Loop
    
    EndIf

   If _lSair
      Exit
   EndIf   

EndDo

Return

/*
===============================================================================================================================
Programa----------: RPON018SEL
Autor-------------: Alex Wallauer
Data da Criacao---: 16/02/2022
Descrição---------: Carga de dados para o relatório
Parametros--------: oproc - objeto da barra de processmento 
Retorno-----------: _aRet - dados coletados do banco
===============================================================================================================================
*/
Static Function RPON018SEL(oproc)

Local _aRet		:= {}
Local _cAlias	:= GetNextAlias()
Local _aFiliais:= {}
Local _cQuery	:= ""
Local _nI,nI,_nA:= A := 0

_aFiliais:= StrTokArr( AllTrim(MV_PAR01) , ";" )

If Empty(_aFiliais)

	U_ITMsg(  "Não foram informadas Filiais válidas para o processamento!" , "Atenção!" ,,1 )
    Return {}

EndIf

For _nI := 1 To Len( _aFiliais )

	_cQuery := " SELECT "
	_cQuery += " R_E_C_N_O_ RECNO  "	  
	_cQuery += " FROM "+ RetSqlName("SRA") +" SRA "+ CRLF
	_cQuery += " WHERE "
	_cQuery += " 	RA_FILIAL = '"+ _aFiliais[_nI] +"' "+ CRLF
	_cQuery += " AND D_E_L_E_T_	= ' ' "+ CRLF
	If !Empty(MV_PAR04) 
		_cQuery += " AND RA_MAT >= '" + MV_PAR04 + "'  "
	EndIf
	If !Empty(MV_PAR05)
		_cQuery += " AND RA_MAT <= '" + MV_PAR05 + "' "
	EndIf
	
	If !Empty(MV_PAR06)
		cCatFun:=AllTrim(MV_PAR06)
		_cQuery += "AND trim(SRA.RA_CATFUNC) IN "+ FormatIn( RTrim( cCatFun ) , ";" )
	EndIf 
	
	If !Empty(MV_PAR07)
		cSitFol:=""
	    For nI := 1 To Len( AllTrim(MV_PAR07) )
	    	If SubStr( AllTrim(MV_PAR07) , nI , 1 ) <> "*"
	    		cSitFol += SubStr( AllTrim(MV_PAR07) , nI , 1 ) + ";"
	    	EndIf
	    Next
	    cSitFol := SubStr( cSitFol , 1 , Len(cSitFol) - 1 )
		If " " $ RTRIM(MV_PAR07)
			_cQuery += " AND (trim(SRA.RA_SITFOLH)  IN "+ FormatIn( RTRIM( cSitFol ) , ";" ) + " OR SRA.RA_SITFOLH = ' ') "
		Else
			_cQuery += " AND trim(SRA.RA_SITFOLH)  IN "+ FormatIn( RTRIM( cSitFol ) , ";" )
		EndIf 
	EndIf

  	If !Empty( MV_PAR08 )	
		_cQuery += " AND SRA.RA_I_SETOR	IN "+ FormatIn( AllTrim( MV_PAR08 ) , ";" ) + CRLF	
	EndIf
	
	If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )
	
	DBSelectArea(_cAlias)
   _cTot := 0
	COUNT TO  _cTot
   _cTot:=AllTrim(Str(_cTot))
   _nTam:=Len(_cTot)
   SPI->(DBSetOrder(2))

	(_cAlias)->( DBGoTop() )
	_nni := 0

	While (_cAlias)->( !Eof() )
		
		_nni++
		oproc:cCaption := ("Lendo Filial: " + _aFiliais[_nI] + " / funcionario " +StrZero(_nni,_nTam) +" de "+ _cTot )
		ProcessMessages()
		
      SRA->(DBGoTo((_cAlias)->RECNO))

      _aMinExtra:= {}
      nMinExtras:=BuscaHextras()
      For A := 1 TO Len(_aMinExtra)
	      aAdd(_aAuxExtra,ACLONE( _aMinExtra[A] ))
	  Next

	  _cCargo:=""
	  If MV_PAR11 = "1"
         _cCargo:=SRA->RA_CARGO
	  
	  ElseIf MV_PAR11 = "3"
         aAdd( _aRet , { SRA->RA_MAT , SRA->RA_NOME , 1 ,nMinExtras}) 
		 (_cAlias)->(DBSkip())
		 Loop
	  
	  ElseIf MV_PAR11 = "4"
	     For _nA := 1 To Len( _aMinExtra )                                 //4-HE               5-DATA APONTAMENTO   , 6-EVENTO         ,  7-DEPARTAMENTO 
	        aAdd( _aRet , { SRA->RA_MAT , SRA->RA_NOME , If(_nA=1,1,0) ,_aMinExtra[_nA,2]  , DToC(_aMinExtra[_nA,1]) ,_aMinExtra[_nA,3] , Posicione("SQB",1,SRA->RA_FILIAL+SRA->RA_DEPTO,"QB_DESCRIC") }) 
		 Next
		 (_cAlias)->(DBSkip())
		 Loop
      EndIf			
      //MV_PAR11 = "1" E "2"
	  If (_nPos:= aScan(_aRet , {|R| R[1]==SRA->RA_I_SETOR .And. R[2]==_cCargo })) = 0
		 aAdd( _aRet , { SRA->RA_I_SETOR , _cCargo    , 1 , nMinExtras  }) 
      Else
         _aRet[_nPos,3]+=1
         _aRet[_nPos,4]+=nMinExtras
      EndIf						
		
      (_cAlias)->(DBSkip())
		
	EndDo

Next

_aRet2:={}
_nTotFunc:=0
//_nTotCHorE:=0//Centesimal
_nTotSHorE:=0//Sexagenal
For _nI := 1 To Len( _aRet )
   nHoraExtra :=Round( (_aRet[_nI,4]*100)/60,2)//TOTAL DE HORAS GERAL  //Centesimal
   nHora2Extra:=INT(nHoraExtra)//INTEIRO DA HORA
   nHora2Extra:=(nHora2Extra*60)//TOTAL DE MINUTOS HORA CHEIA
   nHora2Extra:=(_aRet[_nI,4]*100)-nHora2Extra//TOTAL DE MINUTOS - TOTAL DE MINUTOS DAS HORAS CHEIAS
   nHora2Extra:=INT(nHoraExtra)+(nHora2Extra/100)//SOMA OS RESTOS DOS MINUTOS
   nHora2Extra:=Round(nHora2Extra,2)//Sexagesimal
   cHora2Extra:=TRANS(nHora2Extra,"@E 999999999.99") 
   nMediaHora2:=Round(If(_aRet[_nI,3]=0,0,nHora2Extra/_aRet[_nI,3]),2)
   cMediaHora2:=TRANS(nMediaHora2,"@E 999999999.99") 
	If MV_PAR11 = "1"//QUEBRA POR SETOR+FUNCAO
      aAdd(_aRet2,{Posicione("ZAK",1,xFilial("ZAK")+_aRet[_nI,1],"ZAK_DESCRI"),;//Setor
                   Posicione("SQ3",1,xFilial("SQ3")+_aRet[_nI,2],"Q3_DESCSUM"),;//Função        
                   _aRet[_nI,3],;//                   nHoraExtra,; //Centesimal //No. Colaboradores
                   cHora2Extra,;//Sexagesimal                                   //No. Horas     
                   cMediaHora2;                                                 //Medias de Horas
                  })
	  aAdd(_aColXML,{_aRet2[Len(_aRet2),1] , _aRet2[Len(_aRet2),2] , _aRet2[Len(_aRet2),3] ,nHora2Extra, nMediaHora2})
   ElseIf MV_PAR11 = "2"//QUEBRA SÓ POR SETOR
      aAdd(_aRet2,{Posicione("ZAK",1,xFilial("ZAK")+_aRet[_nI,1],"ZAK_DESCRI"),;//Setor
                   _aRet[_nI,3],;//                   nHoraExtra,;//Centesimal  //No. Colaboradores
                   cHora2Extra,;//Sexagesimal                                   //No. Horas     
                   cMediaHora2;                                                 //Medias de Horas
                  })
	  aAdd(_aColXML,{_aRet2[Len(_aRet2),1] , _aRet2[Len(_aRet2),2] , nHora2Extra, nMediaHora2})
	ElseIf MV_PAR11 = "3"//POR FUNCIONARIO
      aAdd(_aRet2,{_aRet[_nI,1],;//MATRICULA
                   _aRet[_nI,2],;//Funcionario
				   cHora2Extra;  //No. Horas - Sexagenal
                   })                  
	  aAdd(_aColXML,{_aRet2[Len(_aRet2),1] , _aRet2[Len(_aRet2),2] , nHora2Extra})
	ElseIf MV_PAR11 = "4"//POR FUNCIONARIO POR DIA
      aAdd(_aRet2,{_aRet[_nI,1],;//01-MATRICULA
                   _aRet[_nI,2],;//02-NOME
                   _aRet[_nI,7],;//03-DEPARTAMENTO
                   _aRet[_nI,5],;//04-DATA
                   _aRet[_nI,6],;//05-EVENTO
				   cHora2Extra;  //06-HORA - Sexagenal
                   })                  
	  aAdd(_aColXML,{_aRet2[Len(_aRet2),1] , _aRet2[Len(_aRet2),2] , _aRet2[Len(_aRet2),3] ,_aRet2[Len(_aRet2),4] ,_aRet2[Len(_aRet2),5] ,nHora2Extra})
   EndIf
   _nTotFunc +=_aRet[_nI,3]
// _nTotCHorE+= nHoraExtra//Centesimal
// _nTotSHorE+= nHora2Extra//Sexagesimal
Next


If MV_PAR11 = "1"//QUEBRA POR SETOR+FUNCAO
   aSort(_aRet2,,, { | x,y | x[1]+x[2] < y[1]+y[2] })
   aAdd( _aRet2 , { "TOTAL " , "" , _nTotFunc          , /*TRANS(_nTotSHorE,"@E 999999999.99")*/   , '' })//5 Colunas
   aSort(_aColXML,,, { | x,y | x[1]+x[2] < y[1]+y[2] })
   aAdd( _aColXML , { "TOTAL " , "" , _nTotFunc        , /*TRANS(_nTotSHorE,"@E 999999999.99")*/   , '' })//5 Colunas
ElseIf MV_PAR11 = "2"//QUEBRA SÓ POR SETOR
   aSort(_aRet2,,, { | x,y | x[1] < y[1] })
   aAdd( _aRet2 , { "TOTAL" ,      _nTotFunc          ,  /*TRANS(_nTotSHorE,"@E 999999999.99")*/ , '' })//4 Colunas
   aSort(_aColXML,,, { | x,y | x[1] < y[1] })
   aAdd( _aColXML , { "TOTAL" ,      _nTotFunc        ,  /*TRANS(_nTotSHorE,"@E 999999999.99")*/ , '' })//4 Colunas
ElseIf MV_PAR11 = "3"//POR FUNCIONARIO
   aSort(_aRet2,,, { | x,y | x[1] < y[1] })
   aAdd( _aRet2 , { "TOTAL" , _nTotFunc               , /*TRANS(_nTotSHorE,"@E 999999999.99")*/ })//3 Colunas
   aSort(_aColXML,,, { | x,y | x[1] < y[1] })
   aAdd( _aColXML , { "TOTAL" , _nTotFunc             , /*TRANS(_nTotSHorE,"@E 999999999.99")*/ })//3 Colunas
ElseIf MV_PAR11 = "4"//POR FUNCIONARIO POR DIA
   aSort(_aRet2,,, { | x,y | x[1]+DToS(CTOD(x[4])) < y[1]+DToS(CTOD(y[4])) })
// aAdd( _aRet2 , { "TOTAIS" , ""  ,""  ,  ""  ,  "" , /*TRANS(_nTotSHorE,"@E 999999999.99")*/ })//6 Colunas
   aSort(_aColXML,,, { | x,y | x[1]+DToS(CTOD(x[4])) < y[1]+DToS(CTOD(y[4])) })
// aAdd( _aColXML , { "TOTAIS" , ""  ,""  ,  ""  ,  "" , /*TRANS(_nTotSHorE,"@E 999999999.99")*/ })//6 Colunas
EndIf

If MV_PAR11 <> "4"
   If Len(_aRet2[1]) <> Len(_aRet2[Len(_aRet2)])
      U_ITMsg("Ultima linha do _aRet2 (TOTAIS) esta com menos colunas que as demais linhas anteriores",'Atenção!',"Insira o mesmo numero de colunas no aAdd do _aRet2 de 'TOTAIS' ",3)
   EndIf
EndIf

Return( _aRet2 )

/*
===============================================================================================================================
Programa----------: BuscaHextras
Autor-------------: Alex Wallauer
Data da Criacao---: 16/02/2022
Descrição---------: Retorna HORAS EXTRAS DO FUNCIONARIO
Parametros--------: SRA POSICIONADA
Retorno-----------:  HORAS EXTRAS 
===============================================================================================================================
*/
Static Function BuscaHextras()

Local _cAlias	:= GetNextAlias()
Local _cQuery	:= ""
Local _nMinExtra:= 0
_aMinExtra:= {}

_cQuery += " SELECT SPC.PC_FILIAL,SPC.PC_DATA,SPC.PC_PD,  SPC.PC_QUANTC AS TOTHE "+ CRLF
_cQuery += " FROM "+ RetSqlName("SPC") +" SPC "+ CRLF
_cQuery += " WHERE "+ CRLF
_cQuery += "     SPC.D_E_L_E_T_  = ' ' "+ CRLF
_cQuery += " AND SPC.PC_ABONO    = ' ' "+ CRLF
_cQuery += " AND SPC.PC_PD	IN "+ FormatIn( AllTrim( MV_PAR10 ) , ";" ) + CRLF	
_cQuery += " AND SPC.PC_FILIAL  = '"+ SRA->RA_FILIAL +"' " + CRLF
_cQuery += " AND SPC.PC_DATA BETWEEN '"+ DToS( MV_PAR02 ) +"' AND '"+ DToS( MV_PAR03 ) +"' "+ CRLF
_cQuery += " AND SPC.PC_MAT = '"+SRA->RA_MAT+"' "+ CRLF
_cQuery += " ORDER BY SPC.PC_FILIAL,SPC.PC_DATA,SPC.PC_PD "

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .T. )

While !(_cAlias)->(Eof())
   If (_cAlias)->TOTHE >= 1
      nHora:=INT((_cAlias)->TOTHE) 
      nMin:= ((_cAlias)->TOTHE) - nHora
      _nMinExtra+= ( ( nHora * 0.60) + nMin )//Soma 0.60 pq a somatoria dos minutos esta dividida por 100
      aAdd(_aMinExtra,{SToD((_cAlias)->PC_DATA) , ( ( nHora * 0.60) + nMin ) , (_cAlias)->PC_PD+"-"+Posicione("SP9",1,(_cAlias)->PC_FILIAL+(_cAlias)->PC_PD ,"P9_DESC")  , SPH->PH_FILIAL+SPH->PH_MAT })
   Else
      _nMinExtra+=(_cAlias)->TOTHE//Soma os minutos divididos por 100
      aAdd(_aMinExtra,{SToD((_cAlias)->PC_DATA) , (_cAlias)->TOTHE , (_cAlias)->PC_PD+"-"+Posicione("SP9",1,(_cAlias)->PC_FILIAL+(_cAlias)->PC_PD ,"P9_DESC")  , SPH->PH_FILIAL+SPH->PH_MAT })
   EndIf
   (_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

_cQuery := " SELECT SPH.PH_FILIAL, SPH.PH_DATA, SPH.PH_PD, SPH.PH_QUANTC AS TOTHE , SPH.PH_MAT"+ CRLF
_cQuery += " FROM "+ RetSqlName("SPH") +" SPH "+ CRLF
_cQuery += " WHERE "+ CRLF
_cQuery += "     SPH.D_E_L_E_T_  = ' ' "+ CRLF
_cQuery += " AND SPH.PH_ABONO    = ' ' "+ CRLF
_cQuery += " AND SPH.PH_PD IN "+ FormatIn( AllTrim( MV_PAR10 ) , ";" ) + CRLF	
_cQuery += " AND SPH.PH_FILIAL  = '"+ SRA->RA_FILIAL +"' " + CRLF
_cQuery += " AND SPH.PH_DATA BETWEEN '"+ DToS( MV_PAR02 ) +"' AND '"+ DToS( MV_PAR03 ) +"' "+ CRLF
_cQuery += " AND SPH.PH_MAT = '"+SRA->RA_MAT+"' "+ CRLF
_cQuery += " ORDER BY SPH.PH_FILIAL, SPH.PH_DATA, SPH.PH_PD "

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .T. )

While !(_cAlias)->(Eof())
   If (_cAlias)->TOTHE >= 1
      nHora:=INT((_cAlias)->TOTHE) 
      nMin:= ((_cAlias)->TOTHE) - nHora
      _nMinExtra+= ( (nHora * 0.60) + nMin )//Soma 0.60 pq a somatoria dos minutos esta dividida por 100
      aAdd(_aMinExtra,{SToD((_cAlias)->PH_DATA) , ( ( nHora * 0.60) + nMin )  , (_cAlias)->PH_PD+"-"+Posicione("SP9",1,(_cAlias)->PH_FILIAL+(_cAlias)->PH_PD ,"P9_DESC") , SPH->PH_FILIAL+SPH->PH_MAT })
   Else
      _nMinExtra+=(_cAlias)->TOTHE//Soma os minutos divididos por 100
      aAdd(_aMinExtra,{SToD((_cAlias)->PH_DATA) , (_cAlias)->TOTHE , (_cAlias)->PH_PD+"-"+Posicione("SP9",1,(_cAlias)->PH_FILIAL+(_cAlias)->PH_PD ,"P9_DESC") , SPH->PH_FILIAL+SPH->PH_MAT })


   EndIf
   (_cAlias)->(DBSkip())
EndDo

(_cAlias)->(DBCloseArea())

Return _nMinExtra

/*
===============================================================================================================================
Programa----------: RPON018P
Autor-------------: Alex Wallauer
Data da Criacao---: 16/02/2022
Descrição---------: Validação das Perguntas da Rotina
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RPON018P( _nOpc )

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
