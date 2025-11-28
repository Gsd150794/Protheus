/*  
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS -                             
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer | 22/11/2023 | Chamado 45641. Troca do diretorio de geracao do PDF e delecao apos o envio do e-mail.
Alex Wallauer | 06/02/2024 | Chamado 45595. Andre/Jerry. Novos filtros de Filial e armazens e Ajustes.
=============================================================================================================================== 
Analista       - Programador     - Inicio     - Envio    - Chamado - Motivo de Alteração 
===============================================================================================================================
Lucas          - Alex Wallauer   - 02/05/25 - 06/05/25 - 50525   - Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "topconn.ch"
#Include "msmgadd.ch"
#Include "dbtree.ch"                  
#Include "RWMake.ch"
#Include "RPTDEF.CH"

#DEFINE _ENTER CHR(13)+CHR(10)

/*
===============================================================================================================================
Programa--------: ROMS079 // U_ROMS079
Autor-----------: Alex Wallauer
Data da Criacao-: 18/09/2023
===============================================================================================================================
Descrição-------: Chamado 44779 - Jerry. Relatórios de Ordem de Carga Consolidado. 
===============================================================================================================================
Parametros------: NENHUM
===============================================================================================================================
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function ROMS079()// U_ROMS079
Local nI , _nX
Local _aParAux:={}
Local _aParRet:={}
Local aAcesso := FWEmpLoad(.F.)
Local _cTitulo:="Relatorio de Ordens de Carga Consolidadas"

_aParOpc:={"1-Sim","2-Nao","3-Ambas"}
MV_PAR01:=Date()
MV_PAR02:=Date()
MV_PAR03:=3
MV_PAR04:=3
MV_PAR05:=Space(100)
MV_PAR06:=Space(100)

aAdd( _aParAux , { 1 , "Data da Carga de"               , MV_PAR01, "@D", "" , ""  , ""  , 060 , .T. })
aAdd( _aParAux , { 1 , "Data da Carga ate"              , MV_PAR02, "@D", "" , ""  , ""  , 060 , .T. })
aAdd( _aParAux , { 3 , "Cargas Faturadas"               , MV_PAR03, _aParOpc , 060 ,".T.",.T.  ,".T."}) 
aAdd( _aParAux , { 3 , "Lista Ordem de Carga já listada", MV_PAR04, _aParOpc , 060 ,".T.",.T.  ,".T."}) 
aAdd( _aParAux , { 1 , "Filiais"                        , MV_PAR05, "@!", "",'SM0001',"" , 100 , .F. })
aAdd( _aParAux , { 1 , "Armazens"                       , MV_PAR06, "@!", "",'NNRARM',"" , 100 , .F. })
      
For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next 
   
While .T.
  
      If !ParamBox( _aParAux , "Selecione os filtros" , _aParRet , {|| .T. } , , , , , , , .T. , .T. )
         Exit
      EndIf

      If !(MV_PAR02 >= MV_PAR01)
  	      U_ITMsg("Periodo da Data de Carga INVALIDO",'Atenção!',"Tente novamente com outro periodo",1)
  	      Loop
   	  EndIf
	  xVarAux := AllTrim(MV_PAR05)
	  _cFilsAcesso := ""
	  For _nX := 1 To Len(aAcesso)
	  	_cFilsAcesso+=aAcesso[_nX][03]+", "
	  Next
	  If Empty(xVarAux)
         U_ITMsg("Com a filial em branco, somente as filiais que o usuario tem acesso serao selecionadas: "+_cFilsAcesso+" (MV_PAR05)",'Atenção!',,1)
	  	 MV_PAR05:=StrTran( _cFilsAcesso, ", ", ";")
	  Else
	  	 aDadAux := U_ITLinDel( xVarAux , ";" )
	  	 SM0->(DBSetOrder(1))
	  	 For nI := 1 To Len(aDadAux)
	  		If !SM0->(DBSeek(cEmpAnt + aDadAux[nI]))
               U_ITMsg("Filial "+aDadAux[nI]+" informada não existe. (MV_PAR05)",'Atenção!',"Selecione no minimo uma Filial dessa lista: "+_cFilsAcesso,1)
	  		   Loop
	  		EndIf	  		
	  		If !aDadAux[nI] $ _cFilsAcesso
               U_ITMsg("Filial "+aDadAux[nI]+" informada o usuário não tem acesso.",'Atenção!',"Selecione no minimo uma Filial dessa lista: "+_cFilsAcesso,1)
	  		   Loop
	  		EndIf
	  	 Next
	  EndIf
      If ValType(MV_PAR03) = "N"
         MV_PAR03:=Str(MV_PAR03,1)
      EndIf
      If ValType(MV_PAR04) = "N"
         MV_PAR04:=Str(MV_PAR04,1)
      EndIf
      
      cTimeInicial:=Time()
      _cTitulo :="Relatorio de Ordens de Carga Consolidadas - "+DToC(DATE())
      _cTitProd:="Relatorio de Produtos Consolidados - "+DToC(DATE())

      aCab        :={}
      _aCabXML    :={}
      _aCabImp    :={}
      _aColXML    :={}
      _aDadosCarga:={}
      _aCargas    :={}

      _aCabItem   :={}
      _aCabItemImp:={}
      _aCabItemXML:={}
      _aColItemXML:={}
      _aDadosItem :={}

      nPosQt1m:=0
      nPosQt2m:=0
      nPosPBru:=0
	  nPosQPal:=0
      nPosPtos:=0
      nPosFil :=0
      nPosCar :=0
  	   FWMsgRun(,{|oproc|  ROMS79CP(oproc)  }, "Selecionando Cargas - Hr. Ini. : "+cTimeInicial,"Filtrando Cargas..." )
  	   
      _cTitulo2:=_cTitulo+" H. F. : "+Time()
      _cMsgTop:="Data da Carga: "  +AllTrim(AllToChar(MV_PAR01))+" ate "+AllTrim(AllToChar(MV_PAR02))+"; Cargas Faturadas: " +_aParOpc[Val(MV_PAR03)]+"; Lista Ordem de Carga já listada: "+_aParOpc[Val(MV_PAR04)]+" - Hr. Ini. : "+cTimeInicial+" / H. F. : "+Time()

      While Len(_aDadosCarga) > 0 
         
         _cMsgFil:=_cTitulo2+_ENTER+;
                   "Data da Carga: "                  +AllTrim(AllToChar(MV_PAR01))+" ate "+AllTrim(AllToChar(MV_PAR02))+_ENTER+;
                   "Cargas Faturadas: "               +_aParOpc[Val(MV_PAR03)]+_ENTER+;
                   "Lista Ordem de Carga já listada: "+_aParOpc[Val(MV_PAR04)]

         _aSX1:=ROMS79Per()
         aBotoes:={}
         aAdd(aBotoes,{"",{|| FWMsgRun(,{|oProc|  RCOM079M(oProc)  },"Preprando Tela...","Para enviar e-mail com PDF...")  },"","Enviar e-mail com PDF"})
         aAdd(aBotoes,{"",{|| U_ITListBox(_cTitProd,_aCabItem,_aDadosItem,.T.,1,_cMsgTop,,,,,,,_aCabItemXML,,_aColItemXML) },"","Produtos Consolidados"})
         aAdd(aBotoes,{"",{|| U_ITMsgLog(_cMsgFil, "FILTROS APLICADOS" )                                                   },"","Filtros Aplicados"    })
 
                          //      ,_aCols       ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab   , bDblClk , _aColXML , bCondMarca,_bLegenda,_lHasOk,_bHeadClk,_aSX1 )
         U_ITListBox(_cTitulo2,aCab,_aDadosCarga, .T.    , 2    ,_cMsgTop ,          ,       ,         ,     ,        , aBotoes  , _aCabXML,         , _aColXML ,           ,         ,       ,         ,_aSX1)
	
	     If !U_ITMsg("Confirma Sair ?",'Atenção!',_cTitulo2,3,2,2)
		    Loop
		 EndIf
         Exit
    EndDo

EndDo

Return .T.

/*
===============================================================================================================================
Programa--------: ROMS79CP
Autor-----------: Alex Wallauer
Data da Criacao-: 18/09/2023
===============================================================================================================================
Descrição-------: Ler os dados da Select e grava da array
===============================================================================================================================
Parametros------: oProc 
===============================================================================================================================
Retorno---------: _aDadosCarga
===============================================================================================================================*/
Static Function ROMS79CP(oproc)
Local _cQuery    := "" , L
Local _cAlias    := GetNextAlias()
Local _cPicPeso  := PesqPict("DAK","DAK_PESO")
Local _cPicValor := PesqPict("DAK","DAK_VALOR")

