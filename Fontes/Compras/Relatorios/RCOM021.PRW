/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |07/05/2025| Chamado 50617. Corrigir chamada estática no nome das tabelas do sistema
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: RCOM021
Autor-------------: Alex Wallauer
Data da Criacao---: 26/12/2022
Descricao---------: Relação de Questionamentos - CHAMADO 42202 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function RCOM021()
Local _aParRet :={}
Local _aParAux :={}  , nI
Local _bOK     :={|| If( MV_PAR01 < MV_PAR02  ,.T.,(U_ITMsg("Datas invalidas!",'Atencao',"Digite a data inicial menor ou igual a data fianl", 3),.F.) ) }

MV_PAR01:=CTOD("")
MV_PAR02:=CTOD("")
MV_PAR03:="1"
_aTipos:={"1-PC","2-SC"}
aAdd( _aParAux , { 1 , "Data Inicial"  , MV_PAR01, "@D"  , ""  ,"", "" , 060 , .T. } ) 
aAdd( _aParAux , { 1 , "Data Final"    , MV_PAR02, "@D"  , ""  ,"", "" , 060 , .T. } ) 
aAdd( _aParAux , { 2 , "Tipos"         , MV_PAR03,_aTipos, 060   ,".T.",.T. ,".T."}) 


For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next nI
          //aParametros, cTitle                       , @aRet    ,[bOk], [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
