/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
Alex Wallauer |24/09/2025| Chamado 52151. Alteração da leitura dos parametros do ZP1 para o SX6
André Lisboa  |07/11/2025| Chamado 52432. Correção reabertura custo gerencial (ZE0/ZE1)
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MEST014
Autor-------------: Josué Danich 
Data da Criacao---: 28/03/2017
Descrição---------: Rotina de atualização de parâmetros de estoque - Chamado 19460
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MEST014()       

Local _cArmazem := 0 
Local _cperg1 := "MV_CQ - Almoxarifado do Controle de Qualidade"
Local _cperg2 := "MV_DBLQMOV - Bloquear/desbloquear movimentos do estoque"
Local _cperg3 := "IT_DIFCM - Diferença de porcentagem no custo médio permitida nas transferências"
Local _cperg4 := "IT_DIFCMP - Percentual diferenca do CM nas producoes"
Local _cperg5 := "MV_ULMES - Desfazer ultima virada de saldos?"
Local _cperg6 := "IT_VLDCUS - Habilta/Desabilta Custo Produção?"
Local _cperg7 := "IT_ULMES - Reabrir Custo Gerencial?"
Local _cperg9 := "IT_DESTTRA - Código de Destino das Transferências para Filtro de Consulta (F3)."

//VERIFICA PERMISSÕES DE ACESSO
Local _lRet1 := U_ITVACESS( 'ZZL' , 3 , 'ZZL_PARDIF' , "S" )
Local _lRet2 := U_ITVACESS( 'ZZL' , 3 , 'ZZL_ULMES'  , "S" )
Local _lRet3 := U_ITVACESS( 'ZZL' , 3 , 'ZZL_PARDIF' , "S" )
Local _lRet4 := U_ITVACESS( 'ZZL' , 3 , 'ZZL_DIFCMP' , "S" )
Local _lRet5 := U_ITVACESS( 'ZZL' , 3 , 'ZZL_DESFAZ' , "S" )
Local _lRet6 := U_ITVACESS( 'ZZL' , 3 , 'ZZL_VLDCUS' , "S" )
Local _lRet7 := .T.
Local _lRet8 := U_ITVACESS( 'ZZL' , 3 , 'ZZL_AULMES' , "S" )
Local _lRet9 := U_ITVACESS( 'ZZL' , 3 , 'ZZL_AUTMUL' , "S" ) // Autorizado a fazer transferências multiplas.

If ZZL->(FIELDPOS("ZZL_DESFCG")) <> 0
   _lRet7 := U_ITVACESS( 'ZZL' , 3 , 'ZZL_DESFCG' , "S" )
EndIf

//MONTA VARIAVEIS
DBSelectArea("SX6")
SX6->(DBSetOrder(1))	

If SX6->(DBSeek(cFilAnt + "MV_CQ")) .And. _lRet1
	_cArmazem := getmv("MV_CQ")
Else
    _cArmazem:=""
	_lRet1 := .F.
EndIf

If SX6->(DBSeek(cFilAnt + "MV_DBLQMOV")) .And. _lRet2
	dDtUlMes:= GETMV("MV_DBLQMOV")
ElseIf _lRet2
	U_ITMsg("Não foi efetuado o cadastro do parâmetro MV_DBLQMOV para a filial: " + cFilAnt,'Atenção!',;
	        "Favor contactar o departamento de informática informando do erro ocorrido.",1)
    dDtUlMes:=CTOD("")	
	_lRet2 := .T.
EndIf

If SX6->(DBSeek(cFilAnt + "IT_DIFCM")) .And. _lRet3
	_nporcenta := GETMV("IT_DIFCM")
Else
    _nporcenta:=0
	_lRet3 := .F.
EndIf

If  _lRet4
	_nDIFCMP := SuperGetMV("IT_DIFCMP",.F.,"00")
EndIf
If  SX6->(DBSeek(cFilAnt + "MV_ULMES")) .And. _lRet5
	_cUltMes := GETMV("MV_ULMES")
Else
   _lRet5:=.F.
EndIf

If  _lRet6
	If SuperGetMV("IT_VLDCUS",.F.,.T.)
	   _cVLDCUS := "Sim"
    Else
	   _cVLDCUS := "Nao"
	EndIf
