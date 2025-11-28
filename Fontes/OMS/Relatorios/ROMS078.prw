/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves | 28/08/2024 | Chamado 48344 - Adicionar informação do Leite Magro no SubItem
Igor Melgaço  | 19/09/2024 | Chamado 48576. Ajuste no ZK1_SUBITE para 2 caracteres.
Lucas Borges  | 22/04/2025 | Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
Analista        - Programador     - Inicio     - Envio      - Chamado - Motivo de Alteração
==============================================================================================================================
Antonio Ramos   - Igor Melgaço    - 19/12/2024 - 19/12/2024 - 49414   - Ajuste para novo tipo de contrato.
Antonio Ramos   - Igor Melgaço    - 11/04/2025 - 24/04/2025 - 50007   - Ajuste para novo tipo de relatório 5-Grupo BI MIX.
Alexandro       - Igor Melgaço    - 25/04/2025 - 25/04/2025 - 50525   - Ajuste para remoção de diretório local.
Antonio Neves   - Antonio Neves   - 05/05/2025 - 05/05/2025 - 50608   - Ajueste do Parametro 5 para incluir o parâmetros 02 e 03 na query
Antonio Neves   - Antonio Neves   - 08/05/2025 - 09/05/2025 - 50654   - Ajuste do relatório trazendo valores duplicados e adicionar campo valor unitario item
Andre           - Igor Melgaço    - 28/05/2025 -            - 50805   - Ajustes para inclusão de colunas e impressão do campo "Regional"
=============================================================================================================================== 
*/

#Include "TOTVS.ch"
#Include "topconn.ch"
#Include "msmgadd.ch"
#Include "dbtree.ch"                  
#Include "RWMake.ch"

//Picture DOS CAMPOS NUMERICOS
//Static _cPictQTDE  := "@E 999,999,999,999.9999"//Getsx3cache("C6_UNSVEN" ,"X3_PICTURE")
//Static _cPictVLNET := "@E 999,999,999,999.999"
//Static _cPictVALOR := "@E 999,999,999,999.99"  //Getsx3cache("C6_VALOR"  ,"X3_PICTURE")

/*
===============================================================================================================================
Programa--------: ROMS078
Autor-----------: Alex Wallauer
Data da Criacao-: 02/02/2023
Descrição-------: Chamado 42798. Relatórios de verbas/acordos comerciais
Parametros------: NENHUM
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function ROMS078()// U_ROMS078
Local nI
Local _cCombo := Getsx3cache("ZK1_TIPOAC","X3_CBOX")//"1=Aniversario;2=Reforma-Reinauguracao;3=Acao Comercial;4=Rebaixa de preco;5=Introducao de produto;6=Contrato"
_cCombo := StrTran(_cCombo,"=","-")
_aTiposAcor:= StrTokArr(_cCombo, ';')//"1-Aniversario","2-Reforma Reinauguracao","3-Acao Comercial","4-Rebaixa de preco","5-Introducao de produto"

_cCombo := Getsx3cache("ZK1_STATUS","X3_CBOX")//"1=Em Elaboracao;2=Efetivado;3=Recusado;4=Encaminhado;5=Provisao"
_cCombo := StrTran(_cCombo,"=","-")
_aStatus := StrTokArr(_cCombo, ';')

_aItalac_F3:={}//       1             2           3                                     4                        5                  6                    7         8          9         10         11        12
//  (_aItalac_F3,{"CPOCAMPO"     ,_cTabela   ,_nCpoChave                           , _nCpoDesc               ,_bCondTab        ,_cTitAux           , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR12"     ,           ,                                     ,                         ,                ,"Tipo de Acordo",1     ,_aTiposAcor,Len(_aTiposAcor)} )
aAdd(_aItalac_F3,{"MV_PAR13"     ,           ,                                     ,                         ,                ,"Status"        ,1     ,_aStatus   ,Len(_aStatus)   } )

Private _aRel:={"1-Verbas sintético","2-Verbas x contratos","3-Rateio por item","4-Rateio por parcela","5-Grupo BI MIX"}

MV_PAR01:="1"
MV_PAR02:=Date()
MV_PAR03:=Date()
MV_PAR04:=Date()
MV_PAR05:=Date()
MV_PAR06:=Space(Len(SC5->C5_VEND1))
MV_PAR07:=Space(Len(SC5->C5_VEND1))
MV_PAR08:=Space(Len(SC5->C5_VEND1))
MV_PAR09:=Space(Len(SC5->C5_I_GRPVE))
MV_PAR10:=Space(Len(SA2->A2_COD))
MV_PAR11:=Space(Len(SA2->A2_LOJA))
MV_PAR12:=Space(50)
MV_PAR13:=Space(50)
MV_PAR14:="3"

_aParAux:={}
_aParRet:={}

cVal:='Vazio().OR.ExistCpo("SA1",MV_PAR10+AllTrim(MV_PAR11))' 
aAdd( _aParAux , { 2 , "Selecione Relatorio"  , MV_PAR01, _aRel   , 100 ,".T.",.T.,".T."}) 
aAdd( _aParAux , { 1 , "Inclusao de"          , MV_PAR02, "@D", "" , ""	     , "" , 050 , .T. })
aAdd( _aParAux , { 1 , "Inclusao ate"         , MV_PAR03, "@D", "" , ""	     , "" , 050 , .T. })
aAdd( _aParAux , { 1 , "Vencimento de"        , MV_PAR04, "@D", "" , ""	     , "" , 050 , .F. })
aAdd( _aParAux , { 1 , "Vencimento ate"       , MV_PAR05, "@D", "" , ""	     , "" , 050 , .F. })
aAdd( _aParAux , { 1 , "Gerente"              , MV_PAR06, "@!", "" , "SA3_02", "" , 050 , .F. })
aAdd( _aParAux , { 1 , "Coordenador"          , MV_PAR07, "@!", "" , "SA3_01", "" , 050 , .F. })
aAdd( _aParAux , { 1 , "Vendedor"             , MV_PAR08, "@!", "" , "SA3BLQ", "" , 050 , .F. })
aAdd( _aParAux , { 1 , "Redes"	             , MV_PAR09, "@!", "" , "ACY2"  , "Empty(MV_PAR10) .And. Empty(MV_PAR11)" , 050, .F. } )
aAdd( _aParAux , { 1 , "Cliente"              , MV_PAR10, "@!", "" , "SA1"   , "Empty(MV_PAR09)", 050,  , .F. } )
aAdd( _aParAux , { 1 , "Loja  "	             , MV_PAR11, "@!",cVal,""	     , "Empty(MV_PAR09)", 050,  , .F. } )
aAdd( _aParAux , { 1 , "Tipo do Acordo"       , MV_PAR12, "@!","" ,"F3ITLC", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Status"               , MV_PAR13, "@!","" ,"F3ITLC", "" , 100 , .F. } ) 
aAdd( _aParAux , { 2 , "Já Abatido"           , 3       , {"1-Sim","2-Nao","3-Ambos"}, 060 ,".T.",.T.,".T."}) 
      
For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next 
   
While .T.

   If !ParamBox( _aParAux , "Selecione os filtros" , _aParRet , {|| .T. } , , , , , , , .T. , .T. )
      Exit
   EndIf
   
   If !(MV_PAR03 >= MV_PAR02)
      U_ITMsg("Periodo da inclusao INVALIDO",'Atenção!',"Tente novamente com outro periodo",1)
      Loop
   EndIf

   If !(MV_PAR05 >= MV_PAR04)
      U_ITMsg("Periodo do vencimento INVALIDO",'Atenção!',"Tente novamente com outro periodo",1)
      Loop
   EndIf

   If (!Empty(MV_PAR09) .And.  !Empty(MV_PAR10+MV_PAR11))
      U_ITMsg("Preencha uma Rede ou um Cliente",'Atenção!',"Um dos 2 pode ser preenchido mas não os 2 juntos.",1)
      Loop
   EndIf

   If ("3" $ MV_PAR13 .Or. "5" $ MV_PAR13) .And. AllToChar(MV_PAR01) = "3"//3-Rateio por item
      U_ITMsg("Status 3-Recusado e 5-Provisao serão ignorados nesse Relatorio '3-Rateio por item' ! ",'Atenção!',,3)
   EndIf

   If ValType(MV_PAR14) = "N"
      MV_PAR14:=Str(MV_PAR14,1)
   EndIf

   _cTitulo:="RELATORIO DE "
   If Val(AllToChar(MV_PAR01)) > 0 .And. Val(AllToChar(MV_PAR01)) <= Len(_aRel)
      _cTitulo+=Upper(SubStr(_aRel[Val(MV_PAR01)],3))
   EndIf
   
   cTimeInicial:=Time()
   _cTitulo+=" - "+DToC(DATE())+" - H. I. : "+Time()

   aCab:={}
   aCabXML:={}
   _aDadosRel:={}
      
   FWMsgRun(,{|oproc|  _aDadosRel := ROMS78CP(oproc)  }, "Selecionando os Acordos...","Filtrando Acordos..." )
   
   If Len(_aDadosRel) > 0 
      
      _cTitulo2:=_cTitulo+" H. F. : "+Time()
      _cMsgTop:="Par. 1: "+AllTrim(AllToChar(MV_PAR01))+ "; Par. 2: " +AllTrim(AllToChar(MV_PAR02))+"; Par. 3: " +AllTrim(AllToChar(MV_PAR03))+"; Par. 4: "+AllTrim(AllToChar(MV_PAR04))+;
               "; Par. 5: "+AllTrim(AllToChar(MV_PAR05))+ "; Par. 6: " +AllTrim(AllToChar(MV_PAR06))+"; Par. 7: " +AllTrim(AllToChar(MV_PAR07))+"; Par. 8: "+AllTrim(AllToChar(MV_PAR08))+;
               "; Par. 9: "+AllTrim(AllToChar(MV_PAR09))+ "; Par. 10: "+AllTrim(AllToChar(MV_PAR10))+"; Par. 11: "+AllTrim(AllToChar(MV_PAR11))+;
               "; Par. 12: "+AllTrim(AllToChar(MV_PAR12))+"; Par. 13: "+AllTrim(AllToChar(MV_PAR13))+"; Par. 14: "+AllTrim(AllToChar(MV_PAR14))

      _cMsgFil:=_cTitulo2+CRLF+;
                  "Inclusão de : "   +AllTrim(AllToChar(MV_PAR02))+" ate "+AllTrim(AllToChar(MV_PAR03))+CRLF+;
                  "Vencimento de : " +AllTrim(AllToChar(MV_PAR04))+" ate "+AllTrim(AllToChar(MV_PAR05))+CRLF+;
                  "Gerente : "       +AllTrim(AllToChar(MV_PAR06))+CRLF+;
                  "Coordenador : "   +AllTrim(AllToChar(MV_PAR07))+CRLF+;
                  "Vendedor : "      +AllTrim(AllToChar(MV_PAR08))+CRLF+;
                  "Redes : "	        +AllTrim(AllToChar(MV_PAR09))+CRLF+;
                  "Cliente : "       +AllTrim(AllToChar(MV_PAR10))+CRLF+;
                  "Loja : "	        +AllTrim(AllToChar(MV_PAR11))+CRLF+;
                  "Tipo do Acordo : "+AllTrim(AllToChar(MV_PAR12))+CRLF+;
                  "Status : "        +AllTrim(AllToChar(MV_PAR13))+CRLF+;
                  "Já Abatido : "    +AllTrim(AllToChar(MV_PAR14))

      _aSX1:=ROMS78Per()
      aBotoes:={}
      aAdd(aBotoes,{"",{|| U_ITMsgLog(_cMsgFil, "FILTROS APLICADOS" )},"","Filtros Aplicados"})
                        //      ,_aCols     ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab  , bDblClk , _aColXML , bCondMarca,_bLegenda,_lHasOk,_bHeadClk,_aSX1 )
      U_ITListBox(_cTitulo2,aCab,_aDadosRel, .T.    , 1    ,_cMsgTop ,          ,       ,         ,     ,        , aBotoes  , aCabXML,         ,          ,           ,         ,       ,         ,_aSX1)
      Loop      
   Else 
      Loop
   EndIf

   Exit

EndDo


Return .T.

/*
===============================================================================================================================
Programa--------: ROMS78CP
Autor-----------: Alex Wallauer
Data da Criacao-: 02/02/2023
Descrição-------: Ler os dados da Select e grava da array
Parametros------: oProc 
Retorno---------: _aDadosRel
===============================================================================================================================*/
Static Function ROMS78CP(oproc)
Local _cQuery     := "" //, _nni , nPos , P , Z2
Local _cAlias2    := GetNextAlias()
Local _aMes			:= {"Janeiro","Fevereiro","Março","Abril","Maio","Junho","Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"}
Local _cCnpj, _cFormaPgto , _cCnpjFavo
Local _cProvisao  := ""
Local ni := 0

aCab:={}
aCabXML:={}

If oproc <> NIL
   oproc:cCaption := ("Filtrando dados ..." )
   ProcessMessages() 
EndIf

