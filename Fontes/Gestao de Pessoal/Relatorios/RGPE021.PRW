/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGPE021
Autor-------------: Alex Wallauer
Data da Criacao---: 10/09/2021
Descrição---------: Relatório de Conferências de Folgas do dia 31 . Chamado 37715
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGPE021()

Local _cTitulo    := "Relatório de Conferências de Folgas do dia 31" , M , C
Private _nMesMax  := 12
Private _aPeriodo := {}
Private _aPergunts:= {}

SET DATE FORMAT TO "DD/MM/YYYY"

While Pergunte("RGPE021",,_cTitulo)	          
                                                                                                             //ANO INICIAL          MAIOR QUE ANO FINAL                       //SE ANOS IGUAIS                       E   MES INICIAL         MAIOR QUE MES FINAL
   If (Len(AllTrim(MV_PAR06))+Len(AllTrim(MV_PAR07))) < 12 .OR.;
       Empty(MV_PAR06) .Or.  Empty(MV_PAR07) .OR.;
       Val(SUBST(AllTrim(MV_PAR07),3,4)) < Val(SUBST(AllTrim(MV_PAR06),3,4)) .OR.;
       Val(SUBST(MV_PAR06,3)) > Val(SUBST(MV_PAR07,3)) .OR.;
      (Val(SUBST(MV_PAR06,3)) = Val(SUBST(MV_PAR07,3)) .AND.;
       Val(LEFT(MV_PAR06,2)) > Val(LEFT(MV_PAR07,2))  )
      U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo com as 2 datas preenchidas no formato MMAAAA",3)
      Loop
   EndIf
   MV_PAR06 := SubStr(MV_PAR06,1,2) + "/" + SubStr(MV_PAR06,3,4)
   MV_PAR07 := SubStr(MV_PAR07,1,2) + "/" + SubStr(MV_PAR07,3,4)

   
   If AllTrim(MV_PAR06) == AllTrim(MV_PAR07)
      nMeses := 1
   ElseIf Val(SubStr(AllTrim(MV_PAR07),1,2)) - Val(SubStr(AllTrim(MV_PAR06),1,2)) = 1
      nMeses := 2 
   Else
      nMeses := INT((((LASTDAY(CTOD("01/"+MV_PAR07))-(CTOD("01/"+MV_PAR06)))/30)))+1
   EndIf
   
   If nMeses > _nMesMax
      U_ITMsg("Periodo INVALIDO de "+AllTrim(Str(nMeses))+" meses." ,'Atenção!',"Periodo nao pode ser maior que 12 meses",3)
      Loop
   EndIf

   cTimeInicial:=Time()
   _cTexto:= AllTrim(MV_PAR06)
   aAdd(_aPeriodo,_cTexto)//o primeiro periodo coloco fora do For por isso (_nMesMax-1)
   For M := 1 TO (_nMesMax-1)//MONTA SEMPRE _nMesMax DE MESES , INDENPENDETE DO PERIODO FILTRO 
       _nMes:=Val(SubStr(_cTexto,1,2))
       If _nMes < 12//NAO mexer nesse numero 12 é referente a DESEMBRO
          _cTexto:=StrZero(_nMes+1,2)+SubStr(_cTexto,3)//SOMA AQUI + 1 MES NO MESMO ANO
       Else
          _cTexto:="01/"+AllTrim(Str(Val(SubStr(_cTexto,4))+1))//SOMA AQUI + 1 ANO QUANDO TROCA DE DESEMBRO PARA JANEIRO 
       EndIf
       aAdd(_aPeriodo,_cTexto)
   Next
   MV_PAR06 := CTOD("01/"+ MV_PAR06)
   MV_PAR07 := LASTDAY(CTOD("01/"+ MV_PAR07))
   MV_PAR08 := U_ITSEPDEL( MV_PAR08 , 1 , ";" , "*" )
   _aDados  := {}
   _lSair   := .F.

   FWMsgRun( ,{|oproc| _aDados := RGPE021SEL(oproc) } , "Aguarde!" , "Lendo dados..." )

    If Len(_aDados) > 0

        aCab:={}
        aAdd(aCab,"Filial")
        aAdd(aCab,"Matricula")
        aAdd(aCab,"Nome") ; nPosFiltro:=Len(aCab)
        aAdd(aCab,"Dt. Admissao")
        aAdd(aCab,"Setor")
        aAdd(aCab,"Funcao")
        aAdd(aCab,"Turno")
        aAdd(aCab,"Banco de Horas")
        aAdd(aCab,"Faltas")
        aAdd(aCab,"Dias Gozados")
        For M := 1 TO Len(_aPeriodo) 
            aAdd(aCab,_aPeriodo[M])
        Next
        aAdd(aCab,"Total Dias Afastamento")

        aAdd(_aPergunts,{"0-FILTROS"         ,""})
        aAdd(_aPergunts,{"1-Filial/Filiais?" ,AllTrim(AllToChar(MV_PAR01))})
        aAdd(_aPergunts,{'2-Matricula De ?'  ,AllTrim(AllToChar(MV_PAR02))})
        aAdd(_aPergunts,{'3-Matricula Até ?' ,AllTrim(AllToChar(MV_PAR03))})
        aAdd(_aPergunts,{'4-Setor De ?'      ,AllTrim(AllToChar(MV_PAR04))})
        aAdd(_aPergunts,{'5-Setor Ate ?'     ,AllTrim(AllToChar(MV_PAR05))})
        aAdd(_aPergunts,{"6-Mes/Ano Inicial?",AllTrim(AllToChar(MV_PAR06))})
        aAdd(_aPergunts,{"7-Mes/Ano Final?"  ,AllTrim(AllToChar(MV_PAR07))})
        aAdd(_aPergunts,{'8-Situações ?'     ,AllTrim(AllToChar(MV_PAR08))})

        For M := 1 TO Len (_aPergunts)
            aAdd( _aDados, {} )
            For C := 1 TO Len(aCab)
		          aAdd( _aDados[Len(_aDados)], "" )
            Next
            _aDados[Len(_aDados),nPosFiltro]:=_aPergunts[M,1]+" "+_aPergunts[M,2]//Na coluna no coloca os parametros 
        Next

        _cTitulo:="Relatório de Conferências de Folgas do dia 31"+' - Data: ' + DToC(Date()) +" -  H.I.: "+cTimeInicial+" H.F.: "+Time()
        _cMsgTop:="Par. 1: "+AllTrim(AllToChar(MV_PAR01))+"; Par. 2: "+AllTrim(AllToChar(MV_PAR02))+"; Par. 3: "+AllTrim(AllToChar(MV_PAR03))+"; Par. 4: "+AllTrim(AllToChar(MV_PAR04))+;
                "; Par. 5: "+AllTrim(AllToChar(MV_PAR05))+"; Par. 6: "+AllTrim(AllToChar(MV_PAR06))+"; Par. 7: "+AllTrim(AllToChar(MV_PAR07))+"; Par. 7: "+AllTrim(AllToChar(MV_PAR08))

                                //       ,_aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca )
       _lSair:=!U_ITListBox(_cTitulo,aCab,_aDados , .T.    , 1    ,_cMsgTop,          ,        ,         ,     ,        ,          ,       ,         ,          ,            )
    
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
Programa----------: RGPE021SEL
Autor-------------: Alex Wallauer
Data da Criacao---: 10/09/2021
Descrição---------: Carga de dados para o relatório
Parametros--------: oproc - objeto da barra de processmento 
Retorno-----------: _aRet - dados coletados do banco
===============================================================================================================================
*/
Static Function RGPE021SEL(oproc)


