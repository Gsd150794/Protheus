/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |19/11/2021| Chamado 38244. Incluido 2 paramentros novos de Inicio Ferias de até.
Alex Wallauer |03/02/2022| Chamado 38743. Ajuste no filtro dos 2 paramentros novos de Inicio Ferias de até.
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGPE016
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/06/2018
Descrição---------: Relatório de programação de ferias via email - Chamado 25178
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGPE016()

Local _alog := {}  , _nzi

If !(isincallstack("MDIEXECUTE") .Or. isincallstack("SIGAADV"))

	//===========================================================================
	//| Prepara o ambiente pra processamento do JOB                             |
	//===========================================================================
	
	RpcClearEnv()
	RpcSetType(2)
		
	If !RPCSETENV( '01' , '01' )
		Return
	EndIf
	
	Pergunte('RGPE016',.F.)

Else

	//Faz pergunte
	If !Pergunte('RGPE016',.T.)
   
  		U_ITMsg("Relatório cancelado!","Atenção",,1)
		Return .F.
		
	EndIf


EndIf

_aheader := ;
{"Filial",;				//01
"Cent Custo",;			//03
"Setor",;				//02
"Matricula",;			//04
"Nome",;				//05
"Cargo",;				//06
"Munícipio",;			//07
"Estado",;				//08
"Dt. Ini. Per. Aquis",;	//09
"Dt. Fim. Per. Aquis",;	//10
"Dt Limite Maximo.",;	//11
;
"1o.Dt Inicio Ferias",;	//12
"1o.Dt Final Ferias",;	//13
"1o.Dias Ferias",;		//14
"1o.Dias Abono",;		//15
;
"2o.Dt Inicio Ferias",;	//16
"2o.Dt Final Ferias",;	//17
"2o.Dias Ferias",;		//18
"2o.Dias Abono",;		//19
;
"3o.Dt Inicio Ferias",;	//20
"3o.Dt Final Ferias",;	//21
"3o.Dias Ferias",;		//22
"3o.Dias Abono",;		//23
;
"Dias Vencidos",;		//24
"Dias Prop/Saldo",;		//25
"Tipo",;				//26
"Fim Gozo",;			//27
"Situacao do Func.",;   //29
"Dt Afastamento"}       //30

//Log de utilização
U_ITLOGACS()

Private _cTitulo:='Programação de Férias Filtros: Data: ' + DToC(MV_PAR01)+" - Dias: "+Str(MV_PAR02,3)

If !Empty(MV_PAR12) .Or. !Empty(MV_PAR13)
   _cTitulo+=" - Inicio Ferias de "+DToC(MV_PAR12)+" ate "+DToC(MV_PAR13)
EndIf

If (isincallstack("MDIEXECUTE") .Or. isincallstack("SIGAADV"))


	FWMsgRun(,{ |_oProc| _alog := RGPE016D(_oProc) },"Processando relatório...","Aguarde...")

	If Len(_alog) > 0
	
		U_ITListBox( _cTitulo ,_aheader , _alog , .T. , 1 , _cTitulo )
		 			
	Else
	
		U_ITMsg("Não foram localizados registros para esse filtro","Atenção",,2)
		_lenvia := .F.
		
	EndIf
	
Else

	_cfiliais := u_itgetmv("ITFERFIL","92")
	_afils := StrTokArr(_cfiliais,",")

	For _nzi := 1 to Len(_afils)

		MV_PAR01 := DATE()+45
		MV_PAR02 := 31
		MV_PAR03 := '000000'
		MV_PAR04 := 'ZZZZZZ'
		MV_PAR05 := ' A*F*'
		MV_PAR06 := '***************'
		MV_PAR07 := _afils[_nzi]
		MV_PAR08 := 1
		MV_PAR09 := " "
		MV_PAR10 := " "

		_alog := RGPE016D()
		
		If Len(_alog) > 0
			_cfil := cfilant
			cfilant := _afils[_nzi]
			RGPE016E(_alog,_aheader)
			cfilant := _cfil					
		EndIf
	Next
EndIf

Return 

