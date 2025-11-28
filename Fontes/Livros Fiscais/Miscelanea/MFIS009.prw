/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "FWMBROWSE.CH"
#Include "FWMVCDEF.CH"
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MFIS009
Autor-------------: Igor Melgaço
Data da Criacao---: 23/12/2022
Descrição---------: Acertos Fiscais Italac. Chamado: 43865 
Parametros--------: 
Retorno-----------:  
===============================================================================================================================
*/ 
User Function MFIS009()

Local nA 
Local _aParRet   := {}
Local _aParAux   := {}
Local _bOK       := {|| .T. }
Local _cFiltro   := ""
Local _cTabela := ""
Local _cTimeIni  := Time()
Local _cTitAux   := "Acertos Fiscais Italac"

_aStatus:={"1-Entrada     ",;
	       "2-Saida"}

MV_PAR01 := _aStatus[1]
MV_PAR02 := CTOD("")
MV_PAR03 := CTOD("")
MV_PAR04 := Space(Len(SF1->F1_DOC))
MV_PAR05 := Space(Len(SF1->F1_SERIE))
MV_PAR06 := Space(Len(SF1->F1_DOC))
MV_PAR07 := Space(Len(SF1->F1_SERIE))
MV_PAR08 := Space(Len(SF1->F1_FORNECE))
MV_PAR09 := Space(Len(SF1->F1_LOJA))
MV_PAR10 := Space(Len(SF1->F1_FORNECE))
MV_PAR11 := Space(Len(SF1->F1_LOJA))
MV_PAR12 := Space(Len(SF1->F1_FORNECE))
MV_PAR13 := Space(Len(SF1->F1_LOJA))
MV_PAR14 := Space(Len(SF1->F1_FORNECE))
MV_PAR15 := Space(Len(SF1->F1_LOJA))

aAdd( _aParAux , { 2 , "Movimento"     , MV_PAR01, _aStatus, 060   ,".T.",.T. ,".T."}) 
aAdd( _aParAux , { 1 , "Data Inicial"  , MV_PAR02, "@D", "", ""	, "" , 050 , .F.  })
aAdd( _aParAux , { 1 , "Data Final"	   , MV_PAR03, "@D", "", ""	, "" , 050 , .F.  })
aAdd( _aParAux , { 1 , "De Nota"       , MV_PAR04, "@!"  , ""    , ""        , "" , 060 , .F. } )
aAdd( _aParAux , { 1 , "De Serie"      , MV_PAR05, "@!"  , ""    , ""        , "" , 060 , .F. } )
aAdd( _aParAux , { 1 , "Ate Nota"      , MV_PAR06, "@!"  , ""    , ""        , "" , 060 , .F. } )
aAdd( _aParAux , { 1 , "Ate Serie"     , MV_PAR07, "@!"  , ""    , ""        , "" , 060 , .F. } )
aAdd( _aParAux , { 1 , "Fornecedor de" , MV_PAR08, ""	   , ""	, "SA2"		, "" , 50         , .F. } )
aAdd( _aParAux , { 1 , "Loja de"	   , MV_PAR09, ""	   , ""	, ""		   , "" , 25         , .F. } )
aAdd( _aParAux , { 1 , "Fornecedor até", MV_PAR10, ""	   , ""	, "SA2"		, "" , 50         , .F. } )
aAdd( _aParAux , { 1 , "Loja até"	   , MV_PAR11, ""	   , ""	, ""		   , "" , 25         , .F. } )
aAdd( _aParAux , { 1 , "Cliente de"	   , MV_PAR12, ""	   , ""	, "SA1"		, "" , 50         , .F. } )
aAdd( _aParAux , { 1 , "Loja de"	   , MV_PAR13, ""	   , ""	, ""		   , "" , 25         , .F. } )
aAdd( _aParAux , { 1 , "Cliente até"   , MV_PAR14, ""	   , ""	, "SA1"		, "" , 50         , .F. } )
aAdd( _aParAux , { 1 , "Loja até"	   , MV_PAR15, ""	   , ""	, ""		   , "" , 25         , .F. } )

