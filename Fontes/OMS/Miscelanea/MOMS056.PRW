/*
===============================================================================================================================
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUCAO INICIAL
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                            
 ===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "rwmake.ch"
#Include "TopConn.ch"

/*
===============================================================================================================================
Programa----------: MOMS056
Autor-------------: Alex Wallauer
Data da Criacao---: 05/08/2020
===============================================================================================================================
Descricao---------: Agenda dos Vendedores - CHAMADO 33805
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MOMS056()

Local _aParRet :={}
Local _aParAux :={} , nI
Local _bOK     :={|| If(MV_PAR02 >= MV_PAR01,.T.,(U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo",3),.F.) ) }


MV_PAR01:=dDataBase
MV_PAR02:=dDataBase
MV_PAR03:=dDataBase

aAdd( _aParAux , { 1 , "Data de:"	, MV_PAR01, "@D"	, ""	, ""		, "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Data ate:"	, MV_PAR02, "@D"	, ""	, ""		, "" , 050 , .F. } )

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next nI

While .T.

   _lLoop:=.F.
//            aParametros,cTitle                  ,aRet     ,bOk ,aButtons,lCentered,nPosX,nPosY,oDlgWizard,cLoad,lCanSave,lUserSave
    If !ParamBox( _aParAux , "Intervalo de Datas" ,@_aParRet,_bOK,        ,         ,     ,     ,          ,     ,.T.     ,.T. )//Intervalo de Datas e Filial
	   Exit
    EndIf

    FWMsgRun(,{|oproc|  MOMS056Proc(oproc) },'Aguarde processamento...','Lendo dados...')
   
    If _lLoop//Se A função MOMS056Proc() devolver .F. ou usuario abortar ou processsar normalmente dá o Loop para aparecer a tela novamente senão sai fora 
       Loop
    EndIf

    Exit//Botão cancela 

EndDo

Return

/*
===============================================================================================================================
Programa----------: MOMS056Proc
Autor-------------: Alex Wallauer
Data da Criacao---: 05/08/2020
===============================================================================================================================
Descricao---------: le os dados para o Monitor do TAF
===============================================================================================================================
Parametros--------: oproc
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS056Proc(oproc)
Local _cQry		:= ""
Local _ntot := 0
Local _npos := 1
Local _cAlias:= GetNextAlias()
DEFAULT oproc := NIL

oproc:cCaption := ("Lendo dados...")
ProcessMessages()

_cQry := "SELECT A1_COD, A1_LOJA, A1_NOME , A1_I_SEMAN, A1_I_FREQ "
_cQry += " FROM " + RetSqlName("SA1") 
_cQry += " WHERE  D_E_L_E_T_  = ' '  "//???? AND  A1_MSBLQL <> '1'
_cQry += "   AND  A1_I_SEMAN <> ' ' AND  A1_I_FREQ <> ' ' "
_cQry += " ORDER BY A1_COD,A1_LOJA "

DBUSEAREA( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , _cAlias , .T., .F. )

COUNT TO _ntot

_aClientes:={}

(_cAlias)->(DBGoTop())

While !(_cAlias)->(Eof())
	
   oproc:cCaption := ("Lendo dados " + CVALTOCHAR(_npos) + " de " + CVALTOCHAR(_ntot))
   ProcessMessages()
   _npos++

   aAdd(_aClientes,{.T.,(_cAlias)->A1_COD  ,;//2
                        (_cAlias)->A1_LOJA ,;//3
                        (_cAlias)->A1_NOME ,;//4
                     (_cAlias)->A1_I_SEMAN ,;//5
                      (_cAlias)->A1_I_FREQ })//6
   //6
   (_cAlias)->(DBSkip())//6
   //6
EndDo

If Len(_aClientes) = 0
   U_ITMsg("Não foram encontrados Clientes configurados ",'Atenção!',"Tente novamente com outro periodo",3)
   _lLoop:=.T.
   Return .T.
EndIf

While  .T.

   _lLoop:=.F.
   _lRet:=.F.

   _lRet  :=U_ITListBox( 'Lista de Clientes'                    ,;//           , _aCols     ,_lMaxSiz,_nTipo,_cMsgTop , _lSelUnc ,
                         {" ",'Codigo','Cliente','Dia da Semena','Frequencia'} , _aClientes , .T.    , 2    ,         ,          ,;
                         { 5 ,     30,  100     ,           100 },        )
                                                      // _aSizes , _nCampo , bOk , bCancel )
   If !_lRet
      _lLoop:=.T.
      Exit
   EndIf

   FWMsgRun(,{|oproc|  MOMS056Agenda(oproc,MV_PAR01,MV_PAR02) },'Aguarde processamento...','Lendo dados...')

   If _lLoop
      Loop
   EndIf

   Exit//Botão cancela 
   
EndDo


Return .T.


/*
===============================================================================================================================
Programa----------: MOMS056Agenda
Autor-------------: Alex Wallauer
Data da Criacao---: 05/08/2020
===============================================================================================================================
Descricao---------: Gera a Agenda
===============================================================================================================================
Parametros--------: oproc,MV_PAR01,MV_PAR02
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS056Agenda(oproc,MV_PAR01,MV_PAR02)
Local C , _lInv:=.T.
Local oOkV:=LoadBitmap( GetResources() , "BR_VERDE"    )
Local oOkA:=LoadBitmap( GetResources() , "BR_AMARELO"  )
Local _aDias:={"DOMINGO","SEGUNDA","TERCA","QUARTA","QUINTA","SEXTA","SABADO"}
Local _cAlias2:= GetNextAlias()


oproc:cCaption := ("Lendo dados dos Clientes...")
ProcessMessages()

_dData:=MV_PAR01
_aAgenda:={}
_ntot:=DateDiffDay(_dData,MV_PAR02)
_nConta:=0
While _dData <= MV_PAR02

   _nConta++
   oproc:cCaption := ("Lendo Data: "+DToC(_dData)+"-"+ CVALTOCHAR(_nConta) + " de " + CVALTOCHAR(_ntot))
   ProcessMessages()
/*
   If !(DAY(_dData) = 1 .And. Month(_dData) = 1) .And. !(DAY(_dData) = 31 .And. Month(_dData) = 12) 
      _dData:=_dData+1
      Loop
   EndIf*/

   _nDiaSem     := DOW(_dData)      //1 A 7
   _d1oDiaMes   := FirstDate(_dData)//Primeiro dia do mes da data
   _nNumSemAno  := Val(RetSem(_dData))    // 1 A 52 ou 53 //Numero da semana da _dData
   _lPar        := ((_nNumSemAno % 2) = 0 )  //Semana par ou impar
   _lBissexto   := (( Year(_dData) % 4) = 0 )//Ano Bissexto
   _nSemMes     := 0
   
   _cQry := "SELECT TO_CHAR(TO_DATE("+DToS(_dData)+",'YYYYMMDD'),'W') NSEMMES FROM DUAL" //SEMANA DO MES

   DBUSEAREA( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , _cAlias2 , .T., .F. )

   If !(_cAlias2)->(Eof())
      _nSemMes:=Val((_cAlias2)->NSEMMES)//Retorna o numero da semana do mes
   EndIf
   (_cAlias2)->(DBCloseArea())

   _cDes:=""//_aDias[_nDiaSem]
   _cDes+="NSD: "+StrZero(_nNumSemAno,2)
   _cDes+=" - NSM: "+CVALTOCHAR(_nSemMes)+If(_nSemMes=1," [M1]",If(_nSemMes=2," [M2]",If(_nSemMes=3," [M3]",If(_nSemMes=4," [M4]"," [M5]"))))
   _cDes+=" - "+If(_nNumSemAno = 53,"PAR+IMPAR",If(_lPar,"[QI] PAR","[QP] IMPAR"))
   _cDes+=If(_lBissexto," - [ANO BISSEXTO]","")
   //linha de dados do dia
   aAdd(_aAgenda, { If(_lInv,oOkV,oOkA),;//1
                                 _dData,;//2
                       _aDias[_nDiaSem],;//3
                                    "" ,;//4
                                 _cDes ,;//5
                                   .F. })//6

   For C := 1 TO Len(_aClientes) 
       If !_aClientes[C,1]
          Loop
       EndIf
       
       lFreq:=.F.
       lADD :=.F.
       _nPos:=6//A1_I_FREQ
       If _aClientes[C,_nPos] ="SE"
          lFreq:=.T.
       ElseIf _nNumSemAno = 53 .And. (_aClientes[C,_nPos] ="QI" .Or. _aClientes[C,_nPos] ="QP")
          lFreq:=.T.
       ElseIf _aClientes[C,_nPos] ="QI" .And. !_lPar
          lFreq:=.T.
       ElseIf _aClientes[C,_nPos] ="QP" .And. _lPar
          lFreq:=.T.
       ElseIf _aClientes[C,_nPos] ="M1" .And. _nSemMes = 1
          lFreq:=.T.
       ElseIf _aClientes[C,_nPos] ="M2" .And. _nSemMes = 2
          lFreq:=.T.
       ElseIf _aClientes[C,_nPos] ="M3" .And. _nSemMes = 3
          lFreq:=.T.
       ElseIf _aClientes[C,_nPos] ="M4" .And. _nSemMes = 4
          lFreq:=.T.
       EndIf
       _nPos:=5//A1_I_SEMAN
       If _nDiaSem = 1 .And. _aClientes[C,_nPos] ="DOM"
          lADD:=lFreq
       ElseIf _nDiaSem = 2 .And. _aClientes[C,_nPos] ="SEG"
          lADD:=lFreq
       ElseIf _nDiaSem = 3 .And. _aClientes[C,_nPos] ="TER"
          lADD:=lFreq
       ElseIf _nDiaSem = 4 .And. _aClientes[C,_nPos] ="QUA"
          lADD:=lFreq
       ElseIf _nDiaSem = 5 .And. _aClientes[C,_nPos] ="QUI"
          lADD:=lFreq
       ElseIf _nDiaSem = 6 .And. _aClientes[C,_nPos] ="SEX"
          lADD:=lFreq
       ElseIf _nDiaSem = 7 .And. _aClientes[C,_nPos] ="SAB"
          lADD:=lFreq
       EndIf

       If lADD
          aAdd(_aAgenda, { If(_lInv,oOkV,oOkA)                                             ,;//1
                                        _dData                                             ,;//2
                               _aClientes[C,2]                                             ,;//3
                               _aClientes[C,3]                                             ,;//4
                               _aClientes[C,5]+" - "+_aClientes[C,6]+" - "+_aClientes[C,4] ,;//5
                                          .T.                                              })//6
       EndIf
       
   Next
   
   _lInv:=!_lInv
   _dData:=_dData+1
   