If AllToChar(MV_PAR01) = "1"//

   // Alinhamento: 1-Left   ,2-Center,3-Right
   // Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
   //             Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
   //   (aCabXML,{Titulo             ,1           ,1         ,.F.       })
   aAdd(aCab   , "Vencimento")                     // 1
   aAdd(aCabXML,{"Vencimento",1,1,.F.})            // 1 
   aAdd(aCab   , "Ano vencimento")                 // 2
   aAdd(aCabXML,{"Ano vencimento",2,2,.F.})        // 2
   aAdd(aCab   , "Mes vencimento")                 // 3
   aAdd(aCabXML,{"Mes vencimento",2,2,.F.})        // 3

   aAdd(aCab,"Cod Gerente")                        // 4
   aAdd(aCabXML,{"Cod Gerente",1,1,.F.})           // 4 
   aAdd(aCab,"Gerente")                            // 5
   aAdd(aCabXML,{"Gerente",1,1,.F.})               // 5 
   aAdd(aCab,"Cod Coordenador")                    // 6
   aAdd(aCabXML,{"Cod Coordenador",1,1,.F.})       // 6 
   aAdd(aCab,"Coordenador")                        // 7
   aAdd(aCabXML,{"Coordenador",1,1,.F.})           // 7 
   aAdd(aCab,"Cod Vendedor")                       // 8
   aAdd(aCabXML,{"Cod Vendedor",1,1,.F.})          // 8 
   aAdd(aCab,"Vendedor")                           // 9
   aAdd(aCabXML,{"Vendedor",1,1,.F.})              // 9 

   aAdd(aCab   , "Verba")                          // 10
   aAdd(aCabXML,{"Verba",2,1,.F.})                 // 10
   aAdd(aCab   , "Rede")                           // 11
   aAdd(aCabXML,{"Rede",1,1,.F.})                  // 11
   //---------------------------------------- 
   aAdd(aCab   , "CNPJ")                           // 11-a
   aAdd(aCabXML,{"CNPJ",1,1,.F.})                  // 11-a
   aAdd(aCab   , "Forma de Pagamento")             // 11-b
   aAdd(aCabXML,{"Forma de Pagamento",1,1,.F.})    // 11-b
   //----------------------------------------
   aAdd(aCab   , "Tipo de acordo")                 // 12
   aAdd(aCabXML,{"Tipo de acordo",1,1,.F.})        // 12
   aAdd(aCab   , "Data lançamento")                // 13
   aAdd(aCabXML,{"Data lançamento",2,4,.F.})       // 13
   aAdd(aCab   , "Observação")                     // 14
   aAdd(aCabXML,{"Observação",1,1,.F.})            // 14
   aAdd(aCab   , "Status")                         // 15
   aAdd(aCabXML,{"Status",1,1,.F.})                // 15
   aAdd(aCab   , "Total da verba")                 // 16
   aAdd(aCabXML,{"Total da verba",3,3,.F.})        // 16
   aAdd(aCab   , "Efetivado")                      // 17   
   aAdd(aCabXML,{"Efetivado",3,3,.F.})             // 17
   aAdd(aCab   , "Pendente")                       // 18 
   aAdd(aCabXML,{"Pendente",3,3,.F.})              // 18 
   aAdd(aCab   , "Provisão")                       // 19
   aAdd(aCabXML,{"Provisão",3,3,.F.})              // 19
   aAdd(aCab   , "Data NCC")                       // 20
   aAdd(aCabXML,{"Data NCC",2,4,.F.})              // 20
   aAdd(aCab   , "Saldo Fin.")                       // 21
   aAdd(aCabXML,{"Saldo Fin.",3,3,.F.})              // 21
   //------------------------------------------------------------------------
   aAdd(aCab   , "Favorecido")                     // 22
   aAdd(aCabXML,{"Favorecido",2,1,.F.})            // 22
   aAdd(aCab   , "Loja Favorecido")                // 23
   aAdd(aCabXML,{"Loja Favorecido",2,1,.F.})       // 23
   aAdd(aCab   , "CNPJ Favorecido")                // 24
   aAdd(aCabXML,{"CNPJ Favorecido",2,1,.F.})       // 24
   aAdd(aCab   , "Nome Favorecido")                     // 25
   aAdd(aCabXML,{"Nome Favorecido",2,1,.F.})            // 25
   aAdd(aCab   , "Regional")                     // 26
   aAdd(aCabXML,{"Regional",2,1,.F.})            // 26

   //------------------------------------------------------------------------   
   aAdd(aCab   , "Provisionado")                    // 27
   aAdd(aCabXML,{"Provisionado",2,1,.F.})          // 27
   //------------------------------------------------------------------------

   aAdd(aCab   , "Sub. Tipo")                    // 28
   aAdd(aCabXML,{"Sub. Tipo",2,1,.F.})          // 28

   aAdd(aCab   , "Periodo de Ref.")                    // 29
   aAdd(aCabXML,{"Periodo de Ref.",2,1,.F.})          // 29
   




   _cQuery += "  SELECT"
   // _cQuery += "         TRIM (TO_CHAR ( (TO_DATE (ZK3_VENCTO || '01', 'yyyymmdd')), 'Month')) "
   // _cQuery += "         || '/' "
   // _cQuery += "         || SubStr (ZK3_VENCTO, 1, 4) "
   // _cQuery += "            VENCIMENTO , "//********************* COLUNA
   _cQuery += "         SubStr (ZK3_VENCTO, 1, 4) ANO , "//********************* COLUNA
   _cQuery += "         SubStr (ZK3_VENCTO, 5, 2) MES , "//********************* COLUNA
   _cQuery += "         ZK1_CGEREN , ZK1_GERENT , ZK1_CCOODN , ZK1_COODNA , ZK1_CVENDE , ZK1_VENDER , "  //********************* COLUNA
   _cQuery += "         ZK1_CODIGO , " //********************* COLUNA
   _cQuery += "         ZK3_GERAC , "
   //---------------------------------------- 
   _cQuery += "         ZK1_FORPAG, ZK1_CLIENT, ZK1_CLILOJ, "
   _cQuery += "         ZK1_FAVORE , ZK1_FAVLOJ , ZK1_PROV, "
   //----------------------------------------
   _cQuery += "         Case "
   _cQuery += "            WHEN TRIM (ZK1_REDES) IS NOT NULL "
   _cQuery += "            THEN "
   _cQuery += "               ZK1_REDES "
   _cQuery += "            WHEN (ZK1_CLIENT <> ' ' AND ZK1_CLILOJ <> ' ') "
   _cQuery += "            THEN "
   _cQuery += "               (SELECT A1_NOME "
   _cQuery += "                  FROM " + RetSqlName("SA1") + " SA1 "
   _cQuery += "                 WHERE     A1_FILIAL = ' ' "
   _cQuery += "                       AND A1_COD = ZK1_CLIENT "
   _cQuery += "                       AND A1_LOJA = ZK1_CLILOJ "
   _cQuery += "                       AND SA1.D_E_L_E_T_ = ' ') "
   _cQuery += "            Else "
   _cQuery += "               (SELECT A1_NOME "
   _cQuery += "                  FROM " + RetSqlName("SA1") + " SA1 "
   _cQuery += "                 WHERE     A1_FILIAL = ' ' "
   _cQuery += "                       AND A1_COD = ZK1_CLIENT "
   _cQuery += "                       AND A1_LOJA = "
   _cQuery += "                              (SELECT MIN (A1_LOJA) "
   _cQuery += "                                 FROM " + RetSqlName("SA1") + " SA1B "
   _cQuery += "                                WHERE     SA1B.A1_FILIAL = SA1.A1_FILIAL "
   _cQuery += "                                      AND SA1B.A1_COD = SA1.A1_COD "
   _cQuery += "                                      AND SA1B.D_E_L_E_T_ = ' ') "
   _cQuery += "                       AND SA1.D_E_L_E_T_ = ' ') "
   _cQuery += "         END "
   _cQuery += "            CLIENTE, "//********************* COLUNA
   _cQuery += "         ZK1_TIPOAC, "//********************* COLUNA
   _cQuery += "         ZK1_INCLDT, "//********************* COLUNA
   _cQuery += "         ZK1_OBS   , "//********************* COLUNA
   _cQuery += "         ZK1_STATUS, "//********************* COLUNA
   _cQuery += "         ZK1_VLRCOR, "//********************* COLUNA
   _cQuery += "         DECODE (ZK1_STATUS, '2', ZK3_VALOR,  '4', ZK3_VALOR,'6', ZK3_VALOR,  0) EFETIVADO, "//********************* COLUNA
   _cQuery += "         DECODE (ZK1_STATUS, '1', ZK3_VALOR, 0) PENDENTE, "//********************* COLUNA
   _cQuery += "         DECODE (ZK1_STATUS, '5', ZK3_VALOR, 0) PROVISAO,  "//********************* COLUNA
   _cQuery += "         Case ZK1_SUBITE WHEN '01' THEN 'sell_in/out' "
   _cQuery += "                         WHEN '02' THEN 'Rbxa.Prc' "
   _cQuery += "                         WHEN '03' THEN 'Dt.Critc' "
   _cQuery += "                         WHEN '04' THEN 'Tabl.' "
   _cQuery += "                         WHEN '05' THEN 'Dif.Imp' " 
   _cQuery += "                         WHEN '06' THEN 'Int.Prod' "
   _cQuery += "                         WHEN '07' THEN 'Comite' "
   _cQuery += "                         WHEN '08' THEN 'Dif.Prc' "
   _cQuery += "                         WHEN '09' THEN 'Contr' "
   _cQuery += "                         WHEN '10' THEN 'Aniv' "
   _cQuery += "                         WHEN '11' THEN 'Re/Inaug' "
   _cQuery += "                         WHEN '12' THEN 'Mkt/Trade' "
   _cQuery += "                         WHEN '13' THEN 'UHT MGR' "
   _cQuery += "         END AS SUBITE, " //********************* COLUNA
   _cQuery += "         ZK1_ANOMES, "//********************* COLUNA 
   _cQuery += "         E1_SALDO "
   _cQuery += "  FROM (  SELECT ZK3_FILIAL, "
   _cQuery += "                   ZK3_CODIGO, "
   _cQuery += "                   SubStr (ZK3_VENCTO, 1, 6) ZK3_VENCTO, "
   _cQuery += "                   SUM (ZK3_VALOR) ZK3_VALOR, "
   _cQuery += "                   MIN (E1_EMISSAO) ZK3_GERAC , "
   _cQuery += "                   SUM (E1_SALDO) E1_SALDO "  
   _cQuery += "              FROM " + RetSqlName("ZK3") + " ZK3 "
   _cQuery += "                  LEFT JOIN " + RetSqlName("SE1") + " SE1 ON SE1.E1_FILIAL = ZK3.ZK3_TITFIL AND SE1.E1_NUM = ZK3.ZK3_TITULO AND SE1.E1_PARCELA = ZK3.ZK3_TITPAR AND SE1.E1_PREFIXO='VRB' AND SE1.E1_TIPO = 'NCC' AND SE1.D_E_L_E_T_ = ' ' ""
   _cQuery += "             WHERE ZK3.D_E_L_E_T_ = ' ' "
   _cQuery += "          GROUP BY ZK3_FILIAL, ZK3_CODIGO, SubStr (ZK3_VENCTO, 1, 6)) ZK3, "
   _cQuery += "         " + RetSqlName("ZK1") + " ZK1 "
   _cQuery += "  WHERE     ZK1_FILIAL = ZK3_FILIAL "
   _cQuery += "         AND ZK1_CODIGO = ZK3_CODIGO "
   _cQuery += "         AND ZK1.D_E_L_E_T_ = ' ' "

   _cQuery:=ROMS78Filtro(@_cQuery)

   _cQuery += " ORDER BY ZK3_VENCTO, ZK1_GERENT, ZK1_CLIENT, ZK1_CODIGO "
      
   cTimeINI:=Time()
   MPSysOpenQuery( _cQuery , _cAlias2 )

   DBSelectArea(_cAlias2)   
   _nTot:=nConta:=0
   COUNT TO _nTot
   _cTotGeral:=AllTrim(Str(_nTot))

   cTimeFIM:="Hora Incial: "+cTimeINI+" - Hora Final: "+TIME()+" da leitura dos dados"

   (_cAlias2)->(DBGoTop())
   If (_cAlias2)->(Eof())
      U_ITMsg("Não tem Acordos para processamento com esses filtros.",cTimeFIM,"Altere os filtros.",3) 
      Return {}
   EndIf
      
   If !U_ITMsg("Serão processados "+_cTotGeral+' registros, Confirma ?',cTimeFIM,,3,2,3,,"CONFIRMA","VOLTAR")
      Return {}
   EndIf
      
   _aDadosRel:={}
   While (_cAlias2)->(!Eof()) //**********************************  While  ******************************************************
            
         If oproc <> NIL
            nConta++
            oproc:cCaption := ("Lendo "+StrZero(nConta,5) +" de "+ _cTotGeral )
            ProcessMessages()
         EndIf

         _cTIPOAC:=""
         If Val((_cAlias2)->ZK1_TIPOAC) > 0 .And. Val((_cAlias2)->ZK1_TIPOAC) <= Len(_aTiposAcor)
            _cTIPOAC:=_aTiposAcor[Val((_cAlias2)->ZK1_TIPOAC)]
         EndIf
         _cSTATUS:=""
         If Val((_cAlias2)->ZK1_STATUS) > 0 .And. Val((_cAlias2)->ZK1_STATUS) <= Len(_aStatus)
            _cSTATUS:=_aStatus[Val((_cAlias2)->ZK1_STATUS)]
         EndIf

         _aProd := {}
         aAdd(_aProd ,_aMes[Val((_cAlias2)->MES)]+"/"+(_cAlias2)->ANO)//(_cAlias2)->VENCIMENTO) // 1
         aAdd(_aProd ,(_cAlias2)->ANO)               // 2
         aAdd(_aProd ,(_cAlias2)->MES)               // 3

         aAdd(_aProd ,(_cAlias2)->ZK1_CGEREN)        // 4
         aAdd(_aProd ,(_cAlias2)->ZK1_GERENT)        // 5
         aAdd(_aProd ,(_cAlias2)->ZK1_CCOODN)        // 6
         aAdd(_aProd ,(_cAlias2)->ZK1_COODNA)        // 7
         aAdd(_aProd ,(_cAlias2)->ZK1_CVENDE)        // 8
         aAdd(_aProd ,(_cAlias2)->ZK1_VENDER)        // 9

         aAdd(_aProd ,(_cAlias2)->ZK1_CODIGO)        // 10
         aAdd(_aProd ,(_cAlias2)->CLIENTE)           // 11 
   //------------------------------------------------------------ CNPJ 
   //------------------------------------------------------------ Forma de pagamento
         _cCnpj := " "

         If !Empty((_cAlias2)->ZK1_CLIENT) .And. !Empty((_cAlias2)->ZK1_CLILOJ) 
            _cCnpj := Posicione('SA1',1,xFilial('SA1')+(_cAlias2)->ZK1_CLIENT+(_cAlias2)->ZK1_CLILOJ,'A1_CGC')   
         ElseIf !Empty((_cAlias2)->ZK1_CLIENT)
            _cCnpj := Posicione('SA1',1,xFilial('SA1')+(_cAlias2)->ZK1_CLIENT,'A1_CGC')    
         EndIf 
         
         If ! Empty(_cCnpj)
            _cCnpj := Transform( _cCnpj , "@R! NN.NNN.NNN/NNNN-99" )
         EndIf 

         aAdd(_aProd ,_cCnpj)           //  
   //-----------------------------------------         

         _cFormaPgto := ""
         If (_cAlias2)->ZK1_FORPAG == "1"
            _cFormaPgto := "BOLETO"   
         ElseIf (_cAlias2)->ZK1_FORPAG == "2"
            _cFormaPgto := "DESCONTO"
         ElseIf (_cAlias2)->ZK1_FORPAG == "3"
            _cFormaPgto := "DEPOSITO"
         EndIf 
         aAdd(_aProd ,_cFormaPgto)           //  
   //------------------------------------------------------------

         aAdd(_aProd ,_cTIPOAC)                      // 12
         aAdd(_aProd ,SToD((_cAlias2)->ZK1_INCLDT))  // 13
         aAdd(_aProd ,(_cAlias2)->ZK1_OBS)           // 14
         aAdd(_aProd ,_cSTATUS)                      // 15
         aAdd(_aProd ,(_cAlias2)->ZK1_VLRCOR)        // 16
         aAdd(_aProd ,(_cAlias2)->EFETIVADO)         // 17
         aAdd(_aProd ,(_cAlias2)->PENDENTE)          // 18
         aAdd(_aProd ,(_cAlias2)->PROVISAO)          // 19
         aAdd(_aProd ,SToD((_cAlias2)->ZK3_GERAC))   // 20
         aAdd(_aProd ,(_cAlias2)->E1_SALDO)   // 21
   //--------------------------------------------------------------------------- Favorecido  
         _cCnpjFavo := ""
         _cNomeFavo := ""
         _cRegional := ""

         If !Empty((_cAlias2)->ZK1_FAVORE) .And. !Empty((_cAlias2)->ZK1_FAVLOJ) 
            DBSelectArea("SA1")
            DBSetOrder(1)
            If DBSeek(xFilial('SA1')+(_cAlias2)->ZK1_FAVORE+(_cAlias2)->ZK1_FAVLOJ)
               _cCnpjFavo := SA1->A1_CGC
               _cNomeFavo := SA1->A1_NOME

               DBSelectArea("SA3")
               DBSetOrder(1)
               If DBSeek(xFilial('SA3')+SA1->A1_VEND)
                  cGeren := SA3->A3_GEREN
                  cCoord := SA3->A3_SUPER
                  DBSelectArea("ZAM")
                  DBSetOrder(1)
                  If DBSeek(xFilial('ZAM')+cCoord+cGeren)
                     _cRegional := ZAM->ZAM_REGCOD + " - " + Tabela("ZC", ZAM->ZAM_REGCOD, .F.)
                  EndIf
               EndIf

            EndIf
               
         ElseIf !Empty((_cAlias2)->ZK1_FAVORE)
            DBSelectArea("SA1")
            DBSetOrder(1)
            If DBSeek(xFilial('SA1')+(_cAlias2)->ZK1_FAVORE)
               _cCnpjFavo := SA1->A1_CGC
               _cNomeFavo := SA1->A1_NOME

               DBSelectArea("SA3")
               DBSetOrder(1)
               If DBSeek(xFilial('SA3')+SA1->A1_VEND)
                  cGeren := SA3->A3_GEREN
                  cCoord := SA3->A3_SUPER

                  DBSelectArea("ZAM")
                  DBSetOrder(1)
                  If DBSeek(xFilial('ZAM')+cCoord+cGeren)
                     _cRegional := ZAM->ZAM_REGCOD + " - " + Tabela("ZC", ZAM->ZAM_REGCOD, .F.)
                  EndIf
               EndIf
            EndIf
         EndIf 

         If ! Empty(_cCnpjFavo)
            _cCnpjFavo := Transform( _cCnpjFavo , "@R! NN.NNN.NNN/NNNN-99" )
         EndIf 

         aAdd(_aProd ,(_cAlias2)->ZK1_FAVORE)       // 22
         aAdd(_aProd ,(_cAlias2)->ZK1_FAVLOJ)       // 23
         aAdd(_aProd ,_cCnpjFavo)                   // 24
         aAdd(_aProd ,_cNomeFavo)                      // 25
         aAdd(_aProd ,_cRegional)                      // 26

         _cProvisao := " "
         If (_cAlias2)->ZK1_PROV == "S"
            _cProvisao := "SIM"
         ElseIf (_cAlias2)->ZK1_PROV == "N"   
            _cProvisao := "NÃO" 
         EndIf 
         aAdd(_aProd ,_cProvisao)                   // 27
         aAdd(_aProd ,(_cAlias2)->SUBITE)           // 28
         aAdd(_aProd ,SubStr((_cAlias2)->ZK1_ANOMES,1,2)+'/'+SubStr((_cAlias2)->ZK1_ANOMES,3,4))                // 29

         aAdd(_aDadosRel , _aProd  )
               
         (_cAlias2)->(DBSkip())
      
   EndDo

