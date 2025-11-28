/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |07/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
Alex Wallauer |14/10/2024| Chamado 48840. Ajustes dos titulos e mensagens.
Alex Wallauer |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MEST001
Autor-----------: Alex Wallauer
Data da Criacao-: 23/09/2021
Descrição-------: Rotina para verificar e ajustar problemas nos saldos empenhados das SAs- Chamado 37834
Parametros------: NENHUM
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function MEST001()
Local _aParRet :={} , nI
Local _aParAux :={} 
Local _bOK     :={||.T. }

Private _cAlias1	:= GetNextAlias()

_cSelectSB1:="SELECT B1_COD , B1_TIPO, B1_DESC FROM "+RETSQLNAME("SB1")+" SB1 WHERE D_E_L_E_T_ = ' ' AND B1_MSBLQL <> '1' ORDER BY B1_COD "
_aItalac_F3:={}//       1           2         3                      4                      5               6                    7         8          9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela ,_nCpoChave              , _nCpoDesc              ,_bCondTab    , _cTitAux         , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR01" ,_cSelectSB1,{|Tab|(Tab)->B1_COD},{|Tab|(Tab)->B1_TIPO+" "+(Tab)->B1_DESC}, ,"Produtos"        ,          ,          , 1        ,.F.        ,       , } )

MV_PAR01:=Space(20)
aAdd( _aParAux , { 1 , "Produto"	      , MV_PAR01, "@!"	, ""	, "F3ITLC"  , "" , 060 , .F. } )
For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next nI

While .T.

   If !ParamBox( _aParAux , "Digite o produto com Problema" , @_aParRet, _bOK )
       Exit
   EndIf
   
   cTimeInicial:=Time()
   MV_PAR01:=AllTrim(MV_PAR01)
   _cLogQry:=""
   aLog := {}
   lRet :=.T.
   SB2->(DBSetOrder(1))//B2_FILIAL+B2_COD+B2_LOCAL
   
   FWMsgRun( ,{|oProc|  lRet:=GeraLog(oProc) } , "Hora Inicial: "+cTimeInicial+" - Produto: "+MV_PAR01 )
    
   If Len(aLog) > 0
      
      aTitCol:={}
      aAdd(aTitCol,"TABELA")
      aAdd(aTitCol,"PRODUTO")
      aAdd(aTitCol,"D3_NUMSA ")
      aAdd(aTitCol,"D3_ITEMSA") 
      aAdd(aTitCol,"D3_QUANT")
      aAdd(aTitCol,"CQ_QUANT") 
      aAdd(aTitCol,"CQ_NUM ")   
      aAdd(aTitCol,"CQ_ITEM")
      aAdd(aTitCol,"CQ_NUMREQ")
      aAdd(aTitCol,"D3_NUMSEQ")
      aAdd(aTitCol,"D3_EMISSAO")
      aAdd(aTitCol,"D3_ESTORNO")
      aAdd(aTitCol,"D3_LOCAL")
      aAdd(aTitCol,"D3_TM")
      aAdd(aTitCol,"REC_SD3")
      aAdd(aTitCol,"REC_SCQ")
      
      cTit1:="Log (MEST001) Produto: "+If(!Empty(MV_PAR01),MV_PAR01,"Todos com problema na base")
      cTit2:="Produto: "+If(!Empty(MV_PAR01),MV_PAR01,"Todos com problema na base")+" / Hr Ini: "+cTimeInicial+" Hr final "+TIME()+" / Clique em Confirmar para gravar o CQ_NUMREQ e B2_QEMPSA! "
      _lOK:=.F.
      bOk:={|_oDlg| If(_lOK:= U_ITMsg("Confirma Gravar os dados ?",'Atenção!',,2,2,2) ,_oDlg:End(), ) }
   
    //                             , _aCols,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
      U_ITListBox(cTit1,aTitCol,aLog   ,.T.     ,1     ,cTit2    ,         ,        ,         , bOk )
      
      If _lOK//Grava os dados
         _lOK:=.F.
        (_cAlias1)->(DBGoTop())
        While !(_cAlias1)->(Eof())

           SD3->(DBGoTo((_cAlias1)->REC_SD3))
           SCQ->(DBGoTo((_cAlias1)->REC_SCQ))
           
  	        If SB2->(DBSeek(SD3->D3_FILIAL+SD3->D3_COD+SD3->D3_LOCAL)) .And. SB2->B2_QEMPSA >= SD3->D3_QUANT
              SB2->(RecLock( "SB2" , .F. )) 
              SB2->B2_QEMPSA:=(SB2->B2_QEMPSA-SD3->D3_QUANT)
              SB2->(MSUnLock()) 
              _lOK:=.T.
           Else
              (_cAlias1)->(DBSkip())
              Loop   
           EndIf

           SCQ->(RecLock( "SCQ" , .F. )) 
           SCQ->CQ_NUMREQ:=SD3->D3_NUMSEQ
           SCQ->(MSUnLock()) 

           (_cAlias1)->(DBSkip())
	
        EndDo
         If _lOK
            U_ITMsg("Dados gravados com SUCESSO para o PRODUTO: "+MV_PAR01,"Atencao!",,2)
         Else
            U_ITMsg("NAO Gravou para o PRODUTO: "+MV_PAR01,"Atencao!",,3)
         EndIf
         
         Exit   
      EndIf
   
   Else
   
      U_ITMsg("Nao foi encontrado dados para esse PRODUTO: "+MV_PAR01,"Atencao!",,3)
   
   EndIf