EndIf

If  _lRet7
	_cITUltMes := SuperGetMV("IT_ULMES",.F.,"012001")
EndIf

If _lRet9
   _cDestTran := SuperGetMV("IT_DESTTRA",.F.,"T00001;T00002;") + Space(100)
EndIf

//Monta perguntas
Private _lwhen1 := _lRet1
Private _lwhen2 := _lRet2
Private _lwhen3 := _lRet3
Private _lwhen4 := _lRet4
Private _lwhen6 := _lRet6
Private _lwhen8 := _lRet8
Private _lwhen9 := _lRet9   // JPP TESTE
Private _oDlg				// Dialog Principal
Private _lcontinua := .T.
oMainWnd:ReadClientCoords()//So precisa declarar uma fez para o Programa todo                                                                                

nposv := 005
nposh := 010

navav := 040
navah := 230

//Monta array de posições
_nI := 0
_nqt := 10 // 9 // JPP TESTE

apos := {}	

While _nI <= _nqt
	aAdd(apos,{nposv + ( IIf(_nI > 4, _nI - 5, _nI) * navav ), (IIf(_nI > 4, 1,0) * navah) + nposh})
	_nI++
EndDo

_lcontinua := .T.

While _lcontinua
	_nI := 1
	_lcontinua :=.T.
    _lRefazSaldo:=.F.
    _lReAbreCusGer:=.F.
	
	DEFINE MSDIALOG _oDlg TITLE "CENTRAL PARAMETROS ESTOQUE" FROM MEST014T(100),MEST014T(100) To MEST014T(650),MEST014T(1100) PIXEL
	
	If _nI <= Len(apos) .And. _lRet1
		@ MEST014T(apos[_nI][1]),MEST014T(apos[_nI][2]) To MEST014T(apos[_nI][1]+35),MEST014T(apos[_nI][2]+216)  PIXEL OF _oDlg
		
		@ MEST014T(apos[_nI][1]+14),MEST014T(apos[_nI][2] +4) Say    _cperg1;
        Size MEST014T(150),MEST014T(015) PIXEL OF _oDlg
		
        @ MEST014T(apos[_ni][1]+13),MEST014T(apos[_ni][2] + 150) MsGet  _cArmazem Size MEST014T(030),MEST014T(008) WHEN _lwhen1 Picture "@E 99" PIXEL OF _oDlg
		
		_nI++
	EndIf
	
	If _nI <= Len(apos) .And. _lRet2
		@ MEST014T(apos[_nI][1]),MEST014T(apos[_nI][2]) To MEST014T(apos[_nI][1]+35),MEST014T(apos[_nI][2]+216)  PIXEL OF _oDlg
		
		@ MEST014T(apos[_nI][1]+14),MEST014T(apos[_nI][2] + 4) Say    _cperg2;
        Size MEST014T(150),MEST014T(015) PIXEL OF _oDlg
		
        @ MEST014T(apos[_ni][1]+13),MEST014T(apos[_ni][2] + 150) MsGet dDtUlMes Size MEST014T(030),MEST014T(008) WHEN _lwhen2 Picture "@D 99/99/99" PIXEL OF _oDlg		
		
		_nI++
	EndIf

	If _nI <= Len(apos) .And. _lRet3
		@ MEST014T(apos[_nI][1]),MEST014T(apos[_nI][2]) To MEST014T(apos[_nI][1]+35),MEST014T(apos[_nI][2]+216)  PIXEL OF _oDlg
		
		@ MEST014T(apos[_nI][1]+14),MEST014T(apos[_nI][2] +4) Say    _cperg3;
        Size MEST014T(150),MEST014T(015) PIXEL OF _oDlg
		
        @ MEST014T(apos[_ni][1]+13),MEST014T(apos[_ni][2] + 150) MsGet _nporcenta Size MEST014T(030),MEST014T(008) WHEN _lwhen3 Picture "@E 999,999,999.99" PIXEL OF _oDlg		
		
		_nI++
	EndIf
	
	If _nI <= Len(apos) .And. _lRet4
		@ MEST014T(apos[_nI][1]),MEST014T(apos[_nI][2]) To MEST014T(apos[_nI][1]+35),MEST014T(apos[_nI][2]+216)  PIXEL OF _oDlg
		
		@ MEST014T(apos[_nI][1]+14),MEST014T(apos[_nI][2] +4) Say    _cperg4;
        Size MEST014T(150),MEST014T(015) PIXEL OF _oDlg
		
        @ MEST014T(apos[_ni][1]+13),MEST014T(apos[_ni][2] + 150) MsGet _nDIFCMP Size MEST014T(030),MEST014T(008) WHEN _lwhen4 Picture "@E 999,999,999.99" PIXEL OF _oDlg
		
		_nI++
	EndIf
	
	If _nI <= Len(apos) .And. _lRet5
		@ MEST014T(apos[_nI][1]),MEST014T(apos[_nI][2]) To MEST014T(apos[_nI][1]+35),MEST014T(apos[_nI][2]+216)  PIXEL OF _oDlg
		
        @ MEST014T(apos[_ni][1]+14),MEST014T(apos[_ni][2] +4) Say _cperg5 Size MEST014T(150),MEST014T(015) PIXEL OF _oDlg
		
        @ MEST014T(apos[_ni][1]+13),MEST014T(apos[_ni][2] + 135) MsGet _cUltMes Size MEST014T(045),MEST014T(010) WHEN _lRet8 Picture "@D" PIXEL OF _oDlg
		
        @ MEST014T(apos[_ni][1]+13),MEST014T(apos[_ni][2] + 185) Button "SIM" Size MEST014T(025),MEST014T(012) PIXEL OF _oDlg ACTION( _lRefazSaldo:=.T.,(_oDlg:End()) )
		
		_nI++
	EndIf

	If _nI <= Len(apos) .And. _lRet6
		
		@ MEST014T(apos[_nI][1]),MEST014T(apos[_nI][2]) To MEST014T(apos[_nI][1]+35),MEST014T(apos[_nI][2]+216)  PIXEL OF _oDlg
		
        @ MEST014T(apos[_ni][1]+14),MEST014T(apos[_ni][2] +4) Say _cperg6 Size MEST014T(150),MEST014T(015) PIXEL OF _oDlg
		
        @ MEST014T(apos[_ni][1]+13),MEST014T(apos[_ni][2] + 135) COMBOBOX _cVLDCUS Size MEST014T(045),MEST014T(010)  PIXEL OF _oDlg ITEMS {"Sim","Nao"}

		_nI++
		
	EndIf

	If _nI <= Len(apos) .And. _lRet7
		
		@ MEST014T(apos[_nI][1]),MEST014T(apos[_nI][2]) To MEST014T(apos[_nI][1]+35),MEST014T(apos[_nI][2]+216)  PIXEL OF _oDlg
		
        @ MEST014T(apos[_ni][1]+14),MEST014T(apos[_ni][2] +4) Say _cperg7 Size MEST014T(150),MEST014T(015) PIXEL OF _oDlg
		
        @ MEST014T(apos[_ni][1]+13),MEST014T(apos[_ni][2] + 135) MsGet _cITUltMes Size MEST014T(045),MEST014T(010) WHEN _lRet8 Picture "@!" PIXEL OF _oDlg
		
        @ MEST014T(apos[_ni][1]+13),MEST014T(apos[_ni][2] + 185) Button "SIM" Size MEST014T(025),MEST014T(012) PIXEL OF _oDlg ACTION( _lReAbreCusGer:=.T.,_oDlg:End() )
		
		_nI++
		
	EndIf
