/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: REST016
Autor-------------: Alex Wallauer
Data da Criacao---: 30/04/2019
Descrição---------: Relatório de Listagem de OPs ITALAC
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function REST016()

_SelSB1:="(SELECT SB1.B1_I_DESCD FROM "+RETSQLNAME("SB1")+" SB1 WHERE D_E_L_E_T_ = ' ' AND SB1.B1_COD = SC2.C2_PRODUTO) DESCD "
_cSelePSC2:="SELECT DISTINCT C2_PRODUTO,"+_SelSB1+" FROM "+RETSQLNAME("SC2")+" SC2 WHERE D_E_L_E_T_ = ' ' AND C2_FILIAL = '"+xFilial("SC2")+"' ORDER BY C2_PRODUTO " 
                                                                           
_aItalac_F3:={}//       1           2         3                      4                      5                6                         7         8          9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave               , _nCpoDesc              ,_bCondTab    , _cTitAux                , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR05" ,_cSelePSC2,{|Tab| (Tab)->C2_PRODUTO}, {|Tab|(Tab)->DESCD}    ,             ,"Produtos"               ,          ,          ,30        ,.T.        ,       , } )

While .T.
   If !Pergunte("REST016",.T.)
      Return
   EndIf

    If Empty(MV_PAR01) .Or. Empty(MV_PAR02) .Or. MV_PAR02 < MV_PAR01
       U_ITMsg("Datas invalidas ou não preenchidas",'Atenção!',"Preencha as 2 datas e a final maior ou igual a inicial",1)
       Loop
    EndIf

   cTimeInicial:=Time()

   FWMsgRun( ,{|oProc|  REST016R(oProc) } , "SC2 - Hora Inicial: "+cTimeInicial+", Aguarde...",  )

  EndDo 

U_ITLOGACS( "REST016" )

Return