/*
===============================================================================================================================
Programa----------: RGPE016E
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/06/2018
Descrição---------: Envia email do relatório
Parametros--------: _alog - Dados do relatório
					_aheader - cabeçalho do relatório
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGPE016E(_alog,_aheader)

Local _aConfig	:= U_ITCFGEML('')
Local _cEmail	:= U_ITGETMV( 'IT_WFPRFR' , 'sistema@italac.com.br' )
Local _carquivo := "\temp\RGPE016.csv"  , _nI , _nc

erase(_carquivo)

U_RGPE016G( 'Relatório de programação de férias - ' + DToC(date())  , _aHeader , _alog, 'RGPE016')
	

	_cMsgEml := '<html>'
	_cMsgEml += '<head><title></title>Relatório de programação de férias - ' + DToC(date()) + '</head>'
	_cMsgEml += '<body>'
	_cMsgEml += '<style Type="text/css"><!--'
	_cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
	_cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
	_cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
	_cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
	_cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
	_cMsgEml += 'td.aceito	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #00CC00; }'
	_cMsgEml += 'td.recusa  { font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FF0000; }'
	_cMsgEml += '--></style>'
	_cMsgEml += '<center>'
	_cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="700" height="50"><br>'
	_cMsgEml += '<table class="bordasimples" width="700">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '	<td class="titulos"><center>Relatório de programação de férias - ' + DToC(date()) + '</center></td>'
	_cMsgEml += '	</tr>'
	_cMsgEml += '</table>'
	_cMsgEml += '<br>'
	_cMsgEml += '<table class="bordasimples" width="700">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td align="center" colspan="2" class="grupos">Log Processamento</b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Data:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" >'+ DToC(date()) +'</td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" width="20%"><b>Hora:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" >'+ Time() +'</td>'
	_cMsgEml += '    </tr>'
	
	_cMsgEml += '	<tr>'
	_cMsgEml += '      <td class="titulos" align="center" colspan="2"><font color="red">Esta é uma mensagem automática. Por favor não responder!</font></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '</table>'
	

	_cMsgEml += '<br>'
	_cMsgEml += '<table class="bordasimples" width="1200">'
	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td align="center" colspan="18" class="grupos">Programação de férias</b></td>'
	_cMsgEml += '    </tr>'
	_cMsgEml += '    <tr>'	
	
	_cMsgEml += '      <td class="itens" align="center" width="10%"><b>Filial</b></td>'

	For _nI := 2 to Len(_aheader)
	    _cMsgEml += '      <td class="itens" align="left" width="10%"><b>' + ( _aheader[_nI] ) + '</b></td>'
    Next

	_cMsgEml += '    </tr>'
	_cMsgEml += '</center>'
	
	For _nI := 1 to Len(_alog)

		_cMsgEml += '    <tr>'

	    For _nc := 1 to Len( _alog[_nI] )
	        If _alog[_nI][_nc] <> "___  / ___ / ___"
		        _cMsgEml += '   <td class="itens" align="left" >' + ( _alog[_nI][_nc] ) + '</td>'        
		    Else
		        _cMsgEml += '   <td class="itens" align="left" ></td>'        
		    EndIf		        
	    Next

		_cMsgEml += '    </tr>'

	Next

	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center">     </td>'
	_cMsgEml += '      <td class="itens" align="left" >      </td>'
	_cMsgEml += '    </tr>'

	_cMsgEml += '    <tr>'
	_cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
	_cMsgEml += '      <td class="itens" align="left" > ['+ GetEnvServer() +'] </td>'
	_cMsgEml += '    </tr>'
	
	_cMsgEml += '</body>'
	_cMsgEml += '</html>'

_cEmlLog := ''

_cAssunto := "Programação de férias - Filial " + cfilant + " - " + DToC(date())
_cEmlLog := ""

If !(isincallstack("MDIEXECUTE") .Or. isincallstack("SIGAADV"))
	
		U_ITENVMAIL( _aConfig[01] , _cEmail ,        ,         ,_cAssunto, _cMsgEml ,_carquivo;
			,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )
	
Else

		FWMsgRun(,{ || U_ITENVMAIL( _aConfig[01] , _cEmail ,        ,         ,_cAssunto, _cMsgEml ,_carquivo;
	         ,_aConfig[01],_aConfig[02], _aConfig[03],_aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )},"Aguarde...","Enviando email...")


		U_ITMsg("Enviado arquivo "+_carquivo+" para "+_cEmail+CHR(13)+CHR(10)+_cEmlLog,"Atenção",,1)
	         
EndIf

Return

/*
===============================================================================================================================
Programa----------: RGPE016D
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/06/2018
Descrição---------: Montar dados do relatório     
Parametros--------: Nenhum
Retorno-----------: _alog - Array com dados de relatório
===============================================================================================================================
*/
Static Function RGPE016D(_oProc)