//------------------------------------------------------ // JPP TESTE

    If _nI <= Len(apos) .And. _lRet9
		
		@ MEST014T(apos[_nI][1]),MEST014T(apos[_nI][2]) To MEST014T(apos[_nI][1]+35),MEST014T(apos[_nI][2]+216)  PIXEL OF _oDlg
		
		@ MEST014T(apos[_nI][1]+14),MEST014T(apos[_nI][2] +4) Say    _cperg9;
        Size MEST014T(150),MEST014T(015) PIXEL OF _oDlg
		
        @ MEST014T(apos[_ni][1]+13),MEST014T(apos[_ni][2] + 150) MsGet  _cDestTran Size MEST014T(50),MEST014T(008) WHEN _lwhen9 PIXEL OF _oDlg
		
		_nI++
		
	EndIf

//------------------------------------------------------

	@ MEST014T(215),MEST014T(300) Button "Atualizar Parametros" Size MEST014T(080),MEST014T(013) PIXEL OF _oDlg ACTION(FWMsgRun(,{|| _lcontinua := MEST014C(_cArmazem,dDtUlMes,_nporcenta,_oDlg)},"Processando alteracao, aguarde...","Aguarde"))
	
    @ MEST014T(215),MEST014T(400) Button "SAIR" Size MEST014T(045),MEST014T(013) PIXEL OF _oDlg ACTION(_oDlg:End())
	
	ACTIVATE MSDIALOG _oDlg CENTERED

    If _lRefazSaldo
       If U_ITMsg( "Confirma DESFAZER ultima virada de saldos ?",'ATENCAO!',,3,2,2)
          
          FWMsgRun( ,{|oProc| _lRefazSaldo:=MEST014F(oProc) } ,'Aguarde!','Verificando os dados...'  )
          
          If !_lRefazSaldo
             Loop
          EndIf
       Else
          Loop
       EndIf
    EndIf
	
    If _lReAbreCusGer
       FWMsgRun( ,{|oProc| _lReAbreCusGer:=MEST14CG(oProc) } ,'Aguarde!','Verificando os dados...'  )
          
       If !_lReAbreCusGer
          Loop
       EndIf
    EndIf

	_lcontinua :=.F.
	