ElseIf AllToChar(MV_PAR01) = "2"// ************************************************************************************

   // Alinhamento: 1-Left   ,2-Center,3-Right
   // Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
   //             Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
   //   (aCabXML,{Titulo             ,1           ,1         ,.F.       })

   aAdd(aCab,"Cod Gerente")                                 // 1
   aAdd(aCabXML,{"Cod Gerente",1,1,.F.})                    // 1
   aAdd(aCab,"Gerente")                                     // 2
   aAdd(aCabXML,{"Gerente",1,1,.F.})                        // 2
   aAdd(aCab,"Cod Coordenador")                             // 3
   aAdd(aCabXML,{"Cod Coordenador",1,1,.F.})                // 3
   aAdd(aCab,"Coordenador")                                 // 4
   aAdd(aCabXML,{"Coordenador",1,1,.F.})                    // 4
   aAdd(aCab,"Cod Vendedor")                                // 5
   aAdd(aCabXML,{"Cod Vendedor",1,1,.F.})                   // 5
   aAdd(aCab,"Vendedor")                                    // 6
   aAdd(aCabXML,{"Vendedor",1,1,.F.})                       // 6

   aAdd(aCab,"Verba")                                       // 7
   aAdd(aCabXML,{"Verba",1,1,.F.})                          // 7
   aAdd(aCab,"Rede")                                        // 8
   aAdd(aCabXML,{"Rede",1,1,.F.})                           // 8

   //---------------------------------------- 
   aAdd(aCab   , "CNPJ")                                    // 8-a
   aAdd(aCabXML,{"CNPJ",1,1,.F.})                           // 8-a
   aAdd(aCab   , "Forma de Pagamento")                      // 8-b
   aAdd(aCabXML,{"Forma de Pagamento",1,1,.F.})             // 8-b
   //----------------------------------------
   
   aAdd(aCab,"Tipo de acordo")                              // 9
   aAdd(aCabXML,{"Tipo de acordo",1,1,.F.})                 // 9
   aAdd(aCab,"Data lançamento")                             // 10
   aAdd(aCabXML,{"Data lançamento",2,4,.F.})                // 10
   aAdd(aCab,"Observação")                                  // 11
   aAdd(aCabXML,{"Observação",1,1,.F.})                     // 11
   aAdd(aCab,"Status")                                      // 12
   aAdd(aCabXML,{"Status",1,1,.F.})                         // 12
   aAdd(aCab,"Contrato")                                    // 13
   aAdd(aCabXML,{"Contrato",1,1,.F.})                       // 13
   aAdd(aCab,"Parcela")                                     // 14 
   aAdd(aCabXML,{"Parcela",2,1,.F.})                        // 14
   aAdd(aCab,"Período vencimento")                          // 15
   aAdd(aCabXML,{"Período vencimento",1,1,.F.})             // 15
   aAdd(aCab,"Data vencimento")                             // 16
   aAdd(aCabXML,{"Data vencimento",2,4,.F.})                // 16
   aAdd(aCab,"Ano vencimento")                              // 17
   aAdd(aCabXML,{"Ano vencimento",2,2,.F.})                 // 17
   aAdd(aCab,"Mes vencimento")                              // 18
   aAdd(aCabXML,{"Mes vencimento",2,2,.F.})                 // 18
   aAdd(aCab,"Total verba")                                 // 19
   aAdd(aCabXML,{"Total verba",3,3,.F.})                    // 19 
   aAdd(aCab,"Efetivado")                                   // 20
   aAdd(aCabXML,{"Efetivado",3,3,.F.})                      // 20
   aAdd(aCab,"Pendente")                                    // 21
   aAdd(aCabXML,{"Pendente",3,3,.F.})                       // 21  
   aAdd(aCab,"Provisão")                                    // 22
   aAdd(aCabXML,{"Provisão",3,3,.F.})                       // 22
   aAdd(aCab   , "Data NCC")                                // 23
   aAdd(aCabXML,{"Data NCC",2,4,.F.})                       // 23
   aAdd(aCab,"Saldo Fin.")                                  // 24
   aAdd(aCabXML,{"Saldo Fin.",3,3,.F.})                     // 24
   //------------------------------------------------------------------------
   aAdd(aCab   , "Favorecido")                              // 25
   aAdd(aCabXML,{"Favorecido",2,1,.F.})                     // 25
   aAdd(aCab   , "Loja Favorecido")                         // 26
   aAdd(aCabXML,{"Loja Favorecido",2,1,.F.})                // 26
   aAdd(aCab   , "CNPJ Favorecido")                         // 27
   aAdd(aCabXML,{"CNPJ Favorecido",2,1,.F.})                // 27
   aAdd(aCab   , "Nome Favorecido")                              // 28
   aAdd(aCabXML,{"Nome Favorecido",2,1,.F.})                     // 28
   aAdd(aCab   , "Regional")                                // 29
   aAdd(aCabXML,{"Regional",2,1,.F.})                       // 29
   aAdd(aCab   , "Provisionado")                            // 30
   aAdd(aCabXML,{"Provisionado",2,1,.F.})                   // 30
   aAdd(aCab   , "Sub. Tipo")                               // 31
   aAdd(aCabXML,{"Sub. Tipo",2,1,.F.})                      // 31
   aAdd(aCab   , "Periodo de Ref.")                         // 32
   aAdd(aCabXML,{"Periodo de Ref.",2,1,.F.})                // 32
   //------------------------------------------------------------------------

   _cQuery += "  SELECT ZK1_CGEREN , ZK1_GERENT , ZK1_CCOODN , ZK1_COODNA , ZK1_CVENDE , ZK1_VENDER , "//********************* COLUNA 01
   _cQuery += "        ZK1_CODIGO  ,"//********************* COLUNA 02

   //---------------------------------------- 
   _cQuery += "         ZK1_FORPAG, ZK1_CLIENT, ZK1_CLILOJ, "
   _cQuery += "         ZK1_FAVORE , ZK1_FAVLOJ , ZK1_PROV, "
   //----------------------------------------

   _cQuery += "        Case"
   _cQuery += "           WHEN TRIM (ZK1_REDES) IS NOT NULL"
   _cQuery += "           THEN"
   _cQuery += "              ZK1_REDES"
   _cQuery += "           WHEN (ZK1_CLIENT <> ' ' AND ZK1_CLILOJ <> ' ')"
   _cQuery += "           THEN"
   _cQuery += "              (SELECT A1_NOME"
   _cQuery += "                 FROM  " + RetSqlName("SA1") + " SA1"
   _cQuery += "                WHERE     A1_FILIAL = ' '"
   _cQuery += "                      AND A1_COD = ZK1_CLIENT"
   _cQuery += "                      AND A1_LOJA = ZK1_CLILOJ"
   _cQuery += "                      AND SA1.D_E_L_E_T_ = ' ')"
   _cQuery += "           Else"
   _cQuery += "              (SELECT A1_NOME"
   _cQuery += "                 FROM  " + RetSqlName("SA1") + " SA1"
   _cQuery += "                WHERE     A1_FILIAL = ' '"
   _cQuery += "                      AND A1_COD = ZK1_CLIENT"
   _cQuery += "                      AND A1_LOJA ="
   _cQuery += "                             (SELECT MIN (A1_LOJA)"
   _cQuery += "                                FROM  " + RetSqlName("SA1") + " SA1B"
   _cQuery += "                               WHERE     SA1B.A1_FILIAL = SA1.A1_FILIAL"
   _cQuery += "                                     AND SA1B.A1_COD = SA1.A1_COD"
   _cQuery += "                                     AND SA1B.D_E_L_E_T_ = ' ')"
   _cQuery += "                      AND SA1.D_E_L_E_T_ = ' ')"
   _cQuery += "        END CLIENTE   ,"//********************* COLUNA 03
   _cQuery += "           ZK1_TIPOAC ,"//********************* COLUNA 04
   _cQuery += "           ZK1_INCLDT ,"//********************* COLUNA 05
   _cQuery += "           ZK1_OBS    ,"//********************* COLUNA 06
   _cQuery += "           ZK1_STATUS ,"//********************* COLUNA 07
   _cQuery += "           ZK3_CONTRA ,"//********************* COLUNA 08
   _cQuery += "           ZK3_PARCEL ,"//********************* COLUNA 09
   //_cQuery += "           TRIM ("
   //_cQuery += "              TO_CHAR ("
   //_cQuery += "                 (TO_DATE (SubStr (ZK3_VENCTO, 1, 6) || '01', 'yyyymmdd')),"
   //_cQuery += "                 'Month'))"
   //_cQuery += "        || '/'"
   //_cQuery += "        || SubStr (ZK3_VENCTO, 1, 4) VENCIMENTO,"//********************* COLUNA 10
   _cQuery += "        ZK3_VENCTO,"                             //********************* COLUNA 11
   _cQuery += "        SubStr (ZK3_VENCTO,1,4) ANO,"            //********************* COLUNA 12
   _cQuery += "        SubStr (ZK3_VENCTO,5,2) MES,"            //********************* COLUNA 13


   _cQuery += "        ZK1_VLRCOR ,"                            //********************* COLUNA 14
   _cQuery += "        DECODE (ZK1_STATUS, '2', ZK3_VALOR,'4', ZK3_VALOR,'6', ZK3_VALOR,  0) EFETIVADO,"//********************* COLUNA 15
   _cQuery += "        DECODE (ZK1_STATUS, '1', ZK3_VALOR, 0) PENDENTE ,                "//********************* COLUNA 16
   _cQuery += "        DECODE (ZK1_STATUS, '5', ZK3_VALOR, 0) PROVISAO ,                  "//********************* COLUNA 17
   _cQuery += "        (SE1.E1_EMISSAO) ZK3_GERAC,  "
   _cQuery += "         SE1.E1_SALDO, "
   _cQuery += "         Case ZK1_SUBITE WHEN '01' THEN 'sell_in/out' "
   _cQuery += "                         WHEN '02' THEN 'Rbxa.Prc' "
   _cQuery += "                         WHEN '03' THEN 'Dt.Critc' "
   _cQuery += "                         WHEN '04' THEN 'Tabl.' "
   _cQuery += "                         WHEN '05' THEN 'Dif.Imp' "
   _cQuery += "                         WHEN '06' THEN 'Int.Prod' "
   _cQuery += "                         WHEN '07' THEN 'Comite' "
   _cQuery += "                         WHEN '08' THEN 'Dif.Prc' "
   _cQuery += "                         WHEN '09' THEN 'Contr' "
   _cQuery += "                         WHEN '10' THEN 'Aniv' "
   _cQuery += "                         WHEN '11' THEN 'Re/Inaug' "
   _cQuery += "                         WHEN '12' THEN 'Mkt/Trade' "
   _cQuery += "                         WHEN '13' THEN 'UHT MGR' "
   _cQuery += "         END AS SUBITE, " //********************* COLUNA
   _cQuery += "         ZK1_ANOMES, "//********************* COLUNA   
   _cQuery += "         ZK1_AGUARD "
   _cQuery += "     FROM " + RetSqlName("ZK3") + " ZK3 "
   _cQuery += "          JOIN " + RetSqlName("ZK1") + " ZK1 ON  ZK1_FILIAL = ZK3_FILIAL   AND ZK1_CODIGO = ZK3_CODIGO  AND ZK1.D_E_L_E_T_ = ' ' "
   _cQuery += "          LEFT JOIN " + RetSqlName("SE1") + " SE1 ON SE1.E1_FILIAL = ZK3.ZK3_TITFIL AND SE1.E1_NUM = ZK3.ZK3_TITULO AND SE1.E1_PARCELA = ZK3.ZK3_TITPAR AND SE1.E1_PREFIXO='VRB' AND SE1.E1_TIPO = 'NCC' AND SE1.D_E_L_E_T_ = ' ' "
   _cQuery += "     WHERE ZK3.D_E_L_E_T_ = ' ' "

   _cQuery:=ROMS78Filtro(@_cQuery)

   _cQuery += " ORDER BY ZK1_GERENT, ZK1_CLIENT, ZK1_CODIGO, ZK3_VENCTO, ZK3_CONTRA, ZK3_PARCEL "

   cTimeINI:=Time()
   MPSysOpenQuery( _cQuery , _cAlias2 )

   DBSelectArea(_cAlias2)
   _nTot:=nConta:=0
   COUNT TO _nTot
   _cTotGeral:=AllTrim(Str(_nTot))

   cTimeFIM:="Hora Incial: "+cTimeINI+" - Hora Final: "+TIME()+" da leitura dos dados"

   (_cAlias2)->(DBGoTop())
   If (_cAlias2)->(Eof())
      U_ITMsg("Não tem Acordos para processamento com esses filtros.",cTimeFIM,"Altere os filtros.",3) 
      Return {}
   EndIf
      
   If !U_ITMsg("Serão processados "+_cTotGeral+' Acordos, Confirma ?',cTimeFIM,,3,2,3,,"CONFIRMA","VOLTAR")
      Return {}
   EndIf
      
   _aDadosRel:={}
   While (_cAlias2)->(!Eof()) //**********************************  While  ******************************************************
            
         If oproc <> NIL
            nConta++
            oproc:cCaption := ("Lendo "+StrZero(nConta,5) +" de "+ _cTotGeral )
            ProcessMessages()
         EndIf

         _cTIPOAC:=""
         If Val((_cAlias2)->ZK1_TIPOAC) > 0 .And. Val((_cAlias2)->ZK1_TIPOAC) <= Len(_aTiposAcor)
            _cTIPOAC:=_aTiposAcor[Val((_cAlias2)->ZK1_TIPOAC)]
         EndIf
         _cSTATUS:=""
         If Val((_cAlias2)->ZK1_STATUS) > 0 .And. Val((_cAlias2)->ZK1_STATUS) <= Len(_aStatus)
            _cSTATUS:=_aStatus[Val((_cAlias2)->ZK1_STATUS)]
         EndIf

         _aProd := {}
         aAdd(_aProd ,(_cAlias2)->ZK1_CGEREN)      // 1
         aAdd(_aProd ,(_cAlias2)->ZK1_GERENT)      // 2
         aAdd(_aProd ,(_cAlias2)->ZK1_CCOODN)      // 3
         aAdd(_aProd ,(_cAlias2)->ZK1_COODNA)      // 4
         aAdd(_aProd ,(_cAlias2)->ZK1_CVENDE)      // 5
         aAdd(_aProd ,(_cAlias2)->ZK1_VENDER)      // 6

         aAdd(_aProd ,(_cAlias2)->ZK1_CODIGO)      // 7
         aAdd(_aProd ,(_cAlias2)->CLIENTE)         // 8
   //------------------------------------------------------------ CNPJ 
   //------------------------------------------------------------ Forma de pagamento
         _cCnpj := " "

         If !Empty((_cAlias2)->ZK1_CLIENT) .And. !Empty((_cAlias2)->ZK1_CLILOJ) 
            _cCnpj := Posicione('SA1',1,xFilial('SA1')+(_cAlias2)->ZK1_CLIENT+(_cAlias2)->ZK1_CLILOJ,'A1_CGC')   
         ElseIf !Empty((_cAlias2)->ZK1_CLIENT)
            _cCnpj := Posicione('SA1',1,xFilial('SA1')+(_cAlias2)->ZK1_CLIENT,'A1_CGC')    
         EndIf 

         If ! Empty(_cCnpj)
            _cCnpj := Transform( _cCnpj , "@R! NN.NNN.NNN/NNNN-99" )
         EndIf 

         aAdd(_aProd ,_cCnpj)           // 
   //-----------------------------------------         
         _cFormaPgto := ""
         If (_cAlias2)->ZK1_FORPAG == "1"
            _cFormaPgto := "BOLETO"   
         ElseIf (_cAlias2)->ZK1_FORPAG == "2"
            _cFormaPgto := "DESCONTO"
         ElseIf (_cAlias2)->ZK1_FORPAG == "3"
            _cFormaPgto := "DEPOSITO"
         EndIf 
         aAdd(_aProd ,_cFormaPgto)           //  
   //------------------------------------------------------------

         aAdd(_aProd ,_cTIPOAC)                    // 9
         aAdd(_aProd ,SToD((_cAlias2)->ZK1_INCLDT))// 10 
         aAdd(_aProd ,(_cAlias2)->ZK1_OBS)         // 11
         aAdd(_aProd ,_cSTATUS)                    // 12
         aAdd(_aProd ,(_cAlias2)->ZK3_CONTRA)      // 13
         aAdd(_aProd ,(_cAlias2)->ZK3_PARCEL)      // 14 
         aAdd(_aProd ,_aMes[Val((_cAlias2)->MES)]+"/"+(_cAlias2)->ANO)//(_cAlias2)->VENCIMENTO)  // 15
         aAdd(_aProd ,SToD((_cAlias2)->ZK3_VENCTO))// 16
         aAdd(_aProd ,(_cAlias2)->ANO)             // 17
         aAdd(_aProd ,(_cAlias2)->MES)             // 18
         aAdd(_aProd ,(_cAlias2)->ZK1_VLRCOR)      // 19
         aAdd(_aProd ,(_cAlias2)->EFETIVADO)       // 20
         aAdd(_aProd ,(_cAlias2)->PENDENTE)        // 21
         aAdd(_aProd ,(_cAlias2)->PROVISAO)        // 22
         aAdd(_aProd ,SToD((_cAlias2)->ZK3_GERAC)) // 23
         aAdd(_aProd ,(_cAlias2)->E1_SALDO)        // 24
   //--------------------------------------------------------------------------- Favorecido  
         _cCnpjFavo := ""
         _cNomeFavo := ""
         _cRegional := ""

         If !Empty((_cAlias2)->ZK1_FAVORE) .And. !Empty((_cAlias2)->ZK1_FAVLOJ) 
            DBSelectArea("SA1")
            DBSetOrder(1)
            If DBSeek(xFilial('SA1')+(_cAlias2)->ZK1_FAVORE+(_cAlias2)->ZK1_FAVLOJ)
               _cCnpjFavo := SA1->A1_CGC
               _cNomeFavo := SA1->A1_NOME
               DBSelectArea("SA3")
               DBSetOrder(1)
               If DBSeek(xFilial('SA3')+SA1->A1_VEND)
                  cGeren := SA3->A3_GEREN
                  cCoord := SA3->A3_SUPER

                  DBSelectArea("ZAM")
                  DBSetOrder(1)
                  If DBSeek(xFilial('ZAM')+cCoord+cGeren)
                     _cRegional := ZAM->ZAM_REGCOD + " - " + Tabela("ZC", ZAM->ZAM_REGCOD, .F.)
                  EndIf

               EndIf
            EndIf
               
         ElseIf !Empty((_cAlias2)->ZK1_FAVORE)
            DBSelectArea("SA1")
            DBSetOrder(1)
            If DBSeek(xFilial('SA1')+(_cAlias2)->ZK1_FAVORE)
               _cCnpjFavo := SA1->A1_CGC
               _cNomeFavo := SA1->A1_NOME
               DBSelectArea("SA3")
               DBSetOrder(1)
               If DBSeek(xFilial('SA3')+SA1->A1_VEND)
                  cGeren := SA3->A3_GEREN
                  DBSelectArea("SA3")
                  DBSetOrder(1)
                  If DBSeek(xFilial('SA3')+cGeren)
                     _cRegional := SA3->A3_I_REGIS
                  EndIf
               EndIf
            EndIf
         EndIf 

         If ! Empty(_cCnpjFavo)
            _cCnpjFavo := Transform( _cCnpjFavo , "@R! NN.NNN.NNN/NNNN-99" )
         EndIf 

         aAdd(_aProd ,(_cAlias2)->ZK1_FAVORE)          // 25
         aAdd(_aProd ,(_cAlias2)->ZK1_FAVLOJ)          // 26
         aAdd(_aProd ,_cCnpjFavo)                      // 27
         aAdd(_aProd ,_cNomeFavo)                      // 28
         aAdd(_aProd ,_cRegional)                      // 29

         _cProvisao := " "
         If (_cAlias2)->ZK1_PROV == "S"
            _cProvisao := "SIM"
         ElseIf (_cAlias2)->ZK1_PROV == "N"   
            _cProvisao := "NÃO" 
         EndIf 
         aAdd(_aProd ,_cProvisao)                      // 30
         aAdd(_aProd ,(_cAlias2)->SUBITE)                // 31
         aAdd(_aProd ,SubStr((_cAlias2)->ZK1_ANOMES,1,2)+'/'+SubStr((_cAlias2)->ZK1_ANOMES,3,4))                // 32
         aAdd(_aProd ,(_cAlias2)->ZK1_AGUARD) //33 
         aAdd(_aDadosRel , _aProd  )
               
         (_cAlias2)->(DBSkip())
      
   EndDo