Local _alog		:= {}
Local _cAliasSRA
Local _cQuery := ""
Local _ntot := 0

If ValType(_oProc) = "O"
   _oProc:cCaption := ("Lendo dados dos funcionarios ")
   ProcessMessages()
EndIf   
 
//Faz query filtrando o SRA
_cQuery := " SELECT" 
_cQuery += "    R_E_C_N_O_  REC"
_cQuery += " FROM "+ RetSqlName("SRA") +" SRA "
_cQuery += " WHERE "
_cQuery += "     SRA.D_E_L_E_T_  = ' ' "        


If !Empty(MV_PAR03) .And. !Empty(MV_PAR04)

	_cQuery += " AND SRA.RA_MAT >= '" + AllTrim(MV_PAR03) + "' AND SRA.RA_MAT <= '" + AllTrim(MV_PAR04) + "' "

   _cTitulo+=' - Matriculas de ' + AllTrim(MV_PAR03)+" ate "+AllTrim(MV_PAR04)

EndIf

_csitfol := RGPE016F(MV_PAR05)

If !Empty(_csitfol)

	_cQuery += " AND SRA.RA_SITFOLH IN " + _csitfol

   _cTitulo+=' - Situacoes: ' + AllTrim(_csitfol)
	
EndIf 

_ccatfunc := RGPE016F( AllTrim(MV_PAR06)  )

If !Empty(_ccatfunc)

	_cQuery += " AND SRA.RA_CATFUNC IN " + _ccatfunc

   _cTitulo+=' - Categorias: ' + AllTrim(_ccatfunc)
	
EndIf 

If !Empty(MV_PAR07)

	_cQuery += " AND SRA.RA_FILIAL IN " + FormatIn( AllTrim(MV_PAR07) , ';' )

   _cTitulo+=' - Filiais: ' + AllTrim(MV_PAR07)
	
EndIf 

If !Empty(MV_PAR09)

	_cQuery += " AND SRA.RA_I_SETOR IN " + FormatIn( AllTrim(MV_PAR09) , ';' )

   _cTitulo+=' - Setores: ' + AllTrim(MV_PAR09)
	
EndIf 

If !Empty(MV_PAR11) 

	_cQuery += " AND SRA.RA_CC >= '" + MV_PAR10 + "' AND SRA.RA_CC <= '" + MV_PAR11 + "'"

   _cTitulo+=' - Centros de custos de: ' + AllTrim(MV_PAR10)+' ate ' + AllTrim(MV_PAR11)
	
EndIf 

_cQuery += " ORDER BY RA_FILIAL,RA_MAT"

_cAliasSRA	:= GetNextAlias()   	
If Select(_cAliasSRA) > 0
	(_cAliasSRA)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAliasSRA , .T. , .F. )

COUNT TO _ntot  
_cTot:=AllTrim(Str(_ntot))
_nTam:=Len(_cTot)+1

_nConta := 0
(_cAliasSRA)->(DBGoTop())
_cAliasSRF	:= GetNextAlias()   	

