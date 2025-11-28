/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Lucas Borges  |13/10/2024| Chamado 48465. Retirada da função de conout
Igor Melgaço  |06/05/2025| Chamado 50525. Ajuste para remoção de diretório Local C:\SMARTCLIENT\.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MGPE015
Autor-------------: Josué Danich Prestes
Data da Criacao---: 21/12/2016
Descrição---------: Rotina de atualização de equipamentos de ponto - Chamado 18026
Parametros--------: _lShedule - Se está rodando em schedule
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function MGPE015(_lShedule)

Local _oSelf := nil

Default _lShedule:= .F. 
Private _lContinua:= .T.

If _lShedule //Cria ambiente se For schedule
	RPCSetType(3)
	RpcSetEnv( "01" , "01" ,,,"GPE", "SCHEDULE_ATUA" , {'SRA','SP0'} )
	Sleep( 5000 ) //Aguarda 5 segundos para subam as configurações do ambiente.
    MGPE015P(_lShedule,_oSelf)
Else
	While _lcontinua
		_lcontinua := .F.
		_bProcess    := {|_oSelf| U_MGPE015P(_lShedule,_oSelf)  }
		tNewProcess():New( "MGPE015", "Atualiza equipamentos ponto", _bProcess, "Rotina de atualização de equipamentos de ponto","MGPE015",,,,,,.T.)
	EndDo
EndIf

Return
/*
===============================================================================================================================
Programa----------: MGPE015P
Autor-------------: Josué Danich Prestes
Data da Criacao---: 21/12/2016
Descrição---------: Atualiza equipamentos de ponto
Parametros--------: _lShedule - se está rodando via schedule
					_oSelf - objeto da tela
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE015P(_lShedule,_oSelf)

Local _nconta :=0
Local _nproce :=0
Local _nproce2 := 0
Local _nconta2 := 0
Local _cAlias2 := GetNextAlias()
Local _cAlias  := GetNextAlias()
Local _cTemp   := ""
Local _cDirTemp := GetTempPath()

Default _lShedule := .F.

U_ITLOGACS('MGPE015')

If .not. _lShedule
	Count to _nconta
	_oself:SetRegua1( 0 )
Else
	MV_PAR01 := ""
	MV_PAR02 := "000000"
	MV_PAR03 := "ZZZZZZ"
EndIf

cQuery := " SELECT count(*) TOT  from " 
cQuery += retsqlname("SP0") + " SP0 WHERE SP0.D_E_L_E_T_ = ' '" 
cQuery += " AND (SP0.P0_I_CTRID ='W' OR SP0.P0_I_CTRID ='A') " 

If !(_lShedule)  //Se estiver rodando manualmente só roda para filial atual 
	cQuery  += " and SP0.P0_FILIAL = '" + cfilant + "'"
EndIf

If !Empty(AllTrim(MV_PAR01))
	cQuery += " AND SP0.P0_RELOGIO IN " + FormatIn( MV_PAR01 , ";" )
EndIf

If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , _cAlias , .T. , .F. )
	
_nconta := (_cAlias)->TOT

cQuery := " SELECT P0_RELOGIO,P0_FILIAL,P0_I_IP, P0_I_CTRID, P0_I_TIPO   from " 
cQuery += retsqlname("SP0") + " SP0 WHERE SP0.D_E_L_E_T_ = ' ' 
cQuery += " AND (SP0.P0_I_CTRID ='W' OR SP0.P0_I_CTRID ='A') " 

If !(_lShedule)  //Se estiver rodando manualmente só roda para filial atual 
	cQuery  += " and SP0.P0_FILIAL = '" + cfilant + "'"
EndIf

If !Empty(AllTrim(MV_PAR01))
	cQuery += " AND SP0.P0_RELOGIO IN " + FormatIn( MV_PAR01 , ";" )
EndIf
 
If Select(_cAlias) > 0
	(_cAlias)->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , _cAlias , .T. , .F. )
	
//===================================================================
//Loop principal de equipamentos
//===================================================================
If (_cAlias)->(Eof())
	If .not. _lShedule
		U_ITMsg("Não foram encontrados relógios ControId na seleção de relógios!","Atenção",,1)
		_lcontinua := .T. //Continua com tela aberta
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE015"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01501"/*cMsgId*/, "MGPE01501 - Não foram encontrados relógios ControId na seleção de relógios!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
	Return