ElseIf AllToChar(MV_PAR01) = "3"// ************************************************************************************

   // Alinhamento: 1-Left   ,2-Center,3-Right
   // Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
   //             Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
   //   (aCabXML,{Titulo             ,1           ,1         ,.F.       })
   aAdd(aCab,"Cod Gerente")                              // 1
   aAdd(aCabXML,{"Cod Gerente",1,1,.F.})                 // 1 
   aAdd(aCab,"Gerente")                                  // 2 
   aAdd(aCabXML,{"Gerente",1,1,.F.})                     // 2
   aAdd(aCab,"Cod Coordenador")                          // 3
   aAdd(aCabXML,{"Cod Coordenador",1,1,.F.})             // 3
   aAdd(aCab,"Coordenador")                              // 4
   aAdd(aCabXML,{"Coordenador",1,1,.F.})                 // 4
   aAdd(aCab,"Cod Vendedor")                             // 5
   aAdd(aCabXML,{"Cod Vendedor",1,1,.F.})                // 5
   aAdd(aCab,"Vendedor")                                 // 6
   aAdd(aCabXML,{"Vendedor",1,1,.F.})                    // 6

   aAdd(aCab,"Verba")                                    // 7
   aAdd(aCabXML,{"Verba" ,1,1,.F.})                      // 7
   aAdd(aCab,"Rede")                                  // 8
   aAdd(aCabXML,{"Rede" ,1,1,.F.})                    // 8

   //---------------------------------------- 
   aAdd(aCab   , "CNPJ")                                // 8-a
   aAdd(aCabXML,{"CNPJ",1,1,.F.})                       // 8-a
   aAdd(aCab   , "Forma de Pagamento")                  // 8-b
   aAdd(aCabXML,{"Forma de Pagamento",1,1,.F.})         // 8-b
   //----------------------------------------

   aAdd(aCab,"Observação")                               // 9
   aAdd(aCabXML,{"Observação" ,1,1,.F.})                 // 9
   aAdd(aCab,"Efetivado")                                // 10
   aAdd(aCabXML,{"Efetivado" ,3,3,.F.})                  // 10
   aAdd(aCab,"Pendente")                                 // 11
   aAdd(aCabXML,{"Pendente" ,3,3,.F.})                   // 11
   aAdd(aCab,"Valor Item")                                 // 11
   aAdd(aCabXML,{"Valor Item" ,3,3,.F.})                   // 11
   aAdd(aCab,"Produto")                                  // 12
   aAdd(aCabXML,{"Produto" ,1,1,.F.})                    // 12
   aAdd(aCab,"Descrição")                                // 13
   aAdd(aCabXML,{"Descrição" ,1,1,.F.})                  // 13
   aAdd(aCab,"Rateio")                                   // 14
   aAdd(aCabXML,{"Rateio" ,3,3,.F.})                     // 14
   aAdd(aCab,"% Rateio")                                 // 15
   aAdd(aCabXML,{"% Rateio",3,2,.F.})                    // 15
   aAdd(aCab   , "Data NCC")                             // 16
   aAdd(aCabXML,{"Data NCC",2,4,.F.})                    // 16
   aAdd(aCab,"Saldo Fin.")                                 // 17
   aAdd(aCabXML,{"Saldo Fin.",3,2,.F.})                    // 17
   //-----------------------------------------------------------------------
   aAdd(aCab   , "Favorecido")                           // 18
   aAdd(aCabXML,{"Favorecido",2,1,.F.})                  // 18
   aAdd(aCab   , "Loja Favorecido")                      // 19
   aAdd(aCabXML,{"Loja Favorecido",2,1,.F.})             // 19
   aAdd(aCab   , "CNPJ Favorecido")                      // 20
   aAdd(aCabXML,{"CNPJ Favorecido",2,1,.F.})             // 20
   aAdd(aCab   , "Nome Favorecido")                              // 21
   aAdd(aCabXML,{"Nome Favorecido",2,1,.F.})                     // 21
   aAdd(aCab   , "Regional")                                // 22
   aAdd(aCabXML,{"Regional",2,1,.F.})                       // 22
   aAdd(aCab   , "Provisionado")                         // 21
   aAdd(aCabXML,{"Provisionado"   ,2,1,.F.})             // 21
   aAdd(aCab   , "Sub. Tipo")                    // 22
   aAdd(aCabXML,{"Sub. Tipo",2,1,.F.})          // 22
   aAdd(aCab   , "Periodo de Ref.")                    // 23
   aAdd(aCabXML,{"Periodo de Ref.",2,1,.F.})          // 23

   aAdd(aCab   , "Qtd. 2a Unid.")                 // 24
   aAdd(aCabXML,{"Qtd. 2a Unid.",1,1,.F.})        // 24
   aAdd(aCab   , "Contrato")                              // 25
   aAdd(aCabXML,{"Contrato",2,1,.F.})                     // 25
   aAdd(aCab   , "Vencimento")                             // 26
   aAdd(aCabXML,{"Vencimento",2,4,.F.})                    // 26

   //------------------------------------------------------------------------

   _cQuery += "SELECT ZK1_CGEREN , ZK1_GERENT , ZK1_CCOODN , ZK1_COODNA , ZK1_CVENDE , ZK1_VENDER ,   "//********************* COLUNA 01
   _cQuery += "       ZK1_CODIGO , ZK1_PROV,   "//********************* COLUNA 02

   //------------------------------------------------------------- 
   _cQuery += "         ZK1_FORPAG, ZK1_CLIENT, ZK1_CLILOJ, "
   _cQuery += "         ZK1_FAVORE , ZK1_FAVLOJ ,  "
   //-------------------------------------------------------------

   _cQuery += "         Case  "
   _cQuery += "            WHEN TRIM (ZK1_REDES) IS NOT NULL  "
   _cQuery += "            THEN  "
   _cQuery += "               ZK1_REDES "
   _cQuery += "            WHEN (ZK1_CLIENT <> ' ' AND ZK1_CLILOJ <> ' ')  "
   _cQuery += "            THEN  "
   _cQuery += "               (SELECT A1_NOME  "
   _cQuery += "                  FROM " + RetSqlName("SA1") + " SA1  "
   _cQuery += "                 WHERE     A1_FILIAL = ' '  "
   _cQuery += "                       AND A1_COD  = ZK1_CLIENT  "
   _cQuery += "                       AND A1_LOJA = ZK1_CLILOJ  "
   _cQuery += "                       AND SA1.D_E_L_E_T_ = ' ')  "
   _cQuery += "            Else "
   _cQuery += "               (SELECT A1_NOME  "
   _cQuery += "                  FROM " + RetSqlName("SA1") + " SA1  "
   _cQuery += "                 WHERE     A1_FILIAL = ' '  "
   _cQuery += "                       AND A1_COD = ZK1_CLIENT  "
   _cQuery += "                       AND A1_LOJA =  "
   _cQuery += "                              (SELECT MIN (A1_LOJA)  "
   _cQuery += "                                 FROM " + RetSqlName("SA1") + " SA1B  "
   _cQuery += "                                WHERE     SA1B.A1_FILIAL = SA1.A1_FILIAL  "
   _cQuery += "                                      AND SA1B.A1_COD = SA1.A1_COD  "
   _cQuery += "                                      AND SA1B.D_E_L_E_T_ = ' ')  "
   _cQuery += "                       AND SA1.D_E_L_E_T_ = ' ')  "
   _cQuery += "         END  CLIENTE, "//********************* COLUNA 03
   _cQuery += "         ZK1_OBS     , "//********************* COLUNA 04
   _cQuery += "         DECODE (ZK1_STATUS, '2', ZK1_VLRCOR,'4', ZK1_VLRCOR,'6', ZK1_VLRCOR, 0) EFETIVADO,  "
   _cQuery += "         DECODE (ZK1_STATUS, '1', ZK1_VLRCOR, 0) PENDENTE,  "        
   //_cQuery += "        Case WHEN ZK2_RATEIO IS NuLL THEN ZK1_VLRCOR Else ZK2_RATEIO END  VALITEM, "
   _cQuery += " Case WHEN ZK2_PRODUT LIKE 'G%' THEN ZK2_VRFATM "
   _cQuery += " WHEN ZK2_RATEIO IS NULL THEN ZK1_VLRCOR "
   _cQuery += " Else ZK2_RATEIO END VALITEM, "
   //********************* COLUNA 06
   _cQuery += "         ZK2_PRODUT ,  "//********************* COLUNA 07
   _cQuery += "         ZK2_DESCRI ,  "//********************* COLUNA 08
   _cQuery += "         ZK2_RATEIO ,  "//********************* COLUNA 09
   _cQuery += "         ZK2_RATPER ,  "//********************* COLUNA 10
   _cQuery += "         ZK3_GERAC  ,  " 
   _cQuery += "         ZK3_VENCTO ,  " 
   _cQuery += "         ZK3_CONTRA ,  "   
   _cQuery += "         ZK2_QPED2U SEGUNID , "
   _cQuery += "         Case ZK1_SUBITE WHEN '01' THEN 'sell_in/out' WHEN '02' THEN 'Rbxa.Prc' WHEN '03' THEN 'Dt.Critc' "
   _cQuery += "         WHEN '04' THEN 'Tabl.' WHEN '05' THEN 'Dif.Imp' WHEN '06' THEN 'Int.Prod' WHEN '07' THEN 'Comite' "
   _cQuery += "         WHEN '08' THEN 'Dif.Prc' WHEN '09' THEN 'Contr' WHEN '10' THEN 'Aniv' WHEN '11' THEN 'Re/Inaug' "
   _cQuery += "         WHEN '12' THEN 'Mkt/Trade' WHEN '13' THEN 'UHT MGR' END AS SUBITE, " //********************* COLUNA
   _cQuery += "         ZK1_ANOMES, "//********************* COLUNA 
   _cQuery += "         E1_SALDO "
   _cQuery += "    FROM " + RetSqlName("ZK1") + " ZK1 "
   _cQuery += "        LEFT JOIN " + RetSqlName("ZK2") + " ZK2 ON  ZK2_CODIGO = ZK1_CODIGO AND ZK2.D_E_L_E_T_ = ' ' "
   _cQuery += "         AND ZK2_FILIAL = ' '  "
   _cQuery += "         AND ZK2_TIPREG = 'I'  "
   _cQuery += "        LEFT JOIN (  SELECT ZK3_FILIAL, ZK3_CODIGO,  "
   _cQuery += "                   SUM (ZK3_VALOR) ZK3_VALOR,  "
   _cQuery += "                   MIN (ZK3_VENCTO) ZK3_VENCTO , "
   _cQuery += "                   MIN (ZK3_CONTRA) ZK3_CONTRA , "
   _cQuery += "                   MIN (E1_EMISSAO) ZK3_GERAC , "
   _cQuery += "                   SUM (E1_SALDO) E1_SALDO "  
   _cQuery += "              FROM " + RetSqlName("ZK3") + "  ZK3_A"
   _cQuery += "                   LEFT JOIN " + RetSqlName("SE1") + " SE1 ON SE1.E1_FILIAL = ZK3_A.ZK3_TITFIL AND SE1.E1_NUM = ZK3_A.ZK3_TITULO AND SE1.E1_PARCELA = ZK3_A.ZK3_TITPAR AND SE1.E1_PREFIXO='VRB' AND SE1.E1_TIPO = 'NCC' AND SE1.D_E_L_E_T_ = ' ' ""
   _cQuery += "             WHERE ZK3_A.D_E_L_E_T_ = ' '  "
   //"Vencimento de: "+AllTrim(AllToChar(MV_PAR04))+" ate "+AllTrim(AllToChar(MV_PAR05))+CRLF+;
   If !Empty(MV_PAR04)
      _cQuery += "  AND ZK3_VENCTO >= '" + DToS(MV_PAR04)+"' "
   EndIf   
   If !Empty(MV_PAR05)
      _cQuery += "  AND ZK3_VENCTO <= '" + DToS(MV_PAR05)+"' "
   EndIf
   _cQuery += "          GROUP BY ZK3_FILIAL, ZK3_CODIGO ) ZK3 ON  ZK1_FILIAL = ZK3_FILIAL   AND ZK1_CODIGO = ZK3_CODIGO  "
   _cQuery += "   WHERE     ZK1_STATUS not in ('3','5')  "
   _cQuery += "         AND ZK1.D_E_L_E_T_ = ' '  "
   //_cQuery += "         AND ZK2_FILIAL = ' '  "
   //_cQuery += "         AND ZK2_TIPREG = 'I'  "

   _cQuery := ROMS78Filtro(@_cQuery)

   _cQuery += " ORDER BY ZK1_GERENT, ZK1_CODIGO, ZK2_DESCRI "
      
   cTimeINI:=Time()

   MPSysOpenQuery( _cQuery , _cAlias2 )

   DBSelectArea(_cAlias2)
   _nTot:=nConta:=0
   COUNT TO _nTot
   _cTotGeral:=AllTrim(Str(_nTot))

   cTimeFIM:="Hora Incial: "+cTimeINI+" - Hora Final: "+TIME()+" da leitura dos dados"

   (_cAlias2)->(DBGoTop())
   If (_cAlias2)->(Eof())
      U_ITMsg("Não tem Acordos para processamento com esses filtros.",cTimeFIM,"Altere os filtros.",3) 
      Return {}
   EndIf
      
   If !U_ITMsg("Serão processados "+_cTotGeral+' Acordos, Confirma ?',cTimeFIM,,3,2,3,,"CONFIRMA","VOLTAR")
      Return {}
   EndIf
      
   _aDadosRel:={}
   While (_cAlias2)->(!Eof()) //**********************************  While  ******************************************************
            
         If oproc <> NIL
            nConta++
            oproc:cCaption := ("Lendo "+StrZero(nConta,5) +" de "+ _cTotGeral )
            ProcessMessages()
         EndIf

         _aProd := {}
         aAdd(_aProd ,(_cAlias2)->ZK1_CGEREN)       // 1 
         aAdd(_aProd ,(_cAlias2)->ZK1_GERENT)       // 2
         aAdd(_aProd ,(_cAlias2)->ZK1_CCOODN)       // 3
         aAdd(_aProd ,(_cAlias2)->ZK1_COODNA)       // 4
         aAdd(_aProd ,(_cAlias2)->ZK1_CVENDE)       // 5
         aAdd(_aProd ,(_cAlias2)->ZK1_VENDER)       // 6

         aAdd(_aProd ,(_cAlias2)->ZK1_CODIGO)       // 7
         aAdd(_aProd ,(_cAlias2)->CLIENTE   )       // 8
         //------------------------------------------------------------ CNPJ 
         //------------------------------------------------------------ Forma de pagamento
         _cCnpj := " "

         If !Empty((_cAlias2)->ZK1_CLIENT) .And. !Empty((_cAlias2)->ZK1_CLILOJ) 
            _cCnpj := Posicione('SA1',1,xFilial('SA1')+(_cAlias2)->ZK1_CLIENT+(_cAlias2)->ZK1_CLILOJ,'A1_CGC')   
         ElseIf !Empty((_cAlias2)->ZK1_CLIENT)
            _cCnpj := Posicione('SA1',1,xFilial('SA1')+(_cAlias2)->ZK1_CLIENT,'A1_CGC')    
         EndIf 
         
         If ! Empty(_cCnpj)
            _cCnpj := Transform( _cCnpj , "@R! NN.NNN.NNN/NNNN-99" )
         EndIf 

         aAdd(_aProd ,_cCnpj)           
         //-----------------------------------------         
         _cFormaPgto := ""
         If (_cAlias2)->ZK1_FORPAG == "1"
            _cFormaPgto := "BOLETO"   
         ElseIf (_cAlias2)->ZK1_FORPAG == "2"
            _cFormaPgto := "DESCONTO"
         ElseIf (_cAlias2)->ZK1_FORPAG == "3"
            _cFormaPgto := "DEPOSITO"
         EndIf 
         aAdd(_aProd ,_cFormaPgto)           //  
         //------------------------------------------------------------

         aAdd(_aProd ,(_cAlias2)->ZK1_OBS   )       // 9
         aAdd(_aProd ,(_cAlias2)->EFETIVADO )       // 10
         aAdd(_aProd ,(_cAlias2)->PENDENTE  )       // 11
         aAdd(_aProd ,(_cAlias2)->VALITEM)
         aAdd(_aProd ,(_cAlias2)->ZK2_PRODUT)       // 12
         aAdd(_aProd ,(_cAlias2)->ZK2_DESCRI)       // 13
         aAdd(_aProd ,(_cAlias2)->ZK2_RATEIO)       // 14
         aAdd(_aProd ,(_cAlias2)->ZK2_RATPER)       // 15
         aAdd(_aProd ,SToD((_cAlias2)->ZK3_GERAC )) // 16
         aAdd(_aProd ,(_cAlias2)->E1_SALDO)       // 17
   //--------------------------------------------------------------------------- Favorecido  
         _cCnpjFavo := ""
         _cNomeFavo := ""
         _cRegional := ""

         If !Empty((_cAlias2)->ZK1_FAVORE) .And. !Empty((_cAlias2)->ZK1_FAVLOJ) 
            DBSelectArea("SA1")
            DBSetOrder(1)
            If DBSeek(xFilial('SA1')+(_cAlias2)->ZK1_FAVORE+(_cAlias2)->ZK1_FAVLOJ)
               _cCnpjFavo := SA1->A1_CGC
               _cNomeFavo := SA1->A1_NOME
               DBSelectArea("SA3")
               DBSetOrder(1)
               If DBSeek(xFilial('SA3')+SA1->A1_VEND)
                  cGeren := SA3->A3_GEREN
                  cCoord := SA3->A3_SUPER

                  DBSelectArea("ZAM")
                  DBSetOrder(1)
                  If DBSeek(xFilial('ZAM')+cCoord+cGeren)
                     _cRegional := ZAM->ZAM_REGCOD + " - " + Tabela("ZC", ZAM->ZAM_REGCOD, .F.)
                  EndIf
               EndIf
            EndIf
               
         ElseIf !Empty((_cAlias2)->ZK1_FAVORE)
            DBSelectArea("SA1")
            DBSetOrder(1)
            If DBSeek(xFilial('SA1')+(_cAlias2)->ZK1_FAVORE)
               _cCnpjFavo := SA1->A1_CGC
               _cNomeFavo := SA1->A1_NOME
               DBSelectArea("SA3")
               DBSetOrder(1)
               If DBSeek(xFilial('SA3')+SA1->A1_VEND)
                  cGeren := SA3->A3_GEREN
                  cCoord := SA3->A3_SUPER

                  DBSelectArea("ZAM")
                  DBSetOrder(1)
                  If DBSeek(xFilial('ZAM')+cCoord+cGeren)
                     _cRegional := ZAM->ZAM_REGCOD + " - " + Tabela("ZC", ZAM->ZAM_REGCOD, .F.)
                  EndIf
               EndIf
            EndIf
         EndIf 

         If ! Empty(_cCnpjFavo)
            _cCnpjFavo := Transform( _cCnpjFavo , "@R! NN.NNN.NNN/NNNN-99" )
         EndIf 

         aAdd(_aProd ,(_cAlias2)->ZK1_FAVORE)       // 18
         aAdd(_aProd ,(_cAlias2)->ZK1_FAVLOJ)       // 19 
         aAdd(_aProd ,_cCnpjFavo)                   // 20
         aAdd(_aProd ,_cNomeFavo)                      // 21
         aAdd(_aProd ,_cRegional)                      // 22

         _cProvisao := " "
         If (_cAlias2)->ZK1_PROV == "S"
            _cProvisao := "SIM"
         ElseIf (_cAlias2)->ZK1_PROV == "N"   
            _cProvisao := "NÃO" 
         EndIf 
         aAdd(_aProd ,_cProvisao)                   // 23

         aAdd(_aProd ,(_cAlias2)->SUBITE)                // 24
         aAdd(_aProd ,SubStr((_cAlias2)->ZK1_ANOMES,1,2)+'/'+SubStr((_cAlias2)->ZK1_ANOMES,3,4))                // 25
         aAdd(_aProd, (_cAlias2)->SEGUNID)

         aAdd(_aProd, (_cAlias2)->ZK3_CONTRA)
         aAdd(_aProd, DToC(SToD((_cAlias2)->ZK3_VENCTO)))

         aAdd(_aDadosRel , _aProd  )
               
         (_cAlias2)->(DBSkip())
      
   EndDo


