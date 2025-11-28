/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: MQDO003
Autor-----------: Alex Wallauer
Data da Criacao-: 01/11/2023
Descrição-------: Chamado do gatilho 005 do QDH_CODTP - Chamado 45435
                  Ajuste para que o sequencial seja único para os 5 primeiros caracteres
Parametros------: NENHUM
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function MQDO003

Local _cTextoAux:= ""
Local _cFiltro  := ""
Local _cCodigo  := ""
Local _cAlias   := ""
Local _cQuery   := ""
Local _cSiglas  := SuperGetMV("IT_SIGFORM",.F.,"CB.F./TP.F./PF.F./JR.F./TC.F./CA.F./XG.F.")
Local _nTam     := 5
//Corumbaíba ->CB.F. // Tapejara -> TP.F. // Passo Fundo -> PF.F. // Jaru -> JR.F. 
//Três Corações -> TC.F. // Conceição do Araguaia -> CA.F. // Xinguara -> XG.F.

If GETMV("MV_QNSEQDC") == "S"
	If QD2->(DBSeek(xFilial("QD2")+M->QDH_CODTP))		
		
      If QD2->QD2_QSEQ == 0 .Or. !LEFT(M->QDH_DOCTO,_nTam) $ _cSiglas
			Return M->QDH_DOCTO
		EndIf
	
		_cCodigo := AllTrim(QD2->QD2_SIGLA)					

      _cAlias := GetNextAlias()			
      _cQuery := " SELECT MAX(QDH_DOCTO) AS CODIGO "
      _cQuery += " FROM " + RetSqlName("QDH")
      _cQuery += " WHERE D_E_L_E_T_ <> '*'"
      _cQuery += " AND QDH_DOCTO LIKE '" + LEFT(_cCodigo,_nTam) + "%' "
      _cQuery := ChangeQuery(_cQuery)
      MPSysOpenQuery(_cQuery,_cAlias)
      
      DBSelectArea(_cAlias)
      (_cAlias)->(DBGoTop())
      If !Empty((_cAlias)->CODIGO)
         _cSeqAtual:= Right(AllTrim((_cAlias)->CODIGO),QD2->QD2_QSEQ)
         _cTextoAux:= _cCodigo+Soma1(_cSeqAtual)
         _nCt:= Val(_cSeqAtual)+1
      Else//Não tem NENHUM
      	_cTextoAux:= _cCodigo+StrZero(1,QD2->QD2_QSEQ)
         _nCt:= 1
      EndIf
      (_cAlias)->(DBCloseArea())

		DBSelectArea("QDH")
		QDH->(DBSetOrder(1))
		Set Filter to
		Help := .T.	// Nao apresentar Help MayUse
		While QDH->(DBSeek(M->QDH_FILIAL+_cTextoAux)) .OR.;//!FreeForUse("QDH",M->QDH_FILIAL+PadR(_cTextoAux,TamSX3( "QDH_DOCTO" )[1])+"000",.F.).OR.; //.Or. VerifDel(_cTextoAux)
               !MayIUseCode("QDH_DOCTO_"+AllTrim(M->QDH_FILIAL)+LEFT(_cTextoAux,_nTam)+RIGHT(_cTextoAux,QD2->QD2_QSEQ))
         _nCt++
         _cTextoAux:=_cCodigo+StrZero(_nCt,QD2->QD2_QSEQ)
			Help := .T.	// Nao apresentar Help MayUse
      EndDo
		Help := .F.	// Habilito o help novamente

		M->QDH_DOCTO := _cTextoAux
		M->QDH_RV    := "000"	
		M->QDH_REVINV:=INVERTE(M->QDH_RV)
		
      _cFiltro:= Qd050Filtro()
		Set Filter to &(_cFiltro)
	EndIf
EndIf

Return M->QDH_DOCTO