Local _aRet			:= {}
Local _cAlias		:= GetNextAlias()
Local _aFiliais		:= {}
Local _cQuery		:= ""
Local _nI , T		:= 0

Default oproc := nil

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
	If !Empty(MV_PAR02) .And. !Empty(MV_PAR03)
		_cQuery += " AND RA_MAT BETWEEN '"+ MV_PAR02 +"' AND '"+ MV_PAR03 +"' "+ CRLF
	EndIf
	If !Empty(MV_PAR04) .And. !Empty(MV_PAR05) 
		_cQuery += " AND RA_I_SETOR BETWEEN '"+ MV_PAR04 +"' AND '"+ MV_PAR05 +"' "+ CRLF
	EndIf 
	If !Empty(MV_PAR08)
		_cQuery += " AND SRA.RA_SITFOLH IN "+ FormatIn( AllTrim( MV_PAR08 ) , ";" )	+ CRLF
	EndIf
   _cQuery += " ORDER BY SRA.RA_MAT "
	
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
		
        If ValType(oproc) = "O"
		    _nni++
			oproc:cCaption := ("Lendo Filial: " + _aFiliais[_nI] + " / funcionario " +StrZero(_nni,_nTam) +" de "+ _cTot )
			ProcessMessages()
		EndIf
		SRA->(DBGoTo((_cAlias)->RECNO))

      _nFaltas	:= _nAbono := 0
      BuscaEventos()
      aTestados:=BuscaAfas(SRA->RA_FILIAL,SRA->RA_MAT)
					
		aAdd( _aRet , {	;
                        AllTrim(SRA->RA_FILIAL)	                                                                    ,; //Filial
						      AllTrim(SRA->RA_MAT)						                                                        ,; //Matrícula
						      AllTrim(Capital(AllTrim(If(!Empty(SRA->RA_NSOCIAL),SRA->RA_NSOCIAL,SRA->RA_NOME) )))        ,; //Funcionário
						      DToC(SRA->RA_ADMISSA)				                                                           ,; //Dt Admissao 
						      AllTrim(SRA->RA_I_SETOR+"-"+Posicione("ZAK",1,xFilial("ZAK")+SRA->RA_I_SETOR,"ZAK_DESCRI")) ,; //Desc. Setor
							   AllTrim(Posicione("SRJ",1,xFilial("SRJ")+SRA->RA_CODFUNC,"RJ_DESC"))                        ,; //Desc. Funçao 
						      AllTrim(SRA->RA_TNOTRAB+"-"+Posicione("SR6",1,SRA->RA_FILIAL+SRA->RA_TNOTRAB,"R6_DESC"))	  ,; //Desc. Turno
                        If(SPI->(DBSeek( SRA->RA_FILIAL + SRA->RA_MAT )),"Sim","Nao")                               ,; //Banco de Horas
                        AllTrim(Str(_nFaltas))                                                                      ,; //Faltas
						      AllTrim(Str(_nAbono))			                                                              }) //DIAS GOZADOS
        _nTotAfastados:=0
        For T := 1 TO Len (aTestados)
		    aAdd( _aRet[Len(_aRet)] , AllTrim(Str(aTestados[T])))
          _nTotAfastados+=aTestados[T]
        Next
	     aAdd( _aRet[Len(_aRet)] , AllTrim(Str(_nTotAfastados)))//"Total de dias Afastamento"			                                                        ,; //Total de dias Afastamento
						
		
        (_cAlias)->(DBSkip())
		
	EndDo

