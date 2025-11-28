/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
-------------------------------------------------------------------------------------------------------------------------------
 Jerry        | 17/04/2020 | Ajustes e inclusão de melhorias nas rotinas de tabelas de preços. Chamado 28370.
-------------------------------------------------------------------------------------------------------------------------------
 Julio Paz    | 29/03/2021 | Correções na gravação do Status de alteração da tabela de preços. Chamado 35936.
-------------------------------------------------------------------------------------------------------------------------------
 Igor Melgaço | 09/12/2021 | Correções na gravação do Status de alteração da tabela de preços. Chamado 37416.
==============================================================================================================================================================================================
Analista       - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==============================================================================================================================================================================================
Jerry Santiago - Julio Paz     - 11/08/24 - 15/09/25 - 50058   - Refazer Toda a Rotina de Gravação de Log de Alteração da Tabela de Preço. 
==============================================================================================================================================================================================
*/ 
//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "FWMVCDEF.CH"
#Include "TBICONN.CH"

/*
===============================================================================================================================
Programa----------: OMSA010
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/03/2018
===============================================================================================================================
Descrição---------: Pontos de entrada do formmodel do programa OMSA010 - Chamado 24295 
===============================================================================================================================
Parametros--------: Nenhum  
===============================================================================================================================
Retorno-----------: Nenhum 
===============================================================================================================================
*/
User Function OMSA010()
Local _aParam		:= If(Type("ParamIXB") == "U", Nil,ParamIXB) 
Local _nni			:= 0
Local _lAlterou     := .F.
Local _lExcluiu     := .F.
Local _lNovoItem    := .F.
Local _lSoAltCab    := .T.

