/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |19/09/2021| Chamado 41359. Correção de error.log.
Alex Wallauer |13/08/2024| Chamado 48002. Andre. Correção de error.log: variable does not exist _N2SALDO.
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: REST015
Autor-------------: Alex Wallauer
Data da Criacao---: 29/04/2019
Descrição---------: Relatório de informações das liberações da qualidade
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function REST015()
Static _asAllusers := {}
Private _aAllusers := {}
Private _nPU := 0
If Len(_asAllusers) = 0
   _asAllusers := FWSFALLUSERS()
EndIf   
_aAllusers := _asAllusers

_SelSB1:="(SELECT SB1.B1_I_DESCD FROM "+RETSQLNAME("SB1")+" SB1 WHERE D_E_L_E_T_ = ' ' AND SB1.B1_COD = SD7.D7_PRODUTO) DESCD "
_cSeleNSD7:="SELECT DISTINCT D7_NUMERO, D7_LIBERA, MIN(D7_DATA) D7DATA FROM "+RETSQLNAME("SD7")+" SD7 WHERE D_E_L_E_T_ = ' ' AND D7_FILIAL = '"+xFilial("SD7")+"' ORDER BY D7_NUMERO  GROUP BY  D7_NUMERO, D7_LIBERA " 
//_cSeleUSD7:="SELECT DISTINCT D7_USUARIO             FROM "+RETSQLNAME("SD7")+" SD7 WHERE D_E_L_E_T_ = ' ' AND D7_FILIAL = '"+xFilial("SD7")+"' ORDER BY D7_USUARIO " 
_cSelePSD7:="SELECT DISTINCT D7_PRODUTO,"+_SelSB1+" FROM "+RETSQLNAME("SD7")+" SD7 WHERE D_E_L_E_T_ = ' ' AND D7_FILIAL = '"+xFilial("SD7")+"' ORDER BY D7_PRODUTO " 

_aDadosTM:={}
aAdd( _aDadosTM ,"0-Qtd. Original      ")
aAdd( _aDadosTM ,"1-Liberado           ")
aAdd( _aDadosTM ,"2-Rejeitado          ")
aAdd( _aDadosTM ,"3-Devolucao Liberacao")
aAdd( _aDadosTM ,"4-Devolucao Rejeicao ")
aAdd( _aDadosTM ,"6-Est. Liberacao     ")
aAdd( _aDadosTM ,"7-Est. Rejeicao      ")
aAdd( _aDadosTM ,"8-Despesas Agregadas ")
aAdd( _aDadosTM ,"9-Estorno Despesas   ")

//_bCol8:={|Tab| _cUser:=Upper((Tab)->D7_USUARIO) , If( (_nPU:=aScan(_aAllusers, {|A| Upper(A[3]) == _cUser })) <> 0 ,_aAllusers[ _nPU,4],Space(40)) }
_bCol3:={|Tab| DToC(SToD((Tab)->D7DATA))+" "+(Tab)->D7_LIBERA}
                                                                           
_aItalac_F3:={}//       1           2         3                      4                      5                6                         7         8          9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave               , _nCpoDesc              ,_bCondTab    , _cTitAux                , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR03" ,_cSeleNSD7,{|Tab| (Tab)->D7_NUMERO }, _bCol3                 ,             ,"Numero da Transferencia",          ,          ,100       ,.T.        ,       , } )
aAdd(_aItalac_F3,{"MV_PAR05" ,_cSelePSD7,{|Tab| (Tab)->D7_PRODUTO}, {|Tab|(Tab)->DESCD}    ,             ,"Produtos"               ,          ,          ,30        ,.T.        ,       , } )
aAdd(_aItalac_F3,{"MV_PAR07" ,"CYO"     ,                         ,                        ,             ,"Motivos de Rejeicao"} )

While .T.
   If !Pergunte("REST015",.T.)
      Return
   EndIf

    If Empty(MV_PAR01) .Or. Empty(MV_PAR02) .Or. MV_PAR02 < MV_PAR01
       U_ITMsg("Datas invalidas ou não preenchidas",'Atenção!',"Preencha as 2 datas e a final maior ou igual a inicial",1)
       Loop
    EndIf

   cTimeInicial:=Time()

   FWMsgRun( ,{|oProc|  REST015R(oProc) } , "SD7 - Hora Inicial: "+cTimeInicial+", Aguarde...",  )

  EndDo 

U_ITLOGACS( "REST015" )

Return


