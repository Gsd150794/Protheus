/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/
   
#Include "TOTVS.ch"
#Include "topconn.ch"

/*
===============================================================================================================================
Programa----------: RGPE002
Autor-------------: Alex Wallauer
Data da Criacao---: 19/12/2023
Descrição---------: Chamdo 45898 - Fernando. Relatório Motivo de Contratação.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function RGPE002()
Local _oReport	   := Nil
Private _cCodTurno := ""
Private _cDescTurno:= ""
Private _dDataSPF  := Ctod("  /  /  ")
Private _cPerg	   := "RGPE002"
Private _cTitulo   := "Relatório Motivo de Contratação"

If !Pergunte(  _cPerg ,,_cTitulo )
   Return .F. 
EndIf

_oReport := RGPE002PRC()
_oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: RGPE002PRC
Autor-------------: Alex Wallauer
Data da Criacao---: 19/12/2023
Descrição---------: Processa a impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
/*/

Static Function RGPE002PRC()

Local _oReport	:= Nil
Local _oSec001	:= Nil
Local _oSec002	:= Nil
Local _oSec003	:= Nil
Local _cAliaSRA	:= "SRA"
Local _cAliaQRY	:= GetNextAlias()

_oReport := TReport():New( "RGPE002" , _cTitulo , "RGPE002" , {|_oReport| RGPE002PRT( _oReport , _cAliaSRA , _cAliaQRY ) } , _cTitulo , .T. )
_oReport:SetLandScape(.T.) /// Aqui que define Retrato ou Paisagem  
_oReport:SetDevice(4)
_oReport:lEmptyLineExcel:=.F.
_oReport:nExcelPrintType:=3

//====================================================================================================
//SECAO 1
//====================================================================================================
_oSec001 := TRSection():New( _oReport , _cTitulo , {""} )
_oSec001:SetTotalInLine(.F.)
TRCell():New( _oSec001 , "" ,, "" ,,,, )

//====================================================================================================
//SECAO 2
//====================================================================================================
_oSec002 := TRSection():New( _oSec001 , "" , {""} )
_oSec002:SetTotalInLine(.F.)
TRCell():New( _oSec002 , "SETOR"	,,"Setor: "	,, 50 ,, {||(_cAliaQRY)->SETOR + " - " + (_cAliaQRY)->DSETOR }	)
TRCell():New( _oSec002 , "TOTSET"	,,""		,, 05 ,, 			)


If MV_PAR16 == 1 // Totais somente quando usa ordem por setor

	TRFunction():New( _oSec002:Cell("TOTSET") ,, "COUNT" ,, "TOTAL GERAL DE SETORES " ,,, .F. , .T. )
	_oSec002:SetTotalText( "TOTAL DE SETORES" )

EndIf

//====================================================================================================
//SECAO 3
//====================================================================================================
_oSec003 := TRSection():New( _oSec001 , _cTitulo , {"SRA"} )
_oSec003:SetTotalInLine(.F.)

TRCell():New( _oSec003 , "FILIAL"	,, "Filial"		    ,						, 02 ,, )
TRCell():New( _oSec003 , "MATR"	    ,, "Matricula"      , "999999"	            , 10 ,, )
TRCell():New( _oSec003 , "NOME"		,, "Nome"			,                       , 30 ,, {|| If(!Empty((_cAliaQRY)->NSOCIAL),AllTrim((_cAliaQRY)->NSOCIAL)+".",(_cAliaQRY)->NOME)	} )
TRCell():New( _oSec003 , "SEXO"		,, "SEXO"			,						, 30 ,, )
TRCell():New( _oSec003 , "DTNASC"	,, "Dt. Nasc."		,						, 10 ,, )
TRCell():New( _oSec003 , "DTADMI"	,, "Dt. Adm."		,						, 10 ,, )
TRCell():New( _oSec003 , "CENTROC"	,, " C.Custo"		,						, 10 ,, )
TRCell():New( _oSec003 , "DCENTROC"	,, "Desc CC"        ,						, 10 ,, )
TRCell():New( _oSec003 , "SETOR"	,, "Setor"			,						, 06 ,, )
TRCell():New( _oSec003 , "DSETOR"	,, "Desc Setor"		,						, 24 ,, )
TRCell():New( _oSec003 , "CFUNCAO"	,, "Função"			,						, 06 ,, )
TRCell():New( _oSec003 , "FUNCAO"	,, "Desc Função"	,						, 19 ,, )
If MV_PAR14 == 1
   TRCell():New( _oSec003,"SALARIO"	,, "Salario"		, "@E 9,999,999.99"		, 12 ,, )
