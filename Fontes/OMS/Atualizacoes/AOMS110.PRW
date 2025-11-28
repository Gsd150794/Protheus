/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |11/04/2019| Chamado 28694. Validações de bloqueio logístico
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================

#Include "TOTVS.ch"  
#Include "RWMAKE.CH"             

/*
===============================================================================================================================
Programa----------: AOMS110
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/09/2018
===============================================================================================================================
Descrição---------: Tela de vinculo de pedido de vendas - Chamado 25661
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS110()
Local _cperg := "AOMS110"
Local _cCodUsr	:= RetCodUsr()
Local _nposori := SC5->(Recno())

//Valida bloqueio logístico
If SC5->C5_I_BLOG == "S"

	ZZL->(DBSetOrder(3))
	If !(ZZL->(DBSeek(xFilial("ZZL") + RetCodUsr()))) .Or. ZZL->ZZL_PVLOG != "S"	

		U_MT_ITMSG("Pedido em Planejamento Logístico, operação não permitida, Por favor entrar em contato com área de Logística","Atenção",,1)
		Return

	EndIf

EndIf

//Valida se pedido pode ser alterado
SC9->( DBSetOrder(1) )
If SC9->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) ) 
      While SC9->( !Eof() ) .And. SC9->( C9_FILIAL + C9_PEDIDO ) == SC5->C5_FILIAL + SC5->C5_NUM
          If !Empty(SC9->C9_NFISCAL)
              U_MT_ITMSG("Pedido selecionado "+AllTrim(SC5->C5_NUM)+" já tem Nota: "+SC9->C9_NFISCAL,"Atenção!","Estorne a Nota "+AllTrim(SC9->C9_NFISCAL)+" ou selecione outro pedido",1)
              Return
          EndIf 
          If !Empty(SC9->C9_CARGA)
              U_MT_ITMSG("Pedido selecionado "+AllTrim(SC5->C5_NUM)+" já esta na carga: "+SC9->C9_CARGA,"Atenção!","Estorne a carga "+AllTrim(SC9->C9_CARGA)+" ou selecione outro pedido",1)
              Return
          EndIf 
           SC9->(DBSkip())
	   EndDo
EndIf

//Se o pedido já tiver pedido vinculado verifica se o pedido vinculado pode ser alterado
_nposori := SC5->(Recno())
_cpedido := SC5->C5_NUM

SC5->(DBSetOrder(1))
If SC5->(DBSeek(SC5->C5_FILIAL+SC5->C5_I_PEVIN))

	//Valida bloqueio logístico
	If SC5->C5_I_BLOG == "S"

		ZZL->(DBSetOrder(3))
		If !(ZZL->(DBSeek(xFilial("ZZL") + RetCodUsr()))) .Or. ZZL->ZZL_PVLOG != "S"	

	        U_MT_ITMSG("Pedido selecionado "+AllTrim(_cpedido)+" possui pedido vinculado, " + SC5->C5_NUM + " e em Planejamento Logístico. Por favor entrar em contato com área de Logística. ",;
              													"Atenção!","Retire o Planejamento Logístico ou selecione outro pedido",1)
   			Return

		EndIf

	EndIf

	SC9->( DBSetOrder(1) )
	If SC9->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) ) 
      While SC9->( !Eof() ) .And. SC9->( C9_FILIAL + C9_PEDIDO ) == SC5->C5_FILIAL + SC5->C5_NUM
          If !Empty(SC9->C9_NFISCAL)
              U_MT_ITMSG("Pedido selecionado "+AllTrim(_cpedido)+" possui pedido vinculado, " + SC5->C5_NUM + " já tem Nota: "+SC9->C9_NFISCAL,;
              													"Atenção!","Estorne a Nota "+AllTrim(SC9->C9_NFISCAL)+" ou selecione outro pedido",1)
              Return
          EndIf 
          If !Empty(SC9->C9_CARGA)
              U_MT_ITMSG("Pedido selecionado "+AllTrim(_cpedido)+" possui pedido vinculado, " + SC5->C5_NUM + " já esta na carga: "+SC9->C9_CARGA,;
              "Atenção!","Estorne a carga "+AllTrim(SC9->C9_CARGA)+" ou selecione outro pedido",1)
              Return
          EndIf 
           SC9->(DBSkip())
	   EndDo
	EndIf

EndIf

SC5->(DBGoTo(_nposori))

If SC5->C5_I_ENVRD != "V"

	_cperg := "AOMS1102"
	
EndIf

Pergunte(_cperg,.F.)
MV_PAR01 := SC5->C5_I_PEVIN
MV_PAR02 := 1

If Pergunte(_cperg)

	SC5->(DBGoTo(_nposori))
	_cpedido := SC5->C5_NUM
	
	//valida para não escolher o próprio pedido
	If AllTrim(SC5->C5_NUM) == AllTrim(MV_PAR01)
	
		U_ITMsg("Não é possível vincular um pedido a si mesmo","Atenção",,1)
		Return
		
	EndIf

	//Se o MV_PAR01 estiver em branco pergunta se quer remover vinculo do pedido de vendas
	If Empty(MV_PAR01) .And. Empty(SC5->C5_I_PEVIN)
	
		U_ITMsg("Pedido atual não tem vínculo registrado, obrigatório indicar um vínculo","Atenção","Preencha o campo de pedido à vincular",1)
		Return
		
	ElseIf Empty(MV_PAR01)
	
		If !(U_ITMsg("Deseja limpar vínculo do pedido " +SC5->C5_NUM + " com o pedido "+ SC5->C5_I_PEVIN + "?","Atenção",,2,2,2))
		
			U_ITMsg("Processo cancelado","Atenção",,1)
			Return
		
		EndIf
		
	EndIf

	//Valida se pedido selecionado pode ser vinculado
     If !Empty(MV_PAR01) .And. !SC5->(DBSeek(xFilial()+MV_PAR01))
         U_MT_ITMSG("O Pedido vinculado "+MV_PAR01+" não existe.","PEDIDO VINCULADO",;
		            "Selecione um Pedido cadastrado",1)

		 Return
		       
     ElseIf !Empty(MV_PAR01) .And. !Empty(SC5->C5_I_PEVIN) .And. !(SC5->C5_I_PEVIN == _CPEDIDO)
      
         U_MT_ITMSG("O Pedido selecionado " + MV_PAR01 + " já esta vinculado com outro Pedido: "+SC5->C5_I_PEVIN,"PEDIDO VINCULADO",;
		            "Selecione outro um Pedido",1)

		 Return

	 ElseIf SC5->C5_I_BLOG == "S"

		ZZL->(DBSetOrder(3))
		If !(ZZL->(DBSeek(xFilial("ZZL") + RetCodUsr()))) .Or. ZZL->ZZL_PVLOG != "S"	

	        U_MT_ITMSG("Pedido selecionado "+AllTrim(SC5->C5_NUM)+" em Planejamento Logístico!",;
              													"Atenção!","Retire do Planejamento Logístico ou selecione outro pedido",1)
   			Return

		EndIf

     ElseIf !Empty(MV_PAR01)   //ve se tem carga e nota
      
         SC9->( DBSetOrder(1) )
         If SC9->( DBSeek( SC5->C5_FILIAL + MV_PAR01 ) ) 
	        While SC9->( !Eof() ) .And. SC9->( C9_FILIAL + C9_PEDIDO ) == SC5->C5_FILIAL + MV_PAR01
	           If !Empty(SC9->C9_NFISCAL)
                  U_MT_ITMSG("Pedido Vinculado "+AllTrim(MV_PAR01)+" já tem Nota: "+SC9->C9_NFISCAL,"Atenção!","Estorne a Nota "+AllTrim(SC9->C9_NFISCAL)+" ou selecione outro pedido",1)
                  Return
	           EndIf 
	           If !Empty(SC9->C9_CARGA)
                  U_MT_ITMSG("Pedido selecionado "+AllTrim(MV_PAR01)+" já esta na carga: "+SC9->C9_CARGA,"Atenção!","Estorne a carga "+AllTrim(SC9->C9_CARGA)+" ou selecione outro pedido",1)
                  Return
	           EndIf 
	           SC9->(DBSkip())
	        EndDo
         EndIf
      
     EndIf
	
	SC5->(DBGoTo(_nposori))
	
	BEGIN TRANSACTION

	//Se possui um vinculo atual diferente do indicado no MV_PAR01 apaga vinculo do pedido vinculado
	If !Empty(SC5->C5_I_PEVIN) .And. AllTrim(MV_PAR01) !=  AllTrim(SC5->C5_I_PEVIN) .And. SC5->(DBSeek(SC5->C5_FILIAL+SC5->C5_I_PEVIN))
    
		_aLogSC5 := U_ITIniLog( 'SC5')
    
		RecLock("SC5",.F.)
		SC5->C5_I_PEVIN := ""
		If SC5->C5_I_ENVRD == "V" .And. MV_PAR02 = 1 
			SC5->C5_I_ENVRD := "R"
			SC5->C5_I_DTRET := Date() - 1
			SC5->C5_I_HRRET := Time()
			_CMENS := " - Pedido vinculado anteriormente" + SC5->C5_NUM + " liberado para envio ao RDC."
		EndIf
		SC5->(MSUnLock())
		
		//Grava log de alteração de tabela
         U_ITGrvLog( _aLogSC5 , "SC5" , 1 , SC5->( C5_FILIAL + C5_NUM ) ,"A" , _cCodUsr , Date() , Time() )    
		
		
		//Verifica se o pedido de vendas existe no RDC 
		_cQry := "select pedido,pedid2 from rdcitl.TGA447 WHERE  "
		_cQry += " pedido = '" + AllTrim(SC5->C5_NUM) + "'"

		If Select ("TRBPED") > 0

			DBSelectArea("TRBPED")
			TRBPED->(DBCloseArea())
	
		EndIf

		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBPED" , .T., .F. )

		DBSelectArea("TRBPED")

		//se existe atualiza campo pedid2
		If !TRBPED->(Eof())
		
			_cQry := " UPDATE rdcitl.TGA447 SET pedid2 = ''"
			_cQry += " WHERE pedido = '" + AllTrim(SC5->C5_NUM) + "'"
						
			_nres := TCSqlExec(_cQry)
		
		ElseIf MV_PAR02 = 1
		
			//Se não existe marca o pedido para ser enviado ao RDC
			RecLock("SC5",.F.)
			SC5->C5_I_ENVRD := "R"
			SC5->C5_I_DTRET := Date() - 1
			SC5->C5_I_HRRET := Time()
			SC5->(MSUnLock())
				
		EndIf
		
		If Select ("TRBPED") > 0

			DBSelectArea("TRBPED")
			TRBPED->(DBCloseArea())
	
		EndIf
		
	EndIf

	SC5->(DBGoTo(_nposori))
	_CMENS := ""
	
	_aLogSC5 := U_ITIniLog( 'SC5')
	
	RecLock("SC5",.F.)
	//Se libera para envio ao RDC marca como recuperado em data anterior para o schedule gerar muro e enviar
	If SC5->C5_I_ENVRD == "V" .And. MV_PAR02 = 1
		SC5->C5_I_ENVRD := "R"
    	SC5->C5_I_DTRET := Date() - 1
    	SC5->C5_I_HRRET := Time()
    	_CMENS := " - Pedido " + SC5->C5_NUM + " liberado para envio ao RDC."
    EndIf
    
    SC5->C5_I_PEVIN := AllTrim(MV_PAR01)
    
    SC5->(MSUnLock())
    
    //Grava log de alteração de tabela
     U_ITGrvLog( _aLogSC5 , "SC5" , 1 , SC5->( C5_FILIAL + C5_NUM ) ,"A" , _cCodUsr , Date() , Time() )    
        
    //Verifica se o pedido de vendas existe no RDC 
	_cQry := "select pedido,pedid2 from rdcitl.TGA447 WHERE  "
	_cQry += " pedido = '" + AllTrim(SC5->C5_NUM) + "'"

	If Select ("TRBPED") > 0

		DBSelectArea("TRBPED")
		TRBPED->(DBCloseArea())
	
	EndIf

	dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBPED" , .T., .F. )

	DBSelectArea("TRBPED")

	//se existe atualiza campo pedid2
	If !TRBPED->(Eof())
		
		_cQry := " UPDATE rdcitl.TGA447 SET pedid2 = '" + AllTrim(SC5->C5_I_PEVIN) + "'"
		_cQry += " WHERE pedido = '" + AllTrim(SC5->C5_NUM) + "'"
						
		_nres := TCSqlExec(_cQry)
		
	ElseIf MV_PAR02 = 1
		
		//Se não existe marca o pedido para ser enviado ao RDC
		RecLock("SC5",.F.)
		SC5->C5_I_ENVRD := "R"
		SC5->C5_I_DTRET := Date() - 1
		SC5->C5_I_HRRET := Time()
		SC5->(MSUnLock())
				
	EndIf
		
	If Select ("TRBPED") > 0

		DBSelectArea("TRBPED")
		TRBPED->(DBCloseArea())
	
	EndIf
    
    
    //Atualiza pedido vinculado
    If !Empty(MV_PAR01) 
    	SC5->(DBSeek(SC5->C5_FILIAL+SC5->C5_I_PEVIN))
    	
    	_aLogSC5 := U_ITIniLog( 'SC5')
    	
    	RecLock("SC5",.F.)
    	SC5->C5_I_PEVIN := _cpedido
    	//Se libera para envio ao RDC marca como recuperado em data anterior para o schedule gerar muro e enviar
    	If SC5->C5_I_ENVRD == "V" .And. MV_PAR02 = 1
    		SC5->C5_I_ENVRD := "R"
    		SC5->C5_I_DTRET := Date() - 1
    		SC5->C5_I_HRRET := Time()
    		_CMENS := " - Pedido " + SC5->C5_NUM + " vinculado também liberado para envio ao RDC."
    	EndIf
    	SC5->(MSUnLock())
    	
    	//Grava log de alteração de tabela
         U_ITGrvLog( _aLogSC5 , "SC5" , 1 , SC5->( C5_FILIAL + C5_NUM ) ,"A" , _cCodUsr , Date() , Time() )    
           
    	//Verifica se o pedido de vendas existe no RDC 
		_cQry := "select pedido,pedid2 from rdcitl.TGA447 WHERE  "
		_cQry += " pedido = '" + AllTrim(SC5->C5_NUM) + "'"

		If Select ("TRBPED") > 0

			DBSelectArea("TRBPED")
			TRBPED->(DBCloseArea())
	
		EndIf

		dbUseArea( .T. , "TOPCONN" , TcGenQry(,, _cQry ) , "TRBPED" , .T., .F. )

		DBSelectArea("TRBPED")

		//se existe atualiza campo pedid2
		If !TRBPED->(Eof())
		
			_cQry := " UPDATE rdcitl.TGA447 SET pedid2 = '" + AllTrim(SC5->C5_I_PEVIN) + "'"
			_cQry += " WHERE pedido = '" + AllTrim(SC5->C5_NUM) + "'"
						
			_nres := TCSqlExec(_cQry)
		
		ElseIf MV_PAR02 = 1
		
			//Se não existe marca o pedido para ser enviado ao RDC
			RecLock("SC5",.F.)
			SC5->C5_I_ENVRD := "R"
			SC5->C5_I_DTRET := Date() - 1
			SC5->C5_I_HRRET := Time()
			SC5->(MSUnLock())
				
		EndIf
		
		If Select ("TRBPED") > 0

			DBSelectArea("TRBPED")
			TRBPED->(DBCloseArea())
	
		EndIf
    	    	
    EndIf
    
    END TRANSACTION
    
    SC5->(DBGoTo(_nposori))

    U_ITMsg("Vínculo do pedido " + SC5->C5_NUM + " atualizado com sucesso!","Atenção","Pedido vinculado: " + SC5->C5_I_PEVIN + _CMENS,3)

Else

	U_ITMsg("Encerrado sem alterações","Atenção",,1)
	
EndIf

Return
