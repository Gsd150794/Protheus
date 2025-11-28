/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGPE021
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 23/10/2019
Descrição---------: Relatorio de transferências de setor - Chamado 30942
Retorno-----------: Nenhum  
===============================================================================================================================
*/
User Function MGPE021()

Local _aParAux:={} , nI
Local _aParRet:={}

MV_PAR01:=Space(200)
MV_PAR02:=dDataBase
MV_PAR03:=dDataBase
MV_PAR04:=Space(Len(SRE->RE_CCD))
MV_PAR05:=Space(Len(SRE->RE_CCP))

aAdd( _aParAux , { 1 , "Filial"               , MV_PAR01, "@!"  , ""    ,"LSTFIL"   , "" , 060 , .T. } ) 
aAdd( _aParAux , { 1 , "Data de"	          , MV_PAR02, "@D"	, ""	, ""		, "" , 060 , .T. } )
aAdd( _aParAux , { 1 , "Data ate"             , MV_PAR03, "@D"	, ""	, ""		, "" , 060 , .T. } )
aAdd( _aParAux , { 1 , "Centro de Custo de"   , MV_PAR04, "@!"  , ""    , "CTT"     , "" , 060 , .F. } ) 
aAdd( _aParAux , { 1 , "Centro de Custo ate"  , MV_PAR05, "@!"  , ""    , "CTT"     , "" , 060 , .F. } ) 

For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next 

While .T.

   lSair:=.T.
   
   If !ParamBox( _aParAux , "Seleção de dados do Relatorio de transferências" , @_aParRet )
      Return .T.
   EndIf

   FWMsgRun( ,{|oproc| lSair:=MPGE021INI(oproc) } , "Processando..." , "Iniciando o processamento..." )

   If lSair
      Exit
   EndIf

EndDo

Return .T.

/*
===============================================================================================================================
Programa----------: MPGE021INI
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 29/07/2019
Descrição---------: Rotina de montagem da tela de processamento
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: .T. OU .F.
===============================================================================================================================
*/
Static Function MPGE021INI(oproc)

Local _cQuery	:= ""
Local _aDados	:= {}
Private cAliasAux	:= GetNextAli8as()

//Grava Log de execução da rotina
U_ITLOGACS( "MPGE021" )

oproc:cCaption := ("Lendo dados...")
ProcessMessages()

_cQuery := " SELECT  R_E_C_N_O_ REC_SRE "
_cQuery += " FROM " +RETSQLNAME("SRE") + " SRE WHERE  "
_cQuery += "(   SRE.RE_FILIALD IN "+ FormatIn(AllTrim(MV_PAR01), ";" )
_cQuery += " OR SRE.RE_FILIALP IN "+ FormatIn(AllTrim(MV_PAR01), ";" )+")"
If !Empty(MV_PAR02)
   _cQuery += " AND RE_DATA BETWEEN '" + DToS(MV_PAR02) + "' AND '" + DToS(MV_PAR03) + "'"
ElseIf !Empty(MV_PAR01) 
   _cQuery += " AND RE_DATA >= '" + DToS(MV_PAR02) + "'"
EndIf
If !Empty(MV_PAR05)
   _cQuery += " AND (   RE_CCP  BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR05 + "' "
   _cQuery += "      OR RE_CCD  BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR05 + "')"
ElseIf !Empty(MV_PAR04) 
   _cQuery += " AND (   RE_CCD  >= '" + MV_PAR04 + "'"
   _cQuery += "      OR RE_CCP  >= '" + MV_PAR04 + "')"
EndIf
_cQuery += "  AND D_E_L_E_T_ = ' ' " 

_cQuery += " ORDER BY RE_DATA,RE_CCP,RE_MATP "
	
MPSysOpenQuery( _cQuery , cAliasAux ) 

oProc:cCaption := ("Contando os dados lidos...")
ProcessMessages()
DBSelectArea(cAliasAux)
(cAliasAux)->(DBGoTop())
_cTot := 0
COUNT TO _cTot
_cTot:=AllTrim(Str(_cTot))
_nTam:=Len(_cTot)
(cAliasAux)->(DBGoTop())
_npv:=0

While (cAliasAux)->(!Eof())

    SRE->(DBGoTo((cAliasAux)->REC_SRE))
	_npv++
	oProc:cCaption := ("Processando Dados: "+ StrZero(_npv,_nTam) +" de "+ _cTot)
	ProcessMessages()

    _aItens:={}
	aAdd(_aItens,DToC(SRE->RE_DATA))
	aAdd(_aItens,SRE->RE_FILIALD)
	aAdd(_aItens,SRE->RE_MATD)
	aAdd(_aItens,SRE->RE_CCD+"-"+Posicione("CTT",1,xFilial("CTT")+SRE->RE_CCD,"CTT_DESC01"))
	aAdd(_aItens,Posicione("SRA",1,AllTrim(SRE->RE_FILIALP)+SRE->RE_MATP,"RA_NOME"))
	aAdd(_aItens,SRE->RE_FILIALP)
	aAdd(_aItens,SRE->RE_MATP)
	aAdd(_aItens,SRE->RE_CCP+"-"+Posicione("CTT",1,xFilial("CTT")+SRE->RE_CCP,"CTT_DESC01"))
	cSetor:=Posicione("SRA",1,AllTrim(SRE->RE_FILIALP)+SRE->RE_MATP,"RA_I_SETOR")
	If !Empty(cSetor)
       aAdd(_aItens,cSetor+"-"+Posicione("ZAK",1,xFilial("ZAK")+cSetor,"ZAK_DESCRI"))
    Else   
       aAdd(_aItens," ")
    EndIf   
	aAdd(_aDados,_aItens)

    (cAliasAux)->(DBSkip())
 
EndDo

(cAliasAux)->( DBCloseArea() )


//Monta _aCab
_aCab:={}
_aSizes:={}
aAdd(_aCab,Getsx3cache("RE_DATA"   ,"X3_TITULO"))
aAdd(_aSizes,38)
aAdd(_aCab,Getsx3cache("RE_FILIALD","X3_TITULO"))
aAdd(_aSizes,37)
aAdd(_aCab,Getsx3cache("RE_MATD"   ,"X3_TITULO"))
aAdd(_aSizes,39)
aAdd(_aCab,Getsx3cache("RE_CCD"    ,"X3_TITULO"))
aAdd(_aSizes,140)
aAdd(_aCab,Getsx3cache("RA_NOME"   ,"X3_TITULO"))
aAdd(_aSizes,130)
aAdd(_aCab,Getsx3cache("RE_FILIALP","X3_TITULO"))
aAdd(_aSizes,37)
aAdd(_aCab,Getsx3cache("RE_MATP"   ,"X3_TITULO"))
aAdd(_aSizes,39)
aAdd(_aCab,Getsx3cache("RE_CCP"    ,"X3_TITULO"))
aAdd(_aSizes,140)
aAdd(_aCab,"Setor Atual")
aAdd(_aSizes,200)

If Len(_aDados) > 0
   _cTitulo:="Relatorio de transferências de Setor"
   _cMsgTop:="Relatorio de transferências de Setor"
//    ITListBox(_cTitAux, _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons )
	U_ITLISTBOX(_cTitulo, _aCab    , _aDados   , .T.      , 1      ,_cMsgTop  ,          , _aSizes )
Else
	U_ITMsg("Nenhum registro gerado!","Atenção",,1)
EndIf

Return .F.