ElseIf AllToChar(MV_PAR01) = "4"////////////////////////////////////////////////////////////////////////////

   // Alinhamento: 1-Left   ,2-Center,3-Right
   // Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
   //             Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
   //   (aCabXML,{Titulo             ,1           ,1         ,.F.       })
   aAdd(aCab,"Cod Gerente")                             // 1 
   aAdd(aCabXML,{"Cod Gerente",1,1,.F.})                // 1
   aAdd(aCab,"Gerente")                                 // 2
   aAdd(aCabXML,{"Gerente",1,1,.F.})                    // 2
   aAdd(aCab,"Cod Coordenador")                         // 3
   aAdd(aCabXML,{"Cod Coordenador",1,1,.F.})            // 3
   aAdd(aCab,"Coordenador")                             // 4
   aAdd(aCabXML,{"Coordenador",1,1,.F.})                // 4
   aAdd(aCab,"Cod Vendedor")                            // 5
   aAdd(aCabXML,{"Cod Vendedor",1,1,.F.})               // 5
   aAdd(aCab,"Vendedor")                                // 6
   aAdd(aCabXML,{"Vendedor",1,1,.F.})                   // 6

   aAdd(aCab,"Verba")                                   // 7
   aAdd(aCabXML,{"Verba",1,1,.F.})                      // 7
   aAdd(aCab,"Rede")                                 // 8
   aAdd(aCabXML,{"Rede",1,1,.F.})                    // 8

   //---------------------------------------- 
   aAdd(aCab   , "CNPJ")                                // 8-a
   aAdd(aCabXML,{"CNPJ",1,1,.F.})                       // 8-a
   aAdd(aCab   , "Forma de Pagamento")                  // 8-b
   aAdd(aCabXML,{"Forma de Pagamento",1,1,.F.})         // 8-b
   //----------------------------------------

   aAdd(aCab,"Tipo de acordo")                          // 9
   aAdd(aCabXML,{"Tipo de acordo",1,1,.F.})             // 9
   aAdd(aCab,"Observação")                              // 10
   aAdd(aCabXML,{"Observação",1,1,.F.})                 // 10
   aAdd(aCab,"Data lançamento")                         // 11
   aAdd(aCabXML,{"Data lançamento",2,4,.F.})            // 11
   aAdd(aCab,"Vencimento")                              // 12
   aAdd(aCabXML,{"Vencimento",1,1,.F.})                 // 12
   aAdd(aCab,"Total da verba")                          // 13
   aAdd(aCabXML,{"Total da verba",3,3,.F.})             // 13
   aAdd(aCab,"Total parcela")                           // 14
   aAdd(aCabXML,{"Total parcela",3,3,.F.})              // 14
   aAdd(aCab,"Produto")                                 // 15
   aAdd(aCabXML,{"Produto",1,1,.F.})                    // 15
   aAdd(aCab,"Descrição")                               // 16
   aAdd(aCabXML,{"Descrição",1,1,.F.})                  // 16
   aAdd(aCab,"% Verba")                                 // 17 
   aAdd(aCabXML,{"% Verba",3,2,.F.})                    // 17 
   aAdd(aCab,"Rateio")                                  // 18
   aAdd(aCabXML,{"Rateio",3,3,.F.})                     // 18
   aAdd(aCab,"% Rateio")                                // 19
   aAdd(aCabXML,{"% Rateio",3,2,.F.})                   // 19
   aAdd(aCab   , "Data NCC")                            // 20
   aAdd(aCabXML,{"Data NCC",2,4,.F.})                   // 20
   aAdd(aCab   , "Saldo Fin")                           // 21
   aAdd(aCabXML,{"Saldo Fin",3,3,.F.})                  // 21

   //------------------------------------------------------------------------
   aAdd(aCab   , "Favorecido")                          // 22
   aAdd(aCabXML,{"Favorecido",2,1,.F.})                 // 22
   aAdd(aCab   , "Loja Favorecido")                     // 23
   aAdd(aCabXML,{"Loja Favorecido",2,1,.F.})            // 23
   aAdd(aCab   , "CNPJ Favorecido")                     // 24
   aAdd(aCabXML,{"CNPJ Favorecido",2,1,.F.})            // 24
   aAdd(aCab   , "Provisionado")                        // 25
   aAdd(aCabXML,{"Provisionado",2,1,.F.})               // 25
   aAdd(aCab   , "Regional")                            // 26
   aAdd(aCabXML,{"Regional",2,1,.F.})                   // 26
   aAdd(aCab   , "Periodo de Ref.")                     // 27
   aAdd(aCabXML,{"Periodo de Ref.",2,1,.F.})            // 27
   //------------------------------------------------------------------------

   _cQuery += "  SELECT ZK1_CGEREN , ZK1_GERENT , ZK1_CCOODN , ZK1_COODNA , ZK1_CVENDE , ZK1_VENDER ,  "//********************* COLUNA 01
   _cQuery += "         ZK1_CODIGO ,  "//********************* COLUNA 02
   
   //-------------------------------------------------------------- 
   _cQuery += "         ZK1_FORPAG, ZK1_CLIENT, ZK1_CLILOJ, "
   _cQuery += "         ZK1_FAVORE , ZK1_FAVLOJ , ZK1_PROV,  "
   //--------------------------------------------------------------

   _cQuery += "         Case  "
   _cQuery += "            WHEN TRIM (ZK1_REDES) IS NOT NULL  "
   _cQuery += "            THEN  "
   _cQuery += "               ZK1_REDES  "
   _cQuery += "            WHEN (ZK1_CLIENT <> ' ' AND ZK1_CLILOJ <> ' ')  "
   _cQuery += "            THEN  "
   _cQuery += "               (SELECT A1_NOME  "
   _cQuery += "                  FROM " + RetSqlName("SA1") + " SA1  "
   _cQuery += "                 WHERE     A1_FILIAL = ' '  "
   _cQuery += "                       AND A1_COD = ZK1_CLIENT  "
   _cQuery += "                       AND A1_LOJA = ZK1_CLILOJ  "
   _cQuery += "                       AND SA1.D_E_L_E_T_ = ' ')  "
   _cQuery += "            Else  "
   _cQuery += "               (SELECT A1_NOME  "
   _cQuery += "                  FROM " + RetSqlName("SA1") + " SA1  "
   _cQuery += "                 WHERE     A1_FILIAL = ' '  "
   _cQuery += "                       AND A1_COD = ZK1_CLIENT  "
   _cQuery += "                       AND A1_LOJA =  "
   _cQuery += "                              (SELECT MIN (A1_LOJA)  "
   _cQuery += "                                 FROM " + RetSqlName("SA1") + " SA1B  "
   _cQuery += "                                WHERE     SA1B.A1_FILIAL = SA1.A1_FILIAL  "
   _cQuery += "                                      AND SA1B.A1_COD = SA1.A1_COD  "
   _cQuery += "                                      AND SA1B.D_E_L_E_T_ = ' ')  "
   _cQuery += "                       AND SA1.D_E_L_E_T_ = ' ')   END CLIENTE, "//********************* COLUNA 03
   _cQuery += "            ZK1_TIPOAC, "//********************* COLUNA 04
   _cQuery += "            ZK1_OBS   , "//********************* COLUNA 05
   _cQuery += "            ZK1_INCLDT, "//********************* COLUNA 06
   //_cQuery += "            TRIM (TO_CHAR ( (TO_DATE (VENCTO, 'yyyymmdd')), 'Month')) || '/'  "
   //_cQuery += "         || SubStr (VENCTO, 1, 4)  VENCIMENTO,  "//********************* COLUNA 07
   _cQuery += "         SubStr (VENCTO,1,4) ANO," //********************* COLUNA 07
   _cQuery += "         SubStr (VENCTO,5,2) MES," //********************* COLUNA 07
   _cQuery += "         ZK1_VLRCOR  ,  "//********************* COLUNA 08
   _cQuery += "         ZK3_VALOR   ,  "//********************* COLUNA 09
   _cQuery += "         ZK2_PRODUT  ,  "//********************* COLUNA 10
   _cQuery += "         ZK2_DESCRI  ,  "//********************* COLUNA 11
   _cQuery += "         Round ( ( (ZK3_VALOR / ZK1_VLRCOR) * 100), 5) PERC_VERBA,  " //********************* COLUNA 12
   _cQuery += "         Round (   (ZK2_RATEIO * (TRUNC ( ( (ZK3_VALOR / ZK1_VLRCOR) * 100), 5)) / 100), 2)  RATEIO,  " //********************* COLUNA 13
   _cQuery += "         ZK2_RATPER,  "//********************* COLUNA 14
   _cQuery += "         ZK3_GERAC ,  "//********************* COLUNA 15
   _cQuery += "         Case ZK1_SUBITE WHEN '01' THEN 'sell_in/out' WHEN '02' THEN 'Rbxa.Prc' WHEN '03' THEN 'Dt.Critc' "
   _cQuery += "         WHEN '04' THEN 'Tabl.' WHEN '05' THEN 'Dif.Imp' WHEN '06' THEN 'Int.Prod' WHEN '07' THEN 'Comite' "
   _cQuery += "         WHEN '08' THEN 'Dif.Prc' WHEN '09' THEN 'Contr' WHEN '10' THEN 'Aniv' WHEN '11' THEN 'Re/Inaug' "
   _cQuery += "         WHEN '12' THEN 'Mkt/Trade' WHEN '13' THEN 'UHT MGR'  END AS SUBITE, " //********************* COLUNA
   _cQuery += "         ZK1_ANOMES, "//********************* COLUNA 
   _cQuery += "         E1_SALDO "
   _cQuery += "    FROM " + RetSqlName("ZK1") + " ZK1, "
   _cQuery += "         " + RetSqlName("ZK2") + " ZK2, "
   _cQuery += "        (  SELECT ZK3_FILIAL, ZK3_CODIGO,  "
   _cQuery += "                   SubStr (ZK3_VENCTO, 1, 6) || '01' VENCTO,  "
   _cQuery += "                   SUM (ZK3_VALOR) ZK3_VALOR,  "
   _cQuery += "                   MIN (E1_EMISSAO) ZK3_GERAC , "
   _cQuery += "                   SUM (E1_SALDO) E1_SALDO "  
   _cQuery += "              FROM " + RetSqlName("ZK3") + "  ZK3_A"
   _cQuery += "                   LEFT JOIN " + RetSqlName("SE1") + " SE1 ON SE1.E1_FILIAL = ZK3_A.ZK3_TITFIL AND SE1.E1_NUM = ZK3_A.ZK3_TITULO AND SE1.E1_PARCELA = ZK3_A.ZK3_TITPAR AND SE1.E1_TIPO = 'NCC' AND SE1.E1_PREFIXO='VRB' AND SE1.D_E_L_E_T_ = ' ' ""
   _cQuery += "             WHERE ZK3_A.D_E_L_E_T_ = ' '  "
   //"Vencimento de: "+AllTrim(AllToChar(MV_PAR04))+" ate "+AllTrim(AllToChar(MV_PAR05))+_ENTER+;
   If !Empty(MV_PAR04)
      _cQuery += "  AND ZK3_VENCTO >= '" + DToS(MV_PAR04)+"' "
   EndIf   
   If !Empty(MV_PAR05)
      _cQuery += "  AND ZK3_VENCTO <= '" + DToS(MV_PAR05)+"' "
   EndIf
   _cQuery += "          GROUP BY ZK3_FILIAL, ZK3_CODIGO, SubStr(ZK3_VENCTO, 1, 6)) ZK3  " //ON  ZK2_FILIAL = ZK3_FILIAL   AND ZK2_CODIGO = ZK3_CODIGO
   _cQuery += "   WHERE     ZK1_STATUS IN ('2', '4')  "
   _cQuery += "         AND ZK1.D_E_L_E_T_ = ' '  "
   _cQuery += "         AND ZK2_FILIAL = ' '  "
   _cQuery += "         AND ZK2_CODIGO = ZK1_CODIGO  "
   _cQuery += "         AND ZK2_TIPREG = 'I'  "
   _cQuery += "         AND ZK2.D_E_L_E_T_ = ' '  "
   _cQuery += "         AND ZK3_CODIGO = ZK1_CODIGO  "

   _cQuery:=ROMS78Filtro(@_cQuery)

   _cQuery += " ORDER BY ZK1_GERENT, ZK1_CODIGO, VENCTO, ZK2_DESCRI "

   cTimeINI:=Time()

   MPSysOpenQuery( _cQuery , _cAlias2 )

   DBSelectArea(_cAlias2)
   _nTot:=nConta:=0
   COUNT TO _nTot
   _cTotGeral:=AllTrim(Str(_nTot))

   cTimeFIM:="Hora Incial: "+cTimeINI+" - Hora Final: "+TIME()+" da leitura dos dados"

   (_cAlias2)->(DBGoTop())
   If (_cAlias2)->(Eof())
      U_ITMsg("Não tem Acordos para processamento com esses filtros.",cTimeFIM,"Altere os filtros.",3) 
      Return {}
   EndIf
      
   If !U_ITMsg("Serão processados "+_cTotGeral+' Acordos, Confirma ?',cTimeFIM,,3,2,3,,"CONFIRMA","VOLTAR")
      Return {}
   EndIf
      
   _aDadosRel:={}
   While (_cAlias2)->(!Eof()) //**********************************  While  ******************************************************
            
         If oproc <> NIL
            nConta++
            oproc:cCaption := ("Lendo "+StrZero(nConta,5) +" de "+ _cTotGeral )
            ProcessMessages()
         EndIf

         _cTIPOAC:=""
         If Val((_cAlias2)->ZK1_TIPOAC) > 0 .And. Val((_cAlias2)->ZK1_TIPOAC) <= Len(_aTiposAcor)
            _cTIPOAC:=_aTiposAcor[Val((_cAlias2)->ZK1_TIPOAC)]
         EndIf

         _aProd := {}
         aAdd(_aProd ,(_cAlias2)->ZK1_CGEREN) // 1
         aAdd(_aProd ,(_cAlias2)->ZK1_GERENT) // 2
         aAdd(_aProd ,(_cAlias2)->ZK1_CCOODN) // 3
         aAdd(_aProd ,(_cAlias2)->ZK1_COODNA) // 4
         aAdd(_aProd ,(_cAlias2)->ZK1_CVENDE) // 5
         aAdd(_aProd ,(_cAlias2)->ZK1_VENDER) // 6

         aAdd(_aProd ,(_cAlias2)->ZK1_CODIGO) // 7 
         aAdd(_aProd ,(_cAlias2)->CLIENTE)    // 8
   //------------------------------------------------------------ CNPJ 
   //------------------------------------------------------------ Forma de pagamento
         _cCnpj := " "

         If !Empty((_cAlias2)->ZK1_CLIENT) .And. !Empty((_cAlias2)->ZK1_CLILOJ) 
            _cCnpj := Posicione('SA1',1,xFilial('SA1')+(_cAlias2)->ZK1_CLIENT+(_cAlias2)->ZK1_CLILOJ,'A1_CGC')   
         ElseIf !Empty((_cAlias2)->ZK1_CLIENT)
            _cCnpj := Posicione('SA1',1,xFilial('SA1')+(_cAlias2)->ZK1_CLIENT,'A1_CGC')    
         EndIf 
         
         If ! Empty(_cCnpj)
            _cCnpj := Transform( _cCnpj , "@R! NN.NNN.NNN/NNNN-99" )
         EndIf 

         aAdd(_aProd ,_cCnpj)         
   //-----------------------------------------         
         _cFormaPgto := ""
         If (_cAlias2)->ZK1_FORPAG == "1"
            _cFormaPgto := "BOLETO"   
         ElseIf (_cAlias2)->ZK1_FORPAG == "2"
            _cFormaPgto := "DESCONTO"
         ElseIf (_cAlias2)->ZK1_FORPAG == "3"
            _cFormaPgto := "DEPOSITO"
         EndIf 
         aAdd(_aProd ,_cFormaPgto)           //  
   //------------------------------------------------------------
         aAdd(_aProd ,_cTIPOAC)               // 9
         aAdd(_aProd ,(_cAlias2)->ZK1_OBS)    // 10
         aAdd(_aProd ,SToD((_cAlias2)->ZK1_INCLDT)) // 11 
         aAdd(_aProd ,_aMes[Val((_cAlias2)->MES)]+"/"+(_cAlias2)->ANO)//(_cAlias2)->VENCIMENTO) // 12
         aAdd(_aProd ,(_cAlias2)->ZK1_VLRCOR) // 13
         aAdd(_aProd ,(_cAlias2)->ZK3_VALOR)  // 14
         aAdd(_aProd ,(_cAlias2)->ZK2_PRODUT) // 15
         aAdd(_aProd ,(_cAlias2)->ZK2_DESCRI) // 16
         aAdd(_aProd ,(_cAlias2)->PERC_VERBA) // 17
         aAdd(_aProd ,(_cAlias2)->RATEIO)     // 18
         aAdd(_aProd ,(_cAlias2)->ZK2_RATPER) // 19
         aAdd(_aProd ,SToD((_cAlias2)->ZK3_GERAC)) // 20

         aAdd(_aProd ,(_cAlias2)->E1_SALDO) // 21
   //--------------------------------------------------------------------------- Favorecido  
         _cCnpjFavo := ""
         _cNomeFavo := ""
         _cRegional := ""

         If !Empty((_cAlias2)->ZK1_FAVORE) .And. !Empty((_cAlias2)->ZK1_FAVLOJ) 
            DBSelectArea("SA1")
            DBSetOrder(1)
            If DBSeek(xFilial('SA1')+(_cAlias2)->ZK1_FAVORE+(_cAlias2)->ZK1_FAVLOJ)
               _cCnpjFavo := SA1->A1_CGC
               _cNomeFavo := SA1->A1_NOME
               DBSelectArea("SA3")
               DBSetOrder(1)
               If DBSeek(xFilial('SA3')+SA1->A1_VEND)
                  cGeren := SA3->A3_GEREN
                  DBSelectArea("SA3")
                  DBSetOrder(1)
                  If DBSeek(xFilial('SA3')+cGeren)
                     _cRegional := SA3->A3_I_REGIS
                  EndIf
               EndIf
            EndIf
               
         ElseIf !Empty((_cAlias2)->ZK1_FAVORE)
            DBSelectArea("SA1")
            DBSetOrder(1)
            If DBSeek(xFilial('SA1')+(_cAlias2)->ZK1_FAVORE)
               _cCnpjFavo := SA1->A1_CGC
               _cNomeFavo := SA1->A1_NOME
               DBSelectArea("SA3")
               DBSetOrder(1)
               If DBSeek(xFilial('SA3')+SA1->A1_VEND)
                  cGeren := SA3->A3_GEREN
                  cCoord := SA3->A3_SUPER

                  DBSelectArea("ZAM")
                  DBSetOrder(1)
                  If DBSeek(xFilial('ZAM')+cCoord+cGeren)
                     _cRegional := ZAM->ZAM_REGCOD + " - " + Tabela("ZC", ZAM->ZAM_REGCOD, .F.)
                  EndIf
               EndIf
            EndIf
         EndIf 
         
         If ! Empty(_cCnpjFavo)
            _cCnpjFavo := Transform( _cCnpjFavo , "@R! NN.NNN.NNN/NNNN-99" )
         EndIf 

         aAdd(_aProd ,(_cAlias2)->ZK1_FAVORE)    // 22
         aAdd(_aProd ,(_cAlias2)->ZK1_FAVLOJ)    // 23
         aAdd(_aProd ,_cCnpjFavo)                // 24
         aAdd(_aProd ,_cNomeFavo)                      // 25
         aAdd(_aProd ,_cRegional)                      // 26

         _cProvisao := " "
         If (_cAlias2)->ZK1_PROV == "S"
            _cProvisao := "SIM"
         ElseIf (_cAlias2)->ZK1_PROV == "N"   
            _cProvisao := "NÃO" 
         EndIf 
         aAdd(_aProd ,_cProvisao)                // 27

         aAdd(_aProd ,(_cAlias2)->SUBITE)                // 28
         aAdd(_aProd ,SubStr((_cAlias2)->ZK1_ANOMES,1,2)+'/'+SubStr((_cAlias2)->ZK1_ANOMES,3,4))                // 29

         aAdd(_aDadosRel , _aProd  )
               
         (_cAlias2)->(DBSkip())
      
   EndDo

