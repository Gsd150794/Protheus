/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |26/06/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
Igor Melgaço  |23/12/2024| Chamado 49402. Ajustes para buscar o número do PIS da SRA ao invés do banco da Telematica.
Lucas Borges  |08/07/2025| Chamado 50617. Revisões diversas visando padronizar os fontes
===============================================================================================================================
*/

#Include "TOTVS.ch"


/*
===============================================================================================================================
Programa----------: MPON001
Autor-------------: Alex Wallauer
Data da Criacao---: 10/08/2020
Descricao---------: Leitura das Catracas do Refeitorio - CHAMADO 33784
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MPON001

Local _aParRet := {} As Array
Local _aParAux := {} As Array
Local _bOK     := {|| If(MV_PAR02 >= MV_PAR01,.T.,(U_ITMsg("Periodo INVALIDO",'Atenção!',"Tente novamente com outro periodo",3),.F.) ) } As Block
Local nI       := 0 As Numeric


MV_PAR01:=dDataBase
MV_PAR02:=dDataBase
MV_PAR03:=Space(200)
MV_PAR04:="refeicao.txt"+Space(200)
MV_PAR05:=Space(10)

aAdd( _aParAux , { 1 , "Data de"	         , MV_PAR01, "@D"	, ""	, ""		, "" , 050 , .T. } )
aAdd( _aParAux , { 1 , "Data ate"	      , MV_PAR02, "@D"	, ""	, ""		, "" , 050 , .T. } )
aAdd( _aParAux , { 6 ,"Selecionar Dir."   , MV_PAR03 ,"","","",90,.T.,"Todos os arquivos (*.*) |*.*","C:\",GETF_RETDIRECTORY+GETF_LOCALHARD+GETF_NETWORKDRIVE})
aAdd( _aParAux , { 1 , "Arquivo"	         , MV_PAR04, "@!"	, ""	, ""		, "" , 050 , .T. } )
aAdd( _aParAux , { 1 , "Código da Catraca", MV_PAR05, "@!"	, ""	, ""		, "" , 050 , .T. } )

For nI := 1 To Len( _aParAux )
	aAdd( _aParRet , _aParAux[nI][03] )
Next nI

While .T.
   _lLoop:=.F.
   //            aParametros,cTitle                  ,aRet     ,bOk ,aButtons,lCentered,nPosX,nPosY,oDlgWizard,cLoad,lCanSave,lUserSave
   If !ParamBox( _aParAux , "Leitura das Catracas do Refeitorio" ,@_aParRet,_bOK,        ,         ,     ,     ,          ,     ,.T.     ,.T. )//Intervalo de Datas e Filial
      Exit
   EndIf

   FWMsgRun(,{|oproc|  MPON001Proc(oproc) },'Aguarde processamento...','Lendo dados...')

   If _lLoop//Se A função MPON001Proc() devolver .F. ou usuario abortar ou processsar normalmente dá o Loop para aparecer a tela novamente senão sai fora 
      Loop
   EndIf
   Exit//Botão cancela 
EndDo

Return

/*
===============================================================================================================================
Programa----------: MPON001Proc
Autor-------------: Alex Wallauer
Data da Criacao---: 10/08/2020
Descricao---------: le os dados para o Monitor do TAF
Parametros--------: oproc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MPON001Proc(oProc As Object) As Logical

Local _ntot    := 0 As Numeric
Local _npos    := 1 As Numeric
Local _cAlias  := GetNextAlias() As Character
Local _cCATREF := AllTrim(MV_PAR05) As Character

DEFAULT oProc := NIL

oproc:cCaption := ("Lendo dados...")
ProcessMessages()

BeginSql alias _cAlias
   SELECT ACES.DIREACES, ACES.CODICOLE, ACES.HORAACES,
         TO_CHAR(ACES.DATAACES,'DD/MM/YYYY') DATAACES,
         ACES.ICARD, LAB.NUMEPIS, LAB.TIPOCOLA, LAB.NUMECPF, SRA.RA_PIS
   FROM SURICATO.TBMARCAACESS@DB_SIGA ACES
   JOIN SURICATO.TBHISTOCRACH@DB_SIGA CRA ON CRA.ICARD = ACES.ICARD
   JOIN SURICATO.TBCOLAB@DB_SIGA LAB ON CRA.IDCOLAB = LAB.IDCOLAB
   JOIN %Table:SRA% SRA ON LPAD(LAB.NUMECPF,11,0) = SRA.RA_CIC AND SRA.D_E_L_E_T_ = ' '
   WHERE ACES.CODICOLE = %exp:_cCATREF% AND
         ACES.DATAACES >= TO_DATE(%exp:MV_PAR01%, 'YYYYMMDD') AND
         ACES.DATAACES <= TO_DATE(%exp:MV_PAR02%, 'YYYYMMDD') AND
         ((CRA.DATAINIC >= ACES.DATAACES AND
            CRA.DATAFINA <= ACES.DATAACES) OR
            CRA.DATAFINA = TO_DATE('19001231', 'YYYYMMDD')) AND
            SRA.RA_SITFOLH <> 'D'
   ORDER BY LAB.NUMEPIS , CRA.IDCOLAB
EndSql

Count To _ntot

_aHorarios:={}

(_cAlias)->(DBGoTop())

While !(_cAlias)->(Eof())
	
   oproc:cCaption := ("Lendo dados " + cValToChar(_npos) + " de " + cValToChar(_ntot))
   ProcessMessages()
   _npos++

   _nhoras  := Int((_cAlias)->HORAACES / 60)
   _nminutos:= (_cAlias)->HORAACES - ((INT((_cAlias)->HORAACES / 60))*60) 
   _cHoras  := StrZero(_nhoras,2) + ":" + StrZero(_nminutos,2)

   aAdd(_aHorarios,{((_cAlias)->DIREACES  = "S")           ,;//1
                        (_cAlias)->DIREACES                ,;//2
                        AllTrim(Str((_cAlias)->CODICOLE,3)),;//3
                        _cHoras                            ,;//4
                        (_cAlias)->DATAACES                ,;//5
                        StrZero((_cAlias)->ICARD,12)       ,;//6
                        StrZero(Val((_cAlias)->RA_PIS),11) ,;//7
                        StrZero((_cAlias)->TIPOCOLA,2)     })//8

   (_cAlias)->(DBSkip())
EndDo

If Len(_aHorarios) = 0
   FWAlertInfo("Não foram encontrados registros para essa selececao. Tente novamente com outro periodo","MPON00101")
   _lLoop:=.T.
   Return .T.
EndIf

While .T.

   _lLoop:=.F.
   _lRet:=.F.

   _lRet  :=U_ITListBox( 'Selecione um Ticket'                  ,;//           , _aCols     ,_lMaxSiz,_nTipo,_cMsgTop , _lSelUnc ,
                         {" ",'Direcao','Catraca','Hora','Data','Cracha','PIS','Tipo do Colaborador'} , _aHorarios , .T.    , 2    ,         ,          ,;
                         { 5 ,       30,  30     ,  20  ,   40 ,      75, 75  ,10})
                                                      // _aSizes , _nCampo , bOk , bCancel )
   If !_lRet
      _lLoop:=.T.
      Exit
   EndIf

   FWMsgRun(,{|oproc| MPON001Grava(oproc) },'Aguarde processamento...','Gerando Arquivo...')

   If _lLoop
      Loop
   EndIf

   Exit//Botão cancela 
EndDo

Return .T.

/*
===============================================================================================================================
Programa----------: MPON001Grava
Autor-------------: Alex Wallauer
Data da Criacao---: 10/08/2020
Descricao---------: Gera a Agenda
Parametros--------: oproc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MPON001Grava(oproc As Object)

Local Z     := 0 As Numeric
Local _ntot := Len(_aHorarios) As Numeric
Local _cDir := AllTrim(MV_PAR03) As Character
Local _cFile := AllTrim(MV_PAR04) As Character

If Right(_cDir,1) <> "\"
   _cDir := _cDir + "\"
EndIf
_oFile:= FWFileWriter():New(_cDir+_cFile)

If _oFile:Exists()
   If FWAlertYesNo("Arquivo " + _cDir+_cFile+" já existe. Deseja sobrepor ?","MPON00101")
      _lLoop:=.T.
      Return .F.
   EndIf
	If !_oFile:Erase()
		FWAlertError("Não foi possível excluir o arquivo " + _cDir+_cFile+". Feche o arquivo e Tente novamente","MPON00102" )
      _lLoop:=.T.
      Return .F.
	EndIf
EndIf

If !_oFile:Create()
   FWAlertError("Nao foi possível gerar o arquivo "+_cDir+AllTrim(MV_PAR04)+". Verifique os parametros e Tente novamente","MPON00103")
   _lLoop:=.T.
   Return .F.
EndIf

For Z := 1 To Len(_aHorarios)
   oproc:cCaption := ("Lendo: "+ cValToChar(Z) + " de " + cValToChar(_ntot))
   ProcessMessages()

   If !_aHorarios[Z,1]
      Loop
   EndIf
   
   _cLinha:='"'+_aHorarios[Z,2]+'";"'+_aHorarios[Z,3]+'";"'+_aHorarios[Z,4]+'";"'+_aHorarios[Z,5]+'";"'+_aHorarios[Z,6]+'";"'+_aHorarios[Z,7]+'"'+CHR(13)+CHR(10)
   _oFile:Write(_cLinha)
Next Z

_oFile:Close()
_oFile:= Nil

FWAlertSuccess("Arquivo "+_cDir+AllTrim(MV_PAR04)+" Gerado com sucesso","MPON00104")

Return .T.

