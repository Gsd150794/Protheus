/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |07/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
Alex Wallauer |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MEST018
Autor-----------: Alex Wallauer
Data da Criacao-: 03/07/2019
Descrição-------: Log de mão de obra - Chamado 29718
Parametros------: NENHUM
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function MEST018()

Local cTimeInicial:=Time()
Local _aParRet :={}
Local _aParAux :={} , _nip , W , nI
Local _bOK     :={|| If(MV_PAR02 >= MV_PAR01 .Or. MV_PAR02 > DATE(),.T.,(U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo ate a data de hoje",3),.F.) ) }

Private aLog := {}
Private _cFecham	:= ""
                                   	
MV_PAR01:=dDataBase
MV_PAR02:=dDataBase
MV_PAR03:=Space(200)
MV_PAR04:=Space(200)
MV_PAR05:=Space(200)
aAdd( _aParAux , { 1 , "Data de"	      , MV_PAR01, "@D"	, ""	, ""		, "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Data ate"         , MV_PAR02, "@D"	, ""	, ""		, "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Filial"           , MV_PAR03, "@!"  , ""  ,"LSTFIL", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Conciderar CCs"   , MV_PAR04, "@!"  , ""  ,"LSTCT2", "" , 100 , .F. } ) 
aAdd( _aParAux , { 1 , "Desconciderar CCs", MV_PAR05, "@!"  , ""  ,"LSTCT2", "" , 100 , .F. } ) 
For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next nI

If !ParamBox( _aParAux , "Intervalo de Datas e Filial" , @_aParRet, _bOK )
   Return .F.
EndIf

cTimeInicial:=Time()
lRet:=.T.

_aFiliais:=StrTokArr(AllTrim(MV_PAR03),';')
_cLogQry:=""

//=================================================================================================		
//Buscar data do ultimo fechamento  
//=================================================================================================
_cQuery1 := " SELECT MAX(RD_DATARQ) AS ULTF FROM " + RETSQLNAME("SRD") + " SRD "
_cQuery1 += " WHERE SRD.D_E_L_E_T_ = ' ' "
_cQuery1 += " AND RD_FILIAL = '" + xFilial("SRD") + "'"
_cQuery1 += " AND RD_ROTEIR = 'FOL' "
_cquery1 := ChangeQuery(_cquery1)
MPSysOpenQuery(_cquery1,"SRDU")

If !(SRDU->( Eof() ))
      _cFecham := SRDU->ULTF
EndIf

SRDU->( DBCloseArea() )

For _nip := 1 To Len(_aFiliais)
   Private _cFER:=_cEFE:=_c13S:=_cE13:=_cDC:=_cSMT:=_cEST:=_nInss:=_nAct:=_nFgts:=_nTerc:=""
	For W := 1 To 3
        FWMsgRun( ,{|oProc|  lRet:=GeraLog(oProc,_aFiliais[_nip],W,MV_PAR01,MV_PAR02) } , "Hora Inicial: "+cTimeInicial+" - Filial: "+_aFiliais[_nip]+" - "+StrZero(_nip,2)+" de "+StrZero(Len(_aFiliais),2) )
   Next W
Next _nip
 
If Len(aLog) > 0
   
   aTitCol:={}
   aAdd(aTitCol,"FILIAL")
   aAdd(aTitCol,"TIPO VERBA")
   aAdd(aTitCol,"VALOR INSS")
   aAdd(aTitCol,"VALOR ACT")
   aAdd(aTitCol,"RAT TERCEIROS")
   aAdd(aTitCol,"FGTS     ")
   aAdd(aTitCol,"FERIAS   ")
   aAdd(aTitCol,"VALOR 13o")
   aAdd(aTitCol,"FOLHA    ")
   aAdd(aTitCol,"PROVENTOS")
   aAdd(aTitCol,"DESCONTOS")
   aAdd(aTitCol,"VALOR ESTAGIO")
   aAdd(aTitCol,"MULTA S/ DEMISSAO")
   aAdd(aTitCol,"VALOR SM")
   aAdd(aTitCol,"VALOR DC")
   aAdd(aTitCol,"VALOR ACD INSS")
   aAdd(aTitCol,"VALOR SMT")
   aSize:=NIL
   cTit1:="Log de Mao de Obra (MEST018) Filiais: "+AllTrim(MV_PAR03)+" / Datas de "+DToC(MV_PAR01)+" ate "+DToC(MV_PAR02)+" / Quantidade de Registros: "+AllTrim(Str(Len(aLog))) 
   cTit2:="Filiais: "+AllTrim(MV_PAR03)+" / Hr Ini: "+cTimeInicial+" Hr final "+TIME()+" / Quantidade de Registros: "+AllTrim(Str(Len(aLog))) 
   U_ITListBox(cTit1,aTitCol,aLog,.T.,1,cTit2,,aSize )

Else
   U_ITMsg("Nao foi encontrado dados para essa selecao","Atencao!",,1)
EndIf

Return lRet

/*
===============================================================================================================================
Programa----------: GeraLog
Autor-------------: Alex Wallauer
Data da Criacao---: 03/07/2019
Descrição---------: Geração do Log de mão de obra 
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function GeraLog(OPROC,_cFil,W,_dinicial,_dfinal)

Local _nTot := 0
Local _nConta := 0 
Local _cDIncial:=AllTrim(Str(YEAR(_dInicial)))+StrZero(MONTH(_dInicial),2)
Local _cDFinal :=AllTrim(Str(YEAR(_dFinal))) +StrZero(MONTH(_dFinal ),2)
Local _cYESINCC:=AllTrim(MV_PAR04)
Local _cNOTINCC:=AllTrim(MV_PAR05)

If W = 1//SÓ FAZ UMA VEZ PARA CADA FILIAL

   If oproc <> nil
      oproc:cCaption :="Lendo Filial: "+_cFil+" - "+Str(W,1)+" / 3 - Impostos" 
      ProcessMessages()
   EndIf

   _cFER:=SuperGetMV("IT_FERIAS",.F.,"11.107")//"11.107" //FÉRIAS	           11,107% - [Fixo]   
   _c13S:=SuperGetMV("IT_13SALA",.T.,"08.330")//"8.33"   //13º SALARIO	        8,330% - [Fixo]
   _cFER:=If(Empty(_cFER),"11.107",_cFER)//"11.107" //FÉRIAS	           11,107% - [Fixo]   
   _c13S:=If(Empty(_c13S),"08.330",_c13S)//"8.33"   //13º SALARIO	        8,330% - [Fixo]

   //Busca Impostos - INSS, RAT(ACT), FGTS
   _cQuery := " SELECT SubStr(RCC_CONTEU,2,7) AS INSS, SubStr(RCC_CONTEU,12,6) AS ACT, SubStr(RCC_CONTEU,26,6) AS FGTS
   _cQuery += " FROM " + RETSQLNAME("RCC") + " RCC "
   _cQuery += " WHERE RCC.D_E_L_E_T_ = ' ' "
   _cQuery += " AND RCC_CODIGO = 'S037' "
   _cQuery += " AND SubStr(RCC_CONTEU,1,1) = '1'"
   _cQuery += " AND SubStr(RCC_FIL,1,2) = '" + _cFil + "'"
   _cQuery += " AND RCC_CHAVE = '"+SubStr(DToS(_dInicial),1,6)+"'"

   _cQuery := ChangeQuery(_cQuery)
   MPSysOpenQuery(_cQuery,"SRXT")

   If !(SRXT->( Eof() ))		
	  _nInss 	:= AllTrim(SRXT->INSS)
	  _nAct	 	:= AllTrim(SRXT->ACT)
	  _nFgts	:= AllTrim(SRXT->FGTS) 
   Else
	  _nInss:= "0"
      _nAct	:= "0"
	  _nFgts:= "0"
   EndIf

   SRXT->( DBCloseArea() )
   
   //Busca Impostos - TERCEIROS
   _cQuery := " SELECT SubStr(RCC_CONTEU,7,6) AS TERC "
   _cQuery += " FROM " + RETSQLNAME("RCC") + " RCC "
   _cQuery += " WHERE RCC.D_E_L_E_T_ = ' ' "
   _cQuery += " AND RCC_CODIGO = 'S038' "
   _cQuery += " AND SubStr(RCC_FIL,1,2) = '" + _cFil + "'"
   _cQuery += " AND (SubStr(RCC_CHAVE,13,6) = '"+SubStr(DToS(_dInicial),1,6)+"'"
   _cQuery += "      OR  RCC_CHAVE = ' ') ORDER BY RCC_CHAVE DESC "
   _cQuery := ChangeQuery(_cQuery)
   MPSysOpenQuery( _cQuery ,"SRXV" ) 
   
   SRXV->(DBGoTop())

   If !(SRXV->( Eof() ))
	  _nTerc:= AllTrim(SRXV->TERC)
   EndIf
   If Empty(_nTerc)
	  _nTerc:= "0"
   EndIf		
   
   SRXV->( DBCloseArea() )

   _cEFE:=(Val(_nInss)+Val(_nFgts)+Val(_nTerc)+Val(_nAct))*(Val(_cFER))/100 //Encargos sob Férias	
   _cE13:=(Val(_nInss)+Val(_nFgts)+Val(_nTerc)+Val(_nAct))*(Val(_c13S))/100 //Encargos sob 13º	

   _cDC :=Val(_nInss)+Val(_nFgts)+Val(_nTerc)+Val(_nAct) //VALOR_DC - 37,22
   _cDC :=Str(_cDC,7,3) //VALOR_DC - 37,22
 
   _cSMT:=Val(_nInss)+Val(_cFER) +_cEFE +Val(_nFgts)+Val(_nTerc)+Val(_nAct)//VALOR_SMT - 52.46336
   _cSMT:=Str(_cSMT,7,3)//VALOR_SMT - 52.46336
   
   _cEST:=Val(_cFER) +_cEFE
   _cEST:=Str(_cEST,7,3)

EndIf

If oproc <> nil
   oproc:cCaption := "Lendo Filial: "+_cFil+" - "+Str(W,1)+" / 3 - Valores"  
   ProcessMessages()
EndIf

If _cDIncial > _cFecham .Or. _cDFinal > _cFecham
	
	_cQry := " SELECT  TMP.INSS, TMP.ACT, TMP.RAT_TERC, TMP.FGTS, TMP.FERIAS, TMP.DECIMO_TER, TMP.FOLHA, TMP.PROVENTOS, TMP.DESCONTOS, "
	_cQry += "  DECODE(TMP.VALOR_ESTAG,NULL,0,TMP.VALOR_ESTAG)             VALOR_ESTA, "
	_cQry += "  DECODE(TMP.VALOR_MULTA_DEMIS,NULL,0,TMP.VALOR_MULTA_DEMIS) MULTA_DEMI, "
	_cQry += "  DECODE(TMP.VALOR_SM,NULL,0,TMP.VALOR_SM)                   VALOR_SM,   "
	_cQry += "  DECODE(TMP.VALOR_ACD_INSS,NULL,0,TMP.VALOR_ACD_INSS)       VALORACDIN, "
	_cQry += "  DECODE(TMP.VALOR_DC,NULL,0,TMP.VALOR_DC)                   VALOR_DC,   "
	_cQry += "  DECODE(TMP.VALOR_SMT,NULL,0,TMP.VALOR_SMT)                 VALOR_SMT   "
	_cQry += " FROM (  "
	_cQry += "  SELECT "
	
	_cQry += "   		((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nInss+")/100) as INSS,"
	_cQry += "      	((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nAct +")/100) as ACT,"
	_cQry += "    		((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nTerc+")/100) as RAT_TERC,"
	_cQry += "    		((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nFgts+")/100) as FGTS,"
	
	_cQry += "    		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) + "
	_cQry += "   	 	(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) * ("+_nInss+")/100) + "
	_cQry += "    		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) * ("+_nAct +")/100) + " 
	_cQry += "   		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) * ("+_nTerc+")/100) + "
	_cQry += "    		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) *(("+_nFgts+")/100) )) as Ferias, "
	
	_cQry += "    		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) + "
	_cQry += "    		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nInss+")/100) + " 
	_cQry += "   		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nAct +")/100) + "
	_cQry += "   		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nTerc+")/100) + "
	_cQry += "   		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nFgts+")/100))  as DECIMO_TER, "
	
	_cQry += "    		(p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) as Folha, "
	_cQry += "           p.proventos as proventos, d.devol as descontos, "
	
	_cQry += "   (SELECT SUM(RC_VALOR) FROM " + RETSQLNAME("SRC") + " SRC WHERE SRC.D_E_L_E_T_ = ' '  "
	_cQry += "           AND RC_FILIAL = '"+_cFil+"' AND  RC_PERIODO >= '"+_cDIncial+"' AND  RC_PERIODO <= '"+_cDFinal+"'  "
   If !Empty(_cYESINCC)
	   _cQry += "           AND RC_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RC_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += "           AND RC_PD IN ('727','831')) AS VALOR_MULTA_DEMIS,  "
	
	_cQry += "   (SELECT ((TM.VALOR*"+_nFgts+")/100) FROM "//8.00
	_cQry += "   (SELECT SUM(RC_VALOR) VALOR FROM " + RETSQLNAME("SRC") + " SRC WHERE SRC.D_E_L_E_T_ = ' '  "
	_cQry += "           AND RC_FILIAL = '"+_cFil+"' AND RC_PERIODO >= '"+_cDIncial+"' AND  RC_PERIODO <= '"+_cDFinal+"'  "
   If !Empty(_cYESINCC)
	   _cQry += "           AND RC_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RC_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += "           AND RC_PD IN ('097')) TM ) AS VALOR_SM, "
	
	_cQry += "   (SELECT ((TM.VALOR*"+_nFgts+")/100) FROM "//8.00
	_cQry += "   (SELECT SUM(RC_VALOR) VALOR FROM " + RETSQLNAME("SRC") + " SRC WHERE SRC.D_E_L_E_T_ = ' '  "
	_cQry += "           AND RC_FILIAL = '"+_cFil+"' AND RC_PERIODO >= '"+_cDIncial+"' AND  RC_PERIODO <= '"+_cDFinal+"'  "
   If !Empty(_cYESINCC)
	   _cQry += "           AND RC_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RC_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += "           AND RC_PD IN ('098')) TM ) AS VALOR_ACD_INSS, "
	
	_cQry += "   (SELECT ((TSM.VALOR*"+_cSMT+")/100) FROM "//52.46336
	_cQry += "   (SELECT SUM(RC_VALOR) VALOR FROM " + RETSQLNAME("SRC") + " SRC WHERE SRC.D_E_L_E_T_ = ' '  "
	_cQry += "           AND RC_FILIAL = '"+_cFil+"' AND RC_PERIODO >= '"+_cDIncial+"' AND  RC_PERIODO <= '"+_cDFinal+"' "
   If !Empty(_cYESINCC)
	   _cQry += "           AND RC_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RC_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += "           AND RC_PD IN ('121','323','361')) TSM ) AS VALOR_SMT, "
	
	_cQry += "   (SELECT TDC.VALOR+((TDC.VALOR*"+_cDC+")/100) FROM "//37,22
	_cQry += "   (SELECT SUM(RC_VALOR) VALOR FROM " + RETSQLNAME("SRC") + " SRC WHERE SRC.D_E_L_E_T_ = ' '  "
	_cQry += "           AND RC_FILIAL = '"+_cFil+"' AND RC_PERIODO >= '"+_cDIncial+"' AND  RC_PERIODO <= '"+_cDFinal+"' "
   If !Empty(_cYESINCC)
	   _cQry += "           AND RC_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RC_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += "           AND RC_PD IN ('200','356','205')) TDC ) AS VALOR_DC, "
	
	_cQry += "   (SELECT ((TE.VALOR*"+_cEST+")/100) FROM "//15.241
	_cQry += "   (SELECT SUM(RC_VALOR) VALOR FROM " + RETSQLNAME("SRC") + " SRC WHERE SRC.D_E_L_E_T_ = ' '  "
	_cQry += "           AND RC_FILIAL = '"+_cFil+"' AND RC_PERIODO >= '"+_cDIncial+"' AND  RC_PERIODO <= '"+_cDFinal+"' "
   If !Empty(_cYESINCC)
	   _cQry += "           AND RC_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RC_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += "           AND RC_PD IN ('192','193')) TE ) AS VALOR_ESTAG "
	_cQry += "   from ( "

	_cQry += "   SELECT SUM(RC_VALOR) AS PROVENTOS, "
	_cQry += "   				 	RC_filial  "
	_cQry += "   		from " + retsqlname("SRC") + " SRC2  join " + retsqlname("SRV") + " SRV2 on rc_filial = rv_filial and rc_pd = rv_cod "
	_cQry += "     	 WHERE RC_FILIAL = '" + _cFil + "'"
	_cQry += "     	AND	sRC2.D_E_L_E_T_ = ' ' and srv2.D_E_L_E_T_ = ' ' "

	_cQry += "   	    AND (RV_I_CUSTG = '1' OR RC_PD = '106') " 
	
	If W = 1//query com verbas com todos os impostos
		_cQry += " 	AND RV_INSS = 'S' AND RV_FGTS = 'S' "
	ElseIf W = 2//query com verbas sem impostos
		_cQry += " 	AND RV_INSS = 'N' AND RV_FGTS = 'N' "
	ElseIf W = 3//query com verbas FGTS
		_cQry += " 	AND RV_INSS = 'N' AND RV_FGTS = 'S' "
	EndIf
   If !Empty(_cYESINCC)
	   _cQry += "           AND RC_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RC_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += "   		group by RC_filial) p "
	_cQry += "   FULL OUTER join ( "
	_cQry += "   		select sum(RC_valor) as devol, "
	_cQry += "   				RC_filial "
	_cQry += "   		from " + retsqlname("SRC") + " SRC3 join " + retsqlname("SRV") + " SRV3 on rc_filial = rv_filial and rc_pd = rv_cod "
	_cQry += "    WHERE SRC3.D_E_L_E_T_ = ' '  AND SRV3.D_E_L_E_T_ = ' ' " 
	_cQry += "     	       AND RC_FILIAL = '" + _cFil + "'"

	_cQry += "     	 	   AND (RV_I_CUSTG = '2' OR RC_PD = '403') " 

	If W = 1//query com verbas com todos os impostos
		_cQry += "     	 	   AND RV_INSS = 'S' AND RV_FGTS = 'S' " 
	ElseIf W = 2//query com verbas sem impostos
		_cQry += " 	   AND RV_INSS = 'N' AND RV_FGTS = 'N' " 
	ElseIf W = 3//query com verbas FGTS
		_cQry += " 	   AND RV_INSS = 'N' AND RV_FGTS = 'S' " 
	EndIf
   If !Empty(_cYESINCC)
	   _cQry += "           AND RC_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RC_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += "   		GROUP BY RC_FILIAL) D "
	_cQry += "   				ON P.RC_FILIAL = D.RC_FILIAL "
	_cQry += " ) TMP "

Else //****************************************************************************************************************************************
	
	_cQry := " SELECT  TMP.INSS, TMP.ACT, TMP.RAT_TERC, TMP.FGTS, TMP.FERIAS, TMP.DECIMO_TER, TMP.FOLHA, TMP.PROVENTOS, TMP.DESCONTOS, "
	_cQry += "  DECODE(TMP.VALOR_ESTAG,NULL,0,TMP.VALOR_ESTAG)             VALOR_ESTA, "
	_cQry += "  DECODE(TMP.VALOR_MULTA_DEMIS,NULL,0,TMP.VALOR_MULTA_DEMIS) MULTA_DEMI, "
	_cQry += "  DECODE(TMP.VALOR_SM,NULL,0,TMP.VALOR_SM)                   VALOR_SM,   "
	_cQry += "  DECODE(TMP.VALOR_ACD_INSS,NULL,0,TMP.VALOR_ACD_INSS)       VALORACDIN, "
	_cQry += "  DECODE(TMP.VALOR_DC,NULL,0,TMP.VALOR_DC)                   VALOR_DC,   "
	_cQry += "  DECODE(TMP.VALOR_SMT,NULL,0,TMP.VALOR_SMT)                 VALOR_SMT   "
	_cQry += " FROM (  "
	_cQry += "  SELECT "
	_cQry += " 		((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nInss+")/100) as INSS,"
	_cQry += " 		((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nAct +")/100) as ACT,"
	_cQry += " 		((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nTerc+")/100) as RAT_TERC,"
	_cQry += " 		((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nFgts+")/100) as FGTS,"
	
	_cQry += " 		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) + "
	_cQry += " 		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) * ("+_nInss+")/100) + "
	_cQry += " 		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) * ("+_nAct +")/100) + " 
	_cQry += " 		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) * ("+_nTerc+")/100) + "
	_cQry += " 		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) *(("+_nFgts+")/100) )) as Ferias, "
	
	_cQry += " 		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) + "
	_cQry += " 		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nInss+")/100) + " 
	_cQry += " 		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nAct +")/100) + "
	_cQry += " 		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nTerc+")/100) + "
	_cQry += " 		(((p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nFgts+")/100))  as DECIMO_TER, "
	
	_cQry += "  		(p.proventos - (Case when d.devol > 1 then d.devol Else 0 end)) as Folha, "
	_cQry += "      p.proventos as proventos, d.devol as descontos, "
	
	_cQry += " (SELECT SUM(RD_VALOR) FROM " + RETSQLNAME("SRD") + " SRD WHERE SRD.D_E_L_E_T_ = ' '  "
	_cQry += "         AND RD_FILIAL = '"+_cFil+"' AND  RD_DATARQ >= '"+_cDIncial+"' AND  RD_DATARQ <= '"+_cDFinal+"' "
   If !Empty(_cYESINCC)
	   _cQry += "           AND RD_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RD_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += "         AND RD_PD IN ('727','831')) AS VALOR_MULTA_DEMIS,  "
	
	_cQry += " (SELECT ((TM.VALOR*"+_nFgts+")/100) FROM  "//8.00
	_cQry += " (SELECT SUM(RD_VALOR) VALOR FROM " + RETSQLNAME("SRD") + " SRD WHERE SRD.D_E_L_E_T_ = ' '  "
	_cQry += "         AND RD_FILIAL = '"+_cFil+"' AND RD_DATARQ >= '"+_cDIncial+"' AND  RD_DATARQ <= '"+_cDFinal+"'  "
   If !Empty(_cYESINCC)
	   _cQry += "           AND RD_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RD_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += "         AND RD_PD IN ('97')) TM ) AS VALOR_SM, "
	
	_cQry += " 	 (SELECT ((TM.VALOR*"+_nFgts+")/100) FROM "//8.00
	_cQry += " 	 (SELECT SUM(RD_VALOR) VALOR FROM " + RETSQLNAME("SRD") + " SRD WHERE SRD.D_E_L_E_T_ = ' '  "
	_cQry += " 	         AND RD_FILIAL = '"+_cFil+"' AND RD_DATARQ >= '"+_cDIncial+"' AND  RD_DATARQ <= '"+_cDFinal+"'  "
   If !Empty(_cYESINCC)
	   _cQry += "           AND RD_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RD_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += " 	         AND RD_PD IN ('098')) TM ) AS VALOR_ACD_INSS, "
	
	_cQry += " (SELECT ((TSM.VALOR*"+_cSMT+")/100) FROM "// 49.036
	_cQry += " (SELECT SUM(RD_VALOR) VALOR FROM " + RETSQLNAME("SRD") + " SRD WHERE SRD.D_E_L_E_T_ = ' '  "
	_cQry += "         AND RD_FILIAL = '"+_cFil+"' AND RD_DATARQ >= '"+_cDIncial+"' AND  RD_DATARQ <= '"+_cDFinal+"' "
   If !Empty(_cYESINCC)
	   _cQry += "           AND RD_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RD_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += "         AND RD_PD IN ('121','323','361')) TSM ) AS VALOR_SMT, "
	
	_cQry += " (SELECT TDC.VALOR+((TDC.VALOR*"+_cDC+")/100) FROM "// 37.925
	_cQry += " (SELECT SUM(RD_VALOR) VALOR FROM " + RETSQLNAME("SRD") + " SRD WHERE SRD.D_E_L_E_T_ = ' '  "
	_cQry += "         AND RD_FILIAL = '"+_cFil+"' AND RD_DATARQ >= '"+_cDIncial+"' AND  RD_DATARQ <= '"+_cDFinal+"' "
   If !Empty(_cYESINCC)
	   _cQry += "           AND RD_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RD_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += "         AND RD_PD IN ('200','356','205')) TDC ) AS VALOR_DC, "
	
	_cQry += " (SELECT ((TE.VALOR*"+_cEST+")/100) FROM  "// 11.111
	_cQry += " (SELECT SUM(RD_VALOR) VALOR FROM " + RETSQLNAME("SRD") + " SRD WHERE SRD.D_E_L_E_T_ = ' '  "
	_cQry += "         AND RD_FILIAL = '"+_cFil+"' AND RD_DATARQ >= '"+_cDIncial+"' AND  RD_DATARQ <= '"+_cDFinal+"' "
   If !Empty(_cYESINCC)
	   _cQry += "           AND RD_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RD_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += "         AND RD_PD IN ('192','193')) TE ) AS VALOR_ESTAG "
	_cQry += " from ( "
	_cQry += "   	select 	sum(RD_valor) as proventos, "
	_cQry += " 				 	RD_filial  "
	_cQry += " 		from " + RETSQLNAME("SRD") + " SRD2  JOIN "+RETSQLNAME("SRV")+" SRV2 on rd_filial = rv_filial and rd_pd = rv_cod "
	_cQry += " WHERE RD_FILIAL = '"+_cFil+"' "
	_cQry += " 		and	rd_datarq >= '"+_cDIncial+"' AND  RD_DATARQ <= '"+_cDFinal+"' and "
	_cQry += "   		sRD2.D_E_L_E_T_ = ' ' and srv2.D_E_L_E_T_ = ' ' "
	_cQry += " 		AND RV_I_CUSTG = '1'  "
	If W = 1//query com verbas com todos os impostos
		_cQry	+= " 	AND RV_INSS = 'S' AND RV_FGTS = 'S' "
	ElseIf W = 2//query com verbas sem impostos
		_cQry	+= " 	AND RV_INSS = 'N' AND RV_FGTS = 'N' "
	ElseIf W = 3//query com verbas FGTS
		_cQry	+= " 	AND RV_INSS = 'N' AND RV_FGTS = 'S' "
	EndIf
   If !Empty(_cYESINCC)
	   _cQry += "           AND RD_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RD_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += " 		GROUP BY RD_FILIAL) P "
	_cQry += " FULL OUTER JOIN ( "
	_cQry += " 		SELECT SUM(RD_VALOR) AS DEVOL, "
	_cQry += " 				RD_filial "
	_cQry += " 		FROM " + RETSQLNAME("SRD") + " SRD3 JOIN "+RETSQLNAME("SRV")+" SRV3 ON RD_FILIAL = RV_FILIAL AND RD_PD = RV_COD "
	_cQry += " 		WHERE 	SRD3.D_E_L_E_T_ = ' '  AND SRV3.D_E_L_E_T_ = ' ' AND  "
	_cQry += "  RD_FILIAL = '"+_cFil+"' "
	_cQry += " 	and rd_datarq >= '"+_cDIncial+"' and rd_datarq <= '"+_cDFinal+"' "
	_cQry += " 	AND RV_I_CUSTG = '2' "
	If W = 1//query com verbas com todos os impostos
		_cQry	+= " 	AND RV_INSS = 'S' AND RV_FGTS = 'S' "
	ElseIf W = 2//query com verbas sem impostos
		_cQry	+= " 	AND RV_INSS = 'N' AND RV_FGTS = 'N' "
	ElseIf W = 3//query com verbas FGTS
		_cQry	+= " 	AND RV_INSS = 'N' AND RV_FGTS = 'S' "
	EndIf
   If !Empty(_cYESINCC)
	   _cQry += "           AND RD_CC IN " + FormatIn(_cYESINCC,";")
	EndIf
   If !Empty(_cNOTINCC)
	   _cQry += "           AND RD_CC NOT IN " + FormatIn(_cNOTINCC,";")
	EndIf
	_cQry += " 		GROUP BY RD_FILIAL) D ON P.RD_FILIAL = D.RD_FILIAL "
	_cQry += " ) TMP "
EndIf

If Select("MAO") > 0
   MAO->(DBCloseArea())
EndIf

_cLogQry+="*** LENDO FILIAL: "+_cFil+" - QUERY: "+Str(W,1)+" / 3 **************************************************************** "+CRLF+CRLF
_cLogQry+=_cQry+CRLF+CRLF+CRLF

_cQry := ChangeQuery(_cQry)
MPSysOpenQuery(_cQry,"MAO")

DBSelectArea("MAO")
COUNT To _nTot
_cTotReg:=AllTrim(Str( _nTot ))
	
MAO->(DBGoTop())                           

While !(MAO->(Eof()))

   _nConta++
   If oproc <> nil
	  oproc:cCaption := "Gerando Filial "+_cFil+" - "+ AllTrim(Str(_nConta)) + " de " + _cTotReg+" - Valores"
	  ProcessMessages()
   EndIf
   aLogAux:={}
   aAdd(aLogAux,_cFil)
   If W	 = 1                                      // COM VERBAS COM TODOS OS IMPOSTOS
      aAdd(aLogAux,"VERBAS COM TODOS OS IMPOSTOS")// RV_INSS = 'S' AND RV_FGTS = 'S' "  
   ElseIf W	 = 2                                  // COM VERBAS SEM IMPOSTOS
      aAdd(aLogAux,"VERBAS SEM IMPOSTOS")         // RV_INSS = 'N' AND RV_FGTS = 'N' "  
   ElseIf W	 = 3                                  // COM VERBAS FGTS
      aAdd(aLogAux,"COM VERBAS FGTS")             // RV_INSS = 'N' AND RV_FGTS = 'S' "  
   EndIf
   
   aAdd(aLogAux,TRANS(MAO->INSS      ,"@E 99,999,999,999.99"))
   aAdd(aLogAux,TRANS(MAO->ACT       ,"@E 99,999,999,999.99"))
   aAdd(aLogAux,TRANS(MAO->RAT_TERC  ,"@E 99,999,999,999.99"))
   aAdd(aLogAux,TRANS(MAO->FGTS      ,"@E 99,999,999,999.99"))
   aAdd(aLogAux,TRANS(MAO->FERIAS    ,"@E 99,999,999,999.99"))
   aAdd(aLogAux,TRANS(MAO->DECIMO_TER,"@E 99,999,999,999.99"))
   aAdd(aLogAux,TRANS(MAO->FOLHA     ,"@E 99,999,999,999.99"))
   aAdd(aLogAux,TRANS(MAO->PROVENTOS ,"@E 99,999,999,999.99"))
   aAdd(aLogAux,TRANS(MAO->DESCONTOS ,"@E 99,999,999,999.99"))
   aAdd(aLogAux,TRANS(MAO->VALOR_ESTA,"@E 99,999,999,999.99"))
   aAdd(aLogAux,TRANS(MAO->MULTA_DEMI,"@E 99,999,999,999.99"))
   aAdd(aLogAux,TRANS(MAO->VALOR_SM  ,"@E 99,999,999,999.99"))
   aAdd(aLogAux,TRANS(MAO->VALOR_DC  ,"@E 99,999,999,999.99"))
   aAdd(aLogAux,TRANS(MAO->VALORACDIN,"@E 99,999,999,999.99"))
   aAdd(aLogAux,TRANS(MAO->VALOR_SMT ,"@E 99,999,999,999.99"))

   aAdd(aLog,aLogAux)
   
   MAO->(DBSkip())
	
EndDo

If W = 3//SÓ FAZ UMA VEZ PARA CADA FILIAL

   If oproc <> nil
      oproc:cCaption := "Lendo Filial: "+_cFil+" - "+Str(W,1)+" / 3 - Verbas"  
      ProcessMessages()
   EndIf

   If _cDIncial > _cFecham .Or. _cDFinal > _cFecham
      _cQry := "SELECT RC_PD VERBA, SUM(RC_VALOR) PROVENTOS, RV_INSS INSS, RV_FGTS FGTS, RV_DESC DESCICAO "
      _cQry += "       FROM "+RETSQLNAME("SRC")+" SRC2  "
      _cQry += "       JOIN "+RETSQLNAME("SRV")+" SRV2 ON RC_FILIAL = RV_FILIAL AND RC_PD = RV_COD "
      _cQry += "       WHERE RC_FILIAL = '"+_cFil+"' "
      _cQry += " 	      AND RC_PERIODO >= '"+_cDIncial+"' AND RC_PERIODO <= '"+_cDFinal+"' "
      If !Empty(_cYESINCC)
   	   _cQry += "           AND RC_CC IN " + FormatIn(_cYESINCC,";")
   	EndIf
      If !Empty(_cNOTINCC)
   	  _cQry += "     AND RC_CC NOT IN " + FormatIn(_cNOTINCC,";")
      EndIf
      _cQry += "         AND SRC2.D_E_L_E_T_ = ' ' AND SRV2.D_E_L_E_T_ = ' ' "
      _cQry += "       	 AND (RV_I_CUSTG = '1' OR RC_PD = '106') "
      _cQry += "GROUP BY RC_PD, RV_INSS, RV_FGTS, RV_DESC "
      _cQry += "ORDER BY RC_PD "
   Else
      _cQry := "SELECT RD_PD VERBA, SUM(RD_VALOR) PROVENTOS, RV_INSS INSS, RV_FGTS FGTS, RV_DESC DESCICAO "
      _cQry += "       FROM "+RETSQLNAME("SRD")+" SRD2  "
      _cQry += "       JOIN "+RETSQLNAME("SRV")+" SRV2 ON RD_FILIAL = RV_FILIAL AND RD_PD = RV_COD "
      _cQry += "       WHERE RD_FILIAL = '"+_cFil+"' "
      _cQry += " 	      AND RD_DATARQ >= '"+_cDIncial+"' AND RD_DATARQ <= '"+_cDFinal+"' "
      If !Empty(_cYESINCC)
   	   _cQry += "           AND RD_CC IN " + FormatIn(_cYESINCC,";")
   	EndIf
      If !Empty(_cNOTINCC)
   	  _cQry += "     AND RD_CC NOT IN " + FormatIn(_cNOTINCC,";")
      EndIf
      _cQry += "         AND SRD2.D_E_L_E_T_ = ' ' AND SRV2.D_E_L_E_T_ = ' ' "
      _cQry += "       	 AND RV_I_CUSTG = '1'  "
      _cQry += "GROUP BY RD_PD, RV_INSS, RV_FGTS, RV_DESC "
      _cQry += "ORDER BY RD_PD "
   EndIf

   If Select("MAO") > 0
      MAO->(DBCloseArea())
   EndIf
   _cQry := ChangeQuery(_cQry)

   MPSysOpenQuery(_cQry,"MAO")

   _cLogQry+="*** LENDO FILIAL: "+_cFil+" Verbas 1 - QUERY: "+Str(W,1)+" / 3 **************************************************************** "+CRLF+CRLF
   _cLogQry+=_cQry+CRLF+CRLF+CRLF
   
   DBSelectArea("MAO")
   COUNT To _nTot
   _cTotReg:=AllTrim(Str( _nTot ))
   	
   MAO->(DBGoTop())                           
   
   While !(MAO->(Eof()))
   
      _nConta++
      If oproc <> nil
   	  oproc:cCaption := "Gerando Filial "+_cFil+" - "+ AllTrim(Str(_nConta)) + " de " + _cTotReg+" - Verbas"
   	  ProcessMessages()
      EndIf
      aLogAux:={}
      aAdd(aLogAux,_cFil)
      aAdd(aLogAux,MAO->VERBA+" - "+MAO->DESCICAO)  
      aAdd(aLogAux,MAO->INSS)
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,MAO->FGTS)
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,TRANS(MAO->PROVENTOS ,"@E 99,999,999,999.99"))
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")

      aAdd(aLog,aLogAux)
      
      MAO->(DBSkip())
   	
   EndDo

   If _cDIncial > _cFecham .Or. _cDFinal > _cFecham
      _cQry := "SELECT RC_PD VERBA, SUM(RC_VALOR) DESCONTOS, RV_INSS INSS, RV_FGTS FGTS, RV_DESC DESCICAO "
      _cQry += "       FROM "+RETSQLNAME("SRC")+" SRC2  "
      _cQry += "       JOIN "+RETSQLNAME("SRV")+" SRV2 ON RC_FILIAL = RV_FILIAL AND RC_PD = RV_COD "
      _cQry += "       WHERE RC_FILIAL = '"+_cFil+"' "
      _cQry += " 	      AND RC_PERIODO >= '"+_cDIncial+"' AND RC_PERIODO <= '"+_cDFinal+"' "
      _cQry += "         AND SRC2.D_E_L_E_T_ = ' ' AND SRV2.D_E_L_E_T_ = ' ' "
      _cQry += "         AND (RV_I_CUSTG = '2' OR RC_PD = '403') "
      If !Empty(_cYESINCC)
   	   _cQry += "           AND RC_CC IN " + FormatIn(_cYESINCC,";")
   	EndIf
      If !Empty(_cNOTINCC)
         _cQry += "     AND RC_CC NOT IN " + FormatIn(_cNOTINCC,";")
      EndIf
      _cQry += "GROUP BY RC_PD, RV_INSS, RV_FGTS, RV_DESC "
      _cQry += "ORDER BY RC_PD "
   Else
      _cQry := "SELECT RD_PD VERBA, SUM(RD_VALOR) DESCONTOS, RV_INSS INSS, RV_FGTS FGTS, RV_DESC DESCICAO "
      _cQry += "       FROM "+RETSQLNAME("SRD")+" SRD2  "
      _cQry += "       JOIN "+RETSQLNAME("SRV")+" SRV2 ON RD_FILIAL = RV_FILIAL AND RD_PD = RV_COD "
      _cQry += "       WHERE RD_FILIAL = '"+_cFil+"' "
      _cQry += " 	      AND RD_DATARQ >= '"+_cDIncial+"' AND RD_DATARQ <= '"+_cDFinal+"' "
      _cQry += "         AND SRD2.D_E_L_E_T_ = ' ' AND SRV2.D_E_L_E_T_ = ' ' "
      _cQry += "         AND RV_I_CUSTG = '2'  "
      If !Empty(_cYESINCC)
   	   _cQry += "           AND RD_CC IN " + FormatIn(_cYESINCC,";")
   	EndIf
      If !Empty(_cNOTINCC)
   	  _cQry += "     AND RD_CC NOT IN " + FormatIn(_cNOTINCC,";")
      EndIf
      _cQry += "GROUP BY RD_PD, RV_INSS, RV_FGTS, RV_DESC "
      _cQry += "ORDER BY RD_PD "
   EndIf

   If Select("MAO") > 0
      MAO->(DBCloseArea())
   EndIf
   _cQry := ChangeQuery(_cQry)

   MPSysOpenQuery(_cQry,"MAO")

   _cLogQry+="*** LENDO FILIAL: "+_cFil+" Verbas 2 - QUERY: "+Str(W,1)+" / 3 **************************************************************** "+CRLF+CRLF
   _cLogQry+=_cQry+CRLF+CRLF+CRLF
   
   DBSelectArea("MAO")
   COUNT To _nTot
   _cTotReg:=AllTrim(Str( _nTot ))
   	
   MAO->(DBGoTop())                           
   
   While !(MAO->(Eof()))
   
      _nConta++
      If oproc <> nil
   	  oproc:cCaption := "Gerando Filial "+_cFil+" - "+ AllTrim(Str(_nConta)) + " de " + _cTotReg+" - Verbas"
   	  ProcessMessages()
      EndIf
      aLogAux:={}
      aAdd(aLogAux,_cFil)
      aAdd(aLogAux,MAO->VERBA+" - "+MAO->DESCICAO)  
      aAdd(aLogAux,MAO->INSS)
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,MAO->FGTS)
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,TRANS(MAO->DESCONTOS ,"@E 99,999,999,999.99"))
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")
      aAdd(aLogAux,"")

      aAdd(aLog,aLogAux)
      
      MAO->(DBSkip())
   EndDo
EndIf

Return .T.
