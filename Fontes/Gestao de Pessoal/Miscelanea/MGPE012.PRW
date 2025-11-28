/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |17/09/2019| Chamado 28346. Retirada chamada da função itputx1.
Lucas Borges  |26/09/2019| Chamado 28346. Revisão de fontes.
Alex Wallauer |31/07/2020| Chamado 33590. Sequencia zerada por filial/arquivo agora
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGPE012
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/08/2015
Descrição---------: Geracao Arquivo de Recibos de Pagamento - Itau	
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE012()

Local _nOpca	:= 0
Local _aSays	:={ }
Local _aButtons	:= { } //<== arrays locais de preferencia
Local _cPerg	:= "MGPE012"
Local oproc
Local _afils	:= {}
Local _nI		:= 0

Private _cFilSRA	:= ""  
Private _nSeqFun	:= 0
Private _afiliais	:= {}
Private _cagencia
Private _cconta
Private _cdigito
Private _aresults	:= {}
Private _ngravados	:= 0
Private _ntotais	:= 0
Private _cagenciam	:= ""
Private _ccontam	:= ""
Private _ccnpjm		:= ""
Private _cagenciau	:= ""
Private _cdigitou	:= ""
Private _ccontau	:= ""
Private _csequ		:= ""

cCadastro := OemToAnsi("Exportacao de Hollerith Itau") 

Pergunte(_cPerg,.F.)
   
aAdd(_aSays,OemToAnsi(" Este programa Gera o Arquivo de Holerite Eletronico Itau" ) ) 

aAdd(_aButtons, { 17,.T.,{|| _cFilSRA := BuildExpr("SRA",,_cFilSRA) } } )
aAdd(_aButtons, { 5,.T.,{|| Pergunte(_cPerg,.T. ) } } )
aAdd(_aButtons, { 1,.T.,{|o| _nOpca := 1,FechaBatch() }} )
aAdd(_aButtons, { 2,.T.,{|o| FechaBatch() }} )

//----------------------------------------------------------------
// Pega dados da matriz para usar em filiais que tem o mesmo 
// contrato
//----------------------------------------------------------------
_lachou := .F.
RCC->(DBSetOrder(1))
If RCC->(DBSeek(xFilial("RCC")+"S052"+'01'))
		
	While !(RCC->(Eof())) .And. RCC->RCC_FILIAL == xFilial("RCC") .And. RCC->RCC_CODIGO = "S052" .And. RCC->RCC_FIL = '01'
			
			  If SubStr(RCC->RCC_CONTEU,21,3) == "341"
			  
			  	SM0->(DBSeek('01' + '01'))
			  	_lachou := .T.
			  	_cagenciam := AllTrim(SubStr(RCC->RCC_CONTEU,24,5))
			  	_ccontam := AllTrim(SubStr(RCC->RCC_CONTEU,30,12))
			  	_ccnpjm := StrZero(Val(SM0->M0_CGC),14)
			  	SM0->(DBSeek('01' + cfilant))
			  				  	
			  	Exit
			  	
			  EndIf
			  
			  RCC->(DBSkip())
	EndDo
	
EndIf

If !_lachou

	U_ITMsg("Não foram localizados dados bancarios da matriz","Atenção",,1)
	
	Return
	
EndIf


	
FormBatch( cCadastro, _aSays, _aButtons )

//----------------------------------------------------------------
// Variaveis utilizadas para parametros                         
//----------------------------------------------------------------
If _nOpca == 1

	//Grava log de utilização
	u_itlogacs()

	//Roda Loop de filiais
	If Empty(MV_PAR14)
	
		_cfilloc := cfilant
		
		SM0->(DBGoTop())
		
		While !(SM0->(Eof()))
		
			aAdd(_afils,AllTrim(SM0->M0_CODFIL))
			SM0->(DBSkip())
		
		EndDo
		SM0->(DBSeek('01' + cfilant))
	
	Else
	
		_afils := StrTokArr(MV_PAR14,";")
		_cfilloc := cfilant
		
	EndIf
	
	For _nI := 1 to Len(_afils)
	
		cfilant := _afils[_nI]

		//Pega parâmetro com dados da agencia, conta/digito pagadora
		_lachou := .F.
		RCC->(DBSetOrder(1))
		If RCC->(DBSeek(xFilial("RCC")+"S052"+cfilant))
		
			While !(RCC->(Eof())) .And. RCC->RCC_FILIAL == xFilial("RCC") .And. RCC->RCC_CODIGO = "S052" .And. RCC->RCC_FIL = cfilant
			
			  If SubStr(RCC->RCC_CONTEU,21,3) == "341"
			  
			  	_lachou := .T.
			  	_cagencia := AllTrim(SubStr(RCC->RCC_CONTEU,24,5))
			  	_cconta := AllTrim(SubStr(RCC->RCC_CONTEU,30,12))
			  	_cdigito := AllTrim(SubStr(RCC->RCC_CONTEU,42,1))
			  	_cseq := AllTrim(SubStr(RCC->RCC_CONTEU,44,6))
			  	Exit
			  	
			  EndIf
			  
			  RCC->(DBSkip())
			  
			EndDo
			
		EndIf

		_ngravados := 0
		_nSeqfun := 0
		
		If SM0->(DBSeek('01' + cfilant)) .And. _lachou
		
			If !(_cagencia == _cagenciau .And. _cconta == _ccontau .And. _cdigito == _cdigitou .And. _cseq == _csequ)
			
				_npos := aScan(_afiliais,{|_vAux|_vAux[1]==_cagencia .And. _vAux[2]==_cconta .And. _vAux[3]==_cdigito .And. _vAux[4] == _cseq })  
				
			 	If _npos == 0
			 	
			 		_nSeqFun := 0
			 		aAdd(_afiliais,{_cagencia,_cconta,_cdigito,_cseq,0})
			 		_npos := Len(_afiliais)
			 		
			 	Else
			 	
			 		_nSeqfun := 0
			 		
			 	EndIf
			 	
			 EndIf
			 
		
			FWMsgRun(,{|oproc| MGPE012P(oproc)},"Geracao do Arquivo Holerite","Processando dados...")  
			
			_afiliais[_npos,5] := _nSeqFun
			_cagenciau := _cagencia
			_ccontau := _cconta
			_cdigitou := _cdigito
			_csequ := _cseq
			
		Else
		
			U_ITMsg("Dados bancarios ou filial " + cfilant + " não encontrados","Atenção","Registros dessa filial não serão processados",1)
		
		EndIf
		
	Next
	
	cfilant := _cfilloc
	SM0->(DBSeek('01' + cfilant))
	
	If Len(_aresults) > 0
		//Apresenta resultados da gravação
		U_ITListBox( 'Dados gravados nos arquivos' , {"Filial","CC","Matricula","Nome","Funcao","Vencimentos","Descontos","Liquido","Salário"} , _aresults , .T. , 1 )
	
		U_ITMsg("Arquivos Gerado com no Diretorio : " + MV_PAR04, "Processo Concluído",,2 )
	
	Else

		U_ITMsg("Não foram gerados arquivos!","Atenção",,1 )

	EndIf