EndDo

If Len(_aAgenda) = 0
   U_ITMsg("Não foram encontrados dados para esse perido ",'Atenção!',"Tente novamente com outro periodo",3)
   _lLoop:=.T.
   Return .T.
EndIf

_cMsgTop:='Agenda dos Vendedores'
While  .T.

   _lRet:=U_ITListBox( _cMsgTop           ,;// , _aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,
               {" ",'DATA','CODIGO',"LOJA",'CLIENTE'} , _aAgenda, .T.    , 1    ,       ,          ,;
               {10 ,    30,   40   ,    20, 150     }, 1       ,     ,        , )
                                // _aSizes , _nCampo , bOk , bCancel, _abuttons )

   If _lRet .And. U_ITMsg("Confirma GRAVAR ?",'Atenção!',,3,2,2)

      FWMsgRun(,{|oproc| MOMS056Grava(oproc) },'Aguarde processamento...','Grava dados...')

      _lLoop:=.T.
   Else
      _lLoop:=.F.
   EndIf

   Exit

EndDo

Private cCadastro	:= "AGENDA DOS VENDEDORES"
Private aRotina	:= {}                

aAdd(aRotina,{"Pesquisar"	,"AxPesqui",0,1})
aAdd(aRotina,{"Visualizar"	,"AxVisual",0,2})
aAdd(aRotina,{"Incluir"		,"AxInclui",0,3})
aAdd(aRotina,{"Alterar"		,"AxAltera",0,4})
aAdd(aRotina,{"Excluir"		,"AxDeleta",0,5})
	
