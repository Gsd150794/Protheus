/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Igor Melgaço  |10/03/2025| Chamado 49456. Ajustes para replicação das verbas
Igor Melgaço  |19/05/2025| Chamado 50567.  Ajustes para replicação das verbas
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: GP40VALPE
Autor-----------: Alexandre Villar
Data da Criacao-: 29/01/2016
Descrição-------: P.E. na validação do cadastro de Verbas
Parametros------: Nenhum - Variáveis em memória com dados da tabela de Verbas
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function GP40VALPE()

Local _lExec := .T. As Logical
Local oproc := nil As Object

_lExec := U_ITMsg( 'Deseja replicar as alterações da Verba atual para as demais Filiais da Empresa?' , 'Atenção!',,2,2,2 )

If _lExec
		
	FWMsgRun(,{ |oproc| U_GP40REP(oproc)},"Aguarde...","Iniciando processo de replicação...")
	
Else

	U_ITMsg("Processo de replicação cancelado!","Atenção",,1)

EndIf

Return

/*
===============================================================================================================================
Programa--------: GPEA040
Autor-----------: Josué Danich
Data da Criacao-: 26/10/2017
Descrição-------: P.E. na validação do cadastro de Verbas via MVC
Parametros------: Nenhum - Variáveis em memória com dados da tabela de Verbas
Retorno---------: ( .T. ) Dados validados / ( .F. ) Dados não validados
===============================================================================================================================
*/
User Function GPEA040() 

Local aParam     := ParamIXB As Array
Local xRet       := .T. 

oObj       := aParam[1]
cIdPonto   := aParam[2]
cIdModel   := aParam[3]

If cIdPonto == 'BUTTONBAR' .And. !IsInCallStack("U_AGPE006")

	xRet := { {'Replicar Verba', 'Replicar', { || U_GP40VALPE() }, 'Replica Verba para outras filiais' } }
		
EndIf

Return xRet

