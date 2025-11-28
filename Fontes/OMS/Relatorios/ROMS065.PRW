/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO                             
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
 Jerry        | 27/06/2023 | Chamado 43761. Adicionado novas Colunas.
 Alex Wallauer| 15/09/2023 | Chamado 44503. Tratamento para as novas colunas de Subsegmento.
==============================================================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==============================================================================================================================================================
Alex     - Igor Melgaço  - 02/05/25 - 06/05/25 -  50525  - Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
==============================================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "topconn.ch"
#DEFINE ENTER CHR(13)+CHR(10)


/*
===============================================================================================================================
Programa--------: ROMS065
Autor-----------: Alex Wallauer
Data da Criacao-: 28/10/2021
===============================================================================================================================
Descrição-------: Lista clientes por Gerente / Vendedor - CHAMADO 38081
===============================================================================================================================
Parametros------: NENHUM
===============================================================================================================================
Retorno---------: NENHUM
===============================================================================================================================
*/

User Function ROMS065()//U_ROMS065
Local _aParRet :={} , nI 
Local _aParAux :={} 
Local _bOK     :={||.T. }

Private _cAlias1	:= GetNextAlias()
_aItalac_F3:={}
//_cSelectSB1:="SELECT DISTINCT A1_COD, A1_NOME, A1_MSBLQL FROM "+RETSQLNAME("SB1")+" SB1 WHERE "+If(MV_PAR07="1","A1_MSBLQL <> '1'", "A1_MSBLQL = '1'" )+" AND D_E_L_E_T_ = ' ' ORDER BY A1_COD " 
_bSelectSA1:={|| "SELECT DISTINCT A1_COD, A1_NOME, A1_MSBLQL FROM "+RETSQLNAME("SA1")+" SA1 WHERE "+If(MV_PAR07="2","A1_MSBLQL = '1'", "A1_MSBLQL <> '1'" )+" AND D_E_L_E_T_ = ' ' ORDER BY A1_COD "  }
_bCondSA1  :={|| If(MV_PAR07="2",(A1_MSBLQL = "1"),(A1_MSBLQL <> "1")) }
//aAdd(_aItalac_F3,{"MV_PAR01","SA1",SA1->(FIELDPOS("A1_COD")),{|| SA1->A1_LOJA+"-"+SA1->A1_NOME } ,_bCondSA1 ,"Clientes",,,} )
aAdd(_aItalac_F3,{"MV_PAR01",_bSelectSA1,{|Tab| AllTrim((Tab)->A1_COD) }, {|Tab| "["+(Tab)->A1_MSBLQL+"] "+(Tab)->A1_NOME } ,_bCondSA1 ,"Clientes",,,,.F.        ,       , } )

//AD(_aItalac_F3,{"1CPO_PO1",_cTab,_nCpoChave               , _nCpoDesc                          ,_bCondTab , _cTitAux      , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
_bCondTab:={|| SA3->A3_I_TIPV = 'V' }//
aAdd(_aItalac_F3,{"MV_PAR04","SA3",SA3->(FIELDPOS("A3_COD")), SA3->(FIELDPOS("A3_NOME"))  ,_bCondTab ,"Representantes",,,} )

MV_PAR01:=Space(350)
MV_PAR02:=Space(250)
MV_PAR03:=Space(250)
MV_PAR04:=Space(250)
MV_PAR05:=Space(150)
MV_PAR06:=Date()
MV_PAR07:="1-Sim"

aAdd( _aParAux , { 1 , "Clientes"        , MV_PAR01, "@!"  , ""    , "F3ITLC"    , "" , 100 , .F. } )
aAdd( _aParAux , { 1 , "Gerentes"        , MV_PAR02, "@!"  , ""    , "LSTGER"    , "" , 100 , .F. } )//SA3.A3_I_TIPV = 'G'
aAdd( _aParAux , { 1 , "Coordenadores"   , MV_PAR03, "@!"  , ""    , "LSTSUP"    , "" , 100 , .F. } )//SA3.A3_I_TIPV = 'C'
aAdd( _aParAux , { 1 , "Representantes"  , MV_PAR04, "@!"  , ""    , "F3ITLC"    , "" , 100 , .F. } )//SA3.A3_I_TIPV = 'V'
aAdd( _aParAux , { 1 , "UFs"             , MV_PAR05, "@!"  , ""    , "LSTEST"    , "" , 100 , .F. } )
aAdd( _aParAux , { 1 , "Data Emiss PV/NF", MV_PAR06, "@D"	 , ""	   , ""		       , "" , 050 , .T. } )
aAdd( _aParAux , { 2 , "Situacao"        , MV_PAR07, {"1-ATIVO","2-BLOQUEADO","3-AMBOS"}, 090 ,".T.",.T. } )

