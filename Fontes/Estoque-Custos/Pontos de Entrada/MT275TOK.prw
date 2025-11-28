/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Walluer  |26/07/2024| Chamado 47697. Ajuste na validação para não bloquear caso o campo DD_MOTIVO For igual a 'VV'. 
Alex Wallauer |21/11/2024| Chamado 48952. Novo tratamento para os produtos com rastro / lotes.
Alex Wallauer |22/11/2024| Chamado 49204. Correção da validação do numero do lote para quando não #.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MT275TOK
Autor-------------: Igor Melgaço
Data da Criacao---: 20/05/2021
Descricao---------: PE na A275TudoOK() do Programa de Bloqueio de Lotes (MATA275.PRX) - Chamado: 34943
Caminho-----------: SIGAEST -> ATUALIZACOES -> MOVIMENTAOCES -> INTERNAS -> RASTREABILIDADE -> BLOQUEIO
Parametros--------: Nenhum
Retorno-----------: Logico validando o lançamento 
===============================================================================================================================
*/ 
User Function MT275TOK

Local _aArea	:= FWGetArea()
Local _aAreaSDD	:= SDD->(GetArea())
Local _aAreaSB8 := SB8->(GetArea())
Local _aAreaSD1 := SD1->(GetArea())
Local _aAreaSD5 := SD5->(GetArea())
Local _lRet	    := .T.  
Local _cNF      := ""
Local _cSerie   := ""
Local _cPed     := ""
Local _cItem    := ""
Local _cCodFor  := ""
Local _cNomFor  := ""
Local _cMsgRes1 := "Caso o lote enviado pelo fornecedor seja maior do que 11 caracteres, entrar em contato com o TI."
Local _cMsgRes2 := "Verifique o processo de compra, laudo ou NF e altere o Lote do Fornecedor antes da confirmação:"
Local _cMsgPro3 := "O Lote do Fornecedor inputado já existe no cadastro!"
Local _cMsgPed  := ""
Local _cMsgTit  := "Atenção"
Local _aTamNF   := TamSX3("D1_DOC")
Local _aTamSer  := TamSX3("D1_SERIE")
Local _aTamFil  := TamSX3("D1_FILIAL")
Local _aTamPed  := TamSX3("C7_NUM")
Local _aTamItem := TamSX3("C7_ITEM")

