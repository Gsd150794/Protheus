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
Programa----------: RGLT070
Autor-------------: Alex Wallauer
Data da Criacao---: 23/02/2022
Descrição---------: Relatório de Programado X Realizado leite de terceiros . Chamado 39218
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGLT070()//U_RGLT070 

Local _cTitulo := "Relatório Programado X Realizado leite de terceiros" 
Local _aDados	:= {}
Local oproc    := nil
Local nI		   := 0 
Local _aParRet	:= {}
Local _aParAux := {}

_cSelecSC7 :="SELECT DISTINCT C7_NUM   , C7_EMISSAO FROM "+RETSQLNAME("SC7")+" SC7 WHERE D_E_L_E_T_ = ' ' AND C7_FILIAL = '"+xFilial("SC7")+"' ORDER BY C7_NUM " //AND C7_ENCER <> 'E' AND C7_RESIDUO <> 'S' 
_cSelSA2   :="SELECT A2_COD,A2_LOJA,A2_NREDUZ FROM "+RETSQLNAME("SA2")+" SA2 WHERE SubStr(A2_COD,1,1) IN ('P','G','L') AND D_E_L_E_T_ = ' ' ORDER BY A2_COD, A2_LOJA "
_cSelectSB1:="SELECT B1_COD , B1_DESC FROM "+RETSQLNAME("SB1")+" SB1 WHERE D_E_L_E_T_ = ' ' AND B1_TIPO = 'MP' ORDER BY B1_COD "

_aItalac_F3:={}//       1           2         3                      4                      5          6                      7         8          9         10         11        12
//  (_aItalac_F3,{"CPOCAMPO",_cTabela   ,_nCpoChave            , _nCpoDesc               ,_bCondTab   , _cTitAux           , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR03",_cSelecSC7 ,{|Tab| (Tab)->C7_NUM }, {|Tab|DToC(SToD((Tab)->C7_EMISSAO))},,"Pedidos"           ,          ,          ,          ,.F.        ,       , } )
aAdd(_aItalac_F3,{"MV_PAR04",_cSelSA2   ,{|Tab|(Tab)->A2_COD+(Tab)->A2_LOJA},{|Tab| (Tab)->A2_NREDUZ},,"Fornecedores"      ,          ,          ,          ,.F.        ,       , } )
aAdd(_aItalac_F3,{"MV_PAR05",_cSelectSB1,{|Tab|(Tab)->B1_COD},{|Tab|(Tab)->B1_DESC}                  ,,"Produtos Tipo = MP",          ,          ,          ,.F.        ,       , } )

MV_PAR01:=dDataBase
MV_PAR02:=dDataBase
MV_PAR03:=Space(200)
MV_PAR04:=Space(200)
MV_PAR05:=Space(200)
MV_PAR06:=1

_aStatus:={"Todos            ",;
        "Abertos          ",;
        "Parciais         ",;
        "Paciais + Abertos",;
        "Encerrados       "}
 
_aParAux:={}
aAdd( _aParAux , { 1 , "Data de"	  , MV_PAR01, "@D"	, ""	, ""		, "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Data ate"	  , MV_PAR02, "@D"	, ""	, ""		, "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Pedidos"	  , MV_PAR03, "@!"    , ""	, 'F3ITLC'	, "" , 100 , .F. } )
aAdd( _aParAux , { 1 , "Fornecedor"	  , MV_PAR04, "@!"    , ""	, 'F3ITLC'	, "" , 100 , .F. } )
aAdd( _aParAux , { 1 , "Produtos"     , MV_PAR05, "@!"    , ""	, 'F3ITLC'	, "" , 100 , .F. } )
aAdd( _aParAux , { 3 , "Status"       , MV_PAR06, _aStatus,100          , "", .T., .T. , .T. } )

For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next nI

