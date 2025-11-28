/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
=========================================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MDTA1801
Autor-----------: Alex Wallauer
Data da Criacao-: 27/10/2021
Descrição-------: P.E. do menudef do MDTA180.PRX - rograma de Cadastro dos riscos - CHAMADO 37981
Parametros------: NENHUM
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function MDTA1801

Local aRot:={}
aAdd( aRot , { "Carga de EPIs" , "U_MDT180Carga" , 0 , 4 } ) 

Return aRot
/*
===============================================================================================================================
Programa--------: U_MDT180Ca
Autor-----------: Alex Wallauer
Data da Criacao-: 27/10/2021
Descrição-------: P.E. do menudef do MDTA180.PRX - rograma de Cadastro dos riscos - CHAMADO 
Parametros------: NENHUM
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function MDT180Ca()

Local _aParRet :={} , nI 
Local _aParAux :={} 
Local _bOK     :={||.T. }

Private _cAlias1	:= GetNextAlias()


MV_PAR01:="1-Sim"
MV_PAR02:=Space(100)

aAdd( _aParAux , { 2 , "Carga" , MV_PAR01, {"1-Risco Posicionado","2-Todos os Riscos"}   , 090 ,".T.",.T. } )
aAdd( _aParAux , { 1 , "Filial", MV_PAR02, "@!"  , ""  ,"LSTFIL", "" , 100 , .F. } ) 

For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next nI

While .T.

   If !ParamBox( _aParAux , "Digite o tipo da Carga Desejada" , @_aParRet, _bOK )
       Exit
   EndIf
   
   cTimeInicial:=Time()
   MV_PAR01:=AllTrim(MV_PAR01)
   _cLogQry:=""
   aLog := {}
   aGrava := {}
   lRet :=.T.
   SA2->(DBSetOrder(1))//
   _cTot:=""   
   FWMsgRun( ,{|oProc|  lRet:=GeraLog(oProc) } , "Hora Inicial: "+cTimeInicial+" - Carga: "+MV_PAR01 )
    If !lRet
       Loop
    EndIf
   
   If Len(aLog) > 0
      
      aTitCol:={}
      aAdd(aTitCol,"")
      aAdd(aTitCol,"TNX_FILIAL")
      aAdd(aTitCol,"TNX_NUNRIS")
      aAdd(aTitCol,"TNX_EPI ")
      aAdd(aTitCol,"TNX_AGENTE")

      cTit1:="Log (MDTA1801) Carga: "+MV_PAR01+" / Gravados: "+_cTot
      cTit2:="Filial: "+MV_PAR01+" / Gravados: "+_cTot
      _lOK:=.F.
      bOk:=NIL//{|_oDlg| If(_lOK:= U_ITMsg("Confirma Carga dos dados ?",'Atenção!',,2,2,2) ,_oDlg:End(), ) }
      While .T.

         aBotoes:=NIL//{}                                           
         //aAdd( aBotoes , { "" , {|| AVISO("ATENCAO",oLbxAux:aArray[oLbxAux:nAt][ nPosCarta],{"Fechar"},3) }	, "" , "Ver Carta"} )

      //                          , _aCols,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
         U_ITListBox(cTit1,aTitCol,aLog   ,.T.     ,4     ,cTit2   ,          ,        ,         , bOk ,        , aBotoes   )
   
         Exit
  
      EndDo
   
   Else
   
      U_ITMsg(" Nao foi encontrado dados para Filial: "+If(!Empty(MV_PAR01),MV_PAR01,"Todas"),"Atencao!",,3)
   
   EndIf

EndDo

If Select(_cAlias1) > 0
   DBSelectArea(_cAlias1)
   (_cAlias1)->( DBCloseArea() )
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: GeraLog
Autor-------------: Alex Wallauer
Data da Criacao---: 15/10/2021
Descrição---------: Geração do Log de mão de obra 
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function GeraLog(OPROC)

Local _cQry:=""
Local _cAlias2	:= GetNextAlias()

If oproc <> nil
   oproc:cCaption := "Lendo TN0... "
   ProcessMessages()
EndIf

_cQry+= "SELECT R_E_C_N_O_ REC_TN0  "
_cQry+= "FROM "+RETSQLNAME("TN0")+"  "
_cQry+= "WHERE D_E_L_E_T_ = ' ' " 
If MV_PAR01= "1"
   _cQry+= " AND TN0_FILIAL = '"+TN0->TN0_FILIAL+"' "
   _cQry+= " AND TN0_NUMRIS = '"+TN0->TN0_NUMRIS+"' "
ElseIf !Empty(MV_PAR02)
   _cQry+= " AND TN0_FILIAL IN "+ FormatIn(MV_PAR02,";")
EndIf
_cQry+= "ORDER BY TN0_FILIAL, TN0_NUMRIS "

_cLogQry:=_cQry+CRLF+CRLF

If Select(_cAlias1) > 0
   DBSelectArea(_cAlias1)
   (_cAlias1)->( DBCloseArea() )
EndIf

DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry), _cAlias1, .F., .T.)   
(_cAlias1)->(DBGoTop())                           

COUNT TO _nTot

_cQry1:= "SELECT R_E_C_N_O_ REC_TNF  "
_cQry1:= "SELECT DISTINCT TNF_FILIAL, TNF_CODEPI "
_cQry1+= "FROM "+RETSQLNAME("TNF")+"  "
_cQry1+= "WHERE D_E_L_E_T_ = ' ' " 
_cQry1+= " AND TNF_DTDEVO = ' ' "
_cQry3:= " ORDER BY TNF_FILIAL, TNF_CODEPI "

_cTot:=AllTrim(Str(_nTot))
_nTam:=Len(_cTot)+1
nConta:=0
nGravados:=0
(_cAlias1)->(DBGoTop())     
TNX->(DBSetOrder(1))                     
While !((_cAlias1)->(Eof()))

   nConta++
   If oproc <> nil
	  oproc:cCaption := "Lendo TN0: "+AllTrim(Str(nConta,_nTam)) +" de "+ _cTot
	  ProcessMessages()
   EndIf

   TN0->(DBGoTo((_cAlias1)->REC_TN0))

   _cQry2:= " AND TNF_FILIAL = '"+TN0->TN0_FILIAL+"' "
   _cQry2+= " AND TNF_CODFUN = '"+TN0->TN0_CODFUN+"' "

   _cLogQry+=_cQry1+_cQry2+_cQry3+CRLF+CRLF

   DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry1+_cQry2+_cQry3), _cAlias2, .F., .T.)   

   If MV_PAR01= "1"
      _nTot2:=0
      COUNT TO _nTot2
      _cTot:=AllTrim(Str(_nTot2))
      _nTam:=Len(_cTot)+1
      nConta:=0
   EndIf
   (_cAlias2)->(DBGoTop())                           

   While !((_cAlias2)->(Eof()))

      If MV_PAR01= "1"
         nConta++
         If oproc <> nil
	        oproc:cCaption := "Lendo TNF: "+AllTrim(Str(nConta,_nTam)) +" de "+ _cTot
	        ProcessMessages()
         EndIf
      EndIf

      If !TNX->(DBSeek(TN0->TN0_FILIAL+TN0->TN0_NUMRIS+(_cAlias2)->TNF_CODEPI))
          TNX->(RecLock("TNX",.T.))
          TNX->TNX_FILIAL:=TN0->TN0_FILIAL
          TNX->TNX_NUMRIS:=TN0->TN0_NUMRIS
          TNX->TNX_EPI   :=(_cAlias2)->TNF_CODEPI
          TNX->TNX_AGENTE:=TN0->TN0_AGENTE
          TNX->(MSUnLock())
          lGRAVOU:=.T.
          nGravados++
      Else
          lGRAVOU:=.F.
      EndIf

      aLogAux:={}
      aAdd(aLogAux,lGRAVOU          )
      aAdd(aLogAux,TNX->TNX_FILIAL  )
      aAdd(aLogAux,TNX->TNX_NUMRIS  )
      aAdd(aLogAux,TNX->TNX_EPI     )
      aAdd(aLogAux,TNX->TNX_AGENTE  )
      aAdd(aLog,aLogAux)
    
      (_cAlias2)->(DBSkip())
   	
   EndDo
   (_cAlias2)->(DBCloseArea())                           

   (_cAlias1)->(DBSkip())
	
EndDo
_cTot:=AllTrim(Str(nGravados))

Return .T.