If !ParamBox( _aParAux , "Relação de Questionamentos" , @_aParRet, _bOK, /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
    Return .F.
EndIf

U_ITLOGACS( "RCOM021" )

SET DATE FORMAT TO "DD/MM/YYYY"

cTimeInicial:=Time()

FWMsgRun( ,{|oProc|   RCOM021R(oProc) } , "Hora Inicial: "+cTimeInicial+", Aguarde...",  )

SET DATE FORMAT TO "DD/MM/YY"

Return


/*
===============================================================================================================================
Programa----------: RCOM021R
Autor-------------: Alex Wallauer
Data da Criacao---: 26/12/2022
Descriçâo---------: Selecao de dados
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function  RCOM021R(oProc)
Local cQry1		:= ""
Local _cAlias  := GetNextAlias()

oProc:cCaption :=  "Selelecionado Dados, Aguarde... "
ProcessMessages()

_lTodos := (Posicione("ZZL",4,xFilial("ZZL")+UsrRetName(__cUserId),"ZZL_GCOM") = "S") .And. ZZL->ZZL_CC <> ' '

cQry1 += " SELECT R_E_C_N_O_ RECZY2 "
cQry1 += " FROM  " + RetSqlName("ZY2") + " A "
cQry1 += " WHERE A.ZY2_FILPED = '"+cFilAnt+"' "
If !Empty(MV_PAR01)
   cQry1 += " AND A.ZY2_DATAM >= "+DToS(MV_PAR01)
EndIf
If !Empty(MV_PAR02)
   cQry1 += " AND A.ZY2_DATAM <= "+DToS(MV_PAR02)
EndIf
If MV_PAR03 = "1"//PC
   cQry1 += " AND A.ZY2_ORIGEM  <> 'SC' "
ElseIf MV_PAR03 = "2"//SC
   cQry1 += " AND A.ZY2_ORIGEM  = 'SC' "
EndIf
cQry1 += " AND A.D_E_L_E_T_ = ' ' "

If !_lTodos
   cQry1 += " AND ZY2_PEDIDO IN (SELECT DISTINCT B.ZY2_PEDIDO FROM " + RetSqlName("ZY2") + " B   "
   cQry1 += "                         WHERE B.ZY2_FILPED  =  A.ZY2_FILPED "
   cQry1 += "                           AND B.ZY2_PEDIDO  =  A.ZY2_PEDIDO "
   cQry1 += "                           AND B.ZY2_USER  = '"+__cUserId+"' "
   cQry1 += "                           AND B.D_E_L_E_T_ = ' ' ) "
EndIf


cQry1 += " ORDER BY ZY2_FILPED, ZY2_PEDIDO, ZY2_DATAM, ZY2_HORAM
cQry1 := ChangeQuery(cQry1)

MPSysOpenQuery( cQry1, _cAlias )

nTotal:=nConta:=0
DBSelectArea(_cAlias)
COUNT TO nTotal
(_cAlias)->(DBGoTop())
_aDados:={}
nTotal:=AllTrim(Str(nTotal))
nTam:=Len(nTotal)

While !(_cAlias)->(Eof())

   nConta++
   oProc:cCaption :=  "Lendo "+StrZero(nConta,nTam)+" de "+nTotal
   ProcessMessages()
   ZY2->(DBGoTo( (_cAlias)->RECZY2 ))

   _aItens:={}
   aAdd(_aItens,ZY2->ZY2_FILPED) 
   aAdd(_aItens,ZY2->ZY2_PEDIDO) 
   aAdd(_aItens,UsrFullName(ZY2->ZY2_USER) ) //RCOM021FullNome( ZY2->ZY2_USER,oProc) ) 
   aAdd(_aItens,ZY2->ZY2_TIPO  ) 
   aAdd(_aItens,ZY2->ZY2_MENSAG) 
   aAdd(_aItens,DToC(  ZY2->ZY2_DATAM )) 
   aAdd(_aItens,ZY2->ZY2_HORAM ) 
   aAdd(_aDados,_aItens)
	
   (_cAlias)->(DBSkip())

EndDo

If Len(_aDados) = 0 
    U_ITMsg("Nao ha dados para essa selecao",'Atenção!',,3)
EndIf

While Len(_aDados) > 0 
   _aTit:={}
   _aSiz:={}

   aAdd(_aTit,'Filial') 
   aAdd(_aSiz,15)
   aAdd(_aTit,'Pedido')
   aAdd(_aSiz,15)
   aAdd(_aTit,'Usuario')
   aAdd(_aSiz,50)
   aAdd(_aTit,'Tipo')
   aAdd(_aSiz,15)
   aAdd(_aTit,'Mensagem')
   aAdd(_aSiz,150)
   aAdd(_aTit,'Data')
   aAdd(_aSiz,15)
   aAdd(_aTit,'Hora')
   aAdd(_aSiz,15)

   _cTitulo:="Relação de Questionamentos"

   _cMsgTop:="Questionamentos encontradas - H.I.: "+cTimeInicial+" H.F.: "+TIME()+" Par. 1 : "+AllToChar(MV_PAR01)+"; Par. 2 : "+AllToChar(MV_PAR02)+"; Par. 3 : "+AllToChar(MV_PAR03)
   
   bOk:=NIL//{|| If(U_ITMsg("Confirma Gerar EXCEL ?",'Atencao!',,2,2,2) , DlgToExcel( { { "ARRAY" , _cTitulo , _aTit , _aDados } } )  ,.F. )   }

   //                        , _aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
   U_ITListBox(_cTitulo,_aTit,_aDados  , .T.    , 3    ,_cMsgTop,          ,_aSiz   ,         , bOk ,        , )
                                                                                                  

   If  !U_ITMsg("Confirma Sair ?",'Atenção!',"Os dados serão perdidos",3,2,2)
       Loop
   EndIf

    Exit

EndDo

Return

/*
===============================================================================================================================
Programa----------: RCOM021FullNome()
Autor-------------: Alex Wallauer
Data da Criacao---: 26/12/2022
Descrição---------: RETORNA o nome complerto do usuario
Parametros--------: _cCodUser
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function RCOM021FullNome(_cCodUser,oProc)

Local nPos:=0
Static _aAllusers := {}
Default lPrimeiroNome := .F.
If Len(_aAllusers) = 0
   oProc:cCaption :=  "Lendo Usuarios..."
   ProcessMessages()
   _aAllusers := FWSFALLUSERS()
EndIf   

If (nPos:=aScan(_aAllusers, { |A| AllTrim(A[2]) == AllTrim(_cCodUser) })) <> 0
   Return _aAllusers[nPos][4]
EndIf

Return ""
