/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Jonathan      |04/05/2020| Chamado 32763. Alterar chamada "MsgBox" para "U_ITMsg"
Alex Wallauer |28/05/2020| Chamado 36494. Novo filtro / Campo para listar o usuario
Lucas Borges  |26/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MTAF001
Autor-------------: Alex Wallauer
Data da Criacao---: 09/08/2018
Descricao---------: Monitor do TAF
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MTAF001

Local _aParRet :={} As Array
Local _aParAux :={} As Array
Local nI       := 0 As Numeric
Local _bOK     :={|| If(MV_PAR02 >= MV_PAR01,.T.,(FWAlertWarning("Período inválido!!","MTAF00101" ),.F.) ) } As Codeblock

MV_PAR01:=dDataBase
MV_PAR02:=dDataBase
MV_PAR03:="1-Sim"
MV_PAR04:=dDataBase

aAdd( _aParAux , { 1 , "Data de"	           , MV_PAR01, "@D"	, ""	, ""		, "" , 050 , .F. } )
aAdd( _aParAux , { 1 , "Data ate"	        , MV_PAR02, "@D"	, ""	, ""		, "" , 050 , .F. } )
aAdd( _aParAux , { 2 , "Somente com Usuario", MV_PAR03, {"1-Sim","2-Nao"}          , 060 ,".T.",.T.,".T."}) 

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next nI

While .T.

   _lLoop:=.F.

    MV_PAR01:=MV_PAR04//e Volta
    If !ParamBox( _aParAux , "Intervalo de Datas" , @_aParRet, _bOK )
	   Exit
    EndIf
    MV_PAR04:=MV_PAR01//Salva

    FWMsgRun(,{|oproc|  MTAF001Proc(oproc) },'Aguarde processamento...','Lendo dados...')
   
    If _lLoop//Se A função MEST009K() devolver .F. ou usuario abortar ou processsar normalmente dá o Loop para aparecer a tela novamente senão sai fora 
       Loop
    EndIf

    Exit//Botão cancela 
EndDo

Return

