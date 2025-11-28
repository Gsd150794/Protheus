/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |08/03/2022| Chamado 39413. Inclusao da coluna "APRENDIZ?".
Julio Paz     |18/03/2024| Chamado 46563. Inclusão colunas: Categ SEFIP/Deficiente/Tipo Defic/Categ Def ESocial/Obs Defic.
Igor Melgaço  |29/05/2025| Chamado 50776. Ajuste na query para filtro de Filiais
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "topconn.ch"

/*
===============================================================================================================================
Programa----------: RGPE007
Autor-------------: Erich Buttner
Data da Criacao---: 19/07/2013
Descrição---------: Relatório do Quadro de Funcionários 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGPE007()

Local _oReport	:= Nil

Private _cCodTurno := "", _cDescTurno := "", _dDataSPF := Ctod("  /  /  ")

_oReport := RGPE007PRC()
_oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: RGPE007PRC
Autor-------------: Erich Buttner
Data da Criacao---: 19/07/2013
Descrição---------: Processa a impressão do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGPE007PRC()

Local _oReport	:= Nil
Local _oSec001	:= Nil
Local _oSec002	:= Nil
Local _oSec003	:= Nil
Local _cAliaSRA	:= "SRA"
Local _cAliaQRY	:= GetNextAlias()
Local _cPerg	:= "RGPE007"
Private _cTitulo:="Relatório de Quadro de Funcionários"

Pergunte(  _cPerg ,,_cTitulo )

_oReport := TReport():New( "RGPE007" , _cTitulo , "RGPE007" , {|_oReport| RGPE007PRT( _oReport , _cAliaSRA , _cAliaQRY ) } , _cTitulo , .T. )
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

TRCell():New( _oSec003 , "FILIAL"	,, "Fil"			,						, 02 ,, )//{|| FILIAL	} )
TRCell():New( _oSec003 , "MATR"	    ,, "Matricula"      , "999999"	            , 10 ,, )//{|| MATR	} )
TRCell():New( _oSec003 , "NOME"		,, "Nome"			,                       , 30 ,, {|| If(!Empty((_cAliaQRY)->NSOCIAL),(_cAliaQRY)->NSOCIAL,(_cAliaQRY)->NOME)	} )
TRCell():New( _oSec003 , "SEXO"		,, "SEXO"			,						, 30 ,, )//{|| SEXO	} )
TRCell():New( _oSec003 , "DTNASC"	,, "Dt. Nasc."		,						, 10 ,, )//{|| DTNASC	} )
TRCell():New( _oSec003 , "RG"		,, "RG"				,						, 12 ,, )//{|| RG		} )
TRCell():New( _oSec003 , "CPF"		,, "CPF"			, "@R 999.999.999-99"	, 19 ,, )//{|| CPF		} )
TRCell():New( _oSec003 , "PIS"		,, "PIS"			, "@R 99999999999"		, 19 ,, )//{|| PIS		} ) "@R 999.99999.99-9"
TRCell():New( _oSec003 , "BCOAGE"	,, "Bco/Ag"			, "@R !!!/!!!!!!"		, 10 ,, )//{||       	} )
TRCell():New( _oSec003 , "CONTA"   	,, "Conta"     		,						, 12 ,, )//{||       	} )
TRCell():New( _oSec003 , "NCTPS"	,, "N. CTPS/Serie"	,						, 25 ,, )//{|| NCTPS	} )
TRCell():New( _oSec003 , "DTADMI"	,, "Dt. Adm."		,						, 10 ,, )//{|| DTADMI	} )
TRCell():New( _oSec003 , "CENTROC"	,, " C.Custo"		,						, 10 ,, )//{|| CENTROC	} )
TRCell():New( _oSec003 , "DCENTROC"	,, "Desc CC"        ,						, 10 ,, )//{|| DCENTROC} )
TRCell():New( _oSec003 , "SETOR"	,, "Setor"			,						, 06 ,, )//{|| SETOR   } )
TRCell():New( _oSec003 , "DSETOR"	,, "Desc Setor"		,						, 24 ,, )//{|| DSETOR  } )
TRCell():New( _oSec003 , "CFUNCAO"	,, "Função"			,						, 06 ,, )//{|| CFUNCAO	} )
TRCell():New( _oSec003 , "FUNCAO"	,, "Desc Função"	,						, 19 ,, )//{|| FUNCAO	} )
TRCell():New( _oSec003 , "NCBO"		,, "N. CBO"			,						, 15 ,, )//{|| NCBO	} )
TRCell():New( _oSec003 , "APREN"	,, "Aprendiz?"		,						, 15 ,, {|| If((_cAliaQRY)->APREN='1',"Sim","Nao")} )
If MV_PAR14 == 1
   TRCell():New( _oSec003 , "SALARIO"	,,"Salario"			, "@E 9,999,999.99"		, 12 ,, )//{|| SALARIO	} )
EndIf
TRCell():New( _oSec003 , "CTURNO"	,, "Turno"			,						, 10 ,, {|| U_RGPE007T("CTURNO", (_cAliaQRY)->FILIAL , (_cAliaQRY)->MATR)} ) //{|| CTURNO	} )
TRCell():New( _oSec003 , "TURNO"	,, "Desc Turno"  	,						, 50 ,, {|| U_RGPE007T("TURNO" , (_cAliaQRY)->FILIAL , (_cAliaQRY)->MATR)} )  //{|| TURNO	} )
TRCell():New( _oSec003 , "EST"		,, "UF"			    ,						, 02 ,, )//{|| EST		} )
TRCell():New( _oSec003 , "MUN"		,, "Municipio"		,						, 20 ,, )//{|| MUN		} )
TRCell():New( _oSec003 , "SITFUNC"	,, "Sit.Func"       ,						, 10 ,, )//{|| SITFUNC	} )
TRCell():New( _oSec003 , "DTAFAST"	,, "Dt.Afast"       ,						, 10 ,, )//{|| DTAFAST	} )
TRCell():New( _oSec003 , "DTDEMI"	,, "Dt. Demis."		,						, 10 ,, )//{|| DTDEMI	} )

TRCell():New( _oSec003 , "CATEGO"	,, "Categ SEFIP"	  ,						, 10 ,, )//{|| CAMPO	} )
TRCell():New( _oSec003 , "DEFIFIS"	,, "Deficiente"		  ,						, 10 ,,{|| If((_cAliaQRY)->DEFIFIS == "1" ,"SIM","NÃO")}) //{|| CAMPO	} )
TRCell():New( _oSec003 , "TPDDEFIS"	,, "Tipo Deficiência" ,						, 15 ,,{|| U_RGPE007E((_cAliaQRY)->TPDDEFIS)})
TRCell():New( _oSec003 , "PORTDEV"	,, "Categ Def eSocial",						, 30 ,,{|| U_RGPE007F((_cAliaQRY)->PORTDEV)})  
TRCell():New( _oSec003 , "OBSDEFI"	,, "Obs. Deficiência" ,						, 10 ,,) //{|| CAMPO	} )

TRFunction():New( _oSec003:Cell("FILIAL") ,, "COUNT" ,, "TOTAL GERAL DE FUNCIONARIOS " ,,, .T. , .T.,.F.)
TRFunction():New( _oSec003:Cell("MATR") ,, "COUNT" ,, "TOTAL GERAL COM DEMISSAO " ,,, .T. , .T. ,.F.,, {|| (_cAliaQRY)->DTDEMI # "  /  /  " } )

_oSec003:SetTotalText( "TOTAL FUNC. / TOTAL COM DEMISSAO" )


Return( _oReport )

/*
===============================================================================================================================
Programa----------: RGPE007PRT
Autor-------------: Erich Buttner
Data da Criacao---: 19/07/2013
Descrição---------: Consulta e Impressão dos dados do relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGPE007PRT( _oReport , _cAliaSRA , _cAliaQRY )

Local _oSec003	:= _oReport:Section(1):Section(2)
Local _cFiltro	:= ''
Local _cFilIn	:= ''
Local _cQuery	:= "% "
Local _oXml		:= Nil
Local _nI		:= 0
Local _cAfastamento, _dAfastamento   
Local _cFerias, _dFerias

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

If !Empty( MV_PAR15)
	_cQuery += " AND SRA.RA_CODFUNC IN "+ FormatIn( AllTrim( MV_PAR15) , ';' )
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
			SRA.RA_FILIAL FILIAL,
			SRA.RA_I_SETOR SETOR, 
			ZAK.ZAK_DESCRI DSETOR,
			SRA.RA_MAT MATR,
			SRA.RA_NOMECMP NOME,
			SRA.RA_NSOCIAL NSOCIAL,
			SRA.RA_SEXO SEXO,
			SRA.RA_RG RG,
			SRA.RA_CIC CPF, 
			SRA.RA_PIS PIS, 
			SRA.RA_BCDEPSA BCOAGE,
			SRA.RA_CTDEPSA CONTA,
			SRA.RA_CODFUNC CFUNCAO,
			RJ.RJ_DESC FUNCAO,
			SubStr(SRA.RA_ADMISSA,7,2) || '/' || SubStr(SRA.RA_ADMISSA,5,2) || '/' || SubStr(SRA.RA_ADMISSA,1,4) DTADMI, 
			SubStr(SRA.RA_DEMISSA,7,2) || '/' || SubStr(SRA.RA_DEMISSA,5,2) || '/' || SubStr(SRA.RA_DEMISSA,1,4) DTDEMI,
			SRA.RA_SALARIO SALARIO,
			SRA.RA_SITFOLH SITFOL,
			SRA.RA_CATFUNC,
			SubStr(SRA.RA_NASC,7,2) || '/' || SubStr(SRA.RA_NASC,5,2) || '/' || SubStr(SRA.RA_NASC,1,4) DTNASC,
			RJ_CODCBO NCBO,
			RJ_I_MENOR APREN,
			SRA.RA_NUMCP || '-' || SRA.RA_SERCP  || '/' || SRA.RA_UFCP NCTPS,
			SRA.RA_ESTADO EST,
			SRA.RA_MUNICIP MUN,
			SRA.RA_CC CENTROC, 
			CTT.CTT_DESC01 DCENTROC,
			SRA.RA_CATEG CATEGO,  
            SRA.RA_DEFIFIS DEFIFIS,
            SRA.RA_TPDEFFI TPDDEFIS,
            SRA.RA_PORTDEF PORTDEV,
            SRA.RA_OBSDEFI OBSDEFI    
        FROM %Table:SRA% SRA
		    JOIN %Table:SRJ% RJ ON SRA.RA_CODFUNC = RJ.RJ_FUNCAO AND RJ.RJ_FILIAL = SRA.RA_FILIAL
			 JOIN %Table:ZAK% ZAK ON ZAK.ZAK_COD = SRA.RA_I_SETOR AND ZAK.ZAK_FILIAL = %xFilial:ZAK%
			 JOIN %Table:CTT% CTT ON CTT.CTT_CUSTO  = SRA.RA_CC AND CTT.CTT_FILIAL = %xFilial:CTT%
        WHERE SRA.%notdel%
	 	      AND RJ.%notdel%
	 	      AND ZAK.%notdel%
	 	      AND CTT.%notdel%   
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

    _oReport:Section(1):Section(2):Cell("DTAFAST"):SetValue("  /  /     ")    
    
    _oReport:Section(1):Section(2):Cell("MATR"):SetSize(7) 
    _oReport:Section(1):Section(2):Cell("MATR"):SetValue((_cAliaQRY)->MATR)
    
    If (_cAliaQRY)->SITFOL == "A"
       _oReport:Section(1):Section(2):Cell("SITFUNC"):SetValue("AFASTADO")
       
       _dAfastamento := U_RGPE007D((_cAliaQRY)->FILIAL,(_cAliaQRY)->MATR)
       
       If !Empty(_dAfastamento) .And. ValType(_dAfastamento) == "D"
          _cAfastamento  := DToC(_dAfastamento) 
       Else
          _cAfastamento  := "  /  /    "      
       EndIf
       
       _oReport:Section(1):Section(2):Cell("DTAFAST"):SetValue(_cAfastamento)    
    ElseIf (_cAliaQRY)->SITFOL == "F"
       _oReport:Section(1):Section(2):Cell("SITFUNC"):SetValue("FERIAS")
       
       _dFerias := U_RGPE007D((_cAliaQRY)->FILIAL,(_cAliaQRY)->MATR)
       
       If !Empty(_dFerias) .And. ValType(_dFerias) == "D"
          _cFerias  := DToC(_dFerias) 
       Else
          _cFerias  := "  /  /    "      
       EndIf
       
       _oReport:Section(1):Section(2):Cell("DTAFAST"):SetValue(_cFerias)    

    ElseIf (_cAliaQRY)->SITFOL == "D"
       _oReport:Section(1):Section(2):Cell("SITFUNC"):SetValue("DEMITIDO")
    Else
       _oReport:Section(1):Section(2):Cell("SITFUNC"):SetValue("ATIVO")
    EndIf

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
Função------------: RGPE007D
Autor-------------: Julio de Paula Paz
Data da Criacao---: 05/02/2017
Descrição---------: Retornar a ultima data de afastamento do funcionário.
Parametros--------: _cFilial    = Filial do funcionário
                    _cMatricula = Código de matricula
Retorno-----------: _DataAfast  = Data de afastamento do funcionário.
===============================================================================================================================
*/
User Function RGPE007D(_cFilial, _cMatricula)
Local _dRet := Ctod("  /  /  ")
Local _cQry, _cAlias
Local _aSaveArea := FWGetArea()