aCab    :={}
_aCabXML:={}
_aCabImp:={}

If oproc <> NIL
   oproc:cCaption := ("Filtrando dados ..." )
   ProcessMessages() 
EndIf

// Alinhamento: 1-Left   ,2-Center,3-Right
// Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
//             Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
//   (_aCabXML,{Titulo             ,1           ,1         ,.F.       })
aAdd(aCab   , "") 
aAdd(_aCabXML,{""                  ,2           ,1         ,.F.})// 01

aAdd(aCab   , "")
aAdd(_aCabXML,{"Enviado"           ,2           ,1         ,.F.})// 02

aAdd(aCab   , "Filial")            ; nPosFil:=Len(aCab)
aAdd(_aCabXML,{aCab[Len(aCab)]     ,2           ,1         ,.F.})// 03
aAdd(_aCabImp,"Fil")

aAdd(aCab   , "Carga")             ; nPosCar:=Len(aCab)
aAdd(_aCabXML,{aCab[Len(aCab)]     ,2           ,1         ,.F.})// 04
aAdd(_aCabImp,aCab[Len(aCab)])

aAdd(aCab   , "Peso")              ; nPosPeso:=Len(aCab)
aAdd(_aCabXML,{aCab[Len(aCab)]     ,3           ,2         ,.F.,_cPicPeso})// 05
aAdd(_aCabImp,aCab[Len(aCab)])

aAdd(aCab   , "Veículo")
aAdd(_aCabXML,{aCab[Len(aCab)]     ,1           ,1         ,.F.})// 06
aAdd(_aCabImp,aCab[Len(aCab)])

aAdd(aCab   , "Desc. Veículo")
aAdd(_aCabXML,{aCab[Len(aCab)]     ,1           ,1         ,.F.})// 07
aAdd(_aCabImp,aCab[Len(aCab)])

aAdd(aCab   , "Cod.Motorista")
aAdd(_aCabXML,{aCab[Len(aCab)]     ,1           ,1         ,.F.})// 08
aAdd(_aCabImp,aCab[Len(aCab)])

aAdd(aCab   , "Nome Motorista")
aAdd(_aCabXML,{aCab[Len(aCab)]     ,1           ,1         ,.F.})// 09
aAdd(_aCabImp,"Motorista"    )

aAdd(aCab   , "Ptos de Entrega")   ; nPosPEnt:=Len(aCab)
aAdd(_aCabXML,{aCab[Len(aCab)]     ,3           ,2         ,.F.,"@E 9,999"})// 10
aAdd(_aCabImp,"Ptos.Ent"     )

aAdd(aCab   , "Valor Carga")       ; nPosVlor:=Len(aCab)
aAdd(_aCabXML,{aCab[Len(aCab)]     ,3           ,3         ,.F.,_cPicValor})// 11
aAdd(_aCabImp,aCab[Len(aCab)])

aAdd(aCab   , "Pre-Carga?")
aAdd(_aCabXML,{aCab[Len(aCab)]      ,2           ,1         ,.F.})// 12
aAdd(_aCabImp,"Pre Carga"     )

aAdd(aCab   , "Data")              ;nPosData:=Len(aCab) 
aAdd(_aCabXML,{aCab[Len(aCab)]     ,2           ,4         ,.F.})// 13
aAdd(_aCabImp,aCab[Len(aCab)])

aAdd(aCab   , "Hora")
aAdd(_aCabXML,{aCab[Len(aCab)]     ,2           ,1         ,.F.})// 14
aAdd(_aCabImp,aCab[Len(aCab)])

aAdd(aCab   , "Qtd Envio")         ; nPosQEnv:=Len(aCab)
aAdd(_aCabXML,{aCab[Len(aCab)]     ,3           ,2         ,.F.,"@E 9,999"})//15
aAdd(_aCabImp,"Envio"        )

_aCabItem   :={}
_aCabItemXML:={}
_aCabItemImp:={}

aAdd(_aCabItem   , "Cod. Produto - Amz") 
aAdd(_aCabItemXML,{_aCabItem[Len(_aCabItem)]     ,2           ,1         ,.F.})                          // 01
aAdd(_aCabItemImp,"Produto - Amz")

aAdd(_aCabItem   , "Descricao do Produto")
aAdd(_aCabItemXML,{_aCabItem[Len(_aCabItem)]     ,1           ,1         ,.F.})                          // 02
aAdd(_aCabItemImp,_aCabItem[Len(_aCabItem)])

aAdd(_aCabItem   , "Qt Liberada 1a UM")          ; nPosQt1m:=Len(_aCabItem) 
aAdd(_aCabItemXML,{_aCabItem[Len(_aCabItem)]     ,3           ,2         ,.F.,"@E 999,999,999,999.999" })// 03
aAdd(_aCabItemImp,"Qt.Lib.1UM"             )

aAdd(_aCabItem   , "Unidade")       
aAdd(_aCabItemXML,{_aCabItem[Len(_aCabItem)]     ,2           ,1         ,.F.})                          // 04
aAdd(_aCabItemImp,"1a UM"                    )

aAdd(_aCabItem   , "Qt Liberada 2a UM")          ; nPosQt2m:=Len(_aCabItem) 
aAdd(_aCabItemXML,{_aCabItem[Len(_aCabItem)]     ,3           ,2         ,.F.,"@E 999,999,999,999.999" })// 05
aAdd(_aCabItemImp,"Qt.Lib.2UM"             )

aAdd(_aCabItem   , "Seg Um")
aAdd(_aCabItemXML,{_aCabItem[Len(_aCabItem)]     ,2           ,1         ,.F.})                          // 06
aAdd(_aCabItemImp,"2a UM"                    )

aAdd(_aCabItem   , "Peso Bruto Total")           ; nPosPBru:=Len(_aCabItem) 
aAdd(_aCabItemXML,{_aCabItem[Len(_aCabItem)]     ,3           ,2         ,.F.,"@E 999,999,999,999.9999"})// 07
aAdd(_aCabItemImp,"Peso Bruto Tot"         )

aAdd(_aCabItem   , "Qtd Pallet")                 ; nPosQPal:=Len(_aCabItem) 
aAdd(_aCabItemXML,{_aCabItem[Len(_aCabItem)]     ,1           ,1         ,.F.})                          // 08
aAdd(_aCabItemImp,_aCabItem[Len(_aCabItem)])

aAdd(_aCabItem   , "Valor Total Prod.")          ; nPosPtos:=Len(_aCabItem)
aAdd(_aCabItemXML,{_aCabItem[Len(_aCabItem)]     ,3           ,3         ,.F.,"@E 999,999,999,999.99"  })// 09
aAdd(_aCabItemImp,"Vlr. Total Prod."         )


_cQuery += "  SELECT DAK.R_E_C_N_O_ REC_DAK FROM DAK010 DAK "
_cQuery += "     WHERE DAK.D_E_L_E_T_ = ' ' "

If !Empty(MV_PAR01)
   _cQuery += "  AND DAK_DATA >= '" + DToS(MV_PAR01)+"' "
EndIf
If !Empty(MV_PAR02)
   _cQuery += "  AND DAK_DATA <= '" + DToS(MV_PAR02)+"' "
EndIf
If LEFT(MV_PAR03,1) $ "1,2"
   _cQuery += "  AND DAK_FEZNF = '" + LEFT(MV_PAR03,1)+"' "
EndIf
If LEFT(MV_PAR04,1) = "1" //Já Enviado
   _cQuery += "  AND DAK_I_ENV <> 0 "