EndIf
TRCell():New( _oSec003 , "CTURNO"	,, "Turno"			,						, 10 ,, {|| U_RGPE002T("CTURNO", (_cAliaQRY)->FILIAL , (_cAliaQRY)->MATR)} )
TRCell():New( _oSec003 , "TURNO"	,, "Desc Turno"  	,						, 50 ,, {|| U_RGPE002T("TURNO" , (_cAliaQRY)->FILIAL , (_cAliaQRY)->MATR)} )
TRCell():New( _oSec003 , "RA_I_MOTSU",, "Motivo da Contração", "@!"             , 20 ,, )
TRCell():New( _oSec003 , "RA_I_MATSU",, "Matricula Substituida","@!"	        , 10 ,, )
TRCell():New( _oSec003 , "S_NOME"	 ,, "Nome"			,                       , 30 ,, {|| If(!Empty((_cAliaQRY)->S_NSOCIAL),AllTrim((_cAliaQRY)->S_NSOCIAL)+".",(_cAliaQRY)->S_NOME)	} )
TRCell():New( _oSec003 , "S_SEXO"	 ,, "SEXO"			,						, 30 ,, )
TRCell():New( _oSec003 , "S_DTNASC"	 ,, "Dt. Nasc."		,						, 10 ,, )
TRCell():New( _oSec003 , "S_DTADMI"	 ,, "Dt. Adm."		,						, 10 ,, )
TRCell():New( _oSec003 , "S_DTDEMI"	 ,, "Dt. Demissao"	,						, 10 ,, )
TRCell():New( _oSec003 , "S_CENTROC" ,, " C.Custo"		,						, 10 ,, )
TRCell():New( _oSec003 , "S_DCENTROC",, "Desc CC"       ,						, 10 ,, )
TRCell():New( _oSec003 , "S_SETOR"	 ,, "Setor"			,						, 06 ,, )
TRCell():New( _oSec003 , "S_DSETOR"	 ,, "Desc Setor"	,						, 24 ,, )
TRCell():New( _oSec003 , "S_CFUNCAO" ,, "Função"		,						, 06 ,, )
TRCell():New( _oSec003 , "S_FUNCAO"	 ,, "Desc Função"	,						, 19 ,, )
If MV_PAR14 == 1
   TRCell():New( _oSec003,"S_SALARIO",, "Salario"		, "@E 9,999,999.99"		, 12 ,, )
EndIf
TRCell():New( _oSec003 , "S_CTURNO"	 ,, "Turno"			,						, 10 ,, {|| U_RGPE002T("CTURNO", (_cAliaQRY)->FILIAL , (_cAliaQRY)->S_MATR)} )
TRCell():New( _oSec003 , "S_TURNO"	 ,, "Desc Turno"  	,						, 50 ,, {|| U_RGPE002T("TURNO" , (_cAliaQRY)->FILIAL , (_cAliaQRY)->S_MATR)} )

TRFunction():New( _oSec003:Cell("FILIAL") ,, "COUNT" ,, "TOTAL GERAL DE FUNCIONARIOS " ,,, .T. , .T.,.F.)

Return( _oReport )

