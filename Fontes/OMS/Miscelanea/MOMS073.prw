/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Alex Wallauer |22/08/2025| Chamado 50463. Novos calculos baseado nos cadastros de Premissas Z39 , Z39 e Z40.
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
=========================================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MOMS073
Autor-------------: Alex Wallauer
Data da Criacao---: 06/03/2025
Descrição---------: Rotina para calculo baseado nos cadastros de Premissas Z39 , Z39 e Z40 dos Leites magro e integral
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS073()

 Local _aParRet     := {} As Array
 Local _aParAux     := {} As Array
 Local _bOK         := {|| U_MOMS073Val() } As Block
 Local _nI          := 0 As Numeric
 Local _lRet        := .F. As Logical
 Local _aTables     := {"SC5","SF2","SC6","Z38","Z39","Z40"} As Array

 Private _lScheduler:= FWGetRunSchedule() As Logical
 Private _lAmbTeste := .F.
  // Verifica a necessidade de criar um ambiente, caso nao esteja
 // criado anteriormente um ambiente, pois ocorrera erro
 If Select("SX3") <= 0
    // Nao consome licensas
    RPCSetType(3)
    // Seta o ambiente com a empresa 01 filial 01
    RpcSetEnv("01","01",,,,"SCHEDULE_PC_LIBERADOS",_aTables)
    _lScheduler:=.T.
 EndIf

 _dDataDia:=Date()
 _nMes    := Val(SubStr(DToS(_dDataDia),5,2))
 _nAno    := Val(SubStr(DToS(_dDataDia),1,4))
 _dDtIni  := Ctod("01/"+StrZero(_nMes,2)+"/"+StrZero(_nAno,4))
 MV_PAR01 := Space(100)
 MV_PAR02 := Space(100)
 MV_PAR03 := Space(100)
 MV_PAR04 := StrZero(_nMes,2)+StrZero(_nAno,4)
 MV_PAR05 := _dDtIni
 MV_PAR06 := LastDate(_dDtIni)//Date()
 
 If _lScheduler
    MOMS73INT()
 Else
    _lAmbTeste := !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
    _bCondTab  :={ || If(Empty(MV_PAR04),.T., (Z38_PERIOD == RIGHT(MV_PAR04,4)+LEFT(MV_PAR04,2)) )  } 
    _bValida   :={ |cAcao,_aDados| If(cAcao<>"D", .T. , _cRetorno:=(Len(_aDados) > 0) ) }
    _cSelectZ38:="SELECT Z38_COD , Z38_PERIOD, Z38_DESC FROM "+RETSQLNAME("Z38")+" Z38 WHERE D_E_L_E_T_ = ' ' AND Z38_MSBLQL = '2' ORDER BY Z38_COD "
    
    _aItalac_F3:={}//       1           2         3                      4                      5               6                    7         8          9         10         11        12
    //AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela   ,_nCpoChave           , _nCpoDesc                                  ,_bCondTab, _cTitAux         , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
    aAdd(_aItalac_F3,{"MV_PAR03"   ,_cSelectZ38,{|Tab|(Tab)->Z38_COD},{|Tab|(Tab)->Z38_PERIOD+" "+(Tab)->Z38_DESC},_bCondTab,"Premissas"       ,          ,          ,          ,.F.        ,       ,_bValida } )

    aAdd( _aParAux , { 1 , "Gerente "     , MV_PAR01, "@!" , "" , "LSTGER" , "Empty(MV_PAR02)" , 100 , .F. } )//01
    aAdd( _aParAux , { 1 , "Coordenador " , MV_PAR02, "@!" , "" , "LSTSUP" , "Empty(MV_PAR01)" , 100 , .F. } )//02
    aAdd( _aParAux , { 1 , "Premissa"     , MV_PAR03, "@!" , "" , "F3ITLC" , ""                , 100 , .F. } )//03
    aAdd( _aParAux , { 1 , "Digite o Periodo (MM/AAAA)", MV_PAR04, "@R 99/9999", "U_MOMS073Val()","","", 070 , .T. } )//04
    If _lAmbTeste 
       aAdd( _aParAux , { 1 , "Data emissão de" , MV_PAR05, "@D" , "" , ""   , ""              , 100 , .T. } )//05
       aAdd( _aParAux , { 1 , "Data emissão ate", MV_PAR06, "@D" , "" , ""   , ""              , 100 , .T. } )//05
    EndIf
    For _nI := 1 To Len( _aParAux )
       aAdd( _aParRet , _aParAux[_nI][03] )
    Next _nI
    
    While .T.
    
       // ParamBox( _aParAux , cTitle                                                       , @aRet    ,[bOk], [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
       If ParamBox( _aParAux , " Percentual de Meta e Percentual Acumulado do Coordenador " , @_aParRet, _bOK, /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
          
          
          MV_PAR01 := AllTrim(MV_PAR01)//Gerente
          MV_PAR02 := AllTrim(MV_PAR02)//Coordenador
          MV_PAR03 := AllTrim(MV_PAR03)//Premissa
          _dDataDia:= MV_PAR04
          _dDtIni  := Ctod("01/"+LEFT(_dDataDia,2)+"/"+RIGHT(_dDataDia,4))//PRIMEIRO DIA DO MES
          _dDataDia:= LastDate(_dDtIni)//Retorna a Data do ùltimo dia do MES da Data Passada

          If !_lAmbTeste 
             MV_PAR05:= _dDtIni
             MV_PAR06:= _dDataDia
          EndIf
          
          FWMsgRun( ,{|oProc|  _lRet := MOMS73INT(oProc) } , "Hora Inicial: "+Time()+" Selecionando notas... ","Lendo de "+DToC(_dDtIni)+" até "+DToC(_dDataDia) )
          
          If !_lRet
             Loop
          EndIf
   
       EndIf
       
       Exit
    
    EndDo
    
 EndIf

Return

/*
===============================================================================================================================
Programa----------: MOMS073Val()
Autor-------------: Alex Wallauer
Data da Criacao---: 01/09/2025
Descrição---------: Validações do ParamBox.
Parametros--------: Nenhum
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
User Function MOMS073Val()

 Local _cMes:= MV_PAR04
 Local _lRet:=.T.
 Z38->(DBSetOrder(2))
 _cMes:= RIGHT(_cMes,4)+LEFT(_cMes,2)
 If !Z38->(MsSeek( FWxFilial() + _cMes ))
    U_ITMsg("Não há premissas cadastradas para esse Mes+Ano "+MV_PAR04,'Atenção!',"Selecione um mes com premissas cadastradas.",1) // Cancel
    _lRet:=.F.
 EndIf
 Z38->(DBSetOrder(1))

Return _lRet

/*
===============================================================================================================================
Programa----------: MOMS73INT
Autor-------------: Alex Wallauer
Data da Criacao---: 06/03/2025
Descrição---------: Rotinas para Ler as notas fiscais e PVs para calcular o percentual de meta e acumulado do Coordenador
Parametros--------: oProc As Object
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function MOMS73INT(oProc As Object) As Logical

 Local aCab     As Array
 Local _cTitAux As Character
 Local _cMsgTop As Character
 Local _cAlias:= GetNextAlias() As Character
 Local L      := 0 As Numeric
 Local _cQry  := "" As Character
 Local aLog   := {} As Array
 Local _lRet  :=.T. As Logical
 Local cTimeInicial:=Time() As Character
 _cQry +=  " WITH "
 _cQry +=  "     BASE_Z38 "
 _cQry +=  "     AS "
 _cQry +=  "         (SELECT Z38_COD        COD, "
 _cQry +=  "                 Z38_TPCALC     TPCALC, "
 _cQry +=  "                 Z38_FILIAL     FILIAL, "
 _cQry +=  "                 Z38_PERIOD     PERIOD "
 _cQry +=  "            FROM Z38010 "
 _cQry +=  "           WHERE     Z38_FILIAL = ' ' "
 _cQry +=  "                 AND Z38_PERIOD = '"+LEFT(DToS(_dDataDia),6)+"' "
 If !Empty( MV_PAR03 )
    If Len(AllTrim(MV_PAR03)) = 3
       _cQry += "             AND Z38_COD = '"+ AllTrim(MV_PAR03) + "' "
    Else
       _cQry += "             AND Z38_COD IN "+ FormatIn(MV_PAR03, ";" )
    EndIf
 EndIf
 _cQry +=  "                 AND Z38_MSBLQL <> '1' "
 _cQry +=  "                 AND D_E_L_E_T_ = ' '), "
 _cQry +=  "     BASE_Z40 "
 _cQry +=  "     AS "
 _cQry +=  "         (SELECT Z40_COD        COD, "
 _cQry +=  "                 Z40_COORD      COORD, "
 _cQry +=  "                 Z40_FILIAL     FILIAL, "
 _cQry +=  "                 Z40_PERIOD     PERIOD "
 _cQry +=  "            FROM Z40010 "
 _cQry +=  "           WHERE     Z40_FILIAL = ' ' "
 _cQry +=  "                 AND Z40_PERIOD = '"+LEFT(DToS(_dDataDia),6)+"' "
 If !Empty( MV_PAR02 )
    If Len(AllTrim(MV_PAR02)) = 6
       _cQry += "            AND Z40_COORD = '"+ AllTrim(MV_PAR02) + "' "
    Else
       _cQry += "            AND Z40_COORD IN "+ FormatIn( MV_PAR02 , ";" )
    EndIf
 EndIf
 _cQry +=  "                 AND D_E_L_E_T_ = ' '), "
 _cQry +=  "     BASE "
 _cQry +=  "     AS "
 _cQry +=  "         (SELECT Z38.COD, Z38.TPCALC, Z40.COORD "
 _cQry +=  "            FROM BASE_Z38  Z38 "
 _cQry +=  "                 JOIN BASE_Z40 Z40 "
 _cQry +=  "                     ON     Z40.FILIAL = Z38.FILIAL "
 _cQry +=  "                        AND Z40.COD = Z38.COD "
 _cQry +=  "                        AND Z40.PERIOD = Z38.PERIOD), "
 _cQry +=  "     FAT "
 _cQry +=  "     AS "
 _cQry +=  "         (  SELECT Z38.COD, "
 _cQry +=  "                   Z38.TPCALC, "
 _cQry +=  "                   Z40.COORD, "
 _cQry +=  "                   SUM ( "
 _cQry +=  "                       Case "
 _cQry +=  "                           WHEN Z39_TIPO = 'A' AND Z39_TPCONV = 'M' "
 _cQry +=  "                           THEN "
 _cQry +=  "                               (D2_QUANT - D2_QTDEDEV) * Z39_FATOR "
 _cQry +=  "                           WHEN Z39_TIPO = 'A' "
 _cQry +=  "                           THEN "
 _cQry +=  "                               (D2_QUANT - D2_QTDEDEV) / Z39_FATOR "
 _cQry +=  "                           Else "
 _cQry +=  "                               0 "
 _cQry +=  "                       END)    AS FAT_A, "
 _cQry +=  "                   SUM ( "
 _cQry +=  "                       Case "
 _cQry +=  "                           WHEN Z39_TIPO = 'B' AND Z39_TPCONV = 'M' "
 _cQry +=  "                           THEN "
 _cQry +=  "                               (D2_QUANT - D2_QTDEDEV) * Z39_FATOR "
 _cQry +=  "                           WHEN Z39_TIPO = 'B' "
 _cQry +=  "                           THEN "
 _cQry +=  "                               (D2_QUANT - D2_QTDEDEV) / Z39_FATOR "
 _cQry +=  "                           Else 0 END)    AS FAT_B "
 _cQry +=  "              FROM BASE_Z38 Z38 "
 _cQry +=  "                   JOIN Z39010 Z39 "
 _cQry +=  "                       ON     Z39_FILIAL = Z38.FILIAL "
 _cQry +=  "                          AND Z39_COD = Z38.COD "
 _cQry +=  "                          AND Z39_PERIOD = Z38.PERIOD "
 _cQry +=  "                          AND Z39.D_E_L_E_T_ = ' ' "
 _cQry +=  "                   JOIN BASE_Z40 Z40 "
 _cQry +=  "                       ON     Z40.FILIAL = Z39_FILIAL "
 _cQry +=  "                          AND Z40.COD = Z39_COD "
 _cQry +=  "                          AND Z40.PERIOD = Z39_PERIOD "
 _cQry +=  "                   JOIN SF2010 SF2 "
 _cQry +=  "                       ON     F2_EMISSAO BETWEEN '" + DToS(MV_PAR05) + "' AND '" + DToS(MV_PAR06) + "' " 
 _cQry +=  "                          AND F2_TIPO = 'N' "
 _cQry +=  "                          AND F2_VEND2 = Z40.COORD "
 _cQry +=  "                          AND SF2.D_E_L_E_T_ = ' ' "
 _cQry +=  "                   JOIN SD2010 SD2 "
 _cQry +=  "                       ON     D2_FILIAL = F2_FILIAL "
 _cQry +=  "                          AND D2_DOC = F2_DOC "
 _cQry +=  "                          AND D2_SERIE = F2_SERIE "
 _cQry +=  "                          AND D2_FORMUL = F2_FORMUL "
 _cQry +=  "                          AND D2_COD = Z39_PRODUT "
 _cQry +=  "                          AND SD2.D_E_L_E_T_ = ' ' "
 _cQry +=  "                   JOIN ZAY010 ZAY "
 _cQry +=  "                       ON     ZAY_FILIAL = ' ' "
 _cQry +=  "                          AND ZAY_CF = D2_CF "
 _cQry +=  "                          AND ZAY_TPOPER = 'V' "
 _cQry +=  "                          AND ZAY.D_E_L_E_T_ = ' ' "
 _cQry +=  "          GROUP BY Z38.COD, Z38.TPCALC, Z40.COORD), "
 _cQry +=  "     PEND "
 _cQry +=  "     AS "
 _cQry +=  "         (  SELECT Z38.COD, "
 _cQry +=  "                   Z38.TPCALC, "
 _cQry +=  "                   Z40.COORD, "
 _cQry +=  "                   SUM ( "
 _cQry +=  "                       Case "
 _cQry +=  "                           WHEN Z39_TIPO = 'A' AND Z39_TPCONV = 'M' "
 _cQry +=  "                           THEN "
 _cQry +=  "                               C6_QTDVEN * Z39_FATOR "
 _cQry +=  "                           WHEN Z39_TIPO = 'A' "
 _cQry +=  "                           THEN "
 _cQry +=  "                               C6_QTDVEN / Z39_FATOR "
 _cQry +=  "                           Else "
 _cQry +=  "                               0 "
 _cQry +=  "                       END)    AS PEND_A, "
 _cQry +=  "                   SUM ( "
 _cQry +=  "                       Case "
 _cQry +=  "                           WHEN Z39_TIPO = 'B' AND Z39_TPCONV = 'M' "
 _cQry +=  "                           THEN "
 _cQry +=  "                               C6_QTDVEN * Z39_FATOR "
 _cQry +=  "                           WHEN Z39_TIPO = 'B' "
 _cQry +=  "                           THEN "
 _cQry +=  "                               C6_QTDVEN / Z39_FATOR "
 _cQry +=  "                           Else "
 _cQry +=  "                               0 "
 _cQry +=  "                       END)    AS PEND_B "
 _cQry +=  "              FROM BASE_Z38 Z38 "
 _cQry +=  "                   JOIN Z39010 Z39 "
 _cQry +=  "                       ON     Z39_FILIAL = Z38.FILIAL "
 _cQry +=  "                          AND Z39_COD = Z38.COD "
 _cQry +=  "                          AND Z39_PERIOD = Z38.PERIOD "
 _cQry +=  "                          AND Z39.D_E_L_E_T_ = ' ' "
 _cQry +=  "                   JOIN BASE_Z40 Z40 "
 _cQry +=  "                       ON     Z40.FILIAL = Z39_FILIAL "
 _cQry +=  "                          AND Z40.COD = Z39_COD "
 _cQry +=  "                          AND Z40.PERIOD = Z39_PERIOD "
 _cQry +=  "                   JOIN SC5010 SC5 "
 _cQry +=  "                       ON     C5_TIPO = 'N' "
 _cQry +=  "                          AND C5_NOTA = ' ' "
 _cQry +=  "                          AND C5_VEND2 = Z40.COORD "
 _cQry +=  "                          AND SC5.D_E_L_E_T_ = ' ' "
 _cQry +=  "                   JOIN SC6010 SC6 "
 _cQry +=  "                       ON     C6_FILIAL = C5_FILIAL "
 _cQry +=  "                          AND C6_NUM = C5_NUM "
 _cQry +=  "                          AND C6_PRODUTO = Z39_PRODUT "
 _cQry +=  "                          AND SC6.D_E_L_E_T_ = ' ' "
 _cQry +=  "                   JOIN ZAY010 ZAY "
 _cQry +=  "                       ON     ZAY_FILIAL = ' ' "
 _cQry +=  "                          AND ZAY_CF = C6_CF "
 _cQry +=  "                          AND (ZAY_TPOPER = 'V' OR C5_I_OPER = '42') "
 _cQry +=  "                          AND ZAY.D_E_L_E_T_ = ' ' "
 _cQry +=  "          GROUP BY Z38.COD, Z38.TPCALC, Z40.COORD), "
 _cQry +=  "     UNIFICADO "
 _cQry +=  "     AS "
 _cQry +=  "         (  SELECT B.COD, "
 _cQry +=  "                   B.TPCALC, "
 _cQry +=  "                   B.COORD, "
 _cQry +=  "                   NVL (SUM (F.FAT_A), 0)      AS FAT_A, "
 _cQry +=  "                   NVL (SUM (F.FAT_B), 0)      AS FAT_B, "
 _cQry +=  "                   NVL (SUM (P.PEND_A), 0)     AS PEND_A, "
 _cQry +=  "                   NVL (SUM (P.PEND_B), 0)     AS PEND_B "
 _cQry +=  "              FROM BASE B "
 _cQry +=  "                   LEFT JOIN FAT F "
 _cQry +=  "                       ON     F.COD = B.COD "
 _cQry +=  "                          AND F.TPCALC = B.TPCALC "
 _cQry +=  "                          AND F.COORD = B.COORD "
 _cQry +=  "                   LEFT JOIN PEND P "
 _cQry +=  "                       ON     P.COD = B.COD "
 _cQry +=  "                          AND P.TPCALC = B.TPCALC "
 _cQry +=  "                          AND P.COORD = B.COORD "
 _cQry +=  "          GROUP BY B.COD, B.TPCALC, B.COORD) "
 _cQry +=  "   SELECT COD Z38_COD, TPCALC Z38_TPCALC, COORD  Z40_COORD, FAT_A , FAT_B , PEND_A , PEND_B   "
 _cQry +=  "     FROM UNIFICADO "
 _cQry +=  " ORDER BY COORD, COD "

 MPSysOpenQuery( _cQry,_cAlias )
 DBSelectArea(_cAlias)
 _nTot:=nConta:=0
 Private _nGravados:=0 As Numeric

 If oProc <> Nil .And. !_lScheduler
    COUNT TO _nTot
    _cTot:=AllTrim(Str(_nTot))
    oProc:cCaption:=TIME()+"-Preparando processamento de "+_cTot+" registros."
    ProcessMessages()
    (_cAlias)->(DBCloseArea())
    MPSysOpenQuery( _cQry,_cAlias )
    _cTot:=_cTot+" -"+Time()
 EndIf
 If _nTot = 0 .And. !_lScheduler
     If !_lScheduler
        U_ITMsg("Não foram encontrados registros para esses filtros.",'Atenção!',"Selecione outros filtros.",1) // Cancel
     EndIf
     Return .F.
 EndIf

 aCab:={}
 aAdd(aCab,"")                     //01
 nPos1:=Len(aCab)
 aAdd(aCab,"Cod.Coord.")           //03
 nPosCoo:=Len(aCab)
 aAdd(aCab,"Premissa")             //04
 nPosPre:=Len(aCab)
 aAdd(aCab,"Tipo Calculo")         //05  1=Beta vs Total;2=Beta vs Alfa
 nPospTC:=Len(aCab)
 aAdd(aCab,"Qtde Faturada Alfa")   //06
 nPosQLIA:=Len(aCab)
 aAdd(aCab,"Qtde Faturada Beta")   //07
 nPosQLMB  :=Len(aCab)
 aAdd(aCab,"Qtde Pendente Alfa")   //08
 nPosPQLMA:=Len(aCab)
 aAdd(aCab,"Qtde Pendente Beta")   //09
 nPosPQLIB  :=Len(aCab)
 aAdd(aCab,"Coordenador")          //10
 aAdd(aCab,"Gerente")              //11
 aAdd(aCab,"% Atingimento Fat.")   //12
 nPosAFat :=Len(aCab)
 aAdd(aCab,"% Atingimento Total")  //13
 nPosAtiT :=Len(aCab)
 aAdd(aCab,"Chave Z40")            //14
 nPosCahv :=Len(aCab)
 aAdd(aCab,"Alvo")                 //15
 nPosAlvo :=Len(aCab)
 aAdd(aCab,"Observações ")         //16
 nPosObs  :=Len(aCab)

 While (_cAlias)->(!Eof())
    nConta++
    If oProc <> Nil
       oProc:cCaption:='Quantidade de Registros Lidas: '+AllTrim(Str(nConta))+ " / "+_cTot
       ProcessMessages()
    EndIf
    cGerente:=AllTrim(Posicione("SA3",1,xFilial("SA3")+(_cAlias)->Z40_COORD,"A3_GEREN"))
    If !Empty( MV_PAR01 )
       If Len(AllTrim(MV_PAR01)) = 6
          If cGerente <> AllTrim(MV_PAR01) 
             (_cAlias)->(DBSkip())
             Loop
          EndIf
       Else
          If !cGerente $ AllTrim(MV_PAR01) 
             (_cAlias)->(DBSkip())
             Loop
          EndIf
       EndIf
    EndIf

    cNome    := AllTrim(SA3->A3_NOME)+If(SA3->A3_MSBLQL="1"," (Inativo)","")//NOME DO CORODENADOR
    cGerente := cGerente+"-"+AllTrim(Posicione("SA3",1,xFilial("SA3")+cGerente,"A3_NOME"))//CUIDADO ESTA POSICIONADO NO GETENTE
    _nPercFat:= 0
    _nPercTot:= 0
    If (_cAlias)->Z38_TPCALC = "1"
       _nPercFat:=Round( ( ((_cAlias)->FAT_B / ((_cAlias)->FAT_B  + (_cAlias)->FAT_A )) *100 ) ,2)//Percentual Acumulado ? (( Qtd Leite Magro / ( QtdLeiteMago + QtdLeiteIntegral) ) * 100 )
       _nPercTot:=Round( ( ( ((_cAlias)->FAT_B+(_cAlias)->PEND_B)/ (((_cAlias)->FAT_B+(_cAlias)->PEND_B) + ((_cAlias)->FAT_A+(_cAlias)->PEND_A))) *100 ) ,2)//Percentual Acumulado ? (( Qtd Leite Magro / ( QtdLeiteMago + QtdLeiteIntegral) ) * 100 )
    ElseIf (_cAlias)->Z38_TPCALC = "2"
       _nPercFat:=Round( ( ((_cAlias)->FAT_B / ( (_cAlias)->FAT_A )) *100 ) ,2)//Percentual Acumulado ? (( Qtd Leite Magro / (QtdLeiteIntegral) ) * 100 )
       _nPercTot:=Round( ( (((_cAlias)->FAT_B+(_cAlias)->PEND_B) / ((_cAlias)->FAT_A+(_cAlias)->PEND_A)) *100 ) ,2)//Percentual Acumulado ? (( Qtd Leite Magro / (QtdLeiteIntegral) ) * 100 )
    EndIf
    If !Empty((_cAlias)->FAT_B) .And. Empty((_cAlias)->FAT_A)//SE SÓ TIVER BETA É 100%
       _nPercFat:=100//Faturamento
    EndIf
    If !Empty((_cAlias)->FAT_B+(_cAlias)->PEND_B) .And. Empty((_cAlias)->FAT_A+(_cAlias)->PEND_A)//SE SÓ TIVER BETA É 100%
       _nPercTot:=100//Pendente+Faturamento
    EndIf

    _aItens:={}
    aAdd(_aItens,.T.)                   //01 - Pronto para gravar ou Gravado com sucesso
    aAdd(_aItens,(_cAlias)->Z40_COORD)  //02 - nPosCoo - CODIGO DO COORDENADOR
    aAdd(_aItens,(_cAlias)->Z38_COD)    //03 - nPosPre
    aAdd(_aItens,If((_cAlias)->Z38_TPCALC="1","1-Beta vs Total","2-Beta vs Alfa")) //05 - nPospTC - //06  1=Beta vs Total;2=Beta vs Alfa
    aAdd(_aItens,(_cAlias)->FAT_A )     //05 - ALFA / INTEGRAL - nPosQLIA
    aAdd(_aItens,(_cAlias)->FAT_B )     //06 - BETA / MAGRO    - nPosQLMB
    aAdd(_aItens,(_cAlias)->PEND_A)     //07 - ALFA / INTEGRAL - nPosPQLMA
    aAdd(_aItens,(_cAlias)->PEND_B)     //08 - BETA / MAGRO    - nPosPQLIB
    aAdd(_aItens,cNome)                 //10 - NOME DO COORDENADOR
    aAdd(_aItens,cGerente)              //11 - CODIGO + NOME DO GERENTE
    aAdd(_aItens,_nPercFat)             //12 - % Atingimento Fat.
    aAdd(_aItens,_nPercTot)             //13 - % Atingimento Total (Pendente+Faturamento)
    aAdd(_aItens,xFilial("Z40")+(_cAlias)->Z38_COD+LEFT(DToS(_dDataDia),6)+(_cAlias)->Z40_COORD )//14 - Z40_FILIAL+Z40_COD+Z40_PERIOD+Z40_COORD
    aAdd(_aItens,0)                     //15 - Alvo    
    aAdd(_aItens,"Pronto para gravar.") //16 - Observações
    aAdd(aLog,_aItens)
    
    (_cAlias)->(DBSkip())
 
 EndDo

 (_cAlias)->(DBCloseArea())

 If oProc <> NIL  .And. !_lScheduler
    If Len(aLog) > 0

       _cPictPerc:= "@E 999,999.99"
       _cPictQtde:= "@E 999,999,999,999.999"

       _aDados:=AClone(aLog)//FORMATO CORRETO PARA GERAR O EXCEL EM INGLES COM PONTO PARA DECIMAIS

       For L := 1 TO Len(_aDados)//AJUSTE PARA MOSTRAR NA TELA DO U_ITListBox() OS NUMEROS EM PORTUGUES
           _aDados[L,nPosAtiT ]:= TRANSFORM(_aDados[L,nPosAtiT ],_cPictPerc)
           _aDados[L,nPosAFat ]:= TRANSFORM(_aDados[L,nPosAFat ],_cPictPerc)
           _aDados[L,nPosAlvo ]:= TRANSFORM(_aDados[L,nPosAlvo ],_cPictPerc)
           _aDados[L,nPosQLIA ]:= TRANSFORM(_aDados[L,nPosQLIA ],_cPictQtde)
           _aDados[L,nPosQLMB ]:= TRANSFORM(_aDados[L,nPosQLMB ],_cPictQtde)
           _aDados[L,nPosPQLIB]:= TRANSFORM(_aDados[L,nPosPQLIB],_cPictQtde)
           _aDados[L,nPosPQLMA]:= TRANSFORM(_aDados[L,nPosPQLMA],_cPictQtde)
       Next

       _cMsgTop := "Resultado do processamento, - Periodo de "+DToC(_dDtIni)+" até "+DToC(_dDataDia)+" / Execucao:  Data "+DToC(DATE())+" Hr Ini: "+cTimeInicial+" Hr final "+Time()
       _cTitAux := _cMsgTop
       
       While .T.
          //         ITListBox( _cTitAux , _aHeader , _aCols , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda,_lHasOk,_bHeadClk,_aSX1,_lComCab)
          _lRet := U_ITListBox( _cTitAux , aCab     , _aDados, .T.      , 4      , _cMsgTop ,          ,         ,         ,     ,        ,          ,       ,         , aLog     ,           ,         ,       ,         ,     ,        )

          If !_lRet .And. U_ITMsg("Confirma SAIDA?","Gravação do Z40","Todos os dados serão perdidos.",3,2,2)

             Exit

          ElseIf U_ITMsg("Confirma gravação dos dados?","Gravação do Z40",,3,2,2)

             FWMsgRun( ,{|oProc|  _lRet := MOMS73Grv(oProc,aLog) } , "Hora Inicial: "+Time()+" Gravando Dados... " )

              _aDados:=AClone(aLog)//FORMATO CORRETO PARA GERAR O EXCEL EM INGLES COM PONTO PARA DECIMAIS
              For L := 1 TO Len(_aDados)//AJUSTE PARA MOSTRAR NA TELA DO U_ITListBox() OS NUMEROS EM PORTUGUES
                  _aDados[L,nPosAtiT ]:= TRANSFORM(_aDados[L,nPosAtiT ],_cPictPerc)
                  _aDados[L,nPosAFat ]:= TRANSFORM(_aDados[L,nPosAFat ],_cPictPerc)
                  _aDados[L,nPosAlvo ]:= TRANSFORM(_aDados[L,nPosAlvo ],_cPictPerc)
                  _aDados[L,nPosQLIA ]:= TRANSFORM(_aDados[L,nPosQLIA ],_cPictQtde)
                  _aDados[L,nPosQLMB ]:= TRANSFORM(_aDados[L,nPosQLMB ],_cPictQtde)
                  _aDados[L,nPosPQLIB]:= TRANSFORM(_aDados[L,nPosPQLIB],_cPictQtde)
                  _aDados[L,nPosPQLMA]:= TRANSFORM(_aDados[L,nPosPQLMA],_cPictQtde)
              Next

             _cMsgTop := "Resultado do Gravacao: "+AllTrim(Str(_nGravados))+ " GRAVADOS e "+AllTrim(Str(Len(aLog)-_nGravados))+" não gravados. Periodo de "+DToC(_dDtIni)+" até "+DToC(_dDataDia)+" / Execucao:  Data "+DToC(DATE())+" Hr Ini: "+cTimeInicial+" Hr final "+Time()
             _cTitAux := _cMsgTop

             //ITListBox( _cTitAux , _aHeader , _aCols , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda,_lHasOk,_bHeadClk,_aSX1,_lComCab)
             U_ITListBox( _cTitAux , aCab     , _aDados, .T.      , 4      , _cMsgTop ,          ,         ,         ,     ,        ,          ,       ,         , aLog     ,           ,         ,       ,         ,     ,        )

             Exit

          Else
             Loop
          EndIf
       EndDo
    EndIf
 Else
    If Len(aLog) > 0
       MOMS73Grv(,aLog)
       _cMsgTop := "Resultado do Gravacao: "+AllTrim(Str(_nGravados))+ " GRAVADOS e "+AllTrim(Str(Len(aLog)-_nGravados))+" não gravados. Periodo de "+DToC(_dDtIni)+" até "+DToC(_dDataDia)+" / Execucao:  Data "+DToC(DATE())+" Hr Ini: "+cTimeInicial+" Hr final "+Time()
    EndIf
 EndIf

Return _lRet

/*
===============================================================================================================================
Programa----------: MOMS73Grv
Autor-------------: Alex Wallauer
Data da Criacao---: 06/03/2025
Descrição---------: Gravaçã dos dados do SA3
Parametros--------: oProc As Object
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function MOMS73Grv(oProc As Object,aLog As Array) As Logical

 Local _nI:=0 As Numeric
 Local _nDeci1:=Getsx3cache("Z40_ATING","X3_DECIMAL")+1//"99999.99"
 Local _nTamI1:=Getsx3cache("Z40_ATING","X3_TAMANHO")-_nDeci1//"99999.99"
 Local _nDeci2:=Getsx3cache("Z40_ATINF","X3_DECIMAL")+1//"99999.99"
 Local _nTamI2:=Getsx3cache("Z40_ATINF","X3_TAMANHO")-_nDeci2//"99999.99"
 Local _cGrvdat:= Date()
 Local _cGrvhor:= Time()

 Z40->(DBSetOrder(1))
 For _nI := 1 To Len( aLog )
    If oProc <> Nil
       oProc:cCaption:='Gravando Registro: '+AllTrim(Str(_nI))+" / "+AllTrim(Str(Len(aLog)))
       ProcessMessages()
    EndIf
    If aLog[_nI][nPos1]
       If Z40->(DBSeek( aLog[_nI][nPosCahv] )) 
          aLog[_nI][nPosObs] :="Gravado com sucesso."
          aLog[_nI][nPos1]   := .T.
          Z40->(RecLock("Z40",.F.))
          If aLog[_nI][nPosAtiT] <= Val(Replicate("9",_nTamI1))
             Z40->Z40_ATING := aLog[_nI][nPosAtiT]
          Else
             Z40->Z40_ATING    := Val(Replicate("9",_nTamI1))+0.99
             aLog[_nI][nPosObs]:= "Gravado com 99.999,99."
             aLog[_nI][nPos1]  := .F.
          EndIf
          If aLog[_nI][nPosAFat] <= Val(Replicate("9",_nTamI2))
             Z40->Z40_ATINF := aLog[_nI][nPosAFat]
          Else
             Z40->Z40_ATINF    := Val(Replicate("9",_nTamI2))+0.99
             aLog[_nI][nPosObs]:= "Gravado com 99.999,99."
             aLog[_nI][nPos1]  := .F.
          EndIf
          If Z40->(FieldPos("Z40_FAT_A")) > 0
             Z40->Z40_FAT_A := aLog[_nI][nPosQLIA ]
             Z40->Z40_FAT_B := aLog[_nI][nPosQLMB ]
             Z40->Z40_PEND_A:= aLog[_nI][nPosPQLMA]
             Z40->Z40_PEND_B:= aLog[_nI][nPosPQLIB]
             Z40->Z40_GRVDAT:= _cGrvdat
             Z40->Z40_GRVHOR:= _cGrvhor
             If _lScheduler
                Z40->Z40_GRVUSU:= "Gravado por Schedule"
             Else
                Z40->Z40_GRVUSU:= Capital(AllTrim(UsrFullName(RetCodUsr())))+" da Filial "+cFilAnt
             EndIf
          EndIf
          Z40->(MSUnLock())
          aLog[_nI][nPosAlvo]:=Z40->Z40_ALVO  
          _nGravados++
       Else
          aLog[_nI][nPosObs]:="Chave ["+aLog[_nI][nPosCahv]+"] não encontrada."
          aLog[_nI][nPos1]  := .F.
       EndIf
    EndIf
 Next _nI

Return .T.

/*
===============================================================================================================================
Programa----------: SchedDef
Autor-------------: Alex Wallauer
Data da Criacao---: 06/03/2025
Descrição---------: DefiniçStaticStatic Function SchedDef para o novo Schedule
Uso---------------: No novo Schedule existe uma forma para a definição dos Perguntes para o botão Parâmetros, além do cadastro
                    das funções no SXD. Ao definir em sua rotinStaticatic Function SchedDef(), no cadastro da rotina no Agenda-
                    mento do Schedule será verificado se existe estStaticic Function e irá executá-la habilitando o botão Parâ-
                    metros com as informações do retorno da SchedDef(), deixando de verificar assim as informações na SXD. O
                    retorno da SchedDef deverá ser um array.
                    Válido para Function e User Function, lembrando que uma vez definido a SchedDef, ao chamar a rotina o ambi-
                    ente já está inicializado.
                    Uma vez definido a Static Function SchedDef(), a rotina deixa de ser uma execução como processo especial,
                    ou seja, não se deve cadastrá-la no Agendamento passando parâmetros de linha. Ex: Funcao("A","B") ou
                    U_Funcao("A","B").
Parametros--------: aReturn[1] - Tipo: "P" - para Processo, "R" -  para Relatórios
                    aReturn[2] - Nome do Pergunte, caso nao use passar ParamDef
                    aReturn[3] - Alias  (para Relatório)
                    aReturn[4] - Array de ordem  (para Relatório)
                    aReturn[5] - Título (para Relatório)
Retorno-----------: aParam
===============================================================================================================================
*/
Static Function SchedDef()

Local aParam  := {}
Local aOrd := {}

aParam := { "P",;
            "PARAMDEFF",;
            "",;
            aOrd,;
            }

Return aParam
