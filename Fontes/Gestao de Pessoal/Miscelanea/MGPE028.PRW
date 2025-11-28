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
Programa----------: MGPE028
Autor-------------: Igor Melgaço
Data da Criacao---: 15/01/2025
Descrição---------: Rotina de verificação de caracteres inválidos na SQ3 - Chamado 49377
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MGPE028()

    FWMsgRun(,{|oproc|  MGPE028P(oProc) },'Aguarde processamento...','Lendo dados...')

Return

/*
===============================================================================================================================
Programa----------: MGPE028P
Autor-------------: Igor Melgaço
Data da Criacao---: 15/01/2025
Descrição---------: Rotina processamento de verificação de caracteres inválidos 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MGPE028P(oProc) As Logical
Local aCampos  := { {"Q3_DESCSUM",""} , {"Q3_MEMO1","Q3_DESCDET"} , {"Q3_MEMO2","Q3_DRESP"} , {"Q3_MEMO3","Q3_DRELINT"}} As Array
Local i := 0 As Numeric
Local _aErro := {} As Array
Local _aCab := {"","Filial","Cargo","Descrição Sumária","CC","Campo","Mensagem"} As Array
Local _cTitAux := "Log de processamento de verificação da SQ3" As Char
Local _cMsgTop := "Verifique as falhas de gravações de acordo com o Log:" As Char

DBSelectArea("SQ3")
DBSetOrder(1)
SQ3->(DBGoTop())
While SQ3->(!Eof())

	oProc:cCaption := ("Lendo Filial "+SQ3->Q3_FILIAL+" Cargo "+SQ3->Q3_CARGO+" - "+AllTrim(SQ3->Q3_DESCSUM)+" CC"+SQ3->Q3_CC)

	For i := 1 to Len(aCampos)

		If aCampos[i,1] == "Q3_MEMO1" .Or. aCampos[i,1] == "Q3_MEMO2" .Or. aCampos[i,1] == "Q3_MEMO3"
			&("_c"+aCampos[i,1]) := MSMM(SQ3->&(aCampos[i,2]),80,,,,,,"SQ3",,"RDY")
		Else
			&("_c"+aCampos[i,1]) := SQ3->&(aCampos[i,1])
		EndIf

		&("_cTMP"+aCampos[i,1]) := &("_c"+aCampos[i,1]) 
				// CRMA980VCP(cCampo               ,cDesc       ,lSubstitui,lAuto)
		_lRet := U_CRMA980VCP(@&("_c"+aCampos[i,1]),aCampos[i,1],.F.,.T.)
		
		If _lRet

			If &("_c"+aCampos[i,1]) <> &("_cTMP"+aCampos[i,1])
				
				If aCampos[i,1] == "Q3_MEMO1" .Or. aCampos[i,1] == "Q3_MEMO2" .Or. aCampos[i,1] == "Q3_MEMO3"
			       	RecLock("SQ3", .F.)
					//MSMM(SQ3->Q3_DRELINT,80,,,,,,"SQ3",,"RDY")
		            MSMM(, 80, , &("_c"+aCampos[i,1]), 1, , , "SQ3", aCampos[i,1])
		        	SQ3->(MSUnLock())
				Else
					
					RecLock("SQ3",.F.)
					SQ3->&(aCampos[i,1]) := &("_c"+aCampos[i,1])
					MSUnLock()
				EndIf
				aAdd(_aErro,{.T.,SQ3->Q3_FILIAL,SQ3->Q3_CARGO,SQ3->Q3_DESCSUM,SQ3->Q3_CC,aCampos[i,1],"Há caracteres inválidos no campo"})
			EndIf
		Else
			aAdd(_aErro,{.F.,SQ3->Q3_FILIAL,SQ3->Q3_CARGO,SQ3->Q3_DESCSUM,SQ3->Q3_CC,aCampos[i,1],"Há caracteres inválidos no campo"})
		EndIf

	Next
	SQ3->(DBSkip())
EndDo

If Len(_aErro) > 0
	//ITListBox( _cTitAux , _aHeader , _aCols , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda                      ,_lHasOk,_bHeadClk,_aSX1)
	U_ITListBox( _cTitAux , _aCab     , _aErro   , .F.      , 2      , _cMsgTop ,          ,         ,         ,     ,        ,          ,       ,         ,          ,           , {|C,L|U_MGPE026L(C,L)}        , .F.   ,         ,     )
EndIf

Return
