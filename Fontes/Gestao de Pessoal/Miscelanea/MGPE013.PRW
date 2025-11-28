/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/09/2019| Chamado 28346. Retirada chamada da função itputx1
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25
Lucas Borges  |22/04/2025| Chamado 50505. Alterada a picture do CNPJ para contemplar campo alfanumérico
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "rwmake.ch"

/*
===============================================================================================================================
Programa----------: MGPE013
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/08/2015
Descrição---------: Geracao Arquivo de Recibos de Pagamento - BB
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE013()

Private _cPerg     	:= 'MGPE013'
Private _cLin		:= ''
Private _nQtFunc	:= 0
Private _nHdl		:= 0
Private _lLiq		:= .F.
Private _lData		:= .F.
Private _lHeader	:= .F.
Private _lContinua	:= .T.
Private _oGeraTxt
Private _nTotais 	:= 0

Pergunte(_cPerg,.F.)

DBSelectArea( "SRA" )
SRA->(DBSetOrder(1))

//-----------------------------------------------------------------------
// Montagem da tela de processamento.                                  
//-----------------------------------------------------------------------
@ 200,001 TO 410,480 DIALOG _oGeraTxt TITLE OemToAnsi( "Geracao do Arquivo de Pagamento" )
@ 002,010 TO 095,230
@ 010,018 Say " Este programa ira gerar o arquivo de demonstrativo de pagamento    "
@ 018,018 Say " para o Banco do Brasil.	 						   "
@ 026,018 Say "                                                                    "

@ 070,128 BMPBUTTON Type 05 ACTION Pergunte(_cPerg,.T.)
@ 070,158 BMPBUTTON Type 01 ACTION MGPE013O()
@ 070,188 BMPBUTTON Type 02 ACTION Close(_oGeraTxt)

Activate Dialog _oGeraTxt Centered

Return

/*
===============================================================================================================================
Programa----------: MGPE013O
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/08/2015
Descrição---------: Funcao chamada pelo botao OK na tela inicial de processamento. Executa a geracao do arquivo texto.    
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE013O

Local _cfilloc
Local _nI
Local _lachou := .F.

Private _afils := {}
Private _aresults := {}
Private _cconta
Private _cagencia
Private _cdigito
Private _nrecno

//Grava log de utilização
u_itlogacs()

//Roda Loop de filiais
If Empty(MV_PAR11)
	
	_cfilloc := cfilant
		
	SM0->(DBGoTop())
		
	While !(SM0->(Eof()))
		
		aAdd(_afils,AllTrim(SM0->M0_CODFIL))
		SM0->(DBSkip())
		
	EndDo
	SM0->(DBSeek('01' + cfilant))
	
Else
	
	_afils := {}
	_afils2 := {}
	
	If !Empty(MV_PAR11)
	
		_afils := StrTokArr(MV_PAR11,";")
		
	EndIf
	
	If !Empty(MV_PAR12)
	
		_afils2 := StrTokArr(MV_PAR12,";")
		
	EndIf
	
	For _nI := 1 to Len(_afils2)
	
		aAdd(_afils,_afils2[_nI])
		
	Next _nI
	
	_cfilloc := cfilant
		
EndIf
	
For _nI := 1 to Len(_afils)
	
		cfilant := _afils[_nI]
		_lHeader := .F.
		
		//Pega parâmetro com dados da agencia, conta/digito pagadora
		_lachou := .F.
		RCC->(DBSetOrder(1))
		If RCC->(DBSeek(xFilial("RCC")+"S052"+cfilant))
		
			While !(RCC->(Eof())) .And. RCC->RCC_FILIAL == xFilial("RCC") .And. RCC->RCC_CODIGO = "S052" .And. RCC->RCC_FIL = cfilant
			
			  If SubStr(RCC->RCC_CONTEU,21,3) == "001"
			  
			  	_lachou := .T.
			  	_cagencia := AllTrim(SubStr(RCC->RCC_CONTEU,24,5))
			  	_cconta := AllTrim(SubStr(RCC->RCC_CONTEU,30,12))
			  	_cdigito := AllTrim(SubStr(RCC->RCC_CONTEU,42,1))
			  	_nrecno := RCC->(Recno())
			  	
			  	Exit
			  	
			  EndIf
			  
			  RCC->(DBSkip())
			  
			EndDo
			
		EndIf
		
		If SM0->(DBSeek('01' + cfilant)) .And. _lachou
		
			_nQtFunc := 0 //Zera leituras de funcionarios
			FWMsgRun(,{|oproc| MGPE013R(oproc)},"Geracao do Arquivo Holerite","Processando dados...")  
				
		EndIf
		
Next
	
cfilant := _cfilloc
SM0->(DBSeek('01' + cfilant))
	

//Apresenta resultados da gravação
If Len(_aresults) > 0

	U_ITListBox( 'Dados gravados nos arquivos' , {"Filial","CC","Matricula","Nome","Vencimentos","Descontos","Liquido","Salário","Cons. Liquido","Situação"} , _aresults , .T. , 1 )
	U_ITMsg("Arquivos Gerado com no Diretorio : " + MV_PAR03, "Processo Concluído",,2 )
	
Else

	U_ITMsg("Não foram gerados arquivos!","Atenção",,1 )

EndIf



Close(_oGeraTxt)

Return

/*
===============================================================================================================================
Programa----------: MGPE013R
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/08/2015
Descrição---------: Funcao auxiliar chamada pela Processa.  A funcao Processa monta a janela com a regua de processamento.    
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE013R(oproc)

Local _cMesArqRef
Local _cAcessaSR1  := &("{ || " + ChkRH("GPER030","SR1","2") + "}")
Local _cAcessaSRA  := &("{ || " + ChkRH("GPER030","SRA","2") + "}")
Local _cAcessaSRC  := &("{ || " + ChkRH("GPER030","SRC","2") + "}")

//Variaveis para emissao do arquivo de ferias
Local _cDataBas	:= ""
Local _cDBaseAt	:= ""
Local _cDFerias	:= ""
Local _cDAbonPe	:= ""
Local _npos := 1
Local _nconta := 0
Local _cCodBco, _cCodAgenc, _cCodContaC, _lGravouArqTxt, _cTextoMsg, _cFilParam  

Private _cMesAnoRef
Private _cFinPgt, _nSequenc

Private _nTOTVENC, _nTOTDESC, _nFlag, _nChave
Private _cDesc_Fil, _cDesc_End, _cDESC_CGC, _cDESC_FUNC
Private _cFilialAnt, _cFuncaoAnt, _cCcAnt, _nVez, _nOrdemZ

Private _nAteLim, _nBaseFgts, _nFgts, _nBaseIr, _nBaseIrFe, _nLiquido

Private _aLanca := {}
Private _aProve := {}
Private _aDesco := {}
Private _aBases := {}
Private _aInfo  := {}
Private _aCodFol:= {}

Pergunte(_cPerg,.F.)
 
//----------------------------------------------------------------
// Cria o Arquivo TXT                                         
//----------------------------------------------------------------

_nHdl	:= MSFCREATE(AllTrim(MV_PAR03)+"BBHOL_" + cfilant +".REM")

If Ferror() # 0 .And. _nHdl = -1

	_cMsg := "Erro de abertura, codigo DOS:" + Str(FERROR(),2) 
	Aviso( "Atencao", _cMsg, { "OK" } ) 
    Return

EndIf


_cMesAnoRef := StrZero(Month(MV_PAR01),2) + StrZero(Year(MV_PAR01),4)
_cMesArqRef  := If(MV_PAR02 == 4,"13"+Right(_cMesAnoRef,4),_cMesAnoRef)


//----------------------------------------------------------------
//  Selecionando a Ordem de impressao escolhida no parametro.     
//----------------------------------------------------------------
DBSelectArea( "SI3" )
DBSetOrder(1)
DBSelectArea( "SRF" )
DBSetOrder(1)
DBSelectArea( "SRH" )
DBSetOrder(1)
DBSelectArea( "SRJ" )
DBSetOrder(1)
DBSelectArea( "SRR" )
DBSetOrder(1)
DBSelectArea( "SRA" )
DBSetOrder(1)

//----------------------------------------------------------------
// Carrega Regua Processamento                                  
//----------------------------------------------------------------
_nconta := RecCount()

SRA->(DBGoTop())

//----------------------------------------------------------------
//  Selecionando o Primeiro Registro e montando Filtro.           
//----------------------------------------------------------------
DBSeek(CFILANT + MV_PAR06,.T.)
_cCond := "SRA->RA_FILIAL + SRA->RA_MAT <= CFILANT + MV_PAR07"

DBSelectArea("SRA")
ProcRegua(RecCount())

_nTOTVENC    := _nTOTDESC   := _nFlag      := _nChave     := 0
_cDesc_Fil   := _cDesc_End  := _cDESC_CGC   := _cDESC_FUNC := ""
_cFilialAnt := "  "
_cFuncaoAnt := "    "
_cCcAnt     := Space(9)
_nVez        := 0
_nOrdemZ     := 0
_nSequenc   := 0

If MV_PAR02 == 1			// Adiantamento
	_cFinPgt := "02"
ElseIf MV_PAR02 == 2		// Folha
	_cFinPgt := "01"
ElseIf MV_PAR02 == 3		// 1a Parcela
	_cFinPgt := "04"
ElseIf MV_PAR02 == 4		// 2a Parcela
	_cFinPgt := "04"
ElseIf MV_PAR02	== 5		// Extras
	_cFinPgt := "10"
ElseIf MV_PAR02 == 6		// Ferias
	_cFinPgt := "07"
EndIf

If !(!(Fp_CodFol(@_aCodFol,cfilant)) .Or. ! (fInfo(@_aInfo,cfilant)))
	
	_cDesc_Fil := _aInfo[3]
	_cDesc_End := _aInfo[4]                // Dados da Filial
	_cDesc_CGC := _aInfo[8]
	_lcontinua := .T.
	
Else

	U_ITMsg("Filial " + cfilant + " não possui dados de folha cadastrados", "Atenção","Filial não será processada",1) 
	_lcontinua := .F.
			
EndIf


DBSelectArea("SRA")
While SRA->(!Eof()) .And. &_cCond .And. _lContinua

	//----------------------------------------------------------------
	// Movimenta Regua Processamento                                
	//----------------------------------------------------------------
  	If ValType(oproc) = "O"

      	oproc:cCaption := ("Processando filial " + AllTrim(cfilant) + " - Registro " + StrZero(_npos,6) + " de " + StrZero(_nconta,6) + "...")
   		ProcessMessages()
 
    EndIf
  	_npos++

	
	If (SRA->RA_FILIAL   < CFILANT)  .Or. (SRA->RA_FILIAL   > CFILANT) .Or. ;
		(SRA->RA_CC       < MV_PAR04)   .Or. (SRA->RA_CC       > MV_PAR05)  .Or. ;
		(SRA->RA_MAT      < MV_PAR06)  .Or. (SRA->RA_MAT      > MV_PAR07)
		SRA->(DBSkip())
		Loop
	EndIf
	
	//-------------------------------------
	//  Verifica Data Demissao          
	//-------------------------------------
	_cSitFunc := SRA->RA_SITFOLH
	_dDtPesqAf:= CTOD("01/" + Left(_cMesAnoRef,2) + "/" + Right(_cMesAnoRef,4),"DDMMYY")
	If _cSitFunc == "D" .And. (!Empty(SRA->RA_DEMISSA) .And. MesAno(SRA->RA_DEMISSA) > MesAno(_dDtPesqAf))
		_cSitFunc := " "
	EndIf
	
	//----------------------------------------------------------------
	//  Consiste situacao e categoria dos funcionarios			     |
	//----------------------------------------------------------------
	If !( _cSitFunc $ MV_PAR08) .Or.  ! ( SRA->RA_CATFUNC $ MV_PAR09)
		DBSkip()
		Loop
	EndIf
	If _cSitFunc $ "D" .And. Mesano(SRA->RA_DEMISSA) # Mesano(MV_PAR01)
		DBSkip()
		Loop
	EndIf
	
	//----------------------------------------------------------------
	//Consiste que o funcionário tem conta no banco do brasil
	//----------------------------------------------------------------
	If !( SubStr(AllTrim(SRA->RA_BCDEPSA),1,3) == '001' )
		DBSkip()
		Loop
	EndIf
	
	_aLanca  := {}
	_aProve  := {}
	_aDesco  := {}
	_aBases  := {}
	
	_cDataBas	:= ""
	_cDBaseAt	:= ""
	_cDFerias	:= ""
	_cDAbonPe	:= ""
	
	_nAteLim := _nBaseFgts := _nFgts := _nBaseIr := _nBaseIrFe := _nLiquido := 0.00
	
	//----------------------------------------------------------------
	//  Consiste controle de acessos e filiais validas		        |
	//----------------------------------------------------------------
	_cFilParam := fValidFil()  
	If Empty(_cFilParam)
	   _cFilParam := ""
	EndIf
	
	If !(SRA->RA_FILIAL $ _cFilParam) .Or. !Eval(_cAcessaSRA) // !(SRA->RA_FILIAL $ fValidFil()) .Or. !Eval(_cAcessaSRA)
		SRA->(DBSkip())
		Loop
	EndIf
	
	If SRA->RA_CODFUNC # _cFuncaoAnt           // Descricao da Funcao
		DescFun(Sra->Ra_Codfunc,Sra->Ra_Filial)
		_cFuncaoAnt := Sra->Ra_CodFunc
	EndIf
	
	If SRA->RA_CC # _cCcAnt                   // Centro de Custo
		DescCC(Sra->Ra_Cc,Sra->Ra_Filial)
		_cCcAnt := SRA->RA_CC
	EndIf
		
	_nTotvenc := 0
	
	SI3->(DBSeek( xFilial("SI3",SRA->RA_FILIAL)+SRA->RA_CC ))
	SRJ->(DBSeek( xFilial("SRJ",SRA->RA_FILIAL)+SRA->RA_CODFUNC ))
	SRH->(DBSeek( xFilial("SRH",SRA->RA_FILIAL)+SRA->RA_MAT ))
	
	If MV_PAR02 == 1 .Or. MV_PAR02 == 2
		_CROT := IIf(MV_PAR02==1,'ADI','FOL')
		DBSelectArea("SRC")
		If DBSeek(SRA->RA_FILIAL + SRA->RA_MAT)
			While !Eof() .And. SRC->RC_FILIAL+SRC->RC_MAT == SRA->RA_FILIAL+SRA->RA_MAT
				If !Eval(_cAcessaSRC) 
					DBSkip()
					Loop
				EndIf
				
				If  SRC->RC_ROTEIR != _CROT
		    
					SRC->(DBSkip())
					Loop
			    
				EndIf
	
				If (MV_PAR02 == 1) .And. (Src->Rc_Pd == _aCodFol[7,1])      // Desconto de Adto
					MGPE013S("P",_aCodFol[6,1],SRC->RC_HORAS,SRC->RC_VALOR)
					_nTOTVENC += Src->Rc_Valor
				ElseIf (MV_PAR02 == 1) .And. (Src->Rc_Pd == _aCodFol[12,1])
					MGPE013S("D",_aCodFol[9,1],SRC->RC_HORAS,SRC->RC_VALOR)
					_nTOTDESC += SRC->RC_VALOR
				ElseIf (MV_PAR02 == 1) .And. (Src->Rc_Pd == _aCodFol[8,1])
					MGPE013S("P",_aCodFol[8,1],SRC->RC_HORAS,SRC->RC_VALOR)
					_nTOTVENC += SRC->RC_VALOR
				Else
					If PosSrv( Src->Rc_Pd , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "1"
						If (MV_PAR02 #1) .Or. (MV_PAR02 == 1 .And. PosSrv(Src->Rc_Pd,Sra->Ra_Filial,"RV_ADIANTA") == "S")
							MGPE013S("P",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
							_nTOTVENC += Src->Rc_Valor
						EndIf
					ElseIf PosSrv( Src->Rc_Pd , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "2"
						If (MV_PAR02 #1) .Or. (MV_PAR02 == 1 .And. PosSrv(Src->Rc_Pd,Sra->Ra_Filial,"RV_ADIANTA") == "S")
							MGPE013S("D",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
							_nTOTDESC += Src->Rc_Valor
						EndIf
					ElseIf PosSrv( Src->Rc_Pd , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "3"
						If (MV_PAR02 #1) .Or. (MV_PAR02 == 1 .And. PosSrv(Src->Rc_Pd,Sra->Ra_Filial,"RV_ADIANTA") == "S")
							MGPE013S("B",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
						EndIf
					EndIf
				EndIf 
				If MV_PAR02 = 1
					If SRC->RC_PD == _aCodFol[10,1]
						_nBaseIr := SRC->RC_VALOR
					EndIf
				ElseIf SRC->RC_PD == _aCodFol[13,1]
					_nAteLim += SRC->RC_VALOR
				ElseIf SRC->RC_PD$ _aCodFol[108,1]+'*'+_aCodFol[17,1]
					_nBaseFgts += SRC->RC_VALOR
				ElseIf SRC->RC_PD$ _aCodFol[109,1]+'*'+_aCodFol[18,1]
					_nFgts += SRC->RC_VALOR
				ElseIf SRC->RC_PD == _aCodFol[15,1]
					_nBaseIr += SRC->RC_VALOR
				ElseIf SRC->RC_PD == _aCodFol[16,1]
					_nBaseIrFe += SRC->RC_VALOR
				ElseIf SRC->RC_PD == _aCodFol[47,1]
					_nLiquido := SRC->RC_VALOR
				EndIf
				DBSelectArea("SRC")
				DBSkip()
			EndDo
		
		Else
	
			_CROT := IIf(MV_PAR02==1,'ADI','FOL')
			_cdtref := AllTrim(Str(year(MV_PAR01))) + AllTrim(StrZero(MONTH(MV_PAR01),2))
		
			If SRD->(DBSeek(SRA->RA_FILIAL + SRA->RA_MAT + AllTrim(_cdtref)))
			
				While !(SRD->(Eof())) .And. SRD->RD_FILIAL+SRD->RD_MAT+SRD->RD_DATARQ == SRA->RA_FILIAL+SRA->RA_MAT+AllTrim(_cdtref)
					
					If  SRD->RD_ROTEIR != _CROT
			    
						SRD->(DBSkip())
						Loop
			    
					EndIf
				
					If (MV_PAR02 == 1) .And. (SRD->RD_Pd == _aCodFol[7,1])      // Desconto de Adto
						MGPE013S("P",_aCodFol[6,1],SRD->RD_HORAS,SRD->RD_VALOR)
						_nTOTVENC += SRD->RD_Valor
					ElseIf (MV_PAR02 == 1) .And. (SRD->RD_Pd == _aCodFol[12,1])
						MGPE013S("D",_aCodFol[9,1],SRD->RD_HORAS,SRD->RD_VALOR)
						_nTOTDESC += SRD->RD_VALOR
					ElseIf (MV_PAR02 == 1) .And. (SRD->RD_Pd == _aCodFol[8,1])
						MGPE013S("P",_aCodFol[8,1],SRD->RD_HORAS,SRD->RD_VALOR)
						_nTOTVENC += SRD->RD_VALOR
					Else
					
						If PosSrv( SRD->RD_Pd , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "1"
							If (MV_PAR02 #1) .Or. (MV_PAR02 == 1 .And. PosSrv(SRD->RD_Pd,Sra->Ra_Filial,"RV_ADIANTA") == "S")
								MGPE013S("P",SRD->RD_PD,SRD->RD_HORAS,SRD->RD_VALOR)
								_nTOTVENC += SRD->RD_Valor
							EndIf
						ElseIf PosSrv( SRD->RD_Pd , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "2"
							If (MV_PAR02 #1) .Or. (MV_PAR02 == 1 .And. PosSrv(SRD->RD_Pd,Sra->Ra_Filial,"RV_ADIANTA") == "S")
								MGPE013S("D",SRD->RD_PD,SRD->RD_HORAS,SRD->RD_VALOR)
								_nTOTDESC += SRD->RD_Valor
							EndIf
						ElseIf PosSrv( SRD->RD_Pd , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "3"
							If (MV_PAR02 #1) .Or. (MV_PAR02 == 1 .And. PosSrv(SRD->RD_Pd,Sra->Ra_Filial,"RV_ADIANTA") == "S")
								MGPE013S("B",SRD->RD_PD,SRD->RD_HORAS,SRD->RD_VALOR)
							EndIf
						EndIf
					EndIf 
					If MV_PAR02 = 1
						If SRD->RD_PD == _aCodFol[10,1]
							_nBaseIr := SRD->RD_VALOR
						EndIf
					ElseIf SRD->RD_PD == _aCodFol[13,1]
						_nAteLim += SRD->RD_VALOR
					ElseIf SRD->RD_PD$ _aCodFol[108,1]+'*'+_aCodFol[17,1]
						_nBaseFgts += SRD->RD_VALOR
					ElseIf SRD->RD_PD$ _aCodFol[109,1]+'*'+_aCodFol[18,1]
						_nFgts += SRD->RD_VALOR
					ElseIf SRD->RD_PD == _aCodFol[15,1]
						_nBaseIr += SRD->RD_VALOR
					ElseIf SRD->RD_PD == _aCodFol[16,1]
						_nBaseIrFe += SRD->RD_VALOR
					ElseIf SRD->RD_PD == _aCodFol[47,1]
						_nLiquido := SRD->RD_VALOR
					EndIf
					DBSelectArea("SRD")
					DBSkip()
				EndDo
			EndIf
		
		EndIf
	
	ElseIf MV_PAR02 == 3 
		DBSelectArea("SRC")
		If DBSeek(SRA->RA_FILIAL + SRA->RA_MAT)
			While !Eof() .And. SRA->RA_FILIAL + SRA->RA_MAT == SRC->RC_FILIAL + SRC->RC_MAT
				If !Eval(_cAcessaSRC) .Or. AllTrim(SRC->RC_ROTEIR) != '131'
					DBSkip()
					Loop
				EndIf
				If SRC->RC_PD == _aCodFol[22,1]
					MGPE013S("P",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
					_nTOTVENC += SRC->RC_VALOR
				ElseIf SRC->RC_PD == _aCodFol[172,1]
					MGPE013S("D",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
					_nTOTDESC += SRC->RC_VALOR
				ElseIf SRC->RC_PD == _aCodFol[108,1] .Or. SRC->RC_PD == _aCodFol[109,1] .Or. SRC->RC_PD == _aCodFol[173,1]
					MGPE013S("B",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
				EndIf
				
				If SRC->RC_PD == _aCodFol[108,1]
					_nBaseFgts := SRC->RC_VALOR
				ElseIf SRC->RC_PD == _aCodFol[109,1]
					_nFgts     := SRC->RC_VALOR
				EndIf
				DBSelectArea("SRC")
				DBSkip()
			EndDo
			_nLiquido := _nTOTVENC - _nTOTDESC
		EndIf
	ElseIf MV_PAR02 == 4
		DBSelectArea("SRC")
		DBSetOrder(2)
		If DBSeek(SRA->RA_FILIAL + SRA->RA_CC + SRA->RA_MAT)
			While !Eof() .And. SRA->RA_FILIAL + SRA->RA_CC + SRA->RA_MAT == SRC->RC_FILIAL + SRC->RC_CC + SRC->RC_MAT
				If !Eval(_cAcessaSRC) .Or. AllTrim(SRC->RC_ROTEIR) != '132'
					DBSkip()
					Loop
				EndIf
				If PosSrv( SRC->RC_PD , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "1"
					MGPE013S("P",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
					_nTOTVENC = _nTOTVENC + SRC->RC_VALOR
				ElseIf PosSrv( SRC->RC_PD , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "2"
					MGPE013S("D",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
					_nTOTDESC = _nTOTDESC + SRC->RC_VALOR
				ElseIf PosSrv( SRC->RC_PD , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "3"
					MGPE013S("B",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
				EndIf
				
				If SRC->RC_PD == _aCodFol[19,1]
					_nAteLim += SRC->RC_VALOR
				ElseIf SRC->RC_PD$ _aCodFol[108,1]
					_nBaseFgts += SRC->RC_VALOR
				ElseIf SRC->RC_PD$ _aCodFol[109,1]
					_nFgts += SRC->RC_VALOR
				ElseIf SRC->RC_PD == _aCodFol[27,1]
					_nBaseIr += SRC->RC_VALOR
				ElseIf SRC->RC_PD == _aCodFol[21,1]
					_nLiquido := SRC->RC_VALOR
				EndIf
				DBSkip()
			EndDo
		EndIf
	ElseIf MV_PAR02 == 5
		DBSelectArea("SR1")
		DBSetOrder(1)
		If DBSeek( SRA->RA_FILIAL + SRA->RA_MAT )
			While !Eof() .And. SRA->RA_FILIAL + SRA->RA_MAT ==	SR1->R1_FILIAL + SR1->R1_MAT
				If !Eval(_cAcessaSR1)
					DBSkip()
					Loop
				EndIf
				If PosSrv( SR1->R1_PD , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "1"
					MGPE013S("P",SR1->R1_PD,SR1->R1_HORAS,SR1->R1_VALOR)
					_nTOTVENC = _nTOTVENC + SR1->R1_VALOR
				ElseIf PosSrv( SR1->R1_PD , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "2"
					MGPE013S("D",SR1->R1_PD,SR1->R1_HORAS,SR1->R1_VALOR)
					_nTOTDESC = _nTOTDESC + SR1->R1_VALOR
				ElseIf PosSrv( SR1->R1_PD , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "3"
					MGPE013S("B",SR1->R1_PD,SR1->R1_HORAS,SR1->R1_VALOR)
				EndIf
				DBSkip()
			EndDo
			_nLiquido := _nTOTVENC - _nTOTDESC
		EndIf
	EndIf
	
	DBSelectArea("SRA")
	
	If _nTOTVENC == 0 .And. _nTOTDESC == 0
		SRA->(DBSkip())
		Loop
	EndIf
	
	_cDataBas	:= DToC(SRH->RH_DATABAS)
	_cDBaseAt	:= DToC(SRH->RH_DBASEAT)
	_cDFerias	:= Str(SRH->RH_DFERIAS)
	_cDAbonPe	:= Str(SRH->RH_DABONPE)

	_cTextoMsg := "" 
	
	//Há dados a ser informado
	If _lData
	
		//Verifica Header
		If !_lHeader
	
				//pega número sequencial do rcc
				DBSelectArea('RCC')
				RCC->( DBGoTo(_nrecno) )
								
	
				// Monta Header de Arquivo - Visao 1
				_cLin := Replicate("0",20)									//01-20 preencher com zeros(000:.0)
				_cLin += "00"													//21-22 preencher com zeros (00)
				_cLin += "0"			 										//23-23 preencher com zero
				_cLin += StrZero((Val(SubStr(RCC_CONTEU,24,4))),4)				//24-27 prefixo da agência do BB, sem DV
				_cLin += StrZero((Val(SubStr(RCC_CONTEU,30,12))),11)		//28-38 num. da conta da empresa no BB, sem DV    
				_cLin += "EDO001"												//39-44 preencher com EDO001
				_cLin += StrZero((Val(SubStr(RCC_CONTEU,1,20))),12)		//45-56 número do contrato, atribuído pelo EDO
				_cLin += StrZero((Val(SubStr(RCC_CONTEU,43,6))+1),6)		//57-62 número seqüencial da remessa
				_cLin += "00315"												//63-67 código do   produto  - 00315
				_cLin += "00001"												//68-72 código da modalidade - 00001
				_cLin += Transf(Year(MV_PAR01),'9999')						//73-76 ano a que se refere o documento
				_cLin += StrZero(Month(MV_PAR01),2)						//77-78 mês a que se refere o documento
				_cLin += "00"													//79-80 número seqüencial de extraordinariedade
				_cLin += MGPE013D(MV_PAR10,"DDMMAAAA")						//81-88 data (ddmmaaaa) referente ao crédito
				_cLin += Space(12)											//89-100 preencher com brancos
				_cLin += CHR(13)+CHR(10)
				
				MGPE013G()
				
				
				MGPE013Z(StrZero((Val(SubStr(RCC_CONTEU,43,6))+1),6)) //Atualiza sequencia no RCC
				
				
				_lHeader := .T.

		EndIf
		
		//Dados do Funcionario - Visao 2
		If _nLiquido == 0
			_nLiquido := _nTOTVENC-_nTOTDESC
		EndIf

        _cCodBco   := Subs(SRA->RA_BCDEPSA,1,3)

        _cCodAgenc := AllTrim(Subs(SRA->RA_BCDEPSA,4,5))

        _cCodContaC := AllTrim(SRA->RA_CTDEPSA)
        
        _lGravouArqTxt := .F.
        
        If _cCodBco == "001" .And. Len(_cCodAgenc) >= 5 .And. Len(_cCodContaC) >= 5
		   _cLin := StrZero(Val(SRA->RA_MAT),20)							//01-20 identificador do destinatário empresa
		   _cLin += "00"													//21-22 preencher com números zeros (00)
		   _cLin += "1"														//23-23 preencher com o número 1
		   _cLin += Subs(SRA->RA_BCDEPSA,4,4)								//24-27 prefixo da agência do BB, sem DV
		   _cLin += StrZero(Val(Left(AllTrim(SRA->RA_CTDEPSA),Len(AllTrim(SRA->RA_CTDEPSA))-1)),11)		//28-38 conta BB do destinatário no BB, sem DV
		   _cLin += StrZero(Len(_aLanca)+11,2)								//39-40 quantidade de linhas do texto
		   _cLin += Left(SRA->RA_NOME + Space(40),40)						//41-80 nome do destinatário
		   _cLin += StrZero(Val(SRA->RA_CIC),11)							//81-91 CPF do destinatário
		   _cLin += Space(09)											   	//92-100 preencher com brancos
		   _cLin += CHR(13)+CHR(10)

		   MGPE013G()
		   _nQtFunc++
		
		   // Monta Header de Lote - Registro Tipo "3" Segmento "E" --> Proventos
		   MGPE0133()
			
		   //Verifica Liquidos
		   If _nLiquido == 0
			  _nLiquido := _nTOTVENC-_nTOTDESC
		   EndIf
			
		   If MV_PAR02 <> 6
			  // Verifica Iconsistencias de Liquidos
			  _lliq := .T.
			  If _nLiquido != (_nTotVenc - _nTotDesc)
		         _lLiq := .F.
			  EndIf
		   Else
			  _lliq := .T.
		   EndIf
		   _lGravouArqTxt := .T.
		   
        Else
           _lLiq := .F. 
           _lGravouArqTxt := .F. 
        EndIf

	    If _lGravouArqTxt 
	       _cTextoMsg := "SUCESSO NA GRAVAÇÃO DO ARQUIVO DE ENVIO. "
	    Else
	       _cTextoMsg := "NÃO FOI POSSÍVEL GRAVAR ARQUIVO DE ENVIO. PROBLEMAS COM:" 
	       If _cCodBco <> "001" 
	          _cTextoMsg += " CODIGO DO BANCO INVÁLIDO. "
	       EndIf
	    
	       If Len(_cCodAgenc) < 5 
	          _cTextoMsg += " NUMERO DA AGENCIA INVÁLIDO. "
	       EndIf
	    
	       If Len(_cCodContaC) < 5
	          _cTextoMsg += " NUMERO DA CONTA CORRENTE INVÁLIDO. "
	       EndIf
	    EndIf
	EndIf
	
	aAdd(_aresults,{cfilant,DescCC(Sra->Ra_Cc,Sra->Ra_Filial),SRA->RA_MAT,SubStr(SRA->RA_NOME,1,30),Transform(_nTotvenc,"@E 9999999.99"),Transform(_nTotdesc,"@E 9999999.99"),;
			Transform(_nLiquido,"@E 9999999.99"),Transform(SRA->RA_SALARIO,"@E 9999999.99"),IIf(_lliq,"OK","INCONSISTENTE"),_cTextoMsg})
			
	_nTotais := _nTotais + _nLiquido
	
	
	DBSelectArea("SRA")

	DBSkip()
	_nTOTDESC := _nTOTVENC := 0
EndDo

If _nQtFunc > 0

    aAdd(_aresults,{cfilant,"Totais da Filial:","   ",StrZero(_nQtFunc,6) + " funcionários","Conta pagadora: " + _cagencia + " - " + _cconta + "/" + _cdigito ,;
							" "," ",Transform(_nTotais,"@E 9999999.99")," ", "GRAVADO NO ARQUIVO DE ENVIO COM SUCESSO."})

EndIf
							
_nTotais := 0


//Ha Dados a Serem Gerados
If _lData
	
	_cLin := Replicate("9",20)	//01-20 preencher com números Nove (999:.9)
	_cLin += "99"				//21-22 preencher com números Nove (99)
	_cLin += "9"					//23-23 preencher com o número Nove (9)
	_cLin += Replicate("9",15)	//24-38 preencher com números Nove (999:.9)
	_cLin += StrZero(_nQtFunc,11)	//39-49 quantidade de destinatários do arquivo
	_cLin += Space(51)			//50-100 preencher com brancos
	_cLin += CHR(13)+CHR(10)

	MGPE013G()
		
EndIf



//----------------------------------------------------------------
//  Termino do relatorio                                          
//----------------------------------------------------------------
DBSelectArea("SRC")
DBSetOrder(1)          // Retorno a ordem 1
DBSelectArea("SRC")
DBSetOrder(1)          // Retorno a ordem 1
DBSelectArea("SRA")
SET FILTER TO

FClose( _nHdl )
If !(Type("MV_PAR03") == "U")
	fErase(AllTrim(MV_PAR03) + OrdBagExt())
EndIf


Return

/*
===============================================================================================================================
Programa----------: MGPE013S
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/08/2015
Descrição---------: Somar as Verbas no Array  
Parametros--------: 	_cTipo - P provento, D desconto, B base
						_Verba - Verba
						_nHoras - quantidade de horas
						_nValor - valor da verba
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE013S(_cTipo,_cPd,_nHoras,_nValor)

Local _cDesc_paga

_lData	:= .T.  //Há Dados a serem informados

_cDesc_paga := DescPd(_cPd,Sra->Ra_Filial)  // mostra como pagto

If _cTipo #'B'
	//--Array para Recibo Pre-Impresso
	nPos := aScan(_aLanca,{ |X| X[2] = _cPd })
	If nPos == 0
		aAdd(_aLanca,{_cTipo,_cPd,_cDesc_Paga,_nHoras,_nValor})
	Else
		_aLanca[nPos,4] += _nHoras
		_aLanca[nPos,5] += _nValor
	EndIf
EndIf

//--Array para o Recibo Pre-Impresso
If _cTipo = 'P'
	_cArray := "_aProve"
ElseIf _cTipo = 'D'
	_cArray := "_aDesco"
ElseIf _cTipo = 'B'
	_cArray := "_aBases"
EndIf

nPos := aScan(&_cArray,{ |X| X[1] = _cPd })
If nPos == 0
	aAdd(&_cArray,{_cPd+" "+left(_cDesc_Paga,19),_nHoras,_nValor })
Else
	&_cArray[nPos,2] += _nHoras
	&_cArray[nPos,3] += _nValor
EndIf

Return

/*
===============================================================================================================================
Programa----------: MGPE013D
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/08/2015
Descrição---------: Converte datas
Parametros--------: 	dData - Data a ser convertida
						_xTipo - Mascara de conversão
Retorno-----------: cret - string com data convertida
===============================================================================================================================
*/
Static Function MGPE013D( dData, _xTipo )

