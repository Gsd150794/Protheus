/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |02/06/2020| Chamado 33115. Correção da query para tabela ZZI
Lucas Borges  |07/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RCOM017
Autor-------------: Alex Wallauer
Data da Criacao---: 12/05/2020
Descrição---------: Relatório de Acompanhamento de Compras em Aberto - CHAMADO 32575
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM017()
Local _aParRet :={}
Local _aParAux :={}  , nI
Local _bOK     :={|| If(MV_PAR02 >= MV_PAR01 .Or. MV_PAR02 > DATE(),.T.,(U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo ate a data de hoje",3),.F.) ) }

_bSelectSC1:={|| U_MontaSC1Select() }
_cSelectSB1:="SELECT B1_COD , B1_TIPO, B1_DESC FROM "+RETSQLNAME("SB1")+" SB1 WHERE D_E_L_E_T_ = ' ' AND B1_MSBLQL = '2' ORDER BY B1_COD "

_cSelecSZZ7 :="SELECT ZZ7_CODUSR, ZZ7_NOME FROM "+RETSQLNAME("ZZ7")+" ZZ7 WHERE ZZ7_TIPO  = 'S' AND ZZ7_STATUS <> 'B' AND D_E_L_E_T_ = ' ' AND ZZ7_FILIAL = '"+xFilial("ZZ7")+"' ORDER BY ZZ7_NOME " 
_cSelecAZZ7 :="SELECT ZZ7_CODUSR, ZZ7_NOME FROM "+RETSQLNAME("ZZ7")+" ZZ7 WHERE ZZ7_TIPO  = 'A' AND ZZ7_STATUS <> 'B' AND D_E_L_E_T_ = ' ' AND ZZ7_FILIAL = '"+xFilial("ZZ7")+"' ORDER BY ZZ7_NOME " 

_aItalac_F3:={}//       1           2         3                      4                      5               6                    7         8          9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela ,_nCpoChave              , _nCpoDesc              ,_bCondTab    , _cTitAux         , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR04" ,_cSelecSZZ7,{|Tab|(Tab)->ZZ7_CODUSR},{|Tab|(Tab)->ZZ7_NOME},               ,"Solicitantes"    ,          ,          ,20        ,.F.        ,       , } )
aAdd(_aItalac_F3,{"MV_PAR05" ,_cSelecAZZ7,{|Tab|(Tab)->ZZ7_CODUSR},{|Tab|(Tab)->ZZ7_NOME},               ,"Aprovadores"     ,          ,          ,20        ,.F.        ,       , } )
aAdd(_aItalac_F3,{"MV_PAR06" ,"SY1"      ,                        ,                      ,               ,"Compradores"     ,} )
aAdd(_aItalac_F3,{"MV_PAR07" ,_bSelectSC1,{|Tab| (Tab)->C1_NUM }, {|Tab|DToC(SToD((Tab)->C1_EMISSAO))},  ,"Solicitacoes"    ,          ,          ,60        ,.T.        ,       , } )
aAdd(_aItalac_F3,{"MV_PAR08" ,_cSelectSB1,{|Tab|(Tab)->B1_COD},{|Tab|(Tab)->B1_TIPO+" "+(Tab)->B1_DESC}, ,"Produtos"        ,          ,          ,20        ,.F.        ,       , } )

_aOpcoes:={}
aAdd( _aOpcoes , "1-Consumo     ")
aAdd( _aOpcoes , "2-Investimento")
aAdd( _aOpcoes , "3-Manutenção  ")
aAdd( _aOpcoes , "4-Serviço     ") 
aAdd( _aOpcoes , "5-Todas       ") 

MV_PAR01:=dDataBase
MV_PAR02:=dDataBase
MV_PAR03:=Space(200)
MV_PAR04:=Space(200)
MV_PAR05:=Space(200)
MV_PAR06:=Space(200)
MV_PAR07:=Space(200)
MV_PAR08:=Space(200)
MV_PAR09:="Todos"
MV_PAR10:=_aOpcoes[5]

//01-DATA:	    c1_emissao
//02-DATA:	    c1_emissao
//03-FILIAL:	    c1_filial	
//04-SOLICITANTE:c1_solicit	// ZZ7
//05-APROVADOR:	 c1_i_codap // ZZ7
//06-COMPRADOR:	 c1_codcomp // SY1
//07-NUMERO SC:	 c1_num	   // SC1
//08-PRODUTO:	 c1_produto	// SB1
//09-USO DIRETO (S/N): c1_i_usod SIM NA0
//10-APLICAÇÃO:	 c1_i_aplic 
aAdd( _aParAux , { 1 , "Data de"	      , MV_PAR01, "@D"	, ""  , ""	   , "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Data ate"         , MV_PAR02, "@D"	, ""  , ""	   , "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Filial"           , MV_PAR03, "@!"  , ""  ,"LSTFIL", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Solicitantes"     , MV_PAR04, "@!"  , ""  ,"F3ITLC", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Aprovadores"      , MV_PAR05, "@!"  , ""  ,"F3ITLC", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Compradores"      , MV_PAR06, "@!"  , ""  ,"F3ITLC", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Numero SC"        , MV_PAR07, "@!"  , ""  ,"F3ITLC", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Produtos"         , MV_PAR08, "@!"  , ""  ,"F3ITLC", "" , 100 , .F. } ) 
aAdd( _aParAux , { 2 , "Uso Direto"       , MV_PAR09, {"1-Sim  ","2-Nao  ","Todos"}, 090 ,".T.", .T. } )
aAdd( _aParAux , { 2 , "Aplicacao"        , MV_PAR10, _aOpcoes                  , 090 ,".T.", .T. } )

For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next nI
          //aParametros, cTitle                                , @aRet    ,[bOk], [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
If !ParamBox( _aParAux , "Acompanhamento de Compras em Aberto" , @_aParRet, _bOK, /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
    Return .F.
EndIf

U_ITLOGACS( " RCOM017" )

cTimeInicial:=Time()

FWMsgRun( ,{|oProc|   RCOM017R(oProc) } , "SC - Hora Inicial: "+cTimeInicial+", Aguarde...",  )

Return

/*
===============================================================================================================================
Programa----------: RCOM017R
Autor-------------: Alex Wallauer
Data da Criacao---: 25/04/2019
Descrição---------: Função que imprime o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function  RCOM017R(oProc)
Local cQry1		:= ""
Local _cAlias  := GetNextAlias()

   
   oProc:cCaption :=  "Selelecionado SCs, Aguarde... "
   ProcessMessages()

////                 FILIAL  ; NUMERO SC; ITEM SC ; COD PROD; DESCRIÇÃO; U.M.; QUANT SC; QUANT ENTREG; 2A. U.M.; QUANT 2A. U.M.; DT ENTREGA SC; OBS      ; DT EMISSAO   ; SOLICITANTE; STATUS APROV ; URGENTE? ; APROVADOR  ; DT APROVAï¿½ï¿½O; COMPRADOR                               ; APLICAï¿½ï¿½O ; OBS APROV  ; USO DIRETO?; NUM PEDIDO                         ; QUANT PC                                ; QUANT ENTREG PC                      ; RESIDUO PC                                      ; PC ENCERRADO?                             ; COD APROVACAO PC                                ;STATUS
   cQry1 += " SELECT SC.FILIAL, SC.NUMSC, SC.ITEMSC, SC.PRD, SC.DESCR , SC.UM, SC.QUANT, SC.QUJESC   , SC.SEGUM, SC.QTSEGUMSC   , SC.ENTREG_SC, SC.OBS_SC, SC.EMISSAO_SC, SC.SOLICIT , SC.APROV_STAT, SC.URGENT, SC.APROV_SC, SC.DT_APRV  ,  NVL2(SC.COMPRAD,SC.COMPRAD,' ') COMPRAD, SC.APLIC , SC.OBS_APROV, SC.USOD   , NVL2(C7.C7_NUM,C7.C7_NUM,' ') C7_NUM, NVL2(C7.C7_QUANT,C7.C7_QUANT,0) C7_QUANT, NVL2(C7.C7_QUJE,C7.C7_QUJE,0) C7_QUJE, NVL2(C7.C7_RESIDUO,C7.C7_RESIDUO,' ') C7_RESIDUO, NVL2(C7.C7_ENCER,C7.C7_ENCER,' ') C7_ENCER,NVL2(C7.C7_CONAPRO,C7.C7_CONAPRO,' ') C7_CONAPRO, SC.C1_I_CDINV," 
   cQry1 += " (SELECT ZZI_DESINV FROM " + RetSqlName("ZZI") + " ZZI WHERE SC.FILIAL= ZZI_FILIAL  AND SC.C1_I_CDINV = ZZI.ZZI_CODINV AND ZZI.D_E_L_E_T_ <> '*') ZZI_DESINV "
   cQry1 += " FROM ("
   cQry1 += " SELECT C1.C1_FILIAL FILIAL , C1.C1_NUM NUMSC, C1.C1_ITEM ITEMSC, C1.C1_PRODUTO PRD, C1.C1_DESCRI DESCR, C1.C1_UM UM, C1.C1_QUANT QUANT, C1.C1_QUJE QUJESC, C1.C1_SEGUM SEGUM, C1.C1_QTSEGUM QTSEGUMSC, "
   cQry1 += "  C1.ENTREGA_SC ENTREG_SC, C1.C1_OBS OBS_SC, C1.EMISSAO EMISSAO_SC, C1.C1_SOLICIT SOLICIT, C1.C1_APROV APROV_STAT, C1.C1_I_URGEN URGENT, "
   cQry1 += "  C1.ZZ7_NOME APROV_SC, C1.C1_I_DTAPR DT_APRV, Y.Y1_NOME COMPRAD, C1.C1_I_APLIC APLIC, C1.C1_I_OBSAP OBS_APROV, C1.C1_I_USOD USOD , C1.C1_I_CDINV "//, C1.ZZI_DESINV   "
   cQry1 += " FROM ("
   cQry1 += " SELECT C1_FILIAL, C1_NUM, C1_ITEM, C1_PRODUTO, C1_DESCRI, C1_UM, C1_QUANT, C1_QUJE, C1_SEGUM, C1_QTSEGUM, "
   cQry1 += "  C1_DATPRF ENTREGA_SC, C1_OBS, C1_EMISSAO EMISSAO, C1_SOLICIT, C1_APROV, C1_I_URGEN, "
   cQry1 += "  ZZ7_NOME, C1_I_DTAPR, C1_CODCOMP, C1_I_APLIC, C1_I_OBSAP, C1_I_USOD , C1_I_CDINV"
   cQry1 += " FROM  " + RetSqlName("SC1") + " SC1 JOIN " + RetSqlName("ZZ7") + " ZZ7 ON C1_FILIAL = ZZ7_FILIAL AND C1_I_CODAP = ZZ7_CODUSR "
   cQry1 += "  WHERE  SC1.D_E_L_E_T_ = ' ' AND  ZZ7.D_E_L_E_T_ = ' ' "
   cQry1 += "  AND C1_RESIDUO <> 'S' "

   If !Empty(MV_PAR02)
      cQry1 += " AND C1_EMISSAO BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "' "
   ElseIf !Empty(MV_PAR01)
      cQry1 += " AND C1_EMISSAO >= '" + DToS(MV_PAR01) + "' "
   EndIf   

   If !Empty(MV_PAR03)
       cQry1 += " AND C1_FILIAL IN "+FormatIn(AllTrim(MV_PAR03),";")
   Else
       cQry1 += " AND C1_FILIAL = '"+xFilial("SC1")+"'"
   End If
//SOLICITANTES
   If !Empty(MV_PAR04)
       cQry1 += "AND C1_I_CDSOL IN "+FormatIn(AllTrim(MV_PAR04),";")
   EndIf
//APROVADORES
   If !Empty(MV_PAR05)
       cQry1 += "AND C1_I_CODAP IN "+FormatIn(AllTrim(MV_PAR05),";")
   EndIf

   //Filtra comprador
   If !Empty(MV_PAR06)
   	   cQry1 += " AND C1_CODCOMP  IN "+FormatIn(AllTrim(MV_PAR06),";")
   EndIf     
   
   //Filtra SC
   If !Empty(MV_PAR07)
   	   cQry1 += " AND C1_NUM IN "+FormatIn(AllTrim(MV_PAR07),";")
   EndIf 

   //Filtra PRODUTO
   If !Empty(MV_PAR08)
   	   cQry1 += " AND C1_PRODUTO IN "+FormatIn(AllTrim(MV_PAR08),";")
   EndIf 

   //Filtra APLICACAO
   If MV_PAR10 = "1"				//Consumo
   	  cQry1 += " AND C1_I_APLIC = 'C' "
   ElseIf MV_PAR10 = "2"		//Investimento
   	  cQry1 += " AND C1_I_APLIC = 'I' "
   ElseIf MV_PAR10 = "3"			//Manutenção
   	  cQry1 += " AND C1_I_APLIC = 'M' "
   ElseIf MV_PAR10 = "4"		//Serviço
   	  cQry1 += " AND C1_I_APLIC = 'S' "
   ElseIf MV_PAR10 = "5"			//Todos
   	  cQry1 += " AND C1_I_APLIC <> ' ' "
   EndIf
    
    //Uso Direto
   If MV_PAR09 = "1"
   	  cQry1 += " AND C1_I_USOD = 'S' "
   ElseIf MV_PAR09 = "2"
   	  cQry1 += " AND C1_I_USOD = 'N' "
   EndIf
   
   cQry1 += "  ORDER BY C1_FILIAL, C1_NUM, C1_ITEM ) C1 "
   cQry1 += "  LEFT JOIN ( "
   cQry1 += "  SELECT Y1_COD, Y1_NOME FROM  " + RetSqlName("SY1") + " "
   cQry1 += "  WHERE  D_E_L_E_T_ = ' ' "
   cQry1 += "         AND Y1_MSBLQL = '2' ORDER BY Y1_COD ) Y "
   cQry1 += "         ON Y.Y1_COD = C1.C1_CODCOMP ) SC "
   cQry1 += " LEFT JOIN (SELECT C7_FILIAL, C7_NUM, C7_ITEM, C7_QUANT, C7_QUJE, C7_RESIDUO, C7_ENCER, "
   cQry1 += " C7_CONAPRO, C7_NUMSC, C7_ITEMSC FROM  " + RetSqlName("SC7") + " SC7"
   cQry1 += " WHERE  SC7.D_E_L_E_T_ = ' ' "
   cQry1 += " AND C7_NUMSC <> ' ') C7 "
   cQry1 += " ON SC.FILIAL = C7.C7_FILIAL AND SC.NUMSC = C7.C7_NUMSC AND SC.ITEMSC = C7.C7_ITEMSC "
   cQry1 += " ORDER BY SC.FILIAL, SC.NUMSC , SC.ITEMSC"
   cQry1 := ChangeQuery(cQry1)

//crio o novo alias
MPSysOpenQuery( cQry1, _cAlias ) 

nTotal:=nConta:=0
DBSelectArea(_cAlias)
COUNT TO nTotal
(_cAlias)->(DBGoTop())
_aDados:={}
nTotal:=AllTrim(Str(nTotal))
nTam:=Len(nTotal)+1
SCR->(DBSetOrder(1))

While !(_cAlias)->(Eof())

   nConta++
   oProc:cCaption :=  "Lendo "+StrZero(nConta,nTam)+" de "+nTotal +" - Lendo SC " +(_cAlias)->NUMSC
   ProcessMessages()
   
   _cObs:=""
   If (_cAlias)->QUJESC = 0 .And. Empty((_cAlias)->C7_NUM)
      If (_cAlias)->APROV_STAT = "L"
          _cObs:="SC APROVADA DIA "+DToC(SToD((_cAlias)->DT_APRV))+","+If( !Empty( (_cAlias)->COMPRAD ) ," PARADA COM COMPRADOR "+(_cAlias)->COMPRAD ," AGUARDANDO COMPRAS INDICAR COMPRADOR" )
      ElseIf (_cAlias)->APROV_STAT = "R"
          _cObs:="SC REJEITADA, ELIMINAR RESIDUO DA SC PARA ESTE ITEM"
      ElseIf (_cAlias)->APROV_STAT = "B"
          _cObs:="SC BLOQUEADA, AGUARDANDO APROVAÇÃO"
      EndIf
   
   ElseIf (_cAlias)->QUJESC > 0 .And. (_cAlias)->QUJESC < (_cAlias)->QUANT
      If (_cAlias)->C7_RESIDUO = "S" .Or. (_cAlias)->C7_ENCER = "E" .And. (_cAlias)->C7_QUJE = 0
         _cObs:="COMPRA NÃO REALIZADA. VERIFICAR COMPLEMENTO DE COMPRA OU ELIMINAR RESIDUO"
      ElseIf (_cAlias)->C7_RESIDUO = "S" .Or. (_cAlias)->C7_ENCER = "E" .And. (_cAlias)->C7_QUJE > 0 
         _cObs:="ITEM SC ATENDIDO PARCIALMENTE. VERIFICAR COMPLEMENTO DE COMPRA OU ELIMINAR RESIDUO"
      ElseIf (_cAlias)->C7_RESIDUO <> "S" .And. (_cAlias)->C7_ENCER <> "E" .And. (_cAlias)->C7_QUJE > 0 .And. (_cAlias)->C7_QUJE < (_cAlias)->C7_QUANT 
         _cObs:="ENTREGA PARCIAL REALIZADA. AGUARDANDO CHEGADA RESTANTE PARA ESTE ITEM DA SC, VERIFICAR SE COMPLEMENTO DA COMPRA OU ELIMINE RESIDUO DO PC E SC"
      ElseIf (_cAlias)->C7_RESIDUO <> "S" .And. (_cAlias)->C7_ENCER <> "E" .And. (_cAlias)->C7_QUJE = 0 
         _cObs:="AGUARDANDO CHEGADA PARCIAL PARA ESTE ITEM DA SC, VERIFICAR SE COMPLEMENTO DA COMPRA"
      EndIf
   
   ElseIf (_cAlias)->QUJESC <= (_cAlias)->QUANT  //3 - C1_QUJE > = C1_QUANT (P/T/A = "T") "SC ATENDIDA TOTALMENTE EM PC"
      //3A
      If (_cAlias)->C7_RESIDUO <> "S" .And. (_cAlias)->C7_ENCER <> "E" .And. (_cAlias)->C7_CONAPRO = "L"
         _cObs:="AGUARDANDO CHEGADA DO MATERIAL OU ELIMINE RESIDUO DO P.C. E DA S.C."
      //3B
      ElseIf (_cAlias)->C7_RESIDUO <> "S" .And. (_cAlias)->C7_ENCER <> "E" .And. (_cAlias)->C7_CONAPRO= "B"
         _cObs:="AGUARDANDO APROVAÇÃO DO P.C."
      //3C
      ElseIf (_cAlias)->C7_RESIDUO = "S" .And. (_cAlias)->C7_ENCER <> "E" .And. (_cAlias)->C7_CONAPRO= "B"
         _cObs:="PEDIDO BLOQUEADO FOI ENCERRADO. ELIMINE RESIDUO DA SC."
      //3C1
      ElseIf (_cAlias)->C7_RESIDUO <> "S" .And. (_cAlias)->C7_ENCER = "E" .And. (_cAlias)->C7_CONAPRO= "B"
         _cObs:="PEDIDO BLOQUEADO FOI ENCERRADO. ELIMINE RESIDUO DA SC."
      //3C2
      ElseIf (_cAlias)->C7_RESIDUO = "S" .And. (_cAlias)->C7_ENCER = "E" .And. (_cAlias)->C7_CONAPRO= "B"
         _cObs:="PEDIDO BLOQUEADO FOI ENCERRADO. ELIMINE RESIDUO DA SC."
      //3D
      ElseIf (_cAlias)->C7_RESIDUO = "S" .And. (_cAlias)->C7_ENCER <> "E" .And. (_cAlias)->C7_CONAPRO= "L" .And. (_cAlias)->C7_QUJE >= (_cAlias)->C7_QUANT
         _cObs:="COMPRA ATENDIDA. MATERIAL CHEGOU A ITALAC"
      //3D1
      ElseIf (_cAlias)->C7_RESIDUO <> "S" .And. (_cAlias)->C7_ENCER = "E" .And. (_cAlias)->C7_CONAPRO= "L" .And. (_cAlias)->C7_QUJE >= (_cAlias)->C7_QUANT
         _cObs:="COMPRA ATENDIDA. MATERIAL CHEGOU A ITALAC"
      //3D2
      ElseIf (_cAlias)->C7_RESIDUO = "S" .And. (_cAlias)->C7_ENCER = "E" .And. (_cAlias)->C7_CONAPRO= "L" .And. (_cAlias)->C7_QUJE >= (_cAlias)->C7_QUANT
         _cObs:="COMPRA ATENDIDA. MATERIAL CHEGOU A ITALAC"
      //3E
      ElseIf (_cAlias)->C7_RESIDUO = "S" .And. (_cAlias)->C7_ENCER <> "E" .And. (_cAlias)->C7_CONAPRO= "L" .And. (_cAlias)->C7_QUJE < (_cAlias)->C7_QUANT .And. (_cAlias)->C7_QUJE > 0
         _cObs:="COMPRA PARCIALMENTE ATENDIDA. PC ENCERRADO. VERIICAR COMPLEMTO DE COMPRA OU ELIMINAR RESIDUO DA SC"
      //3E1
      ElseIf (_cAlias)->C7_RESIDUO <> "S" .And. (_cAlias)->C7_ENCER = "E" .And. (_cAlias)->C7_CONAPRO= "L" .And. (_cAlias)->C7_QUJE < (_cAlias)->C7_QUANT .And. (_cAlias)->C7_QUJE > 0
         _cObs:="COMPRA PARCIALMENTE ATENDIDA. PC ENCERRADO. VERIICAR COMPLEMTO DE COMPRA OU ELIMINAR RESIDUO DA SC"
      //3E2
      ElseIf (_cAlias)->C7_RESIDUO = "S" .And. (_cAlias)->C7_ENCER = "E" .And. (_cAlias)->C7_CONAPRO= "L" .And. (_cAlias)->C7_QUJE < (_cAlias)->C7_QUANT .And. (_cAlias)->C7_QUJE > 0
         _cObs:="COMPRA PARCIALMENTE ATENDIDA. PC ENCERRADO. VERIICAR COMPLEMTO DE COMPRA OU ELIMINAR RESIDUO DA SC"
      //3F
      ElseIf (_cAlias)->C7_RESIDUO  = "S" .And. (_cAlias)->C7_ENCER <> "E" .And. (_cAlias)->C7_CONAPRO= "L" .And. (_cAlias)->C7_QUJE = 0
         _cObs:="COMPRA NÃO REALIZADA. VERIFICAR COMPLEMENTO DE COMPRA OU ELIMINAR RESIDUO"
      //3F1
      ElseIf (_cAlias)->C7_RESIDUO <> "S" .And. (_cAlias)->C7_ENCER  = "E" .And. (_cAlias)->C7_CONAPRO= "L" .And. (_cAlias)->C7_QUJE = 0
         _cObs:="COMPRA NÃO REALIZADA. VERIFICAR COMPLEMENTO DE COMPRA OU ELIMINAR RESIDUO"
      //3F2
      ElseIf (_cAlias)->C7_RESIDUO  = "S" .And. (_cAlias)->C7_ENCER  = "E" .And. (_cAlias)->C7_CONAPRO= "L" .And. (_cAlias)->C7_QUJE = 0
         _cObs:="COMPRA NÃO REALIZADA. VERIFICAR COMPLEMENTO DE COMPRA OU ELIMINAR RESIDUO"

      EndIf
  
   EndIf


      _aItens:={}
      aAdd(_aItens,(_cAlias)->FILIAL ) 
      aAdd(_aItens,(_cAlias)->NUMSC  ) 
      aAdd(_aItens,(_cAlias)->ITEMSC ) 
      aAdd(_aItens,(_cAlias)->PRD    ) 
      aAdd(_aItens,(_cAlias)->DESCR  ) 
      aAdd(_aItens,(_cAlias)->UM    ) 
      aAdd(_aItens,(_cAlias)->QUANT ) 
      aAdd(_aItens,(_cAlias)->QUJESC) 
      aAdd(_aItens,(_cAlias)->SEGUM ) 
      aAdd(_aItens,(_cAlias)->QTSEGUMSC    ) 
      aAdd(_aItens,DToC(SToD((_cAlias)->ENTREG_SC ))) 
      aAdd(_aItens,(_cAlias)->OBS_SC ) 
      aAdd(_aItens,DToC(SToD((_cAlias)->EMISSAO_SC)) ) 
      aAdd(_aItens,(_cAlias)->SOLICIT  ) 
      aAdd(_aItens,(_cAlias)->APROV_STAT ) 
      aAdd(_aItens,(_cAlias)->URGENT ) 
      aAdd(_aItens,(_cAlias)->APROV_SC ) 
      aAdd(_aItens,DToC(SToD((_cAlias)->DT_APRV))   ) 
      aAdd(_aItens,(_cAlias)->COMPRAD  ) 
      aAdd(_aItens,(_cAlias)->APLIC  ) 
      aAdd(_aItens,(_cAlias)->ZZI_DESINV  ) 
      aAdd(_aItens,(_cAlias)->OBS_APROV  ) 
      aAdd(_aItens,(_cAlias)->USOD       ) 
      aAdd(_aItens,(_cAlias)->C7_NUM     ) 
      aAdd(_aItens,(_cAlias)->C7_QUANT   ) 
      aAdd(_aItens,(_cAlias)->C7_QUJE    ) 
      aAdd(_aItens,(_cAlias)->C7_RESIDUO ) 
      aAdd(_aItens,(_cAlias)->C7_ENCER   ) 
      aAdd(_aItens,(_cAlias)->C7_CONAPRO ) 
	  aAdd(_aItens,_cObs)

        aAdd(_aDados,_aItens)
		(_cAlias)->(DBSkip())
	EndDo

If Len(_aDados) = 0 
    U_ITMsg("Não há dados para essa seleção",'Atenção!',,3)
EndIf

While Len(_aDados) > 0 
   _aTit:={}
   _aSiz:={}

//Colunas:
//FILIAL; NUMERO SC; ITEM SC; COD PROD; DESCRIÇÃO; U.M.; QUANT SC; QUANT ENTREG; 2A. U.M.; QUANT 2A. U.M.; DT ENTREGA SC; OBS;
// DT EMISSAO; SOLICITANTE; STATUS APROV; URGENTE?; APROVADOR; DT APROVAÇÃO; COMPRADOR; APLICAÇÃO; OBS APROV; USO DIRETO?; NUM PEDIDO; QUANT PC; 
//QUANT ENTREG PC; RESIDUO PC; PC ENCERRADO?; COD APROV PC;STATUS
   aAdd(_aTit,'FILIAL') 
   aAdd(_aSiz,20)
   aAdd(_aTit,'NO. SC')
   aAdd(_aSiz,25)
   aAdd(_aTit,'ITEM SC')
   aAdd(_aSiz,20)
   aAdd(_aTit,'CODIGO')
   aAdd(_aSiz,35)
   aAdd(_aTit,'DESCRIÇÃO DO PRODUTO')
   aAdd(_aSiz,150)
   aAdd(_aTit,'U.M.')
   aAdd(_aSiz,20)
   aAdd(_aTit,'QUANT SC')
   aAdd(_aSiz,50)
   aAdd(_aTit,'QUANT ENTREG')
   aAdd(_aSiz,50)
   aAdd(_aTit,'2A. U.M.')
   aAdd(_aSiz,25)
   aAdd(_aTit,'QUANT 2A. U.M.')
   aAdd(_aSiz,50)
   aAdd(_aTit,'DT ENTREGA SC')
   aAdd(_aSiz,50)
   aAdd(_aTit,'OBESERVACAO')
   aAdd(_aSiz,200)
   aAdd(_aTit,'DT EMISSAO')
   aAdd(_aSiz,50)
   aAdd(_aTit,'SOLICITANTE')
   aAdd(_aSiz,150)
   aAdd(_aTit,'STATUS APROV')
   aAdd(_aSiz,50)
   aAdd(_aTit,'URGENTE?')
   aAdd(_aSiz,50)
   aAdd(_aTit,'APROVADOR')
   aAdd(_aSiz,150)
   aAdd(_aTit,'DT APROVAÇÃO')
   aAdd(_aSiz,50)
   aAdd(_aTit,'COMPRADOR')
   aAdd(_aSiz,150)
   aAdd(_aTit,'APLICAÇÃO')
   aAdd(_aSiz,50)
   aAdd(_aTit,'INVESTIMENTO')
   aAdd(_aSiz,100)
   aAdd(_aTit,'OBS APROV')
   aAdd(_aSiz,100)
   aAdd(_aTit,'USO DIRETO?')
   aAdd(_aSiz,50)
   aAdd(_aTit,'NUM PEDIDO')
   aAdd(_aSiz,30)
   aAdd(_aTit,'QUANT PC')
   aAdd(_aSiz,50)
   aAdd(_aTit,'QUANT ENTREG PC')
   aAdd(_aSiz,50)
   aAdd(_aTit,'RESIDUO PC')
   aAdd(_aSiz,50)
   aAdd(_aTit,'PC ENCERRADO?')
   aAdd(_aSiz,50)
   aAdd(_aTit,'COD APROV PC')
   aAdd(_aSiz,50)
   aAdd(_aTit,'STATUS')
   aAdd(_aSiz,400)

   _cTitulo:="SCs encontradas - H.I.: "+cTimeInicial+" H.F.: "+Time()

   _cMsgTop:="Par. 1 : "+DToC(MV_PAR01)+"; Par. 2 : "+DToC(MV_PAR02)+"; Par. 3 : "+AllTrim(MV_PAR03)+"; Par. 4 : "+AllTrim(MV_PAR04)+;
           "; Par. 5 : "+AllTrim(MV_PAR05)+"; Par. 6 : "+AllTrim(MV_PAR06)+"; Par. 7 : "+AllTrim(MV_PAR07)+"; Par. 8 : "+AllTrim(MV_PAR08)+;
           "; Par. 9 : "+AllTrim(MV_PAR09)+"; Par. 10 : "+AllTrim(MV_PAR10)

   bOk:={|| If(U_ITMsg("Confirma Gerar EXCEL ?",'Atenção!',,2,2,2) , DlgToExcel( { { "ARRAY" , _cTitulo , _aTit , _aDados } } )  ,.F. )   }

   //                           , _aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
      U_ITListBox(_cTitulo,_aTit,_aDados  , .T.    , 3    ,_cMsgTop,          ,_aSiz   ,         , bOk ,        , )
                                                                                                  

   If  !U_ITMsg("Confirma Sair ?",'Atenção!',,3,2,2)
       Loop
   EndIf

    Exit

EndDo

Return

/*
===============================================================================================================================
Programa----------: MontaSC1Select
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 14/05/2020
Descrição---------: Cria O SELECT DO SC1
Parametros--------: cPerg
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MontaSC1Select()

Local cQry1:=" SELECT DISTINCT C1_NUM , C1_EMISSAO FROM "+RETSQLNAME("SC1")+" SC1 WHERE C1_RESIDUO <> 'S' AND D_E_L_E_T_ = ' ' "
   
   If !Empty(MV_PAR02)
      cQry1 += " AND C1_EMISSAO BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "' "
   ElseIf !Empty(MV_PAR01)
      cQry1 += " AND C1_EMISSAO >= '" + DToS(MV_PAR01) + "' "
   EndIf   
   
   If !Empty(MV_PAR03)
       cQry1 += " AND C1_FILIAL IN "+FormatIn(AllTrim(MV_PAR03),";")
   Else
       cQry1 += " AND C1_FILIAL = '"+xFilial("SC1")+"'"
   End If
//SOLICITANTES
   If !Empty(MV_PAR04)
       cQry1 += "AND C1_SOLICIT IN "+FormatIn(AllTrim(MV_PAR04),";")
   EndIf
//APROVADORES
   If !Empty(MV_PAR05)
       cQry1 += "AND C1_I_CODAP IN "+FormatIn(AllTrim(MV_PAR05),";")
   EndIf

   //Filtra comprador
   If !Empty(MV_PAR06)
   	   cQry1 += " AND C1_CODCOMP  IN "+FormatIn(AllTrim(MV_PAR06),";")
   EndIf     
   
   //Filtra SC
   If !Empty(MV_PAR07)
   	   cQry1 += " AND C1_NUM IN "+FormatIn(AllTrim(MV_PAR07),";")
   EndIf 

   //Filtra PRODUTO
   If !Empty(MV_PAR08)
   	   cQry1 += " AND C1_PRODUTO IN "+FormatIn(AllTrim(MV_PAR08),";")
   EndIf 

   //Filtra APLICACAO
   If MV_PAR10 = "1"				//Consumo
   	  cQry1 += " AND C1_I_APLIC = 'C' "
   ElseIf MV_PAR10 = "2"		//Investimento
   	  cQry1 += " AND C1_I_APLIC = 'I' "
   ElseIf MV_PAR10 = "3"			//Manutenï¿½ï¿½o
   	  cQry1 += " AND C1_I_APLIC = 'M' "
   ElseIf MV_PAR10 = "4"		//Serviï¿½o
   	  cQry1 += " AND C1_I_APLIC = 'S' "
   ElseIf MV_PAR10 = "5"			//Todos
   	  cQry1 += " AND C1_I_APLIC <> ' ' "
   EndIf
    
    //Uso Direto
   If MV_PAR09 = "1"
   	  cQry1 += " AND C1_I_USOD = 'S' "
   ElseIf MV_PAR09 = "2"
   	  cQry1 += " AND C1_I_USOD = 'N' "
   EndIf

cQry1 += " ORDER BY 1 " 
cQry1 := ChangeQuery(cQry1)

Return cQry1