EndDo

If Select(_cAlias1) > 0
   (_cAlias1)->( DBCloseArea() )
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: GeraLog
Autor-------------: Alex Wallauer
Data da Criacao---: 23/09/2021
Descrição---------: Geração do Log de mão de obra 
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function GeraLog(OPROC)
Local _cQry:=""

If oproc <> nil
   oproc:cCaption := "Lendo SCQ/SD3... "
   ProcessMessages()
EndIf

_cQry+= "SELECT D3_FILIAL, D3_NUMSA, D3_ITEMSA, D3_COD, D3_QUANT, CQ_QUANT, CQ_NUM, CQ_PRODUTO, CQ_ITEM, CQ_NUMREQ, D3_EMISSAO, D3_ESTORNO, D3_TM, D3_NUMSEQ, D3_LOCAL, D3.R_E_C_N_O_ REC_SD3 , CQ.R_E_C_N_O_ REC_SCQ "
_cQry+= "FROM "+RETSQLNAME("SD3")+" D3 "
_cQry+= "JOIN "+RETSQLNAME("SCQ")+" CQ ON D3_FILIAL = CQ_FILIAL AND D3_NUMSA = CQ_NUM AND D3_ITEMSA = CQ_ITEM "
_cQry+= "WHERE D3.D_E_L_E_T_ = ' ' " 
_cQry+= "AND CQ.D_E_L_E_T_ = ' ' "
_cQry+=" AND D3_FILIAL = '"+cFilAnt+"' "
_cQry+= "AND D3_ESTORNO <> 'S' "
_cQry+= "AND CQ_NUMREQ = ' ' "
If !Empty(MV_PAR01)
   _cQry+= "AND CQ_PRODUTO = '"+MV_PAR01+"' "
EndIf
_cQry+= "ORDER BY D3_FILIAL, D3_NUMSA, D3_ITEMSA "

_cLogQry:=_cQry+CRLF

If Select(_cAlias1) > 0
   (_cAlias1)->( DBCloseArea() )
EndIf

_cQry := ChangeQuery(_cQry)
MPSysOpenQuery(_cQry,_cAlias1)

(_cAlias1)->(DBGoTop())                           

While !((_cAlias1)->(Eof()))

   If oproc <> nil
	  oproc:cCaption := "Listando SCQ/SD3... "
	  ProcessMessages()
   EndIf


   aLogAux:={}
   aAdd(aLogAux,"SQC/SD3")
   aAdd(aLogAux,AllTrim((_cAlias1)->D3_COD)+" - "+AllTrim(Posicione("SB1",1,xFilial("SB1")+(_cAlias1)->D3_COD,"B1_DESC")) ) 
   aAdd(aLogAux,(_cAlias1)->D3_NUMSA  )
   aAdd(aLogAux,(_cAlias1)->D3_ITEMSA ) 
   aAdd(aLogAux,TRANS((_cAlias1)->D3_QUANT,"@E 99,999,999,999.999")  )
   aAdd(aLogAux,TRANS((_cAlias1)->CQ_QUANT,"@E 99,999,999,999.999")  ) 
   aAdd(aLogAux,(_cAlias1)->CQ_NUM    )   
   aAdd(aLogAux,(_cAlias1)->CQ_ITEM   )
   aAdd(aLogAux,(_cAlias1)->CQ_NUMREQ )
   aAdd(aLogAux,(_cAlias1)->D3_NUMSEQ )
   aAdd(aLogAux,DToC(SToD((_cAlias1)->D3_EMISSAO)))
   aAdd(aLogAux,(_cAlias1)->D3_ESTORNO)
   aAdd(aLogAux,(_cAlias1)->D3_LOCAL)
   aAdd(aLogAux,(_cAlias1)->D3_TM)
   aAdd(aLogAux,(_cAlias1)->REC_SD3)
   aAdd(aLogAux,(_cAlias1)->REC_SCQ)

   aAdd(aLog,aLogAux)

  	SB2->(DBSeek((_cAlias1)->D3_FILIAL+(_cAlias1)->D3_COD+(_cAlias1)->D3_LOCAL))

   aLogAux:={}
   aAdd(aLogAux,"SB2")
   aAdd(aLogAux,AllTrim(SB2->B2_COD)+" - "+AllTrim(Posicione("SB1",1,xFilial("SB1")+SB2->B2_COD,"B1_DESC")) ) 
   aAdd(aLogAux,'' )
   aAdd(aLogAux,"B2_QEMPSA: ") 
   aAdd(aLogAux,TRANS(SB2->B2_QEMPSA,"@E 99,999,999,999.999")  )
   aAdd(aLogAux,""  ) 
   aAdd(aLogAux,"")   
   aAdd(aLogAux,"")
   aAdd(aLogAux,"")
   aAdd(aLogAux,"")
   aAdd(aLogAux,"")
   aAdd(aLogAux,"")
   aAdd(aLogAux,SB2->B2_LOCAL)
   aAdd(aLogAux,"Recno SB2:")
   aAdd(aLogAux,SB2->(Recno() ))
   aAdd(aLogAux,0)

   aAdd(aLog,aLogAux)

   (_cAlias1)->(DBSkip())
	
EndDo

Return .T.