While !(_cAliasSRA)->(Eof())

	SRA->(DBGoTo((_cAliasSRA)->REC))
	
    If ValType(_oProc) = "O"
       _nConta++
       _oProc:cCaption := ("Lendo funcionario " + SRA->RA_FILIAL + '/' + SRA->RA_MAT+" : "+Str(_nConta,_nTam)+" de "+_cTot )
       ProcessMessages()
    EndIf   

	//Faz query filtrando o SRF
	_cQuery := " SELECT" 
	_cQuery += "    R_E_C_N_O_  REC"
	_cQuery += " FROM "+ RetSqlName("SRF") +" SRF "
	_cQuery += " WHERE "
	_cQuery += "     SRF.D_E_L_E_T_  = ' ' "
	_cQuery += " AND SRF.RF_FILIAL = '" + AllTrim(SRA->RA_FILIAL) + "' "
	_cQuery += " AND SRF.RF_MAT = '" + AllTrim(SRA->RA_MAT) + "' " 
    If !Empty(MV_PAR01)
	   _cQuery += " AND SRF.RF_DATAFIM <= '" + DToS(MV_PAR01) + "' "
	EndIf   
	_cQuery += " AND SRF.RF_STATUS = '1' "//só os ativos 
	_cQuery += " AND SRF.RF_DATABAS <= " + DToS(DATE())
	_cQuery += " ORDER BY SRF.RF_DATABAS "
	      
	If Select(_cAliasSRF) > 0
		(_cAliasSRF)->( DBCloseArea() )
	EndIf
 
	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAliasSRF , .T. , .F. )
	
	While !(_cAliasSRF)->(Eof())
	
		SRF->(DBGoTo((_cAliasSRF)->REC))

		_ddtbase 	:= IIf(SRF->RF_DATABAS>SRA->RA_ADMISSA,SRF->RF_DATABAS,SRA->RA_ADMISSA)
	
        _cDtFimGozo := SToD("")
		_ddtiniciof := SToD("")
		_ddtfinalf  := SToD("")
		_ndiasFer   := 0 
		_ndiasAbon  := 0

		_d2dtiniciof:= SToD("")
		_d2dtfinalf := SToD("")
		_n2diasFer  := 0
		_n2diasAbon := 0

		_d3dtiniciof:= SToD("")
		_d3dtfinalf := SToD("")
		_n3diasFer  := 0
		_n3diasAbon := 0

		_ndiasprog := 0

		If  !Empty(SRF->RF_DFEPRO1) .Or. !Empty(SRF->RF_DATINI2) .Or. !Empty(SRF->RF_DATINI3)
	
			_ddtiniciof := SRF->RF_DATAINI
			_ddtfinalf 	:= SRF->RF_DATAINI+(SRF->RF_DFEPRO1-1)
			_ndiasFer   := SRF->RF_DFEPRO1
			_ndiasAbon  := SRF->RF_DABPRO1

			_ndiasprog  += SRF->RF_DFEPRO1 + SRF->RF_DABPRO1

			_d2dtiniciof := SRF->RF_DATINI2
			If !Empty(SRF->RF_DATINI2)
			   _d2dtfinalf  := SRF->RF_DATINI2+(SRF->RF_DFEPRO2-1)
			EndIf   
			_n2diasFer   := SRF->RF_DFEPRO2
			_n2diasAbon  := SRF->RF_DABPRO2

			_ndiasprog   += SRF->RF_DFEPRO2 + SRF->RF_DABPRO2

			_d3dtiniciof:= SRF->RF_DATINI3
			If !Empty(SRF->RF_DATINI3)
			   _d3dtfinalf := SRF->RF_DATINI3+(SRF->RF_DFEPRO3-1)
			EndIf   
			_n3diasFer  := SRF->RF_DFEPRO3
			_n3diasAbon := SRF->RF_DABPRO3

			_ndiasprog  += SRF->RF_DFEPRO3 + SRF->RF_DABPRO3

		ElseIf !Empty(SRF->RF_DFERANT) 

			_ndiasprog  += SRF->RF_DFERANT
		
		EndIf
	
        _nLimite   := 730-(If(MV_PAR02<31,31,MV_PAR02)) //699
		_cperINI   := DToC(SRF->RF_DATABAS) 
		_cperFIM   := DToC(SRF->RF_DATAFIM)
		_cDtLimMax := DToC(SRF->RF_DATABAS+_nLimite) 
		_ndiasvenc := SRF->RF_DFERVAT
		
		//Montagem de campo proporcional/Saldo conforme tipo de registro
		If SRF->RF_DFERVAT > 0
			_ndiasprop  := SRF->RF_DFERVAT - _ndiasprog
		Else
			_ndiasprop  := SRF->RF_DFERAAT - _ndiasprog
		EndIf
	
		_ctipo := If(SRF->RF_DFERVAT>0,"Vencida","Proporcional")
		_cSitu := "Ativo"// (A =Afastado, Vazio = Ativo, D = Demitido, T = Transferido)
		If SRA->RA_SITFOLH="A"
		   _cSitu := "Afastado
		ElseIf SRA->RA_SITFOLH="D"
		   _cSitu := "Demitido"
		ElseIf SRA->RA_SITFOLH="T"
		   _cSitu := "Transferido"
		EndIf
        
		_lLoop:=.F.
        If !Empty(MV_PAR12) .Or. !Empty(MV_PAR13)
		   
		    _lLoop:=.T.
            If !Empty(MV_PAR12) 
               If     !Empty(_ddtiniciof ) .And. _ddtiniciof  >= MV_PAR12  .And. (Empty(MV_PAR13) .Or.  _ddtiniciof  <= MV_PAR13 )
			      _lLoop:=.F.
			   ElseIf !Empty(_d2dtiniciof) .And. _d2dtiniciof >= MV_PAR12  .And. (Empty(MV_PAR13) .Or.  _d2dtiniciof <= MV_PAR13 )
			      _lLoop:=.F.
			   ElseIf !Empty(_d3dtiniciof) .And. _d3dtiniciof >= MV_PAR12  .And. (Empty(MV_PAR13) .Or.  _d3dtiniciof <= MV_PAR13 )
			      _lLoop:=.F.
			   EndIf
			ElseIf !Empty(MV_PAR13)
               If     !Empty(_ddtiniciof ) .And. _ddtiniciof  <= MV_PAR13 
			      _lLoop:=.F.
			   ElseIf !Empty(_d2dtiniciof) .And. _d2dtiniciof <= MV_PAR13 
			      _lLoop:=.F.
			   ElseIf !Empty(_d3dtiniciof) .And. _d3dtiniciof <= MV_PAR13 
			      _lLoop:=.F.
			   EndIf
			EndIf
           
        EndIf

        If _lLoop
		   (_cAliasSRF)->(DBSkip())
		   Loop
        EndIf

		If MV_PAR08 == 3 .Or. (MV_PAR08 == 1 .And. _ctipo == "Vencida") .Or. (MV_PAR08 == 2 .And. _ctipo == "Proporcional");
			.Or. (!(isincallstack("MDIEXECUTE") .Or. isincallstack("SIGAADV")) .And.  _ndiasprop > 22) //Alerta prestes a vencer no schedule

            _cDtFimGozo    := BuscaGozo(SRA->RA_FILIAL+SRA->RA_MAT)
			_cDtAfastamento:= BuscaDtAfas(SRA->RA_FILIAL,SRA->RA_MAT)
		
			aAdd(_alog,{SRA->RA_FILIAL,;   													//01 *
				fDesc("CTT",SRA->RA_CC,"CTT_DESC01",,SRA->RA_FILIAL) ,;						//02
				Posicione("ZAK",1,xFilial("ZAK")+SRA->RA_I_SETOR,"ZAK_DESCRI"),;			//03
				SRA->RA_MAT,;																//04
				If(!Empty(SRA->RA_NSOCIAL),SRA->RA_NSOCIAL,SRA->RA_NOME) ,;																//05 *
				FDESC("SQ3",SRA->RA_CARGO,"Q3_DESCSUM",,SRA->RA_FILIAL),;					//06
				AllTrim(SRA->RA_MUNICIP),;													//07			
				SRA->RA_ESTADO,;															//08
				_cperINI,;																	//09 *
				_cperFIM,;																	//10
				_cDtLimMax,;															    //11
                ;
				DToC(_ddtiniciof),;	        												//12
				DToC(_ddtfinalf ),;		    												//13
                StrZero(_ndiasFer ,4,1),;											        //14 
                StrZero(_ndiasAbon,4,1),;													//15 
				;
				DToC(_d2dtiniciof),;	    												//16
				DToC(_d2dtfinalf ),;														//17
                StrZero(_n2diasFer ,4,1),;											        //18 
                StrZero(_n2diasAbon,4,1),;													//19 
				;
				DToC(_d3dtiniciof),;	    												//20
				DToC(_d3dtfinalf ),;														//21
                StrZero(_n3diasFer ,4,1),;											        //22 
                StrZero(_n3diasAbon,4,1),;													//23 
				;
				StrZero(_ndiasvenc,4,1),;													//24
				StrZero(_ndiasprop,4,1),;													//25
				_ctipo,;																	//26
				_cDtFimGozo,;																//27 
				_cSitu,;																	//29
				_cDtAfastamento})															//30  

		EndIf

		(_cAliasSRF)->(DBSkip())
	
	EndDo

	(_cAliasSRA)->(DBSkip())
	