ElseIf AllToChar(MV_PAR01) = "5"

   aCabec := {}

   aAdd(aCabec,{FWX3Titulo("ZK1_CODIGO"),"C"})   
   aAdd(aCabec,{"Cod Cliente","C"})
   aAdd(aCabec,{"Loja","C"})   
   aAdd(aCabec,{"Nome","C"})   
   aAdd(aCabec,{FWX3Titulo("ZK1_VLRCOR"),"C"})   
   aAdd(aCabec,{"Gerente","C"})   
   aAdd(aCabec,{"Coordenador","C"})   
   aAdd(aCabec,{"Observacao","C"})   
   aAdd(aCabec,{"Tipo de Acordo","C"})   
   aAdd(aCabec,{"SubItem","C"})   
   aAdd(aCabec,{"Periodo","C"})   
   aAdd(aCabec,{"Data Inclusao","C"})   
   aAdd(aCabec,{"Produto","C"})  
   aAdd(aCabec,{"Valor Fat.","N"})  


   // Alinhamento: 1-Left   ,2-Center,3-Right
   // Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
   //             Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
   //   (aCabXML,{Titulo             ,1           ,1         ,.F.       })

   For ni := 1 to Len(aCabec)
      aAdd(aCab,aCabec[ni,1])
      If aCabec[ni,2] == "C"
         aAdd(aCabXML,{aCabec[ni,1],1,1,.F.})
      ElseIf aCabec[ni,2] == "D"
         aAdd(aCabXML,{aCabec[ni,1],2,4,.F.})
      ElseIf aCabec[ni,2] == "N"
         aAdd(aCabXML,{aCabec[ni,1],3,3,.F.})
      EndIf
   Next
  
   _cQuery := " SELECT ZK1_CODIGO ACORDO, "
   _cQuery += "      A1_COD CODIGO,  "
   _cQuery += "      A1_LOJA LOJA,  "
   _cQuery += "      TRIM(A1_NOME) CLIENTE,  "
   _cQuery += "      ZK1_VLRCOR VALOR,  "
   _cQuery += "      TRIM(ZK1_GERENT) GERENTE,  "
   _cQuery += "      ZK1_COODNA COORDENADOR, "
   _cQuery += "      RTRIM(ZK1_OBS) OBSERVACAO,  "
   _cQuery += "      Case ZK1_TIPOAC WHEN '1' THEN 'ANIVERSARIO' WHEN '2' THEN 'INAUG/REIN' WHEN '3' THEN 'ACAO COML' WHEN '4' THEN 'RBX. PRECO'  "
   _cQuery += "                     WHEN '5' THEN 'INT. PRODUTO1' WHEN '6' THEN 'CONTRATO' WHEN '7' THEN 'INVESTIENTO' WHEN '8' THEN 'ACORDO COMERCIAL' "
   _cQuery += "                     WHEN '9' THEN 'PENDENCIA' Else 'OUTROS' END AS TIPO_ACORDO, "
   _cQuery += "      Case ZK1_SUBITE WHEN '01' THEN 'SELL' WHEN '02' THEN 'RBX.PRC' WHEN '03' THEN 'DT. CRITICA' WHEN '04' THEN 'TABELA' WHEN '05' THEN 'DIF. IMPOSTO' "
   _cQuery += "                     WHEN '06' THEN 'IN.PRO' WHEN '07' THEN 'COMITE' WHEN '08' THEN 'DIF. PRECO' WHEN '09' THEN 'CONT' WHEN '10' THEN 'ANIVERSARIO' "
   _cQuery += "                     WHEN '11' THEN 'RE/INAUG' WHEN '12' THEN 'MKT/TRD' WHEN '13' THEN 'UHT MAGRO' END AS SUB_ITEM, "
   _cQuery += "      SubStr(ZK1_ANOMES,1,2)||'/'||SubStr(ZK1_ANOMES,3,4) PERIODO,  "
   _cQuery += "      SubStr(ZK1_INCLDT,7,2)||'/'||SubStr(ZK1_INCLDT,5,2)||'/'||SubStr(ZK1_INCLDT,1,4) DATA_INCLUSAO, "
   _cQuery += "      ZK2_PRODUT PROD,  "
   _cQuery += "      SUM(ZK2_VRFATM) FATURADO "
   _cQuery += " FROM " + RetSqlName("ZK2") + " ZK2 "
   _cQuery += "      INNER JOIN " + RetSqlName("ZK1") + " ZK1 ON ZK1_CODIGO = ZK2_CODIGO AND ZK1.D_E_L_E_T_ =' '   "
   _cQuery += "      LEFT JOIN " + RetSqlName("SA1") + " SA1 ON ZK1_FAVORE =  A1_COD AND ZK1_FAVLOJ = A1_LOJA AND SA1.D_E_L_E_T_ =' '  "
   
   _cQuery += "      LEFT JOIN ( SELECT ZK3_FILIAL, ZK3_CODIGO,  "
   _cQuery += "                           SUM (ZK3_VALOR) ZK3_VALOR  "
   _cQuery += "                  FROM " + RetSqlName("ZK3") + "  ZK3_A"
   _cQuery += "                  WHERE ZK3_A.D_E_L_E_T_ = ' '  "
   
   If !Empty(MV_PAR04)
      _cQuery += "                     AND ZK3_VENCTO >= '" + DToS(MV_PAR04)+"' "
   EndIf   
   If !Empty(MV_PAR05)
      _cQuery += "                     AND ZK3_VENCTO <= '" + DToS(MV_PAR05)+"' "
   EndIf
   _cQuery += "                  GROUP BY ZK3_FILIAL, ZK3_CODIGO) ZK3 ON  ZK1_FILIAL = ZK3_FILIAL   AND ZK1_CODIGO = ZK3_CODIGO  "

   _cQuery += " WHERE ZK2.D_E_L_E_T_ =' '  "
   _cQuery += "      AND ZK1_INCLDT   BETWEEN '" + DToS(MV_PAR02)+"' AND '" + DToS(MV_PAR03)+"'   "
   _cQuery += "      AND ZK2_PRODUT LIKE 'G%' "
   
   _cQuery := ROMS78Filtro(@_cQuery)
   
   _cQuery += " GROUP BY ZK1_CODIGO,  "
   _cQuery += "      A1_COD, A1_LOJA ,  " 
   _cQuery += "      TRIM(A1_NOME) ,  " 
   _cQuery += "      ZK1_VLRCOR,  " 
   _cQuery += "      TRIM(ZK1_GERENT),  " 
   _cQuery += "      ZK1_COODNA, "
   _cQuery += "      RTRIM(ZK1_OBS),  "
   _cQuery += "      ZK1_TIPOAC, "
   _cQuery += "      ZK1_SUBITE, "
   _cQuery += "      SubStr(ZK1_ANOMES,1,2)||'/'||SubStr(ZK1_ANOMES,3,4),  "
   _cQuery += "      SubStr(ZK1_INCLDT,7,2)||'/'||SubStr(ZK1_INCLDT,5,2)||'/'||SubStr(ZK1_INCLDT,1,4), "
   _cQuery += "      ZK2_PRODUT  "

   cTimeINI:=Time()

   _nTot:=nConta:=0

   MPSysOpenQuery( _cQuery , _cAlias2 )

   DBSelectArea(_cAlias2)
   COUNT TO _nTot

   _cTotGeral := AllTrim(Str(_nTot))

   cTimeFIM:="Hora Incial: "+cTimeINI+" - Hora Final: "+TIME()+" da leitura dos dados"

   (_cAlias2)->(DBGoTop())
   If (_cAlias2)->(Eof())
      U_ITMsg("Não tem Acordos para processamento com esses filtros.",cTimeFIM,"Altere os filtros.",3) 
      Return {}
   EndIf
      
   If !U_ITMsg("Serão processados "+_cTotGeral+' Acordos, Confirma ?',cTimeFIM,,3,2,3,,"CONFIRMA","VOLTAR")
      Return {}
   EndIf
      
   _aDadosRel:={}
   While (_cAlias2)->(!Eof()) //**********************************  While  ******************************************************
            
         If oproc <> NIL
            nConta++
            oproc:cCaption := ("Lendo "+StrZero(nConta,5) +" de "+ _cTotGeral )
            ProcessMessages()
         EndIf

         _aProd := {}
         aAdd(_aProd ,(_cAlias2)->ACORDO)
         aAdd(_aProd ,(_cAlias2)->CODIGO)
         aAdd(_aProd ,(_cAlias2)->LOJA)
         aAdd(_aProd ,(_cAlias2)->CLIENTE)
         aAdd(_aProd ,(_cAlias2)->VALOR)
         aAdd(_aProd ,(_cAlias2)->GERENTE)
         aAdd(_aProd ,(_cAlias2)->COORDENADOR)
         aAdd(_aProd ,(_cAlias2)->OBSERVACAO)
         aAdd(_aProd ,(_cAlias2)->TIPO_ACORDO)
         aAdd(_aProd ,(_cAlias2)->SUB_ITEM)
         aAdd(_aProd ,(_cAlias2)->PERIODO)
         aAdd(_aProd ,(_cAlias2)->DATA_INCLUSAO)
         aAdd(_aProd ,(_cAlias2)->PROD)
         aAdd(_aProd ,(_cAlias2)->FATURADO)

         aAdd(_aDadosRel , _aProd  )
               
         (_cAlias2)->(DBSkip())
      
   EndDo