Begin Sequence
   _cQry := " SELECT R8_DATAINI FROM "+RetSqlName("SR8")+ " SR8 "
   _cQry += " WHERE SR8.R8_FILIAL = '" + _cFilial + "' AND SR8.D_E_L_E_T_ = ' ' "
   _cQry += " AND SR8.R8_MAT = '" + _cMatricula + "' "
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

/*
===============================================================================================================================
Função------------: RGPE007T
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/09/2019
Descrição---------: Retornar o código e a descrição do turno.
Parametros--------: _cCampo = Campo que chamou a função.
                    _cCodFilial = Codigo da Filial
					_cMatricula = Codigo da Matricula
Retorno-----------: _cRet = Retorna o código ou a descrição do turno.
===============================================================================================================================
*/
User Function RGPE007T(_cCampo, _cCodFilial, _cMatricula)
Local _cRet := ""
Local _cQry 

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

/*
===============================================================================================================================
Função------------: RGPE007E
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/09/2019
Descrição---------: Retornar o código e a descrição do tipo de deficiência.
Parametros--------: _cCodDefic = Codigo da Deficiência
Retorno-----------: _cRet = Retorna o código ou a descrição da deficiência
===============================================================================================================================
*/
User Function RGPE007E(_cCodDef)
_cRet := ""