ElseIf LEFT(MV_PAR04,1) = "2"//Não Enviado
   _cQuery += "  AND DAK_I_ENV = 0 "
EndIf
If !Empty(MV_PAR05)
   _cQuery += "  AND DAK_FILIAL IN " + FormatIn(AllTrim(MV_PAR05), ";") + " " 
EndIf
If !Empty( MV_PAR06 )// Filtra Armazens
   _cQuery += "AND EXISTS (SELECT 'Y' FROM " +RETSQLNAME("SC9")+" C9 WHERE C9.D_E_L_E_T_ = ' ' AND C9.C9_FILIAL = DAK.DAK_FILIAL AND C9.C9_CARGA = DAK.DAK_COD "
   _cQuery += "AND C9.C9_LOCAL IN "+ FormatIn( AllTrim(MV_PAR06) , ";" ) + " )" 	
EndIf

_cQuery += " ORDER BY DAK_COD "
cTimeINI:=Time()
 DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )
   
_nTot:=nConta:=0
COUNT TO _nTot
_cTotGeral:=AllTrim(Str(_nTot))
cTimeFIM:="Hora Incial: "+cTimeINI+" - Hora Final: "+TIME()+" da leitura dos dados"
(_cAlias)->(DBGoTop())
If (_cAlias)->(Eof())
   U_ITMsg("Não tem Acordos para processamento com esses filtros.",cTimeFIM,"Altere os filtros.",3) 
   Return {}
EndIf
      
If !U_ITMsg("Serão processados "+_cTotGeral+' registros, Confirma ?',cTimeFIM,,3,2,3,,"CONFIRMA","VOLTAR")
   Return {}
EndIf

DAK->( DBSetOrder(1) )
DAI->( DBSetOrder(1) )
SC9->( DBSetOrder(1) )
SB1->( DBSetOrder(1) )
SC6->( DBSetOrder(1) )
      
_aDadosCarga:={}
While (_cAlias)->(!Eof()) //**********************************  While  ******************************************************
            
   nConta++
   oproc:cCaption := ("Lendo "+StrZero(nConta,5) +" de "+ _cTotGeral )
   ProcessMessages()

   DAK->(DBGoTo((_cAlias)->REC_DAK))
   _aPedCarga := {}
   
   aAdd(_aPedCarga ,.T.)//01 
   
   If DAK->DAK_I_ENV > 0 //Já Enviado
      aAdd(_aPedCarga ,.F.)//02 
   Else//Não Enviado
      aAdd(_aPedCarga ,.T.)//02 
   EndIf

   aAdd(_aPedCarga ,DAK->DAK_FILIAL )                                                         //03
   aAdd(_aPedCarga ,DAK->DAK_COD    )                                                         //04           
   aAdd(_aPedCarga ,DAK->DAK_PESO   )                                                         //05           
   aAdd(_aPedCarga ,DAK->DAK_CAMINH )                                                         //06           
   aAdd(_aPedCarga ,Posicione("DA3",1,xFilial("DA3")+DAK->DAK_CAMINH,"DA3_DESC") )            //07 - DA3 É compartilhada
   aAdd(_aPedCarga ,DAK->DAK_MOTORI )                                                         //08           
   aAdd(_aPedCarga ,AllTrim(Posicione("DA4",1,xFilial("DA4")+DAK->DAK_MOTORI,"DA4_NOME"))  )  //09 - DA4 É compartilhada
   aAdd(_aPedCarga ,DAK->DAK_PTOENT )                                                         //10           
   aAdd(_aPedCarga ,DAK->DAK_VALOR  )                                                         //11           
   aAdd(_aPedCarga ,If(DAK->DAK_I_PREC="1","Sim","Não") )                                     //12                               
   aAdd(_aPedCarga ,DAK->DAK_DATA   )                                                         //13         
   aAdd(_aPedCarga ,DAK->DAK_HORA   )                                                         //14         
   aAdd(_aPedCarga ,DAK->DAK_I_ENV  )                                                         //15

   aAdd(_aDadosCarga , _aPedCarga )

	//====================================================================================================
	// Compondo os dados do produto
	//====================================================================================================
   If DAI->( DBSeek( DAK->DAK_FILIAL + DAK->DAK_COD ) )
	
	  While DAI->( !Eof() ) .And. DAI->( DAI_FILIAL + DAI_COD ) == DAK->DAK_FILIAL + DAK->DAK_COD
		
			If SC6->( DBSeek( DAI->DAI_FILIAL + DAI->DAI_PEDIDO ) )
			
			   While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == DAI->DAI_FILIAL+DAI->DAI_PEDIDO

				  If !Empty(MV_PAR06) .And. !SC6->C6_LOCAL $ AllTrim(MV_PAR06)   
				     SC6->( DBSkip() )
					 Loop
				  EndIf
				  SB1->( DBSeek( xFilial("SB1")  + SC6->C6_PRODUTO ) )
				  SC9->( DBSeek( SC6->C6_FILIAL + SC6->C6_NUM + SC6->C6_ITEM ) )

                  _cDescItem:=SB1->B1_DESC

				   If (nPos := aScan( _aDadosItem , { |x| x[1] == AllTrim(SC6->C6_PRODUTOS)+"-"+SC6->C6_LOCAL } ) ) == 0
                      
					  _aProds:={}
                      aAdd(_aProds , AllTrim(SC6->C6_PRODUTOS)+"-"+SC6->C6_LOCAL)//01
                      aAdd(_aProds , _cDescItem                          )//02
                      aAdd(_aProds , SC9->C9_QTDLIB                      )//03
                      aAdd(_aProds , SB1->B1_UM                          )//04
                      aAdd(_aProds , SC9->C9_QTDLIB2                     )//05
                      aAdd(_aProds , SB1->B1_SEGUM                       )//06
                      aAdd(_aProds , ( SB1->B1_PESBRU * SC9->C9_QTDLIB ) )//07
                      aAdd(_aProds , " "                                 )//08
                      aAdd(_aProds , ( SC9->C9_QTDLIB * SC9->C9_PRCVEN ) )//09
                      
					  aAdd(_aDadosItem , _aProds )
				   Else
					  _aDadosItem[nPos][nPosQt1m] += SC9->C9_QTDLIB                  //03   
					  _aDadosItem[nPos][nPosQt2m] += SC9->C9_QTDLIB2                 //05 
					  _aDadosItem[nPos][nPosPBru] +=(SB1->B1_PESBRU * SC9->C9_QTDLIB)//07
					  _aDadosItem[nPos][nPosPtos] +=(SC9->C9_QTDLIB * SC9->C9_PRCVEN)//09			
				   EndIf
				   SC6->( DBSkip() )

				EndDo
		
			EndIf
			DAI->( DBSkip() )
		EndDo
	EndIf

   (_cAlias)->(DBSkip())
      
EndDo

oproc:cCaption := ("Acertos finais...")

(_cAlias)->(DBCloseArea())

_aColXML:=ACLONE(_aDadosCarga)//FORMATO PARA GERAR O EXCEL CORRETO EM INGLES COM PONTO
For L := 1 TO Len(_aColXML)    //AJUSTE PARA GERAR O EXCEL CORRETO
    _aColXML[L,1]:=" "//If(_aColXML[L,1],"X"," ") Retirei pq senão vai ter que ficar repricando sempre o _aColXML
    _aColXML[L,2]:=If(_aColXML[L,2],"NAO","SIM")
Next

For L := 1 TO Len(_aDadosCarga)//AJUSTE PARA MOSTRA NA TELA DO U_ITListBox CORRETO
    _aDadosCarga[L,nPosPeso]:= TRANSFORM(_aDadosCarga[L,nPosPeso],_cPicPeso )// DAK->DAK_PESO 
    _aDadosCarga[L,nPosPEnt]:= TRANSFORM(_aDadosCarga[L,nPosPEnt],"@E 9,999")// DAK->DAK_PTOENT
    _aDadosCarga[L,nPosVlor]:= TRANSFORM(_aDadosCarga[L,nPosVlor],_cPicValor)// DAK->DAK_VALOR
    _aDadosCarga[L,nPosQEnv]:= TRANSFORM(_aDadosCarga[L,nPosQEnv],"@E 9,999")// DAK->DAK_I_ENV
    _aDadosCarga[L,nPosData]:= DToC(_aDadosCarga[L,nPosData]                )// DAK->DAK_DATA	