EndDo

aSort(_aLog,,,{|X,Y| ( X[1]+X[5]+DToS(CTOD(X[9])) ) < ( Y[1]+Y[5]+DToS(CTOD(Y[9])) ) })//ORDEM DE FILIAL + NOME + Dt. Ini. Per. Aquis

_cTot:=AllTrim(Str(Len(_alog)))

Return _alog

/*
===============================================================================================================================
Programa----------: RGPE016F
Autor-------------: Josué Danich Prestes
Data da Criacao---: 25/06/2018
Descrição---------: Formata campo de situação 
Parametros--------: String a formatar
Retorno-----------: String formatado
===============================================================================================================================
*/
Static Function RGPE016F(_cDados)

Local _cStrFormt:= ""  , x

For x:=1 To Len(_cDados)
	
	If SubStr(_cDados,x,1) != "*" 
	
		If Empty(_cStrFormt)
		
			_cStrFormt+= "("
			
		EndIf
		
		_cStrFormt+= "'" + SubStr(_cDados,x,1) + "',"
		
	EndIf
	
Next x

If !Empty(_cStrFormt)
	_cStrFormt:= SubStr(_cStrFormt,1,Len(_cStrFormt) - 1) + ")"
EndIf

Return _cStrFormt

/*
===============================================================================================================================
Programa----------: RGPE016G
Autor-------------: Josué Danich /prestes
Data da Criacao---: 10/07/2018
Descrição---------: Função para gerar arquivo CSV a partir de um Array
Parametros--------: _cTitArq  - Título do arquivo
------------------: _aHeader  - Cabeçalho do arquivo
------------------: _aCols    - Dados do arquivo
Retorno-----------: Nenhum
===============================================================================================================================
 */