Begin Sequence
   
   If AllTrim(_cCodDef) == "0"
      _cRet := "0=NÃO É PORTADOR DE DEFICIÊNCIA"
   ElseIf AllTrim(_cCodDef) == "1"
      _cRet := "1=FÍSICA" 
   ElseIf AllTrim(_cCodDef) == "2"
      _cRet := "2=AUDITIVA"
   ElseIf AllTrim(_cCodDef) == "3"
      _cRet := "3=VISUAL"
   ElseIf AllTrim(_cCodDef) == "4"
      _cRet := "4=INTELECTUAL (MENTAL)"
   ElseIf AllTrim(_cCodDef) == "5"
      _cRet := "5=MULTIPLA"
   ElseIf AllTrim(_cCodDef) == "6"
      _cRet := "6=REABILITADO"
   EndIf 

End Sequence

Return _cRet 

/*
===============================================================================================================================
Função------------: RGPE007F
Autor-------------: Julio de Paula Paz
Data da Criacao---: 04/09/2019
Descrição---------: Retornar as descrições das deficiências atribuidas ao funcionário.
Parametros--------: _cDefFunc = Deficiências do Funcionário.
Retorno-----------: _cRet = Retorna as descrições das deficiências do Funcionário.
===============================================================================================================================
*/
User Function RGPE007F(_cDefFunc)
Local _cRet := ""

