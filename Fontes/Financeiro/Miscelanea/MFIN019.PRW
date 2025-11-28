/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |23/02/2022| Chamado 39208. Ajustes para exibição de total selecionado.
===============================================================================================================================
*/

#Include "TOTVS.ch"

Static _aCab := {}
Static _aSizes := {}
Static _cMask := PesqPict( "SE2" , "E2_SALDO" )

/*
===============================================================================================================================
Programa----------: MFIN019
Autor-------------: Igor Melgaço
Data da Criacao---: 18/02/2021
Descrição---------: Processamento em lote de bloqueio gerencial de Título no Contas a Pagar CHAMADO 39208
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIN019()
Local _nI        := 0
Local _aParRet   := {}
Local _aParAux   := {}
Local _bOK       := {||.T.  }
Local _cTimeIni  := Time()
Local _lRet      := .F.
Local _nTamPref  := TamSX3("E2_PREFIXO")[1]
Local _nTamNum	  := TamSX3("E2_NUM")[1]
Local _nTamFor   := TamSX3("A2_COD")[1]
Local _nTamLoja  := TamSX3("A2_LOJA")[1]

DBSelectArea("ZZL")
DBSetOrder(3)
If DBSeek(xFilial("ZZL")+__cUserId)
   If !(ZZL->ZZL_BLQGER == "S")
      U_ITMsg("Usuário sem permissão de acesso a esta rotina. Para mais informações procurar o gestor financeiro da unidade.",,,3,,,,,, )
      Return .F.
   EndIf
EndIf

MV_PAR01 := Space(200)
MV_PAR02 := Space(_nTamPref)
MV_PAR03 := Space(_nTamPref)
MV_PAR04 := Space(_nTamNum)
MV_PAR05 := Space(_nTamNum)
MV_PAR06 := Ctod("")
MV_PAR07 := Ctod("")
MV_PAR08 := Space(_nTamFor)
MV_PAR09 := Space(_nTamLoja)
MV_PAR10 := Space(_nTamFor)
MV_PAR11 := Space(_nTamLoja)
MV_PAR12 := "1"

aAdd( _aParAux , { 1 , "Filiais: "	               , MV_PAR01, ""	   , ""	, "LSTFIL"	, "" , 100        , .F. } )
aAdd( _aParAux , { 1 , "Prefixo de: "        	   , MV_PAR02, ""	   , ""	, ""		   , "" , _nTamPref  , .F. } )
aAdd( _aParAux , { 1 , "Prefixo até: "	            , MV_PAR03, ""	   , ""	, ""		   , "" , _nTamPref  , .F. } )
aAdd( _aParAux , { 1 , "Numero de Título de: "	   , MV_PAR04, ""	   , ""	, ""		   , "" , _nTamNum   , .F. } )
aAdd( _aParAux , { 1 , "Numero de Título até: "	   , MV_PAR05, ""	   , ""	, ""		   , "" , _nTamNum   , .F. } )
aAdd( _aParAux , { 1 , "Emissão de"	               , MV_PAR06, "@D"	, ""  , ""	      , "" , 050        , .F. } )
aAdd( _aParAux , { 1 , "Emissão ate"               , MV_PAR07, "@D"	, ""  , ""	      , "" , 050        , .F. } )
aAdd( _aParAux , { 1 , "Fornecedor de: "	         , MV_PAR08, ""	   , ""	, "SA2"		, "" , _nTamFor   , .F. } )
aAdd( _aParAux , { 1 , "Loja de: "	               , MV_PAR09, ""	   , ""	, ""		   , "" , _nTamLoja  , .F. } )
aAdd( _aParAux , { 1 , "Fornecedor até: "	         , MV_PAR10, ""	   , ""	, "SA2"		, "" , _nTamFor   , .F. } )
aAdd( _aParAux , { 1 , "Loja até: "	               , MV_PAR11, ""	   , ""	, ""		   , "" , _nTamLoja  , .F. } )
aAdd( _aParAux , { 2 , "Operação a Executar: "	   , MV_PAR12, {"1=Bloqueio","2=Desbloqueio"}, 090 ,".T.", .T. } )


For _nI := 1 To Len( _aParAux )
      aAdd( _aParRet , _aParAux[_nI][03] )
Next _nI

If !ParamBox( _aParAux , " bloqueio gerencial em lote de Título no Contas a Pagar " , @_aParRet, _bOK )
   _lRet := .F.
Else
   FWMsgRun( ,{|oProc|  _lRet := MFIN019PR(oProc) } , "Hora Inicial: "+_cTimeIni+" Pesquisando títulos... " )
EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MFIN019PR
Autor-------------: Igor Melgaço
Data da Criacao---: 18/02/2021
Descrição---------: Processamento da rotina
Parametros--------: oProc = objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MFIN019PR(oProc)
Local _aTit     := {}
Local _cTitulo  := "Selecione os Registros para o "+IIf(MV_PAR10 == "1","Bloqueio","Desbloqueio")+" Gerencial"
Local _cMsgTop  := IIf(MV_PAR10 == "1","Bloqueio","Desbloqueio") + " Gerencial de título a Pagar"
Local _lRet     := .F.
Local _bDblClk  :={||}
Local _bHeadClk :={||}

Private _nTotalM := 0

_aTit := MFIN019QRY(oProc)

If Len(_aTit) = 0
   U_ITMsg( "De acordo com os parâmetros imputados não foi encontrado registro no periodo!" , "Atenção!",,2 )
Else
   _aCab := {"",;
            Getsx3cache("E2_FILIAL"  ,"X3_TITULO") ,;
            Getsx3cache("E2_PREFIXO" ,"X3_TITULO") ,;
            Getsx3cache("E2_NUM"     ,"X3_TITULO") ,;
            Getsx3cache("E2_PARCELA" ,"X3_TITULO") ,;
            Getsx3cache("E2_TIPO"    ,"X3_TITULO") ,;
            Getsx3cache("E2_EMISSAO" ,"X3_TITULO") ,;
            Getsx3cache("E2_FORNECE" ,"X3_TITULO") ,;
            Getsx3cache("E2_LOJA"    ,"X3_TITULO") ,;
            Getsx3cache("A2_NOME"    ,"X3_TITULO") ,;
            Getsx3cache("E2_VENCTO"  ,"X3_TITULO") ,;
            Getsx3cache("E2_VALOR"   ,"X3_TITULO") ,;
            Getsx3cache("E2_SALDO"   ,"X3_TITULO") ,;
            Getsx3cache("E2_PORTADOR","X3_TITULO") ,;
            ""}

   _aSizes := {20,20,30,50,20,30,50,50,20,100,50,50,50,30,100}
   
   //_bDblClk := {|| (_nTotalM += oLbxDados:aArray[oLbxAux:nAt][12]) , (_cMsgTop := _cMsgTop + Space(10) + Transform(  _aTit[12]  , _cMask ) ), oMsgTop:SysRefresh()   }
   _bDblClk := {|| U_MFIN019H( @oLbxAux, @oSayAux, @_cMsgTop,.F.) }
   _bHeadClk := {|oLbx, ni| IIf(ni=1,FWMsgRun( ,{|oProc,oLbx|  U_MFIN019H( @oLbxAux, @oSayAux, @_cMsgTop, .T.,oProc) } , "Processando... " ),.F.)  }
            //  ITListBox( _cTitAux , _aHeader , _aCols , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk      , _aColXML , bCondMarca,_bLegenda, _lBtnOk,_bHeadClk)
   _lRet := U_ITListBox(_cTitulo  , _aCab     ,@_aTit , .T.       , 2      ,@_cMsgTop , .F.      , _aSizes  ,         ,     ,        ,         ,      , _bDblClk ,          ,/*_bCondMarca*/,         ,        , _bHeadClk )

   If _lRet
      MDIN019GR(_aTit,oProc)
   EndIf