While .T.

        //ParamBox( _aParAux , cTitle                                 , @aRet     ,[bOk]    , [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
    If !ParamBox( _aParAux , "Digite os filtros dos dados do Leite" , @_aParRet ,{||.T.}  , /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
        Exit
    EndIf

    If !Empty(MV_PAR01) .And.  !Empty(MV_PAR02) .And.  MV_PAR01 > MV_PAR02
        U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo com as 2 datas preenchidas",3)
        Loop
    EndIf
    //Log de utilização
    U_ITLOGACS()

    _aDados  := {}
    _lSair   := .F.
    cTimeInicial:=Time()


    FWMsgRun( ,{|oproc| _aDados := RGLT070SEL(oproc) } , "Aguarde!" , "Lendo dados..." )

    If Len(_aDados) > 0

        aCab:={}
        aAdd(aCab,"Pedido")
        aAdd(aCab,"Dt Emissao")
        aAdd(aCab,"Cod. Fornecedor")
        aAdd(aCab,"Nome Fornecedor")
        aAdd(aCab,"Cod. Produto")
        aAdd(aCab,"Nome Produto")
        aAdd(aCab,"Quant Prevista")
        aAdd(aCab,"Quant Realizada")
        aAdd(aCab,"Diferença")

        _cTitulo2:=_cTitulo+' - Data: ' + DToC(Date()) 
        _cMsgTop:="Par. 1: "+AllTrim(AllToChar(MV_PAR01))+"; Par. 2: "+AllTrim(AllToChar(MV_PAR02))+"; Par. 3: "+AllTrim(AllToChar(MV_PAR03))+"; Par. 4: "+AllTrim(AllToChar(MV_PAR04))+;
                "; Par. 5: "+AllTrim(AllToChar(MV_PAR05))+"; Par. 6: "+AllTrim(AllToChar(MV_PAR06))+" -  H.I.: "+cTimeInicial+" H.F.: "+Time()

                                //        ,_aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca )
       _lSair:=!U_ITListBox(_cTitulo2,aCab,_aDados , .T.    , 1    ,_cMsgTop,          ,        ,         ,     ,        ,          ,       ,         ,          ,            )
    
    Else
        U_ITMsg("Não á registro para esses filtros",'Atenção!',"Tente novamente com outros filtros",3)
        Loop
    EndIf
EndDo

Return

/*
===============================================================================================================================
Programa----------: RGLT070SEL
Autor-------------: Alex Wallauer
Data da Criacao---: 23/02/2022
Descrição---------: Carga de dados para o relatório
Parametros--------: oproc - objeto da barra de processmento 
Retorno-----------: _aRet - dados coletados do banco
===============================================================================================================================
*/
Static Function RGLT070SEL(oproc)
Local _aRet		:= {}
Local _cQuery	:= ""
Local _cAlias	:= GetNextAlias()

_cQuery := " SELECT "
_cQuery += " R_E_C_N_O_ RECNO  "	  
_cQuery += " FROM "+ RetSqlName("SC7") +" SC7 "+ CRLF
_cQuery += " WHERE SC7.C7_FILIAL = '" + cFilAnt + "' "
_cQuery += "   AND SC7.D_E_L_E_T_ = ' ' "

If !Empty(MV_PAR01)
	_cQuery += " AND C7_EMISSAO >= '"+DToS(MV_PAR01)+"' "
EndIf
If !Empty(MV_PAR02)
	_cQuery += " AND C7_EMISSAO <= '"+DToS(MV_PAR02)+"' "
EndIf
If !Empty(MV_PAR03)
	_cQuery += " AND C7_NUM IN "+FormatIn(AllTrim(MV_PAR03),";")
EndIf
If !Empty(MV_PAR04)
	_cQuery += " AND C7_FORNECE||C7_LOJA IN "+FormatIn(AllTrim(MV_PAR04),";")
EndIf
If !Empty(MV_PAR05)
	_cQuery += " AND C7_PRODUTO IN "+FormatIn(AllTrim(MV_PAR05),";")
EndIf

If MV_PAR06 = 2     // ABERTOS
	_cQuery += "AND C7_QUJE = '0' AND C7_ENCER <> 'E' AND C7_RESIDUO <> 'S' "		
ElseIf MV_PAR06 = 3 // PARCIAL
	_cQuery += "AND C7_QUJE < C7_QUANT AND C7_QUJE >  '0' AND C7_ENCER <> 'E' AND C7_RESIDUO <> 'S' "	
ElseIf MV_PAR06 = 4 // PARCIAL + ABERTOS
	_cQuery += "AND C7_QUJE < C7_QUANT AND C7_QUJE >= '0' AND C7_ENCER <> 'E' AND C7_RESIDUO <> 'S' "
ElseIf MV_PAR06 = 5 // ENCERRADO
	_cQuery += "AND (C7_ENCER = 'E' OR C7_RESIDUO = 'S') "	
EndIf

_cQuery += " ORDER BY C7_NUM "	

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
    oproc:cCaption := ("Lendo registro: " +StrZero(_nni,_nTam) +" de "+ _cTot )
    ProcessMessages()

    SC7->( DBGoTo((_cAlias)->RECNO) )
    aItem:={}
    aAdd(aItem,SC7->C7_NUM)
    aAdd(aItem,SC7->C7_EMISSAO)
    aAdd(aItem,SC7->C7_FORNECE+SC7->C7_LOJA)
    aAdd(aItem,Posicione("SA2",1,xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA, "A2_NOME"))
    aAdd(aItem,SC7->C7_PRODUTO)
    aAdd(aItem,Posicione("SB1",1,xFilial("SB1")+SC7->C7_PRODUTO,"B1_DESC"))
    aAdd(aItem,TRANS(SC7->C7_I_QTORI,"@E 999,999,999,999.99"))
    aAdd(aItem,TRANS(SC7->C7_QUJE,"@E 999,999,999,999.99"))
    aAdd(aItem,TRANS(SC7->C7_I_QTORI-SC7->C7_QUJE,"@E 999,999,999,999.99"))
    aAdd(_aRet,aItem)
    (_cAlias)->(DBSkip())

EndDo

Return( _aRet )