For nA := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nA][03] )
Next

While .T.
                            //aParametros, cTitle                                , @aRet    ,[bOk], [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
    If !ParamBox( _aParAux , _cTitAux, @_aParRet, _bOK, /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
        Return .F.
    EndIf
    
    _cTabela := IIf(Subs(MV_PAR01,1,1) == "1","SF1","SF2")

    _cFiltro := _cTabela+"->"+Subs(_cTabela,2,2)+"_FILIAL == '"+cFilAnt+"' .AND." 

    If Subs(MV_PAR01,1,1) == "1" 
        If !Empty(MV_PAR02)
            _cFiltro += " DToS(SF1->F1_DTDIGIT) >= '" + DToS(MV_PAR02)+"' "
        EndIf
        If !Empty(MV_PAR03)
            _cFiltro += " .And. DToS(SF1->F1_DTDIGIT) <= '" + DToS(MV_PAR03)+"' "
        EndIf
    Else
        If !Empty(MV_PAR02)
            _cFiltro += " DToS(SF2->F2_EMISSAO) >= '" + DToS(MV_PAR02)+"' "
        EndIf
        If !Empty(MV_PAR03)
            _cFiltro += " .And. DToS(SF2->F2_EMISSAO) <= '" + DToS(MV_PAR03)+"' "
        EndIf
    EndIf
    
    If !Empty(MV_PAR04) 
        _cFiltro += IIf(Empty(_cFiltro),""," .And. ")+_cTabela+"->"+Subs(_cTabela,2,2)+"_DOC >= '" + MV_PAR04+"' "
    EndIf
    If !Empty(MV_PAR06)
        _cFiltro += IIf(Empty(_cFiltro),""," .And. ")+_cTabela+"->"+Subs(_cTabela,2,2)+"_DOC <= '" + MV_PAR06+"' "
    EndIf

    If !Empty(MV_PAR05)
        _cFiltro += IIf(Empty(_cFiltro),""," .And. ") + _cTabela + "->" + Subs(_cTabela,2,2) + "_SERIE >= '" + MV_PAR05+"' "
    EndIf
    If !Empty(MV_PAR07)
        _cFiltro += IIf(Empty(_cFiltro),""," .And. ") + _cTabela + "->" + Subs(_cTabela,2,2) + "_SERIE <= '" + MV_PAR07+"' "
    EndIf

    If Subs(MV_PAR01,1,1) = "1"
        If !Empty(MV_PAR08) 
            _cFiltro += IIf(Empty(_cFiltro),"",".AND.") + " SF1->F1_FORNECE >= '" + MV_PAR08+"' "
        EndIf
        If !Empty(MV_PAR10)
            _cFiltro += IIf(Empty(_cFiltro),"",".AND.") + " SF1->F1_FORNECE <= '" + MV_PAR10+"' "
        EndIf

        If !Empty(MV_PAR09)
            _cFiltro += IIf(Empty(_cFiltro),"",".AND.") + " SF1->F1_LOJA >= '" + MV_PAR09+"' "
        EndIf
        If !Empty(MV_PAR11)
            _cFiltro += IIf(Empty(_cFiltro),"",".AND.") + " SF1->F1_LOJA <= '" + MV_PAR11+"' "
        EndIf
    Else
        If !Empty(MV_PAR12) 
            _cFiltro += IIf(Empty(_cFiltro),"",".AND.") + " SF2->F2_CLIENTE >= '" + MV_PAR12+"' "
        EndIf
        If !Empty(MV_PAR14)
            _cFiltro += IIf(Empty(_cFiltro),"",".AND.") + " SF2->F2_CLIENTE <= '" + MV_PAR14+"' "
        EndIf
        If !Empty(MV_PAR13) 
            _cFiltro += IIf(Empty(_cFiltro),"",".AND.") + " SF2->F2_LOJA >= '" + MV_PAR13+"' "
        EndIf
        If !Empty(MV_PAR15)
            _cFiltro += IIf(Empty(_cFiltro),"",".AND.") + " SF2->F2_LOJA <= '" + MV_PAR15+"' "
        EndIf
    EndIf

    If Subs(MV_PAR01,1,1) = "1"
        FWMsgRun( ,{|| U_MFIS010(_cFiltro) } , "Aguarde!" , "Hor Inicial: "+_cTimeIni+" / Carregando dados..." )
    Else
        FWMsgRun( ,{|| U_MFIS011(_cFiltro) } , "Aguarde!" , "Hor Inicial: "+_cTimeIni+" / Carregando dados..." )
    EndIf    
EndDo

Return


/*
===============================================================================================================================
Programa----------: MFIS009ALT
Autor-------------: Igor Melgaço
Data da Criacao---: 23/05/2023
Descrição---------: Validação para alteração de campos
Parametros--------: _oModel
Retorno-----------: lRet
===============================================================================================================================
*/
User Function MFIS009ALT(cTIPO)

Local lRet := .F. 

DBSelectArea("ZZL")
DBSetOrder(3) //ZZL_FILIAL + ZZL_CODUSU
If DBSeek(xFilial("ZZL") + __cUserId)
    If cTIPO = "FED" // FED Federal
        If ZZL->ZZL_AIMPF == "S"
            lRet := .T.
        Else
            lRet := .F.
        EndIf
    Else // EST Estadual
        If ZZL->ZZL_AIMPE == "S"
            lRet := .T.
        Else
            lRet := .F.
        EndIf
    EndIf
EndIf

Return lRet

/*
===============================================================================================================================
Programa----------: MFIS010MON
Autor-------------: Igor Melgaço
Data da Criacao---: 19/05/2023
Descrição---------: Consulta Histórico de Alterações 
Parametros--------: _cChave
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIS010T(_aCabec,_cTabela,_cChave,_cCpoChave,_cTitulo)

Local oDlg			:= Nil
Local oLbxTOP		:= Nil
Local oLbxDET		:= Nil
Local aPosObj   	:= {}
Local aObjects  	:= {}
Local aSize     	:= MsAdvSize()
Local bMontaTOP		:= { || Processa({|lEnd| MFIS009CAR( @oLbxTOP ,_cTabela ,  _cChave, _cCpoChave ) }) }
Local bMontaDET		:= { || MFIS009DET( @oLbxDET ,_cTabela, oLbxTOP:aArray[oLbxTOP:nAt][04] ,_cCpoChave, oLbxTOP:aArray[oLbxTOP:nAt][01] ) }
Local oBar			:= Nil
Local aBtn 	    	:= Array(02)
Local oBold			:= Nil
Local oScrPanel		:= Nil
Local aCabLbxTOP	:= {  "Campo" , "Descrição" , "Última Alt.","Recno" } // 04
Local aCabLbxDET	:= { "Data"				,; // 01
                         "Hora"				,; // 02
                         "Usuário"			,; // 03
                         "Nome Usr."		,; // 04
                         "Cont. Orig."		,; // 05
                         "Cont. Alt."		 } // 06

Private	nDvPosAnt	:= 0
Private	cCadastro	:= "["+ _cChave +"] - " + _cTitulo

//================================================================================
//| Verifica se existe histórico de alterações                                   |
//================================================================================
DBSelectArea("Z07")
Z07->( DBSetOrder(1) )
If !Z07->( DBSeek( xFilial("Z07") + _cTabela + " 1" + _cChave ) )
	//MessageBox( "A chave ["+ _cChave +"] não possui histórico de alterações." , _cTitulo , 0 )
	U_ITMsg("A chave ["+ _cChave +"] não possui histórico de alterações.","Atenção",,3)
	
    Return
EndIf

aAdd( aObjects, { 100 , 025 , .T. , .F. , .T. } )
aAdd( aObjects, { 100 , 070 , .T. , .F. } )
aAdd( aObjects, { 100 , 100 , .T. , .T. } )

aInfo   := { aSize[1] , aSize[2] , aSize[3] , aSize[4] , 3 , 2 }
aPosObj := MsObjSize( aInfo , aObjects )

DEFINE FONT oBold NAME "Arial" SIZE 0, -12 BOLD

DEFINE MSDIALOG oDlg TITLE cCadastro From aSize[7],00 to aSize[6],aSize[5] Of oMainWnd Pixel

	aPosObj[01][01] += 12
	aPosObj[02][01] += 10
	aPosObj[02][03] += 10
	aPosObj[03][01] += 10
	aPosObj[03][03] += 10
	
	//================================================================================
	//| Imprime o código e o nome do vendedor                                        |
	//================================================================================
	@ aPosObj[01][01],aPosObj[01][02] MSPANEL oScrPanel PROMPT "" SIZE aPosObj[01][03],aPosObj[01][04] OF oDlg LOWERED
	
	@ 004 , 004 Say _aCabec[1,1] 	SIZE 060,07 OF oScrPanel PIXEL
	@ 012 , 004 Say _aCabec[1,2]   	SIZE 060,09 OF oScrPanel PIXEL FONT oBold

	@ 004 , 070 Say _aCabec[2,1]  	SIZE 165,07 OF oScrPanel PIXEL
	@ 012 , 070 Say _aCabec[2,2]   	SIZE 165,09 OF oScrPanel PIXEL FONT oBold
	
	//================================================================================
	//| Monta o resumo das alterações do cadastro                                    |
	//================================================================================
	@aPosObj[02][01],aPosObj[02][02] To aPosObj[02][03],aPosObj[02][04] LABEL "Campos Alterados" OF oDlg PIXEL
	
	@aPosObj[02][01]+7,aPosObj[02][02]+4 	Listbox oLbxTOP Fields	;
											HEADER 	""		 		;
											On DbLCLICK ( Nil )		;
											Size aPosObj[02][04]-10,( aPosObj[02][03] - aPosObj[02][01] ) - 10 Of oDlg Pixel
	
	oLbxTOP:AHeaders	:= aClone(aCabLbxTOP)
	oLbxTOP:bChange		:= { || Eval(bMontaDET) }
	
	Eval(bMontaTOP)
	
	//================================================================================
	//| Monta os detalhes das alterações do cadastro                                 |
	//================================================================================
	@aPosObj[03][01],aPosObj[03][02] To aPosObj[03][03],aPosObj[03][04] LABEL "Histórico dos Campos" COLOR CLR_HBLUE OF oDlg PIXEL
	
	@aPosObj[03][01]+7,aPosObj[03][02]+4 	Listbox oLbxDET Fields;
											HEADER 	""		 		;
											On DbLCLICK ( Nil )		;
											Size aPosObj[03][04]-10,( aPosObj[03][03] - aPosObj[03][01] ) - 10 Of oDlg Pixel
					
	oLbxDET:AHeaders := aClone(aCabLbxDET)
	
	Eval(bMontaDET)
	
	//================================================================================
	//| Monta a barra de botões da tela                                              |
	//================================================================================
	DEFINE BUTTONBAR oBar SIZE 25,25 3D OF oDlg
	
	DEFINE BUTTON aBtn[01] RESOURCE PmsBExcel()[1] OF oBar GROUP ACTION DlgToExcel({{"ARRAY","",oLbxPM7:AHeaders,oLbxPM7:aArray}})	TOOLTIP "Exportar para Planilha..."
	aBtn[01]:cTitle := ""
	
	DEFINE BUTTON aBtn[02] RESOURCE "FINAL" 		OF oBar GROUP ACTION oDlg:End() 													TOOLTIP "Sair da Tela..."
	aBtn[02]:cTitle := ""
	
	oDlg:lMaximized := .T.
	
ACTIVATE MSDIALOG oDlg CENTERED

Return

/*
===============================================================================================================================
Programa----------: MFIS009CAR
Autor-------------: Igor Melgaço
Data da Criacao---: 19/05/2023
Descrição---------: Carregamento do Histórico de Alterações
Parametros--------: oLbxAux, _cChave
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIS009CAR( oLbxAux , _cTabela, _cChave, _cCpoChave )

Local _cQuery	:= ""
Local _cAlias	:= GetNextAlias()
Local _aLbxAux	:= {}
Local _nTotReg	:= 0
Local _nCont	:= 0

//================================================================================
//| Consulta para buscar o resumo das alterações do cadastro                     |
//================================================================================
_cQuery := " SELECT "
_cQuery += " 	Z07.Z07_CAMPO 		AS CAMPO,	"
_cQuery += " 	MAX( Z07.Z07_DATA )	AS DT_ULT,	"
_cQuery += "    "+_cTabela+".R_E_C_N_O_	AS REG"
_cQuery += " FROM "+ RetSqlName(_cTabela) +" "+_cTabela+"	"
_cQuery += "    INNER JOIN "+ RetSqlName("Z07") +" Z07 "
_cQuery += "        ON "+_cCpoChave+" = Z07.Z07_CHAVE "
_cQuery += " WHERE "
_cQuery += "     	Z07.D_E_L_E_T_  = ' ' "
_cQuery += "    AND	Z07.Z07_ALIAS	= '"+_cTabela+"' "
_cQuery += "    AND	("+_cCpoChave+") = '"+ _cChave +"' "
_cQuery += " GROUP BY Z07.Z07_CAMPO, "+_cTabela+".R_E_C_N_O_ "
_cQuery += " ORDER BY Z07.Z07_CAMPO "

_cQuery	:= ChangeQuery(_cQuery)
DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAlias , .F. , .T. )

TCSetField( _cAlias , "Z07.Z07_DATA" , "D" , 8 , 0 )

DBSelectArea(_cAlias)
(_cAlias)->(DBGoTop())

(_cAlias)->( DBEval( { || _nTotReg++ } ) )

ProcRegua(_nTotReg)

(_cAlias)->( DBGoTop() )

//================================================================================
//| Grava os dados do Resumo                                                     |
//================================================================================
While (_cAlias)->(!Eof())

	aAdd( _aLbxAux , {	(_cAlias)->CAMPO							   		,; // 01
						Posicione("SX3",2,(_cAlias)->CAMPO,"X3_DESCRIC")	,; // 02
                       	(_cAlias)->DT_ULT									,; // 03
                       	(_cAlias)->REG					    				}) // 04


_nCont++
IncProc("Montando estrutura "+StrZero(_nCont,6)+" de "+StrZero(_nTotReg,6)  )
(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

//================================================================================
//| Monta o objeto do ListBox                                                    |
//================================================================================
If	Len(_aLbxAux) > 0 .And. ValType(oLbxAux) == "O"
                     
	oLbxAux:SetArray(_aLbxAux)
	oLbxAux:bLine:={||{	_aLbxAux[oLbxAux:nAt][01]	,; // 01
						_aLbxAux[oLbxAux:nAt][02]	,; // 02
						_aLbxAux[oLbxAux:nAt][03]	,; // 03
						_aLbxAux[oLbxAux:nAt][04]	}} // 04
	
	oLbxAux:Refresh()

EndIf

Return

/*
===============================================================================================================================
Programa----------: MFIS009DET
Autor-------------: Igor Melgaço
Data da Criacao---: 19/05/2023
Descrição---------: Monta estrutura de Detalhes do Log de Alterações do Campo
Parametros--------: oLbxAux , nRegSF1 , cCampo 
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIS009DET( oLbxAux , cTabela , nReg , cCpoChave , cCampo )

Local _cQuery	:= ""
Local _cAlias	:= GetNextAlias()
Local _aLbxAux	:= {}
Local _nTotReg	:= 0
Local _nCont	:= 0

//================================================================================
//| Consulta para buscar os detalhes das alterações dos campos                   |
//================================================================================
_cQuery := " SELECT "
_cQuery += " 	Z07.Z07_DATA	AS DT_ALT	, "
_cQuery += " 	Z07.Z07_HORA	AS HORA		, "
_cQuery += " 	Z07.Z07_CODUSU	AS CODUSU	, "
_cQuery += " 	Z07.Z07_CONORG	AS CONT_ORG	, "
_cQuery += " 	Z07.Z07_CONALT	AS CONT_ALT	  "
_cQuery += " FROM "+ RetSqlName(cTabela) +" "+cTabela+"	"
_cQuery += "    INNER JOIN "+ RetSqlName("Z07") +" Z07 "
_cQuery += "        ON "+cCpoChave+" = Z07.Z07_CHAVE "
_cQuery += " WHERE "
_cQuery += "    Z07.D_E_L_E_T_  = ' ' "
_cQuery += "    AND	Z07.Z07_ALIAS	= '"+cTabela+"' "
_cQuery += "    AND	Z07.Z07_CAMPO	= '"+ cCampo +"' "
_cQuery += "    AND	"+cTabela+".R_E_C_N_O_	= '"+ CValToChar(nReg) +"' "
//_cQuery += " 	SF1.D_E_L_E_T_  = ' ' "
_cQuery += " ORDER BY Z07.Z07_DATA , Z07.Z07_HORA , Z07.Z07_CODUSU , Z07.Z07_CONORG "

_cQuery	:= ChangeQuery(_cQuery)

DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAlias , .F. , .T. )

TCSetField( _cAlias , "Z07.Z07_DATA" , "D" , 8 , 0 )

DBSelectArea(_cAlias)
(_cAlias)->(DBGoTop()) 

(_cAlias)->( DBEval( { || _nTotReg++ } ) )

ProcRegua(_nTotReg) // Regua

(_cAlias)->(DBGoTop())                                                                                   

//================================================================================
//| Grava o resultado dos detalhes das alterações dos campos                     |
//================================================================================
While (_cAlias)->(!Eof())

            aAdd( _aLbxAux , {			(_cAlias)->DT_ALT		,; // 01
                                        (_cAlias)->HORA			,; // 02
                                        (_cAlias)->CODUSU		,; // 03
    AllTrim( Capital( UsrFullName(	(_cAlias)->CODUSU ) ) )	,; // 04
                            AllTrim(	(_cAlias)->CONT_ORG )	,; // 05
                            AllTrim(	(_cAlias)->CONT_ALT )	}) // 06

    _nCont++
    IncProc("Montando estrutura "+StrZero(_nCont,6)+" de "+StrZero(_nTotReg,6)  )
    (_cAlias)->( DBSkip() )
    
EndDo

(_cAlias)->( DBCloseArea() )

//================================================================================
//| Monta o objeto do ListBox com os dados dos detalhes                          |
//================================================================================
If	Len(_aLbxAux) > 0 .And. ValType(oLbxAux) == "O"
                     
	oLbxAux:SetArray(_aLbxAux)
	oLbxAux:bLine:={||{	_aLbxAux[oLbxAux:nAt][01]	,; // 01
						_aLbxAux[oLbxAux:nAt][02]	,; // 02
						_aLbxAux[oLbxAux:nAt][03]	,; // 03
						_aLbxAux[oLbxAux:nAt][04]	,; // 04
						_aLbxAux[oLbxAux:nAt][05]	,; // 05
						_aLbxAux[oLbxAux:nAt][06]	}} // 06

	oLbxAux:Refresh()

EndIf

Return