EndIf

Return

/*
===============================================================================================================================
Programa----------: MGPE012P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/08/2015
Descrição---------: Gera o arquivo texto   
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE012P(oproc)

//----------------------------------------------------------------
// Define Variaveis Locais (Programa)                           
//----------------------------------------------------------------
Local _cMesAnoRef, _cAnoMesRef, _cMesArqRef, cArqNtx
Local _aOrdBag     := {}
Local _cArqMov     := ""
Local _cAcessaSR1  := &("{ || " + ChkRH("GPER030","SR1","2") + "}")
Local _cAcessaSRA  := &("{ || " + ChkRH("GPER030","SRA","2") + "}")
Local _cAcessaSRC  := &("{ || " + ChkRH("GPER030","SRC","2") + "}")
Local _cInicio, _cFim 
Local _cDesc_Fil := "" 
Local _cDesc_Red := ""
Local _cDesc_End := ""
Local _cCcAnt     := Space(9)
Local _nconta := 0
Local _npos := 1



//----------------------------------------------------------------
// Define Variaveis Private(Basicas)                            
//----------------------------------------------------------------
Private  _cAliasMov   := ""
Private _nAteLim := 0
Private  _nBaseFgts := 0 
Private  _nFgts := 0
Private  _nBaseIr := 0
Private  _nBaseIrFe := 0
Private  _nDedDep := 0
Private _nHandle

//----------------------------------------------------------------
// Define Variaveis Private(Programa)                          
//----------------------------------------------------------------
Private _aLanca := {}
Private _aProve := {}
Private _aDesco := {}
Private _aBases := {}
Private _aInfo  := {}
Private _aCodFol:= {}
Private _nSeq   := 0
Private _nTotVct:= 0     
Private _nTotDes:= 0     
Private _nTotLiq:= 0     
Private _nSeqd  := 0     
Private _nLiquido := 0  
Private _aTotLote := {0,0}
Private _cFinPgt := {}            
Private _nTotalLiq := 0    
Private _cCodAdto := ""
Private _cCodBaseAd := ""
Private _nTotvenc := 0
Private _nTotdesc:= 0


If  ! Fp_CodFol(@_aCodFol,cfilant) .Or. ! fInfo(@_aInfo,cfilant)

	U_ITMsg("Filial " + cfilant + " não tem dados de folha cadastrados!","Atenção","Filial não será processada",1)
	Return

EndIf
        
_cCodAdto   := _aCodFol[007,1]
_cCodBaseAd := _aCodFol[012,1]
_cDesc_Red := AllTrim(_aInfo[1])		
_cDesc_Fil := _aInfo[3]
_cDesc_End := _aInfo[4]                // Dados da Filial

_cMesAnoRef := SubStr(MV_PAR01,5,2) + SubStr(MV_PAR01,1,4)
_cAnoMesRef := Right(_cMesAnoRef,4) + Left(_cMesAnoRef,2)

If MV_PAR03 == 6  

		_cMesArqRef := "13" + Right(_cMesAnoRef,4)

Else

		_cMesArqRef := _cMesAnoRef

EndIf	              

//----------------------------------------------------------------
// Cria o Arquivo TXT                                         
//----------------------------------------------------------------
_nHandle	:= MSFCREATE(AllTrim(AllTrim(MV_PAR04)+AllTrim(CFILANT)+"_PGTOITAU.REM"))

If Ferror() # 0 .And. _nHandle = -1

	U_ITMsg( "Erro de abertura, codigo DOS:" + Str(FERROR(),4) ,"Atencao",,1 ) 
    Return

EndIf


//----------------------------------------------------------------
// Selecionando a Ordem de impressao escolhida no parametro.    
//----------------------------------------------------------------
DBSelectArea( "SRA")

If MV_PAR02 == 1

	SRA->(DBSetOrder(1))

ElseIf MV_PAR02 == 2

	SRA->(DBSetOrder(2))

ElseIf MV_PAR02 == 3

	SRA->(DBSetOrder(3))

EndIf

SRA->(DBGoTop())

//----------------------------------------------------------------
// Selecionando o Primeiro Registro e montando Filtro.          
//----------------------------------------------------------------
If MV_PAR02 == 1

	SRA->(DBSeek(cfilant + MV_PAR07,.T.))
	_cInicio := "SRA->RA_FILIAL + SRA->RA_MAT"
	_cFim    := cfilant + MV_PAR08

ElseIf MV_PAR02 == 2

	SRA->(DBSeek(cfilant + MV_PAR05 + MV_PAR07,.T.))
	_cInicio  := "SRA->RA_FILIAL + SRA->RA_CC + SRA->RA_MAT"
	_cFim     := cfilant + MV_PAR06 + MV_PAR08

ElseIf MV_PAR02 == 3

	SRA->(DBSeek(cfilant + MV_PAR09 + MV_PAR07,.T.))
	_cInicio := "SRA->RA_FILIAL + SRA->RA_NOME + SRA->RA_MAT"
	_cFim    := cfilant + MV_PAR10 + MV_PAR08

EndIf

DBSelectArea("SRA")
//----------------------------------------------------------------
// Carrega Regua Processamento                                  
//----------------------------------------------------------------
_nconta := RecCount()



// Monta Header de Arquivo Empresa - Registro Tipo "0"
MGPE012M() 

If MV_PAR03 == 1			// Adiantamento

   _cFinPgt := "J"

ElseIf MV_PAR03 == 2		// Folha

   _cFinPgt := "E" 

ElseIf MV_PAR03 == 3		// 1a Parcela
 
   _cFinPgt := "A"

ElseIf MV_PAR03 == 4		// 2a Parcela

   _cFinPgt := "B" 

Else					// Extras

   _cFinPgt := "I"	

EndIf


DBSelectArea("SRA")
While !Eof() .And. &_cInicio <= _cFim
	
	//----------------------------------------------------------------
	// Movimenta Regua Processamento                                
	//----------------------------------------------------------------
  	If ValType(oproc) = "O"

      	oproc:cCaption := ("Processando filial " + AllTrim(cfilant) + " - Registro " + StrZero(_npos,6) + " de " + StrZero(_nconta,6) + "...")
   		ProcessMessages()
 
    EndIf
  	_npos++
  	
	//----------------------------------------------------------------
	// Consiste Parametrizacao do Intervalo de Impressao            
	//----------------------------------------------------------------
	If (SRA->RA_NOME < MV_PAR09)    .Or. (SRA->Ra_NOME > MV_PAR10)    .Or. ;
		(SRA->RA_MAT < MV_PAR07)     .Or. (SRA->Ra_MAT > MV_PAR08)     .Or. ;
		(SRA->RA_CC < MV_PAR05)       .Or. (SRA->Ra_CC > MV_PAR06)
		
		SRA->(DBSkip(1))
		Loop

	EndIf

	_aLanca:={}         // Zera Lancamentos
	_aProve:={}         // Zera Lancamentos
	_aDesco:={}         // Zera Lancamentos
	_aBases:={}         // Zera Lancamentos
	_nAteLim := _nBaseFgts := _nFgts := _nBaseIr := _nBaseIrFe := _nDedDep := 0.00
	_dDataPg := Ctod("  /  /  ")
	
	//----------------------------------------------------------------
	// Consiste situacao e categoria dos funcionarios			     |
	//----------------------------------------------------------------
	If !( SRA->RA_SITFOLH $ MV_PAR11 ) .Or.  ! ( SRA->RA_CATFUNC $ MV_PAR12 )

		SRA->(DBSkip())
		Loop

	EndIf          
	                                                        
	If SRA->RA_SITFOLH $ "D" .And. SubStr(DToS(SRA->RA_DEMISSA),1,6) < AllTrim(MV_PAR01)

		SRA->(DBSkip())
		Loop

	EndIf
	
	//----------------------------------------------------------------
	// Consiste controle de acessos e filiais validas				 |
	//----------------------------------------------------------------
    If !(SRA->RA_FILIAL $ fValidFil()) .Or. !Eval(_cAcessaSRA)

       SRA->(DBSkip())
       Loop

    EndIf


	//----------------------------------------------------------------
	// Verifica se satisfaz a condicao de filtro do usuario         
	//----------------------------------------------------------------
	If _cFilSRA # Nil .And. !Empty(_cFilSRA) .And. !&_cFilSRA

		SRA->(DBSkip())
		Loop

	EndIf

	//----------------------------------------------------------------
	//Consiste que o funcionário tem conta no banco itau
	//----------------------------------------------------------------
	If !( SubStr(AllTrim(SRA->RA_BCDEPSA),1,3) == '341' )
		SRA->(DBSkip())
		Loop
	EndIf


	If SRA->RA_CC #_cCcAnt                   // Centro de Custo

		MGPE012C(Sra->Ra_Cc,Sra->Ra_Filial)
		_cCcAnt:=SRA->RA_CC

	EndIf
			
	/*
	==================================
	MV_PAR03
	1 - Adto
	2 - Folha
	3 - 1a.Parcela
	4 - 2a.Parcela
	5 - Valores Extras
	==================================
	*/
	
	If MV_PAR03 == 1 .Or. MV_PAR03 == 2
		
	  _CROT := IIf(MV_PAR03==1,'ADI','FOL')
		
	  //Verifica se tem no SRC
	  SRC->(DBSetOrder(4)) //RC_FILIAL+RC_MAT+RC_PERIODO+RC_ROTEIR+RC_SEMANA+RC_PD     

	  If SRC->(DBSeek(SRA->RA_FILIAL+SRA->RA_MAT+AllTrim(MV_PAR01)+_CROT))
		                                                                                                      
		
		SRC->(DBSetOrder(1))
		
		
		If SRC->(DBSeek(SRA->RA_FILIAL + SRA->RA_MAT))
			
			While !(SRC->(Eof())) .And. SRC->RC_FILIAL+SRC->RC_MAT == SRA->RA_FILIAL+SRA->RA_MAT
			    
			    If !Eval(_cAcessaSRC)
			    
			       SRC->(DBSkip())
			       Loop
			    
			    EndIf
			    
			    If  SRC->RC_ROTEIR != _CROT
		    
					SRC->(DBSkip())
					Loop
			    
				EndIf
				
				If (MV_PAR03 == 1) .And. (Src->Rc_Pd == _aCodFol[7,1])      // Desconto de Adto
				
					MGPE012S("P",_aCodFol[6,1],SRC->RC_HORAS,SRC->RC_VALOR)
					_nTotvenc += Src->Rc_Valor
					
				ElseIf (MV_PAR03 == 1) .And. (Src->Rc_Pd == _aCodFol[12,1])
				
					MGPE012S("D",_aCodFol[9,1],SRC->RC_HORAS,SRC->RC_VALOR)
					_nTotdesc += SRC->RC_VALOR
					
				ElseIf (MV_PAR03 == 1) .And. (Src->Rc_Pd == _aCodFol[8,1])
				
					MGPE012S("P",_aCodFol[8,1],SRC->RC_HORAS,SRC->RC_VALOR)
					_nTotvenc += SRC->RC_VALOR
					
				Else
				
					If PosSrv( Src->Rc_Pd , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "1"
					
						If (MV_PAR03 #1) .Or. (MV_PAR03 == 1 .And. PosSrv(Src->Rc_Pd,Sra->Ra_Filial,"RV_ADIANTA") == "S")
						
							MGPE012S("P",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
							_nTotvenc += Src->Rc_Valor
							
						EndIf
						
					ElseIf PosSrv( Src->Rc_Pd , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "2"
					
						If (MV_PAR03 #1) .Or. (MV_PAR03 == 1 .And. PosSrv(Src->Rc_Pd,Sra->Ra_Filial,"RV_ADIANTA") == "S")
						
							MGPE012S("D",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
							_nTotdesc += Src->Rc_Valor
							
						EndIf
						
					ElseIf PosSrv( Src->Rc_Pd , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "3"
					
						If (MV_PAR03 #1) .Or. (MV_PAR03 == 1 .And. PosSrv(Src->Rc_Pd,Sra->Ra_Filial,"RV_ADIANTA") == "S")
						
							MGPE012S("B",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
							
						EndIf
						
					EndIf
					
				EndIf
				
				If MV_PAR03 = 1  
				  		   
					If SRC->RC_PD == _aCodFol[10,1]
					
						_nBaseIr := SRC->RC_VALOR
					   _dDataPg := SRC->RC_DATA
					   
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
					
              ElseIf SRC->RC_PD = _aCodFol[59,1]
                
                  _nDedDep += SRC->RC_VALOR
                    
              ElseIf SRC->RC_PD = _aCodFol[47,1]
                
                  _dDataPg := SRC->RC_DATA  
                      
              ElseIf SRC->RC_PD == _aCodFol[47,1]
                
              	_nLiquido := SRC->RC_VALOR
               		
				EndIf
				
				DBSelectArea("SRC")
				SRC->(DBSkip())
				
			EndDo
			
		EndIf
		
	  Else
	  
	    //Procura no SRD
	    SRD->(DBSetOrder(1)) //RD_FILIAL+RD_MAT+RD_DATARQ+RD_PD+RD_SEMANA+RD_SEQ+RD_CC                                                                                                         
		
		_CROT := IIf(MV_PAR03==1,'ADI','FOL')
		
		If SRD->(DBSeek(SRA->RA_FILIAL + SRA->RA_MAT + AllTrim(MV_PAR01)))
			
			While !(SRD->(Eof())) .And. SRD->RD_FILIAL+SRD->RD_MAT+SRD->RD_DATARQ == SRA->RA_FILIAL+SRA->RA_MAT+AllTrim(MV_PAR01)
			    
			    If  SRD->RD_ROTEIR != _CROT
			    
			       SRD->(DBSkip())
			       Loop
			    
			    EndIf
				
				If (MV_PAR03 == 1) .And. (SRD->RD_Pd == _aCodFol[7,1])      // Desconto de Adto
				
					MGPE012S("P",_aCodFol[6,1],SRD->RD_HORAS,SRD->RD_VALOR)
					_nTotvenc += SRD->RD_Valor
					
				ElseIf (MV_PAR03 == 1) .And. (SRD->RD_Pd == _aCodFol[12,1])
				
					MGPE012S("D",_aCodFol[9,1],SRD->RD_HORAS,SRD->RD_VALOR)
					_nTotdesc += SRD->RD_VALOR
					
				ElseIf (MV_PAR03 == 1) .And. (SRD->RD_Pd == _aCodFol[8,1])
				
					MGPE012S("P",_aCodFol[8,1],SRD->RD_HORAS,SRD->RD_VALOR)
					_nTotvenc += SRD->RD_VALOR
					
				Else
				
					If PosSrv( SRD->RD_Pd , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "1"
					
						If (MV_PAR03 #1) .Or. (MV_PAR03 == 1 .And. PosSrv(SRD->RD_Pd,Sra->Ra_Filial,"RV_ADIANTA") == "S")
						
							MGPE012S("P",SRD->RD_PD,SRD->RD_HORAS,SRD->RD_VALOR)
							_nTotvenc += SRD->RD_Valor
							
						EndIf
						
					ElseIf PosSrv( SRD->RD_Pd , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "2"
					
						If (MV_PAR03 #1) .Or. (MV_PAR03 == 1 .And. PosSrv(SRD->RD_Pd,Sra->Ra_Filial,"RV_ADIANTA") == "S")
						
							MGPE012S("D",SRD->RD_PD,SRD->RD_HORAS,SRD->RD_VALOR)
							_nTotdesc += SRD->RD_Valor
							
						EndIf
						
					ElseIf PosSrv( SRD->RD_Pd , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "3"
					
						If (MV_PAR03 #1) .Or. (MV_PAR03 == 1 .And. PosSrv(SRD->RD_Pd,Sra->Ra_Filial,"RV_ADIANTA") == "S")
						
							MGPE012S("B",SRD->RD_PD,SRD->RD_HORAS,SRD->RD_VALOR)
							
						EndIf
						
					EndIf
					
				EndIf
				
				If MV_PAR03 = 1  
				  		   
					If SRD->RD_PD == _aCodFol[10,1]
					
						_nBaseIr := SRD->RD_VALOR
					   _dDataPg := SRD->RD_DATPGT
					   
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
					
              ElseIf SRD->RD_PD = _aCodFol[59,1]
                
                  _nDedDep += SRD->RD_VALOR
                    
              ElseIf SRD->RD_PD = _aCodFol[47,1]
                
                  _dDataPg := SRD->RD_DATPGT 
                      
              ElseIf SRD->RD_PD == _aCodFol[47,1]
                
              	_nLiquido := SRD->RD_VALOR
               		
				EndIf
				
				DBSelectArea("SRD")
				SRD->(DBSkip())
				
			EndDo
			
		EndIf
	    
	  EndIf
	
	/*
	==================================
	MV_PAR03
	1 - Adto
	2 - Folha
	3 - 1a.Parcela
	4 - 2a.Parcela
	5 - Valores Extras
	==================================
	*/
		
	ElseIf MV_PAR03 == 3
	              
		DBSelectArea("SRC")
		If SRC->(DBSeek(SRA->RA_FILIAL + SRA->RA_MAT))
		
			While !(SRC->(Eof())) .And. SRA->RA_FILIAL + SRA->RA_MAT == SRC->RC_FILIAL + SRC->RC_MAT
			
			    If !Eval(_cAcessaSRC) .Or. AllTrim(SRC->RC_ROTEIR) != '131'
			    
			       SRC->(DBSkip())
			       Loop
			       
			    EndIf
				If SRC->RC_PD == _aCodFol[22,1]
				
					MGPE012S("P",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
					_nTotvenc += SRC->RC_VALOR
					
				ElseIf SRC->RC_PD == _aCodFol[172,1]
				
					MGPE012S("D",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
					_nTotdesc += SRC->RC_VALOR
					
				ElseIf SRC->RC_PD == _aCodFol[108,1] .Or. SRC->RC_PD == _aCodFol[109,1] .Or. SRC->RC_PD == _aCodFol[173,1] 
				
					MGPE012S("B",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
					
				EndIf
				
				If SRC->RC_PD == _aCodFol[108,1]
				
					_nBaseFgts := SRC->RC_VALOR
					
				ElseIf SRC->RC_PD == _aCodFol[109,1]
				
					_nFgts     := SRC->RC_VALOR
					
              ElseIf SRC->RC_PD == _aCodFol[22,1]
                
                  _dDataPg := SRC->RC_DATA
                    
				EndIf
                
              If SRC->RC_PD == _aCodFol[047,1]
              
					_nLiquido := SRC->RC_VALOR
					
				EndIf           

				DBSelectArea("SRC")
				SRC->(DBSkip())
				
			EndDo
			
		EndIf
		
	ElseIf MV_PAR03 == 4  
	   
		DBSelectArea("SRC")
		SRC->(DBSetOrder(2))
		
		If SRC->(DBSeek(SRA->RA_FILIAL + SRA->RA_CC + SRA->RA_MAT))
		
			While !(SRC->(Eof())) .And. SRA->RA_FILIAL + SRA->RA_CC + SRA->RA_MAT == SRC->RC_FILIAL + SRC->RC_CC + SRC->RC_MAT
			
			    If !Eval(_cAcessaSRC) .Or. AllTrim(SRC->RC_ROTEIR) != '132'
			    
			       SRC->(DBSkip())
			       Loop
			       
			    EndIf
			    
				If PosSrv( SRC->RC_PD , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "1"
				
					MGPE012S("P",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
					_nTotvenc = _nTotvenc + SRC->RC_VALOR
					
				ElseIf PosSrv( SRC->RC_PD , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "2"
				
					MGPE012S("D",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
					_nTotdesc = _nTotdesc + SRC->RC_VALOR
					
				ElseIf PosSrv( SRC->RC_PD , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "3"
				
					MGPE012S("B",SRC->RC_PD,SRC->RC_HORAS,SRC->RC_VALOR)
					
				EndIf

				If SRC->RC_PD == _aCodFol[19,1]
				
					_nAteLim += SRC->RC_VALOR
					
				ElseIf SRC->RC_PD$ _aCodFol[108,1]
				
					_nBaseFgts += SRC->RC_VALOR
					
				ElseIf SRC->RC_PD$ _aCodFol[109,1]
				
					_nFgts += SRC->RC_VALOR
					
				ElseIf SRC->RC_PD == _aCodFol[27,1]
				
					_nBaseIr += SRC->RC_VALOR
					
				ElseIf SRC->RC_PD == _aCodFol[62,1]
				
					_nDedDep += SRC->RC_VALOR
					
				ElseIf SRC->RC_PD == _aCodFol[21,1]
				
				    _dDataPg := SRC->RC_DATA
				    
				ElseIf SRC->RC_PD == _aCodFol[21,1]
				
               		_nLiquido := SRC->RC_VALOR
               		
				EndIf
				
				SRC->(DBSkip())
				
			EndDo
			
		EndIf
		
	ElseIf MV_PAR03 == 5 
	   
		DBSelectArea("SR1")
		SR1->(DBSetOrder(1))
		If SR1->(DBSeek( SRA->RA_FILIAL + SRA->RA_MAT ))
		
			While !(SR1->(Eof())) .And. SRA->RA_FILIAL + SRA->RA_MAT ==	SR1->R1_FILIAL + SR1->R1_MAT
			
			    If !Eval(_cAcessaSR1)
			    
			       SR1->(DBSkip())
			       Loop
			       
			    EndIf
			    
				If PosSrv( SR1->R1_PD , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "1"
				
					MGPE012S("P",SR1->R1_PD,SR1->R1_HORAS,SR1->R1_VALOR)
					_nTotvenc = _nTotvenc + SR1->R1_VALOR
					
				ElseIf PosSrv( SR1->R1_PD , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "2"
				
					MGPE012S("D",SR1->R1_PD,SR1->R1_HORAS,SR1->R1_VALOR)
					_nTotdesc = _nTotdesc + SR1->R1_VALOR
					
				ElseIf PosSrv( SR1->R1_PD , SRA->RA_FILIAL , "RV_TIPOCOD" ) == "3"
				
					MGPE012S("B",SR1->R1_PD,SR1->R1_HORAS,SR1->R1_VALOR)
					
				EndIf
				
				SR1->(DBSkip())
				
			EndDo
			
		EndIf
		
	EndIf
	
	DBSelectArea("SRA")
	
	If _nTotvenc = 0 .And. _nTotdesc = 0
	
		SRA->(DBSkip())
		Loop
		
	EndIf
    
	MGPE012I()   // Impressao do Recibo de Pagamento
   
	DBSelectArea("SRA")
	SRA->(DBSkip())
	_nTotdesc := _nTotvenc := 0
	
EndDo

cLin6 := '34100015'+Space(9)+StrZero(_aTotLote[1]+1,6)+'000'+If((_nTotalLiq)==Int(_nTotalLiq),StrZero(_nTotalLiq,13)+'00',StrZero(Val(Replace(Transform(_nTotalLiq,"@E 9999999.99"),',','')),15))+'000000000000000000'

cLin7 := '34199999'+Space(9)+'000001'+StrZero(_aTotLote[1]+3,6)

_aTotLote[1]++


MGPE012G(cLin6,240)
MGPE012G(cLin7,240)
	 

//----------------------------------------------------------------
// Seleciona arq. defaut do Siga caso Imp. Mov. Anteriores      
//----------------------------------------------------------------
If !Empty( _cAliasMov )

	fFimArqMov( _cAliasMov , _aOrdBag , _cArqMov )
	
EndIf


//----------------------------------------------------------------
// Termino do relatorio                                         
//----------------------------------------------------------------

FClose(_nHandle)

DBSelectArea("SRC")
DBSetOrder(1)          // Retorno a ordem 1
DBSelectArea("SRC")
DBSetOrder(1)          // Retorno a ordem 1
DBSelectArea("SRA")
SET FILTER TO
RetIndex("SRA")

If !(Type("cArqNtx") == "U")

	fErase(cArqNtx + OrdBagExt())
	
EndIf

//Se não tem valores a pagar apaga o arquivo gerado
If _ngravados == 0 

	ferase(AllTrim(AllTrim(MV_PAR04)+AllTrim(CFILANT)+"_PGTOITAU.REM"))
	
Else

     aAdd(_aresults,{cfilant,"Totais da Filial:","   ",StrZero(_ngravados,6) + " funcionários","Conta pagadora: " + _cagencia + " - " + _cconta + "/" + _cdigito ,;
							" "," ",Transform(_ntotais,"@E 9999999.99")," "})
							
     _ntotais := 0


EndIf


/*
===============================================================================================================================
Programa----------: MGPE012I
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/08/2015
Descrição---------: IMRESSAO DO RECIBO FORMULARIO CONTINUO
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE012I()

Local _nConta
Local _nMaxReg 
Local _nValIR := 0
Local _nPosAd

If MV_PAR03 == 2

	If (_nPosAd := aScan(_aLanca,{ |x| x[2] == _cCodAdto}))>0
	
		If (nPos := aScan(_aBases,{ |x| _cCodBaseAd $ x[1]})) > 0
		
			_nValIR := _aBases[nPos,3]
			_aLanca[_nPosAd,5] -= _nValIR
			aAdd(_aLanca,{"D",_cCodBaseAd,SubStr(_aBases[nPos,1],5,20),0,_nValIR})
			
		EndIf
		
	EndIf
	
EndIf

MGPE012H()       // Header do funcionário

_nMaxReg := If ( Len(_aLanca) > 35,35,Len(_aLanca))                                                                         

For _nConta = 1 To _nMaxReg

	MGPE012N(_nConta)
	
Next

If _nLiquido == 0

   _nLiquido := _nTotvenc -_nTotdesc
   
EndIf

_aTotLote[1]++

_nSeqd := 0

_nTotVct += _nTotVenc    
_nTotDes += _nTotDesc  
        
If (_nTotVenc-_nTotDesc) > 0

	_nTotLiq += _nTotVenc - _nTotDesc 
	    
EndIf

Return
  
/*
===============================================================================================================================
Programa----------: MGPE012M
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/08/2015
Descrição---------: Impressao cabecalho
Parametros--------: 	
Retorno-----------: 
===============================================================================================================================
*/
Static Function MGPE012M()   // Cabecalho do Recibo()

Local _cLin0 := ""
Local _cLin1 := ""

_nSeq ++        
_aTotLote[1]++

DBSelectArea("SM0") 
DBSelectArea("SEE")

If _cagenciam == _cagencia .And. _cconta == _ccontam

	_ccnpj := _ccnpjm

Else

	_ccnpj := StrZero(Val(SM0->M0_CGC),14)

EndIf


_cLin0 := '34100000      080'+If(SM0->M0_TPINSC=2,'2','1')+_ccnpj+Space(20)+StrZero(Val(AllTrim(_cagencia)),5)+Space(1)+StrZero(Val(AllTrim(_cconta)),12)+Space(1)+AllTrim(_cdigito)+ ;
		"GOIASMINAS IND LATICINIOS LTDA"+'BANCO ITAU'+Space(30)+'1'+GRAVADATA(DDATABASE,.F.,5)+SUBST(TIME(),1,2)+SUBST(TIME(),4,2)+SUBST(TIME(),7,2)+'00000000000000' 

_cLin1 := '34100011C3001040 '+If(SM0->M0_TPINSC=2,'2','1')+_ccnpj+Space(20)+StrZero(Val(AllTrim(_cagencia)),5)+Space(1)+StrZero(Val(AllTrim(_cconta)),12)+Space(1)+AllTrim(_cdigito)+ ;
		"GOIASMINAS IND LATICINIOS LTDA"+'01'+Space(38)+SubStr(SM0->M0_ENDCOB,1,30)+StrZero(Val(SubStr(SM0->M0_ENDCOB, AT(',',SM0->M0_ENDCOB)+1,5)),5)+SubStr(SM0->M0_COMPCOB,1,15)+SubStr(SM0->M0_CIDCOB,1,20)+SubStr(SM0->M0_CEPCOB,1,8)+ ;
		SubStr(SM0->M0_ESTCOB,1,2)+Space(8)	 

MGPE012G(_cLin0,240)
MGPE012G(_cLin1,240)

Return

/*
===============================================================================================================================
Programa----------: MGPE012H
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/08/2015
Descrição---------: Monta Header do funcionario
Parametros--------: 	
Retorno-----------: 
===============================================================================================================================
*/
Static Function MGPE012H()   


Local _cFuncao := LEFT(Posicione("SRJ",1,xFilial("SRJ")+SRA->RA_CODFUNC,"RJ_DESC")+Space(50),50)
Local _cLin2 := ""
Local _cLin3 := ""

_nSeqFun ++
_ngravados++

_aTotLote[1]++
//Header - Funcionário (Registro Tipo 1)      

_cLin2 := '34100013'+StrZero(_nSeqFun,5)+'A001000'+SubStr(RA_BCDEPSA,1,3)+StrZero(Val(SubStr(RA_BCDEPSA,4,5)),5)+Space(1)+ ;
			StrZero(Val(SubStr(AllTrim(RA_CTDEPSA),1,Len(AllTrim(RA_CTDEPSA))-1)),12)+Space(1)+SubStr(RA_CTDEPSA,Len(AllTrim(RA_CTDEPSA)),1)+PadR(RA_NOME,30,'')+PadR(RA_MAT,20,'')+SubStr(DToS(MV_PAR13),7,2)+SubStr(DToS(MV_PAR13),5,2)+SubStr(DToS(MV_PAR13),1,4)+ ;
   			'REA'+'000000000000000000000000000000'+ ;
   			'                    00000000000000000000000'+'                    '+'000000'+StrZero(Val(PadL(RA_CIC,14)),14)+'            0'   	            	                    

_nTotalLiq := 0

_cLin3 := '34100013'+StrZero(_nSeqFun,5)+'D   '+ SubStr(MV_PAR01,5,2) + SubStr(MV_PAR01,1,4) + ;
   			MGPE012C(Sra->Ra_Cc,Sra->Ra_Filial)+PadR(RA_MAT,10,'')+SubStr(_cFuncao,1,30)+'00000000000000000'+ ;
   			If(AllTrim(SubStr(RA_DEPIR,2,1))=='','0',AllTrim(SubStr(RA_DEPIR,2,1)))+'0'+ ;
   			If(AllTrim(SubStr(RA_DEPSF,2,1))=='','0',AllTrim(SubStr(RA_DEPSF,2,1)))+AllTrim(Str(INT(RA_HRSEMAN)))+ ;
   			If(_nAteLim==Int(_nAteLim),StrZero(_nAteLim,13)+'00',StrZero(Val(Replace(Transform(_nAteLim,"@E 9999999.99"),',','')),15))+ ;
   			If(_nFgts==Int(_nFgts),StrZero(_nFgts,13)+'00',StrZero(Val(Replace(Transform(_nFgts,"@E 9999999.99"),',','')),15))+	;
   			If(_nTotvenc==Int(_nTotvenc),StrZero(_nTotvenc,13)+'00',StrZero(Val(Replace(Transform(_nTotvenc,"@E 9999999.99"),',','')),15))+ ;
   			If(_nTotdesc==Int(_nTotdesc),StrZero(_nTotdesc,13)+'00',StrZero(Val(Replace(Transform(_nTotdesc,"@E 9999999.99"),',','')),15))+ ;
   			If((_nTotvenc-_nTotdesc)==Int(_nTotvenc-_nTotdesc),StrZero(_nTotvenc-_nTotdesc,13)+ ;
   			'00',StrZero(Val(Replace(Transform(_nTotvenc-_nTotdesc,"@E 9999999.99"),',','')),15))+ ;
   			If((RA_SALARIO)==Int(RA_SALARIO),StrZero(RA_SALARIO,13)+'00',StrZero(Val(Replace(Transform(RA_SALARIO,"@E 9999999.99"),',','')),15))+ ;
   			If((_nBaseIr)==Int(_nBaseIr),StrZero(_nBaseIr,13)+'00',StrZero(Val(Replace(Transform(_nBaseIr,"@E 9999999.99"),',','')),15))+ ;
   			If((_nBaseFgts)==Int(_nBaseFgts),StrZero(_nBaseFgts,13)+'00',StrZero(Val(Replace(Transform(_nBaseFgts,"@E 9999999.99"),',','')),15))+'01'
   			
aAdd(_aresults,{cfilant,MGPE012C(Sra->Ra_Cc,Sra->Ra_Filial),RA_MAT,SubStr(RA_NOME,1,30),SubStr(_cFuncao,1,30),Transform(_nTotvenc,"@E 9999999.99"),Transform(_nTotdesc,"@E 9999999.99"),;
				Transform(_nTotvenc-_nTotdesc,"@E 9999999.99"),Transform(RA_SALARIO,"@E 9999999.99")})
				
_ntotais := _ntotais + _nTotvenc-_nTotdesc
   
MGPE012G(_cLin2,240)                    
MGPE012G(_cLin3,240)

Return

/*
===============================================================================================================================
Programa----------: MGPE012N
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/08/2015
Descrição---------: Impressao das Verbas (Lancamentos) Form. Continuo 
Parametros--------: 	_nConta - verba no formato "Pnnnnnn" (Provento) ou "Dnnnnnn" (Desconto)
Retorno-----------: 
===============================================================================================================================
*/

Static Function MGPE012N(_nConta)   // Impressao dos Lancamentos()

Local _cTip := ""
Local _cTipr := ""
Local _cDet := ""


If _aLanca[_nConta,1] == "P"  /*Provento*/

   _cTip := "1" 
   
ElseIf _aLanca[_nConta,1] == "D"  /*Desconto*/

   _cTip := "2" 
   
EndIf   

If _aLanca[_nConta,4] == 00000

   _cTipr := "DIAS     "
   
Else

   _cTipr := "HORAS    "
   
EndIf   

If _aLanca[_nConta,1] # "B"

   _aTotLote[1]++
   _nSeqd ++                    

   _cDet := "34100013"+StrZero(_nSeqFun,5)+"E   "+_cTip+PadR(_aLanca[_nConta,3],23,'')+PadR(_aLanca[_nConta,4],7,'')+Space(5)+ ;
   			If(_aLanca[_nConta,5] = 0,"000000000",StrZero(_aLanca[_nConta,5]*100,15))+Space(35)+"000000000000000"+ ;
   			Space(35)+"000000000000000"+Space(35)+"000000000000000"+Space(22)


	MGPE012G(_cDet,240)
	
EndIf

Return


/*
===============================================================================================================================
Programa----------: MGPE012S
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/08/2015
Descrição---------: Somar as verbas no array
Parametros--------: 	_cTipo - P provento, D desconto, B base
						_cPd - Verba
						_nHoras - quantidade de horas
						_nValor - valor da verba
Retorno-----------: 
===============================================================================================================================
*/

Static Function MGPE012S(_cTipo,_cPd,_nHoras,_nValor)

Local _cDesc_Paga := DescPd(_cPd,Sra->Ra_Filial)  // mostra como pagto
Local _cArray := ""

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

    aAdd(&_cArray,{_cPd+" "+_cDesc_Paga,_nHoras,_nValor })
    
Else

    &_cArray[nPos,2] += _nHoras
    &_cArray[nPos,3] += _nValor
    
EndIf

Return


/*
===============================================================================================================================
Programa----------: MGPE012G
Autor-------------: Josué Danich Prestes
Data da Criacao---: 13/08/2015
Descrição---------: Grava registro no arquivo texto
Parametros--------: 	cRegistro - string a ser gravada
						nbytes - tamanho da linha
Retorno-----------: 
===============================================================================================================================
*/
Static Function MGPE012G( _cRegistro, _nbytes )

Local _cMsg

_cRegistro := Left(_cRegistro+Space(_nBytes),_nBytes)+CHR(13)+CHR(10)

FWrite(_nHandle,_cRegistro,Len(_cRegistro))

If Ferror() # 0

	_cMsg := "Erro de gravacao, codigo DOS:" + Str(Ferror(),2) 
	Help(" ",1, , ,_cMsg )
	Return (.F.)
	
EndIf

Return 

/*
===============================================================================================================================
Programa--------: MGPE012C
Autor-----------: Josué Danich Prestes
Data da Criacao-: 09/11/2017
Descrição-------: Retorna descrição do centro de custo com 20 caracteres
Parametros------: _Ccc - Código do centro de custo
				  _cfilial - filial do centro de custo
Retorno---------: _cret - descrição do centro de custo
===============================================================================================================================
*/
Static Function MGPE012C( _Ccc,_cfilial )

Local _cret := ""

_cret := SubStr(DescCC(_Ccc,_cfilial),1,20)

Return _cret