If _aParam <> NIL

	_oObj		:= _aParam[01]
	_cIdPonto	:= _aParam[02]
	
	// Validacao de Ativacao
	_oModel 	:= FWModelActive()
	
	
	//Gravação de log
	If _cIdPonto == 'MODELPOS'

		_oModel 	:= FWModelActive()
		_oModelMAS 	:= _oModel:GetModel('DA0MASTER')
		_oModelDET 	:= _oModel:GetModel('DA1DETAIL')
		_nlinhas    := _oModelDET:GetQtdLine()
		_oObj		:= _aParam[01]
		_nOper		:= _oObj:GetOperation()
		_nposi := DA1->(Recno())
		
		
		//Inclusão ou cópia
		If _nOper == 3  
		
			//Varre linhas criando uma linha de log para cada linha do modelo
			For _nni := 1 to _nlinhas
			
				If !_oModelDET:IsDeleted(_nni)
				
					_oModelDET:GoLine(_nni) // _oModelDET::SetLine(_nni)

					RecLock("ZGS",.T.)
					ZGS->ZGS_FILIAL := xFilial("ZGS")
					ZGS->ZGS_ITEM   := _oModelDET:GetValue("DA1_ITEM")
					ZGS->ZGS_DATA   := Date()
					ZGS->ZGS_HORA   := Time()
					ZGS->ZGS_USER   := cUserName
					ZGS->ZGS_MODULO := funname()	
					ZGS->ZGS_CODTAB := _oModelMAS:GetValue("DA0_CODTAB")
					ZGS->ZGS_DATDE 	:= _oModelMAS:GetValue("DA0_DATDE")
					ZGS->ZGS_HORADE	:= _oModelMAS:GetValue("DA0_HORADE")
					ZGS->ZGS_DATATE	:= _oModelMAS:GetValue("DA0_DATATE")
					ZGS->ZGS_HORATE	:= _oModelMAS:GetValue("DA0_HORATE")
					ZGS->ZGS_CONDPG	:= _oModelMAS:GetValue("DA0_CONDPG")
					ZGS->ZGS_TPHORA	:= _oModelMAS:GetValue("DA0_TPHORA")
					ZGS->ZGS_ATIVO 	:= _oModelMAS:GetValue("DA0_ATIVO")
					ZGS->ZGS_I_FILI := _oModelMAS:GetValue("DA0_I_FILI")
   					ZGS->ZGS_PES1	:= _oModelMAS:GetValue("DA0_I_PES1")
					ZGS->ZGS_PES2	:= _oModelMAS:GetValue("DA0_I_PES2")
					ZGS->ZGS_PES3	:= _oModelMAS:GetValue("DA0_I_PES3")
					ZGS->ZGS_OBS	:= _oModelMAS:GetValue("DA0_I_OBS")

					ZGS->ZGS_DATDE 	:= _oModelMAS:GetValue("DA0_DATDE")
					ZGS->ZGS_HORADE	:= _oModelMAS:GetValue("DA0_HORADE")
					ZGS->ZGS_DATATE	:= _oModelMAS:GetValue("DA0_DATATE")
					ZGS->ZGS_HORATE	:= _oModelMAS:GetValue("DA0_HORATE")
					ZGS->ZGS_CONDPG	:= _oModelMAS:GetValue("DA0_CONDPG")
					ZGS->ZGS_TPHORA	:= _oModelMAS:GetValue("DA0_TPHORA")
					ZGS->ZGS_ATIVO 	:= _oModelMAS:GetValue("DA0_ATIVO")
					ZGS->ZGS_I_FILI := _oModelMAS:GetValue("DA0_I_FILI")

                    ZGS->ZGS_CODPRO	:= _oModelDET:GetValue("DA1_CODPRO")	  // Produto
                    ZGS->ZGS_OCODPR	:= _oModelDET:GetValue("DA1_CODPRO")	  // Produto ant
                    ZGS->ZGS_PRCVEN	:= _oModelDET:GetValue("DA1_PRCVEN")	  // Prc Venda
                    ZGS->ZGS_PRCMAX	:= _oModelDET:GetValue("DA1_PRCMAX")	  // Prc Max	
                    ZGS->ZGS_PRF1	:= _oModelDET:GetValue("DA1_I_PRF1")	  // Preco Fx 1	
                    ZGS->ZGS_PRF2	:= _oModelDET:GetValue("DA1_I_PRF2")	  // Preco Fx 2	
                    ZGS->ZGS_PRF3	:= _oModelDET:GetValue("DA1_I_PRF3")	  // Preco Fx 3
                    ZGS->ZGS_PMF1	:= _oModelDET:GetValue("DA1_I_PMF1")	  // Pr Min Fx1	
                    ZGS->ZGS_PMF2	:= _oModelDET:GetValue("DA1_I_PMF2")	  // Pr Min Fx2	
                    ZGS->ZGS_PMF3	:= _oModelDET:GetValue("DA1_I_PMF3")	  // Pr Min Fx3

					ZGS->ZGS_STATUS := "I" // Status de inclusão									
					ZGS->(MSUnLock())
					
				EndIf
				
			Next
			
		EndIf
		
		//===================================
		// Alteração e exclusão
		//===================================
		If _nOper == 4 .Or. _nOper == 5
		
            DA1->(DBSetOrder(2)) // DA1_FILIAL+DA1_CODPRO+DA1_CODTAB+DA1_ITEM
            //==================================================================================
			// Verifica se foi alterado apenas o cabeçalho para gerar apenas um registro de log.
			//==================================================================================
			For _nni := 1 to _nlinhas

				_oModelDET:GoLine(_nni) 

                _lAlterou  := .F.
                _lExcluiu  := .F.
                _lNovoItem := .F.
                _lSoAltCab := .T.
                If DA1->(DBSeek(xFilial("DA1")+_oModelDET:GetValue("DA1_CODPRO")+_oModelMAS:GetValue("DA0_CODTAB")+_oModelDET:GetValue("DA1_ITEM")))
                   If _oModelDET:IsDeleted(_nni) .Or. _nOper == 5
                      _lExcluiu := .T.
				   EndIf 
                   If _oModelMAS:GetValue("DA0_I_PES1") <> DA0->DA0_I_PES1 .Or. _oModelMAS:GetValue("DA0_I_PES2") <> DA0->DA0_I_PES2 .Or. _oModelMAS:GetValue("DA0_I_PES3") <> DA0->DA0_I_PES3 .Or. ;
                      _oModelMAS:GetValue("DA0_DATDE")  <> DA0->DA0_DATDE  .Or. _oModelMAS:GetValue("DA0_DATATE") <> DA0->DA0_DATATE .Or. _oModelMAS:GetValue("DA0_I_PES3") <> DA0->DA0_I_PES3 .Or. ;
					  _oModelMAS:GetValue("DA0_HORATE") <> DA0->DA0_HORATE .Or. _oModelMAS:GetValue("DA0_CONDPG") <> DA0->DA0_CONDPG .Or. _oModelMAS:GetValue("DA0_ATIVO")  <> DA0->DA0_ATIVO .Or. ;
					  _oModelMAS:GetValue("DA0_TPHORA") <> DA0->DA0_TPHORA .Or. _oModelMAS:GetValue("DA0_I_FILI") <> DA0->DA0_I_FILI .Or. _oModelDET:GetValue("DA1_PRCVEN") <> DA1->DA1_PRCVEN .Or. ;
					  _oModelDET:GetValue("DA1_PRCMAX") <> DA1->DA1_PRCMAX .Or. _oModelDET:GetValue("DA1_I_PRF1") <> DA1->DA1_I_PRF1 .Or. _oModelDET:GetValue("DA1_I_PRF2") <> DA1->DA1_I_PRF2 .Or. ;
					  _oModelDET:GetValue("DA1_I_PRF3") <> DA1->DA1_I_PRF3 .Or. _oModelDET:GetValue("DA1_I_PMF1") <> DA1->DA1_I_PMF1 .Or. _oModelDET:GetValue("DA1_I_PMF2") <> DA1->DA1_I_PMF2 .Or. ;
					  _oModelDET:GetValue("DA1_I_PMF3") <> DA1->DA1_I_PMF3

                      _lAlterou := .T.
					  
					  If _oModelDET:GetValue("DA1_PRCVEN") <> DA1->DA1_PRCVEN .Or. ;
					     _oModelDET:GetValue("DA1_PRCMAX") <> DA1->DA1_PRCMAX .Or. _oModelDET:GetValue("DA1_I_PRF1") <> DA1->DA1_I_PRF1 .Or. _oModelDET:GetValue("DA1_I_PRF2") <> DA1->DA1_I_PRF2 .Or. ;
					     _oModelDET:GetValue("DA1_I_PRF3") <> DA1->DA1_I_PRF3 .Or. _oModelDET:GetValue("DA1_I_PMF1") <> DA1->DA1_I_PMF1 .Or. _oModelDET:GetValue("DA1_I_PMF2") <> DA1->DA1_I_PMF2 .Or. ;
					     _oModelDET:GetValue("DA1_I_PMF3") <> DA1->DA1_I_PMF3
					     _lSoAltCab := .F.
					  EndIf 
								  
				   EndIf 

				EndIf 

            Next 
		    
            If _lAlterou .And. _lSoAltCab
 		       ZGS->(RecLock("ZGS",.T.))
			   ZGS->ZGS_FILIAL := xFilial("ZGS")
			   ZGS->ZGS_ITEM   := _oModelDET:GetValue("DA1_ITEM")
			   ZGS->ZGS_DATA   := Date()                            // Data da Gravação
			   ZGS->ZGS_HORA   := Time()                            // Hora da Gravação
			   ZGS->ZGS_USER   := cUserName                         // Login do usuário
			   ZGS->ZGS_MODULO := funname()	
			   ZGS->ZGS_CODTAB := _oModelMAS:GetValue("DA0_CODTAB") // Códido da Tabela 
			   ZGS->ZGS_OPES1	:= DA0->DA0_I_PES1
			   ZGS->ZGS_OPES2	:= DA0->DA0_I_PES2
			   ZGS->ZGS_OPES3	:= DA0->DA0_I_PES3
			   ZGS->ZGS_OOBS	:= DA0->DA0_I_OBS

			   ZGS->ZGS_ODATDE := DA0->DA0_DATDE
			   ZGS->ZGS_OHORAD := DA0->DA0_HORADE
			   ZGS->ZGS_ODATAT := DA0->DA0_DATATE
			   ZGS->ZGS_OHORAT := DA0->DA0_HORATE
			   ZGS->ZGS_OCONDP := DA0->DA0_CONDPG
			   ZGS->ZGS_OTPHOR := DA0->DA0_TPHORA
			   ZGS->ZGS_OATIVO := DA0->DA0_ATIVO
			   ZGS->ZGS_I_OFIL := DA0->DA0_I_FILI

			   ZGS->ZGS_DATDE 	:= _oModelMAS:GetValue("DA0_DATDE")
			   ZGS->ZGS_HORADE	:= _oModelMAS:GetValue("DA0_HORADE")
			   ZGS->ZGS_DATATE	:= _oModelMAS:GetValue("DA0_DATATE")
			   ZGS->ZGS_HORATE	:= _oModelMAS:GetValue("DA0_HORATE")
			   ZGS->ZGS_CONDPG	:= _oModelMAS:GetValue("DA0_CONDPG")
			   ZGS->ZGS_TPHORA	:= _oModelMAS:GetValue("DA0_TPHORA")
			   ZGS->ZGS_ATIVO 	:= _oModelMAS:GetValue("DA0_ATIVO")
			   ZGS->ZGS_I_FILI  := _oModelMAS:GetValue("DA0_I_FILI")
			   ZGS->(MSUnLock())

			Else 
               //===================================================================================
			   // Varre linhas criando uma linha de log para cada linha do modelo que foi alterada.
               //===================================================================================
			   For _nni := 1 to _nlinhas
			      
				   _oModelDET:GoLine(_nni) // _oModelDET::SetLine(_nni)

                   //======================================================
				   // Verifica se algum item foi alterado antes de criar um
				   // registro de log de alteração.
				   //======================================================
				   _lAlterou  := .F.
                   _lExcluiu  := .F.
                   _lNovoItem := .F.

                   If DA1->(DBSeek(xFilial("DA1")+_oModelDET:GetValue("DA1_CODPRO")+_oModelMAS:GetValue("DA0_CODTAB")+_oModelDET:GetValue("DA1_ITEM")))
                      If _oModelDET:IsDeleted(_nni) .Or. _nOper == 5
                         _lExcluiu := .T.
				      EndIf 
                      If _oModelMAS:GetValue("DA0_I_PES1") <> DA0->DA0_I_PES1 .Or. _oModelMAS:GetValue("DA0_I_PES2") <> DA0->DA0_I_PES2 .Or. _oModelMAS:GetValue("DA0_I_PES3") <> DA0->DA0_I_PES3 .Or. ;
                         _oModelMAS:GetValue("DA0_DATDE")  <> DA0->DA0_DATDE  .Or. _oModelMAS:GetValue("DA0_DATATE") <> DA0->DA0_DATATE .Or. _oModelMAS:GetValue("DA0_I_PES3") <> DA0->DA0_I_PES3 .Or. ;
					     _oModelMAS:GetValue("DA0_HORATE") <> DA0->DA0_HORATE .Or. _oModelMAS:GetValue("DA0_CONDPG") <> DA0->DA0_CONDPG .Or. _oModelMAS:GetValue("DA0_ATIVO")  <> DA0->DA0_ATIVO .Or. ;
					     _oModelMAS:GetValue("DA0_TPHORA") <> DA0->DA0_TPHORA .Or. _oModelMAS:GetValue("DA0_I_FILI") <> DA0->DA0_I_FILI .Or. _oModelDET:GetValue("DA1_PRCVEN") <> DA1->DA1_PRCVEN .Or. ;
					     _oModelDET:GetValue("DA1_PRCMAX") <> DA1->DA1_PRCMAX .Or. _oModelDET:GetValue("DA1_I_PRF1") <> DA1->DA1_I_PRF1 .Or. _oModelDET:GetValue("DA1_I_PRF2") <> DA1->DA1_I_PRF2 .Or. ;
					     _oModelDET:GetValue("DA1_I_PRF3") <> DA1->DA1_I_PRF3 .Or. _oModelDET:GetValue("DA1_I_PMF1") <> DA1->DA1_I_PMF1 .Or. _oModelDET:GetValue("DA1_I_PMF2") <> DA1->DA1_I_PMF2 .Or. ;
					     _oModelDET:GetValue("DA1_I_PMF3") <> DA1->DA1_I_PMF3
					  
					     _lAlterou := .T.
				      EndIf 
                   Else 
				      _lNovoItem := .T. 
				   EndIf 

                   If _lNovoItem .Or. _lExcluiu .Or. _lAlterou 
				      ZGS->(RecLock("ZGS",.T.))
				      ZGS->ZGS_FILIAL := xFilial("ZGS")
				      ZGS->ZGS_ITEM   := _oModelDET:GetValue("DA1_ITEM")
				      ZGS->ZGS_DATA   := Date()                            // Data da Gravação
				      ZGS->ZGS_HORA   := Time()                            // Hora da Gravação
				      ZGS->ZGS_USER   := cUserName                         // Login do usuário
				      ZGS->ZGS_MODULO := funname()	
				      ZGS->ZGS_CODTAB := _oModelMAS:GetValue("DA0_CODTAB") // Códido da Tabela 
				      ZGS->ZGS_OPES1	:= DA0->DA0_I_PES1
				      ZGS->ZGS_OPES2	:= DA0->DA0_I_PES2
				      ZGS->ZGS_OPES3	:= DA0->DA0_I_PES3
				      ZGS->ZGS_OOBS	:= DA0->DA0_I_OBS

				      ZGS->ZGS_ODATDE := DA0->DA0_DATDE
				      ZGS->ZGS_OHORAD := DA0->DA0_HORADE
				      ZGS->ZGS_ODATAT := DA0->DA0_DATATE
				      ZGS->ZGS_OHORAT := DA0->DA0_HORATE
			   	      ZGS->ZGS_OCONDP := DA0->DA0_CONDPG
				      ZGS->ZGS_OTPHOR := DA0->DA0_TPHORA
				      ZGS->ZGS_OATIVO := DA0->DA0_ATIVO
				      ZGS->ZGS_I_OFIL := DA0->DA0_I_FILI

				      ZGS->ZGS_DATDE 	:= _oModelMAS:GetValue("DA0_DATDE")
				      ZGS->ZGS_HORADE	:= _oModelMAS:GetValue("DA0_HORADE")
				      ZGS->ZGS_DATATE	:= _oModelMAS:GetValue("DA0_DATATE")
				      ZGS->ZGS_HORATE	:= _oModelMAS:GetValue("DA0_HORATE")
				      ZGS->ZGS_CONDPG	:= _oModelMAS:GetValue("DA0_CONDPG")
				      ZGS->ZGS_TPHORA	:= _oModelMAS:GetValue("DA0_TPHORA")
				      ZGS->ZGS_ATIVO 	:= _oModelMAS:GetValue("DA0_ATIVO")
				      ZGS->ZGS_I_FILI   := _oModelMAS:GetValue("DA0_I_FILI")
                      ZGS->ZGS_CODPRO	:= _oModelDET:GetValue("DA1_CODPRO")	  // Produto
                      ZGS->ZGS_OCODPR	:= _oModelDET:GetValue("DA1_CODPRO")	  // Produto ant
                      ZGS->ZGS_PRCVEN	:= _oModelDET:GetValue("DA1_PRCVEN")	  // Prc Venda
                      ZGS->ZGS_PRCMAX	:= _oModelDET:GetValue("DA1_PRCMAX")	  // Prc Max	
                      ZGS->ZGS_PRF1	    := _oModelDET:GetValue("DA1_I_PRF1")	  // Preco Fx 1	
                      ZGS->ZGS_PRF2	    := _oModelDET:GetValue("DA1_I_PRF2")	  // Preco Fx 2	
                      ZGS->ZGS_PRF3	    := _oModelDET:GetValue("DA1_I_PRF3")	  // Preco Fx 3
                      ZGS->ZGS_PMF1	    := _oModelDET:GetValue("DA1_I_PMF1")	  // Pr Min Fx1	
                      ZGS->ZGS_PMF2	    := _oModelDET:GetValue("DA1_I_PMF2")	  // Pr Min Fx2	
                      ZGS->ZGS_PMF3	    := _oModelDET:GetValue("DA1_I_PMF3")	  // Pr Min Fx3

				      // Se já existe linha no da1 grava valores antigos
				       
                      If _lAlterou .Or. _lExcluiu   //If DA1->(DBSeek(xFilial("DA1")+_oModelMAS:GetValue("DA0_CODTAB")+_oModelDET:GetValue("DA1_ITEM")))					   
                         ZGS->ZGS_ODATDE	:= DA0->DA0_DATDE     // Dt De ant
                         ZGS->ZGS_OHORAD	:= DA0->DA0_HORADE    // Hora de ant
                         ZGS->ZGS_ODATAT	:= DA0->DA0_DATATE    // Dt Ate Ant
                         ZGS->ZGS_OHORAT	:= DA0->DA0_HORATE    // Hora ate Ant
                         ZGS->ZGS_OATIVO	:= DA0->DA0_ATIVO     // Ativo ant
                         ZGS->ZGS_OPRCVE	:= DA1->DA1_PRCVEN    // Prc Venda Ant	
                         ZGS->ZGS_OPRCMA	:= DA1->DA1_PRCMAX    // Prc Mx Ant	
                         //ZGS->ZGS_PMF1	    := DA1->DA1_I_PRF1    // Preço Fx 1 Ant	// JPP TESTE -REVER ESTE TRECHO. DEVERIA SER ZGS_OPRF1
                         //ZGS->ZGS_PMF2	    := DA1->DA1_I_PRF2    // Preço Fx 2 Ant
                         //ZGS->ZGS_PMF3	    := DA1->DA1_I_PRF3    // Preço Fx 3 Ant
						 ZGS->ZGS_OPRF1     := DA1->DA1_I_PRF1    // Preço Fx 1 Ant
						 ZGS->ZGS_OPRF2     := DA1->DA1_I_PRF2    // Preço Fx 2 Ant
						 ZGS->ZGS_OPRF3     := DA1->DA1_I_PRF3    // Preço Fx 3 Ant
                         ZGS->ZGS_OPMF1	    := DA1->DA1_I_PMF1    // Pr Min Fx1 A
                         ZGS->ZGS_OPMF2	    := DA1->DA1_I_PMF2    // Pr Min Fx2 A
                         ZGS->ZGS_OPMF3	    := DA1->DA1_I_PMF3    // Pr Min Fx3 A	
                      EndIf
                      
					  // Se apagou a linha grava que foi deletada
				      If _lExcluiu  // _oModelDET:IsDeleted(_nni) .Or. _nOper == 5
				         ZGS->ZGS_STATUS := "X" // Status de Exclusão
				      Else 	
				         ZGS->ZGS_STATUS := "A" // Status de Alteração
				      EndIf
					  ZGS->(MSUnLock())

				   EndIf 
              Next

		   EndIf 	

		EndIf
	EndIf
	
EndIf

Return .T.  