/*
===============================================================================================================================
Programa----------: RGPE002PRT
Autor-------------: Alex Wallauer
Data da Criacao---: 19/12/2023
Descrição---------: Consulta e Impressão dos dados do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGPE002PRT( _oReport , _cAliaSRA , _cAliaQRY )

Local _oSec003	:= _oReport:Section(1):Section(2)
Local _cFiltro	:= ''
Local _cFilIn	:= ''
Local _cQuery	:= "% "
Local _oXml		:= Nil
Local _nI		:= 0

_oReport:Section(1):Section(2):XmlLoad( _oXml )

//====================================================================================================
// Trata o filtro de Situação na Folha
//====================================================================================================
For _nI := 1 To Len( MV_PAR11 )

	_cFiltro	:= SubStr( MV_PAR11 , _nI , 1 )
	_cFilIn		+= _cFiltro + ","
	
Next _nI

If !Empty( _cFilIn )
	_cFilIn := SubStr( _cFilIn , 1 , Len(_cFilIn) - 1 )
	_cQuery += " AND SRA.RA_SITFOLH IN "+ FormatIn( _cFilIn , ',' )
EndIf
	
//====================================================================================================
// Trata o filtro da Data de Demissão
//====================================================================================================
If !Empty(MV_PAR17) .And. !Empty(MV_PAR18)
	_cQuery += " AND SRA.RA_DEMISSA BETWEEN '"+ DToS(MV_PAR17) +"' AND '"+ DToS(MV_PAR18) +"' "
EndIf

//====================================================================================================
// Trata o filtro da Data de Admissao
//====================================================================================================
If !Empty(MV_PAR19) .And. !Empty(MV_PAR20)
	_cQuery += " AND SRA.RA_ADMISSA BETWEEN '"+ DToS(MV_PAR19) +"' AND '"+ DToS(MV_PAR20) +"' "
EndIf

//====================================================================================================
// Trata o filtro de Situação na Folha
//====================================================================================================
_cFilIn := ""
For _nI := 1 To Len( MV_PAR12 )

	_cFiltro	:= SubStr( MV_PAR12 , _nI , 1 )
	_cFilIn		+= _cFiltro + ","
	
Next _nI

If !Empty( _cFilIn )
	_cFilIn := SubStr( _cFilIn , 1 , Len(_cFilIn) - 1 )
	_cQuery += " AND SRA.RA_CATFUNC IN "+ FormatIn( _cFilIn , ',' )
EndIf

If ( MV_PAR13 <> 3 )
	_cQuery += " AND SRA.RA_TPCONTR = '"+ cValToChar( MV_PAR13 ) +"' "
EndIf

If ( MV_PAR21 <> 4 )
	_cQuery += " AND SRA.RA_I_MOTSU = '"+ cValToChar( MV_PAR21 ) +"' "
EndIf

If !Empty( MV_PAR15)
    MV_PAR15 := U_ITSEPDEL( AllTrim( MV_PAR15) , 1 , ";" , "*" )
	_cQuery += " AND SRA.RA_CODFUNC IN "+ FormatIn( ( MV_PAR15) , ';' )
EndIf

If MV_PAR16 == 2
    _cQuery += " ORDER BY SRA.RA_FILIAL , SRA.RA_NOMECMP "
Else
	_cQuery += " ORDER BY SRA.RA_FILIAL , SRA.RA_I_SETOR , SRA.RA_MAT "
EndIf

_cQuery += " %"

If DToS(MV_PAR20) > DToS(Date()) 
   _cdat := DToS(MV_PAR20)
   _dDataSPF := MV_PAR20
Else
   _cdat := DToS(date())
   _dDataSPF := Date()
EndIf

_oSec003:BeginQuery()

	BeginSql Alias _cAliaQRY
	
		SELECT
			SRA.RA_FILIAL   FILIAL,
			SRA.RA_MAT      MATR,
			SRA.RA_NOMECMP  NOME,
			SRA.RA_NSOCIAL  NSOCIAL,
			SRA.RA_SEXO     SEXO,
			SRA.RA_NASC     DTNASC,
			SRA.RA_ADMISSA  DTADMI, 
			SRA.RA_CC       CENTROC, 
			CTT.CTT_DESC01  DCENTROC,
			SRA.RA_I_SETOR  SETOR, 
			ZAK.ZAK_DESCRI  DSETOR,
			SRA.RA_CODFUNC  CFUNCAO,
			SRJ.RJ_DESC     FUNCAO,
			SRA.RA_SALARIO  SALARIO,
			SRA.RA_SITFOLH  SITFOL,
			SRA.RA_I_MOTSU  ,
            SRA.RA_I_MATSU  ,
			SRA2.RA_MAT     S_MATR,
			SRA2.RA_NOMECMP S_NOME,
			SRA2.RA_NSOCIAL S_NSOCIAL,
			SRA2.RA_SEXO    S_SEXO,
			SRA2.RA_NASC    S_DTNASC,
			SRA2.RA_ADMISSA S_DTADMI, 
			SRA2.RA_DEMISSA S_DTDEMI, 			
			SRA2.RA_CC      S_CENTROC, 
			CTT2.CTT_DESC01 S_DCENTROC,
			SRA2.RA_I_SETOR S_SETOR, 
			ZAK2.ZAK_DESCRI S_DSETOR,
			SRA2.RA_CODFUNC S_CFUNCAO,
			SRJ2.RJ_DESC    S_FUNCAO,
			SRA2.RA_SALARIO S_SALARIO        
		FROM %Table:SRA% SRA		
		     LEFT JOIN %Table:SRJ% SRJ  ON SRA.RA_CODFUNC  = SRJ.RJ_FUNCAO  AND SRJ.RJ_FILIAL   = SRA.RA_FILIAL//EXCLUSIVO
			 LEFT JOIN %Table:ZAK% ZAK  ON SRA.RA_I_SETOR  = ZAK.ZAK_COD    AND ZAK.ZAK_FILIAL  = %xFilial:ZAK%//COMPARTILHADO
			 LEFT JOIN %Table:CTT% CTT  ON SRA.RA_CC       = CTT.CTT_CUSTO  AND CTT.CTT_FILIAL  = %xFilial:CTT%//COMPARTILHADO		     
			 LEFT JOIN %Table:SRA% SRA2 ON SRA2.RA_MAT     = SRA.RA_I_MATSU AND SRA2.RA_FILIAL  = SRA.RA_FILIAL//EXCLUSIVO		     
			 LEFT JOIN %Table:SRJ% SRJ2 ON SRA2.RA_CODFUNC = SRJ2.RJ_FUNCAO AND SRA2.RA_FILIAL  = SRJ2.RJ_FILIAL AND SRJ2.%notdel%//EXCLUSIVO
			 LEFT JOIN %Table:ZAK% ZAK2 ON SRA2.RA_I_SETOR = ZAK2.ZAK_COD   AND ZAK2.ZAK_FILIAL = %xFilial:ZAK2% AND ZAK2.%notdel%//COMPARTILHADO
			 LEFT JOIN %Table:CTT% CTT2 ON SRA2.RA_CC      = CTT2.CTT_CUSTO AND CTT2.CTT_FILIAL = %xFilial:CTT2% AND CTT2.%notdel%//COMPARTILHADO        
		WHERE SRA.%notdel%
	 	  AND SRJ.%notdel%
	 	  AND ZAK.%notdel%
	 	  AND CTT.%notdel%   
		  AND SRA.RA_I_MOTSU <> ' '
 		  AND ( SRA.RA_FILIAL  BETWEEN %Exp:MV_PAR01% AND %Exp:MV_PAR02% )
		  AND ( SRA.RA_CC      BETWEEN %Exp:MV_PAR03% AND %Exp:MV_PAR04% )
		  AND ( SRA.RA_MAT     BETWEEN %Exp:MV_PAR05% AND %Exp:MV_PAR06% )
		  AND ( SRA.RA_I_SETOR BETWEEN %Exp:MV_PAR07% AND %Exp:MV_PAR08% )
	      AND ( SRA.RA_NOME    BETWEEN %Exp:MV_PAR09% AND %Exp:MV_PAR10% )
		%Exp:_cQuery%									

	EndSql

_oSec003:EndQuery()

If MV_PAR16 == 1 //Ordem por setor

	_oReport:Section(1):Section(1):Init()
	_oReport:Section(1):Section(1):PrintLine()

EndIf

_oReport:Section(1):Section(2):Init()

_cSetor := (_cAliaQRY)->SETOR
nTot:=0
COUNT TO nTot
_oReport:OMETER:NTOTAL:=nTot 

(_cAliaQRY)->(DBGoTop() )

While !_oReport:Cancel() .And. (_cAliaQRY)->( !Eof() )
    
	_oReport:IncMeter()

    _oReport:Section(1):Section(2):Cell("DTNASC"):SetValue(SToD((_cAliaQRY)->DTNASC))
    _oReport:Section(1):Section(2):Cell("DTADMI"):SetValue(SToD((_cAliaQRY)->DTADMI))

    _oReport:Section(1):Section(2):Cell("S_DTNASC"):SetValue(SToD((_cAliaQRY)->S_DTNASC))
    _oReport:Section(1):Section(2):Cell("S_DTADMI"):SetValue(SToD((_cAliaQRY)->S_DTADMI))
    _oReport:Section(1):Section(2):Cell("S_DTDEMI"):SetValue(SToD((_cAliaQRY)->S_DTDEMI))
    
	If MV_PAR16 == 1
	
		If SubStr( AllTrim(_cSetor) , 1 , 6 ) <> SubStr( AllTrim( (_cAliaQRY)->SETOR ) , 1 , 6 )
		
			_oReport:Section(1):Section(1):Finish()
			_oReport:Section(1):Section(2):Finish()
			_oReport:Section(1):Section(1):Init()
			_oReport:Section(1):Section(1):PrintLine()
			_oReport:Section(1):Section(2):Init()
			_oReport:Section(1):Section(2):PrintLine() 
			_cSetor := (_cAliaQRY)->SETOR
			
		Else
		
			_oReport:Section(1):Section(2):PrintLine()
			
		EndIf
		
	Else
	
		_oReport:Section(1):Section(2):PrintLine()
		
	EndIf
	
(_cAliaQRY)->( DBSkip() )
EndDo

If MV_PAR16 == 1 //Ordem por setor

	_oReport:Section(1):Section(1):Finish()
	_oReport:Section(1):Section(1):Init()

EndIf

_oReport:Section(1):Section(2):Finish()
_oReport:Section(1):Section(2):Init()

Return

/*
===============================================================================================================================
Função------------: RGPE002T
Autor-------------: Alex Wallauer
Data da Criacao---: 19/12/2023
Descrição---------: Retornar o código e a descrição do turno.
Parametros--------: _cCampo = Campo que chamou a função.
                    _cCodFilial = Codigo da Filial
					_cMatricula = Codigo da Matricula
Retorno-----------: _cRet = Retorna o código ou a descrição do turno.
===============================================================================================================================
*/
User Function RGPE002T(_cCampo, _cCodFilial, _cMatricula)
Local _cRet := ""
Local _cQry 
If Empty(_cMatricula)
   Return Space(Len(SR6->R6_DESC))