EndDo

Return(.T.)
/*
===============================================================================================================================
Programa----------: MEST014F
Autor-------------: Alex Wallauer
Data da Criacao---: 17/07/2018
Descrição---------: Refaz Saldo ultimo saldo da filial corrente
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST014F(oProc)

Local cAlias  := GetNextAlias()
Local _cData  := ""
Local _aSB9   := {}
Local _nQtdReg:=0
Local _cB9queryA:= " SELECT MAX(B9_DATA) UltData "
Local _cB9queryB:= " SELECT COUNT(R_E_C_N_O_) TOTAL "
Local _cB9queryC:= " SELECT R_E_C_N_O_ RECSB9 "
Local _cB9query1:= " FROM " + RETSQLNAME("SB9")+" WHERE D_E_L_E_T_ = ' '  AND B9_FILIAL = '" +cFilAnt+"'
Local _cB9query2:= ""
   
_cB9queryA := ChangeQuery(_cB9queryA+_cB9query1)
MPSysOpenQuery(_cB9queryA,cAlias)

_cData := (cAlias)->UltData
If Select(cAlias) > 0 
   (cAlias)->( DBCloseArea() )
EndIf

If Empty( _cData ) .Or. Empty( _cUltMes )
   U_ITMsg("Filial sem fechamento.","ATENCAO",;
           "Favor verificar e ajustar antes de prosseguir",1)		
   Return .F.
EndIf

If _cData <> DToS(_cUltMes)
   U_ITMsg("Data do parametro da virada (MV_ULMES) "+DToC(_cUltMes)+" e data "+DToC(SToD(_cData))+" dos registros gravados na tabela de saldos iniciais (SB9) divergentes.","ATENCAO",;
           "Favor verificar e ajustar antes de prosseguir",1)		
   Return .F.
EndIf

If Select(cAlias) > 0 
   (cAlias)->( DBCloseArea() )
EndIf

_cB9query2:= " AND B9_DATA = '" +_cData+"' ORDER BY B9_LOCAL , B9_COD "

_cB9queryB := ChangeQuery(_cB9queryB+_cB9query1+_cB9query2)
MPSysOpenQuery(_cB9queryB,cAlias)

_nQtdReg := (cAlias)->TOTAL 
If Select(cAlias) > 0 
   (cAlias)->( DBCloseArea() )
EndIf

_cTotal:=AllTrim(Str(_nQtdReg))

If Empty( _nQtdReg )
   U_ITMsg("Filial sem fechamentos.","ATENCAO",;
           "Favor verificar e ajustar antes de prosseguir",1)		
   Return .F.
ElseIf !U_ITMsg( "Serão processados "+_cTotal+" registros. Deseja Continuar?",'ATENCAO!',,3,2,2)
   Return .F.
EndIf

If Select(cAlias) > 0 
   (cAlias)->( DBCloseArea() )
EndIf

_cB9queryC := ChangeQuery(_cB9queryC+_cB9query1+_cB9query2)
MPSysOpenQuery(_cB9queryC,cAlias)

_nConta:=0	

While ! (cAlias)->( Eof() )

   _nConta++

   oProc:cCaption := "Lendo Item: "+AllTrim(SB9->B9_COD)+" - "+AllTrim(Str(_nConta))+" / "+_cTotal
   ProcessMessages()

   SB9->(DBGoTo((cAlias)->RECSB9))

   aAdd(_aSB9,{;
        SB9->B9_FILIAL,;
        SB9->B9_LOCAL ,;
        SB9->B9_COD   ,;
        Posicione('SB1',1,xFilial('SB1')+SB9->B9_COD,'B1_DESC'),;
        TRANS(SB9->B9_QINI ,"@E 999,999,999.99999") ,;
        TRANS(SB9->B9_VINI1,"@E 99,999,999,999.99") ,;
        SB9->B9_DATA})
   
   (cAlias)->(DBSkip())

EndDo

If Len(_aSB9) > 0
	_lOK    :=.F.
	_bOK    :={|oDlg| If(U_ITMsg( "Todos os Registros listados serão excluidos, Confirma ? "  ,'ATENCAO!',,3,2,2),(_lOK:=.T. , oDlg:End()),.T.) }
	_bCancel:={|oDlg| If(U_ITMsg("Confirma o Cancelamento? Todo o processamento será perdido!",'ATENCAO!',,3,2,2),(_lOK:=.F. , oDlg:End()),.T.) }
	
	U_ITListBox('Lista de Armazens / Produtos (MEST014)' ,;//ITListBox( _cTitAux , _aHeader , _aCols , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel )
	            {'Filial','Armazem','Codigo','Produto','Quantidade','Valor','Data'},_aSB9,.T.,1,"Lista de Armazens / Produtos com saldo fechado que seram abertos:",,;
	            {      35,       35,      50,      320,          60,     60,    40},, _bOK,_bCancel  )
	
	If _lOK

       BEGIN TRANSACTION 

		_nConta:=0 
		(cAlias)->( DBGoTop() )
		While ! (cAlias)->( Eof() )
			
			SB9->(DBGoTo((cAlias)->RECSB9))
			_nConta++			
			oProc:cCaption := "Excluindo Item: "+AllTrim(SB9->B9_COD)+" - "+AllTrim(Str(_nConta))+" / "+_cTotal
			ProcessMessages()			
	        SB9->(RecLock("SB9",.F.))
            SB9->(DBDelete())
			
			(cAlias)->(DBSkip())
			
		EndDo
        
		If SX6->(DBSeek(cFilAnt + "MV_ULMES"))
			
			If Select(cAlias) > 0
				(cAlias)->( DBCloseArea() )
			EndIf

			_cB9queryA := ChangeQuery(_cB9queryA+_cB9query1)
			MPSysOpenQuery(_cB9queryA,cAlias)

  	        _cUltMes := (cAlias)->UltData
	        
	        PutMV("MV_ULMES",_cUltMes)    
 
        EndIf

       END TRANSACTION 

	    U_ITMsg("Virada de saldos desfeita referente a data "+DToC(SToD(_cData))+". Saldos inciais ajustados para a data "+DToC(SToD(_cUltMes)),'ATENCAO!',,2)		

	    If U_ITMsg('É <B>IMPRESCINDIVEL</B> QUE APOS A EXCLUSAO SEJA  EXECUTADA'+CRLF+'A  ROTINA "REFAZ SALDOS", Executar agora?',"ATENCAO","",3,2,2)
		   oProc:cCaption := "EXCEUTANDO REFAZ SALDO, AGURADE..."
		   ProcessMessages()			
           MATA300()
        Else
	       U_ITMsg( "IMPORTANTE! NÃO SE ESQUEÇA DE RODAR O REFAZ SALDOS, SEM A EXECUÇÃO OS SALDOS ATUAIS PODEM FICAR COMPROMETIDOS!!",'ATENCAO!',,1)
        EndIf
	EndIf
	
EndIf

If Select(cAlias) > 0 
   (cAlias)->( DBCloseArea() )
EndIf

Return(.T.)

/*
===============================================================================================================================
Programa----------: MEST014C
Autor-------------: Josué Danich 
Data da Criacao---: 09/01/2017
Descrição---------: Atualiza parâmetros da filial corrente 
Parametros--------: _cArmazem - Armazem CQ
					dDtUlMes
					_nporcenta
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST014C(_cArmazem,dDtUlMes,_nporcenta,_oDlg)     

Local _alog := {}
        
DBSelectArea("SX6")
SX6->(DBSetOrder(1))	

If SX6->(DBSeek(cFilAnt + "MV_CQ")) .And. _lwhen1 
	PutMV("MV_CQ",_cArmazem)
	aAdd(_alog,{"MV_CQ  - O almoxarifado de qualidade foi definido como : " + AllTrim(_cArmazem) + " para a filial: " + cFilAnt})
EndIf  

If SX6->(DBSeek(cFilAnt + "MV_DBLQMOV")) .And. _lwhen2 
	PutMV("MV_DBLQMOV",dDtUlMes)
	aAdd(_alog,{"MV_DBLQMOV  - A data de bloqueio do estoque foi definida como : " + AllTrim(DToC(dDtUlMes)) + " para a filial: " + cFilAnt})
EndIf

If SX6->(DBSeek(cFilAnt + "IT_DIFCM")) .And. _lwhen3
	PutMV("IT_DIFCM",_nporcenta)
	aAdd(_alog,{"IT_DIFCM  - A tolerância de diferença de custo na transferência foi definida como : " + AllTrim(Str(_nporcenta)) + " para a filial: " + cFilAnt})
EndIf     

If SX6->(DBSeek(cFilAnt + "MV_ULMES")) .And. _lwhen8
	PutMV("MV_ULMES",_cUltMes)
	aAdd(_aLog, {"MV_ULMES - A data ultimo fechamento do estoque foi definida como: " + AllToChar(_cUltMes) + " para a filial: " + cFilAnt})
EndIf

 SX6->(DBSetOrder(1))
 
 If _lwhen8 .AND. (SX6->(DbSeek( cFilAnt + "IT_ULMES")) .OR. SX6->(DbSeek( '  ' + "IT_ULMES") )) 
     PutMv("IT_ULMES",_cITUltMes)
     aAdd(_alog,{"IT_ULMES - Reabrir Custo Gerencial : " + _cITUltMes + " para a filial: " + cFilAnt})
 EndIf   
 
 If _lwhen4 .AND. (SX6->(DbSeek( cFilAnt + "IT_DIFCMP")) .OR. SX6->(DbSeek( '  ' + "IT_DIFCMP") )) 
    PutMv("IT_DIFCMP",_nDIFCMP)
    aAdd(_alog,{"IT_DIFCMP - Percentual diferenca do CM nas producoes : " + AllTrim(str(_nDIFCMP)) + " para a filial: " + cFilAnt})
 EndIf   
 
 If _lwhen6 .AND. (SX6->(DbSeek( cFilAnt + "IT_VLDCUS")) .OR. SX6->(DbSeek( '  ' + "IT_VLDCUS") )) 
    PutMv("IT_VLDCUS",IIf(_cVLDCUS=="Sim",.T.,.F.))
    aAdd(_alog,{"IT_VLDCUS - Validação do custo de Produção : " + _cVLDCUS + " para a filial: " + cFilAnt})
 EndIf   
 
 If _lwhen9 .AND. (SX6->(DbSeek( cFilAnt + "IT_DESTTRA")) .OR. SX6->(DbSeek( '  ' + "IT_DESTTRA") )) 
    PutMv("IT_DESTTRA",AllTrim(_cDestTran))
    aAdd(_alog,{"IT_DESTTRA - Código de Destino das Transferências para Filtro de Consulta (F3): " + AllTrim(_cDestTran) + " para a filial: " + cFilAnt})
 EndIf
 
 If Len(_alog) == 0
     u_itmsg("Nenhuma alteração realizada!","Atenção",,3)
 Else
     U_ITListBox( 'Ajustes realizados nos parâmetros' , {'Descrição'} , _alog , .F. , 1 , 'Os seguintes ajustes foram efetivados: ' )
 EndIf
 
 //Registra log de acesso a rotina
 U_ITLOGACS('MEST014')
 
 _oDlg:End()

Return .T.

/*
===============================================================================================================================
Programa----------: MEST014T
Autor-------------: André Lisboa
Data da Criacao---: 09/01/2017
Descrição---------: Funcao responsavel por manter o Layout independente da resolucao horizontal do Monitor do Usuario.
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST014T(_nTam)                                                         

Local _nHres	:=	oMainWnd:nClientWidth	// Resolucao horizontal do monitor     

If _nHres == 640	// Resolucao 640x480 (soh o Ocean e o Classic aceitam 640)  
	_nTam *= 0.8                                                                
ElseIf (_nHres == 798).Or.(_nHres == 800)	// Resolucao 800x600                
	_nTam *= 1   	                                                               
Else	// Resolucao 1024x768 e acima faz proporcao                                          
	_nTam = (_nTam * 1)                                                               
EndIf                                                                         

Return Int(_nTam)    

/*
===============================================================================================================================
Programa----------: MEST14CG
Autor-------------: Alex Wallauer
Data da Criacao---: 02/07/2018
Descrição---------: REABRE CUSTO GERENCIAL
Parametros--------: oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function  MEST14CG(oProc)

Local cAlias  := GetNextAlias()
Local _cData  := ""
Local _aZE0   := {}
Local _nQtdReg:=0
Local _cB9queryA:= " SELECT MAX(SubStr(ZE0_DATARQ,3,4)||SubStr(ZE0_DATARQ,1,2)) UltData "
Local _cB9queryC:= " SELECT R_E_C_N_O_ RECZE0 "
Local _cB9query1:= " FROM " + RETSQLNAME("ZE0")+" WHERE D_E_L_E_T_ = ' '  AND ZE0_FILIAL = '" +cFilAnt+"'
Local _cB9query2:= ""
   
_cB9queryA := ChangeQuery(_cB9queryA+_cB9query1)
MPSysOpenQuery(_cB9queryA,cAlias)

_cData := SubStr((cAlias)->UltData,5,2) + SubStr((cAlias)->UltData,1,4)
If Select(cAlias) > 0 
   (cAlias)->( DBCloseArea() )
EndIf

If Empty( _cData ) .Or. Empty( _cITUltMes )
   U_ITMsg("Filial sem fechamento de Custo gerencial.","ATENCAO",;
           "Favor verificar e ajustar antes de prosseguir",1)		
   Return .F.
EndIf

If _cData <> _cITUltMes
   U_ITMsg("Data do parametro da virada (IT_ULMES) "+_cITUltMes+" e data "+_cData+" dos registros gravados na tabela (ZE0) divergentes.","ATENCAO",;
           "Favor verificar e ajustar antes de prosseguir",1)		
   Return .F.
EndIf

If Select(cAlias) > 0 
   (cAlias)->( DBCloseArea() )
EndIf

_cB9query2:= " AND ZE0_DATARQ = '" +_cData+"'  "
_cB9queryC := ChangeQuery(_cB9queryC+_cB9query1+_cB9query2)
MPSysOpenQuery(_cB9queryC,cAlias)

COUNT To _nQtdReg
DBGoTop()
_cTotal:=AllTrim(Str(_nQtdReg))

If Empty( _nQtdReg )
   U_ITMsg("Filial sem fechamento de Custo gerencial.","ATENCAO",;
           "Favor verificar e ajustar antes de prosseguir",1)		
   Return .F.
ElseIf !U_ITMsg( "Confirma REABRIR CUSTO GERENCIAL ?",'ATENCAO!',"Serão processados "+_cTotal+" registros.",3,2,2)
   Return .F.
EndIf

_nConta:=0	

While ! (cAlias)->( Eof() )

   _nConta++

   oProc:cCaption := "Lendo ZE0 - "+AllTrim(Str(_nConta))+" / "+_cTotal
   ProcessMessages()

   ZE0->(DBGoTo((cAlias)->RECZE0))

   aAdd(_aZE0,{;
        ZE0->ZE0_FILIAL,;
        ZE0->ZE0_DATARQ,;
        ZE0->ZE0_TPCUS ,;
        ZE0->ZE0_DTPCT ,;
        ZE0->ZE0_EVCUS ,;
        TRANS(ZE0->ZE0_QTDE ,"@E 999,999,999.99999") ,;
        TRANS(ZE0->ZE0_VALOR,"@E 99,999,999,999.99") })
   
   (cAlias)->(DBSkip())
EndDo

If Len(_aZE0) > 0
	_lOK:=.F.
	_bOK    :={|oDlg| If(U_ITMsg( "Todos os Registros listados serão excluidos, Confirma ? "  ,'ATENCAO!',,3,2,2),(_lOK:=.T. , oDlg:End()),.T.) }
	
	_bCancel:={|oDlg| If(U_ITMsg("Confirma o Cancelamento? Todo o processamento será perdido!",'ATENCAO!',,3,2,2),(_lOK:=.F. , oDlg:End()),.T.) }
	
	U_ITListBox(_cTotal+' Registros ZE0 (MEST014)',;//ITListBox( _cTitAux , _aHeader , _aCols , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel )
	            {'Filial','Mes Ano',AVSX3("ZE0_TPCUS",5),AVSX3("ZE0_DTPCT",5),AVSX3("ZE0_EVCUS",5),'Quantidade','Valor'},_aZE0,.T.,1,_cTotal+' Registros ZE0 que seram excluidos (MEST014)',,;
	            {      35,       40,               35,                     50,                  40,          60,     60},, _bOK,_bCancel  )
	
	If _lOK

       BEGIN TRANSACTION 

		_nConta:=0 
		(cAlias)->( DBGoTop() )
		While ! (cAlias)->( Eof() )
			
			ZE0->(DBGoTo((cAlias)->RECZE0))
			_nConta++			
			oProc:cCaption := "Excluindo ZE0 - "+AllTrim(Str(_nConta))+" / "+_cTotal
			ProcessMessages()			
	        ZE0->(RecLock("ZE0",.F.))
            ZE0->(DBDelete())
			
			(cAlias)->(DBSkip())
		EndDo
        _nConta:=0
		ZE1->( DBSetOrder(1) )
     	If ZE1->( DBSeek(cFilant+_cData ) )
		    While ! ZE1->( Eof() ) .And. ZE1->ZE1_FILIAL == cFilant .And. AllTrim(ZE1->ZE1_COMP) == _cData
			   _nConta++			
			   oProc:cCaption := "Excluindo ZE1... - "+AllTrim(Str(_nConta))
			   ProcessMessages()			
	           ZE1->(RecLock("ZE1",.F.))
               ZE1->(DBDelete())
			   ZE1->(DBSkip())
		    EndDo
		EndIf 

         If (SX6->(DbSeek( cFilAnt + "IT_ULMES")) .OR. SX6->(DbSeek( '  ' + "IT_ULMES") )) 
            If SELECT(cAlias) > 0 
               (cAlias)->( DBCloseArea() )
            EndIf
			_cB9queryA := ChangeQuery(_cB9queryA)
             MPSysOpenQuery(_cB9queryA,cAlias)
            _cData := Substr((cAlias)->UltData,5,2) + Substr((cAlias)->UltData,1,4)
            PutMv("IT_ULMES",_cData)
        EndIf 

       END TRANSACTION 

	   U_ITMsg("Custo Gerencial Aberto referente a data "+_cITUltMes,'ATENCAO!',;
		       "Custo Gerencial Fechado atual na data "+_cData,2)		
	EndIf
EndIf

If Select(cAlias) > 0 
   (cAlias)->( DBCloseArea() )
EndIf

Return(.T.)
