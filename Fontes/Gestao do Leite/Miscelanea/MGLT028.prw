/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |16/01/2016| Chamado 18442. Criação de Log e analise de dados.
Lucas Borges  |15/04/2019| Chamado 28346. Revisão de fontes
Lucas Borges  |03/09/2019| Chamado 28346. Corrigido o nome do pergunte
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGLT028
Autor-------------: Josué Danich Prestes
Data da Criacao---: 11/10/2016
Descrição---------: Rotina criada para trocar o fretista - Chamado 16752   
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGLT028()

Private _cPerg	:= "MGLT028"
Private _nCont	:= 0

If Pergunte(_cPerg, .T.)
	Processa( {|| MGLT028GRV() }, , "Aguarde, processando informações...")
EndIf

Return

/*
===============================================================================================================================
Programa----------: MGLT028GRV
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 13/10/2016
Descrição---------: Função de gravação da troca de fretista
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGLT028GRV()
Local _cAlias	:=GetNextAlias()
Local _aLog		:={}
Local _cFiltro	:= "% "
Local _nTotal	:= 0

DBSelectArea("ZLD")

ProcRegua(0)

If !Empty(MV_PAR04)//Rota
	_cFiltro += " AND ZLD_LINROT BETWEEN  '"+ MV_PAR03 +"' AND '"+ MV_PAR04 +"' "
Else
	_cFiltro += " AND ZLD_LINROT >= '"+ MV_PAR03 +"' "
EndIf

If !Empty(MV_PAR05)
	_cFiltro += " AND ZLD_FRETIS||ZLD_LJFRET >= '"+MV_PAR05+AllTrim(MV_PAR06)+"'"
EndIf

If !Empty(MV_PAR07)
	_cFiltro += " AND ZLD_FRETIS||ZLD_LJFRET <= '"+MV_PAR07+AllTrim(MV_PAR08)+"'"
EndIf
_cFiltro += " %"
	
IncProc("Lendo Dados Aguarde...")

BeginSql alias _cAlias
	SELECT ZLD.R_E_C_N_O_ REC_ZLD, A2_NOME
	FROM %Table:ZLD% ZLD, %Table:SA2% SA2
	WHERE ZLD.D_E_L_E_T_ = ' '
	AND SA2.D_E_L_E_T_ = ' '
	AND ZLD_FILIAL = %xFilial:ZLD%
	AND ZLD_DTCOLE BETWEEN %exp:MV_PAR01% AND %exp:MV_PAR02%
	AND ZLD_FRETIS = A2_COD
	AND ZLD_LJFRET = A2_LOJA
	%exp:_cFiltro%
EndSql

Count To _nTotal
(_cAlias)->(DBGoTop())

ProcRegua(_nTotal)

If _nTotal == 0
	MsgStop("Não tem registros para o filtro selecionado!","MGLT02801")
	Return .F.
EndIf

If !MsgYesNo("Serão processados "+AllTrim(Str(_nTotal,10))+" registros. Continua?","MGLT02802")
   Return .F.
EndIf

ZL3->( DBSetOrder(1))

BEGIN TRANSACTION

_nDias:=0

While !(_cAlias)->(Eof()) //.And. ZLD->ZLD_DTCOLE >= MV_PAR01 .And. ZLD->ZLD_DTCOLE <= MV_PAR02

   ZLD->(DBGoTo( (_cAlias)->REC_ZLD  ))
    
   _nDias++
    
   IncProc("Lendo dia: "+DToC(ZLD->ZLD_DTCOLE)+" - "+AllTrim(Str(_nDias,10))+" de "+AllTrim(Str(_nTotal,10))+" ..." )

   aAdd( _aLog , {.F.,;//1
                  ZLD->ZLD_FRETIS,;//2
                  ZLD->ZLD_LJFRET,;//3
                  (_cAlias)->A2_NOME,;//4
                  "",;//5
                  "",;//6
                  "",;//7
                  DToC(ZLD->ZLD_DTCOLE),;//8
                  ZLD->ZLD_SETOR ,;//9 
                  ZLD->ZLD_TICKET,;//10
                  ZLD->ZLD_LINROT,;//11
                  TRANSF(ZLD->ZLD_QTDBOM,PesqPict("ZLD","ZLD_QTDBOM")) ,;//12
                  TRANSF(ZLD->ZLD_KM,PesqPict("ZLD","ZLD_KM")) ,;//13
                  If(ZLD->ZLD_STATUS="F","Fechado","Aberto")})//14
    
	If ZL3->(DBSeek(ZLD->(ZLD_FILIAL+ZLD_LINROT)))

		If ZL3->ZL3_FROBR == 'S'
	
			_aLog[Len(_aLog),5]:=ZL3->ZL3_FRETIS
			_aLog[Len(_aLog),6]:=ZL3->ZL3_FRETLJ
			_aLog[Len(_aLog),7]:=LEFT(Posicione("SA2",1,xFilial("SA2")+ZL3->ZL3_FRETIS+ZL3->ZL3_FRETLJ,"A2_NOME"),40)

			If (ZLD->ZLD_FRETIS # ZL3->ZL3_FRETIS .Or. ZLD->ZLD_LJFRET # ZL3->ZL3_FRETLJ) .And. ZLD->ZLD_STATUS # "F"
			   _aLog[Len(_aLog),1]:=.T.
			   _nCont++
            EndIf
            
			If MV_PAR09 = 1 .And. (ZLD->ZLD_FRETIS # ZL3->ZL3_FRETIS .Or. ZLD->ZLD_LJFRET # ZL3->ZL3_FRETLJ) .And. ZLD->ZLD_STATUS # "F"
  			   ZLD->(RecLock("ZLD", .F.))
			   ZLD->ZLD_FRETIS := ZL3->ZL3_FRETIS
			   ZLD->ZLD_LJFRET := ZL3->ZL3_FRETLJ
			   ZLD->(MSUnLock())
			EndIf
	
	    Else
            _aLog[Len(_aLog),5]:=ZL3->ZL3_FROBR
		EndIf
	EndIf

	(_cAlias)->(DBSkip())

EndDo

END TRANSACTION

_cTitAux:='Log de Processamento'
If MV_PAR09 = 1 
   _cMsgTop:='Foram alterados [' + AllTrim(Str(_nCont)) + '] registros.'
Else
   _cMsgTop:='Foram analisados [' + AllTrim(Str(_nCont)) + '] registros diferentes.' 
EndIf
_cTitAux+=" - "+_cMsgTop
_cMsgTop+=" Filial processada: "+xFilial("ZLD")

//ITListBox( _cTitAux                                              , _aHeader                                                                  , _aCols,_lMaxSiz,_nTipo,_cMsgTop , _lSelUnc , _aSizes              , _nCampo ) 
  U_ITListBox( _cTitAux , {'' ,'Fretista (ZLD)','Loja','Nome','Fretista (ZL3)','Loja','Nome','Data','Setor','Ticket','Rota','Qtde Leite','KM','Status'} , _aLog , .T.    , 4    ,_cMsgTop,          ,;
                          { 10,         50     , 30   ,65    , 50             , 25   ,65    ,40    , 30    ,45      , 30   , 25         , 15 , 25       } )

Return .T.