Begin Sequence 
   
   If "1" $ _cDefFunc 
      _cRet += "PORTADOR DE DEFICIÊNCIA FÍSICA "
   EndIf 

   If "2" $ _cDefFunc 
      If ! Empty(_cRet)
         _cRet += "; "
	  EndIf 
	  
      _cRet += "PORTADOR DE DEFICIÊNCIA AUDITIVA "
   EndIf 

   If "3" $ _cDefFunc 
      If ! Empty(_cRet)
         _cRet += "; "
	  EndIf 

      _cRet += "PORTADOR DE DEFICIÊNCIA VISUAL "
   EndIf 

   If "4" $ _cDefFunc 
      If ! Empty(_cRet)
         _cRet += "; "
	  EndIf 

      _cRet += "PORTADOR DE DEFICIÊNCIA MENTAL "
   EndIf 

   If "5" $ _cDefFunc 
      If ! Empty(_cRet)
         _cRet += "; "
	  EndIf 

      _cRet += "PORTADOR DE DEFICIÊNCIA INTELECTUAL "
   EndIf 

   If "6" $ _cDefFunc 
      If ! Empty(_cRet)
         _cRet += "; "
	  EndIf 
	  
      _cRet += "O TRABALHADOR É REABILITADO E APTO A RETORNAR AO TRABALHO "
   EndIf 

End Sequence 

Return _cRet 