Next

For L := 1 TO Len(_aDadosItem)//CALCULA A QDE DE Pallets 00 21 00 19 90 1
    If SB1->( DBSeek( xFilial("SB1") + LEFT(_aDadosItem[L,1],11) ) )
	   _aDadosItem[L,nPosQPal]:= REST79SPal(_aDadosItem[L,nPosQt1m],_aDadosItem[L,nPosQt2m],SB1->B1_SEGUM,SB1->B1_TIPO)
	EndIf
Next

_aColItemXML:=ACLONE(_aDadosItem)//FORMATO PARA GERAR O EXCEL CORRETO EM INGLES COM PONTO

For L := 1 TO Len(_aDadosItem)//AJUSTE PARA MOSTRA NA TELA DO U_ITListBox CORRETO
    _aDadosItem[L,nPosQt1m]:= TRANSFORM(_aDadosItem[L,nPosQt1m],"@E 999,999,999,999.999" )// SC9->C9_QTDLIB   
    _aDadosItem[L,nPosQt2m]:= TRANSFORM(_aDadosItem[L,nPosQt2m],"@E 999,999,999,999.999" )// SC9->C9_QTDLIB2  
    _aDadosItem[L,nPosPBru]:= TRANSFORM(_aDadosItem[L,nPosPBru],"@E 999,999,999,999.9999")// SB1->B1_PESBRU * SC9->C9_QTDLIB
    _aDadosItem[L,nPosPtos]:= TRANSFORM(_aDadosItem[L,nPosPtos],"@E 999,999,999,999.99"  )// SC9->C9_QTDLIB * SC9->C9_PRCVEN 
Next

aSort(_aDadosItem,,,{|x,y|x[2]<y[2]})

Return 
/*
===============================================================================================================================
Programa--------: ROMS79Per
Autor-----------: Alex Wallauer
Data da Criacao-: 18/09/2023
===============================================================================================================================
Descrição-------: Parâmetros do relatório
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: _aPergunte
===============================================================================================================================
*/               
Static Function ROMS79Per()
Local _aDadosPegunte := {}
Local _aPergunte := {}
Local nI
Local _cTexto

aAdd(_aDadosPegunte,{"01", "Data da Carga de"               , "MV_PAR01"})
aAdd(_aDadosPegunte,{"02", "Data da Carga ate"              , "MV_PAR02"})   
aAdd(_aDadosPegunte,{"03", "Cargas Faturadas"               , "MV_PAR03"})
aAdd(_aDadosPegunte,{"04", "Lista Ordem de Carga já listada", "MV_PAR04"})   
aAdd(_aDadosPegunte,{"05", "Filiais selecionadas"           , "MV_PAR05"})   
aAdd(_aDadosPegunte,{"06", "Armazens selecionados"          , "MV_PAR06"})   

For nI := 1 To Len(_aDadosPegunte)          
    _cTexto := ""
	 
    If _aDadosPegunte[nI,3] == "MV_PAR03" .Or. _aDadosPegunte[nI,3] == "MV_PAR04"
	   If AllToChar(MV_PAR14) ==  "1"
	      _cTexto := "Sim"
	   ElseIf AllToChar(MV_PAR14) == "2"
	      _cTexto := "Não"
	   Else
	      _cTexto := "Ambas"
	   EndIf

    Else
       _cTexto := &(_aDadosPegunte[nI,3])
       If ValType(_cTexto) == "D"
          _cTexto := DToC(_cTexto)
       EndIf   
    EndIf	

    aAdd(_aPergunte,{"Pergunta " + _aDadosPegunte[nI,1] + ':',_aDadosPegunte[nI,2],_cTexto })

Next
Return _aPergunte