EndIf
(_cAlias2)->(DBCloseArea())

Return _aDadosRel

/*
===============================================================================================================================
Programa--------: ROMS78Filtro
Autor-----------: Alex Wallauer
Data da Criacao-: 02/02/2023
Descrição-------: Retorna os filtro do Usuario
Parametros------: _cQuery
Retorno---------: _cQuery
===============================================================================================================================*/
Static Function ROMS78Filtro(_cQuery)

//"Inclusão de: "  +AllTrim(AllToChar(MV_PAR02))+" ate "+AllTrim(AllToChar(MV_PAR03))+CRLF+;
If !Empty(MV_PAR02)
   _cQuery += "  AND ZK1_INCLDT >= '" + DToS(MV_PAR02)+"' "
EndIf

If !Empty(MV_PAR03)
   _cQuery += "  AND ZK1_INCLDT <= '" + DToS(MV_PAR03)+"' "
EndIf

If LEFT(AllToChar(MV_PAR01),1) $ "1,2"// ZK3

//"Vencimento de: "+AllTrim(AllToChar(MV_PAR04))+" ate "+AllTrim(AllToChar(MV_PAR05))+CRLF+;
   If !Empty(MV_PAR04)
      _cQuery += "  AND ZK3_VENCTO >= '" + DToS(MV_PAR04)+"' "
   EndIf
   
   If !Empty(MV_PAR05)
      _cQuery += "  AND ZK3_VENCTO <= '" + DToS(MV_PAR05)+"' "
   EndIf