DBSelectArea("ZAG")
DBSetOrder(1)
mBrowse(,,,,"ZAG")

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS056Agenda
Autor-------------: Alex Wallauer
Data da Criacao---: 05/08/2020
===============================================================================================================================
Descricao---------: Gera a Agenda
===============================================================================================================================
Parametros--------: oproc,MV_PAR01,MV_PAR02
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS056Grava(oproc)
Local Z
Local _ntot:=Len(_aAgenda)

DBSelectArea("ZAG")
DBSetOrder(1)

For Z := 1 TO Len(_aAgenda)
  
   oproc:cCaption := ("Lendo Data: "+DToC(_dData)+"-"+ CVALTOCHAR(Z) + " de " + CVALTOCHAR(_ntot))
   ProcessMessages()

    If !_aAgenda[Z,6]
       Loop
    EndIf
    If ZAG->(DBSeek(xFilial("ZAG")+DToS(_aAgenda[Z,2])+_aAgenda[Z,3]+_aAgenda[Z,4]))
       ZAG->(RecLock("ZAG",.F.))
    Else
       ZAG->(RecLock("ZAG",.T.))
    EndIf
    ZAG->ZAG_FILIAL:=xFilial("ZAG")
    ZAG->ZAG_DATA  :=_aAgenda[Z,2]
    ZAG->ZAG_CLIENT:=_aAgenda[Z,3]
    ZAG->ZAG_LOJA  :=_aAgenda[Z,4]
    ZAG->(MSUnLock())
    
Next

Return .T.