/*
===============================================================================================================================
Programa--------: RCOM079M
Autor-----------: Alex Wallauer
Data da Criacao-: 18/09/2023
===============================================================================================================================
Descrição-------: Função responsável por exibir a janela para a digitação dos endereços de email e Observação
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function RCOM079M(oProc)
Local oAnexo
Local oAssunto
Local oButCan
Local oButEnv
Local oCc
Local oGetAnx
Local oGetAssun
Local oGetCc
Local oGetPara
Local oMens
Local oPara

Local _aConfig	:= U_ITCFGEML('')
Local _cEmlLog	:= ""
Local _cObs		:= Space(200)
Local nOpcA		:= 2 , R

Local cGetAssun := "Lista de Ordens de Carga Consolidadas da Filial "+cFilAnt+" - "+AllTrim( Posicione('SM0',1,"01"+cFilAnt,'M0_FILIAL') )+" - "+DToC(DATE())+" - "+TIME()+Space(300)
Local cFileName	:= "ROMS079_"+DToS(DATE())+"_"+StrTran(TIME(),":","_")+".PDF"
Local cGetPara	:= UsrRetMail(__cUserId)+Space(300)
Local cGetCc	:= Space(300)

Private cPathSrv:= GETMV("MV_RELT",,"\SPOOL\")

ROMS079B(cPathSrv,cFileName) // GERA O PDF ****************************************

cGetAnx := cPathSrv+cFileName///spool
_cPathLocal:=GetTempPath()

If File(cGetAnx) 
	//Copia arquivo da spool para estação local
	If !CpyS2T(cGetAnx,_cPathLocal)
		U_ITMsg("Não foi possivel copiar o arquivo "+cGetAnx+" para "+_cPathLocal,'Atenção!',"Feche o arquivo "+cGetAnx+", caso aberto,e tente novamente",1)
		_cPathLocal:=""
	Else
        _cOrigem2:=StrTran( cGetAnx, cPathSrv, _cPathLocal ) 
	EndIf
Else
    U_ITMsg("Não foi possivel localizar o arquivo "+cGetAnx,'Atenção!',"Tente novamente.",1)
EndIf


Private oDlgMail

DEFINE MSDIALOG oDlgMail TITLE "E-Mail" FROM 000, 000  TO 415, 584   PIXEL

	@ 005, 006 Say oPara PROMPT "Para:" SIZE 015, 007 OF oDlgMail   PIXEL
	@ 005, 030 MSGET oGetPara VAR cGetPara SIZE 256, 010 OF oDlgMail PICTURE "@!"    PIXEL

	@ 021, 006 Say oCc PROMPT "Cc:" SIZE 015, 007 OF oDlgMail   PIXEL
	@ 021, 030 MSGET oGetCc VAR cGetCc SIZE 256, 010 OF oDlgMail PICTURE "@!"    PIXEL

	@ 037, 006 Say oAssunto PROMPT "Assunto:" SIZE 022, 007 OF oDlgMail   PIXEL
	@ 037, 030 MSGET oGetAssun VAR cGetAssun SIZE 256, 010 OF oDlgMail PICTURE "@!"    PIXEL

	@ 053, 006 Say oAnexo PROMPT "Anexo:" SIZE 019, 007 OF oDlgMail   PIXEL
	@ 053, 030 MSGET oGetAnx VAR cGetAnx SIZE 256, 010 OF oDlgMail PICTURE "@!"    READONLY PIXEL

	@ 069, 006 Say oMens PROMPT "Observacao:" SIZE 030, 007 OF oDlgMail   PIXEL
	_oScrAux	:= TSimpleEditor():New( 080 , 006 , oDlgMail , 285 , 105 ,,,,, .T. )
	
	_oScrAux:Load( _cObs )
	If !Empty(_cPathLocal)
       @ 189, 156 BUTTON oButEnv PROMPT "&Visualizar"	SIZE 037, 012 OF oDlgMail ACTION ( ShellExecute("open", _cOrigem2, "", _cPathLocal, 1) ) PIXEL
	EndIf
	@ 189, 201 BUTTON oButEnv PROMPT "&Enviar"		SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 1 , _cObs := _oScrAux:RetText() , oDlgMail:End() ) PIXEL
	@ 189, 245 BUTTON oButCan PROMPT "&Cancelar"	SIZE 037, 012 OF oDlgMail ACTION ( nOpcA := 2 , oDlgMail:End() ) PIXEL

ACTIVATE MSDIALOG oDlgMail CENTERED

If nOpcA == 1
   _cFiltros:="Periodo de "+AllTrim(AllToChar(MV_PAR01))+" ate "+AllTrim(AllToChar(MV_PAR02))+_ENTER
   _cFiltros+="Cargas Faturadas? "+SubStr(_aParOpc[Val(MV_PAR03)],3)+_ENTER
   _cFiltros+="Ordens de Cargas já listadas? "+SubStr(_aParOpc[Val(MV_PAR04)],3)+_ENTER
   _cFiltros+="Armazens? "+AllTrim(MV_PAR06)+_ENTER

    _cMsgEml := '<html>'
    _cMsgEml += '<head><title>'+cGetAssun+'</title></head>'
    _cMsgEml += '<body>'
    _cMsgEml += '<style Type="text/css"><!--'
    _cMsgEml += 'table.bordasimples { border-collapse: collapse; }'
    _cMsgEml += 'table.bordasimples tr td { border:1px solid #777777; }'
    _cMsgEml += 'td.titulos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #C6E2FF; }'
    _cMsgEml += 'td.grupos	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #E5E5E5; }'
    _cMsgEml += 'td.itens	{ font-family:VERDANA; font-size:12px; V-align:middle; margin-right: 15px; margin-left: 15px; background-color: #FFFFFF; }'
    _cMsgEml += '--></style>'
    _cMsgEml += '<center>'
    _cMsgEml += '<img src="http://www.italac.com.br/wf/italac-wf.jpg" width="600" height="50"><br>'
    _cMsgEml += '<table class="bordasimples" width="600">'
    _cMsgEml += '    <tr>'
    _cMsgEml += '	     <td class="titulos"><center>LISTA DE ORDEMS DE CARGA CONSOLIDADAS</center></td>'
    _cMsgEml += '	 </tr>'
    _cMsgEml += '</table>'
    _cMsgEml += '<br>'
    _cMsgEml += '<table class="bordasimples" width="600">'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td align="center" colspan="2" class="grupos">Dados do Envio</b></td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Enviado por: </b></td>'
    _cMsgEml += '      <td class="itens" >'+ UsrFullName(__cUserId) +'</td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '    <tr>'
	If Len(AllTrim(MV_PAR05)) = 2 
       _cMsgEml += ' <td class="itens" align="center" width="30%"><b>Filial: </b></td>'
       _cMsgEml += ' <td class="itens" >'+ AllTrim(MV_PAR05)+" - "+AllTrim( Posicione('SM0',1,"01"+AllTrim(MV_PAR05),'M0_FILIAL') ) +'</td>'
    Else
       _cMsgEml += ' <td class="itens" align="center" width="30%"><b>Filiais: </b></td>'
       _cMsgEml += ' <td class="itens" >'+ AllTrim(MV_PAR05) +'</td>'
	EndIf
    _cMsgEml += '    </tr>'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Filtros:</b></td>'
    _cMsgEml += '      <td class="itens" >'+ _cFiltros +'</td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" width="30%"><b>Observações:</b></td>'
    _cMsgEml += '      <td class="itens" >'+ _cObs +'</td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '</table>'
    _cMsgEml += '</center>'
    _cMsgEml += '<br>'
    _cMsgEml += '<br>'
    _cMsgEml += '    <tr>'
    _cMsgEml += '      <td class="itens" align="center" ><b>Ambiente:</b></td>'
    _cMsgEml += '      <td class="itens" align="left" > ['+ GETENVSERVER() +'] / <b>Fonte:</b> [ROMS079]</td>'
    _cMsgEml += '    </tr>'
    _cMsgEml += '</body>'
    _cMsgEml += '</html>'

	//cGetPara:=StrTran( cGetPara, ";", "," )
	//cGetCc  :=StrTran( cGetCc  , ";", "," )

	U_ITENVMAIL( Lower(AllTrim(UsrRetMail(RetCodUsr()))), cGetPara, cGetCc, "", cGetAssun, _cMsgEml, cGetAnx, _aConfig[01], _aConfig[02], _aConfig[03], _aConfig[04], _aConfig[05], _aConfig[06], _aConfig[07], @_cEmlLog )

	If !Empty( _cEmlLog )
       If "SUCESSO" $ Upper(_cEmlLog)
           For R := 1 TO Len(_aCargas)
			   If DAK->(DBSeek(_aCargas[R])) 
                  DAK->( RecLock("DAK",.F.) )           
                  DAK->DAK_I_ENV++
                  DAK->( MSUnLock() )
			   EndIf
           Next
       EndIf
    EndIf
	
	U_ITMsg( _cEmlLog+_ENTER+"E-mail para: "+AllTrim(cGetPara)+_ENTER+"CC: "+cGetCc , 'Término do processamento!' , ,3 )

    If cGetAnx # nil .And. FILE(cGetAnx)
       FErase(cGetAnx)
       U_ITCONOUT("Arquivo "+cGetAnx+" apagado com sucesso")
    EndIf    
    
	If cGetAnx # nil
	   cGetAnx:=StrTran( Upper(cGetAnx), ".PDF", ".REL")
	   If FILE(cGetAnx)
          FErase(cGetAnx)
	   EndIf
    EndIf    

EndIf

Return

/*
===============================================================================================================================
Programa--------: ROMS079B
Autor-----------: Alex Wallauer
Data da Criacao-: 18/09/2023
===============================================================================================================================
Descrição-------: Ler os dados do listbox
===============================================================================================================================
Parametros------: cLocal,cFileName
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/  
Static Function ROMS079B(cLocal,cFileName)

       //FWMsPrinter():New(cFilePrintert,nDevice],lAdjustToLegacy], [ cPathInServer], [ lDisabeSetup ], [ lTReport], [ @oPrintSetup], [ cPrinter], [ lServer], [ lPDFAsPNG], [ lRaw], [ lViewPDF], [ nQtdCopy] )
oPrint:= FwMsPrinter():New(cFileName    , IMP_PDF, .T.            , cLocal          , .T.          )//, .T.        ,  NIL           , NIL        , NIL       , NIL         , NIL    , .F.        , NIL         )
oPrint:SetLandScape()    // Fixa a Impressao em Retrato //oPrint:SetPortrait()
oPrint:cPathPDF := cLocal
oPrint:SetViewPDF(.F.)

Processa( {|| ROMS079C() }, "Aguarde...", "Montando PDF...",.F.)

LjMsgRun( "Gerando a PDF: +"+cLocal+cFileName, "Aguarde..." , {|| oPrint:Preview() } )//Visualiza antes de imprimir

Return .T.
/*
===============================================================================================================================
Programa--------: ROMS079C
Autor-----------: Alex Wallauer
Data da Criacao-: 18/09/2023
===============================================================================================================================
Descrição-------: Geração dos dados em PDF
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/ 
Static Function ROMS079C()

Local  ni , L , _nTamDes := 50
Private _nLinhaIni := 70
Private _nLinha    := _nLinhaIni 
Private _nLinMax   := 2400
Private _nColIni   := 10

//COLUNAS DOS PRODUTOS
Private _nColI02:=_nColIni+225//Descricao do Produto
Private _nColI03:=_nColI02+800//Qt 1a
Private _nColI04:=_nColI03+365//1 UM
Private _nColI05:=_nColI04+100//Qt 2a
Private _nColI06:=_nColI05+365//2 UM
Private _nColI07:=_nColI06+120//Peso Bruto Tot
Private _nColI08:=_nColI07+335//Qtd Pal
Private _nColI09:=_nColI08+435//Vlr. Tot. Prod

//COLUNAS DAS CARGAS
Private _nColCar:=_nColIni+55 //Carga
Private _nColC02:=_nColCar+160//Peso
Private _nColC03:=_nColC02+220//Veiculo
Private _nColC04:=_nColC03+165//Desc. Vei.
Private _nColC05:=_nColC04+440//Cod. Motorista
Private _nColC06:=_nColC05+235//Motorista
Private _nColC07:=_nColC06+700//Ptos 
Private _nColC08:=_nColC07+200//Valor 
Private _nColC09:=_nColC08+295//Pre Carga
Private _nColC10:=_nColC09+145//Data
Private _nColC11:=_nColC10+150//Hora
Private _nColC12:=_nColC11+145//Envio

//Configuracoes para "Exporta para PDF" / Envio via e-mail
Private _nColMax	:= 3280
Private _nColFimPDH := _nColMax-1150
//                                  Fonte          Tamanho   Negrito
Private _oFont18	:= TFont():New( "Arial"     ,, 28      ,, .T.)
Private _oFontIT    := TFont():New('Courier new',, 12      ,, .F.)
//Configuracoes para "Exporta para PDF" / Envio via e-mail

ProcRegua(Len(_aDadosCarga))
IncProc("Contando Marcados de " + StrZero(Len(_aDadosCarga),6))
nConta:=0
For NI := 1 TO Len(_aDadosCarga)
    If !_aDadosCarga[NI][01] 
	   Loop
	EndIf
    //IncProc("Contando Marcados: " + StrZero(NI,5) + " de " + StrZero(Len(_aDadosCarga),6))
    nConta++
Next
IncProc("Contando Marcados: " + StrZero(nConta,5) + " de " + StrZero(Len(_aDadosCarga),6))

_aDadosAuxItem:=ACLONE(_aDadosItem)

If nConta < Len(_aDadosCarga)//SE NÃO ESTÃO TODOS MARCADOS RECALCULA OS ITENS PARA SÓ OS MARCADOS

    ProcRegua(Len(_aDadosCarga))
    
    _aDadosItem:={}
    For NI := 1 TO Len(_aDadosCarga)
    
    	IncProc("Recalculando Marcados: " + StrZero(NI,5) + " de " + StrZero(Len(_aDadosCarga),6))
        If !_aDadosCarga[NI][01] 
    	   Loop
    	EndIf
        
        If DAK->(DBSeek(_aDadosCarga[NI][nPosFil]+_aDadosCarga[NI][nPosCar]))
    	   REST79ReLe()
    	EndIf
    
    Next
    For L := 1 TO Len(_aDadosItem)//CALCULA A QDE DE Pallets
        If SB1->( DBSeek( xFilial("SB1") + _aDadosItem[L,1] ) )
    	   _aDadosItem[L,nPosQPal]:= REST79SPal(_aDadosItem[L,nPosQt1m],_aDadosItem[L,nPosQt2m],SB1->B1_SEGUM,SB1->B1_TIPO)
    	EndIf
    Next
    For L := 1 TO Len(_aDadosItem)//AJUSTE PARA MOSTRAR NO RELATORIO CORRETO
        _aDadosItem[L,nPosQt1m]:= TRANSFORM(_aDadosItem[L,nPosQt1m],"@E 999,999,999,999.999" )//SC9->C9_QTDLIB   
        _aDadosItem[L,nPosQt2m]:= TRANSFORM(_aDadosItem[L,nPosQt2m],"@E 999,999,999,999.999" )//SC9->C9_QTDLIB2  
        _aDadosItem[L,nPosPBru]:= TRANSFORM(_aDadosItem[L,nPosPBru],"@E 999,999,999,999.9999")//SB1->B1_PESBRU * SC9->C9_QTDLIB
        _aDadosItem[L,nPosPtos]:= TRANSFORM(_aDadosItem[L,nPosPtos],"@E 999,999,999,999.99"  )//SC9->C9_QTDLIB * SC9->C9_PRCVEN 
    Next

    aSort(_aDadosItem,,,{|x,y|x[2] < y[2]})

EndIf//SE NÃO ESTÃO TODOS MARCADOS RECALCULA PARA SÓ OS MARCADOS

_nPagAux:=0
REST079CAB()
REST79Sub("PRODUTOS")

ProcRegua(Len(_aDadosItem))

For NI := 1 TO  Len(_aDadosItem)
	
	IncProc("Imprimindo PRODUTO: " + StrZero(NI,5) + " de " + StrZero(Len(_aDadosItem),5))

	If _nLinha >= _nLinMax
	   oPrint:EndPage()
	   REST079CAB()
       REST79Sub("PRODUTOS")
    EndIf
	
	oPrint:Say( _nLinha , _nColIni , _aDadosItem[NI][01], _oFontIT )
	oPrint:Say( _nLinha  ,_nColI02 , MEMOLINE(_aDadosItem[NI][02],_nTamDes,1), _oFontIT )
	oPrint:Say( _nLinha , _nColI03 , _aDadosItem[NI][03], _oFontIT )
	oPrint:Say( _nLinha , _nColI04 , _aDadosItem[NI][04], _oFontIT )
	oPrint:Say( _nLinha , _nColI05 , _aDadosItem[NI][05], _oFontIT )
	oPrint:Say( _nLinha , _nColI06 , _aDadosItem[NI][06], _oFontIT )
  	oPrint:Say( _nLinha , _nColI07 , _aDadosItem[NI][07], _oFontIT )
	oPrint:Say( _nLinha , _nColI08 , _aDadosItem[NI][08], _oFontIT )
	oPrint:Say( _nLinha , _nColI09 , _aDadosItem[NI][09], _oFontIT )
	_nLinha += 050
    If !Empty(MEMOLINE(_aDadosItem[NI][02],_nTamDes,2))
	   oPrint:Say( _nLinha  ,_nColI02 , MEMOLINE(_aDadosItem[NI][02],_nTamDes,2), _oFontIT )
	   _nLinha += 050
	EndIf

Next

ProcRegua(Len(_aDadosCarga))

REST079CAB(.T.)
REST79Sub("CARGA")

_aCargas:={}
For NI := 1 TO Len(_aDadosCarga)

	IncProc("Imprimindo CARGA: " + StrZero(NI,5) + " de " + StrZero(Len(_aDadosCarga),6))
    If !_aDadosCarga[NI][01] 
	   Loop
	EndIf
    
	aAdd(_aCargas,_aDadosCarga[NI][nPosFil]+_aDadosCarga[NI][nPosCar])

	If _nLinha >= _nLinMax
	   oPrint:EndPage()
	   REST079CAB(.T.)
       REST79Sub("CARGA")
    EndIf

	oPrint:Say( _nLinha , _nColIni , _aDadosCarga[NI][nPosFil], _oFontIT )//Filial
	oPrint:Say( _nLinha , _nColCar , _aDadosCarga[NI][nPosCar], _oFontIT )//Carga
	oPrint:Say( _nLinha  ,_nColC02 , _aDadosCarga[NI][05], _oFontIT )//Peso
	oPrint:Say( _nLinha , _nColC03 , _aDadosCarga[NI][06], _oFontIT )//Veiculo
	oPrint:Say( _nLinha , _nColC04 , _aDadosCarga[NI][07], _oFontIT )//Desc. Vei.
  	oPrint:Say( _nLinha , _nColC05 , _aDadosCarga[NI][08], _oFontIT )//Motorista
	oPrint:Say( _nLinha , _nColC06 , _aDadosCarga[NI][09], _oFontIT )//Descri Moto
  	oPrint:Say( _nLinha , _nColC07 , _aDadosCarga[NI][10], _oFontIT )//Ptos *
	oPrint:Say( _nLinha , _nColC08 , _aDadosCarga[NI][11], _oFontIT )//Valor 
	oPrint:Say( _nLinha , _nColC09 , _aDadosCarga[NI][12], _oFontIT )//Pre Carga
	oPrint:Say( _nLinha , _nColC10 , _aDadosCarga[NI][13], _oFontIT )//Data
	oPrint:Say( _nLinha , _nColC11 , _aDadosCarga[NI][14], _oFontIT )//Hora
    oPrint:Say( _nLinha , _nColC12 , _aDadosCarga[NI][15], _oFontIT )//Envio
	_nLinha += 050

Next

oPrint:EndPage()                // Finaliza a Pagina de Impressao

_aDadosItem:=ACLONE(_aDadosAuxItem)

Return .F. //NAO SAIR 

/*
===============================================================================================================================
Programa--------: REST079CAB
Autor-----------: Alex Wallauer
Data da Criacao-: 18/09/2023
===============================================================================================================================
Descrição-------: Função para construir o cabeçalho da página
===============================================================================================================================
Parametros------: _lTit2 := .F. ou .T.
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

Static Function REST079CAB(_lTit2)
Local _nAjusteCb:= 0
Local _oFont10	:= TFont():New( "Arial" ,, 14 ,,.F. )
Local nColTot	:= oPrint:nPageWidth /// oPrint:nFactorHor //Largura da página em cm dividido pelo fator horizontal, retorna tamanho da página em pixels
Local nMeio     := int(nColTot / 3)+55
Local nLargura  := 800
Local nAltura   := 100
DEFAULT _lTit2  := .F.

oPrint:StartPage()              // Inicializa a Pagina de Impressao

_nLinha := _nLinhaIni
_nPagAux++

oPrint:Line( _nLinha		, _nColIni , _nLinha		, _nColMax )
_nLinha += 050

If _lTit2
   _nSomaCol:=0950//1235
   oPrint:Say( _nLinha+35 , _nColIni +_nSomaCol - _nAjusteCb, "RESUMO DAS ORDENS DE CARGA" , _oFont18 )
Else
   _nSomaCol:=0990//1235
   oPrint:Say( _nLinha+35 , _nColIni +_nSomaCol - _nAjusteCb, "LISTAGEM ORDEM DE CARGA" , _oFont18 )
EndIf

nColTot	:= oPrint:nPageWidth /// oPrint:nFactorHor //Largura da página em cm dividido pelo fator horizontal, retorna tamanho da página em pixels
nMeio    := int(nColTot / 3)+55
nLargura := 800
nAltura  := 100

If Len(AllTrim(MV_PAR05)) = 2 
   oPrint:SayAlign(_nLinha+055, nMeio, 'FILIAL: '+ AllTrim(MV_PAR05) +' - '+ AllTrim(FWFilialName(cEmpAnt,AllTrim(MV_PAR05),1))  , _oFont10,nLargura,nAltura,,2)
Else
   oPrint:SayAlign(_nLinha+055, nMeio, 'FILIAIS: '+ AllTrim(MV_PAR05) , _oFont10,nLargura,nAltura,,2)
EndIf
_nLinPDH:=40

oPrint:Say( _nLinha,_nColIni, "Periodo de "+AllTrim(AllToChar(MV_PAR01))+" ate "+AllTrim(AllToChar(MV_PAR02)) , _oFont10 )
oPrint:SayAlign( _nLinha-_nLinPDH,_nColFimPDH, 'Página: '+ StrZero(_nPagAux,3)	, _oFont10 ,900,100,, 1 )
_nLinha += 050

oPrint:Say( _nLinha,_nColIni, "Cargas Faturadas? "+SubStr(_aParOpc[Val(MV_PAR03)],3) , _oFont10 )
oPrint:SayAlign( _nLinha-_nLinPDH,_nColFimPDH, 'Data: '+ DToC( Date() )	    , _oFont10 ,900,100,, 1 )
_nLinha += 050

oPrint:Say( _nLinha,_nColIni, "Ordens de Cargas já listadas? "+SubStr(_aParOpc[Val(MV_PAR04)],3) , _oFont10 )
oPrint:SayAlign( _nLinha-_nLinPDH,_nColFimPDH, 'Hora: '+ Time(), _oFont10 ,900,100,, 1 )
_nLinha += 025

oPrint:Line( _nLinha , _nColIni , _nLinha, _nColMax )
_nLinha += 040

Return

/*
===============================================================================================================================
Programa--------: REST79Sub()
Autor-----------: Alex Wallauer
Data da Criacao-: 18/09/2023
===============================================================================================================================
Descrição-------: Imprimie os cabecalho  das colulas dos pedidos
===============================================================================================================================
Parametros------: _cTipo: "PRODUTOS" "CARGA"
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function REST79Sub(_cTipo)

Local aTitulo:={_aCabItemImp,_aCabImp} , R 
Local nTipo :=1

_aPosicao:={}

If _cTipo = "PRODUTOS"	
    
	nTipo:=1
	aAdd(_aPosicao,_nColIni)      //Produto
	aAdd(_aPosicao,_nColI02)      //Descricao do Produto
	aAdd(_aPosicao,_nColI03+130)  //Qt 1a
	aAdd(_aPosicao,_nColI04-25)   //1 UM
	aAdd(_aPosicao,_nColI05+130)  //Qt 2a
	aAdd(_aPosicao,_nColI06-25)   //2 UM
	aAdd(_aPosicao,_nColI07+091)  //Pso.Bruto Tot
	aAdd(_aPosicao,_nColI08)      //Qtd Pal
	aAdd(_aPosicao,_nColI09+035)  //Vr Total

ElseIf _cTipo = "CARGA"
    
	nTipo:=2
	aAdd(_aPosicao,_nColIni)     // Filial
	aAdd(_aPosicao,_nColCar)     // Carga
	aAdd(_aPosicao,_nColC02+115) // Peso
	aAdd(_aPosicao,_nColC03)     // Veiculo
	aAdd(_aPosicao,_nColC04)     // Desc. Vei.
    aAdd(_aPosicao,_nColC05-45)  // Cod. Motorista
	aAdd(_aPosicao,_nColC06)     // Motorista
	aAdd(_aPosicao,_nColC07)     // Ptos.Ent
	aAdd(_aPosicao,_nColC08+28)  // Valor Carga
	aAdd(_aPosicao,_nColC09-45)  // Pre Carga
	aAdd(_aPosicao,_nColC10+15)  // Data
	aAdd(_aPosicao,_nColC11+15)  // Hora
	aAdd(_aPosicao,_nColC12+25)  // Envio

EndIf

For R := 1 TO Len(aTitulo[nTipo]) //Os titulos que determinam quantas colunas serão impressao
    oPrint:Say( _nLinha,_aPosicao[R],aTitulo[nTipo,R],_oFontIT )
Next
_nLinha += 030

oPrint:Line( _nLinha , _nColIni , _nLinha, _nColMax )
_nLinha += 050
		
Return .T.


/*
===============================================================================================================================
Programa--------: REST79SPal()
Autor-----------: Alex Wallauer
Data da Criacao-: 18/09/2023
===============================================================================================================================
Descrição-------: Imprimie os cabecalho  das colulas dos pedidos
===============================================================================================================================
Parametros------: nQtde1,nQtde2
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function REST79SPal(nQtde1,nQtde2,cSegUM,cTipo)

Local _nQtPallet:= 0
Local _nQtSobra := 0
Local _nQtNoPl	 := 0
Local _cUMPal	 := ''

//================================================================================
// Cálculo da quantidade de Pallets
//================================================================================
If SB1->B1_I_UMPAL == '1'
	_nQtPallet	:= Int( nQtde1 / SB1->B1_I_CXPAL )
ElseIf SB1->B1_I_UMPAL == '2'
	If AllTrim(cSegUM) == "PC" .And. AllTrim(cTipo) == "PA" //Tratamento para o QUEIJO
	   _nQtPallet	:= Int(  nQtde2  / SB1->B1_I_CXPAL )
   Else
	   _nQtPallet	:= Int( ROMS79CNV( nQtde1 , 1 , 2 ) / SB1->B1_I_CXPAL )
	EndIf
ElseIf SB1->B1_I_UMPAL == '3'
	_nQtPallet	:= Int( ROMS79CNV( nQtde1 , 1 , 3 ) / SB1->B1_I_CXPAL )
Else
	_nQtPallet	:= 0
	_nQtSobra	:= 0
	_cUMPal		:= ''
EndIf

_nQtNoPl := ( _nQtPallet * SB1->B1_I_CXPAL )
//================================================================================
// Dados para impressão da sobra com relação aos Pallets completos
//================================================================================
If SB1->B1_I_QTOC3 == '1'
	If SB1->B1_I_UMPAL == '2'
		_nQtNoPl := ROMS79CNV( _nQtNoPl , 2 , 1 )
	ElseIf SB1->B1_I_UMPAL == '3'
		_nQtNoPl := ROMS79CNV( _nQtNoPl , 3 , 1 )
	EndIf
	_nQtSobra	:= nQtde1 - _nQtNoPl
	_cUMPal		:= SB1->B1_UM
ElseIf SB1->B1_I_QTOC3 == '2'
	If SB1->B1_I_UMPAL == '1'
		_nQtNoPl := ROMS79CNV( _nQtNoPl , 1 , 2 )
	ElseIf SB1->B1_I_UMPAL == '3'
		_nQtNoPl := ROMS79CNV( _nQtNoPl , 3 , 2 )
	EndIf
	_nQtSobra	:= ROMS79CNV( nQtde1 , 1 , 2 ) - _nQtNoPl
	_cUMPal		:= SB1->B1_SEGUM
ElseIf SB1->B1_I_QTOC3 == '3'
	If SB1->B1_I_UMPAL == '1'
	   _nQtNoPl := ROMS79CNV( _nQtNoPl , 1 , 3 )
	   _nQtSobra:= ROMS79CNV( nQtde1 , 1 , 3 ) - _nQtNoPl
	ElseIf SB1->B1_I_UMPAL == '2'
	   _nQtNoPl := ROMS79CNV( _nQtNoPl , 2 , 3 )//CONVERTE PARA CAIXAS
	   _nQtSobra:= ROMS79CNV( nQtde2 , 2 , 3 ) - _nQtNoPl
	EndIf
	_cUMPal		:= SB1->B1_I_3UM
Else
	_nQtPallet	:= 0
	_nQtSobra	:= 0
	_cUMPal		:= ''
EndIf
		
_cInfPal := ''
If !Empty( _cUMPal )
	If _nQtPallet > 0
		_cInfPal := cValToChar( _nQtPallet ) + ' Pallet' + IIf( _nQtPallet > 1 , 's' , '' ) + IIf( _nQtSobra > 0 , '+' , '' )
	EndIf
	If _nQtSobra > 0
		_cInfPal += cValToChar( _nQtSobra ) +' '+ _cUMPal
	EndIf
EndIf

Return _cInfPal

/*
===============================================================================================================================
Programa--------: ROMS79CNV
Autor-----------: Alex Wallauer
Data da Criacao-: 18/09/2023
===============================================================================================================================
Descrição-------: Função para conversão entre unidades de medida - COPIA DA ROMS004CNV
===============================================================================================================================
Parametros------: _nQtdAux , _nUMOri , _nUMDes
===============================================================================================================================
Retorno---------: _nRet
===============================================================================================================================
*/
Static Function ROMS79CNV( _nQtdAux , _nUMOri , _nUMDes )

