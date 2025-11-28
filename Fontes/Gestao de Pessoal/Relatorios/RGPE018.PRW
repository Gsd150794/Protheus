/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |16/09/2019| Chamado 28346. Retirado uso não permitido de API e Loop.
Alex Wallauer |24/02/2021| Chamado 28346. Retirado uso não permitido de API e Loop.
Lucas Borges  |09/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RGPE018
Autor-------------: Alex Wallauer
Data da Criacao---: 06/05/2019
Descrição---------: Relatório de histórico de funções do funcionario - Chamado 27521
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RGPE018()

_cSelePSRA:="SELECT RA_MAT, RA_NOME FROM "+RETSQLNAME("SRA")+" SRA WHERE D_E_L_E_T_ = ' ' AND RA_SITFOLH <> 'D' ORDER BY RA_NOME " 
                                                                           
_aItalac_F3:={}//       1           2         3                      4                      5                6                         7         8          9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela,_nCpoChave               , _nCpoDesc              ,_bCondTab    , _cTitAux                , _nTamChv , _aDados  , _nMaxSel , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR02" ,_cSelePSRA,{|Tab| (Tab)->RA_MAT}, {|Tab|(Tab)->RA_NOME}    ,             ,"Funcionarios"             ,          ,          ,99        ,.F.        ,       , } )

If Pergunte("RGPE018",.T.) .And. !Empty(MV_PAR03) .And. !Empty(MV_PAR04)
	cTimeInicial:=Time()
	FWMsgRun( ,{|oProc|  RGPE018R(oProc) } , "Processando - Hora Inicial: "+cTimeInicial+", Aguarde...",  )
EndIf
U_ITLOGACS( "RGPE018" )

Return