User Function RGPE016G( _cTitAux , _aHeader , _aCols , _cNameFile )

Local _nHdlArq	:= 0
Local _nI		:= 0
Local _nX		:= 0
Local _cPthArq	:= '\temp'
Local _cPthDes	:= ''
Local _cNomArq	:= If(_cNameFile = NIL,'PROTHEUS_'+ StrTran( Time() , ':' , '' ) + DToS( Date() ) + RetCodUsr() +'.csv', _cNameFile +'.csv' )
Local _cArqTmp	:= _cPthArq +'\'+ _cNomArq
Local _cBuffer	:= ''

//==========================================
//Grava log de utilização da rotina
//==========================================
U_ITLOGACS()


If !Empty( _aHeader ) .And. !Empty( _aCols )

	If !ExistDir( _cPthArq )
		If MakeDir( _cPthArq ) <> 0
			U_ITMsg( 'Não foi possível criar o diretório temporário para o arquivo, informe a área de TI/ERP!', "Alerta",,1  )
			Return .F.
		EndIf
	EndIf
	
	_nHdlArq := FCreate( _cArqTmp ,,, .F. )
	
	If _nHdlArq < 0
		U_ITMsg(  'Não foi possível criar o arquivo no diretório temporário, informe a área de TI/ERP!' , "Alerta",,1 )
		Return .F.
	EndIf
	
	If !Empty( _cTitAux )
		FWrite( _nHdlArq , AllTrim( _cTitAux ) + CRLF )
	EndIf
	
	_cBuffer := ''
	
	For _nI := 1 To Len( _aHeader )
		_cBuffer += _aHeader[_nI] + ';'
	Next _nI
	
	FWrite( _nHdlArq , AllTrim( _cBuffer ) + CRLF )
	
	For _nI := 1 To Len( _aCols )
		
		_cBuffer := ''
		
		For _nX := 1 To Len( _aCols[_nI] )
			
			Do Case
				
				Case ValType( _aCols[_nI][_nX] ) == 'C'	; _cBuffer += _aCols[_nI][_nX]							+ ';'
				Case ValType( _aCols[_nI][_nX] ) == 'N'	; _cBuffer += cValToChar( _aCols[_nI][_nX] )			+ ';'
				Case ValType( _aCols[_nI][_nX] ) == 'L'	; _cBuffer += IIf( _aCols[_nI][_nX] , '.T.' , '.F.' )	+ ';'
				Case ValType( _aCols[_nI][_nX] ) == 'D'	; _cBuffer += DToC( _aCols[_nI][_nX] )					+ ';'
				OtherWise								; _cBuffer += ';'
				
			EndCase
					
		Next _nX
		
		FWrite( _nHdlArq , AllTrim( _cBuffer ) + CRLF )
		
	Next _nI
	
	FClose( _nHdlArq )

    If _cNameFile # NIL
       Return .T.
    EndIf
	
	If File( _cArqTmp )
		
		_cPthDes := U_ITSELDIR()
		LjMsgRun( 'Copiando o arquivo...' , 'Aguarde!' , {|| CpyS2T( _cArqTmp , _cPthDes , .T. ) } )
		FErase( _cArqTmp )
		
	Else
		U_ITMsg(  'Falha no processamento do arquivo, informe a área de TI/ERP!' , "Atenção",,1 )
        Return .F.
	EndIf
	