If FWIsInCallStack("A275LIBE")

	If "#" $ M->DD_LOTEFOR

		_cFilial  := Subs(SDD->DD_LOTEFOR,2,_aTamFil[1])
		_cPed     := Subs(SDD->DD_LOTEFOR,2+_aTamFil[1],_aTamPed[1])
		_cItem    := Subs(SDD->DD_LOTEFOR,2+_aTamFil[1]+_aTamPed[1],_aTamItem[1])
		
        //SDD->DD_OBSERVA contem SF1->F1_DOC + SF1->F1_SERIE + SF1->F1_FORNECE + SF1->F1_LOJA
		_cCodFor  := AllTrim(Subs(SDD->DD_OBSERVA, Len(SF1->F1_DOC + SF1->F1_SERIE)+1) )
		_cNomFor  := Posicione("SA2",1,xFilial("SA2") + _cCodFor ,"A2_NOME")
		_cNF      := Subs(SDD->DD_OBSERVA,1,_aTamNF[1])
		_cSerie   := Subs(SDD->DD_OBSERVA,1+_aTamNF[1],_aTamSer[1])

		_cMsgPed := CHR(13)+CHR(10) + CHR(13)+CHR(10) ;
		+  _cCodFor + " - " + _cNomFor + CHR(13)+CHR(10) ;
		+ "NF: " + _cNF + "   Serie: " + _cSerie + CHR(13)+CHR(10) ;
		+ "Lote: " + M->DD_LOTEFOR

		U_ITMsg("Não permitida confirmação pois o campo Lote do Fornecedor contem # que identifica que não foi preenchido pelo XML na entrada do documento do Fornecedor.", _cMsgTit, _cMsgRes2 + _cMsgPed,1)
		_lRet := .F.//************************* FALSO  *************************//
	
	ElseIf Empty(AllTrim(M->DD_LOTEFOR)) .Or. ( "#" $ SDD->DD_LOTECTL .And. Len(AllTrim(M->DD_LOTEFOR)) > 11 )

		U_ITMsg("Obrigatório o preenchimento do campo Lote do Fornecedor com ate 11 caracteres.", _cMsgTit,_cMsgRes1,1)
		_lRet := .F. //************************* FALSO  *************************//

	Else
	    _cDD_LOTEFOR := M->DD_LOTEFOR 
		 
		_cCodFor  := AllTrim(Subs(SDD->DD_OBSERVA, Len(SB8->B8_DOC + SB8->B8_SERIE)+1,6) )//DD_OBSERVA É = a SF1->F1_DOC + SF1->F1_SERIE + SF1->F1_FORNECE + SF1->F1_LOJA
		
		If "#" $ SDD->DD_LOTECTL//VERIFICA SE O QUE TAVA ANTES ERA COM #
		   
		   _cDD_LOTEFOR := AllTrim(M->DD_LOTEFOR)+_cCodFor//11 + 6 do cod do forn + uma letra = 18

		   SB8->(DBSetOrder(3)) // FILIAL+PRODUTO+LOCAL+LOTECTL+NUMLOTE+B8_DTVALID 
		   
		   If SB8->(DBSeek(xFilial("SB8")+SDD->DD_PRODUTO + SDD->DD_LOCAL + _cDD_LOTEFOR )) //+ SDD->DD_NUMLOTE
		      
			  _cCodigo:="A"
		      _cDD_LOTEFOR := AllTrim(M->DD_LOTEFOR)+_cCodigo+_cCodFor//11 + 6 do cod do forn + uma letra = 18

		      While SB8->(!Eof()) .And. SB8->(DBSeek(xFilial("SB8")+SDD->DD_PRODUTO + SDD->DD_LOCAL + _cDD_LOTEFOR )) //+ SDD->DD_NUMLOTE

			     If _cCodigo <> "Z"
				    _cCodigo:=Soma1(_cCodigo)
				 Else//SE For "Z"
			        Exit//_cCodigo:="AA"
				 EndIf
		         _cDD_LOTEFOR := AllTrim(M->DD_LOTEFOR)+_cCodigo+_cCodFor

		      EndDo
		   EndIf
		EndIf        
		
		M->DD_LOTEFOR:=_cDD_LOTEFOR

		// VERIFICA SE LOTE DO FORNECEDOR INPUTADO JÁ EXISTE NO CADASTRO
		If M->DD_LOTEFOR <> SDD->DD_LOTEFOR

			SB8->(DBSetOrder(3)) // FILIAL+PRODUTO+LOCAL+LOTECTL+NUMLOTE+B8_DTVALID 
			If !(SDD->DD_MOTIVO = 'VV') .AND.;
			    SB8->(DBSeek(xFilial("SB8")+SDD->DD_PRODUTO + SDD->DD_LOCAL + M->DD_LOTEFOR)) .AND.;
			    _cCodFor <> SB8->B8_CLIFOR//+SB8->B8_LOJA + SDD->DD_NUMLOTE
			
				_cFilial  := Subs(SDD->DD_LOTEFOR,2,_aTamFil[1])
				_cNomFor  := Posicione("SA2",1,xFilial("SA2") + SB8->B8_CLIFOR+SB8->B8_LOJA,"A2_NOME")
				_cNF      := Subs(SDD->DD_OBSERVA,1,_aTamNF[1])
				_cSerie   := Subs(SDD->DD_OBSERVA,1+_aTamNF[1],_aTamSer[1])
				_cMsgPro3 += CHR(13)+CHR(10) + "Nota Fiscal: " + SB8->B8_DOC  + " Serie: " + SB8->B8_SERIE

				_cMsgPed := CHR(13)+CHR(10) ;
				+  _cCodFor + "  " + _cNomFor + CHR(13)+CHR(10) ;
				+ "NF: " + _cNF + "   Serie: " + _cSerie + CHR(13)+CHR(10);
				+ "Lote: " + M->DD_LOTEFOR
				
				U_ITMsg(_cMsgPro3,_cMsgTit, _cMsgRes2 + _cMsgPed,1) // _cMsgPro3 = "O Lote do Fornecedor inputado já existe no cadastro!"
				_lRet  := .F.//************************* FALSO  *************************//
			
		    EndIf
		
	    EndIf

        // ************************************************ QUALQUER VALIDACAO DEVE SER ACIMA DESSE If ************************************************

		If _lRet

		   _cNF      := Subs(SDD->DD_OBSERVA,1,_aTamNF[1])
		   _cSerie   := Subs(SDD->DD_OBSERVA,1+_aTamNF[1],_aTamSer[1])
           _dDtvalid := CTOD("")

		   SB8->(DBSetOrder(3)) // FILIAL+PRODUTO+LOCAL+LOTECTL+NUMLOTE+B8_DTVALID
		   nRecno:=0
		   If SB8->(DBSeek(xFilial("SB8")+SDD->DD_PRODUTO + SDD->DD_LOCAL + SDD->DD_LOTECTL + SDD->DD_NUMLOTE))
              _dDtvalid := SB8->B8_DTVALID
		      SB8->(RecLock("SB8",.F.))
		      SB8->B8_LOTECTL := M->DD_LOTEFOR
		      SB8->B8_LOTEFOR := M->DD_LOTEFOR
		      SB8->(MSUnLock())
		      nRecno:=SB8->(RECNO())
		   EndIf

			// DD_OBSERVA = SF1->F1_DOC + SF1->F1_SERIE + SF1->F1_FORNECE + SF1->F1_LOJA
			SD1->(DBSetOrder(17)) 
			             // SD1->D1_FILIAL + D1_DOC+D1_SDOC+D1_FORNECE+D1_LOJA       + SD1->D1_COD     + SD1->D1_LOTECTL + SD1->D1_NUMLOTE + DToS(D1_DTVALID)
			If SD1->(DBSeek(SDD->DD_FILIAL + AllTrim(SDD->DD_OBSERVA)                + SDD->DD_PRODUTO + SDD->DD_LOTECTL + SDD->DD_NUMLOTE ))
				While    SD1->D1_FILIAL + SD1->(D1_DOC+D1_SDOC+D1_FORNECE+D1_LOJA)+ SD1->D1_COD     + SD1->D1_LOTECTL + SD1->D1_NUMLOTE == ;
						    SDD->DD_FILIAL + AllTrim(SDD->DD_OBSERVA)                + SDD->DD_PRODUTO + SDD->DD_LOTECTL + SDD->DD_NUMLOTE  .And. SD1->(!Eof())
				   If SD1->D1_LOCAL == SDD->DD_LOCAL//O Local NAO ESTA NO INDICE, MAS PODE SER DIFERENTE COMO O MESMO LOTE
			          SD1->(RecLock("SD1",.F.))
			          SD1->D1_LOTECTL := M->DD_LOTEFOR
			          SD1->D1_LOTEFOR := M->DD_LOTEFOR
			          SD1->(MSUnLock())
				   EndIf
				   SD1->(DBSkip())
				EndDo
			EndIf

			SD5->(DBSetOrder(2)) 
			             // SD5->D5_FILIAL + SD5->D5_PRODUTO + SD5->D5_LOCAL + SD5->D5_LOTECTL + SD5->D5_NUMLOTE + D5_NUMSEQ
			If SD5->(DBSeek(xFilial("SD5") + SDD->DD_PRODUTO + SDD->DD_LOCAL + SDD->DD_LOTECTL + SDD->DD_NUMLOTE ))
				While SD5->D5_FILIAL + SD5->D5_PRODUTO + SD5->D5_LOCAL + SD5->D5_LOTECTL + SD5->D5_NUMLOTE == ;
						 SDD->DD_FILIAL + SDD->DD_PRODUTO + SDD->DD_LOCAL + SDD->DD_LOTECTL + SDD->DD_NUMLOTE .And. SD5->(!Eof())
					SD5->(RecLock("SD5",.F.))
					SD5->D5_LOTECTL := M->DD_LOTEFOR
					SD5->D5_LOTEFOR := M->DD_LOTEFOR
					SD5->(MSUnLock())
					SD5->(DBSkip())
				EndDo
			EndIf
			
			M->DD_LOTECTL := M->DD_LOTEFOR

		EndIf

	EndIf

EndIf

FWRestArea(_aArea)
FWRestArea(_aAreaSDD)
FWRestArea(_aAreaSB8)
FWRestArea(_aAreaSD1)
FWRestArea(_aAreaSD5)

Return (_lRet)