Local _nRet	:= 0

Do Case

	Case _nUMDes == 1
		
		//================================================================================
		// Conversão da Segunda UM para a Primeira
		//================================================================================
		If _nUMOri == 2
			
			If SB1->B1_TIPCONV == 'D'
				_nRet := _nQtdAux * SB1->B1_CONV
			ElseIf SB1->B1_TIPCONV == 'M'
				_nRet := _nQtdAux / SB1->B1_CONV
			EndIf
		
		//================================================================================
		// Conversão da Terceira UM para a Primeira
		//================================================================================
		ElseIf _nUMOri == 3
			
			_nRet := _nQtdAux * SB1->B1_I_QT3UM
			
		EndIf
		
	Case _nUMDes == 2
	    
		//================================================================================
		// Conversão da Primeira UM para a Segunda
		//================================================================================
		If _nUMOri == 1
			
			If SB1->B1_TIPCONV == 'D'
				_nRet := _nQtdAux / SB1->B1_CONV
			ElseIf SB1->B1_TIPCONV == 'M'
				_nRet := _nQtdAux * SB1->B1_CONV
			EndIf
		
		//================================================================================
		// Conversão da Terceira UM para a Segunda
		//================================================================================	
		ElseIf _nUMOri == 3
			
			_Ret := _nQtdAux * SB1->B1_I_QT3UM
			
			If SB1->B1_TIPCONV == 'D'
				_nRet := _nRet / SB1->B1_CONV
			ElseIf SB1->B1_TIPCONV == 'M'
				_nRet := _nRet * SB1->B1_CONV
			EndIf
			
		EndIf
	
	Case _nUMDes == 3
    
		//================================================================================
		// Conversão da PRIMEIRA UM PARA A TERCEIRA
		//================================================================================
		If _nUMOri == 1
			
			_nRet := _nQtdAux / SB1->B1_I_QT3UM
		
		//================================================================================
		// Conversão da SEGUNDA UM PARA A TERCEIRA
		//================================================================================	
		ElseIf _nUMOri == 2
			
			If SB1->B1_CONV > 0 
			   If SB1->B1_TIPCONV == 'D'
			   	  _nRet := _nQtdAux * SB1->B1_CONV
			   ElseIf SB1->B1_TIPCONV == 'M'
			   	  _nRet := _nQtdAux / SB1->B1_CONV
			   EndIf
			Else//SÓ PARA O QUEIJO
			   _nRet := _nQtdAux
			EndIf			
			
			_nRet := _nRet / SB1->B1_I_QT3UM
			
		EndIf

