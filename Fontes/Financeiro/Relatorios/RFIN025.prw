/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves |15/03/2024| Chamado 46603. Inclusão da Coluna de Nota Fiscal de Remessa
Igor Melgaço  |05/06/2024| Chamado 47265. Inclusão do Histórico da baixa.
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RFIN025
Autor-------------: Igor Melgaço
Data da Criacao---: 12/07/2023
Descrição---------: Relatório de Títulos abertos e ou atrasados Chamado 44450
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RFIN025()
Local nI := 0
Local _aParAux := {} 
Local _aParRet := {} 
Local _bOK     := {||.T.  }
Local _aAcesso := FWEmpLoad(.F.)//Se .T. retorna todas as empresas, se .F. retorna empresas que o usuário logado tem acesso
//Retorna aRRAY[n][1] = Código da empresa
//        aRRAY[n][2] = Nome da empresa
//        aRRAY[n][3] = Código da filial
//        aRRAY[n][4] = Nome da filial
MV_PAR01 := Space(99)
MV_PAR02 := CTOD("")
MV_PAR03 := CTOD("")
MV_PAR04 := CTOD("")
MV_PAR05 := CTOD("")
MV_PAR06 := Space(250)
MV_PAR07 := Space(400)
MV_PAR08 := 1
MV_PAR09 := 1
MV_PAR10 := 1
MV_PAR11 := CTOD("")
MV_PAR12 := CTOD("")

_aItalac_F3:={}
//_bSelectSA1:={|| "SELECT A1_COD, A1_LOJA,A1_NOME FROM "+RETSQLNAME("SA1")+" SA1 WHERE D_E_L_E_T_ = ' ' ORDER BY A1_COD,A1_LOJA "  }
//aAdd(_aItalac_F3,{"MV_PAR06",_bSelectSA1,{|Tab| (Tab)->A1_COD + ' ' + (Tab)->A1_LOJA }, {|Tab| (Tab)->A1_NOME } , ,"Clientes",,,15,.F.        ,       , } )
_bSelectSA1:={|| "SELECT DISTINCT A1_COD, A1_NOME FROM "+RETSQLNAME("SA1")+" SA1 WHERE D_E_L_E_T_ = ' ' ORDER BY A1_COD "  }
aAdd(_aItalac_F3,{"MV_PAR06",_bSelectSA1,{|Tab| (Tab)->A1_COD }, {|Tab| (Tab)->A1_NOME } , ,"Clientes",,,15,.F.        ,       , } )

_bSelectSX5:={|| "SELECT DISTINCT SubStr(X5_CHAVE,1,3) X5_CHAVE, X5_DESCRI FROM "+RETSQLNAME("SX5")+" SX5 WHERE D_E_L_E_T_ = ' ' AND X5_TABELA = '05' ORDER BY X5_CHAVE "  }
aAdd(_aItalac_F3,{"MV_PAR07",_bSelectSX5,{|Tab| (Tab)->X5_CHAVE }, {|Tab|(Tab)->X5_DESCRI } , ,"Tipos de Título",3,,,.F.        ,       , } )

aAdd( _aParAux , { 1 , "Filiais"	           , MV_PAR01, ""		, ""	, "LSTFIL"    , "" , 100 , .F. } )
aAdd( _aParAux , { 1 , "Emissão de"	        , MV_PAR02, "@D"	, ""	, ""		  , "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Emissão ate"	     , MV_PAR03, "@D"	, ""	, ""		  , "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Vencimento de"	     , MV_PAR04, "@D"	, ""	, ""		  , "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Vencimento ate"	  , MV_PAR05, "@D"	, ""	, ""		  , "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Clientes"           , MV_PAR06, "@!"    , ""    , "F3ITLC"    , "" , 100 , .F. } )
aAdd( _aParAux , { 1 , "Tipos"              , MV_PAR07, "@!"    , ""    , "F3ITLC"    , "" , 100 , .F. } )
aAdd( _aParAux , { 3 , "Posição"            , MV_PAR08, {"Todos","Vencidos","Não vencidos"}, 060, "", .T., .T. , .T. } )
aAdd( _aParAux , { 3 , "Tipo Vencimento"    , MV_PAR09, {"Original","Real"}                , 060, "", .T., .T. , .T. } )
aAdd( _aParAux , { 3 , "Tipo Relatorio"     , MV_PAR10, {"Abertos","Baixados"}             , 060, "", .T., .T. , .T. } )
aAdd( _aParAux , { 1 , "Baixa de  "	        , MV_PAR11, "@D"	, ""	, ""		  , "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Baixa ate"	        , MV_PAR12, "@D"	, ""	, ""		  , "" , 050 , .F. } )

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next