EndIf
Begin Sequence

   If _cCampo == "CTURNO"
      _cQry := " SELECT MAX(R_E_C_N_O_) NRRECNO FROM "+ RetSqlName("SPF") + " SPF " 
	  _cQry += " WHERE SPF.PF_FILIAL = '" + _cCodFilial + "' "
	  _cQry += " AND SPF.PF_MAT = '" + _cMatricula + "' "
	  _cQry += " AND SPF.PF_DATA <= '" + DToS(_dDataSPF) + "' "
	  _cQry += " AND SPF.D_E_L_E_T_ = ' ' "
     
      If Select("TRBSPF") > 0
	     TRBSPF->(DBCloseArea())
      EndIf
      
	  TCQUERY _cQry NEW ALIAS "TRBSPF"	
   
      If TRBSPF->(Eof()) .Or. TRBSPF->(Bof()) .Or. TRBSPF->NRRECNO == 0
         _cCodTurno  := "SEM TURNO"
		 _cDescTurno := "NAO HA TURNO CADASTRADO PARA O PERIODO INFORMADO."
		 _cRet       := _cCodTurno

         Break
      EndIf
    
      SPF->(DBGoTo(TRBSPF->NRRECNO))
	  SR6->(DBSetOrder(1)) // R6_FILIAL+R6_TURNO 

	  _cCodTurno  := SPF->PF_TURNOPA
	  _cDescTurno := "SEM DESCRICAO PARA O TURNO"

	  If SR6->(DBSeek(SPF->PF_FILIAL+SPF->PF_TURNOPA))
	     _cDescTurno := SR6->R6_DESC
	  EndIf
      _cRet := _cCodTurno
   Else
      _cRet := _cDescTurno
   EndIf

End Sequence

Return _cRet
