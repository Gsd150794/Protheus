/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz     |27/08/2018| Chamado 26160. Correções em consulta específica para listar dados de todas filiais.
Lucas Borges  |08/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Julio Paz     |21/01/2020| Chamado 31220. Alterar a consulta específica Rel.Conf.Cod.ajuste p/permitir digitar o cód.Apuração.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: XFUNFIS
Autor-------------: Erich Buttner
Data da Criacao---: 16/05/2013
Descrição---------: Rotinas genéricas para utilização nos desenvolvimentos do módulo Fiscal
===============================================================================================================================
*/

/*
===============================================================================================================================
Programa--------: CODAJUS
Autor-----------: Erich Buttner
Data da Criacao-: 16/05/2013
Descrição-------: Monta Tela para consulta de Contas de Ajustes
Parametros------: 
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function CODAJUS()

Local i := 0
Local n := 0
Local aAjust := {}
Local _nI 
Local _cCodAjuste
Local _nRegAtu := CC7->(Recno())

Private nTam       	:= 0
Private nMaxSelect 	:= 0
Private aCat      	:= {}
Private MvRet     	:= AllTrim(ReadVar())
Private MvPar     	:= ""
Private cTitulo   	:= ""
Private MvParDef  	:= ""


#IFDEF WINDOWS
	oWnd := GetWndDefault()
#EndIf

//Realizado a inclusão dos codigos abaixo, utilzado no Relatório RFIS005
If IsInCallStack("U_RFIS005")

    CC7->(DBGoTop())	
    While ! CC7->(Eof())
       // Filtra dados das filiais
       If !CC7->CC7_FILIAL $ MV_PAR01
          CC7->(DBSkip())
          Loop
       EndIf
    
       If !Empçty(CC7->CC7_CODLAN)
          _cCodAjuste := U_ItKey(CC7->CC7_CODLAN,"CC7_CODLAN")
       ElseIf !Empçty(CC7->CC7_CLANAP)
          _cCodAjuste := U_ItKey(CC7->CC7_CLANAP,"CC7_CODLAN")
       Else
          CC7->(DBSkip())
          Loop
       EndIf
    
       _nI :=aScan(aAjust,_cCodAjuste )
       If _nI == 0
          aAdd(aAjust,_cCodAjuste)
       EndIf
       
       CC7->(DBSkip()) 
    EndDo
Else
	aAdd(aAjust,"RO40000001") // ALTERADO POR ERICH BUTTNER DIA 11/06/13 - INCLUIR 2 CODIGOS NOVOS
	aAdd(aAjust,"RO40000002") // ALTERADO POR ERICH BUTTNER DIA 11/06/13 - INCLUIR 2 CODIGOS NOVOS
	aAdd(aAjust,"GO10009029")
	aAdd(aAjust,"GO000019  ")
EndIf

//Tratamento para carregar variaveis da lista de opcoes
nTam:=10
nMaxSelect := 6 //75 / 7
cTitulo := "Codigo Ajuste"

For n := 1 to Len(aAjust) 
	MvParDef += aAjust[n] // ALTERADO POR ERICH BUTTNER DIA 11/06/13 - INCLUIR 2 CODIGOS NOVOS//AllTrim(aAjust[n])
Next n 

//=====================================================================
// Trativa abaixo para no caso de uma alteracao do campo trazer todos |
// os dados que foram selecionados anteriormente.                     |
//=====================================================================

If Len(AllTrim(&MvRet)) == 0
	
	MvPar:= AllTrim(StrTran(&MvRet,";",""))
	&MvRet:= AllTrim(StrTran(&MvRet,";",""))
	
Else
	
	MvPar:= AllTrim(StrTran(&MvRet,";","/"))
	
EndIf


//=====================================================================
// Somente altera o conteudo caso o usuario clique no botao ok 		  |
//=====================================================================
 
nTam:=10
nMaxSelect := 6 
&MvRet := &MvRet +Space(nTam * nMaxSelect + nMaxSelect) 
&MvRet := SubStr(&MvRet,1, (nTam * nMaxSelect + nMaxSelect)) 

//Executa funcao que monta tela de opcoes
If f_Opcoes(@MvPar,cTitulo,aAjust,MvParDef,12,49,.F.,nTam,nMaxSelect)
	
   //Tratamento para separar retorno com barra ";"
   &MvRet := ""  
   For i:=1 to Len(MvPar) step nTam
       If !(SubStr(MvPar,i,1) $ " |*")
	      &MvRet  += SubStr(MvPar,i,nTam) + ";"
	   EndIf
   Next i

   //Trata para tirar o ultimo caracter
   &MvRet := SubStr(&MvRet,1,Len(&MvRet)-1)
   &MvRet := &MvRet + Space(100)
   &MvRet := SubStr(&MvRet,1,99)
EndIf

CC7->(DBGoTo(_nRegAtu))

Return(.T.)

/*
===============================================================================================================================
Programa--------: ICompFis
Autor-----------: Erich Buttner
Data da Criacao-: 27/02/2013
Descrição-------: Cadastra os complementos de notas fiscais de entrada e de saida com as informacoes necessarias ao Sped.
Parâmetros------:	_cTpMov - tipo do movimento
					_cDoc - documento na tabela CDT
					_cSerie - série do documento
					_cCliFor - código de cliente/fornecedor
					_cLoja - loja do cliente/fornecedor
					_cTpFrete - tipo de frete
					_cMensFis  - mensagem fiscal a ser gravada
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ICompFis(_cTpMov,_cDoc,_cSerie,_cCliFor,_cLoja,_cTpFrete,_cMensFis)

Local _aArea 	:= FWGetArea()
Local _aAreaCCE := CCE->(GetArea())
Local _aAreaCDT := CDT->(GetArea())
Local _aAreaCDD := CDD->(GetArea())
Local _aAreaSF4 := SF4->(GetArea())
Local _aAreaSD1 := SD1->(GetArea())
Local _aAreaSD2 := SD2->(GetArea())
Local _aAreaSF1 := SF1->(GetArea())
Local _aAreaSF2 := SF2->(GetArea())
Local _cAliasCCE:= "CCE"
Local _cAliasSD1:= "SD1"
Local _cAliasSD2:= "SD2"
Local _cAliasSF1:= "SF1"
Local _cAliasSF2:= "SF2"
Local _cCceCod	:= ""
Local _cMensAlt2:= ""
Local _cBranco	:= "%''%"
Local _lAchouSF2:= .F.
Local _lAchouSF1:= .F.
Local _aDocRef	:= {}
Local _nX		:= 0
Local _lRet		:= .F.
Local _nPos1	:= 1
Local _nPos2	:= 1
Local _nPos3    := 1
Local _nPos4	:= 2
Local _nPos5  	:= 1
Local _cChar	:=''

_cMensFis += "FFIIMM"

Begin Transaction
	While !(_lRet)

		If !Empty(AllTrim(SubStr(_cMensFis,_nPos1,254)))

			While _nPos4 <> 1 .And. _nPos2 <= 254
				If SubStr(_cMensFis,_nPos3,1) == Char(10)
					_nPos4 := 1
					_nPos5 := 2
				EndIf

				If "FFIIMM" $ SubStr(AllTrim(_cMensFis),_nPos1,_nPos2)
					_nPos4 := 1
					_nPos5 := 1
				EndIf
				_nPos2 ++
				_nPos3 ++
			EndDo

			_cMensAlt2:= _cMensAlt2+AllTrim(SubStr(AllTrim(_cMensFis),_nPos1,_nPos2-_nPos5))
			_cMensAlt2:= StrTran(AllTrim(_cMensAlt2),"FFIIMM","")

			For _nX:=1 To Len(_cMensAlt2)
				_cChar:=SubStr(_cMensAlt2, _nX, 1)
				If (Asc(_cChar) < 32 .Or. Asc(_cChar) > 123) .Or. _cChar $ "';"
					_cMensAlt2:=StrTran(_cMensAlt2,_cChar,"")
				EndIf
			Next _nX
			
			_nPos1 := _nPos3
			If   !Empty(AllTrim(_cMensAlt2)) .And. !('FFIIMM' $ AllTrim(_cMensAlt2))

				_cAliasCCE	:= GetNextAlias()
				BeginSql Alias _cAliasCCE
			     SELECT CCE_COD
			       FROM %Table:CCE%
			      WHERE D_E_L_E_T_ = ' '
		            AND CCE_FILIAL = %xFilial:CCE%
			        AND CCE_DESCR = %exp:AllTrim(_cMensAlt2)%
				EndSql

				_cCceCod := (_cAliasCCE)->CCE_COD
				(_cAliasCCE)->(DBCloseArea())

				DBSelectArea("CCE")
				CCE->(DBSetOrder(1))

				If Empty(_cCceCod)
					RecLock("CCE",.T.)
					CCE->CCE_FILIAL	:= xFilial("CCE")
					CCE->CCE_COD	:= GetSx8Num("CCE","CCE_COD")
					CCE->CCE_DESCR	:= AllTrim(StrTran(StrTran(_cMensAlt2,Char(10),""),Char(13),""))
					CCE->(MSUnLock())
					ConfirmSX8()
					_cCceCod := CCE->CCE_COD

				EndIf

				DBSelectArea("CDT")
				CDT->(DBSetOrder(1))

				If CDT->(DBSeek(xFilial("CDT")+_cTpMov+_cDoc+_cSerie+_cCliFor+_cLoja+_cCceCod))
					RecLock ("CDT",.F.)
				Else
					RecLock ("CDT",.T.)
				EndIf

				CDT->CDT_FILIAL	:= xFilial("CDT")
				CDT->CDT_TPMOV	:= _cTpMov
				CDT->CDT_DOC	:= _cDoc
				CDT->CDT_SERIE	:= _cSerie
				CDT->CDT_CLIFOR	:= _cCliFor
				CDT->CDT_LOJA	:= _cLoja
				CDT->CDT_IFCOMP	:= _cCceCod
				CDT->CDT_INDFRT	:= "" //ALTERADO POR ERICH BUTTNER DIA 08/08/13 - CORREÇÃO DA INFORMAÇÃO DO CAMPO CDT_INDFRT //CDT->CDT_INDFRT	:= _cTpFrete CHAMADO - 3957

				CDT->(MSUnLock())
			Else
				_lRet:= .T.
			EndIf
	    Else
	    	_lRet:= .T.
		EndIf

		_cMensAlt2 := ""
		_nPos4 := 2
		_nPos2 := 1
		_nPos5 := 1
	EndDo

	//==============================================================
	//Verifica a existencia de documentos referenciados
	//==============================================================
	If _cTpMov == "E"

		_cAliasSD1	:= GetNextAlias()

		BeginSql Alias _cAliasSD1

			SELECT SD1.D1_FILIAL,SD1.D1_DOC,SD1.D1_SERIE,SD1.D1_FORNECE,SD1.D1_LOJA,
				SD1.D1_NFORI,D1_SERIORI,SD1.D1_TIPO,SD1.D1_TES,SD1.D1_ORIGLAN
			FROM %Table:SD1% SD1
				WHERE SD1.D1_FILIAL = %xFilial:SD1%
				AND SD1.D1_DOC = %Exp:_cDoc%
				AND SD1.D1_SERIE = %Exp:_cSerie%
				AND SD1.D1_FORNECE = %Exp:_cCliFor%
				AND SD1.D1_LOJA = %Exp:_cLoja%
				AND SD1.D1_NFORI <> %Exp:_cBranco%
				AND SD1.%NotDel%
			ORDER BY %Order:SD1%
		EndSql

		While !((_cAliasSD1)->(Eof()))

			//==============================================================
			//Verifica o cliente/fornecedor do documento original
			//==============================================================

		  	SF4->(DBSetOrder(1))
			SF4->(DBSeek(xFilial("SF4")+(_cAliasSD1)->D1_TES))
			_lAchouSF2 := .F.  // Forço a reinicialização da variável a cada passo do laço.

			If (_cAliasSD1)->D1_TIPO $ "DB" .Or. SF4->F4_PODER3 == "D"
				If !SF2->(DBSeek(xFilial("SF2")+(_cAliasSD1)->(D1_NFORI+D1_SERIORI+D1_FORNECE+D1_LOJA)))
					(_cAliasSD1)->(DBSkip())
					Loop
				Else
				    _lAchouSF2 := .T.
				EndIf
			Else
				If !SF1->(DBSeek(xFilial("SF1")+(_cAliasSD1)->(D1_NFORI+D1_SERIORI+D1_FORNECE+D1_LOJA)))
					(_cAliasSD1)->(DBSkip())
					Loop
				EndIf
			EndIf

			If (aScan(_aDocRef,{|x|	x[1] == (_cAliasSD1)->D1_NFORI	 .And. ;
					x[2] == (_cAliasSD1)->D1_SERIORI .And. ;
					x[3] == (_cAliasSF1)->F1_FORNECE .And. ;
					x[4] == (_cAliasSF1)->F1_LOJA	 .And. ;
					x[5] == (_cAliasSD1)->D1_TIPO})) == 0
				If _lAchouSF2
				   aAdd(_aDocRef,{(_cAliasSD1)->D1_NFORI,(_cAliasSD1)->D1_SERIORI,SF2->F2_CLIENTE,SF2->F2_LOJA,(_cAliasSD1)->D1_TIPO,SF2->F2_CHVNFE})
				Else
				   aAdd(_aDocRef,{(_cAliasSD1)->D1_NFORI,(_cAliasSD1)->D1_SERIORI,(_cAliasSF1)->F1_FORNECE,(_cAliasSF1)->F1_LOJA,(_cAliasSD1)->D1_TIPO,(_cAliasSF1)->F1_CHVNFE})
				EndIf
			EndIf
			(_cAliasSD1)->(DBSkip())

		EndDo
		(_cAliasSD1)->(DBCloseArea())

	Else

		_cAliasSD2	:= GetNextAlias()

		BeginSql Alias _cAliasSD2

			SELECT SD2.D2_FILIAL,SD2.D2_DOC,SD2.D2_SERIE,SD2.D2_CLIENTE,SD2.D2_LOJA,
				SD2.D2_NFORI,SD2.D2_SERIORI,SD2.D2_TIPO,SD2.D2_TES
			FROM %Table:SD2% SD2
			WHERE SD2.D2_FILIAL = %xFilial:SD2%
				AND SD2.D2_DOC = %Exp:_cDoc%
				AND SD2.D2_SERIE = %Exp:_cSerie%
				AND SD2.D2_CLIENTE = %Exp:_cCliFor%
				AND SD2.D2_LOJA = %Exp:_cLoja%
				AND SD2.D2_NFORI <> %Exp:_cBranco%
				AND SD2.%NotDel%
			ORDER BY %Order:SD2%
		EndSql

		While !((_cAliasSD2)->(Eof()))

			//==============================================================
			//Verifica o cliente/fornecedor do documento original
			//==============================================================
			SF4->(DBSetOrder(1))
			SF4->(DBSeek(xFilial("SF4")+(_cAliasSD2)->D2_TES))
			_lAchouSF1 := .F.  // Forço a reinicialização da variável a cada passo do laço.

			If (_cAliasSD2)->D2_TIPO $ "DB" .Or. SF4->F4_PODER3 == "D"
				If !SF1->(DBSeek(xFilial("SF1")+(_cAliasSD2)->(D2_NFORI+D2_SERIORI+D2_CLIENTE+D2_LOJA)))
					(_cAliasSD2)->(DBSkip())
					Loop
				Else
				    _lAchouSF1 := .T.
				EndIf
			Else
				If !SF2->(DBSeek(xFilial("SF2")+(_cAliasSD2)->(D2_NFORI+D2_SERIORI+D2_CLIENTE+D2_LOJA)))
					(_cAliasSD2)->(DBSkip())
					Loop
				EndIf
			EndIf

		   	If (aScan(_aDocRef,{|x|	x[1] == (_cAliasSD2)->D2_NFORI	 .And. ;
					x[2] == (_cAliasSD2)->D2_SERIORI .And. ;
					x[3] == (_cAliasSF2)->F2_CLIENTE .And. ;
					x[4] == (_cAliasSF2)->F2_LOJA	 .And. ;
					x[5] == (_cAliasSD2)->D2_TIPO})) == 0
				If _lAchouSF1
				   aAdd(_aDocRef,{(_cAliasSD2)->D2_NFORI,(_cAliasSD2)->D2_SERIORI,(_cAliasSF1)->F1_FORNECE,(_cAliasSF1)->F1_LOJA,(_cAliasSD1)->D1_TIPO,(_cAliasSF1)->F1_CHVNFE})
				Else
					aAdd(_aDocRef,{(_cAliasSD2)->D2_NFORI,(_cAliasSD2)->D2_SERIORI,(_cAliasSF2)->F2_CLIENTE,(_cAliasSF2)->F2_LOJA,(_cAliasSD2)->D2_TIPO,(_cAliasSF2)->F2_CHVNFE})
				EndIf
			EndIf

			(_cAliasSD2)->(DBSkip())

		EndDo
		(_cAliasSD2)->(DBCloseArea())
	EndIf
	If !Empty(_aDocRef)
		DBSelectArea("CDD")
		CDD->(DBSetOrder(1)) //CDD_FILIAL+CDD_TPMOV+CDD_DOC+CDD_SERIE+CDD_CLIFOR+CDD_LOJA+CDD_DOCREF+CDD_SERREF+CDD_PARREF+CDD_LOJREF
		DBSelectArea("CCE")
		CCE->(DBSetOrder(1))

		If Empty(_cCceCod) .Or. !(CCE->(DBSeek(xFilial("CCE")+_cCceCod)))

			_cMensAlt2	:= "DOCUMENTO REFERENCIADO"
			_cAliasCCE	:= GetNextAlias()

			BeginSql Alias _cAliasCCE
			  SELECT CCE_COD
				FROM %Table:CCE%
			  WHERE D_E_L_E_T_ = ' '
				AND CCE_FILIAL = %xFilial:CCE%
				AND CCE_DESCR = %exp:AllTrim(_cMensAlt2)%
			EndSql

			_cCceCod := (_cAliasCCE)->CCE_COD
			(_cAliasCCE)->(DBCloseArea())

			If Empty(_cCceCod)
				RecLock("CCE",.T.)
				CCE->CCE_FILIAL	:= xFilial("CCE")
				CCE->CCE_COD	:= GetSx8Num("CCE","CCE_COD")
				CCE->CCE_DESCR	:= _cMensAlt2
				CCE->(MSUnLock())
				ConfirmSX8()
				
				_cCceCod := CCE->CCE_COD
			EndIf
		EndIf

		For _nX:=1 to Len(_aDocRef)
			If !CDD->(DBSeek(xFilial("CDD")+_cTpMov+_cDoc+_cSerie+_cCliFor+_cLoja+_aDocRef[_nX][1]+_aDocRef[_nX][2]+_aDocRef[_nX][3]+_aDocRef[_nX][4]))
				RecLock("CDD",.T.)
				CDD->CDD_FILIAL	:= xFilial("CDD")
				CDD->CDD_TPMOV	:= _cTpMov
				CDD->CDD_DOC	:= _cDoc
				SerieNfId("CDD",1,"CDD_SERIE",,,,_cSerie)
				CDD->CDD_CLIFOR	:= _cCliFor
				CDD->CDD_LOJA	:= _cLoja
				CDD->CDD_DOCREF	:= _aDocRef[_nX][1]
				SerieNfId("CDD",1,"CDD_SERREF",,,,_aDocRef[_nX][2])
				CDD->CDD_PARREF	:= _aDocRef[_nX][3]
				CDD->CDD_LOJREF	:= _aDocRef[_nX][4]
				CDD->CDD_IFCOMP	:= _cCceCod
				CDD->CDD_CHVNFE	:= _aDocRef[_nX][6]
				CDD->CDD_SDOC	:= _cSerie
				CDD->CDD_SDOCRF	:= _aDocRef[_nX][2]
				CDD->(MSUnLock())
			EndIf
		Next

	EndIf
End Transaction
FWRestArea(_aAreaCCE)
FWRestArea(_aAreaCDT)
FWRestArea(_aAreaCDD)
FWRestArea(_aAreaSF4)
FWRestArea(_aAreaSD1)
FWRestArea(_aAreaSD2)
FWRestArea(_aAreaSF1)
FWRestArea(_aAreaSF2)
FWRestArea(_aArea)
Return

/*
===============================================================================================================================
Programa--------: ECompFis
Autor-----------: Lucas Borges Ferreira
Data da Criacao-: 02/07/2018
Descrição-------: Exclui os complementos de notas fiscais de entrada e de saida com as informacoes necessarias ao Sped.
Parâmetros------:	_cTpMov - tipo do movimento
					_cDoc - documento na tabela CDT
					_cSerie - série do documento
					_cCliFor - código de cliente/fornecedor
					_cLoja - loja do cliente/fornecedor
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ECompFis(_cTpMov,_cDoc,_cSerie,_cCliFor,_cLoja)

Local _cQuery	:= ""

	// Geração do C113
	_cQuery:=" UPDATE "+RETSQLNAME('CDD')
	_cQuery+="    SET D_E_L_E_T_ = '*', 
	_cQuery+="        R_E_C_D_E_L_ = R_E_C_N_O_
	_cQuery+=" WHERE D_E_L_E_T_ = ' ' "
	_cQuery+=" AND CDD_FILIAL = '"+xFilial("CDD")+"'"
	_cQuery+=" AND CDD_TPMOV = '"+_cTpMov+"'"
	_cQuery+=" AND CDD_DOC = '"+_cDoc+"'"
	_cQuery+=" AND CDD_SERIE = '"+_cSerie+"'"
	_cQuery+=" AND CDD_CLIFOR = '"+_cCliFor+"'"
	_cQuery+=" AND CDD_LOJA = '"+_cLoja+"'"
	
	If TCSqlExec( _cQuery ) < 0
		MsgStop( 'Erro ao excluir complementos. '+AllTrim(TCSQLError()),"XFUNFIS01")
	EndIf
	// Geração do C110
	_cQuery:=" UPDATE "+RETSQLNAME('CDT')
	_cQuery+="    SET D_E_L_E_T_ = '*'
	_cQuery+=" WHERE D_E_L_E_T_ = ' ' "
	_cQuery+=" AND CDT_FILIAL = '"+xFilial("CDD")+"'"
	_cQuery+=" AND CDT_TPMOV = '"+_cTpMov+"'"
	_cQuery+=" AND CDT_DOC = '"+_cDoc+"'"
	_cQuery+=" AND CDT_SERIE = '"+_cSerie+"'"
	_cQuery+=" AND CDT_CLIFOR = '"+_cCliFor+"'"
	_cQuery+=" AND CDT_LOJA = '"+_cLoja+"'"
	
	If TCSqlExec( _cQuery ) < 0
		MsgStop( 'Erro ao excluir complementos. '+AllTrim(TCSQLError()),"XFUNFIS02")
	EndIf

Return