EndIf

Return _lRet


/*
===============================================================================================================================
Programa----------: MFIN019QRY
Autor-------------: Igor Melgaço
Data da Criacao---: 18/02/2021
Descrição---------: Executa Busca de Títulos
Parametros--------: Nenhum
Retorno-----------: oProc = Status de Processamento
===============================================================================================================================
*/
Static Function MFIN019QRY(oProc)
Local _cFiltro := "% "
Local _aTit := {}
Local i := 0


If !Empty(MV_PAR01)

	_cFiltro += " AND E2_FILIAL IN " + FormatIn(AllTrim(MV_PAR01),";") 
	
EndIf


If !Empty(AllTrim(MV_PAR02+MV_PAR03))

	_cFiltro += " AND E2_PREFIXO BETWEEN '" + MV_PAR02 + "' AND '" + MV_PAR03 + "' "
	
EndIf

If !Empty(AllTrim(MV_PAR04+MV_PAR05))

	_cFiltro += " AND E2_NUM BETWEEN '" + MV_PAR04 + "' AND '" + MV_PAR05 + "' "
	
EndIf


    _cFiltro += " AND E2_EMISSAO BETWEEN '" + DToS(MV_PAR06) + "' AND '" + DToS(MV_PAR07) + "' "


If !Empty(AllTrim(MV_PAR08+MV_PAR10))

	_cFiltro += " AND E2_FORNECE BETWEEN '" + MV_PAR08 + "' AND '" + MV_PAR10 + "' "
	
