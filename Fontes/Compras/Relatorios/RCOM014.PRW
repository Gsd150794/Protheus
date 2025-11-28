/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Walauer  |11/04/2020| Chamado 39745. Correção da Inversão dos campos dos filtros MV_PAR04 e MV_PAR05 
Alex Walauer  |11/04/2023| Chamado 42499. Foi adicionado 2 novos filtros: "Situacao do Aprov." e "Lista Bloque./Rejeit."
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include 'TOPCONN.CH'

/*
===============================================================================================================================
Programa----------: RCOM014
Autor-------------: Alex Wallauer
Data da Criacao---: 25/04/2019
===============================================================================================================================
Descrição---------: Relatório de pedidos de compra pendentes de aprovação
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM014()

_cSelecSC7:="SELECT DISTINCT C7_NUM   , C7_EMISSAO FROM "+RETSQLNAME("SC7")+" SC7 WHERE C7_ENCER <> 'E' AND C7_RESIDUO <> 'S' AND D_E_L_E_T_ = ' ' AND C7_FILIAL = '"+xFilial("SC7")+"' ORDER BY C7_NUM " 
_cSelecSAL:="SELECT DISTINCT AL_COD   , AL_DESC   FROM "+RETSQLNAME("SAL")+" SAL WHERE D_E_L_E_T_ = ' ' ORDER BY AL_COD " 
_cSelecSAJ:="SELECT DISTINCT AJ_GRCOM             FROM "+RETSQLNAME("SAJ")+" SAJ WHERE D_E_L_E_T_ = ' ' ORDER BY AJ_GRCOM " 

_aItalac_F3:={}//       1           2         3                      4                      5          6                      7         8          9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave            , _nCpoDesc              ,_bCondTab    , _cTitAux           , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR03" ,_cSelecSC7,{|Tab| (Tab)->C7_NUM }, {|Tab|DToC(SToD((Tab)->C7_EMISSAO))},,"Pedidos"           ,          ,          ,60        ,.T.        ,       , } )
aAdd(_aItalac_F3,{"MV_PAR04" ,_cSelecSAL,{|Tab| (Tab)->AL_COD }, {|Tab|(Tab)->AL_DESC}  ,             ,"Grupo Aprovadores" ,          ,          ,          ,.T.        ,       , } )
aAdd(_aItalac_F3,{"MV_PAR05" ,"SAK"     ,2                     ,4                       ,             ,"Aprovadores"} )
aAdd(_aItalac_F3,{"MV_PAR06" ,_cSelecSAJ,{|Tab|(Tab)->AJ_GRCOM}, {|Tab|(Tab)->AJ_GRCOM} ,             ,"Grupo Compradores" ,          ,          ,          ,.T.        ,       , } )
aAdd(_aItalac_F3,{"MV_PAR07" ,"SY1"     ,                      ,                        ,             ,"Compradores"} )

If !Pergunte("RCOM014",.T.)
   Return
EndIf

U_ITLOGACS( "RCOM014" )

cTimeInicial:=Time()

FWMsgRun( ,{|oProc|  RCOM014R(oProc) } , "SC7 - Hora Inicial: "+cTimeInicial+", Aguarde...",  )

Return


/*
===============================================================================================================================
Programa----------: RCOM014R
Autor-------------: Alex Wallauer
Data da Criacao---: 25/04/2019
Descrição---------: Função que imprime o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM014R(oProc)

Local cQry1		:= ""
Local _cAlias  := GetNextAlias()

   oProc:cCaption :=  "Selelecionado Pedidos, Aguarde... "
   ProcessMessages()

cQry1 := "SELECT  C7_NUM, "
cQry1 += "        C7_EMISSAO, "
cQry1 += "        C7_PRODUTO, "
cQry1 += "        C7_QUANT, "
cQry1 += "        C7_PRECO, "
cQry1 += "        C7_DATPRF , "
cQry1 += "        C7_COMPRA ,"
cQry1 += "        C7_GRUPCOM, "
cQry1 += "        C7_TOTAL, "
cQry1 += "        R_E_C_N_O_ RECSC7 "
cQry1 += "FROM " + RetSqlName("SC7") + " SC7  "
cQry1 += " WHERE SC7.C7_FILIAL = '"+xFilial("SC7")+" ' "

If !Empty(MV_PAR02)
   cQry1 += " AND C7_EMISSAO BETWEEN '" + DToS(MV_PAR01) + "' AND '" + DToS(MV_PAR02) + "' "
ElseIf !Empty(MV_PAR01)
   cQry1 += " AND C7_EMISSAO >= '" + DToS(MV_PAR01) + "' "
EndIf   

cQry1 +=  " AND  SC7.C7_FILIAL||SC7.C7_NUM IN "
cQry1 +=  "  (SELECT CR_FILIAL||CR_NUM FROM " + RetSqlName("SCR") + " SCR 
cQry1 +=  "    WHERE CR_FILIAL = SC7.C7_FILIAL AND CR_NUM = SC7.C7_NUM  AND SCR.D_E_L_E_T_ = ' '  AND SCR.CR_DATALIB = ' ' "

If !Empty(MV_PAR04)
	cQry1 += " AND CR_GRUPO IN "+FormatIn(AllTrim(MV_PAR04),";")
EndIf
If !Empty(MV_PAR05)
	cQry1 += " AND CR_APROV IN "+FormatIn(AllTrim(MV_PAR05),";")
EndIf
cQry1 +=  "  )"

//Filtra grupo de compras
If !Empty(MV_PAR03)
	cQry1 += " AND C7_NUM IN "+FormatIn(AllTrim(MV_PAR03),";")
EndIf
	
//Filtra grupo de compras
If !Empty(MV_PAR06)
	cQry1 += " AND C7_GRUPCOM IN "+FormatIn(AllTrim(MV_PAR06),";")
EndIf

//Filtra comprador
If !Empty(MV_PAR07)
	cQry1 += " AND C7_COMPRA  IN "+FormatIn(AllTrim(MV_PAR07),";")
EndIf

cQry1 += "  AND SC7.D_E_L_E_T_ = ' ' AND C7_RESIDUO <> 'S' "
cQry1 += "ORDER BY C7_FILIAL, C7_NUM, C7_EMISSAO "

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
   oProc:cCaption :=  "Lendo "+StrZero(nConta,nTam)+" de "+nTotal +" - Lendo Pedido " +(_cAlias)->C7_NUM
   ProcessMessages()   
   _dDtUltLib:=SToD((_cAlias)->C7_EMISSAO)
   _cObs:=""
   SCR->(DBSeek(xFilial("SCR")+"PC"+AllTrim((_cAlias)->C7_NUM)))
   _cAprov:=SCR->CR_APROV
   _cGrupo:=SCR->CR_GRUPO
   _lLoop:=.F.
   While SCR->(!Eof()) .And. xFilial("SCR")+"PC"+AllTrim((_cAlias)->C7_NUM) == SCR->CR_FILIAL+SCR->CR_TIPO+AllTrim(SCR->CR_NUM)
      If Empty(SCR->CR_DATALIB)//ULTIMO Pendente
         If MV_PAR08 = 1 
            If !SCR->CR_APROV $ AllTrim(MV_PAR05)
               _lLoop:=.T.
               Exit
            EndIf
         EndIf
         _cAprov:=SCR->CR_APROV  
         _cGrupo:=SCR->CR_GRUPO
         Exit
      Else
          If SCR->CR_STATUS = "04"
             If MV_PAR09 = 2 
                _lLoop:=.T.
                Exit
             EndIf
             _cObs:="Bloqueado por "+AllTrim(Posicione("SAK",1,xFilial("SAK")+SCR->CR_APROV,"AK_NOME"))+" ("+SCR->CR_GRUPO+")"
          EndIf
          If SCR->CR_STATUS = "06"
             If MV_PAR09 = 2 
                _lLoop:=.T.
                Exit
             EndIf
             _cObs:="Rejeitado por "+AllTrim(Posicione("SAK",1,xFilial("SAK")+SCR->CR_APROV,"AK_NOME"))+" ("+SCR->CR_GRUPO+")"
          EndIf
         _dDtUltLib:=SCR->CR_DATALIB
      EndIf 
      _cAprov:=SCR->CR_APROV
      _cGrupo:=SCR->CR_GRUPO
      SCR->(DBSkip()) 
   EndDo
   
   If _lLoop
	   (_cAlias)->(DBSkip())
      Loop
   EndIf

   _aItens:={}
	aAdd(_aItens,(_cAlias)->C7_NUM)
	aAdd(_aItens,SToD((_cAlias)->C7_EMISSAO))
	aAdd(_aItens,AllTrim((_cAlias)->C7_PRODUTO)+" - "+Posicione("SB1",1,xFilial("SB1")+(_cAlias)->C7_PRODUTO,"B1_DESC") )
	aAdd(_aItens,Transform((_cAlias)->C7_QUANT,PesqPict("SC7","C7_QUANT")))
	aAdd(_aItens,Transform((_cAlias)->C7_TOTAL,PesqPict("SC7","C7_TOTAL")))
	aAdd(_aItens,SToD((_cAlias)->C7_DATPRF))
	aAdd(_aItens,_cAprov+" - "+AllTrim(Posicione("SAK",1,xFilial("SAK")+_cAprov,"AK_NOME"))+" ("+SCR->CR_GRUPO+")" )
	aAdd(_aItens,_dDtUltLib)
	aAdd(_aItens,AllTrim(Str( ( DATE()-SToD((_cAlias)->C7_EMISSAO) )  ) ))  
	aAdd(_aItens,(_cAlias)->C7_COMPRA +" - "+AllTrim(Posicione("SY1",1,xFilial("SY1")+(_cAlias)->C7_COMPRA,"Y1_NOME"))+" ("+(_cAlias)->C7_GRUPCOM+")" )
	aAdd(_aItens,_cObs)
	aAdd(_aItens,(_cAlias)->RECSC7)

   aAdd(_aDados,_aItens)
	(_cAlias)->(DBSkip())
EndDo

If Len(_aDados) = 0 
    U_ITMsg("Não há dados para essa seleção",'Atenção!',,3)
EndIf

While Len(_aDados) > 0 
   _aTit:={}
   _aSiz:={}

   aAdd(_aTit,'Pedido') 
   aAdd(_aSiz,20)
   aAdd(_aTit,'Emissao')
   aAdd(_aSiz,25)
   aAdd(_aTit,'Produto')
   aAdd(_aSiz,100)
   aAdd(_aTit,'Quantidade')
   aAdd(_aSiz,35)
   aAdd(_aTit,'Valor')
   aAdd(_aSiz,30)
   aAdd(_aTit,'Entrega')
   aAdd(_aSiz,20)
   aAdd(_aTit,'Aprovador Pendente')
   aAdd(_aSiz,150)
   aAdd(_aTit,'Pendente desde')
   aAdd(_aSiz,50)
   aAdd(_aTit,'Dias Pendente')
   aAdd(_aSiz,50)
   aAdd(_aTit,'Comprador')
   aAdd(_aSiz,150)
   aAdd(_aTit,'Obeservacao')
   aAdd(_aSiz,200)
   aAdd(_aTit,'Registro')
   _nCampo:=Len(_aTit)
   aAdd(_aSiz,20)

   _cMsgTop:="Pedidos encontrados - H.I.: "+cTimeInicial+" H.F.: "+Time()

   _cTitulo:="Par. 1 : "+DToC(MV_PAR01)+"; Par. 2 : "+DToC(MV_PAR02)+"; Par. 3 : "+AllTrim(MV_PAR03)+"; Par. 4 : "+AllTrim(MV_PAR04)+;
           "; Par. 5 : "+AllTrim(MV_PAR05)+"; Par. 6 : "+AllTrim(MV_PAR06)+"; Par. 7 : "+AllTrim(MV_PAR07)
   _aBbuttons:={}
	aAdd(_aBbuttons,{"",{|| U_RCOM014AP()},"","Consulta Aprovadores"}) 
	aAdd(_aBbuttons,{"",{|| U_RCOM014V() },"","Visualizar Pedido de Compras"}) 
   
   
   bOk:={|| If(U_ITMsg("Confirma Gerar EXCEL ?",'Atenção!',,2,2,2) , DlgToExcel( { { "ARRAY" , _cTitulo , _aTit , _aDados } } )  ,.F. )   }

   //                           , _aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _aBbuttons )
      U_ITListBox(_cTitulo,_aTit,_aDados  , .T.    , 3    ,_cMsgTop,          ,_aSiz   ,         , bOk ,        , _aBbuttons )
                                                                                                  

   If  !U_ITMsg("Confirma Sair ?",'Atenção!',,3,2,2)
       Loop
   EndIf

    Exit

EndDo

Return

/*
===============================================================================================================================
Programa----------: RCOM014AP
Autor-------------: Alex Wallauer
Data da Criacao---: 11/01/2023
Descrição---------: Consulta Aprovadores
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM014AP()

Local _nRec:=oLbxAux:aArray[oLbxAux:nAt][_nCampo]

If _nRec > 0
   SC7->(DBGoTo(_nRec))
   aRotina := {{"XX","XX",0,2,0,NIL}}
   a120Posic("SC7",SC7->(RECNO()),1,If(SC7->C7_TIPO == 1,'PC','AE'),.F.,.F.)
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: RCOM014V
Autor-------------: Alex Wallauer
Data da Criacao---: 11/01/2023
Descrição---------: Função utilizada para visualizar Pedido de Compras A120Pedido()
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM014V()

Local aArea	
Local _nRec:=oLbxAux:aArray[oLbxAux:nAt][_nCampo]

If _nRec > 0

   aArea:= FWGetArea()

   SC7->(DBGoTo(_nRec))
   l120Auto	:= .F.
   cCadastro:= "Pedido de Compras"
   nTipoPed	:= 1
   Inclui   :=.F.
   Altera   :=.F.
   aRotina  := {{"XX","XX",0,2,0,NIL}}

   A120Pedido("SC7",SC7->(Recno()),1)

   FWRestArea(aArea)

EndIf

Return