/*
===============================================================================================================================
Programa----------: RGPE018R
Autor-------------: Alex Wallauer
Data da Criacao---: 06/05/2019
Descrição---------: Função que imprime o relatório
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RGPE018R(oProc)
Local cQry1 := ""  , _nPos
Local _cAlias:= GetNextAlias()
Local _lLerTudo:=.F.
If LEFT(MV_PAR02,1) = "*"
   _lLerTudo:=.T.
   MV_PAR02:=SubStr(MV_PAR02,2)
EndIf

oProc:cCaption :=  "Selecionando Cargos, Aguarde... "
ProcessMessages()

_aDados:={}

If MV_PAR05 <> 2 

   cQry1 := "SELECT  R_E_C_N_O_ RECSR7 "
   cQry1 += "FROM " + RetSqlName("SR7") + " SR7  "
   cQry1 += " WHERE "
   cQry1 += " R7_FILIAL||R7_MAT IN (SELECT  R7_FILIAL||R7_MAT  "
   cQry1 += "                 FROM  " + RetSqlName("SR7") + " SR7  "
   cQry1 += "                 WHERE SR7.D_E_L_E_T_ = ' ' "
   If !Empty(MV_PAR01)
   	cQry1 += " AND R7_FILIAL IN "+FormatIn(AllTrim(MV_PAR01),";")
   EndIf
   If !Empty(MV_PAR04)
      cQry1 += "              AND R7_DATA BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "'"
   ElseIf !Empty(MV_PAR03)
      cQry1 += "              AND R7_DATA >= '" + DToS(MV_PAR03) + "'"
   EndIf   
   cQry1 += "           ) "
   If !Empty(MV_PAR02)
   	cQry1 += " AND R7_MAT IN "+FormatIn(AllTrim(MV_PAR02),";")
   EndIf
   
   cQry1 += " AND SR7.D_E_L_E_T_ = ' ' "
   cQry1 += " ORDER BY R7_FILIAL, R7_MAT, R7_DATA "
   
   //crio o novo alias
   MPSysOpenQuery( cQry1, _cAlias ) 
   
   nTotal:=nConta:=0
   DBSelectArea(_cAlias)
   COUNT TO nTotal
   (_cAlias)->(DBGoTop())
   
   nTotal:=AllTrim(Str(nTotal))
   nTam:=Len(nTotal)+1
   SRA->(DBSetOrder(1))
   SR7->(DBSetOrder(1))
   SR3->(DBSetOrder(2))
   
   While !(_cAlias)->(Eof())
      
      SR7->(DBGoTo((_cAlias)->RECSR7))
      nConta++
      oProc:cCaption :=  "Lendo Cargos - "+StrZero(nConta,nTam)+" de "+nTotal +" - Matricula: " +SR7->R7_MAT
      ProcessMessages()
   
      SRA->(DBSeek(SR7->R7_FILIAL+SR7->R7_MAT)) 
      If SRA->RA_SITFOLH = 'D'  
         (_cAlias)->(DBSkip())
         Loop
      EndIf
   
      _aItens:={}
       If (_nPos:=aScan(_aDados,{ |D| D[1] == SR7->R7_FILIAL .And. D[2] == SR7->R7_MAT })) = 0 .Or. _lLerTudo
          aAdd(_aItens,SR7->R7_FILIAL)//1
          aAdd(_aItens,SR7->R7_MAT)   //2
          aAdd(_aItens,AllTrim(SRA->RA_NOMECMP))//3
          aAdd(_aItens,AllTrim(SRA->RA_CC)+" - "+AllTrim(Posicione("CTT",1,xFilial("CTT")+SRA->RA_CC,"CTT_DESC01")))//4
          aAdd(_aItens,DToC(SR7->R7_DATA))      //5
          aAdd(_aItens,"")//Função anterior     //6
          aAdd(_aItens,AllTrim(SR7->R7_DESCFUN))//7
          cTipo:=""
          cSal:=""
          If SR3->(DBSeek(SR7->R7_FILIAL+SR7->R7_MAT)) 
             While SR3->(!Eof()) .And. SR7->R7_FILIAL+SR7->R7_MAT == SR3->R3_FILIAL+SR3->R3_MAT
                cTipo:=AllTrim(SR3->R3_TIPO)+" - "+AllTrim(Posicione("SX5",1,xFilial("SX5")+"41"+SR3->R3_TIPO,"X5_DESCRI"))//8
                cSal :="R$ "+TRANS(SR3->R3_VALOR,"@E 999,999,999,999.99")//9  //salario atual 
                SR3->(DBSkip()) 
             EndDo          
          EndIf
          aAdd(_aItens,cTipo)                //8
          aAdd(_aItens,cSal)                 //9
          aAdd(_aItens,"CARGO")              //10
          
          aAdd(_aDados,ACLONE(_aItens))
       Else
          _aDados[_nPos,4]:=AllTrim(SRA->RA_CC)+" - "+AllTrim(Posicione("CTT",1,xFilial("CTT")+SRA->RA_CC,"CTT_DESC01"))
          _aDados[_nPos,5]:=DToC(SR7->R7_DATA)
          _aDados[_nPos,6]:=_aDados[_nPos,7]//Função anterior 
          _aDados[_nPos,7]:=AllTrim(SR7->R7_DESCFUN)//Função atual 
       EndIf      
   
      (_cAlias)->(DBSkip())
   	
   EndDo
   
   If !_lLerTudo
      _aDadosAux:=ACLONE(_aDados)
      _aDados:={}
      For _nPos :=  1 TO Len(_aDadosAux)
          If Empty(_aDadosAux[_nPos,6]) .Or. Empty(_aDadosAux[_nPos,7]) .Or. AllTrim(_aDadosAux[_nPos,6]) = AllTrim(_aDadosAux[_nPos,7])
             Loop
          EndIf
          aAdd(_aDados,_aDadosAux[_nPos])
      Next
   EndIf
EndIf

If Len(_aDados) > 0 
   _aTit:={}
   aAdd(_aTit,"Filial") 
   aAdd(_aTit,"Matricula" )
   aAdd(_aTit,"Nome")
   aAdd(_aTit,"Centro de custo" ) 
   aAdd(_aTit,"Data de alteracao")
   aAdd(_aTit,"Funcao de " )
   aAdd(_aTit,"Funcao para")
   aAdd(_aTit,"Tipo de Aumento")
   aAdd(_aTit,"Salario")
   aAdd(_aTit,"Tipor Rel")
EndIf
//****************************  SALARIO  *************************************************
If MV_PAR05 <> 1
   oProc:cCaption :=  "Selecionando Salario, Aguarde... "
   ProcessMessages()
   
   cQry1 := "SELECT  R_E_C_N_O_ RECSR3 "
   cQry1 += "FROM " + RetSqlName("SR3") + " SR3  "
   cQry1 += " WHERE "
   cQry1 += " R3_FILIAL||R3_MAT IN (SELECT  R3_FILIAL||R3_MAT  "
   cQry1 += "                 FROM  " + RetSqlName("SR3") + " SR3  "
   cQry1 += "                 WHERE SR3.D_E_L_E_T_ = ' ' "
   If !Empty(MV_PAR01)
   	cQry1 += " AND R3_FILIAL IN "+FormatIn(AllTrim(MV_PAR01),";")
   EndIf
   If !Empty(MV_PAR04)
      cQry1 += "              AND R3_DATA BETWEEN '" + DToS(MV_PAR03) + "' AND '" + DToS(MV_PAR04) + "'"
   ElseIf !Empty(MV_PAR03)
      cQry1 += "              AND R3_DATA >= '" + DToS(MV_PAR03) + "'"
   EndIf   
   cQry1 += "           ) "
   If !Empty(MV_PAR02)
   	cQry1 += " AND R3_MAT IN "+FormatIn(AllTrim(MV_PAR02),";")
   EndIf
   
   cQry1 += " AND SR3.D_E_L_E_T_ = ' ' "
   cQry1 += " ORDER BY R3_FILIAL, R3_MAT, R3_DATA "
   
   //crio o novo alias
   MPSysOpenQuery( cQry1, _cAlias ) 
   
   nTotal:=nConta:=0
   DBSelectArea(_cAlias)
   COUNT TO nTotal
   (_cAlias)->(DBGoTop())
   
   If Len(_aDados) = 0 //Se não tem dados de função
      _aTit:={}
      aAdd(_aTit,"Filial") 
      aAdd(_aTit,"Matricula" )
      aAdd(_aTit,"Nome")
      aAdd(_aTit,"Tipo Aumento" ) 
      aAdd(_aTit,"Data de alteracao")
      aAdd(_aTit,"Salario de " )
      aAdd(_aTit,"Salario para")
      aAdd(_aTit,"")
      aAdd(_aTit,"")
      aAdd(_aTit,"Tipor Rel")
   ElseIf nTotal > 0
      _aItens:={} ; lDel:=.T.
      aAdd(_aItens,"Filial") 
      aAdd(_aItens,"Matricula" )
      aAdd(_aItens,"Nome")
      aAdd(_aItens,"Tipo Aumento" ) 
      aAdd(_aItens,"Data de alteracao")
      aAdd(_aItens,"Salario de " )
      aAdd(_aItens,"Salario para")
      aAdd(_aItens,"")
      aAdd(_aItens,"")
      aAdd(_aItens,"Tipor Rel")
      aAdd(_aDados,ACLONE(_aItens))
   EndIf
   
   nTotal:=AllTrim(Str(nTotal))
   nTam:=Len(nTotal)+1
   SRA->(DBSetOrder(1))
   SR3->(DBSetOrder(1))
   nConta:=0
   While !(_cAlias)->(Eof())
      
      SR3->(DBGoTo((_cAlias)->RECSR3))
      SRA->(DBSeek(SR3->R3_FILIAL+SR3->R3_MAT)) 
      If SRA->RA_SITFOLH = 'D'  
         (_cAlias)->(DBSkip())
         Loop
      EndIf
      nConta++
      oProc:cCaption :=  "Lendo Salario - "+StrZero(nConta,nTam)+" de "+nTotal +" - Matricula: " +SR3->R3_MAT
      ProcessMessages()
   
      _aItens:={}
       If (_nPos:=aScan(_aDados,{ |D| D[1] == SR3->R3_FILIAL .And. D[2] == SR3->R3_MAT .And. D[10] == "SALARIO"})) = 0 .Or. _lLerTudo
          aAdd(_aItens,SR3->R3_FILIAL)//1
          aAdd(_aItens,SR3->R3_MAT)   //2
          aAdd(_aItens,AllTrim(SRA->RA_NOMECMP))//3
          aAdd(_aItens,AllTrim(SR3->R3_TIPO)+" - "+AllTrim(Posicione("SX5",1,xFilial("SX5")+"41"+SR3->R3_TIPO,"X5_DESCRI")))//4
          aAdd(_aItens,DToC(SR3->R3_DATA))      //5
          aAdd(_aItens,"")                      //6  //salario anterior 
          aAdd(_aItens,"R$ "+TRANS(SR3->R3_VALOR,"@E 999,999,999,999.99"))  //7  //salario atual 
          aAdd(_aItens,"")               //8
          aAdd(_aItens,"")               //9
          aAdd(_aItens,"SALARIO")        //10
          lDel:=.F.
          aAdd(_aDados,ACLONE(_aItens))
       Else
          _aDados[_nPos,4]:=AllTrim(SR3->R3_TIPO)+" - "+AllTrim(Posicione("SX5",1,xFilial("SX5")+"41"+SR3->R3_TIPO,"X5_DESCRI"))//4
          _aDados[_nPos,5]:=DToC(SR3->R3_DATA)    //5 
          _aDados[_nPos,6]:=_aDados[_nPos,7]      //6  //salario anterior 
          _aDados[_nPos,7]:="R$ "+TRANS(SR3->R3_VALOR,"@E 999,999,999,999.99")//7  //salario atual 
       EndIf      
   
      (_cAlias)->(DBSkip())
   	
   EndDo
   
   If !_lLerTudo
      _aDadosAux:=ACLONE(_aDados)
      _aDados:={}
      For _nPos :=  1 TO Len(_aDadosAux)
          If Empty(_aDadosAux[_nPos,6]) .Or. Empty(_aDadosAux[_nPos,7]) .Or. AllTrim(_aDadosAux[_nPos,6]) = AllTrim(_aDadosAux[_nPos,7])
             Loop
          EndIf
          If lDel .And._aDadosAux[_nPos,1] = "Filial"
             Loop
          EndIf
          aAdd(_aDados,_aDadosAux[_nPos])
      Next
   EndIf

EndIf

If Len(_aDados) = 0 .Or. nConta = 0
    U_ITMsg("Não há dados para essa seleção",'Atenção!',,3)
EndIf

While Len(_aDados) > 0 

   _aSiz:={}
   aAdd(_aSiz,30)
   aAdd(_aSiz,30)
   aAdd(_aSiz,90)
   aAdd(_aSiz,90)
   aAdd(_aSiz,30)
   aAdd(_aSiz,90)
   aAdd(_aSiz,20)
   
   _cTitulo := "RELATORIO DE HISTORICO DE FUNCOES / SALARIO DOS FUNCIONARIOS " 
   
   _cMsgTop:="Informacoes encontradas - H.I.: "+cTimeInicial+" H.F.: "+Time()

   _cTitulo:="Par. 1 : "+AllTrim(MV_PAR01)+"; Par. 2 : "+AllTrim(MV_PAR02)+"; Par. 3 : "+DToC(MV_PAR03)+"; Par. 4 : "+DToC(MV_PAR04)
           
           
   bOk:={|| If(U_ITMsg("Confirma Gerar EXCEL ?",'Atenção!',,2,2,2) , DlgToExcel( { { "ARRAY" , _cTitulo , _aTit , _aDados } } )  ,.F. )   }

   //                           , _aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
      U_ITListBox(_cTitulo,_aTit,_aDados  , .T.    , 3    ,_cMsgTop,          ,_aSiz   ,         , bOk ,        , )
                                                                                                  

   If  !U_ITMsg("Confirma Sair ?",'Atenção!',,3,2,2)
       Loop
   EndIf

    Exit

EndDo

Return