EndIf

If !Empty(AllTrim(MV_PAR09+MV_PAR11))

	_cFiltro += " AND E2_LOJA BETWEEN '" + MV_PAR09 + "' AND '" + MV_PAR11 + "' "
	
EndIf

If MV_PAR12 == "1"
   _cFiltro += " AND E2_MSBLQL <> '1' "
Else
   _cFiltro += " AND E2_MSBLQL = '1' "
EndIf


_cFiltro += " %"


	//====================================================================================================
	// Executa query para consultar Dados
	//====================================================================================================

   _cAlias:= GetNextAlias()

   If Select(_cAlias) > 0
		(_cAlias)->( DBCloseArea() )
	EndIf
	
   BeginSql Alias _cAlias
      
      SELECT E2_FILIAL, E2_PREFIXO,E2_NUM, E2_PARCELA, E2_TIPO, E2_EMISSAO, E2_FORNECE, A2_NOME, E2_LOJA, E2_VENCTO, E2_VENCREA, E2_VALOR, E2_SALDO, E2_PORTADO
      FROM %Table:SE2% SE2
               JOIN %Table:SA2% SA2
         ON (SE2.E2_FORNECE = SA2.A2_COD AND SE2.E2_LOJA = SA2.A2_LOJA AND SA2.%notDel%)
      WHERE SE2.%notDel%
            AND E2_SALDO > 0
            AND E2_TIPO NOT IN ('PA ','TX ','INS ')
            %Exp:_cFiltro%
      ORDER BY E2_FILIAL, E2_PREFIXO,E2_NUM

   EndSql

	(_cAlias)->(DBGoTop())
   
   While (_cAlias)->(!Eof())
      i++
      aAdd(_aTit,;
         {.F.,;
         (_cAlias)->E2_FILIAL ,;
         (_cAlias)->E2_PREFIXO ,;
         (_cAlias)->E2_NUM     ,;
         (_cAlias)->E2_PARCELA ,;
         (_cAlias)->E2_TIPO    ,;
         SToD((_cAlias)->E2_EMISSAO) ,;
         (_cAlias)->E2_FORNECE ,;
         (_cAlias)->E2_LOJA    ,;
         (_cAlias)->A2_NOME    ,;
         SToD((_cAlias)->E2_VENCTO)  ,;
         Transform(  (_cAlias)->E2_VALOR  , _cMask )    ,;
         Transform(  (_cAlias)->E2_SALDO  , _cMask )    ,;
         (_cAlias)->E2_PORTADOR,;
         ""};
      )
      
      oproc:cCaption := ("Lendo registros "+AllTrim(Str(i)))
      ProcessMessages()

      (_cAlias)->(DBSkip())

   EndDo

   (_cAlias)->(DBCloseArea())

Return _aTit