Local _cRet := Space(08)

If _xTipo == "DDMMAAAA"
	_cRet := StrZero(Day(dData),2) + StrZero(Month(dData),2) + StrZero(Year(dData),4)
ElseIf _xTipo == "MMAAAA"
	_cRet := StrZero(Month(dData),2) + StrZero(Year(dData),4)
EndIf


Return( _cRet )


/*
===============================================================================================================================
Programa----------: MGPE0133
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/08/2015
Descrição---------: Dados das Verbas - Visao 3   
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
Static Function MGPE0133()

Local _nI, _nLen, _cVrb, _nProv, _nDesc, _nLiq, _nSeq
                                 
_nProv := _nDesc := _nLiq := 0
_nSeq  := 1

//Imprime cabecalho
	_cLin := StrZero(Val(SRA->RA_MAT),20)		//01-20 identificador do destinatário empresa
	_cLin += StrZero(_nSeq,2)						//21-22 seqüencial da linha do texto
	_cLin += "2"									//23-23 preencher com o número 2
	_cLin += "EMPRESA: GOIASMINAS  - CNPJ: " + Transform(_cDesc_CGC,'@R! NN.NNN.NNN/NNNN-99') + " 1" + Space(28) + CHR(13)+CHR(10)
	MGPE013G()
    _nSeq++

	_cLin := StrZero(Val(SRA->RA_MAT),20)		//01-20 identificador do destinatário empresa
	_cLin += StrZero(_nSeq,2)						//21-22 seqüencial da linha do texto
	_cLin += "2"									//23-23 preencher com o número 2
	_cLin += StrZero(Val(SRA->RA_MAT),6) + " - " + SRA->RA_NOME + Space(9) + "0" + Space(28) + CHR(13)+CHR(10)
	MGPE013G()
    _nSeq++

	_cLin := StrZero(Val(SRA->RA_MAT),20)		//01-20 identificador do destinatário empresa
	_cLin += StrZero(_nSeq,2)						//21-22 seqüencial da linha do texto
	_cLin += "2"									//23-23 preencher com o número 2
	_cLin += "FUNCAO: " + StrZero(Val(SRA->RA_CODFUNC),5) + " - " + Left(SRJ->RJ_DESC+Space(30),30) + Space(2) + "0" + Space(28) + CHR(13)+CHR(10)
	MGPE013G()
    _nSeq++

	_cLin := StrZero(Val(SRA->RA_MAT),20)		//01-20 identificador do destinatário empresa
	_cLin += StrZero(_nSeq,2)						//21-22 seqüencial da linha do texto
	_cLin += "2"									//23-23 preencher com o número 2
	_cLin += "COMPETENCIA: " + StrZero(month(MV_PAR01),2) + "/" + StrZero(year(MV_PAR01),4) + Space(28) + "1" + Space(28) + CHR(13)+CHR(10)
	MGPE013G()
    _nSeq++

// Calcula Quantidade de Proventos
_nLen := Len(_aLanca)

If _nLen == 0
	Return
EndIf

// Processa Array
For _nI := 1 To _nLen

    //Monta inicio da linha texto
	_cLin := StrZero(Val(SRA->RA_MAT),20)		//01-20 identificador do destinatário empresa
	_cLin += StrZero(_nSeq,2)						//21-22 seqüencial da linha do texto
	_cLin += "2"									//23-23 preencher com o número 2

	_cVrb  := IIf(_aLanca[_nI][1] == "P", "PRO" , "DES")

    //Se encontrou a primeira ocorrencia de desconto, imprime total de proventos
    If _cVrb == "DES" .And. _nDesc == 0
		_cLin += "TOTAL DE PROVENTOS:      "
		_cLin += Transform(_nProv, '@E 999,999,999.99')
		_cLin += Space(9)
		_cLin += "1"
		_cLin += Space(28)
		_cLin += CHR(13)+CHR(10)
		MGPE013G()
        _nSeq++
		_cLin := StrZero(Val(SRA->RA_MAT),20)		//01-20 identificador do destinatário empresa
		_cLin += StrZero(_nSeq,2)						//21-22 seqüencial da linha do texto
		_cLin += "2"									//23-23 preencher com o número 2
    EndIf
	
	_nProv += IIf(_aLanca[_nI][1] == "P", _aLanca[_nI][5] , 0 )
	_nDesc += IIf(_aLanca[_nI][1] == "D", _aLanca[_nI][5] , 0 )
	_cLin += _cVrb + Space(1)										//24-27 Tipo (pro,des,bas)
	_cLin += _aLanca[_nI][2]+Space(1)								//28-31 Codigo da verba
	_cLin += Left(_aLanca[_nI][3],20)+Space(1)						//32-52 Descricao da verba
	_cLin += Transform(_aLanca[_nI][4], '@E 999.99')+Space(1) 		//53-58 Horas do Lancamento
	_cLin += Transform(_aLanca[_nI][5], '@E 9999,999.99')+Space(1) 	//60-70 Horas do Lancamento
	_cLin += "0"													//72-72 "1"-para saltar uma linha de intervalo/"0"-para linhas corridas
	_cLin += Space(28)											//73-100 preencher com brancos
	_cLin += CHR(13)+CHR(10)
	MGPE013G()
    _nSeq++

Next

//imprime total de descontos
_cLin := StrZero(Val(SRA->RA_MAT),20)		//01-20 identificador do destinatário empresa
_cLin += StrZero(_nSeq,2)						//21-22 seqüencial da linha do texto
_cLin += "2"									//23-23 preencher com o número 2
_cLin += "TOTAL DE DESCONTOS:      "
_cLin += Transform(_nDesc, '@E 999,999,999.99')
_cLin += Space(9)
_cLin += "1"
_cLin += Space(28)
_cLin += CHR(13)+CHR(10)
MGPE013G()
_nSeq++
	
//Imprime total liquido
_cLin := StrZero(Val(SRA->RA_MAT),20)		//01-20 identificador do destinatário empresa
_cLin += StrZero(_nSeq,2)						//21-22 seqüencial da linha do texto
_cLin += "2"									//23-23 preencher com o número 2
_nLiq := _nProv - _nDesc
_cLin += "TOTAL LIQUIDO A RECEBER: "
_cLin += Transform(_nLiq, '@E 999,999,999.99')
_cLin += Space(09)
_cLin += "1"
_cLin += Space(28)
_cLin += CHR(13)+CHR(10)
MGPE013G()
_nSeq++

//Imprime base FGTS
_cLin := StrZero(Val(SRA->RA_MAT),20)		//01-20 identificador do destinatário empresa
_cLin += StrZero(_nSeq,2)						//21-22 seqüencial da linha do texto
_cLin += "2"									//23-23 preencher com o número 2
_cLin += "BASE FGTS: "
_cLin += Transform(_nBaseFgts, '@E 999,999,999.99')
_cLin += Space(23)
_cLin += "0"
_cLin += Space(28)
_cLin += CHR(13)+CHR(10)
MGPE013G()
_nSeq++

//Imprime FGTS MES
_cLin := StrZero(Val(SRA->RA_MAT),20)		//01-20 identificador do destinatário empresa
_cLin += StrZero(_nSeq,2)						//21-22 seqüencial da linha do texto
_cLin += "2"									//23-23 preencher com o número 2
_cLin += "FGTS MES.: "
_cLin += Transform(_nFgts, '@E 999,999,999.99')
_cLin += Space(23)
_cLin += "0"
_cLin += Space(28)
_cLin += CHR(13)+CHR(10)
MGPE013G()
_nSeq++

//Imprime Base INSS
_cLin := StrZero(Val(SRA->RA_MAT),20)		//01-20 identificador do destinatário empresa
_cLin += StrZero(_nSeq,2)						//21-22 seqüencial da linha do texto
_cLin += "2"									//23-23 preencher com o número 2
_cLin += "BASE INSS: "
_cLin += Transform(_nAteLim, '@E 999,999,999.99')
_cLin += Space(23)
_cLin += "0"
_cLin += Space(28)
_cLin += CHR(13)+CHR(10)
MGPE013G()
_nSeq++

//Imprime base IR
_cLin := StrZero(Val(SRA->RA_MAT),20)		//01-20 identificador do destinatário empresa
_cLin += StrZero(_nSeq,2)						//21-22 seqüencial da linha do texto
_cLin += "2"									//23-23 preencher com o número 2
_cLin += "BASE IR..: "
_cLin += Transform(_nBaseIr, '@E 999,999,999.99')
_cLin += Space(23)
_cLin += "0"
_cLin += Space(28)
_cLin += CHR(13)+CHR(10)
MGPE013G()
_nSeq++

Return

/*
===============================================================================================================================
Programa----------: MGPE013G
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/08/2015
Descrição---------: Grava linha no arquivo  
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/
Static Function MGPE013G()

If FWrite(_nHdl,_cLin,Len(_cLin)) != Len(_cLin)
	MsgAlert("Ocorreu um erro na gravacao do arquivo. Continua?","Atencao!")
EndIf

Return

/*
===============================================================================================================================
Programa----------: MGPE013C
Autor-------------: Josué Danich Prestes 
Data da Criacao---: 13/08/2015
Descrição---------: Rotina para abrir consulta de contratos de cnab
Parametros--------: Nenhum
Retorno-----------: Sempre .T.
===============================================================================================================================
*/
User Function MGPE013C()