/*
===============================================================================================================================
Programa--------: GP40rep
Autor-----------: Josué Danich
Data da Criacao-: 14/11/2018
Descrição-------: Rotina de replicação de verbas
Parametros------: oproc - objeto da barra de processamento
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function GP40REP(oProc As Object)

Local _aAreaSRV	:= SRV->(GetArea()) As Array
Local _aCpoSRV	:= {} As Array
Local _cCpoExc	:= Upper( AllTrim( U_ITGETMV( 'IT_CPONSRV' , '' ) ) ) As Char
Local _cEmpCor	:= AllTrim(cEmpAnt) As Char
Local _cFilCor	:= AllTrim(cfilAnt) As Char
Local _nii 		:= 0 As Numeric
Local _nnk		:= 0 As Numeric
Local _aCpoSRVt := {} As Array
Local _cFilAntBkp := cFilAnt As Char
Local _nI         := 0 As Numeric
Local _aSM0        := {} As Array

aAdd(_aCpoSRVt,{"RV_COD","006"})
aAdd(_aCpoSRVt,{"RV_DESC","T...NIO SOBRE VERBAS"})
aAdd(_aCpoSRVt,{"RV_TIPOCOD","1"})
aAdd(_aCpoSRVt,{"RV_CODCORR"," "})
aAdd(_aCpoSRVt,{"RV_CODFOL","1285"})
aAdd(_aCpoSRVt,{"RV_TIPO","V"})
aAdd(_aCpoSRVt,{"RV_OBRIGAT","N"})
aAdd(_aCpoSRVt,{"RV_QTDLANC","9"})
aAdd(_aCpoSRVt,{"RV_INSS","S"})
aAdd(_aCpoSRVt,{"RV_IR","S"})
aAdd(_aCpoSRVt,{"RV_FGTS","S"})
aAdd(_aCpoSRVt,{"RV_INCORP","S"})
aAdd(_aCpoSRVt,{"RV_REF13","N"})
aAdd(_aCpoSRVt,{"RV_REFFER","N"})
aAdd(_aCpoSRVt,{"RV_ADIANTA","N"})
aAdd(_aCpoSRVt,{"RV_PERICUL","N"})
aAdd(_aCpoSRVt,{"RV_INSALUB","N"})
aAdd(_aCpoSRVt,{"RV_PENSAO","N"})
aAdd(_aCpoSRVt,{"RV_DSRHE","N"})
aAdd(_aCpoSRVt,{"RV_HE","N"})
aAdd(_aCpoSRVt,{"RV_ADICTS","N"})
aAdd(_aCpoSRVt,{"RV_SINDICA","N"})
aAdd(_aCpoSRVt,{"RV_SALFAMI","N"})
aAdd(_aCpoSRVt,{"RV_SEGVIDA","N"})
aAdd(_aCpoSRVt,{"RV_DEDINSS","N"})
aAdd(_aCpoSRVt,{"RV_TAREFA"," "})
aAdd(_aCpoSRVt,{"RV_PIS","N"})
aAdd(_aCpoSRVt,{"RV_ENCARCC"," "})
aAdd(_aCpoSRVt,{"RV_CUSTO"," "})
aAdd(_aCpoSRVt,{"RV_LCTOP","A99"})
aAdd(_aCpoSRVt,{"RV_MED13","N "})
aAdd(_aCpoSRVt,{"RV_MEDFER","N "})
aAdd(_aCpoSRVt,{"RV_MEDAVI","N "})
aAdd(_aCpoSRVt,{"RV_GRAMED"," "})
aAdd(_aCpoSRVt,{"RV_CONVCOL"," "})
aAdd(_aCpoSRVt,{"RV_VALDISS"," "})
aAdd(_aCpoSRVt,{"RV_MEDREAJ"," "})
aAdd(_aCpoSRVt,{"RV_RAIS","A-**************************************                    "})
aAdd(_aCpoSRVt,{"RV_DIRF","A "})
aAdd(_aCpoSRVt,{"RV_COMPL_","S"})
aAdd(_aCpoSRVt,{"RV_CODCOM_","230"})
aAdd(_aCpoSRVt,{"RV_DSRPROF","N"})
aAdd(_aCpoSRVt,{"RV_HRSATIV","N"})
aAdd(_aCpoSRVt,{"RV_CUSTEMP","2"})
aAdd(_aCpoSRVt,{"RV_LANCPCO"," "})
aAdd(_aCpoSRVt,{"RV_HOMOLOG","018"})
aAdd(_aCpoSRVt,{"RV_GRPVERB"," "})
aAdd(_aCpoSRVt,{"RV_CODDSR"," "})
aAdd(_aCpoSRVt,{"RV_DESCDET","TRIENIO SOBRE VERBAS                              "})
aAdd(_aCpoSRVt,{"RV_LCTODIA"," "})
aAdd(_aCpoSRVt,{"RV_VLIMDE",0})
aAdd(_aCpoSRVt,{"RV_VLIMATE",0})
aAdd(_aCpoSRVt,{"RV_RLIMDE",0})
aAdd(_aCpoSRVt,{"RV_RLIMATE",0})
aAdd(_aCpoSRVt,{"RV_CODMSEG"," "})
aAdd(_aCpoSRVt,{"RV_I_CUSTG"," "})
aAdd(_aCpoSRVt,{"RV_AGLTRCT"," "})
aAdd(_aCpoSRVt,{"RV_RRA"," "})
aAdd(_aCpoSRVt,{"RV_NATUREZ","1206"})
aAdd(_aCpoSRVt,{"RV_INCIRF","11"})
aAdd(_aCpoSRVt,{"RV_INCFGTS","11"})
aAdd(_aCpoSRVt,{"RV_INCSIND","00"})
aAdd(_aCpoSRVt,{"RV_INCCP","11"})
aAdd(_aCpoSRVt,{"RV_INSSFER","2"})
aAdd(_aCpoSRVt,{"RV_LEEINC","1"})
aAdd(_aCpoSRVt,{"RV_LEEPRE","1"})
aAdd(_aCpoSRVt,{"RV_LEEAUS","1"})
aAdd(_aCpoSRVt,{"RV_LEEBEN","1"})
aAdd(_aCpoSRVt,{"RV_LEEFIX","1"})
aAdd(_aCpoSRVt,{"RV_ORIGEM"," "})
aAdd(_aCpoSRVt,{"RV_FECCOMP","2"})
aAdd(_aCpoSRVt,{"RV_CODREMU"," "})
aAdd(_aCpoSRVt,{"RV_CODMEMO"," "})
aAdd(_aCpoSRVt,{"RV_INSSJUB"," "})
aAdd(_aCpoSRVt,{"RV_BSEREMT"," "})
aAdd(_aCpoSRVt,{"RV_BASCAL","1"})
aAdd(_aCpoSRVt,{"RV_FERSEG"," "})
aAdd(_aCpoSRVt,{"RV_EMPCONS","2"})
aAdd(_aCpoSRVt,{"RV_REFABON"," "})

For _nnk := 1 to Len(_aCpoSRVt)
		
	If  !( AllTrim( _aCpoSRVt[_nnk][1] ) $ _cCpoExc )
		aAdd( _aCpoSRV , { AllTrim( _aCpoSRVt[_nnk][1] ) , &( 'M->'+ AllTrim( _aCpoSRVt[_nnk][1] ) ) } )
	EndIf
		
Next

oproc:cCaption := ("Contando filiais ativas...")
ProcessMessages()

_ntot := 0
_aSM0 := FwLoadSM0()

For _nI := 1 To Len(_aSM0)
	If _cEmpCor == _aSM0[_nI,1]
		_ntot++
	EndIf
Next

_nkk := 0
For _nI := 1 To Len(_aSM0)
	If _cEmpCor == _aSM0[_nI,1]
		
		_nkk++
		oproc:cCaption := ("Replicando verba da filial " + AllTrim(_aSM0[_nI,2]) + " - " + StrZero(_nkk,6) + " de " + StrZero(_ntot,6) + ".")
		ProcessMessages()
		
		If _cFilCor <> AllTrim(AllTrim(_aSM0[_nI,2])) .And. !Empty(AllTrim(AllTrim(_aSM0[_nI,2])))
				
			DBSelectArea("SRV")
			SRV->( DBSetOrder(1) )
			If SRV->( DBSeek( AllTrim(_aSM0[_nI,2]) + M->RV_COD ) ) 
				
				cfilant := AllTrim(AllTrim(_aSM0[_nI,2]))
				aCab := {}
						
				For _nii := 1 to Len(_aCpoSRV)
						
					aAdd( aCab, { _aCpoSRV[_niI][01], &( 'M->'+ _aCpoSRV[_niI][01] ), Nil } )
					
				Next 
						
				_lretorno := FWMVCRotAuto(FwLoadModel("GPEA040"),'SRV',4,{{'SRVMASTER',aCab}},.F.,.T.) 
								
			Else
			
				cfilant := AllTrim(AllTrim(_aSM0[_nI,2]))
				aCab := {}
						
				For _nii := 1 to Len(_aCpoSRV)
						
					aAdd( aCab, { _aCpoSRV[_nII][01], &( 'M->'+ _aCpoSRV[_nII][01] ), Nil } )
						
				Next 
											
				_lretorno := FWMVCRotAuto(FwLoadModel("GPEA040"),'SRV',3,{{'SRVMASTER',aCab}},.F.,.T.)
								
			EndIf
				
										
		EndIf
	EndIf
Next

SRV->(FWRestArea(_aAreaSRV))
cfilant := _cFilAntBkp
U_ITMsg("Replicação de verbas concluída!","Atenção",,2)

Return
