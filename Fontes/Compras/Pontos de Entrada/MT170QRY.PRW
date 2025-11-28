/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT170QRY
Autor-------------: Alex Wallauer
Data da Criacao---: 24/02/2022
Descrição---------: Ponto de entrada antes da  geração das SCs. Chamado: 39266 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT170QRY

Local _aParRet	:= {} , nI
Local _aParAux  := {}
Local _aPars    := {}

Public cUrgen:= " "
Public cCCust:= Space(Len(SC1->C1_CC     ))
Public cAprov:= Space(Len(SC1->C1_I_CODAP))
Public cObsSC:= Space(Len(SC1->C1_I_OBSSC))

//Guarda parametros atuais e refaz pergunte
For nI = 1 to 10
	_cNome := "MV_PAR" + StrZero(nI,2)
	aAdd(_aPars, &(_cNome) )
Next	

MV_PAR01:= Space(Len(SC1->C1_CC     ))
MV_PAR02:= Space(Len(SC1->C1_I_CODAP))
MV_PAR03:= "N"
MV_PAR04:= Space(Len(SC1->C1_I_OBSSC))
_cValCC := ' cCCust:=MV_PAR02 , U_VldInf("C") .And. U_VldZLH(cFilAnt) .And.  Ctb105CC() '
_cValAP := ' cAprov:=MV_PAR03 , U_VldInf("A") '

_aParAux:={}
aAdd( _aParAux , { 1 , "'C. Custo'"	  , MV_PAR01, "@!" , _cValCC, "CTTZLH"	, "" , 050 , .T. } )
aAdd( _aParAux , { 1 , "Aprovador"	  , MV_PAR02, "@!" , _cValAP, 'ZZ7APR'	, "" , 050 , .T. } )
aAdd( _aParAux , { 2 , "Urgente"      , MV_PAR03, {"S-Sim","N-Nao"}     , 050 ,".T.",.T.,".T."}) 
aAdd( _aParAux , { 1 , "Obs. Generica", MV_PAR04, "@!"    , ""	, ''	    , "" , 100 , .F. } )

For nI := 1 To Len( _aParAux )
    aAdd( _aParRet , _aParAux[nI][03] )
Next 

// ParamBox( _aParAux , cTitle                  , @aRet     ,[bOk]    , [ aButtons ] [ lCentered ] [ nPosX ] [ nPosy ] [ oDlgWizard ] [ cLoad ] [ lCanSave ] [ lUserSave ] 
If ParamBox( _aParAux , "Digite os dados da SC" , @_aParRet ,{||.T.}  , /*aButtons*/,/*lCentered*/,/*nPosX*/,/*nPosy*/,/*oDlgWizard*/,/*cLoad*/,.T.         ,.T.          )
   cCCust:= MV_PAR01
   cAprov:= MV_PAR02
   cUrgen:= MV_PAR03
   cObsSC:= MV_PAR04
EndIf
For nI = 1 to 10
	_cNome    := "MV_PAR" + StrZero(nI,2)
	&(_cNome) := _apars[nI]
Next nI

Return .T.