Else

	U_ITMsg(  'Não foi possível verificar os dados para a geração do arquivo, não é possível criar um arquivo em branco!' ,  "Atenção",,1 )
    Return .F.
	
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: BuscaGozo()
Autor-------------: Alex Wallauer
Data da Criacao---: 21/01/2019
Descrição---------: Busca a data da ultima ferias gozada
Parametros--------: Matricula
Retorno-----------: data da ultima ferias gozada
===============================================================================================================================
*/
Static Function BuscaGozo(cMat) 
Local _cDtFimGozo:=""

SR8->(DBSetOrder(2))  // R8_FILIAL+R8_MAT+R8_SEQ
SR8->(DBSeek(cMat))
While ! SR8->(Eof()) .And. SR8->R8_FILIAL+SR8->R8_MAT == cMat

	If SR8->R8_TIPOAFA = "001"
       _cDtFimGozo:=DToC(SR8->R8_DATAFIM)
	EndIf
	
	SR8->(DBSkip())
EndDo
//Não mostra as data menores que 60 dias 
If CTOD(_cDtFimGozo) <= (DATE()-60) 
   _cDtFimGozo:=""
EndIf
Return _cDtFimGozo

/*
===============================================================================================================================
Função------------: BuscaDtAfas
Autor-------------: Alex Wallauer
Data da Criacao---: 24/06/2020
Descrição---------: Retornar a ultima data de afastamento do funcionário.
Parametros--------: _cFilial    = Filial do funcionário
                    _cMatricula = Código de matricula
Retorno-----------: _DataAfast  = Data de afastamento do funcionário.
===============================================================================================================================
*/
Static Function BuscaDtAfas(_cFilial, _cMatricula)
Local _dRet := Ctod("  /  /  ")
Local _cQry, _cAlias
Local _aSaveArea := FWGetArea()

Begin Sequence
   _cQry := " SELECT R8_DATAINI FROM "+RetSqlName("SR8")+ " SR8 "
   _cQry += " WHERE SR8.R8_FILIAL = '" + _cFilial + "' AND SR8.D_E_L_E_T_ = ' ' "
   _cQry += " AND SR8.R8_MAT = '" + _cMatricula + "' "
   _cQry += " AND SR8.R8_TIPOAFA <> '001' "
   _cQry += " AND SR8.R8_DATAINI <= '"+DToS(Date())+"' "
   _cQry += " AND (SR8.R8_DATAFIM = '        ' OR SR8.R8_DATAFIM >= '"+DToS(Date())+"' ) "
   
   _cAlias := GetNextAlias()
		
   If Select(_cAlias) > 0
	  (_cAlias)->( DBCloseArea() )
   EndIf
		
   DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQry) , _cAlias , .F. , .T. )
   TCSetField(_cAlias,"R8_DATAINI","D",8,0)
		
   (_cAlias)->( DBGoTop() )
   
   While (_cAlias)->( !Eof() )
	  If ! Empty((_cAlias)->R8_DATAINI)
	     If DToS(_dRet) < DToS((_cAlias)->R8_DATAINI)
	        _dRet := (_cAlias)->R8_DATAINI
	     EndIf
	  EndIf
			
      (_cAlias)->( DBSkip() )
   EndDo
		
   (_cAlias)->( DBCloseArea() )

End Sequence

FWRestArea(_aSaveArea)

Return _dRet