/*
===============================================================================================================================
Programa----------: MTAF001Proc
Autor-------------: Alex Wallauer
Data da Criacao---: 09/08/2018
Descricao---------: le os dados para o Monitor do TAF
Parametros--------: oproc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MTAF001Proc(oproc As Object)

Local _cFiltro		:= "%%" As Character
Local _ntot    := 0 As Numeric
Local _npos    := 1 As Numeric
Local _cAlias  := GetNextAlias() As Character
Local _aParRet :={} As Array
Local _aParAux :={} As Array
Local nI       := 0 As Numeric

DEFAULT oproc := NIL

oproc:cCaption := ("Lendo dados do TAFXERP...")
ProcessMessages()
If MV_PAR03 = "1"
   _cFiltro := "% AND ST2.TAFUSER <> ' ' %"
EndIf

BeginSql alias _cAlias
   SELECT DISTINCT ERP.TAFTICKET, ERP.TAFDATA, ST2.TAFFIL, ST2.TAFUSER
   FROM TAFXERP ERP , TAFST2 ST2 
   WHERE ERP.TAFDATA >= %exp:MV_PAR01% AND ERP.TAFDATA <= %exp:MV_PAR02
   AND ERP.TAFTICKET = ST2.TAFTICKET 
   AND ERP.TAFKEY = ST2.TAFKEY
   %exp:_cFiltro%
   AND ERP.D_E_L_E_T_ = ' ' 
   AND  ST2.D_E_L_E_T_ = ' '
   ORDER BY ST2.TAFUSER DESC, ST2.TAFFIL , ERP.TAFDATA
EndSql

COUNT TO _ntot

_aTicket:={}
(_cAlias)->(DBGoTop())

While !(_cAlias)->(Eof())
   oproc:cCaption := ("Lendo Ticket " + StrZero(_npos,9) + " de " + StrZero(_ntot,9))
   ProcessMessages()
   _npos++
   aAdd(_aTicket,{SubStr((_cAlias)->TAFFIL,3,2),SToD((_cAlias)->TAFDATA),(_cAlias)->TAFTICKET,(_cAlias)->TAFUSER})
   (_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())

If Len(_aTicket) == 0
   FWAlertWarning("Não foram encontrados tickets para esse período. Tente novamente com outro período","MTAF00102")
   _lLoop:=.T.
   Return .T.
EndIf

MV_PAR01:="9-COM ERRO"
MV_PAR02:=Space(100)

aAdd( _aParAux , {2,"STATUS:",MV_PAR01    , {"1-INTEGRADO",;
                                             "2-ALTERADO ",;
                                             "9-COM ERRO ",;
                                             "O-OUTROS   ",;
                                             "T-TODOS    "},060,".T.",.T.,".T."}) 

aAdd( _aParAux , {1,"Filial:",MV_PAR02    ,"@!","","LSTFIL",'',100,.F.}) 

For nI := 1 To Len(_aParAux)
    aAdd(_aParRet , _aParAux[nI][03])
Next nI

While  .T.
   _lLoop:=.F.

   _cTicket:=U_ITListBox( 'Selecione um Ticket'               ,;//          , _aCols   ,_lMaxSiz,_nTipo,_cMsgTop , _lSelUnc ,
                         {'Filial','Data da Integração','Codigo do Ticket','User'} , _aTicket , .F.    , 3    ,         ,          ,;
                         {      30,            100     ,              100 ,    50}, 3       )
                                                                // _aSizes , _nCampo , bOk , bCancel )
   If Empty(_cTicket) .Or. ( ValType(_cTicket) = "L" )
      If ValType(_cTicket) = "L" .And. _cTicket
         _lLoop:=.T.
      EndIf   
      Exit
   EndIf

   If !ParamBox( _aParAux , "Selecione o Status" , @_aParRet, {|| !Empty(MV_PAR01) } )
      Loop
   EndIf
   
   FWMsgRun(,{|oproc|  MTAF001Tic(oproc,_cTicket,MV_PAR01,MV_PAR02) },'Aguarde processamento...','Lendo dados...')

   If _lLoop
      Loop
    EndIf
    Exit//Botão cancela 
EndDo

Return .T.

/*
===============================================================================================================================
Programa----------: MTAF001Tic
Autor-------------: Alex Wallauer
Data da Criacao---: 09/08/2018
Descricao---------: le os erros para o Monitor do TAF
Parametros--------: oproc,_cTicket,MV_PAR01,MV_PAR02
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MTAF001Tic(oproc As Object,_cTicket As Character,MV_PAR01 As Character,MV_PAR02 As Character)

Local _cFiltro	:= "% " As Character
Local _ntot    := 0 As Numeric
Local _npos    := 1 As Numeric
Local _cAlias  := GetNextAlias() As Character
Local _aBotao  :={} As Array

DEFAULT oproc := NIL

oproc:cCaption := ("Lendo dados do TAFXERP e TAFST2...")
ProcessMessages()

If Left(MV_PAR01,1) $ '1,2,9'
   _cFiltro += " AND ERP.TAFSTATUS = '"+Left(MV_PAR01,1)+"' "
ElseIf Left(MV_PAR01,1) = '0'
   _cFiltro += " AND NOT ERP.TAFSTATUS IN ('1','2','9')"
EndIf
If !Empty(MV_PAR02) 
   _cFiltro += " AND SubStr(ST2.TAFFIL,3,2) IN "+FormatIn(AllTrim(MV_PAR02),";")
EndIf
_cFiltro += " %"

BeginSql alias _cAlias
   SELECT ERP.TAFDATA, ERP.TAFHORA, ERP.TAFKEY, ERP.TAFSTATUS, ERP.TAFCODERR, ERP.TAFERR, ST2.TAFFIL,
         DBMS_LOB.SubStr(ERP.TAFERR,1000,1) TAFERRO, DBMS_LOB.SubStr(ST2.TAFMSG,1000,1) TAFMEMO
   FROM TAFXERP ERP, TAFST2 ST2 
   WHERE ERP.TAFTICKET = %exp:_cTicket%
   AND ERP.D_E_L_E_T_ = ' '
   AND ST2.D_E_L_E_T_ = ' '
   AND ERP.TAFTICKET = ST2.TAFTICKET
   AND ERP.TAFKEY    = ST2.TAFKEY
   %exp:_cFiltro%
   ORDER BY ERP.TAFKEY
EndSql

COUNT TO _ntot

(_cAlias)->(DBGoTop())
_aKEY:={}

While !(_cAlias)->(Eof())
   oproc:cCaption := ("Lendo registros " + StrZero(_npos,9) + " de " + StrZero(_ntot,9))
   ProcessMessages()
   _npos++

   aAdd(_aKEY,{SubStr((_cAlias)->TAFFIL,3,2),;//01
               SToD( (_cAlias)->TAFDATA ),;//02
               (_cAlias)->TAFHORA,;        //03
               AllTrim((_cAlias)->TAFKEY),;//04
               (_cAlias)->TAFSTATUS,;     //05
               "'"+(_cAlias)->TAFCODERR,;//06
               AllTrim((_cAlias)->TAFERRO),;//07
               AllTrim((_cAlias)->TAFMEMO)})//08
   
   (_cAlias)->(DBSkip())
EndDo
(_cAlias)->(DBCloseArea())

If Len(_aKEY) == 0
   FWAlertWarning("Não foram encontrados registros para esse Ticket. Tente novamente com outro Ticket","MTAF00103")
   _lLoop:=.T.
   Return .T.
EndIf

aAdd( _aBotao , {"", {|| U_ITMsg(oLbxAux:aArray[oLbxAux:nAt][7],"Mensagem de Erro",oLbxAux:aArray[oLbxAux:nAt][7],2)},"Mensagem de Erro"} )
aAdd( _aBotao , {"", {|| U_ITMsg(oLbxAux:aArray[oLbxAux:nAt][8],"Dados de Origem" ,oLbxAux:aArray[oLbxAux:nAt][8],2)},"Dados de Origem" } )
_cMsgTop:='MTAF001 - Lista de informaçoes do Ticket: '+_cTicket

While  .T.
   U_ITListBox( 'Lista de informaçoes do Ticket: '+_cTicket                                              ,;// , _aCols  ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,
               {'FILIAL','DATA','HORA','TAFKEY','STATUS','CODIGO ERRO','Descricao do Erro','Dados de origem'} , _aKEY   , .T.    , 3    ,_cMsgTop,          ,;
               {      20,    30,    30,      45,      25,         40  ,  200              ,150              }, 1       ,     ,        , _aBotao)
                                                                                                  // _aSizes , _nCampo , bOk , bCancel, _abuttons )
   If !FWAlertYesNo("Confirma voltar para a tela anterior?","MTAF00104")
      Loop
   EndIf

   _lLoop:=.T.
   Exit
EndDo

Return .T.