Next _nI

Return( _aRet )
/*
===============================================================================================================================
Função------------: BuscaAfas
Autor-------------: Alex Wallauer
Data da Criacao---: 24/06/2020
Descrição---------: Retornar a ultima data de afastamento do funcionário.
Parametros--------: _cFilial    = Filial do funcionário
                    _cMatricula = Código de matricula
Retorno-----------: _DataAfast  = Data de afastamento do funcionário.
===============================================================================================================================
*/
Static Function BuscaAfas(_cFilial, _cMatricula)
Local _cQry      :=""
Local _cAlias    := GetNextAlias()
Local _aTestados :={} , M
Local _dUltDiaMes:= LASTDAY(dDatabase)


For M := 1 TO _nMesMax
    aAdd(_aTestados,0)
Next

_cQry += " SELECT R8_DATAINI , R8_DATAFIM FROM "+RetSqlName("SR8")+ " SR8 "+ CRLF
_cQry += " WHERE SR8.R8_FILIAL = '" + _cFilial + "' AND SR8.D_E_L_E_T_ = ' ' "+ CRLF
_cQry += " AND SR8.R8_MAT = '" + _cMatricula + "' "+ CRLF
_cQry += " AND SR8.R8_TIPOAFA <> '001' "+ CRLF
_cQry += " AND (SR8.R8_DATAINI BETWEEN '"+ DToS( MV_PAR06 ) +"' AND '"+ DToS( MV_PAR07 ) +"'  "+ CRLF
_cQry += "  OR  SR8.R8_DATAFIM BETWEEN '"+ DToS( MV_PAR06 ) +"' AND '"+ DToS( MV_PAR07 ) +"'  "+ CRLF
_cQry += "  OR  (SR8.R8_DATAFIM = ' '  AND SR8.R8_DATAINI <= '"+ DToS( MV_PAR07 )        +"'))"+ CRLF
_cQry += " ORDER BY SR8.R8_DATAINI "
		
DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQry) , _cAlias , .F. , .T. )
	
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )
  
   If SToD((_cAlias)->R8_DATAINI) > MV_PAR06//DATA INICIAL MAIOR QUE A DO FILTRO VALE ELA 
      _dDtAux:=SToD((_cAlias)->R8_DATAINI)
   Else//SENÃO A DO FILTRO
      _dDtAux:=MV_PAR06
   EndIf

   If Empty((_cAlias)->R8_DATAFIM)  .Or. SToD((_cAlias)->R8_DATAFIM) > MV_PAR07//SE DATA FIM EM BRANCO OU MAIOR QUE A DO FILTRO VALE A DO FILTRO
      If MV_PAR07 <= _dUltDiaMes//SE DATA FIM DO FILTRO For MENOR QUE A DO DIA DO MES CORRENTE
         _dDtFimAux:=MV_PAR07
      Else
         _dDtFimAux:=_dUltDiaMes
      EndIf
   Else
      _dDtFimAux:=SToD((_cAlias)->R8_DATAFIM)
   EndIf

   While _dDtAux <= _dDtFimAux
      
      _cAchaCol:=SubStr(DToS(_dDtAux),5,2)+"/"+LEFT(DToS(_dDtAux),4)
      
      nPos :=aScan(_aPeriodo,_cAchaCol)
      If nPos > 0
         _aTestados[nPos]++//SOMA NO MES DA DATA
     Else//TEM QUE ACHAR PQ SENAO TEM ALGUMA COISA ERRADA NA BASE
        U_ITMsg("Periodo "+_cAchaCol+" nao encontrado [ "+DToC(_dDtAux)+" ]",'Atenção!',"FAVOR ENTRAR EM CONTATO COM A AREA DE TI COM PRINT DESSA MENSAGEM",3)
        Exit
     EndIf   
      _dDtAux:=(_dDtAux+1)//SOMA 1 DIA NA DATA CORRENTE
   EndDo
		
   (_cAlias)->( DBSkip() )
EndDo
	
(_cAlias)->( DBCloseArea() )


Return _aTestados

/*
===============================================================================================================================
Programa----------: BuscaEventos
Autor-------------: Alex Wallauer
Data da Criacao---: 24/06/2020
Descrição---------: Retorna Faltas do funcionario.	
Parametros--------: SRA POSICIONADA
Retorno-----------: Preenche _nFaltas / _nAbono
===============================================================================================================================
*/
Static Function BuscaEventos()
Local _cAlias	:= GetNextAlias()
Local _cQuery	:= ""

_cQuery += " SELECT SPC.PC_PD PD_413 ,SPC.PC_ABONO ABONO_28 "+ CRLF
_cQuery += " FROM "+ RetSqlName("SPC") +" SPC "+ CRLF
_cQuery += " WHERE "+ CRLF
_cQuery += "     SPC.D_E_L_E_T_  = ' ' "+ CRLF
_cQuery += " AND (SPC.PC_PD  = '413' "+ CRLF
_cQuery += " OR   SPC.PC_ABONO = '028') " + CRLF
_cQuery += " AND SPC.PC_FILIAL  = '"+ SRA->RA_FILIAL +"' " + CRLF
_cQuery += " AND SPC.PC_DATA BETWEEN '"+ DToS( MV_PAR06 ) +"' AND '"+ DToS( MV_PAR07 ) +"' "+ CRLF
_cQuery += " AND SPC.PC_MAT = '"+SRA->RA_MAT+"' "+ CRLF

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .T. )


While !(_cAlias)->(Eof())
   If (_cAlias)->ABONO_28 = '028'
      _nAbono++
   ElseIf (_cAlias)->PD_413 = "413" .And. Empty((_cAlias)->ABONO_28)
     _nFaltas++
   EndIf
   (_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())

_cQuery := " SELECT SPH.PH_PD PD_413,SPH.PH_ABONO ABONO_28"+ CRLF
_cQuery += " FROM "+ RetSqlName("SPH") +" SPH "+ CRLF
_cQuery += " WHERE "+ CRLF
_cQuery += "     SPH.D_E_L_E_T_  = ' ' "+ CRLF
_cQuery += " AND (SPH.PH_PD  = '413' "+ CRLF
_cQuery += " OR   SPH.PH_ABONO = '028') " + CRLF
_cQuery += " AND SPH.PH_FILIAL  = '"+ SRA->RA_FILIAL +"' " + CRLF
_cQuery += " AND SPH.PH_DATA BETWEEN '"+ DToS( MV_PAR06 ) +"' AND '"+ DToS( MV_PAR07 ) +"' "+ CRLF
_cQuery += " AND SPH.PH_MAT = '"+SRA->RA_MAT+"' "+ CRLF

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .T. )

While !(_cAlias)->(Eof())
   If (_cAlias)->ABONO_28 = '028'
      _nAbono++
   ElseIf (_cAlias)->PD_413 = "413" .And. Empty((_cAlias)->ABONO_28)
     _nFaltas++
   EndIf
   (_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())

Return .T.