For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next nI

While .T.

             //aParametros, cTitle                                , @aRet    ,[bOk], [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
   If !ParamBox( _aParAux , "Lista clientes por gerente/vendedor" , @_aParRet, _bOK, /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
       Exit
   EndIf
   
   cTimeInicial:=Time()
   MV_PAR01:=AllTrim(MV_PAR01)
   MV_PAR02:=AllTrim(MV_PAR02)
   MV_PAR03:=AllTrim(MV_PAR03)
   MV_PAR04:=AllTrim(MV_PAR04)
   MV_PAR05:=AllTrim(MV_PAR05)
   _cLogQry:=""
   aLog := {}
   aGrava := {}
   lRet :=.T.
   SA2->(DBSetOrder(1))//
   _cTot:=""   
   FWMsgRun( ,{|oProc|  lRet:=GeraDados(oProc) } , "Hora Inicial: "+cTimeInicial+" - Clientes: "+If(Empty(MV_PAR01),"Todos",MV_PAR01) )
    If !lRet
       Loop
    EndIf
   
   If Len(aLog) > 0
      
      aTitCol:={}
      aAdd(aTitCol,"CODGER"  )          
      aAdd(aTitCol,"GERENTE" )          
      aAdd(aTitCol,"COORD" )           
      aAdd(aTitCol,"COORDENADOR")   
      aAdd(aTitCol,"COD SUP."  )       
      aAdd(aTitCol,"SUPERVISOR")       

      aAdd(aTitCol,"TIPO REP 1"  )     
      aAdd(aTitCol,"CODREP 1"  )     
      aAdd(aTitCol,"REPRESENTANTE 1")     
      aAdd(aTitCol,"NOME REPRESENTANTE 1")
      aAdd(aTitCol,"REGRA COMISSAO 1")

      aAdd(aTitCol,"TIPO REP 2"  )     
      aAdd(aTitCol,"CODREP 2"  )        
      aAdd(aTitCol,"REPRESENTANTE 2")   
      aAdd(aTitCol,"NOME REPRESENTANTE 2")      
      aAdd(aTitCol,"REGRA COMISSAO 2")      

      aAdd(aTitCol,"COD" )              
      aAdd(aTitCol,"LOJA")              
      aAdd(aTitCol,"PESSOA"  )          
      aAdd(aTitCol,"CNPJ"  )            
      aAdd(aTitCol,"REDE"  )            
      aAdd(aTitCol,"NOME DA REDE")      
      aAdd(aTitCol,"RAZAO SOCIAL" )     
      aAdd(aTitCol,"NOME REDUZIDO" )    
      aAdd(aTitCol,"CIDADE"   )         
      aAdd(aTitCol,"UF"  )              
      aAdd(aTitCol,"CEP"  )             
      aAdd(aTitCol,"ENDERECO"    )      
      aAdd(aTitCol,"REGIAO DE VENDA"  ) 
      aAdd(aTitCol,"REGIONAL"  )       
      aAdd(aTitCol,"DDD"  )             
      aAdd(aTitCol,"TELEFONE")          
      aAdd(aTitCol,"COD SEG."  )        
      aAdd(aTitCol,"SEGMENTO"  )  

      aAdd(aTitCol,"COD SUBSEG."  )        
      aAdd(aTitCol,"SUBSEGMENTO"  )  

      aAdd(aTitCol,"DT 1A COMP" )       
      aAdd(aTitCol,"DT ULT COMP"  )     
      aAdd(aTitCol,"DT ULT AVALIACAO" ) 
      aAdd(aTitCol,"DT INCLUSAO" )  
      aAdd(aTitCol,"DT_ULT_NOTA")   

      aAdd(aTitCol,"SITUACAO")          
      aAdd(aTitCol,"CONTRIBUINTE"  )    
      aAdd(aTitCol,"OPT SIMP NAC" )     
      aAdd(aTitCol,"COND PAGTO"  )        
      aAdd(aTitCol,"DESCRICAO COND PAGTO")      
      aAdd(aTitCol,"INC. ESTADUAL ")
      aAdd(aTitCol,"E-MAIL XML    ")
      aAdd(aTitCol,"E-MAIL CONTATO")
      aAdd(aTitCol,"SUFRAMA       ")
      aAdd(aTitCol,"RISCO         ")
      aAdd(aTitCol,"LIMITE CREDITO")   
      aAdd(aTitCol,"CODIGO CHEP   ")
      aAdd(aTitCol,"TOT NF DO CLIENTE")
      aAdd(aTitCol,"TOT NF DA REDE")      

      cTit1:="Lista clientes por gerente/vendedor (ROMS065) "
      cTit2:="Param 1: "+MV_PAR01+"/ Param 2: "+MV_PAR02+"/ Param 3: "+MV_PAR03+"/ Param 4: "+MV_PAR04+"/ Param 6: "+AllToChar(MV_PAR06)+"/ Param 7: "+MV_PAR07

      //                          , _aCols,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
      U_ITListBox(cTit1,aTitCol,aLog   ,.T.     ,1     ,cTit2   ,          ,        ,         ,     ,        ,           )
   
   Else
   
      U_ITMsg(" Nao foi encontrado dados para esses filtros","Atencao!",,3)
   
   EndIf

EndDo

If Select(_cAlias1) > 0
   DBSelectArea(_cAlias1)
   (_cAlias1)->( DBCloseArea() )
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: GeraDados
Autor-------------: Alex Wallauer
Data da Criacao---: 15/10/2021
===============================================================================================================================
Descrição---------: Geração de Dados dos Clientes 
===============================================================================================================================
Parametros--------: oproc - objeto da barra de processamento
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function GeraDados(OPROC)
Local _cQry:=""
cPict:=PesqPict("SA1","A1_LC")

If oproc <> nil
   oproc:cCaption := "Lendo Dados... "
   ProcessMessages()
EndIf

_cQry+= " SELECT  "
_cQry+= " GEREN.A3_COD   CODGER,"   //CODGER                    
_cQry+= " GEREN.A3_NOME  GERENTE, " //GERENTE                    
_cQry+= " COORD.A3_COD   COORD,"    //COORD   
_cQry+= " COORD.A3_NOME  COORDENA,"  //COORDENA  

_cQry+= " SUPER.A3_COD   CODSUPER,"    //COORD   
_cQry+= " SUPER.A3_NOME  SUPER,"  //COORDENA  

_cQry+= " VEND.A3_I_TIPV TIPO,Case "+ENTER
_cQry+= "    WHEN VEND.A3_TIPO = 'E' THEN 'EXTERNO' "+ENTER
_cQry+= " WHEN VEND.A3_TIPO = 'I' THEN 'INTERNO' "+ENTER
_cQry+= "     Else 'PARCEIRO' "+ENTER
_cQry+= " END TIPO1  , "+ENTER

_cQry+= " VEND.A3_COD    CODREP_1,"  //CODREP_1                     
_cQry+= " VEND.A3_NOME   REPRESEN,"  //REPRESEN  
_cQry+= " VEND.A3_I_NOMEF NOMEREP1,"//"NOME_REPRESENTANTE" 

_cQry+= " VEND2.A3_COD   CODREP_2,"  //CODREP_2                    
_cQry+= " VEND2.A3_NOME  REPRESE2,"  //REPRESE2"  
_cQry+= " VEND2.A3_I_NOMEF NOMEREP2,"//"NOME_REPRESENTANTE"                        

_cQry+= " VEND2.A3_I_TIPV TIPO,Case "+ENTER
_cQry+= "    WHEN VEND2.A3_TIPO = 'E' THEN 'EXTERNO' "+ENTER
_cQry+= " WHEN VEND2.A3_TIPO = 'I' THEN 'INTERNO' "+ENTER
_cQry+= "     Else 'PARCEIRO' "+ENTER
_cQry+= " END TIPO2  , "+ENTER
_cQry+= " SX5.X5_DESCRI REGIONAL, "+ENTER 


_cQry+= " SA1.R_E_C_N_O_ REC_SA1,"+ENTER

//---------- Para ultimo Pedido de Venda
_cQry+= " (SELECT MAX (C5_EMISSAO  )  FROM "+RetSqlName("SC5")+" SC5 WHERE SC5.D_E_L_E_T_ = ' ' "+ENTER
_cQry+= " AND C5_CLIENT = A1_COD AND C5_LOJACLI = A1_LOJA "+ENTER
_cQry+= " AND C5_I_OPER IN ('01','05','42','12','15','18','24') ) DT_ULT_PV, "+ENTER
   
//---------- Para ultima nota fiscal emitida
_cQry+= " (SELECT MAX (F2_EMISSAO) FROM "+RETSQLNAME("SF2")+" SF2 WHERE SF2.F2_CLIENTE = SA1.A1_COD AND SF2.F2_LOJA = SA1.A1_LOJA AND SF2.d_e_l_e_t_ = ' ' AND SF2.F2_TIPO = 'N') DT_ULT_NF, " +ENTER

//----------- QUERY TOTAL DE NOTAS EMITIDAS PARA O CLIENTE
_cQry += "     (SELECT COUNT(*) FROM " + RETSQLNAME("SF2") + " SF2 " + "WHERE SF2.F2_CLIENTE = SA1.A1_COD AND SF2.F2_LOJA = SA1.A1_LOJA AND SF2.d_e_l_e_t_ = ' ' AND SF2.F2_TIPO = 'N') NFS_CLIENTE , "

//----------- QUERY TOTAL DE NOTAS EMITIDAS PARA A REDE
_cQry += "     (  Case WHEN SA1.A1_GRPVEN  = '999999' THEN 0 "
_cQry += "             Else (SELECT COUNT(*) FROM " + RETSQLNAME("SF2")+ " SF2, " + RETSQLNAME("SA10") +" REDE "
_cQry += "                   where SF2.d_e_l_e_t_ = ' ' AND SF2.F2_TIPO = 'N'  AND REDE.A1_COD = SF2.F2_CLIENTE AND REDE.A1_LOJA = SF2.F2_LOJA  AND "
_cQry += "             REDE.A1_GRPVEN = SA1.A1_GRPVEN  )   
_cQry += "                END ) NFS_REDE, "

_cQry += " Case " +ENTER
_cQry += " WHEN VEND.A3_I_REGCO = 'N' THEN 'SEM COMISSÃO' "+ENTER
_cQry += " WHEN VEND.A3_I_REGCO = 'N' THEN 'SEM COMISSÃO' "+ENTER
_cQry += " WHEN VEND.A3_I_REGCO = 'C' THEN 'CLT + COMISSÃO'"+ENTER
_cQry += " WHEN VEND.A3_I_REGCO = 'D' THEN 'DIFERENCIADA'"+ENTER
_cQry += " WHEN VEND.A3_I_REGCO = 'P' THEN 'FIXO - COMISSÃO'"+ENTER
_cQry += " WHEN VEND.A3_I_REGCO = 'F' THEN 'APENAS FIXO SEM COMISSÃO'"+ENTER
_cQry += " WHEN VEND.A3_I_REGCO = 'V' THEN 'PADRAO VAREJO'"+ENTER
_cQry += " Else 'PARCEIRO' "+ENTER
_cQry += " END REGRA1, "+ENTER
_cQry += " Case " +ENTER
_cQry += " WHEN VEND2.A3_I_REGCO = 'N' THEN 'SEM COMISSÃO' "+ENTER
_cQry += " WHEN VEND2.A3_I_REGCO = 'N' THEN 'SEM COMISSÃO' "+ENTER
_cQry += " WHEN VEND2.A3_I_REGCO = 'C' THEN 'CLT + COMISSÃO'"+ENTER
_cQry += " WHEN VEND2.A3_I_REGCO = 'D' THEN 'DIFERENCIADA'"+ENTER
_cQry += " WHEN VEND2.A3_I_REGCO = 'P' THEN 'FIXO - COMISSÃO'"+ENTER
_cQry += " WHEN VEND2.A3_I_REGCO = 'F' THEN 'APENAS FIXO SEM COMISSÃO'"+ENTER
_cQry += " WHEN VEND2.A3_I_REGCO = 'V' THEN 'PADRAO VAREJO'"+ENTER
_cQry += " Else 'PARCEIRO' "+ENTER
_cQry += " END REGRA2 "+ENTER 
 
_cQry+= " FROM  "+ENTER
_cQry +=  RetSqlName("SA1")+" SA1,  "+ENTER
_cQry +=  RetSqlName("SA3")+" VEND, "+ENTER
_cQry +=  RetSqlName("SA3")+" VEND2,  "+ENTER
_cQry +=  RetSqlName("SA3")+" COORD,  "+ENTER
_cQry +=  RetSqlName("SA3")+" GEREN, " +ENTER
_cQry +=  RetSqlName("SA3")+" SUPER, " +ENTER
_cQry +=  RetSqlName("ZAM")+" ZAM, " +ENTER
_cQry +=  RetSqlName("SX5")+" SX5 " +ENTER
_cQry+= " WHERE SA1.D_E_L_E_T_ = ' ' "+ENTER
_cQry+= " AND A1_CLIFUN <> '1'"+ENTER
_cQry+= " AND VEND.A3_COD = A1_VEND"+ENTER
_cQry+= " AND VEND.D_E_L_E_T_ = ' '"+ENTER
_cQry+= " AND VEND2.A3_COD  (+) = A1_I_VEND2"+ENTER
_cQry+= " AND VEND2.D_E_L_E_T_  (+) = ' ' "+ENTER
_cQry+= " AND GEREN.A3_COD =VEND.A3_GEREN"+ENTER
_cQry+= " AND GEREN.D_E_L_E_T_ = ' '"+ENTER
_cQry+= " AND COORD.A3_COD = VEND.A3_SUPER"+ENTER
_cQry+= " AND COORD.D_E_L_E_T_ = ' '"+ENTER
_cQry+= " AND SUPER.A3_COD     (+)= VEND.A3_I_SUPE"+ENTER 
_cQry+= " AND SUPER.D_E_L_E_T_ (+)= ' ' "+ENTER
 
_cQry+= " AND ZAM.D_E_L_E_T_  (+) <> '*' "+ENTER
_cQry+= " AND ZAM.ZAM_GERCOD  (+) =  VEND.A3_GEREN "+ENTER
_cQry+= " AND ZAM.ZAM_COOCOD  (+) =  VEND.A3_SUPER "+ENTER
_cQry+= " AND SX5.D_E_L_E_T_  (+) <> '*' "+ENTER
_cQry+= " AND SX5.X5_TABELA   (+) = 'ZC' "+ENTER
_cQry+= " AND SX5.X5_CHAVE    (+) = ZAM.ZAM_REGCOD "+ENTER

  


If !Empty(MV_PAR01)
   _cQry+= " AND A1_COD IN "+FormatIn(AllTrim(MV_PAR01),";")+ENTER
EndIf
If !Empty(MV_PAR02)
   _cQry+= " AND GEREN.A3_COD IN "+FormatIn(AllTrim(MV_PAR02),";")+ENTER
EndIf
If !Empty(MV_PAR03)
   _cQry+= " AND COORD.A3_COD IN "+FormatIn(AllTrim(MV_PAR03),";")+ENTER
EndIf
If !Empty(MV_PAR04)
   _cQry+= " AND VEND.A3_COD IN "+FormatIn(AllTrim(MV_PAR04),";")+ENTER
EndIf
If !Empty(MV_PAR05)
   _cQry+= " AND A1_EST IN "+FormatIn(AllTrim(MV_PAR05),";")+ENTER
EndIf
If MV_PAR07 = "1"//ATIVO
   _cQry+= " AND A1_MSBLQL <> '1'"+ENTER
ElseIf MV_PAR07 = "2"//BLOQUEADO
   _cQry+= " AND A1_MSBLQL = '1'"+ENTER
EndIf
_cQry+= " ORDER BY GEREN.A3_NOME , COORD.A3_NOME , VEND.A3_NOME , A1_NOME "

//nHandle := FCreate("c:\smartclient\ROMS065_"+StrTran(TIME(),":","_")+".TXT")
//FWrite(nHandle, _cQry)
//FClose(nHandle)

If Select(_cAlias1) > 0
   DBSelectArea(_cAlias1)
   (_cAlias1)->( DBCloseArea() )
EndIf

DbUseArea(.T., "TOPCONN", TCGenQry(,,_cQry), _cAlias1, .F., .T.)   
(_cAlias1)->(DBGoTop())                           

COUNT TO _nTot

_cTot:=AllTrim(Str(_nTot))
_nTam:=Len(_cTot)+1
nConta:=0
(_cAlias1)->(DBGoTop())     
TNX->(DBSetOrder(1))                     
While !((_cAlias1)->(Eof()))

   nConta++
   If oproc <> nil
	  oproc:cCaption := "Lendo Dados: "+AllTrim(Str(nConta,_nTam)) +" de "+ _cTot
	  ProcessMessages()
   EndIf

   SA1->(DBGoTo( (_cAlias1)->REC_SA1) )

   aLogAux:={}
   aAdd(aLogAux,(_cAlias1)->CODGER  )
   aAdd(aLogAux,(_cAlias1)->GERENTE )

   aAdd(aLogAux,(_cAlias1)->COORD   )
   aAdd(aLogAux,(_cAlias1)->COORDENA)


   aAdd(aLogAux,(_cAlias1)->CODSUPER   )
   aAdd(aLogAux,(_cAlias1)->SUPER)


   aAdd(aLogAux,(_cAlias1)->TIPO1)
   aAdd(aLogAux,(_cAlias1)->CODREP_1)
   aAdd(aLogAux,(_cAlias1)->REPRESEN)
   aAdd(aLogAux,(_cAlias1)->NOMEREP1)
   aAdd(aLogAux,(_cAlias1)->REGRA1)   
   
   aAdd(aLogAux,(_cAlias1)->TIPO2)
   aAdd(aLogAux,(_cAlias1)->CODREP_2)
   aAdd(aLogAux,(_cAlias1)->REPRESE2)
   aAdd(aLogAux,(_cAlias1)->NOMEREP2) 
   aAdd(aLogAux,(_cAlias1)->REGRA2)
 
   aAdd(aLogAux,SA1->A1_COD   )   
   aAdd(aLogAux,SA1->A1_LOJA )    
   aAdd(aLogAux,SA1->A1_PESSOA )  
   aAdd(aLogAux,SA1->A1_CGC  )     
   aAdd(aLogAux,SA1->A1_GRPVEN )  
   aAdd(aLogAux,Posicione("ACY",1,xFilial("ACY") + SA1->A1_GRPVEN, "ACY_DESCRI") )
   aAdd(aLogAux,SA1->A1_NOME  )   
   aAdd(aLogAux,SA1->A1_NREDUZ )  
   aAdd(aLogAux,SA1->A1_MUN   )    
   aAdd(aLogAux,SA1->A1_EST )      
   aAdd(aLogAux,SA1->A1_CEP  )    
   aAdd(aLogAux,SA1->A1_END  )    
   aAdd(aLogAux,SA1->A1_I_REGIA  )
   aAdd(aLogAux,(_cAlias1)->REGIONAL )
   aAdd(aLogAux,SA1->A1_DDD  )    
   aAdd(aLogAux,SA1->A1_TEL )     
   aAdd(aLogAux,SA1->A1_I_GRCLI )
   aAdd(aLogAux,Posicione("ZZ6",1,xFilial("ZZ6") + SA1->A1_I_GRCLI, "ZZ6_DESCRO")  ) 
   aAdd(aLogAux,SA1->A1_I_SUBCO )
   aAdd(aLogAux,Posicione("ZS6",1,xFilial()+SA1->A1_I_GRCLI+SA1->A1_I_SUBCO,"ZS6_DESCRI")  ) 

   aAdd(aLogAux,DToC(SA1->A1_PRICOM  ))  
   aAdd(aLogAux,DToC(SToD((_cAlias1)->DT_ULT_PV)) )  
   aAdd(aLogAux,DToC(SA1->A1_I_DTREA ))  
   aAdd(aLogAux,DToC(SA1->A1_I_DTCAD )) 
   aAdd(aLogAux,DToC(SToD((_cAlias1)->DT_ULT_NF)) )      

   aAdd(aLogAux,If(SA1->A1_MSBLQL ="1","Bloqueado","Ativo") )  
   aAdd(aLogAux,If(SA1->A1_CONTRIB="1","Sim","Nao") )  
   aAdd(aLogAux,If(SA1->A1_SIMPNAC="1","Sim","Nao") )  


   aAdd(aLogAux,SA1->A1_COND ) 
   aAdd(aLogAux,Posicione("SE4",1,xFilial("SE4") + SA1->A1_COND, "E4_DESCRI")  ) 
   aAdd(aLogAux,SA1->A1_INSCR)  
   aAdd(aLogAux,SA1->A1_EMAIL)  
   aAdd(aLogAux,SA1->A1_I_EMAIL)
   aAdd(aLogAux,SA1->A1_SUFRAMA)
   aAdd(aLogAux,SA1->A1_RISCO)  
   aAdd(aLogAux,TRansform(SA1->A1_LC,cPict))     
   aAdd(aLogAux,SA1->A1_I_CCHEP)
   aAdd(aLogAux,(_cAlias1)->NFS_CLIENTE)
   aAdd(aLogAux,(_cAlias1)->NFS_REDE) 

   aAdd(aLog,aLogAux)
   (_cAlias1)->(DBSkip())
	
EndDo

Return .T.