/*
===============================================================================================================================
Programa----------: MDIN019GR
Autor-------------: Igor Melgaço
Data da Criacao---: 18/02/2021
Descrição---------: Rotina de gravação do Array
Parametros--------: _aTit = Array de títulos 
------------------: oProc = Status de Processamento
Retorno-----------: 
===============================================================================================================================
*/  
Static Function MDIN019GR(_aTit,oProc)
Local i := 0
Local _cMsg := ""
Local _cTitulo := "Log "+IIf(MV_PAR10 == "1","Bloqueio","Desbloqueio")+" Gerencial dos titulos"
Local _cMsgTop := IIf(MV_PAR10 == "1","Bloqueio","Desbloqueio") + " Gerencial de título a Pagar"
Local _bOk := {||.T.}
Local _nTam := 0
Local _aProc := {}
Local _nTotalP := 0
Local _nTotalNP := 0

_aCab[14] := "Processamento..."

For i := 1 To Len(_aTit)
   If _aTit[i,1]
      aAdd(_aProc,_aTit[i])
   EndIf
Next

_nTam :=  Len(_aProc)

If _nTam > 0
   For i := 1 To _nTam
      oproc:cCaption := ("Processando "+AllTrim(Str(i))+" de "+AllTrim(Str(_nTam)))
      ProcessMessages()

      DBSelectArea("SE2")
      DBSetOrder(1) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
      If DBSeek(_aProc[i,2]+_aProc[i,3]+_aProc[i,4]+_aProc[i,5]+_aProc[i,6]+_aProc[i,8]+_aProc[i,9] )
         _aProc[i,1]  := U_F050BLQGER(.T.,@_cMsg)
         _aProc[i,14] := _cMsg
      Else
         _aProc[i,1]  := .F.
      EndIf

      If _aProc[i,1] 
         _nTotalP += Val(StrTran(StrTran(_aProc[i][13],".",""),",","."))
      Else
         _nTotalNP += Val(StrTran(StrTran(_aProc[i][13],".",""),",","."))
      EndIf
   Next

   _cMsgTop :=  _cMsgTop + Space(20) + "Total Processado:"+ Transform(  _nTotalP  , _cMask ) + Space(20) + "Total Não Processado:"+ Transform(  _nTotalNP  , _cMask )

   //   ITListBox( _cTitAux , _aHeader  , _aCols, _lMaxSi, _nTip, _cMsgTo, _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda, _lBtnOk)
   U_ITListBox(_cTitulo  , _aCab     ,_aProc , .T.    , 4    ,_cMsgTop , .F.     , _aSizes  ,        , _bOk,        ,          ,       ,         ,          ,           ,         ,  .F.      )
Else
   U_ITMsg("Nenhum registro selecionado para "+IIf(MV_PAR10 == "1","Bloqueio","Desbloqueio")+"!",,,3,,,,,, )
EndIf
 _aTit := {}

Return .T.

        
User Function MFIN019H( oLbxDados, oMsgStop, _cMsgTop, lHeader,oProc)
Local _nPos := 0
Local _nTam := 0
Default lHeader := .F.

   If lHeader
      _nTam := Len( oLbxDados:aArray )
      oproc:cCaption := ("Atualizando os registros...   Total: "+AllTrim(Str(_nTam)))
      ProcessMessages()
      
      For _nPos := 1 To _nTam

            oLbxDados:aArray[ _nPos , 01 ] := !oLbxDados:aArray[ _nPos , 01 ]

            If oLbxDados:aArray[ _nPos , 01 ]
               _nTotalM += Val(StrTran(StrTran(oLbxDados:aArray[_nPos][13],".",""),",","."))
            Else
               _nTotalM -= Val(StrTran(StrTran(oLbxDados:aArray[_nPos][13],".",""),",","."))
            EndIf
            
      Next _nPos
   Else
      _nPos := oLbxAux:nAt

      oLbxDados:aArray[ _nPos , 01 ] := !oLbxDados:aArray[ _nPos , 01 ]

      If oLbxDados:aArray[ _nPos , 01 ]
         _nTotalM += Val(StrTran(StrTran(oLbxDados:aArray[_nPos][13],".",""),",","."))
      Else
         _nTotalM -= Val(StrTran(StrTran(oLbxDados:aArray[_nPos][13],".",""),",","."))
      EndIf

   EndIf

   _cMsgTop :=  IIf(MV_PAR10 == "1","Bloqueio","Desbloqueio") + " Gerencial de título a Pagar" + Space(20) + "Total Selecionado:"+ Transform(  _nTotalM  , _cMask )
   oMsgStop:Refresh()
   oLbxDados:Refresh()


Return