While .T.
		//aParametros, cTitle                          , @aRet   ,[bOk]  , [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
	If !ParamBox( _aParAux , "Selecione os filtros" , @_aParRet,  _bOK , /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
	   Exit
	EndIf
    
	If MV_PAR10 = 2//Quando Tipo Relatorio = Baixados não filtrar Vencidos ou Não vencidos
       MV_PAR08:=1
	EndIf

	If !Empty(MV_PAR01)
			
	    _cFilSemAcesso:=""
        _cFilNaoExiste:=""
		SM0->(DBSetOrder(1))
		_aFilSelecionados := U_ITLinDel( AllTrim(MV_PAR01) , ";" )
		For nI := 1 To Len(_aFilSelecionados)
			If aScan( _aAcesso , {|F| F[3] == _aFilSelecionados[nI] } ) = 0
			   _cFilSemAcesso+="[ "+_aFilSelecionados[nI]+" ] "
			EndIf
               If !SM0->(DBSeek(cEmpAnt + _aFilSelecionados[nI]))
			   _cFilNaoExiste+="[ "+_aFilSelecionados[nI]+" ] "
			EndIf
		Next
		If !Empty(_cFilNaoExiste)
			U_ITMsg("A(s) Filiai(s): "+_cFilNaoExiste+" não são válidas." , "Atenção!" ,"Selecione as filiais validas pelo F3.",1 )
			Loop	
		EndIf
		If !Empty(_cFilSemAcesso)
			U_ITMsg("O usuário não tem acesso a(s) Filiai(s): "+_cFilSemAcesso,"Atenção!","Selecione as filiais com acesso pelo F3.",1 )
			Loop
		EndIf
    EndIf
	cTimeInicial := Time()
 	FWMsgRun( ,{|oProc|  RFIN025R(oProc) } , "SE1 - Hora Inicial: "+cTimeInicial+", Aguarde...",  )

EndDo

Return

/*
===============================================================================================================================
Programa----------: RFIN025R
Autor-------------: Igor Melgaço
Data da Criacao---: 12/07/2023
Descrição---------: Função que imprime o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RFIN025R(oProc)
Local _cQuery    := ""
Local _cFiltro   := ""
Local _cAlias    := GetNextAlias()
Local _aLinha    := {}
Local _aDados    := {}
Local _aTit      := {}
Local _nDias     := 0 , L
Local _cPictValor:= "9999"+PesqPict("SE1","E1_VALOR")
Local _cPictSaldo:= "9999"+PesqPict("SE1","E1_SALDO")
Local _cPictDesc := "9999"+PesqPict("SE1","E1_SALDO")
Local i := 0

Local _cNotRem    := ""
Local _cSerRem    := ""
oProc:cCaption := ("Filtrando os dados! Aguarde...")
ProcessMessages()

If !Empty(AllTrim(MV_PAR01))
	_cFiltro += " AND E1_FILIAL IN " + FormatIn(AllTrim(MV_PAR01),";") 	
EndIf

If !Empty( MV_PAR02)
	_cFiltro += " AND E1_EMISSAO >= '" + DToS(MV_PAR02) + "' "
EndIf
If !Empty(MV_PAR03)
	_cFiltro += " AND E1_EMISSAO <= '" + DToS(MV_PAR03) + "' "
EndIf

If MV_PAR09 = 1//VENCTO Original

   If !Empty(AllTrim( DToS(MV_PAR04)+ DToS(MV_PAR05)))
   	   _cFiltro += " AND E1_VENCTO BETWEEN '" + DToS(MV_PAR04) + "' AND '" + DToS(MV_PAR05) + "' "
   EndIf
   If MV_PAR08 = 2
   	  _cFiltro += " AND E1_VENCTO <'" + DToS(dDataBase) + "' "
   ElseIf MV_PAR08 = 3
   	  _cFiltro += " AND E1_VENCTO >='" + DToS(dDataBase) + "' "
   EndIf

ElseIf MV_PAR09 = 2//VENCTO Real

   If !Empty(AllTrim( DToS(MV_PAR04)+ DToS(MV_PAR05)))
   	  _cFiltro += " AND E1_VENCREA BETWEEN '" + DToS(MV_PAR04) + "' AND '" + DToS(MV_PAR05) + "' "
   EndIf
   If MV_PAR08 = 2
   	  _cFiltro += " AND E1_VENCREA <'" + DToS(dDataBase) + "' "
   ElseIf MV_PAR08 = 3
   	  _cFiltro += " AND E1_VENCREA >='" + DToS(dDataBase) + "' "
   EndIf

EndIf

If !Empty(AllTrim(MV_PAR06))
    _cFiltro += " AND E1_CLIENTE IN "+FormatIn(AllTrim(StrTran(MV_PAR06, " ","")),";")
EndIf

If !Empty(AllTrim(MV_PAR07))
    _cFiltro += " AND TRIM(E1_TIPO) IN "+FormatIn(AllTrim(MV_PAR07),";")
EndIf

If MV_PAR10 = 1 // Abertos ******************************************

   _cQuery := "SELECT "
   _cQuery += "     E1_FILIAL	   , E1_PREFIXO	, E1_NUM		   , "
   _cQuery += "     E1_PARCELA   , E1_PORTADO	, E1_AGEDEP		, "
   _cQuery += "     E1_CONTA	   , E1_TIPO		, E1_NATUREZ	, "
   _cQuery += "     E1_CLIENTE   , E1_LOJA		, E1_NOMCLI		, "
   _cQuery += "     E1_EMISSAO   , E1_VENCTO		, E1_VENCREA	, E1_HIST   ,"
   _cQuery += "     E1_VALOR	   , E1_SALDO		, A1_CGC       , A1_EST   ,"
   _cQuery += "     E1_TIPODES   , E1_NUMBCO		, E1_DECRESC	, E1_I_CART , ZAR_DESC , E1_I_CHDCI,"
   _cQuery += "     E1_NUMBOR	   , E1_I_CARGA	, E1_I_DESCO   , E1_I_NUMBC, E1_EMIS1 ,"
   _cQuery += "     E1_I_ULBCO   , E1_I_ULCTA	, E1_I_ULAGE   , E1_IDCNAB , "
   _cQuery += "     E1_VEND1     , A3_COD       , A3_NOME      , E1_I_DTPRO, "
   _cQuery += "     F2_I_DTRC  DT_CANHOTO, "
   _cQuery += "     F2_I_DENCL DT_ENT_CLI, "
   _cQuery += "     F2_I_PENCL DT_PRV_CLI, "
   _cQuery += "     F2_I_PENCO DT_PRV_ORI, "
   _cQuery += "     F2_I_PENOL DT_PRVOPER, "
   _cQuery += "     F2_I_PEDID , "
   _cQuery += "     NVL((SELECT E1_SALDO FROM " + RetSqlName("SE1") + " SE11 "
   _cQuery += "          WHERE SE11.E1_FILIAL = SE1.E1_FILIAL AND SE11.E1_NUM= SE1.E1_NUM AND SE11.E1_CLIENTE = SE1.E1_CLIENTE "
   _cQuery += "            AND SE11.E1_LOJA = SE1.E1_LOJA AND SE11.E1_EMISSAO = SE1.E1_EMISSAO AND SE11.E1_PARCELA = SE1.E1_PARCELA "
   _cQuery += "            AND SE11.D_E_L_E_T_ =' ' AND SE11.E1_PREFIXO='DCT' AND SE11.E1_TIPO ='NCC'),0) E1_DESCFIN, "       
   _cQuery += "     F2_FILIAL||' '||F2_DOC||' '||F2_SERIE CHAVESF2, "
   _cQuery += "     A3_SUPER       , NVL((SELECT A3_NOME    FROM "+ RetSqlName("SA3") +" SA3S WHERE SA3S.A3_COD = SA3.A3_SUPER AND SA3S.D_E_L_E_T_ =' '),' ') A3_NSUPER, "
   _cQuery += "     A3_GEREN       , NVL((SELECT A3_NOME    FROM "+ RetSqlName("SA3") +" SA3G WHERE SA3G.A3_COD = SA3.A3_GEREN AND SA3G.D_E_L_E_T_ =' '),' ') A3_NGEREN, "
   _cQuery += "     A1_GRPVEN      , NVL((SELECT ACY_DESCRI FROM "+ RetSqlName("ACY") +" ACYG WHERE ACY_GRPVEN  = A1_GRPVEN    AND ACYG.D_E_L_E_T_ =' '),' ') A1_NGRPVEN "
   _cQuery += " FROM  "+ RetSqlName("SE1") +" SE1 " 
   _cQuery += "          JOIN "+ RetSqlName("SA1") +" SA1 ON SA1.A1_COD    = SE1.E1_CLIENTE AND SA1.A1_LOJA    = SE1.E1_LOJA AND SA1.D_E_L_E_T_ =' '" 
   _cQuery += "     LEFT JOIN "+ RetSqlName("SF2") +" SF2 ON SE1.E1_FILIAL = SF2.F2_FILIAL  AND SE1.E1_NUM     = SF2.F2_DOC  AND SE1.E1_PREFIXO = SF2.F2_SERIE AND SF2.D_E_L_E_T_ =' ' " 
   _cQuery += "     LEFT JOIN "+ RetSqlName("SA3") +" SA3 ON SE1.E1_VEND1  = SA3.A3_COD     AND SA3.D_E_L_E_T_ = ' ' " 
   _cQuery += "     LEFT JOIN "+ RetSqlName("ZAR") +" ZAR ON SE1.E1_I_CART = ZAR.ZAR_COD    AND ZAR.D_E_L_E_T_ = ' ' " 
   _cQuery += " WHERE SE1.D_E_L_E_T_ = ' ' AND E1_SALDO > 0 "
   _cQuery += _cFiltro
   _cQuery += " ORDER BY E1_FILIAL, E1_NUM, E1_CLIENTE, E1_LOJA"

ElseIf MV_PAR10 = 2 // Baixados

   If !Empty( MV_PAR11)
      _cFiltro += " AND E5_DATA >= '" + DToS(MV_PAR11) + "' "
   EndIf
   If !Empty(MV_PAR12)
      _cFiltro += " AND E5_DATA <= '" + DToS(MV_PAR12) + "' "
   EndIf
   _cQuery := " SELECT "
   _cQuery += "     E5_FILIAL  E1_FILIAL , E5_PREFIXO E1_PREFIXO  , E5_NUMERO E1_NUM         , A1_CGC ,"
   _cQuery += "     E5_PARCELA E1_PARCELA, E5_BANCO E1_PORTADO	   , E5_AGENCIA E1_AGEDEP     , E1_HIST,"
   _cQuery += "     E5_VALOR E1_VALOR    , E1_SALDO			      , "
   _cQuery += "     E5_CONTA E1_CONTA	  , E1_NATUREZ	            , E5_TIPO E1_TIPO          , A1_EST ,"
   _cQuery += "     E5_CLIFOR E1_CLIENTE , E1_LOJA                , E5_BENEF E1_NOMCLI       , E5_LOJA,"
   _cQuery += "     E5_HISTOR ,"
   _cQuery += "     E1_EMISSAO		     , E1_VENCTO			      , Case E1_I_DTPRO WHEN ' ' THEN E1_VENCREA Else E1_I_DTPRO END AS E1_VENCREA, "
   _cQuery += "     E1_TIPODES		     , E1_NUMBCO			      , E1_DECRESC	            , E1_I_CART         , ZAR_DESC  ,"
   _cQuery += "     E1_NUMBOR		        , E1_I_CARGA		         , E1_I_DESCO               , E1_I_NUMBC        , E1_EMIS1  ,"
   _cQuery += "     E1_I_ULBCO		     , E1_I_ULCTA		         , E1_I_ULAGE               , E1_IDCNAB         , E1_I_CHDCI,"
   _cQuery += "     E1_VEND1             , A3_COD                 , A3_NOME                  , E5_DATA E1_I_DTPRO, "
   _cQuery += "     F2_I_DTRC  DT_CANHOTO, "
   _cQuery += "     F2_I_DENCL DT_ENT_CLI, "
   _cQuery += "     F2_I_PENCL DT_PRV_CLI, "
   _cQuery += "     F2_I_PENCO DT_PRV_ORI, "
   _cQuery += "     F2_I_PENOL DT_PRVOPER, "
   _cQuery += "     F2_I_PEDID , "
   _cQuery += "     NVL((SELECT E1_SALDO FROM " + RetSqlName("SE1") + " SE11 "
   _cQuery += "          WHERE SE11.E1_FILIAL = SE1.E1_FILIAL AND SE11.E1_NUM= SE1.E1_NUM AND SE11.E1_CLIENTE = SE1.E1_CLIENTE "
   _cQuery += "            AND SE11.E1_LOJA = SE1.E1_LOJA AND SE11.E1_EMISSAO = SE1.E1_EMISSAO AND SE11.E1_PARCELA = SE1.E1_PARCELA "
   _cQuery += "            AND SE11.D_E_L_E_T_ =' ' AND SE11.E1_PREFIXO='DCT' AND SE11.E1_TIPO ='NCC'),0) E1_DESCFIN, "       
   _cQuery += "     F2_FILIAL||' '||F2_DOC||' '||F2_SERIE CHAVESF2, "
   _cQuery += "     A3_SUPER             , NVL((SELECT A3_NOME    FROM "+ RetSqlName("SA3") +" SA3S WHERE SA3S.A3_COD = SA3.A3_SUPER  AND SA3S.D_E_L_E_T_ =' '),' ') A3_NSUPER,"
   _cQuery += "     A3_GEREN             , NVL((SELECT A3_NOME    FROM "+ RetSqlName("SA3") +" SA3G WHERE SA3G.A3_COD = SA3.A3_GEREN  AND SA3G.D_E_L_E_T_ =' '),' ') A3_NGEREN,"
   _cQuery += "     A1_GRPVEN            , NVL((SELECT ACY_DESCRI FROM "+ RetSqlName("ACY") +" ACY WHERE ACY_GRPVEN   = SA1.A1_GRPVEN AND  ACY.D_E_L_E_T_ =' '),' ') A1_NGRPVEN"
   _cQuery += " FROM  "+ RetSqlName("SE5") +" SE5 " 
   _cQuery += "     INNER JOIN "+ RetSqlName("SE1") +" SE1 ON SE1.E1_FILIAL = SE5.E5_FILIAL  AND SE1.E1_NUM  = SE5.E5_NUMERO AND SE1.E1_PREFIXO = SE5.E5_PREFIXO AND SE1.E1_CLIENTE = SE5.E5_CLIFOR AND SE1.E1_LOJA = SE5.E5_LOJA AND SE1.D_E_L_E_T_ = ' ' "
   _cQuery += "           JOIN "+ RetSqlName("SA1") +" SA1 ON SA1.A1_COD    = SE1.E1_CLIENTE AND SA1.A1_LOJA = SE1.E1_LOJA   AND SE1.E1_PARCELA = SE5.E5_PARCELA AND SA1.D_E_L_E_T_ = ' ' " 
   _cQuery += "     LEFT  JOIN "+ RetSqlName("SF2") +" SF2 ON SE1.E1_FILIAL = SF2.F2_FILIAL  AND SE1.E1_NUM  = SF2.F2_DOC    AND SE1.E1_PREFIXO = SF2.F2_SERIE   AND SF2.D_E_L_E_T_ =' ' " 
   _cQuery += "     LEFT  JOIN "+ RetSqlName("SA3") +" SA3 ON SE1.E1_VEND1  = SA3.A3_COD     AND SA3.D_E_L_E_T_ = ' ' " 
   _cQuery += "     LEFT  JOIN "+ RetSqlName("ZAR") +" ZAR ON SE1.E1_I_CART = ZAR.ZAR_COD    AND ZAR.D_E_L_E_T_ = ' ' " 
   _cQuery += " WHERE SE5.E5_RECPAG ='R' AND SE5.E5_BANCO <> ' ' AND SE5.D_E_L_E_T_ = ' ' "
   _cQuery += _cFiltro
   _cQuery += " ORDER BY E1_FILIAL, E1_NUM, E1_CLIENTE, E1_LOJA"

EndIf
//E5_CLIFOR CODCLI, E5_LOJA LOJA, E5_BENEF NOME_CLIENTE, A1_CGC, A1_EST UF, E1_VENCTO VENCORI,
//Case E1_I_DTPRO WHEN ' ' THEN E1_VENCREA Else E1_I_DTPRO END AS VENCREA
//, E5_DATA DT_BAIXA, E5_VALOR VALOR, E5_BANCO BANCO, E5_AGENCIA AGENCIA, E5_CONTA CONTA
//FROM SIGH.SE5010 SE5
//INNER JOIN SIGH.SE1010 SE1 ON E1_FILIAL = E5_FILIAL AND E1_NUM = E5_NUMERO AND E1_PREFIXO = E5_PREFIXO AND E1_CLIENTE = E5_CLIFOR AND E1_LOJA = E5_LOJA AND SE1.D_E_L_E_T_ = ' '
//LEFT JOIN SIGH.SA1010 SA1 ON A1_COD = E5_CLIFOR AND A1_LOJA = E5_LOJA AND SA1.D_E_L_E_T_ =' '
//WHERE E5_RECPAG ='R' AND E5_BANCO ' ' AND SE5.D_E_L_E_T_ =' ' AND E5_DATA BETWEEN '20230901' AND '20230930'

MPSysOpenQuery( _cQuery, _cAlias ) 
(_cAlias)->(DBGoTop())

If ((_cAlias)->(Eof()) .And. (_cAlias)->(Bof()))
   U_ITMsg("Não há dados para essas seleções.",'Atenção!',,3)
   Return .F.
EndIf
_aCabXML:={}
// Alinhamento: 1-Left   ,2-Center,3-Right
// Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
//             Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
//   (_aCabXML,{Titulo             ,1           ,1         ,.F.       })
aAdd(_aTit,'') 
If MV_PAR10 = 1 // Abertos
   aAdd(_aCabXML,{"Prazo"          ,1           ,1         ,.F.})//01
ElseIf MV_PAR10 = 2 // Baixados
   aAdd(_aCabXML,{"Pago"           ,1           ,1         ,.F.})//01
EndIf
aAdd(_aTit,'Filial')  ; _nPosfil:=Len(_aTit)
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//02
aAdd(_aTit,'Prefixo')
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,1           ,1         ,.F.})//03
aAdd(_aTit,'Numero')  ; _nPosTit:=Len(_aTit)
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//04
aAdd(_aTit,'Parcela') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//05
aAdd(_aTit,'Tipo') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,1           ,1         ,.F.})//06
aAdd(_aTit,'Codigo Cliente') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//07
aAdd(_aTit,'Loja') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//08
aAdd(_aTit,'Nome')  ; _nPosNom:=Len(_aTit)
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,1           ,1         ,.F.})//09
aAdd(_aTit,'CNPJ')                 ; _nPosCNPJ:=Len(_aTit)    
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//10
aAdd(_aTit,'UF') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//11
aAdd(_aTit,'Emissão')              ; _nPosEmi:=Len(_aTit)
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//12
aAdd(_aTit,'Vencimento')           ; _nPosVen:=Len(_aTit)
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,4         ,.F.})//13
aAdd(_aTit,'Venc Real')            ; _nPosRea:=Len(_aTit)
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,4         ,.F.})//14
If MV_PAR10 = 1 // Abertos
   aAdd(_aTit,'Dt Prorrogação')    ;_nPosPro:=Len(_aTit)//15         
ElseIf MV_PAR10 = 2 // Baixados
   aAdd(_aTit,'Dt Baixa')          ;_nPosPro:=Len(_aTit)//15         
EndIf
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,4         ,.F.})//16
aAdd(_aTit,'Dt Contab.')            ;_nPosCon:=Len(_aTit)     
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,4         ,.F.})//17
aAdd(_aTit,'Qtd Dias de Vencto')   ;_nPosQtd  :=Len(_aTit)
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,2         ,.F.,"@E 999,999,999"})//18
aAdd(_aTit,'Valor')                ;_nPosValor:=Len(_aTit)
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,3           ,3         ,.F.})//19
aAdd(_aTit,'Saldo')                ;_nPosSaldo:=Len(_aTit)
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,3           ,3         ,.F.})//20
aAdd(_aTit,'Saldo Desc.Contratual');_nPosDesc :=Len(_aTit)    
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,3           ,3         ,.F.})//21
aAdd(_aTit,'Carteira') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,1           ,1         ,.F.})//22
aAdd(_aTit,'Desc Carteira') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,1           ,1         ,.F.})//23
aAdd(_aTit,'Portador') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//24
aAdd(_aTit,'Agencia') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//25
aAdd(_aTit,'Conta') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//26
aAdd(_aTit,'Nr Bordero') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//27
aAdd(_aTit,'Nosso Numero') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//28
aAdd(_aTit,'ID CNAB') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//29
aAdd(_aTit,'Natureza') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//30
aAdd(_aTit,'Cod Vendedor') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//31
aAdd(_aTit,'Nome Vendedor') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,1           ,1         ,.F.})//32
aAdd(_aTit,'Cod Coordenador') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//33
aAdd(_aTit,'Nome Coordenador') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,1           ,1         ,.F.})//34
aAdd(_aTit,'Cod Gerente') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//35
aAdd(_aTit,'Nome Gerente') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,1           ,1         ,.F.})//36
aAdd(_aTit,'Cod Grupo de Venda') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//37
aAdd(_aTit,'Nome Grupo de Venda') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,1           ,1         ,.F.})//38
aAdd(_aTit,'Chave NF Ori') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//39
aAdd(_aTit,'Historico'    )
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//38
aAdd(_aTit,'Ocorr. Fretes') 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//40
aAdd(_aTit,'Dt. Canhoto'               );_nPosDCan:=Len(_aTit) 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//41
aAdd(_aTit,'Dt. Entrega Cliente'       );_nPosDEnt:=Len(_aTit) 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//42
aAdd(_aTit,'Dt. Prevista Cliente'      );_nPosPCli:=Len(_aTit) 
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//43
aAdd(_aTit,'Prev.Entr.Cliente Original');_nPosPOri:=Len(_aTit)
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//44
aAdd(_aTit,'Prev.Entrega Oper.Log.'    );_nPosPOpe:=Len(_aTit)
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//45
aAdd(_aTit,'Cliente Remessa'    )
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,1           ,1         ,.F.})//46
aAdd(_aTit,'Chave Nota'    )
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//47
aAdd(_aTit,'Nota Remessa'    )
aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//48
If MV_PAR10 = 2 // Baixados
   aAdd(_aTit,'Historico de Baixa'    )
   aAdd(_aCabXML,{_aTit[Len(_aTit)]   ,2           ,1         ,.F.})//49
EndIf

_aTotais:={0,0,0,0,0,0}
ZF5->(DBSetOrder(1)) // ZF5_FILIAL+ZF5_DOCOC+ZF5_SEROC

While (_cAlias)->(!Eof())

	i++
	oproc:cCaption := ("Lendo registros "+AllTrim(Str(i)) )
    ProcessMessages()

    If MV_PAR10 = 1 // Abertos
       If MV_PAR09 = 1//VENCTO Original
          _nDias  := dDatabase - SToD((_cAlias)->E1_VENCTO)
       ElseIf MV_PAR09 = 2//VENCTO Real
          _nDias  := dDatabase - SToD((_cAlias)->E1_VENCREA)
       EndIf
    ElseIf MV_PAR10 = 2 // Baixados
       _nDias  := SToD((_cAlias)->E1_I_DTPRO) - SToD((_cAlias)->E1_VENCREA)
    EndIf
   If !Empty((_cAlias)->F2_I_PEDID)
//      _cPedRem := Posicione("SC5",1,xFilial("SC5")+(_cAlias)->F2_I_PEDID,"C5_I_PVREM")
      //_cCliRem := Posicione("SC5",1,xFilial("SC5")+_cPedRem,"C5_CLIENTE")
      _cPedRem := Posicione("SC5",1,(_cAlias)->E1_FILIAL+(_cAlias)->F2_I_PEDID,"C5_I_PVREM")
      _cCliRem := Posicione("SC5",1,(_cAlias)->E1_FILIAL+_cPedRem,"C5_CLIENTE")
      If !Empty(_cPedRem)
         _cNotRem := Posicione("SF2",20,(_cAlias)->E1_FILIAL+_cPedRem,"F2_DOC")
         _cSerRem := Posicione("SF2",20,(_cAlias)->E1_FILIAL+_cPedRem,"F2_SERIE")
      EndIf
      SA1->(DBSetOrder(1))
      If SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
         _cCliRem := SC5->C5_CLIENTE+" "+SC5->C5_LOJACLI+"-"+AllTrim(SA1->A1_NOME)+" ["+_cPedRem+"]"
      EndIf
   Else
      _cCliRem := ""
   EndIf

    _cOcorrFrete:=If(ZF5->(DBSeek((_cAlias)->E1_FILIAL+(_cAlias)->E1_NUM+(_cAlias)->E1_PREFIXO)),"SIM","NÃO")

    _cPFOUPJ:=If(Len(AllTrim((_cAlias)->A1_CGC))=11,Transform((_cAlias)->A1_CGC,"@R 999.999.999-99"),;
	                                                 Transform((_cAlias)->A1_CGC,"@R! NN.NNN.NNN/NNNN-99"))
	_aLinha := {}
	aAdd(_aLinha,If(_nDias>0,.F.,.T.))                                              //01
	aAdd(_aLinha,(_cAlias)->E1_FILIAL)                                              //02
	aAdd(_aLinha,(_cAlias)->E1_PREFIXO)                                             //03
	aAdd(_aLinha,(_cAlias)->E1_NUM)                                                 //04
	aAdd(_aLinha,(_cAlias)->E1_PARCELA)                                             //05
	aAdd(_aLinha,(_cAlias)->E1_TIPO)                                                //06
	aAdd(_aLinha,(_cAlias)->E1_CLIENTE)                                             //07
	aAdd(_aLinha,(_cAlias)->E1_LOJA)                                                //08
	aAdd(_aLinha,(_cAlias)->E1_NOMCLI)                                              //09
	aAdd(_aLinha,_cPFOUPJ)                                                          //10
	aAdd(_aLinha,(_cAlias)->A1_EST)                                                 //11
	aAdd(_aLinha,SToD((_cAlias)->E1_EMISSAO))                                       //12
	aAdd(_aLinha,SToD((_cAlias)->E1_VENCTO ))                                       //13
	aAdd(_aLinha,SToD((_cAlias)->E1_VENCREA))                                       //14
	aAdd(_aLinha,SToD((_cAlias)->E1_I_DTPRO))                                       //15
	aAdd(_aLinha,SToD((_cAlias)->E1_EMIS1  ))                                       //16
	aAdd(_aLinha,_nDias)                                                            //17
	aAdd(_aLinha,(_cAlias)->E1_VALOR )                                              //18
	aAdd(_aLinha,(_cAlias)->E1_SALDO )                                              //19
	aAdd(_aLinha,(_cAlias)->E1_DESCFIN)                                             //20
	aAdd(_aLinha,(_cAlias)->E1_I_CART)                                              //21
	aAdd(_aLinha,(_cAlias)->ZAR_DESC)                                               //22
	aAdd(_aLinha,(_cAlias)->E1_PORTADO)                                             //23
	aAdd(_aLinha,(_cAlias)->E1_AGEDEP)                                              //24
	aAdd(_aLinha,(_cAlias)->E1_CONTA)                                               //25
	aAdd(_aLinha,(_cAlias)->E1_NUMBOR)                                              //26
	aAdd(_aLinha,(_cAlias)->E1_NUMBCO)                                              //27
	aAdd(_aLinha,(_cAlias)->E1_IDCNAB)                                              //28
	aAdd(_aLinha,(_cAlias)->E1_NATUREZ)                                             //29
	aAdd(_aLinha,(_cAlias)->A3_COD)                                                 //30
	aAdd(_aLinha,(_cAlias)->A3_NOME)                                                //31
	aAdd(_aLinha,(_cAlias)->A3_SUPER)                                               //32
	aAdd(_aLinha,(_cAlias)->A3_NSUPER)                                              //33
	aAdd(_aLinha,(_cAlias)->A3_GEREN)                                               //34
	aAdd(_aLinha,(_cAlias)->A3_NGEREN)                                              //35
	aAdd(_aLinha,(_cAlias)->A1_GRPVEN)                                              //36
	aAdd(_aLinha,(_cAlias)->A1_NGRPVEN)                                             //37
	aAdd(_aLinha,(_cAlias)->E1_I_CHDCI)                                             //38
   aAdd(_aLinha,(_cAlias)->E1_HIST)                                                //39 
	aAdd(_aLinha,_cOcorrFrete)                                                      //40
	aAdd(_aLinha,SToD((_cAlias)->DT_CANHOTO))                                       //41 
	aAdd(_aLinha,SToD((_cAlias)->DT_ENT_CLI))                                       //42 
	aAdd(_aLinha,SToD((_cAlias)->DT_PRV_CLI))                                       //43 
	aAdd(_aLinha,SToD((_cAlias)->DT_PRV_ORI))                                       //44 
	aAdd(_aLinha,SToD((_cAlias)->DT_PRVOPER))                                       //45 
   aAdd(_aLinha,_cCliRem)                                                          //46 
   aAdd(_aLinha,(_cAlias)->CHAVESF2)                                               //47 
   aAdd(_aLinha,_cNotRem+" - "+_cSerRem)                                           //48
   If MV_PAR10 = 2 // Baixados
      aAdd(_aLinha,(_cAlias)->E5_HISTOR)    
   EndIf

    _aTotais[1]+=(_cAlias)->E1_VALOR// Total de valor
    _aTotais[2]+=(_cAlias)->E1_SALDO// Total de Saldo
    If MV_PAR10 = 1 // ABERTOS
       If _nDias > 0//VENCIDOS
	       _aTotais[3]+=(_cAlias)->E1_VALOR// Total de Valor Vencidos
          _aTotais[4]+=(_cAlias)->E1_SALDO// Total de Saldo Vencidos
	   Else
          _aTotais[5]+=(_cAlias)->E1_VALOR// Total de Valor a Vencer  
          _aTotais[6]+=(_cAlias)->E1_SALDO// Total de Saldo a Vencer 
      EndIf
//  ElseIf MV_PAR10 = 2 // BAIXADOS
    EndIf

    aAdd(_aDados,(_aLinha))
	
   _cNotRem := _cSerRem:= ""
	
   (_cAlias)->(DBSkip())
EndDo

If Len(_aDados) > 0 
	
   oproc:cCaption := ("Acertos finais...")

   (_cAlias)->(DBCloseArea())
//*************************************************************************************************
   _aColXML:=ACLONE(_aDados)//FORMATO CORRETO PARA GERAR O EXCEL EM INGLES COM PONTO PARA DECIMAIS
//*************************************************************************************************

   For L := 1 TO (Len(_aColXML))//AJUSTE PARA PARA GERAR O EXCEL CORRETO COM A LEGENDA
       _aColXML[L,1]:=If(_aColXML[L,1],"NO PRAZO","ATRASADO")
       _aColXML[L,_nPosEmi]:=If(Empty(_aColXML[L,_nPosEmi])," ",_aColXML[L,_nPosEmi])
       _aColXML[L,_nPosVen]:=If(Empty(_aColXML[L,_nPosVen])," ",_aColXML[L,_nPosVen])
       _aColXML[L,_nPosRea]:=If(Empty(_aColXML[L,_nPosRea])," ",_aColXML[L,_nPosRea])
       _aColXML[L,_nPosPro]:=If(Empty(_aColXML[L,_nPosPro])," ",_aColXML[L,_nPosPro])
       _aColXML[L,_nPosCon]:=If(Empty(_aColXML[L,_nPosCon])," ",_aColXML[L,_nPosCon])

       _aColXML[L,_nPosDCan]:=If(Empty(_aColXML[L,_nPosDCan])," ",_aColXML[L,_nPosDCan])
       _aColXML[L,_nPosDEnt]:=If(Empty(_aColXML[L,_nPosDEnt])," ",_aColXML[L,_nPosDEnt])
       _aColXML[L,_nPosPCli]:=If(Empty(_aColXML[L,_nPosPCli])," ",_aColXML[L,_nPosPCli])
       _aColXML[L,_nPosPOri]:=If(Empty(_aColXML[L,_nPosPOri])," ",_aColXML[L,_nPosPOri])
       _aColXML[L,_nPosPOpe]:=If(Empty(_aColXML[L,_nPosPOpe])," ",_aColXML[L,_nPosPOpe])
   Next   

   For L := 1 TO Len(_aDados)//AJUSTE PARA MOSTRAR NA TELA DO U_ITListBox() CORRETA
       _aDados[L,_nPosValor]:= TRANSFORM(_aDados[L,_nPosValor],_cPictValor)
       _aDados[L,_nPosSaldo]:= TRANSFORM(_aDados[L,_nPosSaldo],_cPictSaldo)
       _aDados[L,_nPosDesc ]:= TRANSFORM(_aDados[L,_nPosDesc ],_cPictDesc )
   Next

   If MV_PAR10 = 1 // Abertos
      _cTitulo:="Relação de Títulos em Aberto - "+DToC(DATE())+" - "+Time()
      _cMsgTop:= "TOTAIS: Valor A Vencer "+TRANSFORM(_aTotais[5],_cPictValor)+" | Valor Vencidos "+TRANSFORM(_aTotais[3],_cPictValor)+" | Saldo A Vencer "+TRANSFORM(_aTotais[6],_cPictSaldo)+" | Saldo Vencidos "+TRANSFORM(_aTotais[4],_cPictSaldo)+" | Valor Total "+TRANSFORM(_aTotais[1],_cPictValor)+" | Saldo Total "+TRANSFORM(_aTotais[2],_cPictValor)
   ElseIf MV_PAR10 = 2 // Baixados
      _cTitulo:="Relação de Títulos Baixados - "+DToC(DATE())+" - "+Time()
      _cMsgTop:= "TOTAIS: Valor Total "+TRANSFORM(_aTotais[1],_cPictValor)+" | Saldo Total "+TRANSFORM(_aTotais[2],_cPictValor)
   EndIf


    oOk:= LoadBitmap( GetResources() , "BR_VERDE"    )
    oNo:= LoadBitmap( GetResources() , "BR_VERMELHO" )
    _aButtons:={}
    aAdd(_aButtons,{"",{|| AOMS59Pes( oLbxAux ) }, "" , "PESQUISAR"} )

	//                        , _aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons , _aCab  , bDblClk , _aColXML , bCondMarca,_bLegenda:EVAL(_bLegenda,_aCols,oLbxAux:nAt),_lHasOk,_bHeadClk,_aSX1)
	U_ITListBox(_cTitulo,_aTit,_aDados  , .T.    , 3    ,_cMsgTop,          ,        ,         ,     ,        , _aButtons ,_aCabXML,         , _aColXML ,           ,{|aCol,Lin|If(aCol[Lin,1],oOk,oNo)}          )
Else				
	U_ITMsg("Não há dados para essa seleção",'Atenção!',,3)
EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS66Pesq
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 10/10/2023
Descrição---------: Pesquisas
Parametros--------: _oLbxAux
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function AOMS59Pes( oLbxAux ) 

Local _oDlg			:= Nil
Local _cGet 		:= Space(Len(SE1->E1_NOMCLI))
Local _nOpca		:= 0
Local nPos			:= 0
Local _lAchou		:= .F.
Local _aPosCol:={_nPosfil,_nPosTit,_nPosNom,_nPosVen}
Local aOrdem :={"Filial do Titulo","Numero do Titulo","Nome do Cliente","Vencimento Original"}
Local cOrdem :=aOrdem[2]

If oLbxAux <> NIL
   N:=oLbxAux:nAt
   aCols:=oLbxAux:aArray
Else
   Return .F.
EndIf

If MV_PAR09 = 2//VENCTO Real
   _aPosCol:={_nPosfil,_nPosTit,_nPosNom,_nPosRea}
   aOrdem :={"Filial do Titulo","Numero do Titulo","Nome do Cliente","Vencimento Real"}
EndIf

DEFINE MSDIALOG _oDlg TITLE "PESQUISAR" FROM 178,181 TO 259,697 PIXEL 

@ 004,003 ComboBox cOrdem ITEMS aOrdem SIZE 150,10 PIXEL OF _oDlg
@ 020,003 MsGet  _cGet			       SIZE 212,009 PIXEL OF _oDlg COLOR CLR_BLACK Picture "@!" 

DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( _nOpca := 1 , _oDlg:End() ) OF _oDlg
DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( _nOpca := 0 , _oDlg:End() ) OF _oDlg

ACTIVATE MSDIALOG _oDlg CENTERED

If _nOpca == 1
   _cGet := AllTrim( _cGet)
   _nOrdem:=aScan(aOrdem,cOrdem)
   If _nOrdem <> 0 
      If _nOrdem = 4 // DATAS DE VENCIMENTO
         _cGet := DToS(CTOD(_cGet))
	     aSort( aCols ,,, { |x,y| DToS(x[_aPosCol[4]]) < DToS(y[_aPosCol[4]]) } )
         nPos := aScan(aCols,{|P| DToS(P[_aPosCol[4]]) == _cGet }) 
      ElseIf _nOrdem = 3
	     aSort( aCols ,,, { |x,y| x[_aPosCol[3]] < y[_aPosCol[3]] } )
         nPos := aScan(aCols,{|P| _cGet $ P[_aPosCol[3]] }) 
      Else
	     aSort( aCols ,,, { |x,y| x[_aPosCol[_nOrdem]] < y[_aPosCol[_nOrdem]] } )
         nPos := aScan(aCols,{|P| AllTrim(P[_aPosCol[_nOrdem]]) == _cGet }) 
      EndIf
      If nPos <> 0 
      	  oLbxAux:nAt:= N :=nPos
      	 _lAchou:= .T.
      EndIf	  	
   EndIf	  	
Else
   Return .T.
EndIf

If _lAchou
   oLbxAux:Refresh()
   oLbxAux:SetFocus()
   //U_ITMsg(cOrdem+" "+_cGet+" esta na linha: "+AllTrim(Str(nPos)),'Atenção!',,2) 
Else
   U_ITMsg(cOrdem+" não foi encontrado.",'Atenção!',"Tente outro "+cOrdem,3) 
EndIf

Return .T.