EndIf

While .not. (_cAlias)->(Eof())
	If .not. _lShedule
		_nproce++
		_oself:IncRegua1("Atualizando equipamento " + StrZero(_nproce,3) + " de " + StrZero(_nconta,3))
	Else
		FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE015"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01502"/*cMsgId*/, "MGPE01502 - Atualizando equipamento " + StrZero(_nproce,3) + " de " + StrZero(_nconta,3)/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
	EndIf
 		
	cQuery := " SELECT count(*) TOT  from " 
	cQuery += retsqlname("SRA") + " SRA WHERE SRA.D_E_L_E_T_ = ' ' and SRA.RA_FILIAL = '" + AllTrim((_cAlias)->P0_FILIAL) +  "'" 
	cQuery += " AND SRA.RA_SITFOLH = 'D' AND ( SRA.RA_CATFUNC = 'M' OR SRA.RA_CATFUNC = 'E' ) AND SRA.RA_I_ZERS NOT LIKE '%" + AllTrim((_cAlias)->P0_RELOGIO) + "%'"
	cQuery += " AND (SRA.RA_I_CRACH > ' ' OR SRA.RA_I_ZERS > ' ' OR SRA.RA_CRACHA > ' ')"
 
	If Select(_cAlias2) > 0
		(_cAlias2)->( DBCloseArea() )
	EndIf

	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , _cAlias2 , .T. , .F. )
	
	_nconta2 := (_cAlias2)->TOT
	
	cQuery := " SELECT RA_I_CRACH, RA_PIS, RA_NOMECMP, RA_MAT, RA_CRACHA, RA_NOME, R_E_C_N_O_ RECN  from " 
	cQuery += retsqlname("SRA") + " SRA WHERE SRA.D_E_L_E_T_ = ' ' and SRA.RA_FILIAL = '" + AllTrim((_cAlias)->P0_FILIAL) +  "'" 
	cQuery += " AND SRA.RA_SITFOLH = 'D' AND ( SRA.RA_CATFUNC = 'M' OR SRA.RA_CATFUNC = 'E' ) AND RA_I_ZERS NOT LIKE '%" + AllTrim((_cAlias)->P0_RELOGIO) + "%'"
	cQuery += " AND (SRA.RA_I_CRACH > ' ' OR SRA.RA_I_ZERS > ' ' OR SRA.RA_CRACHA > ' ')"
 
	If Select(_cAlias2) > 0
		(_cAlias2)->( DBCloseArea() )
	EndIf

	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , _cAlias2 , .T. , .F. )
	
	_nproce3 := 0
    
    //===================================================================
    //Loop funcionários demitidos para zerar cracha
    //===================================================================
            
    While !((_cAlias2)->(Eof()))
		If .not. _lShedule
			_oself:IncRegua1("Atualizando equipamento " + StrZero(_nproce,3) + " de " + StrZero(_nconta,3) + " - Atualizando inativos "  + StrZero(_nproce3,5) + " de " + StrZero(_nconta2,5) + " - " + (_cAlias2)->RA_NOME  )
		EndIf
		
		_nproce3++
       
		If _nproce3 == 1 //Cria arquivo integra.txt
			If !(_lShedule)
				_cTemp := _cDirTemp+"integra.txt" 
				ferase(_cTemp)
				nHandle := FCreate(_cTemp)
			Else
				ferase(_cDirTemp+"integra.txt")
				nHandle := FCreate(_cDirTemp+"integra.txt")
			EndIf
		EndIf
       
       
      	FWrite(nHandle, AllTrim((_cAlias2)->RA_PIS)+CHR(13)+CHR(10))
      	FWrite(nHandle, AllTrim((_cAlias2)->RA_NOMECMP)+CHR(13)+CHR(10))
      	FWrite(nHandle, AllTrim((_cAlias2)->RA_MAT)+CHR(13)+CHR(10))
      	FWrite(nHandle,"1"+CHR(13)+CHR(10))
      	FWrite(nHandle, '9999' + AllTrim((_cAlias2)->RA_MAT) + CHR(13)+CHR(10))
      	FWrite(nHandle, '9' + AllTrim((_cAlias2)->RA_MAT) + CHR(13)+CHR(10))
       	FWrite(nHandle,"00"+CHR(13)+CHR(10))
       	
		//=======================================================================
		//Grava campo RA_I_ZERS
		//=======================================================================
		SRA->(DBGoTo((_cAlias2)->RECN))
		SRA->(RecLock("SRA",.F.))
		
		SRA->RA_I_ZERS := AllTrim(SRA->RA_I_ZERS) + "|" + AllTrim((_cAlias)->P0_RELOGIO)
		SRA->RA_I_CRACH := "  "
		SRA->RA_CRACHA := "   "
		
		SRA->(MSUnLock())
				
		(_cAlias2)->(DBSkip())
    EndDo 
	
	cQuery := " SELECT count(*) TOT  from " 
	cQuery += retsqlname("SRA") + " SRA WHERE SRA.D_E_L_E_T_ = ' ' and SRA.RA_FILIAL = '" + AllTrim((_cAlias)->P0_FILIAL) +  "'" 
	cQuery += " AND SRA.RA_SITFOLH <> 'D' AND ( SRA.RA_CATFUNC = 'M' OR SRA.RA_CATFUNC = 'E' ) AND SRA.RA_MAT >= '" + AllTrim(MV_PAR02) +  "' AND SRA.RA_MAT <= '" + AllTrim(MV_PAR03) + "'"
 
	If Select(_cAlias2) > 0
		(_cAlias2)->( DBCloseArea() )
	EndIf

	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , _cAlias2 , .T. , .F. )
	
	_nconta2 := (_cAlias2)->TOT
	
	cQuery := " SELECT RA_I_CRACH, RA_PIS, RA_NOMECMP, RA_MAT, RA_CRACHA, RA_NOME, RA_I_CIAD  from " 
	cQuery += retsqlname("SRA") + " SRA WHERE SRA.D_E_L_E_T_ = ' ' and SRA.RA_FILIAL = '" + AllTrim((_cAlias)->P0_FILIAL) +  "'" 
	cQuery += " AND SRA.RA_SITFOLH <> 'D' AND ( SRA.RA_CATFUNC = 'M' OR SRA.RA_CATFUNC = 'E' ) AND SRA.RA_MAT >= '" + AllTrim(MV_PAR02) +  "' AND SRA.RA_MAT <= '" + AllTrim(MV_PAR03) + "'"
 
	If Select(_cAlias2) > 0
		(_cAlias2)->( DBCloseArea() )
	EndIf

	DBUseArea( .T. , "TOPCONN" , TcGenQry(,,cQuery) , _cAlias2 , .T. , .F. )
			
    _nproce2 := _nproce3
    //===================================================================
    //Loop funcionários ativos
    //===================================================================
            
    While !((_cAlias2)->(Eof()))
	    If .not. _lShedule
    		_oself:IncRegua1("Atualizando equipamento " + StrZero(_nproce,3) + " de " + StrZero(_nconta,3) + " - Atualizando funcionario "  + StrZero(_nproce2,5) + " de " + StrZero(_nconta2,5) + " - " + (_cAlias2)->RA_NOME  )
		EndIf
       
    	_nproce2++      
       
    	If _nproce2 == 1 //Cria arquivo integra.txt
			If !(_lShedule)
				ferase(_cDirTemp+"integra.txt")
				nHandle := FCreate(_cDirTemp+"integra.txt")
			Else
				ferase(_cDirTemp+"integra.txt")
				nHandle := FCreate(_cDirTemp+"integra.txt")
	      	EndIf
      	EndIf
      
      	FWrite(nHandle, AllTrim((_cAlias2)->RA_PIS)+CHR(13)+CHR(10))
      	FWrite(nHandle, AllTrim((_cAlias2)->RA_NOMECMP)+CHR(13)+CHR(10))
      	FWrite(nHandle, AllTrim((_cAlias2)->RA_MAT)+CHR(13)+CHR(10))
      	FWrite(nHandle,"1"+CHR(13)+CHR(10))
      	FWrite(nHandle, AllTrim((_cAlias2)->RA_CRACHA)+CHR(13)+CHR(10))
 
   	    If .not. Empty(AllTrim((_cAlias2)->RA_I_CRACH))
        	nsegpar := Val(SubStr(AllTrim((_cAlias2)->RA_I_CRACH),5,5))
        	If AllTrim((_cAlias)->P0_I_CTRID) == 'A' .Or. ( AllTrim((_cAlias)->P0_I_CTRID) == 'W' .And.  AllTrim((_cAlias)->P0_I_TIPO) == "R" )
        		npripar := Val(SubStr(AllTrim((_cAlias2)->RA_I_CRACH),1,3)) * 65536  //codificação para o rep 1818 e rep web
        	Else
        		npripar := Val(SubStr(AllTrim((_cAlias2)->RA_I_CRACH),1,3)) * 65536 * 2  //codificação para a catraca  web
        	EndIf
        	FWrite(nHandle, AllTrim(Str(npripar+nsegpar))+CHR(13)+CHR(10) )
        Else
        	FWrite(nHandle, AllTrim((_cAlias2)->RA_MAT)+CHR(13)+CHR(10) )
        EndIf
  
        If AllTrim((_cAlias2)->RA_I_CIAD) == "S" //Usuário normal ou administrador
	       	FWrite(nHandle,"1"+CHR(13)+CHR(10))
        Else
         	FWrite(nHandle,"0"+CHR(13)+CHR(10))
        EndIf
        (_cAlias2)->(DBSkip())
    EndDo 
        
    If _nproce2 > 0
		FClose(nHandle)
		If .not. _lShedule
	 	  	U_ITMsg("Realizando comunicação com o equipamento " + AllTrim((_cAlias)->P0_RELOGIO) + ", confira o log na tela a seguir:","Atenção",,3)
 		    //Roda integrador para o arquvivo criado, se For schedule só vai gerar o arquivo que será lido pelo schedule do servidor
 	    	_oself:IncRegua1("Atualizando equipamento " + StrZero(_nproce,3) + " de " + StrZero(_nconta,3) + " - Enviando dados para o equipamento..."  )
 			shellexecute("Open", "C:\Windows\System32\cmd.exe"," /c "+_cDirTemp+"\LE1.BAT " +  AllTrim((_cAlias)->P0_I_IP),_cDirTemp,1)
		EndIf
    Else
 	  	If .not. _lShedule
			U_ITMsg("Nenhum funcionário encontrado com os parâmetros utilizados!","Atenção",,1)
			_lcontinua := .T. //Volta para tela inicial
			Return
    	Else
			FWLogMsg("INFO"/*cSeverity*/, /*cTransactionId*/, "MGPE015"/*cGroup*/, FunName()/*cCategory*/, /*cStep*/, "MGPE01503"/*cMsgId*/, "MGPE01503 - Nenhum funcionário encontrado com os parâmetros utilizados!"/*cMessage*/, /*nMensure*/, /*nElapseTime*/, /*aMessage*/)
    	EndIf
    EndIf
	(_cAlias)->(DBSkip())
EndDo

If .not. _lShedule
	_lcontinua := .F.
EndIf

Return