EndIf

   // Filtra Gerente
If !Empty( MV_PAR06 )             
   If Len(AllTrim(MV_PAR06)) <= 6
      _cQuery += " AND ZK1_CGEREN = '"+ AllTrim(MV_PAR06) + "' "
   Else
      _cQuery += " AND ZK1_CGEREN IN "+ FormatIn( AllTrim(MV_PAR06) , ";" )
   EndIf
EndIf
   
// Filtra Coordenador
If !Empty( MV_PAR07 )             
   If Len(AllTrim(MV_PAR07)) <= 6
      _cQuery += " AND ZK1_CCOODN = '"+ AllTrim(MV_PAR07) + "' "
   Else
      _cQuery += " AND ZK1_CCOODN IN "+ FormatIn( AllTrim(MV_PAR07) , ";" )
   EndIf
EndIf

// Filtra Vendedor
If !Empty( MV_PAR08 )      
   If Len(AllTrim(MV_PAR08)) <= 6
      _cQuery += " AND ZK1_CVENDE = '"+ AllTrim(MV_PAR08) + "' "
   Else
      _cQuery += " AND ZK1_CVENDE IN "+ FormatIn(AllTrim(MV_PAR08), ";" )
   EndIf
EndIf
// Rede
If !Empty( MV_PAR09 )                                                   
   If Len(AllTrim(MV_PAR09)) <= Len(ZK1->ZK1_CREDES)
      _cQuery += " AND ZK1_CREDES 	= '" + AllTrim(MV_PAR09) + "' "
   Else
      _cQuery += " AND ZK1_CREDES 	IN " + FormatIn( AllTrim(MV_PAR09) , ";" )
   EndIf
EndIf

// CLIENTE
If !Empty( MV_PAR10 )                                                   
   _cQuery += " AND ZK1_CLIENT	= '" + AllTrim(MV_PAR10) + "' "
EndIf

// LOJA
If !Empty( MV_PAR11 )                                                   
   _cQuery += " AND ZK1_CLILOJ	= '" + AllTrim(MV_PAR11) + "' "
EndIf
      
//"Tipo do Acordo" +AllTrim(AllToChar(MV_PAR12))+CRLF+;
If !Empty( MV_PAR12 )      
   _cQuery += " AND ZK1_TIPOAC IN "+ FormatIn(AllTrim(MV_PAR12), ";" )
EndIf

If LEFT(AllToChar(MV_PAR01),1) $ "1,2,3"// ZK3

   //"Status"         +AllTrim(AllToChar(MV_PAR13))+CRLF+;
   If !Empty( MV_PAR13 )      
      _cQuery += " AND ZK1_STATUS  IN "+ FormatIn(AllTrim(MV_PAR13), ";" )
   EndIf

EndIf

//"Já Abatido"     +AllTrim(AllToChar(MV_PAR14))
If  LEFT(AllToChar(MV_PAR14),1) $ "1/2"
   _cQuery += " AND ZK1_ABATIM = '"+ LEFT(AllToChar(MV_PAR14),1)+"' "
EndIf

Return _cQuery

/*
===============================================================================================================================
Programa--------: ROMS78Per
Autor-----------: Alex Wallauer
Data da Criacao-: 02/02/2023
Descrição-------: Parâmetros do relatório
Parametros------: Nenhum
Retorno---------: _aPergunte
===============================================================================================================================
*/               
Static Function ROMS78Per()
Local _aDadosPegunte := {}
Local _aPergunte := {}
Local _nI
Local _cTexto

aAdd(_aDadosPegunte,{"01", "Relatorio"          , "MV_PAR01"})       
aAdd(_aDadosPegunte,{"02", "Inclusao de"        , "MV_PAR02"})           
aAdd(_aDadosPegunte,{"03", "Inclusao ate"       , "MV_PAR03"})
aAdd(_aDadosPegunte,{"04", "Vencimento de"      , "MV_PAR04"})           
aAdd(_aDadosPegunte,{"05", "Vencimento ate"     , "MV_PAR05"})
aAdd(_aDadosPegunte,{"06", "Gerente"            , "MV_PAR06"})
aAdd(_aDadosPegunte,{"07", "Coordenador"        , "MV_PAR07"})  
aAdd(_aDadosPegunte,{"08", "Vendedor"           , "MV_PAR08"})  
aAdd(_aDadosPegunte,{"09", "Redes"	            , "MV_PAR09"})       
aAdd(_aDadosPegunte,{"10", "Cliente"            , "MV_PAR10"})           
aAdd(_aDadosPegunte,{"11", "Loja  "	            , "MV_PAR11"})
aAdd(_aDadosPegunte,{"12", "Tipo do Acordo"     , "MV_PAR12"})           
aAdd(_aDadosPegunte,{"13", "Status"             , "MV_PAR13"})          
aAdd(_aDadosPegunte,{"14", "Já Abatido"         , "MV_PAR14"})

For _nI := 1 To Len(_aDadosPegunte)          
    _cTexto := ""
	 If _aDadosPegunte[_nI,3] == "MV_PAR01"
       If Val(AllToChar(MV_PAR01)) > 0 .And. Val(AllToChar(MV_PAR01)) <= Len(_aRel)
          _cTexto := Upper(_aRel[Val(MV_PAR01)])
       EndIf
 
	 ElseIf _aDadosPegunte[_nI,3] == "MV_PAR14"
	   If AllToChar(MV_PAR14) ==  "1"
	      _cTexto := "Sim"
	   ElseIf AllToChar(MV_PAR14) == "2"
	      _cTexto := "Não"
	   Else
	      _cTexto := "Ambos"
	   EndIf
    Else
       _cTexto := &(_aDadosPegunte[_nI,3])
       If ValType(_cTexto) == "D"
          _cTexto := DToC(_cTexto)
       EndIf   
    EndIf	

    aAdd(_aPergunte,{"Pergunta " + _aDadosPegunte[_nI,1] + ':',_aDadosPegunte[_nI,2],_cTexto })

Next


Return _aPergunte