Local _cRet		:= ''
Local _cQuery	:= ''
Local _cAlias	:= GetNextAlias()
Local _cTitAux	:= 'Contratos/Contas - Banco do Brasil'
Local _aDados	:= {}
Local _nconta	:= 0
Local _nI		:= 0
		
_cQuery := " SELECT SubStr( RCC.RCC_CONTEU , 21 , 3 )	AS BANCO," 
_cQuery += " LPAD(TRIM(SubStr( RCC.RCC_CONTEU , 1 , 20 )),12,'0') 	AS CONTRATO," 
_cQuery += " LPAD(TRIM(SubStr( RCC.RCC_CONTEU , 24 , 4 )),4,'0')	AS AGENCIA," 
_cQuery += " LPAD(TRIM(SubStr( RCC.RCC_CONTEU , 30 , 11 )),11,'0')	AS CONTA,"
_cQuery += " TRIM(SubStr( RCC.RCC_CONTEU , 42 , 1 ))	AS DIGITO,"
_cQuery += " LPAD(TRIM(SubStr( RCC.RCC_CONTEU , 43 , 6 )),6,'0')	AS SEQUENCIA,"
_cQuery += " R_E_C_N_O_ AS NUM"
_cQuery += " FROM "+ RetSqlName("RCC") + " RCC"
_cQuery += " WHERE RCC.RCC_FILIAL = '" + xFilial("RCC") + "'"
_cQuery += " AND D_E_L_E_T_		= ' ' AND SubStr( RCC.RCC_CONTEU , 21 , 3 ) = '001'"
_cQuery += " AND   RCC.RCC_CODIGO	= 'S052'"
		
		
If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TCGenQry(,,_cQuery) , _cAlias , .F. , .T. )

DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )
While (_cAlias)->( !Eof() )

	
	aAdd( _aDados , { .F. ,  AllTrim((_cAlias)->CONTRATO)+"/"+ AllTrim((_cAlias)->SEQUENCIA)+"/"+ AllTrim(Str((_cAlias)->NUM)) } )
	
	(_cAlias)->( DBSkip() )

EndDo

(_cAlias)->( DBCloseArea() )

If U_ITListBox( _cTitAux , { '__' ,  'Contrato/Sequência/Registro'  } , @_aDados , .F. , 2 , 'Selecione o contrato: ' )

	
	For _nI := 1 To Len( _aDados )
		
		If _aDados[_nI][01]
			
			_nconta++
			
			If _nconta > 1
			 
			  alert("Selecione apenas uma conta!")
			  Return .T.
			 
			 Else
			 
				_cRet += _aDados[_nI][02] +';'
			
			EndIf
			
		EndIf
		
	Next _nI
	
	&( ReadVar() ) := SubStr( _cRet , 1 , Len(_cRet) - 1 )

EndIf

Return( .T. )


Static Function MGPE013Z(_csequen)

//Grava nova sequência do banco para todos os registros do banco do brasil

RCC->(DBSetOrder(1))
If RCC->(DBSeek(xFilial("RCC")+"S052"))
		
	While !(RCC->(Eof())) .And. RCC->RCC_FILIAL == xFilial("RCC") .And. RCC->RCC_CODIGO = "S052" 
			
		  If SubStr(RCC->RCC_CONTEU,21,3) == "001"

		  		RecLock( 'RCC' , .F. )
			
		  		RCC->RCC_CONTEU		:= SubStr(RCC->RCC_CONTEU,1,42) + StrZero((Val(_csequen)),6)
			
		  		RCC->( MSUnLock() )
		  				
		  EndIf
		  	
		  RCC->(DBSkip())
		  
	EndDo
	
EndIf

Return