/*
===============================================================================================================================
Programa----------: REST015R
Autor-------------: Alex Wallauer
Data da Criacao---: 29/04/2019
Descrição---------: Função que imprime o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function REST015R(oProc)
Local cQry1		:= ""
Local _cAlias  := GetNextAlias()
Private _aItens  := {}
Private _n1Origem:=0
Private _n2Origem:=0
Private _n1Liberados:=0
Private _n2Liberados:=0
Private _n1Rejetados:=0
Private _n2Rejetados:=0
Private _n1Saldo:=0
Private _n2Saldo:=0
Private _cMotRej := ""
Private _cObsItal := ""

   oProc:cCaption :=  "Selecionando Tranferencias, Aguarde... "
   ProcessMessages()

cQry1 := "SELECT  R_E_C_N_O_ RECSD7 "
cQry1 += "FROM " + RetSqlName("SD7") + " SD7  "
cQry1 += " WHERE SD7.D7_FILIAL = '"+xFilial("SD7")+" ' AND "
cQry1 += " D7_NUMERO IN (SELECT  D7_NUMERO "
cQry1 += "                 FROM  " + RetSqlName("SD7") + " SD7  "
cQry1 += "                 WHERE SD7.D7_FILIAL = '"+xFilial("SD7")+" ' "
cQry1 += "                       AND SD7.D_E_L_E_T_ = ' ' "
cQry1 += "                       AND D7_TIPO = 0 "
If MV_PAR04 = 1//'S'
   cQry1 += "                    AND D7_LIBERA = 'S' "
ElseIf MV_PAR04 = 2//'N'
   cQry1 += "                    AND D7_LIBERA <> 'S' "
EndIf
If !Empty(MV_PAR02)
   cQry1 += "                    AND D7_DATA BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "'"
ElseIf !Empty(MV_PAR01)
   cQry1 += "                    AND D7_DATA >= '" + DToS(MV_PAR01) + "'"
EndIf   
cQry1 += "            ) "

If !Empty(MV_PAR03)
	cQry1 += " AND D7_NUMERO IN "+FormatIn(AllTrim(MV_PAR03),";")
EndIf
	
If !Empty(MV_PAR05)
	cQry1 += " AND D7_PRODUTO IN "+FormatIn(AllTrim(MV_PAR05),";")
EndIf

If !Empty(MV_PAR07)
	cQry1 += " AND D7_MOTREJE IN "+FormatIn(AllTrim(MV_PAR07),";")
EndIf

cQry1 += " AND SD7.D_E_L_E_T_ = ' ' "
cQry1 += " ORDER BY D7_FILIAL, D7_NUMERO, D7_SEQ "

//crio o novo alias
MPSysOpenQuery( cQry1, _cAlias ) 

nTotal:=nConta:=0
DBSelectArea(_cAlias)
COUNT TO nTotal

If nTotal = 0 
    U_ITMsg("Não há dados para essa seleção",'Atenção!',,1)
    (_cAlias)->(DBCloseArea())
    Return .F.
EndIf

(_cAlias)->(DBGoTop())
SD7->(DBGoTo((_cAlias)->RECSD7))
_cNumero :=SD7->D7_NUMERO
_cProduto:=SD7->D7_PRODUTO
_cData:=SD7->D7_DATA
_aDados:={}
nTotal:=AllTrim(Str(nTotal))
nTam:=Len(nTotal)+1
SCR->(DBSetOrder(1))

While !(_cAlias)->(Eof())

   SD7->(DBGoTo((_cAlias)->RECSD7))
   nConta++
   oProc:cCaption :=  "Lendo "+StrZero(nConta,nTam)+" de "+nTotal +" - Lendo Pedido " +SD7->D7_NUMERO
   ProcessMessages()
   
   _aItens:={}
     If MV_PAR06 = 2 // ANALITICO
	    _cTipo:=Space(22)
        If (_nPU:=aScan(_aDadosTM,{|T| Val(T) == SD7->D7_TIPO })) <> 0
           _cTipo:=_aDadosTM[_nPU]
        EndIf
    	aAdd(_aItens,SD7->D7_NUMERO)
		aAdd(_aItens,AllTrim(SD7->D7_PRODUTO)+" - "+Posicione("SB1",1,xFilial("SB1")+SD7->D7_PRODUTO,"B1_I_DESCD") )
		aAdd(_aItens,DToC(SD7->D7_DATA))
		aAdd(_aItens,_cTipo)
		aAdd(_aItens,Transform(SD7->D7_QTDE   ,PesqPict("SD7","D7_QTDE")))
		aAdd(_aItens,Transform(SD7->D7_SALDO  ,PesqPict("SD7","D7_SALDO")))
		aAdd(_aItens,Transform(SD7->D7_QTSEGUM,PesqPict("SD7","D7_QTSEGUM")))
		aAdd(_aItens,Transform(SD7->D7_SALDO2 ,PesqPict("SD7","D7_SALDO2")))
		aAdd(_aItens,AllTrim(SD7->D7_USUARIO)+" - "+If( (_nPU:=aScan(_aAllusers, {|A| Upper(A[3]) == Upper(AllTrim(SD7->D7_USUARIO))})) <> 0 ,_aAllusers[ _nPU,4],Space(40)))
		aAdd(_aItens,AllTrim(SD7->D7_MOTREJE)+" - "+Posicione("CYO",1,xFilial("CYO")+SD7->D7_MOTREJE,"CYO_DSRF") )
      aAdd(_aItens,SD7->D7_I_OBS)

        aAdd(_aDados,ACLONE(_aItens))
   
     ElseIf MV_PAR06 = 1 // SINTETICO

        If _cNumero <> SD7->D7_NUMERO
		     REST15Sin()
           aAdd(_aDados,ACLONE(_aItens))
           _cMotRej  := ""
           _cObsItal := ""
        EndIf

         _cMotRej += IIf(!Empty(AllTrim(SD7->D7_MOTREJE)),(IIf(!Empty(_cMotRej),";","") + AllTrim(SD7->D7_MOTREJE)+" - "+ AllTrim(Posicione("CYO",1,xFilial("CYO")+SD7->D7_MOTREJE,"CYO_DSRF"))),"")
         _cObsItal += IIf(!Empty(AllTrim(SD7->D7_I_OBS)),(IIf(!Empty(_cObsItal),";","") + AllTrim(SD7->D7_I_OBS)),"")

        If SD7->D7_TIPO = 0
           _n1Origem:=SD7->D7_SALDO
           _n2Origem:=SD7->D7_SALDO2
           _n1Saldo :=SD7->D7_SALDO
           _n2Saldo :=SD7->D7_SALDO2
        ElseIf SD7->D7_TIPO = 1 //LIBERACAO
           _n1Saldo    -=SD7->D7_QTDE
           _n2Saldo    -=SD7->D7_QTSEGUM
           _n1Liberados+=SD7->D7_QTDE
           _n2Liberados+=SD7->D7_QTSEGUM
        ElseIf SD7->D7_TIPO = 2//REJEIÇÃO
           _n1Saldo    -=SD7->D7_QTDE
           _n2Saldo    -=SD7->D7_QTSEGUM
           _n1Rejetados+=SD7->D7_QTDE
           _n2Rejetados+=SD7->D7_QTSEGUM
        ElseIf SD7->D7_TIPO = 6//ESTONO DA LIBERAÇÃO
           _n1Saldo    +=SD7->D7_QTDE
           _n2Saldo    +=SD7->D7_QTSEGUM
           _n1Liberados-=SD7->D7_QTDE
           _n2Liberados-=SD7->D7_QTSEGUM
        ElseIf SD7->D7_TIPO = 7//ESTORNO DA REJEIÇÃO
           _n1Saldo    +=SD7->D7_QTDE
           _n2Saldo    +=SD7->D7_QTSEGUM
           _n1Rejetados-=SD7->D7_QTDE
           _n2Rejetados-=SD7->D7_QTSEGUM
        EndIf

     EndIf

	 (_cAlias)->(DBSkip())
	
    EndDo

If Len(_aDados) = 0 
    U_ITMsg("Não há dados para essa seleção",'Atenção!',,1)
    (_cAlias)->(DBCloseArea())
    Return .F.
EndIf

If !(_cAlias)->(Eof()) .And. MV_PAR06 = 1 // SINTETICO
   _aItens:={}
   REST15Sin()
   aAdd(_aDados,ACLONE(_aItens))
ElseIf MV_PAR06 = 1 // SINTETICO
   REST15Sin()
   aAdd(_aDados,ACLONE(_aItens))//adiciona o ultimo
EndIf   

While Len(_aDados) > 0 
   _aTit:={}
   _aSiz:={}

   If MV_PAR06 = 2 // ANALITICO
      aAdd(_aTit,'Numero') 
      aAdd(_aSiz,20)
      aAdd(_aTit,'Produto')
      aAdd(_aSiz,90)
      aAdd(_aTit,'Data')
      aAdd(_aSiz,25)
      aAdd(_aTit,'Tipo')
      aAdd(_aSiz,40)
      aAdd(_aTit,'Quantidade 1 UM')
      aAdd(_aSiz,55)
      aAdd(_aTit,'Saldo 1 UM')
      aAdd(_aSiz,55)
      aAdd(_aTit,'Quantidade 2 UM')
      aAdd(_aSiz,55)
      aAdd(_aTit,'Saldo 2 UM')
      aAdd(_aSiz,35)
      aAdd(_aTit,'Usuario')
      aAdd(_aSiz,200)
      aAdd(_aTit,'Motivo da Rejeicao')
      aAdd(_aSiz,200)
      aAdd(_aTit,'Obs ITALAC')
      aAdd(_aSiz,60)

   ElseIf MV_PAR06 = 1 // SINTETICO

      aAdd(_aTit,'Numero') 
      aAdd(_aSiz,20)
      aAdd(_aTit,'Produto')
      aAdd(_aSiz,90)
      aAdd(_aTit,'Data')
      aAdd(_aSiz,25)
   
      aAdd(_aTit,'Qtde Original 1 UM')
      aAdd(_aSiz,55)
      aAdd(_aTit,'Qtde Liberada 1 UM')
      aAdd(_aSiz,55)
      aAdd(_aTit,'Qtde Rejeitada 1 UM')
      aAdd(_aSiz,55)
      aAdd(_aTit,'Saldo 1 UM')
      aAdd(_aSiz,35)

      aAdd(_aTit,'Qtde Original 2 UM')
      aAdd(_aSiz,55)
      aAdd(_aTit,'Qtde Liberada 2 UM')
      aAdd(_aSiz,55)
      aAdd(_aTit,'Qtde Rejeitada 2 UM')
      aAdd(_aSiz,55)
      aAdd(_aTit,'Saldo 2 UM')
      aAdd(_aSiz,35)

      aAdd(_aTit,'Motivo da Rejeicao')
      aAdd(_aSiz,200)
      aAdd(_aTit,'Obs ITALAC')
      aAdd(_aSiz,60) 
   EndIf

   _cMsgTop:="Tranferencias encontrados - H.I.: "+cTimeInicial+" H.F.: "+Time()

   _cTitulo:="Par. 1 : "+DToC(MV_PAR01)+"; Par. 2 : "+DToC(MV_PAR02)+"; Par. 3 : "+AllTrim(MV_PAR03)+"; Par. 4 : "+AllTrim(Str(MV_PAR04))+;
           "; Par. 5 : "+AllTrim(MV_PAR05)+"; Par. 6 : "+AllTrim(Str(MV_PAR06))
           
   bOk:={|| If(U_ITMsg("Confirma Gerar EXCEL ?",'Atenção!',,2,2,2) , DlgToExcel( { { "ARRAY" , _cTitulo , _aTit , _aDados } } )  ,.F. )   }

   //                           , _aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
      U_ITListBox(_cTitulo,_aTit,_aDados  , .T.    , 3    ,_cMsgTop,          ,_aSiz   ,         , bOk ,        , )
                                                                                                  

   If  !U_ITMsg("Confirma Sair ?",'Atenção!',,3,2,2)
       Loop
   EndIf

    Exit

EndDo

(_cAlias)->(DBCloseArea())

Return .T.

/*
===============================================================================================================================
Programa----------: REST15Sin
Autor-------------: Alex Wallauer
Data da Criacao---: 29/04/2019
Descrição---------: Função para GRava as somas dos vlaores do relatorio Sintetico
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function REST15Sin()

aAdd(_aItens,_cNumero)
aAdd(_aItens,AllTrim(_cProduto)+" - "+Posicione("SB1",1,xFilial("SB1")+_cProduto,"B1_I_DESCD") )
aAdd(_aItens,DToC(_cData))

aAdd(_aItens,Transform(_n1Origem   ,PesqPict("SD7","D7_QTDE")))
aAdd(_aItens,Transform(_n1Liberados,PesqPict("SD7","D7_QTDE")))
aAdd(_aItens,Transform(_n1Rejetados,PesqPict("SD7","D7_QTDE")))
aAdd(_aItens,Transform(_n1Saldo    ,PesqPict("SD7","D7_SALDO")))

aAdd(_aItens,Transform(_n2Origem   ,PesqPict("SD7","D7_QTSEGUM")))
aAdd(_aItens,Transform(_n2Liberados,PesqPict("SD7","D7_QTSEGUM")))
aAdd(_aItens,Transform(_n2Rejetados,PesqPict("SD7","D7_QTSEGUM")))
aAdd(_aItens,Transform(_n2Saldo    ,PesqPict("SD7","D7_SALDO2")))

aAdd(_aItens,_cMotRej)
aAdd(_aItens,_cObsItal)

_cNumero :=SD7->D7_NUMERO
_cProduto:=SD7->D7_PRODUTO
_cData   :=SD7->D7_DATA

_n1Origem:=0
_n1Liberados:=0
_n1Rejetados:=0
_n1Saldo:=0

_n2Origem:=0
_n2Liberados:=0
_n2Rejetados:=0
_n2Saldo:=0

Return .T.