/*
===============================================================================================================================
Programa----------: REST016R
Autor-------------: Alex Wallauer
Data da Criacao---: 30/04/2019
Descrição---------: Função que imprime o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function REST016R(oProc)
Local cQry1		:= "" , P
Local _cAlias  := GetNextAlias()

   oProc:cCaption :=  "Selecionando OP's, Aguarde... "
   ProcessMessages()

cQry1 := "SELECT  R_E_C_N_O_ RECSC2 "
cQry1 += "FROM " + RetSqlName("SC2") + " SC2  "
cQry1 += " WHERE SC2.C2_FILIAL = '"+xFilial("SC2")+" ' "


If !Empty(MV_PAR02)
   cQry1 += "AND C2_EMISSAO BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "'"
ElseIf !Empty(MV_PAR01)
   cQry1 += "AND C2_EMISSAO >= '" + DToS(MV_PAR01) + "'"
EndIf   

If !Empty(MV_PAR03)
	cQry1 += " AND C2_CC IN "+FormatIn(AllTrim(MV_PAR03),";")
EndIf

If MV_PAR04 = 1//'S' Encerradas: C2_DATRF <> ' '
   cQry1 += " AND C2_DATRF <> ' ' "
ElseIf MV_PAR04 = 2//'N' ABERTAS : C2_DATRF = ' '
   cQry1 += " AND C2_DATRF = ' ' "
EndIf
	
If !Empty(MV_PAR05)
	cQry1 += " AND C2_PRODUTO IN "+FormatIn(AllTrim(MV_PAR05),";")
EndIf

cQry1 += " AND SC2.D_E_L_E_T_ = ' ' "
cQry1 += " ORDER BY C2_FILIAL, C2_NUM , C2_ITEM , C2_SEQUEN , C2_PRODUTO "

//crio o novo alias
MPSysOpenQuery( cQry1, _cAlias ) 

nTotal:=nConta:=0
DBSelectArea(_cAlias)
COUNT TO nTotal
(_cAlias)->(DBGoTop())
SC2->(DBGoTo((_cAlias)->RECSC2))
_aDados:={}
nTotal:=AllTrim(Str(nTotal))
nTam:=Len(nTotal)+1
SCR->(DBSetOrder(1))

_aProd:={}
_aUM:={}

While !(_cAlias)->(Eof())

   SC2->(DBGoTo((_cAlias)->RECSC2))
   nConta++
   oProc:cCaption :=  "Lendo "+StrZero(nConta,nTam)+" de "+nTotal +" - Lendo OP " +SC2->(C2_NUM+C2_ITEM+C2_SEQUEN)
   ProcessMessages()
   
   _aItens:={}
   aAdd(_aItens,SC2->(C2_NUM+C2_ITEM+C2_SEQUEN))
   aAdd(_aItens,AllTrim(SC2->C2_PRODUTO)+" - "+Posicione("SB1",1,xFilial("SB1")+SC2->C2_PRODUTO,"B1_I_DESCD") )
   aAdd(_aItens,AllTrim(SC2->C2_CC)+" - "+Posicione("CTT",1,xFilial("CTT")+SC2->C2_CC,"CTT_DESC01"))
   aAdd(_aItens,Transform(SC2->C2_QUANT   ,PESQPICT("SC2","C2_QUANT")))
   aAdd(_aItens,SC2->C2_UM)
   aAdd(_aItens,DToC(SC2->C2_EMISSAO))
   aAdd(_aItens,Transform(SC2->C2_QUJE  ,PesqPict("SC2","C2_QUJE")))
   aAdd(_aItens,Transform(SC2->C2_QUANT -SC2->C2_QUJE,PesqPict("SC2","C2_QUJE")))
        
   aAdd(_aDados,ACLONE(_aItens))

   If (_nPos:=aScan(_aProd,{|P| P[1] == SC2->C2_PRODUTO })) = 0
      aAdd(_aProd,{SC2->C2_PRODUTO,SC2->C2_QUANT} )
   Else
      _aProd[_nPos,2]+=SC2->C2_QUANT
   EndIf
   If (_nPos:=aScan(_aUM,{|P| P[1] == SC2->C2_UM })) = 0
      aAdd(_aUM,{SC2->C2_UM,SC2->C2_QUANT} )
   Else
      _aUM[_nPos,2]+=SC2->C2_QUANT
   EndIf

   (_cAlias)->(DBSkip())
	
EndDo

For P := 1 TO Len(_aProd)
   _aItens:={}
   aAdd(_aItens,"")
   aAdd(_aItens,AllTrim(_aProd[P,1])+" - "+Posicione("SB1",1,xFilial("SB1")+_aProd[P,1],"B1_I_DESCD") )
   aAdd(_aItens,"Total do Produto")
   aAdd(_aItens,Transform(_aProd[P,2]   ,"@E 9999,999,999,999.999"))
   aAdd(_aItens,"")
   aAdd(_aItens,"")
   aAdd(_aItens,"")
   aAdd(_aItens,"")
   aAdd(_aDados,ACLONE(_aItens))
Next
For P := 1 TO Len(_aUM)
   _aItens:={}
   aAdd(_aItens,"")
   aAdd(_aItens,AllTrim(_aUM[P,1])+" - "+Posicione("SAH",1,xFilial("SAH")+_aUM[P,1],"AH_DESCPO") )
   aAdd(_aItens,"Total da Unidade")
   aAdd(_aItens,Transform(_aUM[P,2]   ,"@E 9999,999,999,999.999"))
   aAdd(_aItens,"")
   aAdd(_aItens,"")
   aAdd(_aItens,"")
   aAdd(_aItens,"")
   aAdd(_aDados,ACLONE(_aItens))
Next

If Len(_aDados) = 0 
    U_ITMsg("Não há dados para essa seleção",'Atenção!',,3)
EndIf

While Len(_aDados) > 0 
   _aTit:={}
   _aSiz:={}

//C2_NUM+C2_ITEM+C2_SEQUEN (NUMERO OP), C2_PRODUTO, C2_I_DESC, C2_CC, C2_QUANT, C2_UM, C2_EMISSAO, C2_QUJE (QTDE APONTADA), C2_QUANT -C2_QUJE (SALDO)

      aAdd(_aTit,'Numero OP') 
      aAdd(_aSiz,20)
      aAdd(_aTit,'Produto')
      aAdd(_aSiz,70)
      aAdd(_aTit,'Centro de Custo')
      aAdd(_aSiz,90)
      aAdd(_aTit,'Quantidade')
      aAdd(_aSiz,55)
      aAdd(_aTit,'UM')
      aAdd(_aSiz,20)
      aAdd(_aTit,'Data')
      aAdd(_aSiz,50)
      aAdd(_aTit,'Qtde Apontada')
      aAdd(_aSiz,45)
      aAdd(_aTit,'Saldo')
      aAdd(_aSiz,45)


   _cMsgTop:="OPs encontrados - H.I.: "+cTimeInicial+" H.F.: "+Time()

   _cTitulo:="Par. 1 : "+DToC(MV_PAR01)+"; Par. 2 : "+DToC(MV_PAR02)+"; Par. 3 : "+AllTrim(MV_PAR03)+"; Par. 4 : "+AllTrim(Str(MV_PAR04))+;
           "; Par. 5 : "+AllTrim(MV_PAR05)
           
   bOk:={|| If(U_ITMsg("Confirma Gerar EXCEL ?",'Atenção!',,2,2,2) , DlgToExcel( { { "ARRAY" , _cTitulo , _aTit , _aDados } } )  ,.F. )   }

   //                           , _aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
      U_ITListBox(_cTitulo,_aTit,_aDados  , .T.    , 3    ,_cMsgTop,          ,_aSiz   ,         , bOk ,        , )
                                                                                                  

   If  !U_ITMsg("Confirma Sair ?",'Atenção!',,3,2,2)
       Loop
   EndIf

    Exit

EndDo

Return