EndCase

Return( Round(_nRet,2) )


/*
===============================================================================================================================
Programa--------: REST79ReLe()
Autor-----------: Alex Wallauer
Data da Criacao-: 18/09/2023
===============================================================================================================================
Descrição-------: Compondo os dados do produto MARCADOS
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function REST79ReLe()
If DAI->( DBSeek( xFilial("DAI") + DAK->DAK_COD ) )
	
	While DAI->( !Eof() ) .And. DAI->( DAI_FILIAL + DAI_COD ) == xFilial("DAI") + DAK->DAK_COD
	
		//====================================================================================================
		// Compondo os dados do produto
		//====================================================================================================
		If SC6->( DBSeek( xFilial("SC6") + DAI->DAI_PEDIDO ) )
		
		   While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == xFilial("SC6") + DAI->DAI_PEDIDO
			    
			  SB1->( DBSeek( xFilial("SB1") + SC6->C6_PRODUTO ) )
			  SC9->( DBSeek( xFilial("SC9") + SC6->C6_NUM + SC6->C6_ITEM ) )

                _cDescItem:=AllTrim(SB1->B1_DESC)

			   If (nPos := aScan( _aDadosItem , { |x| x[1] == AllTrim(SC6->C6_PRODUTOS)+"-"+SC6->C6_LOCAL } ) ) == 0
                    
				  _aProds:={}
                    aAdd(_aProds , AllTrim(SC6->C6_PRODUTOS)+"-"+SC6->C6_LOCAL)//01
                    aAdd(_aProds , _cDescItem                          )//02
                    aAdd(_aProds , SC9->C9_QTDLIB                      )//03
                    aAdd(_aProds , SB1->B1_UM                          )//04
                    aAdd(_aProds , SC9->C9_QTDLIB2                     )//05
                    aAdd(_aProds , SB1->B1_SEGUM                       )//06
                    aAdd(_aProds , ( SB1->B1_PESBRU * SC9->C9_QTDLIB ) )//07
                    aAdd(_aProds , " "                                 )//08
                    aAdd(_aProds , ( SC9->C9_QTDLIB * SC9->C9_PRCVEN ) )//09
                    
				  aAdd(_aDadosItem , _aProds )
			   Else
				  _aDadosItem[nPos][nPosQt1m] += SC9->C9_QTDLIB
				  _aDadosItem[nPos][nPosQt2m] += SC9->C9_QTDLIB2
				  _aDadosItem[nPos][nPosPBru] +=(SB1->B1_PESBRU * SC9->C9_QTDLIB)
				  _aDadosItem[nPos][nPosPtos] +=(SC9->C9_QTDLIB * SC9->C9_PRCVEN)			
			   EndIf
			   SC6->( DBSkip() )

			EndDo
	
		EndIf
		DAI->( DBSkip() )
	EndDo
EndIf

Return
