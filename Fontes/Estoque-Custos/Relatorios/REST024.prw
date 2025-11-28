/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |15/03/2023| Chamado 43297. Criação do RELATORIO DE ULTIMA MOVIMENTACAO DE ESTOQUE - OBSOLESCÊNCIA
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Alex Wallauer |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: REST024
Autor-----------: Alex Wallauer
Data da Criacao-: 15/03/2023
Descrição-------: Chamado 43297. RELATORIO DE ULTIMA MOVIMENTACAO DE ESTOQUE - OBSOLESCÊNCIA
Parametros------: NENHUM
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function REST024
Local nI
_cTitulo:="RELATORIO DE ULTIMA MOVIMENTACAO DE ESTOQUE - OBSOLESCÊNCIA"

MV_PAR01:=Date()
MV_PAR02:=Space(50)
MV_PAR03:=Space(150)
MV_PAR04:="EM;PA;PP;MP;PI;IN;IM"+Space(50)

_aParAux:={}
_aParRet:={}

aAdd( _aParAux , { 1 , "Data ate"             , MV_PAR01, "@D","" , ""	   , "" , 050 , .T. })
aAdd( _aParAux , { 1 , "Filiais"              , MV_PAR02, "@!","" ,"LSTFIL", "" , 100 , .F. })
aAdd( _aParAux , { 1 , "Grupo"                , MV_PAR03, "@!","" ,"SBMLIS", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Tipo"                 , MV_PAR04, "@!","" ,"TIPLIS", "" , 100 , .F. } ) 
      
For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next 
   
While .T.
  
      If !ParamBox( _aParAux , "Selecione os filtros" , _aParRet , {|| .T. } , , , , , , , .T. , .T. )
         Exit
      EndIf

      cTimeInicial:=Time()
  	   _cTitulo+=" - "+DToC(DATE())+" - H. I. : "+Time()

      aCab:={}
      aCabXML:={}
      _aDadosRel:={}
         
  	   FWMsgRun(,{|oproc|  _aDadosRel := REST24CP(oproc)  }, "Selecionando os Produtos...","Filtrando Produtos..." )
  	   
      If Len(_aDadosRel) > 0 
         
         _cTitulo2:=_cTitulo+" H. F. : "+Time()
         _cMsgTop:="Data ate: "+AllTrim(AllToChar(MV_PAR01))+ "; Filiais: " +AllTrim(AllToChar(MV_PAR02))+"; Grupo: " +AllTrim(AllToChar(MV_PAR03))+"; Tipo: "+AllTrim(AllToChar(MV_PAR04))

         _cMsgFil:=_cTitulo2+CRLF+;
                   "Data ate : "+AllTrim(AllToChar(MV_PAR01))+CRLF+;
                   "Filiais : " +AllTrim(AllToChar(MV_PAR02))+CRLF+;
                   "Grupo : "   +AllTrim(AllToChar(MV_PAR03))+CRLF+;
                   "Tipo : "    +AllTrim(AllToChar(MV_PAR04))

         _aSX1:=REST24Per()
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
Programa--------: REST24CP
Autor-----------: Alex Wallauer
Data da Criacao-: 15/03/2023
Descrição-------: Ler os dados da Select e grava da array
Parametros------: oProc 
Retorno---------: _aDadosRel
===============================================================================================================================*/
Static Function REST24CP(oproc)
Local _cQuery     := "" //, _nni , nPos , P , Z2
Local _cAlias2    := GetNextAlias()

aCab:={}
aCabXML:={}

If oproc <> NIL
   oproc:cCaption := ("Filtrando dados ..." )
   ProcessMessages() 
EndIf

	// Alinhamento: 1-Left   ,2-Center,3-Right
	// Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
	//         Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
	//         Titulo             ,1           ,1         ,.F.       })
   aAdd(aCab   , "Descricao"     )
   aAdd(aCabXML,{"Descricao"     ,1           ,1         ,.F.       })
   aAdd(aCab   , "Codigo"        )
   aAdd(aCabXML,{"Codigo"        ,2           ,1         ,.F.       })
   aAdd(aCab   , "Grupo"         )
   aAdd(aCabXML,{"Grupo"         ,2           ,1         ,.F.       })
   aAdd(aCab    ,"Tipo"          )
   aAdd(aCabXML,{"Tipo"          ,2           ,1         ,.F.       }) 
   aAdd(aCab    ,"Bloquedo?"     )
   aAdd(aCabXML,{"Bloquedo?"     ,2           ,1         ,.F.       }) 
   aAdd(aCab    ,"Ultima Saida"  )
   aAdd(aCabXML,{"Ultima Saida"  ,2           ,4         ,.F.       }) 
   aAdd(aCab    ,"Ultima Entrada")
   aAdd(aCabXML,{"Ultima Entrada",2           ,4         ,.F.       }) 
   aAdd(aCab    ,"Ultima Interno")
   aAdd(aCabXML,{"Ultima Interno",2           ,4         ,.F.       }) 
   aAdd(aCab    ,"Ultima Data"   )
   aAdd(aCabXML,{"Ultima Data"   ,2           ,4         ,.F.       }) 
   aAdd(aCab    ,"Endereço"      )
   aAdd(aCabXML,{"Endereço"      ,1           ,1         ,.F.       }) 

_cQuery += "  SELECT P.DESCR DESCR    ,"
_cQuery += "         P.COD   COD      ,"
_cQuery += "         P.GRP   GRUPO    ,"
_cQuery += "         P.TIPO  TIPO     ,"
_cQuery += "         P.BLQ   BLQ      ,"
_cQuery += "         P.ULD2  ULT_SAI  ,"
_cQuery += "         P.ULD1  ULT_ENTR ,"
_cQuery += "         P.ULD3  ULT_INTER,"
_cQuery += "         P.ENDER ENDER     "
_cQuery += "  FROM   "
_cQuery += "  (SELECT B1.B1_DESC   DESCR,   "
_cQuery += "          B1.B1_COD    COD,   "
_cQuery += "          B1.B1_GRUPO  GRP,   "
_cQuery += "          B1.B1_TIPO   TIPO,   "
_cQuery += "          B1.B1_MSBLQL BLQ,   "
_cQuery += "    "
_cQuery += "  (SELECT MAX(D2.D2_EMISSAO) FROM   SD2010 D2   "
_cQuery += "    WHERE D2.D2_COD = B1.B1_COD   "
_cQuery += "      AND D2.D_E_L_E_T_ = ' '  "
_cQuery += If( !Empty( MV_PAR01 ) , " AND D2.D2_EMISSAO <=  '"+ DToS( MV_PAR01 )+"' "	, "" ) 
_cQuery += If( !Empty( MV_PAR02 ) , " AND D2.D2_FILIAL IN "+ FormatIn( AllTrim( MV_PAR02 ) , ';' )	, "" ) 
_cQuery += "      AND D2_CLIENTE <> '000001'  "
_cQuery += "      AND (SELECT F4_ESTOQUE FROM  SF4010 F4   "
_cQuery += "            WHERE F4.D_E_L_E_T_ = ' '   "
_cQuery += "              AND F4_ESTOQUE = 'S'   "
_cQuery += "              AND F4.F4_CODIGO = D2.D2_TES    "
_cQuery += "              AND F4.F4_FILIAL = D2.D2_FILIAL "
_cQuery += "              AND ROWNUM = 1) = 'S' ) ULD2,   "
_cQuery += "    "
_cQuery += "  (SELECT MAX(D1.D1_DTDIGIT) FROM   SD1010 D1   "
_cQuery += "    WHERE D1.D1_COD = B1.B1_COD   "
_cQuery += "      AND D1.D_E_L_E_T_ = ' ' "
_cQuery += If( !Empty( MV_PAR01 ) , " AND D1.D1_DTDIGIT <=  '"+ DToS( MV_PAR01 )+"' "	, "" ) 
_cQuery += If( !Empty( MV_PAR02 ) , " AND D1.D1_FILIAL IN "+ FormatIn( AllTrim( MV_PAR02 ) , ';' )	, "" ) 
_cQuery += "      AND D1_FORNECE <> 'F00001'  "
_cQuery += "      AND (SELECT F4_ESTOQUE FROM  SF4010 F4   "
_cQuery += "            WHERE F4.D_E_L_E_T_ = ' '   "
_cQuery += "              AND F4_ESTOQUE = 'S'   "
_cQuery += "              AND F4.F4_CODIGO = D1.D1_TES   "
_cQuery += "              AND F4.F4_FILIAL = D1.D1_FILIAL "
_cQuery += "              AND ROWNUM = 1) = 'S' ) ULD1,   "
_cQuery += "      "
_cQuery += "  (SELECT MAX(D3.D3_EMISSAO) FROM   SD3010 D3  "
_cQuery += "    WHERE D3.D3_COD = B1.B1_COD   "
_cQuery += "      AND D3.D_E_L_E_T_ = ' '      "
_cQuery += If( !Empty( MV_PAR01 ) , " AND D3.D3_EMISSAO <=  '"+ DToS( MV_PAR01 )+"' "	, "" ) 
_cQuery += If( !Empty( MV_PAR02 ) , " AND D3.D3_FILIAL IN "+ FormatIn( AllTrim( MV_PAR02 ) , ';' )	, "" ) 
_cQuery += "      AND D3_CF NOT IN ('RE4','DE4')  "
_cQuery += "      AND NOT (D3_TM IN ('497','498','997','998'))   "
_cQuery += "      AND NOT ( SubStr(D3_DOC,1,6) = 'INVENT')   "
_cQuery += "      AND D3_ESTORNO <> 'S' ) ULD3,   "
_cQuery += "    "
_cQuery += "  (SELECT BZ_I_LOCAL FROM   SBZ010 BZ   "
_cQuery += "    WHERE BZ.BZ_COD = B1.B1_COD   "
_cQuery += If( !Empty( MV_PAR02 ) , " AND BZ.BZ_FILIAL IN "+ FormatIn( AllTrim( MV_PAR02 ) , ';' )	, "" ) 
_cQuery += "      AND BZ.D_E_L_E_T_ = ' '   "
_cQuery += "      AND ROWNUM = 1 ) ENDER   "
_cQuery += "    "
_cQuery += "  FROM   SB1010 B1   "
_cQuery += "  WHERE B1.D_E_L_E_T_ = ' '      "
_cQuery += "    AND B1_FILIAL = '  '  "
_cQuery += If( !Empty( MV_PAR03 ) , " AND B1.B1_GRUPO IN "+ FormatIn( AllTrim( MV_PAR03 ) , ';' )	, "" ) 
_cQuery += If( !Empty( MV_PAR04 ) , " AND B1.B1_TIPO  IN "+ FormatIn( AllTrim( MV_PAR04 ) , ';' )	, "" ) 
_cQuery += "    ORDER BY B1.B1_DESC ) P  "
_cQuery += "    "
_cQuery += "  WHERE P.ULD1||P.ULD2||P.ULD3 IS NOT NULL  "


cTimeINI:=Time()
DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias2 , .T. , .F. )

_nTot:=nConta:=0
COUNT TO _nTot
_cTotGeral:=AllTrim(Str(_nTot))

cTimeFIM:="Hora Incial: "+cTimeINI+" - Hora Final: "+TIME()+" da leitura dos dados"
(_cAlias2)->(DBGoTop())

If _nTot = 0
   U_ITMsg("Não tem registros para processamento com esses filtros.",cTimeFIM,"Altere os filtros.",3) 
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
         
         _dUltData:=SToD((_cAlias2)->ULT_SAI)
         _cUltData:=DToC(_dUltData)+" (S)"
         
         If _dUltData < SToD((_cAlias2)->ULT_ENTR)
            _dUltData:= SToD((_cAlias2)->ULT_ENTR)
            _cUltData:= DToC(_dUltData)+" (E)"
         EndIf
         If _dUltData < SToD((_cAlias2)->ULT_INTER)
            _dUltData:= SToD((_cAlias2)->ULT_INTER)
            _cUltData:= DToC(_dUltData)+" (I)"
         EndIf
         
         _aProd := {}
         aAdd(_aProd ,AllTrim((_cAlias2)->DESCR))
         aAdd(_aProd ,(_cAlias2)->COD)
         aAdd(_aProd ,(_cAlias2)->GRUPO)
         aAdd(_aProd ,(_cAlias2)->TIPO)
         aAdd(_aProd ,If((_cAlias2)->BLQ="1","SIM","NAO") )
         aAdd(_aProd ,SToD((_cAlias2)->ULT_SAI))
         aAdd(_aProd ,SToD((_cAlias2)->ULT_ENTR))
         aAdd(_aProd ,SToD((_cAlias2)->ULT_INTER))
         aAdd(_aProd ,_cUltData)
         aAdd(_aProd ,(_cAlias2)->ENDER)

         aAdd(_aDadosRel , _aProd  )
               
         (_cAlias2)->(DBSkip())
      
EndDo

(_cAlias2)->(DBCloseArea())

Return _aDadosRel

/*
===============================================================================================================================
Programa--------: REST24Per
Autor-----------: Alex Wallauer
Data da Criacao-: 15/03/2023
Descrição-------: Parâmetros do relatório
Parametros------: Nenhum
Retorno---------: _aPergunte
===============================================================================================================================
*/               
Static Function REST24Per()
Local _aDadosPegunte := {}
Local _aPergunte := {}
Local _nI
Local _cTexto

aAdd(_aDadosPegunte,{"01", "Data ate : ", "MV_PAR01"})       
aAdd(_aDadosPegunte,{"02", "Filiais : " , "MV_PAR02"})           
aAdd(_aDadosPegunte,{"03", "Grupo : "   , "MV_PAR03"})
aAdd(_aDadosPegunte,{"04", "Tipo : "    , "MV_PAR04"})           

For _nI := 1 To Len(_aDadosPegunte)          

    _cTexto := &(_aDadosPegunte[_nI,3])
    If ValType(_cTexto) == "D"
       _cTexto := DToC(_cTexto)
    EndIf   

    aAdd(_aPergunte,{"Pergunta " + _aDadosPegunte[_nI,1] + ':',_aDadosPegunte[_nI,2],_cTexto })

Next

Return _aPergunte
